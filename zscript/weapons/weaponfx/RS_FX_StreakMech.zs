// =====================================================================
// RS_FX_StreakMech -- the Streak pack's MECHANICS, as opposed to its
// art (RS_FX_Streak.zs). Rebuilt in ZScript from the source pack's ACS,
// which is the whole reason this project prefers ZScript: most of that
// ACS was scaffolding for a language with no floats, no vectors and no
// real function calls. Rebuilt, the mechanics are a fraction of the size
// and can be called directly instead of through named-script dispatch.
//
// Nothing here is wired to a weapon. Each piece is a static call or a
// standalone token, so an RS_AttackProfile, an affix, or a monster can
// use it without any of them knowing about each other.
// =====================================================================

// ---------------------------------------------------------------------
// LINE-SEGMENT (LANCE) DAMAGE
//
// Damages everything within `radius` of a LINE running `length` units
// along a direction -- a capsule, not a sphere. This is the damage shape
// RS did not have: point damage and radius blasts were the only two
// options, and neither describes a spear, a lance, or a beam that should
// hurt everything it passes through on the way to the wall.
//
// Pairs with RS_ST_Beam.Draw() in RS_FX_Streak.zs: that draws the beam,
// this damages along it. Deliberately split so either can be used alone
// -- a purely cosmetic tether draws without damaging, and a damage lance
// can wear any visual.
//
// The perpendicular-distance test is a standard point-to-segment
// projection: project the victim onto the line, clamp to the segment's
// ends, then measure. Clamping is what stops it damaging things behind
// the firer or past the endpoint.
// ---------------------------------------------------------------------
// `play` scope is required, not decorative: DamageMobj is a play-scope
// call, and a plain class defaults to data scope where it is illegal.
class RS_ST_LanceHit play
{
	static void Apply(Actor source, Vector3 start, Vector3 dir,
	                  double length, double radius, int damage,
	                  Name damageType = 'None', Actor ignore = null)
	{
		if (!source || length <= 0 || radius <= 0) return;
		if (dir.Length() <= 0) return;
		dir = dir.Unit();

		// BlockThingsIterator over the whole capsule would need a box big
		// enough to contain it; a ThinkerIterator is simpler and this
		// fires once per shot, not per tic.
		let it = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(it.Next()))
		{
			if (mo == source || mo == ignore) continue;
			if (!mo.bShootable || mo.health <= 0) continue;
			if (mo.bNoInteraction) continue;

			// Project the victim onto the lance axis.
			Vector3 toTarget = mo.pos + (0, 0, mo.height * 0.5) - start;
			double along = toTarget dot dir;

			// Clamped to the segment, so nothing behind the muzzle or
			// past the tip is caught.
			if (along < 0 || along > length) continue;

			Vector3 closest = start + dir * along;
			double perp = (mo.pos + (0, 0, mo.height * 0.5) - closest).Length();
			if (perp > radius + mo.radius) continue;

			mo.DamageMobj(source, source, damage, damageType);
		}
	}
}

// ---------------------------------------------------------------------
// BURN (fire damage over time)
//
// A token that sits on the victim and deals damage on an interval until
// it runs out. REFRESHES RATHER THAN STACKS: re-applying takes the
// higher of the two remaining durations instead of adding them. That is
// the source's behaviour and it is the correct one -- a stacking burn on
// a rapid-fire flame weapon multiplies into nonsense within a second.
//
// The intended consumer is a flame/incendiary attack: a projectile's
// Death state calls RS_ST_Burn.Apply(victim, ...). Nothing calls it yet.
// ---------------------------------------------------------------------
class RS_ST_BurnToken : Inventory
{
	int BurnTicsLeft;
	int BurnDamage;
	int BurnInterval;
	int burnClock;
	Actor BurnSource;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
	}

	override void DoEffect()
	{
		Super.DoEffect();
		if (!Owner || Owner.health <= 0)
		{
			Destroy();
			return;
		}

		if (BurnTicsLeft <= 0)
		{
			Destroy();
			return;
		}

		BurnTicsLeft--;

		// Cosmetic: a flame every so often so a burning target reads as
		// burning without spawning one per tic.
		if ((BurnTicsLeft % 6) == 0)
		{
			Owner.A_SpawnItemEx("RS_ST_Flame",
				frandom(-8, 8), frandom(-8, 8), frandom(0, Owner.height),
				0, 0, frandom(0.5, 1.5),
				0, SXF_CLIENTSIDE);
		}

		if (++burnClock < BurnInterval) return;
		burnClock = 0;

		// Source is passed through so kills credit the firer rather than
		// the victim, and so ally checks upstream still mean something.
		Actor src = BurnSource ? BurnSource : Owner;
		Owner.DamageMobj(null, src, max(1, BurnDamage), 'Fire');
	}
}

class RS_ST_Burn play
{
	// duration/interval in tics (35 = 1 second).
	static void Apply(Actor victim, Actor source, int damage = 4,
	                  int duration = 105, int interval = 12)
	{
		if (!victim || !victim.bShootable || victim.health <= 0) return;
		if (victim.bNoDamage) return;

		let tok = RS_ST_BurnToken(victim.FindInventory("RS_ST_BurnToken"));
		if (!tok)
		{
			tok = RS_ST_BurnToken(victim.GiveInventoryType("RS_ST_BurnToken"));
			if (!tok) return;
		}

		// Refresh, never stack -- see the class header.
		tok.BurnTicsLeft = max(tok.BurnTicsLeft, duration);
		tok.BurnDamage   = max(tok.BurnDamage, damage);
		tok.BurnInterval = interval > 0 ? interval : 12;
		tok.BurnSource   = source;
	}
}

