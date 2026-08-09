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
// meter is BB_BAR, a plate is BB_PANEL, a STRING is BB_TEXT (one
// billboard for the whole string, drawn through a distance field).
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
	private Array<double>       mBaseW;        // ditto -- unscaled size
	private Array<double>       mBaseH;
	private double              mScale;        // 0 or 1 = full size

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
	// survive, and the text read backwards. At the time RS_BBCompose.Text
	// placed one BB_GLYPH per character at increasing localRight, so a
	// left-pointing "right" laid every string out from screen-right to
	// screen-left -- the whole card mirrored, labels on the wrong side,
	// stat values on the wrong side.
	//
	// Text() is one BB_TEXT now and does not walk a pen, but this basis
	// is MORE load-bearing rather than less: the sfd lane confirmed the
	// SDF glyph pen, the aim ray and the touch test all resolve through
	// BillboardBasis, so an error here would still mirror everything.
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
		// Base size and offset, kept so Rescale can be ABSOLUTE rather
		// than cumulative. Scaling from the current value would compound
		// every call and drift the card away from any size you asked for.
		mBaseW.Push(b.Width());
		mBaseH.Push(b.Height());
		return b;
	}

	// -----------------------------------------------------------------
	// SMOOTH SCALE, NO REBUILD. Added 2026-08-09.
	//
	// The card used to scale in 12 discrete steps, and the reason was
	// real at the time: changing size marked the panel mContentDirty,
	// which is ReleaseAll() plus a full Build() -- every billboard
	// destroyed and recreated. Doing that 35 times a second for someone
	// merely walking was untenable, so the ramp was quantised instead.
	//
	// Two things removed that constraint. BB_TEXT collapsed the card from
	// ~60 parts to a handful, and ResizeBillboard is a direct engine
	// setter -- the sfd lane confirmed both. So a rescale is now N cheap
	// setter calls with no allocation and no handle churn, which is what
	// Place() already was.
	//
	// The offsets scale too, not just the parts. Scaling only the parts
	// would shrink each element in place and leave a full-size card with
	// tiny contents rattling around inside it.
	// -----------------------------------------------------------------
	void Rescale(double f)
	{
		if (f <= 0 || f == mScale) return;
		mScale = f;

		for (int i = 0; i < mParts.Size() && i < mBaseW.Size(); i++)
			if (mParts[i])
				mParts[i].Resize(mBaseW[i] * f, mBaseH[i] * f);

		// Force the next Place() through: the early-out compares the
		// transform only, and the transform has not changed -- but every
		// offset just did.
		mPlaced = false;
	}

	double Scale() const { return mScale <= 0 ? 1.0 : mScale; }

	// -----------------------------------------------------------------
	// WHERE IS THIS PANEL-LOCAL POINT, IN THE WORLD?
	//
	// Uses the transform Place() last stored, so a caller gets exactly
	// the point a part at that offset would occupy -- same basis, same
	// scale, no second derivation to drift out of step with the first.
	// That matters: the card model has to sit precisely where the icon
	// slot is, and "roughly there" reads as broken.
	//
	// Returns the panel origin unplaced, which is harmless -- a caller
	// asking before the first Place has nothing better to be told.
	// -----------------------------------------------------------------
	Vector3 WorldAt(double localRight, double localUp) const
	{
		if (!mPlaced) return mAt;
		double sc = mScale > 0 ? mScale : 1.0;
		return mAt + RightOf(mYaw) * (localRight * sc)
		           + UpOf(mYaw, mTilt) * (localUp * sc);
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
			double sc = mScale > 0 ? mScale : 1.0;
			mParts[i].MoveTo(at + r * (mLocalRight[i] * sc) + u * (mLocalUp[i] * sc));
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
	// LAST-RESORT WIDTH ESTIMATE ONLY -- not a layout input.
	//
	// Used solely when level.MeasureBillboardText returns 0.0, which means
	// no SDF atlas is loaded. Every real layout decision comes from the
	// engine measurer; this exists so a font-less load degrades to
	// roughly-right rather than to zero-width strings stacked on one spot.
	const GLYPH_PITCH_FALLBACK = 0.62;

	// Parts are created at the origin and moved into place by Place().
	// Creating them at their final position instead would duplicate the
	// basis maths in two places and let the two drift.
	private static RS_Billboard Raw(double w, double h, int payload, int data, Color col,
		string text = "")
	{
		return RS_Billboard.Make((0, 0, 0), w, h, 0, 0, payload, data, col,
			LevelLocals.BBF_FIXED, 0, text);
	}

	// -----------------------------------------------------------------
	// TEXT. ONE BB_TEXT BILLBOARD FOR THE WHOLE STRING.
	//
	// Rewritten 2026-08-09. This placed one BB_GLYPH per character and
	// did its own pen walk, width maths and clipping. All of that is now
	// deleted rather than adapted, because BB_TEXT OWNS ITS OWN LAYOUT:
	// EmitBillboardSDFText walks a pen from each glyph's advance in the
	// atlas metrics and fits the string to whichever axis runs out first.
	// Two layout engines on one string fight, and theirs is the one the
	// renderer actually obeys.
	//
	// What this buys, beyond looking right:
	//   * a card drops from ~60 parts to a handful, which is what made
	//     the per-tic Place() walk expensive and forced card growth into
	//     12 discrete steps
	//   * the string stays sharp at any size -- a distance field
	//     reconstructs the edge instead of resampling a picture of one
	//   * glow becomes available per part (RS_Billboard.SetGlow)
	//
	// GLYPH_PITCH IS GONE and must not come back as a layout input. It
	// was only ever correct because mksdf.ps1 deliberately writes ONE
	// reference advance for every glyph, so tabular figures stay aligned
	// and a ticking number does not jitter its own width. Regenerate the
	// atlas proportional and a hardcoded pitch silently stops being true.
	// Measure instead -- see Measure() below.
	//
	// align: -1 starts at x, 0 centres on it, +1 ends at it.
	// maxW: the width this string must fit inside, in world units.
	//       0 = do not constrain.
	// -----------------------------------------------------------------
	static RS_Billboard Text(RS_BBComposedPanel p, double x, double y, string txt,
		double h, Color col, int align = -1, double maxW = 0)
	{
		if (!p || txt.Length() == 0 || h <= 0) return null;

		double w = Measure(txt, h);

		// Shrink to fit rather than truncate. The old version cut
		// characters off, which turns a long label into a different and
		// wrong word ("PROTOTYPE" -> "PROTO"); scaling the height keeps
		// every character and only costs legibility, which the reader can
		// at least SEE happening.
		if (maxW > 0 && w > maxW)
		{
			double shrink = maxW / w;
			h *= shrink;
			w = maxW;
		}

		// BB_TEXT is centred on its position like every other payload, so
		// convert the caller's alignment into a centre point.
		double cx = x;
		if (align < 0)      cx = x + w * 0.5;
		else if (align > 0) cx = x - w * 0.5;

		return p.Add(Raw(w, h, LevelLocals.BB_TEXT, 0, col, txt), cx, y);
	}

	// -----------------------------------------------------------------
	// HOW WIDE WILL THAT STRING BE, in world units, before placing it.
	//
	// The engine's own measurer mirrors EmitBillboardSDFText's maths
	// rather than re-deriving them, so the two cannot disagree -- and if
	// they ever do, the renderer is right and the measurer is the bug.
	//
	// Returns 0.0 when no SDF atlas is loaded, which means "estimate it
	// yourself" and NOT "the string is empty" -- a mod is allowed not to
	// ship a font. The fallback is the old fixed-pitch approximation,
	// which is what this whole file used to assume unconditionally.
	// -----------------------------------------------------------------
	static double Measure(string txt, double h)
	{
		double w = level.MeasureBillboardText(txt, h);
		if (w > 0.0)
			return w;
		return h * GLYPH_PITCH_FALLBACK * txt.Length();
	}

	// A NUMBER AS A SEGMENT READOUT -- the arcade display look.
	//
	// BB_SEGMENT, not BB_DIGITS. BB_DIGITS draws raster glyph quads: a
	// picture of a number, which goes blocky as you walk toward it and
	// carries no glow. BB_SEGMENT is built from arithmetic in the shader,
	// so it stays exactly sharp at any size, cannot break on a missing
	// font lump, and takes a glow like the SDF payloads do.
	//
	// This is the thing the owner pointed at -- the readouts in the other
	// lane's screenshots are this payload.
	//
	// `data` is PACKED GLOW on this payload (and on BB_TEXT/SEGLCD/SEAM),
	// not a value: the number itself rides in `text`. Passing an integer
	// here the way BB_DIGITS wants would silently set a nonsense glow.
	static RS_Billboard Segment(RS_BBComposedPanel p, double x, double y, string txt,
		double w, double h, Color col, double glowReach = 0.35, double glowStr = 0.6)
	{
		if (!p) return null;
		return p.Add(Raw(w, h, LevelLocals.BB_SEGMENT,
			LevelLocals.BBGlow(glowReach, glowStr), col, txt), x, y);
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
