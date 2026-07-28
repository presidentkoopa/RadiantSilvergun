// ----------------------------------------------------------------------------
// SMOKING BLACK IMP EX -- the imp apex. A relentless artillery miniboss:
//   OneShot (escalating weave-ball barrage), BigShot (charge -> EffectHK lasers ->
//   BigOne artillery), SpamShotRain (bouncing-ball storm), Kamehameha (charged
//   railgun beam), Smokeout (vile-target smoke AOE), and a Warp dodge on pain.
//   Trails death-breath smoke constantly (which heals nearby HF_Imps -- inherited).
// ----------------------------------------------------------------------------


class HF_BlackImpEX : HF_Imp
{
	override string MonIdentity() { return "class:imp species:imp role:miniboss trait:ex trait:projectile faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	Default
	{
		Health 8600;
		GibHealth -860;
		Radius 20;
		Height 56;
		Speed 14;
		PainChance 28;
		XScale 1.15;
		YScale 1.15;
		Mass 4000;
		Monster;
		+BOSS
		+MISSILEMORE
		+NORADIUSDMG
		+DONTHARMSPECIES
		+FLOORCLIP
		-MISSILEEVENMORE
		SeeSound "agaures/sight";
		PainSound "agaures/pain";
		DeathSound "agaures/death";
		ActiveSound "agaures/active";
		MeleeSound "agaures/scratch";
		Obituary "$OB_BLACKIMPEX";
		Tag "Smoking Black Imp EX";
	}

	// EX is a fixed miniboss: it does not ride the tier dial. Lock to a high tier
	// for tint, but its states are bespoke (below), not the dial's per-color blocks.
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		bDontThrust = true;
	}

