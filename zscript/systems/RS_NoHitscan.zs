// =====================================================================
// RS_NoHitscan -- every monster hitscan becomes a travelling projectile.
//
// Ported 1:1 from NoMoreHitscans (GZDoom minimod, Jan 2025), with the
// classes renamed into the RS_ namespace and the cvars onto rs_.
//
// WHY THIS SHAPE, AND WHY IT IS NOT A SWEEP OVER OUR OWN FILES:
// this tree has 163 hitscan call sites across 20 monster files --
// Chaingunner 34, Arachnotron 29, Shotgunner 28, Zombieman 21,
// Mastermind 15. Every one of them carries a CHP-faithful spread,
// pellet count and damage roll that was expensive to get right and has
// been got wrong before. This layer touches NONE of them. It intercepts
// the engine's hitscan at the event level and flies a projectile along
// the line the hitscan would have taken.
//
// HOW IT WORKS
//   1. WorldHitscanPreFired fires before the engine resolves a hitscan.
//      Returning true CANCELS the engine's version.
//   2. The gate is monsters only, never players, and only full-range
//      (>= MISSILERANGE) attacks -- a deliberately narrow filter, kept
//      from the original.
//   3. The replacement projectile is +NOINTERACTION: it does NOT use
//      engine collision at all. Every tic it runs its own LineTracer
//      over the distance it is about to travel and reproduces the whole
//      hitscan impact contract by hand -- puff spawn with the right
//      flags, DoSpecialDamage on the puff, DamageMobj with
//      DMG_INFLICTOR_IS_PUFF, blood, TraceBleedAngle, decals, sky, and
//      RemoteActivate so shootable switches still work.
//
// KNOWN AND DELIBERATE:
//   * A_CustomRailgun is NOT caught. The event fires from P_LineAttack;
//     railguns go through P_RailAttack. T10's five-beam Unmaker barrage
//     therefore stays instant. That is the correct outcome for now -- a
//     rail beam reads as a beam, not a bullet -- and the segmented
//     Quake-2-style rail is the thing that will replace it properly.
//     RS_HitscanReplacer's trace-and-impact half is written to be the
//     base that beam builds on, which is why HandleCollision and
//     GetNormalFromTracer are separate virtuals rather than inlined.
//   * Attacks authored with a range SHORTER than MISSILERANGE pass
//     through untouched and stay hitscan.
//   * +NOINTERACTION means nothing reactive sees these in flight.
// =====================================================================

class RS_HitscanHandler : EventHandler
{
	override bool WorldHitscanPreFired(WorldEvent e)
	{
		if (!rs_nohitscan_enabled) return false;

		if (e.thing && e.thing.bIsMonster && !e.thing.player
		    && e.AttackDistance >= MISSILERANGE)
		{
			let hr = RS_HitscanReplacer.FireReplacer(
				shooter:      e.thing,
				damage:       e.damage,
				pufftype:     e.AttackPuffType,
				damageType:   e.damageType,
				spawnheight:  e.AttackZ,
				// Relative to the shooter's facing -- A_SpawnProjectile
				// adds the actor's own angle back on.
				angle:        e.AttackAngle - e.thing.angle,
				pitch:        e.AttackPitch,
				spawnofs_xy:  e.AttackOffsetSide
			);
			return hr != null;
		}
		return false;
	}
}

class RS_HitscanReplacer : Actor
{
	int rs_damagefromhitscan;
	class<Actor> rs_pufftype;

	Default
	{
		+MISSILE
		+NOINTERACTION
		+FORCEXYBILLBOARD
		+BLOODSPLATTER
		Speed 80;
		RenderStyle 'Add';
		Height 0;
		Radius 0;
	}

	int GetProjDamage()
	{
		return ApplyDamageFactor(damageType, rs_damagefromhitscan);
	}

	static RS_HitscanReplacer FireReplacer(Actor shooter, int damage,
	                                       class<Actor> pufftype, Name damageType,
	                                       double spawnheight, double spawnofs_xy,
	                                       double angle, double pitch)
	{
		if (!shooter) return null;
		if (!spawnheight) spawnheight = 32;
		let proj = RS_HitscanReplacer(shooter.A_SpawnProjectile('RS_HitscanReplacer',
			spawnheight: spawnheight,
			angle: angle,
			pitch: pitch,
			flags: CMF_AIMDIRECTION));
		if (proj)
		{
			proj.rs_damagefromhitscan = damage;
			proj.rs_pufftype = pufftype;
			proj.damageType = damageType;
		}
		return proj;
	}

