// =====================================================================
// RS_PACKAssembly -- THE DOOR. This is what PACK was missing.
// ---------------------------------------------------------------------
// Built 2026-08-07, at the owner's direction, after a review found that
// the whole PACK apparatus was finished and unreachable:
//
//   RS_PACKCatalog   691 lines, 409 monster projectiles across 8 themes,
//                    every entry verified to resolve to a live class.
//                    CALLED BY NOTHING.
//   RS_FamilyPalette 274 lines, per-archetype Core/Prestige pools --
//                    the fence that keeps a shotgun a shotgun.
//                    CALLED BY NOTHING.
//   ApplyTheme()     a working assembly function. NO CALLERS.
//
// Three quarters of a feature with no ignition. Every Make* call in the
// entire tree lives inside a weapon file and runs at compile time;
// nothing in this game has ever built an attack profile at runtime.
// This file does, and it is the only thing that does.
//
// ---------------------------------------------------------------------
// WHAT IT ACTUALLY BUILDS
//
// A PACK beat is a real RS_AttackProfile, appended to a weapon's slot,
// so it rides the ordinary rotation: a list of [own, own, PACK] is
// literally "every third shot is a captured monster round". No new
// firing path, no special case in A_RS_FireSlot -- the dispatcher does
// not know or care that this profile came from here.
//
// AXIS OWNERSHIP -- the important design decision in this file.
//
// PACK's eight axes do NOT all come from the monster tree. Only the
// projectile (axis 1) and its themed fire sound (axis 5) do. Everything
// else -- casing, muzzle, smoke, puff, sparks, trail -- is drawn from
// THE GUN'S OWN archetype palette, because a shotgun that starts firing
// caco bile should still eject a shell, still flash like a shotgun, and
// still sound like it is being fired by a shotgun underneath the new
// noise. Take the whole eight axes from the monster and you have not
// modified the player's gun, you have replaced it with a monster.
//
// This is also where RS_FamilyPalette finally gets consulted, which is
// the fence the review warned about: without it, assembly pools the
// entire catalog flat and a pistol can draw a Cyberdemon rocket.
// =====================================================================

class RS_PACKAssembly : Object
{
	// -----------------------------------------------------------------
	// THEME ELIGIBILITY -- the fence, at theme granularity.
	//
	// RS_FamilyPalette fences the CATALOG axes by archetype, but its
	// pools hold RS_Catalog classes and PACK's projectiles are monster
	// classes, so it cannot filter axis 1 by pool membership. The
	// equivalent fence for axis 1 is which THEMES an archetype may draw
	// at all, and that is what this is.
	//
	// The rule behind the table: a theme has to be sayable by the gun.
	// A flamethrower firing an ice shard is a different weapon; a
	// railgun spitting poison is not a railgun. Ballistic archetypes are
	// deliberately permissive -- a bullet gun firing a strange round is
	// exactly the fantasy PACK exists to sell -- while the archetypes
	// that already have a strong elemental identity are narrowed to it.
	//
	// If-chain, not a table: `static const TYPE name[] = {...}` does not
	// resolve on this engine build (CLAUDE.md, three separate bugs).
	// -----------------------------------------------------------------
	static bool ThemeAllowedFor(string archetype, int theme)
	{
		// Flamethrower: fire and nothing else. It is a fire weapon.
		if (archetype == "flamethrower")
			return theme == RS_PACKCatalog.MTHEME_FIRE;

		// Railgun: coherent energy only. No bile, no bugs.
		if (archetype == "railgun")
			return theme == RS_PACKCatalog.MTHEME_PLASMA
			    || theme == RS_PACKCatalog.MTHEME_LIGHTNING
			    || theme == RS_PACKCatalog.MTHEME_VOID;

		// Energy / BFG: the exotic end of the library.
		if (archetype == "energy" || archetype == "bfg")
			return theme == RS_PACKCatalog.MTHEME_PLASMA
			    || theme == RS_PACKCatalog.MTHEME_LIGHTNING
			    || theme == RS_PACKCatalog.MTHEME_PSYCHIC
			    || theme == RS_PACKCatalog.MTHEME_VOID
			    || theme == RS_PACKCatalog.MTHEME_FIRE;

		// Launchers throw things that detonate. Impact and fire read as
		// ordnance; ice and poison read as a spell.
		if (archetype == "launcher")
			return theme == RS_PACKCatalog.MTHEME_IMPACT
			    || theme == RS_PACKCatalog.MTHEME_FIRE
			    || theme == RS_PACKCatalog.MTHEME_PLASMA;

		// Melee never draws a PACK projectile. There is no barrel.
		if (archetype == "melee")
			return false;

		// Every ballistic archetype (pistol, revolver, rifle, smg,
		// shotgun, supershotgun, chaingun) may draw anything. This is
		// the case PACK is really for.
		return true;
	}

