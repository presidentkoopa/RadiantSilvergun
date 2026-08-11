// =====================================================================
// RS_Imprint -- the late-game elite payout.
//
// THE HOLE THIS FILLS
// ---------------------------------------------------------------------
// RS_EliteDrop's WorldThingDied asks RS_ClassGating.NextMissingIdentity
// which of the player's six class-weapon identities is still missing,
// and BAILS when the answer is "" -- so the moment a player completes
// their set, every elite in the game pays food and nothing else. The
// elite layer, which is the hardest content in the mod, becomes worth
// less than a zombieman for the rest of the run. That is the whole
// reason this file exists.
//
// WHAT AN IMPRINT IS
// ---------------------------------------------------------------------
// A rolled STAT PACKAGE applied to a weapon the player already owns.
// The six class weapons are permanent chassis; an imprint deepens one.
// It is not a gun, it is not a pickup, and it never adds a seventh
// weapon to anybody's inventory.
//
// THE ROLL (owner's R2, docs/rs_32_affix_curse_workshop.txt)
// ---------------------------------------------------------------------
//   * the FULL ladder, Trash..Prototype -- not the Trash..Basic window
//     that pre-completion class-weapon drops are capped to
//   * weighted by the eight rs_elite_dropweight_* sliders, defaults
//     descending so the top of the ladder stays an event
//   * a +0/1/2 tier-bonus slider applied AFTER the roll, capped at
//     Prototype
//   * random family
//   * an elite killed before its 50% reveal pays nothing, ever -- that
//     gate already exists in RS_PanelDropHandler.WorldThingDied and this
//     branch sits downstream of it, so it is inherited rather than
//     re-implemented
//
// CURSED IS NOT A TIER AND IS NOT ROLLED HERE. It is an effect, from
// Promotion and from death (RS_Curses.zs). VRT_Cursed is already
// unreachable -- RS_PanelDropHandler.TierFloor returns VRT_Trash -- and
// Weight() below returns a hard 0 for that slot with NO CVAR BEHIND IT.
//
// So R2's "eight sliders" ships as SEVEN weight sliders (Trash through
// Prototype) plus the tier-bonus slider. There is deliberately no
// `rs_elite_dropweight_cursed`: a cvar that can never affect anything is
// a trap for the next reader, and a menu row for it would be a lie. The
// eight EVR_Tier SLOTS are still eight; only seven are rollable, and
// that is a consequence of the owner's own "Cursed is no longer a tier"
// ruling, not a shortcut taken here. Flagged for him rather than
// silently reconciled.
//
// =====================================================================
// HOW APPLYING WORKS -- RE-ROLL, KEEP BETTER (owner's decision,
// 2026-08-08)
// ---------------------------------------------------------------------
// Roll the weapon's stats at the imprint's tier, then for each stat keep
// whichever value is higher, the existing one or the newly rolled one.
// An imprint can therefore NEVER make a weapon worse, which is what
// makes a random-family package safe to hand out: a Shotgun-band roll
// landing on a Revolver can only lift the stats where the shotgun's
// bands happen to be generous, and is inert everywhere else.
//
// rs_imprint_mode flips this to a STRAIGHT re-roll (every stat takes the
// imprint's value, up or down, and the tier is assigned rather than
// raised). That is the riskier version the owner wants available later;
// keep-better is the default and mode 1 is opt-in.
//
// WHY THE PACKAGE IS ROLLED AT DROP TIME AND NOT AT APPLY TIME
// ---------------------------------------------------------------------
// Because the offer panel shows `old -> new`. A package rolled when the
// player accepts it cannot be previewed, only promised -- the card would
// have to show a range, and the number the player finally gets would be
// a different number from the one they decided on. So the dice are
// thrown when the elite dies; the card reads real values; accepting
// applies exactly what was on the card. "Roll the weapon's stats at the
// imprint's tier" is honoured, it just happens earlier.
//
// WHAT AN IMPRINT DELIBERATELY DOES NOT TOUCH
// ---------------------------------------------------------------------
// This list is the design, not an oversight, and every line of it is a
// case where writing the field would have quietly stolen another
// system's reward:
//
//   PelletCount    -- PROMOTION owns permanent pellet growth. Note that
//                     RollStats ASSIGNS PelletCount (`PelletCount = 1`
//                     on the Revolver), so anything that re-rolls a live
//                     weapon in place erases every promotion the player
//                     has ever paid for. See CLAUDE.md, "Never duplicate
//                     a design space another mechanic already owns as
//                     its reward."
//   PromotionCount -- same axis, permanent by contract.
//   Condition      -- REPAIR owns wear (Grey Bits, RS_Roll's repair
//                     curve). A free refill riding on a loot drop would
//                     delete that economy, and would also hand the
//                     player a silent DOWNGRADE in keep-better's mirror
//                     case, because low Condition is a GAMBLE here, not
//                     simply bad (RS_Roll.GetConditionEffects: below 20
//                     the gun rolls hot).
//   RateOfFire     -- identity, and pinned to the real fire-animation
//                     length by RS_Weapon's own contract. Carried on the
//                     package for DISPLAY only; never written.
//   Locked* /      -- the CURSE system owns those. RollStats CLEARS every
//   CurseStack*       Locked* flag as a side effect, which on a live
//                     weapon would be a free curse-wipe that also leaves
//                     the CurseStack* counters non-zero, i.e. desynced.
//                     Nothing here touches either set.
//   GunBonsai      -- level, XP and upgrades are GunBonsai's axis.
//   attack profiles / projectile class -- weapon identity.
//
// This is exactly the split the workshop doc states: "Chassis keeps:
// PelletCount, PromotionCount, GunBonsai level/XP/upgrades."
//
// THE CURSE GATE, WIRED AT LAST
// ---------------------------------------------------------------------
// RS_Weapon.CanAcceptImprint() has existed since 2026-08-07 and has
// never been fed by anything. It is the owner's ruling that a weapon
// carrying any curse refuses an imprint ABOVE its current tier until the
// curse is lifted. CanApplyTo() below is its first and only caller.
// Note what that deliberately still allows: a SAME-or-lower-tier imprint
// lands on a cursed weapon normally, so curses stall you, they do not
// trap you.
//
// THE DAMAGE BASELINE -- THE TRAP RS_EliteDrop ALREADY DOCUMENTS
// ---------------------------------------------------------------------
// PostBeginPlay rolls every weapon at Basic and captures THAT as its
// promotion baseline, and CaptureInitialDamageBaseline is a capture-ONCE
// guard. GetDamageCeiling() is baseline * 1.8, and the GunBonsai damage
// card stops being offered at the ceiling while the state-ladder tracer
// pins to "Peak" above 0.90 of it. So an imprint that raises
// DamagePerShot past a stale baseline would silently disable the
// player's own level-ups and freeze the tracer -- the identical failure
// RS_EliteDrop.Create's RollStats call had to fix with
// ResetDamageBaseline() + CaptureInitialDamageBaseline().
//
// ApplyTo does the same pair, but ONLY when the damage number actually
// moved. That guard matters: on a PROMOTED weapon the baseline is the
// promotion cut point, and re-anchoring it for an imprint that changed
// nothing would raise the ceiling for free.
// =====================================================================

