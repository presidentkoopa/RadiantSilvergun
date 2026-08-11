// =====================================================================
// ELITE FOOD.
//
// A revealed elite bursts a shower of food when it dies. That is the
// whole of it.
//
// WHAT THIS FILE USED TO BE, 2026-08-11: 2,520 lines carrying a pedestal
// actor, a light beacon, a marker glyph, a halo, a world-space card with
// two layouts, an approach ramp, a hit-region map, six take routes and
// an imprint economy. Owner's call: all of it removed. Elites drop food;
// every monster drops kill rewards through RS_Bits; nothing else.
//
// The card system it belonged to is gone from the tree along with the
// imprint system. If any of it is wanted back it is in git history, at
// 70041685 and its parents.
//
// THE ELITE CONTRACT IS UNCHANGED. An elite that dies WITHOUT having
// revealed itself pays nothing at all -- reveal is what makes it an
// elite rather than a monster with extra health, and the payout follows
// the reveal, not the kill.
// =====================================================================

class RS_EliteFoodHandler : EventHandler
{
	static bool FoodEnabled()
	{
		let cv = CVar.FindCVar("rs_elite_food");
		return cv ? cv.GetBool() : true;
	}

	// Kept from the old drop system: bigger monsters were always worth a
	// bigger pile, in steps rather than continuously.
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
		if (!FoodEnabled()) return;

		int startHealth = victim.SpawnHealth();

		// 5% of starting health, floored at 4 and capped at 25 so a
		// Cyberdemon does not carpet the map.
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
		if (!e.Thing || !e.Thing.bIsMonster) return;

		// REVEALED, NOT MERELY ELITE. An elite carried from above its
		// half-health line to dead in one hit never revealed and pays
		// nothing -- the same contract the drop system used.
		let tok = RS_EliteToken(e.Thing.FindInventory("RS_EliteToken"));
		if (!tok || !tok.revealed) return;

		ScatterFood(e.Thing);
	}
}

// The food itself. HealthBonus so it stacks past 100 the way the vanilla
// bonus does; the sprite picks one of eight fruits at spawn and holds it,
// so a pile reads as a spread rather than eight copies of one thing.
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
