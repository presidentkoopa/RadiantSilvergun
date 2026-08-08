// =====================================================================
// RS_ScoreLives -- the extra-life ECONOMY.
//
// The other half of the death-save system. RS_ScoreRevival.zs owns what
// HAPPENS when a life is spent; this file owns how a life is EARNED,
// how many you may hold, whether it survives the exit line, and who
// gets told when the number changes.
//
// THE DESIGN, AS RULED BY THE OWNER 2026-08-07
//   Lives are earned, not handed out. Six independent, independently
//   disableable sources:
//
//     TAKING damage      every N points absorbed buys a life. Rewards
//                        surviving a beating -- the meter fills fastest
//                        exactly when you are most likely to need it.
//     DEALING damage     every N points dealt to monsters buys a life.
//                        Rewards volume, so a slaughter map pays for
//                        itself. Overkill does not count (see below).
//     CLEARING a level   with an optional completion requirement --
//                        all kills, all secrets, either, or both.
//     KILLING a boss     any +BOSS actor.
//     SCORE              two ways: a flat score-per-life meter, and
//                        RS_Score's own reward thresholds, which
//                        already pay lives and are absorbed here so the
//                        two systems cannot double-count.
//     KILL SPREE         a life every N kills in one unbroken streak.
//
// WHY THIS IS A StaticEventHandler AND RS_ScoreHandler IS NOT
//   Verified in the engine, not assumed. EventManager::IsStaticType
//   (events.cpp:549) returns true only for handlers that do NOT descend
//   from DEventHandler, and InitStaticHandlers (events.cpp:590) puts
//   those in the global staticEventManager while everything else goes
//   into Level->localEventManager -- which is Shutdown() and rebuilt on
//   every single map load (p_setup.cpp:475).
//
//   So: a class deriving from `EventHandler` LOSES EVERY FIELD AT THE
//   EXIT LINE. A class deriving from `StaticEventHandler` does not.
//   Lives must survive a level change, so this handler is static.
//   WorldTick is dispatched to static handlers -- events.cpp:1071
//   declares it with DEFINE_EVENT_LOOPER(WorldTick, true), and that
//   macro calls staticEventManager first.
//
// REGISTRATION: this does NOT EXIST at runtime unless MAPINFO.txt lists
// it in GameInfo { AddEventHandlers = ... }. Same trap that left
// RS_MonsterDebug's entire menu dead and that RS_Score.zs warns about
// at the top of its own file. If lives never appear, check MAPINFO
// before reading a line of this file.
// =====================================================================


// ---------------------------------------------------------------------
// One player's ledger. Held by the handler (so it outlives the pawn)
// AND pointed at by the RS_LifeForce on the pawn (so the damage hook
// can reach it without a lookup). Which of the two copies wins on a
// level change is the whole subtlety, and it is handled in
// RS_LivesHandler.InitPlayer.
// ---------------------------------------------------------------------
class RS_LifeInfo : Object play
{
	// Why a life count changed. Drives the wording of the message and
	// nothing else -- but "you earned a life" and "you spent a life"
	// reading identically was one of the things that made the old
	// system impossible to debug by playing it.
	const SRC_NONE          = 0;
	const SRC_START         = 1;
	const SRC_SPENT         = 2;
	const SRC_DAMAGE_TAKEN  = 3;
	const SRC_DAMAGE_DEALT  = 4;
	const SRC_LEVEL         = 5;
	const SRC_BOSS          = 6;
	const SRC_SCORE         = 7;
	const SRC_SPREE         = 8;
	const SRC_CONSOLE       = 9;

	// Completion requirements for the end-of-level bonus.
	const COMPLETION_NONE               = 0;
	const COMPLETION_ALL_KILLS          = 1;
	const COMPLETION_ALL_SECRETS        = 2;
	const COMPLETION_KILLS_OR_SECRETS   = 3;
	const COMPLETION_EITHER_STACKING    = 4;
	const COMPLETION_KILLS_AND_SECRETS  = 5;

	int playerNum;
	int lives;

	// Earning meters. Each is a running remainder, so a partial meter
	// is never thrown away by a level change -- getting most of the way
	// to a life and losing it silently would be the worst possible
	// feel for a system that is supposed to reward persistence.
	int chargeTaken;
	int chargeDealt;
	int chargeScore;

