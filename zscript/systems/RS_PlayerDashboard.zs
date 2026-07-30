// RS-original "Player" dashboard -- image 3's reference, scoped down.
// Top area shows a main-vs-offhand comparison -- the one idea from the
// menu-design postmortem that nothing else in this project answers
// ("which of these two do I keep" is the constant dual-wield question).
// The functional part is the bottom: select and evaluate player-level
// GunBonsai attributes (not weapon-specific -- that's RS_StatusCards.zs's
// WEAPON/OFFHAND sections). Same toggle-grid + description panel pattern
// as everywhere else, reading/writing through GunBonsai's real player
// upgrade bag (bag_index 0), nothing invented.

class RS_Menu_PlayerDashboard : OptionMenu {
  array<string> names;
  array<bool> enab;
  array<int> levels;
  array<string> descs;
  int cursor;
  bool hasStats;
  int playerLevel;
  uint playerXP, playerMaxXP;
  RS_Weapon mainWep;
  RS_Weapon offhandWep;

  override void Init(Menu parent, OptionMenuDescriptor desc) {
    Super.Init(parent, desc);
    cursor = 0;
  }

  void LoadData() {
    names.Clear();
    enab.Clear();
    levels.Clear();
    descs.Clear();
    hasStats = false;
    mainWep = null;
    offhandWep = null;

    let pawn = players[consoleplayer].mo;
    if (pawn && pawn.player) {
      mainWep = RS_Weapon(pawn.player.ReadyWeapon);
      offhandWep = RS_Weapon(pawn.player.OffhandWeapon);
    }

    let pps = TFLV_EventHandler.GetConsolePlayerStats();
    if (!pps) return;
    hasStats = true;

    playerLevel = pps.level;
    playerXP = pps.XP;
    playerMaxXP = bonsai_gun_levels_per_player_level;

    for (int i = 0; i < pps.upgrades.upgrades.size(); ++i) {
      let u = pps.upgrades.upgrades[i];
      names.Push(u.GetName());
      enab.Push(u.enabled);
      levels.Push(u.level);
      descs.Push(u.GetDesc());
    }
    cursor = clamp(cursor, 0, max(0, names.size() - 1));
  }

  static int DPS(RS_Weapon wep) {
    if (!wep) return -1;
    return wep.DamagePerShot * max(1, wep.PelletCount) * max(0, wep.RateOfFire);
  }

