// =====================================================================
// RS_CardContent -- WHAT AN OFFER CARD SAYS, as plain data.
// ---------------------------------------------------------------------
// One list of lines, built from a weapon and (optionally) the weapon you
// are holding. No geometry, no billboards, no canvas: a renderer walks
// the list and draws it however that renderer draws things. Two of them
// are being written against this file right now, which is why every name
// below is fixed and none of them may be reshaped without saying so.
//
// WHY THIS EXISTS. RS_BBWeaponCard draws a fixed 4x3 grid of ALL twelve
// stats on every weapon. A pistol therefore shows PLT 1 and CHK -- two
// numbers that are constants for that gun and cannot inform any choice --
// while the numbers that DO decide the swap sit in the same grey column
// as the noise. The fix is not a smaller grid, it is CHOOSING: a row is
// emitted only when it can differ, and it carries the difference.
//
// THE CONTRACT, in one paragraph, because renderers need it:
//   * A line is a stat row unless one of IsRule / IsSection / IsProse is
//     set. Exactly one of those is ever set at a time.
//   * IsRule    -- a horizontal divider. Label and Value are both "".
//   * IsSection -- a small uppercase heading. LABEL CARRIES THE TEXT,
//     Value is "".
//   * IsProse   -- full-width wrapped text. LABEL CARRIES THE TEXT,
//     Value is "". Same rule as IsSection deliberately: two fields for
//     "the one string on this line" is how the two diverge later.
//   * A stat row always has a Label and a Value. DeltaText is "" and
//     DeltaState is NONE when there is nothing to compare against --
//     NEVER a fake "(+0)", which would read as "identical" when the
//     truth is "unknown".
//   * On a STAT row, LabelColor is RS_BBWeaponCard.StatRGB()'s answer
//     and nothing else. Where a row has no entry in that table (CHK),
//     StatRGB returns its own neutral default and that IS the answer --
//     inventing a second colour here is how a project ends up with four
//     colour ladders that have drifted apart, which is exactly what
//     RS_TierPalette was created to end. Sections, prose and empty
//     sockets are not stats and carry their own muted greys.
//
// *** BB_SEGMENT HAS NO COMMA, AND NO PERCENT SIGN. ***
// Verified in the engine this mod is built for, not assumed:
// SegmentMask() at E:\UZDXREMA\src\rendering\hwrenderer\scene\hw_sprites.cpp
// :1964 accepts digits, A-Z (case-folded), and
//     - _ = + * / \ | ' " ( ) [ ] ? ! . :
// and returns 0 for everything else. EmitBillboardSegments then does
// `if (mask != 0) emit(...)` and advances the pen REGARDLESS, so an
// unlisted character is skipped SILENTLY while the layout still reserves
// its cell. "(+2,+3)" renders as "(+2 +3)" with no error in any log.
// Every string this file emits is therefore built from that alphabet:
// "/" separates the halves of a composite delta, "=" means unchanged,
// and no value carries a "%" no matter how much it wants one.
//
// EVERY VALUE IS AN INTEGER. Crit chance rolls 1-5%, so a whole percent
// spans the entire range; a decimal point would spend a character cell
// on every readout for granularity nobody can act on. The full status
// sheet (RS_Screens / RS_Slate) keeps its decimals -- this is a card you
// read in half a second while something is shooting at you.
//
// CURSED STATS READ "???" HERE EXACTLY AS THEY DO EVERYWHERE ELSE.
// RS_Slate.zs:1424 states the law: the sheet and the in-world screen
// must not disagree about what the player is allowed to know, or one of
// them gives the game away. The number is what the gold is buying. That
// extends further than the Slate needed to go: a DERIVED row leaks its
// inputs (DPS is damage times two constants, so printing DPS prints the
// damage), and so does a DELTA against a cursed weapon in the OTHER
// hand (offer minus held reveals held). Both are suppressed below.
// =====================================================================

