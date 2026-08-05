// =====================================================================
// RS_CG_T0001 -- Green Chaingunner (CH "GreenCGuy")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:1077-1176
// ACTOR:   GreenCGuy : ChaingunGuy
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
// (For the record: CHP gives this colour Health 90, CH gives it 85.
// 85 is what belongs in a CH-only import.)
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Game Doom                     :1079
//   Health 85                     :1080
//   Radius 20                     :1081
//   Height 56                     :1082
//   Mass 100                      :1083
//   Speed 8                       :1084
//   PainChance 150                :1085
//   BloodColor "Green"            :1086
//   DamageFactor "Exorcist", 3.0  :1087
//   DamageFactor "DIMp", 0        :1088
//   PainChance "DIMp", 0          :1089
//   MONSTER                       :1090
//   +FLOORCLIP                    :1091
//   +AVOIDMELEE                   :1092
//   +DONTHARMSPECIES              :1093
//   SeeSound    "chainguy/sight"  :1094
//   PainSound   "chainguy/pain"   :1095
//   DeathSound  "chainguy/death"  :1096
//   ActiveSound "chainguy/active" :1097
//   AttackSound "chainguy/attack" :1098
//   Obituary "%o was greenified"  :1099
//   DropItem x5                   :1100-1104  (see the omission list)
//   Translation (2 ranges)        :1105
//   Tag "Green Chaingunner"       :1106
//
// CH STATES NO SPECIES ON THIS ACTOR, and that is load-bearing, not an
// oversight in the transcription. T00 is Species "CGuy" and T02 is
// Species "Cguy"; the green captain is in NEITHER, so with
// +DONTHARMSPECIES it will happily shoot both of them and they it. The
// TierData row states r.species = "" for exactly this reason.
// zscript/monsters/RS_Chaingunner.zs:157-161 reached the same reading
// independently ("CH states NO Species here -- it breaks the chain").
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH2 (:1111, :1115, :1117, :1121, :1143) -- CH sprinkles
//                       this spawn into Spawn/See/Missile/Pain as a
//                       floating tier marker. Not in our tree, and
//                       RS_HealthBars already shows tier over the
//                       monster's head. See the STATE-INDEX note below --
//                       dropping it does NOT move `Goto Missile+1`.
//   * Tickles (:1146-1148) / ThePlanBoner / CHBoner -- a joke death branch
//                       keyed to a CH-only inventory token that nothing
//                       here grants, so the branch is unreachable by
//                       construction. The Death: guard at :1150 goes with
//                       it.
//   * CHRandom_GibGenerator (:1158) + the A_SpawnParticle("Green")
//                       confetti (:1163) in XDeath -- the gib actor is
//                       CH-only and absent from our tree. The particle
//                       calls are engine intrinsics and WOULD work; they
//                       are dropped only to stay identical to
//                       RS_Chaingunner_C0001_Common.zs, which drops the
//                       pair together.
//   * SplashAbyss burst in Pain.AbyssPE (:1131-1132, 45 spawns each) --
//                       omitted to match C0001's Pain.AbyssPE exactly.
//                       NOTE: RS_SplashAbyss DOES exist in our tree
//                       (zscript/monsters/monsterfx/RS_imp_projectiles.zs
//                       :203), so this one is restorable today -- but it
//                       must go back into every captain at once or the
//                       abyss conversion will look different depending on
//                       who is being converted.
//   * DropItem "implyingclip" (:1101) and "implyingclip",128 (:1102) --
//                       the CH pickup class does not exist anywhere in
//                       this repo (checked *.zs/*.zsc/*.txt; there is no
//                       DECORATE lump). CH's two vanilla drops,
//                       HealthBonus (:1103, :1104), and Chaingun (:1100)
//                       are carried. Restore the clip verbatim the day
//                       the CH pickups are imported.
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * Trail11        -> RS_Trail11        (RS_human_projectiles.zs:717)
//   * BlueCGuy       -> RS_CG_T0002       (CH's Grow target, :1172)
//   * AbyssCGuy2     -> RS_CG_T0008       (CH's Pain.AbyssPE target,
//                       :1133 -- the class name follows
//                       RS_Chaingunner_C0001_Common.zs:132. FLAGGED: the
//                       older single-class ladder in
//                       zscript/monsters/RS_Chaingunner.zs:190 puts
//                       AbyssCGuy2 at tier SIX, and RS_MonsterMaster's own
//                       generic conversion calls SetTier(6). T0008 here is
//                       consistency with the pattern file, not a second
//                       opinion. If T0008 is wrong it is wrong in C0001
//                       and in all five siblings too.)
//   * GrowRaisin     -> RS_CG_GrowRaisin  (defined in C0001)
//
// STATE-INDEX NOTE -- checked, not assumed. CH's Missile ends
// `Goto Missile+1`, and in CH index 1 is the dropped 0-tic
// ColorTierIconCH2 spawn, which falls straight through to index 2, the
// first A_CustomBulletAttack frame. With the icon gone, index 1 IS that
// attack frame. The offset therefore lands on the same state either way
// and `Goto Missile+1` is carried verbatim. (Cyan/T0003 is the one file
// in this set where the arithmetic does NOT survive; see its header.)
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor;
// its roll is A_CustomBulletAttack's 4th argument, random(1,8), plus the
// random(6,17)/random(3,13) spread and the random(1,2) bullet count --
// all four carried verbatim. Nothing was flattened to a constant. Note
// also that `CPOS FE 4` is TWO frames, so the attack fires TWICE per
// pass; that is CH's own doubling and is preserved.
//
// DIVERGENCE FROM C0001, DELIBERATE AND FLAGGED:
//   * TierData sets r.flags. It has to.
//     RS_MonsterMaster.RS_ApplyTierProperties ASSIGNS the flag set
//     absolutely (RS_MonsterMaster.zs:712-776) -- with r.flags left 0 it
//     runs `bAVOIDMELEE = false; bDONTHARMSPECIES = false` at
//     PostBeginPlay and the Default block's flags are silently gone.
//   * The Spawn.T00/See.T00/... alias block at the end of States. See
//     the comment there -- without it MissileState is nulled and this
//     captain never fires a shot.
// =====================================================================

