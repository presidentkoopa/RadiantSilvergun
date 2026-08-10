// =====================================================================
// RS_MG_Gore -- the dismemberment/gib actor set for the RS_MG monsters.
//
// Rebuilt native ZScript from MeatGrinder V2C (gore.txt, specialeffects.txt,
// weapons.txt). Every class is RS_MG_ prefixed: the originals used bare
// names (XDeath1, FlyingBloodParticle, GibTeeth) that are far too generic
// to drop into a tree this size without a collision risk.
//
// ---------------------------------------------------------------------
// CONVERSIONS MADE, AND WHY -- none of these are optional
// ---------------------------------------------------------------------
//   * ThrustThingZ() IS ACS, NOT ZSCRIPT. Verified absent from the engine's
//     whole zscript tree. It appears three times in the source (the two
//     ceiling-meat actors and the wall-smear). ACS thrust is in 1/8 units,
//     so ThrustThingZ(0,20,0,1) becomes vel.z += 2.5 and (0,1,1,1) --
//     downwards=1 -- becomes vel.z -= 0.125.
//   * `Game Doom` and `SpawnID` are DECORATE-only. Deleted, not converted.
//   * XScale/YScale are not ZScript Default properties and non-uniform
//     scale CANNOT be set in a Default block at all -- the engine's
//     scale property takes one float for both axes. Every stretched actor
//     therefore sets Scale in BeginPlay. Flattening them to a uniform
//     value would be silent data loss; the blood SPOTS are meant to be
//     wide and flat (1.0 x 0.3), and a round one reads as a ball.
//   * `Decal BrutalBloodSuper` dropped: that decal is defined in the
//     source pack's DECALDEF, which is not imported here. An undefined
//     decal name is a load-time complaint, so the property is removed
//     rather than left dangling. Restore it with the DECALDEF if wanted.
//   * A_PlaySound -> A_StartSound (the former is deprecated).
//
// SOUNDS: misc/xdeath2 and misc/xdeath4 are stock GZDoom and resolve.
// "blooddrop2" is the source pack's own and is NOT imported -- an
// unresolved sound name is completely inert here (no error, no log line),
// so the drip is simply silent until the lump lands. Recorded because a
// silent sound is the exact failure this project has been bitten by.
// =====================================================================

// ---------------------------------------------------------------------
// Base blood particle. Everything gory inherits from this.
// ---------------------------------------------------------------------
class RS_MG_Blood : Actor
{
	Default
	{
		Projectile;
		+MISSILE
		+THRUACTORS
		+CLIENTSIDEONLY
		+BOUNCEONCEILINGS
		-NOGRAVITY
		Radius 2;
		Height 2;
		Gravity 0.7;
		Speed 5;
	}
	States
	{
	Spawn:
		BSPR ABCDEFGHIJ 2;
		BSPR J 100;
		Stop;
	Death:
	XDeath:
	Crash:
		XDT1 FGHIJJKL 2;
		Stop;
	NoSpawn:
	Splash:
		TNT1 A 0;
		Stop;
	}
}

class RS_MG_BloodFast : RS_MG_Blood
{
	Default { Speed 10; -BOUNCEONWALLS }
}

class RS_MG_BloodCrushed : RS_MG_BloodFast
{
	Default { Speed 2; +NOCLIP +NOGRAVITY }
	States
	{
	Spawn:
		BSPR ABCDEFGHIJ 2;
		Stop;
	}
}

class RS_MG_BloodBig : RS_MG_Blood
{
	Default { Speed 8; Gravity 0.5; }
	States
	{
	Spawn:
		BLHT ABCDEF 3;
		BSPR F 100;
		Stop;
	Death:
	XDeath:
	Crash:
		XDT1 FGHIJJKL 2;
		Stop;
	}
}

// ---------------------------------------------------------------------
// Flat blood decals-on-the-floor. Non-uniform scale, so BeginPlay.
// The source rolled one of ten sizes; kept, because identical spots
// tile visibly when several land together.
// ---------------------------------------------------------------------
class RS_MG_BloodSpot : Actor
{
	Default
	{
		+CLIENTSIDEONLY
		+THRUACTORS
		+DONTGIB
		+NOCLIP
		Radius 1;
		Height 1;
	}
	override void BeginPlay()
	{
		Super.BeginPlay();
		Scale = (1.0, 0.3);   // source XScale 1.0 / YScale 0.3
	}
	States
	{
	Spawn:
		BSPR C 1;
		TNT1 A 0 A_SetAngle(random(0, 360));
		TNT1 A 0
		{
			// source: A_Jump(255, Spawn1..Spawn9, Live) -- ten even buckets
			double s = 0.90 + 0.02 * random(0, 9);
			Scale = (s + 0.08, s * 0.35);
		}
		BSPR C 1 A_QueueCorpse;
		BSPR C -1;
		Stop;
	}
}

