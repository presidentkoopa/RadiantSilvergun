// =====================================================================
// RS_PanelController -- layout policy for in-world panels, and the
// handler that drives them.
//
// The owner asked for this as its own file, and the split earns itself:
// RS_Panel knows how to be a quad and how to hinge to another quad, and
// nothing else. Every taste decision -- how big, how far, how steeply
// canted, how many at once, tall or stacked -- lives here, behind
// cvars, with its own options page. The primitive stays dumb; the
// controller is where the mod's opinion goes.
//
// TWO SCOPES, ON PURPOSE. Solving a panel's world placement moves
// actors, which is play scope. Painting a canvas is a UI-side surface.
// So WorldTick solves and RenderOverlay paints, exactly the split
// RS_UIHandler already uses. Do not try to merge them.
// =====================================================================

class RS_PanelController
{
	// -----------------------------------------------------------------
	// ORIENTATION BIAS -- the one number I could not verify without a
	// headset.
	//
	// RF_FLATSPRITE composes its matrix as yaw, then pitch, then roll,
	// and a flat sprite at pitch 0 lies FLAT ON THE FLOOR (that is what
	// the flag means). Standing it upright to face along its yaw needs
	// a quarter turn, and which sign depends on the engine's pitch
	// convention. Rather than guess in a constant and ship a panel that
	// renders edge-on and invisible, it is a cvar: if the first boot
	// shows a floor-flat or upside-down panel, this is the dial, and it
	// is a five-second fix in-game instead of a rebuild.
	//
	// *** READ THIS BEFORE YOU TOUCH THE DIAL. ***
	// There are THREE INDEPENDENT unknowns here, and two of them can
	// impersonate the third. Diagnose in this order or you will chase
	// the wrong one:
	//
	//   1. PITCH BIAS (this cvar) -- wrong sign gives a panel lying flat
	//      on the floor, or standing but facing away. GEOMETRY is wrong.
	//   2. U MIRRORING -- text reads right-to-left. The quad is placed
	//      correctly; only the horizontal texture coordinate is flipped.
	//
	//      *** SETTLED 2026-08-08, AND THE OLD TEXT HERE WAS WRONG. ***
	//      It said the billboard path assigns UVs "UNSWAPPED, following
	//      the decal path ... rather than the sprite path's swap", and
	//      that the swap "means nothing to a path that never calls
	//      GetSpritePositioning". That reasoning is what shipped the bug.
	//      The swap has nothing to do with GetSpritePositioning: it
	//      compensates for the CORNER ORDER, and the billboard path
	//      produces the SAME corner order as the sprite path.
	//
	//      Proof, from the engine and not from us: the sprite path's
	//      v[0]->v[1] runs along (-V.y, V.x) (hw_sprites.cpp:1285-1308)
	//      and so does a billboard's, because a billboard's `right` is
	//      (sin yaw, -cos yaw) and its view direction is -F
	//      (hw_sprites.cpp:2083). Identical geometry, so it needs the
	//      identical UV assignment -- and the sprite path's UNMIRRORED
	//      branch is the SWAPPED one, ul = UR = 1, ur = UL = 0
	//      (hw_sprites.cpp:1247-1248, gametexture.cpp:340-341).
	//      ProcessBillboard defaults to ul = 0, ur = 1
	//      (hw_sprites.cpp:2027-2028), which is the path's own MIRROR
	//      branch. So every billboard draws mirrored unless `bb_flipu`
	//      is ON. It is not a preference; ON is the correct value.
	//
	//      The mod's own half of the same mistake was RS_BBCompose.RightOf
	//      -- see the correction note there. BOTH have to be right.
	//   3. CANVAS V-FLIP -- text upside down. Canvas textures are stored
	//      inverted and the sprite path, unlike walls and flats, does not
	//      compensate. We do not pre-flip.
	//
	//      Checked 2026-08-08 for the BILLBOARD path and it is already
	//      right: ProcessBillboard sets vt = 0 / vb = 1
	//      (hw_sprites.cpp:2025-2026), and the engine's own hardware-canvas
	//      case does the same (hw_sprites.cpp:2201-2202). So a canvas on a
	//      billboard needs no pre-flip. Not verified for FLATSPRITE.
	//
	// THE TRAP: if (2) and (3) are BOTH wrong, the card appears rotated
	// 180 degrees -- which looks exactly like a pitch/orientation problem
	// and will send you into this cvar, where nothing you do will fix it.
	// A 180 rotation is a UV problem, not a geometry problem. Check that
	// the panel is in the right PLACE and facing you before assuming the
	// bias is wrong; if the geometry is right and the content is turned,
	// leave this alone and go to (2) and (3).
	// -----------------------------------------------------------------
	static double PitchBias()
	{
		let cv = CVar.FindCVar("rs_panel_pitchbias");
		return cv ? cv.GetFloat() : -90.0;
	}

	static double RollBias()
	{
		let cv = CVar.FindCVar("rs_panel_rollbias");
		return cv ? cv.GetFloat() : 0.0;
	}

	static bool Enabled()
	{
		let cv = CVar.FindCVar("rs_panel_enabled");
		return cv ? cv.GetBool() : true;
	}

	// 0 = TALL (one panel per weapon), 1 = STACKED (three hinged
	// panels per weapon, curving toward the reader). Both are built;
	// this picks which one a triptych assembles.
	// Which backend a card should use. Composed costs no canvastexture,
	// which is the only reason more than one card can be up at once.
	static bool Composed()
	{
		let cv = CVar.FindCVar("rs_panel_compose");
		return cv ? cv.GetBool() : true;
	}

	static int Density()
	{
		let cv = CVar.FindCVar("rs_panel_density");
		return cv ? cv.GetInt() : 0;
	}

	static double PanelWidth()
	{
		let cv = CVar.FindCVar("rs_panel_width");
		return cv ? cv.GetFloat() : 40.0;
	}

	static double PanelHeight()
	{
		let cv = CVar.FindCVar("rs_panel_height");
		return cv ? cv.GetFloat() : 80.0;
	}

	// How far the wings cant inward. Positive folds them toward the
	// reader, which is what makes all three faces legible from one
	// standing position -- a flat row of three panels is not.
	static double HingeAngle()
	{
		let cv = CVar.FindCVar("rs_panel_hinge");
		return cv ? cv.GetFloat() : 35.0;
	}

