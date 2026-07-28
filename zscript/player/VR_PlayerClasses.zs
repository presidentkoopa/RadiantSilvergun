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
		Player.StartItem "Fist";
		Player.StartItem "Pistol";
		Player.StartItem "Clip", 50;
	}
}

class VR_Dual_Pistol : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Pistols";
		Player.StartItem "Fist";
		Player.StartItem "VR_Pistol";
		Player.StartItem "VR_Pistol4";
		Player.StartItem "VR_RocketLauncher";
		Player.StartItem "VR_PlasmaRifle";
		Player.StartItem "VR_BFG9000";
	}
}

class VR_Dual_Revolver : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Revolvers";
		Player.StartItem "Fist";
		Player.StartItem "VR_Revolver";
		Player.StartItem "VR_Revolver4";
		Player.StartItem "VR_RocketLauncher";
		Player.StartItem "VR_PlasmaRifle";
		Player.StartItem "VR_BFG9000";
	}
}

class VR_Dual_Rifle : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Rifles";
		Player.StartItem "Fist";
		Player.StartItem "VR_Rifle";
		Player.StartItem "VR_Rifle4";
		Player.StartItem "VR_RocketLauncher";
		Player.StartItem "VR_PlasmaRifle";
		Player.StartItem "VR_BFG9000";
	}
}

class VR_Dual_SMG : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual SMGs";
		Player.StartItem "Fist";
		Player.StartItem "VR_SMG";
		Player.StartItem "VR_SMG4";
		Player.StartItem "VR_RocketLauncher";
		Player.StartItem "VR_PlasmaRifle";
		Player.StartItem "VR_BFG9000";
	}
}

class VR_Dual_Shotgun : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Shotguns";
		Player.StartItem "Fist";
		Player.StartItem "VR_Shotgun";
		Player.StartItem "VR_Shotgun4";
		Player.StartItem "VR_RocketLauncher";
		Player.StartItem "VR_PlasmaRifle";
		Player.StartItem "VR_BFG9000";
	}
}

class VR_Dual_SSG : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Super Shotguns";
		Player.StartItem "Fist";
		Player.StartItem "VR_SuperShotgun";
		Player.StartItem "VR_SuperShotgun4";
		Player.StartItem "VR_RocketLauncher";
		Player.StartItem "VR_PlasmaRifle";
		Player.StartItem "VR_BFG9000";
	}
}

class VR_Dual_Chaingun : DoomPlayer
{
	Default
	{
		Player.DisplayName "Dual Chainguns";
		Player.StartItem "Fist";
		Player.StartItem "VR_Chaingun";
		Player.StartItem "VR_Chaingun4";
		Player.StartItem "VR_RocketLauncher";
		Player.StartItem "VR_PlasmaRifle";
		Player.StartItem "VR_BFG9000";
	}
}
