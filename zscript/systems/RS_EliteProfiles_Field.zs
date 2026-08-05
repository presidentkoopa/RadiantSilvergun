// =====================================================================
// RS_EliteProfiles_Field -- the four profiles that move things around.
// ---------------------------------------------------------------------
// Cyan, Silver, Grey and Green. Not one of them changes what a monster
// hits for; all four change WHERE THINGS ARE. Cyan shoves the room away
// from it, Silver drags the room into it, Grey sidesteps out of your
// crosshair and lunges back in, and Green crosses fifty paces of floor
// between two tics. They share a file because they share that shape, and
// because the first two share the field code at the top of it.
//
// NONE OF THESE EXIST TO THE ENGINE YET. A profile is reachable only
// once this file is in zscript.txt's include list AND the class has a
// case in RS_EliteRoster with Count() bumped to match (RS_Elites.zs:127).
// A .zs that is not included does not error -- the classes are simply
// not there. Both edits are outside this file on purpose.
//
// HOW THE HOOKS LAND HERE. OnSelected and OnReveal BOTH fire at reveal,
// OnSelected first -- the long form of why is at the top of
// RS_EliteProfiles_Simple.zs. Cyan is where you can watch it happen: its
// wind is 192 for the space of one statement and 384 for the rest of the
// fight. The two methods are kept apart anyway, because the split is
// real -- one is what the profile IS, the other is what waking up buys
// it -- and re-deriving which line was which later is the expensive part.
//
// COLOUR IS GetShade() AND NOTHING ELSE. The body is never tinted; our
// monster art is bespoke per tier and a tint on top of bespoke art
// corrupts it (RS_Elites.zs:171). Each GetShade below records the full
// colour set its look was designed around and then returns ONE fixed
// member of it, because the controller caches a single shade at reveal:
// a random pick would eventually produce a cyan elite that came up white.
//
// PROFILES THAT CHANGE HEALTH ALSO MOVE StartHealth AND boostedMax.
// Silver is the one here that does. The controller deliberately sets
// StartHealth to the boosted maximum so a marked monster's health bar
// reads 100% and gives nothing away (RS_Elites.zs:376); a profile that
// raises health without moving StartHealth hands that back by drawing a
// 125% bar.
// =====================================================================

// ---------------------------------------------------------------------
// RS_EliteField -- the shared radius shove, and the one real decision in
// this file.
//
// THE PROBLEM. Cyan and Silver both want "everything within 384 units is
// being dragged one way, every single tic". The engine's A_RadiusThrust
// does exactly that and would be one line. It cannot be used here, for
// two independent reasons:
//
//   1. ITS ONLY FILTER IS SPECIES. To spare or single out the player it
//      needs a Species stamped on the PlayerPawn, and this project has
//      other systems that read and write Species. A field effect is not
//      allowed to claim a player-wide identifier for its own bookkeeping
//      -- that is a collision waiting to happen in a system that has
//      nothing to do with wind.
//
//   2. AN UNCAPPED PER-TIC IMPULSE IS NOT A FORCE, IT IS A CATAPULT.
//      A_RadiusThrust adds force*falloff*0.5/mass to velocity. At 384
//      force against a 100-mass player that is ~1.9 units/tic ADDED
//      every tic. Standing on the floor, friction settles it around 18
//      units/tic -- faster than a player can run, so you physically
//      cannot walk towards a revealed Cyan elite. In the air there is no
//      friction at all and it just keeps accumulating. This was the
//      failure: the profile did not push the player, it deleted them
//      from the fight.
//
// So the sweep is ours. It reproduces the engine's own filter and
// falloff maths exactly -- shootable things only, distance falloff,
// halved, divided by mass, line-of-sight checked -- and adds the two
// things the engine cannot express:
//
//   * PLAYERS TAKE HALF FORCE. Not zero: being shoved is the whole point
//     of the profile and a field the player cannot feel is a field that
//     is not there. Half.
//   * A SPEED CEILING ALONG THE FIELD AXIS. The field may not drive
//     anything past PLAYERCAP/MONSTERCAP units per tic along its own
//     direction. It never removes speed the target already had -- it
//     only declines to add more -- so a rocket jump or a player's own
//     sprint through the field is untouched. 6.0 units/tic is a little
//     under half a running player, which is the design rule: the field
//     is always something you fight, never a wall you cannot cross.
//
// XY ONLY, deliberately. The engine suppresses the vertical component of
// a thrust-only radius attack, and it is right to: a per-tic upward
// nudge turns a windy room into a trampoline.
// ---------------------------------------------------------------------
class RS_EliteField
{
	// Players take half of whatever a monster takes.
	const PLAYERFORCE = 0.5;

