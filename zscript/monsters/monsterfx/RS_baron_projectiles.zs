// =====================================================================
// RS_baron_projectiles.zs
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
// hf_baron_projectiles.zs -- projectiles for the RS_Baron color rainbow.
// PASS 1: Neutral + Green/Blue/Purple/Yellow/FireBlu/Gray/Red colors.
// (Pass 2 adds Cyan/Brown/Abyss/Black/White heavy custom bodies.)
//
// Ripped faithfully from Colourful Hell (full dependency trees traced).
// NOTE: earlier passes flattened CH's damage ROLLS to single constants on the
// false belief that a ZScript Default block requires a constant Damage. It does
// not -- `DamageFunction (random(a,b))` is the property for exactly this and it
// PRESERVES the roll. Rolls are restored wherever they were recorded; any bare
// constant left here is one whose original spread was lost and needs re-reading
// from CH/CHP.
// Translations/flags/sub-spawns preserved.
// Stock IWAD sprites (BAL1/BAL2/BAL7/MISL/PLSE/BFE1) used as CH uses them.
// Shared with imp/HK (reused, not redefined): RS_BaronStar3, RS_RedRevLoad/2,
// RS_SparkPuff1, RS_RedBBall, RS_BluBBall, RS_CrackoBallTrail.
// Cosmetic multi-hop trails collapsed into self-contained forms.
// ============================================================================

// ---------- GREEN: Spspit2 (seeking) + Spspit3 (greenie-spitter) ----------
class RS_GreeniesBR : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 15; Mass 5;
		Damage 1; DamageType "Poison";
		Projectile; +RANDOMIZE; +BOUNCEONFLOORS; +EXPLODEONWATER;
		RenderStyle "Add"; Alpha 0.75; BounceType "Hexen"; BounceCount 3;
		BounceFactor 1.1; WallBounceFactor 1.1; Scale 0.25;
		SeeSound "fire/fire1"; DeathSound "caco/shotx";
		Translation "168:191=112:127", "250:254=117:119", "208:223=112:124";
	}
	States
	{
	Spawn:
		BAL2 AB 4 Bright;
		Loop;
	Death:
		BAL2 C 3 Bright A_SetTranslucent(0.4);
		BAL2 DE 2 Bright;
		Stop;
	}
}
class RS_Trail12 : Actor
{
	Default { Radius 6; Height 16; Speed 16; Projectile; +NOINTERACTION; RenderStyle "Add"; Scale 0.5; Alpha 0.5; }
	States { Spawn: BAL7 CDE 6 Bright; Stop; }
}
class RS_Spspit2 : Actor
{
	Default
	{
		Radius 6; Height 16; Speed 25;
		Damage 40; DamageType "Plasma";
		Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.85;
		SeeSound "baron/attack"; DeathSound "imp/shotx";
	}
	States
	{
	Spawn:
		BAL7 A 2 Bright A_SpawnItemEx("RS_Trail12",0,0,8);
		BAL7 B 2 Bright A_SeekerMissile(2,2);
		Loop;
	Death:
		BAL7 CDE 3 Bright;
		Stop;
	}
}
class RS_Spspit3 : Actor
{
	Default
	{
		Radius 8; Height 16; Speed 12;
		Damage 36; DamageType "Plasma";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85; Scale 1.33;
		SeeSound "baron/attack"; DeathSound "imp/shotx";
		Translation "168:191=112:127";
	}
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
	Fly:
		BAL1 A 4 Bright A_SpawnItemEx("RS_GreeniesBR", -3,0,0, random(1,9),0,random(-3,9), random(180,210));
		BAL1 B 4 Bright A_SpawnItemEx("RS_GreeniesBR", -3,0,0, random(1,9),0,random(-3,9), random(150,180));
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(4,32);
		Stop;
	}
}

// ---------- BLUE: SmashBall4 (seeking + trail) + SmashBalls2 (bouncing splitter) ----------
class RS_Blutrail1 : Actor
{
	Default { Radius 15; Height 9; Speed 0; Projectile; +NOINTERACTION; RenderStyle "Add"; Alpha 0.55; Scale 1.2;
		Translation "192:194=198:202", "4:4=195:195", "224:225=193:196"; }
	States { Spawn: PLSE BCD 3 Bright; Goto Death; Death: PLSE DE 3 Bright; Stop; }
}
class RS_STracerPuffBlue : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 0; RenderStyle "Add"; DamageType "Fire"; Alpha 0.67;
		Projectile; ExplosionRadius 8; ExplosionDamage 1; +FLOORHUGGER; -NOGRAVITY; +DONTSPLASH;
		Translation "0:255=%[0.00,0.00,0.57]:[1.02,1.15,1.99]";
	}
	States { Spawn: FTRA ABCDEFGHIJ 3 Bright; Stop; }
}
class RS_STracerBlue : Actor
{
	Default
	{
		Radius 5; Height 5; Speed 2;
		Damage 11; DamageType "Fire";
		RenderStyle "Add"; Alpha 0.67; Projectile; +FLOORHUGGER; +THRUGHOST; -NOGRAVITY; +DONTSPLASH;
		DeathSound "weapons/firex4";
		Translation "0:255=%[0.00,0.00,0.57]:[1.02,1.15,1.99]";
	}
	States
	{
	Spawn:
		TNT1 A 1 Bright A_CStaffMissileSlither;
		TNT1 A 0 A_SpawnItem("RS_STracerPuffBlue",0,0);
		TNT1 A 0 A_Jump(24,"Death");
		Loop;
	Death:
		FTRA K 4 Bright;
		FTRA L 4 Bright A_Explode(10,32);
		FTRA MNO 3 Bright;
		Stop;
	}
}
class RS_SmashBall4 : Actor
{
	Default
	{
		Radius 12; Height 18; Speed 24; Mass 4;
		Damage 35; DamageType "Plasma";
		Projectile; +RANDOMIZE; +EXPLODEONWATER; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.75; Scale 1.8;
		SeeSound "caco/attack"; DeathSound "caco/shotx";
		Translation "168:191=192:207", "208:223=193:202", "250:254=197:197", "231:231=224:224";
	}
	States
	{
	Spawn:
		BAL2 A 4 Bright A_SeekerMissile(3,3);
		BAL2 A 0 A_SpawnItemEx("RS_Blutrail1",0,0,5);
		BAL2 B 4 Bright A_SeekerMissile(3,3);
		BAL2 A 0 A_SpawnItemEx("RS_Blutrail1",0,0,5);
		Loop;
	Death:
		BAL2 C 3 Bright A_SetTranslucent(0.4);
		BAL2 DE 6 Bright A_Explode(11,128);
		Stop;
	}
}
class RS_SmashBalls2 : Actor
{
	Default
	{
		Radius 12; Height 18; Speed 11; Mass 4;
		Damage 20; DamageType "Plasma"; Gravity 0.1;
		Projectile; -NOGRAVITY; +RANDOMIZE; +BOUNCEONFLOORS; +USEBOUNCESTATE; +EXPLODEONWATER; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.88; BounceType "Hexen"; BounceCount 7; BounceFactor 2; WallBounceFactor 0.1; Scale 1.5;
		SeeSound "caco/attack"; BounceSound "Bomb/bounce"; DeathSound "caco/shotx";
		Translation "168:191=192:207", "208:223=193:202", "250:254=197:197", "231:231=224:224";
	}
	States
	{
	Spawn:
	Fly:
		BAL2 AB 6 Bright;
		Loop;
	Bounce.Floor:
		BAL2 A 5 Bright;
		TNT1 AAAAA 0 A_CustomMissile("RS_STracerBlue", 0,0, random(1,120), 0);
		TNT1 AAAAA 0 A_CustomMissile("RS_STracerBlue", 0,0, random(121,240), 0);
		TNT1 AAAAA 0 A_CustomMissile("RS_STracerBlue", 0,0, random(241,359), 0);
		BAL2 B 5 Bright A_Jump(64,"FollowMe");
		TNT1 A 0 A_Jump(12,"Death");
		Goto Fly;
	FollowMe:
		BAL2 AB 3 Bright A_SeekerMissile(2,2);
		TNT1 A 0 A_Jump(12,"Death");
		Goto Fly;
	Death:
		BAL2 C 3 Bright A_SetTranslucent(0.4);
		BAL2 DE 6 Bright A_Explode(12,128);
		Stop;
	}
}