	virtual void HandleCollision()
	{
		let collision = RS_ProjCollisionController.CheckCollision(
			self, self.pos, vel.Unit(), vel.Length());
		if (!collision) return;
		let hittype = collision.results.HitType;

		if (hitType == TRACE_HitNone)
			return;

		Vector2 pAngles = (self.angle, self.pitch);

		let puffdefs = GetDefaultByType(rs_pufftype);
		double puffsize = 1;
		switch (hittype)
		{
			case TRACE_HitActor:
			case TRACE_HitWall:
				puffsize = puffdefs.radius;
				break;
			case TRACE_HitCeiling:
				puffsize = puffdefs.height;
				break;
		}
		Vector3 puffpos = GetNormalFromTracer(collision.results,
		                                      distance: puffsize, fromEnd: true);
		A_Stop();

		if (hitType == TRACE_HitActor && collision.projectileVictim)
		{
			let victim = collision.projectileVictim;
			// Normally the shooter should always be there, but who knows:
			Actor source = target ? target : Actor(self);

			// Initial damage, modified by the victim's damage factor.
			int dealtDamage = GetProjDamage();

			int puffFlags = PF_HITTHING;
			if (!victim.bNOBLOOD && !victim.bDORMANT)
				puffFlags |= PF_HITTHINGBLEED;

			let puff = SpawnPuff(rs_pufftype,
				pos: puffpos,
				hitdir: pAngles.x,
				particledir: pAngles.x + 180,
				updown: puffdefs.vel.z,
				flags: puffFlags,
				victim: victim
			);
			if (puff)
			{
				puff.A_Face(source);
				if (bHITTRACER)     puff.tracer = victim;
				if (bHITMASTER)     puff.master = victim;
				if (bHITTARGET)     puff.target = victim;
				if (bPUFFGETSOWNER) puff.target = target;
				// Let the puff's DoSpecialDamage() modify the damage.
				// This is what keeps custom puffs behaving -- ours carry
				// real logic, so skipping it would quietly flatten them.
				dealtDamage = puff.DoSpecialDamage(victim, dealtDamage, damagetype);
			}

			dealtDamage = victim.DamageMobj(puff ? puff : Actor(self), source,
			                                dealtDamage, damageType,
			                                DMG_INFLICTOR_IS_PUFF);

			if (!victim.bNOBLOOD && !victim.bDORMANT)
			{
				victim.SpawnBlood(puffpos, pAngles.x + 180, dealtDamage);
				victim.TraceBleedAngle(dealtDamage, pAngles.x, pAngles.y);
				if (puff && !puff.bPUFFONACTORS)
					puff.Destroy();
			}
			SetStateLabel("Death");
			return;
		}

		switch (hitType)
		{
		case TRACE_HitWall:
			// Shootable switches and gun-triggered lines still work.
			if (collision.results.HitLine && target)
			{
				collision.results.HitLine.RemoteActivate(
					target, collision.results.Side, SPAC_Impact, pos);
			}
		case TRACE_HitCeiling:
		case TRACE_HitFloor:
			name decaltype;
			let puff = SpawnPuff(rs_pufftype,
				pos: puffpos,
				hitdir: pAngles.x,
				particledir: pAngles.x + 180,
				updown: puffdefs.vel.z,
				flags: 0
			);
			if (puff)
				decaltype = puff.GetDecalName();
			if (target && decaltype == 'none')
				decaltype = target.GetDecalName();
			if (decaltype != 'none')
			{
				A_SprayDecal(decaltype, collision.results.distance,
				             direction: collision.results.hitVector);
			}
			SetStateLabel("Death");
			break;
		case TRACE_HasHitSky:
			SpawnPuff(rs_pufftype,
				pos: puffpos,
				hitdir: pAngles.x,
				particledir: pAngles.x + 180,
				updown: puffdefs.vel.z,
				flags: PF_HITSKY
			);
			SetStateLabel("Null");
			break;
		}
	}

