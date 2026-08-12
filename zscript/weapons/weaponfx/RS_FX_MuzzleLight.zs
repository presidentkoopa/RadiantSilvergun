// =====================================================================
// RS_MuzzleLight -- the BEAT muzzle light. Not a general muzzle flash.
// ---------------------------------------------------------------------
// OWNER RULING 2026-08-11: RS_Main never emits a muzzle light of its
// own. GlowInTheDark owns the muzzle flash, always, for every gun. The
// ONE exception is a PACKed attack profile that explicitly names a
// MuzzleFlash on the MUZZLE axis -- a themed beat that should read
// differently from the gun's normal report. When that happens this
// spawns, and it LAYERS with GITD's rather than replacing it.
//
// WHY LAYERING IS FREE: A_AttachLight is keyed by NAME. GITD attaches
// "gitd_muzzle"; this attaches "rs_beat_muzzle". Two differently-named
// lights on the same pawn coexist and add. Neither mod needs to know
// the other exists, and there is no load-order dependency -- which is
// exactly how sound channels layer, and exactly what was asked for.
//
// WHAT THIS FILE USED TO BE, and the bug that ended it:
//
//   class RS_MuzzleLight : PointLight   // unattenuated, radius 72-116
//   ... spawned via A_SpawnItemEx(shooter, 0,0,0)
//
// `shooter` was the PLAYER PAWN and an actor's origin is at its FEET,
// so every shot lit the floor in a ring around the player instead of
// flashing what you were shooting at. Unattenuated made it worse: a
// plain PointLight is near-full brightness across its whole radius, so
// it read as a flat wash rather than a falloff. It was on by default
// (rs_fx_hifitier 2) and fired on ~50% of shots.
//
// The shape below is deliberately copied from GITD's GITD_MuzzleLight
// so the two overlay cleanly instead of fighting:
//   - carrier actor, invisible, RIDES the host (SetOrigin every tic)
//   - height * 0.6, the same anchor GITD uses
//   - A_AttachLight flag 8 = LF_ATTENUATE, real falloff that lights
//     the surface you are aiming at
//   - short life with a smooth fade rather than a hard cut
// =====================================================================

class RS_MuzzleLight : Actor
{
	Actor  host;        // the pawn this rides
	Color  mcol;
	int    mrad;
	int    mlife;
	int    mage;

	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+DONTSPLASH
		+THRUACTORS
		+NOTELEPORT
		RenderStyle "None";
	}

	States
	{
	Spawn:
		TNT1 A 1;
		Loop;
	}

	// Arm on the shot: full brightness now, falling off over life tics.
	void Arm(Actor h, Color c, int rad, int life)
	{
		host  = h;
		mcol  = c;
		mrad  = rad;
		mlife = max(1, life);
		mage  = -1;
	}

	override void Tick()
	{
		Super.Tick();
		if (!host)
		{
			A_RemoveLight("rs_beat_muzzle");
			Destroy();
			return;
		}

		// Ride the shooter. A static light drifts off the muzzle the
		// instant the player strafes, which at these lifetimes is
		// visible as a smear.
		SetOrigin(host.pos + (0, 0, host.height * 0.6), true);

		mage++;
		if (mage > mlife)
		{
			A_RemoveLight("rs_beat_muzzle");
			Destroy();
			return;
		}

		double fade = 1.0 - double(mage) / double(mlife + 1);
		fade = clamp(fade, 0.0, 1.0);

		int finalRad = int(double(mrad) * fade);
		if (finalRad < 1) finalRad = 1;

		// flag 8 = LF_ATTENUATE. Without it the light is flat across its
		// whole radius, which is what made the old one a floor-wash.
		A_AttachLight("rs_beat_muzzle", 0, mcol, finalRad, 0, 8);
	}
}
