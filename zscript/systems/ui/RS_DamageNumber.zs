// =====================================================================
// RS_DamageNumber -- the number that comes off a hit.
// ---------------------------------------------------------------------
// Design of record: docs/rs_damage_numbers_spec.md. Read it before
// changing anything here; every non-obvious decision below is answering
// a paragraph in it.
//
// WHAT THIS IS. A world-space floating number, made of a parent actor
// that owns the physics and one child actor per drawn glyph. The parent
// is invisible; it exists so that a multi-digit number is ONE thing with
// one velocity, one lifetime and one roll, rather than N sprites that
// have to be kept in agreement.
//
// WORLD-SPACE, NOT HUD. Same argument as the health bars, and it is
// written down at the top of RS_HealthBars.zs: a screen-space number
// pinned to the view has no depth, and in a headset that sits on your
// face. Do not "simplify" this into a HUD draw.
//
// ---------------------------------------------------------------------
// REGISTRATION -- THREE THINGS, AND TWO OF THEM FAIL SILENTLY
//
//   1. This file must be in zscript.txt's include list. A .zs that is
//      not included does not exist -- no error, the classes are simply
//      absent.
//   2. RS_DamageNumberHandler MUST be added to MAPINFO.txt's
//      GameInfo { AddEventHandlers = ... }. That handler is the live
//      number registry: it holds the cap list and the cached CVar
//      handles. WITHOUT IT the numbers still appear and still read the
//      cvars, but THE CAP DOES NOT APPLY and every spawn pays a full
//      set of CVar.FindCVar string lookups instead of reading cached
//      handles. See RS_DNSettings for the fallback.
//   3. The sprites must exist. RSDN A-J are the digits 0-9 and RSDH A-J
//      are the soft halos behind them. They are registered by the Spawn
//      states of RS_DNDigit / RS_DNHalo, which is the only thing that
//      puts a sprite name into the engine's sprite table.
//
//      A sprite name with no lumps on disk is NOT an error -- the engine
//      sets numframes = 0 and draws nothing (r_data/sprites.cpp:188).
//      So this file compiles and boots against art that does not exist
//      yet, and the failure mode is invisible numbers, not a crash.
//
// ---------------------------------------------------------------------
// COLOUR IS A STENCIL, NOT A TRANSLATION
//
// The digits are drawn with RenderStyle "Stencil" and their colour comes
// from SetShade(). That is the only way to get a colour that VARIES AT
// RUNTIME -- headshot gold saturates with the shot's quality, so there
// is no fixed set of colours a TRNSLATE table could hold.
//
// Verified against the engine rather than assumed:
//   * thingdef_properties.cpp:753-768 -- the Default property spelled
//     "Stencil" maps to STYLE_TranslucentStencil, NOT to the ZScript
//     enum STYLE_Stencil. The difference matters: STYLE_Stencil carries
//     STYLEF_Alpha1 and would refuse to fade. The one this file wants is
//     the property spelling.
//   * hw_sprites.cpp:1469 -- a style with STYLEF_ColorIsFixed takes its
//     colour from the actor's `fillcolor`, and fillcolor is what
//     SetShade() writes (p_mobj.cpp:3637).
//   * main.fp:195 -- TM_STENCIL replaces rgb with white and KEEPS the
//     texture's alpha, so the glyph's shape and its antialiased edge
//     survive; only its colour is replaced.
//
// THE COST: the digit art's own internal shading is discarded. A digit
// sprite here should be authored as a flat white glyph with its shape in
// the alpha channel. Anything painted into its rgb will not survive.
//
// The halo uses "AddShaded" instead, which is TM_ALPHATEXTURE
// (main.fp:207): alpha = greyscale * alpha. That is deliberate and it is
// the robust choice -- it produces a soft glow whether the halo art
// carries its falloff in the alpha channel or in rgb brightness, so it
// cannot be broken by how the art happens to have been generated.
//
// NO DYNAMIC LIGHTS ANYWHERE IN THIS FILE, per the spec: a shower of
// numbers lighting the geometry reads as a bug.
//
// ---------------------------------------------------------------------
// THE COST MODEL, HONESTLY
//
// Each live number runs one Tick and one SetOrigin per glyph per tic.
// SetOrigin is used rather than SetXYZ because it relinks the actor into
// its sector -- a glyph that drifts across a sector boundary without
// relinking renders from the wrong subsector, which is visible. It also
// refreshes floorz (p_maputl.cpp:569 calls P_FindFloorCeiling), which is
// what the landing test reads.
//
// At the shipped defaults the glow is OFF, so a three-digit number costs
// four SetOrigins a tic. rs_dn_max is the bound on all of it. That is
// the same shape of cost RS_HealthBars already pays for every monster on
// the map, so it is a known quantity here, but it is not free -- if this
// ever needs profiling, the glow toggle is the big lever.
// =====================================================================

// The hit kinds. Public contract -- the emit site in
// zscript/systems/weapon/RS_Headshot.zs codes against these names and
// these values. Do not renumber.
enum RS_DNType
{
	RS_DN_NORMAL   = 0,
	RS_DN_CRIT     = 1,
	RS_DN_HEAD     = 2,
	RS_DN_CRITHEAD = 3,
	RS_DN_KILL     = 4
}

// =====================================================================
// CVAR HANDLES, HELD ONCE.
//
// The handle lookup is the string-keyed part and is what costs; reading
// GetInt()/GetFloat() off a held handle is cheap and stays live, so the
// options menu keeps working immediately. Same pattern and same reason
// as RS_HealthBars.
//
// This lives in its own object rather than on the handler so that a
// number can still be spawned when the handler was never registered in
// MAPINFO -- in that case each number makes its own copy. That path is
// correct but slow, and it exists only so the feature degrades to
// "works, uncapped" instead of "silently does nothing".
// =====================================================================
// `play`: this reads CVar handles on behalf of actors and is held by an
// EventHandler, both of which are play scope. An unscoped class is DATA
// scope, and a data object calling into play is the "Can't call play
// function ... from data context" error this tree has already hit in
// rs_monster_utils.zs. RS_CritMark and RS_HeadshotUtil carry the same
// keyword for the same reason.
class RS_DNSettings play
{
	CVar cvEnable, cvScale, cvMax, cvLifetime;
	CVar cvSignificance, cvColour, cvMotion, cvGlow;
	CVar cvOverkill, cvPerHand, cvDistance, cvMinimum;

	void RS_Cache()
	{
		if (!cvEnable)       cvEnable       = CVar.FindCVar("rs_dn_enable");
		if (!cvScale)        cvScale        = CVar.FindCVar("rs_dn_scale");
		if (!cvMax)          cvMax          = CVar.FindCVar("rs_dn_max");
		if (!cvLifetime)     cvLifetime     = CVar.FindCVar("rs_dn_lifetime");
		if (!cvSignificance) cvSignificance = CVar.FindCVar("rs_dn_significance");
		if (!cvColour)       cvColour       = CVar.FindCVar("rs_dn_colour");
		if (!cvMotion)       cvMotion       = CVar.FindCVar("rs_dn_motion");
		if (!cvGlow)         cvGlow         = CVar.FindCVar("rs_dn_glow");
		if (!cvOverkill)     cvOverkill     = CVar.FindCVar("rs_dn_overkill");
		if (!cvPerHand)      cvPerHand      = CVar.FindCVar("rs_dn_perhand");
		if (!cvDistance)     cvDistance     = CVar.FindCVar("rs_dn_distance");
		if (!cvMinimum)      cvMinimum      = CVar.FindCVar("rs_dn_minimum");
	}

