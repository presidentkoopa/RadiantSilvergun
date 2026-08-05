// =====================================================================
// RS_AffixIngredients -- the parts bin for affixes themselves, not
// attacks. RS_Catalog answers "what can a shot be made of." This
// answers "what can an affix be made of."
//
// Every ingredient carries a PowerCost AND, where relevant, an
// eligibility gate (MinPelletCount, MinTier) -- both exist because of
// the 4th standing question (see feedback_affix_workshop_process
// memory), which is narrower than "is the math fair": does this
// ingredient duplicate a design space an EXISTING mechanic (Promotion,
// base stat rolls) already owns as its own reward. Pellet count
// specifically is Promotion's reward axis -- an ingredient may
// REDISTRIBUTE along it (payload:multi/cluster: more pellets,
// proportionally less damage each, net wash, costs 0) but must never
// GROW it for free. Where an effect literally can't avoid that on some
// weapons (payload:slug's pellet math is a no-op on an already-single-
// pellet gun), the fix is an eligibility gate, not a price tag --
// MinPelletCount makes the ingredient simply unavailable there, rather
// than available-but-expensive.
//
// The generator (RS_AffixGenerator, separate file) checks eligibility
// first, then sums a candidate bundle's remaining PowerCost and only
// accepts bundles that net to <= 0. Two separate safety nets, not one --
// gating stops domain-duplication, the cost budget stops plain free
// power (like homing, which doesn't duplicate anything but is still an
// uncompensated bonus on its own).
// =====================================================================

class RS_AffixIngredient : Object
{
	string Category;       // "payload", "behavior", "drawback", ...
	string Key;             // e.g. "payload"
	string Value;            // e.g. "cluster"
	double PowerCost;         // 0 = wash, >0 = real bonus, <0 = real downside
	int MinPelletCount;        // 0 = no requirement. slug needs > 1 to be honest.
	EVR_Tier MinTier;            // VRT_Basic = always eligible
	string RequiredArchetype;   // "" = any archetype. Same check RS_Weapon's
	                             // GetPaletteArchetype() is built for -- this
	                             // is a DIFFERENT axis than RS_FamilyPalette
	                             // (which catalog PIECE fits an archetype);
	                             // this is "is this archetype even allowed
	                             // to have this keyword GRANTED at all."

	// Which attack Modes this ingredient actually DOES something on --
	// bitmask of (1 << RS_ATK_*). 0 = any mode. This gate exists to kill
	// a specific budget exploit: a drawback that's a no-op on some
	// weapon (velocity penalty on a hitscan gun) would otherwise hand
	// the generator free negative-cost credit -- misery on paper,
	// nothing in play, and a positive ingredient paid for with
	// counterfeit money. If the weapon has no beat the effect touches,
	// the ingredient simply isn't offered.
	int RequiredModeMask;

	static RS_AffixIngredient Make(string category, string key, string value,
		double powerCost, int minPellets = 0, EVR_Tier minTier = VRT_Basic,
		string requiredArchetype = "", int modeMask = 0)
	{
		let ing = RS_AffixIngredient(new("RS_AffixIngredient"));
		ing.Category = category;
		ing.Key = key;
		ing.Value = value;
		ing.PowerCost = powerCost;
		ing.MinPelletCount = minPellets;
		ing.MinTier = minTier;
		ing.RequiredArchetype = requiredArchetype;
		ing.RequiredModeMask = modeMask;
		return ing;
	}

	// Every Mode present on either of the weapon's slots, as a mask.
	static play int WeaponModeMask(RS_Weapon wpn)
	{
		int mask = 0;
		for (int s = 0; s < 2; s++)
		{
			let slot = wpn.GetSlot(s);
			if (!slot) continue;
			for (int i = 0; i < slot.Count(); i++)
			{
				let prof = slot.PeekAt(i);
				if (prof) mask |= (1 << prof.Mode);
			}
		}
		return mask;
	}

	play bool IsEligible(RS_Weapon wpn)
	{
		if (wpn.Tier < MinTier)
			return false;
		if (MinPelletCount > 0 && wpn.PelletCount < MinPelletCount)
			return false;
		if (RequiredArchetype != "" && wpn.GetPaletteArchetype() != RequiredArchetype)
			return false;
		if (RequiredModeMask != 0 && (WeaponModeMask(wpn) & RequiredModeMask) == 0)
			return false;
		return true;
	}
}

