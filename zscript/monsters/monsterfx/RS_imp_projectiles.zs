// =====================================================================
// RS_imp_projectiles.zs
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
// RS Imp projectiles -- ripped from Colourful Hell for the RED imp color-state.
// RedMessImp2 = the seeking fireball (spawns trailing RedMessImp sub-bits).
// Stock BAL1 sprites + a red translation. Used by RS_Imp's Red Missile state.
// ============================================================================
class RS_RedMessImp2 : Actor
{
	Default
	{
		Radius 6; Height 8; Mass 5; Speed 11;
		Projectile;
		+SEEKERMISSILE;
		Scale 0.55;
		RenderStyle "Add";
		Damage 10;
		DamageType "Fire";
		Alpha 0.95;
		SeeSound "imp/attack";
		DeathSound "weapons/firex4";
		Translation "208:223=176:191", "224:231=176:176";
	}
	States
	{
	Spawn:
		BAL1 A 1 A_SeekerMissile(3,5);
		BAL1 B 1 A_CustomMissile("RS_RedMessImp", 2, 0, random(-180,180));
		BAL1 A 1 A_Weave(1,1,2,1);
		Loop;
	Death:
		BAL1 CDE 1 A_SetTranslucent(0.35);
		Stop;
	}
}

class RS_RedMessImp : Actor
{
	Default
	{
		Radius 5; Height 5; Mass 7; Speed 4;
		Projectile;
		+THRUACTORS;
		Scale 0.3;
		RenderStyle "Add";
		Alpha 0.5;
		Translation "208:223=176:191", "224:231=176:176";
	}
	States
	{
	Spawn:
		BAL1 AB 6;
		Goto Death;
	Death:
		BAL1 A 1 A_SetTranslucent(0.25);
		Stop;
	}
}

// ============================================================================
// IMP RAINBOW projectiles -- ripped/adapted from Colourful Hell, one per color.
// All use stock BAL1 sprites + the color's translation (faithful to CH).
// NOTE: earlier passes flattened CH's damage ROLLS to single constants on the
// false belief that a ZScript Default block requires a constant Damage. It does
// not -- `DamageFunction (random(a,b))` is the property for exactly this and it
// PRESERVES the roll. Rolls are restored wherever they were recorded; any bare
// constant left here is one whose original spread was lost and needs re-reading
// from CH/CHP.
// ============================================================================

// GREEN -- seeking plasma ball
class RS_GreenIBall : Actor
{
	Default
	{
		Radius 8; Height 16; Speed 14; FastSpeed 26;
		Damage 13; DamageType "Plasma";
		Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.85;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "168:191=112:127";
	}
	States
	{
	Spawn:
		BAL1 AB 4 Bright A_SeekerMissile(1,1);
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(4,32);
		Stop;
	}
}

// BLUE -- fast straight fireball
class RS_BluFier1 : Actor
{
	Default
	{
		Radius 6; Height 8; Speed 16; FastSpeed 28;
		Damage 11; DamageType "Fire";
		Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.9;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "168:191=196:207";
	}
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
		Loop;
	Death:
		BAL1 CDE 6 Bright;
		Stop;
	}
}

// PURPLE -- bouncing fireball (Hexen bounce, 4 bounces)
class RS_Bounc11 : Actor
{
	Default
	{
		Radius 15; Height 8; Speed 18;
		Damage 18; DamageType "Fire";
		Projectile; +BOUNCEONWALLS;
		RenderStyle "Add"; Alpha 0.75;
		BounceType "Hexen"; WallBounceFactor 0.7; BounceFactor 0.7;
		BounceCount 4; BounceSound "Bomb/bounce";
		SeeSound "imp/attack"; DeathSound "weapons/plasmax";
		Translation "168:191=250:254", "208:223=250:254";
	}
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(6,48);
		Stop;
	}
}



// ============================================================================
// IMP RAINBOW Wave 2 -- the custom-sprite colors' projectiles.
// Ripped faithfully from CH (full parent chains + sub-spawns traced).
// Cosmetic ACS-gated markers dropped (no CH ACS).
// ============================================================================

