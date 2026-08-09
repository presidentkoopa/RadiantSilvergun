// =====================================================================
// RS_BBStatusCards -- THE GUNBONSAI STATUS SCREEN, AS A DECK OF CARDS.
// ---------------------------------------------------------------------
// The flat menu this replaces is zscript/gunbonsai/menu/StatusDisplay.zsc
// (TFLV_Menu_StatusDisplay) plus the graft that extends it,
// zscript/gunbonsai/OffhandStatusDisplay.zsc
// (TFLV_Menu_UnifiedStatusDisplay -- which is the class MENUDEF.txt:1062
// actually binds to the name "GunBonsaiStatusDisplay", so it is the one
// the key really opens). Between them they push, in one scrolling column:
//
//   PLAYER STATUS    level, XP toward the next player level,
//                    then the player's whole upgrade bag as toggle rows
//   WEAPON STATUS    type (tag and class name), level, XP,
//                    then the mainhand's whole upgrade bag
//   a rule + the upgrade controls help line
//   LD EFFECTS       the mainhand's Legendoom effects, current one
//                    pre-selected -- only when it has any
//   OFFHAND WEAPON   type, level, XP, then the offhand's upgrade bag
//
// ---------------------------------------------------------------------
// THE SPLIT, AND WHY IT IS THIS ONE.
//
// A menu can only ever be a list, so the flat screen is one column and
// the reader has to scroll to find out whether it ended. The DATA is not
// a list. It is up to three SUBJECTS -- the player, the mainhand, the
// offhand -- and each subject has exactly two parts:
//
//   a HEADLINE   one level, one progress bar, a handful of counts. Fixed
//                size, read in half a second, answers "how close am I".
//   a LEDGER     its upgrade bag. UNBOUNDED length, read slowly, answers
//                "what have I actually got".
//
// Those two are read at different moments and one of them can be twenty
// rows long, so they are different cards:
//
//   SUBJECT CARD   one per subject that exists (1 to 3 cards).
//   LEDGER CARD    one per PAGE of a subject's bag (ROWS entries each).
//   EFFECTS CARD   the mainhand's Legendoom list, only when non-empty.
//
// Splitting on subject FIRST is what makes the count honest: one gun and
// an empty bag is two cards, dual-wielding with full bags is eight. The
// arranger below is solved for arbitrary N, which is exactly what
// pagination needs, so a long bag costs another card instead of a
// scrollbar. NO CARD EVER SCROLLS -- that is the whole point of the
// exercise and it is the one property the flat menu could not have.
//
// The controls-help line is NOT reproduced as a row. It tells you to
// press Enter to toggle and Left/Right to tune an upgrade, and in the
// world there is nothing listening for either (see the hookup note at
// the bottom of this file). Printing it would be the mod lying about its
// own controls. The banner says what is true instead: read only, toggle
// from the flat sheet.
//
// ---------------------------------------------------------------------
// THE ONE PLACE THIS FILE TOUCHES TFLV, AND WHY THAT IS A WART.
//
// RS_GunBonsaiBridge's header says it is the ONE file where RS and the
// vendored GunBonsai system may reference each other's types, and
// RS_BBLevelUpCard's header says a UI file quietly becoming the second
// one is how that rule dies. It is right, and this file breaks it --
// deliberately, in one class, RS_BBStatusSource, and nowhere else.
//
// The reason is simply that the bridge does not expose any of this. It
// answers three questions (strip a promoted weapon, count its socket
// affixes, name them) and none of them is "what level is the player" or
// "what is in this bag". The honest fix is three more accessors on
// RS_GunBonsaiBridge -- PlayerProgress, WeaponProgress, BagRows -- and
// this file calling those instead. THAT FILE IS NOT MINE THIS SESSION,
// so the coupling is quarantined in one class that produces plain data,
// and every other class here is TFLV-free and would not change at all if
// the bridge grew those three functions tomorrow. Same shape as
// RS_BBImprintCard flagging its duplicated reroll price rather than
// silently reaching into RS_BBWeaponCard.
//
// ---------------------------------------------------------------------
// TWO QUESTIONS THAT LOOK LIKE ONE, AND MUST NOT BE MERGED.
//
//   "what is FITTED IN A SOCKET on this gun"   RS_GunBonsaiBridge
//                                              .FittedNames -- filters to
//                                              TFLV_Upgrade_RS_SlateBase
//   "what is IN THE BAG on this gun"           every upgrade with a
//                                              level, including pure stat
//                                              purchases that occupy no
//                                              socket at all
//
// The flat status menu shows the SECOND (it dumps the whole bag). The
// weapon card and the imprint card show the FIRST. Both are correct for
// what they are, and the bug that was found and fixed today was two
// functions answering the SAME question two ways -- not these two
// questions existing.
//
// So the ledger cards list the whole bag, and a row is MARKED as
// occupying a socket by testing whether its name is in the bridge's own
// FittedNames answer. That is a derivation FROM the sanctioned
// definition, not a second copy of the predicate: nothing in this file
// knows what TFLV_Upgrade_RS_SlateBase is, and if the bridge changes its
// mind about what counts, these pips change with it for free.
//
// ---------------------------------------------------------------------
// ENGINE FACTS THIS FILE IS BUILT ON. Each one has cost a boot here.
//
//   * Strings are BB_TEXT (RS_BBCompose.Text). Numbers are BB_SEGMENT
//     (RS_BBCompose.Segment). BB_DIGITS and BB_GLYPH are raster quads --
//     blocky up close, no glow, and BB_DIGITS renders multi-digit values
//     BACKWARDS. Neither appears below.
//   * BB_SEGMENT'S ALPHABET IS FINITE: 0-9, A-Z, and - _ = + * / \ | ' "
//     ( ) [ ] ? ! . : and nothing else. An unlisted character is SKIPPED
//     SILENTLY while the pen still advances, so "72%" draws "72" and a
//     gap with no error anywhere. Every value below is routed through
//     RS_BBLevelUpCard.SegmentSafe first -- REUSED, not re-transcribed,
//     because a second copy of that table is a second thing to get wrong.
//     "1234/5000" and "3/5" are safe ('/' is in the table); a percent
//     sign and a promotion pip row are not, and go through Text.
//   * Plates are BB_PANEL textured quads -- no rounded corners, no inset
//     shadow. Nothing here is designed around either.
//   * NEVER add an argument to AddBillboard / AddBillboardPersistent /
//     AttachBillboard. At sixteen the ZScript compiler dies SILENTLY mid
//     LoadActors. Glow, gradient and progress are setters on
//     RS_Billboard for exactly that reason, and this file only ever uses
//     the setters.
//   * A class with no scope qualifier is DATA scope. RS_BBStatusSource is
//     `play` because it reads TFLV play objects and RS_Weapon fields; the
//     card and the row types are `play` because play code builds them.
//     RS_BBStatusScreen inherits its scope from RS_BBLevelUpScreen, the
//     same way RS_BBWeaponStatus inherits it from RS_BBScreen.
//   * `const` is CLASS SCOPE ONLY. Inside a function body it is a parse
//     error, so every constant below sits at class scope.
//   * `static const TYPE name[] = { ... }` does not resolve on this
//     engine build. Colours come from switches and if-chains.
//
// TIER COLOUR COMES FROM RS_TierPalette AND NOWHERE ELSE. There is
// exactly ONE new colour in this file -- the player accent -- and its
// justification is written where it is declared.
// =====================================================================

// WHAT KIND OF CARD THIS IS. File scope, following ERS_TriSlot's note:
// every enum in this codebase sits at file scope, and a nested enum read
// from another file is exactly the resolution question that has cost this
// project a failed boot before.
enum ERS_StatusCardKind
{
	RSSC_Player  = 0,   // the player's own level and track
	RSSC_Weapon  = 1,   // one hand's gun: level, tier, sockets
	RSSC_Ledger  = 2,   // one page of somebody's upgrade bag
	RSSC_Effects = 3    // the mainhand's Legendoom effect list
}

// HOW A LEDGER ROW READS. Not a colour and not a shape -- a STATE, which
// the card face turns into both.
enum ERS_StatusRowState
{
	RSSR_Plain = 0,
	RSSR_Hot   = 1,   // the live one: the active Legendoom effect
	RSSR_Off   = 2    // disabled in the bag (upgrade.enabled == false)
}

// WHETHER A ROW SHOWS A SOCKET PIP, and if so which one.
//
// THREE STATES, NOT A BOOL, and the third is the interesting one. On a
// subject card there are no sockets involved at all, so a column of
// hollow pips would imply a socket count that does not exist -- those
// rows draw NO pip. On a ledger card every row gets one, and hollow
// versus filled is what separates a socketed affix from a stat purchase
// that occupies nothing.
enum ERS_StatusPip
{
	RSSP_None   = 0,
	RSSP_Hollow = 1,
	RSSP_Filled = 2
}

