// =====================================================================
// RS_LostSoul -- per-tier state rebuild
// (docs/rs_09_monster_rebuild_spec.txt). Replaces LostSoul.
//
// THIRTEEN REAL CREATURES. Every tier is its own state cluster with
// literal sprites and Colourful Hell's own attack for that colour,
// ported from CH decorate/lostsouls.txt via the proven HF port:
//
//   T00 SKUL vanilla charge        T01 SKUL+tint splash then charge
//   T02 SKUL+tint fast charge      T03 LFX1 quick flame charge
//   T04 SKUL+tint charge           T05 FRGO forgotten-one charge
//   T06 ABSP abyss beetle: spits, worm, then charge
//   T07 SKUL+tint charge           T08 MISL bonfire ram
//   T09 BAL1 gray fireball ram     T10 FRGO twin bolts then charge
//   T11 WASP hornet: stand-off volley, or a close sting
//   T12 ETHS THE MIMIC -- cycles Revenant / Baron / Arch-vile ghost
//       forms and fires each one's full signature combo. The apex.
//
// SPRITE NOTES (verified on disk):
//   * BAL1 (T09) and MISL (T08) are vanilla IWAD projectile sprites
//     used as bodies -- CH's own choice for the "flaming ball" souls,
//     not a substitution. They carry frames A-E only, so those
//     clusters are authored inside that range.
//   * T06 was BST7 in the old table; CH/HF actually give the abyss
//     soul the ABSP beetle body, which is what ships here.
//   * T08's old BOSF token exists nowhere in ART SOURCE; MISL is the
//     same bonfire idea and is vanilla.
// =====================================================================

