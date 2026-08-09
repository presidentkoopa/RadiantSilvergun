// =====================================================================
// RS_BBImprintCard -- the IMPRINT offer card, composed of billboards.
// ---------------------------------------------------------------------
// The class-weapon card (RS_BBWeaponCard) is the template this follows
// for its vocabulary -- Plate/Text/Segment, tier colour from
// RS_TierPalette, stat colour from RS_BBWeaponCard.StatRGB. It is NOT
// the template for its CONTENT, and the difference is the whole reason
// this file exists:
//
//   A CLASS WEAPON REPLACES NOTHING. You are only offered one you do not
//   own, so there is no copy in hand to measure against and that card
//   deliberately shows plain values with no arrows.
//
//   AN IMPRINT REPLACES A NUMBER ON A GUN YOU ARE HOLDING, and it lands
//   on ONE HAND. The same package is worth a great deal on one of your
//   two weapons and nothing at all on the other, because it re-rolls
//   from a random family's bands (RS_Imprint.RollDonorClass) and, in the
//   default keep-better mode, only lifts the stats where those bands
//   happen to beat what you already have. So the MAINHAND-versus-OFFHAND
//   comparison is not a nicety on this card. It IS the decision, and the
//   two hand blocks are side by side for exactly that reason.
//
// WHAT IS ON IT, and what is deliberately not:
//
//   * only the stats the imprint actually MOVES, per hand, as old > new.
//     A row that reads "40 > 40" teaches nothing and costs a row out of
//     a very tight vertical budget. RS_Imprint.DirectionOn is the filter
//     and it is the same predicate ApplyTo uses, so the preview and the
//     result cannot disagree.
//   * each hand's socket count before > after, and each hand's CURRENT
//     fittings by name.
//   * WHICH FITTINGS DIE. If the imprint's tier grants fewer sockets
//     than that gun is using, the doomed ones are struck through in red
//     with a count. A player must be able to see what they are about to
//     lose before they commit, not discover it afterwards.
//   * NO ART SLOT. An imprint has no weapon model and no icon -- it is a
//     rolled stat package, not an object. Reserving a picture slot for
//     one would leave a permanent hole on every card. The DISC style's
//     emblem is drawn from the same primitives as everything else and
//     costs no texture.
//   * NO RECYCLE. Owner, 2026-08-08: "recycle is broken as a mechanic".
//     It was a third exit that PAID OUT, which made denying strictly
//     worse than destroying and turned every offer into an accounting
//     question. Four actions: OFFHAND, MAINHAND, REROLL, DENY.
//
// TWO LAYOUTS, ONE FILE, PICKED BY rs_imprintcard_style:
//
//   0  DISC -- a round identity disc fused to the LEFT EDGE of the body,
//      half in and half out. SHAPE IS THE FIRST READ: round means
//      imprint, rectangular means class weapon, and that lands before a
//      single word is legible. The disc costs 0.94h of width off the
//      data area, which is the price of the read.
//   1  FLAT -- a plain rectangle. No disc, every pixel spent on data,
//      hand blocks 36% wider than DISC's. The same nine rows either way.
//
// ---------------------------------------------------------------------
// NOTHING CALLS THIS YET, AND THAT IS DELIBERATE.
//
// RS_Panel.SyncBackend hardcodes `RS_BBWeaponCard.Build(...)` as the
// composed backend's layout call. Wiring an imprint through it means
// editing RS_Panel.zs, RS_EliteDrop.zs or RS_BBWeaponCard.zs -- all of
// which another session owns right now. This file is complete and
// self-contained; the hookup is one branch in SyncBackend when that
// session is done. Build()'s signature is shaped for it: same first
// three parameters as RS_BBWeaponCard.Build.
//
// ---------------------------------------------------------------------
// `play`, NOT a bare class. A class with no scope qualifier defaults to
// DATA scope. Build() reaches RS_GunBonsaiBridge.FittedNames and
// RS_Imprint.CanApplyTo, both play. RS_BBWeaponCard and RS_CardModelFor
// each cost a boot to the identical mistake on 2026-08-09.
//
// SUBMISSION ORDER IS DEPTH ORDER. Billboards do not depth-test against
// each other, so everything here draws strictly back to front, once, in
// one pass. That is also what makes the strike-through possible at all
// -- see Strike() below.
// =====================================================================

class RS_BBImprintCard play
{
	// =================================================================
	// STYLE. 0 = DISC, 1 = FLAT.
	//
	// Read through CVar.FindCVar rather than cached, matching every
	// accessor in RS_PanelController: a composed panel only lays out
	// when its content is marked dirty, so a cached value would need an
	// invalidation path that does not exist, and the cvar would appear
	// to do nothing until the next drop.
	// =================================================================
	static int Style()
	{
		let cv = CVar.FindCVar("rs_imprintcard_style");
		return cv ? clamp(cv.GetInt(), 0, 1) : 0;
	}

	// =================================================================
	// PALETTE.
	//
	// TIER COLOUR IS NEVER WRITTEN HERE. RS_TierPalette.RGB is the one
	// ladder in the tree -- four had drifted apart before it existed --
	// and PER-STAT colour comes from RS_BBWeaponCard.StatRGB so a stat
	// is the same colour on this card as on the weapon card. A player
	// who has learned that orange means ACC must not have to relearn it
	// one card over.
	//
	// What IS declared below is the delta/state vocabulary, which no
	// existing file owns in Color form (RS_DropTriptych's verdict
	// colours are Font.CR_ constants and cannot reach a billboard).
	// These are STATE colours, not tier colours -- the same distinction
	// RS_TierPalette's own header draws about Condition's bands -- and
	// they are deliberately off-hue from the ladder so a green delta
	// cannot be misread as a Common-tier swatch: the ladder's Common is
	// a hard (40,255,60), this is a softer (120,235,140).
	// =================================================================
	static Color UpRGB()    { return Color(255, 120, 235, 140); }
	static Color DownRGB()  { return Color(255, 232,  96,  84); }

	// The colour of a fitting that is about to be evicted, and of the
	// bar drawn across it. ONE red for both, on purpose: two reds would
	// read as two different severities when there is only one.
	static Color DoomRGB()  { return Color(255, 235,  70,  62); }

	static Color DimRGB()   { return Color(255, 150, 146, 158); }
	static Color FaintRGB() { return Color(255,  96,  92, 108); }
	static Color InkRGB()   { return Color(255, 240, 236, 228); }

	// Near-black, for text sitting ON a tier-filled plate. Not pure
	// black: a Basic weapon's tier colour is (235,235,240) and pure
	// black on near-white is harsher than anything else on the card.
	static Color PlateInkRGB() { return Color(255, 12, 12, 16); }