	// Score-system integration bookkeeping.
	int  lastScoreSeen;
	bool scoreSeeded;
	int  spreePaid;
	int  mirroredLives;   // what we last wrote into RS_Score's own field

	// Maps whose clear bonus has already been paid, by checksum, so a
	// hub you re-enter or a level you revisit cannot be farmed.
	Array<string> levelsCleared;

	// Deferred reporting. A burst of grants -- level clear plus the
	// minimum-per-level top-up, say -- coalesces into ONE message and
	// ONE netevent instead of three of each.
	int reportDelay;
	int reportedLives;
	int reportSource;

	RS_LifeForce force;

	static RS_LifeInfo Create(int pln)
	{
		let info = new("RS_LifeInfo");
		info.playerNum = pln;
		info.reportedLives = 0;
		info.GiveStartingLives();
		return info;
	}

	static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	void GiveStartingLives()
	{
		lives = max(0, CVInt("rs_lives_starting", 1));
		chargeTaken = 0;
		chargeDealt = 0;
		chargeScore = 0;
		spreePaid = 0;
		scoreSeeded = false;
		mirroredLives = lives;
		ScheduleReport(SRC_START, 20);
	}

	// -----------------------------------------------------------------
	// The one function that may change `lives`. Everything else routes
	// through here so there is exactly one place that clamps, one place
	// that reports, and one place to put a breakpoint.
	//
	// applyMax only blocks GAINS past the ceiling. It never confiscates
	// lives already held -- a ceiling lowered mid-game, or lives handed
	// over by another mod, must not evaporate.
	// -----------------------------------------------------------------
	void AdjustLives(int delta, bool applyMax, int source)
	{
		if (delta == 0)
			return;

		int oldLives = lives;
		int cap = CVInt("rs_lives_max", 9);

		if (!applyMax || cap <= 0)
			lives = max(0, lives + delta);
		else if (delta < 0 || lives < cap)
			lives = max(0, min(lives + delta, max(cap, lives)));

		// A grant that the ceiling swallowed is not news. Reporting it
		// would put a netevent and a "you gained a life" message on the
		// wire every time a capped player took a hit.
		if (lives != oldLives)
			ScheduleReport(source, source == SRC_SPENT ? 2 : 5);
	}

	void ScheduleReport(int source, int delay)
	{
		// Keep the FIRST source of a coalesced burst unless a spend
		// joins it -- spending a life is always the headline.
		if (reportDelay <= 0 || source == SRC_SPENT)
			reportSource = source;
		reportDelay = max(reportDelay, delay);
	}

	void Report()
	{
		ScheduleReport(SRC_NONE, 5);
	}

	// -----------------------------------------------------------------
	// Earning: damage taken. Fed from RS_LifeForce.AbsorbDamage, which
	// sees the true post-armour number. The hit that TRIGGERS a save is
	// deliberately not counted -- being saved is already the payout.
	// -----------------------------------------------------------------
	void AddDamageTaken(int damage)
	{
		int per = CVInt("rs_lives_damage_taken_per_life", 700);
		if (per <= 0 || damage <= 0)
			return;

		chargeTaken += damage;

		int bonus = 0;
		while (chargeTaken >= per)
		{
			chargeTaken -= per;
			bonus++;
		}

		if (bonus > 0)
			AdjustLives(bonus, true, SRC_DAMAGE_TAKEN);
	}

	void AddDamageDealt(int damage)
	{
		int per = CVInt("rs_lives_damage_dealt_per_life", 10000);
		if (per <= 0 || damage <= 0)
			return;

		chargeDealt += damage;

		int bonus = 0;
		while (chargeDealt >= per)
		{
			chargeDealt -= per;
			bonus++;
		}

		if (bonus > 0)
			AdjustLives(bonus, true, SRC_DAMAGE_DEALT);
	}

	void AddScoreCharge(int points)
	{
		int per = CVInt("rs_lives_score_per_life", 0);
		if (per <= 0 || points <= 0)
			return;

		chargeScore += points;

		int bonus = 0;
		while (chargeScore >= per)
		{
			chargeScore -= per;
			bonus++;
		}

		if (bonus > 0)
			AdjustLives(bonus, true, SRC_SCORE);
	}

