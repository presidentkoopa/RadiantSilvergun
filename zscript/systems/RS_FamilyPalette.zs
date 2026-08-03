// =====================================================================
// RS_FamilyPalette -- the missing link between a weapon's archetype and
// the Catalog. RS_Catalog is one flat parts bin; nothing about it says
// "a Shotgun may only draw from THESE puffs/casings/sounds." This file
// is that fence, keyed by the same archetype: keyword value every
// weapon already declares (RS_Weapon.GetPaletteArchetype()) -- NOT
// EVR_Family, which only covers 7 of the arsenal's ~13 archetypes and
// leaves every Heavy/GH/melee weapon at EVR_Family_None.
//
// Two-tier split per category, not one list per Tier value: a Core pool
// (always available, even Basic) and a Prestige pool (layered in once
// Tier >= VRT_Advanced). A full per-Tier matrix would mean inventing
// content that doesn't exist yet -- this stays honest about what's
// actually in the Catalog today.
//
// Unmapped archetypes fall back to the full unfiltered pool (today's
// pre-palette behavior), so nothing softlocks for an archetype that
// hasn't been hand-tuned here yet.
// =====================================================================

class RS_FamilyPalette
{
	// -----------------------------------------------------------------
	// BULLET MODE
	// -----------------------------------------------------------------

	static void BulletProjectiles(string archetype, EVR_Tier tier, out Array<Class<Actor> > pool)
	{
		pool.Clear();
		if (archetype == "railgun")
		{
			pool.Push(RS_Catalog.PROJ_RailBolt());
			pool.Push(RS_Catalog.PROJ_RailBoltStraight());
		}
		else if (archetype == "flamethrower")
		{
			pool.Push(RS_Catalog.PROJ_GH_FlameJet());
		}
		else
		{
			// Every standard-arms archetype (pistol/revolver/rifle/smg/
			// shotgun/supershotgun/chaingun) shares the one generic
			// travelling round -- there's no per-archetype bullet-shape
			// variety in the Catalog yet, so there's nothing to fence.
			pool.Push(RS_Catalog.PROJ_Ballistic());
		}
	}

	static void BulletPuffs(string archetype, EVR_Tier tier, out Array<Class<Actor> > pool)
	{
		pool.Clear();
		if (archetype == "shotgun" || archetype == "supershotgun")
			pool.Push(RS_Catalog.PUFF_Shot());
		else if (archetype == "melee")
			pool.Push(RS_Catalog.PUFF_Chainsaw());
		else
			pool.Push(RS_Catalog.PUFF_Bullet());
		if (tier >= VRT_Advanced)
			pool.Push(RS_Catalog.PUFF_Vanilla());
	}

	// String, not Class<Actor> -- matches RS_Catalog.CASING_*'s own
	// signature (RS_HiFiFX.CasingEject() takes a string).
	static void BulletCasings(string archetype, EVR_Tier tier, out Array<string> pool)
	{
		pool.Clear();
		if (archetype == "shotgun" || archetype == "supershotgun")
			pool.Push(RS_Catalog.CASING_Shell());
		else if (archetype == "rifle" || archetype == "chaingun" || archetype == "smg" || archetype == "railgun")
			pool.Push(RS_Catalog.CASING_Rifle());
		else if (archetype == "pistol" || archetype == "revolver")
			pool.Push(RS_Catalog.CASING_Small());
		// melee/launcher/energy/bfg/flamethrower: deliberately empty --
		// caller should fall back to "" (no casing ejected), correct for
		// all of them.
	}

	static void BulletSounds(string archetype, EVR_Tier tier, out Array<sound> pool)
	{
		pool.Clear();
		bool prestige = tier >= VRT_Advanced;
		if (archetype == "pistol")
		{
			pool.Push(RS_Catalog.SND_Pistol());
			if (prestige) pool.Push(RS_Catalog.SND_GH_Pistol());
		}
		else if (archetype == "revolver")
		{
			pool.Push(RS_Catalog.SND_Revolver());
			if (prestige) pool.Push(RS_Catalog.SND_GH_Revolver());
		}
		else if (archetype == "rifle")
		{
			pool.Push(RS_Catalog.SND_Rifle());
			if (prestige) pool.Push(RS_Catalog.SND_GH_Rifle());
		}
		else if (archetype == "smg")
		{
			pool.Push(RS_Catalog.SND_SMG());
			if (prestige) { pool.Push(RS_Catalog.SND_GH_SMG()); pool.Push(RS_Catalog.SND_GH_MP40()); }
		}
		else if (archetype == "shotgun")
		{
			pool.Push(RS_Catalog.SND_Shotgun());
			if (prestige) { pool.Push(RS_Catalog.SND_GH_PumpShotgun()); pool.Push(RS_Catalog.SND_GH_AssaultShotgun()); }
		}
		else if (archetype == "supershotgun")
		{
			pool.Push(RS_Catalog.SND_SuperShotgun());
			if (prestige) pool.Push(RS_Catalog.SND_GH_SSG());
		}
		else if (archetype == "chaingun")
		{
			pool.Push(RS_Catalog.SND_Chaingun());
			if (prestige) { pool.Push(RS_Catalog.SND_GH_Minigun()); pool.Push(RS_Catalog.SND_GH_Machinegun()); }
		}
		else if (archetype == "melee")
		{
			pool.Push(RS_Catalog.SND_Chainsaw());
			if (prestige) { pool.Push(RS_Catalog.SND_GH_Chainsaw()); pool.Push(RS_Catalog.SND_GH_Fist()); }
		}
		else if (archetype == "railgun")
		{
			pool.Push(RS_Catalog.SND_GH_Railgun());
		}
		else if (archetype == "flamethrower")
		{
			pool.Push(RS_Catalog.SND_GH_Flamethrower());
		}
		else
		{
			// Unmapped archetype -- never return an empty pool.
			pool.Push(RS_Catalog.SND_Pistol());
		}
	}

