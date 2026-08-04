// =====================================================================
// RS_Mancubus -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\13\13_<code>.txt
// One CHP file per colour; each is a genuinely different creature with
// its OWN sprite set, stats, and attack. CH decorate/Fatsos.txt is only
// consulted for states CHP leaves undefined (the CHP actors inherit from
// it). Nothing here is inferred, tinted, or shared -- every tier below
// was read out of its CHP file.
//
//   tier  CHP   body   HP     what it actually is
//   T00   13_C  FATT     600  vanilla fatso: FatShot2 triple spread
//   T01   13_G  FATG     750  green: paired acid bombs
//   T02   13_B  FTSB     850  blue: plasma waves OR a charged beam burst
//   T03   13_CY FATC     720  cyan crystal: ice fat-balls, bounces away,
//                             and body-slams from close range
//   T04   13_P  HECT    1024  purple Hectebus: bouncing bombs, or a
//                             hitscan "swoosh" if you are above it
//   T05   13_Y  INCB    1250  yellow Incubus: homing rockets / seekers
//   T06   13_A  UNMB    2150  abyss "Ralph Bluetawn": floats, bomb pairs
//                             or a six-shot abyss wave fan
//   T07   13_F  FATF    1400  fireblu blob: ten-ball dump or twin heavies
//   T08   13_BR FFAT     950  brown: electric arcs + bass soundwave, and
//                             a point-blank vile-zap if you close in
//   T09   13_GY FTGR    1000  gray: spike volleys, scrap-spray up close
//   T10   13_R  HBST    1600  red Horned Beast: rage meter -- five pains
//                             and it goes no-flinch and faster
//   T11   13_K  BDEM    9001  BLACK SHADOW BEAST: seven patterns and a
//                             phase-2 below 5500 HP
//   T12   13_W  QUEE   15000  WHITE "Angry Mama": railgun, ball barrage,
//                             ground nuke, spread shot, point-blank zap
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
//
// RS mechanics preserved from the previous file: the T07+ phase gate
// (BuildTierAttacks swaps the pool once ThresholdFired), the close-range
// Panic ring, the Enrage-on-threshold in the Pain dispatcher, and
// GetBaseKeywords. Family-wide rolls live in the dispatcher overrides so
// every tier cluster inherits them without repeating the roll.
// =====================================================================

class RS_Mancubus : RS_MonsterMaster replaces Fatso
{
	// CHP's red Horned Beast counts pains in User_Rage5; user vars are
	// not a thing here, so it is a private field (same contract as
	// rsDashBudget/rsPhase2Done in RS_Cacodemon).
	private int rsRage;

	Default
	{
		Health 600;
		Radius 48;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 80;
		Monster;
		+FLOORCLIP +BOSSDEATH
		SeeSound "fatso/sight";   PainSound "fatso/pain";
		DeathSound "fatso/death"; ActiveSound "fatso/active";
		Obituary "$OB_FATSO";
		Tag "Mancubus";
	}

