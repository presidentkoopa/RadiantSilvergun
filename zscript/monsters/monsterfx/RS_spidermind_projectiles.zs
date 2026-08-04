// =====================================================================
// RS_spidermind_projectiles.zs
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
// hf_spidermind_projectiles.zs -- Spider Mastermind projectiles (Neutral + colors).
// Neutral = Babel ZManShot (a BabelBullet w/ CVar tracer-type; simplified to a plain
//   fast bullet). Bits/Chunks gib-cosmetics dropped -> cosmetic pass.
// ============================================================================

class RS_ZManShot : FastProjectile
{
	// the Spider Mastermind's chaingun bullet (CH/Babel ZManShot, simplified from BabelBullet)
	Default
	{
		Radius 4; Height 4; Speed 70; Damage 9;
		Projectile; +BLOODSPLATTER; DamageType "Monster"; Decal "BulletChip";
		RenderStyle "Add"; Alpha 0.85; Scale 0.5;
		SeeSound ""; MissileType "RS_ZManTrail";
	}
	States
	{
	Spawn:
		PLSS A 1 Bright;
		Loop;
	Death:
		PUFF A 1 Bright;
		PUFF BCD 3;
		Stop;
	}
}
class RS_ZManTrail : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.4; Scale 0.3; }
	States { Spawn: PLSS A 2 Bright A_FadeOut(0.25); Stop; }
}

// ============================================================================
// SPIDER MASTERMIND COLORS pass 1 -- GREEN / BLUE / CYAN / PURPLE.
// Shares RS_FrostLong, RS_SparkPuff1, RS_FrostWingBaron, RS_Gas14. Damage->constants.
// ============================================================================

// ---------- GREEN: poison spider-shot spread/sweep ----------
class RS_SpidieShot1 : Actor
{
	Default { Radius 2; Height 2; Speed 65; FastSpeed 80; Damage 6; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85; Scale 0.15;
		DamageType "Poison"; SeeSound "spider/attack"; DeathSound "imp/shotx"; Translation "168:191=112:127"; }
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
		Loop;
	Death:
		BAL1 CD 4 Bright;
		BAL1 D 0 A_Jump(128,"Gas");
		BAL1 E 2 Bright;
		Stop;
	Gas:
		BAL1 E 2 Bright A_SpawnItemEx("RS_Gas14",0,0,2,0,0,0,SXF_NOCHECKPOSITION);
		Stop;
	}
}

// ---------- BLUE: frost breath + bouncing ice orbs ----------
class RS_FrostMind : Actor
{
	Default { Radius 18; Height 18; Speed 19; Damage 8; DamageType "Ice"; Projectile; +THRUACTORS; RenderStyle "Add"; Alpha 0.85; Scale 1.1;
		SeeSound "ice/Breath"; DeathSound "Ice/Splode"; Translation "192:207=250:254"; }
	States
	{
	Spawn:
		PUFI ABCD 3 Bright A_Explode(8,20);
		Goto Death;
	Death:
		PUFI EFGH 4 Bright A_Explode(8,20);
		Stop;
	}
}
class RS_IceOrb : Actor
{
	Default { Radius 16; Height 15; Speed 14; Damage 30; DamageType "Ice"; Projectile; +SEEKERMISSILE; +BOUNCEONFLOORS; +USEBOUNCESTATE;
		RenderStyle "Add"; BounceType "Doom"; BounceCount 7; BounceFactor 1.5; WallBounceFactor 0.2; Alpha 0.85; Scale 2;
		SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; BounceSound "Ice/Splode"; WeaveIndexXY 9; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ICEY A 3 Bright A_SeekerMissile(1,2);
		ICEY B 3 Bright A_Weave(2,0,2,0);
		Loop;
	Death:
		ICEY CDE 4 Bright A_Explode(20,64);
		Stop;
	}
}

// ---------- CYAN: ice bombs + orbiting ice orbs ----------
class RS_SpiderCyanBomb : Actor
{
	Default { Radius 3; Height 3; Speed 45; Projectile; +NOGRAVITY; +SEEKERMISSILE; RenderStyle "Add"; Damage 27; DamageType "Ice"; Alpha 0.85; Scale 0.33;
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4"; Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		RED9 B 2 Bright A_SeekerMissile(1,1);
		RED9 A 3 Bright;
		Loop;
	Death:
		RED9 ABC 4 Bright A_Explode(27,64);
		Stop;
	}
}
class RS_IceOrbCyanMind : Actor
{
	Default { Radius 8; Height 8; Speed 42; Damage 30; DamageType "Ice"; Projectile; +THRUSPECIES; Alpha 0.85; Scale 1.5;
		SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ICEY A 2 Bright A_SeekerMissile(2,2);
		ICEY B 2 Bright A_Weave(2,1,2,1);
		Loop;
	Death:
		ICEY CDE 4 Bright A_Explode(20,48);
		Stop;
	}
}
class RS_IceOrbCyanMind2 : RS_IceOrbCyanMind { Default { Speed 30; } }

// ---------- PURPLE: demon-missiles + plasma orbs ----------
class RS_DemoMissile : Actor
{
	Default { Species "MMind3"; Radius 11; Height 8; Speed 17; Damage 20; DamageType "Fire"; Projectile; +DEHEXPLOSION; +ROCKETTRAIL; +THRUSPECIES;
		SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		MISL A 1 Bright A_CustomMissile("RS_SparkPuff1",4,0,CMF_AIMOFFSET,random(0,360),random(0,360));
		Loop;
	Death:
		BBOM A 4 Bright A_SetScale(1.8);
		BBOM B 5 A_SetTranslucent(0.65);
		BBOM CD 3 Bright A_Explode(40,128);
		Stop;
	}
}
class RS_OrbPurpleMind : Actor
{
	Default { Radius 3; Height 2; Speed 30; Damage 20; DamageType "Plasma"; Projectile; +RANDOMIZE; +MTHRUSPECIES; +FLOATBOB;
		RenderStyle "Add"; Alpha 0.85; Scale 0.25; SeeSound "Weapons/Plasmaf"; DeathSound "weapons/plasmax";
		Translation "16:47=250:254","128:143=250:254","152:191=250:254"; }
	States
	{
	Spawn:
		BAL1 A 1 Bright A_BishopMissileWeave;
		Loop;
	Death:
		BAL1 CDE 4 Bright;
		Stop;
	}
}

