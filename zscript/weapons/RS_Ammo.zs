// =====================================================================
// RS_Ammo -- every per-weapon chambered/magazine Ammo class.
// ---------------------------------------------------------------------
// Only weapon types with a real chamber/magazine concept (confirmed
// from the old reference files) get these: Revolver, Pistol, SMG,
// Rifle, Shotgun, SuperShotgun. Chaingun/Rocket/Plasma/BFG have no
// chamber in the old files either -- they consume their reserve pool
// (VR_ChaingunAmmo/RocketAmmo/Cell) directly, no separate class needed.
//
// VR_Shell is the shared reserve type for Shotgun and SuperShotgun
// (real name from the old files, not vanilla). VR_ChaingunAmmo is the
// Chaingun's real reserve type, also not vanilla.
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


class VR_RevLoadedBase : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 6;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 6;
	}
}

class VR_RevLoaded : VR_RevLoadedBase {}
class VR_RevLoaded2 : VR_RevLoadedBase {}
class VR_RevLoaded3 : VR_RevLoadedBase {}
class VR_RevLoaded4 : VR_RevLoadedBase {}
class VR_RevLoaded5 : VR_RevLoadedBase {}
class VR_RevLoaded6 : VR_RevLoadedBase {}


class VR_PistolLoadedBase : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 12;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 12;
	}
}

class VR_PistolLoaded : VR_PistolLoadedBase {}
class VR_PistolLoaded2 : VR_PistolLoadedBase {}
class VR_PistolLoaded3 : VR_PistolLoadedBase {}
class VR_PistolLoaded4 : VR_PistolLoadedBase {}
class VR_PistolLoaded5 : VR_PistolLoadedBase {}
class VR_PistolLoaded6 : VR_PistolLoadedBase {}


class VR_SMGLoadedBase : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}

class VR_SMGLoaded : VR_SMGLoadedBase {}
class VR_SMGLoaded2 : VR_SMGLoadedBase {}
class VR_SMGLoaded3 : VR_SMGLoadedBase {}
class VR_SMGLoaded4 : VR_SMGLoadedBase {}
class VR_SMGLoaded5 : VR_SMGLoadedBase {}
class VR_SMGLoaded6 : VR_SMGLoadedBase {}


class VR_RifleLoadedBase : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}

class VR_RifleLoaded : VR_RifleLoadedBase {}
class VR_RifleLoaded2 : VR_RifleLoadedBase {}
class VR_RifleLoaded3 : VR_RifleLoadedBase {}
class VR_RifleLoaded4 : VR_RifleLoadedBase {}
class VR_RifleLoaded5 : VR_RifleLoadedBase {}
class VR_RifleLoaded6 : VR_RifleLoadedBase {}


class VR_ShotLoadedBase : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 8;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 8;
	}
}

class VR_ShotLoaded : VR_ShotLoadedBase {}
class VR_ShotLoaded2 : VR_ShotLoadedBase {}
class VR_ShotLoaded3 : VR_ShotLoadedBase {}
class VR_ShotLoaded4 : VR_ShotLoadedBase {}
class VR_ShotLoaded5 : VR_ShotLoadedBase {}
class VR_ShotLoaded6 : VR_ShotLoadedBase {}


class VR_SSGLoadedBase : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 2;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 2;
	}
}

class VR_SSGLoaded : VR_SSGLoadedBase {}
class VR_SSGLoaded2 : VR_SSGLoadedBase {}
class VR_SSGLoaded3 : VR_SSGLoadedBase {}
class VR_SSGLoaded4 : VR_SSGLoadedBase {}
class VR_SSGLoaded5 : VR_SSGLoadedBase {}
class VR_SSGLoaded6 : VR_SSGLoadedBase {}
