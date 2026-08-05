// =====================================================================
// RS_CG_B0002 -- The crazy lady scientist (CH "WhiteCguy2")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:2520-2705
// ACTOR:   WhiteCguy2   (a BARE Actor in CH -- it does NOT inherit
//                        ChaingunGuy, so nothing is carried in from
//                        vanilla and every number below is stated by CH
//                        itself)
// ROLE:    B -- boss body. 7777 HP, +BOSS, a summoner with a phase 2.
//
// THE NAME. "The crazy lady scientist" is CH's own Tag, line 2577.
// Nothing here is invented flavour -- if a name is not in CH it is not
// in this file.
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
// (Worth knowing while reading: CHP's own white chaingunner is 6666 HP.
// CH's is 7777. This file is CH's number.)
//
// EVERY PROPERTY CH SETS, so a differ can check the list:
//   Game Doom       Health 7777     Species "Science"
//   Radius 19       Height 52       Mass 90         Speed 14
//   PainChance 20   RadiusDamageFactor 0.5
//   DamageFactor "Melee", 3.75      DamageFactor "Heroic", 3.0
//   DamageFactor "DIMp", 0          PainChance "DIMp", 0
//   MONSTER, +FLOORCLIP, +THRUSPECIES, +DONTHARMSPECIES, +BOSS,
//   -NORADIUSDMG, +DONTMORPH, +MISSILEMORE, +DONTHARMCLASS, +NOFEAR
//   Var Int User_Ph2   (rebuilt as the private field below)
//   SeeSound    "science/devi"      PainSound   "science/pain"
//   DeathSound  "science/die"       ActiveSound "lady/active"
//   Obituary "%o fell to the power of science"
//   Tag "The crazy lady scientist"
//   DropItem CH_SoulSphere / BackPack / BackPackBundle /
//            CH_CellPack,174 x3 / CH_Cell,174 x9 / CH_BFG9000,64 /
//            CH_Chainsaw,128 / CH_BlueArmor,128 /
//            RLPrototypeAssaultShieldArmorPickup,32 /
//            RLMedicalPowerArmorPickup,32 /
//            RLLegendaryWeaponSpawner,4 / RLUniqueWeaponSpawner,16 /
//            RareArmorPool,128 / LewdLabCoat / Chaingun
// Note the radius/height: 19 x 52, NOT the family's usual 20 x 56. She
// is deliberately a slightly smaller target than the men. CH also
// states NO Translation -- the FSZS sprite set is already her body.
// CH ships NO XDeath and NO Raise for her; that is CH's choice, not a
// transcription gap.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH11 -- CH sprinkles this spawn into Idle/See/See2/
//                         Missile/Pain as a floating tier marker. Not in
//                         our tree, and RS_HealthBars already shows tier
//                         over the monster's head.
//                         OFFSET CHECK: this actor contains NO
//                         `Goto <state>+N` at all -- every jump is to a
//                         bare label. Removing 0-tic lines therefore
//                         cannot move a target. Checked, not assumed.
//   * ACS_NamedExecuteAlways("AnnounceWhiteCG") on line 2584 -- CH's
//                         boss-arrival announcer script. No ACS by that
//                         name exists in this repo, and the repo's own
//                         convention (see RS_Chaingunner.zs header) is
//                         to strip ACS rather than leave a dangling
//                         call. The Spawn -> Scripted -> Idle shape is
//                         kept so the state layout still matches CH and
//                         the announcer can be dropped straight back in.
//   * CH_Cactus in Death (line 2701) -- CH-only gag pickup, absent from
//                         our tree. A_SpawnItemEx takes a class<Actor>,
//                         so an unresolvable name there is a COMPILE
//                         error, not a silent no-op. The whole
//                         A_SpawnItemEx line is dropped; the death
//                         animation is otherwise untouched.
//   * Tickles / CHBoner / ThePlanBoner -- CH does not give her this
//                         branch at all. Listed only so the absence is
//                         not read as a deletion.
//   * TWENTY-THREE CH-ONLY DROPITEMS, none of which is a class in this
//     tree. Four of them are DoomRL Arsenal's, not CH's own. She has by
//     far the fattest drop table in the family, so the count matters --
//     itemised with CH's own line so a differ can put them back the day
//     the pickups are ported:
//         DropItem "CH_SoulSphere"                             :2551
//         DropItem "BackPackBundle"                            :2553
//         DropItem "CH_CellPack", 174                          :2555
//         DropItem "CH_CellPack", 174                          :2556
//         DropItem "CH_CellPack", 174                          :2557
//         DropItem "CH_Cell", 174                              :2558
//         DropItem "CH_Cell", 174                              :2559
//         DropItem "CH_Cell", 174                              :2560
//         DropItem "CH_Cell", 174                              :2561
//         DropItem "CH_Cell", 174                              :2562
//         DropItem "CH_Cell", 174                              :2563
//         DropItem "CH_Cell", 174                              :2564
//         DropItem "CH_Cell", 174                              :2565
//         DropItem "CH_Cell", 174                              :2566
//         DropItem "CH_BFG9000", 64                            :2567
//         DropItem "CH_Chainsaw", 128                          :2568
//         DropItem "CH_BlueArmor", 128                         :2569
//         DropItem "RLPrototypeAssaultShieldArmorPickup", 32   :2570
//         DropItem "RLMedicalPowerArmorPickup", 32             :2571
//         DropItem "RLLegendaryWeaponSpawner", 4               :2572
//         DropItem "RLUniqueWeaponSpawner", 16                 :2573
//         DropItem "RareArmorPool", 128                        :2574
//         DropItem "LewdLabCoat"                               :2575
//     CH's two vanilla drops (BackPack :2552, Chaingun :2576) are
//     carried live below.
//
// SOUNDS: "lady/active" IS in this repo's SNDINFO (SUCHA).
// "science/devi", "science/pain", "science/die", "Science/Atk" and
// "Science/Enuff" are NOT (checked 2026-08-05). They are carried
// verbatim anyway -- an unresolved sound name is inert, and deleting
// CH's value would lose the only record of what this boss is supposed
// to sound like. Five SNDINFO lines fix it.
//
// RETARGETED, NOT DROPPED:
//   * Puddle1      -> RS_Puddle1      (RS_human_projectiles.zs:205)
//   * NeedlesCg1   -> RS_NeedlesCg1   (RS_human_projectiles.zs:198)
//   * NeedlesCg2   -> RS_NeedlesCg2   (RS_human_projectiles.zs:204)
//   * VolativeCaco -> RS_VolativeCaco (RS_human_projectiles.zs:1000)
//   * SlimyWorm    -> RS_SlimyWorm    (RS_human_projectiles.zs:1052)
//   * SpliceBaron  -> RS_SpliceBaron  (RS_human_projectiles.zs:1109)
//   VolativeCaco, SlimyWorm and SpliceBaron are NOT chaingunners -- they
//   are her live experiments, and they live in Chaingunners.txt only
//   because she summons them. They are already in this tree; this file
//   builds none of them.
//
// A_SetUserVar IS GONE, replaced by a real field. CH's `User_Ph2` is a
// one-shot latch: the first time she drops below 5555 HP she takes the
// Phase2 branch, and every later Missile roll that reaches Phase2 finds
// the latch set and diverts to "Nah" -- which is the WIDER attack table
// (five options instead of four, and the only route to Puddle2,
// DartStorm and Summon3). Phase 2 is not a single scripted beat, it is
// a permanent change of repertoire.
//
// MULTI-FRAME ACTIONS, DELIBERATE, DO NOT "FIX". CH stacks frames on a
// single action line specifically to fire it N times:
//   * Puddle    `FSZS FF 0   A_CustomMissile("Puddle1",...)`   = 2 puddles
//   * Puddle2   `FSZS FFFF 0 A_CustomMissile("Puddle1",...)`   = 4 puddles
//   * Summon2   `FSZS FFF 3  A_SpawnItemEx("SlimyWorm",...)`   = 3 worms
//   * Phase2    `FSZS FF 0   A_SpawnItemEx("SpliceBaron",...)` = 2 barons
// Collapsing any of these to one call would quietly quarter the attack.
//
// CH QUIRK KEPT ON PURPOSE: Phase2 sets NOPAIN true and NOTHING in this
// actor ever sets it false. Past 5555 HP she cannot be staggered again.
// That is what CH ships. Left alone.
//
//
// SOUNDS: RESOLVED 2026-08-05. Any note below saying a sound name is
// NOT in this repo SNDINFO is STALE. CH sound library was imported
// that day -- 693 lumps into sounds/ch/ and 804 SNDINFO definitions,
// including the $random directives. Every sound name this file uses
// now resolves end to end to a real lump. Verified, not assumed.
// TIER ICONS: RESTORED 2026-08-05, and NOT from this file.
// CH pastes an A_SpawnItemEx("ColorTierIconCH<n>") line into Spawn,
// See, Missile and Pain of every actor. Those lines are 0-tic, and
// `Goto X+N` offsets COUNT FRAMES -- so adding or removing one silently
// retargets every jump after it in that state. That hazard already cost
// two placeholder frames in this family.
// RS_MonsterMaster emits the icon on a timer instead (RS_EmitTierIcon).
// Identical on screen, cannot shift an offset, and every one of the
// seventeen families gets it rather than just the ones edited by hand.
// Gated on rs_mon_tiericons, off by default exactly as CH ships it.
// Anything below claiming the icons were dropped is superseded by this.