class RS_MG_BloodSpot2 : RS_MG_BloodSpot {}

class RS_MG_CeilBloodSpot : RS_MG_BloodSpot2
{
	Default { +NOGRAVITY Gravity 0.0; }
	override void BeginPlay()
	{
		Super.BeginPlay();
		Scale = (0.6, 0.15);
	}
	States
	{
	Spawn:
		BSPR C 1;
		TNT1 A 0 A_SetAngle(random(0, 360));
		BSPR C 1 A_QueueCorpse;
		TNT1 A 0 A_SpawnItem("RS_MG_CeilBloodSpawner");
	Live:
		BSPR C 10 { vel.z += 2.5; }   // was ThrustThingZ(0,20,0,1)
		Loop;
	}
}

class RS_MG_CeilBloodSpawner : Actor
{
	Default { +NOGRAVITY +THRUACTORS +NOCLIP Scale 0.5; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 3 A_SpawnItemEx("RS_MG_CeilDripBig", random(-10,10), random(-10,10), 0, 0, 0, -5);
		TNT1 AAAAAAAAAAAAAA 10 A_SpawnItemEx("RS_MG_CeilDripBig", random(-10,10), random(-10,10), 0, 0, 0, -5);
		TNT1 AAAAAAAAAAAAAA 15 A_SpawnItemEx("RS_MG_CeilDrip", random(-10,10), random(-10,10), 0, 0, 0, -5);
		TNT1 AAAAAAAAAAAAAA 20 A_SpawnItemEx("RS_MG_CeilDrip", random(-10,10), random(-10,10), 0, 0, 0, -5);
		Stop;
	}
}

class RS_MG_CeilBloodSpawnerSmall : RS_MG_CeilBloodSpawner
{
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 AAAAAAAAAAAAAA 5 A_SpawnItemEx("RS_MG_CeilDrip", random(-5,5), random(-5,5), 0, 0, 0, -5);
		TNT1 AAAAAAAAAAAAAA 10 A_SpawnItemEx("RS_MG_CeilDrip", random(-5,5), random(-5,5), 0, 0, 0, -5);
		TNT1 AAAAAAAAAAAAAA 16 A_SpawnItemEx("RS_MG_CeilDrip", random(-5,5), random(-5,5), 0, 0, 0, -5);
		TNT1 AAAAAAAAAAAAAA 26 A_SpawnItem("RS_MG_CeilDrip");
		Stop;
	}
}

class RS_MG_CeilDrip : RS_MG_Blood
{
	Default
	{
		+THRUACTORS +CLIENTSIDEONLY -FORCEXYBILLBOARD +FORCEYBILLBOARD +TOUCHY
		Gravity 0.6; Radius 2; Height 1;
	}
	override void BeginPlay() { Super.BeginPlay(); Scale = (0.1, 0.2); }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_Jump(230, "NoSpawn");
		TNT1 A 0 A_JumpIf(waterlevel > 1, "Splash");
		BLUD Z 500;
		Stop;
	Death:
		TNT1 A 0;
		TNT1 A 0 A_StartSound("blooddrop2");   // not imported -- inert, see header
		TNT1 A 0 { Scale = (1.0, 1.0); }
		XDT1 EFGHIJKL 2;
		Stop;
	}
}

class RS_MG_CeilDripBig : RS_MG_CeilDrip
{
	Default { Gravity 0.8; }
	override void BeginPlay() { Super.BeginPlay(); Scale = (0.4, 1.0); }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_Jump(160, "NoSpawn");
		TNT1 A 0 A_JumpIf(waterlevel > 1, "Splash");
		BLUD Z 500;
		Stop;
	}
}

// ---------------------------------------------------------------------
// The small blood chunk. XDeath1 in the source.
// ---------------------------------------------------------------------
class RS_MG_Chunk : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 0; Scale 0.6; Mass 1;
		+NOBLOCKMAP +MISSILE +NOTELEPORT +MOVEWITHSECTOR
		+CLIENTSIDEONLY -DONTSPLASH +THRUGHOST +THRUACTORS +FLOORCLIP
	}
	States
	{
	Spawn:
		BLHT ABCDEFGHI 2;
		Stop;
	Death:
		XDT1 EF 3;
		TNT1 A 0 A_SpawnItem("RS_MG_BloodSpot");
		Stop;
	Splash:
	NoSpawn:
		TNT1 A 0;
		Stop;
	}
}