// Plain Object, NO scope qualifier, deliberately -- this is data, and it
// has to be readable from a ui-scope renderer and writable from the play
// -scope builder below. Adding `play` here would lock every renderer out
// of the thing they exist to draw.
class RS_CardLine : Object
{
	string  Label;        // "DMG", "TOTAL/SHOT"; the whole text on a section/prose line
	string  Value;        // "8-14", "30"; "" on rules, sections and prose
	Color   LabelColor;   // RS_BBWeaponCard.StatRGB(), never a local invention
	string  DeltaText;    // "(+2/+3)", or "" when nothing to compare
	int     DeltaState;   // RS_CardContent.RS_CARDDELTA_*
	bool    IsRule;       // horizontal divider
	bool    IsSection;    // small uppercase heading, Label carries the text
	bool    IsProse;      // full-width wrapped text, Label carries the text
}

// `play`, NOT a bare class. A class with no scope qualifier defaults to
// DATA, and this one reads live weapons and calls RS_GunBonsaiBridge --
// a play class. Third file today to need this said out loud.
class RS_CardContent play
{
	const RS_CARDDELTA_NONE  = 0;   // no comparison available
	const RS_CARDDELTA_SAME  = 1;
	const RS_CARDDELTA_UP    = 2;   // strictly better
	const RS_CARDDELTA_DOWN  = 3;   // strictly worse
	const RS_CARDDELTA_MIXED = 4;   // one end up, other down

	// -----------------------------------------------------------------
	// UP green, DOWN red, MIXED yellow, everything else neutral.
	//
	// The green and the red are RS_Slate.DirTint's values to the byte, so
	// the two screens cannot drift into arguing about which green means
	// better. The yellow is the WORN band from RS_BBWeaponCard.
	// ConditionRGB, for the same reason -- the card already has exactly
	// one yellow and this is it.
	//
	// NOT the tier ramp, deliberately (RS_Slate.zs:563 made this call
	// first): a delta answers "is this better", tier answers "how rare is
	// this", and one ramp serving both makes one of them unreadable.
	// -----------------------------------------------------------------
	static Color DeltaColor(int state)
	{
		if (state == RS_CARDDELTA_UP)    return Color(255,  90, 224, 110);
		if (state == RS_CARDDELTA_DOWN)  return Color(255, 228,  84,  70);
		if (state == RS_CARDDELTA_MIXED) return Color(255, 235, 210,  70);
		return Color(255, 150, 150, 150);
	}

