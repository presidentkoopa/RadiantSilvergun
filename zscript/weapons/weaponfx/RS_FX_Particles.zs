// =====================================================================
// RS_FXParticles -- generic particle primitives (explosion/spark bursts)
// that RS_FXSparks.zs, RS_FXSmoke.zs, and others build on. Split out of
// the original monolithic RS_EnhancedFX.zs -- see RS_FXBase.zs for the
// full explanation of the split and the RS_ prefix rule.
// =====================================================================

class RS_ExplosionParticle : Actor
{
	Default
	{
		Height 1;
		Radius 1;
		Mass 0;
		+MISSILE
		+NOBLOCKMAP
		+DONTSPLASH
		+FORCEXYBILLBOARD
		+CLIENTSIDEONLY
		+THRUACTORS
		+GHOST
		-NOGRAVITY
		+THRUGHOST
		+NOTELEPORT
		RenderStyle "Add";
		Scale 0.8;
		Gravity 0;
	}
	States
	{
	Spawn:
		// Frame A, not the source's B -- SPKO ships only frame A in the
		// sanctioned source pack. B/S are brightness variants that exist
		// solely in unrelated mods (BrutalDoom), so they're not ours to
		// pull from. Single-frame fade-out particle either way, so the
		// effect is unchanged; this just binds to a frame that exists.
		SPKO A 1 Bright A_FadeOut(0.02);
		Loop;
	}
}

class RS_ExplosionParticle2 : RS_ExplosionParticle
{
	Default
	{
		Scale 0.1;
	}
	States
	{
	Spawn:
		SPRK "S" 1 Bright;
		SPRK "S" 1 Bright A_FadeOut(0.02);
		Wait;
	}
}

class RS_ExplosionParticleHeavy : RS_ExplosionParticle2
{
	Default
	{
		Speed 5;
		Gravity 0.5;
		Scale 0.2;
		BounceFactor 0.01;
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

// One-call omnidirectional particle burst -- spawn this anywhere and it
// throws a sphere of heavy particles, then removes itself. The source did
// this with ten duplicated A_CustomMissile frames and a fixed count; a
// real loop is both shorter and lets the count scale with the FX tier,
// which the flat version couldn't do. Nothing calls it yet -- it's here so
// any future effect that wants a burst has one line to reach for instead
// of hand-rolling a spawn loop.
class RS_ExplosionParticleSpawner : Actor
{
	Default
	{
		+NOCLIP
		+NOBLOCKMAP
		+CLIENTSIDEONLY
		+NOGRAVITY
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		int tier = RS_HiFiFX.Tier();
		if (tier == RS_HiFiFX.RSFX_OFF)
		{
			Destroy();
			return;
		}

		// Source fired a flat 10. Standard keeps that, Hi-Fi doubles it.
		int count = (tier == RS_HiFiFX.RSFX_HIFI) ? 20 : 10;
		for (int i = 0; i < count; i++)
		{
			let p = Spawn("RS_ExplosionParticleHeavy", Pos, ALLOW_REPLACE);
			if (!p)
				continue;
			// Random direction over the full sphere, matching the source's
			// two-pass random(0,360)/random(0,180) spread.
			p.Angle = FRandom(0, 360);
			p.Pitch = FRandom(-90, 90);
			p.Vel3DFromAngle(p.Speed, p.Angle, p.Pitch);
		}

		Destroy();
	}
}
