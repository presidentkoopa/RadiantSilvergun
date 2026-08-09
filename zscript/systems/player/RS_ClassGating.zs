// =====================================================================
// RS_ClassGating -- one chokepoint, not per-weapon logic.
// ---------------------------------------------------------------------
// Every map-placed weapon pickup gets checked once, at the moment the
// map spawns it, against the player's chosen class. Before it's ever
// collidable, a Dual_X player has EVERY pickup that isn't already an
// owned copy of their own class weapon REPLACED WITH ANOTHER COPY OF
// THAT CLASS WEAPON -- play Dual_SMG and the pistol, revolver, rifle,
// shotgun, SSG, chaingun (and, per rs_dualclass_allowbigguns, plasma/
// rocket/BFG) pedestals all become SMG copies instead. This is now the
// primary way a Dual_X player's arsenal grows past the two copies
// (identity 1 mainhand, 4 offhand) granted at spawn -- see
// WorldThingSpawned's own comment for the fill order and the heavy-
// ordnance carve-out. Once all six identities are owned, a pedestal of
// this kind falls back to leaving reserve ammo instead of a pickup,
// which is what this file used to do for every mismatch, always.
//
// Player.StartItem grants and GiveInventory calls (monster drops,
// "Allow Big Guns", console give) never go through WorldThingSpawned, so
// this only ever touches actual floor pickups -- it can't clobber
// anything already handed to the player directly.
//
// This now catches ANY Weapon, not just RS_Weapon -- vanilla Doom's own
// Pistol/Shotgun/SuperShotgun/Chaingun/RocketLauncher/PlasmaRifle/
// BFG9000 pickups are never wrapped in this mod's own classes, so the
// old RS_Weapon-only cast never saw them at all. New RS_Weapon families
// need no new code here; the fill logic is keyed off the player's own
// VR_DualClassBase.GetMainhandClass(), not the pickup's type.
// =====================================================================

class RS_ClassGating : EventHandler
{
	// RE-ENTRANCY GUARD -- REBUILT 2026-08-07. Read this before touching it.
	//
	// This was a bool (`mFilling`) set immediately before every Actor.Spawn
	// and cleared immediately after, on the belief -- stated in this file
	// and repeated in RS_EliteDrop.zs -- that "Actor.Spawn fires
	// WorldThingSpawned AGAIN, synchronously." IT DOES NOT, and that is
	// why the freeze this guard was written to stop was never actually
	// fixed. Verified in the engine source at E:\UZDXREMA:
	//
	//   * WorldThingSpawned is fired from exactly one place --
	//     AActor::CallPostBeginPlay (src/playsim/p_mobj.cpp:5164-5167).
	//   * CallPostBeginPlay is reached only from the FRESH-THINKER pass
	//     (src/playsim/dthinker.cpp:602-611), driven by RunThinkers'
	//     do-while at dthinker.cpp:152-160, which keeps ticking fresh
	//     thinkers "until there are no new ones".
	//
	// So the event for anything we spawn arrives AFTER this handler has
	// returned and already cleared the flag. A boolean window cannot
	// possibly be open at delivery time, which made all three guards in
	// this project dead code:
	//
	//   1. the pedestal fill below -- replacement spawns, its own deferred
	//      event finds the same still-unowned gap, spawns another, forever
	//      inside one tic's fresh-thinker walk. The tic never ends: a hard
	//      freeze at map load on any Dual_X class near a weapon pickup.
	//   2. TryRandomBFG -- its output classes ARE its input set, so every
	//      reroll re-matches itself. Unbounded destroy+spawn until an
	//      allocation fails; this is the "could not malloc" crash.
	//   3. RS_EliteDrop's mSpawningDrop -- closed before the payload's
	//      event lands, so elite drops fed straight into (1).
	//
	// A REFERENCE survives deferred delivery where a boolean cannot, so
	// the guard is now a list of the actors this handler spawned. Each is
	// claimed exactly once, when its event finally arrives, and removed.
	// Sized-bounded by construction: one entry per spawn, one removal per
	// event, and WorldUnloaded clears the rest.
	Array<Actor> mOurSpawns;

