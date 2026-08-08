// =====================================================================
// RS_ScoreHUD -- the arcade score readout. Drawing only; every value it
// shows is computed in RS_Score.zs and simply read here.
//
// REBUILT 2026-08-07. What was wrong, and how it was proved wrong:
//
//   1. TEXT WAS DRAWN IN THE WRONG PLACE ENTIRELY. Every DrawText call
//      passed `x / f, y / f` alongside DTA_ScaleX/DTA_ScaleY. That is
//      wrong: the engine does NOT scale the text origin. Verified in
//      E:\UZDXREMA -- src/common/2d/v_drawtext.cpp:298 sets `cx = x`
//      raw, and DTA_ScaleX lands in `parms->patchscalex`
//      (v_draw.cpp:1297) which only multiplies destwidth/destheight and
//      the per-glyph advance. VirtualToRealCoords is skipped because
//      virtWidth defaults to the viewport width (v_draw.cpp:1395). So
//      x,y are REAL FRAMEBUFFER PIXELS.
//
//      Consequence at 1080p, scale 100 (f = 2.25): the bar drew at the
//      configured spot while the score number drew at 1/2.25 of that
//      position -- a completely different part of the screen, up and to
//      the left, on top of the Gun Bonsai widget. That is the "all over
//      the place" the owner reported. The bar was right because
//      DrawTexture + DTA_DestWidthF takes raw pixels and was already
//      being fed raw pixels.
//
//   2. THE SCORE NUMBER SAT ON TOP OF THE BAR. The score's top edge was
//      +7 and the bar's top edge was +13, but RSSCRFN1 is 12 pixels tall
//      (FON2 header, byte 4 of RSSCRFN1.fon2 = 0x0C). 12 > 6, so the
//      number overlapped the bar completely. The offsets were inherited
//      from an ACS original where the same numbers were HudMessage
//      ANCHOR points with a fractional alignment code, not top-left
//      coordinates. They do not transfer literally.
//
//   3. rs_score_bonustime was read with a different default and a
//      different clamp here (35 / 5..350) than in RS_Score.zs
//      (105 / 35..350), so the HUD could hide a popup that the model
//      still considered live, or hold one the model had already wiped.
//      This file now uses RS_Score.zs's contract exactly, and treats 0
//      as "off" (which the model tolerates -- its own clamp floors at
//      35, so values still expire).
//
// ASSETS
//   graphics/score/  RSSCBKT      bar frame, 124x8
//                    RSSCBG1..4   bar track, 120x6
//                    RSSCBR1..4   bar fill,  120x6
//                    RSSCLF1..4   life pip,  8x8, animated
//   root             RSSCRFN1     the score number font (12px tall)
//                    RSSCRFN2     the bonus stack font  (7px tall)
//   TEXTCOLO.txt     RSScore_*    the gradient palette, 8 ramps
//
//   The 1/2 pairing on the bar art is what the next reward will be --
//   1 for ammo regen, 2 for an extra life -- and 3/4 are the flash
//   overlays for each. That is why there are four of each and not two.
//
// WHY THERE IS NO Screen.Dim IN THIS FILE
//   An earlier version drew the reward bar and the life pips as tinted
//   rectangles, with the flavours mapped onto stock console colours. It
//   looked like placeholder art because it was placeholder art. Every
//   element draws real graphics and real gradients, INCLUDING the five
//   bar patterns -- a pattern is the real fill artwork revealed through
//   a different clip mask, never a drawn rectangle. If a rectangle ever
//   reappears in here, something has regressed.
//
// GEOMETRY
//   A 640x480 virtual space, normalised against screen HEIGHT so the
//   readout is the same physical size at any aspect ratio. Offsets are
//   virtual pixels from the group origin; every one is a cvar, and the
//   constants below are only the defaults.
//
//     lives     -16   8x8 pips, 12px pitch
//     score      -2   12px tall, so it ends at +10
//     bar       +13   6px tall, frame +12..+20
//     underline +21   bar numbers (left) and reward label (right)
//     spree     +30   12px tall
//     bonuses   +45   7px tall on a 13px pitch
//
//   The group's own size scales with rs_score_hud_scale; each element
//   additionally scales with its own multiplier. OFFSETS always use the
//   group scale, never the element scale -- that is what keeps the
//   assembly together when one piece is resized.
//
// CLOCK
//   Everything here is driven by the `now` passed in from
//   RS_ScoreHandler.RenderOverlay, which is Level.maptime. This file
//   never reads level.time. Do not mix them.
// =====================================================================

class RS_ScoreHUD : Object
{
	// Virtual canvas.
	const VW = 640;
	const VH = 480;

	// Native sizes of the bar art.
	const BAR_ART_W = 120;
	const BAR_ART_H = 6;
	const BKT_PAD_X = 2;   // RSSCBKT is 124 wide -- 2px proud each side
	const BKT_PAD_Y = 1;   // and 8 tall -- 1px proud top and bottom

	// Life pips are 8x8 drawn on a 12px pitch.
	const LIFE_ART      = 8;
	const LIFE_PITCH    = 12;
	const LIVES_MAXDRAW = 10;

