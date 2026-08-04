// =====================================================================
// RS_Score -- arcade scoring. The foundations of a style-kill system.
// ---------------------------------------------------------------------
// Conceptually ported from dakka (0dot0repeating/dakka, pk3/acs/score/),
// which is ACS built for Zandronum. This is a ZScript rebuild, not a
// transliteration: the ACS original spends most of its length working
// around limits we do not have (a flat `global int 22:MapScoreData[]`
// with hand-computed player strides because ACS has no structs, a
// manual server->client data sender because Zandronum has no play/ui
// scope, TID juggling with Thing_ChangeTID to walk the killer pointer,
// three Warp() calls to fake a multi-height line-of-sight test). All of
// that is gone. The DESIGN is what was worth taking:
//
//   base points for a kill, then independent situational multipliers
//   that stack, grouped into flavors, each announcing itself on the HUD
//   the instant it pays.
//
// WHAT THIS SYSTEM DELIBERATELY DOES NOT DO
//   It does not grant permanent power. Promotion owns permanent growth
//   and Gun Bonsai owns weapon growth; score pays out in CONSUMABLES
//   (extra lives, ammo regen) and optionally trickles into the existing
//   Gold economy. That keeps it clear of the rule in CLAUDE.md about
//   never duplicating a design space another mechanic already owns.
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
	const RS_SB_BASE        = 0;
	const RS_SB_SPREE       = 1;
	const RS_SB_UNTOUCHABLE = 2;
	const RS_SB_INFIGHTER   = 3;
	const RS_SB_AMBIDEXTROUS= 4;
	const RS_SB_SCRAPPING   = 5;
	const RS_SB_TELEFRAG    = 6;
	const RS_SB_BLINDSIDE   = 7;
	const RS_SB_DARWIN      = 8;
	const RS_SB_AIRBORNE    = 9;
	const RS_SB_REDLINE     = 10;
	const RS_SB_SWANSONG    = 11;
	const RS_SB_POINTBLANK  = 12;
	const RS_SB_BRAWLER     = 13;
	const RS_SB_GIANTSLAYER = 14;
	const RS_SB_COUNT       = 15;

	// Flavor groups, dakka's three plus one of ours. Purely a color/
	// readability device -- nothing keys off the group mechanically.
	const RS_SF_BASE       = 0;
	const RS_SF_EFFICIENCY = 1;
	const RS_SF_STYLE      = 2;
	const RS_SF_DARING     = 3;

	// Comparison chains, never `static const string x[] = {...}` --
	// that form does not resolve reliably on this engine build (see
	// CLAUDE.md; it has been rediscovered three times).
	static string BonusName(int id)
	{
		switch (id)
		{
			case RS_SB_BASE:         return "";
			case RS_SB_SPREE:        return "SPREE";
			case RS_SB_UNTOUCHABLE:  return "UNTOUCHABLE";
			case RS_SB_INFIGHTER:    return "INFIGHTER";
			case RS_SB_AMBIDEXTROUS: return "AMBIDEXTROUS";
			case RS_SB_SCRAPPING:    return "SCRAPPING";
			case RS_SB_TELEFRAG:     return "TELEFRAG";
			case RS_SB_BLINDSIDE:    return "BLINDSIDE";
			case RS_SB_DARWIN:       return "DARWIN";
			case RS_SB_AIRBORNE:     return "AIRBORNE";
			case RS_SB_REDLINE:      return "REDLINE";
			case RS_SB_SWANSONG:     return "SWAN SONG";
			case RS_SB_POINTBLANK:   return "POINT-BLANK";
			case RS_SB_BRAWLER:      return "BRAWLER";
			case RS_SB_GIANTSLAYER:  return "GIANT SLAYER";
		}
		return "";
	}

	static int BonusFlavor(int id)
	{
		switch (id)
		{
			case RS_SB_BASE:
				return RS_SF_BASE;

			case RS_SB_SPREE:
			case RS_SB_UNTOUCHABLE:
			case RS_SB_INFIGHTER:
				return RS_SF_EFFICIENCY;

			case RS_SB_AMBIDEXTROUS:
			case RS_SB_SCRAPPING:
			case RS_SB_TELEFRAG:
			case RS_SB_BLINDSIDE:
			case RS_SB_DARWIN:
			case RS_SB_AIRBORNE:
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
	static string BonusCVar(int id)
	{
		switch (id)
		{
			case RS_SB_SPREE:        return "rs_score_b_spree";
			case RS_SB_UNTOUCHABLE:  return "rs_score_b_untouchable";
			case RS_SB_INFIGHTER:    return "rs_score_b_infighter";
			case RS_SB_AMBIDEXTROUS: return "rs_score_b_ambidextrous";
			case RS_SB_SCRAPPING:    return "rs_score_b_scrapping";
			case RS_SB_TELEFRAG:     return "rs_score_b_telefrag";
			case RS_SB_BLINDSIDE:    return "rs_score_b_blindside";
			case RS_SB_DARWIN:       return "rs_score_b_darwin";
			case RS_SB_AIRBORNE:     return "rs_score_b_airborne";
			case RS_SB_REDLINE:      return "rs_score_b_redline";
			case RS_SB_SWANSONG:     return "rs_score_b_swansong";
			case RS_SB_POINTBLANK:   return "rs_score_b_pointblank";
			case RS_SB_BRAWLER:      return "rs_score_b_brawler";
			case RS_SB_GIANTSLAYER:  return "rs_score_b_giantslayer";
		}
		return "";
	}

	static bool BonusEnabled(int id)
	{
		if (id == RS_SB_BASE)
			return true;

		string cv = BonusCVar(id);
		if (cv == "")
			return true;

		let c = CVar.GetCVar(cv, null);
		return c ? c.GetBool() : true;
	}

	// Melee identification. dakka carried a 13-row table of weapon
	// names and damage types; ours is a name test because every melee
	// weapon in this project is an RS_ class with a predictable name.
	static bool IsMeleeWeaponName(Name wpn)
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
// One of these per player slot. A real object rather than the ACS
// original's parallel-array-with-stride arithmetic.
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

	// Spree (dakka: killstreak)
	int spreeCount;
	int spreeExpire;

	// Untouchable
	int utKills;
	int utDamage;
	int utStacks;

	// Airborne
	double airFloorZ;
	double airPeak;

	// Ambidextrous -- last-fired timestamps
	Name lastWeaponA;
	Name lastWeaponB;
	int  lastWeaponATime;
	int  lastWeaponBTime;
	int  lastPrimaryTime;
	int  lastAltTime;

	// Per-bonus popup state
	Array<int> bonusValue;
	Array<int> bonusTime;

	// True on the tic a kill scored, so the HUD can flash.
	bool flashPulse;

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
	// Tuning constants ported from dakka's score_defs.h. Where dakka
	// hardcoded them, most are cvars here -- "granular controls over
	// everything" was the brief. These remain fixed because they are
	// shape, not preference.
	const SPREE_TICS_PER_100HP = 24;
	const SPREE_MIN_TICS       = 72;
	const SPREE_MAX_TICS       = 360;

	const AMBI_TICS_PER_100HP  = 24;
	const AMBI_MIN_TICS        = 72;
	const AMBI_MAX_TICS        = 144;

	const AIR_MIN_HEIGHT       = 64.0;
	const POINTBLANK_DIST      = 96.0;

	// NOT named `players` -- that identifier is the engine's global
	// player array, and shadowing it here silently breaks every
	// players[i].mo lookup in this class.
	Array<RS_ScorePlayer> scorePlayers;

	// Per-map reward threshold, calibrated at load from the map's own
	// monster population -- dakka's best idea, and the thing that makes
	// the reward bar mean the same thing on MAP01 and on a slaughtermap.
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

	RS_ScorePlayer Get(int pln)
	{
		if (pln < 0 || pln >= scorePlayers.Size())
			return null;
		return scorePlayers[pln];
	}

	bool ScoreEnabled() const
	{
		let c = CVar.GetCVar("rs_score_enable", null);
		return c ? c.GetBool() : true;
	}

	static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	static double CVFloat(string name, double def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetFloat() : def;
	}

	static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	// -----------------------------------------------------------------
	// Map load -- calibrate the reward threshold.
	//
	// dakka summed every monster's SpawnHealth. We have something
	// better: RS monsters carry an explicit Tier and a TierMaxHealth,
	// so the population can be weighted by how dangerous it actually
	// is rather than by raw hit points. A T12 monster and a pile of
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
	// dangerous elite. Non-RS monsters (other mods, plain Doom actors)
	// fall back to SpawnHealth, which is exactly dakka's rule, so the
	// system still works on an unmodified bestiary.
	// -----------------------------------------------------------------
	static int BasePointsFor(Actor mo)
	{
		if (!mo)
			return 0;

		int hp = mo.SpawnHealth();

		let rsmon = RS_MonsterMaster(mo);
		if (rsmon)
		{
			if (rsmon.TierMaxHealth > 0)
				hp = rsmon.TierMaxHealth;

			// Tier weighting: each tier above T00 is worth a little
			// more than its hit points suggest. Multiplicative and
			// gentle -- at the default 0.12 a TEX (13) monster is
			// worth ~2.5x its HP, a T03 ~1.36x.
			double per = CVFloat("rs_score_tierweight", 0.12);
			double mult = 1.0 + (per * rsmon.Tier);
			return int(hp * mult);
		}

		return hp;
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
		let rsmon = RS_MonsterMaster(victim);
		if (rsmon && (rsmon.IsSummonedMinion() || rsmon.IsTransientStage()))
			return;

		int basePoints = BasePointsFor(victim);
		if (basePoints <= 0)
			return;

		// Walk to the real killer. dakka did this with TID swapping and
		// a MISSILE-flag loop; e.Inflictor/target gives it to us
		// directly.
		Actor killer = e.Inflictor ? e.Inflictor : victim.target;
		while (killer && killer.bMissile && killer.target)
			killer = killer.target;

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
		double mAmbi        = MultAmbidextrous(sp, victim, now);
		double mScrapping   = MultScrapping(pi);
		double mBlindside   = MultBlindside(victim, killer);
		double mAirborne    = MultAirborne(sp, killer);
		double mRedline     = MultRedline(killer);
		double mSwanSong    = MultSwanSong(killer);
		double mPointBlank  = MultPointBlank(victim, killer);
		double mBrawler     = MultBrawler(pi);
		double mTelefrag    = MultTelefrag(e);
		double mGiantSlayer = MultGiantSlayer(rsmon);

		int pSpree       = int(basePoints * mSpree);
		int pUntouchable = int(basePoints * mUntouchable);
		int pAmbi        = int(basePoints * mAmbi);
		int pScrapping   = int(basePoints * mScrapping);
		int pBlindside   = int(basePoints * mBlindside);
		int pAirborne    = int(basePoints * mAirborne);
		int pRedline     = int(basePoints * mRedline);
		int pSwanSong    = int(basePoints * mSwanSong);
		int pPointBlank  = int(basePoints * mPointBlank);
		int pBrawler     = int(basePoints * mBrawler);
		int pTelefrag    = int(basePoints * mTelefrag);
		int pGiantSlayer = int(basePoints * mGiantSlayer);

		int total = basePoints
			+ pSpree + pUntouchable + pAmbi + pScrapping + pBlindside
			+ pAirborne + pRedline + pSwanSong + pPointBlank + pBrawler
			+ pTelefrag + pGiantSlayer;

		int before = sp.score;
		sp.score += total;
		sp.flashPulse = true;

		sp.AddBonus(RS_ScoreDefs.RS_SB_BASE,         basePoints,   now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_SPREE,        pSpree,       now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_UNTOUCHABLE,  pUntouchable, now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_AMBIDEXTROUS, pAmbi,        now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_SCRAPPING,    pScrapping,   now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_BLINDSIDE,    pBlindside,   now);
		sp.AddBonus(RS_ScoreDefs.RS_SB_AIRBORNE,     pAirborne,    now);
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

	// Infighting and self-destruction pay everyone, exactly as in dakka
	// -- the joke is that the player gets credit for arranging it.
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
			sp.flashPulse = true;

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

	// dakka's Switcharoo, reworked for a dual-wield chassis. The
	// original asked "did you fire 2+ weapons, or failing that 2+ fire
	// modes, in a short window". On this project that condition is
	// mainhand-then-offhand, which is the signature move -- so it gets
	// the signature bonus and a name that says what it rewards.
	double MultAmbidextrous(RS_ScorePlayer sp, Actor victim, int now)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_AMBIDEXTROUS))
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
			return CVFloat("rs_score_m_ambidextrous", 0.15);

		bool twoModes = (sp.lastPrimaryTime >= cutoff)
			&& (sp.lastAltTime >= cutoff);

		if (twoModes)
			return CVFloat("rs_score_m_ambidextrous", 0.15) * 0.5;

		return 0;
	}

	// dakka's Scrapping paid you for killing with the Scrapper -- its
	// slot-1 junk gun. The transferable idea is "you did it the hard
	// way, with bad equipment", and this project already ranks
	// equipment: any weapon at Basic or below counts.
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

	// dakka warped the corpse to three heights and ran CheckSight from
	// each because Zandronum gave it nothing better. We can just ask
	// twice -- eye level and feet -- which is the part that mattered.
	double MultBlindside(Actor victim, Actor killer)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_BLINDSIDE))
			return 0;

		if (!victim || !killer)
			return 0;

		if (victim.CheckSight(killer, SF_IGNOREVISIBILITY))
			return 0;

		return CVFloat("rs_score_m_blindside", 0.2);
	}

	double MultAirborne(RS_ScorePlayer sp, Actor killer)
	{
		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_AIRBORNE))
			return 0;

		double height = sp.airPeak - AIR_MIN_HEIGHT;
		if (height <= 0)
			return 0;

		double per = CVFloat("rs_score_m_airborne", 0.005);
		double cap = CVFloat("rs_score_m_airborne_max", 2.0);
		return min(cap, height * per);
	}

	// dakka called this Bone-Dry internally and Redline on the HUD.
	// Kept the HUD name because it is the better one.
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

	// Ours, not dakka's. The tier ladder is the project's own difficulty
	// statement, so killing far up it should read as an achievement in
	// its own right rather than only as more hit points.
	double MultGiantSlayer(RS_MonsterMaster rsmon)
	{
		if (!rsmon)
			return 0;

		if (!RS_ScoreDefs.BonusEnabled(RS_ScoreDefs.RS_SB_GIANTSLAYER))
			return 0;

		int minTier = CVInt("rs_score_giantslayer_tier", 8);
		if (rsmon.Tier < minTier)
			return 0;

		double per = CVFloat("rs_score_m_giantslayer", 0.15);
		return per * (rsmon.Tier - minTier + 1);
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
			TickDisplay(sp);
			TickRegen(i, sp, pmo);
			ExpireBonuses(sp, now);
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

	// Port of dakka's Air_UpdateZHeight -- track the peak height of the
	// current jump, measured from the floor we left.
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
	// any weapon class. dakka needed every weapon's DECORATE to call
	// ACS_NamedExecuteWithResult("Dakka_Switcharoo", slot, mode) on
	// every single fire state; reading the button state here gets the
	// same information for free and works on weapons we did not write.
	void TrackWeapons(RS_ScorePlayer sp, Actor mo, int now)
	{
		let pi = mo.player;
		if (!pi || !pi.ReadyWeapon)
			return;

		bool firing = (pi.cmd.buttons & BT_ATTACK) != 0;
		bool altFiring = (pi.cmd.buttons & BT_ALTATTACK) != 0;

		if (!firing && !altFiring)
			return;

		if (firing)
			sp.lastPrimaryTime = now;
		if (altFiring)
			sp.lastAltTime = now;

		Name wn = pi.ReadyWeapon.GetClassName();

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

	// Ammo regen, ported from dakka's Score_ProcessRewards. It trickles
	// ammo into whatever the player is holding rather than dumping a
	// pickup, so it reads as a state you are in, not an item you got.
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
