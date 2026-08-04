// =====================================================================
// RS_MonsterStages -- multi-stage boss bodies and pack minions that
// don't belong to a single family file. Per-tier state architecture
// (docs/rs_09_monster_rebuild_spec.txt).
//
// The shrink chain (Arachnotron) and the Butcher's dogs live here
// rather than padding their parent's file, since both are referenced
// through RS_MonsterCatalog and neither is a "family" in its own right.
//
// SUBSTITUTION: DemonDog T08 was IFN2, a 2-frame effect sprite that
// cannot carry a walker's state set -- HDOG stands in (same call as
// RS_Minions' tendril).
// =====================================================================

// ---------------------------------------------------------------------
// ARACHNOTRON SHRINK CHAIN -- same kit, smaller body, less health each
// time. Stage 3 shatters instead of leaving a corpse.
// ---------------------------------------------------------------------

class RS_ArachnotronStage2 : RS_MonsterMaster
{
	Default
	{
		Health 260;
		Radius 44;
		Height 48;
		Mass 400;
		Speed 15;
		PainChance 140;
		Monster;
		+FLOORCLIP
		Scale 0.72;
		SeeSound "baby/sight";   PainSound "baby/pain";
		DeathSound "baby/death"; ActiveSound "baby/active";
		Obituary "$OB_BABY";
		Tag "Arachnotron (Split)";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BSP2 BSP2 BSP2 ACNB BSP2 ACNB ABSP ACNB BSP2 BSP2 BSP2 BSP2 TRIT";
	}

	override string TintTable()
	{
		return "- rs_arach_t01 rs_arach_t02 rs_arach_t03 rs_arach_t04 rs_arach_t05 "
		       "- rs_arach_t07 rs_arach_t08 rs_arach_t09 rs_arach_t10 "
		       "rs_arach_t11 rs_arach_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:arachnotron role:artillery delivery:heavy element:plasma mobility:ground trait:secondstage";
	}

	override Class<Actor> DeathMorphClass()
	{
		return RS_MonsterCatalog.MORPH_ArachStage3();
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(), 3, 22.0,
			"baby/attack", 1.0, 0.0, "Plasma Spread"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(), 12, 360.0,
			"baby/attack", 1.0, 5.0, "Plasma Ring"));
		return slot;
	}

	States
	{
	// --- BSP2 body: T00 T01 T02 T04 T08 T09 T10 T11 (mini spider) ---
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T08:
	Spawn.T09:
	Spawn.T10:
	Spawn.T11:
		"BSP2" AB 8 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T08:
	See.T09:
	See.T10:
	See.T11:
		"BSP2" AABBCCDDEEFF 3 { A_BabyMetal(); }
		Loop;
	Missile.T00:
	Missile.T01:
	Missile.T02:
	Missile.T04:
	Missile.T08:
	Missile.T09:
	Missile.T10:
	Missile.T11:
		"BSP2" A 12 Bright { A_FaceTarget(); }
		"BSP2" G 8 Bright { A_RS_MonsterFire(); }
		"BSP2" H 8 Bright;
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T08:
	Pain.T09:
	Pain.T10:
	Pain.T11:
		"BSP2" I 3;
		"BSP2" I 3 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T08:
	Death.T09:
	Death.T10:
	Death.T11:
		"BSP2" J 12 { A_Scream(); }
		"BSP2" K 6 { A_NoBlocking(); }
		"BSP2" LMNO 6;
		"BSP2" P -1;
		Stop;

	// --- ACNB body: T03 T05 T07 (small spider, 8 frames: walk ABCD,
	// lunge EFG, death curls back down the sheet) ---
	Spawn.T03:
	Spawn.T05:
	Spawn.T07:
		"ACNB" AB 8 { A_Look(); }
		Loop;
	See.T03:
	See.T05:
	See.T07:
		"ACNB" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T03:
	Missile.T05:
	Missile.T07:
		"ACNB" E 10 Bright { A_FaceTarget(); }
		"ACNB" F 8 Bright { A_RS_MonsterFire(); }
		"ACNB" G 8 Bright;
		Goto See;
	Pain.T03:
	Pain.T05:
	Pain.T07:
		"ACNB" A 3;
		"ACNB" A 3 { A_Pain(); }
		Goto See;
	Death.T03:
	Death.T05:
	Death.T07:
		"ACNB" H 8 { A_Scream(); }
		"ACNB" G 6 { A_NoBlocking(); }
		"ACNB" FEDA 5;
		"ACNB" A -1;
		Stop;

	// --- ABSP body: T06 (abyss eye-spider, 10 frames) ---
	Spawn.T06:
		"ABSP" AB 8 { A_Look(); }
		Loop;
	See.T06:
		"ABSP" ABCDDDCB 3 { A_Chase(); }
		Loop;
	Missile.T06:
		"ABSP" E 10 Bright { A_FaceTarget(); }
		"ABSP" F 8 Bright { A_RS_MonsterFire(); }
		"ABSP" G 8 Bright;
		Goto See;
	Pain.T06:
		"ABSP" H 3;
		"ABSP" H 3 { A_Pain(); }
		Goto See;
	Death.T06:
		"ABSP" I 8 { A_Scream(); }
		"ABSP" J 8 { A_NoBlocking(); }
		"ABSP" J -1;
		Stop;

	// --- TRIT body: T12 (trite, 11 frames) ---
	Spawn.T12:
		"TRIT" AB 8 { A_Look(); }
		Loop;
	See.T12:
		"TRIT" AABBCC 3 { A_Chase(); }
		Loop;
	Missile.T12:
		"TRIT" D 10 Bright { A_FaceTarget(); }
		"TRIT" E 8 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T12:
		"TRIT" F 3;
		"TRIT" F 3 { A_Pain(); }
		Goto See;
	Death.T12:
		"TRIT" G 8 { A_Scream(); }
		"TRIT" H 6 { A_NoBlocking(); }
		"TRIT" IJ 6;
		"TRIT" K -1;
		Stop;
	}
}

