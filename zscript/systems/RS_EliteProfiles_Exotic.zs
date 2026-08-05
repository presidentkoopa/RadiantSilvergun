// =====================================================================
// RS_EliteProfiles_Exotic -- the four profiles that break a rule.
// ---------------------------------------------------------------------
// DarkRed, Pink, Indigo and Gold. Everywhere else in the set a profile is
// a stat change, a projectile, or a thing dripped on the floor. These four
// are the ones that touch the fight's PREMISE: one of them is not dead
// when it looks dead, one un-kills what you already killed, one is four
// monsters pretending to be one, and one turns the room into its armour.
//
// They share a file because they share a hazard, not a shape. Every one of
// them can produce an infinite loop, an unkillable monster, or a monster
// that never dies properly, and the guards against those are the majority
// of the code below. Read the guard paragraphs before changing anything:
// most of them look like paranoia and every one is load-bearing.
//
// NONE OF THESE EXIST TO THE ENGINE YET. A profile is reachable only once
// this file is in zscript.txt's include list AND the class has a case in
// RS_EliteRoster with Count() bumped to match (RS_Elites.zs:127). A .zs
// that is not included does not error -- the classes are simply not there.
// Both edits are outside this file on purpose.
//
// HOW THE HOOKS LAND HERE. OnSelected and OnReveal BOTH fire at reveal,
// OnSelected first, and GetShade() is read BEFORE either of them
// (RS_Elites.zs:493). So GetShade may not depend on OnSelected having run,
// and a profile only ever exists on a monster that has already woken up.
// That last point does real work in this file: the awake/asleep split
// these four were designed around collapses to "always awake" here, so
// every branch that asked whether the monster had woken up is simply the
// awake branch now. DarkRed is where that shows -- see its comment.
//
// COLOUR IS GetShade() AND NOTHING ELSE. The body is never tinted: our
// monster art is bespoke per tier and a tint on top of bespoke art
// corrupts it (RS_Elites.zs:171). THAT RULE FOLLOWS THE EFFECT, NOT THE
// ACTOR -- Gold converts OTHER monsters, and those are bespoke art too, so
// its conversion changes their behaviour and never their palette.
//
// PROFILES THAT CHANGE HEALTH ALSO MOVE StartHealth, and the controller's
// boostedMax with it, so the health bar stays honest and the controller's
// own record of the monster stays true (RS_Elites.zs:376).
// =====================================================================

// =====================================================================
// DARKRED -- it dies, and it is lying.
//
// THE MECHANIC, because it is not readable from the code alone: DarkRed
// cannot be killed by damage. At the moment the killing blow lands it
// bursts into blood, vanishes completely, and leaves a small destructible
// body where it was standing. The real monster is still alive at 1 HP; it
// is hidden, unshootable, and parked in a far corner of the map with its
// animation frozen. Three seconds later it comes back to the body's
// position, screams, and gets up with two thirds of its health.
//
// THE COUNTER-PLAY IS THE WHOLE PROFILE: destroy the body. It has 30 HP
// and one shot of anything does it. Destroy it inside those three seconds
// and the real monster is dragged back to that spot and killed for good.
// Ignore it and you fight the thing again. That is the entire design: a
// three-second window where the correct move is to shoot a corpse.
//
// WHY THE REAL MONSTER IS MOVED AT ALL. It has to keep thinking -- the
// controller and this profile both tick off it -- but it must not be
// hittable, must not block, and must not eat splash meant for the body
// standing in its place. Turning it off is not an option; getting it out
// of the room is. The corner is arbitrary and far.
// =====================================================================

// ---------------------------------------------------------------------
// The stand-in. A 30 HP prop wearing the monster's own corpse frame.
//
// IT HAS NO ART OF ITS OWN, DELIBERATELY. At spawn it walks the monster's
// Death sequence and copies the last VISIBLE frame of it, plus scale,
// translation, alpha and blood colour. So a zombieman leaves a zombieman's
// body and a mancubus leaves a mancubus's, with no per-tier corpse sprite
// to author and nothing that can fail to resolve -- every frame it can
// possibly use is a frame the monster itself already ships.
//
// The 16x16 hitbox is deliberately small and independent of the monster:
// it is a stump to shoot, not an obstacle to walk around, and a big
// monster's body should not keep blocking the corridor it died in.
// ---------------------------------------------------------------------
class RS_EliteStandIn : Actor
{
	Default
	{
		Health 30;
		Radius 16;
		Height 16;
		+SOLID
		+SHOOTABLE
		+ISMONSTER
		+NOICEDEATH
		+DONTGIB
	}