	// Tilt between stacked panels in STACKED mode. The top panel leans
	// down toward the reader and the bottom leans up, so a column reads
	// as a curved surface rather than a wall.
	static double StackTilt()
	{
		let cv = CVar.FindCVar("rs_panel_stacktilt");
		return cv ? cv.GetFloat() : 18.0;
	}

	// Vertical offset from the player's LIVE view z -- never a world
	// constant. In VR the eye line is the player's real room-scale
	// height, not the 41 Player.ViewHeight assumes, so a fixed offset
	// is correct for exactly one person and wrong for everyone else.
	static double HeightOfs()
	{
		let cv = CVar.FindCVar("rs_panel_heightofs");
		return cv ? cv.GetFloat() : 0.0;
	}

	// -----------------------------------------------------------------
	// THREE-RANGE PRESENCE -- THE OUTER RADIUS.
	//
	// This used to be the whole story: a hard on/off switch with a
	// fixed-size card, so the card popped into existence at full size the
	// instant you crossed a circle you could not see. Owner's design
	// 2026-08-08 replaces the switch with a RAMP, and this is the FAR end
	// of it -- the distance at which a card first appears, at
	// CardMinScale(), standing on top of the drop's own pillar.
	//
	// Outside it there is no card at all, only the pillar and its marker.
	// That is still spawn/despawn rather than an alpha fade, and for the
	// same reason as before: a map full of drops costs a pillar each, not
	// a live panel set each.
	// -----------------------------------------------------------------
	static double CardRadius()
	{
		let cv = CVar.FindCVar("rs_panel_radius");
		return cv ? cv.GetFloat() : 320.0;
	}

	// The NEAR end of the ramp: inside this the card is fully grown,
	// readable and holding station at Comfort(). Between the two the
	// scale, the stand-off distance and the height all interpolate, so
	// there is no frame at which anything jumps.
	//
	// Clamped against CardRadius by the caller rather than here, because
	// a player who drags the two sliders past each other should get a
	// degenerate-but-sane result, not a division by zero.
	static double CardNear()
	{
		let cv = CVar.FindCVar("rs_drop_cardnear");
		return cv ? cv.GetFloat() : 88.0;
	}

	// HOW LONG THE GROWTH RAMP IS, in map units, measured OUTWARD from
	// CardNear. Added 2026-08-09.
	//
	// The ramp used to run from CardNear all the way to the outer detect
	// radius -- hundreds of units -- so the card spent an entire room
	// slowly inflating and was already most of its size before you could
	// read it. The owner wants the opposite: nothing, then a fast bloom
	// from a point as you arrive.
	//
	// 96 is about two body-widths: close enough to read as "on arrival",
	// long enough that the bloom is a movement rather than a pop.
	static double CardRamp()
	{
		let cv = CVar.FindCVar("rs_drop_cardramp");
		return cv ? clamp(cv.GetFloat(), 8.0, 512.0) : 96.0;
	}

	// How big the card is at the OUTER radius, as a fraction of full
	// size. Deliberately close to MarkerSize() in world terms so the
	// swap from marker to card is a substitution rather than a pop --
	// the marker is ~11 units and a 0.30 card is ~16 across its three
	// panels.
	// THE FLOOR WAS 0.05 AND THE DEFAULT WAS 0.30, which is why the card
	// never grew "from a point" -- it could not get smaller than a third
	// of full size, so the whole singularity end of the ramp did not
	// exist. Floor is 0.0 now and the default is a genuine speck.
	//
	// Zero is allowed deliberately: at the far end the card is meant to
	// be INVISIBLE, indistinguishable from the marker it grows out of.
	static double CardMinScale()
	{
		let cv = CVar.FindCVar("rs_drop_cardminscale");
		return cv ? clamp(cv.GetFloat(), 0.0, 1.0) : 0.02;
	}

	static int MaxAssemblies()
	{
		let cv = CVar.FindCVar("rs_panel_maxlive");
		return cv ? cv.GetInt() : 8;
	}

	// How far in front of the reader the card holds station.
	static double Comfort()
	{
		let cv = CVar.FindCVar("rs_panel_comfort");
		return cv ? cv.GetFloat() : 72.0;
	}

	// -----------------------------------------------------------------
	// TYPOGRAPHY. Player-facing because legibility in a headset is
	// genuinely personal -- panel distance, IPD and lens sharpness all
	// move where the comfortable point is, and no default is right for
	// everyone.
	//
	// Resolved by NAME through Font.GetFont so a font that is not
	// present falls back rather than crashing.
	// -----------------------------------------------------------------
	static Font BodyFont()
	{
		let cv = CVar.FindCVar("rs_panel_font");
		int pick = cv ? cv.GetInt() : 0;
		Font f = Font.GetFont(FontName(pick));
		return f ? f : SmallFont;
	}

	static Font TitleFont()
	{
		let cv = CVar.FindCVar("rs_panel_titlefont");
		int pick = cv ? cv.GetInt() : 2;
		Font f = Font.GetFont(FontName(pick));
		return f ? f : BigFont;
	}

	// A switch, not a static array literal -- `static const TYPE n[] =
	// {...}` does not reliably resolve on this engine build and has
	// produced a bogus "Unknown identifier" three separate times here.
	static Name FontName(int pick)
	{
		switch (pick)
		{
			case 1:  return 'NewSmallFont';
			case 2:  return 'BigFont';
			case 3:  return 'ConFont';
			default: return 'SmallFont';
		}
	}

	static int RowPitch()
	{
		let cv = CVar.FindCVar("rs_panel_rowpitch");
		int p = cv ? cv.GetInt() : 18;
		return clamp(p, 8, 48);
	}

	// --- drop marker --------------------------------------------------
	// HOLD-USE TAKE. The card's wing text has always promised this and
	// nothing implemented it until 2026-08-07. Off makes the card
	// point-and-trigger / MOUSE3 / punch only, as it was.
	static bool UseTakeEnabled()
	{
		let cv = CVar.FindCVar("rs_panel_usetake");
		return !cv || cv.GetBool();
	}

	// How long USE must be held before it counts as a HOLD rather than a
	// TAP. Both gestures are live and they mean different hands -- see
	// RS_PanelInput.CaptureUse. Anything shorter than this, measured at
	// the moment the button comes back up, is a tap.
	static int UseHoldTics()
	{
		let cv = CVar.FindCVar("rs_panel_useholdtics");
		return cv ? clamp(cv.GetInt(), 5, 105) : 21;
	}

