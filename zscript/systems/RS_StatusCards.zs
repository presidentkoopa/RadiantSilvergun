// RS-flavored presentation layer for GunBonsai's status/toggle screen.
//
// Hooks in the same way as RS_LevelUpCards.zs: MENUDEF repoints
// GunBonsaiStatusDisplay's second declaration (the one that overrides
// Class to the offhand-aware variant) at RS_Menu_StatusCards instead of
// TFLV_Menu_UnifiedStatusDisplay. GunBonsai's own upgrade bags, toggle/tune
// netevents, and XP tracking are untouched -- this only replaces the plain
// text list with a box-per-upgrade grid plus a shared description panel,
// matching the reference layout's "highlight an upgrade to read about it"
// pattern.
//
// Data is reloaded every Drawer() call rather than cached, because toggle/
// tune go through EventHandler.SendNetworkEvent -- the change lands a tic
// or two later, not instantly. Re-reading live each frame is how the
// original TFLV_Menu_UpgradeToggle handles this too (see its Draw()
// override re-reading the tooltip every call).

class RS_Menu_StatusCards : OptionMenu {
  bool hasStats;
  int playerLevel;
  double playerXP, playerMaxXP;
  array<string> playerNames;
  array<bool> playerEnabled;
  array<int> playerLevels;
  array<string> playerDescs;

  string weaponTag;
  int weaponLevel;
  double weaponXP, weaponMaxXP;
  array<string> weaponNames;
  array<bool> weaponEnabled;
  array<int> weaponLevels;
  array<string> weaponDescs;

  bool hasOffhandWeapon;
  bool hasOffhandInfo;
  string offhandTag;
  int offhandLevel;
  double offhandXP, offhandMaxXP;
  array<string> offhandNames;
  array<bool> offhandEnabled;
  array<int> offhandLevels;
  array<string> offhandDescs;

  int focusSection; // 0=player, 1=mainhand weapon, 2=offhand weapon
  int cursorP, cursorW, cursorO;

  override void Init(Menu parent, OptionMenuDescriptor desc) {
    Super.Init(parent, desc);
    focusSection = 0;
    cursorP = 0;
    cursorW = 0;
    cursorO = 0;
  }

  void LoadBag(TFLV_Upgrade_UpgradeBag bag, out array<string> names, out array<bool> enab, out array<int> lvls, out array<string> descs) {
    names.Clear();
    enab.Clear();
    lvls.Clear();
    descs.Clear();
    for (int i = 0; i < bag.upgrades.size(); ++i) {
      let u = bag.upgrades[i];
      names.Push(u.GetName());
      enab.Push(u.enabled);
      lvls.Push(u.level);
      descs.Push(u.GetDesc());
    }
  }

  void LoadData() {
    hasStats = false;
    hasOffhandWeapon = false;
    hasOffhandInfo = false;
    playerNames.Clear();
    weaponNames.Clear();
    offhandNames.Clear();

    let pps = TFLV_EventHandler.GetConsolePlayerStats();
    if (!pps) return;

    TFLV_CurrentStats stats;
    hasStats = pps.GetCurrentStats(stats);
    if (!hasStats) return;

    playerLevel = stats.plvl;
    playerXP = stats.pxp;
    playerMaxXP = stats.pmax;
    LoadBag(stats.pupgrades, playerNames, playerEnabled, playerLevels, playerDescs);

    weaponTag = stats.wname;
    weaponLevel = stats.wlvl;
    weaponXP = stats.wxp;
    weaponMaxXP = stats.wmax;
    LoadBag(stats.wupgrades, weaponNames, weaponEnabled, weaponLevels, weaponDescs);

    let pawn = players[consoleplayer].mo;
    if (pawn && pawn.player.OffhandWeapon) {
      hasOffhandWeapon = true;
      let ohwep = pawn.player.OffhandWeapon;
      offhandTag = ohwep.GetTag();
      let ohinfo = pps.GetInfoFor(ohwep);
      if (ohinfo) {
        hasOffhandInfo = true;
        offhandLevel = ohinfo.level;
        offhandXP = ohinfo.XP;
        offhandMaxXP = ohinfo.maxXP;
        LoadBag(ohinfo.upgrades, offhandNames, offhandEnabled, offhandLevels, offhandDescs);
      }
    }
  }

