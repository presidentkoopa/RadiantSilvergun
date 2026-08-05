// =====================================================================
// RS_UI -- the unified UI's play-scope half. Spec: docs/rs_10_ui_spec.txt.
//
// ARCHITECTURE (the one-shot safety decision): menus never call game
// APIs. RS_UIHandler (play scope, registered in MAPINFO) pre-builds
// every screen as plain rows -- key/value/color/command/tooltip -- and
// ONE dynamic menu class (RS_Menu_Dynamic, rs_menu/RS_UIMenus.zsc)
// renders whatever model is loaded. UI scope only ever reads plain
// data; every game mutation goes through rs-ui-* netevents handled
// here. One rendering path, no scope traps.
//
// The card picker is the one exception -- it rides GunBonsai's own
// proven giver/menu flow (the MENUDEF name "GunBonsaiWeaponLevelUpMenu"
// is re-pointed at RS_Menu_CardPicker; the giver never knows).
// =====================================================================

// The single source of L4's color doctrine. Doom-toned screens; rarity
// color is DATA (tier words, card tags), never decoration.
class RS_UIStyle
{
	static int TierColor(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return Font.CR_DARKRED;
			case VRT_Trash:     return Font.CR_BROWN;
			case VRT_Basic:     return Font.CR_GRAY;
			case VRT_Common:    return Font.CR_WHITE;
			case VRT_Uncommon:  return Font.CR_GREEN;
			case VRT_Advanced:  return Font.CR_LIGHTBLUE;
			case VRT_Designer:  return Font.CR_PURPLE;
			case VRT_Prototype: return Font.CR_GOLD;
		}
		return Font.CR_GRAY;
	}

	static string TierName(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return "CURSED";
			case VRT_Trash:     return "TRASH";
			case VRT_Basic:     return "BASIC";
			case VRT_Common:    return "COMMON";
			case VRT_Uncommon:  return "UNCOMMON";
			case VRT_Advanced:  return "ADVANCED";
			case VRT_Designer:  return "DESIGNER";
			case VRT_Prototype: return "PROTOTYPE";
		}
		return "?";
	}

	// Promotion rank as star pips: "* * o o o". Text glyphs on purpose
	// (L4: juice with intent, no art dependency). Shown to 5.
	static string Pips(int count)
	{
		string s = "";
		for (int i = 0; i < 5; i++)
		{
			if (i > 0) s = s .. " ";
			s = s .. (i < count ? "*" : "o");
		}
		return s;
	}

	static int ConditionColor(double cnd)
	{
		if (cnd >= 80.0) return Font.CR_GREEN;
		if (cnd >= 40.0) return Font.CR_YELLOW;
		return Font.CR_RED;
	}

	// A simple text XP bar: [=====>....]
	static string XPBar(double xp, double maxxp)
	{
		int filled = (maxxp > 0) ? clamp(int(10.0 * xp / maxxp), 0, 10) : 0;
		string s = "[";
		for (int i = 0; i < 10; i++)
			s = s .. (i < filled ? "=" : ".");
		return s .. "]";
	}
}

// =====================================================================
// The play-scope screen builder + netevent hub.
// =====================================================================
class RS_UIHandler : EventHandler
{
	// --- The screen model, read by RS_Menu_Dynamic (ui reads play). ---
	// Parallel arrays, one entry per row. Cmd "" = static text row;
	// otherwise the row is selectable and Confirm fires
	// SendNetworkEvent(Cmd, Arg).
	string mTitle;
	int    mTitleColor;
	string mSubtitle;
	int    mSubtitleColor;
	Array<string> mRowKey;
	Array<string> mRowVal;
	Array<int>    mRowColor;
	Array<string> mRowCmd;
	Array<int>    mRowArg;
	Array<string> mRowTip;

	// Sheet cycle position: 0 offhand, 1 mainhand, 2 player.
	int mCycle;

	// The test showcase stand (`netevent rs-showcase` toggles it). One
	// slot, console-player oriented -- it's a dev/preview prop, not a
	// per-player system.
	RS_ShowcaseStand mShowcase;