// ---------------------------------------------------------------------
// MASS-NORMALIZED KNOCKBACK
//
// Thrust divided by the victim's mass, then square-rooted. The sqrt is
// the entire point and is easy to miss when reading the original: plain
// division makes a Zombieman fly roughly twenty times further than a
// Baron off the same blast, which looks broken. The sqrt compresses that
// spread so light things still fly further, but not absurdly so.
// ---------------------------------------------------------------------
class RS_ST_Push play
{
	static void Apply(Actor victim, Vector3 origin, double power,
	                  bool causePain = true)
	{
		if (!victim || power <= 0) return;
		if (victim.bDontThrust || victim.bNoInteraction) return;

		Vector3 away = victim.pos + (0, 0, victim.height * 0.5) - origin;
		double dist = away.Length();
		if (dist <= 0)
		{
			// Dead centre: pick any direction rather than dividing by zero.
			away = (frandom(-1, 1), frandom(-1, 1), 0.5);
			dist = away.Length();
			if (dist <= 0) return;
		}
		away = away / dist;

		double mass = max(1, victim.mass);
		double thrust = sqrt(power / mass);

		victim.vel += away * thrust;

		if (causePain && !victim.bNoPain && !victim.bInvulnerable
		    && !victim.bDormant && victim.health > 0)
		{
			victim.A_Pain();
		}
	}
}

// ---------------------------------------------------------------------
// SURFACE-STICKING PROJECTILE
//
// Sticks where it lands and orients to the surface it hit, instead of
// sitting at whatever angle it happened to be flying. The alignment is
// the fiddly half and the reason this is worth lifting rather than
// re-deriving: a grenade flat against a wall reads as stuck, the same
// grenade at its flight angle reads as floating.
//
// Subclass it and give it a Detonate state; nothing here explodes on its
// own, so the damage stays the subclass's business.
// ---------------------------------------------------------------------
class RS_ST_StickyProjectile : Actor
{
	bool Stuck;
	int  StickFuse;

	Default
	{
		Projectile;
		-NOGRAVITY
		+CANBOUNCEWATER
		Gravity 0.9;
		Radius 6;
		Height 6;
		Speed 30;
	}

	// Tics until Detonate after sticking. 0 (the field default) = stay
	// until something else destroys it -- a proximity mine rather than a
	// timed charge. Set in a subclass's Default as
	// `RS_ST_StickyProjectile.Fuse 70;`, never as a bare assignment: a
	// plain `StickFuse = 0;` inside a Default block is a parse error.
	property Fuse : StickFuse;

	override int SpecialMissileHit(Actor victim)
	{
		// Stick to bodies too, not just geometry.
		if (victim && victim.bShootable && victim != target)
		{
			StickTo(victim);
			return 0;
		}
		return -1;
	}

	// What this sticks to, for the follow logic. NOT `master`.
	//
	// `master` used to hold it, and that would have quietly broken XP.
	// Every RS projectile carries `master = the firing weapon` -- set at
	// spawn in RS_Weapon (RS_FireProfileBullet / FireAffixPartRound /
	// FireProfileHeavy) -- and GunBonsai reads exactly that pointer to
	// decide which hand earned the damage
	// (zscript/gunbonsai/EventHandler.zsc, the offhand attribution test).
	// Overwriting it with the victim would make the round stop naming its
	// firer, so its damage, its XP and its on-kill procs would fall
	// through to whatever the fallback guessed.
	//
	// Latent rather than live -- nothing currently fires this class --
	// which is the cheapest possible moment to fix it. A separate field
	// costs nothing and leaves the sacred pointer alone.
	Actor StuckTo;

	void StickTo(Actor victim)
	{
		if (Stuck) return;
		Stuck = true;
		bNoGravity = true;
		bMissile = false;
		vel = (0, 0, 0);
		StuckTo = victim;
		if (StickFuse > 0) SetStateLabel("Detonate");
	}

	// Align flat to whatever plane was hit. BlockingLine covers walls;
	// floor/ceiling fall back to a flat lie, which is what those planes
	// mean anyway.
	void AlignToSurface()
	{
		bNoGravity = true;
		vel = (0, 0, 0);

		if (BlockingLine)
		{
			Vector2 n = (-BlockingLine.delta.y, BlockingLine.delta.x).Unit();
			// Face out of the wall, not into it.
			double wallAngle = atan2(n.y, n.x);
			if (BlockingLine.frontsector == cursector) wallAngle += 180;
			angle = wallAngle;
			pitch = 0;
		}
		else
		{
			pitch = (pos.z <= floorz) ? -90 : 90;
		}
	}

	States
	{
	Spawn:
		TNT1 A 1;
		Loop;

	Death:
		TNT1 A 0
		{
			AlignToSurface();
			Stuck = true;
			bMissile = false;
		}
		Goto Stick;

	// Held until the fuse (if any) or an outside trigger.
	Stick:
		TNT1 A 1 A_JumpIf(StickFuse > 0 && --StickFuse <= 0, "Detonate");
		Loop;

	Detonate:
		TNT1 A 0;
		Stop;
	}
}
