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
// RS_RocketShotFatso is NOT defined here. CHP 12_R.txt has the BSP2 arachnotron
// firing RocketShotFatso_C -- the same homing rocket the Incubus fires, not a
// plain dumbfire. The single shared definition lives in RS_manc_projectiles.zs.

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
// Harmless afterimage the black EX spider sheds when it opens up -- CH
// BlackSpideEXShade, with 12_KX's magenta stencil override folded in.
class RS_BlackSpideEXShade : Actor
{
	Default { Radius 6; Height 6; Speed 1; Projectile; +NOCLIP; +NOINTERACTION;
		RenderStyle "Stencil"; StencilColor "FF 00 FF"; Alpha 0.33; XScale 3.35; YScale 1.75; }
	States { Spawn: FLUM ACDBE 3 Bright; Stop; }
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

// =====================================================================
// CHP FAMILY 12 -- FX ported for the RS_Arachnotron per-tier rebuild.
// Sources: CHP/DECORATE/12/12_{Y,A,W,C}.txt and their CH parents in
// CH/decorate/Spiders.txt. CHP colour cruft (per-colour translations,
// icon spawners, particle walls, ACS announcers) stripped; behaviour,
// sprites, sounds and damage kept as authored.
// =====================================================================

// ---------- T05 YELLOW / T06 ABYSS: the psychic railgun ----------
// CH PsychicAra is the railgun PUFF; PsychicPulse is its trail actor.
class RS_PsychicAra : Actor
{
	Default
	{
		Projectile;
		+NOBLOCKMAP +NOGRAVITY +ALLOWPARTICLES +RANDOMIZE
		+PUFFONACTORS +BLOODLESSIMPACT
		RenderStyle "Add";
		DamageType "Getoutofmyheadcharles";
		Alpha 0.95;
		VSpeed 1;
		Scale 2;
		Mass 5;
	}
	States
	{
	Spawn:
		TNT1 A 1 Bright;
	Melee:
		BLST ABCDEFGHJKLMNOP 1 Bright;
		Stop;
	}
}

class RS_PsychicPulse : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 11;
		Projectile;
		+NOCLIP +BLOODLESSIMPACT
		RenderStyle "Add"; Alpha 0.75;
		SeeSound "queen/fire";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 A_Jump(255, "A1", "A2", "A3", "A4");
	A1:
		BLST ABCDEFGHIIHGEFDCBA 1 Bright;
		Goto Death;
	A4:
		BLST ABCDEFGHHIIIIIIIHHHGEFDCBA 1 Bright;
		Goto Death;
	A2:
		BLST BCDEFGGEFDCB 1 Bright;
		Goto Death;
	A3:
		BLST BCD 1 Bright;
		BLST EFGGEF 2 Bright;
		BLST DCB 1 Bright;
		Goto Death;
	Death:
		TNT1 A 0;
		Stop;
	}
}

// The abyss spider's heavier psychic bolt (A_VileTarget payload).
class RS_PsychicAbyssSP : Actor
{
	Default
	{
		Radius 13; Height 9; Speed 0;
		DamageFunction (random(2, 15));
		Projectile;
		+RANDOMIZE +MTHRUSPECIES +DONTHARMCLASS
		RenderStyle "Stencil"; StencilColor "Black";
		Scale 0.75;
		DamageType "Getoutofmyheadcharles";
		SeeSound "holy3/holy3"; DeathSound "holy2/holy2";
	}
	States
	{
	Spawn:
		BBOM B 1 Bright;
	Death:
		BBOM C 2 Bright A_Explode(random(10, 32), 64, 0);
		Stop;
	}
}

// ---------- T06 ABYSS: the ambient walk / shoot / pain ghosts ----------
// CH spawns these through a 4-way RandomSpawner (norm/blue/black/fuzz);
// the "norm" variant is the authored look, the rest are palette noise.
class RS_AbyssSPwalk1 : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.65; XScale 2.45; YScale 1.75; }
	States { Spawn: TRIT ABBC 2; Stop; }
}
class RS_AbyssSPwalk2 : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.65; XScale 2.45; YScale 1.75; }
	States { Spawn: TRIT CDDEE 2; Stop; }
}
class RS_AbyssSPShoot : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.65; XScale 2.45; YScale 1.75; }
	States { Spawn: TRIT E 5 Bright; TRIT F 4 Bright; Stop; }
}
class RS_AbyssSPPain : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.65; XScale 2.45; YScale 1.75; }
	States { Spawn: TRIT F 6; Stop; }
}

// ---------- T12 WHITE: the egg it lays, and the webbing ----------
class RS_WhiteSPSlowdown : PowerSpeed
{
	Default { +INVENTORY.AUTOACTIVATE; -INVENTORY.INVBAR; Powerup.Duration 15; Speed 0.2; }
}