// =====================================================================

class RS_CG_B0002 : RS_Chaingunner
{
	// CH's `Var Int User_Ph2;` (line 2550), rebuilt as a real field.
	// Named for this family so it cannot collide with RS_MonsterMaster's
	// own members -- ZScript has no shadowing, and a subclass field that
	// silently matches a base field is a fatal redefinition.
	private int rsWhitePh2;

	Default
	{
		// CH states `Game Doom`; ZScript has no Game actor property (DECORATE
		// only), so it is recorded here rather than declared. Not a loss --
		// this mod is Doom-only.
		Health 7777;
		Species "Science";
		RadiusDamageFactor 0.5;
		DamageFactor "Melee", 3.75;
		DamageFactor "Heroic", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Mass 90;
		Speed 14;
		Radius 19;
		Height 52;
		PainChance 20;
		Monster;
		+FLOORCLIP
		+THRUSPECIES
		+DONTHARMSPECIES
		+BOSS
		-NORADIUSDMG
		+DONTMORPH
		+MISSILEMORE
		+DONTHARMCLASS
		+NOFEAR
		SeeSound "science/devi";
		PainSound "science/pain";
		DeathSound "science/die";
		ActiveSound "lady/active";
		Obituary "%o fell to the power of science";
		Tag "The crazy lady scientist";
		// CH's vanilla drops only -- the twenty-three CH-only pickups
		// are itemised in the header.
		DropItem "BackPack";
		DropItem "Chaingun";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	//
	// dmgMul stays 1.0: CH states no damage multiplier, the field is
	// data-only (RS_MonsterTierRow does not apply it), and any other
	// number would be invented rather than transcribed -- a boss
	// multiplier is a design decision, not a CH fact.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 20; r.dmgMul = 1.0;
		r.species = "Science";
		// REQUIRED -- see RS_Chaingunner_C0001_Common.zs. Assigned
		// absolutely; omitting it strips Default's flags at spawn.
		r.flags = RS_TF_THRUSPECIES | RS_TF_DONTHARMSPECIES | RS_TF_BOSS
		        | RS_TF_DONTMORPH | RS_TF_DONTHARMCLASS | RS_TF_NOFEAR;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		FSZS A 0;
		Goto Scripted;
	// CH fires ACS_NamedExecuteAlways("AnnounceWhiteCG") here. The script
	// is not in this repo; the state is kept so the layout still matches
	// CH and the announcer drops straight back in.
	Scripted:
		FSZS A 0;
		Goto Idle;
	Idle:
		FSZS AB 10 A_Look;
		Loop;
	See:
		FSZS AABB 4 A_Chase;
		FSZS A 0 A_Jump(64, "See2");
		FSZS CCDD 4 A_Chase;
		FSZS A 0 A_Jump(64, "See2");
		Loop;
	See2:
		FSZS AABB 4 A_FastChase;
		FSZS A 0 A_Jump(64, "See");
		FSZS CCDD 4 A_FastChase;
		FSZS A 0 A_Jump(64, "See");
		Loop;
	Missile:
		FSZS E 4 A_FaceTarget;
		FSZS E 0 A_JumpIfHealthLower(5555, "Phase2");
		FSZS E 0 A_Jump(256, "Puddle", "Summon1", "Darts", "Summon2");
		Goto See;
	Puddle:
		FSZS E 8 A_FaceTarget;
		FSZS F 9 Bright;
		FSZS FF 0 A_CustomMissile("RS_Puddle1", 40, 0, random(-60, 60), 2, random(10, 30));
		Goto See;
	Puddle2:
		FSZS E 8 A_FaceTarget;
		FSZS F 9 Bright;
		FSZS FFFF 0 A_CustomMissile("RS_Puddle1", 56, 0, random(-80, 80), 2, random(12, 35));
		Goto See;
	Darts:
		FSZS E 1 A_FaceTarget;
		FSZS F 6 Bright;
		FSZS F 1 Bright A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-5, 5));
		FSZS E 1 A_FaceTarget;
		FSZS E 0 A_CheckSight("See");
		FSZS F 1 Bright A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15));
		FSZS E 1 A_FaceTarget;
		FSZS E 0 A_CheckSight("See");
		FSZS F 1 Bright A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-25, 25));
		FSZS E 2 A_MonsterRefire(128, "See");
		Goto Darts;
	DartStorm:
		FSZS E 1 A_FaceTarget;
		FSZS F 6 Bright;
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-35, 35));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-25, 25));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-35, 35));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15));
		FSZS F 1 Bright A_CustomMissile("RS_NeedlesCg2", random(32, 42), 7, random(-5, 5));
		FSZS E 6 A_FaceTarget;
		FSZS E 0 A_CheckSight("See");
		FSZS F 8 Bright A_CustomMissile("RS_NeedlesCg2", random(32, 42), 7, random(-5, 5));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-35, 35));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg1", random(32, 42), 7, random(-25, 25));
		FSZS E 6 A_FaceTarget;
		FSZS E 0 A_CheckSight("See");
		FSZS F 8 Bright A_CustomMissile("RS_NeedlesCg2", random(32, 42), 7, random(-5, 5));
		FSZS F 0 A_CustomMissile("RS_NeedlesCg2", random(32, 42), 7, random(-25, 25));
		FSZS E 6 A_FaceTarget;
		FSZS E 2 A_Jump(128, "DartStorm");
		FSZS E 2 A_Jump(64, "Darts");
		Goto See;
	Summon1:
		FSZS E 3 A_FaceTarget;
		FSZS F 2 A_PlaySound("Science/Atk");
		FSZS F 2 A_PainAttack("RS_VolativeCaco");
		FSZS FA 2;
		Goto See;
	Summon2:
		FSZS E 3 A_FaceTarget;
		FSZS F 2 A_PlaySound("Science/Atk");
		FSZS FFF 3 A_SpawnItemEx("RS_SlimyWorm", random(-64, 64), random(-64, 64), random(5, 15),
		                         0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION);
		FSZS FA 2;
		Goto See;
	Summon3:
		FSZS E 12 A_FaceTarget;
		FSZS E 12 A_PlaySound("Science/Atk");
		FSZS F 12;
		FSZS F 8 A_SpawnItemEx("RS_SpliceBaron", random(-64, 64), random(-64, 64), random(5, 15),
		                       0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION);
		FSZS F 12;
		FSZS A 8;
		Goto See;
	// One-shot. Once the latch is set, every later trip through here
	// diverts to Nah -- the wider phase-2 attack table.
	Phase2:
		FSZS E 0 A_ChangeFlag("NOPAIN", true);
		FSZS E 0 { if (rsWhitePh2 >= 1) return ResolveState("Nah"); return ResolveState(null); }
		FSZS E 20;
		FSZS G 8 A_PlaySound("Science/Enuff");
		FSZS G 7 A_SetSpeed(19);
		FSZS E 8 { rsWhitePh2++; }
		FSZS F 12;
		FSZS FF 0 A_SpawnItemEx("RS_SpliceBaron", random(-64, 64), random(-64, 64), random(5, 15),
		                        0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION);
		FSZS A 5;
		Goto See;
	Nah:
		FSZS E 0 A_Jump(256, "Summon1", "Puddle2", "DartStorm", "Summon2", "Summon3");
		Goto See;
	Pain:
		FSZS G 3;
		FSZS G 3 A_Pain;
		Goto See;
	Death:
		FSZS H 11;
		FSZS I 11 A_Scream;
		FSZS J 11 A_NoBlocking;
		FSZS KLM 11;
		FSZS N -1;
		Stop;

	}
}