// --- CYAN: frost spray (FrostLong -> FrostLong2, KIRC sprites, PUFI death) ---
class RS_FrostLong : Actor
{
	Default
	{
		Radius 3; Height 4; Speed 76;
		Damage 8; DamageType "Ice";
		Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.85; Scale 0.3;
		DeathSound "Ice/Hit2";
	}
	States
	{
	Spawn:
		KIRC A 1 Bright A_SeekerMissile(8,8);
		KIRC B 1 Bright A_PlaySound("Ice/Fly");
		KIRC C 1 Bright A_Weave(1,1,2,1);
		KIRC D 1 Bright;
		Loop;
	Death:
		PUFI ABCD 1 Bright A_SetTranslucent(0.4);
		PUFI EFGH 1 Bright;
		Stop;
	}
}
class RS_FrostLong2 : RS_FrostLong
{
	Default
	{
		-SEEKERMISSILE;
		Damage 6;
	}
	States
	{
	Spawn:
		KIRC ABCD 1 Bright;
		Loop;
	}
}

// --- ABYSS: AbyssBallCH -> SplashAbyss/SplashAbyss2 (RCHB sprites) ---
class RS_SplashAbyss : Actor
{
	Default
	{
		Radius 6; Height 16; Speed 16; FastSpeed 23;
		Projectile; +RANDOMIZE; +THRUACTORS; -NOGRAVITY;
		Scale 0.3;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
	}
	States
	{
	Spawn:
		BAL1 AB 12;
		BAL1 A 2 A_Jump(32,"Death");
		Loop;
	Death:
		BAL7 C 1 Bright A_SetScale(0.6);   // BAL7 = stock Doom Caco-fireball sprite (from IWAD, as CH uses it)
		BAL7 CDE 4 Bright;
		Stop;
	}
}
class RS_SplashAbyss2 : RS_SplashAbyss
{
	Default
	{
		Height 6; Speed 34;
		Damage 4; DamageType "Ice";
		-THRUACTORS; +MTHRUSPECIES; +DONTHARMCLASS;
	}
}
class RS_AbyssBallCH : Actor
{
	Default
	{
		Radius 8; Height 16; Speed 21;
		Damage 22; DamageType "Plasma";
		Projectile; +RANDOMIZE; +DONTHARMCLASS;
		SeeSound "Roach/Fire"; DeathSound "imp/shotx";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		RCHB A 2 Bright;
		TNT1 AAA 0 A_SpawnItemEx("RS_SplashAbyss2", random(-3,3), random(-3,3), random(1,3), 0,0,1, random(-359,359));
		RCHB B 2 Bright;
		TNT1 AAA 0 A_SpawnItemEx("RS_SplashAbyss2", random(-3,3), random(-3,3), random(1,3), 0,0,1, random(-359,359));
		Loop;
	Death:
		TNT1 A 0 A_SetScale(1.2,1.2);
		TNT1 AAAAAAA 0 A_CustomMissile("RS_SplashAbyss2", 6, 0, random(-180,180), CMF_OFFSETPITCH, random(-25,-5));
		RCHB CDE 4 Bright A_Explode(5,56);
		Stop;
	}
}

// --- GRAY: CGNail (BLAD/6PUF/FBL1 sprites, PuffCybieRed smoke) ---
class RS_PuffCybieRed : Actor
{
	Default { Radius 1; Height 1; +NOCLIP; +NOGRAVITY; +NOINTERACTION; RenderStyle "Add"; Alpha 0.75; }
	States
	{
	Spawn:
		SMK2 ABCDE 2;
		Stop;
	}
}
class RS_CGNail : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 45; Scale 0.5;
		Damage 3; DamageType "Melee";
		Decal "BulletChip";
		AttackSound "moloch/nailhitbleed"; DeathSound "weapons/firex4";
		Projectile; +SPAWNSOUNDSOURCE; +EXTREMEDEATH; +BLOODSPLATTER;
	}
	States
	{
	Spawn:
		BLAD A 2 Bright;
		Loop;
	Death:
		"6PUF" A 0 A_PlaySound("moloch/nailhit");
		"6PUF" ABCDEF 1 Bright A_Explode(2,16);
		FBL1 EFG 1 Bright A_Explode(2,16);
		FBL1 G 1 Bright A_SpawnItemEx("RS_PuffCybieRed",0,0,2);
		Stop;
	}
}

// --- WHITE: WimpBall1-5 (all stock BAL1 + translation, no sub-spawns) ---
class RS_WimpBall1 : Actor
{
	Default
	{
		Radius 7; Height 14; Speed 14; FastSpeed 26;
		Damage 15; DamageType "Plasma";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Scale 0.8; Alpha 0.85;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "168:191=112:127";
	}
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(4,32);
		Stop;
	}
}
class RS_WimpBall2 : RS_WimpBall1 { Default { Translation "168:191=196:207"; } }     // blue
class RS_WimpBall3 : RS_WimpBall1 { Default { Translation "168:191=250:254"; } }     // purple
class RS_WimpBall4 : RS_WimpBall1 { Default { Translation "168:191=212:223"; } }     // yellow
class RS_WimpBall5 : RS_WimpBall1 { Default { Translation "168:191=176:191"; } }     // red

