// =====================================================================
// RS_Minions -- summoned monsters, on the per-tier state architecture
// (docs/rs_09_monster_rebuild_spec.txt).
// ---------------------------------------------------------------------
// These are REAL RS_MonsterMaster monsters, not throwaway actors: they
// carry a tier, wear per-tier bodies, and can be retiered by the
// ambient dial like anything else. They do NOT count toward kill
// totals (SummonMinion clears COUNTKILL).
//
// Bodies reuse existing verified sprites -- a minion is a variant of
// something already on disk, never new art.
//
// SUBSTITUTIONS (verified against the sprite folders):
//   * Tendril T08 was IFN2, a 2-frame effect sprite that cannot carry
//     a walker's state set -- HDOG stands in.
//   * Sentinel T08 was BOSF, which exists nowhere in ART SOURCE --
//     SKUL (its tinted base body) stands in.
// =====================================================================

// ---------------------------------------------------------------------
// BARON'S TENTACLES -- the Deep One's pack.
// Two shapes from one summoner: a melee rusher that closes, and a
// ranged plinker that hangs back.
// ---------------------------------------------------------------------

class RS_BaronTentacle : RS_MonsterLadder
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
		return "SARG SARG SARG WORM SARG SRG2 HDOG SARG HDOG WORM SRG2 BCHR JUGG";
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
	// --- SARG body: T00 T01 T02 T04 T07 (vanilla demon layout) ---
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T07:
		"SARG" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T07:
		"SARG" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T00:
	Melee.T01:
	Melee.T02:
	Melee.T04:
	Melee.T07:
		"SARG" EF 6 { A_FaceTarget(); }
		"SARG" G 6 { A_SargAttack(); }
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T07:
		"SARG" H 2;
		"SARG" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T07:
		"SARG" I 6;
		"SARG" J 6 { A_Scream(); }
		"SARG" K 4;
		"SARG" L 4 { A_NoBlocking(); }
		"SARG" MN 4;
		Stop;

	// --- WORM body: T03 T09 ---
	Spawn.T03:
	Spawn.T09:
		"WORM" AB 10 { A_Look(); }
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
		"SRG2" AB 10 { A_Look(); }
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

	// --- HDOG body: T06, and T08 (IFN2 substitute, see header) ---
	Spawn.T06:
	Spawn.T08:
		"HDOG" AB 10 { A_Look(); }
		Loop;
	See.T06:
	See.T08:
		"HDOG" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T06:
	Melee.T08:
		"HDOG" EF 6 { A_FaceTarget(); }
		"HDOG" G 6 { A_SargAttack(); }
		Goto See;
	Pain.T06:
	Pain.T08:
		"HDOG" H 2;
		"HDOG" H 2 { A_Pain(); }
		Goto See;
	Death.T06:
	Death.T08:
		"HDOG" I 6;
		"HDOG" J 6 { A_Scream(); }
		"HDOG" K 4;
		"HDOG" L 4 { A_NoBlocking(); }
		"HDOG" MNOPQ 4;
		Stop;

	// --- BCHR body: T11 ---
	Spawn.T11:
		"BCHR" AB 10 { A_Look(); }
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
		"BCHR" MNOPQ 4;
		Stop;

	// --- JUGG body: T12 ---
	Spawn.T12:
		"JUGG" AB 10 { A_Look(); }
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
		"JUGG" MNOPQ 4;
		Stop;
	}
}

// The ranged half of the pack. Same bodies, different job -- it keeps
// its distance and throws, so the player can't just back into a corner
// and swing. One Missile override serves every tier: bare #### keeps
// whichever body the tier cluster dressed us in, and E/F/G exist on
// every body this table uses.
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
		#### E 6 { A_FaceTarget(); }
		#### F 6 { A_FaceTarget(); }
		#### G 8 { A_RS_MonsterFire(); }
		Goto See;
	}
}

// ---------------------------------------------------------------------
// PAIN ELEMENTAL'S SENTINEL -- the permanent escort.
// Small, fast, and replaced when it dies. The replacement loop is what
// makes the White Pain Elemental fight feel maintained rather than a
// one-shot summon you can just out-wait.
// ---------------------------------------------------------------------

