// =====================================================================
// VR_PlayerClasses -- 7 selectable starting loadouts.
// ---------------------------------------------------------------------
// Every Dual_X class grants Fist + two Basic-tier weapons of that type
// (one mainhand, one offhand), plus all three heavy ordnance pieces
// universally (Rocket, Plasma, BFG) if "Allow Big Guns" is on -- those
// don't belong to any one specialization, every class gets them when
// enabled.
//
// All 7 get listed in MAPINFO's PlayerClasses -- GZDoom shows its own
// native class-select screen at game start automatically.
// =====================================================================

// ---------------------------------------------------------------------
// VR_DualClassBase -- shared behavior for all 7 Dual_X classes.
// ---------------------------------------------------------------------
// Collapses what used to be seven byte-identical PostBeginPlay copies
// into one, following the same virtual-override shape already
// established by GetHeavyProjectile()/GetOffhandClass() elsewhere: a
// base does the real work, each subclass just names its own weapon.
//
// Force-equips the granted mainhand weapon explicitly rather than
// trusting engine default weapon-selection at spawn, which was leaving
// the player holding fists instead of their class weapon.
// =====================================================================
class VR_DualClassBase : DoomPlayer abstract
{
	// Each Dual_X class overrides this with its own mainhand identity-1
	// class name (e.g. "VR_Revolver"). Empty string is the "nothing to
	// force-equip" default -- shouldn't happen for a real subclass, but
	// keeps this base safe to instantiate directly if it ever needs to be.
	virtual string GetMainhandClass()
	{
		return "";
	}

	// Class-gating family this class is allowed to pick up -- see
	// RS_ClassGating.zs. None means "not gated" and should never be
	// returned by a real Dual_X subclass.
	virtual EVR_Family GetFamily()
	{
		return EVR_Family_None;
	}

	// -----------------------------------------------------------------
	// SEAT BOTH HANDS, ONCE, AFTER EVERY SPAWN GRANT HAS LANDED.
	//
	// This is the single seating authority. It exists because of two
	// engine facts that between them broke both hands:
	//
	//  1. GiveDefaultInventory is HAND-BLIND. It runs
	//     `ReadyWeapon = PendingWeapon = weap` for every granted weapon
	//     that has ammo, with no bOffhandWeapon check -- so the LAST
	//     weapon granted always wins the main hand, whatever it is.
	//     Player.StartItem is granted in REVERSE declaration order, so
	//     that last grant is the FIRST line in the Default block: the
	//     fist. Every class span with a fist in the main hand.
	//
	//  2. A direct write to ReadyWeapon/OffhandWeapon after the engine
	//     has already raised the psprites LEAVES THAT PSPRITE STALE, and
	//     TickPSprites destroys any psprite whose Caller no longer
	//     matches its slot -- with nothing to rebuild it. That is why
	//     Vanilla+ and MeatGrinder lost the weapon, the models and the
	//     GunBonsai HUD a moment after spawning: their real guns are
	//     granted in PostBeginPlay, after the raise, so the pointer
	//     write orphaned the layer and the next tic deleted it.
	//
	// Setting PendingWeapon = WP_NOCHANGE and calling BringUpWeapon is
	// the engine's own "raise whatever is in both hands, now" primitive
	// (player.zs:1930-1954). It is the ONLY way to seat two hands in one
	// tic -- there is exactly one PendingWeapon, so the ordinary switch
	// path can only ever change one hand.
	//
	// Flag-driven throughout: a weapon is offhand because it carries
	// +WEAPON.OFFHANDWEAPON, never because of its class name. Any future
	// weapon with that flag is seated correctly with no change here.
	// -----------------------------------------------------------------
	void SeatHands()
	{
		if (!player) return;

		Weapon mainGun = null, mainFiller = null;
		Weapon offGun  = null, offFiller  = null;

		for (Inventory item = Inv; item != null; item = item.Inv)
		{
			let w = Weapon(item);
			if (!w) continue;

			// A filler is the empty-slot placeholder a class grants so the
			// hand is never truly empty. It must lose to any real weapon,
			// but still be seated if that is genuinely all there is.
			let rw = RS_Weapon(w);
			bool filler = rw && rw.IsHandFiller();

			if (w.bOffhandWeapon)
			{
				if (filler) { if (!offFiller) offFiller = w; }
				else        { if (!offGun)    offGun    = w; }
			}
			else
			{
				if (filler) { if (!mainFiller) mainFiller = w; }
				else        { if (!mainGun)    mainGun    = w; }
			}
		}

		// GetMainhandClass is a TIEBREAKER, not the authority -- it picks
		// which of your own guns is the featured one (Vanilla+ swaps its
		// starting pair on a cvar), while the flag decides the hand.
		string featured = GetMainhandClass();
		if (featured.Length())
		{
			let w = Weapon(FindInventory(featured));
			if (w && !w.bOffhandWeapon) mainGun = w;
		}

		Weapon mainWep = mainGun ? mainGun : mainFiller;
		Weapon offWep  = offGun  ? offGun  : offFiller;

		if (mainWep) player.ReadyWeapon   = mainWep;
		if (offWep)  player.OffhandWeapon = offWep;

		player.PendingWeapon = WP_NOCHANGE;
		BringUpWeapon();
	}