	// Copy everything that makes this read as THIS monster's body.
	void SetupFrom(Actor src)
	{
		if (!src)
		{
			Destroy();
			return;
		}

		translation = src.translation;
		CopyBloodColor(src);
		Scale = src.Scale;
		alpha = src.alpha;
		angle = src.angle;

		// Fallback: whatever it was showing when it "died".
		sprite = src.sprite;
		frame  = src.frame;

		// Then look for something better -- the frame the monster's own
		// death animation comes to rest on. Sprite index 0 is the empty
		// sprite, so a death that ends by vanishing is skipped and the
		// fallback above stands. The step cap is not decoration: a Death
		// sequence is free to loop, and following NextState off the end of
		// one that does would never return.
		State s = src.FindState("Death");
		for (int i = 0; s && i < 64; i++)
		{
			if (s.sprite != 0)
			{
				sprite = s.sprite;
				frame  = s.frame;
			}

			if (s.Tics < 0)
				break;

			s = s.NextState;
		}
	}

	States
	{
	Spawn:
		"####" "#" -1;
		Stop;
	Death:
		"####" "#" 0
		{
			for (int i = 0; i < 32; i++)
				A_SpawnItemEx("Blood",
				              xvel: FRandom(3.0, 8.0),
				              zvel: FRandom(4.0, 8.0),
				              angle: FRandom(0.0, 359.9),
				              flags: SXF_USEBLOODCOLOR);
		}
		// Held empty for a second before removal so the profile always has
		// a live pointer to notice the destruction through.
		TNT1 A 35;
		Stop;
	}
}

class RS_EliteProfile_DarkRed : RS_EliteProfile
{
	Actor   standIn;        // the body the player is meant to shoot
	bool    hidden;         // real monster is parked and pretending
	int     restics;        // tics left before it gets up
	int     baseTics;       // what restics is reloaded from
	Vector3 hidePos;        // where the fake death happened
	double  keptAlpha;      // the monster's own alpha, restored on return

	// HOW MANY TIMES IT MAY PULL THIS. One. See the guard paragraph in
	// OnTick -- this is the anti-softlock number and it is the only knob
	// that needs moving if the trick should be repeatable.
	int fakeDeathsLeft;

	color shade;
	bool  shadePicked;

	override color GetShade()
	{
		// ROLLED ONCE AND KEPT. The controller reads this at reveal to fix
		// the aura and pentagram colour for the elite's whole life; a fresh
		// roll per call would strobe the moment anything asked twice.
		//
		// A SWITCH, NOT AN ARRAY -- `static const color x[] = {...}` does
		// not resolve on this engine build. See the note in RS_Elites.zs.
		// The darkest two entries read as almost no aura at all on a dark
		// map. That is kept: an elite you can barely see coming is on
		// theme for the one that fakes its own death.
		if (!shadePicked)
		{
			shadePicked = true;
			switch (random(0, 4))
			{
				case 0:  shade = "E62E00"; break;
				case 1:  shade = "B32400"; break;
				case 2:  shade = "801A00"; break;
				case 3:  shade = "4D0F00"; break;
				default: shade = "1A0500"; break;
			}
		}
		return shade;
	}

	override void OnSelected()
	{
		// Set before the guard: these are ours, not the monster's, and
		// they should be right even if the actor went away.
		//
		// Every tic. The fake death has to trigger on the exact tic the
		// killing blow lands or the monster is briefly a 1 HP punching bag.
		tickInterval   = 1;
		baseTics       = 105;   // three seconds to shoot the body
		fakeDeathsLeft = 1;

		if (!mon)
			return;

		// The flag that makes all of it possible: damage floors its health
		// at 1 instead of killing it. Cleared again the moment the trick is
		// spent, so the last death is a real one.
		mon.bBUDDHA = true;

		// It sounds gibbed rather than killed, because what the player is
		// meant to believe is that it came apart.
		mon.DeathSound = "misc/gibbed";
	}

	// No OnReveal. There is nothing to upgrade: the trick is the profile,
	// and a second charge of it is exactly what the guard below exists to
	// prevent.

