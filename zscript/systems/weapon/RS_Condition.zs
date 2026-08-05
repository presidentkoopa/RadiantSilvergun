// =====================================================================
// RS_Condition -- wires weapon Condition degradation into play.
// ---------------------------------------------------------------------
// RS_Weapon.OnPlayerDamaged and RS_Roll.DegradeCondition existed with
// zero callers, so Condition never moved after the creation roll: guns
// never wore, Grey Bits had nothing to repair, and the sub-50 gamble
// band was unreachable content. This file is the missing caller.
//
// Two paths, both landing on the currently equipped pair (mainhand +
// offhand -- the hit landed on the player, not on a specific gun):
//
//   1. DAMAGE: every hit the player takes routes to
//      RS_Weapon.OnPlayerDamaged on both hands. The threshold/loss
//      math stays in RS_Roll.DegradeCondition (a hit of 20+ costs 3
//      Condition) -- this file adds no numbers of its own.
//   2. HAZARD FLOORS: standing on a damaging floor grinds Condition
//      continuously (rs_condition_hazard_rate, points per second). A
//      radsuit (PowerIronFeet) shields the guns by the
//      rs_condition_hazard_suited multiplier -- 0 full protection,
//      0.25 default (dampens, doesn't seal), 1 no protection. Owner
//      rulings 2026-08-05: "def when standing in a hazard" and the
//      follow-up "or even if radsuit?" -> resolved as this dial.
//
// RS_ConditionHandler must ALSO be in MAPINFO.txt's AddEventHandlers --
// a handler not listed there never runs.
// =====================================================================

class RS_ConditionHandler : EventHandler
{
	override void WorldThingDamaged(WorldEvent e)
	{
		if (!e.Thing || !(e.Thing is "PlayerPawn") || e.Damage <= 0)
			return;
		if (!CVar.FindCVar("rs_condition_degrade").GetBool())
			return;

		let plr = PlayerPawn(e.Thing).player;
		if (!plr)
			return;

		let mh = RS_Weapon(plr.ReadyWeapon);
		if (mh)
			mh.OnPlayerDamaged(e.Damage);
		let oh = RS_Weapon(plr.OffhandWeapon);
		if (oh && oh != mh)
			oh.OnPlayerDamaged(e.Damage);
	}

	override void WorldTick()
	{
		if (!CVar.FindCVar("rs_condition_degrade").GetBool())
			return;

		double rate = CVar.FindCVar("rs_condition_hazard_rate").GetFloat();
		if (rate <= 0)
			return;

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;
			let mo = players[i].mo;
			if (!mo || mo.health <= 0)
				continue;
			// The radsuit seals the PLAYER; how much it shields the guns
			// is a dial. 0 = suited guns never wear, 1 = the suit never
			// cared about your guns. Default 0.25: it dampens, it doesn't
			// seal -- a long soak still costs.
			double effRate = rate;
			if (mo.FindInventory("PowerIronFeet"))
			{
				effRate *= CVar.FindCVar("rs_condition_hazard_suited").GetFloat();
				if (effRate <= 0)
					continue;
			}
			let sec = mo.curSector;
			if (!sec || sec.damageamount <= 0)
				continue;
			// Grounded exposure only -- floating above nukage costs
			// nothing, same rule the sector's own damage follows.
			if (mo.pos.z > mo.floorz)
				continue;

			double amount = effRate / GameTicRate;
			let mh = RS_Weapon(players[i].ReadyWeapon);
			if (mh)
				mh.Condition = max(0.0, mh.Condition - amount);
			let oh = RS_Weapon(players[i].OffhandWeapon);
			if (oh && oh != mh)
				oh.Condition = max(0.0, oh.Condition - amount);
		}
	}
}
