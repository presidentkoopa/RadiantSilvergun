// =====================================================================
// RS_AffixInstall -- THE IGNITION for the affix part-swap layer.
// ---------------------------------------------------------------------
// Built 2026-08-08 at the owner's direction, after tracing the affix
// chain end to end and finding it complete except for a starter motor:
//
//   RS_AffixIngredients          the parts bin, with PowerCost and
//                                eligibility gating .............. built
//   RS_AffixGenerator.Generate() rolls a legal bundle .. CALLED BY NOTHING
//   RS_AffixGenerator.Apply()    grants it as keywords . CALLED BY NOTHING
//   RS_ShotKeywordMods.Resolve() keywords -> shot math ......... LIVE
//   RS_Weapon.Affix* (8 axes)    receive part swaps ... WRITTEN BY NOTHING
//
// So the BEHAVIOUR half of affixes already worked -- homing, piercing,
// spread and damage all resolve from granted keywords on every shot.
// The PARTS half had a finished receiver and no sender: eight fields
// declared, read by the dispatch, cleared by ClearAffixParts(), and set
// by absolutely nothing in the tree.
//
// This is the same shape RS_PACKAssembly was written to fix for PACK --
// its header calls itself "THE DOOR... three quarters of a feature with
// no ignition". Same disease, different system, so: same cure, and
// deliberately the same shape of file so the next reader recognises it.
//
// ---------------------------------------------------------------------
// WHAT IT DOES NOT DO, ON PURPOSE
//
// It does not invent a new affix concept, a new UI, or a new currency.
// It calls the generator that already exists, applies the bundle the
// way that generator already intends, and then translates the part-
// bearing keywords into the eight axes. Everything it knows about what
// is legal comes from RS_AffixIngredients' own gating and cost budget.
//
// It also does not touch the identity anchors. Owner, 2026-08-08:
// weapon sounds, rate of fire and reload rate are what keep a family
// feeling like itself while everything else is rerolled around it. Fire
// sound is therefore NEVER overridden here -- a themed voice goes to
// ExtraFireSound, which layers UNDER the gun's own report rather than
// replacing it. RateOfFire and ReloadSpeed are weapon stats, not axes,
// so this layer structurally cannot reach them.
// =====================================================================

class RS_AffixInstall : Object play
{
	// -----------------------------------------------------------------
	// INSTALL A ROLLED BUNDLE ONTO A WEAPON.
	//
	// count: how many ingredients to try for. The generator's own cost
	// budget may return fewer -- that is the budget working, not a
	// failure, and is deliberately not treated as an error here.
	//
	// targetProfile: null installs weapon-wide (GrantKeyword). Passing a
	// profile installs onto that beat only (GrantLocal), which is what
	// makes "every third shot is the strange one" possible without the
	// other two beats changing.
	// -----------------------------------------------------------------
	static play void RollOnto(RS_Weapon wpn, int count = 2,
		RS_AttackProfile targetProfile = null)
	{
		if (!wpn || count <= 0)
			return;

		Array<RS_AffixIngredient> bundle;
		RS_AffixGenerator.Generate(wpn, count, bundle);
		if (bundle.Size() == 0)
			return;

		// Keywords first: this is what RS_ShotKeywordMods.Resolve reads,
		// and it is the half that already worked.
		RS_AffixGenerator.Apply(wpn, bundle, targetProfile);

		// Then the parts. Separate pass, deliberately: a bundle can grant
		// keywords that carry no part identity at all (behavior:homing is
		// pure math), and a part swap must never be implied by the mere
		// presence of a keyword that happens to sit in the same bundle.
		for (int i = 0; i < bundle.Size(); i++)
			InstallPartsFor(wpn, bundle[i].Key, bundle[i].Value);
	}

