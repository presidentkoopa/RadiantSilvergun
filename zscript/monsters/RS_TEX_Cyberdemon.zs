// ----------------------------------------------------------------------------
// OBSIDIAN TYRANT -- the Cyberdemon apex (HP 24000). CHPLUS 17_KX. An enhanced
//   Smith-demon raid boss: a teleport-reposition mechanic (goes invulnerable +
//   phases away when cornered), 3 phases (full -> 14000 -> 4000 HP), and a heavy
//   hammer melee. Attacks: HellShotCombo, FlameBlast, HomingHell, LightningCall,
//   BigHell, plus a penta-heal. Shares the Smith-demon projectile DNA with the
//   regular Black Cyberdemon (PentaLine/MolochQuake/ZappersCB/STracer/SmithDFSpawner).
//   uservars -> ZScript member ints. Portal-summons folded (flagged for cosmetic/
//   gameplay review like the Black cyber's). Builds on HF_Cyberdemon chassis.
// ----------------------------------------------------------------------------

// new EX projectiles (the enhanced Smith-fire family). Damage->constants.
class HF_HSFlameBlastTrail : Actor
{
	Default { +NOINTERACTION; RenderStyle "Add"; Alpha 0.6; Scale 1.2; }
	States { Spawn: CFFX NOPQ 3 Bright A_FadeOut(0.15); Stop; }
}
class HF_HellShotEX : Actor
{
	Default { Radius 8; Height 12; Speed 30; Damage 80; Projectile; RenderStyle "Add"; DamageType "Fire"; Alpha 0.95;
		SeeSound "weapons/firbfi"; DeathSound "weapons/hellex"; +THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		HEPA ABCDEF 3 Bright A_SpawnItemEx("HF_RedPuff2",0,0,0,0,0,0,0,8);
		Loop;
	Death:
		HELX A 3 Bright A_Explode(50,160);
		HELX B 0 A_CustomMissile("HF_STracer",0,0,0,CMF_AIMDIRECTION,random(0,360));
		HELX B 0 A_CustomMissile("HF_STracer",0,0,120,CMF_ABSOLUTEANGLE);
		HELX B 0 A_CustomMissile("HF_STracer",0,0,240,CMF_ABSOLUTEANGLE);
		HELX C 3 Bright;
		Stop;
	}
}
class HF_HSFlameBlast : FastProjectile
{
	Default { Radius 8; Height 12; Speed 72; Damage 30; Scale 1.5; Projectile; RenderStyle "Add"; DamageType "Fire"; Alpha 0.95;
		SeeSound "weapons/hellfi"; DeathSound "weapons/firbfi"; +THRUGHOST; Decal "Scorch"; }
	States
	{
	Spawn:
		CFFX N 1 Bright A_SpawnItemEx("HF_HSFlameBlastTrail",-10,0,0,0,0,0,0,128);
		Loop;
	Death:
		CFFX ABCDE 3 Bright A_Explode(20,96);
		Stop;
	}
}
class HF_HSHomer : Actor
{
	Default { Radius 8; Height 12; Speed 22; Damage 50; Projectile; RenderStyle "Add"; DamageType "Fire"; Alpha 0.95;
		SeeSound "weapons/hellfi"; DeathSound "weapons/hellex"; +THRUGHOST; +SEEKERMISSILE; +EXTREMEDEATH; Decal "Scorch"; }
	States
	{
	Spawn:
		MSP2 A 2 Bright A_SpawnItemEx("HF_RedPuff2",0,0,0,0,0,0,0,8);
		MSP2 A 0 A_SeekerMissile(25,25,SMF_PRECISE);
		MSP2 B 2 Bright A_SpawnItemEx("HF_RedPuff2",0,0,0,0,0,0,0,8);
		MSP2 B 0 A_SeekerMissile(25,25,SMF_PRECISE);
		Loop;
	Death:
		HELX ABC 4 Bright A_Explode(40,128);
		Stop;
	}
}
class HF_ZapCybEX : Actor
{
	Default { Radius 17; Height 15; Speed 32; Damage 35; Projectile; RenderStyle "Add"; Alpha 0.85; Scale 1.6;
		SeeSound "Litn/litn2"; +THRUGHOST; +SEEKERMISSILE; +USEBOUNCESTATE; BounceType "Hexen"; BounceCount 5; BounceFactor 2; WallBounceFactor 2;
		Translation "192:199=[255,255,255]:[191,0,255]"; Decal "Scorch"; }
	States
	{
	Spawn:
		LITN B 0 A_SeekerMissile(5,10,SMF_PRECISE);
		LITN B 2 Bright A_SpawnItemEx("HF_Zap88",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		LITN CDEFG 2 Bright;
		Loop;
	Bounce:
		LITN B 2 Bright A_SeekerMissile(5,10,SMF_PRECISE);
		Goto Spawn;
	Death:
		LITN GOP 3 Bright A_Explode(35,96);
		Stop;
	}
}
class HF_PentaHealCybEX2 : Actor
{
	Default { Radius 0; Height 32; Speed 16; RenderStyle "None"; Projectile; +FLOORHUGGER; +NOCLIP; }
	States { Spawn: TNT1 AAAAAAAAAAAA 1 A_SpawnItem("HF_PentaFire",0,0); Stop; }
}
class HF_PentaHealCybEX : Actor
{
	Default { Radius 0; Height 32; Speed 200; Alpha 0.85; Projectile; +FLOORHUGGER; +NOCLIP; }
	States
	{
	Spawn:
		TNT1 A 1;
		TNT1 A 0 A_PlaySound("Ice/Cast");
		TNT1 A 0 A_CustomMissile("HF_PentaHealCybEX2",0,0,-198,2);
		TNT1 A 0 A_CustomMissile("HF_PentaHealCybEX2",0,0,198,2);
		Stop;
	}
}

class HF_ObsidianTyrant : HF_Cyberdemon
{
	override string MonIdentity() { return "class:cyberdemon species:cyberdemon role:miniboss trait:ex trait:teleport trait:projectile faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	int tyReady;   // intro (User_Supersmith)
	int tyOH;      // phase-2 portal latch (User_OH1)
	int tyCool;    // reposition cooldown (User_DumDum)

	Default
	{
		Health 24000;
		GibHealth -2400;
		Radius 40;
		Height 110;
		Speed 20;
		PainChance 12;
		Mass 0x7FFFFFFF;
		Monster;
		MinMissileChance 140;
		+BOSS
		+MISSILEMORE
		+MISSILEEVENMORE
		+FLOORCLIP
		+NORADIUSDMG
		+DONTMORPH
		+NOPAIN
		SeeSound "cyber/sight";
		PainSound "cyber/pain";
		DeathSound "cyber/death";
		ActiveSound "cyber/active";
		Obituary "$OB_OBSIDIANTYRANT";
		Tag "Obsidian Tyrant";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		tyReady = 0; tyOH = 0; tyCool = 0;
		bDontThrust = true;
	}

	States
	{
	Spawn:
		HSMI AB 10 A_Look;
		Loop;
	See:
		HSMI A 0 A_ChangeFlag("THRUACTORS",false);
		HSMI A 0 A_UnSetReflectiveInvulnerable;
		HSMI A 0 A_SetSpeed(20);
		HSMI A 0 A_CheckBlock("Reposition",CBF_NOLINES);
		HSMI A 0 A_PlaySound("cyber/hoof",CHAN_5);
		HSMI AABB 3 A_Chase;
		HSMI C 0 A_PlaySound("cyber/hoof",CHAN_6);
		HSMI CCDD 3 A_Chase;
		HSMI D 0 A_Jump(2,"Reposition");
		Loop;
	Reposition:
		HSMI O 0 A_ChangeFlag("NOPAIN",true);
		HSMI O 6 A_QuakeEx(6,6,6,100,2,64);
		HSMI O 0 A_SetInvulnerable;
		HSMI O 1 A_SetTranslucent(0.5);
		HSMI O 1 A_SetTranslucent(0.2);
		HSMI O 1 A_SetTranslucent(0);
		HSMI O 0 A_ChangeFlag("FLOAT",true);
		HSMI O 0 A_ChangeFlag("THRUACTORS",true);
		HSMI O 0 A_SetSpeed(99);
		HSMI OOOOOOOOOOOO 1 A_Wander;
		HSMI O 0 A_ChangeFlag("FLOAT",false);
		HSMI O 0 A_ChangeFlag("THRUACTORS",false);
		HSMI O 0 A_SetSpeed(20);
		HSMI O 1 A_SetTranslucent(0.3);
		HSMI O 1 A_SetTranslucent(0.6);
		HSMI O 1 A_SetTranslucent(1);
		HSMI O 0 A_UnSetInvulnerable;
		HSMI O 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	Melee:
		HSMI L 0 A_SetSpeed(20);
		HSMI L 3 A_FaceTarget;
		HSMI M 0 A_PlaySound("monster/hamswg");
		HSMI M 3 A_FaceTarget;
		HSMI N 3 A_CustomMeleeAttack(random(100,250),"monster/hamhit");
		HSMI L 4;
		Goto See;
	Missile:
		HSMI A 0 A_JumpIfHealthLower(4000,"Missile.Rage");
		HSMI A 0 A_JumpIfHealthLower(14000,"Missile.Mid");
		HSMI A 0 A_JumpIfCloser(650,"Melee");
		HSMI A 0 A_UnSetReflectiveInvulnerable;
		HSMI A 0 A_PlaySound("hellsmith/laugh",CHAN_7,1,0,0.6);
		HSMI A 0 A_Jump(256,"Missile.HellCombo","Missile.Lightning","Missile.Homing","Missile.FlameBlast");
		Goto See;
	Missile.Mid:
		HSMI A 0 A_UnSetReflectiveInvulnerable;
		HSMI A 0 A_PlaySound("hellsmith/laugh",CHAN_7,1,0,0.6);
		HSMI A 0 A_Jump(96,"Missile.BigHell","Missile.Lightning");
		HSMI A 0 A_Jump(256,"Missile.HellCombo","Missile.Homing","Missile.FlameBlast","Missile.Penta");
		Goto See;
	Missile.Rage:
		HSMI A 0 A_ChangeFlag("MISSILEEVENMORE",true);
		HSMI A 0 A_PlaySound("hellsmith/laugh",0,255,0,0);
		HSMI A 0 A_Jump(120,"Missile.HealUp","Missile.BigHell");
		HSMI A 0 A_Jump(256,"Missile.HellCombo","Missile.Lightning","Missile.Homing","Missile.FlameBlast","Missile.Penta");
		Goto See;
	Missile.HellCombo:
		HSMI G 6 A_FaceTarget;
		HSMI G 0 A_PlaySound("weapons/firbfi");
		HSMI H 4 Bright A_CustomMissile("HF_HellShotEX",52,-9,random(-3,3));
		HSMI G 4 A_FaceTarget;
		HSMI H 4 Bright A_CustomMissile("HF_HellShotEX",52,-9,random(-6,6));
		HSMI G 4 A_FaceTarget;
		HSMI H 4 Bright A_CustomMissile("HF_HellShotEX",52,-9,random(-3,3));
		HSMI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.FlameBlast:
		HSMI G 6 A_FaceTarget;
		HSMI G 0 A_PlaySound("weapons/hellfi");
		HSMI HHHHHHHH 2 Bright A_CustomMissile("HF_HSFlameBlast",52,-9,random(-7,7));
		HSMI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Homing:
		HSMI G 6 A_FaceTarget;
		HSMI H 4 Bright A_CustomMissile("HF_HSHomer",52,-9,random(-4,4));
		HSMI H 4 Bright A_CustomMissile("HF_HSHomer",52,-9,random(-4,4));
		HSMI H 4 Bright A_CustomMissile("HF_HSHomer",52,-9,random(-4,4));
		HSMI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Lightning:
		HSMI G 6 A_FaceTarget;
		HSMI G 0 A_PlaySound("Litn/litn2");
		HSMI H 4 Bright A_CustomMissile("HF_ZapCybEX",52,-9,random(-8,8));
		HSMI H 4 Bright A_CustomMissile("HF_ZapCybEX",52,-9,random(-8,8));
		HSMI H 0 A_SpawnItemEx("HF_ZappersCB",random(-32,32),random(-32,32),64,0,0,0,0,SXF_NOCHECKPOSITION);
		HSMI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.BigHell:
		HSMI G 8 A_FaceTarget;
		HSMI G 0 A_PlaySound("weapons/hellex");
		HSMI H 8 Bright A_CustomMissile("HF_BigHellshot",52,-9,0);
		HSMI H 0 A_SpawnItemEx("HF_SmithDFSpawner",random(-128,128),random(-128,128),8,0,0,0,0,SXF_NOCHECKPOSITION);
		HSMI G 10 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Penta:
		HSMI G 8 A_FaceTarget;
		HSMI G 0 A_PlaySound("weapons/diasht");
		HSMI H 4 Bright A_CustomMissile("HF_PentaLine1",2,0,0);
		HSMI H 4 Bright A_CustomMissile("HF_PentaLine1",2,0,72,CMF_ABSOLUTEANGLE);
		HSMI H 4 Bright A_CustomMissile("HF_PentaLine1",2,0,144,CMF_ABSOLUTEANGLE);
		HSMI H 4 Bright A_CustomMissile("HF_PentaLine1",2,0,216,CMF_ABSOLUTEANGLE);
		HSMI H 4 Bright A_CustomMissile("HF_PentaLine1",2,0,288,CMF_ABSOLUTEANGLE);
		HSMI H 0 A_CustomMissile("HF_MolochQuake",8,0,0);
		HSMI G 10 A_MonsterRefire(40,"See");
		Goto See;
	Missile.HealUp:
		HSMI G 8 A_FaceTarget;
		HSMI G 0 A_PlaySound("Ice/Cast");
		HSMI H 6 Bright A_CustomMissile("HF_PentaHealCybEX",2,0,0);
		HSMI H 6 Bright A_CustomMissile("HF_PentaHealCybEX",2,0,90,CMF_ABSOLUTEANGLE);
		HSMI H 6 Bright A_CustomMissile("HF_PentaHealCybEX",2,0,180,CMF_ABSOLUTEANGLE);
		HSMI H 6 Bright A_CustomMissile("HF_PentaHealCybEX",2,0,270,CMF_ABSOLUTEANGLE);
		HSMI H 0 A_GiveInventory("Health",1500);   // the EX self-heal
		HSMI G 12 A_MonsterRefire(40,"See");
		Goto See;
	Pain:
		HSMI G 6; HSMI G 6 A_Pain;
		Goto See;
	Death:
		HSMI I 10 A_Scream;
		HSMI JKL 10;
		HSMI M 8 A_NoBlocking;
		HSMI NO 8;
		HSMI O -1;
		Stop;
	}
}
