// =====================================================================
// RS_SummonMark -- "did the map place this, or did something spawn it?"
// ---------------------------------------------------------------------
// Owner ruling 2026-08-07: summons pay nothing. A Pain Elemental spawns
// Lost Souls forever, and every one of them was paying full score AND
// full Kill Reward Bits -- an infinite, effortless farm sitting in the
// middle of the reward economy.
//
// RS_SystemsMaster ALREADY declares the contract that was supposed to
// stop this ("is this a summoned minion or a temporary boss stage?"),
// and RS_Score.zs and RS_Bits.zs both dutifully check it. But not one
// monster in the tree implements it, so the cast always returns null and
// the guard always says "no, pay them". A contract nobody signed.
//
// ---------------------------------------------------------------------
// WHY THIS IS A MARK AT SPAWN AND NOT A CHECK AT KILL TIME
//
// The obvious implementation is "at kill time, is victim.master a
// monster?" -- and it does not work. The engine's own A_PainShootSkull
// (painelemental.zs) calls CopyFriendliness, which copies TARGET and
// friendliness and sets NO master or tracer at all. A vanilla Lost Soul
// has no link to the Elemental that made it. Neither do most CH summons,
// which use A_SpawnItemEx without SXF_SETMASTER.
//
// So the only thing that reliably separates a summon from a map monster
// is WHEN it appeared. Map-placed monsters are spawned during level
// setup, before the first tic runs; anything that becomes a monster
// after that was put there by something in the level.
//
// ---------------------------------------------------------------------
// THIS TOUCHES NO MONSTER FILE. zscript/monsters/** is protected, and
// implementing RS_SystemsMaster properly would mean editing every family
// that summons. Marking from outside costs one inventory item on things
// that were not in the map, and the monster tree never knows.
// =====================================================================

// The mark itself. Presence is the whole payload.
class RS_SummonToken : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
	}
}

class RS_SummonMarker : EventHandler
{
	// Is this a thing that arrived after the map was built?
	static bool IsSummon(Actor a)
	{
		return a && a.FindInventory("RS_SummonToken");
	}

	// Should a kill on this actor pay out at all? The single question
	// both RS_Score and RS_Bits ask.
	static bool PaysRewards(Actor a)
	{
		if (!a) return false;
		let cv = CVar.FindCVar("rs_summons_pay");
		if (cv && cv.GetBool())
			return true;          // farming explicitly re-enabled
		return !IsSummon(a);
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let mo = e.Thing;
		if (!mo || !mo.bIsMonster) return;

		// LEVEL SETUP vs LIVE PLAY. Every map-placed monster is spawned
		// before the first tic, so maptime 0 is the map's own roster and
		// anything later was produced by something inside the level.
		//
		// Deliberately NOT `> 0`: the fresh-thinker pass that delivers
		// this event can still be running on tic 0 for map-placed things.
		if (level.maptime <= 0) return;

		// An archvile RAISING a corpse does not spawn it, so a resurrected
		// map monster never passes through here and keeps paying -- which
		// is right. Reviving is not summoning.
		if (mo.FindInventory("RS_SummonToken")) return;

		mo.GiveInventoryType("RS_SummonToken");
	}
}
