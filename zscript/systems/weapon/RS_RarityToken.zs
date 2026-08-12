// =====================================================================
// RS_RarityToken -- the elite payout, and the gate on the card system.
//
// ---------------------------------------------------------------------
// WHAT ONE IS
//
// A token is A WEAPON FAMILY, A TIER, AND A SET OF ROLLED STATS. Not a
// generic "+1 rung" -- an "SMG Uncommon" with real numbers already on
// it, rolled inside the SMG's own Uncommon range.
//
// Each of the player's six class weapons carries a rarity. You start at
// Basic. Kill an elite, it drops a token; spend it on the matching
// weapon and that weapon takes the token's tier and its numbers.
//
//     Basic -> Common -> Uncommon -> Advanced -> Designer -> Prototype
//
// Rarity is where sockets come from (RS_Roll.SocketsForTier), so that
// ladder IS the affix ladder:
//
//     Basic       0 sockets   NO RS affixes can be taken at all
//     Common      1
//     Uncommon    2
//     Advanced    3
//     Designer    4
//     Prototype   5
//
// Elites are therefore not a bonus alongside the card system. They are
// the way into it.
//
// ---------------------------------------------------------------------
// ADDITIVE, AND WHY NEITHER ALTERNATIVE WORKS
//
// The obvious implementation -- hand the tier to RS_Weapon.ApplyUpgradeCard
// -- is wrong, and quietly so. That path calls RollStats(newTier), and
// RollStats is a full RE-ROLL: every stat is thrown away and rolled
// fresh in the new tier's range.
//
// Walk the owner's own case. An SMG on a Basic token, levelled a few
// times, carrying an affix and several stat increases. An SMG Uncommon
// token drops. Re-rolling would delete every increase earned and
// replace it with a fresh Uncommon roll -- which can land LOWER than a
// well-levelled Basic on any given stat. The reward for killing an
// elite would sometimes be a worse gun, with nothing on screen
// explaining why.
//
// Keep-better is the other wrong answer: it silently discards the
// token's roll whenever your current number is higher, which on
// overlapping bands is most of the time.
//
// So: ADDITIVE. new = tokenRoll + (current - RollBase). You keep every
// point levelling gave you and the token supplies a fresh base under
// it. Tier and sockets are set outright, because those are the token's
// whole point. Levels and affixes are untouched -- they live in
// GunBonsai's bag, not in the weapon's stats.
//
// The earned part appears on both sides, so new - current reduces to
// tokenRoll - RollBase: a token is judged against the roll THIS GUN
// ORIGINALLY GOT, and a stat can go DOWN. Deliberate. It makes a token
// a trade rather than a guaranteed upgrade.
//
// ---------------------------------------------------------------------
// HOW IT GETS IN-RANGE NUMBERS
//
// A DONOR. Spawn a throwaway weapon of the target class, roll it at the
// target tier, copy its eight stats, destroy it. Recovered from the old
// RS_Imprint (90aaf2c6), and it is the right trick: every weapon
// already knows its own per-tier ranges through its RollStats override,
// so this reuses 46 weapons' worth of tuning instead of restating any
// of it here. A range table in this file would be a second source of
// truth and would drift the first time one weapon was retuned.
//
// ---------------------------------------------------------------------
// WHAT THIS REPLACED
//
// RS_Imprint, 784 lines, removed in 90aaf2c6 having never worked in
// play. This keeps its one good idea -- the donor -- and drops the rest: the second weighted ladder, the eight drop-weight
// sliders, the separate tier bonus, the preview screen.
//
// And on the other side: until 2026-08-11 the ONLY thing in the tree
// that could raise a tier was a side effect of lifting a curse. A clean
// weapon could never climb at all. That block is gone; this is what was
// always supposed to be there.
//
// THE LOCK RULE STILL HOLDS, and matters more now: a cursed weapon
// cannot take a token. RS_Weapon.CanAcceptImprint is the gate and it
// survived the purge intact; only its wording changed, from a curse
// that "refuses" to a count of locked stats, because a number the
// player can act on beats a personality they cannot. Lifting a lock no
// longer hands out a free tier -- it unblocks one you go and earn.
//
// ---------------------------------------------------------------------
// A LOWER TOKEN IS STILL WORTH READING
//
// Tier is a BAND. Bands overlap. A Common that rolled high can beat an
// Advanced that rolled low on any given stat, the same way Trash tier
// still gets its treasure roll -- so the panel does not refuse a token
// beneath your rarity, it shows you the eight numbers and lets you
// decide. Tier is taken with max(), so spending one can never demote
// you or take a socket back: the only thing at risk is the roll under
// your feet, and every stat that would move is on screen first.
// =====================================================================

// One door for every cvar this system reads, so a missing or renamed
// cvar degrades to the documented default instead of null-dereferencing
// on .GetInt(). CVar.FindCVar returns null for a name that does not
// exist, and the mod's own convention -- RS_Elite.zs's header says so --
// is that a cvar block and its readers are a pair; this makes breaking
// the pair survivable rather than fatal.
class RS_TokenDial
{
	static int Int(string nm, int def)
	{
		let cv = CVar.FindCVar(nm);
		return cv ? cv.GetInt() : def;
	}

	static bool Bool(string nm, bool def)
	{
		let cv = CVar.FindCVar(nm);
		return cv ? cv.GetBool() : def;
	}
}

class RS_Rarity
{
	const START_TIER = VRT_Basic;

	// The whole-sprite colour wash for a tier, from TRNSLATE.txt.
	//
	// These are the palette's own colours -- see the note above the
	// rs_wpn_* block, which was one rung out for months because nothing
	// called it. RS_TierPalette.RGB() is still the source; this only
	// names the translation that was derived from it.
	// Returns `name`, not `string`. A_SetTranslation takes a Name, and
	// String -> Name is not a conversion ZScript will make for you on a
	// variable the way it does on a literal.
	static name TierTranslation(int t)
	{
		if (t == VRT_Cursed)    return "rs_wpn_cursed";
		if (t == VRT_Trash)     return "rs_wpn_trash";
		if (t == VRT_Common)    return "rs_wpn_common";
		if (t == VRT_Uncommon)  return "rs_wpn_uncommon";
		if (t == VRT_Advanced)  return "rs_wpn_advanced";
		if (t == VRT_Designer)  return "rs_wpn_designer";
		if (t == VRT_Prototype) return "rs_wpn_prototype";
		return "rs_wpn_basic";
	}

	// How loud the drop is, 0..1 up the ladder. Drives light radius, beam
	// height and beam brightness together, so a Prototype reads as a
	// different EVENT from across the room rather than as the same object
	// in a different colour. Basic sits at 0 and is never dropped.
	static double TierWeight(int t)
	{
		int lo = int(VRT_Common);
		int hi = int(VRT_Prototype);
		return clamp(double(int(t) - lo) / double(hi - lo), 0.0, 1.0);
	}

	static bool CanClimb(RS_Weapon w)
	{
		return w && w.Tier < VRT_Prototype;
	}

	static string TierWord(int t)
	{
		if (t == VRT_Cursed)    return "Cursed";
		if (t == VRT_Trash)     return "Trash";
		if (t == VRT_Basic)     return "Basic";
		if (t == VRT_Common)    return "Common";
		if (t == VRT_Uncommon)  return "Uncommon";
		if (t == VRT_Advanced)  return "Advanced";
		if (t == VRT_Designer)  return "Designer";
		if (t == VRT_Prototype) return "Prototype";
		return "?";
	}
}

// ---------------------------------------------------------------------
// The payload. `play` because Roll() spawns a donor actor and ApplyTo()
// writes fields on a live weapon.
// ---------------------------------------------------------------------
class RS_RarityPayload play
{
	Class<RS_Weapon> mWeaponClass;
	string mWeaponTag;
	int    mTier;

	// The eight the old imprint carried, and the eight RS_Weapon rolls.
	int    mDamagePerShot;
	double mAccuracy;
	double mVelocity;
	double mCritChance;
	double mCritMult;
	int    mCapacity;
	double mReloadSpeed;
	double mChoke;

	bool   mFilled;

