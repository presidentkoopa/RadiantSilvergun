// =====================================================================
// RS_FX_Streak -- the Streak (RS_ST_) pack's combat FX.
//
// PACK RESOURCES ONLY -- no weapon classes were imported. Everything here
// is a piece an RS_AttackProfile can point at: a ProjectileClass, an
// ImpactPuff, a Trail, an ExplosionVisual. Nothing references a weapon
// and nothing is wired to one; RS_Catalog is the only consumer.
//
// The trail/puff pair at the top is the exception in one respect -- it is
// what RS_Catalog.TRAIL_Ballistic()/PUFF_Bullet() now return, so it is the
// arsenal-wide default for ballistic rounds rather than an opt-in skin.
//
// Sprite codes were reallocated on import (source lumps are 4-char codes
// that would collide with this tree's own):
//   RST0 tracers      RST1 tracers      RSI8/RSI9 fire
//   RSR8/RSR9 projectiles                RSPB/RSPC plasma
//   RSF9 flares       RSED explosions    RSB2 bullets
//   RSK6-RSK9 smoke   RSS4 sparks
// Sounds are logical rs_st/* names in SNDINFO, files in
// sounds/rs_st_weapon/.
// =====================================================================

class RS_StreakTrail : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY +NOTIMEFREEZE
		RenderStyle "Add";
		Scale 0.35;
		Alpha 0.85;
	}
	States
	{
	Spawn:
		RST0 A 1 Bright A_FadeOut(0.20);
		RST0 B 2 Bright A_FadeOut(0.25);
		Stop;
	}
}

class RS_StreakPuff : RS_EnhancedBulletPuff
{
	States
	{
	Puff:
		RST0 CDE 1 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// FIRE
// RS_ST_FlameJet is the profile-usable one: a real travelling round, so
// it drops into a profile's ProjectileClass exactly like RS_GH_FlameJet
// does. Short life and low alpha read as a cone rather than a bullet.
// RS_ST_Flame/RS_ST_FireCloud are cosmetic-only -- no damage, no
// collision -- for ImpactPuff/ExplosionVisual slots.
// ---------------------------------------------------------------------
class RS_ST_FlameJet : RS_BallisticFired
{
	Default
	{
		DamageType "Fire";
		Scale 0.5;
		Alpha 0.9;
		RenderStyle "Add";
		+BRIGHT
	}
	States
	{
	Spawn:
		RSI8 ABCDEFGHIJKLMNOP 2 Bright;
		Stop;

	Death:
		TNT1 A 0
		{
			A_StartSound("rs_st/flame_stop", CHAN_AUTO);
			// Same override contract as the RS_BallisticFired base: the
			// honest default here is "no puff, just the sound", so only
			// spawn what a profile actually asked for.
			if (ImpactPuffOverride) Spawn(ImpactPuffOverride, pos);
			if (ImpactSparkOverride) Spawn(ImpactSparkOverride, pos);
		}
		Stop;
	}
}

// Cosmetic flame burst. Five entry points into one 15-frame animation so
// a cluster of them doesn't animate in lockstep -- that staggering is the
// source's own behaviour, kept because it's what stops a flame wall
// looking like one sprite drawn many times.
class RS_ST_Flame : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY
		+THRUACTORS +PAINLESS +DONTSPLASH
		RenderStyle "Add";
		Scale 0.5;
		Alpha 0.6;
		Radius 0;
		Height 0;
	}
	States
	{
	Spawn:
		RSI8 A 0 Bright NoDelay A_Jump(256, "Fire1", "Fire2", "Fire3", "Fire4", "Fire5");
		Goto Fire1;
	Fire1:
		RSI8 BCDEFGHIJKLMNOP 1 Bright;
		Stop;
	Fire2:
		RSI8 DEFGHIJKLMNOP 1 Bright;
		Stop;
	Fire3:
		RSI8 FGHIJKLMNOP 1 Bright;
		Stop;
	Fire4:
		RSI8 HIJKLMNOP 1 Bright;
		Stop;
	Fire5:
		RSI8 JKLMNOP 1 Bright;
		Stop;
	}
}

// Big billowing fire cloud -- the heavy end of the fire set. Cosmetic;
// pair it with a heavy profile's ExplosionVisual, never as the damage.
class RS_ST_FireCloud : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY
		+THRUACTORS +PAINLESS +DONTSPLASH
		RenderStyle "Add";
		Scale 0.6;
		Alpha 0.9;
		Radius 0;
		Height 0;
	}
	States
	{
	Spawn:
		RSI9 EFGHIJKLMNO 2 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// ENERGY
// ---------------------------------------------------------------------
class RS_ST_EnergyShot : Actor
{
	int RolledDamage;
	double ShotCritChance;

	Default
	{
		Projectile;
		Radius 13; Height 8; Speed 30;
		Damage 100;
		Scale 0.9; Alpha 0.95; RenderStyle "Add";
		+BRIGHT +FORCEXYBILLBOARD
		SeeSound "rs_st/bfg_fire";
		DeathSound "rs_st/bfg_explode";
	}

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		SetDamage(finalDamage);
		ShotCritChance = critChance;
	}

	States
	{
	Spawn:
		RSR8 ABCDEFGH 2 Bright;
		Loop;
	Death:
		RSPB ABCD 3 Bright;
		Stop;
	}
}

