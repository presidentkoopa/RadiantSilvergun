// =====================================================================
// RS_lostsoul_projectiles.zs
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
// hf_lostsoul_projectiles.zs -- Lost Soul projectiles (charge-skull color ladder).
// Most colors are the flying A_SkullAttack ram (no projectile). Ranged colors + the
// White "mimic" apex fire these. Heavily reuses the pool: RS_WormLewd, RS_AcidBlast1,
// RS_Zap7, RS_Purp1, RS_BaronWave, RS_Spspit2, RS_SmashBalls2, RS_Spear11, RS_BaronStar,
// RS_RevenantTracerHoming, RS_FatsoShotYE, RS_RocketShotFatso, RS_Shot2Fatso (already built).
// New ones below. Damage->constants.
// ============================================================================

// ---------- GREEN: poison "splasher soul" (BAL7) ----------
class RS_SplasherSoul : Actor
{
	Default { Radius 6; Height 16; Speed 5; FastSpeed 5; Damage 10; DamageType "Poison"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 1; Scale 1.6; DeathSound "baron/shotx"; }
	States { Spawn: BAL7 CDE 5 Bright A_Explode(10,48); Stop; }
}

// ---------- ABYSS: "beetle" bouncing poison spit (BLVB) ----------
class RS_BeetleSpitAbyss : Actor
{
	Default { Radius 4; Height 4; Speed 20; Damage 5; PoisonDamage 1; RenderStyle "Add"; Alpha 0.67; DamageType "Poison"; Projectile; Gravity 0.02; -NOGRAVITY;
		+USEBOUNCESTATE; BounceType "Hexen"; BounceFactor 1.25; BounceCount 4; Scale 0.25; DeathSound "imp/shotx"; Translation "0:255=%[0.20,0.40,0.00]:[0.70,1.30,0.20]"; }
	States { Spawn: BLVB AB 3 Bright; Loop; Death: BLVB CD 3 Bright; Stop; }
}

// ---------- RED: spit bolt (BAL1) ----------
class RS_SpitBoltLS : Actor
{
	Default { Radius 11; Height 11; Mass 25; Speed 21; Damage 23; DamageType "Plasma"; Projectile; Scale 0.6; RenderStyle "Add"; Alpha 0.95;
		SeeSound "Spell/spellCast1"; DeathSound "fire/Fire4"; Translation "208:223=176:191","224:231=176:176"; }
	States { Spawn: BAL1 AB 4 Bright; Loop; Death: BAL1 CDE 4 Bright A_Explode(23,48); Stop; }
}

// ---------- BLACK "hornet" (WASP): seeking sting-swarm + stingers ----------
class RS_BSoulHellNo : Actor
{
	Default { Radius 6; Height 6; Speed 16; Damage 2; DamageType "Melee"; Projectile; +SEEKERMISSILE; Scale 0.45; SeeSound "baron/attack"; DeathSound "baron/shotx"; }
	States { Spawn: WASP AB 2 Bright A_SeekerMissile(10,10,SMF_PRECISE); Loop; Death: WASP C 3 Bright; Stop; }
}
class RS_BSoulStinger1 : Actor
{
	Default { Radius 2; Height 2; Damage 15; DamageType "Melee"; PoisonDamage 6; PoisonDamageType "Poison"; Speed 35; YScale 0.6; XScale 1.4; Decal "BulletChip"; Species "Hornet";
		SeeSound "Jam/Jamd"; AttackSound "moloch/nailhitbleed"; DeathSound "gas/gas1"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; }
	States { Spawn: 6PUF AB 2 Bright; Loop; Death: BLAD ABC 3 Bright; Stop; }
}
class RS_BSoulStinger2 : RS_BSoulStinger1 { Default { Speed 28; Damage 20; } }

// ---------- WHITE MIMIC: ghost-form transform burst (SPIR) ----------
class RS_WSSmore : Actor
{
	Default { Radius 3; Height 3; Speed 12; Projectile; RenderStyle "Add"; Alpha 0.67; }
	States { Spawn: SPIR FGH 4; Goto Death; Death: SPIR IJ 3 Bright; Stop; }
}

