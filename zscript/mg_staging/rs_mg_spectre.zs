// ============================================================================
// rs_mg_spectre.zs -- RS_MGSpectre.  STAGING; see rs_mg_base.zs.
//
// The stealth bruiser: the same body and the same state machine as the demon,
// rendered OptFuzzy at half alpha with +SHADOW so the engine also degrades
// monsters' aim at it.  It shares the demon's sprite sets, which is why both
// count 5 custom sequences off the same four prefixes.
//
// ART: 5 custom sequences -> 5 coloured tiers.
//      SARH  SARC  SAAR  SARB (plasma)  CRSH (crush)
//
// It is a SEPARATE CLASS rather than a subclass of the demon, exactly as the
// source has it.  Left that way on purpose: the two are free to diverge, and
// re-parenting one monster onto another is the kind of tidy-up that reads well
// in a diff and changes behaviour in ways nobody notices until much later.
//
// Same structural note as the demon: XDeath and Death2 share a label.
// ============================================================================

class RS_MGSpectre : RS_MG_Monsters
{
	Default
	{
		Health 150;
		PainChance 180;
		Speed 10;
		Radius 30;
		Height 56;
		Mass 400;
		RenderStyle "OptFuzzy";
		Alpha 0.5;
		Monster;
		+FLOORCLIP
		+SHADOW
		SeeSound "spectre/sight";
		AttackSound "spectre/melee";
		PainSound "spectre/pain";
		DeathSound "spectre/death";
		ActiveSound "spectre/active";
		HitObituary "$OB_SPECTREHIT";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "spectre"; }
	override string MonIdentity() { return "class:spectre species:demon role:bruiser trait:melee trait:stealth faction:hell set:gore"; }

	override int MGTiers() { return 5; }   // SARH SARC SAAR SARB CRSH

	// ------------------------------------------------------------------------
	// 150 HP base, identical to the demon -- and deliberately given a LOWER
	// table than the demon at every single rung, roughly 90% of it.
	//
	// Why the same monster gets less: this one is hard to SEE.  Effective
	// toughness is not just HP, it is HP divided by how reliably the player
	// lands shots, and OptFuzzy plus +SHADOW already costs the player accuracy
	// and aim assist.  Handing the spectre the demon's numbers on top of that
	// stacks two toughness mechanics in the same direction and produces a
	// monster that is tedious rather than tense -- you are not being challenged,
	// you are missing.
	//
	// A tint on a fuzzy sprite is also barely legible, which is a second reason
	// not to let this one climb: the player often cannot tell which rung they
	// are fighting, so the rungs must stay close enough together that guessing
	// wrong is survivable.
	//
	// The two ladders sit deliberately close (240/220, 600/540) so the pair
	// still reads as the same creature.  If the demon's table is ever retuned,
	// retune this one WITH it and keep the ~10% gap.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 220;   // x1.5   (demon 240)
			case HFMT_CYAN:    return 265;   // x1.8   (demon 290)  fast AND unseen
			case HFMT_BLUE:    return 320;   // x2.1   (demon 350)
			case HFMT_FIREBLU: return 410;   // x2.7   (demon 450)
			case HFMT_BROWN:   return 540;   // x3.6   (demon 600)  ceiling
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
