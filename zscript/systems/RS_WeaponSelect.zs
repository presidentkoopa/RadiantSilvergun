// RS-original "Weapon Selection" comparison screen -- not a GunBonsai
// retarget, there is no upstream equivalent. Answers the real question
// from docs/rs_02_weaponselect_v01.txt Part 5: a Dual Revolvers player can
// own up to three near-identical rolled revolvers per hand, differing only
// in invisible numbers, with nothing today to compare them by except a
// text status screen.
//
// Both MAIN and OFFHAND cards are selectable -- Enter on a MAIN card sets
// PendingWeapon (normal weapon switch); Enter on an OFFHAND card sets
// player.OffhandWeapon directly (no engine PendingWeapon-equivalent exists
// for the offhand, it's a fork-level construct). Both route through
// RS_MenuActionHandler, same "menu netevent -> play scope" pattern as
// every other RS_ menu action.
//
// This is deliberately NOT the general hand-registry system from rs_02
// Part 2 -- it only handles picking among weapons already owned. What it
// does NOT solve: a fresh floor pickup of an offhand-flagged weapon still
// unconditionally overwrites whatever was deliberately chosen here
// (RS_Weapon.zs's AttachToOwner, unchanged). Arbitrating that is separate,
// larger work; this is the narrow "choose from what I'm carrying" case.
//
// Upgrade management (toggle/tune) is deliberately NOT duplicated here --
// that's RS_StatusCards.zs's job, which already does it against the
// currently-equipped weapon via GunBonsai's real (current-weapon-only)
// netevents. This screen shows a read-only upgrade summary per weapon
// instead of reinventing a per-arbitrary-weapon toggle protocol that
// doesn't exist server-side (see rs_02 Part 3J, J6).

class RS_Menu_WeaponSelect : OptionMenu {
  array<RS_Weapon> mainWeapons;
  array<RS_Weapon> offhandWeapons;
  int focusSection; // 0 = main, 1 = offhand
  int cursorMain, cursorOffhand;

  override void Init(Menu parent, OptionMenuDescriptor desc) {
    Super.Init(parent, desc);
    focusSection = 0;
    cursorMain = 0;
    cursorOffhand = 0;
    LoadWeapons();
  }

  void LoadWeapons() {
    mainWeapons.Clear();
    offhandWeapons.Clear();
    let pawn = players[consoleplayer].mo;
    if (!pawn) return;
    for (Inventory item = pawn.inv; item != null; item = item.inv) {
      let wep = RS_Weapon(item);
      if (!wep) continue;
      if (wep.bOffhandWeapon) offhandWeapons.Push(wep);
      else mainWeapons.Push(wep);
    }
    cursorMain = clamp(cursorMain, 0, max(0, mainWeapons.size() - 1));
    cursorOffhand = clamp(cursorOffhand, 0, max(0, offhandWeapons.size() - 1));
  }

  // One icon per archetype, not per identity -- matches the icon set as
  // provided. Most-specific substring checked first (PlasmaRifle before
  // Rifle, SuperShotgun before Shotgun) so a generic match can't shadow it.
  static TextureID IconFor(RS_Weapon wep) {
    string cls = wep.GetClassName();
    string lump = "";
    if (cls.IndexOf("PlasmaRifle") >= 0) lump = "PLASA0";
    else if (cls.IndexOf("SuperShotgun") >= 0) lump = "SGN2A0";
    else if (cls.IndexOf("Shotgun") >= 0) lump = "SHOTA0";
    else if (cls.IndexOf("Revolver") >= 0) lump = "REVOQ0";
    else if (cls.IndexOf("SMG") >= 0) lump = "SMGZA0";
    else if (cls.IndexOf("Rifle") >= 0) lump = "RIFPA0"; // VR_Rifle, RS_VP_ARifle
    else if (cls.IndexOf("Pistol") >= 0) lump = "PISTA0";
    else if (cls.IndexOf("Chaingun") >= 0) lump = "MGUNA0";
    else if (cls.IndexOf("RocketLauncher") >= 0) lump = "LAUNA0";
    else if (cls.IndexOf("BFG9000") >= 0) lump = "BFUGA0";
    else if (cls.IndexOf("Chainsaw") >= 0) lump = "CSAWA0";
    if (lump == "") { TextureID none; return none; }
    return TexMan.CheckForTexture(lump, TexMan.Type_Any);
  }

