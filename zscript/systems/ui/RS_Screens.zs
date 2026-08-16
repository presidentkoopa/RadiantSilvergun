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
	// Forwards to RS_TierPalette -- the one tier colour ladder.
	static int TierColor(int tier)
	{
		return RS_TierPalette.FontColor(tier);
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
	// Per-row XP-bar payload: frac < 0 = plain row, no bar; frac >= 0
	// makes RS_Menu_Dynamic draw a real track+fill bar in the value
	// column, filled to the fraction, in the row's tier colour
	// (barTier -1 = the tierless gold).
	Array<double> mRowBarFrac;
	Array<int>    mRowBarTier;

	// The tier colouring this screen's header plate; -1 = no tier
	// (player sheet, promotion confirm) and the plate renders gold.
	int mSheetTier;

	// WHICH HAND THIS SHEET IS. -1 = not a weapon sheet.
	//
	// Read by RS_MenuItem_SheetHeader, which hangs an accent rail on the
	// side the hand is on -- mainhand warm on the LEFT, offhand cool on
	// the RIGHT -- so the two are distinguishable from peripheral vision
	// without reading the title. Deliberately separate from mSheetTier:
	// tier is DATA and keeps the palette, the hand is CHROME and gets its
	// own two colours, so they never compete for the same signal.
	int mHand;

	// Sheet cycle position: 0 offhand, 1 mainhand, 2 player.
	int mCycle;

	// True only while the loaded model is a cycling sheet (weapon /
	// player). RS_Menu_Dynamic reads it: Left/Right cycle subjects on
	// sheets, and stay inert on confirm/repair screens.
	bool mCycleNav;

	// (The showcase stand and its floating world card were removed
	// 2026-08-07 -- see the rs-showcase note in NetworkProcess. The
	// canvas-painting half went with them: it displayed through
	// billboard payload 1 (texture), which needs TextureID.GetIndex(),
	// and that native still does not exist in ZScript. In-world screens

	// Reroll cost escalation: 5 << rsRerolls (5/10/20/40...), tracked on
	// the giver itself (fresh giver per offer = automatic reset).
	const REROLL_BASE_COST = 5;
	// Buying an EXTRA card costs more than rerolling the same ones --
	// widening the draw is strictly stronger than shuffling it.
	// 12 << rsExtraCards (12/24/48...).
	const EXPAND_BASE_COST = 12;
	const REPAIR_BITS_PER_PRESS = 50;   // 50 grey = +5 condition per press
	// CURSE_LIFT_COST (a flat 25 GOLD) was here and is gone, 2026-08-07.
	//
	// The curse rework gave lifting a real price list -- Curse Bits, and
	// a different amount per stat depending on how much that curse hurts
	// (RS_Curse.StatCost, all sliders on the Curses options page). This
	// screen was the only thing still charging a flat rate in a different
	// currency, which meant the same action cost two different things
	// depending on whether the player found this route or the console one.
	//
	// A cursed stat still reads ??? until lifted, so the "you are buying
	// information as much as power" reasoning behind the original number
	// survives -- it is just priced with everything else now.

	void ClearModel()
	{
		mCycleNav = false;
		mSheetTier = -1;
		mHand = -1;
		mTitle = ""; mSubtitle = "";
		mTitleColor = Font.CR_GOLD;
		mSubtitleColor = Font.CR_WHITE;
		mRowKey.Clear(); mRowVal.Clear(); mRowColor.Clear();
		mRowCmd.Clear(); mRowArg.Clear(); mRowTip.Clear();
		mRowBarFrac.Clear(); mRowBarTier.Clear();
	}

	// CONTRACT: barFrac and cmd are mutually exclusive. A bar row renders
	// as a non-selectable XPRow; if a row carries both, the menu side
	// (RS_UIMenus.zsc, RS_Menu_Dynamic.Init) keeps the command's
	// KVOption dispatch and drops the bar.
	void AddRow(string k, string v, int color, string cmd = "", int arg = 0, string tip = "",
		double barFrac = -1.0, int barTier = -1)
	{
		mRowKey.Push(k);
		mRowVal.Push(v);
		mRowColor.Push(color);
		mRowCmd.Push(cmd);
		mRowArg.Push(arg);
		mRowTip.Push(tip);
		mRowBarFrac.Push(barFrac);
		mRowBarTier.Push(barTier);
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

		mHand = hand;
		mSubtitle = RS_UIStyle.TierName(rsw.Tier) .. "      " .. RS_UIStyle.Pips(rsw.PromotionCount);
		mSubtitleColor = RS_UIStyle.TierColor(rsw.Tier);
		mSheetTier = rsw.Tier;

		// --- GunBonsai level / XP / the LEVEL UP row ---
		if (info)
		{
			// barFrac >= 0 makes the menu render a real tier-coloured
			// bar in the value column; the text carries the numbers.
			AddRow(string.format("LEVEL %d", info.level),
				string.format("%d / %d xp", int(info.XP), int(info.maxXP)),
				Font.CR_WHITE, "", 0, "",
				info.maxXP > 0 ? clamp(info.XP / info.maxXP, 0.0, 1.0) : 0.0,
				rsw.Tier);
			int banked = info.XP >= info.maxXP ? 1 : 0;
			if (banked > 0)
				AddRow(">> LEVEL UP! <<", "choose an upgrade card",
					Font.CR_ORANGE, "rs-ui-levelup", hand,
					"A level is banked. Confirm to open the card picker.\nEsc there keeps it banked -- no penalty.");
		}
		AddRule();

		// --- Stats: what the gun actually is. ---
		int dps = int(rsw.DamagePerShot * max(1, rsw.PelletCount) * max(1, rsw.RateOfFire));
		// A CURSED STAT SHOWS ???, NOT ITS NUMBER. Owner ruling
		// 2026-08-07: "curses obscure the actual value of a rolled stat
		// until they are lifted by spending gold."
		//
		// These rows used to print the halved value with a [LOCKED] tag
		// beside it, which gives the whole thing away -- you could see
		// exactly what you were buying and simply never buy a bad one.
		// Hiding the number is what makes the gold a gamble: a cursed
		// stat may be a ruined masterpiece or a ruined dud, and paying
		// is the only way to find out.
		AddRow("DAMAGE/SHOT",
			rsw.LockedDamage ? "???   (cursed)"
				: string.format("%d   (ceiling %d)", rsw.DamagePerShot, rsw.GetDamageCeiling()),
			rsw.LockedDamage ? Font.CR_DARKRED : Font.CR_TAN, "", 0,
			"Per-pellet damage, exact -- what you see is what lands.\nThe ceiling rises with every Promotion.");
		// DPS is derived from damage, so it must hide too -- otherwise it
		// leaks the exact number the curse is concealing.
		AddRow("DPS", rsw.LockedDamage ? "???" : string.format("%d", dps),
			rsw.LockedDamage ? Font.CR_DARKRED : Font.CR_TAN, "", 0,
			"Damage x pellets x rate of fire. Derived, not rolled.");
		// BARS. Every row below carries barFrac so the sheet reads at a
		// glance instead of being a wall of right-aligned numbers -- the
		// bar renderer in RS_UIMenus has existed since the sheet was
		// built and not one of the 75 rows was using it. A cursed stat
		// passes -1 deliberately: no bar, because a bar IS the number and
		// drawing one would leak exactly what the curse hides.
		AddRow("RATE OF FIRE", string.format("%d/s", rsw.RateOfFire), Font.CR_TAN,
			"", 0, "Trigger pulls per second. Never cursed.",
			clamp(rsw.RateOfFire / 20.0, 0.0, 1.0), rsw.Tier);
		AddRow("ACCURACY",
			rsw.LockedAccuracy ? "???   (cursed)" : string.format("%d", int(rsw.Accuracy)),
			rsw.LockedAccuracy ? Font.CR_DARKRED : Font.CR_TAN,
			"", 0, "Tighter cone, straighter shot.",
			rsw.LockedAccuracy ? -1.0 : clamp(rsw.Accuracy / 100.0, 0.0, 1.0),
			rsw.Tier);
		AddRow("CRIT",
			rsw.LockedCritChance ? "???   (cursed)" : string.format("%.1f%%", rsw.CritChance * 100.0),
			rsw.LockedCritChance ? Font.CR_DARKRED : Font.CR_TAN,
			"", 0, "Chance any single pellet lands doubled.",
			rsw.LockedCritChance ? -1.0 : clamp(rsw.CritChance * 4.0, 0.0, 1.0),
			rsw.Tier);
		AddRow("VELOCITY",
			rsw.LockedVelocity ? "???   (cursed)" : string.format("%d", int(rsw.Velocity)),
			rsw.LockedVelocity ? Font.CR_DARKRED : Font.CR_TAN,
			"", 0, "How fast the round travels. Matters for leading.",
			rsw.LockedVelocity ? -1.0 : clamp(rsw.Velocity / 60.0, 0.0, 1.0),
			rsw.Tier);
		int magNow = wep.AmmoType2 ? pawn.CountInv(wep.AmmoType2) : 0;
		// The loaded count is honest either way; only CAPACITY is cursed.
		AddRow("MAGAZINE",
			rsw.LockedCapacity ? string.format("%d / ???", magNow)
				: string.format("%d / %d", magNow, rsw.Capacity),
			rsw.LockedCapacity ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("PELLETS", string.format("%d", rsw.PelletCount), Font.CR_TAN, "", 0,
			"Promotion's permanent reward: +1 per cash-in.");
		if (rsw.Choke > 0)
			AddRow("CHOKE", string.format("%.2f", rsw.Choke), Font.CR_TAN,
				"", 0, "Tightens the pellet cone. Shotgun-family exclusive.");
		// Informational. Repair is passive -- there is nothing to confirm
		// here, and the menu this used to open did nothing worth opening.
		AddRow("CONDITION", string.format("%d%%", int(rsw.Condition)),
			RS_UIStyle.ConditionColor(rsw.Condition), "", 0,
			"Below 50, worn guns roll hot -- more damage, backfire risk.\nRepairs itself over time.",
			clamp(rsw.Condition / 100.0, 0.0, 1.0), rsw.Tier);
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
				// The affix's own description, as the row tooltip. GetDesc
				// has existed on every upgrade since GunBonsai shipped and
				// this sheet never asked for it -- so a held affix showed a
				// name and a level and nothing about what it actually does.
				string blurb = upg.GetDesc();
				string tip = upg.GetTooltip(upg.level);
				if (tip != "") blurb = blurb .. "\n\n" .. tip;
				AddRow("  " .. upg.GetName(),
					string.format("Lv %d   %s", upg.level, tag),
					(mastered || masteryNext) ? Font.CR_ORANGE : Font.CR_WHITE,
					"", 0, blurb,
					// Six takes is the ladder; the bar is progress to
					// Mastery, tinted with the weapon's tier.
					clamp(upg.level / 6.0, 0.0, 1.0), rsw.Tier);
			}
			if (held == 0)
				AddRow("  (none yet)", "", Font.CR_DARKGRAY);
		}

		// --- The four attack inputs ---
		// One row per input that actually has content, so a normal gun
		// shows one line and a fully built one shows four. Rotation is
		// reported per slot, because "every 3rd shot" and "every 3rd
		// alt-fire" are now different statements.
		AddRule();
		AddRow("ATTACK SLOTS", "", Font.CR_LIGHTBLUE);
		string slotNames[4];
		slotNames[0] = "  FIRE";
		slotNames[1] = "  ALT-FIRE";
		slotNames[2] = "  MOD + FIRE";
		slotNames[3] = "  MOD + ALT";
		bool anySlot = false;
		for (int s = 0; s < RS_Weapon.RS_SLOT_COUNT; s++)
		{
			let sl = rsw.GetSlot(s);
			if (!sl || sl.IsEmpty()) continue;
			anySlot = true;
			int n = sl.Count();
			AddRow(slotNames[s],
				n > 1 ? string.format("%d beats, cycling", n) : "1 beat",
				n > 1 ? Font.CR_ORANGE : Font.CR_TAN, "", 0,
				n > 1
					? "This input cycles these beats in order, one per pull.\nAn affix beat lands every Nth time you use THIS input."
					: "One profile. Every pull of this input is the same shot.",
				clamp(n / 4.0, 0.0, 1.0), rsw.Tier);
		}
		if (!anySlot)
			AddRow("  (no profiles built)", "", Font.CR_DARKGRAY);
		AddRule();

		// --- Curses on this hand ---
		// The stat rows above already hide cursed NUMBERS, but the eight
		// player flaws never appeared on any sheet at all -- you could be
		// jam-prone and hungry on this hand with nothing anywhere saying
		// so. Listed only when carried, so a clean hand costs one line.
		{
			int flaws = 0;
			for (int f = 0; f < RS_Curse.FLAW_COUNT; f++)
				if (RS_CurseLedger.Has(pawn, f, hand)) flaws++;

			AddRow(string.format("CURSES  (%d on this hand)", flaws), "",
				flaws > 0 ? Font.CR_DARKRED : Font.CR_LIGHTBLUE);

			if (flaws == 0)
				AddRow("  (clean)", "", Font.CR_DARKGRAY);
			else
				for (int f = 0; f < RS_Curse.FLAW_COUNT; f++)
				{
					if (!RS_CurseLedger.Has(pawn, f, hand)) continue;
					// Informational, not a route. Repair is passive and
					// there is no curse menu worth sending anyone to --
					// this row exists so you can SEE what you are
					// carrying, which nothing anywhere did before.
					AddRow("  " .. RS_Curse.FlawName(f), "ACTIVE", Font.CR_DARKRED,
						"", 0, RS_Curse.FlawBlurb(f, hand));
				}
		}
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
			string.format("GUN LEVELS  %d / %d", int(stats.XP), int(pmax)),
			Font.CR_WHITE, "", 0, "",
			pmax > 0 ? clamp(stats.XP / pmax, 0.0, 1.0) : 0.0, -1);

		// THE MISSING DOOR, added 2026-08-07.
		//
		// The player track had no way to be spent. Weapon levels fed it
		// 1 each, it filled, GunBonsai logged "player level up ready"
		// (PerPlayerStats.zsc:249) -- and then nothing, forever, because
		// upstream deliberately stopped auto-opening the screen and
		// GBOH_UnifiedInfo's fallback path is unreachable: the RS UI
		// handler intercepts it and cycles sheets instead, on the stated
		// promise that "level-ups launch from the sheets' own LEVEL UP
		// rows" (EventHandler.zsc). The weapon sheets have that row.
		// This one never did.
		//
		// Same shape as the weapon sheet's row 200 lines up, with -1 as
		// the hand argument to mean "the player, not a weapon".
		if (stats.XP >= pmax)
			AddRow(">> PLAYER LEVEL UP! <<", "choose a player upgrade",
				Font.CR_ORANGE, "rs-ui-levelup", -1,
				"A player level is banked. Confirm to open the picker.\nEarned from gun levels, not from kills directly.");
		AddRule();

		// --- Both hands' GunBonsai levels, at a glance. The hand sheets
		// carry the detail; this is the "where do my guns stand" summary
		// the player track feeds from (each gun level = +1 player XP). ---
		for (int hand = 0; hand <= 1; hand++)
		{
			string hn = (hand == 0) ? "OFFHAND" : "MAINHAND";
			let hwep = HandWeapon(pawn, hand);
			if (!hwep)
			{
				AddRow(hn, "(empty)", Font.CR_DARKGRAY);
				continue;
			}
			let hrsw = RS_Weapon(hwep);
			let hinfo = stats.GetInfoFor(hwep);
			int hcol = hrsw ? RS_UIStyle.TierColor(hrsw.Tier) : Font.CR_WHITE;
			if (hinfo)
				AddRow(hn .. "  " .. hwep.GetTag(),
					string.format("LEVEL %d   %d / %d xp%s", hinfo.level,
						int(hinfo.XP), int(hinfo.maxXP),
						hinfo.XP >= hinfo.maxXP ? "   >> LEVEL UP!" : ""),
					hcol, "", 0, "",
					hinfo.maxXP > 0 ? clamp(hinfo.XP / hinfo.maxXP, 0.0, 1.0) : 0.0,
					hrsw ? hrsw.Tier : -1);
			else
				AddRow(hn .. "  " .. hwep.GetTag(), "(no GunBonsai info yet)", hcol);
		}
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
	// A thin wrapper now -- HandWeapon(pawn, hand) is the only thing this
	// used `hand` for. Split out so the in-world card can build the SAME
	// row model off an arbitrary weapon (the one the weapon wheel is
	// currently pointed at, say) rather than only ever "whatever this
	// hand is holding".
	void BuildWeaponCard(PlayerPawn pawn, int hand)
	{
		BuildWeaponCardForWeapon(pawn, HandWeapon(pawn, hand));
	}

	void BuildWeaponCardForWeapon(PlayerPawn pawn, Weapon wep)
	{
		ClearModel();

		// BOTH EARLY RETURNS MUST SET COLOUR, NOT JUST TITLE.
		//
		// mTitleColor/mSubtitleColor/mSheetTier are FIELDS on this
		// singleton, not locals -- a return with no assignment leaves
		// whatever the PREVIOUS build happened to leave there, and on
		// the very first build ever (or after a level change resets the
		// handler) that is the zero-default, Font.CR_UNTRANSLATED. Every
		// renderer's CR->RGB table (RS_CardPanel.CRToRGB included) has no
		// case for CR_UNTRANSLATED and falls through to its "readable
		// text" default -- (216,222,233), near-white -- which is fine
		// for TEXT and wrong for a SHELL: a card colouring its whole
		// border from this is a solid near-white plate with no visible
		// contrast against anything drawn on top of it. Confirmed via a
		// screenshot of wr_DataCard showing exactly that for a non-RS
		// weapon. Font.CR_DARKGRAY here is the row's own colour already
		// used two lines below -- reusing it for the title keeps both
		// legible and both honest about "there is nothing to show".
		if (!wep) { mTitle = "NO WEAPON"; mTitleColor = Font.CR_DARKGRAY; mSheetTier = -1; return; }

		mTitle = wep.GetTag();
		let rsw = RS_Weapon(wep);
		if (!rsw)
		{
			mTitleColor = Font.CR_DARKGRAY;
			mSheetTier = -1;
			AddRow("(not an RS weapon)", "", Font.CR_DARKGRAY);
			return;
		}

		mTitleColor = RS_UIStyle.TierColor(rsw.Tier);
		mSubtitle = RS_UIStyle.TierName(rsw.Tier) .. "      " .. RS_UIStyle.Pips(rsw.PromotionCount);
		mSubtitleColor = RS_UIStyle.TierColor(rsw.Tier);
		mSheetTier = rsw.Tier;

		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		let info = stats ? stats.GetInfoFor(wep) : null;
		int held = 0;
		if (info)
		{
			for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
				if (info.upgrades.upgrades[i].level > 0) held++;
		}

		int dps = int(rsw.DamagePerShot * max(1, rsw.PelletCount) * max(1, rsw.RateOfFire));
		int magNow = wep.AmmoType2 ? pawn.CountInv(wep.AmmoType2) : 0;

		if (info)
			AddRow(string.format("LEVEL %d", info.level),
				string.format("%d / %d xp", int(info.XP), int(info.maxXP)),
				Font.CR_WHITE, "", 0, "",
				info.maxXP > 0 ? clamp(info.XP / info.maxXP, 0.0, 1.0) : 0.0,
				rsw.Tier);
		// TWO FAMILIES, so the sheet stops reading as one flat tan. Offense
		// (what the gun does to a target) runs warm; handling (how well
		// you land it) runs cool. Sockets, level and condition keep their
		// own colours -- they were never the problem, only the eight
		// stats sharing one hue between them were. Locked still wins over
		// both: red is red regardless of family, because a curse is not
		// a category, it is a state.
		// FIRE for offense, SAPPHIRE for handling -- not ORANGE/CYAN, and
		// not ICE either any more. Those first two are already spoken
		// for: RS_StatusBar's HAND_MAIN/HAND_OFF are exactly Font.CR_
		// ORANGE and Font.CR_CYAN, and the token card's own MAINHAND/
		// OFFHAND chip uses the same pair in RGB. ICE was the first pick
		// for handling and it was wrong for a different reason: at
		// (190,215,255) it sits close enough to plain white that next to
		// FIRE's saturated orange it read as barely-there, not as a
		// second family -- confirmed against a screenshot where DAMAGE/
		// CRIT/PELLETS clearly popped and ACCURACY/VELOCITY did not.
		// SAPPHIRE (80,170,255) is a real, saturated blue instead.
		AddRow("DAMAGE", string.format("%d  (ceiling %d)", rsw.DamagePerShot, rsw.GetDamageCeiling()),
			rsw.LockedDamage ? Font.CR_DARKRED : Font.CR_FIRE);
		AddRow("ROF", string.format("%d/s", rsw.RateOfFire), Font.CR_SAPPHIRE);
		AddRow("DPS", string.format("%d", dps), Font.CR_FIRE);
		AddRow("ACCURACY", string.format("%d%s", int(rsw.Accuracy), rsw.LockedAccuracy ? "  [LOCKED]" : ""),
			rsw.LockedAccuracy ? Font.CR_DARKRED : Font.CR_SAPPHIRE);
		AddRow("CAPACITY", string.format("%d / %d", magNow, rsw.Capacity),
			rsw.LockedCapacity ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("CRIT", string.format("%.1f%%%s", rsw.CritChance * 100.0, rsw.LockedCritChance ? "  [LOCKED]" : ""),
			rsw.LockedCritChance ? Font.CR_DARKRED : Font.CR_FIRE);
		AddRow("PELLETS", string.format("%d", rsw.PelletCount), Font.CR_FIRE);
		AddRow("VELOCITY", string.format("%d", int(rsw.Velocity)),
			rsw.LockedVelocity ? Font.CR_DARKRED : Font.CR_SAPPHIRE);
		AddRow("BONSOC", string.format("%d / %d", held, rsw.GunBonaiSockets), Font.CR_LIGHTBLUE);
		// CRIT MULT took TIME BTWN's sheet slot (owner ruling 2026-08-05):
		// TBS was always derived from ROF, already shown one row up.
		AddRow("CRIT MULT", string.format("x%.1f", rsw.CritMult > 0 ? rsw.CritMult : 2.0), Font.CR_FIRE);
		AddRow("CONDITION", string.format("%d%%", int(rsw.Condition)),
			RS_UIStyle.ConditionColor(rsw.Condition));
	}


	// -----------------------------------------------------------------
	// S6 -- THE DROP COMPARISON.
	//
	// The first screen that answers a QUESTION instead of reporting a
	// state. The weapon sheet says what a gun is; this says whether to
	// take it. Per rs_00 the live decision is never "what are this gun's
	// numbers", it is "do I keep developing what I have or rebuild on
	// this" -- and that is a comparison, which is the one thing a HUD
	// structurally cannot show, because it has one column.
	//
	// Three columns -- offhand held | THE DROP | mainhand held -- which
	// is already the shape of the dual-hand inventory and of CycleSheets.
	//
	// Built into the SHARED row model on purpose. The in-world panel is a
	// second renderer for this same model, so every decision made here --
	// which rows matter, what beats what, what is worth shouting about --
	// survives whatever shape the billboard surface comes back in. This
	// is data, not draw calls.
	// -----------------------------------------------------------------

	// One comparison cell. An absent hand renders as a dash and never as a
	// zero: an empty hand is not a weapon that scores nothing.
	static string TriCell(double v, bool present, int decimals = 0)
	{
		if (!present) return "--";
		if (decimals > 0) return string.format("%.1f", v);
		return string.format("%d", int(v));
	}

	// The model carries one color per row, so the color IS the verdict:
	// green beats both hands, yellow beats one, brick beats neither.
	static int TriVerdict(double drop, double off, bool hasOff, double main, bool hasMain)
	{
		int wins = 0, losses = 0;
		if (hasOff)  { if (drop > off)  wins++; else if (drop < off)  losses++; }
		if (hasMain) { if (drop > main) wins++; else if (drop < main) losses++; }
		if (wins > 0 && losses == 0) return Font.CR_GREEN;
		if (wins > 0)                return Font.CR_YELLOW;
		if (losses > 0)              return Font.CR_BRICK;
		return Font.CR_DARKGRAY;
	}

	// Adds one comparison row -- and DROPS it when all three columns
	// agree. Twelve stats is not glanceable at reading distance, and this
	// model is meant to be read from across a room; a row that says the
	// same thing three times is noise competing with the row that
	// decides. "Identical" means identical AS DISPLAYED, so the cells are
	// compared after formatting: that sidesteps float equality and it
	// matches what the player can actually see.
	void AddTriRow(string label, double drop, double off, bool hasOff,
		double main, bool hasMain, int decimals = 0)
	{
		string cOff  = TriCell(off,  hasOff,  decimals);
		string cDrop = TriCell(drop, true,    decimals);
		string cMain = TriCell(main, hasMain, decimals);

		if ((!hasOff || cOff == cDrop) && (!hasMain || cMain == cDrop)) return;

		AddRow(label, string.format("%5s  [ %s ]  %-5s", cOff, cDrop, cMain),
			TriVerdict(drop, off, hasOff, main, hasMain));
	}

	void BuildDropCompare(PlayerPawn pawn, Weapon drop)
	{
		ClearModel();

		let d = RS_Weapon(drop);
		if (!d)
		{
			mTitle = "NO DROP";
			AddRow("(not an RS weapon)", "", Font.CR_DARKGRAY);
			return;
		}

		let offW  = RS_Weapon(HandWeapon(pawn, 0));
		let mainW = RS_Weapon(HandWeapon(pawn, 1));
		bool hasOff  = (offW  != null);
		bool hasMain = (mainW != null);

		mTitle = d.GetTag();
		mTitleColor = RS_UIStyle.TierColor(d.Tier);
		mSubtitle = RS_UIStyle.TierName(d.Tier) .. "   " .. RS_UIStyle.Pips(d.PromotionCount);
		mSubtitleColor = RS_UIStyle.TierColor(d.Tier);
		mSheetTier = d.Tier;

		AddRow("OFFHAND",  hasOff  ? offW.GetTag()  : "(empty)",
			hasOff  ? RS_UIStyle.TierColor(offW.Tier)  : Font.CR_DARKGRAY);
		AddRow("MAINHAND", hasMain ? mainW.GetTag() : "(empty)",
			hasMain ? RS_UIStyle.TierColor(mainW.Tier) : Font.CR_DARKGRAY);
		AddRule();
		AddRow("", string.format("%5s  [ %s ]  %-5s", "OFF", "DROP", "MAIN"), Font.CR_DARKGRAY);

		int rowsBefore = mRowKey.Size();

		// PELLETS LEADS, because +1 pellet is roughly double damage --
		// it is the entire Promotion payoff (rs_00), and a thrice-promoted
		// Uncommon buries an unpromoted Prototype on this row alone. It
		// cannot sit in the same weight as ACCURACY six rows down.
		int dp = max(1, d.PelletCount);
		int op = hasOff  ? max(1, offW.PelletCount)  : 0;
		int mp = hasMain ? max(1, mainW.PelletCount) : 0;
		AddTriRow("PELLETS", dp, op, hasOff, mp, hasMain);
		if ((hasOff && dp != op) || (hasMain && dp != mp))
			AddRow("   ^ each pellet is a full damage roll", "", Font.CR_GOLD);

		AddTriRow("DAMAGE", d.DamagePerShot,
			hasOff  ? offW.DamagePerShot  : 0, hasOff,
			hasMain ? mainW.DamagePerShot : 0, hasMain);

		AddTriRow("DPS", d.DamagePerShot * dp * max(1, d.RateOfFire),
			hasOff  ? offW.DamagePerShot  * op * max(1, offW.RateOfFire)  : 0, hasOff,
			hasMain ? mainW.DamagePerShot * mp * max(1, mainW.RateOfFire) : 0, hasMain);

		AddTriRow("ROF", d.RateOfFire,
			hasOff  ? offW.RateOfFire  : 0, hasOff,
			hasMain ? mainW.RateOfFire : 0, hasMain);

		AddTriRow("ACCURACY", d.Accuracy,
			hasOff  ? offW.Accuracy  : 0, hasOff,
			hasMain ? mainW.Accuracy : 0, hasMain);

		AddTriRow("CRIT %", d.CritChance * 100.0,
			hasOff  ? offW.CritChance  * 100.0 : 0, hasOff,
			hasMain ? mainW.CritChance * 100.0 : 0, hasMain, 1);

		AddTriRow("CRIT MULT", d.CritMult > 0 ? d.CritMult : 2.0,
			hasOff  ? (offW.CritMult  > 0 ? offW.CritMult  : 2.0) : 0, hasOff,
			hasMain ? (mainW.CritMult > 0 ? mainW.CritMult : 2.0) : 0, hasMain, 1);

		AddTriRow("VELOCITY", d.Velocity,
			hasOff  ? offW.Velocity  : 0, hasOff,
			hasMain ? mainW.Velocity : 0, hasMain);

		AddTriRow("CAPACITY", d.Capacity,
			hasOff  ? offW.Capacity  : 0, hasOff,
			hasMain ? mainW.Capacity : 0, hasMain);

		// SOCKETS is the rebuild argument. An Uncommon with two sockets
		// and good rolls is rs_00's "better foundation" case -- the whole
		// reason to walk away from a higher tier -- so it has to be
		// visible AT the decision, not one menu later.
		AddTriRow("SOCKETS", d.GunBonaiSockets,
			hasOff  ? offW.GunBonaiSockets  : 0, hasOff,
			hasMain ? mainW.GunBonaiSockets : 0, hasMain);

		AddTriRow("CONDITION", d.Condition,
			hasOff  ? offW.Condition  : 0, hasOff,
			hasMain ? mainW.Condition : 0, hasMain);

		if (mRowKey.Size() == rowsBefore)
			AddRow("(identical on every stat)", "", Font.CR_DARKGRAY);

		// A Cursed drop carrying a monster roll under its locks is the
		// most interesting pickup in the game. The locks are what make it
		// a gamble rather than a downgrade, so they have to be legible at
		// the decision -- the player is being asked to bet on what they
		// cannot see yet.
		string locks = "";
		if (d.LockedDamage)     locks = locks .. "DMG ";
		if (d.LockedAccuracy)   locks = locks .. "ACC ";
		if (d.LockedVelocity)   locks = locks .. "VEL ";
		if (d.LockedCritChance) locks = locks .. "CRIT ";
		if (d.LockedCapacity)   locks = locks .. "CAP ";
		if (locks != "")
		{
			AddRule();
			AddRow("LOCKED", locks, Font.CR_DARKRED);
		}

		// Deliberately NO overall verdict line. A win-count would weight
		// ACCURACY the same as PELLETS, which is false -- and a summary
		// that lies is worse than none. The row colors and the pellet
		// callout carry the judgment the design has actually made; the
		// rest is the player's call, which is the point of the screen.
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
		mSheetTier = rsw.Tier;

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

		// CURSE LIFTING, built 2026-08-07. This row used to read
		// "(curse-lifting not yet awakened)" -- the flags were set, the
		// unlock function existed with its 1.5x reward, and nothing in
		// the game could ever call it.
		//
		// Owner ruling: a curse OBSCURES the stat's real value until it
		// is lifted by spending gold, and lifting it adds 1.5x to that
		// stat. So the row shows ??? rather than the halved number --
		// you are buying information as much as power, and you cannot
		// tell a cursed masterpiece from a cursed dud until you pay.
		// CURSE BITS, NOT GOLD, AND PER-STAT PRICING. Changed 2026-08-07
		// with the curse rework.
		//
		// This screen charged a flat 25 GOLD while the rest of the system
		// charges RS_Bit_Curse at a price that varies by how much the
		// curse hurts. Two prices in two currencies for the same action is
		// the kind of split that only shows up when a player finds one
		// route and not the other. One source of truth now:
		// RS_Curse.StatCost().
		int bits = pawn.CountInv("RS_Bit_Curse");
		bool anyLocked = rsw.HasAnyCurse();
		AddRow("CURSES", string.format("%d curse bits", bits), Font.CR_PURPLE);
		if (!anyLocked)
			AddRow("  (no locked stats)", "", Font.CR_DARKGRAY);
		else
		{
			AddCurseRow(rsw, bits, hand, "damage",     "  > LIFT DAMAGE",
				rsw.LockedDamage,     rsw.CurseStackDamage,     0);
			AddCurseRow(rsw, bits, hand, "accuracy",   "  > LIFT ACCURACY",
				rsw.LockedAccuracy,   rsw.CurseStackAccuracy,   1);
			AddCurseRow(rsw, bits, hand, "velocity",   "  > LIFT VELOCITY",
				rsw.LockedVelocity,   rsw.CurseStackVelocity,   2);
			AddCurseRow(rsw, bits, hand, "critchance", "  > LIFT CRIT",
				rsw.LockedCritChance, rsw.CurseStackCritChance, 3);
			AddCurseRow(rsw, bits, hand, "capacity",   "  > LIFT CAPACITY",
				rsw.LockedCapacity,   rsw.CurseStackCapacity,   4);

			AddRow("  (price varies by stat -- see Curses options)", "",
				Font.CR_DARKGRAY);
		}
	}

	// One lift row. Shows the stack depth, because a stat cursed twice
	// needs two lifts and the first one pays no bonus -- a player looking
	// at "x2" understands why the number did not jump.
	void AddCurseRow(RS_Weapon rsw, int bits, int hand, string stat,
		string label, bool locked, int stack, int idx)
	{
		if (!locked) return;

		int cost = RS_Curse.StatCost(stat);
		bool afford = bits >= cost;
		int  col = afford ? Font.CR_GOLD : Font.CR_DARKGRAY;

		string tip = afford
			? "Lift it: the stat is RESTORED to its real value, boosted, and the weapon gains a tier."
			: string.format("Costs %d Curse Bits. You have %d.", cost, bits);

		string shown = (stack > 1) ? string.format("??? x%d", stack) : "???";

		AddRow(label, shown, col, afford ? "rs-ui-uncurse" : "",
			hand * 8 + idx, tip);
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
			// arg -1 = THE PLAYER's own level, not a weapon's. The player
			// sheet's LEVEL UP row sends this; every weapon sheet sends a
			// real hand index. Without this branch the player track had
			// no spend path at all -- see BuildPlayerSheet.
			if (evt.args[0] < 0)
			{
				if (stats) stats.StartLevelUp();
			}
			else
			{
				// Open the card picker for this hand's weapon, via GB's own
				// giver flow (which opens our re-pointed menu).
				let wep = HandWeapon(pawn, evt.args[0]);
				let info = (stats && wep) ? stats.GetInfoFor(wep) : null;
				if (info) info.StartLevelUp();
			}
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
		else if (evt.name == "rs-ui-drop-compare")
		{
			// Dev harness for the drop comparison until the drop system
			// has a real dropped weapon to hand it. Judges the named
			// hand's weapon AS IF it were the drop, so the layout, the
			// verdict colors and the equal-row filter can all be seen
			// with live numbers today, in the flat menu, with no engine
			// billboard in existence. arg0: 0 offhand, 1 mainhand.
			let w = HandWeapon(pawn, evt.args[0]);
			if (w)
			{
				BuildDropCompare(pawn, w);
				if (players[consoleplayer].mo == pawn)
					Menu.SetMenu("RSDynamicSheet");
			}
		}
		// rs-showcase REMOVED 2026-08-07, at the owner's direction: "the
		// showcase has no purpose apart to prove something to me i don't
		// care about." It was a dev toggle that spun a weapon on a
		// pedestal with a card above it, and it was the ONLY consumer of
		// the billboard natives in this file.
		//
		// It is also the whole reason the mod stopped booting: this branch
		// called AttachBillboard / RemoveBillboard / BB_TEXTURE /
		// tex.GetIndex(), and every one of those was absent from the
		// engine, so a single unresolved name here took the entire mod
		// down at codegen -- all 17 monster families, every weapon, the
		// lot. Three separate comments in this branch claimed the natives
		// had been "verified against the engine tree"; they had not.
		//
		// The in-world UI lives in zscript/systems/ui/ now:
		else if (evt.name == "rs-ui-repair-menu")
		{
			BuildCurseRepair(pawn, evt.args[0]);
			if (players[consoleplayer].mo == pawn)
				Menu.SetMenu("RSDynamicSheet");
		}
		else if (evt.name == "rs-ui-uncurse")
		{
			// arg packs hand and which stat: hand*8 + statIndex.
			int hand = evt.args[0] / 8;
			int which = evt.args[0] % 8;
			let rsw = RS_Weapon(HandWeapon(pawn, hand));
			if (!rsw) return;

			// Work out WHICH stat first, so an unlocked one costs nothing
			// and a double-press cannot be charged twice.
			string statName = "";
			switch (which)
			{
				case 0: if (rsw.LockedDamage)     statName = "damage";     break;
				case 1: if (rsw.LockedAccuracy)   statName = "accuracy";   break;
				case 2: if (rsw.LockedVelocity)   statName = "velocity";   break;
				case 3: if (rsw.LockedCritChance) statName = "critchance"; break;
				case 4: if (rsw.LockedCapacity)   statName = "capacity";   break;
			}
			if (statName == "") return;

			int cost = RS_Curse.StatCost(statName);
			if (pawn.CountInv("RS_Bit_Curse") < cost)
			{
				pawn.A_Log(string.format("Lifting %s costs %d Curse Bits. You have %d.",
					statName, cost, pawn.CountInv("RS_Bit_Curse")), true);
				return;
			}

			// Charge only if the lift actually happened. UnlockStat now
			// returns whether it did, so this cannot take bits for nothing.
			if (!rsw.UnlockStat(statName))
				return;

			pawn.TakeInventory("RS_Bit_Curse", cost);

			// Only drop the keyword when the LAST stack on that stat is
			// gone -- a doubly-cursed stat is still cursed after one lift,
			// and the keyword is what the rest of the mod reads to know.
			if (!rsw.IsStatCursed(statName))
				rsw.UngrantKeyword("curse", statName);

			pawn.A_StartSound("rs_bit_repair", CHAN_AUTO, CHANF_DEFAULT, 0.7);
			pawn.A_Log(string.format("Curse lifted: %s restored and boosted.",
				statName), true);

			BuildCurseRepair(pawn, hand);
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
				if (expanding)
				{
					// ADD a card; keep the ones on screen. Both branches
					// used to call CreateUpgradeCandidates(), which
					// clears and redraws -- so "another card" silently
					// rerolled the whole offer and the cards the player
					// was reading were gone. Reroll SHOULD redraw; that
					// is what it is for. Expand should not.
					giver.rsExtraCards++;
					giver.RS_AddCandidate();
				}
				else
				{
					giver.rsRerolls++;
					giver.CreateUpgradeCandidates();
				}
			}

			// Release the menu claim either way, then let the giver
			// reclaim and reopen -- the player is never dumped back to
			// gameplay with a level still banked.
			stats.currentEffectGiver = null;
			giver.SetStateLabel("ChooseUpgrade");
		}
	}
}

