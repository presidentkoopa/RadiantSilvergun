// =====================================================================
// RS_FX_AffixParts -- projectile bodies and impact pieces owned by the
// DESIGNED affixes (docs/rs_09_affix_slate.txt), installed through the
// RS_Weapon Affix* part-swap layer. This file is the proof of that
// layer: before it, the Affix* fields had no writer anywhere.
//
// Asset rules obeyed here (learned the hard way, see rs_MASTER_FX_CATALOG):
//   * Every sprite referenced is either vanilla-IWAD (FATB, BAL2, BFE2,
//     PUFF) or verified in-repo (RSI1 fire loop, RSE4/RSE5 explosions,
//     ICEY -- imported from ART SOURCE/CH and VIEWED before import:
//     A/B/C are the spiky tumbling shard, F/G/H/I the crystal orb).
//     ICEY has NO D/E frames -- do not "fix" a death state to CDE.
//   * Ice sounds are real imports (sounds/combatfx/ice/, SNDINFO
//     rs_fx_ice_*). Bone sounds are vanilla skeleton/* -- zero risk.
//   * Ballistic adapters extend RS_BallisticFired, so they ride the
//     whole pipeline (SetupStats exact damage, trails, feedback,
//     seek/pierce fields) for free. The ONE plain-Actor part is the
//     bouncing orb -- FastProjectile cannot bounce, engine limitation,
//     which is exactly why RS_AffixPartActor exists.
// =====================================================================

// ---------------------------------------------------------------------
// Plain-Actor part base. The bullet path's RS_FireAffixPartRound spawns
// these when the installed AffixProjectile isn't ballistic: exact
// damage (same DoSpecialDamage override contract as the ballistic
// tree), own authored flight, master pointer set by the caller.
// ---------------------------------------------------------------------
class RS_AffixPartActor : Actor
{
	int ExactDamage;

	Default
	{
		Projectile;
		Radius 6;
		Height 8;
		Speed 25;
		Damage 5;   // fallback; ExactDamage overrides on spawn
		+THRUSPECIES
		Species "Player";
	}

	// See RS_BallisticFired: GetMissileDamage is native non-virtual and
	// cannot be overridden. DoSpecialDamage is virtual and runs after the
	// engine's random(1,8) roll, so returning the exact value replaces it.
	override int DoSpecialDamage(Actor target, int damage, Name damagetype)
	{
		if (ExactDamage > 0)
			return ExactDamage;
		return Super.DoSpecialDamage(target, damage, damagetype);
	}
}

// ---------------------------------------------------------------------
// PAINTER -- thermal wardrobe, two families. Which family a given gun
// gets is rolled once when the affix is taken (the upgrade stores the
// roll); levels grow the math, not the family.
// ---------------------------------------------------------------------

// Family A "Wisp" -- in-repo RSI1 rolling flame, a ball of living fire.
class RS_AffixFireWisp : RS_BallisticFired
{
	Default
	{
		DamageType "Fire";
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.35;
		+BRIGHT
	}
	States
	{
	Spawn:
		RSI1 ABCDEFGHIJKLM 2 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("rs_fx_impact_bullet", CHAN_AUTO);
		RSE5 A 3 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
		}
		Stop;
	}
}

// Family B "Ember" -- vanilla caco-ball fireball shedding hot sparks.
class RS_AffixFireEmber : RS_BallisticFired
{
	int emberTimer;

	Default
	{
		DamageType "Fire";
		RenderStyle "Add";
		Alpha 0.95;
		Scale 0.5;
		+BRIGHT
	}

	override void Tick()
	{
		Super.Tick();
		if (++emberTimer >= 3)
		{
			emberTimer = 0;
			Spawn("RS_HitSpark", pos);
		}
	}

	States
	{
	Spawn:
		BAL2 AB 4 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("rs_fx_impact_bullet", CHAN_AUTO);
		RSE4 A 2 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
		}
		RSE4 BC 2 Bright;
		Stop;
	}
}

