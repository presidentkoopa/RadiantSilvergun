// ----------------------------------------------------------------------------
// BLACK MANCUBUS EX -- "Shadow Beast EX" (HP18000). CH BlackFatsoEX. The shadow beast
//   cranked up: buffed poison/plasma balls, weaving big bombs, a poison burp, long-range
//   shots, breath at close range, and a phase-2 enrage (<5500HP, +speed). BDEM body.
//   Derives HF_Mancubus. Bombs use A_Weave (pattern #3) for the weaving approach.
// ----------------------------------------------------------------------------
class HF_BlackMancubusEX : HF_Mancubus
{
	override string MonIdentity() { return "class:mancubus species:mancubus role:miniboss trait:ex trait:projectile faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	Default
	{
		Health 18000;
		GibHealth -1800;
		Radius 54;
		Height 70;
		Mass 1600;
		Speed 12;
		PainChance 24;
		Monster;
		+BOSS +MISSILEMORE +FLOORCLIP +BOSSDEATH
		SeeSound "fatso/sight";
		PainSound "fatso/pain";
		DeathSound "fatso/death";
		ActiveSound "fatso/active";
		Obituary "$OB_BLACKMANCEX";
		Tag "Shadow Beast EX";
	}

	States
	{
	Spawn:
		BDEM AB 15 A_Look;
		Loop;
	See:
		BDEM AABBCCDDEEFF 4 A_Chase;
		Loop;
	Missile:
		BDEM A 0 A_JumpIfHealthLower(5500,"Missile.Phase2");
		BDEM A 0 A_JumpIfCloser(500,"Missile.Breath");
		BDEM A 0 A_Jump(256,"Missile.BigBombs","Missile.Weave","Missile.Long");
		Goto See;
	Missile.BigBombs:
		BDEM G 12 A_FatRaise;
		BDEM H 8 Bright A_FaceTarget;
		BDEM H 6 Bright A_CustomMissile("HF_ShadowBombBigEX",32,0,0);
		BDEM H 4 Bright A_CustomMissile("HF_ShadowSplash",24,0,random(-12,12));
		BDEM H 4 Bright A_CustomMissile("HF_ShadowSplash",24,0,random(-12,12));
		BDEM IG 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Weave:
		BDEM G 10 A_FatRaise;
		BDEM H 5 Bright A_FaceTarget;
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBeast_Ballex1",32,0,random(-8,8));
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBeast_Ballex2",32,0,random(-8,8));
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBeast_Ballex3",32,0,random(-8,8));
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBeast_BallFireEX",32,0,0);
		BDEM IG 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Long:
		BDEM G 10 A_FatRaise;
		BDEM H 6 Bright A_CustomMissile("HF_BlackFatShotLongRange",32,0,-4);
		BDEM H 6 Bright A_CustomMissile("HF_BlackFatShotLongRange",32,0,4);
		BDEM H 6 Bright A_CustomMissile("HF_BlackFatShotLongRange",32,0,0);
		BDEM IG 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Breath:
		BDEM G 8 A_FatRaise;
		BDEM HHHHHHHH 2 Bright A_CustomMissile("HF_BlackFatsoBurp",32,0,random(-14,14));
		BDEM IG 6 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Phase2:
		BDEM A 0 A_ChangeFlag("MISSILEEVENMORE",true);
		BDEM A 0 A_SetSpeed(21);
		BDEM A 0 A_JumpIfCloser(500,"Missile.Breath");
		BDEM G 8 A_FatRaise;
		BDEM H 5 Bright A_FaceTarget;
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBombBigEX",32,0,random(-6,6));
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBeast_Ballex2",32,0,random(-10,10));
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBeast_Ballex3",32,0,random(-10,10));
		BDEM H 4 Bright A_CustomMissile("HF_ShadowBeast_BallFireEX",32,0,random(-10,10));
		BDEM IG 6 A_MonsterRefire(48,"See");
		Goto See;
	Pain:
		BDEM J 3; BDEM J 3 A_Pain;
		Goto See;
	Death:
		BDEM K 6;
		BDEM L 6 A_Scream;
		BDEM M 6;
		BDEM N 6 A_NoBlocking;
		BDEM OPQR 6;
		BDEM S -1 A_BossDeath;
		Stop;
	}
}