// The spray/burst half of the energy set, split out so an affix can take
// the burst without the ball (same reason the MG blast pieces are
// separate entries rather than one composite).
class RS_ST_EnergySpray : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY
		RenderStyle "Add";
		Scale 0.7;
		Alpha 0.9;
		Radius 0;
		Height 0;
	}
	States
	{
	Spawn:
		RSPB ABCD 3 Bright A_FadeOut(0.12);
		Stop;
	}
}

// Arc/lance impact flash -- 14 frames, the longest cosmetic in the pack.
class RS_ST_ArcImpact : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY
		RenderStyle "Add";
		Scale 0.55;
		Alpha 0.9;
		Radius 0;
		Height 0;
	}
	States
	{
	Spawn:
		RSPC FGHIJKLMNOPQRS 2 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// GRENADE
// Subclasses the existing launched-grenade body rather than restating
// arc/bounce/blast behaviour -- this is a re-skin, so only the Spawn
// sprite differs. RSR9 is an 8-way rotation set, so it holds its
// orientation as you strafe around it.
// ---------------------------------------------------------------------
class RS_ST_Grenade : RS_GH_GrenadeLaunched
{
	States
	{
	Spawn:
		RSR9 A 2;
		Loop;
	}
}

// ---------------------------------------------------------------------
// SMALL PARTICLES -- trail motes and a glow blob, for Trail slots and
// as spawn-fodder inside other effects.
// ---------------------------------------------------------------------
class RS_ST_EmberTrail : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY +NOTIMEFREEZE
		RenderStyle "Add";
		Scale 0.3;
		Alpha 0.9;
	}
	States
	{
	Spawn:
		RST1 A 2 Bright A_FadeOut(0.08);
		Loop;
	}
}

// ---------------------------------------------------------------------
// RING-BURST EXPLOSION
//
// The assembled cosmetic blast: a horizontal ring of outward-flying
// motes, a shower of bouncing sparks that each trail their own smoke, a
// bank of smoke puffs, then a finishing flash. Ported from the source's
// multi-stage client-side explosion.
//
// CARRIES NO DAMAGE. It is a look, spawned alongside a real A_Explode,
// never instead of one -- so it drops into a heavy profile's
// ExplosionVisual slot without touching that projectile's splash.
//
// The spark direction set is picked from where the blast went off: a
// floor hit throws sparks up and out, a ceiling hit throws them down,
// open air throws them evenly. That check is the source's and is the
// reason the effect reads as grounded instead of floating.
// ---------------------------------------------------------------------
class RS_ST_Explosion : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY
		RenderStyle "Add";
		Radius 0;
		Height 0;
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			A_StartSound("rs_st/rocket_explode", CHAN_AUTO);

			// Ring: 36 motes at 10-degree steps, thrown outward. One full
			// turn -- the source stepped a counter to 360 the same way.
			for (int i = 0; i < 36; i++)
			{
				A_SpawnItemEx("RS_ST_RingParticle",
					0, 0, 0,
					32, 0, 0,
					i * 10,
					SXF_CLIENTSIDE);
			}

			// Sparks: bias by what we hit.
			bool nearFloor   = (pos.z - floorz) < 1;
			bool nearCeiling = (ceilingz - pos.z) < 1;

			for (int i = 0; i < 16; i++)
			{
				double zofs, zvel;
				if (nearFloor)        { zofs = frandom( 2,  6); zvel = frandom(  0, 10); }
				else if (nearCeiling) { zofs = frandom(-6, -2); zvel = frandom(-10,  0); }
				else                  { zofs = frandom(-3,  3); zvel = frandom( -4,  8); }

				A_SpawnItemEx("RS_ST_BlastSpark",
					frandom(-6, 6), frandom(-1, 1), zofs,
					frandom(4, 12), frandom(-3, 3), zvel,
					frandom(0, 360),
					SXF_CLIENTSIDE);
			}

			// Smoke bank.
			for (int i = 0; i < 12; i++)
			{
				A_SpawnItemEx("RS_ST_BlastSmoke",
					frandom(-6, 6), frandom(-1, 1), frandom(-4, 4),
					frandom(-3, 3), 0, frandom(-3, 3),
					frandom(0, 360),
					SXF_CLIENTSIDE);
			}
		}
		RSED GHIJ 2 Bright;
		Stop;
	}
}