	// =================================================================
	// THE ROWS, AND WHY EACH ONE IS OR IS NOT THERE.
	//
	// ALWAYS (they can differ on any two guns in the game):
	//   DMG      what one impact does. Labelled DMG/PLT when the volley
	//            is more than one pellet, because on those weapons the
	//            number is PER PELLET and a bare "DMG 8" next to a
	//            pistol's "DMG 30" is a lie of omission.
	//   DPS      the answer to the question actually being asked. Not a
	//            field on the weapon; = DamagePerShot * RateOfFire *
	//            PelletCount, the same product RS_Slate computes.
	//   ACC      the other half of whether damage lands.
	//   CND      an offer at 30% condition is a trap, and it is the one
	//            stat that is bad NEWS rather than a trade-off.
	//   SOCKETS  the count, per the contract.
	//
	// GATED (a constant for this weapon, so it informs nothing):
	//   PELLETS     PelletCount > 1. A "1" here is what the grid was
	//               printing on every pistol in the game.
	//   TOTAL/SHOT  PelletCount > 1. At one pellet it is DMG again to
	//               the digit, and a row that duplicates the row above
	//               it is worse than absent.
	//   CHK         PelletCount > 1. Choke is rolled on EVERY weapon in
	//               the arsenal (RS_DropTriptych.zs:244) and bites on
	//               none of them below two pellets -- RS_Weapon.zs:768
	//               gates it exactly there.
	//   MAG         Capacity > 1, or the capacity is cursed (see below).
	//               Capacity 1 is "this weapon has no magazine".
	//   CMUL        CritMult > 0. Zero does not mean "no crit damage",
	//               it means NEVER ROLLED, and dispatch falls back to
	//               the legacy 2.0 (RS_Weapon.zs:755). Printing "0"
	//               would state the opposite of the truth.
	//
	// DELIBERATELY ABSENT, and this is the part worth arguing with:
	//   ROF   folded into DPS. It is assigned by weapon identity and
	//         fixed by the fire animation, so it says nothing about THIS
	//         instance -- and where it does matter, it surfaces by name
	//         inside DPS's own delta the moment it disagrees with the
	//         other inputs. That is the only time it is load-bearing.
	//   VEL   second-order, and meaningless on the melee weapons that
	//         still roll it. Never decides a swap on its own.
	//   RLD   second-order. Its one dramatic effect, the bonus-round
	//         overflow, needs ReloadSpeed > 1.5 (RS_Weapon.zs:426) and
	//         the upgrade cards cap the stat at 1.4, so on a fresh offer
	//         that effect is unreachable.
	//   CRIT  1-5% across the whole tier ladder. As an integer it is a
	//         one-digit row that moves by one; as a decimal it costs a
	//         character cell on every card. It is on the status sheet.
	//   Both screens that DO show all twelve still exist and are one
	//   button away. This is a decision aid, not an inventory.
	// =================================================================
	static play void ForWeapon(RS_Weapon offered, RS_Weapon held, out Array<RS_CardLine> lines)
	{
		lines.Clear();
		if (!offered) return;

		// -------------------------------------------------------------
		// COMPARABILITY. Two weapons compare when all three hold:
		//   1. there IS a second weapon, and it is an RS_Weapon (the
		//      parameter type does that -- a fist or a vanilla import
		//      arrives here as null already),
		//   2. it has rolled (bStatsRolled). An unrolled weapon is a
		//      column of zeroes, and every delta against it would come
		//      back "+everything, strictly better",
		//   3. it is not the same object as the offer. Comparing a thing
		//      to itself yields a card of "(=)" that answers nothing.
		//
		// ARCHETYPE IS DELIBERATELY NOT PART OF THIS. The question a
		// card answers is "swap or not", which is almost always asked
		// across archetypes -- gating on a match would delete the deltas
		// in exactly the cases they are needed. The honest handling of a
		// shotgun-versus-pistol comparison is MIXED on the composite
		// rows, not a refusal to compare.
		//
		// Nulled here rather than checked at every row, so there is one
		// definition of "comparable" and no row can quietly disagree.
		// -------------------------------------------------------------
		if (held && (held == offered || !held.bStatsRolled))
			held = null;
		bool cmp = (held != null);

		// --- inputs, resolved once ------------------------------------
		int pellets  = max(1, offered.PelletCount);
		int hPellets = cmp ? max(1, held.PelletCount) : 1;
		int dmg      = offered.DamagePerShot;
		int hDmg     = cmp ? held.DamagePerShot : 0;
		int rof      = offered.RateOfFire;
		int hRof     = cmp ? held.RateOfFire : 0;

		// WHAT THE CURSE HIDES. Shown-ness is about the OFFER; the
		// delta additionally needs the HELD weapon's copy of the same
		// stat to be visible, because a subtraction against a hidden
		// number publishes that number.
		bool dmgShown   = !offered.LockedDamage;
		bool dmgCmp     = cmp && dmgShown && !held.LockedDamage;
		bool accShown   = !offered.LockedAccuracy;
		bool accCmp     = cmp && accShown && !held.LockedAccuracy;
		bool capShown   = !offered.LockedCapacity;
		bool capCmp     = cmp && capShown && !held.LockedCapacity;

		// =============================================================
		// STATS
		// =============================================================
		lines.Push(Section("STATS"));

		// --- DMG ------------------------------------------------------
		let rDmg = Row(pellets > 1 ? "DMG/PLT" : "DMG",
			dmgShown ? ("" .. dmg) : "???", "DMG");
		if (dmgShown) SimpleDelta(rDmg, dmgCmp, dmg, hDmg);
		lines.Push(rDmg);

		if (offered.PelletCount > 1)
		{
			// --- PELLETS ------------------------------------------------
			// Leads the volley pair because Promotion grows it
			// permanently, so it is the number a player is most often
			// deciding about, and it multiplies everything under it.
			let r = Row("PELLETS", "" .. offered.PelletCount, "PLT");
			SimpleDelta(r, cmp, offered.PelletCount, hPellets);
			lines.Push(r);

			// --- TOTAL/SHOT -- derived, and it earns the row ------------
			// The one number that says what pulling the trigger once
			// does. Neither DamagePerShot nor PelletCount answers it and
			// nothing on the weapon stores it.
			int total  = dmg * pellets;
			int hTotal = hDmg * hPellets;
			let rt = Row("TOTAL/SHOT", dmgShown ? ("" .. total) : "???", "DMG");
			if (dmgShown)
				CompositeDelta(rt, dmgCmp, total, hTotal,
					dmg - hDmg, pellets - hPellets, 0, 2);
			lines.Push(rt);
		}

		// --- DPS -- derived ------------------------------------------
		// Gated on a real cadence rather than clamped with max(1,...):
		// a weapon with no RateOfFire assigned would render a DPS equal
		// to its per-shot total, which is a different, wrong claim
		// dressed as a right one. Every shipped weapon assigns one.
		if (rof > 0)
		{
			int dps  = dmg * rof * pellets;
			int hDps = hDmg * hRof * hPellets;
			// Pellets only counts as a live input when one of the two
			// actually volleys; otherwise the delta grows a third "+0"
			// component on every pistol comparison in the game.
			bool pelletsLive = (pellets > 1 || hPellets > 1);
			let r = Row("DPS", dmgShown ? ("" .. dps) : "???", "DPS");
			if (dmgShown)
				CompositeDelta(r, dmgCmp && hRof > 0, dps, hDps,
					dmg - hDmg, rof - hRof, pellets - hPellets,
					pelletsLive ? 3 : 2);
			lines.Push(r);
		}

		// --- ACC ------------------------------------------------------
		int acc  = RoundI(offered.Accuracy);
		int hAcc = cmp ? RoundI(held.Accuracy) : 0;
		let rAcc = Row("ACC", accShown ? ("" .. acc) : "???", "ACC");
		if (accShown) SimpleDelta(rAcc, accCmp, acc, hAcc);
		lines.Push(rAcc);

		// --- CHK ------------------------------------------------------
		// Choke on a 0-100 scale (the field is 0..0.8; the upgrade cards
		// treat 0.8 as a mechanical bound, not a tier bound). Higher is
		// tighter: RS_Weapon.zs:768 multiplies spread by 1 - Choke*0.5.
		//
		// THE DELTA NEEDS THE HELD WEAPON TO VOLLEY TOO. Choke is rolled
		// on a pistol and does nothing there, so "your pistol's choke is
		// 40 and this shotgun's is 25" is arithmetic over a number that
		// has never affected a shot. The row still appears -- the offer
		// has live choke -- it simply has no comparison.
		if (offered.PelletCount > 1)
		{
			int chk  = RoundI(offered.Choke * 100.0);
			int hChk = cmp ? RoundI(held.Choke * 100.0) : 0;
			let r = Row("CHK", "" .. chk, "CHK");
			SimpleDelta(r, cmp && held.PelletCount > 1, chk, hChk);
			lines.Push(r);
		}

		// --- MAG ------------------------------------------------------
		// `|| !capShown` closes a leak rather than being defensive: a
		// curse HALVES capacity (RS_Weapon.zs:1877), so a 2-round weapon
		// cursed lands on 1, the gate drops the row, and a missing MAG
		// row on a cursed gun announces the exact thing the "???" is
		// there to conceal.
		if (offered.Capacity > 1 || !capShown)
		{
			let r = Row("MAG", capShown ? ("" .. offered.Capacity) : "???", "MAG");
			if (capShown)
				SimpleDelta(r, capCmp, offered.Capacity, cmp ? held.Capacity : 0);
			lines.Push(r);
		}

		// --- CMUL -----------------------------------------------------
		// Compared against the held weapon's EFFECTIVE multiplier, not
		// its stored one: 0 means never rolled and the shot dispatcher
		// substitutes 2.0, so a held 0 really is a x2 in the fiction the
		// player lives in. Comparing against the literal 0 would report
		// "+200" on a weapon that is no better at critting at all.
		if (offered.CritMult > 0)
		{
			int cm  = RoundI(offered.CritMult * 100.0);
			int hCm = cmp ? RoundI((held.CritMult > 0 ? held.CritMult : 2.0) * 100.0) : 0;
			let r = Row("CMUL", "" .. cm, "CMUL");
			SimpleDelta(r, cmp, cm, hCm);
			lines.Push(r);
		}

		// --- CND ------------------------------------------------------
		int cnd  = RoundI(offered.Condition);
		int hCnd = cmp ? RoundI(held.Condition) : 0;
		let rCnd = Row("CND", "" .. cnd, "CND");
		SimpleDelta(rCnd, cmp, cnd, hCnd);
		lines.Push(rCnd);

		// --- the curse footnote, and the one prose line this file emits
		// A column of "???" with nothing explaining it reads as a
		// rendering fault. This says it is deliberate.
		//
		// The count is OF THE STATS THIS CARD HIDES, not of every lock
		// on the weapon: LockedVelocity hides nothing here because VEL
		// is not a row, and a note claiming three hidden stats above two
		// "???" is itself a bug report.
		if (offered.HasAnyCurse())
		{
			int hidden = 0;
			if (!dmgShown)  hidden++;
			if (!accShown)  hidden++;
			if (!capShown)  hidden++;
			lines.Push(Prose(hidden > 0
				? ("CURSED - " .. hidden .. " STATS HIDDEN")
				: "CURSED"));
		}

		// =============================================================
		// SOCKETS -- the count.
		// =============================================================
		lines.Push(Rule());
		lines.Push(Section("SOCKETS"));

		// THE WEAPON'S OWN COUNT, not a tier lookup. RS_BBWeaponCard
		// takes max(GunBonaiSockets, SocketsForTier(Tier)) and that is a
		// second opinion about a number the weapon already stores -- the
		// same shape of divergence rule 6 exists to prevent. If the two
		// ever disagree the weapon is right, because the weapon is what
		// the affix installer writes into.
		int socks = offered.GunBonaiSockets;
		let rSoc = Row("SOCKETS", "" .. socks, "SOC");
		SimpleDelta(rSoc, cmp, socks, cmp ? held.GunBonaiSockets : 0);
		lines.Push(rSoc);

		// =============================================================
		// FITTED -- what is in them, by name.
		//
		// Names come from RS_GunBonsaiBridge.FittedNames and NOWHERE
		// ELSE. That function is already filtered to socket affixes
		// (it shares CountActiveAffixes' filter, which is the whole
		// point of it living there); a second walk over the upgrade bag
		// in this file would be a second definition of "what is on this
		// weapon", and the last time this project had two of those they
		// disagreed for months.
		//
		// A dropped weapon has never been wielded, so GunBonsai holds no
		// WeaponInfo for it and this comes back empty. That is honest --
		// an unwielded weapon genuinely has nothing fitted.
		// =============================================================
		Array<string> fitted;
		RS_GunBonsaiBridge.FittedNames(offered, fitted);

		// max(), not socks: if the bag somehow holds more fittings than
		// the weapon has slots, the extras are the interesting part and
		// dropping them silently is how the discrepancy stays invisible.
		int slots = max(socks, int(fitted.Size()));
		if (slots > 0)
		{
			lines.Push(Rule());
			lines.Push(Section("FITTED"));

			for (int i = 0; i < slots; i++)
			{
				bool filled = i < fitted.Size();
				// EMPTY SLOTS ARE ROWS. Omitting them makes the socket
				// count above a claim the list below silently
				// contradicts -- and the empty ones are what a player is
				// shopping for.
				let r = Row(filled ? fitted[i] : "EMPTY", "", "SOC");
				if (!filled) r.LabelColor = Color(255, 96, 92, 108);
				lines.Push(r);
			}
		}
	}

