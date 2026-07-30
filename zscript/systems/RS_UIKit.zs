// Shared drawing primitives for RS_Main's custom OptionMenu screens
// (level-up cards, the status/toggle screen, and whatever else replaces a
// stock GunBonsai menu). Plain static utility class, not a Menu -- every
// RS_Menu_* screen calls into this instead of duplicating draw code.
//
// Engine constraints these obey (verified against E:\DXR2 engine source,
// not guessed -- see docs/HANDOFF_3.md and docs/rs_02_weaponselect_v01.txt):
//   - Screen.Dim takes no DTA_* flags, so every filled rect goes through a
//     blitted 1x1(ish) texture (textures/RS_UI/RS_Fill.png) with
//     DTA_FillColor + DTA_AlphaChannel instead.
//   - Every draw call carries DTA_VirtualWidth/Height set to the real
//     screen size, or it lands on a different VR quad.
//   - Text color goes through DTA_Color with a neutral CR_WHITE base font,
//     matching GunBonsai's own HUD.zsc convention exactly.
//   - Colors are plain `uint` ARGB (0xAARRGGBB), not the Color struct --
//     Color's 3-arg constructor defaults alpha to 0, a real footgun.
//   - DrawLineFrame/DrawLine exist natively but take no DTA_* tags, so they
//     can't be VR-routed; borders are four thin fills instead.

class RS_UIKit {
  static TextureID FillTex() {
    return TexMan.CheckForTexture("RS_Fill", TexMan.Type_Any);
  }

  static void FillRect(int x, int y, int w, int h, uint col, double alpha, int fbw, int fbh) {
    Screen.DrawTexture(FillTex(), false, x, y,
      DTA_DestWidth, w, DTA_DestHeight, h,
      DTA_FillColor, col, DTA_AlphaChannel, true, DTA_Alpha, alpha,
      DTA_VirtualWidth, fbw, DTA_VirtualHeight, fbh, DTA_KeepRatio, true);
  }

  static void BorderRect(int x, int y, int w, int h, int thick, uint col, int fbw, int fbh) {
    FillRect(x, y, w, thick, col, 1.0, fbw, fbh);
    FillRect(x, y + h - thick, w, thick, col, 1.0, fbw, fbh);
    FillRect(x, y, thick, h, col, 1.0, fbw, fbh);
    FillRect(x + w - thick, y, thick, h, col, 1.0, fbw, fbh);
  }

  static void DrawTextAt(Font fnt, string text, int x, int y, uint col, int fbw, int fbh) {
    if (!fnt || text == "") return;
    Screen.DrawText(fnt, Font.CR_WHITE, x, y, text,
      DTA_VirtualWidth, fbw, DTA_VirtualHeight, fbh, DTA_KeepRatio, true,
      DTA_Color, col);
  }

  static void DrawTextCentered(Font fnt, string text, int cx, int y, uint col, int fbw, int fbh) {
    if (!fnt || text == "") return;
    int w = fnt.StringWidth(text);
    DrawTextAt(fnt, text, cx - w/2, y, col, fbw, fbh);
  }

  static void WrapText(Font fnt, string text, int maxWidth, out array<string> lines) {
    array<string> words;
    text.Split(words, " ");
    string cur = "";
    for (uint i = 0; i < words.size(); ++i) {
      string test = (cur == "") ? words[i] : cur .. " " .. words[i];
      if (cur != "" && fnt.StringWidth(test) > maxWidth) {
        lines.Push(cur);
        cur = words[i];
      } else {
        cur = test;
      }
    }
    if (cur != "") lines.Push(cur);
  }

  static void DrawWrapped(Font fnt, string text, int x, int y, int maxWidth, uint col, int fbw, int fbh) {
    array<string> lines;
    WrapText(fnt, text, maxWidth, lines);
    int lh = fnt.GetHeight() + 2;
    for (int i = 0; i < lines.size(); ++i) {
      DrawTextAt(fnt, lines[i], x, y + i*lh, col, fbw, fbh);
    }
  }

  // Draws a wrapping row of small toggle boxes for one upgrade bag (used by
  // the status screen's PLAYER/WEAPON/OFFHAND sections). Each box shows the
  // upgrade's level; colour reflects enabled/disabled. Returns the Y just
  // below the drawn grid so the caller can stack sections.
  static int DrawToggleGrid(
      array<string> names, array<bool> enabled, array<int> levels,
      int focusedIndex, bool sectionFocused,
      int x, int y, int w, int boxSize, int gutter, int maxCols,
      Font fnt, int fbw, int fbh) {
    int n = names.size();
    if (n <= 0) return y;
    int cols = max(1, min(maxCols, n));
    int rows = (n + cols - 1) / cols;
    for (int i = 0; i < n; ++i) {
      int col = i % cols;
      int row = i / cols;
      int bx = x + col * (boxSize + gutter);
      int by = y + row * (boxSize + gutter);
      bool sel = sectionFocused && (i == focusedIndex);
      uint accent = enabled[i] ? 0xFF50E070 : 0xFF806858;
      FillRect(bx, by, boxSize, boxSize, enabled[i] ? 0xFF163420 : 0xFF241C18, 0.85, fbw, fbh);
      BorderRect(bx, by, boxSize, boxSize, sel ? 3 : 1, accent, fbw, fbh);
      DrawTextCentered(fnt, string.format("%d", levels[i]), bx + boxSize/2, by + boxSize/2 - fnt.GetHeight()/2, 0xFFFFFFFF, fbw, fbh);
    }
    return y + rows * (boxSize + gutter);
  }

  // Fits a texture into a box, preserving aspect ratio, centered. Used for
  // the weapon icons -- they're irregular sprite-shaped art (a BFG icon is
  // not the same aspect as a pistol icon), not uniform square glyphs.
  static void DrawIconFit(TextureID tex, int x, int y, int boxW, int boxH, int fbw, int fbh, double alpha = 1.0) {
    if (!tex.IsValid()) return;
    Vector2 sz = TexMan.GetScaledSize(tex);
    if (sz.x <= 0 || sz.y <= 0) return;
    double scale = min(double(boxW) / sz.x, double(boxH) / sz.y);
    int dw = int(sz.x * scale);
    int dh = int(sz.y * scale);
    int dx = x + (boxW - dw) / 2;
    int dy = y + (boxH - dh) / 2;
    Screen.DrawTexture(tex, false, dx, dy,
      DTA_DestWidth, dw, DTA_DestHeight, dh, DTA_Alpha, alpha,
      DTA_VirtualWidth, fbw, DTA_VirtualHeight, fbh, DTA_KeepRatio, true);
  }
}
