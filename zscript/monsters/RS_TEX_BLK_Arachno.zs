// ----------------------------------------------------------------------------
// ARACHNOTRON BLACK EX -- "Macross Missile Spam EX" (HP12000). CHPLUS 12_KX.
//   The black arachnotron cranked to 11: missile-swarm barrages (BBSP1 bursting into
//   homing SPMM swarms), spiral plasma shots, bubblegum bombs, EX lasers, and seeking
//   rockets. ARA7/KSPX body. Derives HF_Arachnotron. Phase-2 enrage <6000HP.
// ----------------------------------------------------------------------------
class HF_BlackArachnotronEX : HF_Arachnotron
{
	override string MonIdentity() { return "class:arachnotron species:spider role:miniboss trait:ex trait:missilespam faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	Default
	{
		Health 12000;
		GibHealth -1200;
		Radius 70;
		Height 70;
		Mass 1200;
		Speed 14;
		PainChance 30;
		Monster;
		+BOSS +MISSILEMORE +FLOORCLIP +BOSSDEATH
		Species "Spider1";
		SeeSound "baby/sight";
		PainSound "baby/pain";
		DeathSound "baby/death";
		ActiveSound "baby/active";
		Obituary "$OB_BLACKARACHEX";
		Tag "Macross Missile Spam EX";
	}

	States
	{
	Spawn:
		MSPI AB 10 A_Look;
		Loop;
	See:
		MSPI A 20 A_BabyMetal;
		MSPI ABBCCD 3 A_Chase;
		Loop;
	Missile:
		MSPI A 0 A_JumpIfHealthLower(6000,"Missile.Phase2");
		MSPI A 0 A_JumpIfCloser(500,"Missile.Close");
		MSPI A 0 A_Jump(256,"Missile.Swarm","Missile.Spiral","Missile.Lasers","Missile.Rockets");
		Goto See;
	Missile.Swarm:
		MSPI A 10 Bright A_FaceTarget;
		MSPI G 5 Bright A_CustomMissile("HF_BBSP1",0,0,random(-6,6));
		MSPI G 5 Bright A_CustomMissile("HF_BBSP1",0,0,random(-6,6));
		MSPI G 5 Bright A_CustomMissile("HF_BBSP1",0,0,random(-6,6));
		MSPI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Spiral:
		MSPI A 8 Bright A_FaceTarget;
		MSPI GGGGGGGG 2 Bright A_CustomMissile("HF_BlackSpideSpiralShot",0,0,random(-4,4));
		MSPI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Lasers:
		MSPI A 8 Bright A_FaceTarget;
		MSPI G 3 Bright A_CustomMissile("HF_ExSpideLaser1",0,-8,random(-3,3));
		MSPI G 3 Bright A_CustomMissile("HF_ExSpideLaser1",0,8,random(-3,3));
		MSPI G 3 Bright A_CustomMissile("HF_ExSpideLaser1",0,0,0);
		MSPI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Rockets:
		MSPI A 8 Bright A_FaceTarget;
		MSPI G 4 Bright A_CustomMissile("HF_SpRocket4EX",0,-6,random(-5,5));
		MSPI G 4 Bright A_CustomMissile("HF_SpRocket4EX",0,6,random(-5,5));
		MSPI G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Close:
		MSPI G 3 Bright A_CustomMissile("HF_BubblegumBombEXSpidie",0,0,random(-12,12));
		MSPI G 3 Bright A_CustomMissile("HF_BubblegumBombEXSpidie",0,0,random(-12,12));
		Goto See;
	Missile.Phase2:
		MSPI A 0 A_ChangeFlag("MISSILEEVENMORE",true);
		MSPI A 8 Bright A_FaceTarget;
		MSPI G 4 Bright A_CustomMissile("HF_BBSP1",0,0,random(-10,10));
		MSPI G 4 Bright A_CustomMissile("HF_BBSP1",0,0,random(-10,10));
		MSPI GGGG 2 Bright A_CustomMissile("HF_BlackSpideSpiralShot",0,0,random(-6,6));
		MSPI G 4 Bright A_CustomMissile("HF_SpRocket4EX",0,0,random(-8,8));
		MSPI G 6 A_MonsterRefire(48,"See");
		Goto See;
	Pain:
		MSPI H 3; MSPI H 3 A_Pain;
		Goto See;
	Death:
		MSPI I 20 A_Scream;
		MSPI J 7 A_NoBlocking;
		MSPI KL 7;
		MSPI M -1 A_BossDeath;
		Stop;
	}
}