// ============================================================================
// CORRECTED Wave-1 projectiles -- the REAL CH actors (replacing earlier winged
// RS_YellowIBall / RS_FireBluBall). Yellow fires SpitFireImp; FireBlu alternates
// RedBBall + BluBBall (a blue-translated RedBBall).
// ============================================================================

// YELLOW fires this -- the SpitFire flame (FLUM/BBOM sprites, explodes on death)
class RS_SpitFireImp : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 19;
		Damage 22; DamageType "Fire";
		Projectile; RenderStyle "Add";
		SeeSound "Imp/Attack"; DeathSound "Fire/fire5";
		Alpha 0.9; Scale 0.85;
	}
	States
	{
	Spawn:
		FLUM ABCDE 6 Bright;
		Loop;
	Death:
		BBOM ABC 2 Bright A_SetScale(0.7);
		BBOM DEFG 3 Bright A_Explode(7,64);
		Stop;
	}
}

// FIREBLU ball trail
class RS_CrackoBallTrail : Actor
{
	Default { Radius 1; Height 1; +NOCLIP; +NOGRAVITY; +FLOAT; RenderStyle "Add"; Alpha 0.5;
		Translation "192:207=171:191", "240:247=191:191"; }
	States
	{
	Spawn:
		BLL9 AB 2 Bright A_FadeOut(0.1);
		Loop;
	}
}

// FIREBLU fires these two, alternating (RED9/ARCB sprites)
class RS_RedBBall : Actor
{
	Default
	{
		Radius 8; Height 12; Speed 25;
		Damage 25; DamageType "Plasma";
		Scale 0.5;
		Projectile; +THRUGHOST; +DONTHARMCLASS;
		SeeSound "weapons/firbfi"; DeathSound "weapons/hellex";
		RenderStyle "Add"; Alpha 0.8;
		Translation "112:127=176:191";
	}
	States
	{
	Spawn:
		RED9 A 3 Bright A_SetScale(0.5);
		RED9 B 3 Bright A_CustomMissile("RS_CrackoBallTrail", 4, 0, CMF_AIMOFFSET, random(0,360), random(0,360));
		RED9 C 3 Bright A_SetScale(0.4);
		Loop;
	Death:
		ARCB J 0 A_SetTranslucent(0.67,1);
		ARCB J 3 Bright;
		ARCB K 3 Bright A_Explode(12,128,0);
		ARCB LMN 3 Bright;
		Stop;
	}
}
class RS_BluBBall : RS_RedBBall { Default { Translation "0:255=196:207"; } }

// CYAN's primary (far) attack -- fast ice ball, CHCY sprites, frost burst on death
class RS_CyanImpBall : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 28; Scale 0.75;
		Damage 11; DamageType "Ice";
		Projectile; +DONTHARMCLASS;
		SeeSound "imp/attack"; DeathSound "Ice/Hit2";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		CHCY ABCDFG 3 Bright;
		Loop;
	Death:
		TNT1 A 0 A_Scream;
		TNT1 AAAAAAA 0 A_CustomMissile("RS_FrostLong2", 0, 0, random(0,359), CMF_OFFSETPITCH, random(-25,-5));
		Stop;
	}
}

// ============================================================================
// BLACK IMP web -- the deepest dependency tree in the imp set. Ripped faithfully
// (full recursion). DIBigOne is the centerpiece: it spawns SpiralSaw5 + GroundRedCyb
// + AgauresBall1 and explodes; its death drops DeathBreathDI. DeathBreathDI is the
// SIGNATURE mechanic -- the "smoking" breath that HEALS nearby Black imps via
// A_RadiusGive (ally-sustain). AGAS/BLVB/BLTR/RED9/RED8/SPIR sprites.
// (Black imp's heaviest sub-spawns are flagged for the efficiency pass.)
// ============================================================================

// trail for the Agaures balls
class RS_AgauresBallTrail : Actor
{
	Default { Radius 0; Height 1; Projectile; RenderStyle "Add"; Alpha 0.75; }
	States
	{
	Spawn:
		TNT1 A 1 Bright;
		BLTR ABCDEF 2 Bright;
		Stop;
	}
}