	// Ceilings on the speed the field itself may impart, map units per
	// tic, measured along the field's own axis. The monster figure is
	// loose -- it is a runaway guard, not a balance number.
	const PLAYERCAP  = 6.0;
	const MONSTERCAP = 16.0;

	// Positive force pushes away from src, negative pulls towards it.
	static void Apply(Actor src, double force, double dist)
	{
		if (!src || force == 0 || dist <= 0)
			return;

		BlockThingsIterator it = BlockThingsIterator.Create(src, dist);
		while (it.Next())
		{
			Actor t = it.Thing;
			if (!t || t == src)
				continue;

			// The engine's own radius filter, reproduced. Shootable is
			// doing most of the work: it excludes decorations, items and
			// -- because the flag is cleared on death -- corpses, which
			// is why there is no separate corpse test worth adding.
			if (!t.bSHOOTABLE || t.health <= 0)
				continue;

			// NORADIUSDMG is how the engine spells "this is a set piece,
			// explosions do not move it". Our own boss elites get
			// DONTTHRUST at reveal (RS_Elites.zs:470) and land here too.
			if (t.bDONTTHRUST || t.bNORADIUSDMG || t.bNOCLIP)
				continue;

			// Live projectiles are left alone. A magnet that hoovers up
			// rockets is a fun idea; a wind that blows the player's own
			// rocket back into their face is an invisible damage source
			// nobody can learn to play around.
			if (t.bMISSILE)
				continue;

			Vector2 d   = src.Vec2To(t);
			double  len = d.Length();
			if (len <= 0 || len > dist)
				continue;

			double f   = force;
			double cap = MONSTERCAP;
			if (t.player)
			{
				f  *= PLAYERFORCE;
				cap = PLAYERCAP;
			}

			// Sight last, because it is the expensive test and this runs
			// every tic. IGNOREVISIBILITY so an invisible player is still
			// in the wind; a field that only touches things it can SEE
			// would be a stealth mechanic nobody asked for.
			if (!t.CheckSight(src, SF_IGNOREVISIBILITY | SF_IGNOREWATERBOUNDARY))
				continue;

			double m = t.Mass;
			if (m < 1)
				m = 1;

			double thrust = (f * (1.0 - (len / dist))) * 0.5 / m;

			double dx = d.X / len;
			double dy = d.Y / len;

			// The ceiling. Clamping the component ALONG the field axis,
			// rather than the target's total speed, is what keeps this
			// from fighting the player's own movement.
			double along = t.Vel.X * dx + t.Vel.Y * dy;
			if (thrust > 0)
				thrust = min(thrust, max(0.0, cap - along));
			else
				thrust = max(thrust, min(0.0, -cap - along));

			if (thrust == 0)
				continue;

			t.Vel.X += dx * thrust;
			t.Vel.Y += dy * thrust;
		}
	}
}

// ---------------------------------------------------------------------
// CYAN -- a standing gale. Everything not nailed down is being pushed
// away from it, all the time.
//
// It is the only profile that fights you with the floor rather than with
// damage: it cannot stop you closing, but it makes every step towards it
// cost something, and it scatters the monsters around it into a ring so
// you are never fighting it alone in a tidy corridor.
// ---------------------------------------------------------------------
class RS_EliteProfile_Cyan : RS_EliteProfile
{
	int windforce;

