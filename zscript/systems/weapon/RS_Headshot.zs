// =====================================================================
// RS_Headshot -- universal hit-location scoring.
//
// THE ONE IDEA: there is no monster list.
//
// Every headshot system ever written for this engine ships a hardcoded
// table of monster class names -- which ones have heads, which ones are
// all head, which ones have a hitbox too strange to bother with. That
// table is the tell. It exists because those systems cannot see the
// monster; they can only see its collision box, so they have to be told
// per-class what the box means.
//
// A collision box is not the monster. The monster is a PICTURE drawn
// inside the box. The box is one fixed size for the actor's whole life;
// the picture changes every frame -- it rears back, it ducks, it flies,
// it dies, it turns side-on. So "the top of the box" is the head only
// some of the time, and no per-class table can fix that, because the
// error is per-FRAME, not per-class.
//
// This reads the picture instead. The drawn sprite for the frame and
// rotation that is on screen RIGHT NOW is what the head box is measured
// from. That needs no table, and it is why this works on Doom monsters,
// on the imported families, and on anything added later without a line
// of new code.
//
// WHAT THAT BUYS, none of it special-cased:
//   * airborne, lifts, knockback  -- nothing here reads FloorZ
//   * every animation frame       -- the box tracks the drawn pose
//   * all eight rotations         -- profile and front differ, correctly
//   * every monster size          -- scale is read, not assumed
//   * a Cacodemon                 -- it is all head, so a top-centre hit
//                                    scores and a bottom hit does not.
//                                    No exemption needed; the geometry
//                                    already answers it.
//
// ---------------------------------------------------------------------
// QUALITY, NOT A FLAG
//
// A headshot here is not a yes/no. It carries a quality from 0 to 1:
// how near the centre of the head the shot actually landed. Clip the
// edge and it is a graze; go through the middle and it is not.
//
// This is the point of measuring precisely. A binary check throws away
// everything the measurement just learned -- if a perfect shot and a
// lucky clip pay the same, precision was pointless. One number comes
// out of here and drives damage, effect size, sound pitch and score, so
// those four can never disagree about how good a shot was.
//
// ---------------------------------------------------------------------
// COST: NOTHING PER MONSTER, NOTHING PER TIC
//
// No inventory item is attached to anything. No monster carries state,
// no monster runs a Tick, and a level full of monsters that never get
// shot costs exactly zero. All the work happens inside a damage event
// that already occurred, and only if the feature is on.
//
// The reason for the second damage application (see ApplyBonus) rather
// than modifying the original: WorldThingDamaged CANNOT change damage
// on this engine build. p_interaction.cpp:1594 calls it with the final
// figure and discards the return value. The ONLY in-engine hook that
// can alter incoming damage on an arbitrary actor is ModifyDamage on an
// Inventory item the victim is already carrying -- which is precisely
// the per-monster item this file exists to avoid.
//
// WorldEvent.NewDamage already exists and is already honoured, but only
// for the sector and line damage paths (events.cpp:2030 and :2053).
// Wiring the thing-damaged path to honour it too is a small engine
// change, and when it lands, ApplyBonus collapses into a single
// assignment and the second damage call goes away. Written so that swap
// touches one function.
// =====================================================================

class RS_HeadshotUtil play
{
	// The bonus is dealt as damage type 'RS_Headshot', which is also the
	// recursion guard -- the handler ignores anything arriving under
	// that name, so a bonus can never score a headshot on itself.
	//
	// Written as a literal at both sites rather than held in a const:
	// a const bound to a NAME literal has no precedent anywhere in the
	// engine's own ZScript, and this project has been bitten three times
	// by constructs that look obviously valid and do not resolve on this
	// build. Two call sites, both in this file -- a const buys nothing
	// worth that risk.

	// How much of the sprite's width the head is assumed to occupy.
	// Deliberately generous -- a head box narrower than the drawn head
	// reads as the system being broken, while one slightly too wide just
	// reads as forgiving.
	//
	// Declared before its use rather than after. ZScript resolves class
	// members in two passes so the order should not matter; this project
	// has been burned enough by "should" that the free version wins.
	const HEAD_WIDTH_FRAC = 0.55;

