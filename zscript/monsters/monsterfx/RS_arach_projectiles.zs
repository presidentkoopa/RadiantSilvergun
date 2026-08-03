// =====================================================================
// RS_arach_projectiles.zs
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
// hf_arach_projectiles.zs -- Arachnotron projectiles (Neutral plasma-arc + colors + 2 EX).
// Neutral fires the signature ArachnotronPlasma (bouncing plasma arc). Reuses from earlier
// monsters: RS_PlasmaBallSP3, RS_IceOrbCyanAra1/2, RS_SpiderCyanBomb, RS_AracnorbBall,
// RS_CHBSTarget. Bits/Chunks gib-cosmetics dropped -> cosmetic pass. Damage->constants.
// ============================================================================

// ---------- NEUTRAL: the signature plasma-arc (APLS) ----------
class RS_ArachnotronPlasma : FastProjectile
{
	Default { Radius 13; Height 8; Speed 25; Damage 5; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.75; SeeSound "baby/attack"; DeathSound "baby/shotx"; }
	States
	{
	Spawn:
		APLS AB 5 Bright;
		Loop;
	Death:
		APBX ABCDE 5 Bright;
		Stop;
	}
}

// ---------- GREEN: spider spit (BAL7) ----------
class RS_SpSpit : FastProjectile
{
	Default { Radius 6; Height 16; Speed 20; FastSpeed 30; Damage 29; DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85;
		SeeSound "baron/attack"; DeathSound "weapons/plasmax"; }
	States { Spawn: BAL7 AB 3 Bright; Loop; Death: BAL7 CDE 4 Bright A_Explode(29,48); Stop; }
}

// ---------- BLUE: reuses RS_PlasmaBallSP3 ----------

// ---------- CYAN: reuses RS_IceOrbCyanAra1/2 + RS_SpiderCyanBomb ----------

// ---------- PURPLE: arachnorb corkscrew (reuses RS_AracnorbBall) ----------

// ---------- YELLOW: reuses RS_AracnorbBall ----------

// ---------- ABYSS: holy bolt + ice breath (ABSP) ----------
class RS_AbyssSPBolt : FastProjectile
{
	Default { DamageType "Plasma"; Radius 13; Height 9; Speed 27; Damage 60; Projectile; +RANDOMIZE; +MTHRUSPECIES; +DONTHARMCLASS; RenderStyle "Add"; Alpha 1; Scale 0.5;
		SeeSound "holy3/holy3"; DeathSound "holy2/holy2"; Translation "Ice"; }
	States { Spawn: SSBL ABCDEFGH 2 Bright; Loop; Death: SSBL IJK 4 Bright A_Explode(60,80); Stop; }
}
class RS_AbyssSPBreath : FastProjectile
{
	Default { Radius 12; Height 12; Speed 24; Damage 8; DamageType "Ice"; Projectile; +THRUACTORS; RenderStyle "Add"; Alpha 0.85; Scale 0.75;
		SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY CDE 4 Bright; Stop; }
}

