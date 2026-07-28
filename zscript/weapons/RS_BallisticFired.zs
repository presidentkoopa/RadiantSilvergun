// =====================================================================
// RS_BallisticFired -- Master Ballistic Projectile & Visual Manager
// ---------------------------------------------------------------------
// Base master class for all ballistic projectiles. Inherits from 
// FastProjectile to prevent high-speed projectiles from tunneling.
// Stats are dynamically assigned by the firing weapon via SetupStats.
// =====================================================================

class RS_BallisticFired : FastProjectile
{
	double ShotCritChance;

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
		PUFF A 4;
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