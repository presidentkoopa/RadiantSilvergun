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

	// Set by RS_Weapon.RS_FireProfileBullet at spawn time when
	// RS_ShotKeywordMods.Resolve found "behavior:homing" granted
	// (weapon-wide or on this specific rotation beat). Real native
	// GZDoom seeking, not a custom implementation -- SMF_LOOK means it
	// acquires its own target instead of needing tracer pre-set, which
	// is what a player-fired round needs (nothing sets tracer for us).
	// Flagged, not fully verified: this class extends FastProjectile,
	// and FastProjectile + A_SeekerMissile is a known-working
	// combination in other GZDoom mods, but hasn't been playtested here
	// yet -- confirm turn rate/feel in a real playthrough before
	// trusting the tuning numbers below.
	bool Homing;

	// --- Seeker affix (docs/rs_09_affix_slate.txt) ---
	// A Seeker round homes true from level 1; what levels buy is
	// CYCLING: when the locked target dies, the round may drop lock and
	// re-acquire, SeekLevel-1 times (99 = unlimited, Mastery). Precise
	// adds SMF_PRECISE hard tracking.
	int    SeekLevel;
	int    RetargetsUsed;
	bool   SeekPrecise;
	// Tracking authority in deg/tic, scaled from the firer's rolled
	// Accuracy at spawn (rs_11 amplifier rule). 0 = legacy fixed 6/10.
	double SeekTurn;

	// --- Ghost affix ---
	// PierceLimit: how many victims this round may punch through before
	// it stops ripping (99 = all). PierceRetention: damage kept per
	// punch-through, applied in DoSpecialDamage. StitchOnKill (Mastery):
	// a rip-kill flips the round into an unlimited seeker mid-flight,
	// visibly stitching the crowd together.
	int    PierceLimit;
	double PierceRetention;
	int    PierceHits;
	bool   StitchOnKill;

	// --- Monster-signature spray (wave D1, docs/rs_13) ---
	// How many sub-projectiles this round releases and whether they
	// seek. Set at spawn from RS_ShotKeywordMods; the signature adapter
	// classes (RS_FX_AffixParts.zs) read them. 0 = no spray, which is
	// every round that isn't a Swarm/Nova signature.
	int  SprayCount;
	bool SpraySeek;

	// --- Minimal impact-spawn hook ---
	// Spawned at the impact point alongside the puff/spark, when set.
	// This is the hook the payload:explosive/hazard keywords have been
	// waiting for; its first real consumer is Painter's Mastery ignite
	// (RS_AffixGroundFire). Null = nothing extra, the universal default.
	Class<Actor> ImpactSpawnExtra;

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
		if (Homing)
		{
			// Seeker cycling: when the locked target dies, drop lock so
			// SMF_LOOK re-acquires -- if this round has retargets left.
			// SeekLevel 0 (plain behavior:homing, no Seeker affix) keeps
			// the original semantics: one lock, no cycling.
			if (tracer && tracer.health <= 0)
			{
				if (SeekLevel > 0 && (SeekLevel >= 99 || RetargetsUsed < SeekLevel - 1))
				{
					tracer = null;
					RetargetsUsed++;
				}
				else
					Homing = false;
			}
			if (Homing)
			{
				int flags = SMF_LOOK | (SeekPrecise ? SMF_PRECISE : 0);
				if (SeekTurn > 0)
					A_SeekerMissile(int(SeekTurn * 0.6), int(SeekTurn), flags);
				else
					A_SeekerMissile(6, 10, flags);
			}
		}
		if (++ghostTimer >= 2)
		{
			ghostTimer = 0;
			Class<Actor> trail = TrailOverride ? TrailOverride : RS_Catalog.TRAIL_Ballistic();

			// Layered echo trail. One bit at the round's own position used to
			// be the whole effect, which reads as a dotted line at speed
			// because a fast round moves further between emissions than the
			// bit is wide. Instead drop three, walked BACKWARDS along this
			// tic's velocity vector at 0.2/0.4/0.6 of it -- i.e. into the gap
			// the round just crossed -- each one smaller than the last.
			//
			// The gap gets filled, so it reads as a tapered streak with a
			// bright head rather than beads. Additive blending means the
			// overlaps brighten on their own, and FORCEXYBILLBOARD on the
			// trail bit keeps the streak facing the viewer -- which is what
			// stops it going edge-on and vanishing in VR.
			//
			// NOW ON THE PERFORMANCE DIAL, as this comment always said it
			// should be. Fixed 2026-08-07.
			//
			// This was the single highest-volume effect in the game and
			// the ONLY one exempt from rs_fx_hifitier: 3 actors per 2 tics
			// per round, and a round is per PELLET -- so one shotgun blast
			// with 9 pellets was 27 actors every other tic for the whole
			// flight. The heavy projectiles all gate their trails
			// correctly (RS_FX_HeavyProjectiles.zs); only the bullet path
			// didn't. Setting FX to Off left the worst offender running at
			// full density, which made the dial look broken.
			//
			// Off = no trail at all. Standard = the single head bit, which
			// is what this effect was before the layered version. Hi-Fi =
			// the full three-bit tapered streak.
			int tier = RS_HiFiFX.Tier();
			if (tier == RS_HiFiFX.RSFX_OFF)
				return;
			int bits = (tier == RS_HiFiFX.RSFX_STANDARD) ? 1 : 3;

			for (int i = 1; i <= bits; i++)
			{
				double f = i * 0.2;
				let p = Spawn(trail, pos - (vel.x * f, vel.y * f, vel.z * f));
				if (p)
				{
					double s = 0.40 - i * 0.09;   // 0.31 / 0.22 / 0.13
					p.Scale = (s, s);
				}
			}
		}
	}

	// ONE DoSpecialDamage override doing BOTH jobs, in the right order --
	// exact damage first, then Ghost's pierce economy on top of it.
	//
	// Exact damage: DoSpecialDamage, not GetMissileDamage -- the latter
	// is exposed to ZScript as native non-virtual and cannot be
	// overridden (real compile error). This hook runs after the engine
	// has already applied its random(1,8) roll, so overwriting the
	// incoming value with ExactDamage replaces that roll outright:
	// rounds deal exactly what SetupStats was given, and bullet/hitscan
	// modes finally agree.
	//
	// Pierce economy (Ghost affix): retention decay per punch-through,
	// a hard stop when the punch budget runs out, and the Mastery
	// stitch. Rounds without PierceLimit set (including plain
	// behavior:piercing rips) skip that block entirely.
	override int DoSpecialDamage(Actor victim, int damage, Name damagetype)
	{
		if (ExactDamage > 0)
			damage = ExactDamage;

		if (PierceLimit > 0 && bRIPPER)
		{
			damage = max(1, int(damage * (PierceRetention ** PierceHits)));
			PierceHits++;

			// Mastery: this hit will kill, and the round is allowed to
			// keep going -- turn it into an unlimited precise seeker so
			// it visibly whips toward its next victim.
			if (StitchOnKill && victim && victim.health <= damage)
			{
				Homing = true;
				SeekLevel = 99;
				SeekPrecise = true;
				if (SeekTurn <= 0) SeekTurn = 12;
				tracer = null;
			}

			// Punch budget spent: stop ripping. The round detonates on
			// the next thing it touches instead of passing through.
			if (PierceLimit < 99 && PierceHits >= PierceLimit)
				bRIPPER = false;
		}
		return Super.DoSpecialDamage(victim, damage, damagetype);
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
		ExactDamage = finalDamage;

		// 2. Assign the dynamically rolled velocity and recalculate trajectory
		Speed = rolledVelocity;
		Vel3DFromAngle(Speed, Angle, Pitch);

		// 3. Store the rolled crit chance for impact calculations
		ShotCritChance = critChance;
	}

	// The engine's default missile-damage formula multiplies the stored
	// damage by random(1,8) on impact. ExactDamage, applied in the
	// merged DoSpecialDamage override above, replaces that roll so every
	// ballistic round deals exactly what SetupStats was given.
	int ExactDamage;

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
		TNT1 A 0 A_StartSound("rs_fx_impact_bullet", CHAN_AUTO);
		TNT1 A 0
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Class<Actor> spark = ImpactSparkOverride ? ImpactSparkOverride : RS_Catalog.SPARK_Hit();
			Spawn(puff, pos);
			if (spark) Spawn(spark, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
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