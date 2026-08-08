// =====================================================================
// RS_Hook -- the grappling hook. A DEFAULT MECHANIC, always available.
//
// ---------------------------------------------------------------------
// WHAT IT DOES, IN ONE PARAGRAPH
//
// Fire it. If it hits a wall, YOU get pulled to the wall. If it hits a
// monster, the MONSTER gets pulled to you. Either way, the moment it
// leaves your hand it sweeps a radius around you and drags every loose
// bit in. That third behaviour is unconditional -- it happens on a hit,
// on a miss, on a wall, on a body, every single time.
//
// IT IS NOT A SWING. There is no rope you hang from, no momentum you
// carry through an arc. It is a one-shot yank, which is the whole reason
// it does not feel like web-slinging. Owner's call, 2026-08-07, after
// looking at a swinging implementation and rejecting it.
//
// ---------------------------------------------------------------------
// THE BIT SWEEP IS NOT A CURSE FEATURE, AND THAT IS THE POINT
//
// `mainhand-bit-repellent` / `offhand-bit-repellent` (RS_Curses.zs) push
// loose bits AWAY from the player, radially, forever. The hook pulls
// them back.
//
// The hook was NOT built to solve that and is NOT granted by it. It is
// always present, works identically for an uncursed player, and would
// exist if the curse did not. It simply happens to be the answer --
// owner, 2026-08-07: "it's just a solution to a problem coincidentially".
//
// That distinction is worth preserving in code as well as in comments:
// nothing in this file reads the curse ledger, and nothing in the curse
// system grants or modifies the hook. If a later change makes the sweep
// conditional on being cursed, the mechanic has been misunderstood.
//
// ---------------------------------------------------------------------
// WHY THIS IS A ZSCRIPT REBUILD AND NOT AN IMPORT
//
// The reference implementation is ~100 lines of ACS, and roughly 80 of
// them are TID plumbing: UniqueTID, Thing_ChangeTID, SetActivator back
// and forth, store-and-restore of the player's original TID. None of
// that is the mechanic -- it is ACS working around not being able to
// hold a pointer to an actor. ZScript holds the actor, so all of it
// disappears. ThrustThing/ThrustThingZ become direct velocity writes.
//
// No ACS, no `loadacs`, no `#library`, no DECORATE, no dependency.
//
// ASSETS: sprites/rs_hook/ -- ONE sprite, HOOK, two frames:
//   HOOK A   open, in flight    (8-angle rotations, A1/A2A8/A3A7/A4A6/A5)
//   HOOK B   closed, impacted   (same 8 rotations)
// and Sounds/rs_hook/, five lumps. See SNDINFO for the name mapping.
// =====================================================================

class RS_HookSettings
{
	static int CVInt(string name, int def)
	{
		let c = CVar.FindCVar(name);
		return c ? c.GetInt() : def;
	}

	static bool CVBool(string name, bool def)
	{
		let c = CVar.FindCVar(name);
		return !c ? def : c.GetBool();
	}

	static double CVFloat(string name, double def)
	{
		let c = CVar.FindCVar(name);
		return c ? c.GetFloat() : def;
	}

	// Which hand it launches from. 0 = mainhand, 1 = offhand.
	// Offhand by default: the mainhand is your gun and interrupting it to
	// grapple is the wrong trade in a firefight.
	const HAND_MAIN = 0;
	const HAND_OFF  = 1;

	static int Hand()
	{
		return clamp(CVInt("rs_hook_hand", HAND_OFF), 0, 1);
	}

	static bool Enabled() { return CVBool("rs_hook_enable", true); }
}


// =====================================================================
// THE PROJECTILE.
//
// FastProjectile with a hard lifetime rather than a range check: the
// reference did the same thing and it is the right call, because a
// distance test on a fast mover is a per-tic cost that a frame counter
// gets for free. Ten frames at speed 40 is the range.
// =====================================================================
class RS_HookShot : FastProjectile
{
	Default
	{
		MissileHeight 8;
		Height 14;
		Radius 10;
		Projectile;
		+HITTRACER
		+PAINLESS
		+NODAMAGETHRUST
		MaxTargetRange 10;
		MaxStepHeight 4;
		Speed 40;
		Damage 0;
		SeeSound "rs_hook/fire";
		ActiveSound "rs_hook/swish";
		Obituary "%o was reeled in.";
	}

