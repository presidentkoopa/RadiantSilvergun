// =====================================================================
// VR_PlayerClasses -- 8 selectable starting loadouts.
// ---------------------------------------------------------------------
// Vanilla+ is the standard Doom start. Every Dual_X class grants Fist +
// two Basic-tier weapons of that type (one mainhand, one offhand),
// plus all three heavy ordnance pieces universally (Rocket, Plasma,
// BFG) regardless of which Dual_X was picked -- those don't belong to
// any one specialization, every class gets them.
//
// All 8 get listed in MAPINFO's PlayerClasses -- GZDoom shows its own
// native class-select screen at game start automatically.
// =====================================================================

class VR_VanillaPlus : DoomPlayer
{
	Default
	{
		Player.DisplayName "Vanilla+";
		Player.StartItem "RS_VP_Fist";
		Player.StartItem "RS_VP_Fist2";
		Player.StartItem "RS_VP_Pistol";
		Player.StartItem "RS_VP_Pistol2";
		Player.StartItem "Clip", 50;
		Player.StartItem "RS_VP_PistolLoaded", 11;
		Player.StartItem "RS_VP_PistolLoaded2", 11;
	}
}

class VR_Dual_Pistol : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Pistols";
		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Pistol";
		Player.StartItem "VR_Pistol4";
		Player.StartItem "Clip", 72;
		Player.StartItem "VR_PistolLoaded", 12;
		Player.StartItem "VR_PistolLoaded4", 12;
	}
}

class VR_Dual_Revolver : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Revolvers";
		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Revolver";
		Player.StartItem "VR_Revolver4";
		Player.StartItem "Clip", 36;
		Player.StartItem "VR_RevLoaded", 6;
		Player.StartItem "VR_RevLoaded4", 6;
	}
}

class VR_Dual_Rifle : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Rifles";
		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Rifle";
		Player.StartItem "VR_Rifle4";
		Player.StartItem "Clip", 60;
		Player.StartItem "VR_RifleLoaded", 20;
		Player.StartItem "VR_RifleLoaded4", 20;
	}
}

class VR_Dual_SMG : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual SMGs";
		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_SMG";
		Player.StartItem "VR_SMG4";
		Player.StartItem "Clip", 90;
		Player.StartItem "VR_SMGLoaded", 30;
		Player.StartItem "VR_SMGLoaded4", 30;
	}
}

class VR_Dual_Shotgun : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Shotguns";
		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Shotgun";
		Player.StartItem "VR_Shotgun4";
		Player.StartItem "VR_Shell", 24;
		Player.StartItem "VR_ShotLoaded", 8;
		Player.StartItem "VR_ShotLoaded4", 8;
	}
}

class VR_Dual_SSG : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Super Shotguns";
		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_SuperShotgun";
		Player.StartItem "VR_SuperShotgun4";
		Player.StartItem "VR_Shell", 12;
		Player.StartItem "VR_SSGLoaded", 2;
		Player.StartItem "VR_SSGLoaded4", 2;
	}
}

class VR_Dual_Chaingun : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Chainguns";
		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Chaingun";
		Player.StartItem "VR_Chaingun4";
		Player.StartItem "VR_ChaingunAmmo", 60;
	}
}
