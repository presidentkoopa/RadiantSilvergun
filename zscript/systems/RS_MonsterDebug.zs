// =====================================================================
// RS_MonsterDebug -- monster-only diagnostics.
// ---------------------------------------------------------------------
// REGISTRATION: this is a plain EventHandler, so it does NOT exist at
// runtime unless it is listed in MAPINFO.txt's
// GameInfo { AddEventHandlers = ... }. The previous version of this file
// was never listed there, which is why every netevent it defined did
// absolutely nothing -- no error, no output. If a command here goes
// silent again, check MAPINFO first, before reading any other code.
//
// Console commands:
//   rs_mon_line        spawn one of every family, in a row, at a tier
//   rs_mon_tier_up     every live RS monster +1 tier
//   rs_mon_tier_down   every live RS monster -1 tier
//   rs_mon_tier_set    every live RS monster -> rs_mon_dbg_tier
//   rs_mon_wake        hand every live RS monster the player as a target
//   rs_mon_diag        per-monster dump: tier, sprite index, stats, flags
//   rs_mon_audit       static check of every family's body/tint tables
//   rs_mon_clear       remove every live RS monster
// =====================================================================

class RS_MonsterDebug : EventHandler
{
	const RS_DBG_COLSTEP = 130.0;   // spacing across the row
	const RS_DBG_START   = 260.0;   // distance of the row from the player

	// Comparison chain, not a static const array -- this engine build does
	// not resolve those reliably in a class body.
	static string DbgClass(int i)
	{
		switch (i)
		{
			case 0:  return "RS_Zombieman";
			case 1:  return "RS_Shotgunner";
			case 2:  return "RS_CG_C0001";
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
			case 15: return "RS_Mastermind";
			case 16: return "RS_Cyberdemon";
			default: return "";
		}
	}

	static int DbgCount() { return 17; }

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

	// Shared by Lineup and SpawnOne -- spawn one instance of DbgClass(i) at
	// the given world position, apply tier, tag passive/hostile. Returns
	// the spawned actor (or null) so callers can report success.
	private Actor SpawnAt(PlayerPawn pmo, int i, Vector3 p, double ang, int tier)
	{
		string cls = DbgClass(i);
		Class<Actor> c = cls;
		if (!c)
		{
			Console.Printf("\cgRS: class \"%s\" does not exist.", cls);
			return null;
		}

		let a = Actor.Spawn(c, p, ALLOW_REPLACE);
		if (!a)
		{
			Console.Printf("\cgRS: %s failed to spawn (no room?).", cls);
			return null;
		}

		a.angle = ang + 180;

		let m = RS_MonsterMaster(a);
		if (m)
		{
			m.SetTier(tier, true);
			// Passive by default so it can be studied without a fight
			// breaking out. FRIENDLY rather than DORMANT: a dormant
			// monster stops ticking, which would hide the very behaviour
			// this menu exists to inspect.
			if (!GB("rs_mon_dbg_hostile", false))
			{
				m.bFRIENDLY = true;
				m.bNOTARGET = true;
			}
		}
		return a;
	}

	// -----------------------------------------------------------------
	// SPAWN A ROW -- one of every family, same tier, facing the player.
	// -----------------------------------------------------------------
	private void Lineup(PlayerPawn pmo, int tier)
	{
		int n = DbgCount();
		int spawned = 0, failed = 0;
		double ang = pmo.angle;
		Vector2 fwd  = (cos(ang), sin(ang));
		Vector2 side = (cos(ang - 90), sin(ang - 90));

		for (int i = 0; i < n; i++)
		{
			double across = (i - (n - 1) * 0.5) * RS_DBG_COLSTEP;
			Vector3 p = (pmo.pos.xy + fwd * RS_DBG_START + side * across, pmo.pos.z);
			if (SpawnAt(pmo, i, p, ang, tier)) spawned++; else failed++;
		}

		Console.Printf("\ccRS Lineup: %d spawned, %d failed, tier %02d.", spawned, failed, tier);
		Console.Printf("\ccOrder: Zombie Shotgun Chaingun Imp Demon Spectre Soul Caco Pain Baron Knight Revenant Mancubus Arach Vile Mastermind Cyber");
	}

