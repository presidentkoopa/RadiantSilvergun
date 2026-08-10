// =====================================================================
// RS_Panel -- a world-oriented textured quad. The primitive every
// in-world menu in this mod is built out of.
//
// WHY THIS IS AN ACTOR AND NOT AN ENGINE CALL (2026-08-06)
// -----------------------------------------------------------------
// GZDoom already draws arbitrarily-oriented textured quads. RF_FLATSPRITE
// builds its corners from a matrix composed out of the actor's OWN
// yaw/pitch/roll with no view vector anywhere in it, and Actor.picnum is
// a settable TextureID that the sprite path honours as a direct texture
// override -- the engine's own comment calls it "CustomSprite-style
// direct picnum specification". An actor with +FLATSPRITE +ROLLSPRITE
// and picnum pointed at a canvas texture IS a panel, today, with no
// engine change at all.
//
// TNT1 is deliberate and correct: the visibility gate reads
// `sprite == 0 && !isPicnumOverride`, and TNT1 is sprite index 0, so a
// valid picnum is exactly what keeps it drawing. Do not "fix" this by
// giving it a real sprite.
//
// A native primitive replaces the backend later -- for scale (hundreds
// of panels without an Actor apiece) and for the aim ray. The API in
// this file is deliberately the API the native version keeps, so
// swapping the backend does not touch a single caller.
//
// FACING IS A MODE, NOT THE DEFINITION
// -----------------------------------------------------------------
// A panel that always turns to face the camera CANNOT be linked to
// another panel at an angle -- if both turn independently, the angle
// between them stops meaning anything and a hinged assembly collapses
// into parallel planes. So facing is per-panel:
//     RSPF_Fixed      use my own orientation, inherited from my parent
//     RSPF_CameraYaw  turn to the viewer, stay upright
//     RSPF_Camera     turn to the viewer including tilt
// A triptych is ONE CameraYaw root with Fixed children hinged off it.
//
// ORIENTATION IS STORED IN DESIGN SPACE, NOT ENGINE SPACE
// -----------------------------------------------------------------
// mYaw/mTilt are what a human means: which way it faces, and how far
// its top leans. The engine's FLATSPRITE pitch needs a bias to stand a
// floor-aligned quad upright, and which sign that is depends on the
// build. That bias lives in ONE place (RS_PanelController.PitchBias)
// and is cvar-driven, so a wrong guess is a five-second fix in the
// headset instead of a rebuild.
// =====================================================================

enum ERS_PanelFacing
{
	RSPF_Fixed      = 0,
	RSPF_CameraYaw  = 1,
	RSPF_Camera     = 2
}

// Which edge of a panel a hinge attaches to.
enum ERS_PanelEdge
{
	RSPE_Right  = 0,
	RSPE_Left   = 1,
	RSPE_Top    = 2,
	RSPE_Bottom = 3
}

// Which primitive draws a panel. BOTH ARE SUPPORTED AND BOTH ARE
// CORRECT FOR DIFFERENT JOBS -- this is not a migration with an old side
// and a new side. Owner ruling 2026-08-07: "i want to still have
// flatsprites for thigns ... as long as I can have the ability for both".
enum ERS_PanelBackend
{
	RSPB_Flatsprite = 0,   // an Actor with +FLATSPRITE and a picnum
	RSPB_Billboard  = 1,   // one engine billboard showing this panel's canvas
	RSPB_Composed   = 2    // many payload billboards, no canvas at all
}

class RS_Panel : Actor
{
	// --- identity -------------------------------------------------
	string   mCanvas;        // canvas texture lump name, e.g. "RSPNL01"
	int      mSlot;          // index within its assembly; also the sort key

	// --- size, in MAP UNITS, FULL EXTENT --------------------------
	// FULL extent, not half-extent. A panel with mWidth 48 measures 48
	// units edge to edge. This is written down because the previous
	// engine's `size` parameter was ambiguous and nobody could tell
	// which it meant -- and for a hinge it is the difference between
	// wings that meet the centre panel exactly and wings that overlap
	// it or leave a seam.
	double   mWidth, mHeight;

	// The unscaled size, set once at Create and never touched by the
	// approach ramp. mWidth is the DRAWN size and changes every tic; this
	// is the size the card's layout is solved at. Keeping them apart is
	// what lets a card be born collapsed inside the drop's glow and still
	// know how big it is meant to become.
	double   mBaseW, mBaseH;