  // Locked palette (docs/HANDOFF_3.md) -- these colours are fixed per stat
  // everywhere they appear, unlike affix cards which are colour-neutral.
  static uint StatColor(string stat) {
    if (stat == "DMG") return 0xFFFF4040;
    if (stat == "RoF") return 0xFFFFD040;
    if (stat == "DPS") return 0xFF40FF60;
    if (stat == "Acc") return 0xFFFF8030;
    if (stat == "Vel") return 0xFFC060FF;
    if (stat == "Cyl" || stat == "Cap") return 0xFF40FFF0;
    if (stat == "Pellets") return 0xFF4090FF;
    if (stat == "BonSoc") return 0xFFFF6060;
    if (stat == "CND") return 0xFF40C0A0;
    if (stat == "Crit") return 0xFFFFF040;
    if (stat == "TimeBtwn") return 0xFFB0B0FF;
    return 0xFFFFFFFF;
  }

  static uint TierAccent(EVR_Tier t) {
    switch (t) {
      case VRT_Cursed:    return 0xFF902040;
      case VRT_Trash:     return 0xFF707070;
      case VRT_Basic:     return 0xFFC0C0C0;
      case VRT_Common:    return 0xFF60D060;
      case VRT_Uncommon:  return 0xFF40C0FF;
      case VRT_Advanced:  return 0xFFC060FF;
      case VRT_Designer:  return 0xFFFFD040;
      case VRT_Prototype: return 0xFFFF6030;
      default:            return 0xFFFFFFFF;
    }
  }

  static string TierName(EVR_Tier t) {
    switch (t) {
      case VRT_Cursed:    return "Cursed";
      case VRT_Trash:     return "Trash";
      case VRT_Basic:     return "Basic";
      case VRT_Common:    return "Common";
      case VRT_Uncommon:  return "Uncommon";
      case VRT_Advanced:  return "Advanced";
      case VRT_Designer:  return "Designer";
      case VRT_Prototype: return "Prototype";
      default:            return "?";
    }
  }

  bool IsEquipped(RS_Weapon wep, bool offhand) {
    let pawn = players[consoleplayer].mo;
    if (!pawn || !pawn.player) return false;
    return offhand ? (pawn.player.OffhandWeapon == wep) : (pawn.player.ReadyWeapon == wep);
  }

  void DrawIconCard(RS_Weapon wep, int x, int y, int w, int h, bool selected, bool equipped, Font fnt, int fbw, int fbh) {
    uint accent = TierAccent(wep.Tier);
    RS_UIKit.FillRect(x, y, w, h, 0xFF0C0A18, 0.85, fbw, fbh);
    RS_UIKit.BorderRect(x, y, w, h, selected ? 4 : 2, accent, fbw, fbh);

    int iconBoxH = int(h * 0.62);
    RS_UIKit.DrawIconFit(IconFor(wep), x + 4, y + 4, w - 8, iconBoxH - 4, fbw, fbh);

    Font labelFont = fnt;
    RS_UIKit.DrawWrapped(labelFont, wep.GetTag(), x + 4, y + iconBoxH + 2, w - 8, 0xFFFFFFFF, fbw, fbh);

    if (equipped) {
      RS_UIKit.FillRect(x + 2, y + 2, 8, 8, 0xFF50E070, 1.0, fbw, fbh);
    }
  }

  void DrawStatRow(string label, string value, int x, int y, int colW, Font fnt, int fbw, int fbh) {
    RS_UIKit.DrawTextAt(fnt, label, x, y, StatColor(label), fbw, fbh);
    RS_UIKit.DrawTextAt(fnt, value, x + colW, y, 0xFFE6E6E6, fbw, fbh);
  }

