// =====================================================================
// RS_human_projectiles.zs
// ---------------------------------------------------------------------
// Monster attack components, extracted per docs/catalog_notes.txt: every
// projectile is a standalone catalogued entry with its own visual
// identity, audio, movement and damage properties, so monster attacks
// can be recombined the same way weapon attacks are, rather than each
// monster owning a hardcoded projectile.
//
// Converted from the earlier port's library and RS_-prefixed. Sprite
// references verified against ART SOURCE / IWAD -- see the import notes
// at the bottom of this file for anything that was corrected.
// =====================================================================

// ============================================================================
// hf_human_projectiles.zs -- Zombieman / Shotgunner / Chaingunner projectiles.
// The humans are hitscan grunts; colors add a projectile twist. Reuses pool:
// RS_FireSGguy2, RS_ZombieRock, RS_PurpFire2, RS_SplashAbyss2, RS_HKRedDeath,
// RS_PlasmaBallSP3, RS_FireBCGguy (already built). New below. Damage->constants.
// ============================================================================

// ---------- ZOMBIEMAN color projectiles ----------
class RS_Gas11 : Actor
{
	Default { Radius 6; Height 8; Speed 12; Damage 8; DamageType "Poison"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.7; Scale 0.8;
		SeeSound "grenade/fuse"; DeathSound "weapons/grenade"; Translation "0:255=%[0.20,0.40,0.00]:[0.70,1.20,0.20]"; }
	States { Spawn: PSBG ABCD 4 Bright; Loop; Death: PSBG EFG 4 Bright A_Explode(8,48); Stop; }
}
class RS_IceZombieShot : Actor
{
	Default { Radius 6; Height 8; Speed 33; Damage 11; DamageType "Ice"; Projectile; RenderStyle "Add"; Alpha 0.9; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY CDE 4 Bright A_Explode(11,40); Stop; }
}
class RS_IceZombieShot2 : RS_IceZombieShot { Default { Speed 28; Damage 9; } }
class RS_Orbb11 : Actor
{
	Default { Radius 6; Height 8; Speed 21; Damage 10; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.9; Scale 0.7;
		SeeSound "imp/attack"; DeathSound "imp/shotx"; Translation "0:255=%[0.40,0.00,0.60]:[1.30,0.30,1.70]"; }
	States { Spawn: BAL1 AB 3 Bright A_SeekerMissile(2,2); Loop; Death: BAL1 CDE 4 Bright A_Explode(10,40); Stop; }
}
class RS_MiniRKTZombie : Actor
{
	Default { Radius 6; Height 8; Speed 22; Damage 22; DamageType "Fire"; Projectile; +RANDOMIZE; +ROCKETTRAIL; Scale 0.6; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States { Spawn: MISL A 3 Bright; Loop; Death: MISL BCD 4 Bright A_Explode(40,80); Stop; }
}
class RS_AbyssZshotCH : Actor
{
	Default { Radius 6; Height 8; Speed 32; Damage 17; DamageType "Ice"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; Translation "Ice"; SeeSound "imp/attack"; DeathSound "imp/shotx"; }
	States { Spawn: BAL7 AB 3 Bright; Loop; Death: BAL7 CDE 4 Bright A_Explode(17,48); Stop; }
}
class RS_AbyssZshotCH2 : RS_AbyssZshotCH { Default { Speed 45; } }
class RS_AbyssZShotCH3 : RS_AbyssZshotCH { Default { Speed 60; Damage 22; } }

// ---------- SHOTGUNNER color projectiles ----------
class RS_FireSGguy : Actor
{
	Default { Radius 4; Height 4; Speed 21; Damage 10; DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States { Spawn: FIRE AB 3 Bright; Loop; Death: FIRE CDE 3 Bright; Stop; }
}
class RS_SGshot1 : Actor
{
	Default { Radius 4; Height 4; Speed 55; Damage 4; DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85; Scale 0.6; SeeSound "weapons/shotgf"; DeathSound "weapons/plasmax"; }
	States { Spawn: BAL1 AB 2 Bright; Loop; Death: BAL1 CD 3 Bright; Stop; }
}
class RS_SGLance1 : Actor
{
	Default { Radius 6; Height 8; Speed 20; Damage 35; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.9; SeeSound "weapons/plasmaf"; DeathSound "weapons/plasmax"; }
	States { Spawn: PLSE AB 3 Bright A_SeekerMissile(2,2); Loop; Death: PLSS CDE 4 Bright A_Explode(35,64); Stop; }
}
class RS_RedMessImp3 : Actor
{
	Default { Radius 6; Height 8; Speed 26; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "0:255=%[0.60,0.00,0.00]:[2.00,0.30,0.30]"; }
	States { Spawn: BAL1 AB 3 Bright; Loop; Death: BAL1 CDE 4 Bright A_Explode(30,48); Stop; }
}
class RS_SGGasNade : Actor
{
	Default { Radius 6; Height 8; Speed 25; Damage 40; DamageType "Poison"; Projectile; +GRENADETRAIL; -NOGRAVITY; Gravity 0.4; BounceType "Doom"; BounceCount 2;
		SeeSound "weapons/grenade"; DeathSound "weapons/grenade"; }
	States { Spawn: MISL A 4 Bright; Loop; Death: GRND ABCD 4 Bright A_Explode(60,96); Stop; }
}
class RS_MineShotgun : Actor
{
	Default { Radius 6; Height 8; Speed 20; Damage 30; DamageType "Fire"; Projectile; +BOUNCEONWALLS; +THRUGHOST; BounceType "Doom"; BounceCount 3; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States { Spawn: MISL A 4 Bright; Loop; Death: SHOT ABCD 4 Bright A_Explode(50,96); Stop; }
}

// ---------- CHAINGUNNER color projectiles ----------
class RS_BlueChainPuff3 : Actor
{
	Default { Radius 4; Height 4; Speed 1; Damage 0; +NOGRAVITY +NOINTERACTION; RenderStyle "Add"; Alpha 0.7; Scale 0.6; }
	States { Spawn: SSBL ABCD 2 Bright; Stop; }
}
class RS_BrownOrbCguy : Actor
{
	Default { Radius 3; Height 3; Speed 32; Damage 9; DamageType "Fire"; Projectile; +THRUGHOST; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; Scale 0.5;
		SeeSound "imp/attack"; DeathSound "imp/shotx"; Translation "0:255=%[0.31,0.23,0.18]:[1.10,0.74,0.40]"; }
	States { Spawn: BAL1 AB 2 Bright; Loop; Death: RIP1 ABC 3 Bright A_Explode(9,40); Stop; }
}
class RS_CGBigOne : Actor
{
	Default { Radius 8; Height 8; Speed 19; Damage 50; DamageType "Plasma"; Projectile; +NOGRAVITY; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.9; Scale 1.2;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx"; }
	States { Spawn: SPIR FGH 3 Bright A_SeekerMissile(3,3); Loop; Death: RED9 ABCDE 4 Bright A_Explode(80,96); Stop; }
}
class RS_GenShield : Actor
{
	// orbiting shield bubble (cosmetic-ish, low damage)
	Default { Radius 8; Height 8; Speed 1; Damage 0; Projectile; +RANDOMIZE; +NOGRAVITY +THRUACTORS; RenderStyle "Add"; Alpha 0.4; Scale 1.2; }
	States { Spawn: BFE1 ABCD 4 Bright; Loop; Death: BFS1 CDE 3 Bright; Stop; }
}
class RS_NeedlesCg1 : Actor
{
	Default { Radius 2; Height 2; Speed 35; Damage 12; DamageType "Melee"; Projectile; +SPAWNSOUNDSOURCE; +BLOODSPLATTER; +RANDOMIZE; YScale 0.6; XScale 1.4;
		SeeSound "Jam/Jamd"; DeathSound "gas/gas1"; }
	States { Spawn: 6PUF AB 2 Bright; Loop; Death: BLAD ABC 3 Bright; Stop; }
}
class RS_NeedlesCg2 : RS_NeedlesCg1 { Default { Damage 8; DamageType "Poison"; PoisonDamage 6; } }
class RS_Puddle1 : Actor
{
	Default { Radius 8; Height 4; Speed 0; Damage 4; DamageType "Poison"; Projectile; +NOCLIP +FLOORHUGGER; RenderStyle "Translucent"; Alpha 0.5; Scale 0.8;
		DeathSound "gas/gas1"; Translation "0:255=%[0.20,0.40,0.00]:[0.70,1.20,0.20]"; }
	States { Spawn: BOGY ABCD 6; BOGY ABCD 6 A_FadeOut(0.1); Stop; }
}


// =====================================================================
// REBUILD ADDITIONS (rs_09 per-tier state port). These are CH attacks
// the earlier HF port never imported; ported from CH decorate
// (Zombies.txt / Shotgunners.txt / Chaingunners.txt) per the spec's
// "no RS_ port -> add it here" rule. Damage -> constants, house style.
// =====================================================================

// ---------- UNDERTAKER (white zombieman) bone kit ----------
// BBBN / RNGG sprites copied from ART SOURCE (CH sprites/theride, fx)
// into sprites/monsters/projectiles/.
class RS_BoneProjZM : Actor
{
	Default { Radius 8; Height 8; Speed 32; Damage 10; Projectile; +BLOODLESSIMPACT; +SKYEXPLODE; +FORCEPAIN; Scale 0.75;
		SeeSound "skeleton/attack"; DeathSound "skeleton/melee"; Translation "0:255=[129,129,129]:[255,255,255]"; }
	States
	{
	Spawn:
		BBBN ABCD 4;
		Loop;
	Death:
		MISL B 0 A_SetScale(0.3);
		MISL BCD 3;
		Stop;
	}
}
class RS_BoneProjZM2 : RS_BoneProjZM { Default { Speed 36; Damage 14; } }
class RS_BoneProjZM3 : RS_BoneProjZM { Default { Speed 40; Damage 19; } }

// The shovel: a big blade fan. CH ShoveZM sprays ShoveZM2/3 side
// blades both forward and backward; kept, at reduced count.
class RS_ShoveZM2 : Actor
{
	Default { Radius 6; Height 8; Speed 25; Damage 3; DamageType "Melee"; Alpha 0.75; Scale 1.8; Decal "BulletChip";
		Projectile; +SPAWNSOUNDSOURCE; +EXTREMEDEATH; +BLOODSPLATTER; DeathSound ""; }
	States
	{
	Spawn:
		BLAD AAAA 3 Bright;
	Death:
		BLAD AA 1 Bright A_FadeOut(0.15);
		BLAD AAAA 1 Bright A_FadeOut(0.15);
		Stop;
	}
}
class RS_ShoveZM3 : RS_ShoveZM2 { Default { Speed 27; Damage 7; Scale 1.55; } }
class RS_ShoveZM : Actor
{
	Default { Radius 6; Height 8; Speed 25; Damage 20; DamageType "Melee"; Scale 2.0; Decal "BulletChip";
		Projectile; +SPAWNSOUNDSOURCE; +EXTREMEDEATH; +BLOODSPLATTER;
		AttackSound "skeleton/swing"; DeathSound "moloch/nailhitbleed"; }
	States
	{
	Spawn:
		BLAD AA 2 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
		BLAD AAA 0 A_SpawnProjectile("RS_ShoveZM3", 0, 0);
		BLAD A 2 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
		BLAD A 3 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
		BLAD AA 0 A_SpawnProjectile("RS_ShoveZM3", 0, 3, -180);
		BLAD AA 0 A_SpawnProjectile("RS_ShoveZM3", 0, -3, -180);
		BLAD A 3 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
	Death:
		BLAD A 1 Bright;
		6PUF ABCDEF 1 Bright;
		TNT1 A 0 A_Explode(12, 64);
		Stop;
	}
}

// Orbiting bone satellite for the tornado. One class with a
// randomized orbit replaces CH's seven near-identical BoneStormer1-7.
class RS_BoneStormer : Actor
{
	double OrbR;
	double OrbH;
	double OrbA;
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		OrbR = frandom(12, 80);
		OrbH = frandom(10, 128);
		OrbA = frandom(0, 359);
	}
	Default { Radius 8; Height 8; Speed 120; Damage 2; Projectile; +BLOODLESSIMPACT; +RIPPER; +FORCEPAIN; Scale 0.75;
		Translation "0:255=[129,129,129]:[255,255,255]"; DeathSound "skeleton/melee"; }
	States
	{
	Spawn:
		BBBN A 1 Bright NoDelay
		{
			A_Warp(AAPTR_MASTER, OrbR, 0, OrbH, OrbA,
			       WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE);
			OrbA += 8;
		}
		TNT1 A 0 A_Jump(6, "Death");
		Loop;
	Death:
		MISL B 0 A_SetScale(0.3);
		MISL BCD 3;
		Stop;
	}
}

// The wandering bone tornado (RNGG). Floorhugging bouncer that drags
// an orbiting bone storm with it and spits bones as it goes.
class RS_BoneTorn2 : Actor
{
	Default { Radius 6; Height 8; Speed 18; Mass 25; Projectile; +FLOORHUGGER; +THRUACTORS; +DONTBLAST; +DONTTHRUST;
		+BOUNCEONWALLS; BounceType "Doom"; BounceCount 999; BounceFactor 1; WallBounceFactor 1.1;
		RenderStyle "Add"; Alpha 0.75; SeeSound "skeleton/attack"; }
	States
	{
	Spawn:
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer", 0, 0, 4, 0, 0, 0, 0, SXF_SETMASTER | SXF_ORIGINATOR);
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer", 0, 0, 4, 0, 0, 0, 0, SXF_SETMASTER | SXF_ORIGINATOR);
		RNGG CCDD 1 Bright A_SpawnProjectile("RS_BoneProjZM3", 4, random(-20, 20), random(0, 359), CMF_AIMDIRECTION | CMF_OFFSETPITCH, random(-20, 5));
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer", 0, 0, 4, 0, 0, 0, 0, SXF_SETMASTER | SXF_ORIGINATOR);
		RNGG CCDD 1 Bright A_SpawnProjectile("RS_BoneProjZM3", 4, random(-20, 20), random(0, 359), CMF_AIMDIRECTION | CMF_OFFSETPITCH, random(-20, 5));
		RNGG D 0 A_Jump(8, "Death");
		Loop;
	Death:
		RNGG ABCD 4 Bright;
		Stop;
	}
}

// ---------- SHOTGUNNER rebuild additions ----------
// Brown SG mud pellet: fast, near-invisible, knocks the target around.
class RS_BrownSGshot : Actor
{
	Default { Radius 2; Height 2; Speed 64; Damage 3; Projectile; +DONTBLAST; +DONTTHRUST; RenderStyle "Add"; Alpha 0.85;
		DeathSound "imp/shotx"; }
	States
	{
	Spawn:
		TNT1 A 5 Bright;
		Goto Death;
	Death:
		TNT1 A 0 A_Stop;
		PUFF C 6 Bright;
		TNT1 A 0 A_Blast(BF_NOIMPACTDAMAGE, 128, 32, 20.0);
		PUFF DE 6 Bright;
		Stop;
	}
}
// Gray SG sniper laser-dot puff (the telegraph).
class RS_RedDotSGPuff : BulletPuff
{
	Default { +NOBLOOD; +PAINLESS; +ALWAYSPUFF; Translation "0:255=175:191"; Scale 0.5; }
	States
	{
	Spawn:
		TNT1 A 0;
	Melee:
	Death:
		PUFF A 6 Bright;
		Stop;
	}
}

// ---------- CHAINGUNNER rebuild additions ----------
// Gray chaingunner's exploding tracer puff.
class RS_GrayCGuff : Actor
{
	Default { Projectile; +NOGRAVITY; +ALLOWPARTICLES; +PUFFONACTORS; +ALWAYSPUFF; RenderStyle "Add"; Alpha 0.85; Scale 0.25;
		Mass 5; DamageType "Fire"; DeathSound "imp/shotx"; }
	States
	{
	Spawn:
		MISL BC 2 Bright;
	Melee:
	Death:
		MISL D 4 Bright A_Explode(6, 64);
		MISL E 4 Bright;
		Stop;
	}
}
// Red chaingunner's detonating puffs, three range grades.
class RS_DetoPuffCG : Actor
{
	Default { Projectile; +NOGRAVITY; +ALLOWPARTICLES; +RANDOMIZE; +PUFFONACTORS; +ALWAYSPUFF; RenderStyle "Add"; Alpha 0.85; Scale 0.35;
		Mass 5; DamageType "Fire"; DeathSound "imp/shotx"; }
	States
	{
	Spawn:
		MISL BC 4 Bright;
	Melee:
	Death:
		MISL D 4 Bright A_Explode(4, 42);
		MISL E 4 Bright;
		Stop;
	}
}
class RS_DetoPuff2 : RS_DetoPuffCG { Default { Scale 0.30; } }
class RS_DetoPuff3 : RS_DetoPuffCG { Default { Scale 0.25; } }
// The General's seeking plasma bombs (BFS1/BFE1 are IWAD BFG sprites).
class RS_SpamShotsCguy : Actor
{
	Default { Radius 14; Height 9; Speed 25; Damage 25; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.75; Scale 0.55; SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx"; }
	States
	{
	Spawn:
		BFS1 AB 2 Bright A_SeekerMissile(2, 3);
		Loop;
	Death:
		BFE1 AB 8 Bright A_SetScale(1.15);
		BFE1 C 8 Bright A_Explode(25, 128);
		BFE1 DEF 8 Bright;
		Stop;
	}
}

// =====================================================================
// CHP 02 (SHOTGUNNER) REBUILD ADDITIONS
// ---------------------------------------------------------------------
// Ported for the RS_Shotgunner per-tier rebuild. Source of truth is
// CHP/DECORATE/02/02_<code>.txt; where a CHP actor only overrides a
// couple of properties on a CH parent, the CH parent supplied the rest
// and CHP's values were applied on top (CHP always wins).
// =====================================================================

// T03 cyan pellet puff. CHP CyanSGPuff_C is an empty-bodied BulletPuff
// subclass with an ice hit sound -- the frost read is the sound plus the
// particle burst, there is no sprite of its own.
class RS_CyanSGPuff : BulletPuff
{
	Default { +ALWAYSPUFF; +PUFFONACTORS; DeathSound "ice/hit2"; }
	States
	{
	Spawn:
		TNT1 A 1;
	Melee:
	Death:
		TNT1 A 0 { A_Scream(); }
		Stop;
	}
}

// T11 black commander kit ------------------------------------------------
// Smoke motes the detonating puffs and airstrike missiles burst into.
class RS_PufFCHBS : Actor
{
	Default { Radius 1; Height 1; Speed 8; Damage 1; Projectile; +NOCLIP; +NOGRAVITY;
		RenderStyle "Add"; Alpha 0.75; }
	States { Spawn: SMK2 ABCDE 2; Stop; }
}

// The sniped mark: a detonating puff planted on the target by A_VileTarget.
class RS_DetoPuffCG2 : Actor
{
	Default { Radius 2; Height 1; Mass 1; Projectile; RenderStyle "Add"; Alpha 1.0; Scale 0.55;
		DamageType "Fire"; SeeSound "weapons/firex4"; }
	States
	{
	Spawn:
		MISL BC 1 Bright;
		Goto Death;
	Death:
		MISL D 4 Bright { A_Explode(random(12, 36), 42); }
		MISL E 4 Bright { A_Burst("RS_PufFCHBS"); }
		Stop;
	}
}

// The bomblets the airstrike rains down while it flies overhead.
class RS_MissileCHBS : Actor
{
	Default { Radius 11; Height 8; Speed 10; Damage 30; DamageType "Fire"; Projectile; -NOGRAVITY;
		Gravity 1.5; Scale 0.7; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		MSLH A 2 Bright;
		Loop;
	Death:
		MISL B 0 { A_SetTranslucent(0.8, 1); }
		MISL B 4 Bright { A_Explode(random(5, 40), 98); }
		MISL C 5 Bright;
		MISL D 6 Bright { A_Burst("RS_PufFCHBS"); }
		Stop;
	}
}

// The airstrike itself: hugs the ceiling toward the marked spot, seeding
// bomblets the whole way, then detonates twice on impact.
class RS_AirStrikeCHBS : Actor
{
	Default { Radius 6; Height 8; Speed 28; Mass 50; Damage 22; DamageType "Fire"; Projectile;
		+CEILINGHUGGER; +FLOAT; +NOGRAVITY; RenderStyle "Add"; Gravity 7; Alpha 0.35; Scale 0.5;
		SeeSound "caco/attack"; DeathSound "fire/fire5"; }
	States
	{
	Spawn:
		HEAD DD 2 Bright { A_SpawnItemEx("RS_MissileCHBS", random(-80, 80), random(-80, 80), -32, random(-10, 13), random(-10, 25), 1, 0, SXF_NOCHECKPOSITION); }
		HEAD DD 3 Bright { A_SpawnItemEx("RS_MissileCHBS", random(-200, 200), random(-200, 200), -32, random(-10, 13), random(-10, 25), 1, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		BBOM A 2 Bright { A_SetScale(1); }
		BBOM B 2 { A_SetTranslucent(0.65); }
		BBOM CD 3 Bright { A_Explode(random(10, 40), 108); }
		BBOM EFG 6 Bright { A_Explode(random(10, 45), 108); }
		Stop;
	}
}

// T12 Benellus' punisher ------------------------------------------------
// A_VileTarget plants the invisible carrier on the victim; it immediately
// hangs a shotgun on either flank, each of which cocks, fires once, and
// blows itself up.
class RS_ShotgunPunishNerf : Actor
{
	Default { Radius 12; Height 12; Speed 1; Health 300; RenderStyle "SoulTrans"; Alpha 0.95;
		Monster; +NOTRIGGER; +NOCLIP; +NOBLOOD; -COUNTKILL;
		SeeSound "weapons/sshotl"; DeathSound "weapons/rockx"; }
	States
	{
	Spawn:
		SHOT A 6 Bright { A_SetScale(0.8, 0.3); }
		SHOT A 6 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 6 Bright { A_SetScale(1.6, 0.9); }
		SHOT A 6 Bright { A_SetScale(1.2, 1.1); }
		SHOT A 6 Bright { A_SetScale(1.0, 1.0); }
		SHOT A 6 Bright { A_SetScale(1.3, 0.6); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 18 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(1, 7), random(1, 5), "BulletPuff", 0); }
		SHOT A 4 Bright { A_SetScale(1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(0.1, 0.1); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The mirrored twin. CH gives it negative X scale so the two read as a
// pair closing in from both sides.
class RS_ShotgunPunishNerf2 : RS_ShotgunPunishNerf
{
	States
	{
	Spawn:
		SHOT A 6 Bright { A_SetScale(-0.8, 0.3); }
		SHOT A 6 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 6 Bright { A_SetScale(-1.6, 0.9); }
		SHOT A 6 Bright { A_SetScale(-1.2, 1.1); }
		SHOT A 6 Bright { A_SetScale(-1.0, 1.0); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 18 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(1, 7), random(1, 5), "BulletPuff", 0); }
		SHOT A 3 Bright { A_SetScale(-1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(-0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(-0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(-0.1, 0.1); }
		TNT1 A 0 { A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The carrier A_VileTarget actually spawns.
class RS_ShotgunpunisherNerfed : Actor
{
	Default { Speed 1; Projectile; +NOCLIP; -COUNTKILL; Alpha 0.01; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 Bright { A_SpawnItemEx("RS_ShotgunPunishNerf", 0, 128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_ShotgunPunishNerf2", 0, -128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		Stop;
	}
}

// =====================================================================
// CHP 01 (Zombieman) REBUILD ADDITIONS -- ported for RS_Zombieman.zs.
// Each is a CHP `*_C` class; the `_C` suffix is stripped and RS_ added.
// Where CHP's `_C` class only re-declares its CH parent with no changes
// (BloodyPuff_C : BloodyPuff {}, CH_BoneGib_C : CH_BoneGib { ... }),
// the CH parent supplies the body and CHP's overrides go on top.
// =====================================================================

// Red ZombieUnman's slug puff. CH BloodyPuff; CHP BloodyPuff_C adds
// nothing to the Common colour. DBLD sprites copied from CH/sprites/
// zombies into sprites/monsters/projectiles/.
class RS_BloodyPuff : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +PUFFONACTORS; +EXTREMEDEATH; }
	States
	{
	Spawn:
	Crash:
		DBLD A 4 Bright;
		DBLD BCD 4;
		Stop;
	}
}

// "Player 9"'s rocket. CHP Rocket_C is a FastProjectile, not the stock
// Rocket -- kept as CHP has it.
class RS_Rocket : FastProjectile
{
	Default { Radius 11; Height 8; Speed 20; Damage 20; Projectile; +RANDOMIZE; +DEHEXPLOSION; +ROCKETTRAIL;
		SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; Obituary "$OB_MPROCKET"; }
	States
	{
	Spawn:
		MISL A 1 Bright;
		Loop;
	Death:
		MISL B 8 Bright A_Explode();
		MISL C 6 Bright;
		MISL D 4 Bright;
		Stop;
	}
}

// The Undertaker's bone shrapnel (XDeath). CH CH_BoneGib body, CHP's
// Speed 2 override. Bounces, then rattles to a stop and fades.
class RS_CH_BoneGib : Actor
{
	Default { Radius 2; Height 3; Damage 0; Speed 2; Projectile; +DOOMBOUNCE; +MOVEWITHSECTOR; +CANNOTPUSH;
		-NOGRAVITY; +NOTONAUTOMAP; BounceFactor 0.5; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 { vel.z += 13.75; }
		Goto Wee;
	Wee:
		BBBN ABCD random(3, 6);
		Loop;
	Crash:
	Death:
		BBBN ABD 1;
		BBBN C 850;
		Stop;
	}
}

// =====================================================================
// CHAINGUNNER -- CHP rebuild additions (DECORATE/04/04_*.txt, CHP is
// authoritative; CH parents consulted only where CHP left a property or
// state undefined). Damage rolls collapse to constants per this file's
// house style; the A_Explode rolls stay as rolls because they are the
// attack, not the contact damage.
// =====================================================================

// T01 GREEN -- the green chaingunner's tracer, used as a bullet PUFF
// (CHP 08_G Trail11_C). Non-interacting: it is the visible tracer, the
// A_CustomBulletAttack hitscan is what actually hurts.
class RS_Trail11 : Actor
{
	Default { Radius 6; Height 16; Speed 16; FastSpeed 23; Projectile; +RANDOMIZE; +NOINTERACTION;
		RenderStyle "Add"; Scale 0.5; Alpha 0.6; Translation "168:255=112:127"; }
	States { Spawn: BAL1 CDE 6 Bright; Goto Death; Death: BAL1 CDE 6 Bright; Stop; }
}

// T02 BLUE -- rail impact spark (CH BlueChainPuff2, CHP _C sets Speed 2).
class RS_BlueChainPuff2 : Actor
{
	Default { Radius 12; Height 12; Speed 2; Projectile; +NOINTERACTION; +ALWAYSPUFF;
		RenderStyle "Add"; Alpha 0.73; Scale 0.25; }
	States { Spawn: SSBL KIJ 1 Bright; Goto Death; Death: SSBL KIJ 1 Bright; Stop; }
}

// T04 PURPLE -- three grades of seeking micro-rocket, one per range band
// (CHP 04_P Boomer1/2/3_C). 1 = point blank and hardest-seeking, 3 = long
// range and dumb-fired.
class RS_Boomer1 : FastProjectile
{
	Default { Radius 3; Height 2; Speed 68; Damage 4; DamageType "Fire"; Projectile; +SEEKERMISSILE;
		Scale 0.15; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		MISL A 1 Bright A_SeekerMissile(8, 8);
		Loop;
	Death:
		MISL B 8 Bright A_Explode(random(1, 8), 46);
		MISL C 6 Bright;
		MISL D 4 Bright;
		Stop;
	}
}
class RS_Boomer2 : RS_Boomer1
{
	Default { Damage 3; }
	States { Spawn: MISL A 1 Bright A_SeekerMissile(4, 4); Loop; }
}
class RS_Boomer3 : RS_Boomer1 { Default { -SEEKERMISSILE; Damage 3; } }

// T05 YELLOW -- the plasma gunner's rail spark: A_CustomRailgun spawns a
// line of these along the beam and they seek and pop (CHP 04_Y).
class RS_CGRailBuff : FastProjectile
{
	Default { Radius 4; Height 4; Speed 14; FastSpeed 26; Damage 2; DamageType "Plasma"; Projectile;
		+RANDOMIZE; +SEEKERMISSILE; Scale 0.33; RenderStyle "Add"; Alpha 0.85;
		Translation "168:191=193:205", "208:223=192:197", "160:167=4:4", "224:231=4:4",
		            "232:235=199:199", "248:249=193:193", "0:0=0:0"; }
	States
	{
	Spawn:
		BAL1 AB 3 Bright;
		Goto Death;
	Death:
		TNT1 A 0 A_SetScale(0.22, 0.22);
		BAL1 A 3 Bright A_Explode(2, 24);
		TNT1 A 0 A_SetScale(0.11, 0.11);
		BAL1 B 3 Bright A_Explode(2, 24);
		Stop;
	}
}

// T06 ABYSS -- the captain's ground splash. Spawned ON the target by
// A_VileTarget; its Spawn frame falls straight through into Death, so it
// detonates where it lands rather than travelling.
class RS_SplashAbyssCguy : Actor
{
	Default { Radius 6; Height 16; Damage 5; DamageType "Ice"; Speed 16; FastSpeed 23; Projectile;
		+THRUACTORS; +FLOATBOB; +FORCERADIUSDMG; Scale 0.3;
		Translation "0:255=%[0.04,0.04,0.06]:[0.58,0.98,1.30]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		BAL7 C 1 Bright A_SetScale(0.5);
		TNT1 A 0 ThrustThingZ(0, random(1, 33), 0, 0);
		TNT1 A 0 A_Explode(7, 32);
		BAL7 CDE 3 Bright;
		Stop;
	}
}

// T08 BROWN -- the deployable sandbag. Thrown, inflates, wanders a step,
// turns solid, then rots. This is the brown chaingunner's whole identity:
// it builds cover instead of pushing.
class RS_BrownSandBagCGuy : Actor
{
	Default { Radius 42; Height 24; Speed 3; Species "BrownCguy"; +THRUSPECIES; +THRUACTORS; +SOLID; Gravity 1; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		SB4G X 3 Bright A_SetScale(0.45, 0.45);
		SB4G X 3 Bright A_SetScale(0.6, 0.75);
		SB4G X 3 Bright A_SetScale(1.05, 1.2);
		SB4G X 3 Bright A_SetScale(1.5, 1.5);
		SB4G XX 1 A_Wander();
		TNT1 A 0 { bTHRUACTORS = false; }
	Flier:
		SB4G X 300 Bright;
		Goto Death;
	Death:
		SB4G X 2 Bright A_NoBlocking();
		SB4G X 2 Bright A_SetScale(1.05, 1.05);
		SB4G X 2 Bright A_SetScale(0.75, 0.75);
		SB4G X 2 Bright A_SetScale(0.3, 0.15);
		Stop;
	}
}

// T09 GRAY -- the hopping gunner's fast tracer (CHP 04_GY GrayPewPew_C).
class RS_GrayPewPew : Actor
{
	Default { Radius 4; Height 5; Speed 60; Damage 16; DamageType "Fire"; Projectile; +RANDOMIZE;
		SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; Scale 0.28;
		Translation "0:255=%[0.28,0.25,0.22]:[1.01,1.01,1.01]"; }
	States
	{
	Spawn:
		RIP1 ABC 2 Bright;
		Loop;
	Death:
		RIP1 D 0 A_SetTranslucent(0.75, 1);
		RIP1 DEFGH 2 Bright;
		Stop;
	}
}

// T09 GRAY -- the close-range lob. Trails for a randomised fuse, drops
// out of the air, coasts to a dead stop, sits there, then detonates.
// CHP counts the fuse in a GrayKaboomInv inventory item capped at 6;
// here it is a plain field (rs_09 spec: user vars -> private ints).
class RS_GrayKaboom : Actor
{
	private int rsFuse;

	Default { Radius 8; Height 12; Speed 6; Damage 45; Scale 1.15; DamageType "Fire"; Projectile;
		RenderStyle "Normal"; +THRUGHOST; +NOEXPLODEFLOOR; Decal "Scorch"; SeeSound "weapons/rocklf"; }
	States
	{
	Spawn:
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 0
		{
			rsFuse += random(1, 2);
			if (rsFuse >= 6) return ResolveState("Coast");
			return ResolveState(null);
		}
		Loop;
	Coast:
		FBR2 A 0 { bNOGRAVITY = false; }
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.9);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.8);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.7);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.6);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.5);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.4);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0);
	Sit:
		FBR2 A random(50, 750) Bright;
	Death:
	XDeath:
	Crash:
		BAL3 C 0 { bNOGRAVITY = true; }
		BAL3 C 0 Bright A_SetTranslucent(0.67, 1);
		BAL3 C 0 Bright A_StartSound("weapons/rocklx", CHAN_BODY);
		BAL3 C 6 Bright A_SetScale(1.5);
		BAL3 D 6 Bright A_Explode(random(20, 75), 128, 0);
		BAL3 E 6 Bright;
		Stop;
	}
}

// T11 BLACK -- the General's shielded volley bolt and its own sub-trail
// (CHP 04_K TrailSPCguy_C / CHP 16_Y TrailSP2_C).
class RS_TrailSP2 : FastProjectile
{
	Default { Radius 6; Height 16; Speed 20; DamageType "Plasma"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.35; Scale 0.25; Decal "ArachnotronScorch"; }
	States
	{
	Spawn:
		SPPL AB 2 Bright;
		Goto Death;
	Death:
		APBX ABCDE 4 Bright A_Explode(7, 32);
		Stop;
	}
}
class RS_TrailSPCguy : FastProjectile
{
	Default { Radius 6; Height 16; Speed 22; DamageType "Plasma"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.65; Scale 0.55; Decal "ArachnotronScorch"; }
	States
	{
	Spawn:
		SPPL AB 2 Bright A_SpawnItemEx("RS_TrailSP2", 0, 0, 2);
		Loop;
	Death:
		APBX ABCDE 4 Bright A_Explode(10, 32);
		Stop;
	}
}

// ---------------------------------------------------------------------
// T12 WHITE -- the lady scientist's three live experiments. These are
// real monsters, not projectiles, but they exist only as her summons, so
// they live with the rest of her kit. All are -COUNTKILL per CHP: a boss
// that spawns forever must not make 100% kills impossible.
// ---------------------------------------------------------------------

// Her first experiment: a cacodemon wired to blow. It swells as it
// closes, its "melee" is detonating on you, and it seeds five babies.
class RS_BabyCacoBall : Actor
{
	Default { Radius 3; Height 4; Speed 11; FastSpeed 10; Damage 3; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 1.0; SeeSound "caco/attack"; DeathSound "caco/shotx"; Decal "DoomImpScorch"; }
	States
	{
	Spawn:
		BCAB AB 4 Bright;
		Loop;
	Death:
		BCAB CDE 6 Bright;
		Stop;
	}
}
class RS_BabyCaco : Actor
{
	Default
	{
		Health 125; Radius 18; Height 36; Mass 200; Speed 11; PainChance 176;
		Monster; +NOGRAVITY; +FLOAT; +THRUSPECIES; -COUNTKILL;
		Scale 0.9; BloodColor "Blue"; Species "Science";
		SeeSound "caco/sight"; PainSound "caco/pain"; DeathSound "caco/death"; ActiveSound "caco/active";
		Obituary "%o underestimated a Baby Cacodemon.";
		HitObituary "%o was nibbled to death by a Baby Cacodemon.";
		Tag "smol babby caco";
	}
	States
	{
	Spawn:
		CACB A 10 A_Look();
		Loop;
	See:
		CACB A 3 A_Chase();
		Loop;
	Melee:
	Missile:
		CACB AB 5 A_FaceTarget();
		CACB C 5 Bright A_CustomComboAttack("RS_BabyCacoBall", 17, random(1, 8) * 3, "caco/attack");
		Goto See;
	Pain:
		CACB D 3;
		CACB D 3 A_Pain();
		CACB E 6;
		Goto See;
	Death:
		CACB F 8;
		CACB G 8 A_Scream();
		CACB HI 8;
		CACB J 8 A_NoBlocking();
		CACB K 8;
		CACB L -1 A_SetFloorClip();
		Stop;
	Raise:
		CACB L 8 A_UnSetFloorClip();
		CACB KJIHGF 8;
		Goto See;
	}
}
class RS_VolativeCaco : Actor
{
	Default
	{
		Health 100; Radius 31; Height 56; Mass 500; Speed 11; FloatSpeed 4; PainChance 90;
		Monster; +MISSILEMORE; +MISSILEEVENMORE; +TOUCHY; +LOOKALLAROUND; +FLOAT; +NOGRAVITY;
		+DONTHARMSPECIES; -COUNTKILL;
		Scale 1.1; XScale 1.3; BloodColor "Blue"; Species "Science";
		SeeSound "caco/sight"; PainSound "caco/pain"; DeathSound "weapons/rocklx"; ActiveSound "caco/active";
		Obituary "%o stood too close to the unstable cacodemon";
		Tag "Unstable cacodemon";
	}
	States
	{
	Spawn:
		HEAD A 10 A_Look();
		Loop;
	See:
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.4, 1.3);
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.5, 1.4);
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.4, 1.3);
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.3, 1.2);
		Loop;
	Melee:
		HEAD BC 4;
		Goto Death;
	Pain:
		HEAD E 3;
		HEAD E 3 A_Pain();
		HEAD F 6;
		Goto See;
	Death:
		HEAD D 8;
		HEAD D 1 A_Scream();
		MISL CD 6 A_Explode(random(20, 60), 128);
		MISL E 0 A_SpawnItemEx("RS_BabyCaco", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS);
		MISL E 1 A_SpawnItemEx("RS_BabyCaco", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS);
		MISL E 2 A_SpawnItemEx("RS_BabyCaco", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS);
		MISL E 0 A_SpawnItemEx("RS_BabyCaco", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS);
		MISL E 1 A_SpawnItemEx("RS_BabyCaco", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS);
		TNT1 A 0 A_Die();
		MISL E 0;
		Stop;
	}
}

// Her second experiment: a noclipping worm that surfaces, then spits a
// five-ball slime volley. Reuses the arachnotron slime pool.
class RS_SlimyWorm : Actor
{
	Default
	{
		Health 250; Radius 30; Height 56; Mass 400; Speed 8; PainChance 90;
		Monster; +THRUSPECIES; +FLOORCLIP; +MISSILEMORE; +SHORTMISSILERANGE; +NOCLIP; -COUNTKILL;
		BloodColor "Yellow"; Species "Science";
		SeeSound "demon/sight"; AttackSound "demon/melee"; PainSound "demon/pain";
		DeathSound "demon/death"; ActiveSound "demon/active";
		Obituary "%o got melted up good by a slimy minion worm";
		HitObituary "%o was digested by a slimy minion worm.";
		Tag "Worm minion";
	}
	States
	{
	Spawn:
		WORM AB 10 A_Look();
		Loop;
	See:
		WORM AABBCCDD 3 A_Chase();
		WORM A 0 { bNOCLIP = false; }
		Loop;
	Missile:
		WORM E 8 A_FaceTarget();
		WORM F 8 A_StartSound("imp/attack", CHAN_WEAPON);
		WORM F 0 A_SpawnProjectile("RS_SlimeBall1", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall2", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall3", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall4", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall5", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM G 8;
		Goto See;
	Melee:
		WORM EF 8 A_FaceTarget();
		WORM G 8 A_CustomMeleeAttack(random(1, 10) * 4);
		Goto See;
	Pain:
		WORM H 2;
		WORM H 2 A_Pain();
		Goto See;
	Death:
		WORM I 8;
		WORM J 8 A_Scream();
		WORM K 4;
		WORM L 4 A_NoBlocking();
		WORM M 4;
		WORM N -1;
		Stop;
	Raise:
		WORM NMLKJI 5;
		Goto See;
	}
}

// Her third experiment, and the one the phase change hands you: an
// arachnotron spliced onto a baron. Painless, alternates the spider's
// refire loop with a three-ball baron fan.
class RS_SpliceBaron : Actor
{
	Default
	{
		Health 1000; Radius 64; Height 70; Mass 1000; Speed 12; PainChance 0;
		Monster; +FLOORCLIP; +THRUSPECIES; +DONTHARMSPECIES; +MISSILEMORE; +MISSILEEVENMORE;
		+DONTMORPH; +NOCLIP; -COUNTKILL;
		BloodColor "Green"; Species "Science";
		DamageFactor "Plasma", 1.2; DamageFactor "Fire", 1.1;
		SeeSound "baron/sight"; PainSound "baron/pain"; DeathSound "baron/death"; ActiveSound "baby/active";
		Obituary "what has science done; %o was killed by a horrible abomination";
		Tag "Splice hell";
	}
	States
	{
	Spawn:
		ARBR AB 10 A_Look();
		Loop;
	See:
		ARBR A 0 A_Chase();
		ARBR A 3 A_StartSound("baby/walk", CHAN_BODY);
		ARBR ABBCC 3 A_Chase();
		ARBR A 0 { bNOCLIP = false; }
		ARBR D 0 A_Chase();
		ARBR D 3 A_StartSound("baby/walk", CHAN_BODY);
		ARBR DEEFF 3 A_Chase();
		Goto See;
	Missile:
		ARBR A 1 Bright A_Jump(128, "Missile2");
	MissileLoop:
		ARBR A 20 Bright A_FaceTarget();
		ARBR G 3 Bright A_SpawnProjectile("ArachnotronPlasma", 15, 0, 0);
		ARBR H 2 Bright;
		ARBR H 1 Bright A_SpidRefire();
		Goto MissileLoop;
	Missile2:
		ARBR P 2 Bright A_FaceTarget();
		ARBR P 5 Bright A_SpawnProjectile("BaronBall", 30, 0, 5);
		ARBR Q 5 Bright A_SpawnProjectile("BaronBall", 30, 0, 0);
		ARBR R 5 Bright A_SpawnProjectile("BaronBall", 30, 0, -5);
		Goto See;
	Death:
		ARBR J 20 A_Scream();
		ARBR K 7 A_NoBlocking();
		ARBR LMNO 7;
		ARBR O -1 A_BossDeath();
		Stop;
	}
}

// =====================================================================
// TEX ADDITIONS -- the fourteenth tier (the CHP "EX" bosses).
// ---------------------------------------------------------------------
// Zombieman TEX is CHP 01_KX CommonBlackZombieEX2, a COMMON boss, so its
// projectiles are the `_C` colour. Shotgunner TEX (02_WX
// GreenWhiteSGEX2) and Chaingunner TEX (04_KX GreenBlackCGuyEX2) are
// GREEN bosses, so theirs are the `_G` colour. The suffix is stripped on
// import, so one RS_ class serves each -- and the numbers below are the
// ones the boss that actually fires it uses, not a different colour's.
//
// Every CHP `_C`/`_G` class here was checked against its CH parent; where
// CHP redeclares the whole body (which it does for all of these) CHP
// wins outright and CH was only read to confirm nothing was left
// undefined.
// =====================================================================

// ---------- ZOMBIEMAN TEX: PLAYER X (01_KX) -------------------------
// The BFG. Player X's panic button: a fat, slow orb that detonates into
// a cloud of thirty smaller ones, so the real damage arrives a beat
// AFTER you dodged the thing you saw.
class RS_PlayerEXBFG : FastProjectile
{
	Default
	{
		Radius 12; Height 12; Speed 25;
		Damage (random(100, 200)); DamageType "Plasma";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 1.25; Scale 1.0;
		DeathSound "weapons/bfgx";
	}
	States
	{
	Spawn:
		BFS1 A 2 Bright { A_SpawnItemEx("RS_TrailSPCguy", random(-2, 2), random(-2, 2), random(-1, 1), 20, 0, random(-5, 5), random(-270, 270)); }
		BFS1 B 2 Bright { A_SpawnItemEx("RS_TrailSPCguy", random(-2, 2), random(-2, 2), random(-1, 1), 20, 0, random(-5, 5), random(-270, 270)); }
		Loop;
	Death:
		BFE1 AB 8 Bright { A_SetScale(1.25); }
		TNT1 A 0 { A_Quake(15, 15, 0, 40); }
		BFE1 C 8 Bright { A_Explode(random(45, 125), 156); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_PlayerEXBFG2", random(-12, 12), random(-12, 12), random(-1, 1), random(2, 19), 0, random(-9, 9), random(-359, 359), SXF_NOCHECKPOSITION); }
		BFE1 DEF 8 Bright;
		Stop;
	}
}

// The shrapnel. Each one also self-destructs on a small random roll, so
// the cloud thins out instead of hanging around forever.
class RS_PlayerEXBFG2 : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 10;
		Damage (random(20, 80)); DamageType "Plasma";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 1.25; Scale 0.55;
		Translation "0:255=%[0.00,0.17,0.00]:[0.81,1.35,0.28]";
	}
	States
	{
	Spawn:
		BFS1 A 2 Bright { A_SetScale(0.55, 0.75); }
		BFS1 B 2 Bright { A_SetScale(0.75, 0.55); }
		TNT1 A 0 A_Jump(2, "Death");
		Loop;
	Death:
		BFS1 ABABAB 2 Bright { A_FadeOut(0.33); }
		Stop;
	}
}

// ---------- SHOTGUNNER TEX: GREEN BENELLUS (02_WX) ------------------
// The full-strength Punisher pair. The T12 Benellus already ships the
// NERFED twins (RS_ShotgunPunishNerf/2); these are CH's originals, which
// wind up faster and throw a bigger pellet spread. Kept as separate
// classes rather than tuning the nerfed ones, because BOTH exist in the
// source and T12 must not silently get the EX version's teeth.
class RS_ShotgunPunish : Actor
{
	Default
	{
		Radius 12; Height 12; Speed 1; Health 375;
		RenderStyle "SoulTrans"; Alpha 0.95;
		Monster; +NOTRIGGER; +NOCLIP; +NOBLOOD; -COUNTKILL;
		SeeSound "weapons/sshotl"; DeathSound "weapons/rocklx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		SHOT A 2 Bright { A_SetScale(0.8, 0.3); }
		SHOT A 2 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 4 Bright { A_SetScale(1.6, 0.9); }
		SHOT A 4 Bright { A_SetScale(1.2, 1.1); }
		SHOT A 4 Bright { A_SetScale(1.0, 1.0); }
		SHOT A 3 Bright { A_SetScale(1.3, 0.6); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 13 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(3, 10), random(1, 6), "BulletPuff", 0); }
		SHOT A 4 Bright { A_SetScale(1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(0.1, 0.1); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The mirrored twin -- negative X scale, so the pair reads as closing in
// from both sides at once.
class RS_ShotgunPunish2 : RS_ShotgunPunish
{
	States
	{
	Spawn:
		SHOT A 2 Bright { A_SetScale(-0.8, 0.3); }
		SHOT A 4 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 4 Bright { A_SetScale(-1.6, 0.9); }
		SHOT A 4 Bright { A_SetScale(-1.2, 1.1); }
		SHOT A 3 Bright { A_SetScale(-1.0, 1.0); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 13 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(3, 10), random(1, 6), "BulletPuff", 0); }
		SHOT A 3 Bright { A_SetScale(-1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(-0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(-0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(-0.1, 0.1); }
		TNT1 A 0 { A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The carrier A_VileTarget plants on you -- it hangs one gun on each
// flank and vanishes.
class RS_ShotgunPunisher : Actor
{
	Default { Speed 1; Projectile; +NOCLIP; -COUNTKILL; Alpha 0.01;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 Bright { A_SpawnItemEx("RS_ShotgunPunish", 0, 128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_ShotgunPunish2", 0, -128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		Stop;
	}
}

// The OTHER carrier: same idea, but it plants two SHRINES instead of two
// guns -- turrets that stay, chase, and have to be killed.
class RS_ShotgunPunisher2 : Actor
{
	Default { Speed 1; Projectile; +NOCLIP; -COUNTKILL; Alpha 0.01;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 Bright { A_SpawnItemEx("RS_ShotgunShrine", 0, 178, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_ShotgunShrine", 0, -178, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		Stop;
	}
}

// A shrine is a walking gun emplacement: it chases you, opens up with a
// spark barrage, and DAMAGES ITSELF every burst, so it burns down on its
// own if you can survive it. Dies into an explosion plus two mines.
class RS_ShotgunShrine : Actor
{
	Default
	{
		Radius 30; Height 64; Speed 10; Health 1000;
		Monster;
		+NOTRIGGER; +MISSILEMORE; +MISSILEEVENMORE; +THRUSPECIES;
		+DONTHARMCLASS; +DONTHARMSPECIES; +NOTARGETSWITCH; +NOCLIP; +NOBLOOD;
		Species "BENE";
		SeeSound "weapons/sshotl"; DeathSound "weapons/rocklx";
		Obituary "$OB_SHOTGUY";
		Tag "Green Shotgun Shrine";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		BENE M 2 Bright { A_SetScale(1.0, 0.1); }
		BENE M 2 Bright { A_SetScale(1.0, 0.4); }
		BENE M 2 Bright { A_SetScale(1.0, 0.7); }
		BENE M 2 Bright { A_SetScale(1.0, 1.0); }
	Idle:
		BENE MNOP 6 { A_Chase(); }
		Loop;
	Missile:
		BENE M 6 { A_FaceTarget(); }
		BENE M 6 Bright;
		BENE Q 1 Bright { A_StartSound("shotguy/attack", CHAN_WEAPON); }
		BENE QRQRQRQR 1 Bright { A_SpawnProjectile("RS_SparkFireBen", 84, 0, random(-3, 3)); }
		// CHP's damagething(80): the shrine pays for every burst it fires.
		TNT1 A 0 { A_DamageSelf(80); }
		Goto Missile;
	Death:
		BENE M 2 Bright { A_SetScale(0.8, 1.0); }
		BENE M 2 Bright { A_SetScale(0.5, 1.2); }
		BENE M 2 Bright { A_SetScale(0.3, 1.5); }
		BENE M 2 Bright { A_SetScale(0.1, 1.8); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); A_Scream(); A_NoBlocking(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 128); }
		TNT1 AA 0 { A_SpawnProjectile("RS_MineShotgun", random(20, 60), random(-15, 15), random(-20, 20), 0); }
		Stop;
	}
}

// The bubble Benellus wraps itself in before the focused-fire barrage --
// forty of these, purely a tell that the big one is coming.
class RS_SparkShieldBen : Actor
{
	Default
	{
		+NOGRAVITY; +SPAWNFLOAT; +NOINTERACTION;
		RenderStyle "Add"; Speed 1; Alpha 0.95; Scale 1.33; Mass 2;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		PUFF ABABABAB 10 Bright;
		PUFF BBB 5 { A_FadeOut(0.33); }
		Stop;
	}
}

// The barrage itself: tiny, very fast, and it lays a spark puff on every
// single tic of flight, so the volume on screen is the point.
class RS_SparkFireBen : FastProjectile
{
	Default
	{
		Radius 2; Height 2; Speed 68; FastSpeed 100;
		Damage (random(8, 15));
		Projectile; +MTHRUSPECIES;
		RenderStyle "Add"; Alpha 0.85; Scale 0.15;
		DeathSound "imp/shotx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		PUFF AB 1 Bright { A_SpawnItemEx("RS_SparkPuff1", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		TNT1 AAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SparkPuff1", 0, 0, 0, random(-3, 3), random(-3, 3), random(-3, 3), random(-358, 358), SXF_NOCHECKPOSITION); }
		Stop;
	}
}

// ---------- CHAINGUNNER TEX: GREEN WARFACE (04_KX) ------------------
// The lobbed bomb. Floats for its first arc, then gravity comes back on
// and it drops -- and the detonation is a NINE-STAGE escalating blast,
// each ring wider than the last. Getting out of the first one is not
// getting out of it.
class RS_YellowBombCGuyEX : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 48;
		Damage (random(25, 100)); DamageType "Fire";
		Projectile; +RANDOMIZE; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 1.0; Scale 1.25;
		DeathSound "weapons/rocklx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		GBLL ABC 6 Bright;
	Fly:
		GBLL ABC 6 Bright;
		TNT1 A 0 { bNOGRAVITY = false; }
		Loop;
	Death:
		GBLL A 6 Bright { A_SetScale(1.0, 1.0); }
		GBLL B 6 Bright { A_SetScale(0.75, 0.75); }
		GBLL C 6 Bright { A_SetScale(0.5, 0.5); }
		GBLL A 6 Bright { A_SetScale(0.25, 0.25); }
		GBLL BCABC 6 Bright;
		BBOM A 2 Bright { A_SetScale(0.5, 0.5); }
		TNT1 A 0 { A_Explode(random(13, 25), 32, 0); }
		BBOM B 2 Bright { A_SetScale(0.75, 0.75); }
		TNT1 A 0 { A_Explode(random(13, 37), 64, 0); }
		BBOM C 2 Bright { A_SetScale(1.25, 1.25); }
		TNT1 A 0 { A_Explode(random(25, 75), 74, 0); }
		BBOM C 2 Bright { A_SetScale(2.0, 2.0); }
		TNT1 A 0 { A_Explode(random(25, 100), 128, 0); }
		BBOM C 2 Bright { A_SetScale(2.5, 2.5); }
		TNT1 A 0 { A_Explode(random(38, 112), 176, 0); }
		BBOM C 2 Bright { A_SetScale(3.0, 3.0); }
		TNT1 A 0 { A_Explode(random(38, 112), 256, 0); }
		BBOM C 2 Bright { A_SetScale(3.5, 3.5); }
		TNT1 A 0 { A_Explode(random(38, 112), 256, 0); }
		BBOM C 2 Bright { A_SetScale(4.0, 4.0); }
		TNT1 A 0 { A_Explode(random(38, 112), 312, 0); }
		BBOM CCCBA 4 Bright { A_FadeOut(0.20); }
		Stop;
	}
}

// The spam round. Wide damage roll (13..150) so a burst of these is
// genuinely swingy, and each one dies into a small cluster bomb.
class RS_SpamShotsCGuyEX : FastProjectile
{
	Default
	{
		Radius 12; Height 9; Speed 35;
		Damage (random(13, 150)); DamageType "Plasma";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 0.95; Scale 0.25;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		GRFZ DEFGH 2 Bright;
		Loop;
	Death:
		GRFZ IJ 4 Bright { A_SetScale(1.0, 1.0); }
		GRFZ K 4 Bright { A_Explode(random(28, 110), 256, 0); }
		GRFZ LMN 3 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-64, 64), random(-64, 64), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-128, 128), random(-128, 128), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		GRFZ OP 4 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-32, 32), random(-32, 32), random(-64, 128), random(12, 99), 0, random(-25, 25), random(0, 359), SXF_NOCHECKPOSITION); }
		Stop;
	}
}

// Identical round, fire damage type -- CHP alternates the two through
// the RedSpam volley so resistances can't cover the whole burst.
class RS_SpamShotsCGuyEX2 : RS_SpamShotsCGuyEX { Default { DamageType "Fire"; } }

// The sub-munition. Spawns already dead: it exists only to be an
// explosion at a random offset.
class RS_ExplosionsCGuyEX : FastProjectile
{
	Default
	{
		Radius 12; Height 9; Speed 35;
		Damage (random(25, 75)); DamageType "Fire";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 0.95; Scale 0.42;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		GRFZ IJ 3 Bright;
		GRFZ K 3 Bright { A_Explode(random(14, 96), 128, 0); }
		GRFZ LMN 2 Bright;
		GRFZ OP 3 Bright;
		Stop;
	}
}

// Same, but it FLIES for eleven tics first. That delay is the whole
// trick: the second wave lands where you ran to.
class RS_ExplosionsCGuyEXDelayed : FastProjectile
{
	Default
	{
		Radius 3; Height 3; Speed 63;
		Damage (random(25, 75)); DamageType "Fire";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 0.95; Scale 0.42;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		TNT1 A 11;
	Death:
		TNT1 A 0 { A_Stop(); }
		GRFZ IJ 3 Bright;
		GRFZ K 3 Bright { A_Explode(random(14, 96), 128, 0); }
		GRFZ LMN 2 Bright;
		GRFZ OP 3 Bright;
		Stop;
	}
}

// THE big one. A seeker that trails saws and small blasts on the way in,
// then detonates into a two-stage 386-radius field seeded with roughly
// two hundred delayed sub-munitions. It is the general's finisher.
class RS_CGBigEX : FastProjectile
{
	Default
	{
		Radius 8; Height 8; Speed 26;
		Damage (random(38, 100)); DamageType "Plasma";
		Projectile; +NOGRAVITY; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.75; Scale 0.75;
		SeeSound "spell/spellcast1"; DeathSound "fire/fire4";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		RED9 B 1 Bright { A_SeekerMissile(2, 4); }
		RED9 AA 1 Bright { A_SpawnItemEx("RS_SpiralSaw5", 0, 0, 0, 0, 0, 0, 0, 128); }
		RED9 A 0 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-128, 24), random(-64, 64), random(-32, 32), 1, 0, random(-1, 1), random(0, 359), SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		SPIR A 1 Bright { A_SetScale(1.5); }
		SPIR ABCDEDCBA 5 Bright { A_Explode(random(6, 38), 164); }
		SPIR E 1 Bright { A_SetScale(3.0); }
		GRFZ IJ 4 Bright;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-24, 68), random(12, 99), 0, random(-25, 25), random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-14, 28), random(12, 99), 0, random(-25, 25), random(180, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(0, 180), SXF_NOCHECKPOSITION); }
		GRFZ K 4 Bright { A_Explode(random(68, 139), 386, 0); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-6, 28), random(12, 99), 0, random(-25, 25), random(180, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(0, 180), SXF_NOCHECKPOSITION); }
		GRFZ LMN 3 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-64, 64), random(-64, 64), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(180, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-64, 128), random(12, 99), 0, random(-25, 25), random(0, 180), SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_Explode(random(83, 160), 386, 0); }
		GRFZ OP 4 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-64, 64), random(-124, 124), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		GRFZ III 2 { A_FadeOut(0.20); }
		Stop;
	}
}

