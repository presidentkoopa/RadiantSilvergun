// =====================================================================
// RS_demon_projectiles.zs
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
// hf_demon_projectiles.zs -- Pinky/Demon projectiles (color ladder).
// Pinky is mostly a melee charger; only a few colors fire. Shares RS_MolochQuake,
// RS_WDRock1, RS_WDRock3 (from Cyberdemon/Caco). Damage->constants.
// ============================================================================

// ---------- YELLOW: lightning zap (LITN) ----------
class RS_ZapZapCB : Actor
{
	Default { Speed 1; Projectile; +RANDOMIZE; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.65; Scale 1; Damage 15; Translation "0:255=#[255,255,0]"; }
	States { Spawn: LITN ABCDEFGOPABCDEFGOP 1 Bright A_Explode(10,48); Goto Death; Death: LITN A 2 Bright; Stop; }
}

// ---------- ABYSS: "Hell Hound" seeking fire (FRFX) ----------
class RS_AbyssDogFire : Actor
{
	Default { Radius 4; Height 3; Speed 18; Damage 30; Projectile; +SEEKERMISSILE; DamageType "Fire"; RenderStyle "Add"; Alpha 1; XScale 1.4; YScale 0.5;
		SeeSound "hellhound/attack"; DeathSound "hellhound/shotx"; Translation "Ice"; }
	States { Spawn: FRFX AB 3 Bright A_SeekerMissile(4,4); Loop; Death: FRFX CDE 4 Bright A_Explode(30,48); Stop; }
}

// ---------- BROWN: kickback orb (BAL1) ----------
class RS_BrownOrbDemon : Actor
{
	Default { Radius 3; Height 3; Speed 28; ProjectileKickBack 2000; Mass 100; Species "Demon1"; Damage 22; Projectile; DamageType "Fire"; +MTHRUSPECIES; +RANDOMIZE;
		RenderStyle "Add"; SeeSound "imp/attack"; DeathSound "imp/shotx"; Translation "0:255=%[0.31,0.23,0.18]:[1.10,0.74,0.40]"; }
	States { Spawn: BAL1 AB 3 Bright; Loop; Death: BAL1 CDE 4 Bright A_Explode(22,48); Stop; }
}

// ---------- RED: blood bolts (BAL1 / falling BLUD) ----------
class RS_RedDemonBloodBolt1 : Actor
{
	Default { Radius 7; Height 7; Mass 5; Speed 19; Projectile; Scale 0.95; RenderStyle "Add"; Damage 16; DamageType "Fire"; Alpha 0.95;
		SeeSound "imp/attack"; DeathSound "imp/shotx"; Translation "0:255=%[0.60,0.00,0.00]:[2.00,0.30,0.30]"; }
	States
	{
	Spawn:
		BAL1 AB 3 Bright A_SpawnItemEx("RS_RedDemonBloodBolt3",0,0,0,0,0,0,random(0,360));
		Loop;
	Death:
		BAL1 CDE 4 Bright A_Explode(16,48);
		Stop;
	}
}
class RS_RedDemonBloodBolt3 : Actor
{
	Default { Speed 15; Alpha 0.75; RenderStyle "Translucent"; Projectile; -NOGRAVITY; Mass 5; Gravity 0.2; DamageType "Fire"; Damage 3; Scale 0.95;
		Translation "0:255=%[0.60,0.00,0.00]:[2.00,0.30,0.30]"; }
	States { Spawn: BLUD AB 4; Loop; Death: SPRY ABC 4; Stop; }
}

// ---------- WHITE: "Juggernaut" -- MolochQuake + rocks (shared RS_MolochQuake/WDRock) ----------
// (RS_MolochQuake, RS_WDRock1, RS_WDRock3 already defined. WDRock2 below.)
class RS_WDRock2 : Actor
{
	Default { Radius 8; Height 8; Speed 5; FloatSpeed 6; +FLOAT; +NOGRAVITY; +NOCLIP; Scale 1.2; }
	States { Spawn: JUBD A 0; Fly: JUBD ABCD 3 Bright; Loop; Death: JUBD D 1; Stop; }
}