// One mote of the expanding ring. Fades on a slow curve so the ring is
// still visible after it has spread -- a fast fade reads as a flash, not
// a shockwave.
class RS_ST_RingParticle : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY
		RenderStyle "Add";
		Alpha 0.125;
		Scale 0.3;
		Radius 0;
		Height 0;
	}
	States
	{
	Spawn:
		RSS4 A 1 Bright A_FadeOut(0.02);
		Loop;
	}
}

// A thrown spark: real gravity and bounce, and it lays down its own
// smoke every tic while it flies. That nested trail is what turns a
// spark shower into something with depth -- it is the piece most easily
// dropped in a port, and dropping it is why a rebuilt explosion usually
// looks flat next to the original.
class RS_ST_BlastSpark : Actor
{
	Default
	{
		+CLIENTSIDEONLY +THRUACTORS +PAINLESS +DONTSPLASH +NOTRIGGER
		+FORCEXYBILLBOARD
		Projectile;
		-NOGRAVITY
		Gravity 0.67;
		BounceType "Doom";
		BounceFactor 0.25;
		WallBounceFactor 1.0;
		Damage 0;
		Radius 3; Height 3;
		Scale 0.075;
		RenderStyle "Add";
		ReactionTime 105;
	}
	States
	{
	Spawn:
		RSS4 B 1 Bright
		{
			A_SpawnItemEx("RS_ST_EmberTrail", 0, 0, 0,
				frandom(-1, 1), 0, frandom(-1, 1),
				random(0, 360), SXF_CLIENTSIDE);
			A_Countdown();
		}
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}

// Smoke puff. Four sprite sets of differing length, picked at random, so
// a bank of them doesn't animate in lockstep.
class RS_ST_BlastSmoke : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD
		RenderStyle "Add";
		Alpha 0.5;
		Scale 0.5;
		Radius 0;
		Height 0;
	}
	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			A_SetScale(frandom(0.4, 0.6));
			return A_Jump(256, "S1", "S2", "S3", "S4");
		}
		Goto S1;
	S1:
		RSK6 ABCDEFGHIJKLMNOPQR 1 Bright;
		Stop;
	S2:
		RSK7 ABCDEFGHIJKLMNOPQR 1 Bright;
		Stop;
	S3:
		RSK8 ABCDEFGHIJKLMNOP 1 Bright;
		Stop;
	S4:
		RSK9 ABCDEFGHIJKLMNOP 1 Bright;
		Stop;
	}
}

// ---------------------------------------------------------------------
// 3D JAGGED BEAM GENERATOR
//
// Ported from the source pack's ACS beam routine. NOT ported from the
// author's helix.txt math notes -- that file describes a rotation matrix,
// and the ACS builds the same matrix inline, so the running code is what
// this follows.
//
// WHAT IT DOES: draws a lightning-style beam between two points that
// forks and jitters instead of running straight. It walks from start to
// end in random-length steps; at each step it pushes the point sideways
// off the beam axis by a random radius, at an angle that rotates as it
// goes -- so the path corkscrews around the straight line rather than
// wobbling in one plane. Then it walks the finished polyline and drops a
// particle every `density` units.
//
// WHY IT'S SHORTER THAN THE ORIGINAL: the ACS had to hand-build a 3x3
// rotation matrix to convert a local offset into world space, because it
// only had scalars. ZScript has real vectors, so the same job is a
// perpendicular basis (side/up) and two multiplies. The generated shape
// is the same; the matrix is gone because it was scaffolding, not intent.
//
// Purely cosmetic -- spawns particles, deals no damage and traces
// nothing. Whatever calls it decides the endpoints and does its own
// damage. That split is deliberate: it makes this reusable for a railgun
// beam, a chain-lightning arc between two monsters, or a tether.
// ---------------------------------------------------------------------
class RS_ST_Beam : Actor
{
	// Points are held as three parallel double arrays, not Array<Vector3>
	// -- ZScript's dynamic arrays don't take vector element types.
	//
	// There is no Cross() helper here on purpose: `cross` is a built-in
	// ZScript operator (as is `dot`), so a hand-written one is both
	// redundant and a fatal parse error on the reserved word. Cost a
	// whole-mod load failure once; don't reintroduce it.

