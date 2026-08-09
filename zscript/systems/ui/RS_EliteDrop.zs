// =====================================================================
// RS_EliteDrop -- the thing the triptych card is FOR.
//
// The elite system is complete: 17 types, boosted health at spawn,
// hidden until 50%, a full reveal with powers and a pentagram. What it
// has never had is a payout. RS_Elite.zs says so in its own header --
// "the weapon-tier drop arms at the reveal; the drop system itself is a
// later step" -- and the options menu already promises the player that
// "an elite killed before revealing pays nothing", describing a rule
// that nothing enforced because nothing paid at all. This is that step.
//
// THE DROP IS A PEDESTAL, NOT A WEAPON ACTOR. That is deliberate and it
// dodges two live traps at once:
//
//   1. RS_ClassGating.WorldThingSpawned DESTROYS a world-spawned
//      RS_Weapon whose family does not match the player's class, and
//      leaves a Clip behind. An elite drop that IS an RS_Weapon would
//      be eaten before the player ever saw it.
//   2. Vanilla pickup of a class the player ALREADY OWNS converts the
//      weapon to ammo and calls GoAwayAndDie -- so the rolled
//      Prototype you were comparing evaporates on touch. With six class
//      weapons and a dual-wield loadout, that is the common case, not
//      the edge case.
//
// So the pedestal holds an inert weapon instance as its payload. The
// instance is real, its stats are really rolled, and the card reads it
// directly -- but it is not in the pickup path, so neither trap fires.
// Taking it is our own transfer, not Inventory::TryPickup.
//
// TWO-STAGE PRESENCE. The pedestal always glows, at any range. The CARD
// only materialises inside RS_PanelController.CardRadius and despawns
// when you leave -- spawn/despawn on radius rather than an alpha fade,
// so a map full of drops costs a marker each and not a live panel set
// each.
// =====================================================================

// =====================================================================
// WHAT KIND OF DROP THIS IS -- the SHAPE half of the read.
//
// Colour says how good it is; SHAPE says what it is. Two facts, two
// channels, never mixed -- a player reading a room full of pillars gets
// count, quality and kind with no text at all.
//
// File scope rather than nested in a class, following ERS_PanelFacing
// and ERS_TriSlot: a nested enum referenced from another file is exactly
// the kind of resolution question that has cost this project a failed
// boot before.
// =====================================================================
enum ERS_DropKind
{
	RSDK_Weapon  = 0,   // a class weapon -- DIAMOND
	RSDK_Imprint = 1    // an imprint     -- CIRCLE
}

class RS_WeaponDrop : Actor
{
	Weapon      mPayload;    // the real, rolled instance the card reads
	RS_DropBeacon mBeacon;   // the tapering pillar and the shape on top of it
	RS_DropHalo mGlow;       // the additive tier halo worn by the payload
	bool        mCardUp;
	int         mTier;

	// Distance from the viewer as of this tic, measured ONCE in Tick and
	// read by everything that ramps with range. The card scale, the
	// pillar's growth and the marker all have to agree about how far away
	// this drop is, or they disagree at the range boundaries -- which is
	// the pop the ramp exists to remove.
	double      mViewDist;

	// ------------------------------------------------------------------
	// NON-NULL MAKES THIS AN IMPRINT OFFER RATHER THAN A CLASS WEAPON.
	//
	// Set only by RS_Imprint.Drop (zscript/systems/weapon/RS_Imprint.zs),
	// which is the late-game half of the elite payout: once the player
	// owns all six identities there is no missing weapon to hand out, so
	// the elite offers a rolled STAT PACKAGE for a gun they already
	// carry instead.
	//
	// The payload weapon is still spawned and still rolled -- it IS the
	// package's dice, and the comparison card already reads it -- but on
	// an imprint it is never handed over. Accepting writes the package
	// onto the weapon in the chosen hand and the payload is destroyed
	// with the pedestal.
	//
	// FOR THE FLOOR-VISUALS LANE: this is the branch. An imprint drop
	// currently wears the donor weapon's pickup sprite, so it looks
	// exactly like a class-weapon drop; RS_ElitePackage in this same
	// folder is the black EPKG body already built for the data drop and
	// still used by nothing.
	// ------------------------------------------------------------------
	RS_Imprint  mImprint;

	bool IsImprint() const { return mImprint != null; }