	// -----------------------------------------------------------------
	// SPAWN ONE -- a single family, alone, directly ahead, at T00. Built
	// for VR bisection: clear, spawn one, tier it up by itself and watch
	// where it hangs, without needing the console or a full row. Always
	// T00 on spawn -- use the existing Tier Up button to walk it from
	// there, one family at a time, until the freeze is isolated to one
	// class and one tier.
	// -----------------------------------------------------------------
	private void SpawnOne(PlayerPawn pmo, int i)
	{
		double ang = pmo.angle;
		Vector2 fwd = (cos(ang), sin(ang));
		Vector3 p = (pmo.pos.xy + fwd * RS_DBG_START, pmo.pos.z);

		let a = SpawnAt(pmo, i, p, ang, 0);
		if (a)
			Console.Printf("\ccRS: spawned %s at T00.", DbgClass(i));
	}

	// -----------------------------------------------------------------
	// SPAWN A SET -- ONE family, EVERY tier it has, in a row, left to
	// right, T00 nearest the left.
	//
	// This is the verification tool rs_21 section 6 depends on. "The
	// owner walks every tier before the family is called done" is
	// fourteen spawn-and-retier cycles per family with the existing
	// buttons; here it is one button and the whole ladder is standing in
	// front of you at once, which also makes a tier that looks WRONG
	// obvious by comparison with its neighbours rather than from memory.
	//
	// Reads the family's own MaxTier() rather than assuming 12 or 13.
	// The ladder is deliberately open-ended (TierLabel GENERATES labels),
	// four families have no TEX body at all because CHP ships those
	// KX/WX files as empty stubs, and hardcoding a ceiling here has
	// already produced one wrong console report.
	// -----------------------------------------------------------------
	private void SpawnSet(PlayerPawn pmo, int i)
	{
		// Same string -> Class<Actor> idiom SpawnAt uses; it is proven here
		// and this engine build is not the place to invent a second one.
		string cls = DbgClass(i);
		Class<Actor> c = cls;
		if (!c)
		{
			Console.Printf("\cgRS Set: class \"%s\" does not exist.", cls);
			return;
		}

		// Peek the ceiling off the class DEFAULTS -- no spawn needed, and
		// it cannot be got wrong by a clamp we did not expect.
		let def = RS_MonsterMaster(GetDefaultByType(c));
		if (!def)
		{
			Console.Printf("\cgRS Set: %s is not an RS_MonsterMaster.", cls);
			return;
		}
		int top = def.MaxTier();

		int n = top + 1;
		double ang = pmo.angle;
		Vector2 fwd  = (cos(ang), sin(ang));
		Vector2 side = (cos(ang - 90), sin(ang - 90));

		int spawned = 0, failed = 0;
		for (int t = 0; t <= top; t++)
		{
			double across = (t - (n - 1) * 0.5) * RS_DBG_COLSTEP;
			Vector3 p = (pmo.pos.xy + fwd * RS_DBG_START + side * across, pmo.pos.z);
			if (SpawnAt(pmo, i, p, ang, t)) spawned++; else failed++;
		}

		Console.Printf("\ccRS Set: %s -- %d spawned, %d failed, T00 through %s.",
		               cls, spawned, failed, RS_MonsterMaster.TierLabel(top));
		Console.Printf("\ccLeft to right = lowest tier to highest. Any two that look alike are worth a second look.");
	}

	// -----------------------------------------------------------------
	// RETIER. mode 0 = set to arg, 1 = add arg.
	// -----------------------------------------------------------------
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