	// -----------------------------------------------------------------
	// THE SHOT'S REACH.
	//
	// How far the aiming hand may be from the panel it hit and still have
	// the trigger count as "I shot the card" rather than "I shot past
	// it". The card holds station at Comfort() -- 72 by default -- so
	// anything at arm's length is comfortably inside this and a shot
	// across a room is not, even in the case where a future non-comfort
	// assembly is pinned to a distant pedestal.
	//
	// It is NOT the whole answer to accidental takes and must not be read
	// as one: in comfort mode the card is ALWAYS about 72 units away, so
	// this gate never fires there. What actually stops a stray shot is
	// that only a row carrying a command captures the press, and the take
	// rows are two lines on angled wings. See RS_PanelInput.CaptureAttack.
	// -----------------------------------------------------------------
	static double ShootRange()
	{
		let cv = CVar.FindCVar("rs_panel_shootrange");
		return cv ? cv.GetFloat() : 192.0;
	}

	static bool BeamEnabled()
	{
		let cv = CVar.FindCVar("rs_drop_beam");
		return cv ? cv.GetBool() : true;
	}

	static double BeamWidth()
	{
		let cv = CVar.FindCVar("rs_drop_beamwidth");
		return cv ? cv.GetFloat() : 7.0;
	}

	static double BeamHeight()
	{
		let cv = CVar.FindCVar("rs_drop_beamheight");
		return cv ? cv.GetFloat() : 44.0;
	}

	static int DropChance()
	{
		let cv = CVar.FindCVar("rs_elitedrop_chance");
		return cv ? clamp(cv.GetInt(), 0, 100) : 100;
	}

	static int LightRadius()
	{
		let cv = CVar.FindCVar("rs_drop_lightradius");
		return cv ? int(cv.GetFloat()) : 96;
	}

	// -----------------------------------------------------------------
	// HOW THE PILLAR REFUSES TO VANISH.
	//
	// A 7x44 quad is a legible shaft of light at twenty feet and a
	// sub-pixel sliver at two hundred. The pillar is supposed to be the
	// thing you read a LEVEL by, so a world-fixed size cannot be right
	// for both ends of that.
	//
	// So it grows with distance, and only ever OUTWARD from the card
	// radius: inside that radius the factor is exactly 1 and the pillar
	// is the size it has always been, with its taper still dying at eye
	// level, which is what BeamHeight's own slider is for. Beyond it the
	// factor rises linearly, capped, so the shaft holds roughly a
	// constant angular size instead of shrinking to nothing.
	//
	// 1.0 turns the whole thing off and gives back the old world-fixed
	// pillar. QUANTISED to eighths on purpose: the size is pushed into
	// the panel with BindCanvas, and an unquantised factor would do that
	// texture lookup every tic for every drop on the map.
	static double BeamGrow(double dist)
	{
		let cv = CVar.FindCVar("rs_drop_beamgrow");
		double cap = cv ? cv.GetFloat() : 3.0;
		if (cap <= 1.0) return 1.0;

		double r = CardRadius();
		if (r <= 0 || dist <= r) return 1.0;

		double g = clamp(dist / r, 1.0, cap);
		return int(g * 8.0 + 0.5) / 8.0;
	}

	// --- the marker on top of the pillar -------------------------------
	static bool MarkerEnabled()
	{
		let cv = CVar.FindCVar("rs_drop_marker");
		return cv ? cv.GetBool() : true;
	}

	// Deliberately SMALL. The pillar is what carries across a level; the
	// marker only has to resolve into a recognisable silhouette once you
	// are close enough to care which drop you are walking toward. It
	// grows with the pillar (see BeamGrow) so it holds that silhouette
	// rather than dissolving into a dot.
	static double MarkerSize()
	{
		let cv = CVar.FindCVar("rs_drop_markersize");
		return cv ? cv.GetFloat() : 11.0;
	}

	// -----------------------------------------------------------------
	// HOW BIG THE DROPPED WEAPON ITSELF IS.
	//
	// SEEN RUNNING 2026-08-08 AND IT IS NOT A TASTE DIAL, it is a fix
	// with a dial on it. Five of the six class families render their
	// FIRST-PERSON model in the world (SHTG A, CHGG A, REVO A, RIFK A,
	// SAWG A all carry FrameIndex entries in MODELDEF, at Scale 1.35),
	// and a first-person mesh at 1.35 standing on a floor is roughly the
	// size of a car. A screenshot of a Prototype drop at 96 units away
	// showed a gun taller than the corridor.
	//
	// The engine multiplies the ACTOR's scale into world models and NOT
	// into HUD ones -- `scaleFactorX = actor->Scale.X * smf->xscale` at
	// src/r_data/models.cpp:82, against the HUD path's `smf->xscale`
	// alone at :245. So shrinking the payload actor fixes the drop and
	// cannot touch the gun in your hands. It fixes the sprite-backed
	// families (the SMG's SMP1) in the same stroke and by the same
	// amount, which is why it is one number rather than per-family.
	//
	// Restored to the class default on take, next to bBright, for the
	// same reason: it is dressing the pedestal put on, not a property of
	// the weapon.
	static double PayloadScale()
	{
		let cv = CVar.FindCVar("rs_drop_spritescale");
		return cv ? clamp(cv.GetFloat(), 0.05, 2.0) : 0.42;
	}

	// --- the glow worn by the pickup sprite ----------------------------
	// How far the additive halo stands proud of the weapon's own
	// silhouette. 1.0 is "exactly under it" -- the halo only brightens,
	// it does not outline.
	static double GlowSize()
	{
		let cv = CVar.FindCVar("rs_drop_glowsize");
		return cv ? clamp(cv.GetFloat(), 1.0, 2.0) : 1.16;
	}

	static double GlowAlpha()
	{
		let cv = CVar.FindCVar("rs_drop_glowalpha");
		return cv ? clamp(cv.GetFloat(), 0.0, 1.0) : 0.45;
	}

	// --- the dynamic light ---------------------------------------------
	// 0 off, 1 plain, 2 attenuated. LF_ATTENUATE is what makes the light
	// SOFT rather than merely small: without it a dynamic light falls off
	// linearly and ends in a visible disc on the floor, and with it the
	// inverse-square falloff reads as a glow around the object. The flag
	// lives on DynamicLight (dynlights.zs:36-38).
	static int LightDetail()
	{
		let cv = CVar.FindCVar("rs_drop_lightdetail");
		return cv ? clamp(cv.GetInt(), 0, 2) : 2;
	}