	// True only while the loaded model is a cycling sheet (weapon /
	// player). RS_Menu_Dynamic reads it: Left/Right cycle subjects on
	// sheets, and stay inert on confirm/repair screens.
	bool mCycleNav;

	// Reroll cost escalation: 5 << rsRerolls (5/10/20/40...), tracked on
	// the giver itself (fresh giver per offer = automatic reset).
	const REROLL_BASE_COST = 5;
	// Buying an EXTRA card costs more than rerolling the same ones --
	// widening the draw is strictly stronger than shuffling it.
	// 12 << rsExtraCards (12/24/48...).
	const EXPAND_BASE_COST = 12;
	const REPAIR_BITS_PER_PRESS = 50;   // 50 grey = +5 condition per press

	void ClearModel()
	{
		mCycleNav = false;
		mTitle = ""; mSubtitle = "";
		mTitleColor = Font.CR_GOLD;
		mSubtitleColor = Font.CR_WHITE;
		mRowKey.Clear(); mRowVal.Clear(); mRowColor.Clear();
		mRowCmd.Clear(); mRowArg.Clear(); mRowTip.Clear();
	}

	void AddRow(string k, string v, int color, string cmd = "", int arg = 0, string tip = "")
	{
		mRowKey.Push(k);
		mRowVal.Push(v);
		mRowColor.Push(color);
		mRowCmd.Push(cmd);
		mRowArg.Push(arg);
		mRowTip.Push(tip);
	}

	void AddRule()
	{
		AddRow("..............................................", "", Font.CR_DARKGRAY);
	}

	// --- Subject helpers -------------------------------------------------

	Weapon HandWeapon(PlayerPawn pawn, int hand)
	{
		if (hand == 0) return pawn.player.OffhandWeapon;
		return pawn.player.ReadyWeapon;
	}

	// -----------------------------------------------------------------
	// The cycle bind lands here (via the GBOH_UnifiedInfo graft in
	// GunBonsai's EventHandler). Sheets only -- level-ups launch FROM
	// the sheets, per the spec.
	// -----------------------------------------------------------------
	void CycleSheets(uint p, int dir = 1)
	{
		PlayerPawn pawn = players[p].mo;
		if (!pawn) return;

		for (int tries = 0; tries < 3; tries++)
		{
			mCycle = (mCycle + 3 + dir) % 3;
			if (mCycle == 0 && !pawn.player.OffhandWeapon) continue;
			if (mCycle == 1 && !pawn.player.ReadyWeapon) continue;
			break;
		}

		if (mCycle == 2) BuildPlayerSheet(pawn);
		else             BuildWeaponSheet(pawn, mCycle);
		mCycleNav = true;

		if (players[consoleplayer].mo == pawn)
			Menu.SetMenu("RSDynamicSheet");
	}

