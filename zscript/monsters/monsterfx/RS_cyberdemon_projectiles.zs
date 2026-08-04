// =====================================================================
// RS_cyberdemon_projectiles.zs
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
// hf_cyberdemon_projectiles.zs -- Cyberdemon projectiles (Neutral + CH colors).
// Neutral = Babel CyberdemonMissile/HomingMissile (BExplode cosmetic dropped;
//   A_Explode keeps the real damage). Color projectiles added in later passes.
// ============================================================================

class RS_CyberdemonMissile : Actor
{
	Default
	{
		Speed 20;
		Damage 30;
		Projectile;
		+RANDOMIZE
		+DEHEXPLOSION
		+ROCKETTRAIL
		DeathSound "";
		DamageType "Monster";
		Radius 11; Height 8;
	}
	States
	{
	Spawn:
		MISL A 1 Bright;
		Loop;
	Death:
		TNT1 A 0 A_Explode;
		HMIS B 8 Bright;
		HMIS C 6 Bright;
		HMIS D 4 Bright;
		Stop;
	}
}

class RS_CyberdemonHomingMissile : Actor
{
	Default
	{
		Damage 30;
		Speed 15;
		FastSpeed 30;
		Projectile;
		+SEEKERMISSILE
		+ROCKETTRAIL
		DamageType "Monster";
		Radius 11; Height 8;
	}
	States
	{
	Spawn:
		HMIS A 1 Bright A_SeekerMissile(0, 1, SMF_PRECISE|SMF_CURSPEED);
		Loop;
	Death:
		TNT1 A 0 A_Explode;
		HMIS B 8 Bright;
		HMIS C 6 Bright;
		HMIS D 4 Bright;
		Stop;
	}
}

// ============================================================================
// CYBERDEMON COLORS pass 1 -- GREEN / BLUE / PURPLE.
// Shared with HK/Baron: RS_BluCybFX, RS_HKRedDeath, RS_SparkPuff1, RS_BaronOfDirtCH3.
// Damage->constants; cosmetic ColorTierIcon markers dropped (cosmetic pass).
// ============================================================================

// ---------- GREEN: splash-rockets (poison gas clouds) ----------
class RS_Gas14 : Actor
{
	Default { Radius 6; Height 16; Speed 0; Projectile; +RANDOMIZE; RenderStyle "Add"; DamageType "Poison"; Scale 0.8; Alpha 0.6; }
	States
	{
	Spawn:
		PSBG CDEFGHGF 4 Bright A_Explode(6,42);
		PSBG G 0 A_Jump(180,"Death");
		Loop;
	Death:
		PSBG CDEFGHI 6 Bright A_Explode(6,42);
		Stop;
	}
}
class RS_SplashRocket : Actor
{
	Default { Radius 11; Height 8; Speed 20; Damage 17; DamageType "Fire"; Projectile; +RANDOMIZE; +DEHEXPLOSION; +ROCKETTRAIL;
		SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx";
		Translation "128:143=113:127","168:191=113:127","208:223=112:121"; }
	States
	{
	Spawn:
		MISL A 3 Bright A_SpawnItemEx("RS_Gas14",0,0,2,0,0,0,SXF_NOCHECKPOSITION);
		Loop;
	Death:
		MISL B 8 Bright A_Explode;
		HMIS C 6 Bright;
		MISL CCCCCCC 0 A_SpawnItemEx("RS_Gas14",random(-8,8),random(-8,8),random(-2,2),random(3,28),0,random(-6,20),random(-359,359),SXF_NOCHECKPOSITION);
		HMIS D 4 Bright;
		Stop;
	}
}

// ---------- BLUE: BFG-swoosh artillery + plasma + seeking arts ----------
// (RS_SwooshCBTR / RS_SwooshCBTR2 / RS_PlasmaBallSP4 already defined in the HK
//  projectiles -- shared. RS_SwooshCBTR3 / RS_PlasmaBallSP5 derive from them below.)
class RS_SwooshCBTR3 : RS_SwooshCBTR { Default { Speed 13; } }
class RS_PlasmaBallSP5 : RS_PlasmaBallSP4 { Default { Species "Cybie"; +DONTHARMSPECIES; } }
class RS_SwooshCB : Actor
{
	Default { Radius 13; Height 8; Speed 36; Damage 35; Projectile; +RANDOMIZE; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.75; Scale 0.6;
		SeeSound "Litn/litn3"; DeathSound "weapons/bfgx"; Translation "112:127=192:207"; }
	States
	{
	Spawn:
		BFS1 AB 1 Bright A_SpawnItemEx("RS_SwooshCBTR",0,0,3);
		Loop;
	Death:
		BFE1 AB 8 Bright;
		BFE1 C 8 Bright A_Explode(35,124);
		BFE1 DEF 8 Bright;
		Stop;
	}
}
class RS_SwooshCB2 : Actor
{
	Default { Radius 15; Height 9; Speed 15; Damage 45; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; +EXTREMEDEATH;
		RenderStyle "Add"; Alpha 0.95; Scale 0.8; SeeSound "Litn/litn3"; DeathSound "weapons/bfgx"; Translation "112:127=192:207"; }
	States
	{
	Spawn:
		BFS1 A 1 Bright A_SpawnItemEx("RS_SwooshCBTR3",0,0,3);
		BFS1 B 2 Bright A_SpawnItemEx("RS_BluCybFX",0,0,3);
		BFS1 BBBBBBBB 0 A_CustomMissile("RS_PlasmaBallSP5",random(-3,3),random(-12,12),random(0,360),CMF_AIMDIRECTION,random(0,360));
		BFS1 A 1 Bright A_SeekerMissile(5,12);
		Loop;
	Death:
		BFE1 AB 8 Bright;
		BFE1 C 8 Bright A_Explode(45,124);
		BFE1 DEF 8 Bright;
		Stop;
	}
}
class RS_BluCybArt : Actor
{
	Default { Radius 8; Height 8; Speed 20; Damage 35; DamageType "Plasma"; Projectile; +SEEKERMISSILE; +EXTREMEDEATH; +BOUNCEONWALLS; +USEBOUNCESTATE;
		BounceType "Hexen"; BounceCount 2; BounceFactor 1.5; Scale 0.65; SeeSound "Litn/litn3"; DeathSound "weapons/bfgx"; Translation "112:127=192:207"; }
	States
	{
	Spawn:
		BFS1 A 1 Bright A_SpawnItemEx("RS_SwooshCBTR3",0,0,3);
		BFS1 B 1 Bright A_SpawnItemEx("RS_BluCybFX",0,0,3);
		BFS1 A 1 Bright A_SeekerMissile(3,1);
		Loop;
	Bounce:
		BFS1 A 1 Bright A_SpawnItemEx("RS_SwooshCBTR3",0,0,3);
		BFS1 A 1 Bright A_SeekerMissile(6,3);
		Loop;
	Death:
		BFE1 ABCDEF 6 Bright A_Explode(20,124);
		Stop;
	}
}

// ---------- PURPLE: caco-fire waves + seeking orbs + propane rockets ----------
class RS_CBWave : Actor
{
	Default { Radius 10; Height 10; Speed 4; Damage 20; Projectile; +DONTHARMCLASS; +EXPLODEONWATER; +FLOATBOB;
		RenderStyle "Add"; Alpha 0.75; Scale 0.85; DamageType "Fire"; SeeSound "Fire/fire4"; DeathSound "Spell/Impact1";
		Translation "168:223=250:254","224:231=250:250"; }
	States
	{
	Spawn:
		SBS1 ABCD 8 Bright A_ScaleVelocity(1.5);
		Loop;
	Death:
		BAL2 C 2 Bright A_SetScale(1.1);
		BAL2 D 3 Bright A_SetTranslucent(0.4);
		BAL2 E 6 Bright A_Explode(12,88);
		Stop;
	}
}
class RS_OrbCB2 : Actor
{
	Default { Radius 3; Height 4; Speed 128; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.55; Scale 0.3;
		Translation "16:47=250:254","128:143=250:254","152:191=250:254"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL1 A 4 Bright A_SeekerMissile(8,8);
		BAL1 B 4 Bright A_Weave(1,1,2,1);
		Goto Death;
	Death:
		BAL1 CDE 6 Bright;
		Stop;
	}
}
class RS_OrbCB : Actor
{
	Default { Radius 3; Height 4; Speed 125; Damage 10; Projectile; +RANDOMIZE; +MTHRUSPECIES; +SEEKERMISSILE;
		RenderStyle "Add"; DeathSound "Fire/fire5"; Alpha 0.85; Scale 0.3;
		Translation "16:47=250:254","128:143=250:254","152:191=250:254"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL1 B 0 A_SpawnItemEx("RS_OrbCB2",0,0,1);
		BAL1 A 1 Bright A_SeekerMissile(8,8);
		BAL1 B 1 Bright A_Weave(1,1,2,1);
		Loop;
	Death:
		BAL1 CDE 6 Bright;
		Stop;
	}
}
class RS_Propane : Actor
{
	Default { Radius 11; Height 8; Speed 20; Damage 18; Projectile; +RANDOMIZE; +DEHEXPLOSION; +ROCKETTRAIL; +SEEKERMISSILE;
		DamageType "Fire"; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx";
		Translation "128:143=250:254","144:151=253:254"; }
	States
	{
	Spawn:
		MISL A 1 Bright A_SeekerMissile(4,4);
		Loop;
	Death:
		MISL B 8 Bright A_Explode(96,128);
		HMIS C 6 Bright;
		HMIS D 4 Bright;
		Stop;
	}
}

// ============================================================================
// CYBERDEMON COLORS pass 2a -- CYAN (ice-spray/towers) + YELLOW (fire-rain/forgotten).
// CARD/SUPR bodies. Shares RS_SparkPuff1, RS_SpikeCyanRev. Damage->constants.
// ============================================================================

// ---------- CYAN: ice spray + big-ice towers + gun flares ----------
class RS_CyanCybieGunFlare : Actor
{
	Default { Radius 2; Height 2; Speed 2; Projectile; +NOINTERACTION; +THRUACTORS; RenderStyle "Add"; Alpha 0.55; Scale 0.66;
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States { Spawn: TNT1 A 0; Death: SSBL ABCDEFGH 2 Bright; Stop; }
}
class RS_CyanCybieHower : Actor
{
	Default { Radius 2; Height 2; Speed 1; Projectile; +NOINTERACTION; +THRUACTORS; RenderStyle "Add"; Alpha 0.73; XScale 0.33; YScale 0.10;
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		SSBL I 3 Bright;
	Death:
		SSBL I 3 Bright;
		SSBL I 3 Bright A_SetScale(0.43,0.10);
		SSBL J 3 Bright A_SetScale(0.66,0.10);
		SSBL KKK 3 Bright A_FadeOut(0.20);
		Stop;
	}
}
class RS_CyanCybieSprayIce : Actor
{
	Default { Radius 2; Height 2; Speed 42; Mass 500; Damage 7; Projectile; DamageType "Ice"; +THRUGHOST; Gravity 1.5; Scale 0.33;
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		RIP1 ABC 8 Bright;
		Loop;
	Death:
		RIP1 A 0 A_ChangeFlag("NOGRAVITY",false);
		RIP1 CBACBA 6 A_Explode(6,6);
		Stop;
	}
}
class RS_AbyssCybieDecoFlame : Actor
{
	Default { Radius 4; Height 3; Speed 18; Projectile; +NOCLIP; +NOINTERACTION; RenderStyle "Add"; Alpha 0.55; XScale 0.55; YScale 0.81;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States { Spawn: FRFX ABCD 3 Bright; FRFX HIJKLMNO 2 Bright; Stop; }
}
class RS_CyanCybieBigIce : Actor
{
	Default { Radius 8; Height 4; Speed 30; +BRIGHT; Projectile; DamageType "Ice"; Damage 50; Scale 0.15;
		SeeSound "weapons/rocklf"; DeathSound "Bomb/boom"; }
	States
	{
	Spawn:
		GBLL A 0;
		Goto Fly;
	Fly:
		C3BB DEFGHI 2 Bright A_SpawnItemEx("RS_AbyssCybieDecoFlame",cos(pitch)*1,0,0-(sin(pitch)*1),cos(pitch)*1,0,-sin(pitch)*1,SXF_NOCHECKPOSITION);
		Loop;
	Death:
		TNT1 A 0 A_Scream;
		TNT1 A 0 A_SetScale(1.33,1.0);
		SSBL ABCD 3 Bright;
		TNT1 A 0 A_Explode(70,128,0);
		SSBL EFGH 2 Bright;
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(16,60),0,random(2,28),random(0,90));
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(16,60),0,random(2,28),random(91,180));
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(16,60),0,random(2,28),random(181,270));
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(16,60),0,random(2,28),random(271,359));
		Stop;
	}
}
class RS_CyanCybieBigIce2 : RS_CyanCybieBigIce { Default { Speed 20; } }
class RS_CyanCybieBigIce3 : RS_CyanCybieBigIce { Default { Speed 12; } }