	static int LightFlags()
	{
		return LightDetail() >= 2 ? DynamicLight.LF_ATTENUATE : 0;
	}

	// -----------------------------------------------------------------
	// Tier -> the TRNSLATE name that tints a dropped weapon's sprite,
	// and the tier colour for its glow and light.
	//
	// Rarity names, not numbers: the monster block in TRNSLATE.txt is
	// rs_<family>_t<NN> because monsters have numeric difficulty tiers.
	// Weapons have rarity tiers. The two vocabularies stay apart.
	// -----------------------------------------------------------------
	static Name TierTranslation(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return 'rs_wpn_cursed';
			case VRT_Trash:     return 'rs_wpn_trash';
			case VRT_Basic:     return 'rs_wpn_basic';
			case VRT_Common:    return 'rs_wpn_common';
			case VRT_Uncommon:  return 'rs_wpn_uncommon';
			case VRT_Advanced:  return 'rs_wpn_advanced';
			case VRT_Designer:  return 'rs_wpn_designer';
			default:            return 'rs_wpn_prototype';
		}
	}

	// The same ramp as RS_UIStyle.TierColor, as literal RGB for the
	// glow and the dynamic light. RS_UIStyle returns Font.CR_* constants,
	// which are text-colour indices and cannot light a room.
	// Forwards to RS_TierPalette -- the single tier table. This used to
	// hold its own ladder, one of four that had drifted apart.
	static Color TierGlow(int tier)
	{
		return RS_TierPalette.RGB(tier);
	}
}

// =====================================================================
// RS_PanelHandler -- solves every live assembly each tic, paints their
// cards each frame, and resolves the aim ray to a row.
//
// MUST also be listed in MAPINFO.txt's AddEventHandlers. A handler name
// in MAPINFO with no class is a hard crash at map load; a class with no
// MAPINFO line compiles and silently never runs. Both halves or
// neither.
// =====================================================================
class RS_PanelHandler : EventHandler
{
	Array<RS_PanelAssembly> mLive;
	Array<RS_PanelCard>     mCards;   // parallel to every panel, by slot

	// Aim resolution, recomputed each tic in play scope and read by the
	// painter. -1 = the ray is on nothing.
	// This handler owns GEOMETRY -- which panel the ray hit and where on
	// it (mHotUV). It does not own CONTENT and cannot know what a row
	// is; resolving uv -> row needs the card, which belongs to whoever
	// built the panel.
	int      mHotAssembly;
	int      mHotPanel;
	// Which controller is pointing: 0 offhand/left, 1 mainhand/right,
	// -1 nothing. In flat play this is always 0 (the view ray).
	int      mHotHand;
	Vector2  mHotUV;

	// How far the winning hit was from the hand that made it, in map
	// units. 0 for a poke -- the hand is IN the panel. Kept because the
	// SHOT route needs to distinguish "I put my muzzle on the card" from
	// "the ray happened to cross a live row on its way somewhere else";
	// TraceHand already computes this distance to sort competing hits and
	// used to throw it away.
	//
	// NO_HIT rather than 0 when nothing is hot, because 0 is the poke's
	// legitimate answer and a range test reading `<= range` would pass on
	// a cleared value.
	const NO_HIT_DIST = 1e9;
	double   mHotDist;

	// --- published BY the content side, read by the input side --------
	// These two used to be deliberately absent, on the grounds that a
	// geometry handler cannot know what a row is and the only value
	// anything ever wrote was -1. That reasoning held right up until
	// something needed to press a row: the trigger capture runs in
	// PlayerThink, where neither the card nor the painter is reachable,
	// so the row state has to be somewhere it can see.
	//
	// It is still not RESOLVED here -- the card owner resolves it and
	// calls PublishHotRow. This is a letterbox, not a decision.
	int      mHotRow;
	bool     mHotRowLive;

	// --- THE AIM RAY'S OWN ANSWER, KEPT SEPARATE ----------------------
	// Snapshotted at the end of the two ray casts, BEFORE TracePoke is
	// allowed to overwrite the hot record.
	//
	// TOUCH BEATS POINTING, and it should -- but only for the HIGHLIGHT
	// and for the touch route's own press. Letting it also overwrite what
	// the trigger reads produced a real, silent failure of the shoot
	// route: rest your left hand anywhere on the card while aiming the
	// right at a live row, and mHotHand became 0, so CaptureAttack asked
	// for BT_OFFHANDATTACK and the right trigger was never read. The gun
	// fired, nothing was taken, and there was nothing to see -- the
	// highlight was still drawn, on the row your left hand was resting on.
	//
	// So the trigger reads THIS record and the touch reads the other one.
	// Two records, still one confirm and one row resolver.
	int      mAimAssembly;
	int      mAimPanel;
	int      mAimHand;
	Vector2  mAimUV;
	double   mAimDist;
	int      mAimRow;
	bool     mAimRowLive;

	// --- the punch ----------------------------------------------------
	// Hand positions as of last tic, and whether they are trustworthy.
	// There is no native hand velocity, so a swing is measured as travel
	// between tics -- which is all "how fast did that hand move into the
	// card" needs.
	Vector3  mPrevHand0, mPrevHand1;
	bool     mHavePrevHand;

	// Which hand struck a panel this tic, or -1. Consumed exactly once
	// by whoever owns the content, then cleared.
	int      mPokeStrikeHand;

	// =================================================================
	// CONTACT IS THE PRESS. THE PUNCH IS ONLY A SECOND WAY TO PRESS.
	//
	// Owner's ruling 2026-08-08: touch is the PRIMARY route and the keys
	// are the fallback. This code had that backwards. TracePoke found the
	// hand, resolved the row and lit the highlight -- and then did nothing
	// at all unless the hand was ALSO travelling at rs_panel_punch
	// (1.5 units/tic, ~52 a second) along the face normal. Reaching out
	// and putting your hand on a button did not press it. The only way to
	// take a drop by touch was to hit the card hard enough, which is not
	// what "reach out and touch the panel to choose" means and is not
	// something a player discovers.
	//
	// A hand ARRIVING in the panel now presses it, once. The punch is
	// kept, because it is the only way to press the SAME row twice without
	// withdrawing your hand first, and because a jab is a real gesture
	// people will make at a button.
	//
	// WHY A LATCH AND NOT A TIMER. A hand held in a panel is one press,
	// not thirty-five a second, and the natural fix -- a cooldown -- is
	// wrong in both directions at once: long enough to stop a resting hand
	// re-firing is long enough to block a deliberate second press, and
	// short enough to allow the second press is short enough to machine-gun
	// on a hand that is merely resting. So the latch is positional: this
	// hand pressed this panel, and it cannot press it again until it has
	// LEFT.
	//
	// AND LEFT MEANS FURTHER OUT THAN IT CAME IN. Hysteresis, for the
	// oldest reason there is -- a hand parked exactly on the boundary
	// jitters across it, and without a wider release band that reads as
	// the panel firing at random. Entry is rs_panel_poke off the face;
	// release is rs_panel_pokerelease times that.
	//
	// Per hand, because two hands are two independent gestures. One shared
	// latch would have let a resting left hand hold the right hand's press
	// off, which is the same class of bug as the aim record above.
	// =================================================================
	bool     mTouchLatch0, mTouchLatch1;   // this hand has pressed and not yet left
	int      mTouchOnAsm0,   mTouchOnAsm1;   // ...which assembly it latched on
	int      mTouchOnPanel0, mTouchOnPanel1; // ...and which panel of it

