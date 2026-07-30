// =====================================================================
// RS_FXBFG -- BFG-specific trail/flare/debris effects. Split out of the
// original monolithic RS_EnhancedFX.zs -- see RS_FXBase.zs.
// Depends on RS_FXBase.zs (RS_FlareGeneral) and RS_FXPlasma.zs
// (RS_PlasmaRailBall, RS_BluePlasmaPiece, RS_BluePlasmaShred/Trail).
// The projectile itself (RS_EnhancedBFGBall) lives in
// RS_HeavyProjectiles.zs, not here -- see that file's own header.
// =====================================================================

class RS_BFGTrail : RS_FlareGeneral
{
	Default
	{
		Alpha 0.4;
		Scale 0.5;
		+NOINTERACTION
	}
	States
	{
	Spawn:
		TNT1 A 0 A_Warp(AAPTR_MASTER);
		RSF1 A 1 Bright;
		Wait;
	}
}

class RS_BFGBallRayFlare : RS_FlareGeneral
{
	Default
	{
		RenderStyle "Add";
		Alpha 0.1;
		Scale 0.07;
	}
	States
	{
	Spawn:
		RSF1 A 1 Bright A_FadeOut(0.01);
		Wait;
	}
}

class RS_BFGBallRay : RS_PlasmaRailBall
{
	Default
	{
		Alpha 0.5;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItem("RS_BFGBallRayFlare");
		RSP6 "ABCDEFGHIJKLM" 1 Bright A_FadeOut(0.08);
		Stop;
	}
}

class RS_BFGBallRayPuff : Actor
{
	Default
	{
		DamageType "None";
		+BLOODLESSIMPACT
	}
}

class RS_BFGGreenPlasmaPiece : RS_BluePlasmaPiece
{
	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		Alpha 0.5;
		Speed 3;
		Scale 0.1;
	}
}

class RS_BFGGreenPlasmaShredTrail : RS_BluePlasmaShredTrail { }

class RS_BFGGreenPlasmaShred : RS_BluePlasmaShred
{
	States
	{
	Spawn:
		RSP3 "ABCDE" 1 Bright A_SpawnItem("RS_BFGGreenPlasmaShredTrail");
		Stop;
	}
}

class RS_EnhancedBFGExtra : BFGExtra
{
	Default
	{
		DamageType "BFGSplash";
		Scale 0.35;
		RenderStyle "Add";
		Alpha 0.6;
	}
	States
	{
	Spawn:
		TNT1 "A" 0 A_SpawnProjectile("RS_BFGGreenPlasmaPiece", 0, 0, Random(-360, 360), 2, Random(-80, 80));
		RSP6 "AABBCCDDEEFFGGHHIIJJKKLLMM" 1 Bright;
		Stop;
	}
}

class RS_BFGRailPuff : RS_EnhancedBFGExtra
{
	Default
	{
		+BLOODLESSIMPACT
		+ALWAYSPUFF
		DamageType "BFGSplash";
		Scale 0.35;
		RenderStyle "Add";
		Alpha 0.6;
	}
	States
	{
	Spawn:
		TNT1 "A" 0 A_SpawnProjectile("RS_BFGGreenPlasmaPiece", 0, 0, Random(-360, 360), 2, Random(-50, 50));
		TNT1 "A" 0 A_SpawnProjectile("RS_BFGGreenPlasmaShred", 0, 0, Random(-360, 360), 2, Random(-90, 90));
		TNT1 A 3;
		Stop;
	}
}
