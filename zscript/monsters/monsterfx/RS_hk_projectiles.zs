// =====================================================================
// RS_hk_projectiles.zs
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
// hf_hk_projectiles.zs -- projectiles for the RS_HellKnight color rainbow.
// Ripped faithfully from Colourful Hell (full dependency trees traced).
// NOTE: earlier passes flattened CH's damage ROLLS to single constants on the
// false belief that a ZScript Default block requires a constant Damage. It does
// not -- `DamageFunction (random(a,b))` is the property for exactly this and it
// PRESERVES the roll. Rolls are restored wherever they were recorded; any bare
// constant left here is one whose original spread was lost and needs re-reading
// from CH/CHP.
// Translations,
// flags, sub-spawns preserved. Stock IWAD sprites (BAL1/BAL2/BAL7/MISL/PUFF/PLSE/
// BAR1/MANF) used as CH uses them. Cosmetic ACS-only markers dropped.
// ============================================================================

// ---------- BLUE: BaronsBlueBalls (BAL7 + PLSE death) ----------
class RS_BaronsBlueBalls : Actor
{
	Default
	{
		Radius 6; Height 16; Speed 18; FastSpeed 25;
		Damage 27; DamageType "Plasma";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85;
		SeeSound "baron/attack"; DeathSound "weapons/plasmax";
		Translation "112:127=192:207";
	}
	States
	{
	Spawn:
		BAL7 AB 4 Bright;
		Loop;
	Death:
		PLSE CDE 3 Bright;
		Stop;
	}
}

// ---------- PURPLE: HKBolt2 (seeking, SBS1+BAL2) + PurpFire2 (PFIR) ----------
class RS_HKBolt2 : Actor
{
	Default
	{
		Radius 6; Height 8; Speed 19; FastSpeed 38;
		Damage 30; DamageType "Plasma";
		Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 1; Scale 0.7;
		SeeSound "caco/attack"; DeathSound "caco/shotx";
		Translation "168:223=250:254", "224:231=250:250", "168:191=250:254";
	}
	States
	{
	Spawn:
		SBS1 A 3 Bright A_SeekerMissile(2,2);
		SBS1 B 3 Bright A_Weave(3,1,5,0);
		Loop;
	Death:
		BAL2 C 2 Bright A_SetScale(1.1);
		BAL2 D 3 Bright A_SetTranslucent(0.4);
		BAL2 E 6 Bright A_Explode(17,88);
		Stop;
	}
}
class RS_PurpFire2 : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 16;
		Damage 7; DamageType "Fire";
		Projectile; RenderStyle "Add"; Alpha 0.85; Scale 1.1;
		SeeSound "fire/fire1"; DeathSound "Imp/shotx";
		Translation "192:207=250:254";
	}
	States
	{
	Spawn:
		PFIR ABCD 5 Bright A_Explode(6,20);
		Goto Death;
	Death:
		PFIR EFFG 5 Bright A_Explode(6,20);
		Stop;
	}
}

// ---------- FIREBLU: FireBluHKBall1 -> 3 -> 2 (MANF/MISL/BAL1) ----------
class RS_FireBluHKBall2 : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 20;
		Damage 7; DamageType "Plasma";
		Projectile; RenderStyle "Add"; Alpha 0.75; Scale 1;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "208:223=195:207", "225:231=192:195";
	}
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(4,128);
		Stop;
	}
}
class RS_FireBluHKBall3 : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 12;
		Damage 7; DamageType "Plasma";
		Projectile; RenderStyle "Add"; Alpha 0.75; Scale 0.5;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "208:223=195:207", "225:231=192:195";
	}
	States
	{
	Spawn:
		BAL1 AB 1 Bright A_BishopMissileWeave;
		BAL1 A 0 A_Jump(4,"Death");
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(3,128);
		Stop;
	}
}
class RS_FireBluHKBall1 : Actor
{
	Default
	{
		Radius 20; Height 20; Mass 600; Speed 15;
		Damage 27; DamageType "Plasma";
		Projectile; Scale 1; RenderStyle "Add"; Alpha 0.95;
		SeeSound "Spell/spellCast1"; DeathSound "Crack/death";
		Translation "216:223=199:207", "208:214=193:201", "231:231=194:194", "168:175=198:201";
	}
	States
	{
	Spawn:
		MANF AB 3 A_SpawnItemEx("RS_FireBluHKBall3", random(-3,3), random(-3,3), random(-3,3), 0,0,0,0, SXF_NOCHECKPOSITION);
		Loop;
	Death:
		MISL B 4 A_SetTranslucent(0.35);
		MISL C 1 A_Explode(12,128);
		MISL CCCCCCCCCCCCCC 0 A_CustomMissile("RS_FireBluHKBall2", 5, 0, random(0,360), 0, random(-180,180));
		MISL DDD 2 A_Explode(7,128);
		Stop;
	}
}

// ---------- GRAY: MinesHK (bouncing mine, RIP1) -> CGNail (already in imp file) ----------
class RS_MinesHK : Actor
{
	Default
	{
		Radius 12; Height 12; Speed 32;
		Damage 12; DamageType "Fire";
		RenderStyle "SoulTrans"; Alpha 0.95;
		Projectile; -NOGRAVITY; +BOUNCEONWALLS; +THRUGHOST;
		Gravity 0.3; BounceType "Doom"; BounceCount 25;
		BounceFactor 0.95; WallBounceFactor 1.1;
		SeeSound "monster/dknmsl"; BounceSound "fire/fire3"; DeathSound "weapons/boom1";
		Translation "144:151=90:95", "64:79=96:109", "236:239=104:111", "1:2=111:111";
	}
	States
	{
	Spawn:
		RIP1 ABC 4 Bright;
		RIP1 C 0 A_Jump(4,"Death");
		Loop;
	Death:
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 15);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 45);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 75);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 105);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 135);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 165);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 195);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 225);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 255);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 285);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 315);
		MISL D 0 A_CustomMissile("RS_CGNail", 0, 0, 345);
		Stop;
	}
}

