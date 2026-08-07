// =====================================================================
// RS_WeaponDiag -- disposable. Watches the player's weapon and HUD
// state and prints ONLY WHEN SOMETHING CHANGES, for the first ~4
// seconds after spawn.
//
// Change-only on purpose. The symptom is "everything draws correctly,
// then a second later it is all gone" -- so a per-tic dump buries the
// one interesting tic in 140 identical lines. This prints a line at
// spawn, then a line every time any watched value moves, so the log
// reads as a short list of events and the moment things vanish is
// immediately visible with its tic number attached.
//
// Watched, and why each one:
//   Ready / Offhand   -- did a hand get cleared or repointed?
//   Pending           -- did something request a switch?
//   PSP_WEAPON / PSP_OFFHANDWEAPON -- did the drawn layer get
//                        destroyed? (FindPSprite: read-only. GetPSprite
//                        CREATES the layer and would manufacture the
//                        very thing being measured.)
//   health            -- the vanilla status bar draws this; if the HUD
//                        dies WITH health, the player state itself is
//                        the suspect, not the weapons.
//   screenblocks      -- >11 hides the GunBonsai HUD *and* changes the
//                        status bar. One value that would take the
//                        whole screen down at once.
//   ReadyWeapon owner -- if the weapon still exists but is no longer
//                        owned by this player, it was taken away.
//
// Disposable -- delete this file, its include line and its MAPINFO
// name when the question is settled.
// =====================================================================
class RS_WeaponDiag : EventHandler
{
	int  mTicks;
	bool mHavePrev;

	string mPrevReady, mPrevOffhand, mPrevPending;
	bool   mPrevMainPsp, mPrevOffPsp;
	int    mPrevHealth, mPrevBlocks;
	bool   mPrevOwned;

	const MAX_TICKS = 140;   // ~4 seconds at 35 tics/sec

	// --- render-pass watchdog ------------------------------------------
	// Handlers' RenderOverlay run in MAPINFO registration order, and this
	// handler is LAST. So if a handler ahead of us throws inside its own
	// RenderOverlay, ours may simply stop being called -- the whole HUD
	// disappears at once and NOTHING is printed, because the abort is not
	// a script error the log reports.
	//
	// That is the one mechanism that explains "every HUD element vanishes
	// together while the game keeps running", and nothing had ever
	// instrumented it. Counting frames here and checking the count from
	// WorldTick (which is a separate pass, and demonstrably still running)
	// turns a silent death into a printed line.
	// A HEARTBEAT, not a counter -- and that is forced, not a style
	// choice. RenderOverlay is `ui` scope and a handler's fields are
	// `play`; ui cannot WRITE play state ("Expression must be a
	// modifiable value"). So the render pass cannot tick a shared counter
	// for WorldTick to inspect. It can, however, READ play state and it
	// can print. So it prints its own heartbeat once a second.
	//
	// Read the log this way: if the `render alive` lines stop while the
	// state lines keep coming, the render pass died while the tick pass
	// lived -- i.e. a handler registered ahead of this one is aborting
	// inside its own render hook, silently, which is the one mechanism
	// that takes every HUD element down at once.
	ui int mLastBeatSec;

	override void RenderOverlay(RenderEvent e)
	{
		if (!level) return;
		int sec = level.time / 35;
		if (sec == mLastBeatSec) return;
		mLastBeatSec = sec;
		if (sec <= 5)
			Console.Printf("RS_DIAG: render alive, t=%d", level.time);
	}

	// The pawn itself being swapped out would also take everything down
	// at once. Cheap to rule in or out.
	Actor mPrevPawn;

	static string WeaponName(Weapon w)
	{
		if (!w) return "NONE";
		return w.GetClassName() .. "";
	}

	static string PendingName(PlayerInfo p)
	{
		if (p.PendingWeapon == WP_NOCHANGE) return "NOCHANGE";
		if (!p.PendingWeapon) return "NONE";
		return p.PendingWeapon.GetClassName() .. "";
	}

