// RS_VP_PlasmaRifle -- "Plasma Rifle", the Vanilla+ plasma gun.
// ---------------------------------------------------------------------
// Real data: magazine 60, full auto, sprites PLZG/PLZR/PLCH/PLZA/PLAS.
//
// Fires the vanilla PlasmaBall class, which RS_EnhancedFX transparently
// replaces with RS_EnhancedPlasmaBall -- the enhanced plasma trail comes
// through for free with no per-weapon wiring.
//
// Restored in this pass:
//   - The RAIL-BEAM ALT-FIRE. Spends 20 cells for a hitscan rail through
//     everything in line, at roughly 40x a normal bolt. This is the
//     weapon's whole identity in the source and was previously absent.
//     It is a genuinely different attack type, so it does NOT route
//     through A_RS_VP_Fire (which builds a travelling-projectile volley);
//     it uses A_RailAttack with the offhand-aware flag, the same
//     dual-wield accommodation the projectile paths already make.
//   - The venting cooldown after sustained fire, with its smoke.
//   - The full PLZR reload plus the rs_vp_plasma_cin and
//     rs_vp_plasma_beep cues -- both imported long ago, called by nothing
//     until now. The beep is the "topped up, weapon is live again" tell.
//
// DESIGN NOTE -- the beep is a prototype, not just flavour.
// It is an audible "this weapon is ready to fire again" signal, which is
// the seed of a general cadence system: every weapon eventually wanting
// some way to tell the player its next shot is available, rather than
// the player guessing from animation length. Deliberately kept local to
// this weapon for now -- one concrete instance to feel out before it
// gets generalised across the arsenal. When that system is built, this
// is the reference implementation to lift from.
// =====================================================================
class RS_VP_PlasmaRifle : RS_VP_Weapon replaces PlasmaRifle
{
	Default
	{
		Tag "Plasma Rifle";
		Weapon.SelectionOrder 100;
		Weapon.SlotNumber 6;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 30;
		Weapon.AmmoType1 "Cell";
		Weapon.AmmoType2 "RS_VP_PlasmaLoaded";
		Weapon.UpSound "rs_vp_plasma_equip";
		Inventory.PickupMessage "You got the Plasma Rifle!";
		Inventory.PickupSound "rs_vp_plasma_pickup";
		+WEAPON.NOHANDSWITCH;
	}

