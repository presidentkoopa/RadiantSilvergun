// =====================================================================
// RS_ClassGating -- one chokepoint, not per-weapon logic.
// ---------------------------------------------------------------------
// Every map-placed weapon pickup gets checked once, at the moment the
// map spawns it, against the player's chosen class family. A mismatch is
// REPLACED WITH RESERVE AMMO for the class you're actually playing,
// before it's ever collidable -- play Dual_Revolver and the pistol, SMG,
// chaingun, shotgun, SSG and rifle pickups become Clip. It used to
// simply destroy the pickup, which stripped items out of maps and left
// nothing in their place. Player.StartItem
// grants and GiveInventory calls (monster drops, "Allow Big Guns", console
// give) never go through WorldThingSpawned, so this only ever touches
// actual floor pickups -- it can't clobber anything already handed to
// the player directly.
//
// New weapons are covered automatically: as long as a weapon type
// overrides RS_Weapon.GetFamily() (see the 7 Dual_X-owned weapon files),
// nobody has to touch this file again.
// =====================================================================

class RS_ClassGating : EventHandler
{
	// Which families the Dual_X class system actually filters on.
	//
	// ONLY the original seven. Every other family -- melee, launcher,
	// energy, BFG, railgun, flamethrower -- is identity only and is never
	// filtered, which keeps heavy ordnance universal (the documented
	// design) and keeps the imported GunstarHeroes / MeatGrinder sets
	// spawning for every class, exactly as they did when they all still
	// returned EVR_Family_None.
	//
	// This is the ONE place that decides gated-vs-not. When the class
	// system is redone so every weapon can be a candidate, change this
	// function -- not GetFamily() on 30+ weapon files.
	//
	// Comparison chain, not a static const table: this engine build
	// doesn't resolve `static const TYPE name[] = {...}` in a class body.
	static bool IsGatedFamily(EVR_Family f)
	{
		return f == EVR_Family_Pistol
		    || f == EVR_Family_Revolver
		    || f == EVR_Family_Rifle
		    || f == EVR_Family_SMG
		    || f == EVR_Family_Shotgun
		    || f == EVR_Family_SuperShotgun
		    || f == EVR_Family_Chaingun;
	}

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

		// Not a gated family -- never reached from the handler below,
		// which checks IsGatedFamily() first. Empty means "leave nothing".
		return "";
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		super.WorldThingSpawned(e);

		// AN ELITE DROP'S PAYLOAD IS EXEMPT FROM BOTH PASSES BELOW.
		//
		// RS_WeaponDrop spawns a real class weapon into the world to be its
		// own marker. That spawn comes straight through here, so on any
		// Dual_X class the gating below destroyed four of the six possible
		// drops before Spawn() even returned -- silently, leaving a Clip on
		// the floor where the pedestal should have been. The Vanilla+ swap
		// above would eat it too.
		//
		// The flag is set only for the duration of that one Spawn call
		// (RS_EliteDrop.zs, RS_WeaponDrop.Create), so nothing else can slip
		// through behind it. It lives on the handler because ZScript has no
		// mutable statics.
		let dh = RS_PanelDropHandler(EventHandler.Find("RS_PanelDropHandler"));
		if (dh && dh.mSpawningDrop)
			return;

		// Vanilla+ Options world-spawn substitution -- runs first, on the
		// actual spawned thing, before class gating even looks at it. If
		// a swap fires, e.Thing gets destroyed and replaced; the original
		// never reaches the gating check below at all.
		if (RS_VanillaPlusSwaps.TrySwap(e))
			return;

		let wep = RS_Weapon(e.Thing);
		if (!wep || wep.owner || !IsGatedFamily(wep.GetFamily()))
			return;

		// consoleplayer is deliberate, not a multiplayer oversight -- this
		// project is singleplayer/VR-only, confirmed with the dev.
		let pawn = players[consoleplayer].mo;
		if (!pawn)
			return;

		let pc = VR_DualClassBase(pawn);
		EVR_Family allowed = pc ? pc.GetFamily() : EVR_Family_None;

		// EVR_Family_None here means "not a gated class" (Vanilla+, or no
		// class system in play) -- let everything through.
		if (allowed == EVR_Family_None)
			return;

		// A mismatch is REPLACED, not deleted. Playing Dual_Revolver, the
		// pistol/SMG/chaingun/shotgun/SSG/rifle pickups don't spawn -- but
		// what's left behind is ammo you can actually use, not an empty
		// floor. Deleting outright was the old behaviour and it silently
		// stripped pickups out of every map.
		if (wep.GetFamily() != allowed)
		{
			string ammo = AmmoForFamily(allowed);
			if (ammo != "")
				Actor.Spawn(ammo, wep.Pos, ALLOW_REPLACE);
			wep.Destroy();
		}
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

	static play bool TrySwapPair(WorldEvent e, string actualClass, string baseClass, string cvarName, string swapToClass)
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
	static play bool TryRandomBFG(WorldEvent e, string actualClass)
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
		if (repl)
		{
			repl.angle = e.Thing.angle;
			Console.Printf("Vanilla+: Random BFG world spawn -> %s.", newClass);
		}
		e.Thing.Destroy();
		return true;
	}

	static play bool TrySwap(WorldEvent e)
	{
		if (!e.Thing)
			return false;
		string cls = e.Thing.GetClassName();

		if (TryRandomBFG(e, cls))
			return true;

		if (TrySwapPair(e, cls, "RS_GH_Chainsaw", "rs_vp_swap_flamethrower_chainsaw", "RS_GH_Flamethrower")) return true;
		if (TrySwapPair(e, cls, "RS_GH_SSG", "rs_vp_swap_autoshotgun_ssg", "RS_GH_AssaultShotgun")) return true;
		if (TrySwapPair(e, cls, "RS_GH_RocketLauncher", "rs_vp_swap_grenadelauncher_rocketlauncher", "RS_GH_GrenadeLauncher")) return true;
		if (TrySwapPair(e, cls, "RS_GH_Plasma", "rs_vp_swap_railgun_plasmarifle", "RS_GH_Railgun")) return true;

		// Minigun has two independent possible substitutes.
		string suf = IdentitySuffix(cls, "RS_GH_Minigun");
		if (suf != "not-a-match")
		{
			let cv1 = CVar.GetCVar("rs_vp_swap_rifle_minigun", null);
			int c1 = cv1 ? cv1.GetInt() : 0;
			if (c1 > 0 && Random(1, 100) <= c1)
			{
				let repl = Actor.Spawn("RS_GH_Rifle" .. suf, e.Thing.pos);
				if (repl) { repl.angle = e.Thing.angle; Console.Printf("Vanilla+: world spawn swapped %s -> RS_GH_Rifle%s.", cls, suf); }
				e.Thing.Destroy();
				return true;
			}
			let cv2 = CVar.GetCVar("rs_vp_swap_machinegun_minigun", null);
			int c2 = cv2 ? cv2.GetInt() : 0;
			if (c2 > 0 && Random(1, 100) <= c2)
			{
				let repl = Actor.Spawn("RS_GH_Machinegun" .. suf, e.Thing.pos);
				if (repl) { repl.angle = e.Thing.angle; Console.Printf("Vanilla+: world spawn swapped %s -> RS_GH_Machinegun%s.", cls, suf); }
				e.Thing.Destroy();
				return true;
			}
		}

		return false;
	}
}