  int CurrentSectionCount() {
    if (focusSection == 0) return playerNames.size();
    if (focusSection == 1) return weaponNames.size();
    return offhandNames.size();
  }

  int GetCursor() {
    if (focusSection == 0) return cursorP;
    if (focusSection == 1) return cursorW;
    return cursorO;
  }

  void SetCursor(int v) {
    if (focusSection == 0) cursorP = v;
    else if (focusSection == 1) cursorW = v;
    else cursorO = v;
  }

  // "name" is a reserved ZScript keyword (the built-in Name type), so it
  // can't be used as a parameter identifier -- the compiler reads
  // "out string name" as the start of a type declaration and chokes on
  // the "=" that follows inside the body. Renamed to outName.
  bool GetFocusedDesc(out string outName, out string desc) {
    int c = GetCursor();
    if (focusSection == 0 && c >= 0 && c < playerNames.size()) {
      outName = string.format("%s (Lv %d)", playerNames[c], playerLevels[c]);
      desc = playerDescs[c];
      return true;
    }
    if (focusSection == 1 && c >= 0 && c < weaponNames.size()) {
      outName = string.format("%s (Lv %d)", weaponNames[c], weaponLevels[c]);
      desc = weaponDescs[c];
      return true;
    }
    if (focusSection == 2 && c >= 0 && c < offhandNames.size()) {
      outName = string.format("%s (Lv %d)", offhandNames[c], offhandLevels[c]);
      desc = offhandDescs[c];
      return true;
    }
    return false;
  }

  void DrawSection(string header, string subtitle, uint subColor,
      array<string> names, array<bool> enab, array<int> lvls,
      int cursor, bool focused,
      int marginX, out int y, int panelW, int boxSize, int gutter, int maxCols,
      Font bodyFont, int lh, int fbw, int fbh) {
    RS_UIKit.DrawTextAt(bodyFont, header, marginX, y, 0xFFFFD040, fbw, fbh);
    RS_UIKit.DrawTextAt(bodyFont, subtitle, marginX, y + lh, subColor, fbw, fbh);
    y += lh*2 + 4;
    if (names.size() > 0) {
      y = RS_UIKit.DrawToggleGrid(names, enab, lvls, cursor, focused,
        marginX, y, panelW, boxSize, gutter, maxCols, bodyFont, fbw, fbh);
    }
    y += int(fbh * 0.02);
  }