	// Where "family stays family" actually shows up most: a Pistol
	// rolling PelletOverride=6 doesn't feel like a Pistol anymore.
	// Locked to 1/1 for every archetype except the two pellet-based ones.
	static void BulletPelletRange(string archetype, EVR_Tier tier, out int minP, out int maxP)
	{
		bool prestige = tier >= VRT_Advanced;
		if (archetype == "shotgun")
		{
			minP = 4;
			maxP = prestige ? 9 : 7;
		}
		else if (archetype == "supershotgun")
		{
			minP = 8;
			maxP = prestige ? 16 : 14;
		}
		else
		{
			minP = 1;
			maxP = 1;
		}
	}

	// -----------------------------------------------------------------
	// HEAVY MODE -- Heavy attacks swap whole projectile CLASSES (see
	// RS_FX_HeavyProjectiles.zs's header), so the fence that matters here
	// is which classes are archetype-appropriate, not loose FX pieces.
	// -----------------------------------------------------------------

	static void HeavyProjectiles(string archetype, EVR_Tier tier, out Array<Class<Actor> > pool)
	{
		pool.Clear();
		bool prestige = tier >= VRT_Advanced;
		if (archetype == "launcher")
		{
			pool.Push(RS_Catalog.PROJ_Rocket());
			if (prestige)
			{
				pool.Push(RS_Catalog.PROJ_GrenadeLaunched());
				pool.Push(RS_Catalog.PROJ_GrenadeThrown());
			}
		}
		else if (archetype == "energy")
		{
			pool.Push(RS_Catalog.PROJ_PlasmaBall());
			if (prestige)
			{
				pool.Push(RS_Catalog.PROJ_GH_PlasmaShot());
				pool.Push(RS_Catalog.PROJ_GH_UnmakerShot());
			}
		}
		else if (archetype == "bfg")
		{
			pool.Push(RS_Catalog.PROJ_BFGBall());
			if (prestige)
				pool.Push(RS_Catalog.PROJ_GH_BFGShot());
		}
		else
		{
			// Unmapped archetype -- full pool, matches today's
			// pre-palette behavior so nothing softlocks.
			pool.Push(RS_Catalog.PROJ_Rocket());
			pool.Push(RS_Catalog.PROJ_PlasmaBall());
			pool.Push(RS_Catalog.PROJ_BFGBall());
			pool.Push(RS_Catalog.PROJ_GH_BFGShot());
			pool.Push(RS_Catalog.PROJ_GH_PlasmaShot());
			pool.Push(RS_Catalog.PROJ_GH_UnmakerShot());
			pool.Push(RS_Catalog.PROJ_GrenadeLaunched());
			pool.Push(RS_Catalog.PROJ_GrenadeThrown());
		}
	}

	static void HeavySounds(string archetype, EVR_Tier tier, out Array<sound> pool)
	{
		pool.Clear();
		bool prestige = tier >= VRT_Advanced;
		if (archetype == "launcher")
		{
			pool.Push(RS_Catalog.SND_RocketLauncher());
			if (prestige)
			{
				pool.Push(RS_Catalog.SND_GH_RocketLauncher());
				pool.Push(RS_Catalog.SND_GH_GrenadeLauncher());
				pool.Push(RS_Catalog.SND_GH_HandGrenade());
			}
		}
		else if (archetype == "energy")
		{
			pool.Push(RS_Catalog.SND_PlasmaRifle());
			if (prestige)
			{
				pool.Push(RS_Catalog.SND_GH_Plasma());
				pool.Push(RS_Catalog.SND_GH_Unmaker());
			}
		}
		else if (archetype == "bfg")
		{
			pool.Push(RS_Catalog.SND_BFG9000());
			if (prestige)
			{
				pool.Push(RS_Catalog.SND_GH_BFG9000());
				pool.Push(RS_Catalog.SND_GH_BFG10k());
			}
		}
		else
		{
			pool.Push(RS_Catalog.SND_RocketLauncher());
			pool.Push(RS_Catalog.SND_PlasmaRifle());
			pool.Push(RS_Catalog.SND_BFG9000());
		}
	}

	// Cosmetic blast look (RS_AttackProfile.ExplosionVisual) -- energy
	// weapons stay plasma-splash colored, everything else gets the
	// fireball family, exotic variants unlocked at Advanced+.
	static void HeavyExplosionVisuals(string archetype, EVR_Tier tier, out Array<Class<Actor> > pool)
	{
		pool.Clear();
		bool prestige = tier >= VRT_Advanced;
		if (archetype == "energy")
		{
			pool.Push(RS_Catalog.PLASMA_Splash());
			if (prestige)
				pool.Push(RS_Catalog.PLASMA_SplashAlt());
		}
		else
		{
			pool.Push(RS_Catalog.EXPLOSION_Fireball());
			if (prestige)
			{
				pool.Push(RS_Catalog.EXPLOSION_FireballAlt());
				pool.Push(RS_Catalog.EXPLOSION_Small());
				pool.Push(RS_Catalog.EXPLOSION_Tiny());
				pool.Push(RS_Catalog.EXPLOSION_Flash());
			}
		}
	}
}