	// The blood burst. Fires twice per cycle -- once when it goes down and
	// once when it gets back up -- and it is the only thing selling either.
	private void RS_EliteBloodBurst()
	{
		if (!mon)
			return;

		for (int i = 0; i < 32; i++)
			mon.A_SpawnItemEx("Blood",
			                  xvel: FRandom(3.0, 8.0),
			                  zvel: FRandom(4.0, 8.0),
			                  angle: FRandom(0.0, 359.9),
			                  flags: SXF_USEBLOODCOLOR);
	}

	private bool RS_EliteStandInLives()
	{
		return standIn && !standIn.bDestroyed;
	}

	private int RS_EliteFullHealth()
	{
		if (ctl && ctl.boostedMax > 0)
			return ctl.boostedMax;
		if (mon)
			return mon.SpawnHealth();
		return 0;
	}

	// -----------------------------------------------------------------
	// Going down.
	// -----------------------------------------------------------------
	private void RS_EliteFakeDeath()
	{
		hidePos = mon.Pos;
		RS_EliteBloodBurst();

		hidden  = true;
		restics = baseTics;
		fakeDeathsLeft--;

		// Spawned before the monster moves, so it lands exactly where the
		// monster was standing rather than where it is about to be.
		let body = RS_EliteStandIn(mon.Spawn("RS_EliteStandIn", mon.Pos, ALLOW_REPLACE));
		if (body)
			body.SetupFrom(mon);
		standIn = body;

		mon.bSOLID        = false;
		mon.bSHOOTABLE    = false;
		mon.bNOTARGET     = true;
		mon.bNOTAUTOAIMED = true;
		mon.bNEVERTARGET  = true;
		mon.bINVISIBLE    = true;

		// bINVISIBLE hides the monster; it does NOT hide the aura, which
		// respawns off the monster every tic and copies its sprite, frame
		// and ALPHA (RS_Elites.zs:211). Zeroing alpha is what stops a
		// stack of stencil ghosts of a "dead" monster from being drawn in
		// the corner it is parked in -- an aura ghost inheriting alpha 0
		// destroys itself on its first fade tic.
		keptAlpha = mon.alpha;
		mon.alpha = 0;

		mon.Vel  = (0, 0, 0);
		mon.tics = -1;           // freeze the animation where it stands

		mon.SetOrigin((16384.0, 16384.0, 0.0), false);
	}

	// -----------------------------------------------------------------
	// Coming back -- position, visibility and physics only. Both exits
	// from the hidden state go through here so neither can forget one.
	// -----------------------------------------------------------------
	private void RS_EliteReturnBody(Vector3 at)
	{
		hidden = false;

		mon.SetOrigin(at, false);

		// 105 tics of gravity accumulate on a frozen actor parked at z 0.
		// Without this it returns with all of it and slams into the floor.
		mon.Vel = (0, 0, 0);

		mon.alpha         = keptAlpha;
		mon.bSOLID        = mon.Default.bSOLID;
		mon.bSHOOTABLE    = mon.Default.bSHOOTABLE;
		mon.bNOTAUTOAIMED = mon.Default.bNOTAUTOAIMED;
		mon.bNEVERTARGET  = mon.Default.bNEVERTARGET;
		mon.bINVISIBLE    = mon.Default.bINVISIBLE;

		// NOT restored to its default: the controller SETS bNOTARGET on
		// every elite at reveal (RS_Elites.zs:453). Handing it back to the
		// actor default here would quietly cancel an elite property that
		// this profile does not own.
		mon.bNOTARGET = true;
	}

