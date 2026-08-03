// =====================================================================
// RS_pe_projectiles.zs
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
// hf_pe_projectiles.zs -- Pain Elemental projectiles (color ladder).
// PEs spawn Lost Souls (A_PainAttack -> stock Lost Souls); the colored-soul flavor
// (CH_Soul/colored LSoul variants) is folded -> cosmetic pass. Per-color projectiles
// below. Shares RS_HKRedDeath. Black overlord body-part cosmetics folded. Damage->const.
// ============================================================================

// ---------- BLUE: seeking plasma ----------
class RS_PlasmaPE : Actor
{
	Default { Radius 8; Height 16; Speed 14; FastSpeed 26; Damage 16; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.85; Scale 0.8;
		SeeSound "spell/spellcast1"; DeathSound "weapons/plasmax"; }
	States
	{
	Spawn:
		PLSE AB 4 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		PLSE BCDE 4 Bright;
		Stop;
	}
}

// ---------- CYAN: bouncing ice orbs ----------
class RS_IceOrbCyanAra1 : Actor
{
	Default { Radius 8; Height 8; Speed 20; Damage 27; DamageType "Ice"; Projectile; +SEEKERMISSILE; +BOUNCEONFLOORS; +USEBOUNCESTATE; RenderStyle "Add";
		BounceType "Doom"; BounceCount 7; BounceFactor 1.25; WallBounceFactor 1.25; Alpha 0.85; Scale 1.5; Gravity 0.5; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; }
	States
	{
	Spawn:
		ICEY AB 3 Bright A_SeekerMissile(2,2);
		Loop;
	Death:
		ICEY CDE 4 Bright A_Explode(27,64);
		Stop;
	}
}
class RS_IceOrbCyanAra2 : RS_IceOrbCyanAra1 { Default { Speed 14; Scale 1.0; } }

// ---------- YELLOW: bouncing lava balls ----------
class RS_LavaballPE : Actor
{
	Default { Radius 8; Height 8; Speed 17; Damage 35; DamageType "Fire"; Scale 1.0; Projectile; RenderStyle "Add"; Alpha 0.95; +THRUGHOST;
		SeeSound "weapons/firmfi"; DeathSound "weapons/firex3"; BounceType "Doom"; BounceCount 3; WallBounceFactor 1.25; }
	States
	{
	Spawn:
		BAL3 AB 4 Bright;
		Loop;
	Death:
		BAL3 CDE 4 Bright A_Explode(35,80);
		Stop;
	}
}

// ---------- FIREBLU: explosive blue boom ----------
class RS_BoomPEBlu : Actor
{
	Default { Radius 6; Height 16; Speed 25; Projectile; DamageType "Fire"; Damage 37; RenderStyle "Add"; Translation "208:223=197:207"; DeathSound "weapons/rocklx"; Alpha 0.75; }
	States
	{
	Spawn:
		MISL B 4 Bright;
		Goto Death;
	Death:
		MISL CD 4 Bright A_Explode(37,96);
		MISL E 4 Bright;
		Stop;
	}
}

// ---------- BROWN: flesh shot (BAL7 tinted) ----------
class RS_BrownPEShot : Actor
{
	Default { Radius 6; Height 14; Speed 18; Damage 27; DamageType "Plasma"; Projectile; +RANDOMIZE; SeeSound "baron/attack"; DeathSound "baron/shotx";
		Translation "0:255=%[0.00,0.00,0.31]:[0.20,0.20,2.00]"; }
	States
	{
	Spawn:
		BAL7 AB 4 Bright A_SpawnItemEx("RS_Splash11",0,0,3,0,0,0,random(0,360));
		Loop;
	Death:
		BAL7 CDE 6 Bright A_Explode(27,48);
		Stop;
	}
}

// ---------- ABYSS: coil seekers + pulse + volley (AYPE) ----------
class RS_AbyPECoil : Actor
{
	Default { Radius 6; Height 6; Speed 12; Damage 50; DamageType "Melee"; Projectile; +RANDOMIZE; +THRUACTORS; +SEEKERMISSILE; Scale 0.3;
		SeeSound "baron/attack"; DeathSound "weapons/rocklx"; Translation "Ice"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		AYPE AB 2 Bright A_SeekerMissile(4,4);
		Loop;
	Death:
		AYPE CDE 4 Bright A_Explode(50,64);
		Stop;
	}
}
class RS_AbyssPEPulse : Actor
{
	Default { Speed 11; Damage 2; DamageType "Plasma"; Radius 10; Height 4; RenderStyle "Translucent"; Alpha 0.1; Species "PE"; Translation "Ice"; Projectile;
		+THRUACTORS; +DROPOFF; +FORCERADIUSDMG; +BLOODLESSIMPACT; +RIPPER; +FORCEPAIN; }
	States
	{
	Spawn:
		AYPE AAAA 6 A_Explode(4,96,0);
	Death:
		AYPE B 4 Bright;
		Stop;
	}
}
class RS_VollreyAbyPE : Actor
{
	Default { Radius 6; Height 8; Speed 27; FastSpeed 38; Damage 22; DamageType "Plasma"; Projectile; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.75; Scale 0.55;
		SeeSound "Forgotten/Attack"; DeathSound "spell/Impact1"; Translation "Ice"; }
	States
	{
	Spawn:
		AYPE AB 2 Bright A_SeekerMissile(4,4);
		Loop;
	Death:
		AYPE CDE 4 Bright A_Explode(22,48);
		Stop;
	}
}

