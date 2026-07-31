// =====================================================================
// RS_ClassGating -- one chokepoint, not per-weapon logic.
// ---------------------------------------------------------------------
// Every map-placed weapon pickup gets checked once, at the moment the
// map spawns it, against the player's chosen class family. A mismatch
// is destroyed on the spot, before it's ever collidable. Player.StartItem
// grants and GiveInventory calls (Elite drops, "Allow Big Guns", console
// give) never go through WorldThingSpawned, so this only ever touches
// actual floor pickups -- it can't clobber anything already handed to
// the player directly.
//
// New weapons are covered automatically: as long as a weapon type
// overrides RS_Weapon.GetFamily() (see the 7 Dual_X-owned weapon files),
// nobody has to touch this file again.
// =====================================================================

class RS_ClassGating : EventHandler
{
	override void WorldThingSpawned(WorldEvent e)
	{
		super.WorldThingSpawned(e);

		let wep = RS_Weapon(e.Thing);
		if (!wep || wep.owner || wep.GetFamily() == EVR_Family_None)
			return;

		let pawn = players[consoleplayer].mo;
		if (!pawn)
			return;

		let pc = VR_DualClassBase(pawn);
		EVR_Family allowed = pc ? pc.GetFamily() : EVR_Family_None;

		// EVR_Family_None here means "not a gated class" (Vanilla+, or no
		// class system in play) -- let everything through.
		if (allowed == EVR_Family_None)
			return;

		if (wep.GetFamily() != allowed)
			wep.Destroy();
	}
}
