// ----------------------------------------------------------------------------
// BLACK CACO EX -- "Hades Incarnate" (HP10000). CH BlackCacoEX. An enhanced Hades
//   caco raid boss: drifting shades, eye-beams, buffed hades-ball barrages, floor
//   bolts, phase-2 enrage (<6500HP). Reuses the Black Caco's Hades DNA (HF_HadesBall
//   family, HF_EyeBeamCaco, HF_HadesBolt, HF_HadeLoad1). RedSpikeCacoEX summon folded.
//   Derives HF_Caco. uservars -> member ints.
// ----------------------------------------------------------------------------

class HF_HadesBallEX2 : HF_HadesBall { Default { Damage 50; Speed 18; } }
class HF_HadesBallEX3 : HF_HadesBall { Default { Damage 35; Speed 10; Radius 12; Height 8; Scale 1.4; } }
class HF_BlackCacoEXShade : Actor
{
	// drifting shade the EX trails (CH cosmetic-ish drifter; here lightly damaging)
	Default { Radius 20; Height 16; Speed 4; Damage 12; DamageType "Plasma"; Projectile; +FLOAT; +FLOATBOB; +NOGRAVITY; +SEEKERMISSILE;
		RenderStyle "Translucent"; Alpha 0.4; Scale 1.2; Translation "0:255=%[0.10,0.10,0.10]:[0.40,0.40,0.40]"; }
	States { Spawn: HELE AB 6 A_SeekerMissile(1,2); Loop; Death: HELE CD 6 A_FadeOut(0.2); Stop; }
}

class HF_BlackCacoEX : HF_Caco
{
	override string MonIdentity() { return "class:cacodemon species:caco role:miniboss trait:ex trait:projectile faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	int exDO;    // phase-2 latch (User_DO2)

	Default
	{
		Health 10000;
		GibHealth -1000;
		Radius 40;
		Height 70;
		Mass 1000;
		Speed 14;
		FloatSpeed 6;
		PainChance 30;
		Monster;
		+FLOAT +NOGRAVITY +BOSS +MISSILEMORE +DONTHARMSPECIES
		Species "Caco";
		SeeSound "caco/sight";
		PainSound "caco/pain";
		DeathSound "caco/death";
		ActiveSound "monster/helact";
		Obituary "$OB_BLACKCACOEX";
		Tag "Black Cacodemon EX";
	}

	override void PostBeginPlay() { Super.PostBeginPlay(); exDO = 0; }

	States
	{
	Spawn:
		HELE A 10 A_Look;
		Loop;
	See:
		HELE A 3 A_Chase;
		Loop;
	Missile:
		TNT1 AAA 0 A_SpawnItemEx("HF_BlackCacoEXShade",0,0,random(22,44),random(-1,1),0,random(-1,1),random(160,200),SXF_NOCHECKPOSITION);
		HELE A 0 A_JumpIfHealthLower(6500,"Missile.Phase2");
		HELE A 0 A_Jump(256,"Missile.Beam","Missile.Balls","Missile.Bolts","Missile.Bald");
		Goto See;
	Missile.Beam:
		HELE B 8 Bright A_FaceTarget;
		HELE C 0 A_SpawnItemEx("HF_HadeLoad1",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION);
		HELE C 0 A_PlaySound("Crack/see");
		HELE D 6 Bright A_CustomMissile("HF_EyeBeamCaco",0,8,0);
		HELE D 4 Bright A_CustomMissile("HF_EyeBeamCaco",0,-8,0);
		HELE D 4 Bright A_CustomMissile("HF_EyeBeamCaco",0,0,0);
		HELE B 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Balls:
		HELE B 6 A_FaceTarget;
		HELE D 4 Bright A_CustomMissile("HF_HadesBallEX2",0,0,random(-6,6));
		HELE D 4 Bright A_CustomMissile("HF_HadesBallEX3",0,0,random(-10,10));
		HELE D 4 Bright A_CustomMissile("HF_HadesBall2",0,0,random(-4,4));
		HELE B 6 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Bolts:
		HELE B 6 A_FaceTarget;
		HELE D 4 Bright A_CustomMissile("HF_HadesBolt",0,0,0);
		HELE D 4 Bright A_CustomMissile("HF_HadesBolt",0,0,20,CMF_ABSOLUTEANGLE);
		HELE D 4 Bright A_CustomMissile("HF_HadesBolt",0,0,-20,CMF_ABSOLUTEANGLE);
		HELE D 4 Bright A_CustomMissile("HF_HadesBolt",0,0,40,CMF_ABSOLUTEANGLE);
		HELE D 4 Bright A_CustomMissile("HF_HadesBolt",0,0,-40,CMF_ABSOLUTEANGLE);
		HELE B 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Bald:
		HELE B 6 A_FaceTarget;
		HELE DDDDDD 2 Bright A_CustomMissile("HF_HadesBallEX2",0,0,random(-12,12));
		HELE B 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Phase2:
		HELE A 0 A_ChangeFlag("MISSILEEVENMORE",true);
		HELE A 0 A_SetSpeed(42);
		HELE BC 8 A_FaceTarget;
		HELE D 8 A_PlaySound("monster/helsit");
		HELE DDDD 6 A_CustomMissile("HF_HadesBallEX2",0,0,random(-18,18));
		HELE D 0 A_CustomMissile("HF_EyeBeamCaco",0,8,0);
		HELE D 0 A_CustomMissile("HF_EyeBeamCaco",0,-8,0);
		HELE C 6 A_CustomMissile("HF_HadesBolt",0,0,random(0,360),CMF_ABSOLUTEANGLE);
		HELE C 6 A_CustomMissile("HF_HadesBolt",0,0,random(0,360),CMF_ABSOLUTEANGLE);
		HELE B 8 A_MonsterRefire(48,"See");
		Goto See;
	Pain:
		HELE E 3; HELE E 3 A_Pain;
		Goto See;
	Death:
		HELE G 8;
		HELE H 8 A_Scream;
		HELE IJ 8;
		HELE K 8 A_NoBlocking;
		HELE L -1 A_SetFloorClip;
		Stop;
	}
}