	// The player who fired it. `target` is the engine's shooter pointer
	// and is what we want, but it is also what several Actor paths
	// rewrite, so the reference is held explicitly.
	Actor mShooter;

	// -----------------------------------------------------------------
	// PULL THE PLAYER TO THE HOOK. Wall/geometry hit.
	//
	// Direction is hook -> player REVERSED, i.e. player -> hook, scaled
	// by distance so a long shot pulls harder and a short one does not
	// fling you. The /12 divisor is the reference's, kept because it is
	// tuned and because changing it changes the feel of the whole
	// mechanic; it is exposed as a cvar rather than edited here.
	// -----------------------------------------------------------------
	void PullPlayer()
	{
		if (!mShooter) return;

		Vector3 delta = pos - mShooter.pos;
		double dist = delta.xy.Length();

		double div = max(1.0, RS_HookSettings.CVFloat("rs_hook_pull_divisor", 12.0));
		double zdiv = max(1.0, RS_HookSettings.CVFloat("rs_hook_pull_zdivisor", 4.0));

		if (dist > 1.0)
		{
			double push = dist / div;
			mShooter.vel.x += (delta.x / dist) * push;
			mShooter.vel.y += (delta.y / dist) * push;
		}

		// Vertical is divided separately and more gently -- the reference
		// uses a different divisor for Z for the same reason, and it is
		// what keeps a hook fired at a ledge from launching you over it.
		mShooter.vel.z += delta.z / zdiv;
	}

	// -----------------------------------------------------------------
	// PULL THE MONSTER TO THE PLAYER. Body hit.
	//
	// The mirror of the above: same maths, opposite endpoints. A monster
	// with +NOFORWARDFALL or huge mass still gets moved, deliberately --
	// the hook is not a shove, it is a chain.
	// -----------------------------------------------------------------
	void PullVictim(Actor victim)
	{
		if (!victim || !mShooter) return;
		if (victim.bDONTTHRUST) return;

		Vector3 delta = mShooter.pos - victim.pos;
		double dist = delta.xy.Length();

		double div = max(1.0, RS_HookSettings.CVFloat("rs_hook_pull_divisor", 12.0));
		double zdiv = max(1.0, RS_HookSettings.CVFloat("rs_hook_pull_zdivisor", 4.0));

		if (dist > 1.0)
		{
			double push = dist / div;
			victim.vel.x += (delta.x / dist) * push;
			victim.vel.y += (delta.y / dist) * push;
		}
		victim.vel.z += delta.z / (zdiv * 0.5);
	}

	// A body hit resolves through the tracer pointer (+HITTRACER), which
	// is what the flag is for -- the thing we struck without damaging it.
	override int DoSpecialDamage(Actor victim, int damage, Name damagetype)
	{
		return 0;
	}

	States
	{
	Spawn:
		// The limited frame count IS the range limit.
		HOOK AAAAAAAAAA 2 A_StartSound("rs_hook/loop", CHAN_BODY);
		Stop;

	Death:
		// Geometry.
		HOOK B 0 A_StartSound("rs_hook/hit/terrain", CHAN_BODY);
		HOOK B 0 { PullPlayer(); }
		HOOK B 16;
		Stop;

	XDeath:
		// A body, gibbed.
		HOOK B 0 A_StartSound("rs_hook/hit/flesh", CHAN_BODY);
		HOOK B 0 { PullVictim(tracer); }
		HOOK B 16;
		Stop;

	Crash:
		// A body, not gibbed. Same outcome -- the reference routes both
		// through one path and so do we.
		HOOK B 0 A_StartSound("rs_hook/hit/flesh", CHAN_BODY);
		HOOK B 0 { PullVictim(tracer); }
		HOOK B 16;
		Stop;
	}
}


// =====================================================================
// THE DRIVER. One per player, ticked from PlayerThink.
//
// Same shape and the same reasoning as RS_GrenadeThrower next door:
// PlayerThink runs BEFORE the weapon thinks, so a button read here is
// seen before CheckWeaponFire looks at it. An EventHandler's WorldTick
// runs AFTER the player has already thought (p_tick.cpp:175 then :178),
// which is why input handling cannot live there.
// =====================================================================
class RS_HookThrower : Object
{
	bool mHeld;      // button state last tic, for edge detection
	int  mCooldown;  // tics until the next shot is allowed

