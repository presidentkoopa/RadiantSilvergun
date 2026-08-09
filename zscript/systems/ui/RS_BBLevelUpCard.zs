// =====================================================================
// RS_BBLevelUpCard -- THE WEAPON LEVEL-UP OFFER, IN THE WORLD.
// ---------------------------------------------------------------------
// The screen from zscript/LevelUpTemplate.txt, built out of billboard
// payloads instead of a painted canvas: a weapon levels up, several
// cards come up in front of you, you take exactly one.
//
// WHAT IS HERE, AND WHAT IS DELIBERATELY NOT
//
//   HERE   the CARD FACE (one composed panel per card) and TWO ways of
//          arranging N of them in the air, chosen by a cvar.
//   NOT    the level-up flow. Nothing in this file decides when a
//          weapon levels, what the offer contains, or what happens on
//          accept. RS_AffixInstall owns the offer; GunBonsai's giver
//          owns the moment; RS_BBCardPicker (RS_BillboardUI.zs) is the
//          flat-list version that exists today. This is a layout
//          library those call, not a second flow competing with them.
//
// THE COUNT IS NOT THREE. RS_AffixInstall.CardsForWeapon() is base 3,
// +1 per promotion, hard capped at 8 -- the owner's own range, stated
// out loud. LevelUpTemplate.txt draws three cards; that is an EXAMPLE
// of the screen, not its ceiling, and a layout that only works at three
// is a layout that breaks the first time somebody promotes a gun. Both
// styles below are solved for 1..8 and the arithmetic is written out
// where they are solved, so the next reader can check it without
// booting anything.
//
// ---------------------------------------------------------------------
// SIZED FOR ARM'S LENGTH. 34 map units = 1 metre, and this screen is
// assumed to be read at REACH = 26 units = 0.76 m -- a card held out in
// front of you, not a poster across the room.
//
// That number is a decision with a reason, not a taste: 0.76 m is at
// the outer edge of a seated player's reach, so the player can PUT A
// HAND ON the card they want. RS_PanelHandler's poke test
// (rs_panel_poke, 6 units off the face) then makes touch selection work
// with no new machinery at all. Push the screen out to the drop card's
// rs_panel_comfort (46 units, 1.35 m) and touch becomes impossible; pull
// it to 0.3 m and it is inside the near-clip discomfort zone and you go
// cross-eyed reading it.
//
// EVERY LENGTH IN THIS FILE IS MAP UNITS. Where a number is chosen by
// eye it is quoted in both, so the next reader can tell whether it is a
// real distance or a fudge.
//
// ---------------------------------------------------------------------
// FIVE ENGINE FACTS THIS FILE IS BUILT ON. Each cost somebody a boot.
//
//   * Strings are BB_TEXT (RS_BBCompose.Text) and numbers are
//     BB_SEGMENT (RS_BBCompose.Segment). BB_DIGITS and BB_GLYPH are
//     raster quads: blocky up close, no glow, and BB_DIGITS renders
//     multi-digit values BACKWARDS. Neither appears below.
//   * BB_SEGMENT IS A 16-SEGMENT DISPLAY AND ITS ALPHABET IS FINITE.
//     Verified in the engine, not assumed -- SegmentMask() at
//     src/rendering/hwrenderer/scene/hw_sprites.cpp:1964 covers 0-9,
//     A-Z (one case), and - _ = + * / \ | ' " ( ) [ ] ? ! . : and
//     nothing else. An unlisted character returns mask 0, which the
//     emitter SKIPS SILENTLY while still advancing the pen. So "-20%"
//     through Segment draws "-20" and a gap, with no error anywhere.
//     That is why Readout() below tests the string first and falls back
//     to Text -- see SegmentSafe().
//   * Plates are BB_PANEL textured quads. No rounded corners, no inset
//     shadow; nothing here is designed around either.
//   * NEVER add an argument to AddBillboard/AddBillboardPersistent/
//     AttachBillboard. At sixteen the ZScript compiler dies silently
//     mid-LoadActors. Glow and gradient are SETTERS on RS_Billboard for
//     exactly that reason.
//   * A class with no scope qualifier is DATA scope. Everything here is
//     `play` because it reads RS_Weapon fields and calls
//     RS_AffixInstall's play statics.
//
// TIER COLOUR COMES FROM RS_TierPalette AND NOWHERE ELSE. It appears on
// exactly one surface here (the banner, which is about the WEAPON) and
// never on a card, which is about an OFFER. Two vocabularies, never on
// the same plate -- the same discipline RS_TierPalette's own header
// applies to Condition's green/yellow/red.
// =====================================================================

// WHAT KIND OF THING A CARD IS OFFERING.
//
// Declared at file scope rather than nested in a class, following
// ERS_TriSlot's own note: every enum in this codebase (ERS_PanelFacing,
// EVR_Tier, ERS_TriSlot) sits at file scope, and a nested enum read from
// another file is exactly the resolution question that has cost this
// project a failed boot before.
//
// The five kinds and their colours are the roster docs/rs_10_ui_spec.txt
// already describes and RS_Screens.zs already draws in Font.CR_ form
// (white affix / orange mastery / green stat / purple combo / gold
// promote). This file gives those the same names in RGB because a
// billboard cannot take a Font.CR_ index. It is NOT a new ladder and it
// is NOT tier colour -- see the header.
//
// ONE STALE WORD IN THAT DOC, AND IT IS WORTH KNOWING BEFORE IT CONFUSES
// SOMEBODY: rs_10 calls the combo card "Designer-purple", written when
// Designer WAS purple. RS_TierPalette (the consolidation of four drifted
// ladders, and the authority) has Designer as YELLOW and ADVANCED as
// purple. The combo card here is purple because purple is what the
// design asked for, NOT because it is claiming a tier -- reading a tier
// off it would be reading the wrong one. If the owner wants these five
// to live in a shared table, that table does not exist yet and inventing
// one is his call, not this file's.
enum ERS_LevelUpKind
{
	RSLU_Affix     = 0,   // a GunBonsai upgrade or a designed affix
	RSLU_Mastery   = 1,   // an affix reaching its top level
	RSLU_Stat      = 2,   // a permanent stat purchase
	RSLU_Combo     = 3,   // two related stats, one card
	RSLU_Promotion = 4    // the cash-in
}

