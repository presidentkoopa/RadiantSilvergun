// =====================================================================
// RS_FXRegistry -- THE RUNTIME QUERY INDEX.
// ---------------------------------------------------------------------
// Built 2026-08-08 at the owner's direction: "the work needs to be done
// the hard way, we need a solid foundation."
//
// WHERE THIS SITS, because three files in this folder have catalog-ish
// names and only one of them is this:
//
//   RS_Catalog       author-time named constants (PROJ_Ballistic,
//                    SCALE_Pellet). A weapon calls them BY NAME at
//                    compile time. Nothing queries it.
//   RS_PACKCatalog   the 409 monster attacks, damage and speed intact.
//                    Zero actor overlap with either other file.
//   RS_FXRegistry    THIS. Every FX tagged by axis, role and theme, so
//                    a caller can ask for a KIND of thing -- "a
//                    headline fire trail" -- instead of naming one.
//
// This file is a SIBLING of RS_PACKCatalog, not a child. That file's
// header used to claim it was the single door to all PACK ingredients;
// the claim was deleted 2026-08-11 because it was false and because it
// read as permission to stop looking, which is how a 105-card set got
// built against this index while those 409 attacks went unreached.
//
// ---------------------------------------------------------------------
// WHY THE IF-CHAINS COULD NEVER WORK
//
// Every part-picking function in this project so far answers exactly one
// question with exactly one answer:
//
//     if (archetype == "shotgun") pool.Push(PUFF_Shot());   RS_FamilyPalette
//     static Class<Actor> PuffFor(int theme) { ... }        first attempt here
//
// The real data is MANY-TO-MANY and the original catalog spec said so.
// docs/rs_MASTER_FX_CATALOG.txt's own format section defines the column
// as "USE -- which PACK ingredient slot(s) it can fill". Slot(S). One FX
// legitimately fills several axes, and which axis it lands in changes
// what it MEANS:
//
//   * smoke      -> muzzle smoke, or an impact plume
//   * sparks     -> impact sparks, or a trail
//   * a caco ball-> the projectile that leaves the barrel, OR twenty of
//                   them spawning at the point of impact. One out the
//                   front is a round; twenty on contact is a payload.
//
// An if-chain cannot express that. A list of entries, each declaring the
// themes it belongs to and the axes it can serve, can -- and the roller
// then ASKS ("anything that fills axis 6, themed fire") instead of being
// told.
//
// ---------------------------------------------------------------------
// WHAT IS DELIBERATELY NOT HERE
//
// Descriptors. docs/rs_MASTER_FX_CATALOG.txt is the human-readable
// authority for "what does this actually look like", and all six of its
// content sections currently read "(pending inventory pass)" -- the
// descriptive body was never written, because writing it means viewing
// thousands of sprite frames by hand.
//
// This file therefore carries STRUCTURE and the mappings that are
// defensible from a class's own name and its owning monster family
// (RS_DarkFlameTrailVile is the Archvile's flame trail; RS_IceCacoTrail
// is the ice Cacodemon's). Everything else waits for eyes on the art --
// which is what RS_FXGallery exists to make possible.
// =====================================================================

class RS_FXEntry : Object
{
	Class<Actor> Cls;
	string       Id;          // short human label, for the gallery
	int          Themes;      // bitmask of 1 << MTHEME_*
	int          Axes;        // bitmask of 1 << RS_FXAXIS_*

	// STABLE NAME, added 2026-08-11. Id is the gallery caption -- it has
	// spaces and "(default)" suffixes in it and is not addressable. An
	// affix says "muzzlesmoke3" and means one exact entry, so a handle is
	// a separate, typeable thing: lowercase, [a-z0-9_], never reused.
	string       Handle;

	// SIZE AND BEHAVIOUR, added 2026-08-11. Axis says WHERE a thing may go;
	// this says how LOUD it is and whether it bites. Without it a query for
	// smoke hands a pistol muzzle a card-sized plume, which is the exact
	// failure the field exists to stop.
	int          Roles;       // bitmask of 1 << RS_FXROLE_*

	// Trailing defaults so all 37 pre-existing Add() lines compile untouched.
	static RS_FXEntry Make(Class<Actor> cls, string id, int themes, int axes,
		string handle = "", int roles = 0)
	{
		let e = RS_FXEntry(new("RS_FXEntry"));
		e.Cls = cls;
		e.Id = id;
		e.Themes = themes;
		e.Axes = axes;
		e.Handle = handle;
		e.Roles = roles;
		return e;
	}

	bool FitsAxis(int axis) const  { return (Axes & (1 << axis)) != 0; }
	bool FitsTheme(int theme) const { return (Themes & (1 << theme)) != 0; }

	// Roles == 0 fails EVERY role test, deliberately. An untagged entry is
	// UNCLASSIFIED, not "suits anything" -- letting a plume nobody has
	// sized leak into a constrained query is the whole problem.
	bool FitsRole(int role) const  { return (Roles & (1 << role)) != 0; }
}

class RS_FXRegistry : Object
{
	// The eight axes, as bit positions. These mirror the profile fields
	// they feed -- see RS_AttackProfile and RS_Weapon's Affix* block.
	// PAYLOAD is not one of the original eight: it is the "twenty of them
	// on impact" case the owner named, which is a real distinct use of an
	// actor and had nowhere to be recorded.
	const RS_FXAXIS_PROJECTILE = 0;
	const RS_FXAXIS_CASING     = 1;
	const RS_FXAXIS_MUZZLE     = 2;
	const RS_FXAXIS_SMOKE      = 3;
	const RS_FXAXIS_SOUND      = 4;
	const RS_FXAXIS_PUFF       = 5;
	const RS_FXAXIS_SPARKS     = 6;
	const RS_FXAXIS_TRAIL      = 7;
	const RS_FXAXIS_PAYLOAD    = 8;
	const RS_FXAXIS_COUNT      = 9;

