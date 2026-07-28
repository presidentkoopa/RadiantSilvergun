// ----------------------------------------------------------------------------
// BLACK REVENANT EX -- "Death Knight" (HP7500). CH BlackRevenantEX. A grappling
//   melee raid boss: hooks that yank, dart cleaves, sword/shield throws, bouncing
//   mines, and shield-blast bomb barrages. DKNT body. Derives HF_Revenant.
//   Loreshot-hook simplified to a fast melee projectile. uservars folded.
// ----------------------------------------------------------------------------


class HF_BlackRevHook : Actor
{
	Default { Radius 6; Height 6; Speed 42; Damage 22; Projectile; DamageType "Melee"; +THRUGHOST; +MTHRUSPECIES; SeeSound "monster/dknmsl"; DeathSound "weapons/boom1";
		RenderStyle "Add"; Alpha 0.85; Scale 0.5; Translation "0:255=%[0.10,0.10,0.10]:[0.50,0.50,0.50]"; }
	States { Spawn: BAL1 AB 2 Bright; Loop; Death: BAL1 CDE 3 Bright A_Explode(22,48); Stop; }
}
class HF_DKDart : Actor
{
	Default { Radius 3; Height 12; Speed 28; Damage 12; RenderStyle "Add"; DamageType "Fire"; Alpha 1.0; Projectile; +THRUGHOST; +MTHRUSPECIES;
		SeeSound "monster/dkndrt"; DeathSound "weapons/firex4"; }
	States { Spawn: MISL A 2 Bright; Loop; Death: MISL BCD 3 Bright A_Explode(12,48); Stop; }
}
class HF_ShieldBombRev : Actor
{
	Default { Radius 4; Height 6; Mass 5; Speed 34; Projectile; Scale 0.55; Damage 15; DamageType "Fire"; SeeSound "imp/attack"; DeathSound "weapons/firex4"; RenderStyle "Add"; }
	States { Spawn: MISL A 2 Bright; Loop; Death: MISL BC 3 Bright A_Explode(15,48); Stop; }
}
class HF_ShieldBlastRev : Actor
{
	Default { Radius 6; Height 8; Speed 12; Damage 35; DamageType "Fire"; Projectile; +SEEKERMISSILE; +MTHRUSPECIES; RenderStyle "Add"; Alpha 0.75; }
	States { Spawn: BAL1 AB 2 Bright A_SeekerMissile(3,3); Loop; Death: BAL1 CDE 4 Bright A_Explode(35,80); Stop; }
}
class HF_MinesRev : Actor
{
	Default { Radius 12; Height 12; Speed 24; Damage 25; RenderStyle "Translucent"; Alpha 0.95; Projectile; DamageType "Fire"; -NOGRAVITY; +BOUNCEONWALLS; +MTHRUSPECIES;
		BounceCount 4; BounceFactor 0.7; SeeSound "imp/attack"; DeathSound "weapons/rocklx"; }
	States { Spawn: MISL A 4 Bright; Loop; Death: MISL BCD 4 Bright A_Explode(40,96); Stop; }
}

class HF_BlackRevenantEX : HF_Revenant
{
	override string MonIdentity() { return "class:revenant species:revenant role:miniboss trait:ex trait:grapple trait:melee faction:hell set:hf"; }
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial

	Default
	{
		Health 7500;
		GibHealth -750;
		Radius 24;
		Height 60;
		Mass 600;
		Speed 14;
		PainChance 40;
		Monster;
		+BOSS +MISSILEMORE +FLOORCLIP
		SeeSound "skeleton/sight";
		PainSound "skeleton/pain";
		DeathSound "skeleton/death";
		ActiveSound "monster/dknact";
		Obituary "$OB_BLACKREVEX";
		Tag "Death Knight";
	}

	States
	{
	Spawn:
		DKNT AB 10 A_Look;
		Loop;
	See:
		DKNT ABCDEF 3 A_Chase;
		Loop;
	Melee:
		DKNT G 1 A_FaceTarget;
		DKNT H 6 A_SkelWhoosh;
		DKNT I 6 A_FaceTarget;
		DKNT J 6 A_CustomMeleeAttack(random(60,160),"skeleton/melee");
		Goto See;
	Missile:
		DKNT A 0 A_PlaySound("BK/invi",0,4);
		DKNT A 0 A_JumpIfCloser(220,"Melee");
		DKNT A 0 A_JumpIfCloser(1000,"Missile.Close");
		DKNT A 0 A_Jump(255,"Missile.Cleave","Missile.ShieldBlast","Missile.Dash");
		Goto See;
	Missile.Close:
		DKNT A 0 A_Jump(255,"Missile.Cleave","Missile.Mines","Missile.Dash","Missile.Grap");
		Goto See;
	Missile.Cleave:
		DKNT J 8 Bright A_FaceTarget;
		DKNT KKKKKK 2 Bright A_CustomMissile("HF_DKDart",44,0,random(-9,9));
		DKNT J 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.ShieldBlast:
		DKNT P 10 Bright A_FaceTarget;
		DKNT T 10 Bright A_FaceTarget;
		DKNT UUUUUUUU 1 Bright A_CustomMissile("HF_ShieldBombRev",random(32,56),0,random(-7,7));
		DKNT UUUUUUUU 1 Bright A_CustomMissile("HF_ShieldBombRev",random(32,56),0,random(-7,7));
		DKNT U 8 Bright A_CustomMissile("HF_ShieldBlastRev",44,0,0);
		DKNT J 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Mines:
		DKNT P 8 Bright A_FaceTarget;
		DKNT U 4 Bright A_CustomMissile("HF_MinesRev",40,0,random(-8,8));
		DKNT U 4 Bright A_CustomMissile("HF_MinesRev",40,0,random(-8,8));
		DKNT U 4 Bright A_CustomMissile("HF_MinesRev",40,0,random(-8,8));
		DKNT J 8 A_MonsterRefire(40,"See");
		Goto See;
	Missile.Grap:
		DKNT PTU 3 Bright A_FaceTarget;
		DKNT U 3 Bright A_CustomMissile("HF_BlackRevHook",44,0,0);
		DKNT U 6 Bright A_CustomMissile("HF_DKDart",44,0,random(-4,4));
		Goto See;
	Missile.Dash:
		DKNT P 4 Bright A_FaceTarget;
		DKNT A 0 A_SetSpeed(40);
		DKNT BCDEF 2 A_Chase;
		DKNT J 6 A_CustomMeleeAttack(random(40,110),"skeleton/melee");
		DKNT A 0 A_SetSpeed(14);
		Goto See;
	Pain:
		DKNT L 5; DKNT L 5 A_Pain;
		Goto See;
	Death:
		DKNT M 7;
		DKNT N 7 A_Scream;
		DKNT O 7;
		DKNT P 7 A_NoBlocking;
		DKNT Q 7;
		DKNT R -1;
		Stop;
	}
}