	// Default vertical offsets from the group origin. See GEOMETRY.
	const DEF_LIVES_Y = -16;
	const DEF_SCORE_Y =  -2;
	const DEF_BAR_Y   =  13;
	const DEF_UNDER_Y =  21;
	const DEF_SPREE_Y =  30;
	const DEF_COMBO_Y =  45;

	// The bonus stack's two columns. The block is 110 wide; the amount
	// column starts at its left edge and the name column 43 in, which
	// reproduces the original centred -55 / -12 exactly.
	const COMBO_BLOCK_W = 110;
	const COMBO_GAP     = 43;
	const COMBO_LINEH   = 13;

	// Bar patterns.
	const BS_SOLID     = 0;
	const BS_SEGMENTED = 1;
	const BS_PIPS      = 2;
	const BS_GRADIENT  = 3;
	const BS_SWEEP     = 4;

	// Horizontal alignment of the whole group.
	const AL_AUTO   = 0;
	const AL_CENTER = 1;
	const AL_LEFT   = 2;
	const AL_RIGHT  = 3;

	// -----------------------------------------------------------------
	// Persistent ui state.
	//
	// These exist because two transient elements have no "when did this
	// appear" timestamp in the model: the spree counter and the life
	// row. A fade-IN needs one. Marked `ui` individually rather than
	// making the whole class ui-scoped, because RS_Score.zs declares
	// `ui RS_ScoreHUD hud;` against the current shape and that shape is
	// known to compile here.
	// -----------------------------------------------------------------
	ui int lastSpree;
	ui int spreeStamp;
	ui int lastLives;
	ui int livesStamp;

	// Set once per bar draw so the pattern helpers do not need an
	// eleventh parameter.
	ui uint barTint;

	// =================================================================
	// CVAR ACCESS
	//
	// Every default here must be the value that makes the readout look
	// right when the cvar DOES NOT EXIST YET. The menu lane declares
	// these; until it does, this file has to stand up on its own.
	// =================================================================
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

	ui double CVFloat(string name, double def) const
	{
		let c = CVar.GetCVar(name, players[consoleplayer]);
		return c ? c.GetFloat() : def;
	}

	// A colour cvar with the alpha byte forced opaque, returned as uint
	// for the same reason GunBonsai's hud_colours() does (settings.zsc:94)
	// -- DTA_Color multiplies all four channels, so a zero alpha byte
	// would erase the element, and 0xFF000000 does not fit in a signed
	// int. A cvar that does not exist yet reads as plain white, i.e. no
	// tint at all.
	ui uint CVTint(string name) const
	{
		let c = CVar.GetCVar(name, players[consoleplayer]);
		if (!c)
			return 0xFFFFFFFF;
		return c.GetInt() | 0xFF000000;
	}

	// =================================================================
	// PALETTE
	//
	// Indices into the RSScore_* ramps in TEXTCOLO.txt. Every per-element
	// colour cvar is one of these numbers, so the menu can present the
	// same list everywhere and nothing can name a ramp that is not
	// defined. Font.FindFontColor returns CR_UNTRANSLATED for a name that
	// does not resolve, so a colourless readout means TEXTCOLO.txt is not
	// being loaded -- it does not mean these indices are wrong.
	// =================================================================
	ui int PaletteColor(int idx) const
	{
		switch (idx)
		{
			case 0: return Font.FindFontColor("RSScore_Gold");
			case 1: return Font.FindFontColor("RSScore_White");
			case 2: return Font.FindFontColor("RSScore_Efficiency");
			case 3: return Font.FindFontColor("RSScore_Style");
			case 4: return Font.FindFontColor("RSScore_Daring");
			case 5: return Font.FindFontColor("RSScore_Base");
			case 6: return Font.FindFontColor("RSScore_GoldFlash");
			case 7: return Font.FindFontColor("RSScore_WhiteFlash");
		}
		return Font.FindFontColor("RSScore_Gold");
	}

	// The bright twin used for the afterglow overlay. Only Gold and White
	// have real *Flash ramps; the flavour ramps redraw in themselves,
	// which still reads as a pulse because the overlay is additive alpha
	// on top of the same glyphs.
	ui int PaletteFlash(int idx) const
	{
		switch (idx)
		{
			case 0: return 6;
			case 5: return 6;
			case 1: return 7;
		}
		return idx;
	}

	// Flavour -> palette index, each overridable.
	ui int FlavorPalette(int flavor) const
	{
		switch (flavor)
		{
			case RS_ScoreDefs.RS_SF_EFFICIENCY:
				return CVInt("rs_score_hud_col_efficiency", 2);
			case RS_ScoreDefs.RS_SF_STYLE:
				return CVInt("rs_score_hud_col_style", 3);
			case RS_ScoreDefs.RS_SF_DARING:
				return CVInt("rs_score_hud_col_daring", 4);
		}
		return CVInt("rs_score_hud_col_base", 5);
	}

	// Per-flavour filter for the combo stack -- show the Style bonuses
	// but not the Daring ones, and so on.
	//
	// Base is deliberately NOT gated here. It has its own switch
	// (rs_score_hud_showbase) and gating the same line twice would make
	// one of the two menu rows look broken.
	ui bool FlavorVisible(int flavor) const
	{
		switch (flavor)
		{
			case RS_ScoreDefs.RS_SF_EFFICIENCY:
				return CVBool("rs_score_hud_showflavor_efficiency", true);
			case RS_ScoreDefs.RS_SF_STYLE:
				return CVBool("rs_score_hud_showflavor_style", true);
			case RS_ScoreDefs.RS_SF_DARING:
				return CVBool("rs_score_hud_showflavor_daring", true);
		}
		return true;
	}

