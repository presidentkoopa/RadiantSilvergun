// =====================================================================
// RS_DebugGive -- debug menu, one "+1" button per weapon family, plus
// RS_DebugRandomProfile (PGDN) -- slams a randomly assembled catalog
// combo onto the currently-wielded weapon's PrimarySlot. Exists to prove
// "hand a weapon a new profile at runtime" actually works end to end
// (sound, sprite, damage scaling) before that logic gets buried inside
// a GunBonsai affix nobody can trigger on demand.
// ---------------------------------------------------------------------
// Each press grants the first identity of that family the player
// doesn't already own (base class, then 2..6, in order). Once all 6
// are owned, further presses are a no-op. Debug-only: bypasses class
// gating and the Elite-drop system entirely, on purpose.
// =====================================================================

class RS_DebugGive : EventHandler
{
	static void GiveNextIdentity(PlayerInfo plr, Array<string> identities)
	{
		if (!plr.mo)
			return;
		for (int i = 0; i < identities.Size(); i++)
		{
			if (!plr.mo.FindInventory(identities[i]))
			{
				plr.mo.GiveInventory(identities[i], 1);
				Console.Printf("RS Debug: gave %s.", identities[i]);
				return;
			}
		}
		Console.Printf("RS Debug: already own all 6.");
	}

	static void Family(PlayerInfo plr, string baseName)
	{
		Array<string> ids;
		ids.Push(baseName);
		for (int i = 2; i <= 6; i++)
			ids.Push(baseName .. i);
		GiveNextIdentity(plr, ids);
	}

	// BFG9000 is the one irregular case -- no underscore before the
	// trailing digit (VR_BFG90002, not VR_BFG9000_2), same quirk noted
	// for the Vanilla+ set before it was removed.
	static void FamilyBFG(PlayerInfo plr)
	{
		Array<string> ids;
		ids.Push("VR_BFG9000");
		for (int i = 2; i <= 6; i++)
			ids.Push("VR_BFG9000" .. i);
		GiveNextIdentity(plr, ids);
	}

	// Same irregular naming as VR_BFG9000/FamilyBFG above, GH side.
	static void FamilyGHBFG9000(PlayerInfo plr)
	{
		Array<string> ids;
		ids.Push("RS_GH_BFG9000");
		for (int i = 2; i <= 6; i++)
			ids.Push("RS_GH_BFG9000" .. i);
		GiveNextIdentity(plr, ids);
	}

	// -------------------------------------------------------------
	// "Give Dual GH Weapons" / "Give All GH Weapons" -- blanket buttons
	// covering every GH weapon type at once, per Vanilla+ Options.
	// -------------------------------------------------------------
	static void GiveDualAllGH(PlayerInfo plr)
	{
		Array<string> types;
		types.Push("RS_GH_Fist"); types.Push("RS_GH_Chainsaw"); types.Push("RS_GH_Pistol");
		types.Push("RS_GH_Revolver"); types.Push("RS_GH_PumpShotgun"); types.Push("RS_GH_AssaultShotgun");
		types.Push("RS_GH_SSG"); types.Push("RS_GH_Minigun"); types.Push("RS_GH_Rifle");
		types.Push("RS_GH_SMG"); types.Push("RS_GH_MP40"); types.Push("RS_GH_Machinegun");
		types.Push("RS_GH_RocketLauncher"); types.Push("RS_GH_GrenadeLauncher"); types.Push("RS_GH_HandGrenade");
		types.Push("RS_GH_Flamethrower"); types.Push("RS_GH_Plasma"); types.Push("RS_GH_Railgun");
		types.Push("RS_GH_Unmaker"); types.Push("RS_GH_BFG10k");

		if (!plr.mo) return;
		for (int i = 0; i < types.Size(); i++)
		{
			if (!plr.mo.FindInventory(types[i])) plr.mo.GiveInventory(types[i], 1);
			string off = types[i] .. "4";
			if (!plr.mo.FindInventory(off)) plr.mo.GiveInventory(off, 1);
		}
		// BFG9000's irregular naming (no underscore before the digit).
		if (!plr.mo.FindInventory("RS_GH_BFG9000")) plr.mo.GiveInventory("RS_GH_BFG9000", 1);
		if (!plr.mo.FindInventory("RS_GH_BFG90004")) plr.mo.GiveInventory("RS_GH_BFG90004", 1);
		Console.Printf("RS Debug: gave mainhand+offhand of every GH weapon.");
	}