// =====================================================================
// RS_WeaponInfoService -- the row model, reachable from a mod that has
// never heard of RS_UIHandler, RS_Weapon, or the row model's own shape.
//
// THE WHEEL NOW OWNS THE CARD. Owner's ruling: "the wheel and those
// cards should be a uniform system... the 'wheel' needs to be the wheel
// + data card... if a mod we load this with doesn't have a compat
// patch, then the data card is disabled and it is just the wheel." That
// flips the dependency this session had been building the other way --
// RS_Main no longer hosts the card and reaches out to the wheel for a
// position; the WHEEL hosts the card (wr_DataCard, RS_WeaponWheel/
// zscript.zs) and reaches out to whichever weapon mod is loaded, for
// CONTENT ONLY. Position is now a same-object field read on the wheel's
// own side -- no Service round trip for it at all, which is what
// removes the exact class of timing bug this session kept chasing.
//
// Every request answers in PLAIN STRINGS, INTS AND DOUBLES -- no Object
// carrying RS_UIHandler across, which would just move the hard-
// dependency problem into a downcast the wheel cannot make. Rows are
// addressed by INDEX (intArg), the weapon by OBJECT (objectArg); nothing
// else about the row model's own class needs to exist on the far side.
//
//   GetInt   ("RowCount",      objectArg: Weapon)            -> N
//   GetInt   ("TitleColor",    objectArg: Weapon)             -> packed 0xRRGGBB
//   GetInt   ("SubtitleColor", objectArg: Weapon)             -> packed 0xRRGGBB
//   GetInt   ("SheetTier",     objectArg: Weapon)             -> tier, or -1
//   GetInt   ("RowColor",      objectArg: Weapon, intArg: i)  -> packed 0xRRGGBB
//   GetInt   ("RowBarTier",    objectArg: Weapon, intArg: i)  -> tier, or -1
//   GetInt   ("TierRGB",       intArg: tier)                  -> packed 0xRRGGBB,
//                                                                 no weapon needed
//   GetDouble("RowBarFrac",    objectArg: Weapon, intArg: i)  -> 0..1, or -1
//   GetString("Title",         objectArg: Weapon)             -> weapon name
//   GetString("Subtitle",      objectArg: Weapon)             -> tier + pips
//   GetString("RowKey",        objectArg: Weapon, intArg: i)  -> label
//   GetString("RowVal",        objectArg: Weapon, intArg: i)  -> value text
//
//   GetInt   ("AffixHeld",     objectArg: Weapon)             -> N held
//   GetInt   ("AffixSockets",  objectArg: Weapon)             -> total sockets
//   GetInt   ("AffixLevel",    objectArg: Weapon, intArg: i)  -> 1..6+
//   GetString("AffixName",     objectArg: Weapon, intArg: i)  -> upgrade name
//   AffixName/AffixLevel are indexed 0..AffixHeld-1 across every HELD
//   upgrade (level > 0), uncapped -- how many a caller shows is its own
//   space decision, so it is not capped here the way the old RS_Main
//   card's own AFFIX_MAX once was.
//
// A weapon this mod cannot read (not an RS_Weapon, or null) answers
// RowCount 0 and everything else its own type's empty default -- the
// wheel's own card treats that as "nothing to show", never as an error.
// =====================================================================
class RS_WeaponInfoService : Service
{
	// The shared row model is rebuilt for the REQUESTED weapon once per
	// TIC, not once ever -- a caller asks one field at a time (GetInt/
	// GetString/GetDouble are separate overrides, and a card has a dozen
	// fields), so caching by weapon identity alone stops the rebuild
	// stampede within a single tic. Caching PAST that tic is a different
	// bug: the old RS_Main-only card called BuildWeaponCardForWeapon
	// unconditionally every WorldTick with no cache at all, so XP,
	// condition, and every other live stat were always current and only
	// the billboard REBUILD was gated on a signature change. Keying on
	// identity alone here would have frozen the row model the instant a
	// weapon was first read and never refreshed it again for as long as
	// the same weapon stayed equipped -- condition regenerating, XP
	// filling, an affix levelling, all invisible. mCachedTic is what
	// keeps this an equivalent-strength cache rather than a stronger,
	// wrong one.
	private Weapon mCachedFor;
	private int    mCachedTic;

