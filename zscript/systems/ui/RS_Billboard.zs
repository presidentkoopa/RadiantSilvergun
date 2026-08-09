// =====================================================================
// RS_Billboard -- the script side of the engine's billboard primitive.
// ---------------------------------------------------------------------
// Built 2026-08-07, the day the natives landed. This is the thin layer
// every in-world screen in RS should sit on from here.
//
// WHY A WRAPPER AND NOT DIRECT CALLS. The natives hand out integer
// handles (AddBillboardPersistent / AttachBillboard) and a handle that
// is dropped without RemoveBillboard is a leak the garbage collector
// cannot see -- it is not an actor, nothing owns it, and it survives
// until the level ends. Every leak this project has found so far has
// been exactly that shape (RS_BFGTrail hung glow sprites in the air for
// a whole map). So handles live in objects with a Destroy() that
// releases them, and nothing outside this file touches a raw handle.
//
// ---------------------------------------------------------------------
// WHAT THE ENGINE GIVES US (E:\UZDXREMA, doombase.zs:536-582)
//
//   AddBillboard              transient, expires by lifetime, no handle
//   AddBillboardPersistent    lives until removed, returns a handle
//   AttachBillboard           follows an actor, dies with it
//   Update/Move/Orient/Resize/SetBillboardAlpha/RemoveBillboard
//   AimBillboard(start, dir)  -> hit id + UV across the face
//   TouchBillboard(point, r)  -> hit id + UV + distance to surface
//
// The last two are the important ones. RS_PanelController currently
// hand-rolls ray/plane intersection and a hand-inside-bounds poke test
// against every live panel, every tic. The engine now does both, in
// native code, and returns the SAME UV the shader sees -- which removes
// the entire class of "the hit test drifted from the pixels" bug.
//
// CONSTANTS COME FROM THE ENGINE, NOT FROM HERE. This file used to
// declare its own BBP_*/BBF_*/BBFACE_* copies of the payload, flag and
// facing numbers. The engine exposes them, and its own comment on that
// enum says exactly why they should be used: "so callers are not obliged
// to invent their own copies of the same numbers, which is how two sets
// of constants for one thing start drifting apart." Mine matched at the
// time of the swap; they were one engine edit away from not matching.
//
// THEY MUST BE QUALIFIED -- write the LevelLocals. prefix on every one.
// A bare name will not compile. The enums are declared INSIDE LevelLocals
// (doombase.zs:542-565) and their values stay members of it -- ZScript
// does not hoist them to global scope. A bare name is "Unknown
// identifier".
//
// Settled by experiment on 2026-08-08, and worth recording because the
// first attempt got it backwards. An earlier boot reported "BBF_FIXED is
// not a member of LevelLocals", which reads as proof the qualified form
// is wrong -- so all 23 uses were changed to bare names. That was a
// misread: the engine .pk3 loaded at the time was STALE and contained no
// billboard enums at all, so BOTH forms failed, each with the error its
// own syntax produces. Only after a clean engine build did the real
// answer appear.
//
// The lesson is about diagnosis, not syntax: an error message about a
// symbol proves nothing until you know the file defining that symbol is
// the one actually loaded.
//
//   payloads  BB_PANEL / BB_TEXTURE / BB_DIGITS /
//             BB_GLYPH / BB_RING / BB_BAR
//   facing    BBF_FIXED / BBF_CAMERAYAW / BBF_CAMERA
//   flags     BBFL_PERSISTENT / BBFL_ATTACHED /
//             BBFL_NODEPTH / BBFL_VIEWLOCKED / BBFL_FOLLOWANGLE
//
// ---------------------------------------------------------------------
// ALL FIVE PAYLOADS DRAW. CORRECTED 2026-08-07 -- THIS BLOCK SAID THE
// OPPOSITE AND WAS WRONG.
//
// It read "ONLY BB_TEXTURE ACTUALLY DRAWS ... a screen built on BB_RING
// or BB_BAR is INVISIBLE", and told every later session to paint a
// canvas instead. That was true when written and is now false: engine
// commit 42c26aa411, "All five billboard payloads draw, and none of them
// needed a shader".
//
// The premise was the error. Nothing needed a shader -- ProcessBillboard
// built ONE quad and submitted it once, and nothing stopped it
// submitting several. Emission is now a callback and each payload
// decides how many quads to send: a bar is a track plus a fill, a number
// is a row of glyphs. The shapes come from three generated graphics
// (bbwhite, bbpanel, bbring) tinted by the billboard's colour.
// Verified in src/rendering/hwrenderer/scene/hw_sprites.cpp:1917-1957
// before this edit, not taken on report.
//
//   BB_PANEL   rounded plate      BB_BAR     track + fill meter
//   BB_RING    ring               BB_DIGITS  a number
//   BB_GLYPH   one character      BB_TEXTURE a canvas or any texture
//
// Two real costs, stated by the lane that built them: a rounded plate
// stretched to a non-square billboard stretches its corner radius too,
// and ring thickness is fixed by the artwork rather than settable.
//
// WHY THIS ENTRY MATTERED. A wrong fact misleads; a wrong fact that says
// "do not use that, it is invisible" stops anyone checking. That is the
// exact failure shape CLAUDE.md calls the worst kind, and this file was
// carrying one. BB_TEXTURE is still right for real ARTWORK; the other
// four are right for READOUTS, and RS_BBCompose.zs is built on them.
//
// STILL TRUE, and the reason composition exists at all: a canvas is a
// scarce, hand-declared resource. Each one needs an ANIMDEFS
// `canvastexture` entry, and two billboards pointing at the same canvas
// show the SAME PICTURE. RS ships eleven and a triptych spends nine, so
// a second card had nowhere to draw. A composed panel costs zero.
//
// =====================================================================