	static void GiveFullAllGH(PlayerInfo plr)
	{
		Array<string> types;
		types.Push("RS_GH_Fist"); types.Push("RS_GH_Chainsaw"); types.Push("RS_GH_Pistol");
		types.Push("RS_GH_Revolver"); types.Push("RS_GH_PumpShotgun"); types.Push("RS_GH_AssaultShotgun");
		types.Push("RS_GH_SSG"); types.Push("RS_GH_Minigun"); types.Push("RS_GH_Rifle");
		types.Push("RS_GH_SMG"); types.Push("RS_GH_MP40"); types.Push("RS_GH_Machinegun");
		types.Push("RS_GH_RocketLauncher"); types.Push("RS_GH_GrenadeLauncher"); types.Push("RS_GH_HandGrenade");
		types.Push("RS_GH_Flamethrower"); types.Push("RS_GH_Plasma"); types.Push("RS_GH_Railgun");
		types.Push("RS_GH_Unmaker"); types.Push("RS_GH_BFG10k");

		if (!plr.mo) return;
		for (int i = 0; i < types.Size(); i++)
		{
			if (!plr.mo.FindInventory(types[i])) plr.mo.GiveInventory(types[i], 1);
			for (int n = 2; n <= 6; n++)
			{
				string id = types[i] .. n;
				if (!plr.mo.FindInventory(id)) plr.mo.GiveInventory(id, 1);
			}
		}
		// BFG9000's irregular naming (no underscore before the digit).
		if (!plr.mo.FindInventory("RS_GH_BFG9000")) plr.mo.GiveInventory("RS_GH_BFG9000", 1);
		for (int n = 2; n <= 6; n++)
		{
			string id = "RS_GH_BFG9000" .. n;
			if (!plr.mo.FindInventory(id)) plr.mo.GiveInventory(id, 1);
		}
		Console.Printf("RS Debug: gave all 6 identities of every GH weapon.");
	}

	// -------------------------------------------------------------
	// RS_DebugRandomProfile -- grabs the mainhand weapon (player.
	// ReadyWeapon), builds one RS_AttackProfile and replaces the given
	// slot's entry 0 with it (which: 0 = PrimarySlot/main trigger, 1 =
	// SecondarySlot/alt-fire -- same indexing as RS_Weapon.GetSlot).
	// Doesn't touch the weapon's rolled stats (Tier/DamagePerShot/etc.)
	// -- only the attack itself, same as a GunBonsai affix would. Each
	// press REPLACES the slot's entry (reroll), not stacks.
	//
	// Which PIECES actually get re-rolled is gated per-category by the
	// rs_debugrandom_* cvars (RS_DebugBallisticMenu) -- unchecked means
	// "keep whatever this slot already has," read off the current
	// profile before it gets replaced, not "reset to nothing." A field
	// with no existing profile to read from (first-ever press) falls
	// back to a sane default rather than null. PelletOverride/spread ARE
	// allowed to randomize here even though a real affix should respect
	// archetype-locked pellet counts -- this is a debug sandbox,
	// deliberately wilder, and that's opt-in via its own toggle.
	// -------------------------------------------------------------
	static bool DebugToggle(string name, bool def = true)
	{
		CVar cv = CVar.FindCVar(name);
		return cv ? cv.GetBool() : def;
	}