	// =================================================================
	// FADE CURVE -- fast in, slow out, with the two halves separately
	// tunable.
	//
	// Both halves use the same ease-out quadratic, t * (2 - t). Applied
	// to the rising edge it reaches 75% opacity by the time a third of
	// the fade-in has elapsed, which is what makes a popup feel struck
	// rather than dissolved in. Applied to the falling edge (with t as
	// the fraction REMAINING) it holds near full for most of the fade
	// and then drops, which is what makes a long fade-out read as a
	// linger instead of a slow dim.
	//
	// No pow() -- it is not reliably available here, and this shape does
	// not need it.
	// =================================================================
	ui double Ease(double t) const
	{
		t = clamp(t, 0.0, 1.0);
		return t * (2.0 - t);
	}

	ui double FadeCurve(int age, int life, int inTics, int outTics) const
	{
		if (life <= 0 || age < 0 || age >= life)
			return 0.0;

		inTics  = max(0, inTics);
		outTics = max(0, outTics);

		// Never let the two halves overlap -- a short life with long
		// fades would otherwise produce a popup that never reaches full
		// opacity and flickers instead.
		if (inTics + outTics > life)
		{
			double sc = double(life) / double(max(1, inTics + outTics));
			inTics  = int(inTics * sc);
			outTics = int(outTics * sc);
		}

		if (inTics > 0 && age < inTics)
			return Ease(double(age) / double(inTics));

		if (outTics > 0 && age > life - outTics)
			return Ease(double(life - age) / double(outTics));

		return 1.0;
	}

	ui int FadeInTics() const
	{
		return clamp(CVInt("rs_score_hud_fadein", 3), 0, 70);
	}

	ui int FadeOutTics() const
	{
		return clamp(CVInt("rs_score_hud_fadeout", 24), 0, 210);
	}

	// The extra size a popup carries during its fade-in. 1.0 once the
	// fade-in is over.
	ui double PopScale(int age, int inTics) const
	{
		if (!CVBool("rs_score_hud_pop", true))
			return 1.0;
		if (inTics <= 0 || age < 0 || age >= inTics)
			return 1.0;

		double amount = clamp(CVInt("rs_score_hud_popsize", 35), 0, 200) / 100.0;
		return 1.0 + amount * (1.0 - Ease(double(age) / double(inTics)));
	}

	// =================================================================
	// GEOMETRY
	// =================================================================

	// Virtual -> real, normalised against height so the widget is the
	// same physical size at any aspect ratio.
	ui double BaseScale() const
	{
		double s = clamp(CVInt("rs_score_hud_scale", 100), 25, 400) / 100.0;
		return (Screen.GetHeight() / double(VH)) * s;
	}

	// An element's own size multiplier, on top of the group scale.
	ui double ElemScale(string cvarname) const
	{
		double s = clamp(CVInt(cvarname, 100), 25, 400) / 100.0;
		return BaseScale() * s;
	}

	ui int Preset() const
	{
		return clamp(CVInt("rs_score_hud_preset", 0), 0, 8);
	}

	// The group origin in real framebuffer pixels.
	//
	// Preset 0 is Custom and uses rs_score_hud_x / rs_score_hud_y, which
	// is what those two cvars have always meant. The named presets are
	// positions that are known not to collide: the Gun Bonsai XP widgets
	// occupy roughly the top 17% of the screen in the left and right
	// quarters (bonsai_hud_x 0.01, bonsai_hud_y 0.02, size 0.15, mirrored
	// -- see zscript/gunbonsai/HUD.zsc:50), and the status bar owns the
	// bottom 16%.
	ui double, double GroupOrigin()
	{
		double px, py;

		switch (Preset())
		{
			case 1: px = 50; py = 20; break;   // Top Centre, under the XP band
			case 2: px = 15; py = 30; break;   // Upper Left, under the mainhand widget
			case 3: px = 85; py = 30; break;   // Upper Right, under the offhand widget
			case 4: px = 50; py = 48; break;   // Lower Centre, above the status bar
			case 5: px = 12; py = 48; break;   // Lower Left
			case 6: px = 88; py = 48; break;   // Lower Right
			case 7: px =  8; py = 40; break;   // Left Flank
			case 8: px = 92; py = 40; break;   // Right Flank
			default:
				px = clamp(CVInt("rs_score_hud_x", 50), 0, 100);
				py = clamp(CVInt("rs_score_hud_y", 5), 0, 100);
				break;
		}

		return Screen.GetWidth() * (px / 100.0), Screen.GetHeight() * (py / 100.0);
	}

	// Auto alignment follows the preset, so a side preset does not have
	// to be paired with an alignment by hand.
	ui int Alignment() const
	{
		int a = clamp(CVInt("rs_score_hud_align", AL_AUTO), AL_AUTO, AL_RIGHT);
		if (a != AL_AUTO)
			return a;

		switch (Preset())
		{
			case 2:
			case 5:
			case 7:
				return AL_LEFT;
			case 3:
			case 6:
			case 8:
				return AL_RIGHT;
		}
		return AL_CENTER;
	}