// ---------- FIREBLU: seeking fireblu plasma (4 variants) ----------
class RS_PlasmaBallSPFB1 : FastProjectile
{
	Default { DamageType "Plasma"; Radius 13; Height 8; Speed 20; Damage 3; Projectile; +RANDOMIZE; +MTHRUSPECIES; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.75;
		SeeSound "fire/fire3"; DeathSound "weapons/plasmax";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States { Spawn: APLS AB 4 Bright A_SeekerMissile(3,3); Loop; Death: APBX ABCDE 4 Bright A_Explode(15,48); Stop; }
}
class RS_PlasmaBallSPFB2 : RS_PlasmaBallSPFB1 { Default { Speed 16; } }
class RS_PlasmaBallSPFB3 : RS_PlasmaBallSPFB1 { Default { Speed 24; } }
class RS_PlasmaBallSPFB4 : RS_PlasmaBallSPFB1 { Default { Speed 28; Scale 0.7; } }

// ---------- BROWN: brown orb + spam (ARAC) ----------
class RS_BrownOrbSpiderCH : FastProjectile
{
	Default { Radius 3; Height 3; Speed 28; Mass 100; Species "Spider1"; Damage 8; Projectile; DamageType "Plasma"; +MTHRUSPECIES; +THRUGHOST; +HITTARGET;
		SeeSound "baby/attack"; DeathSound "Litn/litn3"; Translation "0:255=#[169,232,23]"; Scale 0.45; }
	States { Spawn: PLSS AB 2 Bright; Loop; Death: PLSS CDE 3 Bright A_Explode(8,40); Stop; }
}
class RS_BrownSpamSP : FastProjectile
{
	Default { Radius 6; Height 6; Speed 8; Species "Spider1"; Damage 7; RenderStyle "Add"; Projectile; DamageType "Plasma"; +MTHRUSPECIES; +THRUGHOST;
		SeeSound "baby/attack"; DeathSound "weapons/plasmax"; Translation "0:255=%[0.31,0.23,0.18]:[1.10,0.74,0.40]"; Scale 0.6; }
	States { Spawn: PLSS AB 2 Bright; Loop; Death: PLSS CD 3 Bright; Stop; }
}

// ---------- GRAY: stone rockets (reuses RS_CHBSTarget for targeting) ----------
class RS_SpiderStoneRocket : FastProjectile
{
	Default { Radius 8; Height 8; Speed 83; Damage 75; XScale 1.2; Projectile; +NOGRAVITY; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States { Spawn: MISL A 2 Bright A_SpawnItemEx("RS_StoneRockTrail",0,0,0,0,0,0,0,128); Loop; Death: MISL BCD 4 Bright A_Explode(75,96); Stop; }
}
class RS_StoneRockTrail : Actor
{
	Default { +NOINTERACTION; RenderStyle "Translucent"; Alpha 0.5; Scale 0.5; }
	States { Spawn: PUFI ABCD 3; Stop; }
}

// ---------- RED: seeking red bombs + fatso rockets (BSP2) ----------
class RS_RedBombSP : FastProjectile
{
	Default { Radius 6; Height 8; Mass 5; Speed 27; Projectile; +SEEKERMISSILE; Scale 0.6; RenderStyle "Add"; Damage 22; Alpha 0.95; DamageType "Plasma";
		SeeSound "weapons/hominglaunch"; DeathSound "weapons/firex4"; Translation "208:223=176:191","224:231=176:176"; }
	States { Spawn: APLS AB 3 Bright A_SeekerMissile(4,4); Loop; Death: APBX ABCDE 4 Bright A_Explode(40,80); Stop; }
}
class RS_RocketShotFatso : FastProjectile
{
	Default { Radius 8; Height 8; Speed 30; Damage 35; Projectile; RenderStyle "Add"; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx";
		Translation "208:223=176:191"; }
	States { Spawn: MISL A 3 Bright; Loop; Death: MISL BCD 4 Bright A_Explode(50,96); Stop; }
}

// ---------- BLACK: "Macross Missile Spam" -- big ball + missile swarm + rockets (MSPI) ----------
class RS_BBSP1 : FastProjectile
{
	Default { Radius 8; Height 12; Speed 31; Damage 45; DamageType "Plasma"; Projectile; RenderStyle "Add"; SeeSound "baby/attack"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		MISL B 2 Bright A_SpawnItemEx("RS_SPMM1",random(-30,30),random(-30,30),random(1,32),0,0,0,0,SXF_NOCHECKPOSITION);
		Loop;
	Death:
		MISL CD 4 Bright A_Explode(45,80);
		Stop;
	}
}
class RS_SPMM1 : FastProjectile
{
	Default { Radius 8; Height 12; Speed 26; Damage 40; Scale 1.15; DamageType "Fire"; Projectile; RenderStyle "Normal"; +SEEKERMISSILE; DontHurtShooter;
		SeeSound "monster/brufir"; DeathSound "weapons/hellex"; Decal "Scorch"; }
	States { Spawn: MISL A 3 Bright A_SeekerMissile(4,4); Loop; Death: MISL BCD 4 Bright A_Explode(40,64); Stop; }
}
class RS_SPMM2 : RS_SPMM1 { Default { Speed 28; } }
class RS_SPMM3 : RS_SPMM1 { Default { Speed 24; Scale 1.0; } }
class RS_SPMM4 : RS_SPMM1 { Default { Speed 30; } }
class RS_SPMM5 : RS_SPMM1 { Default { Speed 22; Scale 1.3; } }
class RS_SpRocket3 : FastProjectile
{
	Default { Radius 8; Height 8; Speed 37; Damage 27; XScale 1.2; Projectile; SeeSound "fire/fire3"; DeathSound "fire/fire1"; DamageType "Fire"; }
	States { Spawn: MISL A 3 Bright; Loop; Death: MISL BCD 4 Bright A_Explode(35,80); Stop; }
}
class RS_SpRocket4 : RS_SpRocket3 { Default { Speed 42; } }

// ---------- WHITE: slime balls + homer + plasma bolt + web shot (TRIT, HP10000) ----------
class RS_SlimeBall1 : FastProjectile
{
	Default { Radius 8; Height 8; Speed 22; Damage 30; DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85;
		SeeSound "baby/attack"; DeathSound "weapons/plasmax"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States { Spawn: APLS AB 3 Bright; Loop; Death: APBX ABCDE 4 Bright A_Explode(30,64); Stop; }
}
class RS_SlimeBall2 : RS_SlimeBall1 { Default { Speed 18; } }
class RS_SlimeBall3 : RS_SlimeBall1 { Default { Speed 26; } }
class RS_SlimeBall4 : RS_SlimeBall1 { Default { Speed 20; Scale 1.2; } }
class RS_SlimeBall5 : RS_SlimeBall1 { Default { Speed 28; Scale 0.8; } }
class RS_WhiteSpiderHomer : FastProjectile
{
	Default { Radius 8; Height 8; Speed 6; Damage 60; DamageType "Plasma"; Projectile; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.9; Scale 1.0;
		SeeSound "weapons/hominglaunch"; DeathSound "weapons/bigbrn"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL1 A 2 Bright A_SeekerMissile(5,5,SMF_PRECISE);
		Loop;
	Death:
		BAL1 CDE 4 Bright A_Explode(60,96);
		Stop;
	}
}
class RS_WhiteSpiderPBolt : FastProjectile
{
	Default { Radius 8; Height 8; Speed 8; Damage 60; DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 0.9;
		SeeSound "holy3/holy3"; DeathSound "holy2/holy2"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States
	{
	Spawn:
		SSBL A 2 Bright;
		SSBL B 2 Bright A_ScaleVelocity(random(2,4));
	Fly:
		SSBL ABCDEFGH 2 Bright;
		Loop;
	Death:
		SSBL IJK 4 Bright A_Explode(60,80);
		Stop;
	}
}
class RS_WhiteSpiderWebShot : FastProjectile
{
	Default { Radius 3; Height 3; Speed 35; Damage 5; Scale 0.75; Projectile; SeeSound "phantom/bomb"; DeathSound "phantom/explode"; DamageType "Plasma"; RenderStyle "Add"; Alpha 0.8; }
	States { Spawn: APLS AB 2 Bright; Loop; Death: APBX ABC 3 Bright A_Explode(5,32); Stop; }
}

// ============================== EX PROJECTILES ==============================
// ---------- BLACK EX "Macross Missile Spam EX" extras ----------
class RS_BlackSpideSpiralShot : FastProjectile
{
	Default { Radius 6; Height 6; Speed 15; Damage 50; DamageType "Plasma"; Projectile; +DONTHARMCLASS; +THRUACTORS; +ROLLSPRITE; RenderStyle "Add"; Alpha 0.8; Scale 0.8;
		SeeSound "baby/attack"; DeathSound "weapons/plasmax"; }
	States { Spawn: APLS AB 3 Bright A_SetAngle(angle+30,SPF_INTERPOLATE); Loop; Death: APBX ABCDE 4 Bright A_Explode(50,64); Stop; }
}
class RS_BubblegumBombEXSpidie : FastProjectile
{
	Default { Radius 6; Height 6; Speed 38; Damage 50; DamageType "Fire"; Projectile; +RANDOMIZE; +DONTHARMCLASS; RenderStyle "Add"; Alpha 0.9;
		SeeSound "weapons/hominglaunch"; DeathSound "weapons/firex4"; Translation "0:255=%[1.00,0.40,1.00]:[2.00,1.20,2.00]"; }
	States { Spawn: MISL A 2 Bright; Loop; Death: MISL BCD 4 Bright A_Explode(60,96); Stop; }
}
class RS_ExSpideLaser1 : FastProjectile
{
	Default { Radius 6; Height 6; Speed 38; Damage 30; DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 0.85; Scale 0.6;
		SeeSound "incubus/shot"; DeathSound "weapons/plasmax"; Translation "0:255=%[0.00,0.00,1.29]:[2.00,1.01,2.00]"; }
	States { Spawn: PLSS AB 2 Bright; Loop; Death: PLSS CDE 3 Bright A_Explode(30,48); Stop; }
}
class RS_SpRocket4EX : FastProjectile
{
	Default { Radius 11; Height 8; Speed 30; Damage 50; DamageType "Fire"; Projectile; +SEEKERMISSILE; Scale 1.25; SeeSound "weapons/hominglaunch"; DeathSound "weapons/rocklx"; }
	States { Spawn: MISL A 3 Bright A_SeekerMissile(4,4); Loop; Death: MISL BCD 4 Bright A_Explode(80,128); Stop; }
}

// ---------- WHITE EX "WHITE HOT SPIDER" extras (fire/heat theme) ----------
class RS_BoilBoltL9 : FastProjectile
{
	Default { DamageType "Fire"; Species "WhiteSP"; Radius 9; Height 9; Speed 10; Damage 60; Projectile; +RANDOMIZE; +DONTHARMSPECIES; RenderStyle "Add"; Alpha 0.9;
		SeeSound "weapons/firmfi"; DeathSound "weapons/firex3"; }
	States { Spawn: APLS AB 3 Bright; Loop; Death: APBX ABCDE 4 Bright A_Explode(60,80); Stop; }
}
class RS_FireBombL9 : Actor
{
	Default { Radius 13; Height 11; Speed 18; Damage 35; DamageType "Fire"; Projectile; -NOGRAVITY; RenderStyle "Add"; Alpha 1.0; Gravity 0.15;
		SeeSound "weapons/firmfi"; DeathSound "weapons/rocklx"; BounceType "Doom"; BounceCount 2; }
	States { Spawn: MISL A 4 Bright; Loop; Death: MISL BCD 5 Bright A_Explode(70,128); Stop; }
}
class RS_KrakatoaL9 : FastProjectile
{
	Default { DamageType "Fire"; Species "WhiteSP"; Radius 20; Height 20; Speed 80; Damage 60; Projectile; +RANDOMIZE; +DONTHARMSPECIES; RenderStyle "Add"; Alpha 0.95; Scale 1.5;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bigbrn"; }
	States { Spawn: APLS AB 3 Bright; Loop; Death: APBX ABCDE 5 Bright A_Explode(90,160); Stop; }
}
class RS_SPWHIL9 : FastProjectile
{
	Default { Radius 8; Height 8; Speed 29; Damage 50; Scale 0.75; Projectile; +SEEKERMISSILE; SeeSound "phantom/bomb"; DeathSound "phantom/explode"; DamageType "Fire"; RenderStyle "Add"; Alpha 0.9; }
	States { Spawn: APLS AB 2 Bright A_SeekerMissile(4,4); Loop; Death: APBX ABC 3 Bright A_Explode(50,80); Stop; }
}
class RS_WhiteHotFlareL9 : FastProjectile
{
	Default { Radius 4; Height 4; Speed 64; Damage 20; Scale 0.15; DamageType "Fire"; Projectile; RenderStyle "Add"; Alpha 1.0; SeeSound "fire/fire3"; DeathSound "fire/fire1"; }
	States { Spawn: APLS A 2 Bright; Loop; Death: APBX AB 3 Bright; Stop; }
}