	// Null-safe readers. A cvar that is not declared reads as its stated
	// default rather than as zero -- a missing CVARINFO entry must not
	// silently turn the whole feature off.
	//
	// NOT declared const, deliberately: CVar.GetInt/GetFloat are not
	// const themselves (base.zs:703-704), and ZScript will not let a
	// const method call a non-const one.
	int    RS_I(CVar c, int d)    { return c ? c.GetInt()   : d; }
	double RS_F(CVar c, double d) { return c ? c.GetFloat() : d; }
	bool   RS_B(CVar c, bool d)   { return c ? (c.GetInt() != 0) : d; }
}

// =====================================================================
// THE LIVE REGISTRY AND THE CAP.
//
// A plain counter and a list, incremented on spawn and decremented in
// OnDestroy. NOT a ThinkerIterator scan: RS_HiFiFX.SpawnMuzzleLight
// counts that way and it is fine at a few shots per second, but damage
// numbers spawn at a rate where the scan would cost more than the thing
// it protects. The spec calls this out explicitly.
//
// A plain EventHandler rather than a StaticEventHandler, deliberately:
// MAPINFO recreates it per map, so the list starts empty on every level
// and there is no way for a stale pointer from the last map to survive
// into this one.
//
// MUST BE LISTED IN MAPINFO.txt's AddEventHandlers or none of this runs.
// =====================================================================
class RS_DamageNumberHandler : EventHandler
{
	// Newest last, so index 0 is the oldest and is what gets recycled.
	private Array<RS_DamageNumber> rsLive;

	// Shared handles, built on first use by whichever number gets here
	// first.
	RS_DNSettings rsCV;

	// Every method here carries an RS_ prefix on purpose. StaticEventHandler
	// is a native class and a name that collides with something on it is a
	// redefinition, not an override -- ZScript has no shadowing. The rest
	// of this repo's handlers use the same prefix (RS_LearnGate,
	// RS_NextGate, RS_SpawnBarFor) and for the same reason.
	RS_DNSettings RS_Settings()
	{
		if (!rsCV) rsCV = new("RS_DNSettings");
		rsCV.RS_Cache();
		return rsCV;
	}

	static RS_DamageNumberHandler RS_Get()
	{
		return RS_DamageNumberHandler(EventHandler.Find("RS_DamageNumberHandler"));
	}

	int RS_LiveCount() { return rsLive.Size(); }

	// -----------------------------------------------------------------
	// LIVE DYNAMIC LIGHTS. Lives here rather than on RS_DNLight because
	// ZSCRIPT DOES NOT ALLOW STATIC MEMBER VARIABLES ON A CLASS -- the
	// first attempt declared `private static int rsLive;` on the light
	// and the compiler rejected it outright:
	//
	//   Invalid qualifiers for rsLive (static not allowed)
	//
	// An EventHandler is the natural home anyway: there is exactly one of
	// it, it already owns the number registry directly above, and it
	// outlives every actor it counts.
	//
	// Deliberately NOT named rsLive -- that name is taken by the array
	// above, and ZScript has no shadowing, so reusing it would be a
	// redefinition rather than a separate field.
	// -----------------------------------------------------------------
	int rsLightCount;

	// Make room for one more. Called before the new number is spawned, so
	// the ceiling is a ceiling rather than a ceiling-plus-one.
	//
	// The oldest is DESTROYED rather than reused: a number carries a
	// dozen fields set at birth (colour, path, launch, jitter) and
	// rebuilding all of them in place is the same work as a fresh spawn
	// with an extra way to get it wrong.
	void RS_MakeRoom(int cap)
	{
		if (cap < 1) cap = 1;

		// Prune anything the engine already nulled out from under us --
		// a destroyed object's pointers go null, so this cannot leak.
		for (int i = rsLive.Size() - 1; i >= 0; i--)
		{
			if (!rsLive[i]) rsLive.Delete(i);
		}

		while (rsLive.Size() >= cap)
		{
			let oldest = rsLive[0];
			rsLive.Delete(0);
			// bDestroyed as well as the null test: OnDestroy removes the
			// entry itself, so a survivor here should be live, and calling
			// Destroy on something already torn down is not worth risking
			// for the one line it costs to check.
			if (oldest && !oldest.bDestroyed) oldest.Destroy();
		}
	}

	void RS_Register(RS_DamageNumber n)
	{
		if (n) rsLive.Push(n);
	}

	void RS_Release(RS_DamageNumber n)
	{
		if (!n) return;
		for (int i = 0; i < rsLive.Size(); i++)
		{
			if (rsLive[i] == n)
			{
				rsLive.Delete(i);
				return;
			}
		}
	}
}

// =====================================================================
// ONE DRAWN GLYPH.
//
// It has no Tick and no logic of its own. The parent positions it,
// scales it, rolls it and fades it every tic, and destroys it in
// OnDestroy -- the same ownership shape RS_HPBar uses for its chip,
// mark and bracket, and for the same reason: everything that hangs off
// one number needs the same transform, and one actor computing it once
// cannot drift out of sync with itself.
// =====================================================================
class RS_DNGlyph : Actor
{
	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		// SetOrigin runs every tic and without NOBLOCKMAP each call would
		// unlink and relink a sprite that can never touch anything.
		// NOINTERACTION does not imply it. NOSECTOR must NOT be added --
		// sector linkage is what makes a sprite render at all.
		+NOINTERACTION
		+ZDOOMTRANS
		+ROLLSPRITE
		+ROLLCENTER
		// +INTERPOLATEANGLES is what makes a tumble smooth instead of
		// stepping at 35Hz. It is the easiest of the four to forget and
		// the most obvious when it is missing.
		// (thingdef_data.cpp:377)
		+INTERPOLATEANGLES
		Alpha 1.0;
		Radius 1;
		Height 1;
	}

	// Layout, written by the parent when the number is built.
	// dnOffsetEm is measured in ADVANCE UNITS from the row's centre, so
	// it is independent of how big the number happens to be this tic.
	double dnOffsetEm;
	double dnSizeMul;
	double dnAlphaMul;

	// The art's own size AND its offsets, read once.
	//
	// Everything is expressed as a target world HEIGHT and converted
	// through the size, so these numbers do not change if the digit art is
	// regenerated at a different resolution.
	//
	// THE OFFSETS ARE READ RATHER THAN ASSUMED, and that is load-bearing.
	// A PNG with no `grAb` chunk gets offsets of ZERO
	// (pngtexture.cpp:242 only writes them when the chunk is present, and
	// nothing else defaults them), which puts the actor's position at the
	// glyph's CORNER, not its middle -- so an uncompensated number sits
	// half a glyph off the hit that caused it. Reading them means this
	// file is right whether or not the art ever gets centred offsets, and
	// the compensation falls to zero the moment it does.
	double dnTexW, dnTexH;
	double dnOffX, dnOffY;
	private bool dnMeasured;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		// A stencil style reads its colour from fillcolor, and fillcolor
		// starts life as 0 -- which is BLACK, not "unset". A glyph whose
		// SetShade never ran would draw as a black hole. Seed it.
		SetShade(Color(255, 255, 255, 255));

		bBright    = true;
		dnSizeMul  = 1.0;
		dnAlphaMul = 1.0;
	}

	// Fallbacks are deliberately nonzero: the art may not be on disk yet,
	// and a zero height would divide the whole layout by zero.
	void RS_Measure()
	{
		if (dnMeasured) return;
		dnMeasured = true;
		dnTexW = 8.0;
		dnTexH = 12.0;
		dnOffX = 0.0;
		dnOffY = 0.0;

		if (!CurState) return;

		TextureID tex;
		bool flip;
		Vector2 texScale;
		[tex, flip, texScale] = CurState.GetSpriteTexture(0);
		if (!tex.IsValid()) return;

		Vector2 sz = TexMan.GetScaledSize(tex);
		if (sz.x > 0.0 && sz.y > 0.0)
		{
			dnTexW = sz.x;
			dnTexH = sz.y;
		}

		Vector2 off = TexMan.GetScaledOffset(tex);
		dnOffX = off.x;
		dnOffY = off.y;
	}

	// Set the glyph's world height in map units, honouring a non-uniform
	// stretch. Scale.X and Scale.Y are assigned SEPARATELY and at
	// RUNTIME, which is the supported way -- the engine's `scale` Default
	// property takes one float and writes both axes, so a non-uniform
	// scale is impossible in a Default block. See CLAUDE.md; this is the
	// "do it in code instead" that note points at.
	void RS_SizeTo(double worldH, double stretchX, double stretchY)
	{
		RS_Measure();
		double s = worldH / dnTexH;
		Scale.X = s * stretchX;
		Scale.Y = s * stretchY;
	}

	// Point this glyph at one of the thirteen sets. `digit` is 0-9 and
	// maps to frames A-J. Called once at build time, never per tic.
	void RS_SetFont(int fontIdx, int digit, bool isHalo)
	{
		String p = RS_DNFont.Prefix(fontIdx);
		if (isHalo)
			p = "DH" .. p.Mid(2);
		int spr = GetSpriteIndex(p);
		if (spr > 0)
			Sprite = spr;
		Frame = clamp(digit, 0, 9);
	}

}