class RS_PainSentinel : RS_MonsterLadder
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
		return "SKUL SKUL SKUL LFX1 SKUL FRGO BST7 SKUL SKUL SKUL FRGO WASP ETHS";
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
	// --- SKUL body: T00 T01 T02 T04 T07 T08 T09 (T08 = BOSF sub) ---
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T07:
	Spawn.T08:
	Spawn.T09:
		"SKUL" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T07:
	See.T08:
	See.T09:
		"SKUL" AB 5 { A_Chase(); }
		Loop;
	Missile.T00:
	Missile.T01:
	Missile.T02:
	Missile.T04:
	Missile.T07:
	Missile.T08:
	Missile.T09:
		"SKUL" C 8 { A_FaceTarget(); }
		"SKUL" D 8 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T07:
	Pain.T08:
	Pain.T09:
		"SKUL" E 3;
		"SKUL" E 3 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T07:
	Death.T08:
	Death.T09:
		"SKUL" F 6 Bright;
		"SKUL" G 6 Bright { A_Scream(); }
		"SKUL" H 6 Bright { A_NoBlocking(); }
		"SKUL" IJ 6 Bright;
		Stop;

	// --- LFX1 body: T03 ---
	Spawn.T03:
		"LFX1" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"LFX1" AB 5 { A_Chase(); }
		Loop;
	Missile.T03:
		"LFX1" C 8 { A_FaceTarget(); }
		"LFX1" D 8 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T03:
		"LFX1" E 3;
		"LFX1" E 3 { A_Pain(); }
		Goto See;
	Death.T03:
		"LFX1" F 6 Bright;
		"LFX1" G 6 Bright { A_Scream(); }
		"LFX1" H 6 Bright { A_NoBlocking(); }
		"LFX1" IJ 6 Bright;
		Stop;

	// --- FRGO body: T05 T10 ---
	Spawn.T05:
	Spawn.T10:
		"FRGO" AB 10 { A_Look(); }
		Loop;
	See.T05:
	See.T10:
		"FRGO" AB 5 { A_Chase(); }
		Loop;
	Missile.T05:
	Missile.T10:
		"FRGO" C 8 { A_FaceTarget(); }
		"FRGO" D 8 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T05:
	Pain.T10:
		"FRGO" E 3;
		"FRGO" E 3 { A_Pain(); }
		Goto See;
	Death.T05:
	Death.T10:
		"FRGO" F 6 Bright;
		"FRGO" G 6 Bright { A_Scream(); }
		"FRGO" H 6 Bright { A_NoBlocking(); }
		"FRGO" IJ 6 Bright;
		Stop;

	// --- BST7 body: T06 ---
	Spawn.T06:
		"BST7" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"BST7" AB 5 { A_Chase(); }
		Loop;
	Missile.T06:
		"BST7" C 8 { A_FaceTarget(); }
		"BST7" D 8 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T06:
		"BST7" E 3;
		"BST7" E 3 { A_Pain(); }
		Goto See;
	Death.T06:
		"BST7" F 6 Bright;
		"BST7" G 6 Bright { A_Scream(); }
		"BST7" H 6 Bright { A_NoBlocking(); }
		"BST7" IJ 6 Bright;
		Stop;

	// --- WASP body: T11. Four frames total (ABCD, verified on disk),
	// so it gets a bespoke compact set rather than the SKUL layout. ---
	Spawn.T11:
		"WASP" AB 6 { A_Look(); }
		Loop;
	See.T11:
		"WASP" ABCD 3 { A_Chase(); }
		Loop;
	Missile.T11:
		"WASP" C 6 { A_FaceTarget(); }
		"WASP" D 6 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T11:
		"WASP" A 3;
		"WASP" A 3 { A_Pain(); }
		Goto See;
	Death.T11:
		"WASP" D 5 Bright { A_Scream(); }
		"WASP" D 5 Bright { A_NoBlocking(); }
		"WASP" DD 4 Bright A_FadeOut(0.25);
		Stop;

	// --- ETHS body: T12 ---
	Spawn.T12:
		"ETHS" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"ETHS" AB 5 { A_Chase(); }
		Loop;
	Missile.T12:
		"ETHS" C 8 { A_FaceTarget(); }
		"ETHS" D 8 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T12:
		"ETHS" E 3;
		"ETHS" E 3 { A_Pain(); }
		Goto See;
	Death.T12:
		"ETHS" F 6 Bright;
		"ETHS" G 6 Bright { A_Scream(); }
		"ETHS" H 6 Bright { A_NoBlocking(); }
		"ETHS" IJ 6 Bright;
		Stop;
	}
}