// ---------- CYAN: IceHKShot / IceOrbCyanHK / CyanHKShade / SpikeCyanRev / IceCacoTrail ----------
class RS_SpikeCyanRev : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 9; Mass 500;
		Damage 2; DamageType "Ice";
		Projectile; -NOGRAVITY; +THRUGHOST; Gravity 1.5;
		Scale 0.25; RenderStyle "Add"; Alpha 0.80;
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]";
	}
	States
	{
	Spawn:
		RIP1 ABCABC 8 Bright;
	Death:
		RIP1 CBA 6 A_Explode(1,6);
		Stop;
	}
}
class RS_IceCacoTrail : Actor
{
	Default
	{
		Radius 3; Height 2; Speed 42;
		Damage 9; DamageType "Ice";
		Projectile; RenderStyle "Add"; Alpha 0.5;
		Scale 1.0;
		SeeSound "Ice/Hit2"; DeathSound "spike/spiked";
	}
	States
	{
	Spawn:
		ICEY ABC 3 Bright;
	Death:
		ICEY FGHI 3 Bright;
		Stop;
	}
}
class RS_IceHKShot : Actor
{
	Default
	{
		Radius 5; Height 5; Speed 34;
		Damage 18; DamageType "Ice";
		Projectile; RenderStyle "Add"; Alpha 0.65; Scale 1.5;
		SeeSound "Ice/Hit2"; DeathSound "spike/spiked";
	}
	States
	{
	Spawn:
		ICEY ABC 3 Bright;
		Loop;
	Death:
		TNT1 AAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(0,90));
		TNT1 AAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(89,180));
		TNT1 AAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(181,270));
		TNT1 AAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(271,359));
		ICEY FGHI 5 Bright;
		Stop;
	}
}
class RS_CyanHKShade : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 1;
		Projectile; +NOCLIP; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.25;
		Translation "0:255=%[0.07,0.35,0.87]:[1.01,2.00,2.00]";
	}
	States
	{
	Spawn:
		HFRY A 2 Bright;
	Death:
		TNT1 A 0 A_SetTranslucent(0.20);
		HFRY A 2 Bright A_SetScale(1.1,1.1);
		TNT1 A 0 A_SetTranslucent(0.10);
		HFRY A 2 Bright A_SetScale(1.3,1.3);
		TNT1 A 0 A_SetTranslucent(0.05);
		HFRY A 2 Bright A_SetScale(1.5,1.5);
		Stop;
	}
}
class RS_IceOrbCyanHK : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 42;
		Damage 30; DamageType "Ice";
		Projectile; Scale 2;
		SeeSound "ice/Cast"; DeathSound "Ice/Hit2";
		Translation "0:255=%[0.07,0.35,0.87]:[1.01,2.00,2.00]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ICEY A 2 Bright;
		ICEY B 2 Bright A_SpawnItemEx("RS_IceCacoTrail", 0,0,0, random(2,21),0,random(-5,25), random(0,359), SXF_NOCHECKPOSITION);
		ICEY C 2 Bright A_SpawnItemEx("RS_IceCacoTrail", 0,0,0, random(2,21),0,random(-5,25), random(0,359), SXF_NOCHECKPOSITION);
		Loop;
	Death:
		TNT1 A 0 A_SetScale(2.5,1.5);
		ICEY F 4 Bright A_Explode(30,128);
		TNT1 AAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(0,90));
		TNT1 AAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(89,180));
		TNT1 AAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(181,270));
		TNT1 AAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev", 0,0,1, random(12,40),0,random(5,25), random(271,359));
		ICEY GHI 3 Bright;
		Stop;
	}
}