// The digits. RSDN frame A = 0 ... frame J = 9, so the frame index IS
// the digit and no lookup table is needed.
//
// "Stencil" here is the Default-property spelling, which the engine maps
// to STYLE_TranslucentStencil -- solid colour from SetShade, alpha
// honoured so it can fade out. See this file's header for the source
// lines; do not "correct" it to the STYLE_Stencil enum, which forces
// alpha to 1 and would make the fade a hard pop.
// -------------------------------------------------------------------
// THE DIGIT SETS.
//
// Thirteen of them, all real pixel art at their own native sizes. They
// are NOT scaled to match each other and must not be -- the actor sizes
// every number off the art's measured height at runtime, so a set stays
// whatever it was drawn as and the world scale does the rest.
//
// Returned as a prefix rather than a sprite index because the halo set
// is the same name with DH for DN, so one lookup answers both.
//
// A switch, NOT a `static const String[]`. Array literals of that shape
// do not reliably resolve on this engine build -- found and fixed three
// separate times in this tree, symptom is a bogus "Unknown identifier".
// -------------------------------------------------------------------
class RS_DNFont
{
	static String Prefix(int idx)
	{
		switch (idx)
		{
		case 1:  return "DN02";
		case 2:  return "DN03";
		case 3:  return "DN04";
		case 4:  return "DN05";
		case 5:  return "DN06";
		case 6:  return "DN07";
		case 7:  return "DN08";
		case 8:  return "DN09";
		case 9:  return "DN10";
		case 10: return "DN11";
		case 11: return "DN12";
		case 12: return "DN13";
		}
		// 0 and anything out of range land on the default set. DN01 is
		// the same art as RSDN; the duplicate exists so the picker can
		// index every set uniformly.
		return "DN01";
	}
}

class RS_DNDigit : RS_DNGlyph
{
	Default
	{
		RenderStyle "Stencil";
	}

	// The state below names RSDN so the sprite is REGISTERED -- GZDoom
	// only enters a name into the sprite table if some actor state
	// references it, and a name that never appears in a state resolves
	// to nothing at runtime. Every alternate set is reached through
	// RS_SetFont instead, which is why RS_DNFontRegistry exists further
	// down: without it, twelve of the thirteen sets would silently draw
	// blank. Same trick RS_HealthBars uses for its bar frames.
	States
	{
	Spawn:
		RSDN A -1;
		Stop;
	}

}

// -------------------------------------------------------------------
// SPRITE REGISTRATION -- DO NOT DELETE. Never spawned, no behaviour.
//
// GZDoom only enters a sprite name into its table if an actor STATE
// references it. These sets are chosen at runtime by name, so without a
// state block naming every one of them, GetSpriteIndex returns nothing
// and the digits render BLANK -- with no error, no warning and no log
// line, which is this project's most expensive failure mode.
//
// If a digit set is added, add both its DN and DH prefix here too.
// -------------------------------------------------------------------
class RS_DNFontRegistry : Actor
{
	States
	{
	Spawn:
		DN01 A 1; DN02 A 1; DN03 A 1; DN04 A 1; DN05 A 1; DN06 A 1;
		DN07 A 1; DN08 A 1; DN09 A 1; DN10 A 1; DN11 A 1; DN12 A 1;
		DN13 A 1;
		DH01 A 1; DH02 A 1; DH03 A 1; DH04 A 1; DH05 A 1; DH06 A 1;
		DH07 A 1; DH08 A 1; DH09 A 1; DH10 A 1; DH11 A 1; DH12 A 1;
		DH13 A 1;
		Stop;
	}
}

// The soft halo behind a digit. Additive, larger, low alpha -- this is
// the layer that actually sells "the number is emitting light", and it
// is one extra sprite draw rather than a dynamic light.
//
// "AddShaded" takes the glyph shape from the texture's greyscale times
// its alpha, so the halo art can carry its falloff in either channel and
// still come out soft.
class RS_DNHalo : RS_DNGlyph
{
	Default
	{
		RenderStyle "AddShaded";
	}

	States
	{
	Spawn:
		RSDH A -1;
		Stop;
	}
}

// =====================================================================
// THE NUMBER ITSELF.
// =====================================================================
class RS_DamageNumber : Actor
{
	// ---- size ------------------------------------------------------
	// The world height of a "size 1.0" glyph, in map units. Everything
	// scales off this, and it is expressed as a height rather than a
	// sprite scale so that regenerating the digit art at a different
	// resolution does not silently resize every number in the game.
	const RS_DN_TARGET_H  = 10.0;
	// Horizontal advance as a fraction of the glyph's own width. Slightly
	// over 1 so digits do not touch.
	const RS_DN_TRACKING  = 1.06;
	// The halo is drawn this much taller than the digit it sits behind.
	const RS_DN_HALO_MULT = 1.55;
	const RS_DN_HALO_A_LO = 0.30;
	const RS_DN_HALO_A_HI = 0.55;
	// How far behind the digit the halo sits, in map units. Both layers
	// would otherwise be coplanar and their sort order would be unstable,
	// which flickers.
	const RS_DN_HALO_DEPTH = 0.7;

	const RS_DN_MAXDIGITS = 7;
	// Gap before the dimmed overkill group, in advance units.
	const RS_DN_OVER_GAP  = 0.45;
	const RS_DN_OVER_SIZE = 0.60;
	const RS_DN_OVER_A    = 0.55;

	// ---- life ------------------------------------------------------
	const RS_DN_BORN_TICS  = 4;    // punch in
	const RS_DN_SQUASH_TICS = 3;   // landing squash
	const RS_DN_LANDED_HOLD = 14;  // how long a landed number may linger
	const RS_DN_LIFE_JITTER = 0.20;