	void AddBossKill()
	{
		int n = CVInt("rs_lives_per_boss", 1);
		if (n > 0)
			AdjustLives(n, true, SRC_BOSS);
	}

	// -----------------------------------------------------------------
	// Earning: clearing a level.
	// -----------------------------------------------------------------
	bool LevelSeen(string md5)
	{
		return levelsCleared.Find(md5) != levelsCleared.Size();
	}

	// 0 = no bonus, 1 = the normal bonus, 2 = the stacking double.
	// A switch, never a `static const int table[]` -- that form does not
	// resolve on this engine build and has been rediscovered three
	// times (CLAUDE.md).
	int BonusCount()
	{
		bool allKills   = level.killed_monsters >= level.total_monsters;
		bool allSecrets = level.found_secrets   >= level.total_secrets;

		switch (CVInt("rs_lives_completion", 0))
		{
			case COMPLETION_ALL_KILLS:
				return allKills ? 1 : 0;

			case COMPLETION_ALL_SECRETS:
				return allSecrets ? 1 : 0;

			case COMPLETION_KILLS_OR_SECRETS:
				return (allKills || allSecrets) ? 1 : 0;

			case COMPLETION_KILLS_AND_SECRETS:
				return (allKills && allSecrets) ? 1 : 0;

			case COMPLETION_EITHER_STACKING:
				if (allKills && allSecrets)
					return 2;
				return (allKills || allSecrets) ? 1 : 0;

			case COMPLETION_NONE:
			default:
				return 1;
		}
	}

	void AddLevelClearLives(string md5)
	{
		if (LevelSeen(md5))
			return;

		int mult = BonusCount();
		if (mult <= 0)
			return;

		levelsCleared.Push(md5);

		int per = CVInt("rs_lives_per_level", 1);
		if (per > 0)
			AdjustLives(per * mult, true, SRC_LEVEL);

		// The floor. Distinct from the ceiling on purpose: it is a
		// promise that you never START a level with nothing, which is
		// what stops a bad run from turning into an unrecoverable one.
		// Passed applyMax = false, because a floor that the ceiling can
		// veto is not a floor.
		int floorLives = CVInt("rs_lives_min_per_level", 1);
		if (floorLives > 0 && lives < floorLives)
			AdjustLives(floorLives - lives, false, SRC_LEVEL);
	}

	// -----------------------------------------------------------------
	// Called by RS_LifeForce once a save has fully landed.
	// -----------------------------------------------------------------
	void OnSaved()
	{
		// Getting killed is exactly the thing the Untouchable and Spree
		// bonuses measure the absence of. Surviving it on a banked life
		// does not preserve them.
		let sp = RS_LivesHandler.ScorePlayerFor(playerNum);
		if (sp)
		{
			sp.utKills = 0;
			sp.utDamage = 0;
			sp.utStacks = 0;
			sp.spreeCount = 0;
		}
		spreePaid = 0;
	}

	// -----------------------------------------------------------------
	// The message. Deliberately plain literals, not $STRINGS: the
	// LANGUAGE.* lumps belong to another lane.
	// -----------------------------------------------------------------
	void SayChange(int delta)
	{
		if (!CVBool("rs_lives_message", true))
			return;

		Actor pawn = (playerNum >= 0 && playerNum < MAXPLAYERS && playeringame[playerNum])
			? players[playerNum].mo : null;
		if (!pawn)
			return;

		string msg;

		if (delta < 0)
		{
			// Hoisted out of the String.Format call deliberately. A
			// ternary of two literals inline in a vararg is exactly the
			// shape that produces confusing type errors on this engine
			// build (CLAUDE.md, on GetClassName in a ternary).
			string noun = (lives == 1) ? "life" : "lives";
			msg = String.Format("\c[Orange]SAVED.\c- %d %s left.", lives, noun);
		}
		else if (delta > 0)
		{
			string why;
			switch (reportSource)
			{
				case SRC_DAMAGE_TAKEN: why = "endured";       break;
				case SRC_DAMAGE_DEALT: why = "dealt";         break;
				case SRC_LEVEL:        why = "level clear";   break;
				case SRC_BOSS:         why = "boss";          break;
				case SRC_SCORE:        why = "score";         break;
				case SRC_SPREE:        why = "spree";         break;
				case SRC_START:        why = "";              break;
				default:               why = "";              break;
			}

			if (why == "")
				msg = String.Format("\c[Gold]Extra lives: %d\c-", lives);
			else
				msg = String.Format("\c[Gold]EXTRA LIFE\c- (%s) -- %d banked.", why, lives);
		}
		else
		{
			msg = String.Format("Extra lives: %d", lives);
		}

		pawn.A_Log(msg, true);
	}
}


