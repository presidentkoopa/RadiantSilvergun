// ============================================================================
// rs_mg_arachnotron.zs -- RS_MGArachnotron.  STAGING; see rs_mg_base.zs.
//
// The suppression platform.  Stock A_BspiAttack held in a loop by
// A_SpidRefire, so it puts down a continuous plasma stream and only stops when
// it loses sight of you.  Its See state is the vanilla stomp cycle with
// A_BabyMetal, which is why every jump back into it targets See+1 -- entering
// at See would replay the 20-tic wind-up.
//
// ART: 2 custom sequences -> 2 coloured tiers.
//      XBSP (gib)  CRSH (crush)
//
// GibHealth 50 is set explicitly, so it takes a long way past dead to reach
// XDeath.  +BOSSDEATH and +MAP07BOSS2 are live: the last Arachnotron on Doom 2
// MAP07 raises floor tag 667.
// ============================================================================

class RS_MGArachnotron : RS_MG_Monsters
{
	Default
	{
		Health 500;
		GibHealth 50;
		Radius 64;
		Height 64;
		Mass 600;
		Speed 12;
		PainChance 128;
		Monster;
		+FLOORCLIP
		+BOSSDEATH     // crush/ice deaths still fire the boss special
		+MAP07BOSS2    // last Arachnotron on Doom2 MAP07 raises floor tag 667
		SeeSound "baby/sight";
		PainSound "baby/pain";
		DeathSound "baby/death";
		ActiveSound "baby/active";
		Obituary "$OB_BABY";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "spider"; }
	override string MonIdentity() { return "class:arachnotron species:arachnotron role:artillery trait:projectile faction:hell set:gore"; }

	override int MGTiers() { return 2; }   // XBSP CRSH

	// ------------------------------------------------------------------------
	// 500 HP base, TWO rungs only -- the same base as the hell knight but a
	// third of its ladder, purely because only two sequences were drawn.
	//
	// Radius 64 makes it the widest target in the roster, so like the Mancubus
	// it can hold HP honestly.  The reason it stays modest anyway (x1.5, x1.8)
	// is the attack: A_SpidRefire keeps it firing as long as it can see you, so
	// this is a sustained-damage monster like the chaingunner, not a
	// burst-damage one, and every extra second is continuous plasma rather than
	// one more discrete shot to dodge.
	//
	// Two rungs is also a reason to keep the step small.  With only GREEN and
	// CYAN available the ladder has nowhere to build to, so the second rung
	// should read as "the tough one", not as a boss.  900 is a hell knight's
	// worth of plasma platform, which is exactly the right top end.
	//
	// The neutral GibHealth 50 is left untouched.  It is a fixed threshold, not
	// a fraction, so a coloured Arachnotron gibs proportionally less easily --
	// which suits a bigger, meaner one and needs no separate lever.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 750;   // x1.5
			case HFMT_CYAN:    return 900;   // x1.8 -- ceiling; a fast one is already the hard version
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		BSPI AB 10 A_Look;
		Loop;
	See:
		BSPI A 20;
		BSPI A 3 A_BabyMetal;
		BSPI ABBCC 3 A_Chase;
		BSPI D 3 A_BabyMetal;
		BSPI DEEFF 3 A_Chase;
		Goto See+1;
	Missile:
		BSPI A 20 BRIGHT A_FaceTarget;
		BSPI G 4 BRIGHT A_BspiAttack;
		BSPI H 4 BRIGHT;
		BSPI H 1 BRIGHT A_SpidRefire;
		Goto Missile+1;
	Pain:
		BSPI I 3;
		BSPI I 3 A_Pain;
		Goto See+1;
	Death:
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		BSPI J 7 A_Scream;
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(30, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		BSPI K 7 A_NoBlocking;
		BSPI LMNO 7;
		BSPI P -1 A_BossDeath;
		Stop;

	XDeath:

		TNT1 AAA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(30, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeathSpiderLeg", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAAA 0 A_CustomMissile("XDeath1b", 50,  0, random(0, 360), 2, random(10, 45));
		XBSP A 7 A_Scream;
		XBSP B 7 A_NoBlocking;
		XBSP C 7;
		XBSP D -1 A_BossDeath;
		Stop;
	Raise:
		BSPI P 5;
		BSPI ONMLKJ 5;
		Goto See+1;

	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH F 1;
		CRSH F -1;
		Stop;

	}
}
