// =====================================================================
// RS_CG_T0009 -- "Bad makeup day" (CH "FireBluCGuy2")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:827-942
// ACTOR:   FireBluCGuy2   (a BARE Actor in CH -- it does NOT inherit
//                          ChaingunGuy, so nothing is carried in from
//                          vanilla and every number below is stated by
//                          CH itself)
// ROLE:    T -- tier body, the fireblu captain
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// EVERY PROPERTY CH SETS, so a differ can check the list:
//   Health 450                       Radius 20        Height 56
//   Species "Cguy3"                  Speed 18         PainChance 135
//   BloodColor "Blue"
//   DamageFactor "Exorcist", 3.0     DamageFactor "DIMp", 0
//   PainChance "DIMp", 0
//   MONSTER, +FLOORCLIP, +DONTHARMSPECIES, +MISSILEMORE
//   SeeSound    "lady/aggro"         PainSound   "lady/hurt"
//   DeathSound  "lady/die"           ActiveSound "lady/active"
//   Obituary "%o got fireblu'd by fireblu chaingunner"
//   Tag "Bad makeup day"
//   Translation (17 ranges, line 855) -- carried verbatim
//   DropItem CH_Cell / CH_Plasmarifle,64 / Chaingun / ArmorBundle,64 /
//            HealthBonus / HealthBonus / HealthBundle,128
// CH states NO Mass and NO AttackSound for this actor. A bare CH Actor
// gets the engine default Mass 100, which is what we already inherit --
// writing a number here would invent one.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH7 -- CH sprinkles this spawn into Spawn/See/Dodge/
//                         Missile/Pain as a floating tier marker. Not in
//                         our tree, and RS_HealthBars already shows tier
//                         over the monster's head. NOTE: every one of
//                         those lines is 0-tic and this actor contains
//                         no `Goto <state>+N`, so removing them cannot
//                         move a jump target. Checked, not assumed.
//   * Tickles / CHBoner / ThePlanBoner -- a joke death branch keyed to a
//                         CH-only inventory token that nothing here
//                         grants, so the branch is unreachable by
//                         construction. The `A_JumpIfInventory("CHBoner"
//                         ,1,"Tickles")` line that opened CH's Death:
//                         goes with it.
//   * SplashAbyss x90 in Pain.AbyssPE -- CH-only splash actor, absent
//                         from our tree. Both 45-frame TNT1 rows dropped.
//   * CH_Pantsu in XDeath (line 935) -- CH-only gag pickup, absent from
//                         our tree. A_SpawnItemEx takes a class<Actor>,
//                         so an unresolvable name here is a COMPILE
//                         error, not a silent no-op.
//   * ACS -- none; this actor makes no ACS call.
//   * FOUR CH-ONLY DROPITEMS, none of which is a class in this tree.
//     Itemised with CH's own line so a differ can put them back the day
//     the pickups are ported:
//         DropItem "CH_Cell"            :848
//         DropItem "CH_Plasmarifle", 64 :849
//         DropItem "ArmorBundle", 64    :851
//         DropItem "HealthBundle", 128  :854
//     CH's three vanilla drops (Chaingun :850, HealthBonus :852,
//     HealthBonus :853) are carried live below.
//
// SOUNDS: "lady/aggro|hurt|die|active" ARE defined in this repo's
// SNDINFO (SUCAGGRO/SUCHURT/SUCDIE/SUCHA), so all four are carried live.
//
// RETARGETED, NOT DROPPED:
//   * FireBCGguy  -> RS_FireBCGguy (RS_spidermind_projectiles.zs:249)
//   * AbyssCGuy2  -> RS_CG_T0008, same retarget the pattern file makes.
//     RS_CG_T0008 is not in the tree yet; RS_Chaingunner_C0001_Common.zs
//     already carries the same forward reference.
//
// CH QUIRK KEPT ON PURPOSE: See: and Dodge: each end with an A_Jump(88)
// into the other, so the actor flip-flops between A_Chase and
// A_FastChase roughly a third of the time. That is CH's fireblu, not a
// bug; do not "unify" the two loops.
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

class RS_CG_T0009 : RS_Chaingunner
{
	Default
	{
		Health 450;
		Species "Cguy3";
		BloodColor "Blue";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Radius 20;
		Height 56;
		Speed 18;
		PainChance 135;
		Monster;
		+FLOORCLIP
		+DONTHARMSPECIES
		+MISSILEMORE
		SeeSound "lady/aggro";
		PainSound "lady/hurt";
		DeathSound "lady/die";
		ActiveSound "lady/active";
		Obituary "%o got fireblu'd by fireblu chaingunner";
		// CH's vanilla drops only -- the four CH-only pickups are
		// itemised in the header.
		DropItem "Chaingun";
		DropItem "HealthBonus";
		DropItem "HealthBonus";
		Translation "160:162=196:198", "163:166=177:183", "167:167=205:205",
		            "112:114=197:200", "115:117=176:179", "118:121=200:203",
		            "122:125=182:186", "126:127=205:207", "96:101=200:205",
		            "104:111=185:191", "99:107=198:204", "48:63=175:183",
		            "64:79=200:207", "19:31=199:207", "5:15=201:207",
		            "144:159=176:191", "128:143=197:207";
		Tag "Bad makeup day";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	//
	// dmgMul stays 1.0: CH states no damage multiplier anywhere on this
	// actor, the field is data-only (RS_MonsterTierRow does not apply it),
	// and any other number would be invented rather than transcribed.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 135; r.dmgMul = 1.0;
		r.species = "Cguy3";
		// REQUIRED -- see RS_Chaingunner_C0001_Common.zs. Assigned
		// absolutely; omitting it strips Default's flags at spawn.
		r.flags = RS_TF_DONTHARMSPECIES;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		PZOW AB 10 A_Look;
		Loop;
	See:
		PZOW AABB 4 A_Chase;
		PZOW CCDD 4 A_Chase;
		PZOW A 0 A_Jump(88, "Dodge");
		Loop;
	Dodge:
		PZOW AABB 4 A_FastChase;
		PZOW CCDD 4 A_FastChase;
		PZOW A 0 A_Jump(88, "See");
		Loop;
	Missile:
		PZOW E 10 A_FaceTarget;
		PZOW F 4 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-1, 1));
		PZOW F 1 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-15, 15));
		PZOW F 1 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-35, 35));
		PZOW E 2 A_FaceTarget;
		PZOW F 4 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-1, 1));
		PZOW E 2 A_FaceTarget;
		PZOW F 3 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-3, 3));
		PZOW F 1 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-15, 15));
		PZOW F 1 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-35, 35));
		PZOW E 2 A_FaceTarget;
		PZOW F 3 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-2, 2));
		PZOW E 2 A_FaceTarget;
		PZOW F 2 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-1, 1));
		PZOW F 1 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-15, 15));
		PZOW F 1 A_CustomMissile("RS_FireBCGguy", 31, 4, random(-35, 35));
		Goto See;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:897.
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
		PZOW G 3;
		PZOW G 3 A_Pain;
		PZOW G 1 A_Jump(128, "Dodge");
		Goto See;
	Death:
		PZOW H 5;
		PZOW I 5 A_Scream;
		PZOW J 5 A_Fall;
		PZOW KLM 5;
		PZOW N -1;
		Stop;
	XDeath:
		PZOW O 5;
		PZOW P 5 A_XScream;
		PZOW Q 5 A_Fall;
		PZOW RSTUV 5;
		PZOW W -1;
		Stop;
	Raise:
		PZOW MLKJIH 5;
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
