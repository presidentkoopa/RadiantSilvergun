// =====================================================================
// RS_DebugHandler -- backend for the Debug / Testing menu.
// ---------------------------------------------------------------------
// MENUDEF "Command" items can only run console commands, which covers
// native cheats (god/noclip/kill monsters) directly with zero ZScript.
// Anything stateful, or that needs to reach into RS_Weapon/RS_HiFiFX,
// needs real logic behind it -- that's what NetworkProcess is for,
// triggered by MENUDEF's "netevent <name>" command string.
//
// Six sections, one per system this session actually built: General
// cheats, Weapon Acquisition, Stat/Roll Testing, Reload Testing,
// Vanilla+ Behavior Testing, Hi-Fi FX Testing. Meant to keep growing --
// each section's list/logic is self-contained so adding one more test
// hook later doesn't mean touching the others.
//
// Per-player cycle position is stored in `user` cvars (CVARINFO), which
// GZDoom already keeps separate per player -- no need to touch any
// player pawn class to add state.
// =====================================================================

class RS_DebugHandler : EventHandler
{
	// -------------------------------------------------------------
	// Weapon Acquisition
	// -------------------------------------------------------------

	// Vanilla+ weapon list, mainhand class names. Offhand is always the
	// same name + "2" except RS_VP_BFG9000 (irregular: RS_VP_BFG90002,
	// no underscore before the trailing digit), handled explicitly.
	// ZScript can't return a dynamic array by value -- filled via an out
	// parameter instead of a return, same shape for DualWeaponList below.
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

	static string VPOffhandName(string mainhand)
	{
		if (mainhand == "RS_VP_BFG9000")
			return "RS_VP_BFG90002";
		return mainhand .. "2";
	}

	// Main arsenal weapon list, identity-1 (mainhand) class names.
	// Offhand is always identity 4 -- the established slot pattern this
	// session confirmed already exists (1&4 share the starting pair).
	static void DualWeaponList(out Array<string> list)
	{
		list.Push("VR_Revolver");
		list.Push("VR_Pistol");
		list.Push("VR_SMG");
		list.Push("VR_Rifle");
		list.Push("VR_Shotgun");
		list.Push("VR_SuperShotgun");
		list.Push("VR_Chaingun");
	}

	static void GiveAllVP(PlayerInfo plr)
	{
		Array<string> list;
		VPWeaponList(list);
		for (int i = 0; i < list.Size(); i++)
		{
			plr.mo.GiveInventory(list[i], 1);
			plr.mo.GiveInventory(VPOffhandName(list[i]), 1);
		}
		RefillVPAmmo(plr);
		Console.Printf("RS Debug: gave all Vanilla+ weapons.");
	}

	static void GiveNextVP(PlayerInfo plr)
	{
		Array<string> list;
		VPWeaponList(list);
		let cv = CVar.GetCVar("rs_debug_vpindex", plr);
		int idx = cv ? cv.GetInt() : 0;
		if (idx < 0 || idx >= list.Size())
			idx = 0;

		plr.mo.GiveInventory(list[idx], 1);
		plr.mo.GiveInventory(VPOffhandName(list[idx]), 1);
		Console.Printf("RS Debug: gave %s (+ off-hand).", list[idx]);

		if (cv)
			cv.SetInt((idx + 1) % list.Size());
	}

	static void RefillVPAmmo(PlayerInfo plr)
	{
		plr.mo.GiveInventory("Clip", 999);
		plr.mo.GiveInventory("Shell", 999);
		plr.mo.GiveInventory("RocketAmmo", 999);
		plr.mo.GiveInventory("Cell", 999);
		Console.Printf("RS Debug: refilled Vanilla+ reserve ammo.");
	}

	static void GiveNextDual(PlayerInfo plr)
	{
		Array<string> list;
		DualWeaponList(list);
		let cv = CVar.GetCVar("rs_debug_dualindex", plr);
		int idx = cv ? cv.GetInt() : 0;
		if (idx < 0 || idx >= list.Size())
			idx = 0;

		plr.mo.GiveInventory(list[idx], 1);
		plr.mo.GiveInventory(list[idx] .. "4", 1);
		Console.Printf("RS Debug: gave %s (+ off-hand).", list[idx]);

		if (cv)
			cv.SetInt((idx + 1) % list.Size());
	}

