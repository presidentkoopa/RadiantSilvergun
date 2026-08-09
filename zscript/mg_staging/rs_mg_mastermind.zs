// ============================================================================
// rs_mg_mastermind.zs -- RS_MGMastermind.  STAGING; see rs_mg_base.zs.
//
// Boss bracket.  Unlike vanilla it does NOT use A_SPosAttack -- its Missile
// state fires the same projectile bullet the zombies use, one per cycle, held
// in a loop by A_SpidRefire.  So it is a fast-firing projectile turret rather
// than a true hitscan chaingun, and its rounds can be dodged at distance.
//
// Its death is a 30-plus-second set piece: staged A_SpawnItemEx explosions
// walking across its body, then a huge gib spray, then a 30-tic hold before
// A_BossDeath fires.
//
// ART: 1 custom sequence -> 1 coloured tier.
//      CRSH (crush).  Everything else is the vanilla SPID set.
//
// CONVERTED, not copied:
//   +MISSILEMORE  ->  MissileChanceMult 0.5
// Deprecated flag; the engine's own deprecation text points at the property.
// Behaviour identical, one less warning at load.
//
// FLAGS WORTH KNOWING ABOUT, all left exactly as the source has them:
//   * +FLOORCLIP appears TWICE (once in the property block's normal position
//     and once among the boss flags).  Harmless -- setting a flag twice is
//     idempotent -- and deleting the duplicate is a cosmetic edit to a monster,
//     which is not what this pass is for.
//   * +NOTARGET means other monsters will not target it, so it sits outside
//     infighting entirely.  Counter-intuitive on a boss and easy to mistake for
//     a typo of +NOTARGETSWITCH; it is not being changed on a guess.
//   * +E3M8BOSS / +E4M8BOSS fire the level's boss special on the last one.
// ============================================================================

class RS_MGMastermind : RS_MG_Monsters
{
	Default
	{
		Health 3000;
		Radius 90;
		Height 100;
		Mass 1000;
		Speed 12;
		PainChance 40;
		Monster;
		+FLOORCLIP
		+BOSS
		MissileChanceMult 0.5;   // was +MISSILEMORE
		+FLOORCLIP
		+NORADIUSDMG
		+DONTMORPH
		+NOTARGET
		+BOSSDEATH
		+E3M8BOSS      // last Spider Mastermind on E3M8/E4M8 fires the boss special
		+E4M8BOSS
		SeeSound "spider/sight";
		PainSound "spider/pain";
		DeathSound "spider/death";
		ActiveSound "spider/active";
		Obituary "$OB_SPIDER";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "spider"; }
	override string MonIdentity() { return "class:spidermastermind species:spider role:boss trait:hitscan faction:hell set:gore"; }

	override int MGTiers() { return 1; }   // CRSH

	// ------------------------------------------------------------------------
	// 3000 HP base, ONE rung, x1.3.
	//
	// Two independent reasons converge on the same small number, which is why
	// it is the right one.
	//
	// The art reason: one custom sequence, so one tier.  There is nothing on
	// screen to tell a second rung apart from the first.
	//
	// The scale reason: at 3000 HP the multiplier has stopped being a difficulty
	// dial and become an ammunition audit.  x1.3 is +900 HP -- already more
	// than a whole Baron of extra shooting -- and the fight was long before
	// that.  The old shared curve applied x1.6 here, which is +1800, and the
	// black and white rungs of that same curve would have produced 36,000 and
	// 60,000 HP.  Numbers like that do not make a boss harder, they make it a
	// wall you run out of rockets against.
	//
	// A coloured Mastermind should be MEANER, not longer.  The buff curve
	// already hands it more speed, more damage and less pain -- that is where
	// its difficulty comes from, and the HP step just has to be big enough for
	// the player to notice the fight is not the usual one.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 3900;  // x1.30 -- the whole ladder; see above
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		SPID AB 10 A_Look;
		Loop;
	See:
		SPID A 3 A_Metal;
		SPID ABB 3 A_Chase;
		SPID C 3 A_Metal;
		SPID CDD 3 A_Chase;
		SPID E 3 A_Metal;
		SPID EFF 3 A_Chase;
		Loop;
	Missile:
		SPID A 20 BRIGHT A_FaceTarget;
		TNT1 A 0 A_StartSound("ENEMYGUN", 1);
		TNT1 A 0 A_StartSound("enemysg", 4);
		TNT1 A 0 A_CustomMissile("MG_EnemyBullet", 45, 0, random(-8,8), 1, random(-1,1));
		SPID H 2 BRIGHT;
		SPID G 2;
		SPID H 0 BRIGHT A_SpidRefire;
		Goto Missile+1;
	Pain:
		SPID I 3;
		SPID I 3 A_Pain;
		Goto See;
	Death:
		SPID I 1 A_Scream;
		SPID I 1 A_NoBlocking;
		SPID IIIII 13 A_SpawnItemEx("Explosion", random(-64,64), random(-64,64), random(32,120));
		SPID JK 6;
		TNT1 A 0 A_SpawnItemEx("Explosion", random(-64,64), random(-64,64), random(32,120));
		SPID LMN 6;
		TNT1 AAAAA 0 A_SpawnItemEx("Explosion", random(-64,64), random(-64,64), random(32,120));
		TNT1 AAAAAAAAAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleHuge", 50,  0, random(0, 360), 2, random(30, 65));
		TNT1 AAA 0 A_CustomMissile("XDeath1b", 80,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAAA 0 A_CustomMissile("XDeath2", 80,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 80,  0, random(0, 360), 2, random(10, 45));
		SPID OPQR 10;
		TNT1 A 0 A_CustomMissile("XDeath1", 10,  0, random(0, 360), 2, random(10, 45));
		SPID S 30;
		SPID S -1 A_BossDeath;
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
