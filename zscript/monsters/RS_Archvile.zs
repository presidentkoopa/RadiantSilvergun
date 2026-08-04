// =====================================================================
// RS_Archvile -- per-tier state rebuild (docs/rs_09_monster_rebuild_spec.txt).
// Replaces Archvile. Template: RS_Imp.zs.
//
// THE SUMMONER, now thirteen real viles. Every color keeps the resurrect
// + fire-pillar and adds its own flavor, ported from the proven HF port
// (hf_archvile.zs) and CH decorate (Archviles.txt):
//
//   T00 VILE vanilla pillar        T01 VILE+tint poison greenening
//   T02 VILE+tint big-bolt+gash    T03 DIAB+tint ice-start volley
//   T04 VILE+tint soul-fire worry  T05 VILE+tint arc-ring pillar
//   T06 DGRD abyss ice bolts       T07 VILE+tint flame-soldier fire
//   T08 WICK ground-spike pillar   T09 VILE+tint rock-drop + spikes
//   T10 DIAB dark-fire comet+flare T11 VILE dark-flame cloud swarm
//   T12 LMWZ floating-eye boss: bolt volleys + eye turrets + quake
//
// RS mechanics preserved from the previous file, all of them:
//   * the resurrect trigger REPURPOSED into a summon at T05+ (Heal ->
//     Conjure, flat six-class roster via RS_MonsterCatalog, live cap);
//   * the escalating RS_VilePortal at T08+ (ChargeCounter pays for it),
//     arriving part-charged at T10+;
//   * orbiting eye satellites at T08+ (OnTierApplied), the "this one
//     summons" tell;
//   * one-shot Enrage at half health + PhaseDodge on pain at T05+, both
//     rolled in the Pain DISPATCHER so every tier cluster gets them;
//   * MinionsDieWithMe, keywords, tint table, BuildTierAttacks.
//
// Frame notes (verified on disk / IWAD):
//   * Heal + Conjure use bare #### with N/O/P -- those frames exist on
//     every body this family wears (VILE DIAB DGRD WICK LMWZ). The old
//     bracket-frame glow ([\]) only exists on VILE; HF avoided brackets
//     on purpose and so do we.
//   * WICK's death hands off to the WICT torso sprites, copied from CH
//     into sprites/monsters/Archvile/ alongside the body.
//   * LMWZ has A + E-P only; the white cluster never references outside
//     that set.
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

	// Audit data: which body each tier wears.
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
	// add ever lands. (Per-tier VOICES: HF kept the stock vile voice on
	// every color -- the tint and the attack carry the identity -- so
	// there is nothing to wire here.)
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
	// vanilla state path; the conjure profile only exists once the tier
	// earns it.
	// -----------------------------------------------------------------
	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_VILE_TIER_CONJURE)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));

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
	// monster on repeat.
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

	States
	{
	// ===== dispatcher overrides: family-wide mechanics roll here =====

	// The heal trigger. Vanilla A_VileChase jumps here when it finds a
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
		// Bare #### = keep the current tier's body. N/O/P exist on every
		// vile body (VILE DIAB DGRD WICK LMWZ -- verified).
		#### NOP 4 Bright;
		Goto See;

	Conjure:
		#### N 8 Bright { A_FaceTarget(); }
		#### O 8 Bright { RS_Conjure(); }
		#### P 8 Bright
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

	Pain:
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
			return TierState("Pain");
		}
		Goto See;

	// =========================================================
	// VILE GROUP -- T00/T01/T02/T04/T05/T07/T09/T11 share the
	// IWAD body: walk/pain/death stack here, bespoke casts below.
	// =========================================================
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T05:
	Spawn.T07:
	Spawn.T09:
	Spawn.T11:
		"VILE" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T05:
	See.T07:
	See.T09:
	See.T11:
		"VILE" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T05:
	Pain.T07:
	Pain.T09:
	Pain.T11:
		"VILE" Y 5 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T05:
	Death.T07:
	Death.T09:
	Death.T11:
		"VILE" Q 7;
		"VILE" R 7 { A_Scream(); }
		"VILE" S 7 { A_NoBlocking(); }
		"VILE" TUVWXY 7;
		"VILE" Z -1;
		Stop;

	// ===== T00 -- the vanilla fire pillar =====
	Missile.T00:
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" G 10 Bright { A_FaceTarget(); }
		"VILE" H 8 Bright { A_VileTarget(); }
		"VILE" IJKLMN 8 Bright { A_FaceTarget(); }
		"VILE" O 8 Bright { A_VileAttack(); }
		"VILE" P 20 Bright;
		Goto See;

	// ===== T01 GREEN -- poison pillar + greenening balls =====
	Missile.T01:
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" GH 8 Bright { A_FaceTarget(); }
		"VILE" IJKLMN 4 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_Greenening", 32, 0, random(-6, 6)); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_Greenening2", 32, 0, random(-6, 6)); }
		"VILE" O 0 Bright { A_VileTarget(); }
		"VILE" PQ 8 Bright { A_FaceTarget(); }
		"VILE" R 8 Bright { A_VileAttack(); }
		Goto See;

	// ===== T02 BLUE -- big-bolt + plasma gash pillar =====
	Missile.T02:
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" GH 8 Bright { A_FaceTarget(); }
		"VILE" IJKLMN 4 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_BigBolt2", 32, 0, 0); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_BlueGash3", 32, 0, random(-8, 8)); }
		"VILE" O 0 Bright { A_VileTarget(); }
		"VILE" PQ 8 Bright { A_FaceTarget(); }
		"VILE" R 8 Bright { A_VileAttack(); }
		Goto See;

	// =========================================================
	// T03 CYAN -- ice-start volley (DIAB body, frost tint)
	// =========================================================
	Spawn.T03:
		"DIAB" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"DIAB" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T03:
		"DIAB" G 0 Bright { A_VileStart(); }
		"DIAB" GH 8 Bright { A_FaceTarget(); }
		"DIAB" IJKLMN 4 Bright { A_FaceTarget(); }
		"DIAB" N 2 Bright { A_SpawnProjectile("RS_IceStartVile1", 32, 0, random(-6, 6)); }
		"DIAB" N 2 Bright { A_SpawnProjectile("RS_IceStartVile2", 32, 0, random(-6, 6)); }
		"DIAB" N 2 Bright { A_SpawnProjectile("RS_IceToMeetVile1", 32, 0, random(-6, 6)); }
		"DIAB" O 0 Bright { A_VileTarget(); }
		"DIAB" PQ 8 Bright { A_FaceTarget(); }
		"DIAB" R 8 Bright { A_VileAttack(); }
		Goto See;
	Pain.T03:
		"DIAB" Y 5 { A_Pain(); }
		Goto See;
	Death.T03:
	Death.T10:
		// CH RedArch3's DIAB death chain -- shared by both DIAB tiers.
		"DIAB" Q 7;
		"DIAB" R 7 { A_Scream(); }
		"DIAB" S 7 { A_NoBlocking(); }
		"DIAB" TUVW 7;
		"DIAB" XY 5;
		"DIAB" Z -1;
		Stop;

	// ===== T04 PURPLE -- soul-fire "worry" pillar =====
	Missile.T04:
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" GH 8 Bright { A_FaceTarget(); }
		"VILE" IJKLMN 4 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_PurpleWorry", 32, 0, random(-8, 8)); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_PurpleWorry2", 32, 0, random(-8, 8)); }
		"VILE" O 0 Bright { A_VileTarget(); }
		"VILE" PQ 8 Bright { A_FaceTarget(); }
		"VILE" R 8 Bright { A_VileAttack(); }
		Goto See;

	// ===== T05 YELLOW -- arc-ring pillar =====
	Missile.T05:
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" GH 8 Bright { A_FaceTarget(); }
		"VILE" IJKLMN 4 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_ArcRing2", 32, 0, random(-12, 12)); }
		"VILE" O 0 Bright { A_VileTarget(); }
		"VILE" PQ 8 Bright { A_FaceTarget(); }
		"VILE" R 8 Bright { A_VileAttack(); }
		Goto See;

	// =========================================================
	// T06 ABYSS -- fast ice-bolt pillar (DGRD body)
	// =========================================================
	Spawn.T06:
		"DGRD" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"DGRD" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T06:
		"DGRD" G 0 Bright { A_VileStart(); }
		"DGRD" GH 8 Bright { A_FaceTarget(); }
		"DGRD" IJKLMN 4 Bright { A_FaceTarget(); }
		"DGRD" N 2 Bright { A_SpawnProjectile("RS_IceABVile", 32, 0, random(-5, 5)); }
		"DGRD" N 2 Bright { A_SpawnProjectile("RS_IceABVile", 32, 0, random(-5, 5)); }
		"DGRD" N 2 Bright { A_SpawnProjectile("RS_SplashAbyss2", 32, 0, 0); }
		"DGRD" O 0 Bright { A_VileTarget(); }
		"DGRD" PQ 8 Bright { A_FaceTarget(); }
		"DGRD" R 8 Bright { A_VileAttack(); }
		Goto See;
	Pain.T06:
		"DGRD" Q 5 { A_Pain(); }
		Goto See;
	Death.T06:
		"DGRD" L 6;
		"DGRD" M 6 { A_Scream(); }
		"DGRD" N 6 { A_NoBlocking(); }
		"DGRD" OP 6;
		"DGRD" Q -1;
		Stop;

	// ===== T07 FIREBLU -- flame-soldier fire pillar =====
	Missile.T07:
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" GH 8 Bright { A_FaceTarget(); }
		"VILE" IJKLMN 4 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_FireSGguy2", 32, 0, random(-9, 9)); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_FireSGguy2", 32, 0, random(-9, 9)); }
		"VILE" O 0 Bright { A_VileTarget(); }
		"VILE" PQ 8 Bright { A_FaceTarget(); }
		"VILE" R 8 Bright { A_VileAttack(); }
		Goto See;

	// =========================================================
	// T08 BROWN -- ground-spike pillar (WICK body)
	// =========================================================
	Spawn.T08:
		"WICK" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"WICK" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T08:
		"WICK" G 0 Bright { A_VileStart(); }
		"WICK" GH 8 Bright { A_FaceTarget(); }
		"WICK" IJKLMN 4 Bright { A_FaceTarget(); }
		"WICK" N 2 Bright { A_SpawnProjectile("RS_VileGroundSpikeBrown", 32, 0, 0); }
		"WICK" N 2 Bright { A_SpawnProjectile("RS_VileGroundSpikeBrown", 32, 0, random(-12, 12)); }
		"WICK" O 0 Bright { A_VileTarget(); }
		"WICK" PQ 8 Bright { A_FaceTarget(); }
		"WICK" R 8 Bright { A_VileAttack(); }
		Goto See;
	Pain.T08:
		"WICK" Q 5 { A_Pain(); }
		Goto See;
	Death.T08:
		// CH: the Wicked's robe collapses and the torso drops out (WICT,
		// copied from CH into sprites/monsters/Archvile/).
		"WICK" N 5 { A_Scream(); }
		"WICK" O 5;
		"WICK" P 5 { A_NoBlocking(); }
		"WICT" A 5;
		"WICT" BCDEF 5;
		"WICT" G -1;
		Stop;

	// ===== T09 GRAY -- rock-drop + spike pillar =====
	Missile.T09:
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" GH 8 Bright { A_FaceTarget(); }
		"VILE" IJKLMN 4 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_CHBSTarget", 32, 0, 0); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_RockVileDrop", 32, 0, random(-8, 8)); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_VileGroundSpike", 32, 0, 0); }
		"VILE" O 0 Bright { A_VileTarget(); }
		"VILE" PQ 8 Bright { A_FaceTarget(); }
		"VILE" R 8 Bright { A_VileAttack(); }
		Goto See;

	// =========================================================
	// T10 RED -- dark-fire comet + flare pillar (DIAB body).
	// Death shared with T03 above (Death.T10 stacks there).
	// =========================================================
	Spawn.T10:
		"DIAB" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"DIAB" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T10:
		"DIAB" G 0 Bright { A_VileStart(); }
		"DIAB" GH 8 Bright { A_FaceTarget(); }
		"DIAB" IJKLMN 4 Bright { A_FaceTarget(); }
		"DIAB" N 2 Bright { A_SpawnProjectile("RS_ReAComet", 32, 0, random(-6, 6)); }
		"DIAB" N 2 Bright { A_SpawnProjectile("RS_DFlare", 32, 0, random(-8, 8)); }
		"DIAB" N 2 Bright { A_VileTarget("RS_BaronRing"); }
		"DIAB" O 0 Bright { A_VileTarget(); }
		"DIAB" PQ 8 Bright { A_FaceTarget(); }
		"DIAB" R 8 Bright { A_VileAttack(); }
		Goto See;
	Pain.T10:
		"DIAB" Y 5 { A_Pain(); }
		Goto See;

	// ===== T11 BLACK -- dark-flame cloud swarm. Apex of the
	// standard VILE body: alternates the DFire pillar with a
	// cloud barrage that keeps rolling while it has sight. =====
	Missile.T11:
		"VILE" A 0 A_Jump(96, "Missile.T11.Cloud");
		"VILE" G 0 Bright { A_VileStart(); }
		"VILE" GH 6 Bright { A_FaceTarget(); }
		"VILE" IJKLMN 3 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_DFire", 32, 0, 0); }
		"VILE" O 0 Bright { A_VileTarget(); }
		"VILE" PQ 6 Bright { A_FaceTarget(); }
		"VILE" R 8 Bright { A_VileAttack(); }
		Goto See;
	Missile.T11.Cloud:
		"VILE" GH 6 Bright { A_FaceTarget(); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_BVileCloud", 32, 0, random(-15, 15)); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_BVileCloud", 32, 0, random(-15, 15)); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_BVileCloud", 32, 0, random(-15, 15)); }
		"VILE" N 2 Bright { A_SpawnProjectile("RS_DFlare", 32, 0, random(-12, 12)); }
		"VILE" R 8 A_MonsterRefire(40, "See");
		Goto Missile.T11.Cloud;

	// =========================================================
	// T12 WHITE -- floating-eye boss (LMWZ, A + E-P frames ONLY).
	// Bolt volleys + shootable eye turrets at range; the full
	// pillar with a quake up close. THE APEX.
	// =========================================================
	Spawn.T12:
		"LMWZ" EF 10 Bright { A_Look(); }
		Loop;
	See.T12:
		"LMWZ" EEFFEEFFEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T12:
		"LMWZ" E 0 A_JumpIfCloser(1500, "Missile.T12.Close");
		"LMWZ" E 0 A_Jump(256, "Missile.T12.Bolts", "Missile.T12.Eyes");
		Goto See;
	Missile.T12.Bolts:
		"LMWZ" EF 6 Bright { A_FaceTarget(); }
		"LMWZ" G 3 Bright { A_SpawnProjectile("RS_WVileBolt1", 32, 0, random(-6, 6)); }
		"LMWZ" G 3 Bright { A_SpawnProjectile("RS_WVileBolt1", 32, 0, random(-6, 6)); }
		"LMWZ" H 3 Bright { A_SpawnProjectile("RS_WVileBolt2", 32, 0, 0); }
		"LMWZ" E 8 A_MonsterRefire(40, "See");
		Goto Missile.T12.Bolts;
	Missile.T12.Eyes:
		"LMWZ" EF 6 Bright { A_FaceTarget(); }
		"LMWZ" G 5 Bright { A_SpawnItemEx("RS_WVileEye", random(-128, 128), random(-128, 128), 64, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		"LMWZ" H 5 Bright { A_SpawnItemEx("RS_WVileEye", random(-128, 128), random(-128, 128), 64, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		"LMWZ" E 8 A_MonsterRefire(40, "See");
		Goto See;
	Missile.T12.Close:
		"LMWZ" E 0 Bright { A_VileStart(); }
		"LMWZ" EFG 8 Bright { A_FaceTarget(); }
		"LMWZ" HIJKLM 4 Bright { A_FaceTarget(); }
		"LMWZ" N 0 Bright { A_VileTarget(); }
		"LMWZ" O 0 Bright { A_QuakeEx(4, 4, 4, 40, 0, 640, ""); }
		"LMWZ" OP 8 Bright { A_FaceTarget(); }
		"LMWZ" P 8 Bright { A_VileAttack(); }
		Goto See;
	Pain.T12:
		"LMWZ" E 5 { A_Pain(); }
		Goto See;
	Death.T12:
		"LMWZ" J 6 { A_Scream(); }
		"LMWZ" K 6 { A_NoBlocking(); }
		"LMWZ" LMNO 6;
		"LMWZ" P -1;
		Stop;
	}
}