// The stats an imprint knows about, in the order the offer panel should
// show them. File scope, not nested: this codebase's own enums
// (EVR_Tier, ERS_TriSlot, ERS_PanelFacing) all sit at file scope, and a
// nested enum read from another file is the kind of resolution question
// that has cost this project a boot before.
enum ERS_ImprintStat
{
	RSIS_Damage = 0,
	RSIS_Accuracy,
	RSIS_Velocity,
	RSIS_CritChance,
	RSIS_CritMult,
	RSIS_Capacity,
	RSIS_ReloadSpeed,
	RSIS_Choke,
	RSIS_Sockets,
	RSIS_RateOfFire,
	RSIS_COUNT
}

// `play` and it must be: ApplyTo writes fields on a live Actor, and an
// unscoped Object subclass is DATA scope, which cannot. Same reason
// RS_DropTriptych carries the keyword.
class RS_Imprint play
{
	// --- identity -----------------------------------------------------
	EVR_Tier          mTier;
	EVR_Family        mFamily;      // the random family this rolled from
	class<Actor>      mDonorClass;  // whose per-tier bands were rolled
	string            mDonorTag;    // that weapon's Tag, for the card

	// --- the rolled package -------------------------------------------
	int    mDamagePerShot;
	double mAccuracy;
	double mVelocity;
	double mCritChance;
	double mCritMult;
	int    mCapacity;
	double mReloadSpeed;
	double mChoke;
	int    mSockets;                // derived from mTier, not rolled
	int    mRateOfFire;             // DISPLAY ONLY -- never applied

