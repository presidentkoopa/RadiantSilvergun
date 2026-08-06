// =====================================================================
// RS_DropTriptych -- the drop comparison card, in the world.
//
// THE SHAPE, AND WHY IT IS THIS SHAPE
// -----------------------------------------------------------------
// zscript/CardTemplate.txt -- the owner's own drawing, predating all of
// this -- is three panels side by side: offhand left, THE DROP IN THE
// MIDDLE, mainhand right. The flat menu could not do side-by-side, so
// docs/rs_10 flattened it into one column with the three values packed
// into a single space-padded string ("translated to chassis reality").
// This is the original drawing, built as drawn.
//
// THE PACKING GOES AWAY. On three physical panels each weapon gets an
// ordinary (label, value, colour) row list. No %5s padding, no
// monospace assumption -- that packing only ever existed because three
// columns had to fit in one string, and it was fragile in a
// proportional font anyway.
//
// WHO CARRIES THE VERDICT. The CENTRE panel is the thing being judged,
// so its rows carry the comparison colour -- green beats both hands,
// yellow beats one, brick beats neither. The wings show their own
// numbers in plain tan. That is the actual question being asked:
// "is this better than what I am holding?"
// =====================================================================

// Panel slots. In TALL mode only the three CORE panels exist; in
// STACKED mode each weapon grows an AFFIX and an IDENTITY panel hinged
// above and below its core.
//
// Declared at file scope, not nested in the class: this codebase's own
// enums (ERS_PanelFacing, EVR_Tier) all sit at file scope, and a
// nested enum referenced from another file is exactly the kind of
// resolution question that has cost this project a failed boot before.
// Not worth finding out.
enum ERS_TriSlot
{
	TRI_CoreDrop = 0,
	TRI_CoreOff,
	TRI_CoreMain,
	TRI_AffixDrop,
	TRI_AffixOff,
	TRI_AffixMain,
	TRI_KeyDrop,
	TRI_KeyOff,
	TRI_KeyMain,
	TRI_COUNT
}

// `play` required: FillAffixes and FillIdentity read live weapon and
// GunBonsai state (GetStatsFor, GetKeywordValue, GetPaletteArchetype,
// GetSlotCount) -- all play functions. An unscoped Object subclass is DATA
// scope, so without this every one of those calls fails and the locals they
// assign to cascade into "Unknown identifier" / "static context" errors.
class RS_DropTriptych play
{
	RS_PanelAssembly mAsm;
	Array<RS_PanelCard> mCards;
	Actor  mDropActor;
	bool   mStacked;

	// -----------------------------------------------------------------
	// Comparison. Colour IS the verdict -- there is no delta arrow and
	// no overall score line, deliberately: a win-count would weight
	// ACCURACY the same as PELLETS, which is false.
	// -----------------------------------------------------------------
	static int Verdict(double drop, double off, bool hasOff, double main, bool hasMain)
	{
		int wins = 0, losses = 0;
		if (hasOff)  { if (drop > off)  wins++; else if (drop < off)  losses++; }
		if (hasMain) { if (drop > main) wins++; else if (drop < main) losses++; }

		if (wins > 0 && losses == 0) return Font.CR_GREEN;
		if (wins > 0 && losses > 0)  return Font.CR_YELLOW;
		if (losses > 0)              return Font.CR_BRICK;
		return Font.CR_DARKGRAY;
	}

	// "--" for an absent hand, never "0" -- a fist that deals no splash
	// and a weapon that is not there are different facts.
	static string Cell(double v, bool present, int decimals = 0)
	{
		if (!present) return "--";
		// Spelled out rather than a star-precision "%.*f" -- ZScript's
		// String.Format supports a subset of printf and star precision
		// is not part of it.
		if (decimals >= 2) return String.Format("%.2f", v);
		if (decimals == 1) return String.Format("%.1f", v);
		return String.Format("%d", int(v));
	}