	override void OnSelected()
	{
		// Every tic. A field that gusts on a slower cadence reads as a
		// series of shoves, which is a different and worse effect -- the
		// player learns the rhythm and walks in between them.
		tickInterval = 1;

		windforce = 192;

		if (!mon)
			return;

		// Eight leaves on a 45-degree spread. They are the only reason
		// the wind is legible: the shove itself has no sprite, so without
		// them a player being pushed backwards has nothing to attribute
		// it to and reads it as a bug.
		for (int i = 0; i < 8; i++)
			mon.A_SpawnItemEx("RS_EliteLeaf",
			                  angle: i * 45,
			                  flags: SXF_SETMASTER | SXF_NOCHECKPOSITION);
	}

	override void OnReveal()
	{
		windforce = 384;
	}

	override void OnTick()
	{
		if (!mon)
			return;

		RS_EliteField.Apply(mon, windforce, 384);
	}

	// INTENTIONALLY EMPTY -- Cyan does nothing on death. The leaves
	// notice their master has died on their own and fade out; there is
	// nothing to clean up here and no parting gust. The empty override is
	// the record that a death effect was considered and declined.
	override void OnDeath() {}

	// Designed against ffffff / ccffff / 33ccff. The saturated end: the
	// aura is an additive stencil, so the two pale entries wash out to
	// white against anything bright and stop reading as a colour at all.
	override color GetShade() { return "33CCFF"; }
}

// The wind made visible. Eight of these orbit the elite at its own
// radius, each at its own height and its own distance, so the ring reads
// as turbulence rather than as a fairground carousel.
//
// It orbits by WARPING rather than by moving: 12 degrees of its own angle
// per tic, then a warp to the master offset by that angle. NOINTERACTION
// because it must not collide, must not be shot, and must not cost
// anything -- there are eight of them per elite and they exist for the
// whole fight.
class RS_EliteLeaf : Actor
{
	double orbitdist;
	double orbitheight;

	Default
	{
		+NOINTERACTION
		+FLOATBOB
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		if (master)
		{
			orbitdist   = frandom(master.Radius, master.Radius * 1.5);
			orbitheight = frandom(0, master.Height);
		}
	}

	override void Tick()
	{
		Super.Tick();

		if (master)
		{
			A_SetAngle(angle + 12);
			A_Warp(AAPTR_MASTER,
			       xofs: orbitdist,
			       zofs: orbitheight,
			       flags: WARPF_NOCHECKPOSITION | WARPF_USECALLERANGLE | WARPF_INTERPOLATE);

			if (master.health < 1)
				A_FadeOut();
		}
		else
		{
			// Master gone entirely -- fade and self-destruct rather than
			// hang in the air over an empty spot.
			A_FadeOut();
		}
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_Jump(128, "Spawn2");
	Spawn1:
		LEF1 ABCDEFGHI 1;
		Loop;
	Spawn2:
		LEF2 ABCDEFGHI 1;
		Loop;
	}
}

// ---------------------------------------------------------------------
// SILVER -- Cyan's sign flipped. A magnetic well that will not let you
// leave.
//
// The same field, pulling instead of pushing, and that one sign change
// makes a completely different fight: Cyan is a monster you cannot reach,
// Silver is a monster you cannot back away from. Everything else about
// it -- the extra health, the quadrupled mass, the fact that it does not
// bleed -- exists to sell "this thing is a lump of metal" and to make it
// immovable by anyone else's thrust in turn.
// ---------------------------------------------------------------------
class RS_EliteProfile_Silver : RS_EliteProfile
{
	int radfactor;

	override void OnSelected()
	{
		tickInterval = 1;

		// Negative force. The whole profile is this minus sign.
		radfactor = -224;

		if (!mon)
			return;

		// Quadrupled, and it is not flavour: mass is the divisor in every
		// thrust in the game, so the magnet is itself close to unpushable.
		mon.Mass *= 4;
		mon.bNOBLOOD = true;

		mon.health      = int(mon.health * 1.25);
		mon.StartHealth = mon.health;
		if (ctl)
			ctl.boostedMax = mon.health;
	}

	override void OnReveal()
	{
		radfactor = -384;
	}