  // Fixed 4-column, 3-row grid -- every stat gets its own cell, values
  // always line up regardless of label length. Replaces the old
  // hand-placed row-by-row calls, which used one column width for labels
  // of very different lengths ("DMG" vs "Pellets") and drifted out of
  // alignment against the icon block above it.
  void DrawStatGrid(RS_Weapon wep, int x, int y, int w, Font fnt, int fbw, int fbh) {
    int dps = wep.DamagePerShot * max(1, wep.PelletCount) * max(0, wep.RateOfFire);
    string loaded = "--";
    if (wep.AmmoType2)
      loaded = string.format("%d/%d", wep.owner ? wep.owner.CountInv(wep.AmmoType2) : 0, wep.Capacity);
    // Can't call wep.GetTimeBetweenShots() here -- it's a play-scope
    // function (like the rest of RS_Weapon's firing logic) and this menu
    // draws in ui scope, which GZDoom keeps strictly separate. Reading
    // the plain RateOfFire field it's built from is fine (only function
    // calls are scope-restricted, not member reads) -- same math
    // (1.0 / RateOfFire), just done locally instead of through the call.
    double tbs = 1.0 / max(1, wep.RateOfFire);

    // label/value pairs, read order matches the reference layout: row of
    // damage/rate stats, row of capacity/precision stats, row of
    // condition/timing stats. Array + Push, not a fixed-size array
    // initializer -- this file already uses Array<string>.Push
    // everywhere else (see the upgrade-summary block below), so it's a
    // pattern already proven to compile on this engine rather than a
    // second untested guess.
    array<string> labels;
    array<string> values;
    labels.Push("DMG");     values.Push(string.format("%d", wep.DamagePerShot));
    labels.Push("RoF");     values.Push(string.format("%d/s", wep.RateOfFire));
    labels.Push("DPS");     values.Push(string.format("%d", dps));
    labels.Push("Acc");     values.Push(string.format("%.0f%%", wep.Accuracy));
    labels.Push("Cap");     values.Push(loaded);
    labels.Push("Crit");    values.Push(string.format("%.0f%%", wep.CritChance * 100.0));
    labels.Push("Pellets"); values.Push(string.format("%d", max(1, wep.PelletCount)));
    labels.Push("Vel");     values.Push(string.format("%.0f", wep.Velocity));
    labels.Push("BonSoc");  values.Push(string.format("%d", wep.GunBonaiSockets));
    labels.Push("TimeBtwn"); values.Push(string.format("%.2fs", tbs));
    labels.Push("CND");     values.Push(string.format("%.0f%%", wep.Condition));

    int cols = 4;
    int colW = w / cols;
    int rowGap = int((fnt.GetHeight() + 2) * 1.6);
    for (int i = 0; i < labels.size(); ++i) {
      int row = i / cols;
      int col = i % cols;
      int cx = x + col * colW;
      int cy = y + row * rowGap;
      DrawStatRow(labels[i], values[i], cx, cy, int(colW * 0.42), fnt, fbw, fbh);
    }
  }

