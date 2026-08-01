// VR_Pistol -- the Pistol weapon type.
// ---------------------------------------------------------------------
// Real data pulled from the old reference file (sprites/sounds/frame
// sequences/damage only -- no old architecture): dmg anchor 4-10,
// magazine 12, reload frames PISG F-R / S-W / X-Y exactly. Real sounds:
// 9mmshoot/9mmclip1/9mmclip2/9mmslide/rs_fx_weapon_empty. True semi-auto: trigger
// release required, cadence overshoot costs Accuracy, not blocked.
// =====================================================================
class VR_Pistol : RS_Weapon
{
	Default
	{
		Tag "Pickpocket";
		Weapon.SelectionOrder 1888;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 48;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "VR_PistolLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Pistol; }

	override string GetBaseKeywords()
	{
		return "archetype:pistol trigger:semiauto delivery:bullet payload:single feed:atomic-fill reserve:clip element:kinetic promotion:pellet set:radiantsilvergun";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(4, 10); // real vanilla anchor
				Accuracy      = RS_Roll.RollDouble(70, 80);
				Velocity      = RS_Roll.RollDouble(7000, 9000);
				CritChance    = RS_Roll.RollDouble(0.01, 0.03);
				Capacity      = 12; // real magazine size
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(6, 13);
				Accuracy      = RS_Roll.RollDouble(72, 82);
				Velocity      = RS_Roll.RollDouble(7000, 9000);
				CritChance    = RS_Roll.RollDouble(0.015, 0.035);
				Capacity      = 12;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(8, 16);
				Accuracy      = RS_Roll.RollDouble(74, 84);
				Velocity      = RS_Roll.RollDouble(7000, 9000);
				CritChance    = RS_Roll.RollDouble(0.02, 0.04);
				Capacity      = 12;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(11, 19);
				Accuracy      = RS_Roll.RollDouble(76, 86);
				Velocity      = RS_Roll.RollDouble(7000, 9500);
				CritChance    = RS_Roll.RollDouble(0.025, 0.045);
				Capacity      = 12;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(14, 22);
				Accuracy      = RS_Roll.RollDouble(78, 88);
				Velocity      = RS_Roll.RollDouble(7000, 10000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 15;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(80, 90);
				Velocity      = RS_Roll.RollDouble(7000, 10500);
				CritChance    = RS_Roll.RollDouble(0.035, 0.055);
				Capacity      = 15;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(12, 18);
					CritChance    = RS_Roll.RollDouble(0.05, 0.08);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(2, 6);
					CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				}
				Accuracy = RS_Roll.RollDouble(55, 70);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				Capacity = 12;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(9, 15);
				Accuracy      = RS_Roll.RollDouble(65, 80);
				Velocity      = RS_Roll.RollDouble(7000, 9500);
				CritChance    = RS_Roll.RollDouble(0.04, 0.07);
				Capacity      = 12;
				break;
		}

		if (t == VRT_Cursed)
		{
			LockedDamage     = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		RateOfFire       = 4;   // real cadence, fixed by the fire animation
		ReloadSpeed       = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount       = 1;
		Choke             = 0;
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}


	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_Pistol(),
			spreadScale: 0.05,
			usesCadence: true,
			ammoCost: 1,
			casing: RS_Catalog.CASING_Small(),
			profName: "9mm"));
	}

	States
	{
	Spawn:
		PSP1 A -1;
		Stop;

	Ready:
		PISG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		PISG A 1 A_Lower;
		Loop;

	Select:
		PISG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		PISG B 2;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		PISG C 2;
		PISG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// Real exact frame sequence from the reference file.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("9mmclip1", CHAN_AUTO);
		PISG FGHIJKLMNOPQR 1;
		TNT1 A 0 A_PlaySound("9mmclip2", CHAN_AUTO);
		PISG STUVW 1;
		TNT1 A 0 A_PlaySound("9mmslide", CHAN_AUTO);
		PISG XY 1 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		PISF A 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_Pistol2 : VR_Pistol
{
	Default
	{
		Tag "Grifter";
		Weapon.SelectionOrder 1887;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_PistolLoaded2";
	}
}

class VR_Pistol3 : VR_Pistol
{
	Default
	{
		Tag "Cutpurse";
		Weapon.SelectionOrder 1886;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_PistolLoaded3";
	}
}

class VR_Pistol4 : VR_Pistol
{
	Default
	{
		Tag "Highwayman";
		Weapon.SelectionOrder 1885;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_PistolLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Pistol5 : VR_Pistol
{
	Default
	{
		Tag "Knave";
		Weapon.SelectionOrder 1884;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_PistolLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Pistol6 : VR_Pistol
{
	Default
	{
		Tag "Scoundrel";
		Weapon.SelectionOrder 1883;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_PistolLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