	// Record an actor we just spawned so its deferred WorldThingSpawned
	// passes straight through. Call this at EVERY Actor.Spawn site that
	// can produce something this handler would otherwise re-process.
	void NoteOurSpawn(Actor a)
	{
		if (a) mOurSpawns.Push(a);
	}

	// True exactly once per noted actor -- the event it was waiting for.
	private bool ClaimOurSpawn(Actor a)
	{
		if (!a) return false;
		int i = mOurSpawns.Find(a);
		if (i == mOurSpawns.Size()) return false;
		mOurSpawns.Delete(i);
		return true;
	}

	override void WorldUnloaded(WorldEvent e)
	{
		super.WorldUnloaded(e);
		mOurSpawns.Clear();
	}

	// (IsGatedFamily() was removed 2026-08-07. It listed the seven
	// families the class system filters on and had ZERO callers -- the
	// real gate is `pc.GetFamily() == EVR_Family_None` in
	// WorldThingSpawned below, which tests the PLAYER's family, not the
	// pickup's. Its own comment called it "the ONE place that decides
	// gated-vs-not" and told future sessions to edit it there instead of
	// on 30+ weapon files; editing it would have done nothing at all.
	// RS_Roll.zs carried the same claim and has been corrected too.)

	// What a gated-out pickup leaves behind: reserve ammo for the class
	// you're actually playing. Taken from the Dual_X-owned weapons'
	// own Weapon.AmmoType1, not invented here -- RS_Pistol/RS_Revolver/
	// RS_Rifle/RS_SMG all draw Clip, RS_Shotgun/RS_SuperShotgun draw
	// VR_Shell, RS_Chaingun draws VR_ChaingunAmmo.
	static string AmmoForFamily(EVR_Family f)
	{
		if (f == EVR_Family_Pistol || f == EVR_Family_Revolver
		 || f == EVR_Family_Rifle  || f == EVR_Family_SMG)
			return "Clip";

		if (f == EVR_Family_Shotgun || f == EVR_Family_SuperShotgun)
			return "VR_Shell";

		if (f == EVR_Family_Chaingun)
			return "VR_ChaingunAmmo";

		// Not a gated family -- never reached, because the handler below
		// returns early on EVR_Family_None and only the seven gated
		// families can reach it. Empty means "leave nothing".
		return "";
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		super.WorldThingSpawned(e);

		// Our own spawn, arriving on a later tic through the same event it
		// was spawned from. A reference, not a time window -- see
		// mOurSpawns' declaration for the engine ordering that makes the
		// window approach impossible.
		if (ClaimOurSpawn(e.Thing)) return;

		// AN ELITE DROP'S PAYLOAD IS EXEMPT FROM BOTH PASSES BELOW.
		//
		// RS_WeaponDrop spawns a real class weapon into the world to be its
		// own marker. That spawn comes straight through here, so on any
		// Dual_X class the gating below destroyed four of the six possible
		// drops before Spawn() even returned -- silently, leaving a Clip on
		// the floor where the pedestal should have been. The Vanilla+ swap
		// above would eat it too.
		//
		// RECOGNISED BY STATE, NOT BY A FLAG (2026-08-07). This used to
		// read RS_PanelDropHandler.mSpawningDrop, a window opened around
		// the payload's Actor.Spawn and closed "immediately and
		// unconditionally" -- i.e. always shut by the time the deferred
		// event actually arrived, so the exemption never once applied and
		// every elite drop fed the fill loop below. The payload does not
		// need a flag to be identifiable: RS_WeaponDrop.Create sets
		// bSpecial=false and bNoInteraction=true on it BEFORE the event
		// fires, and no ordinary floor pickup is ever non-interactive.
		// That state is the exemption.
		if (e.Thing && e.Thing.bNoInteraction)
			return;

		// Vanilla+ Options world-spawn substitution -- runs first, on the
		// actual spawned thing, before class gating even looks at it. If
		// a swap fires, e.Thing gets destroyed and replaced; the original
		// never reaches the gating check below at all.
		//
		// GUARDED, and this one is not theoretical. Every swap in here
		// ends in Actor.Spawn, and TryRandomBFG's replacement is drawn
		// from the SAME three classes it matches on (RS_GH_Unmaker /
		// BFG10k / BFG9000), so its output always re-matches its own
		// input. Unguarded that is unbounded destroy+spawn: no error, no
		// crash, just memory consumed until an allocation fails.
		//
		// The handler is now passed IN so each swap can register the
		// actor it spawned (NoteOurSpawn) at the moment it creates it.
		// The old code set a boolean around this whole call because the
		// swaps live on a different class with static methods and could
		// not reach this handler's field -- but a boolean was never going
		// to survive until the deferred event arrived. Passing `self`
		// costs nothing and makes the guard work.
		// OWNERSHIP GUARD, AHEAD OF THE SWAP. Added 2026-08-07.
		//
		// TrySwapPair/TryRandomBFG match on the class NAME and a cvar, and
		// then call e.Thing.Destroy() -- they never ask whether anybody is
		// holding it. And a weapon handed straight into inventory DOES
		// arrive here: GiveInventory spawns a real actor, so its
		// WorldThingSpawned fires on the fresh-thinker pass with `owner`
		// already set (p_mobj.cpp:5164 via dthinker.cpp:602-611).
		//
		// So any RS_GH_Chainsaw / SSG / RocketLauncher / Plasma / Minigun /
		// Unmaker / BFG10k / BFG9000 that reached inventory by ANY route --
		// an elite drop taken, a card grant, a console give -- could be
		// deleted out of the player's hands and re-spawned on the floor at
		// their feet, on the tic after they got it.
		//
		// The gating pass below has always had this guard (see the cast a
		// few lines down); the swap pass ran in front of it without one.
		// The swaps are meant for things lying on the floor, which is
		// exactly what this checks.
		// Inventory(e.Thing).owner, not e.Thing.owner -- `owner` is
		// declared on Inventory, not on Actor, so the bare form is an
		// unknown identifier and the file will not compile. The cast is
		// also the right test on its own: a non-Inventory actor has no
		// owner to speak of and should fall through to the swap anyway.
		let asInv = Inventory(e.Thing);
		if (asInv && asInv.owner)
			return;

		bool swapped = RS_VanillaPlusSwaps.TrySwap(e, self);
		if (swapped)
			return;

		// BROAD CAST, ON PURPOSE. Vanilla Doom's own Pistol/Shotgun/
		// SuperShotgun/Chaingun/RocketLauncher/PlasmaRifle/BFG9000 are
		// never wrapped in this mod's own classes (verified: none of
		// zscript/weapons/rs_weapon declare `replaces`), so casting to
		// RS_Weapon here -- the old behaviour -- never saw them at all.
		// Weapon is the common ancestor of both (DoomWeapon : Weapon,
		// verified in the engine source), so this is the narrowest cast
		// that catches everything a pedestal can hold.
		//
		// Melee is exempt: there is no per-class melee identity ladder,
		// only Fist and its shared variants (RS_Fist.zs), which are the
		// same for every class and have nothing to fill.
		let wep = Weapon(e.Thing);
		if (!wep || wep.owner || wep.bMeleeWeapon)
			return;

		// =============================================================
		// A MONSTER'S OWN DROP IS NOT A PEDESTAL.
		//
		// THE CHECK IS DEFERRED A TIC, AND IT HAS TO BE. Corrected
		// 2026-08-07 after this shipped broken.
		//
		// The first version read `if (wep.bTossed) return;` RIGHT HERE,
		// inside WorldThingSpawned. That is a silent no-op, every single
		// time, because the engine has not set the flag yet:
		//
		//   inventory_util.zs:656   mo = Spawn(...)      <- event fires HERE
		//   inventory_util.zs:668   inv.bTossed = true;  <- flag set 12 lines later
		//
		// So bTossed is ALWAYS false when this event runs, the guard
		// always passed, and every weapon a monster dropped was converted
		// into the player's next missing class identity. Killing one
		// shotgunner handed over a permanent arsenal slot and the
		// six-weapon set completed itself off hitscanner corpses in the
		// first map -- which then made elites pay nothing, because
		// NextMissingIdentity had nothing left to return.
		//
		// It also defeated RS_NoMonsterDrops: that handler suppresses the
		// dropped item a tic later, but this code had already destroyed
		// it and spawned a replacement via Actor.Spawn, which carries no
		// bTossed, so the replacement sailed straight through.
		//
		// RS_NoMonsterDrops documents this exact engine ordering in its
		// own header and defers a tic BECAUSE of it. This now does the
		// same thing rather than repeating the mistake next door to the
		// file that explains it.
		// =============================================================
		mPendingFill.Push(wep);
		return;
	}