// ============================================================================
// SPIDER MASTERMIND COLORS pass 2 -- YELLOW / FIREBLU / GRAY / BROWN.
// Shares RS_MolochNail, RS_ZombieRock, RS_Drt1/2/3, RS_SparkPuff1. Damage->constants.
// ============================================================================

// small shared trails for this batch
class RS_TrailSP : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.5; Scale 0.4; }
	States { Spawn: PLSS A 2 Bright A_FadeOut(0.2); Stop; }
}
class RS_BuffTrailSP : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.4; Scale 0.5; }
	States { Spawn: SMK2 ABCD 3 A_FadeOut(0.15); Stop; }
}

// ---------- YELLOW: arachnorb balls + fiend plasma + remote bombs ----------
class RS_AracnorbBall : Actor
{
	Default { Radius 13; Height 8; Speed 11; Damage 30; RenderStyle "Add"; Alpha 0.75; SeeSound "baby/attack"; DeathSound "baby/shotx";
		Projectile; +STRIFEDAMAGE; +SEEKERMISSILE; +RANDOMIZE; }
	States
	{
	Spawn:
		ACNF AABB 1 Bright A_BishopMissileWeave;
		Loop;
	Death:
		ACNF CDEFG 5 Bright A_Explode(20,64);
		Stop;
	}
}
class RS_FiendPlasmaBall : Actor
{
	Default { Radius 6; Height 16; Speed 24; Damage 22; DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.95;
		SeeSound "Weapons/Plasmaf"; DeathSound "Weapons/Plasmax"; Scale 1.1; }
	States
	{
	Spawn:
		SPPL AB 1 Bright A_CustomMissile("RS_TrailSP",2,0,CMF_AIMOFFSET,random(0,360),random(0,360));
		Loop;
	Death:
		PLSE ABCDE 4 Bright;
		Stop;
	}
}
class RS_PlasmaBallSP3 : Actor
{
	Default { DamageType "Plasma"; Radius 13; Height 8; Speed 25; Damage 5; Projectile; +RANDOMIZE; +MTHRUSPECIES; RenderStyle "Add"; Alpha 0.75;
		SeeSound "weapons/plasmaf"; DeathSound "weapons/plasmax"; }
	States { Spawn: PLSS AB 6 Bright; Loop; Death: PLSE ABCDE 4 Bright; Stop; }
}
class RS_RemoteBombV2 : Actor
{
	Default { Radius 20; Height 20; Mass 20; Speed 15; Damage 25; SeeSound "prox/fire"; AttackSound "prox/beep"; DeathSound "weapons/rocklx";
		DamageType "Fire"; Projectile; +FLOATBOB; +SEEKERMISSILE; }
	States
	{
	Spawn:
		BOMB A 2 A_SeekerMissile(9,18);
		BOMB B 2 A_SpawnItemEx("RS_BuffTrailSP",5,0,2);
		BOMB A 2 A_SeekerMissile(9,18);
		Loop;
	Death:
		MISL B 6 Bright A_Explode(50,128);
		MISL CD 4 Bright;
		Stop;
	}
}