	// --- orientation, DESIGN SPACE --------------------------------
	double   mYaw;           // which way the face points
	double   mTilt;          // 0 = vertical; + leans the top toward the viewer
	int      mFacing;

	// --- linkage --------------------------------------------------
	RS_Panel mParent;
	int      mHingeParentEdge;
	int      mHingeMyEdge;
	double   mHingeAngle;
	bool     mHinged;

	// --- backend ------------------------------------------------------
	// Which primitive actually draws this panel. See SetBackend() for the
	// full reasoning; the short version is that a flatsprite is an actor
	// and cannot be locked to the view without swimming, and a billboard
	// can. Everything else about a panel is identical either way.
	int          mBackend;   // ERS_PanelBackend
	RS_Billboard mBB;        // null unless mBackend == RSPB_Billboard

	// [BB] Composed backend. The panel stops being a picture entirely and
	// becomes a transform that a pile of payload billboards ride on, so it
	// costs no canvastexture -- which is the whole point, since canvases are
	// the thing there are only eleven of.
	//
	// mComposed holds the parts and their panel-local offsets; mContent is
	// what to lay out. Content is held rather than laid out immediately
	// because Create() runs before the assembly has solved a transform, and
	// laying out into an unsolved panel would place every part at the origin.
	RS_BBComposedPanel mComposed;
	Weapon             mContentWeapon;
	string             mContentHeading;
	bool               mContentDirty;
	Color        mTint;      // last SetTint, replayed onto the billboard

	Vector3  mAnchorOfs;     // root panels only: offset from the anchor actor
	Actor    mAnchor;        // root panels only: what the assembly hangs on

	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+FLATSPRITE
		+ROLLSPRITE
		+BRIGHT
		+NOTONAUTOMAP
		Radius 1;
		Height 1;
		RenderStyle "Translucent";
		Alpha 1.0;
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	// -----------------------------------------------------------------
	// Construction
	// -----------------------------------------------------------------
	static RS_Panel Create(Vector3 where, string canvasName, double w, double h, int slot = 0)
	{
		let p = RS_Panel(Actor.Spawn("RS_Panel", where));
		if (!p) return null;

		p.mCanvas = canvasName;
		p.mWidth  = w;
		p.mHeight = h;
		// THE SIZE THE CARD IS LAID OUT AT, kept apart from the size it is
		// currently DRAWN at. mWidth is scaled every tic by the drop's
		// approach ramp; this is not.
		p.mBaseW  = w;
		p.mBaseH  = h;
		p.mSlot   = slot;
		p.mFacing = RSPF_Fixed;
		p.mYaw    = 0;
		p.mTilt   = 0;

		p.BindCanvas();
		return p;
	}

	// Point picnum at the canvas and scale the quad to the requested
	// map-unit size. Scale must be assigned at runtime -- a Default
	// block cannot express a non-uniform scale at all (the engine's
	// scale property takes ONE float and writes X and Y together).
	void BindCanvas()
	{
		if (mCanvas == "") return;

		TextureID t = TexMan.CheckForTexture(mCanvas, TexMan.Type_Any);
		if (!t.IsValid()) return;

		picnum = t;

		Vector2 texels = TexMan.GetScaledSize(t);
		if (texels.x > 0 && texels.y > 0)
			Scale = (mWidth / texels.x, mHeight / texels.y);
	}

	// -----------------------------------------------------------------
	// Tint a panel through the stencil path.
	//
	// AddStencil draws the texture's SHAPE in a flat fillcolor, added
	// to the scene -- so one white gradient canvas becomes a glow of
	// any colour without a second texture. That is how every drop beam
	// in a map shares a single canvas and still reads its own tier.
	// -----------------------------------------------------------------
	void SetTint(Color c)
	{
		// Remembered as well as applied, because the BILLBOARD backend
		// takes its colour as a call argument rather than reading the
		// actor's shade -- without a stored copy, a tint set before the
		// backend swap would be lost on the next sync.
		mTint = c;

		// fillcolor is `native READONLY color` (actor.zs:120) and its own
		// comment says it "must be set with SetShade to initialize
		// correctly" -- assigning it directly is the "Expression must be a
		// modifiable value" error, and would skip that initialization even
		// if it compiled.
		SetShade(c);
		A_SetRenderStyle(alpha, STYLE_AddStencil);
	}

