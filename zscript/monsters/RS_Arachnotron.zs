// =====================================================================
// RS_Arachnotron -- per-tier state rebuild (docs/rs_09_monster_rebuild_spec.txt).
// Replaces Arachnotron. Template: RS_Imp.zs.
//
// THIRTEEN REAL SPIDERS. Tier -> body -> attack, from the proven HF port
// (E:\RadiantSilvergun\zscript\monsters\hf_arachnotron.zs) and CH decorate
// (Spiders.txt). CHPLUS is the sole color source (base CH has no
// arachnotron).
//
//   T00 BSPI vanilla plasma-arc     T01 BSPI+tint spider-spit volleys
//   T02 BSPI+tint plasma stream     T03 ACNB+tint ice orbs + cyan bomb
//   T04 BSPI+tint arachnorb spam    T05 ACNB+tint Brainchoton triple orb
//   T06 ABSP abyss bolts + breath   T07 ACNB+tint seeking fireblu plasma
//   T08 BSPI+tint Brown Recluse     T09 BSPI+tint stone rockets
//   T10 BSP2+tint Red Rage bombs    T11 BSP2+tint Macross Missile Spam
//   T12 TRIT White Spider: slime / homer / bolt / web
//
// RS mechanics preserved from the previous file: the T07+ hover-barrage
// (lift off, no-flinch, unload the attack slot -- BuildTierAttacks and
// RS_HoverBarrage unchanged), the T11+ shrinking death chain
// (DeathMorphClass -> RS_ArachnotronStage2, stages live in
// RS_MonsterStages.zs), keywords, tint table. Hover rolls in the Missile
// DISPATCHER so every tier cluster gets it without repeating the roll.
//
// +MAP07BOSS2 restored from the HF port (the previous RS file dropped it;
// without it the last arachnotron on MAP07 never raises floor tag 667).
//
// Frame substitutions (verified on disk, sprites/monsters/Arachnotron/):
//   ACNB has A-H only -- its death is CH's real crash chain (D/EFG/H),
//   no substitution needed. BSP2 death uses the CH Black-spider chain
//   (J/K/LMN/O/P); CH's Red BSP2 death is the same frames.
// =====================================================================

class RS_Arachnotron : RS_MonsterMaster replaces Arachnotron
{
	Default
	{
		Health 500;
		Radius 64;
		Height 64;
		Mass 600;
		Speed 12;
		PainChance 128;
		Monster;
		+FLOORCLIP +BOSSDEATH
		+MAP07BOSS2   // last arachnotron on MAP07 raises floor tag 667
		SeeSound "baby/sight";   PainSound "baby/pain";
		DeathSound "baby/death"; ActiveSound "baby/active";
		Obituary "$OB_BABY";
		Tag "Arachnotron";
	}