	// Bypasses the "Allow Big Guns" toggle entirely -- for when you just
	// need a Rocket/Plasma/BFG in hand right now, without flipping a
	// setting and restarting the class.
	static void GiveBigGuns(PlayerInfo plr)
	{
		plr.mo.GiveInventory("VR_RocketLauncher", 1);
		plr.mo.GiveInventory("VR_PlasmaRifle", 1);
		plr.mo.GiveInventory("VR_BFG9000", 1);
		Console.Printf("RS Debug: gave heavy ordnance.");
	}

	// -------------------------------------------------------------
	// Stat / Roll Testing
	// -------------------------------------------------------------

	// EVR_Tier(intValue) isn't valid cast syntax in ZScript -- enums aren't
	// callable like a class constructor. A plain switch onto the named
	// constants is the safe way to turn the menu's stored int back into
	// a real EVR_Tier value.
	static EVR_Tier TierFromInt(int t)
	{
		switch (t)
		{
			case 0: return VRT_Cursed;
			case 1: return VRT_Trash;
			case 2: return VRT_Basic;
			case 3: return VRT_Common;
			case 4: return VRT_Uncommon;
			case 5: return VRT_Advanced;
			case 6: return VRT_Designer;
			default: return VRT_Prototype;
		}
	}

	// Force-rerolls whatever's in both hands to the tier picked in the
	// menu (rs_debug_reroll_tier) -- the fast way to see any tier's
	// stat range without grinding the loot loop to reach it.
	static void RerollHeldToTier(PlayerInfo plr)
	{
		let tierCv = CVar.GetCVar("rs_debug_reroll_tier", plr);
		EVR_Tier t = TierFromInt(tierCv ? tierCv.GetInt() : 7);

		int count = 0;
		if (plr.ReadyWeapon is "RS_Weapon")
		{
			RS_Weapon(plr.ReadyWeapon).RollStats(t);
			count++;
		}
		if (plr.OffhandWeapon is "RS_Weapon")
		{
			RS_Weapon(plr.OffhandWeapon).RollStats(t);
			count++;
		}
		Console.Printf("RS Debug: rerolled %d held weapon(s) to tier %d.", count, t);
	}

	// Prints both hands' current rolled stats -- the fast way to confirm
	// a roll/tier/purist-mode change actually took effect without a HUD
	// stat display.
	static void DumpHeldStats(PlayerInfo plr)
	{
		DumpOneWeapon(plr.ReadyWeapon, "Mainhand");
		DumpOneWeapon(plr.OffhandWeapon, "Off-hand");
	}

	static void DumpOneWeapon(Weapon w, string label)
	{
		if (!(w is "RS_Weapon"))
		{
			Console.Printf("RS Debug: %s -- not an RS_Weapon.", label);
			return;
		}
		let rw = RS_Weapon(w);
		Console.Printf("RS Debug: %s = %s | Tier %d | Dmg %d | Acc %.1f | Vel %.0f | Crit %.3f | Cap %d | Cond %.1f",
			label, w.GetClassName(), rw.Tier, rw.DamagePerShot, rw.Accuracy,
			rw.Velocity, rw.CritChance, rw.Capacity, rw.Condition);
	}

	// -------------------------------------------------------------
	// Reload Testing
	// -------------------------------------------------------------

	// Empties the chambered magazine on both held weapons -- forces the
	// Reload: state on the next trigger pull instead of needing to burn
	// through a full mag of real shots to get there.
	static void EmptyHeldMagazines(PlayerInfo plr)
	{
		EmptyOneMag(plr, plr.ReadyWeapon);
		EmptyOneMag(plr, plr.OffhandWeapon);
		Console.Printf("RS Debug: emptied held weapon magazine(s).");
	}

