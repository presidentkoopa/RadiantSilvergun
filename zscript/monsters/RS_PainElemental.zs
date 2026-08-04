// =====================================================================
// RS_PainElemental -- per-tier state rebuild
// (docs/rs_09_monster_rebuild_spec.txt). Replaces PainElemental.
//
// THIRTEEN REAL CREATURES, ported from CH decorate/thepains.txt via
// the proven HF port:
//
//   T00 PAIN vanilla soul spit    T01 PAIN+tint eager soul spit
//   T02 PAIN+tint plasma, or a soul
//   T03 INFR twin ice orbs        T04 TORT double soul spit
//   T05 INFR lavaballs, or a soul T06 AYPE abyss: coil+volley far,
//                                       pulse close
//   T07 PAIN+tint twin boom shots T08 FLSP twin brown shots
//   T09 INFR heavy lavaballs      T10 TORT corpse breath / spike bomb
//                                       / soul
//   T11 OVER THE OVERLORD -- storm shots / over-balls / bee swarms,
//       close-range triple
//   T12 WATC the Watcher: seeker triples, souls, and REAL tiered
//       lost-soul summons
//
// RS mechanics preserved: the maintained sentinel escort (T06+, grows
// at T09+), the T11+ DeathMorphClass into RS_PainPilot, the ring-burst
// attack slots. The escort runs from Tick exactly as before.
//
// SPRITE NOTE (verified on disk): INFR ships no F frame -- E stands in
// where CH's choreography said F. AYPE ships A-F+XY only.
// =====================================================================

class RS_PainElemental : RS_MonsterMaster replaces PainElemental
{
	const RS_PE_TIER_ESCORT = 6;
	const RS_PE_TIER_HEAVY  = 9;
	const RS_PE_TIER_PILOT  = 11;

	const RS_PE_CHECK_INTERVAL = 70;   // 2s between escort headcounts

	private int rsNextEscortCheck;

	Default
	{
		Health 400;
		Radius 31;
		Height 56;
		Mass 400;
		Speed 8;
		PainChance 128;
		Monster;
		+FLOAT +NOGRAVITY
		SeeSound "pain/sight";   PainSound "pain/pain";
		DeathSound "pain/death"; ActiveSound "pain/active";
		Tag "Pain Elemental";
	}