			int want = (mode == 1) ? m.Tier + arg : arg;
			int before = m.Tier;
			m.SetTier(want, false);
			touched++;
			// Report the label the monster ACTUALLY landed on. Clamping to
			// a hardcoded 12 here used to lie about TEX and anything above
			// it -- SetTier clamps to that family's own MaxTier(), so read
			// the result back instead of re-deriving it.
			if (touched <= 4)
				Console.Printf("\cc  %s: %s -> %s", m.GetClassName(),
				               RS_MonsterMaster.TierLabel(before),
				               RS_MonsterMaster.TierLabel(m.RS_DbgTargetTier()));
		}

		Console.Printf("\ccRS Retier: %d retiering, %d tier-locked.", touched, locked);
		if (touched == 0)
			Console.Printf("\cgNo live RS monsters found. Spawn a row first.");
	}

	// -----------------------------------------------------------------
	// WAKE -- hand every monster the player as a target. This is the test
	// for "they stand still and do nothing": if they move after this but
	// not before, the problem is target acquisition (A_Look), not the
	// state machine or the chase code.
	// -----------------------------------------------------------------
	private void WakeAll(PlayerPawn pmo)
	{
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster m;
		int woke = 0;

		while (m = RS_MonsterMaster(it.Next()))
		{
			if (m.health <= 0) continue;
			m.bFRIENDLY = false;
			m.bNOTARGET = false;
			m.bAMBUSH   = false;
			m.target    = pmo;
			m.LastHeard = pmo;
			let st = m.ResolveState("See");
			if (st) m.SetState(st);
			woke++;
		}

		Console.Printf("\ccRS Wake: %d monsters given the player as target and pushed into See.", woke);
		Console.Printf("\ccIf they move NOW but not before, target acquisition is the bug.");
	}

	// -----------------------------------------------------------------
	// PER-MONSTER DUMP. The numbers that actually tell us what is wrong:
	// sprite index (does it change with tier?), frame, stats (did
	// ApplyTier run?), velocity (are they moving?), and the flags that
	// most commonly freeze a monster.
	// -----------------------------------------------------------------
	private void Diag()
	{
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster m;
		int n = 0;

		Console.Printf("\cc--- RS MONSTER DIAG ---");
		while (m = RS_MonsterMaster(it.Next()))
		{
			n++;
			if (n > 20)
				continue;

			string body = m.RS_DbgBodyToken(m.Tier);
			string tint = m.RS_DbgTintToken(m.Tier);

			// TierLabel, not a raw %02d -- tier 13 must read "TEX", and
			// anything above it reads T14/T15 without this needing to know
			// how high the ladder currently goes.
			Console.Printf("\cw%s \cc%s  body=%s tint=%s  spr=%d frm=%d",
				m.GetClassName(), RS_MonsterMaster.TierLabel(m.Tier),
				body.Length() > 0 ? body : "(none)",
				tint.Length() > 0 ? tint : "(none)",
				int(m.sprite), int(m.frame));

			Console.Printf("\cc   hp=%d/%d spd=%.2f pain=%d dmgMul=%.2f vel=%.2f",
				m.health, m.TierMaxHealth, m.Speed, m.PainChance,
				m.TierDamageMul, m.vel.Length());

			string flags = "";
			if (m.bFRIENDLY)  flags = flags .. "FRIENDLY ";
			if (m.bNOTARGET)  flags = flags .. "NOTARGET ";
			if (m.bAMBUSH)    flags = flags .. "AMBUSH ";
			if (m.bDORMANT)   flags = flags .. "DORMANT ";
			if (m.bCORPSE)    flags = flags .. "CORPSE ";
			if (!m.bSHOOTABLE) flags = flags .. "!SHOOTABLE ";
			if (!m.bSOLID)    flags = flags .. "!SOLID ";
			if (m.bNOSECTOR)  flags = flags .. "NOSECTOR ";

			Console.Printf("\cc   target=%s  flags=%s",
				m.target ? m.target.GetClassName() .. "" : "(none)",
				flags.Length() > 0 ? flags : "(clean)");
		}

		if (n > 20)
			Console.Printf("\cc... and %d more (showing first 20).", n - 20);
		Console.Printf("\ccTotal live RS monsters: %d", n);
		if (n == 0)
			Console.Printf("\cgNone found. Either nothing spawned, or the classes are not RS_MonsterMaster.");
	}

	// -----------------------------------------------------------------
	// STATIC TABLE AUDIT. Reads every family's BodyTable()/TintTable()
	// off the class defaults -- no spawning required. Catches the data
	// errors that silently produce an invisible or unchanged monster:
	// wrong number of entries, tokens that are not 4 characters, and
	// tiers that fall off the end of a short table.
	// -----------------------------------------------------------------
	private void Audit()
	{
		Console.Printf("\cc--- RS MONSTER TABLE AUDIT ---");
		int problems = 0;

		for (int i = 0; i < DbgCount(); i++)
		{
			string cls = DbgClass(i);
			Class<Actor> c = cls;
			if (!c)
			{
				Console.Printf("\cgMISSING CLASS: %s", cls);
				problems++;
				continue;
			}

			let def = RS_MonsterMaster(GetDefaultByType(c));
			if (!def)
			{
				Console.Printf("\cg%s is not an RS_MonsterMaster.", cls);
				problems++;
				continue;
			}

			Array<string> bodies, tints;
			string b = def.BodyTable();
			string t = def.TintTable();
			if (b.Length() > 0) b.Split(bodies, " ");
			if (t.Length() > 0) t.Split(tints, " ");

			string issues = "";
			if (bodies.Size() != 13)
				issues = issues .. String.Format("body has %d entries (want 13); ", bodies.Size());
			if (tints.Size() != 13)
				issues = issues .. String.Format("tint has %d entries (want 13); ", tints.Size());

			for (int k = 0; k < bodies.Size(); k++)
				if (bodies[k].Length() != 4)
					issues = issues .. String.Format("body[%d]=\"%s\" not 4 chars; ", k, bodies[k]);

			if (issues.Length() > 0)
			{
				Console.Printf("\cg%-18s %s", cls, issues);
				problems++;
			}
			else
			{
				Console.Printf("\cc%-18s ok  %s", cls, b);
			}
		}

		// STATE CLUSTER AUDIT -- the rebuilt body system's real check.
		// Walks LIVE monsters (spawn a row first) and asks each class
		// which per-tier clusters it is missing where its BodyTable says
		// the body differs from T00's. A clean rebuild prints nothing
		// here; anything listed would show the WRONG BODY at that tier.
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster m;
		int audited = 0;
		Array<string> seen;
		while (m = RS_MonsterMaster(it.Next()))
		{
			string cn = m.GetClassName() .. "";
			bool dup = false;
			for (int k = 0; k < seen.Size(); k++)
				if (seen[k] == cn) { dup = true; break; }
			if (dup) continue;
			seen.Push(cn);
			audited++;

			string miss = m.RS_AuditClusters();
			if (miss.Length() > 0)
			{
				Console.Printf("\cg%-18s missing clusters: %s", cn, miss);
				problems++;
			}
		}
		if (audited == 0)
			Console.Printf("\ccCluster audit skipped: no live RS monsters. Spawn a row, then AUDIT again.");

		Console.Printf("\cc--- audit done: %d problems ---", problems);
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
		Console.Printf("\ccRS: removed %d monsters.", n);
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		let plr = players[e.Player];
		if (!plr || !plr.mo)
			return;
		let pmo = PlayerPawn(plr.mo);
		if (!pmo)
			return;

		if (e.Name ~== "rs_mon_line")
			Lineup(pmo, GI("rs_mon_dbg_tier", 0));
		// ONE event, family index in Args[0] -- `netevent rs_mon_set 3`.
		// The spawn-one events below are one-per-family and predate this;
		// they are left alone rather than rewritten, but do NOT add
		// seventeen more lines here for the set buttons. MENUDEF passes
		// the index.
		else if (e.Name ~== "rs_mon_set")
			SpawnSet(pmo, clamp(e.Args[0], 0, DbgCount() - 1));
		else if (e.Name ~== "rs_mon_spawn_zombieman")
			SpawnOne(pmo, 0);
		else if (e.Name ~== "rs_mon_spawn_shotgunner")
			SpawnOne(pmo, 1);
		else if (e.Name ~== "rs_mon_spawn_chaingunner")
			SpawnOne(pmo, 2);
		else if (e.Name ~== "rs_mon_spawn_imp")
			SpawnOne(pmo, 3);
		else if (e.Name ~== "rs_mon_spawn_demon")
			SpawnOne(pmo, 4);
		else if (e.Name ~== "rs_mon_spawn_spectre")
			SpawnOne(pmo, 5);
		else if (e.Name ~== "rs_mon_spawn_lostsoul")
			SpawnOne(pmo, 6);
		else if (e.Name ~== "rs_mon_spawn_cacodemon")
			SpawnOne(pmo, 7);
		else if (e.Name ~== "rs_mon_spawn_painelemental")
			SpawnOne(pmo, 8);
		else if (e.Name ~== "rs_mon_spawn_baron")
			SpawnOne(pmo, 9);
		else if (e.Name ~== "rs_mon_spawn_hellknight")
			SpawnOne(pmo, 10);
		else if (e.Name ~== "rs_mon_spawn_revenant")
			SpawnOne(pmo, 11);
		else if (e.Name ~== "rs_mon_spawn_mancubus")
			SpawnOne(pmo, 12);
		else if (e.Name ~== "rs_mon_spawn_arachnotron")
			SpawnOne(pmo, 13);
		else if (e.Name ~== "rs_mon_spawn_archvile")
			SpawnOne(pmo, 14);
		else if (e.Name ~== "rs_mon_spawn_mastermind")
			SpawnOne(pmo, 15);
		else if (e.Name ~== "rs_mon_spawn_cyberdemon")
			SpawnOne(pmo, 16);
		else if (e.Name ~== "rs_mon_tier_up")
			Retier(1, 1);
		else if (e.Name ~== "rs_mon_tier_down")
			Retier(1, -1);
		else if (e.Name ~== "rs_mon_tier_set")
			Retier(0, GI("rs_mon_dbg_tier", 0));
		else if (e.Name ~== "rs_mon_wake")
			WakeAll(pmo);
		else if (e.Name ~== "rs_mon_diag")
			Diag();
		else if (e.Name ~== "rs_mon_audit")
			Audit();
		else if (e.Name ~== "rs_mon_clear")
			ClearMonsters();
	}
}