// ---------- YELLOW: forgotten-fire seekers + fire-rain storm + demon arm ----------
class RS_GlowBack : Actor
{
	Default { Radius 16; Height 12; Projectile; +RANDOMIZE; +THRUACTORS; RenderStyle "Add"; Speed 15; FloatSpeed 30; Scale 0.65; Alpha 0.85; }
	States
	{
	Spawn:
		BBOM B 1 Bright;
		BBOM B 3 Bright A_SetScale(0.5);
		BBOM B 2 Bright;
		BBOM B 3 Bright A_SetScale(0.65);
		BBOM B 1 Bright;
		Stop;
	}
}
class RS_Vollrey : Actor
{
	Default { Radius 6; Height 8; Speed 27; FastSpeed 38; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.75; Scale 1.15; SeeSound "Forgotten/Attack"; DeathSound "spell/Impact1"; Translation "168:191=220:223"; }
	States
	{
	Spawn:
		FRGO CC 2 Bright A_SeekerMissile(12,18);
		FRGO DD 2 Bright A_CustomMissile("RS_GlowBack",8,0);
		Loop;
	Death:
		BBOM A 2 Bright A_SetScale(1.5);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(15,148);
		BBOM EFG 6 Bright A_Explode(17,148);
		Stop;
	}
}
class RS_Vollrey2 : Actor
{
	Default { Radius 6; Height 8; Speed 27; FastSpeed 38; Damage 35; DamageType "Fire"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.75; Scale 1.15; SeeSound "Forgotten/Attack"; DeathSound "spell/Impact1"; Translation "168:191=220:223"; }
	States
	{
	Spawn:
		FRGO CC 2 Bright;
		FRGO DD 2 Bright A_CustomMissile("RS_GlowBack",8,0);
		Loop;
	Death:
		BBOM A 2 Bright A_SetScale(1.5);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(15,148);
		BBOM EFG 6 Bright A_Explode(17,148);
		Stop;
	}
}
class RS_CybieRain : Actor
{
	Default { Radius 6; Height 8; Speed 10; FastSpeed 15; Mass 50; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Gravity 5; Alpha 1; Scale 1.3; SeeSound "caco/attack"; DeathSound "fire/fire5"; }
	States
	{
	Spawn:
		STRS AB 2 Bright A_SeekerMissile(3,3);
		STRS CD 2 Bright A_CustomMissile("RS_SparkPuff1",4,0,CMF_AIMOFFSET,random(0,360),random(0,360));
		Loop;
	Death:
		BBOM A 2 Bright A_SetScale(1);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(20,108);
		BBOM EFG 6 Bright A_Explode(17,108);
		Stop;
	}
}
class RS_CybieRainMaker : Actor
{
	Default { Radius 6; Height 8; Speed 15; FastSpeed 38; Mass 50; Damage 22; DamageType "Fire"; Projectile;
		+CEILINGHUGGER; +FLOAT; +NOGRAVITY; +RANDOMIZE; +INVISIBLE; RenderStyle "Add"; Gravity 7; Alpha 1; Scale 1.3;
		SeeSound "caco/attack"; DeathSound "fire/fire5"; }
	States
	{
	Spawn:
		STRS AB 2 Bright A_SpawnItemEx("RS_CybieRain",random(-400,400),random(-400,400),-32,random(-15,15),random(-15,15),1,SXF_NOCHECKPOSITION);
		STRS CD 2 Bright A_SpawnItemEx("RS_CybieRain",random(-700,700),random(-700,700),-32,random(-15,15),random(-15,15),1,SXF_NOCHECKPOSITION);
		Loop;
	Death:
		BBOM ABCD 3 Bright;
		Stop;
	}
}



// ============================================================================
// CYBERDEMON COLORS pass 2b -- GRAY (rockslide/spikes) + FIREBLU (caco-balls/dash)
//   + BROWN (goo/balls). SUPR/8CYB/CYBR bodies. Shares Drt1/2/3, Gas14, GreeniesBR,
//   BaronOfDirtCH3, HKRedDeath. Damage->constants.
// ============================================================================

// ---------- GRAY: vile-targeted rockslides + ground-spikes ----------
class RS_CHBSTarget : Actor
{
	// the targeting beacon a vile-target lands on (beeps + flashes)
	Default { Radius 1; Height 1; Projectile; +NOCLIP; +NOGRAVITY; +NOINTERACTION; Speed 1; RenderStyle "Add"; Alpha 1.0; Scale 1.1; }
	States
	{
	Spawn:
		CHTA A 3 Bright;
		TNT1 A 3 Bright;
		Goto Fly;
	Fly:
		CHTA A 4 Bright A_PlaySound("prox/beep",7,2,false,ATTN_NONE);
		TNT1 A 4 Bright;
		CHTA A 4 Bright;
		TNT1 A 4 Bright A_PlaySound("prox/beep",7,2,false,ATTN_NONE);
		CHTA A 4 Bright;
		TNT1 A 3 Bright;
		Stop;
	}
}
class RS_RockSlideDropCH : Actor
{
	// a falling rock from the rockslide (lands and damages where it hits)
	Default { Speed 1; Projectile; +NOCLIP; +CEILINGHUGGER; -NOGRAVITY; Gravity 1.0; Damage 20; DamageType "Melee";
		Scale 0.8; Translation "0:255=%[0.30,0.30,0.30]:[0.85,0.85,0.85]"; }
	States
	{
	Spawn:
		JUBD A 1 Bright;
		Goto Fly;
	Fly:
		JUBD AB 3;
		Loop;
	Death:
		JUBD CD 4 A_Explode(15,48,0);
		DIRT JKL 3;
		Stop;
	}
}
class RS_RockSlideCH1 : Actor
{
	// ground-target rockslide controller: warps to the target spot, rains rocks
	Default { Speed 1; Projectile; +NOCLIP; Alpha 0.01; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 2 A_Warp(AAPTR_TRACER,0,0,6,0,WARPF_NOCHECKPOSITION);
		TNT1 AAA 1 A_SpawnItemEx("RS_RockSlideDropCH",random(-48,48),random(-48,48),random(128,400),0,0,0,0,SXF_NOCHECKPOSITION);
		TNT1 A 2 A_Warp(AAPTR_TRACER,0,0,6,0,WARPF_NOCHECKPOSITION);
		TNT1 AAA 1 A_SpawnItemEx("RS_RockSlideDropCH",random(-48,48),random(-48,48),random(128,400),0,0,0,0,SXF_NOCHECKPOSITION);
		TNT1 A 2 A_Warp(AAPTR_TRACER,0,0,6,0,WARPF_NOCHECKPOSITION);
		TNT1 AAA 1 A_SpawnItemEx("RS_RockSlideDropCH",random(-48,48),random(-48,48),random(128,400),0,0,0,0,SXF_NOCHECKPOSITION);
		Stop;
	}
}
class RS_VileGroundSpikes2 : Actor
{
	Default { Speed 1; Damage 5; DamageType "Melee"; Projectile; +FLOORHUGGER; +THRUACTORS; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		SSPK C 30 A_Jump(128,"WaitMore");
		SSPK D 10;
		SSPK A 3 A_SetScale(1.0,0.3);
		TNT1 A 0 A_Explode(80,32,0);
		SSPK A 3 A_SetScale(1.0,1.0);
		TNT1 A 0 A_Explode(80,32,0);
		SSPK A 8 A_ChangeFlag("THRUACTORS",false);
		Goto Death;
	WaitMore:
		SSPK C 45;
		TNT1 A 0 A_Jump(8,"WaitMore");
		SSPK D 15;
		Goto Fly+1;
	Death:
		SSPK A 8 A_SetSolid;
		SSPK A 16;
		SSPK AAA 8 A_FadeOut(0.33);
		Stop;
	}
}
class RS_VileGroundSpike : Actor
{
	Default { Speed 24; Projectile; +THRUACTORS; +FLOORHUGGER; Alpha 0.01; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 4 Bright A_SpawnItemEx("RS_Drt1",random(-3,4),random(-2,2),random(1,3),1,0,1,random(0,360),128);
		TNT1 A 4 Bright A_SpawnItemEx("RS_VileGroundSpikes2",0,0,random(1,3),0,0,0,0,128);
		TNT1 A 4 Bright A_SpawnItemEx("RS_Drt2",random(-2,2),random(-4,3),random(1,3),1,0,1,random(0,360),128);
		TNT1 A 4 Bright A_SpawnItemEx("RS_VileGroundSpikes2",0,0,random(1,3),0,0,0,0,128);
		Stop;
	}
}