	// =================================================================
	// SELF-TEST. Prints exactly what a renderer would draw, with no
	// renderer -- so the content can be judged wrong before anyone has
	// drawn it wrong.
	//
	// *** THIS NEEDS ONE LINE IN MAPINFO.txt THAT IS NOT HERE. ***
	// RS_CardDumpHandler at the bottom of this file must also be named
	// in MAPINFO.txt's gameinfo AddEventHandlers list. A handler class
	// that is not listed there compiles cleanly and silently never runs
	// -- there is no Create()/Register() on StaticEventHandler in this
	// engine build (checked: E:\UZDXREMA\wadsrc\static\zscript\events.zs
	// declares only Find and the Send* family), so it cannot register
	// itself. This session was scoped to two files and MAPINFO is not
	// one of them; until that line is added, `netevent rs_card_dump`
	// does nothing and DumpFor must be called from code.
	// =================================================================
	static void DumpFor(RS_Weapon offered, RS_Weapon held)
	{
		Array<RS_CardLine> lines;
		ForWeapon(offered, held, lines);

		Console.Printf("%s", "=== RS_CardContent  offer: "
			.. (offered ? offered.GetTag() : "<none>")
			.. "   held: " .. (held ? held.GetTag() : "<none>")
			.. "   lines: " .. int(lines.Size()) .. " ===");

		for (int i = 0; i < lines.Size(); i++)
		{
			let r = lines[i];
			if (!r) continue;

			if (r.IsRule)
			{
				Console.Printf("%s", "  --------------------------------");
				continue;
			}
			if (r.IsSection)
			{
				Console.Printf("%s", "  [" .. r.Label .. "]");
				continue;
			}
			if (r.IsProse)
			{
				Console.Printf("%s", "  * " .. r.Label);
				continue;
			}

			// Hand-padded. String.Format's width flags on %s are not
			// worth betting a boot on when a while-loop is three lines.
			Console.Printf("%s", "  " .. Pad(r.Label, 12) .. Pad(r.Value, 8)
				.. Pad(r.DeltaText, 12) .. StateName(r.DeltaState));
		}
	}