// =====================================================================
// RS_LevelUpOffer -- ONE CARD'S WORTH OF CONTENT, as plain data.
//
// The card face draws this and nothing else, so a caller can fill it
// from ANY source -- GunBonsai's candidate list, RS_AffixInstall's
// rolled bundles, a hand-written test -- without the layout knowing
// which. That is deliberate: this file must not become a second place
// where offers are decided.
//
// PLAIN DATA AND ONE RS TYPE. The bundle is Array<RS_AffixIngredient>
// because that is what RS_AffixInstall.AcceptOffer takes, so an accepted
// card can be installed with no translation step. There is deliberately
// no TFLV_ type anywhere in this file: RS_GunBonsaiBridge's header says
// it is the ONE place RS and the vendored system may reference each
// other's types, and a UI file quietly becoming the second one is how
// that rule dies.
// =====================================================================
class RS_LevelUpOffer play
{
	int    Kind;
	string Title;          // "SEEKER", "DAMAGE +3", "PROMOTE"
	string Body;           // plain language, wrapped by the card
	string Rank;           // "LV 3 -> 4", "* * o o o  ->  * * * o o", ""
	string MetricLabel;    // "DPS"      -- what you gain, named
	string MetricValue;    // "+12.4"    -- and measured
	string CostLabel;      // "COST"     -- what it takes, named
	string CostValue;      // "-20% STATS"
	Array<RS_AffixIngredient> Bundle;   // empty unless this is an affix roll

	static RS_LevelUpOffer Make(int kind, string title, string body)
	{
		let o = new("RS_LevelUpOffer");
		o.Kind  = kind;
		o.Title = title;
		o.Body  = body;
		return o;
	}

	// -----------------------------------------------------------------
	// AN AFFIX CARD, FROM A ROLLED BUNDLE.
	//
	// RS_AffixGenerator budgets a bundle to net PowerCost <= 0, so a
	// bundle that contains a real bonus contains a real drawback paying
	// for it. That structure is the card: the ingredient with the
	// highest cost is what you are being OFFERED, the lowest (if it is
	// negative) is what it COSTS you, and both are printed. A card that
	// showed only the upside would be lying by omission about a system
	// whose whole design is that the two are paired.
	//
	// Wording comes from RS_AffixInstall.DescribeIngredient -- which is
	// where that file's own header says it belongs, so a new ingredient
	// gets its sentence in the same edit that adds it, not here.
	// -----------------------------------------------------------------
	static RS_LevelUpOffer FromBundle(Array<RS_AffixIngredient> bundle)
	{
		if (bundle.Size() == 0)
			return null;

		int best = 0, worst = 0;
		for (int i = 1; i < bundle.Size(); i++)
		{
			if (bundle[i].PowerCost > bundle[best].PowerCost)  best = i;
			if (bundle[i].PowerCost < bundle[worst].PowerCost) worst = i;
		}

		let prime = bundle[best];

		// Held in locals, not chained. `Foo().MakeUpper()` -- a method
		// call on a function's return value -- is the kind of construct
		// that either compiles or costs a boot to find out, and this
		// file cannot be built this session. Locals are boring, and the
		// same reasoning RS_PanelHandler gives for its scratch fields.
		string ident = RS_AffixInstall.StripLevel(prime.Value);
		string cat   = prime.Category;
		string identU = ident.MakeUpper();
		string catU   = cat.MakeUpper();

		let o = Make(RSLU_Affix, identU,
			RS_AffixInstall.DescribeIngredient(prime));

		// The category is the honest one-word answer to "what sort of
		// change is this" -- payload, behavior, drawback -- and it is on
		// the ingredient already rather than being guessed from wording.
		o.MetricLabel = catU;
		o.MetricValue = identU;

		if (worst != best && bundle[worst].PowerCost < 0)
		{
			string down  = RS_AffixInstall.StripLevel(bundle[worst].Value);
			o.CostLabel = "COST";
			o.CostValue = down.MakeUpper();
			// The drawback's own sentence rides in the body under the
			// upside, because "COST: HEAVY" tells you the name of the
			// price and not what paying it feels like.
			o.Body = o.Body .. "  --  " ..
				RS_AffixInstall.DescribeIngredient(bundle[worst]);
		}

		o.Bundle.Copy(bundle);
		return o;
	}

	// -----------------------------------------------------------------
	// THE PROMOTION CASH-IN, as a card.
	//
	// Every number below is READ, not invented: RS_Screens.zs's own
	// promotion confirm (BuildPromotionConfirm) is the authority on what
	// promotion costs and pays, and this says the same things in the
	// space a card has. If those two ever disagree, the confirm screen
	// is right and this is the bug -- it is the screen with the button.
	//
	// Returns null off Prototype. docs/rs_10_ui_spec.txt is where the
	// "Prototype only" gate comes from; RS_Screens.zs enforces the same
	// thing in code ("Prototype tier required to promote").
	// -----------------------------------------------------------------
	static RS_LevelUpOffer Promotion(RS_Weapon wpn)
	{
		if (!wpn || wpn.Tier < VRT_Prototype)
			return null;

		let o = Make(RSLU_Promotion, "PROMOTE",
			"Cash the gun in. It falls to BASIC and keeps one more pellet, forever.");

		o.Rank = RS_UIStyle.Pips(wpn.PromotionCount) .. "  ->  " ..
		         RS_UIStyle.Pips(wpn.PromotionCount + 1);

		o.MetricLabel = "PELLETS";
		// "->" deliberately, even though '>' is NOT in the 16-segment
		// alphabet: SegmentSafe() sees that and Readout() draws the whole
		// value as text instead. Spelling it "3-4" to stay inside the
		// segment table would read as a RANGE rather than as a change,
		// which is a worse lie than a slightly plainer glyph.
		o.MetricValue = "" .. wpn.PelletCount .. " -> " .. (wpn.PelletCount + 1);

		o.CostLabel = "COST";
		// Percent sign on purpose: it is the clearest way to say this and
		// Readout() will route it through Text rather than dropping the
		// character in a Segment. See SegmentSafe().
		o.CostValue = "-20% STATS";
		return o;
	}