	// Set once the package has been spent on a weapon, so a duplicated
	// netevent (a punch and a trigger landing on the same tic, which the
	// panel's own debounce is not a hard guarantee against) cannot apply
	// the same imprint twice.
	bool   mSpent;

	// False between Blank() and FillFrom() -- the window where the object
	// exists so the pedestal can answer "what shape is my marker" but the
	// dice have not been read off the donor yet. Nothing should ever see
	// it false, because Drop() closes the window in the same call; it is
	// here so a panel reading a half-built package shows nothing rather
	// than a wall of confident zeroes.
	bool   mRolled;

	// =================================================================
	// CVARS
	// =================================================================
	static bool Enabled()
	{
		return RS_Curse.CVBool("rs_imprint_enabled", true);
	}

	// 0 = re-roll, keep better (default). 1 = straight re-roll.
	static int Mode()
	{
		return clamp(RS_Curse.CVInt("rs_imprint_mode", 0), 0, 1);
	}

	static bool KeepBetter()
	{
		return Mode() == 0;
	}

	static bool RandomFamily()
	{
		// Fallback matches CVARINFO's default. It read `true` while the cvar
		// shipped true; both moved to false on 2026-08-11 and they have to
		// move together, or a missing cvar silently restores the old
		// behaviour on the one path nobody tests.
		return RS_Curse.CVBool("rs_imprint_randomfamily", false);
	}

	// -----------------------------------------------------------------
	// THE TIER WEIGHTS.
	//
	// One case per EVR_Tier slot so the names cannot drift out of step
	// with the enum. A switch and not a `static const int w[] = {...}` --
	// that array form does not reliably resolve on this engine build and
	// has produced a bogus "Unknown identifier" three separate times in
	// this tree (CLAUDE.md).
	//
	// Defaults sum to 100 on purpose, so each slider reads as a
	// percentage in the menu at stock settings, and they descend, so
	// Prototype stays rare without a second gate.
	// -----------------------------------------------------------------
	static int Weight(int tier)
	{
		switch (tier)
		{
			// A HARD ZERO WITH NO CVAR BEHIND IT, deliberately. Cursed is
			// no longer a tier -- it is an effect from Promotion and from
			// death -- and TierFloor() already made VRT_Cursed
			// unreachable. Giving this slot a slider would be shipping a
			// control that cannot do anything.
			case VRT_Cursed:    return 0;

			case VRT_Trash:     return max(0, RS_Curse.CVInt("rs_elite_dropweight_trash",     25));
			case VRT_Basic:     return max(0, RS_Curse.CVInt("rs_elite_dropweight_basic",     25));
			case VRT_Common:    return max(0, RS_Curse.CVInt("rs_elite_dropweight_common",    20));
			case VRT_Uncommon:  return max(0, RS_Curse.CVInt("rs_elite_dropweight_uncommon",  14));
			case VRT_Advanced:  return max(0, RS_Curse.CVInt("rs_elite_dropweight_advanced",   9));
			case VRT_Designer:  return max(0, RS_Curse.CVInt("rs_elite_dropweight_designer",   5));
			case VRT_Prototype: return max(0, RS_Curse.CVInt("rs_elite_dropweight_prototype",  2));
		}
		return 0;
	}