	static void EmptyOneMag(PlayerInfo plr, Weapon w)
	{
		if (w is "RS_Weapon" && w.AmmoType2)
			plr.mo.TakeInventory(w.AmmoType2, 999);
	}

	// Empties reserve ammo on both held weapons -- forces the OutOfAmmo:
	// path, which is otherwise inconvenient to reach on purpose.
	static void EmptyHeldReserve(PlayerInfo plr)
	{
		EmptyOneReserve(plr, plr.ReadyWeapon);
		EmptyOneReserve(plr, plr.OffhandWeapon);
		Console.Printf("RS Debug: emptied held weapon reserve ammo.");
	}

	static void EmptyOneReserve(PlayerInfo plr, Weapon w)
	{
		if (w is "RS_Weapon" && w.AmmoType1)
			plr.mo.TakeInventory(w.AmmoType1, 999);
	}

	// -------------------------------------------------------------
	// Vanilla+ Behavior Testing
	// -------------------------------------------------------------

	// Exercises the real TryPickup override on RS_VP_Weapon, the same
	// code path a floor pickup uses -- not GiveInventory, which bypasses
	// pickup logic entirely. First click grants mainhand (if you don't
	// have it), second click morphs to off-hand, third click (both hands
	// full) falls through to ordinary vanilla ammo-only behavior --
	// walking through all three real states on demand.
	static void ForceVPPickupMorph(PlayerInfo plr)
	{
		// Spawn() has no implicit self here (this is a static function,
		// not an Actor instance method) -- Actor.Spawn is the properly
		// scoped static form for spawning from non-actor code.
		let spawned = Weapon(Actor.Spawn("RS_VP_Pistol", plr.mo.Pos));
		if (spawned)
			spawned.TryPickup(plr.mo);
		Console.Printf("RS Debug: ran Vanilla+ pickup-morph check (Pistol).");
	}

	// Spawns 10 Chainguns under the player's real, current
	// rs_vanillaplus_arifle_enable/_chance settings and reports how many
	// became Assault Rifles -- an honest empirical test of the actual
	// substitution roll rather than a guaranteed/faked result. Note this
	// counts every RS_VP_Chaingun/RS_VP_ARifle currently in the world,
	// so run this on an otherwise-empty test map for a clean read.
	static void TestARifleSubstitution(PlayerInfo plr)
	{
		for (int i = 0; i < 10; i++)
			Actor.Spawn("RS_VP_Chaingun", plr.mo.Pos + (FRandom(-64, 64), FRandom(-64, 64), 0), ALLOW_REPLACE);

		int chainguns = 0, arifles = 0;
		let it = ThinkerIterator.Create("RS_VP_Chaingun");
		while (it.Next()) chainguns++;
		it = ThinkerIterator.Create("RS_VP_ARifle");
		while (it.Next()) arifles++;

		Console.Printf("RS Debug: spawned 10 Chaingun rolls -- %d Chaingun, %d Assault Rifle now in world.", chainguns, arifles);
	}

	// -------------------------------------------------------------
	// Hi-Fi FX Testing
	// -------------------------------------------------------------
	// These bypass RS_HiFiFX's own tier gates on purpose -- the point is
	// to SEE the effect on demand regardless of the current Weapon
	// Fidelity Options setting, not to reproduce gameplay-accurate gating.

	static void SpawnTestCasing(PlayerInfo plr)
	{
		plr.mo.A_SpawnItemEx("RS_CasingSmall", 4, 0, 0,
			FRandom(0.5, 1.5), FRandom(-1.0, 1.0), FRandom(2.0, 4.0), 0, 0, 128);
		Console.Printf("RS Debug: spawned a test casing.");
	}

	static void SpawnTestMagDrop(PlayerInfo plr)
	{
		plr.mo.A_SpawnItemEx("RS_MagDrop", 0, 0, -4.0,
			FRandom(-1.0, 1.0), FRandom(-1.0, 1.0), 0, 0, 0, 128);
		Console.Printf("RS Debug: spawned a test mag drop.");
	}

