// =====================================================================
// RS_CG_T0003 -- Jetpack Larry (CH "CyanCGuy2")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:256-409
// ACTOR:   CyanCGuy2             (a bare Actor in CH -- NOT : ChaingunGuy)
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
// (For the record: CHP gives this colour Health 150 and the CGCY sprite
// sheet; CH gives it 125 and CPS2. This file is CH's.)
//
// CH's SPAWNER, NOT IMPORTED. `Actor CyanCGuy` at :234 is a thin ACS-gated
// picker -- it calls CH_Cyan and either re-rolls the whole Colourset12
// spawner or spawns CyanCGuy2. It is a spawn-placement wrapper, it needs
// ACS this repo does not have, and RS owns tier selection now. Only
// CyanCGuy2, the actual creature, is here.
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Health 125                    :258
//   Radius 20                     :259
//   Height 56                     :260
//   PainChance 88                 :261
//   DropItem x8                   :262-269  (see the omission list)
//   Mass 3500                     :270
//   Speed 11                      :271
//   BloodColor "Cyan"             :272
//   DamageFactor Fire, 1.5        :273  AND :274 -- CH states it twice
//   DamageFactor melee, 1.5       :275
//   DamageFactor ice, 0.10        :276
//   DamageFactor "Exorcist", 3.0  :277
//   DamageFactor "DIMp", 0        :278
//   PainChance "DIMp", 0          :279
//   DamageFactor falling, 0.0     :280  AND :281 -- CH states it twice
//   RenderStyle Add               :282
//   Alpha 0.95                    :283
//   MONSTER                       :284
//   +FLOORCLIP                    :285
//   +AVOIDMELEE                   :286
//   +DONTHARMSPECIES              :287
//   +MISSILEMORE                  :288
//   +NOFEAR                       :289
//   +NOICEDEATH                   :290
//   +BRIGHT                       :291
//   +LAXTELEFRAGDMG               :292
//   SeeSound    "cguy2/see"       :293
//   PainSound   "form2/hurt"      :294
//   DeathSound  "cguy2/die"       :295
//   ActiveSound "form2/active"    :296
//   AttackSound "chainguy/attack" :297
//   Obituary                      :298
//   Tag "Jetpack Larry"           :299
//   Translation (4 ranges)        :300
// CH states no Game and no Species for this actor -- both are left
// unstated here rather than invented. An unstated property in CH means
// "engine default", and writing one in would make it up. The missing
// Species matters: with +DONTHARMSPECIES and no species string, this
// captain is in no infighting group and will trade fire with every other
// colour. zscript/monsters/RS_Chaingunner.zs:167-176 reads it the same
// way. It is also CH's ONLY chaingunner with both +AVOIDMELEE and
// +MISSILEMORE and a real Alpha, and by far the heaviest at Mass 3500.
//
// THE DUPLICATED DamageFactor LINES ARE CH'S, AND ARE KEPT. CH writes
// Fire and falling twice each, once unquoted and once quoted, with
// identical values. Both copies are carried rather than de-duplicated --
// rule 6 of this import is verbatim, and a reader diffing this file
// against CH should find the same number of lines. They are the first
// thing to delete if the compiler ever objects; nothing is lost, the
// values are identical.
// The lower-case tokens are also CH's. `melee`, `ice` and `falling` are
// written exactly as CH writes them and NOT capitalised to match the
// engine's NAME_Melee / NAME_Ice / NAME_Falling. If CH's casing means
// those three factors never match, that is CH's bug and it is reproduced
// here rather than silently corrected -- correcting it would change the
// creature's resistances, which is not a transcription's job.
//
// SOUNDS NOT YET IN THIS REPO'S SNDINFO -- carried verbatim anyway.
// "cguy2/see" and "cguy2/die" have no entry in E:\RS_Main\SNDINFO. CH
// defines them at CH/SNDINFO.txt:1112 (CGUY2/See = D64FORME) and :1117
// (CGuy2/Die = D64FORD3), and neither lump is in sounds/. Until those two
// lines exist this captain's sight and death cries are silent -- an
// undefined sound name is a no-op, not an error. "form2/hurt" and
// "form2/active" ARE defined (SNDINFO:640, :671) and work today.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH12 (:305, :309, :311, :317, :325, :342, :350, :359,
//                       :369, :392) -- CH sprinkles this spawn into
//                       Spawn/See/See2/Jumpy/Missile/Missile2/Pain as a
//                       floating tier marker. Not in our tree, and
//                       RS_HealthBars already shows tier over the
//                       monster's head. THIS ONE MOVED A STATE OFFSET --
//                       see the STATE-INDEX note below.
//   * CallACS("CH_CyanBounce") == 1 -> "See2" (:324, :332, :337) -- CH's
//                       player-facing option to switch the jetpack off.
//                       There is no ACS in this repo at all (no acs/
//                       directory, no LOADACS) and CallACS on an
//                       undefined script returns 0, so the jump could
//                       never fire even if transcribed. Dropping it
//                       leaves the bouncing permanently ON, which is
//                       CH's behaviour with the option at its default.
//                       zscript/monsters/RS_Chaingunner.zs:58-59 records
//                       the same decision for the same script.
//   * Tickles (:396-398) / ThePlanBoner / CHBoner -- a joke death branch
//                       keyed to a CH-only inventory token that nothing
//                       here grants, so the branch is unreachable by
//                       construction. The Death: guard at :400 goes with
//                       it.
//   * SplashAbyss burst in Pain.AbyssPE (:380-381, 45 spawns each) --
//                       omitted to match C0001's Pain.AbyssPE exactly.
//                       NOTE: RS_SplashAbyss DOES exist in our tree
//                       (zscript/monsters/monsterfx/RS_imp_projectiles.zs
//                       :203), so this one is restorable today -- but it
//                       must go back into every captain at once or the
//                       abyss conversion will look different depending on
//                       who is being converted.
//   * DropItem "CH_ClipBox" (:262), "CH_Plasmarifle",32 (:263),
//     "ArmorBundle",88 (:264), "HealthBundle",128 (:265),
//     "CH_Berserk",64 (:266), "CH_RocketAmmo" (:268) and
//     "CH_RocketAmmo",128 (:269) -- none of these pickup classes exist
//                       anywhere in this repo (checked *.zs/*.zsc/*.txt;
//                       there is no DECORATE lump). Only CH's vanilla
//                       drop, ChainGun (:267), is carried. Restore the
//                       rest verbatim the day the CH pickups are
//                       imported. That is SEVEN of eight drops gone --
//                       this is the richest drop table in the set and it
//                       is currently almost empty.
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * IceZombieShot2 -> RS_IceZombieShot2 (RS_human_projectiles.zs:47)
//   * CH_Cirno       -> RS_CH_Cirno       (RS_arach_projectiles.zs:558)
//   * AbyssCGuy2     -> RS_CG_T0008       (CH's Pain.AbyssPE target,
//                       :382 -- name follows
//                       RS_Chaingunner_C0001_Common.zs:132. FLAGGED: the
//                       older single-class ladder in
//                       zscript/monsters/RS_Chaingunner.zs:190 puts
//                       AbyssCGuy2 at tier SIX, and RS_MonsterMaster's own
//                       generic conversion calls SetTier(6). T0008 here is
//                       consistency with the pattern file, not a second
//                       opinion.)
//   * VelX/VelY/VelZ -> vel.x/vel.y/vel.z (ZScript spelling; identical
//                       values, same as RS_Arachnotron.zs:421 which makes
//                       the same RS_CH_Cirno call).
//   * A_CustomMissile is KEPT and deliberately NOT rewritten to
//     A_SpawnProjectile. They are NOT the same call: A_CustomMissile
//     forwards flags|CMF_BADPITCH. Every shot in this actor's Missile
//     block passes a real pitch (random(-5,5) down to random(-1,1)), so
//     swapping the name here WOULD change where the ice bolts go. The
//     sibling files that renamed it were all pitch-0 calls where it makes
//     no difference. RS_Chaingunner_T0009_Fireblu.zs:149 also keeps the
//     original spelling, so the name is known to compile in this tree.
//
// STATE-INDEX NOTE -- THIS IS THE ONE FILE IN THE SET WHERE THE
// ARITHMETIC DOES NOT SURVIVE, AND IT IS HANDLED EXPLICITLY.
// CH's Missile2 ends `Goto Missile2+1`, and in CH index 0 is the
// ColorTierIconCH12 spawn while index 1 is `CPS2 E 1 A_FaceTarget`. The
// refire loop therefore RE-FACES the target every pass. Simply deleting
// the icon would make index 1 the first firing frame instead, and this
// captain would keep shooting at wherever the player used to be. A bare
// `TNT1 A 0;` placeholder holds index 0 so `Goto Missile2+1` stays
// verbatim and still lands on A_FaceTarget. DO NOT DELETE IT AS DEAD.
// (In Missile, See, See2, Jumpy and Pain the icon is not at a referenced
// offset, so it is simply gone.)
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor;
// the projectile carries it (RS_IceZombieShot2, Damage 9). What this
// actor rolls is AIM -- the twelve narrowing spread pairs from
// random(-11,11)/random(-5,5) down to random(-1,1) (:344-366) -- and all
// twenty-two rolls are carried verbatim. That narrowing IS the attack:
// Larry walks his fire onto the target. Nothing was flattened.
//
// DIVERGENCE FROM CH, DELIBERATE AND FLAGGED:
//   * CH gives CyanCGuy2 NO Raise state at all, which in CH means an
//     archvile cannot resurrect it. That is NOT REPRESENTABLE here:
//     RS_MonsterMaster always exposes a Raise dispatcher
//     (RS_MonsterMaster.zs:1896-1898), so RaiseState is non-null on every
//     subclass and the engine will offer the corpse to A_VileChase
//     regardless. Left alone, the base dispatcher's fallback is a bare
//     `Goto See` -- the corpse would snap upright with no animation. This
//     file therefore ships a reverse-death Raise in its OWN body, exactly
//     the resolution zscript/monsters/RS_Chaingunner.zs:61-66 documented
//     and :627-629 implemented for this same colour. It is an ADDITION,
//     it is not in CH, and it is here rather than silent.
//   * CH gives it no XDeath either; XDeath.T00 aliases to Death, matching
//     RS_Chaingunner.zs:624-626 ("it always shatters").
//   * TierData sets r.flags and r.missileChance. It has to.
//     RS_MonsterMaster.RS_ApplyTierProperties ASSIGNS the flag set
//     absolutely (RS_MonsterMaster.zs:712-776) -- with r.flags left 0 it
//     runs `bAVOIDMELEE = false; bDONTHARMSPECIES = false; bNOFEAR =
//     false; bNOICEDEATH = false; bLAXTELEFRAGDMG = false` at
//     PostBeginPlay and five of the Default block's flags are silently
//     gone. +FLOORCLIP and +BRIGHT have no RS_TF_ constant and are never
//     touched, so the Default's copies stand.
//   * The Spawn.T00/See.T00/... alias block at the end of States. See
//     the comment there -- without it MissileState is nulled and this
//     captain never fires a shot.
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

