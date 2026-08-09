// ============================================================================
// rs_mg_demon.zs -- RS_MGDemon.  STAGING; see rs_mg_base.zs.
//
// The melee bruiser.  Fast chase (the See and Melee states carry the Fast
// keyword), stock A_SargAttack, no ranged option at all.  Three randomised
// dismemberment deaths plus a plasma channel and a crush channel.
//
// ART: 5 custom sequences -> 5 coloured tiers.
//      SARH  SARC  SAAR  SARB (plasma)  CRSH (crush)
//
// STRUCTURAL NOTE, verbatim: XDeath and Death2 SHARE A LABEL -- XDeath falls
// straight into Death2's body.  So gibbing this monster and rolling Death2 off
// the normal death give the same animation.  That is a deliberate-looking
// economy, not an accident, and it is why the roll is A_Jump(220, ...) over
// three branches rather than five.
// ============================================================================

class RS_MGDemon : RS_MG_Monsters
{
	Default
	{
		Health 150;
		PainChance 180;
		Speed 10;
		Radius 30;
		Height 56;
		Mass 400;
		Monster;
		+FLOORCLIP
		SeeSound "demon/sight";
		AttackSound "demon/melee";
		PainSound "demon/pain";
		DeathSound "demon/death";
		ActiveSound "demon/active";
		Obituary "$OB_DEMONHIT";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "demon"; }
	override string MonIdentity() { return "class:demon species:demon role:bruiser trait:melee faction:hell set:gore"; }

	override int MGTiers() { return 5; }   // SARH SARC SAAR SARB CRSH

	// ------------------------------------------------------------------------
	// 150 HP base, melee-only, and that last fact is what shapes the ladder.
	//
	// A melee monster cannot threaten you at range, so its HP does not convert
	// into damage the way a shooter's does -- you can back away from it all day.
	// What extra HP on a pinky buys is TIME IN THE ROOM: it stays as a moving
	// obstacle, blocking corridors and soaking shots you wanted to spend on the
	// shooters behind it.  That is genuinely valuable, so the ladder is real
	// (x1.6 to x4.0), but it stops well short of the "unkillable wall" that a
	// large multiplier would produce, because a pinky you cannot kill is not a
	// threat, it is a locked door.
	//
	// The ceiling (600) is Mancubus-class HP on a monster with no ranged
	// attack.  That is the correct top end for a body-blocker.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 240;   // x1.6
			case HFMT_CYAN:    return 290;   // x1.9  -- fast; a pinky that catches you
			case HFMT_BLUE:    return 350;   // x2.3
			case HFMT_FIREBLU: return 450;   // x3.0
			case HFMT_BROWN:   return 600;   // x4.0  -- ceiling, the corridor plug
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		SARG AB 10 A_Look;
		Loop;
	See:
		SARG AABBCCDD 2 Fast A_Chase;
		Loop;
	Melee:
		SARG EF 8 Fast A_FaceTarget;
		SARG G 8 Fast A_SargAttack;
		Goto See;
	Pain:
		SARG H 2 Fast;
		SARG H 2 Fast A_Pain;
		Goto See;
	Death:
		SARG I 1;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SARG I 0 A_Jump(220, "Death1", "Death2", "Death3");
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 40,  0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SARG I 8;
		SARG J 8 A_Scream;
		SARG K 4;
		SARG L 4 A_NoBlocking;
		SARG M 4;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SARG N -1;
		Stop;

	Death1:
		TNT1 A 0;
		TNT1 A 0 A_CustomMissile("XDeath1b", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath2", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3", 40,  0, random(0, 360), 2, random(10, 45));
		SARH A 6 A_Scream;
		SARH B 6 A_NoBlocking;
		SARH C 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SARH D -1;
		Stop;
	XDeath:
	Death2:
		TNT1 A 0;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeathDemonArm", 50,  0, random(0, 360), 2, random(10, 45));
		SARC A 6 A_Scream;
		SARC B 6 A_NoBlocking;
		SARC C 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SARC D -1;
		Stop;

	Death3:
		TNT1 A 0;
		TNT1 A 0 A_CustomMissile("XDeath1b", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeathDemonArm", 50,  0, random(0, 360), 2, random(10, 45));
		SAAR A 6 A_Scream;
		SAAR B 6 A_NoBlocking;
		SAAR CDE 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		SAAR F -1;
		Stop;

	Death.Plasma:
		TNT1 A 0;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 40,  0, random(0, 360), 2, random(10, 45));
		SARB A 6 A_Scream;
		TNT1 A 0 A_SpawnItem("SmokePillar");
		SARB B 6 A_NoBlocking;
		SARB C 6;
		SARB D -1;
		Stop;

	Raise:
		SARG N 5;
		SARG MLKJI 5;
		Goto See;

	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH B 1;
		CRSH B -1;
		Stop;

	}
}
