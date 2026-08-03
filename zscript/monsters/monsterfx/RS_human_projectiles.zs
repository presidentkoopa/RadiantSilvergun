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


// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * SGRN -> GRND (source comment wrongly called SGRN a stock IWAD sprite)  (1 occurrence)