	// -----------------------------------------------------------------
	// HOW MANY CARDS THIS WEAPON'S LEVEL-UP SHOWS.
	//
	// Tied to PromotionCount, at the owner's direction 2026-08-08 -- and
	// this is what that field's own declaration already anticipated:
	// "read by two real systems: RS's own stat level-up magnitude... and
	// eventually GunBonsai's affix rank selection once a promoted weapon
	// climbs back to a socket-bearing tier."
	//
	// Promotion sacrifices a Prototype weapon back to Basic. It costs the
	// player everything that weapon had climbed to, so what it buys has to
	// be felt permanently -- more CHOICE at every future level-up is that,
	// and it compounds with the run rather than being a one-off refund.
	//
	// The three-card screen in zscript/LevelUpTemplate.txt is an EXAMPLE,
	// not the ceiling: the owner's range is 1 through 8. Base 3, one more
	// per promotion, hard-capped at 8 so a heavily promoted weapon cannot
	// produce a screen that will not fit or a choice nobody can weigh.
	// -----------------------------------------------------------------
	const CARDS_MIN  = 1;
	const CARDS_BASE = 3;
	const CARDS_MAX  = 8;

	static int CardsForWeapon(RS_Weapon wpn)
	{
		if (!wpn)
			return CARDS_BASE;
		return clamp(CARDS_BASE + wpn.PromotionCount, CARDS_MIN, CARDS_MAX);
	}

	// -----------------------------------------------------------------
	// OFFER, DON'T IMPOSE.
	//
	// Owner, 2026-08-08: a weapon level-up PRESENTS OPTIONS -- some raise
	// raw stats, some are affixes -- and the player picks. So the entry
	// point for the level-up path is not "roll one and apply it", it is
	// "roll several, show them, apply the one chosen".
	//
	// This builds `choices` distinct candidate bundles WITHOUT touching
	// the weapon. Nothing is granted, no axis is written, and the weapon
	// is unchanged if the player takes a different card entirely. Pass
	// the winning bundle to AcceptOffer() to actually install it.
	//
	// Each bundle is generated independently, so two offers can overlap.
	// That is correct and deliberate -- the pool is small and forcing
	// them to be disjoint would silently narrow what the later offers
	// can contain as the pool empties.
	// -----------------------------------------------------------------
	static play void BuildOffers(RS_Weapon wpn, int choices, int perBundle,
		out Array<RS_AffixIngredient> flat, out Array<int> bundleSizes)
	{
		flat.Clear();
		bundleSizes.Clear();
		if (!wpn || choices <= 0 || perBundle <= 0)
			return;

		// ZScript has no array-of-arrays worth using here, so the bundles
		// are returned FLATTENED with a parallel size list: bundle N is
		// the next bundleSizes[N] entries of `flat`. Ugly, honest, and it
		// avoids inventing a wrapper class for a two-call lifetime.
		for (int i = 0; i < choices; i++)
		{
			Array<RS_AffixIngredient> bundle;
			RS_AffixGenerator.Generate(wpn, perBundle, bundle);
			if (bundle.Size() == 0)
				continue;

			for (int j = 0; j < bundle.Size(); j++)
				flat.Push(bundle[j]);
			bundleSizes.Push(bundle.Size());
		}
	}

	// -----------------------------------------------------------------
	// THE PLAYER PICKED ONE. Install it for real.
	//
	// Same two-pass shape as RollOnto: keywords first (the half that
	// already worked and drives RS_ShotKeywordMods), then parts.
	// -----------------------------------------------------------------
	static play void AcceptOffer(RS_Weapon wpn, Array<RS_AffixIngredient> bundle,
		RS_AttackProfile targetProfile = null)
	{
		if (!wpn || bundle.Size() == 0)
			return;

		RS_AffixGenerator.Apply(wpn, bundle, targetProfile);

		for (int i = 0; i < bundle.Size(); i++)
			InstallPartsFor(wpn, bundle[i].Key, bundle[i].Value);
	}