// ---------- BROWN: BrownHKShieldCheck (melee probe) + HKRedDeath (shared w/ Red) ----------
class RS_BrownHKShieldCheck : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 20;
		Damage 35; DamageType "Melee";
		Projectile; Alpha 0.85; Scale 1.5; Gravity 0.5;
	}
	States
	{
	Spawn:
		TNT1 A 6;
		Goto Death;
	XDeath:
		TNT1 A 1 A_PlaySound("monster/dknswg");
		Stop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
class RS_REDTHINGSHK : Actor
{
	Default
	{
		Radius 5; Height 5; Mass 5; Speed 9;
		Projectile; +THRUACTORS; Scale 0.2; RenderStyle "Add"; Alpha 0.8;
		Translation "208:223=176:191", "224:231=176:176";
	}
	States
	{
	Spawn:
		BAL1 AB 12;
		BAL1 A 2 A_Jump(32,"Death");
		Loop;
	Death:
		BAL1 A 1 A_SetTranslucent(0.35);
		Stop;
	}
}
class RS_HKRedDeath : Actor
{
	Default
	{
		Radius 10; Height 42; +DONTGIB; +NOGRAVITY;
		DamageType "Fire"; DeathSound "world/barrelx"; Scale 0.7;
	}
	States
	{
	Spawn:
		BAR1 AB 0 A_PlaySound("world/barrelx");
		Goto Death;
	Death:
		MISL B 8 Bright A_Explode(7,42);
		MISL C 6 Bright A_PlaySound("world/barrelx");
		MISL D 3 Bright A_SpawnItemEx("RS_REDTHINGSHK", 0,0,0, frandom(-4,4),frandom(-4,4),frandom(2,8));
		Stop;
	}
}

// ---------- YELLOW: FireHKBall1 (BRB2) + BigHK -> BigHK2/BigHK3 (XXBF) ----------
class RS_SparkPuff1 : Actor
{
	Default
	{
		+NOBLOCKMAP; +NOGRAVITY; +SPAWNFLOAT; +NOINTERACTION;
		RenderStyle "Add"; Speed 1; Alpha 0.95; VSpeed 4; Mass 2;
	}
	States
	{
	Spawn:
		PUFF ABAB 4 Bright;
		Stop;
	}
}
class RS_FireHKBall1 : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 15;
		Damage 25; DamageType "Fire";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9;
		SeeSound "imp/attack"; DeathSound "imp/shotx"; Decal "BaronScorch";
	}
	States
	{
	Spawn:
		BRB2 AB 6 Bright A_CustomMissile("RS_SparkPuff1", 1, 0, CMF_AIMOFFSET, random(0,360), random(0,360));
		Loop;
	Death:
		BRB2 CDEFGHI 3 Bright A_Explode(4,32);
		Stop;
	}
}
class RS_BigHK2 : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 0;
		Damage 30; DamageType "Fire";
		Projectile; RenderStyle "Add"; Scale 1.33; Alpha 0.9; +NOCLIP;
		SeeSound "fire/fire3";
	}
	States
	{
	Spawn:
		XXBF AB 2 Bright;
		XXBF C 2 Bright A_Explode(13,100,0);
		XXBF DEFGHIJKLMNOPQRS 2 Bright;
		Stop;
	}
}
class RS_BigHK3 : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 12;
		Damage 30; DamageType "Fire";
		Projectile; RenderStyle "Add"; Scale 1.33; Alpha 0.9; +NOCLIP;
		SeeSound "fire/fire3";
	}
	States
	{
	Spawn:
		XXBF AB 2 Bright;
		XXBF C 2 Bright A_Explode(13,88,0);
		XXBF DEFGHIJKLMNOPQRS 2 Bright;
		Stop;
	}
}
class RS_BigHK : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 18;
		Damage 43; DamageType "Fire";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; Scale 2;
		SeeSound "imp/attack"; DeathSound "weapons/rocklx"; Decal "BaronScorch";
	}
	States
	{
	Spawn:
		BRB2 ABABAB 2 Bright A_SpawnItemEx("RS_BigHK2", random(-8,2), random(-12,12), 0, 0,0,0,0, SXF_NOCHECKPOSITION);
		Loop;
	Death:
		BRB2 C 1 Bright A_CustomMissile("RS_BigHK3", 4, 0, CMF_AIMOFFSET, random(0,360), random(0,360));
		BRB2 D 1 Bright A_CustomMissile("RS_BigHK3", 4, 0, CMF_AIMOFFSET, random(0,360), random(0,360));
		BRB2 E 1 Bright A_CustomMissile("RS_BigHK3", 4, 0, CMF_AIMOFFSET, random(0,360), random(0,360));
		BRB2 FGHI 3 Bright A_Explode(4,32);
		Stop;
	}
}

// ---------- ABYSS: AbyssHKBall (BAL7) -> SplashAbyss2 (imp file) + AbyssHKMist (PSBG) ----------
class RS_AbyssHKMist : Actor
{
	Default
	{
		Radius 16; Height 12; Speed 1; DamageType "Ice";
		Projectile; RenderStyle "Add"; Scale 1.33; Alpha 0.6;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
	}
	States
	{
	Spawn:
		PSBG CDE 2 Bright;
		Goto Death;
	Death:
		PSBG FGHIIHGFFGHI 6 Bright A_Explode(5,46);
		Stop;
	}
}
class RS_AbyssHKBall : Actor
{
	Default
	{
		Radius 12; Height 9; Speed 28; Scale 1.42;
		Damage 32; DamageType "Plasma";
		Projectile; +RANDOMIZE; +DONTHARMCLASS; RenderStyle "Add"; Alpha 1.0;
		SeeSound "baron/attack"; DeathSound "spit/spit2";
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
	}
	States
	{
	Spawn:
		BAL7 AB 4 Bright;
		Loop;
	Death:
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SplashAbyss2", random(-228,228), random(-8,8), random(6,16), 0,0,2,0, SXF_NOCHECKPOSITION);
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SplashAbyss2", random(-8,8), random(-228,228), random(6,16), 0,0,2,0, SXF_NOCHECKPOSITION);
		TNT1 A 0 A_Explode(19,64,0);
		PLSE CDE 3 Bright;
		TNT1 AAA 0 A_SpawnItemEx("RS_AbyssHKMist", random(-156,156), random(-156,156), 6, random(1,11),0,0, random(-359,359), SXF_NOCHECKPOSITION);
		Stop;
	}
}