	// ---- motion ----------------------------------------------------
	// The round's own velocity is inherited, but at a fraction: a rocket
	// leaves the barrel at ~40 units a tic and a number thrown at that
	// speed is off the map before it is read.
	const RS_DN_IMPULSE_GAIN = 0.12;
	const RS_DN_IMPULSE_MAX  = 6.0;
	const RS_DN_POP          = 2.2;   // upward kick at birth
	const RS_DN_GRAV         = 0.85;
	const RS_DN_DRAG         = 0.985;
	const RS_DN_DRIFT        = 1.10;  // motion OFF: straight up, no more
	const RS_DN_BOUNCE_E     = 0.45;
	const RS_DN_LAND_EPS     = 1.2;   // how high a landed number lies
	const RS_DN_STRETCH_REF  = 8.0;   // speed at which stretch maxes out

	// Trajectories. Consts rather than an enum because they are private
	// to this file, and rather than a static array because
	// `static const T name[] = {...}` does not reliably resolve on this
	// engine build -- three separate bugs in this repo, see CLAUDE.md.
	const RS_DNP_BALLISTIC = 0;
	const RS_DNP_KICK      = 1;
	const RS_DNP_SNAP      = 2;
	const RS_DNP_FLOAT     = 3;
	const RS_DNP_BOUNCE    = 4;

	// A headshot at or above this quality does not travel at all.
	// Stillness reads as precision where a scatter reads as force.
	const RS_DN_SNAP_Q     = 0.80;
	const RS_DN_CHIP_FRAC  = 0.04;
	const RS_DN_HEAVY_FRAC = 0.30;

	// ---- POSITIVE ROLL IS COUNTERCLOCKWISE ON SCREEN ----------------
	//
	// Derived from the engine, not from lore, because getting it backwards
	// tilts the baseline one way and the glyphs the other -- which reads
	// as broken rather than as a wrong angle.
	//
	//   hw_sprites.cpp:585    roll rotates about the axis
	//                         (cos(angleRad), 0, sin(angleRad)) in the
	//                         renderer's (X, height, Y) component order,
	//                         with angleRad = 270 - HWAngles.Yaw.
	//   r_utility.cpp:764     HWAngles.Yaw = 270 - view angle, so
	//                         angleRad IS the view angle and the axis is
	//                         the view direction, pointing away from the
	//                         eye.
	//   matrix.h:149          the rotation built there is the standard
	//                         right-handed Rodrigues form.
	//
	// Working it through for a viewer facing east: a point one unit above
	// the sprite's centre moves to world +Y for a small positive roll,
	// and +Y is that viewer's LEFT -- i.e. counterclockwise on screen.
	//
	// If landed or tumbling numbers ever read with the baseline fighting
	// the glyphs, this sign is the one thing to flip.
	const RS_DN_ROLL_CCW = 1.0;

	// Which way a LANDED (flat) number reads. A flat sprite's local +X
	// maps to world (cos t, -sin t) with t = 270 - angle - roll, and the
	// unmirrored UV assignment puts the texture's RIGHT edge at local +X
	// (hw_sprites.cpp:1362-1374 for the rect, :1283-1292 for the UVs) --
	// so digits run along +X.
	//
	// This is the one piece of geometry in the file that could not be
	// cross-checked against an existing working case the way the
	// billboard basis could (RS_BBCompose.RightOf already had that one
	// proved, and this file's billboard maths reproduces its answer). If
	// landed numbers read BACKWARDS, flip this to -1.0 and nothing else.
	const RS_DN_FLATROW_SIGN = 1.0;

	// -----------------------------------------------------------------
	// State
	// -----------------------------------------------------------------
	// NOT private: Emit is a static of this class and writes these on a
	// freshly spawned instance. ZScript's `private` is class-scoped and
	// should permit that, but this costs nothing to avoid finding out.
	RS_DamageNumberHandler dnHandler;
	RS_DNSettings          dnCV;

	private Array<RS_DNDigit> dnDigits;
	private Array<RS_DNHalo>  dnHalos;

	private int    dnAge, dnLife;
	private int    dnPath;
	private bool   dnLanded, dnBounced;
	private int    dnLandAge;

	private Vector3 dnVel;
	private double  dnGrav;
	private double  dnSpin, dnSpinVel;
	private double  dnAimRoll;
	private bool    dnAimSeeded;

	private double dnSizeFactor;   // significance -> size, fixed at birth
	private double dnOvershoot;    // birth punch peak
	private double dnSettle;       // resting scale
	private double dnStretchGain;
	private double dnHaloAlpha;
	// Which digit set this number wears. Fixed at birth, never per
	// tic -- changing the picker mid-flight would make one number
	// change typeface halfway through its own life.
	private int dnFont;

	private double dnGlyphW, dnGlyphH;   // measured from the first digit
	private bool   dnMotion;
	private bool   dnDistanceComp;

	private Color  dnColour;

	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+NOINTERACTION
		Radius 1;
		Height 1;
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	// =================================================================
	// THE PUBLIC ENTRY POINT.
	//
	//   pos          where the hit landed, in the world
	//   amount       damage dealt, already final
	//   impulse      velocity of the round that caused it; may be zero
	//   significance damage as a fraction of the victim's health BEFORE
	//                the hit. Values above 1 mean overkill and are used
	//                as such -- do NOT clamp this at the call site or the
	//                overkill readout has nothing to work from.
	//   hitType      one of RS_DNType
	//   quality      0..1 headshot quality; 0 when it was not a headshot
	//   offhand      true if the offhand weapon landed it
	//
	// Everything expensive happens on the instance, not here: this
	// function must stay cheap enough to call from inside a damage
	// callback for every pellet of a shotgun blast.
	// =================================================================
	static void Emit(Vector3 pos, int amount, Vector3 impulse,
	                 double significance, int hitType, double quality,
	                 bool offhand)
	{
		let h = RS_DamageNumberHandler.RS_Get();
		RS_DNSettings cv;

		if (h)
		{
			cv = h.RS_Settings();
		}
		else
		{
			// Handler not registered in MAPINFO. The numbers still work
			// and still honour every cvar; they are simply uncapped, and
			// each spawn pays for its own handle lookups. See the header.
			cv = new("RS_DNSettings");
			cv.RS_Cache();
		}

		if (!cv.RS_B(cv.cvEnable, true))
			return;

		// The floor. `<=` because the cvar's own description is "nothing
		// AT OR BELOW this draws", and 0 therefore means "show all"
		// without needing a special case.
		if (amount <= 0 || amount <= cv.RS_I(cv.cvMinimum, 0))
			return;

		if (h)
			h.RS_MakeRoom(cv.RS_I(cv.cvMax, 96));

		let n = RS_DamageNumber(Actor.Spawn("RS_DamageNumber", pos, NO_REPLACE));
		if (!n)
			return;

		n.dnHandler = h;
		n.dnCV      = cv;
		n.RS_Build(amount, impulse, significance, hitType, quality, offhand);

		if (h)
			h.RS_Register(n);
	}

