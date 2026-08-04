// =====================================================================
// RS_Shotgunner -- per-tier state rebuild
// (docs/rs_09_monster_rebuild_spec.txt). Replaces ShotgunGuy.
//
// THIRTEEN REAL CREATURES. Every tier is its own state cluster with
// literal sprites and Colourful Hell's own attack for that colour,
// ported from CH decorate/Shotgunners.txt via the proven HF port:
//
//   T00 SPOS vanilla 3-pellet   T01 SPOS+tint shot + green bolt
//   T02 SPOS+tint shot + lance  T03 CNSG frost: pellets + ice shot
//   T04 HMZP shot + purple fire T05 ASGZ 7-pellet assault spread
//   T06 ABSG abyss: 5 pellets + abyss shot + splash
//   T07 GPOS twin fire-shells   T08 QSZM heavy 5-pellet slug
//   T09 GRSH single hard slug   T10 GPOS shot + red mess
//   T11 ZSP1 pellets + gas grenade
//   T12 BENE apex: 8-pellet storm, or a double mine lob
//
// RS mechanic preserved: the T07+ squad summon (RS_CallSquad), rolled
// in the Missile DISPATCHER so every tier inherits it without
// repeating the roll thirteen times.
// =====================================================================

class RS_Shotgunner : RS_HumanMonster replaces ShotgunGuy
{
	Default
	{
		Health 30;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "shotguy/sight";  PainSound "shotguy/pain";
		DeathSound "shotguy/death"; ActiveSound "shotguy/active";
		AttackSound "shotguy/attack";
		Obituary "$OB_SHOTGUY";
		Tag "Shotgun Guy";
		DropItem "Shotgun";
	}

