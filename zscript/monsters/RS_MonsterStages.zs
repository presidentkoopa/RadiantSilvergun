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
