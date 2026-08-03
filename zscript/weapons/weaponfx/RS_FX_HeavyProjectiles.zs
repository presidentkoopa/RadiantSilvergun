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
// signature and role, and RS_Weapon.RS_FireProfileHeavy() calls it the
// tic the projectile spawns. Same shape as the bullet path, so both
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
	// Cosmetic only -- swaps the blast's look, never its damage/splash
	// radius (that's still SplashDamage() below via A_Explode). null
	// until PostBeginPlay fills in the Catalog default, or an
	// AttackProfile's own ExplosionVisual overrides it in
	// RS_Weapon.RS_FireProfileHeavy.
	Class<Actor> ExplosionVisual;

	// Set by RS_Weapon.RS_FireProfileHeavy at spawn time when
	// RS_ShotKeywordMods.Resolve found "behavior:homing" granted --
	// same trigger and same A_SeekerMissile call as RS_BallisticFired.
	// Real difference worth flagging: this class is a plain Rocket, NOT
	// FastProjectile. A_SeekerMissile doesn't care about that (it just
	// turns the actor's velocity vector every tic), but the turn math
	// interacts with travel speed, and Rocket's speed/tic is nothing like
	// a FastProjectile's -- don't assume the bullet-mode feel carries over
	// unplaytested.
	bool Homing;

	// Vanilla Rocket: Damage 20, A_Explode(128, 128) on death.
	const VANILLA_DIRECT = 20;
	const VANILLA_SPLASH = 128;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (!ExplosionVisual)
			ExplosionVisual = RS_Catalog.EXPLOSION_Fireball();
	}

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
		if (Homing)
			A_SeekerMissile(6, 10, SMF_LOOK);
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
		// The rocket itself goes invisible on death -- the fireball is a
		// separate, independently-swappable actor (ExplosionVisual), not
		// this class's own sprite. Same 0-tic spawn-frame idiom already
		// used throughout RS_FX_Plasma.zs/RS_FX_BFG.zs.
		TNT1 A 0 A_Explode(SplashDamage(), VANILLA_SPLASH);
		TNT1 A 0 A_SpawnItemEx(ExplosionVisual, 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		Stop;
	}
}

class RS_EnhancedPlasmaBall : PlasmaBall replaces PlasmaBall
{
	int trailTimer;
	int RolledDamage;
	double ShotCritChance;
	Class<Actor> ExplosionVisual;

	// Set by RS_Weapon.RS_FireProfileHeavy at spawn time when
	// RS_ShotKeywordMods.Resolve found "behavior:homing" granted --
	// same trigger and same A_SeekerMissile call as RS_BallisticFired.
	// Real difference worth flagging: this class is a plain PlasmaBall,
	// NOT FastProjectile. A_SeekerMissile doesn't care about that (it just
	// turns the actor's velocity vector every tic), but the turn math
	// interacts with travel speed, and PlasmaBall's speed/tic is nothing
	// like a FastProjectile's -- don't assume the bullet-mode feel carries
	// over unplaytested.
	bool Homing;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (!ExplosionVisual)
			ExplosionVisual = RS_Catalog.PLASMA_Splash();
	}

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		ShotCritChance = critChance;
		SetDamage(finalDamage);
	}

	override void Tick()
	{
		Super.Tick();
		if (Homing)
			A_SeekerMissile(6, 10, SMF_LOOK);
		if (RS_HiFiFX.Tier() == RS_HiFiFX.RSFX_OFF)
			return;
		if (++trailTimer >= 2)
		{
			trailTimer = 0;
			Spawn("RS_BlueFlarePlasmaTrail", Pos, NO_REPLACE);
		}
	}

	States
	{
	Death:
		// Vanilla PlasmaBall has no splash call to preserve (direct-hit
		// only), so a full override is safe. DeathSound still plays --
		// that's the engine's own missile-death handling reading the
		// Default block, not anything in this state.
		TNT1 A 0 A_SpawnItemEx(ExplosionVisual, 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		Stop;
	}
}

class RS_EnhancedBFGBall : BFGBall replaces BFGBall
{
	int trailTimer;
	int RolledDamage;
	double ShotCritChance;
	Class<Actor> ExplosionVisual;

	// Set by RS_Weapon.RS_FireProfileHeavy at spawn time when
	// RS_ShotKeywordMods.Resolve found "behavior:homing" granted --
	// same trigger and same A_SeekerMissile call as RS_BallisticFired.
	// Real difference worth flagging: this class is a plain BFGBall, NOT
	// FastProjectile. A_SeekerMissile doesn't care about that (it just
	// turns the actor's velocity vector every tic), but the turn math
	// interacts with travel speed, and BFGBall's speed/tic is nothing like
	// a FastProjectile's -- don't assume the bullet-mode feel carries over
	// unplaytested.
	bool Homing;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (!ExplosionVisual)
			ExplosionVisual = RS_Catalog.EXPLOSION_FireballAlt();
	}

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		ShotCritChance = critChance;
		SetDamage(finalDamage);
	}

	override void Tick()
	{
		Super.Tick();
		if (Homing)
			A_SeekerMissile(6, 10, SMF_LOOK);
		if (RS_HiFiFX.Tier() == RS_HiFiFX.RSFX_OFF)
			return;
		if (++trailTimer >= 2)
		{
			trailTimer = 0;
			Spawn("RS_BFGTrail", Pos, NO_REPLACE);
		}
	}

	States
	{
	Death:
		// A_BFGSpray is the real damage/ray mechanic -- kept exactly as
		// vanilla, on its original frame. RS_EnhancedBFGExtra/
		// RS_BFGRailPuff (RS_FX_BFG.zs) already give each ray hit its own
		// green-plasma flourish; this only adds a detonation-point visual
		// alongside the untouched spray.
		BFE1 A 8 Bright A_BFGSpray;
		TNT1 A 0 A_SpawnItemEx(ExplosionVisual, 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		BFE1 BCDEF 8 Bright;
		Stop;
	}
}
