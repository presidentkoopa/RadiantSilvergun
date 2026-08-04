// =====================================================================
// RS_ScoreHUD -- the arcade readout. Drawing only; every value it shows
// is computed in RS_Score.zs and simply read here.
//
// Layout is dakka's (score number, reward bar under it, life pips over
// it, bonus list below), rebuilt with GZDoom's Screen API instead of
// HudMessage IDs. dakka needed a hand-managed block of message IDs
// (24199-24205 for the bar, 25501+ for lives, 24409+i*2 for bonuses)
// because HudMessage has no other way to address a line it already
// drew; RenderOverlay redraws every frame, so none of that exists here.
//
// Everything positional is a cvar: rs_score_hud_x/y place it anywhere
// on screen as a percentage, rs_score_hud_scale sizes it, and each
// element can be switched off on its own.
// =====================================================================

class RS_ScoreHUD : Object
{
	// Virtual canvas. Same 640x480 dakka used, so its position numbers
	// port directly.
	const VW = 640;
	const VH = 480;

	// The bar's drawn width at 100% scale, in virtual pixels.
	const BARW = 160;
	const BARH = 9;

	ui int CVInt(string name, int def) const
	{
		let c = CVar.GetCVar(name, players[consoleplayer]);
		return c ? c.GetInt() : def;
	}

	ui bool CVBool(string name, bool def) const
	{
		let c = CVar.GetCVar(name, players[consoleplayer]);
		return c ? c.GetBool() : def;
	}

	// Preset palette -- an index rather than a free-text color so the
	// options menu can offer a normal dropdown.
	ui Color PresetColor(int idx) const
	{
		switch (idx)
		{
			case 0:  return 0xFFFFD700; // gold
			case 1:  return 0xFFFFFFFF; // white
			case 2:  return 0xFFFF3030; // red
			case 3:  return 0xFF30FF30; // green
			case 4:  return 0xFF3090FF; // blue
			case 5:  return 0xFFFF30FF; // magenta
			case 6:  return 0xFF30FFFF; // cyan
			case 7:  return 0xFFFF8000; // orange
		}
		return 0xFFFFD700;
	}

	ui int PresetTextColor(int idx) const
	{
		switch (idx)
		{
			case 0:  return Font.CR_GOLD;
			case 1:  return Font.CR_WHITE;
			case 2:  return Font.CR_RED;
			case 3:  return Font.CR_GREEN;
			case 4:  return Font.CR_LIGHTBLUE;
			case 5:  return Font.CR_PURPLE;
			case 6:  return Font.CR_CYAN;
			case 7:  return Font.CR_ORANGE;
		}
		return Font.CR_GOLD;
	}

	// Flavor -> color, so a bonus reads as efficiency/style/daring at a
	// glance the way dakka's DScore_* translations did.
	ui int FlavorColor(int flavor) const
	{
		switch (flavor)
		{
			case RS_ScoreDefs.RS_SF_EFFICIENCY: return Font.CR_BRICK;
			case RS_ScoreDefs.RS_SF_STYLE:      return Font.CR_GREEN;
			case RS_ScoreDefs.RS_SF_DARING:     return Font.CR_ORANGE;
		}
		return Font.CR_WHITE;
	}

	// Virtual -> real conversion. Done by hand rather than with
	// DTA_Virtual* so bars (Screen.Dim, which has no virtual params)
	// and text land on exactly the same grid.
	ui double ScaleFactor() const
	{
		double s = clamp(CVInt("rs_score_hud_scale", 100), 25, 400) / 100.0;
		// Normalize against height so the widget is the same physical
		// size regardless of aspect ratio.
		return (Screen.GetHeight() / double(VH)) * s;
	}

	ui double OriginX() const
	{
		double pct = clamp(CVInt("rs_score_hud_x", 85), 0, 100) / 100.0;
		return Screen.GetWidth() * pct;
	}

	ui double OriginY() const
	{
		double pct = clamp(CVInt("rs_score_hud_y", 10), 0, 100) / 100.0;
		return Screen.GetHeight() * pct;
	}

	// -----------------------------------------------------------------
	ui void Draw(RS_ScorePlayer sp, int threshold, int now)
	{
		if (!sp)
			return;

		double f  = ScaleFactor();
		double ox = OriginX();
		double oy = OriginY();

		if (CVBool("rs_score_hud_showscore", true))
			DrawScoreNumber(sp, ox, oy, f);

		if (CVBool("rs_score_hud_showbar", true))
			DrawRewardBar(sp, threshold, ox, oy, f);

		if (CVBool("rs_score_hud_showlives", true))
			DrawLives(sp, ox, oy, f);

		if (CVBool("rs_score_hud_showbonuses", true))
			DrawBonuses(sp, ox, oy, f, now);

		if (CVBool("rs_score_hud_showspree", true))
			DrawSpree(sp, ox, oy, f, now);
	}