	Default
	{
		+NOGRAVITY
		+NOBLOCKMAP
		+NOINTERACTION
		+BRIGHT
		Radius 16;
		Height 16;
		// No RenderStyle/Alpha here on purpose. This actor's sprite is
		// TNT1 -- it is a positional anchor, never drawn. The visible
		// drop is its payload weapon and its beam, which carry their
		// own styles. Setting them here read as intent and did nothing.
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	// `ip` ARRIVES EMPTY AND IS FILLED BY THE CALLER AFTERWARDS, and that
	// is the whole reason it is a parameter rather than something
	// RS_Imprint.Drop assigns once this returns.
	//
	// The ordering is load-bearing: RaiseBeam() at the bottom of this
	// function reads DropKind(), which reads IsImprint(), which reads
	// mImprint. Setting the field after Create() returned would raise
	// every imprint's marker as a DIAMOND -- the class-weapon shape --
	// and nothing would ever correct it, because RaiseBeam self-guards on
	// mBeacon and never runs twice. Shape is the entire "what kind of
	// drop is that" read at range, so it would have been silently wrong
	// in exactly the case it exists for.
	//
	// The package's STATS cannot be known any earlier than they are:
	// they are read off the payload weapon this function spawns and
	// rolls. So the object is handed in empty, its identity is enough to
	// answer DropKind(), and RS_Imprint.Drop fills the numbers in a
	// moment later. Passing the KIND as an int instead would have put a
	// second source of truth next to IsImprint(); this keeps one.
	static RS_WeaponDrop Create(Vector3 where, class<Weapon> what, int tier,
	                            RS_Imprint ip = null)
	{
		let d = RS_WeaponDrop(Actor.Spawn("RS_WeaponDrop", where));
		if (!d) return null;

		d.mTier    = tier;
		d.mImprint = ip;

		// The payload IS the marker. It keeps its own pickup sprite --
		// so you can still tell a shotgun from a revolver across a room
		// -- and takes a luminance-preserving tier tint on top of it.
		// Only its pickup behaviour is removed, not its visibility.
		//
		// EXEMPTION FROM CLASS GATING -- HOW IT ACTUALLY WORKS, 2026-08-07.
		//
		// This is a world spawn of a real RS_Weapon, so it goes through
		// WorldThingSpawned like any floor pickup -- which means
		// RS_ClassGating would destroy or convert it, and Vanilla+ might
		// swap it. That is a real hazard and it needed a real exemption.
		//
		// It USED to be a boolean window: set dh.mSpawningDrop true, spawn,
		// set it false, with a comment promising "the exempt window is
		// exactly this one Spawn." That was wrong at the root, because
		// WorldThingSpawned is NOT synchronous -- the engine defers it to
		// the fresh-thinker pass (p_mobj.cpp:5164 via dthinker.cpp:602-611),
		// so the flag was always back to false by the time the payload's
		// event arrived. The exemption never once applied, and on a Dual_X
		// class every elite drop fell into the class-gating fill loop.
		//
		// THE PAYLOAD IS NOW RECOGNISED BY ITS OWN STATE instead. The
		// bSpecial=false / bNoInteraction=true pair below is set before the
		// deferred event can fire, and nothing else on a floor is ever
		// non-interactive, so RS_ClassGating simply checks that. No window,
		// nothing to keep in sync across two files, and it cannot rot the
		// way a flag did.
		let w = Weapon(Actor.Spawn(what, where));

		if (w)
		{
			w.bSpecial       = false;
			w.bNoInteraction = true;
			w.bNoGravity     = true;
			w.A_ChangeLinkFlags(1);      // bNoBlockmap is not directly assignable

			// A_ChangeLinkFlags(blockmap, sector) and ONLY the first
			// argument is passed on purpose. The second defaults to
			// FLAG_NO_CHANGE, so bNoSector is left alone
			// (actor.zs:1067-1073) -- and it has to be, because a
			// sector-unlinked actor is not in any sector's thing list and
			// is therefore never submitted for rendering. Passing a second
			// 1 here would make the drop invisible, silently, and would
			// look exactly like a sprite problem.

			// FULLBRIGHT. The tier tint is the entire rarity read, and a
			// drop lands wherever the elite died -- which is usually a
			// dark corner, where an unlit sprite renders every tier as the
			// same grey silhouette. Cleared again on take (see the take
			// branch) so the weapon does not carry it into your hands.
			w.bBright = true;

			// PICKUP-SIZED, NOT HAND-SIZED. See
			// RS_PanelController.PayloadScale for the engine reference --
			// five of the six families draw their FIRST-PERSON mesh in the
			// world at MODELDEF scale 1.35, which stands a gun the size of
			// a car on the floor. Seen running before this line existed.
			//
			// Scale is a Vector2 and the Default's copy is the honest
			// baseline: several families set their own, so a flat
			// assignment here would silently normalise them all to one
			// size and lose whatever per-weapon scaling MODELDEF and the
			// sprite art already agree on.
			w.Scale = w.default.Scale * RS_PanelController.PayloadScale();

			// Rarity tint. '%' in TRNSLATE is a DESATURATED remap: the
			// engine interpolates along the range using each pixel's
			// LUMINANCE, so shading and shape survive and only hue
			// changes. A plain index remap would scramble the sprite,
			// because Doom's palette is not ordered by brightness.
			w.A_SetTranslation(RS_PanelController.TierTranslation(tier));

			// Soft dynamic light in the tier colour. Attached to the
			// weapon rather than the pedestal so it sits where the
			// object visually is.
			//
			// LF_ATTENUATE is what makes it SOFT rather than merely small.
			// Without it a dynamic light falls off linearly and ends in a
			// visible disc on the floor; attenuated lights use the
			// inverse-square falloff, which reads as a glow around the
			// object instead of a spotlight under it. The flag lives on
			// DynamicLight (dynlights.zs:36) next to the light type this
			// call already names.
			//
			// radius2 is inert for a plain PointLight -- only the pulse
			// and flicker types read the second intensity -- so it is left
			// at half the first purely so the number means something if
			// the type is ever changed.
			//
			// SOFTNESS IS A SETTING, because "soft" costs something. An
			// attenuated light is the inverse-square one and it is what
			// the owner asked for; a plain one is cheaper on a machine
			// that is struggling, and 0 turns the light off entirely for
			// anyone who finds a lit floor distracting in a headset.
			// Radius stays on its own slider -- the two are different
			// questions and a single "quality" dial would conflate them.
			Color glow = RS_PanelController.TierGlow(tier);
			if (RS_PanelController.LightDetail() > 0 &&
			    RS_PanelController.LightRadius() > 0)
			{
				w.A_AttachLight('RSDropGlow', DynamicLight.PointLight, glow,
					RS_PanelController.LightRadius(),
					RS_PanelController.LightRadius() / 2,
					RS_PanelController.LightFlags(), (0, 0, 8));
			}

			// THE GLOW ON THE SPRITE ITSELF, which the translation above
			// is NOT. A translation only re-maps the colours already in
			// the sprite; it cannot make the object brighter than its own
			// art, so a Prototype and a Trash differed only in hue. The
			// halo is a second copy of the SAME silhouette, one size up,
			// drawn additively in the tier colour -- so the object appears
			// to be emitting its rarity rather than painted with it.
			d.mGlow = RS_DropHalo.Create(w, glow);

			// Every world spawn in this project hardcodes VRT_Basic --
			// PostBeginPlay rolls Basic and nothing else ever re-rolls.
			// An elite drop that is meant to span the ladder has to say
			// so explicitly. RollStats is per-instance and re-callable,
			// so this is cheap and it is the ONLY way a non-Basic
			// weapon reaches the world today.
			let rsw = RS_Weapon(w);
			// EVR_Tier(x) is not a cast -- ZScript has no enum-constructor
			// syntax, so it parses as a call to an undefined function. An
			// int converts to the enum parameter on its own.
			if (rsw)
			{
				rsw.RollStats(tier);

				// RE-ANCHOR THE PROMOTION/CEILING BASELINE ON THE ROLL THE
				// PLAYER ACTUALLY GETS. PostBeginPlay already rolled this
				// weapon at Basic a moment ago and captured THAT number as
				// the baseline; the RollStats above then replaced every
				// stat with the real tier's roll, but the capture is
				// "once only" and kept the stale Basic figure. Everything
				// measured against the baseline was therefore measured
				// against a roll that never appeared on the weapon --
				// GetDamageCeiling(), the damage-card gate, and the
				// state-ladder tracer body, which sat pinned at "Peak" on
				// every elite drop in the game.
				rsw.ResetDamageBaseline();
				rsw.CaptureInitialDamageBaseline();
			}

			d.mPayload = w;
		}

		d.RaiseBeam();
		return d;
	}

	// -----------------------------------------------------------------
	// THE LIGHT PILLAR. A thin vertical shaft rising out of the pickup
	// and tapering to nothing around eye level, so a drop reads from
	// across a room without a HUD marker painted on your face.
	//
	// It is a PANEL, not a stack of sprite actors: one camera-facing
	// quad wearing a shared gradient canvas, tinted per tier through
	// AddStencil. So every beam in a map costs one canvas between them
	// and one quad each, and the taper is exact rather than approximated
	// by stepping alpha down a column of actors.
	//
	// WHY IT STAYS ON THE FLATSPRITE BACKEND. Checked 2026-08-08 against
	// the engine, because RS_Panel now offers three and picking by taste
	// would have been a coin flip:
	//
	//   RSPB_Billboard is WRONG HERE, and for one disqualifying reason:
	//   ProcessBillboard hardcodes `RenderStyle = STYLE_Translucent`
	//   (hw_sprites.cpp:2014) and the billboard API has no renderstyle
	//   argument at all -- colour is a tint, not a blend mode. A light
	//   shaft is ADDITIVE or it is not a light shaft; a translucent
	//   tinted quad standing in a room is a coloured slab you can see
	//   the wall through. Everything else about the backend is better
	//   for this job (facing resolves at render rate rather than per
	//   tic, no actor, no swim in VR) and none of it matters against
	//   that. If the engine ever takes a blend mode on a billboard, this
	//   is the first thing that should move.
	//
	//   RSPB_Composed is wrong by definition -- it is a transform with
	//   no canvas, for readouts assembled out of bars and digits. There
	//   is no artwork path in it.
	//
	//   RSPB_Flatsprite CAN be additive: SetTint goes through
	//   A_SetRenderStyle(alpha, STYLE_AddStencil), which draws the
	//   gradient's SHAPE in the tier colour with DestAlpha = One. The
	//   painted alpha ramp survives as coverage, so the taper is real.
	// -----------------------------------------------------------------
	void RaiseBeam()
	{
		if (mBeacon) return;

		// THE KIND IS READ, NOT PASSED. mImprint is already set by
		// RS_Imprint.Drop before this runs, and IsImprint() is the only
		// question the shape has to answer -- so there is no second
		// "kind" argument to keep in step with it, and a future third
		// drop type changes DropKind() and nothing else.
		mBeacon = RS_DropBeacon.Create(pos, mTier, DropKind());
	}

	// DIAMOND for a class weapon, CIRCLE for an imprint. Shape carries
	// WHAT; colour carries HOW GOOD. Neither ever carries both, which is
	// what lets a player read a room full of drops without text.
	int DropKind() const
	{
		return IsImprint() ? RSDK_Imprint : RSDK_Weapon;
	}

	override void Tick()
	{
		Super.Tick();
		if (!mPayload) { Destroy(); return; }

		// Keep the payload with the pedestal so a card reading it never
		// finds it somewhere else.
		mPayload.SetOrigin(pos, true);

		PlayerPawn viewer = players[consoleplayer].mo;
		if (!viewer) return;

		// ONE DISTANCE, MEASURED ONCE, USED BY EVERYTHING.
		//
		// The pillar's growth, the marker's visibility and the card's
		// scale are all functions of the same number, and they have to
		// be the SAME number or the three ranges disagree at their
		// boundaries -- which is exactly how a "continuous" ramp ends up
		// popping anyway.
		mViewDist = (pos - viewer.pos).Length();

		// The marker hides while this drop's card is up: the card
		// REPLACES the marker, it does not stand next to it.
		if (mBeacon) mBeacon.Update(pos, mViewDist, !mCardUp);

		let handler = RS_PanelDropHandler(EventHandler.Find("RS_PanelDropHandler"));
		if (handler) handler.ConsiderDrop(self);
	}

	override void OnDestroy()
	{
		if (mPayload) mPayload.Destroy();
		if (mBeacon)  mBeacon.Release();
		if (mGlow)    mGlow.Destroy();
		Super.OnDestroy();
	}
}

// =====================================================================
// RS_DropBeacon -- the FAR half of the three-range presence, and the
// only part of a drop that is meant to be read from across a level.
//
// Two pieces, and the split is the whole design:
//
//   THE PILLAR   a tapering shaft of light in the drop's TIER COLOUR.
//                It answers "there is a drop there, and how good is
//                it" at any range, with no text and no HUD marker.
//   THE MARKER   a small shape sitting on top of the pillar. It
//                answers "what KIND of drop" -- DIAMOND for a class
//                weapon, CIRCLE for an imprint.
//
// Colour is quality, shape is kind, and NEITHER is ever asked to carry
// the other. That is what makes a room full of drops legible: count the
// pillars, read their colours, read their shapes, and you know
// everything before you have walked a step.
//
// WHY IT IS ITS OWN OBJECT. RS_WeaponDrop and RS_ElitePackage both need
// exactly this and had two hand-copied versions of the beam between
// them, already drifting -- the package's copy never got the paint
// guard the weapon drop's did. One object, one behaviour, and adding
// the marker meant adding it once.
//
// ---------------------------------------------------------------------
// IT IS ORDINARY SPRITES NOW, NOT RS_Panel. SEEN RUNNING 2026-08-08.
//
// The pillar was an RS_Panel wearing the RSPNLBM canvas, and it has
// NEVER ONCE BEEN VISIBLE. Proved in the running game, not argued: a
// probe spawned two panels at the same spot in the same tic, one on the
// canvas and one on a plain wall texture (BROWN1). The plain one drew.
// The canvas one did not -- with a valid picnum, alpha 1.0, bInvisible
// false and a correct 32x256 scaled size, all four printed to the
// console from the spawn itself. Screenshots at pitch bias -90, 0 and
// +90 all showed nothing, so it is not orientation either.
//
// (The probe found a second, separate defect worth passing on: the
// BROWN1 panel rendered LYING FLAT at the shipped rs_panel_pitchbias of
// -90. That is RS_Panel's own dial and this file no longer depends on
// it, but a flatsprite panel that will not stand up is still wrong.)
//
// So the floor presence stopped depending on that path entirely. A
// pillar and a marker are ART, and art is what an ordinary sprite is
// for. What that buys, beyond simply working:
//
//   * CAMERA-FACING IS FREE. A normal sprite always faces the viewer
//     and always stands upright. No mFacing, no FaceViewer, no
//     ApplyOrientation, no pitch bias, and no per-tic re-aim -- which
//     also means it cannot lag the head by a tic and swim in VR.
//   * ADDITIVE IS AVAILABLE. STYLE_AddStencil draws the sprite's SHAPE
//     in fillcolor, so one white gradient serves all eight tiers, which
//     is exactly what the canvas was there to do. A billboard could not
//     have done this -- ProcessBillboard hardcodes STYLE_Translucent
//     (hw_sprites.cpp:2014) and a translucent slab is not a shaft of
//     light.
//   * NO SCARCE RESOURCE. A canvas has to be hand-declared in ANIMDEFS
//     and there are eleven. Three PNGs in sprites/rs_dropfx/ cost none
//     of them.
//
// The art is generated geometry, not drawn: RSBM is a white column with
// the taper painted into its ALPHA, RSMD an alpha diamond and RSMC an
// alpha disc, all bottom- or centre-anchored through their own grAb
// chunks so placement here is one SetOrigin with no fudge factor.
// ---------------------------------------------------------------------
//
// PLAY SCOPE IS LOAD-BEARING, not decoration: an unscoped Object
// subclass is DATA scope, and every call in here (Actor.Spawn,
// SetOrigin, Destroy) is a play function. Without it this class
// produces a wall of "Can't call play function from data context".
// Same reasoning RS_PanelAssembly records for itself.
// =====================================================================
class RS_DropBeacon play
{
	RS_DropGlyph mBeam;      // the tapering shaft
	RS_DropGlyph mMark;      // the shape on top of it
	int          mTier;
	int          mKind;
	double       mGrow;      // last applied distance factor; resize on change only

	static RS_DropBeacon Create(Vector3 foot, int tier, int kind)
	{
		let b = new("RS_DropBeacon");
		b.mTier = tier;
		b.mKind = kind;
		b.mGrow = -1;

		Color glow = RS_PanelController.TierGlow(tier);

		if (RS_PanelController.BeamEnabled())
			b.mBeam = RS_DropGlyph.Create(foot, RSDG_Beam, glow);

		if (RS_PanelController.MarkerEnabled())
		{
			b.mMark = RS_DropGlyph.Create(foot,
				kind == RSDK_Imprint ? RSDG_Circle : RSDG_Diamond, glow);
		}

		// SIZE AND PLACE THEM AT BIRTH. Update() does it every tic, but
		// Update is next tic -- and on a drop the player is already
		// looking at, that first frame is the one they see.
		PlayerPawn viewer = players[consoleplayer].mo;
		double d0 = viewer ? (foot - viewer.pos).Length() : 0.0;
		b.Update(foot, d0, true);
		return b;
	}

	// -----------------------------------------------------------------
	// Once per tic, from the owner's Tick.
	//
	// `dist` drives the SIZE and nothing else -- see BeamGrow() for why a
	// world-fixed pillar is invisible at the range this is supposed to be
	// read at. `showMark` is false while this drop's card is up, because
	// the card stands where the marker was and two of them there at once
	// is the pop the whole ramp exists to remove.
	//
	// No eye vector and no aiming: a sprite faces the camera by itself.
	// -----------------------------------------------------------------
	void Update(Vector3 foot, double dist, bool showMark)
	{
		double g = RS_PanelController.BeamGrow(dist);
		bool   resize = (g != mGrow);
		mGrow = g;

		double h = RS_PanelController.BeamHeight() * g;
		double m = RS_PanelController.MarkerSize() * g;

		if (mBeam)
		{
			// RSBM is bottom-anchored, so the actor sits AT the pickup and
			// the column grows upward out of it. No half-height offset,
			// which is one fewer place for the two to disagree.
			if (resize) mBeam.SetSpan(RS_PanelController.BeamWidth() * g, h);
			mBeam.SetOrigin(foot, true);
		}

		if (mMark)
		{
			// bInvisible rather than Destroy/recreate: the marker comes
			// back the moment the card goes away, and a spawn per crossing
			// of the card radius would be a churn the player can walk back
			// and forth through.
			mMark.bInvisible = !showMark;
			if (showMark)
			{
				if (resize) mMark.SetSpan(m, m);
				// RSMD/RSMC are centre-anchored, so half the marker sits
				// below the point given -- put its BOTTOM on the top of the
				// pillar rather than its middle.
				mMark.SetOrigin((foot.x, foot.y, foot.z + h + m * 0.5), true);
			}
		}
	}

