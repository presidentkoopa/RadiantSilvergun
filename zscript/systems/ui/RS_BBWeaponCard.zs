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

class RS_BBWeaponCard
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

		RS_BBCompose.Text(p, cx - half + pad, cy, key, lineH,
			StatRGB(key), -1, cw * 0.56);
		RS_BBCompose.Number(p, numCx, cy, value,
			numW, lineH, Color(255, 245, 245, 240));
	}

	// -----------------------------------------------------------------
	// WHERE THE ART SITS, in panel-local units. Published as functions
	// rather than repeated as literals so the 3D card model and the flat
	// icon cannot drift apart -- they are the same slot, and a model half
	// an inch off the icon it replaces reads as a bug rather than as a
	// choice.
	// -----------------------------------------------------------------
	static double ArtLocalRight(double w) { return -w * 0.5 + (w * 0.30) * 0.5; }
	static double ArtLocalUp(double h)    { return h * 0.16; }

	// -----------------------------------------------------------------
	// heading: "MAINHAND", "OFFHAND", "DROP" -- which column this is.
	// -----------------------------------------------------------------
	static void Build(RS_BBComposedPanel p, double w, double h,
		Weapon wep, string heading)
	{
		if (!p || w <= 0 || h <= 0) return;

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
		double line = min(w, h) * 0.085;

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
		double idW  = w * 0.30;
		double idCx = -w * 0.5 + idW * 0.5;

		// A darker sub-plate so the identity block reads as its own region
		// rather than as text that happens to be on the left.
		RS_BBCompose.Plate(p, idCx, 0, idW * 0.94, h * 0.9,
			Color(255, 20, 20, 28));

		// Tier-filled header strip. The one place the tier is a solid fill
		// rather than an outline, which is what makes it the first thing
		// the eye lands on.
		let strip = RS_BBCompose.Plate(p, idCx, h * 0.42, idW * 0.94, h * 0.13, tier);
		if (strip) strip.SetGlow(0.7, 0.85);
		RS_BBCompose.Text(p, idCx, h * 0.42, "CLASS WEAPON", line * 0.62,
			Color(255, 10, 10, 14), 0, idW * 0.9);

		TextureID icon = wep.Icon;
		if (icon.IsValid())
		{
			RS_BBCompose.Picture(p, ArtLocalRight(w), ArtLocalUp(h), icon,
				idW * 0.78, h * 0.26, Color(255, 255, 255, 255));
		}

		let nameBB = RS_BBCompose.Text(p, idCx, -h * 0.14, wep.GetTag(), line * 1.05,
			Color(255, 240, 236, 228), 0, idW * 0.9);
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
		double gx0 = -w * 0.5 + idW;          // left edge of the grid area
		double gw  = w - idW;
		double cw  = gw / 4.0;
		double rowH = line * 1.62;
		// LAYOUT USES THE WHOLE CARD NOW. Fixed 2026-08-09.
		//
		// Measured before changing: content ran from +6.80 down to -3.71
		// on a card spanning -8.5..+8.5 -- 62% of the height, with the
		// bottom 4.8 units simply empty. That is what read as "needs
		// better use of space".
		//
		// Fractions of h rather than absolutes so it holds at any card
		// size the cvars produce.
		double gyTop = h * 0.30;

		Color faint = Color(255, 96, 92, 108);
		RS_BBCompose.Text(p, gx0 + gw * 0.03, h * 0.43, "STATS", line * 0.62,
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
		double sy = -h * 0.17;
		int socks = max(rsw.GunBonaiSockets, SocketsForTier(rsw.Tier));

		RS_BBCompose.Plate(p, gx0 + gw * 0.5, sy - h * 0.12, gw * 0.94, h * 0.34,
			Color(255, 22, 22, 30));
		RS_BBCompose.Text(p, gx0 + gw * 0.03, sy, "SOCKETS", line * 0.62,
			faint, -1, gw * 0.4);
		RS_BBCompose.Number(p, gx0 + gw * 0.94, sy, socks,
			gw * 0.10, line * 0.7, tier);

		// One pip per socket, in a row. Empty ones are drawn, not omitted:
		// seeing four slots with two filled is the whole point.
		double pipW = gw * 0.055;
		double pipY = sy - h * 0.10;
		for (int i = 0; i < socks && i < 5; i++)
		{
			double px = gx0 + gw * 0.06 + (pipW * 1.7) * i;
			RS_BBCompose.Plate(p, px, pipY, pipW, pipW,
				i < rsw.GunBonaiSockets ? tier : Color(255, 60, 58, 72));
		}

		// --- condition, the one stat with a live warning colour --------
		RS_BBCompose.Text(p, gx0 + gw * 0.94, -h * 0.40,
			rsw.Condition >= 80 ? "SOUND" : (rsw.Condition >= 40 ? "WORN" : "FAILING"),
			line * 0.62, ConditionRGB(rsw.Condition), 1, gw * 0.4);
	}
}
