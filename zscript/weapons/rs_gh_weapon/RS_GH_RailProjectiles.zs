// =====================================================================
// RS_GH_ railgun bolt -- source: HF_RailBeam's coil math (itself an
// homage to the classic Q2Railgun DECORATE, Q2Stuff-L.D/weapons.q2),
// rebuilt as a REAL travelling RS_BallisticFired projectile rather than
// an instant A_RailAttack hitscan.
//
// WHY A REAL PROJECTILE, NOT HITSCAN: the source weapon (HF_HB_Railgun)
// actually fired via native A_RailAttack -- HF_RailBeam existed in the
// source file but was dead code, set as bulletOverride and never
// consulted since the weapon's Fire: state called A_RailAttack directly,
// bypassing it. Deliberately reviving the travelling-bolt design instead
// of porting the (unused) hitscan behavior: a real actor at the weapon's
// own rolled Velocity is dodgeable/reactable, which a 0-tic instant trace
// can never be -- and it plugs straight into RS_Weapon's existing
// RS_BallisticFired pipeline (SetupStats damage/velocity/crit, automatic
// ghost ripple) with zero special-case firing code needed.
//
// PRIMARY = RS_GH_RailBolt, coiled double-helix wrap (sprite RSF8).
// SECONDARY = RS_GH_RailBoltStraight, BD-faithful straight line (RSR6).
// Both referenced via RS_Catalog.PROJ_GH_RailBolt()/PROJ_GH_RailBoltStraight().
// =====================================================================

// One coil-wrap segment. Sprite RSF8 (source: LEYS, frame R -- the only
// frame the source code actually references).
class RS_GH_RailCoilSeg : Actor
{
	Default
	{
		+NOGRAVITY +NOINTERACTION +BRIGHT +FORCEXYBILLBOARD +CLIENTSIDEONLY
		RenderStyle "Add";
		Alpha 1.0;
		Scale 0.28;
	}
	States
	{
	Spawn:
		RSF8 R 1 Bright;
		RSF8 R 1 Bright;
		RSF8 R 1 Bright A_FadeOut(0.45);
		Stop;
	}
}

// Straight-mode trail segment (secondary/alt-fire only). Sprite RSR6
// (source: TRAC).
class RS_GH_RailSeg : Actor
{
	Default
	{
		+NOGRAVITY +NOINTERACTION +BRIGHT +FORCEXYBILLBOARD +CLIENTSIDEONLY
		RenderStyle "Add";
		Alpha 1.0;
		Scale 0.45;
	}
	States
	{
	Spawn:
		RSR6 A 1 Bright;
		RSR6 A 1 Bright;
		RSR6 A 1 Bright A_FadeOut(0.35);
		Stop;
	}
}

// Shared impact -- spark burst + generic hit mark, both modes.
class RS_GH_RailImpactSpark : Actor
{
	Default { +NOGRAVITY +NOINTERACTION +BRIGHT +FORCEXYBILLBOARD RenderStyle "Add"; Alpha 1.0; Scale 0.4; }
	States
	{
	Spawn:
		RSS2 A 1 Bright;
		RSS2 B 2 Bright A_FadeOut(0.4);
		Stop;
	}
}

// PRIMARY -- coiled double-helix wrap around the flight path. Real
// travelling FastProjectile (via RS_BallisticFired), so DamagePerShot/
// Velocity/CritChance are the weapon's own rolled stats, same as every
// other bullet weapon in this arsenal.
class RS_GH_RailBolt : RS_BallisticFired
{
	double coilAng;

	const COIL_RADIUS = 5.0;
	const COIL_STEP   = 40.0;

	Default
	{
		Scale 0.35;
		RenderStyle "Add";
		+BRIGHT
	}

	States
	{
	Spawn:
		RSR6 A 1 Bright
		{
			double spd = vel.Length();
			if (spd > 0.0)
			{
				vector3 vdir = vel / spd;
				vector3 ref = (abs(vdir.z) < 0.9) ? (0.0, 0.0, 1.0) : (1.0, 0.0, 0.0);

				vector3 right = (vdir cross ref);
				double rLen = right.Length();
				right = (rLen > 0.0001) ? (right / rLen) : (1.0, 0.0, 0.0);

				vector3 up2 = (right cross vdir);
				double uLen = up2.Length();
				up2 = (uLen > 0.0001) ? (up2 / uLen) : (0.0, 0.0, 1.0);

				double c1 = COIL_RADIUS * cos(coilAng);
				double s1 = COIL_RADIUS * sin(coilAng);
				vector3 offset = (c1 * right.x + s1 * up2.x, c1 * right.y + s1 * up2.y, c1 * right.z + s1 * up2.z);
				Spawn("RS_GH_RailCoilSeg", pos + offset, ALLOW_REPLACE);

				// Second segment 180 degrees offset -- double-helix look.
				double c2 = COIL_RADIUS * cos(coilAng + 180.0);
				double s2 = COIL_RADIUS * sin(coilAng + 180.0);
				vector3 offset2 = (c2 * right.x + s2 * up2.x, c2 * right.y + s2 * up2.y, c2 * right.z + s2 * up2.z);
				Spawn("RS_GH_RailCoilSeg", pos + offset2, ALLOW_REPLACE);
			}
			coilAng = (coilAng + COIL_STEP) % 360.0;
		}
		Loop;

	Death:
		TNT1 A 0
		{
			SpawnPuff("BulletPuff", pos, angle, angle + 180, 0);
			Spawn("RS_GH_RailImpactSpark", pos);
			Spawn("RS_GH_RailImpactSpark", pos);
		}
		Stop;
	}
}

// SECONDARY -- BD-faithful straight line, no helix. Same real-projectile
// treatment as the primary.
class RS_GH_RailBoltStraight : RS_BallisticFired
{
	Default
	{
		Scale 0.45;
		RenderStyle "Add";
		+BRIGHT
	}

	States
	{
	Spawn:
		RSR6 A 1 Bright
		{
			Actor s = Spawn("RS_GH_RailSeg", pos, ALLOW_REPLACE);
			if (s) s.angle = angle;
		}
		Loop;

	Death:
		TNT1 A 0
		{
			SpawnPuff("BulletPuff", pos, angle, angle + 180, 0);
			Spawn("RS_GH_RailImpactSpark", pos);
			Spawn("RS_GH_RailImpactSpark", pos);
		}
		Stop;
	}
}