	// A swing spans several tics and would otherwise register on every
	// one of them. Not a cvar: it is a debounce on a physical gesture,
	// not a taste dial, and there is no value a player would want here
	// that the punch threshold does not already express better.
	//
	// PER HAND since 2026-08-08. One shared counter meant a punch with one
	// hand ate the next ten tics of the other hand's presses -- invisible,
	// and exactly the "both hands work, but not at the same time" bug that
	// is hardest to reproduce on purpose.
	const POKE_COOLDOWN_TICS = 10;
	int      mPokeCool0, mPokeCool1;

	// --- the USE key --------------------------------------------------
	// TAP and HOLD are two different takes and they share one button, so
	// the classifier needs somewhere to keep score across tics. It lives
	// HERE, next to the poke's own debounce, because this class is
	// already the input letterbox -- and because the code that writes it
	// (RS_PanelInput.CaptureUse) is a static called from PlayerThink and
	// has no instance of its own to keep state in.
	//
	// mUseArmed is the load-bearing one. A press is only ours if it BEGAN
	// while a take was on offer; a USE already held down when you walked
	// into the card's radius belongs to whatever door you were opening,
	// and swallowing it halfway through would be a take you never asked
	// for AND a door that stopped working.
	int      mUseHeld;    // tics held, counted only while armed
	bool     mUseArmed;   // this press began on our watch and is ours to classify
	bool     mUseFired;   // the HOLD already fired; the release must not also tap

	play void PublishHotRow(int row, bool live)
	{
		mHotRow     = row;
		mHotRowLive = live;
	}

	// The same letterbox for the aim ray's own row. Resolved by the same
	// function on the content side, one line apart from the hot row, so the
	// two cannot use different rules about what a row is.
	play void PublishAimRow(int row, bool live)
	{
		mAimRow     = row;
		mAimRowLive = live;
	}

	// Read-and-clear. A strike is an event, not a state -- leaving it
	// set would re-fire the row on the next tic that happened to look at
	// it, which is the same repeat-press failure the trigger edge test
	// exists to avoid.
	play int ConsumePokeStrike()
	{
		int h = mPokeStrikeHand;
		mPokeStrikeHand = -1;
		return h;
	}

	play void ClearHot()
	{
		mHotAssembly = -1; mHotPanel = -1; mHotHand = -1;
		mHotRow = -1; mHotRowLive = false;
		mHotDist = NO_HIT_DIST;
		mPokeStrikeHand = -1;

		mAimAssembly = -1; mAimPanel = -1; mAimHand = -1;
		mAimRow = -1; mAimRowLive = false;
		mAimDist = NO_HIT_DIST;

		// The cooldown only ticks down while panels are live, so leaving
		// it wound would carry over and swallow the first punch at the
		// NEXT card. Nothing is up to debounce any more; drop it.
		mPokeCool0 = 0; mPokeCool1 = 0;

		// Same for the contact latches. A latch says "this hand has already
		// pressed this panel and must leave before it presses again", and
		// with no panels left there is nothing to have left -- carrying one
		// forward would swallow the first touch on the NEXT card, which is
		// precisely the press a player is most sure they made.
		mTouchLatch0 = false; mTouchLatch1 = false;
		mTouchOnAsm0 = -1; mTouchOnAsm1 = -1;
		mTouchOnPanel0 = -1; mTouchOnPanel1 = -1;

		// Same argument for the USE classifier: with no panels up there
		// is nothing to take, so a part-finished press is void. Dropping
		// mUseArmed here also hands the button straight back to the
		// engine, which is what makes a door work again the instant the
		// card goes away.
		mUseHeld  = 0;
		mUseArmed = false;
		mUseFired = false;
	}

	// -----------------------------------------------------------------
	// Registration
	// -----------------------------------------------------------------
	int RegisterAssembly(RS_PanelAssembly a)
	{
		if (!a) return -1;
		if (mLive.Size() >= RS_PanelController.MaxAssemblies())
		{
			// Oldest out. An options-menu cap plus a radial cull is the
			// design; when the cap bites, the panel you walked away
			// from is the one that goes.
			let old = mLive[0];
			if (old) old.Destroy();
			mLive.Delete(0);
		}
		mLive.Push(a);
		return mLive.Size() - 1;
	}

	void DropAssembly(RS_PanelAssembly a)
	{
		for (int i = 0; i < mLive.Size(); i++)
		{
			if (mLive[i] == a)
			{
				if (mLive[i]) mLive[i].Destroy();
				mLive.Delete(i);
				return;
			}
		}
	}

	void ClearAll()
	{
		for (int i = 0; i < mLive.Size(); i++)
			if (mLive[i]) mLive[i].Destroy();
		mLive.Clear();
		ClearHot();
	}

