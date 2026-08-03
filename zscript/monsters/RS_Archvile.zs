// =====================================================================
// RS_Archvile -- the summoner. Replaces Archvile.
// ---------------------------------------------------------------------
// The single biggest summoner in Colourful Hell, and rebuilt here as a
// tier-gated escalation rather than a flat kit. What the survey found
// across CHP's sixteen archvile files, and what's kept:
//
//   * the resurrect trigger REPURPOSED into a summon -- the vile stops
//     reviving corpses and starts conjuring fresh monsters;
//   * a portal object that summons on its OWN schedule and gets worse
//     the longer it lives, so the player has a second thing worth
//     killing and killing it early denies the ramp;
//   * orbiting eyes as a visual tell that adds are coming;
//   * a phase-dodge on pain, which every high-tier CHP vile has.
//
// TIER GATING (the "low tiers stay Doom-honest" posture):
//   T00-T04  vanilla archvile. Fire pillar, resurrect, nothing else.
//   T05+     conjures from a flat six-class roster on its heal trigger.
//   T08+     wears orbiting eyes and can drop an escalating portal.
//   T10+     portals come out already part-charged.
//
// Everything it summons and everything it throws comes from
// RS_MonsterCatalog. No class is named inline in this file.
// =====================================================================

class RS_Archvile : RS_MonsterMaster replaces Archvile
{
	// Slot 0: the one-shot enrage gate. Slot indices are per-monster --
	// see RS_MonsterMaster.CheckThreshold.
	const RS_VILE_ENRAGE_SLOT = 0;

	// Tier gates, named rather than scattered as magic numbers so the
	// posture is editable in one place.
	const RS_VILE_TIER_CONJURE = 5;
	const RS_VILE_TIER_PORTAL  = 8;
	const RS_VILE_TIER_PRIMED  = 10;

	private bool rsEyesAttached;

	Default
	{
		Health 700;
		Radius 20;
		Height 56;
		Mass 500;
		Speed 15;
		PainChance 10;
		Monster;
		+FLOORCLIP +QUICKTORETALIATE +NOTARGET
		MaxTargetRange 896;
		SeeSound "vile/sight";   PainSound "vile/pain";
		DeathSound "vile/death"; ActiveSound "vile/active";
		Obituary "$OB_VILE";
		Tag "Arch-Vile";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "VILE VILE VILE DIAB VILE VILE DGRD VILE WICK VILE DIAB VILE LMWZ";
	}

	override string TintTable()
	{
		return "- rs_vile_t01 rs_vile_t02 rs_vile_t03 rs_vile_t04 rs_vile_t05 "
		       "rs_vile_t06 rs_vile_t07 - rs_vile_t09 - - rs_vile_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:archvile role:summoner delivery:radial element:thermal mobility:ground trait:resurrector";
	}

	// Its pack dies with it. A vile that leaves six conjured monsters
	// behind after dying isn't a summoner fight, it's a tax.
	override bool MinionsDieWithMe()
	{
		return true;
	}

	// -----------------------------------------------------------------
	// The eyes. Purely a tell -- they do no damage. They exist so the
	// player can read "this one summons" across a room, before the first
	// add ever lands.
	// -----------------------------------------------------------------
	override void OnTierApplied(int t)
	{
		bool wantEyes = (t >= RS_VILE_TIER_PORTAL);

		if (wantEyes && !rsEyesAttached)
		{
			AttachSatellite(RS_MonsterCatalog.SAT_VileEye(),   0, 38, 46);
			AttachSatellite(RS_MonsterCatalog.SAT_VileEye(), 180, 38, 46);
			rsEyesAttached = true;
		}
		// Tiering back down doesn't strip them mid-life; the satellites
		// die with us anyway. Deliberate: a monster flickering its own
		// attachments on every dial nudge looks broken.
	}