// ---------- FIREBLU: bouncing caco-balls + seeking missiles ----------
class RS_FireBluCacoBall2 : Actor
{
	Default { Radius 12; Height 16; Speed 1; Damage 14; DamageType "Fire"; Projectile; +RANDOMIZE; +THRUACTORS;
		RenderStyle "Add"; Alpha 0.85; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States
	{
	Spawn:
		FIRE AB 1 Bright;
		Goto Death;
	Death:
		FIRE CDEEDCDE 5 A_Explode(6,64);
		FIRE FGH 4 Bright A_Explode(6,64);
		Stop;
	}
}
class RS_FireBluCacoBall : Actor
{
	Default { Radius 12; Height 18; Speed 16; Damage 22; DamageType "Plasma"; Projectile; +BOUNCEONWALLS;
		BounceType "Hexen"; WallBounceFactor 0.9; BounceFactor 0.9; BounceCount 4; BounceSound "Bomb/bounce";
		RenderStyle "Add"; Alpha 0.45; Scale 1.5; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "208:223=195:207","225:231=192:195"; }
	States
	{
	Spawn:
		BAL1 AB 4 Bright A_SpawnItemEx("RS_FireBluCacoBall2",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		Loop;
	Death:
		BAL1 CDE 5 Bright A_Explode(22,96);
		Stop;
	}
}
class RS_FireBluCybMiss : Actor
{
	Default { Radius 20; Height 20; Mass 600; Speed 20; Damage 55; DamageType "Plasma"; Projectile; +SEEKERMISSILE;
		Scale 1.5; RenderStyle "Add"; Alpha 0.95; SeeSound "Spell/spellCast1"; DeathSound "Crack/death";
		Translation "216:223=199:207","208:214=193:201","168:175=198:201"; }
	States
	{
	Spawn:
		MANF A 3 Bright A_SpawnItemEx("RS_FireBluCacoBall2",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		MANF B 3 Bright A_SeekerMissile(5,2);
		Loop;
	Death:
		MISL B 4 A_SetTranslucent(0.35);
		MISL C 2 A_Explode(27,256);
		HMIS D 4 Bright;
		Stop;
	}
}

// ---------- BROWN: drilling goo-balls + sharp green basics ----------
class RS_GreenBalb2 : Actor
{
	Default { Radius 6; Height 4; Speed 11; Gravity 0.2; Damage 22; DamageType "Plasma"; Projectile; +RANDOMIZE; -NOGRAVITY;
		RenderStyle "Add"; Alpha 0.9; Scale 0.7; SeeSound "spit/spit"; DeathSound "spit/spit2";
		Translation "168:191=112:127","208:223=112:118","144:151=125:127"; }
	States
	{
	Spawn:
		GBLL ABC 6 Bright A_SpawnItemEx("RS_Trail12",0,0,5);
		Loop;
	Death:
		BAL2 CDE 6 Bright A_Explode(18,32);
		Stop;
	}
}
class RS_BrownCybBasic : Actor
{
	Default { Radius 9; Height 9; Speed 25; Damage 90; DamageType "Plasma"; Projectile; +DONTHARMCLASS;
		SeeSound "SHARPST1"; DeathSound "shadowbeast/pr1death";
		Translation "0:255=%[0.13,0.22,0.14]:[0.79,1.34,0.28]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		MANF A 2 Bright;
		TNT1 AAA 0 A_SpawnItemEx("RS_GreeniesBR",random(-3,3),random(-3,3),random(1,3),random(2,8),0,1,random(-359,359));
		MANF B 2 Bright;
		TNT1 AAA 0 A_SpawnItemEx("RS_GreeniesBR",random(-3,3),random(-3,3),random(1,3),random(2,8),0,1,random(-359,359));
		Loop;
	Death:
		MANF CD 4 Bright A_Explode(45,128);
		Stop;
	}
}
class RS_Splash11 : Actor
{
	Default { Radius 6; Height 16; Speed 16; FastSpeed 23; Projectile; +RANDOMIZE; +THRUACTORS; -NOGRAVITY;
		RenderStyle "Add"; Scale 0.3; Alpha 0.5; Translation "168:191=112:127"; }
	States
	{
	Spawn:
		BAL1 AB 12;
		BAL1 A 2 A_Jump(32,"Death");
		Loop;
	Death:
		BAL7 C 1 Bright A_SetScale(0.6);
		BAL7 CDE 4 Bright;
		Stop;
	}
}

// ============================================================================
// CYBERDEMON APEX TRIO -- ABYSS / BLACK / WHITE. The deepest webs.
// AbyssShotIdentifier (cosmetic) dropped -> cosmetic pass. Deepest recursive sub-chains
// (PentaFire recursion, SmithDeathFire) folded faithfully. Damage->constants.
// ============================================================================

// ---------- ABYSS (TERM body, HP12000): void bubbles + holy waves + seeking rockets ----------
class RS_AbyCybBub : Actor
{
	Default { Radius 3; Height 3; Speed 12; Damage 5; DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 0.75; Scale 0.3;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States { Spawn: BAL1 AB 8 Bright; Goto Death; Death: BAL1 CDE 6 Bright; TNT1 A 0 A_Explode(7,32,0); Stop; }
}
class RS_AbyCybBubProj : Actor
{
	Default { Radius 2; Height 2; Speed 28; Damage 7; DamageType "Plasma"; Projectile; +THRUACTORS; RenderStyle "Add"; Alpha 0.75; Scale 0.3;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 AA 1 A_SpawnItemEx("RS_AbyCybBub",-2,random(2,64),random(-8,8),15,0,random(-3,3),random(0,90));
		TNT1 A 2 Bright;
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
class RS_AbyCybWave2 : Actor
{
	Default { Radius 6; Height 6; Speed 20; Damage 10; DamageType "Melee"; Projectile; +DONTHARMCLASS; Species "Cybie";
		RenderStyle "Add"; Alpha 0.25; Scale 0.45; SeeSound "holy3/holy3"; DeathSound "holy2/holy2"; }
	States { Spawn: SSBL I 6 Bright; Death: SSBL J 12 Bright; Stop; }
}
class RS_AbyCybWave : Actor
{
	Default { Radius 6; Height 6; Speed 28; ProjectileKickBack 7000; Damage 25; DamageType "Melee"; Projectile; +DONTHARMCLASS; Species "Cybie";
		RenderStyle "Add"; Alpha 0.25; Scale 0.45; SeeSound "holy3/holy3"; DeathSound "holy2/holy2"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		SSBL KKKKKKKKK 2 Bright A_SpawnItemEx("RS_AbyCybWave2",-2,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		Loop;
	Death:
		SSBL J 8 Bright;
		Stop;
	}
}
// (RS_SplashAbyss2 already defined in imp projectiles -- shared.)
class RS_AbyssCybRocket : Actor
{
	Default { Radius 11; Height 8; Speed 21; Damage 20; DamageType "Fire"; Projectile; +SEEKERMISSILE; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx";
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		MISL A 1 Bright A_SpawnItemEx("RS_SplashAbyss2",0,0,1,3,0,2,random(-359,359),SXF_NOCHECKPOSITION);
		MISL A 1 Bright A_SeekerMissile(2,2);
		Loop;
	Death:
		MISL B 8 Bright A_Explode(60,128);
		MISL CD 4 Bright;
		Stop;
	}
}
// Terminator body-parts (bouncing gibs the Abyss flings). DOOMBOUNCE; the long CH
// translation folded to the abyss tint.
class RS_TerminatorArm : Actor
{
	Default { Radius 12; Height 15; Speed 3; Mass 1000; Scale 1.2; +MISSILE; +DROPOFF; BounceType "Doom"; BounceCount 6; Damage 30; DamageType "Melee";
		Translation "0:255=%[0.00,0.00,0.07]:[0.49,0.72,0.74]"; }
	States { Spawn: TARM ABCD 4; Loop; Death: TARM EF 6; Stop; }
}
class RS_TerminatorHead : Actor
{
	Default { Radius 6; Height 8; Speed 10; Mass 1000; Scale 1.2; +DROPOFF; +MISSILE; BounceType "Doom"; BounceCount 6; Damage 25; DamageType "Melee";
		Translation "0:255=%[0.00,0.00,0.07]:[0.49,0.72,0.74]"; }
	States { Spawn: THAD ABCD 4; Loop; Death: THAD EF 6; Stop; }
}
class RS_TerminatorShoulder : Actor
{
	Default { Radius 8; Height 8; Speed 8; Mass 1000; Scale 1.2; +DROPOFF; +MISSILE; BounceType "Doom"; BounceCount 6; Damage 20; DamageType "Melee";
		Translation "0:255=%[0.00,0.00,0.07]:[0.49,0.72,0.74]"; }
	States { Spawn: TSHO ABCD 4; Loop; Death: TSHO EF 6; Stop; }
}

// ---------- BLACK (BSMT body, HP14500): the Smith-demon -- hammers, penta-laser,
//            moloch quakes, hellshots w/ tracers, zappers, ghost summons ----------
class RS_RedPuff2 : Actor
{
	Default { Radius 0; Height 1; Speed 0; Projectile; RenderStyle "Add"; Alpha 0.85; }
	States { Spawn: TNT1 A 3 Bright; RPUF ABCDE 3 Bright; Stop; }
}
class RS_STracerPuff : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.5; }
	States { Spawn: HELX AB 4 Bright; Stop; }
}
class RS_STracer : Actor
{
	Default { Radius 5; Height 5; Speed 15; Damage 22; RenderStyle "Add"; DamageType "Fire"; Alpha 0.67; Projectile;
		+FLOORHUGGER; +THRUGHOST; -NOGRAVITY; +DONTSPLASH; SeeSound "weapons/diasht"; DeathSound "weapons/firex3"; }
	States
	{
	Spawn:
		TNT1 A 1 Bright A_CStaffMissileSlither;
		TNT1 A 0 A_SpawnItem("RS_STracerPuff",0,0);
		Loop;
	Death:
		HELX ABC 4 Bright;
		Stop;
	}
}
class RS_BigHellshot : Actor
{
	Default { Radius 12; Height 20; Speed 7; Damage 110; Projectile; RenderStyle "Add"; DamageType "Fire"; Alpha 0.95; DeathSound "weapons/hellex";
		+THRUGHOST; Decal "Scorch"; Scale 1.75; }
	States
	{
	Spawn:
		HEPA ABCDEF 8 Bright A_SpawnItemEx("RS_RedPuff2",0,0,0,0,0,0,0,8);
		Loop;
	Death:
		HELX A 3 Bright A_Explode(90,200);
		HELX BC 3 Bright;
		Stop;
	}
}
class RS_Hellshot2 : Actor
{
	Default { Radius 8; Height 12; Speed 25; Damage 80; Projectile; RenderStyle "Add"; DamageType "Fire"; Alpha 0.95; DeathSound "weapons/hellex";
		+THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		HEPA ABCDEF 3 Bright A_SpawnItemEx("RS_RedPuff2",0,0,0,0,0,0,0,8);
		Loop;
	Death:
		HELX A 3 Bright A_Explode(40,128);
		HELX B 3 Bright A_CustomMissile("RS_STracer",0,0,0,CMF_AIMDIRECTION,random(0,360));
		HELX C 3 Bright;
		Stop;
	}
}
class RS_HammerShot : Actor
{
	Default { Radius 9; Height 14; Speed 32; Scale 1.45; Damage 85; Projectile; DamageType "Fire"; Alpha 0.95; DeathSound "weapons/hellex";
		+THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		FHFX A 0 A_PlaySound("Ice/Fly");
		FHFX ABCD 2;
		Loop;
	Death:
		FHFX EFG 4 Bright A_Explode(50,160);
		Stop;
	}
}
class RS_SmithHammer : Actor
{
	Default { Radius 5; Height 5; Speed 2; Damage 0; RenderStyle "Normal"; Projectile; -NOGRAVITY; +LOWGRAVITY; DeathSound "monsters/hamflr"; }
	States { Spawn: MAUL ABC 4; Loop; Death: MAUL D -1; Stop; }
}
class RS_MolochQuake : Actor
{
	Default { Speed 8; Damage 16; DamageType "Melee"; Radius 12; Height 16; RenderStyle "Translucent"; Alpha 0.1; Projectile;
		+DROPOFF; -NOGRAVITY; +FORCERADIUSDMG; +BLOODLESSIMPACT; +FLOORHUGGER; +RIPPER; SeeSound "moloch/thud"; }
	States
	{
	Spawn:
		IDGA CCAABBCCC 10 A_Explode(18,128);
	Death:
		IDGA C 1 A_Explode(18,128);
		Stop;
	}
}
class RS_PentaFire : Actor
{
	Default { Radius 8; Height 16; Speed 0; Damage 20; DamageType "Fire"; Projectile; +NOGRAVITY; RenderStyle "Add"; Alpha 0.85; Scale 1.0;
		DeathSound "weapons/firex3"; }
	States { Spawn: HEPA ABCDEF 4 Bright A_Explode(15,40); Stop; }
}
// PentaLine: radiating fire-line geometry. CH recurses PentaLine1->2->3->4 to draw a
// growing star; folded to a finite two-stage line that drops PentaFire along its path.
class RS_PentaLine2 : Actor
{
	Default { Radius 0; Height 32; Speed 16; RenderStyle "None"; Projectile; +FLOORHUGGER; +NOCLIP; }
	States { Spawn: TNT1 AAAAAAAAAAAAAAAA 1 A_SpawnItem("RS_PentaFire",0,0); Stop; }
}
class RS_PentaLine1 : Actor
{
	Default { Radius 0; Height 32; Speed 200; RenderStyle "None"; Projectile; +FLOORHUGGER; +NOCLIP; SeeSound "weapons/diasht"; }
	States
	{
	Spawn:
		TNT1 A 1;
		TNT1 A 0 A_CustomMissile("RS_PentaLine2",0,0,-198,2);
		TNT1 A 0 A_CustomMissile("RS_PentaLine2",0,0,198,2);
		Stop;
	}
}
class RS_PentaLine3 : RS_PentaLine1 {}
class RS_SmithFire : Actor
{
	Default { Radius 2; Height 2; Damage 0; +NOCLIP; Speed 0; Projectile; RenderStyle "Add"; Alpha 0.75; SeeSound "Weapons/hellex"; }
	States { Spawn: MNSM ABCDEFGHIJKLMNOPQ 3 Bright; Stop; }
}
class RS_SmithDeathFire : Actor
{
	Default { Radius 6; Height 8; Speed 0; Damage 8; DamageType "Fire"; Projectile; +NOGRAVITY; +FLOORHUGGER; RenderStyle "Add"; Alpha 0.7; }
	States { Spawn: MNSM ABCDEFGH 4 Bright A_Explode(8,40); Stop; }
}
class RS_SmithDFSpawner : Actor
{
	Default { Radius 0; Height 1; Speed 0; Damage 0; RenderStyle "None"; ReactionTime 300; Projectile; +NOEXPLODEFLOOR; }
	States
	{
	Spawn:
		TNT1 A 1 A_CustomMissile("RS_SmithDeathFire",0,0,0,2,90);
		TNT1 A 0 A_CountDown;
		Loop;
	Death:
		TNT1 A 1;
		Stop;
	}
}
class RS_SmithGhost2 : Actor
{
	Default { Radius 40; Height 70; Speed 1; Damage 25; DamageType "Melee"; RenderStyle "Translucent"; Alpha 0.5; Projectile; }
	States { Spawn: BSMT O 35; BSMT O 2 A_FadeOut(0.10); Loop; }
}
class RS_ZappersCB : Actor
{
	Default { Radius 6; Height 8; Speed 15; FastSpeed 38; Mass 50; Damage 20; DamageType "Plasma"; Projectile;
		+CEILINGHUGGER; +FLOAT; +NOGRAVITY; +RANDOMIZE; RenderStyle "Add"; Gravity 7; Alpha 1; Scale 1.3;
		SeeSound "caco/attack"; DeathSound "fire/fire5"; Translation "112:127=192:207"; }
	States
	{
	Spawn:
		STRS AB 2 Bright A_Wander;
		STRS CD 2 Bright A_SeekerMissile(4,4);
		Loop;
	Death:
		BBOM CD 3 Bright A_Explode(20,96);
		BBOM EFG 6 Bright;
		Stop;
	}
}
class RS_Zap88B : Actor
{
	// the Black cyber's lightning zap (LITN); named ...B to avoid clashing with shared RS_Zap88
	Default { Radius 6; Height 8; Speed 30; Damage 18; DamageType "Plasma"; Projectile; +THRUGHOST; RenderStyle "Add"; Alpha 0.8;
		Translation "112:127=192:207"; SeeSound "Litn/litn2"; }
	States { Spawn: LITN ABCDEFG 3 Bright; Loop; Death: LITN GOP 3 Bright A_Explode(18,48); Stop; }
}

// ---------- WHITE (BSMT+MMDR body): Romero-themed scatter/seek balls + reflective shield ----------
class RS_TrailSPRomero : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.5; Scale 0.7; Translation "0:255=%[0.00,0.40,0.00]:[2.00,2.00,1.01]"; }
	States { Spawn: SPER AB 4 Bright A_FadeOut(0.15); Stop; }
}
class RS_RomeroCHScatter : Actor
{
	Default { Radius 7; Height 7; Speed 38; Damage 55; DamageType "Plasma"; Projectile; +RANDOMIZE; +DONTHARMCLASS; +THRUSPECIES; Species "Daikatana";
		RenderStyle "Add"; Alpha 0.85; Scale 0.95; SeeSound "ELECTRO8"; DeathSound "Crack/death";
		Translation "0:255=%[0.00,0.40,0.00]:[2.00,2.00,1.01]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		SPER A 1 Bright A_SpawnItemEx("RS_TrailSPRomero",0,0,0,0,0,0,0,128);
		SPER B 1 Bright;
		Loop;
	Death:
		SPER AB 4 Bright A_Explode(40,96);
		Stop;
	}
}
class RS_RomeroCHSeekBall : Actor
{
	Default { Radius 5; Height 5; Speed 30; Damage 55; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; +DONTHARMCLASS; +THRUSPECIES; Species "Daikatana";
		RenderStyle "Add"; Alpha 0.75; Scale 0.85; SeeSound "ELECTRO8"; DeathSound "Crack/death";
		Translation "0:255=%[0.00,0.40,0.00]:[2.00,2.00,1.01]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		SPER A 1 Bright A_SeekerMissile(4,4);
		SPER B 1 Bright A_SpawnItemEx("RS_TrailSPRomero",0,0,0,0,0,0,0,128);
		Loop;
	Death:
		SPER AB 4 Bright A_Explode(40,96);
		Stop;
	}
}
// The orbiting reflective shield the White cyber wears. Reflects/deflects shots.
class RS_IDShieldWalk : Actor
{
	Default { Radius 60; Height 72; Speed 1; Species "Daikatana"; Health 999; +NOTARGET; +DONTTHRUST; +NOGRAVITY;
		+INVULNERABLE; +MTHRUSPECIES; +REFLECTIVE; +SHIELDREFLECT; +THRUSPECIES; +NOBLOCKMAP;
		RenderStyle "Add"; Alpha 0.6; Scale 1.25; Translation "0:255=%[0.00,0.40,0.00]:[2.00,2.00,1.01]"; }
	States
	{
	Spawn:
		MMDR A 2 Bright A_Warp(AAPTR_MASTER,0,0,0,0,WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE);
		Loop;
	}
}

// =====================================================================
// FAMILY 17 SECOND PASS -- the pieces RS_Cyberdemon.zs needs that this
// library did not carry yet. Ported from CHP\DECORATE\17\17_*.txt.
// Purely-cosmetic sub-spawn chains (particle walls, puddle litter,
// smoke) are folded into the actors' own animations rather than
// dragging a dozen more decoration classes across; every damaging
// component is kept.
// =====================================================================

// ---------- T03 CYAN: the hover exhaust under the cyan cybie.
class RS_CyanCybieHover : Actor
{
	Default { Radius 2; Height 2; Speed 1; +NOINTERACTION; +NOBLOCKMAP;
		RenderStyle "Add"; Alpha 0.7; Scale 0.6; }
	States
	{
	Spawn:
		TNT1 A 0;
		SSBL I 3 Bright;
	Death:
		SSBL I 3 Bright A_SetScale(0.43, 0.10);
		SSBL I 3 Bright A_SetScale(0.66, 0.10);
		SSBL J 3 Bright A_SetScale(0.89, 0.10);
		SSBL KKK 3 Bright A_FadeOut(0.20);
		Stop;
	}
}

// ---------- T04 PURPLE: the "worry" bomb planted by A_VileTarget.
class RS_PurpleWorryCB : Actor
{
	Default { Radius 10; Height 20; Speed 1; +NOGRAVITY; +NOCLIP; +NOBLOCKMAP;
		RenderStyle "Add"; Alpha 0.9; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		SBFX HIJKHIJK 7 Bright;
		Goto Death;
	Death:
		TNT1 A 0 A_Scream;
		MISL B 5 Bright A_SetScale(3, 0.45);
		MISL C 5 Bright A_Explode(random(40, 90), 128);
		MISL D 5 Bright;
		Stop;
	}
}

// ---------- T05 YELLOW: the disaster shower. CHP drops a marker that
// spawns its rain source at the ceiling; the rain itself is the
// already-ported RS_CybieRain.
class RS_ShoweringCB2 : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; }
	States
	{
	Spawn:
		TNT1 A 4;
		TNT1 AAAAAAAA 3 A_SpawnItemEx("RS_CybieRain", random(-96, 96), random(-96, 96), 0, 0, 0, random(-14, -6), random(0, 359), SXF_NOCHECKPOSITION);
		TNT1 AAAAAAAA 2 A_SpawnItemEx("RS_CybieRain", random(-160, 160), random(-160, 160), 0, 0, 0, random(-14, -6), random(0, 359), SXF_NOCHECKPOSITION);
		Stop;
	}
}
class RS_ShoweringCB : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItemEx("RS_ShoweringCB2", 0, 0, 32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		Stop;
	}
}

