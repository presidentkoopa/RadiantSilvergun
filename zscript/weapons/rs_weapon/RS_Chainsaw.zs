// VR_Chainsaw -- the main arsenal's first melee weapon.
// ---------------------------------------------------------------------
// Assets sourced from 1.0b_Weapons_VanillaVRPlus_v1.2 (Chainsaw.md3 HUD
// model, SAWG A-D 3D frames, the CSAW* sound set) -- see MODELDEF's
// "VR_Chainsaw" blocks for the exact frame indices (SAWG A/B/C/D ->
// model frames 0/3/5/7, the pack's own verified values). Ready idles on
// A<->B; Fire swings C<->D, matching vanilla Doom's own two-idle/
// two-attack chainsaw frame convention.
//
// No ammo, no magazine, no reload -- Capacity/Velocity/AmmoType2 are all
// unused fields here, same as RS_VP_Chainsaw. RateOfFire is set to match
// the real swing animation length (4 tics/swing = ~9/sec), not an
// arbitrary round number, so the Weapon Selection screen's DPS math
// stays honest.
// =====================================================================
class VR_Chainsaw : RS_Weapon
{
	Default
	{
		Tag "Sawtooth";
		Weapon.SelectionOrder 1500;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		Weapon.UpSound "sawstrt";
		Weapon.ReadySound "sawredy";
		+WEAPON.MELEEWEAPON;
		+WEAPON.NOAUTOFIRE;
		+WEAPON.NOHANDSWITCH;
	}

	override string GetBaseKeywords()
	{
		return "archetype:melee trigger:fullauto delivery:melee payload:single feed:none reserve:none element:kinetic promotion:pellet set:radiantsilvergun";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(3, 6);
				CritChance    = RS_Roll.RollDouble(0.02, 0.05);
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(4, 7);
				CritChance    = RS_Roll.RollDouble(0.025, 0.06);
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(5, 9);
				CritChance    = RS_Roll.RollDouble(0.03, 0.07);
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(6, 11);
				CritChance    = RS_Roll.RollDouble(0.035, 0.08);
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(7, 13);
				CritChance    = RS_Roll.RollDouble(0.04, 0.09);
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(9, 15);
				CritChance    = RS_Roll.RollDouble(0.05, 0.1);
				break;
			case VRT_Trash:
				DamagePerShot = RS_Roll.RollInt(2, 4);
				CritChance    = RS_Roll.RollDouble(0.01, 0.03);
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(5, 8);
				CritChance    = RS_Roll.RollDouble(0.04, 0.07);
				break;
		}

		Accuracy        = 100; // melee, always connects in range
		Velocity        = 0;   // melee, no projectile
		Capacity        = 0;   // no magazine
		RateOfFire      = 9;   // matches the real 4-tic swing animation
		ReloadSpeed     = 1.0; // no reload exists for this weapon
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (t == VRT_Cursed)
		{
			LockedDamage     = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	// Melee: no ammo, no spread, 64-unit reach. Same GunBonsai XP gap as
	// the chaingun's hitscan -- no projectile, nothing to attribute.
	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeMelee(
			range: 64.0,
			fireSnd: RS_Catalog.SND_Chainsaw(),
			puff: "BulletPuff",
			profName: "Sawteeth"));
	}

	States
	{
	Spawn:
		SAWG A -1;
		Stop;

	Ready:
		SAWG A 4 A_WeaponReady();
		SAWG B 4 A_WeaponReady();
		Loop;

	Deselect:
		TNT1 A 0 A_PlaySound("sawstop", CHAN_WEAPON);
		SAWG A 1 A_Lower;
		Loop;

	Select:
		TNT1 A 0 A_PlaySound("sawstrt", CHAN_WEAPON);
		SAWG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		SAWG C 2;
		TNT1 A 0 A_RS_FireSlot(0);
		SAWG D 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		Stop;
	}
}

class VR_Chainsaw2 : VR_Chainsaw
{
	Default
	{
		Tag "Ripsaw";
		Weapon.SelectionOrder 1499;
		Weapon.SlotNumber 1;
	}
}

class VR_Chainsaw3 : VR_Chainsaw
{
	Default
	{
		Tag "Hacksaw";
		Weapon.SelectionOrder 1498;
		Weapon.SlotNumber 1;
	}
}

class VR_Chainsaw4 : VR_Chainsaw
{
	Default
	{
		Tag "Bonesaw";
		Weapon.SelectionOrder 1497;
		Weapon.SlotNumber 1;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Chainsaw5 : VR_Chainsaw
{
	Default
	{
		Tag "Timber";
		Weapon.SelectionOrder 1496;
		Weapon.SlotNumber 1;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Chainsaw6 : VR_Chainsaw
{
	Default
	{
		Tag "Ripper";
		Weapon.SelectionOrder 1495;
		Weapon.SlotNumber 1;
		+WEAPON.OFFHANDWEAPON;
	}
}