	// Subclasses whose loadout can't be static Player.StartItem (Vanilla+
	// swaps its pair on a cvar) override THIS, not PostBeginPlay -- so
	// their grants land before SeatHands runs, instead of after it.
	virtual void GrantStartingArsenal()
	{
		let cv = CVar.GetCVar("rs_dualclass_allowbigguns", null);
		if (cv && cv.GetBool())
		{
			GiveInventory("VR_RocketLauncher", 1);
			GiveInventory("VR_PlasmaRifle", 1);
			GiveInventory("VR_BFG9000", 1);
			// Reserve ammo for the granted heavy ordnance -- these three
			// weapons don't currently consume ammo when fired (a known,
			// separate bug, see HANDOFF), but granting the guns with no
			// reserve at all would be wrong regardless of when that gets
			// fixed.
			GiveInventory("RocketAmmo", 20);
			GiveInventory("Cell", 200);
		}
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		GrantStartingArsenal();
		SeatHands();
	}

	// -----------------------------------------------------------------
	// IN-WORLD PANEL CONFIRM -- the one place a button can be taken away
	// from the weapon before the weapon sees it.
	//
	// This is not where you would expect UI input handling to live, and
	// it is here for a measured reason rather than convenience. An
	// EventHandler's WorldTick runs AFTER the player has already thought
	// (p_tick.cpp:175, then :178), and the shot is decided inside that
	// think -- TickPSprites -> CheckWeaponFire reads player.cmd.buttons
	// at player.zs:478. Anything that clears buttons in WorldTick is
	// clearing them after the gun has already gone off. RS_WheelPoC's
	// header asserts the opposite ordering; it is wrong, and copying it
	// here would have shipped a confirm that also discharges your
	// weapon.
	//
	// PlayerThink is virtual (player.zs:1732) and CheckWeaponFire is not
	// (player.zs:463), so this override is the hook.
	//
	// Capture returns immediately unless a panel row is genuinely live
	// under a pointing hand, so in the common case this is a couple of
	// null checks per tic.
	// -----------------------------------------------------------------
	override void PlayerThink()
	{
		RS_PanelInput.Capture(self);
		Super.PlayerThink();
	}
}

class VR_Dual_Pistol : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Dual Pistols";
		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Pistol";
		Player.StartItem "VR_Pistol4";
		Player.StartItem "Clip", 72;
		Player.StartItem "VR_PistolLoaded", 12;
		Player.StartItem "VR_PistolLoaded4", 12;
	}

	override string GetMainhandClass() { return "VR_Pistol"; }
	override EVR_Family GetFamily() { return EVR_Family_Pistol; }
}

class VR_Dual_Revolver : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Dual Revolvers";
		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Revolver";
		Player.StartItem "VR_Revolver4";
		Player.StartItem "Clip", 36;
		Player.StartItem "VR_RevLoaded", 6;
		Player.StartItem "VR_RevLoaded4", 6;
	}

	override string GetMainhandClass() { return "VR_Revolver"; }
	override EVR_Family GetFamily() { return EVR_Family_Revolver; }
}

class VR_Dual_Rifle : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Dual Rifles";
		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Rifle";
		Player.StartItem "VR_Rifle4";
		Player.StartItem "Clip", 60;
		Player.StartItem "VR_RifleLoaded", 20;
		Player.StartItem "VR_RifleLoaded4", 20;
	}

	override string GetMainhandClass() { return "VR_Rifle"; }
	override EVR_Family GetFamily() { return EVR_Family_Rifle; }
}

class VR_Dual_SMG : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Dual SMGs";
		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_SMG";
		Player.StartItem "VR_SMG4";
		Player.StartItem "Clip", 90;
		Player.StartItem "VR_SMGLoaded", 30;
		Player.StartItem "VR_SMGLoaded4", 30;
	}

	override string GetMainhandClass() { return "VR_SMG"; }
	override EVR_Family GetFamily() { return EVR_Family_SMG; }
}

class VR_Dual_Shotgun : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Dual Shotguns";
		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Shotgun";
		Player.StartItem "VR_Shotgun4";
		Player.StartItem "VR_Shell", 24;
		Player.StartItem "VR_ShotLoaded", 8;
		Player.StartItem "VR_ShotLoaded4", 8;
	}

	override string GetMainhandClass() { return "VR_Shotgun"; }
	override EVR_Family GetFamily() { return EVR_Family_Shotgun; }
}