// DeathBreathDI -- the smoking ally-heal breath (heals nearby Black imps)
class RS_DeathBreathDI : Actor
{
	Default
	{
		Radius 24; Height 6; Speed 1;
		Damage 1; DamageType "DIMp";
		Scale 0.95; Projectile; +FLOATBOB;
		RenderStyle "Translucent"; Alpha 0.67;
	}
	States
	{
	Spawn:
		AGAS ABCDE 4 A_Explode(1,42);
		AGAS E 0 A_RadiusGive("Health", 64, RGF_MONSTERS|RGF_EXFILTER, 3, "RS_Imp");
		AGAS FGDEF 4 A_Explode(1,42);
		AGAS F 0 A_RadiusGive("Health", 64, RGF_MONSTERS|RGF_EXFILTER, 5, "RS_Imp");
		AGAS GDEFGD 4 A_Explode(1,42);
		AGAS E 0 A_RadiusGive("Health", 64, RGF_MONSTERS|RGF_EXFILTER, 3, "RS_Imp");
		AGAS EFGDEF 4 A_Explode(1,42);
		AGAS F 0 A_RadiusGive("Health", 64, RGF_MONSTERS|RGF_EXFILTER, 5, "RS_Imp");
		AGAS GDCBA 4 A_Explode(1,42);
		Goto Death;
	Death:
		AGAS DC 1 A_SetScale(0.65);
		AGAS BA 3 A_Explode(1,32);
		Stop;
	}
}

// SpiralSaw5 -- spiral explosion burst
class RS_SpiralSaw5 : Actor
{
	Default { Radius 1; Height 1; Speed 1; Projectile; +NOCLIP; +NOGRAVITY; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.55; }
	States
	{
	Spawn:
		SPIR EDCBA 3 Bright A_Explode(6,88);
		Stop;
	}
}

// GroundRedCyb -- floor-hugging bouncing fire
class RS_GroundRedCyb : Actor
{
	Default
	{
		Radius 6; Height 8; Speed 1; Mass 25;
		Projectile; +FLOORHUGGER; +THRUACTORS; +RANDOMIZE; +BOUNCEONWALLS;
		BounceCount 999; BounceType "Doom"; DamageType "Fire";
		BounceFactor 1; WallBounceFactor 1.5;
		RenderStyle "Add"; SeeSound "Fire/fire3"; Alpha 0.95;
		YScale 0.3; XScale 0.75;
	}
	States
	{
	Spawn:
		RED8 ABCFGH 3 Bright A_Explode(6,128);
		RED8 D 1 Bright;
		Stop;
	}
}

// AgauresBall1 -- slow heavy fire ball, drops DeathBreathDI on death
class RS_AgauresBall1 : Actor
{
	Default
	{
		Radius 10; Height 18; Speed 9;
		Damage 22; DamageType "Fire";
		Scale 1.45; RenderStyle "Add"; Alpha 0.67;
		Projectile; +THRUGHOST;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
	}
	States
	{
	Spawn:
		BLVB AAABBB 1 Bright A_SpawnItemEx("RS_AgauresBallTrailEX",0,0,0,0,0,0,0,128,0);
		BLVB A 0 A_Jump(24,"Death");
		Loop;
	Death:
		BLVB CDEF 2 Bright A_SpawnItemEx("RS_DeathBreathDI", random(-178,178), random(-178,178), random(-12,42), 0,0,0,0,128,0);
		Stop;
	}
}

// AgauresBall2 -- faster fire ball, explodes
class RS_AgauresBall2 : Actor
{
	Default
	{
		Radius 8; Height 16; Speed 19;
		Damage 15; DamageType "Fire";
		RenderStyle "Add"; Alpha 0.67;
		Projectile; +THRUGHOST;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
	}
	States
	{
	Spawn:
		BLVB AAABBB 1 Bright A_SpawnItemEx("RS_AgauresBallTrailEX",0,0,0,0,0,0,0,128,0);
		Loop;
	Death:
		BLVB C 0 A_SetScale(2,2);
		BLVB CDEF 4 Bright A_Explode(5,64);
		Stop;
	}
}

