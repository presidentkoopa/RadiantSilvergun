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
// SCOPE NOTE, CORRECTED 2026-08-07. What stood here was wrong on the one
// fact the whole file rests on, and it cost a day:
//
//   "Elite drops are NOT affected -- RS_WeaponDrop.Create uses
//    Actor.Spawn, which never sets bDropped."
//
// Actor.Spawn absolutely does set it, because Inventory::BeginPlay sets
// bDropped on every inventory item regardless of how it was created
// (engine inventory.zs:175). Elite drops WERE affected. So were kill-
// reward Bits, RS_ClassGating's pedestal fills, and -- fatally -- every
// weapon, magazine, armour and stats-proxy the player is given at spawn.
// See the long note on WorldTick below for the full chain.
//
// The test is now bTossed, which IS the monster-drop discriminator the
// original was reaching for: exactly one line in the entire engine sets
// it, and that line is inside A_DropItem. So this file finally does what
// its own name says -- it suppresses monster drops, and nothing else.
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

	// =================================================================
	// THIS TEST DESTROYED THE PLAYER'S ENTIRE INVENTORY. Fixed 2026-08-07.
	// -----------------------------------------------------------------
	// It used to be `if (!allow && a && a.bDropped) a.Destroy();`, on the
	// belief that bDropped means "a monster dropped this". IT DOES NOT.
	// Verified in the engine at E:\UZDXREMA:
	//
	//   * Inventory::BeginPlay() sets bDropped on EVERY inventory item
	//     (inventory.zs:175) -- its own comment reads "[RH] Items are
	//     dropped by default".
	//   * The ONLY thing that clears it is AActor::LevelSpawned()
	//     (p_mobj.cpp:5043), whose only caller is P_SpawnMapThing
	//     (p_mobj.cpp:6296). So it is cleared for MAP-PLACED things and
	//     for nothing else.
	//
	// Therefore bDropped was true for every item this mod ever handed the
	// player, and the chain ran:
	//
	//   Player.StartItem -> GiveDefaultInventory -> GiveInventoryType
	//     -> Spawn -> bDropped = true -> WorldThingSpawned -> mPending
	//     -> next WorldTick -> Destroy()
	//
	// Weapons, ammo, armour, and GunBonsai's TFLV_PerPlayerStatsProxy --
	// which is itself an Inventory -- all eaten a tic after spawn. Losing
	// ReadyWeapon/OffhandWeapon then makes TickPSprites destroy both
	// weapon layers (player.zs:552-570) with nothing to rebuild them, and
	// GunBonsai's ShouldDrawHUD returns false without a ReadyWeapon
	// (EventHandler.zsc:108). That is the whole "my HUD, my models and my
	// ammo all blink out about a second after I spawn" bug, on every
	// class -- the guns visibly churn because each destroyed weapon makes
	// the engine raise the next one, which is then eaten in its turn.
	//
	// THE TEST IS "A MONSTER TOSSED THIS ONTO THE FLOOR":
	//
	//   bTossed   -- THE ONE THAT MATTERS. Set in exactly one place in
	//                the whole engine: Actor.A_DropItem
	//                (inventory_util.zs:669), which is the code path
	//                every monster DropItem goes through. Nothing else
	//                anywhere sets it -- not Actor.Spawn, not
	//                GiveInventory, not map placement. Grepped across
	//                wadsrc and src to confirm before relying on it.
	//   bDropped  -- not map-placed
	//   !owner    -- nobody is holding it
	//   bSpecial  -- still pickable. Inventory.BecomeItem clears this the
	//                moment an item enters an inventory (inventory.zs),
	//                so it separates a pickup on the ground from gear.
	//
	// THIS IS NOW A REAL MONSTER-ONLY TEST, which is what the file always
	// claimed to be. Owner ruling 2026-08-07: "all drops are controlled
	// by KillRewards (or the food drop from Elites), so normal weapon
	// pickups that the map would give you, we have rules for those."
	//
	// So what survives, correctly:
	//   * elite weapon pedestals (RS_WeaponDrop.Create -> Actor.Spawn)
	//   * RS_ClassGating's pedestal fills
	//   * kill-reward Bits (A_SpawnItemEx, not A_DropItem)
	//   * anything the map placed
	//   * the player's own gear
	// and what dies: a monster's own DropItem list -- the shells, clips,
	// weapons and armour that 17 families of CH monsters would otherwise
	// carpet the floor with.
	// =================================================================
	override void WorldTick()
	{
		if (mPending.Size() == 0) return;

		bool allow = DropsAllowed();
		for (int i = 0; i < mPending.Size(); i++)
		{
			let a = mPending[i];

			// a can be null already: the item may have been picked up or
			// destroyed inside its own first tic.
			let inv = Inventory(a);
			if (!allow && inv && inv.bTossed && inv.bDropped
			    && !inv.owner && inv.bSpecial)
				inv.Destroy();
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
