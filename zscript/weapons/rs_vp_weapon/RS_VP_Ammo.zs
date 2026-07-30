// =====================================================================
// RS_VP_Ammo -- chambered-round Ammo classes for the Vanilla+ set.
// ---------------------------------------------------------------------
// Flat by design: every class inherits Ammo directly, no shared abstract
// parent. A parent whose own direct parent is Ammo becomes what
// GetParentAmmo() resolves to, which is exactly the bug that made the
// main arsenal's chambers pool together and fail to spawn. Same lesson
// applied here from the start.
//
// One class per identity (mainhand + offhand) so each hand tracks its
// own chamber independently, same as the main arsenal.
//
// MaxAmount is deliberately ~2x the weapon's magazine Capacity: the main
// arsenal hit a real bug where RollStats raised Capacity above MaxAmount
// and reloads silently burned reserve ammo into a ceiling forever. The
// headroom means a non-purist roll can raise Capacity without tripping
// that again.
// =====================================================================

// --- Pistol (Beretta), mag 11 ---
class RS_VP_PistolLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 22;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 22;
		+IGNORESKILL
	}
}
class RS_VP_PistolLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 22;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 22;
		+IGNORESKILL
	}
}

// --- Assault Rifle (ARifle), mag 31 ---
class RS_VP_ARifleLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 62;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 62;
		+IGNORESKILL
	}
}
class RS_VP_ARifleLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 62;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 62;
		+IGNORESKILL
	}
}

// --- Shotgun (Riotgun), mag 8 ---
class RS_VP_ShotgunLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 16;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 16;
		+IGNORESKILL
	}
}
class RS_VP_ShotgunLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 16;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 16;
		+IGNORESKILL
	}
}

// --- Super Shotgun (DoubleSG), mag 2 ---
class RS_VP_SuperShotgunLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
		+IGNORESKILL
	}
}
class RS_VP_SuperShotgunLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
		+IGNORESKILL
	}
}

// --- Chaingun (Minigun), mag 150 ---
class RS_VP_ChaingunLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 300;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 300;
		+IGNORESKILL
	}
}
class RS_VP_ChaingunLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 300;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 300;
		+IGNORESKILL
	}
}

// --- Rocket Launcher, mag 5 ---
class RS_VP_RocketLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 10;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 10;
		+IGNORESKILL
	}
}
class RS_VP_RocketLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 10;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 10;
		+IGNORESKILL
	}
}

// --- Plasma Rifle, mag 60 ---
class RS_VP_PlasmaLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 120;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 120;
		+IGNORESKILL
	}
}
class RS_VP_PlasmaLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 120;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 120;
		+IGNORESKILL
	}
}

// --- BFG9000, mag 160 ---
class RS_VP_BFGLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 320;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 320;
		+IGNORESKILL
	}
}
class RS_VP_BFGLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 320;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 320;
		+IGNORESKILL
	}
}
