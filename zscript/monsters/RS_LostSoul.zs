// =====================================================================
// RS_LostSoul -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\05\05_<code>.txt
// One CHP file per colour; the first ACTOR in each is the creature, and
// each is a genuinely different creature with its OWN sprite set, stats
// and attack. CH decorate/lostsouls.txt only fills what CHP leaves
// undefined (CHP's actors inherit from those CH parents).
//
//   tier  CHP    parent          body   HP    what it actually is
//   T00   05_C   CommonLSoul     SKUL     50  vanilla ram
//   T01   05_G   GreenLSoul      SKUG     60  ram + poison splasher, melee
//   T02   05_B   BlueLSoul       SKUB     73  rush OR psychic hitscan volley
//   T03   05_CY  CyanLSoul2      SKUC     40  eyed ice comet, shatters
//   T04   05_P   PurpleLSoul     PHNT     90  THRUACTORS phantom charge,
//                                             psychic rings in melee
//   T05   05_Y   YellowLSoul     FRGO    120  forgotten one: LOS-tracked
//                                             charge, splits on death
//   T06   05_A   AbyssLSoul2     BST7    240  BEETLEJUICE: burrows, stalks,
//                                             pops, spits, warp-grapples
//   T07   05_F   FireBluLSoul2   SKUF     88  charred skull, suicide bomb
//   T08   05_BR  BrownLSoul2     BOSF     65  THE CUBE: double glide-ram,
//                                             dies to mass-heal the horde
//   T09   05_GY  GrayLSoul2      SKGR     50  A HIVE: ceiling-hung, sows
//                                             bees, expires on its own
//   T10   05_R   RedLSoul        SKUR    166  bloody: spit volley OR charge
//   T11   05_K   BlackLSoul3     WASP   1500  QUEEN BEE: stinger runs,
//                                             evasion, calls the swarm
//   T12   05_W   WhiteLSoul2     ETHS   6000  THE SHIFTER -- ghost-forms
//                                             into revenant / baron /
//                                             arch-vile and fires that
//                                             monster's full combo.
//   TEX   05_WX  CommonWhiteL-   ETHS  10500  THE VENGEFUL SOUL -- the
//                Soul EX2                     shifter with a spendable
//                                             escort of two orbiting
//                                             skulls, SIX forms instead of
//                                             three (hell knight, caco and
//                                             mancubus unlock below 8000
//                                             HP), plus a beam and a
//                                             charged soul bolt of its own.
//
// Tier stats are CHP's own Health/Speed/PainChance per file, applied
// through TierData below as multipliers off this class's defaults.
//
// TEX SOURCE: CHP 05_WX.txt, ACTOR CommonWhiteLSoulEX2 (the first actor
// in the file), parent CH lostsouls.txt WhiteLSoulEX for the properties
// CHP does not restate. Its escort skulls, order tokens, shade and
// soul-shot live in RS_lostsoul_projectiles.zs; the hell knight form's
// RS_BlueHKShot came from CHP 11_B and lives in RS_hk_projectiles.zs.
//
// TEX CHP properties with no TierData channel, recorded rather than
// silently dropped: Height 56 (Default is 56 already), FloatSpeed 4,
// Mass 400, RenderStyle Add / Alpha 0.95, +BOSS +NOCLIP +NOFEAR
// +DONTBLAST +NODAMAGETHRUST and the Heroic/ice/playervoid damage
// factors. The row carries Health / Speed / PainChance / damage only.
//
// NOT PORTED (and why):
//   * NewIcon*/ColorTierIcon* spawns, A_GivetoChildren("GoAway"),
//     RandomLetterSpawner, A_SpawnParticle walls, the CHWhitePlan
//     radiusgive -- CHP HUD/gore/bookkeeping cruft.
//   * ACS_NamedExecuteAlways("AnnounceBlackSoul"/"AnnounceWhiteSoul") --
//     ACS boss banners.
//   * T11's BlackLSoul2Check_C escorts were ACS-gated (CallACS
//     "CH_Lackeys"); the CH parent spawns the six bees unconditionally,
//     so that is what ships.
//   * T12's ACS_NamedExecuteWithResult("BaronMissile_C") is an ACS
//     lead-prediction wrapper around BaronBall_C -- ported as a plain
//     A_SpawnProjectile("RS_BaronBall", 32, 0, 0); same projectile, only
//     the aim-lead math is lost.
//
// SPRITE NOTES (verified against sprites/monsters/_src):
//   * SKUC ships only frames S-W; the whole cyan cluster lives there and
//     CHP's stray "SKUC A" spawn line is carried on TNT1 instead.
//   * SKGR ships only A, C, D, E -- exactly what CHP uses.
//   * SKUF has no K frame (CHP inherited that death line from a
//     SKUL-bodied parent). The 2-tic frame is carried on TNT1 so the
//     ThrustThingZ still fires.
//   * BOSS has no O frame (vanilla stops at N, CH adds P-R). CHP's
//     "BOSS IJKLMNO" death run ships as IJKLMN.
//   * BOSF (T08) and MISL/SKUL/SKEL/BOSS/VILE/BAL1 are IWAD sprites.
// =====================================================================

class RS_LostSoul : RS_MonsterMaster replaces LostSoul
{
	// T06 BEETLEJUICE burrow timer (CHP user_pop) and T09 HIVE lifespan
	// (CHP's DewzanToken counter). CHP user vars / inventory counters are
	// private int fields here.
	private int rsBeetlePop;
	private int rsHiveLife;

	Default
	{
		Health 100;
		Radius 16;
		Height 56;
		Mass 50;
		Speed 8;
		Damage 3;
		PainChance 256;
		Monster;
		+FLOAT +NOGRAVITY +DONTFALL +NOICEDEATH MissileChanceMult 0.5;
		+FLOORCLIP
		AttackSound "skull/melee";
		PainSound "skull/pain";
		DeathSound "skull/death";
		ActiveSound "skull/active";
		Obituary "$OB_SKULL";
		Tag "Lost Soul";
		RenderStyle "SoulTrans";
	}

	// CHP's real per-colour numbers, read out of 05_*.txt. Health and
	// Speed are absolute there, so they are expressed as multipliers off
	// Default Health 100 / Speed 8 to keep the base class's
	// recompute-from-defaults contract.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 256; r.dmgMul = 1.0;
		int hp = 50; int spd = 8;
		switch (t)
		{
			case 0:  hp = 50;   spd = 8;  r.painChance = 256; r.dmgMul = 1.0; break;
			case 1:  hp = 60;   spd = 8;  r.painChance = 200; r.dmgMul = 1.1; break;
			case 2:  hp = 73;   spd = 9;  r.painChance = 175; r.dmgMul = 1.2; break;
			case 3:  hp = 40;   spd = 8;  r.painChance = 192; r.dmgMul = 1.3; break;
			case 4:  hp = 90;   spd = 9;  r.painChance = 60;  r.dmgMul = 1.4; break;
			case 5:  hp = 120;  spd = 12; r.painChance = 120; r.dmgMul = 1.6; break;
			case 6:  hp = 240;  spd = 8;  r.painChance = 32;  r.dmgMul = 1.5; break;
			case 7:  hp = 88;   spd = 15; r.painChance = 256; r.dmgMul = 1.5; break;
			// T08 CUBE and T09 HIVE are +NOPAIN in CH -- painChance 0.
			case 8:  hp = 65;   spd = 15; r.painChance = 0;   r.dmgMul = 1.4; break;
			case 9:  hp = 50;   spd = 2;  r.painChance = 0;   r.dmgMul = 1.0; break;
			case 10: hp = 166;  spd = 11; r.painChance = 88;  r.dmgMul = 1.8; break;
			case 11: hp = 1500; spd = 9;  r.painChance = 128; r.dmgMul = 2.2; break;
			case 12: hp = 6000; spd = 19; r.painChance = 22;  r.dmgMul = 3.0; break;
			// TEX -- CHP 05_WX CommonWhiteLSoulEX2's own numbers.
			case 13: hp = 10500; spd = 19; r.painChance = 32; r.dmgMul = 4.0; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 100.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		// TEX wears ETHS too -- CHP's EX soul is the T12 shifter's own body,
		// not a new sprite set. The same token twice is correct.
		return "SKUL SKUG SKUB SKUC PHNT FRGO BST7 SKUF BOSF SKGR SKUR WASP ETHS ETHS";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:lostsoul role:skirmisher delivery:melee element:thermal mobility:flying";
	}

