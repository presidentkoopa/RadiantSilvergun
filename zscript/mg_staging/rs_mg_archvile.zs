// ============================================================================
// rs_mg_archvile.zs -- RS_MGArchvile.  STAGING; see rs_mg_base.zs.
//
// The support monster.  A_VileChase in See, so it walks the map raising the
// corpses of anything it passes; A_VileTarget then A_VileAttack for the
// unavoidable line-of-sight fire attack.  Speed 15 and PainChance 10 -- it is
// the fastest thing in the roster and it barely flinches.
//
// ART: 3 custom sequences -> 3 coloured tiers.
//      XVIL (gib)  BVIL (plasma)  CRSH (crush)
//
// The normal death is a coin flip -- A_Jump(128, "Death2") -- between the
// vanilla VILE collapse and the XVIL sequence.
//
// NOTE, verbatim and NOT tidied: both the XVIL and BVIL sequences run `DFGH`
// -- frame E is skipped in each.  Consistent across both, so it may well be
// intentional (or E may simply not exist in those sets); either way, filling
// it in would be inventing a frame.
//
// TECHNICAL NOTE: the Heal state is `VILE "[\]" 10 BRIGHT;`.  That is three
// frames -- [ , \ , ] -- quoted because the backslash is not a bare frame
// letter.  The `\` frame (index 27) is legal in a lump name and illegal as a
// Windows filename; the engine's escape for it on disk is `^`, so that lump
// ships as VILE^n.  Do not "correct" either the quoting here or the caret in
// the filename.
//
// COSMETIC NORMALISATION: the source label read `Death.PLasma`.  ZScript state
// labels are case-insensitive so it resolved fine; it now reads Death.Plasma
// to match every other file in the set.
// ============================================================================

class RS_MGArchvile : RS_MG_Monsters
{
	Default
	{
		Health 700;
		Radius 20;
		Height 56;
		Mass 500;
		Speed 15;
		PainChance 10;
		Monster;
		+FLOORCLIP
		SeeSound "vile/sight";
		PainSound "vile/pain";
		DeathSound "vile/death";
		ActiveSound "vile/active";
		Obituary "$OB_VILE";
	}

	override void BeginPlay() { Super.BeginPlay(); tintFam = "archvile"; }
	override string MonIdentity() { return "class:archvile species:archvile role:support trait:fire faction:hell set:gore"; }

	override int MGTiers() { return 3; }   // XVIL BVIL CRSH

	// ------------------------------------------------------------------------
	// 700 HP base and THE SHALLOWEST NON-BOSS LADDER IN THE SET: x1.3 to x1.79.
	// A green archvile gets less proportional HP than a green zombieman by a
	// factor of five, and that is the correct answer, not a rounding accident.
	//
	// The archvile is designed around dying fast.  Everything else about it --
	// the unavoidable in-sight attack, the resurrection walk, the speed, the
	// PainChance 10 that means you cannot stunlock it -- assumes the player's
	// counterplay is to burn it down NOW, before it finishes an attack and
	// before it raises the room.  HP is the one stat that attacks that
	// assumption directly.
	//
	// It is also the only monster whose survival can UNDO the player's
	// progress: every second it lives is corpses standing back up, so its HP
	// buys more than time, it buys back the fight you already won.  Nothing
	// else in the roster compounds like that except the pain elemental, and
	// both of them get the smallest steps for the same reason.
	//
	// The ceiling (1250) sits only a little over a Baron's neutral 1000, and
	// that is as far as this monster may go.  A blue archvile should be the
	// thing you drop everything to kill -- and should still die when you do.
	// ------------------------------------------------------------------------
	override int MGHP(int t)
	{
		switch (t)
		{
			case HFMT_GREEN:   return 910;   // x1.30 -- smallest first step in the set
			case HFMT_CYAN:    return 1050;  // x1.50 -- and it is ALREADY the fastest thing here
			case HFMT_BLUE:    return 1250;  // x1.79 -- ceiling; still killable inside one attack cycle
			default:           return 0;
		}
	}

	States
	{

	Spawn:
		VILE AB 10 A_Look;
		Loop;
	See:
		VILE AABBCCDDEEFF 2 A_VileChase;
		Loop;
	Missile:
		VILE G 0 BRIGHT A_VileStart;
		VILE G 10 BRIGHT A_FaceTarget;
		VILE H 8 BRIGHT A_VileTarget;
		VILE IJKLMN 8 BRIGHT A_FaceTarget;
		VILE O 8 BRIGHT A_VileAttack;
		VILE P 20 BRIGHT;
		Goto See;
	Heal:
		VILE "[\]" 10 BRIGHT;
		Goto See;
	Pain:
		VILE Q 5;
		VILE Q 5 A_Pain;
		Goto See;
	Death:
		TNT1 A 0;
		TNT1 A 0 A_Jump(128, "Death2");
		VILE Q 7;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAAA 0 A_CustomMissile("XDeath2", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAAA 0 A_CustomMissile("XDeath3", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(10, 45));
		VILE R 7 A_Scream;
		VILE S 7 A_NoBlocking;
		VILE TUVWXY 7;
		TNT1 A 0 A_CustomMissile("XDeath1", 40,  0, random(0, 360), 2, random(10, 45));
		VILE Z -1;
		Stop;

	Death2:
		XVIL A 5;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath2", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AAA 0 A_CustomMissile("XDeath3", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(10, 45));
		XVIL B 5 A_Scream;
		XVIL C 5 A_NoBlocking;
		XVIL DFGH 5;
		TNT1 A 0 A_CustomMissile("XDeath1", 40,  0, random(0, 360), 2, random(10, 45));
		XVIL I -1;
		Stop;

	Death.Plasma:
		BVIL A 5;
		TNT1 A 0 A_CustomMissile("CeilingBloodChecker", 50,  0, random(0, 360), 2, random(60, 90));
		TNT1 AAAA 0 A_CustomMissile("FlyingBloodParticleFast", 50,  0, random(0, 360), 2, random(0, 90));
		TNT1 AAAAA 0 A_CustomMissile("FlyingBloodParticleBig", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath2", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 40,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath1b", 40,  0, random(0, 360), 2, random(10, 45));
		BVIL B 5 A_Scream;
		BVIL C 5 A_NoBlocking;
		BVIL DFGH 5;
		TNT1 A 0 A_SpawnItem("SmokePillar");
		TNT1 A 0 A_CustomMissile("XDeath1", 40,  0, random(0, 360), 2, random(10, 45));
		BVIL I -1;
		Stop;

	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("FlyingBloodParticleCrushed", 0,  0, random(0, 360), 2, random(0, 90));
		TNT1 AA 0 A_CustomMissile("XDeath2", 50,  0, random(0, 360), 2, random(10, 45));
		TNT1 AA 0 A_CustomMissile("XDeath3", 50,  0, random(0, 360), 2, random(10, 45));
		CRSH A 1;
		CRSH A -1;
		Stop;

	}
}