// ---------- FIREBLU: vile-targeted flame fields + flame waves (FIRE sprite) ----------
class RS_FireBCGguy : Actor
{
	Default { Radius 6; Height 6; Speed 45; FastSpeed 26; Damage 12; DamageType "Fire"; Projectile; +RANDOMIZE; +THRUACTORS;
		RenderStyle "Add"; Alpha 0.85; Scale 0.65; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States
	{
	Spawn:
		FIRE AB 2 Bright;
		Loop;
	Death:
		FIRE CDEEDCDE 5 A_Explode(8,64);
		FIRE FGH 4 Bright;
		Stop;
	}
}
class RS_FireBluMindFlame1 : Actor
{
	Default { Radius 12; Height 16; Speed 1; Damage 14; DamageType "Fire"; Projectile; +RANDOMIZE; +THRUACTORS; RenderStyle "Add"; Alpha 0.85;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States
	{
	Spawn:
		FIRE AB 1 Bright;
		Goto Death;
	Death:
		FIRE CDEEDCDE 5 A_Explode(8,64);
		FIRE FGH 4 Bright A_Explode(8,64);
		Stop;
	}
}
class RS_FireBluMindFlame3 : Actor
{
	Default { Radius 14; Height 14; Speed 14; Damage 10; DamageType "Fire"; Projectile; +RANDOMIZE; +THRUACTORS; +SEEKERMISSILE; +FLOORHUGGER;
		RenderStyle "Add"; Alpha 0.85; XScale 1.5; YScale 0.7; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States
	{
	Spawn:
		FIRE AB 2 Bright A_SeekerMissile(2,2);
		Loop;
	Death:
		FIRE CDEEDCDE 4 A_Explode(8,64);
		FIRE FGH 3 Bright;
		Stop;
	}
}

// ---------- GRAY: needles + moloch-nails + bouncing gray shots ----------
class RS_GrayMindNeedle : Actor
{
	Default { Radius 6; Height 4; Damage 30; DamageType "Melee"; Speed 5; XScale 1.1; YScale 0.45; Decal "BulletChip";
		AttackSound "moloch/nailhitbleed"; DeathSound "spike/spiked"; Projectile; +SPAWNSOUNDSOURCE; +BLOODSPLATTER; +SEEKERMISSILE; }
	States
	{
	Spawn:
		BLAD A 5 Bright;
		BLAD A 1 A_ScaleVelocity(3);
		Goto Fly;
	Fly:
		BLAD A 1 Bright A_SeekerMissile(5,5,SMF_PRECISE);
		Loop;
	Death:
		BLAD A 3 Bright;
		Stop;
	}
}
class RS_SpidieShotGray : Actor
{
	Default { Radius 3; Height 3; Speed 46; Damage 6; Projectile; +USEBOUNCESTATE; BounceType "Hexen"; BounceCount 3; BounceFactor 1; WallBounceFactor 1;
		Scale 0.25; DamageType "Melee"; SeeSound "moloch/nailhitbleed"; DeathSound "spike/spiked";
		Translation "0:255=%[0.14,0.25,0.32]:[0.79,0.79,0.79]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL1 AB 4 Bright;
		Loop;
	Bounce:
		PUFI ABCD 2 Bright;
		Goto Fly;
	Death:
		PUFI ABCD 3 Bright;
		Stop;
	}
}

// ---------- BROWN: ground-spikes + brown orbs (B05P body) ----------
class RS_MindGroundSpikeBrown : Actor
{
	Default { Speed 1; Radius 24; Height 8; Damage 18; DamageType "Melee"; Projectile; +FLOORHUGGER; +THRUACTORS; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		B0N8 A 3 A_QuakeEx(2,2,2,15,0,40);
		B0N8 A 1 A_SpawnItemEx("RS_Drt2",0,32,1,random(1,5),0,random(1,5),random(0,360));
		B0N8 A 1 A_SpawnItemEx("RS_Drt3",-32,0,1,random(1,5),0,random(1,5),random(0,360));
		B0N8 A 1 A_SpawnItemEx("RS_Drt1",0,-32,1,random(1,5),0,random(1,5),random(0,360));
		B0N8 BCDEF 3 A_Explode(18,48);
		Stop;
	}
}
class RS_BrownOrbMindTrail : Actor
{
	Default { Radius 2; Height 2; Projectile; +NOCLIP; Translation "0:255=@74[77,52,26]"; Scale 0.15; }
	States { Spawn: TNT1 A 1; Goto Death; Death: RIP1 DEFGH 1 Bright; Stop; }
}
class RS_BrownOrbMind : Actor
{
	Default { Radius 3; Height 3; Speed 38; ProjectileKickBack 333; Mass 100; Damage 18; Projectile; DamageType "Fire"; +MTHRUSPECIES; +THRUGHOST;
		SeeSound "fire/fire3"; DeathSound "weapons/boom1"; Translation "0:255=@74[77,52,26]"; Scale 0.33; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL1 AB 4 Bright A_SpawnItemEx("RS_BrownOrbMindTrail",0,0,0);
		Loop;
	Death:
		RIP1 DEFGH 3 Bright A_Explode(18,64);
		Stop;
	}
}

// Brown extras: bone-throw + wind-blast pushes (BBBN/BAL1/BBOM)
class RS_BrownMindBone2 : Actor
{
	Default { Radius 5; Height 5; Speed 20; ProjectileKickBack 500; Mass 100; Damage 30; Projectile; DamageType "Melee";
		+MTHRUSPECIES; +THRUGHOST; +SEEKERMISSILE; DeathSound "MEATIMPB"; Scale 2.25; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BBBN ABCD 1 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		BBBN A 4;
		Stop;
	}
}
class RS_WindBlastMasterMind : Actor
{
	Default { Radius 2; Height 2; Speed 15; Projectile; +NOCLIP; RenderStyle "Add"; Alpha 0.25; SeeSound "PUSHBMIN"; Scale 1.5;
		Translation "0:255=%[0.54,0.59,0.36]:[2.00,2.00,2.00]"; }
	States { Spawn: TNT1 A 0; Fly: BAL1 A 4 Bright; BAL1 B 4 Bright A_SetScale(2.0,2.0); Goto Death; Death: BAL1 CDE 3 Bright; Stop; }
}
class RS_WindBlastMasterMind2 : Actor
{
	Default { Radius 2; Height 2; Speed 10; Projectile; +NOCLIP; RenderStyle "Add"; Alpha 0.25; Scale 1.5;
		Translation "0:255=%[0.54,0.59,0.36]:[2.00,2.00,2.00]"; }
	States { Spawn: TNT1 A 0; Fly: BBOM B 2 Bright; BBOM B 2 Bright A_SetScale(2.0,2.0); Goto Death; Death: BBOM CDE 3 Bright; Stop; }
}

// ============================================================================
// SPIDER MASTERMIND APEX -- RED / ABYSS / BLACK / WHITE. The summit webs.
// AbyssShotIdentifier + CH ammo-drops dropped -> cosmetic pass. Damage->constants.
// Deepest sub-chains folded faithfully (tracked for cosmetic pass).
// ============================================================================

// ---------- RED (APYT body, HP10000): spiral-saws + damage rings + red bombs ----------
class RS_SpiralSawMind1 : Actor
{
	Default { Radius 6; Height 8; Speed 18; Projectile; +NOGRAVITY; +SEEKERMISSILE; RenderStyle "Add"; Damage 35; DamageType "Fire"; Alpha 0.75;
		SeeSound "Weapons/BFGF"; DeathSound "Fire/Fire4"; }
	States
	{
	Spawn:
		RED9 B 3 Bright A_SeekerMissile(1,1);
		RED9 AAAAA 0 A_CustomMissile("RS_SparkPuff1",4,0,CMF_AIMOFFSET,random(0,360),random(0,360));
		RED9 ABC 2 Bright A_Weave(5,1,7,1);
		Loop;
	Death:
		RED9 ABC 4 Bright A_Explode(35,96);
		Stop;
	}
}
class RS_RedMindRingNew : Actor
{
	Default { Radius 6; Height 8; Speed 1; Mass 999999; Gravity 10; Projectile; +BOUNCEONFLOORS; +THRUACTORS; +RANDOMIZE; +SEEKERMISSILE; +USEBOUNCESTATE; +DONTTHRUST;
		BounceCount 999; BounceType "Hexen"; BounceFactor 0.5; RenderStyle "Add"; SeeSound "Fire/fire3"; Damage 45; DamageType "Melee"; Alpha 0.95; Scale 1;
		Translation "208:223=176:191","224:231=176:176"; }
	States
	{
	Spawn:
		RED9 AB 4 Bright A_SeekerMissile(1,1);
		Loop;
	Bounce:
		RED9 A 2 Bright;
		Goto Spawn;
	Death:
		RED9 ABC 4 Bright A_Explode(45,64);
		Stop;
	}
}
class RS_RedMindBomb : Actor
{
	// CH RedMindBomb is a floating MONSTER bomb; here a seeking float-bomb projectile.
	Default { Radius 20; Height 20; Mass 20; Speed 19; Damage 40; DamageType "Fire"; Projectile; +FLOAT; +FLOATBOB; +SEEKERMISSILE;
		SeeSound "prox/fire"; AttackSound "vile/active"; DeathSound "weapons/rocklx"; RenderStyle "Add"; Alpha 0.85; Scale 1.85;
		Translation "208:223=176:191","224:231=176:176"; }
	States
	{
	Spawn:
		MISL A 3 Bright A_SeekerMissile(4,8);
		Loop;
	Death:
		MISL B 6 Bright A_Explode(80,160);
		MISL CD 4 Bright;
		Stop;
	}
}

// ---------- ABYSS (multi-body ABSP/AMIN/ANIM/ARNQ, HP12222): big-zaps + holy waves + cracked-floor ----------
class RS_AbyssMindBigZap : Actor
{
	Default { Radius 18; Height 18; Speed 1; Projectile; +DONTHARMCLASS; +NOCLIP; +FLOATBOB; RenderStyle "Add"; Alpha 1.0; Scale 1.05; }
	States { Spawn: TNT1 A 0; Fly: ZPWV ABCBCABCACBABCA 10 Bright; Goto Death; Death: TNT1 A 0; Stop; }
}
class RS_AbyssMindWave2 : Actor
{
	Default { Radius 18; Height 18; Speed 20; Damage 25; DamageType "Melee"; Projectile; +DONTHARMCLASS; RenderStyle "Add"; Alpha 0.25; Scale 0.6;
		DeathSound "holy2/holy2"; }
	States { Spawn: ZPWV D 6 Bright; Death: ZPWV D 8 Bright; Stop; }
}
class RS_AbyssMindWave : Actor
{
	Default { Radius 18; Height 18; Speed 34; ProjectileKickBack 9000; Damage 50; DamageType "Melee"; Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 0.25; Scale 0.85; SeeSound "queen/fire"; DeathSound "holy2/holy2"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ZPWV D 5 Bright A_SpawnItemEx("RS_AbyssMindWave2",0,0,3,0,0,0,0);
		Loop;
	Death:
		ZPWV D 8 Bright;
		Stop;
	}
}
class RS_CrackedAbyssMindFall : Actor
{
	Default { Radius 1; Height 1; Speed 18; Damage 30; DamageType "Plasma"; Projectile; +NOGRAVITY; +CEILINGHUGGER; Scale 0.85; RenderStyle "Add"; Alpha 1.0;
		SeeSound "Crack/see"; DeathSound "Crack/death"; Translation "Ice"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 A_ChangeFlag("CEILINGHUGGER",false);
		TNT1 A 0 A_ChangeFlag("NOGRAVITY",false);
		SPIR ABC 2 Bright;
		Loop;
	Death:
		SPIR DE 4 Bright A_Explode(20,48);
		Stop;
	}
}
class RS_CrackedAbyssMindFloor : Actor
{
	Default { Radius 4; Species "Revenant"; Height 4; Speed 24; Damage 20; DamageType "Plasma"; Projectile; +FLOORHUGGER; Scale 0.85; RenderStyle "Add"; Alpha 1.0;
		SeeSound "Crack/see"; DeathSound "Crack/death"; Translation "Ice"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		SPIR A 3 Bright A_CStaffMissileSlither;
		SPIR B 2 Bright;
		Loop;
	Death:
		SPIR CDE 4 Bright A_Explode(20,48);
		Stop;
	}
}

// ---------- BLACK (ARNQ "Pseudo Old God", HP11111): psychic waves, queen plasma, shades ----------
class RS_PsychicAra2 : Actor
{
	Default { Projectile; +NOBLOCKMAP; +NOGRAVITY; +ALLOWPARTICLES; RenderStyle "Stencil"; StencilColor "Black"; Alpha 0.95; Damage 7; DamageType "Plasma";
		Scale 1.8; DeathSound "deepone/active"; Mass 50; }
	States
	{
	Spawn:
		ARNQ A 2 Bright;
		Goto Death;
	Death:
		ARNQ C 1;
		ARNQ B 2 Bright A_QuakeEx(2,2,2,30,0,9);
		ARNQ C 1 Bright A_Explode(7,64);
		Stop;
	}
}
class RS_ZWAVE3 : Actor
{
	Default { Radius 10; Height 10; Speed 15; SeeSound "queen/fire"; Projectile; Damage 20; DamageType "Melee"; RenderStyle "Stencil"; StencilColor "Black"; Alpha 0.65; Scale 0.3; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 A_Explode(5,64);
		BLST ABCD 1 Bright;
		BLST EFGHI 1 Bright;
		Loop;
	Death:
		BLST EFGHI 2 Bright;
		Stop;
	}
}
class RS_QueenMindWave : Actor
{
	Default { Radius 8; Height 8; Speed 24; Damage 50; Projectile; +SEEKERMISSILE; DamageType "Plasma"; RenderStyle "Add"; SeeSound "queen/fire"; DeathSound "queen/hit"; Decal "SwordLightning"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BLST A 2 Bright A_SeekerMissile(3,6);
		BLST B 0 A_SpawnItemEx("RS_ZWAVE3",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		BLST B 2 Bright;
		Loop;
	Death:
		BLST CDE 4 Bright A_Explode(50,96);
		Stop;
	}
}
class RS_QueenPlasmaBlast : Actor
{
	Default { Radius 13; Height 8; Speed 32; Damage 25; Projectile; DamageType "Plasma"; Scale 0.75; +RANDOMIZE; +BLOODLESSIMPACT; +NOEXTREMEDEATH; +BOUNCEONFLOORS; +USEBOUNCESTATE;
		BounceType "Doom"; BounceCount 3; BounceFactor 1.25; RenderStyle "Add"; Alpha 0.75; SeeSound "electricplasma/shoot"; }
	States
	{
	Spawn:
		EBLT AB 2 Bright;
		Loop;
	Bounce:
		EBLT C 2 Bright;
		Goto Spawn;
	Death:
		EBLT CDE 4 Bright A_Explode(25,64);
		Stop;
	}
}
class RS_BlackSpidShade : Actor
{
	// the drifting black shade (CH SpecialSpot-based summon decoration; here a damaging drifter)
	Default { Radius 32; Height 32; Speed 8; Damage 30; DamageType "Melee"; Projectile; +FLOATBOB; +SEEKERMISSILE; +NOGRAVITY; RenderStyle "Translucent"; Alpha 0.5;
		Translation "0:255=%[0.45,0.45,0.45]:[0.01,0.01,0.01]"; }
	States
	{
	Spawn:
		ARNQ AB 6 A_SeekerMissile(1,2);
		Loop;
	Death:
		ARNQ CDE 6 A_FadeOut(0.2);
		Stop;
	}
}

// ---------- WHITE (W5PD "Everlasting White Spidey", HP15000): crackle-orbs + tracers + winders ----------
class RS_STracerWhiteSP : Actor
{
	Default { Radius 5; Height 5; Speed 20; Damage 22; RenderStyle "Add"; DamageType "Fire"; Alpha 0.67; Projectile; +FLOORHUGGER; +THRUGHOST; -NOGRAVITY; +DONTSPLASH;
		SeeSound "ELECTRO8"; DeathSound "Crack/death"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States
	{
	Spawn:
		FTRA A 1 Bright A_CStaffMissileSlither;
		Loop;
	Death:
		FTRA KLM 4 Bright A_Explode(15,64);
		Stop;
	}
}
class RS_WhiteMindCrackleOrb : Actor
{
	Default { Radius 16; Height 16; Speed 9; Projectile; +NOGRAVITY; +SEEKERMISSILE; Scale 2.35; Damage 80; DamageType "Plasma";
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4"; Translation "0:255=%[0.21,0.29,0.68]:[1.07,2.00,2.00]"; }
	States
	{
	Spawn:
		RED9 AB 3 Bright A_SeekerMissile(2,3);
		Loop;
	Death:
		RED9 ABC 5 Bright A_Explode(80,160);
		Stop;
	}
}
class RS_WhiteMindCrackleOrb2 : Actor
{
	Default { Radius 16; Height 16; Speed 0; Projectile; +NOGRAVITY; +SEEKERMISSILE; Scale 1; Damage 80; DamageType "Plasma";
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4"; Translation "0:255=%[0.21,0.29,0.68]:[1.07,2.00,2.00]"; }
	States
	{
	Spawn:
		RED9 B 2 Bright A_SetScale(1.5);
		RED9 A 2 Bright;
		Loop;
	Death:
		RED9 ABC 5 Bright A_Explode(80,128);
		Stop;
	}
}
class RS_WhiteMindshot1 : Actor
{
	Default { Radius 6; Height 6; Speed 45; Damage 30; DamageType "Plasma"; Projectile; +BOUNCEONWALLS; +USEBOUNCESTATE; BounceType "Doom"; BounceCount 2;
		XScale 1.1; YScale 0.75; RenderStyle "Add"; SeeSound "weapons/plasmaf"; DeathSound "weapons/plasmax";
		Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States
	{
	Spawn:
		PLSS AB 4 Bright;
		Loop;
	Bounce:
		PLSS A 2 Bright;
		Goto Spawn;
	Death:
		PLSE ABCDE 4 Bright;
		Stop;
	}
}
class RS_WhiteSpidWinder : Actor
{
	Default { Radius 5; Height 5; Speed 30; Damage 40; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; +DONTHARMCLASS; +THRUSPECIES; +FLOORHUGGER;
		RenderStyle "Add"; Alpha 0.9; Scale 0.85; SeeSound "ELECTRO8"; DeathSound "Crack/death"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States
	{
	Spawn:
		SPER AB 2 Bright A_SeekerMissile(3,4);
		Loop;
	Death:
		SPER AB 4 Bright A_Explode(40,96);
		Stop;
	}
}

// =====================================================================
// FAMILY 16 SECOND PASS -- the pieces RS_Mastermind.zs needs that this
// library did not carry yet. Ported from CHP\DECORATE\16\16_*.txt (and
// the CH parent where CHP only tweaks it), same rules as above: the
// projectile is faithful, purely-cosmetic sub-spawn chains are folded
// in rather than dragging ten more decoration actors across.
// =====================================================================

// ---------- T03 CYAN: the ice trail. CH's CyanSpidTrail is a
// SpecialSpot on purpose -- the cyan mind teleports ONTO its own trail
// when it takes pain, so this must stay a spot, not a plain Actor.
class RS_CyanSpidTrail : SpecialSpot
{
	Default { Radius 4; Height 4; Speed 8; +NOBLOCKMAP; +NOGRAVITY; +NOCLIP;
		RenderStyle "Add"; Alpha 0.6; Scale 0.5;
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		ICEY A 3 Bright A_FadeOut(0.12);
		Loop;
	}
}

// ---------- T11 BLACK: the teleport anchor. CH spawns BlackSpidShade
// (a SpecialSpot there) as both the damaging shade and the warp anchor;
// RS_BlackSpidShade is already a damaging drifter, so the anchor is its
// own invisible, short-lived spot.
class RS_BlackSpidSpot : SpecialSpot
{
	Default { Radius 2; Height 2; +NOBLOCKMAP; +NOGRAVITY; +NOCLIP; +INVISIBLE; }
	States
	{
	Spawn:
		TNT1 A 70;
		Stop;
	}
}

// ---------- T11 BLACK: the warp flash (CHP ZWAVE2_C).
class RS_ZWAVE2 : Actor
{
	Default { +NOINTERACTION; +NOBLOCKMAP; Scale 1.5; RenderStyle "Add"; Alpha 0.75; }
	States
	{
	Spawn:
		TNT1 A 2;
		BLST ABCD 1 Bright A_FadeOut(0.0625);
		BLST EFGHIJKLMNOP 1 Bright A_FadeOut(0.0625);
		Stop;
	}
}

// ---------- T06 ABYSS: the tentacle field dropped by A_VileTarget.
// CHP's ABVileTend_C is a translated ABVileTend whose death splashes
// four abyss puddles; the splash actors are decoration and are folded
// into the death animation here.
// Defined in RS_archvile_projectiles.zs, from CH Archviles.txt ABVileTend.

// ---------- T06 ABYSS: the psychic tangle (CHP PsychicTangleAbyVile_C).
// Defined in RS_archvile_projectiles.zs -- CHP's _C variant and CH's parent are
// the same actor, so the vile's copy serves the spider mastermind too.

// ---------- T07 FIREBLU: the fireblu spam bolt (CHP 04_F FireBCguy_C).
class RS_FireBCguy : FastProjectile
{
	Default { Radius 6; Height 6; Speed 45; Damage 12; DamageType "Fire";
		Projectile; +RANDOMIZE; +THRUACTORS; RenderStyle "Add"; Alpha 0.85; Scale 0.65;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200", "160:160=177:177", "162:162=184:184", "163:163=204:204",
		            "164:164=186:186", "165:165=204:204", "166:166=189:189", "167:167=207:207"; }
	States
	{
	Spawn:
		FIRE A 0;
		FIRE AB 4 Bright A_Explode(random(4, 15), 64);
		Goto Fly;
	Fly:
		FIRE CDEEDCDE 3 A_Explode(random(4, 15), 64);
		Loop;
	Death:
		FIRE FGH 6 Bright A_Explode(random(5, 15), 64);
		Stop;
	}
}

// ---------- T08 BROWN: the third, fastest wind blast.
class RS_WindBlastMasterMind3 : RS_WindBlastMasterMind2 { Default { Speed 20; } }

// ---------- T08 BROWN: the bone shield the brown mind hands out to
// every demon around it, once, when it drops below 3000.
class RS_MindBoneShield : Actor
{
	private int rsSpin;
	Default { Radius 40; Height 64; +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION;
		RenderStyle "Translucent"; Alpha 0.7; Scale 1.1;
		Translation "0:255=%[0.10,0.08,0.05]:[1.20,1.05,0.70]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BBBN A 1 { rsSpin += 8; A_Warp(AAPTR_MASTER, 34, 0, 24, rsSpin, WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); if (!master || master.health <= 0) return ResolveState("Death"); return ResolveState(null); }
		BBBN B 1 { rsSpin += 8; A_Warp(AAPTR_MASTER, 34, 0, 24, rsSpin, WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); if (!master || master.health <= 0) return ResolveState("Death"); return ResolveState(null); }
		Loop;
	Death:
		BBBN CD 2 A_FadeOut(0.2);
		Loop;
	}
}
class RS_ShieldUpMind2 : CustomInventory
{
	Default { Inventory.MaxAmount 1; +INVENTORY.AUTOACTIVATE; +INVENTORY.UNDROPPABLE; }
	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	Pickup:
	Use:
		TNT1 A 0 A_SpawnItemEx("RS_MindBoneShield", 0, 0, 0, 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION);
		Stop;
	}
}

// ---------- T09 GRAY: the floating brain that rides the gray mind.
class RS_BrainPainGray : Actor
{
	Default { Radius 6; Height 6; +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.8; Scale 0.8; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		ICEY AAABBBCCC 1 Bright { A_Warp(AAPTR_MASTER, random(-8, 8), random(-13, 13), random(82, 102), 0, WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); if (!master || master.health <= 0) return ResolveState("Death"); return ResolveState(null); }
		Loop;
	Death:
		ICEY A 2 Bright A_NoBlocking;
		ICEY B 2 Bright A_SetScale(1);
		ICEY C 2 Bright A_SetScale(0.7);
		ICEY F 2 Bright A_SetScale(0.4);
		Stop;
	}
}

// ---------- T09 GRAY: the nail storm round (CHP SpidieNail_C).
class RS_SpidieNail : FastProjectile
{
	Default { Radius 4; Height 6; Speed 30; Damage 20; DamageType "Fire";
		Projectile; +SPAWNSOUNDSOURCE; +EXTREMEDEATH; +BLOODSPLATTER; +ROCKETTRAIL;
		Scale 1.1; Decal "BulletChip";
		SeeSound "moloch/nail"; AttackSound "moloch/nailhitbleed"; DeathSound "weapons/firex4"; }
	States
	{
	Spawn:
		BLAD A 1 Bright;
		Loop;
	Death:
		"6PUF" A 0 A_StartSound("moloch/nailhit", CHAN_BODY);
		"6PUF" ABCDEF 1 Bright A_Explode(random(2, 10), 64);
		FBL1 EFG 1 Bright A_Explode(random(5, 20), 64);
		Stop;
	}
}

// =====================================================================
// T12 WHITE -- "Everlasting White Spidey" (16_W) kit.
// =====================================================================

// The homing plasma rocket of the Rockabye pattern.
class RS_ESPlasmaRocket : Actor
{
	Default { Radius 13; Height 9; Speed 1; Damage 60; DamageType "Plasma";
		Projectile; +RANDOMIZE; +DEHEXPLOSION; +MTHRUSPECIES; Species "MMind";
		Scale 1.0; XScale 1.3; YScale 0.85;
		SeeSound "weapons/hominglaunch"; DeathSound "weapons/rocklx";
		Translation "48:159=%[0.00,0.00,0.00]:[1.01,1.01,1.01]",
		            "0:15=%[0.00,0.00,0.00]:[1.01,1.01,1.01]",
		            "16:47=%[0.00,0.19,0.25]:[0.50,1.63,2.00]",
		            "160:255=%[0.00,0.19,0.25]:[0.50,1.63,2.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_ScaleVelocity(random(20, 60));
	Fly:
		MISL A 1 Bright;
		MISL AA 1 Bright A_Weave(3, 0, 3, 0);
		Loop;
	Death:
		MISL B 0 A_SetTranslucent(0.75, 1);
		MISL B 4 Bright A_Explode(random(80, 180), 88);
		MISL CD 4 Bright;
		Stop;
	}
}

// The Shocker's bouncing lightning ball.
class RS_ESZapper : Actor
{
	Default { Radius 8; Height 9; Speed 1; Damage 25; DamageType "Plasma";
		Projectile; +RANDOMIZE; +FORCEXYBILLBOARD; BounceType "Hexen";
		+BOUNCEONWALLS; +BOUNCEONCEILINGS; +BOUNCEONFLOORS;
		+THRUSPECIES; +MTHRUSPECIES; +DONTHARMSPECIES; Species "MMind";
		BounceCount 6; BounceFactor 1; WallBounceFactor 1;
		RenderStyle "Add"; Alpha 0.9; Scale 1;
		Translation "0:255=%[0.21,0.29,0.68]:[1.07,2.00,2.00]";
		SeeSound "monster/hadtel"; BounceSound "Litn/litn2"; DeathSound "monster/hadsit"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_ScaleVelocity(random(20, 40));
		TNT1 A 0 A_StartSound("Litn/litn3", CHAN_BODY);
	Fly:
		LITN B 0 A_Explode(random(0, 3), 96, 0);
		LITN B 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN C 0 A_Explode(random(0, 3), 96, 0);
		LITN C 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN D 0 A_Explode(random(0, 3), 96, 0);
		LITN D 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN E 0 A_Explode(random(0, 3), 96, 0);
		LITN E 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN F 0 A_Explode(random(0, 3), 96, 0);
		LITN F 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN G 0 A_Explode(random(0, 3), 96, 0);
		LITN G 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN O 0 A_Explode(random(0, 3), 96, 0);
		LITN O 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN P 0 A_Explode(random(0, 3), 96, 0);
		LITN P 2 Bright A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		Loop;
	Death:
		LITN AAAAAAAA 0 A_SpawnItemEx("RS_ESZapZap", 0, 0, 0, frandom(-5, 5), frandom(-5, 5), frandom(-5, 5), 0, SXF_NOCHECKPOSITION);
		LITN A 2;
		Stop;
	}
}
// The lightning-strike payload rained from the sky by the MegaStrike.
class RS_ESZapper2 : RS_ESZapper {}

// EyeBeam railgun puffs: the trail spark and the impact burst.
class RS_WhiteMindRB4 : Actor
{
	Default { Radius 4; Height 4; Speed 11; Damage 20; Projectile; +NOGRAVITY;
		+MTHRUSPECIES; Species "MMind"; RenderStyle "Add"; Alpha 0.9;
		SeeSound "Spell/spellCast1"; DeathSound "Crack/death"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL2 A 3 Bright A_SetScale(1.33, 1.33);
		BAL2 B 3 Bright A_SetScale(1.15, 1.15);
		BAL2 A 3 Bright A_SetScale(0.85, 0.85);
		BAL2 B 3 Bright A_SetScale(1.15, 1.15);
	Death:
		BAL2 C 4 A_SetTranslucent(0.55);
		BAL2 D 1 A_Explode(random(10, 20), 88);
		BAL2 E 2 A_Explode(random(10, 20), 88);
		Stop;
	}
}
class RS_WhiteMindRB3 : Actor
{
	Default { Radius 4; Height 4; Speed 1; Damage 60; Projectile; +NOGRAVITY;
		+MTHRUSPECIES; Species "MMind"; RenderStyle "Add"; DeathSound "NETHERDE"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		TNT1 A 0 A_Scream;
		BFE1 AB 5 Bright;
		BFE1 C 8 Bright A_Explode(random(30, 95), 128);
		TNT1 A 0 A_Quake(9, 9, 0, 30);
		BFE1 DEF 8 Bright;
		Stop;
	}
}

// The orbiting reflective shield the white mind raises once.
class RS_WhiteSpidShieldWalk : Actor
{
	private int rsAngle;
	Default { Radius 88; Height 100; Speed 18; Health 999; Species "MMind";
		Monster;
		+NOTRIGGER +NOTARGET +DONTTHRUST +NOGRAVITY +INVULNERABLE
		+REFLECTIVE +DEFLECT +SHIELDREFLECT +THRUSPECIES +MTHRUSPECIES
		-COUNTKILL
		RenderStyle "Add"; Alpha 1.0; Scale 1.5;
		Translation "0:255=%[0.00,0.00,0.00]:[1.01,1.76,2.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		CHSW Z 1 Bright { rsAngle += 8; A_Warp(AAPTR_MASTER, 128, 0, 8, rsAngle, WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE); if (rsAngle >= 3600 || !master || master.health <= 0) return ResolveState("Death"); return ResolveState(null); }
		Loop;
	Death:
		CHSW Z 2 Bright A_NoBlocking;
		CHSW Z 2 Bright A_SetScale(1.0);
		CHSW Z 2 Bright A_SetScale(0.7);
		CHSW Z 2 Bright A_SetScale(0.4);
		TNT1 A 0 A_Die;
		Stop;
	}
}

// The lightning caller: a target marker that rains ESZapper2 from above.
// CHP's marker blinks between CHTA A and CHTA X; RS's art set only
// carries CHTA A, so the off-frames are TNT1.
class RS_WhiteSpidMegaStrike2 : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +MTHRUSPECIES; +DONTHARMSPECIES; Species "MMind"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 AAAAA 0 A_SpawnProjectile("RS_ESZapper2", -8, 0, random(0, 360), CMF_AIMDIRECTION, random(-60, -90));
		Stop;
	}
}
class RS_WhiteSpidMegaStrike : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +MTHRUSPECIES; +DONTHARMSPECIES; Species "MMind"; Scale 1.25; }
	States
	{
	Spawn:
		CHTA A 0;
		CHTA A 0 A_StartSound("SPMTARG", CHAN_BODY);
		CHTA A 2 Bright;
		TNT1 A 2;
		CHTA A 2 Bright;
		TNT1 A 2;
		CHTA A 2 Bright;
		TNT1 A 2;
		CHTA A 2 Bright;
		TNT1 A 2;
		CHTA A 2 Bright A_SpawnItemEx("RS_WhiteSpidMegaStrike2", random(-32, 32), random(-32, 32), 32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		TNT1 A 2 A_SpawnItemEx("RS_WhiteSpidMegaStrike2", random(-32, 32), random(-32, 32), 32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		CHTA A 2 Bright A_SpawnItemEx("RS_WhiteSpidMegaStrike2", random(-32, 32), random(-32, 32), 32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		TNT1 A 2 A_SpawnItemEx("RS_WhiteSpidMegaStrike2", random(-32, 32), random(-32, 32), 32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		CHTA A 2 Bright A_SpawnItemEx("RS_WhiteSpidMegaStrike2", random(-32, 32), random(-32, 32), 32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		TNT1 A 2 A_SpawnItemEx("RS_WhiteSpidMegaStrike2", random(-32, 32), random(-32, 32), 32767, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		Stop;
	}
}

// The web shot -- a slow, heavy tangle round fired in long strings.
// Ported from CHP 12_W's WHITESPIDERWEBSHOT_C, which 16_W only reskins
// with +MTHRUSPECIES. The web-decal litter it drops on death and the
// player-slowdown token are CH inventory plumbing with no consumer
// here; the round itself is verbatim.
class RS_WhiteMindWebShot : FastProjectile
{
	Default { Radius 3; Height 3; Speed 35; Damage 3; DamageType "Melee";
		Projectile; +MTHRUSPECIES; +DONTHARMSPECIES; Species "MMind"; Scale 0.75;
		SeeSound "phantom/bomb"; DeathSound "phantom/explode";
		Translation "192:207=80:95"; }
	States
	{
	Spawn:
		PLSE A 3 Bright;
		Loop;
	Death:
		PLSE BCDE 1 Bright;
		Stop;
	}
}

// The chaos ball, fired once per Everlasting cycle: a heavy bouncing
// plasma orb. CHP's OrbOfChaos death gag is left out; the ball keeps
// its own blast.
class RS_WhiteSpidChaosBall : Actor
{
	Default { Radius 40; Height 80; Speed 30; Damage 140; DamageType "Plasma";
		Species "MMind"; Scale 1.5; Gravity 0.6;
		Projectile; +BOUNCEONWALLS; +BOUNCEONCEILINGS; -NOGRAVITY; +MTHRUSPECIES;
		BounceCount 99999; BounceFactor 1; WallBounceFactor 1;
		SeeSound "Crack/see"; DeathSound "Crack/death";
		RenderStyle "Stencil"; StencilColor "BF 98 E7"; }
	States
	{
	Spawn:
		RED9 AAAABBBB 1 Bright;
		Loop;
	Death:
		BLL9 A 0 A_SetScale(3, 3);
		BLL9 CDE 6 Bright A_Explode(120, 200);
		Stop;
	}
}

// The orbital nuke: a rising show flare, a ground marker that counts
// down, and the shell that falls on it.
class RS_WhiteFatNukeShow : FastProjectile
{
	Default { Radius 9; Height 9; Speed 21; Projectile; +NOINTERACTION;
		Scale 1.0; XScale 0.55; YScale 1.74; SeeSound "imp/attack";
		Translation "231:231=4:4", "208:223=80:86", "168:191=192:196", "32:47=4:4", "250:254=4:4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL2 B 6 A_SetScale(0.44, 1.86);
		BAL2 A 6 A_SetScale(0.33, 1.99);
		BAL2 B 6 A_SetScale(0.22, 2.22);
		BAL2 A 6 A_SetScale(0.11, 2.44);
		Stop;
	}
}
class RS_WhiteFatNuke : FastProjectile
{
	Default { Radius 12; Height 12; Speed 25; Mass 8000; Damage 150; DamageType "Fire";
		Projectile; -NOGRAVITY; +DONTHARMSPECIES; Species "MMind";
		Scale 1.0; XScale 1.2; YScale 2.6; RenderStyle "Add"; Alpha 1.0;
		SeeSound "ARCAZAP7"; DeathSound "NETHERDE";
		Translation "231:231=4:4", "208:223=80:86", "168:191=192:196", "32:47=4:4",
		            "250:254=4:4", "112:120=80:88", "120:127=192:199", "160:167=4:4",
		            "224:235=192:192", "64:79=192:199", "144:151=4:4", "128:143=4:4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL2 AB 1 Bright;
		Loop;
	Death:
		TNT1 A 0 A_SetScale(2.5, 0.15);
		TNT1 A 0 A_Scream;
		BFE1 AB 3 Bright;
		BFE1 C 8 Bright A_Explode(random(80, 155), 326);
		TNT1 A 0 A_Quake(15, 15, 0, 40);
		BFE1 DEF 8 Bright A_Explode(random(80, 155), 326);
		Stop;
	}
}
class RS_WhiteFatMark : Actor
{
	Default { Radius 4; Height 4; Speed 1; +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Death;
	Death:
		TNT1 A 1 A_Scream;
		CHTA A 10 Bright;
		TNT1 A 1;
		CHTA A 10 Bright;
		TNT1 A 1;
		CHTA A 10 Bright;
		TNT1 A 1;
		CHTA A 10 Bright;
		TNT1 A 1;
		CHTA A 10 Bright;
		TNT1 A 1;
		CHTA A 10 Bright;
		TNT1 A 1;
		CHTA A 10 Bright;
		TNT1 A 1;
		CHTA A 10 Bright;
		TNT1 A 0 A_SpawnItemEx("RS_WhiteFatNuke", 0, 0, random(128, 256), 0, 0, -2, 0, SXF_NOCHECKPOSITION);
		Stop;
	}
}

// The mini sentinel the white mind lobs out with A_PainAttack, and its
// flare round. Excluded from the kill count, like every RS minion.
class RS_DFlareMind2 : Actor
{
	Default { Radius 4; Height 4; Speed 25; Damage 5; DamageType "Plasma";
		Projectile; +NOGRAVITY; RenderStyle "Add"; Alpha 0.9; Scale 0.5;
		SeeSound "weapons/plasmaf"; DeathSound "weapons/plasmax";
		Translation "16:47=%[0.00,0.34,0.34]:[0.00,2.00,2.00]",
		            "160:255=%[0.00,0.34,0.34]:[0.00,2.00,2.00]"; }
	States
	{
	Spawn:
		PLSS AB 3 Bright;
		Loop;
	Death:
		PLSE ABCDE 4 Bright;
		Stop;
	}
}
class RS_MiniSentinelSpider : Actor
{
	Default { Health 40; PainChance 255; Speed 28; FloatSpeed 4;
		Radius 12; Height 26; Mass 300; Species "MMind";
		Monster;
		+NOGRAVITY +DROPOFF +NOBLOOD +NOBLOCKMONST +INCOMBAT MissileChanceMult 0.5;
		+LOOKALLAROUND +NEVERRESPAWN +DONTHARMSPECIES +NOINFIGHTSPECIES
		-COUNTKILL
		DeathSound "Crack/death"; PainSound "prox/beep";
		Obituary "%o was vaporized by a mini sentinel";
		Tag "Mini Sentinel";
		Translation "16:47=%[0.00,0.34,0.34]:[0.00,2.00,2.00]",
		            "160:255=%[0.00,0.34,0.34]:[0.00,2.00,2.00]"; }
	States
	{
	Spawn:
		MNDR A 10;
		Goto See;
	See:
		MNDR A 1 A_SentinelBob;
		MNDR A 2 A_Chase;
		Loop;
	Missile:
		MNDR A 4 A_FaceTarget;
		MNDR B 1 Bright A_SpawnProjectile("RS_DFlareMind2", 15, 0, 0);
		MNDR B 1 Bright A_SpawnProjectile("RS_DFlareMind2", 15, 0, random(-3, 3));
		MNDR B 1 Bright A_SpawnProjectile("RS_DFlareMind2", 15, 0, random(-9, 9));
		MNDR A 4;
		Goto See;
	Pain:
		MNDR A 5 A_Pain;
		Goto See;
	Death:
		MNDR C 7 Bright A_Fall;
		MNDR D 5 Bright A_Scream;
		MNDR E 5 Bright;
		MNDR F 5 Bright;
		MNDR G 5 Bright;
		MNDR HI 5 Bright;
		Stop;
	}
}