	// Weapons seen this tic, judged on the next one -- see the long note
	// above. Anything still here and NOT bTossed was placed by the map (or
	// by another mod) and is a legitimate fill candidate; anything bTossed
	// was dropped by a monster and is left alone for RS_NoMonsterDrops.
	private Array<Weapon> mPendingFill;

	override void WorldTick()
	{
		super.WorldTick();
		if (mPendingFill.Size() == 0) return;

		for (int i = 0; i < mPendingFill.Size(); i++)
		{
			let wep = mPendingFill[i];

			// May have been picked up, suppressed or destroyed inside its
			// own first tic.
			if (!wep || wep.bDestroyed) continue;

			// NOW the flag is real.
			if (wep.bTossed) continue;

			// Re-check the conditions that could have changed in a tic.
			if (wep.owner) continue;

			ResolveFill(wep);
		}
		mPendingFill.Clear();
	}

	// The fill itself, moved out of WorldThingSpawned unchanged apart from
	// taking its weapon as an argument.
	private void ResolveFill(Weapon wep)
	{

		// consoleplayer is deliberate, not a multiplayer oversight -- this
		// project is singleplayer/VR-only, confirmed with the dev.
		let pawn = players[consoleplayer].mo;
		if (!pawn)
			return;

		// Not a Dual_X class (Vanilla+, or no class system in play) --
		// let everything through untouched.
		let pc = VR_DualClassBase(pawn);
		if (!pc || pc.GetFamily() == EVR_Family_None)
			return;

		string mainhand = pc.GetMainhandClass();
		if (mainhand.Length() == 0)
			return;

		// -------------------------------------------------------------
		// THE HEAVY ORDNANCE CARVE-OUT IS GONE. Removed 2026-08-08 at
		// the owner's order ("remove 'allowbigguns'").
		//
		// Rocket launcher, plasma rifle and BFG used to be handed to
		// every class for free and skip the fill entirely. That is
		// incompatible with the tier ladder below, which reads the map
		// weapon you replaced to decide how good your class weapon is --
		// those three ARE the top three rungs, so exempting them made
		// Advanced, Designer and Prototype unreachable from map pickups.
		//
		// They now go through the same path as everything else.
		// -------------------------------------------------------------

		// -------------------------------------------------------------
		// THE FILL. Extra mainhand copies (2, 3) before extra offhand
		// copies (5, 6) -- the owner's specified order. 1 and 4 are
		// never targets: those are the spawn grant, not a gap.
		//
		// Sequential ifs, not a loop over an array: `static const TYPE
		// name[] = {...}` does not reliably resolve on this engine
		// build (see CLAUDE.md) -- found and fixed three times
		// elsewhere in this project already. Not worth a fourth.
		// -------------------------------------------------------------
		// SECOND, INDEPENDENT SAFETY NET against the fill loop.
		//
		// If this pickup is ALREADY one of the player's own identity
		// classes, there is nothing to convert -- leave it on the floor
		// and let them walk over it. This matters beyond tidiness: it is
		// what makes the fill idempotent. Even if a replacement's event
		// somehow reaches this point unclaimed, it now recognises itself
		// as already-correct and stops, instead of spawning another copy
		// of what it already is. Belt and braces, deliberately, because
		// the failure mode here is a frozen game rather than a wrong
		// number.
		string here = wep.GetClassName();
		if (here == mainhand
		 || here == mainhand .. "2" || here == mainhand .. "3"
		 || here == mainhand .. "4" || here == mainhand .. "5"
		 || here == mainhand .. "6")
			return;

		// THE TIER COMES FROM WHAT THE MAP PUT THERE. Read it BEFORE the
		// original is destroyed below -- see TierForMapWeapon.
		int mapTier = TierForMapWeapon(here);

		string gap = NextMissingIdentity(pawn, mainhand);
		if (gap != "")
		{
			let repl = Actor.Spawn(mainhand .. gap, wep.pos);
			// Register BEFORE anything else can run: this actor's own
			// WorldThingSpawned is already queued for the fresh-thinker
			// pass and must find itself claimed when it arrives.
			NoteOurSpawn(repl);
			if (repl)
				repl.angle = wep.angle;

			// Roll it at the tier the map earned. PostBeginPlay has
			// already rolled this weapon at Basic and captured THAT as
			// its promotion baseline, so the baseline has to be reset
			// and retaken or the ceiling stays anchored to a number the
			// player never sees -- the same trap RS_EliteDrop documents
			// at its own RollStats call.
			let rsw = RS_Weapon(repl);
			if (rsw)
			{
				rsw.ResetDamageBaseline();
				rsw.RollStats(mapTier);
				rsw.CaptureInitialDamageBaseline();
			}
			// Only consume the pedestal if we actually produced something
			// to stand in its place. Spawn() returns null for an abstract
			// class and prints one console line; destroying regardless
			// would silently delete the pickup and leave bare floor.
			if (repl)
				wep.Destroy();
			return;
		}

		// All six already owned. Leave reserve ammo instead of an empty
		// floor -- this is the old mismatch behaviour, unchanged, just
		// reached by a different condition now. Ammo classes are never
		// Weapon subclasses, so this one was never actually re-entrant
		// -- noted anyway, for the same reason the codebase avoids three
		// narrow guards where one consistent rule reads clearer.
		string ammo = AmmoForFamily(pc.GetFamily());
		if (ammo != "")
			NoteOurSpawn(Actor.Spawn(ammo, wep.pos, ALLOW_REPLACE));
		wep.Destroy();
	}