	// -----------------------------------------------------------------
	// EVERY CARD ON THE SCREEN, FOR ONE WEAPON.
	//
	// A convenience so this file is demonstrable end to end, NOT the
	// designed offer pipeline. It fills what it can honestly source:
	// affix bundles from RS_AffixInstall.BuildOffers, and the promotion
	// card from the weapon's own state.
	//
	// THERE ARE NO STAT CARDS IN HERE, AND THAT IS THE POINT.
	// TFLV_Upgrade_RS_Card* already owns every stat magnitude in this
	// game, promotion scaling and ceilings included. A second roller
	// living in a UI file would drift from it within a week and nothing
	// would report the drift -- so the stat and combo cards come from
	// whoever owns the level-up moment, as RS_LevelUpOffer.Make() rows,
	// and this function does not pretend to produce them.
	//
	// BuildOffers can return FEWER bundles than asked (its cost budget
	// may reject a roll), so offers.Size() is the truth about how many
	// cards there are and both layouts are driven from it rather than
	// from CardsForWeapon directly.
	//
	// OPEN QUESTION FOR THE OWNER, recorded rather than guessed:
	// docs/rs_10_ui_spec.txt says the promo card "doesn't count against
	// the tier's offer count", i.e. a Prototype gun sees N+1 cards. The
	// brief for this file says the count IS CardsForWeapon. This fills
	// the promo card INTO the count (never exceeding 8). Either ruling
	// works -- the layouts are solved for arbitrary N, so a 9th card
	// widens the fan and adds a grid column rather than breaking.
	// -----------------------------------------------------------------
	static play void OffersFor(RS_Weapon wpn, out Array<RS_LevelUpOffer> offers)
	{
		offers.Clear();
		if (!wpn)
			return;

		int want  = RS_AffixInstall.CardsForWeapon(wpn);
		let promo = Promotion(wpn);
		int affix = promo ? want - 1 : want;

		Array<RS_AffixIngredient> flat;
		Array<int> sizes;
		if (affix > 0)
			RS_AffixInstall.BuildOffers(wpn, affix, 2, flat, sizes);

		int at = 0;
		for (int b = 0; b < sizes.Size(); b++)
		{
			Array<RS_AffixIngredient> one;
			for (int j = 0; j < sizes[b] && at + j < flat.Size(); j++)
				one.Push(flat[at + j]);
			at += sizes[b];

			let o = FromBundle(one);
			if (o) offers.Push(o);
		}

		if (promo) offers.Push(promo);
	}

	// -----------------------------------------------------------------
	// KIND COLOUR. A switch, not a static array literal -- `static const
	// TYPE name[] = {...}` does not resolve on this engine build and has
	// produced a bogus "Unknown identifier" three separate times here.
	// -----------------------------------------------------------------
	static Color KindRGB(int kind)
	{
		switch (kind)
		{
			case RSLU_Affix:     return Color(255, 226, 224, 232);   // white
			case RSLU_Mastery:   return Color(255, 255, 150,  40);   // orange
			case RSLU_Stat:      return Color(255,  90, 220,  90);   // green
			case RSLU_Combo:     return Color(255, 180, 110, 255);   // purple
			case RSLU_Promotion: return Color(255, 255, 200,  60);   // gold
		}
		return Color(255, 200, 200, 200);
	}

	// The same five, lifted toward white for the card under the hand.
	// A SECOND TABLE RATHER THAN ARITHMETIC ON THE FIRST: Color's
	// component accessors are the kind of thing that either compiles or
	// costs a boot to find out, and this file cannot be compiled this
	// session. Five literals are boring and certain.
	static Color KindLitRGB(int kind)
	{
		switch (kind)
		{
			case RSLU_Affix:     return Color(255, 255, 255, 255);
			case RSLU_Mastery:   return Color(255, 255, 205, 140);
			case RSLU_Stat:      return Color(255, 180, 255, 180);
			case RSLU_Combo:     return Color(255, 224, 190, 255);
			case RSLU_Promotion: return Color(255, 255, 240, 170);
		}
		return Color(255, 255, 255, 255);
	}

	static string KindName(int kind)
	{
		switch (kind)
		{
			case RSLU_Affix:     return "AFFIX";
			case RSLU_Mastery:   return "MASTERY";
			case RSLU_Stat:      return "STAT";
			case RSLU_Combo:     return "COMBO";
			case RSLU_Promotion: return "CASH-IN";
		}
		return "";
	}
}

// =====================================================================
// RS_BBLevelUpCard -- ONE CARD FACE.
//
// Both styles draw the SAME card. Only the arrangement differs, which
// is the whole reason the two styles can be a cvar rather than a fork:
// a card looks like a card whichever way the screen is dealt.
//
// ---------------------------------------------------------------------
// THE ROWS, AND THE PROOF THAT THEY DO NOT COLLIDE.
//
// All offsets are fractions of the card's own height h, measured from
// its centre, + is up. Top edge is +0.500, bottom edge -0.500. Half
// heights are half the glyph or plate height, so a row occupies
// [centre - half, centre + half]:
//
//   row            centre    half     span              gap below
//   -------------------------------------------------------------
//   (top edge)     +0.500                               0.020
//   header strip   +0.420    0.060    +0.360 .. +0.480  0.024
//   kind / rank    +0.310    0.026    +0.284 .. +0.336  0.022
//   rule           +0.258    0.004    +0.254 .. +0.262  0.034
//   body 0         +0.190    0.030    +0.160 .. +0.220  0.055
//   body 1         +0.105    0.030    +0.075 .. +0.135  0.055
//   body 2         +0.020    0.030    -0.010 .. +0.050  0.055
//   body 3         -0.065    0.030    -0.095 .. -0.035  0.029
//   rule           -0.128    0.004    -0.132 .. -0.124  0.028
//   metric         -0.195    0.035    -0.230 .. -0.160  0.012
//   cost           -0.272    0.030    -0.302 .. -0.242  0.033
//   key plate      -0.400    0.065    -0.465 .. -0.335  0.035
//   (bottom edge)  -0.500
//
// Twelve rows, every gap positive, smallest 0.012h. At the smallest
// card this file can produce (h = 5.26 units, the 8-card fan) that
// smallest gap is 0.063 units = 1.9 mm at 0.76 m -- thin, but it is
// clearance between a metric row and a cost row, not between two
// glyphs, and both of those rows are half-height text inside their
// allocation.
//
// The body rows step by 0.085h and the glyph is capped at 0.70 of that
// step. RS_BBWeaponCard's measured limit is 0.82 before a glyph touches
// the row above it, so there is real margin rather than a value that
// happens to work.
//
// HORIZONTAL, the same discipline. Nothing is centred by eye:
//   pad          = 0.05w each side
//   body text    starts -0.45w, maxW 0.90w  -> ends exactly +0.45w
//   kind chip    starts -0.45w, maxW 0.40w  -> ends at most -0.05w
//   rank         ends   +0.45w, maxW 0.44w  -> starts at least +0.01w
//                (0.06w gutter between them even when both run full)
//   metric label starts -0.45w, maxW 0.50w  -> ends at most +0.05w
//   metric value box 0.34w wide, right edge at +0.45w -> starts +0.11w
//                (0.06w gutter)
// Text() SHRINKS a string that will not fit rather than truncating it,
// so a long word degrades to smaller type instead of becoming a
// different, wrong word. Nothing here can run off the edge.
//
// PART BUDGET: 19 billboards worst case (frame, ground, strip, title,
// kind, rank, 2 rules, 4 body lines, 2 metric, 2 cost, key plate, key
// word, key number). Eight cards plus the banner is ~160 quads, and
// they are static -- see the screen's Place() note on why a settled
// screen costs nothing per tic.
// =====================================================================
class RS_BBLevelUpCard play
{
	// Row step as a fraction of card height, and how many wrapped lines
	// the body gets. Class scope: `const X = 5;` inside a function is a
	// parse error in ZScript.
	const ROW_STEP   = 0.085;
	const BODY_LINES = 4;