	static void RandomProfile(PlayerInfo plr, int which = 0)
	{
		if (!plr.mo || !plr.ReadyWeapon)
			return;
		let wpn = RS_Weapon(plr.ReadyWeapon);
		if (!wpn)
		{
			Console.Printf("RS Debug: current weapon isn't an RS_Weapon.");
			return;
		}
		wpn.EnsureAttackProfiles();

		// What's already sitting in this slot -- the "keep it" source for
		// any category whose toggle is off.
		let cur = wpn.GetSlot(which) ? wpn.GetSlot(which).PeekAt(0) : null;

		// Fenced by RS_FamilyPalette, keyed on this weapon's own archetype
		// + Tier -- a Shotgun stays shotgun-shaped instead of pooling the
		// whole Catalog flat. Spark/Trail stay unfenced below: cosmetic
		// garnish, not archetype-defining, so full variety there doesn't
		// hurt "family stays family."
		string archetype = wpn.GetPaletteArchetype();
		Array<Class<Actor> > projPool = RS_FamilyPalette.BulletProjectiles(archetype, wpn.Tier);
		Array<sound> sndPool = RS_FamilyPalette.BulletSounds(archetype, wpn.Tier);
		Array<Class<Actor> > puffPool = RS_FamilyPalette.BulletPuffs(archetype, wpn.Tier);
		Array<string> casingPool = RS_FamilyPalette.BulletCasings(archetype, wpn.Tier);
		casingPool.Push(""); // no casing ejected -- always an option regardless of archetype

		Array<Class<Actor> > sparkPool;
		sparkPool.Push(RS_Catalog.SPARK_Hit());
		sparkPool.Push(RS_Catalog.SPARK_X());
		sparkPool.Push(RS_Catalog.SPARK_XNoModel());
		sparkPool.Push(RS_Catalog.SPARK_XHeavy());
		sparkPool.Push(RS_Catalog.SPARK_Ricochet());
		sparkPool.Push(RS_Catalog.SPARK_Rail());

		Array<Class<Actor> > trailPool;
		trailPool.Push(RS_Catalog.TRAIL_Ballistic());

		int pelletMin, pelletMax;
		RS_FamilyPalette.BulletPelletRange(archetype, wpn.Tier, pelletMin, pelletMax);

		Class<Actor> proj = DebugToggle("rs_debugrandom_projectile")
			? projPool[Random(0, projPool.Size() - 1)]
			: (cur ? cur.ProjectileClass : RS_Catalog.PROJ_Ballistic());
		sound fireSnd = DebugToggle("rs_debugrandom_sound")
			? sndPool[Random(0, sndPool.Size() - 1)]
			: (cur ? cur.FireSound : RS_Catalog.SND_Pistol());
		Class<Actor> puff = DebugToggle("rs_debugrandom_puff")
			? puffPool[Random(0, puffPool.Size() - 1)]
			: (cur ? cur.ImpactPuff : null);
		Class<Actor> spark = DebugToggle("rs_debugrandom_spark")
			? sparkPool[Random(0, sparkPool.Size() - 1)]
			: (cur ? cur.ImpactSparks : null);
		Class<Actor> smoke = DebugToggle("rs_debugrandom_smoke")
			? ((Random(0, 1) == 1) ? RS_Catalog.SMOKE_Wisp() : null)
			: (cur ? cur.MuzzleSmoke : null);
		Class<Actor> trail = DebugToggle("rs_debugrandom_trail")
			? trailPool[Random(0, trailPool.Size() - 1)]
			: (cur ? cur.Trail : null);
		bool bigMuzzle = DebugToggle("rs_debugrandom_bigmuzzle")
			? (Random(0, 1) == 1)
			: (cur ? cur.BigMuzzle : false);
		double dmgMult = DebugToggle("rs_debugrandom_dmgmult")
			? FRandom(0.5, 2.0)
			: (cur ? cur.DamageMult : 1.0);
		double spreadScale = DebugToggle("rs_debugrandom_spread")
			? FRandom(0.02, 0.15)
			: (cur ? cur.SpreadScale : 0.05);
		bool usesChoke = DebugToggle("rs_debugrandom_choke")
			? (Random(0, 1) == 1)
			: (cur ? cur.UsesChoke : false);
		bool usesCadence = DebugToggle("rs_debugrandom_cadence")
			? (Random(0, 1) == 1)
			: (cur ? cur.UsesCadence : true);
		string casing = DebugToggle("rs_debugrandom_casing")
			? casingPool[Random(0, casingPool.Size() - 1)]
			: (cur ? cur.CasingClass : "");
		int ammoCost = DebugToggle("rs_debugrandom_ammocost")
			? Random(0, 2)
			: (cur ? cur.AmmoCost : 1);

		let p = RS_AttackProfile.MakeBullet(
			fireSnd: fireSnd,
			spreadScale: spreadScale,
			usesCadence: usesCadence,
			ammoCost: ammoCost,
			casing: casing,
			bigMuzzle: bigMuzzle,
			usesChoke: usesChoke,
			dmgMult: dmgMult,
			proj: proj,
			profName: "Debug Random",
			impactPuff: puff,
			impactSparks: spark,
			muzzleSmoke: smoke,
			trail: trail);

		// Not exposed as MakeBullet() params -- set directly, same
		// pattern as PelletOverride below.
		p.VelocityMult = DebugToggle("rs_debugrandom_velmult")
			? FRandom(0.5, 2.0)
			: (cur ? cur.VelocityMult : 1.0);
		p.CritBonus = DebugToggle("rs_debugrandom_critbonus")
			? FRandom(0.0, 0.2)
			: (cur ? cur.CritBonus : 0.0);

		if (DebugToggle("rs_debugrandom_pellets"))
		{
			// pelletMin==pelletMax==1 for non-pellet archetypes -- leave
			// PelletOverride at its InitDefaults() value of 0 (0 = "use
			// the weapon's own real PelletCount") rather than forcing it
			// to a literal 1, which would freeze out any Condition-driven
			// pellet bonus.
			if (pelletMax > pelletMin)
				p.PelletOverride = Random(pelletMin, pelletMax);
		}
		else if (cur)
		{
			p.PelletOverride = cur.PelletOverride;
		}

		wpn.ReplaceProfile(which, 0, p);
		string smokeName = smoke ? smoke.GetClassName().."" : "default";
		string trailName = trail ? trail.GetClassName().."" : "default";
		string puffName = puff ? puff.GetClassName().."" : "default";
		string sparkName = spark ? spark.GetClassName().."" : "default";
		Console.Printf("RS Debug: %s slot %d is now [%s / %s / puff:%s / spark:%s / smoke:%s / trail:%s].",
			wpn.GetTag(), which, proj.GetClassName(), fireSnd, puffName,
			sparkName, smokeName, trailName);
	}