class RS_MG_Chunkb : RS_MG_Chunk
{
	Default { Speed 5; +BOUNCEONWALLS }
	States
	{
	Death:
		XDT1 EF 3;
		TNT1 A 0 A_SpawnItem("RS_MG_BloodSpot2");
		Stop;
	}
}

// Fired upward on death to test for a ceiling and paint it.
class RS_MG_CeilingBloodChecker : RS_MG_Blood
{
	Default { Speed 12; Mass 1; -BOUNCEONCEILINGS }
	States
	{
	Spawn:
		TNT1 A 5;
		Stop;
	Death:
		TNT1 A 0;
		TNT1 A 0 A_CheckCeiling("Ceiling");
		Stop;
	Splash:
	NoSpawn:
		TNT1 A 0;
		Stop;
	Ceiling:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItem("RS_MG_CeilBloodSpawnerSmall");
		TNT1 A 0 A_SpawnItem("RS_MG_CeilBloodSpot");
		Stop;
	}
}

// ---------------------------------------------------------------------
// The flying meat. Sticks to walls and smears, or sticks to ceilings and
// eventually drops. XDeath2 / XDeath3 in the source.
// ---------------------------------------------------------------------
class RS_MG_Meat : RS_MG_Chunk
{
	Default
	{
		+CLIENTSIDEONLY +DONTSPLASH
		Radius 2; Height 2; Gravity 0.4; Scale 1.1; Speed 8;
		DeathSound "misc/xdeath2";
		SeeSound "misc/xdeath4";
	}
	States
	{
	Spawn:
		TNT1 A 0 A_JumpIf(waterlevel > 1, "Splash");
		XMT1 ABCDEFGH 2;
		Loop;
	Death:
		TNT1 A 0 A_CheckFloor("SpawnFloor");
		TNT1 A 0 A_CheckCeiling("SpawnCeiling");
		TNT1 A 0 A_SpawnItem("RS_MG_MeatSmear");
		Stop;
	SpawnFloor:
		XMT1 M 1;
		TNT1 A 0 A_QueueCorpse;
		XMT1 M -1;
		Stop;
	SpawnCeiling:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItemEx("RS_MG_MeatCeil", 0, 0, 8);
		TNT1 A 0 A_SpawnItemEx("RS_MG_CeilBloodSpot", 0, 0, 1);
		Stop;
	Vanish:
		TNT1 A 5;
		Stop;
	}
}

class RS_MG_Meatb : RS_MG_Meat { Default { Speed 4; } }   // low-range

class RS_MG_MeatSmear : Actor
{
	Default
	{
		Radius 1; Height 1; Mass 1; Scale 1.0;
		+NOBLOCKMAP +NOTELEPORT +THRUGHOST +CLIENTSIDEONLY
		+DONTSPLASH +MOVEWITHSECTOR +FORCEXYBILLBOARD +NOGRAVITY
	}
	States
	{
	Spawn:
		XMT1 N 10;
		TNT1 A 0 { vel.z -= 0.125; }   // was ThrustThingZ(0,1,1,1), downwards
		TNT1 A 0 A_Jump(255, "Spawn1", "Spawn2", "Spawn3", "Spawn4");
	Spawn1:
		XMT1 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN 2 A_CheckFloor("Rest");
		Goto Death;
	Spawn2:
		XMT1 NNNNNNNNNNNNNNNNNNNNNNNN 2 A_CheckFloor("Rest");
		Goto Death;
	Spawn3:
		XMT1 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN 2 A_CheckFloor("Rest");
		Goto Death;
	Spawn4:
		XMT1 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN 2 A_CheckFloor("Rest");
		Goto Death;
	Death:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItem("RS_MG_MeatFall");
		Stop;
	Rest:
		XMT1 M 1;
		TNT1 A 0 A_QueueCorpse;
		XMT1 M -1;
		Stop;
	Vanish:
		TNT1 A 5;
		Stop;
	}
}