	// =================================================================
	// BIRTH. Everything random about a number is rolled here, once.
	//
	// THE RULE, from the spec: jitter PRESENTATION freely, never jitter
	// MEANING. Size comes from significance and colour comes from hit
	// type, and neither may be randomised -- the moment they are, the
	// display stops being information and becomes decoration.
	// =================================================================
	void RS_Build(int amount, Vector3 impulse, double significance,
	              int hitType, double quality, bool offhand)
	{
		double sig = max(0.0, significance);
		double q   = clamp(quality, 0.0, 1.0);

		dnMotion       = dnCV.RS_B(dnCV.cvMotion, true);
		dnDistanceComp = dnCV.RS_B(dnCV.cvDistance, false);

		bool wantColour = dnCV.RS_B(dnCV.cvColour, false);
		bool wantSig    = dnCV.RS_B(dnCV.cvSignificance, false);
		bool wantGlow   = dnCV.RS_B(dnCV.cvGlow, false);
		bool wantOver   = dnCV.RS_B(dnCV.cvOverkill, false);
		bool wantHand   = dnCV.RS_B(dnCV.cvPerHand, false);

		// ---- size: SIGNIFICANCE, NOT MAGNITUDE ----------------------
		// 50 damage is the whole of a zombieman and a rounding error on a
		// Cyberdemon. Sizing by the raw figure tells the player how big
		// their gun is, which they already know.
		//
		// Square-rooted so that a 4% chip is still legible rather than a
		// speck; the curve buys the top of the range its impact without
		// making the bottom of it useless.
		dnSizeFactor = 1.0;
		if (wantSig)
			dnSizeFactor = 0.50 + 1.50 * sqrt(clamp(sig, 0.0, 1.0));

		// ---- colour -------------------------------------------------
		int cr = 236, cg = 232, cb = 216;   // bone white, the default

		if (wantColour)
		{
			if (hitType == RS_DN_KILL)
			{
				// The spec wants the monster's own tier or elite colour
				// here. That is not in this function's signature and
				// inventing a lookup would mean this file reaching into
				// the monster side, which it has no business doing. A hot
				// amber stands in: distinct from every other tier, and the
				// killing blow is also carrying extra lifetime and a
				// bigger halo, so it does not rely on hue alone.
				cr = 255; cg = 214; cb = 150;
			}
			else if (hitType == RS_DN_CRITHEAD)
			{
				// Its own tier and deliberately rare.
				cr = 255; cg = 252; cb = 240;
			}
			else if (hitType == RS_DN_CRIT)
			{
				// The exact teal the round wore in flight -- TRNSLATE.txt's
				// rs_crit_teal is 38,208,206. The player sees a teal round
				// leave the barrel and a teal number come off the target:
				// two halves of one event rather than two effects.
				cr = 38; cg = 208; cb = 206;
			}
			else if (hitType == RS_DN_HEAD)
			{
				// Gold, saturating with quality. A graze is pale, a centre
				// hit is bright.
				cr = RS_Mix(240, 255, q);
				cg = RS_Mix(232, 196, q);
				cb = RS_Mix(190,  32, q);
			}
		}

		if (wantHand)
		{
			// Which hand landed it. Subtle on purpose -- this is a bias,
			// not a second colour scheme, and it must not be able to turn
			// a crit's teal into something that reads as a different kind
			// of hit.
			if (offhand) { cr = RS_Scale(cr, 0.92); cb = RS_Scale(cb, 1.08); }
			else         { cr = RS_Scale(cr, 1.06); cb = RS_Scale(cb, 0.92); }
		}

		dnColour = Color(255, cr, cg, cb);

		// ---- lifetime -----------------------------------------------
		int baseLife = max(6, dnCV.RS_I(dnCV.cvLifetime, 35));
		double lifeMul = 1.0 + frandom(-RS_DN_LIFE_JITTER, RS_DN_LIFE_JITTER);
		if (dnMotion)
		{
			// Weight follows significance: a big-fraction hit hangs
			// longer. Same number that set the size, so motion and size
			// can never disagree about how much a shot mattered.
			lifeMul *= 1.0 + 0.35 * clamp(sig, 0.0, 1.0);
			if (hitType == RS_DN_KILL)
				lifeMul *= 1.5;    // the last number lingers
		}
		dnLife = max(8, int(baseLife * lifeMul));

		// ---- presentation jitter ------------------------------------
		dnOvershoot = frandom(1.30, 1.50);
		dnSettle    = frandom(0.92, 1.08);
		dnHaloAlpha = frandom(RS_DN_HALO_A_LO, RS_DN_HALO_A_HI);
		// Read once, here. RS_DNFont.Prefix clamps anything unexpected
		// back to the default set, so a bad cvar value cannot produce
		// an unregistered sprite name and blank digits.
		let fcv = CVar.FindCVar("rs_dn_font");
		dnFont = fcv ? fcv.GetInt() : 0;

		// ---- trajectory ---------------------------------------------
		dnPath = RS_DNP_BALLISTIC;
		if (dnMotion)
		{
			if ((hitType == RS_DN_HEAD || hitType == RS_DN_CRITHEAD) && q >= RS_DN_SNAP_Q)
				dnPath = RS_DNP_SNAP;
			else if (hitType == RS_DN_CRIT || hitType == RS_DN_CRITHEAD)
				dnPath = RS_DNP_KICK;
			else if (sig < RS_DN_CHIP_FRAC)
				dnPath = RS_DNP_FLOAT;
			else if (hitType == RS_DN_KILL || sig >= RS_DN_HEAVY_FRAC)
				dnPath = RS_DNP_BOUNCE;
		}

		RS_SetupLaunch(impulse, sig);

		// ---- glyphs -------------------------------------------------
		int overkill = 0;
		if (wantOver && hitType == RS_DN_KILL && sig > 1.0)
		{
			// significance = amount / healthBefore, so healthBefore falls
			// straight out of it and the waste is what is left. This is
			// the only reason Emit's contract asks for significance
			// UNCLAMPED -- clamp it and there is no overkill to show.
			int hpBefore = int(round(double(amount) / sig));
			overkill = max(0, amount - hpBefore);
		}

		RS_BuildGlyphs(amount, overkill, wantGlow);
	}

	// -----------------------------------------------------------------
	// The launch. Force moves, precision doesn't -- that contrast is the
	// whole grammar and all three numbers it needs already exist.
	// -----------------------------------------------------------------
	private void RS_SetupLaunch(Vector3 impulse, double sig)
	{
		double w = clamp(sig, 0.0, 1.0);

		dnGrav        = RS_DN_GRAV;
		dnStretchGain = 0.35;
		dnVel         = (0.0, 0.0, 0.0);
		dnSpin        = frandom(-6.0, 6.0);
		dnSpinVel     = 0.0;
		Roll          = dnSpin;

		if (!dnMotion)
		{
			// Off: rise straight up like a debug readout. That is what
			// this toggle is for and it should look plain.
			dnVel  = (0.0, 0.0, RS_DN_DRIFT);
			dnGrav = 0.0;
			dnSpin = 0.0;
			Roll   = 0.0;
			dnStretchGain = 0.0;
			return;
		}

		if (dnPath == RS_DNP_SNAP)
		{
			// It does not move at all. No gravity, no spin, no stretch.
			dnGrav        = 0.0;
			dnStretchGain = 0.0;
			dnSpinVel     = 0.0;
			return;
		}

		if (dnPath == RS_DNP_FLOAT)
		{
			// Chip damage drifts and never lands.
			dnVel  = (frandom(-0.25, 0.25), frandom(-0.25, 0.25),
			          frandom(0.55, 0.95));
			dnGrav = 0.0;
			dnStretchGain = 0.12;
			dnSpinVel = frandom(-1.2, 1.2);
			return;
		}

		// The round's own direction. This mod fires REAL PROJECTILES, so
		// a hit has a genuine vector and not just a location -- a shot
		// from below throws the number up and away, a shot from behind
		// pushes it through and out. That is the single biggest
		// difference between "a number appeared" and "something hit
		// that", and it costs nothing because the velocity was already
		// there at impact.
		Vector3 imp = impulse * RS_DN_IMPULSE_GAIN;
		double impLen = imp.Length();
		if (impLen > RS_DN_IMPULSE_MAX)
			imp *= RS_DN_IMPULSE_MAX / impLen;

		double kick = (dnPath == RS_DNP_KICK) ? 1.9 : 1.0;

		// Spread, so a burst fans out instead of stacking in one column.
		// A crit scatters wider because it was thrown harder.
		double spread = (dnPath == RS_DNP_KICK) ? 1.9 : 1.1;

		dnVel = imp * kick;
		dnVel.x += frandom(-spread, spread);
		dnVel.y += frandom(-spread, spread);
		dnVel.z += RS_DN_POP * (1.0 + 0.6 * w) * frandom(0.85, 1.25) * kick;

		// A heavy hit arcs higher and falls slower. Same fraction that
		// set the size, so they cannot disagree.
		dnGrav = RS_DN_GRAV * (1.0 - 0.35 * w);

		double horiz = (dnVel.x, dnVel.y).Length();
		dnSpinVel = frandom(-1.0, 1.0) * (3.5 + horiz * 1.8);

		if (dnPath == RS_DNP_KICK)
			dnStretchGain = 0.60;   // a crit stretches harder
	}

