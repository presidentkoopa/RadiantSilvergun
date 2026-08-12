// =====================================================================
// RS_MonsterFire -- "this monster fired, here, now."
//
// A cross-mod signal, built for GlowInTheDark's monster muzzle flash
// but deliberately not coupled to it. Anything can consume it and
// nothing has to.
//
// ---------------------------------------------------------------------
// WHY IT EXISTS
//
// GITD's monster flash needs to know the instant a monster's attack
// goes off, and from outside RS_Main the only lever available is
// guessing from sprite frames. Its 3.2 implementation did exactly that
// -- match the monster by inheritance, then test mo.frame against a
// hand-verified table of vanilla firing frames.
//
// That cannot work on this roster. RS_CommonZombie DOES inherit
// ZombieMan, so it passes the `is` test -- and then animates on SGAR,
// not POSS. Vanilla's firing frame 5 is POSS F; frame 5 on SGAR is F,
// the A_FaceTarget wind-up, one frame BEFORE A_PosAttack. Other
// variants animate on CYNT and never match at all. The result is a
// flash that fires early on some monsters and never on others, with no
// error either way. 143 costed variants each with their own frame
// layout means no table survives.
//
// RS_Main does not have to guess. It knows.
//
// ---------------------------------------------------------------------
// WHY ONE CHECK COVERS THE WHOLE ROSTER
//
// Two kinds of monster attack, and both arrive as a missile:
//
//   projectile monsters   spawn their own +MISSILE actor, target = the
//                         shooter, at the muzzle.
//   hitscan monsters      RS_NoHitscan already converts every
//                         full-range monster hitscan into a travelling
//                         RS_HitscanReplacer (+MISSILE, fired through
//                         A_SpawnProjectile so target is the shooter).
//                         163 hitscan call sites across 20 monster
//                         files, all of them, for free.
//
// So `thing.bMISSILE && thing.target.bISMONSTER` is the whole test, and
// the projectile's OWN spawn position is the muzzle -- more accurate
// than any offset guess, because it is where the attack actually came
// out.
//
// NOT COVERED, stated rather than hidden: A_CustomRailgun. RS_NoHitscan
// documents that it goes through P_RailAttack and is deliberately left
// instant, so rail attacks emit no signal. Melee emits none either --
// there is no muzzle to flash.
//
// ---------------------------------------------------------------------
// THE CONTRACT, for whoever consumes this
//
//   class RS_MonsterFiredMarker
//     .target   the shooting monster
//     .pos      the muzzle -- where the round actually left
//     .angle    the shot's facing
//     .pitch    the shot's elevation
//     lives     1 tic, then destroys itself
//
// Observe it from a WorldThingSpawned handler. Look it up BY STRING so
// there is no hard dependency:
//
//     Class<Actor> mk = "RS_MonsterFiredMarker";
//     if (mk && e.Thing is mk) { ... }
//
// That way a consumer loads fine whether or not RS_Main is present --
// mk is simply null and the branch never runs.
//
// Read .target.bFRIENDLY if you care: a summoned minion firing is a
// real shot and does signal. Filtering that is the consumer's call, not
// this file's.
// =====================================================================

class RS_MonsterFiredMarker : Actor
{
	Default
	{
		+NOINTERACTION
		+NOBLOCKMAP
		+NOGRAVITY
		+DONTSPLASH
		+THRUACTORS
		+NOTELEPORT
		RenderStyle "None";
	}

	States
	{
	Spawn:
		TNT1 A 1;
		Stop;
	}
}

class RS_MonsterFireSignal : EventHandler
{
	// One volley is one shot. A mancubus throws three fireballs and a
	// converted arachnotron volley spawns a replacer per pellet, all in
	// the same tic from the same actor -- without this, a single attack
	// signals three to thirty times and any light driven off it strobes.
	//
	// A single memo slot is enough precisely because a volley's spawns
	// are consecutive and same-tic; it does not need to be a map.
	private Actor mLastShooter;
	private int   mLastTic;

	static bool Enabled()
	{
		let cv = CVar.GetCVar("rs_monster_fire_signal", null);
		return cv ? cv.GetBool() : true;
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let t = e.Thing;

		// Cheapest possible reject first -- this handler sees every
		// actor spawn in the map, including every puff and every gib.
		if (!t || !t.bMISSILE)
			return;

		let shooter = t.target;
		if (!shooter || !shooter.bISMONSTER)
			return;                       // player shots are not our business

		if (!Enabled())
			return;

		// Same shooter, same tic: part of the volley we already signalled.
		if (shooter == mLastShooter && level.maptime == mLastTic)
			return;
		mLastShooter = shooter;
		mLastTic     = level.maptime;

		// The projectile's own spawn point IS the muzzle. Copying its
		// facing too means a consumer can offset forward along the shot
		// if it wants, rather than being stuck at a point.
		let mk = Actor.Spawn("RS_MonsterFiredMarker", t.pos, ALLOW_REPLACE);
		if (!mk)
			return;
		mk.target = shooter;
		mk.angle  = t.angle;
		mk.pitch  = t.pitch;
	}
}