	// -----------------------------------------------------------------
	// Basis vectors in design space.
	//
	// Facing yaw y with zero tilt:   F = (cos y, sin y, 0)
	//                                R = (-sin y, cos y, 0)   [viewer's right]
	//                                U = (0, 0, 1)
	// Tilting by t rotates U toward -F, which leans the TOP toward the
	// viewer for positive t.
	//
	// *** RIGHT WAS (sin y, -cos y). CORRECTED 2026-08-08. ***
	//
	// That is the viewer's LEFT, and it is the same inversion the engine
	// carried in three places until the same day (BillboardBasis, in
	// g_levellocals.h, is where the derivation lives now). The mod's own
	// drawing side was ALREADY right -- RS_BBCompose.RightOf returns
	// (-sin, cos) and lays every composed part out with it -- so this file
	// and that one disagreed about which way a panel runs, and the two
	// things that disagreed were WHERE A PANEL IS DRAWN and WHERE IT IS
	// TOUCHED.
	//
	// What it actually broke, all of it silent:
	//
	//   * HingeTo/SolveFromParent walk to a parent's edge along this
	//     vector, so RSPE_Left placed a wing on the reader's RIGHT. The
	//     drop card's OFFHAND wing sat where the mainhand wing looked like
	//     it should be -- and since the Hand Law is "the hand that touches
	//     is the hand that receives", reaching left handed you the wrong
	//     gun. This is the "wings are on swapped sides" note in
	//     docs/rs_state_20260808.md, and this is its cause.
	//   * PanelUnderHand and TraceHand both build u from `local dot
	//     RightVec()`, so every uv was mirrored: the row you pressed was
	//     the row's mirror image across the panel's centre line. On a card
	//     whose only live rows are single lines on the wings, that reads
	//     as "the panel ignores me", not as a mirror.
	//
	// FaceVec is deliberately left flat -- it is the yaw-only face
	// direction, used for "is this panel pointing at me" and for the punch
	// test, both of which want the horizontal answer. The true face normal
	// of a TILTED panel is RightVec cross UpVec; nothing here needs it,
	// and the drop card runs at tilt 0.
	// -----------------------------------------------------------------
	Vector3 FaceVec() const
	{
		return (cos(mYaw), sin(mYaw), 0);
	}

	Vector3 RightVec() const
	{
		return (-sin(mYaw), cos(mYaw), 0);
	}

	Vector3 UpVec() const
	{
		double st = sin(mTilt), ct = cos(mTilt);
		return (-st * cos(mYaw), -st * sin(mYaw), ct);
	}

	// -----------------------------------------------------------------
	// HINGES -- the reason the transform is a graph and not a list.
	//
	// A wing does NOT rotate about the centre panel's middle. It rotates
	// about the SHARED EDGE. Parented at the centre and given a yaw, it
	// swings straight through the centre panel; hinged at the edge, it
	// folds the way a triptych actually folds. So the child's placement
	// is: walk to the parent's edge, rotate, then extend by the child's
	// own half-extent along its NEW axis.
	//
	// Expressed the way you would say it out loud:
	//     wing.HingeTo(centre, RSPE_Right, RSPE_Left, -35);
	// "attach my left edge to the centre's right edge, canted 35 in."
	//
	// It recomputes from live widths, so changing a panel's size does
	// not silently open a seam or overlap the neighbour.
	// -----------------------------------------------------------------
	void HingeTo(RS_Panel parent, int parentEdge, int myEdge, double degrees)
	{
		mParent           = parent;
		mHingeParentEdge  = parentEdge;
		mHingeMyEdge      = myEdge;
		mHingeAngle       = degrees;
		mHinged           = true;
		mFacing           = RSPF_Fixed;   // a hinged panel never faces the camera
	}