	// BT_USER1 -- KEYCONF binds it, and it is the button the reference
	// used. GZDoom's user buttons are free for mods.
	static bool ButtonDown(PlayerPawn pawn)
	{
		return pawn && pawn.player
		    && (pawn.player.original_cmd.buttons & BT_USER1);
	}

	void Update(PlayerPawn pawn)
	{
		if (!pawn || !pawn.player) return;

		if (mCooldown > 0)
			mCooldown--;

		bool down = ButtonDown(pawn);

		// Rising edge only. A held button fires once, not every tic.
		if (down && !mHeld && mCooldown <= 0 && RS_HookSettings.Enabled())
		{
			Fire(pawn);
			mCooldown = max(1, RS_HookSettings.CVInt("rs_hook_cooldown", 20));
		}

		mHeld = down;
	}

	// -----------------------------------------------------------------
	// FIRE.
	//
	// The bit sweep runs FIRST and unconditionally -- before the
	// projectile is even spawned, so it happens whether or not the shot
	// goes anywhere. That ordering is deliberate: the sweep is a property
	// of firing the hook, not of hitting something with it.
	// -----------------------------------------------------------------
	void Fire(PlayerPawn pawn)
	{
		SweepBits(pawn);

		int hand = RS_HookSettings.Hand();

		// SpawnPlayerMissile, NOT A_FireProjectile. A_FireProjectile is
		// declared on StateProvider (stateprovider.zs:239) -- it is a
		// weapon/CustomInventory state action and does not exist on a
		// PlayerPawn, so calling it from here does not compile. This is
		// the Actor-level equivalent (actor.zs:771) and it is what the
		// rest of this file's aiming needs anyway.
		//
		// ALF_ISOFFHAND is how the rest of the arsenal tells the VR aim
		// code which controller is doing the aiming (RS_Weapon uses the
		// same flag on every fire path); without it an offhand shot
		// leaves from the mainhand's pose.
		double ofs = RS_HookSettings.CVFloat("rs_hook_hand_offset", 8.0);
		if (hand == RS_HookSettings.HAND_MAIN) ofs = -ofs;

		int aimflags = (hand == RS_HookSettings.HAND_OFF) ? ALF_ISOFFHAND : 0;

		FTranslatedLineTarget lt;
		Actor spawned, unused;
		[spawned, unused] = pawn.SpawnPlayerMissile("RS_HookShot",
			1e37, ofs, 0, 0, lt, false, false, aimflags);

		let shot = RS_HookShot(spawned);
		if (shot)
			shot.mShooter = pawn;
	}

	// -----------------------------------------------------------------
	// THE BIT SWEEP. Every loose bit within the radius is dragged to the
	// player.
	//
	// Owner ruling 2026-08-07: "whenever we fire it, it runs a small
	// radian detectection for bits and brings them toi the player,
	// regardlkss of the polayer is flying to a wall or a monster is
	// flying to the player".
	//
	// GIVES the bit velocity toward the player rather than teleporting
	// it: a bit that arrives instantly is indistinguishable from a bit
	// that was picked up remotely, and watching them come is the whole
	// appeal. It also means a bit behind a wall does not phase through
	// one -- it just bumps into it, which is correct.
	// -----------------------------------------------------------------
	void SweepBits(PlayerPawn pawn)
	{
		if (!pawn) return;

		double radius = RS_HookSettings.CVFloat("rs_hook_bit_radius", 512.0);
		double force  = RS_HookSettings.CVFloat("rs_hook_bit_force", 12.0);
		if (radius <= 0 || force <= 0) return;

		let it = BlockThingsIterator.Create(pawn, radius);
		while (it.Next())
		{
			let mo = it.thing;
			if (!mo || mo == pawn) continue;
			if (!RS_BitUtil.IsBit(mo)) continue;

			Vector3 delta = pawn.pos - mo.pos;
			double dist = delta.Length();
			if (dist > radius) continue;

			if (dist < 1.0)
				continue;   // already on top of us; the pickup will fire

			// Constant speed rather than distance-scaled: a far bit and a
			// near one should both arrive, and scaling by distance makes
			// the far ones crawl.
			mo.vel.x += (delta.x / dist) * force;
			mo.vel.y += (delta.y / dist) * force;
			mo.vel.z += (delta.z / dist) * force * 0.5;

			// Bits are dropped items sitting on floors; without this they
			// slide rather than travel.
			mo.bNOGRAVITY = true;
		}
	}
}
