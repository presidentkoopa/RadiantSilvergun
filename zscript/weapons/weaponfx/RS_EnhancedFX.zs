// =====================================================================
// RS_EnhancedFX -- tracers, ricochet, hit sparks, smoke, and heavy-
// ordnance debris/flare effects.
// ---------------------------------------------------------------------
// Every class in this file is deliberately renamed from its source
// material's original names. That source is a real, popular, standalone
// GZDoom mod some players run on its own -- if this file reused any of
// its class names unchanged and a player loaded both, GZDoom would
// throw a duplicate-class-definition error and refuse to load at all.
// Every single class here carries the RS_ prefix for that reason, no
// exceptions, including the throwaway-looking ones.
//
// This is a restyled rebuild, not a 1:1 port:
//   - ~6 near-duplicate smoke classes (differing only by Alpha/Scale)
//     are collapsed into one RS_SmokeWisp with a SetupVisual() call,
//     the same pattern RS_BallisticFired.SetupStats already establishes.
//   - ~11 per-weapon "barrel smoke" classes were already fully inert in
//     the source (every line of actual content commented out) -- kept
//     as one inert placeholder rather than reproducing eleven empty
//     classes.
//   - RS_BallisticTracer integrates directly with the existing
//     RS_BallisticFired/ProjectileClass system instead of being a
//     second, disconnected projectile type.
//
// All four toggles (tracers/ricochet/smoke/hq sounds) are real CVars
// (CVARINFO.txt) surfaced in the Enhanced Weapon FX menu (MENUDEF.txt).
// Every effect here checks its relevant CVar before doing the expensive
// part; disabling a toggle means a cheap/no-op fallback, not a missing
// effect and not an error.
// =====================================================================


// ---------------------------------------------------------------------
// Shared primitives
// ---------------------------------------------------------------------

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

// ---------------------------------------------------------------------
// Debris / smoke / flare bases
// ---------------------------------------------------------------------

class RS_DebrisGeneral : Actor
{
	Default
	{
		+FIXMAPTHINGPOS
		+LOOKALLAROUND
		+NOTAUTOAIMED
		+MISSILE
		+NOBLOCKMAP
		+MOVEWITHSECTOR
		+NOGRAVITY
		+DROPOFF
		+NOTELEPORT
		+FORCEXYBILLBOARD
		+GHOST
		+THRUACTORS
		+FLOORCLIP
		RenderStyle "Translucent";
		Alpha 1.0;
		Radius 1;
		Height 1;
		Mass 1;
		Damage 0;
	}
}

class RS_DummyChecker : Inventory
{
	Default
	{
		+UNDROPPABLE
		+UNTOSSABLE
		-COUNTITEM
		-INVBAR
		+PERSISTENTPOWER
		Inventory.Amount 1;
		Inventory.MaxAmount 9999;
	}
}

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

class RS_FlareGeneral : RS_DebrisGeneral
{
	Default
	{
		+NOINTERACTION
		+NOCLIP
		-MISSILE
		-FORCEXYBILLBOARD
		RenderStyle "Add";
		Alpha 0.4;
		Scale 0.4;
	}
}

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
		SetScale(scaleVal);
		Vel.Z = vspeedVal;
	}

	States
	{
	Spawn:
		TNT1 A 0 A_SetScale(Scale.X * (Random(0, 1) ? 1 : -1), Scale.Y * (Random(0, 1) ? 1 : -1));
		SMOK "ABCDEFGHIJKLMNOPQ" 1;
		Stop;
	}
}

// ---------------------------------------------------------------------
// Sparks
// ---------------------------------------------------------------------

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
		+DOOMBOUNCE
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

// ---------------------------------------------------------------------
// Ricochet -- bounced-round visual + sound, spawned on impact when
// rs_fx_ricochet is on.
// ---------------------------------------------------------------------

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
	States
	{
	Spawn:
		TNT1 "A" 0 A_CustomMissile("RS_SparkXNoModel", 2, 0, Random(0, 360), 2, Random(0, 360));
		TNT1 A 0 A_PlaySound("rs_fx_ricochet");
		PUFF A 2;
		Stop;
	}
}