	void SolveFromParent()
	{
		if (!mHinged || !mParent) return;

		Vector3 hinge;
		double  newYaw  = mParent.mYaw;
		double  newTilt = mParent.mTilt;

		// Step 1 -- walk to the hinge point on the parent's edge.
		if (mHingeParentEdge == RSPE_Right)
			hinge = mParent.pos + mParent.RightVec() * (mParent.mWidth * 0.5);
		else if (mHingeParentEdge == RSPE_Left)
			hinge = mParent.pos - mParent.RightVec() * (mParent.mWidth * 0.5);
		else if (mHingeParentEdge == RSPE_Top)
			hinge = mParent.pos + mParent.UpVec() * (mParent.mHeight * 0.5);
		else
			hinge = mParent.pos - mParent.UpVec() * (mParent.mHeight * 0.5);

		// Step 2 -- rotate. A left/right hinge swings in yaw; a
		// top/bottom hinge swings in tilt. That is what makes a stacked
		// column curve toward the reader instead of fanning sideways.
		if (mHingeParentEdge == RSPE_Right || mHingeParentEdge == RSPE_Left)
			newYaw = mParent.mYaw + mHingeAngle;
		else
			newTilt = mParent.mTilt + mHingeAngle;

		mYaw  = newYaw;
		mTilt = newTilt;

		// Step 3 -- extend by MY half-extent along MY new axis, from the
		// edge of mine that is doing the attaching.
		Vector3 place;
		if (mHingeMyEdge == RSPE_Left)
			place = hinge + RightVec() * (mWidth * 0.5);
		else if (mHingeMyEdge == RSPE_Right)
			place = hinge - RightVec() * (mWidth * 0.5);
		else if (mHingeMyEdge == RSPE_Bottom)
			place = hinge + UpVec() * (mHeight * 0.5);
		else
			place = hinge - UpVec() * (mHeight * 0.5);

		SetOrigin(place, true);
	}

	// -----------------------------------------------------------------
	// Face a point. CameraYaw keeps the panel upright, which is almost
	// always what you want for text -- a panel that pitches to track a
	// player looking down at it reads as unstable.
	// -----------------------------------------------------------------
	void FaceViewer(Vector3 eye)
	{
		if (mFacing == RSPF_Fixed) return;

		Vector3 d = level.Vec3Diff(pos, eye);
		mYaw = atan2(d.y, d.x);

		if (mFacing == RSPF_Camera)
		{
			double flat = d.xy.Length();
			mTilt = -atan2(d.z, flat);
		}
		else
		{
			mTilt = 0;
		}
	}

	// -----------------------------------------------------------------
	// Push design-space orientation into engine angles.
	//
	// PitchBias stands a floor-aligned FLATSPRITE quad upright. Which
	// sign that is depends on the engine build, so it is a cvar and not
	// a constant -- see the file header.
	// -----------------------------------------------------------------
	void ApplyOrientation()
	{
		angle = mYaw;
		pitch = RS_PanelController.PitchBias() + mTilt;
		roll  = RS_PanelController.RollBias();

		SyncBackend();
	}