class RS_Billboard : Object
{
	// The handle. 0 means "nothing allocated" -- the natives return 0 on
	// failure and AimBillboard/TouchBillboard return 0 for a miss, so 0
	// is consistently "no billboard" across the whole API.
	private int mId;

	// Kept so a caller can re-issue an Update without re-deriving them.
	int     mPayload;
	int     mData;
	Color   mColor;
	double  mW, mH;

	int Handle() const { return mId; }

	// Current size. Read by RS_BBComposedPanel.Add to capture a part's
	// UNSCALED dimensions once, so Rescale can work from the original
	// rather than compounding on the last value.
	double Width()  const { return mW; }
	double Height() const { return mH; }
	bool Alive() const { return mId != 0; }

	// -----------------------------------------------------------------
	// Persistent billboard at a world position.
	// -----------------------------------------------------------------
	// `text` is what BB_TEXT draws and is ignored by every other payload.
	// AddBillboardPersistent takes it as its LAST parameter, after
	// lifetime -- so lifetime has to be passed explicitly (0 = permanent,
	// which persistent billboards are anyway) to reach it positionally.
	static RS_Billboard Make(Vector3 where, double w, double h,
		double yaw, double tilt, int payload, int data, Color col,
		int facing = LevelLocals.BBF_FIXED, int flags = 0, string text = "")
	{
		let b = new("RS_Billboard");
		b.mPayload = payload;
		b.mData    = data;
		b.mColor   = col;
		b.mW = w; b.mH = h;
		b.mId = level.AddBillboardPersistent(where, w, h, yaw, tilt,
			facing, payload, data, col,
			flags | LevelLocals.BBFL_PERSISTENT, 0, text);
		return b;
	}

	// -----------------------------------------------------------------
	// VIEW-LOCKED billboard -- the one that makes a comfortable in-world
	// HUD possible.
	//
	// `ofs` is NOT a world position: X is distance ahead of the viewer,
	// Y is right, Z is up. The engine resolves it at RENDER rate, which
	// is the whole point -- a panel we move from script can only update
	// once per tic, so it lags the head and then snaps, which in VR
	// reads as the UI swimming. This does not.
	// -----------------------------------------------------------------
	static RS_Billboard MakeViewLocked(Vector3 ofs, double w, double h,
		int payload, int data, Color col)
	{
		let b = new("RS_Billboard");
		b.mPayload = payload;
		b.mData    = data;
		b.mColor   = col;
		b.mW = w; b.mH = h;
		b.mId = level.AddBillboardPersistent(ofs, w, h, 0, 0,
			LevelLocals.BBF_CAMERAYAW, payload, data, col,
			LevelLocals.BBFL_PERSISTENT | LevelLocals.BBFL_VIEWLOCKED | LevelLocals.BBFL_NODEPTH);
		return b;
	}

	// -----------------------------------------------------------------
	// Attached to an actor. Dies with it -- which means the handle can
	// go stale underneath us, so Release() tolerates that (see below).
	// -----------------------------------------------------------------
	// FOLLOWANGLE IS ON BY DEFAULT, and that is a real decision.
	//
	// Without it an attached billboard keeps the yaw it was BORN with:
	// the actor turns and its faces stay pointing where they started, so
	// a rotating pedestal leaves its card behind. With it, yaw is
	// relative to the actor's facing and the faces turn with it. Almost
	// nothing wants the other behaviour, so it is the default and a
	// caller has to ask for the odd case.
	static RS_Billboard MakeAttached(Actor mo, Vector3 ofs, double w, double h,
		double yaw, double tilt, int payload, int data, Color col,
		int facing = LevelLocals.BBF_FIXED,
		int flags = LevelLocals.BBFL_FOLLOWANGLE)
	{
		if (!mo) return null;
		let b = new("RS_Billboard");
		b.mPayload = payload;
		b.mData    = data;
		b.mColor   = col;
		b.mW = w; b.mH = h;
		b.mId = level.AttachBillboard(mo, ofs, w, h, yaw, tilt,
			facing, payload, data, col, flags);
		return b;
	}

	// --- mutation ------------------------------------------------------
	void SetData(int data, Color col)
	{
		if (!mId) return;
		mData = data; mColor = col;
		level.UpdateBillboard(mId, data, col);
	}

