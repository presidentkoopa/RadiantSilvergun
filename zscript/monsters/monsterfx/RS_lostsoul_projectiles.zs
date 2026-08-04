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


// ============================================================================
// CHP 05 REBUILD ADDITIONS
// Ported for the RS_LostSoul rebuild from Colourful Hell Plus DECORATE/05/*
// (CH decorate/lostsouls.txt, Archviles.txt, Revenants.txt fill in the
// parents CHP inherits from). Suffix _C stripped, RS_ prefixed.
// ============================================================================

// ---------- T02 BLUE: "psychic" hitscan puff (CH PsychPuff + CHP VSpeed) ----
class RS_PsychPuff : Actor
{
	Default
	{
		+NOBLOCKMAP +NOGRAVITY +ALLOWPARTICLES +RANDOMIZE
		RenderStyle "Translucent"; Alpha 0.5; VSpeed 1; Mass 5; Scale 0.3;
	}
	States
	{
	Spawn:
		PLSE A 4 Bright;
		PLSE B 4;
	Melee:
		PLSE CDE 4;
		Stop;
	}
}

// ---------- T03 CYAN: the two orbiting eye satellites ----------
class RS_CyanSoulEye : Actor
{
	Default
	{
		Radius 40; Height 70; Speed 1; Scale 0.2; Projectile;
		+NOINTERACTION; +NOCLIP;
		Translation "0:255=%[0.50,0.00,0.00]:[2.00,0.49,0.49]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Live;
	Live:
		BFE1 C 1 Bright { A_Warp(AAPTR_TARGET, 9, -11, 37, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE|WARPF_COPYVELOCITY); }
		BFE1 B 1 Bright { A_Warp(AAPTR_TARGET, 9, -11, 37, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE|WARPF_COPYVELOCITY); }
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
class RS_CyanSoulEye2 : RS_CyanSoulEye
{
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Live;
	Live:
		BFE1 C 1 Bright { A_Warp(AAPTR_TARGET, 9, 11, 37, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE|WARPF_COPYVELOCITY); }
		BFE1 B 1 Bright { A_Warp(AAPTR_TARGET, 9, 11, 37, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE|WARPF_COPYVELOCITY); }
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}

// ---------- T04 PURPLE: the phantom's psychic ring ----------
class RS_PsychicRingLS : FastProjectile
{
	Default
	{
		Radius 13; Height 16; Speed 10; Scale 0.3;
		Damage 7; DamageType "Plasma"; Projectile;
		RenderStyle "Add"; Alpha 0.5;
		Translation "0:255=252:252";
	}
	States
	{
	Spawn:
		SSBL IKIKJ 4;
		SSBL KJ 4 { A_SetTranslucent(0.3, 0); }
		Goto Death;
	Death:
		TNT1 A 1;
		Stop;
	}
}

// ---------- T06 ABYSS: the beetle's point-blank "leave me alone" burst ----
class RS_Canyouleavemealonealready : Actor
{
	Default
	{
		Radius 8; Height 16; Speed 14; FastSpeed 26; Scale 0.75;
		Species "Demon1"; Damage 14; DamageType "Melee"; Projectile;
		+DONTHARMCLASS; +DONTHARMSPECIES;
		RenderStyle "Add"; Alpha 0.25;
		Translation "168:191=112:127";
	}
	States
	{
	Spawn:
		BAL1 A 1 Bright;
		BAL1 CDE 2 Bright { A_Explode(random(1, 7), 32, 0); }
		Stop;
	Death:
		BAL1 CDE 2 Bright { A_Explode(random(1, 7), 32, 0); }
		Stop;
	}
}

// ---------- T08 BROWN CUBE: the roving resurrector ring ----------
// CH's ArchRingHelp: an invisible A_VileChase walker that raises corpses
// along its path, then expires.
// [dedupe] duplicate class RS_ArchRingHelp removed -- defined earlier in the load order.

// ---------- T09 GRAY HIVE / T11 QUEEN BEE: the bee itself ----------
// CHP CommonBlackLsoul2 (05_K) over CH BlackLSoul2. A real 18 HP escort
// monster, not a projectile -- the hive sows them and the Queen calls them.
class RS_BlackLSoul2 : Actor
{
	Default
	{
		Health 18; Species "HORNET";
		Radius 14; Height 26; Mass 30; Speed 18; PainChance 255; Scale 0.5;
		DamageFactor "fire", 0.2;
		DamageFactor "plasma", 0.4;
		MaxTargetRange 256;
		BloodColor "Yellow";
		DeathSound "Hornet/Death";
		Monster;
		+FLOAT +THRUSPECIES +NOGRAVITY +FLOATBOB +NOBLOODDECALS
		+DONTHARMCLASS +SPAWNFLOAT +DONTOVERLAP
		-NORADIUSDMG
		-COUNTKILL
		Obituary "%o couldn't take a little sting";
		Tag "Bee";
	}
	States
	{
	Spawn:
		WASP A 0 NoDelay { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		WASP AB 2 { A_Look(); }
		Loop;
	See:
		WASP A 0 { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		WASP A 0 A_JumpIfCloser(256, "Dodge");
		WASP AB 2 { A_Chase(); }
		Loop;
	Dodge:
		WASP A 0 { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		WASP A 1 { A_FastChase(); }
		WASP A 1 { A_FaceTarget(); }
		WASP B 1 { A_FastChase(); }
		WASP B 1 { A_FaceTarget(); }
		Goto See;
	Missile:
		WASP A 0 { A_StartSound("Hornet/Fly", 7, CHANF_LOOPING); }
		WASP A 2 { A_FaceTarget(); }
		WASP B 2 { A_SkullAttack(30); }
		WASP B 10 A_JumpIfCloser(16, "Melee");
		WASP B 10 A_CheckFloor("Death");
		WASP B 10 A_JumpIfCloser(16, "Melee");
		WASP B 10 A_CheckFloor("Death");
		WASP B 10 A_JumpIfCloser(16, "Melee");
		WASP B 10 A_CheckFloor("Death");
		WASP B 10 A_JumpIfCloser(16, "Melee");
		WASP B 10 A_CheckFloor("Death");
		WASP B 10 A_JumpIfCloser(16, "Melee");
		WASP B 10 A_CheckFloor("Death");
		WASP B 10 A_JumpIfCloser(16, "Melee");
		WASP B 10 A_CheckFloor("Death");
		Goto See;
	Melee:
		WASP A 5 { A_FaceTarget(); }
		WASP B 3 { A_CustomMeleeAttack(random(1, 2), "GENTLES1"); }
		Goto See;
	Death:
		WASP C 1 { bNOGRAVITY = false; bDONTFALL = false; bFLOATBOB = false; }
		WASP C 1 { A_StopSound(7); }
		WASP C 0 { A_ScreamAndUnblock(); }
	Fall:
		WASP C 1 A_CheckFloor("Splat");
		Loop;
	Splat:
		WASP D 1 { A_Stop(); }
		WASP D 1 { A_StartSound("Hornet/Splat"); }
		WASP D 64;
		WASP D 1 { A_SetTranslucent(0.9); }
		WASP D 1 { A_SetTranslucent(0.8); }
		WASP D 1 { A_SetTranslucent(0.7); }
		WASP D 1 { A_SetTranslucent(0.6); }
		WASP D 1 { A_SetTranslucent(0.5); }
		WASP D 1 { A_SetTranslucent(0.4); }
		WASP D 1 { A_SetTranslucent(0.3); }
		WASP D 1 { A_SetTranslucent(0.2); }
		WASP D 1 { A_SetTranslucent(0.1); }
		Stop;
	}
}

// ---------- T11 QUEEN BEE: the body-hugging aura ----------
class RS_BLSoulFX : Actor
{
	Default
	{
		Radius 40; Height 70; Speed 1; Scale 0.33; Projectile;
		+NOINTERACTION; +NOCLIP;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Live;
	Live:
		BBOM B 1 Bright { A_Warp(AAPTR_MASTER, -2, 0, -12, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE|WARPF_COPYVELOCITY); }
		BBOM B 0 Bright { A_SetScale(0.33, 0.33); }
		BBOM B 1 Bright { A_Warp(AAPTR_MASTER, -2, 0, -12, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE|WARPF_COPYVELOCITY); }
		BBOM B 0 Bright { A_SetScale(0.38, 0.38); }
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}

// ---------- T12 MIMIC, revenant form: the CHP tracer + the hatching egg ---
class RS_RevenantTracer : Actor
{
	Default
	{
		Radius 11; Height 8; Speed 10; Damage 5; Projectile;
		+SEEKERMISSILE; +RANDOMIZE;
		RenderStyle "Add"; Alpha 1;
		SeeSound "skeleton/attack"; DeathSound "skeleton/tracex";
	}
	States
	{
	Spawn:
		FATB AB 2 Bright { A_Tracer(); }
		Loop;
	Death:
		FBXP AB 8 Bright;
		FBXP C 4 Bright;
		Stop;
	}
}
class RS_RevEgg : Actor
{
	Default
	{
		Health 50; Radius 20; Height 32; Species "whitelsoul";
		Monster;
		+NOPAIN +NOTARGET +FLOAT +FLOATBOB +NOGRAVITY +LOOKALLAROUND +NOBLOOD
		-COUNTKILL
		Speed 3; Alpha 0.95; Scale 2;
		Translation "168:191=80:95", "208:223=80:95", "224:231=4:4", "232:235=94:94";
	}
	States
	{
	Spawn:
		BAL1 AB 4 { A_Look(); }
		Loop;
	See:
		BAL1 A 16 { A_StartSound("skeleton/sight", CHAN_VOICE); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 C 2 { A_PainAttack("RS_Revenant", 0, PAF_NOSKULLATTACK); }
		Goto Death;
	Death:
		BAL1 DE 3 Bright;
		Stop;
	}
}

// ---------- T12 MIMIC, baron form: CHP's own baron ball + the HK egg -----
// [dedupe] duplicate class RS_BaronBall removed -- defined earlier in the load order.
class RS_HKEgg : RS_RevEgg
{
	States
	{
	Spawn:
		BAL1 AB 4 { A_Look(); }
		Loop;
	See:
		BAL1 A 16 { A_StartSound("Knight/sight", CHAN_VOICE); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 C 2 { A_PainAttack("RS_HellKnight", 0, PAF_NOSKULLATTACK); }
		Goto Death;
	Death:
		BAL1 DE 3 Bright;
		Stop;
	}
}

// ---------- T12 MIMIC, arch-vile form: the wound flash + the spawner orb --
// [dedupe] duplicate class RS_BlueGash removed -- defined earlier in the load order.
// [dedupe] duplicate class RS_ArchSpawnerOrb removed -- defined earlier in the load order.


// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * SBSI -> SBS1 (typo in source; next line already used SBS1)  (1 occurrence)
//   * CHP 05 additions: A_Burst("IceChunk_C") -> stock "IceChunk"; CHP's
//     _C subclass is an empty passthrough of GZDoom's own IceChunk.
//   * RS_ArchRingHelp keeps CH's A_RadiusGive("GrowRaisin") as
//     RS_GrowRaisin (ported in RS_demon_projectiles.zs) -- it is the
//     marker RS_Demon's Raise checks to come back one colour up.
//   * RS_ArchSpawnerOrb drops CH's "RandomizerArc" drop-spawner line (a
//     RandomSpawner over ~40 CH-named monster classes that do not exist
//     here). The ArchvileFire it fires alongside is kept.