	// =================================================================
	// SHORT STAT KEYS.
	//
	// RS_Imprint.StatLabel returns the long form ("DAMAGE/PELLET"),
	// which is right for a full-width menu row and impossible in a
	// half-block stat cell. These are the SAME keys RS_BBWeaponCard's
	// 4x3 grid uses, so StatRGB answers for them and the colours match
	// across the two cards for free.
	//
	// CHOKE HAS NO KEY IN StatRGB AND THAT IS NOT AN OVERSIGHT ON MY
	// PART. "CHK" falls through to StatRGB's own grey default, which is
	// StatRGB's answer to an unknown key, not a colour invented here.
	// Inventing one would be a fifth colour table, which is the exact
	// disease RS_TierPalette was written to cure. If choke deserves a
	// colour it belongs in StatRGB, and that file is another session's.
	//
	// A switch, not `static const string k[] = {...}` -- that array form
	// does not reliably resolve on this engine build and has produced a
	// bogus "Unknown identifier" three separate times in this tree.
	// =================================================================
	static string StatKey(int i)
	{
		switch (i)
		{
			case RSIS_Damage:      return "DMG";
			case RSIS_Accuracy:    return "ACC";
			case RSIS_Velocity:    return "VEL";
			case RSIS_CritChance:  return "CRIT";
			case RSIS_CritMult:    return "CMUL";
			case RSIS_Capacity:    return "MAG";
			case RSIS_ReloadSpeed: return "RLD";
			case RSIS_Choke:       return "CHK";
			case RSIS_Sockets:     return "SOC";
			case RSIS_RateOfFire:  return "ROF";
		}
		return "?";
	}

	// Spelled out rather than a star-precision "%.*f": ZScript's
	// String.Format supports a subset of printf and star precision is
	// not part of it. Same shape as RS_DropTriptych.Cell, rewritten
	// rather than called because that class is on the supersede list
	// (see zscript.txt's RS_Slate note) and because its "--" absent case
	// is wrong here -- an empty hand gets a whole different block.
	static string Fmt(double v, int decimals)
	{
		if (decimals >= 2) return String.Format("%.2f", v);
		if (decimals == 1) return String.Format("%.1f", v);
		return String.Format("%d", int(v));
	}

	// =================================================================
	// A RING. The only round primitive in the whole system.
	//
	// RS_BBCompose has no Ring() helper and I must not add one (another
	// session owns that file), so this reproduces its private Raw():
	// created at the origin, because RS_BBComposedPanel.Place() is what
	// puts every part in the world and a part created at its final
	// position would duplicate the basis maths in two places.
	//
	// VERIFIED IN THE ENGINE, NOT ASSUMED, because two things about
	// BB_RING are not what its own declaration says:
	//
	//   * g_levellocals.h:117 documents `data` as "progress (low byte,
	//     0-255) | style bits". THE IMPLEMENTATION IGNORES data
	//     ENTIRELY -- hw_sprites.cpp:2227-2228 is one emit of the whole
	//     bbring texture. So data 0 draws a complete ring, not an empty
	//     one. Passing a progress here would do nothing and mislead the
	//     next reader.
	//   * it is a FAT ANNULUS, not an outline and not a disc.
	//     wadsrc/static/graphics/bbring.png is 128x128 with its alpha
	//     opaque from the rim in to radius 40 of 64 -- a band 37.5% of
	//     the radius thick, with a transparent hole 62.5% of the
	//     diameter across. That measurement is what sizes the disc's
	//     inner bed below; guessing it would have put the bed's corners
	//     out through the rim.
	//
	// Square w/h on purpose. The ring artwork stretches with the quad,
	// so a non-square BB_RING is an ellipse -- fine for some effects,
	// fatal for a shape whose entire job is to say "round".
	// =================================================================
	private static RS_Billboard Ring(RS_BBComposedPanel p, double x, double y,
		double d, Color col)
	{
		if (!p || d <= 0) return null;
		return p.Add(RS_Billboard.Make((0, 0, 0), d, d, 0, 0,
			LevelLocals.BB_RING, 0, col, LevelLocals.BBF_FIXED, 0, ""), x, y);
	}

	// =================================================================
	// STRIKE-THROUGH.
	//
	// There is no strike-through in BB_TEXT and there is no font style
	// bit to ask for one, so it is a thin plate laid ACROSS the name --
	// and the order is the entire trick. Billboards do not depth-test
	// against each other, so submission order is draw order: a plate
	// submitted BEFORE its text sits behind it (that is how every
	// backing plate on this card works), and the same plate submitted
	// AFTER the text lands on top of it. This must therefore be called
	// immediately after the Text it cancels, never before.
	//
	// WIDTH COMES FROM THE PLACED BILLBOARD, NOT FROM A GUESS.
	// RS_BBCompose.Text measures through the engine and SHRINKS a string
	// that will not fit its maxW, so the drawn width of a long affix
	// name is not the width you asked for. RS_Billboard.Width() reports
	// what was actually created. Re-deriving it from Measure() would be
	// right until the first name that had to shrink, and then silently
	// wrong on exactly the rows that matter most.
	//
	// THICKNESS, solved rather than picked. The card is read at 0.3 m,
	// and 34 units = 1 metre, so the eye is 10.2 units away and the
	// 1.7-unit card subtends 2*atan(0.85/10.2) = 9.5 degrees. One unit
	// is therefore about 5.6 degrees = 336 arcmin, and a body line
	// (0.0952 units) is ~32 arcmin. At 0.16 of a line the bar is ~5
	// arcmin -- right at the limit of what an eye resolves, which is
	// what a strike-through should be: unmistakable as a cancellation,
	// never mistaken for an underline or a row rule.
	// =================================================================
	private static void Strike(RS_BBComposedPanel p, RS_Billboard textBB,
		double xLeft, double y, double line)
	{
		if (!p || !textBB) return;
		double drawn = textBB.Width();
		if (drawn <= 0) return;
		RS_BBCompose.Plate(p, xLeft + drawn * 0.5, y, drawn, line * 0.16, DoomRGB());
	}

	// =================================================================
	// THE REROLL PRICE.
	//
	// Identical expression to RS_BBWeaponCard's action strip
	// (20 + tier * 15), because two offer cards quoting two different
	// prices for the same button is a bug the player finds before we do.
	// It is DUPLICATED rather than shared, and that is a wart worth
	// stating plainly: the honest fix is one static accessor on
	// RS_BBWeaponCard that both cards call, and RS_BBWeaponCard.zs is
	// owned by another session this run. If that formula ever changes,
	// it changes in two places until then.
	// =================================================================
	static int RerollCost(int tier)
	{
		return 20 + tier * 15;
	}

	// =================================================================
	// BUILD -- the entry point. Same first three parameters as
	// RS_BBWeaponCard.Build so the hookup in RS_Panel.SyncBackend is one
	// branch rather than a new plumbing shape.
	//
	// mainW / offW are the player's two live weapons. Either may be
	// null, a fist, or the empty-slot filler; the hand block handles all
	// three by asking RS_Imprint.CanApplyTo for the reason, so the card
	// prints the same sentence the take path would refuse with.
	// =================================================================
	static void Build(RS_BBComposedPanel p, double w, double h,
		RS_Imprint ip, RS_Weapon mainW, RS_Weapon offW)
	{
		if (!p || w <= 0 || h <= 0) return;

		if (Style() == 1) BuildFlat(p, w, h, ip, mainW, offW);
		else              BuildDisc(p, w, h, ip, mainW, offW);
	}