	States
	{
	Spawn:
		AGUR AB 10 A_Look;
		Loop;
	See:
		AGUR AA 3 A_Chase;
		AGUR YYY 0 A_SpawnItemEx("HF_DeathBreathDI", -1, random(-18,18), random(2,32), random(1,5), 0, 1, random(90,270));
		AGUR BB 3 A_Chase;
		AGUR YYY 0 A_SpawnItemEx("HF_DeathBreathDI", -2, random(-18,18), random(2,32), random(1,5), 0, 2, random(90,270));
		AGUR CC 3 A_Chase;
		AGUR DD 3 A_Chase;
		AGUR YYY 0 A_SpawnItemEx("HF_DeathBreathDI", -4, random(-18,18), random(2,32), random(1,5), 0, 4, random(90,270));
		Loop;
	Melee:
		AGUR W 6 A_FaceTarget;
		AGUR X 6 A_FaceTarget;
		AGUR Y 6 A_CustomMeleeAttack(random(20,95),"agaures/swing","none");
		AGUR A 0 A_SpawnItemEx("HF_DeathBreathDI", random(-118,118), random(-118,118), random(-6,32), 0,0,0,0,128,0);
		AGUR Y 0 A_Jump(88,"Missile");
		Goto See;
	Missile:
		AGUR A 0 A_SpawnItemEx("HF_DeathBreathDI", random(-88,88), random(-88,88), random(-6,27), random(1,9), 0, 1, random(-359,359));
		AGUR A 0 A_JumpIfCloser(1300,"Choice");
		AGUR A 0 A_Jump(256,"Kamehameha","Smokeout");
		Goto See;
	Choice:
		TNT1 A 0 A_Jump(256,"Kamehameha","Smokeout","OneShot","BigShot","SpamShotRain");
		Goto See;
	Kamehameha:
		AGUR W 2 A_PlaySound("agaures/sight",7,2,false,ATTN_NONE);
		AGUR W 2 Bright A_FaceTarget;
		AGUR A 0 A_SpawnItemEx("HF_BlackImpEXCharge", 1,32, 42);
		AGUR A 0 A_SpawnItemEx("HF_BlackImpEXCharge", 1,-32, 42);
		AGUR W 18 Bright;
		AGUR X 8 A_FaceTarget;
		AGUR Y 0 A_PlaySound("weapons/railgf",1);
		AGUR Y 9 Bright A_CustomRailgun(50,0,"none","none",RGF_NOPIERCING|RGF_SILENT,1,0,"none",0,0,0,0,0.4,1.0,"none",1);
		AGUR Y 16;
		AGUR YYY 0 A_SpawnItemEx("HF_DeathBreathDI", random(-118,118), random(-118,118), random(-6,32), random(1,9), 0, 1, random(-359,359));
		Goto See;
	Smokeout:
		AGUR Y 2;
		AGUR Y 2 A_FaceTarget;
		AGUR A 0 A_SpawnItemEx("HF_BlackImpEXCharge", 16,3, 32);
		AGUR A 0 A_SpawnItemEx("HF_BlackImpEXCharge", 16,-3, 32);
		AGUR Y 1 A_VileTarget("HF_BlackImpSmokeOut");
		AGUR YYY 2 Bright A_SpawnItemEx("HF_DeathBreathDI", -4, random(-18,18), random(2,32), random(1,5), 0, 1, random(90,270));
		AGUR YYYYYYYY 1 Bright A_SpawnItemEx("HF_DeathBreathDI", -4, random(-18,18), random(2,32), random(1,5), 0, 1, random(90,270));
		AGUR Y 3 Bright A_CheckSight("See");
		AGUR Y 9 Bright A_FaceTarget;
		AGUR Y 4 Bright A_VileTarget("HF_BlackImpSmokeOut");
		AGUR XW 6;
		Goto See;
	OneShot:
		AGUR EF 12 A_FaceTarget;
		AGUR GGGGGGGGGGGG 1 Bright A_CustomMissile("HF_BlackImpEXBall1", 42, 0, random(-30,30));
		AGUR G 0 A_FaceTarget;
		AGUR GGGGGGGGG 2 Bright A_CustomMissile("HF_BlackImpEXBall1", 42, 0, random(-15,15));
		AGUR G 0 A_FaceTarget;
		AGUR GGGGGG 3 Bright A_CustomMissile("HF_BlackImpEXBall1", 42, 0, random(-7,7));
		AGUR G 0 A_FaceTarget;
		AGUR GGG 4 Bright A_CustomMissile("HF_BlackImpEXBall1", 42, 0, random(-1,1));
		AGUR GF 6 A_Jump(24,"BigShot");
		Goto See;
	BigShot:
		AGUR E 12 Bright A_FaceTarget;
		AGUR A 0 A_SpawnItemEx("HF_BlackImpEXCharge", 1,32, 38);
		AGUR A 0 A_SpawnItemEx("HF_BlackImpEXCharge", 1,-32, 38);
		AGUR F 12 Bright A_FaceTarget;
		AGUR F 2 Bright A_CustomMissile("HF_EffectHK",28,0);
		AGUR F 2 Bright A_CustomMissile("HF_EffectHK",32,0);
		AGUR F 2 Bright A_CustomMissile("HF_EffectHK",36,0);
		AGUR G 1 Bright A_FaceTarget;
		AGUR G 8 Bright A_CustomMissile("HF_BlackImpEXBigOne", 64, 0, 0, 0, 0);
		AGUR G 4;
		AGUR A 10;
		Goto See;
	SpamShotRain:
		AGUR EF 8 A_FaceTarget;
		AGUR GGGGG 1 A_CustomMissile("HF_BlackImpEXBall2", random(70,90), 0, random(-15,15), 0, 0);
		AGUR GGGGGGG 0 A_CustomMissile("HF_BlackImpEXBall2", random(70,90), 0, random(-15,15), 0, 0);
		AGUR G 1 A_FaceTarget;
		AGUR GGGG 2 A_CustomMissile("HF_BlackImpEXBall2", random(70,90), 0, random(-10,10), 0, 0);
		AGUR G 1 A_FaceTarget;
		AGUR GGG 3 A_CustomMissile("HF_BlackImpEXBall2", random(70,90), 0, random(-5,5), 0, 0);
		AGUR GF 6 A_Jump(24,"BigShot");
		Goto See;
	Pain:
		AGUR H 2;
		AGUR YYYYYYYYY 0 A_SpawnItemEx("HF_DeathBreathDI",0, random(-18,18), random(2,32), random(3,8), 0, 1, random(-359,359));
		AGUR H 2 A_Pain;
		AGUR A 0 A_Jump(64,"Warp");
		Goto See;
	Warp:
		TNT1 A 0 A_ChangeFlag("NOPAIN",true);
		TNT1 A 0 A_SetSpeed(99);
		TNT1 AAAA 0 A_Wander;
		TNT1 AA 3 A_Wander;
		TNT1 AAAA 1 A_Wander;
		TNT1 A 0 A_SetSpeed(14);
		TNT1 A 0 A_ChangeFlag("NOPAIN",false);
		TNT1 AAAAAAAA 0 A_SpawnItemEx("HF_DeathBreathDI", 0, 0, random(1,6), random(3,15), 0, random(1,12), random(-359,359));
		Goto See;
	Death:
		AGUR I 12 A_Scream;
		AGUR J 12;
		AGUR KL 12;
		AGUR M 8 A_NoBlocking;
		AGUR NO 8;
		AGUR P -1;
		Stop;
	}
}