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

// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * SGRN -> GRND (source comment wrongly called SGRN a stock IWAD sprite)  (1 occurrence)