	override void OnTick()
	{
		if (!mon)
			return;

		if (!hidden)
		{
			// <= rather than == : identical under BUDDHA, which floors at
			// exactly 1, and it cannot be stepped over by anything that
			// sets health directly.
			if (mon.health <= 1 && fakeDeathsLeft > 0)
				RS_EliteFakeDeath();
			return;
		}

		// ----- hidden from here down -----

		// THE STRANDING GUARD, and the reason this branch is first.
		//
		// Everything that gets the monster out of hiding is keyed to the
		// stand-in. If the stand-in disappears without being killed -- a
		// crusher, a map script, anything that removes an actor outright --
		// then the "it was destroyed" test never fires, the get-up test
		// requires it to still exist, and the real monster sits invisible
		// and unshootable in the corner of the map forever, holding a kill
		// the level cannot complete. So a stand-in that is GONE counts as
		// a stand-in that was DESTROYED, and the body comes back to where
		// the fake death happened rather than to a corpse that no longer
		// has a position.
		bool gone = !RS_EliteStandInLives();

		if (gone || standIn.health < 1)
		{
			Vector3 back = hidePos;
			if (!gone)
				back = standIn.Pos;

			RS_EliteReturnBody(back);

			// The permanent death. BUDDHA off first or the kill floors at
			// 1 and we are straight back where we started.
			mon.bBUDDHA   = false;
			mon.bSPECTRAL = false;
			mon.tics      = 1;
			mon.A_Die();
			return;
		}

		restics--;
		if (restics >= 0)
			return;

		// ----- it gets up -----
		RS_EliteReturnBody(standIn.Pos);

		// The gib scream, on the way UP. It is the sound of something
		// pulling itself back out of its own corpse, and it is the cue
		// that the three-second window was missed.
		mon.A_StartSound("misc/gibbed", CHAN_VOICE);

		mon.SetStateLabel("Spawn");
		mon.tics = 1;

		// TWO THIRDS OF ITS FULL POOL BACK.
		//
		// This is the one place in the set where the awake/asleep split
		// mentioned in the file header is visible. The fraction was
		// written as a choice between a third asleep and two thirds awake,
		// read inline at the moment of standing up rather than through the
		// reveal hook -- which is why this profile has no OnReveal at all.
		// A profile here only exists on a monster that has already woken
		// up, so the third is unreachable and two thirds is simply what
		// this is. The other value is recorded here and nowhere else.
		//
		// Floored at 1: two thirds of a tiny pool rounds to zero, and a
		// monster standing up with zero health is one that can never die
		// properly afterwards.
		mon.health = max(1, int(RS_EliteFullHealth() * 0.66));

		RS_EliteBloodBurst();

		if (RS_EliteStandInLives())
			standIn.Destroy();
		standIn = null;

		// THE ANTI-SOFTLOCK GUARD.
		//
		// The trick is self-renewing by nature: it destroys its own body
		// on the way up, so the next killing blow would spawn a fresh one
		// and it would do this forever. That is fine exactly as long as
		// the player can always reach the body -- and they cannot. A body
		// that lands in lava, over a ledge, or behind a door that closed
		// is a monster that cannot be killed at all, on a map that may
		// need it dead. One charge: the second time it reaches 1 HP,
		// BUDDHA is already gone and it dies like anything else.
		if (fakeDeathsLeft <= 0)
			mon.bBUDDHA = false;
	}

	// The stand-in must never outlive the profile. If the monster is
	// killed by something BUDDHA does not stop -- a telefrag, a massacre,
	// the map ending it -- the controller calls this and the body would
	// otherwise be left standing as a shootable prop with nothing behind
	// it. Only if it is still alive: on the destroyed path it is already
	// mid-burst and cutting that short would delete the one visual that
	// tells the player they won.
	override void OnDeath()
	{
		if (RS_EliteStandInLives() && standIn.health > 0)
			standIn.Destroy();
		standIn = null;
	}
}

// =====================================================================
// PINK -- it un-kills what you already killed, and it pays for it.
//
// THE MECHANIC: every two seconds it sweeps for corpses within a few body
// widths, and stands every one of them back up. Each raise costs it a
// fifth of its own maximum health, taken as real damage, so it flinches
// visibly every time it does this. It will not spend its last fifth,
// which caps it at four raises per life and makes the arithmetic the
// player's lever: a pink elite standing over a pile of bodies is a timer,
// not a wall.
//
// FIGHT IT SECOND. The real cost of ignoring one is that everything else
// in the room becomes reusable, so the answer is to break the sweep --
// kill it, or fight it somewhere it has nothing to work with.
// =====================================================================
class RS_EliteProfile_Pink : RS_EliteProfile
{
	int radFactor;          // multiples of the monster's radius

	color shade;
	bool  shadePicked;

	override color GetShade()
	{
		// Rolled once and kept, same as DarkRed above.
		if (!shadePicked)
		{
			shadePicked = true;
			switch (random(0, 4))
			{
				case 0:  shade = "FF8AA0"; break;
				case 1:  shade = "FF6682"; break;
				case 2:  shade = "FFCCD5"; break;
				case 3:  shade = "FFB3FF"; break;
				default: shade = "FFFFFF"; break;
			}
		}
		return shade;
	}