	// Left edge of a block `w` wide, honouring the group alignment.
	ui double AlignX(double ox, double w) const
	{
		switch (Alignment())
		{
			case AL_LEFT:  return ox;
			case AL_RIGHT: return ox - w;
		}
		return ox - (w * 0.5);
	}

	// =================================================================
	// RESOURCES
	// =================================================================

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

	// =================================================================
	// ENTRY POINT
	//
	// The signature is fixed by RS_ScoreHandler.RenderOverlay
	// (RS_Score.zs:1304) -- three arguments, `now` already being
	// Level.maptime. That file is not this lane's to edit, so nothing
	// here may require a fourth.
	// =================================================================
	ui void Draw(RS_ScorePlayer sp, int threshold, int now)
	{
		if (!sp)
			return;

		double ga = clamp(CVInt("rs_score_hud_alpha", 100), 0, 100) / 100.0;
		if (ga <= 0.0)
			return;

		double ox, oy;
		[ox, oy] = GroupOrigin();

		TrackTransients(sp, now);

		// Vertical order is fixed and is the point of the rebuild:
		// lives, then the SCORE NUMBER, then the BAR under it, then the
		// bar's underline, then the spree, then the COMBO STACK under
		// everything. Each element is independently movable from there.
		if (CVBool("rs_score_hud_showlives", true))
			DrawLives(sp, ox, oy, now, ga);

		if (CVBool("rs_score_hud_showscore", true))
			DrawScoreNumber(sp, ox, oy, now, ga);

		if (CVBool("rs_score_hud_showbar", true))
			DrawRewardBar(sp, threshold, ox, oy, now, ga);

		if (CVBool("rs_score_hud_showspree", false))
			DrawSpree(sp, ox, oy, now, ga);

		if (CVBool("rs_score_hud_showbonuses", true))
			DrawBonuses(sp, ox, oy, now, ga);
	}

	// Stamp the tic on which a transient element last CHANGED, so it can
	// be given a fade-in. The model has a timestamp for bonus popups
	// (bonusTime) but none for the spree counter or the life row.
	ui void TrackTransients(RS_ScorePlayer sp, int now)
	{
		if (sp.spreeCount != lastSpree)
		{
			lastSpree  = sp.spreeCount;
			spreeStamp = now;
		}

		if (sp.extraLives != lastLives)
		{
			lastLives  = sp.extraLives;
			livesStamp = now;
		}
	}

	// A transient's alpha built from a stamp (fade in) and a remaining
	// lifetime (fade out). Used by the spree counter, which is the one
	// element with a real expiry in the model.
	ui double StampAlpha(int now, int stamp, int remaining) const
	{
		int inT  = FadeInTics();
		int outT = FadeOutTics();

		double aIn = 1.0;
		if (inT > 0)
			aIn = Ease(double(now - stamp) / double(inT));

		double aOut = 1.0;
		if (outT > 0 && remaining < outT)
			aOut = Ease(double(remaining) / double(outT));

		return clamp(min(aIn, aOut), 0.0, 1.0);
	}

	// =================================================================
	// THE SCORE NUMBER -- above the bar.
	//
	// Screen.DrawText takes a single colour, so the label and the number
	// are two pieces and the pair is aligned as a unit. Positions are
	// REAL PIXELS; do not divide them by the scale factor (see the header
	// of this file for why that used to be here and what it did).
	// =================================================================
	ui void DrawScoreNumber(RS_ScorePlayer sp, double ox, double oy, int now, double ga)
	{
		Font fnt = BigFont();
		if (!fnt)
			return;

		double bs = BaseScale();
		double f  = ElemScale("rs_score_hud_score_scale");

		string label = CVBool("rs_score_hud_label", true)
			? StringTable.Localize("$RS_SCORE_LABEL")
			: "";
		string num = String.Format("%d", sp.displayScore);

		double lw = fnt.StringWidth(label) * f;
		double nw = fnt.StringWidth(num) * f;

		double x = AlignX(ox, lw + nw) + (CVInt("rs_score_hud_score_x", 0) * bs);
		double y = oy + (CVInt("rs_score_hud_score_y", DEF_SCORE_Y) * bs);

		int iLabel = CVInt("rs_score_hud_col_label", 1);
		int iNum   = ScoreNumberPalette(sp, now);

		Screen.DrawText(fnt, PaletteColor(iLabel), x, y, label,
			DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, ga);

		Screen.DrawText(fnt, PaletteColor(iNum), x + lw, y, num,
			DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, ga);

		// The afterglow on a scoring kill: the whole line redrawn in the
		// bright twin ramps, on the shared fade curve. This used to be a
		// one-tic bool, which is far too short to register -- it is why
		// the number never felt struck. RS_Score.zs ages sp.flashAge in
		// WorldTick and never clears it, so the window check is ours.
		if (!CVBool("rs_score_hud_flash", true))
			return;

		// No fade-IN on the afterglow: a strike is instantaneous by
		// definition, so the whole lifetime is the fade-out. Passing an
		// in-time of 1 here would make the very first tic transparent,
		// which is the tic that matters most.
		int flashLife = clamp(CVInt("rs_score_hud_flashtime", 12), 1, 105);
		double a = FadeCurve(sp.flashAge, flashLife, 0, flashLife) * ga;
		if (a <= 0.0)
			return;

		Screen.DrawText(fnt, PaletteColor(PaletteFlash(iLabel)), x, y, label,
			DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, a);

		Screen.DrawText(fnt, PaletteColor(PaletteFlash(iNum)), x + lw, y, num,
			DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, a);
	}