	// -----------------------------------------------------------------
	// Row builders. `key` is the StatRGB lookup, which is NOT always the
	// label -- "DMG/PLT" and "TOTAL/SHOT" both colour as DMG, because
	// they are the damage family and colour is how a stat is found on
	// this card without reading the word.
	// -----------------------------------------------------------------
	private static RS_CardLine Row(string label, string value, string key)
	{
		let r = new("RS_CardLine");
		r.Label      = label;
		r.Value      = value;
		r.LabelColor = RS_BBWeaponCard.StatRGB(key);
		r.DeltaState = RS_CARDDELTA_NONE;
		return r;
	}

	private static RS_CardLine Section(string text)
	{
		let r = new("RS_CardLine");
		r.Label      = text;
		r.IsSection  = true;
		r.LabelColor = Color(255, 96, 92, 108);
		r.DeltaState = RS_CARDDELTA_NONE;
		return r;
	}

	private static RS_CardLine Prose(string text)
	{
		let r = new("RS_CardLine");
		r.Label      = text;
		r.IsProse    = true;
		r.LabelColor = Color(255, 190, 60, 60);   // RS_Slate.CurseTint()
		r.DeltaState = RS_CARDDELTA_NONE;
		return r;
	}

	private static RS_CardLine Rule()
	{
		let r = new("RS_CardLine");
		r.IsRule     = true;
		r.DeltaState = RS_CARDDELTA_NONE;
		return r;
	}

