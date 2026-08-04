// =====================================================================
// RS_HellKnight -- per-tier state rebuild
// (docs/rs_09_monster_rebuild_spec.txt). Replaces HellKnight.
//
// THIRTEEN REAL CREATURES, ported from CH decorate/Hellknights.txt:
//
//   T00 BOS2 vanilla bruiser        T01 BOS2+tint combo attack
//   T02 BOS2+tint blue-ball chain (four-shot LOS-checked string)
//   T03 HFRY frost knight: ice-shot volley, flips scale mid-cast
//   T04 BOS2+tint bolt chain, close-range breath
//   T05 BRUS abyss balls            T06 BRUS abyss bar-volley
//   T07 BOS2+tint fireblu: bolt chain or a scatter storm
//   T08 HWAR Hellion warrior: hellion ball, closes to melee
//   T09 BOS2+tint moloch nails, or mine lobs
//   T10 BRUR heavy bolt chain       T11 BRUC THE GHOST -- splits into
//       a genuine second knight the moment it spawns
//   T12 PHAN phantom: mines + nails, the apex
//
// RS mechanics preserved: the T11+ instant clone split (guarded so a
// clone never re-splits) and the T07+ imp escort call, both rolled in
// the dispatchers so every tier inherits them.
// =====================================================================

class RS_HellKnight : RS_KnightBase replaces HellKnight
{
	Default
	{
		Health 500;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 50;
		Monster;
		+FLOORCLIP
		SeeSound "knight/sight";   PainSound "knight/pain";
		DeathSound "knight/death"; ActiveSound "knight/active";
		Obituary "$OB_KNIGHT";
		HitObituary "$OB_KNIGHTHIT";
		Tag "Hell Knight";
	}

