// =====================================================================
// RS_DropTest -- put a weapon drop in front of me, right now.
// ---------------------------------------------------------------------
// Built 2026-08-09, because the owner asked "what card?" and the honest
// answer was that there was no way to make one appear.
//
// RS_WeaponDrop.Create() is reachable only from the elite death path, so
// SEEING A CARD meant finding an elite, killing it, and hoping the tier
// rolled something interesting. That is a fine way to meet a drop in a
// run and a hopeless way to iterate on how the card LOOKS -- which is
// the actual work right now.
//
// `summon RS_WeaponDrop` does not substitute for this. It spawns the
// actor with no weapon and no tier, so the card composes from nothing
// and draws "<heading> EMPTY" -- which looks exactly like a broken card
// and would send someone hunting a bug that is not there.
//
// ---------------------------------------------------------------------
// USAGE
//
//   netevent rs_drop                 a random weapon at a random tier
//   netevent rs_drop,<tier>          0 Cursed .. 7 Prototype
//   netevent rs_drop,<tier>,<n>      n of them, in a row, for comparing
//                                    tier colours side by side
//
// Bind it if you are iterating:  bind p "netevent rs_drop,7"
// =====================================================================

class RS_DropTestHandler : EventHandler
{
	override void NetworkProcess(ConsoleEvent e)
	{
		Super.NetworkProcess(e);

		if (e.Name != "rs_drop")
			return;

		let pawn = players[e.Player].mo;
		if (!pawn)
			return;

		// Args are 0 when omitted, and 0 is also a legal tier (Cursed), so
		// "omitted" cannot be distinguished from "asked for Cursed" here.
		// Deliberately resolved in favour of the explicit request: someone
		// typing rs_drop,0 means Cursed, and someone typing bare rs_drop
		// gets a random tier because e.Args[1] is 0 and the count branch
		// below treats <1 as 1.
		int tier  = clamp(e.Args[0], VRT_Cursed, VRT_Prototype);
		bool roll = (e.Args[0] == 0 && e.Args[1] == 0 && e.Args[2] == 0);
		int count = max(1, e.Args[1]);

		// In front of the player, on the floor plane, far enough out that
		// the card has somewhere to grow into. Spaced along their right so
		// several tiers can be compared without walking.
		double yaw = pawn.angle;
		Vector3 fwd = (cos(yaw), sin(yaw), 0);
		Vector3 rgt = (cos(yaw - 90), sin(yaw - 90), 0);

		for (int i = 0; i < count; i++)
		{
			double side = (i - (count - 1) * 0.5) * 56.0;
			Vector3 at = pawn.pos + fwd * 96.0 + rgt * side;

			int useTier = roll ? random(VRT_Cursed, VRT_Prototype) : tier;

			class<Weapon> what = PickWeapon();
			if (!what)
			{
				Console.Printf("\c[RED][RS DROP]\c- no RS_Weapon classes found.");
				return;
			}

			let d = RS_WeaponDrop.Create(at, what, useTier);
			if (!d)
			{
				Console.Printf("\c[RED][RS DROP]\c- Create() returned null.");
				return;
			}

			Console.Printf("\c[GOLD][RS DROP]\c- %s, tier %d (%s)",
				what.GetClassName(), useTier, RS_UIStyle.TierName(useTier));
		}
	}

	// A random concrete weapon from the whole class tree.
	//
	// Walked rather than hardcoded: a hardcoded name is a second list of
	// what weapons exist, and this project's own rules are explicit that a
	// second definition is the thing that goes stale. AllClasses is walked
	// once per call, which is fine for a debug command fired by hand.
	private class<Weapon> PickWeapon()
	{
		Array<class<Weapon> > pool;

		for (int i = 0; i < AllClasses.Size(); i++)
		{
			let c = (class<RS_Weapon>)(AllClasses[i]);
			if (!c)
				continue;

			// Abstract-in-spirit bases carry no sprites and would drop an
			// invisible object. GetDefaultByType is the only honest test
			// available from script -- a class with no Tag is not something
			// meant to be held.
			let def = GetDefaultByType(c);
			if (!def || def.GetTag() == "")
				continue;

			pool.Push(c);
		}

		if (pool.Size() == 0)
			return null;
		return pool[random(0, pool.Size() - 1)];
	}
}