class RS_CG_T0001 : RS_MonsterMaster
{
	Default
	{
		// CH states `Game Doom`; ZScript has no Game actor property (DECORATE
		// only), so it is recorded here rather than declared. Not a loss --
		// this mod is Doom-only.
		Health 85;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 150;
		BloodColor "Green";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Monster;
		+FLOORCLIP
		+AVOIDMELEE
		+DONTHARMSPECIES
		// CH states NO Species -- see the header. Deliberately absent.
		SeeSound "chainguy/sight";
		PainSound "chainguy/pain";
		DeathSound "chainguy/death";
		ActiveSound "chainguy/active";
		AttackSound "chainguy/attack";
		Obituary "%o was greenified";
		// CH's vanilla drops only -- "implyingclip" x2 is itemised in the
		// header. CH lists HealthBonus twice; both are kept.
		DropItem "Chaingun";
		DropItem "HealthBonus";
		DropItem "HealthBonus";
		Translation "32:47=116:127", "31:31=115:115";
		Tag "Green Chaingunner";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 150; r.dmgMul = 1.0;
		// CH states NO Species on GreenCGuy. "" is the base class's
		// "leave alone", which is the correct statement of "this colour
		// is in no species group" -- see the header.
		r.species = "";
		r.bloodColor = "Green";
		// Assigned absolutely by the base class -- see the header.
		r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		CPOS AB 10 A_Look;
		Loop;
	See:
		CPOS AABB 3 A_Chase;
		CPOS CCDD 3 A_Chase;
		Loop;
	Missile:
		CPOS E 12 A_FaceTarget;
		CPOS FE 4 Bright A_CustomBulletAttack(random(6,17), random(3,13),
		                                      random(1,2), random(1,8),
		                                      "RS_Trail11");
		CPOS F 3 A_MonsterRefire(150, "See");
		Goto Missile+1;
	Pain:
		CPOS G 3;
		CPOS G 3 A_Pain;
		Goto See;
	Death:
		CPOS H 5;
		CPOS I 5 A_Scream;
		CPOS J 5 A_NoBlocking;
		CPOS KLM 5;
		CPOS N -1;
		Stop;
	// CH switches the gib frames to the green-tinted CGUG sheet rather
	// than translating CPOS -- gore does not remap cleanly. CGUG O..T
	// ship in sprites/monsters/Chaingunner/T01/. Chaingunners.txt:1157.
	XDeath:
		CGUG O 5;
		CGUG P 5 A_XScream;
		CGUG Q 5 A_NoBlocking;
		CGUG RS 5;
		CGUG T -1;
		Stop;
	Raise:
		CPOS N 5 A_JumpIfInventory("RS_CG_GrowRaisin", 1, "Grow");
		CPOS MLKJIH 5;
		Goto See;
	// CH's own tier promotion: resurrected while "growing" -> the blue
	// captain. Chaingunners.txt:1170.
	Grow:
		CPOS MLKJIH 5;
		CPOS A 0 A_SpawnItemEx("RS_CG_T0002", 0, 0, 6, 0, 0, 0, 0,
		                       SXF_NOCHECKPOSITION | SXF_SETTARGET);
		TNT1 A 0 A_Die;
		Stop;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:1125.
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
