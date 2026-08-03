// =====================================================================
// RS_MonsterDebug -- the "let me actually look at this" handler.
// ---------------------------------------------------------------------
// Two jobs:
//
//   1. LINE UP THE ZOO. Spawn a grid in front of the player -- one row
//      per family, one column per tier -- so every body and every
//      colour is visible side by side at once. This is the only
//      practical way to check thirteen tiers times fifteen families
//      without playing for an hour.
//
//   2. RETIER ON DEMAND. Push every live monster to a chosen tier and
//      watch the stats and colours move. Retiers go through
//      SetTier(t, false), so they use the staggered transform -- the
//      room does NOT snap in one frame, each monster picks its own
//      short delay and glows while it waits.
//
// Console commands (bind or type):
//   rs_mon_line            ONE ROW -- one of every family, same tier.
//                          The view for watching retiers: spawn the
//                          row, then tier up/down and watch the stagger
//                          ripple down the line.
//   rs_mon_attack          every live monster faces you and attacks NOW
//   rs_mon_zoo             grid of every family x every tier
//   rs_mon_zoo_family      grid of ONE family x every tier (see cvar)
//   rs_mon_tier_up         every live monster +1 tier
//   rs_mon_tier_down       every live monster -1 tier
//   rs_mon_tier_set        every live monster -> rs_debug_mon_tier
//   rs_mon_tier_roll       every live monster -> its own random tier
//   rs_mon_clear           remove every live RS monster
// =====================================================================

class RS_MonsterDebug : EventHandler
{
	// Spacing between spawned monsters. Generous -- Arachnotron and
	// Mancubus are wide, and an overlapping grid is unreadable.
	const RS_ZOO_COLSTEP = 130.0;   // between tiers (across)
	const RS_ZOO_ROWSTEP = 150.0;   // between families (away from player)
	const RS_ZOO_START   = 260.0;   // distance of the first row

	// The roster. Comparison chain rather than a static const array --
	// this engine build doesn't resolve those reliably in a class body.
	static string ZooClass(int i)
	{
		switch (i)
		{
			case 0:  return "RS_Zombieman";
			case 1:  return "RS_Shotgunner";
			case 2:  return "RS_Chaingunner";
			case 3:  return "RS_Imp";
			case 4:  return "RS_Demon";
			case 5:  return "RS_Spectre";
			case 6:  return "RS_LostSoul";
			case 7:  return "RS_Cacodemon";
			case 8:  return "RS_PainElemental";
			case 9:  return "RS_Baron";
			case 10: return "RS_HellKnight";
			case 11: return "RS_Revenant";
			case 12: return "RS_Mancubus";
			case 13: return "RS_Arachnotron";
			case 14: return "RS_Archvile";
			default: return "";
		}
	}

	static int ZooCount() { return 15; }

	// -----------------------------------------------------------------
	// SPAWN
	// -----------------------------------------------------------------

	// Spawns one monster of `cls` at tier `t`, laid out at grid slot
	// (col, row) relative to the player's facing. Returns false if the
	// class doesn't exist or there was no room.
	private bool SpawnAt(PlayerPawn pmo, string cls, int t, int col, int row, int cols)
	{
		Class<Actor> c = cls;
		if (!c)
			return false;

		// Centre the row on the player's view line, then push it out.
		double across = (col - (cols - 1) * 0.5) * RS_ZOO_COLSTEP;
		double outDist = RS_ZOO_START + row * RS_ZOO_ROWSTEP;

		double ang = pmo.angle;
		Vector2 fwd  = (cos(ang), sin(ang));
		Vector2 side = (cos(ang - 90), sin(ang - 90));
		Vector3 p = (pmo.pos.xy + fwd * outDist + side * across, pmo.pos.z);

		// NOCHECKPOSITION on purpose: a debug grid that silently drops
		// half its rows because something clipped a wall is worse than
		// one that overlaps geometry. We want to SEE all of them.
		let a = Actor.Spawn(c, p, ALLOW_REPLACE);
		if (!a)
			return false;

		a.angle = ang + 180;   // face the player

		let m = RS_MonsterMaster(a);
		if (m)
		{
			// instant = true: no stagger, no flash. The zoo should be
			// standing at its tiers the moment it appears.
			m.SetTier(t, true);

			// Two review modes, because they want opposite things:
			//
			//   PASSIVE (default) -- they hold the line and don't come
			//     at you, so you can study bodies and watch retiers.
			//     FRIENDLY rather than DORMANT deliberately: a dormant
			//     monster is asleep, and that risks suppressing the very
			//     transform you're trying to watch. Friendly monsters
			//     tick and animate normally.
			//
			//   HOSTILE -- normal monsters that shoot back, for
			//     reviewing what each tier's attack actually looks like.
			//     Turn god mode on first.
			if (!GB("rs_debug_mon_hostile", false))
			{
				m.bFRIENDLY = true;
				m.bNOTARGET = true;
			}
		}
		return true;
	}

