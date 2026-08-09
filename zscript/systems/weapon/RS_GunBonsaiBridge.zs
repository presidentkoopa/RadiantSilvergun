// =====================================================================
// RS_GunBonsaiBridge -- the one file where RS_Weapon and the vendored
// GunBonsai system talk to each other. Nothing else on either side should
// reference the other's types directly -- RS_Weapon.Promote() calls
// OnWeaponPromoted() here, and that's the only coupling point.
// ---------------------------------------------------------------------
// Affix stripping is fully graftable: TFLV_WeaponInfo's upgrade bag
// (info.upgrades) and OnDeactivate() are both public, reached from here
// with zero edits to vendored files.
//
// The XP-curve discount (see docs/rs_01_promotion_system.txt) is NOT
// graftable the same way -- GetXPForLevel() is a concrete, non-virtual
// method called internally by TFLV_WeaponInfo's own Rebind()/
// CountPendingLevels(), and `extend class` can only ADD new members, not
// replace an existing method's body. That piece is instead a small,
// guarded edit directly inside zscript/GunBonsai/WeaponInfo.zsc's
// GetXPForLevel() -- consistent with this project's existing precedent
// (the offhand/GBOH additions are already direct edits to vendored
// GunBonsai files, not a pure extend-only graft).
// =====================================================================

class RS_GunBonsaiBridge : Object play
{
	// Called once, at the end of RS_Weapon.Promote(). Strips every
	// GunBonsai-granted affix off a weapon that just dropped to 0 sockets.
	// OnDeactivate() runs first so any persistent side effect an upgrade
	// set up (flags, stat modifiers) gets properly reversed instead of
	// orphaned, then the bag itself is cleared.
	static void OnWeaponPromoted(RS_Weapon wep)
	{
		if (!wep || !wep.Owner)
			return;

		let stats = TFLV_PerPlayerStats.GetStatsFor(wep.Owner);
		if (!stats)
			return;

		let info = stats.GetInfoFor(wep);
		if (!info)
			return;

		info.upgrades.OnDeactivate(stats, info);
		info.upgrades.upgrades.Clear();
	}

	// How many affixes this weapon is currently carrying. Read by
	// RS_Weapon.Promote() BEFORE the strip above, to mitigate the
	// promotion curse roll: investing in a gun before cashing it in is
	// insurance. Counts only the ten designed affixes -- stat and combo
	// cards are permanent purchases, not affixes, and buying six damage
	// cards shouldn't read as "well-equipped" here.
	static int CountActiveAffixes(RS_Weapon wep)
	{
		if (!wep || !wep.Owner)
			return 0;

		let stats = TFLV_PerPlayerStats.GetStatsFor(wep.Owner);
		if (!stats)
			return 0;

		let info = stats.GetInfoFor(wep);
		if (!info)
			return 0;

		int n = 0;
		for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
		{
			let upg = info.upgrades.upgrades[i];
			if (upg && upg.level > 0 && (upg is "TFLV_Upgrade_RS_SlateBase"))
				n++;
		}
		return n;
	}

	// WHAT IS ACTUALLY FITTED, by name, for the offer card's socket rows.
	//
	// The card used to draw anonymous pips: you could count your sockets
	// but not read what was in them. The mockup lists each fitting by
	// name, which is the thing that teaches a first-time player what a
	// socket does.
	//
	// Names come from the upgrade's own GetName(), so a renamed or newly
	// added affix needs no entry here.
	static void FittedNames(RS_Weapon wep, out Array<string> outv)
	{
		outv.Clear();
		if (!wep || !wep.Owner)
			return;

		let stats = TFLV_PerPlayerStats.GetStatsFor(wep.Owner);
		if (!stats)
			return;

		let info = stats.GetInfoFor(wep);
		if (!info)
			return;

		for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
		{
			let upg = info.upgrades.upgrades[i];
			if (upg && upg.level > 0)
				outv.Push(upg.GetName());
		}
	}

	// Read a weapon's Condition for UI (the GunBonsai HUD's CND readout).
	// Takes a plain Weapon so callers never name RS types -- the cast
	// lives here, the one sanctioned coupling point. -1 = not an RS
	// weapon. clearscope: called from ui draw code, reads only.
	clearscope static int ConditionFor(Weapon w)
	{
		let rw = RS_Weapon(w);
		if (!rw)
			return -1;
		return int(rw.Condition);
	}

	// Called by A_RS_FireSlot, on the acting player, the instant a shot is
	// committed -- before any mode-specific firing path runs. Attribution
	// by direct declaration, not detection: this is why it works
	// identically for bullet/heavy/hitscan/melee, instead of only working
	// for modes that happen to spawn a projectile actor to carry a master
	// pointer. See the WorldThingDamaged fallback in
	// zscript/GunBonsai/EventHandler.zsc that reads this.
	static void NotifyFired(Actor pawn, RS_Weapon wep)
	{
		let p = VR_DualClassBase(pawn);
		if (p)
			p.RS_LastFiredWeapon = wep;
	}
}

// VR_DualClassBase (zscript/player/VR_PlayerClasses.zs) is RS's own player
// class, not an engine or vendored one -- every player class in this
// project (VR_Dual_Pistol, ..., RS_GH_Weaponset) extends it, so adding a
// field directly here carries zero risk of the class not existing in
// whatever engine fork this runs on (unlike extending the raw engine
// PlayerPawn, which crashed: "class playerpawn cannot be found in current
// translation unit" -- this build's PlayerPawn isn't reachable the way
// vanilla GZDoom's is). One field: which RS_Weapon most recently fired,
// for this player. Always reflects the truth at the moment it's read;
// nothing clears it between shots because nothing needs to -- a stale
// value just means "the last weapon that fired," which is exactly what a
// fresh shot overwrites.
extend class VR_DualClassBase
{
	RS_Weapon RS_LastFiredWeapon;
}