	// "colors!!!" lands here: with rs_score_hud_score_tint on, the score
	// number takes the colour of the live spree tier, so the readout
	// changes hue as the streak climbs instead of being permanently gold.
	ui int ScoreNumberPalette(RS_ScorePlayer sp, int now) const
	{
		int base = CVInt("rs_score_hud_col_score", 0);

		if (!CVBool("rs_score_hud_score_tint", true))
			return base;

		if (sp.spreeCount < 2 || sp.spreeExpire - now <= 0)
			return base;

		int tier = SpreeTier(sp.spreeCount);
		if (tier <= 0)
			return base;

		return SpreeTierPalette(tier);
	}

	// =================================================================
	// SPREE TIERS -- the multiplier made visible.
	// =================================================================
	ui int SpreeTier(int count) const
	{
		if (count >= CVInt("rs_score_hud_spree_t3", 20)) return 3;
		if (count >= CVInt("rs_score_hud_spree_t2", 12)) return 2;
		if (count >= CVInt("rs_score_hud_spree_t1",  5)) return 1;
		return 0;
	}

	ui int SpreeTierPalette(int tier) const
	{
		switch (tier)
		{
			case 1: return CVInt("rs_score_hud_col_spree1", 3);   // Style
			case 2: return CVInt("rs_score_hud_col_spree2", 0);   // Gold
			case 3: return CVInt("rs_score_hud_col_spree3", 4);   // Daring
		}
		return CVInt("rs_score_hud_col_spree0", 1);               // White
	}

	// =================================================================
	// THE REWARD BAR -- below the score number.
	//
	// RSSCBKT frame, RSSCBG* track, RSSCBR* fill revealed by a clip mask.
	// The FILL IS CLIPPED, NEVER SCALED -- scaling would squash the
	// artwork instead of revealing it, and every pattern below keeps that
	// property: the texture is always drawn at full bar size and only the
	// clip rectangle changes.
	// =================================================================
	ui void DrawRewardBar(RS_ScorePlayer sp, int threshold, double ox, double oy, int now, double ga)
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

		string bg  = nextIsLife ? "RSSCBG2" : "RSSCBG1";
		string fg  = nextIsLife ? "RSSCBR2" : "RSSCBR1";
		string bgF = nextIsLife ? "RSSCBG4" : "RSSCBG3";
		string fgF = nextIsLife ? "RSSCBR4" : "RSSCBR3";

		int flashLife = clamp(CVInt("rs_score_hud_flashtime", 12), 1, 105);
		double fAlpha = CVBool("rs_score_hud_flash", true)
			? FadeCurve(sp.flashAge, flashLife, 0, flashLife) * ga
			: 0.0;

		double bs = BaseScale();
		double f  = ElemScale("rs_score_hud_bar_scale");

		double bw = clamp(CVInt("rs_score_hud_bar_width", BAR_ART_W), 32, 480) * f;
		double bh = clamp(CVInt("rs_score_hud_bar_height", BAR_ART_H), 2, 64) * f;

		double bx = AlignX(ox, bw) + (CVInt("rs_score_hud_bar_x", 0) * bs);
		double by = oy + (CVInt("rs_score_hud_bar_y", DEF_BAR_Y) * bs);

		int style = clamp(CVInt("rs_score_hud_barstyle", BS_SOLID), BS_SOLID, BS_SWEEP);
		int segs  = clamp(CVInt("rs_score_hud_barsegments", 12), 2, 64);

		barTint = CVTint("rs_score_hud_bar_tint");

		// Track.
		TextureID tBG = Tex(bg);
		if (tBG.IsValid())
			Screen.DrawTexture(tBG, false, bx, by,
				DTA_DestWidthF, bw, DTA_DestHeightF, bh,
				DTA_Alpha, ga, DTA_Color, barTint);

		if (fAlpha > 0.0)
		{
			TextureID tBGF = Tex(bgF);
			if (tBGF.IsValid())
				Screen.DrawTexture(tBGF, false, bx, by,
					DTA_DestWidthF, bw, DTA_DestHeightF, bh,
					DTA_Alpha, fAlpha, DTA_Color, barTint);
		}

		// Frame, centred on the same rectangle and proud on every side.
		if (CVBool("rs_score_hud_barframe", true))
		{
			TextureID tBK = Tex("RSSCBKT");
			if (tBK.IsValid())
			{
				double kw = bw + (BKT_PAD_X * 2 * f);
				double kh = bh + (BKT_PAD_Y * 2 * f);
				Screen.DrawTexture(tBK, false, bx - (BKT_PAD_X * f), by - (BKT_PAD_Y * f),
					DTA_DestWidthF, kw, DTA_DestHeightF, kh,
					DTA_Alpha, ga, DTA_Color, CVTint("rs_score_hud_frame_tint"));
			}
		}

		int progress = sp.score % threshold;
		double frac = clamp(progress / double(threshold), 0.0, 1.0);