	// segMin/segMax  -- how far apart the kinks are (map units)
	// radMin/radMax  -- how far off-axis a kink can push
	// density        -- spacing between particles along the finished path
	// A tight beam is small radius + large segment; a wild arc is the
	// reverse. The source used two presets, kept as the defaults here and
	// as DrawArc() below.
	static void Draw(Vector3 start, Vector3 end, Class<Actor> particle,
	                 double density = 6.0,
	                 double segMin = 32.0, double segMax = 128.0,
	                 double radMin = 2.0,  double radMax = 6.0)
	{
		if (!particle) return;

		Vector3 delta = end - start;
		double dist = delta.Length();
		if (dist <= 0 || density <= 0) return;

		Vector3 dir = delta / dist;

		// Perpendicular basis. The reference axis is swapped when the beam
		// is near-vertical, or the cross product collapses to zero and the
		// whole beam degenerates into a straight line.
		Vector3 refAxis = (abs(dir.z) < 0.9) ? (0.0, 0.0, 1.0) : (1.0, 0.0, 0.0);
		Vector3 side = (dir cross refAxis).Unit();
		Vector3 up   = (dir cross side).Unit();

		Array<double> px, py, pz;

		// --- build the jagged path -----------------------------------
		double travelled = 0;
		double angle = frandom(0, 360);
		Vector3 cur = start;

		// Hard cap matches the original's 256-point ceiling. Without it a
		// long beam with small segments can allocate without bound.
		int guard = 0;
		while (guard < 255)
		{
			px.Push(cur.x); py.Push(cur.y); pz.Push(cur.z);
			guard++;

			travelled += frandom(segMin, segMax);
			if (travelled >= dist) break;

			// Rotating the offset angle each step is what makes it
			// corkscrew rather than zigzag flat.
			angle = (angle + frandom(90, 270)) % 360;
			double radius = frandom(radMin, radMax);

			cur = start + dir * travelled
			            + side * (cos(angle) * radius)
			            + up   * (sin(angle) * radius);
		}

		// The path must land exactly on the target, however the walk ended.
		px.Push(end.x); py.Push(end.y); pz.Push(end.z);

		// --- walk it and place particles -----------------------------
		// carry = distance already covered toward the next particle when a
		// segment ends, so spacing stays even across kinks instead of
		// restarting at every corner.
		double carry = 0;
		for (int i = 0; i < px.Size() - 1; i++)
		{
			Vector3 a = (px[i],   py[i],   pz[i]);
			Vector3 b = (px[i+1], py[i+1], pz[i+1]);

			Vector3 seg = b - a;
			double segLen = seg.Length();
			if (segLen <= 0) continue;
			Vector3 segDir = seg / segLen;

			for (double d = carry; d < segLen; d += density)
				Actor.Spawn(particle, a + segDir * d);

			carry = (carry - segLen) % density;
			if (carry < 0) carry += density;
		}
	}

	// The source's second preset: shorter kinks, wider throw -- a loose,
	// angry arc rather than a taut beam.
	static void DrawArc(Vector3 start, Vector3 end, Class<Actor> particle,
	                    double density = 6.0)
	{
		Draw(start, end, particle, density, 16.0, 64.0, 6.0, 12.0);
	}
}

// The beam's particle. Two sprite variants picked at random so a beam
// doesn't read as one repeated dot.
class RS_ST_ArcTrail : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY +NOTIMEFREEZE
		RenderStyle "Add";
		Scale 0.3;
		Alpha 1.0;
		Radius 0;
		Height 0;
	}
	States
	{
	Spawn:
		RSPC F 0 NoDelay A_Jump(128, "Alt");
		Goto Burn;
	Alt:
		RSPC G 0;
		Goto Burn;
	Burn:
		"####" "#" 6 Bright;
		"####" "#" 1 Bright A_FadeOut(0.1);
		Wait;
	}
}

// Scrap shard -- a tumbling metal fragment. Three sprite sets imported
// (RSRA/RSRB/RSRC); RSRC had no reference anywhere in the source pack, so
// it is carried as art without a proven role rather than guessed at.
// Gravity + bounce, no damage: this is debris, not a weapon round.
class RS_ST_ScrapShard : Actor
{
	Default
	{
		+CLIENTSIDEONLY +THRUACTORS +PAINLESS +DONTSPLASH +NOTRIGGER
		+FORCEXYBILLBOARD
		Projectile;
		-NOGRAVITY
		Gravity 0.6;
		BounceType "Doom";
		BounceFactor 0.3;
		Damage 0;
		Radius 2; Height 2;
		Scale 0.4;
		RenderStyle "Add";
		ReactionTime 70;
	}
	States
	{
	Spawn:
		RSRA ABC 2 Bright A_Countdown();
		Loop;
	Death:
		TNT1 A 0;
		Stop;
	}
}

class RS_ST_ScrapShardAlt : RS_ST_ScrapShard
{
	States
	{
	Spawn:
		RSRB ABC 2 Bright A_Countdown();
		Loop;
	}
}

class RS_ST_Glow : Actor
{
	Default
	{
		+NOINTERACTION +CLIENTSIDEONLY +FORCEXYBILLBOARD +NOGRAVITY
		RenderStyle "Add";
		Scale 0.4;
		Alpha 0.8;
	}
	States
	{
	Spawn:
		RSF9 ABC 3 Bright A_FadeOut(0.15);
		Stop;
	}
}