// =====================================================================
// RS_BBStatusRow -- ONE PRINTABLE LINE, as plain data.
//
// A class rather than a struct because ZScript dynamic arrays hold
// primitives and object pointers; Array<SomeStruct> is not available.
// =====================================================================
class RS_BBStatusRow play
{
	string Label;
	string Value;
	int    State;   // ERS_StatusRowState
	int    Pip;     // ERS_StatusPip

	static RS_BBStatusRow Make(string label, string value,
		int state = RSSR_Plain, int pip = RSSP_None)
	{
		let r = new("RS_BBStatusRow");
		r.Label = label;
		r.Value = value;
		r.State = state;
		r.Pip   = pip;
		return r;
	}
}

// =====================================================================
// RS_BBStatusCardData -- ONE CARD'S CONTENT, as plain data.
//
// The face draws this and nothing else, so a caller can fill it from any
// source -- the live GunBonsai bags, a hand-written test, an eventual
// bridge accessor -- without the layout knowing which. That separation
// is the reason the TFLV coupling can be quarantined in one class.
// =====================================================================
class RS_BBStatusCardData play
{
	int    Kind;        // ERS_StatusCardKind
	string Title;       // the headline noun: "PLAYER", the gun's tag, "UPGRADES"
	string Subtitle;    // where it lives: "MAINHAND -- PROTOTYPE"
	string Summary;     // the card's own bottom line
	Color  Accent;      // the subject's colour -- see RS_BBStatusSource.AccentFor

	// Headline block. Meaningful on RSSC_Player and RSSC_Weapon only.
	int    Level;
	double XP;
	double MaxXP;

	Array<RS_BBStatusRow> Rows;

	static RS_BBStatusCardData Make(int kind, string title, string subtitle,
		Color accent)
	{
		let d = new("RS_BBStatusCardData");
		d.Kind     = kind;
		d.Title    = title;
		d.Subtitle = subtitle;
		d.Accent   = accent;
		return d;
	}

	void AddRow(string label, string value,
		int state = RSSR_Plain, int pip = RSSP_None)
	{
		Rows.Push(RS_BBStatusRow.Make(label, value, state, pip));
	}

	// -----------------------------------------------------------------
	// HOW MANY OF THE CARD'S BODY SLOTS THE HEADLINE EATS.
	//
	// Derived from the kind rather than stored, so it cannot drift from
	// what the face actually draws. The face's row ledger (see
	// RS_BBStatusCard's header) budgets ROWS slots; the headline occupies
	// the first HeadSlots of them and the Rows array fills the remainder.
	// -----------------------------------------------------------------
	static int HeadSlotsFor(int kind)
	{
		if (kind == RSSC_Player) return 5;   // big level over slots 0..2, bar over 3..4
		if (kind == RSSC_Weapon) return 3;   // big level over slots 0..1, bar on slot 2
		return 0;                            // ledger and effects cards are all rows
	}
}

// =====================================================================
// RS_BBStatusSource -- THE ONLY TFLV-AWARE CLASS IN THIS FILE.
//
// Reads the live GunBonsai state and RS_Weapon fields and produces plain
// RS_BBStatusCardData. See the file header for why the coupling lives
// here and what the honest fix is.
// =====================================================================
class RS_BBStatusSource play
{
	// SUBJECT CODES ARE RS_UIHandler.mCycle's CODES, not new ones.
	// That handler's CycleSheets() already walks 0 -> 1 -> 2 and the "I"
	// key already lands there (KEYCONF:14 binds I to gboh-unified-info,
	// which GunBonsai's EventHandler.GBOH_UnifiedInfo forwards straight
	// to RS_UIHandler.CycleSheets). Numbering these the same way means
	// the hookup passes mCycle through unchanged instead of translating
	// between two conventions that would drift.
	const SUB_ALL      = -1;
	const SUB_OFFHAND  = 0;
	const SUB_MAINHAND = 1;
	const SUB_PLAYER   = 2;

	// THE DECK IS CAPPED AT EIGHT AND THE NUMBER IS NOT ARBITRARY.
	// RS_BBLevelUpScreen's fan and grid are both SOLVED and written out
	// for 1..8 (its header carries the tables). Past 8 the fan keeps
	// narrowing the card and the grid keeps adding rows, so nothing
	// breaks -- but nothing is proven either, and a status screen is not
	// where to find out. When the cap bites, a subject says so on its own
	// card rather than silently losing pages.
	const MAX_CARDS = 8;

	// ROWS IS NOT DECLARED HERE. It belongs to the card face -- it is a
	// property of the layout, not of the data -- and every use below
	// reads RS_BBStatusCard.ROWS. Two constants that must agree is one
	// constant too many; this project has spent real time on exactly that
	// shape of drift.

	// -----------------------------------------------------------------
	// HOW MANY GUN LEVELS BUY A PLAYER LEVEL.
	//
	// The same quantity stock GunBonsai's status display shows: its
	// PerPlayerStats.GetCurrentStats fills stats.pmax from the cvar
	// bonsai_gun_levels_per_player_level (CVARINFO.txt:112, `server int`),
	// and RS_Screens.BuildPlayerSheet reads the same one. There is no
	// maxXP field on TFLV_PerPlayerStats -- this cvar IS the ceiling.
	//
	// READ THROUGH CVar.FindCVar RATHER THAN BY BARE NAME, which is what
	// both of those do. A bare CVARINFO name resolves inside an ordinary
	// method, and every use of it in this tree is inside one; NOTHING here
	// is an ordinary method, this is a static on a static-only class, and
	// "it probably resolves in a static too" is not worth a whole-mod
	// compile failure to find out. FindCVar works from any scope and
	// returns the same number.
	//
	// A missing cvar returns 0, which XPPair prints as "--" and the bar
	// draws empty. That is the honest answer to "the ceiling is unknown",
	// and it is deliberately NOT a hardcoded 3 -- copying CVARINFO's
	// default here would be a second place that number lives.
	// -----------------------------------------------------------------
	static double PlayerLevelCost()
	{
		let cv = CVar.FindCVar("bonsai_gun_levels_per_player_level");
		return cv ? double(cv.GetInt()) : 0.0;
	}

	// -----------------------------------------------------------------
	// PROGRESS AS A PERCENTAGE FOR BB_BAR, which takes 0..100.
	//
	// A separate function because "max is zero" happens for real: a
	// weapon with no WeaponInfo yet has maxXP 0, and 0/0 must read as an
	// empty bar rather than as a division.
	// -----------------------------------------------------------------
	static int Pct(double v, double maxv)
	{
		if (maxv <= 0) return 0;
		return clamp(int(100.0 * v / maxv), 0, 100);
	}

	// XP as a segment-safe pair. '/' IS in the sixteen-segment alphabet,
	// so this draws through BB_SEGMENT; the values are floored to int
	// because a decimal point costs a character cell and buys nothing
	// (the flat menu prints them whole too).
	static string XPPair(double xp, double maxxp)
	{
		if (maxxp <= 0) return "--";
		return "" .. int(xp) .. "/" .. int(maxxp);
	}

	// -----------------------------------------------------------------
	// THE SUBJECT'S COLOUR. A CARD'S FRAME IS THE COLOUR OF WHAT IT IS
	// ABOUT, and there are only two kinds of subject in this deck.
	//
	// A weapon wears its tier, from RS_TierPalette and nowhere else -- so
	// a ledger card for the mainhand is the same colour as the mainhand's
	// own subject card and the two read as one group across a fan of
	// eight. A weapon outside the roll system (a vanilla leftover, an
	// import) has no tier, and gets the same neutral grey the other cards
	// use for that case rather than a borrowed Basic white, which would
	// claim a rarity it does not have.
	// -----------------------------------------------------------------
	static Color AccentFor(Weapon wep)
	{
		let rsw = RS_Weapon(wep);
		if (!rsw) return Color(255, 200, 200, 200);
		return RS_TierPalette.RGB(rsw.Tier);
	}

	// -----------------------------------------------------------------
	// THE PLAYER ACCENT -- THE ONE NEW COLOUR IN THIS FILE.
	//
	// The player is not loot. There is no tier to read off them and
	// RS_TierPalette must not be asked for one, so the player's cards
	// need a colour of their own, and this is it.
	//
	// KNOWN NEIGHBOUR, CHECKED RATHER THAN ASSUMED, in the same spirit
	// RS_TierPalette's own header checks its: the nearest thing on the
	// ladder is Designer yellow (255, 225, 55). This is a warmer amber
	// and, more to the point, it can only ever appear on a card that
	// carries no tier word, no weapon and no rarity of any kind -- so
	// there is nothing for a misread to attach itself to. It is a ROLE
	// colour, exactly like RS_BBImprintCard's pale-blue hand headings,
	// and it is NOT a ninth rung.
	// -----------------------------------------------------------------
	static Color PlayerRGB() { return Color(255, 245, 150, 60); }