	// =================================================================
	// THE MAP DECIDES HOW GOOD YOUR CLASS WEAPON IS.
	//
	// Owner's design, 2026-08-08. When a map-placed weapon is converted
	// into one of your six, the tier it rolls at comes from WHAT IT WAS:
	//
	//     pistol, shotgun        ->  Common
	//     SSG, chaingun          ->  Uncommon
	//     rocket launcher        ->  Advanced
	//     plasma rifle           ->  Designer
	//     BFG                    ->  Prototype
	//
	// WHY THIS IS BETTER THAN ANY SLIDER WE COULD WRITE. Every Doom map
	// already escalates its weapons on purpose: pistols and shotguns
	// early and everywhere, SSG and chaingun as the mid-game step,
	// rockets when the fights get big, plasma usually behind something,
	// BFG late or hidden or earned. That ordering is a hand-authored
	// difficulty curve, present in every wad ever made and tested for
	// thirty years.
	//
	// Reading tier off it means the mod inherits the level designer's
	// pacing for free: a megawad that gates the BFG until MAP25 gates
	// your Prototype until MAP25, and a map that hands you plasma in the
	// first room hands you a Designer in the first room. No level
	// scaling, no per-wad tuning, and secrets start paying out in gear
	// rather than just ammo.
	//
	// Before this every map fill spawned at Basic -- flat, no variation,
	// nothing to find. This is the curve, not a rebalance of one.
	//
	// The six identities are NOT a ladder: VR_Rifle2 differs from
	// VR_Rifle only by name, slot and magazine. Which of the six you get
	// is just whichever gap is next. ALL the power is in this tier.
	//
	// Unknown weapon (another mod's, or something we do not recognise)
	// falls back to Common rather than to nothing -- an unrecognised
	// pickup should still be worth taking.
	// =================================================================
	static int TierForMapWeapon(Name cls)
	{
		switch (cls)
		{
			// --- Prototype: the map's best prize -------------------
			case 'BFG9000':
			case 'VR_BFG9000':
			case 'RS_GH_BFG9000':
			case 'RS_GH_BFG10k':
				return VRT_Prototype;

			// --- Designer -----------------------------------------
			case 'PlasmaRifle':
			case 'VR_PlasmaRifle':
			case 'RS_GH_Plasma':
			case 'RS_GH_Railgun':
				return VRT_Designer;

			// --- Advanced -----------------------------------------
			case 'RocketLauncher':
			case 'VR_RocketLauncher':
			case 'RS_GH_RocketLauncher':
			case 'RS_GH_GrenadeLauncher':
				return VRT_Advanced;

			// --- Uncommon: the mid-game step up -------------------
			case 'SuperShotgun':
			case 'VR_SuperShotgun':
			case 'RS_GH_SSG':
			case 'RS_GH_AssaultShotgun':
			case 'Chaingun':
			case 'VR_Chaingun':
			case 'RS_GH_Chaingun':
			case 'RS_GH_Minigun':
				return VRT_Uncommon;

			// --- Common: the starting weapons ---------------------
			case 'Pistol':
			case 'VR_Pistol':
			case 'RS_GH_Pistol':
			case 'Shotgun':
			case 'VR_Shotgun':
			case 'RS_GH_PumpShotgun':
				return VRT_Common;
		}
		return VRT_Common;
	}

