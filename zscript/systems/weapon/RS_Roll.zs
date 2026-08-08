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

// Weapon families. Every RS_Weapon declares one, so any weapon from any
// imported set can be a candidate for the loop / progression systems --
// an import is not a second-class citizen that sits outside them.
//
// TWO DISTINCT ROLES, and conflating them deletes weapons:
//
//   1. IDENTITY -- what kind of gun this is. Every family below.
//   2. CLASS GATING -- whether a Dual_X starting class filters it at
//      world spawn. ONLY the original seven do this; see
//      RS_ClassGating's own EVR_Family_None check, which is the place that
//      decides, and the place to revisit when the class system is redone.
//
// The split exists because RS_ClassGating DESTROYS a gated weapon whose
// family doesn't match the player's class. Before this enum grew, the
// GunstarHeroes and MeatGrinder sets all returned EVR_Family_None, and
// None was doing double duty as both "no identity" and "never filtered".
// Giving them real identities without that split would
// have silently removed most of both sets from the game.
//
// Heavy ordnance staying universal is the original design, not an
// accident of this change -- every class gets it via "Allow Big Guns".
enum EVR_Family
{
	EVR_Family_None,

	// --- the original seven: identity AND class gating ---
	EVR_Family_Pistol,
	EVR_Family_Revolver,
	EVR_Family_Rifle,
	EVR_Family_SMG,
	EVR_Family_Shotgun,
	EVR_Family_SuperShotgun,
	EVR_Family_Chaingun,

	// --- identity only, never class-gated (see comment above) ---
	EVR_Family_Melee,
	EVR_Family_Launcher,
	EVR_Family_Energy,
	EVR_Family_BFG,
	EVR_Family_Railgun,
	EVR_Family_Flamethrower
}

class RS_Roll : Object
{
	// -------------------------------------------------------------
	// CONDITION FLOOR AT ROLL TIME. Owner ruling, 2026-08-07.
	//
	// Every weapon in all three sets rolled `Condition = RollDouble(1,
	// 100)`, so a brand-new gun -- including the one you spawn holding --
	// could arrive at single-digit Condition and backfire in your hands
	// on the way out of the starting room. Wear is meant to be something
	// the run does to your weapon, not the state it hands you.
	//
	// A weapon can still DEGRADE below this at any time; this is the
	// floor on the initial roll only (RS_Condition.zs owns degradation,
	// and it clamps at 1, not here).
	//
	// Named rather than inlined at 42 call sites so the next tuning pass
	// is one edit. Scalar const, not a `static const TYPE name[]` array
	// -- the array form is the one that doesn't resolve on this engine
	// build (CLAUDE.md).
	// -------------------------------------------------------------
	const STARTING_CONDITION_MIN = 60;

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
			// NO BACKFIRE IN THIS BAND. Owner ruling 2026-08-07: backfire
			// happens BELOW 20, full stop. 20-29 keeps the gamble's upside
			// -- the weapon is rattling and hitting harder for it -- but a
			// gun at 20+ Condition never blows up in your hands. This band
			// carried a 0.10 chance until that ruling.
			dmgMult = 1.25;
			pelletMult = 1.25;
		}
		else if (cnd >= 10.0)
		{
			// Below 20 -- backfire territory begins here (owner ruling
			// 2026-08-07). Was 0.60 before an earlier pass, 0.20 after.
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