// ---------- WHITE MIMIC arch-form: vile big bolt + arc rings + homer ----------
class RS_BigBolt2 : Actor
{
	Default { Radius 6; Height 8; Speed 17; Damage 60; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.9;
		SeeSound "vile/start"; DeathSound "vile/stop"; }
	States { Spawn: BFE1 AB 3 Bright A_SeekerMissile(2,2); Loop; Death: BFS1 CDEFG 4 Bright A_Explode(60,80); Stop; }
}
class RS_Homer1 : Actor
{
	Default { Radius 6; Height 16; Speed 11; FastSpeed 22; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.75;
		SeeSound "fire/fire1"; DeathSound "fire/fire5"; }
	States
	{
	Spawn:
		SBS1 A 0 A_PlaySound("Fire/fire3");
		SBS1 AB 2 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		MISL BCD 4 Bright A_Explode(30,64);
		Stop;
	}
}
class RS_ArcRing1 : Actor
{
	// FLOOR-HUGGING expanding fire ring (pattern #4)
	Default { Radius 6; Height 8; Speed 8; Projectile; +FLOORHUGGER; +THRUACTORS; +RANDOMIZE; +NOINTERACTION; RenderStyle "Add"; SeeSound "Fire/fire3"; Alpha 0.75; Scale 1; Damage 0; }
	States { Spawn: RNGG ABCDABCDABCD 3 Bright; Goto Death; Death: RNGG A 0 A_Explode(20,64); Stop; }
}
class RS_ArcRing2 : Actor
{
	// bouncing fire ring
	Default { Radius 6; Height 8; Speed 18; Mass 999999; Gravity 10; Projectile; -NOGRAVITY; +BOUNCEONFLOORS; +THRUACTORS; +RANDOMIZE; +BOUNCEONWALLS; +DONTBLAST; +DONTTHRUST;
		BounceCount 999; BounceType "Hexen"; BounceFactor 1; WallBounceFactor 0.9; RenderStyle "Add"; SeeSound "Fire/fire3"; Alpha 0.75; Damage 15; }
	States { Spawn: RNGG ABCD 3 Bright; Loop; Death: RNGG A 2 Bright A_Explode(15,48); Stop; }
}

// ============================== WHITE-EX MIMIC PROJECTILES ==============================
// The WhiteLSoulEX cycles 6 monster forms -- most fire the existing pool. New ones:
class RS_LSCacodemonBall : Actor
{
	Default { Radius 6; Height 8; Speed 18; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; SeeSound "caco/attack"; DeathSound "caco/shotx"; }
	States { Spawn: BAL2 AB 4 Bright; Loop; Death: BAL2 CDE 4 Bright A_Explode(30,64); Stop; }
}
// (RS_HKBolt2 already defined in hf_hk_projectiles.zs -- shared)
class RS_ReAComet : Actor
{
	Default { Radius 12; Height 12; Speed 28; Damage 50; RenderStyle "Add"; DamageType "Fire"; Alpha 0.85; Projectile; +BOUNCEONWALLS; BounceType "Doom"; BounceCount 2;
		BounceFactor 1.05; WallBounceFactor 1.1; SeeSound "vile/start"; DeathSound "vile/stop"; }
	States { Spawn: CBAL AB 3 Bright; Loop; Death: VBA3 ABCDE 4 Bright A_Explode(80,96); Stop; }
}
class RS_SoulexBeam : Actor
{
	Default { Radius 8; Height 8; Speed 69; Damage 20; DamageType "Ice"; Projectile; +DONTHARMCLASS; +THRUSPECIES; +FULLVOLDEATH; Species "whitelsoul"; Scale 0.77;
		SeeSound "ILLSHEAR"; DeathSound "NETHERDE"; RenderStyle "Add"; Alpha 0.9; Translation "Ice"; }
	States { Spawn: BAL2 AB 2 Bright; Loop; Death: PUFI ABCD 3 Bright A_Explode(20,32); Stop; }
}
class RS_SoulexBeam2 : RS_SoulexBeam { Default { Speed 55; } }
class RS_SoulexBeam3 : RS_SoulexBeam { Default { Speed 80; Scale 1.0; } }
class RS_SOULEXSoulCharge : Actor
{
	Default { Radius 16; Height 8; Speed 21; Projectile; +NOGRAVITY; +SEEKERMISSILE; +THRUSPECIES; Species "whitelsoul"; RenderStyle "Add"; Damage 50; DamageType "Melee"; Alpha 0.75; Scale 0.5;
		SeeSound "Spell/spellCast1"; DeathSound "skull/death"; }
	States { Spawn: SPIR FGH 3 Bright A_SeekerMissile(3,3); Loop; Death: ETHS ABC 4 Bright A_Explode(90,96); Stop; }
}


// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * SBSI -> SBS1 (typo in source; next line already used SBS1)  (1 occurrence)