	// -----------------------------------------------------------------
	// EVERY CARD, FOR ONE SUBJECT OR FOR ALL OF THEM.
	//
	// subject is SUB_ALL for the whole deck (what the flat menu showed in
	// one column) or one of the three codes for that subject alone (what
	// the cycle key asks for). Both fill the same array; only the layout
	// downstream cares how many came back.
	//
	// ORDER IS LEFT TO RIGHT AND IT OBEYS THE HAND LAW: offhand first,
	// then the player, then the mainhand. The drop triptych and the
	// imprint card both put the offhand on the left and the mainhand on
	// the right, and a UI that reverses a spatial convention one screen
	// later is worse than one that never had it. A subject's ledger pages
	// sit immediately after its own subject card, so the deck reads as
	// three groups rather than as a shuffle.
	// -----------------------------------------------------------------
	static void Build(PlayerPawn pawn, int subject,
		out Array<RS_BBStatusCardData> cards)
	{
		cards.Clear();
		if (!pawn || !pawn.player) return;

		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		if (!stats) return;

		Weapon mainW = pawn.player.ReadyWeapon;
		Weapon offW  = pawn.player.OffhandWeapon;

		bool wantOff    = (subject == SUB_ALL || subject == SUB_OFFHAND)  && offW != null;
		bool wantMain   = (subject == SUB_ALL || subject == SUB_MAINHAND) && mainW != null;
		bool wantPlayer = (subject == SUB_ALL || subject == SUB_PLAYER);

		// Built into named locals rather than pushed straight into the
		// output, because the ledger pages have to be interleaved between
		// them and the page budget below is not known yet.
		RS_BBStatusCardData offCard;
		RS_BBStatusCardData mainCard;
		RS_BBStatusCardData playerCard;
		RS_BBStatusCardData fxCard;

		Array<RS_BBStatusRow> offBag;
		Array<RS_BBStatusRow> mainBag;
		Array<RS_BBStatusRow> playerBag;

		if (wantOff)
		{
			offCard = WeaponCard(stats, offW, "OFFHAND");
			BagRows(stats, offW, offBag);
		}
		if (wantMain)
		{
			mainCard = WeaponCard(stats, mainW, "MAINHAND");
			BagRows(stats, mainW, mainBag);
			fxCard = EffectsCard(stats, mainW);
		}
		if (wantPlayer)
		{
			playerCard = PlayerCard(stats);
			PlayerBagRows(stats, playerBag);
		}

		// --- how many cards are already spoken for ---------------------
		int fixedCards = 0;
		if (offCard)    fixedCards++;
		if (playerCard) fixedCards++;
		if (mainCard)   fixedCards++;
		if (fxCard)     fixedCards++;

		// --- PAGE BUDGET, ROUND ROBIN ----------------------------------
		// Pages are handed out one at a time, in turn, so that when the
		// cap bites nobody is starved: three bags wanting three pages
		// each with four pages to give get 2/1/1, not 3/1/0. Straight
		// first-come allocation would spend the whole budget on the
		// offhand and show the mainhand nothing, which is the opposite of
		// what a player wants to see.
		//
		// `progress` is what guarantees termination: a pass that hands
		// out nothing ends the loop, so a budget larger than the total
		// demand cannot spin.
		int budget = MAX_CARDS - fixedCards;
		if (budget < 0) budget = 0;

		// int(), not the raw Size(). Array.Size() is UNSIGNED and every
		// use of these below is mixed with signed arithmetic that can go
		// negative on the way to a max() or a subtraction. Pulling the
		// lengths into ints once keeps every comparison signed rather
		// than relying on where the promotion happens to land -- the same
		// habit RS_BBImprintCard's HandBlock records for the same reason.
		int offN    = int(offBag.Size());
		int mainN   = int(mainBag.Size());
		int playerN = int(playerBag.Size());

		int offWant    = Pages(offN);
		int mainWant   = Pages(mainN);
		int playerWant = Pages(playerN);

		int offGive = 0;
		int mainGive = 0;
		int playerGive = 0;

		bool progress = true;
		while (budget > 0 && progress)
		{
			progress = false;
			if (budget > 0 && offGive < offWant)
			{
				offGive++; budget--; progress = true;
			}
			if (budget > 0 && playerGive < playerWant)
			{
				playerGive++; budget--; progress = true;
			}
			if (budget > 0 && mainGive < mainWant)
			{
				mainGive++; budget--; progress = true;
			}
		}

		// --- what actually fits, and what is left over -----------------
		// ONE arithmetic for both the marker row and the subject card's
		// summary line. They said different numbers in the first draft --
		// the marker counted the entry whose slot it took, the summary
		// did not -- which is precisely the "consistent with itself"
		// failure that only shows up when a human reads both at once.
		int offShown    = Shown(offN,    offGive);
		int mainShown   = Shown(mainN,   mainGive);
		int playerShown = Shown(playerN, playerGive);

		int offHidden    = offN    - offShown;
		int mainHidden   = mainN   - mainShown;
		int playerHidden = playerN - playerShown;

		// --- assemble, left to right -----------------------------------
		if (offCard)
		{
			offCard.Summary = BagSummary(offN, offGive, offHidden);
			cards.Push(offCard);
			LedgerCards(cards, offBag, offGive, offShown, offHidden,
				offCard.Accent, "OFFHAND -- " .. offW.GetTag());
		}

		if (playerCard)
		{
			playerCard.Summary = BagSummary(playerN, playerGive, playerHidden);
			cards.Push(playerCard);
			LedgerCards(cards, playerBag, playerGive, playerShown, playerHidden,
				PlayerRGB(), "PLAYER");
		}

		if (mainCard)
		{
			mainCard.Summary = BagSummary(mainN, mainGive, mainHidden);
			cards.Push(mainCard);
			LedgerCards(cards, mainBag, mainGive, mainShown, mainHidden,
				mainCard.Accent, "MAINHAND -- " .. mainW.GetTag());
		}

		if (fxCard) cards.Push(fxCard);
	}

	// Pages a bag of n entries wants, at ROWS entries per page. Integer
	// ceiling; zero entries wants zero pages, so an empty bag costs no
	// card at all rather than an empty one.
	static int Pages(int n)
	{
		if (n <= 0) return 0;
		return (n + RS_BBStatusCard.ROWS - 1) / RS_BBStatusCard.ROWS;
	}

	// -----------------------------------------------------------------
	// HOW MANY ENTRIES ACTUALLY GET PRINTED, given the pages this bag
	// was granted.
	//
	// The subtraction is the whole point: when the list is cut short, the
	// LAST SLOT ON THE LAST PAGE is spent on the "+n more" marker, so one
	// fewer real entry is shown than the slots would suggest. Doing that
	// here, once, is what keeps the marker and the subject card's summary
	// quoting the same number.
	// -----------------------------------------------------------------
	static int Shown(int total, int pages)
	{
		if (pages <= 0 || total <= 0) return 0;
		int cap = pages * RS_BBStatusCard.ROWS;
		if (total <= cap) return total;
		return cap - 1;
	}

	// The subject card's bottom line about its own bag.
	static string BagSummary(int total, int pages, int hidden)
	{
		if (total <= 0)  return "NO UPGRADES YET";
		if (pages <= 0)  return "" .. total .. " UPGRADES -- CYCLE TO THIS SUBJECT";
		if (hidden > 0)  return "" .. hidden .. " MORE -- CYCLE TO THIS SUBJECT";
		return "" .. total .. " UPGRADES ON THE NEXT CARD";
	}

	// -----------------------------------------------------------------
	// SLICE A BAG INTO PAGES.
	//
	// `shown` already excludes the entry whose slot the overflow marker
	// takes (see Shown above), so the marker is APPENDED here rather than
	// overwriting a row. Appending past a full page would write a ninth
	// row into an eight-slot body -- the silent-overflow failure the row
	// ledger exists to prevent -- and the arithmetic that makes that
	// impossible is: last page holds shown - (pages-1)*ROWS entries,
	// which when the list was cut is exactly ROWS-1, leaving one slot.
	// -----------------------------------------------------------------
	static void LedgerCards(out Array<RS_BBStatusCardData> cards,
		Array<RS_BBStatusRow> bag, int pages, int shown, int hidden,
		Color accent, string subject)
	{
		for (int pg = 0; pg < pages; pg++)
		{
			let d = RS_BBStatusCardData.Make(RSSC_Ledger, "UPGRADES",
				subject, accent);

			int first = pg * RS_BBStatusCard.ROWS;
			int last  = min(first + RS_BBStatusCard.ROWS, shown);
			for (int i = first; i < last; i++)
				d.Rows.Push(bag[i]);

			if (pg == pages - 1 && hidden > 0)
				d.Rows.Push(RS_BBStatusRow.Make(
					"+" .. hidden .. " MORE", "", RSSR_Off, RSSP_None));

			if (pages > 1)
				d.Summary = "PAGE " .. (pg + 1) .. " OF " .. pages;
			else
				d.Summary = "" .. shown .. " OF " .. int(bag.Size()) .. " HELD";

			cards.Push(d);
		}
	}

