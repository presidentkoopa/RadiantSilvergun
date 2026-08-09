// =====================================================================
// RS_TierPalette -- THE tier colour table. There is exactly one.
// ---------------------------------------------------------------------
// Added 2026-08-08 at the owner's order ("i just need each tier to be a
// color unique to itself... that kinda follow the classic WoW scheme").
//
// WHY THIS FILE EXISTS. Four independent tier ladders had grown up in
// the tree and drifted apart:
//
//   RS_PanelController.TierGlow()    Color, one set of RGB
//   RS_BBWeaponCard.TierRGB()        Color, a NEAR-COPY with different
//                                    numbers -- same tier, different hue
//   RS_UIStyle.TierColor()           Font.CR_ constants
//   RS_WheelInfo.RS_TierColorTag()   "\c[...]" escape strings
//
// Nothing kept them in step, so the same weapon could read Advanced-blue
// on one surface and Advanced-purple on another. All four now forward to
// the three functions below and cannot disagree again. If a fifth surface
// ever needs a tier colour, it calls this -- it does not write a table.
//
// THE LADDER. Deliberately the classic loot-rarity progression, because
// the player already knows how to read it without being taught:
//
//   Cursed     crimson    -- the only "this is bad" colour on the ladder
//   Trash      olive      -- drab, reads as junk at a glance
//   Basic      white
//   Common     green
//   Uncommon   blue
//   Advanced   purple
//   Designer   yellow
//   Prototype  cyan
//
// KNOWN NEIGHBOURS, checked before this was written, NOT collisions:
//   * the Elite pentagram is pure red (255,0,0) in RS_Elite.zs -- Cursed
//     is crimson (200,30,55), a different hue, and Cursed's drop weight
//     is zero anyway. RS_Elite.zs is under systems/monster and was read,
//     never touched.
//   * Condition's green/yellow/red bands are STAT-STATE colours, not tier
//     colours, and never share a row with a tier swatch.
// =====================================================================

class RS_TierPalette
{
	// Full-colour form -- billboards, panels, glows, anything drawing
	// its own pixels.
	static Color RGB(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return Color(255, 200,  30,  55);
			case VRT_Trash:     return Color(255, 112, 106,  50);
			case VRT_Basic:     return Color(255, 235, 235, 240);
			case VRT_Common:    return Color(255,  40, 255,  60);
			case VRT_Uncommon:  return Color(255,  60, 120, 255);
			case VRT_Advanced:  return Color(255, 180,  40, 255);
			case VRT_Designer:  return Color(255, 255, 225,  55);
			case VRT_Prototype: return Color(255,  40, 255, 255);
		}
		return Color(255, 235, 235, 240);
	}

	// Font.CR_ form -- DrawText and anything taking a translation index.
	static int FontColor(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return Font.CR_RED;
			case VRT_Trash:     return Font.CR_OLIVE;
			case VRT_Basic:     return Font.CR_WHITE;
			case VRT_Common:    return Font.CR_GREEN;
			case VRT_Uncommon:  return Font.CR_BLUE;
			case VRT_Advanced:  return Font.CR_PURPLE;
			case VRT_Designer:  return Font.CR_YELLOW;
			case VRT_Prototype: return Font.CR_CYAN;
		}
		return Font.CR_WHITE;
	}

	// Escape-code form -- for colouring a run inside a larger string.
	static string Tag(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return "\c[Red]";
			case VRT_Trash:     return "\c[Olive]";
			case VRT_Basic:     return "\c[White]";
			case VRT_Common:    return "\c[Green]";
			case VRT_Uncommon:  return "\c[Blue]";
			case VRT_Advanced:  return "\c[Purple]";
			case VRT_Designer:  return "\c[Yellow]";
			case VRT_Prototype: return "\c[Cyan]";
		}
		return "\c[White]";
	}
}
