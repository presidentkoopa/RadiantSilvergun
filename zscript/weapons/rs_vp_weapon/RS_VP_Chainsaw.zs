// RS_VP_Chainsaw -- "Chainsaw", a brand-new weapon type for this project.
// ---------------------------------------------------------------------
// Real data: sustained melee, sprites SAWN (ready/running) / CSAW Z
// (world pickup). Sounds are the HQ vanilla chainsaw set -- up / idle /
// full / hit, all four already staged in SNDINFO.
//
// No ammo, no projectile, no casings. Gets RS_HiFiFX smoke on sustained
// contact (the one melee weapon where barrel-smoke-style FX genuinely
// makes sense) but no CasingEject and no ProjectileClass.
// =====================================================================
class RS_VP_Chainsaw : RS_VP_Weapon replaces Chainsaw
{
	Default
	{
		Tag "Chainsaw";
		Weapon.SelectionOrder 2200;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		Weapon.UpSound "rs_vp_saw_start";
		Weapon.ReadySound "rs_vp_saw_idle";
		+WEAPON.MELEEWEAPON
		+WEAPON.NOAUTOFIRE
		+WEAPON.NOHANDSWITCH
		Obituary "$OB_MPCHAINSAW";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 2;
			Accuracy      = 100;
			Velocity      = 0;
			CritChance    = 0.0;
			Capacity      = 0;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(2, 4 + idx);
			Accuracy      = 100;
			Velocity      = 0;
			CritChance    = RS_Roll.RollDouble(0.0, 0.03);
			Capacity      = 0;
		}

		RateOfFire      = 14;
		ReloadSpeed     = 1.0;
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	action void A_RS_VP_Saw()
	{
		A_CustomPunch(invoker.DamagePerShot, false, 0, "BulletPuff", 80);
		A_PlaySound("rs_vp_saw_flesh", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, true);
		A_RS_MarkFired();
	}

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_Chainsaw2";
	}

	States
	{
	Spawn:
		CSAW Z -1;
		Stop;

	Ready:
		SAWN A 4 A_WeaponReady();
		SAWN B 4 A_WeaponReady();
		Loop;

	Deselect:
		SAWN A 1 A_Lower;
		Loop;

	Select:
		SAWN A 1 A_Raise;
		Loop;

	Fire:
		SAWN D 2;
		TNT1 A 0 A_RS_VP_Saw();
		SAWN E 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;
	}
}

class RS_VP_Chainsaw2 : RS_VP_Chainsaw
{
	Default
	{
		Tag "Chainsaw (Off-Hand)";
		Weapon.SelectionOrder 2199;
		Weapon.SlotNumber 1;
		+WEAPON.OFFHANDWEAPON
	}
}
