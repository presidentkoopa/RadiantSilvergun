// =====================================================================
// RS_MonsterStages -- multi-stage boss bodies and pack minions that
// don't belong to a single family file.
//
// The shrink chain (Arachnotron) and the Butcher's dogs live here
// rather than padding their parent's file, since both are referenced
// through RS_MonsterCatalog and neither is a "family" in its own right.
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
	Spawn:
		"BSP2" AB 8  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"BSP2" AABBCCDDEEFF 3  { RS_WearBody(); A_BabyMetal(); }
		Loop;
	Missile:
		"BSP2" A 12  Bright { RS_WearBody(); A_FaceTarget(); }
		"BSP2" G 8  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		"BSP2" H 8  Bright { RS_WearBody(); }
		Goto See;
	Pain:
		"BSP2" I 3 { RS_WearBody(); }
		"BSP2" I 3  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"BSP2" J 12  { RS_WearBody(); A_Scream(); }
		"BSP2" K 6  { RS_WearBody(); A_NoBlocking(); }
		"BSP2" LMNO 6 { RS_WearBody(); }
		"BSP2" P -1 { RS_WearBody(); }
		Stop;
	}
}

// Final stage. Small, fast, and it bursts rather than falling over.
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
		"POSS" J 8  { RS_WearBody(); A_Scream(); }
		"POSS" K 6  { RS_WearBody(); A_NoBlocking(); }
		// Shatters instead of leaving a corpse -- the visual full stop
		// on the chain.
		"POSS" L 6  { RS_WearBody(); A_Burst("RS_ArachShard"); }
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
		return "HDOG HDOG HDOG WORM HDOG SRG2 HDOG HDOG IFN2 WORM SRG2 BCHR JUGG";
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
	Spawn:
		"HDOG" AB 8  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"HDOG" AABBCCDD 2  { RS_WearBody(); A_Chase(); }
		Loop;
	Melee:
		"HDOG" EF 6  { RS_WearBody(); A_FaceTarget(); }
		"HDOG" G 6  { RS_WearBody(); A_SargAttack(); }
		Goto See;
	Pain:
		"HDOG" H 2 { RS_WearBody(); }
		"HDOG" H 2  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"HDOG" I 6 { RS_WearBody(); }
		"HDOG" J 6  { RS_WearBody(); A_Scream(); }
		"HDOG" K 4 { RS_WearBody(); }
		"HDOG" L 4  { RS_WearBody(); A_NoBlocking(); }
		"HDOG" MN 4 { RS_WearBody(); }
		Stop;
	}
}