	// -----------------------------------------------------------------
	// Nothing to offer. Drawn rather than returned silently: a panel
	// that raised itself and then rendered nothing is indistinguishable
	// from a broken panel, and RS_Imprint.mRolled exists precisely so a
	// half-built package shows this instead of a wall of confident
	// zeroes.
	// -----------------------------------------------------------------
	private static bool Ground(RS_BBComposedPanel p, double w, double h,
		RS_Imprint ip, Color tier)
	{
		// FRAME OUTSIDE, GROUND INSIDE -- and the inset is deliberate.
		// RS_BBWeaponCard grows its frame to w*1.012 x h*1.022, which
		// puts the border OUTSIDE the panel's own declared size and
		// outside the rect the hinge solver and the aim ray reason
		// about. Same border thickness, achieved by shrinking the ground
		// instead, so every pixel of this card lives inside +/-0.5w and
		// +/-0.5h and the envelope the cvars promise is the envelope
		// that draws.
		let frame = RS_BBCompose.Plate(p, 0, 0, w, h, tier);
		if (frame) frame.SetGlow(0.55, 0.7);

		let ground = RS_BBCompose.Plate(p, 0, 0, w * 0.988, h * 0.978,
			Color(240, 14, 14, 20));
		// uObjectColor2's ALPHA is the on switch for the gradient, so
		// the second colour carries a real alpha deliberately.
		if (ground) ground.SetGradient(Color(200, 26, 24, 38));

		if (ip && ip.mRolled) return true;

		RS_BBCompose.Text(p, 0, 0, "IMPRINT -- NO PACKAGE", min(w, h) * 0.056,
			FaintRGB(), 0, w * 0.8);
		return false;
	}

	// =================================================================
	// STYLE 1 -- "FLAT". A plain rectangle, every pixel on data.
	// -----------------------------------------------------------------
	// THE VERTICAL LEDGER. h = 1.7 units, so the card runs -0.85..+0.85
	// and everything below is a fraction of h. Half-extents, because a
	// billboard is CENTRED on its position -- reasoning in centres alone
	// is how a row ends up half outside the card it fits "at".
	//
	//   band          centre     half        top        bottom
	//   title plate   +0.410h    0.070h      +0.480h    +0.340h
	//    title ln1    +0.443h    0.024h      +0.467h    +0.419h
	//    title ln2    +0.377h    0.024h      +0.401h    +0.353h
	//   body row 0    +0.296h    0.028h      +0.324h    +0.268h
	//   body row 8    -0.264h    0.028h      -0.236h    -0.292h
	//   action plate  -0.400h    0.065h      -0.335h    -0.465h
	//
	//   ground        +/-0.489h  (the outermost thing that is not the frame)
	//   card limit    +/-0.500h
	//
	//   title top    +0.480h < +0.489h ground   spare 0.009h = 0.015 units
	//   title bottom +0.340h > +0.324h row 0    gap   0.016h = 0.027 units
	//   row 8 bottom -0.292h > -0.335h action   gap   0.043h = 0.073 units
	//   action bot   -0.465h > -0.489h ground   spare 0.024h = 0.041 units
	//   both title lines sit inside [+0.340h, +0.480h]: 0.419>0.340 and
	//   0.467<0.480, 0.353>0.340 and 0.401<0.480.
	//
	//   NOTHING IS OUTSIDE +/-0.85 AND NO ROW TOUCHES ITS NEIGHBOUR.
	//
	// ROW STEP 0.070h, GLYPH 0.056h -> 0.014h = 0.024 units of air
	// between rows. Nine rows (0..8) is exactly the worst case the
	// content can produce -- see HandBlock's own budget note.
	//
	// LINE HEIGHT IS min(w,h)-DERIVED WHILE THE STEP IS h-DERIVED, and
	// that pairing is load-bearing rather than inherited style. At the
	// shipped 6.0 x 1.7 they are the same number, because h is the
	// shorter side. On a MISCONFIGURED PORTRAIT panel (an old ini
	// holding 40x80) min(w,h) becomes w, so the glyph SHRINKS relative
	// to a step that still follows h: the rows get airier, never
	// overlapping. Tying both to h would have grown the glyphs past the
	// step and collapsed the rows into each other, which is a defect you
	// cannot see the cause of. Degrade toward "wrong", never toward
	// "broken".
	// =================================================================
	private static void BuildFlat(RS_BBComposedPanel p, double w, double h,
		RS_Imprint ip, RS_Weapon mainW, RS_Weapon offW)
	{
		Color tier = ip ? RS_TierPalette.RGB(ip.mTier) : Color(255, 200, 200, 200);
		if (!Ground(p, w, h, ip, tier)) return;

		double line = min(w, h) * 0.056;

		// --- title band: the tier as a solid fill ---------------------
		// The one place on the card the tier is a FILL rather than an
		// outline, which is what makes it the first thing the eye lands
		// on -- the same trick RS_BBWeaponCard's identity strip plays,
		// widened to the whole card because an imprint has no icon and
		// no name of its own to share the space with.
		let strip = RS_BBCompose.Plate(p, 0, h * 0.410, w * 0.966, h * 0.140, tier);
		if (strip) strip.SetGlow(0.7, 0.85);

		// tx is the strip's inner edge on both sides. The strip is
		// w*0.966 wide (+/-0.483w), so anchoring the outer two lines at
		// +/-0.470w leaves a 0.013w margin inside it.
		//
		// THE THREE maxW VALUES ON LINE 1 ARE A PARTITION, NOT A GUESS.
		// Left starts at -0.470w and may run to -0.470w + 0.22w = -0.25w.
		// Centre is CENTRED, so 0.30w of allowance is +/-0.15w. Right
		// ends at +0.470w and may reach back to +0.470w - 0.28w = 0.19w.
		// The three intervals [-0.470,-0.25], [-0.15,+0.15], [0.19,0.470]
		// do not touch, so no string can reach its neighbour even if all
		// three are driven to their limit at once. Text() shrinks rather
		// than truncates, so hitting a limit costs size, never letters.
		double tx = w * 0.470;

		RS_BBCompose.Text(p, -tx, h * 0.443, "IMPRINT", line * 0.86,
			PlateInkRGB(), -1, w * 0.22);
		RS_BBCompose.Text(p, 0, h * 0.443, RS_UIStyle.TierName(ip.mTier),
			line * 1.05, PlateInkRGB(), 0, w * 0.30);
		// THE IMPRINT'S OWN HEADLINE NUMBER. Sockets come from its TIER
		// (RS_Imprint.Blank -> RS_Roll.SocketsForTier), never from the
		// roll, and they are the half of the offer that is not a stat.
		// The DISC style says the same thing with pips; this one has the
		// width to say it in words.
		RS_BBCompose.Text(p, tx, h * 0.443,
			"GRANTS " .. ip.mSockets .. " SOCKETS", line * 0.86,
			PlateInkRGB(), 1, w * 0.28);

		RS_BBCompose.Text(p, -tx, h * 0.377, ip.FamilyLine(), line * 0.78,
			PlateInkRGB(), -1, w * 0.34);
		RS_BBCompose.Text(p, tx, h * 0.377, ModeLine(), line * 0.78,
			PlateInkRGB(), 1, w * 0.44);

		// --- the two hand blocks, plus the actions --------------------
		// bodyCx 0 / bodyW w: FLAT spends the whole card on data, which
		// is the entire point of the style.
		Body(p, 0, w, h * 0.296, h * 0.070, line, ip, mainW, offW);
		Actions(p, 0, w, -h * 0.400, h * 0.130, line, ip);
	}

