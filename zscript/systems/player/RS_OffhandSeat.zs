// Seats a main-hand and an off-hand weapon into their engine-tracked
// pointers once per player, at spawn, then stops touching anything.
//
// Every off-hand weapon in this arsenal already declares
// +WEAPON.OFFHANDWEAPON on itself -- that flag alone doesn't seat the
// weapon into player.OffhandWeapon, so without this the off-hand simply
// stays empty even though the weapon is genuinely in the player's
// inventory. This reads that same flag at runtime instead of hardcoding
// any weapon or player-class name, so any future weapon carrying the
// flag it already needs works without touching this file.
class RS_OffhandSeat : EventHandler
{
	bool done[MAXPLAYERS];
	int  tries[MAXPLAYERS];

	const MAX_TRIES = 35; // ~1 second; then give up for good, never loop

	override void WorldTick()
	{
		for (uint i = 0; i < MAXPLAYERS; ++i)
		{
			if (done[i])
				continue;
			if (!playeringame[i] || !players[i].mo)
				continue;

			PlayerPawn pawn = players[i].mo;
			if (!pawn.player)
				continue;

			tries[i]++;
			if (tries[i] > MAX_TRIES)
			{
				done[i] = true;
				continue;
			}

			Weapon mainGun = null, mainFallback = null;
			Weapon offGun = null, offFallback = null;

			for (Inventory item = pawn.Inv; item != null; item = item.Inv)
			{
				let w = Weapon(item);
				if (!w)
					continue;

				if (w.bOffhandWeapon)
				{
					if (w.bMeleeWeapon) { if (!offFallback) offFallback = w; }
					else { if (!offGun) offGun = w; }
				}
				else
				{
					if (w.bMeleeWeapon) { if (!mainFallback) mainFallback = w; }
					else { if (!mainGun) mainGun = w; }
				}
			}

			Weapon mainWep = mainGun ? mainGun : mainFallback;
			Weapon offWep = offGun ? offGun : offFallback;

			// Wait for BOTH hands to have something before seating either --
			// classes here always grant a main and an off-hand item together,
			// so seeing only one this tic means the other just hasn't landed
			// in the inventory chain yet, not that it's never coming.
			if (!mainWep || !offWep)
			{
				if (tries[i] < MAX_TRIES)
					continue;
				// Budget exhausted: seat whatever we actually have rather
				// than leaving the player with nothing in either hand.
			}

			if (offWep)
			{
				offWep.bOffhandWeapon = true;
				offWep.bNoHandSwitch = true;
				pawn.player.OffhandWeapon = offWep;
			}
			if (mainWep)
			{
				mainWep.bOffhandWeapon = false;
				mainWep.bNoHandSwitch = true;
				pawn.player.ReadyWeapon = mainWep;
			}

			if (!mainWep && !offWep)
				continue; // truly nothing granted at all yet, keep waiting

			pawn.player.PendingWeapon = WP_NOCHANGE;
			pawn.BringUpWeapon();

			done[i] = true;
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		for (uint i = 0; i < MAXPLAYERS; ++i)
		{
			done[i] = false;
			tries[i] = 0;
		}
	}
}