// ---------------------------------------------------------------------
// The handler.
// ---------------------------------------------------------------------
class RS_LivesHandler : StaticEventHandler
{
	RS_LifeInfo info[MAXPLAYERS];
	bool warnedAboutOldSystem;

	// -----------------------------------------------------------------
	// cvar readers. clearscope for the same reason RS_Score's are: some
	// of these are wanted from ui code later, and an unqualified static
	// on a handler defaults to play scope.
	// -----------------------------------------------------------------
	clearscope static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	clearscope static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	clearscope static bool Enabled()
	{
		return CVBool("rs_lives_enable", true);
	}

	clearscope static RS_LivesHandler Get()
	{
		return RS_LivesHandler(StaticEventHandler.Find("RS_LivesHandler"));
	}

	// RS_Score is a separate, optional system. Everything that touches
	// it is null-guarded, so lives work with the score system disabled,
	// missing from MAPINFO, or removed entirely.
	clearscope static RS_ScorePlayer ScorePlayerFor(int pln)
	{
		let h = RS_ScoreHandler(EventHandler.Find("RS_ScoreHandler"));
		return h ? h.Get(pln) : null;
	}

	// -----------------------------------------------------------------
	// Player setup, and the whole of the level-transition policy.
	//
	// Three cases, and getting them confused is how a life system ends
	// up either resetting on every map or surviving a pistol start it
	// was never meant to:
	//
	//   1. The pawn already carries a force whose ledger is the one we
	//      remember -> nothing to do.
	//   2. The pawn carries a force with a DIFFERENT ledger -> we just
	//      loaded a savegame. The actor's copy is the truth; ours is
	//      stale. Take theirs.
	//   3. The pawn carries no force -> either a new game, or a level
	//      transition that stripped inventory (a death exit or a
	//      pistol-start setting). Restore the remembered ledger if we
	//      are allowed to, otherwise start fresh.
	// -----------------------------------------------------------------
	void InitPlayer(int p)
	{
		if (p < 0 || p >= MAXPLAYERS || !playeringame[p])
			return;

		let pawn = players[p].mo;
		if (!pawn)
			return;

		let force = RS_LifeForce(pawn.FindInventory("RS_LifeForce"));

		if (force)
		{
			if (force.info && force.info == info[p])
				return;

			// Case 2: savegame. The actor wins.
			if (force.info)
			{
				info[p] = force.info;
				info[p].playerNum = p;
				force.Initialize(force.info);
				return;
			}
		}
		else
		{
			force = RS_LifeForce(pawn.GiveInventoryType("RS_LifeForce"));
			if (!force)
				return;
		}

		if (!info[p] || !CVBool("rs_lives_ignore_death_exits", true))
		{
			// Case 3a: from scratch.
			force.Initialize(RS_LifeInfo.Create(p));
			info[p] = force.info;
		}
		else
		{
			// Case 3b: carry the remembered ledger across.
			info[p].playerNum = p;
			force.Initialize(info[p]);
		}
	}

	override void PlayerEntered(PlayerEvent e)
	{
		// A brand new game. Forget everything; the player has no force
		// either, so this lands on the from-scratch path.
		if (level.totaltime == 0)
			info[e.PlayerNumber] = null;

		InitPlayer(e.PlayerNumber);
	}

	override void WorldLoaded(WorldEvent e)
	{
		for (int i = 0; i < MAXPLAYERS; i++)
			if (playeringame[i])
				InitPlayer(i);

		WarnIfOldSystemLive();
	}

	// Dying properly resets you to the starting allowance rather than
	// leaving you on zero forever. Without this, one death with an
	// empty bank makes every subsequent death unsaveable and the
	// system silently stops existing for the rest of the run.
	override void PlayerRespawned(PlayerEvent e)
	{
		InitPlayer(e.PlayerNumber);

		let inf = info[e.PlayerNumber];
		if (inf)
			inf.GiveStartingLives();
	}