	Vector3 GetNormalFromTracer(TraceResults results, double distance = 1,
	                            bool fromEnd = false)
	{
		let hittype = results.hittype;
		vector3 hitnormal = -results.HitVector;
		if (hittype == TRACE_HitFloor)
		{
			if (results.ffloor)
				hitnormal = -results.ffloor.top.Normal;
			else
				hitnormal = results.HitSector.floorplane.Normal;
		}
		else if (hittype == TRACE_HitCeiling)
		{
			if (results.ffloor)
				hitnormal = -results.ffloor.bottom.Normal;
			else
				hitnormal = results.HitSector.ceilingplane.Normal;
		}
		else if (hittype == TRACE_HitWall && results.HitLine)
		{
			hitnormal.xy = (-results.HitLine.delta.y, results.HitLine.delta.x).Unit();
			if (results.Side == Line.front)
				hitnormal.xy *= -1;
			hitnormal.z = 0;
		}
		hitnormal *= distance;
		if (fromEnd)
			return level.Vec3Offset(results.HitPos, hitnormal);
		return hitnormal;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		alpha = rs_nohitscan_alpha;
		vel = vel.Unit() * rs_nohitscan_speed;
		A_FaceMovementDirection();
		HandleCollision();

		if (!rs_pufftype) rs_pufftype = 'BulletPuff';
		let puffdefs = GetDefaultByType(rs_pufftype);
		// Inherit the puff's pass-through rules so species, ghost and
		// thrubits behaviour survives the swap from hitscan to missile.
		bHITTRACER      = puffdefs.bHITTRACER;
		bHITMASTER      = puffdefs.bHITMASTER;
		bHITTARGET      = puffdefs.bHITTARGET;
		bPUFFGETSOWNER  = puffdefs.bPUFFGETSOWNER;
		bALLOWTHRUFLAGS = puffdefs.bALLOWTHRUFLAGS;
		bTHRUSPECIES    = puffdefs.bTHRUSPECIES;
		bTHRUGHOST      = puffdefs.bTHRUGHOST;
		thruBits        = puffdefs.thruBits;
		species         = puffdefs.Species;
	}

	override void Tick()
	{
		Super.Tick();
		if (isFrozen() || !InStateSequence(curstate, spawnstate))
			return;

		HandleCollision();
	}

	States {
	Spawn:
		AMRK A -1 bright;
		stop;
	Death:
		TNT1 A 1;
		stop;
	}
}

// The trace. Separate class because it is a LineTracer, and because the
// segmented rail beam will reuse it verbatim -- the only thing that
// changes there is who decides the next segment's direction.
class RS_ProjCollisionController : LineTracer
{
	Actor projectileSource;
	Actor projectileVictim;

	static RS_ProjCollisionController CheckCollision(Actor source, Vector3 start,
	                                                 Vector3 direction, double range)
	{
		let tracer = new('RS_ProjCollisionController');
		tracer.projectileSource = source;
		if (tracer.Trace(start, source.cursector, direction, range,
			TRACE_HitSky,
			wallmask: Line.ML_BLOCKEVERYTHING | Line.ML_BLOCKHITSCAN,
			ignore: source) == false)
		{
			return null;
		}
		return tracer;
	}

	override ETraceStatus TraceCallback()
	{
		if (results.HitType == TRACE_HitActor && results.HitActor)
		{
			let victim = results.HitActor;
			// hit its shooter:
			if (projectileSource.target == victim)
				return TRACE_Skip;
			// not shootable:
			if (!victim.bSolid && !victim.bShootable)
				return TRACE_Skip;
			// ghost:
			if (victim.bGHOST && projectileSource.bTHRUGHOST)
				return TRACE_Skip;
			// +ALLOWTHRUBITS and thrubits match:
			if (projectileSource.bALLOWTHRUBITS
			    && (projectileSource.thruBits & victim.thruBits))
				return TRACE_Skip;
			// +ALLOWTHRUFLAGS +THRUSPECIES and species matches:
			if (projectileSource.bALLOWTHRUFLAGS && projectileSource.bTHRUSPECIES
			    && projectileSource.species == victim.species)
				return TRACE_Skip;
			// +MTHRUSPECIES and the shooter's species matches the victim:
			if (projectileSource.target && projectileSource.bMTHRUSPECIES
			    && projectileSource.target.species == victim.species)
				return TRACE_Skip;

			projectileVictim = victim;
			return TRACE_Stop;
		}

		switch (results.HitType)
		{
			case TRACE_HitWall:
			case TRACE_HitFloor:
			case TRACE_HitCeiling:
			case TRACE_HasHitSky:
				return TRACE_Stop;
				break;
		}

		return TRACE_Skip;
	}
}