	// How many themes this archetype can currently draw. Used by cards
	// to decide whether an offer is even meaningful.
	static int AllowedThemeCount(string archetype)
	{
		int n = 0;
		for (int t = 0; t < RS_PACKCatalog.MTHEME_COUNT; t++)
			if (ThemeAllowedFor(archetype, t) && RS_PACKCatalog.ThemeCount(t) > 0)
				n++;
		return n;
	}

	// Pick one allowed theme at random, or -1 if this archetype can draw
	// nothing. Walks the allowed set rather than rejection-sampling, so
	// a narrow archetype (flamethrower: exactly one) terminates.
	static int RollTheme(string archetype)
	{
		int n = AllowedThemeCount(archetype);
		if (n <= 0) return -1;

		int pick = random(0, n - 1);
		for (int t = 0; t < RS_PACKCatalog.MTHEME_COUNT; t++)
		{
			if (!ThemeAllowedFor(archetype, t)) continue;
			if (RS_PACKCatalog.ThemeCount(t) <= 0) continue;
			if (pick == 0) return t;
			pick--;
		}
		return -1;
	}

	// -----------------------------------------------------------------
	// BUILD ONE PACK BEAT.
	//
	// theme  -- an MTHEME_*, or -1 to roll one this weapon is allowed.
	// index  -- which projectile within the theme, or -1 to roll.
	//
	// Returns null when this weapon can draw nothing, when the theme is
	// empty, or when the projectile does not resolve -- callers must
	// handle null and simply not append. A silently-null beat is far
	// better than a beat that fires nothing, which is exactly the class
	// of bug this project keeps finding.
	// -----------------------------------------------------------------
	static play RS_AttackProfile Build(RS_Weapon wpn, int theme = -1, int index = -1)
	{
		if (!wpn) return null;

		string arch = wpn.GetPaletteArchetype();

		if (theme < 0)
			theme = RollTheme(arch);
		if (theme < 0 || !ThemeAllowedFor(arch, theme))
			return null;

		int count = RS_PACKCatalog.ThemeCount(theme);
		if (count <= 0) return null;

		if (index < 0)
			index = random(0, count - 1);
		index = clamp(index, 0, count - 1);

		Class<Actor> proj = RS_PACKCatalog.DrawProjectile(theme, index);
		if (!proj) return null;

		// --- THE GUN'S OWN AXES, from the palette fence. ---------------
		// Everything except the projectile and the themed sound comes
		// from what this archetype is allowed to use, so the beat still
		// reads as YOUR gun firing something strange rather than as a
		// monster attack that happens to originate at your hands.
		EVR_Tier tier = wpn.Tier;

		Array<Class<Actor> > puffs;   RS_FamilyPalette.BulletPuffs(arch, tier, puffs);
		Array<string>        casings; RS_FamilyPalette.BulletCasings(arch, tier, casings);

		Class<Actor> puff   = puffs.Size()   > 0 ? puffs[random(0, puffs.Size() - 1)]     : null;
		string       casing = casings.Size() > 0 ? casings[random(0, casings.Size() - 1)] : "";

		// --- THE THREE AXES THAT WERE NEVER FILLED. Added 2026-08-11. ---
		//
		// MakeBullet has taken impactSparks, muzzleSmoke and trail since it
		// was written, and Build has never passed any of them, so every PACK
		// beat ever generated left three of the eight axes at null and fell
		// through to the gun's own. Not a bug exactly -- the gun's own part
		// is a valid answer -- but it meant a themed beat could only ever
		// differ from an ordinary shot in its projectile, its casing, its
		// puff and a layered sound.
		//
		// The registry answers these now. Themed, so a fire beat asks for
		// fire-ish parts and takes the gun's own when nothing matches;
		// null from Draw is a legitimate "leave this axis alone".
		//
		// Both safety rails are ON. An entry tagged HOSTILE damages or buffs
		// and raises MONSTERS, and one tagged SPAWNER makes more actors --
		// neither belongs in decoration the player fires, and the whole
		// reason those flags exist is so a roller cannot hand them over by
		// accident.
		//
		// Role is left unconstrained (-1) deliberately: only the 38 entries
		// generated from the index carry role bits, and the 37 original ones
		// are UNCLASSIFIED, which fails every role test. Asking for a role
		// today would silently exclude half the table. Tighten this to
		// R_ACCENT for smoke once the originals have been through the
		// gallery -- that is the curation queue, and this is the line that
		// starts paying for it.
		Class<Actor> sparks = RS_FXRegistry.Draw(
			RS_FXRegistry.RS_FXAXIS_SPARKS, theme, -1, true, true);
		Class<Actor> smoke  = RS_FXRegistry.Draw(
			RS_FXRegistry.RS_FXAXIS_SMOKE,  theme, -1, true, true);
		Class<Actor> trail  = RS_FXRegistry.Draw(
			RS_FXRegistry.RS_FXAXIS_TRAIL,  theme, -1, true, true);

		// --- ASSEMBLE ---------------------------------------------------
		// MakeBullet, not MakeHeavy: a PACK beat is a travelling round
		// on the bullet path, which is the path that carries the
		// GunBonsai master pointer, exact damage, keyword mods and the
		// scale derivation. Heavy mode would need a SetupStats branch
		// per monster class, which is precisely the hardcoded is-chain
		// that just cost this project two whole weapon sets.
		// CORRECTED 2026-08-08. Axis 5 used to carry the theme's sound
		// here, which -- being an override axis like every other one --
		// SILENCED the gun's own fire sound rather than playing under
		// it, contradicting this file's own line above ("still sound
		// like it is being fired by [the gun] underneath the new
		// noise"). A caco-themed shotgun beat sounded like only the
		// caco. Axis 5 is left blank now, so it falls through to the
		// gun's own report exactly like every other appearance axis;
		// the theme's voice moves to ExtraFireSound, which is layered
		// rather than override and plays on its own channel alongside
		// it -- both audible, which is what the prose always promised.
		let p = RS_AttackProfile.MakeBullet(
			"",                                    // axis 5: the gun's own now
			0.05,                                  // spread: the gun's own feel
			true,                                  // uses cadence like any beat
			1,                                     // AMMO COST -- never 0, see below
			casing,                                // axis 2, the gun's
			false,                                 // muzzle: leave the gun's
			false,                                 // choke: not a shotgun-shaped beat
			1.0,                                   // damage: the gun's rolled number
			proj,                                  // axis 1, the monster's
			"PACK: " .. RS_PACKCatalog.ThemeName(theme),
			puff,                                  // axis 6, the gun's
			impactSparks: sparks,                  // the registry's, themed
			muzzleSmoke:  smoke,                   // the registry's, themed
			trail:        trail,                   // the registry's, themed
			extraFireSnd: RS_PACKCatalog.DrawFireSound(theme));  // layered, not axis 5

		// AMMO COST IS EXPLICITLY 1 AND MUST STAY NON-ZERO.
		// MakeBullet/MakeHeavy/MakeVolley/MakeBurst all default ammoCost
		// to 0, and a profile that costs nothing fires free forever with
		// no error and no log line. That default is exactly how the
		// three heavy weapons ended up with infinite ammo for a month.
		// A generated beat is the likeliest place for that to happen
		// again, so it is set here, deliberately, and commented.
		p.AmmoCost = 1;

		return p;
	}