	// -----------------------------------------------------------------
	// Build the row. Offsets are laid out in ADVANCE UNITS and centred,
	// so the whole row re-solves for free when the number changes size.
	// -----------------------------------------------------------------
	private void RS_BuildGlyphs(int amount, int overkill, bool wantGlow)
	{
		int mainCount = RS_DigitCount(amount);
		int overCount = (overkill > 0) ? RS_DigitCount(overkill) : 0;

		// Total width in advance units, so the row can be centred.
		double total = double(mainCount)
		             + ((overCount > 0) ? RS_DN_OVER_GAP + overCount * RS_DN_OVER_SIZE : 0.0);
		double pen = -total * 0.5;

		for (int i = 0; i < mainCount; i++)
		{
			RS_AddGlyph(RS_DigitAt(amount, mainCount, i), pen + 0.5, 1.0, 1.0, wantGlow);
			pen += 1.0;
		}

		if (overCount > 0)
		{
			// Dimmed and smaller, trailing the real figure: you learn how
			// much you are wasting, which is real information for a mod
			// with weapon degradation and an ammo economy.
			//
			// NO PLUS SIGN. The sprite set is ten frames, digits only --
			// the spec's "+88" would need an eleventh frame (K) and the
			// generator was briefed for A-J. The gap and the dimming carry
			// it. If a `+` glyph is ever added, it goes here.
			pen += RS_DN_OVER_GAP;
			for (int i = 0; i < overCount; i++)
			{
				RS_AddGlyph(RS_DigitAt(overkill, overCount, i),
				            pen + RS_DN_OVER_SIZE * 0.5,
				            RS_DN_OVER_SIZE, RS_DN_OVER_A, wantGlow);
				pen += RS_DN_OVER_SIZE;
			}
		}

		// The advance is read off the real art, so tracking stays right
		// whatever resolution the digits were generated at.
		dnGlyphW = 8.0;
		dnGlyphH = 12.0;
		if (dnDigits.Size() > 0)
		{
			dnDigits[0].RS_Measure();
			dnGlyphW = dnDigits[0].dnTexW;
			dnGlyphH = dnDigits[0].dnTexH;
		}

		// Place them before the first frame draws, or the whole row
		// appears stacked at the parent's position for one tic.
		RS_Layout();
	}

	private void RS_AddGlyph(int digit, double offsetEm, double sizeMul,
	                         double alphaMul, bool wantGlow)
	{
		// The halo goes in FIRST so that, when both layers exist, the
		// arrays stay index-parallel with the digits.
		if (wantGlow)
		{
			let hg = RS_DNHalo(Spawn("RS_DNHalo", Pos, NO_REPLACE));
			if (hg)
			{
				hg.RS_SetFont(dnFont, digit, true);
				hg.dnOffsetEm = offsetEm;
				hg.dnSizeMul  = sizeMul;
				hg.dnAlphaMul = alphaMul * dnHaloAlpha;
				hg.SetShade(dnColour);
				dnHalos.Push(hg);
			}
		}

		let g = RS_DNDigit(Spawn("RS_DNDigit", Pos, NO_REPLACE));
		if (!g)
			return;

		g.RS_SetFont(dnFont, digit, false);
		g.dnOffsetEm = offsetEm;
		g.dnSizeMul  = sizeMul;
		g.dnAlphaMul = alphaMul;
		g.SetShade(dnColour);
		dnDigits.Push(g);
	}

	// -----------------------------------------------------------------
	// Digits without a table. RSDN frame A is 0, so the frame index is
	// the digit and there is nothing to look up.
	// -----------------------------------------------------------------
	private static int RS_DigitCount(int v)
	{
		int n = 1;
		int t = abs(v);
		while (t >= 10 && n < RS_DN_MAXDIGITS)
		{
			t /= 10;
			n++;
		}
		return n;
	}

	// i = 0 is the leftmost (most significant) digit.
	private static int RS_DigitAt(int v, int count, int i)
	{
		int t = abs(v);
		for (int k = 0; k < count - 1 - i; k++)
			t /= 10;
		return t % 10;
	}

	private static int RS_Mix(int a, int b, double t)
	{
		return clamp(int(round(a + (b - a) * clamp(t, 0.0, 1.0))), 0, 255);
	}

	private static int RS_Scale(int v, double m)
	{
		return clamp(int(round(v * m)), 0, 255);
	}

	// =================================================================
	// THE FLIGHT.
	// =================================================================
	override void Tick()
	{
		Super.Tick();

		// dnLife is 0 until RS_Build runs, so a number that somehow got
		// spawned without going through Emit removes itself on its first
		// tic instead of dereferencing a null dnCV in the layout.
		dnAge++;
		if (dnAge >= dnLife || !dnCV)
		{
			Destroy();
			return;
		}

		RS_Physics();
		RS_Layout();
	}

	private void RS_Physics()
	{
		if (dnPath == RS_DNP_SNAP)
			return;   // appears, holds dead still, fades

		if (!dnLanded)
		{
			dnVel.z -= dnGrav;
			dnVel.x *= RS_DN_DRAG;
			dnVel.y *= RS_DN_DRAG;

			// The tumble. Spins faster when thrown harder and settles as
			// it slows.
			dnSpin    += dnSpinVel;
			dnSpinVel *= 0.94;

			Vector3 np = Pos + dnVel;
			SetOrigin(np, true);

			// floorz is refreshed by that SetOrigin -- p_maputl.cpp:569
			// runs P_FindFloorCeiling on every call.
			if (dnGrav > 0.0 && dnVel.z <= 0.0 && Pos.z <= floorz + RS_DN_LAND_EPS)
			{
				if (dnPath == RS_DNP_BOUNCE && !dnBounced)
				{
					dnBounced = true;
					SetOrigin((Pos.x, Pos.y, floorz + RS_DN_LAND_EPS), true);
					dnVel.z = -dnVel.z * RS_DN_BOUNCE_E;
					dnVel.x *= 0.60;
					dnVel.y *= 0.60;
					dnSpinVel *= 0.60;
				}
				else
				{
					RS_Land();
				}
			}
		}
	}

