// ---------------------------------------------------------------------
// RS_NoMonsterDrops -- monsters pay out in kill rewards and nothing else.
//
// Owner's call, this session: "the only drops i need are killrewards".
//
// WHY THIS IS A HANDLER AND NOT 1797 DELETIONS.
//
// The obvious implementation is to strip `DropItem` out of the monster
// Default blocks. Do not. Two reasons, both measured:
//
//  1. `DropItem` IS ALSO THE SPAWN TABLE. 432 of the 2229 DropItem lines
//     under zscript/monsters/ sit on `RandomSpawner` subclasses, where the
//     engine reads them as "which monster to become" -- RS_ImpColourset
//     (RS_Imp.zs:11) is how the coloured imps get into a map at all.
//     Those lines are indistinguishable from loot lines by shape. A bulk
//     pass that catches them deletes the roster, compiles clean, and boots.
//  2. CLAUDE.md's import rule requires CH's drop tables stay restorable --
//     "do not silently ship a gutted table". The data stays on disk; only
//     the payout is suppressed, and one cvar puts it back.
//
// Nothing under /monsters/ is touched by this file.
//
// WHY IT DEFERS A TIC -- THE TRAP THIS FILE EXISTS TO DODGE.
//
// The intuitive version is `WorldThingSpawned` + `if (e.Thing.bDropped)`.
// IT SILENTLY CATCHES NOTHING. The engine's own drop path is ZScript:
// Actor.A_DropItem (wadsrc/static/zscript/actors/inventory_util.zs:633)
// calls Spawn() at :656 and only sets `mo.bDropped = true` at :659 --
// AFTER the spawn, so after WorldThingSpawned has already fired. The flag
// is still false when the event sees it. No error, no warning: the handler
// runs, matches nothing, and the drops keep coming.
//
// So candidates are recorded at spawn and judged on the next WorldTick, by
// which point the flag is set whichever order the engine ticks in.
//
// KILL REWARDS ARE NOT AFFECTED. RS_Bits.zs grants them directly -- no
// Spawn, no A_DropItem, no actor in the world to catch. Verified before
// this file was written, not assumed.
//
// KNOWN SCOPE NOTE, FLAGGED RATHER THAN HIDDEN: `bDropped` marks anything
// dropped, which includes a player's own weapon on death (player.zs:861).
// Elite drops are NOT affected -- RS_WeaponDrop.Create uses Actor.Spawn,
// which never sets bDropped. If player death-drops need to survive, this is
// the line to change, and it needs the owner's call on what should happen.
// ---------------------------------------------------------------------

class RS_NoMonsterDrops : EventHandler
{
	private Array<Actor> mPending;

	// Stated positively -- see the cvar's note in CVARINFO.txt. Missing
	// cvar falls back to "no drops", which is this file's whole point.
	static bool DropsAllowed()
	{
		let cv = CVar.FindCVar("rs_monsterdrops");
		return cv ? cv.GetBool() : false;
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if (!e.Thing) return;
		if (!(e.Thing is "Inventory")) return;

		// Deliberately NOT gated on DropsAllowed() here. The cvar is read
		// when the verdict is passed, one tic later, so flipping it from
		// the menu takes effect on the next drop rather than the next map.
		mPending.Push(e.Thing);
	}

	override void WorldTick()
	{
		if (mPending.Size() == 0) return;

		bool allow = DropsAllowed();
		for (int i = 0; i < mPending.Size(); i++)
		{
			let a = mPending[i];

			// a can be null already: the item may have been picked up or
			// destroyed inside its own first tic.
			if (!allow && a && a.bDropped) a.Destroy();
		}
		mPending.Clear();
	}

	// A pending list must not survive a level change -- the actors in it
	// belong to the level being torn down.
	override void WorldUnloaded(WorldEvent e)
	{
		mPending.Clear();
	}
}
