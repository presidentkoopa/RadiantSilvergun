// =====================================================================
// RS_FXSmoke -- smoke wisps, inert barrel-smoke placeholder, and
// generic smoking debris. Split out of the original monolithic
// RS_EnhancedFX.zs -- see RS_FXBase.zs.
// Depends on RS_FXBase.zs (RS_DebrisGeneral) and RS_FXParticles.zs
// (RS_ExplosionParticle).
// =====================================================================

// One consolidated smoke class replacing ~6 near-duplicates from the
// source that differed only by Alpha/Scale/vertical speed. Whatever
// spawns this calls SetupVisual() right after, same shape as
// RS_BallisticFired.SetupStats.
class RS_SmokeWisp : RS_DebrisGeneral
{
	Default
	{
		+NOINTERACTION
		RenderStyle "Add";
		Alpha 0.3;
		Scale 0.1;
	}

	void SetupVisual(double alphaVal, double scaleVal, double vspeedVal = 0)
	{
		A_SetRenderStyle(alphaVal, STYLE_Add);
		A_SetScale(scaleVal); // was bare SetScale() -- not a real Actor function
		Vel.Z = vspeedVal;
	}

	States
	{
	Spawn:
		TNT1 A 0 A_SetScale(Scale.X * (Random(0, 1) ? 1 : -1), Scale.Y * (Random(0, 1) ? 1 : -1));
		RSK0 "ABCDEFGHIJKLMNOPQ" 1;
		Stop;
	}
}

// Fully inert in the source material (every line of real content was
// commented out across all ~11 per-weapon variants). One shared
// placeholder instead of eleven empty classes.
class RS_GunBarrelSmoke : RS_ExplosionParticle
{
	Default
	{
		Radius 1;
		Height 1;
		Speed 0;
		Damage 0;
		Projectile;
		SeeSound "";
		DeathSound "";
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Stop;
	Death:
		TNT1 A 0;
		Stop;
	}
}

class RS_SmokingPiece : RS_DebrisGeneral
{
	Default
	{
		-NOGRAVITY
		Gravity 0.7;
		Alpha 1.0;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_FadeOut(0.025);
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}