	States
	{
	// ================= T00 COMMON (05_C) =================
	Spawn.T00:
		"SKUL" AB 10 Bright { A_Look(); }
		Loop;
	See.T00:
		"SKUL" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T00:
		"SKUL" C 10 Bright { A_FaceTarget(); }
		"SKUL" D 4 Bright { A_SkullAttack(20); }
	Missile.T00.Fly:
		"SKUL" CD 4 Bright;
		Goto Missile.T00.Fly;
	Pain.T00:
		"SKUL" E 3 Bright;
		"SKUL" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T00:
		"SKUL" F 6 Bright;
		"SKUL" G 6 Bright { A_Scream(); }
		"SKUL" H 6 Bright;
		"SKUL" I 6 Bright { A_NoBlocking(); }
		"SKUL" J 6;
		"SKUL" K 6;
		Stop;

	// ================= T01 GREEN (05_G) =================
	// Rams, and coughs a poison splasher on melee and on death.
	Spawn.T01:
		"SKUG" AB 10 Bright { A_Look(); }
		Loop;
	See.T01:
		"SKUG" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T01:
		"SKUG" C 10 Bright { A_FaceTarget(); }
		"SKUG" D 4 Bright { A_SkullAttack(20); }
	Missile.T01.Fly:
		"SKUG" CD 4 Bright;
		Goto Missile.T01.Fly;
	Melee.T01:
		"SKUG" CD 9 Bright { A_CustomMeleeAttack(random(3, 8), "Skull/melee"); }
		"SKUG" C 0 Bright { A_SpawnProjectile("RS_SplasherSoul", 30, 0); }
		Goto See;
	Pain.T01:
		"SKUG" E 3 Bright;
		"SKUG" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T01:
		"SKUG" F 6 Bright;
		"SKUG" G 6 Bright { A_Scream(); }
		"SKUG" H 6 Bright { A_SpawnProjectile("RS_SplasherSoul", 30, 0); }
		"SKUG" I 6 Bright { A_NoBlocking(); }
		"SKUG" J 6;
		"SKUG" K 6;
		Stop;

	// ================= T02 BLUE (05_B) =================
	// Inside 650 it always rushes; outside it coin-flips the rush against
	// a "psychic" hitscan volley.
	Spawn.T02:
		"SKUB" AB 10 Bright { A_Look(); }
		Loop;
	See.T02:
		"SKUB" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T02:
		"SKUB" C 3 Bright A_JumpIfCloser(650, "Missile.T02.Rush");
		"SKUB" C 0 Bright A_Jump(255, "Missile.T02.Decision");
		Goto See;
	Missile.T02.Decision:
		"SKUB" C 0 Bright A_Jump(255, "Missile.T02.Rush", "Missile.T02.Psychic");
		Goto See;
	Missile.T02.Rush:
		"SKUB" C 8 Bright { A_FaceTarget(); }
	Missile.T02.Rush2:
		"SKUB" D 4 Bright { A_SkullAttack(20); }
		"SKUB" CD 4 Bright;
		Goto Missile.T02.Rush2;
	Missile.T02.Psychic:
		"SKUB" C 7 Bright { A_FaceTarget(); }
		"SKUB" C 0 Bright { A_StartSound("fire/fire4", CHAN_WEAPON); }
		"SKUB" D 4 Bright { A_CustomBulletAttack(6, 6, random(1, 15), random(1, 2), "RS_PsychPuff"); }
		"SKUB" CD 4 Bright;
		Goto Missile.T02;
	Melee.T02:
		"SKUB" CD 9 Bright { A_CustomMeleeAttack(random(4, 9), "skull2/melee"); }
		Goto See;
	Pain.T02:
		"SKUB" E 3 Bright;
		"SKUB" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T02:
		"SKUB" F 6 Bright;
		"SKUB" G 6 Bright { A_Scream(); }
		"SKUB" H 6 Bright;
		"SKUB" I 6 Bright { A_NoBlocking(); }
		"SKUB" J 6;
		"SKUB" K 6;
		Stop;

	// ================= T03 CYAN (05_CY) =================
	// Two eye satellites ride it; the attack is a double skull-lunge with
	// a self-thrust and an ice trail, and it shatters when killed.
	Spawn.T03:
		TNT1 A 0 { A_SpawnItemEx("RS_CyanSoulEye2", 0, 0, 24, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		TNT1 A 0 { A_SpawnItemEx("RS_CyanSoulEye", 0, 0, 24, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
	Spawn.T03.Idle:
		"SKUC" STUVW 1 Bright { A_Look(); }
		Loop;
	See.T03:
		"SKUC" STUVW 1 Bright { A_Chase(); }
		Loop;
	Missile.T03:
		"SKUC" ST 1 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("ice/splode", CHAN_AUTO); }
		"SKUC" UVWS 1 Bright { A_SkullAttack(18); }
		"SKUC" T 9 Bright { A_SkullAttack(40); }
		"SKUC" T 0 Bright { ThrustThing(angle, 30, 0, 0); }
		"SKUC" STUVW 1 Bright { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUC" STUVW 2 Bright { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUC" STUVW 3 Bright;
		"SKUC" STUVW 4 Bright;
		"SKUC" STUVW 5 Bright;
		TNT1 A 0 { A_Stop(); }
		Goto See;
	Pain.T03:
		"SKUC" STUVW 1 Bright { A_Pain(); }
		Goto See;
	Death.T03:
		"SKUC" STUVW 1 Bright;
		TNT1 A 2 { A_Scream(); }
		TNT1 A 1 { A_KillChildren("extreme", KILS_FOILINVUL|KILS_KILLMISSILES); }
		TNT1 A 2 { A_NoBlocking(); }
		TNT1 A 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		TNT1 A 0 { A_Burst("IceChunk"); }
		Stop;

	// ================= T04 PURPLE (05_P) =================
	// Phantom: turns THRUACTORS on to charge through the crowd and drops
	// the flag when it closes or takes a hit. Melee is a psychic ring fan.
	Spawn.T04:
		"PHNT" AB 10 Bright { A_Look(); }
		Loop;
	See.T04:
		TNT1 A 0 { bTHRUACTORS = false; }
		"PHNT" AB 6 Bright { A_Chase(); }
		Loop;
	Melee.T04:
		"PHNT" C 4 Bright { A_FaceTarget(); }
		"PHNT" C 0 Bright { A_StartSound("PUZSLV", CHAN_WEAPON); }
		"PHNT" DCDCDC 4 Bright { A_SpawnProjectile("RS_PsychicRingLS", 24, 0, random(-1, 1)); }
		Goto See;
	Missile.T04:
		"PHNT" C 0 Bright { bTHRUACTORS = true; }
		"PHNT" C 8 Bright { A_FaceTarget(); }
	Missile.T04.Fly:
		"PHNT" D 4 Bright { A_SkullAttack(35); }
		"PHNT" C 4 Bright A_JumpIfCloser(100, "Missile.T04.Reset");
		"PHNT" C 0 Bright A_Jump(64, "Missile.T04.Stopit");
		Goto Missile.T04.Fly;
	Missile.T04.Stopit:
		"PHNT" DC 4 Bright;
		Loop;
	Missile.T04.Reset:
		"PHNT" C 0 Bright { bTHRUACTORS = false; }
		Goto Missile.T04.Fly;
	Pain.T04:
		"PHNT" E 3 Bright;
		"PHNT" E 3 Bright { A_Pain(); }
		Goto Pain.T04.Reset2;
	Pain.T04.Reset2:
		"PHNT" C 0 Bright { bTHRUACTORS = false; }
		Goto See;
	Death.T04:
		"PHNT" F 6 Bright;
		"PHNT" G 6 Bright { A_Scream(); }
		"PHNT" H 6 Bright;
		"PHNT" I 6 Bright { A_NoBlocking(); }
		"PHNT" JK 6;
		Stop;

	// ================= T05 YELLOW -- FORGOTTEN ONE (05_Y) =================
	// Bobs while idle, kills the bob to charge, re-charges for as long as
	// the target stays in a 75-degree cone, and splits into common souls
	// when it dies.
	Spawn.T05:
		"FRGO" A 0 Bright { bFLOATBOB = true; }
		"FRGO" AAAAAABBBBBB 1 Bright { A_Look(); }
		Loop;
	See.T05:
		"FRGO" A 0 { bFLOATBOB = true; }
		"FRGO" AABB 3 Bright { A_Chase(); }
		Loop;
	Missile.T05:
		"FRGO" C 0 { bFLOATBOB = false; }
		"FRGO" CCDDC 2 Bright { A_FaceTarget(); }
		"FRGO" D 0 Bright { A_StartSound("Forgotten/Attack", CHAN_VOICE); }
	Missile.T05.Charge:
		"FRGO" D 2 Bright { A_SkullAttack(20); }
		"FRGO" C 2 Bright;
		"FRGO" C 0 Bright A_JumpIfTargetInLOS("Missile.T05.Charge", 75);
	Missile.T05.Drift:
		"FRGO" C 0 A_Jump(24, "Missile.T05.StopCharge");
		"FRGO" DC 2 Bright;
		Goto Missile.T05.Drift;
	Missile.T05.StopCharge:
		"FRGO" C 0 { A_Stop(); }
		Goto See;
	Pain.T05:
		"FRGO" E 0 { bFLOATBOB = true; }
		"FRGO" E 3 Bright;
		"FRGO" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T05:
		"FRGO" E 0 { bFLOATBOB = false; }
		"FRGO" E 0 { A_Stop(); }
		"FRGO" EF 4 Bright;
		"FRGO" G 6 Bright { A_Scream(); }
		"FRGO" H 6 Bright { A_Explode(random(5, 15), 64); }
		"FRGO" I 6 Bright { A_NoBlocking(); }
		"FRGO" J 6 Bright { A_PainDie("RS_LostSoul"); }
		Stop;

	// ================= T06 ABYSS -- BEETLEJUICE (05_A) =================
	// Walks the floor, randomly burrows out of sight, stalks tiny and
	// near-invisible, then POPS back to full size next to you. Ranged
	// spit, a rush, a bite, and a warp-grapple that heals it.
	Spawn.T06:
		"BST7" AB 10 Bright { A_Look(); }
		Loop;
	See.T06:
		"BST7" A 0 { A_SetTranslucent(1.0); bFLOAT = false; bNOGRAVITY = false; }
		"BST7" ABCDE 1 { A_Chase(); }
		"BST7" A 0 A_Jump(4, "See.T06.HideM");
	See.T06.B:
		"BST7" FGHIJ 1 { A_Chase(); }
		"BST7" A 0 A_Jump(6, "See.T06.HideM2");
	See.T06.C:
		"BST7" KLMNO 1 { A_Chase(); }
		"BST7" A 0 A_Jump(8, "See.T06.HideM3");
		Goto See.T06;
	See.T06.HideM:
		TNT1 A 0 A_CheckSight("See.T06.Hide");
		Goto See.T06.B;
	See.T06.HideM2:
		TNT1 A 0 A_CheckSight("See.T06.Hide");
		Goto See.T06.C;
	See.T06.HideM3:
		TNT1 A 0 A_CheckSight("See.T06.Hide");
		Goto See.T06;
	See.T06.Hide:
		TNT1 A 0 { if (ceilingZ <= 164) return ResolveState("See.T06.HideRoof"); return ResolveState(null); }
	See.T06.HideGround:
		"BST7" A 0 { A_StartSound("ZQuTag00", CHAN_AUTO); }
		"BST7" A 0 { A_SetSpeed(1); bSOLID = false; bSHOOTABLE = false; }
		"BST7" A 0 { A_SetScale(0.01, 0.01); A_SetTranslucent(0.05); }
		"BST7" A 0 { A_StartSound("ZQuTag01", CHAN_AUTO); }
	See.T06.Stalk2:
		"ABSP" G 1;
		"ABSP" G 1 { A_Wander(); }
		"ABSP" G 1;
		Goto See.T06.PopYet;
	See.T06.PopYet:
		"ABSP" G 1;
		"ABSP" G 1 A_JumpIfCloser(128, "See.T06.Now2");
		"ABSP" G 1 { rsBeetlePop++; }
		"ABSP" G 2 { if (rsBeetlePop >= 100) return ResolveState("See.T06.Now2"); return ResolveState(null); }
		Goto See.T06.Stalk2;
	See.T06.Now2:
		"BST7" A 0 { A_StartSound("ZQuTag01", CHAN_AUTO); }
		"BST7" A 0 { A_SetScale(1.0, 1.0); A_SetTranslucent(1.0); }
		"BST7" A 0 { rsBeetlePop = 0; A_SetSpeed(8); bSOLID = true; bSHOOTABLE = true; }
		"BST7" A 0 { A_StartSound("BETLEAT1", 4); }
		"BST8" EFG 8;
		Goto See;
	See.T06.HideRoof:
		"BST7" A 0 { A_StartSound("ZQuTag00", CHAN_AUTO); bFLOAT = true; bNOGRAVITY = true; }
		"BST7" A 0 { ThrustThingZ(0, 128, 0, 0); }
		"BST7" A 0 { A_SetSpeed(1); bSOLID = false; bSHOOTABLE = false; }
		"BST7" A 0 { A_SetScale(0.01, 0.01); A_SetTranslucent(0.05); }
		"BST7" A 0 { A_StartSound("ZQuTag01", CHAN_AUTO); }
	See.T06.Stalk:
		"ABSP" G 1;
		"ABSP" G 1 { A_Wander(); }
		"ABSP" G 1;
		Goto See.T06.DropYet;
	See.T06.DropYet:
		"ABSP" G 1;
		"ABSP" G 1 A_JumpIfCloser(128, "See.T06.Now");
		"ABSP" G 0 { ThrustThingZ(0, 128, 0, 0); }
		"ABSP" G 1 { rsBeetlePop++; }
		"ABSP" G 2 { if (rsBeetlePop >= 100) return ResolveState("See.T06.Now"); return ResolveState(null); }
		Goto See.T06.Stalk;
	See.T06.Now:
		"BST7" A 0 { A_StartSound("ZQuTag01", CHAN_AUTO); }
		"BST7" A 0 { A_SetScale(1.0, 1.0); A_SetTranslucent(1.0); }
		"BST7" A 0 { rsBeetlePop = 0; A_SetSpeed(8); bSOLID = true; bSHOOTABLE = true; }
		"BST7" A 0 { bFLOAT = false; bNOGRAVITY = false; }
		"BST7" A 0 { A_StartSound("BETLEAT1", 4); }
		"BST8" EFG 6;
		Goto See;
	Missile.T06:
		"BST8" A 10 Bright { A_FaceTarget(); }
		"BST8" A 1 A_JumpIfCloser(600, "Missile.T06.Rush");
		"BST8" B 2 Bright { A_FaceTarget(); }
	Missile.T06.Spit:
		"BST8" C 2 Bright { A_StartSound("BETLEAT2", 4); }
		"BST8" DE 2 Bright { A_FaceTarget(); }
		"BST8" AAAA 0 { A_SpawnProjectile("RS_BeetleSpitAbyss", 18, 0, random(-10, 10)); }
		"BST8" FG 3 Bright;
	Missile.T06.Rush:
		"BST8" B 8 Bright { A_SkullAttack(20); }
		"BST8" CD 7 Bright { A_FaceTarget(); }
		"BST8" A 0 A_JumpIfCloser(90, "Melee.T06");
		Goto Missile.T06.Spit;
	Melee.T06:
		"BST8" EF 1 Bright { A_CustomMeleeAttack(random(5, 15), "BETLEAT1"); }
		"BST8" G 1 { A_StartSound("BETLEAT1", 4); }
		"BST8" BCD 2 Bright A_JumpIfCloser(72, "Melee.T06.Wrap");
		Goto See;
	Melee.T06.Wrap:
		"BST8" A 1 { A_Warp(AAPTR_TARGET, random(-1, 3), 0, 12, random(-45, 45), WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		"BST8" A 0 { A_StartSound("BETLEAT1", 4); }
		"BST8" A 1 { A_Warp(AAPTR_TARGET, random(-1, 3), 0, 12, random(-45, 45), WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		"BST8" A 0 { A_SpawnProjectile("RS_Canyouleavemealonealready", 12, 0, 0); }
		"BST8" A 0 { HealThing(5, 300); }
		"BST8" A 0 A_JumpIfTargetInLOS("See", 1);
		"BST8" BEBEBBEBEBEBEBEBEBEBEBEE 1 { A_Warp(AAPTR_TARGET, random(-1, 3), 0, 12, random(-45, 45), WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		Loop;
	Pain.T06:
		"BST7" A 0 { A_SetScale(1.0, 1.0); A_SetSpeed(8); A_SetTranslucent(1.0); }
		"BST7" A 0 { rsBeetlePop = 0; bSOLID = true; bFLOAT = false; bNOGRAVITY = false; }
		"BST9" A 3 Bright;
		"BST9" A 3 Bright { A_Pain(); }
		Goto See;
	Death.T06:
		"BST7" A 0 { A_SetScale(1.0, 1.0); }
		"BST7" A 1 { A_SetTranslucent(1.0); }
		"BST9" A 6 Bright;
		"BST9" B 6 Bright { A_Scream(); }
		"BST9" C 6 Bright;
		"BST9" D 6 Bright { A_NoBlocking(); }
		"BST9" EFGH 6;
		"BST9" H -1;
		Stop;
	Raise.T06:
		"BST9" HGFEDCBA 3;
		Goto See;

	// ================= T07 FIREBLU (05_F) =================
	// Rams while shedding fire; in melee it goes invulnerable for a tic
	// and detonates itself.
	Spawn.T07:
		"SKUF" AB 10 Bright { A_Look(); }
		Loop;
	See.T07:
		"SKUF" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T07:
		"SKUF" C 10 Bright { A_FaceTarget(); }
		"SKUF" D 4 Bright { A_SkullAttack(20); }
		"SKUF" C 4 Bright { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 1, random(0, 360)); }
	Missile.T07.Fly:
		"SKUF" D 4 Bright { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 1, random(0, 360)); }
		Goto Missile.T07.Fly;
	Melee.T07:
		"SKUF" C 0 { bNOPAIN = true; bINVULNERABLE = true; }
		"SKUF" CD 1 Bright { A_CustomMeleeAttack(random(3, 8), "skull2/melee"); }
		MISL X 0 { A_StartSound("weapons/rocklx", 7); }
		MISL XYZ 3 Bright { A_Explode(random(10, 50), 128); }
		TNT1 A 0 { A_Die("MeleeDeath"); }
		Stop;
	Pain.T07:
		"SKUF" E 3 Bright;
		"SKUF" EEEE 0 { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 1, random(0, 360)); }
		"SKUF" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T07:
		"SKUF" F 3 Bright;
		"SKUF" G 3 Bright { A_Scream(); }
		"SKUF" H 3 Bright;
		"SKUF" I 3 Bright { A_NoBlocking(); }
		"SKUF" J 3;
		MISL X 0 { A_StartSound("weapons/rocklx", 7); }
		MISL XYZ 3 Bright { A_Explode(random(10, 50), 128); }
		// CHP wrote "SKUF K 2" -- that frame is absent from CHP's own art.
		TNT1 A 2 { ThrustThingZ(0, 2, 1, 0); }
		Stop;
	Death.MeleeDeath:
		TNT1 A 0;
		Stop;

	// ================= T08 BROWN -- THE CUBE (05_BR) =================
	// An A_VileChase raiser that glide-rams twice per pass; its melee ends
	// in a suicide that mass-heals every monster within 1200.
	Spawn.T08:
		"BOSF" ABCD 10 Bright { A_Look(); }
		Loop;
	See.T08:
		"BOSF" ABCD 6 Bright { A_VileChase(); }
		Loop;
	Missile.T08:
		"BOSF" ABCD 4 Bright { A_FaceTarget(); }
		"BOSF" ABCD 3 Bright { A_FaceTarget(); }
		"BOSF" ABCD 2 Bright { A_FaceTarget(); }
		"BOSF" ABCD 1 Bright { A_SkullAttack(); }
		"BOSF" ABCDABCDABCDABCD 1 Bright;
		"BOSF" ABCD 1 Bright { A_SkullAttack(); }
		"BOSF" ABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCDABCD 1 Bright;
		"BOSF" A 0 { A_Stop(); }
		Goto See;
	Melee.T08:
		"BOSF" ABCD 1 Bright { A_FaceTarget(); }
		"BOSF" ABCD 1 Bright { A_CustomMeleeAttack(random(1, 3), "imp/melee"); }
		"BOSF" A 0 A_CheckRange(128, "See", false);
		"BOSF" D 20 Bright { A_StartSound("vile/active", CHAN_AUTO); }
		Goto DeathHeal;
	Heal:
		"BOSF" ABCD 3 Bright;
		"BOSF" D 10 Bright;
		"BOSF" DCBA 3 Bright;
		"BOSF" DCBA 2 Bright;
		"BOSF" DCBA 1 Bright;
		Goto DeathHeal;
	DeathHeal:
		"BOSF" AAAA 0 { A_SpawnItemEx("RS_ArchRingHelp", random(-128, 128), random(-128, 128), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"BOSF" A 0 { A_RadiusGive("Health", 1200, RGF_MONSTERS, 200); }
		"BOSF" A 0 { A_Die(); }
		Goto Death;
	// CH's BrownLSoul2 is +NOPAIN and CHP ships no Pain block for the cube.
	Pain.T08:
		TNT1 A 0;
		Goto See;
	Death.T08:
		"BOSF" AB 1 Bright;
		"BOSF" C 1 Bright { A_Scream(); }
		"BOSF" D 1 Bright { A_NoBlocking(); }
		MISL BCD 3 Bright { A_Explode(random(10, 50), 128); }
		Stop;

	// ================= T09 GRAY -- A HIVE (05_GY) =================
	// Hangs near the ceiling at speed 2, pulses, and throws bees. It runs
	// out of lease after ~2000 chase ticks and kills itself; when the
	// corpse hits the floor it bursts one last brood.
	Spawn.T09:
		"SKGR" A 0 { A_Warp(AAPTR_DEFAULT, pos.x, pos.y, frandom(floorz, ceilingz - height), 0, WARPF_ABSOLUTEPOSITION|WARPF_NOCHECKPOSITION); }
	Spawn.T09.Idle:
		"SKGR" A 10 Bright { A_Look(); }
		Loop;
	See.T09:
		"SKGR" A 8 Bright { A_Chase(); }
		"SKGR" A 0 { rsHiveLife++; if (rsHiveLife >= 2000) return ResolveState("See.T09.Nah"); return ResolveState(null); }
		Loop;
	See.T09.Nah:
		"SKGR" A 0 { A_Die(); }
		Goto Death;
	Missile.T09:
		"SKGR" A 5 Bright { A_SetScale(1.1, 1.4); }
		"SKGR" A 5 Bright { A_SetScale(1.2, 1.3); }
		"SKGR" A 5 Bright { A_SetScale(1.3, 1.2); }
		"SKGR" A 5 Bright { A_SetScale(1.2, 1.3); }
		TNT1 A 0 { A_DualPainAttack("RS_BlackLSoul2"); }
		"SKGR" A 5 Bright { A_SetScale(1.1, 1.4); }
		"SKGR" A 5 Bright { A_SetScale(1.0, 1.5); }
		Goto See;
	Pain.T09:
		TNT1 A 0;
		Goto See;
	Death.T09:
		"SKGR" A 0 { bNOGRAVITY = false; bDONTFALL = false; bFLOAT = false; A_NoBlocking(); }
		"SKGR" A 5 { A_SetScale(1.5, 1.0); }
		"SKGR" A 30;
		Wait;
	Crash:
		"SKGR" C 8 { A_SetScale(1.5, 0.5); }
		TNT1 A 0 { A_PainDie("RS_BlackLSoul2"); }
		"SKGR" D 8 { A_Scream(); }
		"SKGR" E 8;
		Stop;

	// ================= T10 RED (05_R) =================
	// Trails blood constantly. Half the time a three-bolt spit, otherwise
	// the same LOS-tracked charge the forgotten one uses.
	Spawn.T10:
		"SKUR" A 0 Bright { bFLOATBOB = true; }
		"SKUR" AAAAAABBBBBB 1 Bright { A_Look(); }
		Loop;
	See.T10:
		"SKUR" A 0 { bFLOATBOB = true; }
		"SKUR" A 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUR" AABB 3 Bright { A_Chase(); }
		"SKUR" A 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Missile.T10:
		"SKUR" C 0 { bFLOATBOB = false; }
		"SKUR" C 0 A_Jump(126, "Missile.T10.Charge");
		"SKUR" C 0 A_Jump(256, "Missile.T10.Charge", "Missile.T10.Spit");
	Missile.T10.Spit:
		"SKUR" C 8 { A_FaceTarget(); }
		"SKUR" D 5 { A_SpawnProjectile("RS_SpitBoltLS", 12, 0, random(-8, 8)); }
		"SKUR" C 6 { A_FaceTarget(); }
		"SKUR" D 3 { A_SpawnProjectile("RS_SpitBoltLS", 12, 0, random(-8, 8)); }
		"SKUR" C 4 { A_FaceTarget(); }
		"SKUR" D 1 { A_SpawnProjectile("RS_SpitBoltLS", 12, 0, random(-8, 8)); }
		Goto See;
	Missile.T10.Charge:
		"SKUR" CCDDC 2 Bright { A_FaceTarget(); }
		"SKUR" D 0 { A_StartSound("Forgotten/Attack", CHAN_VOICE); }
	Missile.T10.Charge.Go:
		"SKUR" D 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUR" D 2 Bright { A_SkullAttack(23); }
	Missile.T10.Charge.Fly:
		"SKUR" D 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUR" C 2 Bright;
		"SKUR" C 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUR" C 0 Bright A_JumpIfTargetInLOS("Missile.T10.Charge.Go", 75);
		"SKUR" C 0 A_Jump(24, "Missile.T10.StopCharge");
		"SKUR" DC 2 Bright;
		Goto Missile.T10.Charge.Fly;
	Missile.T10.StopCharge:
		"SKUR" C 0 { A_Stop(); }
		Goto See;
	Pain.T10:
		"SKUR" E 0 { bFLOATBOB = true; }
		"SKUR" E 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUR" E 3 Bright;
		"SKUR" E 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SKUR" E 3 Bright { A_Pain(); }
		"SKUR" E 0 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Death.T10:
		"SKUR" E 0 { bFLOATBOB = false; }
		"SKUR" E 0 { A_Stop(); }
		"SKUR" EF 4 Bright { A_Explode(random(5, 15), 64); }
		"SKUR" G 6 Bright { A_Scream(); }
		"SKUR" H 6 Bright { A_Explode(random(5, 15), 64); }
		"SKUR" I 6 Bright { A_NoBlocking(); }
		"SKUR" J 6 Bright { A_SpawnItemEx("RS_HKRedDeath", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Stop;

	// ================= T11 BLACK -- QUEEN BEE (05_K) =================
	// Escorted from the moment she spawns. Three patterns: call more bees,
	// a strafing stinger run that speeds up below 800 HP, or a seeking
	// swarm bolt. She sidesteps anything that gets inside 256.
	Spawn.T11:
		"WASP" A 0 { A_SpawnItemEx("RS_BlackLSoul2", random(-16, 16), random(-16, 16), random(-6, 10), 0, 0, 0, 0, SXF_SETMASTER|SXF_NOCHECKPOSITION); }
		"WASP" A 0 { A_SpawnItemEx("RS_BlackLSoul2", random(-16, 16), random(-16, 16), random(-6, 10), 0, 0, 0, 0, SXF_SETMASTER|SXF_NOCHECKPOSITION); }
		"WASP" A 0 { A_SpawnItemEx("RS_BlackLSoul2", random(-16, 16), random(-16, 16), random(-6, 10), 0, 0, 0, 0, SXF_SETMASTER|SXF_NOCHECKPOSITION); }
		"WASP" A 0 { A_SpawnItemEx("RS_BlackLSoul2", random(-16, 16), random(-16, 16), random(-6, 10), 0, 0, 0, 0, SXF_SETMASTER|SXF_NOCHECKPOSITION); }
		"WASP" A 0 { A_SpawnItemEx("RS_BlackLSoul2", random(-16, 16), random(-16, 16), random(-6, 10), 0, 0, 0, 0, SXF_SETMASTER|SXF_NOCHECKPOSITION); }
		"WASP" A 0 { A_SpawnItemEx("RS_BlackLSoul2", random(-16, 16), random(-16, 16), random(-6, 10), 0, 0, 0, 0, SXF_SETMASTER|SXF_NOCHECKPOSITION); }
		"WASP" A 0 { A_SpawnItemEx("RS_BLSoulFX", 0, 0, -12, 0, 0, 0, 0, SXF_SETMASTER); }
	Spawn.T11.Idle:
		"WASP" A 0 { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		"WASP" AB 2 { A_Look(); }
		Loop;
	See.T11:
		"WASP" A 0 { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		"WASP" A 0 A_JumpIfCloser(256, "Missile.T11.Dodge");
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" AB 2 { A_Chase(); }
		Loop;
	Missile.T11.Dodge:
		"WASP" A 0 { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		"WASP" A 1 { A_FastChase(); }
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" A 1 { A_FaceTarget(); }
		"WASP" B 1 { A_FastChase(); }
		"WASP" B 1 { A_FaceTarget(); }
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		Goto See;
	Missile.T11:
		"WASP" A 0 { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" A 2 { A_FaceTarget(); }
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" A 2 A_Jump(255, "Missile.T11.Minions", "Missile.T11.Stinger", "Missile.T11.HurtSoul");
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" B 2;
		Goto See;
	Missile.T11.HurtSoul:
		"WASP" A 12 { A_FaceTarget(); }
		"WASP" B 8 Bright { A_SpawnProjectile("RS_BSoulHellNo", 0, 0, 0); }
		"WASP" A 0 A_Jump(128, "Missile.T11.Stinger");
		Goto See;
	Missile.T11.Stinger:
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 0 A_Jump(128, "Missile.T11.ThatWay");
		TNT1 A 0 A_JumpIfHealthLower(800, "Missile.T11.FasterBee");
		"WASP" A 5 { ThrustThing(angle * 256 / 360 + 64, 20, 0, 0); }
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 5 Bright { A_Stop(); }
		TNT1 A 0 A_Jump(32, "Missile.T11.ThatWay");
		"WASP" A 5 { ThrustThing(angle * 256 / 360 + 192, 20, 0, 0); }
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright { A_Stop(); }
		Goto See;
	Missile.T11.FasterBee:
		"WASP" A 3 { ThrustThing(angle * 256 / 360 + 64, 25, 0, 0); }
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 1 Bright { A_Stop(); }
		TNT1 A 0 A_Jump(32, "Missile.T11.FasterBee2");
		"WASP" A 3 { ThrustThing(angle * 256 / 360 + 192, 25, 0, 0); }
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright { A_Stop(); }
		Goto See;
	Missile.T11.FasterBee2:
		"WASP" A 3 { ThrustThing(angle * 256 / 360 + 192, 25, 0, 0); }
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 1 Bright { A_Stop(); }
		TNT1 A 0 A_Jump(32, "Missile.T11.FasterBee");
		"WASP" A 3 { ThrustThing(angle * 256 / 360 + 64, 25, 0, 0); }
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 2 Bright;
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright { A_Stop(); }
		Goto See;
	Missile.T11.ThatWay:
		TNT1 A 0 A_JumpIfHealthLower(800, "Missile.T11.FasterBee2");
		"WASP" A 5 { ThrustThing(angle * 256 / 360 + 192, 20, 0, 0); }
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 5 Bright { A_Stop(); }
		"WASP" A 5 { ThrustThing(angle * 256 / 360 + 64, 20, 0, 0); }
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, 0); }
		"WASP" A 5 Bright;
		"WASP" B 5 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, 0); }
		"WASP" A 5 Bright { A_Stop(); }
		Goto See;
	Missile.T11.Minions:
		"WASP" A 0 A_JumpIfCloser(256, "Missile.T11.Dodge");
		"WASP" AB 8 { A_Stop(); }
		"WASP" A 6 { A_SpawnProjectile("RS_RedRevLoad", 18, 0, 0); }
		"WASP" ABABABAB 4 Bright;
		"WASP" A 6 { A_SpawnProjectile("RS_RedRevLoad", 18, 0, 0); }
		"WASP" ABABABAB 4 Bright;
		"WASP" AB 3 { A_PainAttack("RS_BlackLSoul2"); }
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" BA 3 { A_DualPainAttack("RS_BlackLSoul2"); }
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" BA 3 { A_PainAttack("RS_BlackLSoul2"); }
		"WASP" A 0 { A_SpawnProjectile("RS_SparkPuff1", 4, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360)); }
		"WASP" AB 3 { A_DualPainAttack("RS_BlackLSoul2"); }
		Goto See;
	Pain.T11:
		"WASP" B 3;
		Goto Missile.T11.Dodge;
	Death.T11:
		"WASP" C 0 { bNOGRAVITY = false; bDONTFALL = false; bFLOAT = false; }
		"WASP" C 1 { A_StopSound(7); }
		"WASP" C 0 { A_ScreamAndUnblock(); }
	Death.T11.Fall:
		"WASP" C 1 A_CheckFloor("Death.T11.Splat");
		Loop;
	Death.T11.Splat:
		"WASP" D 1 { A_Stop(); }
		"WASP" D 0 { A_StartSound("Hornet/Splat", CHAN_BODY); }
		"WASP" D -1;
		Stop;

	// ================= T12 WHITE -- THE SHIFTER (05_W) =================
	// Holds NOPAIN, flashes into one of three ghost forms and fires that
	// monster's whole signature chain -- including its egg summon -- then
	// drops the form and goes back to chasing.
	Spawn.T12:
		"ETHS" ABCD 10 Bright { A_Look(); }
		Loop;
	See.T12:
		"ETHS" A 0 { bNOPAIN = false; }
		"ETHS" AABBCCDD 3 Bright { A_Chase(); }
		Loop;
	Missile.T12:
		"ETHS" C 0 { bNOPAIN = true; }
		"ETHS" C 2 Bright { A_StartSound("WSOUL/form", 3); }
		"ETHS" E 2 Bright;
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" P 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" P 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" P 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" Q 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" Q 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" R 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" R 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" R 0 A_Jump(256, "Missile.T12.Rev", "Missile.T12.Arch", "Missile.T12.Baron");
		Goto See;
	Missile.T12.Rev:
		"SKEL" L 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 9 { A_StartSound("skeleton/sight", CHAN_VOICE); }
		"SKEL" J 6 { A_FaceTarget(); }
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracer", 50, 7, 5); }
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracer", 50, -7, -5); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_AcidBlast1", 50, 7, 12); }
		"SKEL" K 0 { A_SpawnProjectile("RS_AcidBlast1", 50, -7, -12); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Zap7", 50, 7, 1); }
		"SKEL" K 0 { A_SpawnProjectile("RS_Zap7", 50, -7, -1); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Purp1", 50, 7, 9); }
		"SKEL" K 0 { A_SpawnProjectile("RS_Purp1", 50, -7, -9); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Homer1", 50, 7, 15); }
		"SKEL" K 4 { A_SpawnProjectile("RS_Homer1", 50, -7, -15); }
		"SKEL" L 4 { A_PainAttack("RS_RevEgg", 0, PAF_NOSKULLATTACK); }
		"SKEL" L 0 { bFLOAT = true; bNOGRAVITY = true; bDONTFALL = true; }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;
	Missile.T12.Baron:
		"BOSS" H 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 8 { A_StartSound("baron/sight", CHAN_VOICE); }
		"BOSS" EF 6 { A_FaceTarget(); }
		"BOSS" G 7 { A_CustomComboAttack("RS_BaronBall", 32, 10 * random(1, 8), "baron/melee"); }
		"BOSS" PQ 5 { A_FaceTarget(); }
		"BOSS" R 5 { A_SpawnProjectile("RS_BaronBall", 32, 0, 0); }
		"BOSS" EF 5 { A_FaceTarget(); }
		"BOSS" G 5 { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-1, 1)); }
		"BOSS" PQ 5 { A_FaceTarget(); }
		"BOSS" R 3 { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-8, 8)); }
		"BOSS" EF 3 { A_FaceTarget(); }
		"BOSS" G 3 { A_SpawnProjectile("RS_SmashBalls2", 32, 5, random(-8, 8)); }
		"BOSS" PQ 6 { A_FaceTarget(); }
		"BOSS" R 6 { A_SpawnProjectile("RS_SmashBalls2", 32, 5, random(-1, 1)); }
		"BOSS" EF 5 { A_FaceTarget(); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 1); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 3); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -3); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 6); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -6); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 9); }
		"BOSS" G 5 { A_SpawnProjectile("RS_BaronWave", 32, 5, -9); }
		"BOSS" PQ 5 { A_FaceTarget(); }
		"BOSS" R 5 { A_SpawnProjectile("RS_Spear11", 32, 5, random(-1, 1)); }
		"BOSS" H 5;
		"BOSS" H 8 { A_PainAttack("RS_HKEgg", 0, PAF_NOSKULLATTACK); }
		"BOSS" H 0 { bFLOAT = true; bNOGRAVITY = true; bDONTFALL = true; }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;
	Missile.T12.Arch:
		"VILE" Q 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"VILE" Q 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"VILE" Q 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"VILE" Q 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"VILE" Q 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"VILE" Q 8 { A_StartSound("vile/sight", CHAN_VOICE); }
		"VILE" G 5 { A_FaceTarget(); }
		"VILE" H 4 { A_SpawnItemEx("RS_BlueGash", 0, 0, 32); }
		"VILE" IJKLM 4 Bright { A_FaceTarget(); }
		"VILE" N 1 Bright { A_SpawnProjectile("RS_BigBolt2", 32, 0); }
		"VILE" G 0 { A_VileStart(); }
		"VILE" G 7 Bright { A_FaceTarget(); }
		"VILE" H 6 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILE" IJKLM 5 Bright { A_FaceTarget(); }
		"VILE" N 4 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILE" O 0 A_CheckSight("See");
		"VILE" O 7 Bright { A_VileTarget("RS_ArcRing2"); }
		"VILE" O 4 Bright { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(-3, 3)); }
		"VILE" O 2 Bright { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(-3, 3)); }
		"VILE" P 12 Bright;
		"VILE" Q 3 Bright { A_SpawnItemEx("RS_ArchSpawnerOrb", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"VILE" Q 2 Bright { A_SpawnItemEx("RS_ArchSpawnerOrb", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"VILE" Q 1 Bright { A_SpawnItemEx("RS_ArchSpawnerOrb", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"VILE" Q 8 { bFLOAT = true; bNOGRAVITY = true; bDONTFALL = true; }
		Goto See;
	Pain.T12:
		"ETHS" G 3 Bright;
		"ETHS" G 3 Bright { A_Pain(); }
		Goto See;
	Death.T12:
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 0 { A_StartSound("Skeleton/death", CHAN_VOICE); }
		"SKEL" LMNOP 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" I 0 { A_StartSound("Baron/death", CHAN_VOICE); }
		// CHP wrote "BOSS IJKLMNO"; frame O exists in no BOSS set.
		"BOSS" IJKLMN 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"VILE" Q 0 { A_StartSound("Vile/death", CHAN_VOICE); }
		"VILE" QRSTUVWXYZ 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" HIJKLMN 6 Bright;
		"ETHS" O 12 Bright { A_ScreamAndUnblock(); }
		Stop;

	// ============ TEX WHITE EX -- THE VENGEFUL SOUL (05_WX) ============
	// The T12 shifter, escorted and unbounded. Three things separate it:
	//
	//   1. IT COMES WITH A GUARD. Two RS_SkullWSoulEX1/2 orbit it,
	//      invulnerable and inert -- and it can spend them. A_RadiusGive
	//      of an order token detaches a skull, sends it out, and hatches a
	//      full revenant / hell knight / cacodemon out of it. If both
	//      escorts are gone the See loop notices (A_CheckProximity against
	//      its own skulls) and grows a new pair.
	//   2. SIX FORMS, NOT THREE. T12 shifts into revenant, baron or
	//      arch-vile. This one adds hell knight, cacodemon and mancubus --
	//      and the last three unlock only below 8000 HP, so hurting it
	//      widens the fight rather than narrowing it.
	//   3. TWO DIRECT ATTACKS OF ITS OWN, outside the forms: a charged
	//      soul bolt and a beam, either of which can follow a transform.
	//
	// It holds NOPAIN through every transform, and on pain has a 25%
	// chance to Reset -- recall the escorts, wander, and re-form.
	Spawn.TEX:
		TNT1 A 0
		{
			A_SpawnItemEx("RS_SkullWSoulEX1", 32, 32, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER);
			A_SpawnItemEx("RS_SkullWSoulEX2", -32, -32, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER);
		}
	Spawn.TEX.Idle:
		"ETHS" ABCD 10 Bright { A_Look(); }
		Loop;
	See.TEX:
		"ETHS" A 0 { bNOPAIN = false; }
		"ETHS" AA 3 Bright { A_Chase(); }
		"ETHS" A 0 { A_SpawnItemEx("RS_LSoulEXShade", -2, 0, 1, 1, 0, 1, -180, SXF_NOCHECKPOSITION); }
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX1", 512, 0, CPXF_EXACT);
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX2", 512, 0, CPXF_EXACT);
		"ETHS" BB 3 Bright { A_Chase(); }
		"ETHS" A 0 { A_SpawnItemEx("RS_LSoulEXShade", -2, 0, 1, 1, 0, 1, -180, SXF_NOCHECKPOSITION); }
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX1", 512, 0, CPXF_EXACT);
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX2", 512, 0, CPXF_EXACT);
		"ETHS" CC 3 Bright { A_Chase(); }
		"ETHS" A 0 { A_SpawnItemEx("RS_LSoulEXShade", -2, 0, 1, 1, 0, 1, -180, SXF_NOCHECKPOSITION); }
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX1", 512, 0, CPXF_EXACT);
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX2", 512, 0, CPXF_EXACT);
		"ETHS" DD 3 Bright { A_Chase(); }
		"ETHS" A 0 { A_SpawnItemEx("RS_LSoulEXShade", -2, 0, 1, 1, 0, 1, -180, SXF_NOCHECKPOSITION); }
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX1", 512, 0, CPXF_EXACT);
		"ETHS" A 0 A_CheckProximity("See.TEX.AddOns", "RS_SkullWSoulEX2", 512, 0, CPXF_EXACT);
		Loop;
	// Regrow the guard. Only reachable when a skull is actually missing.
	See.TEX.AddOns:
		"ETHS" CEF 6 Bright;
		"ETHS" A 0 { A_SpawnItemEx("RS_SkullWSoulEX1", 32, 32, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"ETHS" A 0 { A_SpawnItemEx("RS_SkullWSoulEX2", -32, -32, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"ETHS" FEC 6 Bright;
		Goto See;
	Missile.TEX:
		"ETHS" C 0 Bright { bNOPAIN = true; }
		"ETHS" C 2 Bright { A_StartSound("WSOUL/form", CHAN_BODY); }
		"ETHS" E 2 Bright;
		"ETHS" FFFF 0 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		// One in two: spend an escort before doing anything else.
		"ETHS" F 0 Bright A_Jump(128, "Missile.TEX.Order1", "Missile.TEX.Order2", "Missile.TEX.Order3");
	Missile.TEX.Miss2:
		"ETHS" A 0 A_Jump(128, "Missile.TEX.Transformers");
		"ETHS" A 0 A_Jump(256, "Missile.TEX.SoulShot", "Missile.TEX.Beam");
		Goto See;
	// The three orders. Each detaches an escort and hatches one monster.
	// CHP broadcasts these with A_RadiusGive because the escorts are
	// separate actors -- see the token classes in RS_lostsoul_projectiles.
	Missile.TEX.Order1:
		"ETHS" GG 0 { A_RadiusGive("RS_WhiteSoulAdsOff2", 700, RGF_MONSTERS); }
		Goto Missile.TEX.Miss2;
	Missile.TEX.Order2:
		"ETHS" GG 0 { A_RadiusGive("RS_WhiteSoulAdsOff3", 700, RGF_MONSTERS); }
		Goto Missile.TEX.Miss2;
	Missile.TEX.Order3:
		"ETHS" GG 0 { A_RadiusGive("RS_WhiteSoulAdsOff4", 700, RGF_MONSTERS); }
		Goto Missile.TEX.Miss2;
	// The squeeze-and-burst that precedes a form. Below 8000 HP it rolls
	// on the full six instead of the opening three.
	Missile.TEX.Transformers:
		"ETHS" F 4 Bright { A_SetScale(0.85, 1.2); }
		"ETHS" F 4 Bright { A_SetScale(0.70, 1.4); }
		"ETHS" F 4 Bright { A_SetScale(0.55, 1.6); }
		"ETHS" AAAAAAAAAAAA 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_WSSmore", random(-8, 8), random(-8, 8), 1, random(4, 20), 0, random(1, 15), random(-359, 359), SXF_NOCHECKPOSITION); }
		"ETHS" A 0 { A_SetScale(1.0, 1.0); }
		"ETHS" A 0 A_JumpIfHealthLower(8000, "Missile.TEX.RollOut");
		"ETHS" A 0 A_Jump(255, "Missile.TEX.HK", "Missile.TEX.Rev", "Missile.TEX.Caco");
		Goto See;
	Missile.TEX.RollOut:
		"ETHS" A 0 A_Jump(255, "Missile.TEX.Baron", "Missile.TEX.Vile", "Missile.TEX.Fatso", "Missile.TEX.HK", "Missile.TEX.Rev", "Missile.TEX.Caco");
		Goto See;

	// ---- FORM: CACODEMON. Every caco ball CHP ever wrote, in order. ----
	Missile.TEX.Caco:
		"HEAD" LLLLLLLL 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HEAD" D 5 { A_StartSound("caco/sight", CHAN_VOICE); }
		"HEAD" BC 4 { A_FaceTarget(); }
		"HEAD" D 1 Bright { A_SpawnProjectile("RS_CacodemonBall", 32, 7, -4); }
		"HEAD" D 1 Bright { A_SpawnProjectile("RS_CacodemonBall", 32, 7, -2); }
		"HEAD" D 1 Bright { A_SpawnProjectile("RS_CacodemonBall", 32, 7, 0); }
		"HEAD" D 1 Bright { A_SpawnProjectile("RS_CacodemonBall", 32, 7, 2); }
		"HEAD" D 1 Bright { A_SpawnProjectile("RS_CacodemonBall", 32, 7, 4); }
		"HEAD" CBC 3 { A_FaceTarget(); }
		"HEAD" DDD 2 Bright { A_SpawnProjectile("RS_Cacospit1", 32, 0, random(-7, 7)); }
		"HEAD" CBC 3 { A_FaceTarget(); }
		"HEAD" D 4 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-1, 1)); }
		"HEAD" D 4 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-3, 3)); }
		"HEAD" D 4 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-5, 5)); }
		"HEAD" D 4 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-4, 4)); }
		"HEAD" CBC 3 { A_FaceTarget(); }
		"HEAD" D 0 Bright { A_SpawnProjectile("RS_CacoFire4", 32, 0, 8); }
		"HEAD" D 0 Bright { A_SpawnProjectile("RS_CacoFire4", 32, 0, -8); }
		"HEAD" D 0 Bright { A_SpawnProjectile("RS_CacoFire4", 32, 0, 21); }
		"HEAD" D 0 Bright { A_SpawnProjectile("RS_CacoFire4", 32, 0, -21); }
		"HEAD" D 6 Bright { A_SpawnProjectile("RS_CacoFire3", 32, 0, random(-1, 1)); }
		"HEAD" CBC 3 { A_FaceTarget(); }
		"HEAD" DDDD 2 { A_SpawnProjectile("RS_SpitFireCaco", 32, 0, random(-90, 90)); }
		"HEAD" CBC 3 { A_FaceTarget(); }
		"HEAD" D 0 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, 0, CMF_AIMOFFSET); }
		"HEAD" D 0 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, -8, CMF_AIMOFFSET); }
		"HEAD" D 5 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, 8, CMF_AIMOFFSET); }
		"HEAD" CBC 2 { A_FaceTarget(); }
		"HEAD" D 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, 16, CMF_AIMOFFSET); }
		"HEAD" D 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, 12, CMF_AIMOFFSET); }
		"HEAD" B 0 { A_FaceTarget(); }
		"HEAD" C 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, 8, CMF_AIMOFFSET); }
		"HEAD" C 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, 4, CMF_AIMOFFSET); }
		"HEAD" B 0 { A_FaceTarget(); }
		"HEAD" D 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, 0, CMF_AIMOFFSET); }
		"HEAD" D 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, -4, CMF_AIMOFFSET); }
		"HEAD" B 0 { A_FaceTarget(); }
		"HEAD" C 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, -8, CMF_AIMOFFSET); }
		"HEAD" C 2 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, -12, CMF_AIMOFFSET); }
		"HEAD" D 0 { A_FaceTarget(); }
		"HEAD" D 6 Bright { A_SpawnProjectile("RS_CrackodemonBall", 32, 0, -16, CMF_AIMOFFSET); }
		"HEAD" D 5 Bright { A_SpawnProjectile("RS_SBombCaco", 32, 0, 0, CMF_AIMOFFSET); }
		"HEAD" LLLLLLLL 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;

	// ---- FORM: REVENANT. Drops to the floor for the duration. ----
	Missile.TEX.Rev:
		"SKEL" L 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"SKEL" LLLLLLLL 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" L 9 { A_StartSound("skeleton/sight", CHAN_VOICE); }
		"SKEL" J 6 { A_FaceTarget(); }
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracer", 50, 7, 5); }
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracer", 50, -7, -5); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_AcidBlast1", 50, 7, 12); }
		"SKEL" K 0 { A_SpawnProjectile("RS_AcidBlast1", 50, -7, -12); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Zap7", 50, 7, 1); }
		"SKEL" K 0 { A_SpawnProjectile("RS_Zap7", 50, -7, -1); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Purp1", 50, 7, 9); }
		"SKEL" K 0 { A_SpawnProjectile("RS_Purp1", 50, -7, -9); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Homer1", 50, 7, 15); }
		"SKEL" K 0 { A_SpawnProjectile("RS_Homer1", 50, -7, -15); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_RedDeathRev", 50, 0, 0); }
		"SKEL" L 4;
		"SKEL" L 0 { bFLOAT = true; bNOGRAVITY = true; bDONTFALL = true; }
		"SKEL" LLLLLLLL 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;

	// ---- FORM: HELL KNIGHT. ----
	Missile.TEX.HK:
		"BOS2" H 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"BOS2" HHHHHHHH 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOS2" H 8 { A_StartSound("knight/sight", CHAN_VOICE); }
		"BOS2" EF 6 { A_FaceTarget(); }
		"BOS2" G 7 { A_CustomComboAttack("RS_BaronBall", 32, 10 * random(1, 8), "baron/melee"); }
		"BOS2" PQ 5 { A_FaceTarget(); }
		// CHP calls ACS_NamedExecuteWithResult("BaronMissile_C") here -- an
		// ACS lead-prediction wrapper around the same BaronBall. Ported as
		// the plain projectile, exactly as the T12 cluster does.
		"BOS2" R 5 { A_SpawnProjectile("RS_BaronBall", 32, 0, 0); }
		"BOS2" EF 5 { A_FaceTarget(); }
		"BOS2" GGGGG 1 { A_SpawnProjectile("RS_BlueHKShot", 32, 5, random(-1, 1)); }
		"BOS2" PQ 5 { A_FaceTarget(); }
		"BOS2" RRR 1 { A_SpawnProjectile("RS_BlueHKShot", 32, 5, random(-8, 8)); }
		"BOS2" EF 3 { A_FaceTarget(); }
		"BOS2" G 3 { A_SpawnProjectile("RS_HKBolt2", 32, 5, random(-8, 8)); }
		"BOS2" PQ 6 { A_FaceTarget(); }
		"BOS2" R 6 { A_SpawnProjectile("RS_HKBolt2", 32, 5, random(-1, 1)); }
		"BOS2" EF 5 { A_FaceTarget(); }
		"BOS2" G 5 { A_SpawnProjectile("RS_BigHK", 32, 5, 1); }
		"BOS2" PQ 5 { A_FaceTarget(); }
		"BOS2" R 5 { A_SpawnProjectile("RS_THEBEEHK", 32, 5, random(-1, 1)); }
		"BOS2" H 8;
		"BOS2" H 0 { bFLOAT = true; bNOGRAVITY = true; bDONTFALL = true; }
		"BOS2" HHHHHHHH 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;

	// ---- FORM: BARON. Only live below 8000 HP. ----
	Missile.TEX.Baron:
		"BOSS" H 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"BOSS" HHHHHHHH 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" H 8 { A_StartSound("baron/sight", CHAN_VOICE); }
		"BOSS" EF 6 { A_FaceTarget(); }
		"BOSS" G 7 { A_CustomComboAttack("RS_BaronBall", 32, 10 * random(1, 8), "baron/melee"); }
		"BOSS" PQ 5 { A_FaceTarget(); }
		"BOSS" R 5 { A_SpawnProjectile("RS_BaronBall", 32, 0, 0); }
		"BOSS" EF 5 { A_FaceTarget(); }
		"BOSS" G 5 { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-1, 1)); }
		"BOSS" PQ 5 { A_FaceTarget(); }
		"BOSS" R 3 { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-8, 8)); }
		"BOSS" EF 3 { A_FaceTarget(); }
		"BOSS" G 3 { A_SpawnProjectile("RS_SmashBalls2", 32, 5, random(-8, 8)); }
		"BOSS" PQ 6 { A_FaceTarget(); }
		"BOSS" R 6 { A_SpawnProjectile("RS_SmashBalls2", 32, 5, random(-1, 1)); }
		"BOSS" EF 5 { A_FaceTarget(); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 1); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 3); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -3); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 6); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -6); }
		"BOSS" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 9); }
		"BOSS" G 5 { A_SpawnProjectile("RS_BaronWave", 32, 5, -9); }
		"BOSS" PQ 5 { A_FaceTarget(); }
		"BOSS" R 5 { A_SpawnProjectile("RS_Spear11", 32, 5, random(-1, 1)); }
		"BOSS" EF 5 { A_FaceTarget(); }
		"BOSS" H 8 { A_SpawnProjectile("RS_BaronStar", 32, 5, 1); }
		"BOSS" H 0 { bFLOAT = true; bNOGRAVITY = true; bDONTFALL = true; }
		"BOSS" HHHHHHHH 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;

	// ---- FORM: ARCH-VILE. Only live below 8000 HP. ----
	Missile.TEX.Vile:
		"VILE" Q 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"VILE" QQQQQQQQ 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"VILE" Q 8 { A_StartSound("vile/sight", CHAN_VOICE); }
		"VILE" G 5 { A_FaceTarget(); }
		"VILE" H 4 { A_SpawnItemEx("RS_BlueGash", 0, 0, 32); }
		"VILE" IJKLM 4 Bright { A_FaceTarget(); }
		"VILE" N 1 Bright { A_SpawnProjectile("RS_BigBolt2", 32, 0); }
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" G 7 Bright { A_FaceTarget(); }
		"VILE" H 6 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILE" IJKLM 5 Bright { A_FaceTarget(); }
		"VILE" N 4 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILE" O 0 Bright { A_SpawnProjectile("RS_ReAComet", 32, 0); }
		"VILE" O 0 Bright A_CheckSight("See");
		"VILE" O 7 Bright { A_VileTarget("RS_ArcRing2"); }
		"VILE" O 4 Bright { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(-3, 3)); }
		"VILE" O 2 Bright { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(-3, 3)); }
		"VILE" P 12 Bright;
		"VILE" QQ 3 Bright { A_SpawnProjectile("RS_BVileOrb1", 32, 0, random(-19, 19)); }
		"VILE" QQQ 2 Bright { A_SpawnProjectile("RS_BVileOrb1", 32, 0, random(-19, 19)); }
		"VILE" QQQQQ 1 Bright { A_SpawnProjectile("RS_BVileOrb1", 32, 0, random(-19, 19)); }
		"VILE" Q 0 { bFLOAT = true; bNOGRAVITY = true; }
		"VILE" Q 8 { bDONTFALL = true; }
		"VILE" QQQQQQQQ 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;

	// ---- FORM: MANCUBUS. Only live below 8000 HP. The longest chain in
	// the whole family: seven complete Fatso weapon sets back to back. ----
	Missile.TEX.Fatso:
		"FATT" H 0 { bFLOAT = false; bNOGRAVITY = false; bDONTFALL = false; }
		"FATT" HHHHHHHH 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"FATT" G 12 { A_StartSound("fatso/sight", CHAN_VOICE); }
		"FATT" G 5 { A_StartSound("fatso/raiseguns", CHAN_WEAPON); }
		"FATT" H 0 { A_SpawnProjectile("RS_FatShot2", 32, 0, 11.25); }
		"FATT" H 4 Bright { A_SpawnProjectile("RS_FatShot2", 32, 0, 0); }
		"FATT" I 0 { A_FaceTarget(); }
		"FATT" I 0 { A_SpawnProjectile("RS_FatShot2", 32, 0, -11.25); }
		"FATT" I 4 Bright { A_SpawnProjectile("RS_FatShot2", 32, 0, 0); }
		"FATT" G 0 { A_FaceTarget(); }
		"FATT" G 0 { A_SpawnProjectile("RS_FatShot2", 32, 0, 5.625); }
		"FATT" G 4 Bright { A_SpawnProjectile("RS_FatShot2", 32, 0, -5.625); }
		"FATT" H 0 { A_FaceTarget(); }
		"FATT" H 5 Bright { A_SpawnProjectile("RS_GreenBomb1", 32, 13, random(-5, 5)); }
		"FATT" H 0 Bright { A_SpawnProjectile("RS_GreenBomb1", 32, -13, random(-5, 5)); }
		"FATT" I 0 { A_FaceTarget(); }
		"FATT" I 5 Bright { A_SpawnProjectile("RS_GreenBomb1", 32, 13, random(-5, 5)); }
		"FATT" I 0 Bright { A_SpawnProjectile("RS_GreenBomb1", 32, -13, random(-5, 5)); }
		"FATT" G 0 { A_FaceTarget(); }
		"FATT" G 5 Bright { A_SpawnProjectile("RS_GreenBomb1", 32, 13, random(-5, 5)); }
		"FATT" G 0 Bright { A_SpawnProjectile("RS_GreenBomb1", 32, -13, random(-5, 5)); }
		"FATT" H 0 { A_FaceTarget(); }
		"FATT" H 4 Bright { A_SpawnProjectile("RS_Bluewave1", 32, 13, random(-5, 5)); }
		"FATT" H 0 Bright { A_SpawnProjectile("RS_Bluewave1", 32, -13, random(-8, 8)); }
		"FATT" I 0 { A_FaceTarget(); }
		"FATT" I 4 Bright { A_SpawnProjectile("RS_Bluewave1", 32, 13, random(-5, 5)); }
		"FATT" I 0 Bright { A_SpawnProjectile("RS_Bluewave1", 32, -13, random(-8, 8)); }
		"FATT" G 0 { A_FaceTarget(); }
		"FATT" G 4 Bright { A_SpawnProjectile("RS_Bluewave1", 32, 13, random(-5, 5)); }
		"FATT" G 0 Bright { A_SpawnProjectile("RS_Bluewave1", 32, -13, random(-8, 8)); }
		"FATT" H 0 { A_FaceTarget(); }
		"FATT" H 5 Bright { A_SpawnProjectile("RS_BlueFT", 32, 0); }
		"FATT" I 0 Bright { A_FaceTarget(); }
		"FATT" I 4 Bright { A_SpawnProjectile("RS_BlueFT2", 32, 0); }
		"FATT" I 3 Bright { A_SpawnProjectile("RS_BlueFT2", 32, 0, random(-4, 4)); }
		"FATT" G 2 Bright { A_SpawnProjectile("RS_BlueFT2", 32, 0, random(-9, 9)); }
		"FATT" G 2 Bright { A_SpawnProjectile("RS_BlueFT2", 32, 0, random(-16, 16)); }
		"FATT" H 0 { A_FaceTarget(); }
		"FATT" H 5 Bright { A_SpawnProjectile("RS_PurpleBomb1", 32, 13, random(-5, 5)); }
		"FATT" H 0 Bright { A_SpawnProjectile("RS_PurpleBomb1", 32, -13, random(-8, 8)); }
		"FATT" I 0 { A_FaceTarget(); }
		"FATT" I 5 Bright { A_SpawnProjectile("RS_PurpleBomb1", 32, 13, random(-5, 5)); }
		"FATT" I 0 Bright { A_SpawnProjectile("RS_PurpleBomb1", 32, -13, random(-8, 8)); }
		"FATT" G 0 { A_FaceTarget(); }
		"FATT" G 5 Bright { A_SpawnProjectile("RS_PurpleBomb1", 32, 13, random(-5, 5)); }
		"FATT" G 0 Bright { A_SpawnProjectile("RS_PurpleBomb1", 32, -13, random(-8, 8)); }
		"FATT" H 0 { A_FaceTarget(); }
		"FATT" H 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, 42, random(-3, 3), 0); }
		"FATT" H 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, -39, random(-6, 6), 0); }
		"FATT" I 0 { A_FaceTarget(); }
		"FATT" I 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, 42, random(-3, 3), 0); }
		"FATT" I 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, -39, random(-6, 6), 0); }
		"FATT" G 0 { A_FaceTarget(); }
		"FATT" G 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, 42, random(-3, 3), 0); }
		"FATT" G 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, -39, random(-6, 6), 0); }
		"FATT" H 0 { A_FaceTarget(); }
		"FATT" H 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, 42, random(-3, 3), 0); }
		"FATT" H 3 Bright { A_SpawnProjectile("RS_RocketShotFatso", 32, -39, random(-6, 6), 0); }
		"FATT" I 0 { A_FaceTarget(); }
		"FATT" I 0 { A_SpawnProjectile("RS_FatsoShotYE", 32, -12, random(-3, 3)); }
		"FATT" I 3 Bright { A_SpawnProjectile("RS_FatsoShotYE", 32, 12, random(-3, 3)); }
		"FATT" G 0 { A_FaceTarget(); }
		"FATT" G 0 { A_SpawnProjectile("RS_FatsoShotYE", 32, -12, random(-3, 3)); }
		"FATT" G 3 Bright { A_SpawnProjectile("RS_FatsoShotYE", 32, 12, random(-3, 3)); }
		"FATT" H 0 { A_FaceTarget(); }
		"FATT" H 0 { A_SpawnProjectile("RS_FatsoShotYE", 32, -12, random(-3, 3)); }
		"FATT" H 3 Bright { A_SpawnProjectile("RS_FatsoShotYE", 32, 12, random(-3, 3)); }
		"FATT" I 0 { A_FaceTarget(); }
		"FATT" I 0 { A_SpawnProjectile("RS_Shot2Fatso", 32, 20, random(-1, 1)); }
		"FATT" I 6 Bright { A_SpawnProjectile("RS_Shot2Fatso", 32, -20, random(-1, 1)); }
		"FATT" GB 6;
		"FATT" H 0 { bFLOAT = true; bNOGRAVITY = true; bDONTFALL = true; }
		"FATT" HHHHHHHH 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;

	// ---- ITS OWN TWO ATTACKS, no form involved. ----
	Missile.TEX.Beam:
		"ETHS" FEEFF 4 Bright { A_FaceTarget(); }
		"ETHS" FFFFFFFFFFFFFFFFFFFFFFFFFFF 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 10 Bright { A_SpawnProjectile("RS_SoulexBeam", 32, 0, 0); }
		"ETHS" FE 10 Bright;
		Goto See;
	Missile.TEX.SoulShot:
		"ETHS" FEEFF 4 Bright { A_FaceTarget(); }
		"ETHS" F 1 Bright { A_SetScale(1.15, 1.15); }
		"ETHS" F 1 Bright { A_SetScale(1.3, 1.3); }
		"ETHS" F 10 Bright { A_SpawnProjectile("RS_SOULEXSoulCharge", 32, 0, 0); }
		"ETHS" F 1 Bright { A_SetScale(1.15, 1.15); }
		"ETHS" F 1 Bright { A_SetScale(1.0, 1.0); }
		Goto See;

	Pain.TEX:
		"ETHS" G 3 Bright;
		"ETHS" G 3 Bright { A_Pain(); }
		"ETHS" G 3 Bright A_Jump(64, "Pain.TEX.Reset");
		Goto See;
	// One in four: recall the escorts to normal duty, blink out on a long
	// wander, and re-form with a fresh pair.
	Pain.TEX.Reset:
		"ETHS" GGGG 0 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" GG 1 { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" GG 0 { A_RadiusGive("RS_WhiteSoulAdsOff", 700, RGF_MONSTERS); }
		"ETHS" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_Wander(); }
		"ETHS" A 0 { A_SpawnItemEx("RS_SkullWSoulEX1", 32, 32, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"ETHS" A 0 { A_SpawnItemEx("RS_SkullWSoulEX2", -32, -32, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"ETHS" AB 1 Bright;
		Goto See;
	// It dies the way it fought: through every form it ever wore.
	Death.TEX:
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SKEL" M 0 Bright { A_StartSound("skeleton/death", CHAN_VOICE); }
		"SKEL" MNOPQ 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"FATT" K 0 Bright { A_StartSound("fatso/death", CHAN_VOICE); }
		// CHP writes "FATT KLMNOPQRST"; vanilla FATT stops at S.
		"FATT" KLMNOPQRS 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOS2" I 0 Bright { A_StartSound("knight/death", CHAN_VOICE); }
		"BOS2" IJKLMNO 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"VILE" Q 0 Bright { A_StartSound("vile/death", CHAN_VOICE); }
		"VILE" QRSTUVWXYZ 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BOSS" I 0 Bright { A_StartSound("baron/death", CHAN_VOICE); }
		// CHP writes "BOSS IJKLMNO"; frame O exists in no BOSS set.
		"BOSS" IJKLMN 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HEAD" H 0 Bright { A_StartSound("caco/death", CHAN_VOICE); }
		"HEAD" HIJKL 1 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" HIJKLMN 6 Bright;
		"ETHS" O 12 Bright { A_ScreamAndUnblock(); }
		Stop;
	}
}
