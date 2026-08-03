// =====================================================================
// RS_Imp -- the proof family of the per-tier state rebuild
// (docs/rs_09_monster_rebuild_spec.txt). Replaces DoomImp.
//
// THIRTEEN REAL CREATURES, not one imp in thirteen coats. Every tier
// is its own state cluster with literal sprites and Colourful Hell's
// own attack for that color, ported from CH decorate/Imps.txt via the
// proven HF_Imp choreography:
//
//   T00 TROO vanilla imp          T01 TROO+tint  seeker plasma ball
//   T02 TROO+tint fast fireball   T03 CIMP  frost: fan close, balls far
//   T04 TROO+tint triple bounce   T05 TRO4  spitfire + dodge-weave
//   T06 ROAC  tanky abyss volley  T07 TROO+tint red/blu alternator
//   T08 WARI  Warlord: spikes + parry-pull
//   T09 GIMP  nailgunner rings    T10 PRIM  D64 voice, 5-ball burst,
//                                            rages when hurt
//   T11 AGUR  Smoking Black Imp: 3-attack rotation + healing smoke
//   T12 HELN  apex: WimpBall storm
//
// RS mechanics preserved from the previous file: the T07+ Imp Master
// pack summon (RS_ImpPack, cap-gated), the T05+ pain warp-skid
// (PhaseDodge), keywords, tint table. Both now live in the Missile /
// Pain DISPATCHER overrides below, so every tier cluster gets them
// without repeating the roll thirteen times.
//
// HONEST OMISSION: CH's Brown imp "Scatter" squad command (radius-
// gives an ACS-driven command item that makes nearby imps disperse)
// is not ported -- it needs a per-imp inventory + ACS chain. The
// Warlord's own combat identity (spike volley, parry-pull, heavy
// melee) is complete.
// =====================================================================

class RS_Imp : RS_MonsterMaster replaces DoomImp
{
	Default
	{
		Health 60;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "imp/sight";   PainSound "imp/pain";
		DeathSound "imp/death"; ActiveSound "imp/active";
		HitObituary "$OB_IMPHIT";
		Obituary "$OB_IMP";
		Tag "Imp";
	}