// The wind-up glyph. Harmless -- it exists purely so the two-second
// charge before the general's heavy shots is READABLE. Spawns straight
// into its own Death, which is the whole animation.
class RS_SpiralLoadGeneEX : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 3;
		Projectile; +NOINTERACTION; +THRUACTORS;
		RenderStyle "Add"; Alpha 0.95; Scale 1.0;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		GRFZ CBA 4 Bright;
		TNT1 A 0 { A_SetScale(0.75, 0.75); }
		GRFZ BA 4 Bright;
		TNT1 A 0 { A_SetScale(0.5, 0.5); }
		GRFZ BA 4 Bright;
		TNT1 A 0 { A_SetScale(0.25, 0.25); }
		GRFZ BA 4 Bright;
		GRFZ I 1 Bright;
		TNT1 A 0 { A_SetScale(0.5, 0.5); }
		GRFZ I 1 Bright;
		TNT1 A 0 { A_SetScale(0.75, 0.75); }
		GRFZ I 1 Bright;
		Stop;
	}
}

// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * SGRN -> GRND (source comment wrongly called SGRN a stock IWAD sprite)  (1 occurrence)
//   * CHP sound names with no SNDINFO entry in this repo remapped to the
//     nearest vanilla logical name (SNPRFIRE/weapons/firex4 -> weapons/
//     rocklf|rocklx, monster/dknmsl -> weapons/rocklf, weapons/boom1 |
//     weapons/hellex -> weapons/rocklx, SlimeBall/Shoot -> imp/attack,
//     slimeworm/* -> demon/*, BabyCaco/* -> caco/*, arachnobaron/death
//     -> baron/death). Adding the CH oggs is task #2, not this pass.