	override void WorldUnloaded(WorldEvent e)
	{
		if (!Enabled())
			return;

		string md5 = level.GetChecksum();

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !info[i])
				continue;

			info[i].AddLevelClearLives(md5);
		}
	}

	// -----------------------------------------------------------------
	// Earning by DEALING damage, and boss kills.
	//
	// Damage TAKEN is not counted here: RS_LifeForce.AbsorbDamage sees
	// the same hit with the post-armour number and a chance to act on
	// it, so counting it twice from two places would double the meter
	// and put the two systems permanently out of step.
	// -----------------------------------------------------------------
	override void WorldThingDamaged(WorldEvent e)
	{
		if (!Enabled())
			return;

		Actor victim = e.Thing;
		if (!victim || e.Damage <= 0)
			return;

		// Damage to a player is the force's business.
		if (victim.player)
			return;

		if (!victim.bIsMonster)
			return;

		// Walk to the real attacker: a rocket's damage belongs to
		// whoever fired it, and a rocket fired by a summon belongs to
		// whoever summoned it. Same walk RS_Score does for kills.
		Actor src = e.DamageSource;
		while (src && src.bMissile && src.target)
			src = src.target;

		if (!src || !src.player)
			return;

		let inf = InfoFor(src.PlayerNumber());
		if (!inf)
			return;

		// OVERKILL DOES NOT COUNT. WorldThingDamaged is handed
		// `realdamage` (p_interaction.cpp:1594/1615), the full amount
		// the attack rolled -- so a rocket for 128 into a zombieman
		// reports 128, and a BFG into a room of them reports its whole
		// roll per corpse. Counting that would make one loud weapon
		// worth more lives than an hour of careful play. At this point
		// the victim's health is already POST-damage, so anything below
		// zero is exactly the surplus, and subtracting it leaves the
		// damage that actually landed on something living.
		int overkill = max(0, -victim.health);
		int landed = max(0, e.Damage - overkill);
		inf.AddDamageDealt(landed);

		// Boss kills. Same test the reference implementation uses: the
		// damaged thing is a boss and it is now dead.
		if (victim.bBOSS && victim.health <= 0)
			inf.AddBossKill();
	}

	// -----------------------------------------------------------------
	// Per-tic upkeep: score integration, then reporting.
	// -----------------------------------------------------------------
	override void WorldTick()
	{
		if (!Enabled())
			return;

		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i])
				continue;

			let inf = info[i];
			if (!inf)
				continue;

			TickScore(inf, i);
			TickReport(inf);
		}
	}

	RS_LifeInfo InfoFor(int p)
	{
		if (p < 0 || p >= MAXPLAYERS)
			return null;
		return info[p];
	}

	// -----------------------------------------------------------------
	// SCORE INTEGRATION.
	//
	// RS_Score keeps its own `extraLives` field and its HUD draws the
	// pips from it. Rather than fork that, this system treats the field
	// as a SHARED WINDOW: it absorbs anything another system put there,
	// then writes the authoritative count back. Two consequences worth
	// stating, because both were the point:
	//
	//   * the existing HUD keeps working with no edit to
	//     RS_ScoreHUD.zs -- which is another lane's file;
	//   * RS_Score's own reward thresholds (rs_score_rewardmode 0/1/3)
	//     become one of the earning paths for free, and cannot
	//     double-count, because the absorb and the write-back are the
	//     same operation.
	// -----------------------------------------------------------------
	void TickScore(RS_LifeInfo inf, int p)
	{
		let sp = ScorePlayerFor(p);
		if (!sp)
			return;

		// 1. Absorb lives granted by RS_Score's reward thresholds.
		if (CVBool("rs_lives_take_score_rewards", true)
			&& sp.extraLives > inf.mirroredLives)
		{
			inf.AdjustLives(sp.extraLives - inf.mirroredLives, true,
				RS_LifeInfo.SRC_SCORE);
		}

		// 2. The flat score meter. Seeded on first sight, or joining a
		// run in progress would instantly pay out for score earned
		// before the meter existed.
		if (!inf.scoreSeeded)
		{
			inf.lastScoreSeen = sp.score;
			inf.scoreSeeded = true;
		}
		else
		{
			int gained = sp.score - inf.lastScoreSeen;
			if (gained > 0)
				inf.AddScoreCharge(gained);
			inf.lastScoreSeen = sp.score;
		}

		// 3. Spree milestones. Counting whole multiples reached rather
		// than watching for an exact hit means a multi-kill that jumps
		// the counter past a milestone still pays it.
		int sper = CVInt("rs_lives_spree_per_life", 0);
		if (sper > 0)
		{
			int paid = sp.spreeCount / sper;
			if (paid > inf.spreePaid)
				inf.AdjustLives(paid - inf.spreePaid, true, RS_LifeInfo.SRC_SPREE);
			inf.spreePaid = paid;
		}

		if (sp.spreeCount <= 0)
			inf.spreePaid = 0;

		// 4. Write the authoritative count back so the existing HUD
		// draws it.
		sp.extraLives = inf.lives;
		inf.mirroredLives = inf.lives;
	}

	// -----------------------------------------------------------------
	// Reporting. One netevent and at most one message per burst.
	//
	// Emitted from WorldTick rather than from AdjustLives on purpose:
	// EventManager::SendNetworkEvent (events.cpp:384) refuses to send
	// unless gamestate is GS_LEVEL, and AdjustLives can be reached from
	// a level transition where it is not.
	// -----------------------------------------------------------------
	void TickReport(RS_LifeInfo inf)
	{
		if (inf.reportDelay <= 0)
			return;

		inf.reportDelay--;
		if (inf.reportDelay > 0)
			return;

		int delta = inf.lives - inf.reportedLives;

		// THE HUD LANE'S EVENT.
		//   name : "rs-lives-changed"
		//   arg0 : the player's current life count
		//   arg1 : the change since the last report (may be negative)
		//   arg2 : the player number the count belongs to
		EventHandler.SendNetworkEvent("rs-lives-changed",
			inf.lives, delta, inf.playerNum);

		if (delta != 0 || inf.reportSource == RS_LifeInfo.SRC_START)
			inf.SayChange(delta);

		inf.reportedLives = inf.lives;
		inf.reportSource = RS_LifeInfo.SRC_NONE;
	}

	// -----------------------------------------------------------------
	// A loud, once-per-session warning if the OLD buddha-based lives
	// path in RS_Score.zs is still live alongside this one. Two systems
	// spending the same counter is exactly the kind of fault that looks
	// like a physics bug for a week.
	//
	// It only ever WARNS. It does not write another system's cvar and
	// it does not disable anything -- that is the owner's call.
	// -----------------------------------------------------------------
	void WarnIfOldSystemLive()
	{
		if (warnedAboutOldSystem)
			return;

		if (!Enabled())
			return;

		if (!CVBool("rs_score_lives_enable", false))
			return;

		warnedAboutOldSystem = true;
		Console.Printf("\c[Red]RS_Lives:\c- rs_score_lives_enable is ON while rs_lives_enable is ON.");
		Console.Printf("\c[Red]RS_Lives:\c- the old CF_BUDDHA revival in RS_Score.zs is still running and will fight this system.");
		Console.Printf("\c[Red]RS_Lives:\c- set rs_score_lives_enable 0, or remove RS_ScoreHandler.TickLives.");
	}

	// -----------------------------------------------------------------
	// Console and cross-mod entry points.
	// -----------------------------------------------------------------
	override void NetworkProcess(ConsoleEvent e)
	{
		int p = e.Player;
		if (p < 0 || p >= MAXPLAYERS)
			return;

		let inf = InfoFor(p);
		if (!inf)
			return;

		if (e.Name == "rs_lives_report")
		{
			Console.Printf("\c[Gold]--- RS Extra Lives ---\c-");
			Console.Printf("Lives: %d   (cap %d, floor per level %d)",
				inf.lives, CVInt("rs_lives_max", 9), CVInt("rs_lives_min_per_level", 1));
			Console.Printf("Damage taken meter: %d / %d",
				inf.chargeTaken, CVInt("rs_lives_damage_taken_per_life", 700));
			Console.Printf("Damage dealt meter: %d / %d",
				inf.chargeDealt, CVInt("rs_lives_damage_dealt_per_life", 10000));
			Console.Printf("Score meter: %d / %d",
				inf.chargeScore, CVInt("rs_lives_score_per_life", 0));
			Console.Printf("Levels cleared for bonus: %d", inf.levelsCleared.Size());
			Console.Printf("Bullet Time X detected: %s",
				RS_BulletTimeHook.Present() ? "yes" : "no");
		}
		else if (e.Name == "rs_lives_set")
		{
			inf.lives = max(0, e.Args[0]);
			inf.ScheduleReport(RS_LifeInfo.SRC_CONSOLE, 2);
		}
		else if (e.Name == "rs_lives_adjust")
		{
			inf.AdjustLives(e.Args[0], e.Args[1] != 0, RS_LifeInfo.SRC_CONSOLE);
		}
		// Optional bridge for anything written against the Indestructable
		// API -- the Gun Bonsai "Indestructable" upgrade in this tree
		// speaks it. OFF by default, because if the real Indestructable
		// is also loaded both systems would answer and the grant would
		// land twice.
		else if (CVBool("rs_lives_accept_foreign_events", false))
		{
			if (e.Name == "indestructable-adjust-lives")
				inf.AdjustLives(e.Args[0], e.Args[1] != 0, RS_LifeInfo.SRC_CONSOLE);
			else if (e.Name == "indestructable-set-lives")
			{
				inf.lives = max(0, e.Args[0]);
				inf.ScheduleReport(RS_LifeInfo.SRC_CONSOLE, 2);
			}
			else if (e.Name == "indestructable-clamp-lives")
			{
				int lo = e.Args[0];
				int hi = e.Args[1];
				if (lo >= 0 && inf.lives < lo)
					inf.AdjustLives(lo - inf.lives, false, RS_LifeInfo.SRC_CONSOLE);
				if (hi >= 0 && inf.lives > hi)
					inf.AdjustLives(hi - inf.lives, false, RS_LifeInfo.SRC_CONSOLE);
			}
		}
	}
}