	// -----------------------------------------------------------------
	// AIM -- FROM THE HANDS, NOT FROM THE VIEW.
	//
	// The ray starts where the weapon is actually held. GZDoom exposes a
	// full per-hand pose natively -- AttackPos/Angle/Pitch/Roll for the
	// main hand and OffhandPos/Angle/Pitch/Roll for the off hand
	// (actor.zs:268-275) -- and OverrideAttackPosDir (:276) says whether
	// VR is really driving them. It is the same pose the engine spawns
	// projectiles from, so pointing at a panel and shooting at it agree
	// about where you were pointing.
	//
	// Flat play falls back to the view ray, so nothing here needs a
	// headset to be testable.
	//
	// WHICH HAND POINTED IS RECORDED, and that turns out to settle the
	// Hand Law by itself: point at the card with your left controller
	// and the drop goes to your left hand. No per-wing buttons, no rule
	// to memorise, no new bind.
	//
	// uv is 0..1 with (0,0) at the panel's TOP-LEFT as the reader sees
	// it -- the origin RS_PanelCard.RowAtUV expects. The old engine used
	// bottom-left and it was a permanent source of off-by-one-row
	// confusion; top-left matches how the card is painted and read.
	// -----------------------------------------------------------------
	play void SolveAim(PlayerPawn pawn)
	{
		mHotAssembly = -1; mHotPanel = -1; mHotHand = -1;
		mHotDist = NO_HIT_DIST;
		mAimAssembly = -1; mAimPanel = -1; mAimHand = -1;
		mAimDist = NO_HIT_DIST;
		if (!pawn)
		{
			mHotRow = -1; mHotRowLive = false;
			mAimRow = -1; mAimRowLive = false;
			return;
		}

		double best = NO_HIT_DIST;

		// Hand 0 = offhand/left, 1 = mainhand/right. Two rays, nearest
		// hit across both wins.
		for (int hand = 0; hand < 2; hand++)
		{
			Vector3 origin;
			double  yaw, pit;

			if (pawn.OverrideAttackPosDir)
			{
				// Tracked controllers.
				origin = (hand == 0) ? pawn.OffhandPos   : pawn.AttackPos;
				yaw    = (hand == 0) ? pawn.OffhandAngle : pawn.AttackAngle;
				pit    = (hand == 0) ? pawn.OffhandPitch : pawn.AttackPitch;
			}
			else
			{
				// Flat play: one ray down the view, and only once --
				// two identical rays would just cost double.
				if (hand == 1) continue;
				origin = (pawn.pos.x, pawn.pos.y,
				          pawn.player ? pawn.player.viewz : pawn.pos.z + 41);
				yaw    = pawn.angle;
				pit    = pawn.pitch;
			}

			Vector3 dir = (cos(yaw) * cos(pit), sin(yaw) * cos(pit), -sin(pit));
			TraceHand(origin, dir, hand, best);
		}

		// SNAPSHOT THE RAY'S ANSWER BEFORE TOUCH IS ALLOWED TO SPEAK.
		// This is what the trigger reads. See the mAim* declarations.
		mAimAssembly = mHotAssembly;
		mAimPanel    = mHotPanel;
		mAimHand     = mHotHand;
		mAimUV       = mHotUV;
		mAimDist     = mHotDist;

		// TOUCH BEATS POINTING, so it runs last and overwrites.
		TracePoke(pawn);
	}

	// -----------------------------------------------------------------
	// THE POKE -- the "punchable" half, and the only one of the two
	// physical routes that is genuinely its own gesture.
	//
	// This is a POSITION test, not a ray: is the hand actually in the
	// panel? Reaching out and putting your hand on a row is a stronger
	// statement of intent than a ray that happens to graze it from
	// across the room, so a poke wins outright over both aim rays.
	//
	// Tracked hands only. Without OverrideAttackPosDir the "hand"
	// position is the player's own origin, which would put you
	// permanently inside any panel you walked through.
	//
	// A hand that DRIVES INTO a panel also activates the row outright --
	// that is the punch. See TracePoke below; PanelUnderHand is just the
	// containment test it is built on.
	// -----------------------------------------------------------------

	// Scratch results for PanelUnderHand, as FIELDS rather than out
	// params. `out double` has precedent in this file (TraceHand), but a
	// Vector2 out param sitting alongside a returned object reference
	// appears nowhere in this tree -- and a construct with no precedent
	// is not something to guess at when the compiler cannot be run to
	// settle it. Fields are boring and certain.
	//
	// Only ever valid immediately after a PanelUnderHand call that
	// returned non-null.
	int      mScanAsm, mScanPanel;
	Vector2  mScanUV;

	// How far off the face the hand actually was, unsigned. Published
	// because the contact latch needs TWO thresholds from ONE scan: enter
	// at rs_panel_poke, release only past rs_panel_pokerelease times that.
	// Scanning twice per hand per tic to get them would double the cost of
	// the only per-tic loop in this file for a number the scan already had
	// in a local and threw away.
	double   mScanOff;

	// Which panel is this hand inside, if any? Split out of TracePoke so
	// the hand loop can compare TWO hands before deciding, which the
	// first-hit-wins version could not.
	play RS_Panel PanelUnderHand(Vector3 hp, double depth)
	{
		mScanAsm = -1; mScanPanel = -1; mScanUV = (0, 0);
		mScanOff = NO_HIT_DIST;

		// NEAREST FACE WINS, NOT THE FIRST ONE FOUND. Changed 2026-08-08.
		//
		// This used to return on its first containment hit, which was
		// tolerable while the test band was thin and became wrong the
		// moment hysteresis widened it: a triptych's wings are hinged at
		// 35 degrees off a centre panel, so their release slabs overlap,
		// and registration order rather than geometry decided which face
		// your hand was on. The visible form of that is a highlight one
		// panel to the side of your hand -- and since the wings are the
		// only rows that DO anything, it is also the take going to the
		// wrong hand.
		RS_Panel found = null;

		for (int a = 0; a < mLive.Size(); a++)
		{
			let asm = mLive[a];
			if (!asm) continue;

			for (int p = 0; p < asm.Size(); p++)
			{
				let pan = asm.Get(p);
				if (!pan) continue;

				Vector3 local = hp - pan.pos;

				// Distance off the face, signed either way -- a hand
				// that has punched THROUGH the card is still on it.
				// Held in a local rather than nested inside abs():
				// every other `dot` in this file is either its own
				// statement or explicitly parenthesised, and this is
				// not the codebase to get clever about precedence in.
				double off = local dot pan.FaceVec();
				double aoff = abs(off);
				if (aoff > depth) continue;
				if (aoff >= mScanOff) continue;   // a nearer face already won

				double lx = local dot pan.RightVec();
				double ly = local dot pan.UpVec();

				if (abs(lx) > pan.mWidth  * 0.5) continue;
				if (abs(ly) > pan.mHeight * 0.5) continue;

				mScanAsm   = a;
				mScanPanel = p;
				mScanUV    = (lx / pan.mWidth + 0.5, 0.5 - ly / pan.mHeight);
				mScanOff   = aoff;
				found      = pan;
			}
		}

		if (!found) mScanOff = NO_HIT_DIST;
		return found;
	}