	// -----------------------------------------------------------------
	// SEALS -- the drop's own curses, and NOT the weapon's.
	//
	// Two different things share the cursebit currency and it is worth
	// being blunt about which is which, because the card shows both:
	//
	//   WEAPON LOCK   a stat on YOUR GUN is halved and frozen. Lifted at
	//                 the weapon sheet, permanently. Blocks the gun from
	//                 taking a token at all. Reads "-- LOCKED --".
	//   TOKEN SEAL    a stat on THIS DROP has its number hidden. Opened
	//                 here, once, for bits. Blocks nothing. Reads
	//                 "-- SEALED --".
	//
	// THE ROLL HAPPENS AT DROP TIME, not at reveal. The sealed value is
	// already sitting in mDamagePerShot and friends before anyone pays;
	// opening a seal only stops hiding it. If the multiplier were rolled
	// on reveal, the gun you ended up with would depend on whether you
	// looked at it, and a reload would change the answer -- which players
	// find, and which makes the whole card feel rigged.
	//
	// 60% at a third, 40% at five thirds: 0.87x on average, so a seal is
	// a losing bet, with a jackpot big enough to be worth chasing. Owner's
	// numbers, picked over a softer floor deliberately -- a sealed stat
	// should be able to come out dead.
	const SEAL_DAMAGE   = 0;
	const SEAL_ACCURACY = 1;
	const SEAL_VELOCITY = 2;
	const SEAL_COUNT    = 3;

	bool mSealed[SEAL_COUNT];
	bool mOpen[SEAL_COUNT];
	int  mSealCost;           // cursebits per reveal, by tier
	bool mTouched;            // any reveal at all -> denying pays nothing

	int SealsLeft() const
	{
		int n = 0;
		for (int i = 0; i < SEAL_COUNT; i++)
			if (mSealed[i] && !mOpen[i]) n++;
		return n;
	}

	int NextSeal() const
	{
		for (int i = 0; i < SEAL_COUNT; i++)
			if (mSealed[i] && !mOpen[i]) return i;
		return -1;
	}

	bool IsHidden(int idx) const
	{
		return idx >= 0 && idx < SEAL_COUNT && mSealed[idx] && !mOpen[idx];
	}

	// What walking away is worth. Doubles per rung, so denying a
	// Prototype is a real sacrifice and denying a Common is housekeeping.
	//
	// mTouched is the whole tension of the mechanic: one reveal, even
	// one, and the salvage value is gone. Information costs bits AND the
	// option to cash out, which is what stops you probing your way to
	// certainty for free.
	int DenyGold() const
	{
		if (mTouched) return 0;
		int rung = clamp(int(mTier) - int(VRT_Common), 0, 4);
		return RS_TokenDial.Int("rs_token_deny_base", 6) << rung;
	}

	// -----------------------------------------------------------------
	// ROLL A TOKEN for a weapon class at a tier, using a donor.
	//
	// The donor is spawned OUT OF THE WORLD and destroyed immediately.
	// It never ticks, never renders, and never reaches the player -- it
	// exists for exactly as long as it takes to read eight numbers.
	// -----------------------------------------------------------------
	static play RS_RarityPayload Roll(Class<RS_Weapon> wcls, int tier)
	{
		if (!wcls) return null;

		let p = new("RS_RarityPayload");
		p.mWeaponClass = wcls;
		p.mTier        = tier;

		let donor = RS_Weapon(Actor.Spawn(wcls, (0, 0, 0), NO_REPLACE));
		if (!donor)
			return p;                    // unfilled; ApplyTo will do tier only

		donor.RollStats(tier);

		p.mWeaponTag     = donor.GetTag();
		p.mDamagePerShot = donor.DamagePerShot;
		p.mAccuracy      = donor.Accuracy;
		p.mVelocity      = donor.Velocity;
		p.mCritChance    = donor.CritChance;
		p.mCritMult      = donor.CritMult;
		p.mCapacity      = donor.Capacity;
		p.mReloadSpeed   = donor.ReloadSpeed;
		p.mChoke         = donor.Choke;
		p.mFilled        = true;

		donor.Destroy();

		// --- seal the roll, before anyone can look at it -------------
		p.mSealCost = RS_TokenDial.Int("rs_token_seal_cost", 4)
			+ 2 * clamp(int(tier) - int(VRT_Common), 0, 4);

		int chance = clamp(RS_TokenDial.Int("rs_token_seal_chance", 22), 0, 100);
		int badPct = clamp(RS_TokenDial.Int("rs_token_seal_bad",    60), 0, 100);
		double lo  = RS_TokenDial.Int("rs_token_seal_low",   33) / 100.0;
		double hi  = RS_TokenDial.Int("rs_token_seal_high", 167) / 100.0;

		for (int i = 0; i < SEAL_COUNT; i++)
		{
			if (random[RSSeal](1, 100) > chance) continue;
			p.mSealed[i] = true;

			// The bet, resolved now and stored. See the SEALS note above
			// for why this cannot happen at reveal time.
			double mult = (random[RSSeal](1, 100) <= badPct) ? lo : hi;
			if (i == SEAL_DAMAGE)        p.mDamagePerShot = max(1, int(p.mDamagePerShot * mult));
			else if (i == SEAL_ACCURACY) p.mAccuracy = p.mAccuracy * mult;
			else if (i == SEAL_VELOCITY) p.mVelocity = p.mVelocity * mult;
		}

		return p;
	}

	// Open one seal. Payment happens FIRST and is checked before anything
	// mutates, so a refused reveal leaves no half-state -- same discipline
	// as RS_CurseLedger.LiftCurse.
	bool RevealSeal(int idx, PlayerPawn pawn)
	{
		if (!pawn || !IsHidden(idx)) return false;
		if (pawn.CountInv("RS_Bit_Curse") < mSealCost) return false;

		pawn.TakeInventory("RS_Bit_Curse", mSealCost);
		mOpen[idx] = true;
		mTouched   = true;      // the salvage value is gone, permanently
		return true;
	}

	// Right weapon, and is it actually an upgrade?
	bool Matches(RS_Weapon w) const
	{
		return w && mWeaponClass && w.GetClass() == mWeaponClass;
	}

	// Deliberately NOT an IsUpgradeFor(). There was one -- Matches() &&
	// w.Tier < mTier -- and every use of it was a refusal the player did
	// not agree with. Whether a token is worth taking is a question about
	// eight rolled numbers, not about which of two tier words is higher,
	// and the panel is where that gets answered.
	bool RaisesTier(RS_Weapon w) const
	{
		return Matches(w) && w.Tier < mTier;
	}

	// -----------------------------------------------------------------
	// SPEND IT.
	//
	// Deliberately NOT RS_Weapon.ApplyUpgradeCard: that calls RollStats,
	// which re-rolls every stat and would delete the increases the
	// player earned levelling. Same curse gate, different stat handling.
	// -----------------------------------------------------------------
	bool ApplyTo(RS_Weapon w)
	{
		if (!Matches(w))
		{
			Announce(w, "\c[Red]Wrong weapon.\c- That token is for a " .. mWeaponTag .. ".");
			return false;
		}
		// A LOWER TOKEN IS NOT A REFUSAL. It used to be -- "Already
		// Advanced, that token is only Common" -- and that was the
		// engine deciding for you on tier alone.
		//
		// Tier is a BAND, not a number. Bands overlap, and a Common can
		// roll high in its band while your Advanced rolled low in its.
		// Nothing here knows which until the eight numbers are on the
		// panel, so the panel shows them and you decide. Same shape as
		// the treasure roll on Trash: the floor tier still gets to
		// surprise you.
		//
		// What a lower token CANNOT do is demote you -- see the max()
		// on Tier below. So spending one is a pure re-base of the stat
		// floor: your rarity and your sockets are never at risk, only
		// the roll underneath them, and every stat that would move is
		// on screen in green or red before you press USE.
		// The one interesting restriction, and the reason curses still
		// bite now that lifting one no longer hands out a free tier.
		//
		// Say WHAT is in the way and HOW MANY, not that some unseen
		// force disapproves. A locked stat is a mechanic the player can
		// count and act on; a curse with opinions is scenery.
		if (!w.CanAcceptImprint(mTier))
		{
			int n = w.CurseCount();
			Announce(w, string.format("\c[Red]%d stat%s locked.\c- Lift one before this weapon can take a higher rarity.",
				n, n == 1 ? "" : "s"));
			return false;
		}

		// ADDITIVE: the token's roll PLUS what levelling earned.
		//
		//     new = tokenRoll + (current - RollBase)
		//
		// The owner's rule, and the reason RollBase* exists. Not a
		// re-roll (that deletes your level history) and not keep-better
		// (that quietly discards the token's roll whenever your current
		// number is higher, which on overlapping bands is often).
		//
		// Note what this means: since the earned part is on both sides,
		// new - current reduces to tokenRoll - RollBase. So the token is
		// judged purely against the roll THIS GUN ORIGINALLY GOT, and a
		// stat CAN go down -- an SMG that rolled 11 damage at Basic beats
		// a 7 rolled at Uncommon. That is deliberate: it makes a token a
		// trade rather than a guaranteed upgrade, and it is why the
		// preview screen shows red as well as green.
		if (mFilled)
		{
			w.DamagePerShot = mDamagePerShot + w.EarnedDamage();
			w.Accuracy = mAccuracy + w.EarnedAccuracy();
			w.Velocity = mVelocity + w.EarnedVelocity();
			w.CritChance = mCritChance + w.EarnedCritChance();
			w.CritMult = mCritMult + w.EarnedCritMult();
			w.Capacity = mCapacity + w.EarnedCapacity();
			w.ReloadSpeed = mReloadSpeed + w.EarnedReloadSpeed();
			w.Choke = mChoke + w.EarnedChoke();
		}

		// TIER, then sockets FROM it -- read through RS_Roll rather than
		// hardcoded, so the socket table has one owner and cannot drift.
		// Same argument Promote() makes for itself.
		//
		// max(), not assignment: a token can re-base your numbers but it
		// can never take rarity away. Without this, spending a Common on
		// an Advanced gun would silently drop you from 3 sockets to 1 and
		// orphan two affixes you already own.
		int wasTier      = w.Tier;
		w.Tier            = max(w.Tier, mTier);
		w.GunBonaiSockets = RS_Roll.SocketsForTier(w.Tier);

		if (w.Tier > wasTier)
			Announce(w, string.format("\c[Gold]%s is now %s.\c- %d socket%s.",
				w.GetTag(), RS_Rarity.TierWord(w.Tier),
				w.GunBonaiSockets, w.GunBonaiSockets == 1 ? "" : "s"));
		else
			Announce(w, string.format("\c[Gold]%s re-rolled.\c- Still %s, %d socket%s.",
				w.GetTag(), RS_Rarity.TierWord(w.Tier),
				w.GunBonaiSockets, w.GunBonaiSockets == 1 ? "" : "s"));
		return true;
	}

