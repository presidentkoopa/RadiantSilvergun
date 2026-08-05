// =====================================================================
// RS_MonsterLadder -- the CHP-era tier machinery, quarantined.
// ---------------------------------------------------------------------
// SPLIT OUT OF RS_MonsterMaster 2026-08-05.
//
// This is everything that existed to make ONE class behave as FOURTEEN:
// the per-tier stat row, the per-tier sprite and tint tables, the
// per-tier state clusters and the ".T00" dispatch that reads them.
//
// IT IS NOT PART OF THE CH REBUILD AND NOTHING REBUILT FROM CH INHERITS
// IT. Under the CH rebuild each creature is its own class -- own Default
// block, own sprites, own Translation, plain state labels. There is no
// ladder to walk, so none of this runs.
//
// It survives only because the nineteen CHP files in this folder still
// call it, and deleting it would leave sixteen of seventeen families
// with no monsters at all.
//
// A family stops inheriting this the day it is rebuilt from CH. Family
// 04 already has. WHEN THE LAST ONE LEAVES, DELETE THIS FILE and the
// stub seam at the bottom of RS_MonsterMaster with it.
//
// DO NOT ADD ANYTHING HERE. Do not fix bugs here. See README.txt.
// =====================================================================

class RS_MonsterLadder : RS_MonsterMaster abstract
{

	// =================================================================
	// TIER
	// =================================================================

	// The ladder. T00..T12 are Colourful Hell's real hand-tuned numbers.
	//
	// THIS CURVE IS NOT MONOTONIC AND THAT IS DELIBERATE. T03 has less HP
	// than T02 but far more speed. T09 is the slowest tier in the table
	// yet nearly the toughest of the middle band. Each row was a distinct
	// designed creature, not a point on a ramp. Do not "fix" this into a
	// smooth curve -- the irregularity IS the ladder's character.
	//
	// Switch, not a static const array: this engine build does not
	// resolve `static const TYPE name[] = {...}` in a class body
	// reliably (three real bugs so far).
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 200; r.dmgMul = 1.0;