// ---------- RED: BloodBoltHK (BAL1) -> REDTHINGSHK + EffectHK + THEBEEHK -> THEBEEHK2 ----------
class RS_THEBEEHK2 : Actor
{
	Default
	{
		Radius 4; Height 4; Speed 8;
		Damage 2; DamageType "Fire";
		Projectile; +THRUGHOST; RenderStyle "Add"; Alpha 0.85; Scale 1.2;
		DeathSound "weapons/firex4";
	}
	States
	{
	Spawn:
		CBAL ABCDEFG 2 Bright;
		Stop;
	}
}
class RS_THEBEEHK : Actor
{
	Default
	{
		Radius 5; Height 5; Speed 36;
		Damage 2; DamageType "Fire";
		RenderStyle "Add"; Alpha 0.85; Projectile; +THRUGHOST; +SEEKERMISSILE;
		Scale 1.7; SeeSound "weapons/firmfi"; DeathSound "weapons/firex4";
	}
	States
	{
	Spawn:
		VBA3 A 1 NoDelay A_SeekerMissile(32,255,SMF_PRECISE);
		VBA3 B 1 Bright A_Explode(1,42);
		Loop;
	Death:
		CBAL CCDDEEFFGG 1 Bright A_SpawnItemEx("RS_THEBEEHK2", random(-9,9), random(-9,9), random(-5,5), 0,0,0,0, SXF_NOCHECKPOSITION);
		Stop;
	}
}
class RS_EffectHK : Actor
{
	Default { Radius 5; Height 5; Mass 5; Speed 0; Projectile; +NOINTERACTION; }
	States
	{
	Spawn:
		BAL1 A 1;
		Goto Death;
	Death:
		BAL1 A 1 A_SpawnItemEx("RS_REDTHINGSHK", 0,0,0, frandom(-3,3),frandom(-3,3),frandom(2,6));
		Stop;
	}
}
class RS_BloodBoltHK : Actor
{
	Default
	{
		Radius 12; Height 12; Mass 25; Speed 17;
		Damage 32; DamageType "Plasma";
		Projectile; Scale 0.75; RenderStyle "Add"; Alpha 0.95;
		SeeSound "Spell/spellCast1"; DeathSound "fire/Fire4";
		Translation "208:223=176:191", "224:231=176:176";
	}
	States
	{
	Spawn:
		BAL1 AB 4 A_CustomMissile("RS_REDTHINGSHK", 3, 0, CMF_AIMOFFSET, random(0,360), random(0,360));
		Loop;
	Death:
		BAL1 C 4 A_SetTranslucent(0.35);
		BAL1 D 5 A_Explode(8,32);
		BAL1 E 5 A_Explode(8,44);
		Stop;
	}
}

// ---------- BROWN: HellionBall (HLBL, seeking) + HellionPuff trail ----------
class RS_HellionPuff : Actor
{
	Default { Radius 3; Height 3; RenderStyle "Add"; Alpha 0.67; +NOGRAVITY; +NOBLOCKMAP; +DONTSPLASH; +FORCEXYBILLBOARD; }
	States
	{
	Spawn:
		TNT1 A 3 Bright;
		HLBL CDEFGHI 3 Bright;
		Stop;
	}
}
class RS_HellionBall : Actor
{
	Default
	{
		Radius 12; Height 16; Speed 19;
		Damage 32; DamageType "Fire";
		Alpha 0.80; Scale 1.3;
		Projectile; +THRUGHOST; +FORCEXYBILLBOARD; +SEEKERMISSILE; RenderStyle "Add";
		SeeSound "Monster/hlnatk"; DeathSound "Monster/hlnexp"; Decal "DoomImpScorch";
	}
	States
	{
	Spawn:
		HLBL A 1 Bright A_SeekerMissile(7,5);
		HLBL B 1 Bright A_SpawnItemEx("RS_HellionPuff", 0,0,0,0,0,0,0,128);
		HLBL A 1 Bright A_Weave(1.0,1.0,1.0,10);
		HLBL B 1 Bright A_SpawnItemEx("RS_HellionPuff", 0,0,0,0,0,0,0,128);
		Loop;
	Death:
		HLBL JKLMN 3 Bright;
		Stop;
	}
}

// ============================================================================
// GRAY's ranged attack -- MolochNail (BLAD/6PUF/FBL1, shares PuffCybieRed).
// (Gray is range-dual: far -> MolochNail bolts, close -> MinesHK barrage.)
// ============================================================================
class RS_MolochNail : Actor
{
	Default
	{
		Radius 4; Height 6; Speed 30; Scale 1.1;
		Damage 20; DamageType "Fire";
		Decal "BulletChip";
		AttackSound "moloch/nailhitbleed"; DeathSound "weapons/firex4";
		Projectile; +SPAWNSOUNDSOURCE; +EXTREMEDEATH; +BLOODSPLATTER; +ROCKETTRAIL;
	}
	States
	{
	Spawn:
		BLAD A 1 Bright;
		Loop;
	Death:
		"6PUF" A 0 A_PlaySound("moloch/nailhit");
		"6PUF" ABCDEF 1 Bright A_Explode(6,64);
		FBL1 EFG 1 Bright A_Explode(12,64);
		FBL1 G 1 Bright A_SpawnItemEx("RS_PuffCybieRed",0,0,2);
		Stop;
	}
}

// ============================================================================
// BLACK HK ARSENAL -- the apex projectiles, ripped faithfully w/ full sub-spawn
// trees. Stock IWAD sprites (GRND grenade, BFS1/BFE1 BFG, PLSS/PLSE plasma, MISL,
// PUFF) used as CH uses them. Custom sprites ripped (STRS/FBRS/BAL3/MSLH/MTRL/BBOM).
// ============================================================================

