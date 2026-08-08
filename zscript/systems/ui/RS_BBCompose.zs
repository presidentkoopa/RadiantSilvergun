// =====================================================================
// RS_BBCompose -- build a panel out of billboard payloads.
// ---------------------------------------------------------------------
// The engine's five payloads landed 2026-08-07. Before that only
// BB_TEXTURE drew, so every in-world panel had to be PAINTED onto a
// canvas -- and a canvas is a named texture declared by hand in
// ANIMDEFS. RS has eleven and the drop triptych alone spends nine. Ten
// elites on screen was not a performance problem, it was an
// impossibility: there were no textures left to give them.
//
// A composed panel costs no textures at all. A number is BB_DIGITS, a
// meter is BB_BAR, a plate is BB_PANEL, a letter is BB_GLYPH.
//
// WHEN TO STILL USE A CANVAS: real artwork. A painted card face, a
// portrait, anything with a picture on it. Composition is for readouts
// -- names, numbers, bars, plates -- and those are what a drop card is.
//
// ---------------------------------------------------------------------
// PARTS REMEMBER WHERE THEY SIT, and that is the whole design.
//
// A panel in this project re-aims every tic: RS_Panel.FaceViewer runs
// per tic and a hinged assembly re-solves with it. If composing meant
// laying out from scratch each time, a moving player would destroy and
// re-create forty billboards every tic forever.
//
// So a composed panel stores each part's offset in PANEL-LOCAL space --
// right and up, in map units from the panel's centre -- and Place()
// walks that list recomputing world positions. No allocation, no
// handle churn, and the layout code runs once.
// =====================================================================

class RS_BBComposedPanel : Object
{
	private Array<RS_Billboard> mParts;
	private Array<double>       mLocalRight;   // parallel to mParts
	private Array<double>       mLocalUp;

	// Last transform Place() was given, so a caller can skip a no-op.
	private Vector3 mAt;
	private double  mYaw, mTilt;
	private bool    mPlaced;

	bool Empty() const { return mParts.Size() == 0; }
	int  PartCount() const { return mParts.Size(); }

	// The engine's own basis, and it must stay the engine's own: right is
	// (sin yaw, -cos yaw, 0) and positive tilt leans the TOP toward the
	// viewer. Getting this backwards lays every card out mirrored, which
	// survives a long time before anyone reads the text closely enough.
	static Vector3 RightOf(double yaw)
	{
		return (sin(yaw), -cos(yaw), 0);
	}

	static Vector3 UpOf(double yaw, double tilt)
	{
		double st = sin(tilt), ct = cos(tilt);
		return (-cos(yaw) * st, -sin(yaw) * st, ct);
	}

	// Record a part at a panel-local offset. Everything in this file goes
	// through here so nothing can be added without its offset -- a part
	// whose local position is unknown could never be re-placed, and would
	// silently stay behind the first time the panel moved.
	RS_Billboard Add(RS_Billboard b, double localRight, double localUp)
	{
		if (!b) return null;
		mParts.Push(b);
		mLocalRight.Push(localRight);
		mLocalUp.Push(localUp);
		return b;
	}

	// Move every part to match a new panel transform. Cheap: no
	// allocation, no handles created or destroyed.
	void Place(Vector3 at, double yaw, double tilt)
	{
		if (mPlaced && at == mAt && yaw == mYaw && tilt == mTilt) return;

		Vector3 r = RightOf(yaw);
		Vector3 u = UpOf(yaw, tilt);

		for (int i = 0; i < mParts.Size(); i++)
		{
			if (!mParts[i]) continue;
			mParts[i].MoveTo(at + r * mLocalRight[i] + u * mLocalUp[i]);
			mParts[i].Orient(yaw, tilt, LevelLocals.BBF_FIXED);
		}

		mAt = at; mYaw = yaw; mTilt = tilt; mPlaced = true;
	}

	void SetAlphaAll(double a)
	{
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i]) mParts[i].SetAlpha(a);
	}

	// A handle is not garbage-collectable -- it is an integer the engine
	// issued, and dropping it without RemoveBillboard leaks a quad that
	// lives until the level ends. Every leak this project has found has
	// been exactly that shape, so this is the one place parts die.
	void ReleaseAll()
	{
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i]) mParts[i].Release();
		mParts.Clear();
		mLocalRight.Clear();
		mLocalUp.Clear();
		mPlaced = false;
	}

	// Does any part answer to this native hit id? The composed equivalent
	// of RS_Panel.BillboardHandle(), so the controller's aim can still
	// resolve a composed card back to the panel it belongs to.
	bool OwnsHandle(int id) const
	{
		if (id == 0) return false;
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i] && mParts[i].Handle() == id) return true;
		return false;
	}
}