	override void OnSelected()
	{
		tickInterval = 70;      // two seconds between sweeps
		radFactor    = 4;
	}

	// Reach doubles. Nothing else changes -- not the cost, not the cadence.
	// Doubling the radius quadruples the area it can work with, which is
	// already the largest single upgrade in the set.
	override void OnReveal()
	{
		radFactor = 8;
	}

	// THE HEALTH THIS PROFILE MEASURES ITSELF AGAINST is the elite's full
	// boosted pool -- the number the reveal refills to and the number its
	// health bar is drawn against. The working notes for this profile
	// carried two different definitions of "starting health" that
	// overwrote each other in load order; neither survives contact with
	// our model, where the monster's whole life happens after a refill to
	// a known maximum. boostedMax is that maximum and there is no second
	// candidate.
	private int RS_EliteFullHealth()
	{
		if (ctl && ctl.boostedMax > 0)
			return ctl.boostedMax;
		if (mon)
			return mon.SpawnHealth();
		return 0;
	}

	override void OnTick()
	{
		if (!mon || mon.health < 1)
			return;

		// The reserve and the price are the same fifth, which is what
		// makes the cap exactly four raises and easy to reason about.
		//
		// Floored at 1. A fifth of a very small health pool rounds to
		// nothing, and a resurrector that pays nothing per raise is a
		// resurrector with no cost and no cap -- the one shape this
		// mechanic must never take.
		int reserve = max(1, int(RS_EliteFullHealth() * 0.2));
		if (mon.health <= reserve)
			return;

		double range = mon.radius * radFactor;

		ThinkerIterator it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (!mo || mo == mon)
				continue;

			// A corpse that still knows how to stand up. FindState is the
			// real test -- plenty of dead things have no Raise sequence and
			// asking the engine to raise one of those is how you get a
			// monster stuck between states.
			if (!mo.bISMONSTER || mo.health >= 1)
				continue;
			if (!mo.FindState("Raise"))
				continue;
			if (mo.Distance2D(mon) >= range)
				continue;

			// GUARD ONE: the never-raise marker. Anything a profile spawned
			// as a copy of something else carries it, so the set cannot
			// build a population out of its own leftovers.
			if (mo.CountInv("RS_EliteNoRevive"))
				continue;

			// GUARD TWO: never raise another elite. An elite's controller
			// destroys itself the moment its monster dies, so a raised one
			// comes back holding the full elite flag set, the damage
			// multiplier and the revealed token, with nothing ticking
			// behind it -- a monster that looks like an elite and cannot
			// behave like one.
			if (mo.CountInv("RS_EliteMark"))
				continue;

			// Raised with ITSELF as the raiser, not with the elite. The
			// raiser is who the corpse copies its allegiance from, and a
			// monster that gets up owing nothing to the thing that woke it
			// is both the behaviour we want and one less way for a friendly
			// elite to quietly build an army.
			if (!mo.RaiseActor(mo))
				continue;

			// GUARD THREE, AND THE IMPORTANT ONE: what it raises, it may
			// never raise again. Without this, one corpse killed and
			// re-raised in place is an infinite loop bounded only by the
			// elite's health bar, and the player is farming the same
			// monster while the elite feeds on itself. One resurrection
			// per body, ever, by anything of ours.
			mo.GiveInventory("RS_EliteNoRevive", 1);

			// The price, as real damage so it flinches and the player can
			// see the exchange happening. Sourced from nothing -- no kill
			// credit and no infighting if the strain ever finishes it.
			mon.A_DamageSelf(reserve, "None", src: AAPTR_NULL);

			// Re-checked after every raise rather than once per sweep. The
			// check at the top only proves it could afford the FIRST one,
			// and a sweep that finds five bodies would otherwise spend
			// five fifths.
			if (!mon || mon.health <= reserve)
				return;
		}
	}

	// THERE IS NO OnHit HERE, DELIBERATELY.
	//
	// A hit-reaction cooldown was drafted for this profile and is not
	// implemented, because what was drafted never ran: the counter was set
	// on every hit, nothing ever decremented it, and the one place that
	// would have read it was commented out. Its entire observable effect
	// was zero, so zero is what is ported. The record is here so it does
	// not get "restored" later as a bug fix -- if a real cooldown is
	// wanted, it is a new design decision, not a repair.
}

