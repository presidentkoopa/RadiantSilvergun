// =====================================================================
// RS_EliteProfiles_Projectile -- the three elite profiles that answer
// with ordnance, plus every projectile they throw.
// ---------------------------------------------------------------------
// BLUE    a walking cluster bomb. Occasionally coughs a ring of gravity
//         fireballs when hurt, and detonates into a stacked spiral of
//         them when killed. Both ring sizes are computed from the
//         monster's own bounding box, so a Baron blue and a Zombieman
//         blue are the same idea at different scales.
// VIOLET  sustained pressure. Every 20 tics it picks one of three
//         spreads by weight and throws seeking fireballs on that
//         pattern. It is the only one of the three that is dangerous
//         while alive and at range.
// ORANGE  a bomb with legs. Does nothing at all until it dies, then
//         drops a cluster charge at chest height.
//
// WHY THESE THREE SHARE A FILE: orange's sub-munition is a subclass of
// blue's fireball. They are one dependency, so they are one file and
// blue's projectile is defined above the thing that inherits it.
//
// THE HOOKS, AND WHY OnSelected AND OnReveal BOTH SET THE SAME FIELDS:
// the controller calls OnSelected then OnReveal back to back in the tic
// a monster reveals -- a profile does not exist before that, so there is
// no dormant state and no "has it woken up yet" flag to test anywhere.
// Where a profile sets a value in both hooks, OnReveal's value is the
// one that runs, every time. The OnSelected value is kept anyway: it is
// the honest floor of the behaviour and it keeps the profile correct if
// a later call site ever separates the two.
//
// THE BODY IS NEVER TINTED. A profile's colour reaches the player only
// through GetShade(), which feeds the aura, the particles and the
// pentagram. Our monster art is bespoke per tier and a stencil over
// bespoke art destroys it.
//
// COLOUR LISTS ARE SWITCHES, NOT ARRAYS. `static const color name[]`
// does not resolve on this engine build; it has been found and fixed
// three times in unrelated files here. Do not "tidy" these back into
// tables. Two of violet's shades are also nudged off values GZDoom
// rejects outright as stencils -- see the note on that switch.
// =====================================================================

// ---------------------------------------------------------------------
// BLUE -- rings on damage, a spiral on death.
// ---------------------------------------------------------------------
class RS_EliteProfile_Blue : RS_EliteProfile
{
	int projectiles;    // fireballs per ring
	int tiers;          // rings stacked up the body on death
	int hitPause;       // >0 means the retaliation ring is on cooldown

	// Four shades of the same idea, from saturated to blown-out. The
	// controller reads this once at reveal, so an elite picks one of the
	// family and keeps it for life.
	override color GetShade()
	{
		switch (random(0, 3))
		{
			case 0: return "5959FF";
			case 1: return "8080FF";
			case 2: return "B3B3FF";
		}
		return "FFFFFF";
	}

	override void OnSelected()
	{
		if (!mon)
			return;

		// The only thing OnTick does is age hitPause, so this interval IS
		// the resolution of the retaliation cooldown: a pause of 1-4
		// costs 20-80 tics.
		tickInterval = 20;

		// Both counts come off the monster's own hitbox rather than a
		// table: wider throws a denser ring, taller throws more rings.
		// That is what makes one profile fit every monster in the tree.
		projectiles = max(1, int((mon.Radius * 0.33) * 2));

		// Our boss axis, not the raw flag -- no tier in this tree sets
		// bBOSS, so testing the flag alone would mean tier bosses never
		// got the extra ring. The controller already resolved both axes.
		bool boss = ctl ? ctl.isBoss : mon.bBOSS;

		tiers = int(max(1.0, mon.Height / 32.0));
		tiers = int(tiers * (boss ? 1.5 : 1.0));
	}

	// Roughly a 50% denser ring than the OnSelected figure on a
	// standard-radius monster. Supersedes it in the same tic; see header.
	override void OnReveal()
	{
		if (!mon)
			return;

		projectiles = max(1, int(mon.Radius * 0.50));
	}

