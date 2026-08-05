// =====================================================================
// SYSTEMS_MASTER -- the contract between a monster and the RS systems.
// ---------------------------------------------------------------------
// WHAT THIS REPLACES: RS_MonsterMaster.zs, 1,875 lines that had grown
// into a god-class -- a per-tier stat ladder, per-tier sprite and tint
// tables, per-tier state clusters, a ".T00" state dispatcher, an enrage
// tell, a transform tell, pulses, dodges, satellites, morphs, summon
// caps and an attack-profile engine.
//
// THERE IS NO TIER SYSTEM ANY MORE. Every trace of it is gone from this
// file and from the five systems that used to read it. It was never
// reachable in play anyway: nothing ever assigned a spawn tier, so every
// monster in every map sat at tier 0 forever and the entire ladder was
// unreachable content.
//
// THE MOD DOES NOT SHIP MONSTERS OF ITS OWN. Everything below works on
// PLAIN VANILLA DOOM MONSTERS, which is what the game now spawns. None
// of it requires an actor to inherit anything -- health bars, score
// and kill rewards all read facts any Actor already has.
//
// This class exists ONLY as an optional opt-in for a future monster that
// wants to say "don't drop loot for me". Nothing is required to inherit
// it, and nothing breaks if nothing ever does.
//
// NO `abstract`. Colourful Hell uses that keyword exactly zero times,
// and every time this project has used it the actors rendered INVISIBLE
// while ticking, targeting and firing normally -- it cost the weapons
// once and the monsters once. Do not add it.
//
// NO STATE DISPATCHERS. The old base declared Spawn/See/Missile/... as
// `TNT1 A 0 { return TierState(...); }`. TNT1 is the invisible sprite,
// so any subclass that did not declare its own Spawn inherited one and
// vanished. A monster writes plain `Spawn:` like any ordinary actor.
// =====================================================================

class RS_SystemsMaster : Actor
{
	Default
	{
		Monster;
	}

	// A summoned minion should not drop loot -- otherwise a summoner is
	// an infinite reward pinata. Override to true on anything another
	// monster spawns. Vanilla monsters never override it, which is
	// correct: a vanilla monster is always a real kill.
	virtual bool IsSummonedMinion() { return false; }

	// A body that is only a stage in a death-morph chain. Also no loot:
	// the chain pays out once, at the end.
	virtual bool IsTransientStage() { return false; }

	// --- one-shot health thresholds -----------------------------------
	// "Has this monster passed <fraction> health yet?" Latches, so a
	// phase change fires exactly once however many times it is asked.
	// Sixteen independent slots.
	//
	// Kept because it is genuinely useful and has nothing to do with
	// tiers -- it is a health question, and it works on any Actor that
	// inherits this.
	private int rsThresholds;

	bool ThresholdFired(int slot)
	{
		if (slot < 0 || slot > 15) return false;
		return (rsThresholds & (1 << slot)) != 0;
	}

	// Returns true ONCE, the first time health drops below the fraction.
	bool CheckThreshold(int slot, double fraction)
	{
		if (slot < 0 || slot > 15) return false;
		if (ThresholdFired(slot)) return false;

		int mx = SpawnHealth();
		if (mx <= 0) return false;
		if (double(health) / double(mx) > fraction) return false;

		rsThresholds |= (1 << slot);
		return true;
	}
}