	// =================================================================
	// STYLE 0 -- "DISC". A round identity disc fused to the left edge.
	// -----------------------------------------------------------------
	// SHAPE IS THE FIRST READ AND IT IS THE POINT OF THIS STYLE. A
	// player crossing a room sees an outline before they see a glyph;
	// round means "package", rectangular means "gun". That read has to
	// survive the distance at which every word on the card is a smear.
	//
	// THE GEOMETRY, all of it a fraction of w and h:
	//
	//   disc diameter D  = 0.940h        (0.470h radius)
	//   disc centre x    = -0.5w + 0.470h    left edge touches the card's
	//   body plate left  = disc centre       HALF IN, HALF OUT
	//   body plate width = w - 0.470h
	//   body height      = 0.800h        the disc overhangs it by 0.070h
	//                                    top and bottom, which is what
	//                                    makes it read as fused rather
	//                                    than as a circle parked inside
	//                                    a rectangle
	//
	//   CONTENT IS INSET TO THE DISC'S RIGHT EDGE, NOT TO THE BODY'S
	//   LEFT EDGE, and getting this wrong is the trap in the whole
	//   style. The body plate starts at the disc's CENTRE, so the disc's
	//   right half lies on top of the first 0.470h of it. Laying the
	//   hand blocks out from the plate's edge put the left block's first
	//   0.70 units under the disc -- 29% of it covered, in a layout that
	//   passes every bounds check because nothing is outside the card.
	//
	//   content left  = -0.5w + 0.940h
	//   content width = w - 0.940h          = 4.402 at the shipped size
	//   content cx    = +0.470h
	//
	// THE VERTICAL LEDGER (h = 1.7):
	//
	//   band          centre     half        top        bottom
	//   ribbon        +0.362h    0.022h      +0.384h    +0.340h
	//   body row 0    +0.300h    0.024h      +0.324h    +0.276h
	//   body row 8    -0.180h    0.024h      -0.156h    -0.204h
	//   action plate  -0.325h    0.0525h     -0.2725h   -0.3775h
	//
	//   body ground   +/-0.3928h    body frame  +/-0.400h
	//   disc          +/-0.470h     card limit  +/-0.500h
	//
	//   ribbon top   +0.384h < +0.3928h ground   spare 0.0088h = 0.015 units
	//   ribbon bot   +0.340h > +0.324h row 0     gap   0.016h  = 0.027 units
	//   row 8 bottom -0.204h > -0.2725h action   gap   0.0685h = 0.116 units
	//   action bot   -0.3775h > -0.3928h ground  spare 0.0153h = 0.026 units
	//   disc edge    +/-0.470h < +/-0.500h       spare 0.030h  = 0.051 units
	//
	//   NOTHING IS OUTSIDE +/-0.85 AND NO ROW TOUCHES ITS NEIGHBOUR.
	//
	// ROW STEP 0.060h, GLYPH 0.048h -> 0.012h = 0.020 units of air. Nine
	// rows (0..8), the same worst case FLAT budgets for, so both styles
	// share HandBlock unchanged and there is only one row budget in the
	// file to get right.
	//
	// WHAT THE STYLE COSTS, stated so nobody has to measure it later: a
	// hand block is 2.06 units wide here against FLAT's 2.80 -- 27%
	// narrower. Every string on the card is shrink-to-fit
	// (RS_BBCompose.Text measures and scales rather than truncating), so
	// the cost shows up as smaller text, never as a clipped word.
	// =================================================================
	private static void BuildDisc(RS_BBComposedPanel p, double w, double h,
		RS_Imprint ip, RS_Weapon mainW, RS_Weapon offW)
	{
		Color tier = ip ? RS_TierPalette.RGB(ip.mTier) : Color(255, 200, 200, 200);

		// Solved, not eyeballed, and written out because the two centres
		// are one factor apart and swapping them is invisible until the
		// card is in front of you:
		//   discCx  = -0.5w + R                left edge on the card's
		//   bodyCx  = (discCx + 0.5w) * 0.5    = R * 0.5
		//   content = (discCx + R) .. +0.5w    so contentCx = R
		// bodyCx is HALF of contentCx. The body plate reaches further
		// left than the content does, by exactly the disc's radius.
		double discR  = h * 0.470;
		double discCx = -w * 0.5 + discR;
		double bodyW  = w - discR;
		double bodyCx = discR * 0.5;
		double bodyH  = h * 0.800;

		// --- body plate ----------------------------------------------
		// Frame first, ground inside it. Same inset argument as FLAT's
		// Ground(): the border is made by shrinking what sits on top,
		// never by growing the frame past the envelope.
		let frame = RS_BBCompose.Plate(p, bodyCx, 0, bodyW, bodyH, tier);
		if (frame) frame.SetGlow(0.55, 0.7);

		let ground = RS_BBCompose.Plate(p, bodyCx, 0, bodyW * 0.986, bodyH * 0.982,
			Color(240, 14, 14, 20));
		if (ground) ground.SetGradient(Color(200, 26, 24, 38));

		if (!ip || !ip.mRolled)
		{
			RS_BBCompose.Text(p, bodyCx, 0, "IMPRINT -- NO PACKAGE",
				min(w, h) * 0.048, FaintRGB(), 0, bodyW * 0.8);
			return;
		}

		double line       = min(w, h) * 0.048;
		double contentW   = w - discR * 2.0;
		double contentCx  = discR;

		// --- ribbon: the two facts that are not per-hand --------------
		// Both are properties of the PACKAGE rather than of a hand, so
		// they belong above the split instead of being repeated in each
		// block. The socket grant is deliberately NOT here -- on this
		// style it is the disc's emblem, and saying it twice would waste
		// the one line the ribbon has.
		RS_BBCompose.Text(p, contentCx - contentW * 0.48, h * 0.362,
			ip.FamilyLine(), line * 0.92, DimRGB(), -1, contentW * 0.44);
		RS_BBCompose.Text(p, contentCx + contentW * 0.48, h * 0.362,
			ModeLine(), line * 0.92, FaintRGB(), 1, contentW * 0.50);

		Body(p, contentCx, contentW, h * 0.300, h * 0.060, line, ip, mainW, offW);
		Actions(p, contentCx, contentW, -h * 0.325, h * 0.105, line, ip);

		// --- THE DISC, drawn LAST -------------------------------------
		// After the body, because it overlaps it and submission order is
		// depth order. Drawn first it would be buried under the body
		// plate and the whole style would render as a plain rectangle
		// with a suspiciously wide left margin.
		Disc(p, discCx, discR, line, ip, tier);
	}

