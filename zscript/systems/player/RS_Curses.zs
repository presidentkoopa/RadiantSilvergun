// =====================================================================
// RS_Curses -- the PLAYER half of the curse system, and the Divine
// ledger that both halves report into.
//
// ---------------------------------------------------------------------
// TWO POOLS, AND WHY THEY ARE NOT ONE
//
// WEAPON CURSES are the five stat-locks. They live on RS_Weapon, come
// from a Cursed-tier find or from Promotion, and are handled entirely in
// RS_Weapon.zs. Nothing in this file rolls one.
//
// PLAYER CURSES are the eight flaws below. They live HERE, on the
// player, and come from exactly one place: the instant a life-save
// spends your LAST life (RS_ScoreRevival.zs -> RS_LifeForce.AbsorbDamage).
//
// The origin is the whole point. Reading a weapon's curses tells you it
// was promoted hard. Reading your own tells you how many times the run
// nearly ended. Merging the pools would throw that away and gain
// nothing -- they already share every downstream mechanic that matters
// (the cure, the price, the Divine count).
//
// ---------------------------------------------------------------------
// HAND SCOPING -- 8 FLAWS x 2 HANDS = 16 INDEPENDENT CURSES
//
// Owner ruling 2026-08-07: "offhand-jam-prone is diff than
// mainhand-jam-prone". They are separate entries with separate costs and
// separate histories; curing one does nothing to the other.
//
// A player curse rides the SLOT, not the weapon. Swap guns and the
// mainhand curse stays on the mainhand. That is what makes these
// meaningfully different from a stat-lock, which dies with its weapon.
//
// BLIND IS THE ONE THAT USES THE HAND FOR MORE THAN BOOKKEEPING, and it
// is the owner's own design (2026-08-07):
//
//     mainhand-blind  hides monster health bars
//     offhand-blind   hides bit drops -- they are there, you cannot see them
//
// So the hand is not a label on blind, it selects which sense you lose.
//
// ---------------------------------------------------------------------
// WHY AN INVENTORY ITEM AND NOT A HANDLER FIELD
//
// The ledger has to survive a level change, ride with the player, and be
// reachable from a weapon's fire path, from the damage hook, and from
// the HUD. An Inventory item on the player is the one container in this
// engine that does all four without a lookup. RS_LifeInfo next door
// solves the same problem the other way (handler-owned, rebuilt per
// level via InitPlayer) and pays for it with ~80 lines of carry-over
// bookkeeping; there is no reason to repeat that here.
//
// ---------------------------------------------------------------------
// SILENT-PARTNER WAS CUT, 2026-08-07, at the owner's word: "remove it".
// The keyword doc's Group F roster lists nine; ours is eight. The ninth
// ("offhand cannot fire while this is equipped") had no reading that was
// both faithful to the name and sane in a dual-wield VR game -- every
// version was either a sixth stat-lock in disguise or a dead hand.
// =====================================================================

class RS_Curse
{
	// --- the eight flaws ---------------------------------------------
	// Plain consts, not a static const array: this engine build does not
	// reliably resolve `static const TYPE name[] = {...}` (see CLAUDE.md,
	// found and fixed three separate times in unrelated files).
	const FLAW_BITREPEL  = 0;
	const FLAW_GOLDDRAIN = 1;
	const FLAW_JAMPRONE  = 2;
	const FLAW_LOUD      = 3;
	const FLAW_FRAGILE   = 4;
	const FLAW_HEAVY     = 5;
	const FLAW_BLIND     = 6;
	const FLAW_HUNGRY    = 7;
	const FLAW_COUNT     = 8;

	// --- the two hands -----------------------------------------------
	const HAND_MAIN = 0;
	const HAND_OFF  = 1;
	const HAND_COUNT = 2;

	// Index into the flat 16-slot ledger.
	static int SlotOf(int flaw, int hand)
	{
		return hand * FLAW_COUNT + flaw;
	}

	static int FlawOfSlot(int slot)  { return slot % FLAW_COUNT; }
	static int HandOfSlot(int slot)  { return slot / FLAW_COUNT; }
	const SLOT_COUNT = FLAW_COUNT * HAND_COUNT;

	// --- cvar helpers -------------------------------------------------
	static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	// --- naming -------------------------------------------------------
	static string FlawName(int flaw)
	{
		switch (flaw)
		{
			case FLAW_BITREPEL:  return "bit-repellent";
			case FLAW_GOLDDRAIN: return "gold-drain";
			case FLAW_JAMPRONE:  return "jam-prone";
			case FLAW_LOUD:      return "loud";
			case FLAW_FRAGILE:   return "fragile";
			case FLAW_HEAVY:     return "heavy";
			case FLAW_BLIND:     return "blind";
			case FLAW_HUNGRY:    return "hungry";
		}
		return "unknown";
	}

	static string HandName(int hand)
	{
		return hand == HAND_OFF ? "offhand" : "mainhand";
	}