// --- BaronNade: bouncing grenade -> BaronStar3 seeking shrapnel ---
class RS_BaronStar3 : Actor
{
	Default
	{
		Radius 5; Height 7; Speed 27; FastSpeed 38;
		Damage 17; DamageType "Fire"; Species "BaronOfHell";
		Projectile; +RANDOMIZE; +DONTHARMCLASS; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 1; Scale 1.3;
		SeeSound "caco/attack"; DeathSound "spell/Impact1";
	}
	States
	{
	Spawn:
		STRS AB 2 Bright A_SeekerMissile(3,3);
		STRS CD 2 Bright A_Weave(4,1,6,0);
		Goto Death;
	Death:
		BBOM A 2 Bright A_SetScale(1.5);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(12,148);
		BBOM EFG 6 Bright A_Explode(17,148);
		Stop;
	}
}
class RS_BaronNade : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 25;
		Damage 47; DamageType "Fire";
		Projectile; -NOGRAVITY; +GRENADETRAIL;
		BounceType "Doom"; Gravity 0.29; BounceCount 15; BounceFactor 1.15; WallBounceFactor 0.7;
		SeeSound "weapons/grenlf"; DeathSound "weapons/grenlx"; BounceSound "prox/beep";
	}
	States
	{
	Spawn:
		GRND A 1 Bright;
		GRND A 1 Bright A_Jump(12,"Bounce");
		GRND A 1 Bright A_Jump(4,"Death");
		Loop;
	Bounce:
		GRND A 2 Bright ThrustThing(angle*256/(random(1,360)),12,0,0);
		Goto Spawn;
	Death:
		MISL B 8 Bright A_Explode(35,128);
		MISL CCCC 2 Bright A_SpawnItemEx("RS_BaronStar3", random(-180,180), random(-180,180), random(1,32), 0,0,0, SXF_NOCHECKPOSITION);
		MISL DDDD 2 Bright A_SpawnItemEx("RS_BaronStar3", random(-220,220), random(-220,220), random(1,32), 0,0,0, SXF_NOCHECKPOSITION);
		Stop;
	}
}

// --- BruiserMissile: fire bolt + trail ---
class RS_BruiserTrail : Actor
{
	Default { Radius 3; Height 3; RenderStyle "Translucent"; Alpha 0.67; Projectile; }
	States
	{
	Spawn:
		TNT1 A 3 Bright;
		PUFF ABCD 4 Bright;
		Stop;
	}
}
class RS_BruiserMissile : Actor
{
	Default
	{
		Radius 8; Height 12; Speed 20; Scale 1.15;
		Damage 47; DamageType "Fire";
		Projectile; RenderStyle "Normal"; +THRUGHOST; DamageType "Fire";
		SeeSound "monster/brufir"; DeathSound "weapons/hellex"; Decal "Scorch";
	}
	States
	{
	Spawn:
		FBRS A 1 Bright;
		FBRS A 1 Bright A_SpawnItemEx("RS_BruiserTrail",0,0,0,0,0,0,0,128);
		Loop;
	Death:
		BAL3 C 0 A_SetTranslucent(0.67,1);
		BAL3 C 6 Bright A_SetScale(1.5);
		BAL3 D 6 Bright A_Explode(47,128,0);
		BAL3 E 6 Bright;
		Stop;
	}
}

// --- MegaRedRev: fast revenant-style bolt + load FX ---
class RS_RedRevLoad : Actor
{
	Default { Radius 1; Height 1; +NOCLIP; +NOGRAVITY; +NOINTERACTION; RenderStyle "Add"; Alpha 0.75; SeeSound "Weapons/BFGF"; }
	States
	{
	Spawn:
		SPIR ABCDE 4 Bright;
		Stop;
	}
}
class RS_RedRevLoad2 : Actor
{
	Default { Radius 1; Height 1; +NOCLIP; +NOGRAVITY; +NOINTERACTION; RenderStyle "Add"; Alpha 0.75; SeeSound "Weapons/BFGF"; }
	States
	{
	Spawn:
		SPIR ABCDE 3 Bright A_SpawnItemEx("RS_RedRevLoad",0,0,4,0,0,0,0,128);
		Stop;
	}
}
class RS_MegaRedRev : Actor
{
	Default
	{
		Radius 11; Height 9; Speed 90; Scale 1.5;
		Damage 60; DamageType "Plasma";
		Projectile; RenderStyle "Add"; Alpha 0.8;
		SeeSound "Crack/see"; DeathSound "Litn/litn3";
		Translation "192:207=171:191", "240:247=191:191";
	}
	States
	{
	Spawn:
		BLL9 AAAABBBB 1 Bright A_SpawnItemEx("RS_RedRevLoad2",0,0,4,0,0,0,0,128);
		Loop;
	Death:
		BLL9 CDE 6 Bright A_Explode(35,64);
		Stop;
	}
}

// --- SwooshCBBar1: BFG-swoosh -> PlasmaBallSP4 spray + lightning trails ---
class RS_PlasmaBallSP4 : Actor
{
	Default
	{
		Radius 3; Height 3; Speed 9; Scale 0.25;
		Damage 5; DamageType "Plasma";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.75;
		DeathSound "weapons/plasmax";
	}
	States
	{
	Spawn:
		PLSS AB 6 Bright;
		PLSS A 0 A_Jump(2,"Death");
		Loop;
	Death:
		PLSE ABCDE 4 Bright;
		Stop;
	}
}
class RS_SwooshCBTR2 : Actor
{
	Default
	{
		Radius 13; Height 8; Speed 30; Scale 0.2;
		Projectile; +FULLVOLDEATH; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.25;
		DeathSound "Spell/Lightn"; Translation "112:127=192:207";
	}
	States
	{
	Spawn:
		BFS1 AB 2 Bright;
		Goto Death;
	Death:
		BFS1 AB 4 Bright A_Explode(10,32);
		Stop;
	}
}
class RS_SwooshCBTR : Actor
{
	Default
	{
		Radius 13; Height 8; Speed 33; Scale 0.4;
		Projectile; +FULLVOLDEATH; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.50;
		DeathSound "Spell/Lightn"; Translation "112:127=192:207";
	}
	States
	{
	Spawn:
		BFS1 AB 2 Bright A_SpawnItemEx("RS_SwooshCBTR2",0,0,2);
		Goto Death;
	Death:
		BFS1 AB 4 Bright;
		Stop;
	}
}
class RS_SwooshCBBar1 : Actor
{
	Default
	{
		Radius 13; Height 8; Speed 36; Scale 0.6;
		Damage 25; DamageType "Plasma";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.75;
		SeeSound "Litn/litn3"; DeathSound "weapons/bfgx";
		Translation "112:127=192:207";
	}
	States
	{
	Spawn:
		BFS1 AB 1 Bright A_SpawnItemEx("RS_SwooshCBTR",0,0,3);
		Loop;
	Death:
		BFE1 ABC 1 Bright A_Explode(17,124);
		BFS1 BBBBBBBBBBBBBBB 0 A_SpawnItemEx("RS_PlasmaBallSP4", random(-8,8), random(-8,20), 0, random(15,60),0,random(-33,33), random(0,180));
		BFS1 BBBBBBBBBBBBBBB 0 A_SpawnItemEx("RS_PlasmaBallSP4", random(-8,8), random(-8,20), 0, random(15,60),0,random(-33,33), random(180,359));
		Stop;
	}
}

