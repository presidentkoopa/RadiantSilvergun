// ----------------------------------------------------------------------------
// ARACHNOTRON WHITE EX -- "WHITE HOT SPIDER" (HP9500). CHPLUS 12_WX. A fire/heat raid
//   boss: boil-bolts, gravity firebombs, the KRAKATOA mega-blast, seeking white-hot
//   shots, and white-hot flare sprays. LMWX/WSPX body. Derives HF_Arachnotron. Phase-2 <5000.
// ----------------------------------------------------------------------------
class HF_WhiteArachnotronEX : HF_Arachnotron
{
	override string MonIdentity() { return "class:arachnotron species:spider role:miniboss trait:ex trait:fire faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	Default
	{
		Health 9500;
		GibHealth -950;
		Radius 70;
		Height 70;
		Mass 1000;
		Speed 14;
		PainChance 24;
		Monster;
		+BOSS +MISSILEMORE +FLOORCLIP +BOSSDEATH
		Species "WhiteSP";
		SeeSound "baby/sight";
		PainSound "baby/pain";
		DeathSound "baby/death";
		ActiveSound "baby/active";
		Obituary "$OB_WHITEARACHEX";
		Tag "White Hot Spider";
	}

	States
	{
	Spawn:
		LMWX AB 10 A_Look;
		Loop;
	See:
		LMWX A 20 A_BabyMetal;
		LMWX ABBCCD 3 A_Chase;
		Loop;
	Missile:
		LMWX A 0 A_JumpIfHealthLower(5000,"Missile.Phase2");
		LMWX A 0 A_JumpIfCloser(450,"Missile.Krakatoa");
		LMWX A 0 A_Jump(256,"Missile.Boil","Missile.Firebomb","Missile.Seek","Missile.Flare");
		Goto See;
	Missile.Boil:
		LMWX A 8 Bright A_FaceTarget;
		LMWX G 4 Bright A_CustomMissile("HF_BoilBoltL9",0,0,random(-6,6));
		LMWX G 4 Bright A_CustomMissile("HF_BoilBoltL9",0,0,random(-6,6));
		LMWX G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Firebomb:
		LMWX A 8 Bright A_FaceTarget;
		LMWX G 5 Bright A_CustomMissile("HF_FireBombL9",0,-6,random(-5,5));
		LMWX G 5 Bright A_CustomMissile("HF_FireBombL9",0,6,random(-5,5));
		LMWX G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Seek:
		LMWX A 8 Bright A_FaceTarget;
		LMWX G 4 Bright A_CustomMissile("HF_SPWHIL9",0,0,random(-5,5));
		LMWX G 4 Bright A_CustomMissile("HF_SPWHIL9",0,0,random(-5,5));
		LMWX G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Flare:
		LMWX A 6 Bright A_FaceTarget;
		LMWX GGGGGGGG 1 Bright A_CustomMissile("HF_WhiteHotFlareL9",0,0,random(-12,12));
		LMWX G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Krakatoa:
		LMWX A 12 Bright A_FaceTarget;
		LMWX G 0 A_PlaySound("weapons/bfgf");
		LMWX G 10 Bright A_CustomMissile("HF_KrakatoaL9",0,0,0);
		LMWX G 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Phase2:
		LMWX A 0 A_ChangeFlag("MISSILEEVENMORE",true);
		LMWX A 8 Bright A_FaceTarget;
		LMWX G 5 Bright A_CustomMissile("HF_KrakatoaL9",0,0,0);
		LMWX GGGG 2 Bright A_CustomMissile("HF_WhiteHotFlareL9",0,0,random(-10,10));
		LMWX G 4 Bright A_CustomMissile("HF_SPWHIL9",0,0,random(-8,8));
		LMWX G 4 Bright A_CustomMissile("HF_FireBombL9",0,0,random(-6,6));
		LMWX G 6 A_MonsterRefire(48,"See");
		Goto See;
	Pain:
		LMWX H 3; LMWX H 3 A_Pain;
		Goto See;
	Death:
		LMWX I 20 A_Scream;
		LMWX J 7 A_NoBlocking;
		LMWX KL 7;
		LMWX M -1 A_BossDeath;
		Stop;
	}
}
