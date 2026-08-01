// =====================================================================
// VR_PlayerClasses -- 7 selectable starting loadouts.
// ---------------------------------------------------------------------
// Every Dual_X class grants Fist + two Basic-tier weapons of that type
// (one mainhand, one offhand), plus all three heavy ordnance pieces
// universally (Rocket, Plasma, BFG) if "Allow Big Guns" is on -- those
// don't belong to any one specialization, every class gets them when
// enabled.
//
// All 7 get listed in MAPINFO's PlayerClasses -- GZDoom shows its own
// native class-select screen at game start automatically.
// =====================================================================

// ---------------------------------------------------------------------
// VR_DualClassBase -- shared behavior for all 7 Dual_X classes.
// ---------------------------------------------------------------------
// Collapses what used to be seven byte-identical PostBeginPlay copies
// into one, following the same virtual-override shape already
// established by GetHeavyProjectile()/GetOffhandClass() elsewhere: a
// base does the real work, each subclass just names its own weapon.
//
// Force-equips the granted mainhand weapon explicitly rather than
// trusting engine default weapon-selection at spawn, which was leaving
// the player holding fists instead of their class weapon.
// =====================================================================
class VR_DualClassBase : DoomPlayer abstract
{
	// Each Dual_X class overrides this with its own mainhand identity-1
	// class name (e.g. "VR_Revolver"). Empty string is the "nothing to
	// force-equip" default -- shouldn't happen for a real subclass, but
	// keeps this base safe to instantiate directly if it ever needs to be.
	virtual string GetMainhandClass()
	{
		return "";
	}

	// Class-gating family this class is allowed to pick up -- see
	// RS_ClassGating.zs. None means "not gated" and should never be
	// returned by a real Dual_X subclass.
	virtual EVR_Family GetFamily()
	{
		return EVR_Family_None;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		string mainhand = GetMainhandClass();
		if (mainhand.Length())
		{
			let w = Weapon(FindInventory(mainhand));
			if (w)
				player.PendingWeapon = w;
		}

		let cv = CVar.GetCVar("rs_dualclass_allowbigguns", null);
		if (cv && cv.GetBool())
		{
			GiveInventory("VR_RocketLauncher", 1);
			GiveInventory("VR_PlasmaRifle", 1);
			GiveInventory("VR_BFG9000", 1);
			// Reserve ammo for the granted heavy ordnance -- these three
			// weapons don't currently consume ammo when fired (a known,
			// separate bug, see HANDOFF), but granting the guns with no
			// reserve at all would be wrong regardless of when that gets
			// fixed.
			GiveInventory("RocketAmmo", 20);
			GiveInventory("Cell", 200);
		}
	}
}

class VR_Dual_Pistol : VR_DualClassBase
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

	override string GetMainhandClass() { return "VR_Pistol"; }
	override EVR_Family GetFamily() { return EVR_Family_Pistol; }
}

class VR_Dual_Revolver : VR_DualClassBase
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

	override string GetMainhandClass() { return "VR_Revolver"; }
	override EVR_Family GetFamily() { return EVR_Family_Revolver; }
}

class VR_Dual_Rifle : VR_DualClassBase
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

	override string GetMainhandClass() { return "VR_Rifle"; }
	override EVR_Family GetFamily() { return EVR_Family_Rifle; }
}

class VR_Dual_SMG : VR_DualClassBase
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

	override string GetMainhandClass() { return "VR_SMG"; }
	override EVR_Family GetFamily() { return EVR_Family_SMG; }
}

class VR_Dual_Shotgun : VR_DualClassBase
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

	override string GetMainhandClass() { return "VR_Shotgun"; }
	override EVR_Family GetFamily() { return EVR_Family_Shotgun; }
}

class VR_Dual_SSG : VR_DualClassBase
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

	override string GetMainhandClass() { return "VR_SuperShotgun"; }
	override EVR_Family GetFamily() { return EVR_Family_SuperShotgun; }
}

class VR_Dual_Chaingun : VR_DualClassBase
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

	override string GetMainhandClass() { return "VR_Chaingun"; }
	override EVR_Family GetFamily() { return EVR_Family_Chaingun; }
}

// ---------------------------------------------------------------------
// RS_GH_Weaponset -- displayed as "Vanilla+". Ungated (no family gating,
// same as leaving GetFamily() at its EVR_Family_None default -- see
// RS_ClassGating.zs's own comment, which already anticipated exactly
// this case). Starts with Fist/offhand Fist + two pistols, loaded.
// RS_Weapon.AttachToOwner already auto-fills each weapon's loaded
// chamber to Capacity the instant it's granted, so granting the guns is
// enough -- the magazines fill themselves, no reload needed on pickup.
//
// "Start with Rifle instead of Pistols" (rs_vp_startrifle, Vanilla+
// Options menu) swaps the granted mainhand+offhand pair entirely, so it
// has to happen in PostBeginPlay code rather than static StartItem --
// same shape as VR_DualClassBase's own "Allow Big Guns" cvar check.
// ---------------------------------------------------------------------
class RS_GH_Weaponset : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Vanilla+";

		Player.StartItem "Fist";
		Player.StartItem "VR_Fist2";

		// Reserve ammo -- covers the starting pistols (or rifles, if the
		// swap option is on) and anything picked up later.
		Player.StartItem "Clip", 200;
	}

	override string GetMainhandClass()
	{
		let cv = CVar.GetCVar("rs_vp_startrifle", null);
		return (cv && cv.GetBool()) ? "RS_GH_Rifle" : "RS_GH_Pistol";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		let cv = CVar.GetCVar("rs_vp_startrifle", null);
		if (cv && cv.GetBool())
		{
			GiveInventory("RS_GH_Rifle", 1);
			GiveInventory("RS_GH_Rifle4", 1);
		}
		else
		{
			GiveInventory("RS_GH_Pistol", 1);
			GiveInventory("RS_GH_Pistol4", 1);
		}
	}
	// No GetFamily() override -- inherits EVR_Family_None from the base,
	// which is deliberately "ungated" here, not an oversight.
}