// DIBigOne -- the centerpiece: spawns saw + ground-fire + agaures ball, explodes,
// death drops DeathBreathDI + spiral. The Black imp's heavy artillery.
class RS_DIBigOne : Actor
{
	Default
	{
		Radius 12; Height 24; Speed 7;
		DamageFunction (random(40, 125)); DamageType "Plasma";
		Projectile; +NOGRAVITY; RenderStyle "Add"; Scale 2; Alpha 0.75;
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4";
		DropItem "RocketAmmo";
	}
	States
	{
	Spawn:
		RED9 B 1 Bright;
		RED9 AA 1 Bright A_SpawnItemEx("RS_SpiralSaw5",0,0,0,0,0,0,0,128);
		RED9 A 0 A_CustomMissile("RS_GroundRedCyb",0,0);
		RED9 A 0 A_CustomMissile("RS_AgauresBall1", 7, 0, CMF_AIMOFFSET, random(0,360), random(0,360));
		RED9 A 0 A_Explode(random(4, 10), 128);
		Loop;
	Death:
		SPIR AAAA 0 A_SpawnItemEx("RS_DeathBreathDI", random(-178,178), random(-178,178), random(-12,42), 0,0,0,0,128,0);
		// CH Imps.txt:2437 runs A_Explode(random(5,30),178) on NINE frames.
		// A multi-frame line fires its action once PER FRAME, so this is nine
		// blasts, not one -- CH's own intent, kept.
		SPIR ABCDEDCBA 5 Bright A_Explode(random(5, 30), 178);
		SPIR E 1 A_NoBlocking;
		Stop;
	}
}

// ============================================================================
// BLACK IMP EX ("Smoking Black Imp EX") -- CHPLUS miniboss apex (HP 8600).
// Projectiles ported from CHPLUS 03_KX (_C variants flattened). Shares
// RS_DeathBreathDI smoke with the regular Black imp. BLVB sprites.
// ============================================================================
// EX balls get their own VISIBLE BLVB trail (the regular Black imp's AgauresBallTrail
// was simplified to invisible; the EX miniboss keeps the flashy version).
class RS_AgauresBallTrailEX : Actor
{
	Default { Radius 1; Height 1; Projectile; +NOCLIP; +NOGRAVITY; RenderStyle "Add"; Alpha 0.4; Scale 0.8;
		Translation "0:255=%[0.05,0.05,0.05]:[0.55,0.55,0.55]"; }
	States { Spawn: BLVB AB 3 Bright; Stop; }
}
class RS_BlackImpEXBall1 : FastProjectile
{
	Default { Radius 10; Height 10; Speed 14; Damage 22; Scale 1.15; RenderStyle "Add"; DamageType "Fire";
		Alpha 0.67; Projectile; +THRUGHOST; SeeSound "imp/attack"; DeathSound "imp/shotx"; WeaveIndexXY 54; }
	States
	{
	Spawn:
		TNT1 A 0 A_Jump(255,"A1","A2","A3");
	A1:
		BLVB A 1 Bright A_SpawnItemEx("RS_AgauresBallTrailEX",0,0,0,0,0,0,0,128,0);
		BLVB B 1 Bright A_Weave(3,0,2,0);
		Loop;
	A2:
		BLVB A 1 Bright A_SpawnItemEx("RS_AgauresBallTrailEX",0,0,0,0,0,0,0,128,0);
		BLVB B 1 Bright A_Weave(3,0,-2,0);
		Loop;
	A3:
		BLVB A 1 Bright A_SpawnItemEx("RS_AgauresBallTrailEX",0,0,0,0,0,0,0,128,0);
		BLVB B 1 Bright;
		Loop;
	Death:
		BLVB CDEF 2 Bright A_SpawnItemEx("RS_DeathBreathDI",random(-178,178),random(-178,178),random(-12,42),random(1,6),0,0,random(-359,359));
		Stop;
	}
}
class RS_BlackImpEXBall2 : Actor
{
	Default { Radius 8; Height 8; Speed 19; Damage 5; Scale 1.0; RenderStyle "Add"; DamageType "Fire"; Alpha 0.67;
		Projectile; +SEEKERMISSILE; +USEBOUNCESTATE; BounceType "Hexen"; BounceCount 4;
		SeeSound "imp/attack"; DeathSound "imp/shotx"; }
	States
	{
	Spawn:
		BLVB A 1 Bright A_SpawnItemEx("RS_AgauresBallTrailEX",0,0,0,0,0,0,0,128,0);
		BLVB B 1 Bright A_SeekerMissile(random(2,8),random(2,10));
		Loop;
	Bounce:
		TNT1 A 0 ThrustThingZ(0,9,0,0);
		Goto Spawn;
	Death:
		BLVB C 0 Bright A_SetScale(2,2);
		BLVB CDEF 4 Bright A_Explode(5,32);
		Stop;
	}
}
class RS_BlackImpEXBigOne : Actor
{
	Default { Radius 13; Height 13; Speed 9; Damage 85; Scale 1.2; RenderStyle "Add"; DamageType "Fire"; Alpha 0.85;
		Projectile; +SEEKERMISSILE; SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4";
		Translation "0:255=%[0.05,0.05,0.05]:[0.55,0.55,0.55]"; }
	States
	{
	Spawn:
		RED9 B 1 Bright A_Explode(7,128);
		RED9 A 1 Bright A_SeekerMissile(2,2);
		Loop;
	Death:
		SPIR AAAAAAAAAAAA 0 Bright A_SpawnItemEx("RS_DeathBreathDI",random(-178,178),random(-178,178),random(-12,42),random(1,6),0,0,random(-359,359));
		TNT1 A 0 A_SetScale(4.0,4.0);
		SPIR ABCDEDCBA 5 Bright A_Explode(27,256);
		SPIR E 1 A_NoBlocking;
		Stop;
	}
}
class RS_BlackImpEXCharge : Actor
{
	Default { Speed 1; Projectile; +NOINTERACTION; RenderStyle "Add"; Alpha 0.85;
		Translation "0:255=%[0.05,0.05,0.05]:[0.55,0.55,0.55]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BLVB A 3 Bright A_SetScale(1.45,1.2);
		BLVB B 3 Bright A_SetScale(1.2,1.45);
		BLVB A 3 Bright A_SetScale(1.45,1.2);
		BLVB B 3 Bright A_SetScale(1.2,1.45);
		BLVB A 3 Bright A_SetScale(1.0,1.0);
		BLVB B 3 Bright A_SetScale(0.6,0.6);
		BLVB A 3 Bright A_SetScale(0.25,0.25);
		Stop;
	}
}
class RS_BlackImpSmokeOut : Actor
{
	Default { Speed 1; Projectile; +FLOORHUGGER; +THRUACTORS; StencilColor "Black"; SeeSound "Fire/fire3"; Scale 1.0; }
	States
	{
	Spawn:
		RNGG ABCDABCDABCD 1 Bright;
	Fly:
		RNGG ABCDABCDABCDABCDABCDABCD 1 Bright A_SpawnItemEx("RS_DeathBreathDI",0,0,random(1,6),random(3,15),0,random(1,12),random(-359,359));
		RNGG ABCDABCDABCD 1 Bright A_SpawnItemEx("RS_DeathBreathDI",0,0,random(1,6),random(3,15),0,random(1,12),random(-359,359));
		Stop;
	}
}

