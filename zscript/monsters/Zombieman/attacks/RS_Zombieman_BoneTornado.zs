// =====================================================================
// RS_Zombieman_BoneTornado -- the Undertaker's final-form attack.
// ---------------------------------------------------------------------
// CHP source: CHP/DECORATE/01/01_W.txt -- BoneTornado state at :52,
// BoneTorn2_C at :4268, BoneStormer1_C..7_C at :5080 onward.
//
// Unlocked at ladder rung 3 (FinalForm). The monster's own state is
// trivial -- a wind-up and ONE A_CustomMissile("BoneTorn2_C") -- because
// every bit of the attack lives in the projectile it throws.
//
// WHAT THE TORNADO ACTUALLY IS: a floor-hugging emitter that wanders,
// bounces off walls forever (BounceCount 999) and, over about 90 tics,
// spawns SEVEN DISTINCT ORBITER TYPES in a long interleaved sequence,
// with bone bolts thrown out of it periodically.
//
// EACH ORBITER IS A RING, NOT A CLOUD. CHP's BoneStormer does:
//     A_Warp(AAPTR_MASTER, 32, 0, 32, user_angle,
//            WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE)
//     A_SetUserVar("user_angle", user_angle + 8)
//     A_Jump(8, "Death")
// -- so it pins itself 32 units out and 32 up from the tornado, advances
// EIGHT DEGREES PER TIC, and has an 8/256 chance each tic of expiring.
// A ripper with FORCEPAIN, damage random(1,3). The seven variants differ
// only in Speed (105/115/120/125/130/130/155), which sets how far each
// travels between warps and therefore how tight its ring reads.
//
// OUR PREVIOUS VERSION was one RS_BoneStormer picking
// frandom(12,80) radius / frandom(10,128) height / frandom(0,359) angle
// once at spawn -- a static random cloud, not seven counter-reading
// rings, and it never advanced. Three spawn lines against CHP's 32.
//
// ONE CHP BUG DELIBERATELY NOT REPRODUCED. CHP 01_W.txt:4281 (and :4291,
// :4305, :4314, and CH Zombies.txt:2507) reads:
//     A_CustomMissile("BoneProjZM3_C",4,random(-20,20),
//                     CMF_AIMOFFSET,random(0,360),random(0,360))
// The signature is (type, height, xyofs, ANGLE, FLAGS, PITCH), so
// CMF_AIMOFFSET (== 1) is passed as a ONE-DEGREE ANGLE and random(0,360)
// lands in the FLAGS bitfield -- relighting an arbitrary mix of
// CMF_AIMDIRECTION | TRACKOWNER | ABSOLUTEPITCH | ABSOLUTEANGLE on every
// single call. It is a transposition, not a design. We fire what it
// plainly meant: a random angle with AIMOFFSET set. Recorded here rather
// than silently corrected, per rs_21 s2.
// =====================================================================

// ---------------------------------------------------------------------
// THE ORBITERS. One base, six speed variants -- CHP writes seven full
// actors; the only property that differs is Speed.
// ---------------------------------------------------------------------
class RS_BoneStormerRing : FastProjectile
{
	// CHP's `var int user_angle`, advanced 8 per tic.
	int orbAngle;

	Default
	{
		Radius 8;
		Height 8;
		DamageFunction (random(1, 3));
		Speed 120;
		Projectile;
		+BLOODLESSIMPACT
		+RIPPER
		+FORCEPAIN
		Scale 0.75;
		Translation "0:255=[129,129,129]:[255,255,255]";
		DeathSound "Ice/Fly";
	}

	States
	{
	Spawn:
		// NoDelay so the first warp lands on the spawn tic, as CHP's does
		// -- without it the orbiter is visible at the emitter's centre for
		// one tic before snapping out to its ring.
		BBBN A 1 Bright NoDelay
		{
			A_Warp(AAPTR_MASTER, 32, 0, 32, orbAngle,
			       WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE);
			orbAngle += 8;
		}
		TNT1 A 0 A_Jump(8, "Death");   // 8/256 per tic -- CHP's own decay
		Goto Spawn;
	Death:
		TNT1 A 1;
		Stop;
	}
}

class RS_BoneStormer2R : RS_BoneStormerRing { Default { Speed 105; } }
class RS_BoneStormer3R : RS_BoneStormerRing { Default { Speed 115; } }
class RS_BoneStormer4R : RS_BoneStormerRing { Default { Speed 130; } }
class RS_BoneStormer5R : RS_BoneStormerRing { Default { Speed 125; } }
class RS_BoneStormer6R : RS_BoneStormerRing { Default { Speed 130; } }
class RS_BoneStormer7R : RS_BoneStormerRing { Default { Speed 155; } }

// ---------------------------------------------------------------------
// THE TORNADO. CHP BoneTorn2_C, 01_W.txt:4268.
// The interleave order and the tic counts are CHP's, transcribed rather
// than tidied -- the ragged 7/3/7/7/3/8 pattern is what makes the storm
// build unevenly instead of pulsing.
// ---------------------------------------------------------------------
class RS_BoneTornado : Actor
{
	Default
	{
		Radius 6; Height 8; Speed 18; Mass 25;
		Projectile;
		+FLOORHUGGER +THRUACTORS +DONTBLAST +DONTTHRUST
		+BOUNCEONWALLS
		BounceType "Doom"; BounceCount 999; BounceFactor 1; WallBounceFactor 1.1;
		RenderStyle "Add"; Alpha 0.75;
		SeeSound "skeleton/attack";
	}

	// The bolt CHP throws out of the storm. See the header: CHP's own
	// call has its ANGLE and FLAGS arguments transposed; this is what it
	// meant.
	void RS_TornadoBolt()
	{
		A_SpawnProjectile("RS_BoneProjZM3", 4, random(-20, 20),
		                  random(0, 360), CMF_AIMOFFSET, random(0, 360));
	}

	States
	{
	Spawn:
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormerRing", 0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCC     0        A_SpawnItemEx("RS_BoneStormer3R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer2R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer4R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCC     0        A_SpawnItemEx("RS_BoneStormer5R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer6R",  0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCDD 1 Bright { RS_TornadoBolt(); }
		RNGG CCCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer7R",  0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormerRing",0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCCCCC 0      A_SpawnItemEx("RS_BoneStormer3R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCC 1 Bright     A_SpawnItemEx("RS_BoneStormer2R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer4R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCC 0            A_SpawnItemEx("RS_BoneStormer5R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer6R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer7R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCDD 1 Bright { RS_TornadoBolt(); }
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer4R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCC 0            A_SpawnItemEx("RS_BoneStormer5R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer6R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCC 1 Bright     A_SpawnItemEx("RS_BoneStormer7R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormerRing", 0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCC 0            A_SpawnItemEx("RS_BoneStormer3R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer2R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer4R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 0         A_SpawnItemEx("RS_BoneStormer5R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer6R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormer7R",   0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		RNGG CCDD 1 Bright { RS_TornadoBolt(); }
		RNGG CCCCCC 1 Bright  A_SpawnItemEx("RS_BoneStormerRing", 0,0,4, 0,0,0, 0, SXF_SETMASTER|SXF_ORIGINATOR);
		Stop;
	}
}