	// -----------------------------------------------------------------
	// THE PLAYER'S HEADLINE CARD.
	//
	// The player's "XP" is a COUNT OF GUN LEVELS EARNED, not damage-based
	// experience -- TFLV_PerPlayerStats.AddPlayerXP is called with 1 each
	// time a weapon levels. That is why the row below says GUN LEVELS and
	// not XP, and why the ceiling comes from a cvar rather than a curve.
	// -----------------------------------------------------------------
	static RS_BBStatusCardData PlayerCard(TFLV_PerPlayerStats stats)
	{
		double pmax = PlayerLevelCost();
		bool banked = (pmax > 0 && stats.XP >= pmax);

		let d = RS_BBStatusCardData.Make(RSSC_Player, "PLAYER",
			banked ? "LEVEL UP READY" : "PROGRESS TO NEXT LEVEL",
			PlayerRGB());

		d.Level = int(stats.level);
		d.XP    = stats.XP;
		d.MaxXP = pmax;

		// Three rows, filling slots 5..7 under the headline block.
		d.AddRow("GUN LEVELS", XPPair(stats.XP, pmax));
		d.AddRow("UPGRADES",   "" .. int(stats.upgrades.upgrades.Size()));
		// How many guns have XP invested in them. Cheap, real, and the
		// only other number the player object actually holds -- the
		// alternative was leaving the slot empty or borrowing a row from
		// the ledger card sitting next to it, which would print the same
		// name twice on one screen.
		d.AddRow("GUNS TRACKED", "" .. int(stats.weapons.Size()));
		return d;
	}

	// -----------------------------------------------------------------
	// ONE HAND'S HEADLINE CARD.
	//
	// hand is "MAINHAND" or "OFFHAND" -- passed in rather than inferred,
	// because this is called for both and a card that guessed would be
	// right half the time and silently wrong the other half.
	// -----------------------------------------------------------------
	static RS_BBStatusCardData WeaponCard(TFLV_PerPlayerStats stats,
		Weapon wep, string hand)
	{
		if (!wep) return null;

		let rsw  = RS_Weapon(wep);
		let info = stats.GetInfoFor(wep);

		string tierWord = rsw ? RS_UIStyle.TierName(rsw.Tier) : "NOT ROLLED";
		bool banked = info && info.maxXP > 0 && info.XP >= info.maxXP;

		let d = RS_BBStatusCardData.Make(RSSC_Weapon, wep.GetTag(),
			hand .. " -- " .. (banked ? "LEVEL UP READY" : tierWord),
			AccentFor(wep));

		// A weapon that has never hurt anything has no WeaponInfo yet --
		// GunBonsai creates them lazily. Level 0 and an empty bar is the
		// honest picture of that, and the XP row says "--" rather than
		// "0/0", which would read as a real ceiling that has been reached.
		d.Level = info ? int(info.level) : 0;
		d.XP    = info ? info.XP    : 0.0;
		d.MaxXP = info ? info.maxXP : 0.0;

		// Five rows, filling slots 3..7 under the headline block.
		d.AddRow("XP", info ? XPPair(info.XP, info.maxXP) : "--");
		d.AddRow("TIER", tierWord);

		if (rsw)
		{
			// Pips are text glyphs on purpose (RS_UIStyle.Pips' own note),
			// and Row() routes them through BB_TEXT because a nine-cell
			// value inside a 0.24w segment box would be technically legal
			// and practically unreadable.
			d.AddRow("PROMOTION", RS_UIStyle.Pips(rsw.PromotionCount));

			// SOCKETS IS THE BRIDGE'S ANSWER, NOT A SECOND COUNT.
			// FittedNames is the sanctioned definition of "what is in a
			// socket"; GunBonaiSockets is how many the tier granted. The
			// row beneath it counts the whole bag, and the difference
			// between the two numbers is exactly the stat purchases --
			// which is the thing the ledger card's hollow pips show one
			// by one.
			Array<string> fitted;
			RS_GunBonsaiBridge.FittedNames(rsw, fitted);
			d.AddRow("SOCKETS",
				"" .. int(fitted.Size()) .. "/" .. rsw.GunBonaiSockets);
		}
		else
		{
			d.AddRow("PROMOTION", "--");
			d.AddRow("SOCKETS", "--");
		}

		// Held in a local, not chained into the concatenation. A ternary
		// inside a `..` chain either compiles or costs a boot to find
		// out, and this file cannot be built this session -- the same
		// reasoning RS_BBLevelUpCard.FromBundle gives for its own locals.
		int held = info ? int(info.upgrades.upgrades.Size()) : 0;
		d.AddRow("UPGRADES", "" .. held);

		// The flat menu's TYPE row is "tag (ClassName)". The tag is this
		// card's title, so the class name is what is left to say, and it
		// goes in the summary line where a long identifier has the whole
		// card width to shrink into.
		//
		// `.. ""` FIRST, in its own local. GetClassName() returns a Name,
		// not a String, and pairing one straight into a larger expression
		// is a type error this project has been bitten by before.
		string cls = wep.GetClassName() .. "";
		d.Summary = "TYPE " .. cls;
		return d;
	}

	// -----------------------------------------------------------------
	// A WEAPON'S BAG, AS ROWS.
	//
	// This is the SECOND question from the file header -- everything in
	// the bag, which is what the flat menu dumps -- and the pip is the
	// FIRST one, borrowed from the bridge by name. See the header for why
	// that is a derivation rather than a duplicate predicate.
	//
	// A disabled upgrade is marked in the LABEL as well as in colour.
	// Colour alone would be the only tell, and "this row is a slightly
	// different grey" is not a state anyone can read across a fan.
	// -----------------------------------------------------------------
	static void BagRows(TFLV_PerPlayerStats stats, Weapon wep,
		out Array<RS_BBStatusRow> rows)
	{
		rows.Clear();
		if (!wep) return;

		let info = stats.GetInfoFor(wep);
		if (!info) return;

		Array<string> fitted;
		let rsw = RS_Weapon(wep);
		if (rsw) RS_GunBonsaiBridge.FittedNames(rsw, fitted);

		int n = info.upgrades.upgrades.Size();
		for (int i = 0; i < n; i++)
		{
			let upg = info.upgrades.upgrades[i];
			if (!upg || upg.level <= 0) continue;

			string nm = upg.GetName();
			// Array.Find returns Size() for "not present" -- the same
			// idiom the vendored code uses (effects.find(effect) !=
			// effects.size()).
			bool socketed = (fitted.Find(nm) != fitted.Size());

			rows.Push(RS_BBStatusRow.Make(
				upg.enabled ? nm : ("[OFF] " .. nm),
				"" .. int(upg.level) .. "/" .. int(upg.max_level),
				upg.enabled ? RSSR_Plain : RSSR_Off,
				socketed ? RSSP_Filled : RSSP_Hollow));
		}
	}

	// -----------------------------------------------------------------
	// THE PLAYER'S BAG, AS ROWS.
	//
	// No pips at all: player upgrades occupy no socket -- sockets are a
	// property of a gun -- so a pip column here would invent a concept.
	// -----------------------------------------------------------------
	static void PlayerBagRows(TFLV_PerPlayerStats stats,
		out Array<RS_BBStatusRow> rows)
	{
		rows.Clear();
		int n = stats.upgrades.upgrades.Size();
		for (int i = 0; i < n; i++)
		{
			let upg = stats.upgrades.upgrades[i];
			if (!upg || upg.level <= 0) continue;

			string nm = upg.GetName();
			rows.Push(RS_BBStatusRow.Make(
				upg.enabled ? nm : ("[OFF] " .. nm),
				"" .. int(upg.level) .. "/" .. int(upg.max_level),
				upg.enabled ? RSSR_Plain : RSSR_Off,
				RSSP_None));
		}
	}

