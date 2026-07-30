// VR_Pistol -- the Pistol weapon type.
// ---------------------------------------------------------------------
// Real data pulled from the old reference file (sprites/sounds/frame
// sequences/damage only -- no old architecture): dmg anchor 4-10,
// magazine 12, reload frames PISG F-R / S-W / X-Y exactly. Real sounds:
// 9mmshoot/9mmclip1/9mmclip2/9mmslide/AKEMPT. True semi-auto: trigger
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

	override void ApplyUpgradeCard(EVR_Tier newTier)
	{
		bool isSacrificeDowngrade = (Tier == VRT_Prototype && newTier == VRT_Basic);
		RollStats(newTier);
		if (isSacrificeDowngrade)
			PelletCount += 1;
	}

	action void A_RS_FirePistol()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			TakeInventory(invoker.AmmoType2, 1);
			A_RS_MarkFired();
			return;
		}

		double dmg = invoker.DamagePerShot * dmgMult;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		int pellets = max(1, int(invoker.PelletCount * pelletMult));
		int overshoot = invoker.GetCadenceOvershoot();
		double spread = (100.0 - invoker.Accuracy) * 0.05 + (overshoot * 0.15);

		A_RS_FireBallisticVolley(pellets, spread, int(dmg), invoker.CritChance, invoker.Velocity);
		A_PlaySound("9mmshoot", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, false);
		RS_HiFiFX.CasingEject(self, "RS_CasingSmall");
		TakeInventory(invoker.AmmoType2, 1);
		A_RS_MarkFired();
	}

	action void A_RS_Backfire()
	{
		A_PlaySound("AKEMPT", CHAN_WEAPON);
		double dmg = invoker.DamagePerShot;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;
		player.mo.DamageMobj(invoker, player.mo, int(dmg), 'BackfireDamage');
	}

	action void A_RS_MagLoad()
	{
		int needed = invoker.Capacity - CountInv(invoker.AmmoType2);
		int available = CountInv("Clip");
		int toLoad = min(needed, available);
		if (toLoad > 0)
		{
			int clipCost = max(1, toLoad - invoker.GetReloadBonusRounds());
			clipCost = min(clipCost, available);
			TakeInventory("Clip", clipCost);
			GiveInventory(invoker.AmmoType2, toLoad);
		}
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
		TNT1 A 0 A_RS_FirePistol();
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
		PISG XY 1 A_RS_MagLoad();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		PISF A 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
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