	// NOT "ui" -- that is a reserved scope keyword (as in "class Foo ui"),
	// not an ordinary identifier, and using it as one is a parse error at
	// every line that reads it back. "hud" is what the old RS_Main-only
	// card called this exact value.
	//
	// "play" IS REQUIRED HERE, explicitly, even though the override
	// methods below already carry it. Service (engine/service.zs) has no
	// class-level scope tag of its own -- only its individual `virtual
	// play` methods do -- so a plain helper method with no scope keyword
	// defaults to DATA scope regardless of what its callers are. Calling
	// hud.BuildWeaponCardForWeapon (a play function) from a data-scope
	// Ensure() is "Can't call play function ... from data context", a
	// real compile error this shipped with once already.
	private play RS_UIHandler Ensure(Weapon w)
	{
		if (!w) return null;
		let hud = RS_UIHandler(EventHandler.Find("RS_UIHandler"));
		if (!hud) return null;

		if (mCachedFor != w || mCachedTic != level.maptime)
		{
			let pawn = PlayerPawn(w.Owner);
			hud.BuildWeaponCardForWeapon(pawn, w);
			mCachedFor = w;
			mCachedTic = level.maptime;
		}
		return hud;
	}

	// -----------------------------------------------------------------
	// THE AFFIX FOOTER. A genuinely separate cache from Ensure()'s row
	// model above -- it reads TFLV_PerPlayerStats directly rather than
	// going through RS_UIHandler, because the footer was never part of
	// the row model to begin with (the old RS_Main-only card built it
	// straight from GunBonsai's own upgrade list). Same tic-keyed
	// invalidation as Ensure(), same reason: an affix levelling up while
	// the same weapon stays hovered has to show up without waiting for
	// the weapon reference itself to change.
	//
	// Indexed 0..AffixHeld-1 across every HELD upgrade (level > 0) in
	// GunBonsai's own list order -- uncapped. How many of those a caller
	// actually shows is a rendering-space decision, not a data one, so
	// it is not decided here the way the old card's own AFFIX_MAX once
	// was.
	private Weapon mAffixCachedFor;
	private int    mAffixCachedTic;
	private Array<string> mAffixNames;
	private Array<int>    mAffixLevels;
	private int    mAffixHeld;
	private int    mAffixSockets;

