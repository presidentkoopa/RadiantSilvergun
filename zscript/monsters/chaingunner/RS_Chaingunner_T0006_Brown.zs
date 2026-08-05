// =====================================================================
// RS_CG_T0006 -- Brown Noise Maker (CH "BrownCGuy2")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:40-160
// ACTOR:   BrownCGuy2            (a bare Actor in CH -- NOT : ChaingunGuy)
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// The one that DEPLOYS COVER. It throws BrownSandBagCGuy props out in
// front of itself -- actual monsters with 80 HP and -COUNTKILL -- and
// then walks its aim in behind them. The sandbags carry the SAME
// species string it does ("BrownCguy", CH:168), so with
// +DONTHARMSPECIES it cannot shoot its own cover. That is the whole
// trick; do not normalise the species string.
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Health 250                    :42
//   BloodColor "red"              :43
//   DamageFactor "Exorcist", 3.0  :44
//   DamageFactor "DIMp", 0        :45
//   PainChance "DIMp", 0          :46
//   species "BrownCguy"           :47   (CH's own casing -- kept)
//   Radius 20                     :48
//   Height 56                     :49
//   Speed 6                       :50
//   PainChance 102                :51
//   MONSTER                       :52
//   +FLOORCLIP                    :53
//   +DONTHARMSPECIES              :54   AND AGAIN at :58 -- CH lists it
//                                       twice. Both lines are kept; a
//                                       repeated flag is harmless and
//                                       deleting one is an edit CH did
//                                       not make.
//   +MISSILEMORE                  :55
//   +AVOIDMELEE                   :56
//   +NOINFIGHTING                 :57
//   +NOFEAR                       :59
//   SeeSound    "cguy2/see"       :60
//   PainSound   "form2/hurt"      :61
//   DeathSound  "cguy2/die"       :62
//   ActiveSound "form2/active"    :63
//   AttackSound "chainguy/attack" :64
//   Obituary                      :65
//   DropItem x8                   :66-73  (see the omission list)
//   Translation (4 ranges)        :74
//   Tag "Brown Noise Maker"       :75
// CH states no Mass and no Game for this actor -- both are left unstated
// here rather than invented.
//
// SOUNDS THAT HAVE NO SNDINFO ENTRY IN THIS REPO (checked ./SNDINFO):
// "cguy2/see" and "cguy2/die". They are transcribed anyway -- a missing
// sound name is silent, not fatal, and blanking them would lose the
// ground truth. "form2/hurt" (SNDINFO:640), "form2/active" (:671) and
// vanilla "chainguy/attack" all resolve.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH13 -- CH sprinkles this spawn into See/Missile/
//                       More/M1/Pain as a floating tier marker (:83,
//                       :85, :90, :92, :104, :110, :133). Not in our
//                       tree, and RS_HealthBars already shows tier over
//                       the monster's head.
//   * Tickles (:137-139) / ThePlanBoner / CHBoner -- a joke death branch
//                       keyed to a CH-only inventory token that nothing
//                       here grants, so the branch is unreachable by
//                       construction. The Death: guard at :141 goes
//                       with it.
//   * CHRandom_GibGenerator (:149) in XDeath -- CH-only gib actor,
//                       absent from our tree.
//   * SplashAbyss burst in Pain.AbyssPE (:121-122, 45 spawns each) --
//                       omitted to match C0001's Pain.AbyssPE exactly.
//                       NOTE: RS_SplashAbyss DOES exist in our tree
//                       (zscript/monsters/monsterfx/RS_imp_projectiles.zs
//                       :203), so this one is restorable today -- but it
//                       must go back into all five captains at once.
//   * DropItem "ImplyingClip" (:66), "ImplyingClip",128 (:67),
//     "ImplyingClip",128 (:68), "ArmorBundle",64 (:69),
//     "HealthBundle",128 (:73) -- none of these pickup classes exist
//     anywhere in this repo (checked *.zs/*.zsc/*.txt; there is no
//     DECORATE lump). CH's vanilla drops ARE carried: HealthBonus twice
//     (:70, :71) and ChainGun (:72, CH's spelling).
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * A_CustomMissile -> A_SpawnProjectile (same signature, ZScript's
//     current name), matching zscript/monsters/RS_Chaingunner.zs.
//   * A_Fall -> A_NoBlocking (same function; A_Fall is the alias).
//   * CH's NUMERIC STATE OFFSETS BECAME NAMED LABELS, and this is the
//     one change that had to happen. `Goto Missile+6` (:100, :105) and
//     `Goto M1+1` (:114) count frames -- and dropping the seven
//     ColorTierIconCH13 spawns above shifts every one of those counts.
//     Left as numbers they would land mid-burst. Missile+6 is the
//     `CZV1 U 5 A_FaceTarget` at :93 and M1+1 is the one at :108;
//     those two frames now carry the labels Missile.Loop and M1.Loop.
//   * A_CheckProximity(...,"ChaingunGuy",...,CPXF_ANCESTOR,...) at :89
//     is carried verbatim, BUT BE AWARE IT CANNOT MATCH ITS SIBLINGS
//     HERE: RS_CG_* descend from RS_MonsterMaster, not from ChaingunGuy,
//     so the ancestor test only ever sees a literal vanilla ChaingunGuy.
//     In CH it matched CommonCGuy, which IS `: ChaingunGuy`. Left as CH
//     wrote it rather than silently re-pointed -- retarget it at
//     RS_MonsterMaster (or at the specific captains) when the family's
//     shape is settled.
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor
// at all; its rolls live in the action calls -- A_CustomBulletAttack's
// random(2,9) three times over -- and every one is carried verbatim.
// Nothing was flattened to a constant.
//
// DIVERGENCE FROM C0001, DELIBERATE AND FLAGGED:
//   * TierData sets r.flags and r.missileChance. It has to.
//     RS_MonsterMaster.RS_ApplyTierProperties ASSIGNS the flag set
//     absolutely (RS_MonsterMaster.zs:714-776) -- with r.flags left 0 it
//     runs `bDONTHARMSPECIES = false` at PostBeginPlay, and for THIS
//     actor that means it starts shooting its own sandbags. +AVOIDMELEE,
//     +NOINFIGHTING and +NOFEAR go the same way.
//   * The Spawn.T00/See.T00/... alias block at the end of States. See
//     the comment there -- without it MissileState is nulled and this
//     gunner never fires a shot.
// =====================================================================

class RS_CG_T0006 : RS_MonsterMaster
{
	Default
	{
		Health 250;
		BloodColor "red";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Species "BrownCguy";
		Radius 20;
		Height 56;
		Speed 6;
		PainChance 102;
		Monster;
		+FLOORCLIP
		+DONTHARMSPECIES
		+MISSILEMORE
		+AVOIDMELEE
		+NOINFIGHTING
		+DONTHARMSPECIES        // CH states it twice (:54 and :58)
		+NOFEAR
		SeeSound "cguy2/see";
		PainSound "form2/hurt";
		DeathSound "cguy2/die";
		ActiveSound "form2/active";
		AttackSound "chainguy/attack";
		Obituary "%o got rolled out by brown chaingunner";
		// CH's vanilla drops only -- the five CH-only pickups are
		// itemised in the header.
		DropItem "HealthBonus";
		DropItem "HealthBonus";
		DropItem "ChainGun";
		Translation "96:111=@56[79,39,30]", "3:3=74:74",
		            "9:12=236:239", "82:95=67:79";
		Tag "Brown Noise Maker";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 102; r.dmgMul = 1.0;
		r.species = "BrownCguy";
		r.bloodColor = "red";
		// Assigned absolutely by the base class -- see the header. The
		// species guard here is what keeps its own sandbags alive.
		r.flags = RS_TF_DONTHARMSPECIES | RS_TF_AVOIDMELEE
		        | RS_TF_NOINFIGHTING    | RS_TF_NOFEAR;
		// +MISSILEMORE alone = 0.5. LOWER FIRES MORE
		// (RS_MonsterMaster.zs:94-98). CH does NOT give this one
		// +MISSILEEVENMORE, unlike the yellow/gray/abyss captains.
		r.missileChance = 0.5;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		CZV1 AB 10 A_Look;
		Loop;
	See:
		CZV1 AABB 4 A_Chase;
		CZV1 CCDD 4 A_Chase;
		Loop;
	Missile:
		CZV1 U 5 A_FaceTarget;
		TNT1 A 0 A_CheckProximity("More", "ChaingunGuy", 128, 1,
		                          CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		CZV1 UUU 10 A_SpawnItemEx("RS_BrownSandBagCGuy", 32, random(-32,32), 12,
		                          random(3,9), 0, random(3,9), random(-9,9),
		                          SXF_NOCHECKPOSITION);
	// CH re-enters here as `Missile+6` -- see the header note on offsets.
	Missile.Loop:
		CZV1 U 5 A_FaceTarget;
		TNT1 A 0 A_JumpIfCloser(1400, "M1");
		CZV1 F 5 Bright A_CustomBulletAttack(2, 2, 1, random(2,9), "BulletPuff");
		CZV1 F 5 Bright A_CustomBulletAttack(4, 4, 1, random(2,9), "BulletPuff");
		CZV1 F 5 Bright A_CustomBulletAttack(6, 6, 1, random(2,9), "BulletPuff");
		CZV1 F 1 A_CheckSight("See");
		CZV1 F 1 A_MonsterRefire(64, "See");
		Goto Missile.Loop;
	// Another captain is standing close by -- put out a lot more cover.
	More:
		CZV1 UUU 10 A_SpawnItemEx("RS_BrownSandBagCGuy", 32, random(-64,64), 12,
		                          random(3,14), 0, random(4,14), random(-18,18),
		                          SXF_NOCHECKPOSITION);
		CZV1 UUU 10 A_SpawnItemEx("RS_BrownSandBagCGuy", 64, random(-64,64), 12,
		                          random(5,14), 0, random(4,14), random(-18,18),
		                          SXF_NOCHECKPOSITION);
		Goto Missile.Loop;
	M1:
		CZV1 E 10 Bright;
	// CH re-enters here as `M1+1` -- see the header note on offsets.
	M1.Loop:
		CZV1 E 5 A_FaceTarget;
		CZV1 FE 3 A_SpawnProjectile("RS_BrownOrbCguy", 32, -6, random(-5,5), 0,
		                            random(-1,5));
		CZV1 FE 3 A_SpawnProjectile("RS_BrownOrbCguy", 32, -6, random(-5,5), 0,
		                            random(-1,5));
		CZV1 F 1 A_CheckSight("See");
		CZV1 F 1 A_MonsterRefire(64, "See");
		Goto M1.Loop;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:115.
	Pain.AbyssPE:
		TNT1 A 0 A_ChangeFlag("NOPAIN", true);
		TNT1 A 0 A_SetScale(0.8, 0.8);
		AYPB AAB 5 Bright;
		AYPB B 5 Bright A_PlaySound("AbyssForm", 0);
		AYPB BBACDE 5 Bright;
		TNT1 A 0 A_SpawnItemEx("RS_CG_T0008", 0, 0, 0, 0, 0, 0, 0,
		                       SXF_NOCHECKPOSITION | SXF_TRANSFERSPECIAL |
		                       SXF_TRANSFERAMBUSHFLAG);
		AYPB FGH 3 Bright;
		AYPB I 5 Bright A_SetScale(1, 0.75);
		AYPB H 5 Bright A_SetScale(1, 0.5);
		AYPB I 5 Bright A_SetScale(1, 0.25);
		AYPB H 5 Bright A_SetScale(1, 0.05);
		TNT1 A 0 A_Die;
		Stop;
	Pain:
		CZV1 G 3;
		CZV1 G 3 A_Pain;
		CZV1 G 1;
		Goto See;
	Death:
		CZV1 H 5;
		CZV1 I 5 A_Scream;
		CZV1 J 5 A_NoBlocking;
		CZV1 KLM 5;
		CZV1 M -1;      // CH ends on M, not N (:146) -- kept as written
		Stop;
	XDeath:
		CZV1 NO 5;
		CZV1 P 5 A_XScream;
		CZV1 Q 5 A_NoBlocking;
		CZV1 RS 5;
		CZV1 S -1;
		Stop;
	Raise:
		CZV1 MLKJIH 5;
		Goto See;

	// TIER-CLUSTER ALIASES -- NOT COSMETIC, AND NOT IN CH.
	// RS_MonsterMaster.ApplyTier does `MissileState = TierState("Missile")`
	// (RS_MonsterMaster.zs:640-641), and TierState looks up
	// "Missile.<tier>" then "Missile.T00" with exact=true
	// (RS_MonsterMaster.zs:1015-1020). A plain `Missile:` label does NOT
	// satisfy that, so MissileState would be assigned NULL at
	// PostBeginPlay and this gunner would never fire. The same lookup
	// drives the post-retier pendingStateJump into "Spawn.T00"/"See.T00".
	// A label whose whole body is a Goto resolves at compile time, so
	// these are true aliases and cost nothing at runtime.
	// RS_Chaingunner_C0001_Common.zs has the same hole and no aliases --
	// flagged for the owner rather than edited from here.
	Spawn.T00:
		Goto Spawn;
	See.T00:
		Goto See;
	Missile.T00:
		Goto Missile;
	Pain.T00:
		Goto Pain;
	Death.T00:
		Goto Death;
	XDeath.T00:
		Goto XDeath;
	Raise.T00:
		Goto Raise;
	}
}
