// RS_VP_Shotgun -- "Riot Shotgun", the Vanilla+ pump shotgun.
// ---------------------------------------------------------------------
// Real data: dmg 6, 7 pellets, magazine 8, sprites RIOT/RGSW/RGLS/BOOF/RIOB.
//
// No alt-fire: the source's was aim-down-sights, not ported. See
// docs/DIRECTIVE_GNRC_REIMPORT.md section 2.
//
// Restored in this pass:
//   - The pump cycle as its own state. The spent shell ejects on the
//     PUMP, not on the shot -- the source fires its casing spawner from
//     the pump frames, which is why the shell appears a beat after the
//     bang rather than with it.
//   - The real per-shell reload loop (RGLS sprites), including the
//     source's chamber-load first shell and its A_WeaponReady(WRF_NOBOB)
//     interrupt, so a reload can be cut short by firing -- the defining
//     behavior of a tube-fed shotgun and completely absent before.
// =====================================================================
class RS_VP_Shotgun : RS_VP_Weapon replaces Shotgun
{
	Default
	{
		Tag "Riot Shotgun";
		Weapon.SelectionOrder 1300;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 8;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoType2 "RS_VP_ShotgunLoaded";
		Weapon.UpSound "rs_vp_shotgun_select";
		Inventory.PickupMessage "You got the Riot Shotgun!";
		Inventory.PickupSound "rs_vp_shotgun_pump";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 6;
			Accuracy      = 60;
			Velocity      = 7000;
			CritChance    = 0.015;
			Capacity      = 8;
			PelletCount   = 7;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 8 + idx);
			Accuracy      = RS_Roll.RollDouble(55, 68);
			Velocity      = RS_Roll.RollDouble(6500, 8000);
			CritChance    = RS_Roll.RollDouble(0.01, 0.02 + idx * 0.005);
			Capacity      = 8;
			PelletCount   = 7;
		}

		RateOfFire      = 2;
		ReloadSpeed     = 1.0;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_Shotgun2";
	}

	States
	{
	Spawn:
		RIOB A -1;
		Stop;

	Ready:
		RIOT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_deselect", CHAN_AUTO);
		RIOT A 1 A_Lower;
		Loop;

	Select:
		RIOT A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	// Fire consumes the shell; the spent hull stays in the chamber until
	// the pump throws it, so no casing is spawned here.
	Shoot:
		RIOT D 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_Fire("rs_vp_shotgun_fire");
		RIOT D 1;
		RIOT B 1;
		RIOT B 1;
		RIOT C 1;
		RIOT C 1;
		RIOT B 1;
		RIOT B 1;
		RIOT D 1;
		RIOT A 1;
		Goto Pump;

	// Rack back, eject, rack forward. This is where the shell comes out.
	Pump:
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_bck", CHAN_BODY);
		RIOT EF 2;
		RIOT F 1;
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_fwd", CHAN_BODY);
		RIOT F 1;
		TNT1 A 0 A_RS_VP_EjectCasing("RS_CasingShell", 2.0, -2.75);
		RIOT E 1;
		RIOT E 1;
		RIOT A 4;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	// --- Reload --------------------------------------------------------
	// Tube-fed, one shell at a time. An empty gun needs its first shell
	// chambered (which costs a pump); a partially-loaded one just tops up.
	// A_WeaponReady(WRF_NOBOB) inside the loop is what lets the player
	// break off mid-reload and fire -- the source's behavior, and the
	// whole point of a shell-by-shell reload.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "ReloadOpen");
		Goto ReloadFirstShell;

	// Empty: chamber the first shell, then pump it home before looping.
	ReloadFirstShell:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		RGSW ABC 1 A_WeaponReady(WRF_NOSWITCH|WRF_NOFIRE);
		RGSW DEF 1 A_WeaponReady(WRF_NOSWITCH|WRF_NOFIRE);
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_load", CHAN_AUTO);
		RGLS ABC 1 A_WeaponReady(WRF_NOSWITCH|WRF_NOFIRE);
		TNT1 A 0 A_RS_ReloadIncremental();
		RGLS DEFGH 1 A_WeaponReady(WRF_NOSWITCH|WRF_NOFIRE);
		Goto ReloadPump;

	// Partially loaded: no chambering needed, straight into the loop.
	ReloadOpen:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		RGSW ABC 1 A_WeaponReady(WRF_NOBOB);
		RGSW DEF 1 A_WeaponReady(WRF_NOBOB);
		Goto ReloadLoop;

	ReloadLoop:
		RGLS ABC 1 A_WeaponReady(WRF_NOBOB);
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_load", CHAN_AUTO);
		TNT1 A 0 A_RS_ReloadIncremental();
		RGLS DEF 1 A_WeaponReady(WRF_NOBOB);
		RGLS III 1 A_WeaponReady(WRF_NOBOB);
		TNT1 A 0 A_ReFire();
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "ReloadEnd");
		TNT1 A 0 A_JumpIf(CountInv("Shell") > 0, "ReloadLoop");
		Goto ReloadEnd;

	ReloadPump:
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_bck", CHAN_BODY);
		RGSW FE 1;
		RGSW G 2;
		RGSW H 2;
		RGSW H 2;
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_fwd", CHAN_BODY);
		RGSW I 1;
		RGSW J 3;
		RGSW D 4;
		RGSW E 2;
		RGSW F 2;
		TNT1 A 0 A_ReFire();
		TNT1 A 0 A_JumpIf(CountInv("Shell") > 0 && CountInv(invoker.AmmoType2) < invoker.Capacity, "ReloadLoop");
		Goto ReloadEnd;

	ReloadEnd:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		RGSW F 2;
		RGSW E 2;
		RGSW D 1;
		RGSW C 1;
		RGSW B 1;
		RGSW A 1;
		RIOT A 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		BOOF B 1 Bright A_Light2();
		BOOF A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_Shotgun2 : RS_VP_Shotgun
{
	Default
	{
		Tag "Riot Shotgun (Off-Hand)";
		Weapon.SelectionOrder 1299;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "RS_VP_ShotgunLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
