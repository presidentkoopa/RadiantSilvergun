// =====================================================================
// RS_Minions -- summoned monsters.
// ---------------------------------------------------------------------
// These are REAL RS_MonsterMaster monsters, not throwaway actors: they
// carry a tier, they wear a body table, they can be retiered by the
// ambient dial like anything else. That was a deliberate call -- it
// means a summoned pack scales with the fight instead of being frozen
// at whatever the summoner rolled, and it means minions are a system we
// can add to later rather than a pile of one-offs.
//
// What they are NOT: kill-count contributors. A boss that summons
// forever would make 100% kills impossible, so SummonMinion clears
// COUNTKILL on everything it spawns.
//
// Bodies reuse existing verified sprites -- a minion is a variant of
// something already on disk, never new art.
// =====================================================================

// ---------------------------------------------------------------------
// BARON'S TENTACLES -- the Deep One's pack.
// Two shapes from one summoner so the pack has internal structure:
// a melee rusher that closes, and a ranged plinker that hangs back.
// ---------------------------------------------------------------------

class RS_BaronTentacle : RS_MonsterMaster
{
	Default
	{
		Health 120;
		Radius 20;
		Height 48;
		Mass 200;
		Speed 12;
		PainChance 140;
		Monster;
		+FLOORCLIP
		SeeSound "baron/sight";   PainSound "baron/pain";
		DeathSound "baron/death"; ActiveSound "baron/active";
		Obituary "$OB_BARON";
		Tag "Hell Tendril";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SARG SARG SARG WORM SARG SRG2 HDOG SARG IFN2 WORM SRG2 BCHR JUGG";
	}

	override string TintTable()
	{
		return "- rs_demon_t01 rs_demon_t02 rs_demon_t03 rs_demon_t04 rs_demon_t05 "
		       "rs_demon_t06 rs_demon_t07 rs_demon_t08 rs_demon_t09 rs_demon_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:tendril role:fodder delivery:melee element:thermal mobility:ground trait:summoned";
	}

	States
	{
	Spawn:
		"SARG" AB 10  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"SARG" AABBCCDD 2  { RS_WearBody(); A_Chase(); }
		Loop;
	Melee:
		"SARG" EF 6  { RS_WearBody(); A_FaceTarget(); }
		"SARG" G 6  { RS_WearBody(); A_SargAttack(); }
		Goto See;
	Pain:
		"SARG" H 2 { RS_WearBody(); }
		"SARG" H 2  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"SARG" I 6 { RS_WearBody(); }
		"SARG" J 6  { RS_WearBody(); A_Scream(); }
		"SARG" K 4 { RS_WearBody(); }
		"SARG" L 4  { RS_WearBody(); A_NoBlocking(); }
		"SARG" MN 4 { RS_WearBody(); }
		Stop;
	}
}

// The ranged half of the pack. Same body, different job -- it keeps its
// distance and throws, so the player can't just back into a corner and
// swing.
class RS_BaronTentacleRanged : RS_BaronTentacle
{
	Default
	{
		Health 90;
		Speed 9;
		Tag "Hell Tendril (Caster)";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		// Single bolt at low tier; a three-shot fan once it's grown.
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_TendrilBolt(),
			t >= 7 ? 3 : 1,          // count
			t >= 7 ? 24.0 : 0.0,     // fan arc
			"baron/attack", 1.0, 0.0, "Tendril Bolt"));
		return slot;
	}

	override string GetBaseKeywords()
	{
		return "species:tendril role:artillery delivery:heavy element:thermal mobility:ground trait:summoned";
	}

	States
	{
	Missile:
		"POSS" EF 6  { RS_WearBody(); A_FaceTarget(); }
		"POSS" G 8  { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	}
}

// ---------------------------------------------------------------------
// PAIN ELEMENTAL'S SENTINEL -- the permanent escort.
// Small, fast, and replaced when it dies. The replacement loop is what
// makes the White Pain Elemental fight feel maintained rather than a
// one-shot summon you can just out-wait.
// ---------------------------------------------------------------------

class RS_PainSentinel : RS_MonsterMaster
{
	Default
	{
		Health 60;
		Radius 16;
		Height 32;
		Mass 60;
		Speed 14;
		PainChance 200;
		Monster;
		+FLOAT +NOGRAVITY +DONTFALL
		RenderStyle "Add";
		Alpha 0.9;
		SeeSound "skull/melee";  PainSound "skull/pain";
		DeathSound "skull/death"; ActiveSound "skull/active";
		Obituary "$OB_SKULL";
		Tag "Sentinel";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SKUL SKUL SKUL LFX1 SKUL FRGO BST7 SKUL BOSF SKUL FRGO WASP ETHS";
	}

	override string TintTable()
	{
		return "- rs_soul_t01 rs_soul_t02 rs_soul_t03 rs_soul_t04 rs_soul_t05 "
		       "- rs_soul_t07 - rs_soul_t09 rs_soul_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:sentinel role:skirmisher delivery:heavy element:thermal mobility:flying trait:summoned";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_SentinelFlare(), 1, 0.0,
			"skull/melee", 1.0, 0.0, "Sentinel Flare"));
		return slot;
	}

	States
	{
	Spawn:
		"SKUL" AB 10  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"SKUL" AB 5  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		"SKUL" C 8  { RS_WearBody(); A_FaceTarget(); }
		"SKUL" D 8  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	Pain:
		"SKUL" E 3 { RS_WearBody(); }
		"SKUL" E 3  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"SKUL" F 6  Bright { RS_WearBody(); }
		"SKUL" G 6  Bright { RS_WearBody(); A_Scream(); }
		"SKUL" H 6  Bright { RS_WearBody(); A_NoBlocking(); }
		"SKUL" IJ 6  Bright { RS_WearBody(); }
		Stop;
	}
}
