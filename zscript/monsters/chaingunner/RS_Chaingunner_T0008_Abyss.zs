// =====================================================================
// RS_CG_T0008 -- Abyss Captain (CH "AbyssCGuy2")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:434-551
// ACTOR:   AbyssCGuy2            (a bare Actor in CH -- NOT : ChaingunGuy)
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// THE CLASS NAME IS LOAD-BEARING. Every other captain's Pain.AbyssPE
// branch spawns "RS_CG_T0008" by name -- that is the Abyss Pain
// Elemental's conversion attack turning a captain into this one.
// RS_Chaingunner_C0001_Common.zs:132 and the T0005/T0006/T0007 files all
// reference it. Renaming this class breaks four conversions silently.
// (ZScript is case-insensitive for class names: RS_CG_T0008 and
// rs_cg_t0008 are the SAME class, so never add a second spelling.)
//
// It STALKS. Once per approach it fades to 10% alpha over five tics and
// keeps chasing; the fade is one-shot, gated by CH's `user_hide` user
// var. Firing or taking a hit snaps it back to solid AND clears the gate,
// so it can vanish again on the next approach. Beyond 700 units it drops
// splash charges directly on you with A_VileTarget; closer in it switches
// to ice rapid-fire.
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Health 500                    :436
//   BloodColor "Black"            :437
//   DamageFactor "Exorcist", 3.0  :438
//   DamageFactor "DIMp", 0        :439
//   PainChance "DIMp", 0          :440
//   Radius 20                     :441
//   Height 56                     :442
//   Speed 8                       :443
//   PainChance 80                 :444
//   MONSTER                       :445
//   +FLOORCLIP                    :446
//   +DONTHARMSPECIES              :447
//   +MISSILEMORE                  :448
//   +MISSILEEVENMORE              :449
//   SeeSound    "lady/aggro"      :450
//   PainSound   "science/pain"    :451
//   DeathSound  "science/die"     :452
//   ActiveSound "lady/active"     :453
//   Obituary                      :454
//   DropItem x10                  :455-464  (see the omission list)
//   Translation (1 blend range)   :465
//   Tag "Abyss Captain"           :466
//   var int user_hide             :467
// CH STATES NO Species FOR THIS ACTOR, and that is not the same as
// sharing one. It carries +DONTHARMSPECIES with nothing to compare
// against, which is CH's own arrangement -- so no Species is written
// here and TierData leaves r.species empty ("" = leave alone). Do not
// "fix" this by copying a neighbour's string.
// CH also states no Mass, no AttackSound and no Game for this actor --
// all left unstated rather than invented.
//
// SOUNDS THAT HAVE NO SNDINFO ENTRY IN THIS REPO (checked ./SNDINFO):
// "science/pain" and "science/die". They are transcribed anyway -- a
// missing sound name is silent, not fatal, and blanking them would lose
// the ground truth. "lady/aggro" (SNDINFO:672) and "lady/active" (:675)
// resolve, as does "AbyssForm" (:693).
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH9 -- CH sprinkles this spawn into Spawn/Missile/
//                       Rapids/Pain as a floating tier marker (:472,
//                       :491, :498, :504, :510, :521). Not in our tree,
//                       and RS_HealthBars already shows tier over the
//                       monster's head.
//   * Tickles (:525-527) / ThePlanBoner / CHBoner -- a joke death branch
//                       keyed to a CH-only inventory token that nothing
//                       here grants, so the branch is unreachable by
//                       construction. The Death: guard at :529 goes
//                       with it.
//   * CHRandom_GibGenerator (:537) + the A_SpawnParticle("Black")
//                       confetti (:539, :542) in XDeath -- the gib actor
//                       is CH-only and absent from our tree. The particle
//                       calls are engine intrinsics and WOULD work; they
//                       are dropped only to stay identical to
//                       RS_Chaingunner_C0001_Common.zs, which drops the
//                       pair together.
//   * CH_Pantsu (:544) in XDeath -- CH-only drop actor, absent here.
//   * DropItem "CH_Cell" (:455), "CH_Cell" (:456), "CH_Cell",128 (:457),
//     "CH_Cell",128 (:458), "CH_Plasmarifle",64 (:459), "ArmorBundle"
//     (:460), "HealthBundle" (:461), "HealthBundle" (:463),
//     "RLOverchargeSystemArmorPickup",46 (:464) -- none of these pickup
//     classes exist anywhere in this repo (checked *.zs/*.zsc/*.txt;
//     there is no DECORATE lump). Only CH's vanilla drop, Chaingun
//     (:462), is carried. This is the heaviest drop list of the four
//     captains; restore it verbatim the day the CH pickups are imported.
//   * NO Pain.AbyssPE HERE, and that is CH's doing, not an omission --
//     AbyssCGuy2 has no such state (it is already the abyss form). The
//     other four captains convert INTO this one.
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * A_CustomMissile -> A_SpawnProjectile (same signature, ZScript's
//     current name), matching zscript/monsters/RS_Chaingunner.zs.
//   * A_Fall -> A_NoBlocking (same function; A_Fall is the alias).
//   * CH's `var int user_hide` + A_SetUserVar/A_JumpIf become a private
//     int field and anonymous-function state bodies. Same shape
//     zscript/monsters/RS_Chaingunner.zs:76,797-807 already uses for
//     CHP's copy of this creature -- DECORATE user vars have no ZScript
//     equivalent, and A_SetUserVar cannot see a ZScript field.
//     Named rsHideUsed, matching that file. RS_MonsterMaster declares no
//     such field, so there is no shadowing (ZScript has none: a subclass
//     field colliding with a base field is a fatal redefinition).
//     NOTE CH writes `A_SetUserVar("user_hide", user_hide=0)` at :492
//     and :522 -- an assignment inside the value expression. The net
//     effect is user_hide := 0 and that is what is written here.
//   * CH's `Goto Missile+5` (:502, :517) BECAME A NAMED LABEL. It counts
//     frames, and dropping the six ColorTierIconCH9 spawns above shifts
//     the count. Missile+5 is the `PZOW E 10 A_FaceTarget` at :493;
//     that frame now carries the label Missile.Loop.
//   * SplashAbyssCguy -> RS_SplashAbyssCguy, which exists at
//     zscript/monsters/monsterfx/RS_human_projectiles.zs:783.
//     AbyssZShotCH3 -> RS_AbyssZShotCH3, same file, :65.
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor
// at all; the only rolls it states are the A_SpawnProjectile angle
// jitters, random(-1,1), and those are carried verbatim. Nothing was
// flattened to a constant. (The damage this thing does lives on
// RS_SplashAbyssCguy and RS_AbyssZShotCH3, which are built separately.)
//
// DIVERGENCE FROM C0001, DELIBERATE AND FLAGGED:
//   * TierData sets r.flags and r.missileChance. It has to.
//     RS_MonsterMaster.RS_ApplyTierProperties ASSIGNS the flag set
//     absolutely (RS_MonsterMaster.zs:714-776) -- with r.flags left 0 it
//     runs `bDONTHARMSPECIES = false` at PostBeginPlay and the Default
//     block's +DONTHARMSPECIES is silently gone.
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

class RS_CG_T0008 : RS_Chaingunner
{
	// CH's `var int user_hide` (Chaingunners.txt:467). One-shot per
	// approach: the fade checks it, the fade sets it, firing and taking
	// pain clear it.
	private int rsHideUsed;

	Default
	{
		Health 500;
		BloodColor "Black";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Radius 20;
		Height 56;
		Speed 8;
		PainChance 80;
		Monster;
		+FLOORCLIP
		+DONTHARMSPECIES
		+MISSILEMORE
		+MISSILEEVENMORE
		SeeSound "lady/aggro";
		PainSound "science/pain";
		DeathSound "science/die";
		ActiveSound "lady/active";
		Obituary "%o met the nasty abyssal chaingunner";
		// CH's vanilla drop only -- the nine CH-only pickups are itemised
		// in the header.
		DropItem "Chaingun";
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
		Tag "Abyss Captain";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 80; r.dmgMul = 1.0;
		// r.species LEFT EMPTY ON PURPOSE -- CH states none (see header).
		// "" is the row's documented "leave alone" value.
		r.bloodColor = "Black";
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
		PZOW AABBCCDD 4 A_Chase;
		PZOW A 0 A_Jump(128, "Hide");
		Loop;
	// One fade per approach. The guard is CH's user_hide.
	Hide:
		TNT1 A 0 { if (rsHideUsed >= 1) return ResolveState("See");
		           return ResolveState(null); }
		PZOW A 1 A_SetTranslucent(0.85);
		PZOW A 1 A_SetTranslucent(0.65);
		PZOW A 1 A_SetTranslucent(0.45);
		PZOW A 1 A_SetTranslucent(0.25);
		PZOW A 1 A_SetTranslucent(0.10);
		PZOW A 1 { rsHideUsed++; }
		Goto See;
	Missile:
		PZOW E 1 A_SetTranslucent(0.33);
		PZOW E 1 A_SetTranslucent(0.66);
		PZOW E 1 A_SetTranslucent(1.00);
		PZOW A 1 { rsHideUsed = 0; }
	// CH re-enters here as `Missile+5` -- see the header note on offsets.
	Missile.Loop:
		PZOW E 10 A_FaceTarget;
		TNT1 A 0 A_JumpIfCloser(700, "Rapids", true);
		PZOW F 4 Bright A_VileTarget("RS_SplashAbyssCguy");
		PZOW E 2 A_FaceTarget;
		PZOW F 4 Bright A_VileTarget("RS_SplashAbyssCguy");
		PZOW E 2 A_FaceTarget;
		TNT1 A 0 A_CheckSight("See");
		PZOW E 0 A_MonsterRefire(128, "See");
		Goto Missile.Loop;
	Rapids:
		PZOW F 3 Bright A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1,1));
		PZOW E 2 A_FaceTarget;
		PZOW F 3 Bright A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1,1));
		PZOW E 2 A_FaceTarget;
		TNT1 A 0 A_CheckSight("See");
		PZOW F 3 Bright A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1,1));
		PZOW E 2 A_FaceTarget;
		PZOW F 3 Bright A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1,1));
		PZOW E 2 A_FaceTarget;
		TNT1 A 0 A_CheckSight("See");
		PZOW E 0 A_MonsterRefire(128, "See");
		Goto Missile.Loop;
	Pain:
		PZOW G 3;
		PZOW E 1 A_SetTranslucent(1.00);
		PZOW A 1 { rsHideUsed = 0; }
		PZOW G 4 A_Pain;
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