	// -----------------------------------------------------------------
	// S1/S2 -- the weapon sheet.
	// -----------------------------------------------------------------
	void BuildWeaponSheet(PlayerPawn pawn, int hand)
	{
		ClearModel();
		let wep = HandWeapon(pawn, hand);
		string handName = (hand == 0) ? "OFFHAND" : "MAINHAND";

		if (!wep)
		{
			mTitle = handName .. " -- EMPTY";
			mTitleColor = Font.CR_DARKGRAY;
			return;
		}

		let rsw = RS_Weapon(wep);
		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		let info = stats ? stats.GetInfoFor(wep) : null;

		mTitle = handName .. " -- " .. wep.GetTag();
		mTitleColor = rsw ? RS_UIStyle.TierColor(rsw.Tier) : Font.CR_WHITE;

		if (!rsw)
		{
			AddRow("(not an RS weapon)", "", Font.CR_DARKGRAY);
			return;
		}

		mSubtitle = RS_UIStyle.TierName(rsw.Tier) .. "      " .. RS_UIStyle.Pips(rsw.PromotionCount);
		mSubtitleColor = RS_UIStyle.TierColor(rsw.Tier);

		// --- GunBonsai level / XP / the LEVEL UP row ---
		if (info)
		{
			AddRow(string.format("LEVEL %d", info.level),
				string.format("XP %s %d/%d", RS_UIStyle.XPBar(info.XP, info.maxXP), int(info.XP), int(info.maxXP)),
				Font.CR_WHITE);
			int banked = info.XP >= info.maxXP ? 1 : 0;
			if (banked > 0)
				AddRow(">> LEVEL UP! <<", "choose an upgrade card",
					Font.CR_ORANGE, "rs-ui-levelup", hand,
					"A level is banked. Confirm to open the card picker.\nEsc there keeps it banked -- no penalty.");
		}
		AddRule();

		// --- Stats: what the gun actually is. ---
		int dps = int(rsw.DamagePerShot * max(1, rsw.PelletCount) * max(1, rsw.RateOfFire));
		AddRow("DAMAGE/SHOT",
			string.format("%d   (ceiling %d)", rsw.DamagePerShot, rsw.GetDamageCeiling()),
			rsw.LockedDamage ? Font.CR_DARKRED : Font.CR_TAN, "", 0,
			"Per-pellet damage, exact -- what you see is what lands.\nThe ceiling rises with every Promotion.");
		AddRow("DPS", string.format("%d", dps), Font.CR_TAN, "", 0,
			"Damage x pellets x rate of fire. Derived, not rolled.");
		AddRow("RATE OF FIRE", string.format("%d/s", rsw.RateOfFire), Font.CR_TAN);
		AddRow("ACCURACY", string.format("%d%s", int(rsw.Accuracy), rsw.LockedAccuracy ? "  [LOCKED]" : ""),
			rsw.LockedAccuracy ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("CRIT", string.format("%.1f%%%s", rsw.CritChance * 100.0, rsw.LockedCritChance ? "  [LOCKED]" : ""),
			rsw.LockedCritChance ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("VELOCITY", string.format("%d", int(rsw.Velocity)), Font.CR_TAN);
		int magNow = wep.AmmoType2 ? pawn.CountInv(wep.AmmoType2) : 0;
		AddRow("MAGAZINE", string.format("%d / %d", magNow, rsw.Capacity), Font.CR_TAN);
		AddRow("PELLETS", string.format("%d", rsw.PelletCount), Font.CR_TAN, "", 0,
			"Promotion's permanent reward: +1 per cash-in.");
		if (rsw.Choke > 0)
			AddRow("CHOKE", string.format("%.2f", rsw.Choke), Font.CR_TAN,
				"", 0, "Tightens the pellet cone. Shotgun-family exclusive.");
		AddRow("CONDITION", string.format("%d%%", int(rsw.Condition)),
			RS_UIStyle.ConditionColor(rsw.Condition), "rs-ui-repair-menu", hand,
			"Confirm to open repair. Below 50, worn guns roll hot --\nmore damage, backfire risk.");
		AddRule();

		// --- Affixes ---
		int held = 0;
		if (info)
		{
			for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
				if (info.upgrades.upgrades[i].level > 0) held++;
		}
		AddRow(string.format("AFFIXES  (%d held, %d sockets)", held,
			rsw.GunBonaiSockets), "", Font.CR_LIGHTBLUE);
		if (info)
		{
			for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
			{
				let upg = info.upgrades.upgrades[i];
				if (upg.level <= 0) continue;
				bool mastered = upg.level >= 6;
				bool masteryNext = upg.level == 5;
				string tag = mastered ? "MASTERED" : (masteryNext ? "MASTERY NEXT" : "");
				AddRow("  " .. upg.GetName(),
					string.format("Lv %d   %s", upg.level, tag),
					(mastered || masteryNext) ? Font.CR_ORANGE : Font.CR_WHITE);
			}
			if (held == 0)
				AddRow("  (none yet)", "", Font.CR_DARKGRAY);
		}

		// --- Rotation, only when someone (Echo) made it real ---
		let slot = rsw.GetSlot(0);
		if (slot && slot.Count() > 1)
			AddRow("ROTATION", string.format("%d beats", slot.Count()), Font.CR_LIGHTBLUE,
				"", 0, "The trigger cycles these beats in order, every pull.");
		AddRule();

		// --- Promotion ---
		if (rsw.Tier == VRT_Prototype)
			AddRow("> PROMOTE", RS_UIStyle.Pips(rsw.PromotionCount) .. "  ->  " .. RS_UIStyle.Pips(rsw.PromotionCount + 1),
				Font.CR_GOLD, "rs-ui-promote-ask", hand,
				"Cash this Prototype in: lose its affixes and 20% of its\nstats, gain +1 pellet forever and faster re-leveling.");
		else
			AddRow("PROMOTION", string.format("%d  (Prototype tier required to promote)", rsw.PromotionCount),
				Font.CR_DARKGRAY);
	}

	// -----------------------------------------------------------------
	// S3 -- player sheet. Minimal by design.
	// -----------------------------------------------------------------
	void BuildPlayerSheet(PlayerPawn pawn)
	{
		ClearModel();
		mTitle = "PLAYER";
		mTitleColor = Font.CR_GOLD;

		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		if (!stats)
		{
			AddRow("(no GunBonsai stats)", "", Font.CR_DARKGRAY);
			return;
		}
		// TFLV_PerPlayerStats has no maxXP field -- player-level max is the
		// flat bonsai_gun_levels_per_player_level cvar (gun-levels needed
		// per player level), same source stock GB's own status display
		// reads (PerPlayerStats.GetCurrentStats: stats.pmax).
		double pmax = bonsai_gun_levels_per_player_level;
		AddRow(string.format("LEVEL %d", stats.level),
			string.format("XP %s %d/%d", RS_UIStyle.XPBar(stats.XP, pmax), int(stats.XP), int(pmax)),
			Font.CR_WHITE);
		AddRule();
		AddRow("GOLD BITS", string.format("%d", pawn.CountInv("RS_Bit_Gold")), Font.CR_GOLD,
			"", 0, "Spent on card-picker rerolls. Dropped by kills.");
		AddRow("GREY BITS", string.format("%d", pawn.CountInv("RS_Bit_Grey")), Font.CR_WHITE,
			"", 0, "Weapon repair currency -- see a weapon sheet's CONDITION row.");
		AddRule();

		// --- Player-level GB affixes ---
		AddRow("PLAYER AFFIXES", "", Font.CR_LIGHTBLUE);
		int pheld = 0;
		if (stats.upgrades)
		{
			for (int i = 0; i < stats.upgrades.upgrades.Size(); i++)
			{
				let upg = stats.upgrades.upgrades[i];
				if (upg.level <= 0) continue;
				pheld++;
				AddRow("  " .. upg.GetName(), string.format("Lv %d", upg.level), Font.CR_WHITE);
			}
		}
		if (pheld == 0)
			AddRow("  (none yet)", "", Font.CR_DARKGRAY);
		AddRule();

		// --- The map, at a glance ---
		int mt = level.maptime / 35;
		AddRow("MAP TIME", string.format("%d:%02d", mt / 60, mt % 60), Font.CR_WHITE);
		AddRow("KILLS", string.format("%d / %d", level.killed_monsters, level.total_monsters), Font.CR_WHITE);
		AddRow("ITEMS", string.format("%d / %d", level.found_items, level.total_items), Font.CR_WHITE);
		AddRow("SECRETS", string.format("%d / %d", level.found_secrets, level.total_secrets), Font.CR_WHITE);
	}

	// -----------------------------------------------------------------
	// S4 -- the spec card: the full stat readout, one stat per row.
	// This is ALSO the row model the in-world card compositor will
	// consume once the billboard surface lands -- same rows, second
	// renderer. `netevent rs-ui-card <hand>` shows it in the 2D menu.
	// -----------------------------------------------------------------
	void BuildWeaponCard(PlayerPawn pawn, int hand)
	{
		ClearModel();
		let wep = HandWeapon(pawn, hand);
		if (!wep) { mTitle = "NO WEAPON"; return; }

		mTitle = wep.GetTag();
		let rsw = RS_Weapon(wep);
		if (!rsw)
		{
			AddRow("(not an RS weapon)", "", Font.CR_DARKGRAY);
			return;
		}

		mTitleColor = RS_UIStyle.TierColor(rsw.Tier);
		mSubtitle = RS_UIStyle.TierName(rsw.Tier) .. "      " .. RS_UIStyle.Pips(rsw.PromotionCount);
		mSubtitleColor = RS_UIStyle.TierColor(rsw.Tier);

		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		let info = stats ? stats.GetInfoFor(wep) : null;
		int held = 0;
		if (info)
		{
			for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
				if (info.upgrades.upgrades[i].level > 0) held++;
		}

		int dps = int(rsw.DamagePerShot * max(1, rsw.PelletCount) * max(1, rsw.RateOfFire));
		double tbs = rsw.GetTimeBetweenShots();
		int magNow = wep.AmmoType2 ? pawn.CountInv(wep.AmmoType2) : 0;

		AddRow("DAMAGE", string.format("%d  (ceiling %d)", rsw.DamagePerShot, rsw.GetDamageCeiling()),
			rsw.LockedDamage ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("ROF", string.format("%d/s", rsw.RateOfFire), Font.CR_TAN);
		AddRow("DPS", string.format("%d", dps), Font.CR_TAN);
		AddRow("ACCURACY", string.format("%d%s", int(rsw.Accuracy), rsw.LockedAccuracy ? "  [LOCKED]" : ""),
			rsw.LockedAccuracy ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("CAPACITY", string.format("%d / %d", magNow, rsw.Capacity),
			rsw.LockedCapacity ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("CRIT", string.format("%.1f%%%s", rsw.CritChance * 100.0, rsw.LockedCritChance ? "  [LOCKED]" : ""),
			rsw.LockedCritChance ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("PELLETS", string.format("%d", rsw.PelletCount), Font.CR_TAN);
		AddRow("VELOCITY", string.format("%d", int(rsw.Velocity)),
			rsw.LockedVelocity ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("BONSOC", string.format("%d / %d", held, rsw.GunBonaiSockets), Font.CR_LIGHTBLUE);
		AddRow("TIME BTWN", tbs > 0 ? string.format("%.2fs", tbs) : "--", Font.CR_TAN);
		AddRow("CONDITION", string.format("%d%%", int(rsw.Condition)),
			RS_UIStyle.ConditionColor(rsw.Condition));
	}

	// -----------------------------------------------------------------
	// S5 -- promotion confirm.
	// -----------------------------------------------------------------
	void BuildPromotionConfirm(PlayerPawn pawn, int hand)
	{
		ClearModel();
		let rsw = RS_Weapon(HandWeapon(pawn, hand));
		if (!rsw) { mTitle = "NO WEAPON"; return; }

		mTitle = "PROMOTE " .. rsw.GetTag() .. "?";
		mTitleColor = Font.CR_GOLD;
		mSubtitle = RS_UIStyle.Pips(rsw.PromotionCount) .. "  ->  " .. RS_UIStyle.Pips(rsw.PromotionCount + 1);
		mSubtitleColor = Font.CR_GOLD;

		AddRow("YOU LOSE", "", Font.CR_RED);
		AddRow("  all affixes", "", Font.CR_RED);
		AddRow("  20% of every rolled stat", "", Font.CR_RED);
		AddRow("  tier -> BASIC (0 sockets)", "", Font.CR_RED);
		AddRule();
		AddRow("YOU GAIN", "", Font.CR_GREEN);
		AddRow("  +1 pellet, permanent", "", Font.CR_GREEN);
		AddRow(string.format("  faster releveling (XP -%d%%)", min(60, (rsw.PromotionCount + 1) * 15)), "", Font.CR_GREEN);
		AddRow(string.format("  damage ceiling rises (now %d)", rsw.GetDamageCeiling()), "", Font.CR_GREEN);
		AddRule();
		AddRow(">> PROMOTE <<", "there is no undo", Font.CR_GOLD, "rs-ui-promote", hand);
		AddRow("(Esc: not today)", "", Font.CR_DARKGRAY);
	}

	// -----------------------------------------------------------------
	// S6 -- curse & repair. Repair live; curse-lifting rows disabled
	// (the curse system itself is stubbed off).
	// -----------------------------------------------------------------
	void BuildCurseRepair(PlayerPawn pawn, int hand)
	{
		ClearModel();
		let rsw = RS_Weapon(HandWeapon(pawn, hand));
		if (!rsw) { mTitle = "NO WEAPON"; return; }

		mTitle = "SERVICE -- " .. rsw.GetTag();
		mTitleColor = RS_UIStyle.TierColor(rsw.Tier);

		int grey = pawn.CountInv("RS_Bit_Grey");
		AddRow("CONDITION", string.format("%d%%", int(rsw.Condition)),
			RS_UIStyle.ConditionColor(rsw.Condition));
		AddRow("GREY BITS", string.format("%d", grey), Font.CR_WHITE);
		if (rsw.Condition < 100.0)
			AddRow(string.format("> REPAIR  (+%d%% for %d grey)",
				REPAIR_BITS_PER_PRESS / RS_Roll.GREY_BITS_PER_CND_POINT, REPAIR_BITS_PER_PRESS),
				"", Font.CR_GREEN, "rs-ui-repair", hand);
		else
			AddRow("(condition is perfect)", "", Font.CR_DARKGRAY);
		AddRule();

		bool anyLocked = rsw.LockedDamage || rsw.LockedAccuracy || rsw.LockedVelocity
			|| rsw.LockedCritChance || rsw.LockedCapacity;
		AddRow("CURSES", "", Font.CR_PURPLE);
		if (!anyLocked)
			AddRow("  (no locked stats)", "", Font.CR_DARKGRAY);
		else
		{
			if (rsw.LockedDamage)     AddRow("  DAMAGE", "[LOCKED]", Font.CR_DARKRED);
			if (rsw.LockedAccuracy)   AddRow("  ACCURACY", "[LOCKED]", Font.CR_DARKRED);
			if (rsw.LockedVelocity)   AddRow("  VELOCITY", "[LOCKED]", Font.CR_DARKRED);
			if (rsw.LockedCritChance) AddRow("  CRIT", "[LOCKED]", Font.CR_DARKRED);
			if (rsw.LockedCapacity)   AddRow("  CAPACITY", "[LOCKED]", Font.CR_DARKRED);
			AddRow("  (curse-lifting not yet awakened)", "", Font.CR_DARKGRAY);
		}
	}

	// -----------------------------------------------------------------
	// Netevents -- every game mutation the UI can cause.
	// -----------------------------------------------------------------
	override void NetworkProcess(ConsoleEvent evt)
	{
		if (evt.player < 0) return;
		PlayerPawn pawn = players[evt.player].mo;
		if (!pawn) return;
		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);

		if (evt.name == "rs-ui-levelup")
		{
			// Open the card picker for this hand's weapon, via GB's own
			// giver flow (which opens our re-pointed menu).
			let wep = HandWeapon(pawn, evt.args[0]);
			let info = (stats && wep) ? stats.GetInfoFor(wep) : null;
			if (info) info.StartLevelUp();
		}
		else if (evt.name == "rs-ui-promote-ask")
		{
			// If a picker's giver is mid-offer, decline it cleanly first
			// (penalty-free per the RejectLevelUp graft; the banked level
			// survives as XP). Then open the confirm screen.
			if (stats && stats.currentEffectGiver)
			{
				let giver = TFLV_UpgradeGiver(stats.currentEffectGiver);
				if (giver) giver.Choose(-1);
			}
			BuildPromotionConfirm(pawn, evt.args[0]);
			if (players[consoleplayer].mo == pawn)
				Menu.SetMenu("RSDynamicSheet");
		}
		else if (evt.name == "rs-ui-promote")
		{
			let rsw = RS_Weapon(HandWeapon(pawn, evt.args[0]));
			if (rsw && rsw.Tier == VRT_Prototype)
			{
				rsw.ApplyUpgradeCard(VRT_Basic);   // the designed Promote() path
				pawn.A_Log(string.format("%s PROMOTED. %s",
					rsw.GetTag(), RS_UIStyle.Pips(rsw.PromotionCount)), true);
			}
		}
		else if (evt.name == "rs-ui-cycle")
		{
			// Left/Right on a sheet: move between offhand, mainhand and
			// player -- the merged-arsenal navigation.
			CycleSheets(evt.player, evt.args[0] == 0 ? 1 : evt.args[0]);
		}
		else if (evt.name == "rs-ui-card")
		{
			BuildWeaponCard(pawn, evt.args[0]);
			if (players[consoleplayer].mo == pawn)
				Menu.SetMenu("RSDynamicSheet");
		}
		else if (evt.name == "rs-showcase")
		{
			// Dev/preview toggle: spin this hand's weapon 96 units ahead.
			// No args = offhand slot; falls back to the ready weapon.
			if (mShowcase)
			{
				mShowcase.Destroy();
				mShowcase = null;
			}
			else
			{
				let wep = HandWeapon(pawn, evt.args[0]);
				if (!wep) wep = pawn.player.ReadyWeapon;
				if (wep)
				{
					Vector3 spot = pawn.Vec3Angle(96, pawn.angle);
					spot.z = pawn.pos.z + 40;
					mShowcase = RS_ShowcaseStand.Create(spot, wep.GetClass());
				}
			}
		}
		else if (evt.name == "rs-ui-repair-menu")
		{
			BuildCurseRepair(pawn, evt.args[0]);
			if (players[consoleplayer].mo == pawn)
				Menu.SetMenu("RSDynamicSheet");
		}
		else if (evt.name == "rs-ui-repair")
		{
			let rsw = RS_Weapon(HandWeapon(pawn, evt.args[0]));
			if (rsw && pawn.CountInv("RS_Bit_Grey") >= REPAIR_BITS_PER_PRESS
				&& rsw.Condition < 100.0)
			{
				pawn.TakeInventory("RS_Bit_Grey", REPAIR_BITS_PER_PRESS);
				rsw.Condition = RS_Roll.RepairCondition(rsw.Condition, REPAIR_BITS_PER_PRESS);
				// Rebuild + reopen so the numbers refresh in place.
				BuildCurseRepair(pawn, evt.args[0]);
				if (players[consoleplayer].mo == pawn)
					Menu.SetMenu("RSDynamicSheet");
			}
			else
				pawn.A_Log("Not enough Grey Bits.", true);
		}
		else if (evt.name == "rs-ui-reroll" || evt.name == "rs-ui-expand")
		{
			// Two Gold spends against the current offer: reroll the same
			// number of cards, or buy one more card on top. Both rebuild
			// the candidate list and reopen the picker.
			let giver = stats ? TFLV_WeaponUpgradeGiver(stats.currentEffectGiver) : null;
			if (!giver) return;

			bool expanding = (evt.name == "rs-ui-expand");
			int cost = expanding
				? (EXPAND_BASE_COST << giver.rsExtraCards)
				: (REROLL_BASE_COST << giver.rsRerolls);

			if (pawn.CountInv("RS_Bit_Gold") < cost)
			{
				pawn.A_Log(string.format("%s costs %d Gold Bits.",
					expanding ? "Another card" : "Reroll", cost), true);
			}
			else
			{
				pawn.TakeInventory("RS_Bit_Gold", cost);
				if (expanding) giver.rsExtraCards++;
				else           giver.rsRerolls++;
				giver.CreateUpgradeCandidates();
			}

			// Release the menu claim either way, then let the giver
			// reclaim and reopen -- the player is never dumped back to
			// gameplay with a level still banked.
			stats.currentEffectGiver = null;
			giver.SetStateLabel("ChooseUpgrade");
		}
	}
}