	// Audit data -- the clusters below are the live implementation.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BOS2 BOS2 BOS2 HFRY BOS2 BRUS BRUS BOS2 HWAR BOS2 BRUR BRUC PHAN";
	}

	override string TintTable()
	{
		return "- rs_hk_t01 rs_hk_t02 rs_hk_t03 rs_hk_t04 - "
		       "rs_hk_t06 rs_hk_t07 - rs_hk_t09 - rs_hk_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:hellknight role:bruiser delivery:heavy delivery:melee element:thermal mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE GHOST OF E1M8. CHP's white hell knight splits into TWO full
	// -power monsters the instant it spawns -- not a pet, a genuine
	// duplicate. Deliberately not master-linked: killing one does
	// nothing to the other, which is the whole scare.
	//
	// Guarded so the clone doesn't clone: only an original (no master,
	// flag unset) ever splits.
	// -----------------------------------------------------------------
	const RS_HK_TIER_CLONE  = 11;
	const RS_HK_TIER_ESCORT = 7;

	private bool rsIsClone;
	private bool rsSplitDone;

	override bool MinionsDieWithMe() { return false; }

	void RS_Split()
	{
		if (Tier < RS_HK_TIER_CLONE || rsIsClone || rsSplitDone)
			return;
		rsSplitDone = true;

		Vector3 p = (pos.xy + (cos(angle + 90), sin(angle + 90)) * 40.0, pos.z);
		let mo = RS_HellKnight(Spawn("RS_HellKnight", p, ALLOW_REPLACE));
		if (!mo)
			return;

		mo.rsIsClone   = true;     // it will not split again
		mo.rsSplitDone = true;
		mo.SetTier(Tier, true);
		mo.target = target;
		mo.angle  = angle;
		A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	void RS_CallEscort()
	{
		if (Tier < RS_HK_TIER_ESCORT)
			return;
		if (SummonPack("RS_Imp", 2, 4, -3, 96.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	// ===== dispatchers: family-wide mechanics =====
	Spawn:
		TNT1 A 0 NoDelay { RS_Split(); }
		TNT1 A 0 { return TierState("Spawn"); }
		Goto Spawn.T00;
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_HK_TIER_ESCORT && random(0, 255) < 48)
				return ResolveState("CallEscort");
			return TierState("Missile");
		}
		Goto See;
	CallEscort:
		// Bare #### keeps this tier's body; E/F/G exist on every one.
		#### EF 8 { A_FaceTarget(); }
		#### G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ===== BOS2 body: T00 T01 T02 T04 T07 T09 =====
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T07:
	Spawn.T09:
		"BOS2" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T07:
	See.T09:
		"BOS2" AABB 3 { A_Chase(); }
		"BOS2" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T00:
	Melee.T01:
	Melee.T02:
	Melee.T04:
	Melee.T07:
	Melee.T09:
		"BOS2" EF 8 { A_FaceTarget(); }
		"BOS2" G 8 { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T07:
	Pain.T09:
		"BOS2" H 2;
		"BOS2" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T07:
	Death.T09:
		"BOS2" I 8;
		"BOS2" J 8 { A_Scream(); }
		"BOS2" K 8;
		"BOS2" L 8 { A_NoBlocking(); }
		"BOS2" MN 8;
		"BOS2" N -1;
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
	Raise.T04:
	Raise.T07:
	Raise.T09:
		"BOS2" NMLKJI 8;
		Goto See;

	// T00 -- vanilla
	Missile.T00:
		"BOS2" EF 8 { A_FaceTarget(); }
		"BOS2" G 8 { A_BruisAttack(); }
		Goto See;

	// T01 GREEN -- combo: ball at range, claw up close
	Missile.T01:
		"BOS2" EF 8 { A_FaceTarget(); }
		// BaronBall is the stock GZDoom class -- CH calls it directly.
		"BOS2" G 8 { A_CustomComboAttack("BaronBall", 32, 11 * random(1, 8), "baron/melee"); }
		Goto See;

	// T02 BLUE -- a four-shot chain, each link LOS-checked
	Missile.T02:
		"BOS2" EF 8 { A_FaceTarget(); }
		"BOS2" G 8 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-1, 1)); }
		"BOS2" G 0 A_CheckSight("See");
		"BOS2" PQ 6 { A_FaceTarget(); }
		"BOS2" R 6 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-3, 3)); }
		"BOS2" G 0 A_CheckSight("See");
		"BOS2" EF 4 { A_FaceTarget(); }
		"BOS2" G 4 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-5, 5)); }
		"BOS2" PQ 3 { A_FaceTarget(); }
		"BOS2" R 3 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-7, 7)); }
		Goto See;

	// T04 PURPLE -- bolt chain that can loop on itself
	Missile.T04:
		"BOS2" EF 8 { A_FaceTarget(); }
		"BOS2" G 8 { A_SpawnProjectile("RS_HKBolt2", 32, 3, random(-1, 1)); }
		TNT1 A 0 A_Jump(128, "Missile.T04.Alt");
		Goto See;
	Missile.T04.Alt:
		"BOS2" PQ 8 { A_FaceTarget(); }
		"BOS2" R 8 { A_SpawnProjectile("RS_HKBolt2", 32, 3, random(-1, 1)); }
		TNT1 A 0 A_Jump(76, "Missile.T04");
		Goto See;

	// T07 FIREBLU -- a bolt chain, or a wide scatter storm
	Missile.T07:
		TNT1 A 0 A_Jump(255, "Missile.T07.Bolt", "Missile.T07.Storm");
		Goto See;
	Missile.T07.Bolt:
		"BOS2" EF 6 { A_FaceTarget(); }
		"BOS2" G 6 { A_SpawnProjectile("RS_FireBluHKBall1", 32, 3, random(-1, 1)); }
		"BOS2" PQ 5 { A_FaceTarget(); }
		"BOS2" R 5 { A_SpawnProjectile("RS_FireBluHKBall1", 32, 3, random(-9, 9)); }
		TNT1 A 0 A_Jump(76, "Missile.T07.Bolt");
		Goto See;
	Missile.T07.Storm:
		"BOS2" H 12 Bright { A_FaceTarget(); }
		"BOS2" HHHHHH 0 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), CMF_OFFSETPITCH, random(-15, 15)); }
		"BOS2" HHHH 1 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), CMF_OFFSETPITCH, random(-15, 15)); }
		"BOS2" HHHHHH 0 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), CMF_OFFSETPITCH, random(-15, 15)); }
		"BOS2" HHHH 1 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), CMF_OFFSETPITCH, random(-15, 15)); }
		"BOS2" H 6 Bright;
		Goto See;

	// T09 GRAY -- moloch nails at range, mine lobs up close
	Missile.T09:
		TNT1 A 0 A_JumpIfCloser(600, "Missile.T09.Mines");
		"BOS2" EF 8 { A_FaceTarget(); }
		"BOS2" G 8 { A_SpawnProjectile("RS_MolochNail", 32, 3, random(-1, 1)); }
		TNT1 A 0 A_Jump(128, "Missile.T09.Alt");
		Goto See;
	Missile.T09.Alt:
		"BOS2" PQ 8 { A_FaceTarget(); }
		"BOS2" R 8 { A_SpawnProjectile("RS_MolochNail", 32, 3, random(-1, 1)); }
		Goto See;
	Missile.T09.Mines:
		"BOS2" H 10 Bright { A_FaceTarget(); }
		"BOS2" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-1, 1)); }
		"BOS2" H 12 Bright { A_FaceTarget(); }
		"BOS2" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-9, 9)); }
		"BOS2" H 12 Bright { A_FaceTarget(); }
		"BOS2" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-25, 25)); }
		Goto See;

	// ===== T03 CYAN -- the frost knight (HFRY) =====
	Spawn.T03:
		"HFRY" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"HFRY" AABB 3 { A_Chase(); }
		"HFRY" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T03:
		"HFRY" EF 8 { A_FaceTarget(); }
		"HFRY" G 8 { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		Goto See;
	// CH flips the sprite's X scale between casts so the knight visibly
	// switches throwing arm -- kept.
	Missile.T03:
		"HFRY" EF 6 { A_FaceTarget(); }
		"HFRY" G 6 { A_SpawnProjectile("RS_IceHKShot", 42, 0, 0); }
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 { A_SetScale(-1.0, 1.0); }
		"HFRY" EF 6 { A_FaceTarget(); }
		"HFRY" G 6 { A_SpawnProjectile("RS_IceHKShot", 42, 0, random(-3, 3)); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); }
		TNT1 A 0 A_CheckSight("See");
		"HFRY" EF 4 { A_FaceTarget(); }
		"HFRY" G 5 { A_SpawnProjectile("RS_IceHKShot", 42, 0, random(-1, 1)); }
		"HFRY" G 4 { A_SpawnProjectile("RS_IceOrbCyanHK", 42, 0, 0); }
		Goto See;
	Pain.T03:
		"HFRY" H 2;
		"HFRY" H 2 { A_Pain(); }
		Goto See;
	Death.T03:
		"HFRY" I 8;
		"HFRY" J 8 { A_Scream(); }
		"HFRY" K 8;
		"HFRY" L 8 { A_NoBlocking(); }
		"HFRY" MN 8;
		"HFRY" O -1;
		Stop;

	// ===== BRUS body: T05 abyss balls, T06 abyss bar-volley =====
	Spawn.T05:
	Spawn.T06:
		"BRUS" AB 10 { A_Look(); }
		Loop;
	See.T05:
	See.T06:
		"BRUS" AABB 3 { A_Chase(); }
		"BRUS" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T05:
	Melee.T06:
		"BRUS" EF 8 { A_FaceTarget(); }
		"BRUS" G 8 { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		Goto See;
	// T05 -- the alternating two-arm ball string
	Missile.T05:
		"BRUS" EF 4 Bright { A_FaceTarget(); }
		"BRUS" G 2 Bright { A_SpawnProjectile("RS_AbyssHKBall", 32, 2, random(-1, 1)); }
		"BRUS" G 1 Bright A_MonsterRefire(128, "See");
		"BRUS" HI 4 Bright { A_FaceTarget(); }
		"BRUS" J 2 Bright { A_SpawnProjectile("RS_AbyssHKBall", 32, 2, random(-1, 1)); }
		"BRUS" J 1 Bright A_MonsterRefire(128, "See");
		Goto Missile.T05;
	// T06 -- the barrage: one aimed, then two fans of three
	Missile.T06:
		"BRUS" K 7 Bright { A_FaceTarget(); }
		"BRUS" KL 6 Bright { A_FaceTarget(); }
		"BRUS" M 1 Bright { A_SpawnProjectile("RS_AbyssHKBall", 32, 0, 0); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_AbyssHKBall", 32, 0, random(1, 14)); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_AbyssHKBall", 32, 0, random(-14, -1)); }
		"BRUS" M 16 Bright { A_SpawnProjectile("RS_AbyssHKMist", 32, 0, 0); }
		Goto See;
	Pain.T05:
	Pain.T06:
		"BRUS" H 2;
		"BRUS" H 2 { A_Pain(); }
		Goto See;
	Death.T05:
	Death.T06:
		"BRUS" I 8;
		"BRUS" J 8 { A_Scream(); }
		"BRUS" K 8;
		"BRUS" L 8 { A_NoBlocking(); }
		"BRUS" MN 8;
		"BRUS" N -1;
		Stop;

	// ===== T08 BROWN -- the Hellion warrior (HWAR) =====
	Spawn.T08:
		"HWAR" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"HWAR" AABB 3 { A_Chase(); }
		"HWAR" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T08:
		"HWAR" EF 8 { A_FaceTarget(); }
		"HWAR" G 8 { A_CustomMeleeAttack(random(30, 110), "baron/melee"); }
		Goto See;
	Missile.T08:
		"HWAR" E 1 { A_FaceTarget(); }
		"HWAR" EF 8 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(88, "Melee.T08");
		"HWAR" G 6 { A_SpawnProjectile("RS_HellionBall", 32, 0); }
		Goto See;
	Pain.T08:
		"HWAR" H 2;
		"HWAR" H 2 { A_Pain(); }
		Goto See;
	Death.T08:
		"HWAR" I 8;
		"HWAR" J 8 { A_Scream(); }
		"HWAR" K 8;
		"HWAR" L 8 { A_NoBlocking(); }
		"HWAR" MN 8;
		"HWAR" O -1;
		Stop;

	// ===== T10 RED -- heavy bolt chain (BRUR) =====
	Spawn.T10:
		"BRUR" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"BRUR" AABB 3 { A_Chase(); }
		"BRUR" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T10:
		"BRUR" EF 8 { A_FaceTarget(); }
		"BRUR" G 8 { A_CustomMeleeAttack(random(25, 100), "baron/melee"); }
		Goto See;
	Missile.T10:
		"BRUR" EF 6 { A_FaceTarget(); }
		"BRUR" G 6 { A_SpawnProjectile("RS_HKBolt2", 32, 3, random(-1, 1)); }
		"BRUR" G 0 A_CheckSight("See");
		"BRUR" EF 5 { A_FaceTarget(); }
		"BRUR" G 5 { A_SpawnProjectile("RS_HKBolt2", 32, 3, random(-6, 6)); }
		TNT1 A 0 A_Jump(96, "Missile.T10");
		Goto See;
	Pain.T10:
		"BRUR" H 2;
		"BRUR" H 2 { A_Pain(); }
		Goto See;
	Death.T10:
		"BRUR" I 8;
		"BRUR" J 8 { A_Scream(); }
		"BRUR" K 8;
		"BRUR" L 8 { A_NoBlocking(); }
		"BRUR" MN 8;
		"BRUR" N -1;
		Stop;

	// ===== T11 BLACK -- THE GHOST (BRUC). Splits on spawn. =====
	Spawn.T11:
		"BRUC" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"BRUC" AABB 3 { A_Chase(); }
		"BRUC" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T11:
		"BRUC" EF 8 { A_FaceTarget(); }
		"BRUC" G 8 { A_CustomMeleeAttack(random(30, 120), "baron/melee"); }
		Goto See;
	Missile.T11:
		"BRUC" EF 6 { A_FaceTarget(); }
		"BRUC" G 6 Bright { A_SpawnProjectile("RS_HKBolt2", 32, 3, random(-1, 1)); }
		"BRUC" G 0 A_CheckSight("See");
		"BRUC" PQ 5 { A_FaceTarget(); }
		"BRUC" R 5 Bright { A_SpawnProjectile("RS_MolochNail", 32, 3, random(-9, 9)); }
		TNT1 A 0 A_Jump(96, "Missile.T11");
		Goto See;
	Pain.T11:
		"BRUC" H 2;
		"BRUC" H 2 { A_Pain(); }
		Goto See;
	Death.T11:
		"BRUC" I 8;
		"BRUC" J 8 { A_Scream(); }
		"BRUC" K 8;
		"BRUC" L 8 { A_NoBlocking(); }
		"BRUC" MN 8;
		"BRUC" O -1;
		Stop;

	// ===== T12 WHITE -- the phantom (PHAN). Mines and nails. =====
	Spawn.T12:
		"PHAN" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"PHAN" AABB 3 { A_Chase(); }
		"PHAN" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T12:
		"PHAN" EF 8 { A_FaceTarget(); }
		"PHAN" G 8 { A_CustomMeleeAttack(random(35, 130), "baron/melee"); }
		Goto See;
	Missile.T12:
		TNT1 A 0 A_JumpIfCloser(500, "Missile.T12.Mines");
		"PHAN" EF 6 { A_FaceTarget(); }
		"PHAN" G 6 Bright { A_SpawnProjectile("RS_MolochNail", 32, 3, random(-1, 1)); }
		"PHAN" G 0 A_CheckSight("See");
		"PHAN" EF 5 { A_FaceTarget(); }
		"PHAN" G 5 Bright { A_SpawnProjectile("RS_MolochNail", 32, 3, random(-8, 8)); }
		TNT1 A 0 A_Jump(96, "Missile.T12");
		Goto See;
	Missile.T12.Mines:
		"PHAN" H 10 Bright { A_FaceTarget(); }
		"PHAN" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-1, 1)); }
		"PHAN" H 12 Bright { A_FaceTarget(); }
		"PHAN" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-9, 9)); }
		"PHAN" H 12 Bright { A_FaceTarget(); }
		"PHAN" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-25, 25)); }
		Goto See;
	Pain.T12:
		"PHAN" H 2;
		"PHAN" H 2 { A_Pain(); }
		Goto See;
	Death.T12:
		"PHAN" I 8;
		"PHAN" J 8 { A_Scream(); }
		"PHAN" K 8;
		"PHAN" L 8 { A_NoBlocking(); }
		"PHAN" MN 8;
		"PHAN" O -1;
		Stop;
	}
}