	// mHavePrevHand is deliberately NOT touched here -- WorldTick owns
	// it, sets it once per tic after this runs, and is the only writer.
	// Clearing it from here as well would have been a second owner of a
	// flag whose whole job is to say whether one specific snapshot is
	// trustworthy.
	play void TracePoke(PlayerPawn pawn)
	{
		if (!pawn.OverrideAttackPosDir) return;

		double depth = RS_PanelInput.PokeDepth();
		if (depth <= 0) return;

		// The release band. Clamped at or above 1 so a misconfigured value
		// can never make the release band NARROWER than the entry band,
		// which would turn the hysteresis into a repeat-fire.
		double release = depth * max(1.0, RS_PanelInput.PokeRelease());

		double punch      = RS_PanelInput.PunchSpeed();
		bool   contacts   = RS_PanelInput.TouchPress();

		// WHICH HAND SPEAKS FOR THE PANEL THIS TIC, ranked rather than
		// first-come:
		//
		//   2  this hand PRESSED       -- a deliberate act beats everything
		//   1  this hand is in CONTACT -- on the panel, not pressing
		//   0  this hand is HOVERING   -- inside the release band only
		//
		// Ranking matters because the two hands are usually in different
		// states and the old "first hit, unless the other one struck" test
		// could not express that. A left hand hovering an inch off the card
		// outranked a right hand resting ON it purely by loop order, and the
		// highlight -- and therefore the row a keypress would take -- sat
		// under the wrong hand.
		int     bestHand = -1, bestAsm = -1, bestPanel = -1;
		Vector2 bestUV   = (0, 0);
		int     bestRank = -1;
		bool    bestIsPress = false;

		for (int hand = 0; hand < 2; hand++)
		{
			Vector3 hp   = (hand == 0) ? pawn.OffhandPos : pawn.AttackPos;
			Vector3 prev = (hand == 0) ? mPrevHand0      : mPrevHand1;

			bool latched  = (hand == 0) ? mTouchLatch0   : mTouchLatch1;
			int  latchAsm = (hand == 0) ? mTouchOnAsm0   : mTouchOnAsm1;
			int  latchPan = (hand == 0) ? mTouchOnPanel0 : mTouchOnPanel1;
			int  cool     = (hand == 0) ? mPokeCool0     : mPokeCool1;

			// ONE scan, at the WIDER of the two bands. Everything inside
			// `release` is still "near this panel" for the purpose of
			// holding a latch; only what is also inside `depth` counts as
			// contact. Scanning at the narrow band instead would drop the
			// latch the instant a resting hand drifted a millimetre out,
			// which is the jitter this exists to absorb.
			let pan = PanelUnderHand(hp, release);

			if (!pan)
			{
				// Out of the release band entirely: this hand has left, and
				// its next arrival is a fresh press.
				if (hand == 0) { mTouchLatch0 = false; mTouchOnAsm0 = -1; mTouchOnPanel0 = -1; }
				else           { mTouchLatch1 = false; mTouchOnAsm1 = -1; mTouchOnPanel1 = -1; }
				continue;
			}

			int     ai = mScanAsm;
			int     pi = mScanPanel;
			Vector2 uv = mScanUV;
			bool    inContact = (mScanOff <= depth);

			// A hand that has slid onto a DIFFERENT panel has left the one
			// it was latched to, even without ever leaving the release band
			// -- which is exactly what running a finger along a triptych's
			// three faces does. Without this, the first face you touched
			// would be the only one that ever pressed.
			//
			// Written through, not just held in the local: the stored flag
			// is what the NEXT tic reads, and a hand that slides onto a new
			// panel while still short of contact would otherwise arrive
			// already latched and never press it.
			if (latched && (latchAsm != ai || latchPan != pi))
			{
				latched = false;
				if (hand == 0) mTouchLatch0 = false;
				else           mTouchLatch1 = false;
			}

			// --- ROUTE A1: CONTACT. The hand arrived. -----------------
			bool press = false;
			if (contacts && inContact && !latched)
				press = true;

			// --- ROUTE A2: THE PUNCH. -----------------------------------
			// A SWING, not a presence. Travel this tic projected onto the
			// face normal, which points from the panel toward the reader
			// (FaceViewer builds it that way) -- so pressing INTO the card
			// is negative along it, and the sign flip makes "into" read
			// positive.
			//
			// Still here after contact took over the ordinary case, and it
			// earns its place: it is the only way to press the SAME row
			// again without pulling your hand back out past the release
			// band first.
			if (inContact && mHavePrevHand && punch > 0)
			{
				Vector3 travel = hp - prev;
				double  along  = travel dot pan.FaceVec();
				if (-along >= punch) press = true;
			}

			// The cooldown is the last word on both routes, so a jitter at
			// the very edge of the release band cannot machine-gun by
			// crossing it repeatedly.
			if (press && cool > 0) press = false;

			if (inContact)
			{
				if (hand == 0) { mTouchLatch0 = true; mTouchOnAsm0 = ai; mTouchOnPanel0 = pi; }
				else           { mTouchLatch1 = true; mTouchOnAsm1 = ai; mTouchOnPanel1 = pi; }
			}
			else if (!latched)
			{
				// Inside the release band but never latched -- hovering
				// just short of contact. Nothing to remember.
				if (hand == 0) { mTouchOnAsm0 = ai; mTouchOnPanel0 = pi; }
				else           { mTouchOnAsm1 = ai; mTouchOnPanel1 = pi; }
			}

			if (press)
			{
				if (hand == 0) mPokeCool0 = POKE_COOLDOWN_TICS;
				else           mPokeCool1 = POKE_COOLDOWN_TICS;
			}

			int rank = press ? 2 : (inContact ? 1 : 0);
			if (rank > bestRank)
			{
				bestRank    = rank;
				bestHand    = hand;
				bestAsm     = ai;
				bestPanel   = pi;
				bestUV      = uv;
				bestIsPress = press;
			}
		}

		if (bestHand < 0) return;

		mHotAssembly = bestAsm;
		mHotPanel    = bestPanel;
		mHotHand     = bestHand;
		mHotUV       = bestUV;

		// A hand INSIDE the panel is at zero range by definition, and
		// saying so is what lets the shot's range gate be a single test
		// against mHotDist rather than a special case per route.
		mHotDist     = 0;

		if (bestIsPress)
			mPokeStrikeHand = bestHand;
	}

