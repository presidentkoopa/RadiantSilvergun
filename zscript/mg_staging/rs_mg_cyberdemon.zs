// ============================================================================
// rs_mg_cyberdemon.zs -- RS_MGCyberdemon.  STAGING; see rs_mg_base.zs.
//
// Boss bracket, and the top of the roster at 4000 HP.  Three rockets per
// Missile cycle, each fired through A_CustomMissile at a fixed offset rather
// than through A_CyberAttack, so the rocket class is this set's own.
//
// Its death walks staged explosions across the body, sheds four named
// mechanical gib chunks, then holds 30 tics before A_BossDeath.
//
// ART: 1 custom sequence -> 1 coloured tier.
//      CRSH (crush).  Everything else is the vanilla CYBR set.
//
// CONVERTED, not copied:
//   +MISSILEMORE  ->  MissileChanceMult 0.5
// Deprecated flag; the property is what the engine's own deprecation message
// tells you to use.  Same behaviour, one less warning.
//
// +FLOORCLIP is set twice here as well, exactly as on the Mastermind.  Left
// alone for the same reason -- idempotent, and not what this pass is for.
// +E2M8BOSS / +E4M6BOSS fire the level's boss special on the last one.
// ============================================================================

class RS_MGCyberdemon : RS_MG_Monsters
{
	Default
	{
		Health 4000;
		Radius 40;
		Height 110;
		Mass 1000;
		Speed 16;
		PainChance 20;
		Monster;
		+FLOORCLIP
		+BOSS
		MissileChanceMult 0.5;   // was +MISSILEMORE
		+FLOORCLIP
		+NORADIUSDMG
		+DONTMORPH
		+BOSSDEATH
		+E2M8BOSS      // last Cyberdemon on E2M8/E4M6 fires the boss special
		+E4M6BOSS
		SeeSound "cyber/sight";
		PainSound "cyber/pain";
		DeathSound "cyber/death";
		ActiveSound "cyber/active";
		Obituary "$OB_CYBORG";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "cyber"; }
	override string MonIdentity() { return "class:cyberdemon species:cyberdemon role:boss trait:rocket faction:hell set:gore"; }

	override int MGTiers() { return 1; }   // CRSH

	// ------------------------------------------------------------------------
	// 4000 HP base, ONE rung, x1.25 -- THE SMALLEST MULTIPLIER IN THE ENTIRE
	// SET, and the exact monster that proves why the shared curve had to go.
	//
	// Put the two ends of the roster side by side under the old code:
	//
	//     green zombieman    20 x 1.6 =    32   (+12 HP.  Invisible.)
	//     green cyberdemon 4000 x 1.6 =  6400   (+2400 HP.  A different fight.)
	//
	// One multiplier, two completely unrelated outcomes, and neither of them
	// the one anybody wanted.  The zombieman's tier could not be felt at all;
	// the cyberdemon's could be felt for several minutes.  And the top of that
	// same curve -- white, x20 -- would have put this monster at EIGHTY
	// THOUSAND HP.  That is not a boss, it is a load-bearing wall.
	//
	// So this gets the shallowest step in the roster: +1000 HP, one rung, and
	// no more.  At this scale +1000 is already the equivalent of a whole extra
	// Hell Knight's worth of shooting, and the fight was long before it.
	//
	// A coloured Cyberdemon is meant to be FASTER AND MEANER, which the buff
	// curve gives it for free -- more speed, more damage, far less pain.  The
	// HP step exists only so the player registers that this is not the usual
	// one.  Anything more just makes them leave the room for more rockets.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 5000;  // x1.25 -- shallowest step in the set
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		CYBR AB 10 A_Look;
		Loop;
	See:
		CYBR A 3 A_Hoof;
		CYBR ABBCC 3 A_Chase;
		CYBR D 3 A_Metal;
		CYBR D 3 A_Chase;
		Loop;
	Missile:
		CYBR E 6 A_FaceTarget;
		CYBR F 12 A_CustomMissile("MG_Rocket", 58, -10, 0);
		CYBR E 12 A_FaceTarget;
		CYBR F 12 A_CustomMissile("MG_Rocket", 58, -10, 0);
		CYBR E 12 A_FaceTarget;
		CYBR F 12 A_CustomMissile("MG_Rocket", 58, -10, 0);
		Goto See;
	Pain:
		CYBR G 10 A_Pain;
		Goto See;
	Death:
		CYBR H 0;
		CYBR H 0 A_Scream;
		CYBR H 10;
		CYBR I 6;
		CYBR JKL 6;
		TNT1 AAAAA 0 A_SpawnItemEx("Explosion", random(-64,64), random(-64,64), random(32,120));
		TNT1 AAAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleHuge", 40,  0, random(0, 360), 2, random(30, 65));
		TNT1 AAAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleHuge", 80,  0, random(0, 360), 2, random(30, 65));
		TNT1 A 0 A_CustomMissile("CyberGib1", random(80, 90),  0, random(0, 360), 2, random(30, 65));
		TNT1 A 0 A_CustomMissile("CyberGib2", random(60, 90),  0, random(0, 360), 2, random(30, 65));
		TNT1 A 0 A_CustomMissile("CyberGib3", random(60, 90),  0, random(0, 360), 2, random(30, 65));
		TNT1 A 0 A_CustomMissile("CyberGib4", random(50, 90),  0, random(0, 360), 2, random(30, 65));
		TNT1 AAA 0 A_CustomMissile("XDeath1b", 80,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAAA 0 A_CustomMissile("XDeath2", 80,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 80,  0, random(0, 360), 2, random(10, 45));
		CYBR M 6 A_NoBlocking;
		CYBR NO 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 10,  0, random(0, 360), 2, random(10, 45));
		CYBR P 30;
		CYBR P -1 A_BossDeath;
		Stop;
	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH F 1;
		CRSH F -1;
		Stop;

	}
}
