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

	// -----------------------------------------------------------------
	// THE RARITY TOKEN DROP.
	//
	// This is what an elite was always supposed to pay. Tier progression
	// has no other source: every other write to a weapon's Tier is the
	// initial roll or Promote() taking a Prototype back down to Basic.
	// Until 2026-08-11 it was riding on a side effect of lifting a
	// curse, which meant a weapon that never rolled a curse could never
	// climb at all. That block is gone; this replaces it.
	//
	// WHICH WEAPON. A token names one -- an "SMG Uncommon" is for the
	// SMG and nothing else. Drawn from the weapons the player is
	// actually holding, because a token for a gun you do not own is a
	// drop that reads as a reward and is not one. Mainhand and offhand
	// are separate weapon classes, so naming the class names the hand;
	// nothing is rolled for that and nothing has to be asked.
	//
	// WHICH TIER. One rung above what that weapon currently sits at,
	// with the elite's own size buying more. FoodTierFor already grades
	// the corpse and is reused rather than a second ladder invented --
	// a 2000-HP elite is worth +2 rungs, everything smaller is +1.
	//
	// A weapon already at Prototype cannot climb, so it is skipped and
	// the other hand is tried. If both are capped, no token drops: the
	// food is still there, and a token nobody can spend is litter.
	// -----------------------------------------------------------------
	static bool TokensEnabled()
	{
		let cv = CVar.FindCVar("rs_elite_tokens");
		return cv ? cv.GetBool() : true;
	}

	void DropRarityToken(Actor victim, PlayerPawn pawn)
	{
		if (!victim || !pawn || !pawn.player) return;
		if (!TokensEnabled()) return;

		// Prefer the hand that is climbing from further back -- the
		// lower-tier weapon gets the offer, so a neglected offhand
		// catches up rather than the leader running away with it.
		let mainW = RS_Weapon(pawn.player.ReadyWeapon);
		let offW  = RS_Weapon(pawn.player.OffhandWeapon);

		RS_Weapon pick = null;
		if (RS_Rarity.CanClimb(mainW) && RS_Rarity.CanClimb(offW))
			pick = (offW.Tier <= mainW.Tier) ? offW : mainW;
		else if (RS_Rarity.CanClimb(mainW)) pick = mainW;
		else if (RS_Rarity.CanClimb(offW))  pick = offW;
		if (!pick) return;              // both at Prototype; food only

		// Size of the elite buys the rung count.
		int rungs = (FoodTierFor(victim.SpawnHealth()) >= 5) ? 2 : 1;
		int tier  = min(int(pick.Tier) + rungs, int(VRT_Prototype));

		let payload = RS_RarityPayload.Roll(pick.GetClass(), tier);
		if (!payload) return;

		let drop = RS_RarityToken(victim.Spawn("RS_RarityToken",
			victim.pos + (0, 0, 12), ALLOW_REPLACE));
		if (!drop) return;
		drop.mPayload = payload;
		drop.vel = (frandom(-1.5, 1.5), frandom(-1.5, 1.5), frandom(3.0, 5.0));
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

		// The kill has to be attributable to a player for a token to know
		// which weapons to consider. A minion's kill still pays food.
		let pawn = PlayerPawn(e.Thing.target);
		if (!pawn) pawn = players[0].mo;
		DropRarityToken(e.Thing, pawn);
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
