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

	// Launched grenade -- arcs under gravity, bounces, two-stage blast.
	// Referenced by the GH Machine Gun's underbarrel alt-fire; the same
	// entry a Grenade Launcher import points at rather than duplicating.
	static Class<Actor> PROJ_GrenadeLaunched()
	{
		return "RS_GH_GrenadeLaunched";
	}

	// Hand-thrown variant -- same explosion, real slower toss arc. Was
	// missing entirely; HandGrenade shared the launcher's own projectile
	// (and its faster speed) with nothing distinguishing a toss from a
	// launched round.
	static Class<Actor> PROJ_GrenadeThrown()
	{
		return "RS_GH_GrenadeThrown";
	}

	// Heavy ordnance -- Rocket/Plasma/BFG, each carrying real vanilla
	// explosion behaviour plus SetupStats() (see RS_FX_HeavyProjectiles.zs).
	// Read via GetHeavyProjectile() rather than a bullet AttackProfile, but
	// still belongs in the catalog for the same reason every other
	// projectile does: a future affix or a different weapon shouldn't have
	// to know the literal class name to reuse the attack.
	static Class<Actor> PROJ_Rocket()
	{
		return "RS_EnhancedRocket";
	}

	static Class<Actor> PROJ_PlasmaBall()
	{
		return "RS_EnhancedPlasmaBall";
	}

	static Class<Actor> PROJ_BFGBall()
	{
		return "RS_EnhancedBFGBall";
	}

	// GunstarHeroes-specific heavy rounds -- real ported art/behavior, not
	// the vanilla-based Enhanced* skins above. See RS_GH_HeavyProjectiles.zs.
	static Class<Actor> PROJ_GH_BFGShot()
	{
		return "RS_GH_BFGShot";
	}

	static Class<Actor> PROJ_GH_PlasmaShot()
	{
		return "RS_GH_PlasmaShot";
	}

	static Class<Actor> PROJ_GH_UnmakerShot()
	{
		return "RS_GH_UnmakerShot";
	}

	// Real travelling bolts, not hitscan -- see RS_FX_RailProjectiles.zs
	// for why. Primary = coiled helix, secondary = straight BD-faithful.
	// Not GH-specific despite where it was first used -- generic shared
	// building block, same as PROJ_Ballistic() above, just built for the
	// Railgun first.
	static Class<Actor> PROJ_RailBolt()
	{
		return "RS_RailBolt";
	}

	static Class<Actor> PROJ_RailBoltStraight()
	{
		return "RS_RailBoltStraight";
	}

	// No source class existed for this in this project -- genuine new
	// build, real DamageType "Fire". See RS_GH_HeavyProjectiles.zs.
	static Class<Actor> PROJ_GH_FlameJet()
	{
		return "RS_GH_FlameJet";
	}

	// -----------------------------------------------------------------
	// CASING ENTRIES
	// Ejected shell/casing actors, read by RS_HiFiFX.CasingEject() as a
	// string (not Class<Actor> -- see its signature). Real classes live in
	// RS_FX_Casings.zs.
	// -----------------------------------------------------------------
	static string CASING_Small()  { return "RS_CasingSmall"; }
	static string CASING_Rifle()  { return "RS_CasingRifle"; }
	static string CASING_Shell()  { return "RS_CasingShell"; }

	// -----------------------------------------------------------------
	// PLAYER FEEDBACK ENTRIES -- impact puffs, impact sparks, muzzle
	// smoke. Read by RS_AttackProfile.ImpactPuff/ImpactSparks/MuzzleSmoke
	// (bullet/hitscan profiles only). Real classes live in
	// RS_FX_Puffs.zs / RS_FX_Sparks.zs / RS_FX_Ricochet.zs / RS_FX_Smoke.zs.
	// -----------------------------------------------------------------
	static Class<Actor> PUFF_Bullet()   { return "RS_EnhancedBulletPuff"; }
	static Class<Actor> PUFF_Shot()     { return "RS_EnhancedShotPuff"; }
	static Class<Actor> PUFF_Chainsaw() { return "RS_ChainsawPuff"; }
	static Class<Actor> PUFF_Vanilla()  { return "BulletPuff"; }

	static Class<Actor> SPARK_Hit()        { return "RS_HitSpark"; }
	static Class<Actor> SPARK_X()          { return "RS_SparkX"; }
	static Class<Actor> SPARK_XNoModel()   { return "RS_SparkXNoModel"; }
	static Class<Actor> SPARK_XHeavy()     { return "RS_SparkXHeavy"; }
	static Class<Actor> SPARK_Ricochet()   { return "RS_RicochetSpark"; }
	static Class<Actor> SPARK_Rail()       { return "RS_RailImpactSpark"; }

	static Class<Actor> SMOKE_Wisp() { return "RS_SmokeWisp"; }

	// In-flight trail piece dropped periodically behind a travelling
	// bullet -- see RS_FX_BallisticFired.zs's RS_BallisticFired.Tick().
	// Read as the default when an AttackProfile doesn't set its own
	// Trail override (RS_AttackProfile.Trail), same null-means-default
	// shape as the puff/spark/smoke entries above.
	static Class<Actor> TRAIL_Ballistic() { return "RS_BallisticTrail"; }

	// -----------------------------------------------------------------
	// SOUND ENTRIES
	// Logical names, resolved through SNDINFO. A weapon references the
	// entry, never a raw lump path, so re-pointing a sound is one edit
	// here instead of one edit per weapon that used it.
	// -----------------------------------------------------------------

	// ---- Main arsenal: one fire-sound entry per weapon. ------------------
	// Logical names already declared in SNDINFO -- these wrap them, they
	// don't duplicate or rename them.
	static sound SND_Pistol()       { return "9mmshoot"; }
	static sound SND_Revolver()     { return "revolver"; }

	// Alternate fire-sound takes for the Weapon Sound Assignment options
	// menu (MENUDEF's RS_WeaponSoundOptions, rs_soundchoice_revolver).
	// Only the Revolver has real alternates staged today -- everything
	// else in the arsenal has exactly one cataloged fire sound, so their
	// menu rows only ever offer "Default" until more takes get sourced.
	static sound SND_Revolver_Resolve(int choice)
	{
		switch (choice)
		{
			case 1: return "rs_revolver_alt1";
			case 2: return "rs_revolver_alt2";
			case 3: return "rs_revolver_alt3";
			default: return SND_Revolver();
		}
	}
	static sound SND_Rifle()        { return "m16shoot"; }
	static sound SND_SMG()          { return "smgfire"; }
	static sound SND_Shotgun()      { return "shotgf"; }
	static sound SND_SuperShotgun() { return "wpn/shotgun2"; }
	static sound SND_Chaingun()     { return "chngun"; }
	static sound SND_Chainsaw()     { return "sawloop"; }
	static sound SND_RocketLauncher() { return "rocklf"; }
	static sound SND_PlasmaRifle()  { return "weapons/plasma/fire"; }
	static sound SND_BFG9000()      { return "bfgf"; }

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

	// -----------------------------------------------------------------
	// WEAPON SOUND ASSIGNMENT DISPATCH
	// Single choke point for RS_Weapon.GetEffectiveFireSound(): given an
	// archetype (read straight off the weapon's own archetype: keyword,
	// not its class name) and a menu choice index, return the sound.
	// Add a new archetype's alternates here, and here only -- never by
	// touching an individual weapon file. fallback covers every
	// archetype with no case below (the common case today).
	// -----------------------------------------------------------------
	static sound ResolveArchetypeSound(string archetype, int choice, sound fallback)
	{
		if (archetype == "revolver")
			return SND_Revolver_Resolve(choice);
		return fallback;
	}
}