	// Where the marker sits, in world z. The card is handed this so it
	// can rise to meet it at the far end of the ramp -- which is what
	// makes the swap read as the marker GROWING into a card rather than
	// as a second object appearing somewhere else.
	double TopZ(Vector3 foot) const
	{
		double g = mGrow > 0 ? mGrow : 1.0;
		return foot.z + RS_PanelController.BeamHeight() * g
		              + RS_PanelController.MarkerSize() * g * 0.5;
	}

	// Release(), not Destroy(): Object already declares Destroy() as a
	// native, and shadowing it here would be a redefinition rather than
	// an override -- ZScript has no shadowing.
	void Release()
	{
		if (mBeam) mBeam.Destroy();
		if (mMark) mMark.Destroy();
		mBeam = null;
		mMark = null;
	}
}

// Which artwork a glyph wears. An int rather than a StateLabel argument
// because the glyph has to be able to ask itself which one it is later
// (SetSpan needs the texture), and there is no way back from a state to
// a label.
enum ERS_DropGlyphArt
{
	RSDG_Beam    = 0,
	RSDG_Diamond = 1,
	RSDG_Circle  = 2
}

// =====================================================================
// RS_DropGlyph -- one piece of a beacon: the pillar, or the shape on
// top of it. Three frames, one actor, because they differ in artwork
// and in nothing else.
//
// STYLE_AddStencil is the whole trick and it is the same one the halo
// uses: it throws away the texture's RGB, draws its ALPHA as coverage
// in `fillcolor`, and ADDS the result. So one white shape becomes any
// tier colour, and it reads as light rather than as a painted slab you
// can see the wall through.
//
// The art is deliberately pure white with all the shape in the ALPHA
// channel, so nothing about the source image can survive into the
// colour -- if these are ever repainted, only alpha matters.
//
// +FORCEXYBILLBOARD: a tall sprite drawn Y-billboarded pivots about its
// base as you look up or down, which on a 44-unit column standing at
// your feet is very visible. XY billboarding keeps it facing you
// squarely instead.
// =====================================================================
class RS_DropGlyph : Actor
{
	// Which of the three it is. Kept because a state cannot be mapped
	// back to a label, and SetSpan needs to know which texture it is
	// scaling.
	int mArt;

	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+BRIGHT
		+NOTONAUTOMAP
		Radius 1;
		Height 1;
		RenderStyle "AddStencil";
		Alpha 1.0;
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	Beam:
		RSBM A -1;
		Stop;
	Diamond:
		RSMD A -1;
		Stop;
	Circle:
		RSMC A -1;
		Stop;
	}

	static RS_DropGlyph Create(Vector3 where, int art, Color c)
	{
		let g = RS_DropGlyph(Actor.Spawn("RS_DropGlyph", where));
		if (!g) return null;

		g.mArt = art;
		if (art == RSDG_Diamond)     g.SetStateLabel("Diamond");
		else if (art == RSDG_Circle) g.SetStateLabel("Circle");
		else                         g.SetStateLabel("Beam");

		// BILLBOARDING DIFFERS BETWEEN THE TWO PIECES, and it is not a
		// detail. A sprite's default Y-billboard turns about the vertical
		// axis only, which is exactly right for the PILLAR: a shaft of
		// light is supposed to stay vertical, and one that tilts to face
		// you when you look down at it stops reading as light and starts
		// reading as a card lying on the floor.
		//
		// The MARKER wants the opposite. Its whole job is to be a
		// recognisable SHAPE, and a diamond seen from above under
		// Y-billboarding foreshortens into a slot. Full XY facing keeps a
		// diamond a diamond and a circle a circle from any angle, which is
		// the entire point of having two of them.
		g.bForceXYBillboard = (art != RSDG_Beam);

		// fillcolor is `native READONLY color` and its own comment says it
		// "must be set with SetShade to initialize correctly" -- assigning
		// it directly is the "Expression must be a modifiable value"
		// error. Same pairing RS_Panel.SetTint and RS_DropHalo use.
		g.SetShade(c);
		g.A_SetRenderStyle(g.alpha, STYLE_AddStencil);
		return g;
	}

	// Size in MAP UNITS, converted to the actor scale the renderer wants.
	// A sprite's world size is its texture size times its scale, which is
	// the same arithmetic RS_Panel.BindCanvas does -- written out here
	// rather than borrowed, so the pillar depends on the panel primitive
	// for nothing at all.
	void SetSpan(double w, double h)
	{
		TextureID t = TexMan.CheckForTexture(ArtName() .. "A0", TexMan.Type_Any);
		if (!t.IsValid()) return;

		Vector2 texels = TexMan.GetScaledSize(t);
		if (texels.x <= 0 || texels.y <= 0) return;

		Scale = (w / texels.x, h / texels.y);
	}

	string ArtName() const
	{
		if (mArt == RSDG_Diamond) return "RSMD";
		if (mArt == RSDG_Circle)  return "RSMC";
		return "RSBM";
	}
}

// =====================================================================
// RS_DropHalo -- the coloured glow ON the pickup sprite.
//
// A translation is not a glow. TierTranslation re-maps the colours the
// sprite already has, so a Prototype and a Trash differ in hue and in
// nothing else -- and neither is any brighter than the artwork. What the
// drop needs is to look like it is EMITTING its rarity.
//
// So this is the same silhouette again, one size up, drawn additively in
// the tier colour underneath the real one. It wears whatever sprite and
// frame the subject is on right now rather than a fixed frame, so it
// works for every weapon in the game with no per-weapon art and follows
// an animated pickup if one is ever added.
//
// STYLE_AddStencil, not STYLE_Add: AddStencil replaces the texture's RGB
// with fillcolor and keeps its ALPHA as coverage, so the halo is the
// exact shape of the gun in exactly the tier colour. Plain Add would
// wash the sprite's own colours in, and a dark weapon would add almost
// nothing.
//
// LIMIT, STATED RATHER THAN HIDDEN: a payload that renders as a MODEL
// (Pistol, Plasma, Rocket, BFG -- see the world/pickup blocks in
// MODELDEF) has no sprite to copy, so its halo is empty. Those four are
// carried by the dynamic light and the pillar instead. Giving this class
// its own model would mean duplicating every weapon's MODELDEF onto it,
// which is a worse trade than a missing halo on four families.
// =====================================================================
class RS_DropHalo : Actor
{
	// Inventory, not Actor, and that is forced rather than chosen:
	// `owner` is declared on Inventory, NOT on Actor, so the take test in
	// Tick below does not compile against a plain Actor. The subject is
	// always the payload weapon, so nothing is lost by saying so.
	Inventory mSubject;

	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+BRIGHT
		+NOTONAUTOMAP
		Radius 1;
		Height 1;
		RenderStyle "AddStencil";
		Alpha 0.45;
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	static RS_DropHalo Create(Inventory subject, Color c)
	{
		if (!subject) return null;
		let h = RS_DropHalo(Actor.Spawn("RS_DropHalo", subject.pos));
		if (!h) return null;

		h.mSubject = subject;

		// fillcolor is `native READONLY color` and its own comment says it
		// "must be set with SetShade to initialize correctly" -- assigning
		// it directly is the "Expression must be a modifiable value" error.
		// Same pairing RS_Panel.SetTint uses, for the same reason.
		h.SetShade(c);

		// STRENGTH IS PLAYER-FACING, and the reason is the headset. On a
		// flat monitor an additive halo at 0.45 reads as a glow; through
		// lenses the same value can bloom into a smear that hides the gun
		// it is supposed to be advertising. Passed to A_SetRenderStyle
		// rather than left on the Default's alpha, because that call takes
		// the alpha it is going to use.
		h.alpha = RS_PanelController.GlowAlpha();
		h.A_SetRenderStyle(h.alpha, STYLE_AddStencil);
		return h;
	}

	override void Tick()
	{
		Super.Tick();

		// Dies with the thing it is haloing, INCLUDING on take: an
		// Inventory that has been picked up has an owner, and a halo left
		// hanging in the air over an empty floor is the exact leak shape
		// this project keeps finding.
		if (!mSubject || mSubject.bDestroyed || mSubject.owner)
		{
			Destroy();
			return;
		}

		sprite = mSubject.sprite;
		frame  = mSubject.frame;

		// SIZE IS A SETTING. How far the halo stands proud of the gun
		// decides whether it reads as an aura or as a second, blurrier
		// gun -- and where that line falls depends on the sprite, the
		// display and the player. 1.0 turns it off without turning it
		// off: the halo sits exactly under the silhouette and only
		// brightens it.
		Scale  = mSubject.Scale * RS_PanelController.GlowSize();
		SetOrigin(mSubject.pos, true);
	}
}

// =====================================================================
// RS_PanelDropHandler -- arms the drop on an elite kill, and owns the
// radius that decides whether a card is up.
//
// MUST also be listed in MAPINFO.txt's AddEventHandlers.
// =====================================================================
class RS_PanelDropHandler : EventHandler
{
	RS_DropTriptych mCard;
	RS_WeaponDrop   mCardOwner;

	// --- the distance ramp ---------------------------------------------
	// The live card's panel sizes at FULL scale, captured when it is
	// raised and parallel to the assembly's own panel list. Held rather
	// than recomputed because the triptych's layout policy lives in
	// RS_DropTriptych; a second copy of it here would drift.
	Array<double>   mCardBaseW;
	Array<double>   mCardBaseH;

	// The weapon, as a turning 3D model, sitting in the card's art slot.
	// A real actor rather than a billboard because a billboard is a flat
	// quad and this has to be a MODEL -- which is also why it has to be
	// spawned, moved and destroyed by hand: it is not part of the panel
	// assembly and nothing else will clean it up.
	RS_CardModel    mCardModel;
	double          mCardModelBaseScale;

	// Which quantised step the card is currently laid out at, or -1 for
	// "no card / not yet applied". An int and not the raw float on
	// purpose: this is the thing an equality test is allowed to be exact

	// PLAY, and it must stay play: PaintBeamTexture writes it, and that
	// painter is called from WorldThingDied (play), not from RenderOverlay.
	// Marking either of them `ui` breaks the pair -- a ui function cannot
	// write a play field, and a play context cannot call a ui function.
	bool            mBeamPainted;

	// Set only for the duration of the payload's Spawn call in
	// RS_WeaponDrop.Create, and read by RS_ClassGating.WorldThingSpawned so
	// class gating and Vanilla+ leave an elite drop alone. It lives here
	// because ZScript has no mutable statics; play scope is correct because
	// both the writer and the reader are play.
	bool            mSpawningDrop;

	// Last row the pointer rested on, so the hover chirp fires on CHANGE
	// rather than 35 times a second.
	int             mLastHotRow;
	int             mLastHotPanel;