	// -----------------------------------------------------------------
	// THE MEASUREMENT.
	//
	// Returns quality in 0..1 for a hit inside the head, or -1 for
	// anything else. -1 rather than 0 because a dead-centre body shot
	// and a barely-scraping head shot are different answers, and 0 is a
	// legitimate quality (the very edge of the head).
	//
	// `hitPos` is where the damage landed in the world. `viewer` is who
	// fired -- needed because a sprite is a billboard: it faces the
	// shooter, so "left and right across the monster" is measured
	// perpendicular to the shooter's line of sight, not against the
	// monster's own facing.
	// -----------------------------------------------------------------
	// `inflRadius` is the radius of whatever delivered the hit, and it
	// exists because this mod fires REAL PROJECTILES rather than
	// hitscans.
	//
	// A projectile does not stop where its centre meets the monster --
	// it stops when the two bounding boxes TOUCH, so at the moment of
	// impact its centre sits up to its own radius outside the monster.
	// Reading that centre as the impact point therefore reports every
	// shot as further off-centre than it really was, and the bias is
	// one-directional: it can only ever push a hit toward the edge,
	// never toward the middle.
	//
	// On a bullet of radius 6 against a monster whose drawn half-width
	// is 20, that is a 30% error on the horizontal quality -- enough to
	// turn a genuinely centred shot into a scored graze, every time.
	// Subtracting it back out is the correction, floored at zero so a
	// round fatter than the head cannot come out negative.
	static double Resolve(Actor victim, Vector3 hitPos, Actor viewer, double headFrac, double inflRadius = 0)
	{
		if (!victim || !viewer || !victim.CurState)
			return -1.0;

		// The sprite ACTUALLY BEING DRAWN, this frame, this rotation.
		// This single call is the whole difference between this and a
		// per-class table.
		TextureID tex;
		bool flip;
		Vector2 texScale;
		[tex, flip, texScale] = victim.CurState.GetSpriteTexture(victim.SpriteRotation);
		if (!tex.IsValid())
			return -1.0;

		// CheckRealHeight walks the texture's pixels and returns the
		// lowest row with anything in it -- so it trims blank rows off
		// the BOTTOM, giving the drawn extent rather than the canvas.
		// See texture.cpp:98.
		//
		// It has no mirror: there is no call that trims the TOP, so a
		// sprite with empty rows above the head measures its head box
		// slightly high. Proportional, not exact. A CheckRealBounds on
		// the engine side is the fix and is the same loop; until then
		// the error is small and constant per frame, which is the kind
		// a player adapts to without noticing.
		int realH = TexMan.CheckRealHeight(tex);
		if (realH <= 0)
			return -1.0;

		Vector2 scaledSize = TexMan.GetScaledSize(tex);
		Vector2 offset     = TexMan.GetScaledOffset(tex);
		if (scaledSize.x <= 0)
			return -1.0;

		double sy = victim.Scale.Y * texScale.Y;
		double sx = victim.Scale.X * texScale.X;
		if (sy <= 0 || sx <= 0)
			return -1.0;

		// --- vertical -------------------------------------------------
		//
		// Anchored on the actor's OWN z, never on FloorZ. That single
		// choice is what makes this correct for anything not standing
		// on the ground -- a Cacodemon, a monster on a lift, anything
		// knocked into the air. A floor-anchored box puts a flying
		// monster's head at ground level and is wrong for the entire
		// time it matters.
		double spriteTopZ = victim.pos.z + offset.y * sy;
		double drawnH     = realH * sy;
		if (drawnH <= 0)
			return -1.0;

		double headBand = drawnH * clamp(headFrac, 0.05, 1.0);
		double headTopZ = spriteTopZ;
		double headBotZ = spriteTopZ - headBand;

		if (hitPos.z < headBotZ || hitPos.z > headTopZ)
			return -1.0;

		// How near the middle of the band, 1 at centre, 0 at either
		// edge. A shot through the crown scores the same as one through
		// the chin -- both are the edge of the head.
		double vCentre = (headTopZ + headBotZ) * 0.5;
		double vq = 1.0 - (abs(hitPos.z - vCentre) / (headBand * 0.5));
		vq = clamp(vq, 0.0, 1.0);

		// --- horizontal -----------------------------------------------
		//
		// Across the billboard as the SHOOTER sees it. A sprite turns to
		// face whoever is looking, so the meaningful left/right axis is
		// perpendicular to the shooter's line of sight. Measuring
		// against the monster's own angle would rotate the head box off
		// the drawn head every time the monster turned.
		Vector2 los = (victim.pos.xy - viewer.pos.xy);
		double losLen = los.Length();
		if (losLen <= 0)
			return -1.0;
		los /= losLen;

		Vector2 perp = (-los.y, los.x);
		Vector2 rel  = (hitPos.xy - victim.pos.xy);
		double lateral = abs(rel.x * perp.x + rel.y * perp.y);

		// Give back the projectile's own radius -- see the note on this
		// function's signature. Floored at zero: a round wider than the
		// head must read as dead centre, not as a negative distance.
		lateral = max(0.0, lateral - inflRadius);

		// Sprite half-width, not the collision radius. They disagree
		// badly -- radius is a gameplay number chosen for movement and
		// is routinely far narrower or wider than the drawn monster.
		double halfW = scaledSize.x * 0.5 * sx;
		if (halfW <= 0)
			return -1.0;

		// A head is narrower than the body it sits on. Without this the
		// head box is as wide as the widest frame of the sprite, so a
		// shot past a Mancubus's shoulder at head height would score.
		// Proportional rather than measured, for the same reason as the
		// vertical: there is no call that reports the drawn width of a
		// single row. CheckRealBounds fixes both at once.
		double headHalfW = halfW * HEAD_WIDTH_FRAC;
		if (lateral > headHalfW)
			return -1.0;

		double hq = clamp(1.0 - (lateral / headHalfW), 0.0, 1.0);

		// Both axes have to be good. Multiplying would let a perfect
		// vertical rescue a terrible horizontal; the worse of the two is
		// the honest reading of "how centred was that".
		return min(vq, hq);
	}