	// -----------------------------------------------------------------
	// IS EVERY CHARACTER IN THE 16-SEGMENT ALPHABET?
	//
	// This is the guard for the trap described in the file header: the
	// engine's SegmentMask() returns 0 for anything it does not know and
	// EmitBillboardSegments SKIPS that character while still advancing
	// the pen. There is no error, no warning and no log line -- the
	// value just quietly loses its percent sign, or its comma, and reads
	// as a different number.
	//
	// The table below is transcribed from hw_sprites.cpp:1964 and
	// nothing else. Space is allowed because the emitter advances past
	// it without drawing, which is correct rather than lossy.
	//
	// NOT '%' AND NOT ',' -- the two most likely characters in a stat
	// readout, which is exactly why this exists.
	// -----------------------------------------------------------------
	static bool SegmentSafe(string s)
	{
		for (int i = 0; i < s.Length(); i++)
		{
			int c = s.ByteAt(i);

			if (c >= 48 && c <= 57)  continue;          // 0-9
			if (c >= 65 && c <= 90)  continue;          // A-Z
			if (c >= 97 && c <= 122) continue;          // a-z (folded to upper)
			if (c == 32) continue;                      // space: pen advances

			// - _ = + * / \ | ' " ( ) [ ] ? ! . :
			if (c == 45 || c == 95 || c == 61 || c == 43) continue;
			if (c == 42 || c == 47 || c == 92 || c == 124) continue;
			if (c == 39 || c == 34 || c == 40 || c == 41) continue;
			if (c == 91 || c == 93 || c == 63 || c == 33) continue;
			if (c == 46 || c == 58) continue;

			return false;
		}
		return true;
	}

	// -----------------------------------------------------------------
	// WORD WRAP, BY MEASUREMENT.
	//
	// Not by character count. RS_BBCompose's own header is explicit that
	// GLYPH_PITCH "is gone and must not come back as a layout input" --
	// it was only ever right because the SDF atlas is generated with one
	// reference advance per glyph, and regenerating it proportional
	// would silently make any hardcoded pitch a lie. Measure() asks the
	// engine, and the engine's measurer mirrors the renderer's own
	// maths, so the two cannot disagree about whether a line fits.
	//
	// A single word wider than maxW is kept on its own line anyway
	// rather than being broken: Text() will shrink it to fit, which the
	// reader can SEE happening, and a mid-word break cannot be seen at
	// all.
	//
	// Overflow past maxLines is marked with ".." rather than dropped, so
	// a description that was cut says so.
	// -----------------------------------------------------------------
	static void WrapInto(string txt, double h, double maxW, int maxLines,
		out Array<string> lines)
	{
		lines.Clear();
		if (txt.Length() == 0 || h <= 0 || maxW <= 0 || maxLines <= 0)
			return;

		Array<string> words;
		txt.Split(words, " ", TOK_SKIPEMPTY);

		string cur = "";
		for (int i = 0; i < words.Size(); i++)
		{
			// Parenthesised on purpose. `a ? b : c .. d` relies on `..`
			// binding tighter than `?:`, which is true in every C-shaped
			// grammar and is still not worth betting a boot on.
			string trial = (cur == "") ? words[i] : (cur .. " " .. words[i]);

			if (cur == "" || RS_BBCompose.Measure(trial, h) <= maxW)
			{
				cur = trial;
				continue;
			}

			lines.Push(cur);
			cur = words[i];

			if (lines.Size() >= maxLines)
			{
				// Out of room with words still in hand. Mark the last
				// line kept rather than silently ending mid-sentence.
				lines[maxLines - 1] = lines[maxLines - 1] .. "..";
				return;
			}
		}

		if (cur != "" && lines.Size() < maxLines)
			lines.Push(cur);
	}

	// -----------------------------------------------------------------
	// A LABELLED READOUT: word on the left, value hard right.
	//
	// The value goes through BB_SEGMENT when the 16-segment alphabet can
	// carry it and through BB_TEXT when it cannot. That is not a
	// preference -- see SegmentSafe(). Segment is the better draw (shader
	// arithmetic, sharp at any size, takes a glow) and Text is the only
	// one that can render a percent sign, so the string decides.
	// -----------------------------------------------------------------
	static void Readout(RS_BBComposedPanel p, double y, double w,
		string label, string value, double lineH, Color labelCol, Color valCol)
	{
		if (!p || label == "") return;

		double pad = w * 0.05;
		RS_BBCompose.Text(p, -w * 0.5 + pad, y, label, lineH * 0.85,
			labelCol, -1, w * 0.50);

		if (value == "") return;

		double boxW = w * 0.34;
		if (SegmentSafe(value))
			RS_BBCompose.Segment(p, w * 0.5 - pad - boxW * 0.5, y, value,
				boxW, lineH, valCol, 0.30, 0.55);
		else
			RS_BBCompose.Text(p, w * 0.5 - pad, y, value, lineH * 0.90,
				valCol, 1, boxW);
	}

