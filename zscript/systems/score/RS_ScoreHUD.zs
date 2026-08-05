// =====================================================================
// RS_ScoreHUD -- the arcade score readout. Drawing only; every value it
// shows is computed in RS_Score.zs and simply read here.
//
// ASSETS
//   graphics/score/  RSSCBKT      bar frame, 124x8
//                    RSSCBG1..4   bar track, 120x6
//                    RSSCBR1..4   bar fill,  120x6
//                    RSSCLF1..4   life pip,  8x8, animated
//   root             RSSCRFN1     the score number font
//                    RSSCRFN2     the bonus stack font
//   TEXTCOLO.txt     RSScore_*    the gradient palette
//
//   The 1/2 pairing on the bar art is what the next reward will be --
//   1 for ammo regen, 2 for an extra life -- and 3/4 are the flash
//   overlays for each. That is why there are four of each and not two.
//
// WHY THERE IS NO Screen.Dim IN THIS FILE
//   An earlier version drew the reward bar and the life pips as tinted
//   rectangles, with the flavours mapped onto stock console colours. It
//   looked like placeholder art because it was placeholder art. Every
//   element now draws real graphics and real gradients. If a rectangle
//   ever reappears in here, something has regressed.
//
// GEOMETRY
//   All offsets are relative to (centerX, centerY) in a 640x480 virtual
//   space, scaled to the real framebuffer by ScaleFactor():
//
//     lives     centerY - 12   8x8 pips, 12px pitch, centred on centerX
//     score     centerY +  7   centred on centerX
//     bar       centerY + 13   120 wide, centred; frame is 124
//     bonuses   centerY + 26   line height 13
//                              amount column at centerX - 55
//                              name   column at centerX - 12
//
//   These are not taste and should not be nudged casually -- they are a
//   set, and moving one without the others pulls the widget apart. An
//   earlier pass had every one of them wrong (bar at +26 and 160 wide,
//   bonuses at +42 with line height 11, pips 7px spaced 11) and the
//   result did not read as a single object.
//
// POSITION
//   Default is 50%/5% -- top centre, so the readout sits between the
//   mainhand and offhand Gun Bonsai XP bars (bonsai_hud_x 0.01 puts one
//   top-left and mirrors the other to top-right at the same height).
//   Fully cvar-driven; rs_score_hud_x/y move it anywhere.
// =====================================================================

class RS_ScoreHUD : Object
{
	// Virtual canvas.
	const VW = 640;
	const VH = 480;

	// Bar geometry. The fill graphic is 120x6; RSSCBKT is 124x8 and
	// frames it with a 2px margin on every side.
	const BARW  = 120;
	const BARH  = 6;
	const BKTW  = 124;
	const BKTH  = 8;

	// Life pips are 8x8 drawn on a 12px pitch.
	const LIFEW     = 8;
	const LIFEPITCH = 12;
	const LIVES_MAXDRAW = 10;

	// Vertical offsets from centerY.
	const OFF_LIVES  = -12;
	const OFF_SCORE  =   7;
	const OFF_BAR    =  13;
	const OFF_BONUS  =  26;
	const BONUS_LINEH=  13;

	// Horizontal offsets from centerX for the bonus stack.
	const BONUS_AMTX = -55;
	const BONUS_NAMEX= -12;

	// Total afterglow length on a scoring kill, in tics.
	const FLASH_TICS = 7;

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

	// Flavour -> RSScore_* translation. These resolve through
	// TEXTCOLO.txt; Font.FindFontColor returns CR_UNTRANSLATED for a name
	// that is not defined, so a colourless bonus stack means that lump is
	// not being loaded.
	ui int FlavorColor(int flavor) const
	{
		switch (flavor)
		{
			case RS_ScoreDefs.RS_SF_EFFICIENCY: return Font.FindFontColor("RSScore_Efficiency");
			case RS_ScoreDefs.RS_SF_STYLE:      return Font.FindFontColor("RSScore_Style");
			case RS_ScoreDefs.RS_SF_DARING:     return Font.FindFontColor("RSScore_Daring");
		}
		return Font.FindFontColor("RSScore_Base");
	}

