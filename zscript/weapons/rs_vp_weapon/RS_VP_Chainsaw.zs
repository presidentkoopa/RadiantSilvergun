// RS_VP_Chainsaw -- "Chainsaw", a brand-new weapon type for this project.
// ---------------------------------------------------------------------
// Real data: sustained melee, sprites SAWN (ready) / SAWG+SAWR (rev) /
// SAWF (cutting) / CSAW Z (world pickup). Sounds are the source's own
// chainsaw set -- start / idle / loop / stop / zip / off / hit / wall.
//
// No ammo, no projectile, no casings. Gets RS_HiFiFX smoke on sustained
// contact (the one melee weapon where barrel-smoke-style FX genuinely
// makes sense) but no CasingEject and no ProjectileClass.
//
// Restored in this pass:
//   - The MOTOR. This saw is either running or it isn't, and that state
//     persists: pulling the trigger on a dead saw rips the cord (SAWR)
//     and starts the engine rather than cutting, and it keeps idling
//     afterward. Previously it had no motor at all -- every swing was a
//     silent instant hit with no spin-up and no idle.
//   - AltFire kills the engine (the source's TurnOff). This is a real
//     mechanical choice, not a stance toggle: a running saw is loud and
//     wakes monsters, a dead one doesn't. Included on that basis, unlike
//     the ADS toggles which were excluded as flat-screen aiming aids.
//   - The SAWF cutting loop with its own sustained sound, and the wall
//     -vs-flesh hit distinction.
// =====================================================================
class RS_VP_Chainsaw : RS_VP_Weapon replaces Chainsaw
{
	Default
	{
		Tag "Chainsaw";
		Weapon.SelectionOrder 2200;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		Weapon.UpSound "rs_vp_saw_equip";
		Inventory.PickupMessage "A Chainsaw! Find some meat!";
		Inventory.PickupSound "rs_vp_saw_get";
		+WEAPON.MELEEWEAPON
		+WEAPON.NOAUTOFIRE
		+WEAPON.NOHANDSWITCH
		Obituary "$OB_MPCHAINSAW";
	}

	// Whether the motor is currently running. Persists across Ready, so a
	// saw left idling stays idling until it's switched off or holstered.
	// The source tracked this with a "SawOn" inventory token; ZScript has
	// a real field for it.
	bool bMotorRunning;

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

	// A_Saw handles the wall-vs-flesh distinction itself: the hit sound
	// fires on meat, the wall puff spawns on geometry.
	action void A_RS_VP_Saw()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		double dmg = invoker.DamagePerShot * dmgMult;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		A_Saw("", "rs_vp_saw_flesh", int(dmg), "RS_ChainsawPuff");
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

	// Two idles: a dead saw just sits there, a running one shakes and
	// smokes and makes noise.
	Ready:
		TNT1 A 0 A_JumpIf(invoker.bMotorRunning, "ReadyRunning");
		SAWN A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	ReadyRunning:
		TNT1 A 0 A_JumpIf(!invoker.bMotorRunning, "Ready");
		TNT1 A 0 A_PlaySound("rs_vp_saw_idle", CHAN_WEAPON, 1.0, true);
		SAWN A 4 A_WeaponReady();
		SAWN A 4 A_WeaponReady();
		SAWN Z 4 A_WeaponReady();
		SAWN Z 4 A_WeaponReady();
		Goto ReadyRunning;

	// Holstering always kills the motor -- you don't walk around with a
	// running saw on your back.
	Deselect:
		TNT1 A 0 A_StopSound(CHAN_WEAPON);
		TNT1 A 0 { invoker.bMotorRunning = false; }
		TNT1 A 0 A_PlaySound("rs_vp_saw_low", CHAN_AUTO);
		SAWN A 1 A_Lower;
		Loop;

	Select:
		SAWN A 1 A_Raise;
		Loop;

	// Trigger on a dead saw starts it; trigger on a running saw cuts.
	Fire:
		TNT1 A 0 A_JumpIf(invoker.bMotorRunning, "Cut");
		Goto Rev;

	// Rip the cord. Loud enough to wake things, which is the cost of
	// starting it in the first place.
	Rev:
		TNT1 A 0 { invoker.bMotorRunning = true; }
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		SAWG A 2;
		SAWR A 6;
		TNT1 A 0 A_PlaySound("rs_vp_saw_zip", CHAN_AUTO);
		SAWR BCDE 1;
		TNT1 A 0 A_PlaySound("rs_vp_saw_start", CHAN_WEAPON);
		TNT1 A 0 A_AlertMonsters();
		SAWR F 3;
		SAWR EDCBA 1;
		SAWG A 1;
		TNT1 A 0 A_ReFire("Cut");
		Goto ReadyRunning;

	Cut:
		TNT1 A 0 A_StopSound(CHAN_WEAPON);
		TNT1 A 0 A_PlaySound("rs_vp_saw_start", CHAN_WEAPON);
		SAWN B 1;
		SAWN C 1;
		SAWN D 1;
		SAWN E 1;
		SAWN F 1;
		SAWN G 1;
		TNT1 A 0 A_AlertMonsters();

	Hold:
		TNT1 A 0 A_PlaySound("rs_vp_saw_loop", CHAN_WEAPON, 1.0, true);
		SAWF A 1;
		TNT1 A 0 A_RS_VP_Saw();
		SAWF B 1;
		SAWF A 1;
		SAWF B 1;
		TNT1 A 0 A_ReFire("Hold");
		TNT1 A 0 A_StopSound(CHAN_WEAPON);
		TNT1 A 0 A_PlaySound("rs_vp_saw_stop", CHAN_AUTO);
		SAWN G 1 A_WeaponReady();
		SAWN F 1 A_WeaponReady();
		SAWN E 1 A_WeaponReady();
		SAWN D 1 A_WeaponReady();
		SAWN B 1 A_WeaponReady();
		Goto ReadyRunning;

	// --- Kill the engine (alt-fire) ------------------------------------
	// A dead saw is quiet. Doing this on an already-dead saw is a no-op
	// rather than an error.
	AltFire:
		TNT1 A 0 A_JumpIf(invoker.bMotorRunning, "TurnOff");
		Goto Ready;

	TurnOff:
		TNT1 A 0 { invoker.bMotorRunning = false; }
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		SAWG A 2;
		SAWR A 2;
		SAWR A 1;
		SAWR A 1;
		SAWR A 1;
		SAWR A 1;
		TNT1 A 0 A_PlaySound("rs_vp_saw_off", CHAN_AUTO);
		SAWR A 3;
		SAWG A 1;
		TNT1 A 0 A_StopSound(CHAN_WEAPON);
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