// Painter Mastery's ground fire -- the impact-spawn hook's first real
// consumer. Burns in place for ~3 seconds, pulsing modest radius
// damage. Damage is deliberately small and FIXED: the round's rolled
// damage already paid out on impact; this is area denial, not a
// second payload.
class RS_AffixGroundFire : Actor
{
	Default
	{
		Radius 12;
		Height 16;
		RenderStyle "Add";
		Alpha 0.85;
		Scale 0.6;
		DamageType "Fire";
		+NOBLOCKMAP
		+BRIGHT
	}
	States
	{
	Spawn:
		RSI1 ABCDEFGHIJKLM 2 Bright;
		RSI1 A 0 A_Explode(4, 64, 0, false);
		RSI1 ABCDEFGHIJKLM 2 Bright;
		RSI1 A 0 A_Explode(4, 64, 0, false);
		RSI1 ABCDEFGHIJKLM 2 Bright;
		RSI1 A 0 A_Explode(4, 64, 0, false);
		RSI1 MLKJIHG 3 Bright A_FadeOut(0.09);
		Stop;
	}
}

// ---------------------------------------------------------------------
// BONECALLER -- the Revenant tracer, weapon-grade. Vanilla FATB smoke-
// skull sprite, vanilla skeleton sounds, BFE2 blast on impact. Homing
// is decided per pellet by the fire path (HomingChance), so ONE class
// serves straight rounds and hunters alike.
// ---------------------------------------------------------------------
class RS_AffixBoneTracer : RS_BallisticFired
{
	Default
	{
		DamageType "Fire";
		RenderStyle "Add";
		Alpha 0.95;
		Scale 0.5;
		DeathSound "skeleton/tracex";
		Decal "RevenantScorch";
		+BRIGHT
	}
	States
	{
	Spawn:
		FATB AB 2 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("skeleton/tracex", CHAN_AUTO);
		BFE2 A 4 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
		}
		BFE2 BCDE 4 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// CRYO -- imported ICEY art (viewed: A/B spiky tumbling shard flight,
// F-I crystal shatter) + imported CH ice audio.
// ---------------------------------------------------------------------

// L1-5 round: the ice shard.
class RS_AffixIceShard : RS_BallisticFired
{
	Default
	{
		DamageType "Ice";
		RenderStyle "Add";
		Alpha 0.95;
		Scale 0.75;
		DeathSound "rs_fx_ice_hit";
		+BRIGHT
	}
	States
	{
	Spawn:
		ICEY AB 3 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("rs_fx_ice_hit", CHAN_AUTO);
		ICEY F 3 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
		}
		ICEY GHI 3 Bright;
		Stop;
	}
}