	// -----------------------------------------------------------------
	// THE LEGENDOOM EFFECTS CARD.
	//
	// MAINHAND ONLY, because that is what the flat menu shows: it reads
	// stats.winfo.ld_info, and winfo is the CURRENT weapon. The offhand
	// graft never added an effects section, so adding one here would be
	// this file inventing a screen rather than moving one.
	//
	// Returns null when there are no effects, so a non-Legendoom game
	// never sees an empty card. That test is also why this does not call
	// TFLV_Settings.have_legendoom(): a weapon carrying effects IS a
	// Legendoom weapon, and one fewer dependency is one fewer thing to
	// keep in step.
	// -----------------------------------------------------------------
	static RS_BBStatusCardData EffectsCard(TFLV_PerPlayerStats stats, Weapon wep)
	{
		if (!wep) return null;
		let info = stats.GetInfoFor(wep);
		if (!info || !info.ld_info) return null;

		int n = info.ld_info.effects.Size();
		if (n <= 0) return null;

		let d = RS_BBStatusCardData.Make(RSSC_Effects, "EFFECTS",
			"MAINHAND -- " .. wep.GetTag(), AccentFor(wep));

		// One page only. Legendoom's own slot ceiling is small
		// (bonsai_base_ld_effect_slots plus a per-rarity bonus), so ROWS
		// is not a real limit -- but it is CHECKED rather than assumed,
		// because bonsai_ignore_gun_rarity exists and a config this file
		// does not control must never be able to write a ninth row.
		int shown = min(n, RS_BBStatusCard.ROWS);
		if (shown < n) shown = RS_BBStatusCard.ROWS - 1;  // last slot pays for the marker

		for (int i = 0; i < shown; i++)
		{
			bool live = (info.ld_info.currentEffect == i);
			d.AddRow(TFLV_LegendoomUtil.GetEffectTitle(info.ld_info.effects[i]),
				live ? "ON" : "",
				live ? RSSR_Hot : RSSR_Plain,
				live ? RSSP_Filled : RSSP_Hollow);
		}
		if (shown < n)
			d.AddRow("+" .. (n - shown) .. " MORE", "", RSSR_Off, RSSP_None);

		// The one control on this screen that DOES work today, because it
		// is a keybind rather than a menu row: KEYCONF:20 binds P to
		// bonsai_cycle_ld_effect, which GunBonsai's EventHandler turns
		// into CycleLDEffect. Saying so is honest; saying "press Enter"
		// like the flat menu does would not be.
		d.Summary = "P CYCLES THE ACTIVE EFFECT";
		return d;
	}
}

// =====================================================================
// RS_BBStatusCard -- ONE CARD FACE.
//
// Every kind of card in this deck draws through this one function, and
// that is deliberate: a subject card, a ledger page and an effects list
// are different CONTENT on identical chrome, so they read as one deck at
// a glance and differ only where the difference is information.
//
// ---------------------------------------------------------------------
// THE VERTICAL LEDGER, AND THE PROOF THAT NOTHING COLLIDES.
//
// All offsets are FRACTIONS OF THE CARD'S OWN HEIGHT h, measured from
// its centre, + is up. Top edge +0.500, bottom edge -0.500. Every entry
// below is a HALF-EXTENT box, because a billboard is CENTRED on its
// position and reasoning in centres alone is how a row ends up half
// outside the card it "fits" in.
//
//   ROW_STEP = 0.0560h     the body's row pitch
//   line     = min(ROW_STEP*h*0.70, min(w,h)*0.062)     glyph height
//   ROW_HALF = ROW_STEP*0.70/2 = 0.0196h                half a glyph
//
// ROW_HALF IS AN UPPER BOUND, NOT AN EQUALITY, and that is what makes
// the proof hold on a card this file did not choose the shape of. `line`
// is bounded on BOTH axes: the step bound keeps a glyph clear of the row
// above it, the min(w,h) bound keeps the per-line character budget
// stable. On this deck's own 1:1.40 card the step bound wins
// (0.0560*6.30*0.70 = 0.2470 against 4.50*0.062 = 0.2790), so ROW_HALF is
// exact. On a misconfigured landscape card the min(w,h) bound wins, line
// gets SMALLER, and every gap below gets larger. The layout degrades
// toward "airy", never toward "overlapping".
//
//   band            centre     half      span                gap below
//   ---------------------------------------------------------------------
//   (top edge)      +0.5000                                  0.0150
//   header strip    +0.4200    0.0650    +0.3550 .. +0.4850  0.0190
//   subtitle        +0.3100    0.0260    +0.2840 .. +0.3360  0.0300
//   rule            +0.2500    0.0040    +0.2460 .. +0.2540  0.0364
//   body slot 0     +0.1900    0.0196    +0.1704 .. +0.2096  0.0168
//   body slot 1     +0.1340    0.0196    +0.1144 .. +0.1536  0.0168
//   body slot 2     +0.0780    0.0196    +0.0584 .. +0.0976  0.0168
//   body slot 3     +0.0220    0.0196    +0.0024 .. +0.0416  0.0168
//   body slot 4     -0.0340    0.0196    -0.0536 .. -0.0144  0.0168
//   body slot 5     -0.0900    0.0196    -0.1096 .. -0.0704  0.0168
//   body slot 6     -0.1460    0.0196    -0.1656 .. -0.1264  0.0168
//   body slot 7     -0.2020    0.0196    -0.2216 .. -0.1824  0.0344
//   rule            -0.2600    0.0040    -0.2640 .. -0.2560  0.0265
//   summary         -0.3150    0.0245    -0.3395 .. -0.2905  0.0155
//   footer plate    -0.4200    0.0650    -0.4850 .. -0.3550  0.0150
//   (bottom edge)   -0.5000
//
// FOURTEEN BANDS, EVERY GAP POSITIVE, smallest 0.0150h at the two card
// edges -- which are symmetric by construction, since the header and
// footer plates are the same size at the same distance from centre.
//
// TWO OF THOSE HALVES ARE DELIBERATE OVER-ESTIMATES, so the real gaps
// are wider than the table claims: the subtitle and summary are drawn at
// line*0.85, i.e. a true half of 0.0167h, against the 0.0260h and
// 0.0245h budgeted. Budgeting the generous number means a later decision
// to enlarge either row does not silently invalidate the table.
//
// In real distance, at the deck's own card (4.50 x 6.30 units, and 34
// units = 1 metre, read at RS_BBLevelUpScreen's REACH of 26 units =
// 0.76 m): 0.0150h = 0.0945 units = 2.8 mm, and the tightest inter-row
// air, 0.0168h = 0.106 units = 3.1 mm. At the SMALLEST card this deck can
// produce -- the eight-card fan narrows it to 3.757 x 5.26 -- those
// become 2.3 mm and 2.6 mm. Thin, and still clearance between BOXES
// rather than between ink: BB_SEGMENT fits its characters inside the box
// it is handed and BB_TEXT is drawn at its measured height, so the ink is
// always smaller than its allowance.
//
// A MULTI-SLOT BLOCK spans slots a..b with
//     centre = BODY_TOP - ROW_STEP*(a+b)/2
//     half   = ROW_STEP*(b-a)/2 + ROW_HALF
// which is EXACTLY the union of those slots' boxes -- so anything drawn
// inside a block is inside the ledger above, with no new proof needed.
// The two headline blocks:
//
//   PLAYER  big level  slots 0..2  centre +0.1340  half 0.0756
//                      number 2.4*line -> half 0.0470  < 0.0756  OK
//           XP bar     slots 3..4  centre -0.0060  half 0.0476
//                      bar 0.055h  -> half 0.0275      < 0.0476  OK
//   WEAPON  big level  slots 0..1  centre +0.1620  half 0.0476
//                      number 1.8*line -> half 0.0353  < 0.0476  OK
//           XP bar     slot  2     centre +0.0780  half 0.0196
//                      bar 0.030h  -> half 0.0150      < 0.0196  OK
//
// THE FRAME IS THE ONE THING OUTSIDE +/-0.500, by 0.010w and 0.0075h a
// side, exactly as RS_BBLevelUpCard's is -- both decks hang off the same
// arranger and a border that behaved differently between them would read
// as a bug. It does not break that arranger's overlap proof: the fan's
// tightest clear air is 0.908 units at eight cards and two neighbouring
// frames spend 0.045 units each, leaving 0.818.
//
// ---------------------------------------------------------------------
// THE HORIZONTAL LEDGER, in fractions of w. pad = 0.05w, so all content
// lives in [-0.45w, +0.45w]. These are ALLOWANCES: every string may be
// driven to the full width of its interval and the intervals still do
// not touch, and RS_BBCompose.Text SHRINKS rather than truncates, so
// hitting a limit costs size and never letters.
//
//   ledger row (with a pip)
//     pip     side min(line*0.36, 0.030w), centred -0.415w
//                                       -> [-0.4300, -0.4000]
//     label   align -1 at -0.385w, maxW 0.50w   [-0.3850, +0.1150]
//     value   box 0.24w, right edge +0.45w      [+0.2100, +0.4500]
//     gaps: 0.0200 margin / 0.0150 pip-label / 0.0950 label-value
//
//   ledger row (no pip -- every subject-card row)
//     label   align -1 at -0.45w, maxW 0.56w    [-0.4500, +0.1100]
//     value   as above                          [+0.2100, +0.4500]
//     gap 0.1000
//
//   headline
//     label   align -1 at -0.45w, maxW 0.30w    [-0.4500, -0.1500]
//     number  box 0.42w centred +0.24w          [+0.0300, +0.4500]
//     gap 0.1800; the bar is 0.90w centred, i.e. exactly the content rect
//
//   chrome
//     strip / footer plates 0.94w / 0.86w, rules 0.90w, all centred
//     title maxW 0.88w centred                  [-0.4400, +0.4400]
//     subtitle / summary maxW 0.90w centred     [-0.4500, +0.4500]
//     footer "CARD" align +1 at 0.00w, maxW 0.34w  [-0.3400, 0.0000]
//     footer number box 0.22w centred +0.16w       [+0.0500, +0.2700]
//     gap 0.0500, and both sit inside the plate's +/-0.43w
//
// ---------------------------------------------------------------------
// PART BUDGET: 11 pieces of chrome (frame, ground, strip, title,
// subtitle, 2 rules, summary, footer plate, footer word, footer number)
// plus at most 8 rows x 3 (pip, label, value) = 35 billboards worst case.
// A headline card spends fewer (3 for the headline, then 5 rows). Eight
// cards plus the banner is under 300 quads and they are STATIC -- see
// RS_BBLevelUpScreen.Place's note on why a settled screen costs nothing
// per tic.
//
// SUBMISSION ORDER IS DEPTH ORDER. Billboards do not depth-test against
// each other, so a plate drawn after the text it should sit behind
// ERASES it. Everything here is submitted back to front, once.
// =====================================================================
class RS_BBStatusCard play
{
	// Class scope: `const X = 5;` inside a function body is a parse error
	// in ZScript.
	const ROW_STEP = 0.0560;
	const ROW_HALF = 0.0196;   // ROW_STEP * 0.70 / 2 -- an upper bound
	const BODY_TOP = 0.1900;

