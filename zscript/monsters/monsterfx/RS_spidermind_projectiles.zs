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
		RED9 CDE 4 Bright A_Explode(27,64);
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
		RED9 CDE 4 Bright A_Explode(35,96);
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
		RED9 CDE 4 Bright A_Explode(45,64);
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
	States { Spawn: ZPWV D 6 Bright; Death: ZPWV E 8 Bright; Stop; }
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
		ZPWV E 8 Bright;
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
		RED9 CDE 5 Bright A_Explode(80,160);
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
		RED9 CDE 5 Bright A_Explode(80,128);
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
		SPER CDE 4 Bright A_Explode(40,96);
		Stop;
	}
}
