// RS_VP_Chaingun -- "Minigun", the Vanilla+ chaingun.
// ---------------------------------------------------------------------
// Real data: dmg 5, 1 bullet, magazine 150, sprites
// VLCN/VLCS/CHAG/NGLD/RCLD/CHAF/MNIG/EMNG.
//
// The source draws reserve from its own custom "Nato" pickup class,
// which isn't ported -- vanilla Clip instead, same reasoning as ARifle.
//
// Restored in this pass:
//   - The real three-phase firing cycle: spin-up, sustained Hold, and
//     wind-down. Previously this fired one shot per trigger pull like a
//     rifle, with no spin at all -- the barrels never turned.
//   - The EMPTY-BARREL state. When the belt runs dry the source swaps
//     the whole weapon to a second sprite set (CHAG, and EMNG as its
//     world pickup) so a dry minigun visibly reads as dry in the hands.
//     Tracked here with a bool rather than the source's inventory-item
//     flag, since ZScript has a real field to put it in.
//   - Separate loaded/empty reload animations (RCLD vs NGLD).
// =====================================================================
class RS_VP_Chaingun : RS_VP_Weapon replaces Chaingun
{
	Default
	{
		Tag "Minigun";
		Weapon.SelectionOrder 4000;
		Weapon.SlotNumber 4;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 50;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "RS_VP_ChaingunLoaded";
		Weapon.UpSound "rs_vp_minigun_equip";
		Inventory.PickupMessage "You got the Minigun!";
		Inventory.PickupSound "rs_vp_minigun_pickup";
		+WEAPON.NOHANDSWITCH;
	}