	// -----------------------------------------------------------------
	// One comparison row, written to all three core cards at once.
	// -----------------------------------------------------------------
	void TriRow(string label,
	            double dv, double ov, bool hasOff, double mv, bool hasMain,
	            int decimals = 0)
	{
		let cd = mCards[TRI_CoreDrop];
		let co = mCards[TRI_CoreOff];
		let cm = mCards[TRI_CoreMain];

		cd.AddRow(label, Cell(dv, true, decimals),
		          Verdict(dv, ov, hasOff, mv, hasMain));
		co.AddRow(label, Cell(ov, hasOff,  decimals), Font.CR_TAN);
		cm.AddRow(label, Cell(mv, hasMain, decimals), Font.CR_TAN);
	}

	// -----------------------------------------------------------------
	// Header for one card.
	// -----------------------------------------------------------------
	static void Header(RS_PanelCard c, string role, Weapon w)
	{
		let rsw = RS_Weapon(w);
		if (!w || !rsw)
		{
			// AN EMPTY HAND IS AN OFFER, NOT A BLANK.
			//
			// The card previously printed "EMPTY" and stopped, which reads
			// as a dead column -- the player has no way to know that
			// accepting fills it, so the most generous case in the whole
			// system looks like the least interesting one. Say it outright,
			// and say which control does it, because a comparison card that
			// does not tell you how to act on it is only half a card.
			c.SetHeader(role, Font.CR_DARKGRAY, "EMPTY", Font.CR_DARKGRAY);
			c.AddRow("ACCEPT -- GOES HERE", "", Font.CR_GREEN);
			c.AddRow(role == "OFFHAND" ? "  hold USE" : "  tap USE", "",
				Font.CR_GOLD);
			c.AddRow("(nothing is replaced)", "", Font.CR_DARKGRAY);
			return;
		}
		c.SetHeader(w.GetTag(), RS_UIStyle.TierColor(rsw.Tier),
		            RS_UIStyle.TierName(rsw.Tier) .. "   " ..
		            RS_UIStyle.Pips(rsw.PromotionCount),
		            RS_UIStyle.TierColor(rsw.Tier));
		c.AddRow(role, "", Font.CR_LIGHTBLUE);

		// THE CONTROL, ON EVERY WING, ALWAYS.
		//
		// tap USE -> mainhand, hold USE -> offhand. This is the fallback
		// that works with no binds configured and no pointing at all, so
		// it must be legible without the player having found anything in
		// a menu first. It is stated on the occupied wings as well as the
		// empty ones, because the accept control does not change when the
		// hand is full -- only the consequence does, and that is what the
		// comparison rows below are for.
		//
		// THE DROP panel is deliberately excluded: it is the thing being
		// judged, not a destination, and putting a control on it would
		// invite the player to try to accept "into" the drop itself.
		if (role == "OFFHAND")
			c.AddRow("hold USE to take", "", Font.CR_GOLD);
		else if (role == "MAINHAND")
			c.AddRow("tap USE to take", "", Font.CR_GOLD);
	}