// ---------------------------------------------------------------------
// Brown imp (Warlord) spike volley -- ported from CH Fatsos.txt
// FatsoSpikes2 (the small gravity spike the WARI imp actually throws;
// the big FatsoSpikes belongs to the fatso and lives with it). RIP1
// sprites imported to sprites/monsters/projectiles/.
// ---------------------------------------------------------------------
class RS_FatsoSpikes2 : Actor
{
	Default
	{
		Radius 4;
		Height 4;
		Speed 5;
		DamageFunction (random(10, 40));
		Projectile;
		DamageType "Melee";
		-NOGRAVITY
		+THRUGHOST
		Gravity 0.1;
		Scale 0.45;
		SeeSound "monster/dknmsl";
		DeathSound "weapons/rocklx";
		Translation "144:151=90:95", "64:79=96:109", "236:239=104:111", "1:2=111:111";
	}
	States
	{
	Spawn:
		RIP1 ABC 4 Bright;
		Loop;
	Death:
		RIP1 ABCABCABCBA 12 A_Explode(random(1, 4), 8);
		Stop;
	}
}

// =====================================================================
// Ported from CHP DECORATE/03 (imp). These had no RS_ equivalent --
// without them the FireBlu, Gray, Brown and White imps lose real
// attacks or death effects.
// =====================================================================

