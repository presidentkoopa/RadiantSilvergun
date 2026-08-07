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
		// HEAVY ORDNANCE CARVE-OUT. Rocket/Plasma/BFG (vanilla or this
		// mod's own VR_ versions) aren't one of the 7 class families and
		// have no per-class identity ladder of their own -- they're
		// governed by the SAME cvar VR_DualClassBase.PostBeginPlay
		// already uses to grant them universally at spawn:
		//
		//   true  -- every class already gets these for free, so a
		//            pedestal stays a universal weapon too. Only
		//            normalised to the VR_ version if it was the
		//            vanilla one, so it carries this mod's stats
		//            instead of stock Doom damage.
		//   false (default) -- the player has no other way to get them,
		//            so they're funnelled into the SAME class-weapon
		//            copy pool as everything else below.
		// -------------------------------------------------------------
		if (IsHeavyOrdnance(wep.GetClassName()))
		{
			if (AllowBigGuns())
			{
				NormalizeHeavyOrdnance(wep);
				return;
			}
			// else fall through -- treated exactly like any other
			// non-owned pickup from here down.
		}

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
		string gap = NextMissingIdentity(pawn, mainhand);
		if (gap != "")
		{
			let repl = Actor.Spawn(mainhand .. gap, wep.pos);
			if (repl)
				repl.angle = wep.angle;
			wep.Destroy();
			return;
		}

		// All six already owned. Leave reserve ammo instead of an empty
		// floor -- this is the old mismatch behaviour, unchanged, just
		// reached by a different condition now.
		string ammo = AmmoForFamily(pc.GetFamily());
		if (ammo != "")
			Actor.Spawn(ammo, wep.pos, ALLOW_REPLACE);
		wep.Destroy();
	}

	static bool AllowBigGuns()
	{
		let cv = CVar.GetCVar("rs_dualclass_allowbigguns", null);
		return cv && cv.GetBool();
	}

	// Switch, not an array -- see the CLAUDE.md caveat quoted above.
	static bool IsHeavyOrdnance(Name cls)
	{
		switch (cls)
		{
			case 'RocketLauncher':
			case 'PlasmaRifle':
			case 'BFG9000':
			case 'VR_RocketLauncher':
			case 'VR_PlasmaRifle':
			case 'VR_BFG9000':
				return true;
			default:
				return false;
		}
	}

	// Vanilla Rocket/Plasma/BFG become this mod's own VR_ version, which
	// carries this mod's stats instead of stock Doom damage. Already a
	// VR_ pickup is left alone -- nothing to normalise.
	static void NormalizeHeavyOrdnance(Weapon wep)
	{
		string vrName;
		switch (wep.GetClassName())
		{
			case 'RocketLauncher': vrName = "VR_RocketLauncher"; break;
			case 'PlasmaRifle':    vrName = "VR_PlasmaRifle";    break;
			case 'BFG9000':        vrName = "VR_BFG9000";        break;
			default: return;
		}
		let repl = Actor.Spawn(vrName, wep.pos);
		if (repl)
			repl.angle = wep.angle;
		wep.Destroy();
	}

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