	// The USE key's tap/hold state used to live here as mUseHeld. It now
	// lives on RS_PanelHandler, next to the poke's debounce, because the
	// code that classifies the press had to move upstream of the engine's
	// own use-line check -- see RS_PanelInput.CaptureUse for the whole
	// argument. Nothing in this handler reads the button any more.

	// The six RS class weapons.
	//
	// THE CLASSES ARE VR_*, NOT RS_*. The FILES are RS_Revolver.zs and
	// so on, but every class inside them is `class VR_Revolver :
	// RS_Weapon`. Naming these from the filenames is a silent failure,
	// not an error: Spawn() on a class that does not exist returns null,
	// the drop never appears, and nothing is logged. It has bitten this
	// project before -- four dead MODELDEF entries from the same
	// confusion. Five of these six were wrong on first write.
	//
	// A switch and not a static array literal: `static const
	// class<Weapon> x[] = {...}` does not reliably resolve on this
	// engine build and has produced a bogus "Unknown identifier" three
	// separate times in this tree.
	static class<Weapon> ClassWeapon(int i)
	{
		switch (i)
		{
			case 0: return "VR_Revolver";
			case 1: return "VR_Rifle";
			case 2: return "VR_Shotgun";
			case 3: return "VR_SMG";
			case 4: return "VR_Chaingun";
			default: return "VR_PlasmaRifle";
		}
	}

	static bool DropsEnabled()
	{
		let cv = CVar.FindCVar("rs_elitedrop_enabled");
		return cv ? cv.GetBool() : true;
	}

	// -----------------------------------------------------------------
	// THE PAYOUT GATE. An elite killed before it revealed pays nothing.
	// That is the contract the elite system's own header states and the
	// options menu already advertises to the player; this is the first
	// code that honours it.
	// -----------------------------------------------------------------
	// =================================================================
	// THE FOOD SCATTER.
	//
	// Ported from the champions pack's champion_SpawnBundles: how much a
	// dead elite is worth is a function of how much health it had, in
	// six brackets, doubled if you gibbed it and doubled again if it was
	// a boss. That is a good rule and it is kept as-is -- a Cyberdemon
	// elite should bury you in food and a zombieman elite should not.
	//
	// The pack pushed a weighted pool and drew from it; we scatter
	// directly, because the pool only existed so one bundle actor could
	// mix food with ammo and armour, and RS pays those through Kill
	// Rewards instead.
	//
	// SURVIVES RS_NoMonsterDrops BY CONSTRUCTION: that handler suppresses
	// items carrying bTossed, which only A_DropItem sets. A_SpawnItemEx
	// does not, so this is invisible to it -- the same reason kill-reward
	// Bits survive.
	// =================================================================
	static int FoodTierFor(int startHealth)
	{
		if (startHealth >= 2000) return 5;
		if (startHealth >= 1000) return 4;
		if (startHealth >=  500) return 3;
		if (startHealth >=  300) return 2;
		if (startHealth >=  150) return 1;
		return 0;
	}

	void ScatterFood(Actor victim)
	{
		if (!victim) return;

		let cv = CVar.FindCVar("rs_elite_food");
		if (cv && !cv.GetBool()) return;

		int startHealth = victim.SpawnHealth();
		int tier = FoodTierFor(startHealth);

		// The pack's own count, kept: 5% of starting health, floored at 4
		// and capped at 25 so a Cyberdemon does not carpet the map.
		int n = clamp(int(startHealth * 0.05), 4, 25);

		// Gibbed things burst harder.
		if (victim.health <= victim.GetGibHealth()) n *= 2;
		if (victim.bBoss) n *= 2;

		// Scaled by the difficulty the elite actually presented.
		n = int(n * max(1.0, victim.DamageMultiply));

		let mult = CVar.FindCVar("rs_elite_food_mult");
		if (mult) n = int(n * clamp(mult.GetInt(), 0, 400) / 100.0);
		n = clamp(n, 0, 120);

		for (int i = 0; i < n; i++)
		{
			victim.A_SpawnItemEx("RS_FoodBonus",
				0, 0, 8,
				frandom(1.0, 2.0), 0, frandom(8.0, 10.0),
				frandom(0, 359.9),
				SXF_NOCHECKPOSITION);
		}
	}

	override void WorldThingDied(WorldEvent e)
	{
		if (!DropsEnabled()) return;
		if (!e.Thing || !e.Thing.bIsMonster) return;

		// Paint the shared beam gradient before the first drop can raise a
		// beam. Self-guarding on mBeamPainted, so this is one canvas write
		// per level no matter how many elites die.
		PaintBeamTexture();

		let tok = RS_EliteToken(e.Thing.FindInventory("RS_EliteToken"));
		if (!tok || !tok.revealed) return;

		// FOOD FIRST, AND UNCONDITIONALLY. Owner ruling 2026-08-07:
		// "elites will drop their normal assortment of food icons."
		//
		// Deliberately ahead of every gate below. The weapon drop is
		// gated on a VR_ class, on a percentage roll, and on the player
		// still missing an identity -- so a GH/MeatGrinder player, or one
		// who already owns all six, would otherwise get NOTHING at all
		// from an elite. Food is the payout every class always gets.
		ScatterFood(e.Thing);

		// -------------------------------------------------------------
		// ELIGIBILITY GATE (owner's direct instruction, 2026-08-06).
		// Elites only drop for a class whose weapon carries the VR_
		// prefix -- checked once, generically, off GetMainhandClass()
		// rather than a hardcoded list of which classes qualify. A
		// GH/PS/CZ-prefixed class (RS_GH_Weaponset, RS_PS_Weaponset, and
		// any future weapon set) currently gets NOTHING from elites --
		// not a bug, the stated default. If a weapon set is ever brought
		// into the VR_ system, it becomes elite-eligible for free, with
		// no change needed here.
		// -------------------------------------------------------------
		let pc = VR_DualClassBase(players[0].mo);
		if (!pc) return;
		if (pc.GetMainhandClass().Left(3) != "VR_") return;

		// Rate control. Before this every revealed elite dropped, which
		// was never a decision -- just a question nobody asked.
		if (random[RSDrop](1, 100) > RS_PanelController.DropChance()) return;

		// -------------------------------------------------------------
		// THE CLASS WEAPON, NOT THE OLD 6-TYPE LOOP (owner's direct
		// instruction, 2026-08-06). An elite drop is now another copy
		// of THIS PLAYER'S OWN weapon type, gap-filled in the same
		// order (2, 3, then 5, 6) pedestals use -- via the SAME
		// function, RS_ClassGating.NextMissingIdentity, so the two
		// triggers can never disagree about what's still missing.
		//
		// ALL SIX ALREADY OWNED -> AN IMPRINT, NOT A NO-OP.
		//
		// This used to `return` here, and that return was the single
		// biggest hole in the loop: the moment a player finished
		// collecting, every elite in the game paid food and nothing
		// else, so the hardest content in the mod became worth less
		// than a zombieman for the rest of the run. The comment that
		// stood here called the data packet "deliberately not built
		// yet"; it is built now, in zscript/systems/weapon/RS_Imprint.zs,
		// and this is its trigger.
		//
		// Everything above still applies to it unchanged -- the reveal
		// gate, the VR_-class eligibility gate and the drop-chance roll
		// are all upstream of this line, so "killed before the 50%
		// reveal pays nothing, ever" is inherited rather than
		// re-implemented and cannot drift out of step.
		// -------------------------------------------------------------
		string mainhand = pc.GetMainhandClass();
		string gap = RS_ClassGating.NextMissingIdentity(players[0].mo, mainhand);

		Vector3 where = (e.Thing.pos.x, e.Thing.pos.y, e.Thing.pos.z + 8);

		if (gap == "")
		{
			// The imprint rolls its OWN tier -- the full Trash..Prototype
			// ladder off the eight rs_elite_dropweight_* sliders plus the
			// post-roll tier bonus (owner's R2) -- rather than reusing
			// RollDropTier, whose job is the pre-completion window and
			// whose curve is a triangular bias with no sliders behind it.
			RS_Imprint.Drop(where, mainhand);
			return;
		}

		// The ceiling is per-player, so the roll needs the pawn. Player 0
		// deliberately, matching the rest of this handler's single-player
		// assumptions -- flagged rather than hidden.
		int tier = RollDropTier(players[0].mo);
		RS_WeaponDrop.Create(where, mainhand .. gap, tier);
	}

	// -----------------------------------------------------------------
	// HOW MANY OF THIS PLAYER'S OWN SIX IDENTITIES THEY OWN.
	//
	// CORRECTED 2026-08-06. This used to loop ClassWeapon()'s hardcoded
	// list of 6 DIFFERENT weapon TYPES (Revolver/Rifle/Shotgun/SMG/
	// Chaingun/PlasmaRifle), counting how many different types the
	// player had found at least one of. That list was already wrong on
	// its own terms -- missing Pistol and SuperShotgun, which both have
	// real Dual_X classes (VR_Dual_Pistol, VR_Dual_SSG), and including
	// Plasma, which isn't even a gated family -- and it stopped meaning
	// anything the moment pedestals and elites were rewired to hand out
	// copies of the PLAYER'S OWN type instead of different types. A
	// Dual_Pistol or Dual_SSG player could never advance this count at
	// all, because neither type was in the list, so their tier ceiling
	// was permanently stuck at the starting window regardless of how
	// much they'd actually collected.
	//
	// This now counts the SAME six identities NextMissingIdentity
	// (RS_ClassGating.zs) already tracks for the same player. 1 and 4
	// are the guaranteed spawn grant, so a fresh player starts at 2
	// here -- which is exactly what TierCeiling already expects at
	// "0-2 owned", so its thresholds needed no change, only the count
	// feeding them.
	//
	// Ownership, not what is in your hands -- you only carry two at a
	// time, so "holding" would be a meaningless test. FindInventory
	// answers for the whole inventory. Sequential checks, not a loop
	// over an array: `static const TYPE name[] = {...}` does not
	// reliably resolve on this engine build (see CLAUDE.md).
	// -----------------------------------------------------------------
	static int ArsenalCount(PlayerPawn pawn)
	{
		if (!pawn) return 0;
		let pc = VR_DualClassBase(pawn);
		if (!pc) return 0;
		string mainhand = pc.GetMainhandClass();
		if (mainhand.Length() == 0) return 0;

		int n = 0;
		if (pawn.FindInventory(mainhand))        n++;
		if (pawn.FindInventory(mainhand .. "2")) n++;
		if (pawn.FindInventory(mainhand .. "3")) n++;
		if (pawn.FindInventory(mainhand .. "4")) n++;
		if (pawn.FindInventory(mainhand .. "5")) n++;
		if (pawn.FindInventory(mainhand .. "6")) n++;
		return n;
	}