// Mastery round: the bouncing orb. Plain Actor ON PURPOSE -- this is
// the whole reason RS_AffixPartActor exists (FastProjectile cannot
// bounce). Flies at its own authored lob speed, not the weapon's
// rolled bullet velocity; bounces off floors up to 3 times, shattering
// on whatever it finally hits. Modest fixed splash on death -- the
// round's exact rolled damage still rides the direct hit.
class RS_AffixIceOrb : RS_AffixPartActor
{
	Default
	{
		DamageType "Ice";
		RenderStyle "Add";
		Alpha 0.95;
		Scale 1.3;
		Radius 10;
		Height 10;
		Speed 30;
		-NOGRAVITY
		Gravity 0.4;
		BounceType "Doom";
		BounceCount 3;
		BounceSound "rs_fx_ice_hit";
		+BOUNCEONFLOORS
		DeathSound "rs_fx_ice_shatter";
		+BRIGHT
	}
	States
	{
	Spawn:
		ICEY AB 3 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("rs_fx_ice_shatter", CHAN_AUTO);
		ICEY F 3 Bright A_Explode(20, 96, 0, false);
		ICEY GHI 3 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// CACOSPIT (Monster Signature) -- the Cacodemon's own bile ball,
// weapon-grade. Vanilla BAL2 sprite + vanilla caco sounds: zero asset
// risk. Wardrobe family A for TFLV_Upgrade_RS_Cacospit (family B is
// the RSI1 hell-wisp above).
// ---------------------------------------------------------------------
class RS_AffixCacoBall : RS_BallisticFired
{
	Default
	{
		DamageType "Fire";
		RenderStyle "Add";
		Alpha 0.95;
		Scale 0.55;
		DeathSound "caco/shotx";
		+BRIGHT
	}
	States
	{
	Spawn:
		BAL2 AB 4 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("caco/shotx", CHAN_AUTO);
		BAL2 C 4 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
		}
		BAL2 DE 4 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// PAIN ORB Mastery round -- the orb grown up: bigger, six bounces,
// and a three-shard spray when it finally shatters. Spray shards are
// the fixed-damage subclass below, NOT full rolled rounds -- the
// orb's own rolled damage already paid out on the direct hit.
// ---------------------------------------------------------------------
class RS_AffixIceShardSpray : RS_AffixIceShard
{
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		// Fixed modest damage; without this the engine's random(1,8)
		// would multiply the class's fallback Damage unpredictably.
		SetDamage(8);
		ExactDamage = 8;
	}
}

class RS_AffixPainOrbMaster : RS_AffixIceOrb
{
	Default
	{
		Scale 1.6;
		Radius 12;
		Height 12;
		BounceCount 6;
	}
	States
	{
	Death:
		TNT1 A 0 A_StartSound("rs_fx_ice_shatter", CHAN_AUTO);
		ICEY F 3 Bright
		{
			A_Explode(24, 112, 0, false);
			for (int i = 0; i < 3; i++)
			{
				let s = Spawn("RS_AffixIceShardSpray", pos + (0, 0, 8));
				if (s)
				{
					s.angle = angle + 120 * i;
					s.VelFromAngle(18);
					s.vel.z = frandom(2, 5);
					s.master = master;
				}
			}
		}
		ICEY GHI 3 Bright;
		Stop;
	}
}

// =====================================================================
// WAVE D1 -- MONSTER SIGNATURES (docs/rs_13 shortlist entries 01/04/08)
// ---------------------------------------------------------------------
// Every asset below is IWAD-vanilla or verified in-repo. None of these
// wear a CH-external sprite or sound: a signature that renders
// invisible without the Colourful Hell pack loaded is not a signature.
// Sub-spawn counts are HARD CAPPED here regardless of what the resolver
// asks for -- these ride autofire weapons, and rs_13 flagged engine
// load as the real hazard on all three.
// =====================================================================

// ---------------------------------------------------------------------
// 01 ARACH-PLASMA -- the Arachnotron's bolt. APLS flight, APBX death,
// baby/* sounds: pure IWAD, the cleanest candidate in the survey. No
// spray, no splash -- its identity is RATE, so the round stays cheap
// and the Mastery (burn-through) rides the shared pierce fields.
// ---------------------------------------------------------------------
class RS_AffixArachPlasma : RS_BallisticFired
{
	Default
	{
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.85;
		Scale 0.6;
		DeathSound "baby/shotx";
		+BRIGHT
	}
	States
	{
	Spawn:
		APLS AB 3 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("baby/shotx", CHAN_AUTO);
		APBX A 3 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
		}
		APBX BCDE 3 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// 08 SWARM -- the Overlord's bee carrier. LFX1 carrier + WASP motes,
// both verified in-repo. The carrier deals the weapon's OWN rolled
// damage on impact (rs_13 flagged the source's 0-damage carrier as the
// hollow-round trap from rs_05); motes carry a small fixed bite on top.
// ---------------------------------------------------------------------
class RS_AffixSwarmMote : Actor
{
	Default
	{
		Projectile;
		Radius 4;
		Height 4;
		Speed 14;
		Damage 4;          // fixed and small ON PURPOSE -- the carrier's
		                   // rolled damage already paid on the direct hit
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.7;
		+THRUSPECIES
		+SEEKERMISSILE
		Species "Player";
	}

	// "FIXED AND SMALL ON PURPOSE" IS ONLY TRUE WITH THIS OVERRIDE.
	// Added 2026-08-07. Damage 4 on a missile is 4 x random(1,8) at
	// impact (engine p_map.cpp:1430), i.e. 4 to 32 per mote -- and a
	// swarm is many motes. The comment above described an intent the
	// code did not implement. RS_AffixPartActor at the top of this file
	// already carries the correct contract; these two plain-Actor parts
	// never inherited it.
	override int DoSpecialDamage(Actor target, int damage, Name damagetype)
	{
		return 4;
	}

	bool Hunts;

	override void Tick()
	{
		Super.Tick();
		if (Hunts)
			A_SeekerMissile(5, 5, SMF_LOOK);
	}

	States
	{
	Spawn:
		WASP AB 3 Bright;
		Loop;
	Death:
		WASP CD 3 Bright;
		Stop;
	}
}

class RS_AffixSwarmCarrier : RS_BallisticFired
{
	// Motes shed in FLIGHT, on a timer, capped for the whole lifetime --
	// an SMG at 10 rounds/sec must not carpet the map with actors.
	const SWARM_SHED_INTERVAL = 4;
	const SWARM_LIFETIME_CAP  = 8;

	int shedTimer;
	int shedSoFar;

	Default
	{
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.8;
		+BRIGHT
	}

	override void Tick()
	{
		Super.Tick();
		if (SprayCount <= 0 || shedSoFar >= min(SprayCount, SWARM_LIFETIME_CAP))
			return;
		if (++shedTimer < SWARM_SHED_INTERVAL)
			return;
		shedTimer = 0;
		shedSoFar++;

		let m = RS_AffixSwarmMote(Spawn("RS_AffixSwarmMote", pos));
		if (m)
		{
			m.angle = angle + frandom(-55, 55);
			m.pitch = pitch + frandom(-20, 20);
			m.VelFromAngle(m.Speed);
			m.vel.z = vel.z * 0.3 + frandom(-1, 1);
			m.Hunts = SpraySeek;
			m.target = target;
			m.master = master;   // THE SACRED POINTER -- XP attribution
		}
	}

	States
	{
	Spawn:
		LFX1 ABCD 3 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("rs_fx_impact_bullet", CHAN_AUTO);
		LFX1 D 3 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);
		}
		Stop;
	}
}

// ---------------------------------------------------------------------
// 04 NOVA -- the Cyberdemon's swoosh shell. BFS1 flight / BFE1 death,
// PLSS beads: all IWAD. The heavy signature -- it detonates into a
// plasma bead nova. Source sprayed ~30 beads; capped at 16 here
// (rs_13's stated hazard) and the beads carry fixed small damage, not
// the round's roll.
// ---------------------------------------------------------------------
class RS_AffixNovaBead : Actor
{
	Default
	{
		Projectile;
		Radius 4;
		Height 4;
		Speed 9;
		Damage 5;
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.6;
		+THRUSPECIES
		+SEEKERMISSILE
		Species "Player";
	}