	// -----------------------------------------------------------------
	// THE DISC ITSELF: a bed, a rim, and what the imprint grants.
	//
	// THERE IS NO FILLED CIRCLE IN THE PAYLOAD SET, so the disc is
	// layered rather than drawn. BB_PANEL is a rounded RECT -- its
	// artwork, wadsrc/static/graphics/bbpanel.png, carries a corner
	// radius of 16 pixels in 128, so a square one is a rounded square
	// and nothing more -- and BB_RING is a hole. A bed under a rim gets
	// a disc out of the two: the rim's band covers the bed's corners and
	// they stop existing.
	//
	// EVERY NUMBER BELOW COMES OFF THE RING ARTWORK, MEASURED. bbring.png
	// is 128x128 and its alpha runs opaque from the rim inward to radius
	// 39 of 64, so:
	//
	//   rim band     0.61r .. 1.00r     (37.5% of the radius thick)
	//   CLEAR HOLE   0 .. 0.61r         everything readable lives here
	//
	// and the hole is what the layout is solved against, NOT the disc.
	// Sizing text to the disc's own radius was the first version of this
	// function and it put the top and bottom lines out under the rim,
	// where they render as words with their ends bitten off -- a defect
	// that looks like a font bug rather than a layout one.
	//
	//   bed 0.70d square: half-side 0.70r, so it reaches past the hole
	//   edge (0.61r) on all four sides and leaves no dark gap, while its
	//   corners land at 0.70r * 1.414 = 0.99r, just inside the rim's
	//   outer edge and therefore under the band. Bigger and four hard
	//   nubs poke out through the rim; smaller and a gap opens.
	//
	// TEXT INSIDE A CIRCLE IS CHORD-LIMITED. A line at height y has
	// 2*sqrt(hole^2 - y^2) of room, not 2*hole. With hole = 0.61r:
	//
	//   y = +/-0.30r   chord 2*sqrt(0.372 - 0.090) r = 1.06r   maxW 0.90r
	//   y =  0.00r     chord 1.22r                             maxW 1.10r
	//
	// THE EMBLEM IS THE SOCKET GRANT, and that is a deliberate promotion
	// from decoration to data. An imprint has no icon and must not
	// borrow one, so the emblem had to be drawn from primitives either
	// way -- and once it is being drawn anyway, a row of pips saying how
	// many sockets this package stamps in is worth infinitely more than
	// a concentric ring saying nothing. It is also the imprint's only
	// headline number that is not a stat.
	//
	// The family line is NOT on the disc. It is the longest string the
	// package owns ("rolled from super shotgun", 25 characters) and the
	// hole is the tightest space on the card; it lives on the body's
	// ribbon, which has a full content width to give it.
	// -----------------------------------------------------------------
	private static void Disc(RS_BBComposedPanel p, double cx, double r,
		double line, RS_Imprint ip, Color tier)
	{
		double d = r * 2.0;

		RS_BBCompose.Plate(p, cx, 0, d * 0.70, d * 0.70, Color(250, 16, 16, 22));

		// The rim after the bed, so it covers the bed's corners.
		let rim = Ring(p, cx, 0, d, tier);
		if (rim) rim.SetGlow(0.8, 0.9);

		RS_BBCompose.Text(p, cx, r * 0.30, "IMPRINT", line * 0.90,
			InkRGB(), 0, r * 0.90);

		let tierBB = RS_BBCompose.Text(p, cx, 0,
			RS_UIStyle.TierName(ip.mTier), line * 1.35, tier, 0, r * 1.10);
		if (tierBB) tierBB.SetGlow(0.45, 0.65);

		// --- the pip arc: how many sockets this stamps in -------------
		// Five is the ceiling (RS_Roll.SocketsForTier tops out there), so
		// the widest row is 4 gaps of 0.75 line plus one pip of 0.42 =
		// 3.42 line = 0.28 units at the shipped size, against a chord of
		// 0.81 units at this height. Half the room it could have.
		int socks = clamp(ip.mSockets, 0, 5);
		if (socks <= 0)
		{
			// TRASH AND BASIC GRANT NOTHING (SocketsForTier returns 0
			// below Common) and an empty arc is indistinguishable from a
			// draw failure. Say it in words instead -- a blank space is
			// never allowed to be the message.
			RS_BBCompose.Text(p, cx, -r * 0.30, "NO SOCKETS", line * 0.78,
				FaintRGB(), 0, r * 0.90);
		}
		else
		{
			double pipS = line * 0.42;
			double pitch = line * 0.75;
			double px0 = cx - pitch * (socks - 1) * 0.5;
			for (int i = 0; i < socks; i++)
				RS_BBCompose.Plate(p, px0 + pitch * i, -r * 0.30, pipS, pipS, tier);
		}
	}

	// -----------------------------------------------------------------
	// The one sentence that changes what every delta on this card means.
	//
	// Keep-better (rs_imprint_mode 0, the default) cannot lower a stat
	// or a tier -- RS_Imprint.ResultOn takes max() and ResultTier only
	// raises -- so "NEVER WORSE" is a FACT the card is entitled to
	// state, not a reassurance. Mode 1 ASSIGNS the tier, which is the
	// only way sockets ever shrink and therefore the only way a fitting
	// is ever evicted. A player looking at a struck-through affix needs
	// to see, in the same glance, which rule is producing it.
	// -----------------------------------------------------------------
	static string ModeLine()
	{
		return RS_Imprint.KeepBetter() ? "KEEP BETTER -- NEVER WORSE"
		                               : "STRAIGHT RE-ROLL -- CAN LOSE";
	}

	// =================================================================
	// THE BODY: two hand blocks side by side, and the rule between them.
	//
	// OFFHAND LEFT, MAINHAND RIGHT, and that is not arbitrary. The
	// actions read "<- OFFHAND" and "MAINHAND ->", so the arrows have to
	// point AT the block they act on or the strip is actively
	// misleading. It is also the Hand Law the triptych already
	// establishes -- point at the panel on your left to send the drop to
	// your left hand -- and a UI that reverses a spatial convention one
	// card later is worse than one that never had it.
	//
	// bodyCx/bodyW are the CONTENT rect, which is the whole card in FLAT
	// and the part clear of the disc in DISC. Everything below is a
	// fraction of those two, so one layout serves both styles.
	//
	//   inset  0.020 of the content width, each side
	//   gutter 0.026 of it, between the blocks
	//   block  (1 - 0.040 - 0.026) / 2 = 0.467 of it
	//   centres at bodyCx -/+ 0.2465 * width
	//     left  block spans [-0.480, -0.013] of the content rect
	//     right block spans [+0.013, +0.480]
	//   so the blocks cannot touch each other and cannot reach the edge.
	// =================================================================
	private static void Body(RS_BBComposedPanel p, double bodyCx, double bodyW,
		double yTop, double step, double line,
		RS_Imprint ip, RS_Weapon mainW, RS_Weapon offW)
	{
		double blockW = bodyW * 0.467;
		double offset = bodyW * 0.2465;

		// A hairline rule in the gutter. Cheap, and it is what makes the
		// two blocks read as a COMPARISON rather than as one long list
		// that happens to have a gap in it.
		RS_BBCompose.Plate(p, bodyCx, yTop - step * 4.0,
			bodyW * 0.004, step * 9.0, Color(190, 52, 50, 64));

		HandBlock(p, bodyCx - offset, blockW, yTop, step, line, ip, offW,  "OFFHAND");
		HandBlock(p, bodyCx + offset, blockW, yTop, step, line, ip, mainW, "MAINHAND");
	}