  void DrawStatPanel(string sectionLabel, array<RS_Weapon> list, int cursor, bool offhand,
      int x, int y, int w, int h, Font bodyFont, Font nameFont, int lh, int fbw, int fbh) {
    RS_UIKit.FillRect(x, y, w, h, 0xFF0A0814, 0.85, fbw, fbh);
    RS_UIKit.BorderRect(x, y, w, h, 2, 0xFF505050, fbw, fbh);

    int pad = int(w * 0.03);

    if (list.size() <= 0 || cursor < 0 || cursor >= list.size()) {
      RS_UIKit.DrawTextCentered(bodyFont, sectionLabel .. ": none owned", x + w/2, y + h/2 - lh/2, 0xFF909090, fbw, fbh);
      return;
    }

    let wep = list[cursor];
    bool equipped = IsEquipped(wep, offhand);
    let stats = TFLV_EventHandler.GetConsolePlayerStats();
    let info = stats ? stats.GetInfoFor(wep) : null;

    // Icon lives in its own fixed box in the top-left corner. Nothing
    // else is allowed to draw inside iconBoxW x iconBoxH -- that's what
    // was causing the name/tier text to overlap the icon before: text
    // started at the icon's right edge but the icon's actual drawn
    // height (DrawIconFit centers and scales it) wasn't reserved as
    // dead space for anything below it.
    int iconBoxW = int(w * 0.20);
    int iconBoxH = iconBoxW;
    RS_UIKit.FillRect(x + pad, y + pad, iconBoxW, iconBoxH, 0xFF000000, 0.5, fbw, fbh);
    RS_UIKit.BorderRect(x + pad, y + pad, iconBoxW, iconBoxH, 1, 0xFF404040, fbw, fbh);
    RS_UIKit.DrawIconFit(IconFor(wep), x + pad + 2, y + pad + 2, iconBoxW - 4, iconBoxH - 4, fbw, fbh);

    int textX = x + pad*2 + iconBoxW;
    int ty = y + pad;
    RS_UIKit.DrawTextAt(nameFont, wep.GetTag(), textX, ty, 0xFFFFFFFF, fbw, fbh);
    ty += int(lh * 1.4);

    if (equipped) {
      RS_UIKit.DrawTextAt(bodyFont, "[EQUIPPED]", textX, ty, 0xFF50E070, fbw, fbh);
      ty += lh;
    }

    RS_UIKit.DrawTextAt(bodyFont, TierName(wep.Tier), textX, ty, TierAccent(wep.Tier), fbw, fbh);
    ty += lh;
    if (info) {
      RS_UIKit.DrawTextAt(bodyFont, string.format("Lv %d   XP %d/%d", info.level, int(info.XP), int(info.maxXP)), textX, ty, 0xFFC8C8C8, fbw, fbh);
    } else {
      RS_UIKit.DrawTextAt(bodyFont, "(fire at an enemy to track)", textX, ty, 0xFF909090, fbw, fbh);
    }

    // Stat grid starts BELOW the taller of the icon box or the name/tier
    // text block, with real clearance -- the old code took max() of the
    // two but then added almost no gap, so the first stat row still
    // clipped the icon's bottom edge on some weapon names.
    int sy = y + pad + max(iconBoxH, ty - y + lh) + int(h * 0.05);
    DrawStatGrid(wep, x + pad, sy, w - pad*2, bodyFont, fbw, fbh);
    int rowGap = int(lh * 1.6);
    sy += rowGap * 3;

    // Read-only upgrade summary -- see file header for why this doesn't
    // toggle here. Boxes are display only, no cursor, no selected state.
    if (info && info.upgrades.upgrades.size() > 0) {
      sy += int(lh * 0.5);
      RS_UIKit.DrawTextAt(bodyFont, string.format("Upgrades (%d):", info.upgrades.upgrades.size()), x + pad, sy, 0xFFC8C8C8, fbw, fbh);
      sy += lh;
      array<string> names;
      array<bool> enab;
      array<int> lvls;
      for (int i = 0; i < info.upgrades.upgrades.size(); ++i) {
        names.Push(info.upgrades.upgrades[i].GetName());
        enab.Push(info.upgrades.upgrades[i].enabled);
        lvls.Push(info.upgrades.upgrades[i].level);
      }
      int boxSize = int(lh * 1.6);
      int maxCols = max(1, (w - pad*2) / (boxSize + 4));
      RS_UIKit.DrawToggleGrid(names, enab, lvls, -1, false, x + pad, sy, w - pad*2, boxSize, 4, maxCols, bodyFont, fbw, fbh);
    }
  }