// ---------- BLACK: "Butcher" -- hammer melee (BRHM) ----------
class RS_ButcherHammer : Actor
{
	Default { Radius 8; Height 8; Speed 24; Damage 40; Projectile; DamageType "Melee"; +THRUGHOST; +FORCEPAIN; RenderStyle "Add"; Alpha 0.9; Scale 1.1;
		SeeSound "butcher/melee"; DeathSound "butcher/hit"; }
	States { Spawn: BRHM AB 3 Bright; Loop; Death: BRHM CDE 4 Bright A_Explode(40,48); Stop; }
}

// ---------- GRAY: leech-worm bite (WormLewd) ----------
class RS_WormLewd : Actor
{
	Default { Radius 8; Height 16; Speed 14; FastSpeed 26; Scale 0.75; Species "Demon1"; Damage 14; DamageType "Melee"; Projectile; +DONTHARMCLASS; +DONTHARMSPECIES;
		RenderStyle "Add"; Alpha 0.25; Translation "168:191=112:127"; }
	States { Spawn: BAL1 A 1 Bright; Goto Death; Death: BAL1 CDE 2 Bright A_Explode(5,32,0); Stop; }
}

// ============================================================================
// CHP 06 REBUILD ADDITIONS
// Ported for the RS_Demon rebuild from Colourful Hell Plus DECORATE/06/*
// (CH decorate/Demons.txt, Hellknights.txt and CH/DECORATE.txt fill in the
// parents CHP inherits from). Suffix _C stripped, RS_ prefixed.
// ============================================================================

// ---------- T01 GREEN: the gas-bag pop that ends its XDeath ----------
class RS_GreenDEDSmoke : Actor
{
	Default
	{
		Radius 10; Height 42;
		+DONTGIB; +NOGRAVITY;
		DamageType "Fire";
		DeathSound "world/barrelx";
		Translation "128:143=113:127", "144:151=118:127", "168:191=113:127",
			"208:223=112:121", "232:235=120:125", "121:127=0:0";
		Scale 0.9;
	}
	States
	{
	Spawn:
		MISL A 0 { A_StartSound("world/barrelx", CHAN_BODY); }
		Goto Death;
	Death:
		MISL B 8 Bright { A_Explode(random(5, 10), 42); }
		MISL C 6 Bright { A_StartSound("world/barrelx", CHAN_BODY); }
		MISL D 4 Bright;
		Stop;
	}
}

// ---------- T08 BROWN: the after-image left by the fiend's dash ----------
class RS_BrownDemonGhost : Actor
{
	Default
	{
		+NOBLOCKMAP; +NOGRAVITY; +NOCLIP;
		RenderStyle "Translucent"; Alpha 0.33;
	}
	States
	{
	Spawn:
		IFIN ABCD 6 Bright;
		Goto Death;
	Death:
		TNT1 A 0 { A_Stop(); }
		IFIN G 1 Bright { A_NoBlocking(); }
		IFIN G 1 Bright { A_SetScale(0.8, 0.8); }
		IFIN G 1 Bright { A_SetScale(0.6, 0.6); }
		IFIN G 1 Bright { A_SetScale(0.3, 0.2); }
		IFIN G 1 Bright { A_SetScale(0.1, 0.1); }
		Stop;
	}
}

