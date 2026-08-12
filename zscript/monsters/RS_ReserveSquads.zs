// ============================================================================
// RS_ReserveSquads.zs -- the reinforcement director.
//
// WHAT IT IS
//   A director that sends small squads of monsters into a map that is already
//   running. It decides WHEN (a timer, an elite reveal, or a direct call),
//   WHERE (a spawn marker recycled from the map's own monster placement) and
//   WHAT (a roster), then telegraphs the arrival and spawns the group.
//
//   It is as much an API as a feature. SetPiece (and anything else) can hand
//   it explicit classes and a tier band and fire a wave on demand -- see the
//   PUBLIC API block at the bottom of RS_ReserveSquads.
//
// IT SHIPS OFF.
//   rs_reserve_enabled defaults to 0. Nothing fires on its own until a player
//   turns it on or something calls Deploy(). The debug netevents below fire a
//   wave regardless of the master switch, so the machine can be felt before
//   anything is decided about what should trigger it.
//
// NO BOONS. THIS SYSTEM SPAWNS MONSTERS AND NOTHING ELSE.
//   Every event it produces is a threat. It never spawns an item, a pickup,
//   ammo or a powerup -- item generation belongs to Kill Rewards
//   (zscript/systems/ui/RS_Bits.zs) and is not duplicated here. The only
//   non-monster actors this file spawns are its own telegraph beacon and the
//   engine's TeleportFog.
//
// THE PLACEMENT TECHNIQUE (the point of the whole thing)
//   At map start every non-boss, kill-counting monster on the map is walked
//   and its position, facing and class are recorded as a reusable marker.
//   That buys two things for free:
//     * spawn spots a level designer already approved -- reachable, correctly
//       sized, not buried in geometry, on a floor that connects to the map
//     * a roster built out of the map's own bestiary
//   Firing = filter the markers to a distance band around a player, pick
//   some, and put a squad on each.
//
//   A MARKER IS NOT A GUARANTEE. The monster that arrives may be bigger than
//   the one the marker was taken from, the geometry may have moved, and squad
//   members scatter off the marker. So every body is validated before it is
//   kept: a line trace clamps the scatter out of walls, the body is snapped
//   to the floor, and TestMobjLocation plus an explicit headroom check decide
//   whether it stays. A body that does not fit is destroyed -- and
//   ClearCounters() is called FIRST, so a rejected spawn cannot inflate the
//   map's kill total and break a 100% clear.
//
//   Reinforcements that DO place are ordinary countable monsters: they raise
//   the map's monster total and must be killed for a full clear. That is
//   deliberate -- they are real monsters, not decorations.
//
// WIRING (all three or it does not exist):
//   zscript.txt  -- #include "zscript/monsters/RS_ReserveSquads.zs"
//   MAPINFO.txt  -- "RS_ReserveSquads" in GameInfo's AddEventHandlers.
//                   THE TWO ARE A PAIR: a handler named there whose class is
//                   not compiled is a HARD CRASH at map load, and a compiled
//                   handler not named there silently never runs.
//   CVARINFO.txt -- the rs_reserve_* block.
//
// DEBUG NETEVENTS (console, or a menu button someone else wires):
//   netevent rs_reserve_fire [groups] [per group]
//                          -- one wave right now, around the calling player,
//                             ignoring the master switch. 0/absent args mean
//                             "use the cvars".
//   netevent rs_reserve_markers
//                          -- light up every recorded marker inside the
//                             current distance band. Spawns NO monsters; it
//                             is how you look at the placement data.
//   netevent rs_reserve_status
//                          -- markers, bestiary, live reserves, next fire.
//   netevent rs_reserve_clear
//                          -- remove every monster this system spawned that
//                             is still alive (ClearCounters first).
//
// NOT BUILT, ON PURPOSE: no HUD/announcer for arrivals (the telegraph is
// diegetic only), no per-family weighting, no skill or player-count scaling,
// no menu page (MENUDEF belongs to the unified-menu lane).
// ============================================================================

// Membership marker. Every monster this director places carries one, so any
// other system can ask "did the reserve director send this?" without owning a
// list. Undroppable/untossable: it is state, not loot.
class RS_ReserveToken : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
	}
}

// Internal bookkeeping for the react-to-elite-reveal coupling: an elite whose
// reveal has already been answered carries this so it is answered once.
class RS_ReserveSeen : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
	}
}

// ---------------------------------------------------------------------------
// The telegraph beacon, which is also the thing that does the placement.
//
// One beacon per GROUP, spawned on the marker. It holds the group's payload
// and, when its lead-in runs out, performs the validated placement. Being a
// real actor sitting exactly on the marker is what makes the line trace
// possible -- the trace has to start at the spot, not at the player.
//
// Telegraph level 0 ("none") is not a special case in the code: it is a
// lead-in of zero tics, which arrives immediately from Setup(). That keeps
// the original no-warning behaviour reachable through the same one path.
// ---------------------------------------------------------------------------
class RS_ReserveBeacon : Actor
{
	Name   payload;         // what arrives; 'None' = a marker light, no monsters
	double payloadAngle;    // the marker's own recorded facing
	int    payloadCount;    // how many bodies
	int    arrivalStyle;    // rs_reserve_arrival
	int    telegraphLevel;  // rs_reserve_telegraph
	int    waitTics;        // lead-in; 0 = arrive at once
	int    ageTics;
	double spreadRadius;    // scatter around the marker