	// -----------------------------------------------------------------
	// THE CEILING RISES WITH THE ARSENAL. The floor never moves.
	//
	// rs_00's original rule was a CLIFF -- only Cursed/Trash/Basic until
	// all six are found, then the whole ladder at once. That enforced
	// hunting the guns, which is right, but nothing changed for four
	// kills and then everything changed in one step; and a player unlucky
	// at finding weapons had no way to influence it.
	//
	// Shifting the ODDS instead would fix the cliff and be invisible --
	// 30% becoming 35% is not something a player can perceive over the
	// handful of drops they will actually see. They would just conclude
	// loot is random.
	//
	// So each weapon found unlocks a TIER, which the player can see
	// happen:
	//
	//     2 owned -> Basic        (the start: two class weapons)
	//     3       -> Common
	//     4       -> Uncommon
	//     5       -> Advanced
	//     6       -> Prototype    (completing the set unlocks the top)
	//
	// THE POOL WIDENS, IT DOES NOT SLIDE. The floor stays Cursed at every
	// stage on purpose. Per rs_00 those bottom tiers are not merely
	// "bad": a Cursed weapon is powerful with its stats locked behind
	// individual curses, and Trash has the small "Trash to Treasure"
	// chance of an exceptional roll. Both stay interesting forever, so a
	// Prototype-capable player still finding a Cursed is a gamble rather
	// than a disappointment.
	//
	// Knock-on that falls out for free: rs_00 gives Cursed/Trash/Basic no
	// GunBonsai sockets. Under a rising ceiling that stops being a phase
	// of the game and becomes a permanent property -- the bottom three
	// tiers are stat-only, always.
	// -----------------------------------------------------------------
	// TWO PHASES, NOT A RAMP. Owner ruling 2026-08-07:
	//
	//   "when player has less than six class weapons, elites drop rolled
	//    Basic or Trash class weapons until a player has 6, then drop
	//    frames of trash -> prototype"
	//
	// So the drop does one job at a time. Below six, an elite is how you
	// COMPLETE THE SET -- it hands you a missing identity, and the tier
	// is deliberately poor (Trash or Basic) because the weapon itself is
	// the prize. At six, the set is done and the drop switches jobs
	// entirely: now it is about QUALITY, and the whole Trash-to-Prototype
	// range opens up.
	//
	// This replaces a five-step ramp that raised the ceiling one tier per
	// weapon owned (3 owned -> Common, 4 -> Uncommon, 5 -> Advanced). That
	// blurred the two phases together: a player at five weapons was
	// already being handed Advanced guns, so completing the set stopped
	// meaning anything.
	static int TierCeiling(int owned)
	{
		return owned >= 6 ? VRT_Prototype : VRT_Basic;
	}

	// The floor moves with the phase too. Before the set is complete the
	// window is exactly Trash..Basic; after, it is Trash..Prototype.
	static int TierFloor(int owned)
	{
		return VRT_Trash;
	}

	// Weighted toward the bottom of whatever window is open, so the top
	// of the ladder stays an event rather than a Tuesday. Rolling a
	// position in the window rather than a fixed table means the same
	// curve applies however wide the window is.
	static int RollDropTier(PlayerPawn pawn)
	{
		int owned = ArsenalCount(pawn);
		int top   = TierCeiling(owned);
		int bot   = TierFloor(owned);
		int span  = top - bot;

		// PHASE 1 (under six owned): a flat coin-flip between Trash and
		// Basic. No bias worth having across two values, and the tier is
		// not the point yet -- the missing identity is.
		if (owned < 6)
			return bot + random[RSDropTier](0, span);

		// PHASE 2 (set complete): Trash through Prototype, biased low.
		// Two rolls, lower kept -- a triangular curve that makes
		// Prototype genuinely rare without a lookup table to keep in
		// step with the tier enum.
		int a = random[RSDropTier](0, span);
		int b = random[RSDropTier](0, span);
		return bot + min(a, b);
	}

	// -----------------------------------------------------------------
	// THE MID AND NEAR RANGES. One card at a time -- the nearest drop
	// wins, so walking past a field of them reads as the card following
	// you rather than nine cards fighting for the same air.
	//
	// WHAT CHANGED 2026-08-08, and why the old shape was wrong.
	//
	// This used to be a HARD SWITCH: one radius, and a fixed-size card
	// that appeared at full size the instant you crossed a circle you
	// could not see. Everything about that reads as a bug in play -- the
	// card does not arrive, it APPEARS, at reading size, several rooms
	// away from where you are looking.
	//
	// It is now a RAMP between two radii, and three things move along it
	// together:
	//
	//   SCALE     CardMinScale() at the outer edge, 1.0 at the inner.
	//   DISTANCE  the card stands ON THE DROP at the outer edge and
	//             walks in to Comfort() as you approach.
	//   HEIGHT    it sits at the top of the drop's own pillar at the
	//             outer edge -- exactly where the marker was -- and
	//             settles to eye level as it grows.
	//
	// All three from ONE parameter, so they cannot disagree. The far
	// result is a card the size and position of the marker it replaced;
	// the near result is the card as it has always been.
	// -----------------------------------------------------------------
	void ConsiderDrop(RS_WeaponDrop d)
	{
		if (!RS_PanelController.Enabled()) return;

		PlayerPawn pawn = players[consoleplayer].mo;
		if (!pawn) return;

		double dist  = (d.pos - pawn.pos).Length();
		double outer = RS_PanelController.CardRadius();

		if (dist <= outer && mCardOwner != d)
		{
			// A nearer drop takes the card off a farther one.
			if (mCardOwner && (mCardOwner.pos - pawn.pos).Length() <= dist) return;
			RaiseCard(pawn, d);
		}
		else if (dist > outer && mCardOwner == d)
		{
			DropCard();
			return;
		}

		if (mCardOwner == d) TrackCard(pawn, d, dist, outer);
	}

	// -----------------------------------------------------------------
	// The ramp itself, run every tic for whichever drop holds the card.
	// -----------------------------------------------------------------
	void TrackCard(PlayerPawn pawn, RS_WeaponDrop d, double dist, double outer)
	{
		if (!mCard || !mCard.mAsm || !pawn.player) return;

		// The near radius is clamped UNDER the outer one rather than
		// trusted: they are two independent sliders and a player who
		// drags them past each other should get a degenerate-but-sane
		// ramp, not a divide by zero.
		double inner = clamp(RS_PanelController.CardNear(), 1.0, outer - 1.0);

		// 0 = fully grown and in your hands' reach. 1 = a token standing
		// on the pillar, a room away.
		double t = clamp((dist - inner) / (outer - inner), 0.0, 1.0);

		double minS = RS_PanelController.CardMinScale();
		ApplyCardScale(1.0 - t * (1.0 - minS));

		// Stand-off. mComfortDist is used as min(mComfortDist, d) by the
		// assembly's own solver, so handing it `dist` at the far end puts
		// the card exactly on the drop -- there is no separate "pinned"
		// mode to maintain, just the same one number opened up.
		double comfort = RS_PanelController.Comfort();
		mCard.mAsm.mComfortDist = comfort + t * max(0.0, dist - comfort);

		// Height. The assembly places its root at eye.z + mAnchorOfs.z,
		// so the offset is what the marker's world height has to be
		// converted into -- and TopZ is asked of the beacon rather than
		// recomputed here, so the card cannot land somewhere the marker
		// was not.
		double eyez = pawn.player.viewz;
		double base = RS_PanelController.HeightOfs();
		double top  = d.mBeacon ? d.mBeacon.TopZ(d.pos)
		                        : d.pos.z + RS_PanelController.BeamHeight();
		mCard.mAsm.mAnchorOfs = (0, 0, base + t * ((top - eyez) - base));
	}

	// -----------------------------------------------------------------
	// SCALING A LIVE CARD.
	//
	// A panel's size in map units is mWidth/mHeight; what turns that into
	// pixels depends on the backend, so both have to be told:
	//
	//   FLATSPRITE  BindCanvas re-derives the actor Scale from the canvas
	//               size. Cheap -- a texture lookup and two divides.
	//   COMPOSED    the card is dozens of billboards whose sizes were
	//               baked in at layout time, so it has to be laid out
	//               again. NOT cheap, which is the whole reason for the
	//               quantisation below.
	//
	// QUANTISED, DELIBERATELY. Distance is continuous, so an unquantised
	// scale would re-lay-out a composed card thirty-five times a second
	// for a player who is merely walking -- forty billboards destroyed
	// and rebuilt per tic, forever. Twelve steps across the whole ramp
	// bounds that at twelve rebuilds for an entire approach, and twelve
	// steps between 0.30 and 1.0 is under 6% per step: below what reads
	// as a jump on something you are walking toward.
	// -----------------------------------------------------------------
	// QUANTISATION REMOVED 2026-08-09. The comment above is kept because
	// its reasoning was correct WHEN WRITTEN and explains why the ramp
	// looked stepped for so long -- a composed card had to be rebuilt to
	// change size, so twelve rebuilds per approach was the cheap option.
	//
	// Two things ended that. BB_TEXT collapsed a card from ~60 parts to a
	// handful, and RS_BBComposedPanel.Rescale now resizes parts in place
	// through ResizeBillboard, a direct engine setter -- no ReleaseAll,
	// no Build, no handle churn. Scale is continuous now, which is what
	// the owner asked for: "smooth, not x up per player distance".
	// -----------------------------------------------------------------
	// PUT THE MODEL WHERE THE ICON IS, at the card's current scale.
	//
	// The slot comes from RS_BBWeaponCard.ArtLocalRight/Up rather than
	// from literals here, so the model and the flat icon cannot drift
	// apart -- they are the same slot by construction.
	// -----------------------------------------------------------------
	void FollowCardModel(double s)
	{
		if (!mCardModel || !mCard || !mCard.mAsm) return;

		let p = mCard.mAsm.Get(TRI_CoreDrop);
		if (!p || !p.mComposed) return;

		double lr = RS_BBWeaponCard.ArtLocalRight(p.mWidth);
		double lu = RS_BBWeaponCard.ArtLocalUp(p.mHeight);

		mCardModel.PlaceAt(p.mComposed.WorldAt(lr, lu));

		// Scale WITH the card, so the model grows out of the singularity
		// alongside everything else instead of popping in full-size.
		double sc = mCardModelBaseScale * s;
		mCardModel.A_SetScale(sc, sc);
	}

	void ApplyCardScale(double f)
	{
		if (!mCard || !mCard.mAsm) return;

		double s = clamp(f, 0.05, 1.0);
		FollowCardModel(s);

		for (int i = 0; i < mCard.mAsm.Size() && i < mCardBaseW.Size(); i++)
		{
			let p = mCard.mAsm.Get(i);
			if (!p) continue;

			p.mWidth  = mCardBaseW[i] * s;
			p.mHeight = mCardBaseH[i] * s;

			// The hinge solver reads live widths, so the wings re-meet the
			// centre exactly at every scale with nothing else to update.
			//
			// COMPOSED PANELS RESCALE, THEY DO NOT REBUILD. mContentDirty
			// here was the whole cost the quantisation existed to bound --
			// it is ReleaseAll() plus a full Build(), every handle
			// destroyed and remade. Rescale() walks the existing parts and
			// resizes them through a direct engine setter instead, so this
			// is now as cheap as Place() and can run every tic.
			if (p.mBackend == RSPB_Composed)
			{
				if (p.mComposed) p.mComposed.Rescale(s);
			}
			else
			{
				p.BindCanvas();
			}
		}
	}