// ---------- RED: corpse breath + spike bomb (TORT/MISL) ----------
class RS_CorpseBreathPE : Actor
{
	Default { Radius 18; Height 18; Speed 15; Damage 8; DamageType "Melee"; Projectile; +THRUACTORS; -NOGRAVITY; +BOUNCEONFLOORS; RenderStyle "Add";
		BounceType "Doom"; BounceCount 3; BounceFactor 0.8; Gravity 0.24; Alpha 0.85; Scale 0.8; }
	States
	{
	Spawn:
		FRGO ABCD 4 Bright;
		Loop;
	Death:
		FRGO EF 4 Bright A_Explode(8,48);
		Stop;
	}
}
class RS_SbombPE : Actor
{
	Default { Radius 20; Height 20; Mass 600; Speed 9; Damage 30; DamageType "Plasma"; Projectile; Scale 2; RenderStyle "Add"; Alpha 0.95;
		SeeSound "Spell/spellCast1"; DeathSound "Crack/death"; Translation "208:223=176:191","224:231=176:176"; }
	States
	{
	Spawn:
		BAL1 AB 3 Bright;
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(60,128);
		Stop;
	}
}

// ---------- BLACK: the "Overlord" PE (OVER body) -- over-balls, storm shots,
//            hades balls, bee-swarms. Body-part cosmetics folded. ----------
class RS_HadesBall4 : Actor
{
	Default { Radius 6; Height 8; Speed 15; Damage 8; DamageType "Plasma"; Projectile; +THRUGHOST; +FORCEXYBILLBOARD; RenderStyle "Add"; Alpha 0.8;
		SeeSound "Monster/hadtel"; DeathSound "Monster/hadsit"; Decal "CacoScorch"; }
	States { Spawn: HEFX AB 4 Bright; Loop; Death: HEFX CDE 5 Bright A_Explode(8,64); Stop; }
}
class RS_OverBall3 : Actor
{
	Default { Radius 10; Height 20; Speed 15; Damage 8; DamageType "Plasma"; ExplosionDamage 32; ExplosionRadius 32; Projectile; RenderStyle "Add"; Alpha 0.75;
		Translation "192:207=168:191"; +THRUGHOST; +FORCEXYBILLBOARD; DeathSound "weapons/devzap"; }
	States { Spawn: BBOM AB 4 Bright; Loop; Death: BBOM CDE 4 Bright A_Explode(32,64); Stop; }
}
class RS_StormShot1 : Actor
{
	Default { Radius 12; Height 6; Speed 30; Damage 90; Projectile; RenderStyle "Add"; Alpha 0.80; DamageType "Plasma"; +THRUGHOST; +NODAMAGETHRUST; +FORCEXYBILLBOARD; DeathSound "weapons/devexp"; }
	States { Spawn: LFX1 STUVW 1 Bright; Loop; Death: LFX1 XY 3 Bright A_Explode(90,128); Stop; }
}
class RS_BEESHOT : Actor
{
	// bee-swarm: invisible carrier that releases stinging motes (Lost-Soul-spawn folded to motes)
	Default { Radius 12; Height 6; Speed 12; Damage 0; Projectile; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.80; DamageType "Plasma"; }
	States
	{
	Spawn:
		LFX1 S 2 Bright A_SeekerMissile(3,3);
		LFX1 SS 2 Bright A_SpawnItemEx("RS_BeeMotePE",random(-12,12),random(-12,12),random(-8,8),random(-3,3),random(-3,3),0,random(0,360));
		Loop;
	Death:
		LFX1 S 2 Bright;
		Stop;
	}
}
class RS_BeeMotePE : Actor
{
	Default { Radius 3; Height 3; Speed 14; Damage 6; DamageType "Plasma"; Projectile; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.85; Scale 0.4; Translation "192:207=168:191"; }
	States { Spawn: WASP AB 3 Bright A_SeekerMissile(5,5); Loop; Death: WASP C 3 Bright; Stop; }
}
class RS_LoadPE3 : Actor
{
	Default { Radius 1; Height 1; +NOCLIP; +NOGRAVITY; +NOINTERACTION; RenderStyle "Add"; Alpha 0.9; SeeSound "Weapons/BFGF"; }
	States { Spawn: DLIT ABCDE 3 Bright; Stop; }
}

// ---------- WHITE: holy seekers (reuses RS_HKRedDeath) + sentinel spawner folded ----------
// (White's MiniSentinelPE/BufferWhitePE/HealthFountain summons folded -> cosmetic/gameplay flag.
//  HKRedDeath already defined; White uses it directly.)