	// -----------------------------------------------------------------
	// CORE STATS -- the comparison proper.
	// -----------------------------------------------------------------
	void FillCore(PlayerPawn pawn, Weapon drop, Weapon off, Weapon main)
	{
		let rd = RS_Weapon(drop);
		let ro = RS_Weapon(off);
		let rm = RS_Weapon(main);
		if (!rd) return;

		bool hasOff  = (ro != null);
		bool hasMain = (rm != null);

		Header(mCards[TRI_CoreDrop], "THE DROP",  drop);
		Header(mCards[TRI_CoreOff],  "OFFHAND",   off);
		Header(mCards[TRI_CoreMain], "MAINHAND",  main);

		// Fists cannot receive a class weapon. Say so on the wing that
		// is a fist, rather than letting the player point at it and get
		// silence.
		if (ro && IsRealFist(ro))
			mCards[TRI_CoreOff].AddRow("CANNOT APPLY - FIST", "", Font.CR_DARKRED);
		if (rm && IsRealFist(rm))
			mCards[TRI_CoreMain].AddRow("CANNOT APPLY - FIST", "", Font.CR_DARKRED);

		for (int i = 0; i < 3; i++) mCards[i].AddRule();

		// PELLETS leads on purpose: it is the stat Promotion grows
		// permanently, so it is the one a player is most often deciding
		// about, and it multiplies everything below it.
		TriRow("PELLETS",
			rd.PelletCount,
			hasOff  ? ro.PelletCount : 0, hasOff,
			hasMain ? rm.PelletCount : 0, hasMain);

		TriRow("DAMAGE/PELLET",
			rd.DamagePerShot,
			hasOff  ? ro.DamagePerShot : 0, hasOff,
			hasMain ? rm.DamagePerShot : 0, hasMain);

		TriRow("VOLLEY",
			rd.DamagePerShot * max(1, rd.PelletCount),
			hasOff  ? ro.DamagePerShot * max(1, ro.PelletCount) : 0, hasOff,
			hasMain ? rm.DamagePerShot * max(1, rm.PelletCount) : 0, hasMain);

		TriRow("DPS",
			rd.DamagePerShot * max(1, rd.PelletCount) * max(1, rd.RateOfFire),
			hasOff  ? ro.DamagePerShot * max(1, ro.PelletCount) * max(1, ro.RateOfFire) : 0, hasOff,
			hasMain ? rm.DamagePerShot * max(1, rm.PelletCount) * max(1, rm.RateOfFire) : 0, hasMain);

		TriRow("RATE OF FIRE",
			rd.RateOfFire,
			hasOff  ? ro.RateOfFire : 0, hasOff,
			hasMain ? rm.RateOfFire : 0, hasMain);

		TriRow("ACCURACY",
			rd.Accuracy,
			hasOff  ? ro.Accuracy : 0, hasOff,
			hasMain ? rm.Accuracy : 0, hasMain, 1);

		TriRow("CRIT %",
			rd.CritChance * 100.0,
			hasOff  ? ro.CritChance * 100.0 : 0, hasOff,
			hasMain ? rm.CritChance * 100.0 : 0, hasMain, 1);

		// CritMult 0 means the weapon never rolled it and dispatch
		// falls back to 2.0. Showing a raw 0 would read as "no crit
		// damage", which is the opposite of true.
		TriRow("CRIT MULT",
			rd.CritMult > 0 ? rd.CritMult : 2.0,
			hasOff  ? (ro.CritMult > 0 ? ro.CritMult : 2.0) : 0, hasOff,
			hasMain ? (rm.CritMult > 0 ? rm.CritMult : 2.0) : 0, hasMain, 2);

		TriRow("VELOCITY",
			rd.Velocity,
			hasOff  ? ro.Velocity : 0, hasOff,
			hasMain ? rm.Velocity : 0, hasMain);

		TriRow("CAPACITY",
			rd.Capacity,
			hasOff  ? ro.Capacity : 0, hasOff,
			hasMain ? rm.Capacity : 0, hasMain);

		TriRow("RELOAD SPEED",
			rd.ReloadSpeed,
			hasOff  ? ro.ReloadSpeed : 0, hasOff,
			hasMain ? rm.ReloadSpeed : 0, hasMain, 2);

		// Choke is rolled on every weapon in the arsenal but only bites
		// at 2+ pellets. Show the roll, and mark it inert rather than
		// hiding it -- Promotion turns it live.
		TriRow("CHOKE",
			rd.Choke,
			hasOff  ? ro.Choke : 0, hasOff,
			hasMain ? rm.Choke : 0, hasMain, 2);
		if (rd.PelletCount < 2)
			mCards[TRI_CoreDrop].AddRow("  (choke inert below 2 pellets)", "", Font.CR_DARKGRAY);

		TriRow("SOCKETS",
			rd.GunBonaiSockets,
			hasOff  ? ro.GunBonaiSockets : 0, hasOff,
			hasMain ? rm.GunBonaiSockets : 0, hasMain);

		TriRow("CONDITION",
			rd.Condition,
			hasOff  ? ro.Condition : 0, hasOff,
			hasMain ? rm.Condition : 0, hasMain);

		// The condition band, spelled out. RS_Roll.GetConditionEffects
		// is NOT pure -- bands 30-49 roll internally, so calling it for
		// a readout would both return a random sample and advance the
		// RNG. The band name is derived from the number instead.
		mCards[TRI_CoreDrop].AddRow("  " .. BandName(rd.Condition), "",
			RS_UIStyle.ConditionColor(rd.Condition));

		// The Cursed tell. A cursed weapon rolls GOOD numbers under
		// locks -- it is a gamble, not a downgrade, so the locks have to
		// be visible next to the numbers that look attractive.
		string locks = LockDigest(rd);
		if (locks != "")
		{
			mCards[TRI_CoreDrop].AddRule();
			mCards[TRI_CoreDrop].AddRow("LOCKED", locks, Font.CR_DARKRED);
		}
	}