// ---------- PURPLE: BaronWave (bouncing) + Spear11 -> TrailB/Zap88 + Zap88 ----------
class RS_Zap88 : Actor
{
	Default { Speed 1; Projectile; +RANDOMIZE; +NOINTERACTION; RenderStyle "Add"; Alpha 0.65; Scale 1; }
	States { Spawn: LITN ABCDEFGOP 3 Bright; Stop; }
}
class RS_BaronWave : Actor
{
	Default
	{
		Radius 9; Height 10; Speed 21; FastSpeed 50;
		Damage 11; DamageType "Fire";
		Projectile; +RANDOMIZE; +DONTHARMCLASS; +EXPLODEONWATER;
		RenderStyle "Add"; Alpha 0.75; BounceType "Hexen"; BounceCount 2; WallBounceFactor 0.7; Scale 0.7;
		SeeSound "caco/attack"; BounceSound "Bomb/bounce"; DeathSound "caco/shotx";
		Translation "168:223=250:254", "224:231=250:250", "168:191=250:254";
	}
	States
	{
	Spawn:
		SBS1 ABCD 8 Bright;
		Loop;
	Death:
		BAL2 C 2 Bright A_SetScale(1.1);
		BAL2 D 3 Bright A_SetTranslucent(0.4);
		BAL2 E 6 Bright A_Explode(9,88);
		Stop;
	}
}
class RS_TrailB : Actor
{
	Default
	{
		Radius 6; Height 16; Speed 31; FastSpeed 52;
		DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.65; Scale 0.6;
		SeeSound "baron/attack"; DeathSound "weapons/plasmax";
		Translation "112:127=250:254", "0:0=250:254", "112:113=224:224", "192:193=224:224", "192:207=250:254";
	}
	States
	{
	Spawn:
		SPER AB 4 Bright;
		Goto Death;
	Death:
		PLSE CDE 2 Bright A_Explode(7,18);
		Stop;
	}
}
class RS_Spear11 : Actor
{
	Default
	{
		Radius 6; Height 16; Speed 42; FastSpeed 68;
		Damage 47; DamageType "Plasma";
		Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85;
		SeeSound "baron/attack"; DeathSound "Litn/litn3";
		Translation "112:127=250:254", "0:0=250:254", "112:113=224:224", "192:193=224:224", "192:207=250:254";
	}
	States
	{
	Spawn:
		SPER AB 1 Bright A_SpawnItemEx("RS_TrailB",0,0,2);
		Loop;
	Death:
		PLSE CDE 3 Bright A_SpawnItemEx("RS_Zap88", 0,0,2,0,0,0,0, SXF_NOCHECKPOSITION);
		Stop;
	}
}

// ---------- YELLOW: BaronFbomb -> BaronStar3 + BaronRing + BaronStar/Star2 + Firehand1 ----------
class RS_BaronRing : Actor
{
	Default
	{
		Radius 6; Height 8; Speed 1; Mass 25; Gravity 0.7;
		Projectile; +THRUACTORS; -NOGRAVITY; +RANDOMIZE; RenderStyle "Add";
		SeeSound "Fire/fire3"; Alpha 0.75; Scale 1;
	}
	States { Spawn: RNGG ABCD 2 Bright; Loop; Death: RNGG ABCD 4 Bright; Stop; }
}
class RS_BaronStar : Actor
{
	Default
	{
		Radius 5; Height 7; Speed 28; FastSpeed 38;
		Damage 15; DamageType "Fire"; Species "BaronOfHell";
		Projectile; +RANDOMIZE; +DONTHARMCLASS; +SEEKERMISSILE; RenderStyle "Add"; Alpha 1; Scale 1.3;
		SeeSound "caco/attack"; DeathSound "spell/Impact1";
	}
	States
	{
	Spawn:
		STRS AB 2 Bright A_SeekerMissile(3,3);
		STRS CD 2 Bright A_Weave(4,1,6,0);
		Loop;
	Death:
		BBOM A 2 Bright A_SetScale(1);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(15,108);
		BBOM EFG 6 Bright A_Explode(17,108);
		Stop;
	}
}
class RS_BaronStar2 : Actor
{
	Default
	{
		Radius 5; Height 7; Speed 28; FastSpeed 38;
		Damage 15; DamageType "Fire"; Species "BaronOfHell";
		Projectile; +RANDOMIZE; +SEEKERMISSILE; +DONTHARMCLASS; RenderStyle "Add"; Alpha 1; Scale 1.3;
		SeeSound "caco/attack"; DeathSound "spell/Impact1";
	}
	States
	{
	Spawn:
		STRS AB 2 Bright A_SeekerMissile(5,5);
		STRS CD 2 Bright A_Weave(-4,-1,-6,0);
		Loop;
	Death:
		BBOM A 2 Bright A_SetScale(1);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(17,108);
		BBOM EFG 6 Bright A_Explode(17,108);
		Stop;
	}
}
// [dedupe] older duplicate of RS_Firehand1 removed -- ZScript is case-insensitive,
// so the CHP-sourced definition later in this file serves every caller.
// [dedupe] older duplicate of RS_BaronFbomb removed -- ZScript is case-insensitive,
// so the CHP-sourced definition later in this file serves every caller.

// ---------- FIREBLU: RedBBall/BluBBall (shared w/ imp) + BluPowerBomb + RedPower/Bomb ----------
class RS_BluPowerBomb : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 10;
		Damage 40; DamageType "Plasma";
		Projectile; +SEEKERMISSILE; +EXTREMEDEATH; +BOUNCEONWALLS;
		BounceType "Hexen"; BounceCount 4; BounceFactor 1.25; WallBounceFactor 1.25;
		RenderStyle "Add"; Alpha 1.0; Scale 0.55;
		SeeSound "Litn/litn3"; DeathSound "weapons/bfgx";
		Translation "112:127=192:207";
	}
	States
	{
	Spawn:
		ZPWV ABCBCABCACBABCA 1 Bright A_SeekerMissile(12,18);
		Loop;
	Death:
		TNT1 A 0 A_SetScale(1.25,0.8);
		BFE1 AB 8 Bright;
		BFE1 C 8 Bright A_Explode(60,158);
		BFE1 DEF 8 Bright;
		Stop;
	}
}
class RS_ArchonSoul : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 3; Species "BaronOfHell";
		Projectile; +DONTHARMCLASS; +DONTHARMSPECIES; RenderStyle "Add"; Alpha 0.80; DamageType "Plasma";
		Translation "112:127=176:191";
		SeeSound "skull/melee";
	}
	States { Spawn: BFX1 ABCD 6 Bright A_Explode(8,32); Stop; }
}
class RS_RedPower : Actor
{
	Default
	{
		Radius 1; Height 1; Species "BaronOfHell";
		+DONTHARMCLASS; +DONTHARMSPECIES; +NOCLIP; +NOGRAVITY; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.75;
	}
	States
	{
	Spawn:
		RED8 ABCDEEFG 8 Bright A_SpawnItemEx("RS_ArchonSoul", random(-128,128), random(-128,218), random(5,45), 0,0,0,0);
		RED8 H 4 A_SetTranslucent(0.3);
		Stop;
	}
}
class RS_RedPowerBomb : Actor
{
	Default
	{
		Radius 6; Height 8; Speed 21;
		Damage 40; DamageType "Melee";
		Projectile; +NOGRAVITY; +SEEKERMISSILE; +DONTHARMCLASS; +DONTHARMSPECIES; Species "BaronOfHell";
		RenderStyle "Add"; Alpha 0.75;
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4";
	}
	States
	{
	Spawn:
		RED9 B 1 Bright A_SeekerMissile(2,2);
		RED9 AA 3 Bright A_SpawnItemEx("RS_RedRevLoad2",0,0,0,0,0,0,0,128);
		Loop;
	Death:
		SPIR A 1 Bright A_SetScale(2);
		SPIR ABCDEDCBA 5 Bright;
		SPIR E 1;
		Stop;
	}
}