class RS_WhiteSPWebWeb : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 1;
		Projectile;
		+NOCLIP +DONTTHRUST +DONTBLAST
	}
	States
	{
	Spawn:
		TNT1 A 0 A_Jump(128, "A1");
	A2:
		WW3B A 12 Bright;
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		WW3B A 12 Bright { A_SetTranslucent(0.7); }
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		WW3B A 12 Bright { A_SetTranslucent(0.4); }
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		WW3B A 12 Bright { A_SetTranslucent(0.2); }
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		Goto Death;
	A1:
		WW3B B 12 Bright;
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		WW3B B 12 Bright { A_SetTranslucent(0.7); }
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		WW3B B 12 Bright { A_SetTranslucent(0.4); }
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		WW3B B 12 Bright { A_SetTranslucent(0.2); }
		TNT1 A 0 { A_RadiusGive("RS_WhiteSPSlowdown", 64, RGF_PLAYERS | RGF_CUBE, 1); }
		Goto Death;
	Death:
		PLSE A 1;
		Stop;
	}
}

class RS_WhiteSpidegg : Actor
{
	Default
	{
		Health 50;
		Radius 20; Height 32;
		Species "WhiteSP";
		Monster;
		+NOPAIN +NOTARGET +FLOAT +FLOATBOB +NOGRAVITY +LOOKALLAROUND
		-COUNTKILL
		Speed 7;
		Alpha 0.95;
		Scale 2;
		DeathSound "weapons/rocklx";
		Tag "White Spider Egg";
	}
	States
	{
	Spawn:
		BAL1 AB 4 A_Look();
		Loop;
	See:
		BAL1 A 16;
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 ABABABABABABABABABABABABABABABABABABABABABA 1 A_Wander();
		TNT1 A 0 A_FaceTarget();
		TNT1 AA 0 { A_SpawnItemEx("RS_WhiteSPWebWeb", random(12, 64), random(-28, 28), random(1, 8)); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 ABABABABABABABABABABABABABABABABABABABABABA 1 A_Wander();
		TNT1 A 0 A_FaceTarget();
		TNT1 AA 0 { A_SpawnItemEx("RS_WhiteSPWebWeb", random(12, 64), random(-28, 28), random(1, 8)); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 ABABABABABABABABABABABABABABABABABABABABABA 1 A_Wander();
		TNT1 A 0 A_FaceTarget();
		TNT1 AA 0 { A_SpawnItemEx("RS_WhiteSPWebWeb", random(12, 82), random(-28, 28), random(1, 8)); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		BAL1 B 12 { A_SetScale(1.5, 2); }
		BAL1 ABABABABABABABABABABABABABABABABABABABABABA 1 A_Wander();
		TNT1 A 0 A_FaceTarget();
		TNT1 AA 0 { A_SpawnItemEx("RS_WhiteSPWebWeb", random(12, 82), random(-28, 28), random(1, 8)); }
		BAL1 A 12 { A_SetScale(2, 1.5); }
		Goto Death;
	Death:
		TNT1 A 0 A_ScreamAndUnblock();
		MISL B 4 Bright;
		MISL C 4 Bright A_Explode(random(10, 80), 64, 0);
		MISL D 4 Bright;
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_WhiteSPWebWeb", random(-64, 64), random(-64, 64), random(-8, 26)); }
		TNT1 A 1 A_Die();
		Stop;
	}
}

// ---------- SHARED: the arachnotron gib-death blasts (XDeath) ----------
class RS_AraBoom1 : Actor
{
	Default { Radius 10; Height 42; +NOGRAVITY; Scale 1.2; }
	States
	{
	Spawn:
		BAR1 AB 0;
		Goto Death;
	Death:
		MISL B 8 Bright;
		MISL C 6 Bright { A_StartSound("world/barrelx"); }
		MISL D 3 Bright;
		Stop;
	}
}
class RS_AraBoom2 : Actor
{
	Default { Radius 10; Height 42; +NOGRAVITY; Scale 0.6; DeathSound "weapons/firex4"; }
	States
	{
	Spawn:
		BAR1 AB 0 { A_StartSound("weapons/firex4"); }
		Goto Death;
	Death:
		MISL B 8 Bright;
		MISL C 6 Bright { A_StartSound("weapons/firex4"); }
		MISL D 3 Bright;
		Stop;
	}
}
class RS_AraBoom3 : Actor
{
	Default { Radius 10; Height 42; +NOGRAVITY; RenderStyle "Add"; Alpha 0.75; Scale 0.4; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Death;
	Death:
		ARAG B 7 Bright;
		TNT1 A 3;
		ARAG C 6 Bright;
		Stop;
	}
}

// ---------- T03 CYAN: the death easter egg CH drops on the ice spider ----------
class RS_CH_Cirno : Actor
{
	Default
	{
		Radius 3; Height 6; Speed 1; Scale 1; Damage 0;
		Projectile;
		+MOVEWITHSECTOR +CANNOTPUSH +NOTONAUTOMAP
		-NOGRAVITY
		Gravity 0.05;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 { vel.z += 0.625; }   // CH: ThrustThingZ(0,5,0,1) -- add, not set
		Goto Wee;
	Wee:
		CIRN A 5;
		Loop;
	Crash:
		CIRN A -1;
		Stop;
	Death:
		CIRN A -1;
		Stop;
	}
}