	// Audit data -- the clusters below are the live implementation.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SPOS SPOS SPOS CNSG HMZP ASGZ ABSG GPOS QSZM GRSH GPOS ZSP1 BENE";
	}

	override string TintTable()
	{
		return "- rs_sgun_t01 rs_sgun_t02 rs_sgun_t03 rs_sgun_t04 - "
		       "rs_sgun_t06 rs_sgun_t07 rs_sgun_t08 rs_sgun_t09 "
		       "rs_sgun_t10 rs_sgun_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:shotgunner role:fodder delivery:bullet payload:multi element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE CREW COMMANDER. CHP's black shotgunner calls in a squad of its
	// own kind. Summoning its OWN species at a lower tier is the
	// cleanest version of that -- no bespoke minion class, and the squad
	// inherits the whole tier system for free.
	// -----------------------------------------------------------------
	const RS_SG_TIER_SQUAD = 7;

	override bool MinionsDieWithMe() { return false; }

	void RS_CallSquad()
	{
		if (Tier < RS_SG_TIER_SQUAD)
			return;
		int cap = (Tier >= 11) ? 4 : 2;
		if (SummonPack("RS_Shotgunner", 2, cap, -4, 88.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	// ===== dispatcher: family-wide squad roll happens here =====
	Missile:
		TNT1 A 0
		{
			// One attack in five becomes a call for backup.
			if (Tier >= RS_SG_TIER_SQUAD && random(0, 255) < 50)
				return ResolveState("CallSquad");
			return TierState("Missile");
		}
		Goto See;
	CallSquad:
		// Bare #### keeps whichever body this tier dressed us in; E/F
		// exist on every shotgunner body in the table.
		#### E 12 { A_FaceTarget(); }
		#### F 14 Bright { RS_CallSquad(); }
		#### E 8;
		Goto See;

	// ===== T00/T01/T02 SPOS body =====
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
		"SPOS" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
		"SPOS" AABBCCDD 4 { A_Chase(); }
		Loop;
	Pain.T00:
	Pain.T01:
	Pain.T02:
		"SPOS" G 3;
		"SPOS" G 3 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
		"SPOS" H 5;
		"SPOS" I 5 { A_Scream(); }
		"SPOS" J 5 { A_NoBlocking(); }
		"SPOS" K 5;
		"SPOS" L -1;
		Stop;
	XDeath.T00:
	XDeath.T01:
	XDeath.T02:
		"SPOS" M 5;
		"SPOS" N 5 { A_XScream(); }
		"SPOS" O 5 { A_NoBlocking(); }
		"SPOS" PQRST 5;
		"SPOS" U -1;
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
		"SPOS" LKJIH 5;
		Goto See;

	// T00 -- vanilla 3-pellet blast
	Missile.T00:
		"SPOS" E 10 { A_FaceTarget(); }
		"SPOS" F 10 Bright { A_SPosAttack(); }
		"SPOS" E 10;
		Goto See;

	// T01 GREEN -- shell plus a seeking green bolt
	Missile.T01:
		"SPOS" E 10 { A_FaceTarget(); }
		"SPOS" F 8 Bright { A_SPosAttack(); }
		"SPOS" F 4 Bright { A_SpawnProjectile("RS_SGshot1", 24, 0, 0); }
		"SPOS" E 8;
		Goto See;

	// T02 BLUE -- shell plus a piercing lance
	Missile.T02:
		"SPOS" E 10 { A_FaceTarget(); }
		"SPOS" F 8 Bright { A_SpawnProjectile("RS_SGLance1", 24, 0, random(-3, 3)); }
		"SPOS" E 8;
		Goto See;

	// ===== T03 CYAN -- frost gunner (CNSG) =====
	Spawn.T03:
		"CNSG" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"CNSG" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T03:
		"CNSG" E 10 { A_FaceTarget(); }
		"CNSG" F 6 Bright { A_CustomBulletAttack(8, 0, 3, random(3, 9), "BulletPuff"); }
		"CNSG" F 4 Bright { A_SpawnProjectile("RS_IceZombieShot2", 24, 0, random(-6, 6)); }
		"CNSG" E 8;
		Goto See;
	Pain.T03:
		"CNSG" G 3;
		"CNSG" G 3 { A_Pain(); }
		Goto See;
	Death.T03:
		"CNSG" H 5;
		"CNSG" I 5 { A_Scream(); }
		"CNSG" J 5 { A_NoBlocking(); }
		"CNSG" K 5;
		"CNSG" L -1;
		Stop;

	// ===== T04 PURPLE -- hazmat gunner (HMZP) =====
	Spawn.T04:
		"HMZP" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"HMZP" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T04:
		"HMZP" E 10 { A_FaceTarget(); }
		"HMZP" F 8 Bright { A_SPosAttack(); }
		"HMZP" F 4 Bright { A_SpawnProjectile("RS_PurpFire2", 24, 0, random(-4, 4)); }
		"HMZP" E 8;
		Goto See;
	Pain.T04:
		"HMZP" G 3;
		"HMZP" G 3 { A_Pain(); }
		Goto See;
	Death.T04:
		"HMZP" H 5;
		"HMZP" I 5 { A_Scream(); }
		"HMZP" J 5 { A_NoBlocking(); }
		"HMZP" K 5;
		"HMZP" L -1;
		Stop;
	XDeath.T04:
		"HMZP" M 5;
		"HMZP" N 5 { A_XScream(); }
		"HMZP" O 5 { A_NoBlocking(); }
		"HMZP" PQRST 5;
		"HMZP" U -1;
		Stop;

	// ===== T05 YELLOW -- assault gunner (ASGZ), 7-pellet spread =====
	Spawn.T05:
		"ASGZ" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"ASGZ" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T05:
		"ASGZ" E 10 { A_FaceTarget(); }
		"ASGZ" F 10 Bright { A_CustomBulletAttack(11, 0, 7, random(3, 9), "BulletPuff"); }
		"ASGZ" E 8;
		Goto See;
	Pain.T05:
		"ASGZ" G 3;
		"ASGZ" G 3 { A_Pain(); }
		Goto See;
	Death.T05:
		"ASGZ" H 5;
		"ASGZ" I 5 { A_Scream(); }
		"ASGZ" J 5 { A_NoBlocking(); }
		"ASGZ" K 5;
		"ASGZ" L -1;
		Stop;
	XDeath.T05:
		"ASGZ" M 5;
		"ASGZ" N 5 { A_XScream(); }
		"ASGZ" O 5 { A_NoBlocking(); }
		"ASGZ" PQRST 5;
		"ASGZ" U -1;
		Stop;

	// ===== T06 ABYSS -- (ABSG) pellets, abyss shot, splash =====
	Spawn.T06:
		"ABSG" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"ABSG" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T06:
		"ABSG" E 10 { A_FaceTarget(); }
		"ABSG" F 6 Bright { A_CustomBulletAttack(11, 0, 5, random(5, 12), "BulletPuff"); }
		"ABSG" F 4 Bright { A_SpawnProjectile("RS_AbyssZshotCH2", 24, 0, random(-8, 8)); }
		"ABSG" F 4 Bright { A_SpawnProjectile("RS_SplashAbyss2", 24, 0, 0); }
		"ABSG" E 8;
		Goto See;
	Pain.T06:
		"ABSG" G 3;
		"ABSG" G 3 { A_Pain(); }
		Goto See;
	Death.T06:
		"ABSG" H 5;
		"ABSG" I 5 { A_Scream(); }
		"ABSG" J 5 { A_NoBlocking(); }
		"ABSG" K 5;
		"ABSG" L -1;
		Stop;
	XDeath.T06:
		"ABSG" M 5;
		"ABSG" N 5 { A_XScream(); }
		"ABSG" O 5 { A_NoBlocking(); }
		"ABSG" PQRST 5;
		"ABSG" U -1;
		Stop;

	// ===== T07 FIREBLU / T10 RED -- both wear GPOS, different guns =====
	Spawn.T07:
	Spawn.T10:
		"GPOS" AB 10 { A_Look(); }
		Loop;
	See.T07:
	See.T10:
		"GPOS" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T07:
		"GPOS" E 10 { A_FaceTarget(); }
		"GPOS" F 6 Bright { A_SpawnProjectile("RS_FireSGguy", 24, 0, random(-6, 6)); }
		"GPOS" F 4 Bright { A_SpawnProjectile("RS_FireSGguy", 24, 0, random(-6, 6)); }
		"GPOS" E 8;
		Goto See;
	Missile.T10:
		"GPOS" E 10 { A_FaceTarget(); }
		"GPOS" F 6 Bright { A_CustomBulletAttack(11, 0, 3, random(8, 18), "BulletPuff"); }
		"GPOS" F 4 Bright { A_SpawnProjectile("RS_RedMessImp3", 24, 0, random(-6, 6)); }
		"GPOS" E 8;
		Goto See;
	Pain.T07:
	Pain.T10:
		"GPOS" G 3;
		"GPOS" G 3 { A_Pain(); }
		Goto See;
	Death.T07:
	Death.T10:
		"GPOS" H 5;
		"GPOS" I 5 { A_Scream(); }
		"GPOS" J 5 { A_NoBlocking(); }
		"GPOS" K 5;
		"GPOS" L -1;
		Stop;
	XDeath.T07:
	XDeath.T10:
		"GPOS" M 5;
		"GPOS" N 5 { A_XScream(); }
		"GPOS" O 5 { A_NoBlocking(); }
		"GPOS" PQRST 5;
		"GPOS" T -1;
		Stop;

	// ===== T08 BROWN -- heavy slug gunner (QSZM) =====
	Spawn.T08:
		"QSZM" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"QSZM" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T08:
		"QSZM" E 10 { A_FaceTarget(); }
		"QSZM" F 10 Bright { A_CustomBulletAttack(11, 0, 5, random(6, 16), "BulletPuff"); }
		"QSZM" E 8;
		Goto See;
	Pain.T08:
		"QSZM" G 3;
		"QSZM" G 3 { A_Pain(); }
		Goto See;
	Death.T08:
		"QSZM" H 5;
		"QSZM" I 5 { A_Scream(); }
		"QSZM" J 5 { A_NoBlocking(); }
		"QSZM" K 5;
		"QSZM" L -1;
		Stop;
	XDeath.T08:
		"QSZM" M 5;
		"QSZM" N 5 { A_XScream(); }
		"QSZM" O 5 { A_NoBlocking(); }
		"QSZM" PQRST 5;
		"QSZM" U -1;
		Stop;

	// ===== T09 GRAY -- sniper slug, one hard hit (GRSH) =====
	// GRSH ships A-L then O,P,Q only (no M/N on disk) -- the XDeath
	// below uses the frames that exist.
	Spawn.T09:
		"GRSH" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"GRSH" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T09:
		"GRSH" E 10 { A_FaceTarget(); }
		"GRSH" F 10 Bright { A_CustomBulletAttack(5.6, 0, 1, random(20, 45), "BulletPuff"); }
		"GRSH" E 8;
		Goto See;
	Pain.T09:
		"GRSH" G 3;
		"GRSH" G 3 { A_Pain(); }
		Goto See;
	Death.T09:
		"GRSH" H 5;
		"GRSH" I 5 { A_Scream(); }
		"GRSH" J 5 { A_NoBlocking(); }
		"GRSH" K 5;
		"GRSH" L -1;
		Stop;
	XDeath.T09:
		"GRSH" O 5 { A_XScream(); }
		"GRSH" P 5 { A_NoBlocking(); }
		"GRSH" Q -1;
		Stop;

	// ===== T11 BLACK -- gas grenadier (ZSP1) =====
	Spawn.T11:
		"ZSP1" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"ZSP1" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T11:
		"ZSP1" E 10 { A_FaceTarget(); }
		"ZSP1" F 6 Bright { A_CustomBulletAttack(11, 0, 5, random(8, 20), "BulletPuff"); }
		"ZSP1" F 6 Bright { A_SpawnProjectile("RS_SGGasNade", 24, 0, 0); }
		"ZSP1" E 8;
		Goto See;
	Pain.T11:
		"ZSP1" G 3;
		"ZSP1" G 3 { A_Pain(); }
		Goto See;
	Death.T11:
		"ZSP1" H 5;
		"ZSP1" I 5 { A_Scream(); }
		"ZSP1" J 5 { A_NoBlocking(); }
		"ZSP1" K 5;
		"ZSP1" L -1;
		Stop;

	// ===== T12 WHITE -- the Benelli. Pellet storm or a double mine =====
	Spawn.T12:
		"BENE" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"BENE" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T12:
		TNT1 A 0 A_Jump(96, "Missile.T12.Mine");
		"BENE" E 8 { A_FaceTarget(); }
		"BENE" F 4 Bright { A_CustomBulletAttack(8, 0, 8, random(10, 25), "BulletPuff"); }
		"BENE" F 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 24, 0, random(-6, 6)); }
		"BENE" E 8 { A_CPosRefire(); }
		Goto See;
	Missile.T12.Mine:
		"BENE" E 8 { A_FaceTarget(); }
		"BENE" F 6 Bright { A_SpawnProjectile("RS_MineShotgun", 24, 0, random(-8, 8)); }
		"BENE" F 6 Bright { A_SpawnProjectile("RS_MineShotgun", 24, 0, random(-8, 8)); }
		"BENE" E 8;
		Goto See;
	Pain.T12:
		"BENE" G 3;
		"BENE" G 3 { A_Pain(); }
		Goto See;
	Death.T12:
		"BENE" H 5;
		"BENE" I 5 { A_Scream(); }
		"BENE" J 5 { A_NoBlocking(); }
		"BENE" K 5;
		"BENE" L -1;
		Stop;
	XDeath.T12:
		"BENE" M 5;
		"BENE" N 5 { A_XScream(); }
		"BENE" O 5 { A_NoBlocking(); }
		"BENE" PQ 5;
		"BENE" R -1;
		Stop;
	}
}