	// Audit data: which body each tier wears (the clusters below are
	// the live implementation; AUDIT cross-checks them against this).
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "TROO TROO TROO CIMP TROO TRO4 ROAC TROO WARI GIMP PRIM AGUR HELN";
	}

	override string TintTable()
	{
		return "- rs_imp_t01 rs_imp_t02 rs_imp_t03 rs_imp_t04 rs_imp_t05 "
		       "- rs_imp_t07 - rs_imp_t09 - - rs_imp_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:imp role:fodder delivery:melee delivery:heavy element:thermal mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE IMP MASTER. CHP's white imp dumps a whole pack at once rather
	// than trickling them. Scaled by tier so it stays a shock and not a
	// slideshow. Rolled in the Missile dispatcher.
	// -----------------------------------------------------------------
	const RS_IMP_TIER_PACK = 7;
	const RS_IMP_TIER_WARP = 5;

	override bool MinionsDieWithMe() { return false; }

	void RS_ImpPack()
	{
		if (Tier < RS_IMP_TIER_PACK)
			return;
		int n   = (Tier >= 11) ? 4 : 2;
		int cap = (Tier >= 11) ? 7 : 4;
		if (SummonPack("RS_Imp", n, cap, -4, 104.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	// Per-tier voice: Red wears Doom 64's imp voice, Black wears
	// Agaures. Everyone else keeps the stock imp -- the tint does the
	// talking. (Sound fields are safe to set from any context.)
	override void OnTierApplied(int t)
	{
		if (t == 10)
		{
			SeeSound = "imp2/see";      PainSound = "imp2/hurt";
			DeathSound = "imp2/die";    ActiveSound = "imp2/active";
		}
		else if (t == 11)
		{
			SeeSound = "agaures/sight"; PainSound = "agaures/pain";
			DeathSound = "agaures/death"; ActiveSound = "agaures/active";
		}
		else
		{
			SeeSound = "imp/sight";     PainSound = "imp/pain";
			DeathSound = "imp/death";   ActiveSound = "imp/active";
		}
	}

	States
	{
	// ===== dispatcher overrides: family-wide mechanics roll here =====
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_IMP_TIER_PACK && random(0, 255) < 44)
				return ResolveState("SummonPack");
			return TierState("Missile");
		}
		Goto See;
	SummonPack:
		// Bare #### = keep whatever body sprite we're wearing (proven
		// mechanism -- quoted "####" is the broken form). E/F exist on
		// every imp body.
		#### E 10 { A_FaceTarget(); }
		#### F 14 Bright { RS_ImpPack(); }
		Goto See;
	Pain:
		TNT1 A 0
		{
			if (Tier >= RS_IMP_TIER_WARP && random(0, 255) < 64)
				PhaseDodge(24, 5.0, 0.45);
			return TierState("Pain");
		}
		Goto See;

	// =========================================================
	// T00 -- vanilla imp (CH CommonImp is literally this).
	// T01/T02/T04/T07 share the TROO body: walk/pain/death stack
	// here, their bespoke attacks live in their own Missile.
	// =========================================================
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T07:
		"TROO" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T07:
		"TROO" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T00:
	Missile.T00:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_TroopAttack(); }
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T07:
		"TROO" H 2;
		"TROO" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T07:
		"TROO" I 8;
		"TROO" J 8 { A_Scream(); }
		"TROO" K 6;
		"TROO" L 6 { A_NoBlocking(); }
		"TROO" M -1;
		Stop;
	XDeath.T00:
	XDeath.T01:
	XDeath.T02:
	XDeath.T04:
	XDeath.T05:
	XDeath.T06:
	XDeath.T07:
		"TROO" N 5;
		"TROO" O 5 { A_XScream(); }
		"TROO" P 5;
		"TROO" Q 5 { A_NoBlocking(); }
		"TROO" RST 5;
		"TROO" U -1;
		Stop;
	Raise.T00:
		"TROO" MLKJI 8;
		Goto See;

	// ===== T01 GREEN -- seeking plasma ball =====
	Melee.T01:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_CustomMeleeAttack(random(6, 16), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T01:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_SpawnProjectile("RS_GreenIBall", 42, 3); }
		Goto See;

	// ===== T02 BLUE -- fast straight fireball =====
	Melee.T02:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_CustomMeleeAttack(random(6, 18), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T02:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_SpawnProjectile("RS_BluFier1", 42, 3, random(-1, 1)); }
		Goto See;

	// ===== T03 CYAN -- frost imp (CIMP). Far: ball burst. Close: fan =====
	Spawn.T03:
		"CIMP" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"CIMP" CCDD 3 { A_Chase(); }
		"CIMP" AABB 3 { A_Chase(); }
		Loop;
	Melee.T03:
		"CIMP" EF 8 { A_FaceTarget(); }
		"CIMP" G 6 { A_CustomMeleeAttack(random(10, 38), "imp/melee", "", "Ice"); }
		Goto See;
	Missile.T03:
		"CIMP" E 3 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(600, "Missile.T03.Frost");
		"CIMP" EF 3 { A_FaceTarget(); }
		"CIMP" G 3;
		"CIMP" G 0 { A_SpawnProjectile("RS_CyanImpBall", 32, 12, 0); }
		"CIMP" EF 3 { A_FaceTarget(); }
		"CIMP" G 2 A_Jump(128, "Missile.T03.AltSpin");
		"CIMP" G 0 { A_SpawnProjectile("RS_CyanImpBall", 32, 12, random(1, 15)); }
		Goto See;
	Missile.T03.AltSpin:
		"CIMP" G 0 { A_SpawnProjectile("RS_CyanImpBall", 32, 12, random(-15, -1)); }
		Goto See;
	Missile.T03.Frost:
		"CIMP" E 4 { A_FaceTarget(); }
		"CIMP" F 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 10); }
		"CIMP" F 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 8); }
		"CIMP" F 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 6); }
		"CIMP" F 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 4); }
		"CIMP" F 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 2); }
		"CIMP" G 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 0); }
		"CIMP" G 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -2); }
		"CIMP" G 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -4); }
		"CIMP" G 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -6); }
		"CIMP" G 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -8); }
		"CIMP" G 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -10); }
		"CIMP" FE 4 { A_FaceTarget(); }
		Goto See;
	Pain.T03:
		"CIMP" H 2;
		"CIMP" H 2 { A_Pain(); }
		Goto See;
	Death.T03:
		// CH: the frost imp's corpse shatters (A_IceGuyDie).
		"CIMP" N 5 { A_NoBlocking(); }
		"CIMP" O 5 { A_XScream(); }
		"CIMP" P 5 { A_IceGuyDie(); }
		Stop;

	// ===== T04 PURPLE -- triple bouncing fireball =====
	Melee.T04:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_CustomMeleeAttack(random(8, 20), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T04:
		"TROO" EF 7 { A_FaceTarget(); }
		"TROO" G 7 { A_SpawnProjectile("RS_Bounc11", 42, 3, random(-1, 1)); }
		"TROO" G 7 { A_SpawnProjectile("RS_Bounc11", 42, 3, random(-9, 9)); }
		"TROO" GG 2 Bright { A_SpawnProjectile("RS_Bounc11", 42, 3, random(-13, 13)); }
		Goto See;

	// ===== T05 YELLOW -- TRO4 spitfire, dodge-weaves while chasing =====
	Spawn.T05:
		"TRO4" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"TRO4" AABB 3 { A_Chase(); }
		"TRO4" CCDD 3 { A_Chase(); }
		TNT1 A 0 A_Jump(34, "Dodge.T05");
		Loop;
	Dodge.T05:
		"TRO4" AABB 3 { A_FastChase(); }
		"TRO4" CCDD 3 { A_FastChase(); }
		Goto See;
	Melee.T05:
		"TRO4" EF 8 { A_FaceTarget(); }
		"TRO4" G 6 { A_CustomMeleeAttack(random(10, 32), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T05:
		"TRO4" EF 8 { A_FaceTarget(); }
		"TRO4" G 6 { A_SpawnProjectile("RS_SpitFireImp", 42, 3, random(-1, 1)); }
		Goto See;
	Pain.T05:
		"TRO4" H 2;
		"TRO4" H 2 { A_Pain(); }
		Goto See;
	Death.T05:
		"TRO4" I 8;
		"TRO4" J 8 { A_Scream(); }
		"TRO4" K 6;
		"TRO4" L 6 { A_NoBlocking(); }
		"TRO4" M -1;
		Stop;

	// ===== T06 ABYSS -- tanky ROAC, double volley, splash melee =====
	Spawn.T06:
		"ROAC" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"ROAC" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T06:
		"ROAC" EF 8 { A_FaceTarget(); }
		"ROAC" G 5 { A_CustomMeleeAttack(random(16, 42), "imp/melee", "imp/melee"); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		Goto See;
	Missile.T06:
		"ROAC" EF 8 { A_FaceTarget(); }
		"ROAC" G 6 { A_SpawnProjectile("RS_AbyssBallCH", 42, 3, random(-1, 1)); }
		"ROAC" EF 4 { A_FaceTarget(); }
		"ROAC" GG 1 { A_SpawnProjectile("RS_AbyssBallCH", 42, 3, random(-9, 9)); }
		Goto See;
	Pain.T06:
		"ROAC" H 2;
		"ROAC" H 2 { A_Pain(); }
		Goto See;
	Death.T06:
		"ROAC" I 8;
		"ROAC" J 8 { A_Scream(); }
		"ROAC" K 6;
		"ROAC" L 6 { A_NoBlocking(); }
		"ROAC" M -1;
		Stop;

	// ===== T07 FIREBLU -- alternates red/blu, stops if LOS breaks =====
	Melee.T07:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_CustomMeleeAttack(random(10, 29), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T07:
		"TROO" EF 7 { A_FaceTarget(); }
		"TROO" G 7 { A_SpawnProjectile("RS_RedBBall", 42, 3, random(-5, 1)); }
		"TROO" G 0 A_CheckSight("See.T07");
		"TROO" EF 7 { A_FaceTarget(); }
		"TROO" G 7 { A_SpawnProjectile("RS_BluBBall", 42, 3, random(-1, 5)); }
		Goto See;

	// ===== T08 BROWN -- the Warlord (WARI): spikes, parry-pull =====
	Spawn.T08:
		"WARI" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"WARI" AABB 3 { A_Chase(); }
		TNT1 A 0 A_Jump(32, "Parry.T08.Check");
		"WARI" CCDD 3 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "Parry.T08.Check");
		Loop;
	Parry.T08.Check:
		TNT1 A 0 A_JumpIfInTargetLOS("Parry.T08", 0, JLOSF_DEADNOJUMP, 1200, 200);
		Goto See.T08;
	Parry.T08:
		// The pull: negative radius thrust yanks the attacker IN --
		// the Warlord answers ranged fire by dragging you to melee.
		"WARI" II 3 { A_FaceTarget(); }
		"WARI" JJ 3 { A_FaceTarget(); }
		"WARI" K 1 { A_FaceTarget(); }
		"WARI" K 12 { A_RadiusThrust(-420, 252, RTF_NOIMPACTDAMAGE | RTF_THRUSTZ | RTF_NOTMISSILE, 128); }
		"WARI" K 12;
		"WARI" JJII 3;
		Goto See;
	Melee.T08:
		"WARI" E 6 { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"WARI" F 4 { A_FaceTarget(); }
		"WARI" G 5 { A_CustomMeleeAttack(random(1, 8) * 7, "skeleton/melee", ""); }
		Goto See;
	Missile.T08:
		"WARI" A 1 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(32, "Parry.T08.Check");
		"WARI" A 1 { A_FaceTarget(); }
		"WARI" E 3;
		"WARI" L 6 Bright { A_FaceTarget(); }
		"WARI" M 3 Bright;
		"WARI" N 0 { A_SpawnItemEx("RS_FatsoSpikes2", 12, 8, 28, random(20, 45), 0, random(-1, 2), frandom(-5, -2)); }
		"WARI" N 0 { A_SpawnItemEx("RS_FatsoSpikes2", 12, 8, 28, random(20, 45), 0, random(-1, 2), frandom(-1, 1)); }
		"WARI" N 0 { A_SpawnProjectile("RS_FatsoSpikes2", 32, 12, 0); }
		"WARI" N 3 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 8, 28, random(20, 45), 0, random(-1, 2), frandom(2, 5)); }
		"WARI" G 3;
		Goto See;
	Pain.T08:
		"WARI" H 4 { A_Pain(); }
		"WARI" H 4 A_Jump(64, "Parry.T08");
		Goto See;
	Death.T08:
		"WARI" R 8;
		"WARI" S 8 { A_Scream(); }
		"WARI" T 6;
		"WARI" U 6 { A_NoBlocking(); }
		"WARI" V -1;
		Stop;
	XDeath.T08:
		"TROO" N 5;
		"TROO" O 5 { A_XScream(); }
		"TROO" P 5;
		"TROO" Q 5 { A_NoBlocking(); }
		"TROO" RST 5;
		"TROO" U -1;
		Stop;
	Raise.T08:
		"WARI" VU 8;
		"WARI" TSR 6;
		Goto See;

	// ===== T09 GRAY -- nailgunner (GIMP), all-round nail rings =====
	Spawn.T09:
		"GIMP" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"GIMP" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T09:
		"GIMP" EF 8 { A_FaceTarget(); }
		"GIMP" G 6 { A_CustomMeleeAttack(random(10, 26), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T09:
		"GIMP" EF 8 { A_FaceTarget(); }
		"GIMP" G 6;
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 0); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 45); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 135); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 225); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 315); }
		"GIMP" EF 6 { A_FaceTarget(); }
		"GIMP" G 5;
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 15); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 75); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 105); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 165); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 195); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 255); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 285); }
		"GIMP" D 0 { A_SpawnProjectile("RS_CGNail", 32, 0, 345); }
		Goto See;
	Pain.T09:
		"GIMP" H 2;
		"GIMP" H 2 { A_Pain(); }
		Goto See;
	Death.T09:
		// CH referenced GIMP P here, a frame that does not exist in the
		// sprite set (verified on disk) -- K substitutes.
		"GIMP" I 5;
		"GIMP" J 5 { A_XScream(); }
		"GIMP" K 5;
		"GIMP" L 2 { A_NoBlocking(); }
		TNT1 AAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_PuffCybieRed", 0, 0, 2, random(3, 9), 0, random(1, 15), random(0, 359)); }
		"TROO" RSTU 5;
		"TROO" U -1;
		Stop;

	// ===== T10 RED -- PRIM, D64 voice, 5-ball burst, rages =====
	Spawn.T10:
		"PRIM" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"PRIM" AABB 3 { A_Chase(); }
		"PRIM" CCDD 3 { A_Chase(); }
		Loop;
	Melee.T10:
		"PRIM" EF 8 { A_FaceTarget(); }
		"PRIM" G 6 { A_CustomMeleeAttack(random(10, 38), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T10:
		"PRIM" EF 4 { A_FaceTarget(); }
		"PRIM" G 3;
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 32, 12, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 32, 4, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 32, 20, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 22, 12, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 42, 12, 0); }
		Goto See;
	Pain.T10:
		// Gets ANGRIER when hurt: permanent aggression flag + a burst
		// of speed. (Speed renormalizes on the next retier -- fine.)
		"PRIM" H 3 { A_Pain(); }
		"PRIM" H 3 { bMISSILEEVENMORE = true; }
		"PRIM" H 2 { A_StartSound("imp/pain", CHAN_VOICE); }
		"PRIM" H 2 { A_SetSpeed(14); }
		Goto See;
	Death.T10:
		"PRIM" N 5 { A_SpawnProjectile("RS_HKRedDeath", 32, 0); }
		"PRIM" O 5 { A_XScream(); }
		"PRIM" P 5;
		"PRIM" Q 5 { A_NoBlocking(); }
		"PRIM" RST 5;
		"PRIM" U -1;
		Stop;
	XDeath.T10:
		"PRIM" N 5 { A_SpawnProjectile("RS_HKRedDeath", 32, 0); }
		"PRIM" O 5 { A_XScream(); }
		"PRIM" P 5;
		"PRIM" Q 5 { A_NoBlocking(); }
		"PRIM" RST 5 { A_SpawnProjectile("RS_HKRedDeath", random(12, 46), random(-15, 15)); }
		"PRIM" U -1;
		Stop;

	// ===== T11 BLACK -- Smoking Black Imp (AGUR), the near-apex =====
	// Trails ally-healing smoke, rotates three attacks: a fan, a spam
	// string, and the DIBigOne artillery with an EffectHK lead-in.
	Spawn.T11:
		"AGUR" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"AGUR" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T11:
		"AGUR" WX 6 { A_FaceTarget(); }
		"AGUR" Y 6 { A_CustomMeleeAttack(random(20, 65), "agaures/swing", ""); }
		"AGUR" Y 0 { A_SpawnItemEx("RS_DeathBreathDI", random(-118, 118), random(-118, 118), random(-6, 32), 0, 0, 0, 0, 128); }
		"AGUR" Y 0 A_Jump(88, "Missile.T11");
		Goto See;
	Missile.T11:
		"AGUR" A 0 { A_SpawnItemEx("RS_DeathBreathDI", random(-88, 88), random(-88, 88), random(-6, 27), 0, 0, 0, 0, 128); }
		"AGUR" A 0 A_Jump(256, "Missile.T11.One", "Missile.T11.Spam", "Missile.T11.Big");
		Goto See;
	Missile.T11.One:
		"AGUR" EF 12 { A_FaceTarget(); }
		"AGUR" G 6 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, 0); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, random(-15, 15)); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, random(-25, 25)); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, random(-15, 15)); }
		"AGUR" G 0 A_Jump(128, "Missile.T11.Spam");
		Goto See;
	Missile.T11.Spam:
		"AGUR" EF 8 { A_FaceTarget(); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, -5); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 0); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 5); }
		"AGUR" G 0 A_CheckSight("See.T11");
		"AGUR" EF 5 { A_FaceTarget(); }
		"AGUR" G 4 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 0); }
		"AGUR" G 0 A_CheckSight("See.T11");
		"AGUR" EF 4 { A_FaceTarget(); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, -10); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 0); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 10); }
		Goto See;
	Missile.T11.Big:
		"AGUR" EF 12 Bright { A_FaceTarget(); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 28, 0); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 32, 0); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 36, 0); }
		"AGUR" G 8 Bright { A_SpawnProjectile("RS_DIBigOne", 38, 0, 0); }
		"AGUR" G 4;
		"AGUR" A 10;
		Goto See;
	Pain.T11:
		"AGUR" H 2;
		"AGUR" H 2 { A_Pain(); }
		Goto See;
	Death.T11:
		"AGUR" I 12;
		"AGUR" J 12 { A_Scream(); }
		"AGUR" KL 12;
		"AGUR" M 12 { A_NoBlocking(); }
		"AGUR" N -1;
		Stop;

	// ===== T12 WHITE -- apex imp (HELN), the WimpBall storm =====
	Spawn.T12:
		"HELN" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"HELN" AABBCC 2 { A_Chase(); }
		"HELN" DDEEFF 2 { A_Chase(); }
		Loop;
	Melee.T12:
		"HELN" GH 6 { A_FaceTarget(); }
		"HELN" I 6 { A_CustomMeleeAttack(random(20, 50), "imp/melee", "imp/melee"); }
		Goto See;
	Missile.T12:
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall1", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 2 Bright { A_SpawnProjectile("RS_WimpBall2", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall3", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 2 Bright { A_SpawnProjectile("RS_WimpBall4", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall5", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 2 Bright { A_SpawnProjectile("RS_WimpBall1", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall2", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 1 Bright { A_SpawnProjectile("RS_WimpBall3", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 2 Bright { A_SpawnProjectile("RS_WimpBall4", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 1 Bright { A_SpawnProjectile("RS_WimpBall5", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 2 { A_FaceTarget(); }
		Goto See;
	Pain.T12:
		"HELN" J 2;
		"HELN" J 2 { A_Pain(); }
		Goto See;
	Death.T12:
		"HELN" N 6;
		"HELN" O 6 { A_Scream(); }
		"HELN" PQR 6;
		"HELN" S 6 { A_NoBlocking(); }
		"HELN" T -1;
		Stop;
	XDeath.T12:
		"HELN" U 5;
		"HELN" V 5 { A_XScream(); }
		"HELN" W 5;
		"HELN" X 5 { A_NoBlocking(); }
		"HELN" YZ 5;
		"HEL2" AB 5;
		"HEL2" C -1;
		Stop;
	}
}
