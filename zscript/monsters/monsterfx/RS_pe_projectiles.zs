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

// =====================================================================
// CHP FAMILY 10 IMPORT (rebuild pass). Everything CHP's pain elementals
// call that had no RS_ port yet. Ported from
// E:\New folder\ART SOURCE\CHP\DECORATE\10\ (CH parents where CHP only
// tweaks a property).
// =====================================================================

// ---------- T01 GREEN: the gas cloud it sows at close range ----------
class RS_Gas13 : Actor
{
	Default
	{
		Radius 6; Height 16; Speed 0; FastSpeed 0;
		Projectile; +RANDOMIZE; RenderStyle "Add";
		DamageType "Poison"; Scale 0.8; Alpha 0.6;
	}
	States
	{
	Spawn:
		PSBG CDEFGHGF 4 Bright { A_Explode(random(6, 12), 42); }
		PSBG G 0 Bright A_Jump(56, "Death");
		Loop;
	Death:
		PSBG CDEFGHI 6 Bright { A_Explode(random(6, 12), 42); }
		Stop;
	}
}

// ---------- T04 PURPLE: the heavy seeking bomb and the light triple --
class RS_PurplePE1 : FastProjectile
{
	Default
	{
		Radius 8; Height 10; Speed 24; FastSpeed 24; Mass 23; Gravity 0.3;
		Damage 28;
		Projectile; +RANDOMIZE; +EXPLODEONWATER; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.88; Scale 1.0;
		SeeSound "caco/attack"; DeathSound "Bomb/boom";
		Translation "168:191=250:254";
	}
	States
	{
	Spawn:
		SBS1 ABCD 6 Bright { A_SeekerMissile(3, 3); }
		Loop;
	Death:
		SBS4 DE 6 Bright { A_SetTranslucent(0.4); }
		SBS4 FGH 6 Bright { A_Explode(random(5, 38), 88); }
		Stop;
	}
}
class RS_PurplePE2 : FastProjectile
{
	Default
	{
		Radius 8; Height 10; Speed 28; FastSpeed 50; Mass 23; Gravity 0.3;
		Damage 15;
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.65; Scale 0.75;
		SeeSound "caco/attack"; DeathSound "holy/holy2";
		Translation "168:191=250:254", "208:223=250:252", "128:143=250:252",
		            "64:79=251:254", "160:167=251:251", "48:63=250:251";
	}
	States
	{
	Spawn:
		SKUL CD 5 Bright;
		Loop;
	Death:
		SKUL C 6 Bright { A_SetTranslucent(0.4); }
		SKUL D 5 { A_SetTranslucent(0.25); }
		SKUL D 4 { A_SetTranslucent(0.1); }
		Stop;
	}
}

// ---------- T05 YELLOW: the weaving firebomb pair ----------
class RS_FirebombPE : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 6;
		Damage 17; DamageType "Fire"; Scale 1.0;
		Projectile; RenderStyle "Add"; Alpha 0.95; +THRUGHOST;
		SeeSound "fire/fire3"; DeathSound "spell/Impact1";
	}
	States
	{
	Spawn:
		SBS1 AA 1 Bright { A_Weave(3, 0, 5.0, 0.0); }
		SBS1 BB 1 Bright { A_Weave(3, 0, 5.0, 0.0); }
		SBS1 CC 1 Bright { A_Weave(3, 0, 5.0, 0.0); }
		SBS1 DD 1 Bright { A_Weave(3, 0, 5.0, 0.0); }
		SBS1 D 0 { A_ScaleVelocity(1.25); }
		Loop;
	Death:
		MISL BCD 3 Bright { A_Explode(random(5, 20), 88); }
		Stop;
	}
}
// Same bomb, weaving the other way -- CHP fires them as a pair so the
// two paths cross.
class RS_FirebombPE2 : RS_FirebombPE
{
	States
	{
	Spawn:
		SBS1 AA 1 Bright { A_Weave(-3, 0, 5.0, 0.0); }
		SBS1 BB 1 Bright { A_Weave(-3, 0, 5.0, 0.0); }
		SBS1 CC 1 Bright { A_Weave(-3, 0, 5.0, 0.0); }
		SBS1 DD 1 Bright { A_Weave(-3, 0, 5.0, 0.0); }
		SBS1 D 0 { A_ScaleVelocity(1.25); }
		Loop;
	}
}