	void MoveTo(Vector3 where)
	{
		if (mId) level.MoveBillboard(mId, where);
	}

	void Orient(double yaw, double tilt, int facing = LevelLocals.BBF_FIXED)
	{
		if (mId) level.OrientBillboard(mId, yaw, tilt, facing);
	}

	void Resize(double w, double h)
	{
		if (!mId) return;
		mW = w; mH = h;
		level.ResizeBillboard(mId, w, h);
	}

	void SetAlpha(double a)
	{
		if (mId) level.SetBillboardAlpha(mId, clamp(a, 0.0, 1.0));
	}

	// -----------------------------------------------------------------
	// SDF-ERA CAPABILITIES. Added 2026-08-09.
	//
	// Separate setters rather than arguments, and that is NOT a style
	// choice: the sfd lane found that AddBillboard/AddBillboardPersistent/
	// AttachBillboard CRASH THE ZSCRIPT COMPILER at sixteen arguments --
	// silently, no error, the log simply ends mid-sentence part way
	// through LoadActors. Fourteen is fine. Never grow those signatures;
	// grow this block instead.
	// -----------------------------------------------------------------

	// Neon falloff around the shape. radius and strength are BOTH 0..1
	// and the engine clamps them, so the square-clipping artifact warned
	// about in hw_sdffont.h cannot be reached from here -- that was
	// measured in their offline preview tool, where nothing clamps.
	// 1.0 is the maximum and is safe.
	void SetGlow(double radius, double strength)
	{
		if (mId) level.SetBillboardGlow(mId, clamp(radius, 0.0, 1.0),
			clamp(strength, 0.0, 1.0));
	}

	// Second colour for a gradient. Rides uObjectColor2, whose ALPHA is
	// the on switch -- so a col2 with zero alpha means "no gradient",
	// which is why this takes a full Color rather than an RGB triple.
	void SetGradient(Color col2)
	{
		if (mId) level.SetBillboardGradient(mId, col2);
	}

	// Change what a BB_TEXT says without rebuilding the panel around it.
	void SetText(string t)
	{
		if (mId) level.SetBillboardText(mId, t);
	}

	// HOW FAR OPEN a payload that opens is, 0..1.
	//
	// BB_SEAM is a slit whose width this drives. BB_SEGMENT draws a bare
	// plate below about 0.55 and its characters above -- so animating
	// this makes a readout switch on like a display waking rather than
	// simply appearing, which is what a level-up reveal wants.
	//
	// Deliberately has NO easing of its own: the shader carries no
	// progress curve, so the ramp, the hold and the reverse all belong to
	// the caller. Both card sessions asked for this wrapper independently.
	void SetProgress(double t)
	{
		if (mId) level.SetBillboardProgress(mId, clamp(t, 0.0, 1.0));
	}

	// -----------------------------------------------------------------
	// RELEASE. Call it. Every path that drops one of these must call it.
	//
	// Idempotent by design: mId is zeroed first, so a double Release is
	// a no-op rather than removing a handle the engine may since have
	// reissued to somebody else. That specific hazard is why this is not
	// just an inline RemoveBillboard at each call site.
	// -----------------------------------------------------------------
	void Release()
	{
		if (!mId) return;
		int id = mId;
		mId = 0;
		level.RemoveBillboard(id);
	}
}

// =====================================================================
// RS_BillboardGroup -- several billboards handled as one screen.
//
// The same job RS_PanelAssembly does for RF_FLATSPRITE panels, minus
// the actors. A group owns its handles and releases all of them in one
// call, which is what stops a screen leaking when the player walks away
// mid-interaction -- the exact bug found in the drop card, where a
// pedestal destroyed by anything other than the take path left its
// panels registered and repainting forever.
// =====================================================================
class RS_BillboardGroup : Object
{
	Array<RS_Billboard> mParts;

	// Row metadata, parallel to mParts, so a hit on a handle can be
	// resolved back to WHICH ROW was hit without a second lookup
	// structure. -1 means "not a selectable row" (backdrop, title, bar).
	Array<int> mRowOf;

	RS_Billboard Add(RS_Billboard b, int rowIndex = -1)
	{
		if (!b) return null;
		mParts.Push(b);
		mRowOf.Push(rowIndex);
		return b;
	}

	// Which row a native hit id belongs to, or -1.
	int RowForHandle(int id) const
	{
		if (id == 0) return -1;
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i] && mParts[i].Handle() == id)
				return mRowOf[i];
		return -1;
	}

	void SetAlphaAll(double a)
	{
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i]) mParts[i].SetAlpha(a);
	}

	// Recolour just the parts belonging to one row -- the highlight.
	void TintRow(int row, Color c)
	{
		for (int i = 0; i < mParts.Size(); i++)
			if (mRowOf[i] == row && mParts[i])
				mParts[i].SetData(mParts[i].mData, c);
	}

	void ReleaseAll()
	{
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i]) mParts[i].Release();
		mParts.Clear();
		mRowOf.Clear();
	}

	bool Empty() const { return mParts.Size() == 0; }
}
