// ============================================================================
// rs_mg_base.zs -- shared base for the RS_MG monster set.
//
// *** STAGING.  NOT WIRED UP.  DOES NOT LOAD. ***
// Nothing in zscript/mg_staging/ is listed in zscript.txt, so as far as the
// engine is concerned none of these classes exist.  That is deliberate: the
// set is parked outside zscript/monsters/ (which is sealed) for the owner to
// review before any of it lands.  Do not add the include without being asked.
//
// ----------------------------------------------------------------------------
// WHAT THIS SET IS
// ----------------------------------------------------------------------------
// A second roster covering the seventeen standard Doom enemies.  What sets it
// apart from the roster already in zscript/monsters/ is the DEATH WORK, not
// the brains:
//
//   * every grunt rolls one of three to five randomised dismemberment deaths
//     -- leg, arm, head, guts, heavy -- each with its own sprite sequence and
//     its own shower of gib actors;
//   * most of the set carries separate death channels for chainsaw, plasma
//     and crush damage on top of the usual Death / XDeath;
//   * the bosses die in staged explosions rather than a single animation.
//
// The behaviour is stock.  These monsters look, chase, shoot and melee the way
// the vanilla ones do.  What they gain by extending the tiered-monster
// template is the colour dial, the per-tier stat buffs, the tint and the
// keywords -- so a coloured one here runs its ordinary state machine, buffed
// and tinted and keyworded, rather than being redesigned around its colour.
// That is the whole point of the set: it is the tier system applied to a
// familiar monster instead of a reinvented one.
//
// ----------------------------------------------------------------------------
// THE TIER HOOK WAS DEAD.  IT IS REAL NOW.  READ THIS BEFORE TOUCHING IT.
// ----------------------------------------------------------------------------
// The version this was split from declared
//
//     virtual int MGHP(int t) { return 0; }   // "concrete monsters override
//                                             //  to give real per-color HP"
//
// and then NOT ONE of the eighteen classes overrode it.  It returned 0 every
// single time, which sent every monster down the `hpMul` fallback in
// TierData() -- one shared curve for the whole roster.  Green meant "x1.6 HP"
// for a zombieman and for a cyberdemon alike.  A green zombieman came out at
// 32 HP (still one pistol burst; the tier was invisible) and a green
// cyberdemon at 6400 (a rocket sponge with nothing new to say).  The hook was
// documented, plausible, and load-bearing for nothing.
//
// This is the failure mode worth remembering: it produced no error, no
// warning and no log line.  The mod compiled, the game ran, and the tiers
// were simply flat.  The only detector was somebody reading the curve and
// asking what it meant on a monster at each end of the HP range.
//
// So: EVERY concrete monster in this set now overrides MGHP() with an
// absolute per-tier HP table scaled off its own Default Health, and every
// table carries the reasoning for its shape in a comment beside it.  The
// tables are not multiples of one curve -- fodder climbs steeply in ratio
// because doubling 20 HP is nothing, and bosses climb shallowly because
// multiplying 4000 HP is everything.
//
// The `return 0` fallback below is kept as a crash-safety net, not a design
// choice: if a future monster is added and forgets its table, it degrades to
// the old shared curve rather than spawning at 0 HP.  A monster that reaches
// the fallback is a bug, not a valid configuration.
//
// ----------------------------------------------------------------------------
// TIER COUNT FOLLOWS THE ART
// ----------------------------------------------------------------------------
// Owner's rule: a monster gets as many tiers as it HAS.  A tier the player
// cannot tell apart on sight is not a tier, it is a hidden stat block.
//
// So the ladder is capped per monster by MGTiers(), the number of custom
// sprite sequences that monster ships beyond its vanilla set.  TierData()
// returns false above the cap, and the tier simply is not offered.
//
// The counts below were supplied by the owner and then checked against the
// sprite prefixes each actor actually names in its own States block, which is
// the only evidence available from inside this file.  All seventeen agree:
//
//     Shotgunner    8   SPSR SPO3 SPO5 SPDH ZXZ7 ZXZ6 DPS1 CRSH
//     Zombieman     6   POS7 ZZD2 ZZD6 ZXZ2 DPS1 CRSH
//     Mancubus      6   XFAT FAT2 XFT2 XFBT XBBT CRSH
//     Chaingunner   6   CPHS CPSC MPSD ZXZ2 DPS1 CRSH
//     Demon         5   SARH SARC SAAR SARB CRSH
//     Spectre       5   SARH SARC SAAR SARB CRSH
//     Imp           4   TR09 TR08 TROH DPS1
//     Revenant      4   REVH REVP REDX CRSH
//     Baron         3   XBAR BBAR CRSH
//     HellKnight    3   XBAR BBAR CRSH
//     Cacodemon     3   CCD2 CCD3 CRSH
//     Archvile      3   XVIL BVIL CRSH
//     Arachnotron   2   XBSP CRSH
//     Mastermind    1   CRSH
//     Cyberdemon    1   CRSH
//     PainElemental 1   PAIN X  (a frame past the vanilla PAIN set's A-M)
//     LostSoul      0   -- nothing but the vanilla SKUL set
//
// The LostSoul has NO custom art at all, so it gets NO ladder.  Its MGHP()
// override exists and says so out loud rather than inventing one.
//
// Which colours a monster gets is decided by MGTierRank() below: the colours
// are ordered by this file's OWN buff curve, weakest first, and a monster
// takes the first N.  Nothing outside this file is consulted for that order.
//
// ----------------------------------------------------------------------------
// OUTSIDE DEPENDENCIES -- NONE OF THESE ARE IN THIS REPO YET
// ----------------------------------------------------------------------------
// This set was written against a tiered-monster template that is NOT present
// in E:\RS_Main.  A case-insensitive sweep of zscript/ finds zero hits for
// any of it:
//
//     HF_Monster    the parent class every monster here extends
//     HF_TierRow    the struct TierData() fills in
//     HFMT_*        the thirteen tier constants (NEUTRAL + twelve colours)
//     TierData()    the virtual this base overrides
//     MonIdentity() the virtual each monster overrides
//
// Those names are left exactly as written.  They are the template's contract,
// not this set's, and guessing at a replacement for a class nobody can read
// is how imports break.  THIS FILE THEREFORE CANNOT COMPILE UNTIL THAT
// TEMPLATE EXISTS OR THE OWNER NAMES ITS REPLACEMENT.  That is the single
// biggest open question in this staging pass.
//
// The gore and projectile actors every monster spawns are also absent -- 59
// classes, including MG_EnemyBullet, MG_Rocket, the XDeath1/2/3 family and its
// Blue/Green variants, FlyingBloodParticle*, CeilingBloodChecker*, the per-limb
// gib actors and SmokePillar.  They are referenced by name only, so an absent
// one is SILENT: A_CustomMissile on an unknown class spawns nothing, logs
// nothing, and the death animation just plays with no gore.  The full list is
// recoverable by grepping this folder for A_CustomMissile / A_SpawnItem.
//
// The sprites are absent too -- there is no sprites/mg/ in this repo, and none
// of the 30-odd custom prefixes above resolve.  A monster whose sprite is
// missing spawns, moves and kills you while rendering nothing, with no error
// and no log line.  None of this is fixable from inside a code split; it is
// listed so the denominator is on the record.
//
// ----------------------------------------------------------------------------
// CHANGED IN THIS PASS, NOT COPIED
// ----------------------------------------------------------------------------
//   1. Provenance stripped.  The original header credited an outside mod and
//      its author, and every monster's keyword string carried that mod's name
//      as `set:<name>`.  Repo code does not name the mods its systems were
//      rebuilt from.  The keyword is now `set:gore`, which describes what the
//      set actually is -- the roster with the dismemberment death work.  If
//      the owner wants a different handle it is one sweep over 17 files.
//   2. MGHP() made real, per the paragraph above.
//   3. Tier counts capped to the art, per the paragraph above.
//   4. +MISSILEMORE converted on the three monsters that carried it (LostSoul,
//      Mastermind, Cyberdemon) to `MissileChanceMult 0.5`.  It is a deprecated
//      flag; the engine's own deprecation message says to use the property.
//      No monster here carried +MISSILEEVENMORE or +SHORTMISSILERANGE.
//
// The tint key prefix also changed.  The original built its translation names
// on a foreign prefix, borrowed wholesale from another roster so that a green
// grunt here would show the same green as a green grunt there.  Neither that
// prefix nor those TRNSLATE entries exist in this repo, so every borrowed name
// would resolve to nothing.  It is now one named constant, below, so pointing
// the whole set at a real palette is a one-line edit.
// ============================================================================