	// -----------------------------------------------------------------
	// Quality -> multiplier. A graze pays the floor, a centre hit pays
	// the ceiling, and everything between is a straight ramp.
	//
	// Squared on purpose: it makes the top of the range something you
	// have to actually aim for rather than something you drift into,
	// which is the whole point of measuring quality at all.
	// -----------------------------------------------------------------
	static double Multiplier(double quality, double lo, double hi)
	{
		double q = clamp(quality, 0.0, 1.0);
		return lo + (hi - lo) * (q * q);
	}
}

// =====================================================================
// THE HOOK.
//
// A small item on each monster, carrying a single ModifyDamage override.
// This is the ONLY in-engine hook that can change incoming damage on an
// arbitrary actor, and it is handed the inflictor directly -- which is
// the impact point.
//
// An earlier version of this file tried to avoid attaching anything to
// monsters at all, driving everything from WorldThingDamaged on an
// EventHandler. That does not work, for two reasons found the hard way:
//
//   1. WorldEvent.DamagePosition IS NEVER SET on that path. Its name
//      could not look more correct and it reads (0,0,0) for every
//      bullet, punch and rocket. Only WorldHitscanFired,
//      WorldRailgunFired and the sector/line paths populate it
//      (events.cpp:1897, :1914, :2025, :2048).
//   2. That event cannot change damage anyway -- p_interaction.cpp:1594
//      calls it with the final figure and discards the return -- so the
//      bonus had to be a SECOND DamageMobj call, which rolls pain twice.
//
// THE COST CONCERN THAT DROVE THAT DETOUR WAS REAL BUT MISPLACED. What
// makes a per-monster item expensive is a DoEffect or Tick running every
// tic on every monster forever. This item has NEITHER -- no DoEffect, no
// Tick, no states, no fields that need maintaining. It is inert until
// something shoots its owner, at which point ModifyDamage fires once.
// Attaching it costs memory, not frame time.
// =====================================================================
class RS_HeadshotBrain : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
	}

	// Cached cvar HANDLES. The handle lookup is the string-keyed part and
	// is what costs; reading off a held handle is cheap and stays live,
	// so the options menu keeps working immediately. Same pattern as
	// RS_HealthBars, and for the same reason.
	private CVar cvEnable, cvHeadFrac, cvMultLo, cvMultHi;
	private CVar cvFX, cvSound, cvVol, cvMinQuality, cvDebug;

	// Damage numbers. ONLY the two switches that decide whether a number
	// is spawned at all are held here. Everything about how a number
	// LOOKS -- size, colour, motion, glow, overkill, per-hand tint,
	// distance -- is read by RS_DamageNumber itself, so this file never
	// learns the presentation cvars and adding one never touches it.
	private CVar cvDNEnable, cvDNMinimum;

	private void CacheCVars()
	{
		if (!cvEnable)     cvEnable     = CVar.FindCVar("rs_headshot_enable");
		if (!cvHeadFrac)   cvHeadFrac   = CVar.FindCVar("rs_headshot_headfrac");
		if (!cvMultLo)     cvMultLo     = CVar.FindCVar("rs_headshot_mult_graze");
		if (!cvMultHi)     cvMultHi     = CVar.FindCVar("rs_headshot_mult_centre");
		if (!cvFX)         cvFX         = CVar.FindCVar("rs_headshot_fx");
		if (!cvSound)      cvSound      = CVar.FindCVar("rs_headshot_sound");
		if (!cvVol)        cvVol        = CVar.FindCVar("rs_headshot_vol");
		if (!cvMinQuality) cvMinQuality = CVar.FindCVar("rs_headshot_min_quality");
		if (!cvDebug)      cvDebug      = CVar.FindCVar("rs_headshot_debug");
		if (!cvDNEnable)   cvDNEnable   = CVar.FindCVar("rs_dn_enable");
		if (!cvDNMinimum)  cvDNMinimum  = CVar.FindCVar("rs_dn_minimum");
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage,
	                           bool passive, Actor inflictor, Actor source, int flags)
	{
		// `passive` means WE are being hurt. The active pass is this
		// monster hurting something else and is none of our business.
		if (!passive || damage <= 0)
			return;

		CacheCVars();

		if (!owner || !source)
			return;

		// Player shots only. Infighting headshots would be invisible to
		// the player, cost the same to compute, and quietly rebalance
		// every monster-vs-monster fight in the level.
		if (!source.player)
			return;

		// Our own bonus, should it ever be dealt as a second application
		// again (see this file's header). It arrives already scored, so
		// letting it back in would score a headshot on a headshot AND
		// put a second damage number on the same hit.
		if (damageType == 'RS_Headshot')
			return;

		// `q` is the quality this hit scored, or -1 for "not a headshot"
		// -- which now also covers "headshots are switched off" and
		// "splash, so there is no impact point to measure". It is
		// carried past the headshot block because the damage number
		// reads it too.
		double q = -1.0;

		// What the monster actually takes. Starts as the incoming figure
		// and becomes the boosted one if this scores. The damage number
		// must print the number that LANDED, not the one that arrived.
		int dealt = damage;

		// Splash has no meaningful impact point -- the inflictor is the
		// bomb, sitting at the blast centre, not where the blast met
		// this monster. Any answer here would be fiction. (The damage
		// number still draws for splash; it just draws on the victim
		// rather than pretending to know where the blast touched it.)
		if (cvEnable && cvEnable.GetInt() && inflictor && !(flags & DMG_EXPLOSION))
		{
			double headFrac = cvHeadFrac ? cvHeadFrac.GetFloat() : 0.22;

			// The inflictor's radius goes in so the projectile-width bias
			// can be corrected -- this mod fires real projectiles, not
			// hitscans. A puff reports a tiny radius and the correction
			// costs it nothing, so one call is right for both.
			q = RS_HeadshotUtil.Resolve(owner, inflictor.pos, source,
			                            headFrac, inflictor.radius);

			// DEBUG READOUT. Off by default, and the only thing here that
			// prints. It reports MISSES too, because "nothing happened" is
			// the useless answer -- the numbers behind a miss are what say
			// whether the head box is in the wrong place, the wrong size, or
			// never reached at all.
			if (cvDebug && cvDebug.GetInt())
			{
				Console.Printf("\c[Gold]RS_HS\c- %s  hitZ %.1f  ownZ %.1f  q %.2f  %s",
				               owner.GetClassName(), inflictor.pos.z, owner.pos.z, q,
				               q < 0 ? "\c[Red]MISS" : "\c[Green]HEAD");
			}

			// A floor on how bad a graze still counts. At 0 the very edge of
			// the head scores; raising it makes the head effectively smaller
			// without moving the box -- a difficulty dial, not a geometry
			// change.
			//
			// A sub-floor graze is knocked back to -1 rather than merely
			// skipping the bonus, so the damage number cannot colour it
			// gold for a hit the scorer refused to pay for.
			double minQ = cvMinQuality ? cvMinQuality.GetFloat() : 0.0;
			if (q < minQ)
				q = -1.0;

			if (q >= 0)
			{
				double lo = cvMultLo ? cvMultLo.GetFloat() : 1.5;
				double hi = cvMultHi ? cvMultHi.GetFloat() : 4.0;

				// ONE application, not two. This is the payoff for using this
				// hook instead of an event: the original hit simply lands
				// harder, so pain and death roll once, on the real figure.
				newdamage = max(1, int(damage * RS_HeadshotUtil.Multiplier(q, lo, hi)));
				dealt = newdamage;

				SpawnFeedback(source, q, inflictor.pos);
			}
		}

		// EVERY player hit gets its number, headshot or not, and it is
		// spawned from here rather than from anywhere else -- see the
		// comment on EmitDamageNumber for why this is the only place it
		// can be done once and done right.
		EmitDamageNumber(dealt, q, inflictor, source, flags);
	}

	// -----------------------------------------------------------------
	// DAMAGE NUMBERS -- THE WHOLE MOD'S SINGLE EMIT SITE.
	//
	// Spec: docs/rs_damage_numbers_spec.md. The actor and every decision
	// about how a number looks live in zscript/systems/ui/RS_DamageNumber.zs;
	// this hands it the five measurements and gets out of the way.
	//
	// WHY HERE AND NOWHERE ELSE. This function needs five things at once
	// and there is exactly one point in the engine that has all five:
	//
	//   * the IMPACT POINT           -- inflictor.pos
	//   * the round's DIRECTION      -- inflictor.Vel, still intact
	//   * the victim's health BEFORE -- owner.health, not yet decremented
	//   * the FINAL damage           -- after the headshot multiplier
	//   * WHO landed it              -- source, and through it the gun
	//
	// The obvious alternative, an EventHandler's WorldThingDamaged, has
	// none of the first three. WorldEvent.DamagePosition IS NEVER SET on
	// that path -- it reads (0,0,0) for every bullet, punch and rocket,
	// and only the hitscan/railgun/sector/line paths populate it. That
	// cost a rebuild here once already and it is written up at the top
	// of this file. By the time that event fires the health is also
	// already decremented, so significance would have to be reconstructed
	// from a number the event does not carry either.
	//
	// AND IT IS WHY A HEADSHOT CANNOT PRODUCE TWO NUMBERS. There is one
	// call, on one path, per damage application. A general hit path
	// running alongside a headshot path is the shape that double-emits;
	// this has no general path to run alongside.
	//
	// The pre-decrement guarantee is not an assumption. p_interaction.cpp
	// calls the passive GetModifiedDamage (which is what dispatches to
	// this override) at :1213, and does `target->health -= damage` at
	// :1505 -- 292 lines later, with the damage factor, TakeSpecialDamage
	// and the monster armour pass in between. `owner.health` read here is
	// the health the monster had when the round left the barrel.
	//
	// COST: nothing. No thinker, no per-tic scan, no per-monster state.
	// This runs inside a damage event that already happened, and only
	// when the feature is on.
	// -----------------------------------------------------------------
	private void EmitDamageNumber(int dealt, double q, Actor inflictor, Actor source, int flags)
	{
		if (!cvDNEnable || !cvDNEnable.GetInt())
			return;
		if (dealt <= 0)
			return;

		// The floor. Poison ticks, fire and chip effects make screen
		// noise and none of them are decisions. 0 = everything draws.
		int floorDmg = cvDNMinimum ? cvDNMinimum.GetInt() : 0;
		if (dealt <= floorDmg)
			return;

		// WHERE, AND WHICH WAY IT WAS GOING.
		//
		// The inflictor IS the impact point: a projectile is sitting on
		// the monster at the moment it hurts it, and a hitscan puff is
		// spawned at the trace's hit point and handed in as the
		// inflictor by the engine (p_map.cpp:5169, `puff ? puff : t1`).
		//
		// Two cases where it is not, and both fall back to the victim:
		//   * SPLASH -- the inflictor is the bomb at the blast centre,
		//     not where the blast met this monster, so a number there
		//     would pile every victim's figure on one spot.
		//   * NO PUFF -- when the engine has no puff to spawn it passes
		//     the SHOOTER as inflictor, which would put the number in
		//     the player's face rather than on the target.
		Vector3 pos;
		Vector3 impulse = (0, 0, 0);

		if (inflictor && inflictor != source && !(flags & DMG_EXPLOSION))
		{
			pos     = inflictor.pos;
			impulse = inflictor.Vel;
		}
		else
		{
			// Three-quarters up the victim: chest height on a biped,
			// inside the sprite on everything else. Its own centre (z is
			// the FEET) would bury the number in the floor.
			pos = (owner.pos.x, owner.pos.y, owner.pos.z + owner.Height * 0.75);
		}

		// SIGNIFICANCE -- damage as a fraction of the health this monster
		// had BEFORE the hit. The single most valuable number here: 50 to
		// a zombieman is the whole monster, 50 to a Cyberdemon is a
		// rounding error, and sizing by the raw figure only tells the
		// player how big their gun is, which they already know.
		//
		// DELIBERATELY NOT CLAMPED AT THE TOP. An overkill genuinely
		// exceeds 1.0, and that overshoot is the ONLY record of how much
		// damage was wasted -- RS_DamageNumber recovers the pre-hit
		// health as `amount / significance` and the waste as the
		// remainder. Clamping here makes an overkill indistinguishable
		// from an exact kill and silently guts rs_dn_overkill.
		//
		// This was clamped in the first pass, written against a contract
		// that documented the range as 0..1, while the consumer was
		// written to require the overshoot. Both halves were internally
		// reasonable and together they produced a toggle that could
		// never do anything -- exactly the "consistent with itself"
		// failure this project keeps paying for, caught only by reading
		// both sides against each other.
		//
		// Safe because the consumer clamps where clamping is what it
		// wants: RS_SetupLaunch opens with clamp(sig, 0.0, 1.0), so no
		// scale or physics term ever sees the overshoot. Only the
		// overkill branch reads it raw.
		int hpBefore = owner.health;
		double sig = (hpBefore > 0)
			? max(0.0, double(dealt) / double(hpBefore))
			: 1.0;

		// WHICH GUN, AND DID IT CRIT. Resolved through the round's own
		// master pointer where there is one -- see RS_Weapon.FiringWeaponOf,
		// which owns this question because both answers are its fields.
		// CRIT COMES OFF THE ROUND, NOT THE GUN. RS_ShotWasCrit is a
		// field on the weapon describing its LAST PULL, which is only
		// the same thing as "this round" while the round is fast enough
		// that nothing else has been fired since. That holds for
		// bullets and fails for rockets. See RS_CritMark.RoundWasCrit.
		//
		// Only the HAND still comes from the weapon -- a gun cannot
		// change hands mid-flight, so that answer cannot go stale.
		bool crit    = RS_CritMark.RoundWasCrit(inflictor);
		bool offhand = false;
		let firedBy  = RS_Weapon.FiringWeaponOf(inflictor, source);
		if (firedBy)
		{
			// Fallback only: a melee puff carries no token because
			// nothing spawned it through the projectile path, so the
			// gun's own flag is the best answer available and is
			// correct there -- a swing lands on the tic it is thrown.
			if (!inflictor.bMISSILE)
				crit = firedBy.RS_ShotWasCrit;
			offhand = firedBy.bOffhandWeapon;
		}

		bool head = (q >= 0);

		// The killing blow is a DIFFERENT EVENT, not a bigger ordinary
		// one, so it takes the type outright rather than combining. It
		// is known here and only here: health has not been decremented
		// yet, so "this kills it" is a comparison rather than a guess.
		// Quality still goes out below whatever the type says, so a
		// killing headshot has not thrown its measurement away.
		int hitType;
		if (hpBefore > 0 && dealt >= hpBefore)
			hitType = RS_DN_KILL;
		else if (crit && head)
			hitType = RS_DN_CRITHEAD;
		else if (head)
			hitType = RS_DN_HEAD;
		else if (crit)
			hitType = RS_DN_CRIT;
		else
			hitType = RS_DN_NORMAL;

		RS_DamageNumber.Emit(pos, dealt, impulse, sig, hitType,
		                     head ? q : 0.0, offhand);
	}

	// -----------------------------------------------------------------
	// FEEDBACK -- at the hit, sized by quality.
	//
	// It spawns AT the impact point, not at the monster's centre. Shoot
	// the left side of the head and the burst is on the left side of the
	// head. In VR, where you are physically pointing at the thing, an
	// effect that appears near the target rather than on it reads as the
	// game not registering the shot.
	//
	// Its SIZE and the sound's PITCH both ride the same quality number
	// that set the damage, so the feedback reports how good the shot was
	// without a number on screen -- the only form that survives
	// peripheral vision, and the only one that belongs in a headset.
	// -----------------------------------------------------------------
	private void SpawnFeedback(Actor src, double q, Vector3 hitPos)
	{
		if (cvFX && cvFX.GetInt())
		{
			let fx = Spawn("RS_HeadshotSpark", hitPos, ALLOW_REPLACE);
			if (fx)
			{
				// THE ART IS 96x96, so these numbers are small on
				// purpose -- at 1.0 the flash would be 96 world units
				// across, wider than a Cyberdemon, and would swallow
				// whatever you just shot. 0.25 at a graze up to 0.45
				// dead centre puts it at 24-43 units: readable at a
				// glance, clearly bigger for a better shot, never large
				// enough to hide the monster.
				double s = 0.25 + 0.20 * q;
				fx.Scale.X = s;
				fx.Scale.Y = s;
				fx.Alpha   = 0.55 + 0.45 * q;
			}
		}

		// SHIPS OFF, and the cvar defaults to false, because
		// `rs_headshot_hit` HAS NO SNDINFO ENTRY AND NO LUMP YET. An
		// unresolved sound name is completely inert on this engine -- no
		// error, no warning, no log line, just silence. That is how all
		// 52 Streak weapon sounds went eight passes without ever
		// playing. Defaulting this on would ship a toggle that promises
		// a noise and delivers nothing, with no way to tell which.
		if (cvSound && cvSound.GetInt() && src)
		{
			double vol = cvVol ? cvVol.GetFloat() : 1.0;
			// A graze ticks, a centre hit cracks. One lump, pitch
			// carrying the read -- the project's own AllClear pattern.
			src.A_StartSound("rs_headshot_hit", CHAN_AUTO, CHANF_OVERLAP,
			                 vol, ATTN_NONE, 0.85 + 0.35 * q);
		}
	}
}