		switch (t)
		{
			case 0:  r.hpMul= 1.0; r.spdMul=1.0; r.painChance=200; r.dmgMul=1.0; break;
			case 1:  r.hpMul= 1.6; r.spdMul=1.1; r.painChance=180; r.dmgMul=1.2; break;
			case 2:  r.hpMul= 2.0; r.spdMul=1.2; r.painChance=160; r.dmgMul=1.3; break;
			case 3:  r.hpMul= 1.8; r.spdMul=1.6; r.painChance=120; r.dmgMul=1.3; break;
			case 4:  r.hpMul= 3.5; r.spdMul=1.4; r.painChance=100; r.dmgMul=1.6; break;
			case 5:  r.hpMul= 3.0; r.spdMul=1.7; r.painChance= 90; r.dmgMul=1.8; break;
			case 6:  r.hpMul= 4.0; r.spdMul=1.3; r.painChance=100; r.dmgMul=1.5; break;
			case 7:  r.hpMul= 2.5; r.spdMul=1.5; r.painChance=110; r.dmgMul=1.7; break;
			case 8:  r.hpMul= 3.0; r.spdMul=1.1; r.painChance=140; r.dmgMul=1.4; break;
			case 9:  r.hpMul= 3.8; r.spdMul=1.0; r.painChance= 90; r.dmgMul=1.5; break;
			case 10: r.hpMul= 5.0; r.spdMul=1.5; r.painChance= 70; r.dmgMul=2.0; break;
			case 11: r.hpMul=12.0; r.spdMul=1.6; r.painChance= 40; r.dmgMul=2.5; break;
			case 12: r.hpMul=20.0; r.spdMul=1.8; r.painChance= 24; r.dmgMul=3.0; break;
			default: return false;
		}
		return true;
	}


	// Show a specific tier's BODY without committing to that tier --
	// display only, no stat recompute. Used by the transform tell to
	// flick between the old and new creature mid-telegraph.
	override void RS_ShowBody(int t)
	{
		State st = FindStateByString("See." .. TierLabel(t), true);
		if (!st) st = FindStateByString("Spawn." .. TierLabel(t), true);
		if (!st) st = FindStateByString("See.T00", true);
		if (st) SetState(st);
	}


	override void ApplyTier(bool instant)
	{
		// RE-POINT THE ATTACK STATE POINTERS AT THIS TIER'S OWN CLUSTER.
		// This runs BEFORE the TierData bail on purpose -- a tier with no
		// data row still needs correct pointers.
		//
		// WHY THIS EXISTS, because it is not obvious and it cost a session:
		// the dispatcher block below declares Melee: for EVERY monster, so
		// MeleeState was non-null on every tier of every family -- including
		// the ones that have no melee attack at all. Two things break.
		//
		//   1. P_CheckMissileRange does `if (MeleeState == NULL) dist -= 128;`
		//      -- "no melee attack, so fire more". That subtraction is what
		//      makes a hitscan zombie aggressive. Every tier was losing it,
		//      so all fourteen collapsed onto the same lethargic vanilla
		//      firing rate and the tier grammar read as "just a zombieman"
		//      no matter which body was on screen.
		//   2. A_Chase/A_FastChase check melee FIRST and return. At melee
		//      range a melee-less tier went Melee: -> TierState null ->
		//      Goto See -> chase -> Melee: ... and never reached its
		//      missile state at all.
		//
		// CHP is the evidence: of the fifteen family-01 actors only 01_F
		// (T07) and 01_K (T11) define Melee:. The other thirteen have none,
		// and get the -128.
		//
		// TierState returns null when neither Melee.<tier> nor Melee.T00
		// exists, which is exactly the melee-less set, and keeps the real
		// clusters for the tiers that do have one. Family-agnostic: a melee
		// family that authors Melee.T00 still gets its fallback.
		MeleeState   = TierState("Melee");
		MissileState = TierState("Missile");

		RS_MonsterTierRow r = new("RS_MonsterTierRow");
		// THE "LEAVE ALONE" SENTINEL FOR renderStyle IS -1, NOT 0,
		// AND IT HAS TO BE SET HERE.
		// A new() row zero-initialises, and STYLE_None IS 0 -- so a
		// family that simply does not mention renderStyle was getting
		// A_SetRenderStyle(alpha, STYLE_None) and spawning INVISIBLE.
		// Found on `summon rs_shotgunner` 2026-08-05. Every other field
		// can use 0 for "unstated" because 0 is not a legal value for
		// any of them; renderStyle is the one exception, so its default
		// lives at the single allocation site rather than being a line
		// every family has to remember.
		r.renderStyle = -1;
		if (!TierData(Tier, r))
			return;

		// Fraction-preserving: a monster retiered mid-fight keeps how
		// hurt it was rather than being silently full-healed or left on
		// a sliver. Toggleable -- some players want the raw dial.
		// Fraction is measured against the max we had BEFORE this
		// recompute -- TierMaxHealth is still the old ceiling here. On
		// the very first call it's 0, so a fresh monster spawns full.
		double frac = 1.0;
		if (RS_MonOpt("rs_mon_retier_preserve_fraction", true)
		    && !instant && health > 0 && TierMaxHealth > 0)
		{
			frac = clamp(double(health) / double(TierMaxHealth), 0.0, 1.0);
		}

		// Absolute hand-assigned health wins; the multiplier is the
		// fallback for rows that did not state one.
		int newMax = (r.hp > 0) ? r.hp : max(1, int(rsBaseHealth * r.hpMul));
		newMax = max(1, newMax);
		TierMaxHealth = newMax;
		// Direct assignment rather than A_SetHealth: that's an action
		// function, and calling one from a plain method (or on another
		// actor, as the heal path does) is a ZScript wrinkle not worth
		// gambling on. Equivalent here.
		health = max(1, int(newMax * frac));
		Speed         = (r.speed > 0) ? double(r.speed) : rsBaseSpeed * r.spdMul;
		PainChance    = r.painChance;
		TierDamageMul = r.dmgMul;

		RS_ApplyTierProperties(r);
		RS_ApplyTint();
		BuildAttacksForTier(Tier);
		OnTierApplied(Tier);

		// Route the state machine into the new tier's body. Deferred to
		// Tick (SetState from a non-actor context silently fails). If
		// we're mid-fight, enter the new See; if idle, the new Spawn --
		// otherwise a retiered idle monster keeps showing the old body
		// until something wakes it.
		pendingStateJump = (target ? "See." : "Spawn.") .. TierLabel(Tier);
	}


	// =================================================================
	// THE CH PARENT PROPERTIES, APPLIED.
	//
	// Flags are ASSIGNED, not OR'd -- a monster that retiers from T03
	// (+THRUSPECIES) to T04 (no THRUSPECIES) must lose it. The row is a
	// complete statement of the tier, not a delta.
	//
	// The scalar fields are the exception: zero means "the family did
	// not state one", so the authored Default survives. That keeps this
	// additive for the sixteen families that have no table yet.
	// =================================================================
	private void RS_ApplyTierProperties(RS_MonsterTierRow r)
	{
		int f = r.flags;

		// AGGRESSION AND SPACING -- the two that were actually costing us
		// the tier grammar. MissileChanceMult scales the "don't fire"
		// distance roll, so LOWER FIRES MORE (+MISSILEMORE == 0.5).
		// AVOIDMELEE keeps the monster at range instead of closing.
		bAVOIDMELEE       = (f & RS_TF_AVOIDMELEE)       != 0;
		if (r.missileChance > 0)
		{
			// THE LOCK VALVE. Owner-reported, and the mechanism checks
			// out: P_CheckMissileRange does
			//     dist = Distance2D - 64;
			//     if (MeleeState == NULL) dist -= 128;
			//     pr() >= min(int(dist * MissileChanceMult), MinMissileChance)
			// so at 0.0625 -- CH stacking +MISSILEMORE with
			// +MISSILEEVENMORE -- a monster at 500 units rolls
			// (500-192)*0.0625 = 19 and fires on ~93% of chase
			// decisions. It stops moving and hoses. Repointing
			// MeleeState (see ApplyTier) made this WORSE, because those
			// tiers now also get the -128 they were wrongly missing.
			//
			// The ROW KEEPS CH's REAL VALUE -- it is ground truth and a
			// clamped table is a table nobody can audit. The floor is
			// applied here, at use, and is a cvar so it can be tuned or
			// switched off (0) for full CHP fidelity without a rebuild.
			double floorMult = RS_MonOptF("rs_mon_missilechance_floor", 0.125);
			MissileChanceMult = (floorMult > 0)
			                    ? max(r.missileChance, floorMult)
			                    : r.missileChance;
		}

		// INFIGHTING AND PASS-THROUGH.
		bDONTHARMSPECIES  = (f & RS_TF_DONTHARMSPECIES)  != 0;
		bTHRUSPECIES      = (f & RS_TF_THRUSPECIES)      != 0;
		bDONTHARMCLASS    = (f & RS_TF_DONTHARMCLASS)    != 0;
		bNOINFIGHTING     = (f & RS_TF_NOINFIGHTING)     != 0;
		bNOTARGETSWITCH   = (f & RS_TF_NOTARGETSWITCH)   != 0;
		bNOTARGET         = (f & RS_TF_NOTARGET)         != 0;

		// PRESENTATION AND DEATH.
		bROLLSPRITE       = (f & RS_TF_ROLLSPRITE)       != 0;
		bNOICEDEATH       = (f & RS_TF_NOICEDEATH)       != 0;
		bEXTREMEDEATH     = (f & RS_TF_EXTREMEDEATH)     != 0;
		bNOBLOOD          = (f & RS_TF_NOBLOOD)          != 0;
		// +FLOORCLIP is deliberately NOT assigned here. Every CH parent
		// has it and so does every Default in this tree -- making it an
		// absolutely-assigned tier flag would silently CLEAR it for the
		// sixteen families that have no table yet.

		// THE BOSS SET. CH writes -NORADIUSDMG on every boss it makes,
		// so a boss here TAKES splash unless a family says otherwise.
		bBOSS             = (f & RS_TF_BOSS)             != 0;
		bQUICKTORETALIATE = (f & RS_TF_QUICKTORETALIATE) != 0;
		bLOOKALLAROUND    = (f & RS_TF_LOOKALLAROUND)    != 0;
		bNOFEAR           = (f & RS_TF_NOFEAR)           != 0;
		bDONTMORPH        = (f & RS_TF_DONTMORPH)        != 0;
		bLAXTELEFRAGDMG   = (f & RS_TF_LAXTELEFRAGDMG)   != 0;
		bNORADIUSDMG      = (f & RS_TF_TAKESRADIUSDMG)   == 0
		                    && (f & RS_TF_BOSS)          != 0;
		bBOSSDEATH        = (f & RS_TF_BOSSDEATH)        != 0;
		bSEEINVISIBLE     = (f & RS_TF_SEEINVISIBLE)     != 0;
		bNOTIMEFREEZE     = (f & RS_TF_NOTIMEFREEZE)     != 0;
		bCANTSEEK         = (f & RS_TF_CANTSEEK)         != 0;
		if (r.radiusDamageFactor > 0)
			RadiusDamageFactor = r.radiusDamageFactor;

		// THE HOVER SET. Assigned together and absolutely -- a floater
		// that retiers into a walker has to come back down, and NOGRAVITY
		// left on by accident is a monster stuck in the air forever.
		bNOGRAVITY        = (f & RS_TF_NOGRAVITY)        != 0;
		bFLOAT            = (f & RS_TF_FLOAT)            != 0;
		bFLOATBOB         = (f & RS_TF_FLOATBOB)         != 0;

		// SPECIES. The Undertaker and MrBones share "UnderTaker" -- that
		// is how a summoner does not shred its own summons.
		if (r.species != "")
			Species = r.species;

		// BODY. A_SetSize rather than raw radius/height: the engine has
		// to revalidate the position, and a bare assignment can leave the
		// actor stuck in geometry after a mid-fight retier.
		if (r.radius > 0 || r.height > 0)
		{
			A_SetSize(r.radius > 0 ? r.radius : radius,
			          r.height > 0 ? r.height : height);
		}
		// THE GHOST / FLOATER SET (families 05, 07, 09).
		int g = r.flags2;
		bSTEALTH           = (g & RS_TF2_STEALTH)           != 0;
		bSHADOW            = (g & RS_TF2_SHADOW)            != 0;
		bVISIBILITYPULSE   = (g & RS_TF2_VISIBILITYPULSE)   != 0;
		// +SHORTMISSILERANGE IS NOT A FLAG ON THIS ENGINE. GZDoom
		// deprecated it into a property, exactly like +MISSILEMORE ->
		// MissileChanceMult: it sets MaxTargetRange 896. Our own tree
		// corroborates the number -- the only two existing uses,
		// RS_Archvile.zs:107 and RS_human_projectiles.zs:1031, are both
		// 896. The const keeps CH's spelling so the tables still diff
		// against CH/decorate without a translation step; the
		// translation happens here, once.
		// Assigned ABSOLUTELY, like the flags it stands in for: a monster
		// retiering OFF a short-range tier has to lose the 896 again.
		// 0 is the engine's "no limit". An explicit r.maxTargetRange wins.
		MaxTargetRange = (r.maxTargetRange > 0) ? r.maxTargetRange
		               : (((g & RS_TF2_SHORTMISSILERANGE) != 0) ? 896 : 0);
		bSPAWNCEILING      = (g & RS_TF2_SPAWNCEILING)      != 0;
		bSPAWNFLOAT        = (g & RS_TF2_SPAWNFLOAT)        != 0;
		bDONTFALL          = (g & RS_TF2_DONTFALL)          != 0;
		bNOPAIN            = (g & RS_TF2_NOPAIN)            != 0;
		bDONTOVERLAP       = (g & RS_TF2_DONTOVERLAP)       != 0;
		bNOBLOODDECALS     = (g & RS_TF2_NOBLOODDECALS)     != 0;

		// TRANSPARENCY IS IDENTITY HERE. CH's gray spectre is Alpha 0.05
		// and the black is 0.45 -- near-invisible versus merely dim.
		if (r.renderStyle >= 0) A_SetRenderStyle(r.alpha > 0 ? r.alpha : alpha,
		                                         r.renderStyle);
		else if (r.alpha > 0)   A_SetRenderStyle(r.alpha, GetRenderStyle());

		if (r.meleeRange      > 0) MeleeRange     = r.meleeRange;
		if (r.meleeThreshold  > 0) MeleeThreshold = r.meleeThreshold;
		if (r.floatSpeed      > 0) FloatSpeed     = r.floatSpeed;
		// MaxTargetRange is handled with the SHORTMISSILERANGE
		// translation above -- one owner.

		if (r.mass  > 0) Mass = int(r.mass);
		if (r.scale > 0) A_SetScale(r.scale);
		// GibHealth IS READONLY on the instance -- "Expression must be a
		// modifiable value". The engine exposes it through the virtual
		// GetGibHealth() instead, so the row's value is stashed and the
		// override below serves it. Same shape as TierDamageFactor.
		rsTierGibHealth = r.gibHealth;
		rsTierNoneFactor = r.noneDamageFactor;
		// r.bloodColor is deliberately not applied -- see the field.
	}


	// CH states GibHealth on a few parents (FireBluZombie2 is -5: it comes
	// apart almost immediately, which is the point of a kamikaze). 0 in the
	// row means "the family did not state one" and the engine default
	// stands.
	override int GetGibHealth()
	{
		if (rsTierGibHealth != 0)
			return rsTierGibHealth;
		return Super.GetGibHealth();
	}


	// Per-tier DamageFactor. CH states these on the parent and they are
	// real gameplay -- the cyan and gray zombies take DOUBLE from fire
	// and melee, the fire zombie takes a QUARTER from fire, the bosses
	// take triple from "Heroic". Per-type factors live on the class
	// DEFAULTS in ZScript, so they cannot be assigned per instance;
	// this virtual plus the DamageMobj hook below is the per-instance
	// equivalent. 1.0 = unmodified.
	override double TierDamageFactor(int t, Name damageType)
	{
		return 1.0;
	}


	// =================================================================
	// BODY -- thirteen sprite names on one line, in ladder order.
	// "" anywhere in the table (or an empty table) means "leave the
	// authored sprite alone at that tier".
	// =================================================================

	virtual string BodyTable()
	{
		return "";
	}


	// Thirteen TRNSLATE names in ladder order, "-" for "no translation
	// at this tier". A tier with "-" is NOT unfinished -- it means that
	// tier wears a bespoke sprite that is already the right colour, or
	// uses a RenderStyle instead of a palette remap. Colourful Hell does
	// both, so we have to as well.
	virtual string TintTable()
	{
		return "";
	}


	private void RS_ParseTables()
	{
		if (rsTablesParsed)
			return;

		string b = BodyTable();
		if (b.Length() > 0) b.Split(rsBodies, " ");

		string t = TintTable();
		if (t.Length() > 0) t.Split(rsTints, " ");

		rsTablesParsed = true;
	}


	// Read-only views of the parsed tables, for diagnostics. Return "" when
	// the tier falls off the end of a short table -- which is itself the
	// answer to "why doesn't this tier change appearance".
	string RS_DbgBodyToken(int t)
	{
		RS_ParseTables();
		return (t >= 0 && t < rsBodies.Size()) ? rsBodies[t] : "";
	}


	string RS_DbgTintToken(int t)
	{
		RS_ParseTables();
		return (t >= 0 && t < rsTints.Size()) ? rsTints[t] : "";
	}


	// Tint only, on tier change only. The sprite half of the old
	// "wear body" system is GONE -- bodies are real per-tier state
	// clusters now (see TierState below), never runtime assignment.
	override void RS_ApplyTint()
	{
		RS_ParseTables();

		if (Tier >= 0 && Tier < rsTints.Size())
		{
			string tn = rsTints[Tier];
			// "-" is the explicit "this tier has no translation" marker.
			// Setting "" here is a harmless no-op that also CLEARS a
			// translation left over from a previous tier, which is what
			// we want when tiering down into an untranslated body.
			A_SetTranslation(tn == "-" ? "" : tn);
		}
	}


	// Resolve "prefix.<current tier>", falling back to "prefix.T00" for
	// tiers that share the base body, then to null (caller's fallback
	// line handles it). Families stack labels for shared bodies; the
	// fallback is a safety net, not the design.
	override State TierState(string prefix)
	{
		State st = FindStateByString(prefix .. "." .. TierLabel(Tier), true);
		if (st) return st;

		st = FindStateByString(prefix .. ".T00", true);
		if (st) return st;

		// FALL BACK TO THE PLAIN LABEL. Added 2026-08-05.
		//
		// Without this, a class that simply writes `Missile:` -- which is
		// what every ordinary actor in Doom writes -- got NULL back, so
		// ApplyTier set MissileState = null and THE MONSTER NEVER FIRED.
		// It cost five files in family 04 alone, including both bosses
		// and the EX, and every one of them looked correct on the page.
		//
		// The .T00 requirement made sense when ONE class held fourteen
		// tiers and every label needed a tier suffix to be told apart.
		// Under the CH rebuild each creature is its own class with one
		// set of states, so demanding a suffix meant every file carried
		// a block of `Missile.T00: Goto Missile;` aliases whose only
		// purpose was to satisfy this lookup. That is scaffolding for a
		// problem that no longer exists.
		//
		// The two suffixed lookups still run FIRST, so nothing that uses
		// tier clusters changes behaviour.
		return FindStateByString(prefix, true);
	}


	// AUDIT support (RS_MonsterDebug). Reports tier clusters this class
	// is missing where the BodyTable says the tier wears a body DIFFERENT
	// from T00's -- those are the tiers where the T00 fallback would show
	// the wrong creature. Same-body tiers legitimately share clusters and
	// are not flagged. Missile and Melee count as one slot (melee-only
	// bodies are legal).
	string RS_AuditClusters()
	{
		string missing = "";
		string base = RS_DbgBodyToken(0);
		for (int t = 1; t <= 12; t++)
		{
			if (RS_DbgBodyToken(t) == base)
				continue;
			string lbl = TierLabel(t);
			if (!FindStateByString("See." .. lbl, true))
				missing = missing .. "See." .. lbl .. " ";
			if (!FindStateByString("Spawn." .. lbl, true))
				missing = missing .. "Spawn." .. lbl .. " ";
			if (!FindStateByString("Pain." .. lbl, true))
				missing = missing .. "Pain." .. lbl .. " ";
			if (!FindStateByString("Death." .. lbl, true))
				missing = missing .. "Death." .. lbl .. " ";
			if (!FindStateByString("Missile." .. lbl, true)
			    && !FindStateByString("Melee." .. lbl, true))
				missing = missing .. "Attack." .. lbl .. " ";
		}
		return missing;
	}


	// =================================================================
	// ATTACKS -- the same RS_AttackSlot the guns use.
	// =================================================================

	// Null = this tier has no data-driven attack and the family is
	// handling it in states.
	virtual RS_AttackSlot BuildTierAttacks(int t)
	{
		return null;
	}


	void BuildAttacksForTier(int t)
	{
		if (rsAttacksBuiltFor == t)
			return;
		CurrentAttacks = BuildTierAttacks(t);
		rsAttacksBuiltFor = t;
	}

}