	// Exact damage -- see RS_AffixSwarmMote above for the mechanism.
	// Without this, Damage 5 became 5 to 40 per bead, and the header
	// says the nova throws up to SIXTEEN of them: a worst-case 640 from
	// beads the design describes as "fixed small damage, not the round's
	// roll". That is the difference between an accent and a nuke.
	override int DoSpecialDamage(Actor target, int damage, Name damagetype)
	{
		return 5;
	}

	bool Hunts;

	override void Tick()
	{
		Super.Tick();
		if (Hunts)
			A_SeekerMissile(4, 6, SMF_LOOK);
	}

	States
	{
	Spawn:
		PLSS AB 3 Bright;
		Loop;
	Death:
		PLSE ABCDE 3 Bright;
		Stop;
	}
}

class RS_AffixNovaShell : RS_BallisticFired
{
	const NOVA_BEAD_CAP = 16;

	Default
	{
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.95;
		Scale 0.9;
		DeathSound "weapons/bfgx";
		+BRIGHT
	}

	States
	{
	Spawn:
		BFS1 AB 3 Bright;
		Loop;
	Death:
		TNT1 A 0 A_StartSound("weapons/bfgx", CHAN_AUTO);
		BFE1 A 4 Bright
		{
			Class<Actor> puff = ImpactPuffOverride ? ImpactPuffOverride : RS_Catalog.PUFF_Bullet();
			Spawn(puff, pos);
			if (ImpactSpawnExtra) Spawn(ImpactSpawnExtra, pos);

			// The nova. Even ring, flat-ish, capped hard.
			int n = clamp(SprayCount, 0, NOVA_BEAD_CAP);
			for (int i = 0; i < n; i++)
			{
				let b = RS_AffixNovaBead(Spawn("RS_AffixNovaBead", pos + (0, 0, 6)));
				if (!b) continue;
				b.angle = 360.0 * i / double(n);
				b.VelFromAngle(b.Speed);
				b.vel.z = frandom(-1.5, 2.5);
				b.Hunts = SpraySeek;
				b.target = target;
				b.master = master;   // XP attribution
			}
		}
		BFE1 BCDE 4 Bright;
		Stop;
	}
}