	Default
	{
		Radius 1;
		Height 1;
		+NOINTERACTION
		+NOBLOCKMAP
		+NOGRAVITY
		+NOTONAUTOMAP
		+DONTSPLASH
		+NOTIMEFREEZE
		RenderStyle "None";
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	// Called immediately after Spawn, because fields cannot be set before
	// PostBeginPlay runs. Returns the number of bodies committed -- with a
	// lead-in that is the planned count; with no lead-in it is the real,
	// validated count, because the arrival has already happened.
	int Setup(Name cls, double ang, int count, int arrival, int telegraph, int lead, double spread)
	{
		payload        = cls;
		payloadAngle   = ang;
		payloadCount   = count;
		arrivalStyle   = arrival;
		telegraphLevel = telegraph;
		waitTics       = lead;
		spreadRadius   = spread;

		if (waitTics <= 0)
		{
			int n = Arrive();
			Destroy();
			return n;
		}

		// The audible half of the warning. Every telegraph level above
		// "none" gets it -- a sound the player can place in space is the
		// cheapest legible warning there is.
		if (telegraphLevel >= 1)
			A_StartSound("misc/teleport", CHAN_AUTO, CHANF_DEFAULT, 0.5, ATTN_NORM);

		return count;
	}

	override void Tick()
	{
		Super.Tick();

		// Level 2 draws the ring on the floor, level 3 adds the column.
		if (telegraphLevel >= 2)
			DrawRing();
		if (telegraphLevel >= 3)
			DrawColumn();

		if (ageTics >= waitTics)
		{
			Arrive();
			Destroy();
			return;
		}
		ageTics++;
	}

	// Amber, deliberately: this is a wave telegraph, a combat-flow signal.
	// It is NOT a rarity colour and NOT a monster tier -- those vocabularies
	// belong to weapons and to monsters respectively and are not spoken here.
	private void DrawRing()
	{
		double rad = max(24.0, spreadRadius * 0.75);
		double prog = waitTics > 0 ? double(ageTics) / double(waitTics) : 1.0;
		color c = Color(255, 235, 150 + int(60 * prog), 40);
		for (int i = 0; i < 360; i += 12)
		{
			A_SpawnParticle(c, SPF_FULLBRIGHT | SPF_RELPOS, 10, 4, 0,
				rad * cos(double(i)), rad * sin(double(i)), 3,
				startalphaf: 0.35 + 0.5 * prog);
		}
	}

	private void DrawColumn()
	{
		color c = Color(255, 255, 190, 90);
		for (int i = 0; i < 3; i++)
		{
			A_SpawnParticle(c, SPF_FULLBRIGHT | SPF_RELPOS, 26, 5, 0,
				frandom[RSReserve](-10, 10), frandom[RSReserve](-10, 10), 2,
				0, 0, frandom[RSReserve](2.5, 5.0),
				startalphaf: 0.8);
		}
	}

	// The placement. Returns how many bodies survived validation.
	int Arrive()
	{
		if (payloadCount <= 0)
			return 0;

		class<Actor> cls = payload;
		if (!cls)
			return 0;

		int placed = 0;
		for (int i = 0; i < payloadCount; i++)
			if (PlaceOne(cls))
				placed++;
		return placed;
	}

	// One body: spawn on the marker, scatter with the scatter clamped out of
	// walls by a line trace, snap to the floor, validate, keep or destroy.
	private bool PlaceOne(class<Actor> cls)
	{
		Actor mo = Actor.Spawn(cls, (pos.x, pos.y, Actor.ONFLOORZ), ALLOW_REPLACE);
		if (!mo)
			return false;

		// --- scatter, traced clear of geometry ---------------------------
		// The trace starts HERE, on the marker, at the arriving body's own
		// mid-height, and tells us how far we can push before we are inside
		// something. Pull back by the body's radius so it is the whole
		// cylinder that clears the wall, not just its centre.
		if (spreadRadius > 1 && payloadCount > 1)
		{
			double a    = random[RSReserve](0, 359);
			double want = frandom[RSReserve](0, spreadRadius);
			double reach = want + mo.radius + 8;

			FLineTraceData d;
			if (LineTrace(a, reach, 0, TRF_THRUACTORS, mo.height * 0.5, 0, 0, d))
				want = clamp(d.Distance - mo.radius - 8, 0, want);

			if (want > 1)
			{
				Vector2 dest = mo.pos.XY + Actor.AngleToVector(a, want);
				// SetOrigin, not TryMove: a move crosses lines and can trip
				// walk-over specials (a teleport line would fling the body
				// across the map mid-placement). SetOrigin relinks and
				// refinds floor/ceiling without touching line specials.
				mo.SetOrigin((dest.x, dest.y, mo.pos.z), false);
				SnapToFloor(mo);
				if (!Fits(mo))
				{
					// Scatter failed -- fall back to the marker itself,
					// which is ground a level designer already approved.
					mo.SetOrigin((pos.x, pos.y, mo.pos.z), false);
					SnapToFloor(mo);
				}
			}
		}

		// --- the gate -----------------------------------------------------
		// A body that does not fit is destroyed, and ClearCounters() runs
		// FIRST. A spawned-then-destroyed monster that had counted itself
		// would raise the map's kill target with nothing to kill, and no
		// 100% clear would ever be possible again.
		if (!Fits(mo))
		{
			mo.ClearCounters();
			mo.Destroy();
			return false;
		}

		// --- arrival ------------------------------------------------------
		mo.angle = payloadAngle;

		// Drop-in: start it in the air inside whatever headroom exists and
		// let gravity finish the job. Floaters and flyers ignore this --
		// they would simply hang there.
		if (arrivalStyle == 3 && !mo.bNOGRAVITY && !mo.bFLOAT)
		{
			double head = (mo.ceilingz - mo.floorz) - mo.height;
			if (head > 16)
				mo.SetZ(mo.floorz + min(72.0, head - 8));
		}

		switch (arrivalStyle)
		{
			case 1:   // silent -- nothing at all, the bare appearance
				break;

			case 2:   // a quiet flourish: our own motes, no engine fog
			{
				for (int i = 0; i < 24; i++)
					mo.A_SpawnParticle(Color(255, 220, 220, 220),
						SPF_FULLBRIGHT | SPF_RELPOS, 22, 5, 0,
						frandom[RSReserve](-16, 16), frandom[RSReserve](-16, 16),
						frandom[RSReserve](0, 48),
						0, 0, frandom[RSReserve](-1.5, 1.5),
						startalphaf: 0.9);
				break;
			}

			default:  // 0 and 3: the engine's teleport fog, which brings its
			          // own teleport sound with it
				Actor.Spawn("TeleportFog", mo.pos + (0, 0, 8), ALLOW_REPLACE);
				break;
		}

		mo.GiveInventory("RS_ReserveToken", 1);

		// Reinforcements arrive hunting. Waking them by hand (target + See)
		// rather than leaving them in Look means the wave reads as an
		// answer to the player, not as scenery that happened to appear.
		mo.bAMBUSH = false;
		Actor tgt = RS_ReserveSquads.NearestPlayer(mo);
		if (tgt)
		{
			mo.angle = mo.AngleTo(tgt);
			mo.target = tgt;
			if (mo.SeeState)
				mo.SetState(mo.SeeState);
		}
		return true;
	}

	// Non-floaters stand on the floor of wherever they just landed --
	// SetOrigin has already re-found floorz for the new spot. Floaters and
	// flyers keep the height the spawn gave them.
	private static void SnapToFloor(Actor mo)
	{
		if (!mo.bFLOAT && !mo.bNOGRAVITY)
			mo.SetZ(mo.floorz);
	}

	// Two independent questions, both of which have to be yes:
	//   1. is there physically room between this floor and this ceiling
	//   2. does the engine agree the body may exist at this exact spot
	// TestMobjLocation covers most of (1) already; the explicit headroom
	// check is kept because it is the one that catches "a Baron was handed a
	// Zombieman's marker in a crawlspace".
	private static bool Fits(Actor mo)
	{
		if (!mo)
			return false;
		if (mo.height > mo.ceilingz - mo.floorz)
			return false;
		return mo.TestMobjLocation();
	}
}

// ---------------------------------------------------------------------------
// The director itself. MUST be listed in MAPINFO.txt's AddEventHandlers.
// ---------------------------------------------------------------------------
class RS_ReserveSquads : EventHandler
{
	// Recorded markers -- one entry per non-boss monster the map placed.
	// Parallel arrays of plain types on purpose: no object graph to keep
	// alive, nothing to be collected out from under us, and nothing whose
	// meaning depends on surviving a savegame round trip (WorldLoaded
	// rebuilds the table from the live map either way).
	//
	// spotCls/spotTier are the per-marker record of WHAT stood there. Roster
	// mode 1 reads spotCls so a marker prefers its own original occupant --
	// the one body already proven to fit that exact spot.
	Array<double> spotX;
	Array<double> spotY;
	Array<double> spotZ;
	Array<double> spotAng;
	Array<Name>   spotCls;
	Array<int>    spotTier;

