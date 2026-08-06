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
	//                                R = (sin y, -cos y, 0)   [viewer's right]
	//                                U = (0, 0, 1)
	// Tilting by t rotates U toward -F, which leans the TOP toward the
	// viewer for positive t.
	// -----------------------------------------------------------------
	Vector3 FaceVec() const
	{
		return (cos(mYaw), sin(mYaw), 0);
	}

	Vector3 RightVec() const
	{
		return (sin(mYaw), -cos(mYaw), 0);
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

	static RS_PanelAssembly Create(Actor anchor, Vector3 ofs)
	{
		let a = new("RS_PanelAssembly");
		a.mAnchor    = anchor;
		a.mAnchorOfs = ofs;
		a.mAlive     = true;
		return a;
	}

	RS_Panel AddRoot(string canvasName, double w, double h)
	{
		Vector3 where = mAnchor ? mAnchor.pos : (0, 0, 0);
		let p = RS_Panel.Create(where, canvasName, w, h, mPanels.Size());
		if (!p) return null;
		p.mFacing = RSPF_CameraYaw;
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