	private void Announce(RS_Weapon w, string msg)
	{
		if (w && w.owner && w.owner.player == players[consoleplayer])
			Console.Printf("%s", msg);
	}
}

// =====================================================================
// THE DROP. A world object you walk up to, read, and USE.
//
// NOT an Inventory pickup, deliberately, and this is the third shape
// this took before it was right.
//
// Auto-apply is wrong because a token is not always an upgrade. The
// owner's rule: "sometimes it's an improvement, sometimes a lateral
// move, sometimes a calculated tradeoff." Tier and sockets always climb,
// but the stats are judged against the roll your gun ORIGINALLY got and
// the tier bands overlap -- an SMG that rolled 11 damage at Basic beats
// a 7 rolled at Uncommon. A thing that can make your gun worse cannot
// apply itself the moment you brush past it.
//
// Carrying it in inventory and spending it from a menu was wrong too --
// that was mine, invented, and it added a screen nobody asked for.
//
// WHAT IT ACTUALLY IS: it lies on the floor. Stand near it and it tells
// you which hand it is for and exactly what it would do to the weapon
// you are holding RIGHT NOW -- improvement, lateral, or trade, per stat.
// Switch weapons and the numbers change with you, because the weapon in
// your hand IS the selection. There is no cursor and no list. Press USE
// to commit it to that weapon.
//
// +USESPECIAL and Used() are stock engine, so this needs nothing from
// the fork and nothing from the VR interaction layer that never worked.
// =====================================================================

// ---------------------------------------------------------------------
// WHAT IT LOOKS LIKE, and the three reasons it looked like nothing.
//
// The first version was `BON1 ABCDCB 6 Bright` -- the vanilla health
// bonus flask, straight out of the IWAD, dropped into the middle of a
// 4-to-25 piece burst of OTHER health bonuses. The flagship reward of the
// entire elite layer was a blue potion in a pile of fruit, and a
// Prototype was pixel-identical to a Common.
//
// It also could not be reached or picked up, for two separate reasons
// that each looked like the other's fault:
//
//   +NOGRAVITY with vel.z 3..5 from the drop. Nothing pulls it back
//   down, so it rose at 100-175 units/sec until it clamped against the
//   ceiling and parked there, out of a 64-unit use trace.
//
//   +NOBLOCKMAP. The use trace finds things through the blockmap, so
//   even at floor level +USESPECIAL could never have fired. Both gone.
//
// WHAT IT IS NOW: the weapon's own floor pickup, washed in the tier
// colour, lit, under a tapered shaft of light.
//
// THE PICKUP IS A REAL WEAPON ACTOR, not a sprite copied off one. That
// is not laziness, it is the only thing that works: 33 of the 44 weapons
// render their floor pickup as an .md3 model rather than a sprite, four
// (BFG9000, Pistol, PlasmaRifle, RocketLauncher) have no sprite lump in
// the tree at all, the Fist is TNT1, and the SSG's only resolves from
// the IWAD. Reading `sprite` off the class would have drawn nothing for
// a quarter of the arsenal and a red exclamation mark for four of them.
// Spawning the class gets the model OR the sprite, whichever that weapon
// actually has, for all 264 weapon classes, and needs no MODELDEF -- and
// MODELDEF matches on exact class pointer, so the alternative would have
// been 264 hand-written blocks.
//
// The double is inert: not SPECIAL so it cannot be picked up, not in the
// blockmap so it cannot be shot or bumped, NOINTERACTION so it does not
// tick, fall, or advance a state. It is a mesh at a position. The token
// underneath it is the thing with a body and the thing USE finds.
// ---------------------------------------------------------------------

class RS_RarityToken : Actor
{
	RS_RarityPayload mPayload;

	private Actor      mProp;        // the weapon, as an inert display double
	private Array<int> mBeamIds;
	private int        mSpinTic;

	// Tap-versus-hold state. mUser is who pressed; it is only ever read
	// while mHolding, and cleared on release.
	private PlayerPawn mUser;
	private bool       mHolding;
	private int        mHoldTics;

	// The shaft. Slices rather than one quad because a taper is a change
	// in WIDTH along the beam, and a billboard is a rectangle -- a single
	// quad can fade out toward the top but it cannot narrow. Six is where
	// the stepping stops reading as steps at normal approach distances.
	const BEAM_SLICES = 6;
	const BEAM_BASE_W = 7.0;
	const BEAM_SLICE_H = 13.0;

	// How far the display double floats above the token's own origin. See
	// Tick() -- this is clearance, not decoration.
	const PROP_LIFT = 20.0;