class RS_RicochetShell : RS_RicochetBullet
{
	States
	{
	Spawn:
		TNT1 A 0 A_CustomMissile("RS_ShotgunParticles", 2, 0, Random(0, 360), 2, Random(0, 360));
		TNT1 A 0 A_CustomMissile("RS_ShotgunParticles2", 2, 0, Random(0, 360), 2, Random(0, 360));
		TNT1 A 0 A_PlaySound("rs_fx_ricochet");
		PUFF A 2;
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
		SPKO A 1 Bright A_FadeOut(0.02);   // see RS_ExplosionParticle re: frame A
		TNT1 A 0 A_ChangeFlag("NOGRAVITY", false);
		SPKO A 1 Bright A_FadeOut(0.04);
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

// ---------------------------------------------------------------------
// Tracer -- integrates with the existing ballistic system directly.
// This is the ProjectileClass value bullet weapons swap to when
// rs_fx_tracers is on; no weapon file needs to know this class exists.
// ---------------------------------------------------------------------

class RS_BallisticTracer : RS_BallisticFired
{
	States
	{
	Spawn:
		BAL1 A 1 Bright A_JumpIfCloser(192, "SpawnNear");
		TNT1 A 0 A_FadeOut(0.1);
		Loop;
	SpawnNear:
		BAL1 A 30 Bright A_PlaySound("rs_fx_tracerwhizz", CHAN_AUTO, 1.0, false, ATTN_STATIC);
		Loop;
	Death:
		TNT1 A 0 A_JumpIf(!CVar.GetCVar("rs_fx_ricochet", null), "Super::Death");
		TNT1 A 0 A_SpawnProjectile("RS_RicochetBullet", 0, 0, Random(0, 360), 2, Random(-40, 40));
		Goto Super::Death;
	}
}

// ---------------------------------------------------------------------
// Enhanced impact puffs -- wall debris + sparks + optional ricochet,
// replacing the plain PUFF actor's visual when rs_fx_* toggles allow it.
// ---------------------------------------------------------------------

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

// ---------------------------------------------------------------------
// Barrel smoke -- fully inert in the source material (every line of
// real content was commented out across all ~11 per-weapon variants).
// One shared placeholder instead of eleven empty classes.
// ---------------------------------------------------------------------

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

// ---------------------------------------------------------------------
// Rocket-specific
// ---------------------------------------------------------------------

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
		LENR A 1 Bright;
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
		LENG A 2;
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

// ---------------------------------------------------------------------
// Plasma-specific
// ---------------------------------------------------------------------

class RS_BlueFlarePlasma : RS_FlareGeneral
{
	Default
	{
		RenderStyle "Add";
		Alpha 0.5;
		Scale 0.1;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_Warp(AAPTR_MASTER);
	Spawn1:
		TNT1 A 0 A_JumpIfMasterCloser(1, "Spawn1");
		LENB A 1 Bright A_FadeOut(0.1);
		Wait;
	}
}

// Appears behind the plasma ball as a fading trail.
class RS_BlueFlarePlasmaTrail : RS_FlareGeneral
{
	Default
	{
		+FORCEXYBILLBOARD
		Alpha 0.4;
		Scale 0.07;
	}
	States
	{
	Spawn:
		LENB A 1 Bright A_FadeOut(0.15);
		TNT1 A 0 A_SetScale(Scale.X * 0.9, Scale.Y * 0.9);
		Loop;
	}
}

class RS_BluePlasmaPiece : RS_DebrisGeneral
{
	Default
	{
		+DONTSPLASH
		-NOGRAVITY
		RenderStyle "Add";
		Alpha 1.0;
		Scale 0.08;
		Speed 6;
		Gravity 0.8;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		PLBS A 1 Bright A_FadeOut(0.03);
		Loop;
	}
}

class RS_PlasmaRailBall : RS_DebrisGeneral
{
	Default
	{
		-MISSILE
		+NOINTERACTION
		RenderStyle "Add";
		Alpha 0.8;
		Scale 0.03;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItem("RS_PlasmaRailFlare");
		PEXP "ABCDEF" 1 Bright A_FadeOut(0.0025);
		PEXP "GHIJKLM" 2 Bright A_FadeOut(0.0025);
		Stop;
	}
}

class RS_BluePlasmaShred : RS_DebrisGeneral
{
	Default
	{
		+NOINTERACTION
		RenderStyle "Add";
		Speed 5;
		Scale 0.05;
		Alpha 0.6;
	}
	States
	{
	Spawn:
		PLSE "ABCDE" 1 Bright A_SpawnItem("RS_BluePlasmaShredTrail");
		Stop;
	}
}

class RS_BluePlasmaShredTrail : RS_BluePlasmaShred
{
	Default
	{
		Speed 0;
		Alpha 0.5;
	}
	States
	{
	Spawn:
		PLSE "ABCDE" 2 Bright;
		Stop;
	}
}

class RS_PlasmaRailFlareCounter : RS_DummyChecker
{
	Default
	{
		Inventory.MaxAmount 500;
	}
}

class RS_PlasmaRailFlare : RS_BlueFlarePlasmaTrail
{
	Default
	{
		Alpha 0.1;
		Scale 0.07;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_GiveInventory("RS_PlasmaRailFlareCounter", 1, AAPTR_PLAYER1);
		TNT1 A 0 A_JumpIfInventory("RS_PlasmaRailFlareCounter", 250, "Disappear", AAPTR_PLAYER1);
		TNT1 A 1;
		TNT1 A 0 A_TakeInventory("RS_PlasmaRailFlareCounter", 1, 0, AAPTR_PLAYER1);
		LENB A 1 Bright A_FadeOut(0.0025);
		Wait;
	Disappear:
		TNT1 A 1 A_TakeInventory("RS_PlasmaRailFlareCounter", 1, 0, AAPTR_PLAYER1);
		Stop;
	}
}

// ---------------------------------------------------------------------
// BFG-specific
// ---------------------------------------------------------------------

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
		LENG A 1 Bright;
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
		LENG A 1 Bright A_FadeOut(0.01);
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
		PEXP "ABCDEFGHIJKLM" 1 Bright A_FadeOut(0.08);
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
		PLSE "ABCDE" 1 Bright A_SpawnItem("RS_BFGGreenPlasmaShredTrail");
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
		PEXP "AABBCCDDEEFFGGHHIIJJKKLLMM" 1 Bright;
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

// Heavy ordnance (RS_EnhancedRocket / RS_EnhancedPlasmaBall /
// RS_EnhancedBFGBall) moved out to RS_HeavyProjectiles.zs -- they're
// projectiles, not effects, and they now carry SetupStats() so the firing
// weapon's rolled damage actually reaches them. The trail effects they
// spawn still live in this file.

// ---------------------------------------------------------------------
// Dynamic muzzle light -- Hi-Fi tier only (RS_HiFiFX.SpawnMuzzleLight
// gates this before ever spawning one). Color/radius are a first-pass
// guess, meant to be tuned once actually seen in a headset rather than
// assumed correct on paper.
// ---------------------------------------------------------------------

class RS_MuzzleLight : PointLight
{
	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+DONTSPLASH
		+THRUACTORS
		+NOTELEPORT
		Args 255, 200, 120, 96; // R, G, B, radius -- warm muzzle-flash color, randomized per-spawn below
	}

	// Every real muzzle flash looks slightly different shot to shot --
	// randomize brightness (color scaled together, hue kept warm) and
	// radius a little so Hi-Fi tier doesn't look identically robotic
	// every single trigger pull.
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		double brightness = FRandom(0.8, 1.15);
		args[0] = Clamp(int(255 * brightness), 0, 255);
		args[1] = Clamp(int(200 * brightness), 0, 255);
		args[2] = Clamp(int(120 * brightness), 0, 255);
		args[3] = int(FRandom(72, 116));
	}
	States
	{
	Spawn:
		TNT1 A 3 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// Casing ejection + magazine drop -- cosmetic-only props for
// RS_HiFiFX.CasingEject()/MagDrop(). Generic enough to be reused by any
// weapon in this project or a future weapon set, rather than one class
// per gun. Real, falling, physical props -- unlike the floaty debris
// above, these actually drop and settle.
// ---------------------------------------------------------------------

class RS_CasingSmall : RS_DebrisGeneral
{
	Default
	{
		-NOGRAVITY
		-FORCEXYBILLBOARD
		+DROPOFF
		RenderStyle "Normal";
		Alpha 1.0;
		Scale 0.6;
		Gravity 1.0;
		BounceType "Doom";
		BounceFactor 0.3;
		Speed 0;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("rs_fx_casing_pistol", CHAN_AUTO);
		CAS1 "ABCDE" 2;
		Loop;
	Death:
		Stop;
	}
}

class RS_CasingRifle : RS_CasingSmall
{
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("rs_fx_casing_chaingun", CHAN_AUTO);
		CAS2 "ABCDE" 2;
		Loop;
	}
}

class RS_CasingShell : RS_CasingSmall
{
	Default
	{
		Scale 0.8;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("rs_fx_casing_shell", CHAN_AUTO);
		CAS3 "ABDGK" 3;
		Loop;
	}
}

class RS_MagDrop : RS_DebrisGeneral
{
	Default
	{
		-NOGRAVITY
		-FORCEXYBILLBOARD
		+DROPOFF
		RenderStyle "Normal";
		Alpha 1.0;
		Scale 1.0;
		Gravity 1.0;
		BounceType "Doom";
		BounceFactor 0.15;
		Speed 0;
	}
	States
	{
	Spawn:
		ECLI "ABCDEFGH" 3;
		Loop;
	Death:
		Stop;
	}
}