	// THE ONE DEFINITION OF HOW MANY BODY SLOTS A CARD HAS.
	// RS_BBStatusSource reads it from here rather than declaring its own,
	// so pagination and layout cannot disagree about the page size.
	const ROWS = 8;

	// -----------------------------------------------------------------
	// GREYS COME FROM RS_BBImprintCard AND ARE NOT RESTATED HERE.
	//
	// Ink, dim, faint and the near-black used on a filled strip are a
	// VOCABULARY, not a per-card decision, and that file is where they
	// are already named and reasoned about. Copying the literals would
	// make a fifth grey table in a tree that has already had to
	// consolidate four colour ladders into RS_TierPalette. If those greys
	// ever move, this deck moves with them, which is the correct
	// behaviour.
	//
	// The two below are NOT greys and NOT on any ladder: they are
	// per-part constants the weapon card already uses, quoted so the two
	// decks match exactly.
	// -----------------------------------------------------------------
	static Color ValueRGB()    { return Color(255, 245, 245, 240); } // RS_BBWeaponCard.Cell's readout white
	static Color EmptyPipRGB() { return Color(255,  60,  58,  72); } // RS_BBWeaponCard's unfilled pip

	// -----------------------------------------------------------------
	// ONE BODY ROW: optional pip, label left, value hard right.
	//
	// THE VALUE'S PAYLOAD IS DECIDED BY THE STRING, NOT BY PREFERENCE.
	// RS_BBLevelUpCard.SegmentSafe is REUSED rather than re-transcribed --
	// its table came off the engine's own SegmentMask and a second copy
	// is a second thing to get wrong. Segment is the better draw (shader
	// arithmetic, sharp at any size, takes a glow) and Text is the only
	// one that can render a percent sign or a promotion pip row, so:
	//
	//   segment-safe AND short   -> BB_SEGMENT
	//   anything else            -> BB_TEXT, right-aligned in the same box
	//
	// THE LENGTH TEST IS NOT REDUNDANT WITH THE SAFETY TEST. "* * o o o"
	// is entirely legal sixteen-segment characters and would draw -- as
	// nine cells inside a 0.24w box, which the engine shrinks to
	// illegibility (it caps a cell at 0.88 of the box width divided by
	// the character count). A value that long is prose, and prose belongs
	// in Text.
	// -----------------------------------------------------------------
	private static void Row(RS_BBComposedPanel p, double y, double w,
		double line, RS_BBStatusRow r, Color accent)
	{
		if (!p || !r || r.Label == "") return;

		Color labelCol = RS_BBImprintCard.InkRGB();
		Color valCol   = ValueRGB();

		if (r.State == RSSR_Off)
		{
			labelCol = RS_BBImprintCard.FaintRGB();
			valCol   = RS_BBImprintCard.FaintRGB();
		}
		else if (r.State == RSSR_Hot)
		{
			labelCol = accent;
			valCol   = accent;
		}

		double labelX = -w * 0.45;
		double labelW =  w * 0.56;

		if (r.Pip != RSSP_None)
		{
			double pipS = min(line * 0.36, w * 0.030);
			RS_BBCompose.Plate(p, -w * 0.415, y, pipS, pipS,
				r.Pip == RSSP_Filled ? accent : EmptyPipRGB());
			labelX = -w * 0.385;
			labelW =  w * 0.50;
		}

		RS_BBCompose.Text(p, labelX, y, r.Label, line, labelCol, -1, labelW);

		if (r.Value == "") return;

		double boxW = w * 0.24;
		if (RS_BBLevelUpCard.SegmentSafe(r.Value) && r.Value.Length() <= 9)
			RS_BBCompose.Segment(p, w * 0.45 - boxW * 0.5, y, r.Value,
				boxW, line, valCol, 0.30, 0.55);
		else
			RS_BBCompose.Text(p, w * 0.45, y, r.Value, line * 0.92,
				valCol, 1, boxW);
	}

	// -----------------------------------------------------------------
	// THE HEADLINE BLOCK: one big number and one bar.
	//
	// A LEVEL IS THE ONE NUMBER ON THIS SCREEN YOU LOOK FOR FIRST, so it
	// is drawn at two to three times body size and the bar under it is
	// the only thing on the card with no words at all. That is also what
	// stops the player card reading as half empty: the player genuinely
	// has less state than a gun (TFLV_PerPlayerStats holds a level, a
	// count and a bag), so its headline is given more of the card instead
	// of the card being padded with rows borrowed from the ledger page
	// sitting next to it -- which would print the same names twice on one
	// screen.
	//
	// Every offset is derived from the block rule in the file header
	// rather than typed in twice.
	// -----------------------------------------------------------------
	private static void Headline(RS_BBComposedPanel p, double w, double h,
		double line, RS_BBStatusCardData d)
	{
		bool big = (d.Kind == RSSC_Player);

		// Player: number over slots 0..2, bar over slots 3..4.
		// Weapon: number over slots 0..1, bar on slot 2.
		double numB = big ? 2.0 : 1.0;   // number spans slots 0..numB
		double barA = big ? 3.0 : 2.0;
		double barB = big ? 4.0 : 2.0;

		double numY = (BODY_TOP - ROW_STEP * numB * 0.5) * h;
		double barY = (BODY_TOP - ROW_STEP * (barA + barB) * 0.5) * h;

		RS_BBCompose.Text(p, -w * 0.45, numY, "LEVEL", line,
			RS_BBImprintCard.DimRGB(), -1, w * 0.30);

		// Glow rides in Segment's own packed-glow argument, NOT in an
		// extra SetGlow call: `data` is packed glow on this payload and
		// setting it twice by two routes is two sources for one value.
		RS_BBCompose.Segment(p, w * 0.24, numY, "" .. d.Level,
			w * 0.42, line * (big ? 2.4 : 1.8), d.Accent, 0.45, 0.80);

		// BB_BAR grows its fill from the LEFT edge, so only the right end
		// moves as XP comes in -- which is what makes a glance at two
		// cards side by side comparable.
		RS_BBCompose.Bar(p, 0, barY, RS_BBStatusSource.Pct(d.XP, d.MaxXP),
			w * 0.90, h * (big ? 0.055 : 0.030), d.Accent);
	}