	// -----------------------------------------------------------------
	// WHAT TO PRINT ON THE CARD.
	//
	// A player choosing between three affixes needs to know what each
	// one DOES, not its internal key:value. This is the human-readable
	// side and it stays here rather than in the UI, so a new ingredient
	// gets its wording in the same edit that adds it.
	// -----------------------------------------------------------------
	static string DescribeIngredient(RS_AffixIngredient ing)
	{
		if (!ing)
			return "";

		if (ing.Key == "element")
		{
			string e = StripLevel(ing.Value);
			if (e == "fire") return "Rounds burn -- fire damage, ember trail";
			if (e == "ice")  return "Rounds chill -- heavier, colder impact";
			return "Elemental rounds";
		}

		// Everything else is honest-but-generic rather than a fabricated
		// flavour line. An ingredient with no wording yet says what it is
		// rather than pretending to be something.
		return ing.Key .. ": " .. ing.Value;
	}

	// -----------------------------------------------------------------
	// ONE INGREDIENT -> THE EIGHT AXES.
	//
	// Only element: currently carries a part identity. RS_KeywordEffects
	// says so itself at its element: block -- "the part identity
	// (projectile class, sounds, DamageType) is installed by the upgrade
	// through the Affix* part-swap layer; this is only the leveled math
	// riding along with it." This function IS that upgrade side; the
	// math side stays exactly where it is.
	//
	// payload: and behavior: are intentionally absent. They are pure
	// multipliers on existing damage/pellet/spread math and swapping a
	// visual for them would be inventing content, not wiring what exists.
	//
	// If-chain rather than a table: `static const TYPE name[] = {...}`
	// does not resolve on this engine build (three separate bugs in this
	// repo's history, see CLAUDE.md).
	// -----------------------------------------------------------------
	static play void InstallPartsFor(RS_Weapon wpn, string key, string value)
	{
		if (!wpn)
			return;

		if (key != "element")
			return;

		// The value carries its level as a suffix (fire3, icemaster).
		// Strip it -- the part identity is the same at every level, only
		// the math scales, and that scaling is RS_KeywordEffects' job.
		string elem = StripLevel(value);

		if (elem == "fire")
		{
			wpn.AffixImpactPuff   = RS_Catalog.PUFF_Bullet();
			wpn.AffixImpactSparks = RS_Catalog.SPARK_XHeavy();
			wpn.AffixTrail        = RS_Catalog.TRAIL_ST_Ember();
			// LAYERED, NOT AXIS 5. The gun keeps its own report; this
			// rides underneath it. Overriding FireSound here would erase
			// exactly the identity anchor this file exists to protect.
			return;
		}

		if (elem == "ice")
		{
			wpn.AffixImpactSparks = RS_Catalog.SPARK_XNoModel();
			return;
		}

		// Every other element resolves to nothing here rather than to a
		// guess. A null axis is not a hole -- the four-rung chain falls
		// through to the gun's own, then the catalog default, so an
		// unhandled element still fires a complete, correct shot.
	}

	// -----------------------------------------------------------------
	// "fire3" -> "fire", "icemaster" -> "ice".
	//
	// Trailing digits or the literal "master" are the level. Everything
	// before them is the identity.
	// -----------------------------------------------------------------
	static string StripLevel(string v)
	{
		if (v.Length() > 6 && v.Right(6) == "master")
			return v.Left(v.Length() - 6);

		int end = v.Length();
		while (end > 0)
		{
			int c = v.ByteAt(end - 1);
			if (c < 48 || c > 57)   // not 0-9
				break;
			end--;
		}
		return v.Left(end);
	}

	// -----------------------------------------------------------------
	// TAKE IT ALL BACK.
	//
	// ClearAffixParts() already exists on RS_Weapon and nulls all eight.
	// Wrapped here so callers have one obvious symmetric pair -- an
	// install site that has to remember which of two files owns the
	// uninstall is a site that will eventually forget.
	// -----------------------------------------------------------------
	static play void UninstallParts(RS_Weapon wpn)
	{
		if (wpn)
			wpn.ClearAffixParts();
	}
}