	// =================================================================
	// ONE HAND'S BLOCK.
	//
	// THE ROW BUDGET, AND WHY IT IS EXACTLY NINE.
	//
	//   row 0            the hand's name and the weapon in it        1
	//   stat rows        8 stats can be written by an imprint
	//                    (Damage Accuracy Velocity CritChance
	//                     CritMult Capacity ReloadSpeed Choke);
	//                    Sockets has its own row and RateOfFire is
	//                    never applied at all. Two per row:          4
	//   socket row       before > after, and the eviction count      1
	//   affix rows       five is the socket maximum
	//                    (RS_Roll.SocketsForTier tops out at 5).
	//                    Two per row, so three rows hold six:        3
	//                                                              ---
	//                                                                9
	//
	// The cursor advances only for rows that are actually drawn, so a
	// typical imprint -- keep-better moves two or three stats -- packs
	// upward and leaves the bottom of the block empty rather than
	// leaving holes in the middle.
	//
	// AND IT IS HARD-CLAMPED ANYWAY. `row` is checked against ROWS
	// before every draw, so adding a tenth stat to ERS_ImprintStat one
	// day makes the card DROP a row rather than write one over the
	// action strip. A layout that silently overflows is the failure this
	// whole ledger exists to prevent, and the clamp is what makes the
	// arithmetic above a guarantee instead of an expectation.
	// =================================================================
	private static void HandBlock(RS_BBComposedPanel p, double cx, double bw,
		double yTop, double step, double line,
		RS_Imprint ip, RS_Weapon wep, string label)
	{
		if (!p || !ip) return;

		int ROWS = 9;
		int row = 0;

		double left  = cx - bw * 0.5;
		double right = cx + bw * 0.5;

		// --- row 0: whose hand, and what is in it ---------------------
		// Label left, weapon right, and their allowances partition the
		// row: [0.03, 0.35] and [0.37, 0.97] of the block width. They
		// cannot meet even when both strings are driven to their limit.
		//
		// The pale blue is a ROLE colour -- which hand this is -- and is
		// deliberately off the tier ladder's saturated Uncommon blue
		// (60,120,255) so a heading can never be misread as a rarity.
		RS_BBCompose.Text(p, left + bw * 0.03, yTop, label, line * 0.92,
			Color(255, 150, 200, 255), -1, bw * 0.32);
		row++;

		// CanApplyTo IS THE GATE AND THE CARD USES THE SAME ONE.
		// It fills `reason` with the exact sentence the take path
		// refuses with, so a hand that cannot receive this imprint says
		// why here in the same words rather than in a second wording
		// that drifts. It also catches the three cases a plain null
		// check misses: the empty-slot filler (VR_Fist2 and its
		// descendants), a real fist, and the curse gate.
		string reason;
		bool ok = ip.CanApplyTo(wep, reason);

		if (!ok || !wep)
		{
			RS_BBCompose.Text(p, right - bw * 0.03, yTop,
				wep ? wep.GetTag() : "EMPTY", line * 0.86,
				FaintRGB(), 1, bw * 0.60);
			RS_BBCompose.Text(p, left + bw * 0.03, yTop - step,
				reason.Length() > 0 ? reason : "Nothing to imprint.",
				line * 0.86, DownRGB(), -1, bw * 0.94);
			return;
		}

		Color resTier = RS_TierPalette.RGB(ip.ResultTier(wep));
		let nameBB = RS_BBCompose.Text(p, right - bw * 0.03, yTop,
			wep.GetTag(), line * 0.86, resTier, 1, bw * 0.60);
		if (nameBB) nameBB.SetGlow(0.30, 0.45);

		// --- the moved stats, two per row -----------------------------
		// ONLY WHAT MOVES. DirectionOn is the filter, and it is derived
		// from the same predicate ApplyTo uses, so a row on this card
		// cannot promise a change the apply path will not make. Sockets
		// is skipped because it gets its own dedicated row below, and
		// RateOfFire because StatIsApplied is false for it -- it rides
		// on the package for display and is never written, being pinned
		// to the real fire-animation length.
		Array<int> moved;
		for (int i = 0; i < RSIS_COUNT; i++)
		{
			if (i == RSIS_Sockets) continue;
			if (!RS_Imprint.StatIsApplied(i)) continue;
			if (ip.DirectionOn(wep, i) == 0) continue;
			moved.Push(i);
		}

		double cw = bw * 0.5;

		// int, not uint. Array.Size() is unsigned and every use below is
		// mixed with signed row arithmetic (row + i / 2, and a subtraction
		// that can legitimately go negative before max() catches it).
		// Pulling it into an int once keeps every comparison and every
		// division signed, rather than relying on where the promotion
		// happens to land.
		int nMoved = moved.Size();

		if (nMoved == 0)
		{
			// AN IMPRINT THAT DOES NOTHING TO THIS HAND IS THE MOST
			// DECISION-RELEVANT THING THE CARD CAN SAY, and under
			// keep-better it is a very common answer -- a Trash package
			// landing on a gun that already beats it moves nothing at
			// all. Saying so outright is what stops the player reading
			// an empty column as a rendering failure.
			RS_BBCompose.Text(p, left + bw * 0.03, yTop - step * row,
				"NO STAT CHANGE", line * 0.86, FaintRGB(), -1, bw * 0.60);
			row++;
		}
		else
		{
			for (int i = 0; i < nMoved; i++)
			{
				int r = row + i / 2;
				if (r >= ROWS) break;

				int  k   = moved[i];
				int  dec = RS_Imprint.StatDecimals(k);
				double y = yTop - step * r;
				double ccx = (i % 2 == 0) ? (left + cw * 0.5) : (left + cw * 1.5);

				StatCell(p, ccx, cw, y, line, StatKey(k),
					Fmt(RS_Imprint.CurrentOn(wep, k), dec),
					Fmt(ip.ResultOn(wep, k), dec),
					ip.DirectionOn(wep, k));
			}
			row += (nMoved + 1) / 2;
		}

		// --- sockets, and who dies ------------------------------------
		// FittedNames is the same source RS_BBWeaponCard's socket rows
		// read, so the two cards cannot disagree about what is in a gun.
		//
		// KNOWN IMPRECISION, FLAGGED RATHER THAN PAPERED OVER: it
		// returns EVERY GunBonsai upgrade with level > 0, not just the
		// ten designed affixes -- RS_GunBonsaiBridge.CountActiveAffixes
		// filters to TFLV_Upgrade_RS_SlateBase and FittedNames does not.
		// So a gun carrying stat cards can list more fittings than it
		// has sockets. The weapon card has the same behaviour; matching
		// it is better than having two cards that count differently,
		// and the fix belongs in the bridge, which is not this file.
		if (row < ROWS)
		{
			Array<string> fitted;
			RS_GunBonsaiBridge.FittedNames(wep, fitted);

			int nFitted = fitted.Size();
			int before  = wep.GunBonaiSockets;
			int after   = int(ip.ResultOn(wep, RSIS_Sockets));
			int doomed  = max(0, nFitted - after);

			SocketRow(p, left, bw, yTop - step * row, line,
				before, after, doomed, resTier);
			row++;

			// SIX CELLS, TWO PER ROW, and the SIXTH IS SPENT ON THE
			// OVERFLOW MARKER WHEN THERE IS ONE.
			//
			// Five is the real ceiling (SocketsForTier tops out there),
			// so six cells is normally one spare -- but FittedNames can
			// return more than five (see the note above: it does not
			// filter to the designed affixes), and a card that shows the
			// first five of nine while implying that is all of them is
			// worse than one that admits it is truncating.
			//
			// The marker takes a CELL rather than a corner of the last
			// row. Written at the block's left edge it landed exactly on
			// top of the first affix name on that row -- the same
			// overlapping-neighbours failure RS_BBWeaponCard's stat grid
			// had, where two cells rendered as one unreadable string.
			// Owning a cell is what makes that impossible.
			int cap = 6;
			int shown = nFitted;
			int overflow = 0;
			if (nFitted > cap)
			{
				shown = cap - 1;
				overflow = nFitted - shown;
			}

			int survivors = nFitted - doomed;

			for (int i = 0; i < shown; i++)
			{
				int r = row + i / 2;
				if (r >= ROWS) break;

				double y   = yTop - step * r;
				double ccx = (i % 2 == 0) ? (left + cw * 0.5) : (left + cw * 1.5);

				// LAST FITTED, FIRST EVICTED. Nothing in the codebase
				// decides this yet -- RS_Imprint.ApplyTo does not touch
				// the upgrade bag at all, so no affix is currently
				// stripped when sockets shrink. This card therefore
				// PREVIEWS A RULE THAT IS NOT IMPLEMENTED, and LIFO is
				// the assumption it previews under. Flagged for the
				// owner rather than silently invented: if he wants
				// cheapest-first or player-chosen, this line and the
				// eventual strip code have to agree, and only he
				// decides which.
				AffixCell(p, ccx, cw, y, line, fitted[i], i >= survivors);
			}

			if (overflow > 0)
			{
				int r = row + shown / 2;
				if (r < ROWS)
				{
					double ccx = (shown % 2 == 0) ? (left + cw * 0.5)
					                              : (left + cw * 1.5);
					RS_BBCompose.Text(p, ccx - cw * 0.5 + cw * 0.10,
						yTop - step * r, "+" .. overflow .. " MORE",
						line * 0.78, FaintRGB(), -1, cw * 0.86);
				}
			}

			// Kept current even though nothing reads it after this
			// point. A row cursor that stops being true the moment the
			// last section stops using it is a trap for whoever appends
			// the next section -- the arithmetic in this file's header
			// only holds while the cursor does.
			//
			// WORST CASE, END TO END: 1 heading + 4 stat + 1 socket + 3
			// affix = 9 = ROWS. The last cell lands on row index 8,
			// which is the last row the vertical ledger budgets for.
			row += (shown + (overflow > 0 ? 1 : 0) + 1) / 2;
		}
	}