	// -----------------------------------------------------------------
	// THE CARD. Returns its FRAME plate so the screen can light it when
	// the hand or the aim ray is on this card -- the highlight is a
	// recolour of one existing part, not a rebuild and not a move.
	//
	// SUBMISSION ORDER IS DEPTH ORDER. Billboards do not depth-test
	// against each other, so a plate drawn after the text it should sit
	// behind ERASES it. Everything here is submitted back to front, once.
	//
	// `key` is the number the player presses, 1-based, assigned by the
	// screen from the card's position -- so the leftmost card is always
	// 1 whichever style is up.
	// -----------------------------------------------------------------
	static RS_Billboard Build(RS_BBComposedPanel p, double w, double h,
		RS_LevelUpOffer o, int key)
	{
		if (!p || w <= 0 || h <= 0 || !o)
			return null;

		Color kind = RS_LevelUpOffer.KindRGB(o.Kind);

		// TEXT SIZE IS SOLVED, NOT CHOSEN, and it is bounded on BOTH
		// axes on purpose. RS_BBWeaponCard learned this the hard way: a
		// size derived from height alone produced enormous glyphs the
		// moment a card arrived with the wrong aspect, and a size
		// derived from the short side alone does not stop a glyph
		// colliding with the row above it on a landscape card.
		//
		//   step * 0.70   keeps it clear of the row above (0.82 is where
		//                 RS_BBWeaponCard measured contact)
		//   min(w,h) * 0.084  keeps the per-line character budget stable
		//
		// At this file's own 1:1.4 card the two land within 1% of each
		// other, so neither is doing violence to the other; the pair
		// exists so a caller handing this a differently-shaped card gets
		// something that looks wrong rather than something broken.
		double step = h * ROW_STEP;
		double line = min(step * 0.70, min(w, h) * 0.084);
		double pad  = w * 0.05;

		// The frame is the kind colour and it is the card's whole
		// identity at a glance: across a fan of eight you read the
		// COLOURS first and the words second, which is the only way a
		// wide fan is legible at all.
		let frame = RS_BBCompose.Plate(p, 0, 0, w * 1.020, h * 1.015, kind);
		if (frame) frame.SetGlow(0.45, 0.55);

		let ground = RS_BBCompose.Plate(p, 0, 0, w, h, Color(240, 13, 13, 19));
		if (ground) ground.SetGradient(Color(200, 26, 24, 38));

		// --- header strip: the one place the kind is a solid fill -----
		let strip = RS_BBCompose.Plate(p, 0, h * 0.420, w * 0.94, h * 0.120, kind);
		if (strip) strip.SetGlow(0.65, 0.80);
		RS_BBCompose.Text(p, 0, h * 0.420, o.Title, line * 1.15,
			Color(255, 10, 10, 14), 0, w * 0.88);

		// --- kind chip left, rank right -------------------------------
		RS_BBCompose.Text(p, -w * 0.5 + pad, h * 0.310,
			RS_LevelUpOffer.KindName(o.Kind), line * 0.85, kind, -1, w * 0.40);

		if (o.Rank != "")
			RS_BBCompose.Text(p, w * 0.5 - pad, h * 0.310, o.Rank,
				line * 0.85, Color(255, 190, 186, 200), 1, w * 0.44);

		RS_BBCompose.Plate(p, 0, h * 0.258, w * 0.90, h * 0.008,
			Color(255, 62, 58, 74));

		// --- what it DOES, in plain language ---------------------------
		// This is the row the owner's own mockup spends the most space on
		// ("Direct boost to impact power", "Unlock Socket #2 for dynamic
		// passive traits") and it is the difference between a menu and a
		// choice: a name teaches nothing the first time you meet it.
		Array<string> body;
		WrapInto(o.Body, line, w * 0.90, BODY_LINES, body);
		for (int i = 0; i < body.Size(); i++)
			RS_BBCompose.Text(p, -w * 0.5 + pad, h * 0.190 - step * i,
				body[i], line, Color(255, 214, 210, 200), -1, w * 0.90);

		RS_BBCompose.Plate(p, 0, -h * 0.128, w * 0.90, h * 0.008,
			Color(255, 62, 58, 74));

		// --- the two rows you weigh cards against each other on --------
		Readout(p, -h * 0.195, w, o.MetricLabel, o.MetricValue,
			line * 1.10, Color(255, 150, 150, 164), kind);

		Readout(p, -h * 0.272, w, o.CostLabel, o.CostValue,
			line * 0.95, Color(255, 150, 150, 164), Color(255, 226, 110, 96));

		// --- PRESS n ---------------------------------------------------
		// The mockup's own footer. It stays even once touch works,
		// because the number is the only control that is legible from
		// across the fan and the only one that works sitting down with
		// your hands in your lap.
		RS_BBCompose.Plate(p, 0, -h * 0.400, w * 0.86, h * 0.130,
			Color(215, 30, 30, 40));
		RS_BBCompose.Text(p, -w * 0.02, -h * 0.400, "PRESS", line * 0.95,
			Color(255, 170, 166, 180), 1, w * 0.40);
		RS_BBCompose.Segment(p, w * 0.14, -h * 0.400, "" .. key,
			w * 0.16, line * 1.10, kind, 0.35, 0.70);

		return frame;
	}

	// -----------------------------------------------------------------
	// THE BANNER over the cards -- the template's own title bar.
	//
	// This is the ONE surface on the screen that carries tier colour,
	// because it is the only one describing the WEAPON. Cards describe
	// OFFERS and wear kind colour. The two vocabularies never share a
	// plate; see the file header.
	//
	// Row proof, h = 2.6 units:
	//   title  centre +0.24h = +0.624, half 0.406 -> +0.218 .. +1.030
	//   name   centre -0.06h = -0.156, half 0.338 -> -0.494 .. +0.182
	//   hint   centre -0.32h = -0.832, half 0.243 -> -1.075 .. -0.589
	// Top edge +1.300, bottom -1.300. Gaps 0.270 / 0.036 / 0.095 / 0.225,
	// all positive.
	// -----------------------------------------------------------------
	static void BuildBanner(RS_BBComposedPanel p, double w, double h, RS_Weapon wpn)
	{
		if (!p || w <= 0 || h <= 0) return;

		Color tier = wpn ? RS_TierPalette.RGB(wpn.Tier)
		                 : Color(255, 235, 235, 240);
		double line = h * 0.26;

		let frame = RS_BBCompose.Plate(p, 0, 0, w * 1.010, h * 1.040, tier);
		if (frame) frame.SetGlow(0.50, 0.65);

		let ground = RS_BBCompose.Plate(p, 0, 0, w, h, Color(240, 12, 12, 18));
		if (ground) ground.SetGradient(Color(200, 30, 26, 42));

		let title = RS_BBCompose.Text(p, 0, h * 0.24, "WEAPON LEVEL UP",
			line * 1.20, tier, 0, w * 0.90);
		if (title) title.SetGlow(0.40, 0.60);

		if (wpn)
			RS_BBCompose.Text(p, 0, -h * 0.06,
				wpn.GetTag() .. "   " .. RS_UIStyle.TierName(wpn.Tier),
				line, Color(255, 232, 228, 216), 0, w * 0.86);

		// SAY THE RULE ON THE SCREEN. "One only" is the entire shape of
		// this moment and there is nowhere else the player can read it.
		RS_BBCompose.Text(p, 0, -h * 0.32,
			"TOUCH A CARD OR PRESS ITS NUMBER -- ONE ONLY",
			line * 0.72, Color(255, 150, 146, 160), 0, w * 0.86);
	}
}