// --- SpreadMisBar1: homing rocket -> MolochNail shrapnel ---
class RS_HomingRocketTrailFatso : Actor
{
	Default { Radius 4; Height 3; Speed 1; Scale 0.7; +NOGRAVITY; +NOTELEPORT; RenderStyle "Translucent"; Alpha 0.33; }
	States
	{
	Spawn:
		MTRL A 2;
		MTRL BCD 3;
		MTRL E 4 A_SetTranslucent(0.2);
		Stop;
	}
}
class RS_SpreadMisBar1 : Actor
{
	Default
	{
		Radius 11; Height 8; Speed 17; Scale 1.25;
		Damage 25; DamageType "Fire";
		Projectile;
		SeeSound "weapons/hominglaunch"; DeathSound "weapons/homingexplode";
	}
	States
	{
	Spawn:
		MSLH A 2 Bright A_SpawnItemEx("RS_HomingRocketTrailFatso",0,0,0,0,0,0,0,128);
		MSLH A 0 A_Jump(10,"Death");
		Loop;
	Death:
		MISL B 0 A_SetTranslucent(0.8,1);
		MISL B 2 Bright A_Explode(20,88);
		MISL C 3 Bright;
		MISL CC 0 A_CustomMissile("RS_MolochNail", random(-2,2), random(-2,2), random(-4,4), CMF_AIMDIRECTION|CMF_SAVEPITCH);
		MISL DD 0 A_CustomMissile("RS_MolochNail", random(-2,2), random(-2,2), random(-4,4), CMF_AIMDIRECTION|CMF_SAVEPITCH);
		MISL D 3 Bright;
		Stop;
	}
}

// --- BluCybFX: cosmetic plasma burst ---
class RS_BluCybFX : Actor
{
	Default
	{
		Radius 15; Height 9; Speed 1; Scale 1.3;
		Projectile; RenderStyle "Add"; Alpha 0.75;
	}
	States
	{
	Spawn:
		PLSE BCD 3 Bright;
		Goto Death;
	Death:
		PLSE CDE 3 Bright;
		Stop;
	}
}

// Black HK's two-phase mode gate (escalates after taking pain)
class RS_BrusMode : Inventory { Default { Inventory.MaxAmount 3; } }