	// ---- ROLE, added 2026-08-11 --------------------------------------
	// Decidable from Default Scale plus any A_SetScale a class applies to
	// itself, so it is objective the same way axis is. A class that ramps
	// across bands sets several bits.
	const RS_FXROLE_ACCENT   = 0;   // draws at <= 0.5 -- a detail
	const RS_FXROLE_BODY     = 1;   // 0.5 < scale <= 1.5 -- the normal case
	const RS_FXROLE_HEADLINE = 2;   // > 1.5 -- an area effect, the event

	// These two are safety rails, not taste. Both are readable from the
	// class's own states, and a query that cannot exclude them will
	// eventually hand the player something that fights back.
	const RS_FXROLE_HOSTILE  = 3;   // damages, or buffs/raises MONSTERS
	const RS_FXROLE_SPAWNER  = 4;   // its states spawn further actors
	const RS_FXROLE_COUNT    = 5;

	static string RoleName(int r)
	{
		if (r == RS_FXROLE_ACCENT)   return "ACCENT";
		if (r == RS_FXROLE_BODY)     return "BODY";
		if (r == RS_FXROLE_HEADLINE) return "HEADLINE";
		if (r == RS_FXROLE_HOSTILE)  return "HOSTILE";
		if (r == RS_FXROLE_SPAWNER)  return "SPAWNER";
		return "?";
	}

	static string AxisName(int a)
	{
		if (a == RS_FXAXIS_PROJECTILE) return "PROJECTILE";
		if (a == RS_FXAXIS_CASING)     return "CASING";
		if (a == RS_FXAXIS_MUZZLE)     return "MUZZLE";
		if (a == RS_FXAXIS_SMOKE)      return "SMOKE";
		if (a == RS_FXAXIS_SOUND)      return "SOUND";
		if (a == RS_FXAXIS_PUFF)       return "PUFF";
		if (a == RS_FXAXIS_SPARKS)     return "SPARKS";
		if (a == RS_FXAXIS_TRAIL)      return "TRAIL";
		if (a == RS_FXAXIS_PAYLOAD)    return "PAYLOAD";
		return "?";
	}