	// IsHeavyOrdnance / NormalizeHeavyOrdnance REMOVED 2026-08-08 with
	// the AllowBigGuns carve-out they served. Rocket/plasma/BFG are no
	// longer special: they go through the fill like every other map
	// weapon and are the top three rungs of TierForMapWeapon above.

	// Which class-weapon identity this player is missing, in fill order.
	// "" if all six (2, 3, 5, 6 -- 1 and 4 are the spawn grant) are
	// already owned.
	static string NextMissingIdentity(PlayerPawn pawn, string mainhand)
	{
		if (!pawn.FindInventory(mainhand .. "2")) return "2";
		if (!pawn.FindInventory(mainhand .. "3")) return "3";
		if (!pawn.FindInventory(mainhand .. "5")) return "5";
		if (!pawn.FindInventory(mainhand .. "6")) return "6";
		return "";
	}
}

// =====================================================================
// RS_VanillaPlusSwaps -- Vanilla+ Options world-spawn substitution.
// ---------------------------------------------------------------------
// The six swap-chance sliders and the Random BFG toggle (CVARINFO.txt,
// MENUDEF.txt's RS_VanillaPlusOptions) apply HERE -- to whatever spawns
// in the actual game world (map placements, monster drops, anything that
// goes through WorldThingSpawned) -- not to direct grants, which
// stays deterministic on purpose (press the Chainsaw button, get a
// Chainsaw, always).
//
// Matches on class name rather than "is" so a Family's whole 1..6
// identity range (RS_GH_Chainsaw, RS_GH_Chainsaw2..6) is covered
// uniformly, and preserves the identity number across the swap
// (RS_GH_Chainsaw3 -> RS_GH_Flamethrower3), so which specific
// mainhand/offhand slot spawned isn't lost.
// =====================================================================
class RS_VanillaPlusSwaps : Object
{
	// Returns "" if actualClass isn't baseClass or one of its 2..6
	// identities; otherwise returns the identity suffix ("" for the
	// base identity, "2".."6" for the rest).
	static string IdentitySuffix(string actualClass, string baseClass)
	{
		if (actualClass == baseClass)
			return "";
		if (actualClass.Left(baseClass.Length()) != baseClass)
			return "not-a-match";
		string rest = actualClass.Mid(baseClass.Length());
		// Must be purely "2".."6" -- nothing else is a real identity.
		if (rest.Length() == 1 && rest >= "2" && rest <= "6")
			return rest;
		return "not-a-match";
	}

