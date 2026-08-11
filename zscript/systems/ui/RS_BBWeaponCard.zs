// =====================================================================
// RS_BBWeaponCard -- the class-weapon offer card, composed of billboards.
// ---------------------------------------------------------------------
// Rebuilt 2026-08-08 against the owner's mockup. What changed and why,
// because every one of these was a decision he made out loud:
//
//   SQUAT AND WIDE, NOT PORTRAIT. A stat row is a short label and a
//   number; it wants horizontal room. The old card was a tall column of
//   twelve rows, which forced long labels and made them overflow.
//
//   THE STATS ARE A 4x3 GRID. Twelve stats down one column is what made
//   the card tall in the first place. Four columns of three is what makes
//   it wide by construction, and it is why short labels stopped being a
//   compromise -- nothing can run off the edge any more.
//
//   COLUMN ORDER IS HIS, not alphabetical and not the order the fields
//   happen to be declared in:
//       1  DMG ROF DPS     DPS sits under the two it is computed from
//       2  ACC MAG RLD
//       3  PLT VEL CND
//       4  CRIT CMUL SOC   the crit pair stacked
//
//   ONE COLOUR PER STAT, constant on every card, so a stat is found by
//   colour and the word stops being read. Values come from his own
//   HF_ColorConfig. This is also what keeps the card legible when it is
//   small: the colour survives the glyph.
//
//   NO COMPARISON. A class weapon replaces nothing -- you are only ever
//   offered one you do not own, so there is never a copy in hand to
//   measure against. Plain values, no arrows. Inventing a baseline would
//   be showing a comparison that cannot exist.
//
//   SOCKETS SAY WHAT A FITTING DOES. A name alone teaches nothing the
//   first time you meet it. Empty sockets are listed too, so the count
//   is visible rather than implied.
//
// TIER COLOUR COMES FROM RS_TierPalette AND NOWHERE ELSE. This file used
// to carry its own ladder, one of four in the tree that had drifted apart.
//
// SUBMISSION ORDER IS DEPTH ORDER. Billboards do not depth-test against
// each other, so a plate drawn after the text it should sit behind will
// erase it. Everything here draws back to front, once, in one pass.
// =====================================================================

// `play`, NOT a bare class. A class with no scope qualifier defaults to
// DATA, and Build() now reaches RS_GunBonsaiBridge.FittedNames -- a play
// function -- to read what is actually fitted in each socket. Second
// time today: RS_CardModelFor had the identical fault.
class RS_BBWeaponCard play
{
	// ONE COLOUR PER STAT. Owner's HF_ColorConfig values, verbatim.
	// Switch, not a static array -- `static const TYPE n[] = {...}` does
	// not reliably resolve on this engine build.
	static Color StatRGB(string key)
	{
		if (key == "DMG")  return Color(255, 255,  90,  90);
		if (key == "ROF")  return Color(255, 255, 205,  40);
		if (key == "DPS")  return Color(255, 110, 230,  90);
		if (key == "ACC")  return Color(255, 255, 150,  70);
		if (key == "MAG")  return Color(255,  60, 210, 210);
		if (key == "RLD")  return Color(255, 210, 100, 255);
		if (key == "PLT")  return Color(255,  90, 170, 255);
		if (key == "VEL")  return Color(255, 180, 120, 255);
		if (key == "CND")  return Color(255, 180, 192, 204);
		if (key == "CRIT") return Color(255, 255,  90, 160);
		if (key == "CMUL") return Color(255, 255, 180,  60);
		if (key == "SOC")  return Color(255,  46, 210, 140);
		return Color(255, 200, 200, 200);
	}

	static Color TierRGB(int t)
	{
		return RS_TierPalette.RGB(t);
	}

	static Color ConditionRGB(double cnd)
	{
		if (cnd >= 80.0) return Color(255,  80, 220,  90);
		if (cnd >= 40.0) return Color(255, 235, 210,  70);
		return Color(255, 230,  70,  60);
	}

	// How many affix sockets a tier grants.
	static int SocketsForTier(int t)
	{
		if (t >= VRT_Prototype) return 5;
		if (t >= VRT_Advanced)  return 4;
		if (t >= VRT_Uncommon)  return 2;
		return 1;
	}