	// -----------------------------------------------------------------
	// LANDING. There is no smooth tip-over available: FACESPRITE and
	// FLATSPRITE are two values of one three-bit field
	// (actor.h:474-478), so the moment of landing is a hard switch. The
	// impact squash is timed to cover it.
	//
	// Setting bFlatSprite mid-life is a supported thing an actor may do
	// to itself -- the engine's own ZScript does exactly this at
	// sharedmisc.zs:186.
	// -----------------------------------------------------------------
	private void RS_Land()
	{
		dnLanded  = true;
		dnLandAge = dnAge;

		// Lie along the direction it was travelling, keeping whatever
		// roll it happened to have, so it lands askew rather than neatly
		// aligned.
		double horiz = (dnVel.x, dnVel.y).Length();
		if (horiz > 0.05)
			Angle = atan2(dnVel.y, dnVel.x);

		dnVel     = (0.0, 0.0, 0.0);
		dnSpinVel = 0.0;

		SetOrigin((Pos.x, Pos.y, floorz + RS_DN_LAND_EPS), true);

		for (int i = 0; i < dnDigits.Size(); i++)
			if (dnDigits[i]) dnDigits[i].bFlatSprite = true;
		for (int i = 0; i < dnHalos.Size(); i++)
			if (dnHalos[i]) dnHalos[i].bFlatSprite = true;

		// A landed number persists where a flying one has moved on, so
		// landed numbers would dominate the cap. Age them out faster than
		// the ceiling suggests -- the spec's own note.
		dnLife = min(dnLife, dnAge + RS_DN_LANDED_HOLD);
	}

	// =================================================================
	// LAYOUT -- where every glyph goes, this tic.
	// =================================================================
	private void RS_Layout()
	{
		if (dnDigits.Size() == 0 || !dnCV)
			return;

		// ---- the viewer ---------------------------------------------
		Actor cam = players[consoleplayer].camera;
		if (!cam) cam = players[consoleplayer].mo;

		Vector2 toMe = (1.0, 0.0);
		double dist = 256.0;
		if (cam)
		{
			Vector3 d3 = Pos - cam.Pos;
			dist = max(1.0, d3.Length());
			Vector2 d = (d3.x, d3.y);
			double L = d.Length();
			if (L > 0.001) toMe = d / L;
		}

		// ---- how big, this tic --------------------------------------
		double worldH = RS_DN_TARGET_H * dnSizeFactor
		              * max(0.05, dnCV.RS_F(dnCV.cvScale, 1.0));

		if (dnDistanceComp)
		{
			// Scale up SLIGHTLY with distance -- partial compensation, not
			// constant screen size. Without any of it the numbers that
			// matter most, the long shots, are the ones you cannot read;
			// with full compensation a distant number is the same size as
			// a near one and the depth cue is gone, which in a headset is
			// worse than the problem.
			worldH *= clamp(sqrt(dist / 192.0), 1.0, 2.5);
		}

		// Birth punch: overshoot and settle. Its absence is why most
		// damage numbers feel dead.
		double punch;
		if (dnAge < RS_DN_BORN_TICS)
		{
			double t = double(dnAge) / double(RS_DN_BORN_TICS);
			if (t < 0.45) punch = 0.30 + (dnOvershoot - 0.30) * (t / 0.45);
			else          punch = dnOvershoot + (dnSettle - dnOvershoot) * ((t - 0.45) / 0.55);
		}
		else
		{
			punch = dnSettle;
		}

		// Shrink out, never fade out alone -- something that shrinks reads
		// as leaving, something that only goes transparent reads as a bug.
		// And NEVER grow on death: in a headset a growing sprite reads as
		// coming at your face.
		//
		// `fadeA`, not `alpha`: ZScript is CASE-INSENSITIVE, so a local
		// called alpha is the same name as Actor's own Alpha field. That
		// is the redefinition trap CLAUDE.md records, and it is not worth
		// finding out at load time which way the compiler resolves it.
		double fadeA = 1.0;
		int fade = max(4, dnLife / 4);
		if (dnAge > dnLife - fade)
		{
			fadeA = clamp(double(dnLife - dnAge) / double(fade), 0.0, 1.0);
			punch *= 0.25 + 0.75 * fadeA;
		}

		worldH *= punch;

		// ---- squash and stretch -------------------------------------
		// The number stretches along its direction of travel while it is
		// moving fast and relaxes back to round as it slows. This single
		// technique does more for "alive" than every colour rule in the
		// spec.
		double sp = dnVel.Length();
		double stretch = 1.0 + clamp(sp / RS_DN_STRETCH_REF, 0.0, 1.0) * dnStretchGain;
		double sx = stretch;
		double sy = 1.0 / stretch;

		if (dnLanded)
		{
			int since = dnAge - dnLandAge;
			if (since < RS_DN_SQUASH_TICS)
			{
				double s = 1.0 - double(since) / double(RS_DN_SQUASH_TICS);
				sx *= 1.0 + 0.30 * s;
				sy *= 1.0 - 0.28 * s;
			}
		}

		// ---- the row's basis ----------------------------------------
		//
		// BILLBOARD CASE. A sprite turns to face the viewer, so "sideways"
		// is view-relative and changes as the player walks around -- the
		// exact problem written up at the top of RS_HealthBars.zs. The
		// viewer's right, for a sprite seen along view direction V, is
		// (V.y, -V.x); RS_BBCompose.RightOf proved that against
		// hw_sprites.cpp and this reproduces its answer.
		//
		// The row is then rolled with the glyphs, so the baseline tips
		// with them and the stretch runs ALONG the travel instead of
		// always vertically.
		//
		// THREE AXES, NOT ONE. rowDir is the ROLLED reading direction and
		// is where the digits go. sideAxis and upAxis are the UNROLLED
		// sprite axes, which is what the offset compensation needs:
		// +ROLLCENTER rotates a sprite about its own middle, so the roll
		// does not move that middle, and compensating in a rolled basis
		// would swing the whole number around as it tumbled.
		Vector3 rowDir   = (1.0, 0.0, 0.0);
		Vector3 sideAxis = (1.0, 0.0, 0.0);
		Vector3 upAxis   = (0.0, 0.0, 1.0);
		Vector3 depthDir = (toMe.x, toMe.y, 0.0);
		double  upSign   = 1.0;

		if (dnLanded)
		{
			// FLAT CASE. A flat sprite's local +X maps to world
			// (cos t, -sin t) and its local +Y to (sin t, cos t), with
			// t = 270 - angle (- roll, for the rolled axis). See
			// RS_DN_FLATROW_SIGN for the derivation and for the one
			// constant to flip if landed numbers read backwards.
			double t0 = 270.0 - Angle;
			double t  = t0 - Roll;
			rowDir   = (cos(t)  * RS_DN_FLATROW_SIGN, -sin(t)  * RS_DN_FLATROW_SIGN, 0.0);
			sideAxis = (cos(t0) * RS_DN_FLATROW_SIGN, -sin(t0) * RS_DN_FLATROW_SIGN, 0.0);
			upAxis   = (sin(t0), cos(t0), 0.0);

			// The flat rect runs the sprite's BOTTOM edge to local -topOffset
			// where the billboard rect runs its TOP edge to +topOffset
			// (hw_sprites.cpp:1327-1332 against :1363-1370), so the vertical
			// half of the compensation inverts here and only here.
			upSign = -1.0;

			// A flat halo cannot sit behind a flat digit in depth, so it
			// sits underneath it instead. Both stay above the floor --
			// RS_DN_LAND_EPS is deliberately larger than this offset.
			depthDir = (0.0, 0.0, -1.0);
		}
		else
		{
			RS_UpdateRoll(toMe);
			double r = Roll;
			Vector2 rightXY = (toMe.y, -toMe.x);
			sideAxis = (rightXY.x, rightXY.y, 0.0);
			rowDir = (rightXY.x * cos(r),
			          rightXY.y * cos(r),
			          sin(r) * RS_DN_ROLL_CCW);
		}

		// One advance, in world units, at this tic's size. The stretch
		// widens the glyphs, so it has to widen the spacing too or the
		// row overlaps itself the moment it moves fast.
		double advance = dnGlyphW * (worldH / dnGlyphH) * RS_DN_TRACKING * sx;

		// ---- place ---------------------------------------------------
		//
		// The digit and its halo are different art at different sizes with
		// different offsets, so each is centred on the SAME point using its
		// own measurements rather than one shared fudge.
		for (int i = 0; i < dnDigits.Size(); i++)
		{
			let g = dnDigits[i];
			if (!g) continue;

			double off = g.dnOffsetEm * advance;
			Vector3 p = Pos + rowDir * off;

			g.RS_SizeTo(worldH * g.dnSizeMul, sx, sy);
			g.SetOrigin(p + RS_Centre(g, sideAxis, upAxis, upSign), true);
			g.Angle = Angle;
			g.Roll  = Roll;
			g.Alpha = fadeA * g.dnAlphaMul;

			if (i < dnHalos.Size())
			{
				let hg = dnHalos[i];
				if (!hg) continue;

				hg.RS_SizeTo(worldH * hg.dnSizeMul * RS_DN_HALO_MULT, sx, sy);
				hg.SetOrigin(p + depthDir * RS_DN_HALO_DEPTH
				               + RS_Centre(hg, sideAxis, upAxis, upSign), true);
				hg.Angle = Angle;
				hg.Roll  = Roll;
				hg.Alpha = fadeA * hg.dnAlphaMul;
			}
		}
	}