// ---------- T06 ABYSS: the afterimage it leaves while chasing --------
class RS_AbyssPEShadow : Actor
{
	Default { +NOINTERACTION }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		AYPE Y 8;
		AYPE Y 9;
		AYPE YYY 10 { A_FadeOut(0.33); }
		Stop;
	}
}

// ---------- T07 FIREBLU: the silent secondary blast ----------
// RS_BoomPEBlu (above) is the aimed shot; this is the scatter charge it
// carpets the room with -- same body, no soul on death.
class RS_BoomPEBlu2 : RS_BoomPEBlu
{
	States
	{
	Spawn:
		MISL B 4 Bright;
		Goto Death;
	Death:
		MISL CD 4 Bright { A_Explode(random(20, 40), 64, 0); }
		Stop;
	}
}

// ---------- T08 BROWN: the wet trail, the hanging meat, the gibs -----
class RS_SplashBrownPE : Actor
{
	Default
	{
		Radius 3; Height 3; Speed 16;
		Projectile; +RANDOMIZE; +THRUACTORS; -NOGRAVITY; +CLIENTSIDEONLY;
		Scale 0.25;
		Translation "0:255=%[0.00,0.00,0.31]:[0.20,0.20,2.00]";
	}
	States
	{
	Spawn:
		BAL1 AB 12;
		BAL1 A 2 A_Jump(32, "Death");
		Loop;
	Death:
		BAL7 C 1 Bright { A_SetScale(0.6, 0.1); }
		BAL7 CDE 4 Bright;
		Stop;
	}
}
class RS_SplashBrownPE2 : RS_SplashBrownPE
{
	Default { -CLIENTSIDEONLY }
	States
	{
	Spawn:
		BAL1 AB 12;
		BAL1 A 2 A_Jump(32, "Death");
		Loop;
	Death:
		BAL7 A 1 Bright { A_SetScale(0.6, 0.6); }
		BAL7 AB 8 Bright;
		BAL7 A 6 Bright { A_SetScale(0.9, 0.9); }
		BAL7 B 6 Bright { A_SetScale(1.25, 1.25); }
		BAL7 AB 8 Bright { A_Explode(random(2, 12), 32, 0); }
		BAL7 AB 8 Bright { A_Explode(random(2, 12), 32, 0); }
		BAL7 CDE 2 { A_FadeOut(0.25); }
		Stop;
	}
}
class RS_BrownPEded : Actor
{
	Default
	{
		Radius 1; Height 1;
		+NOCLIP +NOGRAVITY +NOINTERACTION
		SeeSound "Crack/death";
		Translation "0:255=%[0.00,0.00,0.31]:[0.20,0.20,2.00]";
		Scale 1.35;
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		HADE IJKL 8 Bright { A_FadeOut(0.15); }
		Stop;
	}
}
class RS_FleshSpawnGib1 : Actor
{
	Default { Speed 8; Mass 100; Radius 1; Height 1; Projectile; -NOGRAVITY; +DROPOFF; Scale 1.5; }
	States { Spawn: FGB1 ABCD 4; Loop; Death: FGB1 E -1; Stop; }
}
class RS_FleshSpawnGib2 : RS_FleshSpawnGib1
{ States { Spawn: FGB2 ABCD 4; Loop; Death: FGB2 I -1; Stop; } }
class RS_FleshSpawnGib2B : RS_FleshSpawnGib1
{ States { Spawn: FGB2 EFGH 4; Loop; Death: FGB2 J -1; Stop; } }
class RS_FleshSpawnGib3 : RS_FleshSpawnGib1
{ States { Spawn: FGB3 ABCD 4; Loop; Death: FGB3 E -1; Stop; } }
class RS_FleshSpawnGib4 : RS_FleshSpawnGib1
{ States { Spawn: FGB4 ABCD 4; Loop; Death: FGB4 I -1; Stop; } }
class RS_FleshSpawnGib4B : RS_FleshSpawnGib1
{ States { Spawn: FGB4 EFGH 4; Loop; Death: FGB4 J -1; Stop; } }
class RS_FleshSpawnGib5 : RS_FleshSpawnGib1
{ States { Spawn: FGB5 ABCD 4; Loop; Death: FGB5 E -1; Stop; } }
class RS_FleshSpawnGib6 : RS_FleshSpawnGib1
{ States { Spawn: FGB6 ABC 4; Loop; Death: FGB6 D -1; Stop; } }
class RS_FleshSpawnGibs : Actor
{
	Default { +NOCLIP }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib1",  14,  0, random(-180, 180), 2, random(10, 40)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib2",   6,  2, random(-180, 180), 2, random(0, 25)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib2B", 10, -2, random(-180, 180), 2, random(0, 25)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib3",   8,  0, random(-180, 180), 2, random(0, 35)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib4",  12,  5, random(-180, 180), 2, random(-5, 40)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib4B",  5, -5, random(-180, 180), 2, random(0, 30)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib5",   6,  3, random(-180, 180), 2, random(10, 60)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib5",   8,  0, random(-180, 180), 2, random(-10, 55)); }
		TNT1 A 0 { A_SpawnProjectile("RS_FleshSpawnGib6",  12,  0, 0, 2, 0); }
		Stop;
	}
}