	// The map's own bestiary, deduplicated, with the tier each class was
	// carrying when the map started.
	Array<Name> bestCls;
	Array<int>  bestTier;

	// Roster handed in from outside (SetPiece). Roster mode 3 reads this.
	Array<Name> explicitCls;

	int nextFireTic;
	int wavesFired;
	int lastWaveTic;

	// =====================================================================
	// Map setup
	// =====================================================================

	// Always rescans, including on a savegame load (WorldLoaded fires there
	// too, after the level is restored). That is deliberate: it means the
	// marker table is never trusted across a serialize/deserialize round
	// trip, only ever rebuilt from the map that is actually in front of us.
	// After a mid-map load the table is smaller -- markers whose monster the
	// player already killed are gone -- which is a fair description of the
	// map at that moment, not a defect.
	override void WorldLoaded(WorldEvent e)
	{
		ScanMap();
		ScheduleNext();
	}

	// The walk. Eligibility deliberately matches the elite handler's own
	// gate (zscript/monsters/RS_Elite.zs): ISMONSTER alone is not
	// enough, because decorative map props carry it -- COUNTKILL and not
	// SPECIAL is what "a real monster the map placed" means here.
	private void ScanMap()
	{
		spotX.Clear(); spotY.Clear(); spotZ.Clear(); spotAng.Clear();
		spotCls.Clear(); spotTier.Clear();
		bestCls.Clear(); bestTier.Clear();

		ThinkerIterator it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (!mo.bISMONSTER || mo.bFRIENDLY || mo.health <= 0)
				continue;
			if (!mo.bCOUNTKILL || mo.bSPECIAL)
				continue;
			// Non-boss only. A boss's footprint is not a reusable spot, and
			// its class is not something to hand a reinforcement wave.
			if (mo.bBOSS)
				continue;

			// Tier through the project's own API -- RS_Zom's token, not a
			// second tier notion invented here.
			int t = RS_Zom.GetTier(mo);
			Name cn = mo.GetClassName();

			spotX.Push(mo.pos.x);
			spotY.Push(mo.pos.y);
			spotZ.Push(mo.pos.z);
			spotAng.Push(mo.angle);
			spotCls.Push(cn);
			spotTier.Push(t);

			bool seen = false;
			for (int i = 0; i < bestCls.Size(); i++)
			{
				if (bestCls[i] == cn) { seen = true; break; }
			}
			if (!seen)
			{
				bestCls.Push(cn);
				bestTier.Push(t);
			}
		}
	}