	// THE SMOKING-GUN HOOK. If the HUD, the models and the ammo all vanish
	// together while the player is alive, the single explanation that
	// covers all of it at once is that the weapons themselves were
	// DESTROYED. This fires the moment any actor is destroyed, so a
	// player-owned weapon dying shows up here with a tic number -- and
	// whatever line of the log sits next to it is the thing that did it.
	//
	// Deliberately not filtered to the console player's weapons only: a
	// weapon whose owner was already cleared before destruction would be
	// invisible to that filter, and that is exactly the case worth
	// catching.
	override void WorldThingDestroyed(WorldEvent e)
	{
		if (mTicks >= MAX_TICKS) return;
		if (!e.Thing) return;

		let w = Weapon(e.Thing);
		if (!w) return;

		PlayerInfo p = players[consoleplayer];
		bool mine = p && p.mo && w.owner == p.mo;
		bool wasHeld = p && (w == p.ReadyWeapon || w == p.OffhandWeapon);

		// An unowned weapon actor being destroyed is ordinary -- that is
		// what every pedestal swap and every pickup does. Only report one
		// that belongs to, or is currently held by, the player.
		if (!mine && !wasHeld) return;

		Console.Printf("RS_DIAG t%d: *** WEAPON DESTROYED: %s (mine=%s held=%s) ***",
			mTicks, w.GetClassName() .. "",
			mine ? "yes" : "no", wasHeld ? "YES" : "no");
	}

	override void WorldTick()
	{
		if (mTicks >= MAX_TICKS) return;

		PlayerInfo p = players[consoleplayer];
		if (!p || !p.mo) return;

		mTicks++;

		string ready   = WeaponName(p.ReadyWeapon);
		string offhand = WeaponName(p.OffhandWeapon);
		string pending = PendingName(p);
		bool   mainPsp = (p.FindPSprite(PSP_WEAPON) != null);
		bool   offPsp  = (p.FindPSprite(PSP_OFFHANDWEAPON) != null);
		int    health  = p.mo.health;
		bool   owned   = (p.ReadyWeapon && p.ReadyWeapon.owner == p.mo);

		let bcv = CVar.FindCVar("screenblocks");
		int blocks = bcv ? bcv.GetInt() : -1;

		bool changed =
			   !mHavePrev
			|| ready   != mPrevReady
			|| offhand != mPrevOffhand
			|| pending != mPrevPending
			|| mainPsp != mPrevMainPsp
			|| offPsp  != mPrevOffPsp
			|| health  != mPrevHealth
			|| blocks  != mPrevBlocks
			|| owned   != mPrevOwned;

		if (changed)
		{
			Console.Printf(
				"RS_DIAG t%d: Ready=%s Off=%s Pend=%s | psp main=%s off=%s | hp=%d blocks=%d ownedByMe=%s",
				mTicks, ready, offhand, pending,
				mainPsp ? "yes" : "GONE",
				offPsp  ? "yes" : "GONE",
				health, blocks,
				owned ? "yes" : "NO");
		}

		// PAWN SWAP. A replaced player pawn takes every HUD element with
		// it at once, which fits the symptom exactly and costs one
		// comparison to rule out.
		if (mHavePrev && p.mo != mPrevPawn)
		{
			Console.Printf("RS_DIAG t%d: *** PLAYER PAWN CHANGED: %s -> %s ***",
				mTicks,
				mPrevPawn ? (mPrevPawn.GetClassName() .. "") : "none",
				p.mo.GetClassName() .. "");
		}
		mPrevPawn = p.mo;

		mPrevReady   = ready;
		mPrevOffhand = offhand;
		mPrevPending = pending;
		mPrevMainPsp = mainPsp;
		mPrevOffPsp  = offPsp;
		mPrevHealth  = health;
		mPrevBlocks  = blocks;
		mPrevOwned   = owned;
		mHavePrev    = true;
	}
}