	// =================================================================
	// TWO BACKENDS, ONE PANEL. Added 2026-08-07 at the owner's direction:
	// "i want to still have flatsprites for thigns but yes, get on this
	// too ... as long as I can have the ability for both".
	//
	// WHICH TO USE, AND WHY IT IS NOT A PREFERENCE:
	//
	//   FLATSPRITE  anchored in the world. Drop cards on a pedestal,
	//               panels you walk around. It is an ACTOR, so the engine
	//               interpolates it for free and it needs no engine
	//               support at all -- which is why this shipped first and
	//               why it still works.
	//
	//   BILLBOARD   attached to the VIEW, or many elements at once, or
	//               needing pixel-exact hit testing.
	//
	// THE ONE THING A FLATSPRITE CANNOT DO. Script moves an actor once
	// per TIC. Anything locked to the head therefore lags a frame and
	// then snaps, which in VR reads as the UI swimming and is genuinely
	// unpleasant. BBFL_VIEWLOCKED resolves at RENDER rate. That is not an
	// optimisation problem -- there is no script rate that fixes it.
	//
	// Likewise the aim ray: AimBillboard returns the UV the SHADER used.
	// RS_PanelController's ray/plane maths returns the UV we believe the
	// shader used. Those two drift, and the drift is invisible until a
	// row stops being clickable where it looks clickable.
	//
	// HOW THE SWAP WORKS. The panel keeps owning its transform either
	// way -- position, yaw, tilt, size, and the whole hinge solver are
	// unchanged and are still correct, because they are OURS and they
	// were never the part the engine does better. Only the DRAW moves.
	// In billboard mode the actor stops rendering (bInvisible) and a
	// billboard handle is created at the same transform and updated with
	// it. Nothing above this line, and no caller, changes.
	//
	// HINGES SURVIVE THE SWAP, and that is not luck. A BBF_FIXED
	// billboard keeps the explicit yaw/tilt it is given:
	// HWSprite::CalculateVertices opens with an early return for
	// billboards (hw_sprites.cpp:417) that copies the four corners
	// straight out of bbVerts, skipping the RF_FLATSPRITE rotation
	// matrix and all camera-facing logic below it. Without that bypass a
	// hinged assembly would be re-oriented downstream and collapse into
	// parallel planes. Verified in the engine source before this was
	// written, because the whole triptych depends on it.
	//
	// WHAT THIS DOES *NOT* SOLVE: canvases. A BB_TEXTURE billboard still
	// needs a hand-declared ANIMDEFS canvas, and two billboards sharing
	// one canvas show the SAME PICTURE -- eleven exist and a triptych
	// spends nine. So swapping backends buys view-locking and native aim,
	// NOT more screens. For readouts that should cost zero textures, use
	// the composed path (RS_BBCompose.zs) instead of a panel at all.
	// Panels are for artwork; composition is for numbers and bars.
	// =================================================================
	void SetBackend(int backend)
	{
		if (mBackend == backend) return;
		mBackend = backend;

		// Leaving a backend always hands its resources back first. A handle
		// dropped without Release is a leak the collector cannot see, and
		// switching backend at runtime is exactly when that would happen.
		if (mBB) { mBB.Release(); mBB = null; }
		if (mComposed) { mComposed.ReleaseAll(); mComposed = null; }

		if (mBackend == RSPB_Flatsprite)
		{
			bInvisible = false;
			return;
		}

		bInvisible = true;   // the actor is now a transform, not a picture
		mContentDirty = true;
		SyncBackend();
	}

	// -----------------------------------------------------------------
	// What a composed panel should say. Held until the next SyncBackend
	// rather than laid out now, because a panel is created before the
	// assembly solves its transform and a layout done here would place
	// every part at the world origin.
	// -----------------------------------------------------------------
	void SetContent(Weapon wep, string heading)
	{
		mContentWeapon  = wep;
		mContentHeading = heading;
		mContentDirty   = true;
	}

	// Create or update the billboard to match this panel's transform.
	// Cheap no-op in flatsprite mode, which is why ApplyOrientation can
	// call it unconditionally.
	void SyncBackend()
	{
		if (mBackend == RSPB_Composed)
		{
			if (!mComposed) mComposed = new("RS_BBComposedPanel");

			// Lay out only when the content changed. A panel re-aims every
			// tic, so rebuilding here would destroy and recreate forty
			// billboards per tic for a player who is merely walking.
			if (mContentDirty)
			{
				// BUILD AT FULL SIZE, ALWAYS. Fixed 2026-08-10.
				//
				// This used to build at mWidth/mHeight, and that is why an
				// elite drop's card never grew. The approach ramp shrinks
				// mWidth to rs_drop_cardminscale BEFORE the first
				// SyncBackend runs, so the compositor captured a 2%-size
				// card as its BASE -- and RS_BBComposedPanel.Rescale scales
				// from that base, so Rescale(1.0) standing on top of the
				// drop returned 100% OF 2%. The card was built collapsed
				// and could never expand out of the point it started in.
				//
				// It presents as "the cards don't appear", not as a scaling
				// bug, because 2% of a six-unit card is smaller than a
				// pixel at any range you could read it from.
				mComposed.ReleaseAll();
				RS_BBWeaponCard.Build(mComposed, mBaseW, mBaseH,
					mContentWeapon, mContentHeading);
				mContentDirty = false;
			}

			// Then take it down to whatever the ramp currently wants. The
			// ratio is the single source of the card's scale -- nothing
			// else may set it, or the base drifts again.
			if (mBaseW > 0)
				mComposed.Rescale(mWidth / mBaseW);

			// Moving is the cheap path: no allocation, no handles touched,
			// just every part repositioned from the offset it remembers.
			mComposed.Place(pos, mYaw, mTilt);
			return;
		}

		if (mBackend != RSPB_Billboard) return;

		TextureID t = TexMan.CheckForTexture(mCanvas, TexMan.Type_Any);
		if (!t.IsValid()) return;

		double bbTilt = mTilt;

		if (!mBB)
		{
			mBB = RS_Billboard.Make(pos, mWidth, mHeight, mYaw, bbTilt,
				LevelLocals.BB_TEXTURE, t.GetIndex(),
				mTint == 0 ? Color(255, 255, 255) : mTint,
				LevelLocals.BBF_FIXED);
			return;
		}

		mBB.MoveTo(pos);
		mBB.Orient(mYaw, bbTilt, LevelLocals.BBF_FIXED);
		mBB.SetData(t.GetIndex(), mTint == 0 ? Color(255, 255, 255) : mTint);
	}

