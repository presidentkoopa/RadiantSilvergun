// RS_PS_FX -- MeatGrinder set: the imported projectile / effect database.
// =====================================================================
// Everything the MeatGrinder pack shipped as a projectile, casing, puff,
// trail, explosion or particle is extracted here as a standalone actor
// and given a RS_Catalog ID. Nothing from the pack was dropped in favour
// of an existing class -- where an equivalent already existed (a plasma
// ball, a bullet), the MeatGrinder one becomes the NEXT selectable entry
// in its family rather than a discard.
//
// SPRITE RENAMES -- source name -> repo sequence, art copied verbatim:
//   TRAC (8-way rot) -> RSB1   sprites/combatfx/bullets
//   PBLS             -> RSP8   sprites/combatfx/plasma      (ball, in flight)
//   PBLE             -> RSP9   sprites/combatfx/plasma      (ball, impact)
//   BFS1             -> RSPA   sprites/combatfx/plasma      (BFG ball)
//   BFGB             -> RSEA   sprites/combatfx/explosions  (BFG detonation)
//   BFE2             -> RSEB   sprites/combatfx/explosions  (BFG spray)
//   EXPZ             -> RSEC   sprites/combatfx/explosions
//   MISL (8-way rot) -> RSR7   sprites/combatfx/projectiles
//   SMK3             -> RSK3   sprites/combatfx/smoke       (rocket trail)
//   SM7K             -> RSK4   sprites/combatfx/smoke       (blast smoke)
//   SB17             -> RSK5   sprites/combatfx/smoke       (pillar)
//   SPKS             -> RSS3   sprites/combatfx/sparks
//   TRL1             -> RSI7   sprites/combatfx/fire
//   FX58             -> RSU5   sprites/combatfx/puffs
//   C4S3             -> RSC3   sprites/combatfx/casings     (rifle case)
//   C4S2             -> RSC4   sprites/combatfx/casings     (shotgun case)
//
// Damage is NOT authored here. Every projectile takes its numbers from
// the firing weapon's rolled stats via SetupStats(), exactly like
// RS_GH_PlasmaShot -- so one entry serves a Basic and a Prototype gun.
// =====================================================================

// ---------------------------------------------------------------------
// BULLET -- the second selectable ballistic visual.
// Source: MeatGrinder's `Bullet` (sprite TRAC). Genuinely different from
// RS_BallisticType1, not a reskin: TRAC is an 8-WAY ROTATION SET of a
// single frame, so the round stays correctly oriented as the player
// strafes around it, where RSB0 cycles 5 shapes regardless of angle.
// ---------------------------------------------------------------------
class RS_BallisticType2 : RS_BallisticFired
{
	States
	{
	Spawn:
		RSB1 A 2 Bright;
		Loop;
	}
}

// ---------------------------------------------------------------------
// PLASMA -- source: PlasmaBall44 / PlasmaBallNew2.
// The source randomised scale sign on death to mirror the impact sprite
// four ways (A_SetScale with negative X). That behaviour is kept: it is
// what stops a burst of plasma impacts looking rubber-stamped.
// ---------------------------------------------------------------------
class RS_PS_PlasmaShot : PlasmaBall
{
	Default
	{
		RenderStyle "Add";
		Alpha 0.75;
		Scale 0.8;
		DamageType "Plasma";
		SeeSound "";
		DeathSound "";
		+FORCEXYBILLBOARD
		+EXTREMEDEATH
	}

	void SetupStats(int finalDamage, double critChance)
	{
		SetDamage(finalDamage);
	}

	States
	{
	Spawn:
		RSP8 AB 1 Bright;
		Loop;
	Death:
		// Source's four-way mirror roll, preserved.
		TNT1 A 0 A_Jump(192, "Burst1", "Burst2", "Burst3", "Burst4");
		TNT1 A 0 A_SetScale(1.0, -1.0);
		Goto Burst;
	Burst1:
		TNT1 A 0 A_SetScale(0.8, 0.8);
		Goto Burst;
	Burst2:
		TNT1 A 0 A_SetScale(-0.8, 0.8);
		Goto Burst;
	Burst3:
		TNT1 A 0 A_SetScale(-1.2, -1.2);
		Goto Burst;
	Burst4:
		TNT1 A 0 A_SetScale(-0.7, 0.7);
		Goto Burst;
	Burst:
		TNT1 AAAA 0 A_CustomMissile("RS_PS_PlasmaParticle", 0, 0, random(0, 360), 2, random(0, 360));
		RSP9 ABCD 1 Bright;
		Stop;
	}
}

