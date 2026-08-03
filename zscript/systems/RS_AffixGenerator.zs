// =====================================================================
// RS_AffixGenerator -- assembles a bundle of RS_AffixIngredients for a
// given weapon. This is the piece that turns "affixes build themselves"
// from a slogan into an actual algorithm: pick eligible ingredients,
// track a running cost, never let the total go positive.
//
// Deliberately two functions, not one:
//   Generate() -- pure decision-making. No side effects. Returns a list.
//   Apply()    -- actually calls GrantKeyword/GrantLocal for real.
// Splitting them means a bundle can be inspected/printed before it ever
// touches a real weapon.
// =====================================================================

class RS_AffixGenerator
{
	// Greedy, not optimal -- doesn't try to find the BEST possible
	// bundle, just builds one that's provably safe by construction.
	// Zero-or-negative-cost ingredients are always safe to add. A
	// positive-cost ingredient is only added if the running total after
	// adding it is still <= 0 -- i.e. only if enough real downsides have
	// already been picked to afford it. That's what makes "never nets
	// positive" true by the shape of the loop, not by hoping the random
	// picks happen to balance.
	//
	// Returns fewer than targetCount if the weapon doesn't have enough
	// eligible, affordable ingredients -- never pads with something
	// ineligible just to hit a number. An affix bundle with 3 real
	// ingredients is better than one with 6 where 3 shouldn't be there.
	static Array<RS_AffixIngredient> Generate(RS_Weapon wpn, int targetCount)
	{
		Array<RS_AffixIngredient> result;
		Array<RS_AffixIngredient> pool;
		RS_AffixIngredientPool.AllIngredients(pool);

		// Eligible-only candidate list, shuffled once. Fisher-Yates, not
		// "sort by Random()" -- the latter is a common bad pattern that
		// isn't actually a uniform shuffle.
		Array<RS_AffixIngredient> candidates;
		for (int i = 0; i < pool.Size(); i++)
			if (pool[i].IsEligible(wpn))
				candidates.Push(pool[i]);

		for (int i = candidates.Size() - 1; i > 0; i--)
		{
			int j = Random(0, i);
			let tmp = candidates[i];
			candidates[i] = candidates[j];
			candidates[j] = tmp;
		}

		double runningCost = 0.0;
		for (int i = 0; i < candidates.Size() && result.Size() < targetCount; i++)
		{
			let ing = candidates[i];

			// Never grant the same key:value twice in one bundle --
			// GrantKeyword is already idempotent about this, but a
			// bundle listing "cluster" twice would just be a wasted
			// ingredient slot, not a stronger effect.
			bool alreadyPicked = false;
			for (int j = 0; j < result.Size(); j++)
				if (result[j].Key == ing.Key && result[j].Value == ing.Value)
					alreadyPicked = true;
			if (alreadyPicked)
				continue;

			if (runningCost + ing.PowerCost > 0.0)
				continue;   // would push the bundle into free-power territory -- skip, don't take

			result.Push(ing);
			runningCost += ing.PowerCost;
		}

		return result;
	}

	// The side-effecting half. targetProfile is optional -- if given,
	// grants land on that one rotation beat only (RS_AttackProfile.
	// GrantLocal); if null, grants are weapon-wide (RS_Weapon.
	// GrantKeyword), same as every affix built so far tonight.
	static void Apply(RS_Weapon wpn, Array<RS_AffixIngredient> bundle, RS_AttackProfile targetProfile = null)
	{
		for (int i = 0; i < bundle.Size(); i++)
		{
			if (targetProfile)
				targetProfile.GrantLocal(bundle[i].Key, bundle[i].Value);
			else
				wpn.GrantKeyword(bundle[i].Key, bundle[i].Value);
		}
	}

	// Debug/verification helper -- prints what a bundle WOULD do without
	// touching anything. Use this before ever calling Apply() on
	// something you haven't looked at.
	static string Describe(Array<RS_AffixIngredient> bundle)
	{
		if (bundle.Size() == 0)
			return "(empty -- no eligible/affordable ingredients found)";
		string s = "";
		double total = 0.0;
		for (int i = 0; i < bundle.Size(); i++)
		{
			if (i > 0) s = s .. ", ";
			s = s .. bundle[i].Key .. ":" .. bundle[i].Value
				.. " (" .. string.format("%.2f", bundle[i].PowerCost) .. ")";
			total += bundle[i].PowerCost;
		}
		return s .. " -- net " .. string.format("%.2f", total);
	}
}