// ---------- GRAY: BaronOfDirtCH/2/3 (dirt-monster artillery) -> Drt1/2/3 + WDRock1/3 + ZombieRock ----------
class RS_Drt1 : Actor
{
	Default { Radius 2; Damage 0; Speed 5; Projectile; -NOGRAVITY; -NOBLOCKMAP; -NOTELEPORT; +RANDOMIZE; }
	States
	{
	Spawn:
		DIRT A 0 A_SetGravity(0.5);
		DIRT A 0 ThrustThingZ(0,15,0,1);
		Goto See;
	See:
		DIRT ABC 5;
		Loop;
	Death:
		DIRT JKL 3;
		Stop;
	}
}
class RS_Drt2 : Actor
{
	Default { Radius 2; Damage 0; Speed 5; Projectile; -NOGRAVITY; -NOBLOCKMAP; -NOTELEPORT; +RANDOMIZE; }
	States
	{
	Spawn:
		DIRT A 0 A_SetGravity(0.5);
		DIRT A 0 ThrustThingZ(0,15,0,1);
		Goto See;
	See:
		DIRT DEF 5;
		Loop;
	Death:
		DIRT JKL 3;
		Stop;
	}
}
class RS_Drt3 : Actor
{
	Default { Radius 2; Damage 0; Speed 5; Projectile; -NOGRAVITY; -NOBLOCKMAP; -NOTELEPORT; +RANDOMIZE; }
	States
	{
	Spawn:
		DIRT A 0 A_SetGravity(0.5);
		DIRT A 0 ThrustThingZ(0,15,0,1);
		Goto See;
	See:
		DIRT GHI 5;
		Loop;
	Death:
		DIRT JKL 3;
		Stop;
	}
}
class RS_WDRock3 : Actor
{
	Default
	{
		Radius 9; Height 9; Speed 36;
		Damage 40; DamageType "Melee";
		Projectile; Scale 0.7;
		SeeSound "monster/hamflr"; DeathSound "Butcher/melee";
	}
	States
	{
	Spawn:
		JUBD ABCD 3 Bright;
		Loop;
	Death:
		JUBD DDDD 0 A_SpawnItemEx("RS_Drt2", random(-2,2),random(-2,2),random(-2,2), 1,0,1, random(0,360),128);
		JUBD DDDD 1 Bright A_SpawnItemEx("RS_Drt3", random(-2,2),random(-2,2),random(-2,2), 1,0,1, random(0,360),128);
		Stop;
	}
}
class RS_ZombieRock : RS_WDRock3
{
	Default { Damage 6; Scale 0.25; }
}
class RS_WDRock1 : Actor
{
	Default { Radius 8; Height 8; Speed 5; FloatSpeed 6; +FLOAT; +NOGRAVITY; +NOCLIP; Scale 1.2; }
	States
	{
	Spawn:
		JUBD A 0;
		Goto Fly;
	Fly:
		JUBD A 0 ThrustThingZ(0,8,0,0);
		JUBD A 6 Bright A_PlaySound("moloch/step",7,2,false,ATTN_NONE);
		Goto Death;
	Death:
		JUBD A 3 Bright A_SpawnItemEx("RS_Drt1", random(-2,2),random(-2,2),0, 2,0,3, random(0,360),128);
		JUBD A 3 Bright A_SpawnItemEx("RS_Drt2", random(-2,2),random(-2,2),0, 1,0,3, random(0,360),128);
		JUBD A 11 Bright A_SpawnItemEx("RS_Drt3", random(-1,2),random(-2,2),0, 3,0,3, random(0,360),128);
		Stop;
	}
}
class RS_BaronOfDirtCH : Actor
{
	Default { Radius 8; Height 8; Speed 2; FloatSpeed 1; +FLOAT; +NOGRAVITY; +NOCLIP; Scale 1.5; }
	States
	{
	Spawn:
		JUBD A 0;
		Goto Fly;
	Fly:
		JUBD A 0 ThrustThingZ(0,1,1,0);
		JUBD A 1 Bright A_SpawnItemEx("RS_Drt1", random(-2,2),random(-2,2),0, 2,0,3, random(0,360),128);
		JUBD A 1 Bright A_SpawnItemEx("RS_Drt2", random(-2,2),random(-2,2),0, 1,0,3, random(0,360),128);
		JUBD A 1 Bright A_SpawnItemEx("RS_Drt3", random(-1,2),random(-2,2),0, 3,0,3, random(0,360),128);
		JUBD A 6 Bright A_PlaySound("moloch/step",7);
		Goto Death;
	Death:
		JUBD AA 2 Bright A_SpawnItemEx("RS_Drt1", random(-2,2),random(-2,2),0, 2,0,3, random(0,360),128);
		JUBD AA 2 Bright A_SpawnItemEx("RS_Drt2", random(-2,2),random(-2,2),0, 1,0,3, random(0,360),128);
		JUBD A 8 Bright;
		Stop;
	}
}
class RS_BaronOfDirtCH2 : Actor
{
	Default
	{
		Radius 16; Height 16; Speed 16; Gravity 0.10;
		Damage 120; DamageType "Melee";
		Projectile; -NOGRAVITY; +SEEKERMISSILE; BounceType "Hexen"; BounceCount 6; BounceFactor 1.15; Scale 1.75;
		SeeSound "monster/hamflr"; DeathSound "moloch/thud";
	}
	States
	{
	Spawn:
	Fly:
		JUBD AAB 2 Bright A_SpawnItemEx("RS_ZombieRock", random(-2,2),random(-2,2),random(-2,2), random(8,18),0,random(-2,9), random(100,220), SXF_NOCHECKPOSITION);
		JUBD B 3 Bright A_SeekerMissile(3,6);
		JUBD CCD 2 Bright A_SpawnItemEx("RS_ZombieRock", random(-2,2),random(-2,2),random(-2,2), random(8,18),0,random(-2,9), random(120,240), SXF_NOCHECKPOSITION);
		JUBD D 3 Bright A_SeekerMissile(6,3);
		Loop;
	Bounce.Floor:
		TNT1 A 0 ThrustThingZ(0,18,0,1);
		Goto Fly;
	Bounce.Wall:
		Goto Death;
	Death:
		JUBD DDDDD 0 A_SpawnItemEx("RS_Drt1", random(-24,24),random(-24,24),random(-2,2), 1,0,1, random(0,360),128);
		JUBD DDDDD 0 A_SpawnItemEx("RS_Drt2", random(-24,24),random(-24,24),random(-2,2), 1,0,1, random(0,360),128);
		JUBD DDDDD 0 A_SpawnItemEx("RS_Drt3", random(-24,24),random(-24,24),random(-2,2), 1,0,1, random(0,360),128);
		JUBD D 1 Bright;
		Stop;
	}
}
class RS_BaronOfDirtCH3 : Actor
{
	Default
	{
		Radius 16; Height 16; Speed 20;
		Damage 115; DamageType "Melee";
		Projectile; -NOGRAVITY; +BOUNCEONFLOORS; BounceType "Hexen"; BounceCount 10; BounceFactor 0.95; Gravity 0.8; Scale 1.2;
		SeeSound "monster/hamflr"; DeathSound "moloch/thud";
	}
	States
	{
	Spawn:
		JUBD ABCD 1 Bright A_SpawnItemEx("RS_Drt1", random(-2,2),random(-2,2),random(-3,3), 1,0,1, random(0,360),128);
		JUBD A 0 A_PlaySound("Ice/Fly");
		Loop;
	Death:
		JUBD DDDD 0 A_SpawnItemEx("RS_Drt1", random(-2,2),random(-2,2),random(-2,2), 1,0,1, random(0,360),128);
		JUBD DDDD 0 A_SpawnItemEx("RS_Drt2", random(-2,2),random(-2,2),random(-2,2), 1,0,1, random(0,360),128);
		JUBD DDDD 0 A_SpawnItemEx("RS_Drt3", random(-2,2),random(-2,2),random(-2,2), 1,0,1, random(0,360),128);
		JUBD D 1 Bright;
		Stop;
	}
}
class RS_WDRock1Alias : Actor { Default { +NOINTERACTION; } States { Spawn: TNT1 A 1; Stop; } }

