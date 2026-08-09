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

	static RS_FXEntry Make(Class<Actor> cls, string id, int themes, int axes)
	{
		let e = RS_FXEntry(new("RS_FXEntry"));
		e.Cls = cls;
		e.Id = id;
		e.Themes = themes;
		e.Axes = axes;
		return e;
	}

	bool FitsAxis(int axis) const  { return (Axes & (1 << axis)) != 0; }
	bool FitsTheme(int theme) const { return (Themes & (1 << theme)) != 0; }
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
	}

	// Skips silently if the class does not resolve. A registry that
	// refuses to load because one entry was renamed is worse than one
	// that quietly holds the rest -- and the gallery makes an absence
	// obvious the moment anyone looks.
	private static void Add(out Array<RS_FXEntry> outv, string cls, string id,
		int themes, int axes)
	{
		Class<Actor> c = cls;
		if (c)
			outv.Push(RS_FXEntry.Make(c, id, themes, axes));
	}

	// -----------------------------------------------------------------
	// THE QUERY. This is what replaces the if-chains: ask for what you
	// need and take what comes back.
	//
	// theme < 0 means "any theme" -- used by the gallery to show
	// everything that can fill an axis regardless of element.
	// -----------------------------------------------------------------
	static void Query(int axis, int theme, out Array<RS_FXEntry> outv)
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
			outv.Push(all[i]);
		}
	}

	// One at random from the eligible set, or null if nothing fits. Null
	// is a legitimate answer and callers must treat it as "leave this
	// axis alone" -- the four-rung fallback in RS_Weapon then lands on
	// the gun's own part or the catalog default, so a shot is still
	// complete.
	static Class<Actor> Draw(int axis, int theme)
	{
		Array<RS_FXEntry> hits;
		Query(axis, theme, hits);
		if (hits.Size() == 0)
			return null;
		return hits[random(0, hits.Size() - 1)].Cls;
	}
}