// =====================================================================
// INDIGO -- one monster is four monsters, and you find out at the end.
//
// THE MECHANIC: when it dies it splits. Two shrunken copies of itself are
// thrown out of the corpse at 75% health, 75% size, 75% damage and 75%
// hitbox -- four of them once it has revealed. They are the same monster
// class it was, so an indigo mancubus splits into mancubi and an indigo
// zombieman into zombiemen, and nothing had to be authored per monster
// for that to work.
//
// The copies do not count as kills. They are the cost of the kill you
// already made, not four more monsters the map now owes you, and a level
// that counts monsters must still be completable after one of these dies
// in a corner you have already cleared.
// =====================================================================

// Marks a copy. Its only job is to stop a copy from ever splitting again;
// see the guard in OnDeath.
class RS_EliteCloneToken : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}
}

class RS_EliteProfile_Indigo : RS_EliteProfile
{
	Class<Actor> cloneType;
	int          spawnCount;

	color shade;
	bool  shadePicked;

	override color GetShade()
	{
		if (!shadePicked)
		{
			shadePicked = true;
			switch (random(0, 3))
			{
				case 0:  shade = "A081FE"; break;
				case 1:  shade = "7A4EFD"; break;
				case 2:  shade = "B3B3FF"; break;
				default: shade = "C6B3FE"; break;
			}
		}
		return shade;
	}

	// tickInterval stays 0. Indigo does nothing at all until it dies --
	// it is the profile you cannot identify while you are fighting it.

	override void OnSelected()
	{
		if (!mon)
			return;

		// Whatever it is, that is what comes out of it.
		cloneType  = mon.GetClassName();
		spawnCount = 2;
	}

	override void OnReveal()
	{
		spawnCount = 4;
	}

	override void OnDeath()
	{
		if (!mon || !cloneType || spawnCount < 1)
			return;

		// THE LOOP GUARD: A COPY NEVER COPIES.
		//
		// Marking happens once at level load, so a copy spawned mid-level
		// is normally never marked and can never carry this profile at
		// all. Normally. The optional re-sweep timer (rs_elite_resweep)
		// marks everything alive on a clock, and with it on, a copy can be
		// marked, reveal, roll this profile and split again -- two into
		// four into eight into sixteen, on a map the player is still
		// standing in. The token below is checked here rather than trusted
		// to the sweep: this is the file that knows what a copy is, and a
		// guard that depends on an option being off is not a guard.
		if (mon.CountInv("RS_EliteCloneToken"))
			return;

		for (int i = 0; i < spawnCount; i++)
		{
			// The line they come out on, centred on the corpse: with two
			// copies that is 12 units either side, with four it is 24.
			int spawnDist = int(-(12 * spawnCount) * 0.5);

			bool  ok;
			Actor clone;
			[ok, clone] = mon.A_SpawnItemEx(cloneType,
			                                xofs:  random(-12, 12),
			                                yofs:  spawnDist + (12 * i),
			                                xvel:  FRandom(2.0, 4.0),
			                                zvel:  FRandom(4.0, 6.0),
			                                angle: 180.0 + ((360.0 / spawnCount) * i),
			                                flags: SXF_TRANSFERTRANSLATION
			                                     | SXF_NOCHECKPOSITION
			                                     | SXF_TRANSFERPOINTERS);

			if (!clone)
				continue;

			// What makes it a copy rather than a reinforcement.
			clone.GiveInventory("RS_EliteCloneToken", 1);

			// And what stops the set feeding on itself: a copy can never
			// be raised by our resurrector. Two profiles that each look
			// reasonable alone are an infinite monster supply together.
			clone.GiveInventory("RS_EliteNoRevive", 1);

			// Floored at 1 -- three quarters of a 1 HP monster is zero, and
			// a copy spawned at zero health is a live actor that can never
			// die properly.
			clone.health = max(1, int(clone.GetSpawnHealth() * 0.75));

			// Moved with it so the health bar reads a full copy rather
			// than a wounded monster -- it is not damaged, it is smaller.
			clone.StartHealth = clone.health;

			clone.A_SetSize(clone.radius * 0.75, clone.height * 0.75);
			clone.Scale          = clone.Scale * 0.75;
			clone.DamageMultiply = 0.75;
			clone.alpha          = mon.alpha;
			clone.CopyBloodColor(mon);

			// NOTHING COPIES FRIENDLINESS HERE ON PURPOSE. The spawn call
			// above already did it -- a monster spawning a monster transfers
			// allegiance as part of the spawn. Doing it again by hand is not
			// harmless: that function resets the actor's health to full
			// unless its third argument says otherwise, so a second call
			// here would quietly undo the 75% line above and hand the player
			// full-strength copies.

			// They share a species and pass through each other. Four
			// bodies erupting from one corpse would otherwise spend the
			// first second shoving each other apart, and any one of them
			// clipping another's attack would start an infight over a
			// death none of them caused.
			clone.Species          = 'RS_EliteClone';
			clone.bTHRUSPECIES     = true;
			clone.bDONTHARMSPECIES = true;

			// Smaller thing, higher voice.
			clone.GiveInventory("RS_EliteVoiceChanger", 1);
			let vc = RS_EliteVoiceChanger(clone.FindInventory("RS_EliteVoiceChanger"));
			if (vc)
				vc.factor = 1.15;

			// Not a kill. -1 is "leave alone" for the item and secret
			// counters; only the monster count is touched, and this call
			// is what hands back the one the spawn just added, so the
			// level total comes out where it started.
			clone.A_ChangeCountFlags(0, -1, -1);
		}
	}
}