	// +0, +1 or +2 tiers, applied AFTER the weighted roll and capped at
	// Prototype. Deliberately post-roll rather than folded into the
	// weights: it shifts the whole distribution up by a fixed step, which
	// is a different knob from making one tier likelier, and it is the
	// one the owner asked for.
	static int TierBonus()
	{
		return clamp(RS_Curse.CVInt("rs_elite_imprint_tierbonus", 0), 0, 2);
	}

	// =================================================================
	// THE TIER ROLL
	// =================================================================
	static int RollTier()
	{
		int total = 0;
		for (int t = VRT_Cursed; t <= VRT_Prototype; t++)
			total += Weight(t);

		// Every slider zeroed. Trash rather than nothing: a player who
		// has turned the whole table off should still see the mechanism
		// work, and a silent no-drop is indistinguishable from a bug.
		if (total <= 0)
			return VRT_Trash;

		int roll = random[RSImprint](1, total);
		int acc  = 0;
		int picked = VRT_Trash;

		for (int t = VRT_Cursed; t <= VRT_Prototype; t++)
		{
			acc += Weight(t);
			if (roll <= acc) { picked = t; break; }
		}

		// int, then plain assignment on the caller's side. EVR_Tier(x) is
		// NOT a cast -- ZScript has no enum-constructor syntax, so it
		// parses as a call to an undefined function. Same trap, same fix,
		// as RS_EliteDrop.zs and RS_Weapon.UnlockStat.
		int bonused = picked + TierBonus();
		if (bonused > VRT_Prototype) bonused = VRT_Prototype;

		// Cursed can only be reached if someone edits Weight() above, but
		// belt and braces: the floor is Trash, always.
		if (bonused < VRT_Trash) bonused = VRT_Trash;
		return bonused;
	}

	// =================================================================
	// WHOSE BANDS GET ROLLED
	//
	// Owner's R2 says "all drops random family", so the default is a
	// random pick from the six VR_ class weapons -- the same list
	// RS_PanelDropHandler.ClassWeapon already owns, so there is exactly
	// one place that knows what the six are.
	//
	// rs_imprint_randomfamily off rolls the PLAYER'S OWN chassis instead.
	// That reading exists because R2 was written when a drop WAS a
	// weapon, where "random family" plainly meant "a random gun"; on a
	// data package it can equally mean "family-agnostic -- any package
	// fits any of your guns". Both readings are defensible and only the
	// owner can settle it, so both are here and the literal one is the
	// default. KEEP-BETTER IS WHAT MAKES THE LITERAL READING SAFE: a
	// mismatched family's bands can lift a stat or do nothing, and can
	// never cost the player anything.
	// =================================================================
	static class<Weapon> RollDonorClass(string mainhand)
	{
		if (!RandomFamily() && mainhand.Length() > 0)
		{
			class<Weapon> own = mainhand;
			if (own) return own;
		}
		return RS_PanelDropHandler.ClassWeapon(random[RSImprint](0, 5));
	}

	// =================================================================
	// BUILD THE PACKAGE off a freshly rolled donor instance.
	//
	// The donor is a real, rolled RS_Weapon -- which is how this gets the
	// per-weapon, per-tier hand-written bands for free and without a
	// second copy of every weapon's table. Stat rolls in this project are
	// NOT a multiplier over a base; each weapon writes its own ranges per
	// tier in its own RollStats override, and duplicating those here
	// would be a table that silently drifts out of step the first time
	// somebody tunes a gun.
	//
	// IT IS SPLIT IN TWO, and that is forced rather than tidy-minded.
	// The pedestal has to know it is carrying an imprint BEFORE it raises
	// its floor marker -- shape is the whole "what kind of drop is that"
	// read at range -- but the package's NUMBERS cannot exist until the
	// pedestal has spawned and rolled the donor. So the identity half is
	// built first (Blank), handed to the pedestal, and the numbers are
	// poured in a moment later (FillFrom). See RS_WeaponDrop.Create's own
	// note on the parameter.
	// =================================================================
	static RS_Imprint Blank(int tier)
	{
		let ip = new("RS_Imprint");
		ip.mTier    = tier;
		ip.mSockets = RS_Roll.SocketsForTier(tier);
		return ip;
	}