	// -----------------------------------------------------------------
	// FIRE ON COMMAND.
	// Point every live RS monster at the player and push it straight
	// into its attack state. Waiting for fifteen monsters to notice you
	// one at a time is a bad way to review attacks -- this makes the
	// whole row fire at once, on demand, as many times as you want.
	//
	// Works on passive monsters too: it hands them a target directly
	// rather than relying on them deciding to acquire one.
	// -----------------------------------------------------------------
	private void FireAll(PlayerPawn pmo)
	{
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster m;
		int fired = 0, noattack = 0;

		while (m = RS_MonsterMaster(it.Next()))
		{
			if (m.health <= 0) continue;

			m.target = pmo;
			m.A_FaceTarget();

			// Prefer the ranged attack; fall back to melee for the
			// monsters that only have one (Demon, Spectre, tendrils).
			State st = m.ResolveState("Missile");
			if (!st) st = m.ResolveState("Melee");

			if (st)
			{
				m.SetState(st);
				fired++;
			}
			else noattack++;
		}

		if (noattack > 0)
			Console.Printf("RS Fire: %d firing, %d have no attack state.", fired, noattack);
		else
			Console.Printf("RS Fire: %d monsters firing.", fired);
	}

	// -----------------------------------------------------------------
	// THE LINEUP -- one of every family, shoulder to shoulder, all at
	// the same tier. This is the view for watching a retier sweep: hit
	// tier up/down and the whole row transforms, each monster picking
	// its own short delay, so the stagger is visible as a ripple down
	// the line rather than a single snap.
	// -----------------------------------------------------------------
	private void Lineup(PlayerPawn pmo, int tier)
	{
		int n = ZooCount();
		int spawned = 0;

		for (int i = 0; i < n; i++)
		{
			// Row 0 for everything -- a single line, not a grid.
			if (SpawnAt(pmo, ZooClass(i), tier, i, 0, n))
				spawned++;
		}

		Console.Printf("RS Lineup: %d monsters at tier %02d, left to right: "
		               "Zombieman Shotgunner Chaingunner Imp Demon Spectre LostSoul "
		               "Caco PainElem Baron HellKnight Revenant Mancubus Arachnotron Archvile.",
		               spawned, tier);
	}

	private void Zoo(PlayerPawn pmo, int onlyFamily = -1)
	{
		int lo = 0, hi = ZooCount() - 1;
		if (onlyFamily >= 0 && onlyFamily < ZooCount())
		{
			lo = onlyFamily;
			hi = onlyFamily;
		}

		int spawned = 0, failed = 0;
		int row = 0;

		for (int f = lo; f <= hi; f++)
		{
			string cls = ZooClass(f);
			for (int t = 0; t <= 12; t++)
			{
				if (SpawnAt(pmo, cls, t, t, row, 13)) spawned++;
				else failed++;
			}
			row++;
		}

		Console.Printf("RS Monster Zoo: %d spawned, %d failed. "
		               "Columns are tiers 00-12 left to right; rows are families.",
		               spawned, failed);
	}

	// -----------------------------------------------------------------
	// RETIER
	// -----------------------------------------------------------------
	//
	// mode: 0 = set to `arg`, 1 = +arg, 2 = random per monster.
	private void Retier(int mode, int arg)
	{
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster m;
		int touched = 0, locked = 0;

		while (m = RS_MonsterMaster(it.Next()))
		{
			if (m.health <= 0)
				continue;
			if (m.TierLocked())
			{
				locked++;
				continue;
			}

			int want;
			if (mode == 1)      want = m.Tier + arg;
			else if (mode == 2) want = random(0, 12);
			else                want = arg;

			// instant = false -- this is the whole point. Each monster
			// picks its own short delay and glows while it waits, so a
			// roomful transforms as a ripple, not a single frame snap.
			m.SetTier(want, false);
			touched++;
		}

		if (locked > 0)
			Console.Printf("RS Retier: %d monsters retiering, %d tier-locked (skipped).", touched, locked);
		else
			Console.Printf("RS Retier: %d monsters retiering.", touched);
	}

	private void ClearMonsters()
	{
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster m;
		int n = 0;
		while (m = RS_MonsterMaster(it.Next()))
		{
			m.Destroy();
			n++;
		}
		Console.Printf("RS Monster Zoo: removed %d.", n);
	}

	// -----------------------------------------------------------------

	private static int GI(string name, int def)
	{
		let cv = CVar.FindCVar(name);
		return cv ? cv.GetInt() : def;
	}

	private static bool GB(string name, bool def)
	{
		let cv = CVar.FindCVar(name);
		return cv ? cv.GetBool() : def;
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		let plr = players[e.Player];
		if (!plr || !plr.mo)
			return;
		let pmo = PlayerPawn(plr.mo);
		if (!pmo)
			return;

		if (e.Name ~== "rs_mon_attack")
			FireAll(pmo);
		else if (e.Name ~== "rs_mon_line")
			Lineup(pmo, GI("rs_debug_mon_tier", 0));
		else if (e.Name ~== "rs_mon_zoo")
			Zoo(pmo);
		else if (e.Name ~== "rs_mon_zoo_family")
			Zoo(pmo, GI("rs_debug_mon_family", 0));
		else if (e.Name ~== "rs_mon_tier_set")
			Retier(0, GI("rs_debug_mon_tier", 0));
		else if (e.Name ~== "rs_mon_tier_up")
			Retier(1, 1);
		else if (e.Name ~== "rs_mon_tier_down")
			Retier(1, -1);
		else if (e.Name ~== "rs_mon_tier_roll")
			Retier(2, 0);
		else if (e.Name ~== "rs_mon_clear")
			ClearMonsters();
	}
}
