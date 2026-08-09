// ============================================================================
// rs_mg_zombieman.zs -- RS_MGZombieman.  STAGING; see rs_mg_base.zs.
//
// The rifle grunt.  Fires a fast projectile bullet rather than a true hitscan,
// so it is dodgeable at range and lethal in a corridor.  Five randomised
// dismemberment deaths (leg / arm / head / guts / heavy) plus separate saw,
// plasma and crush channels.
//
// ART: 6 custom sequences -> 6 coloured tiers.
//      POS7 (leg)  ZZD2 (arm)  ZZD6 (head)  ZXZ2 (guts/heavy)
//      DPS1 (plasma)  CRSH (crush)
//
// NOTE, verbatim from the source and NOT tidied: Death4 and Death5 are
// byte-identical -- both run the ZXZ2 sequence with the same gib spray.  The
// A_Jump therefore has a 2-in-5 chance of the same animation.  It may be an
// unfinished sixth sequence or it may be a deliberate weighting; either way
// collapsing two branches into one is the kind of "obvious" cleanup that has
// silently wrecked monster work in this repo before.  Left alone; owner's call.
// ============================================================================

class RS_MGZombieman : RS_MG_Monsters
{
	Default
	{
		Health 20;
		Radius 20;
		Height 56;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "grunt/sight";
		AttackSound "grunt/attack";
		PainSound "grunt/pain";
		DeathSound "grunt/death";
		ActiveSound "grunt/active";
		Obituary "$OB_ZOMBIE";
		DropItem "Clip";
		BloodColor "darkred";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "zombie"; }
	override string MonIdentity()
	{
		return "class:zombieman species:zombie role:fodder trait:hitscan faction:hell set:gore";
	}

	override int MGTiers() { return 6; }   // POS7 ZZD2 ZZD6 ZXZ2 DPS1 CRSH

	// ------------------------------------------------------------------------
	// 20 HP base -- the floor of the whole roster.
	//
	// Fodder needs the STEEPEST ratio in the set, which is the exact opposite
	// of what the old shared curve gave it.  At the shared x1.6, a green
	// zombieman was 32 HP: still one pistol burst, still one shotgun pellet
	// spread, so the tier was invisible in play.  Ratio is meaningless at this
	// scale; what matters is how many shots it eats, and 20 -> 32 does not
	// change that number at all.
	//
	// So this climbs x2 to x7 while the absolute figure stays small enough to
	// keep the monster feeling like a grunt.  The top of the ladder (140) is
	// roughly two SSG blasts -- a grunt you have to commit to, not a mini-boss.
	// A zombieman that survives longer than that stops reading as a zombieman.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 40;    // x2.0  -- one extra pistol burst
			case HFMT_CYAN:    return 50;    // x2.5  -- fast; HP is not its threat
			case HFMT_BLUE:    return 60;    // x3.0  -- survives a single shotgun
			case HFMT_FIREBLU: return 80;    // x4.0
			case HFMT_BROWN:   return 110;   // x5.5  -- the slow tanky one
			case HFMT_YELLOW:  return 140;   // x7.0  -- ceiling: ~2 SSG blasts
			default:           return 0;     // Neutral, and tiers it has no art for
		}
	}

	States
	{
	Spawn:
		POSS AB 10 A_Look;
		Loop;
	See:
		POSS AABBCCDD 4 A_Chase;
		Loop;
	Missile:
		POSS E 10 A_FaceTarget;
		TNT1 A 0 A_StartSound("ENEMYGUN", CHAN_WEAPON);
		TNT1 A 0 A_StartSound("MGUN2", 4);
		TNT1 A 0 A_CustomMissile("MG_EnemyBullet", 38, 0, random(-6,6), 1, random(-1,1));
		POSS F 8;
		POSS E 8;
		Goto See;
	Pain:
		POSS G 3;
		POSS G 3 A_Pain;
		Goto See;
	Death.Melee:
		NULL A 0;
		NULL A 0 A_FaceTarget;
		NULL A 0 A_Recoil(10);
	Death:
		POSS H 0;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50, 0, random(0, 360), 2, random(60, 90));
		POSS H 0 A_Jump(192, "Death1", "Death2", "Death3", "Death4", "Death5");
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 40, 0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		POSS H 5;
		POSS I 5 A_Scream;
		POSS J 5 A_NoBlocking;
		POSS K 5;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		POSS L -1;
		Stop;
	Death1: // Leg
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 20, 0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XZombieManLeg", 10, 0, random(0, 360), 2, random(40, 50));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		POS7 A 6 A_Scream;
		POS7 B 6 A_NoBlocking;
		POS7 C 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		POS7 D -1;
		Stop;
	Death2: // Arm
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 20, 0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_CustomMissile("XDeathArm", 50, 0, random(0, 360), 2, random(40, 60));
		TNT1 A 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		ZZD2 A 6 A_Scream;
		ZZD2 B 6 A_NoBlocking;
		ZZD2 CD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		ZZD2 E -1;
		Stop;
	Death3: // Head
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 50, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		ZZD6 B 6 A_Scream;
		ZZD6 C 6 A_NoBlocking;
		ZZD6 DEF 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		ZZD6 G -1;
		Stop;
	Death4: // Guts
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30, 0, random(0, 360), 2, random(10, 45));
		ZXZ2 A 6 A_Scream;
		ZXZ2 B 6 A_NoBlocking;
		ZXZ2 BCD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		ZXZ2 E -1;
		Stop;
	Death5: // Heavy -- identical to Death4 in the source; see file header.
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 30, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3b", 30, 0, random(0, 360), 2, random(10, 45));
		ZXZ2 A 6 A_Scream;
		ZXZ2 B 6 A_NoBlocking;
		ZXZ2 BCD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20, 0, random(0, 360), 2, random(10, 45));
		ZXZ2 E -1;
		Stop;
	XDeath:
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleBig", 50, 0, random(0, 360), 2, random(30, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(45, 50));
		TNT1 AA 0 A_CustomMissile("XDeathArm", 50, 0, random(0, 360), 2, random(40, 60));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 50, 0, random(0, 360), 2, random(10, 45));
		POSS N 5 A_XScream;
		POSS O 5 A_NoBlocking;
		POSS PQRST 5;
		TNT1 A 0 A_CustomMissile("XDeath1", 40, 0, random(0, 360), 2, random(10, 45));
		POSS U -1;
		Stop;
	Death.Saw:
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60, 0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 50, 0, random(0, 360), 2, random(30, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath1b", 40, 0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 40, 0, random(0, 360), 2, random(10, 45));
		POSS N 5 A_XScream;
		POSS O 5 A_NoBlocking;
		POSS PQRST 5;
		POSS U -1;
		Stop;
	Raise:
		POSS K 5;
		POSS JIH 5;
		Goto See;
	Death.Plasma:
		DPS1 A 0 A_Stop;
		DPS1 A 0 A_XScream;
		DPS1 A 0 A_NoBlocking;
		TNT1 A 0 A_SpawnItem("SmokePillar");
		TNT1 A 0 A_CustomMissile("XDeath2", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("FlyingBloodParticleFast", 60, 0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleBig", 30, 0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath1", 40, 0, random(0, 360), 2, random(10, 45));
		DPS1 ABCDEFG 4;
		DPS1 H -1;
		Stop;
	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0, 0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50, 0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50, 0, random(0, 360), 2, random(10, 45));
		CRSH A 1;
		CRSH A -1;
		Stop;
	}
}