// ============================================================================
// BARON PASS 2 -- BROWN + CYAN projectiles (ripped faithfully).
// ============================================================================

// ---------- BROWN: flame/rock/spiral + slam (STYR warlord-baron) ----------
// (RS_Drt2 / RS_Drt3 dirt-debris already defined above in Gray's section -- shared.)
class RS_BrownBaronFlame : Actor
{
	Default { Radius 2; Height 2; Speed 0; +NOINTERACTION; RenderStyle "Add"; Alpha 0.9; Scale 0.75;
		Translation "0:255=%[0.28,0.16,0.12]:[1.69,1.17,0.83]"; }
	States
	{
	Spawn:
		FLUM ABCDE 6 Bright;
		Goto Death;
	Death:
		MISL BCD 6 Bright A_SetScale(0.4,0.4);
		Stop;
	}
}
class RS_BrownBaronFlame2 : Actor
{
	Default { Radius 2; Height 2; Speed 0; RenderStyle "Add"; Alpha 0.9; Damage 12; Projectile; Scale 0.6;
		Translation "0:255=%[0.28,0.16,0.12]:[1.69,1.17,0.83]"; }
	States
	{
	Spawn:
		FLUM ABCDE 6 Bright;
		Goto Death;
	Death:
		TNT1 A 0 A_SetScale(0.75,0.75);
		MISL BCD 3 Bright A_Explode(6,64,0);
		Stop;
	}
}
class RS_BaronBrownRock : Actor
{
	Default
	{
		Radius 7; Height 7; Speed 28;
		Damage 25; DamageType "Melee";
		Projectile; +SEEKERMISSILE; Scale 0.5;
		SeeSound "monster/hamflr"; DeathSound "Butcher/melee";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		JUBD AB 3 Bright A_SpawnItemEx("RS_BrownBaronFlame2",1,0,0,1,0,0,0,0,128);
		JUBD B 1 Bright A_SeekerMissile(9,6);
		JUBD CD 3 Bright A_SpawnItemEx("RS_BrownBaronFlame2",1,0,0,1,0,0,0,0,128);
		JUBD D 1 Bright A_SeekerMissile(9,6);
		Loop;
	Death:
		JUBD DDDD 0 A_SpawnItemEx("RS_Drt2",random(-2,2),random(-2,2),random(-2,2),1,0,1,random(0,360),128);
		JUBD DDDDDD 0 A_SpawnItemEx("RS_BrownBaronFlame2",random(-2,2),random(-2,2),random(-2,2),3,0,1,random(0,120));
		JUBD DDDDDD 0 A_SpawnItemEx("RS_BrownBaronFlame2",random(-2,2),random(-2,2),random(-2,2),3,0,1,random(120,240));
		JUBD DDDDDD 0 A_SpawnItemEx("RS_BrownBaronFlame2",random(-2,2),random(-2,2),random(-2,2),3,0,1,random(240,360));
		TNT1 A 0 A_Explode(25,64,0);
		JUBD DDDD 1 Bright A_SpawnItemEx("RS_Drt3",random(-2,2),random(-2,2),random(-2,2),1,0,1,random(0,360),128);
		Stop;
	}
}
class RS_BBaronCmonAndSlam : Actor
{
	Default { Radius 3; Height 3; Speed 1; Mass 250; Projectile; +FLOORHUGGER; +THRUACTORS;
		RenderStyle "Add"; Alpha 0.75; YScale 0.5; XScale 0.85;
		Translation "0:255=%[0.54,0.57,0.84]:[2.00,2.00,2.00]"; }
	States
	{
	Spawn:
		RED8 ABC 2 Bright;
		Goto Startle;
	Startle:
		TNT1 A 0 A_SetScale(0.9,0.8);
		RED8 FGH 2 Bright;
		TNT1 A 0 A_SetScale(1.1,1.25);
		RED8 ABC 2 Bright;
		TNT1 A 0 A_SetScale(1.3,1.75);
		RED8 FGH 2 Bright;
		Goto Death;
	Death:
		RED8 ABCD 4 Bright A_FadeOut(0.25);
		Stop;
	}
}
// simplified reflector (CH's slow-aura used ACS; RS keeps the brief reflect shield)
class RS_ReflectorBBaron : Actor
{
	Default { Radius 32; Height 56; Speed 0; Health 999; Monster;
		+NOTRIGGER; +NOTARGET; +DONTTHRUST; +NOGRAVITY; +INVULNERABLE; +MTHRUSPECIES;
		+REFLECTIVE; +SHIELDREFLECT; +THRUSPECIES; -COUNTKILL; RenderStyle "Add"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 20;
		Goto Death;
	Death:
		TNT1 A 1 Bright A_NoBlocking;
		TNT1 A 0 A_Die;
		Stop;
	}
}
class RS_BrownBaronSpiral : Actor
{
	Default { Radius 2; Height 2; Speed 4; Projectile; +DONTREFLECT; RenderStyle "Add"; Scale 0.6;
		Translation "0:255=%[0.28,0.16,0.12]:[1.69,1.17,0.83]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		B5P1 ABCD 2 Bright;
		TNT1 A 0 A_SetScale(0.8,0.8);
		B5P1 ABCD 4 Bright;
		TNT1 A 0 A_SetScale(0.9,0.9);
		TNT1 A 0 A_Explode(15,64,0);
		B5P1 ABCD 6 Bright;
		TNT1 A 0 A_SetScale(1.2,1.2);
		TNT1 A 0 A_Explode(15,94,0);
		B5P1 ABCD 8 Bright;
		TNT1 A 0 A_Explode(15,128,0);
		Goto Death;
	Death:
		TNT1 A 0 A_SpawnItemEx("RS_ReflectorBBaron",-16,0,0);
		B5P1 ABCD 2 Bright;
		B5P1 ABCD 2 Bright A_SetScale(0.5,0.5);
		B5P1 ABCD 2 Bright A_SetScale(0.3,0.3);
		Stop;
	}
}
// [dedupe] duplicate class RS_BrownVileGas removed -- defined earlier in the load order.

