// =====================================================================
// RS_HeavyProjectiles -- Rocket / Plasma / BFG, as data rather than
// hardcoded strings.
// ---------------------------------------------------------------------
// The parallel to RS_BallisticFired: bullets already had a swappable
// ProjectileClass on RS_Weapon plus a SetupStats() the weapon calls at
// spawn time. Heavy ordnance had neither -- every heavy weapon named its
// projectile in a literal string ("Rocket", "PlasmaBall", "BFGBall"), so
// the weapon's rolled DamagePerShot was never applied to it at all. Tier,
// Condition, XP levels, purist mode: none of it reached these three
// weapons. Their damage rolls were decorative.
//
// These three now carry SetupStats(), matching RS_BallisticFired's
// signature and role, and RS_Weapon.A_RS_FireHeavyProjectile() calls it
// the tic the projectile spawns. Same shape as the bullet path, so both
// halves of the arsenal work the same way.
//
// `replaces` is deliberately KEPT on all three. Weapons point their
// HeavyProjectileClass field directly at these class names, so they don't
// rely on the interception -- but plenty of non-weapon things spawn the
// vanilla classes (the Cyberdemon fires a stock Rocket, several monsters
// spawn stock PlasmaBall). Dropping `replaces` would strip the trail
// effects from every one of those. It stays as the net for everything
// this project doesn't fire itself.
//
// At Hi-Fi FX tier Off, Tick() falls straight through to vanilla
// behavior with nothing extra spawned.
// =====================================================================

// ---------------------------------------------------------------------
// Shared behavior for all three. Not a common parent class -- Rocket,
// PlasmaBall and BFGBall each inherit real, different vanilla explosion
// behavior that shouldn't be reimplemented just to force a shared
// ancestor. Instead each class carries the same two members, which is
// the honest cost of ZScript single inheritance from three different
// vanilla bases.
//
// RolledDamage semantics: SetDamage() covers the direct hit. For the
// splash, vanilla's Death state calls A_Explode with its own fixed
// numbers, so scaling that means scaling against the vanilla baseline
// rather than using the rolled value raw -- an uncapped high roll would
// otherwise make a rocket absurd. The ratio below is a first pass, meant
// to be tuned once actually felt in a headset rather than trusted on
// paper (same stance already taken on RS_MuzzleLight's color/radius).
// ---------------------------------------------------------------------

class RS_EnhancedRocket : Rocket replaces Rocket
{
	int trailTimer;
	int RolledDamage;
	double ShotCritChance;

	// Vanilla Rocket: Damage 20, A_Explode(128, 128) on death.
	const VANILLA_DIRECT = 20;
	const VANILLA_SPLASH = 128;

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		ShotCritChance = critChance;
		SetDamage(finalDamage);
	}

	// Splash scales with how far the roll landed from vanilla's direct
	// damage, so a better rocket launcher makes a bigger crater -- but
	// proportionally, not linearly off the raw roll.
	int SplashDamage()
	{
		if (RolledDamage <= 0)
			return VANILLA_SPLASH;
		return int(VANILLA_SPLASH * (double(RolledDamage) / VANILLA_DIRECT));
	}

	override void Tick()
	{
		Super.Tick();
		if (RS_HiFiFX.Tier() == RS_HiFiFX.RSFX_OFF)
			return;
		if (++trailTimer >= 3)
		{
			trailTimer = 0;
			Spawn("RS_SmokingPiece", Pos, NO_REPLACE);
		}
	}

	States
	{
	Death:
		MISL B 8 Bright A_Explode(SplashDamage(), VANILLA_SPLASH);
		MISL C 6 Bright;
		MISL D 4 Bright;
		Stop;
	}
}

class RS_EnhancedPlasmaBall : PlasmaBall replaces PlasmaBall
{
	int trailTimer;
	int RolledDamage;
	double ShotCritChance;

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		ShotCritChance = critChance;
		SetDamage(finalDamage);
	}

	override void Tick()
	{
		Super.Tick();
		if (RS_HiFiFX.Tier() == RS_HiFiFX.RSFX_OFF)
			return;
		if (++trailTimer >= 2)
		{
			trailTimer = 0;
			Spawn("RS_BlueFlarePlasmaTrail", Pos, NO_REPLACE);
		}
	}
}

class RS_EnhancedBFGBall : BFGBall replaces BFGBall
{
	int trailTimer;
	int RolledDamage;
	double ShotCritChance;

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		ShotCritChance = critChance;
		SetDamage(finalDamage);
	}

	override void Tick()
	{
		Super.Tick();
		if (RS_HiFiFX.Tier() == RS_HiFiFX.RSFX_OFF)
			return;
		if (++trailTimer >= 2)
		{
			trailTimer = 0;
			Spawn("RS_BFGTrail", Pos, NO_REPLACE);
		}
	}
}