// ---------- T05 YELLOW: the arm that tears off on death.
class RS_SuperDemonArm : Actor
{
	Default { Radius 8; Height 8; Speed 1; Damage 1; Projectile; -NOGRAVITY;
		+DOOMBOUNCE; BounceFactor 0.4; }
	States
	{
	Spawn:
		SUPH A 5 A_SpawnItemEx("Blood", 0, 0, 6, frandom(-3, 3), frandom(-3, 3), frandom(1, 4), 0, SXF_NOCHECKPOSITION);
		SUPH B 5 A_SpawnItemEx("Blood", 0, 0, 6, frandom(-3, 3), frandom(-3, 3), frandom(1, 4), 0, SXF_NOCHECKPOSITION);
		SUPH C 5 A_SpawnItemEx("Blood", 0, 0, 6, frandom(-3, 3), frandom(-3, 3), frandom(1, 4), 0, SXF_NOCHECKPOSITION);
		Goto Death;
	Death:
		SUPH D 5 A_SpawnItemEx("Blood", 0, 0, 6, frandom(-3, 3), frandom(-3, 3), frandom(1, 4), 0, SXF_NOCHECKPOSITION);
		SUPH E -1;
		Stop;
	}
}

// =====================================================================
// T10 RED -- Moloch's volcano kit (17_R).
// =====================================================================
class RS_VolcanoBall1 : Actor
{
	Default { Radius 8; Height 8; Speed 18; Damage 20; DamageType "Fire";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; Scale 1.0;
		SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		BAL3 AB 2 Bright;
		Loop;
	Death:
		BAL3 CDE 4 Bright A_Explode(random(5, 10), 88);
		Stop;
	}
}
class RS_VolcanoBall2 : RS_VolcanoBall1
{
	Default { Speed 16; Damage 25; +SEEKERMISSILE; }
	States
	{
	Spawn:
		BAL3 AB 2 Bright A_SeekerMissile(4, 8);
		Loop;
	Death:
		BAL3 CDE 4 Bright A_Explode(random(11, 33), 108);
		Stop;
	}
}
class RS_VolcanoBall3 : RS_VolcanoBall1
{
	Default { Speed 16; Damage 25; }
	States
	{
	Spawn:
		BAL3 AB 2 Bright;
		Loop;
	Death:
		BAL3 CDE 4 Bright A_Explode(random(12, 45), 108);
		Stop;
	}
}
class RS_SoulBomb4 : Actor
{
	Default { Radius 12; Height 12; Speed 12; Damage 40; DamageType "Fire";
		Projectile; +SEEKERMISSILE; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; Scale 1.2;
		SeeSound "moloch/attack"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		RED9 B 1 Bright A_SeekerMissile(1, 1);
		RED9 AA 1 Bright;
		Loop;
	Death:
		SPIR A 1 Bright A_SetScale(2);
		SPIR ABCDEDCBA 5 Bright A_Explode(random(10, 30), 128, 0);
		SPIR E 1;
		Stop;
	}
}
// The wandering volcano vent: drifts, then erupts a scatter of balls.
// CHP's RedCybieVolcano2 spray is folded into the death here.
class RS_RedCybieVolcano1 : Actor
{
	Default { Radius 10; Height 10; Speed 10; Damage 15; DamageType "Fire";
		Projectile; +NOGRAVITY; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9;
		DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		RED8 ABCFGH 3 Bright A_Wander;
		RED8 A 1 Bright A_Jump(24, "Death");
		Loop;
	Death:
		RED8 ABCD 4 Bright A_SetScale(0.5);
		RED8 CDE 4 A_SpawnItemEx("RS_VolcanoBall1", random(-328, 328), random(-328, 328), 3, 0, 0, frandom(2, 8), random(0, 359), SXF_NOCHECKPOSITION);
		RED8 CDE 1;
		Stop;
	}
}