	Default
	{
		+USESPECIAL          // Used() fires on the use key
		+DONTSPLASH
		+NOTELEPORT
		+FLOORCLIP
		Radius 20;
		Height 24;
		// The token itself never draws. Everything visible is the display
		// double or the beam, so this is a physics body and a use target
		// wearing nothing.
		RenderStyle "None";
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	// -----------------------------------------------------------------
	// SETUP, not a field assignment.
	//
	// The payload cannot arrive in PostBeginPlay -- Spawn() has to return
	// before the caller can hand it over -- and everything visible about
	// this actor is derived from the payload. So the drop calls this, and
	// this is where the object actually comes into being.
	// -----------------------------------------------------------------
	void Setup(RS_RarityPayload p)
	{
		mPayload = p;
		if (!p || !p.mWeaponClass) return;

		Color  tcol = RS_TierPalette.RGB(p.mTier);
		double wgt  = RS_Rarity.TierWeight(p.mTier);

		// --- the weapon, as an inert double --------------------------
		mProp = Spawn(p.mWeaponClass, pos, NO_REPLACE);
		if (mProp)
		{
			mProp.bSPECIAL      = false;   // cannot be picked up
			mProp.bSOLID        = false;
			mProp.bNOGRAVITY    = true;
			// NOT `mProp.bNOBLOCKMAP = true`. That field is not writable
			// from script -- the blockmap holds links to the actor, so
			// flipping the flag without unlinking leaves the grid pointing
			// at something that thinks it is not there. A_ChangeLinkFlags
			// is the sanctioned door and does the unlink for you.
			mProp.A_ChangeLinkFlags(1);    // cannot be shot, bumped or used
			mProp.bNOINTERACTION = true;   // no tick, no state advance, no fall
			mProp.bCOUNTITEM    = false;
			mProp.bBRIGHT       = true;    // reads as lit, not as a dark prop
			mProp.bNOTONAUTOMAP = true;
			mProp.A_SetTranslation(RS_Rarity.TierTranslation(p.mTier));
		}

		// --- the emissive --------------------------------------------
		// Keyed by NAME, and the name is the contract: GITD owns
		// "gitd_muzzle", RS_Main's beat light owns "rs_beat_muzzle", and
		// reusing either here would fight them frame by frame with no
		// error. This one is its own.
		//
		// A pulse rather than a point light because a static glow on a
		// floor item reads as level geometry; a slow breath reads as
		// something waiting to be taken.
		if (RS_TokenDial.Bool("rs_token_light", true))
		{
			double ls = RS_TokenDial.Int("rs_token_light_scale", 100) / 100.0;
			int r1 = int((20 + 26 * wgt) * ls);
			int r2 = int((34 + 44 * wgt) * ls);
			A_AttachLight("rs_token_glow", DynamicLight.PulseLight, tcol, r1, r2,
				DynamicLight.LF_ATTENUATE,
				(0, 0, 12), 1.6);
		}

		if (RS_TokenDial.Bool("rs_token_beam", true))
			BuildBeam(tcol, wgt);
	}

	// The shaft of light: stacked camera-facing quads, each narrower and
	// fainter than the one below it, so it closes to a point overhead.
	//
	// BILLBOARDS RATHER THAN PARTICLES, deliberately. This codebase's only
	// particle idiom is A_SpawnParticle, whose shape is the PLAYER's
	// gl_particles_style -- default 0, square. A beam tapering to a point
	// built out of squares reads as a stack of squares. Particles also
	// come from a 4000-entry global pool that RS_ElitePentagram already
	// spends ~745 a tic on, and this beam has to survive being spawned
	// during exactly that effect.
	private void BuildBeam(Color tcol, double wgt)
	{
		double h = BEAM_SLICE_H * (0.75 + 0.5 * wgt);

		for (int i = 0; i < BEAM_SLICES; i++)
		{
			// Cubic taper: nearly full width at the base, closing fast at
			// the top. Linear leaves a visible blunt end.
			double f = double(i) / double(BEAM_SLICES - 1);
			double w = BEAM_BASE_W * (1.0 - f) * (1.0 - f * 0.55);
			if (w < 0.35) w = 0.35;

			// Starts ABOVE the display double, not at the token's feet --
			// a shaft whose base is buried in the floor under the weapon
			// reads as a stripe on the wall behind it.
			int id = level.AttachBillboard(self,
				(0, 0, RS_TokenDial.Int("rs_token_prop_lift", 20) + 4 + h * i), w, h,
				0, 0, LevelLocals.BBF_CAMERAYAW,
				LevelLocals.BB_PANEL, 0, tcol,
				LevelLocals.BBFL_NOHIT);
			if (!id) continue;

			// Alpha falls faster than width so the top dissolves rather
			// than ending. Squared, and scaled by tier so a Common is a
			// hint and a Prototype is a landmark.
			double a = (0.40 + 0.34 * wgt) * (1.0 - f * 0.85) * (1.0 - f * 0.85)
				* (RS_TokenDial.Int("rs_token_beam_alpha", 100) / 100.0);
			level.SetBillboardAlpha(id, a);
			mBeamIds.Push(id);
		}
	}

	// -----------------------------------------------------------------
	// The double is NOINTERACTION, so it does not move itself. Here is
	// where it gets carried: parked on the token, turning, breathing.
	//
	// Both terms are cheap and neither allocates. The turn is the reason
	// a model pickup reads as a reward rather than as scenery.
	// -----------------------------------------------------------------
	override void Tick()
	{
		Super.Tick();

		// --- resolve the press ---------------------------------------
		// Used() cannot tell a tap from a hold, so it only starts the
		// clock and this decides. Reading cmd.buttons rather than
		// counting Used() calls, because GZDoom fires Used() once per
		// press and never again while the key is down.
		if (mHolding)
		{
			bool down = mUser && mUser.player
				&& (mUser.player.cmd.buttons & BT_USE);

			if (!down)
			{
				mHolding = false;
				Tap();                       // released early: it was a tap
				return;                      // Tap may have destroyed us
			}

			mHoldTics++;
			if (mHoldTics >= DenyTics())
			{
				mHolding = false;
				Deny();
				return;
			}
		}

		if (!mProp || mProp.bDestroyed) return;

		// PROP_LIFT, and why it is this large. A weapon's floor pickup is
		// an .md3 centred on its actor origin, and the token now has
		// gravity, so it comes to rest with ITS origin ON the floor. Lift
		// the double by a bob of 3-5 and half the mesh is still under the
		// boards -- which is exactly how it shipped: a shotgun sunk into
		// the floor. The bob rides on top of a real clearance.
		mSpinTic++;
		double bob = RS_TokenDial.Int("rs_token_prop_lift", 20) + 2.2 * sin(mSpinTic * 3.2);
		mProp.SetOrigin(pos + (0, 0, bob), true);
		mProp.angle = mSpinTic * 1.7;
	}

	// Attached billboards die with their actor, so the beam needs no
	// teardown -- but the double is a separate actor and would be left
	// standing in an empty room. Removing the beam explicitly anyway
	// costs one loop and does not depend on that guarantee holding.
	override void OnDestroy()
	{
		for (int i = 0; i < mBeamIds.Size(); i++)
			level.RemoveBillboard(mBeamIds[i]);
		mBeamIds.Clear();
		if (mProp && !mProp.bDestroyed) mProp.Destroy();
		Super.OnDestroy();
	}

	// The weapon this token would land on: the one in the matching hand.
	// Mainhand and offhand are separate weapon CLASSES, so the token's
	// own class already decides the hand -- there is nothing to ask.
	RS_Weapon TargetWeapon(PlayerPawn pawn)
	{
		if (!pawn || !pawn.player || !mPayload) return null;
		let mainW = RS_Weapon(pawn.player.ReadyWeapon);
		let offW  = RS_Weapon(pawn.player.OffhandWeapon);
		if (mPayload.Matches(mainW)) return mainW;
		if (mPayload.Matches(offW))  return offW;
		return null;
	}

	// The readout is DRAWN, not printed -- see RS_TokenHUD below. A
	// six-line console dump in the top corner, re-nagging every three
	// seconds, is unreadable in a headset and was the weak half of the
	// first version of this.

	// -----------------------------------------------------------------
	// ONE BUTTON, THREE JOBS. Tap to advance, hold to walk away.
	//
	//   tap, seals remain    pay bits, open the next one
	//   tap, nothing sealed  apply the token to the weapon in your hand
	//   hold ~1s             break the drop for gold, and it is gone
	//
	// Overloading USE is not laziness -- there is no free button on a
	// controller, and the alternatives were both worse. A second hotspot
	// on the card needs the VR pointer, which has never worked here. A
	// new keybind ships unbound and therefore invisible.
	//
	// What makes the overload safe is that THE CARD ALWAYS SAYS WHAT THE
	// NEXT TAP DOES. The footer reads "[ REVEAL - 8 BITS ]" or "[ USE ]"
	// or "LIFT 2 TO TAKE THIS", and the hold line sits under it with the
	// gold figure on it. Nobody has to remember a rule; they read the
	// thing they are already looking at.
	//
	// Used() is the PRESS. It cannot apply anything, because at press
	// time we do not yet know whether this is a tap or a hold -- so it
	// only starts the clock, and Tick decides on release.
	// -----------------------------------------------------------------
	// Read once per press rather than held as a const, so the slider
	// takes effect on the very next press.
	private int DenyTics() const
	{
		return clamp(RS_TokenDial.Int("rs_token_hold_tics", 32), 6, 200);
	}

	override bool Used(Actor user)
	{
		let pawn = PlayerPawn(user);
		if (!pawn || !mPayload) return false;

		mUser     = pawn;
		mHolding  = true;
		mHoldTics = 0;
		return true;
	}

	double HoldFraction() const
	{
		if (!mHolding) return 0.0;
		return clamp(double(mHoldTics) / double(DenyTics()), 0.0, 1.0);
	}

	// A tap: advance one step. Reveal if anything is sealed, otherwise
	// apply.
	private void Tap()
	{
		let pawn = mUser;
		if (!pawn || !mPayload) return;
		bool mine = (pawn.player == players[consoleplayer]);

		int idx = mPayload.NextSeal();
		if (idx >= 0)
		{
			if (mPayload.RevealSeal(idx, pawn))
			{
				A_StartSound("misc/chat2", CHAN_AUTO, CHANF_DEFAULT, 0.7);
				if (mine)
					Console.Printf("\c[Gold]Seal broken.\c- %d bit%s spent, %d seal%s left.",
						mPayload.mSealCost, mPayload.mSealCost == 1 ? "" : "s",
						mPayload.SealsLeft(), mPayload.SealsLeft() == 1 ? "" : "s");
			}
			else if (mine)
			{
				Console.Printf("\c[Red]Not enough curse bits.\c- That seal costs %d.",
					mPayload.mSealCost);
			}
			return;
		}

		let w = TargetWeapon(pawn);
		if (!w)
		{
			if (mine)
				Console.Printf("\c[Red]Hold your %s to apply this.\c-", mPayload.mWeaponTag);
			return;
		}

		// ApplyTo says its own no, with its own reason.
		if (!mPayload.ApplyTo(w)) return;

		A_StartSound("misc/i_pkup", CHAN_AUTO);
		Destroy();
	}

	// A hold: break the drop for gold and remove it from the world.
	private void Deny()
	{
		let pawn = mUser;
		if (!pawn || !mPayload) return;

		int gold = mPayload.DenyGold();
		if (gold > 0) pawn.GiveInventory("RS_Bit_Gold", gold);

		if (pawn.player == players[consoleplayer])
		{
			if (gold > 0)
				Console.Printf("\c[Gold]Broken down.\c- %d gold.", gold);
			else
				Console.Printf("\c[Gold]Broken down.\c- Nothing back -- a seal was already opened.");
		}

		A_StartSound("world/barrelx", CHAN_AUTO, CHANF_DEFAULT, 0.55);
		Destroy();
	}
}

// =====================================================================
// RS_TokenPanel -- the readout, as a view-locked in-world panel.
//
// NOT a HUD draw. The first attempt was Screen.DrawText into the corner
// of the screen, which in a headset is a thing you look AWAY to read.
// This is real world geometry parked at eye level: it has depth, it has
// parallax, it occupies the room.
//
// BBFL_VIEWLOCKED does the parking -- position becomes an offset from
// the viewer (X ahead, Y right, Z up), resolved AT RENDER RATE, so it
// stays welded to your view instead of lagging a tic and snapping. A
// script-moved panel is what makes people ill; this is not one.
//
// ---------------------------------------------------------------------
// THE DESIGN
//
// Three planes, not one flat card. X is distance, so drawing the shell
// further out than the content gives real parallax when you move your
// head -- the panel has a back and a front, and in a headset that is
// the difference between a sign and an object.
//
//   +1.2   shell      near-black, the full rect
//   +0.6   face       the token's tier colour at low alpha, inset
//    0.0   content    every glyph, number, rule and badge
//
// HIERARCHY. The socket count is the HEADLINE, not a row. It is the only
// number on the panel that gates anything -- rarity is where sockets
// come from, and sockets are what lets a weapon hold affixes at all, so
// a Basic gun reading "0 -> 2" is being told it can finally take cards.
// It gets BB_WG13, the lozenge with the figure punched out of it, at
// twice the size of anything else. The stat rows are detail beneath it.
//
// PAYLOADS, and why each:
//   BB_WG13     the socket badge. Progress opens it from a slit into a
//               full lozenge, the digit appearing past 0.55, so the
//               headline number ASSEMBLES rather than appears.
//   BB_SEGMENT  every other number. Shader-built 16-segment, no font
//               atlas, so it cannot break on a missing lump and stays
//               exactly sharp at any size.
//   BB_TEXT     every label. "DAMAGE" in segments reads like a fault
//               code; words want a real typeface.
//   BB_PANEL    shell, face and the hairline rules -- a rule is a panel
//               0.35 tall, which is one shape instead of a second
//               graphic to keep in sync.
//
// THE REVEAL. Everything carrying a progress term ramps 0 -> 1 over ten
// tics on appearance, eased, so the panel builds itself in front of you.
// One float per frame while it runs and nothing afterwards.
//
// Every element is BBFL_NOHIT. The panel is pure readout and must never
// answer an aim or touch query -- you USE the token, not the sign
// hanging over it, and without this the sign is permanently in the way.
// =====================================================================
class RS_TokenPanel : EventHandler
{
	// Eye-level parking, map units. AHEAD is reading distance: far
	// enough not to cross your eyes, near enough to fill a comfortable
	// arc. UP sits it a touch under the horizon so it is not on top of
	// whatever you are aiming at.

