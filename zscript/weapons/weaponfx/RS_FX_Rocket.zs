// =====================================================================
// RS_FXRocket -- rocket-specific trail/flare effects. Split out of the
// original monolithic RS_EnhancedFX.zs -- see RS_FXBase.zs.
// Depends on RS_FXBase.zs (RS_FlareGeneral).
// The projectile itself (RS_EnhancedRocket) lives in
// RS_HeavyProjectiles.zs, not here -- see that file's own header.
// =====================================================================

class RS_RocketFlare : RS_FlareGeneral
{
	Default
	{
		RenderStyle "Add";
		Alpha 0.4;
		Scale 0.09;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_Warp(AAPTR_MASTER, -16, 0, 6);
		RSF2 A 1 Bright;
		Wait;
	}
}

class RS_HomingRocketFlare : RS_FlareGeneral
{
	Default
	{
		RenderStyle "Add";
		Alpha 0.4;
		Scale 0.09;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_Warp(AAPTR_MASTER, -16, 0, 6);
		TNT1 A 0 A_JumpIfMasterCloser(18, "Spawn");
		Stop;
	}
}

class RS_SeekerFlare : RS_FlareGeneral
{
	Default
	{
		+FORCEXYBILLBOARD
		+NOGRAVITY
		Alpha 0.5;
		Scale 0.12;
	}
	States
	{
	Spawn:
		// Source played a "seeker" sound here, but that asset was part of
		// its homing-rocket feature and was never ported -- and a sound on
		// every individual trail particle would be unbearable regardless.
		// Dropped rather than substituted.
		RSF1 A 2;
		Stop;
	}
}