	// -----------------------------------------------------------------
	// One cell of the stat grid: coloured label on the left of the cell,
	// value hard right. cw is the cell's own width, so the label clips to
	// its cell and can never reach its neighbour.
	// -----------------------------------------------------------------
	private static void Cell(RS_BBComposedPanel p, double cx, double cy,
		double cw, double lineH, string key, int value)
	{
		// EVERY PIECE STAYS INSIDE ITS OWN CELL. Fixed 2026-08-08 after
		// seeing it in game: the value was centred at 0.94 of the half-
		// width, which put its RIGHT edge at 0.94*half + numHalf -- past
		// the cell boundary -- so column 4's number hung off the panel
		// entirely, and every other column's number landed on top of the
		// NEXT column's label. That is what rendered as "1CRIT" and
		// "3RLD": two cells overlapping, not one string.
		//
		// 56/26 with a 0.04 pad each side, solved rather than guessed: it
		// is the widest label allocation that still fits FOUR characters
		// (CRIT and CMUL are the longest keys) while leaving a 0.52-unit
		// gap before the number. 52/30 fitted only three and would have
		// clipped CRIT to CRI.
		//
		// Now the label owns the left 56% and the value is RIGHT-ALIGNED
		// against the cell's inner edge, with a real gap between them.
		// A BB_DIGITS billboard is CENTRED on its position, so the centre
		// has to be pulled in by half its own width plus the margin --
		// placing it at the edge would hang half the number over.
		double half   = cw * 0.5;
		double pad    = cw * 0.04;
		double numW   = cw * 0.26;
		double numCx  = cx + half - pad - numW * 0.5;

		let lbl = RS_BBCompose.Text(p, cx - half + pad, cy, key, lineH,
			StatRGB(key), -1, cw * 0.56);
		// A little glow on the label so the per-stat colour reads as lit
		// rather than printed -- it is the colour that lets you find a
		// stat without reading the word, and glow is what makes a colour
		// carry at distance.
		if (lbl) lbl.SetGlow(0.25, 0.45);
		// SEGMENT, NOT DIGITS. BB_DIGITS is a raster glyph quad -- a
		// picture of a number that goes blocky up close and cannot glow.
		// BB_SEGMENT is shader arithmetic: sharp at any size, no font
		// involved, and it takes the glow that makes the readouts in the
		// reference shots read as lit rather than printed.
		RS_BBCompose.Segment(p, numCx, cy, "" .. value,
			numW, lineH, Color(255, 245, 245, 240), 0.30, 0.55);
	}

	// -----------------------------------------------------------------
	// WHERE THE ART SITS, in panel-local units. Published as functions
	// rather than repeated as literals so the 3D card model and the flat
	// icon cannot drift apart -- they are the same slot, and a model half
	// an inch off the icon it replaces reads as a bug rather than as a
	// choice.
	// -----------------------------------------------------------------
	// The action strip's centre line. A function rather than a constant
	// because the socket list has to know where it is in order to stop
	// before reaching it -- and a second copy of this number is exactly how
	// the two would drift apart.
	static double BTN_Y(double h) { return -h * 0.405; }

	// WHERE THE ART SITS. Read by RS_EliteDrop to place the spinning 3D
	// model, so these two are the ONE definition of that slot -- moving the
	// art means editing here and nowhere else, and the model follows.
	//
	// In the identity column, as the mockup has it. Briefly centred on
	// 2026-08-09 for a portrait card that turned out to be a misreading of
	// the mock -- reverted the same day.
	static double ArtLocalRight(double w) { return -w * 0.5 + (w * 0.30) * 0.5; }
	static double ArtLocalUp(double h)    { return h * 0.16; }

	// The slot's size, so the model and the icon agree without either one
	// guessing. RS_EliteDrop fits the model to this rather than re-deriving
	// it -- it used to spell out (w*0.30)*0.78 itself, a second copy that
	// would silently disagree the moment this moved.
	static double ArtLocalWidth(double w)  { return (w * 0.30) * 0.78; }
	static double ArtLocalHeight(double h) { return h * 0.26; }