  override void Drawer() {
    int fbw = Screen.GetWidth();
    int fbh = Screen.GetHeight();

    LoadData();

    RS_UIKit.FillRect(0, 0, fbw, fbh, 0xFF000000, 0.45, fbw, fbh);

    Font titleFont = Font.FindFont("BigFont");
    if (!titleFont) titleFont = Font.FindFont("NewSmallFont");
    Font bodyFont = Font.FindFont("NewSmallFont");
    int lh = bodyFont.GetHeight() + 2;

    RS_UIKit.DrawTextCentered(titleFont, "STATUS", fbw/2, int(fbh*0.04), 0xFFFFFFFF, fbw, fbh);

    if (!hasStats) {
      RS_UIKit.DrawTextCentered(bodyFont, "No stats available.", fbw/2, int(fbh*0.2), 0xFFFF6060, fbw, fbh);
      return;
    }

    int marginX = int(fbw * 0.06);
    int y = int(fbh * 0.11);
    int panelW = fbw - marginX*2;
    int boxSize = int(fbh * 0.065);
    int gutter = int(fbw * 0.008);
    int maxCols = max(1, panelW / (boxSize + gutter));

    DrawSection("PLAYER STATUS",
      string.format("Level %d   XP %d/%d", playerLevel, int(playerXP), int(playerMaxXP)), 0xFFC8C8C8,
      playerNames, playerEnabled, playerLevels, cursorP, focusSection == 0,
      marginX, y, panelW, boxSize, gutter, maxCols, bodyFont, lh, fbw, fbh);

    DrawSection("WEAPON STATUS",
      string.format("%s -- Level %d   XP %d/%d", weaponTag, weaponLevel, int(weaponXP), int(weaponMaxXP)), 0xFFC8C8C8,
      weaponNames, weaponEnabled, weaponLevels, cursorW, focusSection == 1,
      marginX, y, panelW, boxSize, gutter, maxCols, bodyFont, lh, fbw, fbh);

    if (hasOffhandWeapon && hasOffhandInfo) {
      DrawSection("OFFHAND WEAPON",
        string.format("%s -- Level %d   XP %d/%d", offhandTag, offhandLevel, int(offhandXP), int(offhandMaxXP)), 0xFFC8C8C8,
        offhandNames, offhandEnabled, offhandLevels, cursorO, focusSection == 2,
        marginX, y, panelW, boxSize, gutter, maxCols, bodyFont, lh, fbw, fbh);
    } else {
      string msg = hasOffhandWeapon
        ? string.format("%s -- (fire at an enemy to begin tracking)", offhandTag)
        : "(no offhand weapon equipped)";
      RS_UIKit.DrawTextAt(bodyFont, "OFFHAND WEAPON", marginX, y, 0xFFFFD040, fbw, fbh);
      RS_UIKit.DrawTextAt(bodyFont, msg, marginX, y + lh, 0xFF909090, fbw, fbh);
      y += lh*2 + int(fbh * 0.02);
    }

    // Floats right below whatever's actually drawn above, so a short
    // upgrade list doesn't leave a dead gap before this panel -- clamped
    // to a sane range in case a lot of upgrades push it down too far.
    int descH = int(fbh * 0.12);
    int descY = clamp(y + int(fbh * 0.02), int(fbh * 0.45), int(fbh * 0.80));
    RS_UIKit.FillRect(marginX, descY, panelW, descH, 0xFF0C0A18, 0.85, fbw, fbh);
    RS_UIKit.BorderRect(marginX, descY, panelW, descH, 2, 0xFF808080, fbw, fbh);

    string descName, descText;
    if (GetFocusedDesc(descName, descText)) {
      RS_UIKit.DrawTextAt(bodyFont, descName, marginX + 10, descY + 8, 0xFFFFD040, fbw, fbh);
      RS_UIKit.DrawWrapped(bodyFont, descText, marginX + 10, descY + 8 + lh, panelW - 20, 0xFFE6E6E6, fbw, fbh);
    } else {
      RS_UIKit.DrawTextAt(bodyFont, "Highlight an upgrade to read its full description here.", marginX + 10, descY + 8, 0xFF909090, fbw, fbh);
    }

    RS_UIKit.DrawTextCentered(bodyFont,
      "←→ select   ↑↓ level   ENTER toggle   PGUP/PGDN section",
      fbw/2, int(fbh*0.95), 0xFFC8C8C8, fbw, fbh);
  }

  void ToggleFocused() {
    int n = CurrentSectionCount();
    int c = GetCursor();
    if (n <= 0 || c < 0 || c >= n) return;
    MenuSound("menu/choose");
    EventHandler.SendNetworkEvent("bonsai-toggle-upgrade", focusSection, c);
  }

  void TuneFocused(int amount) {
    int n = CurrentSectionCount();
    int c = GetCursor();
    if (n <= 0 || c < 0 || c >= n) return;
    MenuSound("menu/cursor");
    EventHandler.SendNetworkEvent("bonsai-tune-upgrade", focusSection, c, amount);
  }

  override bool MenuEvent(int mkey, bool fromcontroller) {
    if (!hasStats) return Super.MenuEvent(mkey, fromcontroller);

    int n = CurrentSectionCount();

    switch (mkey) {
      case Menu.MKEY_Left:
        if (n > 0) {
          SetCursor((GetCursor() - 1 + n) % n);
          MenuSound("menu/cursor");
        }
        return true;
      case Menu.MKEY_Right:
        if (n > 0) {
          SetCursor((GetCursor() + 1) % n);
          MenuSound("menu/cursor");
        }
        return true;
      case Menu.MKEY_Up:
        TuneFocused(1);
        return true;
      case Menu.MKEY_Down:
        TuneFocused(-1);
        return true;
      case Menu.MKEY_Enter:
        ToggleFocused();
        return true;
      case Menu.MKEY_PageUp:
        focusSection = (focusSection + 2) % 3;
        MenuSound("menu/cursor");
        return true;
      case Menu.MKEY_PageDown:
        focusSection = (focusSection + 1) % 3;
        MenuSound("menu/cursor");
        return true;
      default:
        return Super.MenuEvent(mkey, fromcontroller);
    }
  }
}
