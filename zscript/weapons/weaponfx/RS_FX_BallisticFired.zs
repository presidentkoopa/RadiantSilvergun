// =====================================================================
// RS_BallisticFired -- Master Ballistic Projectile & Visual Manager
// ---------------------------------------------------------------------
// Sibling file to RS_HeavyProjectiles.zs
// Base master class for all ballistic projectiles. Inherits from 
// FastProjectile to prevent high-speed projectiles from tunneling.
// Stats are dynamically assigned by the firing weapon via SetupStats.
// =====================================================================

class RS_BallisticFired : FastProjectile
{
	double ShotCritChance;
	int ghostTimer;

	Default
	{
		Radius 2;
		Height 2;
		Speed 100; // Fallback only; overridden immediately on spawn
		Damage 5;  // Fallback only; overridden immediately on spawn
		Projectile;
		+THRUSPECIES
		Species "Player";
	}

	// Lives here, not on any subclass, so every visual variant --
	// including future ones a GunBonsai-style system swaps in -- gets
	// the same fading trail for free just by inheriting from this class.
	override void Tick()
	{
		Super.Tick();
		if (++ghostTimer >= 2)
		{
			ghostTimer = 0;
			let ghost = RS_BallisticGhost(Spawn("RS_BallisticGhost", pos));
			if (ghost)
			{
				ghost.sprite = sprite;
				ghost.frame = frame;
				ghost.scale = scale;
				ghost.Alpha = 0.55;
			}
		}
	}

	// -----------------------------------------------------------------
	// SetupStats is called by RS_Weapon the exact tic the bullet spawns.
	// It takes the weapon's rolled DamagePerShot (already modified by 
	// GetConditionEffects), the rolled Velocity, and CritChance.
	// -----------------------------------------------------------------
	void SetupStats(int finalDamage, double rolledVelocity, double critChance)
	{
		// 1. Assign the dynamically rolled damage
		SetDamage(finalDamage);

		// 2. Assign the dynamically rolled velocity and recalculate trajectory
		Speed = rolledVelocity;
		Vel3DFromAngle(Speed, Angle, Pitch);

		// 3. Store the rolled crit chance for impact calculations
		ShotCritChance = critChance;
	}

	States
	{
	Spawn:
		BAL1 A 1 Bright;
		Loop;

	Death:
		TNT1 A 0 A_PlaySound("ballisticimpact", CHAN_AUTO);
		RSU0 A 4;
		Stop;
	}
}

// =====================================================================
// RS_BallisticType1 -- First Selectable Ballistic Visual Type
// ---------------------------------------------------------------------
// Inherits from the master file and applies the in-flight sprite
// animation frames named BB01 sequentially while traveling.
// =====================================================================

class RS_BallisticType1 : RS_BallisticFired
{
	States
	{
	Spawn:
		BB01 A 2 Bright;
		BB01 B 2 Bright;
		BB01 C 2 Bright;
		BB01 D 2 Bright;
		BB01 E 2 Bright;
		Loop;
	}
}

// =====================================================================
// RS_BallisticGhost -- one fading afterimage, spawned periodically along
// a bullet's path. Never collides with anything or affects gameplay --
// purely the trail effect behind an in-flight round.
// =====================================================================

class RS_BallisticGhost : Actor
{
	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+NOTELEPORT
		+CANNOTPUSH
		RenderStyle "Translucent";
	}

	States
	{
	Spawn:
		TNT1 A 1 A_FadeOut(0.11);
		Loop;
	}
}