// ============================================================================
// rs_mg_baron.zs -- RS_MGBaron.  STAGING; see rs_mg_base.zs.
//
// The heavy bruiser.  Stock A_BruisAttack, sharing one label for Melee and
// Missile as vanilla does, so it claws up close and throws a green plasma ball
// at range.  Its normal death is a 64/256 coin flip into the XBAR gib
// sequence, and all of its gore is the GREEN variant set.
//
// ART: 3 custom sequences -> 3 coloured tiers.
//      XBAR (gib)  BBAR (plasma)  CRSH (crush)
//
// MAP HOOKS, kept: +BOSSDEATH so crush and ice deaths still fire the boss
// special, and +E1M8BOSS so the last Baron on Doom 1 E1M8 lowers floor tag 666.
// Both A_BossDeath calls sit on the final -1 frame of each death branch, which
// is why every branch has one.
//
// COSMETIC NORMALISATION: the source wrote `A_JumP` (mixed case) on both the
// Death and XDeath entries.  ZScript function names are case-insensitive so
// this changed nothing; it now reads A_Jump.  Frame letters were NOT touched,
// including the lowercase `XBAR h -1` / `BBAR h -1` at the end of the gib and
// plasma sequences -- the engine folds those to H, and rewriting sprite frames
// on a monster is not a cosmetic edit.
// ============================================================================

class RS_MGBaron : RS_MG_Monsters
{
	Default
	{
		Health 1000;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 50;
		Monster;
		+FLOORCLIP
		+BOSSDEATH     // crush/ice deaths still fire the boss special
		+E1M8BOSS      // last Baron on Doom1 E1M8 lowers floor tag 666
		SeeSound "baron/sight";
		PainSound "baron/pain";
		DeathSound "baron/death";
		ActiveSound "baron/active";
		Obituary "$OB_BARON";
		HitObituary "$OB_BARONHIT";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "baron"; }
	override string MonIdentity() { return "class:baron species:baron role:bruiser trait:projectile faction:hell set:gore"; }

	override int MGTiers() { return 3; }   // XBAR BBAR CRSH

	// ------------------------------------------------------------------------
	// 1000 HP base -- the first monster in the roster where the multiplier
	// stops being the interesting number and the ABSOLUTE total takes over.
	//
	// At this scale a multiplier that felt reasonable lower down is disastrous.
	// The fodder ladder tops out at x7; x7 here is 7000 HP, more than a
	// Cyberdemon, on a monster that is supposed to arrive in pairs.  So the
	// bracket inverts: the bigger the base, the smaller the step.  x1.4 to
	// x1.95, and the ceiling deliberately stops just under 2000 so a blue Baron
	// is still a fight you can finish with the ammunition in the room rather
	// than a wall you have to leave and come back to.
	//
	// This is the whole reason the old shared curve had to go.  It applied the
	// same x1.6 to this monster and to a 20 HP zombieman: on the zombieman that
	// was 12 HP and invisible, on the Baron it was 600 HP and a different
	// encounter.  One number cannot mean both things.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 1400;  // x1.40
			case HFMT_CYAN:    return 1650;  // x1.65 -- fast Baron; speed is the buff, not bulk
			case HFMT_BLUE:    return 1950;  // x1.95 -- ceiling, still under 2k on purpose
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