	// The handle is not garbage-collectable -- it is an integer the engine
	// hands out, and dropping it without RemoveBillboard leaks a quad that
	// survives until the level ends. Every path that destroys a panel must
	// come through here.
	override void OnDestroy()
	{
		if (mBB) { mBB.Release(); mBB = null; }
		if (mComposed) { mComposed.ReleaseAll(); mComposed = null; }
		Super.OnDestroy();
	}

	// The billboard handle, for the controller's native aim. 0 when this
	// panel is a flatsprite, which is also the engine's own "no hit"
	// value -- so a flatsprite can never be matched by a stray hit id.
	int BillboardHandle() const
	{
		return mBB ? mBB.Handle() : 0;
	}

	// Does this panel own the native hit id? A composed panel has no single
	// handle -- it is dozens -- so aim has to ask rather than compare, or
	// pointing at a composed card would never resolve to anything.
	bool OwnsBillboard(int id) const
	{
		if (id == 0) return false;
		if (mBB && mBB.Handle() == id) return true;
		return mComposed && mComposed.OwnsHandle(id);
	}

	override void Tick()
	{
		// Super.Tick() IS called, despite a panel having no physics and
		// no state advance. NOINTERACTION already makes it nearly free,
		// and skipping it stops the engine updating PrevAngles -- which
		// a panel that re-aims every tic needs, or its rotation
		// interpolates from stale angles and judders.
		Super.Tick();
	}
}

// =====================================================================
// RS_PanelAssembly -- a rigid group of panels solved as one object.
//
// This is what makes "link billboards together at angles" real. The
// assembly owns an ORDERED list: index 0 is the root, and every later
// panel resolves against one already solved. Solving top-down in that
// order means a hinge chain of any depth costs one pass and cannot
// reference an unsolved parent.
//
// Sort stability matters here and is not obvious. The engine sorts
// translucent quads by a HORIZONTAL depth projection with a tie-break
// on `index`, and a vertically stacked column has IDENTICAL depth for
// every panel in it. Left alone, the tie falls through to BSP traversal
// order, which changes as the camera moves -- panels would pop past
// each other as you walk. Every panel therefore gets a distinct,
// stable slot number, ascending away from the reader.
// =====================================================================
// `play` is load-bearing, not decoration. An unscoped Object subclass is
// DATA scope, and data scope cannot call a play function -- which is every
// method this class exists to call (RS_Panel.Create, SetOrigin, FaceViewer,
// Destroy). Without it the class produces ~15 errors that all read as
// "Can't call play function X from data context", plus cascading "Unknown
// identifier" noise from the assignments that failed above them.
class RS_PanelAssembly play
{
	Array<RS_Panel> mPanels;
	Actor           mAnchor;
	Vector3         mAnchorOfs;
	bool            mAlive;

	// COMFORT MODE -- the card belongs to the READER, not to the thing
	// it describes. In this mode the assembly does not sit ON its
	// anchor; it sits a fixed, comfortable distance in front of the
	// player, on the line toward the anchor, at eye level. Walk right
	// up to a drop and the card holds its reading distance instead of
	// being shoved into your face; back off and it follows.
	bool            mComfort;
	double          mComfortDist;

	// Backend for every panel in this assembly. Set it BEFORE adding
	// panels and they are born correct; set it after and SetBackend()
	// swaps the live ones over, which is safe but does a texture lookup
	// per panel, so prefer the former.
	//
	// DEFAULTS TO FLATSPRITE, deliberately. That is the backend that is
	// known to work in this mod today -- the drop cards are the one
	// in-world thing that has been seen running -- so nothing silently
	// changes rendering path just because billboards now exist. A screen
	// opts IN.
	int             mBackend;