class RS_MG_Monsters : HF_Monster
{
	// Tint keys are built as <prefix><family>_<colour>, e.g. rs_mon_imp_green.
	// NONE OF THESE TRNSLATE ENTRIES EXIST YET -- an unresolved translation
	// name is inert, so a tiered monster will render untinted rather than
	// erroring.  Kept as one constant so the whole set repoints in one edit.
	// (const is legal at class scope; it is a parse error inside a function
	// body on this engine, so it must live out here.)
	const TINTPREFIX = "rs_mon_";

	// per-monster tint family ("zombie","imp","demon",...) -> <prefix><fam>_<colour>
	string tintFam;

	// Corpse-freeze safety net.  If one of these dies while airborne -- gibbed
	// off a ledge by a rocket -- its final corpse frame has an infinite (-1)
	// duration, and the actor can halt before gravity has finished grounding
	// it, leaving a body hanging in the air.  So: a dead, airborne corpse gets
	// nudged down each tic until it lands.
	//
	// This is PURE PHYSICS.  It touches no state machine and changes no death
	// animation; every monster's states are exactly as written.
	override void Tick()
	{
		Super.Tick();
		if (health <= 0 && !bNoGravity)
		{
			double fz = floorz;
			if (pos.z > fz + 0.5)
			{
				// only intervene if the corpse has actually STALLED in the air
				// (near-zero downward velocity). Normal falling corpses are left
				// alone -- the engine's gravity handles them.
				if (vel.z > -0.5) vel.z -= 0.8;
			}
			else if (pos.z < fz)
			{
				SetZ(fz);
				if (vel.z < 0) vel.z = 0;
			}
		}
	}

