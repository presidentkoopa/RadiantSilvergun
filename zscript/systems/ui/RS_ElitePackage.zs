// =====================================================================
// RS_ElitePackage -- the DATA drop. Not a weapon.
//
// WHY THIS EXISTS SEPARATELY FROM RS_WeaponDrop
// -----------------------------------------------------------------
// Two rewards, two jobs, and they must not look alike:
//
//   * A CLASS WEAPON drop gates progression. You start holding two of
//     six; the other four only arrive this way. It wears the weapon's
//     OWN pickup sprite under a tier translation, so you can tell a
//     shotgun from a revolver across a room and still read its rarity.
//     That is RS_WeaponDrop, and it needs no new art at all.
//
//   * A PACKAGE deepens what you already hold -- stats and modifiers at
//     a tier, applied to a class weapon. It is not a gun, so it must not
//     wear a gun's silhouette. Same sprite for two different rewards is
//     the kind of ambiguity a player never forgives.
//
// THE ART, and why it is nearly free
// -----------------------------------------------------------------
// EPKG is a clone of MBIT (the ammo bit) with every RGB channel driven
// to zero and the ALPHA CHANNEL LEFT ALONE. So the silhouette is intact
// and the object is pure black -- a hole in the world, lit only by its
// own tier aura. Ten by fourteen pixels, scaled up, which is why it can
// be a black blob and still read: at 5x the shape is all it needs.
//
// One 158-byte file for the whole feature.
//
// BLACK + ADDITIVE WOULD BE INVISIBLE. Additive blending adds the
// source colour to the scene, and black adds nothing -- an Add-styled
// black sprite is a no-op. So the body draws NORMALLY (a true dark
// silhouette) and the colour comes from two things layered around it:
// a dynamic light in the tier colour, and the same beam RS_WeaponDrop
// uses. The object stays black; the AIR around it is the rarity.
// =====================================================================

class RS_ElitePackage : Actor
{
	int           mTier;
	RS_DropBeacon mBeacon;

	Default
	{
		+NOGRAVITY
		+NOBLOCKMAP
		+NOINTERACTION
		Radius 12;
		Height 20;
		// No +BRIGHT. This one is deliberately NOT self-lit -- it is the
		// dark object in a coloured glow, and fullbright would flatten it
		// to a grey blob and kill the whole read.
	}

	States
	{
	Spawn:
		EPKG A -1;
		Stop;
	}

	// Scale lives here and not in Default because it is one number a
	// designer will want to move, and because the owner asked for 500%
	// of a 10x14 sprite -- 50x70 map units, roughly a floor pickup's
	// footprint at a readable height.
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		Scale = (5.0, 5.0);
	}

	static RS_ElitePackage Create(Vector3 where, int tier)
	{
		let p = RS_ElitePackage(Actor.Spawn("RS_ElitePackage", where));
		if (!p) return null;

		p.mTier = tier;

		// The aura IS the rarity read. Radius scales with tier so a
		// Prototype announces itself from further away than a Trash --
		// rarity as magnitude, not as a different feature.
		//
		// Detail follows the same slider the weapon drop's light does --
		// this used to pass a hardcoded 0 (plain falloff) while the
		// weapon drop passed LF_ATTENUATE, so the two payouts lit a room
		// differently for no stated reason. Same call, same dial.
		Color glow = RS_PanelController.TierGlow(tier);
		if (RS_PanelController.LightDetail() > 0 &&
		    RS_PanelController.LightRadius() > 0)
		{
			p.A_AttachLight('RSPkgGlow', DynamicLight.PointLight, glow,
				RS_PanelController.LightRadius(),
				RS_PanelController.LightRadius() / 2,
				RS_PanelController.LightFlags(), (0, 0, 10));
		}

		p.RaiseBeam();
		return p;
	}

	// THE SAME BEACON THE WEAPON DROPS USE, and now literally the same
	// code: the pillar means "an elite paid out here" and reads
	// identically whichever payout it is. What differs is the SHAPE on
	// top of it -- RSDK_Imprint gives this one a CIRCLE where a class
	// weapon gets a DIAMOND.
	//
	// This file used to carry a hand-copied second version of the beam,
	// and it had already drifted: it never picked up the "paint before
	// raising" guard the weapon drop's did until that bug was found
	// twice. One object now, so there is nothing left to drift.
	void RaiseBeam()
	{
		if (mBeacon) return;
		mBeacon = RS_DropBeacon.Create(pos, mTier, RSDK_Imprint);
	}

	override void Tick()
	{
		Super.Tick();

		// The beacon sizes itself against the viewer's distance every tic.
		// The marker is always shown here: a package has no comparison
		// card of its own to be replaced by.
		if (!mBeacon) return;

		PlayerPawn viewer = players[consoleplayer].mo;
		if (!viewer) return;

		mBeacon.Update(pos, (pos - viewer.pos).Length(), true);
	}

	override void OnDestroy()
	{
		if (mBeacon) mBeacon.Release();
		Super.OnDestroy();
	}
}