	// Condition band names, from RS_Roll's own table. Note the shape is
	// a U-curve, not a decline: below 20 the gun rolls HOT -- more
	// damage, more pellets, and a real chance of backfiring in your
	// hands. A player reading only the colour would think low is simply
	// bad. It is not; it is loud.
	static string BandName(double c)
	{
		if (c >= 80) return "PRISTINE";
		if (c >= 70) return "SCUFFED";
		if (c >= 60) return "WORN";
		if (c >= 50) return "TIRED";
		if (c >= 40) return "UNSTABLE - may double-shot";
		if (c >= 30) return "ERRATIC - may double-shot";
		if (c >= 20) return "HOT - x1.25, 10% backfire";
		if (c >= 10) return "DANGEROUS - x1.5, 20% backfire";
		return "CRITICAL - x2.0, 35% backfire";
	}

	// -----------------------------------------------------------------
	// "Is this hand holding an actual fist?" -- the single predicate the
	// card and the netevent both ask, so they cannot disagree about what
	// is takeable.
	//
	// VR_FIST2 IS AN EMPTY SLOT, NOT A FIST. Every class grants it at
	// spawn as the filler that the real starting weapon bumps out, and
	// RS_Weapon.AttachToOwner already treats it as "slot is free"
	// (RS_Weapon.zs:1334). A plain `w is "VR_Fist"` catches it too --
	// VR_Fist2 descends from VR_Fist -- so the old check hid the TAKE row
	// in exactly the case where the take was guaranteed to work, and left
	// it visible in every case where it silently would not.
	//
	// VR_Fist4 and VR_Fist6 descend from VR_Fist2 and are filler in the
	// same way, so the test is `is VR_Fist2`, not a name comparison.
	static bool IsRealFist(Weapon w)
	{
		if (!w) return false;                 // empty hand is not a fist
		if (w is "VR_Fist2") return false;    // the filler: an open slot
		return (w is "VR_Fist");
	}

	static string LockDigest(RS_Weapon w)
	{
		string s = "";
		if (w.LockedDamage)     s = s .. "DMG ";
		if (w.LockedAccuracy)   s = s .. "ACC ";
		if (w.LockedVelocity)   s = s .. "VEL ";
		if (w.LockedCritChance) s = s .. "CRIT ";
		if (w.LockedCapacity)   s = s .. "CAP ";
		return s;
	}

	// -----------------------------------------------------------------
	// AFFIXES -- stacked mode only.
	//
	// A dropped weapon has never been wielded, so GunBonsai has no
	// WeaponInfo for it and info is NULL. That is not an error state and
	// must not render as "0 affixes, level 0" -- it is genuinely
	// unknown until you pick the thing up.
	// -----------------------------------------------------------------
	void FillAffixes(PlayerPawn pawn, Weapon w, int slot, string role)
	{
		let c = mCards[slot];
		let rsw = RS_Weapon(w);
		c.SetHeader(role, Font.CR_LIGHTBLUE, "AFFIXES", Font.CR_WHITE);

		if (!rsw) { c.AddRow("(empty)", "", Font.CR_DARKGRAY); return; }

		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		let info  = stats ? stats.GetInfoFor(w) : null;

		if (!info)
		{
			c.AddRow("SOCKETS", String.Format("%d", rsw.GunBonaiSockets), Font.CR_TAN);
			c.AddRule();
			c.AddRow("(never wielded --", "", Font.CR_DARKGRAY);
			c.AddRow(" affixes unknown)", "", Font.CR_DARKGRAY);
			return;
		}

		c.AddRow("LEVEL", String.Format("%d", info.level), Font.CR_TAN);
		c.AddRow("XP", RS_UIStyle.XPBar(info.XP, info.maxXP), Font.CR_TAN);

		int banked = info.CountPendingLevels();
		if (banked > 0)
			c.AddRow("LEVEL UP!", String.Format("%d", banked), Font.CR_ORANGE);

		c.AddRow("SOCKETS", String.Format("%d", rsw.GunBonaiSockets), Font.CR_TAN);
		c.AddRule();

		int shown = 0;
		for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
		{
			let upg = info.upgrades.upgrades[i];
			if (!upg || upg.level <= 0) continue;

			// Mastery is orange, always and only.
			int col = (upg.level >= 6) ? Font.CR_ORANGE
			        : (upg.level == 5) ? Font.CR_ORANGE
			        : Font.CR_WHITE;
			string lvl = (upg.level >= 6) ? "MASTERY"
			           : String.Format("Lv %d", upg.level);

			c.AddRow(upg.GetName(), lvl, col);
			shown++;
		}
		if (shown == 0) c.AddRow("(none yet)", "", Font.CR_DARKGRAY);
	}

