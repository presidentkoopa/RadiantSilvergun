// =====================================================================
// RS_MenuActionHandler -- backend for General Options / Vanilla+ Weapon
// Behavior / Dual Class Behavior menu Command buttons that need real
// logic behind them (anything beyond a native console command like
// "god"/"noclip"/"notarget", which MENUDEF calls directly).
// Triggered by MENUDEF's "netevent <name>" command string.
// =====================================================================

class RS_MenuActionHandler : EventHandler
{
	// -------------------------------------------------------------
	// General Options -- map navigation
	// -------------------------------------------------------------

	static void GoToNextMap()
	{
		string next = level.NextMap;
		if (!next.Length() || !LevelInfo.MapExists(next))
		{
			Console.Printf("RS: no next map defined.");
			return;
		}
		level.ChangeLevel(next, 0, 0);
	}

	// ZScript has no MAPINFO enumeration API, so the pool is built by
	// probing the standard MAPxx / ExMy naming conventions rather than a
	// hand-maintained list -- this only finds maps that follow those
	// conventions, not arbitrary custom-named MAPINFO entries.
	static void GoToRandomMap()
	{
		Array<string> pool;
		for (int i = 1; i <= 32; i++)
		{
			string mapName = i < 10 ? String.Format("MAP0%d", i) : String.Format("MAP%d", i);
			if (mapName != level.MapName && LevelInfo.MapExists(mapName))
				pool.Push(mapName);
		}
		for (int e = 1; e <= 4; e++)
		{
			for (int m = 1; m <= 9; m++)
			{
				string mapName = String.Format("E%dM%d", e, m);
				if (mapName != level.MapName && LevelInfo.MapExists(mapName))
					pool.Push(mapName);
			}
		}

		if (!pool.Size())
		{
			Console.Printf("RS: no other maps found to jump to.");
			return;
		}

		level.ChangeLevel(pool[Random(0, pool.Size() - 1)], 0, 0);
	}

	// -------------------------------------------------------------
	// Vanilla+ Weapon Behavior
	// -------------------------------------------------------------

	static void VPWeaponList(out Array<string> list)
	{
		list.Push("RS_VP_Fist");
		list.Push("RS_VP_Pistol");
		list.Push("RS_VP_ARifle");
		list.Push("RS_VP_Shotgun");
		list.Push("RS_VP_SuperShotgun");
		list.Push("RS_VP_Chaingun");
		list.Push("RS_VP_RocketLauncher");
		list.Push("RS_VP_PlasmaRifle");
		list.Push("RS_VP_BFG9000");
		list.Push("RS_VP_Chainsaw");
	}

	// Offhand is always mainhand + "2", except RS_VP_BFG9000 (irregular:
	// RS_VP_BFG90002, no underscore before the trailing digit).
	static string VPOffhandName(string mainhand)
	{
		if (mainhand == "RS_VP_BFG9000")
			return "RS_VP_BFG90002";
		return mainhand .. "2";
	}

	// Tops every Vanilla+ weapon up to 2 copies total (mainhand + off-hand)
	// -- first press grants whatever's missing, a weapon already at 2 is
	// left alone. Reserve ammo is always refilled regardless, so this
	// doubles as a plain ammo top-up once every weapon's already held.
	static void GiveAllVPWeaponsAndAmmo(PlayerInfo plr)
	{
		Array<string> list;
		VPWeaponList(list);
		for (int i = 0; i < list.Size(); i++)
		{
			string mainhand = list[i];
			string offhand = VPOffhandName(mainhand);
			if (!plr.mo.FindInventory(mainhand))
				plr.mo.GiveInventory(mainhand, 1);
			if (!plr.mo.FindInventory(offhand))
				plr.mo.GiveInventory(offhand, 1);
		}

		plr.mo.GiveInventory("Clip", 999);
		plr.mo.GiveInventory("Shell", 999);
		plr.mo.GiveInventory("RocketAmmo", 999);
		plr.mo.GiveInventory("Cell", 999);
		Console.Printf("RS: gave all Vanilla+ weapons and topped up ammo.");
	}

	// -------------------------------------------------------------
	// Dual Class Behavior
	// -------------------------------------------------------------

	// Both hands of all 3 heavy weapons -- 6 items total. Mirrors what
	// "Allow Big Guns" grants at spawn, just on demand and with the
	// off-hand copies included too.
	static void GiveBigGuns(PlayerInfo plr)
	{
		plr.mo.GiveInventory("VR_RocketLauncher", 1);
		plr.mo.GiveInventory("VR_RocketLauncher4", 1);
		plr.mo.GiveInventory("VR_PlasmaRifle", 1);
		plr.mo.GiveInventory("VR_PlasmaRifle4", 1);
		plr.mo.GiveInventory("VR_BFG9000", 1);
		plr.mo.GiveInventory("VR_BFG90004", 1);
		plr.mo.GiveInventory("RocketAmmo", 20);
		plr.mo.GiveInventory("Cell", 200);
		Console.Printf("RS: gave heavy ordnance (both hands).");
	}

	static void GiveRocketLauncher(PlayerInfo plr)
	{
		plr.mo.GiveInventory("VR_RocketLauncher", 1);
		plr.mo.GiveInventory("RocketAmmo", 20);
		Console.Printf("RS: gave Rocket Launcher.");
	}

	static void GivePlasmaRifle(PlayerInfo plr)
	{
		plr.mo.GiveInventory("VR_PlasmaRifle", 1);
		plr.mo.GiveInventory("Cell", 200);
		Console.Printf("RS: gave Plasma Rifle.");
	}

	static void GiveBFG9000(PlayerInfo plr)
	{
		plr.mo.GiveInventory("VR_BFG9000", 1);
		plr.mo.GiveInventory("Cell", 200);
		Console.Printf("RS: gave BFG 9000.");
	}

