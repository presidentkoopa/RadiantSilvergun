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
		TNT1 A 0 A_PlaySound("rs_fx_impact_bullet", CHAN_AUTO);
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
		TNT1 A 0 A_PlaySound("rs_fx_impact_bullet", CHAN_AUTO);
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
		TNT1 A 0 A_PlaySound("skeleton/tracex", CHAN_AUTO);
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
		TNT1 A 0 A_PlaySound("rs_fx_ice_hit", CHAN_AUTO);
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
		TNT1 A 0 A_PlaySound("rs_fx_ice_shatter", CHAN_AUTO);
		ICEY F 3 Bright A_Explode(20, 96, 0, false);
		ICEY GHI 3 Bright;
		Stop;
	}
}
