// ============================================================================
// rs_mg_chaingunner.zs -- RS_MGChaingunner.  STAGING; see rs_mg_base.zs.
//
// The sustained-fire grunt.  One round per cycle with A_CPosRefire holding it
// in the Missile loop, so it is a continuous stream rather than a burst -- the
// only zombie in the set whose threat is uptime instead of alpha.
//
// ART: 6 custom sequences -> 6 coloured tiers.
//      CPHS (head)  CPSC  MPSD  ZXZ2 (guts/heavy)  DPS1 (plasma)  CRSH (crush)
//
// TWO SOURCE ODDITIES, PRESERVED VERBATIM.  Both are real and neither is fixed
// here, because a plausible-looking repair to a monster is how this repo has
// been damaged before:
//
//   1. Death4 and Death5 exist, are byte-identical to each other, and are
//      UNREACHABLE.  The Death jump only names Death1, Death2, Death3.  Two
//      whole gib branches are dead code.
//   2. That jump is A_Jump(255, ...) -- 255/256, so 1 time in 256 it falls
//      through into Death1 anyway.  Harmless (Death1 is one of the three
//      targets) but it means the "no jump" path was never designed.
//
// Also note the Death entry animates CPHS A for one tic before rolling, so the
// head-loss sprite flashes on every death regardless of which branch wins.
// ============================================================================

class RS_MGChaingunner : RS_MG_Monsters
{
	Default
	{
		Health 70;
		Radius 20;
		Height 56;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "chainguy/sight";
		AttackSound "chainguy/attack";
		PainSound "chainguy/pain";
		DeathSound "chainguy/death";
		ActiveSound "chainguy/active";
		Obituary "$OB_CHAINGUY";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "cg"; }
	override string MonIdentity() { return "class:chaingunner species:zombie role:skirmisher trait:hitscan faction:hell set:gore"; }

	override int MGTiers() { return 6; }   // CPHS CPSC MPSD ZXZ2 DPS1 CRSH

	// ------------------------------------------------------------------------
	// 70 HP base, and DELIBERATELY the shallowest ratio of the three zombies
	// (x1.9 to x6.3, against the zombieman's x2 to x7 off a much smaller base).
	//
	// This looks backwards -- the chaingunner is the strongest zombie, so why
	// does it scale least?  Because its damage is continuous.  Every tic it
	// stays alive is damage taken, with no window to break line of sight in
	// between; extra HP on this monster converts directly into damage dealt in
	// a way it does not for the burst-fire shotgunner.  Give it the
	// shotgunner's x11 and a coloured chaingunner stops being a fight and
	// starts being an attrition puzzle.
	//
	// The ceiling (440) is roughly a Cacodemon.  That is as far as a hitscan
	// stream should go while the player still has a hitscan answer to it.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 130;   // x1.9
			case HFMT_CYAN:    return 160;   // x2.3  -- fast; already the scariest rung
			case HFMT_BLUE:    return 200;   // x2.9
			case HFMT_FIREBLU: return 260;   // x3.7
			case HFMT_BROWN:   return 350;   // x5.0  -- slow enough to be flankable
			case HFMT_YELLOW:  return 440;   // x6.3  -- ceiling, Cacodemon-class
			default:           return 0;
		}
	}

	States
	{
	Spawn:
		CPOS AB 10 A_Look;
		Loop;
	See:
		CPOS AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		CPOS E 10 A_FaceTarget;
		TNT1 A 0 A_StartSound("ENEMYGUN", 1);
		TNT1 A 0 A_StartSound("MGUN2", 4);
		TNT1 A 0 A_CustomMissile("MG_EnemyBullet", 38, 0, random(-8,8), 1, random(-1,1));
		CPOS F 1 BRIGHT;
		CPOS E 2;
		CPOS E 1 A_CPosRefire;
		Goto Missile+1;
	Pain:
		CPOS G 3;
		CPOS G 3 A_Pain;
		Goto See;

	Death:
		CPHS A 1;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		POSS H 0 A_Jump(255, "Death1", "Death2", "Death3");
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 40,  0, random(0, 360), 2, random(0, 90));
	Death1:
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 20,  0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeathBlackArm", 50,  0, random(0, 360), 2, random(40, 60));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("GibHeadPiece", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibTeeth", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibEyeball", 55,  0, random(0, 360), 2, random(45, 50));
		CPSC A 6 A_Scream;
		CPSC B 6 A_NoBlocking;
		CPSC CDEFG 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		CPSC H -1;
		Stop;
	Death2:
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 20,  0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeathBlackArm", 50,  0, random(0, 360), 2, random(40, 60));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("GibHeadPiece", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibTeeth", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibEyeball", 55,  0, random(0, 360), 2, random(45, 50));
		MPSD A 6 A_Scream;
		MPSD B 6 A_NoBlocking;
		MPSD C 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		MPSD D -1;
		Stop;
	Death3:  //Head
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("GibHeadPiece", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibTeeth", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibEyeball", 55,  0, random(0, 360), 2, random(45, 50));
		CPHS B 6 A_Scream;
		CPHS C 6 A_NoBlocking;
		CPHS DE 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		CPHS F -1;
		Stop;
	Death4:  //Guts -- UNREACHABLE in the source; see file header.
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30,  0, random(0, 360), 2, random(10, 45));
		ZXZ2 A 6 A_Scream;
		ZXZ2 B 6 A_NoBlocking;
		ZXZ2 BCD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		ZXZ2 E -1;
		Stop;
	Death5:  //Heavy1 -- UNREACHABLE, and identical to Death4; see file header.
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30,  0, random(0, 360), 2, random(10, 45));
		ZXZ2 A 6 A_Scream;
		ZXZ2 B 6 A_NoBlocking;
		ZXZ2 BCD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		ZXZ2 E -1;
		Stop;
	XDeath:
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(30, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeathBlackArm", 50,  0, random(0, 360), 2, random(40, 60));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		POSS O 5 A_NoBlocking;
		CPOS P 5 A_XScream;
		CPOS QRST 5;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		CPOS T -1;
		Stop;
	Death.Plasma:
		DPS1 A 0 A_Stop;
		DPS1 A 0 A_XScream;
		DPS1 A 0 A_NoBlocking;
		TNT1 A 0 A_SpawnItem("SmokePillar");
		TNT1 A 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 40,  0, random(0, 360), 2, random(10, 45));
		DPS1 ABCDEFG 4;
		DPS1 H -1;
		Stop;
	Raise:
		CPOS N 5;
		CPOS MLKJIH 5;
		Goto See;
	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH A 1;
		CRSH A -1;
		Stop;

	Death.Saw:
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(30, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 40,  0, random(0, 360), 2, random(10, 45));
		POSS N 5 A_XScream;
		POSS O 5 A_NoBlocking;
		POSS PQRST 5;
		POSS U -1;
		Stop;

	}
}
