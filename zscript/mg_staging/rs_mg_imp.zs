// ============================================================================
// rs_mg_imp.zs -- RS_MGImp.  STAGING; see rs_mg_base.zs.
//
// The skirmisher.  Stock A_TroopAttack, so it claws in melee and throws a
// fireball at range off the same state -- Melee and Missile share a label, as
// vanilla does.  Five randomised dismemberment deaths plus plasma and saw
// channels.
//
// ART: 4 custom sequences -> 4 coloured tiers.
//      TR09 (leg)  TR08 (arm/guts/heavy)  TROH (head)  DPS1 (plasma)
//
// NO CRUSH SEQUENCE.  Unlike almost everything else in the set, this monster
// has no Crush state and no CRSH frame, so a crushed imp falls through to the
// engine's default gib behaviour.  That is the source's shape and it is left
// alone -- adding a Crush state would be inventing art that does not exist.
//
// NOTE, verbatim and NOT tidied: Death2, Death4 and Death5 all run the same
// TR08 sequence with slightly different gib sprays, so three of the five
// branches share an animation.  Only the spray differs.  Left as written.
// ============================================================================

class RS_MGImp : RS_MG_Monsters
{
	Default
	{
		Health 60;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "imp/sight";
		PainSound "imp/pain";
		DeathSound "imp/death";
		ActiveSound "imp/active";
		HitObituary "$OB_IMPHIT";
		Obituary "$OB_IMP";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "imp"; }
	override string MonIdentity()
	{
		return "class:imp species:imp role:skirmisher trait:projectile faction:hell set:gore";
	}

	override int MGTiers() { return 4; }   // TR09 TR08 TROH DPS1

	// ------------------------------------------------------------------------
	// 60 HP base.  The imp is the roster's yardstick monster -- the one whose
	// HP the player has an unconscious feel for -- so its ladder is deliberately
	// the most legible: roughly "two imps", "three imps", "four imps".
	//
	// The spread (x1.8 to x3.8) is narrower than the zombies' because the imp
	// already dies to a single shotgun blast at point blank; every rung has to
	// buy a whole extra shot to register at all, and four rungs of that is all
	// the room there is before it stops reading as an imp and starts reading as
	// a small Hell Knight.
	//
	// It stops at FIREBLU because it only has four sequences.  If more imp art
	// ever turns up, the next rungs are BROWN and YELLOW -- keep the same
	// ~x1.3 step and it lands near 300 and 380.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 110;   // x1.8  -- "two imps"
			case HFMT_CYAN:    return 140;   // x2.3  -- fast, so kept modest
			case HFMT_BLUE:    return 175;   // x2.9  -- "three imps"
			case HFMT_FIREBLU: return 230;   // x3.8  -- ceiling, still sub-Demon
			default:           return 0;
		}
	}

	States
	{
	Spawn:
		TROO AB 10 A_Look;
		Loop;
	See:
		TROO AABBCCDD 3 A_Chase;
		Loop;
	Melee:
	Missile:
		TROO EF 8 A_FaceTarget;
		TROO G 6 A_TroopAttack;
		Goto See;
	Pain:
		TROO H 2;
		TROO H 2 A_Pain;
		Goto See;
	Death:
		TROO I 1;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50, 0, random(0, 360), 2, random(60, 90));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		TROO I 0 A_Jump(192, "Death1", "Death2", "Death3", "Death4", "Death5");
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 40, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(10, 45));
		TROO I 5;
		TROO J 5 A_Scream;
		TROO K 5 A_NoBlocking;
		TROO L 5;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		TROO M -1;
		Stop;
	Death1: // Leg
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 20, 0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeathImpLeg", 10, 0, random(0, 360), 2, random(40, 50));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(10, 45));
		TR09 A 6 A_Scream;
		TR09 B 6 A_NoBlocking;
		TR09 C 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		TR09 D -1;
		Stop;
	Death2: // Arm
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 20, 0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeathImpArm", 50, 0, random(0, 360), 2, random(40, 60));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(10, 45));
		TR08 A 6 A_Scream;
		TR08 B 6 A_NoBlocking;
		TR08 CD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		TR08 E -1;
		Stop;
	Death3: // Head
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 50, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("GibHeadPiece", 55, 0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibTeeth", 55, 0, random(0, 360), 2, random(45, 50));
		TNT1 A 0 A_CustomMissile("GibEyeball", 55, 0, random(0, 360), 2, random(45, 50));
		TROH B 6 A_Scream;
		TROH C 6 A_NoBlocking;
		TROH D 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		TROH E -1;
		Stop;
	Death4: // Guts -- same TR08 sequence as Death2; see file header.
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30, 0, random(0, 360), 2, random(10, 45));
		TR08 A 6 A_Scream;
		TR08 B 6 A_NoBlocking;
		TR08 CD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		TR08 E -1;
		Stop;
	Death5: // Heavy -- identical to Death4; see file header.
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30, 0, random(0, 360), 2, random(10, 45));
		TR08 A 6 A_Scream;
		TR08 B 6 A_NoBlocking;
		TR08 CD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		TR08 E -1;
		Stop;
	XDeath:
		TROO I 1;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60, 0, random(0, 360), 2, random(0, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50, 0, random(0, 360), 2, random(30, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeathImpArm", 50, 0, random(0, 360), 2, random(40, 60));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(10, 45));
		TROO J 5 A_XScream;
		TROO K 5 A_NoBlocking;
		TROO LM 5;
		TNT1 A 0 A_CustomMissile("XDeath1", 40, 0, random(0, 360), 2, random(10, 45));
		TROO N -1;
		Stop;
	Raise:
		TROO MLKJI 8;
		Goto See;
	Death.Plasma:
		DPS1 A 0 A_Stop;
		DPS1 A 0 A_XScream;
		DPS1 A 0 A_NoBlocking;
		TNT1 A 0 A_CustomMissile("XDeath2", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60, 0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 40, 0, random(0, 360), 2, random(10, 45));
		DPS1 ABCDEFG 4;
		TNT1 A 0 A_SpawnItem("SmokePillar");
		DPS1 H -1;
		Stop;
	Death.Saw:
		TROO I 4;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60, 0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 50, 0, random(0, 360), 2, random(30, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 40, 0, random(0, 360), 2, random(10, 45));
		TROO J 5 A_XScream;
		TROO K 5 A_NoBlocking;
		TROO LM 5;
		TROO N -1;
		Stop;
	}
}
