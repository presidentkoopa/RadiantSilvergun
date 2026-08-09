// ============================================================================
// rs_mg_revenant.zs -- RS_MGRevenant.  STAGING; see rs_mg_base.zs.
//
// The homing skirmisher.  Stock A_SkelMissile at range and the two-part
// whoosh/fist melee up close.  Its threat is the tracking missile, which
// follows you around corners and has to be dodged or blocked rather than
// out-ranged.
//
// ART: 4 custom sequences -> 4 coloured tiers.
//      REVH (torn-open death)  REVP (plasma)  REDX (gib)  CRSH (crush)
//
// The normal death is a coin flip -- A_Jump(128, "Death2") -- between the
// vanilla SKEL collapse and the REVH sequence, so half of all revenant deaths
// use custom art and half do not.  That is the source's shape, kept.
//
// NOTE, verbatim: Death2 and Death.Plasma both write `TNT1 H 0 A_CustomMissile
// (...)` -- frame H on the TNT1 (invisible) sprite.  TNT1 only defines frame A.
// It is a 0-tic state so nothing renders either way and the action still fires;
// harmless, and left as written rather than silently "corrected".
// ============================================================================

class RS_MGRevenant : RS_MG_Monsters
{
	Default
	{
		Health 300;
		Radius 20;
		Height 56;
		Mass 500;
		Speed 10;
		PainChance 100;
		Monster;
		+FLOORCLIP
		SeeSound "skeleton/sight";
		AttackSound "skeleton/attack";
		PainSound "skeleton/pain";
		DeathSound "skeleton/death";
		ActiveSound "skeleton/active";
		MeleeSound "skeleton/melee";
		Obituary "$OB_UNDEAD";
		HitObituary "$OB_UNDEADHIT";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "rev"; }
	override string MonIdentity() { return "class:revenant species:revenant role:skirmisher trait:projectile trait:homing faction:hell set:gore"; }

	override int MGTiers() { return 4; }   // REVH REVP REDX CRSH

	// ------------------------------------------------------------------------
	// 300 HP base, and a deliberately SHALLOW ladder (x1.5 to x2.8) for a
	// monster this dangerous.
	//
	// The reason is that the revenant's threat lives entirely in its missile,
	// not in its body.  A homing projectile has to be answered every time it is
	// fired -- you cannot ignore one -- so time-on-the-field is worth more here
	// than on any other mid-tier monster.  Doubling its HP does not make it
	// twice as tough, it roughly doubles the number of missiles you have to
	// deal with, and that compounds badly the moment there are two of them.
	//
	// Also worth keeping in mind: the buff curve raises damage alongside HP, so
	// a coloured revenant's missiles hit harder as well as coming more often.
	// The HP table is the one lever that can keep the total from running away,
	// so it stays modest.  The ceiling (840) is under a Baron's neutral HP.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 450;   // x1.5
			case HFMT_CYAN:    return 540;   // x1.8  -- fast, and it already leads you
			case HFMT_BLUE:    return 660;   // x2.2
			case HFMT_FIREBLU: return 840;   // x2.8  -- ceiling, still sub-Baron
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		SKEL AB 10 A_Look;
		Loop;
	See:
		SKEL AABBCCDDEEFF 2 A_Chase;
		Loop;
	Melee:
		SKEL G 1 A_FaceTarget;
		SKEL G 6 A_SkelWhoosh;
		SKEL H 6 A_FaceTarget;
		SKEL I 6 A_SkelFist;
		Goto See;
	Missile:
		SKEL J 1 BRIGHT A_FaceTarget;
		SKEL J 9 BRIGHT A_FaceTarget;
		SKEL K 10 A_SkelMissile;
		SKEL KK 10 A_FaceTarget;
		Goto See;
	Pain:
		SKEL L 5;
		SKEL L 5 A_Pain;
		Goto See;
	Death:
		TNT1 A 0;
		TNT1 A 0 A_Jump(128, "Death2");
		SKEL LM 5;
		SKEL N 5 A_Scream;
		SKEL O 5 A_NoBlocking;
		TNT1 A 0 A_CustomMissile("XDeath1", 30,  0, random(0, 360), 2, random(10, 45));
		SKEL P 5;
		SKEL Q -1;
		Stop;
	Death2:
		REVH E 4;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath2b", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3b", 40,  0, random(0, 360), 2, random(10, 45));
		REVH F 5 A_Scream;
		REVH G 5 A_NoBlocking;
		TNT1 H 0 A_CustomMissile("XDeath1", 30,  0, random(0, 360), 2, random(10, 45));
		REVH IJK 5;
		REVH L -1;
		Stop;

	Death.Plasma:
		REVP E 4;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath2b", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3b", 40,  0, random(0, 360), 2, random(10, 45));
		REVP F 5 A_Scream;
		REVP G 5 A_NoBlocking;
		TNT1 A 0 A_SpawnItem("SmokePillar");
		TNT1 H 0 A_CustomMissile("XDeath1", 30,  0, random(0, 360), 2, random(10, 45));
		REVP IJK 5;
		REVP L -1;
		Stop;

	XDeath:
		REVH AB 2;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("RevenantGib1", 40,  0, random(0, 360), 2, random(30, 45));
		TNT1 A 0 A_CustomMissile("RevenantGib2", 40,  0, random(0, 360), 2, random(30, 45));
		TNT1 A 0 A_CustomMissile("RevenantGib3", 40,  0, random(0, 360), 2, random(30, 45));
		REDX C 3 A_Scream;
		REDX D 3 A_NoBlocking;
		TNT1 A 0 A_CustomMissile("XDeath1", 30,  0, random(0, 360), 2, random(10, 45));
		REDX EFGHIJ 3;
		REDX K -1;
		Stop;


	Raise:
		SKEL Q 5;
		SKEL PONML 5;
		Goto See;

	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH A 1;
		CRSH A -1;
		Stop;

	}
}