	// True once the belt runs dry, false again after a reload. Drives the
	// CHAG (empty) sprite set in place of VLCN. The source carried this as
	// an "EmptyMini" inventory token because DECORATE had nowhere else to
	// put it; ZScript has a real field, so it lives here.
	bool bBeltEmpty;

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 5;
			Accuracy      = 58;
			Velocity      = 8000;
			CritChance    = 0.01;
			Capacity      = 150;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 7 + idx);
			Accuracy      = RS_Roll.RollDouble(52, 66);
			Velocity      = RS_Roll.RollDouble(7000, 9000);
			CritChance    = RS_Roll.RollDouble(0.008, 0.015 + idx * 0.004);
			Capacity      = 150;
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

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_Chaingun2";
	}

	// The Assault Rifle has no classic-Doom slot of its own, so it can't
	// `replaces` anything. Instead, a world-placed Chaingun has a
	// player-controlled chance to silently become an Assault Rifle before
	// it's ever seen. 0 = disabled -- new, unbalanced content by default.
	// A parallel "zombieman drop chance" idea is deliberately not built
	// here: it depends on a Rifle Zombieman monster that doesn't exist yet.
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		let ch = CVar.GetCVar("rs_vanillaplus_arifle_chance", null);
		double chance = ch ? ch.GetFloat() : 0.0;
		if (chance > 0 && FRandom(0, 1) < chance)
		{
			Spawn("RS_VP_ARifle", Pos, ALLOW_REPLACE);
			Destroy();
		}
	}

	States
	{
	Spawn:
		MNIG A -1;
		Stop;

	Ready:
		TNT1 A 0 A_JumpIf(invoker.bBeltEmpty, "ReadyEmpty");
		VLCN A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	// Dry: same idle, different weapon in your hands.
	ReadyEmpty:
		TNT1 A 0 A_JumpIf(!invoker.bBeltEmpty, "Ready");
		CHAG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		TNT1 A 0 A_PlaySound("rs_vp_minigun_down", CHAN_AUTO);
		TNT1 A 0 A_JumpIf(invoker.bBeltEmpty, "DeselectEmpty");
		VLCN A 1 A_Lower;
		Loop;

	DeselectEmpty:
		CHAG A 1 A_Lower;
		Loop;

	Select:
		TNT1 A 0 A_JumpIf(invoker.bBeltEmpty, "SelectEmpty");
		VLCN A 1 A_Raise;
		Loop;

	SelectEmpty:
		CHAG A 1 A_Raise;
		Loop;

	// --- Spin up / sustain / wind down ---------------------------------
	// The barrels have to come up to speed before the first round leaves,
	// and they coast back down after the trigger is released. Fire only
	// spins; Hold is where rounds actually go out.
	Fire:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "SpinUp");
		Goto Reload;

	SpinUp:
		TNT1 A 0 A_PlaySound("rs_vp_minigun_start", CHAN_BODY);
		VLCN B 2;
		VLCN CD 1;
		VLCN ABCD 1;
		TNT1 A 0 A_ReFire();
		Goto WindDown;

	Hold:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) <= 0, "WindDownEmpty");
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "HoldSpin");
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_Fire("rs_vp_minigun_fire", true, "RS_CasingRifle");
		VLCS A 1;
		VLCS B 1;
		TNT1 A 0 A_RS_VP_EjectCasing("RS_CasingRifle", -10.0, -8.0);
		VLCS C 1;
		VLCS D 1;
		TNT1 A 0 A_ReFire("Hold");
		Goto WindDown;

	// Barrels still turning but the cadence gate isn't up yet -- keep
	// spinning rather than stalling the animation.
	HoldSpin:
		VLCS ABCD 1;
		TNT1 A 0 A_ReFire("Hold");
		Goto WindDown;

	WindDown:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) <= 0, "WindDownEmpty");
		TNT1 A 0 A_ClearReFire();
		TNT1 A 0 A_PlaySound("rs_vp_minigun_stop", CHAN_BODY);
		VLCS A 1;
		VLCS B 1;
		VLCS CD 1 A_WeaponReady(WRF_NOSWITCH);
		VLCS ABCD 2 A_WeaponReady(WRF_NOSWITCH);
		VLCN ABC 2 A_WeaponReady();
		VLCN DABCDA 3 A_WeaponReady();
		VLCS BCD 2 A_WeaponReady();
		TNT1 A 0 A_ClearReFire();
		Goto Ready;

	// Ran dry mid-burst: the belt is spent, so the weapon changes over to
	// its empty appearance as it coasts down.
	WindDownEmpty:
		TNT1 A 0 { invoker.bBeltEmpty = true; }
		TNT1 A 0 A_ClearReFire();
		TNT1 A 0 A_PlaySound("rs_vp_minigun_stop", CHAN_BODY);
		CHAG A 1;
		CHAG B 1;
		CHAG CD 1;
		CHAG ABCD 2;
		CHAG ABC 2 A_WeaponReady(WRF_NOFIRE);
		CHAG DABCD 3 A_WeaponReady(WRF_NOFIRE);
		CHAG BCD 2 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 0 A_ClearReFire();
		Goto ReadyEmpty;

	// --- Reload --------------------------------------------------------
	// Two animations: RCLD for topping up a belt that still has rounds,
	// NGLD for threading a fresh belt into a completely empty gun.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_JumpIf(invoker.bBeltEmpty, "ReloadEmpty");
		Goto ReloadPartial;

	ReloadPartial:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		TNT1 A 0 A_PlaySound("rs_vp_minigun_chain", CHAN_AUTO);
		RCLD ABCDEEE 1;
		TNT1 A 0 A_PlaySound("rs_vp_minigun_reload", CHAN_AUTO);
		RCLD F 2;
		TNT1 A 0 A_RS_VP_DropMag();
		NGLD GHIJKL 2 A_RS_ReloadAtomic();
		Goto ReloadFinish;

	ReloadEmpty:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		TNT1 A 0 A_PlaySound("rs_vp_minigun_chain", CHAN_AUTO);
		NGLD ABCDEEE 1;
		TNT1 A 0 A_PlaySound("rs_vp_minigun_reload", CHAN_AUTO);
		NGLD F 2;
		TNT1 A 0 A_RS_VP_DropMag();
		NGLD GHIJKL 2 A_RS_ReloadAtomic();
		Goto ReloadFinish;

	ReloadFinish:
		TNT1 A 0 { invoker.bBeltEmpty = false; }
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		VLCN BCD 1 A_WeaponReady();
		VLCN ABCDABC 2 A_WeaponReady();
		VLCN DABCD 3 A_WeaponReady();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		CHAF A 1 Bright A_Light2();
		CHAF B 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_Chaingun2 : RS_VP_Chaingun
{
	Default
	{
		Tag "Minigun (Off-Hand)";
		Weapon.SelectionOrder 3999;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "RS_VP_ChaingunLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