	// -------------------------------------------------------------
	// RandomHeavyProfile -- the Heavy-mode (Rocket/Plasma/BFG-shaped)
	// equivalent of RandomProfile above. Deliberately a SMALLER field
	// set: Heavy profiles have no puff/spark/trail/pellets/spread/
	// choke/casing -- "impact IS the explosion," already fully
	// catalogued per projectile class (see RS_Weapon.zs's own
	// RS_FireProfileHeavy comment). Same reroll-not-stack,
	// keep-if-unchecked shape as the Bullet version, own toggle cvars
	// (RS_DebugHeavyMenu).
	// -------------------------------------------------------------
	static void RandomHeavyProfile(PlayerInfo plr, int which = 0)
	{
		if (!plr.mo || !plr.ReadyWeapon)
			return;
		let wpn = RS_Weapon(plr.ReadyWeapon);
		if (!wpn)
		{
			Console.Printf("RS Debug: current weapon isn't an RS_Weapon.");
			return;
		}
		wpn.EnsureAttackProfiles();

		let cur = wpn.GetSlot(which) ? wpn.GetSlot(which).PeekAt(0) : null;

		// Fenced by RS_FamilyPalette -- a Rocket Launcher (archetype:
		// launcher) only rolls launcher-shaped projectiles, not a BFG
		// ball. Unmapped archetypes fall back to the full pool (see the
		// palette file's own comment).
		string archetype = wpn.GetPaletteArchetype();
		Array<Class<Actor> > projPool = RS_FamilyPalette.HeavyProjectiles(archetype, wpn.Tier);
		Array<sound> sndPool = RS_FamilyPalette.HeavySounds(archetype, wpn.Tier);

		Class<Actor> proj = DebugToggle("rs_debugrandomheavy_projectile")
			? projPool[Random(0, projPool.Size() - 1)]
			: (cur ? cur.ProjectileClass : RS_Catalog.PROJ_Rocket());
		sound fireSnd = DebugToggle("rs_debugrandomheavy_sound")
			? sndPool[Random(0, sndPool.Size() - 1)]
			: (cur ? cur.FireSound : RS_Catalog.SND_RocketLauncher());
		bool bigMuzzle = DebugToggle("rs_debugrandomheavy_bigmuzzle")
			? (Random(0, 1) == 1)
			: (cur ? cur.BigMuzzle : true);
		double dmgMult = DebugToggle("rs_debugrandomheavy_dmgmult")
			? FRandom(0.5, 2.0)
			: (cur ? cur.DamageMult : 1.0);
		double spawnHeight = DebugToggle("rs_debugrandomheavy_spawnheight")
			? FRandom(0.0, 24.0)
			: (cur ? cur.SpawnHeight : 0.0);
		int ammoCost = DebugToggle("rs_debugrandomheavy_ammocost")
			? Random(0, 2)
			: (cur ? cur.AmmoCost : 1);
		// AmmoClass deliberately not randomized -- same softlock risk as
		// the Bullet version. Always inherits the weapon's own AmmoType2.

		// Cosmetic-only, also fenced by archetype -- energy weapons stay
		// plasma-splash colored rather than rolling a fireball. Only
		// RS_EnhancedRocket/PlasmaBall/BFGBall actually read
		// ExplosionVisual (RS_Weapon.RS_FireProfileHeavy); the GH heavy
		// shots just ignore it.
		Array<Class<Actor> > explosionPool = RS_FamilyPalette.HeavyExplosionVisuals(archetype, wpn.Tier);
		Class<Actor> explosionVisual = DebugToggle("rs_debugrandomheavy_explosionvisual")
			? explosionPool[Random(0, explosionPool.Size() - 1)]
			: null;

		let p = RS_AttackProfile.MakeHeavy(
			proj: proj,
			fireSnd: fireSnd,
			ammoCost: ammoCost,
			bigMuzzle: bigMuzzle,
			spawnHeight: spawnHeight,
			dmgMult: dmgMult,
			profName: "Debug Random Heavy",
			explosionVisual: explosionVisual);

		p.CritBonus = DebugToggle("rs_debugrandomheavy_critbonus")
			? FRandom(0.0, 0.2)
			: (cur ? cur.CritBonus : 0.0);

		wpn.ReplaceProfile(which, 0, p);
		string explosionName = explosionVisual ? explosionVisual.GetClassName().."" : "default";
		Console.Printf("RS Debug: %s slot %d (heavy) is now [%s / %s / blast:%s].",
			wpn.GetTag(), which, proj.GetClassName(), fireSnd, explosionName);
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		let plr = players[e.Player];
		if (!plr || !plr.mo)
			return;

		if (e.Name ~== "rs_debug_random_profile") RandomProfile(plr, 0);
		else if (e.Name ~== "rs_debug_random_profile_secondary") RandomProfile(plr, 1);
		else if (e.Name ~== "rs_debug_random_heavy_profile") RandomHeavyProfile(plr, 0);
		else if (e.Name ~== "rs_debug_random_heavy_profile_secondary") RandomHeavyProfile(plr, 1);
		else if (e.Name ~== "rs_debug_give_pistol") Family(plr, "VR_Pistol");
		else if (e.Name ~== "rs_debug_give_revolver") Family(plr, "VR_Revolver");
		else if (e.Name ~== "rs_debug_give_rifle") Family(plr, "VR_Rifle");
		else if (e.Name ~== "rs_debug_give_smg") Family(plr, "VR_SMG");
		else if (e.Name ~== "rs_debug_give_shotgun") Family(plr, "VR_Shotgun");
		else if (e.Name ~== "rs_debug_give_supershotgun") Family(plr, "VR_SuperShotgun");
		else if (e.Name ~== "rs_debug_give_chaingun") Family(plr, "VR_Chaingun");
		else if (e.Name ~== "rs_debug_give_rocketlauncher") Family(plr, "VR_RocketLauncher");
		else if (e.Name ~== "rs_debug_give_plasmarifle") Family(plr, "VR_PlasmaRifle");
		else if (e.Name ~== "rs_debug_give_bfg9000") FamilyBFG(plr);
		else if (e.Name ~== "rs_debug_give_chainsaw") Family(plr, "VR_Chainsaw");
		else if (e.Name ~== "rs_debug_give_gh_assaultshotgun") Family(plr, "RS_GH_AssaultShotgun");
		else if (e.Name ~== "rs_debug_give_gh_bfg10k") Family(plr, "RS_GH_BFG10k");
		else if (e.Name ~== "rs_debug_give_gh_bfg9000") FamilyGHBFG9000(plr);
		else if (e.Name ~== "rs_debug_give_gh_chainsaw") Family(plr, "RS_GH_Chainsaw");
		else if (e.Name ~== "rs_debug_give_gh_fist") Family(plr, "RS_GH_Fist");
		else if (e.Name ~== "rs_debug_give_gh_flamethrower") Family(plr, "RS_GH_Flamethrower");
		else if (e.Name ~== "rs_debug_give_gh_grenadelauncher") Family(plr, "RS_GH_GrenadeLauncher");
		else if (e.Name ~== "rs_debug_give_gh_handgrenade") Family(plr, "RS_GH_HandGrenade");
		else if (e.Name ~== "rs_debug_give_gh_mp40") Family(plr, "RS_GH_MP40");
		else if (e.Name ~== "rs_debug_give_gh_machinegun") Family(plr, "RS_GH_Machinegun");
		else if (e.Name ~== "rs_debug_give_gh_minigun") Family(plr, "RS_GH_Minigun");
		else if (e.Name ~== "rs_debug_give_gh_pistol") Family(plr, "RS_GH_Pistol");
		else if (e.Name ~== "rs_debug_give_gh_plasma") Family(plr, "RS_GH_Plasma");
		else if (e.Name ~== "rs_debug_give_gh_pumpshotgun") Family(plr, "RS_GH_PumpShotgun");
		else if (e.Name ~== "rs_debug_give_gh_railgun") Family(plr, "RS_GH_Railgun");
		else if (e.Name ~== "rs_debug_give_gh_revolver") Family(plr, "RS_GH_Revolver");
		else if (e.Name ~== "rs_debug_give_gh_rifle") Family(plr, "RS_GH_Rifle");
		else if (e.Name ~== "rs_debug_give_gh_rocketlauncher") Family(plr, "RS_GH_RocketLauncher");
		else if (e.Name ~== "rs_debug_give_gh_smg") Family(plr, "RS_GH_SMG");
		else if (e.Name ~== "rs_debug_give_gh_ssg") Family(plr, "RS_GH_SSG");
		else if (e.Name ~== "rs_debug_give_gh_unmaker") Family(plr, "RS_GH_Unmaker");
		else if (e.Name ~== "rs_debug_give_gh_dual_all") GiveDualAllGH(plr);
		else if (e.Name ~== "rs_debug_give_gh_full_all") GiveFullAllGH(plr);
	}
}