// ---------------------------------------------------------------------
// RPC surface, so another mod can read and move our life count without
// a netevent round trip and without knowing our class names.
//
// Services are found by ServiceIterator and need no registration
// anywhere -- which is the point: an integrating mod can ask for us and
// get an empty iterator if we are not loaded, with no error.
//
// Deliberately the SAME function names and argument shape as the
// Indestructable service, so anything already written against that
// ports by changing one string:
//
//    GetInt("get-lives",    "",           playernum)          -> lives
//    GetInt("set-lives",    "",           playernum, count)   -> lives
//    GetInt("adjust-lives", respect_max,  playernum, delta)   -> lives
//    GetInt("apply-min",    "",           playernum, min)     -> lives
//    GetInt("apply-max",    "",           playernum, max)     -> lives
//
// respect_max is any non-empty string to honour rs_lives_max.
// ---------------------------------------------------------------------
class RS_LivesService : Service play
{
	RS_LifeInfo InfoFor(int p)
	{
		let h = RS_LivesHandler.Get();
		return h ? h.InfoFor(p) : null;
	}

	// The full six-parameter form. The base declares
	// GetInt(String, string, int, double, Object, Name) at
	// engine/service.zs:22; matching it exactly is the one signature
	// that cannot be rejected by the override check.
	override int GetInt(String fn, String strArg, int p, double numArg,
		Object objArg, Name nameArg)
	{
		let inf = InfoFor(p);
		if (!inf)
			return 0;

		if (fn == "get-lives")
		{
			return inf.lives;
		}
		else if (fn == "set-lives")
		{
			inf.lives = max(0, int(numArg));
			inf.ScheduleReport(RS_LifeInfo.SRC_CONSOLE, 2);
			return inf.lives;
		}
		else if (fn == "adjust-lives")
		{
			inf.AdjustLives(int(numArg), strArg != "", RS_LifeInfo.SRC_CONSOLE);
			return inf.lives;
		}
		else if (fn == "apply-min")
		{
			int lo = max(0, int(numArg));
			if (inf.lives < lo)
				inf.AdjustLives(lo - inf.lives, false, RS_LifeInfo.SRC_CONSOLE);
			return inf.lives;
		}
		else if (fn == "apply-max")
		{
			int hi = max(0, int(numArg));
			if (inf.lives > hi)
				inf.AdjustLives(hi - inf.lives, false, RS_LifeInfo.SRC_CONSOLE);
			return inf.lives;
		}

		Console.Printf("\c[Red]RS_LivesService:\c- unknown rpc name '%s'", fn);
		return 0;
	}
}