	// The player-facing identity of one curse. This is the string the
	// spend menu lists and the one the owner named the scheme after:
	// "mainhand - jam prone".
	static string SlotName(int slot)
	{
		return HandName(HandOfSlot(slot)) .. "-" .. FlawName(FlawOfSlot(slot));
	}

	// What one line of flavour text says this costs you.
	static string FlawBlurb(int flaw, int hand)
	{
		switch (flaw)
		{
			case FLAW_BITREPEL:  return "bits are pushed away from you";
			case FLAW_GOLDDRAIN: return "kills with this hand yield no Gold";
			case FLAW_JAMPRONE:  return "this hand jams even in good repair";
			case FLAW_LOUD:      return "each shot leaves your ears ringing";
			case FLAW_FRAGILE:   return "this hand's weapon wears out twice as fast";
			case FLAW_HEAVY:     return "this hand's weapon slows you down";
			case FLAW_BLIND:
				return hand == HAND_OFF ? "you cannot see bit drops"
				                        : "you cannot see monster health";
			case FLAW_HUNGRY:    return "this hand eats twice the ammo";
		}
		return "";
	}

	// --- per-flaw enable gate ----------------------------------------
	static bool FlawEnabled(int flaw)
	{
		switch (flaw)
		{
			case FLAW_BITREPEL:  return CVBool("rs_curse_flaw_bitrepel", true);
			case FLAW_GOLDDRAIN: return CVBool("rs_curse_flaw_golddrain", true);
			case FLAW_JAMPRONE:  return CVBool("rs_curse_flaw_jamprone", true);
			case FLAW_LOUD:      return CVBool("rs_curse_flaw_loud", true);
			case FLAW_FRAGILE:   return CVBool("rs_curse_flaw_fragile", true);
			case FLAW_HEAVY:     return CVBool("rs_curse_flaw_heavy", true);
			case FLAW_BLIND:     return CVBool("rs_curse_flaw_blind", true);
			case FLAW_HUNGRY:    return CVBool("rs_curse_flaw_hungry", true);
		}
		return false;
	}

	// --- the price ----------------------------------------------------
	// Scaled by how much the flaw actually hurts, not alphabetically. A
	// hand that jams is felt every trigger pull; a hand that weighs you
	// down is an inconvenience.
	static int FlawCost(int flaw)
	{
		switch (flaw)
		{
			case FLAW_JAMPRONE:  return CVInt("rs_curse_cost_jamprone", 40);
			case FLAW_HUNGRY:    return CVInt("rs_curse_cost_hungry", 30);
			case FLAW_BLIND:     return CVInt("rs_curse_cost_blind", 30);
			case FLAW_FRAGILE:   return CVInt("rs_curse_cost_fragile", 25);
			case FLAW_LOUD:      return CVInt("rs_curse_cost_loud", 25);
			case FLAW_GOLDDRAIN: return CVInt("rs_curse_cost_golddrain", 20);
			case FLAW_BITREPEL:  return CVInt("rs_curse_cost_bitrepel", 20);
			case FLAW_HEAVY:     return CVInt("rs_curse_cost_heavy", 15);
		}
		return 20;
	}

	// The five stat-lock prices, by the same principle. Lives here rather
	// than in RS_Weapon so the whole price list is one screen -- the spend
	// menu shows both pools side by side and they must stay comparable.
	static int StatCost(string statName)
	{
		if (statName == "damage")     return CVInt("rs_curse_cost_damage", 40);
		if (statName == "critchance") return CVInt("rs_curse_cost_critchance", 30);
		if (statName == "accuracy")   return CVInt("rs_curse_cost_accuracy", 25);
		if (statName == "velocity")   return CVInt("rs_curse_cost_velocity", 20);
		if (statName == "capacity")   return CVInt("rs_curse_cost_capacity", 15);
		return 25;
	}
}