// =====================================================================
// GOLD -- it does not get tougher, the room does.
//
// THE MECHANIC: five times the health, a tenth of the flinch, twelve
// times the mass, no blood, and every animation it plays stretched to
// nearly twice its length. It is the slowest thing in the set and the
// hardest to move. On half of its tics it reaches out a few body widths
// and GILDS every monster it touches: they take a third less damage,
// barely flinch, cannot be pushed, and stop bleeding. Permanently, and
// they keep it after it dies.
//
// SO THE FIGHT IS ABOUT ORDER. Kill it first and the room is normal.
// Leave it in the middle of a crowd and you are fighting the crowd twice.
// The gilding is one-way -- there is no cure and it never wears off --
// which is what stops the profile from being a debuff you can wait out.
//
// THE GILDING IS NOT VISIBLE AS A TINT. Everything it touches is a
// monster with bespoke per-tier art, and the rule against tinting a body
// follows the effect rather than the actor. What a gilded monster gets
// instead is one glint at the moment it turns, from the same sparkle the
// elite itself sheds -- enough to see it happen if you are watching, and
// nothing at all if you are not. That is a real loss of clarity and it is
// the correct trade: a corrupted sprite is worse.
// =====================================================================

// The mark of a gilded monster, and the reason gilding cannot stack.
class RS_EliteGoldToken : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}
}

// ---------------------------------------------------------------------
// The touch itself, in two strengths. Delivered by a radius give, so the
// item IS the effect: it activates on arrival, applies itself once, and
// removes itself. Two classes rather than one parameterised class because
// a radius give hands out a class and cannot hand out a number with it.
//
// The exclusions are the whole safety of it: never a pickup, never a
// weapon spawner, never something already gilded (or the multipliers
// would compound every tic until the room was invulnerable), and never
// the stand-in body DarkRed leaves behind, which is flagged as a monster
// so the player can shoot it and would otherwise be gilded into a prop
// that no longer bleeds when it dies.
// ---------------------------------------------------------------------
class RS_EliteMidasTouch1 : CustomInventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
	}

	States
	{
	Use:
		TNT1 A 0
		{
			// invoker is the item, self is whoever picked it up.
			let o = invoker.owner;
			if (!o)
				return;
			if (o.bSPECIAL || o.bWEAPONSPAWN)
				return;
			if (o is "RS_EliteStandIn")
				return;
			if (o.CountInv("RS_EliteGoldToken"))
				return;

			o.GiveInventory("RS_EliteGoldToken", 1);
			o.Mass         *= 12;
			o.PainChance    = int(o.PainChance * 0.1);
			o.DamageFactor *= 0.66;
			o.bNOBLOOD      = true;

			o.A_SpawnItemEx("RS_EliteSparkle", zofs: o.height * 0.5);
		}
		Stop;
	}
}