// =====================================================================
// Hands the item out. This is the whole of the per-tic footprint: one
// event when a monster spawns, and nothing at all thereafter.
// =====================================================================
class RS_HeadshotHandler : EventHandler
{
	// Only real monsters. Matches the project's own gate rather than a
	// bare ISMONSTER -- decorative map props carry that flag, and a
	// headshot on scenery is not a thing. Same test RS_ReserveSquads
	// documents.
	private static bool Eligible(Actor a)
	{
		return a && a.bISMONSTER && a.bCOUNTKILL && !a.bSPECIAL;
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if (Eligible(e.Thing))
			e.Thing.GiveInventory("RS_HeadshotBrain", 1);
	}
}

// =====================================================================
// The mark left at the hit. Scale and alpha are set by the brain from
// the shot's quality before the first tic draws, so a graze and a centre
// hit are visibly different events rather than the same sprite twice.
// =====================================================================
class RS_HeadshotSpark : Actor
{
	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+NOINTERACTION
		+ZDOOMTRANS
		+ROLLSPRITE
		+ROLLCENTER
		RenderStyle "Add";
		Alpha 1.0;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		// Random roll and flip so a burst of hits in the same place does
		// not read as one sprite stuttering.
		bSPRITEFLIP = (random(0, 1) == 1);
		roll = frandom(-45.0, 45.0);
	}

	// RSH0, 19 frames (A-S), in sprites/combatfx/hitflash/. Named to this
	// tree's own convention -- RS + a category letter + a digit, matching
	// RSU (puffs), RSE (explosions), RSF (flares) and RSS (sparks). No RSH
	// prefix existed under sprites/ before the import, so it cannot lose a
	// load-order race.
	States
	{
	Spawn:
		RSH0 ABCDEFGHIJKLM 1 BRIGHT;
		RSH0 NOPQRS 1 BRIGHT A_FadeOut(0.15);
		Stop;
	}
}
