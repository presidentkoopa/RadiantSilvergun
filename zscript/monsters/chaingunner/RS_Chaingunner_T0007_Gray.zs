// =====================================================================
// RS_CG_T0007 -- That is bad camo (CH "GrayCGuy2")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:601-740
// ACTOR:   GrayCGuy2             (a bare Actor in CH -- NOT : ChaingunGuy)
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// The sniper. It opens every engagement by PAINTING you: fifteen tics of
// facing, then A_VileTarget("CHBSTarget") drops a marker on the target,
// then twenty more tics before the first round leaves the barrel. That
// long tell is the fight -- the four range bands after it (>1400, 1400,
// 800, 400) only tighten the spread and raise the per-bullet roll.
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Health 275                    :603
//   BloodColor "white"            :604
//   DamageFactor "Exorcist", 3.0  :605
//   DamageFactor "DIMp", 0        :606
//   PainChance "DIMp", 0          :607
//   Radius 20                     :608
//   Height 56                     :609
//   Speed 10                      :610
//   PainChance 135                :611
//   MONSTER                       :612
//   +FLOORCLIP                    :613
//   +DONTHARMSPECIES              :614
//   +MISSILEMORE                  :615
//   +MISSILEEVENMORE              :616
//   SeeSound    "lady/aggro"      :617
//   PainSound   "lady/hurt"       :618
//   DeathSound  "lady/die"        :619
//   ActiveSound "lady/active"     :620
//   Obituary                      :621
//   DropItem x8                   :622-629  (see the omission list)
//   Translation (8 ranges)        :630
//   Tag "That is bad camo"        :631
// CH STATES NO Species FOR THIS ACTOR, and that is not the same as
// sharing one. It carries +DONTHARMSPECIES with nothing to compare
// against, which is CH's own arrangement -- so no Species is written
// here and TierData leaves r.species empty ("" = leave alone). Do not
// "fix" this by copying a neighbour's string; that would silently rewire
// the family's infighting web.
// CH also states no Mass, no AttackSound and no Game for this actor --
// all left unstated rather than invented.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH8 -- CH sprinkles this spawn into Spawn/See/Missile/
//                       Pain as a floating tier marker (:636, :640, :642,
//                       :645, :713). Not in our tree, and RS_HealthBars
//                       already shows tier over the monster's head.
//   * Tickles (:717-719) / ThePlanBoner / CHBoner -- a joke death branch
//                       keyed to a CH-only inventory token that nothing
//                       here grants, so the branch is unreachable by
//                       construction. The Death: guard at :721 goes
//                       with it.
//   * CH_Pantsu (:733) in XDeath -- CH-only drop actor, absent here.
//                       (This actor has NO CHRandom_GibGenerator and no
//                       A_SpawnParticle confetti -- CH gives it neither,
//                       so there is nothing else in XDeath to drop.)
//   * SplashAbyss burst in Pain.AbyssPE (:701-702, 45 spawns each) --
//                       omitted to match C0001's Pain.AbyssPE exactly.
//                       NOTE: RS_SplashAbyss DOES exist in our tree
//                       (zscript/monsters/monsterfx/RS_imp_projectiles.zs
//                       :203), so this one is restorable today -- but it
//                       must go back into all five captains at once.
//   * DropItem "ImplyingClip" (:622), "ImplyingClip",128 (:623),
//     "ImplyingClip",128 (:624), "ArmorBundle",64 (:625),
//     "HealthBundle",128 (:629) -- none of these pickup classes exist
//     anywhere in this repo (checked *.zs/*.zsc/*.txt; there is no
//     DECORATE lump). CH's vanilla drops ARE carried: HealthBonus twice
//     (:626, :627) and ChainGun (:628, CH's spelling).
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * A_Fall -> A_NoBlocking (same function; A_Fall is the alias).
//   * CHBSTarget -> RS_CHBSTarget, which exists at
//     zscript/monsters/monsterfx/RS_cyberdemon_projectiles.zs:421.
//   * GrayCGuff -> RS_GrayCGuff, the bullet puff, at
//     zscript/monsters/monsterfx/RS_human_projectiles.zs:389.
//   * This actor has no numeric state offsets -- every branch ends
//     `Goto See` -- so nothing had to be re-labelled.
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor
// at all; its rolls live in the action calls -- A_CustomBulletAttack's
// random(1,6) / random(2,9) / random(3,10) / random(4,12), one roll per
// band, five times each -- and every one is carried verbatim. Nothing
// was flattened to a constant. The four bands differ ONLY in spread and
// in that roll, so flattening any of them would erase the range grammar.
//
// DIVERGENCE FROM C0001, DELIBERATE AND FLAGGED:
//   * TierData sets r.flags and r.missileChance. It has to.
//     RS_MonsterMaster.RS_ApplyTierProperties ASSIGNS the flag set
//     absolutely (RS_MonsterMaster.zs:714-776) -- with r.flags left 0 it
//     runs `bDONTHARMSPECIES = false` at PostBeginPlay and the Default
//     block's +DONTHARMSPECIES is silently gone.
//   * The Spawn.T00/See.T00/... alias block at the end of States. See
//     the comment there -- without it MissileState is nulled and this
//     sniper never fires a shot.
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