	// -----------------------------------------------------------------
	// IDENTITY -- what this gun IS, as opposed to what it scores.
	// -----------------------------------------------------------------
	void FillIdentity(Weapon w, int slot, string role)
	{
		let c = mCards[slot];
		let rsw = RS_Weapon(w);
		c.SetHeader(role, Font.CR_LIGHTBLUE, "IDENTITY", Font.CR_WHITE);

		if (!rsw) { c.AddRow("(empty)", "", Font.CR_DARKGRAY); return; }

		c.AddRow("ARCHETYPE", rsw.GetPaletteArchetype(),         Font.CR_TAN);
		c.AddRow("TRIGGER",   rsw.GetKeywordValue("trigger"),    Font.CR_TAN);
		c.AddRow("DELIVERY",  rsw.GetKeywordValue("delivery"),   Font.CR_TAN);
		c.AddRow("PAYLOAD",   rsw.GetKeywordValue("payload"),    Font.CR_TAN);
		c.AddRow("FEED",      rsw.GetKeywordValue("feed"),       Font.CR_TAN);
		c.AddRow("RESERVE",   rsw.GetKeywordValue("reserve"),    Font.CR_TAN);
		c.AddRow("ELEMENT",   rsw.GetKeywordValue("element"),    Font.CR_TAN);
		c.AddRow("SET",       rsw.GetKeywordValue("set"),        Font.CR_TAN);

		int beats = rsw.GetSlotCount(0);
		if (beats > 1)
		{
			c.AddRule();
			c.AddRow("ROTATION", String.Format("%d beats", beats), Font.CR_LIGHTBLUE);
			let slotObj = rsw.GetSlot(0);
			for (int i = 0; i < beats && i < 8; i++)
			{
				let p = slotObj.PeekAt(i);
				if (p) c.AddRow(String.Format("  %d", i + 1), p.ProfileName, Font.CR_TAN);
			}
		}

		// Runtime-granted keywords: the honest "what has been bolted
		// onto this gun" list, as opposed to its authored identity.
		if (rsw.GrantedKeywords.Size() > 0)
		{
			c.AddRule();
			c.AddRow("GRANTED", "", Font.CR_LIGHTBLUE);
			for (int i = 0; i < rsw.GrantedKeywords.Size() && i < 8; i++)
				c.AddRow("  " .. rsw.GrantedKeywords[i], "", Font.CR_TAN);
		}
	}