	// -----------------------------------------------------------------
	// Where to move a glyph's ORIGIN so that its drawn MIDDLE lands on the
	// point we actually computed.
	//
	// Doom's offsets are "how far the origin sits from the left and top
	// edges", so a sprite spans [-leftOffset, w - leftOffset] along its
	// reading direction and its top edge sits at +topOffset above the
	// origin. That second half is the same convention RS_HeadshotUtil
	// already relies on (`spriteTopZ = pos.z + offset.y * sy`), so it is
	// not a fresh assumption.
	//
	// Called AFTER RS_SizeTo, because it reads the scale that call just
	// wrote -- a stretched glyph's centre is further from its corner.
	// -----------------------------------------------------------------
	private Vector3 RS_Centre(RS_DNGlyph g, Vector3 sideAxis, Vector3 upAxis, double upSign)
	{
		double cx = (g.dnTexW * 0.5 - g.dnOffX) * g.Scale.X;
		double cy = (g.dnOffY - g.dnTexH * 0.5) * g.Scale.Y;
		return -(sideAxis * cx) - (upAxis * (cy * upSign));
	}

	// -----------------------------------------------------------------
	// Roll = where it is going, plus a decaying tumble on top.
	//
	// The spec asks for both -- "tilt the number to line up with its
	// velocity so the stretch runs ALONG the travel", and separately a
	// tumble "driven off horizontal speed so it spins faster when thrown
	// harder and settles as it slows". They are not in conflict if the
	// spin is an offset from the aim rather than the whole of the roll:
	// it tips as it arcs and straightens as it settles.
	// -----------------------------------------------------------------
	private void RS_UpdateRoll(Vector2 toMe)
	{
		if (!dnMotion || dnPath == RS_DNP_SNAP)
		{
			Roll = dnSpin;
			return;
		}

		// The velocity as the viewer sees it: along their right, and up.
		Vector2 rightXY = (toMe.y, -toMe.x);
		double vr = dnVel.x * rightXY.x + dnVel.y * rightXY.y;
		double vu = dnVel.z;

		// Below this the screen-space direction is noise and would make
		// the number jitter. Hold the last aim instead.
		if ((vr * vr + vu * vu) > 0.36)
		{
			dnAimRoll   = atan2(vu * RS_DN_ROLL_CCW, vr);
			dnAimSeeded = true;
		}

		Roll = (dnAimSeeded ? dnAimRoll : 0.0) + dnSpin;
	}

	// =================================================================
	// Teardown. Every actor hanging off this number goes with it --
	// an orphaned glyph has nothing left to move, fade or destroy it and
	// would simply sit in the level forever.
	// =================================================================
	override void OnDestroy()
	{
		for (int i = 0; i < dnDigits.Size(); i++)
			if (dnDigits[i]) dnDigits[i].Destroy();
		dnDigits.Clear();

		for (int i = 0; i < dnHalos.Size(); i++)
			if (dnHalos[i]) dnHalos[i].Destroy();
		dnHalos.Clear();

		if (dnHandler)
			dnHandler.RS_Release(self);

		Super.OnDestroy();
	}
}

// =====================================================================
// THE BIG-HIT LIGHT -- the expensive tier, and the only dynamic light
// this feature ever creates.
//
// A number is UI floating in the world, not an object in it, so a shower
// of them lighting up the level would read as a bug rather than as
// atmosphere. The glow that makes them look emissive is the additive
// halo, and that costs nothing.
//
// So this exists ONLY for the rare hit worth marking -- a killing blow,
// or a crit and a headshot landing together. Those are infrequent by
// definition, which is what makes a brief light affordable AND what
// makes it mean something when the room flashes.
//
// TWO THINGS KEEP IT CHEAP, and the second is the one that matters:
//
//   1. It is gated on hit type, so ordinary hits never reach it.
//   2. THE LIVE COUNT IS A COUNTER, NOT A SCAN. RS_HiFiFX.SpawnMuzzleLight
//      solves the same problem by walking a ThinkerIterator on every
//      spawn to count what is already out there. That is correct at a
//      few muzzle flashes a second and wrong here -- damage numbers
//      spawn far more often, and the scan would cost more than the
//      lights it is protecting. A field incremented on spawn and
//      decremented in OnDestroy answers the same question in constant
//      time.
// =====================================================================
class RS_DNLight : PointLight
{
	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+DONTSPLASH
		+THRUACTORS
		+NOTELEPORT
		Args 255, 200, 120, 64;
	}

	// Returns null when at the ceiling -- the caller simply gets no
	// light, which is the correct degradation. A missed light on one hit
	// in a firefight is invisible; a framerate drop is not.
	static RS_DNLight RS_Make(Vector3 pos, Color c, int radius)
	{
		let cv = CVar.FindCVar("rs_dn_dynlight");
		if (!cv || !cv.GetInt())
			return null;

		// The live count lives on RS_DamageNumberHandler -- ZScript does
		// not permit a static member variable on a class, so there is no
		// per-class counter to keep. See rsLightCount there.
		let h = RS_DamageNumberHandler.RS_Get();
		if (!h)
			return null;   // unregistered handler means no ceiling, so no light

		let capcv = CVar.FindCVar("rs_dn_dynlightmax");
		int cap = capcv ? capcv.GetInt() : 8;
		if (cap <= 0 || h.rsLightCount >= cap)
			return null;

		let l = RS_DNLight(Actor.Spawn("RS_DNLight", pos, NO_REPLACE));
		if (!l)
			return null;

		l.args[0] = c.r;
		l.args[1] = c.g;
		l.args[2] = c.b;
		l.args[3] = radius;
		return l;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		let h = RS_DamageNumberHandler.RS_Get();
		if (h) h.rsLightCount++;
	}

	override void OnDestroy()
	{
		// Decremented HERE and not on a timer, so the count can never
		// drift away from reality -- every path that removes this actor,
		// including a level change, comes through OnDestroy.
		let h = RS_DamageNumberHandler.RS_Get();
		if (h) h.rsLightCount--;
		Super.OnDestroy();
	}

	States
	{
	Spawn:
		TNT1 A 2 Bright;
		TNT1 A 2 Bright;
		TNT1 A 2 Bright;
		Stop;
	}
}