	// -----------------------------------------------------------------
	// THE CARD. Returns its FRAME plate so the screen can light it when
	// the hand or the aim ray is on this card -- the highlight is a
	// recolour of one existing part, not a rebuild and not a move.
	//
	// `index` is 1-based and `total` is the deck size; together they are
	// the footer. NOT a "PRESS n" prompt like the level-up card's: there
	// is nothing to press here, and a number that looks like a control
	// but is not one is worse than no number at all. It answers "how much
	// of this have I seen", which in a fan of eight is a real question.
	// -----------------------------------------------------------------
	static RS_Billboard Build(RS_BBComposedPanel p, double w, double h,
		RS_BBStatusCardData d, int index, int total)
	{
		if (!p || w <= 0 || h <= 0 || !d) return null;

		// TEXT SIZE IS SOLVED, NOT CHOSEN, and bounded on BOTH axes. See
		// the file header for why ROW_HALF stays an upper bound whichever
		// of the two bounds wins.
		double line = min(ROW_STEP * h * 0.70, min(w, h) * 0.062);

		// The frame IS the subject: across a fan you read the COLOURS
		// first and the words second, which is the only way a wide fan is
		// legible at all.
		let frame = RS_BBCompose.Plate(p, 0, 0, w * 1.020, h * 1.015, d.Accent);
		if (frame) frame.SetGlow(0.45, 0.55);

		// uObjectColor2's ALPHA is the gradient's on switch, so the
		// second colour carries a real alpha deliberately.
		let ground = RS_BBCompose.Plate(p, 0, 0, w, h, Color(240, 13, 13, 19));
		if (ground) ground.SetGradient(Color(200, 26, 24, 38));

		// --- header strip: the one place the accent is a solid fill ----
		let strip = RS_BBCompose.Plate(p, 0, h * 0.420, w * 0.94, h * 0.130,
			d.Accent);
		if (strip) strip.SetGlow(0.65, 0.80);
		RS_BBCompose.Text(p, 0, h * 0.420, d.Title, line * 1.15,
			RS_BBImprintCard.PlateInkRGB(), 0, w * 0.88);

		RS_BBCompose.Text(p, 0, h * 0.310, d.Subtitle, line * 0.85,
			RS_BBImprintCard.DimRGB(), 0, w * 0.90);

		RS_BBCompose.Plate(p, 0, h * 0.250, w * 0.90, h * 0.008,
			Color(255, 62, 58, 74));

		// --- body ------------------------------------------------------
		int head = RS_BBStatusCardData.HeadSlotsFor(d.Kind);
		if (head > 0) Headline(p, w, h, line, d);

		// HARD-CLAMPED, and that is what makes the header's arithmetic a
		// guarantee rather than an expectation. If a future content
		// change hands this nine rows, the card DROPS one rather than
		// writing it over the summary line. A layout that silently
		// overflows is the failure the whole ledger exists to prevent.
		int rows = min(int(d.Rows.Size()), ROWS - head);
		for (int i = 0; i < rows; i++)
			Row(p, (BODY_TOP - ROW_STEP * (head + i)) * h, w, line,
				d.Rows[i], d.Accent);

		RS_BBCompose.Plate(p, 0, -h * 0.260, w * 0.90, h * 0.008,
			Color(255, 62, 58, 74));

		RS_BBCompose.Text(p, 0, -h * 0.315, d.Summary, line * 0.85,
			RS_BBImprintCard.FaintRGB(), 0, w * 0.90);

		// --- footer: where this card sits in the deck ------------------
		RS_BBCompose.Plate(p, 0, -h * 0.420, w * 0.86, h * 0.130,
			Color(215, 30, 30, 40));
		RS_BBCompose.Text(p, 0, -h * 0.420, "CARD", line * 0.95,
			RS_BBImprintCard.DimRGB(), 1, w * 0.34);
		RS_BBCompose.Segment(p, w * 0.16, -h * 0.420,
			"" .. index .. "/" .. total, w * 0.22, line * 1.05,
			d.Accent, 0.35, 0.70);

		return frame;
	}

	// -----------------------------------------------------------------
	// THE BANNER over the deck.
	//
	// GEOMETRY IS RS_BBLevelUpCard.BuildBanner's, verbatim, because the
	// two banners hang off the same arranger at the same size (its
	// BANNER_W / BANNER_H / BANNER_GAP, and mBannerUp is computed by its
	// SolveFan / SolveGrid). Its own header carries the row proof for
	// h = 2.6: title +0.24h (half 0.406) spans +0.218..+1.030, name
	// -0.06h (half 0.338) spans -0.494..+0.182, hint -0.32h (half 0.243)
	// spans -1.075..-0.589, all inside +/-1.300 with every gap positive.
	//
	// It is re-implemented rather than called for one reason: that
	// function prints "WEAPON LEVEL UP" and takes an RS_Weapon to colour
	// itself by tier. This banner is about a SCREEN, not a weapon, and
	// there is no tier to read off it -- so it is deliberately the plain
	// off-white RS_TierPalette hands back for an unknown tier, which is
	// the one value on that ladder that claims nothing.
	//
	// THE THIRD LINE IS THE IMPORTANT ONE. The flat menu's controls help
	// says to press Enter to toggle an upgrade and Left/Right to tune it.
	// In the world neither does anything yet, so the banner says what is
	// true instead. A button you can see and not press is honest; a
	// prompt for a control that does not exist is not.
	// -----------------------------------------------------------------
	static void BuildBanner(RS_BBComposedPanel p, double w, double h,
		string subject)
	{
		if (!p || w <= 0 || h <= 0) return;

		double line = h * 0.26;
		Color plain = Color(255, 235, 235, 240);

		let frame = RS_BBCompose.Plate(p, 0, 0, w * 1.010, h * 1.040, plain);
		if (frame) frame.SetGlow(0.50, 0.65);

		let ground = RS_BBCompose.Plate(p, 0, 0, w, h, Color(240, 12, 12, 18));
		if (ground) ground.SetGradient(Color(200, 30, 26, 42));

		let title = RS_BBCompose.Text(p, 0, h * 0.24, "STATUS",
			line * 1.20, plain, 0, w * 0.90);
		if (title) title.SetGlow(0.40, 0.60);

		RS_BBCompose.Text(p, 0, -h * 0.06, subject, line,
			RS_BBImprintCard.InkRGB(), 0, w * 0.86);

		RS_BBCompose.Text(p, 0, -h * 0.32,
			"READ ONLY -- TOGGLE UPGRADES FROM THE FLAT SHEET",
			line * 0.72, RS_BBImprintCard.FaintRGB(), 0, w * 0.86);
	}
}

// =====================================================================
// RS_BBStatusScreen -- THE DECK IN THE AIR.
//
// ---------------------------------------------------------------------
// THIS IS NOT A THIRD LAYOUT ENGINE AND MUST NEVER BECOME ONE.
//
// RS_BBLevelUpScreen already solved "arrange N cards in front of a
// player" in two styles, with the overlap and off-axis arithmetic
// written out and proven for 1 through 8 (its header carries both
// tables). Everything below reuses it by INHERITANCE: Solve / SolveFan /
// SolveGrid decide the card size and where each card goes, Place walks
// them every tic with its lazy-follow and its staggered bloom,
// CardForHandle resolves a native hit id back to a card, and Close
// releases every handle. Not one line of that geometry is restated here.
//
// WHERE ITS API DOES NOT FIT, STATED PRECISELY RATHER THAN WORKED AROUND
// IN SILENCE:
//
//   RS_BBLevelUpScreen.Open() hardcodes BOTH the content type
//   (Array<RS_LevelUpOffer>) and the face builder
//   (RS_BBLevelUpCard.Build), so it cannot deal a deck of anything else.
//   Everything it does BEFORE that loop -- read the style cvar, read the
//   reach cvar, derive the drop and tilt from GAZE_DOWN, latch the
//   anchor yaw, clear the hot index and the age, raise mAlive, Solve(n)
//   -- is entirely content-agnostic and is exactly what this class
//   needs.
//
//   The honest fix is one small change to that file: a
//   `void Begin(PlayerPawn pawn, int n)` holding those eight
//   assignments, or an Open() that takes a builder. Neither exists and
//   that file is not mine this session, so OpenStatus() below REPEATS
//   those eight assignments and nothing else. If they ever drift, this
//   deck sits at the wrong distance or the wrong pitch -- visible
//   immediately, not silent.
//
//   SetHot() is not reusable either, and for a real reason rather than a
//   mechanical one: it recolours frames from RS_LevelUpOffer.KindRGB,
//   which is the LEVEL-UP vocabulary (affix white, mastery orange, stat
//   green, combo purple, promotion gold). A status card is not an offer,
//   and wearing an offer's colour would be a lie about what it is. So
//   the highlight here is SetHotCard(), below, which relights the card in
//   its own subject colour.
//
//   ZScript overrides require the base method to be declared `virtual`
//   and none of RS_BBLevelUpScreen's are -- so everything added here is a
//   NEW NAME (OpenStatus, SetHotCard, StatusStyle, CloseStatus), never a
//   same-name redefinition. ZScript also has no function overloading and
//   no field shadowing: a second `Open` or a second `mHot` in this
//   subclass would be a hard redefinition error, not an override.
//
// SCOPE IS INHERITED. RS_BBLevelUpScreen is `play`, so this is too --
// the same way RS_BBWeaponStatus inherits play from RS_BBScreen without
// restating it.
// =====================================================================
class RS_BBStatusScreen : RS_BBLevelUpScreen
{
	// Parallel to mCards. The CONTENT each card was built from, kept so
	// the highlight can relight a card in its own subject colour without
	// rebuilding it -- and so a future hit test can answer "which subject
	// is the hand on" rather than only "which index".
	//
	// AN OBJECT ARRAY, NOT Array<Color>, AND THAT IS NOT A STYLE CHOICE.
	// The colour is the only thing the highlight needs, but ZScript's
	// dynamic arrays are only instantiated for a fixed set of element
	// types and `Array<Color>` appears NOWHERE ELSE IN THIS TREE -- so it
	// is unproven on this engine build, and an unproven container is not
	// worth a whole-mod compile failure when an object array (which
	// mCards and mFrames already are) carries the same colour for free.
	Array<RS_BBStatusCardData> mData;

	// Which subject this deck was dealt for -- one of RS_BBStatusSource's
	// SUB_* codes, which are RS_UIHandler.mCycle's codes.
	int mSubject;