// The revealed version. Only the damage factor moves -- a third of
// incoming damage rather than two thirds.
class RS_EliteMidasTouch2 : RS_EliteMidasTouch1
{
	States
	{
	Use:
		TNT1 A 0
		{
			let o = invoker.owner;
			if (!o)
				return;
			if (o.bSPECIAL || o.bWEAPONSPAWN)
				return;
			if (o is "RS_EliteStandIn")
				return;
			if (o.CountInv("RS_EliteGoldToken"))
				return;

			o.GiveInventory("RS_EliteGoldToken", 1);
			o.Mass         *= 12;
			o.PainChance    = int(o.PainChance * 0.1);
			o.DamageFactor *= 0.33;
			o.bNOBLOOD      = true;

			o.A_SpawnItemEx("RS_EliteSparkle", zofs: o.height * 0.5);
		}
		Stop;
	}
}

class RS_EliteProfile_Gold : RS_EliteProfile
{
	// REACH IN WHOLE BODY RADII -- 3, and 5 once revealed. The working
	// numbers were written as 3.0 and 5.0 into an integer, so the
	// fractional part never existed at any point; 3 and 5 are not a
	// rounding of something finer, they are the values. Recorded because
	// the decimal points survive in the notes and look like lost precision.
	int radFactor;

	Class<Inventory> midas;

	// Same once-per-state-change gate the other tic-scaling profile uses.
	// Rescaling every tic instead would multiply the remaining tics faster
	// than the engine decrements them, and the monster would freeze in a
	// single frame forever -- which on THIS profile, the one with five
	// times the health, would be an immortal statue.
	State prevState;

	override void OnSelected()
	{
		tickInterval = 1;       // a state change can fall on any tic

		if (!mon)
			return;

		mon.PainChance = int(mon.PainChance * 0.1);

		// FIVE TIMES. This lands at reveal, on top of a bar the controller
		// has just refilled to boostedMax, so a gold elite is far and away
		// the longest fight in the set -- and the marking ceiling and the
		// bonus cap in RS_Elites.zs do not reach it, because they cap what
		// MARKING adds and this is a profile multiplying the result. It is
		// the number to look at first if gold elites feel like a slog; it
		// is deliberate, not an oversight, and it is why everything else
		// about the profile is defensive rather than offensive.
		mon.health      = int(mon.health * 5.0);
		mon.StartHealth = mon.health;
		if (ctl)
			ctl.boostedMax = mon.health;

		mon.Mass    *= 12;      // effectively unpushable
		mon.bNOBLOOD = true;    // it does not bleed, it chips

		radFactor = 3;
		midas     = "RS_EliteMidasTouch1";
	}

	override void OnReveal()
	{
		radFactor = 5;
		midas     = "RS_EliteMidasTouch2";
	}

	override void OnTick()
	{
		if (!mon || !midas)
			return;

		// Half the tics. At every tic the reach would read as a permanent
		// aura the player never sees the edge of; pulsing it means a
		// monster that walks through the fringe sometimes escapes, and the
		// player can learn roughly where the danger stops.
		if (!random(0, 1))
		{
			mon.A_RadiusGive(midas, mon.radius * radFactor, RGF_MONSTERS, 1);

			// The glint. Rolled at 224-in-256 to FAIL on top of the half
			// gate, so it is roughly one in nine tics: a metallic catch of
			// light, not a particle effect. The offset rides its leading
			// edge; the random angle only sets the glint's own facing.
			mon.A_SpawnItemEx("RS_EliteSparkle",
			                  xofs: mon.radius,
			                  zofs: FRandom(0, mon.height),
			                  angle: random(0, 359),
			                  failchance: 224);
		}

		// tics <= 0 is a state that never advances on its own (-1) or one
		// already due this tic. Scaling either produces nonsense.
		if (mon.health < 1 || mon.tics <= 0)
			return;

		if (prevState != mon.CurState)
			mon.A_SetTics(int(mon.tics * 1.75));

		prevState = mon.CurState;
	}

	// INTENTIONALLY EMPTY -- gold does nothing on death, and what it has
	// already done does not come undone. Every monster it gilded keeps the
	// token, the mass, the pain chance and the damage factor for the rest
	// of the level. That permanence is the profile: an effect the player
	// can outlive is one they can ignore.
	override void OnDeath() {}

	// No colour set was ever designed for this one -- its look was defined
	// by suppressing particles entirely, which our aura does not offer per
	// profile. A white aura would read as "no profile at all", so it gets
	// a single fixed metallic shade rather than an invented palette.
	override color GetShade() { return "FFD700"; }
}