class RS_CG_T0007 : RS_MonsterMaster
{
	Default
	{
		Health 275;
		BloodColor "white";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Radius 20;
		Height 56;
		Speed 10;
		PainChance 135;
		Monster;
		+FLOORCLIP
		+DONTHARMSPECIES
		+MISSILEMORE
		+MISSILEEVENMORE
		SeeSound "lady/aggro";
		PainSound "lady/hurt";
		DeathSound "lady/die";
		ActiveSound "lady/active";
		Obituary "%o was sniped by gray chaingunner";
		// CH's vanilla drops only -- the five CH-only pickups are
		// itemised in the header.
		DropItem "HealthBonus";
		DropItem "HealthBonus";
		DropItem "ChainGun";
		Translation "160:167=96:108", "112:114=90:92", "115:117=93:95",
		            "118:127=96:111", "32:47=104:111", "27:31=96:98",
		            "186:186=0:0", "128:143=104:111";
		Tag "That is bad camo";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 135; r.dmgMul = 1.0;
		// r.species LEFT EMPTY ON PURPOSE -- CH states none (see header).
		// "" is the row's documented "leave alone" value.
		r.bloodColor = "white";
		// Assigned absolutely by the base class -- see the header.
		r.flags = RS_TF_DONTHARMSPECIES;
		// +MISSILEMORE and +MISSILEEVENMORE stacked = 0.0625. LOWER FIRES
		// MORE (RS_MonsterMaster.zs:94-98).
		r.missileChance = 0.0625;
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
		Loop;
	Missile:
		PZOW E 15 A_FaceTarget;
		PZOW E 5 A_VileTarget("RS_CHBSTarget");
		PZOW E 20 A_FaceTarget;
		TNT1 A 0 A_JumpIfCloser(400, "M3");
		TNT1 A 0 A_JumpIfCloser(800, "M2");
		TNT1 A 0 A_JumpIfCloser(1400, "M1");
		PZOW F 5 Bright A_CustomBulletAttack(2, 2, 1, random(1,6), "RS_GrayCGuff");
		PZOW E 4 A_FaceTarget;
		PZOW F 4 Bright A_CustomBulletAttack(2, 2, 1, random(1,6), "RS_GrayCGuff");
		PZOW E 3 A_FaceTarget;
		PZOW F 3 Bright A_CustomBulletAttack(2, 2, 1, random(1,6), "RS_GrayCGuff");
		PZOW E 2 A_FaceTarget;
		PZOW F 2 Bright A_CustomBulletAttack(2, 2, 1, random(1,6), "RS_GrayCGuff");
		PZOW E 1 A_FaceTarget;
		PZOW F 1 Bright A_CustomBulletAttack(2, 2, 1, random(1,6), "RS_GrayCGuff");
		Goto See;
	M1:
		PZOW F 5 Bright A_CustomBulletAttack(1, 1, 1, random(2,9), "RS_GrayCGuff");
		PZOW E 4 A_FaceTarget;
		PZOW F 4 Bright A_CustomBulletAttack(1, 1, 1, random(2,9), "RS_GrayCGuff");
		PZOW E 3 A_FaceTarget;
		PZOW F 2 Bright A_CustomBulletAttack(1, 1, 1, random(2,9), "RS_GrayCGuff");
		PZOW E 2 A_FaceTarget;
		PZOW F 2 Bright A_CustomBulletAttack(1, 1, 1, random(2,9), "RS_GrayCGuff");
		PZOW E 1 A_FaceTarget;
		PZOW F 1 Bright A_CustomBulletAttack(1, 1, 1, random(2,9), "RS_GrayCGuff");
		Goto See;
	M2:
		PZOW F 5 Bright A_CustomBulletAttack(0, 0, 1, random(3,10), "RS_GrayCGuff");
		PZOW E 4 A_FaceTarget;
		PZOW F 4 Bright A_CustomBulletAttack(0, 0, 1, random(3,10), "RS_GrayCGuff");
		PZOW E 3 A_FaceTarget;
		PZOW F 3 Bright A_CustomBulletAttack(0, 0, 1, random(3,10), "RS_GrayCGuff");
		PZOW E 2 A_FaceTarget;
		PZOW F 2 Bright A_CustomBulletAttack(0, 0, 1, random(3,10), "RS_GrayCGuff");
		PZOW E 1 A_FaceTarget;
		PZOW F 1 Bright A_CustomBulletAttack(0, 0, 1, random(3,10), "RS_GrayCGuff");
		Goto See;
	M3:
		PZOW F 5 Bright A_CustomBulletAttack(0, 0, 1, random(4,12), "RS_GrayCGuff");
		PZOW E 4 A_FaceTarget;
		PZOW F 4 Bright A_CustomBulletAttack(0, 0, 1, random(4,12), "RS_GrayCGuff");
		PZOW E 3 A_FaceTarget;
		PZOW F 3 Bright A_CustomBulletAttack(0, 0, 1, random(4,12), "RS_GrayCGuff");
		PZOW E 2 A_FaceTarget;
		PZOW F 2 Bright A_CustomBulletAttack(0, 0, 1, random(4,12), "RS_GrayCGuff");
		PZOW E 1 A_FaceTarget;
		PZOW F 1 Bright A_CustomBulletAttack(0, 0, 1, random(4,12), "RS_GrayCGuff");
		Goto See;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:695.
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
		PZOW G 1;
		Goto See;
	Death:
		PZOW H 5;
		PZOW I 5 A_Scream;
		PZOW J 5 A_NoBlocking;
		PZOW KLM 5;
		PZOW N -1;
		Stop;
	XDeath:
		PZOW O 5;
		PZOW P 5 A_XScream;
		PZOW Q 5 A_NoBlocking;
		PZOW RSTUV 5;
		PZOW W -1;
		Stop;
	Raise:
		PZOW MLKJIH 5;
		Goto See;

	// TIER-CLUSTER ALIASES -- NOT COSMETIC, AND NOT IN CH.
	// RS_MonsterMaster.ApplyTier does `MissileState = TierState("Missile")`
	// (RS_MonsterMaster.zs:640-641), and TierState looks up
	// "Missile.<tier>" then "Missile.T00" with exact=true
	// (RS_MonsterMaster.zs:1015-1020). A plain `Missile:` label does NOT
	// satisfy that, so MissileState would be assigned NULL at
	// PostBeginPlay and this sniper would never fire. The same lookup
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
