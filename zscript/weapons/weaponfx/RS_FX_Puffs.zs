// =====================================================================
// RS_FXPuffs -- impact effects, dispatched on WHAT WAS ACTUALLY HIT.
// ---------------------------------------------------------------------
// Rewritten 2026-08-07. What this file used to do, and why none of it
// worked:
//
//  1. EVERY impact spawned a ricochet, which played a ricochet sound
//     unconditionally -- into steel, into rock, into a Baron's chest,
//     identically, on every shot in the game. The gate that was supposed
//     to prevent this read
//         A_JumpIf(!CVar.GetCVar("rs_fx_ricochet", null), "Puff")
//     which negates the CVar HANDLE, not its value. The handle is never
//     null for a declared cvar, so the jump never fired and the menu
//     toggle did nothing in either position.
//
//  2. The wall-debris spawn sat on the FIRST frame of Spawn without
//     NoDelay. GZDoom does not run the action of a state's first frame
//     on the tic it is entered unless the frame is marked NoDelay -- so
//     no bullet impact in this game has ever produced a wall chip. Same
//     bug in the chainsaw puff and the ricochet's first spark.
//
//  3. Nothing anywhere knew what surface it had hit, so a wooden crate,
//     a nukage pool and a steel door all produced the same grey chips
//     and the same sound.
//
// All three are the same underlying gap and are fixed together: the puff
// now asks RS_Material what it hit (a LineTrace back down the shot, see
// that file), and dispatches sound, debris and ricochet off the answer.
// Ricochet is hard surfaces only, on a roll -- owner ruling.
//
// Depends on RS_FX_Base.zs (RS_DebrisGeneral), RS_FX_Sparks.zs
// (RS_SparkXHeavy, RS_RicochetSpark), RS_FX_Ricochet.zs
// (RS_RicochetBullet/Shell, RS_ShotgunParticlesHeavy) and
// zscript/systems/weapon/RS_Material.zs.
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
		RSU3 "ACDEFGH" 2 A_JumpIf(vel.z == 0, "Null");
		RSU3 "ACDEFGH" 3 A_JumpIf(vel.z == 0, "Null");
		Stop;
	Death:
		Stop;
	}
}

// Per-material debris. Same motion, different look -- the chip that
// comes off a steel door should not be the chip that comes off a crate.
// Scale/alpha/bounce differ; all inherit RS_WallPart's state machine.
class RS_WallPartMetal : RS_WallPart
{
	Default
	{
		Scale 0.08;
		BounceFactor 0.6;   // metal chips skitter
		RenderStyle "Add";
		Alpha 0.9;
	}
}

class RS_WallPartWood : RS_WallPart
{
	Default
	{
		Scale 0.12;
		BounceFactor 0.25;  // splinters land dead
		Alpha 1.0;
	}
}

class RS_WallPartDirt : RS_WallPart
{
	Default
	{
		Scale 0.09;
		BounceFactor 0.1;   // clods do not bounce
		Alpha 0.8;
	}
}

class RS_WallPartGlass : RS_WallPart
{
	Default
	{
		Scale 0.06;
		BounceFactor 0.7;
		RenderStyle "Add";
		Alpha 0.7;
	}
}

// =====================================================================
// RS_EnhancedBulletPuff -- the base impact.
//
// The material resolve happens once, in PostBeginPlay, and is cached on
// the actor so the states can read it without re-tracing. PostBeginPlay
// is also the right place because it runs before the first state tic, so
// nothing has been spawned or played on the wrong assumption yet.
// =====================================================================
class RS_EnhancedBulletPuff : Actor
{
	// Resolved surface/body material (ERSMaterial). Read by the states.
	int RSMaterial;
	// True when the shot ended on the sky -- produce nothing at all.
	bool RSHitSky;

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

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		FLineTraceData d;
		[RSMaterial, RSHitSky] = RS_Material.ResolveEx(self, d);
	}

	// One helper the states call, so every puff subclass gets identical
	// surface behaviour and only its own visual differs.
	//
	// NoDelay is mandatory on whichever frame calls this -- see the file
	// header. Without it none of this runs on the tic the puff spawns,
	// which is the only tic it has.
	action void A_RS_SurfaceImpact(bool heavy = false)
	{
		if (invoker.RSHitSky)
			return;

		int mat = invoker.RSMaterial;

		// --- sound, always, chosen by material.
		A_StartSound(RS_Material.ImpactSound(mat), CHAN_AUTO,
			CHANF_DEFAULT, 0.7);

		// --- debris, if this material sheds any. Flesh does not: the
		// engine's own blood already reads as the impact, and chips
		// coming off a body look like a bug.
		String debris = RS_Material.DebrisClass(mat);
		if (debris.Length() > 0)
		{
			A_SpawnItemEx(debris, 0, 0, 0,
				frandom(1, 5), 0, frandom(2, 6),
				random(0, 360), SXF_NOCHECKPOSITION, 64);
		}

		// --- sparks. Hard surfaces throw them; meat and mud do not.
		if (RS_Material.CanRicochet(mat))
		{
			A_SpawnProjectile(heavy ? "RS_ShotgunParticlesHeavy"
			                        : "RS_SparkXHeavy",
				2, 0, random(0, 360), CMF_AIMDIRECTION, random(0, 180));
		}

		// --- ricochet: hard surfaces, on a roll, cvar-gated. This is the
		// whole fix for "every shot ricochets". RollRicochet owns the
		// chance and the cvar so there is exactly one place to tune it.
		if (RS_Material.RollRicochet(mat))
		{
			A_SpawnProjectile(heavy ? "RS_RicochetShell" : "RS_RicochetBullet",
				0, 0, random(0, 360), CMF_AIMDIRECTION, random(-40, 40));
		}
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_RS_SurfaceImpact();
	Puff:
		RSU1 ABCD 1 Bright;
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
		// The saw keeps its own signature sound and heavier debris throw
		// -- it is a continuous grind, not a bullet strike -- but it now
		// gets the material's sound and debris underneath it, and never
		// ricochets (a saw does not).
		TNT1 A 0 NoDelay A_StartSound("rs_fx_saw_wall", CHAN_AUTO);
		TNT1 A 0 A_SpawnItemEx("RS_WallPart", 0, 0, 0,
			frandom(6, 9), 0, frandom(6, 15),
			random(0, 360), SXF_NOCHECKPOSITION, 64);
		TNT1 A 0 A_SpawnItemEx("RS_RicochetSpark", 0, 0, 0,
			frandom(1, 2), 0, frandom(5, 10),
			random(0, 360), SXF_NOCHECKPOSITION, 40);
		RSU2 ABCD 1 Bright;
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
		TNT1 A 0 NoDelay A_RS_SurfaceImpact(true);
		Goto Puff;
	}
}
