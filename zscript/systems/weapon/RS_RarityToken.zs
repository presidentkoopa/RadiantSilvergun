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

class RS_RarityToken : Actor
{
	RS_RarityPayload mPayload;

	// So the readout is printed once on approach rather than every tic,
	// and again if you switch weapons while standing over it.
	private Class<Actor> mLastShown;
	private int mNextShowTic;

	Default
	{
		+USESPECIAL          // Used() fires on the use key
		+NOGRAVITY
		+NOBLOCKMAP
		+DONTSPLASH
		+NOTELEPORT
		Radius 20;
		Height 24;
		Scale 0.7;
	}

	States
	{
	Spawn:
		BON1 ABCDCB 6 Bright;
		Loop;
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

	override bool Used(Actor user)
	{
		let pawn = PlayerPawn(user);
		if (!pawn || !mPayload) return false;

		let w = TargetWeapon(pawn);
		if (!w)
		{
			if (pawn.player == players[consoleplayer])
				Console.Printf("\c[Red]Hold your %s to apply this.\c-", mPayload.mWeaponTag);
			return false;
		}

		// ApplyTo says its own no, with its own reason.
		if (!mPayload.ApplyTo(w)) return false;

		A_StartSound("misc/i_pkup", CHAN_AUTO);
		Destroy();
		return true;
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
	const AHEAD  = 46.0;
	const UP     = -1.0;
	const REACH  = 128.0;

	const HALF_W = 31.0;
	const HALF_H = 22.0;
	const ROW_H  =  4.4;

	// Plane offsets. Bigger X is further away.
	const Z_SHELL = 1.2;
	const Z_FACE  = 0.6;

	const REVEAL_TICS = 10;

	private Array<int> mIds;
	private Array<int> mProgressIds;    // the subset that animates in
	private RS_RarityToken mShownFor;
	private string mSig;
	private int mBornTic;

	private void Clear()
	{
		for (int i = 0; i < mIds.Size(); i++)
			level.RemoveBillboard(mIds[i]);
		mIds.Clear();
		mProgressIds.Clear();
		mShownFor = null;
		mSig = "";
	}

	// One door for every element, so parking and flags cannot drift.
	private int Put(double right, double up, double w, double h,
		int payload, int data, color col, string text = "", double depth = 0)
	{
		int id = level.AddBillboardPersistent(
			(AHEAD + depth, right, UP + up), w, h,
			0, 0, BBF_FIXED,
			payload, data, col,
			BBFL_PERSISTENT | BBFL_VIEWLOCKED | BBFL_NOHIT, 0, text);
		if (id) mIds.Push(id);
		return id;
	}

	override void WorldTick()
	{
		let pawn = players[consoleplayer].mo;
		if (!pawn || pawn.health <= 0) { Clear(); return; }

		RS_RarityToken best = null;
		double bestD = REACH;
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
		let w = best.TargetWeapon(PlayerPawn(pawn));
		string sig = best.mPayload.mWeaponTag .. "|" .. best.mPayload.mTier
			.. "|" .. (w ? w.GetClassName() : "none")
			.. "|" .. (w ? w.Tier : -1) .. "|" .. (w ? w.DamagePerShot : -1);

		if (best != mShownFor || sig != mSig)
		{
			Clear();
			mShownFor = best;
			mSig      = sig;
			mBornTic  = level.maptime;
			Build(best, PlayerPawn(pawn));
		}

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

		// --- three planes -------------------------------------------
		Put(0, 0, HALF_W, HALF_H, BB_PANEL, 0, Color(232, 9, 10, 14), "", Z_SHELL);
		Put(0, 0, HALF_W - 1.6, HALF_H - 1.4, BB_PANEL, 0,
			Color(46, tierCol.r, tierCol.g, tierCol.b), "", Z_FACE);

		double y = HALF_H - 5.4;

		// --- header: the token, as segments, lit ---------------------
		int hid = Put(0, y, HALF_W - 5.0, 3.2, BB_SEGMENT, 0, tierCol,
			(p.mWeaponTag .. " " .. RS_Rarity.TierWord(p.mTier)).MakeUpper());
		if (hid)
		{
			level.SetBillboardGlow(hid, 0.6, 0.75);
			mProgressIds.Push(hid);
		}
		y -= 4.6;

		if (!w)
		{
			Put(0, y, HALF_W - 6, 2.3, BB_TEXT, 0, Color(255, 132, 130, 140),
				"hold your " .. p.mWeaponTag);
			return;
		}

		// --- which hand, in the sheet rails' own two colours ---------
		bool off = w.bOffhandWeapon;
		Put(0, y, 13.0, 2.0, BB_TEXT, 0,
			off ? Color(255, 51, 200, 255) : Color(255, 255, 122, 51),
			off ? "OFFHAND" : "MAINHAND");
		y -= 3.4;

		Rule(y, tierCol); y -= 3.6;

		if (w.Tier >= p.mTier)
		{
			Put(0, y - 3, HALF_W - 6, 2.6, BB_TEXT, 0, Color(255, 132, 130, 140),
				"already " .. RS_Rarity.TierWord(w.Tier));
			return;
		}
		if (!w.CanAcceptImprint(p.mTier))
		{
			Put(0, y - 3, HALF_W - 6, 2.6, BB_TEXT, 0, Color(255, 210, 45, 65),
				"THE CURSE REFUSES IT");
			return;
		}

		// --- THE HEADLINE: sockets, as a lozenge --------------------
		// Rarity gates affixes and sockets ARE that gate, so this is the
		// number the panel is actually about. Sized off the engine's own
		// WG13 ratio: halfW = halfH * (0.60 + digits * 0.42).
		int sockNext = RS_Roll.SocketsForTier(p.mTier);
		double bh = 5.2;
		double bw = bh * (0.60 + 0.42);
		int bid = Put(-HALF_W + 11.0, y - 4.4, bw, bh, BB_WG13, sockNext,
			Color(255, 40, 255, 60));
		if (bid) mProgressIds.Push(bid);

		Put(-HALF_W + 24.0, y - 2.4, 8.0, 1.9, BB_TEXT, 0,
			Color(255, 150, 148, 142), "SOCKETS");
		Put(-HALF_W + 24.5, y - 6.2, 7.0, 2.1, BB_TEXT, 0,
			Color(255, 110, 110, 120),
			string.format("%d now", w.GunBonaiSockets));

		// --- supporting rows ----------------------------------------
		double ry = y - 1.0;
		Row(ry, "DAMAGE",   w.DamagePerShot, p.mDamagePerShot + w.EarnedDamage());   ry -= ROW_H;
		Row(ry, "ACCURACY", int(w.Accuracy), int(p.mAccuracy + w.EarnedAccuracy())); ry -= ROW_H;
		Row(ry, "VELOCITY", int(w.Velocity), int(p.mVelocity + w.EarnedVelocity()));

		double fy = -HALF_H + 6.4;
		Rule(fy + 3.4, tierCol);
		Put(0, fy, 9.5, 2.7, BB_TEXT, 0, Color(255, 216, 168, 56), "[ USE ]");
	}

	// A hairline. Just a panel 0.35 tall -- one shape rather than a
	// second graphic to keep in sync.
	private void Rule(double y, color c)
	{
		Put(0, y, HALF_W - 6.0, 0.35, BB_PANEL, 0,
			Color(120, c.r, c.g, c.b));
	}

	// Label left, the two numbers right, the arrow carrying the verdict:
	// green a gain, red a loss, grey a wash. Improvement, lateral move,
	// or calculated tradeoff -- one row at a time, which is the owner's
	// own framing and the reason the panel exists at all.
	private void Row(double y, string label, int now, int after)
	{
		Color c = (after > now) ? Color(255, 74, 222, 128)
		        : (after < now) ? Color(255, 240,  80, 110)
		                        : Color(255, 118, 118, 128);

		Put(HALF_W - 25.0, y, 8.5, 1.85, BB_TEXT, 0,
			Color(255, 148, 146, 140), label);
		Put(HALF_W - 13.5, y, 3.6, 2.2, BB_SEGMENT, now,
			Color(255, 116, 116, 126));
		Put(HALF_W -  8.4, y, 1.5, 1.7, BB_TEXT, 0, c, ">");
		int aid = Put(HALF_W - 3.6, y, 3.6, 2.2, BB_SEGMENT, after, c);
		if (aid) mProgressIds.Push(aid);
	}
}
