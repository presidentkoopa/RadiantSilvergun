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

	// CORRECTED 2026-08-08 -- THIS RETURNED (sin yaw, -cos yaw, 0) AND THAT
	// IS THE VIEWER'S *LEFT*, NOT THE VIEWER'S RIGHT.
	//
	// The old body carried a comment warning that "getting this backwards
	// lays every card out mirrored, which survives a long time before
	// anyone reads the text closely enough". It was backwards, and it did
	// survive, and the text read backwards. Because RS_BBCompose.Text
	// places one BB_GLYPH per character at increasing localRight, a
	// left-pointing "right" laid every string out from screen-right to
	// screen-left -- the whole card mirrored, labels on the wrong side,
	// stat values on the wrong side.
	//
	// PROVED AGAINST THE ENGINE, not reasoned from our own tree. A panel's
	// yaw points FROM the panel TOWARD the eye (RS_Panel.FaceViewer uses
	// Vec3Diff(pos, eye), and vmthunks.cpp:2699-2701 returns v2 - v1), so
	// the view direction V = -F = (-cos y, -sin y, 0).
	//
	// The ordinary sprite path is the ground truth for "which way does a
	// picture face", because every sprite in Doom depends on it:
	//   hw_sprites.cpp:1285-1308  the sprite's horizontal extent runs from
	//                             leftfac to rightfac along (-V.y, V.x);
	//                             corner v[0] is the leftfac end.
	//   hw_sprites.cpp:1247-1248  the UNMIRRORED branch gives v[0] u = UR
	//                             (= 1, the texture's RIGHT edge) and v[1]
	//                             u = UL (= 0, its LEFT edge).
	//   gametexture.cpp:340-341   UL = 0, UR = 1 for an untrimmed texture.
	// So (-V.y, V.x) runs from the picture's right edge to its left edge:
	// it points to the VIEWER'S LEFT. Substituting V gives
	// (-V.y, V.x) = (sin y, -cos y) -- the old value.
	//
	// The viewer's right is therefore (V.y, -V.x) = (-sin y, cos y, 0),
	// which is what this now returns.
	//
	// THE ENGINE MAKES THE SAME MISTAKE and it is NOT fixed by this
	// function -- see hw_sprites.cpp:2083. That half shows up as each
	// individual GLYPH being mirrored, and the lever for it is the engine
	// cvar `bb_flipu` (hw_sprites.cpp:93, 2027-2028): it must be ON.
	// Both halves have to be right or the text is still unreadable; one
	// alone turns a clean mirror into reversed-but-correctly-shaped
	// letters. A mod cannot set bb_flipu from script (vmnatives.cpp:955 --
	// non-CVAR_MOD cvars are menu-only), so it is a player setting, and
	// the mod already exposes it at MENUDEF.txt:2633.
	static Vector3 RightOf(double yaw)
	{
		return (-sin(yaw), cos(yaw), 0);
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

	// Breathing room at each edge, as a FRACTION of the width a string is
	// given. Text is clipped to that width minus twice this.
	const GLYPH_MARGIN = 0.04;

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
	// maxW: the width this string must fit inside, IN WORLD UNITS, same
	// units as x/y/h. 0 = do not clip.
	//
	// CORRECTED 2026-08-08, SAME DAY IT WAS BROKEN. The first version of
	// this clip hardcoded the bounds to +/-0.5, having assumed the composed
	// panel's local space was normalised to a 1.0-wide card. IT IS NOT --
	// RS_BBWeaponCard.Build places its plate with Plate(p, 0, 0, w, h) and
	// its rows at h * 0.43, so local coordinates are WORLD UNITS and a card
	// is ~30 wide. Clamping those to 0.5 crushed every string into a
	// one-unit strip at the centre of the card.
	//
	// The caller is the only thing that knows the width, so the caller
	// passes it. Left at 0 this behaves exactly as it did before any clip
	// existed, which is what every caller that has not been updated wants.
	static void Text(RS_BBComposedPanel p, double x, double y, string txt,
		double h, Color col, int align = -1, double maxW = 0)
	{
		if (!p || txt.Length() == 0 || h <= 0) return;

		double pitch = h * GLYPH_PITCH;

		// =============================================================
		// TEXT IS CLIPPED TO THE PANEL. Added 2026-08-08.
		//
		// This laid out one glyph per character at a fixed pitch and
		// NEVER checked the result against the panel it was drawing on.
		// A label wider than the card simply kept going, off the edge and
		// across the gap onto the NEXT panel -- so the triptych showed
		// "ACCURA" on one card and "CY 59" on its neighbour, and the tail
		// of every long word appeared to be the next card's data. Nothing
		// errored; it just looked like the values were on the wrong card.
		//
		// Anything that does not fit is truncated rather than allowed to
		// escape -- a clipped word is a legibility problem, an escaped one
		// is a bug that reads as corrupted data.
		//
		// THE BOUND COMES FROM THE CALLER (maxW), NOT FROM A CONSTANT. The
		// first version assumed composed space was normalised to a 1.0-wide
		// panel and clamped to +/-0.5. Local coordinates here are WORLD
		// UNITS -- a card is ~30 wide -- so that crushed every string into a
		// one-unit strip at the middle of the card. maxW = 0 means the
		// caller has not said, so nothing is clipped.
		// =============================================================
		string draw = txt;
		if (maxW > 0)
		{
			double budget = maxW * (1.0 - GLYPH_MARGIN * 2.0);
			int maxChars = int(budget / pitch);
			if (maxChars < 1) maxChars = 1;
			if (draw.Length() > maxChars)
				draw = draw.Left(maxChars);
		}

		double width = pitch * draw.Length();

		double start = x;
		if (align == 0)      start = x - width * 0.5;
		else if (align > 0)  start = x - width;

		// Never begin outside the span either -- a right-aligned string that
		// overflows would otherwise start off the left edge.
		if (maxW > 0)
		{
			double lo = -maxW * 0.5 + maxW * GLYPH_MARGIN;
			if (start < lo) start = lo;
		}

		for (int i = 0; i < draw.Length(); i++)
		{
			int ch = draw.ByteAt(i);
			if (ch == 32) continue;		// space: advance, draw nothing

			p.Add(Raw(pitch, h, LevelLocals.BB_GLYPH, ch, col),
				start + pitch * (i + 0.5), y);
		}
	}

	// A NUMBER. One billboard whatever the magnitude -- the engine fits
	// the digits to the box, shrinking a long value rather than letting
	// it run off the ends of its own panel.
	//
	// KNOWN DEFECT, ENGINE SIDE, NOT FIXABLE FROM HERE (2026-08-08).
	// BB_DIGITS lays its glyphs out itself, walking a pen along the
	// billboard's `right` -- which is the viewer's LEFT (see RightOf
	// above). EmitBillboardGlyphs at hw_sprites.cpp:1884-1897 therefore
	// puts the FIRST digit at screen-right, so a multi-digit value renders
	// reversed: 120 reads 021. `bb_flipu` does NOT touch this -- it only
	// flips U inside each quad, so it fixes the digit SHAPES and leaves
	// the ORDER wrong.
	//
	// Two ways out, both the owner's call: fix `right` in the engine
	// (hw_sprites.cpp:2083), which also removes the need for bb_flipu at
	// all; or stop using BB_DIGITS here and place the digits from this
	// file with Text(), which puts the order under our own control at the
	// cost of one billboard per digit. Single-digit values are unaffected
	// either way.
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