	// SIZED IN DEGREES, NOT UNITS. At AHEAD 46 these subtend 43 x 32
	// degrees of view. The first pass was 31 x 22, which is 68 x 51 --
	// a cinema screen strapped to your face. Comfortable reading in a
	// headset is 30-40 degrees, so anything changed here should be
	// checked back against that arc rather than eyeballed in units.
	// FIELDS, NOT CONSTANTS, and read from cvars every rebuild.
	//
	// Getting a panel readable in a headset is a dozen small adjustments
	// and every one of them used to cost a full rebuild-and-relaunch.
	// These are the numbers that were guessed at wrong twice already --
	// the panel shipped at 68x51 degrees, then at half the size it
	// thought it was -- so they are the ones that belong on sliders.
	//
	// The literals here are the defaults and the cvars carry the same
	// values, so a fresh install draws exactly this.
	private double AHEAD, UP, HALF_W, HALF_H, ROW_H, BORDER;
	private double REACH_NEAR, REACH_FAR;
	private int    REVEAL_TICS;

	// Plane offsets. Bigger X is further away. Not exposed -- these set
	// the parallax between the three planes and are a design decision
	// rather than a comfort dial.
	const Z_SHELL = 0.9;
	const Z_FACE  = 0.45;

	// -----------------------------------------------------------------
	// THE FLOW. Two cursors and a unit, and that is the whole layout
	// engine -- see the long note in Build() for why there are no
	// coordinates in this file any more.
	//
	// LINE is the type scale: one line of body text, as a share of the
	// card's half-height. Everything sizes in multiples of it, so the
	// card's proportions survive any Half Height the slider is set to
	// and the type never grows out of step with the box holding it.
	// -----------------------------------------------------------------
	private double mFlowTop, mFlowBot;

	private double LINE() const { return HALF_H * 0.075; }
	private double PAD()  const { return BORDER + LINE() * 0.6; }

	private void FlowReset()
	{
		mFlowTop =  HALF_H - PAD();
		mFlowBot = -HALF_H + PAD();
	}

	// Take a band of half-height hh off the top and return its centre.
	// gap is the air left under it, in lines.
	private double FlowDown(double hh, double gapLines = 0.5)
	{
		double c = mFlowTop - hh;
		mFlowTop = c - hh - LINE() * gapLines;
		return c;
	}

	// The same, walking up from the bottom edge.
	private double FlowUp(double hh, double gapLines = 0.5)
	{
		double c = mFlowBot + hh;
		mFlowBot = c + hh + LINE() * gapLines;
		return c;
	}

	// What is left between the two cursors, and where its centre is.
	// The stat rows divide this rather than assuming a size, which is
	// what makes the card impossible to overflow.
	private double FlowLeft() const   { return max(0.0, mFlowTop - mFlowBot); }
	private double FlowMiddle() const { return (mFlowTop + mFlowBot) * 0.5; }

	private int CvInt(string nm, int def)
	{
		let cv = CVar.FindCVar(nm);
		return cv ? cv.GetInt() : def;
	}

	// The distance gate is read at the TOP of WorldTick, before any
	// rebuild can have run, so the dials cannot wait for the first Build
	// -- a zero REACH_NEAR on tic one means the panel never appears at
	// all and nothing on screen says why.
	override void OnRegister()
	{
		Super.OnRegister();
		ReadDials();
	}

	private void ReadDials()
	{
		AHEAD       = CvInt("rs_token_ahead",  46);
		UP          = CvInt("rs_token_up",     -1);
		HALF_W      = max(4, CvInt("rs_token_halfw", 18));
		HALF_H      = max(3, CvInt("rs_token_halfh", 13));
		ROW_H       = max(1.0, CvInt("rs_token_rowh",   32) / 10.0);
		BORDER      = clamp(CvInt("rs_token_border", 7) / 10.0, 0.0, HALF_H - 0.5);
		REACH_NEAR  = max(8,  CvInt("rs_token_near", 88));
		REACH_FAR   = max(REACH_NEAR + 4, CvInt("rs_token_far", 116));
		REVEAL_TICS = clamp(CvInt("rs_token_grow_tics", 10), 1, 140);
	}

