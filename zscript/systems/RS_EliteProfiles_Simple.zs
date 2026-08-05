// =====================================================================
// RS_EliteProfiles_Simple -- the four profiles that are pure stat maths.
// ---------------------------------------------------------------------
// Red, Black, Yellow and Bronze. Between them they spawn exactly one
// actor (a glint) and fire nothing at all; everything else is a handful
// of field writes on the monster. They share a file because they share
// that shape, and because four twenty-line classes in four files buys
// nothing but four more include lines to forget.
//
// NONE OF THESE EXIST TO THE ENGINE YET. A profile is reachable only
// once this file is in zscript.txt's include list AND the class has a
// case in RS_EliteRoster with Count() bumped to match (RS_Elites.zs:127).
// A .zs that is not included does not error -- the classes are simply
// not there. Both edits are outside this file on purpose.
//
// HOW THE HOOKS LAND HERE. OnSelected and OnReveal BOTH fire at reveal,
// OnSelected first -- see the model paragraph at the top of RS_Elites.zs.
// They are still written as two methods because the split is real: one
// is "what this profile is", the other is "what waking up buys it", and
// pulling them apart again later should not mean re-deriving which line
// was which. Yellow is where you can see it: it sets its speed factor to
// 1.5 and then immediately to 2.0, so 1.5 currently exists for the space
// of one statement. That is correct, not dead code.
//
// COLOUR IS GetShade() AND NOTHING ELSE. The body is never tinted -- our
// monster art is bespoke per tier and a tint on top of bespoke art
// corrupts it (RS_Elites.zs:171). The aura, the pentagram and the light
// all read GetShade(), and that is the whole of a profile's visual
// identity. Each GetShade below records in a comment the full colour set
// its look was designed around, because the controller caches ONE shade
// at reveal: returning a random pick from the set would eventually mean
// a red elite that came up white, which costs more than the variation
// is worth.
//
// PROFILES THAT CHANGE HEALTH ALSO MOVE StartHealth. The controller sets
// StartHealth to the boosted maximum deliberately, so a marked monster's
// health bar reads 100% and gives nothing away (RS_Elites.zs:376). A
// profile that doubles health without moving StartHealth hands that
// straight back by drawing a 200% bar. boostedMax moves with it so the
// controller's own record of the monster stays true.
// =====================================================================

// ---------------------------------------------------------------------
// RED -- twice the health, and that is the entire profile.
//
// It never ticks, never reacts to being hit, and gains nothing at
// reveal. It is the profile you fight for a long time and cannot
// describe afterwards, which is exactly its job: it keeps "this one is
// taking too long" ambiguous, so the tell stays a tell.
// ---------------------------------------------------------------------
class RS_EliteProfile_Red : RS_EliteProfile
{
	// tickInterval stays 0. There is nothing to run per tic.

	override void OnSelected()
	{
		if (!mon)
			return;

		// This lands at reveal, when the controller has just refilled to
		// boostedMax -- so a Red elite costs the dormant bar plus twice
		// the boosted one, roughly three times a plain elite. Intended:
		// duration is the whole of Red's identity, and the reveal-time
		// model is what makes the second half of it feel earned.
		mon.health *= 2;

		mon.StartHealth = mon.health;
		if (ctl)
			ctl.boostedMax = mon.health;
	}

	// OnReveal, OnTick, OnHit, OnDeath and OnMissileSpawned are not
	// overridden at all. Red has no reveal bonus by design.

	// Designed against ff0000 / ff4d4d / ff9999 / ffffff.
	override color GetShade() { return "FF0000"; }
}

// ---------------------------------------------------------------------
// BLACK -- a glass cannon. Double damage out, double damage in.
//
// The only profile that makes a fight SHORTER. Everything else here
// lengthens one, so Black is what stops "elite" reading as "sponge".
// ---------------------------------------------------------------------
class RS_EliteProfile_Black : RS_EliteProfile
{
	// tickInterval stays 0 -- Black is entirely front-loaded.

	override void OnSelected()
	{
		if (!mon)
			return;

		// MULTIPLIED, not set. The controller SET DamageMultiply to the
		// elite multiplier a few statements before this ran
		// (RS_Elites.zs:444), so Black lands on top of it and a
		// default-configured Black elite hits for 4x. If that is ever
		// too much, the number to move is the cvar, not this line --
		// this line is the profile's identity and the cvar is the
		// player's dial.
		mon.DamageMultiply *= 2.0;

		// DamageFactor ABOVE 1.0 means it TAKES MORE. Not a typo and not
		// a sign error: Black kills you in two hits and dies in two.
		// The frailty is the price of the output, and it is the reason
		// this profile is allowed to stack onto the elite multiplier at
		// all.
		mon.DamageFactor *= 2.0;
	}

	// INTENTIONALLY EMPTY -- Black gets no reveal bonus. A further
	// multiplier here was tried and rejected: at 4x out it already ends
	// fights faster than anything else in the set, in both directions.
	// The empty override is the record of that decision; an absent one
	// would just look unfinished.
	override void OnReveal() {}

	// Designed against 000000 / 4d4d4d / 999999. Pure black is not
	// usable: the aura is an AddStencil and adding black adds nothing,
	// so a 000000 shade is an elite with no visible tell whatsoever.
	// 4D4D4D is the darkest value that still renders. If it reads as
	// nothing on a dark map, 999999 is the next step up.
	override color GetShade() { return "4D4D4D"; }
}