	// -----------------------------------------------------------------
	ui void DrawScoreNumber(RS_ScorePlayer sp, double ox, double oy, double f)
	{
		Font fnt = Font.GetFont("BIGFONT");
		if (!fnt)
			return;

		string txt = String.Format("%d", sp.displayScore);
		int col = PresetTextColor(CVInt("rs_score_hud_color", 0));

		double w = fnt.StringWidth(txt) * f;
		double x = ox - (w * 0.5);
		double y = oy;

		Screen.DrawText(fnt, col, x / f, y / f, txt,
			DTA_ScaleX, f, DTA_ScaleY, f,
			DTA_Alpha, 1.0);

		// The flash pulse: a second pass in white the tic a kill lands,
		// which is dakka's dakka_cl_flashscore, and most of why the
		// number feels like it is being hit rather than incremented.
		if (sp.flashPulse && CVBool("rs_score_hud_flash", true))
		{
			Screen.DrawText(fnt, Font.CR_WHITE, x / f, y / f, txt,
				DTA_ScaleX, f, DTA_ScaleY, f,
				DTA_Alpha, 0.65);
		}
	}

	// -----------------------------------------------------------------
	ui void DrawRewardBar(RS_ScorePlayer sp, int threshold, double ox, double oy, double f)
	{
		if (threshold <= 0)
			return;

		double bw = BARW * f;
		double bh = BARH * f;
		double x  = ox - (bw * 0.5);
		double y  = oy + (26 * f);

		// Which reward is next decides the bar's color, so the player
		// can tell at a glance whether they are filling toward a life
		// or toward ammo regen. dakka swapped the bar graphic for this.
		int mode = CVInt("rs_score_rewardmode", 0);
		bool nextIsLife;

		switch (mode)
		{
			default:
			case 0: nextIsLife = (sp.rewardCount % 2) == 1; break;
			case 1: nextIsLife = (sp.rewardCount % 2) == 0; break;
			case 2: nextIsLife = false; break;
			case 3: nextIsLife = true;  break;
		}

		Color fill = nextIsLife
			? PresetColor(CVInt("rs_score_hud_lifecolor", 3))
			: PresetColor(CVInt("rs_score_hud_barcolor", 4));

		// Frame + track.
		Screen.Dim(0xFF000000, 0.65, int(x - 1 * f), int(y - 1 * f), int(bw + 2 * f), int(bh + 2 * f));
		Screen.Dim(0xFF202020, 0.85, int(x), int(y), int(bw), int(bh));

		int progress = sp.score % threshold;
		double frac = clamp(progress / double(threshold), 0.0, 1.0);

		if (frac > 0)
			Screen.Dim(fill, 0.95, int(x), int(y), int(bw * frac), int(bh));

		// Numeric readout under the bar, for players who want the real
		// number rather than a bar. Off by default -- it is clutter for
		// most people and essential for a few.
		if (CVBool("rs_score_hud_barnumbers", false))
		{
			Font fnt = Font.GetFont("SMALLFONT");
			if (fnt)
			{
				string txt = String.Format("%d / %d", progress, threshold);
				double tw = fnt.StringWidth(txt) * f;
				Screen.DrawText(fnt, Font.CR_GRAY,
					(ox - tw * 0.5) / f, (y + bh + 2 * f) / f, txt,
					DTA_ScaleX, f, DTA_ScaleY, f);
			}
		}
	}

	// -----------------------------------------------------------------
	// Life pips. Drawn as rectangles rather than a font glyph so there
	// is no art or font dependency to go missing.
	ui void DrawLives(RS_ScorePlayer sp, double ox, double oy, double f)
	{
		int lives = sp.extraLives;
		if (lives <= 0)
			return;

		int drawn = min(lives, 10);
		double pw = 7 * f;
		double ph = 7 * f;
		double gap = 4 * f;
		double total = (drawn * pw) + ((drawn - 1) * gap);
		double x = ox - (total * 0.5);
		double y = oy - (14 * f);

		Color c = PresetColor(CVInt("rs_score_hud_lifecolor", 3));

		for (int i = 0; i < drawn; i++)
		{
			double px = x + i * (pw + gap);
			Screen.Dim(0xFF000000, 0.7, int(px - 1 * f), int(y - 1 * f), int(pw + 2 * f), int(ph + 2 * f));
			Screen.Dim(c, 1.0, int(px), int(y), int(pw), int(ph));
		}

		// Past ten pips, show a count instead of an unreadable row.
		if (lives > 10)
		{
			Font fnt = Font.GetFont("SMALLFONT");
			if (fnt)
			{
				string txt = String.Format("x%d", lives);
				Screen.DrawText(fnt, Font.CR_GREEN,
					(x + total + gap) / f, y / f, txt,
					DTA_ScaleX, f, DTA_ScaleY, f);
			}
		}
	}