class RS_LostSoul : RS_MonsterMaster replaces LostSoul
{
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
		+FLOAT +NOGRAVITY +MISSILEMORE +DONTFALL +NOICEDEATH
		+FLOORCLIP
		AttackSound "skull/melee";
		PainSound "skull/pain";
		DeathSound "skull/death";
		ActiveSound "skull/active";
		Obituary "$OB_SKULL";
		Tag "Lost Soul";
		RenderStyle "SoulTrans";
	}

	// Audit data -- the clusters below are the live implementation.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SKUL SKUL SKUL LFX1 SKUL FRGO ABSP SKUL MISL BAL1 FRGO WASP ETHS";
	}

	override string TintTable()
	{
		return "- rs_soul_t01 rs_soul_t02 rs_soul_t03 rs_soul_t04 rs_soul_t05 "
		       "- rs_soul_t07 - rs_soul_t09 rs_soul_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:lostsoul role:skirmisher delivery:melee element:thermal mobility:flying";
	}

	States
	{
	// ===== SKUL body: T00 T01 T02 T04 T07 =====
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T07:
		"SKUL" AB 10 Bright { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T07:
		"SKUL" AB 6 Bright { A_Chase(); }
		Loop;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T07:
		"SKUL" E 3 Bright;
		"SKUL" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T07:
		"SKUL" F 6 Bright;
		"SKUL" G 6 Bright { A_Scream(); }
		"SKUL" H 6 Bright;
		"SKUL" I 6 Bright { A_NoBlocking(); }
		"SKUL" JK 6 Bright;
		Stop;

	// T00 -- the vanilla ram
	Missile.T00:
		"SKUL" C 10 Bright { A_FaceTarget(); }
	Missile.T00.Fly:
		"SKUL" D 4 Bright { A_SkullAttack(); }
		"SKUL" CD 4 Bright;
		Goto Missile.T00.Fly;

	// T01 GREEN -- spits a splasher, then rams
	Missile.T01:
		"SKUL" C 10 Bright { A_FaceTarget(); }
		"SKUL" D 6 Bright { A_SpawnProjectile("RS_SplasherSoul", 0, 0, 0); }
	Missile.T01.Fly:
		"SKUL" D 4 Bright { A_SkullAttack(); }
		"SKUL" CD 4 Bright;
		Goto Missile.T01.Fly;

	// T02 BLUE / T04 PURPLE / T07 FIREBLU -- faster rams
	Missile.T02:
	Missile.T04:
	Missile.T07:
		"SKUL" C 8 Bright { A_FaceTarget(); }
	Missile.T02.Fly:
		"SKUL" D 4 Bright { A_SkullAttack(); }
		"SKUL" CD 4 Bright;
		Goto Missile.T02.Fly;

	// ===== T03 CYAN -- flame soul (LFX1) =====
	Spawn.T03:
		"LFX1" AB 10 Bright { A_Look(); }
		Loop;
	See.T03:
		"LFX1" AB 5 Bright { A_Chase(); }
		Loop;
	Missile.T03:
		"LFX1" C 8 Bright { A_FaceTarget(); }
	Missile.T03.Fly:
		"LFX1" D 3 Bright { A_SkullAttack(); }
		"LFX1" CD 3 Bright;
		Goto Missile.T03.Fly;
	Pain.T03:
		"LFX1" E 3 Bright;
		"LFX1" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T03:
		"LFX1" F 6 Bright;
		"LFX1" G 6 Bright { A_Scream(); }
		"LFX1" H 6 Bright { A_NoBlocking(); }
		"LFX1" IJK 6 Bright;
		Stop;

	// ===== FRGO body: T05 forgotten, T10 twin-bolt =====
	Spawn.T05:
	Spawn.T10:
		"FRGO" AB 10 Bright { A_Look(); }
		Loop;
	See.T05:
	See.T10:
		"FRGO" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T05:
		"FRGO" C 10 Bright { A_FaceTarget(); }
	Missile.T05.Fly:
		"FRGO" D 4 Bright { A_SkullAttack(); }
		"FRGO" CD 4 Bright;
		Goto Missile.T05.Fly;
	Missile.T10:
		"FRGO" C 8 Bright { A_FaceTarget(); }
		"FRGO" D 5 Bright { A_SpawnProjectile("RS_SpitBoltLS", 0, 0, random(-5, 5)); }
		"FRGO" D 5 Bright { A_SpawnProjectile("RS_SpitBoltLS", 0, 0, random(-5, 5)); }
	Missile.T10.Fly:
		"FRGO" D 4 Bright { A_SkullAttack(); }
		"FRGO" CD 4 Bright;
		Goto Missile.T10.Fly;
	Pain.T05:
	Pain.T10:
		"FRGO" E 3 Bright;
		"FRGO" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T05:
	Death.T10:
		"FRGO" F 6 Bright;
		"FRGO" G 6 Bright { A_Scream(); }
		"FRGO" H 6 Bright { A_NoBlocking(); }
		"FRGO" IJ 6 Bright;
		Stop;

	// ===== T06 ABYSS -- beetle soul (ABSP): spits, worm, then rams =====
	Spawn.T06:
		"ABSP" AB 10 Bright { A_Look(); }
		Loop;
	See.T06:
		"ABSP" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T06:
		"ABSP" C 10 Bright { A_FaceTarget(); }
		"ABSP" D 4 Bright { A_SpawnProjectile("RS_BeetleSpitAbyss", 0, 0, random(-8, 8)); }
		"ABSP" D 4 Bright { A_SpawnProjectile("RS_BeetleSpitAbyss", 0, 0, random(-8, 8)); }
		"ABSP" C 4 Bright { A_SpawnProjectile("RS_WormLewd", 0, 0, 0); }
	Missile.T06.Fly:
		"ABSP" D 4 Bright { A_SkullAttack(); }
		"ABSP" CD 4 Bright;
		Goto Missile.T06.Fly;
	Pain.T06:
		"ABSP" E 3 Bright;
		"ABSP" E 3 Bright { A_Pain(); }
		Goto See;
	Death.T06:
		"ABSP" F 6 Bright;
		"ABSP" G 6 Bright { A_Scream(); }
		"ABSP" H 6 Bright { A_NoBlocking(); }
		"ABSP" IJ 6 Bright;
		Stop;

	// ===== T08 BROWN -- bonfire ram (MISL, vanilla, frames A-E) =====
	Spawn.T08:
		"MISL" AB 10 Bright { A_Look(); }
		Loop;
	See.T08:
		"MISL" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T08:
		"MISL" A 10 Bright { A_FaceTarget(); }
	Missile.T08.Fly:
		"MISL" A 4 Bright { A_SkullAttack(); }
		"MISL" A 4 Bright;
		Goto Missile.T08.Fly;
	Pain.T08:
		"MISL" A 3 Bright;
		"MISL" A 3 Bright { A_Pain(); }
		Goto See;
	Death.T08:
		"MISL" B 6 Bright { A_Scream(); }
		"MISL" C 6 Bright { A_NoBlocking(); }
		"MISL" DE 6 Bright;
		Stop;

	// ===== T09 GRAY -- fireball ram (BAL1, vanilla, frames A-E) =====
	Spawn.T09:
		"BAL1" AB 10 Bright { A_Look(); }
		Loop;
	See.T09:
		"BAL1" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T09:
		"BAL1" A 12 Bright { A_FaceTarget(); }
	Missile.T09.Fly:
		"BAL1" B 6 Bright { A_SkullAttack(); }
		"BAL1" AB 4 Bright;
		Goto Missile.T09.Fly;
	Pain.T09:
		"BAL1" A 3 Bright;
		"BAL1" A 3 Bright { A_Pain(); }
		Goto See;
	Death.T09:
		"BAL1" C 6 Bright { A_Scream(); }
		"BAL1" D 6 Bright { A_NoBlocking(); }
		"BAL1" E 6 Bright;
		Stop;

	// ===== T11 BLACK -- hornet (WASP). Volley at range, sting up close.
	// WASP ships only A-D, so the whole cluster lives in those frames. =====
	Spawn.T11:
		"WASP" AB 10 Bright { A_Look(); }
		Loop;
	See.T11:
		"WASP" ABCD 4 Bright { A_Chase(); }
		Loop;
	Missile.T11:
		TNT1 A 0 A_JumpIfCloser(96, "Missile.T11.Sting");
		"WASP" A 6 Bright { A_FaceTarget(); }
		"WASP" B 3 Bright { A_SpawnProjectile("RS_BSoulHellNo", 0, 0, random(-6, 6)); }
		"WASP" B 3 Bright { A_SpawnProjectile("RS_BSoulHellNo", 0, 0, random(-6, 6)); }
		"WASP" B 3 Bright { A_SpawnProjectile("RS_BSoulHellNo", 0, 0, random(-6, 6)); }
		Goto See;
	Missile.T11.Sting:
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger1", 0, 0, random(-10, 10)); }
		"WASP" B 2 Bright { A_SpawnProjectile("RS_BSoulStinger2", 0, 0, random(-10, 10)); }
		"WASP" A 3 Bright { A_SkullAttack(); }
		Goto See;
	Pain.T11:
		"WASP" A 2 Bright;
		"WASP" A 2 Bright { A_Pain(); }
		Goto See;
	Death.T11:
		"WASP" C 5 Bright { A_Scream(); }
		"WASP" D 5 Bright { A_NoBlocking(); }
		"WASP" D 5 Bright A_FadeOut(0.2);
		Stop;

	// ===== T12 WHITE -- THE MIMIC (ETHS). Ghost-flashes into one of
	// three forms and fires that monster's full signature combo. NOPAIN
	// is held for the duration so a combo cannot be interrupted. =====
	Spawn.T12:
		"ETHS" AB 10 Bright { A_Look(); }
		Loop;
	See.T12:
		"ETHS" AB 6 Bright { A_Chase(); }
		Loop;
	Missile.T12:
		"ETHS" C 0 { bNOPAIN = true; }
		"ETHS" C 3 Bright { A_StartSound("skull/active", CHAN_VOICE); }
		"ETHS" E 3 Bright;
		"ETHS" F 3 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" F 0 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" P 3 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" Q 2 Bright { A_SpawnProjectile("RS_WSSmore", 16, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"ETHS" R 1 Bright A_Jump(256, "Missile.T12.Rev", "Missile.T12.Arch", "Missile.T12.Baron");
		Goto See;
	Missile.T12.Rev:
		"SKEL" J 6 Bright { A_FaceTarget(); }
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracerHoming", 50, 7, 5); }
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracerHoming", 50, -7, -5); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_AcidBlast1", 50, 7, 12); }
		"SKEL" K 0 { A_SpawnProjectile("RS_AcidBlast1", 50, -7, -12); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Zap7", 50, 7, 1); }
		"SKEL" K 0 { A_SpawnProjectile("RS_Zap7", 50, -7, -1); }
		"SKEL" J 4 { A_FaceTarget(); }
		"SKEL" K 7 { A_SpawnProjectile("RS_Purp1", 50, 7, 9); }
		"SKEL" K 0 { A_SpawnProjectile("RS_Purp1", 50, -7, -9); }
		"ETHS" A 0 { bNOPAIN = false; }
		Goto See;
	Missile.T12.Baron:
		"BOSS" H 8 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BOSS" EEF 8 { A_FaceTarget(); }
		"BOSS" G 7 Bright { A_SpawnProjectile("RS_BaronWave", 32, 0, 0); }
		"BOSS" EF 5 { A_FaceTarget(); }
		"BOSS" G 5 Bright { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-1, 1)); }
		"BOSS" G 3 Bright { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-8, 8)); }
		"BOSS" EF 3 { A_FaceTarget(); }
		"BOSS" G 3 Bright { A_SpawnProjectile("RS_SmashBalls2", 32, 5, random(-8, 8)); }
		"BOSS" G 3 Bright { A_SpawnProjectile("RS_BaronStar", 32, 5, random(-8, 8)); }
		"ETHS" A 0 { bNOPAIN = false; }
		Goto See;
	Missile.T12.Arch:
		"VILE" G 5 Bright { A_FaceTarget(); }
		"VILE" IJKLM 6 Bright { A_FaceTarget(); }
		"VILE" N 1 Bright { A_SpawnProjectile("RS_BigBolt2", 32, 0, 0); }
		"VILE" G 7 Bright { A_FaceTarget(); }
		"VILE" H 6 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILE" IJKLM 5 Bright { A_FaceTarget(); }
		"VILE" N 4 Bright { A_SpawnProjectile("RS_Homer1", 32, 0, random(-6, 6)); }
		"VILE" H 4 Bright { A_SpawnProjectile("RS_ArcRing2", 32, 0, random(-12, 12)); }
		"ETHS" A 0 { bNOPAIN = false; }
		Goto See;
	Pain.T12:
		"ETHS" C 2 Bright;
		"ETHS" C 2 Bright { A_Pain(); }
		Goto See;
	Death.T12:
		"ETHS" F 6 Bright;
		"ETHS" G 6 Bright { A_Scream(); }
		"ETHS" H 6 Bright { A_NoBlocking(); }
		"ETHS" IJK 6 Bright;
		Stop;
	}
}