	override void OnTick()
	{
		if (!mon)
			return;

		RS_EliteField.Apply(mon, radfactor, 384);

		// One ring every 16 tics, so up to five are alive at once, each
		// at a different size. The stack of them collapsing inwards is
		// what tells the player which direction they are being dragged --
		// the pull itself is invisible and would otherwise read as the
		// floor being broken.
		if (level.time % 16 == 0)
			mon.A_SpawnItemEx("RS_EliteMagnetism", flags: SXF_SETMASTER);
	}

	// Silver's look was defined by suppressing its particles entirely --
	// it never had a colour set, only an absence of one. Our aura is not
	// profile-suppressible and a white one reads as "no profile at all",
	// so it takes a single fixed metallic shade, exactly as Bronze does
	// in RS_EliteProfiles_Simple.zs for the same reason.
	override color GetShade() { return "C0C0C0"; }
}

// A collapsing ring of field lines. Spawned at full size and shrunk 0.01
// per tic, so it is gone in 75 tics whatever its alpha is doing -- the
// shrink, not the fade, is what ends it.
//
// It fades IN over its first 30 tics and only then starts fading out,
// which is why a lone ring looks like nothing much and five overlapping
// ones look like a field: the newest is always the faintest.
class RS_EliteMagnetism : Actor
{
	int zpos;

	Default
	{
		RenderStyle "Add";
		Scale 0.75;
		Alpha 0.0;
		+BRIGHT
		+NOBLOCKMAP
		+NOGRAVITY
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		if (!master)
		{
			Destroy();
			return;
		}

		// Centred on the body, not the feet.
		zpos = int(master.Height * 0.5);
		SetOrigin((master.pos.x, master.pos.y, master.pos.z + zpos), true);
	}

	override void Tick()
	{
		Super.Tick();

		if (isFrozen())
			return;

		Scale.Y -= 0.01;
		Scale.X  = Scale.Y;

		// Hard-pinned every tic rather than warped, because the ring must
		// not lag the monster by even one tic -- a magnet whose field is
		// visibly trailing behind it stops reading as attached to it.
		if (master)
			SetOrigin((master.pos.x, master.pos.y, master.pos.z + zpos), true);

		if (Scale.X <= 0 || !master || master.health < 1)
			Destroy();
	}

	States
	{
	Spawn:
		MAGN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 A_FadeIn(0.04);
	FadeOut:
		MAGN A 1 A_FadeOut(0.005);
		Wait;
	}
}

// ---------------------------------------------------------------------
// GREY -- it moves when you aim at it.
//
// THE GATE IS THE PROFILE. Both of its moves are behind a test for
// whether the monster is inside a 30-degree cone of what its TARGET is
// facing, within 500 units -- that is, whether you currently have it
// roughly centred on your screen. So it does not strafe on a timer, it
// strafes when you line up the shot, and it lunges when you line up the
// shot and it decides to close instead.
//
// That makes it the only profile in the set that is reacting to the
// player rather than to the clock, and it is why it gets no reveal bonus:
// the behaviour is already the reward, and doubling its cadence would
// just make it unhittable.
// ---------------------------------------------------------------------
class RS_EliteProfile_Grey : RS_EliteProfile
{
	override void OnSelected()
	{
		// Every 8 tics. Fast enough to feel like a reaction, slow enough
		// that it cannot dodge continuously.
		tickInterval = 8;
	}

	// OnReveal is not overridden at all. Grey has no reveal bonus by
	// design -- see the header above.

