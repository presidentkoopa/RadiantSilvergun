// =====================================================================
// RS_Revenant -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\08\08_<code>.txt
// One CHP file per colour; the FIRST actor in each file is that colour's
// revenant. Each is a genuinely different creature with its OWN sprite
// set, stats and attack -- nothing here is inferred or tinted.
//
//   tier  CHP   body   HP    what it actually is
//   T00   08_C  SKEL   300   vanilla revenant, twin homing tracers
//   T01   08_G  REVG   360   green: homing acid, drips acid as it walks
//   T02   08_B  SKEB   420   blue: falcon-punch dash inside 300, or a
//                            seven-bolt zap barrage (dash on a budget)
//   T03   08_CY SREV   480   cyan: ice-orb triples or a twin ice bomb,
//                            leaps around the arena, shatters on death
//   T04   08_P  REVP   515   purple: dash / twin bolts / DOUBLE RAILGUN,
//                            crackling with Zap99 the whole time
//   T05   08_Y  REVN   666   yellow TERROR: hellflame channel, homing
//                            pair, or (in its fast form) a fire spit
//   T06   08_A  REVA  1000   abyss: cracked-abyss bolts, a hop-and-spray
//                            ice fan, and a phase-dash on pain
//   T07   08_F  REVF   720   fireblu: four-stage weaving barrage far out,
//                            a 14-way ring up close, exploding punch
//   T08   08_BR INCA   666   brown mummy: gas trail, twin brown balls,
//                            heals the pack when it gibs
//   T09   08_GY ZKEL   760   gray MIKE TYSON: two-fisted combo, thrown
//                            bones, and a 45-speed charge
//   T10   08_R  RASK   830   red: charges a MegaRedRev every 4 shots;
//                            pain locks NOPAIN + MISSILEEVENMORE on
//   T11   08_K  DKNT  4500   THE BLACK KNIGHT: dart cleave, mines, dash,
//                            a reflective shield -- and it does not die
//                            the first time (see the chain below)
//   T12   08_W  REVW  8866   THE LICH: death coils, ice bolts, frost
//                            mines, ground channels, and it summons
//   TEX   08_KX DKNT  7500   THE BLACK KNIGHT UNLEASHED: the T11 knight
//                            with a range-split roster -- a nine-dart
//                            cleave, four looping mines, a 32-shot shield
//                            blast, a grapple hook, and a pain answer that
//                            raises BOTH shield discs. Dies into the same
//                            shade chain, at CHP's EX3/EX4 numbers.
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and are
// applied through TierData below, replacing the generic ladder.
//
// TEX SOURCE: CHP 08_KX.txt, ACTOR CommonBlackRevenantEX2 (the first
// actor in the file), parent CH Revenants.txt BlackRevenantEX for the
// properties CHP does not restate.
//
// TEX CHP properties with no TierData channel, recorded rather than
// silently dropped: MeleeRange 80, Mass 3000, Scale 1.2,
// RadiusDamageFactor 0.33 and the Fire/Poison/Ice damage factors.
// The row carries Health / Speed / PainChance / damage only.
//
// Where CHP left something undefined it came from the CH parent:
//   T09 PainChance <- CH Revenants.txt GrayRevenant2, which sets no
//       PainChance and carries +NOPAIN: effectively 0. CHP still defines
//       a Pain state, so the cluster is ported and simply unreachable.
//
// NOT PORTED (with reason):
//   * NewIcon*/ColorTierIcon* spawns, A_GivetoChildren, CHWhitePlan /
//     "Tickles", "Grow"/GrowRaisin promotion + ArchRingHelp,
//     Death.Nocorpse, CHRandom_GibGenerator, RandomLetterSpawner,
//     A_SpawnParticle walls, ACS_NamedExecuteAlways announcers.
//   * T05's Scripted block: all three branches are chosen by
//     CallACS("CH_YellowRev"), which is stripped. CHP's own no-script
//     fallback (Script2) is a 50/50 coin flip between Script1 (the fast
//     speed-24 form, which is what unlocks SpitIt) and Script3, so that
//     coin flip is what Spawn.T05 does -- both attack paths stay live.
//     Script3's SpecialSoulCheck spawns are ACS-driven and dropped.
//   * T03's CallACS CH_CyanBounce guard on the leap -- ACS. The leap it
//     guards IS ported.
//   * [REVERSED 2026-08-04 -- this entry was WRONG. Corrected in place
//     rather than deleted: a deleted claim gets rediscovered.]
//     T08's A_RadiusGive("RevSpeedBuff2") was dropped because "the CH
//     item's whole body is ACS_NamedExecute("BrownRevSPEED2"), so porting
//     it imports nothing." The body is empty BECAUSE the behaviour is in
//     the ACS: BrownRevSPEED2 DOUBLES the recipient's speed for 210 tics.
//     Rebuilt as RS_RevSpeedBuff in RS_MonsterCommands.zs and wired back
//     into See.T08 (twice per walk cycle, radius 256) and XDeath.T08
//     (radius 1200), exactly where CHP 08_BR.txt:32,37,74 has them.
//     Only the heal half of the gib rally had survived. See
//     docs/rs_19_acs_inventory.txt.
//   * T07's A_SpawnItemEx("FBSkelOnFire_C") on spawn -- that actor does
//     not exist anywhere in CH or CHP (searched both decorate trees).
//     REPORTED, not substituted.
//   * Pain.Fire / Pain.Ice / Pain.Melee sub-states on T05/T06/T07/T11 --
//     the tier dispatch has no per-damage-type channel.
// =====================================================================

class RS_Revenant : RS_MonsterMaster replaces Revenant
{
	// CHP user vars, re-expressed as private fields (no A_SetUserVar).
	private int rsNoDash1;   // 08_B  User_nodash1
	private int rsNoDash2;   // 08_P  User_nodash2
	private int rsCharge;    // 08_R  User_TTT
	private int rsFastForm;  // 08_Y  Script1 vs Script3
	private int rsEnraged;   // 08_W  User_Enrage

	Default
	{
		Health 300;
		Radius 20;
		Height 56;
		Mass 500;
		Speed 10;
		PainChance 100;
		MeleeRange 64;
		Monster;
		+FLOORCLIP MissileChanceMult 0.5;
		SeeSound "skeleton/sight";   PainSound "skeleton/pain";
		DeathSound "skeleton/death"; ActiveSound "skeleton/active";
		MeleeSound "skeleton/melee";
		Obituary "$OB_UNDEAD";
		HitObituary "$OB_UNDEADHIT";
		Tag "Revenant";
	}

	// CHP's real per-colour numbers, read from 08_*.txt. Default Health is
	// 300 and Default Speed 10, so the absolute numbers are expressed as
	// multipliers to keep the base class's recompute-from-defaults
	// contract intact.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 100; r.dmgMul = 1.0;
		int hp = 300; int spd = 10;
		switch (t)
		{
			case 0:  hp = 300;  spd = 10; r.painChance = 100; r.dmgMul = 1.0; break;
			case 1:  hp = 360;  spd = 11; r.painChance = 88;  r.dmgMul = 1.1; break;
			case 2:  hp = 420;  spd = 12; r.painChance = 77;  r.dmgMul = 1.2; break;
			case 3:  hp = 480;  spd = 14; r.painChance = 120; r.dmgMul = 1.3; break;
			case 4:  hp = 515;  spd = 13; r.painChance = 66;  r.dmgMul = 1.4; break;
			case 5:  hp = 666;  spd = 7;  r.painChance = 30;  r.dmgMul = 1.6; break;
			case 6:  hp = 1000; spd = 11; r.painChance = 76;  r.dmgMul = 1.7; break;
			case 7:  hp = 720;  spd = 6;  r.painChance = 12;  r.dmgMul = 1.6; break;
			case 8:  hp = 666;  spd = 12; r.painChance = 120; r.dmgMul = 1.5; break;
			case 9:  hp = 760;  spd = 18; r.painChance = 0;   r.dmgMul = 1.7; break;
			case 10: hp = 830;  spd = 14; r.painChance = 22;  r.dmgMul = 1.9; break;
			case 11: hp = 4500; spd = 10; r.painChance = 64;  r.dmgMul = 2.6; break;
			case 12: hp = 8866; spd = 23; r.painChance = 255; r.dmgMul = 3.2; break;
			// TEX -- CHP 08_KX CommonBlackRevenantEX2's own numbers.
			case 13: hp = 7500; spd = 14; r.painChance = 32;  r.dmgMul = 4.0; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 300.0;
		r.spdMul = double(spd) / 10.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		// TEX wears DKNT too -- CHP's EX knight is the T11 knight, not a
		// new sprite set. The same token twice is correct.
		return "SKEL REVG SKEB SREV REVP REVN REVA REVF INCA ZKEL RASK DKNT REVW DKNT";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap.
	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:revenant role:artillery delivery:heavy delivery:melee element:kinetic mobility:ground trait:homing";
	}

