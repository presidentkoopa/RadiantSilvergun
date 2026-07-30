// =====================================================================
// RS_FXPuffs -- enhanced impact puffs (wall debris + sparks + optional
// ricochet), replacing the plain PUFF actor's visual when rs_fx_*
// toggles allow it. Split out of the original monolithic
// RS_EnhancedFX.zs -- see RS_FXBase.zs.
// Depends on RS_FXBase.zs (RS_DebrisGeneral), RS_FXSparks.zs
// (RS_SparkXHeavy, RS_RicochetSpark), and RS_FXRicochet.zs
// (RS_RicochetBullet/Shell, RS_ShotgunParticlesHeavy).
// =====================================================================

class RS_WallPart : RS_DebrisGeneral
{
	Default
	{
		BounceType "Doom";
		-NOGRAVITY
		+DONTSPLASH
		Speed 8;
		BounceFactor 0.4;
		RenderStyle "Translucent";
		Alpha 1.0;
		Scale 0.1;
	}
	States
	{
	Spawn:
		BPRT "ACDEFGH" 2 A_JumpIf(vel.z == 0, "Null");
		BPRT "ACDEFGH" 3 A_JumpIf(vel.z == 0, "Null");
		Stop;
	Death:
		Stop;
	}
}

class RS_EnhancedBulletPuff : Actor
{
	Default
	{
		+NOGRAVITY
		+FORCEXYBILLBOARD
		-DONTSPLASH
		-ALLOWPARTICLES
		Decal "BulletChip";
		RenderStyle "Add";
		Scale 0.1;
		Alpha 0.8;
		Mass 1;
	}
	States
	{
	Spawn:
		TNT1 "A" 0 A_SpawnItemEx("RS_WallPart", 0, 0, 0, Random(1, 5), 0, Random(2, 6), Random(0, 360), 0, 64);
		TNT1 A 0 A_JumpIf(!CVar.GetCVar("rs_fx_ricochet", null), "Puff");
		TNT1 A 0 A_CustomMissile("RS_SparkXHeavy", 2, 0, Random(0, 360), 2, Random(0, 180));
		TNT1 A 0 A_SpawnProjectile("RS_RicochetBullet", 0, 0, Random(0, 360), 2, Random(-40, 40));
	Puff:
		BPUF ABCD 1 Bright;
		Stop;
	}
}

class RS_ChainsawPuff : RS_EnhancedBulletPuff
{
	Default
	{
		DamageType "Saw";
		Scale 0.15;
		Alpha 0.6;
		Decal "SawMark";
	}
	States
	{
	Spawn:
		TNT1 A 0 A_SpawnItemEx("RS_WallPart", 0, 0, 0, Random(6, 9), 0, Random(6, 15), Random(0, 360), 0, 64);
		TNT1 A 0 A_PlaySound("rs_fx_sawwall");
		TNT1 "A" 0 A_SpawnItemEx("RS_RicochetSpark", 0, 0, 0, Random(1, 2), 0, Random(5, 10), Random(0, 360), 0, 40);
		CPUF ABCD 1 Bright;
		Stop;
	}
}

class RS_EnhancedShotPuff : RS_EnhancedBulletPuff
{
	Default
	{
		Decal "ShotChip";
	}
	States
	{
	Spawn:
		TNT1 A 0 A_SpawnItemEx("RS_WallPart", 0, 0, 0, Random(1, 5), 0, Random(2, 6), Random(0, 360), 0, 64);
		TNT1 A 0 A_JumpIf(!CVar.GetCVar("rs_fx_ricochet", null), "Puff");
		TNT1 A 0 A_CustomMissile("RS_ShotgunParticlesHeavy", 2, 0, Random(0, 360), 2, Random(0, 180));
		TNT1 A 0 A_SpawnProjectile("RS_RicochetShell", 0, 0, Random(0, 360), 2, Random(-40, 40));
		Goto Puff;
	}
}
