// =====================================================================
// RS_Catalog -- the projectile / sound / effect database.
// ---------------------------------------------------------------------
// See docs/catalog_notes.txt. The rule: an imported weapon does NOT own
// its attack. Its projectile, sounds, and effects are extracted into
// standalone, ID-named entries here, and the weapon merely REFERENCES
// those IDs. Two weapons that fire the same kind of round point at the
// same catalog entry instead of each carrying a private copy of it.
//
// The payoff is that new attacks get ASSEMBLED from existing parts --
// pick a projectile ID, a fire sound ID, an impact ID -- rather than
// written as new code per weapon. That's what makes GunBonsai able to
// hand out a genuinely new attack later without anyone having authored
// that specific combination.
//
// ID CONVENTION:  RS_<CATEGORY>_<NAME>
//   RS_PROJ_*   projectile behaviour entries
//   RS_SND_*    fire / impact sound entries
// Set-specific assets keep their set in the path, not the ID -- an ID is
// a behaviour, not a filename, so a GH bullet and an RS bullet that
// behave identically should share one entry.
// =====================================================================

class RS_Catalog
{
	// -----------------------------------------------------------------
	// PROJECTILE ENTRIES
	// Each returns the actor class that carries the attack's movement,
	// visual identity and impact behaviour. Everything numeric --
	// damage, velocity, crit -- is supplied per-shot by the firing
	// weapon's rolled stats (see RS_Weapon.A_RS_FireSlot), so one entry
	// serves a Basic-tier and a Prototype-tier gun alike.
	// -----------------------------------------------------------------

	// Standard travelling ballistic round. The main-arsenal default.
	static Class<Actor> PROJ_Ballistic()
	{
		return "RS_BallisticType1";
	}

	// Same round with a visible tracer. Swapped in by the rs_fx_tracers
	// cvar today; a catalog entry so an affix can request it directly.
	static Class<Actor> PROJ_BallisticTracer()
	{
		return "RS_BallisticTracer";
	}

	// Launched grenade -- arcs under gravity, bounces, two-stage blast.
	// Referenced by the GH Machine Gun's underbarrel alt-fire; the same
	// entry a Grenade Launcher import points at rather than duplicating.
	static Class<Actor> PROJ_GrenadeLaunched()
	{
		return "RS_GH_GrenadeLaunched";
	}

	// -----------------------------------------------------------------
	// SOUND ENTRIES
	// Logical names, resolved through SNDINFO. A weapon references the
	// entry, never a raw lump path, so re-pointing a sound is one edit
	// here instead of one edit per weapon that used it.
	// -----------------------------------------------------------------

	// ---- GunstarHeroes set: one fire-sound entry per weapon. -------------
	// Generated to match the SNDINFO block of the same names. A weapon
	// references the entry; nothing references a lump path directly.
	static sound SND_GH_Fist() { return "rs_gh/fist_fire"; }
	static sound SND_GH_Chainsaw() { return "rs_gh/chainsaw_fire"; }
	static sound SND_GH_Pistol() { return "rs_gh/pistol_fire"; }
	static sound SND_GH_Revolver() { return "rs_gh/revolver_fire"; }
	static sound SND_GH_PumpShotgun() { return "rs_gh/pumpshotgun_fire"; }
	static sound SND_GH_AssaultShotgun() { return "rs_gh/assaultshotgun_fire"; }
	static sound SND_GH_SSG() { return "rs_gh/ssg_fire"; }
	static sound SND_GH_Minigun() { return "rs_gh/minigun_fire"; }
	static sound SND_GH_Rifle() { return "rs_gh/rifle_fire"; }
	static sound SND_GH_SMG() { return "rs_gh/smg_fire"; }
	static sound SND_GH_MP40() { return "rs_gh/mp40_fire"; }
	static sound SND_GH_RocketLauncher() { return "rs_gh/rocketlauncher_fire"; }
	static sound SND_GH_GrenadeLauncher() { return "rs_gh/grenadelauncher_fire"; }
	static sound SND_GH_HandGrenade() { return "rs_gh/handgrenade_fire"; }
	static sound SND_GH_Plasma() { return "rs_gh/plasma_fire"; }
	static sound SND_GH_Railgun() { return "rs_gh/railgun_fire"; }
	static sound SND_GH_BFG9000() { return "rs_gh/bfg9000_fire"; }
	static sound SND_GH_BFG10k() { return "rs_gh/bfg10k_fire"; }
	static sound SND_GH_Unmaker() { return "rs_gh/unmaker_fire"; }
	static sound SND_GH_Flamethrower() { return "rs_gh/flamethrower_fire"; }
	static sound SND_GH_Machinegun() { return "rs_gh/machinegun_fire"; }

	// Grenade launch thump -- underbarrel and any future launcher.
	static sound SND_GH_GrenadeLaunch() { return "rs_gh/grenade_launch"; }
}