	// -----------------------------------------------------------------
	// THE BLACK KNIGHT CHAIN (named RS mechanic, preserved). CHP's black
	// revenant does not die once: 08_K's CommonBlackRevenant3 Death ends
	// with A_SpawnItemEx("CommonBlackRev2") -- the wraith gets back up.
	// DeathMorphClass is the RS wiring for exactly that spawn, so the
	// inline spawn is not duplicated here.
	// -----------------------------------------------------------------
	const RS_REV_TIER_CHAIN = 11;

	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_REV_TIER_CHAIN) ? RS_MonsterCatalog.MORPH_RevShade() : null;
	}

	States
	{
	// ================= T00 COMMON (08_C) =================
	Spawn.T00:
		"SKEL" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"SKEL" AABBCCDDEEFF 2 { A_Chase(); }
		Loop;
	Melee.T00:
		"SKEL" G 1 { A_FaceTarget(); }
		"SKEL" G 6 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"SKEL" H 6 { A_FaceTarget(); }
		"SKEL" I 6 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		Goto See;
	Missile.T00:
		"SKEL" J 10 Bright { A_FaceTarget(); }
		"SKEL" J 9;
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracer2", 50, 7, 1); }
		"SKEL" K 0 { A_SpawnProjectile("RS_RevenantTracer2", 50, -7, -1); }
		"SKEL" K 10 { A_FaceTarget(); }
		Goto See;
	Pain.T00:
		"SKEL" L 5;
		"SKEL" L 5 { A_Pain(); }
		Goto See;
	Death.T00:
		"SKEL" LM 7;
		"SKEL" N 7 { A_Scream(); }
		"SKEL" O 7 { A_NoBlocking(); }
		"SKEL" P 7;
		"SKEL" Q -1;
		Stop;
	XDeath.T00:
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 AAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-2, 2), random(-2, 2), random(26, 34)); }
		TNT1 A 0 { A_SetTranslucent(0.1); }
		"REVB" A 1 ThrustThingZ(0, 45, 0, 0);
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"REVB" A 5 { A_Scream(); }
		"REVB" A 5 { A_SetTranslucent(0.35); }
		"REVB" A 5 { A_NoBlocking(); }
		"REVB" A 5 { A_SetTranslucent(0.7); }
		"REVB" A 8 { A_SetTranslucent(1); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"REVB" A -1;
		Stop;
	Raise.T00:
		"SKEL" Q 5;
		"SKEL" PONML 5;
		Goto See;

	// ================= T01 GREEN (08_G) =================
	// Trails acid everywhere it goes; its tracers are homing acid.
	Spawn.T01:
		"REVG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"REVG" AABBCCDDEEFF 2 { A_Chase(); }
		"REVG" AA 0 { A_SpawnItemEx("RS_Splash11", random(-5, 5), random(-5, 5), random(5, 56)); }
		Loop;
	Melee.T01:
		"REVG" G 3 { A_FaceTarget(); }
		"REVG" GG 0 { A_SpawnItemEx("RS_Splash11", random(-5, 5), random(-5, 5), random(5, 56)); }
		"REVG" G 6 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"REVG" H 6 { A_FaceTarget(); }
		"REVG" I 6 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		Goto See;
	Missile.T01:
		"REVG" J 9 Bright { A_FaceTarget(); }
		"REVG" JJ 0 { A_SpawnItemEx("RS_Splash11", random(-5, 5), random(-5, 5), random(5, 56)); }
		"REVG" J 7;
		"REVG" K 0 { A_SpawnProjectile("RS_AcidBlast1", 50, 7, 1); }
		"REVG" K 0 { A_SpawnProjectile("RS_AcidBlast1", 50, -7, -1); }
		"REVG" K 8 { A_FaceTarget(); }
		Goto See;
	Pain.T01:
		"REVG" L 5;
		"REVG" LL 0 { A_SpawnItemEx("RS_Splash11", random(-5, 5), random(-5, 5), random(5, 56)); }
		"REVG" L 5 { A_Pain(); }
		Goto See;
	Death.T01:
		"REVG" LM 7;
		"REVG" N 7 { A_Scream(); }
		"REVG" N 0 { A_SpawnItemEx("RS_Splash11", random(-5, 5), random(-5, 5), random(5, 56)); }
		"REVG" O 7 { A_NoBlocking(); }
		"REVG" P 7;
		"REVG" P 0 { A_SpawnItemEx("RS_Splash11", random(-5, 5), random(-5, 5), random(5, 56)); }
		"REVG" Q -1;
		Stop;
	XDeath.T01:
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 0 { A_SetTranslucent(0.1); }
		"REVB" B 1 ThrustThingZ(0, 45, 0, 0);
		"REVB" B 5 { A_Scream(); }
		"REVB" B 5 { A_SetTranslucent(0.35); }
		"REVB" B 5 { A_NoBlocking(); }
		"REVB" B 5 { A_SetTranslucent(0.7); }
		"REVB" B 8 { A_SetTranslucent(1); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"REVB" B -1;
		Stop;
	Raise.T01:
		"REVG" Q 5;
		"REVG" PONML 5;
		Goto See;

	// ================= T02 BLUE (08_B) =================
	// Falcon-punch dash inside 300 on a dash budget, else a seven-bolt
	// zap barrage that pays the budget back down.
	Spawn.T02:
		"SKEB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"SKEB" AABBCCDDEEFF 2 { A_Chase(); }
		Loop;
	Melee.T02:
		"SKEB" G 3 { A_FaceTarget(); }
		"SKEB" G 5 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"SKEB" H 5 { A_FaceTarget(); }
		"SKEB" I 4 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		Goto See;
	Missile.T02:
		"SKEB" G 4 { A_FaceTarget(); }
		"SKEB" G 0 A_JumpIfCloser(300, "Missile.T02.Falcon");
		"SKEB" G 0 A_Jump(256, "Missile.T02.Blastings");
		Goto See;
	Missile.T02.Falcon:
		"SKEB" G 0 { if (rsNoDash1 >= 11) return ResolveState("Missile.T02.Blastings"); rsNoDash1 += 5; return ResolveState(null); }
		"SKEB" G 2 Bright { A_SkullAttack(30); }
		Goto Melee;
	Missile.T02.Blastings:
		"SKEB" J 12 Bright { A_FaceTarget(); }
		"SKEB" J 5;
		"SKEB" K 0 { A_SpawnProjectile("RS_Zap7", 50, 7, random(0, 2)); }
		"SKEB" K 0 { A_SpawnProjectile("RS_Zap7", 50, -7, random(-2, 0)); }
		"SKEB" J 12 Bright { A_FaceTarget(); }
		"SKEB" K 0 { A_SpawnProjectile("RS_Zap8", 50, -7, random(4, 7)); }
		"SKEB" K 0 { A_SpawnProjectile("RS_Zap8", 50, 7, random(-7, -4)); }
		"SKEB" K 0 { A_SpawnProjectile("RS_Zap8", 50, -7, random(4, 7)); }
		"SKEB" K 0 { A_SpawnProjectile("RS_Zap8", 50, 7, random(-7, -4)); }
		"SKEB" K 0 { A_SpawnProjectile("RS_Zap8", 50, -7, random(-7, 7)); }
		"SKEB" G 0 { rsNoDash1 = max(0, rsNoDash1 - 2); }
		"SKEB" K 8 { A_FaceTarget(); }
		Goto See;
	Pain.T02:
		"SKEB" L 5;
		"SKEB" L 5 { A_Pain(); }
		Goto See;
	Death.T02:
		"SKEB" LM 7;
		"SKEB" N 7 { A_Scream(); }
		"SKEB" O 7 { A_NoBlocking(); }
		"SKEB" P 7;
		"SKEB" Q -1;
		Stop;
	XDeath.T02:
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 0 { A_SetTranslucent(0.1); }
		"REVB" C 1 ThrustThingZ(0, 45, 0, 0);
		"REVB" C 5 { A_Scream(); }
		"REVB" C 5 { A_SetTranslucent(0.35); }
		"REVB" C 5 { A_NoBlocking(); }
		"REVB" C 5 { A_SetTranslucent(0.7); }
		"REVB" C 8 { A_SetTranslucent(1); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"REVB" C -1;
		Stop;
	Raise.T02:
		"SKEB" Q 5;
		"SKEB" PONML 5;
		Goto See;

	// ================= T03 CYAN (08_CY) =================
	// Bounces around the arena between attacks, whips in melee, throws
	// three ice-orb pairs or a twin ice bomb, and shatters on death.
	Spawn.T03:
		"SREV" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"SREV" AABBCCDDEEFF 2 { A_Chase(); }
		"SREV" A 0 A_Jump(232, "See.T03.SeeMe", "See.T03.Fast");
		Loop;
	See.T03.Fast:
		"SREV" AABBCCDDEEFF 1 { A_FastChase(); }
		Goto See;
	See.T03.SeeMe:
		"SREV" A 0 A_JumpIfInTargetLOS("See.T03.Jumpy", 0, JLOSF_DEADNOJUMP, 750);
		Goto See;
	See.T03.Jumpy:
		"SREV" A 2;
		"SREV" A 1 ThrustThingZ(0, 64, 0, 0);
		"SREV" A 3 ThrustThing(int(angle - randompick(90, 130, 180, 230, 270)), 12, 0, 0);
		"SREV" A 1 ThrustThingZ(0, 52, 0, 0);
		"SREV" A 1 ThrustThing(int(angle + frandom(1, 120)), 18, 0, 0);
		Goto See;
	Melee.T03:
		"SREV" G 1 { A_FaceTarget(); }
		"SREV" G 5 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"SREV" H 6 { A_FaceTarget(); }
		"SREV" I 0 { A_CustomMeleeAttack(random(15, 55), "skeleton/melee", "none"); }
		"SREV" I 6 { A_SpawnProjectile("RS_ChainWhipRev", 48, 10, 0, 0); }
		"SREV" I 0 A_Jump(232, "See.T03.SeeMe", "See.T03.Fast");
		Goto See;
	Missile.T03:
		"SREV" G 2 Bright { A_FaceTarget(); }
		"SREV" G 1 Bright A_Jump(128, "Missile.T03.IceBomb");
		"SREV" J 8 Bright { A_FaceTarget(); }
		"SREV" K 0 { A_SpawnProjectile("RS_IceORBCyanRev", 48, 12, 0); }
		"SREV" K 4 Bright { A_SpawnProjectile("RS_IceORBCyanRev", 48, -12, 0); }
		"SREV" J 8 Bright { A_FaceTarget(); }
		"SREV" K 0 { A_SpawnProjectile("RS_IceORBCyanRev", 48, 12, randompick(-1, 1, -5, 5), 0, random(-1, 1)); }
		"SREV" K 4 Bright { A_SpawnProjectile("RS_IceORBCyanRev", 48, -12, randompick(-1, 1, -5, 5), 0, random(-1, 1)); }
		"SREV" J 8 Bright { A_FaceTarget(); }
		"SREV" K 0 { A_SpawnProjectile("RS_IceORBCyanRev", 48, 12, randompick(-10, 10, -5, 5), 0, random(-1, 1)); }
		"SREV" K 4 Bright { A_SpawnProjectile("RS_IceORBCyanRev", 48, -12, randompick(-10, 10, -5, 5), 0, random(-1, 1)); }
		"SREV" K 12 { A_FaceTarget(); }
		"SREV" L 2 A_Jump(64, "Missile.T03.Bon");
		Goto See;
	Missile.T03.IceBomb:
		"SREV" J 10 Bright { A_FaceTarget(); }
		"SREV" K 6 Bright { A_SpawnProjectile("RS_BigBallCrev", 48, 12, 5); }
		"SREV" K 6 Bright { A_SpawnProjectile("RS_BigBallCrev", 48, -12, -5); }
		"SREV" K 12 { A_FaceTarget(); }
		"SREV" L 2 A_Jump(64, "Missile.T03.Bon");
		Goto See;
	Missile.T03.Bon:
		"SREV" G 2;
		"SREV" G 1 ThrustThingZ(0, 72, 0, 0);
		"SREV" G 4 ThrustThing(int(angle - 180), 18, 0, 0);
		Goto See;
	Pain.T03:
		"SREV" L 5;
		"SREV" L 5 { A_Pain(); }
		"SREV" L 2 A_Jump(128, "Missile.T03.Bon");
		Goto See;
	Death.T03:
		"SREV" LM 7;
		"SREV" N 7 { A_Scream(); }
		"SREV" O 7 { A_NoBlocking(false); }
		TNT1 A 0 { A_SpawnItemEx("RS_CHCirno", 0, 0, 24, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION, 253); }
		"SREV" PQ 7;
		TNT1 A 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		TNT1 A 0 { A_Burst("IceChunk"); }
		Stop;
	XDeath.T03:
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 A 0 { A_SetTranslucent(0.1); }
		"REVB" F 1 ThrustThingZ(0, 45, 0, 0);
		"REVB" F 5 { A_Scream(); }
		"REVB" F 5 { A_SetTranslucent(0.35); }
		"REVB" F 5 { A_NoBlocking(); }
		"REVB" F 5 { A_SetTranslucent(0.7); }
		"REVB" F 8 { A_SetTranslucent(1); }
		"REVB" F 50;
		TNT1 A 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		TNT1 A 0 { A_Burst("IceChunk"); }
		Stop;
	Raise.T03:
		"SREV" Q 5;
		"SREV" PONML 5;
		Goto See;

	// ================= T04 PURPLE (08_P) =================
	// Crackles with Zap99 constantly. Dash inside 300 (budgeted), twin
	// Purp1 bolts inside 1800, otherwise a double railgun volley.
	Spawn.T04:
		"REVP" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"REVP" AABB 3 { A_Chase(); }
		"REVP" B 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" CCDD 3 { A_Chase(); }
		"REVP" D 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" EEFF 3 { A_Chase(); }
		"REVP" F 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		Loop;
	See.T04.Jumper:
		"REVP" AABB 3 { A_FastChase(); }
		"REVP" B 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" CCDD 3 { A_FastChase(); }
		"REVP" D 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" EEFF 3 { A_FastChase(); }
		"REVP" F 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" A 0 A_Jump(158, "See");
		Loop;
	Melee.T04:
		"REVP" G 3 { A_FaceTarget(); }
		"REVP" G 4 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"REVP" G 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" H 4 { A_FaceTarget(); }
		"REVP" I 4 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		Goto See;
	Missile.T04:
		"REVP" G 4 { A_FaceTarget(); }
		"REVP" G 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" G 0 A_JumpIfCloser(300, "Missile.T04.Falcon");
		"REVP" G 0 A_JumpIfCloser(1800, "Missile.T04.Bolts");
		"REVP" G 0 A_Jump(256, "Missile.T04.Rail");
		Goto See;
	Missile.T04.Falcon:
		"REVP" G 0 { if (rsNoDash2 >= 11) return ResolveState("Missile.T04.Bolts"); rsNoDash2 += 5; return ResolveState(null); }
		"REVP" G 2 Bright { A_SkullAttack(40); }
		Goto Melee;
	Missile.T04.Bolts:
		"REVP" J 9 Bright { A_FaceTarget(); }
		"REVP" J 5 Bright { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" K 0 { A_SpawnProjectile("RS_Purp1", 50, 7, random(0, 2)); }
		"REVP" K 0 { A_SpawnProjectile("RS_Purp1", 50, -7, random(-2, 0)); }
		"REVP" J 8 Bright { A_FaceTarget(); }
		"REVP" J 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" G 0 { rsNoDash2 = max(0, rsNoDash2 - 2); }
		"REVP" K 8 { A_FaceTarget(); }
		Goto See;
	Missile.T04.Rail:
		"REVP" GJ 15 Bright { A_FaceTarget(); }
		"REVP" J 5 Bright { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		TNT1 A 0 A_CheckSight("See");
		"REVP" K 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"REVP" K 0 { A_CustomRailgun(random(2, 20), 7, "purple", "white", RGF_FULLBRIGHT|RGF_SILENT, 1, 0, "RS_FatsoPuff3", 0, 0, 10000, 0, 1, 1, "None", 20); }
		"REVP" K 0 { A_CustomRailgun(random(2, 20), -7, "purple", "white", RGF_FULLBRIGHT|RGF_SILENT, 1, 0, "RS_FatsoPuff3", 0, 0, 10000, 0, 1, 1, "None", 20); }
		"REVP" J 10 Bright { A_FaceTarget(); }
		"REVP" JJJ 0 { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" K 8 A_MonsterRefire(120, "See");
		Goto Missile.T04;
	Pain.T04:
		"REVP" L 5 Bright { A_SpawnProjectile("RS_Zap99", random(20, 64), random(-15, 15)); }
		"REVP" L 5 { A_Pain(); }
		Goto See.T04.Jumper;
	Death.T04:
		"REVP" LM 7;
		"REVP" N 7 { A_Scream(); }
		"REVP" O 7 { A_NoBlocking(); }
		"REVP" P 7;
		"REVP" Q -1;
		Stop;
	XDeath.T04:
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 A 0 { A_SetTranslucent(0.1); }
		"REVB" D 1 ThrustThingZ(0, 45, 0, 0);
		"REVB" D 5 { A_Scream(); }
		"REVB" D 5 { A_SetTranslucent(0.35); }
		"REVB" D 5 { A_NoBlocking(); }
		"REVB" D 5 { A_SetTranslucent(0.7); }
		"REVB" D 8 { A_SetTranslucent(1); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"REVB" D -1;
		Stop;
	Raise.T04:
		"REVP" Q 5;
		"REVP" PONML 5;
		Goto See;

	// ================= T05 YELLOW -- TERROR (08_Y) =================
	// Constantly showering sparks. Two forms (see header): the fast
	// speed-24 form unlocks the fire spit; both share the homing pair
	// and the hellflame channel.
	Spawn.T05:
		"REVN" A 0 A_Jump(128, "Spawn.T05.Fast");
		"REVN" AB 10 { A_Look(); }
		"REVN" A 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Loop;
	Spawn.T05.Fast:
		TNT1 A 0 { A_SetSpeed(24); rsFastForm = 1; }
		TNT1 A 0 { A_SetRenderStyle(1.0, STYLE_Normal); }
		"REVN" AB 10 { A_Look(); }
		"REVN" A 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Loop;
	See.T05:
		"REVN" AABBCCDDEEFF 5 { A_Chase(); }
		"REVN" A 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Loop;
	Melee.T05:
		"REVN" G 6 { A_FaceTarget(); }
		"REVN" G 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" G 4 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"REVN" H 4 { A_FaceTarget(); }
		"REVN" H 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" I 4 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		Goto See;
	Missile.T05:
		"REVN" G 4 { A_FaceTarget(); }
		"REVN" G 0 A_JumpIfCloser(600, "Missile.T05.NewMove");
	Missile.T05.Choose:
		"REVN" G 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" G 0 A_JumpIfCloser(1500, "Missile.T05.Projeor");
		"REVN" G 0 A_Jump(256, "Missile.T05.HellFlame");
		Goto See;
	Missile.T05.NewMove:
		TNT1 A 0 { if (Speed >= 20) return ResolveState("Missile.T05.SpitIt"); return ResolveState("Missile.T05.Choose"); }
		Goto Missile.T05.Choose;
	Missile.T05.SpitIt:
		"REVN" L 8 Bright;
		"REVN" K 8 Bright { A_FaceTarget(); }
		"REVN" JJJJ 3 Bright { A_SpawnProjectile("RS_FirespeNewYel", 46, 0, random(-6, 6), CMF_AIMOFFSET|CMF_OFFSETPITCH, random(-5, -1)); }
		"REVN" J 5 A_CheckSight("See");
		Goto Missile.T05;
	Missile.T05.Projeor:
		"REVN" G 0 A_Jump(78, "Missile.T05.Proje");
		"REVN" G 0 A_Jump(256, "Missile.T05.Proje", "Missile.T05.HellFlame");
		Goto See;
	Missile.T05.Proje:
		"REVN" J 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" J 9 Bright { A_FaceTarget(); }
		"REVN" J 5 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Homer1", 50, 9, random(0, 5)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Homer1", 50, -9, random(-5, 0)); }
		"REVN" J 8 Bright { A_FaceTarget(); }
		"REVN" J 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" K 8 { A_FaceTarget(); }
		Goto See;
	Missile.T05.HellFlame:
		"REVN" G 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" G 14 Bright { A_SpawnProjectile("RS_Firehand1", 32, 20); }
		"REVN" H 10 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" I 8 Bright { A_VileTarget("RS_BigBadFire1"); }
		"REVN" I 9 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;
	Pain.T05:
		"REVN" L 5 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" L 5 { A_Pain(); }
		"REVN" L 0 A_Jump(76, "Pain.T05.FlameSplit");
		Goto See;
	Pain.T05.FlameSplit:
		"REVN" L 5 Bright { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" K 5 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"REVN" K 0 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		Goto See;
	Death.T05:
		"REVN" LM 7;
		"REVN" N 7 { A_Scream(); }
		"REVN" O 7 { A_NoBlocking(); }
		"REVN" P 7;
		"REVN" Q -1;
		Stop;
	XDeath.T05:
		TNT1 A 5 { A_SpawnItemEx("RS_ArcRing1", 0, 0, 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 1 { A_Scream(); }
		TNT1 A 1 { A_NoBlocking(); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 0); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 45); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 90); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 135); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 180); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 225); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 270); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 305); }
		"RIP1" H 0 { A_SpawnProjectile("RS_ArchvileFire2", 0, 0, 340); }
		TNT1 A 24;
		"REVB" E 12 { A_SetTranslucent(0.15); }
		"REVB" E 12 { A_SetTranslucent(0.3); }
		"REVB" E 12 { A_SetTranslucent(0.45); }
		"REVB" E 12 { A_SetTranslucent(0.6); }
		"REVB" E 12 { A_SetTranslucent(0.8); }
		"REVB" E -1;
		Stop;
	Raise.T05:
		"REVN" Q 5;
		"REVN" PONML 5;
		Goto See;

	// ================= T06 ABYSS (08_A) =================
	// Leaves abyss splash as it walks; a hop-and-spray ice fan inside
	// 900, cracked-abyss bolts otherwise, and a NOPAIN speed-99 phase
	// dash off pain.
	Spawn.T06:
		"REVA" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"REVA" AAB 1 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"REVA" BCC 1 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"REVA" DDE 1 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"REVA" EFF 1 { A_Chase(); }
		Loop;
	Melee.T06:
		"REVA" G 2 { A_FaceTarget(); }
		"REVA" G 3 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"REVA" H 2 { A_FaceTarget(); }
		"REVA" I 4 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		TNT1 A 0 A_Jump(86, "Missile.T06");
		Goto See;
	Missile.T06:
		"REVA" G 2 { A_FaceTarget(); }
		"REVA" G 0 A_JumpIfCloser(900, "Missile.T06.StepDance");
	Missile.T06.Bolts:
		"REVA" J 12 Bright { A_FaceTarget(); }
		"REVA" J 1 { A_SpawnProjectile("RS_CrackedAbyssRev", 50, 8, random(-10, 1)); }
		"REVA" J 5 { A_SpawnProjectile("RS_CrackedAbyssRev", 50, -8, random(-1, 10)); }
		"REVA" K 8;
		Goto See;
	Missile.T06.StepDance:
		"REVA" G 1;
		"REVA" G 1 A_Jump(162, "Missile.T06.Bolts");
		"REVA" G 1 ThrustThingZ(0, 64, 0, 0);
		TNT1 AAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-328, 328), random(-328, 328), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"REVA" J 1 Bright { A_FaceTarget(); }
		"REVA" JJJJKK 2 { A_SpawnProjectile("RS_IceOrbAbyssRev", 42, 0, random(-50, 50), CMF_OFFSETPITCH, random(-35, 15)); }
		"REVA" K 8;
		Goto See;
	Pain.T06:
		"REVA" L 5;
		"REVA" L 5 { A_Pain(); }
		"REVA" L 1 A_Jump(76, "Pain.T06.Phase");
		Goto See;
	Pain.T06.Phase:
		"REVA" A 1;
		"REVA" A 1 { bNOPAIN = true; }
		"REVA" A 1 { A_SetSpeed(99); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 128), random(-128, 128), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"REVA" ABCDEFABCDEFABCDEF 1 { A_Wander(); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 128), random(-128, 128), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"REVA" A 1 { A_SetSpeed(11); }
		"REVA" A 1 { bNOPAIN = false; }
		Goto See;
	Death.T06:
		"REVA" LM 7;
		"REVA" N 7 { A_Scream(); }
		"REVA" O 7 { A_NoBlocking(); }
		"REVA" P 7;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 128), random(-128, 128), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"REVA" Q -1;
		Stop;
	Raise.T06:
		"REVA" Q 5;
		"REVA" PONML 5;
		Goto See;

	// ================= T07 FIREBLU (08_F) =================
	// A four-stage weaving red/blue barrage at range, a fourteen-bolt
	// ring up close, and an exploding punch in melee.
	Spawn.T07:
		"REVF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"REVF" AABBCCDDEEFF 2 { A_Chase(); }
		Loop;
	Missile.T07:
		TNT1 A 0 A_JumpIfCloser(600, "Missile.T07.Spread");
		"REVF" J 9 Bright { A_FaceTarget(); }
		"REVF" J 7;
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH03", 56, 7, 1); }
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH04", 56, -7, -1); }
		"REVF" K 14 Bright { A_FaceTarget(); }
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH03", 56, 9, random(1, 5)); }
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH04", 56, -9, random(-5, -1)); }
		"REVF" K 14 Bright { A_FaceTarget(); }
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH03", 56, 9, random(2, 8)); }
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH04", 56, -9, random(-8, -2)); }
		"REVF" K 14 Bright { A_FaceTarget(); }
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH03", 56, 9, random(3, 11)); }
		"REVF" K 0 { A_SpawnProjectile("RS_FBSkelCH04", 56, -9, random(-11, -3)); }
		"REVF" K 20 { A_FaceTarget(); }
		Goto See;
	Missile.T07.Spread:
		"REVF" G 10;
		"REVF" L 10 Bright;
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH02", 42, 0, random(-5, 15), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH01", 42, 0, random(5, 25), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH02", 42, 0, random(35, 55), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH01", 42, 0, random(65, 85), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH02", 42, 0, random(95, 115), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH01", 42, 0, random(125, 145), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH02", 42, 0, random(155, 175), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH01", 42, 0, random(185, 205), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH02", 42, 0, random(215, 235), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH01", 42, 0, random(245, 265), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH02", 42, 0, random(275, 295), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH01", 42, 0, random(305, 325), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH02", 42, 0, random(335, 355), 0); }
		"REVF" FF 0 { A_SpawnProjectile("RS_FBSkelCH01", 42, 0, random(-15, 5), 0); }
		"REVF" L 20;
		Goto See;
	Melee.T07:
		"REVF" G 6 { A_FaceTarget(); }
		"REVF" G 1 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"REVF" H 1 { A_FaceTarget(); }
		"REVF" H 0 { A_StartSound("weapons/rocklx", CHAN_WEAPON); }
		"REVF" I 1 Bright;
		"REVF" I 0 { A_SpawnProjectile("RS_BoomSkel1", 42); }
		Goto See;
	Pain.T07:
		"REVF" L 5;
		"REVF" L 5 { A_Pain(); }
		Goto Missile.T07.Spread;
	Death.T07:
		"REVF" LM 7;
		"REVF" N 7 { A_Scream(); }
		"REVF" O 7 { A_NoBlocking(); }
		"REVF" P 7;
		"REVF" Q -1;
		Stop;
	XDeath.T07:
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 A 1 { A_Scream(); }
		TNT1 A 1 { A_NoBlocking(); }
		TNT1 AAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 2, random(0, 360), SXF_NOCHECKPOSITION, 64); }
		TNT1 A 24;
		"REVB" G 12 { A_SetTranslucent(0.15); }
		"REVB" G 12 { A_SetTranslucent(0.3); }
		"REVB" G 12 { A_SetTranslucent(0.45); }
		"REVB" G 12 { A_SetTranslucent(0.6); }
		"REVB" G 12 { A_SetTranslucent(0.8); }
		"REVB" G -1;
		Stop;
	Raise.T07:
		"REVF" Q 5;
		"REVF" PONML 5;
		Goto See;

	// ================= T08 BROWN -- MUMMY (08_BR) =================
	// Leaves a gas trail as it walks, throws two brown balls, and heals
	// every other revenant around it when it gibs.
	Spawn.T08:
		"INCA" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"INCA" AAB 2 { A_Chase(); }
		"INCA" A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"INCA" BCC 2 { A_Chase(); }
		// RESTORED (rs_19 / L3). CHP 08_BR.txt:32. The Incarnate hastens its
		// pack TWICE per walk cycle -- a constant aura, not an event. Dropped
		// by the import as an "empty ACS wrapper"; BrownRevSPEED2 doubles the
		// recipient's speed for 210 tics. See RS_MonsterCommands.zs.
		"INCA" A 0 { A_RadiusGive("RS_RevSpeedBuff", 256, RGF_MONSTERS|RGF_EXFILTER, 1, "RS_Revenant"); }
		"INCA" A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"INCA" DDE 2 { A_Chase(); }
		"INCA" A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"INCA" EFF 2 { A_Chase(); }
		// CHP 08_BR.txt:37 -- the second of the two per-cycle casts.
		"INCA" A 0 { A_RadiusGive("RS_RevSpeedBuff", 256, RGF_MONSTERS|RGF_EXFILTER, 1, "RS_Revenant"); }
		"INCA" A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Melee.T08:
		"INCA" G 0 { A_FaceTarget(); }
		"INCA" G 5 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"INCA" H 5 { A_FaceTarget(); }
		"INCA" I 5 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		Goto See;
	Missile.T08:
		"INCA" J 10 { A_FaceTarget(); }
		"INCA" U 10 Bright { A_FaceTarget(); }
		"INCA" K 0 { A_SpawnProjectile("RS_BrownRevBall", 62, 12, 12); }
		"INCA" K 10 Bright { A_SpawnProjectile("RS_BrownRevBall", 62, -12, -12); }
		Goto See;
	Pain.T08:
		"INCA" L 5;
		"INCA" L 5 { A_Pain(); }
		Goto See;
	Death.T08:
		"INCA" LM 7;
		"INCA" N 7 { A_Scream(); }
		"INCA" O 7 { A_NoBlocking(); }
		"INCA" P 7;
		"INCA" Q -1;
		Stop;
	XDeath.T08:
		TNT1 A 0 { A_Scream(); }
		"INCX" A 10 Bright { A_StartSound("BASSFFAT", CHAN_BODY); }
		"INCX" BC 5 Bright;
		"INCX" D 5 Bright { A_NoBlocking(); }
		"INCX" AAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), random(1, 11), 0, random(0, 4), random(0, 360), SXF_NOCHECKPOSITION); }
		"INCX" A 0 { A_RadiusGive("Health", 1200, RGF_MONSTERS|RGF_EXFILTER, 500, "RS_Revenant"); }
		// CHP 08_BR.txt:74 -- the dying gift. Note the radius: 1200, not the
		// 256 of the walking aura. The Incarnate's death hastens the whole
		// room, and it pairs with the 500 heal on the line above, which the
		// import kept while dropping this half.
		"INCX" A 0 { A_RadiusGive("RS_RevSpeedBuff", 1200, RGF_MONSTERS|RGF_EXFILTER, 1, "RS_Revenant"); }
		"INCX" EFGHIJ 5 Bright;
		"INCX" K -1;
		Stop;
	Raise.T08:
		"INCA" QPONML 5;
		Goto See;

	// ================= T09 GRAY -- MIKE TYSON (08_GY) =================
	// Two-fisted combo (it mirrors its own sprite mid-punch), thrown
	// bones at range, and a 45-speed charge inside 700.
	Spawn.T09:
		"ZKEL" AB 10 { A_Look(); }
		Loop;
	See.T09:
		TNT1 A 0 { A_SetScale(1.0, 1.0); }
		"ZKEL" AABBCCDDEEFF 2 { A_Chase(); }
		Loop;
	Melee.T09:
		"ZKEL" G 1 { A_FaceTarget(); }
		"ZKEL" G 1 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"ZKEL" H 1 { A_FaceTarget(); }
		"ZKEL" I 1 { A_CustomMeleeAttack(random(2, 8)); }
		"ZKEL" G 1 { A_SetScale(-1.0, 1.0); }
		"ZKEL" G 1 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"ZKEL" H 1 { A_FaceTarget(); }
		"ZKEL" I 1 { A_CustomMeleeAttack(random(2, 8)); }
		Goto See;
	Missile.T09:
		"ZKEL" G 0 A_JumpIfCloser(700, "Missile.T09.Closer");
		"ZKEL" G 8 { A_FaceTarget(); }
	Missile.T09.Bones:
		"ZKEL" H 2 { A_SpawnProjectile("RS_BoneToPickGrey", 42, 3, 0); }
		"ZKEL" I 2;
		"ZKEL" G 6 { A_FaceTarget(); }
		"ZKEL" H 2 { A_SpawnProjectile("RS_BoneToPickGrey", 42, 3, random(-1, 1)); }
		"ZKEL" I 2;
		"ZKEL" G 4 { A_FaceTarget(); }
		"ZKEL" H 2 { A_SpawnProjectile("RS_BoneToPickGrey", 42, 3, random(-3, 3)); }
		"ZKEL" I 2;
		Goto See;
	Missile.T09.Closer:
		"ZKEL" G 0 A_Jump(32, "Missile.T09.Bones");
		"ZKEL" G 2 Bright { A_SkullAttack(45); }
		Goto Melee;
	Pain.T09:
		// GrayRevenant2 carries +NOPAIN and no PainChance -- unreachable
		// in normal play, but CHP defines the cluster so it is ported.
		"ZKEL" L 5 { A_SetScale(1.0, 1.0); }
		"ZKEL" L 5 { A_Pain(); }
		Goto See;
	Death.T09:
		"ZKEL" LM 7 { A_SetScale(1.0, 1.0); }
		"ZKEL" N 7 { A_Scream(); }
		"ZKEL" O 7 { A_NoBlocking(); }
		"ZKEL" P 7;
		"ZKEL" Q -1;
		Stop;
	XDeath.T09:
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 A 0 { A_SetTranslucent(0.1); }
		"REVB" A 1 ThrustThingZ(0, 45, 0, 0);
		"REVB" A 5 { A_Scream(); }
		"REVB" A 5 { A_SetTranslucent(0.35); }
		"REVB" A 5 { A_NoBlocking(); }
		"REVB" A 5 { A_SetTranslucent(0.7); }
		"REVB" A 8 { A_SetTranslucent(1); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CHBoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"REVB" A -1;
		Stop;
	Raise.T09:
		"ZKEL" Q 5;
		"ZKEL" PONML 5;
		Goto See;

	// ================= T10 RED (08_R) =================
	// Every shot charges it; on the fourth it loads and fires a
	// MegaRedRev instead. Pain locks NOPAIN and MISSILEEVENMORE on.
	Spawn.T10:
		"RASK" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"RASK" AAABBBCCCDDDEEEFFF 2 { A_Chase(); }
		Loop;
	Melee.T10:
		"RASK" G 1 { A_FaceTarget(); }
		"RASK" G 6 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"RASK" H 5 { A_FaceTarget(); }
		"RASK" II 3 { A_CustomMeleeAttack(random(1, 10) * 6, "skeleton/melee"); }
		Goto See;
	Missile.T10:
		"RASK" J 1 Bright { A_FaceTarget(); }
		"RASK" J 1 Bright { if (rsCharge >= 4) return ResolveState("Missile.T10.MegaShot"); return ResolveState(null); }
		"RASK" J 9 Bright { A_FaceTarget(); }
		"RASK" K 10 { A_SpawnProjectile("RS_RedDeathRev", 60, 9, random(-4, 4)); }
		"RASK" K 0 { rsCharge++; }
		"RASK" K 10 { A_FaceTarget(); }
		"RASK" K 2;
		Goto See;
	Missile.T10.MegaShot:
		"RASK" J 5 Bright { A_StartSound("skeleton/sight", CHAN_VOICE); }
		"RASK" JJJ 5 Bright { A_FaceTarget(); }
		"RASK" J 10 Bright { A_SpawnProjectile("RS_RedRevLoad", 60, 9, 0); }
		"RASK" J 15 Bright { A_FaceTarget(); }
		"RASK" K 7 Bright { A_SpawnProjectile("RS_MegaRedRev", 60, 9, random(-4, 4)); }
		"RASK" K 5 { A_FaceTarget(); }
		"RASK" K 1 { rsCharge = max(0, rsCharge - 4); }
		"RASK" K 1;
		Goto See;
	Pain.T10:
		"RASK" L 5;
		"RASK" LL 5 { A_Pain(); }
		"RASK" L 5 { bNOPAIN = true; }
		"RASK" L 5 { bMISSILEEVENMORE = true; }
		"RASK" L 5;
		Goto See;
	Death.T10:
		"RASK" LM 7;
		"RASK" N 7 { A_Scream(); }
		"RASK" O 7 { A_NoBlocking(); }
		"RASK" P 7;
		"RASK" Q -1;
		Stop;
	XDeath.T10:
		TNT1 A 1 { A_Scream(); }
		TNT1 A 0 { A_NoBlocking(); }
		TNT1 A 1 { A_SpawnProjectile("RS_RedRevLoad", 42, 0, 0); }
		TNT1 A 7;
		TNT1 AAAAAAAAA 1 { A_SpawnProjectile("RS_HKRedDeath", random(12, 64), random(-16, 16)); }
		TNT1 A 24;
		"RASK" Q 12 { A_SetTranslucent(0.2); }
		"RASK" Q 12 { A_SetTranslucent(0.4); }
		"RASK" Q 12 { A_SetTranslucent(0.6); }
		"RASK" Q 12 { A_SetTranslucent(0.8); }
		"RASK" Q 12 { A_SetTranslucent(0.95); }
		"RASK" Q -1;
		Stop;
	Raise.T10:
		"RASK" Q 5;
		"RASK" PONML 5;
		Goto See;

	// ============ T11 BLACK -- THE BLACK KNIGHT (08_K) ============
	// Dart cleave, seeking mines, or a five-hit dash; pain can raise a
	// reflective shield that ends in a shield blast. It does not die the
	// first time -- DeathMorphClass carries it into RS_RevenantShade.
	Spawn.T11:
		"DKNT" AB 10 { A_Look(); }
		Loop;
	See.T11:
		TNT1 A 0 { A_KillChildren("Extreme", KILS_FOILINVUL); }
		"DKNT" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.T11.Shielded:
		TNT1 A 0 { A_SpawnItemEx("RS_RevShieldWalk", 0, 4, 8, 0, 0, 0, 0, SXF_SETMASTER); }
		"DKNT" PPQQRRSS 3 { A_Chase(); }
		Goto See;
	Melee.T11:
		"DKNT" E 6 { A_FaceTarget(); }
		"DKNT" F 1 { A_StartSound("monster/dknswg", CHAN_WEAPON); }
		"DKNT" F 6 { A_FaceTarget(); }
		"DKNT" G 6 { A_CustomMeleeAttack(random(20, 120)); }
		Goto See;
	Missile.T11:
		TNT1 A 0 { A_KillChildren("Extreme", KILS_FOILINVUL); }
		"DKNT" A 0 { A_StartSound("BK/invi", CHAN_BODY, 0, 4.0); }
		"DKNT" A 0 A_Jump(256, "Missile.T11.DartCleave", "Missile.T11.Mines", "Missile.T11.Dash");
		Goto See;
	Missile.T11.DartCleave:
		"DKNT" E 9 Bright { A_FaceTarget(); }
		"DKNT" F 8 Bright { A_StartSound("monster/kntswg", CHAN_WEAPON); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(-6, -2), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(-12, -7), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, 0, 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(7, 12), 0); }
		"DKNT" G 5 Bright { A_SpawnProjectile("RS_DKDart", 32, 0, random(2, 6), 0); }
		Goto See;
	Missile.T11.Mines:
		"DKNT" T 8 Bright { A_FaceTarget(); }
		"DKNT" U 2 Bright { A_FaceTarget(); }
		"DKNT" U 0 { A_SpawnProjectile("RS_MinesRev", 44, -4, -12, 0); }
		"DKNT" U 6 Bright { A_SpawnProjectile("RS_MinesRev", 44, -4, 12, 0); }
		"DKNT" U 0 { A_UnSetReflectiveInvulnerable(); }
		"DKNT" U 0 A_Jump(64, "Missile.T11.Mines");
		Goto See;
	Missile.T11.Dash:
		"DKNT" E 8 Bright { A_UnSetReflectiveInvulnerable(); }
		"DKNT" FFFFF 8 Bright { A_SkullAttack(38); }
		"DKNT" G 4 Bright { A_Stop(); }
		Goto Melee;
	Pain.T11:
		"DKNT" H 2;
		"DKNT" H 2 { A_Pain(); }
		"DKNT" P 0 A_Jump(178, "Pain.T11.Shield");
		Goto See;
	Pain.T11.Shield:
		TNT1 A 0 { bNOPAIN = true; }
		"DKNT" P 60 { A_SpawnItemEx("RS_RevShieldWalk", 0, 4, 8, 0, 0, 0, 0, SXF_SETMASTER); }
		"DKNT" T 10 Bright { A_KillChildren("Extreme", KILS_FOILINVUL); }
		"DKNT" U 10 Bright { A_SpawnProjectile("RS_ShieldBlastRev", 44, 0, 0, 0); }
		TNT1 A 0 { bNOPAIN = false; }
		Goto See;
	Death.T11:
		"DKNT" I 12 Bright { A_KillChildren("Extreme", KILS_FOILINVUL); }
		"DKNT" I 0 { A_SpawnProjectile("RS_DKSword", 44, 32, -90, 0); }
		"DKNT" I 8 Bright { A_SpawnProjectile("RS_DKShield", 44, -32, 90, 0); }
		"DKNT" J 8 Bright;
		"DKNT" J 8 Bright { A_Scream(); }
		"DKNT" J 8 Bright { A_NoBlocking(); }
		// CHP spawns CommonBlackRev2 here; RS does it through
		// DeathMorphClass -> RS_RevenantShade instead.
		"DKNT" K 8 Bright;
		"DKNT" LMN 8 Bright;
		"DKNT" O -1;
		Stop;

	// ================= T12 WHITE -- THE LICH (08_W) =================
	// Death coils and ice bolts at range; up close it rolls between a
	// ground channel, frost mines, an ice breath, and summoning. Under
	// 4500 HP it enrages once (float, no gravity, a speed-99 blink).
	Spawn.T12:
		"REVW" ABCD 5 { A_Look(); }
		Loop;
	See.T12:
		"REVW" AB 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_EvilShadeWhiteRev2", random(-1, 2), random(-6, 6), 3, random(3, 11), 0, random(0, 2), randompick(45, 90, 225, 270, 180, 0), SXF_NOCHECKPOSITION); }
		"REVW" CD 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_EvilShadeWhiteRev2", random(1, 2), random(-6, 6), 3, random(3, 11), 0, random(0, 2), randompick(45, 90, 225, 270, 180, 0), SXF_NOCHECKPOSITION); }
		Loop;
	Missile.T12:
		TNT1 A 0 A_JumpIfHealthLower(4500, "Missile.T12.Enrage");
	Missile.T12.Cast:
		TNT1 A 0 { A_SpawnItemEx("RS_EvilShadeWhiteRev", random(1, 2), 0, 46, random(1, 2), 0, 2, 0, SXF_NOCHECKPOSITION, 128); }
		TNT1 A 0 { A_StartSound("Lich/Cast", CHAN_VOICE); }
		"REVW" E 5 Bright { A_FaceTarget(); }
		"REVW" E 0 A_JumpIfCloser(1500, "Missile.T12.CloseChoice");
		"WRTH" E 0 A_Jump(256, "Missile.T12.IceBolt", "Missile.T12.DeathCoil");
		Goto See;
	Missile.T12.CloseChoice:
		"WRTH" E 0 A_Jump(256, "Missile.T12.GroundPain", "Missile.T12.FrostMines", "Missile.T12.IceBreath", "Missile.T12.DeathCoil", "Missile.T12.IceBolt");
		Goto See;
	Missile.T12.DeathCoil:
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_Splash11", 2, 24, 66, random(3, 9), 0, random(2, 9), random(0, 359)); }
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_Splash11", 2, -24, 66, random(3, 9), 0, random(2, 9), random(0, 359)); }
		"REVW" FGHI 6 Bright { A_FaceTarget(); }
		TNT1 AAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_Splash11", 12, 0, 42, random(2, 7), 0, random(2, 6), random(-12, 12)); }
		"REVW" I 4 Bright { A_SpawnProjectile("RS_WhiteRevCoil", random(28, 40), random(-7, 7), random(-11, 1), 0, random(-2, 2)); }
		"REVW" I 4 Bright { A_SpawnProjectile("RS_WhiteRevCoil2", random(28, 40), random(-7, 7), random(-1, 1)); }
		"REVW" I 4 Bright { A_SpawnProjectile("RS_WhiteRevCoil3", random(28, 40), random(-7, 7), random(-1, 11), 0, random(-2, 2)); }
		TNT1 A 0 A_JumpIfHealthLower(4500, "Missile.T12.MoreCoil");
		"REVW" GF 3;
		Goto See;
	Missile.T12.MoreCoil:
		"REVW" I 4 Bright { A_SpawnProjectile("RS_WhiteRevCoil4", 32, 0, random(-1, 1)); }
		"REVW" GF 3;
		Goto See;
	Missile.T12.IceBolt:
		"REVW" FGH 4 Bright { A_FaceTarget(); }
		"REVW" I 4 { A_SpawnProjectile("RS_CyanCybieGunFlare", 32, 0, 0); }
		"REVW" I 6 Bright { A_SpawnProjectile("RS_WhiteRevFrostBolt", 32, 0, 0); }
		"REVW" GF 3;
		Goto See;
	Missile.T12.IceBreath:
		"REVW" FGHI 4 Bright { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfHealthLower(6200, "Missile.T12.BiggerBreath");
		"REVW" I 6 Bright { A_SpawnProjectile("RS_IceToMeetWhiteRev", 32, 0, 0); }
		TNT1 A 0 A_JumpIfHealthLower(6200, "Missile.T12.BiggerBreath");
		"REVW" GF 3;
		Goto See;
	Missile.T12.BiggerBreath:
		"REVW" I 0 { A_SpawnProjectile("RS_IceToMeetWhiteRev", 32, 0, 5); }
		"REVW" I 0 { A_SpawnProjectile("RS_IceToMeetWhiteRev", 32, 0, -5); }
		"REVW" I 6 Bright { A_SpawnProjectile("RS_IceToMeetWhiteRev", 32, 0, 0); }
		"REVW" GF 3;
		Goto See;
	Missile.T12.FrostMines:
		"REVW" J 5 Bright;
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_FrostWingBaron2", 2, 24, 74, random(2, 12), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_FrostWingBaron2", 2, -24, 74, random(2, 12), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		"REVW" L 3 Bright { bNOPAIN = false; }
		"REVW" K 3 Bright;
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_FrostWingBaron2", 2, 24, 74, random(2, 12), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_FrostWingBaron2", 2, -24, 74, random(2, 12), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		"REVW" JKL 5 Bright { A_FaceTarget(); }
	Missile.T12.FrostMines2:
		"REVW" J 5 Bright { A_FaceTarget(); }
		"REVW" KK 2 Bright { A_SpawnItemEx("RS_IceGroundWhiteRev", random(24, 1028), random(-128, 128), 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"REVW" L 2 Bright { A_FaceTarget(); }
		"REVW" LL 2 Bright { A_SpawnItemEx("RS_IceGroundWhiteRev", random(128, 1028), random(-528, 528), 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"REVW" E 0 A_CheckSight("Missile.T12.FrostMinesStop");
		"REVW" E 0 A_Jump(24, "Missile.T12.FrostMinesStop");
		"REVW" E 0 A_JumpIfCloser(1500, "Missile.T12.FrostMines2");
		Goto Missile.T12.GroundStop;
	Missile.T12.FrostMinesStop:
		"REVW" E 2;
		"WRTH" E 0 { bNOPAIN = true; }
		"REVW" E 2 A_Jump(32, "Missile.T12.IceBolt");
		Goto See;
	Missile.T12.GroundPain:
		"REVW" J 5 Bright;
		"REVW" L 3 Bright { bNOPAIN = false; }
		"REVW" K 3 Bright { A_VileTarget("RS_DarkChannelWhiteRev"); }
		"REVW" JKL 8 Bright { A_FaceTarget(); }
		"REVW" JKL 5 Bright { A_FaceTarget(); }
	Missile.T12.GroundPain2:
		"REVW" JKL 5 Bright { A_FaceTarget(); }
		"REVW" E 0 A_CheckSight("Missile.T12.GroundStop");
		"REVW" E 0 A_Jump(12, "Missile.T12.GroundStop");
		"REVW" E 0 A_JumpIfCloser(1500, "Missile.T12.GroundPain2");
		Goto Missile.T12.GroundStop;
	Missile.T12.GroundStop:
		"REVW" E 2;
		"WRTH" E 0 { bNOPAIN = true; }
		"REVW" E 2 { A_RadiusGive("RS_ByeWhiteRevCast", 9999, RGF_MISSILES|RGF_NOSIGHT, 1); }
		Goto See;
	Missile.T12.SummonHelp:
		"REVW" J 1 Bright;
		TNT1 A 0 { A_SpawnProjectile("RS_RedRevLoad", 72, 23, 0); }
		TNT1 A 0 { A_SpawnProjectile("RS_RedRevLoad", 72, -23, 0); }
		"REVW" J 5 Bright;
		"REVW" L 3 Bright { bNOPAIN = false; }
		"REVW" K 3 Bright;
		"REVW" JKL 8 Bright { A_FaceTarget(); }
		"REVW" J 5 Bright { A_FaceTarget(); }
		"REVW" K 3 Bright ThrustThingZ(0, 12, 0, 0);
		TNT1 A 0 { A_SpawnItemEx("RS_EvilShadeWhiteRev", random(1, 2), 0, 46, random(1, 2), 0, 2, 0, SXF_NOCHECKPOSITION, 128); }
		"REVW" JKLJKL 8 Bright { A_FaceTarget(); }
		"REVW" JKL 8 Bright { A_SpawnItemEx("RS_MrBones", randompick(-64, 64, 32, -32), randompick(-128, 64, -64, 128), 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		TNT1 A 0 { A_SpawnItemEx("RS_EvilShadeWhiteRev", random(1, 2), 0, 46, random(1, 2), 0, 2, 0, SXF_NOCHECKPOSITION, 128); }
		"REVW" JKLJKLJKL 8 Bright { A_FaceTarget(); }
		"REVW" L 3 Bright { bNOPAIN = true; }
		"REVW" FGHI 2 Bright;
		"REVW" III 2 Bright { A_SpawnItemEx("RS_PortalSummons", randompick(-64, 64, 32, -32), randompick(-128, 64, -64, 128), 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"REVW" I 12 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T12.CloseChoice2:
		"WRTH" E 0 A_Jump(256, "Missile.T12.GroundPain", "Missile.T12.SummonHelp", "Missile.T12.DeathCoil", "Missile.T12.IceBolt");
		Goto See;
	Missile.T12.Enrage:
		TNT1 A 0 { if (rsEnraged == 1) return ResolveState("Missile.T12.Second"); return ResolveState(null); }
		TNT1 A 0 { A_StartSound("deepone/death", 7, 0, 2.0, ATTN_NONE); }
		"REVW" E 5 Bright { A_FaceTarget(); }
		"REVW" J 3 Bright { bFLOAT = true; }
		"REVW" K 3 Bright { bNOGRAVITY = true; }
		"REVW" L 3 Bright { rsEnraged = 1; }
		"REVW" L 1 { A_SetTranslucent(0.80); }
		"REVW" L 1 { A_SetTranslucent(0.60); }
		"REVW" L 1 { A_SetTranslucent(0.40); }
		"REVW" L 1 { A_SetTranslucent(0.20); }
		"REVW" L 1 { A_SetSpeed(99); }
		"REVW" LLL 2 { A_Wander(); }
		"REVW" LLLL 1 { A_Wander(); }
		"REVW" LL 2 { A_Wander(); }
		"REVW" L 1 { A_SetSpeed(23); }
		"REVW" L 1 { A_SetTranslucent(0.40); }
		"REVW" L 1 { A_SetTranslucent(0.60); }
		"REVW" L 1 { A_SetTranslucent(0.80); }
		"REVW" L 1 { A_SetTranslucent(1.0); }
		Goto See;
	// CHP's "Nah" -> Missile2: once enraged the lich uses the second
	// close-range table (which trades frost mines for the summon).
	Missile.T12.Second:
		TNT1 A 0 { A_SpawnItemEx("RS_EvilShadeWhiteRev", random(1, 2), 0, 46, random(1, 2), 0, 2, 0, SXF_NOCHECKPOSITION, 128); }
		TNT1 A 0 { A_StartSound("Lich/Cast", CHAN_VOICE); }
		"REVW" E 5 Bright { A_FaceTarget(); }
		"REVW" E 0 A_JumpIfCloser(1500, "Missile.T12.CloseChoice2");
		"WRTH" E 0 A_Jump(256, "Missile.T12.IceBolt", "Missile.T12.DeathCoil");
		Goto See;
	Pain.T12:
		"REVW" M 3;
		"REVW" M 3 { A_Pain(); }
		"REVW" M 3 A_Jump(256, "Pain.T12.Warp");
		Goto See;
	Pain.T12.Warp:
		"REVW" M 1 { A_SetTranslucent(0.80); }
		"REVW" M 1 { A_SetTranslucent(0.60); }
		"REVW" M 1 { A_SetTranslucent(0.40); }
		"REVW" M 1 { A_SetTranslucent(0.20); }
		"WRTH" M 10 { bNOPAIN = true; }
		TNT1 A 0 { A_RadiusGive("RS_ByeWhiteRevCast", 9999, RGF_MISSILES|RGF_NOSIGHT, 1); }
		"REVW" M 1 { A_SetSpeed(99); }
		"REVW" MMM 2 { A_Wander(); }
		"REVW" MMMMMM 1 { A_Wander(); }
		"REVW" MMMM 2 { A_Wander(); }
		"REVW" M 1 { A_SetTranslucent(0.40); }
		"REVW" M 1 { A_SetTranslucent(0.60); }
		"REVW" M 1 { A_SetTranslucent(0.80); }
		"REVW" M 1 { A_SetTranslucent(1.0); }
		"REVW" M 1 { A_SetSpeed(23); }
		"REVW" M 20;
		Goto See;
	Death.T12:
	XDeath.T12:
		TNT1 A 0 { A_RadiusGive("RS_ByeWhiteRevCast", 9999, RGF_MISSILES|RGF_NOSIGHT, 1); }
		"REVW" MMMMMM 2 { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), CMF_AIMOFFSET, 2, -10); }
		"REVW" M 3 { A_Scream(); }
		"REVW" MMMMMMMMMM 1 { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), CMF_AIMOFFSET, 2, -10); }
		"REVW" M 3 { A_NoBlocking(); }
		"REVW" M 3 { A_SetFloorClip(); }
		"REVW" MMMM 3 { A_FadeOut(0.25); }
		Stop;

	// ============ TEX BLACK EX -- THE BLACK KNIGHT UNLEASHED (08_KX) ============
	// The T11 knight with everything it was holding back. Same DKNT body,
	// same three openers, but the roster splits on range: outside 1000 it
	// picks dart cleave / shield blast / dash, inside 1000 it picks dart
	// cleave / mines / dash / GRAPPLE. Both mine and melee chains can
	// re-enter themselves, so a bad read compounds.
	//
	// What is genuinely new over T11:
	//   * the GRAPPLE (RS_BlackRevHook) -- a 42-speed melee-typed hook,
	//     and Melee itself has a 50% chance of ending in a second one;
	//   * ShieldBlast -- thirty-two RS_ShieldBombRev before the blast;
	//   * a NINE-dart cleave instead of five;
	//   * FOUR mines instead of two, on a re-entry loop;
	//   * the standing shield answer on pain now raises BOTH discs
	//     (RS_RevShieldWalk on master, RS_RevShieldWalk2 orbiting target);
	//   * a black smear on every stride so you are always shooting where
	//     it was.
	//
	// Its death is a phase change, not an end: DeathMorphClass already
	// carries any Tier >= 11 knight into RS_RevenantShade, which brings
	// RS_RevenantShadow with it. That is CHP's own EX3 -> EX4 chain
	// (08_KX CommonBlackRevenantEX3 spawns CommonBlackRevenantEX4), so
	// the two inline A_SpawnItemEx calls in CHP's Death are not repeated
	// here -- see the TEX rows on those two classes at the bottom of this
	// file, which carry EX3's and EX4's real numbers.
	Spawn.TEX:
		"DKNT" AB 10 { A_Look(); }
		Loop;
	See.TEX:
		"DKNT" AA 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BlackRevShade", -2, 0, 12, 1, 0, -0.5, 0, SXF_NOCHECKPOSITION); }
		"DKNT" BB 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BlackRevShade", -2, 0, 12, 1, 0, -0.5, 0, SXF_NOCHECKPOSITION); }
		"DKNT" CC 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BlackRevShade", -2, 0, 12, 0, 0, -0.5, 0, SXF_NOCHECKPOSITION); }
		"DKNT" DD 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BlackRevShade", -2, 0, 12, 1, 0, -0.5, 0, SXF_NOCHECKPOSITION); }
		Loop;
	See.TEX.Shielded:
		TNT1 A 0 { A_SpawnItemEx("RS_RevShieldWalk2", 0, 4, 8, 0, 0, 0, 0, SXF_SETTARGET); }
		TNT1 A 0 { A_SpawnItemEx("RS_RevShieldWalk", 0, 4, 8, 0, 0, 0, 0, SXF_SETMASTER); }
		"DKNT" PPQQRRSS 3 { A_Chase(); }
		Goto See;
	Melee.TEX:
		"DKNT" E 3 { A_FaceTarget(); }
		"DKNT" F 1 { A_StartSound("monster/dknswg", CHAN_WEAPON); }
		"DKNT" F 4 { A_FaceTarget(); }
		"DKNT" G 4 { A_CustomMeleeAttack(random(50, 140)); }
		TNT1 A 0 { A_StartSound("BKFuKINV", CHAN_BODY, 0, 4.0); }
		"DKNT" G 4;
		"DKNT" U 0 A_Jump(128, "Missile.TEX.Grap2");
		Goto See;
	Missile.TEX:
		TNT1 A 0 { A_KillChildren("Extreme", KILS_FOILINVUL); }
		"DKNT" A 0 { A_StartSound("BK/invi", CHAN_BODY, 0, 4.0); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.TEX.Choice2");
		"DKNT" A 0 A_Jump(256, "Missile.TEX.DartCleave", "Missile.TEX.ShieldBlast", "Missile.TEX.Dash");
		Goto See;
	// The close-range roster. Note the swap: no shield blast, but the
	// grapple is on the table.
	Missile.TEX.Choice2:
		"DKNT" A 0 A_Jump(256, "Missile.TEX.DartCleave", "Missile.TEX.Mines", "Missile.TEX.Dash", "Missile.TEX.Grap");
		Goto See;
	Missile.TEX.ShieldBlast:
		"DKNT" PT 10 Bright { A_FaceTarget(); }
		"DKNT" U 2 Bright;
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_ShieldBombRev", random(32, 56), 0, random(-7, 7), 0); }
		"DKNT" UUUUUUUU 1 { A_SpawnProjectile("RS_ShieldBombRev", random(32, 56), 0, random(-7, 7), 0); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_ShieldBombRev", random(32, 56), 0, random(-7, 7), 0); }
		"DKNT" UUUUUUUU 1 { A_SpawnProjectile("RS_ShieldBombRev", random(32, 56), 0, random(-7, 7), 0); }
		"DKNT" U 8 Bright { A_SpawnProjectile("RS_ShieldBlastRev", 44, 0, 0, 0); }
		Goto See;
	Missile.TEX.Grap:
		"DKNT" PTU 3 Bright { A_FaceTarget(); }
		"DKNT" U 3 Bright { A_SpawnProjectile("RS_BlackRevHook", 44, 0, 0, 0); }
		"DKNT" T 3;
		"DKNT" P 2;
		Goto See;
	// The follow-up hook, thrown off-axis so it cannot be walked straight
	// out of. Reached from Melee and from the mine loop.
	Missile.TEX.Grap2:
		"DKNT" PTU 3 Bright { A_FaceTarget(); }
		"DKNT" U 3 Bright { A_SpawnProjectile("RS_BlackRevHook", 44, 0, random(-13, 13), 0); }
		"DKNT" T 3;
		"DKNT" P 2;
		Goto See;
	Missile.TEX.DartCleave:
		"DKNT" E 9 Bright { A_FaceTarget(); }
		"DKNT" F 8 Bright { A_StartSound("monster/kntswg", CHAN_WEAPON); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(-6, -2), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(-3, -1), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(-12, -7), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(-18, 9), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, 0, 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(9, 18), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(7, 12), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(1, 3), 0); }
		"DKNT" G 0 { A_SpawnProjectile("RS_DKDart", 32, 0, random(2, 6), 0); }
		"DKNT" G 5 Bright;
		TNT1 A 0 { A_StartSound("BKFuKINV", CHAN_BODY, 0, 4.0); }
		Goto See;
	Missile.TEX.Mines:
		"DKNT" T 8 Bright { A_FaceTarget(); }
		"DKNT" U 2 Bright { A_FaceTarget(); }
		"DKNT" U 0 { A_SpawnProjectile("RS_MinesRev", 44, -4, -12, 0); }
		"DKNT" U 0 { A_SpawnProjectile("RS_MinesRev", 44, -4, -24, 0); }
		"DKNT" U 0 { A_SpawnProjectile("RS_MinesRev", 44, -4, 24, 0); }
		"DKNT" U 6 Bright { A_SpawnProjectile("RS_MinesRev", 44, -4, 12, 0); }
		"DKNT" U 0 { A_UnSetReflectiveInvulnerable(); }
		"DKNT" U 0 A_Jump(64, "Missile.TEX.Mines");
		"DKNT" U 0 A_Jump(106, "Missile.TEX.Grap2");
		Goto See;
	Missile.TEX.Dash:
		"DKNT" E 8 Bright { A_UnSetReflectiveInvulnerable(); }
		"DKNT" FFFFF 8 Bright { A_SkullAttack(42); }
		"DKNT" G 4 Bright { A_Stop(); }
		"DKNT" U 0 A_Jump(64, "Missile.TEX.Grap", "Missile.TEX.Grap2");
		TNT1 A 0 { A_StartSound("BKFuKINV", CHAN_BODY, 0, 4.0); }
		Goto Melee;
	Pain.TEX:
		"DKNT" H 2;
		"DKNT" H 2 { A_Pain(); }
		"DKNT" P 0 A_Jump(178, "Pain.TEX.Shield");
		Goto See;
	// A 70% answer to being hurt: fifty tics of standing still behind a
	// reflective disc, then the disc is thrown at you and two more spawn.
	Pain.TEX.Shield:
		TNT1 A 0 { bNOPAIN = true; }
		TNT1 A 0 { A_SpawnItemEx("RS_RevShieldWalk", 0, 4, 8, 0, 0, 0, 0, SXF_SETMASTER); }
		"DKNT" P 50;
		"DKNT" T 10 Bright { A_KillChildren("Extreme", KILS_FOILINVUL); }
		"DKNT" U 10 Bright { A_SpawnProjectile("RS_ShieldBlastRev", 44, 0, 0, 0); }
		"DKNT" UUU 9 Bright { A_SpawnItemEx("RS_RevShieldWalk2", 0, 4, 8, 0, 0, 0, 0, SXF_SETTARGET); }
		TNT1 A 0 { bNOPAIN = false; }
		TNT1 A 0 { A_StartSound("BKFuKINV", CHAN_BODY, 0, 4.0); }
		Goto See;
	Death.TEX:
		"DKNT" I 12 Bright { A_KillChildren("Extreme", KILS_FOILINVUL); }
		"DKNT" I 0 { A_SpawnProjectile("RS_DKSword", 44, 32, -90, 0); }
		"DKNT" I 8 Bright { A_SpawnProjectile("RS_DKShield", 44, -32, 90, 0); }
		"DKNT" J 8 Bright;
		"DKNT" J 8 Bright { A_Scream(); }
		"DKNT" J 8 Bright { A_NoBlocking(); }
		// CHP spawns CommonBlackRevenantEX3 here and CommonBlackRevenantEX4
		// four seconds later; RS does both through DeathMorphClass ->
		// RS_RevenantShade, which brings RS_RevenantShadow itself.
		"DKNT" K 8 Bright;
		"DKNT" LMN 8 Bright;
		"DKNT" O 240;
		"DKNT" OOOO 10 { A_SpawnItemEx("RS_BlackRevShade", 0, 0, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"DKNT" O -1;
		Stop;
	}
}

// =====================================================================
// RS_RevenantShade -- stage two of the Black Knight chain.
// SOURCE: CHP 08_K.txt, ACTOR CommonBlackRev2 : BlackRev2 -- the wraith
// the knight gets back up as. CHP defines this creature for the black
// tier only, so its per-tier cluster set is the T00 cluster that every
// tier resolves to; the body table is uniform WRTH for the same reason.
// It brings a bound shadow (RS_RevenantShadow) that dies with it -- the
// RS half of the chain, kept from the previous file.
// =====================================================================

class RS_RevenantShade : RS_MonsterMaster
{
	Default
	{
		Health 2800;
		Radius 20;
		Height 56;
		Mass 300;
		Speed 16;
		FloatSpeed 19;
		PainChance 12;
		Monster;
		+FLOAT +NOGRAVITY MissileChanceMult 0.5;
		SeeSound "skeleton/sight";   PainSound "skeleton/pain";
		DeathSound "skeleton/death"; ActiveSound "skeleton/active";
		Obituary "$OB_UNDEAD";
		Tag "Revenant Shade";
	}

	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 12; r.dmgMul = 1.0;
		if (t < 0 || t > RS_TIER_EX) return false;
		// CHP has one BlackRev2 per colour but they are the same creature
		// at the same numbers; the tier only scales damage.
		//
		// TEX is the exception and is not a scaled T00: a knight that died
		// at TEX leaves CHP's OWN second stage, 08_KX
		// CommonBlackRevenantEX3 -- 6666 HP, speed 18, painchance 12
		// against this class's 2800 / 16 / 12 Default.
		if (t == RS_TIER_EX)
		{
			r.hpMul = 6666.0 / 2800.0; r.spdMul = 18.0 / 16.0;
			r.painChance = 12; r.dmgMul = 2.5;
			return true;
		}
		r.dmgMul = 1.0 + 0.1 * t;
		return true;
	}

	override string BodyTable()
	{
		return "WRTH WRTH WRTH WRTH WRTH WRTH WRTH WRTH WRTH WRTH WRTH WRTH WRTH WRTH";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:revenant role:artillery delivery:heavy element:kinetic mobility:flying trait:secondstage trait:homing";
	}

	override bool MinionsDieWithMe() { return true; }

	States
	{
	Spawn.T00:
		TNT1 A 0
		{
			SummonMinion(RS_MonsterCatalog.MORPH_RevShadow(), 0, 64.0, 0.0);
			A_StartSound(RS_MonsterCatalog.SND_Morph(), CHAN_VOICE);
		}
		"WRTH" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"WRTH" A 3 { A_Chase(); }
		Loop;
	Missile.T00:
		"WRTH" E 5 { A_FaceTarget(); }
		"WRTH" E 0 A_Jump(256, "Missile.T00.Seekers", "Missile.T00.AoE", "Missile.T00.Shots");
		Goto See;
	Missile.T00.Shots:
		"WRTH" F 5 { A_FaceTarget(); }
		"WRTH" G 5 Bright;
		"WRTH" G 0 { A_SpawnProjectile("RS_RevSol", 32, 0, random(-9, 9)); }
		"WRTH" G 0 { A_SpawnProjectile("RS_RevSol", 32, 0, random(-1, 1)); }
		"WRTH" G 0 { A_SpawnProjectile("RS_RevSol", 32, 0, random(-9, 9)); }
		Goto See;
	Missile.T00.AoE:
		"WRTH" FG 5 { A_FaceTarget(); }
		"WRTH" IJ 5 Bright { A_StartSound("Spell/SpellCast1", CHAN_BODY, 0, 3.0); }
		"WRTH" I 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 45, 2); }
		"WRTH" I 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 90, 2); }
		"WRTH" I 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 135, 2); }
		"WRTH" I 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 180, 2); }
		"WRTH" J 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 225, 2); }
		"WRTH" J 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 270, 2); }
		"WRTH" J 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 315, 2); }
		"WRTH" J 0 { A_SpawnProjectile("RS_DKFire2", 0, 0, 0, 2); }
		"WRTH" IF 5;
		Goto See;
	Missile.T00.Seekers:
		"WRTH" F 6 { A_FaceTarget(); }
		"WRTH" G 6 Bright;
		"WRTH" G 0 { A_SpawnProjectile("RS_SoulSeekerRev", 32, 0, random(-19, -9)); }
		"WRTH" G 0 { A_SpawnProjectile("RS_SoulSeekerRev", 32, 0, random(9, 19)); }
		"WRTH" F 6 { A_FaceTarget(); }
		"WRTH" G 6 Bright;
		"WRTH" G 0 { A_SpawnProjectile("RS_SoulSeekerRev", 32, 0, random(-19, -9)); }
		"WRTH" G 0 { A_SpawnProjectile("RS_SoulSeekerRev", 32, 0, random(9, 19)); }
		"WRTH" F 6 { A_FaceTarget(); }
		"WRTH" G 6 Bright;
		"WRTH" G 0 { A_SpawnProjectile("RS_SoulSeekerRev", 32, 0, random(-19, -9)); }
		"WRTH" G 0 { A_SpawnProjectile("RS_SoulSeekerRev", 32, 0, random(9, 19)); }
		"WRTH" F 2 Bright A_MonsterRefire(64, "See");
		Goto Missile.T00.Seekers;
	Pain.T00:
		"WRTH" E 3;
		"WRTH" E 3 { A_Pain(); }
		"WRTH" F 6 A_Jump(128, "Missile.T00.AoE");
		Goto See;
	Death.T00:
		"WRTH" I 8;
		"WRTH" J 8 { A_Scream(); }
		"WRTH" KL 8;
		"WRTH" M 8 { A_NoBlocking(); }
		"WRTH" NOPQ 6;
		TNT1 A 0 { A_SpawnItemEx("RS_CHCirno", 0, 0, 24, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION, 232); }
		"WRTH" R -1 { A_SetFloorClip(); }
		Stop;
	}
}