class VR_Dual_SSG : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Dual Super Shotguns";
		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_SuperShotgun";
		Player.StartItem "VR_SuperShotgun4";
		Player.StartItem "VR_Shell", 12;
		Player.StartItem "VR_SSGLoaded", 2;
		Player.StartItem "VR_SSGLoaded4", 2;
	}

	override string GetMainhandClass() { return "VR_SuperShotgun"; }
	override EVR_Family GetFamily() { return EVR_Family_SuperShotgun; }
}

class VR_Dual_Chaingun : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Dual Chainguns";
		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";
		Player.StartItem "VR_Chaingun";
		Player.StartItem "VR_Chaingun4";
		Player.StartItem "VR_ChaingunAmmo", 60;
	}

	override string GetMainhandClass() { return "VR_Chaingun"; }
	override EVR_Family GetFamily() { return EVR_Family_Chaingun; }
}

// ---------------------------------------------------------------------
// RS_GH_Weaponset -- displayed as "Vanilla+". Ungated (no family gating,
// same as leaving GetFamily() at its EVR_Family_None default -- see
// RS_ClassGating.zs's own comment, which already anticipated exactly
// this case). Starts with Fist/offhand Fist + two pistols, loaded.
// RS_Weapon.AttachToOwner already auto-fills each weapon's loaded
// chamber to Capacity the instant it's granted, so granting the guns is
// enough -- the magazines fill themselves, no reload needed on pickup.
//
// "Start with Rifle instead of Pistols" (rs_vp_startrifle, Vanilla+
// Options menu) swaps the granted mainhand+offhand pair entirely, so it
// has to happen in PostBeginPlay code rather than static StartItem --
// same shape as VR_DualClassBase's own "Allow Big Guns" cvar check.
// ---------------------------------------------------------------------
class RS_GH_Weaponset : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "Vanilla+";

		Player.StartItem "VR_Fist";
		Player.StartItem "VR_Fist2";

		// Reserve ammo -- covers the starting pistols (or rifles, if the
		// swap option is on) and anything picked up later.
		Player.StartItem "Clip", 200;
	}

	override string GetMainhandClass()
	{
		let cv = CVar.GetCVar("rs_vp_startrifle", null);
		return (cv && cv.GetBool()) ? "RS_GH_Rifle" : "RS_GH_Pistol";
	}

	// GrantStartingArsenal, NOT PostBeginPlay. This used to override
	// PostBeginPlay and call Super FIRST, which meant its real guns were
	// granted AFTER the base class had already finished seating hands --
	// and, worse, after the engine had already raised the psprites. The
	// direct OffhandWeapon write that followed left that psprite stale,
	// and TickPSprites deleted it on the next tic with nothing to rebuild
	// it. That is the whole "my HUD and weapons vanish a second after I
	// spawn" bug on this class. Granting here puts them in inventory
	// before SeatHands runs, which is the entire point of the split.
	override void GrantStartingArsenal()
	{
		Super.GrantStartingArsenal();

		let cv = CVar.GetCVar("rs_vp_startrifle", null);
		if (cv && cv.GetBool())
		{
			GiveInventory("RS_GH_Rifle", 1);
			GiveInventory("RS_GH_Rifle4", 1);
		}
		else
		{
			GiveInventory("RS_GH_Pistol", 1);
			GiveInventory("RS_GH_Pistol4", 1);
		}
	}
	// No GetFamily() override -- inherits EVR_Family_None from the base,
	// which is deliberately "ungated" here, not an oversight.
}

// =====================================================================
// RS_PS_Weaponset -- the MeatGrinder starting class.
// ---------------------------------------------------------------------
// Starts dual knives and dual TEC-9s: mainhand + offhand of each. The
// offhand variants are the _4 classes, matching the convention every
// Dual_X class above uses (_1.._3 mainhand, _4.._6 carry
// +WEAPON.OFFHANDWEAPON).
//
// No GetFamily() override -- inherits EVR_Family_None from the base,
// which RS_ClassGating reads as "ungated". Deliberate: this is a
// whole-set class, not a single-family one, so it must not filter the
// world down to one weapon family the way VR_Dual_Pistol does.
// =====================================================================
class RS_PS_Weaponset : VR_DualClassBase
{
	Default
	{
		Player.DisplayName "MeatGrinder";
		Player.StartItem "RS_PS_Fist";
		Player.StartItem "RS_PS_Fist4";
		Player.StartItem "RS_PS_Machinegun";
		Player.StartItem "RS_PS_Machinegun4";

		// Reserve for the starting TEC-9s. MeatGrinder has no reload
		// mechanic, so these feed straight from the pool.
		Player.StartItem "Clip", 200;
	}

	override string GetMainhandClass() { return "RS_PS_Machinegun"; }
}