class RS_MG_MeatCeil : RS_MG_BloodSpot
{
	Default
	{
		Projectile;
		+MISSILE +SPAWNCEILING +MOVEWITHSECTOR +NOGRAVITY
		+DONTSPLASH +CEILINGHUGGER
		RenderStyle "Normal";
		Scale 1.1;
	}
	override void BeginPlay() { Super.BeginPlay(); Scale = (1.1, 1.1); }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_Jump(255, "Live1", "Live2", "Live3");
		Goto Live1;
	Live1:
		XMT1 IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII 5 { vel.z += 2.5; }
		Goto Fall;
	Live2:
		XMT1 IIIIIIIIIIIIIIIIIIIIIII 5 { vel.z += 2.5; }
		Goto Fall;
	Live3:
		XMT1 IIIIIIIIIIIIIIIII 5 { vel.z += 2.5; }
		Goto Fall;
	Fall:
		XMT1 F 0;
		XMT1 JJJKKLL 2;
		TNT1 A 0 A_SpawnItemEx("RS_MG_MeatFall", 0, 0, 0, 0, 0, -1);
		Stop;
	Splash:
		TNT1 A 0;
		Stop;
	}
}

class RS_MG_MeatFall : RS_MG_Meat
{
	Default
	{
		Speed 0; Gravity 0.4; Radius 1; Height 0;
		DeathSound "misc/xdeath2";
		SeeSound "";
	}
	States
	{
	Spawn:
		XMT1 FFFGGH 2;
	Live:
		TNT1 A 0 A_JumpIf(waterlevel > 1, "Splash");
		TNT1 A 0 A_CheckFloor("Death");
		XMT1 ABCDEFGH 2;
		Loop;
	Death:
		XMT1 M 1;
		TNT1 A 0 A_QueueCorpse;
		XMT1 M 3;
		XMT1 M -1;
		Stop;
	}
}

// Second meat variant -- different sprite set, same machinery.
class RS_MG_Meat2 : RS_MG_Meat
{
	States
	{
	Spawn:
		TNT1 A 0 A_JumpIf(waterlevel > 1, "Splash");
		XMT2 ABCDEFGH 2;
		Loop;
	Death:
		TNT1 A 0;
		TNT1 A 0 A_CheckFloor("SpawnFloor");
		TNT1 A 0 A_CheckCeiling("SpawnCeiling");
		TNT1 A 0 A_SpawnItem("RS_MG_Meat2Smear");
		Stop;
	SpawnFloor:
		XMT2 I 1;
		TNT1 A 0 A_QueueCorpse;
		XMT2 I -1;
		Stop;
	SpawnCeiling:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItemEx("RS_MG_Meat2Ceil", 0, 0, 8);
		TNT1 A 0 A_SpawnItemEx("RS_MG_CeilBloodSpot", 0, 0, 1);
		Stop;
	Vanish:
		TNT1 A 5;
		Stop;
	}
}

class RS_MG_Meat2b : RS_MG_Meat2 { Default { Speed 4; } }

class RS_MG_Meat2Smear : RS_MG_MeatSmear
{
	States
	{
	Spawn:
		XME2 G 10;
		TNT1 A 0 { vel.z -= 0.125; }
		TNT1 A 0 A_Jump(255, "Spawn1", "Spawn2", "Spawn3", "Spawn4");
	Spawn1:
		XMT2 OOOOOOOOOOOOOOOO 2 A_CheckFloor("Rest");
		Goto Death;
	Spawn2:
		XMT2 OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO 2 A_CheckFloor("Rest");
		Goto Death;
	Spawn3:
		XMT2 OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO 2 A_CheckFloor("Rest");
		Goto Death;
	Spawn4:
		XMT2 OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO 2 A_CheckFloor("Rest");
		Goto Death;
	Death:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItem("RS_MG_Meat2Fall");
		Stop;
	Rest:
		XMT2 I 1;
		TNT1 A 0 A_QueueCorpse;
		XMT2 I -1;
		Stop;
	}
}

class RS_MG_Meat2Ceil : RS_MG_MeatCeil
{
	States
	{
	Spawn:
	Death:
	Crash:
		TNT1 A 0;
		TNT1 A 0 A_Jump(255, "Live1", "Live2", "Live3");
		Goto Live1;
	Live1:
		XMT2 JJJJJJJJJJJJJJJJJ 4 { vel.z += 2.5; }
		Goto Fall;
	Live2:
		XMT2 JJJJJJJJJJJJJJJJJJJJJJJJJJJ 4 { vel.z += 2.5; }
		Goto Fall;
	Live3:
		XMT2 JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ 4 { vel.z += 2.5; }
		Goto Fall;
	Fall:
		XMT2 JJJJKKKLLM 2;
		TNT1 A 0 A_SpawnItemEx("RS_MG_Meat2Fall", 0, 0, 0, 0, 0, -1);
		XMT2 MMN 2;
		Stop;
	Splash:
		TNT1 A 0;
		Stop;
	}
}

