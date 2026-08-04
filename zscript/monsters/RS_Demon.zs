// =====================================================================
// RS_Demon -- on RS_DemonBase (RS_MonsterMaster.zs). Replaces Demon.
// Rebuilt to the per-tier state architecture (docs/rs_09 spec,
// RS_Imp.zs is the template).
//
// THIRTEEN REAL CREATURES:
//   T00 SARG vanilla pinky        T01 SARG+tint faster charger
//   T02 SARG+tint tough charger   T03 WORM ice worm: spike bite + lunge
//   T04 SARG+tint heavy charger   T05 SRG2 lightning zap charger
//   T06 HDOG Hell Hound: seeking fire + bite
//   T07 SARG+tint fireblu charger T08 IFN2 imp-fiend: orb + bolt spam
//   T09 WORM leech-worm: warps on, latches, drains HP
//   T10 SRG2 blood-bolt charger   T11 BCHR the Butcher: hammers
//   T12 JUGG Juggernaut: quakes + rock breath
//
// RS mechanics preserved from the previous file: RS_ButcherHit (the
// hit-counter pack release + one-way no-flinch enrage) now rolls in
// the Pain DISPATCHER so every tier cluster gets it; DemonDog summons;
// MinionsDieWithMe; keywords; tint table; consts.
//
// SUBSTITUTIONS (verified on disk):
//   * T08 IFN2 has ONLY frames A+B on disk (CH's fiend used IFIN A-N,
//     never imported). Attack/pain reuse A/B; death is an explosive
//     vanish (CH's brown demon died in a blast anyway -- DeathSound
//     was a rocket boom) instead of the missing IFIN corpse frames.
//   * T05/T10 SRG2 death omits CH's BloodDemonArm gib toss (cosmetic
//     actor, no RS port).
//   * T12 death omits CH's "Juggernaut/Thud" sound (no SNDINFO lump).
// HONEST OMISSION: CH BrownDemon2's dash/calm uservar state machine is
// not ported (needs per-actor uservars + ghost trail actors); its
// attacks (BrownOrbDemon + bolt chain) are complete. Same call HF made.
// =====================================================================

class RS_Demon : RS_DemonBase replaces Demon
{
	Default
	{
		Health 150;
		Radius 30;
		Height 56;
		Mass 400;
		Speed 10;
		PainChance 180;
		Monster;
		+FLOORCLIP
		SeeSound "demon/sight";   PainSound "demon/pain";
		DeathSound "demon/death"; ActiveSound "demon/active";
		AttackSound "demon/melee";
		Obituary "$OB_DEMON";
		Tag "Demon";
	}

	// Audit data: which body each tier wears (the clusters below are
	// the live implementation; AUDIT cross-checks them against this).
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
		return "species:demon role:bruiser delivery:melee element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE BUTCHER. Takes hits, and at a count releases the pack -- so
	// the reward for beating on it is more things biting you. Plus a
	// chance each hit to permanently stop flinching, which is what turns
	// a pinky into a freight train mid-fight.
	// -----------------------------------------------------------------
	const RS_DEMON_TIER_PACK = 7;
	const RS_DEMON_PACK_AT   = 8;

	override bool MinionsDieWithMe() { return true; }

