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
	// SAME PERMANENT-ACTOR SHAPE AS RS_BFGTrail, fixed 2026-08-07 before
	// it could ship. `RSF2 A 1 Bright; Wait;` re-runs a visible frame
	// forever with no A_FadeOut, no Stop and no lifetime anywhere in
	// RS_FlareGeneral -- so every one of these that spawned would hang
	// in the air until the map ended.
	//
	// It has not bitten yet only because nothing currently spawns this
	// class; it is a catalog entry one profile edit away from live,
	// which is exactly when a leak like this is cheapest to fix and
	// most expensive to discover.
	//
	// The A_Warp is kept here (unlike the BFG trail's, which was dead):
	// this flare is meant to ride the rocket, so it re-anchors to its
	// master each pass -- but it now fades while it does.
	States
	{
	Spawn:
		TNT1 A 0 A_Warp(AAPTR_MASTER, -16, 0, 6);
		RSF2 A 1 Bright A_FadeOut(0.05);
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
