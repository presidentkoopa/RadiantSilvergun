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
	// The card rs_card is currently showing, so a second call can take it
	// away. Held on the handler and not on an actor: this card has no
	// pedestal to die with, which is exactly what makes it useful.
	RS_BBComposedPanel mShown;

	override void NetworkProcess(ConsoleEvent e)
	{
		Super.NetworkProcess(e);

		// -----------------------------------------------------------------
		// WHY IS THERE NO CARD. Prints the whole chain in one go, because
		// every guess so far has been made from a screenshot and every one
		// has been wrong. Each line answers exactly one question, in the
		// order the card actually comes into being.
		// -----------------------------------------------------------------
		if (e.Name == "rs_drop_diag")
		{
			let pawn = players[e.Player].mo;
			if (!pawn) return;

			Console.Printf("\c[GOLD]===== RS DROP DIAG =====");

			// 1. Is there a drop in the world at all, and how far away?
			int drops = 0;
			double nearest = 1e9;
			ThinkerIterator it = ThinkerIterator.Create("RS_WeaponDrop", Thinker.STAT_DEFAULT);
			Actor a;
			while (a = Actor(it.Next()))
			{
				drops++;
				double dd = (a.pos - pawn.pos).Length();
				if (dd < nearest) nearest = dd;
				Console.Printf("  drop #%d  dist %.1f  pos (%.0f,%.0f,%.0f)",
					drops, dd, a.pos.x, a.pos.y, a.pos.z);
			}
			Console.Printf("  drops in level: %d", drops);

			// 2. The distances that decide the bloom.
			Console.Printf("  radius %.1f  near %.1f  ramp %.1f  minscale %.3f",
				RS_PanelController.CardRadius(),
				RS_PanelController.CardNear(),
				RS_PanelController.CardRamp(),
				RS_PanelController.CardMinScale());

			// The three switches that can silently mean "no card ever".
			// enabled=false stops ConsiderDrop dead; composed=false sends
			// the card down the painted-canvas path instead of the
			// billboard one; solo changes how many panels exist.
			// int(), not the bare bool: %d with a bool is not a documented
			// Printf conversion here, and the failure would be a garbage
			// number in the one line that is supposed to settle an argument.
			Console.Printf("  enabled=%d  composed=%d  solo=%d",
				RS_PanelController.Enabled() ? 1 : 0,
				RS_PanelController.Composed() ? 1 : 0,
				RS_PanelController.SoloCard() ? 1 : 0);

			// What the ramp would compute RIGHT NOW for the nearest drop --
			// the actual number that decides whether you can see anything.
			if (drops > 0)
			{
				double outer = RS_PanelController.CardRadius();
				double inner = clamp(RS_PanelController.CardNear(), 1.0, outer - 1.0);
				double ramp  = min(RS_PanelController.CardRamp(), outer - inner);
				double fardist = inner + max(1.0, ramp);
				double t = clamp((nearest - inner) / (fardist - inner), 0.0, 1.0);
				double s = 1.0 - t * (1.0 - RS_PanelController.CardMinScale());
				Console.Printf("\c[GOLD]  nearest %.1f -> t %.2f -> SCALE %.3f  (1.0 = full size)",
					nearest, t, s);
			}

			// 3. Did a card ever get BUILT, and does it still exist?
			let ph = RS_PanelDropHandler(EventHandler.Find("RS_PanelDropHandler"));
			if (!ph)
			{
				Console.Printf("\c[RED]  RS_PanelDropHandler NOT FOUND -- nothing can build a card.");
				return;
			}

			Console.Printf("  card=%s  owner=%s",
				ph.mCard ? "YES" : "\c[RED]NULL\c-",
				ph.mCardOwner ? "YES" : "\c[RED]NULL\c-");

			// 4. If it exists, how big is it RIGHT NOW and where.
			if (ph.mCard && ph.mCard.mAsm)
			{
				Console.Printf("  panels: %d   baseW recorded: %d",
					ph.mCard.mAsm.Size(), ph.mCardBaseW.Size());

				for (int i = 0; i < ph.mCard.mAsm.Size(); i++)
				{
					let p = ph.mCard.mAsm.Get(i);
					if (!p) { Console.Printf("   [%d] null", i); continue; }
					Console.Printf("   [%d] %.3f x %.3f  backend %d  composed=%s",
						i, p.mWidth, p.mHeight, p.mBackend,
						p.mComposed ? "yes" : "NO");
				}
			}
			Console.Printf("\c[GOLD]========================");
			return;
		}

		// -----------------------------------------------------------------
		// THE CARD, IN YOUR FACE, NOW.  netevent rs_card [tier]
		//
		// Builds RS_BBWeaponCard straight into the world at FULL SCALE and
		// places it in front of the player. No drop, no pedestal, no
		// triptych, no distance ramp -- every one of which is a place the
		// card can fail to appear for reasons that have nothing to do with
		// how the card LOOKS.
		//
		// That separation is the whole point: if this shows a card and
		// `rs_drop` does not, the card is fine and the delivery chain is
		// broken. If this shows nothing either, the card itself is broken.
		// One command, and the two halves stop being confused.
		// -----------------------------------------------------------------
		if (e.Name == "rs_card")
		{
			let pawn = players[e.Player].mo;
			if (!pawn) return;

			if (mShown)
			{
				mShown.ReleaseAll();
				mShown = null;
				Console.Printf("\c[GOLD][RS CARD]\c- cleared.");
				return;
			}

			int tier = clamp(e.Args[0], VRT_Cursed, VRT_Prototype);

			// A real weapon so the card has real numbers to draw.
			class<Weapon> what = PickWeapon();
			let wep = Weapon(Actor.Spawn(what, pawn.pos));
			if (!wep)
			{
				Console.Printf("\c[RED][RS CARD]\c- could not spawn a weapon.");
				return;
			}
			// Off the floor and out of the way -- it exists only to be read.
			//
			// bNOSECTOR/bNOBLOCKMAP are READ-ONLY: they decide which world
			// lists the actor is linked into, so assigning them would leave
			// it in a list the flag says it is not in. The engine's supported
			// route is A_ChangeLinkFlags(blockmap, sector), which unlinks,
			// flips the flags and relinks -- the same call Inventory uses to
			// hide a picked-up item (inventory.zs:372).
			wep.A_ChangeLinkFlags(1, 1);
			wep.bINVISIBLE = true;
			let rsw = RS_Weapon(wep);
			if (rsw) rsw.RollStats(tier);

			double w = RS_PanelController.PanelWidth();
			double h = RS_PanelController.PanelHeight();

			mShown = new("RS_BBComposedPanel");
			RS_BBWeaponCard.Build(mShown, w, h, wep, "DROP");

			// Eye height, one card-width out, facing back at the player.
			double yaw = pawn.angle;
			Vector3 fwd = (cos(yaw), sin(yaw), 0);
			// viewz is absolute world Z, not an offset -- the drop path uses
			// it that way at RS_EliteDrop.zs:1299.
			Vector3 at  = (pawn.pos.x, pawn.pos.y, pawn.player.viewz) + fwd * 40.0;

			mShown.Place(at, yaw + 180, 0);

			Console.Printf("\c[GOLD][RS CARD]\c- %s tier %d, %.1f x %.1f at (%.0f,%.0f,%.0f). "
				.. "'netevent rs_card' again to clear.",
				what.GetClassName(), tier, w, h, at.x, at.y, at.z);
			return;
		}

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
			// JUST OUTSIDE THE BLOOM, NOT ACROSS THE ROOM.
			//
			// This was 96 and that made the command useless: the card only
			// starts growing at rs_drop_cardnear + rs_drop_cardramp, which
			// ships as 10 + 24 = 34 units, and below that it sits at
			// rs_drop_cardminscale = 0.02. At 96 units the card was a 2%
			// speck -- correct behaviour, invisible result, and it read as
			// "the cards don't spawn".
			//
			// 44 puts the drop a step outside the bloom, so walking toward
			// it is the whole test. Spaced tighter for the same reason.
			double side = (i - (count - 1) * 0.5) * 34.0;
			Vector3 at = pawn.pos + fwd * 44.0 + rgt * side;

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
	// second definition is the thing that goes stale. AllActorClasses is walked
	// once per call, which is fine for a debug command fired by hand.
	private class<Weapon> PickWeapon()
	{
		Array<class<Weapon> > pool;

		for (int i = 0; i < AllActorClasses.Size(); i++)
		{
			let c = (class<RS_Weapon>)(AllActorClasses[i]);
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
