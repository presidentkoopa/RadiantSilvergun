// ============================================================================
// rs_mg_caco.zs -- RS_MGCaco.  STAGING; see rs_mg_base.zs.
//
// The floating bruiser.  Stock A_HeadAttack, no gravity, a big slow body that
// closes on you in a straight line.  All its gore is BLUE -- it uses the
// XDeath1Blue / XDeath2blue / FlyingBloodParticleBigblue variants throughout
// rather than the red set everything else spawns.
//
// ART: 3 custom sequences -> 3 coloured tiers.
//      CCD2 (death)  CCD3 (plasma)  CRSH (crush)
//
// ---------------------------------------------------------------------------
// TWO REAL DEFECTS IN THE SOURCE.  NEITHER IS FIXED HERE.  OWNER'S CALL.
// ---------------------------------------------------------------------------
// 1. Death2 IS UNREACHABLE.  It is written first in the block, but Death: is
//    the entry point the engine uses and Death: never jumps to it.  So the
//    entire vanilla-frame death (HEAD G-L, with the deflating A_SetScale
//    animation and A_SetFloorClip) is dead code, and every normal death runs
//    the CCD2 gib sequence instead.  Compare the revenant, where the same
//    idea IS wired up: `A_Jump(128, "Death2")` sits at the top of Death.
//
// 2. Death2 jumps to "XDeath", AND THIS CLASS HAS NO XDeath STATE.  Nothing
//    else in the file defines one for it either.  Being unreachable, it never
//    fires today -- but wiring up defect 1 without noticing defect 2 would
//    turn a dead branch into a live jump at a label that does not exist.
//
// Read together these look like one lost edit: a Death: -> Death2 jump that
// was dropped, and an XDeath sequence that was never written.  Guessing at the
// repair means inventing a monster's death animation, which is exactly the
// class of "obvious fix" that has silently damaged monster work here before.
// Reported, not repaired.
// ============================================================================

class RS_MGCaco : RS_MG_Monsters
{
	Default
	{
		Health 400;
		Radius 31;
		Height 56;
		Mass 400;
		Speed 8;
		PainChance 128;
		RenderStyle "Add";
		Alpha 1;
		Monster;
		+FLOORCLIP
		+FLOAT
		+NOGRAVITY
		SeeSound "caco/sight";
		PainSound "caco/pain";
		DeathSound "caco/death";
		ActiveSound "caco/active";
		Obituary "$OB_CACO";
		HitObituary "$OB_CACOHIT";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "caco"; }
	override string MonIdentity() { return "class:cacodemon species:cacodemon role:bruiser trait:projectile trait:flying faction:hell set:gore"; }

	override int MGTiers() { return 3; }   // CCD2 CCD3 CRSH

	// ------------------------------------------------------------------------
	// 400 HP base, and a slightly GENEROUS ladder for its weight class
	// (x1.6 to x2.3) -- more than the revenant gets off a similar base.
	//
	// It can carry that because it is the easiest large target in the game to
	// hit.  Radius 31, floating, no strafing, and it approaches head-on in a
	// straight line, so almost every shot the player takes at it lands.  HP on
	// a monster you cannot miss converts into time-to-kill honestly, without
	// the frustration of HP on something evasive.
	//
	// The other half of the reason is that its attack is a single slow
	// telegraphed fireball with a long wind-up (HEAD B, C, then D).  Extra
	// seconds alive buy it comparatively few extra shots, so the HP is not
	// secretly buying damage the way it would on the revenant or the archvile.
	//
	// Three rungs only, and the ceiling (920) sits just under a Baron.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 640;   // x1.6
			case HFMT_CYAN:    return 760;   // x1.9  -- fast; a caco that keeps pace
			case HFMT_BLUE:    return 920;   // x2.3  -- ceiling, just under a Baron
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		HEAD A 10 A_Look;
		Loop;
	See:
		HEAD A 3 A_Chase;
		Loop;
	Missile:
		HEAD B 5 A_FaceTarget;
		HEAD C 5 A_FaceTarget;
		HEAD D 5 BRIGHT A_HeadAttack;
		Goto See;
	Pain:
		HEAD E 3;
		HEAD E 3 A_Pain;
		HEAD F 6;
		Goto See;
	// UNREACHABLE -- nothing jumps here, and its own A_Jump targets an XDeath
	// state this class does not define.  See the file header.
	Death2:
		TNT1 A 0;
		TNT1 A 0 A_Jump(160, "XDeath");
		HEAD G 8 A_NoBlocking;
		TNT1 A 0 A_CustomMissile("CeilingBloodCheckerBlue", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 A 0 A_CustomMissile("XDeath1bBlue", 30,  0, random(0, 360), 2, random(10, 45));
		HEAD H 6 A_Scream;
		HEAD I 6;
		HEAD J 6;
		HEAD K 6;
		HEAD LLL 6 A_SetScale(scalex+0.03, scaley-0.1);
		TNT1 A 0 A_CustomMissile("XDeath1Blue", 20,  0, random(0, 360), 2, random(10, 45));
		HEAD L -1 A_SetFloorClip;
		Stop;

	Death:
		CCD2 A  0;
		TNT1 AA 0 A_CustomMissile("XDeath1bblue", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath2blue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath3blue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath2bblue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath3bblue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 AAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleBigblue", 50,  0, random(0, 360), 2, random(10, 45));
		CCD2 A  0 A_Scream;
		CCD2 A  0;
		CCD2 A  0 A_NoBlocking;
		CCD2 ABCDEFG 4;
		TNT1 A 0 A_CustomMissile("XDeath1Blue", 20,  0, random(0, 360), 2, random(10, 45));
		CCD2 H -1 A_SetFloorClip;
		Stop;

	Death.Plasma:
		CCD2 A  0;
		TNT1 AA 0 A_CustomMissile("XDeath1bblue", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath2blue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath3blue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath2bblue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath3bblue", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 AAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleBigblue", 50,  0, random(0, 360), 2, random(10, 45));
		CCD3 A  0 A_Scream;
		CCD3 A  0;
		CCD3 A  0 A_NoBlocking;
		CCD3 ABCDEFG 4;
		TNT1 A 0 A_SpawnItem("SmokePillar");
		TNT1 A 0 A_CustomMissile("XDeath1Blue", 20,  0, random(0, 360), 2, random(10, 45));
		CCD3 H -1 A_SetFloorClip;
		Stop;

	Raise:
		HEAD L 8 A_UnSetFloorClip;
		HEAD KJIHG 8;
		Goto See;
	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushedBlue", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2Blue", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3Blue", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH E 1;
		CRSH E -1;
		Stop;

	}
}