	// -----------------------------------------------------------------
	// THE ENTRIES.
	//
	// Built fresh on request rather than cached in a static: ZScript has
	// no clean static-array init on this engine build, and this is called
	// by the gallery and the roller, neither of which is hot.
	//
	// Themes and axes are deliberately GENEROUS where an FX plausibly
	// serves more than one -- that is the entire point of the structure.
	// An entry that is wrong is fixed by editing one line here, not by
	// hunting through if-chains in four files.
	// -----------------------------------------------------------------
	static void All(out Array<RS_FXEntry> outv)
	{
		outv.Clear();

		int T_FIRE  = 1 << RS_PACKCatalog.MTHEME_FIRE;
		int T_ICE   = 1 << RS_PACKCatalog.MTHEME_ICE;
		int T_PLAS  = 1 << RS_PACKCatalog.MTHEME_PLASMA;
		int T_POIS  = 1 << RS_PACKCatalog.MTHEME_POISON;
		int T_LTNG  = 1 << RS_PACKCatalog.MTHEME_LIGHTNING;
		int T_PSY   = 1 << RS_PACKCatalog.MTHEME_PSYCHIC;
		int T_VOID  = 1 << RS_PACKCatalog.MTHEME_VOID;
		int T_IMP   = 1 << RS_PACKCatalog.MTHEME_IMPACT;

		int A_PUFF  = 1 << RS_FXAXIS_PUFF;
		int A_SPRK  = 1 << RS_FXAXIS_SPARKS;
		int A_TRAIL = 1 << RS_FXAXIS_TRAIL;
		int A_SMOKE = 1 << RS_FXAXIS_SMOKE;
		int A_PAY   = 1 << RS_FXAXIS_PAYLOAD;
		int A_PROJ  = 1 << RS_FXAXIS_PROJECTILE;
		int A_CASING = 1 << RS_FXAXIS_CASING;
		int A_MUZZ   = 1 << RS_FXAXIS_MUZZLE;

		// Role shorthand, same spirit as the axis aliases above.
		int R_ACC = 1 << RS_FXROLE_ACCENT;
		int R_BOD = 1 << RS_FXROLE_BODY;
		int R_HED = 1 << RS_FXROLE_HEADLINE;
		int R_HOS = 1 << RS_FXROLE_HOSTILE;
		int R_SPW = 1 << RS_FXROLE_SPAWNER;

		// --- monster-side puffs -------------------------------------
		// Every one of these was unreachable by any system before now:
		// PuffAt() only ever exposed four generic weapon puffs.
		Add(outv, "RS_DFlamePuffVile",  "vile flame puff",  T_FIRE,          A_PUFF | A_PAY);
		Add(outv, "RS_DFlamePuffVile2", "vile flame puff2", T_FIRE,          A_PUFF | A_PAY);
		Add(outv, "RS_BlueChainPuff2",  "blue chain puff",  T_PLAS | T_LTNG, A_PUFF | A_SPRK);
		Add(outv, "RS_BlueChainPuff3",  "blue chain puff3", T_PLAS | T_LTNG, A_PUFF | A_SPRK);
		Add(outv, "RS_PuffCybieRed",    "cyber red puff",   T_FIRE | T_IMP,  A_PUFF);
		Add(outv, "RS_RedPuff",         "pain red puff",    T_FIRE | T_VOID, A_PUFF | A_PAY);
		Add(outv, "RS_RedPuff2",        "cyber red puff2",  T_FIRE | T_VOID, A_PUFF);
		Add(outv, "RS_PsychPuff",       "psychic puff",     T_PSY,           A_PUFF | A_PAY);
		Add(outv, "RS_HellionPuff",     "hellion puff",     T_POIS | T_FIRE, A_PUFF);
		Add(outv, "RS_SparkPuff1",      "spark puff",       T_IMP | T_LTNG,  A_PUFF | A_SPRK);
		Add(outv, "RS_CyanSGPuff",      "cyan sg puff",     T_PLAS | T_ICE,  A_PUFF);
		Add(outv, "RS_BloodyPuff",      "bloody puff",      T_IMP,           A_PUFF);

		// --- monster-side trails ------------------------------------
		Add(outv, "RS_DarkFlameTrailVile", "vile dark flame", T_FIRE,        A_TRAIL | A_SMOKE);
		Add(outv, "RS_IceCacoTrail",       "ice caco trail",  T_ICE,         A_TRAIL);
		Add(outv, "RS_IceFattTrail",       "ice fatso trail", T_ICE,         A_TRAIL);
		Add(outv, "RS_IceSeekerTrailBaron","ice seeker trail",T_ICE,         A_TRAIL);
		Add(outv, "RS_SoulTrail",          "soul trail",      T_PSY | T_VOID,A_TRAIL);
		Add(outv, "RS_BruiserTrail",       "bruiser trail",   T_VOID,        A_TRAIL);
		Add(outv, "RS_HKEXFastBeamTrail",  "hk beam trail",   T_LTNG | T_PLAS, A_TRAIL);
		Add(outv, "RS_CrackoBallTrail",    "cracko trail",    T_POIS,        A_TRAIL);
		Add(outv, "RS_AgauresBallTrail",   "agaures trail",   T_FIRE,        A_TRAIL);
		Add(outv, "RS_ArchonCometTrail",   "archon comet",    T_FIRE,        A_TRAIL);

		// --- weapon-side, already reachable but now described -------
		// Included so the gallery shows the WHOLE menu side by side --
		// comparing a monster trail against the arsenal default is the
		// entire reason for looking at them together.
		Add(outv, "RS_TracerBit",     "tracer bit (default)", T_IMP,  A_TRAIL);
		Add(outv, "RS_StreakTrail",   "streak trail",         T_IMP,  A_TRAIL);
		Add(outv, "RS_ST_EmberTrail", "ember trail",          T_FIRE, A_TRAIL);
		Add(outv, "RS_StreakPuff",    "streak puff (default)",T_IMP,  A_PUFF);
		Add(outv, "RS_EnhancedShotPuff","shot puff",          T_IMP,  A_PUFF);
		Add(outv, "RS_HitSpark",      "hit spark (default)",  T_IMP,  A_SPRK);
		Add(outv, "RS_SparkX",        "spark X",              T_IMP,  A_SPRK);
		Add(outv, "RS_SparkXHeavy",   "spark X heavy",        T_IMP | T_FIRE, A_SPRK);
		Add(outv, "RS_SparkXNoModel", "spark X small",        T_ICE,  A_SPRK);
		Add(outv, "RS_RicochetSpark", "ricochet spark",       T_IMP,  A_SPRK);
		Add(outv, "RS_SmokeWisp",     "smoke wisp (default)", T_IMP,  A_SMOKE);
		Add(outv, "RS_BallisticType1","ballistic 1 (default)",T_IMP,  A_PROJ);
		Add(outv, "RS_BallisticType2","ballistic 2",          T_IMP,  A_PROJ);
		Add(outv, "RS_BallisticType3","ballistic 3",          T_FIRE, A_PROJ);

		// ---- GENERATED 2026-08-11 from the FX index -------------------
		// 39 entries whose axis and role were decided by a SPAWN SITE --
		// which function spawns them and with what parameters -- rather
		// than by a class name. Handles are stable and typeable; an affix
		// naming one of these means that exact entry.
		//
		// Themes are left empty unless the CODE proved one. Guessing theme
		// from a name is what produced forty 'revolver muzzle flashes' that
		// turned out to be voxels -- see RS_FXGallery's header.
		//
		// Full evidence per entry: docs/rs_fx_catalog.md
		Add(outv, "RS_CasingSmall",  "casing small",   T_IMP, A_CASING, "casing_small",  R_ACC);
		Add(outv, "RS_CasingRifle",  "casing rifle",   T_IMP, A_CASING, "casing_rifle",  R_ACC);
		Add(outv, "RS_CasingShell",  "casing shell",   T_IMP, A_CASING, "casing_shell",  R_BOD);
		Add(outv, "RS_MagDrop",      "magazine drop",  T_IMP, A_CASING, "magdrop",       R_BOD);
		Add(outv, "RS_BlastSmokeHeavy", "blast smoke heavy", 0, A_SMOKE, "smoke_heavy", R_BOD);
		Add(outv, "RS_BlastSmoke",      "blast smoke",       0, A_SMOKE, "smoke_blast", R_BOD);
		Add(outv, "RS_BlastSmokeColumn","blast smoke column",0, A_SMOKE, "smoke_column",R_HED);
		Add(outv, "RS_BrownVileGas",    "brown vile gas",    0, A_SMOKE | A_TRAIL | A_PUFF, "gas_brown", R_ACC | R_BOD);
		Add(outv, "RS_BBaronCmonAndSlam","baron ground slam",0, A_SMOKE | A_TRAIL | A_PUFF, "shockwave_ground", R_BOD | R_HED);
		Add(outv, "RS_BaronOfDirtCH",   "dirt plume",        0, A_SMOKE | A_TRAIL, "dust_plume", R_HED | R_SPW);
		Add(outv, "RS_BVileCloud2",     "vile afterimage",   0, A_SMOKE | A_TRAIL, "afterimage_vile", R_HED);
		Add(outv, "RS_DeepCharge1",     "deep charge",       0, A_SMOKE | A_PUFF | A_SPRK, "charge_collapse", R_ACC | R_BOD | R_HED);
		Add(outv, "RS_FireHand1",       "hand flare",        T_FIRE, A_SMOKE | A_PUFF | A_SPRK, "flare_hand", R_BOD);
		Add(outv, "RS_HadeAra",         "hade bullet puff",  0, A_PUFF | A_PAY, "puff_hade", R_HED | R_HOS | R_SPW);
		Add(outv, "RS_BlueGash2",       "blue gash",         0, A_PUFF | A_SPRK | A_TRAIL, "gash_blue", R_BOD);
		Add(outv, "RS_FrostWingBaron",  "frost mote",        0, A_PUFF | A_SPRK | A_TRAIL, "mote_frost", R_ACC);
		Add(outv, "RS_FrostWingBaron2", "frost mote bloom",  0, A_PUFF | A_TRAIL, "mote_frost_bloom", R_ACC | R_BOD);
		Add(outv, "RS_AbyssBaronHandFire3","hand plume",     0, A_PUFF | A_SPRK | A_SMOKE, "plume_hand", R_BOD | R_SPW);
		Add(outv, "RS_AbyssBaronHandFire2","ice shard burst",T_ICE, A_PUFF | A_SPRK | A_PAY, "burst_ice", R_ACC | R_HOS);
		Add(outv, "RS_IceStartVile1",   "ice bloom",         0,     A_PUFF | A_SMOKE | A_SPRK, "bloom_ice", R_BOD);
		Add(outv, "RS_IceStartVile2",   "ice bloom armed",   T_ICE, A_PUFF | A_PAY, "bloom_ice_armed", R_BOD | R_HOS);
		Add(outv, "RS_IceStartVile3",   "ice bloom armed2",  T_ICE, A_PUFF | A_PAY, "bloom_ice_armed2", R_BOD | R_HOS);
		Add(outv, "RS_IceStartVile4",   "ice shard",         T_ICE, A_PUFF | A_SPRK, "shard_ice", R_ACC);
		Add(outv, "RS_FallenFX",        "fallen spark",      0, A_PUFF | A_SPRK | A_TRAIL, "spark_fallen", R_BOD);
		Add(outv, "RS_PsychicTangleAbyVile2","shard sliver", 0, A_PUFF | A_SPRK, "sliver_shard", R_ACC | R_SPW);
		Add(outv, "RS_BrightUpVile2",   "stencil burst",     0, A_PUFF | A_SPRK | A_PAY, "burst_stencil", R_BOD | R_HOS);
		Add(outv, "RS_BlastEmber",      "blast ember",       0, A_SPRK, "ember_blast",      R_ACC);
		Add(outv, "RS_BlastEmberFast",  "blast ember fast",  0, A_SPRK, "ember_blast_fast", R_ACC);
		Add(outv, "RS_BlastShrapnel",   "blast shrapnel",    0, A_SPRK, "shrapnel_blast",   R_ACC);
		Add(outv, "RS_BlastRedFlare",   "blast red flare",   0, A_SPRK | A_PUFF, "flare_red", R_ACC);
		Add(outv, "RS_BlastFlare",      "blast flare",       0, A_SPRK | A_PUFF, "flare_blast", R_ACC);
		Add(outv, "RS_ExplosionParticleSpawner","particle burst", 0, A_SPRK, "burst_particles", R_BOD | R_SPW);
		Add(outv, "RS_VBtrail4",        "vile bolt trail",   0, A_TRAIL | A_SPRK, "trail_vilebolt", R_ACC);
		Add(outv, "RS_WhiteBaronSliceTrail","slash trail",   0, A_TRAIL, "trail_slash", R_ACC);
		Add(outv, "RS_GroundRedCyb",    "burning ground",    T_FIRE, A_TRAIL | A_SMOKE | A_PAY, "ground_fire", R_ACC | R_HOS);
		Add(outv, "RS_SeekerFlare",     "seeker flare",      0, A_TRAIL | A_SPRK, "flare_seeker", R_ACC);
		Add(outv, "RS_VBtrail2",        "vile trail wide",   0, A_TRAIL | A_SPRK, "trail_vile_wide", R_ACC);
		Add(outv, "RS_FallenSP",        "fallen smoke",      0, A_TRAIL | A_PUFF | A_SMOKE, "smoke_fallen", R_BOD);
		Add(outv, "RS_TentacleBall2",   "tentacle ball 2",   T_PLAS, A_PROJ, "proj_tentacle2", R_BOD);

		// -------------------------------------------------------------
		// THE REST OF weaponfx. Everything above this line was typed by
		// hand, 75 entries, and it covered 27 of the 137 actor classes
		// in zscript/weapons/weaponfx -- which meant ten whole sprite
		// categories (acid, ice, poison, lightning, explosions, fire,
		// plasma, bullets, hitflash, magdrops) were sorted, drawn, and
		// unreachable. Anything asking the registry for them got null.
		//
		// These are the other 102. Axis comes from the file the class
		// lives in (RS_FX_Smoke.zs is smoke, RS_FX_Casings.zs is brass
		// -- the files were already sorted by axis, which is the whole
		// reason this could be filled in at all). Role comes from the
		// declared Scale: <= 0.5 is an ACCENT, up to 1.5 is BODY, above
		// that is a HEADLINE. Anything whose states spawn further actors
		// also carries SPAWNER. Theme is read off the class name.
		//
		// Abstract bases and the state-ladder utilities are deliberately
		// absent -- they are not drawable.
		//
		// A wrong line here is fixed by editing that line. That is the
		// entire argument for the registry existing.
		// -------------------------------------------------------------
		Add(outv, "RS_AffixPartActor",                 "affix part actor",          T_IMP, A_PAY | A_PROJ, "affix_part_actor", R_BOD);
		Add(outv, "RS_AffixFireWisp",                  "affix fire wisp",           T_FIRE, A_PAY | A_PROJ, "affix_fire_wisp", R_ACC);
		Add(outv, "RS_AffixFireEmber",                 "affix fire ember",          T_FIRE, A_PAY | A_PROJ, "affix_fire_ember", R_ACC);
		Add(outv, "RS_AffixGroundFire",                "affix ground fire",         T_FIRE, A_PAY | A_PROJ, "affix_ground_fire", R_BOD);
		Add(outv, "RS_AffixBoneTracer",                "affix bone tracer",         T_VOID, A_PAY | A_PROJ, "affix_bone_tracer", R_ACC);
		Add(outv, "RS_AffixIceShard",                  "affix ice shard",           T_ICE, A_PAY | A_PROJ, "affix_ice_shard", R_BOD);
		Add(outv, "RS_AffixIceOrb",                    "affix ice orb",             T_ICE, A_PAY | A_PROJ, "affix_ice_orb", R_BOD);
		Add(outv, "RS_AffixCacoBall",                  "affix caco ball",           T_IMP, A_PAY | A_PROJ, "affix_caco_ball", R_BOD);
		Add(outv, "RS_AffixIceShardSpray",             "affix ice shard spray",     T_ICE, A_PAY | A_PROJ, "affix_ice_shard_spray", R_BOD);
		Add(outv, "RS_AffixPainOrbMaster",             "affix pain orb master",     T_IMP, A_PAY | A_PROJ, "affix_pain_orb_master", R_HED);
		Add(outv, "RS_AffixArachPlasma",               "affix arach plasma",        T_PLAS, A_PAY | A_PROJ, "affix_arach_plasma", R_BOD);
		Add(outv, "RS_AffixSwarmMote",                 "affix swarm mote",          T_IMP, A_PAY | A_PROJ, "affix_swarm_mote", R_BOD);
		Add(outv, "RS_AffixSwarmCarrier",              "affix swarm carrier",       T_IMP, A_PAY | A_PROJ, "affix_swarm_carrier", R_BOD);
		Add(outv, "RS_AffixNovaBead",                  "affix nova bead",           T_PSY, A_PAY | A_PROJ, "affix_nova_bead", R_HED);
		Add(outv, "RS_AffixNovaShell",                 "affix nova shell",          T_PSY, A_PAY | A_PROJ, "affix_nova_shell", R_HED);
		Add(outv, "RS_BFGTrail",                       "bfgtrail",                  T_PLAS, A_PROJ | A_PAY, "bfgtrail", R_ACC);
		Add(outv, "RS_BFGBallRayFlare",                "bfgball ray flare",         T_PLAS, A_PROJ | A_PAY, "bfgball_ray_flare", R_ACC);
		Add(outv, "RS_BFGBallRay",                     "bfgball ray",               T_PLAS, A_PROJ | A_PAY, "bfgball_ray", R_BOD | R_SPW);
		Add(outv, "RS_BFGBallRayPuff",                 "bfgball ray puff",          T_PLAS, A_PROJ | A_PAY, "bfgball_ray_puff", R_BOD);
		Add(outv, "RS_BFGGreenPlasmaPiece",            "bfggreen plasma piece",     T_PLAS, A_PROJ | A_PAY, "bfggreen_plasma_piece", R_ACC);
		Add(outv, "RS_BFGGreenPlasmaShred",            "bfggreen plasma shred",     T_PLAS, A_PROJ | A_PAY, "bfggreen_plasma_shred", R_BOD | R_SPW);
		Add(outv, "RS_EnhancedBFGExtra",               "enhanced bfgextra",         T_PLAS, A_PROJ | A_PAY, "enhanced_bfgextra", R_ACC | R_SPW);
		Add(outv, "RS_BFGRailPuff",                    "bfgrail puff",              T_PLAS, A_PROJ | A_PAY, "bfgrail_puff", R_ACC | R_SPW);
		Add(outv, "RS_BallisticFired",                 "ballistic fired",           T_FIRE, A_PROJ, "ballistic_fired", R_BOD);
		Add(outv, "RS_BallisticTrail",                 "ballistic trail",           T_IMP, A_PROJ, "ballistic_trail", R_ACC);
		Add(outv, "RS_BlastFlareBase",                 "blast flare base",          T_IMP, A_PAY | A_SPRK, "blast_flare_base", R_HED);
		Add(outv, "RS_BlastFlareSpawner",              "blast flare spawner",       T_IMP, A_PAY | A_SPRK, "blast_flare_spawner", R_HED | R_SPW);
		Add(outv, "RS_BlastFlames",                    "blast flames",              T_FIRE, A_PAY | A_SPRK, "blast_flames", R_HED | R_SPW);
		Add(outv, "RS_BlastFlamesMedium",              "blast flames medium",       T_FIRE, A_PAY | A_SPRK, "blast_flames_medium", R_HED | R_SPW);
		Add(outv, "RS_Blast",                          "blast",                     T_IMP, A_PAY | A_SPRK, "blast", R_HED | R_SPW);
		Add(outv, "RS_BlastKaboom",                    "blast kaboom",              T_IMP, A_PAY | A_SPRK, "blast_kaboom", R_HED | R_SPW);
		Add(outv, "RS_ExplosionFireball",              "explosion fireball",        T_FIRE, A_PAY, "explosion_fireball", R_HED);
		Add(outv, "RS_ExplosionFireballAlt",           "explosion fireball alt",    T_FIRE, A_PAY, "explosion_fireball_alt", R_HED);
		Add(outv, "RS_ExplosionSmall",                 "explosion small",           T_IMP, A_PAY, "explosion_small", R_HED);
		Add(outv, "RS_ExplosionTiny",                  "explosion tiny",            T_IMP, A_PAY, "explosion_tiny", R_HED);
		Add(outv, "RS_ExplosionFlash",                 "explosion flash",           T_IMP, A_PAY, "explosion_flash", R_HED);
		Add(outv, "RS_FireLoop",                       "fire loop",                 T_FIRE, A_PAY | A_TRAIL, "fire_loop", R_ACC);
		Add(outv, "RS_FireLoopAlt",                    "fire loop alt",             T_FIRE, A_PAY | A_TRAIL, "fire_loop_alt", R_BOD);
		Add(outv, "RS_LensFlare",                      "lens flare",                T_IMP, A_MUZZ | A_SPRK, "lens_flare", R_ACC);
		Add(outv, "RS_LensFlareAlt1",                  "lens flare alt1",           T_IMP, A_MUZZ | A_SPRK, "lens_flare_alt1", R_BOD);
		Add(outv, "RS_LensFlareAlt2",                  "lens flare alt2",           T_IMP, A_MUZZ | A_SPRK, "lens_flare_alt2", R_BOD);
		Add(outv, "RS_LensFlareAlt3",                  "lens flare alt3",           T_IMP, A_MUZZ | A_SPRK, "lens_flare_alt3", R_BOD);
		Add(outv, "RS_EnhancedRocket",                 "enhanced rocket",           T_IMP, A_PROJ, "enhanced_rocket", R_BOD | R_SPW);
		Add(outv, "RS_EnhancedPlasmaBall",             "enhanced plasma ball",      T_PLAS, A_PROJ, "enhanced_plasma_ball", R_BOD | R_SPW);
		Add(outv, "RS_EnhancedBFGBall",                "enhanced bfgball",          T_PLAS, A_PROJ, "enhanced_bfgball", R_BOD | R_SPW);
		Add(outv, "RS_MuzzleLight",                    "muzzle light",              T_LTNG, A_MUZZ, "muzzle_light", R_BOD);
		Add(outv, "RS_ExplosionParticle",              "explosion particle",        T_IMP, A_SPRK | A_SMOKE, "explosion_particle", R_HED);
		Add(outv, "RS_ExplosionParticle2",             "explosion particle2",       T_IMP, A_SPRK | A_SMOKE, "explosion_particle2", R_HED);
		Add(outv, "RS_ExplosionParticleHeavy",         "explosion particle heavy",  T_IMP, A_SPRK | A_SMOKE, "explosion_particle_heavy", R_HED);
		Add(outv, "RS_BlueFlarePlasma",                "blue flare plasma",         T_PLAS, A_PROJ | A_PAY, "blue_flare_plasma", R_ACC);
		Add(outv, "RS_BlueFlarePlasmaTrail",           "blue flare plasma trail",   T_PLAS, A_PROJ | A_PAY, "blue_flare_plasma_trail", R_ACC);
		Add(outv, "RS_BluePlasmaPiece",                "blue plasma piece",         T_PLAS, A_PROJ | A_PAY, "blue_plasma_piece", R_ACC);
		Add(outv, "RS_PlasmaRailBall",                 "plasma rail ball",          T_PLAS, A_PROJ | A_PAY, "plasma_rail_ball", R_ACC | R_SPW);
		Add(outv, "RS_BluePlasmaShred",                "blue plasma shred",         T_PLAS, A_PROJ | A_PAY, "blue_plasma_shred", R_ACC | R_SPW);
		Add(outv, "RS_BluePlasmaShredTrail",           "blue plasma shred trail",   T_PLAS, A_PROJ | A_PAY, "blue_plasma_shred_trail", R_BOD);
		Add(outv, "RS_PlasmaRailFlareCounter",         "plasma rail flare counter", T_PLAS, A_PROJ | A_PAY, "plasma_rail_flare_counter", R_BOD);
		Add(outv, "RS_PlasmaRailFlare",                "plasma rail flare",         T_PLAS, A_PROJ | A_PAY, "plasma_rail_flare", R_ACC);
		Add(outv, "RS_PlasmaSplash",                   "plasma splash",             T_PLAS, A_PROJ | A_PAY, "plasma_splash", R_ACC);
		Add(outv, "RS_PlasmaSplashAlt",                "plasma splash alt",         T_PLAS, A_PROJ | A_PAY, "plasma_splash_alt", R_BOD);
		Add(outv, "RS_WallPart",                       "wall part",                 T_IMP, A_PUFF, "wall_part", R_ACC);
		Add(outv, "RS_WallPartMetal",                  "wall part metal",           T_IMP, A_PUFF, "wall_part_metal", R_ACC);
		Add(outv, "RS_WallPartWood",                   "wall part wood",            T_IMP, A_PUFF, "wall_part_wood", R_ACC);
		Add(outv, "RS_WallPartDirt",                   "wall part dirt",            T_IMP, A_PUFF, "wall_part_dirt", R_ACC);
		Add(outv, "RS_WallPartGlass",                  "wall part glass",           T_IMP, A_PUFF, "wall_part_glass", R_ACC);
		Add(outv, "RS_EnhancedBulletPuff",             "enhanced bullet puff",      T_IMP, A_PUFF, "enhanced_bullet_puff", R_ACC | R_SPW);
		Add(outv, "RS_ChainsawPuff",                   "chainsaw puff",             T_IMP, A_PUFF, "chainsaw_puff", R_ACC | R_SPW);
		Add(outv, "RS_RailCoilSeg",                    "rail coil seg",             T_IMP, A_PROJ | A_TRAIL, "rail_coil_seg", R_ACC);
		Add(outv, "RS_RailSeg",                        "rail seg",                  T_IMP, A_PROJ | A_TRAIL, "rail_seg", R_ACC);
		Add(outv, "RS_RailImpactSpark",                "rail impact spark",         T_IMP, A_PROJ | A_TRAIL, "rail_impact_spark", R_ACC);
		Add(outv, "RS_RailBolt",                       "rail bolt",                 T_IMP, A_PROJ | A_TRAIL, "rail_bolt", R_ACC);
		Add(outv, "RS_RailBoltStraight",               "rail bolt straight",        T_IMP, A_PROJ | A_TRAIL, "rail_bolt_straight", R_ACC);
		Add(outv, "RS_RicochetBullet",                 "ricochet bullet",           T_IMP, A_SPRK | A_PUFF, "ricochet_bullet", R_BOD | R_SPW);
		Add(outv, "RS_RicochetShell",                  "ricochet shell",            T_IMP, A_SPRK | A_PUFF, "ricochet_shell", R_BOD | R_SPW);
		Add(outv, "RS_ShotgunParticles",               "shotgun particles",         T_IMP, A_SPRK | A_PUFF, "shotgun_particles", R_ACC);
		Add(outv, "RS_ShotgunParticles2",              "shotgun particles2",        T_IMP, A_SPRK | A_PUFF, "shotgun_particles2", R_ACC);
		Add(outv, "RS_ShotgunParticlesHeavy",          "shotgun particles heavy",   T_IMP, A_SPRK | A_PUFF, "shotgun_particles_heavy", R_ACC);
		Add(outv, "RS_RocketFlare",                    "rocket flare",              T_IMP, A_PROJ | A_PAY, "rocket_flare", R_ACC);
		Add(outv, "RS_HomingRocketFlare",              "homing rocket flare",       T_IMP, A_PROJ | A_PAY, "homing_rocket_flare", R_ACC);
		Add(outv, "RS_GunBarrelSmoke",                 "gun barrel smoke",          T_IMP, A_SMOKE, "gun_barrel_smoke", R_BOD);
		Add(outv, "RS_SmokingPiece",                   "smoking piece",             T_IMP, A_SMOKE, "smoking_piece", R_BOD);
		Add(outv, "RS_ST_FlameJet",                    "st flame jet",              T_FIRE, A_TRAIL, "st_flame_jet", R_ACC);
		Add(outv, "RS_ST_Flame",                       "st flame",                  T_FIRE, A_TRAIL, "st_flame", R_ACC);
		Add(outv, "RS_ST_FireCloud",                   "st fire cloud",             T_FIRE, A_TRAIL, "st_fire_cloud", R_HED);
		Add(outv, "RS_ST_EnergyShot",                  "st energy shot",            T_IMP, A_TRAIL, "st_energy_shot", R_BOD);
		Add(outv, "RS_ST_EnergySpray",                 "st energy spray",           T_IMP, A_TRAIL, "st_energy_spray", R_BOD);
		Add(outv, "RS_ST_ArcImpact",                   "st arc impact",             T_LTNG, A_TRAIL, "st_arc_impact", R_BOD);
		Add(outv, "RS_ST_Grenade",                     "st grenade",                T_IMP, A_TRAIL, "st_grenade", R_BOD);
		Add(outv, "RS_ST_Explosion",                   "st explosion",              T_IMP, A_TRAIL, "st_explosion", R_HED | R_SPW);
		Add(outv, "RS_ST_RingParticle",                "st ring particle",          T_IMP, A_TRAIL, "st_ring_particle", R_HED);
		Add(outv, "RS_ST_BlastSpark",                  "st blast spark",            T_IMP, A_TRAIL, "st_blast_spark", R_HED | R_SPW);
		Add(outv, "RS_ST_BlastSmoke",                  "st blast smoke",            T_IMP, A_TRAIL, "st_blast_smoke", R_HED);
		Add(outv, "RS_ST_Beam",                        "st beam",                   T_IMP, A_TRAIL, "st_beam", R_BOD);
		Add(outv, "RS_ST_ArcTrail",                    "st arc trail",              T_LTNG, A_TRAIL, "st_arc_trail", R_ACC);
		Add(outv, "RS_ST_ScrapShard",                  "st scrap shard",            T_IMP, A_TRAIL, "st_scrap_shard", R_ACC);
		Add(outv, "RS_ST_ScrapShardAlt",               "st scrap shard alt",        T_IMP, A_TRAIL, "st_scrap_shard_alt", R_BOD);
		Add(outv, "RS_ST_Glow",                        "st glow",                   T_IMP, A_TRAIL, "st_glow", R_ACC);
		Add(outv, "RS_ST_BurnToken",                   "st burn token",             T_FIRE, A_TRAIL, "st_burn_token", R_BOD | R_SPW);
		Add(outv, "RS_ST_StickyProjectile",            "st sticky projectile",      T_IMP, A_TRAIL, "st_sticky_projectile", R_BOD);

		// -------------------------------------------------------------
		// THE IMPORTED SETS' OWN PARTS (GH and PS).
		//
		// RS_Catalog named these 26 and this index did not, which meant a
		// card asking for a projectile or a casing could never draw
		// anything belonging to the GH or PS weapon sets -- the two
		// largest imported arsenals in the mod. Found by diffing the two
		// files' actor lists: 51 actors were in both, 26 were in Catalog
		// alone, and every one of those 26 was GH or PS.
		// -------------------------------------------------------------
		Add(outv, "RS_GH_BFGShot",          "gh bfg shot",       T_PLAS, A_PROJ, "gh_bfg_shot", R_HED);
		Add(outv, "RS_GH_FlameJet",         "gh flame jet",      T_FIRE, A_PROJ | A_PAY, "gh_flame_jet", R_BOD | R_HOS);
		Add(outv, "RS_GH_GrenadeLaunched",  "gh grenade",        T_IMP,  A_PROJ | A_PAY, "gh_grenade_launched", R_BOD | R_SPW);
		Add(outv, "RS_GH_GrenadeThrown",    "gh grenade thrown", T_IMP,  A_PROJ | A_PAY, "gh_grenade_thrown", R_BOD | R_SPW);
		Add(outv, "RS_GH_PlasmaShot",       "gh plasma shot",    T_PLAS, A_PROJ, "gh_plasma_shot", R_BOD);
		Add(outv, "RS_GH_UnmakerShot",      "gh unmaker shot",   T_VOID, A_PROJ, "gh_unmaker_shot", R_BOD);
		Add(outv, "RS_PS_BFGShot",          "ps bfg shot",       T_PLAS, A_PROJ, "ps_bfg_shot", R_HED);
		Add(outv, "RS_PS_BFGExtra",         "ps bfg spray",      T_PLAS, A_SPRK | A_PAY, "ps_bfg_spray", R_ACC);
		Add(outv, "RS_PS_PlasmaShot",       "ps plasma shot",    T_PLAS, A_PROJ, "ps_plasma_shot", R_BOD);
		Add(outv, "RS_PS_PlasmaParticle",   "ps plasma mote",    T_PLAS, A_SPRK, "ps_plasma_mote", R_ACC);
		Add(outv, "RS_PS_Rocket",           "ps rocket",         T_IMP,  A_PROJ, "ps_rocket", R_BOD);
		Add(outv, "RS_PS_RocketTrail",      "ps rocket trail",   T_IMP,  A_TRAIL, "ps_rocket_trail", R_ACC);
		Add(outv, "RS_PS_FireTrail",        "ps fire trail",     T_FIRE, A_TRAIL, "ps_fire_trail", R_ACC);
		Add(outv, "RS_PS_Explosion",        "ps explosion",      T_IMP,  A_PAY, "ps_explosion", R_HED);
		Add(outv, "RS_PS_ExplosionFire",    "ps fire explosion", T_FIRE, A_PAY, "ps_explosion_fire", R_HED);
		Add(outv, "RS_PS_ExplosionFireSmall","ps fire burst",    T_FIRE, A_PAY | A_SPRK, "ps_explosion_fire_small", R_BOD);
		Add(outv, "RS_PS_BlastSmoke",       "ps blast smoke",    T_IMP,  A_SMOKE, "ps_blast_smoke", R_BOD);
		Add(outv, "RS_PS_BlastSmokeSmall",  "ps blast smoke sm", T_IMP,  A_SMOKE, "ps_blast_smoke_small", R_ACC);
		Add(outv, "RS_PS_BlastSmokeTiny",   "ps blast smoke tn", T_IMP,  A_SMOKE, "ps_blast_smoke_tiny", R_ACC);
		Add(outv, "RS_PS_SmokePillar",      "ps smoke pillar",   T_IMP,  A_SMOKE, "ps_smoke_pillar", R_HED);
		Add(outv, "RS_PS_Shrapnel",         "ps shrapnel",       T_IMP,  A_SPRK, "ps_shrapnel", R_BOD);
		Add(outv, "RS_PS_ShrapnelSmall",    "ps shrapnel small", T_IMP,  A_SPRK, "ps_shrapnel_small", R_ACC);
		Add(outv, "RS_PS_HitPuff",          "ps hit puff",       T_IMP,  A_PUFF, "ps_hit_puff", R_BOD);
		Add(outv, "RS_PS_SawPuff",          "ps saw puff",       T_IMP,  A_PUFF | A_SPRK, "ps_saw_puff", R_ACC);
		Add(outv, "RS_PS_CasingRifle",      "ps rifle brass",    T_IMP,  A_CASING, "ps_casing_rifle", R_ACC);
		Add(outv, "RS_PS_CasingShell",      "ps shotgun shell",  T_IMP,  A_CASING, "ps_casing_shell", R_ACC);
	}