	// -----------------------------------------------------------------
	// BUILD -- geometry, then content.
	// -----------------------------------------------------------------
	static RS_DropTriptych Build(PlayerPawn pawn, Actor dropActor, Weapon drop)
	{
		if (!pawn || !drop) return null;

		let t = new("RS_DropTriptych");
		t.mDropActor = dropActor;
		t.mStacked   = (RS_PanelController.Density() == 1);

		double w  = RS_PanelController.PanelWidth();
		double h  = RS_PanelController.PanelHeight();
		double hg = RS_PanelController.HingeAngle();
		double st = RS_PanelController.StackTilt();

		// A stacked column splits the same height three ways, so a
		// triptych occupies the same envelope in either mode.
		double coreH = t.mStacked ? h * 0.5 : h;

		t.mAsm = RS_PanelAssembly.Create(dropActor,
			(0, 0, RS_PanelController.HeightOfs()));

		for (int i = 0; i < TRI_COUNT; i++)
			t.mCards.Push(RS_PanelCard.Create(String.Format("RSPNL%02d", i + 1)));

		// The centre faces you and stays upright. Everything else is
		// FIXED and inherits from it, which is what keeps the fold
		// rigid as you walk around it.
		let core = t.mAsm.AddRoot("RSPNL01", w, coreH);
		if (!core) return null;

		// Wings hinge at the centre's vertical edges. Negative on the
		// right and positive on the left folds both toward the reader.
		let wingOff  = t.mAsm.AddHinged(core, RSPE_Left,  RSPE_Right,  hg, "RSPNL02", w, coreH);
		let wingMain = t.mAsm.AddHinged(core, RSPE_Right, RSPE_Left,  -hg, "RSPNL03", w, coreH);

		if (t.mStacked)
		{
			// Affix block above, identity block below, each canted so
			// the column curves toward the reader instead of standing
			// as a flat wall.
			t.mAsm.AddHinged(core,     RSPE_Top,    RSPE_Bottom, -st, "RSPNL04", w, h * 0.3);
			if (wingOff)  t.mAsm.AddHinged(wingOff,  RSPE_Top,    RSPE_Bottom, -st, "RSPNL05", w, h * 0.3);
			if (wingMain) t.mAsm.AddHinged(wingMain, RSPE_Top,    RSPE_Bottom, -st, "RSPNL06", w, h * 0.3);

			t.mAsm.AddHinged(core,     RSPE_Bottom, RSPE_Top,     st, "RSPNL07", w, h * 0.3);
			if (wingOff)  t.mAsm.AddHinged(wingOff,  RSPE_Bottom, RSPE_Top,     st, "RSPNL08", w, h * 0.3);
			if (wingMain) t.mAsm.AddHinged(wingMain, RSPE_Bottom, RSPE_Top,     st, "RSPNL09", w, h * 0.3);
		}

		t.Refresh(pawn, drop);
		return t;
	}

	void Refresh(PlayerPawn pawn, Weapon drop)
	{
		for (int i = 0; i < mCards.Size(); i++) mCards[i].Clear();

		Weapon off  = pawn.player ? pawn.player.OffhandWeapon : null;
		Weapon main = pawn.player ? pawn.player.ReadyWeapon   : null;

		FillCore(pawn, drop, off, main);

		if (mStacked)
		{
			FillAffixes(pawn, drop, TRI_AffixDrop, "THE DROP");
			FillAffixes(pawn, off,  TRI_AffixOff,  "OFFHAND");
			FillAffixes(pawn, main, TRI_AffixMain, "MAINHAND");

			FillIdentity(drop, TRI_KeyDrop,  "THE DROP");
			FillIdentity(off,  TRI_KeyOff,   "OFFHAND");
			FillIdentity(main, TRI_KeyMain,  "MAINHAND");
		}

		// The take action lives on the wings: point at the panel on your
		// left to send the drop to your left hand. The Hand Law stops
		// being a rule to memorise and becomes geometry.
		// A null hand is not a fist and not a weapon -- it is nothing to
		// point at, so it gets no action row either. Guarding both
		// keeps the card and the netevent agreeing about what is
		// takeable; if they disagreed the player would aim at a live
		// row and get silence.
		if (off && !IsRealFist(off))
			mCards[TRI_CoreOff].AddRow("> TAKE TO OFFHAND", "", Font.CR_GREEN, "rs-panel-take", 0);
		if (main && !IsRealFist(main))
			mCards[TRI_CoreMain].AddRow("> TAKE TO MAINHAND", "", Font.CR_GREEN, "rs-panel-take", 1);
	}

	RS_PanelCard CardFor(int slot) const
	{
		if (slot < 0 || slot >= mCards.Size()) return null;
		return mCards[slot];
	}

	void Dismiss()
	{
		if (mAsm) mAsm.Destroy();
		mAsm = null;
		mCards.Clear();
	}
}
