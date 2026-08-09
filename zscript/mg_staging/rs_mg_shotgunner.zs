// ============================================================================
// rs_mg_shotgunner.zs -- RS_MGShotgunner.  STAGING; see rs_mg_base.zs.
//
// The shotgun grunt.  Fires a three-round projectile spread, then racks the
// pump on its own sprite sequence (SPSR) with its own sound -- a tell you can
// hear and act on, which is what separates it from the rifle grunt.
//
// ART: 8 custom sequences -> 8 coloured tiers.  The longest ladder in the set.
//      SPSR (pump)  SPO3 (leg)  SPO5 (arm)  SPDH (head)
//      ZXZ7 (guts)  ZXZ6 (heavy)  DPS1 (plasma)  CRSH (crush)
//
// NOTE, verbatim and NOT tidied: XDeath and Death.Saw both animate on the
// RIFLE grunt's POSS sequence, not the shotgunner's SPOS.  On a normal death
// this monster wears SPOS; gib it and it changes uniform mid-animation.  It is
// consistent across both channels, so it may be deliberate reuse of a gib set
// that only exists for POSS.  Not changed -- swapping a sprite prefix on a
// guess is exactly how imports get quietly wrecked.  Owner's call.
// ============================================================================

class RS_MGShotgunner : RS_MG_Monsters
{
	Default
	{
		Health 30;
		Radius 20;
		Height 56;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "shotguy/sight";
		AttackSound "shotguy/attack";
		PainSound "shotguy/pain";
		DeathSound "shotguy/death";
		ActiveSound "shotguy/active";
		Obituary "$OB_SHOTGUY";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "sg"; }
	override string MonIdentity() { return "class:shotgunner species:zombie role:fodder trait:hitscan faction:hell set:gore"; }

	override int MGTiers() { return 8; }   // SPSR SPO3 SPO5 SPDH ZXZ7 ZXZ6 DPS1 CRSH

	// ------------------------------------------------------------------------
	// 30 HP base, and the most art in the roster -- so it gets the longest
	// ladder and the widest total spread, x2 through x11.
	//
	// It can carry that spread because its threat is burst damage at close
	// range, not sustained pressure: a shotgunner that lives longer is a
	// shotgunner that gets more shots off, and each of those shots is a
	// decision the player can answer by breaking line of sight.  Compare the
	// chaingunner below, whose damage is continuous and whose HP therefore has
	// to climb more gently.
	//
	// The ceiling (330, x11) is deliberately Revenant-class.  That is the point
	// of an eight-rung ladder: the top rung has to be a monster you rethink the
	// room for, or the eight sprite sequences were drawn for nothing.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 60;    // x2.0  -- survives one shotgun blast
			case HFMT_CYAN:    return 75;    // x2.5  -- fast flanker
			case HFMT_BLUE:    return 90;    // x3.0
			case HFMT_FIREBLU: return 120;   // x4.0
			case HFMT_BROWN:   return 165;   // x5.5  -- slow, tanky
			case HFMT_YELLOW:  return 210;   // x7.0
			case HFMT_PURPLE:  return 270;   // x9.0
			case HFMT_GRAY:    return 330;   // x11.0 -- ceiling, Revenant-class
			default:           return 0;
		}
	}

	States
	{
	Spawn:
		SPOS AB 10 A_Look;
		Loop;
	See:
		SPOS AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		SPOS E 10 A_FaceTarget;
		TNT1 A 0 A_StartSound("ENEMYGUN", 1);
		TNT1 A 0 A_StartSound("enemysg", 4);
		TNT1 AAA 0 A_CustomMissile("MG_EnemyBullet", 38, 0, random(-6,6), 1, random(-1,1));
		SPOS F 10 BRIGHT;
		SPOS E 10;
		TNT1 A 0 A_StartSound("STGPUMP", 4);
		SPSR ABA 4;
		Goto See;
	Pain:
		SPOS G 3;
		SPOS G 3 A_Pain;
		Goto See;

	Death:
		SPOS H 0;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		SPOS H 0 A_Jump(192, "Death1", "Death2", "Death3", "Death4", "Death5");
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 40,  0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		SPOS H 5;
		SPOS I 5 A_Scream;
		SPOS J 5 A_NoBlocking;
		SPOS K 5;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SPOS L -1;
		Stop;
	Death1:  //Leg
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 20,  0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XShotgunnerLeg", 10,  0, random(0, 360), 2, random(40, 50));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		SPO3 A 6 A_Scream;
		SPO3 B 6 A_NoBlocking;
		SPO3 CGH 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SPO3 F -1;
		Stop;
	Death2:  //Arm
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 20,  0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeathArm", 50,  0, random(0, 360), 2, random(40, 60));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		SPO5 A 6 A_Scream;
		SPO5 B 6 A_NoBlocking;
		SPO5 CD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SPO5 E -1;
		Stop;
	Death3:  //Head
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AAA 0 A_CustomMissile("GibHeadPiece", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibTeeth", 55,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibEyeball", 55,  0, random(0, 360), 2, random(45, 50));
		SPDH B 6 A_Scream;
		SPDH C 6 A_NoBlocking;
		SPDH DE 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SPDH E -1;
		Stop;
	Death4:  //Guts
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30,  0, random(0, 360), 2, random(10, 45));
		ZXZ7 A 6 A_Scream;
		ZXZ7 B 6 A_NoBlocking;
		ZXZ7 BCD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		ZXZ7 E -1;
		Stop;
	Death5:  //Heavy1
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30,  0, random(0, 360), 2, random(10, 45));
		ZXZ6 A 6 A_Scream;
		ZXZ6 B 6 A_NoBlocking;
		ZXZ6 BCD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		ZXZ6 E -1;
		Stop;
	XDeath:
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(30, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeathArm", 50,  0, random(0, 360), 2, random(40, 60));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		POSS N 5 A_XScream;
		POSS O 5 A_NoBlocking;
		POSS PQRST 5;
		POSS U -1;
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
		SPOS L 5;
		SPOS KJIH 5;
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