class RS_CG_T0003 : RS_Chaingunner
{
	Default
	{
		// CH states no Game and no Species -- see the header. Absent
		// deliberately, not forgotten.
		Health 125;
		Radius 20;
		Height 56;
		PainChance 88;
		// CH's vanilla drop only -- the seven CH-only pickups are itemised
		// in the header. "ChainGun" is CH's own casing (:267).
		DropItem "ChainGun";
		Mass 3500;
		Speed 11;
		BloodColor "Cyan";
		DamageFactor "Fire", 1.5;       // :273 -- CH states Fire twice,
		DamageFactor "Fire", 1.5;       // :274    unquoted then quoted
		DamageFactor "melee", 1.5;      // :275 -- CH's own lower case
		DamageFactor "ice", 0.10;       // :276 -- CH's own lower case
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		DamageFactor "falling", 0.0;    // :280 -- and again, twice,
		DamageFactor "falling", 0.0;    // :281    CH's own lower case
		RenderStyle "Add";
		Alpha 0.95;
		Monster;
		+FLOORCLIP
		+AVOIDMELEE
		+DONTHARMSPECIES
		+MISSILEMORE
		+NOFEAR
		+NOICEDEATH
		+BRIGHT
		+LAXTELEFRAGDMG
		// cguy2/* have no SNDINFO entry in this repo yet -- see header.
		SeeSound "cguy2/see";
		PainSound "form2/hurt";
		DeathSound "cguy2/die";
		ActiveSound "form2/active";
		AttackSound "chainguy/attack";
		Obituary "%o was frost torn by cyan chaingunner";
		Tag "Jetpack Larry";
		Translation "0:255=%[0.30,0.57,1.22]:[1.01,2.00,2.00]",
		            "88:90=%[0.00,0.00,1.76]:[0.43,1.22,2.00]",
		            "61:61=%[0.00,0.00,1.59]:[0.52,0.52,2.00]",
		            "57:57=%[0.09,0.02,1.35]:[0.03,0.38,1.74]";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 88; r.dmgMul = 1.0;
		// CH states NO Species on CyanCGuy2. "" is the base class's
		// "leave alone", which is the correct statement of "this colour
		// is in no species group" -- see the header.
		r.species = "";
		r.bloodColor = "Cyan";
		r.radius = 20; r.height = 56; r.mass = 3500;
		r.alpha = 0.95; r.renderStyle = STYLE_Add;
		// Assigned absolutely by the base class -- see the header.
		r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES
		        | RS_TF_NOFEAR | RS_TF_NOICEDEATH
		        | RS_TF_LAXTELEFRAGDMG;
		// +MISSILEMORE. LOWER FIRES MORE (RS_MonsterMaster.zs:94-98).
		r.missileChance = 0.5;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		CPS2 AB 10 A_Look;
		Loop;
	// The jetpack. Roughly a quarter of chase decisions go to a sideways
	// hop, and most of the rest re-roll between a normal chase and the
	// LOS-gated leap.
	See:
		CPS2 AABB 2 A_Chase;
		CPS2 CCDD 2 A_Chase;
		TNT1 A 0 A_Jump(64, "Dodge1", "Dodge2");
		TNT1 A 0 A_Jump(232, "SeeMe", "See2");
		Loop;
	See2:
		CPS2 AABBCCDD 1 A_FastChase;
		Goto See;
	SeeMe:
		CPS2 A 0 A_JumpIfInTargetLOS("Jumpy", 0, JLOSF_DEADNOJUMP, 750);
		Goto See;
	Jumpy:
		CPS2 A 2 A_FastChase;
		CPS2 A 1 ThrustThingZ(0, 64, 0, 0);
		CPS2 A 3 ThrustThing(angle - randompick(130, 180, 230), 12, 0, 0);
		CPS2 A 1 ThrustThingZ(0, 32, 0, 0);
		CPS2 A 1 ThrustThing(angle, 24, 0, 0);
		Goto See;
	Dodge1:
		TNT1 A 0 ThrustThingZ(0, 68, 0, 0);
		CPS2 A 5 ThrustThing(angle*256/360 + 64, 20, 0, 0);
		Goto See;
	Dodge2:
		TNT1 A 0 ThrustThingZ(0, 68, 0, 0);
		CPS2 A 5 ThrustThing(angle*256/360 + 192, 20, 0, 0);
		Goto See;
	// TWELVE SHOTS OF NARROWING SPREAD, then the tight loop in Missile2.
	// The A_CheckSight between every pair is CH's own -- lose sight and
	// the whole burst is abandoned mid-walk. Falls through into Missile2.
	Missile:
		CPS2 E 11 A_FaceTarget;
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-11,11), 0, random(-5,5));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-10,10), 0, random(-4,4));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-9,9), 0, random(-4,4));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-8,8), 0, random(-3,3));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-7,7), 0, random(-3,3));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-6,6), 0, random(-2,2));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-5,5), 0, random(-2,2));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-4,4), 0, random(-1,1));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-3,3), 0, random(-1,1));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-2,2));
		TNT1 A 0 A_CheckSight("See");
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, random(-1,1));
		TNT1 A 0 A_CheckSight("See");
	Missile2:
		// STATE-INDEX PLACEHOLDER -- DO NOT DELETE. CH's index 0 here is
		// the ColorTierIconCH12 spawn (:369) and `Goto Missile2+1` below
		// deliberately skips it to land on A_FaceTarget. Removing this
		// line makes the refire loop skip A_FaceTarget instead and Larry
		// hoses empty air. See the STATE-INDEX note in the header.
		TNT1 A 0;
		CPS2 E 1 A_FaceTarget;
		CPS2 FE 3 A_CustomMissile("RS_IceZombieShot2", 32, 0, 0);
		CPS2 F 1 A_MonsterRefire(64, "See");
		Goto Missile2+1;
	Pain:
		CPS2 G 3;
		CPS2 G 3 A_Pain;
		CPS2 G 1 A_Jump(128, "Dodge1", "Dodge2");
		Goto See;
	Death:
		CPS2 H 5;
		CPS2 I 5 A_Scream;
		CPS2 J 5 A_NoBlocking(false);
		CPS2 KLMNO 5;
		TNT1 A 0 A_SpawnItemEx("RS_CH_Cirno", 0, 0, 24, vel.x, vel.y, vel.z, 0,
		                       SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION, 254);
		CPS2 P 5 A_IceGuyDie;
		Stop;
	// NOT IN CH -- see the DIVERGENCE list in the header. CH ships this
	// actor with no Raise, which the base class cannot represent, so the
	// death frames are played backwards rather than letting the base
	// dispatcher snap the corpse upright with no animation. Same fix, same
	// colour, as zscript/monsters/RS_Chaingunner.zs:627-629.
	Raise:
		CPS2 ONMLKJIH 5;
		Goto See;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:374.
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

	// TIER-CLUSTER ALIASES -- NOT COSMETIC, AND NOT IN CH.
	// RS_MonsterMaster.ApplyTier does `MissileState = TierState("Missile")`
	// (RS_MonsterMaster.zs:640-641), and TierState looks up
	// "Missile.<tier>" then "Missile.T00" with exact=true
	// (RS_MonsterMaster.zs:1015-1020). A plain `Missile:` label does NOT
	// satisfy that, so MissileState would be assigned NULL at
	// PostBeginPlay and this captain would never fire. The same lookup
	// drives the post-retier pendingStateJump into "Spawn.T00"/"See.T00".
	// A label whose whole body is a Goto resolves at compile time, so
	// these are true aliases and cost nothing at runtime.
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
	// Neither CH nor CHP gives cyan an XDeath -- it always shatters.
	XDeath.T00:
		Goto Death;
	Raise.T00:
		Goto Raise;
	}
}
