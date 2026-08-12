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
// KEEP-BETTER, AND WHY IT IS NOT OPTIONAL HERE
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
// So stats are applied KEEP-BETTER, field by field: a token can only
// raise a number, never lower one. Tier and sockets are set outright,
// because those are the token's whole point. Levels and affixes are
// untouched -- they live in GunBonsai's bag, not in the weapon's stats.
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
// play. This keeps its two good ideas -- the donor and keep-better --
// and drops the rest: the second weighted ladder, the eight drop-weight
// sliders, the separate tier bonus, the preview screen.
//
// And on the other side: until 2026-08-11 the ONLY thing in the tree
// that could raise a tier was a side effect of lifting a curse. A clean
// weapon could never climb at all. That block is gone; this is what was
// always supposed to be there.
//
// THE CURSE RULE STILL HOLDS, and matters more now: a cursed weapon
// cannot take a token. RS_Weapon.CanAcceptImprint is the gate, and it
// survived the purge intact along with its "The curse refuses it"
// message. Lifting a curse no longer hands out a free tier -- it
// unblocks one you have to go and earn.
// =====================================================================

class RS_Rarity
{
	const START_TIER = VRT_Basic;

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
		return p;
	}

	// Right weapon, and is it actually an upgrade?
	bool Matches(RS_Weapon w) const
	{
		return w && mWeaponClass && w.GetClass() == mWeaponClass;
	}

	bool IsUpgradeFor(RS_Weapon w) const
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
		if (w.Tier >= mTier)
		{
			Announce(w, string.format("\c[Gold]Already %s.\c- That token is only %s.",
				RS_Rarity.TierWord(w.Tier), RS_Rarity.TierWord(mTier)));
			return false;
		}
		// The one interesting restriction, and the reason curses still
		// bite now that lifting one no longer hands out a free tier.
		if (!w.CanAcceptImprint(mTier))
		{
			Announce(w, "\c[Red]The curse refuses it.\c- Lift a curse before this weapon can take a higher rarity.");
			return false;
		}

		// KEEP-BETTER. A token raises a number or leaves it alone; it
		// never lowers one. Without this an Uncommon roll could land
		// under a well-levelled Basic and the elite kill would be a
		// downgrade.
		if (mFilled)
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

		// TIER, then sockets FROM it -- read through RS_Roll rather than
		// hardcoded, so the socket table has one owner and cannot drift.
		// Same argument Promote() makes for itself.
		w.Tier            = mTier;
		w.GunBonaiSockets = RS_Roll.SocketsForTier(w.Tier);

		Announce(w, string.format("\c[Gold]%s is now %s.\c- %d socket%s.",
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
