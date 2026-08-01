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
	// ReadyWeapon), builds one RS_AttackProfile out of a random catalog
	// projectile + a random catalog fire sound + randomized shot-shape
	// numbers, and replaces PrimarySlot's entry 0 with it. Doesn't touch
	// the weapon's rolled stats (Tier/DamagePerShot/etc.) -- only the
	// attack itself, same as a GunBonsai affix would.
	// -------------------------------------------------------------
	static void RandomProfile(PlayerInfo plr)
	{
		if (!plr.mo || !plr.ReadyWeapon)
			return;
		let wpn = RS_Weapon(plr.ReadyWeapon);
		if (!wpn)
		{
			Console.Printf("RS Debug: current weapon isn't an RS_Weapon.");
			return;
		}

		Array<Class<Actor> > projPool;
		projPool.Push(RS_Catalog.PROJ_Ballistic());
		projPool.Push(RS_Catalog.PROJ_Rocket());
		projPool.Push(RS_Catalog.PROJ_PlasmaBall());
		projPool.Push(RS_Catalog.PROJ_BFGBall());
		projPool.Push(RS_Catalog.PROJ_GH_BFGShot());
		projPool.Push(RS_Catalog.PROJ_GH_PlasmaShot());
		projPool.Push(RS_Catalog.PROJ_GH_UnmakerShot());
		projPool.Push(RS_Catalog.PROJ_GH_RailBolt());
		projPool.Push(RS_Catalog.PROJ_GH_RailBoltStraight());
		projPool.Push(RS_Catalog.PROJ_GH_FlameJet());
		projPool.Push(RS_Catalog.PROJ_GrenadeLaunched());
		projPool.Push(RS_Catalog.PROJ_GrenadeThrown());

		Array<sound> sndPool;
		sndPool.Push(RS_Catalog.SND_Pistol());
		sndPool.Push(RS_Catalog.SND_Revolver());
		sndPool.Push(RS_Catalog.SND_Rifle());
		sndPool.Push(RS_Catalog.SND_Shotgun());
		sndPool.Push(RS_Catalog.SND_RocketLauncher());
		sndPool.Push(RS_Catalog.SND_PlasmaRifle());
		sndPool.Push(RS_Catalog.SND_GH_Railgun());
		sndPool.Push(RS_Catalog.SND_GH_Unmaker());
		sndPool.Push(RS_Catalog.SND_GH_BFG9000());
		sndPool.Push(RS_Catalog.SND_GH_Flamethrower());
		sndPool.Push(RS_Catalog.SND_GH_Minigun());

		Class<Actor> proj = projPool[Random(0, projPool.Size() - 1)];
		sound fireSnd = sndPool[Random(0, sndPool.Size() - 1)];

		let p = RS_AttackProfile.MakeBullet(
			fireSnd: fireSnd,
			spreadScale: FRandom(0.02, 0.15),
			usesCadence: true,
			ammoCost: 1,
			bigMuzzle: (Random(0, 1) == 1),
			dmgMult: FRandom(0.5, 2.0),
			proj: proj,
			profName: "Debug Random");
		if (Random(0, 2) == 0)
			p.PelletOverride = Random(2, 6);

		wpn.EnsureAttackProfiles();
		wpn.ReplaceProfile(0, 0, p);
		Console.Printf("RS Debug: %s primary is now [%s / %s].", wpn.GetTag(), proj.GetClassName(), fireSnd);
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		let plr = players[e.Player];
		if (!plr || !plr.mo)
			return;

		if (e.Name ~== "rs_debug_random_profile") RandomProfile(plr);
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