class RS_AffixIngredientPool
{
	// Real values, matching exactly what RS_KeywordEffects.zs actually
	// does today -- this file describes the SAME math, it doesn't
	// invent new numbers. When that file's math changes, this list has
	// to change with it or the generator will be reasoning about
	// effects that no longer exist.
	static void PayloadIngredients(out Array<RS_AffixIngredient> pool)
	{
		// Exact wash (0.5 * 2 = 1.0) -- costs nothing, because it IS
		// nothing, net. Real choice: coverage vs. focus, not power.
		pool.Push(RS_AffixIngredient.Make("payload", "payload", "multi", 0.0));

		// Exact wash (0.333 * 3 = 1.0), same reasoning.
		pool.Push(RS_AffixIngredient.Make("payload", "payload", "cluster", 0.0));

		// MinPelletCount 2 isn't a fairness nicety, it's the actual fix:
		// on a weapon with only 1 pellet, this keyword's pellet math does
		// nothing at all (1/1 = no change) and it becomes a flat +80%
		// damage buff wearing a pellet keyword as a costume -- exactly
		// the "duplicates Promotion's reward axis for free" violation
		// the 4th standing question is about. It ISN'T eligible there,
		// full stop, not "eligible but priced high."
		//
		// Once actually gated to pellets >= 2, this is a real trade, not
		// a bonus: total damage-per-pull is N pellets * dmg each before,
		// vs 1 pellet * 1.8x dmg after -- at the N=2 gate threshold
		// that's 2 vs 1.8, a real (small) net loss in raw damage, paid
		// for real spread/single-target focus. Priced near 0 (roughly
		// neutral at the gate threshold) rather than positive -- this is
		// a first-pass number, not tuned against actual play.
		pool.Push(RS_AffixIngredient.Make("payload", "payload", "slug", 0.0, minPellets: 2));
	}

	static void BehaviorIngredients(out Array<RS_AffixIngredient> pool)
	{
		// Homing is a real, uncompensated power-up -- nothing makes a
		// seeking round cost anything today. Priced accordingly rather
		// than pretended to be free; a generated bundle that includes
		// this MUST pair it with a real downside elsewhere to net <= 0.
		pool.Push(RS_AffixIngredient.Make("behavior", "behavior", "homing", 0.5));

		// Piercing: same class of uncompensated bonus as homing, and
		// bullet-mode only -- +RIPPER needs a travelling round (hitscan
		// has none; a ripping rocket is a bug generator, fenced at the
		// resolver too). First ingredient to actually use the mode mask.
		pool.Push(RS_AffixIngredient.Make("behavior", "behavior", "piercing", 0.5,
			modeMask: 1 << RS_ATK_BULLET));
	}

	static void DrawbackIngredients(out Array<RS_AffixIngredient> pool)
	{
		// Sluggish: -40% projectile velocity, bullet-only (a no-op on
		// hitscan would mint counterfeit budget credit -- the exact
		// exploit RequiredModeMask exists to kill). Priced near zero
		// DELIBERATELY: at this arsenal's rolled velocities (2500-12500)
		// the cut is numerically real but perceptually almost nil, so it
		// must not fund much. Real price pending a velocity-scale rework.
		pool.Push(RS_AffixIngredient.Make("drawback", "drawback", "sluggish", -0.1,
			modeMask: 1 << RS_ATK_BULLET));

		// Wild: +50% spread. Real, felt cost on both bullet and hitscan
		// paths -- the honest workhorse downside that finally makes
		// homing/piercing purchasable at all.
		pool.Push(RS_AffixIngredient.Make("drawback", "drawback", "wild", -0.5,
			modeMask: (1 << RS_ATK_BULLET) | (1 << RS_ATK_HITSCAN)));
	}

	static void AllIngredients(out Array<RS_AffixIngredient> pool)
	{
		PayloadIngredients(pool);
		BehaviorIngredients(pool);
		DrawbackIngredients(pool);
	}
}