	private void ScheduleNext()
	{
		int lo = max(1, RS_Zom.CV('rs_reserve_interval_min', 45));
		int hi = max(lo, RS_Zom.CV('rs_reserve_interval_max', 90));
		int secs = random[RSReserve](lo, hi);

		// Intensity pulls both dials at once: it shortens the gap here and
		// swells the wave in RunWave.
		int inten = clamp(RS_Zom.CV('rs_reserve_intensity', 100), 10, 400);
		secs = max(1, secs * 100 / inten);

		nextFireTic = level.maptime + secs * 35;
	}

	// =====================================================================
	// The clock
	// =====================================================================

	override void WorldTick()
	{
		if (spotX.Size() == 0)
			return;

		int eliteMode = RS_Zom.CV('rs_reserve_elite_mode', 0);

		// React coupling polls, because the elite system fires no event on
		// reveal and this file does not edit it.
		if (eliteMode == 1 && (level.maptime % 8) == 0)
			CheckEliteReveals();

		// SHIPS OFF. Everything above this line is bookkeeping; nothing
		// below it happens until someone turns the master switch on.
		if (RS_Zom.CV('rs_reserve_enabled', 0) == 0)
			return;

		if (nextFireTic <= 0)
		{
			ScheduleNext();
			return;
		}
		if (level.maptime < nextFireTic)
			return;

		// Suppress coupling: an elite fight the player is actually in owns
		// the moment. Look again shortly rather than losing the wave.
		if (eliteMode == 0 && EliteFightLive())
		{
			nextFireTic = level.maptime + 70;
			return;
		}

		Array<Name> pool;
		Array<int>  poolTier;
		BuildPool(-1, -1, pool, poolTier);
		RunWave(null, pool, poolTier, -1, -1, -1, -1, false);
		ScheduleNext();
	}