	// CHP's real per-colour numbers, read from 13_*.txt. Health is
	// absolute in CHP -- expressed here as a multiplier off the Default
	// so the base class's recompute-from-defaults contract still holds.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 80; r.dmgMul = 1.0;
		int hp = 600; int spd = 8;
		switch (t)
		{
			case 0:  hp = 600;   spd = 8;  r.painChance = 80; r.dmgMul = 1.0; break;
			case 1:  hp = 750;   spd = 8;  r.painChance = 70; r.dmgMul = 1.1; break;
			case 2:  hp = 850;   spd = 8;  r.painChance = 60; r.dmgMul = 1.2; break;
			case 3:  hp = 720;   spd = 11; r.painChance = 70; r.dmgMul = 1.3; break;
			case 4:  hp = 1024;  spd = 8;  r.painChance = 20; r.dmgMul = 1.4; break;
			case 5:  hp = 1250;  spd = 8;  r.painChance = 14; r.dmgMul = 1.5; break;
			case 6:  hp = 2150;  spd = 11; r.painChance = 12; r.dmgMul = 1.7; break;
			case 7:  hp = 1400;  spd = 8;  r.painChance = 45; r.dmgMul = 1.5; break;
			case 8:  hp = 950;   spd = 11; r.painChance = 70; r.dmgMul = 1.4; break;
			case 9:  hp = 1000;  spd = 5;  r.painChance = 20; r.dmgMul = 1.5; break;
			case 10: hp = 1600;  spd = 10; r.painChance = 34; r.dmgMul = 1.8; break;
			case 11: hp = 9001;  spd = 14; r.painChance = 24; r.dmgMul = 2.5; break;
			case 12: hp = 15000; spd = 18; r.painChance = 20; r.dmgMul = 3.0; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 600.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/Mancubus/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "FATT FATG FTSB FATC HECT INCB UNMB FATF FFAT FTGR HBST BDEM QUEE";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:mancubus role:artillery delivery:heavy payload:multi element:thermal mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE PHASE GATE. From T07 up it carries a second attack pool that
	// only unlocks once it has been hurt past the threshold -- the pool
	// is REPLACED, not buffed, so the fight reads as a different fight.
	// Plus the close-range panic button: get inside its guard and it
	// detonates a full ring instead of lobbing over your head.
	// -----------------------------------------------------------------
	const RS_MANC_TIER_PHASE  = 7;
	const RS_MANC_PHASE_SLOT  = 0;
	const RS_MANC_PANIC_RANGE = 220.0;

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_MANC_TIER_PHASE)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_MancFire(), 3, 24.0,
			"fatso/attack", 1.0, 0.0, "Triple Lob"));

		// Phase two replaces the pool -- denser and wider, not just
		// bigger numbers on the same attack.
		if (ThresholdFired(RS_MANC_PHASE_SLOT))
		{
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_MancFire(), 8, 90.0,
				"fatso/attack", 1.0, 4.0, "Weave"));
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_MancFire(), 16, 360.0,
				"fatso/attack", 1.0, 6.0, "Full Bloom"));
		}
		return slot;
	}

	States
	{
	// ===== dispatcher overrides: family-wide mechanics roll here =====
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_MANC_TIER_PHASE && target
			    && Distance3D(target) < RS_MANC_PANIC_RANGE
			    && random(0, 255) < 96)
				return ResolveState("Panic");
			if (Tier >= RS_MANC_TIER_PHASE && random(0, 255) < 64)
				return ResolveState("Barrage");
			return TierState("Missile");
		}
		Goto See;
	Barrage:
		// Bare #### = keep whatever body sprite we are wearing. G/H/I
		// exist on every mancubus body (FATT FATG FTSB FATC HECT INCB
		// UNMB FATF FFAT FTGR HBST BDEM QUEE -- verified on disk).
		#### G 14 { A_FatRaise(); }
		#### H 10 Bright { A_RS_MonsterFire(); }
		#### IG 5 { A_FaceTarget(); }
		#### H 10 Bright { A_RS_MonsterFire(); }
		Goto See;
	Panic:
		#### G 12 { A_FatRaise(); }
		#### H 12 Bright
		{
			FireProfile(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_MancFire(), 20, 360.0,
				"fatso/attack", 1.0, 8.0, "Panic Ring"));
		}
		#### I 12;
		Goto See;
	Pain:
		TNT1 A 0
		{
			if (Tier >= RS_MANC_TIER_PHASE && CheckThreshold(RS_MANC_PHASE_SLOT, 0.6))
			{
				Enrage(1.25);
				BuildAttacksForTier(-1);
				BuildAttacksForTier(Tier);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			}
			return TierState("Pain");
		}
		Goto See;

	// ================= T00 COMMON (13_C) =================
	// The stock silhouette, but CH swaps FatShot for FatShot2 and the
	// death chain is CH's FAT2 crumple that leaves an armed corpse.
	Spawn.T00:
		"FATT" AB 15 { A_Look(); }
		Loop;
	See.T00:
		"FATT" AABBCCDDEEFF 4 { A_Chase(); }
		Loop;
	Missile.T00:
		"FATT" G 0 { A_FaceTarget(); }
		"FATT" G 20 { A_StartSound("fatso/raiseguns", CHAN_WEAPON); }
		"FATT" H 0 { A_SpawnProjectile("RS_FatShot2", 32, 0, 11.25); }
		"FATT" H 10 Bright { A_SpawnProjectile("RS_FatShot2", 32, 0, 0); }
		"FATT" IG 5 { A_FaceTarget(); }
		"FATT" H 0 { A_SpawnProjectile("RS_FatShot2", 32, 0, -11.25); }
		"FATT" H 10 Bright { A_SpawnProjectile("RS_FatShot2", 32, 0, 0); }
		"FATT" IG 5 { A_FaceTarget(); }
		"FATT" H 0 { A_SpawnProjectile("RS_FatShot2", 32, 0, 5.625); }
		"FATT" H 10 Bright { A_SpawnProjectile("RS_FatShot2", 32, 0, -5.625); }
		"FATT" IG 5 { A_FaceTarget(); }
		Goto See;
	Pain.T00:
		"FATT" J 3;
		"FATT" J 3 { A_Pain(); }
		Goto See;
	Death.T00:
		"FAT2" A 5;
		"FAT2" B 5 { A_Scream(); }
		"FAT2" C 5 { A_NoBlocking(); }
		"FAT2" DE 5;
		"FAT2" F 5 { A_SpawnItemEx("RS_FatsoArmed", 0, 0, 3); }
		"FAT2" G 5 { A_BossDeath(); }
		"FAT2" H -1;
		Stop;
	XDeath.T00:
		"FATT" K 6;
		"FATT" L 6 { A_Scream(); }
		"FATT" M 6 { A_NoBlocking(); }
		"FATT" NOPQRS 6;
		"FATT" T 1 { A_BossDeath(); }
		"FATT" T -1;
		Stop;
	Raise.T00:
		"FAT2" H 5;
		"FAT2" GFEDCBA 5;
		Goto See;

	// ================= T01 GREEN (13_G) =================
	// Paired acid bombs, three volleys, alternating shoulders.
	Spawn.T01:
		"FATG" AB 15 { A_Look(); }
		Loop;
	See.T01:
		"FATG" AABBCCDDEEFF 4 { A_Chase(); }
		Loop;
	Missile.T01:
		"FATG" G 0 { A_FaceTarget(); }
		"FATG" G 20 { A_StartSound("fatso/raiseguns", CHAN_WEAPON); }
		"FATG" H 10 Bright { A_SpawnProjectile("RS_GreenBomb1", 20, 13, random(-5, 6)); }
		"FATG" H 0 Bright { A_SpawnProjectile("RS_GreenBomb1", 20, -13, random(-6, 5)); }
		"FATG" IG 5 { A_FaceTarget(); }
		"FATG" H 10 Bright { A_SpawnProjectile("RS_GreenBomb1", 20, 13, random(-7, 5)); }
		"FATG" H 0 Bright { A_SpawnProjectile("RS_GreenBomb1", 20, -13, random(-5, 7)); }
		"FATG" IG 5 { A_FaceTarget(); }
		"FATG" H 10 Bright { A_SpawnProjectile("RS_GreenBomb1", 20, 13, random(-8, 5)); }
		"FATG" H 0 Bright { A_SpawnProjectile("RS_GreenBomb1", 20, -13, random(-5, 8)); }
		"FATG" IG 5;
		Goto See;
	Pain.T01:
		"FATG" J 3;
		"FATG" J 3 { A_Pain(); }
		Goto See;
	Death.T01:
		"FAT3" A 5;
		"FAT3" B 5 { A_Scream(); }
		"FAT3" C 5 { A_NoBlocking(); }
		"FAT3" D 5;
		"FAT3" E 5;
		"FAT3" F 5 { A_SpawnItemEx("RS_FatsoArmed2", 0, 0, 3); }
		"FAT3" G 5 { A_BossDeath(); }
		"FAT3" H -1;
		Stop;
	XDeath.T01:
		"FATG" K 6;
		"FATG" L 6 { A_Scream(); }
		"FATG" M 6 { A_NoBlocking(); }
		"FATG" NOPQRS 6;
		"FATG" T 1 { A_BossDeath(); }
		"FATG" T -1;
		Stop;
	Raise.T01:
		"FAT3" H 5;
		"FAT3" GFEDCBA 5;
		Goto See;

	// ================= T02 BLUE (13_B) =================
	// Two modes: a rolling wave pair, or a charged beam that tightens
	// its spread as it fires and can chain into itself.
	Spawn.T02:
		"FTSB" AB 15 { A_Look(); }
		Loop;
	See.T02:
		"FTSB" AABBCCDDEEFF 4 { A_Chase(); }
		Loop;
	Missile.T02:
		"FTSB" G 0 { A_FaceTarget(); }
		"FTSB" G 17 { A_StartSound("fatso/raiseguns", CHAN_WEAPON); }
		"FTSB" G 0 A_Jump(256, "Missile.T02.Waves", "Missile.T02.Beam");
		Goto Missile.T02.Waves;
	Missile.T02.Waves:
		"FTSB" H 8 Bright { A_SpawnProjectile("RS_Bluewave1", 20, 21, random(-6, 1)); }
		"FTSB" H 0 { A_SpawnProjectile("RS_Bluewave1", 20, -21, random(-1, 6)); }
		"FTSB" IG 7;
		"FTSB" H 8 Bright { A_SpawnProjectile("RS_Bluewave1", 20, 21, random(-1, 6)); }
		"FTSB" H 0 { A_SpawnProjectile("RS_Bluewave1", 20, -21, random(-6, 1)); }
		"FTSB" IG 7;
		"FTSB" H 8 Bright { A_SpawnProjectile("RS_Bluewave1", 20, 21, random(-5, 5)); }
		"FTSB" H 0 { A_SpawnProjectile("RS_Bluewave1", 20, -21, random(-8, 8)); }
		"FTSB" IG 7;
		Goto See;
	Missile.T02.Beam:
		"FTSB" H 0 { A_SpawnProjectile("RS_BlueFT", 12, 0, 0); }
		"FTSB" H 16 Bright { A_FaceTarget(); }
		"FTSB" I 7 Bright { A_FaceTarget(); }
		"FTSB" G 8 Bright { A_SpawnProjectile("RS_BlueFT2", 20, 0, 0); }
		"FTSB" H 5 Bright { A_SpawnProjectile("RS_BlueFT2", 20, 0, random(-4, 4)); }
		"FTSB" I 4 Bright { A_SpawnProjectile("RS_BlueFT2", 20, 0, random(-9, 9)); }
		"FTSB" H 3 Bright { A_SpawnProjectile("RS_BlueFT2", 20, 0, random(-16, 16)); }
		"FTSB" H 2 Bright A_Jump(128, "Missile.T02.Beam", "Missile.T02");
		Goto See;
	Pain.T02:
		"FTSB" J 3;
		"FTSB" J 3 { A_Pain(); }
		Goto See;
	Death.T02:
		"FAT4" A 5;
		"FAT4" B 5 { A_Scream(); }
		"FAT4" C 5 { A_NoBlocking(); }
		"FAT4" DE 5;
		"FAT4" F 5 { A_SpawnItemEx("RS_FatsoArmed3", 0, 0, 3); }
		"FAT4" G 5 { A_BossDeath(); }
		"FAT4" H -1;
		Stop;
	XDeath.T02:
		"FTSB" K 6;
		"FTSB" L 6 { A_Scream(); }
		"FTSB" M 6 { A_NoBlocking(); }
		"FTSB" NOPQRS 6;
		"FTSB" T 1 { A_BossDeath(); }
		"FTSB" T -1;
		Stop;
	Raise.T02:
		"FAT4" H 5;
		"FAT4" GFEDCBA 5;
		Goto See;

	// ================= T03 CYAN (13_CY) =================
	// The Crystal Fatso. It hops away when hurt, sprints in bursts,
	// throws ice fat-balls in two patterns, and body-slams from close
	// range. Shatters on death.
	Spawn.T03:
		"FATC" AB 15 { A_Look(); }
		Loop;
	See.T03:
		"FATC" AABBCCDDEEFF 3 { A_Chase(); }
		"FATC" A 0 A_Jump(64, "See.T03.Hop");
		"FATC" A 0 A_Jump(232, "See.T03.Look", "See.T03.Fast");
		Loop;
	See.T03.Fast:
		"FATC" AABBCCDDEEFF 1 { A_FastChase(); }
		Goto See;
	See.T03.Look:
		// CHP gates this on a CallACS bounce counter; ACS is stripped,
		// so the LOS check alone decides.
		"FATC" A 0 A_JumpIfInTargetLOS("See.T03.Jumpy", 0, JLOSF_DEADNOJUMP, 750);
		Goto See;
	See.T03.Jumpy:
		"FATC" A 2;
		"FATC" A 1 { Vel.Z += 16; }
		"FATC" A 3
		{
			double a = angle - randompick(90, 130, 180, 230, 270);
			Vel.X += 12 * cos(a); Vel.Y += 12 * sin(a);
		}
		"FATC" A 1 { Vel.Z += 8; }
		"FATC" A 1
		{
			double a = angle + frandom(120, 240);
			Vel.X += 18 * cos(a); Vel.Y += 18 * sin(a);
		}
		Goto See;
	See.T03.Hop:
		"FATC" J 3;
		"FATC" J 3 { Vel.Z += 18; }
		"FATC" J 6
		{
			double a = angle - 180;
			Vel.X += 18 * cos(a); Vel.Y += 18 * sin(a);
		}
		Goto See;
	Missile.T03:
		"FATC" A 0 A_Jump(128, "Missile.T03.Slam");
	Missile.T03.Guns:
		"FATC" G 20 { A_StartSound("fatso/raiseguns", CHAN_WEAPON); }
		"FATC" A 0 A_Jump(102, "Missile.T03.Alt");
		"FATC" H 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, -21, random(-1, 1)); }
		"FATC" H 10 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, 21, random(-1, 1)); }
		"FATC" H 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, -21, random(-3, 3)); }
		"FATC" H 5 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, 21, random(-3, 3)); }
		"FATC" IG 5 { A_FaceTarget(); }
		"FATC" A 0 A_CheckSight("See");
		"FATC" H 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, -21, random(-3, 3)); }
		"FATC" H 5 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, 21, random(-3, 3)); }
		"FATC" H 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, -21, random(-5, 5)); }
		"FATC" H 2 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, 21, random(-5, 5)); }
		"FATC" I 15;
		Goto See;
	Missile.T03.Alt:
		"FATC" G 5 { A_FaceTarget(); }
		"FATC" H 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, 21, random(1, 11)); }
		"FATC" H 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, 21, random(-1, 1)); }
		"FATC" H 8 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, 21, random(-11, -1)); }
		"FATC" I 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, -21, random(-11, 1)); }
		"FATC" I 0 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, -21, random(-1, 1)); }
		"FATC" I 8 Bright { A_SpawnProjectile("RS_CyanFatBall", 18, -21, random(1, 11)); }
		Goto See;
	Missile.T03.Slam:
		"FATC" A 0 A_JumpIfCloser(500, "Missile.T03.Slam2", true);
		Goto Missile.T03.Guns;
	Missile.T03.Slam2:
		"FATC" J 10 { A_FaceTarget(); }
		"FATC" J 20 { A_SkullAttack(50); }
		"FATC" J 10 { A_Stop(); }
		"FATC" J 0 { A_SetSpeed(11); }
		Goto Missile.T03;
	Pain.T03:
		"FATC" J 3;
		"FATC" J 3 { A_Pain(); }
		"FATC" J 1 A_Jump(64, "See.T03.Hop");
		Goto See;
	Death.T03:
		"FATC" K 6;
		"FATC" L 6 { A_Scream(); }
		"FATC" M 6 { A_NoBlocking(false); }
		"FATC" NOPQRS 6;
		"FATC" T 1 { A_BossDeath(); }
		"FATC" T 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		"FATC" T 1 { A_Burst("IceChunk"); }
		"FATC" T -1;
		Stop;

	// ================= T04 PURPLE (13_P) =================
	// The Hectebus. Bouncing bombs at range; if you are ABOVE it, or on
	// a roll, it switches to a hitscan burst instead.
	Spawn.T04:
		"HECT" AB 15 { A_Look(); }
		Loop;
	See.T04:
		"HECT" AABBCCDDEEFF 4 { A_Chase(); }
		Loop;
	Missile.T04:
		"HECT" G 0 { A_FaceTarget(); }
		"HECT" G 17 { A_StartSound("mancubus2/attack", CHAN_WEAPON); }
	Missile.T04.Pick:
		// CHP uses the higher-or-lower jump with an EMPTY "lower" label
		// (i.e. a plain fallthrough); spelled out here instead.
		TNT1 A 0
		{
			if (target && target.pos.z > pos.z + 32)
				return ResolveState("Missile.T04.Swoosh");
			return ResolveState(null);
		}
		"HECT" G 0 A_JumpIfCloser(1550, "Missile.T04.Boing1");
		"HECT" G 0 A_Jump(256, "Missile.T04.Swoosh");
		Goto See;
	Missile.T04.Boing1:
		"HECT" H 11 Bright { A_SpawnProjectile("RS_PurpleBomb1", 20, 13, random(-5, 9)); }
		"HECT" H 0 { A_SpawnProjectile("RS_PurpleBomb1", 20, -13, random(-9, 5)); }
		"HECT" IG 7 { A_FaceTarget(); }
		"HECT" H 11 Bright { A_SpawnProjectile("RS_PurpleBomb1", 20, 13, random(-9, 5)); }
		"HECT" H 0 { A_SpawnProjectile("RS_PurpleBomb1", 20, -13, random(-5, 9)); }
		"HECT" IG 7 { A_FaceTarget(); }
		"HECT" H 11 Bright { A_SpawnProjectile("RS_PurpleBomb1", 20, 13, random(-9, 9)); }
		"HECT" H 0 { A_SpawnProjectile("RS_PurpleBomb1", 20, -13, random(-9, 9)); }
		"HECT" IG 7;
		Goto See;
	Missile.T04.Swoosh:
		"HECT" H 0 { A_StartSound("Ratata/rata1", CHAN_WEAPON, CHANF_DEFAULT, 1.9); }
		"HECT" H 5 Bright { A_CustomBulletAttack(15, 1, random(1, 8), random(1, 3), "RS_FatsoPuff3", 8000); }
		"HECT" IG 3 A_MonsterRefire(180, "See");
		Goto Missile.T04.Pick;
	Pain.T04:
		"HECT" J 3;
		"HECT" J 3 { A_Pain(); }
		Goto See;
	Death.T04:
	XDeath.T04:
		"HECT" K 6;
		"HECT" L 6 { A_Scream(); }
		"HECT" M 6 { A_NoBlocking(); }
		"HECT" NOPQRS 6;
		"HECT" T 1 { A_BossDeath(); }
		"HECT" T -1;
		Stop;
	Raise.T04:
		"HECT" R 5;
		"HECT" QPONMLK 5;
		Goto See;

	// ================= T05 YELLOW (13_Y) =================
	// The Incubus: a rocket salvo, or paired seekers. Picks the rocket
	// branch only when the target is inside 1750.
	Spawn.T05:
		"INCB" AD 10 { A_Look(); }
		Loop;
	See.T05:
		"INCB" AAABBB 4 { A_Chase(); }
		"INCB" A 0 { A_StartSound("incubus/walk", CHAN_BODY); }
		"INCB" CCCDDD 4 { A_Chase(); }
		"INCB" C 0 { A_StartSound("incubus/walk", CHAN_BODY); }
		Loop;
	Missile.T05:
		"INCB" E 0 A_JumpIfCloser(1750, "Missile.T05.Choice");
		"INCB" E 0 A_Jump(256, "Missile.T05.Alt");
		Goto See;
	Missile.T05.Choice:
		"INCB" E 0 A_Jump(256, "Missile.T05.Rocketo", "Missile.T05.Alt");
		Goto Missile.T05.Rocketo;
	Missile.T05.Rocketo:
		"INCB" E 0 { A_StartSound("incubus/attack1", CHAN_WEAPON); }
		"INCB" EEE 5 { A_FaceTarget(); }
		"INCB" F 8 Bright { A_SpawnProjectile("RS_RocketShotFatso", 35, 42, random(-3, 3)); }
		"INCB" G 2 Bright { A_SpawnProjectile("RS_RocketShotFatso", 34, -39, random(-6, 6)); }
		"INCB" E 4 { A_FaceTarget(); }
		"INCB" G 8 Bright { A_SpawnProjectile("RS_RocketShotFatso", 34, -39, random(-3, 3)); }
		"INCB" F 2 Bright { A_SpawnProjectile("RS_RocketShotFatso", 35, 42, random(-6, 6)); }
		"INCB" E 4 { A_FaceTarget(); }
		"INCB" F 8 Bright { A_SpawnProjectile("RS_RocketShotFatso", 35, 42, random(-3, 3)); }
		"INCB" G 2 Bright { A_SpawnProjectile("RS_RocketShotFatso", 34, -39, random(-6, 6)); }
		"INCB" E 4 { A_FaceTarget(); }
		"INCB" G 8 Bright { A_SpawnProjectile("RS_RocketShotFatso", 34, -39, random(-3, 3)); }
		"INCB" F 2 Bright { A_SpawnProjectile("RS_RocketShotFatso", 35, 42, random(-6, 6)); }
		"INCB" EE 5 { A_FaceTarget(); }
		Goto See;
	Missile.T05.Alt:
		"INCB" E 0 { A_StartSound("incubus/attack2", CHAN_WEAPON); }
		"INCB" EEE 5 { A_FaceTarget(); }
		"INCB" H 0 { A_SpawnProjectile("RS_FatsoShotYE", 72, -12, random(-3, 3)); }
		"INCB" H 5 Bright { A_SpawnProjectile("RS_FatsoShotYE", 72, 12, random(-3, 3)); }
		"INCB" E 5 { A_FaceTarget(); }
		"INCB" H 0 { A_SpawnProjectile("RS_FatsoShotYE", 72, -12, random(-3, 3)); }
		"INCB" H 5 Bright { A_SpawnProjectile("RS_FatsoShotYE", 72, 12, random(-3, 3)); }
		"INCB" E 5 { A_FaceTarget(); }
		"INCB" H 0 { A_SpawnProjectile("RS_FatsoShotYE", 72, -12, random(-3, 3)); }
		"INCB" H 5 Bright { A_SpawnProjectile("RS_FatsoShotYE", 72, 12, random(-3, 3)); }
		"INCB" EE 5 { A_FaceTarget(); }
		Goto See;
	Pain.T05:
		"INCB" D 5;
		"INCB" C 5 { A_Pain(); }
		Goto See;
	Death.T05:
	XDeath.T05:
		"INCB" I 12 { A_Scream(); }
		"INCB" J 12;
		"INCB" K 8 { A_Fall(); }
		"INCB" LM 8;
		"INCB" N -1 { A_BossDeath(); }
		Stop;
	Raise.T05:
		"INCB" NMLKJI 10;
		Goto See;

	// ================= T06 ABYSS (13_A) =================
	// Floats, trails abyss splash as it walks, and alternates a bomb
	// pair with a six-shot wave fan. CHP marks it unraisable.
	Spawn.T06:
		"UNMB" A 0 { bFLOAT = true; bNOGRAVITY = true; bFLOORCLIP = false; }
		"UNMB" AB 15 { A_Look(); }
		Loop;
	See.T06:
		"UNMB" A 0 { bFLOAT = true; bNOGRAVITY = true; }
		"UNMB" AA 3 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"UNMB" BB 3 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		Loop;
	Missile.T06:
		"UNMB" C 10 { A_StartSound("mancubus2/attack", CHAN_WEAPON); }
		"UNMB" CD 5 { A_FaceTarget(); }
		"UNMB" D 0 A_Jump(128, "Missile.T06.Waves");
		"UNMB" E 0 { A_StartSound("horn/attack", CHAN_WEAPON); }
		"UNMB" EEEE 7 Bright { A_SpawnProjectile("RS_AbyssFatsoBomb", 32, 32, random(-17, 4)); }
		"UNMB" D 10 { A_FaceTarget(); }
		"UNMB" E 0 { A_StartSound("horn/attack", CHAN_WEAPON); }
		"UNMB" EEEE 7 Bright { A_SpawnProjectile("RS_AbyssFatsoBomb", 32, -32, random(-4, 17)); }
		"UNMB" CD 5 { A_FaceTarget(); }
		Goto See;
	Missile.T06.Waves:
		"UNMB" E 2 Bright { A_StartSound("spit/spit2", CHAN_WEAPON); }
		"UNMB" EE 0 { A_SpawnProjectile("RS_FatAbysswave", random(16, 42), 32, random(-18, -10)); }
		"UNMB" EE 0 { A_SpawnProjectile("RS_FatAbysswave", random(16, 42), 32, random(-12, -5)); }
		"UNMB" E 9 Bright { A_SpawnProjectile("RS_FatAbysswave", random(16, 42), 32, random(-7, 4)); }
		"UNMB" EE 0 { A_SpawnProjectile("RS_FatAbysswave", random(16, 42), 32, random(10, 18)); }
		"UNMB" EE 0 { A_SpawnProjectile("RS_FatAbysswave", random(16, 42), 32, random(5, 12)); }
		"UNMB" E 9 Bright { A_SpawnProjectile("RS_FatAbysswave", random(16, 42), -32, random(-4, 7)); }
		"UNMB" CD 5 { A_FaceTarget(); }
		Goto See;
	Pain.T06:
		"UNMB" F 4;
		"UNMB" F 4 { A_Pain(); }
		Goto Missile;
	Death.T06:
		"UNMB" G 7 { A_SetFloorClip(); }
		"UNMB" H 6 { A_Scream(); }
		"UNMB" I 6 { A_NoBlocking(); }
		"UNMB" JKLM 5 { A_UnsetSolid(); }
		"UNMB" N -1 { A_BossDeath(); }
		Stop;

	// ================= T07 FIREBLU (13_F) =================
	// Smokes while it idles and walks. Ten-ball dump at range; inside
	// 1200 it switches to the twin heavy balls.
	Spawn.T07:
		"FATF" A 0 A_Jump(81, "Spawn.T07.Smoke");
		"FATF" A 10 { A_Look(); }
		Loop;
	Spawn.T07.Smoke:
		"FATF" A 0 { A_SpawnProjectile("RS_HBeastSmoke", 64, 0, 0); }
		Goto Spawn.T07;
	See.T07:
		"FATF" A 0 A_Jump(81, "See.T07.Smoke");
		"FATF" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.T07.Smoke:
		"FATF" A 0 { A_SpawnProjectile("RS_HBeastSmoke", 64, 0, 0); }
		Goto See.T07;
	Missile.T07:
		"FATF" E 0 A_JumpIfCloser(1200, "Missile.T07.Fires");
		"FATF" E 10 { A_FaceTarget(); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, 20, random(-1, 1)); }
		"FATF" E 3 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, -20, random(-1, 1)); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, -20, 0); }
		"FATF" E 3 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, 20, 0); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, 20, random(-1, 1)); }
		"FATF" E 3 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, -20, random(-1, 1)); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, 20, 0); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, -20, 0); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, 20, 0); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBall", 32, -20, 0); }
		"FATF" E 5 { A_FaceTarget(); }
		Goto See;
	Missile.T07.Fires:
		"FATF" E 12 { A_FaceTarget(); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBal2", 32, 20, 0); }
		"FATF" E 0 { A_SpawnProjectile("RS_FireBluFatsoBal2", 32, -20, 0); }
		"FATF" E 5 { A_FaceTarget(); }
		Goto See;
	Pain.T07:
		"FATF" F 3;
		"FATF" F 5 { A_Pain(); }
		Goto See;
	Death.T07:
		"FATF" G 8 { A_Scream(); }
		"FATF" H 7 { A_StartSound("horn/shotx", CHAN_VOICE); }
		"FATF" I 6 { A_Fall(); }
		"FATF" JK 5;
		"FATF" LMNO 4;
		"FATF" P 1;
		"FATF" P -1 { A_BossDeath(); }
		Stop;

	// ================= T08 BROWN (13_BR) =================
	// Four electric arc pairs into a bass soundwave. Inside 300 it
	// swaps to a charged vile-zap instead and then rejoins the volley.
	Spawn.T08:
		"FFAT" AB 15 { A_Look(); }
		Loop;
	See.T08:
		"FFAT" AABBCCDDEEFF 4 { A_Chase(); }
		Loop;
	Missile.T08:
		"FFAT" G 0 { A_FaceTarget(); }
		"FFAT" G 10 { A_StartSound("fatso/raiseguns", CHAN_WEAPON); }
		TNT1 A 0 A_JumpIfCloser(300, "Missile.T08.Close");
		"FFAT" G 1 { A_StartSound("ELECFATT", CHAN_WEAPON); }
		"FFAT" G 0 { A_SpawnProjectile("RS_ZapFFAT", 18, -21, random(-1, 5)); }
		"FFAT" G 8 Bright { A_SpawnProjectile("RS_ZapFFAT", 18, 21, random(-5, 1)); }
		"FFAT" G 1 { A_StartSound("ELECFATT", CHAN_WEAPON); }
		"FFAT" G 0 { A_SpawnProjectile("RS_ZapFFAT", 18, -21, random(-1, 5)); }
		"FFAT" G 8 Bright { A_SpawnProjectile("RS_ZapFFAT", 18, 21, random(-5, 1)); }
		"FFAT" G 1 { A_StartSound("ELECFATT", CHAN_WEAPON); }
		"FFAT" G 0 { A_SpawnProjectile("RS_ZapFFAT", 18, -21, random(-1, 5)); }
	Missile.T08.Tail:
		"FFAT" G 8 Bright { A_SpawnProjectile("RS_ZapFFAT", 18, 21, random(-5, 1)); }
		"FFAT" G 1 { A_StartSound("ELECFATT", CHAN_WEAPON); }
		"FFAT" G 0 { A_SpawnProjectile("RS_ZapFFAT", 18, -21, random(-1, 5)); }
		"FFAT" G 8 Bright { A_SpawnProjectile("RS_ZapFFAT", 18, 21, random(-5, 1)); }
		"FFAT" G 5 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("BASSFFAT", CHAN_WEAPON); }
		"FFAT" H 0 { A_SpawnProjectile("RS_FatsoSoundWave", 18, -21, random(-1, 6)); }
		"FFAT" H 0 { A_SpawnProjectile("RS_FatsoSoundWave", 18, -21, random(-3, 3)); }
		"FFAT" H 0 { A_SpawnProjectile("RS_FatsoSoundWave", 18, -21, random(-13, -6)); }
		"FFAT" H 0 { A_SpawnProjectile("RS_FatsoSoundWave", 18, -21, random(6, 13)); }
		"FFAT" H 10 Bright { A_SpawnProjectile("RS_FatsoSoundWave", 18, 21, random(-6, 1)); }
		"FFAT" I 15;
		Goto See;
	Missile.T08.Close:
		"FFAT" G 3 Bright { A_FaceTarget(); }
		"FFAT" G 1 { A_StartSound("ELECFATT", CHAN_WEAPON); }
		"FFAT" G 0 { A_SpawnProjectile("RS_ZapFFAT", 18, -21, random(-1, 5)); }
		"FFAT" G 8 Bright { A_SpawnProjectile("RS_ZapFFAT", 18, 21, random(-5, 1)); }
		"FFAT" GGGGGGGGG 0 { A_SpawnItemEx("RS_ZapFFAT", random(12, 252), random(-12, 12), random(24, 42), 3, 0, random(-1, 1)); }
		"FFAT" H 10 Bright { A_VileTarget("RS_ZapFFAT2"); }
		"FFAT" H 3 Bright { A_FaceTarget(); }
		"FFAT" H 1 { A_StartSound("ELECFATT", CHAN_WEAPON); }
		"FFAT" G 0 { A_SpawnProjectile("RS_ZapFFAT", 18, -21, random(-1, 5)); }
		"FFAT" G 0 { A_SpawnProjectile("RS_ZapFFAT", 18, 21, random(-5, 1)); }
		"FFAT" GGGGGGGGG 0 { A_SpawnItemEx("RS_ZapFFAT", random(12, 252), random(-12, 12), random(24, 42), 3, 0, random(-1, 1)); }
		"FFAT" H 10 Bright { A_VileTarget("RS_ZapFFAT2"); }
		"FFAT" H 1 Bright A_CheckSight("See");
		TNT1 A 0 A_JumpIfCloser(300, "Missile.T08.Close2");
		Goto Missile.T08.Tail;
	Missile.T08.Close2:
		"FFAT" I 1 Bright { A_FaceTarget(); }
		"FFAT" I 10 Bright { A_VileAttack("weapons/bfgx", random(32, 99), random(2, 60), 32, 5, "Plasma"); }
		"FFAT" G 10;
		Goto Missile.T08.Tail;
	Pain.T08:
		"FFAT" J 3;
		"FFAT" J 3 { A_Pain(); }
		Goto See;
	Death.T08:
		"FFAT" K 6;
		"FFAT" L 6 { A_Scream(); }
		"FFAT" M 6 { A_NoBlocking(); }
		"FFAT" NOPQRS 6;
		"FFAT" T 1 { A_BossDeath(); }
		"FFAT" T -1;
		Stop;
	Raise.T08:
		"FFAT" R 5;
		"FFAT" QPONMLK 5;
		Goto See;

	// ================= T09 GRAY (13_GY) =================
	// Three spike volleys at range; inside 1200 it dumps eight bursts
	// of scrap out of both barrels instead.
	Spawn.T09:
		"FTGR" AB 15 { A_Look(); }
		Loop;
	See.T09:
		"FTGR" AABBCCDDEEFF 5 { A_Chase(); }
		Loop;
	Missile.T09:
		"FTGR" G 20 { A_StartSound("mancubus2/attack", CHAN_WEAPON); }
		TNT1 A 0 A_Jump(140, "Missile.T09.Pick");
	Missile.T09.Spikes:
		"FTGR" H 0 { A_SpawnProjectile("RS_FatsoSpikes", 18, -21, random(-1, 11)); }
		"FTGR" H 10 Bright { A_SpawnProjectile("RS_FatsoSpikes", 18, 21, random(-11, 1)); }
		"FTGR" IG 15 { A_FaceTarget(); }
		TNT1 A 0 A_CheckSight("See");
		"FTGR" H 0 { A_SpawnProjectile("RS_FatsoSpikes", 18, -21, random(-1, 11)); }
		"FTGR" H 10 Bright { A_SpawnProjectile("RS_FatsoSpikes", 18, 21, random(-11, 1)); }
		"FTGR" IG 15 { A_FaceTarget(); }
		TNT1 A 0 A_CheckSight("See");
		"FTGR" H 0 { A_SpawnProjectile("RS_FatsoSpikes", 18, -21, random(-1, 11)); }
		"FTGR" H 10 Bright { A_SpawnProjectile("RS_FatsoSpikes", 18, 21, random(-11, 1)); }
		"FTGR" I 15;
		Goto See;
	Missile.T09.Pick:
		TNT1 A 0 A_JumpIfCloser(1200, "Missile.T09.Scrap");
		Goto Missile.T09.Spikes;
	Missile.T09.Scrap:
		"FTGR" G 5 { A_FaceTarget(); }
		"FTGR" H 0 { A_StartSound("fire/fire3", 5); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, -21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" H 0 { A_FaceTarget(); A_StartSound("fire/fire3", 6); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" H 0 { A_FaceTarget(); A_StartSound("fire/fire3", 5); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, -21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" H 0 { A_FaceTarget(); A_StartSound("fire/fire3", 6); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" H 0 { A_FaceTarget(); A_StartSound("fire/fire3", 5); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, -21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" H 0 { A_FaceTarget(); A_StartSound("fire/fire3", 6); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" H 0 { A_FaceTarget(); A_StartSound("fire/fire3", 5); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, -21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" H 0 { A_FaceTarget(); A_StartSound("fire/fire3", 6); }
		"FTGR" HHHH 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"FTGR" IG 15 { A_FaceTarget(); }
		Goto See;
	Pain.T09:
		"FTGR" J 3;
		"FTGR" J 3 { A_Pain(); }
		Goto See;
	Death.T09:
	XDeath.T09:
		"FTGR" K 6;
		"FTGR" L 6 { A_Scream(); }
		"FTGR" M 6 { A_NoBlocking(); }
		"FTGR" NOPQRS 6;
		"FTGR" T 1 { A_BossDeath(); }
		"FTGR" T -1;
		Stop;
	Raise.T09:
		"FTGR" RQPONMLK 5;
		Goto See;

	// ================= T10 RED (13_R) =================
	// The Horned Beast. Smokes as it moves, two shot patterns, and a
	// RAGE METER: every fifth time it flinches it stops flinching
	// altogether, fires more often, and speeds up.
	Spawn.T10:
		"HBST" A 0 A_Jump(81, "Spawn.T10.Smoke");
		"HBST" A 10 { A_Look(); }
		Loop;
	Spawn.T10.Smoke:
		"HBST" A 0 { A_SpawnProjectile("RS_HBeastSmoke", 64, 0, 0); }
		Goto Spawn.T10;
	See.T10:
		"HBST" A 0 A_Jump(81, "See.T10.Smoke");
		"HBST" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.T10.Smoke:
		"HBST" A 0 { A_SpawnProjectile("RS_HBeastSmoke", 64, 0, 0); }
		Goto See.T10;
	Missile.T10:
		"HBST" E 0 A_JumpIfCloser(700, "Missile.T10.Fires");
		"HBST" E 10 { A_FaceTarget(); }
		"HBST" E 0 { A_SpawnProjectile("RS_Shot2Fatso", 32, 20, random(-1, 1)); }
		"HBST" E 0 { A_SpawnProjectile("RS_Shot2Fatso", 32, -20, random(-1, 1)); }
		"HBST" E 5 { A_FaceTarget(); }
		Goto See;
	Missile.T10.Fires:
		"HBST" EEEEE 0 { A_SpawnProjectile("RS_SparkPuff1", 42, random(-12, 12), random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HBST" E 12 { A_FaceTarget(); }
		"HBST" E 0 { A_SpawnProjectile("RS_HBeastShot", 32, 20, 0); }
		"HBST" E 0 { A_SpawnProjectile("RS_HBeastShot", 32, -20, 0); }
		"HBST" E 5 { A_FaceTarget(); }
		Goto See;
	// CHP tracks this in User_Rage5; here it is the private rsRage.
	Missile.T10.Buffs:
		"HBST" F 1 Bright { A_StartSound("Horn/Sight", CHAN_VOICE); }
		"HBST" F 12 Bright { bNOPAIN = true; }
		"HBST" F 12 Bright { bMISSILEEVENMORE = true; }
		"HBST" F 9 Bright { A_SetSpeed(16); }
		"HBST" F 5 { rsRage -= 50; }
		"HBST" A 1;
		Goto See;
	Pain.T10:
		"HBST" F 3
		{
			if (rsRage >= 5) return ResolveState("Missile.T10.Buffs");
			return ResolveState(null);
		}
		"HBST" F 3 { A_Pain(); }
		"HBST" F 2 { rsRage++; }
		Goto See;
	Death.T10:
		"HBST" G 8 { A_Scream(); }
		"HBST" H 7 { A_StartSound("horn/shotx", CHAN_VOICE); }
		"HBST" I 6 { A_Fall(); }
		"HBST" JK 5;
		"HBST" LMNO 4;
		"HBST" P 1;
		"HBST" P -1 { A_BossDeath(); }
		Stop;

	// ================= T11 BLACK -- SHADOW BEAST (13_K) =================
	// Seven patterns. Below 5500 HP it speeds up and swaps three of them
	// for the ground-splash and the big single bomb.
	Spawn.T11:
		"BDEM" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"BDEM" ABC 4 { A_Chase(); }
		"BDEM" DD 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" DEF 4 { A_Chase(); }
		"BDEM" AA 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		Loop;
	Missile.T11:
		TNT1 A 0 A_JumpIfHealthLower(5500, "Missile.T11.Phase2");
		TNT1 A 0 A_JumpIfCloser(300, "Missile.T11.Breath");
		TNT1 A 0 A_Jump(256, "Missile.T11.BigBombs", "Missile.T11.Weave1", "Missile.T11.Weave2", "Missile.T11.LongRange");
		Goto See;
	Missile.T11.Phase2:
		TNT1 A 0 { A_SetSpeed(21); }
		TNT1 A 0 A_JumpIfCloser(300, "Missile.T11.Breath");
		TNT1 A 0 A_Jump(256, "Missile.T11.Ground", "Missile.T11.BiggerBomb", "Missile.T11.Weave1", "Missile.T11.LongRange");
		Goto See;
	Missile.T11.LongRange:
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T11");
		"BDEM" H 12 { A_FaceTarget(); }
		"BDEM" HHH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 8 { A_SpawnProjectile("RS_BlackFatShotLongRange", 48, 0, 0); }
		"BDEM" I 0 A_CheckSight("See");
		"BDEM" I 2 A_Jump(212, "Missile.T11.LongRange");
		Goto See;
	Missile.T11.Ground:
		"BDEM" G 12 { A_StartSound("shadowbeast/sight", CHAN_VOICE); }
		"BDEM" HH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" HI 6 { A_FaceTarget(); }
		"BDEM" IIII 1 { A_SpawnProjectile("RS_ShadowSplash", 12, 0, random(-60, 60)); }
		"BDEM" A 6 A_Jump(88, "Missile.T11.Weave1");
		Goto See;
	Missile.T11.BiggerBomb:
		"BDEM" H 12 { A_FaceTarget(); }
		"BDEM" HHH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 8 { A_SpawnProjectile("RS_ShadowBombBig", 48, 0, 0); }
		"BDEM" I 0 A_CheckSight("See");
		"BDEM" I 2 A_Jump(174, "Missile.T11.BigBombs");
		Goto Missile.T11.BigBombs;
	Missile.T11.BigBombs:
		"BDEM" H 6 { A_FaceTarget(); }
		"BDEM" HHH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, -8); }
		"BDEM" I 6 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, 8); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, 0); }
		"BDEM" H 1 A_CheckSight("See");
		"BDEM" H 8 { A_FaceTarget(); }
		"BDEM" HH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, random(-14, -7)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, random(-14, -7)); }
		"BDEM" I 5 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, random(7, 14)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, random(7, 14)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, random(-26, 26)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, random(-26, 26)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball1", 48, 0, random(-26, 26)); }
		Goto See;
	Missile.T11.Weave1:
		"BDEM" H 4 { A_FaceTarget(); }
		"BDEM" HHH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 4 { A_SpawnProjectile("RS_ShadowBeast_Ball2", 48, 0, -16); }
		"BDEM" I 0 { A_FaceTarget(); }
		"BDEM" I 4 { A_SpawnProjectile("RS_ShadowBeast_Ball2", 48, 0, -8); }
		"BDEM" I 0 { A_FaceTarget(); }
		"BDEM" I 4 { A_SpawnProjectile("RS_ShadowBeast_Ball2", 48, 0, 0); }
		"BDEM" II 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 0 { A_FaceTarget(); }
		"BDEM" I 4 { A_SpawnProjectile("RS_ShadowBeast_Ball2", 48, 0, 8); }
		"BDEM" I 0 { A_FaceTarget(); }
		"BDEM" I 4 { A_SpawnProjectile("RS_ShadowBeast_Ball2", 48, 0, 16); }
		"BDEM" III 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 0 { A_FaceTarget(); }
		"BDEM" I 4 { A_SpawnProjectile("RS_ShadowBeast_Ball2", 48, 0, 32); }
		"BDEM" I 0 A_Jump(128, "Missile.T11.Weave2");
		Goto See;
	Missile.T11.Breath:
		"BDEM" H 6 { A_FaceTarget(); }
		"BDEM" HHH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" IIIIIIIIIIIII 2 { A_SpawnProjectile("RS_ShadowBeast_BallFire", 48, 0, random(-8, 8)); }
		"BDEM" I 0 A_Jump(128, "Missile.T11.Weave1");
		Goto See;
	Missile.T11.Weave2:
		"BDEM" H 16 { A_FaceTarget(); }
		"BDEM" HHH 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -64); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 64); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -56); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 56); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -48); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 48); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -40); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 40); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -32); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 32); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -24); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 24); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -16); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 16); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, -8); }
		"BDEM" I 0 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 8); }
		"BDEM" I 6 { A_SpawnProjectile("RS_ShadowBeast_Ball3", 48, 0, 0); }
		"BDEM" I 0 A_Jump(64, "Missile.T11.BigBombs");
		Goto See;
	Pain.T11:
		TNT1 A 0 A_Jump(16, "Missile.T11.Weave2");
		"BDEM" GG 0 { A_SpawnItemEx("RS_Splash11", random(-20, 20), random(-20, 20), random(5, 76)); }
		"BDEM" G 4 { A_Pain(); }
		Goto See;
	Death.T11:
		"BDEM" R 8;
		"BDEM" S 8 { A_Scream(); }
		"BDEM" TUVWX 6;
		"BDEM" Y 6 { A_NoBlocking(); }
		"BDEM" Z 1;
		"BDEM" Z -1 { A_BossDeath(); }
		Stop;

	// ================= T12 WHITE -- ANGRY MAMA (13_W) =================
	// Railgun at long range. Inside 2000 it rolls the ball barrage, the
	// ground nuke or the scatter shot; below 9000 HP the rapid railgun
	// joins the pool, and inside 400 it detonates the zap ring.
	Spawn.T12:
		"QUEE" A 0 NoDelay { A_SetSize(80, 64, true); }
		"QUEE" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"QUEE" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T12:
		TNT1 A 0 A_JumpIfCloser(2000, "Missile.T12.Choice1");
	Missile.T12.QueenRail:
		"QUEE" E 3 { A_FaceTarget(); }
		"QUEE" E 0 Bright { A_StartSound("WFATATTACK", CHAN_WEAPON, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"QUEE" EFG 9 Bright;
		"QUEE" F 9 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("WFATCRIT", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		TNT1 A 0 { A_StartSound("weapons/railgf", CHAN_7); }
		"QUEE" G 3 Bright { A_CustomRailgun(random(40, 90), 0, "white", "white", RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_WhiteFatRB", 0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB2", 0); }
		"QUEE" E 3 Bright;
		Goto See;
	Missile.T12.RapidRail:
		"QUEE" E 3 { A_FaceTarget(); }
		"QUEE" E 3 Bright { A_StartSound("WFATCRIT", CHAN_VOICE); }
		"QUEE" EFG 3 Bright;
		"QUEE" EF 7 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("WFATATTACK", CHAN_WEAPON); A_StartSound("weapons/railgf", CHAN_7); }
		"QUEE" G 5 Bright { A_CustomRailgun(random(20, 40), 0, "white", "white", RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_WhiteFatRB3", 0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB4", 4); }
		"QUEE" E 3 Bright;
		"QUEE" FF 7 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("WFATATTACK", CHAN_WEAPON); A_StartSound("weapons/railgf", CHAN_7); }
		"QUEE" G 5 Bright { A_CustomRailgun(random(20, 40), 0, "white", "white", RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_WhiteFatRB3", 0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB4", 4); }
		"QUEE" E 3 Bright;
		"QUEE" EF 7 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("WFATCRIT", CHAN_VOICE); A_StartSound("weapons/railgf", CHAN_7); }
		"QUEE" G 5 Bright { A_CustomRailgun(random(20, 40), 0, "white", "white", RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_WhiteFatRB3", 0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB4", 4); }
		"QUEE" E 6 Bright;
		"QUEE" S 5;
		Goto See;
	Missile.T12.Choice2:
		TNT1 A 0 A_Jump(256, "Missile.T12.BallBarrage", "Missile.T12.GroundNuke", "Missile.T12.RapidRail", "Missile.T12.SpreadShot");
		Goto See;
	Missile.T12.Choice1:
		TNT1 A 0 A_JumpIfCloser(400, "Missile.T12.Zap");
		TNT1 A 0 A_JumpIfHealthLower(9000, "Missile.T12.Choice2");
		TNT1 A 0 A_Jump(256, "Missile.T12.BallBarrage", "Missile.T12.GroundNuke", "Missile.T12.SpreadShot");
	Missile.T12.Choice1.Rest:
		"QUEE" S 8 { A_FaceTarget(); }
		Goto See;
	Missile.T12.SpreadShot:
		"QUEE" S 5 { A_FaceTarget(); }
		"QUEE" S 5 Bright;
		"QUEE" E 5 { A_FaceTarget(); }
		"QUEE" F 5 { A_StartSound("WFATATTACK", CHAN_WEAPON); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatScatter", 38, 0, random(-36, 36), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-5, 5)); }
		"QUEE" G 6 Bright;
		"QUEE" S 5;
		Goto See;
	Missile.T12.GroundNuke:
		"QUEE" E 3 { A_FaceTarget(); }
		"QUEE" E 3 Bright { A_StartSound("WFATCRIT", CHAN_VOICE); }
		"QUEE" EFG 2 Bright;
		"QUEE" S 5 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("WFATATTACK", CHAN_WEAPON); }
		"QUEE" SSSSSSSSSSSSSSS 1 Bright { A_SpawnItemEx("RS_WhiteFatNukeShow", random(-24, 24), random(-24, 24), 64, 0, 0, 12, 0, SXF_NOCHECKPOSITION); }
		"QUEE" SSSSSSSSSSSSSSS 1 Bright { A_SpawnItemEx("RS_WhiteFatMark", random(-1524, 1524), random(-1524, 1524), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"QUEE" S 5;
		Goto See;
	Missile.T12.BallBarrage:
		"QUEE" S 3 { A_FaceTarget(); }
		"QUEE" S 3 Bright;
		"QUEE" E 5 { A_FaceTarget(); }
		"QUEE" F 0 { A_StartSound("WFATATTACK", CHAN_WEAPON); }
		"QUEE" G 1 A_Jump(256, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.A1:
		"QUEE" G 1 { A_FaceTarget(); }
		"QUEE" G 1 Bright { A_SpawnProjectile("RS_WhiteFatBall1", 40, 0, random(-5, 5)); }
		"QUEE" G 1 A_CheckSight("See");
		"QUEE" G 0 A_Jump(240, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.A2:
		"QUEE" F 1 { A_FaceTarget(); }
		"QUEE" F 1 Bright { A_SpawnProjectile("RS_WhiteFatBall2", 40, 0, random(-10, 10)); }
		"QUEE" F 1 A_CheckSight("See");
		"QUEE" G 0 A_Jump(240, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.A3:
		"QUEE" G 1 { A_FaceTarget(); }
		"QUEE" G 1 Bright { A_SpawnProjectile("RS_WhiteFatBall3", 40, 0, random(-10, 10)); }
		"QUEE" G 1 A_CheckSight("See");
		"QUEE" G 0 A_Jump(240, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.A4:
		"QUEE" F 1 { A_FaceTarget(); }
		"QUEE" F 1 Bright { A_SpawnProjectile("RS_WhiteFatBall4", 40, 0, random(-10, 10)); }
		"QUEE" F 1 A_CheckSight("See");
		"QUEE" G 0 A_Jump(240, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.A5:
		"QUEE" G 1 { A_FaceTarget(); }
		"QUEE" G 1 Bright { A_SpawnProjectile("RS_WhiteFatBall5", 40, 0, random(-10, 10)); }
		"QUEE" G 1 A_CheckSight("See");
		"QUEE" G 0 A_Jump(240, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.A6:
		"QUEE" F 1 { A_FaceTarget(); }
		"QUEE" F 1 Bright { A_SpawnProjectile("RS_WhiteFatBall6", 40, 0, random(-10, 10)); }
		"QUEE" F 1 A_CheckSight("See");
		"QUEE" G 0 A_Jump(240, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.A7:
		"QUEE" G 1 { A_FaceTarget(); }
		"QUEE" G 1 Bright { A_SpawnProjectile("RS_WhiteFatBall7", 40, 0, random(-10, 10)); }
		"QUEE" G 1 A_CheckSight("See");
		"QUEE" G 0 A_Jump(240, "Missile.T12.A1", "Missile.T12.A2", "Missile.T12.A3", "Missile.T12.A4", "Missile.T12.A5", "Missile.T12.A6", "Missile.T12.A7");
		"QUEE" S 5;
		Goto See;
	Missile.T12.Zap:
		TNT1 A 0 A_Jump(128, "Missile.T12.Zap7");
		Goto Missile.T12.Choice1.Rest;
	Missile.T12.Zap7:
		"QUEE" E 3 { A_FaceTarget(); }
		"QUEE" E 0 Bright { A_StartSound("WFATATTACK", CHAN_VOICE); }
		"QUEE" EFG 3 Bright;
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 15); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 45); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 75); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 105); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 135); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 165); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 195); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 225); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 255); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 285); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 315); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, 345); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, random(10, 170)); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, random(190, 260)); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, random(280, 340)); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoGroundZap", 0, 0, random(-50, 50)); }
		"QUEE" EFG 3 Bright;
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 0, 0, 15); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 45); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 75); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 105); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 135); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 165); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 195); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 225); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 255); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 285); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 315); }
		"QUEE" G 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 48, 0, 345); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 32, 0, random(10, 170)); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 32, 0, random(190, 260)); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 32, 0, random(280, 340)); }
		"QUEE" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_WhiteFatsoAirZap", 32, 0, random(-50, 50)); }
		"QUEE" S 5;
		Goto See;
	Pain.T12:
		"QUEE" S 3;
		"QUEE" S 3 { A_Pain(); }
		"QUEE" S 0 A_Jump(64, "Missile");
		Goto See;
	Death.T12:
		"QUEE" H 6;
		"QUEE" I 6 { A_Scream(); }
		"QUEE" J 6 { A_Fall(); }
		"QUEE" KLMNOP 6;
		"QUEE" Q -1;
		Stop;
	}
}
