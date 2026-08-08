// =====================================================================
// RS_Score -- arcade scoring. The foundations of a style-kill system.
// ---------------------------------------------------------------------
// THE SHAPE OF IT
//   Base points for a kill, then independent situational multipliers
//   that stack, grouped into flavors, each announcing itself on the HUD
//   the instant it pays. Nothing is a mode you enter; every bonus is a
//   fact about the kill you just made, evaluated once, at the moment it
//   happens.
//
//   The multipliers are FRACTIONS OF BASE POINTS, not flat amounts, so
//   the whole system scales itself against whatever bestiary is loaded
//   and a bonus is worth the same proportion on a zombieman as on a
//   Cyberdemon. Raising one in isolation quietly demotes all the others.
//
// WHAT THIS SYSTEM DELIBERATELY DOES NOT DO
//   It does not grant permanent power, and it is NOT tied to Gold Bits
//   or any other economy in this project. Score is its own currency.
//   Promotion owns permanent growth, Gun Bonsai owns weapon growth,
//   Gold owns card rerolls; score pays out in CONSUMABLES (extra lives,
//   ammo regen) and nothing else. Keeping the currencies separate is
//   the design, not an oversight -- if a score cash-in is ever wanted
//   it gets its own price list, it does not become an exchange rate.
//
// REGISTRATION: RS_ScoreHandler is an EventHandler, so it does NOT
// EXIST at runtime unless MAPINFO.txt lists it in
// GameInfo { AddEventHandlers = ... }. Same trap that left
// RS_MonsterDebug's entire menu dead. If scoring goes silent, check
// MAPINFO before reading a single line of this file.
// =====================================================================

// ---------------------------------------------------------------------
// Bonus IDs. Kept as consts rather than an enum so the HUD can iterate
// 0..RS_SB_COUNT-1 without casting.
// ---------------------------------------------------------------------
class RS_ScoreDefs
{
	// Ids are STABLE -- the HUD keeps per-bonus popup state in arrays
	// indexed by these, so renumbering silently reassigns every live
	// popup. Append at the end; never insert in the middle.
	const RS_SB_BASE        = 0;
	const RS_SB_SPREE       = 1;
	const RS_SB_UNTOUCHABLE = 2;
	const RS_SB_INFIGHTER   = 3;
	const RS_SB_SWITCHAROO  = 4;
	const RS_SB_SCRAPPING   = 5;
	const RS_SB_TELEFRAG    = 6;
	const RS_SB_CURVEBALL   = 7;
	const RS_SB_DARWIN      = 8;
	const RS_SB_AIR         = 9;
	const RS_SB_REDLINE     = 10;
	const RS_SB_SWANSONG    = 11;
	const RS_SB_POINTBLANK  = 12;
	const RS_SB_BRAWLER     = 13;
	const RS_SB_GIANTSLAYER = 14;
	const RS_SB_COUNT       = 15;

	// Flavor groups. Purely a color/readability device -- nothing keys
	// off the group mechanically.
	const RS_SF_BASE       = 0;
	const RS_SF_EFFICIENCY = 1;
	const RS_SF_STYLE      = 2;
	const RS_SF_DARING     = 3;

	// Comparison chains, never `static const string x[] = {...}` --
	// that form does not resolve reliably on this engine build (see
	// CLAUDE.md; it has been rediscovered three times).
	clearscope static string BonusName(int id)
	{
		switch (id)
		{
			// Title case is correct: RSSCRFN2 renders caps, so these read
			// as BASE / SPREE / SWITCHAROO on screen.
			//
			// These names are FIXED. A pass once rewrote five of them to be
			// more descriptive -- Base to KILL, Switcharoo to AMBIDEXTROUS,
			// Telefragged to TELEFRAG, Curveball to BLINDSIDE, Air to
			// AIRBORNE -- and every one had to be put back. Do not improve
			// them again.
			case RS_SB_BASE:         return "Base";
			case RS_SB_SPREE:        return "Spree";
			case RS_SB_UNTOUCHABLE:  return "Untouchable";
			case RS_SB_INFIGHTER:    return "Infighter";
			case RS_SB_SWITCHAROO:   return "Switcharoo";
			case RS_SB_SCRAPPING:    return "Scrapping";
			case RS_SB_TELEFRAG:     return "Telefragged";
			case RS_SB_CURVEBALL:    return "Curveball";
			case RS_SB_DARWIN:       return "Darwin";
			case RS_SB_AIR:          return "Air";
			case RS_SB_REDLINE:      return "Redline";
			case RS_SB_SWANSONG:     return "Swan Song";
			case RS_SB_POINTBLANK:   return "Point-Blank";
			case RS_SB_BRAWLER:      return "Brawler";
			// The one bonus original to this project, hence the only name
			// here that was ours to choose.
			case RS_SB_GIANTSLAYER:  return "Giant Slayer";
		}
		return "";
	}

	clearscope static int BonusFlavor(int id)
	{
		switch (id)
		{
			case RS_SB_BASE:
				return RS_SF_BASE;

			case RS_SB_SPREE:
			case RS_SB_UNTOUCHABLE:
			case RS_SB_INFIGHTER:
				return RS_SF_EFFICIENCY;

			case RS_SB_SWITCHAROO:
			case RS_SB_SCRAPPING:
			case RS_SB_TELEFRAG:
			case RS_SB_CURVEBALL:
			case RS_SB_DARWIN:
			case RS_SB_AIR:
				return RS_SF_STYLE;

			case RS_SB_REDLINE:
			case RS_SB_SWANSONG:
			case RS_SB_POINTBLANK:
			case RS_SB_BRAWLER:
			case RS_SB_GIANTSLAYER:
				return RS_SF_DARING;
		}
		return RS_SF_BASE;
	}