	// Virtual -> real. Normalised against height so the widget is the
	// same physical size at any aspect ratio.
	ui double ScaleFactor() const
	{
		double s = clamp(CVInt("rs_score_hud_scale", 100), 25, 400) / 100.0;
		return (Screen.GetHeight() / double(VH)) * s;
	}

	ui double OriginX() const
	{
		double pct = clamp(CVInt("rs_score_hud_x", 50), 0, 100) / 100.0;
		return Screen.GetWidth() * pct;
	}

	ui double OriginY() const
	{
		double pct = clamp(CVInt("rs_score_hud_y", 5), 0, 100) / 100.0;
		return Screen.GetHeight() * pct;
	}

	// TexMan lookup with a null-safe result, so a missing graphic skips
	// its element instead of taking the whole overlay down.
	ui TextureID Tex(string name) const
	{
		return TexMan.CheckForTexture(name, TexMan.Type_Any);
	}

	// The score number font, with a stock fallback so a missing lump
	// degrades to readable rather than to nothing.
	ui Font BigFont() const
	{
		Font f = Font.GetFont("RSSCRFN1");
		return f ? f : Font.GetFont("BIGFONT");
	}

	ui Font SmallFont() const
	{
		Font f = Font.GetFont("RSSCRFN2");
		return f ? f : Font.GetFont("SMALLFONT");
	}

	// -----------------------------------------------------------------
	ui void Draw(RS_ScorePlayer sp, int threshold, int now)
	{
		if (!sp)
			return;

		double f  = ScaleFactor();
		double ox = OriginX();
		double oy = OriginY();

		// Lives sit above the number, the bar under it, the bonus stack
		// under that.
		if (CVBool("rs_score_hud_showlives", true))
			DrawLives(sp, ox, oy, f, now);

		if (CVBool("rs_score_hud_showscore", true))
			DrawScoreNumber(sp, ox, oy, f);

		if (CVBool("rs_score_hud_showbar", true))
			DrawRewardBar(sp, threshold, ox, oy, f);

		if (CVBool("rs_score_hud_showbonuses", true))
			DrawBonuses(sp, ox, oy, f, now);

		if (CVBool("rs_score_hud_showspree", false))
			DrawSpree(sp, ox, oy, f, now);
	}

	// -----------------------------------------------------------------
	// "Score: 1234" -- label in RSScore_White, number in RSScore_Gold.
	// Screen.DrawText takes a single colour, so the two are drawn as
	// separate pieces and the pair is centred as a unit.
	ui void DrawScoreNumber(RS_ScorePlayer sp, double ox, double oy, double f)
	{
		Font fnt = BigFont();
		if (!fnt)
			return;

		string label = StringTable.Localize("$RS_SCORE_LABEL");
		string num   = String.Format("%d", sp.displayScore);

		double lw = fnt.StringWidth(label) * f;
		double nw = fnt.StringWidth(num) * f;

		double x = ox - ((lw + nw) * 0.5);
		double y = oy + (OFF_SCORE * f);

		Screen.DrawText(fnt, Font.FindFontColor("RSScore_White"), x / f, y / f, label,
			DTA_ScaleX, f, DTA_ScaleY, f);

		Screen.DrawText(fnt, Font.FindFontColor("RSScore_Gold"), (x + lw) / f, y / f, num,
			DTA_ScaleX, f, DTA_ScaleY, f);

		// The afterglow on a scoring kill: the whole line redrawn in the
		// *Flash ramps, fading over FLASH_TICS. This used to be a one-tic
		// bool, which is far too short to register -- it is why the
		// number never felt struck.
		if (!CVBool("rs_score_hud_flash", true))
			return;

		int age = sp.flashAge;
		if (age < 0 || age >= FLASH_TICS)
			return;

		double a = 1.0 - (age / double(FLASH_TICS));

		Screen.DrawText(fnt, Font.FindFontColor("RSScore_WhiteFlash"), x / f, y / f, label,
			DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, a);

		Screen.DrawText(fnt, Font.FindFontColor("RSScore_GoldFlash"), (x + lw) / f, y / f, num,
			DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, a);
	}