	// -----------------------------------------------------------------
	// A PLAIN ROW'S DELTA.
	//
	// Takes the ALREADY-ROUNDED display integers, never the doubles they
	// came from. A card whose printed delta does not equal the
	// difference of its two printed values looks broken even when the
	// arithmetic behind it is right, and ACC 74.6 vs 74.4 is exactly the
	// case that produces "74 vs 74, (+1)".
	//
	// Higher is better on every row this file emits, which is why there
	// is no per-row direction table. The one arguable case is CHK, where
	// "better" means a tighter cone -- true at range, a trade up close.
	// -----------------------------------------------------------------
	private static void SimpleDelta(RS_CardLine r, bool comparable, int newV, int oldV)
	{
		if (!comparable)
		{
			r.DeltaText  = "";
			r.DeltaState = RS_CARDDELTA_NONE;
			return;
		}

		int d = newV - oldV;
		if (d == 0)
		{
			r.DeltaText  = "(=)";
			r.DeltaState = RS_CARDDELTA_SAME;
			return;
		}

		r.DeltaText  = "(" .. Signed(d) .. ")";
		r.DeltaState = d > 0 ? RS_CARDDELTA_UP : RS_CARDDELTA_DOWN;
	}

	// -----------------------------------------------------------------
	// A DERIVED ROW'S DELTA -- AND WHY MIXED IS NOT DECORATION.
	//
	// TOTAL/SHOT and DPS are products. Their value moved one way, but
	// the gun did not necessarily get better: a shotgun that trades
	// pellet damage for pellet count can land on a higher total and be a
	// different weapon rather than a better one. Reporting that as a
	// green "+14" is a lie the player cannot see through, because the
	// components are not on the card.
	//
	// So a composite row compares its INPUTS, not just its product:
	//
	//   every input moved the same way (or only one moved at all)
	//       -> the product's own delta, plainly UP or DOWN. The total
	//          is the whole story and the components add nothing.
	//   the inputs disagree
	//       -> MIXED, and the text carries EACH component's delta,
	//          "/"-separated, because the total no longer explains
	//          itself. Order is damage / rate / pellets.
	//
	// live is 2 or 3 -- the number of components that can actually
	// differ for this pair of weapons.
	// -----------------------------------------------------------------
	private static void CompositeDelta(RS_CardLine r, bool comparable,
		int total, int prevTotal, int d1, int d2, int d3, int live)
	{
		if (!comparable)
		{
			r.DeltaText  = "";
			r.DeltaState = RS_CARDDELTA_NONE;
			return;
		}

		int pos = 0;
		int neg = 0;
		if (d1 > 0) pos++;
		else if (d1 < 0) neg++;
		if (d2 > 0) pos++;
		else if (d2 < 0) neg++;
		if (live >= 3)
		{
			if (d3 > 0) pos++;
			else if (d3 < 0) neg++;
		}

		if (pos > 0 && neg > 0)
		{
			// "/" and NOT ",". See the alphabet note at the top of this
			// file: a comma is skipped silently and the pen still moves,
			// so the wrong separator is invisible in every log and shows
			// up only as a gap on a panel nobody is looking at yet.
			string t = "(" .. Signed(d1) .. "/" .. Signed(d2);
			if (live >= 3) t = t .. "/" .. Signed(d3);
			t = t .. ")";

			r.DeltaText  = t;
			r.DeltaState = RS_CARDDELTA_MIXED;
			return;
		}

		SimpleDelta(r, true, total, prevTotal);
	}