// T07 FIREBLU -- the paired red/blue bomb balls. FastProjectile, sheds
// a spiralling trail. Blue is the same round with a different palette,
// exactly as CHP defines it.
class RS_RedBBallImp : FastProjectile
{
	Default
	{
		Radius 8;
		Height 12;
		Speed 25;
		DamageFunction (random(10, 50));
		Scale 0.5;
		Species "Imp";
		Projectile;
		+THRUGHOST +DONTHARMCLASS +DONTHARMSPECIES
		SeeSound "weapons/firbfi";
		DeathSound "weapons/hellex";
		RenderStyle "Add";
		Alpha 0.8;
		Translation "112:127=176:191";
		DamageType "Plasma";
	}
	States
	{
	Spawn:
		RED9 A 3 Bright { A_SetScale(0.5); }
		RED9 B 3 Bright { A_SpawnProjectile("RS_CrackoBallTrail", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		RED9 C 3 Bright { A_SetScale(0.4); }
		Loop;
	Death:
		RED9 ABC 4 Bright { A_Explode(random(5, 20), 64); }
		Stop;
	}
}

class RS_BluBBallImp : RS_RedBBallImp
{
	Default { Translation "0:255=196:207"; }
}

// T09 GRAY -- the nailgun round, and the corpse-burst that fires a full
// ring of them when the gray imp dies.
class RS_GImpNail : FastProjectile
{
	Default
	{
		Species "Imp";
		Radius 2;
		Height 2;
		DamageFunction (random(1, 5));
		DamageType "Melee";
		Speed 45;
		Scale 0.5;
		Decal "BulletChip";
		AttackSound "moloch/nailhitbleed";
		DeathSound "weapons/firex4";
		Projectile;
		+SPAWNSOUNDSOURCE +EXTREMEDEATH +BLOODSPLATTER
		+THRUSPECIES +MTHRUSPECIES
	}
	States
	{
	Spawn:
		BLAD A 2 Bright;
		Loop;
	Death:
		6PUF ABCDEFEF 1 Bright { A_Explode(random(1, 3), 16); }
		FBL1 G 1 Bright { A_SpawnItemEx("RS_PuffCybieRed", 0, 0, 2); }
		Stop;
	}
}

class RS_Impthing3 : Actor
{
	Default
	{
		Species "Imp";
		Projectile;
		+THRUSPECIES +MTHRUSPECIES +NOGRAVITY
		Radius 2;
		Height 2;
		Speed 0;
		Damage 0;
	}
	States
	{
	Spawn:
	Death:
		TNT1 A 0;
		MISL D 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 15,  CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 45,  CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 75,  CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 105, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 135, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 165, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 195, CMF_AIMDIRECTION); }
		MISL D 1 { A_SpawnProjectile("RS_GImpNail", 0, 0, 225, CMF_AIMDIRECTION); }
		// CHP fires TWELVE at 30-degree spacing (03_GY.txt:1079-1103).
		// 255/285/315/345 were missing -- the corpse ring was not closed.
		TNT1 A 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 255, CMF_AIMDIRECTION); }
		TNT1 A 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 285, CMF_AIMDIRECTION); }
		TNT1 A 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 315, CMF_AIMDIRECTION); }
		TNT1 A 0 { A_SpawnProjectile("RS_GImpNail", 0, 0, 345, CMF_AIMDIRECTION); }
		Stop;
	}
}

// T08 BROWN (Warlord) -- the parry shield pulse, and the mace/shield
// that clatter off the corpse when it dies.
class RS_BrownImpShieldMini : Actor
{
	Default
	{
		Radius 64;
		Height 56;
		Speed 1;
		Species "Imp";
		Health 100;
		Monster;
		+NOTRIGGER +NOTARGET +NOPAIN +DONTTHRUST +NOGRAVITY
		+NOICEDEATH +MTHRUSPECIES +THRUSPECIES
		-COUNTKILL
		RenderStyle "Add";
		Alpha 0.85;
		Scale 0.5;
		Translation "0:255=#[240,247,9]";
	}
	States
	{
	Spawn:
		DKNT Z 1 Bright { A_SetScale(0.4, 0.4); }
		DKNT Z 1 Bright { A_SetScale(0.6, 0.6); }
		DKNT Z 1 Bright { A_SetScale(0.7, 0.5); }
		DKNT Z 1 Bright { A_SetScale(0.5, 0.5); }
		DKNT Z 1 Bright { A_FaceTarget(); A_SetScale(0.95, 0.75); }
		DKNT Z 24 Bright;
		Goto Death;
	Death:
		DKNT Z 1 Bright A_FadeOut(0.2);
		Wait;
	}
}

class RS_WarlordMace : Actor
{
	Default { BounceType "Doom";Speed 4; }
	States
	{
	Spawn:
		WLI2 ABCDEF 5;
		WLI2 G -1;
		Stop;
	}
}

class RS_WarlordShield : Actor
{
	Default { BounceType "Doom";Speed 5; }
	States
	{
	Spawn:
		WLI1 ABCDEF 5;
		WLI1 G -1;
		Stop;
	}
}