// ---------- T11 BLACK (the Overlord): storm support + its body parts --
class RS_StormLite1 : Actor
{
	Default
	{
		Radius 6; Height 12; Speed 32; Damage 5;
		Projectile; RenderStyle "Add"; Alpha 0.80; DamageType "Lightning";
		DeathSound "weapons/devzap"; +THRUGHOST; +RIPPER; +FORCEXYBILLBOARD;
	}
	States { Spawn: DLIT ABC 1 Bright; Loop; Death: DLIT DEFGHIJKLMNO 1 Bright; Stop; }
}
// The storm shot's ground burst -- it keeps throwing over-balls out of
// the impact point for a full second.
class RS_StormShotter3 : Actor
{
	Default
	{
		Radius 12; Height 6; Speed 0;
		Projectile; RenderStyle "Add"; Alpha 0.10; DamageType "Plasma";
		+THRUGHOST; +NODAMAGETHRUST; +FORCEXYBILLBOARD;
		DeathSound "weapons/devexp";
	}
	States
	{
	Spawn:
		LFX1 S 0;
		Goto Death;
	Death:
		LFX1 STUVWSTUVWSTUVWSTUVWSTUVWSTUVWSTUVWSTUVWSTUVWSTUVWSTUVWSTUVW 1
			{ A_SpawnProjectile("RS_OverBall3", 0, 0, 0, CMF_AIMOFFSET, random(0, 360)); }
		Stop;
	}
}
class RS_SkullDeathPE : FastProjectile
{
	Default
	{
		Radius 5; Height 7; Speed 32; FastSpeed 38;
		Damage 30; DamageType "Fire";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85; Scale 0.65;
		SeeSound "Forgotten/Attack"; DeathSound "spell/Impact1";
		Translation "76:79=44:47", "136:143=184:191", "128:136=175:183",
		            "64:79=176:191", "208:223=171:181", "161:161=170:170",
		            "144:151=180:191";
	}
	States
	{
	Spawn:
		FRGO C 1 Bright { A_Weave(1, 1, 1, 1); }
		FRGO D 1 Bright;
		Loop;
	Death:
		MISL B 3 Bright { A_SetScale(1.4); }
		MISL C 3 { A_SetTranslucent(0.65); }
		MISL D 3 Bright { A_Explode(random(10, 25), 128); }
		MISL E 5 Bright { A_Explode(random(10, 45), 128); }
		Stop;
	}
}
// The cube. It flies like a brain spit and cracks open into souls.
class RS_SkullBundle3 : FastProjectile
{
	Default
	{
		Radius 6; Height 32; Speed 15; Damage 3;
		Projectile; -ACTIVATEPCROSS; +RANDOMIZE;
		SeeSound "brain/spit"; DeathSound "brain/cubeboom";
	}
	States
	{
	Spawn:
		BOSF A 3 Bright;
		BOSF BCD 3 Bright;
		Loop;
	Death:
		FIRE ABCDEF 2 Bright { A_Fire(); }
		FIRE GGHH 1 { A_PainAttack("RS_LostSoul", random(-180, 180)); }
		FIRE H 0 { A_Scream(); }
		Stop;
	}
}
class RS_OverFlesh1 : Actor
{
	Default { Speed 8; Mass 100; Radius 1; Height 1; Projectile; +THRUGHOST; Gravity 0.125; -NOGRAVITY; }
	States { Spawn: OVF1 ACEGIKM 5; Loop; Death: OVF1 O 3; OVF1 Q -1; Stop; }
}
class RS_OverFlesh2 : RS_OverFlesh1
{ States { Spawn: OVF1 BDFHJLN 5; Loop; Death: OVF1 P 3; OVF1 R -1; Stop; } }
class RS_OverFlesh3 : RS_OverFlesh1
{ States { Spawn: OVF2 ACEG 5; Loop; Death: OVF2 I -1; Stop; } }
class RS_OverFlesh4 : RS_OverFlesh1
{ States { Spawn: OVF2 BDFH 5; Loop; Death: OVF2 J -1; Stop; } }
class RS_OverFlesh5 : RS_OverFlesh1
{ States { Spawn: OVF3 ACEGI 5; Loop; Death: OVF3 K -1; Stop; } }
class RS_OverFlesh6 : RS_OverFlesh1
{ States { Spawn: OVF3 BDFHJ 5; Loop; Death: OVF3 L -1; Stop; } }
class RS_OverBigArm1 : RS_OverFlesh1
{ States { Spawn: OVF4 ACEGI 5; Loop; Death: OVF4 K 3; OVF4 M -1; Stop; } }
class RS_OverBigArm2 : RS_OverFlesh1
{ States { Spawn: OVF4 BDFHJ 5; Loop; Death: OVF4 L 3; OVF4 N -1; Stop; } }
class RS_OverSmallArm1 : RS_OverFlesh1
{ States { Spawn: OVF5 ACEG 5; Loop; Death: OVF5 I -1; Stop; } }
class RS_OverSmallArm2 : RS_OverFlesh1
{ States { Spawn: OVF5 BDFH 5; Loop; Death: OVF5 J -1; Stop; } }
class RS_OverHorn1 : RS_OverFlesh1
{ States { Spawn: OVF6 ACEGI 5; Loop; Death: OVF6 K -1; Stop; } }
class RS_OverHorn2 : RS_OverFlesh1
{ States { Spawn: OVF6 BDFHJ 5; Loop; Death: OVF6 L -1; Stop; } }