	// The main VR_ arsenal has no chainsaw of its own -- gives the
	// Vanilla+ set's Chainsaw pair (main + off-hand) instead. No ammo,
	// it's melee.
	static void GiveChainsaw(PlayerInfo plr)
	{
		plr.mo.GiveInventory("RS_VP_Chainsaw", 1);
		plr.mo.GiveInventory("RS_VP_Chainsaw2", 1);
		Console.Printf("RS: gave Chainsaw.");
	}

	// -------------------------------------------------------------
	// Unified "I" key -- called directly from GunBonsai/EventHandler.zsc's
	// ShowInfo() (the tail of the existing pending-level-up cascade) in
	// place of its old single Menu.SetMenu("GunBonsaiStatusDisplay").
	// When nothing's pending, repeated presses cycle Status -> Weapon
	// Selection -> Player -> Status, instead of only ever reaching Status.
	// State is a per-player "user" cvar (see CVARINFO.txt) so it survives
	// across menu opens/closes without touching the player pawn class.
	// -------------------------------------------------------------

	static void CycleBrowseMenu(int playernum)
	{
		if (playernum != consoleplayer)
			return;

		let cv = CVar.GetCVar("rs_ui_lastbrowsemenu", players[playernum]);
		int idx = 0;
		if (cv)
		{
			idx = (cv.GetInt() + 1) % 3;
			cv.SetInt(idx);
		}

		if (idx == 0) Menu.SetMenu("GunBonsaiStatusDisplay");
		else if (idx == 1) Menu.SetMenu("RS_WeaponSelect");
		else Menu.SetMenu("RS_PlayerDashboard");
	}

	// -------------------------------------------------------------
	// Weapon Selection screen (zscript/systems/RS_WeaponSelect.zs)
	// -------------------------------------------------------------

	// Opens the menu for the player who pressed the key only -- same guard
	// GunBonsai's own GBOH_UnifiedInfo uses (EventHandler.zsc:149).
	static void OpenWeaponSelect(int playernum)
	{
		if (playernum == consoleplayer)
			Menu.SetMenu("RS_WeaponSelect");
	}

	// Re-resolves the Nth non-offhand RS_Weapon in inventory order -- the
	// same scan RS_Menu_WeaponSelect.LoadWeapons() does in UI scope, so the
	// index picked there lines up with the weapon found here. There's no
	// serializable weapon identity to pass through a netevent otherwise
	// (SendNetworkEvent only carries ints); see RS_WeaponSelect.zs header.
	static void SelectMainWeaponByIndex(PlayerInfo plr, int index)
	{
		if (!plr.mo || index < 0)
			return;
		int i = 0;
		for (Inventory item = plr.mo.inv; item != null; item = item.inv)
		{
			let wep = RS_Weapon(item);
			if (!wep || wep.bOffhandWeapon)
				continue;
			if (i == index)
			{
				plr.mo.player.PendingWeapon = wep;
				return;
			}
			i++;
		}
	}

	// Same idea for the offhand, among weapons already owned. This is
	// deliberately NOT the general re-seat system from rs_02 Part 2 --
	// no arbitration against a fresh floor pickup, no boot-time seating.
	// It's the narrow, safe case: point OffhandWeapon at something the
	// player already has flagged bOffhandWeapon. There's no engine
	// PendingWeapon-equivalent for the offhand (it's a fork-level
	// construct, not stock weapon-switch), so this is a direct pointer
	// swap -- the same thing the disabled RS_OffhandSeat.zs did, and
	// exactly what GunBonsai's own XP/HUD tracking already reads live
	// off player.OffhandWeapon every tic, so it picks the change up
	// immediately with no separate cache to invalidate.
	// KNOWN GAP, not fixed by this: the next floor pickup of an
	// offhand-flagged weapon still unconditionally overwrites this
	// (RS_Weapon.zs AttachToOwner) -- that's the R2 arbitration problem,
	// still open.
	static void SelectOffhandWeaponByIndex(PlayerInfo plr, int index)
	{
		if (!plr.mo || index < 0)
			return;
		int i = 0;
		for (Inventory item = plr.mo.inv; item != null; item = item.inv)
		{
			let wep = RS_Weapon(item);
			if (!wep || !wep.bOffhandWeapon)
				continue;
			if (i == index)
			{
				plr.mo.player.OffhandWeapon = wep;
				return;
			}
			i++;
		}
	}

	// -------------------------------------------------------------
	// Dispatch
	// -------------------------------------------------------------

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "rs_general_nextmap") { GoToNextMap(); return; }
		if (e.Name ~== "rs_general_randommap") { GoToRandomMap(); return; }
		if (e.Name ~== "rs_open_weaponselect") { OpenWeaponSelect(e.Player); return; }

		let plr = players[e.Player];
		if (!plr || !plr.mo)
			return;

		if (e.Name ~== "rs_vanillaplus_giveall") GiveAllVPWeaponsAndAmmo(plr);
		else if (e.Name ~== "rs_dualclass_givebigguns") GiveBigGuns(plr);
		else if (e.Name ~== "rs_dualclass_giverocket") GiveRocketLauncher(plr);
		else if (e.Name ~== "rs_dualclass_giveplasma") GivePlasmaRifle(plr);
		else if (e.Name ~== "rs_dualclass_givebfg") GiveBFG9000(plr);
		else if (e.Name ~== "rs_dualclass_givechainsaw") GiveChainsaw(plr);
		else if (e.Name ~== "rs_weapon_select_main") SelectMainWeaponByIndex(plr, e.args[0]);
		else if (e.Name ~== "rs_weapon_select_offhand") SelectOffhandWeaponByIndex(plr, e.args[0]);
	}
}