	void RaiseCard(PlayerPawn pawn, RS_WeaponDrop d)
	{
		DropCard();
		if (!d || !d.mPayload) return;

		mCard = RS_DropTriptych.Build(pawn, d, d.mPayload);
		if (!mCard) return;

		// THE WEAPON, TURNING, IN THE CARD'S ART SLOT.
		//
		// Spawned at the drop rather than at the card: the card has not
		// been placed yet on this tic, so its transform is not solved and
		// asking for a world position now would put the model at the
		// panel origin. FollowCardModel moves it to the right place on
		// the first update, one tic later, which is invisible.
		let rsw = RS_Weapon(d.mPayload);
		Class<Actor> mdl = RS_CardModelFor.ForWeapon(rsw);
		if (mdl)
		{
			mCardModel = RS_CardModel(Actor.Spawn(mdl, d.pos, ALLOW_REPLACE));
			if (mCardModel)
			{
				// Remembered so card scale can multiply it. Reading the
				// live Scale instead would compound every tic and the
				// model would grow without bound.
				mCardModelBaseScale = mCardModel.Scale.X;
			}
		}

		// The card belongs to the reader: it holds a comfortable
		// distance in front of you on the line toward the drop, at eye
		// level, instead of being pinned to the pickup. Walking up to a
		// drop must not shove the card into your face.
		if (mCard.mAsm)
		{
			mCard.mAsm.mComfort     = true;
			mCard.mAsm.mComfortDist = RS_PanelController.Comfort();
		}

		// FULL SIZE IS WHATEVER THE CARD BUILT ITSELF AS, captured here
		// rather than recomputed from cvars. The triptych derives nine
		// panel sizes from four dials (width, height, density, stack
		// tilt) and a stacked column is not a uniform grid -- so asking
		// the panels what they are is the only way to scale them without
		// duplicating that layout policy in this file, where it would
		// silently drift the first time the card's shape changed.
		mCardBaseW.Clear();
		mCardBaseH.Clear();

		// The model is not in the panel assembly, so DropAssembly above
		// does not take it. Left alone it would hang in the air after the
		// card was gone, still turning.
		if (mCardModel)
		{
			mCardModel.Destroy();
			mCardModel = null;
		}
		if (mCard.mAsm)
		{
			for (int i = 0; i < mCard.mAsm.Size(); i++)
			{
				let p = mCard.mAsm.Get(i);
				mCardBaseW.Push(p ? p.mWidth  : 0.0);
				mCardBaseH.Push(p ? p.mHeight : 0.0);
			}
		}

		mCardOwner = d;
		d.mCardUp  = true;

		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		if (ph && mCard.mAsm) ph.RegisterAssembly(mCard.mAsm);

		// Start at the size the ramp says, not at full. Otherwise the
		// card is born full-size for exactly one tic before TrackCard
		// shrinks it -- which is the pop this whole change removes,
		// merely made one frame long.
		TrackCard(pawn, d, (d.pos - pawn.pos).Length(),
			RS_PanelController.CardRadius());
	}

	void DropCard()
	{
		if (mCard)
		{
			let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
			if (ph && mCard.mAsm) ph.DropAssembly(mCard.mAsm);
			mCard.Dismiss();
		}
		mCard = null;
		if (mCardOwner) mCardOwner.mCardUp = false;
		mCardOwner = null;

		mCardBaseW.Clear();
		mCardBaseH.Clear();

		// Otherwise the next card that comes up on the same row index
		// starts already-hovered and never chirps.
		mLastHotRow   = -1;
		mLastHotPanel = -1;
	}

	// -----------------------------------------------------------------
	// ROW RESOLUTION, in one place.
	//
	// Geometry (which panel, and where on it) belongs to
	// RS_PanelHandler; CONTENT (what row that is) belongs to the card,
	// which this handler owns. Every consumer of "what row is under the
	// pointer" -- the painter, the confirm netevent, and now the
	// trigger capture -- comes through here, so the highlight you see,
	// the row that fires, and the press that is eaten cannot disagree
	// about which row it was.
	// -----------------------------------------------------------------
	// ONE resolver, asked twice -- once for whatever won overall (touch
	// beats pointing) and once for the aim ray alone, which is what the
	// weapon trigger reads. Taking a panel index and a uv rather than
	// reading ph.mHot* directly is what lets it serve both without
	// becoming two copies of the same rule about what a row is.
	int ResolveRow(int panel, Vector2 uv, out bool live)
	{
		live = false;
		if (!mCard || panel < 0) return -1;

		let c = mCard.CardFor(panel);
		if (!c) return -1;

		int row = c.RowAtUV(uv);
		live = c.RowIsSelectable(row);
		return row;
	}

	int ResolveHotRow(RS_PanelHandler ph, out bool live)
	{
		live = false;
		if (!ph) return -1;
		return ResolveRow(ph.mHotPanel, ph.mHotUV, live);
	}

	// Publish it where the trigger capture can see it. That capture runs
	// in VR_DualClassBase.PlayerThink, which is upstream of every event
	// handler on this tic (p_tick.cpp:175 vs :178) and has no route to a
	// card -- so the answer has to be left somewhere it can read.
	//
	// Also where the panel makes its two noises that are not tied to an
	// action: the hover chirp, and a punch landing.
	override void WorldTick()
	{
		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		if (!ph) return;

		// ORPHANED-CARD GUARD, added 2026-08-07.
		//
		// A card is normally torn down by the take path, by walking out
		// of radius, or by the pedestal's own Tick calling DropCard().
		// All three require the pedestal to still exist. If the
		// RS_WeaponDrop or its payload is destroyed ANY OTHER WAY --
		// console `remove`, a map script, a crusher -- that Tick stops,
		// mCardOwner goes null, and nothing ever tells the card.
		//
		// The panels then stay registered in RS_PanelHandler.mLive,
		// solved every tic and repainted every frame, for the rest of
		// the map. In comfort mode they hold station in front of the
		// reader, so the player is left staring through a stat sheet for
		// a weapon that no longer exists, with no way to dismiss it.
		//
		// One check, every tic, on the only condition that can produce
		// it: a card with no owner, or an owner with no payload.
		if (mCard && (!mCardOwner || !mCardOwner.mPayload))
			DropCard();

		bool live;
		int row = ResolveHotRow(ph, live);
		ph.PublishHotRow(row, live);

		// And the aim ray's own row, for the SHOOT route. Same resolver, one
		// line apart, so the two answers cannot come from different rules --
		// they differ only in which geometry they were asked about. The
		// trigger needs its own because touch overwrites the hot record and
		// a hand resting on the card would otherwise silently disarm the
		// other hand's trigger. See RS_PanelInput.CaptureAttack.
		bool aimLive;
		int aimRow = ResolveRow(ph.mAimPanel, ph.mAimUV, aimLive);
		ph.PublishAimRow(aimRow, aimLive);

		PlayerPawn pawn = players[consoleplayer].mo;

		// HOVER. Only LIVE rows chirp. Sweeping a hand across a card of
		// twenty stat rows must not chatter -- the sound has to mean
		// "there is something here", or it means nothing.
		if (live && (row != mLastHotRow || ph.mHotPanel != mLastHotPanel))
			RS_PanelInput.Say(pawn, "menu/cursor");

		if (live) { mLastHotRow = row;  mLastHotPanel = ph.mHotPanel; }
		else      { mLastHotRow = -1;   mLastHotPanel = -1; }

		// =============================================================
		// THE USE KEY IS NOT READ HERE, AND MUST NOT BE PUT BACK.
		//
		// Hold-to-take was built in this function on 2026-08-07 and it
		// was in the wrong scope. WorldTick runs at p_tick.cpp:305, AFTER
		// P_PlayerThink at :302, and the engine's use-line check is
		// inside that think: player.zs:1793 calls CheckUse, which tests
		// `player->cmd.ucmd.buttons & BT_USE` and opens the door
		// (p_user.cpp:1326-1334). So a USE read from here is reading a
		// button that has already been spent -- the hold worked, but it
		// also opened whatever you were standing in front of, and a TAP
		// route could not be built at all, because by the time a tap is
		// known to be a tap the door is open.
		//
		// It now lives in RS_PanelInput.CaptureUse, called from
		// VR_DualClassBase.PlayerThink BEFORE Super, where the press can
		// actually be taken away. Exactly the same reasoning that put the
		// trigger capture there.
		//
		// THE PUNCH. Read-and-clear whatever the row underneath is, so a
		// swing at the card is spent on this tic rather than banked and
		// delivered to whatever you point at next.
		//
		// The striking hand is passed on as the hand hint. If the hand
		// landed on a live row that row still wins, exactly as before; if
		// it landed on the stat block or the header, the hint is what
		// makes "reach out and touch it" mean something -- the drop goes
		// to the hand that touched it. A punch is not something you do by
		// accident: it has to cross rs_panel_punch of travel INTO the
		// face in one tic.
		int strike = ph.ConsumePokeStrike();
		if (strike >= 0)
			EventHandler.SendNetworkEvent("rs-panel-use", strike + 1);
	}

	// -----------------------------------------------------------------
	// IS THERE ANYTHING TO TAKE RIGHT NOW?
	//
	// The gate on the USE key, asked live from PlayerThink rather than
	// published a tic late, because the answer decides whether a door
	// opens. Four conditions, and each one is a case where swallowing USE
	// would be wrong rather than merely unnecessary:
	//
	//   * no card, or a card whose pedestal has lost its payload -- there
	//     is nothing this press could mean;
	//   * neither hand can receive it. A REAL fist refuses a class weapon
	//     (the card says so and the take honours it), so if both hands
	//     are fists the key is not ours to eat. An EMPTY hand is not a
	//     fist and is the most takeable case there is -- the card's own
	//     "ACCEPT -- GOES HERE" header promises USE fills it;
	//   * the drop is behind you. In comfort mode the card sits on the
	//     line from your eye toward the pedestal, so turning away from
	//     the drop turns away from the card, and the door you ARE facing
	//     goes back to working normally.
	// -----------------------------------------------------------------
	// A generous cone rather than a narrow one: this only has to
	// distinguish "the card is in front of me" from "I have turned to
	// face something else", and in VR the pawn's yaw and the headset can
	// disagree by a fair margin. 0.35 is about a 140-degree total cone,
	// so a door directly beside you is already outside it. Not a cvar --
	// it is a geometric disambiguation, not a taste dial, the same
	// argument RS_PanelHandler.POKE_COOLDOWN_TICS makes for itself.
	const USE_FACING_DOT = 0.35;

	static bool CanReceive(Weapon w)
	{
		// Null is an empty hand, which is takeable. Only a REAL fist
		// refuses -- VR_Fist2 and its descendants are the empty-slot
		// filler, which is why this asks IsRealFist and not `is VR_Fist`.
		return !RS_DropTriptych.IsRealFist(w);
	}

	bool CanTake(PlayerPawn pawn)
	{
		if (!mCard || !mCardOwner || !mCardOwner.mPayload) return false;
		if (!pawn || !pawn.player) return false;

		if (!CanReceive(pawn.player.OffhandWeapon) &&
		    !CanReceive(pawn.player.ReadyWeapon))
			return false;

		Vector2 flat = (mCardOwner.pos.x - pawn.pos.x,
		                mCardOwner.pos.y - pawn.pos.y);
		double d = flat.Length();
		if (d < 1) return true;          // standing on it; there is no "away"

		Vector2 dir = flat / d;
		Vector2 fwd = (cos(pawn.angle), sin(pawn.angle));
		return (dir dot fwd) >= USE_FACING_DOT;
	}