// =====================================================================
// THE LEDGER. One per player, for the life of the run.
//
// Holds: which of the 16 player-curse slots are active, how many of each
// kind have been CURED (the permanent lift bonuses), and the run-wide
// Divine count that both pools feed.
// =====================================================================
class RS_CurseLedger : Inventory
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		+INVENTORY.IGNORESKILL
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNDROPPABLE
		+INVENTORY.QUIET
	}

	// Active player curses. One entry per slot; 0 = clean.
	// A flaw is a TOGGLE, not a stack -- you either have mainhand-loud or
	// you do not. (Stat-locks DO stack; that is the other pool's rule and
	// it lives on the weapon.)
	Array<int> mActive;

	// How many times each slot has been cured. Drives the permanent
	// inverse-bonus, which is why it is kept after the curse is gone.
	Array<int> mCured;

	// Divine: total cures across BOTH pools, run-wide.
	// Owner ruling 2026-08-07: "all cured curses (player or weapon) move
	// the player themselves closer to divine status (need 10 cured
	// curses) upon which curses no longer apply".
	int mTotalCured;
	bool mDivine;

	// Deafness timer for `loud` -- set on each shot from a cursed hand,
	// counted down in DoEffect.
	int mDeafTics;

	// WHICH HAND FIRED MOST RECENTLY. Stamped by RS_Weapon's fire
	// dispatch (the one place that knows, for every fire Mode, on both
	// hands) and read by the death hook to decide where a player curse
	// lands: "whatever gun you fired last" -- owner, 2026-08-07.
	//
	// Defaults to mainhand so a player who dies without having fired a
	// shot still gets a valid target rather than an unhandled case.
	int mLastFiredHand;

	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		EnsureSized();
	}

	void EnsureSized()
	{
		while (mActive.Size() < RS_Curse.SLOT_COUNT) mActive.Push(0);
		while (mCured.Size()  < RS_Curse.SLOT_COUNT) mCured.Push(0);
	}

	// -----------------------------------------------------------------
	// Lookup. The one entry point everything else uses -- a null return
	// means "no ledger", which every caller must treat as "no curses"
	// rather than as an error. A player mid-spawn legitimately has none.
	// -----------------------------------------------------------------
	static RS_CurseLedger Fetch(Actor mo)
	{
		if (!mo) return null;
		return RS_CurseLedger(mo.FindInventory("RS_CurseLedger"));
	}

	// Convenience: is this flaw live on this hand, for this actor?
	// Static so a fire path can ask in one line without null-dancing.
	static bool Has(Actor mo, int flaw, int hand)
	{
		let led = Fetch(mo);
		return led && led.IsActive(RS_Curse.SlotOf(flaw, hand));
	}

	bool IsActive(int slot) const
	{
		if (slot < 0 || slot >= mActive.Size()) return false;
		return mActive[slot] != 0;
	}

	int CuredCount(int slot) const
	{
		if (slot < 0 || slot >= mCured.Size()) return 0;
		return mCured[slot];
	}

	int ActiveCount() const
	{
		int n = 0;
		for (int i = 0; i < mActive.Size(); i++)
			if (mActive[i] != 0) n++;
		return n;
	}

	// -----------------------------------------------------------------
	// THE PERMANENT LIFT BONUS.
	//
	// A player curse is not pinned to a weapon, so lifting one cannot
	// tier anything up the way a stat-lock does. It pays the INVERSE of
	// the flaw instead, permanently, on the same hand -- the curse showed
	// you what the hand lacked and clearing it leaves the fix behind.
	//
	// Multiplicative in the count so curing the same slot twice across a
	// long run keeps paying, without a second bookkeeping field.
	// -----------------------------------------------------------------
	double LiftBonus(int flaw, int hand) const
	{
		int n = CuredCount(RS_Curse.SlotOf(flaw, hand));
		if (n <= 0) return 0.0;
		return n * RS_Curse.CVInt("rs_curse_playerlift_bonus", 10) / 100.0;
	}

	// Same, as a static one-liner for the fire paths.
	static double BonusFor(Actor mo, int flaw, int hand)
	{
		let led = Fetch(mo);
		return led ? led.LiftBonus(flaw, hand) : 0.0;
	}

	// -----------------------------------------------------------------
	// WHERE EACH LIFT REWARD IS PAID, so the set can be audited without
	// grepping six files:
	//
	//   bit-repellent  RS_Curses.PushBits       -- sign flips, bits drift IN
	//   gold-drain     RS_Bits.GoldDoubled      -- chance of a second gold bit
	//   jam-prone      RS_Weapon.A_RS_FireSlot  -- backfire chance scaled down
	//   fragile        RS_Weapon.OnPlayerDamaged-- Condition loss scaled down
	//   heavy          RS_Curses.ApplyWeight    -- movement above stock
	//   hungry         RS_Weapon.A_RS_FireSlot  -- chance of a free shot
	//
	// LOUD AND BLIND PAY NOTHING YET, and that is a gap rather than a
	// decision. Their flaws remove information (hearing, health bars, bit
	// visibility) and there is no "more than normal" on those axes to
	// hand back -- you either can see a health bar or you cannot. Giving
	// them a bonus on some unrelated axis would break the one rule the
	// other six follow, which is that a lift returns the INVERSE of what
	// the curse took. Left honest and open rather than filled with
	// something arbitrary; the owner decides what, if anything, those two
	// should pay.
	// -----------------------------------------------------------------

	// -----------------------------------------------------------------
	// APPLYING A CURSE. Returns the slot it landed on, or -1.
	//
	// Refuses when: the system is off, the player is Divine, the flaw is
	// disabled in options, or that exact slot is already cursed. The
	// caller re-rolls on -1 rather than this function looping, so a
	// fully-cursed player cannot spin forever.
	// -----------------------------------------------------------------
	int ApplyCurse(int flaw, int hand)
	{
		EnsureSized();

		if (mDivine) return -1;
		if (!RS_Curse.CVBool("rs_curse_enable", true)) return -1;
		if (!RS_Curse.FlawEnabled(flaw)) return -1;

		int slot = RS_Curse.SlotOf(flaw, hand);
		if (slot < 0 || slot >= mActive.Size()) return -1;
		if (mActive[slot] != 0) return -1;

		mActive[slot] = 1;
		return slot;
	}

	// Roll a random ELIGIBLE curse onto one hand. Returns the slot or -1.
	//
	// Builds the candidate list first rather than rolling-and-retrying:
	// with 8 flaws and per-flaw option switches, a player who has turned
	// six off and carries the other two would make blind retries spin for
	// a long time before failing. Enumerating is bounded and honest.
	int RollCurse(int hand)
	{
		EnsureSized();

		if (mDivine) return -1;
		if (!RS_Curse.CVBool("rs_curse_enable", true)) return -1;

		Array<int> candidates;
		for (int f = 0; f < RS_Curse.FLAW_COUNT; f++)
		{
			if (!RS_Curse.FlawEnabled(f)) continue;
			if (IsActive(RS_Curse.SlotOf(f, hand))) continue;
			candidates.Push(f);
		}

		if (candidates.Size() == 0) return -1;
		return ApplyCurse(candidates[random(0, candidates.Size() - 1)], hand);
	}

	// -----------------------------------------------------------------
	// LIFTING. The cure path -- charges Curse Bits, clears the slot,
	// banks the permanent bonus, and reports into Divine.
	//
	// Payment happens FIRST and is checked before anything mutates, so a
	// failed lift leaves no half-state.
	// -----------------------------------------------------------------
	bool LiftCurse(int slot)
	{
		EnsureSized();

		if (!owner || !IsActive(slot)) return false;

		int cost = RS_Curse.FlawCost(RS_Curse.FlawOfSlot(slot));
		if (owner.CountInv("RS_Bit_Curse") < cost) return false;

		owner.TakeInventory("RS_Bit_Curse", cost);

		mActive[slot] = 0;
		mCured[slot]++;

		if (owner)
			owner.A_StartSound("rs_bit_repair", CHAN_AUTO, CHANF_DEFAULT, 0.9);

		Console.Printf("\c[Gold]Curse lifted:\c- %s", RS_Curse.SlotName(slot));

		CountCure();
		return true;
	}

	// -----------------------------------------------------------------
	// DIVINE. Called by BOTH pools -- this one from LiftCurse above, and
	// from RS_Weapon.UnlockStat when a stat-lock is cleared.
	//
	// One counter, deliberately: the owner's ruling is that the PLAYER
	// becomes Divine, not a weapon, and that every cure of either kind
	// moves them toward it. An earlier design gave each weapon its own
	// Divinity track and he cut it ("fuck weapon divinity").
	// -----------------------------------------------------------------
	void CountCure()
	{
		mTotalCured++;

		int need = max(1, RS_Curse.CVInt("rs_curse_divine_threshold", 10));
		if (mDivine || mTotalCured < need)
			return;

		mDivine = true;

		if (RS_Curse.CVBool("rs_curse_divine_announce", true) && owner)
		{
			Console.Printf("\c[Gold]------------------------------------------\c-");
			Console.Printf("\c[Gold]  DIVINE.\c- %d curses broken. No curse takes hold again.", mTotalCured);
			Console.Printf("\c[Gold]------------------------------------------\c-");
			owner.A_StartSound("misc/i_pkup", CHAN_AUTO, CHANF_DEFAULT, 1.0, ATTN_NONE);
		}
	}

	// Divine blocks BOTH pools. RS_Weapon asks this before rolling a
	// stat-lock, and RollCurse checks it above.
	static bool IsDivine(Actor mo)
	{
		let led = Fetch(mo);
		return led && led.mDivine;
	}

	// -----------------------------------------------------------------
	// LOUD. Deafness after a shot from a cursed hand.
	//
	// Owner ruling 2026-08-07: "loud drops the player's hearing for two
	// tics after each shot. music is unaffected."
	//
	// Implemented on the sound VOLUME of the player's own listener rather
	// than by muting channels: snd_sfxvolume is a global the player owns
	// and writing it would persist past the run. `SetSoundVolume` here
	// scales the actor's own emission, so music (which is not an actor
	// channel at all) is untouched by construction.
	// -----------------------------------------------------------------
	// =================================================================
	// LOUD -- the tinnitus ring.
	//
	// Owner design, 2026-08-07: "find a tinnitus effect, and layer it
	// with the weapon firing sound, ramp up its volume (not to exceed
	// room master)" and "have it last x tics, and each shot successively
	// adds to that tic some, so firing once has it last x tics, if you
	// fire before it finishes fading it adds x / 2 tics".
	//
	// SO IT MASKS RATHER THAN DUCKS. That is not a compromise, it is how
	// this is actually done -- and it is the only route available, since
	// ZScript has no listener volume to turn down. A loud enough ring
	// drowns the room the same way it does in life, and nothing else in
	// the mix has to be touched.
	//
	// "NOT TO EXCEED ROOM MASTER" IS FREE. Every sound GZDoom plays is
	// already scaled by snd_sfxvolume, so a normally-played ring cannot
	// be louder than the player's own setting. No clamp needed, and
	// nothing here writes a global the player owns.
	//
	// MUSIC IS UNTOUCHED, by construction -- this adds an actor sound and
	// changes nothing else, and music is not an actor channel.
	// =================================================================

	// A channel of its own, so the ring is never cut by a gunshot or a
	// pickup landing on the same slot.
	const RING_CHANNEL = CHAN_7;

	void Deafen()
	{
		int base = max(1, RS_Curse.CVInt("rs_curse_loud_tics", 70));
		bool fresh = (mDeafTics <= 0);

		// FIRST shot pays full duration; a shot fired while it is still
		// ringing adds HALF. So sustained fire stacks toward the ceiling
		// without one trigger-happy second pinning it there forever.
		mDeafTics += fresh ? base : max(1, base / 2);

		// Ceiling, so it cannot be ratcheted into a permanent state.
		int cap = base * max(1, RS_Curse.CVInt("rs_curse_loud_maxstack", 4));
		mDeafTics = min(mDeafTics, cap);

		if (!owner) return;

		// Only (re)start the sound when it is not already ringing --
		// retriggering it every shot would restart the 8ms attack and
		// machine-gun the transient. An ongoing ring just gets longer
		// and louder.
		if (fresh)
			owner.A_StartSound("rs_curse/tinnitus", RING_CHANNEL,
				CHANF_OVERLAP, RingVolume());
		else
			owner.A_SoundVolume(RING_CHANNEL, RingVolume());
	}

	// Volume climbs with how long the ring has left to run, so a single
	// shot is a chirp and sustained fire is genuinely bad. Capped well
	// under 1.0 -- the master volume is the player's, and a curse should
	// not be the loudest thing they ever hear.
	double RingVolume() const
	{
		int base = max(1, RS_Curse.CVInt("rs_curse_loud_tics", 70));
		double stacked = double(mDeafTics) / double(base);   // 1.0 .. cap
		double vmax = clamp(RS_Curse.CVInt("rs_curse_loud_volume", 70), 0, 100) / 100.0;
		return clamp(0.35 + stacked * 0.25, 0.0, vmax);
	}

	bool IsDeafened() const
	{
		return mDeafTics > 0;
	}

	// Ring over. Stop the loop rather than letting the 4s asset run on
	// past the timer -- the tic counter is the authority on how long this
	// lasts, not the length of the file.
	void Rehear()
	{
		if (owner)
			owner.A_StopSound(RING_CHANNEL);
	}

	// -----------------------------------------------------------------
	// Per-tic work: the deafness countdown, and bit-repellent's push.
	// -----------------------------------------------------------------
	override void DoEffect()
	{
		Super.DoEffect();
		if (!owner) return;

		if (mDeafTics > 0)
		{
			mDeafTics--;

			// Fade the last half-second out under script control, so the
			// ring ends on the TIMER rather than wherever the asset's own
			// tail happens to be when we cut it.
			if (mDeafTics > 0 && mDeafTics < 18 && owner)
				owner.A_SoundVolume(RING_CHANNEL,
					RingVolume() * (mDeafTics / 18.0));

			if (mDeafTics <= 0)
				Rehear();
		}

		PushBits();
		ApplyWeight();
	}

	// -----------------------------------------------------------------
	// HEAVY -- the cursed hand's weapon slows you down. Both hands
	// cursed stacks to double the penalty.
	//
	// Written every tic rather than once on application because Speed is
	// a shared field: powerups, other mods and the player's own class all
	// write it, so a one-shot multiply would be silently overwritten and
	// a one-shot restore would clobber whatever set it last. Recomputing
	// from the class default each tic is the only version that cannot
	// drift or leak.
	// -----------------------------------------------------------------
	void ApplyWeight()
	{
		if (!owner) return;

		int stacks = 0;
		if (IsActive(RS_Curse.SlotOf(RS_Curse.FLAW_HEAVY, RS_Curse.HAND_MAIN))) stacks++;
		if (IsActive(RS_Curse.SlotOf(RS_Curse.FLAW_HEAVY, RS_Curse.HAND_OFF)))  stacks++;

		let def = GetDefaultByType(owner.GetClass());
		if (!def) return;

		// LIFT REWARD, `heavy` cured: you carry it better than you did
		// before you were ever cursed. Both hands' cures add.
		double cured = LiftBonus(RS_Curse.FLAW_HEAVY, RS_Curse.HAND_MAIN)
		             + LiftBonus(RS_Curse.FLAW_HEAVY, RS_Curse.HAND_OFF);

		if (stacks == 0 && cured <= 0)
		{
			// Restore only if WE are the ones holding it, so this never
			// fights a speed powerup.
			if (mWeightApplied)
			{
				owner.Speed = def.Speed;
				mWeightApplied = false;
			}
			return;
		}

		double pct = clamp(RS_Curse.CVInt("rs_curse_heavy_slow", 15) * stacks, 0, 90);
		owner.Speed = def.Speed * (1.0 - pct / 100.0) * (1.0 + cured);
		mWeightApplied = true;
	}

	bool mWeightApplied;

	// -----------------------------------------------------------------
	// BLIND -- the two halves. Owner ruling 2026-08-07:
	//
	//   "main hand blind hides monster hp bars, offhand blind hides bit
	//    drops - they're there but you cnt see them"
	//
	// So the hand is not a label on this one, it SELECTS WHICH SENSE YOU
	// LOSE. That makes blind the only flaw where the two hand-scoped
	// copies do genuinely different things, and it is why the roster
	// keeps hand scoping rather than collapsing to eight global flaws.
	//
	// Both are asked for BY the thing that draws, rather than pushed by
	// this file: the bars test HealthBarsHidden() next to their own
	// master switch, and each bit tests BitsHidden() in its Tick. Neither
	// hides anything else about the object -- a bit you cannot see still
	// picks up, still expires, and is still swept in by the hook.
	//
	// Consoleplayer reads, single-player: this whole mod is written
	// against one local player (RS_KillRewardsHandler does the same).
	// -----------------------------------------------------------------
	static bool HealthBarsHidden()
	{
		let mo = players[consoleplayer].mo;
		if (!mo) return false;
		let led = Fetch(mo);
		return led && led.IsActive(
			RS_Curse.SlotOf(RS_Curse.FLAW_BLIND, RS_Curse.HAND_MAIN));
	}

	// Is offhand-blind live on this player? Read by the bits themselves.
	static bool BitsHidden(Actor mo)
	{
		let led = Fetch(mo);
		return led && led.IsActive(RS_Curse.SlotOf(RS_Curse.FLAW_BLIND, RS_Curse.HAND_OFF));
	}

	// -----------------------------------------------------------------
	// BIT-REPELLENT -- the one flaw that needed a mechanic built, not
	// just a number changed.
	//
	// Owner ruling 2026-08-07: "make them fuckin move, dude, they push
	// away on player, the player has a radial that pushes away bits".
	//
	// Bits are ordinarily completely inert -- static pickups you walk
	// over, with no homing and no velocity of their own. So there was no
	// existing motion to invert; this is the only thing in the mod that
	// moves a bit.
	//
	// EITHER HAND'S copy of the curse pushes, and both stack, because the
	// push is a property of the player rather than of a weapon. Radius
	// and force are cvars because "how repellent" is exactly the kind of
	// feel number that has to be tuned in play, not guessed here.
	// -----------------------------------------------------------------
	void PushBits()
	{
		int stacks = 0;
		if (IsActive(RS_Curse.SlotOf(RS_Curse.FLAW_BITREPEL, RS_Curse.HAND_MAIN))) stacks++;
		if (IsActive(RS_Curse.SlotOf(RS_Curse.FLAW_BITREPEL, RS_Curse.HAND_OFF)))  stacks++;

		// LIFT REWARD, `bit-repellent` cured: the sign flips and bits
		// drift TOWARD you. A permanent, gentle version of what the hook
		// does in one burst -- which is the cleanest possible reading of
		// "the inverse of the flaw", and the reason this curse is the one
		// worth curing first.
		double cured = LiftBonus(RS_Curse.FLAW_BITREPEL, RS_Curse.HAND_MAIN)
		             + LiftBonus(RS_Curse.FLAW_BITREPEL, RS_Curse.HAND_OFF);

		if (stacks == 0 && cured <= 0) return;

		double radius = RS_Curse.CVInt("rs_curse_bitrepel_radius", 192);
		double force  = RS_Curse.CVInt("rs_curse_bitrepel_force", 4) * 0.25 * stacks;

		// Net direction: repulsion from live curses minus attraction from
		// cured ones. A player who was cursed twice and cured both ends up
		// net-positive, which is the point.
		force -= cured * RS_Curse.CVInt("rs_curse_bitrepel_force", 4) * 0.25;

		if (radius <= 0 || force == 0) return;

		let it = BlockThingsIterator.Create(owner, radius);
		while (it.Next())
		{
			let mo = it.thing;
			if (!mo || mo == owner) continue;
			if (!RS_BitUtil.IsBit(mo)) continue;

			// THE HOOK WINS. A bit already travelling toward the player
			// is being reeled in by the grappling hook, and this curse
			// does not fight it.
			//
			// Done by reading the bit's own motion rather than by asking
			// the hook anything: the hook is a default mechanic that
			// knows nothing about curses and must stay that way. All this
			// curse needs is to RECOGNISE inbound movement and leave it
			// alone -- no shared state, no reference in either direction.
			if (IsInbound(mo))
				continue;

			Vector3 away = mo.pos - owner.pos;
			// Directly on top of us: pick an arbitrary direction rather
			// than normalising a zero vector.
			double len = away.xy.Length();
			if (len < 1.0)
			{
				double a = FRandom(0, 360);
				away = (cos(a), sin(a), 0);
				len = 1.0;
			}

			if (len > radius) continue;

			// Falls off with distance -- strongest right at your feet,
			// which is where a bit you are trying to grab actually is.
			double scale = force * (1.0 - len / radius);
			mo.vel.x += (away.x / len) * scale;
			mo.vel.y += (away.y / len) * scale;
		}
	}

	// Is this bit currently travelling TOWARD the player?
	//
	// Dot product of its velocity against the direction to the player.
	// Positive means inbound. That is all the hook detection this curse
	// needs, and it stays correct if the hook is ever retuned, replaced,
	// or if something else starts pulling bits in.
	bool IsInbound(Actor mo) const
	{
		if (!owner || !mo) return false;
		if (mo.vel.xy.Length() < 0.5) return false;   // effectively at rest

		Vector2 toPlayer = (owner.pos.xy - mo.pos.xy);
		double len = toPlayer.Length();
		if (len < 1.0) return true;
		toPlayer /= len;

		return (mo.vel.x * toPlayer.x + mo.vel.y * toPlayer.y) > 0;
	}
}