	// "play" explicitly, same reason as Ensure() above -- this calls
	// TFLV_PerPlayerStats.GetStatsFor, a play function, and would
	// otherwise default to data scope with no class-level tag to inherit
	// from.
	private play void EnsureAffixes(Weapon w)
	{
		if (!w || (mAffixCachedFor == w && mAffixCachedTic == level.maptime))
			return;

		mAffixCachedFor = w;
		mAffixCachedTic = level.maptime;
		mAffixNames.Clear();
		mAffixLevels.Clear();
		mAffixHeld = 0;
		mAffixSockets = 0;
		if (!w) return;

		let rsw = RS_Weapon(w);
		if (!rsw) return;
		mAffixSockets = rsw.GunBonaiSockets;

		let pawn = PlayerPawn(w.Owner);
		let stats = pawn ? TFLV_PerPlayerStats.GetStatsFor(pawn) : null;
		let info = stats ? stats.GetInfoFor(w) : null;
		if (!info) return;

		for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
		{
			let upg = info.upgrades.upgrades[i];
			if (upg.level <= 0) continue;
			mAffixHeld++;
			mAffixNames.Push(upg.GetName());
			mAffixLevels.Push(upg.level);
		}
	}

	override int GetInt(String request, string stringArg, int intArg, double doubleArg, Object objectArg, Name nameArg)
	{
		// TierRGB needs no weapon at all -- RowBarTier answers a tier
		// INDEX (a promotion bar naming the tier it promotes toward, not
		// necessarily the weapon's own), and the caller has no other way
		// to turn that index into a colour without duplicating
		// RS_TierPalette's table a second time.
		if (request == "TierRGB") return Pack(RS_TierPalette.RGB(intArg));

		if (request == "AffixHeld")    { EnsureAffixes(Weapon(objectArg)); return mAffixHeld; }
		if (request == "AffixSockets") { EnsureAffixes(Weapon(objectArg)); return mAffixSockets; }
		if (request == "AffixLevel")
		{
			EnsureAffixes(Weapon(objectArg));
			return (intArg >= 0 && intArg < mAffixLevels.Size()) ? mAffixLevels[intArg] : 0;
		}

		let hud = Ensure(Weapon(objectArg));
		if (!hud) return (request == "SheetTier" || request == "RowBarTier") ? -1 : 0;

		if (request == "RowCount")      return hud.mRowKey.Size();
		if (request == "TitleColor")    return Pack(RS_CardPanel.CRToRGB(hud.mTitleColor));
		if (request == "SubtitleColor") return Pack(RS_CardPanel.CRToRGB(hud.mSubtitleColor));
		if (request == "SheetTier")     return hud.mSheetTier;

		if (request == "RowColor" && intArg >= 0 && intArg < hud.mRowColor.Size())
			return Pack(RS_CardPanel.CRToRGB(hud.mRowColor[intArg]));

		if (request == "RowBarTier" && intArg >= 0 && intArg < hud.mRowBarTier.Size())
			return hud.mRowBarTier[intArg];

		return 0;
	}

