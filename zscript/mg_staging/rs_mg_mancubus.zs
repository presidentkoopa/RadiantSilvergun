// ============================================================================
// rs_mg_mancubus.zs -- RS_MGMancubus.  STAGING; see rs_mg_base.zs.
//
// The artillery piece.  Stock A_FatRaise then the three-stage A_FatAttack1/2/3
// spread, so it commits to a long firing animation and blankets an arc.  Huge,
// slow, and it cannot follow you round a corner.
//
// ART: 6 custom sequences -> 6 coloured tiers.  Tied with the zombieman and
// chaingunner for second-longest ladder in the set, and by far the most art on
// any heavy.
//      XFAT  FAT2  XFT2  XFBT (gib)  XBBT (plasma)  CRSH (crush)
//
// The normal death rolls A_Jump(192, "Death2","Death3","Death4") into three
// alternate gib sequences, so three quarters of its deaths use custom art.
// Every branch ends on A_BossDeath, which is live here: +BOSSDEATH is set, and
// +MAP07BOSS1 makes the last Fatso on Doom 2 MAP07 lower floor tag 666.
// ============================================================================

class RS_MGMancubus : RS_MG_Monsters
{
	Default
	{
		Health 600;
		Radius 48;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 80;
		Monster;
		+FLOORCLIP
		+BOSSDEATH     // crush/ice deaths still fire the boss special
		+MAP07BOSS1    // last Fatso on Doom2 MAP07 lowers floor tag 666
		SeeSound "fatso/sight";
		PainSound "fatso/pain";
		DeathSound "fatso/death";
		ActiveSound "fatso/active";
		Obituary "$OB_FATSO";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "manc"; }
	override string MonIdentity() { return "class:mancubus species:mancubus role:artillery trait:projectile faction:hell set:gore"; }

	override int MGTiers() { return 6; }   // XFAT FAT2 XFT2 XFBT XBBT CRSH

	// ------------------------------------------------------------------------
	// 600 HP base and SIX rungs -- the longest ladder given to anything above
	// the zombie bracket, and the reason is the art: six sequences were drawn
	// for this monster, so six tiers are visibly distinguishable.
	//
	// It can also carry the length.  Radius 48 and Speed 8: it is the biggest
	// non-boss target in the game and one of the slowest, so shots land and the
	// player can always disengage.  And its attack pattern is fixed -- a wide
	// arc from a stationary firing animation with a long wind-up -- so a longer
	// fight means more of the SAME puzzle rather than an escalating one.  That
	// is what makes extra HP safe here and dangerous on the pain elemental.
	//
	// The step is a steady ~x1.2 per rung.  The ceiling (2500, x4.17) lands
	// above a Baron but below a Mastermind, which is the right place for a
	// fully-coloured artillery piece: an event in the room, not the boss of it.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 900;   // x1.5
			case HFMT_CYAN:    return 1080;  // x1.8  -- a Mancubus that repositions
			case HFMT_BLUE:    return 1320;  // x2.2
			case HFMT_FIREBLU: return 1680;  // x2.8
			case HFMT_BROWN:   return 2100;  // x3.5  -- slow and enormous
			case HFMT_YELLOW:  return 2500;  // x4.17 -- ceiling, above Baron, under Mastermind
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		FATT AB 15 A_Look;
		Loop;
	See:
		FATT AABBCCDDEEFF 4 A_Chase;
		Loop;
	Missile:
		FATT G 20 A_FatRaise;
		FATT H 10 BRIGHT A_FatAttack1;
		FATT IG 5;
		FATT H 10 BRIGHT A_FatAttack2;
		FATT IG 5;
		FATT H 10 BRIGHT A_FatAttack3;
		FATT IG 5;
		Goto See;
	Pain:
		FATT J 3;
		FATT J 3 A_Pain;
		Goto See;
	Death:
		FATT K 0;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_Jump(192, "Death2", "Death3", "Death4");
		TNT1 A 0 A_CustomMissile("XDeath1b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		FATT K 6;
		FATT L 6 A_Scream;
		FATT M 6 A_NoBlocking;
		FATT NOPQ 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		FATT RS 6;
		FATT T -1 A_BossDeath;
		Stop;

	Death2:
		FATT K 0;
		TNT1 A 0 A_Scream;
		TNT1 A 0 A_NoBlocking;
		XFAT ABCD 6;
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		XFAT EFGHI 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		XFAT I -1 A_BossDeath;
		Stop;

	Death3:
		FATT K 0;
		TNT1 A 0 A_Scream;
		TNT1 A 0 A_NoBlocking;
		FAT2 KL 6;
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		FAT2 MNOP 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		FAT2 P -1 A_BossDeath;
		Stop;

	Death4:
		FATT K 0;
		TNT1 A 0 A_Scream;
		TNT1 A 0 A_NoBlocking;
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("XDeath3b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("FatsoArm", 50,  0, random(0, 360), 2, random(10, 45));
		XFT2 ABCD 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		XFT2 D -1 A_BossDeath;
		Stop;


	XDeath:
		FATT K 0;
		TNT1 A 0 A_Scream;
		TNT1 A 0 A_NoBlocking;
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("FatsoArm", 50,  0, random(0, 360), 2, random(10, 45));
		XFBT ABCDEF 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		XFBT F -1 A_BossDeath;
		Stop;

	Death.Plasma:
		FATT K 0;
		TNT1 A 0 A_Scream;
		TNT1 A 0 A_NoBlocking;
		TNT1 AAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 A 0 A_CustomMissile("FatsoArm", 50,  0, random(0, 360), 2, random(10, 45));
		XBBT ABCDEF 6;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		XBBT F -1 A_BossDeath;
		Stop;

	Raise:
		FATT R 5;
		FATT QPONMLK 5;
		Goto See;

	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH F 1;
		CRSH F -1;
		Stop;

	}
}