// =====================================================================
// THE HANDLER. Grants the ledger, and owns the two flaws whose effects
// cannot live anywhere else.
//
// MUST BE LISTED IN MAPINFO's AddEventHandlers. A StaticEventHandler
// does NOT self-register on this engine -- EventManager::InitStaticHandlers
// (events.cpp:590-622) builds its list from MAPINFO and nothing else.
// Believing otherwise is what left the ENTIRE lives system dead: nothing
// granted RS_LifeForce, so its damage hook was never installed, and every
// rs_lives_* cvar and menu row sat inert while looking perfectly alive.
// =====================================================================
class RS_CurseHandler : EventHandler
{
	// -----------------------------------------------------------------
	// Grant the ledger. PlayerSpawned rather than WorldLoaded so it
	// covers a player who joins or respawns mid-level, and the item's
	// own MaxAmount 1 makes the repeat grants no-ops.
	// -----------------------------------------------------------------
	override void PlayerSpawned(PlayerEvent e)
	{
		Super.PlayerSpawned(e);

		let p = players[e.PlayerNumber].mo;
		if (!p) return;

		if (!p.FindInventory("RS_CurseLedger"))
			p.GiveInventory("RS_CurseLedger", 1);
	}

	// -----------------------------------------------------------------
	// GOLD-DRAIN. Kills made with a cursed hand pay no Gold.
	//
	// Sits here rather than in RS_Bits because the bit spawner does not
	// know which hand fired -- it only sees a dead monster. The fire path
	// stamps the hand on the player (RS_Weapon's LastFiredHand), and this
	// reads it at the moment of the kill.
	//
	// Runs BEFORE RS_KillRewardsHandler in handler order only by
	// coincidence of registration, which is why it does not try to
	// suppress the drop directly -- it sets a flag the bit spawner reads.
	// See RS_Bits.zs's gold branch.
	// -----------------------------------------------------------------
	override void WorldThingDied(WorldEvent e)
	{
		Super.WorldThingDied(e);
		// Nothing to do here today -- gold suppression is read directly
		// off the ledger inside RS_Bits.zs at the moment it decides to
		// spawn a Gold Bit. Kept as an explicit no-op rather than an
		// absent override so the next reader does not go looking for the
		// hook that "must" be here.
	}