// ============================================================================
// WHITE HELL KNIGHT ("Ghost of E1M8") projectiles -- from base CH WhiteHK3.
// A wall-phasing ghost: phantom-eggs, soul-bombs, soul-trails, spectre summons.
// Egg-hatch + summon simplified to stock Spectre (deep MiniPhantom chain folded).
// ============================================================================
class RS_SoulTrail : Actor
{
	Default { Radius 3; Height 3; Speed 15; Projectile; RenderStyle "Add"; Alpha 0.67; DamageType "Fire"; }
	States { Spawn: SPIR QRS 4; Goto Death; Death: SPIR S 6 Bright; Stop; }
}
class RS_PhantomEgg : Actor
{
	Default { Damage 40; Projectile; DamageType "Plasma"; Radius 13; Height 8; Speed 22;
		SeeSound "phantom/spirit1"; RenderStyle "Add"; Translation "192:207=84:95"; Scale 1.2; }
	States
	{
	Spawn:
		PLSS AB 5 A_SpawnItemEx("RS_SoulTrail",0,0,0,0,0,0,0,128);
		Loop;
	Death:
		// CH hatched MiniPhantom; RS hatches a stock Spectre ambusher
		PLSS A 1 A_SpawnItemEx("Spectre",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		Stop;
	}
}
class RS_SoulBomb : Actor
{
	Default { Radius 12; Height 8; Speed 11; Damage 50; Projectile; RenderStyle "Add"; Alpha 0.67; Scale 0.95;
		MissileType "RS_SoulTrail"; SeeSound "phantom/bomb"; DeathSound "phantom/explode";
		Translation "128:143=80:95","168:191=80:95","208:223=80:88","48:63=80:95"; }
	States
	{
	Spawn:
		SKUL C 1 Bright A_SpawnItemEx("RS_SoulTrail",0,0,13,0,0,0,0,128);
		SKUL D 1 Bright A_SpawnItemEx("RS_SoulTrail",0,0,14,0,0,0,0,128);
		SKUL C 1 Bright A_SpawnItemEx("RS_SoulTrail",0,0,15,0,0,0,0,128);
		SKUL D 1 Bright A_SpawnItemEx("RS_SoulTrail",0,0,16,0,0,0,0,128);
		Loop;
	Death:
		SPIR B 0 A_SetScale(1.8);
		SPIR K 3 Bright A_Explode(45,200);
		SPIR L 3 Bright A_Explode(37,178);
		SPIR M 3 Bright A_Explode(30,158);
		SPIR N 3 Bright A_Explode(22,128);
		SPIR O 3 Bright;
		Stop;
	}
}

// ============================================================================
// BLACK HK EX ("T-800 Baron MK II") projectiles -- CHPLUS miniboss apex (11_KX).
// Shares MegaRedRev/RedRevLoad/BluCybFX/HKRedDeath/BruiserTrail/HomingRocketTrailFatso
// with the regular Black HK. New EX-specific ones below.
// ============================================================================
class RS_ZapDecHKex : Actor
{
	// small lightning decoration sprayed by the T-800's zap attacks
	Default { Speed 1; Projectile; +NOINTERACTION; +NOCLIP; RenderStyle "Add"; Alpha 0.7; Scale 0.9;
		Translation "112:127=192:207"; }
	States { Spawn: LITN ABCDEFGOP 3 Bright; Stop; }
}
class RS_HKEXFastBeamTrail : Actor
{
	Default { Speed 1; Projectile; +NOCLIP; RenderStyle "Add"; Alpha 0.5; Translation "112:127=192:207"; }
	States
	{
	Spawn:
		BFS1 A 3 Bright;
	Death:
		BFS1 AB 4 Bright A_Explode(25,32);
		BFS1 A 3 Bright A_SetScale(0.1,0.1);
		Stop;
	}
}
class RS_HKEXFastBeam : FastProjectile
{
	Default { Radius 13; Height 6; Speed 64; Projectile; RenderStyle "Add"; DamageType "Plasma";
		Alpha 0.5; YScale 0.3; XScale 0.75; SeeSound "Spell/Lightn"; DeathSound "Spell/Lightn";
		Translation "112:127=192:207"; }
	States
	{
	Spawn:
		BFS1 A 1 Bright A_SpawnItemEx("RS_HKEXFastBeamTrail",0,0,1);
		TNT1 A 0 A_SpawnItemEx("RS_HKEXFastBeamTrail",-21,0,1);
		BFS1 B 1 Bright A_SpawnItemEx("RS_HKEXFastBeamTrail",0,0,1);
		Loop;
	Death:
		BFS1 AB 4 Bright A_Explode(25,32);
		Stop;
	}
}
class RS_BruiserMissileEx : FastProjectile
{
	Default { Radius 8; Height 12; Speed 33; Damage 67; Scale 1.15; DamageType "Fire"; Projectile;
		RenderStyle "Normal"; +THRUGHOST; SeeSound "monster/brufir"; DeathSound "weapons/hellex";
		DamageType "Fire"; Decal "Scorch"; }
	States
	{
	Spawn:
		FBRS A 1 Bright A_SpawnItemEx("RS_BruiserTrail",0,0,0,0,0,0,0,128);
		Loop;
	Death:
		BAL3 C 0 A_SetTranslucent(0.67,1);
		BAL3 C 4 Bright A_SetScale(2.5,2.0);
		BAL3 D 6 Bright A_Explode(67,208,0);
		BAL3 E 8 Bright;
		Stop;
	}
}
class RS_BruiserMissileEx2 : FastProjectile
{
	Default { Radius 8; Height 12; Speed 29; Damage 100; Scale 1.15; DamageType "Fire"; Projectile;
		RenderStyle "Normal"; +THRUGHOST; +SEEKERMISSILE; SeeSound "monster/brufir"; DeathSound "weapons/hellex";
		DamageType "Fire"; Decal "Scorch"; }
	States
	{
	Spawn:
		FBRS A 1 Bright A_SeekerMissile(6,6,SMF_PRECISE);
		FBRS A 0 A_SpawnItemEx("RS_BruiserTrail",0,0,0,0,0,0,0,128);
		Loop;
	Death:
		BAL3 C 0 A_SetTranslucent(0.67,1);
		BAL3 C 4 Bright;
		BAL3 D 6 Bright A_Explode(25,128,0);
		BAL3 E 8 Bright;
		Stop;
	}
}
class RS_SpreadMisBarEX : FastProjectile
{
	Default { Radius 9; Height 6; Speed 41; Damage 25; DamageType "Fire"; Projectile; Scale 1.1;
		SeeSound "weapons/hominglaunch"; DeathSound "weapons/homingexplode"; }
	States
	{
	Spawn:
		MSLH A 2 Bright A_SpawnItemEx("RS_HomingRocketTrailFatso",0,0,0,0,0,0,0,128);
		Loop;
	Death:
		MISL B 0 A_SetTranslucent(0.8,1);
		MISL B 2 Bright A_Explode(20,88);
		MISL CD 3 Bright;
		Stop;
	}
}
class RS_BaronHellNade : Actor
{
	Default { Speed 28; Damage 57; Projectile; +SEEKERMISSILE; +USEBOUNCESTATE; BounceType "Doom"; BounceCount 12;
		Scale 0.5; SeeSound "weapons/grenlf"; DeathSound "weapons/grenlx"; BounceSound "prox/beep"; RenderStyle "Add"; }
	States
	{
	Spawn:
		BBOM B 1 Bright A_SetScale(0.75,0.35);
		BBOM B 1 Bright A_Weave(4,4,random(-5,5),random(-5,5));
		BBOM B 1 Bright A_SetScale(0.35,0.75);
		BBOM B 1 Bright A_SeekerMissile(12,12);
		Loop;
	Bounce:
		GRND A 2 Bright ThrustThing(angle*256/(random(1,360)),12,0,0);
		Goto Spawn;
	Death:
		MISL B 5 Bright A_Explode(40,128);
		TNT1 AAAA 0 A_SpawnItemEx("RS_BaronStar3",random(-128,128),random(-128,128),random(1,32),0,0,0,SXF_NOCHECKPOSITION);
		Stop;
	}
}
class RS_ZapOrbHKEX : Actor
{
	// orbits the T-800's target, raining zap-decorations (an aura around the player)
	Default { Radius 9; Height 6; Speed 1; Projectile; +NOCLIP; +NOINTERACTION; }
	States
	{
	Spawn:
		TNT1 A 1 Bright A_Warp(AAPTR_TARGET,1,0,88,0,WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE);
		TNT1 A 1 Bright A_SpawnItemEx("RS_ZapDecHKex",random(-64,64),random(-64,64),random(-72,12),0,0,0,0,128);
		TNT1 A 0 A_Jump(2,"Death");
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
class RS_ZapOrbHKEX2 : FastProjectile
{
	Default { Radius 12; Height 6; Speed 41; Damage 7; DamageType "Plasma"; Projectile; +RIPPER; Scale 1.1; }
	States
	{
	Spawn:
		TNT1 A 1 Bright A_SpawnItemEx("RS_ZapDecHKex",random(-16,16),random(-16,16),random(-2,2),0,0,0,0,128);
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}


// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * SGRN -> GRND (source comment wrongly called SGRN a stock IWAD sprite)  (6 occurrences)

// =====================================================================
// CHP FAMILY 11 IMPORT (rebuild pass). Classes CHP's hell knights call
// that had no RS_ port yet. Ported verbatim from
// E:\New folder\ART SOURCE\CHP\DECORATE\11\ (CH parents where CHP only
// tweaks a property).
// =====================================================================

// T00/T01's combo ball. CHP ships its own BaronBall_C (15_C.txt) rather
// than calling the stock class -- same silhouette, its own numbers.
class RS_BaronBall : FastProjectile
{
	Default
	{
		Radius 6; Height 16; Speed 15; FastSpeed 20;
		Damage 8;
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 1.0;
		SeeSound "baron/attack"; DeathSound "baron/shotx";
		Decal "BaronScorch";
	}
	States
	{
	Spawn:
		BAL7 AB 4 Bright;
		Loop;
	Death:
		BAL7 CDE 6 Bright;
		Stop;
	}
}

// T08's parry. A real reflective wall the Hellion warrior throws up in
// front of itself -- REFLECTIVE + SHIELDREFLECT means shots come back.
class RS_BrownHKShield : Actor
{
	Default
	{
		Radius 72; Height 64; Speed 1;
		Species "BaronOfHell";
		Health 999;
		Monster;
		+NOTRIGGER +NOTARGET +DONTTHRUST +NOGRAVITY +INVULNERABLE
		+REFLECTIVE +SHIELDREFLECT +THRUSPECIES +MTHRUSPECIES
		-COUNTKILL
		RenderStyle "Add"; Alpha 0.95; Scale 1.1;
		Translation "0:255=#[240,247,9]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		DKNT Z 1 Bright { A_SetScale(0.4, 0.4); }
		DKNT Z 1 Bright { A_SetScale(0.6, 0.6); }
		DKNT Z 1 Bright { A_SetScale(0.7, 0.5); }
		DKNT Z 1 Bright { A_SetScale(0.9, 0.8); }
		TNT1 A 0 { A_FaceTarget(); }
		DKNT Z 1 Bright { A_SetScale(1.25, 1.1); }
		TNT1 A 0 { A_StartSound("HEALSIEL", CHAN_AUTO); }
		DKNT Z 8 Bright;
		Goto Death;
	Death:
		DKNT Z 2 Bright { A_NoBlocking(); }
		DKNT Z 2 Bright { A_SetScale(0.8, 0.7); }
		DKNT Z 2 Bright { A_SetScale(0.5, 0.4); }
		DKNT Z 2 Bright { A_SetScale(0.3, 0.2); }
		DKNT Z 2 Bright { A_SetScale(0.2, 0.1); }
		TNT1 A 0 { A_Die(); }
		Stop;
	}
}

// The shield plate the Hellion warrior drops when it dies.
class RS_HellWarriorShield : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 6;
		BounceType "Doom";+DROPOFF +MISSILE
	}
	States
	{
	Spawn:
		HWSH ABCDEFGH 3;
		Loop;
	Death:
		HWSH I -1;
		Stop;
	}
}

// The gore burst every knight's XDeath opens with.
class RS_HKSplashDed : Actor
{
	Default
	{
		Radius 10; Height 42;
		+NOGRAVITY
		Scale 2.0;
	}
	States
	{
	Spawn:
		BAR1 AB 0;
		Goto Death;
	Death:
		BAL7 C 6 Bright { A_StartSound("misc/gibbed/c"); }
		BAL7 DE 6 Bright;
		Stop;
	}
}

// =====================================================================
// CHP 11_B BlueHKShot -- the blue hell knight's plasma bolt.
// ---------------------------------------------------------------------
// Ported here because the EX lost soul (RS_LostSoul TEX, CHP 05_WX) wears
// a hell knight form and fires this as part of that form's chain. It is a
// hell knight projectile, so it lives in the hell knight's library.
// =====================================================================
class RS_BlueHKShot : FastProjectile
{
	Default
	{
		Radius 6;
		Height 16;
		Speed 18;
		FastSpeed 25;
		DamageFunction (random(10, 45));
		DamageType "Plasma";
		Projectile;
		+RANDOMIZE
		RenderStyle "Add";
		Alpha 0.85;
		SeeSound "baron/attack";
		DeathSound "weapons/plasmax";
		Translation "112:127=192:207";
	}
	States
	{
	Spawn:
		BAL7 AB 4 Bright;
		Loop;
	Death:
		PLSE CDE 3 Bright;
		Stop;
	}
}