// ---------- T11 BUTCHER: the pet hound and its fire breath ----------
class RS_DogFire : FastProjectile
{
	Default
	{
		Radius 2; Height 4; Speed 16; Damage 1; Projectile;
		RenderStyle "Add"; DamageType "Fire"; Alpha 0.67; Scale 0.67;
		SeeSound "weapons/bigbrn"; DeathSound "weapons/bigbrn";
		+DONTHURTSHOOTER; +THRUGHOST;
	}
	States
	{
	Spawn:
		TNT1 A 2 Bright;
		FRFX ABCD 2 Bright { A_Explode(1, 8); }
		FRFX D 0 Bright { A_LowGravity(); }
		FRFX EFG 2 Bright { A_Explode(1, 16); }
		FRFX HIJ 2 Bright { A_Explode(1, 32); }
		FRFX KLM 2 Bright { A_Explode(1, 64); }
		FRFX NO 2 Bright;
		Stop;
	Death:
		FRFX HIJ 2 Bright { A_Explode(1, 32); }
		FRFX KLM 2 Bright { A_Explode(1, 64); }
		FRFX NO 2 Bright;
		Stop;
	}
}
class RS_WHOLETTHEDOGSOUT : Actor
{
	Default
	{
		Health 120; PainChance 128; Speed 19;
		Radius 30; Height 50; Mass 500; MeleeDamage 7;
		Species "Butcher"; MaxTargetRange 256;
		DamageFactor "Fire", 0.5;
		Monster;
		+FLOORCLIP +DONTHURTSPECIES +THRUSPECIES +NOFEAR
		-COUNTKILL
		SeeSound "monster/dogsit";
		AttackSound "monster/dogatk";
		MeleeSound "monster/dogbit";
		PainSound "monster/dogpai";
		DeathSound "monster/dogdth";
		ActiveSound "monster/dogact";
		Obituary "%o got burned by the Butchers pet hounds";
		HitObituary "A Butchers pet hound enjoyed %o for dinner.";
		Tag "DOGE";
	}
	States
	{
	Spawn:
		HDOG A 10 { A_Look(); }
		Loop;
	See:
		HDOG AAAABBBBCCCCDDDDEEEEFFFF 1 { A_Chase(); }
		Loop;
	Melee:
		HDOG GH 6 { A_FaceTarget(); }
		HDOG I 6 { A_MeleeAttack(); }
		Goto See;
	Missile:
		HDOG G 10 { A_FaceTarget(); }
		HDOG HHHHHHHHHHHH 1 { A_SpawnProjectile("RS_DogFire", 28, 0, 0, 0, 0); }
		HDOG I 6;
		Goto See;
	Pain:
		HDOG J 2;
		HDOG J 2 { A_Pain(); }
		Goto See;
	Death:
		HDOG K 8;
		HDOG L 8 { A_Scream(); }
		HDOG M 4;
		HDOG N 4 { A_NoBlocking(); }
		HDOG OP 4;
		HDOG Q -1;
		Stop;
	Raise:
		HDOG QPONMLK 5;
		Goto See;
	}
}