// Ejected spark thrown off a plasma impact. Source: PlasmaParticle.
class RS_PS_PlasmaParticle : Actor
{
	Default
	{
		+MISSILE +THRUACTORS +CLIENTSIDEONLY +NOGRAVITY
		+BOUNCEONWALLS +BOUNCEONCEILINGS +FORCEXYBILLBOARD
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.5;
		Radius 1;
		Height 1;
		Speed 15;
	}
	States
	{
	Spawn:
		RSP9 E 1 Bright;
		RSP9 E 2 Bright;
		RSP9 EE 1 Bright A_FadeOut(0.25);
		Stop;
	}
}

// ---------------------------------------------------------------------
// BFG -- source: BFGBall2 / BFGExtra2.
// ---------------------------------------------------------------------
class RS_PS_BFGShot : Actor
{
	Default
	{
		Radius 13;
		Height 8;
		Speed 50;
		Scale 0.5;
		Projectile;
		+RANDOMIZE
		+EXTREMEDEATH
		+FORCEXYBILLBOARD
		DeathSound "weapons/bfgx";
		Obituary "$OB_MPBFG_BOOM";
	}

	void SetupStats(int finalDamage, double critChance)
	{
		SetDamage(finalDamage);
	}

	States
	{
	Spawn:
		RSPA AB 2 Bright;
		Loop;
	Death:
		RSEA A 0 A_SetScale(1.0, 1.0);
		RSEA ABCDE 2 Bright;
		RSEA F 2 Bright A_BFGSpray("RS_PS_BFGExtra");
		RSEA G 2 Bright;
		Stop;
	}
}