	// =================================================================
	// ONE STAT CELL: label, old, arrow, new.
	//
	// THE HORIZONTAL LEDGER, in fractions of the cell width cw. These
	// are BOX extents, and a box is what matters: BB_SEGMENT fits its
	// string inside the box it is handed (hw_sprites.cpp:2163 caps the
	// cell at 0.88 of the box width divided by the character count, and
	// again at 0.62 of its height), so the ink is always NARROWER than
	// the box and centred in it. Non-overlapping boxes therefore
	// guarantee non-overlapping ink, whatever the values turn out to be.
	//
	//   label   [0.040, 0.320]  Text, align -1, maxW 0.28
	//   old     [0.350, 0.550]  Segment box centred at 0.45, width 0.20
	//   arrow   [0.585, 0.645]  Text, align 0 at 0.615, maxW 0.06
	//   new     [0.670, 0.930]  Segment box centred at 0.80, width 0.26
	//
	//   gaps 0.030 / 0.035 / 0.025 of cw, right margin 0.070 of cw.
	//   Every one of those is an allowance, not a measurement: each
	//   string may be driven to the full width of its interval and the
	//   intervals still do not touch.
	//
	// THE ARROW IS BB_TEXT AND MUST STAY BB_TEXT. '>' has no
	// sixteen-segment mask -- hw_sprites.cpp's SegmentMask returns 0 for
	// it, and 0 is the shader's PLATE sentinel, so a '>' pushed through
	// BB_SEGMENT draws a bare plate with nothing on it. Verified in the
	// table, not assumed. The SDF atlas covers ASCII 32..126
	// (tools/sdffont/mksdf.ps1 line 98), so '>' is there.
	//
	// NEW IS COLOURED BY DIRECTION, OLD IS ALWAYS DIM. Colour is the
	// verdict; the label's own stat colour identifies the row and the
	// delta colour judges it, and those two jobs never share a glyph.
	// =================================================================
	private static void StatCell(RS_BBComposedPanel p, double ccx, double cw,
		double y, double line, string key, string oldS, string newS, int dir)
	{
		double x0 = ccx - cw * 0.5;

		let lbl = RS_BBCompose.Text(p, x0 + cw * 0.04, y, key, line * 0.86,
			RS_BBWeaponCard.StatRGB(key), -1, cw * 0.28);
		// The per-stat colour is how a stat is found without reading the
		// word, and glow is what makes a colour carry at distance.
		if (lbl) lbl.SetGlow(0.25, 0.45);

		RS_BBCompose.Segment(p, x0 + cw * 0.45, y, oldS,
			cw * 0.20, line * 0.86, DimRGB(), 0.20, 0.35);

		RS_BBCompose.Text(p, x0 + cw * 0.615, y, ">", line * 0.80,
			FaintRGB(), 0, cw * 0.06);

		RS_BBCompose.Segment(p, x0 + cw * 0.80, y, newS,
			cw * 0.26, line * 0.92,
			dir >= 0 ? UpRGB() : DownRGB(), 0.35, 0.65);
	}