	static RS_PanelAssembly Create(Actor anchor, Vector3 ofs)
	{
		let a = new("RS_PanelAssembly");
		a.mAnchor    = anchor;
		a.mAnchorOfs = ofs;
		a.mAlive     = true;
		a.mBackend   = RSPB_Flatsprite;
		return a;
	}

	// Switch the whole assembly, live panels included.
	void SetBackend(int backend)
	{
		mBackend = backend;
		for (int i = 0; i < mPanels.Size(); i++)
			if (mPanels[i]) mPanels[i].SetBackend(backend);
	}

	// Resolve a native billboard hit id back to a panel index, or -1.
	// This is what lets RS_PanelController use AimBillboard instead of
	// its own ray/plane maths when an assembly is on the billboard
	// backend -- the engine returns a handle, and only the assembly knows
	// which of its panels owns it.
	int PanelForHandle(int id) const
	{
		if (id == 0) return -1;
		// Asks rather than compares, because a composed panel has no single
		// handle -- it is dozens -- and comparing against one would mean
		// pointing at a composed card never resolved to anything.
		for (int i = 0; i < mPanels.Size(); i++)
			if (mPanels[i] && mPanels[i].OwnsBillboard(id))
				return i;
		return -1;
	}

	RS_Panel AddRoot(string canvasName, double w, double h)
	{
		Vector3 where = mAnchor ? mAnchor.pos : (0, 0, 0);
		let p = RS_Panel.Create(where, canvasName, w, h, mPanels.Size());
		if (!p) return null;
		p.mFacing = RSPF_CameraYaw;
		if (mBackend != RSPB_Flatsprite) p.SetBackend(mBackend);
		mPanels.Push(p);
		return p;
	}

	RS_Panel AddHinged(RS_Panel parent, int parentEdge, int myEdge,
	                   double degrees, string canvasName, double w, double h)
	{
		if (!parent) return null;
		let p = RS_Panel.Create(parent.pos, canvasName, w, h, mPanels.Size());
		if (!p) return null;
		p.HingeTo(parent, parentEdge, myEdge, degrees);
		if (mBackend != RSPB_Flatsprite) p.SetBackend(mBackend);
		mPanels.Push(p);
		return p;
	}

	// One pass, in creation order. Root first, then every hinge against
	// an already-placed parent.
	void Solve(Vector3 eye)
	{
		if (!mAlive || mPanels.Size() == 0) return;

		let root = mPanels[0];
		if (!root) return;

		// The root's height comes from live view z, never a constant:
		// in VR the eye line is the player's real room-scale height, not
		// the 41 that Player.ViewHeight assumes, so a fixed world offset
		// is right for exactly one person.
		Vector3 where;

		if (mComfort && mAnchor)
		{
			// Stand off from the reader toward the anchor. If you are
			// already closer to the drop than the comfort distance, the
			// card would end up BEHIND you -- so it clamps to the
			// anchor's own position rather than inverting.
			Vector2 flat = (mAnchor.pos.x - eye.x, mAnchor.pos.y - eye.y);
			double  d    = flat.Length();

			if (d < 1)
			{
				where = (mAnchor.pos.x, mAnchor.pos.y, eye.z + mAnchorOfs.z);
			}
			else
			{
				double reach = min(mComfortDist, d);
				Vector2 dir  = flat / d;
				where = (eye.x + dir.x * reach,
				         eye.y + dir.y * reach,
				         eye.z + mAnchorOfs.z);
			}
		}
		else
		{
			Vector3 base = mAnchor ? mAnchor.pos : root.pos;
			where = (base.x + mAnchorOfs.x,
			         base.y + mAnchorOfs.y,
			         eye.z + mAnchorOfs.z);
		}

		root.SetOrigin(where, true);
		root.FaceViewer(eye);
		root.ApplyOrientation();

		for (int i = 1; i < mPanels.Size(); i++)
		{
			let p = mPanels[i];
			if (!p) continue;
			p.SolveFromParent();
			p.ApplyOrientation();
		}
	}

	void Destroy()
	{
		for (int i = 0; i < mPanels.Size(); i++)
			if (mPanels[i]) mPanels[i].Destroy();
		mPanels.Clear();
		mAlive = false;
	}

	int Size() const
	{
		return mPanels.Size();
	}

	RS_Panel Get(int i) const
	{
		if (i < 0 || i >= mPanels.Size()) return null;
		return mPanels[i];
	}
}