// ---------------------------------------------------------------------
// YELLOW -- everything it does happens sooner. Animation tics are
// divided, and so is the travel time of anything it fires.
// ---------------------------------------------------------------------
class RS_EliteProfile_Yellow : RS_EliteProfile
{
	double factor;

	// The state the monster was in last time we looked.
	//
	// THE SPEED CHANGE IS APPLIED ONCE PER STATE CHANGE, NEVER PER TIC,
	// and that gate is load-bearing in both directions. Rescaling every
	// tic compounds: dividing would collapse a state to nothing at an
	// accelerating rate, and Bronze's multiply below would outrun the
	// engine's one-per-tic decrement, so the state would never end and
	// the monster would freeze mid-frame. One division per state entry
	// is the whole mechanism.
	State prevState;

	override void OnSelected()
	{
		tickInterval = 1;   // a state change can fall on any tic
		factor       = 1.5;
	}

	override void OnReveal()
	{
		factor = 2.0;
	}

	override void OnTick()
	{
		// mon first, so the rest short-circuits: the controller can
		// outlive its monster by a tic.
		//
		// tics <= 0 is a state that never advances on its own (-1) or
		// one already due this tic. Scaling either produces nonsense --
		// int(-1 / 1.5) is 0, which would kick a monster straight out of
		// a state that was meant to hold indefinitely.
		if (!mon || mon.health < 1 || mon.tics <= 0)
			return;

		if (prevState != mon.CurState)
			mon.A_SetTics(int(mon.tics / factor));

		prevState = mon.CurState;
	}

	// The other half of "faster": what it throws arrives sooner too.
	// Reading the same `factor` as the animation means the two halves
	// cannot drift apart, and it is why the profile contract carries an
	// OnMissileSpawned hook at all -- a per-profile projectile tweak has
	// no other place to live that does not put profile knowledge into
	// the world handler.
	override void OnMissileSpawned(Actor missile)
	{
		if (!missile)
			return;

		missile.A_ScaleVelocity(factor);
	}

	// Designed against ffffff / ffffb3 / ffff4d / e6e600. The bright
	// entry, not the dark one -- an additive stencil eats a dark shade.
	override color GetShade() { return "FFFF4D"; }
}

// ---------------------------------------------------------------------
// BRONZE -- slow, unflinching, and immovable. Yellow's mirror: the same
// mechanism multiplied instead of divided.
//
// It never staggers, takes half damage, does not bleed, and cannot be
// pushed. What you get in exchange is time: it telegraphs every attack
// at nearly twice the normal length. It is a positioning problem, not a
// reflex one.
// ---------------------------------------------------------------------
class RS_EliteProfile_Bronze : RS_EliteProfile
{
	// Same once-per-state-change gate as Yellow -- see the note there
	// for why per-tic rescaling would freeze this one outright.
	State prevState;

	override void OnSelected()
	{
		// Set before the guard: tickInterval is ours, not the monster's,
		// and it should be right even if the actor went away.
		tickInterval = 1;

		if (!mon)
			return;

		mon.PainChance    = 0;              // never flinches
		mon.DamageFactor *= 0.5;            // takes half
		mon.Mass          = 0x7FFFFFFF;     // cannot be thrust at all
		mon.bNOBLOOD      = true;           // it does not bleed

		mon.health      = int(mon.health * 2.0);
		mon.StartHealth = mon.health;
		if (ctl)
			ctl.boostedMax = mon.health;
	}

	// INTENTIONALLY EMPTY -- Bronze gets no reveal bonus. Everything it
	// is arrives at once, and doubling down on "slower and tougher"
	// would produce a fight that simply does not end.
	override void OnReveal() {}

	override void OnTick()
	{
		if (!mon)
			return;

		// TWO gates on the glint, not one: a 1-in-9 roll and then a
		// 224-in-256 chance of failing anyway. That is ~1.4% per tic, so
		// roughly one glint every two seconds -- sparse enough to read
		// as a metallic catch of light rather than a particle effect.
		// The offset is rotated by the monster's facing, so glints hug
		// its leading edge; the random angle only sets the glint's own
		// facing, which a round sprite does not show, and it is kept so
		// a directional sparkle can be dropped in later without
		// revisiting this.
		if (!random(0, 8))
			mon.A_SpawnItemEx("RS_EliteSparkle",
			                  xofs: mon.radius,
			                  zofs: frandom(0, mon.height),
			                  angle: random(0, 359),
			                  failchance: 224);

		if (mon.health < 1 || mon.tics <= 0)
			return;

		if (prevState != mon.CurState)
			mon.A_SetTics(int(mon.tics * 1.75));

		prevState = mon.CurState;
	}

	// INTENTIONALLY EMPTY -- Bronze does nothing on death.
	//
	// Worth knowing what is therefore NOT here: nothing resets
	// PainChance, DamageFactor or Mass when it dies. The controller
	// hands back StartHealth and nothing else, so a Bronze corpse raised
	// by an archvile comes back still armoured and still immovable. That
	// is a controller-level decision about every profile, not this
	// profile's to make unilaterally, so it is recorded here rather than
	// patched here.
	override void OnDeath() {}

	// No colour set was ever designed for Bronze -- it is the one
	// profile whose look was defined by suppressing particles entirely.
	// Our aura is not profile-suppressible and a white one would read as
	// "no profile", so it gets a single fixed metallic shade rather than
	// an invented palette.
	override color GetShade() { return "CD7F32"; }
}