	// -----------------------------------------------------------------
	// heading: "MAINHAND", "OFFHAND", "DROP" -- which column this is.
	// -----------------------------------------------------------------
	static void Build(RS_BBComposedPanel p, double w, double h,
		Weapon wep, string heading)
	{
		// A zero or negative size here draws NOTHING and returns silently,
		// which is indistinguishable from "the card never got called". Say
		// which it was.
		if (!p || w <= 0 || h <= 0)
		{
			RS_CardTrace.Fail(String.Format(
				"card Build refused: panel=%s w=%.3f h=%.3f "
				.. "(a size of zero means the panel was collapsed before layout)",
				p ? "ok" : "NULL", w, h));
			return;
		}

		let rsw = wep ? RS_Weapon(wep) : null;
		Color tier = rsw ? TierRGB(rsw.Tier) : Color(255, 200, 200, 200);
		// TEXT SIZE IS DERIVED FROM THE SHORTER SIDE, NOT FROM HEIGHT.
		//
		// This was h * 0.075, and h is the one dimension that changes most
		// between a correct card and a misconfigured one. On a portrait
		// panel (an old ini holding 40x80) that produced enormous glyphs on
		// a narrow card, and since a label is clipped to its own cell, the
		// budget collapsed to ONE CHARACTER per label -- the grid rendered
		// as "A / M / R" down a column and read as garbage rather than as
		// a layout that needed a cvar.
		//
		// Tying it to min(w, h) makes the card degrade legibly instead:
		// wrong proportions look wrong, they do not look broken.
		// 0.085, was 0.062. Text was small for the card it sat on -- the
		// old value was chosen while the grid was crammed into the middle
		// third and there was no room for anything bigger. Now that the
		// layout uses the full height, it can be.
		//
		// Safe to raise because Text() no longer approximates: it measures
		// through the engine and SHRINKS a string that will not fit, so an
		// over-large line degrades to "slightly smaller label" rather than
		// to a clipped word.
		// 0.062 of the SHORT side. Solved, not chosen: the right column
		// has to stack ten rows (a heading, three stat rows, a sockets
		// heading, five socket rows) plus an action strip inside the card
		// height, which gives a 0.078h step -- and a glyph taller than
		// ~0.82 of its step collides with the row above it.
		double line = min(w, h) * 0.062;

		// --- ground, then frame, then regions -------------------------
		// The frame is a tier-coloured plate one step larger than the
		// ground, so the border IS the tier. Cheapest possible "colour the
		// card by rarity" and it survives being far away, when nothing
		// else on the card is legible.
		// THE FRAME GLOWS AND THE GROUND GRADES. Added 2026-08-09 on the
		// sfd lane's SDF work -- both were impossible before it and are
		// why this card read as flat plates.
		//
		// Glow radius/strength are 0..1 and the engine clamps them, so the
		// spread-clipping artifact warned about in hw_sdffont.h cannot be
		// reached from script; that was measured in their offline preview
		// tool, where nothing clamps.
		let frame = RS_BBCompose.Plate(p, 0, 0, w * 1.012, h * 1.022, tier);
		if (frame) frame.SetGlow(0.55, 0.7);

		// The ground fades toward the tier colour at one end instead of
		// being one flat fill. uObjectColor2's ALPHA is the on switch, so
		// the second colour carries a real alpha deliberately.
		let ground = RS_BBCompose.Plate(p, 0, 0, w, h, Color(240, 14, 14, 20));
		if (ground) ground.SetGradient(Color(200, 26, 24, 38));

		if (!wep)
		{
			RS_BBCompose.Text(p, 0, 0, heading .. " EMPTY", line,
				Color(255, 130, 130, 130), 0, w * 0.9);
			return;
		}

		// --- identity column ------------------------------------------
		// The mockup's 150px-of-520 column, which is where w*0.30 comes
		// from. Do not "improve" this into a top band -- that was tried on
		// 2026-08-09 and it was a misreading of the mock.
		double idW  = w * 0.30;
		double idCx = -w * 0.5 + idW * 0.5;

		// A darker sub-plate so the identity block reads as its own region
		// rather than as text that happens to be on the left.
		RS_BBCompose.Plate(p, idCx, 0, idW * 0.94, h * 0.9,
			Color(255, 20, 20, 28));

		// Tier-filled header strip. The one place the tier is a solid fill
		// rather than an outline, which is what makes it the first thing
		// the eye lands on.
		//
		// PULLED IN TO SIT INSIDE ITS OWN PLATE. It was at h*0.42 with
		// height h*0.13, so its top edge landed at h*0.485 against a plate
		// that stops at h*0.45 -- the strip overhung the block it belongs
		// to. h*0.405 +/- h*0.045 sits wholly within it.
		let strip = RS_BBCompose.Plate(p, idCx, h * 0.405, idW * 0.94, h * 0.09, tier);
		if (strip) strip.SetGlow(0.7, 0.85);
		// HEADING, NOT A HARDCODED STRING. This read "CLASS WEAPON" on
		// every card, so the drop, the mainhand and the offhand were
		// indistinguishable -- three identical cards side by side, which
		// is exactly what the owner reported. `heading` has been a
		// parameter the whole time and was only used in the EMPTY case.
		RS_BBCompose.Text(p, idCx, h * 0.405, heading, line * 0.62,
			Color(255, 10, 10, 14), 0, idW * 0.9);

		TextureID icon = wep.Icon;
		if (icon.IsValid())
		{
			RS_BBCompose.Picture(p, ArtLocalRight(w), ArtLocalUp(h), icon,
				ArtLocalWidth(w), ArtLocalHeight(h), Color(255, 255, 255, 255));
		}

		// The weapon's name is the one line on this card that is allowed a
		// rolled face. Everything below it -- labels, numbers, socket names
		// -- stays on FONT_BODY, because a player reads those for accuracy
		// and a rolled face may be dotted, outlined or otherwise decorative.
		let nameBB = RS_BBCompose.Text(p, idCx, -h * 0.14, wep.GetTag(), line * 1.05,
			Color(255, 240, 236, 228), 0, idW * 0.9, RS_BBCompose.FONT_DISPLAY);
		if (nameBB) nameBB.SetGlow(0.35, 0.5);

		if (rsw)
		{
			RS_BBCompose.Text(p, idCx, -h * 0.27, RS_UIStyle.TierName(rsw.Tier),
				line * 0.72, tier, 0, idW * 0.9);

			// Level bar. Grows from the left, so only its right end moves.
			RS_BBCompose.Bar(p, idCx, -h * 0.40, 64,
				idW * 0.82, h * 0.055, tier);
		}

		if (!rsw)
		{
			// Outside the roll system -- an import, a vanilla leftover. Say
			// so rather than printing a column of zeroes, which would read
			// as the worst weapon ever generated.
			RS_BBCompose.Text(p, w * 0.18, 0, "NOT ROLLED", line,
				Color(255, 140, 140, 140), 0, w * 0.6);
			return;
		}

		// --- stat grid: 4 wide, 3 tall --------------------------------
		// THE MOCKUP'S GRID. Briefly replaced on 2026-08-09 by a column of
		// full-width rows from RS_CardContent, on the theory that twelve
		// numbers could not be made readable. Owner: "what happened to the
		// template? 4 x 3 and we had room for shit."
		//
		// He was right. The grid was never the problem -- the card being
		// 1.7 units tall was, and raising it to 2.7 buys the glyph height
		// without touching the layout. Restored verbatim.
		double gx0 = -w * 0.5 + idW;          // left edge of the grid area
		double gw  = w - idW;
		double cw  = gw / 4.0;
		double rowH = h * 0.078;
		// LAYOUT USES THE WHOLE CARD NOW. Fixed 2026-08-09.
		//
		// Measured before changing: content ran from +6.80 down to -3.71
		// on a card spanning -8.5..+8.5 -- 62% of the height, with the
		// bottom 4.8 units simply empty. That is what read as "needs
		// better use of space".
		//
		// Fractions of h rather than absolutes so it holds at any card
		// size the cvars produce.
		double gyTop = h * 0.382;

		Color faint = Color(255, 96, 92, 108);
		RS_BBCompose.Text(p, gx0 + gw * 0.03, h * 0.46, "STATS", line * 0.62,
			faint, -1, gw * 0.5);

		// Column 1 -- DMG ROF DPS. DPS last because it is the product of
		// the two above it, so the column reads as inputs then result.
		int dps = rsw.DamagePerShot * max(1, rsw.RateOfFire) * max(1, rsw.PelletCount);

		for (int col = 0; col < 4; col++)
		{
			double cx = gx0 + cw * (col + 0.5);
			for (int row = 0; row < 3; row++)
			{
				double cy = gyTop - rowH * row;
				string key = "";
				int val = 0;

				if (col == 0)
				{
					if (row == 0) { key = "DMG";  val = rsw.DamagePerShot; }
					if (row == 1) { key = "ROF";  val = rsw.RateOfFire; }
					if (row == 2) { key = "DPS";  val = dps; }
				}
				else if (col == 1)
				{
					if (row == 0) { key = "ACC";  val = int(rsw.Accuracy); }
					if (row == 1) { key = "MAG";  val = rsw.Capacity; }
					if (row == 2) { key = "RLD";  val = int(rsw.ReloadSpeed * 100.0); }
				}
				else if (col == 2)
				{
					if (row == 0) { key = "PLT";  val = rsw.PelletCount; }
					if (row == 1) { key = "VEL";  val = int(rsw.Velocity); }
					if (row == 2) { key = "CND";  val = int(rsw.Condition); }
				}
				else
				{
					if (row == 0) { key = "CRIT"; val = int(rsw.CritChance * 100.0); }
					if (row == 1) { key = "CMUL"; val = int(rsw.CritMult * 100.0); }
					if (row == 2) { key = "SOC";  val = rsw.GunBonaiSockets; }
				}

				if (key != "") Cell(p, cx, cy, cw, line, key, val);
			}
		}

		// --- sockets --------------------------------------------------
		// A sub-plate behind the list, so the sockets read as a separate
		// region from the numbers above them.
		double sy = h * 0.148;
		int socks = max(rsw.GunBonaiSockets, SocketsForTier(rsw.Tier));

		// How many socket rows there is actually room for, decided BEFORE the
		// plate is drawn so the plate can be sized to hold them. The old
		// order did the opposite -- a fixed h*0.40 plate and then up to five
		// rows poured into it -- and the fifth row fell straight through the
		// bottom onto bare card. Only ever visible on a Prototype, which is
		// the one time the card matters most.
		double rowY  = sy - h * 0.078;
		double rowH2 = h * 0.078;
		int sockRows = int((rowY - (BTN_Y(h) + h * 0.090)) / rowH2) + 1;
		sockRows = clamp(sockRows, 0, 5);

		int sockShown = min(socks, sockRows);

		// The plate WRAPS its content: from just above the header down to
		// just below the last row it will actually draw. A weapon with two
		// sockets gets a short plate rather than a tall one with a hole in
		// the bottom of it.
		double plTop = sy + h * 0.055;
		double plBot = rowY - rowH2 * max(0, sockShown - 1) - h * 0.045;
		RS_BBCompose.Plate(p, gx0 + gw * 0.5, (plTop + plBot) * 0.5,
			gw * 0.94, max(h * 0.10, plTop - plBot), Color(255, 22, 22, 30));

		RS_BBCompose.Text(p, gx0 + gw * 0.03, sy, "SOCKETS", line * 0.62,
			faint, -1, gw * 0.4);
		RS_BBCompose.Segment(p, gx0 + gw * 0.94, sy, "" .. socks,
			gw * 0.10, line * 0.7, tier, 0.35, 0.7);

		// NAMED ROWS, NOT ANONYMOUS PIPS. Rebuilt 2026-08-09 toward the
		// mockup: the card used to draw coloured dots, so you could count
		// your sockets but never read what was in them. A name is what
		// teaches a first-time player what a socket actually does -- the
		// owner picked this out of the mock specifically.
		//
		// Names come from the upgrade's own GetName() via the bridge, so
		// a renamed or newly added affix needs no entry anywhere here.
		Array<string> fitted;
		RS_GunBonsaiBridge.FittedNames(rsw, fitted);

		double pipW  = gw * 0.030;

		for (int i = 0; i < sockShown; i++)
		{
			double y = rowY - rowH2 * i;
			bool   filled = i < fitted.Size();

			// The pip stays -- it is the fastest read of "how many do I
			// have left" -- but it is now a bullet in front of a name
			// rather than the whole story.
			RS_BBCompose.Plate(p, gx0 + gw * 0.05, y, pipW, pipW,
				filled ? tier : Color(255, 60, 58, 72));

			RS_BBCompose.Text(p, gx0 + gw * 0.10, y,
				filled ? fitted[i] : "EMPTY",
				line * 0.72,
				filled ? tier : Color(255, 96, 92, 108),
				-1, gw * 0.84);
		}

		// --- THE ACTION STRIP -------------------------------------------
		// Three exits, as the mockup has them and as the owner ruled:
		// Take, Reroll for gold, Deny. There is deliberately NO Recycle --
		// owner, 2026-08-08: "recycle is broken as a mechanic". It was a
		// third exit that PAID OUT, which made denying strictly worse than
		// destroying and turned every offer into an accounting question.
		//
		// Drawn, not yet clickable. The hit test exists -- AimBillboard
		// returns a hit id AND the UV across the face -- so wiring these
		// is a UV-to-region map rather than new machinery. Drawing them
		// first is deliberate: a button you can see and not press is
		// honest, a button that silently does nothing is not.
		double btnY = BTN_Y(h);
		double btnH = h * 0.11;

		// WIDTH IS SOLVED, NOT CHOSEN. Fixed 2026-08-11.
		//
		// btnW was gw * 0.29, and three of those plus two gw * 0.045 gaps is
		// 0.96 of gw. The strip starts at gw * 0.06 and the card's right edge
		// is at gw * 1.00, so only 0.94 was available -- DENY overhung the
		// ground plate AND the tier frame by gw * 0.02 and drew in open air.
		// Small enough (1.4% of card width) to read as a rendering artifact
		// rather than a layout error, which is how it survived.
		//
		// Deriving the width from the span it has to fit means the two margins
		// and the gap are the only numbers anyone tunes, and the strip cannot
		// overhang again whatever they are set to.
		double btnMargin = 0.06;
		double btnGap = gw * 0.045;
		double btnSpan = gw * (1.0 - btnMargin * 2.0);
		double btnW = (btnSpan - btnGap * 2.0) / 3.0;
		double btnX0 = gx0 + gw * btnMargin;

		Color goldC = Color(255, 255, 205, 40);
		Color denyC = Color(255, 200, 120, 108);

		// PRESSABLE, NOT JUST DRAWN. Added 2026-08-11.
		//
		// These three were plates and text and nothing else, so the hit test
		// found the card, handed back a correct UV, and RS_PanelCard.RowAtUV
		// looked it up in a vertical row list that had no entry there. The
		// press landed in dead space with no error.
		//
		// Panel-local to UV: x runs -w/2..+w/2 left to right, y runs +h/2..-h/2
		// top to bottom, and UV is 0..1 with v increasing DOWNWARD -- matching
		// RowAtUV's `uv.y * CARD_H` and the engine's own UV convention.
		double bU0 = (btnY + btnH * 0.5);   // top edge in panel-local y
		double bU1 = (btnY - btnH * 0.5);   // bottom edge
		double v0  = (h * 0.5 - bU0) / h;
		double v1  = (h * 0.5 - bU1) / h;

		RS_BBCompose.Plate(p, btnX0 + btnW * 0.5, btnY, btnW, btnH,
			Color(210, 26, 30, 26));
		RS_BBCompose.Text(p, btnX0 + btnW * 0.5, btnY, "TAKE", line * 0.66,
			tier, 0, btnW * 0.9);
		// arg 1 = mainhand, matching what the wings used before solo mode
		// stopped building them (RS_DropTriptych: "rs-panel-take", 1).
		p.AddHitRegion((btnX0 + w * 0.5) / w, v0,
			(btnX0 + btnW + w * 0.5) / w, v1, "rs-panel-take", 1);

		double bx2 = btnX0 + btnW + btnGap;
		RS_BBCompose.Plate(p, bx2 + btnW * 0.5, btnY, btnW, btnH,
			Color(210, 34, 30, 14));
		RS_BBCompose.Text(p, bx2 + btnW * 0.5, btnY,
			"REROLL " .. (20 + int(rsw.Tier) * 15) .. "g", line * 0.62,
			goldC, 0, btnW * 0.92);
		p.AddHitRegion((bx2 + w * 0.5) / w, v0,
			(bx2 + btnW + w * 0.5) / w, v1, "rs-panel-reroll", 0);

		double bx3 = bx2 + btnW + btnGap;
		RS_BBCompose.Plate(p, bx3 + btnW * 0.5, btnY, btnW, btnH,
			Color(210, 34, 20, 20));
		RS_BBCompose.Text(p, bx3 + btnW * 0.5, btnY, "DENY", line * 0.66,
			denyC, 0, btnW * 0.9);
		p.AddHitRegion((bx3 + w * 0.5) / w, v0,
			(bx3 + btnW + w * 0.5) / w, v1, "rs-panel-deny", 0);

		// --- condition, the one stat with a live warning colour --------
		RS_BBCompose.Text(p, gx0 + gw * 0.94, h * 0.46,
			rsw.Condition >= 80 ? "SOUND" : (rsw.Condition >= 40 ? "WORN" : "FAILING"),
			line * 0.62, ConditionRGB(rsw.Condition), 1, gw * 0.4);
	}
}