	static play bool TrySwapPair(WorldEvent e, RS_ClassGating h, string actualClass, string baseClass, string cvarName, string swapToClass)
	{
		string suffix = IdentitySuffix(actualClass, baseClass);
		if (suffix == "not-a-match")
			return false;

		let cv = CVar.GetCVar(cvarName, null);
		int chance = cv ? cv.GetInt() : 0;
		if (chance <= 0 || Random(1, 100) > chance)
			return false;

		string newClass = swapToClass .. suffix;
		let repl = Actor.Spawn(newClass, e.Thing.pos);
		if (h) h.NoteOurSpawn(repl);
		if (repl)
		{
			repl.angle = e.Thing.angle;
			Console.Printf("Vanilla+: world spawn swapped %s -> %s.", actualClass, newClass);
		}
		e.Thing.Destroy();
		return true;
	}

	// Random BFG: any of the three GH heavy-energy weapons spawning
	// rerolls to one of the three (itself included), same identity
	// suffix preserved. BFG9000's irregular naming (RS_GH_BFG90002, no
	// underscore) is handled by IdentitySuffix the same as any other --
	// "RS_GH_BFG9000" is just the base class string, digits after it are
	// still 2..6 the same way.
	static play bool TryRandomBFG(WorldEvent e, RS_ClassGating h, string actualClass)
	{
		let cv = CVar.GetCVar("rs_vp_randombfg", null);
		if (!cv || !cv.GetBool())
			return false;

		string suffix = "not-a-match";
		string bases[3] = {"RS_GH_Unmaker", "RS_GH_BFG10k", "RS_GH_BFG9000"};
		for (int i = 0; i < 3; i++)
		{
			suffix = IdentitySuffix(actualClass, bases[i]);
			if (suffix != "not-a-match")
				break;
		}
		if (suffix == "not-a-match")
			return false;

		int roll = Random(0, 2);
		string newClass = bases[roll] .. suffix;
		let repl = Actor.Spawn(newClass, e.Thing.pos);
		if (h) h.NoteOurSpawn(repl);
		if (repl)
		{
			repl.angle = e.Thing.angle;
			Console.Printf("Vanilla+: Random BFG world spawn -> %s.", newClass);
		}
		e.Thing.Destroy();
		return true;
	}

