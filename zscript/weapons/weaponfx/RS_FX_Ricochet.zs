// =====================================================================
// RS_FXRicochet -- bounced-round visual + sound, spawned on impact when
// rs_fx_ricochet is on. Split out of the original monolithic
// RS_EnhancedFX.zs -- see RS_FXBase.zs.
// Depends on RS_FXSparks.zs (RS_SparkXNoModel) and RS_FXParticles.zs
// (RS_ExplosionParticle2/Heavy).
// =====================================================================

class RS_RicochetBullet : Actor
{
	Default
	{
		-ACTIVATEIMPACT
		-ACTIVATEPCROSS
		+FORCEXYBILLBOARD
		+THRUACTORS
		BounceType "Hexen";
		Mass 1;
		Damage 0;
		Radius 1;
		Height 1;
		Speed 30;
		SeeSound "";
		RenderStyle "Add";
		Alpha 0.8;
	}
	// NoDelay: without it the engine skips this frame's action on the tic
	// the actor spawns, so the spark never appeared. The sound survived
	// only because it sat on the SECOND frame.
	//
	// Whether this actor exists at all is now decided by the puff, which
	// asks RS_Material whether the surface can ricochet and then rolls
	// for it. Reaching this state means a ricochet genuinely happened,
	// so the sound is unconditional HERE and correct.
	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_SpawnProjectile("RS_SparkXNoModel", 2, 0, random(0, 360), CMF_AIMDIRECTION, random(0, 360));
		TNT1 A 0 A_StartSound("rs_fx_ricochet", CHAN_AUTO);
		RSU0 A 2;
		Stop;
	}
}

class RS_RicochetShell : RS_RicochetBullet
{
	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_SpawnProjectile("RS_ShotgunParticles", 2, 0, random(0, 360), CMF_AIMDIRECTION, random(0, 360));
		TNT1 A 0 A_SpawnProjectile("RS_ShotgunParticles2", 2, 0, random(0, 360), CMF_AIMDIRECTION, random(0, 360));
		TNT1 A 0 A_StartSound("rs_fx_ricochet", CHAN_AUTO);
		RSU0 A 2;
		Stop;
	}
}

class RS_ShotgunParticles : RS_ExplosionParticle2
{
	Default
	{
		Speed 15;
		Radius 8;
		Height 1;
		Gravity 0.6;
		RenderStyle "Add";
		Scale 0.1;
		Alpha 0.9;
	}
	States
	{
	Spawn:
		TNT1 A 2;
		RSS1 A 1 Bright A_FadeOut(0.02);   // see RS_ExplosionParticle re: frame A
		TNT1 A 0 A_ChangeFlag("NOGRAVITY", false);
		RSS1 A 1 Bright A_FadeOut(0.04);
		Wait;
	Death:
		Stop;
	}
}

class RS_ShotgunParticles2 : RS_ShotgunParticles
{
	Default
	{
		Speed 10;
		Gravity 0.5;
		Scale 0.1;
		Alpha 0.9;
	}
}

class RS_ShotgunParticlesHeavy : RS_ExplosionParticleHeavy
{
	Default
	{
		Speed 3;
		Scale 0.1;
	}
}