// ---------- T12 JUGGERNAUT: the meteor telegraph ----------
// The circle-drawers orbit the strike point; the strike itself is the
// Juggernaut warping overhead and slamming down (see Missile.T12.Meteor).
// CHP's drawers are +INVISIBLE, so the CDW2 frame they name is carried on
// TNT1 here -- nothing renders from it either way.
class RS_CircleDrawMeteorCH : FastProjectile
{
	protected int rsRingAngle;
	Default
	{
		Radius 1; Height 1; Speed 255; Projectile;
		+INVISIBLE; +NOCLIP;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		TNT1 A 1 { A_Warp(AAPTR_MASTER, 88, 0, 1, rsRingAngle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		TNT1 AAAA 0 { A_SpawnParticle(0xFFA500, SPF_FULLBRIGHT|SPF_RELATIVE, random(90, 120), random(11, 13), 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0.98, -1, 0); }
		TNT1 A 0 { rsRingAngle += 7; }
		Loop;
	}
}
class RS_CircleDrawMeteorCH2 : RS_CircleDrawMeteorCH
{
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		TNT1 A 1 { A_Warp(AAPTR_MASTER, -88, 0, 1, rsRingAngle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		TNT1 AAAA 0 { A_SpawnParticle(0xFFA500, SPF_FULLBRIGHT|SPF_RELATIVE, random(90, 120), random(11, 13), 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0.98, -1, 0); }
		TNT1 A 0 { rsRingAngle += 7; }
		Loop;
	}
}
class RS_CircleDrawMeteorCH3 : RS_CircleDrawMeteorCH
{
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		TNT1 A 1 { A_Warp(AAPTR_MASTER, 0, 88, 1, rsRingAngle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		TNT1 AAAA 0 { A_SpawnParticle(0xFFA500, SPF_FULLBRIGHT|SPF_RELATIVE, random(90, 120), random(11, 13), 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0.98, -1, 0); }
		TNT1 A 0 { rsRingAngle += 7; }
		Loop;
	}
}
class RS_CircleDrawMeteorCH4 : RS_CircleDrawMeteorCH
{
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		TNT1 A 1 { A_Warp(AAPTR_MASTER, 0, -88, 1, rsRingAngle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		TNT1 AAAA 0 { A_SpawnParticle(0xFFA500, SPF_FULLBRIGHT|SPF_RELATIVE, random(90, 120), random(11, 13), 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0.98, -1, 0); }
		TNT1 A 0 { rsRingAngle += 7; }
		Loop;
	}
}
class RS_CircleDrawMeteorCH5 : RS_CircleDrawMeteorCH
{
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		TNT1 A 1 { A_Warp(AAPTR_MASTER, 0, 46, 1, rsRingAngle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		TNT1 AAAA 0 { A_SpawnParticle(0xFFA500, SPF_FULLBRIGHT|SPF_RELATIVE, random(90, 120), random(11, 13), 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0.98, -1, 0); }
		TNT1 A 0 { rsRingAngle += 7; }
		Loop;
	}
}
class RS_CircleDrawMeteorCH6 : RS_CircleDrawMeteorCH
{
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		TNT1 A 1 { A_Warp(AAPTR_MASTER, -46, 0, 1, rsRingAngle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		TNT1 AAAA 0 { A_SpawnParticle(0xFFA500, SPF_FULLBRIGHT|SPF_RELATIVE, random(90, 120), random(11, 13), 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0.98, -1, 0); }
		TNT1 A 0 { rsRingAngle += 7; }
		Loop;
	}
}
class RS_MeteorStrikeCH : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 1; FloatSpeed 1;
		+NOCLIP;
		DeathSound "Juggernaut/Attack";
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Death;
	Death:
		TNT1 A 1 { A_Scream(); }
		JUBD A 0 { A_SpawnItemEx("RS_CircleDrawMeteorCH", 88, 0, -3, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		JUBD A 0 { A_SpawnItemEx("RS_CircleDrawMeteorCH2", -88, 0, 0, -3, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		JUBD A 0 { A_SpawnItemEx("RS_CircleDrawMeteorCH3", 0, 88, -3, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		JUBD A 0 { A_SpawnItemEx("RS_CircleDrawMeteorCH4", -88, 0, 0, -3, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		JUBD A 0 { A_SpawnItemEx("RS_CircleDrawMeteorCH5", 0, 46, -3, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		JUBD A 0 { A_SpawnItemEx("RS_CircleDrawMeteorCH6", -46, 0, 0, -3, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		CHTA A 1 Bright { A_SpawnItemEx("RS_CircleDrawMeteorCH5", 0, 46, -3, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_CircleDrawMeteorCH6", -46, 0, 0, -3, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		CHTA A 1 Bright { A_SpawnItemEx("RS_CircleDrawMeteorCH5", 0, 46, -3, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_CircleDrawMeteorCH6", -46, 0, 0, -3, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		CHTA A 10 Bright;
		TNT1 A 1 Bright;
		TNT1 A 0 { A_KillChildren("extreme", KILS_FOILINVUL|KILS_KILLMISSILES); }
		Stop;
	}
}

// ---------- shared tokens the demon ladder needs ----------
// CH's GrowRaisin: the arch-vile resurrection marker that lets a raised
// demon come back one colour up. RS_ArchRingHelp hands it out.
class RS_GrowRaisin : Inventory { Default { Inventory.MaxAmount 1; } }
// CH's HKEXProtect: the brown fiend's dash armour.
class RS_HKEXProtect : PowerProtection { Default { DamageFactor 0.6; Powerup.Duration -7; } }

// --- IMPORT NOTES (CHP 06) ----------------------------------------
//   * CH_Cirno_C (T03's death easter-egg spawn) is referenced all over
//     CH/CHP but DEFINED NOWHERE in either tree -- that one cosmetic
//     A_SpawnItemEx line is dropped, not substituted.
//   * BrownImpCommand (T08's death radiusgive) is a CustomInventory whose
//     only body is ACS_NamedExecuteAlways("BrownImpCommand") -- stripped
//     with the rest of the ACS.