	// Skips silently if the class does not resolve. A registry that
	// refuses to load because one entry was renamed is worse than one
	// that quietly holds the rest -- and the gallery makes an absence
	// obvious the moment anyone looks.
	private static void Add(out Array<RS_FXEntry> outv, string cls, string id,
		int themes, int axes, string handle = "", int roles = 0)
	{
		Class<Actor> c = cls;
		if (c)
			outv.Push(RS_FXEntry.Make(c, id, themes, axes, handle, roles));
	}

	// -----------------------------------------------------------------
	// BY NAME. What a hand-authored affix uses when it wants one exact
	// thing rather than a roll -- "muzzlesmoke3", not "some smoke".
	//
	// Linear scan on purpose: this runs at affix-install time, not per
	// tic, and a flat scan keeps the table reviewable as one block.
	//
	// A typo returns null and is SILENT, which is the one real hazard --
	// an unresolvable CLASS at least disappears from the gallery where it
	// can be noticed. Handles are checked for duplicates by the gallery's
	// own audit for that reason.
	// -----------------------------------------------------------------
	static RS_FXEntry ByHandle(string h)
	{
		if (!h.Length()) return null;
		Array<RS_FXEntry> all;
		All(all);
		for (int i = 0; i < all.Size(); i++)
			if (all[i].Handle == h) return all[i];
		return null;
	}