	override void OnTick()
	{
		if (!mon || !mon.target)
			return;

		// Coin flip first, then a real sight check. The coin flip is what
		// stops it dodging every single shot: roughly half the time it
		// simply does not notice you aiming.
		if (!random(0, 1) || !mon.CheckSight(mon.target))
			return;

		// THE SIDESTEP. 50% branch. Sideways velocity relative to its own
		// facing, direction picked at random, so it slides out of the
		// crosshair without ever giving ground.
		if (random(0, 1) && mon.CheckIfInTargetLOS(30, 0, 500))
		{
			mon.A_FaceTarget();
			GreyWhoosh();
			mon.A_ChangeVelocity(0, frandompick(-16, 16), 0, CVF_RELATIVE);
			mon.GiveInventory("RS_EliteShadowSpawner", 1);
			return;
		}

		// THE LUNGE. 1-in-4 of what is left, so it is much rarer than the
		// sidestep -- it has to be, because 48 units of forward velocity
		// crosses a room. The 2.0 of lift is what makes it read as a
		// pounce rather than a slide.
		if (!random(0, 3) && mon.CheckIfInTargetLOS(30, 0, 500))
		{
			mon.A_FaceTarget();
			mon.A_ChangeVelocity(48.0, 0, 2.0, CVF_RELATIVE);
			GreyWhoosh();
			mon.GiveInventory("RS_EliteShadowSpawner", 1);
		}
	}

	// The swing-through-air cue, written out rather than borrowed from
	// the Revenant, whose version of it is a method on that class and is
	// not reachable from a Thinker. These two lines are exactly what it
	// does. The sound matters more than it looks: the shadow trail is
	// silent, so without this the monster teleports across the room with
	// no warning at all.
	private void GreyWhoosh()
	{
		if (!mon)
			return;

		mon.A_FaceTarget();
		mon.A_StartSound("skeleton/swing", CHAN_WEAPON);
	}

	// Designed against ffffff / 808080 / 000000. The middle one: white is
	// what a profile-less elite already looks like, and pure black on an
	// additive stencil adds nothing and would render the elite with no
	// visible tell whatsoever. If 808080 ever comes out black on screen,
	// the stencil note at RS_Elites.zs:176 is why and the fix is to nudge
	// the value, not to change the profile.
	override color GetShade() { return "808080"; }
}

// ---------------------------------------------------------------------
// RS_EliteShadowSpawner -- twenty tics of after-image, refreshed.
//
// It lives on the monster rather than being spawned per move, and that is
// the point: a second lunge inside the window RESETS the clock instead of
// starting a second trail, so a monster that keeps moving keeps smearing
// and one that stops resolves back into a single body.
// ---------------------------------------------------------------------
class RS_EliteShadowSpawner : Inventory
{
	const LIFESPAN = 20;

	int age;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}

	override void DoEffect()
	{
		Super.DoEffect();

		age--;

		if (owner)
		{
			let shadow = owner.Spawn("RS_EliteShadow", owner.pos);

			if (shadow)
			{
				// Copied, not tinted. The after-image has to be THIS
				// monster's exact current frame or the trail reads as a
				// separate creature following it. Translation comes along
				// because our monsters carry per-tier translations of
				// their own and a ghost in the wrong palette is worse
				// than no ghost.
				shadow.Sprite      = owner.Sprite;
				shadow.Frame       = owner.Frame;
				shadow.Angle       = owner.Angle;
				shadow.Translation = owner.Translation;
				shadow.A_SetSize(owner.radius, owner.height);
			}
		}

		if (age <= 0)
			DepleteOrDestroy();
	}

	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);

		age = LIFESPAN;
	}

	override bool HandlePickup(Inventory item)
	{
		// GUARDED ON PURPOSE. HandlePickup is called on every item the
		// owner already holds whenever it is given anything at all, so an
		// unguarded reset here would have the elite's own reveal tokens
		// silently extending the shadow trail.
		if (item && item.GetClass() == GetClass())
			age = LIFESPAN;

		return Super.HandlePickup(item);
	}
}

// One frame of the monster, left behind. Fades on the default 0.01 per
// tic from 0.75, so a shadow outlives the twenty tics that spawned it by
// a long way and the trail dissolves rather than snapping off.
class RS_EliteShadow : Actor
{
	Default
	{
		RenderStyle "Translucent";
		Alpha 0.75;
		+NOBLOCKMAP
		+NOGRAVITY
	}

	States
	{
	Spawn:
		// "####" "#" holds whatever sprite and frame were assigned from
		// outside -- the same trick RS_EliteAura uses (RS_Elites.zs:229).
		"####" "#" 1 A_FadeOut();
		Wait;
	}
}

