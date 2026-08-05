// =====================================================================
// RS_CG_T0010 -- Red Chaingunner (CH "RedCGuy")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:1707-1818
// ACTOR:   RedCGuy : ChaingunGuy
// ROLE:    T -- tier body, the red captain (detonating rounds)
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// EVERY PROPERTY CH SETS, so a differ can check the list:
//   Health 300      Mass 1000       Speed 10        PainChance 88
//   DamageFactor "Exorcist", 3.0    DamageFactor "DIMp", 0
//   PainChance "DIMp", 0
//   Monster, +FLOORCLIP, +AVOIDMELEE, +DONTHARMSPECIES, +MISSILEMORE,
//   +NOFEAR
//   SeeSound    "cguy2/see"         PainSound   "form2/hurt"
//   DeathSound  "cguy2/die"         ActiveSound "form2/active"
//   AttackSound "chainguy/attack"
//   Obituary "%o got rip'd up by the angry Red Chaingunner"
//   Decal BulletChip                Tag "Red Chaingunner"
//   DropItem CH_ClipBox,232 / CH_Plasmarifle,64 / ArmorBundle,88 /
//            HealthBundle,128 / CH_Berserk,64 / ChainGun /
//            CH_RocketAmmo / CH_RocketAmmo,128
// CH states NO Radius and NO Height -- it inherits vanilla ChaingunGuy
// (20 / 56). That is not an omission on our part: an unstated property
// in CH means "vanilla", and the two numbers are written out below only
// because we descend from RS_MonsterMaster rather than ChaingunGuy, and
// Actor's own defaults (radius 20 / height 16) would be wrong.
// CH states no Translation for this actor -- the CPS2 sprite set is
// already red.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH6 -- CH sprinkles this spawn into Spawn/See/Missile/
//                         Pain as a floating tier marker. Not in our
//                         tree, and RS_HealthBars already shows tier over
//                         the monster's head.
//                         OFFSET CHECK, because this actor has three
//                         `Goto Missile+1`: in CH the icon sits at
//                         Missile index 1 and +1 therefore lands ON the
//                         icon's own 0-tic frame, falling straight
//                         through into the A_JumpIfCloser pair. With the
//                         icon gone, +1 lands directly on
//                         A_JumpIfCloser(500). Same frame, same tic,
//                         same behaviour -- the range band is still
//                         re-rolled every refire, which is the whole
//                         point of this monster.
//   * Tickles / CHBoner / ThePlanBoner -- a joke death branch keyed to a
//                         CH-only inventory token that nothing here
//                         grants, so the branch is unreachable by
//                         construction. The `A_JumpIfInventory("CHBoner"
//                         ,1,"Tickles")` line that opened CH's Death:
//                         goes with it.
//   * SplashAbyss x90 in Pain.AbyssPE -- CH-only splash actor, absent
//                         from our tree. Both 45-frame TNT1 rows dropped.
//   * CHRandom_GibGenerator (x3) + the A_SpawnParticle red confetti (x3)
//                         in XDeath -- CH-only gib actors, absent from
//                         our tree.
//   * ACS -- none; this actor makes no ACS call.
//   * SEVEN CH-ONLY DROPITEMS, none of which is a class in this tree.
//     Itemised with CH's own line so a differ can put them back the day
//     the pickups are ported:
//         DropItem "CH_ClipBox", 232      :1711
//         DropItem "CH_Plasmarifle", 64   :1712
//         DropItem "ArmorBundle", 88      :1713
//         DropItem "HealthBundle", 128    :1714
//         DropItem "CH_Berserk", 64       :1715
//         DropItem "CH_RocketAmmo"        :1717
//         DropItem "CH_RocketAmmo", 128   :1718
//     CH's one vanilla drop (ChainGun :1716) is carried live below.
//
// SOUNDS: "form2/hurt" and "form2/active" ARE in this repo's SNDINFO;
// "cguy2/see" and "cguy2/die" ARE NOT (checked 2026-08-05). Both are
// carried verbatim anyway -- an unresolved sound name is inert, and
// deleting CH's value would lose the only record of what this monster is
// supposed to sound like. Two SNDINFO lines fix it.
//
// RETARGETED, NOT DROPPED:
//   * DetoPuffCG / DetoPuff2 / DetoPuff3 -> RS_DetoPuffCG / RS_DetoPuff2
//     / RS_DetoPuff3 (RS_human_projectiles.zs:405/426/437)
//   * AbyssCGuy2 -> RS_CG_T0008, same retarget the pattern file makes.
//     RS_CG_T0008 is not in the tree yet; RS_Chaingunner_C0001_Common.zs
//     already carries the same forward reference.
//
// TRANSLATED, NOT REWRITTEN: CH's `ThrustThing(angle*256/360+64,20,0,0)`
// keeps its exact arithmetic; the only change is an explicit int() around
// the byte-angle conversion, because ZScript's `angle` is a double and
// ThrustThing's first parameter is an int. 64 and 192 are +90 and +270
// degrees -- Dodge1 sidesteps one way, Dodge2 the other.
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