// =====================================================================
// RS_BBCompose -- the vocabulary. Every call takes panel-local
// coordinates, so a layout reads as a drawing rather than as a pile of
// world-space arithmetic, and the same layout works wherever the panel
// ends up.
// =====================================================================

class RS_BBCompose
{
	// Glyph advance as a fraction of glyph height. The engine fits each
	// BB_GLYPH inside the billboard it is given, so this is spacing, not
	// the letter's own width -- proportional spacing would need per-char
	// metrics script cannot reach, and a fixed pitch reads fine for the
	// short all-caps strings these panels use.
	const GLYPH_PITCH = 0.62;

	// Parts are created at the origin and moved into place by Place().
	// Creating them at their final position instead would duplicate the
	// basis maths in two places and let the two drift.
	private static RS_Billboard Raw(double w, double h, int payload, int data, Color col)
	{
		return RS_Billboard.Make((0, 0, 0), w, h, 0, 0, payload, data, col,
			LevelLocals.BBF_FIXED, 0);
	}

	// -----------------------------------------------------------------
	// TEXT. One BB_GLYPH per character.
	//
	// A billboard per letter sounds extravagant and is not: the primitive
	// exists precisely so hundreds can be built without an actor apiece,
	// and a letter is the cheapest thing it draws.
	//
	// align: -1 starts at x, 0 centres on it, +1 ends at it.
	// -----------------------------------------------------------------
	static void Text(RS_BBComposedPanel p, double x, double y, string txt,
		double h, Color col, int align = -1)
	{
		if (!p || txt.Length() == 0 || h <= 0) return;

		double pitch = h * GLYPH_PITCH;
		double width = pitch * txt.Length();

		double start = x;
		if (align == 0)      start = x - width * 0.5;
		else if (align > 0)  start = x - width;

		for (int i = 0; i < txt.Length(); i++)
		{
			int ch = txt.ByteAt(i);
			if (ch == 32) continue;		// space: advance, draw nothing

			p.Add(Raw(pitch, h, LevelLocals.BB_GLYPH, ch, col),
				start + pitch * (i + 0.5), y);
		}
	}

	// A NUMBER. One billboard whatever the magnitude -- the engine fits
	// the digits to the box, shrinking a long value rather than letting
	// it run off the ends of its own panel.
	static RS_Billboard Number(RS_BBComposedPanel p, double x, double y, int value,
		double w, double h, Color col)
	{
		if (!p) return null;
		return p.Add(Raw(w, h, LevelLocals.BB_DIGITS, value, col), x, y);
	}

	// A METER. pct is 0..100 and the engine grows the fill from the LEFT
	// edge, so only the right end moves.
	static RS_Billboard Bar(RS_BBComposedPanel p, double x, double y, int pct,
		double w, double h, Color col)
	{
		if (!p) return null;
		return p.Add(Raw(w, h, LevelLocals.BB_BAR, clamp(pct, 0, 100), col), x, y);
	}

	// A PLATE. The backing everything else sits on, and the part that
	// should carry a hit test: it is far and away the biggest target, and
	// pointing at a card should mean the card rather than whichever glyph
	// the ray happened to cross.
	static RS_Billboard Plate(RS_BBComposedPanel p, double x, double y,
		double w, double h, Color col)
	{
		if (!p) return null;
		return p.Add(Raw(w, h, LevelLocals.BB_PANEL, 0, col), x, y);
	}

	// A PICTURE. The one payload that still needs a real texture -- a
	// weapon's own icon, or a painted canvas where artwork is wanted.
	static RS_Billboard Picture(RS_BBComposedPanel p, double x, double y, TextureID tex,
		double w, double h, Color col)
	{
		if (!p || !tex.IsValid()) return null;
		return p.Add(Raw(w, h, LevelLocals.BB_TEXTURE, tex.GetIndex(), col), x, y);
	}

	// A LABELLED STAT ROW: label left, value right. The shape every line
	// of zscript/CardTemplate.txt turns out to be.
	static void StatRow(RS_BBComposedPanel p, double y, double panelW,
		string label, int value, double lineH, Color labelCol, Color valueCol)
	{
		if (!p) return;
		double edge = panelW * 0.5 * 0.88;
		Text(p, -edge, y, label, lineH, labelCol, -1);
		Number(p, edge * 0.55, y, value, panelW * 0.28, lineH, valueCol);
	}
}