	// -----------------------------------------------------------------
	// Taking the drop. NOT vanilla pickup -- see the file header. The
	// payload instance is handed to the player intact, with its roll,
	// its condition and its locks, and the weapon it displaces goes
	// back onto the pedestal so the trade is reversible.
	// -----------------------------------------------------------------
	override void NetworkProcess(ConsoleEvent evt)
	{
		if (evt.player < 0) return;
		PlayerPawn pawn = players[evt.player].mo;
		if (!pawn || !pawn.player) return;

		// -------------------------------------------------------------
		// THE CONFIRM. This is what makes an in-world panel usable at
		// all: it resolves whatever row the pointing hand is on and
		// fires that row's own netevent.
		//
		// It is deliberately GENERIC -- it dispatches whatever `cmd` the
		// row carries, so every future panel gets a working confirm for
		// free and no new bind is ever needed. Rows with an empty cmd
		// are inert text and are ignored.
		//
		// Resolution happens HERE, in play scope, not in the painter.
		// RS_PanelHandler owns geometry (which panel, and where on it);
		// the card owns content (which row that is). Keeping the row
		// lookup on the content side is why the handler carries a uv
		// and not a row number.
		// -------------------------------------------------------------
		if (evt.name == "rs-panel-use")
		{
			if (!mCard) return;

			let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
			if (!ph) return;

			// THE HAND HINT, AND WHY IT IS OFFSET BY ONE.
			//
			// 0 means "no hand information" and must keep meaning that:
			// the KEYCONF alias and a bare `netevent rs-panel-use` at the
			// console both arrive as 0, and they have always meant "use
			// whatever row the pointer is on". So a route that KNOWS
			// which hand acted sends hand+1 -- see RS_PanelInput.Fire --
			// and this decodes it back to -1/0/1.
			int hint = evt.args[0] - 1;

			bool live;
			int row = ResolveHotRow(ph, live);

			// -------------------------------------------------------------
			// NOTHING IS BEING POINTED AT, BUT A HAND STILL ACTED.
			//
			// This is the tap/hold USE fallback and the punch that landed
			// on the stat block. There is no row to dispatch, so the hint
			// IS the instruction: take the drop to that hand.
			//
			// It goes out as the same rs-panel-take netevent a row would
			// have carried, so there is exactly one implementation of
			// "take this" and this branch cannot drift away from the one
			// the wings use. The take's own guards -- the fist check, the
			// pointing-hand override, the seating -- all still apply,
			// because it is literally the same code.
			// -------------------------------------------------------------
			if (!live)
			{
				if (hint < 0)
				{
					// A press with nothing under it and nothing to infer.
					// Say so: the press was CONSUMED on most routes, so
					// silence here is indistinguishable from a dead bind.
					RS_PanelInput.Say(pawn, "menu/invalid");
					return;
				}

				RS_PanelInput.Say(pawn, "menu/activate");
				EventHandler.SendNetworkEvent("rs-panel-take", hint);
				return;
			}

			let c = mCard.CardFor(ph.mHotPanel);
			if (!c) return;

			// ACKNOWLEDGE THE PRESS ITSELF, before dispatching what it
			// meant. Two sounds, two facts: this one says the button
			// registered, and whatever the row does says whether it
			// worked. That split matters here more than in a flat menu,
			// because the press was CONSUMED -- your gun deliberately did
			// not fire, and without a click that is indistinguishable
			// from an input that went nowhere.
			//
			// It also means a future row that forgets its own sound is
			// merely terse rather than silent.
			RS_PanelInput.Say(pawn, "menu/activate");

			// Re-enter NetworkProcess with the row's own command. Sending
			// the netevent rather than calling the branch directly keeps
			// one dispatch path, so a row behaves identically whether it
			// was pointed at or fired from the console.
			EventHandler.SendNetworkEvent(c.mCmd[row], c.mArg[row]);
			return;
		}

		if (evt.name == "rs-panel-take")
		{
			if (!mCardOwner || !mCardOwner.mPayload) return;

			let w = mCardOwner.mPayload;

			// WHICH HAND TAKES IT IS THE HAND THAT POINTED.
			//
			// The row carries a fallback (the wing you aimed at implies
			// a hand, and flat play has no controllers), but when VR is
			// really driving the poses the physical gesture wins: reach
			// out with your left controller and the drop lands in your
			// left hand. That collapses the Hand Law into something you
			// do rather than something you remember, and it costs no
			// bind and no extra row.
			bool toOffhand = (evt.args[0] == 0);

			let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
			if (ph && ph.mHotHand >= 0 && pawn.OverrideAttackPosDir)
			{
				// THE POINTING HAND WINS -- BUT ONLY IF IT CAN TAKE.
				//
				// This override used to be unconditional, and that made
				// a dead trigger. A row only EXISTS on a wing whose hand
				// holds a real weapon, but the override re-aimed the
				// take at whichever hand was pointing. Hold a fist in
				// your left, a revolver in your right, and point the
				// left at "> TAKE TO MAINHAND": the row was live, so the
				// press got eaten, then the take resolved to the fist
				// and bailed. Button swallowed, gun silent, nothing
				// taken, no feedback.
				//
				// The row's own arg is the fallback and it is always
				// valid -- Refresh only writes the row when that hand is
				// a real weapon. So a fist can point at the other hand's
				// row and mean exactly what it looks like it means.
				bool wantOff = (ph.mHotHand == 0);
				Weapon wantHeld = wantOff ? pawn.player.OffhandWeapon
				                          : pawn.player.ReadyWeapon;
				// IsRealFist, NOT `is "VR_Fist"` -- and this is the second
				// site of the same mistake, which is why it is spelled out
				// here as well as at the guard below.
				//
				// VR_Fist2 : VR_Fist, and VR_Fist4/VR_Fist6 sit under
				// VR_Fist2, so a bare `is "VR_Fist"` is TRUE for the
				// empty-slot filler every class grants at spawn. The
				// condition then reads false, the override never applies,
				// and toOffhand falls back to the row's arg.
				//
				// Symptom: point at TAKE TO MAINHAND with an EMPTY left
				// hand, and the drop goes to the mainhand and displaces a
				// real weapon -- in the one case where the hand you pointed
				// with was free and the take was guaranteed to work. The
				// exact inversion of the intent, and silent.
				//
				// This line did not conflict during the merge that fixed
				// its twin twenty lines down, so nothing surfaced it. That
				// is the whole argument for auditing what git auto-merges,
				// not just what it stops to ask about.
				if (!RS_DropTriptych.IsRealFist(wantHeld)) toOffhand = wantOff;
			}

			// Fists never take a class weapon -- the card says so and
			// the netevent honours it, so the two cannot disagree.
			//
			// VR_Fist2 IS NOT A FIST FOR THIS PURPOSE. It is the empty-slot
			// filler every class grants at spawn, and RS_Weapon.AttachToOwner
			// treats it as "slot is free" (RS_Weapon.zs:1334). Blocking on
			// plain `is "VR_Fist"` blocked VR_Fist2 too -- which is the one
			// case where the take would definitely have worked.
			//
			// MERGE NOTE: the test is IsRealFist (which honours the VR_Fist2
			// exception) and the sound is the interaction lane's. Its version
			// used a bare `is "VR_Fist"`, which would have rejected the empty
			// slot -- but it was right that a silent return here is
			// indistinguishable from a broken button, now that the press has
			// already been taken away from the weapon. Both halves kept.
			Weapon held = toOffhand ? pawn.player.OffhandWeapon
			                        : pawn.player.ReadyWeapon;
			if (RS_DropTriptych.IsRealFist(held))
			{
				RS_PanelInput.Say(pawn, "menu/invalid");
				return;
			}

			// =============================================================
			// AN IMPRINT IS APPLIED, NOT TAKEN.
			//
			// Everything above -- which hand the gesture chose, the
			// pointing-hand override, the fist refusal -- is identical for
			// both kinds of drop, which is why this branch sits here and
			// not at the top: hand resolution is the same question and
			// must have exactly one answer.
			//
			// From here the two diverge completely. A class weapon is
			// SEATED (the instance itself goes into the hand). An imprint
			// is a stat package: nothing enters inventory, the weapon
			// already in that hand is rewritten in place, and the pedestal
			// and its payload are torn down.
			//
			// AN EMPTY HAND CANNOT TAKE ONE. That inverts the class-weapon
			// case, where an empty hand is the most takeable state there
			// is -- an imprint needs a chassis to land on and there is no
			// gun there to improve.
			// =============================================================
			if (mCardOwner.IsImprint())
			{
				let ip  = mCardOwner.mImprint;
				let rsw = RS_Weapon(held);

				if (!held)
				{
					RS_PanelInput.Say(pawn, "menu/invalid");
					if (pawn.player == players[consoleplayer])
						Console.Printf("\c[Gold]An imprint needs a weapon.\c- That hand is empty.");
					return;
				}

				if (!rsw)
				{
					RS_PanelInput.Say(pawn, "menu/invalid");
					if (pawn.player == players[consoleplayer])
						Console.Printf("\c[Gold]That weapon has no rolled stats to imprint.");
					return;
				}

				string reason;
				if (!ip.CanApplyTo(rsw, reason))
				{
					// R3: A REJECTED PACKAGE DOES NOT DESPAWN. The card and
					// the pedestal both stay, so a refusal is a "not yet"
					// -- lift the curse, come back, apply it -- and not a
					// reward silently destroyed by a mistimed press.
					RS_PanelInput.Say(pawn, "menu/invalid");
					if (pawn.player == players[consoleplayer])
						Console.Printf("\c[Red]%s", reason);
					return;
				}

				if (!ip.ApplyTo(rsw))
				{
					RS_PanelInput.Say(pawn, "menu/invalid");
					return;
				}

				if (pawn.player == players[consoleplayer])
					Console.Printf("\c[Gold]%s applied to %s.\c- %s",
						ip.DisplayName(), rsw.GetTag(), ip.FamilyLine());

				RS_PanelInput.Say(pawn, "misc/w_pkup");

				// Tear the whole pedestal down rather than nulling the
				// payload: OnDestroy already takes the payload, the beam
				// and the halo with it, and an imprint leaves nothing
				// behind on the floor to pick up later.
				let spent = mCardOwner;
				DropCard();
				spent.Destroy();
				return;
			}

			mCardOwner.mPayload = null;

			// UNDRESS THE DROP BEFORE HANDING IT OVER. Everything the
			// pedestal put ON the weapon to make it read as a drop is a
			// property of the WEAPON ACTOR, not of the pedestal, so it
			// travels with the instance into your inventory unless it is
			// taken off here.
			//
			//   RSDropGlow -- an attached dynamic light follows its actor,
			//     and an inventory item is moved to the owner's position
			//     every tic. Without this removal, taking a Prototype left
			//     the player permanently haloed in gold and carrying a
			//     light source they could not put down. It also stacks:
			//     six taken drops is six lights.
			//   bBright   -- set so the tier tint reads in a dark corner.
			//     On a weapon in hand it means the pickup form is drawn
			//     fullbright wherever it is next seen.
			//
			// The tier TRANSLATION is deliberately left on: that is the
			// weapon's rarity and it should stay visible on the object.
			w.A_RemoveLight('RSDropGlow');
			w.bBright        = false;

			//   Scale -- shrunk to pickup size on the floor (see
			//     PayloadScale). It cannot affect the gun in your hands,
			//     because the engine only multiplies actor scale into
			//     WORLD models -- but if this instance is ever put back on
			//     a floor by anything else it should be its own size, so
			//     the dressing comes off with the rest of it.
			w.Scale          = w.default.Scale;

			w.bInvisible     = false;
			w.bNoInteraction = false;
			w.bOffhandWeapon = toOffhand;
			w.AttachToOwner(pawn);

			// SEATING IS EXPLICIT, AND THAT IS THE WHOLE POINT OF THE ROW.
			//
			// AttachToOwner alone is not a take. It only seats the offhand
			// when that slot is empty or holds the VR_Fist2 filler
			// (RS_Weapon.zs:1334), and it never touches the mainhand at all
			// -- so with a real weapon in the hand you pointed at, which is
			// the normal case, the drop silently joined inventory, the card
			// and the pedestal vanished, and your hands were unchanged. The
			// take appeared to succeed and did nothing.
			//
			// PendingWeapon, not a direct OffhandWeapon/ReadyWeapon write:
			// CheckWeaponChange reads PendingWeapon.bOffhandWeapon to pick
			// the hand (player.zs:514) and then lowers and raises properly.
			// Assigning the slot by hand would teleport the gun into view
			// and leave WeaponState out of step.
			//
			// It is also why this is a PendingWeapon and not A_SelectWeapon,
			// which the wheel uses: A_SelectWeapon resolves by CLASS through
			// FindInventory, and if the player already owns a weapon of this
			// class it would raise THAT one and leave the rolled drop -- the
			// entire reason the card exists -- sitting unused in inventory.
			// Seating the instance is the only correct move here.
			pawn.player.PendingWeapon = w;

			// The drop is in your hand. Vanilla's own weapon-pickup sound,
			// because that is exactly what just happened -- even though this
			// deliberately never went through the pickup path (see the file
			// header).
			//
			// MERGE NOTE: the interaction lane's branch had this sound INSTEAD
			// of the PendingWeapon seating above, which would have made the
			// take announce itself and then do nothing -- the exact failure
			// the seating comment describes. Both kept, seat first.
			RS_PanelInput.Say(pawn, "misc/w_pkup");

			DropCard();
		}
		else if (evt.name == "rs-panel-dismiss")
		{
			if (mCard) RS_PanelInput.Say(pawn, "menu/clear");
			DropCard();
		}
		else if (evt.name == "rs-panel-test")
		{
			// Dev harness: drop a rolled class weapon in front of you
			// without needing an elite. `netevent rs-panel-test <tier>`
			int tier = evt.args[0];
			if (tier < 0 || tier > 7) tier = RollDropTier(pawn);
			Vector3 spot = pawn.Vec3Angle(96, pawn.angle);
			spot.z = pawn.pos.z + 16;
			RS_WeaponDrop.Create(spot, ClassWeapon(random[RSDrop](0, 5)), tier);
		}
		else if (evt.name == "rs-imprint-test")
		{
			// Dev harness for the OTHER half of the payout.
			// `netevent rs-imprint-test <tier>`; anything outside
			// Trash..Prototype rolls the weighted table instead.
			//
			// This exists because the imprint is the SET-COMPLETE reward,
			// so without it the only way to look at one is to collect all
			// six class weapons first -- which is several hours of play
			// before the feature can be seen at all, let alone tuned.
			int tier = evt.args[0];
			if (tier < VRT_Trash || tier > VRT_Prototype) tier = -1;

			string mainhand = "";
			let pc = VR_DualClassBase(pawn);
			if (pc) mainhand = pc.GetMainhandClass();

			Vector3 spot = pawn.Vec3Angle(96, pawn.angle);
			spot.z = pawn.pos.z + 16;

			if (!RS_Imprint.Drop(spot, mainhand, tier))
				Console.Printf("\c[Red]No imprint dropped.\c- rs_imprint_enabled is off, or the donor class failed to spawn.");
		}
	}