	static play bool TrySwap(WorldEvent e, RS_ClassGating h)
	{
		if (!e.Thing)
			return false;
		string cls = e.Thing.GetClassName();

		if (TryRandomBFG(e, h, cls))
			return true;

		if (TrySwapPair(e, h, cls, "RS_GH_Chainsaw", "rs_vp_swap_flamethrower_chainsaw", "RS_GH_Flamethrower")) return true;
		if (TrySwapPair(e, h, cls, "RS_GH_SSG", "rs_vp_swap_autoshotgun_ssg", "RS_GH_AssaultShotgun")) return true;
		if (TrySwapPair(e, h, cls, "RS_GH_RocketLauncher", "rs_vp_swap_grenadelauncher_rocketlauncher", "RS_GH_GrenadeLauncher")) return true;
		if (TrySwapPair(e, h, cls, "RS_GH_Plasma", "rs_vp_swap_railgun_plasmarifle", "RS_GH_Railgun")) return true;

		// Minigun has two independent possible substitutes.
		string suf = IdentitySuffix(cls, "RS_GH_Minigun");
		if (suf != "not-a-match")
		{
			let cv1 = CVar.GetCVar("rs_vp_swap_rifle_minigun", null);
			int c1 = cv1 ? cv1.GetInt() : 0;
			if (c1 > 0 && Random(1, 100) <= c1)
			{
				let repl = Actor.Spawn("RS_GH_Rifle" .. suf, e.Thing.pos);
				if (h) h.NoteOurSpawn(repl);
				if (repl) { repl.angle = e.Thing.angle; Console.Printf("Vanilla+: world spawn swapped %s -> RS_GH_Rifle%s.", cls, suf); }
				e.Thing.Destroy();
				return true;
			}
			let cv2 = CVar.GetCVar("rs_vp_swap_machinegun_minigun", null);
			int c2 = cv2 ? cv2.GetInt() : 0;
			if (c2 > 0 && Random(1, 100) <= c2)
			{
				let repl = Actor.Spawn("RS_GH_Machinegun" .. suf, e.Thing.pos);
				if (h) h.NoteOurSpawn(repl);
				if (repl) { repl.angle = e.Thing.angle; Console.Printf("Vanilla+: world spawn swapped %s -> RS_GH_Machinegun%s.", cls, suf); }
				e.Thing.Destroy();
				return true;
			}
		}

		return false;
	}
}
