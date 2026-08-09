// ============================================================================
// rs_mg_lostsoul.zs -- RS_MGLostSoul.  STAGING; see rs_mg_base.zs.
//
// The charger.  Flying, no gravity, stock A_SkullAttack -- it lines up and
// rams.  Its Missile state loops back to Missile+2 rather than to See, so once
// it commits it keeps re-charging without returning to a walk cycle.
//
// It does not dismember.  It BURSTS: one death animation on the vanilla SKUL
// frames, spraying fire, smoke and three flavours of soul-gib.  No Pain
// interrupt worth speaking of (PainChance 256, so it flinches from almost
// anything), no Raise, no Crush, no plasma or saw channel.
//
// ART: 0 custom sequences.  SEE THE MGHP COMMENT -- THIS ONE IS DELIBERATE.
//
// CONVERTED, not copied:
//   +MISSILEMORE  ->  MissileChanceMult 0.5
// Deprecated flag.  The engine's own deprecation message for it says to use
// the missilechancemult property instead, and 0.5 is the value that flag set.
// Behaviour is unchanged; it just stops being one of the deprecation warnings.
// ============================================================================

class RS_MGLostSoul : RS_MG_Monsters
{
	Default
	{
		Health 100;
		Radius 16;
		Height 56;
		Mass 50;
		Speed 8;
		PainChance 256;
		Damage 3;                 // constant, as written -- not a flattened roll
		RenderStyle "Add";
		Alpha 1;
		Monster;
		+FLOORCLIP
		+FLOAT
		+NOGRAVITY
		MissileChanceMult 0.5;    // was +MISSILEMORE
		+DONTFALL
		SeeSound "skull/active";
		AttackSound "skull/melee";
		PainSound "skull/pain";
		DeathSound "skull/death";
		ActiveSound "skull/active";
		Obituary "$OB_SKULL";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "lostsoul"; }
	override string MonIdentity() { return "class:lostsoul species:lostsoul role:charger trait:flying faction:hell set:gore"; }

	// ------------------------------------------------------------------------
	// NO TIERS.  Not an oversight, not a TODO -- a decision, and the only one
	// of its kind in the roster.
	//
	// This monster ships ZERO custom sprite sequences.  Every frame it uses is
	// the vanilla SKUL set: it walks on SKUL AB, attacks on CD, flinches on E
	// and dies on F-K.  There is no alternate death, no gib set, no plasma or
	// crush variant.  Nothing was drawn for it.
	//
	// The owner's rule is that a monster gets as many tiers as it HAS, and
	// this one has none.  A tier the player cannot see is not a tier; it is a
	// hidden stat block that makes one lost soul quietly take three times as
	// many shots as the identical lost soul beside it, with nothing on screen
	// to explain why.  On a monster that arrives in swarms, that reads as the
	// game being inconsistent rather than as an enemy being special.
	//
	// So MGTiers() returns 0, TierData() refuses every colour, and both
	// overrides exist purely to state that out loud where the next reader will
	// look.  The base already returns 0, so neither line is load-bearing --
	// they are here so that a sweep for "which monsters declare a tier count"
	// finds all seventeen, and so that a silent absence can never be mistaken
	// for the dead hook this pass was cleaning up.
	//
	// TO GIVE IT A LADDER, DRAW IT ONE FIRST.  A single alternate death or
	// charge sequence is enough for one rung; add it, bump MGTiers(), and fill
	// in GREEN here.  Do not open with the numbers.
	// ------------------------------------------------------------------------
	override int MGTiers() { return 0; }   // no custom art -> no ladder
	override int MGHP(int t) { return 0; }

	States
	{

	Spawn:
		SKUL AB 10 BRIGHT A_Look;
		Loop;
	See:
		SKUL AB 6 BRIGHT A_Chase;
		Loop;
	Missile:
		SKUL C 10 BRIGHT A_FaceTarget;
		SKUL D 4 BRIGHT A_SkullAttack;
		SKUL CD 4 BRIGHT;
		Goto Missile+2;
	Pain:
		SKUL E 3 BRIGHT;
		SKUL E 3 BRIGHT A_Pain;
		Goto See;
	Death:
		SKUL F 3 BRIGHT;
		SKUL G 3 BRIGHT A_Scream;
		TNT1 AAA 0 A_CustomMissile("ExplosionFire", 10,  0, random(0, 360), 2, random(-90, 90));
		TNT1 A 0 A_CustomMissile("ExplSmokeParticle", 10,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("LostSoulGib1", 20,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("LostSoulGib2", 20,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAA 0 A_CustomMissile("LostSoulGib3", 20,  0, random(0, 360), 2, random(0, 90));
		SKUL H 3 BRIGHT;
		SKUL I 3 BRIGHT A_NoBlocking;
		SKUL J 3;
		SKUL K 3;
		Stop;

	}
}