	// -----------------------------------------------------------------
	// TWO DISTANCES, because the beam and the panel are answering
	// different questions.
	//
	// The beam is "there is a Designer SMG token over there" and wants to
	// carry across a room. The panel is "here is what it would do to the
	// gun in your hand", six lines of small type, and wants you standing
	// over the thing. One radius for both meant either a panel appearing
	// at conversational distance or a beam you had to walk into to see.
	//
	// The beam has no radius at all -- it is world geometry and is
	// geometry and is simply visible.
	// -----------------------------------------------------------------

	private Array<int> mIds;
	private Array<int> mProgressIds;    // the subset that animates in
	private RS_RarityToken mShownFor;
	private string mSig;
	private int mBornTic;
	private int mGroup;                 // the shared transform; 0 when none
	private int mHoldRingId;          // driven per tic, never rebuilt

	private void Clear()
	{
		for (int i = 0; i < mIds.Size(); i++)
			level.RemoveBillboard(mIds[i]);
		mIds.Clear();
		mHoldRingId = 0;
		mProgressIds.Clear();
		// Release the members first, then drop the group. Order matters
		// only in that a group outliving its members is a leak the engine
		// will not report -- ids are never recycled, so it would sit there
		// scaling nothing until the level ended.
		if (mGroup) level.RemoveBillboardGroup(mGroup);
		mGroup = 0;
		mShownFor = null;
		mSig = "";
	}

	// One door for every element, so parking and flags cannot drift.
	//
	// TAKES HALF-EXTENTS, PASSES FULL ONES. The engine's width and height
	// are full extents -- BillboardBasis does `halfw = bb.width * 0.5` --
	// but every number in this file is a half-extent measured from the
	// panel's centre, which is what HALF_W and HALF_H have said all along.
	// Handing half-extents straight to the engine drew every element at
	// HALF its size while leaving every POSITION correct, so the shell
	// shrank away from a layout that stayed put: tiny text, a tiny socket
	// badge, and the VELOCITY row sitting outside the box it belongs in.
	// One conversion, in the one place everything goes through.
	private int Put(double right, double up, double w, double h,
		int payload, int data, color col, string text = "", double depth = 0)
	{
		int id = level.AddBillboardPersistent(
			(AHEAD + depth, right, UP + up), w * 2.0, h * 2.0,
			0, 0, LevelLocals.BBF_FIXED,
			payload, data, col,
			LevelLocals.BBFL_PERSISTENT | LevelLocals.BBFL_VIEWLOCKED | LevelLocals.BBFL_NOHIT, 0, text);
		if (id)
		{
			mIds.Push(id);
			// Every element joins the group, so the grow scales the panel
			// as an object -- sizes AND the gaps between them. Elements
			// added but not joined would stay full-size inside a
			// collapsing panel, which looks like a rendering fault.
			if (mGroup) level.SetBillboardGroup(id, mGroup);
		}
		return id;
	}

	// -----------------------------------------------------------------
	// TESTING. Elites are a 5% roll that then has to be fought to half
	// health before it pays anything, so waiting for a Designer token to
	// turn up on its own is not a way to iterate on a card.
	//
	//   netevent rs_token          a token for the gun in your hand,
	//                              tier rolled Common..Prototype
	//   netevent rs_token <3..7>   that exact tier (VRT_Common is 3)
	//   netevent rs_token_wipe     clear every token on the map
	// -----------------------------------------------------------------
	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || !playeringame[e.Player]) return;
		let pmo = players[e.Player].mo;
		if (!pmo) return;

		if (e.Name ~== "rs_token_wipe")
		{
			int n = 0;
			let it = ThinkerIterator.Create("RS_RarityToken");
			Thinker th;
			while (th = it.Next()) { th.Destroy(); n++; }
			Console.Printf("\c[Gold]%d token%s removed.", n, n == 1 ? "" : "s");
			return;
		}

		if (!(e.Name ~== "rs_token")) return;

		// The gun in your hand names the family, exactly as a real drop
		// does -- a test token for a weapon you are not holding would
		// exercise the "SWITCH TO IT" branch and nothing else.
		let w = RS_Weapon(pmo.player.ReadyWeapon);
		if (!w) w = RS_Weapon(pmo.player.OffhandWeapon);
		if (!w)
		{
			Console.Printf("\c[Red]Hold an RS weapon first.");
			return;
		}

		int tier = e.Args[0];
		if (tier < int(VRT_Common) || tier > int(VRT_Prototype))
			tier = random[RSSeal](int(VRT_Common), int(VRT_Prototype));

		let payload = RS_RarityPayload.Roll(w.GetClass(), tier);
		if (!payload) return;

		let drop = RS_RarityToken(Actor.Spawn("RS_RarityToken",
			pmo.Vec3Angle(56, pmo.angle, 16), ALLOW_REPLACE));
		if (!drop) return;
		drop.Setup(payload);