// =====================================================================
// RS_BBLevelUpScreen -- N CARDS IN THE AIR. TWO WAYS.
//
// ---------------------------------------------------------------------
// WHY THERE IS NO ROLL, AND WHAT THAT DOES TO "A HAND OF CARDS"
//
// A real fanned hand ROLLS each card about a pivot near its bottom
// corner, which is what makes the cards splay and overlap. Billboards
// have YAW and TILT and nothing else -- RS_Billboard.Orient takes two
// angles, and there is no third. So the fan here is a YAW ARC: the
// cards stand on a circle centred on the reader, each turned to face
// them, like a curved bank of screens rather than a poker hand.
//
// That turns out to be the better VR layout anyway -- every card is at
// exactly the same reading distance and none of them is foreshortened --
// but it is a CONSTRAINT and not a preference, and the next person to
// look at this and wonder why the cards do not tip should know that
// tipping them is not available from script.
//
// ---------------------------------------------------------------------
// WHY THE SCREEN DOES NOT FOLLOW YOUR HEAD
//
// The obvious implementation re-aims every tic at the current view yaw.
// It is unusable, and specifically it is unusable at 8 cards: turning
// your head to read the outermost card turns the card away by the same
// amount, so the card you are trying to look at is the one card you can
// never look at. A screen you chase is worse than a screen that sits
// still.
//
// So the yaw is LATCHED when the screen opens and the cards stay where
// they were dealt. It follows only if you turn more than FOLLOW_DEADZONE
// (45 degrees, i.e. you have deliberately looked away), and then it eases
// after you at FOLLOW_RATE, staying that far behind. Position tracks the
// eye every tic, so walking never leaves the screen behind -- it is only
// the BEARING that is sticky.
//
// ---------------------------------------------------------------------
// GEOMETRY, WITH THE ARITHMETIC. Card 4.50 x 6.30 units (0.132 x 0.185 m)
// at REACH 26.0 units (0.76 m). Both styles put the screen's centre on
// the RESTING GAZE -- GAZE_DOWN, 8 degrees below the horizon, where a
// relaxed pair of eyes actually sits -- rather than on the horizon,
// which reads as being shoved in your face. The drop is therefore
// 26 * tan(8) = 3.654 units, and because every card is at the same
// horizontal distance and the same height, the tilt that makes them
// face the eye is exactly -8 degrees. The gaze angle and the card tilt
// are the same number by construction, not by coincidence.
//
// FAN. Cards are chords on a circle of radius R = 26, so a card of
// width W occupies 2*asin(W/2R) of arc, and the gap between neighbours
// is step - that. Step is 12 degrees until the sweep cap bites:
//
//   n   step     sweep   card W   half-angle   gap     outer edge
//   ------------------------------------------------------------
//   1   --        0.0     4.500     4.965      --      +/-  4.97
//   2   12.000   12.0     4.500     4.965     2.070    +/- 10.97
//   3   12.000   24.0     4.500     4.965     2.070    +/- 16.97
//   4   12.000   36.0     4.500     4.965     2.070    +/- 22.97
//   5   12.000   48.0     4.500     4.965     2.070    +/- 28.97
//   6   12.000   60.0     4.500     4.965     2.070    +/- 34.97
//   7   12.000   72.0     4.500     4.965     2.070    +/- 40.97
//   8   10.286   72.0     3.757     4.143     2.000    +/- 40.14
//
//   sweep      = (n-1) * step, capped at FAN_SWEEP_MAX = 72
//   half-angle = asin(W/2 / 26)
//   gap        = step - 2*half-angle, i.e. clear air between two cards
//   outer edge = sweep/2 + half-angle, off the anchor bearing
//
// PROOF IT DOES NOT OVERLAP: adjacent cards' near corners both sit ON
// the circle, so the metal distance between them is 2*26*sin(gap/2) --
// 0.941 units at n<=7 and 0.908 at n=8. Positive at every count, and it
// never shrinks below 0.9 units (26 mm) because the CARD narrows once
// the sweep is capped instead of the gap closing. That is the fan doing
// what a hand of cards does: more cards, held tighter.
//
// PROOF IT DOES NOT RUN OFF: nothing can, because there is no edge --
// the extent is angular. The real limit is the neck, and the widest
// case (8 cards, +/-40.1 degrees) needs a head turn to read the outer
// pair. That is the honest cost of this style and it is why the other
// one exists.
//
// GRID. One flat plane, all cards coplanar, gaps GRID_GAP = 0.55 units:
//
//   n   cols x rows   block W   block H   off-axis H    off-axis V
//   ------------------------------------------------------------------
//   1     1 x 1         4.50      6.30    +/- 5.0    -1.1 .. -14.7
//   2     2 x 1         9.55      6.30    +/-10.4    -1.1 .. -14.7
//   3     3 x 1        14.60      6.30    +/-15.7    -1.1 .. -14.7
//   4     4 x 1        19.65      6.30    +/-20.7    -1.1 .. -14.7
//   5     3 x 2        14.60     13.15    +/-15.7    +6.4 .. -21.5
//   6     3 x 2        14.60     13.15    +/-15.7    +6.4 .. -21.5
//   7     4 x 2        19.65     13.15    +/-20.7    +6.4 .. -21.5
//   8     4 x 2        19.65     13.15    +/-20.7    +6.4 .. -21.5
//
//   block W = cols*4.50 + (cols-1)*0.55
//   block H = rows*6.30 + (rows-1)*0.55
//   off-axis = atan(half extent / 26), with the block centred on the
//              resting gaze at -8 degrees
//
// PROOF IT DOES NOT OVERLAP: neighbouring centres are exactly
// W + GRID_GAP apart horizontally (5.05) and H + GRID_GAP vertically
// (6.85), so there is 0.55 units (16 mm) of clear air on every side of
// every card, at every count, including the ragged last row -- which is
// CENTRED rather than left-aligned, so five cards read as 3-over-2 by
// design instead of as a row with a hole in it.
//
// PROOF IT DOES NOT RUN OFF: the whole block is 41 x 28 degrees at its
// largest, which fits inside the comfortable field without moving your
// head at all. That is the grid's entire argument.
//
// AT ONE CARD THE TWO STYLES ARE IDENTICAL, and that is correct: with
// one card there is nothing to arrange, so both degrade to "the card,
// dead ahead, at reading height". At two, the fan turns them slightly
// toward each other (a held pair) and the grid stands them side by side
// (a spread pair). Neither reads as a broken version of the eight-card
// case.
//
// ROWS ARE NOT CAPPED AT TWO. rows = (n+3)/4, so 9..12 cards would
// become three rows rather than overflowing. CardsForWeapon caps at 8
// so that branch is unreachable today; it exists so that raising the cap
// is a one-line decision somewhere else rather than a silent overlap
// here.
// =====================================================================
class RS_BBLevelUpScreen play
{
	// --- the numbers the layout is solved from -------------------------
	const REACH_DEFAULT   = 26.0;    // 0.76 m -- arm's length. See header.
	const GAZE_DOWN       = 8.0;     // degrees below the horizon
	const CARD_W          = 4.50;    // 0.132 m
	const CARD_ASPECT     = 1.40;    // a playing card's proportions
	const FAN_STEP        = 12.0;    // preferred degrees between cards
	const FAN_SWEEP_MAX   = 72.0;    // total spread cap, +/- 36 degrees
	const FAN_GAP         = 2.0;     // guaranteed clear air, in degrees
	const GRID_GAP        = 0.55;    // 16 mm between cards
	const BANNER_W        = 16.0;
	const BANNER_H        = 2.60;
	const BANNER_GAP      = 0.40;
	const FOLLOW_DEADZONE = 45.0;    // turn this far before it follows
	const FOLLOW_RATE     = 3.0;     // degrees per tic once it does
	const GROW_TICS       = 8;       // bloom length, per card
	const GROW_STAGGER    = 2;       // tics between one card and the next
	const GROW_MIN        = 0.55;    // size it blooms FROM