	// -----------------------------------------------------------------
	// RSSCBKT frame, RSSCBG* track, RSSCBR* fill clipped to progress.
	ui void DrawRewardBar(RS_ScorePlayer sp, int threshold, double ox, double oy, double f)
	{
		if (threshold <= 0)
			return;

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

		string bg = nextIsLife ? "RSSCBG2" : "RSSCBG1";
		string fg = nextIsLife ? "RSSCBR2" : "RSSCBR1";
		// 3/4 are the brightened copies, overlaid on a scoring kill so
		// the bar pulses with the number rather than sitting inert while
		// the score above it flashes.
		string bgF = nextIsLife ? "RSSCBG4" : "RSSCBG3";
		string fgF = nextIsLife ? "RSSCBR4" : "RSSCBR3";

		int fAge = sp.flashAge;
		bool flashing = CVBool("rs_score_hud_flash", true)
			&& fAge >= 0 && fAge < FLASH_TICS;
		double fAlpha = flashing ? 1.0 - (fAge / double(FLASH_TICS)) : 0.0;

		double bw = BARW * f;
		double bh = BARH * f;
		double x  = ox - (bw * 0.5);
		double y  = oy + (OFF_BAR * f);

		// Track.
		TextureID tBG = Tex(bg);
		if (tBG.IsValid())
			Screen.DrawTexture(tBG, false, x, y,
				DTA_DestWidthF, bw, DTA_DestHeightF, bh);

		if (flashing)
		{
			TextureID tBGF = Tex(bgF);
			if (tBGF.IsValid())
				Screen.DrawTexture(tBGF, false, x, y,
					DTA_DestWidthF, bw, DTA_DestHeightF, bh,
					DTA_Alpha, fAlpha);
		}

		// Frame, centred on the same point and 2px proud on each side.
		TextureID tBK = Tex("RSSCBKT");
		if (tBK.IsValid())
		{
			double kw = BKTW * f;
			double kh = BKTH * f;
			Screen.DrawTexture(tBK, false, ox - (kw * 0.5), y - ((kh - bh) * 0.5),
				DTA_DestWidthF, kw, DTA_DestHeightF, kh);
		}

		// Fill is CLIPPED, not scaled -- scaling would squash the graphic
		// instead of revealing it.
		int progress = sp.score % threshold;
		double frac = clamp(progress / double(threshold), 0.0, 1.0);

		TextureID tFG = Tex(fg);
		if (frac > 0 && tFG.IsValid())
		{
			Screen.SetClipRect(int(x), int(y), int(ceil(bw * frac)), int(ceil(bh)));
			Screen.DrawTexture(tFG, false, x, y,
				DTA_DestWidthF, bw, DTA_DestHeightF, bh);

			if (flashing)
			{
				TextureID tFGF = Tex(fgF);
				if (tFGF.IsValid())
					Screen.DrawTexture(tFGF, false, x, y,
						DTA_DestWidthF, bw, DTA_DestHeightF, bh,
						DTA_Alpha, fAlpha);
			}

			Screen.ClearClipRect();
		}

		// Numeric readout under the bar. Off by default -- clutter for
		// most people, essential for a few.
		if (CVBool("rs_score_hud_barnumbers", false))
		{
			Font fnt = SmallFont();
			if (fnt)
			{
				string txt = String.Format("%d / %d", progress, threshold);
				double tw = fnt.StringWidth(txt) * f;
				Screen.DrawText(fnt, Font.FindFontColor("RSScore_White"),
					(ox - tw * 0.5) / f, (y + bh + 2 * f) / f, txt,
					DTA_ScaleX, f, DTA_ScaleY, f);
			}
		}
	}