	// -----------------------------------------------------------------
	// The floating "+N NAME" stack. This is the part that sells it.
	ui void DrawBonuses(RS_ScorePlayer sp, double ox, double oy, double f, int now)
	{
		Font fnt = Font.GetFont("SMALLFONT");
		if (!fnt)
			return;

		int life = clamp(CVInt("rs_score_bonustime", 105), 35, 350);
		double y = oy + (42 * f);
		double lineH = 11 * f;
		int shown = 0;

		for (int i = 0; i < RS_ScoreDefs.RS_SB_COUNT; i++)
		{
			if (i >= sp.bonusValue.Size())
				break;

			int val = sp.bonusValue[i];
			int t   = sp.bonusTime[i];

			if (val <= 0 || t < 0)
				continue;

			// Base is the kill itself -- not a bonus, so it only shows
			// if the player asks for it.
			if (i == RS_ScoreDefs.RS_SB_BASE && !CVBool("rs_score_hud_showbase", false))
				continue;

			int age = now - t;
			if (age >= life)
				continue;

			// Hold full opacity for the first half, fade the rest.
			double alpha = 1.0;
			double half = life * 0.5;
			if (age > half)
				alpha = 1.0 - ((age - half) / (life - half));
			alpha = clamp(alpha, 0.0, 1.0);

			string nm = RS_ScoreDefs.BonusName(i);
			if (i == RS_ScoreDefs.RS_SB_BASE)
				nm = "KILL";

			int col = FlavorColor(RS_ScoreDefs.BonusFlavor(i));

			string amt = String.Format("+%d", val);
			double aw = fnt.StringWidth(amt) * f;

			double ly = y + (shown * lineH);

			// Amount right-aligned against the center line, name left of
			// it -- gives the stack a spine instead of ragged edges.
			Screen.DrawText(fnt, col, (ox - 6 * f - aw) / f, ly / f, amt,
				DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, alpha);

			Screen.DrawText(fnt, Font.CR_WHITE, (ox + 4 * f) / f, ly / f, nm,
				DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, alpha);

			shown++;
		}
	}

	// -----------------------------------------------------------------
	// Spree counter with its own decay bar. dakka never showed this --
	// the killstreak was invisible state you had to infer from the
	// Spree bonus appearing. Showing the timer draining is the whole
	// tension of a combo system, so it is drawn.
	ui void DrawSpree(RS_ScorePlayer sp, double ox, double oy, double f, int now)
	{
		if (sp.spreeCount < 2)
			return;

		int remain = sp.spreeExpire - now;
		if (remain <= 0)
			return;

		Font fnt = Font.GetFont("BIGFONT");
		if (!fnt)
			return;

		string txt = String.Format("%d", sp.spreeCount);
		double tw = fnt.StringWidth(txt) * f;

		double x = ox - (tw * 0.5);
		double y = oy - (44 * f);

		// Color ramps toward red as the streak climbs.
		int col = Font.CR_WHITE;
		if (sp.spreeCount >= 20)      col = Font.CR_RED;
		else if (sp.spreeCount >= 12) col = Font.CR_ORANGE;
		else if (sp.spreeCount >= 6)  col = Font.CR_YELLOW;

		Screen.DrawText(fnt, col, x / f, y / f, txt,
			DTA_ScaleX, f, DTA_ScaleY, f);

		// Drain bar directly under the number.
		double bw = 44 * f;
		double bh = 3 * f;
		double bx = ox - (bw * 0.5);
		double by = y + (20 * f);

		// The window this streak was granted, so the bar reads as a
		// fraction rather than an absolute countdown.
		double frac = clamp(remain / 360.0, 0.0, 1.0);

		Screen.Dim(0xFF000000, 0.6, int(bx), int(by), int(bw), int(bh));
		if (frac > 0)
			Screen.Dim(0xFFFF6020, 0.9, int(bx), int(by), int(bw * frac), int(bh));
	}
}
