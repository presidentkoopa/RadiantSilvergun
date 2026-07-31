// =====================================================================
// RS_DebugGive -- debug menu, one "+1" button per weapon family.
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

	override void NetworkProcess(ConsoleEvent e)
	{
		let plr = players[e.Player];
		if (!plr || !plr.mo)
			return;

		if (e.Name ~== "rs_debug_give_pistol") Family(plr, "VR_Pistol");
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
		else if (e.Name ~== "rs_debug_give_gh_bfg9000") Family(plr, "RS_GH_BFG9000");
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
	}
}