	static void SpawnTestMuzzleLight(PlayerInfo plr)
	{
		plr.mo.A_SpawnItemEx("RS_MuzzleLight", 0, 0, 0, 0, 0, 0, 0, 0, 128);
		Console.Printf("RS Debug: spawned a test muzzle light.");
	}

	// Spawns muzzle lights until RS_HiFiFX.MaxMuzzleLights() is hit, using
	// the exact same count-then-cap check RS_HiFiFX.SpawnMuzzleLight uses
	// -- confirms the cap actually holds under load, independent of the
	// current FX tier setting. Spawns up to the current cap + 10, so this
	// stays meaningful even if rs_fx_maxmuzzlelights is raised toward 256.
	static void StressTestMuzzleLights(PlayerInfo plr)
	{
		int cap = RS_HiFiFX.MaxMuzzleLights();
		int attempts = cap + 10;
		int spawned = 0;
		for (int i = 0; i < attempts; i++)
		{
			int count = 0;
			let it = ThinkerIterator.Create("RS_MuzzleLight");
			while (it.Next()) count++;
			if (count >= cap)
				break;
			plr.mo.A_SpawnItemEx("RS_MuzzleLight", 0, 0, 0, 0, 0, 0, 0, 0, 128);
			spawned++;
		}
		Console.Printf("RS Debug: muzzle light stress test -- spawned %d (cap = %d).", spawned, cap);
	}

	// -------------------------------------------------------------
	// Model Testing
	// -------------------------------------------------------------

	// Flips the horizontal mirror on both held weapons' models. Useful
	// for visually A/B-testing an orientation fix (e.g. the Fist Scale
	// fix) without editing MODELDEF and reloading between every attempt.
	// Purely cosmetic and not persisted -- resets on weapon switch/respawn.
	static void ToggleHeldMirror(PlayerInfo plr)
	{
		ToggleOneMirror(plr.ReadyWeapon);
		ToggleOneMirror(plr.OffhandWeapon);
		Console.Printf("RS Debug: toggled held weapon model mirroring.");
	}

	static void ToggleOneMirror(Weapon w)
	{
		if (w)
			w.Scale.X *= -1;
	}

	// -------------------------------------------------------------
	// Dispatch
	// -------------------------------------------------------------

	override void NetworkProcess(ConsoleEvent e)
	{
		let plr = players[e.Player];
		if (!plr || !plr.mo)
			return;

		if (e.Name ~== "rs_debug_vp_giveall") GiveAllVP(plr);
		else if (e.Name ~== "rs_debug_vp_givenext") GiveNextVP(plr);
		else if (e.Name ~== "rs_debug_vp_refillammo") RefillVPAmmo(plr);
		else if (e.Name ~== "rs_debug_dual_givenext") GiveNextDual(plr);
		else if (e.Name ~== "rs_debug_dual_givebigguns") GiveBigGuns(plr);
		else if (e.Name ~== "rs_debug_reroll") RerollHeldToTier(plr);
		else if (e.Name ~== "rs_debug_dumpstats") DumpHeldStats(plr);
		else if (e.Name ~== "rs_debug_reload_emptymag") EmptyHeldMagazines(plr);
		else if (e.Name ~== "rs_debug_reload_emptyreserve") EmptyHeldReserve(plr);
		else if (e.Name ~== "rs_debug_vp_forcemorph") ForceVPPickupMorph(plr);
		else if (e.Name ~== "rs_debug_vp_testarifle") TestARifleSubstitution(plr);
		else if (e.Name ~== "rs_debug_fx_casing") SpawnTestCasing(plr);
		else if (e.Name ~== "rs_debug_fx_magdrop") SpawnTestMagDrop(plr);
		else if (e.Name ~== "rs_debug_fx_muzzlelight") SpawnTestMuzzleLight(plr);
		else if (e.Name ~== "rs_debug_fx_stresstest") StressTestMuzzleLights(plr);
		else if (e.Name ~== "rs_debug_model_togglemirror") ToggleHeldMirror(plr);
	}
}