	void RS_ButcherHit()
	{
		if (Tier < RS_DEMON_TIER_PACK)
			return;

		AddCharge(1);

		if (ChargeCounter >= RS_DEMON_PACK_AT)
		{
			ResetCharge();
			if (SummonPack(RS_MonsterCatalog.MINION_DemonDog(), 3, 6, -3, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}

		// Permanent, one-way. Guarded by the flag itself.
		if (!bNOPAIN && Tier >= 9 && random(0, 255) < 90)
		{
			bNOPAIN = true;
			MissileChanceMult *= 2.0;
			Speed *= 1.25;
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	States
	{
	// ===== dispatcher override: the Butcher counts every flinch =====
	Pain:
		TNT1 A 0
		{
			RS_ButcherHit();
			return TierState("Pain");
		}
		Goto See;

	// =========================================================
	// T00 -- vanilla pinky. T01/T02/T04/T07 share the SARG body:
	// they are CH's stat-ladder chargers, so everything stacks.
	// =========================================================
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
		"SARG" EF 8 { A_FaceTarget(); }
		"SARG" G 8 { A_SargAttack(); }
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
		"SARG" I 8;
		"SARG" J 8 { A_Scream(); }
		"SARG" K 4;
		"SARG" L 4 { A_NoBlocking(); }
		"SARG" M 4;
		"SARG" N -1;
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
	Raise.T04:
	Raise.T07:
		"SARG" NMLKJI 5;
		Goto See;

	// ===== T03 CYAN -- ice worm (WORM). Spike-burst bite, lunges =====
	// T09 GRAY shares the WORM body: walk/pain stack here, its leech
	// attack lives in its own Melee/Missile below.
	Spawn.T03:
	Spawn.T09:
		"WORM" AB 10 { A_Look(); }
		Loop;
	See.T03:
	See.T09:
		"WORM" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T03:
		"WORM" EF 4 { A_FaceTarget(); }
		"WORM" H 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 24, random(9, 33), 0, random(3, 9), frandom(-9, 9)); }
		"WORM" H 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 24, random(9, 33), 0, random(3, 9), frandom(-9, 9)); }
		"WORM" H 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 29, random(9, 33), 0, random(4, 12), frandom(-4, 4)); }
		"WORM" H 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 29, random(9, 33), 0, random(4, 12), frandom(-4, 4)); }
		"WORM" G 4 { A_CustomMeleeAttack(random(25, 75), "slimeworm/melee", ""); }
		Goto See;
	Missile.T03:
		// The Hiss: a skull-charge lunge to close the gap.
		"WORM" EF 4 { A_FaceTarget(); }
		"WORM" G 8 { A_SkullAttack(40); }
		Goto See;
	Pain.T03:
	Pain.T09:
		"WORM" H 2;
		"WORM" H 2 { A_Pain(); }
		Goto See;
	Death.T03:
		// CH: the ice worm's corpse shatters.
		"WORM" I 8;
		"WORM" J 8 { A_Scream(); }
		"WORM" K 4;
		"WORM" L 4 { A_NoBlocking(); }
		"WORM" M 4;
		"WORM" N 1 { A_IceGuyDie(); }
		Stop;

	// ===== T05 YELLOW -- lightning charger (SRG2) =====
	// T10 RED shares the SRG2 body: walk/pain/death stack here.
	Spawn.T05:
	Spawn.T10:
		"SRG2" AB 10 { A_Look(); }
		Loop;
	See.T05:
	See.T10:
		"SRG2" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T05:
		"SRG2" EF 8 { A_FaceTarget(); }
		"SRG2" G 8 { A_SargAttack(); }
		Goto See;
	Missile.T05:
		"SRG2" EF 6 { A_FaceTarget(); }
		"SRG2" G 6 Bright { A_SpawnProjectile("RS_ZapZapCB", 32, 0, 0); }
		Goto See;
	Pain.T05:
	Pain.T10:
		"SRG2" H 2;
		"SRG2" H 2 { A_Pain(); }
		Goto See;
	Death.T05:
	Death.T10:
		// CH tossed a BloodDemonArm gib here -- cosmetic actor with no
		// RS port, omitted.
		"SRG2" I 8;
		"SRG2" J 8 { A_Scream(); }
		"SRG2" K 4;
		"SRG2" L 4 { A_NoBlocking(); }
		"SRG2" M 4;
		"SRG2" N -1;
		Stop;
	Raise.T05:
	Raise.T10:
		"SRG2" NMLKJI 5;
		Goto See;

	// ===== T10 RED -- blood-bolt charger (body shared with T05) =====
	Melee.T10:
		"SRG2" EF 7 { A_FaceTarget(); }
		"SRG2" G 7 { A_CustomMeleeAttack(random(15, 50), "demon/melee", ""); }
		Goto See;
	Missile.T10:
		"SRG2" EF 6 { A_FaceTarget(); }
		"SRG2" G 5 Bright { A_SpawnProjectile("RS_RedDemonBloodBolt1", 24, 0, random(-4, 4)); }
		"SRG2" G 5 Bright { A_SpawnProjectile("RS_RedDemonBloodBolt1", 24, 0, random(-4, 4)); }
		Goto See;

	// ===== T06 ABYSS -- Hell Hound (HDOG): seeking fire + bite =====
	Spawn.T06:
		"HDOG" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"HDOG" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T06:
		"HDOG" EF 7 { A_FaceTarget(); }
		"HDOG" G 7 { A_CustomMeleeAttack(random(15, 55), "hellhound/melee", ""); }
		Goto See;
	Missile.T06:
		"HDOG" EF 6 { A_FaceTarget(); }
		"HDOG" G 5 Bright { A_SpawnProjectile("RS_AbyssDogFire", 24, 0, random(-4, 4)); }
		"HDOG" G 5 Bright { A_SpawnProjectile("RS_AbyssDogFire", 24, 0, random(-4, 4)); }
		Goto See;
	Pain.T06:
		"HDOG" H 2;
		"HDOG" H 2 { A_Pain(); }
		Goto See;
	Death.T06:
		"HDOG" K 8;
		"HDOG" L 8 { A_Scream(); }
		"HDOG" M 4;
		"HDOG" N 4 { A_NoBlocking(); }
		"HDOG" OP 4;
		"HDOG" Q -1;
		Stop;
	Raise.T06:
		"HDOG" QPONMLK 5;
		Goto See;

	// ===== T08 BROWN -- imp-fiend (IFN2). ONLY frames A+B exist on
	// disk (CH used IFIN A-N, never imported) -- every state here is
	// built from those two frames, and the death is an explosive
	// vanish rather than the missing corpse sequence. =====
	Spawn.T08:
		"IFN2" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"IFN2" AABB 2 { A_Chase(); }
		Loop;
	Melee.T08:
		"IFN2" A 7 { A_FaceTarget(); }
		"IFN2" B 7 { A_CustomMeleeAttack(random(12, 45), "demon/melee", ""); }
		Goto See;
	Missile.T08:
		"IFN2" A 6 { A_FaceTarget(); }
		"IFN2" B 6 { A_FaceTarget(); }
		"IFN2" B 5 Bright { A_SpawnProjectile("RS_BrownOrbDemon", 24, 0, random(-5, 5)); }
		"IFN2" A 5 Bright { A_SpawnProjectile("RS_RedDemonBloodBolt3", 24, 0, random(-8, 8)); }
		Goto See;
	Pain.T08:
		"IFN2" A 2;
		"IFN2" A 2 { A_Pain(); }
		Goto See;
	Death.T08:
		"IFN2" A 6 { A_Scream(); }
		"IFN2" B 5 { A_NoBlocking(); A_Explode(random(5, 32), 64); }
		TNT1 AAAAAAAAAAAA 0 { A_SpawnItemEx("RS_PuffCybieRed", 0, 0, 24, random(3, 9), 0, random(1, 15), random(0, 359)); }
		"IFN2" A 4 { A_FadeOut(0.25); }
		"IFN2" B 4 { A_FadeOut(0.25); }
		"IFN2" A 4 { A_FadeOut(0.2); }
		TNT1 A 1;
		Stop;

	// ===== T09 GRAY -- leech-worm. Warps onto the target, latches,
	// drains HP while spitting WormLewd bites; skull-lunge at range.
	// (Walk/pain stacked on T03 above.) =====
	Melee.T09:
		"WORM" EF 3 { A_FaceTarget(); }
		"WORM" G 3 A_JumpIfCloser(72, "Melee.T09.Wrap");
		Goto See;
	Melee.T09.Wrap:
		TNT1 A 0
		{
			// Safety: CH's latch loop has no exit without a target.
			if (!target)
				return ResolveState("See");
			return ResolveState(null);
		}
		"WORM" H 1 { A_Warp(AAPTR_TARGET, random(-1, 3), 0, 12, random(-45, 45), WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); }
		"WORM" E 0 { A_StartSound("slimeworm/melee", CHAN_WEAPON); }
		"WORM" E 1 { A_Warp(AAPTR_TARGET, random(-1, 3), 0, 12, random(-45, 45), WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); }
		"WORM" H 0 { A_SpawnProjectile("RS_WormLewd", 12, 0, 0); }
		"WORM" H 0 { A_CustomMeleeAttack(random(5, 23), "slimeworm/melee", ""); }
		"WORM" H 0 { HealThing(5, 99); }
		"WORM" H 0 A_JumpIfTargetInLOS("See", 1);
		"WORM" HEHEHEHE 1 { A_Warp(AAPTR_TARGET, random(-1, 3), 0, 12, random(-45, 45), WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); }
		Loop;
	Missile.T09:
		"WORM" EF 4 { A_FaceTarget(); }
		"WORM" G 8 { A_SkullAttack(45); }
		Goto See;
	Death.T09:
		"WORM" I 8;
		"WORM" J 8 { A_Scream(); }
		"WORM" K 4;
		"WORM" L 4 { A_NoBlocking(); }
		"WORM" M 4;
		"WORM" N -1;
		Stop;
	Raise.T09:
		"WORM" NMLKJI 5;
		Goto See;

	// ===== T11 BLACK -- the Butcher (BCHR): heavy melee + hammers =====
	Spawn.T11:
		"BCHR" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"BCHR" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T11:
		"BCHR" EF 8 { A_FaceTarget(); }
		"BCHR" G 8 { A_CustomMeleeAttack(random(40, 110), "butcher/melee", ""); }
		Goto See;
	Missile.T11:
		"BCHR" A 0 A_JumpIfCloser(110, "Melee.T11");
		"BCHR" EF 8 { A_FaceTarget(); }
		"BCHR" G 5 Bright { A_SpawnProjectile("RS_ButcherHammer", 32, 0, random(-5, 5)); }
		"BCHR" G 5 Bright { A_SpawnProjectile("RS_ButcherHammer", 32, 0, random(-5, 5)); }
		"BCHR" G 4 A_MonsterRefire(40, "See");
		Goto See;
	Pain.T11:
		"BCHR" H 2;
		"BCHR" H 2 { A_Pain(); }
		Goto See;
	Death.T11:
		// The dying Butcher flings a last hammer, exactly as CH's did.
		"BCHR" H 12 { A_Scream(); }
		"BCHR" IJK 6;
		"BCHR" L 0 { A_FaceTarget(); }
		"BCHR" L 6 { A_SpawnItemEx("RS_ButcherHammer", 0, -18, 24, 3, 0, 3, -85, 128); }
		"BCHR" M 6 { A_NoBlocking(); }
		"BCHR" NOP 6;
		"BCHR" Q -1;
		Stop;

	// ===== T12 WHITE -- Juggernaut (JUGG): quakes + rock breath =====
	Spawn.T12:
		"JUGG" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"JUGG" AABBCCDD 2 { A_Chase(); }
		Loop;
	Melee.T12:
		"JUGG" EF 8 { A_FaceTarget(); }
		"JUGG" G 8 { A_CustomMeleeAttack(random(50, 140), "butcher/melee", ""); }
		Goto See;
	Missile.T12:
		"JUGG" A 0 A_JumpIfCloser(120, "Melee.T12");
		TNT1 A 0 A_Jump(256, "Missile.T12.Quake", "Missile.T12.Rocks");
		Goto See;
	Missile.T12.Quake:
		"JUGG" EF 8 Bright { A_FaceTarget(); }
		"JUGG" G 0 { A_QuakeEx(3, 3, 3, 30, 0, 512); }
		"JUGG" G 4 Bright { A_SpawnProjectile("RS_MolochQuake", 16, 0, 0, CMF_AIMDIRECTION, random(0, 360)); }
		"JUGG" G 4 Bright { A_SpawnProjectile("RS_MolochQuake", 16, 0, 90, CMF_ABSOLUTEANGLE); }
		"JUGG" G 4 Bright { A_SpawnProjectile("RS_MolochQuake", 16, 0, 180, CMF_ABSOLUTEANGLE); }
		"JUGG" G 4 Bright { A_SpawnProjectile("RS_MolochQuake", 16, 0, 270, CMF_ABSOLUTEANGLE); }
		"JUGG" G 8 A_MonsterRefire(40, "See");
		Goto See;
	Missile.T12.Rocks:
		"JUGG" EF 8 { A_FaceTarget(); }
		"JUGG" G 5 Bright { A_SpawnProjectile("RS_WDRock1", 24, 0, random(-6, 6)); }
		"JUGG" G 5 Bright { A_SpawnProjectile("RS_WDRock2", 24, 0, random(-6, 6)); }
		"JUGG" G 5 Bright { A_SpawnProjectile("RS_WDRock3", 24, 0, random(-9, 9)); }
		"JUGG" G 8 A_MonsterRefire(40, "See");
		Goto See;
	Pain.T12:
		"JUGG" H 2;
		"JUGG" H 2 { A_Pain(); }
		Goto See;
	Death.T12:
		// CH plays "Juggernaut/Thud" on frame N -- no SNDINFO lump in
		// this repo, sound omitted.
		"JUGG" K 6 { A_Scream(); }
		"JUGG" LM 6;
		"JUGG" N 6;
		"JUGG" O 6 { A_NoBlocking(); }
		"JUGG" P 6;
		"JUGG" Q -1;
		Stop;
	}
}
