// ============================================================================
// rs_mg_hellknight.zs -- RS_MGHellKnight.  STAGING; see rs_mg_base.zs.
//
// The Baron's lighter twin.  Same states, same sprite sets, same green gore --
// half the HP and no boss flags, because it is a rank-and-file heavy rather
// than an end-of-level fixture.
//
// ART: 3 custom sequences -> 3 coloured tiers.
//      XBAR (gib)  BBAR (plasma)  CRSH (crush)
//
// It is a SEPARATE CLASS, not a subclass of the Baron, exactly as the source
// has it, and it keeps its own copy of the state machine.  Left that way on
// purpose -- see the note in rs_mg_spectre.zs, which is the same situation.
//
// NOTE, verbatim and NOT repaired: all four A_BossDeath calls are still here,
// on the final frame of each death branch, copied across from the Baron -- but
// this class has NO +BOSSDEATH flag, so the call finds no boss-death behaviour
// to trigger and does nothing.  Inert, not harmful.  Whether the flag was meant
// to be here or the calls were meant to be dropped is the owner's call; both
// repairs change what happens at the end of a map.
//
// COSMETIC NORMALISATION: `A_JumP` -> `A_Jump`, as in rs_mg_baron.zs.  Sprite
// frames including the lowercase trailing `h` are untouched.
// ============================================================================

class RS_MGHellKnight : RS_MG_Monsters
{
	Default
	{
		Health 500;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 50;
		Monster;
		+FLOORCLIP
		SeeSound "knight/sight";
		PainSound "knight/pain";
		DeathSound "knight/death";
		ActiveSound "knight/active";
		Obituary "$OB_KNIGHT";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "hk"; }
	override string MonIdentity() { return "class:hellknight species:hellknight role:bruiser trait:projectile faction:hell set:gore"; }

	override int MGTiers() { return 3; }   // XBAR BBAR CRSH

	// ------------------------------------------------------------------------
	// 500 HP base -- exactly half the Baron, and the ladder holds that ratio
	// rung for rung (750/1400, 900/1650, 1100/1950).
	//
	// Keeping the halving intact is the point.  These two monsters look nearly
	// identical on screen and the player tells them apart mostly by how long
	// they take to kill; if the coloured versions drifted apart, a green hell
	// knight and a green Baron would stop having a legible relationship and
	// the player's read on "which one is that" would break exactly where it
	// matters most.
	//
	// So the multipliers are the Baron's, applied to half the base: x1.5,
	// x1.8, x2.2.  Slightly steeper than the Baron's because the smaller
	// absolute numbers can take it -- 1100 is a long fight, not an unfinishable
	// one -- but the shape is the same shape.  If the Baron's table is ever
	// retuned, retune this one with it.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 750;   // x1.5  (Baron 1400)
			case HFMT_CYAN:    return 900;   // x1.8  (Baron 1650)
			case HFMT_BLUE:    return 1100;  // x2.2  (Baron 1950) ceiling
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		BOSS AB 10 A_Look;
		Loop;
	See:
		BOSS AABBCCDD 3 A_Chase;
		Loop;
	Melee:
	Missile:
		BOSS EF 8 A_FaceTarget;
		BOSS G 8 A_BruisAttack;
		Goto See;
	Pain:
		BOSS H  2;
		BOSS H  2 A_Pain;
		Goto See;
	Death:
		BOSS I  0;
		TNT1 A 0 A_Jump(64, "XDeath");
		BOSS I  8;
		TNT1 A 0 A_CustomMissile("CeilingBloodCheckerGreen", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AA 0 A_CustomMissile("XDeath1bGreen", 40,  0, random(0, 360), 2, random(45, 50));
		BOSS J  8 A_Scream;
		BOSS K  8;
		BOSS L  8 A_NoBlocking;
		BOSS MN 8;
		TNT1 A 0 A_CustomMissile("XDeath1Green", 20,  0, random(0, 360), 2, random(10, 45));
		BOSS O -1 A_BossDeath;
		Stop;


	XDeath:
		XBAR A  5;
		TNT1 A 0 A_CustomMissile("CeilingBloodCheckerGreen", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AA 0 A_CustomMissile("XDeath1bGreen", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath2Green", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath3Green", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath2bGreen", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath3bGreen", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBigGreen", 50,  0, random(0, 360), 2, random(10, 45));
		XBAR B  5 A_Scream;
		XBAR C  5;
		XBAR D  5 A_NoBlocking;
		XBAR EFGH 5;
		TNT1 A 0 A_CustomMissile("XDeath1Green", 20,  0, random(0, 360), 2, random(10, 45));
		XBAR h -1 A_BossDeath;
		Stop;


	Death.Plasma:
		XBAR A  5;
		TNT1 A 0 A_CustomMissile("CeilingBloodCheckerGreen", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AA 0 A_CustomMissile("XDeath1bGreen", 40,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath2bGreen", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("XDeath3bGreen", 30,  0, random(0, 360), 2, random(45, 50));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBigGreen", 50,  0, random(0, 360), 2, random(10, 45));
		BBAR B  5 A_Scream;
		BBAR C  5;
		BBAR D  5 A_NoBlocking;
		BBAR EFGH 5;
		TNT1 A 0 A_CustomMissile("XDeath1Green", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_SpawnItem("SmokePillar");
		BBAR h -1 A_BossDeath;
		Stop;

	Raise:
		BOSS O 8;
		BOSS NMLKJI  8;
		Goto See;
	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushedGreen", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2Green", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3Green", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH C 1;
		CRSH C -1;
		Stop;

	}
}