// T11 BLACK -- the Agaures artillery shell.
// [dedupe] duplicate class RS_DIBigOne removed -- defined earlier in the load order.

// T12 WHITE -- the seeking hellion round it rains during nopenopeno.
class RS_Hel2 : Actor
{
	Default
	{
		Radius 8;
		Height 12;
		Speed 12;
		DamageFunction (random(8, 30));
		Projectile;
		+SEEKERMISSILE +NOGRAVITY
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.8;
		DeathSound "weapons/rocklx";
	}
	States
	{
	Spawn:
		HLBL A 1 Bright { A_SeekerMissile(5, 7); }
		HLBL B 1 Bright;
		HLBL A 1 Bright { A_Weave(1, 1, 1.0, 1.0); }
		HLBL B 1 Bright;
		Loop;
	Death:
		HLBL CDEFG 4 Bright { A_Explode(random(4, 16), 64); }
		Stop;
	}
}

// Vanilla-shaped imp fireball, as an RS_ class so T00's combo attack
// resolves inside this library.
class RS_DoomImpBall : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 10;
		FastSpeed 20;
		Damage 3;
		Projectile;
		+RANDOMIZE
		RenderStyle "Add";
		Alpha 1.0;
		SeeSound "imp/attack";
		DeathSound "imp/shotx";
	}
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
		Loop;
	Death:
		BAL1 CDE 6 Bright;
		Stop;
	}
}

// =====================================================================
// TEX ADDITIONS -- the Green Black Imp EX's Kamehameha (CHP 03_KX
// GreenBlackImpEX2). A_CustomRailgun needs two classes: the PUFF it
// stamps on whatever the beam hits, and the SPAWNCLASS it strings along
// the beam itself. Both come from CHP's `_G` colour, which is the one
// this boss actually fires.
// =====================================================================

// The impact end. CHP's `_C` moved the whole thing from Death into
// Spawn and added +PUFFONACTORS/+ALWAYSPUFF, so the hit reads even when
// the beam lands on a wall -- CH's original only fired on Death and
// silently did nothing against actors. CHP wins.
class RS_BlackImpBeam1 : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 1; Scale 1.25;
		Projectile;
		+NOCLIP; +NOGRAVITY; +PUFFONACTORS; +ALWAYSPUFF;
		RenderStyle "Add"; Alpha 1.25;
		DamageType "Plasma";
		DeathSound "imp/shotx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 1 { A_Scream(); }
		SPIR EDCBA 3 Bright { A_Explode(random(2, 20), 128); }
		TNT1 AAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, 0, random(1, 6), random(3, 15), 0, random(1, 12), random(-359, 359)); }
		Stop;
	}
}

// The beam body. Strung along the rail one segment per tic, and each
// segment keeps exploding as it shrinks -- so the beam is a corridor of
// damage that lingers, not an instant line.
class RS_BlackImpBeam2 : Actor
{
	Default
	{
		Radius 10; Height 18; Speed 1; Scale 1.75;
		DamageFunction (random(13, 25)); DamageType "Fire";
		Projectile; +THRUGHOST; +NOCLIP;
		RenderStyle "Add"; Alpha 0.67;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
		BLVB A 3 Bright { A_SetScale(1.75, 1.75); }
		BLVB B 3 Bright { A_SetScale(1.5, 1.5); }
		TNT1 A 0 { A_Explode(random(6, 38), 64, 0); }
		BLVB A 3 Bright { A_SetScale(1.75, 1.75); }
		BLVB B 3 Bright { A_SetScale(1.5, 1.5); }
		TNT1 A 0 { A_Explode(random(6, 38), 64, 0); }
		BLVB A 3 Bright { A_SetScale(1.75, 1.75); }
		BLVB B 3 Bright { A_SetScale(1.5, 1.5); }
		TNT1 A 0 { A_Explode(random(6, 38), 64, 0); }
		BLVB A 3 Bright { A_SetScale(1.75, 1.75); }
		BLVB B 3 Bright { A_SetScale(1.5, 1.5); }
		TNT1 A 0 { A_Explode(random(6, 38), 64, 0); }
		BLVB A 3 Bright { A_SetScale(1.15, 1.15); }
		BLVB B 3 Bright { A_SetScale(0.5, 0.5); }
		BLVB A 3 Bright { A_SetScale(0.15, 0.15); }
		TNT1 AA 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, 0, random(1, 6), random(3, 15), 0, random(-3, 3), random(-359, 359)); }
		Stop;
	}
}