	// ------------------------------------------------------------------------
	// How many COLOURED tiers this monster's art can tell apart, on top of
	// Neutral.  See the header: a tier the player cannot see is not a tier.
	//
	// The base returns 0 on purpose.  A monster that forgets to override this
	// gets Neutral and nothing else -- visibly wrong the first time it spawns,
	// which is the opposite of how MGHP() failed.  MGHP() defaulted to a value
	// that looked plausible, so eighteen missing overrides went unnoticed
	// indefinitely.  A default of "no colours at all" cannot hide.
	// ------------------------------------------------------------------------
	virtual int MGTiers() { return 0; }

	// ------------------------------------------------------------------------
	// Escalation order for the twelve colours, weakest first.  Neutral is 0,
	// so it is never gated.
	//
	// The order is derived from THIS FILE'S OWN buff curve in TierData() --
	// hpMul first, dmgMul to break the one tie (brown and yellow both sit at
	// x3.0 HP; brown is the slow tanky one at x1.4 damage, yellow the fast
	// mean one at x1.8, so brown ranks lower).  No outside ladder is consulted,
	// because the curve below is the only statement of severity this set makes.
	//
	// Written as a switch, NOT as a `static const int[]` array literal -- those
	// do not reliably resolve on this engine build and fail with a misleading
	// "unknown identifier".
	// ------------------------------------------------------------------------
	int MGTierRank(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 1;   // hpMul 1.6
			case HFMT_CYAN:    return 2;   // hpMul 1.8
			case HFMT_BLUE:    return 3;   // hpMul 2.0
			case HFMT_FIREBLU: return 4;   // hpMul 2.5
			case HFMT_BROWN:   return 5;   // hpMul 3.0, dmgMul 1.4
			case HFMT_YELLOW:  return 6;   // hpMul 3.0, dmgMul 1.8
			case HFMT_PURPLE:  return 7;   // hpMul 3.5
			case HFMT_GRAY:    return 8;   // hpMul 3.8
			case HFMT_ABYSS:   return 9;   // hpMul 4.0
			case HFMT_RED:     return 10;  // hpMul 5.0
			case HFMT_BLACK:   return 11;  // hpMul 12.0
			case HFMT_WHITE:   return 12;  // hpMul 20.0
			default:           return 0;   // HFMT_NEUTRAL and anything unknown
		}
	}

	// ------------------------------------------------------------------------
	// ABSOLUTE per-tier HP.  Overridden by every concrete monster in this set;
	// see the header for why this used to be the set's biggest silent defect.
	//
	// Returning 0 means "no table -- fall back to the shared hpMul curve".
	// That path is a crash-safety net so a half-finished monster still spawns
	// alive, NOT a supported configuration.  Nothing that ships should use it.
	// ------------------------------------------------------------------------
	virtual int MGHP(int t) { return 0; }

	// ------------------------------------------------------------------------
	// The shared buff curve: escalating stats per colour, plus the tint.
	// Nothing here redesigns a monster -- it is tougher, faster and meaner and
	// that is all.  Bosses keep their own Default stats at Neutral.
	// ------------------------------------------------------------------------
	override bool TierData(int t, out HF_TierRow r)
	{
		// ART GATE.  Above this monster's cap the tier does not exist, so
		// report no data rather than handing back a stat block with no
		// matching sprite behind it.
		if (MGTierRank(t) > MGTiers()) return false;

		r.hpMul = 1.0; r.hp = MGHP(t); r.spdMul = 1.0; r.painChance = 200; r.dmgMul = 1.0;
		r.behave = 0; r.tint = ""; r.flash = "white";

		// pick the tint for this monster family + colour
		string col = TierColorLower(t);
		if (col.Length() > 0 && tintFam.Length() > 0)
			r.tint = TINTPREFIX .. tintFam .. "_" .. col;

		switch (t)
		{
			case HFMT_NEUTRAL: r.hpMul=1.0;  r.spdMul=1.0; r.painChance=200; r.dmgMul=1.0; r.behave=0; r.tint=""; break;
			case HFMT_GREEN:   r.hpMul=1.6;  r.spdMul=1.1; r.painChance=180; r.dmgMul=1.2; r.behave=1; break;
			case HFMT_BLUE:    r.hpMul=2.0;  r.spdMul=1.2; r.painChance=160; r.dmgMul=1.3; r.behave=1; break;
			case HFMT_CYAN:    r.hpMul=1.8;  r.spdMul=1.6; r.painChance=120; r.dmgMul=1.3; r.behave=2; break;
			case HFMT_PURPLE:  r.hpMul=3.5;  r.spdMul=1.4; r.painChance=100; r.dmgMul=1.6; r.behave=2; break;
			case HFMT_YELLOW:  r.hpMul=3.0;  r.spdMul=1.7; r.painChance=90;  r.dmgMul=1.8; r.behave=3; break;
			case HFMT_ABYSS:   r.hpMul=4.0;  r.spdMul=1.3; r.painChance=100; r.dmgMul=1.5; r.behave=2; break;
			case HFMT_FIREBLU: r.hpMul=2.5;  r.spdMul=1.5; r.painChance=110; r.dmgMul=1.7; r.behave=2; break;
			case HFMT_BROWN:   r.hpMul=3.0;  r.spdMul=1.1; r.painChance=140; r.dmgMul=1.4; r.behave=1; break;
			case HFMT_GRAY:    r.hpMul=3.8;  r.spdMul=1.0; r.painChance=90;  r.dmgMul=1.5; r.behave=2; break;
			case HFMT_RED:     r.hpMul=5.0;  r.spdMul=1.5; r.painChance=70;  r.dmgMul=2.0; r.behave=3; break;
			case HFMT_BLACK:   r.hpMul=12.0; r.spdMul=1.6; r.painChance=40;  r.dmgMul=2.5; r.behave=3; r.flash="white"; break;
			case HFMT_WHITE:   r.hpMul=20.0; r.spdMul=1.8; r.painChance=24;  r.dmgMul=3.0; r.behave=3; r.flash="black"; break;
		}

		// The absolute table WINS.  The switch above has just overwritten
		// hpMul with the shared curve's value, and it is not knowable from
		// here whether the consumer reads hp instead of hpMul or multiplies
		// the two.  Neutralising the multiplier makes both readings agree:
		// a green cyberdemon is 5000, never 5000 x 1.6.
		if (r.hp > 0) r.hpMul = 1.0;

		return true;
	}

	// lowercase colour name for building the tint key (matches TRNSLATE naming).
	string TierColorLower(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return "green";
			case HFMT_BLUE:    return "blue";
			case HFMT_CYAN:    return "cyan";
			case HFMT_PURPLE:  return "purple";
			case HFMT_YELLOW:  return "yellow";
			case HFMT_ABYSS:   return "abyss";
			case HFMT_FIREBLU: return "fireblu";
			case HFMT_BROWN:   return "brown";
			case HFMT_GRAY:    return "gray";
			case HFMT_RED:     return "red";
			case HFMT_BLACK:   return "black";
			case HFMT_WHITE:   return "white";
			default:           return "";
		}
	}
}