	// Cells spent per rail shot, and how hard the beam hits relative to a
	// single bolt. The source charged 20 cells for roughly 250-350 damage
	// against a bolt's 5 -- expressed here as a multiple of the weapon's
	// own rolled DamagePerShot so tier, Condition and GunBonsai levels all
	// reach the rail exactly like they reach ordinary fire.
	const RAIL_CELL_COST  = 20;
	const RAIL_DAMAGE_MUL = 40;

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 5;
			Accuracy      = 100;
			Velocity      = 25000;
			CritChance    = 0.0;
			Capacity      = 60;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 8 + idx);
			Accuracy      = 100;
			Velocity      = RS_Roll.RollDouble(20000, 28000);
			CritChance    = RS_Roll.RollDouble(0.0, 0.02);
			Capacity      = 60;
		}

		RateOfFire      = 11;
		ReloadSpeed     = 1.0;
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	override Class<Actor> GetHeavyProjectile()
	{
		return "RS_EnhancedPlasmaBall";
	}

	action void A_RS_VP_FirePlasma()
	{
		A_RS_FireHeavyProjectile(6);
		A_PlaySound("rs_vp_plasma_fire", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, true);
		TakeInventory(invoker.AmmoType2, 1);
		A_RS_MarkFired();
	}

	// Rail beam. Deliberately not built on A_RS_VP_Fire: that function
	// exists to spawn a travelling-projectile volley, and a rail is an
	// instantaneous line -- forcing them together would mean bending one
	// to fit the other. Condition, crit and the offhand transform are all
	// still honoured, so it behaves like the rest of the arsenal.
	action void A_RS_VP_FireRail()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_VP_Backfire();
			TakeInventory(invoker.AmmoType2, RAIL_CELL_COST);
			A_RS_MarkFired();
			return;
		}

		double dmg = invoker.DamagePerShot * dmgMult * RAIL_DAMAGE_MUL;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		int aimflags = invoker.bOffhandWeapon ? ALF_ISOFFHAND : 0;
		A_RailAttack(int(dmg), 0, false, "0F59EF", "8080FF",
			RGF_SILENT | RGF_FULLBRIGHT | RGF_NOPIERCING,
			aim: aimflags);

		A_PlaySound("rs_vp_plasma_altfire", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, true);
		TakeInventory(invoker.AmmoType2, RAIL_CELL_COST);
		A_RS_MarkFired();
	}

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_PlasmaRifle2";
	}

	States
	{
	Spawn:
		PLAS A -1;
		Stop;

	Ready:
		PLZG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		TNT1 A 0 A_PlaySound("rs_vp_plasma_holster", CHAN_AUTO);
		PLZG A 1 A_Lower;
		Loop;

	// PLCH is the short bring-up before the idle pose.
	Select:
		PLCH CBA 1 A_Raise;
		PLZG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		PLZG A 2;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FirePlasma();
		PLZG B 2;
		TNT1 A 0 A_ReFire();
		Goto Cooldown;

	// Sustained fire leaves the emitter venting. Purely a recovery beat
	// -- the weapon can't fire through it, which is the real cost of
	// holding the trigger down.
	Cooldown:
		PLZG B 1;
		PLZG C 1;
		PLZG D 1;
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG DCB 2;
		Goto Ready;

	// --- Rail beam (alt-fire) ------------------------------------------
	// Charge, then a single line through everything. Costs 20 cells, so
	// it refuses rather than half-firing on a near-empty magazine.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= RAIL_CELL_COST, "RailCharge");
		Goto Reload;

	RailCharge:
		TNT1 A 0 A_PlaySound("rs_vp_plasma_beep", CHAN_AUTO);
		PLZG JAJA 2;
		TNT1 A 0 A_PlaySound("rs_vp_plasma_charge", CHAN_AUTO);
		PLZG AAAA 1;
		PLZG AAAA 1;
		Goto RailFire;

	RailFire:
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FireRail();
		PLZG A 1;
		PLZG A 1;
		PLZG A 1;
		PLZG B 1;
		PLZG C 1;
		PLZG D 1;
		Goto RailCool;

	// Longer vent than ordinary fire -- the rail dumps a lot more heat.
	RailCool:
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG E 1 A_WeaponReady(WRF_NOBOB|WRF_NOFIRE);
		PLZG DCB 2;
		PLZG J 3;
		PLCH ABC 2;
		TNT1 A 0 A_PlaySound("rs_vp_plasma_beep", CHAN_AUTO);
		PLZG AJAJ 2 A_WeaponReady();
		PLZG A 8 A_WeaponReady();
		Goto Ready;

	// --- Reload --------------------------------------------------------
	// Cell pack out, fresh pack in, ready tone. The beep at the end is
	// the weapon telling you it's live again.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		PLZR ABJII 2;
		TNT1 A 0 A_PlaySound("rs_vp_plasma_cout", CHAN_AUTO);
		PLZR HG 1;
		TNT1 A 0 A_RS_VP_DropMag();
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		PLZR EEEEEEE 2;
		PLZR EEEEEEF 2 A_RS_ReloadAtomic();
		PLZR GH 1;
		TNT1 A 0 A_PlaySound("rs_vp_plasma_cin", CHAN_AUTO);
		PLZR I 1;
		PLZR J 3;
		PLZR M 4;
		PLZR NO 2;
		TNT1 A 0 A_PlaySound("rs_vp_plasma_beep", CHAN_AUTO);
		PLZR BA 1;
		PLZG J 6;
		PLZG A 2;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		PLZA D 1 Bright A_Light2();
		PLZA A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_PlasmaRifle2 : RS_VP_PlasmaRifle
{
	Default
	{
		Tag "Plasma Rifle (Off-Hand)";
		Weapon.SelectionOrder 99;
		Weapon.SlotNumber 6;
		Weapon.AmmoType2 "RS_VP_PlasmaLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