	// -----------------------------------------------------------------
	// Console access, for testing and for the eventual spend UI.
	//
	//   netevent rs_curse_list
	//   netevent rs_curse_give,<flaw>,<hand>
	//   netevent rs_curse_lift,<slot>
	//   netevent rs_curse_clear
	// -----------------------------------------------------------------
	// Stat index -> the name UnlockStat matches on. Kept in one place so
	// the console command and any future UI cannot drift apart.
	static string StatNameOf(int i)
	{
		switch (i)
		{
			case 0: return "damage";
			case 1: return "accuracy";
			case 2: return "velocity";
			case 3: return "critchance";
			case 4: return "capacity";
		}
		return "";
	}

	// One weapon's stat-locks, with stack depth so a doubly-cursed stat
	// is visibly different from a singly-cursed one -- that depth is what
	// the escalating lift bonus is paid against.
	static int ListWeapon(Actor mo, RS_Weapon w, string handLabel, int held)
	{
		if (!w || !w.HasAnyCurse()) return 0;

		int hand = (handLabel == "offhand") ? RS_Curse.HAND_OFF : RS_Curse.HAND_MAIN;
		int shown = 0;

		for (int i = 0; i < 5; i++)
		{
			string stat = StatNameOf(i);
			int stack = 0;
			if (stat == "damage"     && w.LockedDamage)     stack = w.CurseStackDamage;
			if (stat == "accuracy"   && w.LockedAccuracy)   stack = w.CurseStackAccuracy;
			if (stat == "velocity"   && w.LockedVelocity)   stack = w.CurseStackVelocity;
			if (stat == "critchance" && w.LockedCritChance) stack = w.CurseStackCritChance;
			if (stat == "capacity"   && w.LockedCapacity)   stack = w.CurseStackCapacity;
			if (stack <= 0) continue;

			int cost = RS_Curse.StatCost(stat);
			Console.Printf("  %s[%d,%d]\c- %s-%-12s x%d  %3d bits",
				held >= cost ? "\c[Green]" : "\c[Red]",
				hand, i, handLabel, stat, stack, cost);
			shown++;
		}
		return shown;
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		Super.NetworkProcess(e);

		if (e.Name.Left(9) != "rs_curse_") return;

		let mo = players[e.Player].mo;
		if (!mo || !mo.player) return;
		let led = RS_CurseLedger.Fetch(mo);
		if (!led) return;

		if (e.Name == "rs_curse_list")
		{
			int held = mo.CountInv("RS_Bit_Curse");

			Console.Printf("\c[Gold]=== CURSES ===\c-");
			if (led.mDivine)
				Console.Printf("\c[Gold]DIVINE.\c- %d cured. No curse takes hold again.",
					led.mTotalCured);
			else
				Console.Printf("Divine progress: %d / %d cured  --  Curse Bits held: %d",
					led.mTotalCured,
					RS_Curse.CVInt("rs_curse_divine_threshold", 10), held);

			// --- weapon stat-locks, both hands ---------------------
			Console.Printf("\c[Gold]-- Weapon curses --\c-");
			int wshown = 0;
			wshown += ListWeapon(mo, RS_Weapon(mo.player.ReadyWeapon), "mainhand", held);
			let off = RS_Weapon(mo.player.OffhandWeapon);
			if (off != RS_Weapon(mo.player.ReadyWeapon))
				wshown += ListWeapon(mo, off, "offhand", held);
			if (wshown == 0)
				Console.Printf("  (none)");

			// --- player flaws ---------------------------------------
			Console.Printf("\c[Gold]-- Player curses --\c-");
			for (int i = 0; i < RS_Curse.SLOT_COUNT; i++)
			{
				if (!led.IsActive(i)) continue;
				int cost = RS_Curse.FlawCost(RS_Curse.FlawOfSlot(i));
				Console.Printf("  %s[%2d]\c- %-26s %3d bits -- %s",
					held >= cost ? "\c[Green]" : "\c[Red]", i,
					RS_Curse.SlotName(i), cost,
					RS_Curse.FlawBlurb(RS_Curse.FlawOfSlot(i), RS_Curse.HandOfSlot(i)));
			}
			if (led.ActiveCount() == 0)
				Console.Printf("  (none)");

			Console.Printf("\c[Gold]Lift:\c- netevent rs_curse_lift,<number>   (player)");
			Console.Printf("\c[Gold]     \c- netevent rs_curse_liftstat,<0 main/1 off>,<0-4>  (weapon)");
			Console.Printf("       weapon stats: 0 damage  1 accuracy  2 velocity  3 crit  4 capacity");
		}
		else if (e.Name == "rs_curse_liftstat")
		{
			// e.Args[0] = hand (0 main / 1 off), e.Args[1] = stat index.
			let wpn = (e.Args[0] == RS_Curse.HAND_OFF)
				? RS_Weapon(mo.player.OffhandWeapon)
				: RS_Weapon(mo.player.ReadyWeapon);

			if (!wpn)
			{
				Console.Printf("No weapon in that hand.");
				return;
			}

			string stat = StatNameOf(e.Args[1]);
			if (stat == "")
			{
				Console.Printf("Stat must be 0-4.");
				return;
			}

			int cost = RS_Curse.StatCost(stat);
			if (mo.CountInv("RS_Bit_Curse") < cost)
			{
				Console.Printf("Need %d Curse Bits, have %d.",
					cost, mo.CountInv("RS_Bit_Curse"));
				return;
			}

			// Charge FIRST but only if the lift actually happens -- so a
			// stat that was never cursed cannot take the player's bits.
			if (!wpn.UnlockStat(stat))
			{
				Console.Printf("That stat is not cursed.");
				return;
			}

			mo.TakeInventory("RS_Bit_Curse", cost);

			// Same rule as the weapon sheet: the keyword only comes off
			// when the LAST stack on that stat is gone.
			if (!wpn.IsStatCursed(stat))
				wpn.UngrantKeyword("curse", stat);

			Console.Printf("\c[Gold]Curse lifted:\c- %s %s  (-%d bits)",
				e.Args[0] == RS_Curse.HAND_OFF ? "offhand" : "mainhand", stat, cost);
		}
		else if (e.Name == "rs_curse_give")
		{
			int slot = led.ApplyCurse(e.Args[0], e.Args[1]);
			if (slot >= 0)
				Console.Printf("\c[Red]Cursed:\c- %s", RS_Curse.SlotName(slot));
			else
				Console.Printf("Refused (already held, disabled, or Divine).");
		}
		else if (e.Name == "rs_curse_lift")
		{
			if (!led.LiftCurse(e.Args[0]))
				Console.Printf("Cannot lift -- not cursed, or not enough Curse Bits.");
		}
		else if (e.Name == "rs_curse_clear")
		{
			for (int i = 0; i < RS_Curse.SLOT_COUNT; i++)
				if (i < led.mActive.Size()) led.mActive[i] = 0;
			Console.Printf("All player curses cleared (no bits charged, no cures counted).");
		}
	}
}
