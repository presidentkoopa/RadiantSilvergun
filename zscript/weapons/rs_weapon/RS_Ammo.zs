// =====================================================================
// RS_Ammo -- every per-weapon chambered/magazine Ammo class.
// ---------------------------------------------------------------------
// Only weapon types with a real chamber/magazine concept get these:
// Revolver, Pistol, SMG, Rifle, Shotgun, SuperShotgun. Chaingun/Rocket/
// Plasma/BFG have no chamber -- they consume their reserve pool
// (VR_ChaingunAmmo/RocketAmmo/Cell) directly.
//
// VR_Shell is the shared reserve type for Shotgun and SuperShotgun.
// VR_ChaingunAmmo is the Chaingun's reserve type.
//
// Every class here inherits Ammo directly. Do not reintroduce a shared
// base: Ammo::GetParentAmmo() resolves to the class whose direct parent
// is Ammo, so a base layer makes all six identities of a type share one
// chamber pool -- and an abstract base cannot be spawned at all.
//
// MaxAmount carries headroom above the highest Capacity that type's
// RollStats can produce, so a Designer/Prototype roll (or a later
// capacity affix) is not silently clamped mid-reload.
// =====================================================================

class VR_Shell : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}

class VR_ChaingunAmmo : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 200;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 200;
	}
}


// --- Revolver chamber: rolled Capacity peaks at 7 ---

class VR_RevLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 14;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 14;
	}
}

class VR_RevLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 14;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 14;
	}
}

class VR_RevLoaded3 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 14;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 14;
	}
}

class VR_RevLoaded4 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 14;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 14;
	}
}

class VR_RevLoaded5 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 14;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 14;
	}
}

class VR_RevLoaded6 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 14;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 14;
	}
}


// --- Pistol magazine: rolled Capacity peaks at 15 ---

class VR_PistolLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}

class VR_PistolLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}

class VR_PistolLoaded3 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}

class VR_PistolLoaded4 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}

class VR_PistolLoaded5 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}

class VR_PistolLoaded6 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}


// --- SMG magazine: rolled Capacity peaks at 40 ---

class VR_SMGLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 80;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 80;
	}
}

class VR_SMGLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 80;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 80;
	}
}

class VR_SMGLoaded3 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 80;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 80;
	}
}

class VR_SMGLoaded4 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 80;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 80;
	}
}

class VR_SMGLoaded5 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 80;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 80;
	}
}

class VR_SMGLoaded6 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 80;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 80;
	}
}


// --- Rifle magazine: rolled Capacity peaks at 25 ---

class VR_RifleLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}

class VR_RifleLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}

class VR_RifleLoaded3 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}

class VR_RifleLoaded4 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}

class VR_RifleLoaded5 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}

class VR_RifleLoaded6 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}


// --- Shotgun tube: rolled Capacity peaks at 10 ---

class VR_ShotLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}

class VR_ShotLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}

class VR_ShotLoaded3 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}

class VR_ShotLoaded4 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}

class VR_ShotLoaded5 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}

class VR_ShotLoaded6 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}


// --- SuperShotgun break-action: rolled Capacity is always 2 ---

class VR_SSGLoaded : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
	}
}

class VR_SSGLoaded2 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
	}
}

class VR_SSGLoaded3 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
	}
}

class VR_SSGLoaded4 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
	}
}

class VR_SSGLoaded5 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
	}
}

class VR_SSGLoaded6 : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 4;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 4;
	}
}