	// A revealed elite alive inside the far edge of the distance band means
	// the player is in a fight that has its own shape. Reading
	// RS_EliteToken.revealed is a read of the elite system's state; nothing
	// here writes to it.
	private bool EliteFightLive()
	{
		double range = RS_Zom.CV('rs_reserve_dist_max', 1536);
		ThinkerIterator it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (mo.health <= 0 || !mo.bISMONSTER)
				continue;
			let tok = RS_EliteToken(mo.FindInventory("RS_EliteToken"));
			if (!tok || !tok.revealed)
				continue;
			for (int i = 0; i < MAXPLAYERS; i++)
			{
				if (!playeringame[i] || !players[i].mo || players[i].mo.health <= 0)
					continue;
				if (mo.Distance3D(players[i].mo) <= range)
					return true;
			}
		}
		return false;
	}

	// Each reveal is answered once. The marker token is ours; the elite's
	// own state is only read.
	private void CheckEliteReveals()
	{
		bool fresh = false;
		ThinkerIterator it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (mo.health <= 0 || !mo.bISMONSTER)
				continue;
			let tok = RS_EliteToken(mo.FindInventory("RS_EliteToken"));
			if (!tok || !tok.revealed)
				continue;
			if (mo.FindInventory("RS_ReserveSeen"))
				continue;
			mo.GiveInventory("RS_ReserveSeen", 1);
			fresh = true;
		}

		if (!fresh)
			return;
		if (RS_Zom.CV('rs_reserve_enabled', 0) == 0)
			return;

		// Don't let a cluster of reveals become a stampede: half the
		// shortest configured gap is the floor between reactive waves.
		int cd = 35 * max(1, RS_Zom.CV('rs_reserve_interval_min', 45)) / 2;
		if (lastWaveTic > 0 && level.maptime - lastWaveTic < cd)
			return;

		Array<Name> pool;
		Array<int>  poolTier;
		BuildPool(-1, -1, pool, poolTier);
		RunWave(null, pool, poolTier, -1, -1, -1, -1, false);
	}

	// =====================================================================
	// Roster
	// =====================================================================

	// The tier-1 "Common" bodies, one per family. Source of truth for these
	// names: RS_MonsterDebugHandler.FamilyList in
	// zscript/monsters/RS_MonsterDebug.zs -- the first entry of each of its
	// seventeen families. Copied rather than called so this file does not
	// depend on another system's list ordering; it is a plain push sequence
	// because `static const Name x[] = {...}` does not reliably resolve on
	// this engine build.
	//
	// These are the plainest monsters in the game: a player cannot tell one
	// from a vanilla monster by looking, which is what makes them the right
	// default for reinforcements.
	private static void CommonTier1(out Array<Name> list)
	{
		list.Clear();
		list.Push('RS_CommonZombie');
		list.Push('RS_CommonSG');
		list.Push('RS_CommonCGuy');
		list.Push('RS_CommonImp');
		list.Push('RS_CommonDemon');
		list.Push('RS_CommonSpectre');
		list.Push('RS_CommonLSoul');
		list.Push('RS_CommonCaco');
		list.Push('RS_CommonPE');
		list.Push('RS_CommonHK');
		list.Push('RS_CommonBaron');
		list.Push('RS_CommonRevenant');
		list.Push('RS_CommonFatso');
		list.Push('RS_CommonSP1');
		list.Push('RS_CommonArch');
		list.Push('RS_CommonCybie');   // +BOSS -- rs_reserve_allow_boss gates it
		list.Push('RS_CommonMind');    // +BOSS -- rs_reserve_allow_boss gates it
	}

	private static bool ClassAllowed(Name n, bool allowBoss)
	{
		class<Actor> cls = n;
		if (!cls)
			return false;
		let def = GetDefaultByType(cls);
		if (!def || !def.bISMONSTER)
			return false;
		if (!allowBoss && def.bBOSS)
			return false;
		return true;
	}

	// Builds the pool for one wave. tierMin/tierMax of -1 mean "read the
	// cvars".
	//
	// An empty pool is a legitimate answer, not a failure to paper over: a
	// tier band that excludes every class in the chosen roster means no wave
	// fires. Widen the band or change rs_reserve_roster. The one exception
	// is escalation, which walks the map's own tier ladder and is written so
	// it can never empty the pool on its own.
	private void BuildPool(int tierMin, int tierMax, out Array<Name> pool, out Array<int> poolTier)
	{
		pool.Clear();
		poolTier.Clear();

		int mode = RS_Zom.CV('rs_reserve_roster', 0);
		if (mode == 3 && explicitCls.Size() == 0)
			mode = 0;                                   // nothing handed in
		if ((mode == 1 || mode == 2) && bestCls.Size() == 0)
			mode = 0;                                   // map gave us no bestiary

		Array<Name> raw;
		Array<int>  rawTier;
		int i;

		if (mode == 0)
		{
			CommonTier1(raw);
			for (i = 0; i < raw.Size(); i++)
				rawTier.Push(1);
		}
		else if (mode == 3)
		{
			// A caller's roster still passes the boss gate below, because
			// mode 3 is the AUTOMATIC director drawing from that list and
			// rs_reserve_allow_boss is the player's own opt-in. A direct
			// DeployList/DeployClass call skips this whole function and is
			// not gated -- that call is a deliberate act, not a roll.
			for (i = 0; i < explicitCls.Size(); i++)
			{
				raw.Push(explicitCls[i]);
				rawTier.Push(-1);                       // -1 = tier unknown, never filtered out
			}
		}
		else
		{
			for (i = 0; i < bestCls.Size(); i++)
			{
				raw.Push(bestCls[i]);
				rawTier.Push(bestTier[i]);
			}
		}

		bool allowBoss = RS_Zom.CV('rs_reserve_allow_boss', 0) != 0;

		if (tierMin < 0) tierMin = RS_Zom.CV('rs_reserve_tier_min', 0);
		if (tierMax < 0) tierMax = RS_Zom.CV('rs_reserve_tier_max', 13);
		if (tierMax < tierMin)
		{
			int swap = tierMin; tierMin = tierMax; tierMax = swap;
		}

		Array<Name> keep;
		Array<int>  keepTier;
		for (i = 0; i < raw.Size(); i++)
		{
			if (!ClassAllowed(raw[i], allowBoss))
				continue;
			int t = rawTier[i];
			if (t >= 0 && (t < tierMin || t > tierMax))
				continue;
			keep.Push(raw[i]);
			keepTier.Push(t);
		}

		// Escalation: the wave counter names a target tier, and the wave is
		// drawn from the highest rung of the map's own ladder at or below
		// that target. If the map has nothing that low, the lowest rung it
		// does have is used -- so escalation raises pressure over time and
		// still always has something to send.
		if (mode == 2 && keep.Size() > 0)
		{
			int step   = max(1, RS_Zom.CV('rs_reserve_escalate_waves', 3));
			int target = 1 + wavesFired / step;

			int chosen = -9999;
			for (i = 0; i < keepTier.Size(); i++)
			{
				if (keepTier[i] <= target && keepTier[i] > chosen)
					chosen = keepTier[i];
			}
			if (chosen == -9999)
			{
				chosen = keepTier[0];
				for (i = 0; i < keepTier.Size(); i++)
				{
					if (keepTier[i] < chosen)
						chosen = keepTier[i];
				}
			}

			Array<Name> rung;
			Array<int>  rungTier;
			for (i = 0; i < keep.Size(); i++)
			{
				if (keepTier[i] != chosen)
					continue;
				rung.Push(keep[i]);
				rungTier.Push(keepTier[i]);
			}
			keep.Clear(); keepTier.Clear();
			for (i = 0; i < rung.Size(); i++)
			{
				keep.Push(rung[i]);
				keepTier.Push(rungTier[i]);
			}
		}

		for (i = 0; i < keep.Size(); i++)
		{
			pool.Push(keep[i]);
			poolTier.Push(keepTier[i]);
		}
	}

	// =====================================================================
	// Firing
	// =====================================================================

	// Markers inside the distance band, drawn without replacement.
	private void PickMarkers(Actor anchor, int want, out Array<int> picked)
	{
		picked.Clear();
		if (!anchor)
			return;

		double dmin = RS_Zom.CV('rs_reserve_dist_min', 384);
		double dmax = RS_Zom.CV('rs_reserve_dist_max', 1536);
		if (dmax < dmin)
		{
			double swap = dmin; dmin = dmax; dmax = swap;
		}

		Array<int> band;
		for (int i = 0; i < spotX.Size(); i++)
		{
			Vector3 sp = (spotX[i], spotY[i], spotZ[i]);
			// Vec3Diff, not raw subtraction: portal-aware, so a portalled
			// map does not report a neighbour room as half a map away.
			double d = level.Vec3Diff(anchor.pos, sp).Length();
			if (d < dmin || d > dmax)
				continue;
			band.Push(i);
		}

		for (int n = 0; n < want && band.Size() > 0; n++)
		{
			int k = random[RSReserve](0, band.Size() - 1);
			picked.Push(band[k]);
			band.Delete(k);
		}
	}

	// One wave. Returns bodies committed. With a telegraph lead-in that is
	// the planned count -- the real placements resolve when each beacon
	// expires, and anything that does not fit is destroyed there.
	private int RunWave(Actor around, out Array<Name> pool, out Array<int> poolTier,
		int groups, int perGroup, int arrival, int telegraph, bool verbose)
	{
		if (spotX.Size() == 0)
		{
			if (verbose) Console.Printf("RS_ReserveSquads: this map handed us no spawn markers.");
			return 0;
		}
		if (pool.Size() == 0)
		{
			if (verbose) Console.Printf("RS_ReserveSquads: the roster is empty -- check rs_reserve_roster and the tier band.");
			return 0;
		}

		Actor anchor = AnchorPlayer(around);
		if (!anchor)
			return 0;

		int inten = clamp(RS_Zom.CV('rs_reserve_intensity', 100), 10, 400);

		if (groups < 0)
		{
			int lo = max(1, RS_Zom.CV('rs_reserve_groups_min', 1));
			int hi = max(lo, RS_Zom.CV('rs_reserve_groups_max', 2));
			groups = random[RSReserve](lo, hi) * inten / 100;
		}
		if (perGroup < 0)
		{
			int lo = max(1, RS_Zom.CV('rs_reserve_pergroup_min', 2));
			int hi = max(lo, RS_Zom.CV('rs_reserve_pergroup_max', 4));
			perGroup = random[RSReserve](lo, hi) * inten / 100;
		}
		groups   = clamp(groups, 1, 32);
		perGroup = clamp(perGroup, 1, 32);

		// Live cap -- the one thing standing between "intensity 400" and a
		// map with two thousand monsters in it.
		int cap = RS_Zom.CV('rs_reserve_max_alive', 24);
		if (cap > 0)
		{
			int room = cap - LiveCount();
			if (room <= 0)
			{
				if (verbose) Console.Printf("RS_ReserveSquads: rs_reserve_max_alive (%d) reached.", cap);
				return 0;
			}
			while (groups * perGroup > room && groups > 1)
				groups--;
			if (groups * perGroup > room)
				perGroup = max(1, room);
		}

		Array<int> picked;
		PickMarkers(anchor, groups, picked);
		if (picked.Size() == 0)
		{
			if (verbose) Console.Printf("RS_ReserveSquads: no markers between %d and %d units of the player.",
				RS_Zom.CV('rs_reserve_dist_min', 384), RS_Zom.CV('rs_reserve_dist_max', 1536));
			return 0;
		}

		if (arrival < 0)   arrival   = RS_Zom.CV('rs_reserve_arrival', 0);
		if (telegraph < 0) telegraph = RS_Zom.CV('rs_reserve_telegraph', 2);
		int lead = (telegraph <= 0) ? 0 : max(0, RS_Zom.CV('rs_reserve_telegraph_time', 35));
		double spread = max(0, RS_Zom.CV('rs_reserve_spread', 96));

		// In plain map-bestiary mode, a marker prefers the class that
		// actually stood on it. That is the strongest placement guarantee
		// available: this exact body fitted this exact spot when the level
		// designer put it there. Any other roster mode ignores it -- the
		// escalation mode is explicitly climbing a ladder, and an explicit
		// caller's list will simply not contain the marker's class, so this
		// falls through to the roll on its own.
		bool preferLocal = (RS_Zom.CV('rs_reserve_roster', 0) == 1);

		int committed = 0;
		for (int i = 0; i < picked.Size(); i++)
		{
			int s = picked[i];
			// One class per group: a squad is a unit. Groups in the same
			// wave roll independently, so a wave can still be mixed.
			Name cls = pool[random[RSReserve](0, pool.Size() - 1)];
			if (preferLocal)
			{
				for (int k = 0; k < pool.Size(); k++)
				{
					if (pool[k] == spotCls[s]) { cls = pool[k]; break; }
				}
			}

			let b = RS_ReserveBeacon(Actor.Spawn("RS_ReserveBeacon",
				(spotX[s], spotY[s], spotZ[s]), NO_REPLACE));
			if (!b)
				continue;
			committed += b.Setup(cls, spotAng[s], perGroup, arrival, telegraph, lead, spread);
		}

		wavesFired++;
		lastWaveTic = level.maptime;
		return committed;
	}

	// =====================================================================
	// Debug netevents -- see the file header for the list.
	// =====================================================================

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || !playeringame[e.Player])
			return;
		let pmo = players[e.Player].mo;
		if (!pmo)
			return;

		if (e.Name ~== "rs_reserve_fire")
		{
			int g = e.Args[0] > 0 ? e.Args[0] : -1;
			int p = e.Args[1] > 0 ? e.Args[1] : -1;
			Array<Name> pool;
			Array<int>  poolTier;
			BuildPool(-1, -1, pool, poolTier);
			int n = RunWave(pmo, pool, poolTier, g, p, -1, -1, true);
			if (n > 0)
				Console.Printf("RS_ReserveSquads: %d reinforcements committed.", n);
		}
		else if (e.Name ~== "rs_reserve_markers")
		{
			// Capped: one beacon draws a ring of particles every tic, and a
			// big map inside a wide band is hundreds of markers. 48 is
			// enough to read the shape of the placement data.
			Array<int> picked;
			PickMarkers(pmo, 48, picked);
			for (int i = 0; i < picked.Size(); i++)
			{
				int s = picked[i];
				let b = RS_ReserveBeacon(Actor.Spawn("RS_ReserveBeacon",
					(spotX[s], spotY[s], spotZ[s]), NO_REPLACE));
				if (b)
					b.Setup('None', spotAng[s], 0, 1, 2, 70, 64);   // 0 bodies: lights only
			}
			Console.Printf("RS_ReserveSquads: lit %d markers (map total %d, band %d-%d).",
				picked.Size(), spotX.Size(),
				RS_Zom.CV('rs_reserve_dist_min', 384), RS_Zom.CV('rs_reserve_dist_max', 1536));
		}
		else if (e.Name ~== "rs_reserve_status")
		{
			Console.Printf("RS_ReserveSquads: %s | markers %d | bestiary %d | explicit roster %d | live %d | waves %d",
				RS_Zom.CV('rs_reserve_enabled', 0) != 0 ? "ON" : "OFF (debug netevents still fire)",
				spotX.Size(), bestCls.Size(), explicitCls.Size(), LiveCount(), wavesFired);
			int wait = nextFireTic - level.maptime;
			Console.Printf("  next scheduled wave in %d seconds", wait > 0 ? wait / 35 : 0);

			Array<Name> pool;
			Array<int>  poolTier;
			BuildPool(-1, -1, pool, poolTier);
			String line = "";
			for (int i = 0; i < pool.Size() && i < 24; i++)
			{
				// Name -> String through an assignment, never straight into
				// a concatenation: a Name and a string literal in the same
				// expression is a type error on this build.
				String nm = pool[i];
				line = line .. " " .. nm;
			}
			Console.Printf("  pool (%d):%s", pool.Size(), line);
		}
		else if (e.Name ~== "rs_reserve_clear")
		{
			// Collect first, destroy after: never tear thinkers out of the
			// list an iterator is still walking.
			Array<Actor> doomed;
			ThinkerIterator it = ThinkerIterator.Create("Actor");
			Actor mo;
			while (mo = Actor(it.Next()))
			{
				if (mo.FindInventory("RS_ReserveToken"))
					doomed.Push(mo);
			}
			for (int i = 0; i < doomed.Size(); i++)
			{
				// ClearCounters first, always -- removing a live monster
				// without it strands its kill in the map's total.
				doomed[i].ClearCounters();
				doomed[i].Destroy();
			}
			Console.Printf("RS_ReserveSquads: removed %d reinforcements.", doomed.Size());
		}
	}

	// =====================================================================
	// PUBLIC API -- what SetPiece (or anything else) calls.
	//
	//   // three shotgunners at one approved spot near the player, no warning
	//   RS_ReserveSquads.DeployClass(pmo, 'RS_CommonSG', 3, 1, 0, 0);
	//
	//   // a two-group wave from a list this encounter owns
	//   Array<Name> squad;
	//   squad.Push('RS_GreenImp'); squad.Push('RS_BlueImp');
	//   RS_ReserveSquads.DeployList(pmo, squad, 2, 3);
	//
	//   // whatever the cvars say, but tiers 4-6 only, fog arrival, full warning
	//   RS_ReserveSquads.Deploy(pmo, -1, -1, 4, 6, 0, 3);
	//
	// Every one of them returns the number of bodies committed, and 0 is a
	// real answer: no markers on this map, nothing inside the distance band,
	// the live cap reached, or a roster the tier band emptied.
	// =====================================================================

	static RS_ReserveSquads Get()
	{
		return RS_ReserveSquads(EventHandler.Find("RS_ReserveSquads"));
	}

	// One wave using the configured roster. Any argument left at -1 falls
	// back to its cvar.
	static int Deploy(Actor around, int groups = -1, int perGroup = -1,
		int tierMin = -1, int tierMax = -1, int arrival = -1, int telegraph = -1)
	{
		let h = Get();
		if (!h)
			return 0;
		Array<Name> pool;
		Array<int>  poolTier;
		h.BuildPool(tierMin, tierMax, pool, poolTier);
		return h.RunWave(around, pool, poolTier, groups, perGroup, arrival, telegraph, false);
	}

	// One wave of exactly this class -- the simplest setpiece call there is.
	static int DeployClass(Actor around, Name cls, int perGroup, int groups = 1,
		int arrival = -1, int telegraph = -1)
	{
		let h = Get();
		if (!h)
			return 0;
		Array<Name> pool;
		Array<int>  poolTier;
		pool.Push(cls);
		poolTier.Push(-1);
		return h.RunWave(around, pool, poolTier, groups, perGroup, arrival, telegraph, false);
	}

	// One wave drawn from a list the caller owns. The list is used exactly
	// as given -- no tier band, no roster mode; the caller has already
	// decided. Boss classes still obey rs_reserve_allow_boss only if the
	// caller filters for it, because an explicit hand-off is a deliberate
	// act, not a roll.
	static int DeployList(Actor around, out Array<Name> classes, int groups = -1,
		int perGroup = -1, int arrival = -1, int telegraph = -1)
	{
		let h = Get();
		if (!h)
			return 0;
		Array<Name> pool;
		Array<int>  poolTier;
		for (int i = 0; i < classes.Size(); i++)
		{
			class<Actor> c = classes[i];
			if (!c)
				continue;
			pool.Push(classes[i]);
			poolTier.Push(-1);
		}
		return h.RunWave(around, pool, poolTier, groups, perGroup, arrival, telegraph, false);
	}

	// Persistent roster for roster mode 3. Set it, switch rs_reserve_roster
	// to 3, and the automatic director draws from the caller's list.
	static void SetRoster(out Array<Name> classes)
	{
		let h = Get();
		if (!h)
			return;
		h.explicitCls.Clear();
		for (int i = 0; i < classes.Size(); i++)
			h.explicitCls.Push(classes[i]);
	}

	static void ClearRoster()
	{
		let h = Get();
		if (h)
			h.explicitCls.Clear();
	}

	// How many approved spawn spots this map handed us. 0 means the director
	// cannot fire here at all, and that is worth knowing before charging a
	// player for an encounter.
	static int MarkerCount()
	{
		let h = Get();
		return h ? h.spotX.Size() : 0;
	}

	// How many of this system's monsters are alive right now.
	static int LiveCount()
	{
		int n = 0;
		ThinkerIterator it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (mo.health > 0 && mo.FindInventory("RS_ReserveToken"))
				n++;
		}
		return n;
	}

	static bool IsReserve(Actor mo)
	{
		return mo != null && mo.FindInventory("RS_ReserveToken") != null;
	}

	// --- small shared helpers, also used by the beacon --------------------

	static Actor AnchorPlayer(Actor around)
	{
		if (around)
			return around;
		Array<int> live;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (playeringame[i] && players[i].mo && players[i].mo.health > 0)
				live.Push(i);
		}
		if (live.Size() == 0)
			return null;
		return players[live[random[RSReserve](0, live.Size() - 1)]].mo;
	}

	static Actor NearestPlayer(Actor from)
	{
		if (!from)
			return null;
		Actor best = null;
		double bestd = 0;
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo || players[i].mo.health <= 0)
				continue;
			double d = from.Distance3D(players[i].mo);
			if (!best || d < bestd)
			{
				best = players[i].mo;
				bestd = d;
			}
		}
		return best;
	}
}
