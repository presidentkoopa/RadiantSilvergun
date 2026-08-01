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