	// Per-bonus enable cvar. One knob per bonus was an explicit ask --
	// every bonus can be switched off independently.
	clearscope static string BonusCVar(int id)
	{
		switch (id)
		{
			case RS_SB_SPREE:        return "rs_score_b_spree";
			case RS_SB_UNTOUCHABLE:  return "rs_score_b_untouchable";
			case RS_SB_INFIGHTER:    return "rs_score_b_infighter";
			case RS_SB_SWITCHAROO:   return "rs_score_b_switcharoo";
			case RS_SB_SCRAPPING:    return "rs_score_b_scrapping";
			case RS_SB_TELEFRAG:     return "rs_score_b_telefrag";
			case RS_SB_CURVEBALL:    return "rs_score_b_curveball";
			case RS_SB_DARWIN:       return "rs_score_b_darwin";
			case RS_SB_AIR:          return "rs_score_b_air";
			case RS_SB_REDLINE:      return "rs_score_b_redline";
			case RS_SB_SWANSONG:     return "rs_score_b_swansong";
			case RS_SB_POINTBLANK:   return "rs_score_b_pointblank";
			case RS_SB_BRAWLER:      return "rs_score_b_brawler";
			case RS_SB_GIANTSLAYER:  return "rs_score_b_giantslayer";
		}
		return "";
	}

	clearscope static bool BonusEnabled(int id)
	{
		if (id == RS_SB_BASE)
			return true;

		string cv = BonusCVar(id);
		if (cv == "")
			return true;

		let c = CVar.GetCVar(cv, null);
		return c ? c.GetBool() : true;
	}

	// Melee identification by name test, which works because every melee
	// weapon in this project is an RS_ class with a predictable name. A
	// per-weapon table would be more precise and would need a new row
	// every time a weapon is added; this does not.
	clearscope static bool IsMeleeWeaponName(Name wpn)
	{
		// GetClassName() hands back a Name, not a String -- concatenate
		// before any string work or it is a type error (CLAUDE.md).
		string s = wpn .. "";
		s = s.MakeLower();

		return s.IndexOf("fist")     >= 0
			|| s.IndexOf("chainsaw") >= 0
			|| s.IndexOf("punch")    >= 0
			|| s.IndexOf("melee")    >= 0
			|| s.IndexOf("knife")    >= 0;
	}
}


// ---------------------------------------------------------------------
// One of these per player slot. Every piece of a player's scoring state
// lives here and nowhere else, so there is exactly one thing to reset,
// carry across a map, or reason about when a bonus misfires.
// ---------------------------------------------------------------------
class RS_ScorePlayer : Object
{
	int score;              // true running score
	int displayScore;       // rolls up toward score, for the HUD counter
	int rewardCount;        // how many thresholds crossed (drives alternation)
	int extraLives;
	int regenTimer;         // tics of ammo regen remaining
	int regenSpent;
	int scoreSpent;         // score spent at a cash-in, if one exists

	// Spree -- the kill streak
	int spreeCount;
	int spreeExpire;

	// Untouchable
	int utKills;
	int utDamage;
	int utStacks;

	// Air
	double airFloorZ;
	double airPeak;

	// Switcharoo -- last-fired timestamps
	Name lastWeaponA;
	Name lastWeaponB;
	int  lastWeaponATime;
	int  lastWeaponBTime;
	int  lastPrimaryTime;
	int  lastAltTime;

	// Per-bonus popup state
	Array<int> bonusValue;
	Array<int> bonusTime;

	// Tics since the last scoring kill, or -1 for "not flashing".
	//
	// This was a one-tic bool. RenderOverlay runs at frame rate and the
	// flag was cleared by the next WorldTick, so the afterglow lasted a
	// single tic, far too short to see. The counter is what lets the HUD
	// draw a real fade.
	int flashAge;

	void Init()
	{
		bonusValue.Clear();
		bonusTime.Clear();
		for (int i = 0; i < RS_ScoreDefs.RS_SB_COUNT; i++)
		{
			bonusValue.Push(0);
			bonusTime.Push(-1);
		}
		ResetRun(true);
	}

	void ResetRun(bool full)
	{
		spreeCount = 0;
		spreeExpire = 0;
		utKills = 0;
		utDamage = 0;
		utStacks = 0;
		airFloorZ = 0;
		airPeak = 0;
		lastWeaponA = 'None';
		lastWeaponB = 'None';
		lastWeaponATime = -99999;
		lastWeaponBTime = -99999;
		lastPrimaryTime = -99999;
		lastAltTime = -99999;
		flashAge = -1;

		if (full)
		{
			score = 0;
			displayScore = 0;
			rewardCount = 0;
			extraLives = 0;
			regenTimer = 0;
			regenSpent = 0;
			scoreSpent = 0;
			ClearBonuses();
		}
	}

	void ClearBonuses()
	{
		for (int i = 0; i < bonusValue.Size(); i++)
		{
			bonusValue[i] = 0;
			bonusTime[i] = -1;
		}
	}

	void AddBonus(int id, int amount, int now)
	{
		if (amount <= 0 || id < 0 || id >= bonusValue.Size())
			return;
		bonusValue[id] += amount;
		bonusTime[id] = now;
	}
}


// ---------------------------------------------------------------------
// The engine.
// ---------------------------------------------------------------------
class RS_ScoreHandler : EventHandler
{
	// These few stay constants while nearly everything else is a cvar,
	// because they are SHAPE rather than preference -- the window a combo
	// lives in, and the reach of point-blank, define what the bonus
	// means. Anything a player might reasonably want to tune is a cvar.
	const SPREE_TICS_PER_100HP = 24;
	const SPREE_MIN_TICS       = 72;
	const SPREE_MAX_TICS       = 360;