	// =================================================================
	// THE SOCKET ROW -- before > after, and the bill.
	//
	// THE HORIZONTAL LEDGER, in fractions of the block width bw:
	//
	//   "SOC"   [0.030, 0.130] Text, align -1, maxW 0.10
	//   before  [0.155, 0.245] Segment box centred at 0.20, width 0.09
	//   arrow   [0.265, 0.305] Text, align 0 at 0.285, maxW 0.04
	//   after   [0.330, 0.420] Segment box centred at 0.375, width 0.09
	//   evicted [0.470, 0.970] Text, align +1 at 0.97, maxW 0.50
	//
	//   gaps 0.025 / 0.020 / 0.025 / 0.050 of bw. Nothing touches.
	//
	// SOCKETS ONLY EVER SHRINK IN MODE 1, and knowing that is what makes
	// the eviction line worth building. Keep-better takes
	// max(imprint tier, weapon tier) so the count can only rise; the
	// STRAIGHT RE-ROLL mode ASSIGNS the tier, so a Trash package on a
	// Prototype gun takes it from five sockets to zero and every fitting
	// on it is condemned. That case is rare, opt-in, and the single most
	// expensive mistake the player can make on this card -- which is
	// exactly why it gets a red count and not a footnote.
	// =================================================================
	private static void SocketRow(RS_BBComposedPanel p, double left, double bw,
		double y, double line, int before, int after, int doomed, Color resTier)
	{
		let lbl = RS_BBCompose.Text(p, left + bw * 0.03, y, "SOC", line * 0.86,
			RS_BBWeaponCard.StatRGB("SOC"), -1, bw * 0.10);
		if (lbl) lbl.SetGlow(0.25, 0.45);

		RS_BBCompose.Segment(p, left + bw * 0.20, y, "" .. before,
			bw * 0.09, line * 0.86, DimRGB(), 0.20, 0.35);

		RS_BBCompose.Text(p, left + bw * 0.285, y, ">", line * 0.80,
			FaintRGB(), 0, bw * 0.04);

		RS_BBCompose.Segment(p, left + bw * 0.375, y, "" .. after,
			bw * 0.09, line * 0.92,
			after < before ? DownRGB() : resTier, 0.35, 0.65);

		if (doomed > 0)
		{
			// "" .. FIRST. A concatenation whose LEFT operand is an int is
			// not a string expression, and this project has been bitten by
			// the same class of type error before (GetClassName() returns a
			// Name, not a String). Costs nothing to be certain.
			RS_BBCompose.Text(p, left + bw * 0.97, y,
				"" .. doomed .. " AFFIX EVICTED", line * 0.86,
				DoomRGB(), 1, bw * 0.50);
		}
	}

	// =================================================================
	// ONE FITTED AFFIX.
	//
	//   pip     centred at 0.05 of cw, square, 0.36 of a line on a side
	//   name    [0.10, 0.96] of cw, Text align -1, maxW 0.86
	//
	// The pip is the fastest "how many" read on the block and the name
	// is what teaches a first-time player what a socket actually does --
	// the same pairing RS_BBWeaponCard settled on after its anonymous
	// dots proved uncountable AND unreadable.
	//
	// A DOOMED FITTING IS RED AND STRUCK, BOTH. Either alone is
	// ambiguous: red on its own reads as "warning", a bar on its own
	// reads as an underline. Together they read as cancelled, which is
	// the only thing they can mean. The strike goes in AFTER the name --
	// see Strike() for why that ordering is the whole mechanism.
	// =================================================================
	private static void AffixCell(RS_BBComposedPanel p, double ccx, double cw,
		double y, double line, string nm, bool doomed)
	{
		double x0 = ccx - cw * 0.5;
		double pipS = line * 0.36;

		RS_BBCompose.Plate(p, x0 + cw * 0.05, y, pipS, pipS,
			doomed ? DoomRGB() : Color(255, 70, 66, 84));

		let bb = RS_BBCompose.Text(p, x0 + cw * 0.10, y, nm, line * 0.82,
			doomed ? DoomRGB() : InkRGB(), -1, cw * 0.86);

		if (doomed) Strike(p, bb, x0 + cw * 0.10, y, line);
	}

	// =================================================================
	// THE ACTION STRIP -- four exits, and no fifth.
	//
	//   "<- OFFHAND"   send it to the left hand
	//   "MAINHAND ->"  send it to the right hand
	//   "REROLL <n>g"  pay to throw the dice again
	//   "DENY"         walk away
	//
	// THERE IS NO RECYCLE. Owner, 2026-08-08: it was a third exit that
	// PAID OUT, which made denying strictly worse than destroying and
	// turned every offer into an accounting question rather than a
	// choice. It is not "not built yet"; it is killed.
	//
	// THE ARROWS POINT AT THEIR OWN BLOCK. "<- OFFHAND" sits under the
	// offhand column and "MAINHAND ->" under the mainhand one, so the
	// strip is a legend for the layout rather than a second thing to
	// memorise. Reverse either and the card is worse than unlabelled.
	//
	// THE HORIZONTAL LEDGER, in fractions of the content width bw:
	//
	//   margin 0.020 each side, gap 0.018 between buttons
	//   button (1 - 0.040 - 3*0.018) / 4 = 0.2265
	//   centre step = 0.2265 + 0.018 = 0.2445
	//   first centre  -0.36675, last centre +0.36675 -- symmetric, and
	//   0.36675 + 0.11325 = 0.480, so the outer edges land exactly on
	//   the 0.020 margin.
	//
	// DRAWN, NOT YET CLICKABLE, and that is the honest order to build
	// them in. The hit test already exists -- AimBillboard returns a hit
	// id AND the UV across the face -- so wiring these is a UV-to-region
	// map rather than new machinery. A button you can see and not press
	// is honest; a button that silently does nothing is not.
	// =================================================================
	private static void Actions(RS_BBComposedPanel p, double bodyCx, double bw,
		double y, double bh, double line, RS_Imprint ip)
	{
		double btnW = bw * 0.2265;
		double stepX = bw * 0.2445;
		double x0 = bodyCx - bw * 0.36675;

		Color takeC = Color(255, 150, 235, 170);
		Color goldC = Color(255, 255, 205,  40);
		Color denyC = Color(255, 200, 120, 108);

		RS_BBCompose.Plate(p, x0, y, btnW, bh, Color(210, 24, 32, 26));
		RS_BBCompose.Text(p, x0, y, "<- OFFHAND", line * 0.86,
			takeC, 0, btnW * 0.90);

		RS_BBCompose.Plate(p, x0 + stepX, y, btnW, bh, Color(210, 24, 32, 26));
		RS_BBCompose.Text(p, x0 + stepX, y, "MAINHAND ->", line * 0.86,
			takeC, 0, btnW * 0.90);

		RS_BBCompose.Plate(p, x0 + stepX * 2.0, y, btnW, bh, Color(210, 34, 30, 14));
		RS_BBCompose.Text(p, x0 + stepX * 2.0, y,
			"REROLL " .. RerollCost(ip ? int(ip.mTier) : 0) .. "g",
			line * 0.82, goldC, 0, btnW * 0.92);

		RS_BBCompose.Plate(p, x0 + stepX * 3.0, y, btnW, bh, Color(210, 34, 20, 20));
		RS_BBCompose.Text(p, x0 + stepX * 3.0, y, "DENY", line * 0.86,
			denyC, 0, btnW * 0.90);
	}
}