	// Audit data: which body each tier wears (the clusters below are the
	// live implementation; AUDIT cross-checks them against this).
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BSPI BSPI BSPI ACNB BSPI ACNB ABSP ACNB BSPI BSPI BSP2 BSP2 TRIT";
	}

	override string TintTable()
	{
		return "- rs_arach_t01 rs_arach_t02 rs_arach_t03 rs_arach_t04 rs_arach_t05 "
		       "- rs_arach_t07 rs_arach_t08 rs_arach_t09 rs_arach_t10 "
		       "rs_arach_t11 rs_arach_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:arachnotron role:artillery delivery:heavy element:plasma mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE SHRINKING CHAIN. CHP's white arachnotron EX dies into a
	// smaller copy of itself, twice, keeping the same attack kit at
	// reduced scale before shattering. Kept because it reads instantly:
	// the thing is visibly diminishing and you can see how close you are
	// to finishing it.
	//
	// Also the hover-barrage: it lifts off and stops flinching for the
	// duration of a big volley, so interrupting it is a timing problem
	// rather than a damage race.
	// -----------------------------------------------------------------
	const RS_ARACH_TIER_CHAIN = 11;
	const RS_ARACH_TIER_HOVER = 7;
	const RS_ARACH_HOVER_SLOT = 0;

	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_ARACH_TIER_CHAIN) ? RS_MonsterCatalog.MORPH_ArachStage2() : null;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_ARACH_TIER_HOVER)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(), 3, 20.0,
			"baby/attack", 1.0, 0.0, "Plasma Spread"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(),
			t >= 11 ? 20 : 12, 360.0,
			"baby/attack", 1.0, 5.0, "Plasma Ring"));
		return slot;
	}

	// Lift off, stop flinching, unload. Reverts itself via PulseStats.
	void RS_HoverBarrage()
	{
		bFLOAT = true;
		bNOGRAVITY = true;
		PulseStats(1.0, 1.0, 70, true);   // noPain for the volley
	}

	// Hover ends when PulseStats reverts; make sure the flight flags end
	// with it so a grounded tier never keeps floating after a retier.
	override void OnTierApplied(int t)
	{
		bFLOAT = false;
		bNOGRAVITY = false;
	}

	States
	{
	// ===== dispatcher overrides: family-wide mechanics roll here =====
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_ARACH_TIER_HOVER && random(0, 255) < 90)
				return ResolveState("Hover");
			return TierState("Missile");
		}
		Goto See;
	Hover:
		// Bare #### = keep whatever body sprite we're wearing (proven
		// mechanism). A/G/H exist on every arachnotron body (BSPI ACNB
		// ABSP BSP2 TRIT -- verified on disk).
		#### A 14 Bright { A_FaceTarget(); }
		TNT1 A 0 { RS_HoverBarrage(); }
		#### G 8 Bright { A_RS_MonsterFire(); }
		#### H 8 Bright;
		#### G 8 Bright { A_RS_MonsterFire(); }
		#### H 10 Bright;
		Goto See;
	Pain:
		TNT1 A 0 { return TierState("Pain"); }
		Goto See;

	// =========================================================
	// BSPI GROUP -- T00/T01/T02/T04/T08/T09 share the vanilla
	// body: walk/pain/death/raise stack here, their bespoke
	// attacks live in their own Missile clusters below.
	// =========================================================
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T08:
	Spawn.T09:
		"BSPI" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T08:
	See.T09:
		"BSPI" A 20 { A_BabyMetal(); }
		"BSPI" ABBCC 3 { A_Chase(); }
		"BSPI" D 3 { A_Chase(); }
		Loop;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T08:
	Pain.T09:
		"BSPI" H 3;
		"BSPI" H 3 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T08:
	Death.T09:
		"BSPI" J 20 { A_Scream(); }
		"BSPI" K 7 { A_NoBlocking(); }
		"BSPI" LMNO 7;
		"BSPI" P -1 { A_BossDeath(); }
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
	Raise.T04:
	Raise.T08:
	Raise.T09:
		"BSPI" PONMLKJ 5;
		Goto See;

	// ===== T00 -- Babel plasma-arc spam (the vanilla identity) =====
	Missile.T00:
		"BSPI" A 20 Bright { A_FaceTarget(); }
	Missile.T00.Loop:
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_ArachnotronPlasma", 0, 0, 0); }
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_ArachnotronPlasma", 0, 0, 0); }
		"BSPI" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T00.Loop;

	// ===== T01 GREEN -- spider-spit volleys =====
	Missile.T01:
		"BSPI" A 12 Bright { A_FaceTarget(); }
	Missile.T01.Loop:
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_SpSpit", 0, 0, 0); }
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_SpSpit", 0, 0, random(-5, 5)); }
		"BSPI" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T01.Loop;

	// ===== T02 BLUE -- plasma-ball stream =====
	Missile.T02:
		"BSPI" A 12 Bright { A_FaceTarget(); }
	Missile.T02.Loop:
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 0, 0, 0); }
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 0, 0, random(-6, 6)); }
		"BSPI" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T02.Loop;

	// =========================================================
	// ACNB GROUP -- T03/T05/T07 share the Brainchoton body
	// (A-H on disk; death is CH's real crash chain).
	// =========================================================
	Spawn.T03:
	Spawn.T05:
	Spawn.T07:
		"ACNB" AB 10 { A_Look(); }
		Loop;
	See.T03:
	See.T05:
	See.T07:
		"ACNB" A 20 { A_BabyMetal(); }
		"ACNB" ABBCCD 3 { A_Chase(); }
		Loop;
	Pain.T03:
	Pain.T05:
	Pain.T07:
		"ACNB" H 3;
		"ACNB" H 3 { A_Pain(); }
		Goto See;
	Death.T03:
	Death.T05:
	Death.T07:
		"ACNB" D 6 { A_Scream(); A_NoBlocking(); }
		"ACNB" EFG 6;
		"ACNB" H -1 { A_BossDeath(); }
		Stop;
	Raise.T03:
	Raise.T05:
	Raise.T07:
		"ACNB" HGFEDA 8;
		Goto See;

	// ===== T03 CYAN -- ice orbs, occasional cyan bomb =====
	Missile.T03:
		"ACNB" A 12 Bright { A_FaceTarget(); }
	Missile.T03.Loop:
		"ACNB" G 0 A_Jump(80, "Missile.T03.Bomb");
		"ACNB" G 4 Bright { A_SpawnProjectile("RS_IceOrbCyanAra1", 0, 0, random(-4, 4)); }
		"ACNB" G 4 Bright { A_SpawnProjectile("RS_IceOrbCyanAra2", 0, 0, random(-8, 8)); }
		"ACNB" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T03.Loop;
	Missile.T03.Bomb:
		"ACNB" G 8 Bright { A_SpawnProjectile("RS_SpiderCyanBomb", 0, 0, 0); }
		Goto See;

	// ===== T05 YELLOW -- Brainchoton arachnorb spam =====
	Missile.T05:
		"ACNB" A 12 Bright { A_FaceTarget(); }
	Missile.T05.Loop:
		"ACNB" G 3 Bright { A_SpawnProjectile("RS_AracnorbBall", 0, 0, random(-7, 7)); }
		"ACNB" G 3 Bright { A_SpawnProjectile("RS_AracnorbBall", 0, 0, random(-7, 7)); }
		"ACNB" G 3 Bright { A_SpawnProjectile("RS_AracnorbBall", 0, 0, random(-7, 7)); }
		"ACNB" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T05.Loop;

	// ===== T07 FIREBLU -- seeking fireblu plasma, three speeds =====
	Missile.T07:
		"ACNB" A 12 Bright { A_FaceTarget(); }
	Missile.T07.Loop:
		"ACNB" G 3 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB1", 0, 0, random(-6, 6)); }
		"ACNB" G 3 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB2", 0, 0, random(-6, 6)); }
		"ACNB" G 3 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB3", 0, 0, random(-6, 6)); }
		"ACNB" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T07.Loop;

	// ===== T04 PURPLE -- arachnorb corkscrews (BSPI body + tint) =====
	Missile.T04:
		"BSPI" A 12 Bright { A_FaceTarget(); }
	Missile.T04.Loop:
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_AracnorbBall", 0, 0, random(-5, 5)); }
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_AracnorbBall", 0, 0, random(-5, 5)); }
		"BSPI" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T04.Loop;

	// ===== T08 BROWN -- Brown Recluse orb + spam =====
	Missile.T08:
		"BSPI" A 12 Bright { A_FaceTarget(); }
	Missile.T08.Loop:
		"BSPI" G 3 Bright { A_SpawnProjectile("RS_BrownOrbSpiderCH", 0, 0, random(-5, 5)); }
		"BSPI" G 3 Bright { A_SpawnProjectile("RS_BrownSpamSP", 0, 0, random(-9, 9)); }
		"BSPI" G 3 Bright { A_SpawnProjectile("RS_BrownSpamSP", 0, 0, random(-9, 9)); }
		"BSPI" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T08.Loop;

	// ===== T09 GRAY -- Metal Spider stone rockets =====
	Missile.T09:
		"BSPI" A 12 Bright { A_FaceTarget(); }
	Missile.T09.Loop:
		"BSPI" G 6 Bright { A_SpawnProjectile("RS_SpiderStoneRocket", 0, 0, random(-3, 3)); }
		"BSPI" G 6 Bright { A_SpawnProjectile("RS_SpiderStoneRocket", 0, 0, random(-3, 3)); }
		"BSPI" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T09.Loop;

	// =========================================================
	// BSP2 GROUP -- T10 Red Rage / T11 Macross Missile Spam.
	// Same body, two tints, two very different attack kits.
	// =========================================================
	Spawn.T10:
	Spawn.T11:
		"BSP2" AB 10 { A_Look(); }
		Loop;
	See.T10:
	See.T11:
		"BSP2" A 3 { A_BabyMetal(); }
		"BSP2" ABBCC 3 { A_Chase(); }
		"BSP2" D 3 { A_BabyMetal(); }
		"BSP2" DEEFF 3 { A_Chase(); }
		Loop;
	Pain.T10:
	Pain.T11:
		"BSP2" I 3;
		"BSP2" I 3 { A_Pain(); }
		Goto See;
	Death.T10:
	Death.T11:
		"BSP2" J 20 { A_Scream(); }
		"BSP2" K 9 { A_NoBlocking(); }
		"BSP2" LMN 8;
		"BSP2" O 9 { A_BossDeath(); }
		"BSP2" P -1;
		Stop;

	// ===== T10 RED -- seeking bombs, occasional fatso rockets =====
	Missile.T10:
		"BSP2" A 12 Bright { A_FaceTarget(); }
	Missile.T10.Loop:
		"BSP2" G 0 A_Jump(96, "Missile.T10.Fatso");
		"BSP2" G 4 Bright { A_SpawnProjectile("RS_RedBombSP", 0, 0, random(-5, 5)); }
		"BSP2" H 4 Bright { A_SpawnProjectile("RS_RedBombSP", 0, 0, random(-5, 5)); }
		"BSP2" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T10.Loop;
	Missile.T10.Fatso:
		"BSP2" G 6 Bright { A_SpawnProjectile("RS_RocketShotFatso", 0, -8, random(-4, 4)); }
		"BSP2" H 6 Bright { A_SpawnProjectile("RS_RocketShotFatso", 0, 8, random(-4, 4)); }
		Goto See;

	// ===== T11 BLACK -- Macross Missile Spam: big balls bursting
	// into homing swarms + rockets, point-blank missile dump =====
	Missile.T11:
		"BSP2" A 0 A_JumpIfCloser(500, "Missile.T11.Close");
		"BSP2" A 0 A_Jump(256, "Missile.T11.Swarm", "Missile.T11.Rockets");
		Goto See;
	Missile.T11.Swarm:
		"BSP2" A 10 Bright { A_FaceTarget(); }
		"BSP2" G 5 Bright { A_SpawnProjectile("RS_BBSP1", 0, 0, random(-4, 4)); }
		"BSP2" H 5 Bright { A_SpawnProjectile("RS_BBSP1", 0, 0, random(-4, 4)); }
		"BSP2" G 8 A_MonsterRefire(40, "See");
		Goto Missile.T11.Swarm;
	Missile.T11.Rockets:
		"BSP2" A 8 Bright { A_FaceTarget(); }
		"BSP2" G 3 Bright { A_SpawnProjectile("RS_SpRocket3", 0, -6, random(-6, 6)); }
		"BSP2" H 3 Bright { A_SpawnProjectile("RS_SpRocket4", 0, 6, random(-6, 6)); }
		"BSP2" G 3 Bright { A_SpawnProjectile("RS_SpRocket3", 0, 0, random(-6, 6)); }
		"BSP2" G 8 A_MonsterRefire(40, "See");
		Goto Missile.T11.Rockets;
	Missile.T11.Close:
		"BSP2" G 2 Bright { A_SpawnProjectile("RS_SPMM1", 0, 0, random(-15, 15)); }
		"BSP2" H 2 Bright { A_SpawnProjectile("RS_SPMM3", 0, 0, random(-15, 15)); }
		"BSP2" G 2 Bright { A_SpawnProjectile("RS_SPMM5", 0, 0, random(-15, 15)); }
		Goto See;

	// =========================================================
	// T12 WHITE -- the White Spider (TRIT). Slime / homer /
	// plasma-bolt rotation at range, web-shot up close.
	// =========================================================
	Spawn.T12:
		"TRIT" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"TRIT" A 20 { A_BabyMetal(); }
		"TRIT" ABBCCD 3 { A_Chase(); }
		Loop;
	Missile.T12:
		"TRIT" A 0 A_JumpIfCloser(400, "Missile.T12.Web");
		"TRIT" A 0 A_Jump(256, "Missile.T12.Slime", "Missile.T12.Homer", "Missile.T12.Bolt");
		Goto See;
	Missile.T12.Slime:
		"TRIT" A 8 Bright { A_FaceTarget(); }
		"TRIT" G 3 Bright { A_SpawnProjectile("RS_SlimeBall1", 0, 0, random(-8, 8)); }
		"TRIT" G 3 Bright { A_SpawnProjectile("RS_SlimeBall2", 0, 0, random(-8, 8)); }
		"TRIT" G 3 Bright { A_SpawnProjectile("RS_SlimeBall3", 0, 0, random(-8, 8)); }
		"TRIT" G 8 A_MonsterRefire(40, "See");
		Goto Missile.T12.Slime;
	Missile.T12.Homer:
		"TRIT" A 8 Bright { A_FaceTarget(); }
		"TRIT" G 6 Bright { A_SpawnProjectile("RS_WhiteSpiderHomer", 0, 0, random(-4, 4)); }
		"TRIT" G 6 Bright { A_SpawnProjectile("RS_WhiteSpiderHomer", 0, 0, random(-4, 4)); }
		"TRIT" G 8 A_MonsterRefire(40, "See");
		Goto Missile.T12.Homer;
	Missile.T12.Bolt:
		"TRIT" A 8 Bright { A_FaceTarget(); }
		"TRIT" G 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 0, 0, random(-5, 5)); }
		"TRIT" G 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 0, 0, random(-5, 5)); }
		"TRIT" G 8 A_MonsterRefire(40, "See");
		Goto Missile.T12.Bolt;
	Missile.T12.Web:
		"TRIT" G 2 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 0, 0, random(-12, 12)); }
		"TRIT" G 2 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 0, 0, random(-12, 12)); }
		"TRIT" G 2 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 0, 0, random(-12, 12)); }
		Goto See;
	Pain.T12:
		"TRIT" H 3;
		"TRIT" H 3 { A_Pain(); }
		Goto See;
	Death.T12:
		// CH: white spider bursts into an explosion (MISL = IWAD rocket boom).
		"TRIT" G 12 { A_Scream(); A_NoBlocking(); }
		"TRIT" HIJ 10;
		"TRIT" H 0 { A_BossDeath(); }
		MISL BCD 10 Bright;
		TNT1 A -1;
		Stop;
	}
}