	const AMBI_TICS_PER_100HP  = 24;
	const AMBI_MIN_TICS        = 72;
	const AMBI_MAX_TICS        = 144;

	const AIR_MIN_HEIGHT       = 64.0;
	// 64 map units, edge to edge. A pass once widened this to 96 without
	// saying why.
	const POINTBLANK_DIST      = 64.0;

	// NOT named `players` -- that identifier is the engine's global
	// player array, and shadowing it here silently breaks every
	// players[i].mo lookup in this class.
	Array<RS_ScorePlayer> scorePlayers;

	// Per-map reward threshold, calibrated at load from the map's own
	// monster population, which is what makes one bar mean the same
	// amount of work on MAP01 as on a slaughtermap.
	int fullRewardScore;
	int mapTotalMonsters;
	int mapTotalPoints;

	// -----------------------------------------------------------------
	// Lifecycle
	// -----------------------------------------------------------------
	override void OnRegister()
	{
		scorePlayers.Clear();
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			let p = new("RS_ScorePlayer");
			p.Init();
			scorePlayers.Push(p);
		}
	}

	// clearscope for the same reason CVInt/CVBool below are: this is called
	// from play code (scoring) AND from ui code (RenderOverlay). An
	// unqualified method on an EventHandler defaults to play scope, which
	// makes the ui caller a compile error. It only reads the array.
	clearscope RS_ScorePlayer Get(int pln)
	{
		if (pln < 0 || pln >= scorePlayers.Size())
			return null;
		return scorePlayers[pln];
	}

	clearscope bool ScoreEnabled() const
	{
		let c = CVar.GetCVar("rs_score_enable", null);
		return c ? c.GetBool() : true;
	}

	// clearscope: these are called from play code (scoring) AND from ui
	// code (ShouldDrawHUD). A plain `static` here defaults to the class's
	// play scope and makes the ui callers a compile error.
	clearscope static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	clearscope static double CVFloat(string name, double def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetFloat() : def;
	}

	clearscope static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	// -----------------------------------------------------------------
	// Map load -- calibrate the reward threshold.
	//
	// Weighted by TIER, not by raw hit points: RS monsters carry an
	// explicit Tier and TierMaxHealth, so the population is measured by
	// how dangerous it actually is. A T12 monster and a pile of
	// zombiemen with the same total HP are not the same map.
	// -----------------------------------------------------------------
	override void WorldLoaded(WorldEvent e)
	{
		mapTotalMonsters = 0;
		mapTotalPoints = 0;

		ThinkerIterator it = ThinkerIterator.Create("Actor", Thinker.STAT_DEFAULT);
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (!mo.bIsMonster || mo.health <= 0)
				continue;

			mapTotalMonsters++;
			mapTotalPoints += BasePointsFor(mo);
		}

		int avg = mapTotalMonsters > 0 ? (mapTotalPoints / mapTotalMonsters) : 0;

		int monMin = CVInt("rs_score_monstermin", 30);
		int monMax = CVInt("rs_score_monstermax", 400);
		double scalar = CVFloat("rs_score_monsterscalar", 0.30);
		int interval = max(1, CVInt("rs_score_interval", 100));

		int clamped = clamp(mapTotalMonsters, monMin, monMax);
		int target = int(avg * scalar * clamped);

		// Round to the interval so the number on the HUD is legible.
		fullRewardScore = max(interval, (target / interval) * interval);

		// Carry-over: preserve each player's fraction of a bar across
		// maps so progress toward the next reward is not silently
		// deleted by an exit line.
		int startMode = CVInt("rs_score_startmode", 1);
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			let sp = Get(i);
			if (!sp)
				continue;

			sp.ResetRun(false);
			sp.ClearBonuses();

			if (startMode == 0)
			{
				// Full reset every map.
				sp.score = 0;
				sp.displayScore = 0;
				sp.rewardCount = 0;
			}
			else if (startMode == 1)
			{
				// Keep score, keep rewards. Default.
			}
			else if (startMode == 2)
			{
				// Keep only the bar fraction, drop the total.
				if (fullRewardScore > 0)
					sp.score = sp.score % fullRewardScore;
				sp.displayScore = sp.score;
			}
		}

		if (CVBool("rs_score_debug", false))
		{
			Console.Printf("\c[Gold]RS_Score:\c- %d monsters, %d total points, avg %d",
				mapTotalMonsters, mapTotalPoints, avg);
			Console.Printf("\c[Gold]RS_Score:\c- reward threshold = %d", fullRewardScore);
		}
	}

	// -----------------------------------------------------------------
	// Base points for a kill.
	//
	// Tier is the real difficulty signal in this project, so it drives
	// the value -- HP alone would rank a bullet-sponge above a genuinely
	// dangerous monster. Plain Doom actors and other mods
	// fall back to SpawnHealth, so the system still works on an
	// unmodified or foreign bestiary.
	// -----------------------------------------------------------------
	static int BasePointsFor(Actor mo)
	{
		if (!mo)
			return 0;

		// TIER WEIGHTING REMOVED 2026-08-05. It multiplied a kill's value
		// by the monster's tier, and there is no tier system. A vanilla
		// monster's SpawnHealth() is its real maximum, and hit points are
		// now the whole measure of what a kill was worth -- which reads
		// correctly across the vanilla bestiary on its own: an Imp is 60,
		// a Cyberdemon is 4000.
		return mo.SpawnHealth();
	}

	// -----------------------------------------------------------------
	// Kill scoring.
	// -----------------------------------------------------------------
	override void WorldThingDied(WorldEvent e)
	{
		if (!ScoreEnabled())
			return;

		Actor victim = e.Thing;
		if (!victim || !victim.bIsMonster)
			return;

		// Respect the SAME payout policy as Kill Rewards. Without this
		// the Pain Elemental's deliberately-infinite escort and every
		// transient boss stage become a score farm. RS_Bits documents
		// this gate; score has to honor it or the two systems disagree
		// about what a kill is.
		// SUMMONS PAY NOTHING. Owner ruling 2026-08-07.
		//
		// The RS_SystemsMaster cast that stood here was DEAD: no monster
		// in the tree implements that contract, so it always returned
		// null and every summon in the game scored full points. A Pain
		// Elemental is an infinite score fountain.
		//
		// RS_SummonMarker marks anything that became a monster after the
		// map was built -- see its header for why a kill-time master
		// check cannot work (the engine's own A_PainShootSkull sets no
		// master at all).
		if (!RS_SummonMarker.PaysRewards(victim))
			return;

		// C01 (Dark Red) elite REMAINS never score. Owner ruling
		// 2026-08-07, and the same exclusion RS_Bits.zs now carries -- the
		// two systems have to agree about what a kill is.
		//
		// C01 leaves a shootable, +ISMONSTER corpse you must destroy to
		// stop it returning. Destroying it fired this handler and scored a
		// second time for one elite. The corpse has to stay a real monster
		// for the mechanic to work, and RS_EliteFX.zs is protected, so the
		// fix belongs on the counting side.
		if (victim is "RS_EliteFX_Corpse")
			return;

		int basePoints = BasePointsFor(victim);
		if (basePoints <= 0)
			return;

		// Walk to the real killer: a rocket's killer is whoever fired it,
		// and a rocket fired by a summon belongs to whoever summoned it.
		//
		// WALKS `master` TOO, added 2026-08-07. The loop used to follow
		// only bMissile->target, which misses two whole categories:
		//
		//   * A BARREL. Shoot a barrel, it kills three monsters, you get
		//     nothing -- a barrel is not a missile, so the walk stopped
		//     on it, and HandleNonPlayerKill's own gate then rejected it
		//     for not being a monster either. Barrels carry their
		//     detonator as `target`.
		//   * A FRIENDLY MONSTER or a summon that is not itself a
		//     missile. Same dead end.
		//
		// Every RS projectile also sets master = the firing weapon, so
		// following master closes the case where a round outlives the
		// gun that fired it.
		//
		// Bounded at 8 hops: a master/target chain can be cyclic (a
		// summon whose master is a summon whose master is the first),
		// and an unbounded walk there is a hang, not a wrong score.
		Actor killer = e.Inflictor ? e.Inflictor : victim.target;
		for (int hops = 0; hops < 8 && killer && !killer.player; hops++)
		{
			if (killer.bMissile && killer.target)      killer = killer.target;
			else if (killer.master && killer.master != killer) killer = killer.master;
			else if (killer.target && killer.target.player)    killer = killer.target;
			else break;
		}

		// Monster died to something that isn't a player.
		PlayerInfo pi = killer ? killer.player : null;
		if (!pi)
		{
			HandleNonPlayerKill(victim, killer, basePoints);
			return;
		}

		int pln = killer.PlayerNumber();
		let sp = Get(pln);
		if (!sp)
			return;

		int now = level.maptime;
		PlayerPawn pawn = PlayerPawn(killer);

		// --- gather the situational multipliers ----------------------
		double mSpree       = MultSpree(sp, now);
		double mUntouchable = MultUntouchable(sp, basePoints);
		double mSwitcharoo  = MultSwitcharoo(sp, victim, now);
		double mScrapping   = MultScrapping(pi);
		double mCurveball   = MultCurveball(victim, killer);
		double mAir         = MultAir(sp, killer);
		double mRedline     = MultRedline(killer);
		double mSwanSong    = MultSwanSong(killer);
		double mPointBlank  = MultPointBlank(victim, killer);
		double mBrawler     = MultBrawler(pi);
		double mTelefrag    = MultTelefrag(e);
		double mGiantSlayer = MultGiantSlayer(victim);

		int pSpree       = int(basePoints * mSpree);
		int pUntouchable = int(basePoints * mUntouchable);
		int pSwitcharoo  = int(basePoints * mSwitcharoo);
		int pScrapping   = int(basePoints * mScrapping);
		int pCurveball   = int(basePoints * mCurveball);
		int pAir         = int(basePoints * mAir);
		int pRedline     = int(basePoints * mRedline);
		int pSwanSong    = int(basePoints * mSwanSong);
		int pPointBlank  = int(basePoints * mPointBlank);
		int pBrawler     = int(basePoints * mBrawler);
		int pTelefrag    = int(basePoints * mTelefrag);
		int pGiantSlayer = int(basePoints * mGiantSlayer);

		int total = basePoints
			+ pSpree + pUntouchable + pSwitcharoo + pScrapping + pCurveball
			+ pAir + pRedline + pSwanSong + pPointBlank + pBrawler
			+ pTelefrag + pGiantSlayer;

		int before = sp.score;
		sp.score += total;
		sp.flashAge = 0;

		sp.AddBonus(RS_ScoreDefs.RS_SB_BASE,         basePoints,   now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_SPREE,        pSpree,       now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_UNTOUCHABLE,  pUntouchable, now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_SWITCHAROO,   pSwitcharoo,  now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_SCRAPPING,    pScrapping,   now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_CURVEBALL,    pCurveball,   now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_AIR,          pAir,         now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_REDLINE,      pRedline,     now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_SWANSONG,     pSwanSong,    now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_POINTBLANK,   pPointBlank,  now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_BRAWLER,      pBrawler,     now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_TELEFRAG,     pTelefrag,    now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_GIANTSLAYER,  pGiantSlayer, now);

		// Streak bookkeeping AFTER scoring, so a kill never counts its
		// own contribution to the streak it just started.
		AddSpree(sp, basePoints, now);
		AddUntouchable(sp, basePoints);

		CheckRewards(pln, before, sp.score);
	}

	// Infighting and self-destruction still pay -- the joke is that the
	// player gets credit for having arranged it.
	void HandleNonPlayerKill(Actor victim, Actor killer, int basePoints)
	{
		int now = level.maptime;

		bool selfKill = (killer == null) || (killer == victim);
		bool monsterKill = killer && killer.bIsMonster && !killer.bFriendly;

		if (!selfKill && !monsterKill)
			return;

		int id = selfKill ? RS_ScoreDefs.RS_SB_DARWIN : RS_ScoreDefs.RS_SB_INFIGHTER;
		if (!RS_ScoreDefs.BonusEnabled(id))
			return;

		double mult = selfKill
			? CVFloat("rs_score_m_darwin", 2.0)
			: CVFloat("rs_score_m_infighter", 0.2);

		int bonus = int(basePoints * mult);

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;

			let sp = Get(i);
			if (!sp)
				continue;

			int before = sp.score;
			sp.score += basePoints + bonus;
			sp.flashAge = 0;

			sp.AddBonus(RS_ScoreDefs.RS_SB_BASE, basePoints, now);
			sp.AddBonus(id, bonus, now);

			CheckRewards(i, before, sp.score);
		}
	}

	// -----------------------------------------------------------------
	// The multipliers. Each returns a fraction of base points.
	// -----------------------------------------------------------------

	double MultSpree(RS_ScorePlayer sp, int now)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_SPREE))
			return 0;

		if (now > sp.spreeExpire)
		{
			sp.spreeCount = 0;
			return 0;
		}

		double inc = CVFloat("rs_score_m_spree", 0.025);
		double cap = CVFloat("rs_score_m_spree_max", 0.25);
		return min(cap, inc * sp.spreeCount);
	}

	void AddSpree(RS_ScorePlayer sp, int basePoints, int now)
	{
		int add = clamp(SPREE_TICS_PER_100HP * basePoints / 100,
						SPREE_MIN_TICS, SPREE_MAX_TICS);
		sp.spreeCount++;
		sp.spreeExpire = now + add;
	}

	// Kill without being touched. Two independent triggers (enough
	// kills OR enough damage dealt) so it fires on a long clean stretch
	// of small fry and on one clean fight with something huge.
	double MultUntouchable(RS_ScorePlayer sp, int basePoints)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_UNTOUCHABLE))
			return 0;

		int needKills = max(1, CVInt("rs_score_ut_kills", 20));
		int needDamage = max(1, CVInt("rs_score_ut_damage", 2000));

		if (sp.utKills < needKills && sp.utDamage < needDamage)
			return 0;

		int div = max(1, CVInt("rs_score_ut_hpdiv", 400));
		sp.utStacks += 1 + (basePoints / div);

		int maxStacks = max(1, CVInt("rs_score_ut_maxstacks", 20));
		double maxMult = CVFloat("rs_score_m_untouchable", 0.5);

		return (maxMult * min(sp.utStacks, maxStacks)) / maxStacks;
	}

	void AddUntouchable(RS_ScorePlayer sp, int basePoints)
	{
		sp.utKills++;
		sp.utDamage += basePoints;
	}

	// Switcharoo: 2+ weapons, or failing that 2+ fire modes, inside a
	// short window scaled off the victim's size (AMBI_TICS_PER_100HP 24,
	// clamped 72..144).
	//
	// On a dual-wield chassis that condition is naturally
	// mainhand-then-offhand, so it lands on the signature move without
	// having to be aimed at it. That observation once got the bonus
	// renamed AMBIDEXTROUS; the observation was right, the rename was
	// not.
	//
	// Detection costs nothing per weapon: TrackWeapons samples
	// pi.cmd.buttons in WorldTick, so no weapon file is touched and this
	// works on weapons we did not write.
	double MultSwitcharoo(RS_ScorePlayer sp, Actor victim, int now)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_SWITCHAROO))
			return 0;

		int hp = BasePointsFor(victim);
		int window = clamp(AMBI_TICS_PER_100HP * hp / 100,
						   AMBI_MIN_TICS, AMBI_MAX_TICS);
		int cutoff = now - window;

		bool twoWeapons = (sp.lastWeaponA != 'None')
			&& (sp.lastWeaponB != 'None')
			&& (sp.lastWeaponA != sp.lastWeaponB)
			&& (sp.lastWeaponATime >= cutoff)
			&& (sp.lastWeaponBTime >= cutoff);

		if (twoWeapons)
			return CVFloat("rs_score_m_switcharoo", 0.15);

		bool twoModes = (sp.lastPrimaryTime >= cutoff)
			&& (sp.lastAltTime >= cutoff);

		if (twoModes)
			return CVFloat("rs_score_m_switcharoo", 0.15) * 0.5;

		return 0;
	}

	// "You did it the hard way, with bad equipment." This project ranks
	// equipment, so any weapon at Basic or below counts.
	//
	// OFF BY DEFAULT (rs_score_b_scrapping) -- see CVARINFO for why.
	double MultScrapping(PlayerInfo pi)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_SCRAPPING))
			return 0;

		let w = RS_Weapon(pi.ReadyWeapon);
		if (!w)
			return 0;

		if (w.Tier <= VRT_Basic)
			return CVFloat("rs_score_m_scrapping", 0.125);

		return 0;
	}

	// It never saw you coming. CheckSight with SF_IGNOREVISIBILITY asks
	// about geometry alone, so darkness and invisibility do not
	// manufacture a Curveball out of a fight the monster was fully aware
	// of.
	double MultCurveball(Actor victim, Actor killer)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_CURVEBALL))
			return 0;

		if (!victim || !killer)
			return 0;

		if (victim.CheckSight(killer, SF_IGNOREVISIBILITY))
			return 0;

		return CVFloat("rs_score_m_curveball", 0.2);
	}

	double MultAir(RS_ScorePlayer sp, Actor killer)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_AIR))
			return 0;

		double height = sp.airPeak - AIR_MIN_HEIGHT;
		if (height <= 0)
			return 0;

		double per = CVFloat("rs_score_m_air", 0.005);
		double cap = CVFloat("rs_score_m_air_max", 2.0);
		return min(cap, height * per);
	}

	// Killing while nearly dead yourself, scaling with how close to the
	// edge you were.
	double MultRedline(Actor killer)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_REDLINE))
			return 0;

		if (killer.health <= 0)
			return 0;

		int threshold = max(1, CVInt("rs_score_redline_hp", 25));
		if (killer.health > threshold)
			return 0;

		double per = CVFloat("rs_score_m_redline", 0.02);
		return per * (threshold - killer.health + 1);
	}

	// Killing something after you are already dead. Overrides Redline
	// naturally, since health <= 0 fails Redline's own test.
	double MultSwanSong(Actor killer)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_SWANSONG))
			return 0;

		if (killer.health > 0)
			return 0;

		return CVFloat("rs_score_m_swansong", 3.0);
	}

	double MultPointBlank(Actor victim, Actor killer)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_POINTBLANK))
			return 0;

		// Edge-to-edge, not center-to-center: a Cyberdemon's center is
		// far away even when you are standing on its toes.
		double dist = victim.Distance3D(killer) - victim.radius - killer.radius;
		double limit = CVFloat("rs_score_pointblank_dist", POINTBLANK_DIST);

		if (dist > limit)
			return 0;

		return CVFloat("rs_score_m_pointblank", 0.1);
	}

	double MultBrawler(PlayerInfo pi)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_BRAWLER))
			return 0;

		if (!pi.ReadyWeapon)
			return 0;

		if (!RS_ScoreDefs.IsMeleeWeaponName(pi.ReadyWeapon.GetClassName()))
			return 0;

		return CVFloat("rs_score_m_brawler", 0.5);
	}

	double MultTelefrag(WorldEvent e)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_TELEFRAG))
			return 0;

		if (e.DamageType != 'Telefrag')
			return 0;

		return CVFloat("rs_score_m_telefrag", 1.0);
	}

	// GIANT SLAYER, REBUILT FOR VANILLA 2026-08-05.
	//
	// It used to read "is this monster's TIER >= N", which was this
	// project's own difficulty statement. There is no tier system, so
	// the bonus now measures the thing it was always a proxy for: how
	// big was the thing you killed. Vanilla's own health values are a
	// perfectly good difficulty ladder --
	//     Imp 60 | Cacodemon 400 | Baron 1000 | Mastermind 3000 | Cyber 4000
	// so the gate is hit points, and the payout scales with how far past
	// the gate it was.
	double MultGiantSlayer(Actor mon)
	{
		if (!mon)
			return 0;

		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_GIANTSLAYER))
			return 0;

		int gate = CVInt("rs_score_giantslayer_hp", 700);
		int hp   = mon.SpawnHealth();
		if (hp < gate)
			return 0;

		double per = CVFloat("rs_score_m_giantslayer", 0.15);
		return per * (1.0 + double(hp - gate) / double(max(1, gate)));
	}

	// -----------------------------------------------------------------
	// Untouchable breaks when the player is hit.
	// -----------------------------------------------------------------
	override void WorldThingDamaged(WorldEvent e)
	{
		Actor t = e.Thing;
		if (!t || !t.player)
			return;

		if (e.Damage <= 0)
			return;

		let sp = Get(t.PlayerNumber());
		if (!sp)
			return;

		sp.utKills = 0;
		sp.utDamage = 0;
		sp.utStacks = 0;
	}

	// -----------------------------------------------------------------
	// Per-tic upkeep.
	// -----------------------------------------------------------------
	override void WorldTick()
	{
		if (!ScoreEnabled())
			return;

		int now = level.maptime;

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;

			let sp = Get(i);
			if (!sp)
				continue;

			Actor pmo = PawnFor(i);
			if (!pmo)
				continue;

			TrackAir(sp, pmo);
			TrackWeapons(sp, pmo, now);
			// TickLives REMOVED 2026-08-07. The CF_BUDDHA revival that lived
			// here is superseded by RS_ScoreLives.zs / RS_LifeForce, which
			// intercepts damage in AbsorbDamage BEFORE the engine subtracts
			// health -- no cheat flags, no resurrection, so weapon state and
			// VR hand poses survive a save.
			//
			// It had to be DELETED rather than left switched off: its own
			// disabled branch still ran `pi.cheats &= ~CF_BUDDHA` every tic,
			// so even with rs_score_lives_enable off it silently cancelled a
			// `buddha` the player had typed themselves, or any other mod's
			// grant. sp.extraLives survives as the HUD's readout and is now
			// written by the new system.
			TickDisplay(sp);
			TickRegen(i, sp, pmo);
			ExpireBonuses(sp, now);

			// Age the flash rather than clearing it. Advancing it here
			// rather than in the HUD keeps RenderOverlay read-only, which
			// matters because it runs at frame rate, not tic rate -- the
			// old code cleared a bool here and so the afterglow was one
			// tic long no matter what the HUD tried to draw.
			if (sp.flashAge >= 0)
				sp.flashAge++;
		}
	}

	static Actor PawnFor(int i)
	{
		if (i < 0 || i >= MAXPLAYERS)
			return null;
		if (!playeringame[i])
			return null;
		return players[i].mo;
	}

	// Track the peak height of the current jump, measured from the floor
	// we left rather than from wherever the ground is now -- otherwise
	// dropping down a shaft would read as a spectacular leap.
	void TrackAir(RS_ScorePlayer sp, Actor mo)
	{
		bool grounded = (mo.pos.z <= mo.floorz) || mo.waterlevel > 0;

		if (grounded)
		{
			sp.airFloorZ = mo.pos.z;
			sp.airPeak = 0;
		}
		else
		{
			double h = mo.pos.z - sp.airFloorZ;
			if (h > sp.airPeak)
				sp.airPeak = h;
		}
	}

	// Sample which weapon and fire mode is being used, with no edits to
	// any weapon class. Reading button state here costs nothing per
	// weapon and works on weapons we did not write -- the alternative is
	// a hook in every fire state of every gun, which rots the moment
	// someone adds a weapon and forgets.
	// SWITCHAROO now counts the OFFHAND as a switch. Owner ruling
	// 2026-08-07 ("get switcharoo to work, or rename it, or make a new
	// thing that does the thing") -- so it was made to work.
	//
	// It used to sample BT_ATTACK / BT_ALTATTACK and read only
	// pi.ReadyWeapon, which on a dual-wield mod meant the offhand was
	// invisible to it: the engine fires the offhand on its own button
	// bit, BT_OFFHANDATTACK (player.zs:463-479, which never sets
	// BT_ATTACK), holding a different weapon in a different slot. So
	// pulling the left trigger recorded NOTHING -- the function returned
	// at the buttons check -- and the one bonus named after switching
	// could never be paid by switching hands, on the mod whose entire
	// identity is two guns.
	//
	// Both hands now feed the same A/B weapon slots, so all three of
	// these read as a switcharoo: mainhand -> other mainhand, primary ->
	// alt fire, and mainhand -> offhand.
	void TrackWeapons(RS_ScorePlayer sp, Actor mo, int now)
	{
		let pi = mo.player;
		if (!pi)
			return;

		bool firing    = (pi.cmd.buttons & BT_ATTACK) != 0;
		bool altFiring = (pi.cmd.buttons & BT_ALTATTACK) != 0;
		bool offFiring = (pi.cmd.buttons & BT_OFFHANDATTACK) != 0;

		if (!firing && !altFiring && !offFiring)
			return;

		if (firing)
			sp.lastPrimaryTime = now;
		if (altFiring)
			sp.lastAltTime = now;
		// The offhand counts as an alternate attack for the primary/alt
		// half of the bonus as well -- it IS the other trigger.
		if (offFiring)
			sp.lastAltTime = now;

		// Which weapon this pull actually came from. The offhand check is
		// first: if both triggers are down on the same tic the offhand is
		// the newer information, since the mainhand will keep re-stamping
		// itself for as long as it is held.
		Weapon fired = null;
		if (offFiring && pi.OffhandWeapon)
			fired = pi.OffhandWeapon;
		else if ((firing || altFiring) && pi.ReadyWeapon)
			fired = pi.ReadyWeapon;

		if (!fired)
			return;

		Name wn = fired.GetClassName();

		if (wn == sp.lastWeaponA)
		{
			sp.lastWeaponATime = now;
		}
		else if (wn == sp.lastWeaponB)
		{
			sp.lastWeaponBTime = now;
		}
		else
		{
			// New weapon -- push A into B, take A.
			sp.lastWeaponB = sp.lastWeaponA;
			sp.lastWeaponBTime = sp.lastWeaponATime;
			sp.lastWeaponA = wn;
			sp.lastWeaponATime = now;
		}
	}

	// The rolling HUD counter. Score jumps instantly; the displayed
	// number chases it, which is most of why arcade scoring feels good.
	void TickDisplay(RS_ScorePlayer sp)
	{
		if (sp.displayScore == sp.score)
			return;

		int diff = sp.score - sp.displayScore;
		int step = max(1, abs(diff) / 8);

		if (diff > 0)
			sp.displayScore = min(sp.score, sp.displayScore + step);
		else
			sp.displayScore = max(sp.score, sp.displayScore - step);
	}

	void ExpireBonuses(RS_ScorePlayer sp, int now)
	{
		int life = clamp(CVInt("rs_score_bonustime", 105), 35, 350);

		for (int i = 0; i < sp.bonusTime.Size(); i++)
		{
			if (sp.bonusTime[i] < 0)
				continue;

			if (now - sp.bonusTime[i] >= life)
			{
				sp.bonusValue[i] = 0;
				sp.bonusTime[i] = -1;
			}
		}
	}

	// -----------------------------------------------------------------
	// Rewards.
	// -----------------------------------------------------------------
	void CheckRewards(int pln, int before, int after)
	{
		if (fullRewardScore <= 0)
			return;

		if (!CVBool("rs_score_rewards_enable", true))
			return;

		int wasCount = before / fullRewardScore;
		int nowCount = after / fullRewardScore;
		int earned = nowCount - wasCount;

		if (earned <= 0)
			return;

		let sp = Get(pln);
		if (!sp)
			return;

		Actor mo = PawnFor(pln);
		int mode = CVInt("rs_score_rewardmode", 0);
		int newLives = 0;

		for (int i = 0; i < earned; i++)
		{
			bool giveLife;

			switch (mode)
			{
				default:
				case 0:  giveLife = (sp.rewardCount % 2) == 1; break; // alternate, regen first
				case 1:  giveLife = (sp.rewardCount % 2) == 0; break; // alternate, life first
				case 2:  giveLife = false; break;                    // regen only
				case 3:  giveLife = true;  break;                    // lives only
			}

			if (giveLife)
			{
				sp.extraLives++;
				newLives++;
			}
			else
			{
				sp.regenTimer += CVInt("rs_score_regen_tics", 700) + 1;
			}

			sp.rewardCount++;
		}

		if (mo)
		{
			mo.A_StartSound(CVBool("rs_score_sound", true) ? "misc/secret" : "", CHAN_AUTO);

			if (newLives > 0 && CVBool("rs_score_sound", true))
				mo.A_StartSound("misc/i_pkup", CHAN_ITEM);
		}
	}

	// Ammo regen trickles into whatever the player is holding rather
	// than dumping a pickup, so it reads as a state you are in and not an
	// item you got.
	void TickRegen(int pln, RS_ScorePlayer sp, Actor mo)
	{
		if (sp.regenTimer <= 0)
		{
			sp.regenSpent = 0;
			return;
		}

		sp.regenTimer--;
		sp.regenSpent++;

		int period = max(1, CVInt("rs_score_regen_period", 7));
		if ((sp.regenSpent % period) != 0)
			return;

		let pi = mo.player;
		if (!pi || !pi.ReadyWeapon)
			return;

		int amount = max(1, CVInt("rs_score_regen_amount", 1));

		if (pi.ReadyWeapon.Ammo1)
			pi.ReadyWeapon.Ammo1.Amount =
				min(pi.ReadyWeapon.Ammo1.MaxAmount, pi.ReadyWeapon.Ammo1.Amount + amount);

		if (CVBool("rs_score_regen_secondary", true) && pi.ReadyWeapon.Ammo2)
			pi.ReadyWeapon.Ammo2.Amount =
				min(pi.ReadyWeapon.Ammo2.MaxAmount, pi.ReadyWeapon.Ammo2.Amount + amount);
	}

	// -----------------------------------------------------------------
	// Extra lives / revival.
	//
	// While a life is banked the player is put in BUDDHA, so lethal
	// damage parks them at 1hp instead of killing them, and catching that
	// 1hp state is the revive. Resurrecting an already-dead pawn is the
	// obvious alternative and it is worse -- it loses the weapon state
	// and looks wrong.

	// -----------------------------------------------------------------
	// HUD. Same shape GunBonsai's handler uses (EventHandler.zsc:123):
	// RenderOverlay lives on the handler and delegates to a drawing
	// class, so all the ui-scope work sits in one object.
	// -----------------------------------------------------------------
	// `ui`, not a plain field: RenderOverlay runs in ui scope and
	// assigns this on first draw. An unmarked (play-scoped) field
	// cannot be written from ui and is a compile error, not a runtime
	// one. GunBonsai's handler declares its own the same way
	// (EventHandler.zsc:12).
	ui RS_ScoreHUD hud;

	ui bool ShouldDrawHUD() const
	{
		if (!CVBool("rs_score_enable", true))
			return false;
		if (!CVBool("rs_score_hud_enable", true))
			return false;
		if (!playeringame[consoleplayer])
			return false;
		if (automapactive && !CVBool("rs_score_hud_onautomap", false))
			return false;

		// Match the engine's own HUD-hiding convention.
		return screenblocks <= 11;
	}

	override void RenderOverlay(RenderEvent e)
	{
		if (!ShouldDrawHUD())
			return;

		let sp = Get(consoleplayer);
		if (!sp)
			return;

		if (!hud)
			hud = new("RS_ScoreHUD");

		hud.Draw(sp, fullRewardScore, level.maptime);
	}

	// -----------------------------------------------------------------
	// Console access. Read-only reporting plus debug grants.
	// -----------------------------------------------------------------
	override void NetworkProcess(ConsoleEvent e)
	{
		int pln = e.Player;
		let sp = Get(pln);
		if (!sp)
			return;

		if (e.Name == "rs_score_report")
		{
			Console.Printf("\c[Gold]--- RS Score ---\c-");
			Console.Printf("Score: %d   Next reward at: %d",
				sp.score, fullRewardScore > 0 ? ((sp.score / fullRewardScore) + 1) * fullRewardScore : 0);
			Console.Printf("Rewards taken: %d   Extra lives: %d   Regen: %d tics",
				sp.rewardCount, sp.extraLives, sp.regenTimer);
			Console.Printf("Spree: %d   Untouchable: %d kills / %d dmg",
				sp.spreeCount, sp.utKills, sp.utDamage);
			Console.Printf("Map: %d monsters, %d points, threshold %d",
				mapTotalMonsters, mapTotalPoints, fullRewardScore);
		}
		else if (e.Name == "rs_score_add")
		{
			int before = sp.score;
			sp.score += e.Args[0];
			CheckRewards(pln, before, sp.score);
		}
		else if (e.Name == "rs_score_reset")
		{
			sp.ResetRun(true);
			Console.Printf("\c[Gold]RS_Score:\c- reset.");
		}
	}
}