	// -----------------------------------------------------------------
	// Attack table. Low tiers get nothing here and fall through to the
	// vanilla state path; the conjure and portal profiles only exist
	// once the tier earns them.
	// -----------------------------------------------------------------
	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_VILE_TIER_CONJURE)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));

		// The conjure: one monster from the flat six-class roster,
		// picked fresh each cast. Cap keeps a long fight from becoming
		// an unkillable wall.
		slot.Append(RS_AttackProfile.MakeSummon(
			RS_MonsterCatalog.ROSTER_VileConjure(random(0, RS_MonsterCatalog.ROSTER_VileConjureCount() - 1)),
			1,                                  // one per cast
			t >= RS_VILE_TIER_PORTAL ? 5 : 3,   // live cap grows with tier
			-3,                                 // summons are weaker than us
			RS_MonsterCatalog.SND_Summon(),
			"Conjure"));

		return slot;
	}

	// A fresh roster pick each time, so the summon isn't the same
	// monster on repeat. Rebuilding the slot is cheap and it's the
	// simplest way to get variety out of a fixed table.
	void RS_Conjure()
	{
		int pick = random(0, RS_MonsterCatalog.ROSTER_VileConjureCount() - 1);
		Class<Actor> cls = RS_MonsterCatalog.ROSTER_VileConjure(pick);
		int cap = (Tier >= RS_VILE_TIER_PORTAL) ? 5 : 3;

		if (SummonPack(cls, 1, cap, -3) > 0)
		{
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
			AddCharge(1);
		}
	}

	// Drop a portal. The portal, not the vile, owns the escalation --
	// see RS_VilePortal. At high tier it arrives part-charged so the
	// ramp starts closer to the dangerous end.
	void RS_DropPortal()
	{
		if (Tier < RS_VILE_TIER_PORTAL)
			return;

		// One at a time. Two overlapping portals is not a fight, it's a
		// framerate problem.
		ThinkerIterator it = ThinkerIterator.Create("RS_VilePortal");
		RS_VilePortal existing;
		while (existing = RS_VilePortal(it.Next()))
			if (existing.master == self && existing.health > 0)
				return;

		double ang = angle + frandom(-40, 40);
		Vector3 p = (pos.xy + (cos(ang), sin(ang)) * 96.0, pos.z);

		let mo = RS_VilePortal(Spawn("RS_VilePortal", p, ALLOW_REPLACE));
		if (!mo)
			return;

		mo.master     = self;
		mo.target     = target;
		mo.PortalTier = Tier;
		mo.PortalStep = (Tier >= RS_VILE_TIER_PRIMED) ? 2 : 0;
		A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	// -----------------------------------------------------------------
	// Pain: the phase dodge. Every high-tier CHP vile has one, always
	// triggered off getting hit rather than off a timer, which is what
	// makes it feel like a reaction instead of a scripted beat.
	// -----------------------------------------------------------------
	override void OnRetier(int oldTier, int newTier) {}

	States
	{
	Spawn:
		"####" AB 10 A_Look;
		Loop;

	See:
		"####" AABBCCDDEEFF 2 A_VileChase;
		Loop;

	// The heal trigger. Vanilla jumps here when A_VileChase finds a
	// corpse. Low tiers resurrect it as normal; from T05 the vile
	// abandons the corpse and conjures something new instead -- the
	// single biggest behavioural change CHP makes to this monster.
	Heal:
		TNT1 A 0
		{
			if (Tier >= RS_VILE_TIER_CONJURE)
				return ResolveState("Conjure");
			return ResolveState(null);
		}
		"####" [\] 10 Bright;
		Goto See;

	Conjure:
		"####" [ 8 Bright A_FaceTarget;
		"####" \ 8 Bright { RS_Conjure(); }
		"####" ] 8 Bright
		{
			// Every few conjures it commits to a portal instead, so the
			// escalation arrives as an event rather than a slow drip.
			if (Tier >= RS_VILE_TIER_PORTAL && ChargeCounter >= 3)
			{
				ResetCharge();
				RS_DropPortal();
			}
		}
		Goto See;

	Missile:
		"####" G 0 Bright A_VileStart;
		"####" G 10 Bright A_FaceTarget;
		"####" H 8 Bright A_VileTarget;
		"####" IJKLMN 8 Bright A_FaceTarget;
		"####" O 8 Bright A_VileAttack;
		"####" P 20 Bright;
		Goto See;

	Pain:
		"####" Q 5;
		"####" Q 5 A_Pain;
		TNT1 A 0
		{
			// Enrage once, permanently, at half health -- then keep the
			// dodge available for the rest of the fight.
			if (CheckThreshold(RS_VILE_ENRAGE_SLOT, 0.5))
			{
				Enrage(1.3);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			}
			if (Tier >= RS_VILE_TIER_CONJURE && random(0, 255) < 96)
				PhaseDodge(45, 3.5, 0.3);
		}
		Goto See;

	Death:
		"####" Q 7;
		"####" R 7 A_Scream;
		"####" S 7 A_NoBlocking;
		"####" TUVWXY 7;
		"####" Z -1;
		Stop;
	}
}