// ---------- T12 WHITE (the Watcher): flares, buffs, fountains --------
// The railgun's tracer particle, also the sentinels' flechette.
class RS_DFlarePE : FastProjectile
{
	Default
	{
		Radius 3; Height 3; Speed 25; Damage 15;
		RenderStyle "Stencil"; StencilColor "red"; DamageType "Fire"; Alpha 0.85;
		Projectile; +THRUGHOST; +MTHRUSPECIES; +THRUSPECIES;
		Species "PE";
		SeeSound "weapons/firmfi"; DeathSound "weapons/firex4";
	}
	States
	{
	Spawn:
		VBA3 AB 3 Bright;
		Goto Death;
	Death:
		CBAL CDEFG 3 Bright;
		Stop;
	}
}
// CHP fires the railgun with a null puff so only the trail shows.
class RS_NothinPuff : Actor
{
	Default { +NOBLOCKMAP +NOGRAVITY +NOINTERACTION; RenderStyle "None"; }
	States { Spawn: TNT1 A 1; Stop; }
}
// The Watcher's aura drops. CHP routes rage/hulk/speed through ACS
// buff scripts; with ACS stripped these keep the tell and the one
// radius-give that needs no script.
class RS_BufferWhitePE : Actor
{
	Default
	{
		Radius 6; Height 1; Speed 5;
		+NOTRIGGER +LOOKALLAROUND +NOTARGET +NEVERTARGET +NOCLIP
		RenderStyle "Stencil"; StencilColor "black";
		Scale 0.35; Alpha 0.01; Mass 2;
	}
	States
	{
	Spawn:
		RNGG A 0;
		Goto Death;
	Death:
		RNGG A 6 { A_RadiusGive("Health", 526, RGF_MONSTERS, 15); }
		Stop;
	}
}
class RS_HealthFountainWhitePE : Actor
{
	Default
	{
		Health 50; Radius 16; Height 10;
		Monster;
		-COUNTKILL -ACTIVATEMCROSS
		+NOTRIGGER +LOOKALLAROUND +NOTARGET +NEVERTARGET +NOCLIP
		RenderStyle "Stencil"; StencilColor "green";
		Speed 15; Species "PE"; Scale 0.65; Alpha 0.95; Mass 500;
		BloodColor "green";
	}
	States
	{
	Spawn:
		RNGG A 0;
		Goto See;
	See:
		RNGG A 0 { A_RadiusGive("Health", 252, RGF_MONSTERS, 25); }
		RNGG AB 6 Bright { A_Chase(null, null, CHF_RESURRECT); }
		RNGG CD 6 Bright { A_Wander(); }
		Loop;
	Heal:
		BBOM CDE 2 Bright;
		Goto See;
	}
}