	// -----------------------------------------------------------------
	// Signed integer, built by hand rather than through String.Format's
	// "%+d". The plus flag is one of the things this project does not
	// get to find out about at load time.
	// -----------------------------------------------------------------
	private static string Signed(int v)
	{
		if (v >= 0) return "+" .. v;
		return "-" .. (-v);
	}

	// Away-from-zero rounding. There is no round() to lean on and int()
	// truncates, which would print an accuracy of 74.9 as 74.
	private static int RoundI(double v)
	{
		if (v >= 0) return int(v + 0.5);
		return -int(-v + 0.5);
	}

	private static string Pad(string s, int w)
	{
		string o = s;
		while (o.Length() < w) o = o .. " ";
		return o;
	}

	private static string StateName(int state)
	{
		if (state == RS_CARDDELTA_SAME)  return "SAME";
		if (state == RS_CARDDELTA_UP)    return "UP";
		if (state == RS_CARDDELTA_DOWN)  return "DOWN";
		if (state == RS_CARDDELTA_MIXED) return "MIXED";
		return "-";
	}

	// -----------------------------------------------------------------
	// OPTIONAL, FOR RENDERERS ONLY. Nothing in this file calls it.
	//
	// Every string RS_CardContent builds is already inside BB_SEGMENT's
	// alphabet. The one string it does NOT control is a fitted affix's
	// name, which comes from that upgrade's own GetName() by way of
	// LANGUAGE -- so if a renderer pushes a FITTED row's label through
	// RS_BBCompose.Segment rather than Text, run it through here first.
	// A character outside the alphabet is dropped silently while the pen
	// still advances, so the failure is a gap, never an error.
	//
	// Substitutes rather than deletes: a dropped character shortens the
	// word invisibly, a "?" says a character was there.
	// -----------------------------------------------------------------
	static string SegSafe(string s)
	{
		// `res`, not `out` -- `out` is a parameter qualifier keyword and
		// naming a local that is a parse error.
		string res;
		for (int i = 0; i < s.Length(); i++)
		{
			int b = s.ByteAt(i);
			if (SegHas(b))      res = res .. s.Mid(i, 1);
			else if (b == 32)   res = res .. " ";     // space: a blank cell
			else                res = res .. "?";
		}
		return res;
	}