class RS_CG_T0010 : RS_Chaingunner
{
	Default
	{
		Health 300;
		PainChance 88;
		Mass 1000;
		Speed 10;
		// Vanilla ChaingunGuy's own numbers -- CH states none, so these
		// ARE CH's values. Kept explicit so the differ can read them.
		Radius 20;
		Height 56;
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Monster;
		+FLOORCLIP
		+AVOIDMELEE
		+DONTHARMSPECIES
		+MISSILEMORE
		+NOFEAR
		SeeSound "cguy2/see";
		PainSound "form2/hurt";
		DeathSound "cguy2/die";
		ActiveSound "form2/active";
		AttackSound "chainguy/attack";
		Obituary "%o got rip'd up by the angry Red Chaingunner";
		Decal "BulletChip";
		Tag "Red Chaingunner";
		// CH's vanilla drop only -- the seven CH-only pickups are
		// itemised in the header.
		DropItem "Chaingun";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	//
	// species stays "" ("leave alone") because CH states no Species on
	// RedCGuy and vanilla ChaingunGuy has none either. dmgMul stays 1.0:
	// CH states no damage multiplier, the field is data-only, and any
	// other number would be invented rather than transcribed.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 88; r.dmgMul = 1.0;
		r.species = "";
		// REQUIRED -- see RS_Chaingunner_C0001_Common.zs. Assigned
		// absolutely; omitting it strips Default's flags at spawn.
		r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES | RS_TF_NOFEAR;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		CPS2 AB 10 A_Look;
		Loop;
	See:
		CPS2 AABB 3 A_Chase;
		CPS2 CCDD 3 A_Chase;
		Loop;
	Dodge1:
		CPS2 A 5 ThrustThing(int(angle * 256 / 360) + 64, 20, 0, 0);
		Goto See;
	Dodge2:
		CPS2 A 5 ThrustThing(int(angle * 256 / 360) + 192, 20, 0, 0);
		Goto See;
	// Three range bands, re-rolled on every refire -- see the OFFSET
	// CHECK in the header for why `Goto Missile+1` is still +1.
	Missile:
		CPS2 E 11 A_FaceTarget;
		TNT1 A 0 A_JumpIfCloser(500, "M1");
		TNT1 A 0 A_JumpIfCloser(1300, "M2");
		CPS2 FE 4 A_CustomBulletAttack(random(3, 14), 0, random(1, 2), random(1, 2), "RS_DetoPuff3");
		CPS2 F 1 A_MonsterRefire(64, "See");
		Goto Missile+1;
	M2:
		CPS2 FE 4 A_CustomBulletAttack(random(2, 11), 0, random(1, 2), random(1, 2), "RS_DetoPuff2");
		CPS2 F 1 A_MonsterRefire(64, "See");
		Goto Missile+1;
	M1:
		CPS2 FE 4 A_CustomBulletAttack(random(1, 8), 0, random(1, 3), random(2, 4), "RS_DetoPuffCG");
		CPS2 F 1 A_MonsterRefire(64, "See");
		Goto Missile+1;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:1772.
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
		CPS2 G 3;
		CPS2 G 3 A_Pain;
		CPS2 G 1 A_Jump(128, "Dodge1", "Dodge2");
		Goto See;
	Death:
		CPS2 H 5;
		CPS2 I 5 A_Scream;
		CPS2 J 5 A_Fall;
		CPS2 KLMNO 5;
		CPS2 P -1;
		Stop;
	XDeath:
		CPS2 Q 5;
		CPS2 R 5 A_XScream;
		CPS2 S 5 A_Fall;
		CPS2 TUVW 5;
		CPS2 X -1;
		Stop;
	Raise:
		CPS2 PONMLKJIH 5;
		Goto See;

	// TIER DISPATCH ALIASES -- LOAD-BEARING, see C0001. Without these
	// MissileState resolves null and this captain never fires.
	Spawn.T00:   Goto Spawn;
	See.T00:     Goto See;
	Missile.T00: Goto Missile;
	Pain.T00:    Goto Pain;
	Death.T00:   Goto Death;
	XDeath.T00:  Goto XDeath;
	Raise.T00:   Goto Raise;
	}
}