  void DrawHandPanel(RS_Weapon wep, bool offhand, bool stronger,
      int x, int y, int w, int h, Font bodyFont, Font nameFont, int lh, int fbw, int fbh) {
    uint handColor = offhand ? 0xFFF5AA32 : 0xFF8CC8F0;
    RS_UIKit.FillRect(x, y, w, h, 0xFF0A0814, 0.7, fbw, fbh);
    RS_UIKit.BorderRect(x, y, w, h, stronger ? 3 : 2, handColor, fbw, fbh);

    RS_UIKit.DrawTextAt(bodyFont, offhand ? "OFFHAND" : "MAIN", x + 10, y + 8, handColor, fbw, fbh);
    if (stronger) {
      string tag = "STRONGER";
      RS_UIKit.DrawTextAt(bodyFont, tag, x + w - 10 - bodyFont.StringWidth(tag), y + 8, 0xFF50E070, fbw, fbh);
    }

    if (!wep) {
      RS_UIKit.DrawTextCentered(bodyFont, "(empty)", x + w/2, y + h/2 - lh/2, 0xFF909090, fbw, fbh);
      return;
    }

    int iconSize = int(h * 0.4);
    int iconY = y + 8 + lh + 4;
    RS_UIKit.DrawIconFit(RS_Menu_WeaponSelect.IconFor(wep), x + 10, iconY, iconSize, iconSize, fbw, fbh);

    int textX = x + 20 + iconSize;
    int ty = iconY;
    RS_UIKit.DrawTextAt(nameFont, wep.GetTag(), textX, ty, 0xFFFFFFFF, fbw, fbh);
    ty += int(lh * 1.6);
    RS_UIKit.DrawTextAt(bodyFont, RS_Menu_WeaponSelect.TierName(wep.Tier),
      textX, ty, RS_Menu_WeaponSelect.TierAccent(wep.Tier), fbw, fbh);
    ty += lh;
    RS_UIKit.DrawTextAt(bodyFont, string.format("DPS %d", DPS(wep)), textX, ty, 0xFF40FF60, fbw, fbh);

    int statY = iconY + iconSize + int(lh * 0.5);
    RS_UIKit.DrawTextAt(bodyFont, string.format("Condition %.0f%%", wep.Condition), x + 10, statY, 0xFF40C0A0, fbw, fbh);
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

    RS_UIKit.DrawTextCentered(titleFont, "PLAYER", fbw/2, int(fbh*0.03), 0xFFFFFFFF, fbw, fbh);

    int marginX = int(fbw * 0.06);
    int panelW = fbw - marginX*2;

    int compareY = int(fbh * 0.10);
    int compareH = int(fbh * 0.38);
    int halfW = int(panelW * 0.485);

    int mainDPS = DPS(mainWep);
    int offDPS = DPS(offhandWep);
    bool mainStronger = mainWep && offhandWep && mainDPS > offDPS;
    bool offStronger = mainWep && offhandWep && offDPS > mainDPS;

    DrawHandPanel(mainWep, false, mainStronger, marginX, compareY, halfW, compareH, bodyFont, titleFont, lh, fbw, fbh);
    DrawHandPanel(offhandWep, true, offStronger, marginX + panelW - halfW, compareY, halfW, compareH, bodyFont, titleFont, lh, fbw, fbh);

    if (!hasStats) {
      RS_UIKit.DrawTextCentered(bodyFont, "No stats available.", fbw/2, int(fbh*0.6), 0xFFFF6060, fbw, fbh);
      return;
    }

    int y = compareY + compareH + int(fbh * 0.03);
    RS_UIKit.DrawTextAt(bodyFont, "PLAYER ATTRIBUTES", marginX, y, 0xFFFFD040, fbw, fbh);
    RS_UIKit.DrawTextAt(bodyFont,
      string.format("Level %d   XP %d/%d", playerLevel, playerXP, playerMaxXP),
      marginX, y + lh, 0xFFC8C8C8, fbw, fbh);
    y += lh*2 + 6;

    int boxSize = int(fbh * 0.06);
    int gutter = int(fbw * 0.008);
    int maxCols = max(1, panelW / (boxSize + gutter));

    if (names.size() > 0) {
      y = RS_UIKit.DrawToggleGrid(names, enab, levels, cursor, true,
        marginX, y, panelW, boxSize, gutter, maxCols, bodyFont, fbw, fbh);
    } else {
      RS_UIKit.DrawTextAt(bodyFont, "(no player attributes yet -- level up to gain some)", marginX, y, 0xFF909090, fbw, fbh);
      y += lh;
    }
    y += int(fbh * 0.02);

    int descH = int(fbh * 0.14);
    RS_UIKit.FillRect(marginX, y, panelW, descH, 0xFF0C0A18, 0.85, fbw, fbh);
    RS_UIKit.BorderRect(marginX, y, panelW, descH, 2, 0xFF808080, fbw, fbh);

    if (cursor >= 0 && cursor < names.size()) {
      RS_UIKit.DrawTextAt(bodyFont, string.format("%s (Lv %d)", names[cursor], levels[cursor]), marginX + 10, y + 8, 0xFFFFD040, fbw, fbh);
      RS_UIKit.DrawWrapped(bodyFont, descs[cursor], marginX + 10, y + 8 + lh, panelW - 20, 0xFFE6E6E6, fbw, fbh);
    } else {
      RS_UIKit.DrawTextAt(bodyFont, "Highlight an attribute to read its full description here.", marginX + 10, y + 8, 0xFF909090, fbw, fbh);
    }

    RS_UIKit.DrawTextCentered(bodyFont,
      "<- -> select   up/down level   ENTER toggle",
      fbw/2, int(fbh*0.95), 0xFFC8C8C8, fbw, fbh);
  }

  void ToggleFocused() {
    if (cursor < 0 || cursor >= names.size()) return;
    MenuSound("menu/choose");
    EventHandler.SendNetworkEvent("bonsai-toggle-upgrade", 0, cursor);
  }

  void TuneFocused(int amount) {
    if (cursor < 0 || cursor >= names.size()) return;
    MenuSound("menu/cursor");
    EventHandler.SendNetworkEvent("bonsai-tune-upgrade", 0, cursor, amount);
  }

  override bool MenuEvent(int mkey, bool fromcontroller) {
    if (!hasStats || names.size() <= 0) return Super.MenuEvent(mkey, fromcontroller);

    switch (mkey) {
      case Menu.MKEY_Left:
        cursor = (cursor - 1 + names.size()) % names.size();
        MenuSound("menu/cursor");
        return true;
      case Menu.MKEY_Right:
        cursor = (cursor + 1) % names.size();
        MenuSound("menu/cursor");
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
      default:
        return Super.MenuEvent(mkey, fromcontroller);
    }
  }
}