	// -----------------------------------------------------------------
	// STYLE. 0 FAN, 1 GRID: the same two arrangements the level-up screen
	// offers, because a card looks like a card whichever way it is dealt.
	//
	// rs_statuscard_style IS NOT DECLARED IN CVARINFO YET, and that is
	// not an oversight. CVar.FindCVar returns null for a name nobody
	// declared, so today this always falls through to the level-up
	// screen's own rs_levelupcard_style and the two decks arrange the
	// same way. Declaring it is a one-line CVARINFO edit whenever the
	// owner wants them to differ, and until then there is no dead cvar
	// sitting in an options menu doing nothing.
	// -----------------------------------------------------------------
	static int StatusStyle()
	{
		let cv = CVar.FindCVar("rs_statuscard_style");
		if (cv) return clamp(cv.GetInt(), 0, 1);
		return RS_BBLevelUpScreen.Style();
	}

	static string SubjectName(int subject)
	{
		if (subject == RS_BBStatusSource.SUB_OFFHAND)  return "OFFHAND";
		if (subject == RS_BBStatusSource.SUB_MAINHAND) return "MAINHAND";
		if (subject == RS_BBStatusSource.SUB_PLAYER)   return "PLAYER";
		return "EVERYTHING";
	}

	// -----------------------------------------------------------------
	// OPEN. Reads the live state, deals the deck, places it.
	//
	// The default subject is -1, spelled as a literal because a default
	// argument has to fold at compile time; it is RS_BBStatusSource
	// .SUB_ALL and the two are checked against each other by the fact
	// that SubjectName's three positive cases are the only other values.
	//
	// Returns null when there is nothing to show -- no player stats at
	// all, which is the case the flat menu answers with
	// "$TFLV_MENU_NO_STATS_FOUND". A screen that raises itself and then
	// renders nothing is indistinguishable from a broken one.
	// -----------------------------------------------------------------
	static RS_BBStatusScreen OpenStatus(PlayerPawn pawn, int subject = -1)
	{
		if (!pawn || !pawn.player) return null;

		Array<RS_BBStatusCardData> cards;
		RS_BBStatusSource.Build(pawn, subject, cards);
		if (cards.Size() == 0) return null;

		let s = new("RS_BBStatusScreen");
		s.mSubject = subject;

		// --- the eight assignments RS_BBLevelUpScreen.Open makes -------
		// See the class header: this is the duplication the missing
		// Begin() would remove, and it is the ONLY thing duplicated.
		s.mStyle = StatusStyle();
		s.mReach = RS_BBLevelUpScreen.Reach();
		// The drop and the tilt are one statement made twice: put the
		// deck on the resting gaze, and turn the cards to face the eye
		// looking down at it. dz/flat IS tan(GAZE_DOWN) by construction,
		// so the tilt is simply the gaze angle negated.
		s.mDrop  = s.mReach * tan(RS_BBLevelUpScreen.GAZE_DOWN);
		s.mTilt  = -RS_BBLevelUpScreen.GAZE_DOWN;
		s.mAnchorYaw = pawn.angle;      // LATCHED, not tracked
		s.mHot   = -1;
		s.mAge   = 0;
		s.mAlive = true;

		int n = cards.Size();
		s.Solve(n);          // fills mCardW / mCardH and the placements

		for (int i = 0; i < n; i++)
		{
			let p = new("RS_BBComposedPanel");
			let frame = RS_BBStatusCard.Build(p, s.mCardW, s.mCardH,
				cards[i], i + 1, n);
			s.mCards.Push(p);
			s.mFrames.Push(frame);
			s.mData.Push(cards[i]);

			// mKind BELONGS TO THE BASE AND NOTHING HERE READS IT.
			// It is filled anyway, one entry per card, for one reason:
			// the inherited SetHot() walks mFrames and indexes mKind at
			// the same position, so leaving it empty would turn a
			// mistaken call to the wrong highlight function into an
			// out-of-bounds VM abort instead of merely a wrong colour.
			s.mKind.Push(RSLU_Affix);
		}

		s.mBanner = new("RS_BBComposedPanel");
		RS_BBStatusCard.BuildBanner(s.mBanner,
			RS_BBLevelUpScreen.BANNER_W, RS_BBLevelUpScreen.BANNER_H,
			SubjectName(subject));

		s.Place(pawn);
		return s;
	}

	// -----------------------------------------------------------------
	// THE HIGHLIGHT IS OPTICAL, NOT GEOMETRIC.
	//
	// Popping the hot card forward would be prettier and would also
	// invalidate every overlap proof in the arranger's header the moment
	// two neighbours were both mid-animation. Recolouring one existing
	// plate cannot move anything.
	//
	// The lit state is a BRIGHTER GLOW ON THE SAME HUE rather than a
	// second table of lifted colours. This deck's accents are the eight
	// tier colours plus the player amber, and a hand-written "lit"
	// variant of each would be nine more literals to keep in step with
	// RS_TierPalette. Glow is the one lever that works for all of them.
	// -----------------------------------------------------------------
	void SetHotCard(int idx)
	{
		if (idx == mHot) return;
		mHot = idx;

		for (int i = 0; i < mFrames.Size() && i < mData.Size(); i++)
		{
			let f = mFrames[i];
			if (!f || !mData[i]) continue;

			bool hot = (i == idx);
			// data is 0 on a BB_PANEL -- the payload does not read it,
			// and glow for a plate is a setter, not packed bits.
			f.SetData(0, mData[i].Accent);
			f.SetGlow(hot ? 0.85 : 0.45, hot ? 1.00 : 0.55);
		}
	}

	// -----------------------------------------------------------------
	// CLOSE. The inherited Close() releases every panel and every handle
	// and is the one that matters -- a billboard handle dropped without
	// RemoveBillboard leaks a quad that lives until the level ends. This
	// drops the content alongside it. Those are plain data objects the
	// collector can see, so skipping this leaks nothing; it exists so a
	// dead screen cannot answer questions about a deck it no longer has.
	// -----------------------------------------------------------------
	void CloseStatus()
	{
		mData.Clear();
		Close();
	}
}

// =====================================================================
// HOW THE "I" KEY SHOULD REACH THIS -- REPORTED, NOT IMPLEMENTED.
//
// WHAT ACTUALLY HAPPENS TODAY, which is not quite what the brief said:
// KEYCONF:14 binds I to gboh-unified-info, NOT to bonsai-show-info
// (KEYCONF:3-8 says upstream's bind is deliberately left unbound because
// the unified one is a superset). That event lands in GunBonsai's
// EventHandler.GBOH_UnifiedInfo, whose FIRST act is
//
//     let rsui = RS_UIHandler(EventHandler.Find("RS_UIHandler"));
//     if (rsui) { rsui.CycleSheets(p); return; }
//
// so ShowInfo() -- and therefore Menu.SetMenu("GunBonsaiStatusDisplay")
// -- is only reached if RS_UIHandler is missing, which MAPINFO makes
// impossible. The flat GunBonsai status display is ALREADY unreachable
// from the keyboard; what the key really opens is RS_UIHandler's own
// RSDynamicSheet menu, cycling offhand -> mainhand -> player. That is the
// "button that cycles entire menus", and those three sheets are the three
// subjects this deck is built around.
//
// THE SMALLEST HONEST HOOKUP, editing nothing this session owns:
//
//   1. A handler owns one RS_BBStatusScreen, calls Place(pawn) in
//      WorldTick and CloseStatus() in WorldUnloaded (handles are not
//      actors and nothing collects them). RS_BBUIHandler in
//      RS_BillboardUI.zs is already exactly this shape and already
//      MAPINFO-registered.
//   2. In RS_UIHandler.CycleSheets, at the one line where it calls
//      Menu.SetMenu("RSDynamicSheet"), branch on a cvar:
//         in-world -> RS_BBStatusScreen.OpenStatus(pawn, mCycle)
//         flat     -> the existing Menu.SetMenu
//      mCycle is already 0/1/2 and RS_BBStatusSource's SUB_* codes are
//      deliberately the same three numbers, so nothing has to translate.
//      One press then re-deals the deck for the next subject, which is
//      the cycle the owner already has in his hands.
//   3. SUB_ALL -- every subject at once, up to eight cards -- is the
//      other mode and wants its own netevent and KEYCONF alias rather
//      than stealing the cycle key.
//
// SHOULD THE FLAT MENU STAY? YES, and not as a courtesy:
//
//   * it is the only place an upgrade can be TOGGLED or TUNED
//     (TFLV_Menu_UpgradeToggle turns Enter into bonsai-toggle-upgrade and
//     Left/Right into bonsai-tune-upgrade). Nothing in the world can do
//     that yet, which is why this deck's banner says so out loud.
//   * it is the fallback when the billboard natives are unavailable, and
//     this whole deck stands on natives that landed two days ago.
//   * removing it means editing zscript/gunbonsai/, which has to be a
//     deliberate decision rather than a side effect of adding a screen.
//
// So: cvar-selected, in-world once it has been looked at in a headset,
// flat menu still bound and still authoritative for anything
// interactive.
// =====================================================================
