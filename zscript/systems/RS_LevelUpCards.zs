// RS-flavored presentation layer for GunBonsai's level-up picker.
//
// This hooks in by having MENUDEF repoint GunBonsaiWeaponLevelUpMenu /
// GunBonsaiPlayerLevelUpMenu at the classes below instead of TFLV's own
// menu classes. GunBonsai's own candidate generation, XP, and upgrade
// application are completely untouched -- this only replaces what draws
// the picker. Every candidate is read straight from giver.candidates via
// GetName()/GetDesc(), so any new GunBonsai upgrade (upstream or
// RS_Upgrade_*) slots in automatically with zero changes here.

class RS_Menu_LevelUpCardsBase : OptionMenu {
  const RS_MAX_CARDS = 8;

  array<string> cardNames;
  array<string> cardDescs;
  int cursor;
  string titleText;

  override void Init(Menu parent, OptionMenuDescriptor desc) {
    Super.Init(parent, desc);
    cursor = 0;
    cardNames.Clear();
    cardDescs.Clear();
    titleText = "";
    PopulateCandidates();
  }

  virtual void PopulateCandidates() {}

  int NumCards() {
    return min(cardNames.size(), RS_MAX_CARDS);
  }

  int GridCols() {
    int n = NumCards();
    return (n <= 4) ? n : 4;
  }

  int GridRows() {
    return (NumCards() <= 4) ? 1 : 2;
  }

  // Slot-indexed, not meaning-indexed -- affix cards are deliberately not
  // colour-coded by element, this is just visual variety per card position.
  uint CardAccent(int i) {
    switch (i % 8) {
      case 0: return 0xFFFF8030; // orange
      case 1: return 0xFF40C0FF; // cyan
      case 2: return 0xFFFF60C0; // magenta
      case 3: return 0xFF40FF60; // green
      case 4: return 0xFFFFD040; // yellow
      case 5: return 0xFFC060FF; // purple
      case 6: return 0xFFFF4040; // red
      default: return 0xFF40C0A0; // teal
    }
  }

  override void Drawer() {
    int fbw = Screen.GetWidth();
    int fbh = Screen.GetHeight();

    RS_UIKit.FillRect(0, 0, fbw, fbh, 0xFF000000, 0.45, fbw, fbh);

    Font titleFont = Font.FindFont("BigFont");
    if (!titleFont) titleFont = Font.FindFont("NewSmallFont");
    RS_UIKit.DrawTextCentered(titleFont, titleText, fbw/2, int(fbh*0.12), 0xFFFFFFFF, fbw, fbh);

    int n = NumCards();
    if (n <= 0) return;

    int cols = GridCols();
    int rows = GridRows();

    int marginX = int(fbw * 0.05);
    int gridTop = int(fbh * 0.30);
    int gridBottom = int(fbh * 0.85);
    int gutter = int(fbw * 0.012);

    int gridW = fbw - marginX*2;
    int gridH = gridBottom - gridTop;
    int cardW = (gridW - gutter*(cols-1)) / cols;
    int cardH = (rows == 1) ? gridH : (gridH - gutter) / 2;

    Font bodyFont = Font.FindFont("NewSmallFont");
    int lh = bodyFont.GetHeight() + 2;

    for (int i = 0; i < n; ++i) {
      int col = i % cols;
      int row = i / cols;
      int x = marginX + col * (cardW + gutter);
      int y = gridTop + row * (cardH + gutter);
      uint accent = CardAccent(i);
      bool sel = (i == cursor);

      RS_UIKit.FillRect(x, y, cardW, cardH, 0xFF0C0A18, 0.82, fbw, fbh);
      RS_UIKit.BorderRect(x, y, cardW, cardH, sel ? 4 : 2, accent, fbw, fbh);

      // Measure both blocks before drawing so the whole text stack can be
      // centered in the card's content area instead of pinned to the top
      // with dead space above the chip.
      array<string> titleLines;
      RS_UIKit.WrapText(bodyFont, cardNames[i], cardW - 24, titleLines);
      array<string> descLines;
      RS_UIKit.WrapText(bodyFont, cardDescs[i], cardW - 24, descLines);

      int chipSize = max(20, int(cardH * 0.14));
      int contentTop = y + 12;
      int contentBottom = y + cardH - chipSize - 16;
      int blockH = titleLines.size()*lh + (descLines.size() > 0 ? int(lh*0.5) : 0) + descLines.size()*lh;
      int textY = contentTop + max(0, (contentBottom - contentTop - blockH) / 2);

      for (int L = 0; L < titleLines.size(); ++L) {
        RS_UIKit.DrawTextAt(bodyFont, titleLines[L], x + 12, textY + L*lh, accent, fbw, fbh);
      }
      int descY = textY + titleLines.size()*lh + int(lh*0.5);
      for (int L = 0; L < descLines.size(); ++L) {
        RS_UIKit.DrawTextAt(bodyFont, descLines[L], x + 12, descY + L*lh, 0xFFE6E6E6, fbw, fbh);
      }
      int chipX = x + 8;
      int chipY = y + cardH - chipSize - 8;
      RS_UIKit.FillRect(chipX, chipY, chipSize, chipSize, accent, 0.25, fbw, fbh);
      RS_UIKit.BorderRect(chipX, chipY, chipSize, chipSize, 2, accent, fbw, fbh);
      RS_UIKit.DrawTextCentered(bodyFont, string.format("%d", i+1), chipX + chipSize/2, chipY + chipSize/2 - lh/2, 0xFFFFFFFF, fbw, fbh);
    }

    RS_UIKit.DrawTextCentered(bodyFont, "MOVE to choose • SELECT to pick", fbw/2, int(fbh*0.92), 0xFFC8C8C8, fbw, fbh);
  }