	void FillFrom(RS_Weapon donor)
	{
		if (!donor) return;

		mFamily        = donor.GetFamily();
		mDonorClass    = donor.GetClass();
		// GetTag() is a String; GetClassName() would be a Name and pairing
		// a Name with a string literal is a type error here (CLAUDE.md).
		mDonorTag      = donor.GetTag();

		mDamagePerShot = donor.DamagePerShot;
		mAccuracy      = donor.Accuracy;
		mVelocity      = donor.Velocity;
		mCritChance    = donor.CritChance;
		mCritMult      = donor.CritMult;
		mCapacity      = donor.Capacity;
		mReloadSpeed   = donor.ReloadSpeed;
		mChoke         = donor.Choke;
		mRateOfFire    = donor.RateOfFire;

		mRolled = true;
	}

	static RS_Imprint FromWeapon(RS_Weapon donor, int tier)
	{
		if (!donor) return null;
		let ip = RS_Imprint.Blank(tier);
		ip.FillFrom(donor);
		return ip;
	}

	// =================================================================
	// THE DATA SHAPE THE OFFER PANEL READS.
	//
	// Deliberately a flat indexed accessor rather than twelve named
	// getters: the panel is a list of rows, and a list of rows wants a
	// loop. Every question the card asks -- what is this stat called, how
	// many decimals, what does the weapon have now, what would it become,
	// is that up or down -- is answerable for any i without the panel
	// knowing a single field name on RS_Weapon.
	//
	// NOTHING IN HERE BUILDS UI. Row layout, colour, geometry and
	// rendering belong to the panel.
	// =================================================================
	static int StatCount() { return RSIS_COUNT; }

	static string StatLabel(int i)
	{
		switch (i)
		{
			case RSIS_Damage:      return "DAMAGE/PELLET";
			case RSIS_Accuracy:    return "ACCURACY";
			case RSIS_Velocity:    return "VELOCITY";
			case RSIS_CritChance:  return "CRIT %";
			case RSIS_CritMult:    return "CRIT MULT";
			case RSIS_Capacity:    return "CAPACITY";
			case RSIS_ReloadSpeed: return "RELOAD SPEED";
			case RSIS_Choke:       return "CHOKE";
			case RSIS_Sockets:     return "SOCKETS";
			case RSIS_RateOfFire:  return "RATE OF FIRE";
		}
		return "?";
	}

	static int StatDecimals(int i)
	{
		switch (i)
		{
			case RSIS_Accuracy:    return 1;
			case RSIS_CritChance:  return 1;
			case RSIS_CritMult:    return 2;
			case RSIS_ReloadSpeed: return 2;
			case RSIS_Choke:       return 2;
		}
		return 0;
	}

	// Does accepting this imprint actually WRITE this stat?
	//
	// Two rows are honest passengers and the card should mark them as
	// such rather than implying a change:
	//   SOCKETS      -- derived from the tier, so it moves only because
	//                   the tier moved. Shown because the player cares
	//                   about the number, not about how it is computed.
	//   RATE OF FIRE -- never written at all (see the header): it is
	//                   pinned to the fire animation's real length.
	static bool StatIsApplied(int i)
	{
		return i != RSIS_RateOfFire;
	}

	// The imprint's own rolled value for stat i.
	double Offered(int i) const
	{
		switch (i)
		{
			case RSIS_Damage:      return mDamagePerShot;
			case RSIS_Accuracy:    return mAccuracy;
			case RSIS_Velocity:    return mVelocity;
			case RSIS_CritChance:  return mCritChance * 100.0;
			case RSIS_CritMult:    return mCritMult > 0 ? mCritMult : 2.0;
			case RSIS_Capacity:    return mCapacity;
			case RSIS_ReloadSpeed: return mReloadSpeed;
			case RSIS_Choke:       return mChoke;
			case RSIS_Sockets:     return mSockets;
			case RSIS_RateOfFire:  return mRateOfFire;
		}
		return 0;
	}