  override void Drawer() {
    int fbw = Screen.GetWidth();
    int fbh = Screen.GetHeight();

    LoadWeapons();

    RS_UIKit.FillRect(0, 0, fbw, fbh, 0xFF000000, 0.45, fbw, fbh);

    Font titleFont = Font.FindFont("BigFont");
    if (!titleFont) titleFont = Font.FindFont("NewSmallFont");
    Font bodyFont = Font.FindFont("NewSmallFont");
    int lh = bodyFont.GetHeight() + 2;

    RS_UIKit.DrawTextCentered(titleFont, "WEAPON SELECTION", fbw/2, int(fbh*0.03), 0xFFFFFFFF, fbw, fbh);

    int marginX = int(fbw * 0.04);
    int leftW = int(fbw * 0.34);
    int rightX = marginX + leftW + int(fbw * 0.02);
    int rightW = fbw - rightX - marginX;

    int cardW = int(leftW * 0.30);
    int cardH = int(fbh * 0.16);
    int cardGutter = int(fbw * 0.01);
    int listY = int(fbh * 0.11);

    RS_UIKit.DrawTextAt(bodyFont, "MAIN", marginX, listY, 0xFF8CC8F0, fbw, fbh);
    int mainRowY = listY + lh + 4;
    for (int i = 0; i < mainWeapons.size(); ++i) {
      int cx = marginX + i * (cardW + cardGutter);
      DrawIconCard(mainWeapons[i], cx, mainRowY, cardW, cardH,
        focusSection == 0 && i == cursorMain, IsEquipped(mainWeapons[i], false),
        bodyFont, fbw, fbh);
    }

    int offhandLabelY = mainRowY + cardH + int(fbh * 0.03);
    RS_UIKit.DrawTextAt(bodyFont, "OFFHAND", marginX, offhandLabelY, 0xFFF5AA32, fbw, fbh);
    int offhandRowY = offhandLabelY + lh + 4;
    for (int i = 0; i < offhandWeapons.size(); ++i) {
      int cx = marginX + i * (cardW + cardGutter);
      DrawIconCard(offhandWeapons[i], cx, offhandRowY, cardW, cardH,
        focusSection == 1 && i == cursorOffhand, IsEquipped(offhandWeapons[i], true),
        bodyFont, fbw, fbh);
    }

    int panelH = int(fbh * 0.33);
    int panelGutter = int(fbh * 0.015);
    int panelY1 = int(fbh * 0.11);
    int panelY2 = panelY1 + panelH + panelGutter;

    DrawStatPanel("MAIN", mainWeapons, cursorMain, false,
      rightX, panelY1, rightW, panelH, bodyFont, titleFont, lh, fbw, fbh);
    DrawStatPanel("OFFHAND", offhandWeapons, cursorOffhand, true,
      rightX, panelY2, rightW, panelH, bodyFont, titleFont, lh, fbw, fbh);

    RS_UIKit.DrawTextCentered(bodyFont,
      "<- -> select   PGUP/PGDN hand   ENTER equip",
      fbw/2, int(fbh*0.95), 0xFFC8C8C8, fbw, fbh);
  }

  void MoveCursor(int delta) {
    if (focusSection == 0) {
      if (mainWeapons.size() <= 0) return;
      cursorMain = (cursorMain + delta + mainWeapons.size()) % mainWeapons.size();
    } else {
      if (offhandWeapons.size() <= 0) return;
      cursorOffhand = (cursorOffhand + delta + offhandWeapons.size()) % offhandWeapons.size();
    }
    MenuSound("menu/cursor");
  }

  void SelectFocused() {
    if (focusSection == 0) {
      if (cursorMain < 0 || cursorMain >= mainWeapons.size()) return;
      MenuSound("menu/choose");
      EventHandler.SendNetworkEvent("rs_weapon_select_main", cursorMain);
    } else {
      if (cursorOffhand < 0 || cursorOffhand >= offhandWeapons.size()) return;
      MenuSound("menu/choose");
      EventHandler.SendNetworkEvent("rs_weapon_select_offhand", cursorOffhand);
    }
  }

  override bool MenuEvent(int mkey, bool fromcontroller) {
    switch (mkey) {
      case Menu.MKEY_Left:
        MoveCursor(-1);
        return true;
      case Menu.MKEY_Right:
        MoveCursor(1);
        return true;
      case Menu.MKEY_PageUp:
      case Menu.MKEY_PageDown:
        focusSection = 1 - focusSection;
        MenuSound("menu/cursor");
        return true;
      case Menu.MKEY_Enter:
        SelectFocused();
        return true;
      default:
        return Super.MenuEvent(mkey, fromcontroller);
    }
  }
}