	// -----------------------------------------------------------------
	// INSTALL a PACK beat into a weapon's primary rotation.
	//
	// `everyNth` is the rotation shape the player actually feels:
	//   3 -> [own, own, PACK]   "every third shot"
	//   2 -> [own, PACK]        "alternating"
	//
	// The weapon's existing profiles are preserved and the PACK beat is
	// appended once, after the slot has been padded out to length-1 with
	// the gun's own opening profile. PadSlotTo is RS_Weapon's own
	// primitive for this and already handles an empty slot safely.
	//
	// Returns the profile installed, or null if nothing was.
	// -----------------------------------------------------------------
	static play RS_AttackProfile Install(RS_Weapon wpn, int everyNth = 3,
		int theme = -1, int index = -1)
	{
		if (!wpn) return null;
		if (everyNth < 2) everyNth = 2;

		let p = Build(wpn, theme, index);
		if (!p) return null;

		// Grow the gun's own opening beat out to everyNth-1 entries, then
		// put the PACK beat last. A gun that already rotates keeps its
		// rotation; this lengthens it rather than replacing it.
		wpn.PadSlotTo(0, everyNth - 1);
		wpn.AppendProfile(0, p);
		return p;
	}

	// Remove every PACK beat from a weapon's primary slot. Used when an
	// affix is deactivated or respecced -- GunBonsai can turn an upgrade
	// off, and a beat that outlives its card is a permanent free
	// upgrade.
	//
	// Identified by ProfileName prefix, which Build() always sets. That
	// is deliberate: the alternative is a marker field on
	// RS_AttackProfile, and a name check needs no change to a structure
	// three other systems read.
	static play void UninstallAll(RS_Weapon wpn)
	{
		if (!wpn) return;
		let slot = wpn.GetSlot(0);
		if (!slot) return;

		for (int i = slot.Profiles.Size() - 1; i >= 0; i--)
		{
			let p = slot.Profiles[i];
			if (p && p.ProfileName.IndexOf("PACK: ") == 0)
				slot.Profiles.Delete(i);
		}
		// Cursor could now point past the end.
		if (slot.Cursor >= slot.Profiles.Size())
			slot.Cursor = 0;
	}
}
