// ----------------------------------------------------------------------------
// T-800 BARON MK II -- the Hell Knight apex (HP 11000). A multi-phase raid boss:
//   intro zap-storm (user_ready) -> main fight (Mode1/Mode2 by distance) -> rage
//   phase under 5000 HP (user_rage), plus a Resistance defensive orbital-zap phase.
//   Attacks: FastBeam, Homing (seeking bruiser-missiles), DeathBeam (MegaRedRev),
//   BigMis (bruiser-missile salvos), MisBar (homing spread), NadeToss (hell-nades).
//   CHPLUS DECORATE uservars -> ZScript member ints (exUserReady / exUserRage).
// ----------------------------------------------------------------------------


class HF_BlackHKEX : HF_HellKnight
{
	override string MonIdentity() { return "class:hellknight species:hellknight role:miniboss trait:ex trait:projectile faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	int exUserReady;   // 0 until the intro zap-storm finishes, then 1
	int exUserRage;    // 0 until HP drops below 5000 (rage phase), then 1

	Default
	{
		Health 11000;
		GibHealth -1100;
		Radius 24;
		Height 64;
		Speed 14;
		PainChance 16;
		Mass 0x7FFFFFFF;
		Monster;
		+BOSS
		+MISSILEMORE
		+NORADIUSDMG
		+DONTHARMSPECIES
		+FLOORCLIP
		+NOPAIN
		SeeSound "monster/brusit";
		PainSound "monster/brupai";
		DeathSound "monster/brudth";
		ActiveSound "monster/bruact";
		Obituary "$OB_BLACKHKEX";
		Tag "T-800 Baron MK II";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		exUserReady = 0;
		exUserRage = 0;
		bDontThrust = true;
	}

	States
	{
	Spawn:
		KKEX AB 10 A_Look;
		Loop;
	See:
		TNT1 A 0 A_JumpIf(exUserReady >= 1, "See2");
		// intro zap-storm (runs once)
		KKEX E 8 A_FaceTarget;
		KKEX E 5 Bright A_CustomMissile("HF_ZapDecHKex",random(12,88),random(-20,20),0);
		KKEX E 4 A_CustomMissile("HF_ZapDecHKex",random(12,88),random(-20,20),0);
		KKEX E 3 Bright A_CustomMissile("HF_ZapDecHKex",random(12,88),random(-20,20),0);
		KKEX E 2 A_CustomMissile("HF_ZapDecHKex",random(12,88),random(-20,20),0);
		KKEX E 2 Bright A_CustomMissile("HF_ZapDecHKex",random(12,88),random(-20,20),0);
		KKEX E 1 { exUserReady = exUserReady + 1; }
		Goto See2;
	See2:
		KKEX A 0 A_PlaySound("BHKEXSTP",CHAN_6);
		KKEX AABB 3 A_Chase;
		KKEX C 0 A_PlaySound("BHKEXSTP",CHAN_7);
		KKEX CCDD 3 A_Chase;
		KKEX D 0 A_Jump(24,"Warp");
		Loop;
	Phase2:
		TNT1 A 0 A_JumpIf(exUserRage >= 1, "Nah");
		TNT1 A 0 A_SetSpeed(18);
		TNT1 A 0 A_ChangeFlag("MISSILEEVENMORE",true);
		KKEX E 6 Bright { exUserRage = exUserRage + 1; }
		KKEX EGGGG 2 Bright A_CustomMissile("HF_ZapDecHKex",random(12,88),random(-20,20),0);
		Goto See2;
	Nah:
		TNT1 A 0;
		Goto Missile.Pick;
	Melee:
	Missile:
		TNT1 A 0 A_JumpIfHealthLower(5000,"Phase2");
	Missile.Pick:
		KKEX E 8 A_FaceTarget;
		KKEX E 0 A_JumpIfCloser(500,"Mode2");
		KKEX E 0 A_JumpIfCloser(1500,"Mode1");
		TNT1 A 0 A_Jump(256,"Homing","DeathBeam","BigMis");
		Goto See2;
	Mode1:
		KKEX E 0 A_Jump(256,"BigMis","MisBar","NadeToss","DeathBeam","FastBeam");
		Goto See2;
	Mode2:
		KKEX E 0 A_Jump(256,"MisBar","FastBeam","NadeToss");
		Goto See2;
	FastBeam:
		KKEX E 0 A_PlaySound("prox/beep");
		KKEX E 3 Bright A_FaceTarget;
		KKEX S 0 A_CustomMissile("HF_BluCybFX",44,-18,0,0);
		KKEX S 3 Bright A_CustomMissile("HF_BluCybFX",44,18,0,0);
		KKEX S 1 Bright A_CustomMissile("HF_HKEXFastBeam",44,18,0,0);
		KKEX S 2 Bright A_CustomMissile("HF_HKEXFastBeam",44,-18,random(-14,14),0);
		KKEX S 2 Bright A_CustomMissile("HF_HKEXFastBeam",44,18,random(-14,14),0);
		KKEX S 2 Bright A_CustomMissile("HF_HKEXFastBeam",44,-18,random(-14,14),0);
		KKEX S 0 A_CheckSight("See2");
		KKEX E 2 Bright A_MonsterRefire(128,"See2");
		Goto FastBeam;
	Homing:
		KKEX E 9 Bright A_PlaySound("prox/beep");
		KKEX E 9 A_FaceTarget;
		KKEX E 9 Bright A_PlaySound("prox/beep");
		KKEX E 9 A_FaceTarget;
		KKEX R 0 A_CustomMissile("HF_BruiserMissileEx2",80,-18,0,0);
		KKEX R 9 Bright A_CustomMissile("HF_BruiserMissileEx2",80,18,0,0);
		KKEX E 6;
		Goto See2;
	DeathBeam:
		KKEX EE 9 A_FaceTarget;
		KKEX E 0 A_PlaySound("prox/beep");
		KKEX S 0 A_CustomMissile("HF_RedRevLoad",44,-18,random(-1,1),0);
		KKEX S 7 Bright A_CustomMissile("HF_RedRevLoad",44,18,random(-1,1),0);
		KKEX S 5 Bright A_FaceTarget;
		KKEX S 0 A_CustomMissile("HF_MegaRedRev",44,-18,random(-1,1),0);
		KKEX S 5 Bright A_CustomMissile("HF_MegaRedRev",44,18,random(-1,1),0);
		KKEX S 5 A_Jump(60,"BigMis");
		Goto See2;
	BigMis:
		KKEX S 0 A_PlaySound("prox/beep");
		KKEX S 0 A_CustomMissile("HF_BruiserMissileEx",46,-20,0,0);
		KKEX S 9 Bright A_CustomMissile("HF_BruiserMissileEx",46,20,0,0);
		KKEX S 0 A_CheckSight("See2");
		KKEX EE 7 A_FaceTarget;
		KKEX S 0 A_CustomMissile("HF_BruiserMissileEx",46,-20,random(-7,7),0);
		KKEX S 6 Bright A_CustomMissile("HF_BruiserMissileEx",46,20,random(-7,7),0);
		KKEX S 0 A_CheckSight("See2");
		KKEX EE 7 A_FaceTarget;
		KKEX S 0 A_CustomMissile("HF_BruiserMissileEx",46,-20,random(-17,17),0);
		KKEX S 6 Bright A_CustomMissile("HF_BruiserMissileEx",46,20,random(-17,17),0);
		KKEX S 0 A_Jump(64,"Homing");
		KKEX E 1 A_Jump(60,"MisBar");
		Goto See2;
	MisBar:
		KKEX F 2 Bright A_CustomMissile("HF_SpreadMisBarEX",44,-18,random(-5,5),CMF_OFFSETPITCH|CMF_SAVEPITCH,random(-1,1));
		KKEX F 2 Bright A_CustomMissile("HF_SpreadMisBarEX",44,18,random(-5,5),CMF_OFFSETPITCH|CMF_SAVEPITCH,random(-1,1));
		KKEX F 2 Bright A_CustomMissile("HF_SpreadMisBarEX",44,-18,random(-14,14),CMF_OFFSETPITCH|CMF_SAVEPITCH,random(-3,3));
		KKEX F 2 Bright A_CustomMissile("HF_SpreadMisBarEX",44,18,random(-14,14),CMF_OFFSETPITCH|CMF_SAVEPITCH,random(-3,3));
		KKEX F 2 Bright A_CustomMissile("HF_SpreadMisBarEX",44,-18,random(-14,14),CMF_OFFSETPITCH|CMF_SAVEPITCH,random(-3,3));
		KKEX F 2 Bright A_CustomMissile("HF_SpreadMisBarEX",44,18,random(-14,14),CMF_OFFSETPITCH|CMF_SAVEPITCH,random(-3,3));
		KKEX F 0 A_CheckSight("See2");
		KKEX EEE 5 A_FaceTarget;
		Goto See2;
	NadeToss:
		KKEX EG 7 A_FaceTarget;
		KKEX G 9 A_CustomMissile("HF_BaronHellNade",60,2,random(-9,9),0,random(3,12));
		KKEX G 1 A_Jump(42,"Missile");
		Goto See2;
	Warp:
		TNT1 A 0 A_ChangeFlag("NOPAIN",true);
		TNT1 A 0 A_SetSpeed(99);
		TNT1 AAAA 0 A_Wander;
		TNT1 AA 3 A_Wander;
		TNT1 AAAA 1 A_Wander;
		TNT1 A 0 A_SetSpeed(14);
		Goto See2;
	Death:
		KKEX H 8 A_Scream;
		KKEX I 8;
		KKEX JK 8;
		KKEX L 8 A_NoBlocking;
		KKEX MN 8;
		KKEX O -1;
		Stop;
	}
}