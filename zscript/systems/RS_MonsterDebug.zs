// =====================================================================
// RS_MonsterDebug -- spawn and inspect the CH chaingunner.
// ---------------------------------------------------------------------
// REWRITTEN 2026-08-05, down from ~500 lines.
//
// The old one knew about all seventeen CHP families, a tier slider, a
// "one of every family" row, sprite-table audits and a body/tint dumper.
// Every one of those referred to something that no longer loads: the CHP
// families are quarantined and unloaded, and the per-tier sprite/tint
// tables belong to the ladder that CH-rebuilt creatures do not have.
//
// ONE FAMILY IS PORTED FROM CH. This spawns that family and nothing
// else. It grows again when family 05 lands.
//
// REGISTRATION: this is a plain EventHandler, so it does NOT exist at
// runtime unless it is listed in MAPINFO.txt's
// GameInfo { AddEventHandlers = ... }. An earlier version was never
// listed there and every command it defined silently did nothing -- no
// error, no output. If a button here goes dead, check MAPINFO FIRST.
//
// Console commands:
//   netevent rs_cg_spawn <0-13>   spawn one, by index
//   netevent rs_cg_line           spawn all fourteen
//   netevent rs_cg_diag           dump what is alive and what it really is
//   netevent rs_cg_wake           make them hostile and target the player
//   netevent rs_cg_clear          remove them all
// =====================================================================

class RS_MonsterDebug : EventHandler
{
	// The fourteen, in CH's own spawn-table order: commonest first, then
	// the optional band, then the bosses, then the EX. The menu lists
	// them in this order too, so the menu and the console agree.
	const RS_CG_COUNT = 14;

	// Comparison chain, not a static const array -- this engine build
	// does not resolve those reliably in a class body.
	static string CGClass(int i)
	{
		switch (i)
		{
			case 0:  return "RS_CG_C0001";
			case 1:  return "RS_CG_T0001";
			case 2:  return "RS_CG_T0002";
			case 3:  return "RS_CG_T0004";
			case 4:  return "RS_CG_T0005";
			case 5:  return "RS_CG_T0010";
			case 6:  return "RS_CG_T0003";
			case 7:  return "RS_CG_T0007";
			case 8:  return "RS_CG_T0006";
			case 9:  return "RS_CG_T0008";
			case 10: return "RS_CG_T0009";
			case 11: return "RS_CG_B0001";
			case 12: return "RS_CG_B0002";
			case 13: return "RS_CG_X0001";
		}
		return "";
	}

	// CH's own names, for the console readout. Nothing invented -- every
	// one of these is a Tag or an obituary in Chaingunners.txt.
	static string CGName(int i)
	{
		switch (i)
		{
			case 0:  return "Former Captain";
			case 1:  return "Green Chaingunner";
			case 2:  return "Blue Chaingunner";
			case 3:  return "Purple Chaingunner";
			case 4:  return "Yellow Chaingunner";
			case 5:  return "Red Chaingunner";
			case 6:  return "Jetpack Larry";
			case 7:  return "Gray Chaingunner";
			case 8:  return "Brown Chaingunner";
			case 9:  return "Abyss Chaingunner";
			case 10: return "Fireblu Chaingunner";
			case 11: return "The General";
			case 12: return "The crazy lady scientist";
			case 13: return "Black ChainGunner EX";
		}
		return "";
	}

	private static bool GB(string name, bool def)
	{
		let cv = CVar.FindCVar(name);
		return cv ? cv.GetBool() : def;
	}

	// Spawn one in front of the player, scattered so repeated spawns do
	// not stack inside each other.
	private Actor SpawnOne(PlayerPawn pmo, int i)
	{
		string cls = CGClass(i);
		Class<Actor> c = cls;
		if (!c)
		{
			Console.Printf("\cgRS: \"%s\" does not exist.", cls);
			return null;
		}

		double ang = pmo.angle;
		Vector3 p = pmo.Vec3Offset(cos(ang) * 160, sin(ang) * 160, 0);

		// Uniform over a disc -- sqrt of the roll. A flat random radius
		// bunches everything at the centre, which is the stacking this
		// is meant to avoid.
		for (int n = 0; n < 16; n++)
		{
			double a = frandom(0, 360);
			double d = sqrt(frandom(0, 1)) * 96;
			Vector3 q = (p.x + cos(a) * d, p.y + sin(a) * d, p.z);
			if (Level.IsPointInLevel(q)) { p = q; break; }
		}

		let a = Actor.Spawn(c, p, ALLOW_REPLACE);
		if (!a)
		{
			Console.Printf("\cgRS: %s failed to spawn (no room?).", cls);
			return null;
		}
		a.angle = ang + 180;

		// Passive by default so it can be watched without a fight
		// starting. FRIENDLY, not DORMANT: a dormant monster stops
		// ticking, which hides the behaviour this exists to show.
		if (!GB("rs_mon_dbg_hostile", false))
			a.bFRIENDLY = true;

		return a;
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (!players[consoleplayer].mo) return;
		let pmo = PlayerPawn(players[consoleplayer].mo);
		if (!pmo) return;

		if (e.Name ~== "rs_cg_spawn")
		{
			int i = clamp(e.Args[0], 0, RS_CG_COUNT - 1);
			let a = SpawnOne(pmo, i);
			if (a)
				Console.Printf("\ccRS: %s  (%s)  hp %d",
				               CGName(i), CGClass(i), a.health);
			return;
		}

		if (e.Name ~== "rs_cg_line")
		{
			int made = 0;
			for (int i = 0; i < RS_CG_COUNT; i++)
				if (SpawnOne(pmo, i)) made++;
			Console.Printf("\ccRS: spawned %d of %d.", made, RS_CG_COUNT);
			return;
		}

		// What is actually alive and what it really is -- read off the
		// live actor, never off a table. A table can agree with itself
		// while the game disagrees with both.
		if (e.Name ~== "rs_cg_diag")
		{
			int n = 0;
			ThinkerIterator it = ThinkerIterator.Create("RS_Chaingunner");
			Actor a;
			while (a = Actor(it.Next()))
			{
				Console.Printf("\cc%-13s\cw hp %5d/%-5d spd %4.1f pain %3d %s%s",
				               a.GetClassName(), a.health, a.SpawnHealth(),
				               a.Speed, a.PainChance,
				               a.bFRIENDLY ? "friendly " : "hostile ",
				               a.target ? "TARGETING" : "");
				n++;
			}
			Console.Printf("\ccRS: %d chaingunner(s) alive.", n);
			return;
		}

		if (e.Name ~== "rs_cg_wake")
		{
			int n = 0;
			ThinkerIterator it = ThinkerIterator.Create("RS_Chaingunner");
			Actor a;
			while (a = Actor(it.Next()))
			{
				a.bFRIENDLY = false;
				a.target = pmo;
				if (a.SeeState) a.SetState(a.SeeState);
				n++;
			}
			Console.Printf("\ccRS: woke %d.", n);
			return;
		}

		if (e.Name ~== "rs_cg_clear")
		{
			int n = 0;
			ThinkerIterator it = ThinkerIterator.Create("RS_Chaingunner");
			Actor a;
			while (a = Actor(it.Next())) { a.Destroy(); n++; }
			Console.Printf("\ccRS: removed %d.", n);
			return;
		}
	}
}