class RS_MG_Meat2Fall : RS_MG_MeatFall
{
	States
	{
	Spawn:
		TNT1 A 0 A_JumpIf(waterlevel > 1, "Splash");
		TNT1 A 0 A_CheckFloor("Death");
		XMT2 O 3;
		Loop;
	Death:
		XMT2 I 1;
		TNT1 A 0 A_QueueCorpse;
		XMT2 I 3;
		XMT2 I -1;
		Stop;
	}
}

// ---------------------------------------------------------------------
// Severed limbs. Tumble in Spawn, land and freeze in Death.
// ---------------------------------------------------------------------
class RS_MG_Arm : RS_MG_Blood
{
	Default
	{
		+BOUNCEONFLOORS +MOVEWITHSECTOR
		BounceCount 2;
		SeeSound "misc/xdeath4";
	}
	States
	{
	Spawn:
		XARM ABCDEFG 3;
		Loop;
	Death:
		XARM H 1;
		TNT1 A 0 A_QueueCorpse;
		XARM H -1;
		Stop;
	}
}

class RS_MG_ZombiemanLeg : RS_MG_Arm
{
	Default { -BOUNCEONFLOORS }
	States
	{
	Spawn:
		LEG1 ABCDEFGH 4;
		Loop;
	Death:
		TNT1 A 0 A_Jump(128, "Death2");
		LEG1 I 1;
		TNT1 A 0 A_QueueCorpse;
		LEG1 I -1;
		Stop;
	Death2:
		LEG1 J 1;
		TNT1 A 0 A_QueueCorpse;
		LEG1 J -1;
		Stop;
	}
}

class RS_MG_ShotgunnerLeg : RS_MG_Arm
{
	Default { -BOUNCEONFLOORS }
	States
	{
	Spawn:
		LEG2 ABCDEFGH 4;
		Loop;
	Death:
		TNT1 A 0 A_Jump(128, "Death2");
		LEG2 I 1;
		TNT1 A 0 A_QueueCorpse;
		LEG2 I -1;
		Stop;
	Death2:
		LEG2 J 1;
		TNT1 A 0 A_QueueCorpse;
		LEG2 J -1;
		Stop;
	}
}

class RS_MG_GibEyeball : RS_MG_Arm
{
	States
	{
	Spawn:
		BRIB EFGH 4;
		Loop;
	Death:
		BRIB E 1;
		TNT1 A 0 A_QueueCorpse;
		BRIB E -1;
		Stop;
	}
}

class RS_MG_GibTeeth : RS_MG_Arm
{
	States
	{
	Spawn:
		BRIB ABCD 4;
		Loop;
	Death:
		BRIB A 1;
		TNT1 A 0 A_QueueCorpse;
		BRIB A -1;
		Stop;
	}
}

class RS_MG_GibHeadPiece : RS_MG_Meat
{
	Default { Scale 0.5; Speed 5; Gravity 0.5; +BOUNCEONCEILINGS +BOUNCEONWALLS }
}

// ---------------------------------------------------------------------
// The bullet every MG hitscanner fires. Source: weapons.txt EnemyBullet,
// a FastProjectile -- so it TRAVELS and can be dodged at range, unlike a
// vanilla A_PosAttack hitscan.
//
// NOTE FOR WIRING: rs_nohitscan_enabled is ON in this repo and converts
// monster hitscans into projectiles already. This monster set never fires
// a hitscan in the first place, so the two do not stack -- but they are
// solving the same problem and only one of them should own it.
// ---------------------------------------------------------------------
class RS_MG_EnemyBullet : FastProjectile
{
	Default
	{
		Radius 3;
		Height 3;
		Speed 90;
		Damage 4;
		Projectile;
		+THRUGHOST
		Scale 0.7;
		Renderstyle "Add";
		Alpha 0.85;
	}
	States
	{
	Spawn:
		XDT1 A 1 Bright;
		Loop;
	Death:
		TNT1 A 0 A_SpawnItem("BulletPuff");
		Stop;
	}
}

// Plasma-death smoke column. Source: specialeffects.txt.
class RS_MG_SmokePillar : Actor
{
	Default
	{
		+NOBLOCKMAP +NOGRAVITY +NOINTERACTION +CLIENTSIDEONLY
		RenderStyle "Translucent";
		Alpha 0.5;
		Scale 1.2;
	}
	States
	{
	Spawn:
		BLHT ABCDEF 6 A_FadeOut(0.03);
		Stop;
	}
}