	// Byte codes rather than string comparisons: ZScript String is not
	// something to bet relational operators on, and ByteAt is the one
	// per-character accessor this project has already used. Transcribed
	// from SegmentMask()'s switch, case for case.
	private static bool SegHas(int b)
	{
		if (b >= 48 && b <= 57)  return true;   // 0-9
		if (b >= 65 && b <= 90)  return true;   // A-Z
		if (b >= 97 && b <= 122) return true;   // a-z, folded by the shader
		// - _ = + * / \ | ' " ( ) [ ] ? ! . :
		return b == 45 || b == 95 || b == 61  || b == 43 || b == 42
		    || b == 47 || b == 92 || b == 124 || b == 39 || b == 34
		    || b == 40 || b == 41 || b == 91  || b == 93 || b == 63
		    || b == 33 || b == 46 || b == 58;
	}
}

// =====================================================================
// RS_CardDumpHandler -- `netevent rs_card_dump [mode]`.
//
//   0 (default)  offer = mainhand, held = offhand
//   1            offer = offhand,  held = mainhand
//   2            offer = mainhand, held = NOTHING -- the no-comparison
//                path, which is the one that has to prove it emits ""
//                and NONE rather than a fake zero
//
// MUST BE NAMED IN MAPINFO.txt's AddEventHandlers OR IT SILENTLY NEVER
// RUNS. See the note on DumpFor above; that edit is not in this
// session's scope and has not been made.
// =====================================================================
class RS_CardDumpHandler : EventHandler
{
	override void NetworkProcess(ConsoleEvent e)
	{
		if (!(e.Name ~== "rs_card_dump")) return;
		if (e.Player < 0 || !playeringame[e.Player]) return;

		let pmo = players[e.Player].mo;
		if (!pmo || !pmo.player) return;

		let main = RS_Weapon(pmo.player.ReadyWeapon);
		let off  = RS_Weapon(pmo.player.OffhandWeapon);

		int mode = e.Args[0];
		if (mode == 1)      RS_CardContent.DumpFor(off, main);
		else if (mode == 2) RS_CardContent.DumpFor(main, null);
		else                RS_CardContent.DumpFor(main, off);
	}
}