	private static int Pack(Color c)
	{
		return (int(c.r) << 16) | (int(c.g) << 8) | int(c.b);
	}

	override double GetDouble(String request, string stringArg, int intArg, double doubleArg, Object objectArg, Name nameArg)
	{
		let hud = Ensure(Weapon(objectArg));
		if (!hud) return -1.0;

		if (request == "RowBarFrac" && intArg >= 0 && intArg < hud.mRowBarFrac.Size())
			return hud.mRowBarFrac[intArg];

		return -1.0;
	}

	override String GetString(String request, string stringArg, int intArg, double doubleArg, Object objectArg, Name nameArg)
	{
		if (request == "AffixName")
		{
			EnsureAffixes(Weapon(objectArg));
			return (intArg >= 0 && intArg < mAffixNames.Size()) ? mAffixNames[intArg] : "";
		}

		let hud = Ensure(Weapon(objectArg));
		if (!hud) return "";

		if (request == "Title")    return hud.mTitle;
		if (request == "Subtitle") return hud.mSubtitle;

		if (request == "RowKey" && intArg >= 0 && intArg < hud.mRowKey.Size())
			return hud.mRowKey[intArg];
		if (request == "RowVal" && intArg >= 0 && intArg < hud.mRowVal.Size())
			return hud.mRowVal[intArg];

		return "";
	}
}