// =====================================================================
// RS_RevenantShadow -- the bound double the shade brings with it.
// No CHP counterpart: this is the RS half of the chain, kept from the
// previous file and converted to the per-tier cluster pattern. No pain,
// dies with its master; it exists to split the player's attention.
// Wears the knight's own DKNT body at every tier.
// =====================================================================

class RS_RevenantShadow : RS_MonsterMaster
{
	Default
	{
		Health 200;
		Radius 20;
		Height 56;
		Mass 200;
		Speed 18;
		PainChance 0;
		Monster;
		+FLOAT +NOGRAVITY +NOPAIN +DONTFALL
		RenderStyle "Translucent";
		Alpha 0.4;
		DeathSound "skeleton/death";
		Obituary "$OB_UNDEAD";
		Tag "Revenant Shadow";
	}

	// The base ladder covers T00-T12. TEX is the one rung with a real
	// CHP counterpart: 08_KX CommonBlackRevenantEX4, the Black Knight's
	// shadow -- 12000 HP, speed 5, painchance 12, non-shootable and
	// melee-only, which is exactly this creature. Its numbers are used
	// rather than a scaled guess.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t == RS_TIER_EX)
		{
			r.hpMul = 12000.0 / 200.0; r.spdMul = 5.0 / 18.0;
			r.painChance = 12; r.dmgMul = 3.0;
			return true;
		}
		return Super.TierData(t, r);
	}

	override string BodyTable()
	{
		return "DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:revenant role:skirmisher delivery:melee element:kinetic mobility:flying trait:summoned";
	}

	States
	{
	Spawn.T00:
		"DKNT" AB 8 { A_Look(); }
		Loop;
	See.T00:
		"DKNT" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T00:
		"DKNT" E 6 { A_FaceTarget(); }
		"DKNT" F 1 { A_StartSound("monster/dknswg", CHAN_WEAPON); }
		"DKNT" F 6 { A_FaceTarget(); }
		"DKNT" G 6 { A_CustomMeleeAttack(random(10, 40)); }
		Goto See;
	Pain.T00:
		"DKNT" H 2;
		"DKNT" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
		"DKNT" IJ 6;
		"DKNT" K 6 { A_Scream(); }
		"DKNT" LMN 6 { A_NoBlocking(); }
		"DKNT" O -1;
		Stop;
	}
}
