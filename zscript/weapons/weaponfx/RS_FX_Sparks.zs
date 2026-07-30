// =====================================================================
// RS_FXSparks -- hit sparks and bounce/impact spark variants. Split out
// of the original monolithic RS_EnhancedFX.zs -- see RS_FXBase.zs.
// Depends on RS_FXParticles.zs (RS_ExplosionParticleHeavy).
// =====================================================================

class RS_HitSpark : RS_ExplosionParticleHeavy
{
	Default
	{
		Speed 6;
		Scale 0.04;
		Gravity 1.0;
		+NOCLIP
	}
	States
	{
	Spawn:
		SPKO A 1 Bright A_FadeOut(0.07);   // see RS_ExplosionParticle re: frame A
		Wait;
	Death:
		Stop;
	}
}

class RS_SparkX : RS_ExplosionParticleHeavy
{
	Default
	{
		Speed 10;
		Gravity 0.8;
		-NOGRAVITY
		Scale 0.05;
		Radius 1;
		Height 1;
		BounceType "Doom"; // was +DOOMBOUNCE -- deprecated since 4.13.0
		+GHOST
		BounceFactor 0.5;
		Damage 0;
		Alpha 1.0;
	}
	States
	{
	Spawn:
		SPKO "A" 1 Bright;
		SPKO "A" 1 Bright A_FadeOut(0.20);
		Wait;
	Death:
		Stop;
	}
}

class RS_SparkXNoModel : RS_SparkX
{
	Default
	{
		Scale 0.03;
		Gravity 0.7;
	}
}

class RS_SparkXHeavy : RS_SparkX
{
	Default
	{
		Speed 3;
		Gravity 0.5;
		BounceFactor 0.01;
		Scale 0.1;
	}
	States
	{
	Spawn:
		SPRK "S" 1 Bright;
		SPRK "S" 1 Bright A_FadeOut(0.02);
		Wait;
	Death:
		Stop;
	}
}

class RS_RicochetSpark : RS_DebrisGeneral
{
	Default
	{
		BounceType "None";
		-NOGRAVITY
		+DONTSPLASH
		RenderStyle "Add";
		Alpha 1.0;
		Radius 3;
		Height 3;
		Scale 0.03;
		Gravity 1.0;
	}
	States
	{
	Spawn:
		SPRK A 1 Bright A_FadeOut(0.05);
		Loop;
	}
}