// Final stage. Small, fast, and it bursts rather than falling over.
// Inherits every tier cluster from Stage2; only the death differs --
// the ENTRY-label override below fires for every tier, keeps whatever
// body the tier dressed us in (bare ####, frame A exists on all four
// bodies), and shatters.
class RS_ArachnotronStage3 : RS_ArachnotronStage2
{
	Default
	{
		Health 120;
		Radius 30;
		Height 36;
		Speed 18;
		Scale 0.5;
		Tag "Arachnotron (Remnant)";
	}

	// End of the chain -- nothing follows it.
	override Class<Actor> DeathMorphClass() { return null; }

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(), 2, 16.0,
			"baby/attack", 1.0, 0.0, "Last Shots"));
		return slot;
	}

	States
	{
	Death:
		#### A 8 { A_Scream(); }
		// Shatters instead of leaving a corpse -- the visual full stop
		// on the chain.
		#### A 6 { A_NoBlocking(); A_Burst("RS_ArachShard"); }
		Stop;
	}
}

// The shards it bursts into. Cosmetic, brief, no damage.
class RS_ArachShard : Actor
{
	Default
	{
		Radius 4;
		Height 4;
		Speed 0;
		Mass 5;
		Scale 0.4;
		+MISSILE
		+NOBLOCKMAP
		+DROPOFF
		+THRUACTORS
		+CLIENTSIDEONLY
		RenderStyle "Add";
		Alpha 0.9;
	}
	States
	{
	Spawn:
		APLS AB 4 Bright;
		Loop;
	Death:
		APBX ABCDE 3 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// THE BUTCHER'S DOGS -- fast, fragile melee harassers. The reward for
// beating on a high-tier demon is three of these arriving.
// ---------------------------------------------------------------------

class RS_DemonDog : RS_MonsterMaster
{
	Default
	{
		Health 90;
		Radius 20;
		Height 40;
		Mass 150;
		Speed 18;
		PainChance 180;
		Monster;
		+FLOORCLIP
		SeeSound "demon/sight";   PainSound "demon/pain";
		DeathSound "demon/death"; ActiveSound "demon/active";
		AttackSound "demon/melee";
		Obituary "$OB_DEMON";
		Tag "Hellhound";
		Scale 0.7;
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "HDOG HDOG HDOG WORM HDOG SRG2 HDOG HDOG HDOG WORM SRG2 BCHR JUGG";
	}

	override string TintTable()
	{
		return "- rs_demon_t01 rs_demon_t02 rs_demon_t03 rs_demon_t04 rs_demon_t05 "
		       "rs_demon_t06 rs_demon_t07 rs_demon_t08 rs_demon_t09 rs_demon_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:hellhound role:skirmisher delivery:melee element:kinetic mobility:ground trait:summoned";
	}

	States
	{
	// --- HDOG body: T00 T01 T02 T04 T06 T07 T08 (T08 = IFN2 sub) ---
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T06:
	Spawn.T07:
	Spawn.T08:
		"HDOG" AB 8 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T06:
	See.T07:
	See.T08:
		"HDOG" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T00:
	Melee.T01:
	Melee.T02:
	Melee.T04:
	Melee.T06:
	Melee.T07:
	Melee.T08:
		"HDOG" EF 6 { A_FaceTarget(); }
		"HDOG" G 6 { A_SargAttack(); }
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T06:
	Pain.T07:
	Pain.T08:
		"HDOG" H 2;
		"HDOG" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T06:
	Death.T07:
	Death.T08:
		"HDOG" I 6;
		"HDOG" J 6 { A_Scream(); }
		"HDOG" K 4;
		"HDOG" L 4 { A_NoBlocking(); }
		"HDOG" MN 4;
		Stop;

	// --- WORM body: T03 T09 ---
	Spawn.T03:
	Spawn.T09:
		"WORM" AB 8 { A_Look(); }
		Loop;
	See.T03:
	See.T09:
		"WORM" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T03:
	Melee.T09:
		"WORM" EF 6 { A_FaceTarget(); }
		"WORM" G 6 { A_SargAttack(); }
		Goto See;
	Pain.T03:
	Pain.T09:
		"WORM" H 2;
		"WORM" H 2 { A_Pain(); }
		Goto See;
	Death.T03:
	Death.T09:
		"WORM" I 6;
		"WORM" J 6 { A_Scream(); }
		"WORM" K 4;
		"WORM" L 4 { A_NoBlocking(); }
		"WORM" MN 4;
		Stop;

	// --- SRG2 body: T05 T10 ---
	Spawn.T05:
	Spawn.T10:
		"SRG2" AB 8 { A_Look(); }
		Loop;
	See.T05:
	See.T10:
		"SRG2" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T05:
	Melee.T10:
		"SRG2" EF 6 { A_FaceTarget(); }
		"SRG2" G 6 { A_SargAttack(); }
		Goto See;
	Pain.T05:
	Pain.T10:
		"SRG2" H 2;
		"SRG2" H 2 { A_Pain(); }
		Goto See;
	Death.T05:
	Death.T10:
		"SRG2" I 6;
		"SRG2" J 6 { A_Scream(); }
		"SRG2" K 4;
		"SRG2" L 4 { A_NoBlocking(); }
		"SRG2" MN 4;
		Stop;

	// --- BCHR body: T11 ---
	Spawn.T11:
		"BCHR" AB 8 { A_Look(); }
		Loop;
	See.T11:
		"BCHR" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T11:
		"BCHR" EF 6 { A_FaceTarget(); }
		"BCHR" G 6 { A_SargAttack(); }
		Goto See;
	Pain.T11:
		"BCHR" H 2;
		"BCHR" H 2 { A_Pain(); }
		Goto See;
	Death.T11:
		"BCHR" I 6;
		"BCHR" J 6 { A_Scream(); }
		"BCHR" K 4;
		"BCHR" L 4 { A_NoBlocking(); }
		"BCHR" MN 4;
		Stop;

	// --- JUGG body: T12 ---
	Spawn.T12:
		"JUGG" AB 8 { A_Look(); }
		Loop;
	See.T12:
		"JUGG" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T12:
		"JUGG" EF 6 { A_FaceTarget(); }
		"JUGG" G 6 { A_SargAttack(); }
		Goto See;
	Pain.T12:
		"JUGG" H 2;
		"JUGG" H 2 { A_Pain(); }
		Goto See;
	Death.T12:
		"JUGG" I 6;
		"JUGG" J 6 { A_Scream(); }
		"JUGG" K 4;
		"JUGG" L 4 { A_NoBlocking(); }
		"JUGG" MN 4;
		Stop;
	}
}

// ---------------------------------------------------------------------
// RS_ArchvilePhantomEX -- CHP 14_KX's CommonBlackArchEX3, "Void Strikes
// back". The TEX tornado vile's Death spawns THREE of these, and they
// are the real second half of that fight.
//
// The body is invisible (TNT1): what you see is the cloud trail it
// sheds constantly. Every See entry re-rolls its speed (10-40), its
// scale (0.77-1.23) and its VoidMode, so no two of the three phantoms
// in the arena move or fight alike.
//
//   VoidMode 0  Shadowing  -- shadow-wave barrage, wide or tight
//   VoidMode 1  BlackHole  -- a singularity that drags you into it
//   VoidMode 2  KABAM      -- the seeking mind-wave
//   VoidMode 3  Shockwave  -- twelve floor-hugging waves at once
//
// On top of that it counts EYES (CHP's user_myeyes: +1 per pain, +1 per
// summon). At exactly 8 it stops to call a revenant squad; at 14 it
// blacks your screen out and resets the counter. Burning it down fast
// is what drives that counter -- the punish scales with your damage.
//
// A stage body, not a ladder entry: every tier label stacks onto one
// cluster, the same shape RS_BaronFallen uses.
// ---------------------------------------------------------------------

// ---------------------------------------------------------------------
// RS_ArchvileCloneMOT -- CHP 14_WX's CommonWhiteArchEX3, the copy the
// Master of Time throws. 500 HP instead of 20800 and deliberately
// declawed: no CloneofTime (a clone cannot clone), no ENDOFTIME, no
// TIMESUP, and its close pool drops StealofTime. What is left is the
// three cheap casts, so a room full of clones is a pressure problem
// rather than fifteen countdowns running at once.
//
// Kept as a stage body rather than a tier: it is spawned, never rolled.
// ---------------------------------------------------------------------

class RS_ArchvileCloneMOT : RS_MonsterMaster
{
	private int rsHohoMOT;

	Default
	{
		Health 500;
		Radius 20;
		Height 56;
		Mass 10;
		Speed 60;
		PainChance 10;
		Monster;
		+FLOAT +NOCLIP +QUICKTORETALIATE +NOTARGET +VISIBILITYPULSE
		+DONTHARMSPECIES +DONTHARMCLASS +THRUSPECIES +MTHRUSPECIES
		+DONTDRAIN +LOOKALLAROUND +CANTSEEK +SEEINVISIBLE +NOTIMEFREEZE
		+NOINFIGHTING +DONTMORPH +NOFEAR +DONTTHRUST +AVOIDMELEE
		-NORADIUSDMG -NOGRAVITY
		Species "MasterofTime";
		BloodColor "Black";
		RenderStyle "Add";
		YScale 1.1;
		SeeSound "WVEXSIGT";   PainSound "WVEXPAIN";
		DeathSound "wizard/death"; ActiveSound "WVEXACTV";
		Obituary "$OB_VILE";
		Tag "Echo of the Master of Time";
	}

	override string BodyTable()
	{
		return "LMWX LMWX LMWX LMWX LMWX LMWX LMWX LMWX LMWX LMWX LMWX LMWX LMWX LMWX";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:archvile role:artillery delivery:radial element:void "
		       "mobility:flying trait:summoned trait:ex";
	}

	States
	{
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T03:
	Spawn.T04:
	Spawn.T05:
	Spawn.T06:
	Spawn.T07:
	Spawn.T08:
	Spawn.T09:
	Spawn.T10:
	Spawn.T11:
	Spawn.T12:
	Spawn.TEX:
		"LMWX" E 0
		{
			A_SetSize(20, 80, true);
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
		"LMWX" E 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T03:
	See.T04:
	See.T05:
	See.T06:
	See.T07:
	See.T08:
	See.T09:
	See.T10:
	See.T11:
	See.T12:
	See.TEX:
		"LMWX" E 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWX" EE 6 { A_Chase(); }
		"LMWX" E 4 { A_FastChase(); }
		"LMWX" E 1 { A_Stop(); }
		"LMWX" EE 6 { A_Chase(); }
		Loop;
	Missile.T00:
	Missile.T01:
	Missile.T02:
	Missile.T03:
	Missile.T04:
	Missile.T05:
	Missile.T06:
	Missile.T07:
	Missile.T08:
	Missile.T09:
	Missile.T10:
	Missile.T11:
	Missile.T12:
	Missile.TEX:
		"LMWX" A 0
		{
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SetTranslucent(1, 1);
		}
		"LMWX" E 0 { if (rsHohoMOT >= 1) return ResolveState("Missile.T00.EyeBoom"); return ResolveState(null); }
	Missile.T00.Choices:
		"LMWX" A 0 A_JumpIfCloser(1000, "Missile.T00.Choices2", true);
		"LMWX" A 0 A_Jump(256, "Missile.T00.Choices1");
		Goto See;
	Missile.T00.Choices1:
		"LMWX" A 0 A_Jump(256, "Missile.T00.Scream", "Missile.T00.Rail");
		Goto See;
	Missile.T00.Choices2:
		"LMWX" A 0 A_Jump(256, "Missile.T00.Bolts", "Missile.T00.Rings", "Missile.T00.Eye");
		Goto See;
	Missile.T00.Bolts:
		"LMWX" EFG 8 Bright { A_FaceTarget(); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, 6); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, 0); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, -6); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, -12); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, 12); }
		"LMWX" HG 10;
		"LMWX" E 0 A_Jump(128, "Missile.T00.Choices");
		Goto See;
	Missile.T00.Scream:
		"LMWX" A 0
		{
			A_SetTranslucent(1, 1);
			bNOPAIN = true;
			A_GiveInventory("RS_WVileResist", 1);
		}
		"LMWX" Q 8 { A_FaceTarget(); }
		"LMWX" A 0 { A_StartSound("SPMDING", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" A 0 { A_SpawnItemEx("RS_SuperEye01", 4, 8, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"LMWX" A 0 { A_SpawnItemEx("RS_OldTimeyMOT", 0, 0, 16, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"LMWX" QQ 8 { A_FaceTarget(); }
		"LMWX" A 0 A_CheckSight("See");
		"LMWX" R 14 Bright { A_SpawnItemEx("RS_WVileQuake", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		"LMWX" R 14 Bright { A_StartSound("Wvile/scream", CHAN_7, 0, 1.0, ATTN_NONE); }
		"LMWX" AAAA 0 { A_SpawnItemEx("RS_WhiteVileResser", random(-328, 328), random(-328, 328), 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" S 12 Bright { A_VileTarget("RS_EyeSpawnerMOT"); }
		"LMWX" TU 10 Bright;
		"LMWX" UTSRQ 5 Bright;
		"LMWX" E 0 { bNOPAIN = false; }
		Goto See;
	Missile.T00.Rings:
		"LMWX" A 0 { A_TakeInventory("RS_MOTFreezeToken", 0, 0, AAPTR_TARGET); }
		"LMWX" A 20 Bright { A_StartSound("wizard/sight", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" A 8 Bright { A_Warp(AAPTR_TARGET, -80, 0, 0, random(0, 360), WARPF_NOCHECKPOSITION); }
		"LMWX" A 0 { A_SpawnItemEx("RS_OldTimeyMOT", 0, 0, 16, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"LMWX" A 0 { A_StartSound("TIME02"); }
		"LMWX" A 5 Bright { A_FaceTarget(); }
		"LMWX" AAAA 12 Bright { A_SpawnProjectile("RS_TimeShockMOT", 42, 0, random(-10, 10)); }
		"LMWX" A 10 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T00.Rail:
		"LMWX" A 20 Bright { A_StartSound("WVEXACTV", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" EFG 10 Bright { A_FaceTarget(); }
		"LMWX" H 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"LMWX" H 15 Bright
		{
			A_CustomRailgun(random(40, 90), 0, 0, 0,
			                RGF_NOPIERCING | RGF_SILENT, 1, 0,
			                "RS_WhiteFatRB", 0, 0, 0, 0, 0.4, 1.0,
			                "RS_WhiteFatRB4", 10);
		}
		"LMWX" G 15 Bright { A_FaceTarget(); }
		"LMWX" E 0 A_Jump(128, "Missile.T00.Choices");
		Goto See;
	Missile.T00.Eye:
		"LMWX" E 1 { A_StartSound("Forgotten/active"); }
		"LMWX" EFG 8 { A_FaceTarget(); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 78, 0); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 78, 24); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 78, -24); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 48, 12); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 48, -12); }
		"LMWX" A 0 { rsHohoMOT++; }
		"LMWX" HG 10;
		"LMWX" E 2;
		Goto See;
	Missile.T00.EyeBoom:
		"LMWX" G 5 Bright { A_FaceTarget(); }
		"LMWX" A 0 { A_RadiusGive("RS_WVEyeGo", 320, RGF_MISSILES, 10); }
		"LMWX" E 0 { rsHohoMOT--; }
		Goto Missile.T00.Choices;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T03:
	Pain.T04:
	Pain.T05:
	Pain.T06:
	Pain.T07:
	Pain.T08:
	Pain.T09:
	Pain.T10:
	Pain.T11:
	Pain.T12:
	Pain.TEX:
		"LMWX" I 3 { A_SetTranslucent(1, 1); }
		"LMWX" I 5 { A_Pain(); }
		"LMWX" F 1 { A_SetTranslucent(0.33, 1); }
		"LMWX" EEEEEEEEEE 2 { A_Wander(); }
		"LMWX" F 1 { A_SetTranslucent(1, 1); }
		"LMWX" F 4 { A_Stop(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T03:
	Death.T04:
	Death.T05:
	Death.T06:
	Death.T07:
	Death.T08:
	Death.T09:
	Death.T10:
	Death.T11:
	Death.T12:
	Death.TEX:
		TNT1 A 0 { bVISIBILITYPULSE = false; }
		"LMWX" J 6 { A_Scream(); }
		TNT1 A 0 { A_KillChildren("Extreme", KILS_FOILINVUL | KILS_KILLMISSILES); }
		"LMWX" K 6 { A_NoBlocking(); }
		"LMWX" LMNO 6;
		"LMWX" P -1;
		Stop;
	}
}

class RS_ArchvilePhantomEX : RS_MonsterMaster
{
	const RS_PHEX_SUMMON_AT   = 8;
	const RS_PHEX_BLACKOUT_AT = 14;

	// CHP's VoidMode inventory (0-3) and its user_myeyes counter.
	private int rsVoidMode;
	private int rsMyEyes;

	Default
	{
		Health 4166;
		Radius 20;
		Height 56;
		Mass 99999;
		Speed 20;
		PainChance 8;
		Monster;
		+QUICKTORETALIATE +FLOORCLIP +NOTARGET +BOSS +LOOKALLAROUND
		+DONTHARMSPECIES +DONTHARMCLASS +DONTMORPH +DONTDRAIN
		+CANTSEEK +SEEINVISIBLE +NOTIMEFREEZE +NOFEAR
		-SOLID -NORADIUSDMG
		Species "vile1";
		BloodColor "Black";
		RenderStyle "Stencil";
		Alpha 0.5;
		SeeSound "Bvile/Air2";   PainSound "Bvile/Air5";
		DeathSound "Bvile/Air4"; ActiveSound "Bvile/Air3";
		Obituary "$OB_VILE";
		Tag "Void Strikes Back";
	}

	override bool MinionsDieWithMe() { return true; }

	override string BodyTable()
	{
		// One body at every tier -- a stage isn't on the ladder. SILE is
		// the only real artwork it ever wears (the Summon and blackout
		// beats); the rest of the time the body is TNT1 and the cloud
		// trail is what you actually see.
		return "SILE SILE SILE SILE SILE SILE SILE SILE SILE SILE SILE SILE SILE SILE";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:archvile role:summoner delivery:radial element:void "
		       "mobility:ground trait:secondstage trait:ex";
	}

	// CHP re-rolls the mode on every See entry and on every pain.
	private void RS_RollVoidMode()
	{
		rsVoidMode = random(0, 3);
	}

	States
	{
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T03:
	Spawn.T04:
	Spawn.T05:
	Spawn.T06:
	Spawn.T07:
	Spawn.T08:
	Spawn.T09:
	Spawn.T10:
	Spawn.T11:
	Spawn.T12:
	Spawn.TEX:
		TNT1 A 1 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T03:
	See.T04:
	See.T05:
	See.T06:
	See.T07:
	See.T08:
	See.T09:
	See.T10:
	See.T11:
	See.T12:
	See.TEX:
		TNT1 A 0 { A_SetSpeed(random(10, 40)); }
		TNT1 A 0 { A_SetScale(frandom(0.77, 1.23), frandom(0.77, 1.23)); }
		TNT1 A 0 { RS_RollVoidMode(); }
		"SILE" GHIGHGHIGHGHIGH 4 { A_SpawnItemEx("RS_BVileEXCloud2", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 15.0), 0, 16416); }
		TNT1 A 0 { A_StartSound("Bvile/Air1", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
	See.T00.Chase:
		TNT1 A 0 { bNOPAIN = false; }
		TNT1 AA 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0, 5.0), 0, 16416); }
		TNT1 AAAAAA 4 { A_Chase(); }
		TNT1 AA 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0, 5.0), 0, 16416); }
		TNT1 AAAAAA 4 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "See.T00.Moveit");
		Loop;
	See.T00.FastChase:
		TNT1 A 0 { bNOPAIN = false; }
		TNT1 AA 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0, 5.0), 0, 16416); }
		TNT1 AAAAAA 4 { A_FastChase(); }
		TNT1 AA 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0, 5.0), 0, 16416); }
		TNT1 AAAAAA 4 { A_FastChase(); }
		TNT1 A 0 A_Jump(64, "See.T00.Moveit");
		Goto See.T00.Chase;
	See.T00.Moveit:
		TNT1 A 0 A_Jump(128, "See.T00.Moveit.Long");
		TNT1 AAAA 0 { A_Wander(); }
		Goto See.T00.FastChase;
	See.T00.Moveit.Long:
		TNT1 AAAAAAAAAAAAAAAA 0 { A_Wander(); }
		Goto See.T00.Chase;
	Missile.T00:
	Missile.T01:
	Missile.T02:
	Missile.T03:
	Missile.T04:
	Missile.T05:
	Missile.T06:
	Missile.T07:
	Missile.T08:
	Missile.T09:
	Missile.T10:
	Missile.T11:
	Missile.T12:
	Missile.TEX:
		TNT1 AAAA 0 { A_SpawnItemEx("RS_BVileEXCloud2", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 15.0), 0, 16416); }
		TNT1 A 0
		{
			if (rsMyEyes >= RS_PHEX_BLACKOUT_AT)
				return ResolveState("Missile.T00.Blackout");
			if (rsMyEyes == RS_PHEX_SUMMON_AT)
				return ResolveState("Missile.T00.Summon");
			if (rsVoidMode >= 3)
				return ResolveState("Missile.T00.Shockwave");
			if (rsVoidMode == 2)
				return ResolveState("Missile.T00.Kabam");
			if (rsVoidMode == 1)
				return ResolveState("Missile.T00.BlackHole");
			return ResolveState("Missile.T00.Shadowing");
		}
		Goto See;
	Missile.T00.Shadowing:
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
	// CHP rolls an even coin here between falling through into the wide
	// pattern and switching to the tight one (its A_Jump takes chance
	// 256 with offset 1 as one arm and the tight label as the other).
	Missile.T00.Shadowing2:
		TNT1 A 0 A_Jump(128, "Missile.T00.Shadowing3");
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-5, 5)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-5, 35)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-35, 5)); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-35, 35)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-35, 35)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-35, 35)); }
		TNT1 A 0 A_Jump(128, "Missile.T00.Shadowing2.Refire");
		Goto See.T00.Chase;
	Missile.T00.Shadowing2.Refire:
		TNT1 A 0 A_MonsterRefire(0, "See.T00.Chase");
		Goto Missile.T00.Shadowing2;
	Missile.T00.Shadowing3:
		TNT1 A 0 A_Jump(128, "Missile.T00.Shadowing2");
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-2, 2)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-2, 2)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-2, 2)); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-2, 2)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-2, 2)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-2, 2)); }
		TNT1 A 0 A_Jump(128, "Missile.T00.Shadowing3.Refire");
		Goto See.T00.Chase;
	Missile.T00.Shadowing3.Refire:
		TNT1 A 0 A_MonsterRefire(0, "See.T00.Chase");
		Goto Missile.T00.Shadowing3;
	Missile.T00.BlackHole:
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnProjectile("RS_BVileEXBlackHole", random(16, 64), random(-64, 64), random(-64, 64)); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		Goto See.T00.Chase;
	Missile.T00.Kabam:
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 A 4 { A_SpawnProjectile("RS_BVileEXMindWave", 32, 0, 0); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud2", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		Goto See.T00.Chase;
	Missile.T00.Shockwave:
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud4", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud4", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud4", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 AAAAAAAAAAAA 0 { A_SpawnProjectile("RS_BVileEXShockwave", 0, 0, random(-64, 64)); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud4", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud4", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		TNT1 AA 4 { A_SpawnItemEx("RS_BVileEXCloud4", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 16416); }
		TNT1 A 0 { A_FaceTarget(); }
		Goto See.T00.Chase;
	// At exactly 8 eyes. CHP names a common, a red and a purple revenant;
	// RS routes that through SummonPack so the live cap and the tier
	// offset apply instead of three unbounded spawns.
	Missile.T00.Summon:
		TNT1 A 0 { bNOPAIN = true; }
		"SILE" G 12 { A_StartSound("Bvile/Air2", CHAN_7, 0, 1.0, ATTN_NONE); }
		"SILE" GHIGHGHIGHGHIGH 4 { A_SpawnItemEx("RS_BVileEXCloud2", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 15.0), 0, 16416); }
		"SILE" J 15 { A_StartSound("Bvile/Air1", CHAN_7, 0, 1.0, ATTN_NONE); }
		"SILE" J 0 { A_FaceTarget(); }
		// CHP writes this glow beat on VILE's bracket frames; this
		// project's standing substitution is VILE N/O/P.
		VILE NOP 15 { A_FaceTarget(); }
		"SILE" A 0
		{
			if (SummonPack("RS_Revenant", 3, 6, -1, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		"SILE" AAAA 0 { A_SpawnItemEx("RS_MrBones", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_TRANSFERRENDERSTYLE | SXF_TRANSFERSTENCILCOL | SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERSCALE); }
		"SILE" A 1 { rsMyEyes++; }
		TNT1 A 0 { bNOPAIN = false; }
		Goto See;
	// At 14 eyes: the screen goes out, and the counter resets.
	Missile.T00.Blackout:
		TNT1 A 0 { bNOPAIN = true; }
		VILE N 12 { A_StartSound("Bvile/Air1", CHAN_7, 0, 1.0, ATTN_NONE); }
		VILE NOPNOPNOPNOPNOP 4 { A_SpawnItemEx("RS_BVileEXCloud4", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 15.0), 0, 16416); }
		VILE P 15 { A_StartSound("Bvile/Air5", CHAN_7, 0, 1.0, ATTN_NONE); }
		"SILE" GJN 15 { A_FaceTarget(); }
		"SILE" A 0 { A_GiveToTarget("RS_BVileEXDarknessToken", 99999999); }
		"SILE" A 1 { rsMyEyes = 0; }
		TNT1 A 0 { bNOPAIN = false; }
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T03:
	Pain.T04:
	Pain.T05:
	Pain.T06:
	Pain.T07:
	Pain.T08:
	Pain.T09:
	Pain.T10:
	Pain.T11:
	Pain.T12:
	Pain.TEX:
		TNT1 A 0 { RS_RollVoidMode(); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_BVileEXCloud2", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 5.0), 0, 16416); }
		TNT1 A 3 { rsMyEyes++; }
		TNT1 A 3 { A_Pain(); }
		TNT1 A 3 A_Jump(156, "Pain.T00.Wee");
		TNT1 A 0 { A_SpawnItemEx("RS_MrBones", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_TRANSFERRENDERSTYLE | SXF_TRANSFERSTENCILCOL | SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERSCALE); }
		Goto See.T00.Chase;
	Pain.T00.Wee:
		TNT1 A 0 { bNOPAIN = true; }
		TNT1 A 1 { A_SetSpeed(99); }
		TNT1 AAAAAAAA 1 { A_Wander(); }
		TNT1 A 0 { A_SetSpeed(random(10, 40)); }
		TNT1 A 0 { A_SpawnItemEx("RS_MrBones", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_TRANSFERRENDERSTYLE | SXF_TRANSFERSTENCILCOL | SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERSCALE); }
		Goto See.T00.Chase;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T03:
	Death.T04:
	Death.T05:
	Death.T06:
	Death.T07:
	Death.T08:
	Death.T09:
	Death.T10:
	Death.T11:
	Death.T12:
	Death.TEX:
		// Both darkness tokens come off the player when it dies -- the
		// blackout is hostage to this thing living, not permanent.
		TNT1 A 0 { A_TakeInventory("RS_BVileEXDarknessToken", 0, 0, AAPTR_TARGET); }
		TNT1 A 0 { A_TakeInventory("RS_BlackMindDarknessToken", 0, 0, AAPTR_TARGET); }
		TNT1 AAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BVileEXCloud3", random(-7, 7), random(-7, 7), 1, frandom(-30.0, 30.0), frandom(-30.0, 10.0), frandom(0.0, 30.0), 0, 16416); }
		TNT1 A 0 { A_Scream(); }
		TNT1 A 0 { A_NoBlocking(); }
		TNT1 A 5 { A_KillChildren("Extreme", KILS_FOILINVUL | KILS_KILLMISSILES); }
		TNT1 AAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BVileEXCloud3", random(-7, 7), random(-7, 7), 1, frandom(-30.0, 30.0), frandom(-30.0, 10.0), frandom(0.0, 30.0), 0, 16416); }
		TNT1 A 5;
		TNT1 AAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BVileEXCloud3", random(-7, 7), random(-7, 7), 1, frandom(-30.0, 30.0), frandom(-30.0, 10.0), frandom(0.0, 30.0), 0, 16416); }
		TNT1 A 5;
		TNT1 AAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BVileEXCloud3", random(-7, 7), random(-7, 7), 1, frandom(-30.0, 30.0), frandom(-30.0, 10.0), frandom(0.0, 30.0), 0, 16416); }
		TNT1 A 5;
		TNT1 AAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BVileEXCloud3", random(-7, 7), random(-7, 7), 1, frandom(-30.0, 30.0), frandom(-30.0, 10.0), frandom(0.0, 30.0), 0, 16416); }
		Stop;
	}
}

// ---------------------------------------------------------------------
// ROMERO EX (17_WX) BODIES -- the two things the White EX cyberdemon puts
// on the map that are monsters rather than projectiles.
// ---------------------------------------------------------------------

// GLITCH BARON. CHP's GlitchBaron_C: a Baron of Hell that has been
// corrupted along with everything else -- it NOCLIPS, it will not infight,
// and it throws the boss's own glitch shots instead of hellfire. Spawned
// two at a time by the phase-2 gate and by FatalBarons.
class RS_GlitchBaron : RS_MonsterMaster
{
	Default
	{
		Health 1000;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 16;
		PainChance 50;
		Monster;
		Species "Daikatana";
		+BOSS +FLOORCLIP +NOCLIP +NOTRIGGER +NOINFIGHTING
		+DONTHARMCLASS +DONTHARMSPECIES +DONTMORPH
		SeeSound "baron/sight";   PainSound "baron/pain";
		DeathSound "baron/death"; ActiveSound "baron/active";
		Obituary "$OB_BARON";
		HitObituary "$OB_BARONHIT";
		Tag "baronbaronbaronbaronbaron";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BOS9 BOS9 BOS9 BOS9 BOS9 BOS9 BOS9 BOS9 BOS9 BOS9 BOS9 BOS9 BOS9";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:baron role:bruiser delivery:heavy element:void "
		       "mobility:ground trait:secondstage trait:ex";
	}

	States
	{
	// BOS9 ships frames A and O ONLY (verified on disk) -- CHP's own
	// GlitchBaron uses A for every animated state and O for the corpse,
	// which is the whole joke: the sprite never finishes loading.
	Spawn.T00:
		TNT1 A 0 { A_SpawnItemEx("RS_RomeroEXGlitch", random(-20, 20), random(-20, 20), random(0, 64), 0, 0, 0, 0, SXF_SETMASTER); }
		TNT1 A 0 { A_SpawnItemEx("RS_RomeroEXGlitch", random(-20, 20), random(-20, 20), random(0, 64), 0, 0, 0, 0, SXF_SETMASTER); }
	Spawn.T00.Look:
		"BOS9" AA 10 { A_Look(); }
		Loop;
	See.T00:
		"BOS9" AAAAAAAA 3 { A_Chase(); }
		Loop;
	Pain.T00:
		"BOS9" A 2;
		"BOS9" A 2 { A_Pain(); }
		Goto See;
	Melee.T00:
	Missile.T00:
		"BOS9" AA 8 { A_FaceTarget(); }
		"BOS9" A 8 { A_CustomComboAttack("RS_RomeroEXGlitchShot", 32, 10 * random(1, 8), "baron/melee"); }
		"BOS9" AA 8 { A_FaceTarget(); }
		"BOS9" A 8 { A_CustomComboAttack("RS_RomeroEXGlitchShot", 32, 10 * random(1, 8), "baron/melee"); }
		Loop;
	Death.T00:
		"BOS9" A 8;
		"BOS9" A 8 { A_Scream(); }
		"BOS9" A 8;
		"BOS9" A 8 { A_NoBlocking(); }
		"BOS9" AA 8;
		"BOS9" O -1 { A_BossDeath(); }
		Stop;
	XDeath.T00:
		"BOS9" A 0 { A_Stop(); }
		"BOS9" A 8;
		"HKGB" B 0 { A_ScreamAndUnblock(); }
		"HKGB" B -1;
		Stop;
	}
}

// "The one behind it all" -- CommonWhiteCybieEX3, what the White EX
// cyberdemon leaves behind. A small, fast, constantly-jittering Romero
// that teleports to whoever killed the boss and then does nothing but
// hover and spray BFG balls. Its output GROWS as it dies: four volleys
// above 2000 HP, five below, seven below 1000.
class RS_CyberdemonRomeroStage2 : RS_MonsterMaster
{
	private int rsVolleys;

	Default
	{
		Health 3000;
		Radius 24;
		Height 88;
		Mass 99999;
		Speed 8;
		PainChance 32;
		Scale 0.75;
		Monster;
		Species "Daikatana";
		+BOSS +FLOORCLIP +THRUACTORS +THRUSPECIES +LAXTELEFRAGDMG
		+DONTHARMCLASS +DONTMORPH +NOICEDEATH +NOFEAR +QUICKTORETALIATE
		-NORADIUSDMG
		SeeSound "TRUROMRO";      PainSound "brain/pain";
		DeathSound "brain/death"; ActiveSound "TRUROMRO";
		Obituary "%o learned that Daikatana will be the greatest game of all time.";
		Tag "The one behind it all";
	}

	override bool MinionsDieWithMe() { return true; }

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "ROMR ROMR ROMR ROMR ROMR ROMR ROMR ROMR ROMR ROMR ROMR ROMR ROMR";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:cyberdemon role:artillery delivery:radial element:plasma "
		       "mobility:flying trait:secondstage trait:ex";
	}

	States
	{
	// The permanent scale wobble IS the character -- ROMR is two frames and
	// every other state tick rewrites the aspect ratio.
	Spawn.T00:
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.75, 0.85); }
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.8207, 0.8207); }
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.85, 0.75); }
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.8207, 0.6793); }
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.75, 0.65); }
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.6793, 0.6793); }
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.65, 0.75); }
		"ROMR" A 1 { A_Look(); }
		"ROMR" A 0 { A_SetScale(0.6793, 0.8207); }
		Loop;
	// It arrives ON you: warps to its target before it starts.
	See.T00:
		"ROMR" A 0 A_Warp(AAPTR_TARGET, 0, 0, 0, 0, WARPF_NOCHECKPOSITION);
		"ROMR" A 100 { A_SpawnItemEx("TeleportFog", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
	See.T00.Walk:
		TNT1 A 0 { bFLOAT = false; bNOGRAVITY = false; }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.75, 0.85); }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.8207, 0.8207); }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.85, 0.75); }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.8207, 0.6793); }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.75, 0.65); }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.6793, 0.6793); }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.65, 0.75); }
		"ROMR" A 1 { A_Chase(); }
		"ROMR" A 0 { A_SetScale(0.6793, 0.8207); }
		Goto See.T00.Walk;
	Missile.T00:
		"ROMR" A 0 A_CheckFloor("Missile.T00.Lift");
		Goto See.T00.Walk;
	Missile.T00.Lift:
		"ROMR" A 0 A_Jump(128, "Missile.T00.SuperBFG");
		"ROMR" A 0 { rsVolleys = 0; }
		"ROMR" A 0 { vel.z = 5.0; bFLOAT = true; bNOGRAVITY = true; }
		"ROMR" A 10 Bright { A_FaceTarget(); }
		"ROMR" A 0 A_JumpIfHealthLower(1000, "Missile.T00.BFG7");
		"ROMR" A 0 A_JumpIfHealthLower(2000, "Missile.T00.BFG5");
	Missile.T00.BFG4:
		"ROMR" A 0 { for (int i = 0; i < 4; i++) A_SpawnProjectile("RS_SpamShotsCguy", 32, 0, random(0, 360), CMF_AIMOFFSET, random(-10, 10)); }
		"ROMR" A 5 Bright { for (int i = 0; i < 4; i++) A_SpawnProjectile("RS_SpamShotsCguy", 32, 0, random(0, 360), CMF_AIMOFFSET, random(-10, 10)); }
		"ROMR" A 0 { rsVolleys++; }
		"ROMR" A 0 { if (rsVolleys >= 4) return ResolveState("Missile.T00.StopIt"); return ResolveState(null); }
		Loop;
	Missile.T00.BFG5:
		"ROMR" A 0 { for (int i = 0; i < 3; i++) A_SpawnProjectile("RS_SpamShotsCguy", 32, 0, random(0, 360), CMF_AIMOFFSET, random(-10, 10)); }
		"ROMR" A 5 Bright { for (int i = 0; i < 5; i++) A_SpawnProjectile("RS_SpamShotsCguy", 32, 0, random(0, 360), CMF_AIMOFFSET, random(-10, 10)); }
		"ROMR" A 0 { rsVolleys++; }
		"ROMR" A 0 { if (rsVolleys >= 5) return ResolveState("Missile.T00.StopIt"); return ResolveState(null); }
		Loop;
	Missile.T00.BFG7:
		"ROMR" A 0 { for (int i = 0; i < 7; i++) A_SpawnProjectile("RS_SpamShotsCguy", 32, 0, random(0, 360), CMF_AIMOFFSET, random(-10, 10)); }
		"ROMR" A 5 Bright { for (int i = 0; i < 8; i++) A_SpawnProjectile("RS_SpamShotsCguy", 32, 0, random(0, 360), CMF_AIMOFFSET, random(-10, 10)); }
		"ROMR" A 0 { rsVolleys++; }
		"ROMR" A 0 { if (rsVolleys >= 6) return ResolveState("Missile.T00.StopIt"); return ResolveState(null); }
		Loop;
	Missile.T00.StopIt:
		"ROMR" A 0 { bFLOAT = false; }
		"ROMR" A 10 Bright { bNOGRAVITY = false; }
		Goto See.T00.Walk;
	// The single big one.
	Missile.T00.SuperBFG:
		"ROMR" A 0 { vel.z = 5.0; bFLOAT = true; bNOGRAVITY = true; }
		"ROMR" AA 10 Bright { A_FaceTarget(); }
		"ROMR" A 5 Bright { A_SpawnProjectile("RS_RomeroEXRealBFG", 32, 0, random(-10, 10), CMF_AIMOFFSET, random(-10, 10)); }
		"ROMR" A 0 { bFLOAT = false; }
		"ROMR" A 10 Bright { bNOGRAVITY = false; }
		Goto See.T00.Walk;
	Pain.T00:
		"ROMR" B 2;
		"ROMR" B 2 { A_Pain(); }
		Goto See.T00.Walk;
	Death.T00:
		TNT1 A 0 { ReleaseMinions(); }
		"ROMR" B 4 Bright { A_Scream(); }
		"ROMR" BBBBBBBBBBBBBBBBBBBBBBBBBBBBB 3 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 70), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"ROMR" BBBBBBBBBBBBBBBBBBBBBBBBBBBBB 1 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 70), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"ROMR" B 0 { A_NoBlocking(); }
		"ROMR" B 0 { A_BossDeath(); }
		"ROMR" B 0 { A_SetScale(2.0, 2.0); }
		MISL X 0 { A_StartSound("weapons/rocklx", CHAN_5); }
		MISL XYZ 4 Bright;
		MISL X 0 { A_StartSound("weapons/rocklx", CHAN_5); }
		MISL XYZ 4 Bright;
		MISL X 0 { A_StartSound("weapons/rocklx", CHAN_5); }
		MISL XYZ 4 Bright;
		TNT1 A -1;
		Stop;
	XDeath.T00:
		Goto Death.T00;
	}
}