	// What the target weapon has RIGHT NOW.
	static double CurrentOn(RS_Weapon w, int i)
	{
		if (!w) return 0;
		switch (i)
		{
			case RSIS_Damage:      return w.DamagePerShot;
			case RSIS_Accuracy:    return w.Accuracy;
			case RSIS_Velocity:    return w.Velocity;
			case RSIS_CritChance:  return w.CritChance * 100.0;
			// A weapon that never rolled CritMult reads 0, and dispatch
			// falls back to 2.0. Showing the raw 0 would read as "no crit
			// damage", which is the opposite of true -- the same
			// correction RS_DropTriptych already makes on its own rows.
			case RSIS_CritMult:    return w.CritMult > 0 ? w.CritMult : 2.0;
			case RSIS_Capacity:    return w.Capacity;
			case RSIS_ReloadSpeed: return w.ReloadSpeed;
			case RSIS_Choke:       return w.Choke;
			case RSIS_Sockets:     return w.GunBonaiSockets;
			case RSIS_RateOfFire:  return w.RateOfFire;
		}
		return 0;
	}

	// What stat i BECOMES if this imprint is accepted onto w. This is the
	// authority for the card's right-hand column, and it is derived from
	// the same predicate ApplyTo uses, so the preview and the result
	// cannot disagree -- which is the failure mode this project keeps
	// paying for ("agrees with itself" is not "correct").
	double ResultOn(RS_Weapon w, int i) const
	{
		if (!w) return Offered(i);

		double cur = CurrentOn(w, i);
		double off = Offered(i);

		if (!StatIsApplied(i)) return cur;

		// Sockets follow the tier, which is itself keep-better in mode 0.
		if (i == RSIS_Sockets)
			return RS_Roll.SocketsForTier(ResultTier(w));

		if (!KeepBetter()) return off;
		return off > cur ? off : cur;
	}

	// The tier the weapon ends up at. Keep-better raises, never lowers --
	// which also means an imprint can never trigger the Prototype->Basic
	// PROMOTION sacrifice by accident. That distinction is load-bearing:
	// RS_Weapon.ApplyUpgradeCard treats "Basic card onto a Prototype gun"
	// as a promotion, and a Basic imprint landing on a Prototype weapon
	// must NOT cut every stat by 20% and hand out a pellet. Promotion is
	// something the player chooses, not something a loot drop does to
	// them. Nothing here calls ApplyUpgradeCard.
	int ResultTier(RS_Weapon w) const
	{
		if (!w) return mTier;
		if (!KeepBetter()) return mTier;
		return int(mTier) > int(w.Tier) ? int(mTier) : int(w.Tier);
	}

	// -1 down, 0 unchanged, +1 up. In keep-better mode -1 is impossible
	// by construction, which is worth the panel knowing: the card can
	// state "never worse" as a fact rather than as a promise.
	int DirectionOn(RS_Weapon w, int i) const
	{
		if (!w) return 0;
		double cur = CurrentOn(w, i);
		double res = ResultOn(w, i);
		if (res > cur) return 1;
		if (res < cur) return -1;
		return 0;
	}

	// How many stats this package would actually move on w. The panel can
	// lead with it ("RAISES 4 OF 9"); it is also the honest answer to
	// "is this Trash imprint worth walking over to?", which under
	// keep-better is very often no.
	int UpCount(RS_Weapon w) const
	{
		int n = 0;
		for (int i = 0; i < RSIS_COUNT; i++)
			if (DirectionOn(w, i) > 0) n++;
		return n;
	}

	int DownCount(RS_Weapon w) const
	{
		int n = 0;
		for (int i = 0; i < RSIS_COUNT; i++)
			if (DirectionOn(w, i) < 0) n++;
		return n;
	}

	// The imprint's own name. THE TIER IS THE NAME -- an imprint has no
	// identity of its own the way a class weapon does, so "PROTOTYPE
	// IMPRINT" is the whole of it, with the family it rolled from as the
	// subtitle.
	string DisplayName() const
	{
		return RS_UIStyle.TierName(mTier) .. " IMPRINT";
	}