class RS_PS_BFGExtra : Actor
{
	Default
	{
		+NOBLOCKMAP +NOGRAVITY +EXTREMEDEATH +FORCEXYBILLBOARD
		RenderStyle "Add";
		Alpha 0.75;
		DamageType "BFGSplash";
	}
	States
	{
	Spawn:
		RSEB ABCD 4 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// ROCKET -- source: NewRocket / Rocket2. MISL is an 8-way rotation set,
// so the rocket body stays oriented in flight.
// ---------------------------------------------------------------------
class RS_PS_Rocket : Actor
{
	Default
	{
		Radius 2;
		Height 2;
		Speed 60;
		Scale 0.5;
		Projectile;
		+RANDOMIZE
		+EXTREMEDEATH
		+BLOODSPLATTER
		SeeSound "weapons/rocklf";
		Obituary "$OB_MPROCKET";
		Decal "ScorchSmall";
	}

	void SetupStats(int finalDamage, double critChance)
	{
		SetDamage(finalDamage);
	}

	States
	{
	Spawn:
		RSR7 A 1 Bright A_SpawnItem("RS_PS_RocketTrail");
		Loop;
	Death:
		TNT1 A 0 A_Explode();
		TNT1 A 0 A_SpawnItem("RS_PS_Explosion");
		TNT1 A 6;
		Stop;
	}
}

// ---------------------------------------------------------------------
// EXPLOSION ASSEMBLY -- source: Explosion / ExplosionFire /
// ExplosionShrapnel / ExplSmokeParticle.
// Kept as separate actors rather than folded into one, because that is
// what makes them individually referenceable: a future affix can take
// the shrapnel without the smoke.
// ---------------------------------------------------------------------
class RS_PS_ExplosionFire : Actor
{
	Default
	{
		+MISSILE +THRUACTORS +CLIENTSIDEONLY +NOGRAVITY
		+BOUNCEONWALLS +BOUNCEONCEILINGS +FORCEXYBILLBOARD
		Radius 1;
		Height 1;
		Speed 4;
	}
	States
	{
	Spawn:
		RSEC ABC 2 Bright;
		RSEC DEFG 1 Bright;
		Stop;
	}
}

class RS_PS_ExplosionFireSmall : RS_PS_ExplosionFire
{
	Default { Scale 0.3; Speed 0; }
}

class RS_PS_Shrapnel : RS_PS_ExplosionFire
{
	Default { Speed 0; RenderStyle "Add"; }
	States
	{
	Spawn:
		RSS3 ABCDEFG 1 Bright;
		Stop;
	}
}

class RS_PS_ShrapnelSmall : RS_PS_Shrapnel
{
	Default { Scale 0.3; }
}

class RS_PS_BlastSmoke : RS_PS_ExplosionFire
{
	Default { Speed 1; Scale 1.6; }
	States
	{
	Spawn:
		RSK4 ABCDEFGHIJKLMNOPQRSTUVWXYZ 2;
		Stop;
	}
}

class RS_PS_BlastSmokeSmall : RS_PS_ExplosionFire
{
	Default { Speed 0; Scale 1.0; }
	States
	{
	Spawn:
		RSK4 ABCDEFGHIJKLMNOPQRSTUVWXYZ 1;
		Stop;
	}
}

class RS_PS_BlastSmokeTiny : RS_PS_ExplosionFire
{
	Default
	{
		Speed 0; Scale 0.5; VSpeed 1;
		RenderStyle "Translucent"; Alpha 0.7;
	}
	States
	{
	Spawn:
		RSK4 ABCDEFGHIJKLMNOPQRSTUVWXYZ 1;
		Stop;
	}
}

class RS_PS_RocketTrail : RS_PS_ExplosionFire
{
	Default { Speed 0; Scale 0.2; }
	States
	{
	Spawn:
		TNT1 A 2;
		RSK3 ABCDEFGHIJKL 1;
		Stop;
	}
}

// The composite blast the source's rocket spawned on death. A_Explode is
// deliberately NOT here -- damage stays on the projectile, this is the
// cosmetic half only, so an affix can swap the look without touching the
// splash.
class RS_PS_Explosion : Actor
{
	Default { +CLIENTSIDEONLY +NOBLOCKMAP +NOGRAVITY }
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("weapons/rocklx", CHAN_AUTO);
		TNT1 AAAA 0 A_CustomMissile("RS_PS_ExplosionFire", 0, 0, random(0, 360), 2, random(-90, 90));
		TNT1 A 0 A_CustomMissile("RS_PS_Shrapnel", 0, 0, random(0, 360), 2, random(0, 90));
		TNT1 A 0 A_QuakeEx(2, 2, 2, 6, 0, 100, "");
		TNT1 A 3;
		TNT1 A 0 A_CustomMissile("RS_PS_BlastSmoke", 0, 0, random(0, 360), 2, random(0, 90));
		TNT1 A 6;
		Stop;
	}
}

// ---------------------------------------------------------------------
// PUFFS -- source: HitPuff / SawPuff. The source's 50/50 horizontal
// mirror is kept for the same reason as the plasma burst above.
// ---------------------------------------------------------------------
class RS_PS_HitPuff : Actor
{
	Default
	{
		+NOBLOCKMAP +NOGRAVITY +RANDOMIZE +FORCEXYBILLBOARD
		-ALLOWPARTICLES
		RenderStyle "Add";
		Alpha 1.0;
		Mass 5;
		Scale 0.5;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("ricochet/hit", CHAN_AUTO);
		TNT1 A 0 A_SpawnItem("RS_PS_BlastSmokeTiny");
		TNT1 A 0 A_Jump(128, "Live");
		TNT1 A 0 A_SetScale(-0.4, 0.4);
	Live:
		RSU5 ABCDEFGHIJ 1 Bright;
		Stop;
	}
}

class RS_PS_SawPuff : RS_PS_HitPuff
{
	Default
	{
		+EXTREMEDEATH
		DamageType "Saw";
	}
	States
	{
	Spawn:
		TNT1 A 0 A_Jump(128, "Live");
		TNT1 A 0 A_SetScale(-0.4, 0.4);
	Live:
		RSU5 ABCDEFGHIJ 1 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// TRAILS / SCENERY -- source: FireTrails1 / SmokePillar.
// ---------------------------------------------------------------------
class RS_PS_FireTrail : RS_PS_ExplosionFire
{
	Default { Speed 0; Scale 0.5; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 1;
		TNT1 A 0 A_Jump(192, "Roll1", "Roll2", "Roll3", "Roll4");
		Goto Live;
	Roll1:
		TNT1 A 0 A_SetScale(0.6, 0.6);
		Goto Live;
	Roll2:
		TNT1 A 0 A_SetScale(0.4, 0.4);
		Goto Live;
	Roll3:
		TNT1 A 0 A_SetScale(-0.6, 0.6);
		Goto Live;
	Roll4:
		TNT1 A 0 A_SetScale(-0.4, 0.4);
		Goto Live;
	Live:
		RSI7 ABC 1 Bright;
		RSI7 DE 1;
		Stop;
	}
}

class RS_PS_SmokePillar : Actor
{
	Default
	{
		+CLIENTSIDEONLY +THRUACTORS +MOVEWITHSECTOR +NOBLOCKMAP +NOGRAVITY
		RenderStyle "Add";
		Scale 1.0;
	}
	States
	{
	Spawn:
		RSK5 AABBCCDDEEFFGGHH 1 A_SetScale(Scale.X, Scale.Y + 0.03);
		RSK5 ABCDEFGHABCDEFGHABCDEFGHABCDEFGH 3;
		RSK5 ABCDEFGHABCDEFGHABCDEFGHABCDEFGH 3;
		RSK5 AABBCCDDEEFFGGHH 1 A_SetScale(Scale.X, Scale.Y - 0.03);
		Stop;
	}
}

// ---------------------------------------------------------------------
// CASINGS -- source: EmptyCase / ShotgunCase. Both settle into one of
// several resting frames, which is the source's own touch and the reason
// a floor littered with MeatGrinder brass doesn't look tiled.
// ---------------------------------------------------------------------
class RS_PS_CasingRifle : Actor
{
	Default
	{
		Height 2;
		Radius 2;
		Speed 8;
		Scale 0.1;
		Mass 0;
		BounceFactor 0.3;
		+WINDTHRUST +CLIENTSIDEONLY +MOVEWITHSECTOR
		BounceType "Doom";   // was +DOOMBOUNCE, deprecated 4.13.0
		+MISSILE +NOBLOCKMAP +NOTELEPORT +FORCEXYBILLBOARD
		+NOTDMATCH +GHOST +FLOORCLIP +THRUACTORS
		-CANBOUNCEWATER
		-NOGRAVITY
		-DROPOFF
		DeathSound "weapons/casing";
		BounceSound "weapons/casing";
	}
	States
	{
	Spawn:
		TNT1 A 0 A_JumpIf(waterlevel > 1, "Splash");
		RSC3 FFGGHHAABBCCDDEEFFGGHHAABBCCDDEEFFGGHH 1;
		RSC3 FFGGHHAABBCCDDEEFFGGHHAABBCCDDEEFFGGHH 1;
		Stop;
	Death:
		TNT1 A 0 A_Jump(256, "Rest1", "Rest2", "Rest3", "Rest4", "Rest5");
		Goto Rest1;
	Rest1:
		RSC3 I 100;
		Stop;
	Rest2:
		RSC3 J 100;
		Stop;
	Rest3:
		RSC3 K 100;
		Stop;
	Rest4:
		RSC3 L 100;
		Stop;
	Rest5:
		RSC3 M 100;
		Stop;
	Splash:
		TNT1 A 0;
		Stop;
	}
}

class RS_PS_CasingShell : RS_PS_CasingRifle
{
	Default
	{
		Speed 7;
		Scale 0.15;
		Mass 2;
		DeathSound "weapons/shell";
		BounceSound "weapons/shell";
	}
	States
	{
	Spawn:
		RSC4 AABBCCDDEEFFGGHHAABBCCDDEEFFGGHH 1;
		Stop;
	Death:
		TNT1 A 0 A_Jump(256, "Rest1", "Rest2", "Rest3", "Rest4", "Rest5");
		Goto Rest1;
	Rest1:
		RSC4 I 100;
		Stop;
	Rest2:
		RSC4 J 100;
		Stop;
	Rest3:
		RSC4 K 100;
		Stop;
	Rest4:
		RSC4 L 100;
		Stop;
	Rest5:
		RSC4 M 100;
		Stop;
	}
}