	// -----------------------------------------------------------------
	// Life pips: RSSCLF1-4 cycled every 4 tics, so the row shimmers.
	ui void DrawLives(RS_ScorePlayer sp, double ox, double oy, double f, int now)
	{
		int lives = sp.extraLives;
		if (lives <= 0)
			return;

		int drawn = min(lives, LIVES_MAXDRAW);

		int frame = (now / 4) % 4;
		TextureID t = Tex(String.Format("RSSCLF%d", frame + 1));
		if (!t.IsValid())
			return;

		double pw = LIFEW * f;
		double pitch = LIFEPITCH * f;

		// The row is centred on centerX at a 12px pitch.
		double left = ox - ((LIFEPITCH * 0.5) * (drawn - 1) * f) - (pw * 0.5);
		double y = oy + (OFF_LIVES * f);

		for (int i = 0; i < drawn; i++)
		{
			Screen.DrawTexture(t, false, left + i * pitch, y,
				DTA_DestWidthF, pw, DTA_DestHeightF, pw);
		}

		// Past ten pips, show a count rather than an unreadable row.
		if (lives > LIVES_MAXDRAW)
		{
			Font fnt = SmallFont();
			if (fnt)
			{
				string txt = String.Format("x%d", lives);
				Screen.DrawText(fnt, Font.FindFontColor("RSScore_White"),
					(left + drawn * pitch + 2 * f) / f, y / f, txt,
					DTA_ScaleX, f, DTA_ScaleY, f);
			}
		}
	}

	// -----------------------------------------------------------------
	// The floating "+N NAME" stack.
	//
	// Both columns are LEFT-aligned at their own anchor, 43px apart. The
	// stack COMPACTS -- `shown` only advances for a bonus that actually
	// paid, so there are never gaps where a quiet bonus would have been.
	ui void DrawBonuses(RS_ScorePlayer sp, double ox, double oy, double f, int now)
	{
		Font fnt = SmallFont();
		if (!fnt)
			return;

		int life = clamp(CVInt("rs_score_bonustime", 35), 5, 350);
		double y = oy + (OFF_BONUS * f);
		double lineH = BONUS_LINEH * f;
		int shown = 0;

		for (int i = 0; i < RS_ScoreDefs.RS_SB_COUNT; i++)
		{
			if (i >= sp.bonusValue.Size())
				break;

			int val = sp.bonusValue[i];
			int t   = sp.bonusTime[i];

			if (val <= 0 || t < 0)
				continue;

			if (i == RS_ScoreDefs.RS_SB_BASE && !CVBool("rs_score_hud_showbase", true))
				continue;

			int age = now - t;
			if (age >= life)
				continue;

			// Hold at full opacity, then fade over the last half second.
			double alpha = 1.0;
			int fadeTics = 17;
			if (age > life - fadeTics)
				alpha = double(life - age) / fadeTics;
			alpha = clamp(alpha, 0.0, 1.0);

			string nm  = RS_ScoreDefs.BonusName(i);
			string amt = String.Format("+%d", val);

			int col = FlavorColor(RS_ScoreDefs.BonusFlavor(i));

			double ly = y + (shown * lineH);

			Screen.DrawText(fnt, col, (ox + BONUS_AMTX * f) / f, ly / f, amt,
				DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, alpha);

			Screen.DrawText(fnt, Font.FindFontColor("RSScore_White"),
				(ox + BONUS_NAMEX * f) / f, ly / f, nm,
				DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, alpha);

			shown++;
		}
	}

	// -----------------------------------------------------------------
	// Spree counter. Off by default: the streak is otherwise invisible
	// state you have to infer from the Spree bonus appearing, and showing
	// it changes how the readout reads. Drawn as text, not a bar.
	ui void DrawSpree(RS_ScorePlayer sp, double ox, double oy, double f, int now)
	{
		if (sp.spreeCount < 2)
			return;

		if (sp.spreeExpire - now <= 0)
			return;

		Font fnt = BigFont();
		if (!fnt)
			return;

		string txt = String.Format("x%d", sp.spreeCount);
		double tw = fnt.StringWidth(txt) * f;

		double x = ox - (tw * 0.5);
		double y = oy - (30 * f);

		int col = Font.FindFontColor("RSScore_Style");
		if (sp.spreeCount >= 20)      col = Font.FindFontColor("RSScore_Daring");
		else if (sp.spreeCount >= 12) col = Font.FindFontColor("RSScore_Gold");

		Screen.DrawText(fnt, col, x / f, y / f, txt,
			DTA_ScaleX, f, DTA_ScaleY, f);
	}
}