	// --- style, behind a cvar so it is a five-second decision ----------
	// 0 FAN, 1 GRID. Anything else is FAN: an out-of-range cvar should
	// give the default screen, not no screen.
	static int Style()
	{
		let cv = CVar.FindCVar("rs_levelupcard_style");
		return (cv && cv.GetInt() == 1) ? 1 : 0;
	}

	// The one measurement most likely to be wrong in a headset, and the
	// one this whole file's sizing hangs off. Same reasoning as
	// rs_panel_pitchbias: better a dial than a rebuild.
	static double Reach()
	{
		let cv = CVar.FindCVar("rs_levelupcard_reach");
		return cv ? clamp(cv.GetFloat(), 12.0, 96.0) : REACH_DEFAULT;
	}

	Array<RS_BBComposedPanel> mCards;
	// Parallel to mCards. mFrames holds a PART of each panel, not an
	// owned handle -- Close() must not release these, the panel's own
	// ReleaseAll() already does, and releasing twice would hand back a
	// handle the engine may have reissued.
	Array<RS_Billboard> mFrames;
	Array<int>    mKind;
	Array<double> mBearing;            // FAN: degrees off the anchor
	Array<double> mLocalX, mLocalY;    // GRID: offsets in the screen plane

	RS_BBComposedPanel mBanner;
	double mBannerUp;

	int    mStyle;
	double mAnchorYaw;
	double mReach, mDrop, mTilt;
	double mCardW, mCardH;
	int    mHot;
	int    mAge;
	bool   mAlive;

	bool Alive() const { return mAlive; }
	int  Count() const { return mCards.Size(); }

	// -----------------------------------------------------------------
	// OPEN. Builds every card once and places them; after this the
	// screen is cheap to keep up.
	// -----------------------------------------------------------------
	static RS_BBLevelUpScreen Open(PlayerPawn pawn, RS_Weapon wpn,
		Array<RS_LevelUpOffer> offers)
	{
		if (!pawn || !pawn.player || offers.Size() == 0)
			return null;

		let s = new("RS_BBLevelUpScreen");
		s.mStyle = Style();
		s.mReach = Reach();

		// The drop and the tilt are the same statement made twice: put
		// the screen on the resting gaze, and turn the cards to face the
		// eye that is looking down at it. tan and atan would round-trip,
		// so the tilt is simply the gaze angle negated -- FaceViewer's
		// camera mode computes -atan2(dz, flat), and dz/flat IS tan(gaze)
		// here by construction.
		s.mDrop = s.mReach * tan(GAZE_DOWN);
		s.mTilt = -GAZE_DOWN;

		// LATCHED, not tracked. See the header.
		s.mAnchorYaw = pawn.angle;
		s.mHot   = -1;
		s.mAge   = 0;
		s.mAlive = true;

		int n = offers.Size();
		s.Solve(n);

		for (int i = 0; i < n; i++)
		{
			let p = new("RS_BBComposedPanel");
			let frame = RS_BBLevelUpCard.Build(p, s.mCardW, s.mCardH,
				offers[i], i + 1);
			s.mCards.Push(p);
			s.mFrames.Push(frame);
			s.mKind.Push(offers[i].Kind);
		}

		s.mBanner = new("RS_BBComposedPanel");
		RS_BBLevelUpCard.BuildBanner(s.mBanner, BANNER_W, BANNER_H, wpn);

		s.Place(pawn);
		return s;
	}

	void Solve(int n)
	{
		mBearing.Clear();
		mLocalX.Clear();
		mLocalY.Clear();

		if (mStyle == 1) SolveGrid(n);
		else             SolveFan(n);
	}

	// -----------------------------------------------------------------
	// STYLE 0 -- FAN. A yaw arc at a constant radius.
	//
	// The card WIDTH is derived from the step rather than the other way
	// round, which is the whole trick: it makes the gap between cards a
	// constant the layout guarantees instead of a leftover it hopes for.
	// Widening the arc is the first response to more cards; narrowing
	// the card is the second, and only once the arc has hit the cap.
	// -----------------------------------------------------------------
	void SolveFan(int n)
	{
		double step = (n <= 1) ? 0.0 : min(FAN_STEP, FAN_SWEEP_MAX / (n - 1));

		mCardW = CARD_W;
		if (n > 1)
		{
			// The widest chord that still leaves FAN_GAP of clear arc.
			// Only bites once the sweep cap has forced the step below
			// ~12.15 degrees, which at FAN_SWEEP_MAX 72 is n = 8.
			//
			// The 0.40 floor is a guard rail, not a plan: it could only
			// be reached past about 30 cards, and CardsForWeapon caps at
			// 8. It exists so that a future cap change produces slivers
			// -- visibly wrong -- rather than negative widths, which
			// would draw inside-out and look like a shader bug.
			double allow = 2.0 * mReach * sin((step - FAN_GAP) * 0.5);
			mCardW = max(0.40, min(CARD_W, allow));
		}
		mCardH = mCardW * CARD_ASPECT;

		double first = -step * (n - 1) * 0.5;
		for (int i = 0; i < n; i++)
		{
			mBearing.Push(first + step * i);
			mLocalX.Push(0.0);
			mLocalY.Push(0.0);
		}

		mBannerUp = mCardH * 0.5 + BANNER_GAP + BANNER_H * 0.5;
	}

	// -----------------------------------------------------------------
	// STYLE 1 -- GRID. One flat plane, rows and columns.
	//
	// COPLANAR ON PURPOSE. Yawing each column toward the reader would
	// make this a shallow fan, and then there would be one style with a
	// slider rather than two styles. A block reads as a block because it
	// is flat. The cost is that the outermost card is 20.7 degrees off
	// axis and therefore foreshortened by cos(20.7) = 0.94, which is
	// under the threshold where anyone notices.
	//
	// The last row is CENTRED. Five cards left-aligned in a 3x2 reads as
	// a missing sixth card; centred, it reads as a deliberate 3-over-2.
	// -----------------------------------------------------------------
	void SolveGrid(int n)
	{
		mCardW = CARD_W;
		mCardH = CARD_W * CARD_ASPECT;

		int rows = (n + 3) / 4;          // 1..4 -> 1, 5..8 -> 2
		if (rows < 1) rows = 1;
		int cols = (n + rows - 1) / rows;

		double sx = mCardW + GRID_GAP;
		double sy = mCardH + GRID_GAP;
		double blockH = rows * mCardH + (rows - 1) * GRID_GAP;

		int placed = 0;
		for (int r = 0; r < rows; r++)
		{
			int c = min(cols, n - placed);
			for (int j = 0; j < c; j++)
			{
				mLocalX.Push((double(j) - double(c - 1) * 0.5) * sx);
				mLocalY.Push(blockH * 0.5 - mCardH * 0.5 - r * sy);
				mBearing.Push(0.0);
			}
			placed += c;
		}

		mBannerUp = blockH * 0.5 + BANNER_GAP + BANNER_H * 0.5;
	}