// ---------------------------------------------------------------------
// GREEN -- it is not where you left it.
//
// THE BLINK, and it is not a teleport. The monster runs its normal chase
// logic fifty to a hundred times inside a single tic, which means it
// arrives somewhere it could genuinely have walked to, following the
// floor, through the doors, around the pillars. That is the whole reason
// it is done this way rather than with a SetOrigin: a real teleport puts
// monsters inside geometry and behind locked doors, and this one cannot,
// because every step of it was a step the monster was allowed to take.
//
// The fog at both ends is doing honest work -- it is the only warning the
// player gets, and it marks both the departure and the arrival so the
// move can be read after the fact.
// ---------------------------------------------------------------------
class RS_EliteProfile_Green : RS_EliteProfile
{
	int steps;
	int chance;
	int cooldown;

	override void OnSelected()
	{
		// Every 35 tics -- once a second. Any faster and the monster is
		// never in one place long enough to be shot at.
		tickInterval = 35;

		steps  = 50;
		chance = 4;
	}

	override void OnReveal()
	{
		// Half again the distance, and the roll goes from 1-in-5 to
		// 1-in-3. Both, because distance alone just makes it disappear
		// and frequency alone just makes it twitchy.
		steps  = int(steps * 1.5);
		chance = 2;
	}

	override void OnTick()
	{
		if (!mon)
			return;

		// The cooldown is what stops two blinks landing back to back and
		// the monster crossing the whole map before you can react.
		if (cooldown)
		{
			cooldown--;
			return;
		}

		if (!mon.target || random(0, chance))
			return;

		int maxstep = random(steps, steps * 2);

		mon.A_SpawnItemEx("TeleportFog");

		// FOUR MOVEMENT PROPERTIES ARE BORROWED FOR THE LENGTH OF THIS
		// FUNCTION AND HANDED BACK BELOW, and they are captured first
		// rather than restored to Default afterwards. This is not
		// defensive style, it is a real bug avoided: the controller sets
		// bJUMPDOWN on every non-boss elite at reveal (RS_Elites.zs:473),
		// so restoring that one to its class default would quietly strip
		// a property the elite is supposed to keep for the rest of the
		// fight -- and it would do it invisibly, on the first blink,
		// forever.
		bool   oldJumpDown   = mon.bJUMPDOWN;
		bool   oldThruActors = mon.bTHRUACTORS;
		double oldDropOff    = mon.MaxDropOffHeight;
		double oldStepHeight = mon.MaxStepHeight;

		// For the duration of the run the monster ignores drops, walls it
		// could step over, and other monsters. Without THRUACTORS the
		// blink stops dead on the first zombie in the corridor; without
		// the two heights it refuses to leave the room it is standing in.
		mon.bJUMPDOWN         = true;
		mon.bTHRUACTORS       = true;
		mon.MaxDropOffHeight  = 512;
		mon.MaxStepHeight     = 512;

		// A shove off its current heading, so it does not simply appear
		// fifty paces closer along the line you were already watching.
		mon.A_SetAngle(mon.angle + randompick(-90, -45, 0, 45, 90));

		for (int i = 0; i < maxstep; i++)
			mon.A_Chase(null, null, CHF_NORANDOMTURN);

		mon.bJUMPDOWN        = oldJumpDown;
		mon.bTHRUACTORS      = oldThruActors;
		mon.MaxDropOffHeight = oldDropOff;
		mon.MaxStepHeight    = oldStepHeight;

		mon.A_SpawnItemEx("TeleportFog");

		cooldown = random(2, 5);
	}

	override void OnHit(int damage)
	{
		// One hit in three makes it blink NOW, off its own cadence. This
		// is what turns the profile from a wandering nuisance into an
		// evasion: the moment you connect, it is somewhere else, and the
		// second shot of a burst misses.
		if (!random(0, 2))
			OnTick();
	}

	// Designed against ffffff / 33cc33 / 70db70 / 1f7a1f / d8fe01. The
	// signature green rather than the pale or the near-black: an additive
	// stencil eats 1f7a1f and washes 70db70 out towards white.
	override color GetShade() { return "33CC33"; }
}