	// Audit data -- the clusters below are the live implementation.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "PAIN PAIN PAIN INFR TORT INFR AYPE PAIN FLSP INFR TORT OVER WATC";
	}

	override string TintTable()
	{
		return "- rs_pain_t01 rs_pain_t02 rs_pain_t03 rs_pain_t04 rs_pain_t05 "
		       "- rs_pain_t07 rs_pain_t08 rs_pain_t09 rs_pain_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:painelemental role:summoner delivery:heavy element:thermal mobility:floating";
	}

	// The escort explicitly does NOT die with the summoner -- CHP goes
	// both ways on this and here the sentinels outliving their parent is
	// the better fight: killing the elemental doesn't instantly clear
	// the room, you still have to mop up.
	override bool MinionsDieWithMe()
	{
		return false;
	}

	// Death is a phase change at high tier only. Below that it just dies.
	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_PE_TIER_PILOT) ? RS_MonsterCatalog.MORPH_PainPilot() : null;
	}

	int EscortSize()
	{
		if (Tier >= RS_PE_TIER_HEAVY)  return 3;
		if (Tier >= RS_PE_TIER_ESCORT) return 2;
		return 0;
	}

	// -----------------------------------------------------------------
	// THE MAINTAINED ESCORT.
	// A headcount on a throttle, not every tic. If we're short, top up
	// by one -- one at a time, so a wiped escort refills visibly rather
	// than popping back in a single frame.
	// -----------------------------------------------------------------
	private void RS_TickEscort()
	{
		int want = EscortSize();
		if (want <= 0 || health <= 0)
			return;

		if (level.time < rsNextEscortCheck)
			return;
		rsNextEscortCheck = level.time + RS_PE_CHECK_INTERVAL;

		Class<Actor> cls = RS_MonsterCatalog.MINION_Sentinel();
		if (CountLiveMinions(cls) >= want)
			return;

		if (SummonMinion(cls, -2, 88.0, 16.0))
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	override void Tick()
	{
		Super.Tick();
		RS_TickEscort();
	}

	States
	{
	// ===== PAIN body: T00 T01 T02 T07 =====
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T07:
		"PAIN" A 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T07:
		"PAIN" AABBCC 3 { A_Chase(); }
		Loop;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T07:
		"PAIN" G 6;
		"PAIN" G 6 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T07:
		"PAIN" H 8 Bright;
		"PAIN" I 8 Bright { A_Scream(); }
		"PAIN" JK 8 Bright;
		"PAIN" L 8 Bright { A_PainDie(); }
		"PAIN" M 8 Bright { A_NoBlocking(); }
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
	Raise.T07:
		"PAIN" MLKJIH 8;
		Goto See;

	// T00 -- vanilla soul spit
	Missile.T00:
		"PAIN" D 5 { A_FaceTarget(); }
		"PAIN" DE 5 { A_FaceTarget(); }
		"PAIN" F 5 Bright { A_PainAttack(); }
		Goto See;

	// T01 GREEN -- quicker spit cadence
	Missile.T01:
		"PAIN" D 4 { A_FaceTarget(); }
		"PAIN" DE 4 { A_FaceTarget(); }
		"PAIN" F 5 Bright { A_PainAttack(); }
		Goto See;

	// T02 BLUE -- plasma pulses, or a soul
	Missile.T02:
		"PAIN" D 5 { A_FaceTarget(); }
		"PAIN" DE 5 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(128, "Missile.T02.Soul");
		"PAIN" F 5 Bright { A_SpawnProjectile("RS_PlasmaPE", 0, 0, 0); }
		"PAIN" F 4 Bright { A_SpawnProjectile("RS_PlasmaPE", 0, 0, random(-6, 6)); }
		Goto See;
	Missile.T02.Soul:
		"PAIN" F 5 Bright { A_PainAttack(); }
		Goto See;

	// T07 FIREBLU -- twin boom shots
	Missile.T07:
		"PAIN" D 5 { A_FaceTarget(); }
		"PAIN" DE 5 { A_FaceTarget(); }
		"PAIN" F 4 Bright { A_SpawnProjectile("RS_BoomPEBlu", 0, 0, random(-4, 4)); }
		"PAIN" F 4 Bright { A_SpawnProjectile("RS_BoomPEBlu", 0, 0, random(-4, 4)); }
		Goto See;

	// ===== INFR body: T03 ice, T05 lava, T09 heavy lava.
	// INFR has no F frame on disk -- E carries the cast. =====
	Spawn.T03:
	Spawn.T05:
	Spawn.T09:
		"INFR" A 10 { A_Look(); }
		Loop;
	See.T03:
	See.T05:
	See.T09:
		"INFR" AABBCC 3 { A_Chase(); }
		Loop;
	Missile.T03:
		"INFR" D 5 { A_FaceTarget(); }
		"INFR" DE 5 { A_FaceTarget(); }
		"INFR" E 4 Bright { A_SpawnProjectile("RS_IceOrbCyanAra1", 0, 0, random(-5, 5)); }
		"INFR" E 4 Bright { A_SpawnProjectile("RS_IceOrbCyanAra2", 0, 0, random(-5, 5)); }
		Goto See;
	Missile.T05:
		"INFR" D 5 { A_FaceTarget(); }
		"INFR" DE 5 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(112, "Missile.T05.Soul");
		"INFR" E 4 Bright { A_SpawnProjectile("RS_LavaballPE", 0, 0, random(-5, 5)); }
		"INFR" E 4 Bright { A_SpawnProjectile("RS_LavaballPE", 0, 0, random(-5, 5)); }
		Goto See;
	Missile.T05.Soul:
		"INFR" E 5 Bright { A_PainAttack(); }
		Goto See;
	// T09 GRAY -- the escort is the identity at this tier; the gun is a
	// heavier lava volley plus the ring from the attack slot.
	Missile.T09:
		"INFR" D 5 { A_FaceTarget(); }
		"INFR" DE 5 { A_FaceTarget(); }
		"INFR" E 5 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T03:
	Pain.T05:
	Pain.T09:
		"INFR" G 6;
		"INFR" G 6 { A_Pain(); }
		Goto See;
	Death.T03:
	Death.T05:
	Death.T09:
		"INFR" H 8 Bright { A_Scream(); }
		"INFR" IJ 8 Bright;
		"INFR" K 8 Bright { A_PainDie(); }
		"INFR" K 8 Bright { A_NoBlocking(); }
		Stop;

	// ===== TORT body: T04 double spit, T10 corpse breath =====
	Spawn.T04:
	Spawn.T10:
		"TORT" A 10 { A_Look(); }
		Loop;
	See.T04:
	See.T10:
		"TORT" AABBCC 3 { A_Chase(); }
		Loop;
	Missile.T04:
		"TORT" D 5 { A_FaceTarget(); }
		"TORT" DE 5 { A_FaceTarget(); }
		"TORT" F 4 Bright { A_PainAttack(); }
		"TORT" F 4 Bright { A_PainAttack(); }
		Goto See;
	Missile.T10:
		"TORT" D 5 { A_FaceTarget(); }
		"TORT" DE 5 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(80, "Missile.T10.Bomb");
		TNT1 A 0 A_Jump(96, "Missile.T10.Soul");
		"TORT" F 4 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 0, 0, random(-7, 7)); }
		"TORT" F 4 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 0, 0, random(-7, 7)); }
		"TORT" F 4 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 0, 0, random(-7, 7)); }
		Goto See;
	Missile.T10.Bomb:
		"TORT" F 8 Bright { A_SpawnProjectile("RS_SbombPE", 0, 0, 0); }
		Goto See;
	Missile.T10.Soul:
		"TORT" F 5 Bright { A_PainAttack(); }
		Goto See;
	Pain.T04:
	Pain.T10:
		"TORT" G 6;
		"TORT" G 6 { A_Pain(); }
		Goto See;
	Death.T04:
	Death.T10:
		"TORT" H 8 Bright;
		"TORT" I 8 Bright { A_Scream(); }
		"TORT" JK 8 Bright;
		"TORT" L 8 Bright { A_PainDie(); }
		"TORT" M 8 Bright { A_NoBlocking(); }
		Stop;

	// ===== T06 ABYSS (AYPE): coil + volley far, pulse close.
	// AYPE ships A-F plus X/Y only -- pain uses E, death uses XY. =====
	Spawn.T06:
		"AYPE" A 10 { A_Look(); }
		Loop;
	See.T06:
		"AYPE" AABBCC 3 { A_Chase(); }
		Loop;
	Missile.T06:
		"AYPE" D 5 { A_FaceTarget(); }
		"AYPE" DE 5 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(700, "Missile.T06.Pulse");
		"AYPE" F 4 Bright { A_SpawnProjectile("RS_AbyPECoil", 0, 0, random(-5, 5)); }
		"AYPE" F 4 Bright { A_SpawnProjectile("RS_VollreyAbyPE", 0, 0, random(-8, 8)); }
		"AYPE" F 4 Bright { A_SpawnProjectile("RS_VollreyAbyPE", 0, 0, random(-8, 8)); }
		Goto See;
	Missile.T06.Pulse:
		"AYPE" F 6 Bright { A_SpawnProjectile("RS_AbyssPEPulse", 0, 0, 0); }
		"AYPE" F 4 Bright { A_SpawnProjectile("RS_AbyPECoil", 0, 0, random(-12, 12)); }
		Goto See;
	Pain.T06:
		"AYPE" E 6;
		"AYPE" E 6 { A_Pain(); }
		Goto See;
	Death.T06:
		"AYPE" X 8 Bright { A_Scream(); }
		"AYPE" X 8 Bright { A_PainDie(); }
		"AYPE" Y 8 Bright { A_NoBlocking(); }
		"AYPE" Y 8 Bright;
		Stop;

	// ===== T08 BROWN (FLSP): twin brown shots =====
	Spawn.T08:
		"FLSP" A 10 { A_Look(); }
		Loop;
	See.T08:
		"FLSP" AABBCC 3 { A_Chase(); }
		Loop;
	Missile.T08:
		"FLSP" D 5 { A_FaceTarget(); }
		"FLSP" DE 5 { A_FaceTarget(); }
		"FLSP" F 4 Bright { A_SpawnProjectile("RS_BrownPEShot", 0, 0, random(-5, 5)); }
		"FLSP" F 4 Bright { A_SpawnProjectile("RS_BrownPEShot", 0, 0, random(-5, 5)); }
		Goto See;
	Pain.T08:
		"FLSP" G 6;
		"FLSP" G 6 { A_Pain(); }
		Goto See;
	Death.T08:
		"FLSP" H 8 Bright;
		"FLSP" I 8 Bright { A_Scream(); }
		"FLSP" JK 8 Bright;
		"FLSP" L 8 Bright { A_PainDie(); }
		"FLSP" M 8 Bright { A_NoBlocking(); }
		Stop;

	// ===== T11 BLACK -- THE OVERLORD (OVER). Three ranged patterns
	// plus a close-range triple. =====
	Spawn.T11:
		"OVER" A 10 { A_Look(); }
		Loop;
	See.T11:
		"OVER" AABBCC 3 { A_Chase(); }
		Loop;
	Missile.T11:
		TNT1 A 0 A_JumpIfCloser(450, "Missile.T11.Close");
		TNT1 A 0 A_Jump(256, "Missile.T11.Storm", "Missile.T11.Balls", "Missile.T11.Bees");
		Goto See;
	Missile.T11.Storm:
		"OVER" D 8 Bright { A_FaceTarget(); }
		"OVER" E 0 { A_SpawnItemEx("RS_LoadPE3", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"OVER" F 6 Bright { A_SpawnProjectile("RS_StormShot1", 0, 8, random(-3, 3)); }
		"OVER" F 4 Bright { A_SpawnProjectile("RS_StormShot1", 0, -8, random(-3, 3)); }
		"OVER" D 8 A_MonsterRefire(40, "See");
		Goto See;
	Missile.T11.Balls:
		"OVER" D 6 { A_FaceTarget(); }
		"OVER" F 4 Bright { A_SpawnProjectile("RS_OverBall3", 0, 0, random(-6, 6)); }
		"OVER" F 4 Bright { A_SpawnProjectile("RS_HadesBall4", 0, 0, random(-8, 8)); }
		"OVER" F 4 Bright { A_SpawnProjectile("RS_OverBall3", 0, 0, random(-6, 6)); }
		"OVER" D 6 A_MonsterRefire(40, "See");
		Goto See;
	Missile.T11.Bees:
		"OVER" D 8 Bright { A_FaceTarget(); }
		"OVER" F 6 Bright { A_SpawnProjectile("RS_BEESHOT", 0, 0, random(-12, 12)); }
		"OVER" F 6 Bright { A_SpawnProjectile("RS_BEESHOT", 0, 0, random(-12, 12)); }
		"OVER" E 6 Bright { A_PainAttack(); }
		"OVER" D 8 A_MonsterRefire(40, "See");
		Goto See;
	Missile.T11.Close:
		"OVER" F 3 Bright { A_SpawnProjectile("RS_OverBall3", 0, 0, random(-15, 15)); }
		"OVER" F 3 Bright { A_SpawnProjectile("RS_HadesBall4", 0, 0, random(-15, 15)); }
		"OVER" F 3 Bright { A_SpawnProjectile("RS_OverBall3", 0, 0, random(-15, 15)); }
		Goto See;
	Pain.T11:
		"OVER" G 6;
		"OVER" G 6 { A_Pain(); }
		Goto See;
	Death.T11:
		"OVER" H 8 Bright;
		"OVER" I 8 Bright { A_Scream(); }
		"OVER" JK 8 Bright;
		"OVER" L 8 Bright { A_PainDie(); }
		"OVER" M 8 Bright { A_NoBlocking(); }
		Stop;

	// ===== T12 WHITE -- the Watcher (WATC). Seekers, souls, and REAL
	// tiered lost-soul summons through the pack system. =====
	Spawn.T12:
		"WATC" A 10 { A_Look(); }
		Loop;
	See.T12:
		"WATC" AABBCC 3 { A_Chase(); }
		Loop;
	Missile.T12:
		"WATC" D 6 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(140, "Missile.T12.Summon");
		TNT1 A 0 A_Jump(96, "Missile.T12.Soul");
		"WATC" F 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 0, 0, random(-5, 5)); }
		"WATC" F 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 0, 0, random(-5, 5)); }
		"WATC" F 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 0, 0, random(-5, 5)); }
		"WATC" D 8 A_MonsterRefire(40, "See");
		Goto See;
	Missile.T12.Summon:
		"WATC" DE 6 Bright { A_FaceTarget(); }
		"WATC" F 6 Bright
		{
			if (SummonPack("RS_LostSoul", 2, 3, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		"WATC" E 6 Bright;
		Goto See;
	Missile.T12.Soul:
		"WATC" F 6 Bright { A_PainAttack(); }
		"WATC" F 6 Bright { A_PainAttack(); }
		Goto See;
	Pain.T12:
		"WATC" G 6;
		"WATC" G 6 { A_Pain(); }
		Goto See;
	Death.T12:
		"WATC" H 8 Bright;
		"WATC" I 8 Bright { A_Scream(); }
		"WATC" JK 8 Bright;
		"WATC" L 8 Bright { A_PainDie(); }
		"WATC" M 8 Bright { A_NoBlocking(); }
		Stop;
	}
}

// =====================================================================
// RS_PainPilot -- what was actually flying the thing.
// ---------------------------------------------------------------------
// Stage two. Smaller, much faster, no longer summons -- it trades the
// escort for raw aggression, so the fight changes character rather than
// just repeating with a second health bar. Data-driven attack at every
// tier, so one cluster set serves the ladder; bare #### keeps whatever
// body the tier dressed it in (SKUL-layout frames exist on every body
// in its table).
// =====================================================================

class RS_PainPilot : RS_MonsterMaster
{
	Default
	{
		Health 350;
		Radius 20;
		Height 40;
		Mass 200;
		Speed 16;
		PainChance 60;
		Monster;
		+FLOAT +NOGRAVITY +MISSILEMORE
		RenderStyle "Add";
		Alpha 0.95;
		SeeSound "pain/sight";   PainSound "pain/pain";
		DeathSound "pain/death"; ActiveSound "pain/active";
		Tag "Pain Elemental (Pilot)";
	}

	override string BodyTable()
	{
		// BOSF (old T08) exists nowhere in ART SOURCE -- SKUL stands in,
		// same substitution as the sentinel's.
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
		return "species:painelemental role:skirmisher delivery:heavy element:thermal mobility:flying trait:secondstage";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		// Three fast shots then a spread -- a pressure pattern, since it
		// no longer has minions doing the pressuring for it.
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainPulse(), 1, 0.0, "pain/attack", 1.0, 0.0, "Bolt"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainPulse(), 1, 0.0, "pain/attack", 1.0, 0.0, "Bolt"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainStorm(), 5, 50.0, "pain/attack", 1.0, 4.0, "Fan"));
		return slot;
	}

	States
	{
	// WASP (T11) has only frames A-D; every other body in the table
	// carries the SKUL layout A-J. The T11 cluster is bespoke; the rest
	// share one #### set seeded per tier by Spawn's literal.
	Spawn.T00:
		"SKUL" AB 6 Bright { A_Look(); }
		Loop;
	Spawn.T03:
		"LFX1" AB 6 Bright { A_Look(); }
		Loop;
	Spawn.T05:
	Spawn.T10:
		"FRGO" AB 6 Bright { A_Look(); }
		Loop;
	Spawn.T06:
		"BST7" AB 6 Bright { A_Look(); }
		Loop;
	Spawn.T12:
		"ETHS" AB 6 Bright { A_Look(); }
		Loop;
	See.T00:
		#### AB 4 Bright { A_Chase(); }
		Loop;
	Missile.T00:
		#### C 6 Bright { A_FaceTarget(); }
		#### D 6 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T00:
		#### E 3 Bright;
		#### E 3 Bright { A_Pain(); }
		Goto See;
	Death.T00:
		#### F 6 Bright;
		#### G 6 Bright { A_Scream(); }
		#### H 6 Bright { A_NoBlocking(); }
		#### IJ 6 Bright;
		Stop;

	// T11 hornet pilot -- four frames, bespoke.
	Spawn.T11:
		"WASP" AB 6 Bright { A_Look(); }
		Loop;
	See.T11:
		"WASP" ABCD 3 Bright { A_Chase(); }
		Loop;
	Missile.T11:
		"WASP" C 6 Bright { A_FaceTarget(); }
		"WASP" D 6 Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain.T11:
		"WASP" A 3 Bright;
		"WASP" A 3 Bright { A_Pain(); }
		Goto See;
	Death.T11:
		"WASP" C 5 Bright { A_Scream(); }
		"WASP" D 5 Bright { A_NoBlocking(); }
		"WASP" DD 4 Bright A_FadeOut(0.25);
		Stop;
	}
}