	string FamilyLine() const
	{
		return "rolled from " .. FamilyName(mFamily);
	}

	static string FamilyName(EVR_Family f)
	{
		switch (f)
		{
			case EVR_Family_Pistol:        return "pistol";
			case EVR_Family_Revolver:      return "revolver";
			case EVR_Family_Rifle:         return "rifle";
			case EVR_Family_SMG:           return "SMG";
			case EVR_Family_Shotgun:       return "shotgun";
			case EVR_Family_SuperShotgun:  return "super shotgun";
			case EVR_Family_Chaingun:      return "chaingun";
			case EVR_Family_Melee:         return "melee";
			case EVR_Family_Launcher:      return "launcher";
			case EVR_Family_Energy:        return "energy";
			case EVR_Family_BFG:           return "BFG";
			case EVR_Family_Railgun:       return "railgun";
			case EVR_Family_Flamethrower:  return "flamethrower";
		}
		return "unmarked";
	}

	// =================================================================
	// THE GATE
	//
	// RS_Weapon.CanAcceptImprint has been sitting unfed since it was
	// written. This is its caller. `reason` is filled on refusal so the
	// panel can print the same sentence the console does, rather than
	// inventing a second wording that drifts.
	// =================================================================
	bool CanApplyTo(RS_Weapon w, out string reason)
	{
		reason = "";

		if (mSpent)
		{
			reason = "This imprint has already been used.";
			return false;
		}
		if (!w)
		{
			reason = "Nothing to imprint.";
			return false;
		}
		// A fist is not a chassis. IsRealFist, NOT `is "VR_Fist"` --
		// VR_Fist2 is the empty-slot filler every class grants at spawn
		// and descends from VR_Fist, so a bare `is` check refuses exactly
		// the case that is fine. Third site of that same trap in this
		// codebase; see RS_DropTriptych.IsRealFist for the other two.
		if (RS_DropTriptych.IsRealFist(w))
		{
			reason = "A fist takes no imprint.";
			return false;
		}
		if (w.IsHandFiller())
		{
			reason = "That hand is empty.";
			return false;
		}

		// THE CURSE GATE (owner ruling 2026-08-07). A cursed weapon
		// refuses an imprint ABOVE its current tier until a curse is
		// lifted -- which is also what lifting one pays for. Same tier or
		// lower still lands, so curses stall progress and never trap it.
		if (!w.CanAcceptImprint(mTier))
		{
			reason = "The curse refuses it -- lift a curse first.";
			return false;
		}

		return true;
	}

