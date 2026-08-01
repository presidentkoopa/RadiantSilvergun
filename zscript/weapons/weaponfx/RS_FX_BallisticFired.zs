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

	// Player Feedback layer override -- null means "use this Sequence's
	// own built-in default impact." Set via SetupFeedback(), called from
	// RS_Weapon's dispatch right alongside SetupStats(). Every subclass
	// that defines its own Death: state (RS_RailBolt, etc.) checks
	// these the same way, so the override works uniformly across every
	// bullet-mode Sequence in the game, not just this base one.
	Class<Actor> ImpactPuffOverride;
	Class<Actor> ImpactSparkOverride;
	Class<Actor> TrailOverride;

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
			Class<Actor> trail = TrailOverride ? TrailOverride : RS_Catalog.TRAIL_Ballistic();
			Spawn(trail, pos);
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

	// Player Feedback layer -- called alongside SetupStats() by whatever
	// spawned this round, if the firing profile set an ImpactPuff/
	// ImpactSparks/Trail override. Leaving any of them unset (null) means
	// this Sequence falls back to RS_Catalog's default for that slot --
	// never affects FireSound, which is the weapon's own, set separately
	// per weapon in its own BuildAttackProfiles().
	void SetupFeedback(Class<Actor> puffOverride, Class<Actor> sparkOverride, Class<Actor> trailOverride = null)
	{
		ImpactPuffOverride = puffOverride;
		ImpactSparkOverride = sparkOverride;
		TrailOverride = trailOverride;
	}

	States
	{
	Spawn:
		BAL1 A 1 Bright;
		Loop;

	Death:
		TNT1 A 0 A_PlaySound("rs_fx_impact_bullet", CHAN_AUTO);
		TNT1 A 0
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Class<Actor> spark = ImpactSparkOverride ? ImpactSparkOverride : RS_Catalog.SPARK_Hit();
			Spawn(puff, pos);
			if (spark) Spawn(spark, pos);
		}
		Stop;
	}
}

// =====================================================================
// RS_BallisticType1 -- First Selectable Ballistic Visual Type
// ---------------------------------------------------------------------
// Inherits from the master file and applies the in-flight sprite
// animation frames named RSB0 sequentially while traveling.
// =====================================================================

class RS_BallisticType1 : RS_BallisticFired
{
	States
	{
	Spawn:
		RSB0 A 2 Bright;
		RSB0 B 2 Bright;
		RSB0 C 2 Bright;
		RSB0 D 2 Bright;
		RSB0 E 2 Bright;
		Loop;
	}
}

// =====================================================================
// RS_BallisticTrail -- one fading, additive-glow trail piece, spawned
// periodically along a bullet's path. Never collides with anything or
// affects gameplay -- purely the trail effect behind an in-flight round.
// Adopted directly from the TrueBullet reference (TB_TrailBit): additive
// render + small scale + fast two-frame fade is what makes the trail
// glow instead of just fading like a flat sprite. Deliberately not named
// with "Bit" -- that word means the Health/Armor/Ammo/Grey/Curse kill-
// reward currency pickups elsewhere in this project (RS_Bits.zs); reusing
// it here would be confusing.
// =====================================================================

class RS_BallisticTrail : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY +NOTIMEFREEZE
		RenderStyle "Add";
		Scale 0.30;
		Alpha 0.85;
	}
	States
	{
	Spawn:
		RSB0 B 2 Bright A_FadeOut(0.22);
		RSB0 C 2 Bright A_FadeOut(0.28);
		Stop;
	}
}