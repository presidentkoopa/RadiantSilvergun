// =====================================================================
// RS_FXRegistry -- the FX catalog as DATA, not as if-chains.
// ---------------------------------------------------------------------
// Built 2026-08-08 at the owner's direction: "the work needs to be done
// the hard way, we need a solid foundation."
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