	// =================================================================
	// APPLY.
	//
	// Field-by-field and deliberately NOT through RollStats(), which is
	// a destructive whole-weapon re-roll: it would clear every Locked*
	// curse flag, reset PelletCount to the weapon's authored value
	// (erasing every Promotion the player has paid for), re-roll
	// Condition on an unrolled weapon, and overwrite the attack identity.
	// See this file's header for the full list and why each one belongs
	// to somebody else.
	// =================================================================
	bool ApplyTo(RS_Weapon w)
	{
		string reason;
		if (!CanApplyTo(w, reason))
			return false;

		bool keep = KeepBetter();
		int oldDamage = w.DamagePerShot;

		if (keep)
		{
			if (mDamagePerShot > w.DamagePerShot) w.DamagePerShot = mDamagePerShot;
			if (mAccuracy      > w.Accuracy)      w.Accuracy      = mAccuracy;
			if (mVelocity      > w.Velocity)      w.Velocity      = mVelocity;
			if (mCritChance    > w.CritChance)    w.CritChance    = mCritChance;
			if (mCritMult      > w.CritMult)      w.CritMult      = mCritMult;
			if (mCapacity      > w.Capacity)      w.Capacity      = mCapacity;
			if (mReloadSpeed   > w.ReloadSpeed)   w.ReloadSpeed   = mReloadSpeed;
			if (mChoke         > w.Choke)         w.Choke         = mChoke;
		}
		else
		{
			// STRAIGHT RE-ROLL. Every stat takes the package's value, up
			// or down. This is the riskier version, off by default.
			w.DamagePerShot = mDamagePerShot;
			w.Accuracy      = mAccuracy;
			w.Velocity      = mVelocity;
			w.CritChance    = mCritChance;
			w.CritMult      = mCritMult;
			w.Capacity      = mCapacity;
			w.ReloadSpeed   = mReloadSpeed;
			w.Choke         = mChoke;
		}

		// TIER, then sockets from it. RS_Roll.SocketsForTier is the single
		// source of truth for the socket table -- read fresh rather than
		// hardcoded, so a future table change cannot drift, which is the
		// same argument Promote() makes for itself.
		int newTier = ResultTier(w);
		w.Tier = newTier;
		w.GunBonaiSockets = RS_Roll.SocketsForTier(w.Tier);

		// RE-ANCHOR THE CEILING ON THE NUMBER THE PLAYER CAN NOW SEE, and
		// only if the damage actually moved. See the header: the baseline
		// is a capture-ONCE field, PostBeginPlay already spent that
		// capture on a throwaway Basic roll, and GetDamageCeiling() is
		// baseline * 1.8. Leaving it stale silently switches off the
		// GunBonsai damage card and pins the state-ladder tracer to Peak.
		//
		// The guard is not cosmetic: on a PROMOTED weapon the baseline is
		// the promotion cut point, and re-anchoring it after an imprint
		// that changed nothing would hand out free ceiling.
		if (w.DamagePerShot != oldDamage)
		{
			w.ResetDamageBaseline();
			w.CaptureInitialDamageBaseline();
		}

		mSpent = true;
		return true;
	}

	// =================================================================
	// THE DROP ITSELF.
	//
	// It rides on RS_WeaponDrop rather than on a new pedestal class, and
	// that is a deliberate reuse rather than laziness:
	//
	//   * the payload weapon IS the roll. Spawning a real instance and
	//     calling its own RollStats is how this gets each weapon's
	//     hand-written per-tier bands without a second copy of them.
	//   * RS_ClassGating already exempts that payload BY ITS STATE
	//     (bSpecial false + bNoInteraction true, set before the deferred
	//     WorldThingSpawned can fire), so a random-family donor the
	//     player's class would normally have destroyed survives with no
	//     new exemption and no flag to keep in sync.
	//   * the offer card already reads mPayload, so an imprint has a
	//     working comparison card from the first boot.
	//
	// *** HANDOFF, STATED RATHER THAN LEFT TO BE DISCOVERED ***
	// An imprint drop therefore currently LOOKS like a class-weapon drop:
	// same pedestal, same tinted pickup sprite, same beam. The floor
	// visuals are another lane's and are not touched here. `IsImprint()`
	// on RS_WeaponDrop is the branch that lane needs, and
	// RS_ElitePackage (zscript/systems/ui/RS_ElitePackage.zs) is the
	// black EPKG body already built for exactly this and still unused by
	// anything.
	// =================================================================
	static RS_WeaponDrop Drop(Vector3 where, string mainhand, int forceTier = -1)
	{
		if (!Enabled()) return null;

		int tier = (forceTier >= VRT_Trash && forceTier <= VRT_Prototype)
			? forceTier : RollTier();

		class<Weapon> donor = RollDonorClass(mainhand);
		if (!donor) return null;

		// Identity first, so the pedestal's marker is the right SHAPE the
		// moment it is raised; numbers a line later, off the donor the
		// pedestal itself rolls. See Blank/FillFrom above for why this
		// cannot be one call.
		let ip = RS_Imprint.Blank(tier);

		let d = RS_WeaponDrop.Create(where, donor, tier, ip);
		if (!d) return null;

		let rsw = RS_Weapon(d.mPayload);
		if (!rsw)
		{
			// A donor that is not an RS_Weapon has no rolled stats to
			// read, so there is no package to offer. Take the pedestal
			// back down rather than leaving a beam standing over an offer
			// that can never be accepted.
			d.Destroy();
			return null;
		}

		ip.FillFrom(rsw);
		return d;
	}
}