	override void OnTick()
	{
		if (hitPause > 0)
			hitPause--;
	}

	// One hit in five, and never while the cooldown is running -- so a
	// hitscan burst cannot chain-trigger this into a wall of fireballs.
	override void OnHit(int damage)
	{
		if (!mon || hitPause > 0)
			return;

		if (random(0, 4))
			return;

		hitPause = random(1, 4);

		// A quarter of the death ring. Floored at one so a small-radius
		// monster cannot divide by zero below.
		int proj2 = max(1, int(projectiles * 0.25));

		// INTEGER division, deliberately kept: the retaliation ring is
		// allowed to be slightly uneven and leave a seam, where the death
		// spiral below closes exactly. Both are as designed.
		double step = double(360 / proj2);

		for (int i = 0; i < proj2; i++)
		{
			mon.A_SpawnProjectile("RS_EliteFireball1",
			                      angle: i * step,
			                      flags: CMF_AIMDIRECTION,
			                      pitch: -6.125);
		}
	}

	override void OnDeath()
	{
		if (!mon || projectiles < 1)
			return;

		double step = 360.0 / double(projectiles);

		for (int j = 0; j < tiers; j++)
		{
			for (int i = 0; i < projectiles; i++)
			{
				// Each ring is rotated half a step past the one below it,
				// so the stack reads as a spiral shell instead of a
				// column of identical rings seen edge-on.
				double ang = ((step * 0.5) * j) + (i * step);

				mon.A_SpawnProjectile("RS_EliteFireball1",
				                      spawnHeight: random(-4, 4) + (24 + (j * 24)),
				                      angle: ang,
				                      flags: CMF_AIMDIRECTION,
				                      pitch: -6.125);
			}
		}
	}
}

// ---------------------------------------------------------------------
// RS_EliteFireball1 -- blue's ring round, and orange's parent class.
//
// Inherits DoomImpBall on purpose: the impact, decal and blocking
// behaviour of a real fireball is behaviour we want and would otherwise
// be reimplementing badly. Everything below is the delta from it.
//
// Gravity 0.1 with -NOGRAVITY is what makes a ring a ring -- the shots
// arc out and fall, so the ring is a spreading dome rather than a flat
// disc that misses everything above or below the shooter.
// ---------------------------------------------------------------------
class RS_EliteFireball1 : DoomImpBall
{
	Default
	{
		-NOGRAVITY
		Speed 10;
		Damage 3;
		Gravity 0.1;
	}

	// A ring thrown into a pack should not be eaten by the pack. Shots
	// pass through anything of the shooter's own class and keep flying;
	// everything else gets default missile handling.
	override int SpecialMissileHit(Actor victim)
	{
		if (victim && target && victim.GetClass() == target.GetClass())
			return 1;

		return -1;
	}