// ---------- CYAN: ice bombs/stars/seekers + frost wings (LOHS ice-baron) ----------
class RS_IceSeekerTrailBaron : Actor
{
	Default { Radius 5; Height 5; Projectile; +NOCLIP; RenderStyle "Add"; Alpha 0.5; Scale 0.45;
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ICEY AB 2 Bright;
	Death:
		ICEY A 1 Bright;
		Stop;
	}
}
class RS_FrostWingBaron : Actor
{
	Default { Radius 2; Height 2; Speed 1; Projectile; +NOINTERACTION; +THRUACTORS;
		RenderStyle "Add"; Alpha 0.65; Scale 0.55; }
	States
	{
	Spawn:
		KIRC ABCD 2 Bright;
		KIRC ABCD 1 Bright;
	Death:
		TNT1 A 0 A_SetScale(0.35,0.35);
		KIRC ABCD 1 Bright;
		TNT1 A 0 A_SetScale(0.15,0.15);
		KIRC ABCD 1 Bright;
		Stop;
	}
}
class RS_BaronCyanBombTrail : Actor
{
	Default { Radius 1; Height 1; Speed 1; Projectile; +NOCLIP; +NOGRAVITY; RenderStyle "Add"; Alpha 0.25;
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		SPIR EDCBA 3 Bright;
		Stop;
	}
}
class RS_BaronCyanBomb : Actor
{
	Default
	{
		Radius 5; Height 5; Speed 38;
		Damage 60; DamageType "Ice";
		Projectile; +NOGRAVITY; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.95; Scale 0.5;
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4";
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		RED9 B 1 Bright A_SeekerMissile(6,4);
		RED9 AA 1 Bright A_SpawnItemEx("RS_BaronCyanBombTrail",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		RED9 A 0 A_Explode(7,32,0);
		Loop;
	Death:
		SPIR A 1 Bright A_SetScale(2.0,2.0);
		SPIR ABCDEDCBA 5 Bright A_Explode(9,128,0);
		SPIR E 1;
		Stop;
	}
}
class RS_BaronStarCyan : Actor
{
	Default
	{
		Radius 5; Height 5; Speed 38;
		Damage 15; DamageType "Ice";
		Projectile; RenderStyle "Add"; Alpha 1; Scale 1.1;
		SeeSound "caco/attack"; DeathSound "spell/Impact1";
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 A_Jump(168,"A1","A3");
		STRS AB 2 Bright;
		STRS CD 2 Bright A_Weave(4,1,6,0);
		Loop;
	A1:
		STRS AB 2 Bright;
		STRS CD 2 Bright ThrustThing(random(0,255),random(1,12),0,0);
		Loop;
	A3:
		STRS ABCD 2 Bright;
		Loop;
	Death:
		BBOM A 2 Bright A_SetScale(1.0,1.0);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright;
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(12,40),0,random(5,25),random(0,90));
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(12,40),0,random(5,25),random(89,180));
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(12,40),0,random(5,25),random(181,270));
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SpikeCyanRev",0,0,1,random(12,40),0,random(5,25),random(271,359));
		BBOM EFG 3 Bright;
		Stop;
	}
}
class RS_IceSeekerBaron : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 26;
		Damage 15; DamageType "Ice";
		Projectile; +SEEKERMISSILE; RenderStyle "Add"; Scale 0.45; Alpha 0.5;
		SeeSound "ice/Cast"; DeathSound "Ice/Hit2";
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ICEY A 2 Bright A_SpawnItemEx("RS_IceSeekerTrailBaron",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		ICEY B 2 Bright A_SeekerMissile(frandom(3,12),frandom(3,12),SMF_PRECISE);
		Loop;
	Death:
		ICEY ABC 1 Bright;
		ICEY A 1 Bright A_Stop;
		ICEY BCABC 1 Bright;
		ICEY F 3 Bright A_Explode(30,64);
		ICEY GHI 2 Bright;
		Stop;
	}
}

// ============================================================================
// BARON PASS 2 -- ABYSS / BLACK / WHITE (the three heavy colors). Full recursive
// rip; cosmetic AbyssShotIdentifier markers dropped. Drt1/2/3,
// SplashAbyss/2, SpiralSaw5 reused from earlier. The deepest sub-actor webs in RS.
// (All flagged for the efficiency pass -- these are the heaviest spawners.)
// ============================================================================