	// -----------------------------------------------------------------
	// THE QUERY. This is what replaces the if-chains: ask for what you
	// need and take what comes back.
	//
	// theme < 0 means "any theme" -- used by the gallery to show
	// everything that can fill an axis regardless of element.
	// -----------------------------------------------------------------
	// role is a trailing default so every existing call site is unchanged.
	// -1 means "any size", which is the old behaviour; pass a real role and
	// a pistol muzzle stops being offered a card-sized plume.
	//
	// noHostile/noSpawner are the safety rails. A generator building an
	// attack for the PLAYER wants both on: an entry tagged HOSTILE buffs or
	// raises monsters, and one tagged SPAWNER makes more actors. Neither is
	// a thing you hand someone by accident.
	static void Query(int axis, int theme, out Array<RS_FXEntry> outv,
		int role = -1, bool noHostile = false, bool noSpawner = false)
	{
		outv.Clear();
		Array<RS_FXEntry> all;
		All(all);

		for (int i = 0; i < all.Size(); i++)
		{
			if (!all[i].FitsAxis(axis))
				continue;
			if (theme >= 0 && !all[i].FitsTheme(theme))
				continue;
			if (role >= 0 && !all[i].FitsRole(role))
				continue;
			if (noHostile && all[i].FitsRole(RS_FXROLE_HOSTILE))
				continue;
			if (noSpawner && all[i].FitsRole(RS_FXROLE_SPAWNER))
				continue;
			outv.Push(all[i]);
		}
	}

	// One at random from the eligible set, or null if nothing fits. Null
	// is a legitimate answer and callers must treat it as "leave this
	// axis alone" -- the four-rung fallback in RS_Weapon then lands on
	// the gun's own part or the catalog default, so a shot is still
	// complete.
	static Class<Actor> Draw(int axis, int theme, int role = -1,
		bool noHostile = false, bool noSpawner = false)
	{
		Array<RS_FXEntry> hits;
		Query(axis, theme, hits, role, noHostile, noSpawner);
		if (hits.Size() == 0)
			return null;
		return hits[random(0, hits.Size() - 1)].Cls;
	}
}
