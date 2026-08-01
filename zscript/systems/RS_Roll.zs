// =====================================================================
// RS_Roll -- shared tier system, dice utilities, and Condition mechanics
// ---------------------------------------------------------------------
// Everything in this file is universal across every future weapon type,
// and set imported. Weapon-specific stat RANGES (what a Revolver
// rolls for Damage at Uncommon tier, etc.) live in each weapon's own
// masterclass file -- this file only holds what every weapon shares:
// the tier ladder, socket counts per tier, generic dice helpers, and
// the Condition curve (backfire risk, degradation, repair).
// =====================================================================

enum EVR_Tier
{
	VRT_Cursed,
	VRT_Trash,
	VRT_Basic,
	VRT_Common,
	VRT_Uncommon,
	VRT_Advanced,
	VRT_Designer,
	VRT_Prototype
}

// Class-gating families -- one per Dual_X starting class. None is the
// "not gated" value: heavy ordnance (Rocket/Plasma/BFG) is deliberately
// universal (every class gets it via "Allow Big Guns"), Fist and the
// Vanilla+ set aren't part of the class system at all.
enum EVR_Family
{
	EVR_Family_None,
	EVR_Family_Pistol,
	EVR_Family_Revolver,
	EVR_Family_Rifle,
	EVR_Family_SMG,
	EVR_Family_Shotgun,
	EVR_Family_SuperShotgun,
	EVR_Family_Chaingun
}

class RS_Roll : Object
{
	// -------------------------------------------------------------
	// Generic dice. Every weapon's RollStats() calls through these
	// instead of calling Random()/FRandom() directly, so there's one
	// place to swap the underlying RNG later if it's ever needed
	// (e.g. a seeded roll for a specific Unique weapon).
	// -------------------------------------------------------------
	static int RollInt(int lo, int hi)
	{
		return Random(lo, hi);
	}

	static double RollDouble(double lo, double hi)
	{
		return FRandom(lo, hi);
	}

	// -------------------------------------------------------------
	// GunBonai sockets per tier -- universal across weapon types.
	// Cursed/Trash/Basic get none; Common through Prototype scale 1-5.
	// -------------------------------------------------------------
	static int SocketsForTier(EVR_Tier t)
	{
		switch (t)
		{
			case VRT_Cursed:    return 0;
			case VRT_Trash:     return 0;
			case VRT_Basic:     return 0;
			case VRT_Common:    return 1;
			case VRT_Uncommon:  return 2;
			case VRT_Advanced:  return 3;
			case VRT_Designer:  return 4;
			case VRT_Prototype: return 5;
			default:            return 0;
		}
	}

	// -------------------------------------------------------------
	// Condition mechanics.
	// -------------------------------------------------------------

	// Repair: this many Grey Bits raises Condition by 1 point.
	const GREY_BITS_PER_CND_POINT = 10;

	// Degradation: any single hit dealing this much raw damage or more
	// drops Condition by this amount on every currently-equipped
	// weapon (both hands), regardless of which hand was firing.
	const CND_DAMAGE_THRESHOLD = 20;
	const CND_LOSS_PER_HIT = 3;

	// How many Condition points one Grey Bit spend restores.
	static double RepairCondition(double currentCnd, int greyBitsSpent)
	{
		double gained = double(greyBitsSpent) / double(GREY_BITS_PER_CND_POINT);
		return min(100.0, currentCnd + gained);
	}

	// Call this whenever the player takes a hit, for each currently
	// equipped weapon (both hands, independently -- the hit landed on
	// the player, not on a specific gun, so both take it).
	static double DegradeCondition(double currentCnd, int rawDamageTaken)
	{
		if (rawDamageTaken >= CND_DAMAGE_THRESHOLD)
			return max(0.0, currentCnd - CND_LOSS_PER_HIT);
		return currentCnd;
	}

	// Condition-band performance modifiers. Called right before a shot
	// resolves. Bands 80-100 are penalty-free; below that, performance
	// degrades, and below 50 there's a real chance of the weapon
	// "rolling well" instead -- more damage and pellets, but with a
	// backfire risk that climbs the further gone the weapon is. This
	// is deliberately not a reliable buff to farm: the good outcome is
	// itself a roll, not guaranteed.
	static void GetConditionEffects(double cnd, out double dmgMult, out double pelletMult, out double backfireChance)
	{
		dmgMult = 1.0;
		pelletMult = 1.0;
		backfireChance = 0.0;

		if (cnd >= 80.0)
		{
			return; // 80-100: no penalties
		}
		else if (cnd >= 70.0)
		{
			dmgMult = 0.95; // slight penalty
		}
		else if (cnd >= 60.0)
		{
			dmgMult = 0.90; // moderate penalty
		}
		else if (cnd >= 50.0)
		{
			// heavier penalty, first flicker of instability -- no backfire
			// risk yet. Original tuning put a 5% backfire chance here; it
			// made "half-worn" already dangerous, which read as too often,
			// too early. Risk now starts at 20 (see below).
			dmgMult = 0.85;
		}
		else if (cnd >= 40.0)
		{
			// 20% chance of +1-pellet-equivalent (2x pellet mult on a
			// 1-pellet base weapon) at the cost of -30% damage; otherwise
			// just a straight damage penalty. No backfire risk.
			if (RollDouble(0, 1) < 0.20)
			{
				pelletMult = 2.0;
				dmgMult = 0.70;
			}
			else
			{
				dmgMult = 0.80;
			}
		}
		else if (cnd >= 30.0)
		{
			// Still no backfire risk -- same reasoning as the 50-59 band.
			if (RollDouble(0, 1) < 0.30)
			{
				pelletMult = 2.0;
				dmgMult = 0.65;
			}
			else
			{
				dmgMult = 0.75;
			}
		}
		else if (cnd >= 20.0)
		{
			// First real backfire risk. Was 0.40 -- cut to a quarter of
			// that; this band is "worn, not ruined."
			dmgMult = 1.25;
			pelletMult = 1.25;
			backfireChance = 0.10;
		}
		else if (cnd >= 10.0)
		{
			// Was 0.60.
			dmgMult = 1.5;
			pelletMult = 1.5;
			backfireChance = 0.20;
		}
		else // 1-9
		{
			// Was 0.75. Still the worst band by far, but a coin flip
			// rather than a near-certainty on every shot.
			dmgMult = 2.0;
			pelletMult = 2.0;
			backfireChance = 0.35;
		}
	}
}