		Console.Printf("\c[Gold]%s %s\c- dropped -- %d seal%s.",
			RS_Rarity.TierWord(tier), payload.mWeaponTag,
			payload.SealsLeft(), payload.SealsLeft() == 1 ? "" : "s");
	}

	override void WorldTick()
	{
		let pawn = players[consoleplayer].mo;
		if (!pawn || pawn.health <= 0) { Clear(); return; }

		// Hysteresis: come in at REACH_NEAR, leave at REACH_FAR. Standing
		// exactly on a single threshold makes the panel strobe on every
		// breath of stick drift, and a panel that builds and collapses
		// four times a second in front of someone's face is the worst
		// thing in this file.
		double gate = mShownFor ? REACH_FAR : REACH_NEAR;

		RS_RarityToken best = null;
		double bestD = gate;
		let it = ThinkerIterator.Create("RS_RarityToken");
		Thinker th;
		while (th = it.Next())
		{
			let t = RS_RarityToken(th);
			if (!t || !t.mPayload) continue;
			double d = t.Distance3D(pawn);
			if (d < bestD) { bestD = d; best = t; }
		}
		if (!best) { Clear(); return; }

		// Rebuild only when the READING changes -- a different token, or
		// you switched weapons over this one. Twenty billboards a frame
		// for a thing that is static most of the time is waste.
		// Spelled out rather than three ?: in a concatenation. ZScript will
		// not take a ternary whose arms are different types, and each of
		// these had a mismatch hiding in it: GetClassName() is a Name
		// against a String literal, and Tier is an enum against an int.
		// Concatenation converts all of them happily; the ternary is where
		// it dies.
		let w = best.TargetWeapon(PlayerPawn(pawn));
		string wname = "none";
		int    wtier = -1;
		int    wdmg  = -1;
		if (w)
		{
			wname = w.GetClassName();
			wtier = int(w.Tier);
			wdmg  = w.DamagePerShot;
		}
		string sig = best.mPayload.mWeaponTag .. "|" .. best.mPayload.mTier
			.. "|" .. wname .. "|" .. wtier .. "|" .. wdmg;

		if (best != mShownFor || sig != mSig)
		{
			Clear();
			mShownFor = best;
			mSig      = sig;
			mBornTic  = level.maptime;

			// Re-read every rebuild, so a slider moved in the menu shows
			// up the next time you step away from a token and back.
			ReadDials();

			// THE GROW, declared once and then left alone.
			//
			// The origin is the panel's centre in view-offset space, which
			// is the same space Put() places every element in -- so scale
			// 0 collapses the whole assembly to a single point at reading
			// distance and scale 1 is the built layout, with every
			// intermediate value a real smaller panel rather than small
			// elements in a full-size arrangement.
			//
			// The engine resolves this per FRAME. Driving it from here
			// would step at 35Hz and would cost two setter calls per
			// element per step, each an O(n) scan of the billboard array.
			mGroup = level.AddBillboardGroup((AHEAD, 0, UP));

			Build(best, PlayerPawn(pawn));

			// After Build, so the members exist to be scaled. A group with
			// no members animates nothing and is not an error.
			if (mGroup)
				level.AnimateBillboardGroup(mGroup, 0.0, 1.0, REVEAL_TICS);
		}

		// The hold ring, every tic. One float, and only while a press is
		// actually being held -- the rest of the time this writes 0 once
		// and the branch costs a comparison.
		if (mHoldRingId)
			level.SetBillboardProgress(mHoldRingId, best.HoldFraction());

		// Drive the reveal, then stop touching it.
		int age = level.maptime - mBornTic;
		if (age <= REVEAL_TICS && mProgressIds.Size() > 0)
		{
			double t = clamp(double(age) / double(REVEAL_TICS), 0.0, 1.0);
			t = 1.0 - (1.0 - t) * (1.0 - t);          // ease out
			for (int i = 0; i < mProgressIds.Size(); i++)
				level.SetBillboardProgress(mProgressIds[i], t);
		}
	}

	private void Build(RS_RarityToken tok, PlayerPawn pawn)
	{
		let p = tok.mPayload;
		let w = tok.TargetWeapon(pawn);
		Color tierCol = RS_TierPalette.RGB(p.mTier);

		// --- two planes: A BLACK FIELD IN A TIER-COLOURED BORDER -----
		//
		// The first version tinted the whole FIELD with the tier colour at
		// low alpha. That fails twice over. A wash behind text eats the
		// contrast the text needs -- red "worse" numbers on a red-tinted
		// Cursed card, green "better" numbers on a green Common one, and
		// the one thing the card exists to say goes quiet. And it makes
		// the tier a MOOD rather than a fact: a 16% tint is hard to name
		// from across a room, where a hard border is unmistakable.
		//
		// So the rarity moves to the EDGE and the field goes black. Both
		// planes are the same two quads as before, just swapped: the tier
		// plate sits further out at full size, the black plate is inset in
		// front of it, and the strip of tier colour left showing around
		// the black IS the border. Two quads, no frame graphic, nothing to
		// keep in sync.
		//
		// ALPHA GOES THROUGH SetBillboardAlpha, NOT THROUGH THE COLOUR --
		// ProcessBillboard does `ThingColor.a = 255` and throws the
		// colour's alpha away.

		int borderId = Put(0, 0, HALF_W, HALF_H, LevelLocals.BB_PANEL, 0,
			tierCol, "", Z_SHELL);
		if (borderId) level.SetBillboardAlpha(borderId, 0.95);

		int faceId = Put(0, 0, HALF_W - BORDER, HALF_H - BORDER,
			LevelLocals.BB_PANEL, 0, Color(255, 6, 7, 10), "", Z_FACE);
		if (faceId) level.SetBillboardAlpha(faceId, 0.94);

		// =============================================================
		// NOTHING BELOW IS PLACED. IT FLOWS.
		//
		// This layout was hand-placed offsets three times running and it
		// walked out of the box every time -- the header floating above
		// the shell, VELOCITY printed on the floor beneath it, rows
		// landing on top of the footer. Every fix was the same fix, done
		// again with better numbers, and it kept failing for the same
		// reason: the card's size is a SLIDER now, and offsets are only
		// correct for the one size they were measured against. Change
		// Half Height by two and the whole composition is wrong, in play,
		// with nothing on screen saying so.
		//
		// So there are no coordinates here at all. Two cursors: one walks
		// DOWN from the top inner edge, one walks UP from the bottom, and
		// each element takes its own height plus a gap out of whichever
		// it belongs to. Whatever is left over in the middle is the band
		// the stat rows divide between themselves -- so the rows size
		// THEMSELVES from the space that happens to remain.
		//
		// Two consequences worth stating. Elements cannot collide,
		// because each one consumes the space it occupies. And the card
		// cannot overflow, because the only thing that ever grows is the
        // middle band, and it grows into space that is by definition
		// unused. Both hold at any Half Width and Half Height.
		// =============================================================
		// NOT `W`. ZScript identifiers are CASE-INSENSITIVE, so `W` is the
		// same name as the `w` three lines up -- the weapon -- and every
		// `cardW * 0.74` below became "RS_Weapon times a double".
		double cardW = HALF_W;
		FlowReset();

		// --- header: the RARITY is the headline, the weapon names it ---
		//
		// "DESIGNER" over "Super Shotgun", not "SSG DESIGNER". The token
		// IS a rarity -- that is the whole of what it is -- and the tag
		// only says which weapon it fits. Two practical reasons beyond
		// the hierarchy: a compound string on a segment display shrinks
		// to fit the panel width and stops being legible, and a NAME
		// wants a real typeface, which is the same reason the stat
		// labels below are BB_TEXT rather than segments.
		int hid = Put(0, FlowDown(LINE() * 2.2, 0.45), cardW * 0.74, LINE() * 2.2,
			LevelLocals.BB_SEGMENT, 0, tierCol,
			RS_Rarity.TierWord(p.mTier).MakeUpper());
		if (hid)
		{
			level.SetBillboardGlow(hid, 0.6, 0.8);
			mProgressIds.Push(hid);
		}

		// The tag wears the rarity too. Rarity and weapon are ONE fact --
		// "an Uncommon SMG" -- and splitting them across a lit headline
		// and a grey subtitle read as two unrelated lines. Now the border,
		// the headline and the name all carry the same hue, and the only
		// things on the card that are NOT tier-coloured are the ones
		// saying something else: the hand, and better/worse.
		Put(0, FlowDown(LINE() * 1.3, 0.55), cardW * 0.78, LINE() * 1.3,
			LevelLocals.BB_TEXT, 0, tierCol, p.mWeaponTag);

		// The tag one row up already names the weapon, so this does not
		// repeat it -- it just says what to do about it. Centred in the
		// whole remaining space rather than flowed, because it is the
		// only thing left on the card.
		if (!w)
		{
			Put(0, FlowMiddle(), cardW * 0.7, LINE() * 1.4, LevelLocals.BB_TEXT, 0,
				Color(255, 150, 148, 158), "SWITCH TO IT");
			return;
		}

		// --- which hand, in the sheet rails' own two colours ---------
		bool off  = w.bOffhandWeapon;
		bool side = (w.Tier >= p.mTier);
		int  locks = w.CurseCount();

		// Off-centre only when SIDEGRADE needs the other half. Two chips
		// stacked would cost a whole row out of a budget that has none;
		// side by side they read as one line of status.
		bool pair  = side || locks > 0;
		double chipY = FlowDown(LINE() * 1.0, 0.5);

		Put(pair ? -cardW * 0.28 : 0.0, chipY, cardW * 0.24, LINE() * 1.0,
			LevelLocals.BB_TEXT, 0,
			off ? Color(255, 51, 200, 255) : Color(255, 255, 122, 51),
			off ? "OFFHAND" : "MAINHAND");

		// A token at or below your rarity keeps going -- it cannot demote
		// you, so the only question is whether its roll beats the roll this
		// gun originally got, and the rows below answer that in green and
		// red. The chip says so and gets out of the way.
		if (side)
			Put(cardW * 0.28, chipY, cardW * 0.24, LINE() * 1.0, LevelLocals.BB_TEXT, 0,
				Color(255, 150, 148, 142), "SIDEGRADE");
		else if (locks > 0)
			Put(cardW * 0.28, chipY, cardW * 0.24, LINE() * 1.0, LevelLocals.BB_TEXT, 0,
				Color(255, 235, 60, 80), string.format("%d LOCKED", locks));

		Rule(FlowDown(LINE() * 0.1, 0.7), tierCol);

		// --- THE BOTTOM, BUILT FIRST -------------------------------
		//
		// The footer flows UP from the bottom edge before the middle is
		// touched, so the space the stat rows get is whatever genuinely
		// remains after both ends have taken theirs. Building it in
		// reading order instead would mean guessing how much to leave.
		int seals = p.SealsLeft();
		int bits  = pawn.CountInv("RS_Bit_Curse");
		int gold  = p.DenyGold();

		// The hold, and what it is worth. Under the tap line at half the
		// weight, because it is the option you take when the one above it
		// is not worth taking. Zero is stated rather than hidden -- "0
		// GOLD" is exactly what a player who already spent bits needs.
		Put(0, FlowUp(LINE() * 0.6, 0.4), cardW * 0.82, LINE() * 0.6,
			LevelLocals.BB_TEXT, 0,
			gold > 0 ? Color(255, 128, 122, 104) : Color(255, 112, 96, 96),
			string.format("HOLD - BREAK FOR %d GOLD", gold));

		// --- THE FOOTER SAYS WHAT THE NEXT PRESS DOES ---------------
		//
		// This is what makes overloading USE safe. One button does three
		// jobs, and the player never has to remember which -- the line
		// they are already reading names the next one.
		double fy = FlowUp(LINE() * 1.25, 0.6);

		if (!w.CanAcceptImprint(p.mTier))
			Put(0, fy, cardW * 0.72, LINE() * 1.25, LevelLocals.BB_TEXT, 0,
				Color(255, 235, 60, 80),
				string.format("LIFT %d TO TAKE THIS", locks));
		else if (seals > 0 && bits >= p.mSealCost)
			Put(0, fy, cardW * 0.78, LINE() * 1.25, LevelLocals.BB_TEXT, 0,
				Color(255, 236, 188, 70),
				string.format("[ BREAK SEAL - %d BITS ]", p.mSealCost));
		else if (seals > 0)
			Put(0, fy, cardW * 0.78, LINE() * 1.15, LevelLocals.BB_TEXT, 0,
				Color(255, 176, 104, 92),
				string.format("NEED %d BITS - HAVE %d", p.mSealCost, bits));
		else
			Put(0, fy, cardW * 0.34, LINE() * 1.25, LevelLocals.BB_TEXT, 0,
				Color(255, 236, 188, 70), "[ USE ]");

		// The hold ring sits ON the footer line, in the left margin the
		// centred text does not use, so it costs no vertical space at
		// all. Progress is driven per tic from the token rather than
		// rebuilt, so this is the only chance to keep its handle.
		mHoldRingId = Put(-cardW * 0.80, fy, LINE() * 1.1, LINE() * 1.1,
			LevelLocals.BB_RING, 0, Color(255, 236, 188, 70));
		if (mHoldRingId) level.SetBillboardProgress(mHoldRingId, 0.0);

		Rule(FlowUp(LINE() * 0.1, 0.7), tierCol);

		// --- THE MIDDLE: whatever is left, divided ------------------
		//
		// The rows do not assume a height, they take a third of the band
		// that survived both cursors. That is the whole reason the card
		// cannot overflow: the only thing that grows is this, and it
		// grows into space nothing else claimed.
		double band  = FlowLeft();
		double mid   = FlowMiddle();
		double pitch = band / 3.0;
		double rowHH = pitch * 0.38;

		// The socket badge shares the band rather than sitting above the
		// rows -- it owns the left third, they own the right half. Sized
		// off the engine's own WG13 ratio: halfW = halfH * 0.60, plus 0.42
		// per digit.
		//
		// max() mirrors ApplyTo: a sidegrade leaves sockets alone, so the
		// badge must read your CURRENT count, not the token's, or the
		// headline promises a socket the apply will not hand over.
		int sockNext = RS_Roll.SocketsForTier(max(w.Tier, p.mTier));
		double bh = min(band * 0.30, LINE() * 3.0);
		double bw = bh * (0.60 + 0.42);
		int bid = Put(-cardW * 0.70, mid + pitch * 0.30, bw, bh,
			LevelLocals.BB_WG13, sockNext,
			sockNext > w.GunBonaiSockets ? Color(255, 40, 255, 60)
			                             : Color(255, 130, 130, 140));
		if (bid) mProgressIds.Push(bid);

		Put(-cardW * 0.28, mid + pitch * 0.30, cardW * 0.22, LINE() * 0.85,
			LevelLocals.BB_TEXT, 0, Color(255, 168, 166, 158), "SOCKETS");
		Put(-cardW * 0.28, mid - pitch * 0.55, cardW * 0.22, LINE() * 0.75,
			LevelLocals.BB_TEXT, 0, Color(255, 124, 124, 134),
			string.format("%d now", w.GunBonaiSockets));

		// A LOCKED STAT IS MASKED, NOT MISSING, and the card is no longer
		// refused outright.
		//
		// The card used to stop dead on "2 STATS LOCKED" and show nothing
		// else, which got the mechanic backwards. A lock is not a wall,
		// it is a PRICE: cursebits drop off kills and buy a lift on the
		// weapon sheet (RS_Curses.zs:415, RS_Screens.zs:1043). Hiding the
		// whole offer meant you could not tell whether a token was worth
		// the bits you would have to spend to take it -- which is the one
		// decision this card exists to support.
		//
		// So every row draws. The locked ones show the label and a mask
		// where their numbers would be: you know a stat is on offer, you
		// know it is behind a lock, and you do not know which way it
		// moves until you pay. Owner's read, and it is the better
		// mechanic -- the curse is fog, not a fence.
		double ry = mid + pitch;
		Row(ry, rowHH, "DAMAGE",   w.DamagePerShot, p.mDamagePerShot + w.EarnedDamage(),
			w.IsStatCursed("damage"),   p.IsHidden(RS_RarityPayload.SEAL_DAMAGE));   ry -= pitch;
		Row(ry, rowHH, "ACCURACY", int(w.Accuracy), int(p.mAccuracy + w.EarnedAccuracy()),
			w.IsStatCursed("accuracy"), p.IsHidden(RS_RarityPayload.SEAL_ACCURACY)); ry -= pitch;
		Row(ry, rowHH, "VELOCITY", int(w.Velocity), int(p.mVelocity + w.EarnedVelocity()),
			w.IsStatCursed("velocity"), p.IsHidden(RS_RarityPayload.SEAL_VELOCITY));
	}

	// A hairline. Just a panel 0.35 tall -- one shape rather than a
	// second graphic to keep in sync.
	private void Rule(double y, color c)
	{
		// Same alpha rule as the planes: the colour's alpha is discarded,
		// so a "half-strength" rule drew at full strength.
		int id = Put(0, y, HALF_W * 0.84, LINE() * 0.1, LevelLocals.BB_PANEL, 0, c);
		if (id) level.SetBillboardAlpha(id, 0.47);
	}

	// Label left, the two numbers right, the arrow carrying the verdict:
	// green a gain, red a loss, grey a wash. Improvement, lateral move,
	// or calculated tradeoff -- one row at a time, which is the owner's
	// own framing and the reason the panel exists at all.
	// hh is handed in rather than assumed: the rows divide whatever
	// band survived the two cursors, so their size is a result of the
	// layout instead of an input to it.
	private void Row(double y, double hh, string label, int now, int after,
		bool locked = false, bool hidden = false)
	{
		// TWO WAYS A ROW GOES DARK, and they are not the same thing.
		//
		//   LOCKED -- your GUN's stat is cursed. Both numbers go, because
		//   the lock hides what the stat IS as well as what it would
		//   become; "41 > ???" would leak half of what it withholds.
		//   Lifted at the weapon sheet.
		//
		//   SEALED -- this DROP's number is hidden. Your current value
		//   still shows, because there is nothing secret about the gun
		//   you are holding -- only the offer is unknown. Opened here,
		//   for bits.
		//
		// Locked wins when both apply: if you cannot see your own number
		// there is nothing to compare an opened seal against, so paying
		// to open one would buy you half a sentence.
		if (locked)
		{
			Put(HALF_W * 0.24, y, HALF_W * 0.22, hh * 0.9, LevelLocals.BB_TEXT, 0,
				Color(255, 120, 100, 104), label);
			Put(HALF_W * 0.74, y, HALF_W * 0.24, hh, LevelLocals.BB_TEXT, 0,
				Color(255, 190, 62, 78), "-- LOCKED --");
			return;
		}

		if (hidden)
		{
			Put(HALF_W * 0.24, y, HALF_W * 0.22, hh * 0.9, LevelLocals.BB_TEXT, 0,
				Color(255, 168, 166, 158), label);
			Put(HALF_W * 0.60, y, HALF_W * 0.11, hh, LevelLocals.BB_SEGMENT, now,
				Color(255, 128, 128, 138));
			Put(HALF_W * 0.74, y, HALF_W * 0.045, hh * 0.8, LevelLocals.BB_TEXT, 0,
				Color(255, 150, 130, 190), ">");
			Put(HALF_W * 0.88, y, HALF_W * 0.11, hh * 0.9, LevelLocals.BB_TEXT, 0,
				Color(255, 176, 140, 236), "SEALED");
			return;
		}

		Color c = (after > now) ? Color(255, 74, 222, 128)
		        : (after < now) ? Color(255, 240,  80, 110)
		                        : Color(255, 118, 118, 128);

		Put(HALF_W * 0.24, y, HALF_W * 0.22, hh * 0.9, LevelLocals.BB_TEXT, 0,
			Color(255, 168, 166, 158), label);
		Put(HALF_W * 0.60, y, HALF_W * 0.11, hh, LevelLocals.BB_SEGMENT, now,
			Color(255, 128, 128, 138));
		Put(HALF_W * 0.74, y, HALF_W * 0.045, hh * 0.8, LevelLocals.BB_TEXT, 0, c, ">");
		int aid = Put(HALF_W * 0.88, y, HALF_W * 0.11, hh, LevelLocals.BB_SEGMENT, after, c);
		if (aid) mProgressIds.Push(aid);
	}
}