// =====================================================================
// T08 BROWN -- the composter's slime kit (17_BR).
// =====================================================================
class RS_BCybieGreenWave : Actor
{
	Default { Radius 8; Height 8; Speed 1; Damage 20; DamageType "Fire";
		+NOGRAVITY; +NOBLOCKMAP; RenderStyle "Add"; Alpha 0.9; }
	States
	{
	Spawn:
		TNT1 A 0;
		GR3P ABCDEFGHIJKLM 3 Bright;
		GR3P M 1 Bright;
		GR3P M 3 Bright A_SetScale(2.0, 2.0);
		GR3P M 3 Bright A_SetScale(2.5, 2.5);
		GR3P MMM 3 Bright A_FadeOut(0.33);
		Stop;
	Death:
		GR3P M 1 Bright;
		GR3P M 3 Bright A_SetScale(2.0, 2.0);
		GR3P M 3 Bright A_SetScale(2.5, 2.5);
		GR3P MMM 3 Bright A_FadeOut(0.33);
		Stop;
	}
}
class RS_BCybieGreenWave2 : Actor
{
	Default { Radius 8; Height 8; Speed 1; Damage 20; DamageType "Fire";
		+NOGRAVITY; +NOBLOCKMAP; RenderStyle "Add"; Alpha 0.9;
		SeeSound "weapons/rocklx"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_SetScale(0.75, 0.75);
		GR3P ABCDEFGHIJKLM 3 Bright A_Explode(random(4, 40), 96, 0);
		GR3P MMM 3 Bright A_FadeOut(0.33);
		Stop;
	Death:
		GR3P MMM 3 Bright A_FadeOut(0.33);
		Stop;
	}
}
// The green detonation ring: two arms warp outwards from the cybie,
// dropping a wave every tic until they reach 512 units.
class RS_BCybExplosionSet : Actor
{
	protected int rsAngle, rsFurther;
	protected int rsStep;
	Default { Radius 4; Height 4; Speed 18; +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; }
	States
	{
	Spawn:
		TNT1 A 0 { rsStep = 12; }
	Fly:
		TNT1 A 1 { rsAngle += rsStep; rsFurther += 12;
		           A_SpawnItemEx("RS_BCybieGreenWave2", 0, 0, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		           A_Warp(AAPTR_MASTER, rsFurther, 0, 32, rsAngle, WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE);
		           if (rsFurther >= 512 || !master) return ResolveState("Death"); return ResolveState(null); }
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
class RS_BCybExplosionSet2 : RS_BCybExplosionSet
{
	States
	{
	Spawn:
		TNT1 A 0 { rsStep = -12; }
		Goto Fly;
	}
}
class RS_BCybExplosionSet3 : Actor
{
	Default { Radius 4; Height 4; Speed 18; Projectile; +NOGRAVITY; +NOINTERACTION; }
	States
	{
	Spawn:
		TNT1 A 6 A_SpawnItemEx("RS_BCybieGreenWave2", 0, 0, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
class RS_BCybieGreenExpand : Actor
{
	Default { Radius 4; Height 4; Speed 1; +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.8; }
	States
	{
	Spawn:
		TNT1 A 0;
		"8CYB" K 3 Bright;
		"8CYB" K 3 Bright A_SetScale(1.4, 1.4);
		"8CYB" K 3 Bright A_SetScale(1.5, 1.5);
		"8CYB" K 3 Bright A_SetScale(1.6, 1.6);
		"8CYB" K 3 Bright A_SetScale(1.7, 1.7);
		"8CYB" KKK 3 Bright A_FadeOut(0.33);
		Stop;
	Death:
		"8CYB" KKK 3 Bright A_FadeOut(0.33);
		Stop;
	}
}
// The acid pool: a delayed splash that eats a wide circle of floor.
class RS_BCybAcidPuddle : Actor
{
	Default { Radius 12; Height 16; Speed 1; +NOGRAVITY; +NOCLIP; +NOBLOCKMAP;
		RenderStyle "Add"; Alpha 0.9; }
	States
	{
	Spawn:
		TNT1 A 10;
		TNT1 A 0 A_StartSound("brownCybie/DeepShot", CHAN_BODY);
		TNT1 A 10;
		SSBL A 5;
	SplashIt:
		SSBL AB 2 Bright;
		TNT1 A 0 A_StartSound("monster/tenpn2", CHAN_BODY);
		TNT1 A 0 A_Explode(random(1, 8), 64, 0);
		SSBL CD 2 Bright;
		SSBL EF 2 Bright;
		TNT1 A 0 A_StartSound("monster/tenpn2", CHAN_BODY);
		TNT1 A 0 A_Explode(random(1, 8), 64, 0);
		SSBL GH 2 Bright;
		Goto Death;
	Death:
		SSBL K 4 Bright A_SetScale(0.6);
		SSBL I 4 Bright A_SetScale(0.4);
		SSBL K 4 Bright A_SetScale(0.2);
		SSBL J 4 Bright A_SetScale(0.075);
		TNT1 AAA 0 A_SpawnItemEx("RS_GreenBalb2", random(-6, 6), random(-6, 6), random(6, 12), random(1, 11), 0, random(1, 11), random(0, 359), SXF_NOCHECKPOSITION);
		Stop;
	}
}
// The slime drill: half of them home, half wander, both leave a trail.
class RS_BCybSlimeSet : Actor
{
	Default { Radius 8; Height 8; Speed 18; Damage 22; DamageType "Fire";
		Projectile; +FLOORHUGGER; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85; Scale 0.7; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_Jump(128, "Homing");
	Wandering:
		GR3P A 1 Bright;
		TNT1 AAA 0 A_Wander;
		GR3P B 1 Bright A_SpawnItemEx("RS_Splash11", 0, -1, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		Loop;
	Homing:
		TNT1 A 0 { bSEEKERMISSILE = true; }
	HomingLoop:
		GR3P A 1 Bright A_SpawnItemEx("RS_Splash11", 0, -1, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		GR3P B 1 Bright A_SeekerMissile(3, 3);
		Goto HomingLoop;
	XDeath:
		TNT1 AAAAA 0 A_SpawnItemEx("RS_Splash11", random(-32, 32), random(-32, 32), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		Stop;
	Death:
		GR3P MMM 2 Bright A_FadeOut(0.33);
		Stop;
	}
}

// =====================================================================
// T12 WHITE -- Romero's kit (17_W).
// =====================================================================
class RS_RomeroGroundCH : Actor
{
	Default { Radius 20; Height 40; Speed 10; Damage 60; DamageType "Fire";
		Projectile; +NOCLIP; +NOGRAVITY; RenderStyle "Add"; Alpha 0.95;
		DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Death;
	Death:
		TNT1 A 0 A_ScreamAndUnblock;
		BRBA ONMLK 3 Bright A_Explode(random(10, 80), 64, 0);
		BRBA ABCDEFGHIJ 2 Bright;
		Stop;
	}
}
class RS_RomeroBeamCH : FastProjectile
{
	Default { Radius 20; Height 20; Speed 50; Damage 100; DamageType "Plasma";
		Projectile; +DONTHARMSPECIES; +THRUSPECIES; Species "Daikatana";
		RenderStyle "Add"; Alpha 1.0; Scale 2.25;
		SeeSound "ELECTRO7"; DeathSound "weapons/bfgx";
		Translation "0:255=%[0.00,0.40,0.00]:[2.00,2.00,1.01]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BRBA O 1 Bright A_Explode(random(10, 80), 64, 0);
		BRBA N 1 Bright A_Explode(random(10, 80), 64, 0);
		BRBA M 1 Bright A_Explode(random(10, 80), 64, 0);
		BRBA L 1 Bright A_Explode(random(10, 80), 64, 0);
		BRBA K 1 Bright A_Explode(random(10, 80), 64, 0);
		Loop;
	Death:
		BRBA O 3 Bright A_SetScale(3.0, 2.5);
		TNT1 A 0 A_Explode(random(60, 180), 128, 0);
		BRBA N 3 Bright A_SetScale(3.8, 2.15);
		BRBA M 3 Bright A_SetScale(3.0, 1.85);
		BRBA L 3 Bright A_SetScale(2.5, 1.75);
		BRBA K 3 Bright A_SetScale(2.25, 2.25);
		BRBA ABCDEFGHIJ 3 Bright;
		Stop;
	}
}
class RS_RomeroRocketCH : FastProjectile
{
	Default { Radius 12; Height 8; Speed 33; Damage 60; DamageType "Fire";
		Projectile; +DONTHARMSPECIES; +THRUSPECIES; Species "Daikatana"; Scale 0.95;
		SeeSound "weapons/hominglaunch"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		MSLH A 2 Bright;
		Loop;
	Death:
		MISL B 0 A_SetTranslucent(0.8, 1);
		TNT1 A 0 A_SetScale(1.45, 0.95);
		MISL B 4 Bright A_Explode(random(80, 180), 128);
		MISL CD 4 Bright;
		Stop;
	}
}
class RS_RomeroRocketCH2 : RS_RomeroRocketCH
{
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		MSLH A 1 Bright;
		MSLH A 1 Bright A_Weave(3, 3, 3, 3);
		Loop;
	}
}
class RS_RomeroRocketCH3 : RS_RomeroRocketCH
{
	Default { +SEEKERMISSILE; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		MSLH A 1 Bright;
		MSLH A 2 Bright A_SeekerMissile(4, 4);
		Loop;
	}
}
class RS_RomeroSkyCH : Actor
{
	Default { Radius 20; Height 40; Speed 10; Damage 60; DamageType "Plasma";
		Projectile; +NOCLIP; +NOGRAVITY; RenderStyle "Add"; Alpha 0.95; }
	States
	{
	Spawn:
		TNT1 A 8;
		Goto Death;
	Death:
		BRBA OOOOO 2 Bright;
		BRBA OOONNNMMMLLLKKK 1 Bright A_SpawnItemEx("RS_RomeroBeamCH", random(-64, 64), random(-64, 64), -24, random(1, 8), 0, random(-33, -1), random(-359, 359), SXF_NOCHECKPOSITION);
		BRBA ABCDEFGHIJ 2 Bright;
		Stop;
	}
}
class RS_SpamShotsRomeroCH : Actor
{
	Default { Radius 14; Height 10; Speed 25; Damage 90; DamageType "Plasma";
		Projectile; +RANDOMIZE; +SEEKERMISSILE; +DONTHARMSPECIES; +THRUSPECIES;
		Species "Daikatana"; RenderStyle "Add"; Alpha 0.85; Scale 0.82;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx"; }
	States
	{
	Spawn:
		BRBA K 2 Bright A_SeekerMissile(2, 3);
		BRBA L 2 Bright;
		Loop;
	Death:
		BRBA MNO 4 Bright A_Explode(40, 96, 0);
		Stop;
	}
}

// ============================================================================
// BLACK EX (17_KX) -- "Obsidian Tyrant". The Smith taken to its EX form.
// Everything here is a straight read of 17_KX.txt; where CHP writes the same
// A_CustomMissile line 24 or 36 times to draw a ring, this file uses the
// for-loop form already used by RS_Cyberdemon's T11 melee -- same shots,
// same angles, same order.
// ============================================================================

class RS_HellFX : Actor
{
	Default { Radius 5; Height 5; Speed 0; Damage 0; Projectile; RenderStyle "Add"; DamageType "Fire"; Alpha 0.8;
		SeeSound "weapons/firex3"; }
	States
	{
	Spawn:
		HELX A 3 Bright;
		HELX B 3 Bright A_Explode(random(5, 40), 96, 0);
		HELX CDEFGHIJ 3 Bright;
		Stop;
	}
}
class RS_HellBoom : Actor
{
	Default { Radius 8; Height 8; Speed 6; Damage 0; Projectile; RenderStyle "Add"; Alpha 0.8;
		+RIPPER; +THRUGHOST; +BLOODLESSIMPACT; SeeSound "weapons/firex3"; }
	States { Spawn: TNT1 AAAAA 6 A_SpawnItem("RS_HellFX", 0, 0); Stop; }
}
class RS_HellShotEX2 : Actor
{
	Default { DontHurtShooter; Radius 13; Height 16; Speed 15; DamageFunction (random(20, 50)); DamageType "Supremesmith"; Projectile;
		RenderStyle "Add"; Alpha 0.9; +THRUGHOST; -NOGRAVITY;
		SeeSound "weapons/firbfi"; DeathSound "weapons/firex3"; }
	States
	{
	Spawn:
		BAL3 AB 2 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, 0, 0, 0, 0, 2);
		Loop;
	Death:
		BAL3 CDE 4 Bright A_Explode(random(20, 50), 96, 0);
		Stop;
	}
}
class RS_STracerEX : RS_STracer
{
	Default { Speed 20; }
	States
	{
	XDeath:
		FTRA KKKKKKKKKKKKKKKK 0 A_SpawnItemEx("RS_Firespe2", 0, 0, 0, random(-16, 16), random(-16, 16));
	Death:
		FTRA K 4 Bright;
		FTRA L 4 Bright A_Explode(random(5, 15), 64);
		FTRA MNO 3 Bright;
		Stop;
	}
}
// The rolling shockwave a hellshot leaves behind: a 24-tracer ring with a
// coin-flip chance of firing again before it fades.
class RS_HellWaverEX : Actor
{
	Default { DontHurtShooter; Radius 8; Height 12; Speed 25; DamageFunction (random(40, 120)); Projectile; RenderStyle "Add";
		DamageType "Fire"; Alpha 0.95; DeathSound "weapons/hellex"; +THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		HADE LKJI 6;
		Goto WaveIt;
	WaveIt:
		HEPA ABCDE 2;
		HEPA F 0 { for (int i = 0; i < 24; i++) A_SpawnProjectile("RS_STracerEX", 0, 0, i * 15, 0); }
		HEPA F 0 A_Jump(128, "WaveIt");
		HEPA F 5;
		Goto Death;
	Death:
		HADE IJKL 8;
		Stop;
	}
}
// CH HellWaver2 carrying 17_K's speed/damage: the slower three-pulse version
// the BigHell star leaves behind when it detonates.
class RS_HellWaver2 : Actor
{
	Default { DontHurtShooter; Radius 8; Height 12; Speed 25; DamageFunction (random(40, 120)); Projectile; RenderStyle "Add";
		DamageType "Fire"; Alpha 0.95; DeathSound "weapons/hellex"; +THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		HADE LKJI 6;
		Goto WaveIt;
	WaveIt:
		HEPA ABCDE 7;
		HEPA F 0 { for (int i = 0; i < 24; i++) A_SpawnProjectile("RS_STracer", 0, 0, i * 15, 0); }
		HEPA F 5;
		HEPA ABCDE 7;
		HEPA F 0 { for (int i = 0; i < 24; i++) A_SpawnProjectile("RS_STracer", 0, 0, i * 15, 0); }
		HEPA F 5;
		HEPA ABCDE 7;
		HEPA F 0 { for (int i = 0; i < 24; i++) A_SpawnProjectile("RS_STracer", 0, 0, i * 15, 0); }
		HEPA F 0 A_Jump(128, "WaveIt");
		HEPA F 5;
		Goto Death;
	Death:
		HADE IJKL 8;
		Stop;
	}
}
class RS_HellShotEX : Actor
{
	Default { DontHurtShooter; Radius 8; Height 12; Speed 30; DamageFunction (random(40, 120)); Projectile; RenderStyle "Add";
		DamageType "Fire"; Alpha 0.95; SeeSound "weapons/firbfi"; DeathSound "weapons/hellex";
		+THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		HEPA ABCDEF 3 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, 0, 0, 0, 0, 8);
		Loop;
	Death:
		HELX A 3 Bright;
		HELX B 0 { for (int i = 0; i < 8; i++) A_SpawnProjectile("RS_HellBoom", 0, 0, i * 45, CMF_AIMDIRECTION | CMF_TRACKOWNER); }
		HELX BBB 0 A_SpawnProjectile("RS_HellShotEX2", 0, 0, random(0, 360), CMF_AIMDIRECTION, random(50, 75));
		HELX B 3 Bright A_Explode(random(20, 80), 128);
		HELX CDEFGHIJ 3 Bright;
		HELX J 0 A_SpawnItemEx("RS_HellWaverEX", 0, 0, 0);
		Stop;
	}
}
class RS_HSHomer : Actor
{
	Default { DontHurtShooter; Radius 8; Height 12; Speed 22; DamageFunction (random(20, 80)); Projectile; RenderStyle "Add";
		DamageType "Fire"; Alpha 0.95; SeeSound "weapons/hellfi"; DeathSound "weapons/hellex";
		+THRUGHOST; +SEEKERMISSILE; +EXTREMEDEATH; Decal "Scorch"; }
	States
	{
	Spawn:
		MSP2 A 2 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, 0, 0, 0, 0, 8);
		MSP2 A 0 A_SeekerMissile(25, 25, SMF_PRECISE);
		MSP2 B 2 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, 0, 0, 0, 0, 8);
		MSP2 B 0 A_SeekerMissile(25, 25, SMF_PRECISE);
		MSP2 C 2 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, 0, 0, 0, 0, 8);
		MSP2 C 0 A_SeekerMissile(25, 25, SMF_PRECISE);
		MSP2 D 2 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, 0, 0, 0, 0, 8);
		MSP2 D 0 A_SeekerMissile(25, 25, SMF_PRECISE);
		Loop;
	Death:
		MSP2 EFGHI 4 Bright A_Explode(random(5, 15), 64);
		Stop;
	}
}
class RS_BigHellCybEX3 : RS_HSHomer { Default { -SEEKERMISSILE; } }
class RS_HSFlameBlastTrail : Actor
{
	Default { RenderStyle "Add"; Alpha 0.5; +NOBLOCKMAP; +NOGRAVITY; }
	States { Spawn: CFFX NOP 2; Stop; }
}
class RS_HSFlameBlast : FastProjectile
{
	Default { DontHurtShooter; Radius 8; Height 12; Speed 72; DamageFunction (random(20, 40)); Scale 1.5; Projectile; RenderStyle "Add";
		DamageType "Fire"; Alpha 0.95; SeeSound "weapons/hellfi"; DeathSound "weapons/firbfi";
		+THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		CFFX N 1 Bright A_SpawnItemEx("RS_HSFlameBlastTrail", -10, 0, 0, 0, 0, 0, 0, 128);
		Loop;
	Death:
		CFFX A 0 { for (int i = 0; i < 8; i++) A_SpawnProjectile("RS_DFlare", 8, 0, i * 45, CMF_AIMDIRECTION, 0); }
	XDeath:
		CFFX A 3 Bright;
		CFFX BCDEFGHIJK 3 Bright A_Explode(random(5, 15), 32, 0);
		CFFX LM 3 Bright;
		Stop;
	}
}
// The thrown lightning: a bouncing seeker that ends in a BFG-sized burst.
class RS_ZapCybEX : Actor
{
	Default { DontHurtShooter; Radius 17; Height 15; Speed 32; DamageFunction (random(20, 50)); Projectile; RenderStyle "Add";
		Alpha 0.85; Scale 1.6; SeeSound "Litn/litn2"; +THRUGHOST; +SEEKERMISSILE;
		BounceType "Hexen"; BounceCount 5; BounceFactor 2.0; WallBounceFactor 2.0;
		Translation "192:199=[255,255,255]:[191,0,255]"; Decal "Scorch"; }
	States
	{
	Spawn:
		LITN B 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN B 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		LITN C 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN C 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		LITN D 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN D 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		LITN E 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN E 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		LITN F 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN F 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		LITN G 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN G 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		LITN O 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN O 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		LITN P 0 A_SeekerMissile(5, 10, SMF_PRECISE);
		LITN P 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		Loop;
	Death:
		PLSE B 0 A_StartSound("weapons/bfgx");
		PLSE B 0 A_SetScale(3.5, 3.5);
		PLSE BBBBBBBBBBBBBBBBBBBBBBBB 0 A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, random(-20, 20), random(-20, 20), random(-20, 20), 0, SXF_NOCHECKPOSITION | SXF_TRANSFERTRANSLATION);
		PLSE BCD 5 Bright A_Explode(random(10, 30), 192, 0);
		PLSE E 5 Bright;
		Stop;
	}
}
// The healing pentagram: five arms, each drawing a green fire line. Unlike
// the damaging PentaLine the arms carry no damage -- the heal is on the boss.
class RS_PentaHealFire : Actor
{
	Default { Radius 0; Height 32; Speed 0; Alpha 0.85; ReactionTime 2; Projectile;
		+FLOORHUGGER; +DONTSPLASH; -NOGRAVITY; RenderStyle "Add";
		Translation "0:255=%[0.00,0.00,0.00]:[0.00,2.00,0.00]"; }
	States
	{
	Spawn:
		CFCF A 1 Bright;
		CFCF A 2 Bright A_StartSound("weapons/onfire");
		CFCF BCDEFGHIJKLM 3 Bright;
		CFCF A 0 A_CountDown();
		Loop;
	Death:
		CFCF NOP 3 Bright;
		Stop;
	}
}
class RS_PentaHealCybEX2 : Actor
{
	Default { Radius 0; Height 32; Speed 16; Alpha 0.85; Projectile; +FLOORHUGGER; +NOCLIP; }
	States { Spawn: TNT1 AAAAAAAAAAAAAAAA 1 A_SpawnItem("RS_PentaHealFire", 0, 0); Stop; }
}
class RS_PentaHealCybEX : Actor
{
	Default { Radius 0; Height 32; Speed 200; Alpha 0.85; Projectile; +FLOORHUGGER; +NOCLIP; }
	States
	{
	Spawn:
		TNT1 A 1;
		TNT1 A 0 A_StartSound("Ice/Cast");
		TNT1 A 0 A_SpawnProjectile("RS_PentaHealCybEX2", 0, 0, -198, CMF_AIMDIRECTION);
		TNT1 A 0 A_SpawnProjectile("RS_PentaHealCybEX2", 0, 0, 198, CMF_AIMDIRECTION);
		Stop;
	}
}
// The afterimage the Tyrant leaves along a charge -- it hits on contact.
class RS_HSGhostEX : Actor
{
	Default { Radius 40; Height 70; Speed 1; DamageFunction (random(12, 34)); DamageType "Melee";
		RenderStyle "Translucent"; Alpha 0.5; Projectile; }
	States
	{
	Spawn:
		HSMI H 35;
	Fade:
		HSMI H 2 A_FadeOut(0.10);
		Loop;
	}
}
// The hammer it throws away as it dies: no thrust, just gravity and RIP.
class RS_HSHammer : Actor
{
	Default { Radius 6; Height 8; Damage 10; Speed 0; Projectile; +RANDOMIZE; +RIPPER; -NOGRAVITY;
		RenderStyle "Normal"; DeathSound "hellsmith/miss"; }
	States
	{
	Spawn:
		HAMM ABC 3;
	Fall:
		HAMM D 3;
		Loop;
	Death:
	Crash:
		HAMM EFG 3;
		HAMM G -1;
		Stop;
	}
}
// BIGHELL, stage 3: the star itself. Rips forward shedding side-missiles and
// a 24-tracer ring every cycle, and its death is the single biggest event in
// the family -- a 256/512 blast, a 36-way boom ring, eight hellshots, then a
// HellWaver on top.
class RS_BigHellCybEX2 : Actor
{
	Default { DontHurtShooter; Species "Cybie"; Radius 32; Height 16; Speed 1; Scale 2.5; DamageFunction (random(200, 400));
		Projectile; RenderStyle "Add"; DamageType "Supremesmith"; Alpha 0.95; DeathSound "weapons/hellex";
		+THRUGHOST; +THRUSPECIES; +DONTHARMSPECIES; Decal "Scorch"; }
	States
	{
	Spawn:
		HEPA A 0 NoDelay A_ScaleVelocity(4);
	Fly:
		HEPA AAAABBBB 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA A 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, 90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA A 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, -90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA CCCCDDDD 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA D 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, 90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA D 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, -90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA EEEEFFFF 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA F 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, 90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA F 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, -90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA AAAABBBB 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA A 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, 90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA A 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, -90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA CCCCDDDD 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA D 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, 90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA D 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, -90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA EEEEFFFF 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA F 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, 90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA F 0 A_SpawnProjectile("RS_BigHellCybEX3", 0, 0, -90, CMF_AIMDIRECTION | CMF_TRACKOWNER, 0);
		HEPA F 0 { for (int i = 0; i < 24; i++) A_SpawnProjectile("RS_STracerEX", 0, 0, i * 15, CMF_AIMDIRECTION | CMF_TRACKOWNER); }
		Loop;
	Death:
		HELX A 0 A_Explode(256, 512, 0);
		HELX A 6 Bright A_SetScale(4.0);
		HELX A 0 { for (int i = 0; i < 36; i++) A_SpawnProjectile("RS_HellBoom", 0, 0, i * 10, CMF_AIMDIRECTION | CMF_TRACKOWNER); }
		HELX A 0 { for (int i = 0; i < 8; i++) A_SpawnProjectile("RS_HellShotEX", 0, 0, i * 45, CMF_AIMDIRECTION | CMF_TRACKOWNER); }
		HELX BCDEFGHIJ 6 Bright A_Explode(random(50, 100), 256);
		HELX J 0 A_SpawnItemEx("RS_HellWaver2", 0, 0, 0);
		Stop;
	}
}
// BIGHELL, stages 1-2: an orb that swells from scale 0.85 to 2.5 over roughly
// eight seconds -- the tell that the Tyrant has gone invulnerable and is
// building the star. The window is the thing to punish, not the orb.
class RS_BigHellCybEX : Actor
{
	Default { Species "Cybie"; RenderStyle "Add"; Alpha 0.95; Scale 0.85;
		+NOBLOCKMAP; +NOGRAVITY; +THRUSPECIES; }
	States
	{
	Spawn:
		HEPA AAABBBCCCDDD 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA D 0 A_SetScale(1.0);
		HEPA EEEFFFAAABBB 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA B 0 A_SetScale(1.15);
		HEPA CCCDDDEEEFFF 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA F 0 A_SetScale(1.3);
		HEPA AAABBBCCCDDD 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA D 0 A_SetScale(1.45);
		HEPA EEEFFFAAABBB 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA B 0 A_SetScale(1.6);
		HEPA CCCDDDEEEFFF 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA F 0 A_SetScale(1.75);
		HEPA AAABBBCCCDDD 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA D 0 A_SetScale(1.9);
		HEPA EEEFFFAAABBB 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA B 0 A_SetScale(2.05);
		HEPA CCCDDDEEEFFF 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA F 0 A_SetScale(2.2);
		HEPA AAABBBCCCDDD 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA D 0 A_SetScale(2.35);
		HEPA EEEFFFAAABBB 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA B 0 A_SetScale(2.5);
		HEPA CCCDDDEEEFFF 1 Bright A_SpawnItemEx("RS_RedPuff2", 0, 0, 0, random(-6, 6), random(-6, 6), random(-6, 6));
		HEPA D 0 A_StartSound("weapons/firbfi", CHAN_VOICE, CHANF_DEFAULT, 1.0, 0.4);
		TNT1 A 0 A_SpawnItemEx("RS_BigHellCybEX2", 0, 0, 0, 1, 0, 0, 0, SXF_TRANSFERPOINTERS);
		Stop;
	}
}

// ============================================================================
// WHITE EX (17_WX) -- "It crashes doom II". Romero's glitch. Read straight out
// of 17_WX.txt. The theme is corruption: nothing here flies straight, several
// of these actors are SOLID walls rather than damage, and two of them count
// their own iterations (CHP used a DewzanToken; here a private int).
// ============================================================================

// The visual noise that clings to the boss and to its glitch-barons.
class RS_RomeroEXGlitch : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOCLIP; RenderStyle "Add"; }
	States
	{
	Spawn:
		X404 A 0 { A_SetScale(frandom(1.2, 1.8), frandom(1.2, 1.8)); }
		X404 A 8 Bright A_Warp(AAPTR_TARGET, random(-20, 20), random(-20, 20), random(0, 128), 0, WARPF_NOCHECKPOSITION);
		Loop;
	}
}
// The bread-and-butter shot: a bouncing block of corrupted texture that
// jitters in a random direction every tic instead of travelling cleanly.
class RS_RomeroEXGlitchShot : Actor
{
	Default { Radius 13; Height 20; Damage 50; Speed 15; RenderStyle "Add"; DamageType "Melee";
		Species "Daikatana"; Projectile; DontHurtShooter;
		BounceType "Hexen"; +BOUNCEONWALLS; +BOUNCEONCEILINGS; +BOUNCEONFLOORS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		SeeSound "GLITCH"; DeathSound "GLITCH";
		BounceCount 3; BounceFactor 0.01; WallBounceFactor 0.01; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		X404 A 0 { A_SetScale(frandom(0.8, 1.2), frandom(0.8, 1.2)); }
		X404 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 Bright { Thrust(2.0, random(0, 360)); }
		X404 A 0 { A_StartSound("GLITCH", CHAN_5); }
		Loop;
	Death:
		TNT1 A 0 A_StopSound(CHAN_5);
		Stop;
	}
}
class RS_RomeroEXMegaGlitchShot : RS_RomeroEXGlitchShot
{
	Default { Damage 150; Speed 15; Scale 2.0; BounceCount 12;
		Translation "176:176=231:231", "231:231=200:200"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		X404 A 0 { A_SetScale(frandom(1.6, 2.4), frandom(1.6, 2.4)); }
		X404 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 Bright { Thrust(2.0, random(0, 360)); }
		X404 A 0 { A_StartSound("GLITCH", CHAN_5); }
		Loop;
	Death:
		TNT1 A 0 A_StopSound(CHAN_5);
		Stop;
	}
}
// A 64x110 seeking slab that hugs the floor. This is the attack that reads as
// the screen itself coming at you.
class RS_RomeroEXFourthWall : Actor
{
	Default { Radius 64; Height 110; Damage 200; Speed 17; DamageType "Melee"; Species "Daikatana";
		XScale 3.0; YScale 15.0; Projectile; DontHurtShooter;
		+FLOORHUGGER; +SEEKERMISSILE; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 { A_StartSound("4THWALL", CHAN_5, 0, 1.0, 0.4); }
	Fly:
		IDGA A 3 A_SeekerMissile(5, 5);
		Loop;
	Death:
		TNT1 A 0 A_StopSound(CHAN_5);
		Stop;
	}
}
class RS_RomeroBeamCHTrail : FastProjectile
{
	Default { Radius 20; Height 20; Speed 50; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.85;
		Scale 2.3; Projectile; Translation "0:255=%[0.00,0.40,0.00]:[2.00,2.00,1.01]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BRBA ONMLK 1 Bright;
		Goto Death;
	Death:
		BRBA ABCDEFGHIJ 1 Bright;
		Stop;
	}
}
class RS_RomeroEXBeamCHTrail : RS_RomeroBeamCHTrail
{
	Default { Species "Daikatana"; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		Translation "0:75=251:251", "149:219=199:199"; }
}
class RS_RomeroEXSpamShotsTrail : RS_RomeroEXBeamCHTrail
{
	Default { Translation "208:247=176:176", "168:200=4:4", "0:167=106:234"; Scale 1.45; }
}
// The beam. Explodes along its own length as it travels, and its DEATH is a
// counted loop -- it keeps detonating and growing for 100 iterations before it
// finally collapses. CHP counted with a DewzanToken; this is the same count.
class RS_RomeroEXBeamCH : FastProjectile
{
	private int rsBeamCount;
	Default { Radius 13; Height 8; Speed 60; Damage 20; DamageType "Plasma"; Species "Daikatana";
		Projectile; DontHurtShooter; RenderStyle "Add"; Alpha 0.9; Scale 2.5;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "0:75=251:251", "149:219=199:199"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BRBA O 1 Bright A_Explode(random(10, 80), 64, 0);
		TNT1 A 0 { A_SpawnItemEx("RS_RomeroEXBeamCHTrail", cos(pitch), 0, -sin(pitch), cos(pitch), 0, -sin(pitch), 0, SXF_NOCHECKPOSITION); }
		BRBA N 1 Bright A_Explode(random(10, 80), 64, 0);
		TNT1 A 0 { A_SpawnItemEx("RS_RomeroEXBeamCHTrail", cos(pitch), 0, -sin(pitch), cos(pitch), 0, -sin(pitch), 0, SXF_NOCHECKPOSITION); }
		BRBA M 1 Bright A_Explode(random(10, 80), 64, 0);
		TNT1 A 0 { A_SpawnItemEx("RS_RomeroEXBeamCHTrail", cos(pitch), 0, -sin(pitch), cos(pitch), 0, -sin(pitch), 0, SXF_NOCHECKPOSITION); }
		BRBA L 1 Bright A_Explode(random(10, 80), 64, 0);
		TNT1 A 0 { A_SpawnItemEx("RS_RomeroEXBeamCHTrail", cos(pitch), 0, -sin(pitch), cos(pitch), 0, -sin(pitch), 0, SXF_NOCHECKPOSITION); }
		BRBA K 1 Bright A_Explode(random(10, 80), 64, 0);
		Loop;
	Death:
		TNT1 A 0 { if (rsBeamCount >= 100) return ResolveState("Collapse"); return ResolveState(null); }
		BRBA O 3 Bright A_SetScale(3.0, 2.5);
		TNT1 A 0 A_Explode(random(60, 180), 128, 0);
		TNT1 A 0 { rsBeamCount++; }
		Loop;
	Collapse:
		BRBA N 3 Bright A_SetScale(3.8, 2.15);
		BRBA M 3 Bright A_SetScale(3.0, 1.85);
		BRBA L 3 Bright A_SetScale(2.5, 1.75);
		BRBA K 3 Bright A_SetScale(2.25, 2.25);
		BRBA ABCDEFGHIJ 3 Bright;
		Stop;
	}
}
class RS_RomeroEXSeekTrail : RS_TrailSPRomero
{
	Default { Species "Daikatana"; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		Translation "0:148=176:176", "160:167=112:112", "224:231=231:231"; }
}
// The seeker: weaves as well as homing, so it does not fly a line you can
// simply sidestep.
class RS_RomeroEXCHSeekBall : Actor
{
	Default { Radius 5; Height 5; Speed 20; DamageFunction (random(20, 90)); DamageType "Plasma"; Projectile;
		+RANDOMIZE; +SEEKERMISSILE; +DONTHARMCLASS; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		Species "Daikatana"; RenderStyle "Add"; Alpha 0.75; Scale 0.85;
		SeeSound "ELECTRO8"; DeathSound "Crack/death"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		X404 A 10 Bright { A_StartSound("GLITCH"); }
	Fly2:
		X404 A 1 Bright { A_SpawnItemEx("RS_RomeroEXSeekTrail", cos(pitch), 0, -sin(pitch), cos(pitch), 0, -sin(pitch), 0, SXF_NOCHECKPOSITION); }
		X404 A 0 A_Weave(3, 0, 2, 0);
		X404 A 1 Bright A_SeekerMissile(3, 6);
		X404 A 0 A_Weave(3, 0, 2, 0);
		Loop;
	Death:
		TNT1 A 0 { A_StartSound("GLITCH"); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_RomeroEXSeekTrail", 0, 0, 0, random(6, 20), 0, random(-15, 15), random(1, 135), SXF_NOCHECKPOSITION); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_RomeroEXSeekTrail", 0, 0, 0, random(6, 20), 0, random(-15, 15), random(136, 270), SXF_NOCHECKPOSITION); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_RomeroEXSeekTrail", 0, 0, 0, random(6, 20), 0, random(-15, 15), random(271, 359), SXF_NOCHECKPOSITION); }
		Stop;
	}
}
// The BFG spam. Randomises its own scale every cycle and has a 32/256 chance
// per cycle of shedding a glitch shot sideways.
class RS_RomeroEXSpamShots : RS_SpamShotsRomeroCH
{
	Default { Speed 30; Projectile; +RANDOMIZE; +SEEKERMISSILE; +DONTHARMCLASS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES; Species "Daikatana";
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "0:148=176:176", "160:167=112:112", "224:231=231:231"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BFS1 A 0 { A_SetScale(frandom(0.1, 2.0), frandom(0.1, 2.0)); }
		BFS1 A 2 Bright { A_SpawnItemEx("RS_RomeroEXSpamShotsTrail", cos(pitch), 0, -sin(pitch), cos(pitch), 0, -sin(pitch), 0, SXF_NOCHECKPOSITION); }
		BFS1 B 2 Bright A_SeekerMissile(6, 7);
		BFS1 A 0 A_Jump(32, "Shed");
		Loop;
	Shed:
		BFS1 A 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 0, 0, random(0, 360), CMF_AIMOFFSET | CMF_TRACKOWNER, random(0, 360)); }
		Goto Fly;
	Death:
		BFE1 AB 8 Bright { A_SetScale(frandom(0.1, 4.0), frandom(0.1, 4.0)); }
		BFE1 C 8 Bright A_Explode(random(25, 80), 152);
		TNT1 A 0 A_ScreamAndUnblock();
		BFE1 DEF 8 Bright;
		Stop;
	}
}
class RS_RomeroEXSpamShots2 : RS_SpamShotsCguy
{
	Default { Species "Daikatana"; +DONTHARMCLASS; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		Translation "112:117=23:86", "118:127=200:237", "160:227=40:79", "228:234=248:255"; }
}
// The floor tiles the Dukie carpet plants -- they detonate, wait 90 tics, and
// detonate a second time, so standing where one already went off is a trap.
class RS_RomeroEXGround : Actor
{
	Default { Species "Daikatana"; DamageType "Plasma"; RenderStyle "Add"; Alpha 1.0;
		XScale 2.25; YScale 0.15;
		+NOINTERACTION; +THRUACTORS; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		+DONTHARMCLASS; +FLOORHUGGER; DeathSound "weapons/rocklx";
		Translation "0:255=251:251"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_ScreamAndUnblock();
		BRBA ONMLK 3 Bright A_Explode(random(10, 80), 64, 0);
		BRBA ABCDEFGHIJ 2 Bright;
		TNT1 A 90;
		TNT1 A 0 A_ScreamAndUnblock();
		BRBA ONMLK 3 Bright A_Explode(random(10, 80), 64, 0);
		BRBA ABCDEFGHIJ 2 Bright;
		Stop;
	}
}
// SOLID. Not damage -- a wall that grows out of the floor and stays for up to
// five seconds. The Trap plants sixteen in a ring around you.
class RS_RomeroEXGlitchBarrier : Actor
{
	Default { Radius 24; Height 64; YScale 0.1; XScale 2.0; Species "Daikatana";
		+SOLID; -NOGRAVITY; +DONTHARMCLASS; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		RenderStyle "Add"; Alpha 0.75; }
	States
	{
	Spawn:
		X404 B 1 Bright;
		X404 B 0 { A_StartSound("GLITCH"); }
	Blockyou:
		X404 B 1 Bright A_SetScale(2.0, 0.3);
		X404 B 1 Bright A_SetScale(2.0, 0.9);
		X404 B 1 Bright A_SetScale(2.0, 1.5);
		X404 B 1 Bright A_SetScale(2.0, 2.1);
		X404 B 1 Bright A_SetScale(2.0, 2.7);
		X404 B 1 Bright A_SetScale(2.0, 3.3);
		X404 B 1 Bright A_SetScale(2.0, 3.9);
		X404 B 1 Bright A_SetScale(2.0, 4.5);
		X404 B random(15, 150) Bright;
		X404 B 1 Bright A_SetScale(2.0, 4.5);
		X404 B 1 Bright A_SetScale(2.0, 3.9);
		X404 B 1 Bright A_SetScale(2.0, 3.3);
		X404 B 1 Bright A_SetScale(2.0, 2.7);
		X404 B 1 Bright A_SetScale(2.0, 2.1);
		X404 B 1 Bright A_SetScale(2.0, 1.5);
		X404 B 1 Bright A_SetScale(2.0, 0.9);
		X404 B 1 Bright A_SetScale(2.0, 0.3);
		Stop;
	}
}
class RS_RomeroEXGlitchTrap : Actor
{
	Default { Species "Daikatana"; +NOBLOCKMAP; +NOGRAVITY; +DONTHARMCLASS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES; }
	States
	{
	Spawn:
		TNT1 A 0;
		// Sixteen barriers on a 160-unit circle, cast at the target's feet.
		TNT1 A 0
		{
			for (int i = 0; i < 16; i++)
				A_SpawnItemEx("RS_RomeroEXGlitchBarrier",
					160.0 * cos(i * 22.5), 160.0 * sin(i * 22.5), -32767);
		}
		Stop;
	}
}
class RS_RomeroEXCode : Actor
{
	Default { Radius 6; Height 8; Damage 20; Scale 1.5; Speed 10; RenderStyle "Add";
		DamageType "Melee"; Species "Daikatana"; Projectile; DontHurtShooter;
		BounceType "Hexen"; +BOUNCEONWALLS; +BOUNCEONCEILINGS; +BOUNCEONFLOORS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		BounceCount 9; BounceFactor 1.0; WallBounceFactor 1.0;
		Translation "0:255=%[0.00,2.00,1.01]:[0.00,2.00,0.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_ScaleVelocity(frandom(0.5, 1.5));
	Spawn2:
		BIN0 A 2 Bright;
		BIN1 A 2 Bright;
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
// The leak: 131 bouncing binary digits sprayed in every direction, one per
// eight tics. CodeLeakage2 doubles the count.
class RS_RomeroEXCodeLeakage : Actor
{
	protected int rsLeakLimit;
	private int rsLeaked;
	Default { Species "Daikatana"; +NOBLOCKMAP; +NOGRAVITY; +DONTHARMCLASS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES; Scale 2.3;
		Translation "0:255=%[0.00,2.00,1.01]:[0.00,2.00,0.00]"; }
	States
	{
	Spawn:
		TNT1 A 0 { if (rsLeakLimit <= 0) rsLeakLimit = 131; }
		TNT1 A 0 { A_StartSound("BINARY", CHAN_5, CHANF_LOOPING); }
	Spawn2:
		TNT1 A 0 { if (rsLeaked >= rsLeakLimit) return ResolveState("Nah"); return ResolveState(null); }
		SPIR DCBADCBA 1;
		TNT1 A 0 { A_SpawnProjectile("RS_RomeroEXCode", 0, 0, random(0, 360), CMF_AIMDIRECTION, random(-90, 90)); }
		TNT1 A 0 { rsLeaked++; }
		Loop;
	Nah:
		TNT1 A 0 A_StopSound(CHAN_5);
		Stop;
	}
}
class RS_RomeroEXCodeLeakage2 : RS_RomeroEXCodeLeakage
{
	States
	{
	Spawn:
		TNT1 A 0 { rsLeakLimit = 262; }
		Goto Super::Spawn + 1;
	}
}
// The orbiting shield. Circles the boss at 128 units for one full rotation
// (400 tics) and reflects while it lives, then clears the boss's latch so the
// shield can be cast again -- exactly CHP's RomeroCHProtect2 handshake.
class RS_RomeroEXShield : Actor
{
	private int rsOrbit;
	Default { Radius 88; Height 110; Speed 18; Species "Daikatana"; Health 999; Monster;
		+NOTRIGGER; +NOTARGET; +DONTTHRUST; +NOGRAVITY; +INVULNERABLE; +REFLECTIVE;
		+DEFLECT; +SHIELDREFLECT; +THRUSPECIES; +MTHRUSPECIES; -COUNTKILL;
		RenderStyle "Add"; Alpha 1.0; Scale 1.5;
		Translation "0:255=%[0.00,2.00,0.00]:[2.00,0.00,2.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 { rsOrbit += 9; }
		CHSW Z 1 Bright { A_Warp(AAPTR_MASTER, 128, 0, 8, rsOrbit + 9, WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); }
		TNT1 A 0 { if (rsOrbit >= 3600) return ResolveState("Death"); return ResolveState(null); }
		Loop;
	Death:
		TNT1 A 0
		{
			let m = RS_Cyberdemon(master);
			if (m) m.RS_ClearGlitchShield();
		}
		CHSW Z 2 Bright A_NoBlocking();
		CHSW Z 2 Bright A_SetScale(1.0);
		CHSW Z 2 Bright A_SetScale(0.7);
		CHSW Z 2 Bright A_SetScale(0.4);
		TNT1 A 0 A_Die();
		Stop;
	}
}
// The mine: arms itself over a couple of seconds, sits for up to a minute, then
// stops interacting and shrinks away. Damage on contact while armed.
class RS_RomeroEXGlitchMine : Actor
{
	Default { Radius 32; Height 8; Speed 0; Damage 50; DamageType "Plasma"; Species "Daikatana";
		Projectile; DontHurtShooter; +DONTHARMCLASS; +THRUSPECIES; +MTHRUSPECIES;
		+DONTHARMSPECIES; +FLATSPRITE; +FLOORHUGGER; RenderStyle "Add"; Alpha 1.0; Scale 0.1;
		SeeSound "GLITCH"; DeathSound "GLITCH"; }
	States
	{
	Spawn:
		X404 A 1;
		X404 A 2 Bright A_SetScale(0.3, 0.3);
		X404 A 2 Bright A_SetScale(0.6, 0.6);
		X404 A 2 Bright A_SetScale(0.9, 0.9);
		X404 A 2 Bright A_SetScale(1.2, 1.2);
		X404 A 2 Bright A_SetScale(1.5, 1.5);
		X404 A 2 Bright A_SetScale(1.8, 1.8);
		X404 A 2 Bright A_SetScale(2.1, 2.1);
		X404 A 2 Bright A_SetScale(2.4, 2.4);
		X404 A random(200, 2000) Bright;
		X404 A 0 { bNOINTERACTION = true; }
		X404 A 2 Bright A_SetScale(2.4, 2.4);
		X404 A 2 Bright A_SetScale(2.1, 2.1);
		X404 A 2 Bright A_SetScale(1.8, 1.8);
		X404 A 2 Bright A_SetScale(1.5, 1.5);
		X404 A 2 Bright A_SetScale(1.2, 1.2);
		X404 A 2 Bright A_SetScale(0.9, 0.9);
		X404 A 2 Bright A_SetScale(0.6, 0.6);
		X404 A 2 Bright A_SetScale(0.3, 0.3);
		Stop;
	Death:
		TNT1 A 1;
		Stop;
	}
}
class RS_RomeroEXGlitchMineSpawner2 : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		Species "Daikatana"; Scale 1.25; }
	States
	{
	Spawn:
		CHTA A 0;
		CHTA A 0 { A_StartSound("SPMTARG"); }
		// CHP blinks CHTA A against CHTA X; only frame A exists in the art
		// source (verified -- the repo's own older CHTA use is A-only too), so
		// the targeter holds A for the same 28 tics instead of flickering.
		CHTA AAAAAAAAAAAAAA 2 Bright;
		CHTA A 0 { A_SpawnItemEx("RS_RomeroEXGlitchMine", 0, 0, -32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		CHTA AAAAAAAAAAAAAAAAAAAAAAAA 2 Bright;
		Stop;
	}
}
class RS_RomeroEXGlitchMineSpawner : Actor
{
	Default { Species "Daikatana"; +NOBLOCKMAP; +NOGRAVITY; +DONTHARMCLASS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 AAAAAAAA random(8, 12) { A_SpawnItemEx("RS_RomeroEXGlitchMineSpawner2", random(-12, 12) * 128, random(-12, 12) * 128, -32767); }
		Stop;
	}
}
class RS_RomeroEXSkyCH : RS_RomeroSkyCH
{
	States
	{
	Spawn:
		TNT1 A 8;
		Goto Death;
	Death:
		BRBA OOOOO 2 Bright { A_SpawnItemEx("RS_RomeroEXSpamShotsTrail", random(-64, 64), random(-64, 64), -24, random(1, 8), 0, random(-33, -1), random(-359, 359), SXF_NOCHECKPOSITION); }
		BRBA OOONNNMMMLLLKKK 1 Bright { A_SpawnItemEx("RS_RomeroEXBeamCH", random(-64, 64), random(-64, 64), -24, random(1, 8), random(1, 8), random(-45, -15), random(-359, 359), SXF_NOCHECKPOSITION); }
		BRBA ABCDEFGHIJ 2 Bright;
		Stop;
	}
}
class RS_RomeroEXBFGHeckShot : Actor
{
	Default { Radius 9; Height 8; Speed 40; Scale 0.75; DamageFunction (random(40, 99));
		DamageType "Plasma"; Species "Daikatana"; Projectile; DontHurtShooter;
		+RANDOMIZE; +FORCERADIUSDMG; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		RenderStyle "Add"; Alpha 0.85; SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "112:117=23:86", "118:127=200:237", "160:227=40:79", "228:234=248:255"; }
	States
	{
	Spawn:
		BFS1 AB 5 Bright;
		Loop;
	Death:
		BFE1 ABCDEF 3 Bright A_Explode(random(10, 30), 192, 0);
		Stop;
	}
}
class RS_RomeroEXBFGHeckFloor : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +FLOORHUGGER; RenderStyle "Add"; Alpha 0.85;
		XScale 2.85; YScale 0.4;
		Translation "112:117=23:86", "118:127=200:237", "160:227=40:79", "228:234=248:255"; }
	States { Spawn: BFS1 A 0; BFS1 A 2 Bright; Stop; }
}
class RS_RomeroEXBFGHeckFloor2 : RS_RomeroEXBFGHeckFloor
{
	States { Spawn: BFS1 B 0; BFS1 B 2 Bright; Stop; }
}
class RS_RomeroEXBFGHeckFloorFade : RS_RomeroEXBFGHeckFloor
{
	States { Spawn: BFS1 AAAAAAAAA 4 A_FadeOut(0.1); Stop; }
}
class RS_RomeroEXBFGHeckFloorSpawner : Actor
{
	Default { Species "Daikatana"; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		+NOBLOCKMAP; +NOGRAVITY; +FLOORHUGGER;
		Translation "112:117=23:86", "118:127=200:237", "160:227=40:79", "228:234=248:255"; }
	States
	{
	Spawn:
		BFS1 A 0 Bright;
		BFS1 A 0 { A_SpawnProjectile("RS_RomeroEXBFGHeckShot", 8, 0, random(0, 360), CMF_AIMDIRECTION, random(80, 100)); }
		Stop;
	}
}
class RS_RomeroEXBFGHeckCeilingSpawner : RS_RomeroEXBFGHeckFloorSpawner
{
	States
	{
	Spawn:
		BFS1 A 0 Bright;
		BFS1 A 0 { A_SpawnProjectile("RS_RomeroEXBFGHeckShot", -8, 0, random(0, 360), CMF_AIMDIRECTION, random(-100, -80)); }
		Stop;
	}
}
// BFG HECK: a wanderer that crawls along the ceiling laying a glowing trail and
// firing BFG shots at floor and ceiling until a 4/256 roll finally ends it.
class RS_RomeroEXBFGHeckSpawner : Actor
{
	Default { Species "Daikatana"; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		+NOBLOCKMAP; +NOGRAVITY; +CEILINGHUGGER; +NOBLOCKMONST; +NOTELEPORT;
		RenderStyle "Add"; Alpha 0.85; XScale 2.85; YScale 0.4;
		Translation "112:117=23:86", "118:127=200:237", "160:227=40:79", "228:234=248:255"; }
	States
	{
	Spawn:
		BFS1 AA 1 Bright { A_SpawnItemEx("RS_RomeroEXBFGHeckFloor", 0, 0, -32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		BFS1 A 0 { Thrust(10.0, random(0, 360)); }
		BFS1 BB 1 Bright { A_SpawnItemEx("RS_RomeroEXBFGHeckFloor2", 0, 0, -32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		BFS1 A 0 A_Jump(128, "Flooring", "Ceilg");
		Loop;
	Flooring:
		BFS1 A 0 { A_SpawnItemEx("RS_RomeroEXBFGHeckFloorSpawner", 0, 0, -32767); }
		BFS1 A 0 A_Jump(4, "Ded");
		Goto Spawn;
	Ceilg:
		BFS1 A 0 { A_SpawnItemEx("RS_RomeroEXBFGHeckCeilingSpawner"); }
		BFS1 A 0 A_Jump(4, "Ded");
		Goto Spawn;
	Ded:
		BFS1 A 0 { A_SpawnItemEx("RS_RomeroEXBFGHeckFloorFade", 0, 0, -32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		BFS1 AAAAAAAAA 4 A_FadeOut(0.1);
		Stop;
	}
}

class RS_RomeroEXRealBFGExtra : BFGExtra
{
	Default { Species "Daikatana"; +THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES; }
}
class RS_RomeroEXRealBFG : Actor
{
	Default { Radius 13; Height 8; Speed 25; Damage 100; DamageType "Plasma"; Species "Daikatana";
		Projectile; +RANDOMIZE; +SEEKERMISSILE; +DONTHARMCLASS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES;
		RenderStyle "Add"; Alpha 0.75; SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx"; }
	States
	{
	Spawn:
		BFS1 AB 4 Bright;
		Loop;
	Death:
		BFE1 AB 8 Bright;
		BFE1 C 8 Bright A_BFGSpray("RS_RomeroEXRealBFGExtra", 40, 15);
		BFE1 DEF 8 Bright;
		Stop;
	}
}
