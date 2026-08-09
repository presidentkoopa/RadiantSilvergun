// ============================================================================
// rs_mg_painelemental.zs -- RS_MGPainElemental.  STAGING; see rs_mg_base.zs.
//
// The summoner.  Stock A_PainAttack while alive and A_PainDie on death, so it
// spits lost souls at you and then bursts into three more.  Floating, no
// gravity, no melee.  It is the only monster in the set whose threat is other
// monsters.
//
// ART: 1 custom sequence -> 1 coloured tier.
//      The vanilla PAIN set runs A-M.  This actor's death animation ends on
//      PAIN X -- frame index 23, well past the end of the vanilla set, so it
//      is custom art added to an otherwise stock prefix.  That single frame is
//      the entire art budget for this monster, hence one rung.
//
// No Crush state and no plasma or saw channel: it has one death and that death
// is the A_PainDie burst.
// ============================================================================

class RS_MGPainElemental : RS_MG_Monsters
{
	Default
	{
		Health 400;
		Radius 31;
		Height 56;
		Mass 400;
		Speed 8;
		PainChance 128;
		Monster;
		+FLOORCLIP
		+FLOAT
		+NOGRAVITY
		SeeSound "pain/sight";
		PainSound "pain/pain";
		DeathSound "pain/death";
		ActiveSound "pain/active";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "pe"; }
	override string MonIdentity() { return "class:painelemental species:painelemental role:summoner trait:flying faction:hell set:gore"; }

	override int MGTiers() { return 1; }   // PAIN X

	// ------------------------------------------------------------------------
	// 400 HP base, ONE rung, and the smallest multiplier given to anything
	// outside the boss bracket: x1.4.
	//
	// A summoner is the one monster where HP does not scale linearly with
	// difficulty -- it COMPOUNDS.  Every extra second alive is another lost
	// soul on the field, and those souls then occupy the player and buy the
	// elemental more seconds.  Double this monster's HP and you have far more
	// than doubled the fight, because the reinforcements arrive while you are
	// already busy with the previous ones.
	//
	// Cacodemon HP on a cacodemon is a longer fight.  Cacodemon HP on a pain
	// elemental is a room that never empties.  So the one rung it earns is a
	// small one: 560 is a noticeably tougher elemental, not a spawner that
	// outlasts your ammunition.
	//
	// EVEN IF MORE ART TURNS UP, do not extend this ladder at the set's usual
	// step.  Whatever the sprite count says, this monster's HP has to be
	// tuned against the souls it produces, and that is a playtest, not a
	// multiplication.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 560;   // x1.4 -- deliberately the smallest non-boss step
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		PAIN A 10 A_Look;
		Loop;
	See:
		PAIN AABBCC 3 A_Chase;
		Loop;
	Missile:
		PAIN D 5 A_FaceTarget;
		PAIN E 5 A_FaceTarget;
		PAIN F 4 BRIGHT A_FaceTarget;
		PAIN F 1 BRIGHT A_PainAttack;
		Goto See;
	Pain:
		PAIN G 6;
		PAIN G 6 A_Pain;
		Goto See;
	Death:
		PAIN H 8 BRIGHT;
		PAIN I 8 BRIGHT A_Scream;
		PAIN JK 8 BRIGHT;
		TNT1 A 0 A_CustomMissile("XDeath1b", 20,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAAAAAAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("ExplosionFire", 0,  0, random(0, 360), 2, random(-90, 90));
		TNT1 AAA 0 A_CustomMissile("ExplSmokeParticle", 0,  0, random(0, 360), 2, random(0, 90));
		PAIN L 8 BRIGHT A_PainDie;
		PAIN M 8;
		PAIN X 1;
		TNT1 A 0 A_CustomMissile("XDeath1", 20,  0, random(0, 360), 2, random(10, 45));
		PAIN X -1;
		Stop;
	Raise:
		PAIN MLKJIH 8;
		Goto See;

	}
}