	// -----------------------------------------------------------------
	// The painter. This runs in ui scope because RenderOverlay IS a ui
	// override -- the engine declares it that way. NOT because canvases
	// are a UI-side surface: they aren't. `class Canvas : Object native
	// abstract` has unscoped methods (base.zs:529) and TexMan.GetCanvas
	// is a plain native static (base.zs:332), so canvas painting needs
	// no ui context anywhere.
	//
	// That distinction is not pedantry -- it caused a real bug. Believing
	// "canvas work must be ui" is what got `ui` put on PaintBeamTexture
	// below, which made the play field it writes read-only to it and
	// produced an "Expression must be a modifiable value" that looked
	// like it was about the field rather than the scope.
	//
	// Solving where the panels ARE is play scope and lives in
	// RS_PanelHandler; this half only draws.
	//
	// Canvas content is uploaded before the 3D scene is rendered each
	// frame, so a card painted here is on the GPU by the time the panel
	// quads sample it. No one-frame lag.
	// -----------------------------------------------------------------
	override void RenderOverlay(RenderEvent e)
	{
		// PaintBeamTexture is NOT called here. RenderOverlay is a `ui`
		// override -- the engine declares it that way -- and the painter is
		// play scope because it writes mBeamPainted. It runs from
		// WorldThingDied instead, which is play and fires before any beam
		// can exist. Painting is a one-time texture write, not per-frame
		// work, so it never belonged in a render hook anyway.
		if (!mCard) return;

		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		int hotPanel = ph ? ph.mHotPanel : -1;

		// READ the published row; do not re-resolve it here.
		//
		// This used to call RowAtUV itself, and still COULD -- RowAtUV
		// lives on RS_PanelCard, an unscoped class, so ui may call it,
		// and reading play fields like mHotUV from ui is legal. What it
		// cannot do is share ResolveHotRow with the confirm path:
		// RenderOverlay is `virtual ui void` (events.zs:181) and
		// StaticEventHandler is `native play` (events.zs:147), so that
		// resolver is play-only.
		//
		// So the choice was two copies of the same lookup or one lookup
		// published once. Published wins: the highlight is now literally
		// the number the trigger capture will act on, rather than a
		// second computation that merely ought to agree with it -- and
		// "agrees with itself" is the failure mode this project keeps
		// paying for.
		//
		// Nothing is lost by not resolving per frame: mHotUV is solved
		// in WorldTick, so it only changes per tic regardless.
		int hotRow = ph ? ph.mHotRow : -1;

		for (int i = 0; i < TRI_COUNT; i++)
		{
			let c = mCard.CardFor(i);
			if (!c) continue;
			c.Paint(i == hotPanel ? hotRow : -1);
		}
	}

	// The beam gradient, painted ONCE and shared by every beam in the
	// map. White on purpose -- each beam tints it through fillcolor, so
	// one texture serves all eight tiers.
	//
	// The taper lives here rather than in geometry: full strength at the
	// bottom where it leaves the pickup, fading to nothing by the top so
	// it dies out around eye level instead of ending in a hard edge.
	// Squaring the fade keeps it bright near the object and makes the
	// last third almost vapour.
	// PLAY, AND CALLED FROM WorldThingDied -- NOT FROM RenderOverlay.
	//
	// This is a scope pair and there is no third option. An unscoped method
	// in a class descending from `StaticEventHandler : Object native play`
	// is a PLAY function, and RenderOverlay is `virtual ui` (events.zs:181)
	// -- an override with no qualifier inherits that ui scope
	// (zcc_compile.cpp:2841). So calling this from RenderOverlay is "Can't
	// call play function ... from ui context" (scopebarrier.cpp:204), and
	// marking it `ui` to fix that makes the mBeamPainted write below fail
	// instead, because ui cannot write a play field. An earlier pass tried
	// both halves in turn and traded one error for the other.
	//
	// The way out is not a scope keyword, it is the call site: this is a
	// one-time texture write, not per-frame work, so it belongs in play
	// where its flag already lives. Do not move it back into the painter.
	void PaintBeamTexture()
	{
		if (mBeamPainted) return;
		let cv = TexMan.GetCanvas("RSPNLBM");
		if (!cv) return;

		// THE ALPHA RAMP BELOW IS THROWN AWAY WITHOUT THIS LINE, AND
		// SILENTLY. Found 2026-08-08 in the engine source.
		//
		// A canvas texture defaults to bTranslucentCanvas = false, and both
		// backends then bind it with TM_OPAQUE -- gl_renderstate.cpp:358 and
		// vk_renderstate.cpp:394 pick the texture mode straight off that
		// flag. TM_OPAQUE forces alpha to 1 for every texel, so the entire
		// taper this function paints, and the transparent surround it is
		// painted into, are discarded at sample time. What actually reached
		// the screen was a solid 32x256 rectangle in the tier colour: a
		// coloured slab standing on the drop, hard-edged top and sides,
		// which is not a light pillar and does not read as one.
		//
		// The flag is per-texture and RSPNLBM is used by beams and nothing
		// else, so this cannot affect the card canvases. The engine's own
		// otherplayertags.zs:110 does exactly this for the same reason --
		// world-space canvas art that needs to be see-through.
		TexMan.SetCanvasTextureTranslucent("RSPNLBM", true);

		cv.Clear(0, 0, 32, 256, Color(0, 0, 0, 0));

		for (int y = 0; y < 256; y++)
		{
			// y = 0 is the TOP of the canvas, which is the top of the
			// beam -- so strength rises as y does.
			//
			// *** IF THE PILLAR COMES OUT POINT-DOWN, THIS IS THE LINE. ***
			// RS_PanelController's header records that canvas V handling is
			// verified for the BILLBOARD path and explicitly NOT verified
			// for FLATSPRITE, which is the path this beam takes. If a beam
			// renders bright at the top and vanishing where it meets the
			// pickup, V is inverted here and the whole fix is to swap this
			// one expression for `double a = (1.0 - t) * (1.0 - t);` and the
			// inset for `int((t) * 12.0)`. Nothing else changes, and no cvar
			// is needed for a two-token edit that can only be one of two
			// values. Do NOT go turning rs_panel_pitchbias for this -- an
			// upside-down GRADIENT is a UV problem, not a geometry one, and
			// the pillar will still be standing in the right place.
			double t = double(y) / 255.0;
			double a = t * t;

			// Narrow the core toward the top as well, so it reads as a
			// taper and not just a fade.
			int inset = int((1.0 - t) * 12.0);
			int a8 = int(a * 255.0);

			// TWO BANDS, NOT ONE. A single Clear gives a column with hard
			// vertical edges -- which is what a slab looks like, not what
			// light looks like. The full-width band is the soft outer
			// bloom and the inset one is the core, so the shaft falls off
			// across its width as well as along its length. It costs one
			// extra write in a paint that happens once per level.
			int flank = int(a8 * 0.30);
			if (flank > 0)
				cv.Clear(0, y, 32, y + 1, Color(flank, 255, 255, 255));
			cv.Clear(inset, y, 32 - inset, y + 1, Color(a8, 255, 255, 255));
		}

		mBeamPainted = true;
	}

	override void WorldUnloaded(WorldEvent e)
	{
		DropCard();
	}
}

// =====================================================================
// RS_FoodBonus -- the elite's food scatter.
// ---------------------------------------------------------------------
// A HealthBonus wearing the FRUT sprite set (8 frames, sprites/rs_food/,
// imported 2026-08-07 from the champions pack at the owner's direction).
//
// Each one picks a random frame and a random horizontal flip at spawn,
// so a pile of twenty reads as an assortment of different food rather
// than twenty copies of one icon. That trick is the whole reason this
// is a separate class instead of a retextured HealthBonus.
//
// -COUNTITEM is deliberate and inherited from the source: dozens of
// these per elite would wreck the level's item percentage, and they are
// a combat payout, not a secret to be found.
// =====================================================================
class RS_FoodBonus : HealthBonus
{
	Default
	{
		+RANDOMIZE
		-COUNTITEM
		Inventory.PickupMessage "$PICKUP_RS_FOOD";
		Tag "$TAG_RS_FOOD";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		bSpriteFlip = random(0, 1);
		frame = random(0, 7);
	}

	States
	{
	Spawn:
		// '#' holds whatever frame PostBeginPlay picked -- the state does
		// not advance it, which is what keeps each item on its own food.
		FRUT "#" 35;
		FRUT "#" 1 Bright;
		Loop;
	}
}