		TextureID tFG = Tex(fg);
		if (frac > 0.0 && tFG.IsValid())
		{
			DrawFillPattern(tFG, bx, by, bw, bh, frac, style, segs, now, ga);

			if (fAlpha > 0.0)
			{
				TextureID tFGF = Tex(fgF);
				if (tFGF.IsValid())
					DrawFillPattern(tFGF, bx, by, bw, bh, frac, style, segs, now, fAlpha);
			}
		}

		DrawBarUnderline(threshold, progress, nextIsLife, oy, bx, bw, ga);
	}

	// -----------------------------------------------------------------
	// One clipped draw of the fill artwork. `d*` is where the texture
	// goes (always the whole bar, so the art is never squashed) and `c*`
	// is the window it is seen through.
	//
	// GZDoom's SetClipRect REPLACES the clip rather than intersecting it
	// (src/common/2d/v_draw.cpp:408), so every caller here hands over a
	// rectangle it has already intersected itself.
	// -----------------------------------------------------------------
	ui void ClipDraw(TextureID t,
		double dx, double dy, double dw, double dh,
		double cx, double cy, double cw, double ch,
		double alpha)
	{
		if (cw <= 0.0 || ch <= 0.0 || alpha <= 0.0)
			return;

		Screen.SetClipRect(int(floor(cx)), int(floor(cy)), int(ceil(cw)), int(ceil(ch)));
		Screen.DrawTexture(t, false, dx, dy,
			DTA_DestWidthF, dw, DTA_DestHeightF, dh,
			DTA_Alpha, alpha, DTA_Color, barTint);
		Screen.ClearClipRect();
	}

	// -----------------------------------------------------------------
	// The five bar patterns. Every one of them is the SAME artwork seen
	// through a different mask -- there is no rectangle drawing in here
	// and there must never be.
	// -----------------------------------------------------------------
	ui void DrawFillPattern(TextureID t,
		double bx, double by, double bw, double bh,
		double frac, int style, int segs, int now, double alpha)
	{
		if (!t.IsValid() || frac <= 0.0 || alpha <= 0.0)
			return;

		switch (style)
		{
			case BS_SEGMENTED: BarSegmented(t, bx, by, bw, bh, frac, segs, alpha); break;
			case BS_PIPS:      BarPips     (t, bx, by, bw, bh, frac, segs, alpha); break;
			case BS_GRADIENT:  BarGradient (t, bx, by, bw, bh, frac, alpha);       break;
			case BS_SWEEP:     BarSweep    (t, bx, by, bw, bh, frac, now, alpha);  break;

			default:
				// Solid -- the original arcade look.
				ClipDraw(t, bx, by, bw, bh, bx, by, bw * frac, bh, alpha);
				break;
		}
	}

	// Whole blocks light up, with the block currently filling faded in
	// proportionally so progress is still legible between steps.
	ui void BarSegmented(TextureID t, double bx, double by, double bw, double bh,
		double frac, int segs, double alpha)
	{
		double segW = bw / segs;
		double gap  = max(1.0, bh * 0.25);
		double lit  = frac * segs;

		for (int i = 0; i < segs; i++)
		{
			double a;

			if (double(i + 1) <= lit)
				a = alpha;                          // block fully lit
			else if (double(i) < lit)
				a = alpha * (lit - double(i));      // the block now filling
			else
				break;                              // nothing past here is lit

			ClipDraw(t, bx, by, bw, bh,
				bx + (i * segW), by, max(1.0, segW - gap), bh, a);
		}
	}

	// Square chips spaced across the bar, the fill art showing through
	// each one.
	ui void BarPips(TextureID t, double bx, double by, double bw, double bh,
		double frac, int segs, double alpha)
	{
		double pipW = bh;
		double span = max(0.0, bw - pipW);
		double step = segs > 1 ? (span / (segs - 1)) : 0.0;
		double lit  = frac * segs;

		for (int i = 0; i < segs; i++)
		{
			double a;

			if (double(i + 1) <= lit)
				a = alpha;                          // pip fully lit
			else if (double(i) < lit)
				a = alpha * (lit - double(i));      // the pip now filling
			else
				break;

			ClipDraw(t, bx, by, bw, bh, bx + (i * step), by, pipW, bh, a);
		}
	}

	// The fill dims toward its own tail, so the leading edge is the
	// brightest thing on the bar and the eye is drawn to where the
	// progress actually is.
	ui void BarGradient(TextureID t, double bx, double by, double bw, double bh,
		double frac, double alpha)
	{
		int slices = 24;
		double filled = bw * frac;
		double sliceW = bw / slices;

		for (int i = 0; i < slices; i++)
		{
			double sx = bx + (i * sliceW);
			if (sx >= bx + filled)
				break;

			double w = min(sliceW, (bx + filled) - sx);

			// 0 at the left end of the FILLED region, 1 at its head.
			double rel = filled > 0.0 ? clamp(((i + 0.5) * sliceW) / filled, 0.0, 1.0) : 0.0;

			ClipDraw(t, bx, by, bw, bh, sx, by, w, bh, alpha * (0.35 + (0.65 * rel)));
		}
	}

	// A solid fill with a highlight band travelling along it. The band
	// wraps on a two-second cycle off Level.maptime.
	ui void BarSweep(TextureID t, double bx, double by, double bw, double bh,
		double frac, int now, double alpha)
	{
		double filled = bw * frac;

		ClipDraw(t, bx, by, bw, bh, bx, by, filled, bh, alpha * 0.7);

		int period = max(1, clamp(CVInt("rs_score_hud_sweeptics", 70), 10, 350));
		double p = double(now % period) / double(period);

		double bandW = max(4.0, bw * 0.18);
		double hx = bx - bandW + (p * (filled + bandW));

		double cx = max(hx, bx);
		double cw = min(hx + bandW, bx + filled) - cx;

		ClipDraw(t, bx, by, bw, bh, cx, by, cw, bh, alpha);
	}

	// -----------------------------------------------------------------
	// The line under the bar: the numeric readout at one end and the
	// next-reward label at the other, so the two can never collide.
	// Both off by default -- clutter for most people, essential for a
	// few.
	// -----------------------------------------------------------------
	ui void DrawBarUnderline(int threshold, int progress, bool nextIsLife,
		double oy, double bx, double bw, double ga)
	{
		bool wantNumbers = CVBool("rs_score_hud_barnumbers", false);
		bool wantLabel   = CVBool("rs_score_hud_rewardlabel", false);

		if (!wantNumbers && !wantLabel)
			return;

		Font fnt = SmallFont();
		if (!fnt)
			return;

		double bs = BaseScale();
		double f  = ElemScale("rs_score_hud_under_scale");
		double y  = oy + (CVInt("rs_score_hud_under_y", DEF_UNDER_Y) * bs);

		if (wantNumbers)
		{
			string txt = String.Format("%d / %d", progress, threshold);
			Screen.DrawText(fnt, PaletteColor(CVInt("rs_score_hud_col_barnum", 1)),
				bx, y, txt,
				DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, ga);
		}

		if (wantLabel)
		{
			// Deliberately not localised: RSSCRFN2 renders caps, and
			// these two words are the arcade convention rather than
			// prose. Nothing in LANGUAGE.rs_ui defines them.
			string txt = nextIsLife ? "1UP" : "AMMO";
			double tw = fnt.StringWidth(txt) * f;

			int idx = nextIsLife
				? CVInt("rs_score_hud_col_reward_life", 4)
				: CVInt("rs_score_hud_col_reward_ammo", 3);

			Screen.DrawText(fnt, PaletteColor(idx), bx + bw - tw, y, txt,
				DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, ga);
		}
	}

	// =================================================================
	// LIFE PIPS -- above the score number.
	//
	// RSSCLF1-4 cycled every 4 tics, so the row shimmers. A newly earned
	// life fades in on the shared curve.
	// =================================================================
	ui void DrawLives(RS_ScorePlayer sp, double ox, double oy, int now, double ga)
	{
		int lives = sp.extraLives;
		if (lives <= 0)
			return;

		int drawn = min(lives, LIVES_MAXDRAW);

		int rate = max(1, CVInt("rs_score_hud_lives_rate", 4));
		int frame = (now / rate) % 4;

		TextureID t = Tex(String.Format("RSSCLF%d", frame + 1));
		if (!t.IsValid())
			return;

		double bs = BaseScale();
		double f  = ElemScale("rs_score_hud_lives_scale");

		double pw    = LIFE_ART * f;
		double pitch = LIFE_PITCH * f;
		double rowW  = pitch * (drawn - 1) + pw;

		double x = AlignX(ox, rowW) + (CVInt("rs_score_hud_lives_x", 0) * bs);
		double y = oy + (CVInt("rs_score_hud_lives_y", DEF_LIVES_Y) * bs);

		// The most recent pip fades in; the rest are steady.
		int inT = FadeInTics();
		double newAlpha = ga;
		if (inT > 0)
			newAlpha = ga * Ease(double(now - livesStamp) / double(inT));

		uint tint = CVTint("rs_score_hud_lives_tint");

		for (int i = 0; i < drawn; i++)
		{
			double a = (i == drawn - 1) ? newAlpha : ga;
			Screen.DrawTexture(t, false, x + (i * pitch), y,
				DTA_DestWidthF, pw, DTA_DestHeightF, pw,
				DTA_Alpha, a, DTA_Color, tint);
		}

		// Past ten pips, show a count rather than an unreadable row.
		if (lives > LIVES_MAXDRAW)
		{
			Font fnt = SmallFont();
			if (fnt)
			{
				string txt = String.Format("x%d", lives);
				Screen.DrawText(fnt, PaletteColor(CVInt("rs_score_hud_col_lives", 1)),
					x + rowW + (2 * f), y, txt,
					DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, ga);
			}
		}
	}

	// =================================================================
	// THE SPREE COUNTER -- between the bar and the combo stack.
	//
	// Off by default: the streak is otherwise invisible state you have
	// to infer from the Spree bonus appearing, and showing it changes
	// how the readout reads. Drawn as text, not a bar. Its slot in the
	// layout is RESERVED whether it is on or not, so turning it on does
	// not shove the combo stack down.
	// =================================================================
	ui void DrawSpree(RS_ScorePlayer sp, double ox, double oy, int now, double ga)
	{
		if (sp.spreeCount < 2)
			return;

		int remaining = sp.spreeExpire - now;
		if (remaining <= 0)
			return;

		Font fnt = BigFont();
		if (!fnt)
			return;

		double a = StampAlpha(now, spreeStamp, remaining) * ga;
		if (a <= 0.0)
			return;

		string txt = SpreeText(sp);
		if (txt == "")
			return;

		double bs = BaseScale();
		double f  = ElemScale("rs_score_hud_spree_scale");

		// The counter pops on every kill that extends the streak.
		f *= PopScale(now - spreeStamp, FadeInTics());

		double tw = fnt.StringWidth(txt) * f;
		double x  = AlignX(ox, tw) + (CVInt("rs_score_hud_spree_x", 0) * bs);
		double y  = oy + (CVInt("rs_score_hud_spree_y", DEF_SPREE_Y) * bs);

		int idx = SpreeTierPalette(SpreeTier(sp.spreeCount));

		Screen.DrawText(fnt, PaletteColor(idx), x, y, txt,
			DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, a);
	}

	// 0 the streak length, 1 the multiplier it is currently worth,
	// 2 both. The multiplier is recomputed from the same cvars
	// RS_ScoreHandler.MultSpree uses, so the two cannot drift.
	ui string SpreeText(RS_ScorePlayer sp) const
	{
		int mode = clamp(CVInt("rs_score_hud_spree_mode", 0), 0, 2);

		if (mode == 0)
			return String.Format("x%d", sp.spreeCount);

		double inc = CVFloat("rs_score_m_spree", 0.025);
		double cap = CVFloat("rs_score_m_spree_max", 0.25);
		int pct = int(min(cap, inc * sp.spreeCount) * 100.0);

		if (mode == 1)
			return String.Format("+%d%%", pct);

		return String.Format("x%d  +%d%%", sp.spreeCount, pct);
	}

	// =================================================================
	// THE COMBO STACK -- below everything else.
	//
	// Two columns, both left-aligned at their own anchor, 43 virtual px
	// apart. The stack COMPACTS: `shown` only advances for a bonus that
	// actually paid, so there are never gaps where a quiet bonus would
	// have been.
	//
	// The popup lifetime uses RS_Score.zs's contract EXACTLY -- default
	// 105, clamp 35..350 (RS_Score.zs:1076). Reading it any other way is
	// what made popups vanish early or linger after the model had wiped
	// them. 0 means "off", which the model tolerates because its own
	// clamp floors at 35 and values still expire.
	// =================================================================
	ui void DrawBonuses(RS_ScorePlayer sp, double ox, double oy, int now, double ga)
	{
		Font fnt = SmallFont();
		if (!fnt)
			return;

		int life = CVInt("rs_score_bonustime", 105);
		if (life <= 0)
			return;
		life = clamp(life, 35, 350);

		int inT  = FadeInTics();
		int outT = FadeOutTics();

		double bs = BaseScale();
		double f  = ElemScale("rs_score_hud_combo_scale");

		int lineH  = clamp(CVInt("rs_score_hud_combo_lineh", COMBO_LINEH), 6, 40);
		int gap    = clamp(CVInt("rs_score_hud_combo_gap", COMBO_GAP), 8, 240);
		int maxRow = clamp(CVInt("rs_score_hud_combo_max", 8), 1, RS_ScoreDefs.RS_SB_COUNT);
		bool up    = CVBool("rs_score_hud_combo_up", false);

		double blockW = COMBO_BLOCK_W * bs;
		double amtX   = AlignX(ox, blockW) + (CVInt("rs_score_hud_combo_x", 0) * bs);
		double nameX  = amtX + (gap * bs);
		double baseY  = oy + (CVInt("rs_score_hud_combo_y", DEF_COMBO_Y) * bs);

		int nameCol = PaletteColor(CVInt("rs_score_hud_col_comboname", 1));
		int shown = 0;

		for (int i = 0; i < RS_ScoreDefs.RS_SB_COUNT; i++)
		{
			if (shown >= maxRow)
				break;

			if (i >= sp.bonusValue.Size())
				break;

			int val = sp.bonusValue[i];
			int t   = sp.bonusTime[i];

			if (val <= 0 || t < 0)
				continue;

			if (i == RS_ScoreDefs.RS_SB_BASE && !CVBool("rs_score_hud_showbase", true))
				continue;

			int flavor = RS_ScoreDefs.BonusFlavor(i);
			if (!FlavorVisible(flavor))
				continue;

			int age = now - t;
			double alpha = FadeCurve(age, life, inT, outT) * ga;
			if (alpha <= 0.0)
				continue;

			string nm  = RS_ScoreDefs.BonusName(i);
			string amt = String.Format("+%d", val);

			int col = PaletteColor(FlavorPalette(flavor));

			double ly = up
				? baseY - (shown * lineH * bs)
				: baseY + (shown * lineH * bs);

			// Only the amount pops; popping the name too makes the two
			// columns disagree about their baseline for a few tics.
			double pf = f * PopScale(age, inT);

			Screen.DrawText(fnt, col, amtX, ly, amt,
				DTA_ScaleX, pf, DTA_ScaleY, pf, DTA_Alpha, alpha);

			Screen.DrawText(fnt, nameCol, nameX, ly, nm,
				DTA_ScaleX, f, DTA_ScaleY, f, DTA_Alpha, alpha);

			shown++;
		}
	}
}