	States
	{
	Spawn:
		CBAL AB 4 Bright;
		Loop;
	Death:
		CBAL CDE 4 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// VIOLET -- the one that is dangerous at range while still alive.
// ---------------------------------------------------------------------
class RS_EliteProfile_Violet : RS_EliteProfile
{
	// TWO OF THESE ARE NUDGED. GZDoom rejects 800080 outright as a
	// stencil colour, so it is A00080 here, and a pure 000000 has to go
	// through the named "Black". The rejected values render as nothing
	// and the aura silently disappears -- see the stencil note in
	// RS_Elites.zs. The black entry is deliberate and does read as an
	// almost-absent aura; that is the shade doing its job, not a fault.
	override color GetShade()
	{
		switch (random(0, 4))
		{
			case 0: return "A00080";
			case 1: return "CC00CC";
			case 2: return "330033";
			case 3: return "FFB3FF";
		}
		return "Black";
	}

	override void OnSelected()
	{
		tickInterval = 30;
	}

	// A third off the cadence. Supersedes the above in the same tic.
	override void OnReveal()
	{
		tickInterval = 20;
	}

	// One shot, at a fixed offset from where the monster is facing.
	// CMF_AIMDIRECTION means the angle is absolute rather than an aim
	// correction, which is what lets case 2 fire backwards. The target
	// check in OnTick is not decoration: A_SpawnProjectile hands the
	// monster's target to a +SEEKERMISSILE round as its tracer, so
	// without a target these would fly straight.
	private void Shoot(double h, double ang)
	{
		if (!mon)
			return;

		mon.A_SpawnProjectile("RS_EliteFireball2", h, 0, ang,
		                      CMF_AIMDIRECTION, -6.125);
	}

	override void OnTick()
	{
		if (!mon || !mon.target)
			return;

		// Fires on two ticks out of three, so the rhythm is uneven and
		// the player cannot count it out.
		if (!random(0, 2))
			return;

		// 9/14 single, 3/14 double, 2/14 the full cross. Written as the
		// literal weighted pick rather than a range test so the weights
		// stay readable and stay exactly these weights.
		int pick = randompick(0, 0, 0,
		                      0, 0, 0,
		                      0, 0, 0,
		                      1, 1, 1,
		                      2, 2);

		double h = mon.Height * 0.5;

		switch (pick)
		{
			case 0:
				Shoot(h,   0.0);
				Shoot(h, -12.5);
				Shoot(h, +12.5);
				break;

			case 1:
				Shoot(h, -12.5);
				Shoot(h, +12.5);
				Shoot(h, -25.0);
				Shoot(h, +25.0);
				break;

			case 2:
				// The cross, then the diagonals. -130 is not a typo for
				// -135: the eighth shot is deliberately off-axis so the
				// full spread never looks like a machine-drawn star.
				Shoot(h,    0.0);
				Shoot(h,  +90.0);
				Shoot(h,  -90.0);
				Shoot(h, -180.0);
				Shoot(h,  +45.0);
				Shoot(h,  -45.0);
				Shoot(h, +135.0);
				Shoot(h, -130.0);
				break;
		}
	}
}

// ---------------------------------------------------------------------
// RS_EliteFireball2 -- violet's seeker.
//
// Same chassis as blue's round, minus the pass-through and plus a slow
// track. Turn rate 4 with threshold 0 means it corrects every spawn
// frame but only slightly: it will curve into a strafing player and will
// not curve around a pillar. No Damage line -- it keeps DoomImpBall's,
// and that is intentional, not an omission.
// ---------------------------------------------------------------------
class RS_EliteFireball2 : DoomImpBall
{
	Default
	{
		-NOGRAVITY
		+SEEKERMISSILE
		Speed 10;
		Gravity 0.1;
	}

	States
	{
	Spawn:
		CBAL AB 4 Bright A_SeekerMissile(0, 4);
		Loop;
	Death:
		CBAL CDE 4 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// ORANGE -- inert until it dies. That is the whole profile.
//
// tickInterval is never set, so it never ticks, and it overrides no hit
// behaviour. An orange elite fights exactly like an ordinary elite right
// up until the corpse goes off.
// ---------------------------------------------------------------------
class RS_EliteProfile_Orange : RS_EliteProfile
{
	double        missileOfs;
	class<Actor>  explosionType;

	override color GetShade()
	{
		switch (random(0, 4))
		{
			case 0: return "FFFFFF";
			case 1: return "FF9900";
			case 2: return "FFAD33";
			case 3: return "FF5C33";
		}
		return "FF3300";
	}

	override void OnSelected()
	{
		if (!mon)
			return;

		// Chest height, not the floor: a blast centred at the feet is
		// eaten by the step the monster is standing on.
		missileOfs = mon.Height * 0.5;

		// Explicit class-lookup cast, the same habit as RS_Upgrade_Slate:
		// a bare string standing in for a Class<Actor> is not reliable on
		// this engine.
		explosionType = (Class<Actor>)("RS_EliteExplosion");
	}

	// The upgrade to sub-munitions. Supersedes the above in the same tic,
	// which means the plain charge is currently the unreachable floor of
	// this profile rather than a thing players will see. It is kept
	// because it is the correct no-reveal behaviour and because it is
	// where the shared explosion shape is written down.
	override void OnReveal()
	{
		explosionType = (Class<Actor>)("RS_EliteClusterExplosion");
	}

	override void OnDeath()
	{
		if (!mon || explosionType == null)
			return;

		let boom = mon.Spawn(explosionType,
		                     (mon.Pos.X, mon.Pos.Y, mon.Pos.Z + missileOfs),
		                     NO_REPLACE);

		// The blast is attributed to whatever the elite was fighting, not
		// to the elite. Consequence, and it is the source behaviour: the
		// splash is credited to the player, so monsters caught in it get
		// angry at the player rather than at a corpse.
		if (boom)
			boom.target = mon.target;
	}
}

// ---------------------------------------------------------------------
// RS_EliteExplosion -- a bang at a position, and nothing else.
//
// Rocket with Speed 0 so it inherits the real rocket blast, its damage
// type and its decal, then sits still. -ROCKETTRAIL because a stationary
// rocket smoking in place looks like a dud.
// ---------------------------------------------------------------------
class RS_EliteExplosion : Rocket
{
	Default
	{
		-ROCKETTRAIL
		Speed 0;
	}

	States
	{
	// NO Stop OR Loop HERE, ON PURPOSE. Spawn falls straight through into
	// Death on the tic it appears, and that fallthrough is the entire
	// detonation mechanism -- this actor is never killed by anything.
	// Adding a terminator to "fix" the state leaves a live rocket sitting
	// in the world forever.
	Spawn:
		TNT1 A 0 NoDelay A_StartSound("weapons/rocklx", CHAN_BODY);
	Death:
		OEXP A 8 Bright A_Explode();
		OEXP B 6 Bright;
		OEXP C 4 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// RS_EliteClusterExplosion -- the same bang, plus shrapnel.
// ---------------------------------------------------------------------
class RS_EliteClusterExplosion : Rocket
{
	Default
	{
		-ROCKETTRAIL
		Speed 0;
	}

	States
	{
	// Same deliberate fallthrough as the plain charge above.
	Spawn:
		TNT1 A 0 NoDelay A_StartSound("weapons/rocklx", CHAN_BODY);
	Death:
		OEXP A 8 Bright
		{
			// Eight sub-munitions thrown out and up, then the main blast.
			// ALL OF IT ON ONE FRAME, DELIBERATELY: a state action fires
			// once per FRAME, so hanging this off OEXP A B C would triple
			// both the shrapnel and the explosion.
			for (int i = 0; i < 8; i++)
			{
				A_SpawnItemEx("RS_EliteMiniCluster",
				              xvel:  frandom(4.0, 8.0),
				              zvel:  frandom(4.0, 8.0),
				              angle: random(0, 360));
			}

			A_Explode();
		}
		OEXP B 6 Bright;
		OEXP C 4 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// RS_EliteMiniCluster -- the shrapnel. THIS IS THE CROSS-PROFILE
// DEPENDENCY: orange's sub-munition is blue's fireball with a heavier
// arc, so blue's class has to exist above this one.
//
// It carries NO impact damage at all -- the roll is zero and the entire
// threat is the small A_Explode when it lands. That is what keeps eight
// of them from being an instant kill on contact while still making the
// ground dangerous for a couple of seconds.
// ---------------------------------------------------------------------
class RS_EliteMiniCluster : RS_EliteFireball1
{
	Default
	{
		DamageFunction (0);
		Gravity 0.6;
		Scale 0.75;
		DeathSound "";
		RenderStyle "Normal";
		+DEHEXPLOSION
	}

	States
	{
	// Spawn is inherited from the parent -- these only differ in how they
	// land.
	Death:
		OEXP A 8 Bright
		{
			A_Explode(64, 64);
			// Quiet: eight of these landing at once at full volume is a
			// wall of noise that buries the main blast.
			A_StartSound("weapons/rocklx", CHAN_BODY, volume: 0.2);
		}
		OEXP B 6 Bright;
		OEXP C 4 Bright;
		Stop;
	}
}