	// -----------------------------------------------------------------
	// PLACE. Called every tic by whoever owns the screen.
	//
	// CHEAP BY CONSTRUCTION. RS_BBComposedPanel.Place() early-outs when
	// the transform it is given is identical to the last one, so a
	// player standing still costs literally nothing per tic even at
	// eight cards. The bloom is the only thing that touches every part,
	// and it stops touching them the tic it finishes -- without that
	// guard a settled screen would keep pushing ~160 alpha writes a tic
	// forever for no visible reason.
	// -----------------------------------------------------------------
	void Place(PlayerPawn pawn)
	{
		if (!mAlive || !pawn || !pawn.player)
			return;

		Vector3 eye = (pawn.pos.x, pawn.pos.y, pawn.player.viewz);

		// LAZY FOLLOW. Nothing moves until you have turned further than
		// the deadzone; past it the anchor eases after you and stays a
		// deadzone behind, so the screen is always reachable and never
		// running away from the card you are trying to read.
		//
		// Actor.deltaangle, qualified: it is a clearscope static on Actor
		// (actor.zs:480) and this class is not an Actor, so the bare name
		// would not resolve.
		double d = Actor.deltaangle(mAnchorYaw, pawn.angle);
		if (abs(d) > FOLLOW_DEADZONE)
		{
			double over = (d > 0) ? d - FOLLOW_DEADZONE : d + FOLLOW_DEADZONE;
			mAnchorYaw += clamp(over, -FOLLOW_RATE, FOLLOW_RATE);
		}

		mAge++;
		// int(), not the raw Size(): Size() is UNSIGNED, and multiplying
		// it into a signed expression is the one arithmetic mix in this
		// file that could go somewhere surprising. Nothing else here does
		// maths on a container length.
		int cards = int(mCards.Size());
		bool blooming = (mAge <= GROW_TICS + cards * GROW_STAGGER + 1);

		double yaw = mAnchorYaw + 180.0;
		Vector3 centre = (eye.x + cos(mAnchorYaw) * mReach,
		                  eye.y + sin(mAnchorYaw) * mReach,
		                  eye.z - mDrop);

		Vector3 rv = RS_BBComposedPanel.RightOf(yaw);
		Vector3 uv = RS_BBComposedPanel.UpOf(yaw, mTilt);

		for (int i = 0; i < mCards.Size(); i++)
		{
			if (!mCards[i]) continue;

			if (blooming)
			{
				// Staggered, so the hand is DEALT rather than appearing.
				// Rescale is N setter calls with no allocation -- see
				// RS_BBComposedPanel.Rescale's own note on why this
				// stopped needing to be quantised.
				double f = clamp(double(mAge - i * GROW_STAGGER)
					/ double(GROW_TICS), 0.0, 1.0);
				mCards[i].Rescale(GROW_MIN + (1.0 - GROW_MIN) * f);
				mCards[i].SetAlphaAll(max(0.12, f));
			}

			if (mStyle == 1)
			{
				mCards[i].Place(centre + rv * mLocalX[i] + uv * mLocalY[i],
					yaw, mTilt);
			}
			else
			{
				// Each fan card gets its OWN bearing, and its yaw points
				// from the card back at the eye -- the convention
				// RS_Panel.FaceViewer sets and RS_BBComposedPanel.Place
				// depends on. A card at bearing a is faced by yaw a+180.
				double a = mAnchorYaw + mBearing[i];
				Vector3 at = (eye.x + cos(a) * mReach,
				              eye.y + sin(a) * mReach,
				              eye.z - mDrop);
				mCards[i].Place(at, a + 180.0, mTilt);
			}
		}

		if (mBanner)
			mBanner.Place(centre + uv * mBannerUp, yaw, mTilt);
	}

	// -----------------------------------------------------------------
	// WHICH CARD IS THE HAND OR THE AIM RAY ON?
	//
	// AimBillboard/TouchBillboard return the native handle of whatever
	// they hit -- one of a card's nineteen parts, not the card. Only the
	// panel knows which parts are its own, so it is asked rather than
	// compared. Same shape as RS_PanelAssembly.PanelForHandle, and for
	// the same reason: a composed card has no single handle.
	// -----------------------------------------------------------------
	int CardForHandle(int id) const
	{
		if (id == 0) return -1;
		for (int i = 0; i < mCards.Size(); i++)
			if (mCards[i] && mCards[i].OwnsHandle(id))
				return i;
		return -1;
	}

	// -----------------------------------------------------------------
	// THE HIGHLIGHT IS OPTICAL, NOT GEOMETRIC, and that is deliberate:
	// popping the hot card forward would be prettier and would also
	// invalidate every overlap proof in this file's header the moment
	// two neighbours were both mid-animation. Recolouring one existing
	// plate cannot move anything.
	// -----------------------------------------------------------------
	void SetHot(int idx)
	{
		if (idx == mHot) return;
		mHot = idx;

		for (int i = 0; i < mFrames.Size(); i++)
		{
			let f = mFrames[i];
			if (!f) continue;

			bool hot = (i == idx);
			// data is 0 on a BB_PANEL -- the payload does not read it,
			// and glow for a plate is a setter, not packed bits.
			f.SetData(0, hot ? RS_LevelUpOffer.KindLitRGB(mKind[i])
			                 : RS_LevelUpOffer.KindRGB(mKind[i]));
			f.SetGlow(hot ? 0.85 : 0.45, hot ? 1.00 : 0.55);
		}
	}

	// -----------------------------------------------------------------
	// CLOSE. Every path that drops this screen must come through here.
	//
	// A billboard handle is an integer the engine issued; dropping it
	// without RemoveBillboard leaks a quad that lives until the level
	// ends, and the collector cannot see it. mFrames is deliberately
	// only CLEARED -- its entries are parts the panels already released.
	// -----------------------------------------------------------------
	void Close()
	{
		for (int i = 0; i < mCards.Size(); i++)
			if (mCards[i]) mCards[i].ReleaseAll();

		if (mBanner) mBanner.ReleaseAll();
		mBanner = null;

		mCards.Clear();
		mFrames.Clear();
		mKind.Clear();
		mBearing.Clear();
		mLocalX.Clear();
		mLocalY.Clear();

		mHot   = -1;
		mAlive = false;
	}
}