	// One hand's ray against every live panel. `best` carries in so a
	// nearer hit from the other hand is not overwritten by a farther one.
	// Is any live assembly using the billboard backend? Guards the native
	// call so a mod running purely on flatsprites never touches it -- and
	// so this whole file still works if the engine build in front of it
	// has no billboard support at all.
	play bool AnyBillboardBacked() const
	{
		for (int a = 0; a < mLive.Size(); a++)
			if (mLive[a] && mLive[a].mBackend == RSPB_Billboard)
				return true;
		return false;
	}

	play void TraceHand(Vector3 origin, Vector3 dir, int hand, out double best)
	{
		// -------------------------------------------------------------
		// NATIVE PATH FIRST, for assemblies on the billboard backend.
		//
		// AimBillboard returns the hit id and the UV THE SHADER USED. The
		// hand-rolled maths below returns the UV we BELIEVE the shader
		// used, and the two drift -- silently, and only in the way that
		// matters: a row stops being clickable where it looks clickable.
		// One engine call removes that entire class of bug.
		//
		// Runs once per hand rather than per panel, because the engine
		// tests every registered billboard itself.
		// -------------------------------------------------------------
		// Whether the engine's answer actually landed on a panel we own. See
		// the fallback note at the flatsprite loop below.
		bool nativeResolved = false;

		if (AnyBillboardBacked())
		{
			int hitId; Vector2 uv;
			[hitId, uv] = level.AimBillboard(origin, dir);

			if (hitId != 0)
			{
				for (int a = 0; a < mLive.Size(); a++)
				{
					let asm = mLive[a];
					if (!asm) continue;

					int p = asm.PanelForHandle(hitId);
					if (p < 0) continue;

					let pan = asm.Get(p);
					if (!pan) continue;

					nativeResolved = true;

					// Distance so this competes fairly with the flatsprite
					// hits below -- the two backends can be on screen at
					// once and the NEAREST must win regardless of which
					// primitive drew it.
					double t = (pan.pos - origin).Length();
					if (t <= 0 || t >= best) continue;

					best         = t;
					mHotDist     = t;
					mHotAssembly = a;
					mHotPanel    = p;
					mHotHand     = hand;
					mHotUV       = uv;
					break;
				}
			}
		}

		for (int a = 0; a < mLive.Size(); a++)
		{
			let asm = mLive[a];
			if (!asm) continue;

			// Billboard-backed panels were resolved natively above; running
			// them through the ray/plane test too would let the OLD maths
			// overwrite the engine's own answer, which is exactly backwards.
			//
			// UNLESS THE ENGINE'S ANSWER WAS ABOUT SOMETHING ELSE. AimBillboard
			// tests EVERY registered billboard and returns only the nearest
			// one, and a composed card is forty small billboards of its own
			// text. So a decorative quad standing between the hand and a
			// billboard-backed panel wins the native query, maps to no panel
			// here, and the panel behind it silently stops being pointable --
			// no hit, no fallback, nothing to see. Falling through to the
			// script test only when nothing native resolved keeps the engine's
			// answer authoritative where it exists and keeps the panel
			// reachable where it does not.
			//
			// The real fix is BBFL_NOHIT (added to the engine 2026-08-08) on
			// every decorative part, which makes the native query answer about
			// panels only. This stays as the belt: an older engine, or a part
			// someone forgets to flag, degrades to slightly-worse maths rather
			// than to a dead panel.
			if (asm.mBackend == RSPB_Billboard && nativeResolved) continue;

			for (int p = 0; p < asm.Size(); p++)
			{
				let pan = asm.Get(p);
				if (!pan) continue;

				Vector3 n = pan.FaceVec();
				double denom = dir dot n;
				if (abs(denom) < 0.0001) continue;   // ray parallel to the face

				double t = ((pan.pos - origin) dot n) / denom;
				if (t <= 0 || t >= best) continue;   // behind the hand, or farther than a hit we hold

				Vector3 local = (origin + dir * t) - pan.pos;

				double lx = local dot pan.RightVec();
				double ly = local dot pan.UpVec();

				if (abs(lx) > pan.mWidth  * 0.5) continue;
				if (abs(ly) > pan.mHeight * 0.5) continue;

				best         = t;
				mHotDist     = t;
				mHotAssembly = a;
				mHotPanel    = p;
				mHotHand     = hand;
				mHotUV       = (lx / pan.mWidth + 0.5, 0.5 - ly / pan.mHeight);
			}
		}
	}

	// -----------------------------------------------------------------
	override void WorldTick()
	{
		if (!RS_PanelController.Enabled())
		{
			if (mLive.Size() > 0) ClearAll();
			else ClearHot();
			return;
		}

		// A stale hot row is not harmless now that something PRESSES it.
		// Before the confirm existed these fields were read only by the
		// painter, which draws nothing when there is no card, so leaving
		// them set on the way out cost nothing. The trigger capture runs
		// in PlayerThink and does not know whether a card is up -- so
		// every path that leaves this function without solving has to
		// say "nothing is hot" rather than leave the last answer lying
		// around.
		if (mLive.Size() == 0) { ClearHot(); return; }

		PlayerPawn pawn = players[consoleplayer].mo;
		if (!pawn) { ClearHot(); return; }

		// Live view z, not pos.z + a constant. See HeightOfs above.
		Vector3 eye = (pawn.pos.x, pawn.pos.y, pawn.player.viewz);

		for (int i = 0; i < mLive.Size(); i++)
			if (mLive[i]) mLive[i].Solve(eye);

		if (mPokeCool0 > 0) mPokeCool0--;
		if (mPokeCool1 > 0) mPokeCool1--;

		// Aim comes off the HANDS, not the view -- see SolveAim.
		SolveAim(pawn);

		// Snapshot the hands AFTER solving, so TracePoke measured travel
		// against where they were last tic rather than against
		// themselves. Dropping the flag when VR is not driving stops a
		// stale pair from reading as one enormous lunge the moment
		// tracked poses come back.
		if (pawn.OverrideAttackPosDir)
		{
			mPrevHand0    = pawn.OffhandPos;
			mPrevHand1    = pawn.AttackPos;
			mHavePrevHand = true;
		}
		else
		{
			mHavePrevHand = false;
		}

		// Row resolution needs the card, which the triptych owns; the
		// hot row is recomputed there when it repaints. Storing the uv
		// is what couples the two without either knowing the other.
	}

	override void WorldUnloaded(WorldEvent e)
	{
		ClearAll();
	}
}
