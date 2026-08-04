// =====================================================================
// RS_GH_ projectiles -- catalog entries for the GunstarHeroes set.
// ---------------------------------------------------------------------
// These are the reusable attack payloads, not weapon-owned code. Any
// weapon can reference them via RS_Catalog; the launched grenade below
// is used by the Machine Gun's underbarrel alt-fire today and is the
// same entry a future Grenade Launcher import will point at rather than
// duplicating.
//
// Built on RS_Weapon's heavy-projectile contract (SetupStats, scaled
// splash) exactly like RS_EnhancedRocket -- NOT ported from the source's
// own thrown-grenade class, which lives in its weapon base and drags in
// that whole parallel system. Only the BEHAVIOUR was taken from the source:
// arcing lob, bounces, two-stage detonation at 70% damage / 50% radius
// of a hand grenade.
// =====================================================================

class RS_GH_GrenadeLaunched : Actor
{
	int RolledDamage;
	double ShotCritChance;

	// Source anchors (launched grenade): A_Explode(60,100) then
	// A_Explode(84,64). Those are the vanilla-equivalent baseline the
	// rolled damage scales against, same approach RS_EnhancedRocket
	// takes -- a better gun makes a bigger crater proportionally,
	// instead of the raw roll being used as splash directly.
	const BASE_DIRECT  = 60;
	const BASE_SPLASH1 = 60;
	const BASE_RADIUS1 = 100;
	const BASE_SPLASH2 = 84;
	const BASE_RADIUS2 = 64;

	Default
	{
		Radius 6;
		Height 6;
		Speed 33;          // launcher muzzle velocity, from the source
		Damage 0;          // all damage is via A_Explode below
		Gravity 0.7;       // the arc
		Projectile;
		-NOGRAVITY
		+THRUSPECIES
		Species "Player";
		BounceType "Doom";
		BounceFactor 0.4;
		WallBounceFactor 0.4;
		BounceSound "rs_gh/grenade_bounce";
		DamageType "Explosive";
		Scale 0.6;
	}

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage   = finalDamage;
		ShotCritChance = critChance;
	}

	// Real toss speed for the hand-thrown grenade (source thrown-grenade,
	// Speed 10) -- a slow, high arc, distinct from the launcher's faster
	// punch-out. Was sharing this class's own Speed 33 (the LAUNCHER's
	// speed) with no distinction at all; that's fixed by subclassing below
	// rather than editing Speed here, so the Grenade Launcher keeps its
	// real launcher speed unchanged.

	double DamageRatio()
	{
		if (RolledDamage <= 0)
			return 1.0;
		return double(RolledDamage) / BASE_DIRECT;
	}

	int Splash1() { return int(BASE_SPLASH1 * DamageRatio()); }
	int Splash2() { return int(BASE_SPLASH2 * DamageRatio()); }

	States
	{
	Spawn:
		JGRN ABCDEFGH 2;
		Loop;

	Death:
		TNT1 A 0 A_NoBlocking;
		TNT1 A 0 A_AlertMonsters;
		TNT1 A 0 A_ChangeFlag("NOGRAVITY", true);
		// Two-stage blast, same shape as the source: a tighter hard hit
		// inside a wider concussion.
		TNT1 A 1 Bright A_Explode(Splash1(), BASE_RADIUS1, 1);
		TNT1 A 1 Bright A_Explode(Splash2(), BASE_RADIUS2, 1);
		TNT1 A 0 A_StartSound("rs_fx_rocket_explode", CHAN_AUTO);
		Stop;
	}
}

// Hand-thrown variant -- same real arc/bounce/two-stage blast, just the
// real slower toss speed (source thrown-grenade, Speed 10) instead of
// the launcher's faster punch-out. Everything else (damage scaling,
// bounce, death FX) is identical, inherited as-is.
class RS_GH_GrenadeThrown : RS_GH_GrenadeLaunched
{
	Default
	{
		Speed 10;
	}
}