  void ChooseIndex(int idx) {
    EventHandler.SendNetworkEvent("bonsai-choose-level-up-option", idx);
    Close();
  }

  override bool MenuEvent(int mkey, bool fromcontroller) {
    int n = NumCards();
    if (n <= 0) return Super.MenuEvent(mkey, fromcontroller);

    int cols = GridCols();
    int rows = GridRows();

    switch (mkey) {
      case Menu.MKEY_Left:
        cursor = (cursor - 1 + n) % n;
        MenuSound("menu/cursor");
        return true;
      case Menu.MKEY_Right:
        cursor = (cursor + 1) % n;
        MenuSound("menu/cursor");
        return true;
      case Menu.MKEY_Up:
        if (rows > 1 && cursor - cols >= 0) {
          cursor -= cols;
          MenuSound("menu/cursor");
        }
        return true;
      case Menu.MKEY_Down:
        if (rows > 1 && cursor + cols < n) {
          cursor += cols;
          MenuSound("menu/cursor");
        }
        return true;
      case Menu.MKEY_Enter:
        MenuSound("menu/choose");
        ChooseIndex(cursor);
        return true;
      case Menu.MKEY_Back:
        EventHandler.SendNetworkEvent("bonsai-choose-level-up-option", -1);
        Close();
        return true;
      default:
        return Super.MenuEvent(mkey, fromcontroller);
    }
  }
}

class RS_Menu_WeaponLevelUpCards : RS_Menu_LevelUpCardsBase {
  override void PopulateCandidates() {
    let stats = TFLV_EventHandler.GetConsolePlayerStats();
    let giver = TFLV_WeaponUpgradeGiver(stats.currentEffectGiver);
    titleText = giver.wielded.wpn.GetTag();
    int n = min(giver.candidates.size(), RS_MAX_CARDS);
    for (int i = 0; i < n; ++i) {
      cardNames.Push(giver.candidates[i].GetName());
      cardDescs.Push(giver.candidates[i].GetDesc());
    }
  }
}

class RS_Menu_PlayerLevelUpCards : RS_Menu_LevelUpCardsBase {
  override void PopulateCandidates() {
    let stats = TFLV_EventHandler.GetConsolePlayerStats();
    let giver = TFLV_PlayerUpgradeGiver(stats.currentEffectGiver);
    titleText = StringTable.Localize("$TFLV_MENU_PLAYER_LEVELUP_TITLE");
    int n = min(giver.candidates.size(), RS_MAX_CARDS);
    for (int i = 0; i < n; ++i) {
      cardNames.Push(giver.candidates[i].GetName());
      cardDescs.Push(giver.candidates[i].GetDesc());
    }
  }
}