// ---------- shared small fx ----------
// (RS_Zap88 already defined above in Purple's section -- reused by Abyss.)
class RS_AbyssCacoZap2 : Actor
{
	Default { Radius 2; Height 2; Speed 2; Species "Caco"; Damage 3; DamageType "Plasma";
		Projectile; +DONTHURTSPECIES; +DONTHARMCLASS; +THRUSPECIES; RenderStyle "Add"; Alpha 1.0; Translation "Ice"; }
	States
	{
	Spawn:
	Death:
		LITN ABCDEFGOP 2 Bright A_Explode(2,64,0);
		Stop;
	}
}
class RS_SpiralSawAby : Actor
{
	Default { Radius 1; Height 1; Speed 1; Projectile; +NOCLIP; +NOGRAVITY; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.55; XScale 1.26; YScale 0.75;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States { Spawn: SPIR EDCBA 3 Bright A_Explode(6,88); Stop; }
}
class RS_GroundRedBar : Actor
{
	Default { Radius 6; Height 8; Speed 1; Mass 25; Projectile; +FLOORHUGGER; +THRUACTORS; +RANDOMIZE; +BOUNCEONWALLS;
		BounceCount 999; BounceType "Doom"; DamageType "Fire"; BounceFactor 1; WallBounceFactor 1.5;
		RenderStyle "Add"; SeeSound "Fire/fire3"; Alpha 0.95; YScale 0.3; XScale 0.95;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States { Spawn: RED8 ABCFGH 3 Bright A_Explode(6,128); RED8 D 1 Bright; Stop; }
}

// ---------- ABYSS: defile / flare / lightning / hand-fire / souls ----------
class RS_SplashAbyssBubbleDemon : Actor
{
	Default { Radius 16; Height 4; Speed 3; Projectile; +THRUACTORS; +FLOORHUGGER; YScale 0.12; XScale 1.45;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ICEY G 3 Bright;
		TNT1 AAA 0 A_SpawnItemEx("RS_SplashAbyss2",random(-128,128),random(-124,124),random(6,16),0,0,2,0,SXF_NOCHECKPOSITION);
		ICEY H 3 Bright;
		ICEY I 3 Bright;
		TNT1 A 0 A_Jump(24,"Death");
		Loop;
	Death:
		ICEY GHI 2 Bright;
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_SplashAbyss2",random(-24,24),random(-128,128),random(6,16),0,0,2,0,SXF_NOCHECKPOSITION);
		Stop;
	}
}
class RS_AbyssBaronDefile : Actor
{
	Default { Radius 6; Height 8; Speed 3; Projectile; +FLOORHUGGER; +THRUACTORS; +FLATSPRITE;
		SeeSound "Fire/fire3"; Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		B5P1 ABCDABCDABCD 3 Bright;
	Fly:
		TNT1 A 0 A_SetScale(1.25,0.75);
		TNT1 AAA 0 A_SpawnItemEx("RS_SplashAbyssBubbleDemon",random(-128,128),random(-128,128),random(5,32),0,0,0,0,SXF_NOCHECKPOSITION,216);
		B5P1 ABCDABCDABCD 3 Bright A_Explode(12,64);
		TNT1 A 0 A_SetScale(1.75,0.75);
		B5P1 ABCDABCDABCD 3 Bright A_Explode(15,128);
		TNT1 A 0 A_SetScale(2.4,0.75);
		B5P1 ABCDABCDABCD 3 Bright A_Explode(18,232);
		Stop;
	}
}
class RS_AbyssBaronHandFire : Actor
{
	Default { Radius 4; Height 3; Speed 1; Projectile; +NOINTERACTION; +NOCLIP; RenderStyle "Add"; Alpha 1.0; XScale 0.75; YScale 1.54;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States { Spawn: FRFX ABCD 2 Bright; Goto Death; Death: FRFX HIJKLMNO 1 Bright; Stop; }
}
class RS_AbyssBaronHandFire2 : Actor
{
	Default { Radius 4; Height 3; Speed 1; Species "BaronOfHell"; Projectile; +DONTHARMCLASS; +DONTHARMSPECIES; DamageType "Ice";
		RenderStyle "Add"; Alpha 1.0; XScale 0.75; YScale 0.75; Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States { Spawn: FRFX ABCD 2 Bright; Goto Death; Death: FRFX HIJKLMNO 1 Bright; Stop; }
}
class RS_AbyssBaronSoul : Actor
{
	Default { Health 30; Radius 24; Height 24; Mass 20; Speed 30; FloatSpeed 30; Species "LSoul"; DamageType "Ice";
		AttackSound "vile/active"; DeathSound "weapons/rocklx"; Scale 0.75; Monster;
		+FLOAT; +NOICEDEATH; +FLOATBOB; +NOTARGETSWITCH; +MISSILEMORE; +NOPAIN; +THRUSPECIES; +MISSILEEVENMORE;
		+NOGRAVITY; +LOOKALLAROUND; +NOBLOOD; +THRUACTORS; -COUNTKILL;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		SSUL AB 2 Bright;
		Goto See;
	See:
		SSUL A 1 Bright A_Chase;
		SSUL B 1 Bright A_SpawnItemEx("RS_AbyssBaronHandFire",0,0,0,0,0,0,0);
		SSUL A 1 Bright A_Chase;
		SSUL B 1 Bright A_SpawnItemEx("RS_AbyssBaronHandFire",0,0,0,0,0,0,0);
		Loop;
	Melee:
		BAL1 A 0;
		Goto Boom;
	Death:
		TNT1 A 0;
		Goto Boom;
	Boom:
		MISL B 0 A_Explode(40,128);
		MISL B 5 Bright A_PlaySound("weapons/rocklx");
		MISL C 5 A_NoBlocking;
		MISL D 5;
		TNT1 A 0 A_Die;
		Stop;
	}
}
class RS_AbyssBaronHandFire3 : Actor
{
	Default { Radius 4; Height 3; Speed 1; Projectile; +NOCLIP; RenderStyle "Add"; Alpha 1.0; XScale 1.25; YScale 1.80;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		FRFX ABCD 8 Bright;
		Goto Death;
	Death:
		FRFX HIJKLMNO 1 Bright;
		TNT1 A 0 A_SpawnItemEx("RS_AbyssBaronSoul",0,0,32,0,0,0,0);
		Stop;
	}
}
class RS_AbyssBaronFlare : Actor
{
	Default { Radius 5; Height 5; Speed 28; Damage 44; DamageType "Plasma"; RenderStyle "Add"; Alpha 0.85; XScale 2.0; YScale 1.25;
		Projectile; +THRUGHOST; +DONTHARMCLASS; SeeSound "weapons/firmfi"; DeathSound "weapons/firex4";
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		VBA3 AB 3 Bright A_SpawnItemEx("RS_AbyssBaronHandFire2",0,0,0,0,0,0,0);
		Loop;
	Death:
		TNT1 A 0 A_SetScale(2.5,1.75);
		CBAL CD 3 Bright;
		TNT1 A 0 A_Explode(50,128);
		CBAL EFG 3 Bright;
		TNT1 A 0 A_SpawnItemEx("RS_AbyssBaronHandFire2",128,0,0,0,0,0,0);
		TNT1 A 0 A_SpawnItemEx("RS_AbyssBaronHandFire2",-128,0,0,0,0,0,0);
		TNT1 A 0 A_SpawnItemEx("RS_AbyssBaronHandFire2",0,128,0,0,0,0,0);
		TNT1 A 0 A_SpawnItemEx("RS_AbyssBaronHandFire2",0,-128,0,0,0,0,0);
		Stop;
	}
}
class RS_AbyssBaronLightning : Actor
{
	Default { Radius 16; Height 6; Speed 76; Damage 70; DamageType "Plasma"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.85; SeeSound "baron/attack"; DeathSound "Litn/litn3";
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		SPER A 1 Bright A_SpawnItemEx("RS_AbyssCacoZap2",0,0,-1);
		SPER B 1 Bright A_SpawnItemEx("RS_AbyssCacoZap2",0,0,1);
		Loop;
	Death:
		PLSE CDE 2 Bright;
		TNT1 A 0 A_Explode(60,128);
		TNT1 AAAAAAAA 0 A_SpawnItemEx("RS_AbyssCacoZap2",random(-128,128),random(-128,128),random(-6,12),random(10,30),0,0,random(-359,359),SXF_NOCHECKPOSITION);
		Stop;
	}
}
class RS_AbyssBaronSoulCharge : Actor
{
	Default { Radius 16; Height 8; Speed 17; Projectile; +NOGRAVITY; +SEEKERMISSILE; RenderStyle "Add"; Damage 50; DamageType "Melee";
		Alpha 0.75; SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4"; Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ETHS E 1 Bright A_SeekerMissile(3,3);
		ETHS FF 1 Bright A_SpawnItemEx("RS_SpiralSawAby",0,0,3,0,0,0,0,128);
		RED9 A 0 A_CustomMissile("RS_GroundRedBar",0,0);
		Loop;
	Death:
		SPIR A 1 Bright A_SetScale(2);
		SPIR ABCDEDCBAE 5 Bright A_Explode(11,128);
		Stop;
	}
}

// ---------- BLACK: Deep-One -- tentacle summoners + railgun beam ----------
class RS_TentacleBall1 : Actor
{
	Default { Radius 4; Height 4; Speed 25; Damage 35; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.75;
		SeeSound "monster/tenatk"; DeathSound "weapons/plasmax"; Projectile; +RANDOMIZE; }
	States { Spawn: OLDP AB 3 Bright; Loop; Death: OLDP CDEF 4 Bright; Stop; }
}
class RS_TentacleBall2 : RS_TentacleBall1
{
	Default { Speed 10; Damage 5; SeeSound "imp/attack"; DeathSound "imp/shotx"; }
	States { Spawn: OLDP FEDC 3 Bright; Loop; Death: OLDP BA 4 Bright; Stop; }
}
class RS_DeepCharge1 : Actor
{
	Default { Radius 13; Height 8; Speed 1; Projectile; RenderStyle "Add"; Alpha 0.95; SeeSound "deepone/fire"; }
	States
	{
	Spawn:
		OLDP A 3 Bright A_SetScale(1.5,1.5);
		OLDP B 3 Bright A_SetScale(1.1,1.1);
		OLDP C 3 Bright A_SetScale(0.9,0.9);
		OLDP D 3 Bright A_SetScale(0.5,0.5);
		OLDP E 3 Bright A_SetScale(0.3,0.8);
		OLDP F 3 Bright A_SetScale(0.3,2);
		Stop;
	}
}
class RS_DeepOneBall : Actor
{
	Default { Radius 13; Height 8; Speed 25; Damage 50; Projectile; +RANDOMIZE; +ROCKETTRAIL; +SEEKERMISSILE;
		RenderStyle "Add"; DamageType "Plasma"; Alpha 0.75; SeeSound "deepone/fire"; DeathSound "deepone/firehit"; }
	States
	{
	Spawn:
		OLDP A 0 A_Tracer;
		OLDP A 2 Bright A_BishopMissileWeave;
		OLDP B 0 A_Tracer;
		OLDP B 2 Bright A_BishopMissileWeave;
		Loop;
	Death:
		OLDP C 0 A_Scream;
		OLDP CDEF 4 Bright;
		Stop;
	}
}
// summoned monster tentacles (self-contained CH bodies, simplified drops)
class RS_DeepTentacle : Actor
{
	Default { Health 500; Radius 40; Height 112; Scale 0.75; Mass 0x7FFFFFFF; Species "BaronOfHell"; PainChance 96;
		SeeSound "monster/tensit"; PainSound "monster/tenpai"; DeathSound "monster/tendth"; ActiveSound "monster/tenact";
		Monster; +FLOORCLIP; +DONTHURTSPECIES; +LOOKALLAROUND; +THRUSPECIES; +NOTARGET; +MISSILEEVENMORE; -NORADIUSDMG;
		Translation "231:231=112:112","16:31=98:109","32:42=105:111"; }
	States
	{
	Spawn:
		TNT1 A 10 A_Look;
		Loop;
	See:
		TEN1 ABCD 4;
	SeeLoop:
		TEN1 EFGH 4 A_Chase;
		Loop;
	Missile:
		TEN1 F 5 A_FaceTarget;
		TNT1 A 0 A_Jump(96,"Missile2");
	Missile1:
		TEN1 I 8 A_FaceTarget;
		TEN1 J 9 Bright A_CustomMissile("RS_TentacleBall1",100);
		TEN1 I 8 A_FaceTarget;
		TEN1 J 9 Bright A_CustomMissile("RS_TentacleBall1",100);
		TEN1 I 8;
		Goto SeeLoop;
	Missile2:
		TEN1 I 8 A_FaceTarget;
		TNT1 A 0 A_CustomMissile("RS_TentacleBall2",10);
		TNT1 A 0 A_CustomMissile("RS_TentacleBall2",30);
		TNT1 A 0 A_CustomMissile("RS_TentacleBall2",50);
		TNT1 A 0 A_CustomMissile("RS_TentacleBall2",70);
		TEN1 K 9 Bright A_CustomMissile("RS_TentacleBall2",90);
		Goto SeeLoop;
	Pain:
		TEN1 L 3;
		TEN1 L 3 A_Pain;
		Goto SeeLoop;
	Death:
		TEN1 M 4;
		TEN1 N 4 A_Scream;
		TEN1 O 4 A_NoBlocking;
		TEN1 PQRS 4;
		TEN1 T -1;
		Stop;
	}
}
class RS_RoseTentacle : Actor
{
	Default { Height 64; Radius 20; Speed 22; Health 50; Mass 5000; MeleeDamage 3; Species "BaronOfHell"; MeleeRange 52;
		BloodColor "0 50 0"; PainChance 128; Monster; -SHOOTABLE; -SOLID; -COUNTKILL; +NOTARGETSWITCH; +THRUSPECIES;
		+NOICEDEATH; +FLOORCLIP; +LOOKALLAROUND;
		Translation "64:79=112:127","144:151=118:127","40:47=121:127"; }
	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_UnsetShootable;
		TNT1 A 0 A_UnsetSolid;
		ROSX RST 4 A_Look;
		Loop;
	See:
		ROSX RS 3 A_Chase;
		ROSX TR 3 A_Chase;
		ROSX ST 3 A_Chase;
		ROSX RS 3 A_Chase;
		Goto Melee;
	Melee:
		TNT1 A 0 A_SetShootable;
		TNT1 A 0 A_SetSolid;
		ROSX RQ 4;
		ROSX P 4 A_MeleeAttack;
		ROSX ONMLABC 4;
		ROSX D 3 A_MeleeAttack;
		Goto See;
	Pain:
		ROSX LMNOPQR 3;
		TNT1 A 0 A_UnSetSolid;
		TNT1 A 0 A_UnSetShootable;
		Goto See;
	Death:
		ROSX U 5;
		ROSX V 5 A_Scream;
		ROSX W 5 A_Fall;
		ROSX XR 5;
		ROSX RRRRRRRRR 2 A_FadeOut(0.1);
		Stop;
	}
}

// ---------- WHITE: slices / homing slices / stars / ground-spikes ----------
class RS_WhiteBaronSliceTrail : Actor
{
	Default { Radius 5; Height 5; Projectile; +NOCLIP; RenderStyle "Add"; Alpha 0.9; XScale 0.9; YScale 1.1; }
	States { Spawn: TNT1 A 0; Fly: VBA3 AB 1 Bright; Death: VBA3 B 1 Bright; Stop; }
}
class RS_WhiteBaronSlice : Actor
{
	Default { Radius 5; Height 5; Speed 38; Projectile; +NOGRAVITY; RenderStyle "Add"; Damage 27; DamageType "Fire";
		Alpha 0.95; XScale 0.9; YScale 1.1; SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BRB2 AB 1 Bright A_SpawnItemEx("RS_WhiteBaronSliceTrail",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		BRB2 A 0 A_Explode(7,16,0);
		Loop;
	Death:
		BRB2 CDEFGHI 5 Bright;
		Stop;
	}
}
class RS_WhiteBaronSliceHoming : Actor
{
	Default { Radius 5; Height 5; Speed 15; Projectile; +NOGRAVITY; +SEEKERMISSILE; RenderStyle "Add"; Damage 15; DamageType "Fire";
		Alpha 0.95; XScale 0.9; YScale 1.1; SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BRB2 B 1 Bright A_SpawnItemEx("RS_WhiteBaronSliceTrail",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		BRB2 A 1 Bright A_SeekerMissile(12,12);
		BRB2 A 0 A_Explode(7,16,0);
		Loop;
	Death:
		BRB2 CDEFGHI 5 Bright;
		Stop;
	}
}
class RS_WhiteBaronStar : Actor
{
	Default { Radius 5; Height 7; Speed 33; Damage 15; DamageType "Fire"; Species "BaronOfHell"; Projectile;
		+RANDOMIZE; +DONTHARMCLASS; +SEEKERMISSILE; RenderStyle "Add"; Alpha 1; Scale 1.3;
		SeeSound "caco/attack"; DeathSound "spell/Impact1"; }
	States
	{
	Spawn:
		TNT1 A 0 A_Jump(128,"Two");
	One:
		STRS AB 2 Bright A_SeekerMissile(3,3);
		STRS CD 2 Bright A_Weave(4,1,6,0);
		Loop;
	Two:
		STRS AB 2 Bright A_SeekerMissile(3,3);
		STRS CD 2 Bright A_Weave(-4,-1,-6,0);
		Loop;
	Death:
		BBOM A 2 Bright A_SetScale(0.65);
		BBOM B 2 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(15,64);
		BBOM EFG 6 Bright A_Explode(17,64);
		Stop;
	}
}
class RS_VileGroundSpikeBrown2 : Actor
{
	Default { Speed 1; Damage 5; DamageType "Melee"; Projectile; +FLOORHUGGER; +THRUACTORS; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 1 A_SpawnItemEx("RS_Drt2",0,32,1,random(1,5),0,random(1,5),random(0,360));
		TNT1 A 1 A_SpawnItemEx("RS_Drt3",-32,0,1,random(1,5),0,random(1,5),random(0,360));
		TNT1 A 1 A_SpawnItemEx("RS_Drt1",0,-32,1,random(1,5),0,random(1,5),random(0,360));
		TNT1 A 11 A_SpawnItemEx("RS_Drt3",32,0,1,random(1,5),0,random(1,5),random(0,360));
		SSPK D 8;
		SSPK A 3 A_SetScale(1.0,0.3);
		TNT1 A 0 A_Explode(80,32,0);
		SSPK A 3 A_SetScale(1.0,1.0);
		TNT1 A 0 A_Explode(80,32,0);
		SSPK A 8 A_ChangeFlag("THRUACTORS",false);
		Goto Death;
	Death:
		SSPK A 8 A_SetSolid;
		SSPK A 16;
		SSPK AAA 8 A_FadeOut(0.33);
		Stop;
	}
}
class RS_VileGroundSpikeBrown : RS_VileGroundSpikeBrown2 {}
class RS_WhiteBaronGround : Actor
{
	Default { Radius 2; Height 2; Speed 25; Alpha 0.67; Projectile; +THRUACTORS; +THRUGHOST; +DONTBLAST; +MTHRUSPECIES;
		-NOGRAVITY; +USEBOUNCESTATE; +SEEKERMISSILE; BounceType "Doom"; BounceCount 99; BounceFactor 1.0; WallBounceFactor 1.0;
		XScale 0.75; YScale 0.75; Gravity 5.0; }
	States
	{
	Spawn:
		TNT1 A 1;
	Fly:
		TNT1 A 1 Bright A_CStaffMissileSlither;
		TNT1 A 0 A_SpawnItemEx("RS_VileGroundSpikeBrown2",0,0,0);
		TNT1 A 1 Bright A_CStaffMissileSlither;
		Loop;
	Bounce.Floor:
		TNT1 A 0 ThrustThing(angle+randompick(-5,-3,-1,0,1,3,5),12,0,0);
		Goto Fly;
	Bounce.Wall:
		TNT1 A 0 A_Stop;
		Goto Death;
	Death:
		TNT1 A 0;
		Stop;
	}
}

// =====================================================================
// CHP 15 REBUILD ADDITIONS
// ---------------------------------------------------------------------
// The five actors the CHP-15 rebuild needed that this library did not
// already carry. Source: the first ACTOR of each
// E:\New folder\ART SOURCE\CHP\DECORATE\15\15_<code>.txt, falling back
// to the CH parent in CH\decorate\Barons.txt (and Revenants.txt, which
// is where CH keeps Firehand1). CHP's `_C` suffix stripped, RS_ added.
// =====================================================================

// ---------- T03 CYAN: the frost wings' cold-burst variant ----------
class RS_FrostWingBaron2 : Actor
{
	Default { Radius 2; Height 2; Speed 1; Projectile; +NOCLIP;
		RenderStyle "Add"; Alpha 0.65; Scale 0.55; }
	States
	{
	Spawn:
		KIRC ABCDABCD 1 Bright;
	Death:
		TNT1 A 0 { A_Stop(); A_SetScale(0.65, 0.65); }
		ICEY FGHI 1 Bright;
		TNT1 A 0 { A_SetScale(0.85, 0.85); }
		ICEY IGHF 1 Bright;
		Stop;
	}
}

// ---------- T05 YELLOW: the fire hand, and the bomb it throws ----------
class RS_FireHand1 : Actor
{
	Default { Radius 2; Height 2; Speed 0; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.9; Scale 1.2; SeeSound "fire/fire4"; }
	States
	{
	Spawn:
		FLUM ABCDE 6 Bright;
		Goto Death;
	Death:
		MISL BCD 6 Bright { A_SetScale(0.6, 0.6); }
		Stop;
	}
}

// A seeking star-bomb: it swells as it flies and sheds stars as it dies.
class RS_BaronFBomb : FastProjectile
{
	Default
	{
		Radius 12; Height 12; Speed 19; FastSpeed 38;
		DamageFunction (random(10, 70)); DamageType "Fire";
		Projectile; +RANDOMIZE +SEEKERMISSILE +DONTHARMCLASS;
		Species "BaronOfHell";
		RenderStyle "Add"; Alpha 1.0; Scale 1.0;
		SeeSound "spell/spellcast1"; DeathSound "spell/Impact1";
	}
	States
	{
	Spawn:
		BBOM A 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM A 1 Bright { A_SetScale(1.3, 1.3); }
		BBOM A 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM A 1 Bright { A_SetScale(1.0, 1.0); }
		Loop;
	Death:
		BBOM A 4 Bright { A_SetScale(1.8, 1.8); }
		BBOM B 5 Bright { A_SetTranslucent(0.65); }
		BBOM B 1 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM B 1 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM C 5 Bright { A_Explode(random(5, 30), 155); }
		BBOM D 4 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM D 1 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM D 1 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM E 6 Bright { A_Explode(random(5, 30), 155); }
		BBOM F 4 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM F 1 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM F 1 Bright { A_SpawnProjectile("RS_BaronStar3", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		BBOM G 5 Bright { A_Explode(random(5, 30), 155); }
		Stop;
	}
}

// ---------- T10 RED: the bouncing comet the Power Baron builds up to ----------
class RS_ArchonCometTrail : Actor
{
	Default { Radius 1; Height 1; Speed 0; +NOINTERACTION +NOBLOCKMAP;
		RenderStyle "Add"; Alpha 0.6; Scale 0.7;
		Translation "112:127=176:191"; }
	States { Spawn: ARCB DEFGH 3 Bright; Stop; }
}

class RS_ArchonComet : Actor
{
	Default
	{
		Radius 8; Height 12; Speed 25; Damage 20; Scale 1.0;
		Projectile; +THRUGHOST +BOUNCEONWALLS +DONTHURTSHOOTER;
		BounceType "Doom"; BounceFactor 1.0; BounceCount 4; WallBounceFactor 1.2;
		SeeSound "weapons/firbfi"; DeathSound "weapons/hellex"; BounceSound "Fire/fire4";
		DamageType "Fire";
		Translation "112:127=176:191";
	}
	States
	{
	Spawn:
		ARCB AAAABBBBCCCC 1 Bright { A_SpawnItemEx("RS_ArchonCometTrail", 0, 0, 0, 0, 0, 0, 0, 128); }
		Loop;
	Death:
		ARCB J 0 { A_SetTranslucent(0.67, 1); }
		ARCB J 3 Bright;
		ARCB K 3 Bright { A_Explode(random(10, 80), 128, 0); }
		ARCB LMN 3 Bright;
		Stop;
	}
}

// ---------- T11 BLACK: the deep-one railgun beam puff ----------
class RS_DeepBeam1 : Actor
{
	Default
	{
		Radius 25; Height 13; Speed 1; DamageFunction (random(10, 25)); Scale 1.5;
		Projectile; +RANDOMIZE; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.9;
		SeeSound "baron/attack"; DeathSound "baron/shotx";
	}
	States
	{
	Spawn:
		OLDP AB 7 Bright;
		OLDP C 0 { A_Scream(); }
		OLDP CDEF 4 Bright;
		Stop;
	}
}

// ---------- THE FALLEN (15_R's CommonRedBaron2) ----------
// Everything the second stage fires. CHP defines these in 15_R.txt
// alongside the Fallen itself.

class RS_FallenFX : Actor
{
	Default { Radius 2; Height 2; Speed 0; Scale 1.0; Projectile; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.67; }
	States { Spawn: TNT1 A 3 Bright; FBFX ABCDE 3 Bright; Stop; }
}

class RS_FallenShot : FastProjectile
{
	Default { Radius 8; Height 8; Speed 16; Damage 2; RenderStyle "Add";
		DamageType "Fire"; Alpha 0.67; Projectile; +THRUGHOST;
		SeeSound "baron/attack"; DeathSound "baron/shotx"; }
	States
	{
	Spawn:
		BALF AB 2 Bright { A_SpawnItemEx("RS_FallenFX", 0, 0, 0, 0, 0, 0, 0, 128); }
		Loop;
	Death:
		BALF CDEF 4 Bright;
		Stop;
	}
}

class RS_RedBBall2 : FastProjectile
{
	Default
	{
		Radius 8; Height 12; Speed 25; DamageFunction (random(10, 55)); Scale 0.5;
		Projectile; +THRUGHOST +DONTHURTSHOOTER;
		SeeSound "weapons/firbfi"; DeathSound "weapons/hellex";
		RenderStyle "Add"; Alpha 0.8; DamageType "Plasma";
		Translation "112:127=176:191";
	}
	States
	{
	Spawn:
		RED9 A 3 Bright { A_SetScale(0.5, 0.5); }
		RED9 B 3 Bright { A_SpawnProjectile("RS_CrackoBallTrail", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		RED9 C 3 Bright { A_SetScale(0.4, 0.4); }
		Loop;
	Death:
		ARCB J 0 { A_SetTranslucent(0.67, 1); }
		ARCB JJJJJ 1 Bright { A_SpawnProjectile("RS_FallenShot", 4, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		ARCB K 3 Bright { A_Explode(random(8, 20), 128, 0); }
		ARCB LMN 3 Bright;
		Stop;
	}
}

// --- CHP-15 IMPORT CORRECTIONS ------------------------------------
//   * CH sound names with no SNDINFO entry in this repo (deepone/*,
//     Obsidian/*, brnaby*, BBARO*, incubus/walk, monster/ar2*) are
//     mapped to their nearest vanilla baron/knight voice rather than
//     left as silent calls.
//   * A_SpawnParticle walls, RandomLetterSpawner, CHRandom_GibGenerator,
//     A_GivetoChildren and the CHBoner/CHWhitePlan gore gates are
//     dropped per docs/rs_09_monster_rebuild_spec.txt.
//   * CHP's DamageType "Fallen" has no resistance table here; the
//     Fallen's shot uses "Fire".
// ------------------------------------------------------------------
