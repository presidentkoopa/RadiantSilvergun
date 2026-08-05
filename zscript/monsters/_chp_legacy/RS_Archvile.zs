// =====================================================================
// RS_Archvile -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\14\14_<code>.txt
// One CHP file per colour; the FIRST ACTOR in each file is that tier's
// creature. Each is a genuinely different monster with its OWN sprite
// set, stats and attack. Nothing here is inferred, tinted or shared --
// every tier below was read out of its CHP file. Where CHP inherits a
// state rather than defining it, the CH parent named on the ACTOR line
// (CH\decorate\Archviles.txt) supplied it.
//
//   tier  CHP    actor / CH parent            body   HP     what it is
//   T00   14_C   CommonCommonArch:CommonArch  VILE     700  vanilla pillar
//   T01   14_G   CommonGreenArch :GreenArch   VILG     750  greenening pair
//   T02   14_B   CommonBlueArch  :BlueArch    VILB     860  gash pillar / bolt
//   T03   14_CY  CommonCyanArch  :CyanVile    VLCY    1200  dodging ice caster
//   T04   14_P   CommonPurpleArch:PurpleArch  VILP    1001  worry pillar + revs
//   T05   14_Y   CommonYellowArch:YellowArch  VILY    1333  arc rings + orbs
//   T06   14_A   CommonAbyssArch :AbyssVile   DGRD    2500  tangle / bile / ice
//   T07   14_F   CommonFirebluArch:FirebluArch2 VILF  1000  long-wind fireblu
//   T08   14_BR  CommonBrownArch :BrownVile   WICK    1400  rocks, boi, medic
//   T09   14_GY  CommonGrayArch  :GrayArch2   VGRY    1111  stone drop / spikes
//   T10   14_R   CommonRedArch3  :RedArch3    DIAB    3200  Grand Redfirevile
//   T11   14_K   CommonBlackArch2:BlackVile   VILE    7750  the Void Gazes Back
//   T12   14_W   CommonWhiteArch2:WhiteVile   LMWZ   12000  Here I Am
//   TEX   14_KX  CommonBlackArchEX2 (no parent) SILE   2700  the tornado
//                vile, "AHH HELP!!!". Not a caster at all -- it sheds a
//                damaging dust cloud on every step and its whole roster
//                is wind: a leaf storm behind a RadiusThrust shove, a
//                wall of blinding shadow waves, one seeking mind-wave,
//                four floor-hugging tornadoes, and a move where it
//                BECOMES the tornado and sucks you in. Two health gates
//                (1800, 900) that WIDEN the pool instead of swapping it.
//   T14   14_WX  CommonWhiteArchEX2 (no parent) LMWX  20800  the MASTER
//                OF TIME. T12's courage ladder taken further, plus a
//                clock it can stop: freeze rings that stack a token on
//                you, planted eyes it detonates as a set, a bouncing
//                clone seed, and -- below 12500 HP -- a 300-SECOND
//                countdown after which it goes invulnerable and simply
//                kills you. Above the EX rung, so MaxTier() is 14.
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
//
// RS mechanics preserved from the previous file, all of them:
//   * orbiting eye satellites at T08+ (OnTierApplied) -- the "this one
//     summons" tell, and CHP's own black-vile eyes by another name;
//   * the resurrect trigger repurposed into a summon (Conjure /
//     RS_Conjure, flat roster via RS_MonsterCatalog, live cap) -- CHP
//     itself turns Heal into a summon on T04/T05/T07/T09/T10/T11, so
//     those tiers call RS_Conjure() straight out of their Heal block;
//   * the escalating RS_VilePortal (ChargeCounter pays for it), arriving
//     part-charged at T10+ -- and T06's own CHP portal roll drops one
//     directly;
//   * one-shot Enrage at half health + PhaseDodge on pain at T05+, both
//     rolled in the Pain DISPATCHER so every tier cluster gets them;
//   * MinionsDieWithMe, GetBaseKeywords, TintTable, BuildTierAttacks.
//
// CHP cruft stripped per docs/rs_09_monster_rebuild_spec.txt: NewIcon*
// trackers, A_GivetoChildren, the CHWhitePlan "Tickles" gore branch,
// ACS_NamedExecuteAlways / CallACS, RandomLetterSpawner, A_SetUserVar
// (replaced by the private int fields below) and A_SpawnParticle walls.
// The bracket glow frames VILE "[\]" are replaced by VILE N/O/P -- the
// bracket tokens broke the parse here once already.
// =====================================================================

class RS_Archvile : RS_MonsterLadder replaces Archvile
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

	// CHP user vars, rebuilt as real fields.
	private int rsSummonCount;   // 14_P  User_Summon
	private int rsOrbCount;      // 14_Y  User_Summon2
	private int rsRage;          // 14_R  User_Rage
	private int rsVoidLimit;     // 14_K  user_limit
	private int rsExTornado;     // 14_KX TornadoToken -- vortex beat count
	private int rsCourageMOT;    // 14_WX user_courage
	private int rsHohoMOT;       // 14_WX user_hoho -- eyes planted, not yet fired
	private int rsEndOfTimeMOT;  // 14_WX user_endoftime -- the countdown started
	// 14_WX's TIMESUPMOT latch. CHP sets it from ACS ("WVileEXTimer2_C",
	// Delay(10500) = exactly 300 seconds) -- the ACS is a stripped
	// announcer, so the deadline lives here as a level.time stamp.
	private int rsTimesUpTic;
	private int rsCourage;       // 14_W  User_courage
	private int rsHoho;          // 14_W  user_hoho

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

	// CHP's real per-colour numbers, read from 14_*.txt. Health is
	// absolute in CHP -- these are hand-tuned creatures -- so it is
	// expressed here as a multiplier off the Default (700 HP, speed 15)
	// to keep the base class's recompute-from-defaults contract.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 10; r.dmgMul = 1.0;
		int hp = 700; int spd = 15;
		switch (t)
		{
			case 0:  hp = 700;   spd = 15; r.painChance = 10; r.dmgMul = 1.0; break;
			case 1:  hp = 750;   spd = 16; r.painChance = 8;  r.dmgMul = 1.1; break;
			case 2:  hp = 860;   spd = 17; r.painChance = 6;  r.dmgMul = 1.2; break;
			case 3:  hp = 1200;  spd = 21; r.painChance = 10; r.dmgMul = 1.3; break;
			case 4:  hp = 1001;  spd = 18; r.painChance = 4;  r.dmgMul = 1.4; break;
			case 5:  hp = 1333;  spd = 18; r.painChance = 4;  r.dmgMul = 1.5; break;
			case 6:  hp = 2500;  spd = 25; r.painChance = 32; r.dmgMul = 1.7; break;
			case 7:  hp = 1000;  spd = 19; r.painChance = 4;  r.dmgMul = 1.5; break;
			case 8:  hp = 1400;  spd = 21; r.painChance = 12; r.dmgMul = 1.6; break;
			case 9:  hp = 1111;  spd = 19; r.painChance = 16; r.dmgMul = 1.6; break;
			case 10: hp = 3200;  spd = 15; r.painChance = 3;  r.dmgMul = 2.0; break;
			case 11: hp = 7750;  spd = 17; r.painChance = 8;  r.dmgMul = 2.5; break;
			case 12: hp = 12000; spd = 40; r.painChance = 64; r.dmgMul = 3.0; break;
			// TEX -- 14_KX CommonBlackArchEX2, CHP's own numbers. Low HP
			// for an EX on purpose: the fight is the storm, not the pool.
			case 13: hp = 2700;  spd = 20; r.painChance = 8;  r.dmgMul = 3.5; break;
			// T14 -- 14_WX CommonWhiteArchEX2, the Master of Time. Stated
			// ABSOLUTELY (r.hp / r.speed) rather than as a multiplier off
			// the T00 default: a tier this far out is a hand-authored
			// creature, not a point on the family's curve.
			case 14:
				r.hp = 20800; r.speed = 60; r.painChance = 10; r.dmgMul = 4.0;
				return true;
			default: return false;
		}
		r.hpMul  = double(hp) / 700.0;
		r.spdMul = double(spd) / 15.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/Archvile/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX  T14
		return "VILE VILG VILB VLCY VILP VILY DGRD VILF WICK VGRY DIAB VILE LMWZ SILE LMWX";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - - - -";
	}

	// This family authors one tier ABOVE the EX rung: 14_WX's Master of
	// Time. Without this the dial clamps at TEX and T14 is unreachable.
	override int MaxTier()
	{
		return 14;
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
	// add ever lands. CHP's own black vile (14_K) bolts two BVileEye
	// actors on at spawn for exactly the same reason; this is that,
	// generalised to every tier that has earned it.
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
	// state path; the conjure profile only exists once the tier earns it.
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
	// monster on repeat. This is what CHP's per-colour "spawn a
	// CommonFirebluSG / CommonGrayCaco / MrBones" lines become.
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
	// ramp starts closer to the dangerous end. `force` exists for T06,
	// whose CHP block rolls its own portal well below the normal gate.
	void RS_DropPortal(bool force = false)
	{
		if (!force && Tier < RS_VILE_TIER_PORTAL)
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

	// The heal trigger. A_VileChase jumps here when it finds a corpse.
	// Each tier owns its own Heal choreography -- CHP defines one per
	// colour, and from T04 up most of them are summons rather than
	// resurrections -- so this only routes.
	Heal:
		TNT1 A 0 { return TierState("Heal"); }
		Goto See;

	// The RS summon beat, referenced by BuildTierAttacks.
	Conjure:
		"VILE" N 8 Bright { A_FaceTarget(); }
		"VILE" O 8 Bright { RS_Conjure(); }
		"VILE" P 8 Bright
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

	// =================================================================
	// T00 COMMON (14_C -- CommonCommonArch : CommonArch). VILE.
	// The stock creature: fire pillar, nothing else.
	// =================================================================
	Spawn.T00:
		"VILE" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"VILE" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T00:
		"VILE" G 0 { A_StartSound("vile/start", CHAN_VOICE); }
		"VILE" G 10 Bright { A_FaceTarget(); }
		"VILE" H 8 Bright { A_VileTarget("RS_ArchvileFire"); }
		"VILE" IJKLMN 8 Bright { A_FaceTarget(); }
		"VILE" O 8 Bright { A_VileAttack("vile/stop", 20, 70, 70, 1, "Fire", 0); }
		"VILE" P 20 Bright;
		Goto See;
	Heal.T00:
		"VILE" NOP 10 Bright;
		Goto See;
	Pain.T00:
		"VILE" Q 5;
		"VILE" Q 5 { A_Pain(); }
		Goto See;
	Death.T00:
		"VILE" Q 7;
		"VILE" R 7 { A_Scream(); }
		"VILE" S 7 { A_NoBlocking(); }
		"VILE" TUVWXY 7;
		"VILE" Z -1;
		Stop;

	// =================================================================
	// T01 GREEN (14_G -- CommonGreenArch : GreenArch). VILG.
	// Two greenening balls thrown as airstrikes, then a plasma blast.
	// =================================================================
	Spawn.T01:
		"VILG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"VILG" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T01:
		"VILG" G 0 { A_StartSound("vile/start", CHAN_VOICE); }
		"VILG" G 16 Bright { A_FaceTarget(); }
		"VILG" H 5 Bright { A_VileTarget("RS_Greenening"); }
		"VILG" IJKL 5 Bright { A_FaceTarget(); }
		"VILG" M 0 A_CheckSight("See");
		"VILG" M 9 Bright { A_VileTarget("RS_Greenening2"); }
		"VILG" N 3 Bright;
		"VILG" O 7 Bright { A_VileAttack("vile/stop", random(30, 46), random(30, 46), 64, 2, "Plasma"); }
		"VILG" P 16 Bright;
		Goto See;
	Heal.T01:
		"VLG2" ABC 10 Bright;
		Goto See;
	Pain.T01:
		"VILG" Q 5;
		"VILG" Q 5 { A_Pain(); }
		Goto See;
	Death.T01:
		"VILG" Q 7;
		"VILG" R 7 { A_Scream(); }
		"VILG" S 7 { A_NoBlocking(); }
		"VILG" TUVWXY 7;
		"VILG" Z -1;
		Stop;

	// =================================================================
	// T02 BLUE (14_B -- CommonBlueArch : BlueArch). VILB.
	// Sheds a plasma gash constantly; picks between a double-gash
	// pillar and a single heavy bolt.
	// =================================================================
	Spawn.T02:
		"VILB" AB 10 { A_Look(); }
		"VILB" A 0 { A_SpawnItemEx("RS_BlueGash", 0, 0, 32); }
		Loop;
	See.T02:
		"VILB" AABBCCDDEEFF 2 { A_VileChase(); }
		"VILB" A 0 { A_SpawnItemEx("RS_BlueGash", 0, 0, 32); }
		Loop;
	Missile.T02:
		"VILB" G 0 A_Jump(256, "Missile.T02.Classic1", "Missile.T02.Boltings2");
		Goto See;
	Missile.T02.Classic1:
		"VILB" G 0 { A_StartSound("vile/start", CHAN_VOICE); }
		"VILB" G 16 Bright { A_FaceTarget(); }
		"VILB" H 7 Bright { A_VileTarget("RS_BlueGash3"); }
		"VILB" IJKL 7 Bright { A_FaceTarget(); }
		"VILB" MN 4 Bright { A_VileTarget("RS_BlueGash3"); }
		"VILB" O 6 Bright { A_VileAttack("vile/stop", random(32, 62), random(32, 62), 64, 10, "Plasma"); }
		"VILB" P 16 Bright;
		Goto See;
	Missile.T02.Boltings2:
		"VILB" G 5 { A_FaceTarget(); }
		"VILB" G 5 { A_StartSound("vile/sight", CHAN_VOICE); }
		"VILB" H 4 { A_SpawnItemEx("RS_BlueGash", 0, 0, 32); }
		"VILB" IJKLM 8 Bright { A_FaceTarget(); }
		"VILB" N 1 Bright { A_SpawnProjectile("RS_BigBolt2", 32, 0); }
		"VILB" O 7 Bright;
		"VILB" P 8 Bright;
		Goto See;
	Heal.T02:
		TNT1 A 0 { A_SpawnItemEx("RS_ArchRingHelp", 32, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"VLB2" ABC 10 Bright;
		Goto See;
	Pain.T02:
		"VILB" Q 5;
		"VILB" Q 0 { A_SpawnItemEx("RS_BlueGash", 0, 0, 32); }
		"VILB" Q 5 { A_Pain(); }
		Goto See;
	Death.T02:
		"VILB" Q 7;
		"VILB" R 7 { A_Scream(); }
		"VILB" S 7 { A_NoBlocking(); }
		"VILB" TUVWXY 7;
		"VILB" Z -1;
		Stop;

	// =================================================================
	// T03 CYAN (14_CY -- CommonCyanArch : CyanVile). VLCY.
	// The Cold Vile: it dodges, back-dashes, and casts a long ice
	// ritual or lays a five-lance floor spread. Shatters when it dies.
	// CHP gated the back-dash on an ACS call (CH_CyanBounce); the ACS
	// is stripped, the dash stays.
	// =================================================================
	Spawn.T03:
		"VLCY" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"VLCY" AABBCCDDEEFF 2 { A_VileChase(); }
		"VLCY" A 0 A_Jump(128, "See.T03.Dodger");
		"VLCY" A 0 A_Jump(32, "See.T03.DashBack");
		Loop;
	See.T03.DashBack:
		"VLCY" G 3 { A_ChangeVelocity(0, 0, 9, CVF_REPLACE); }
		"VLCY" G 3 { A_ChangeVelocity(-18, 0, 0, CVF_RELATIVE); }
		Goto See;
	See.T03.Dodger:
		"VLCY" AABB 2 { A_FastChase(); }
		"VLCY" A 0 A_Jump(64, "See");
		"VLCY" CCDD 2 { A_FastChase(); }
		"VLCY" A 0 A_Jump(64, "See.T03.DashBack");
		Goto See;
	Missile.T03:
		"VLCY" A 0 A_JumpIfCloser(900, "Missile.T03.Choice");
		Goto Missile.T03.Classical;
	Missile.T03.Choice:
		"VLCY" A 0 A_Jump(256, "Missile.T03.Classical", "Missile.T03.Floor");
		Goto See;
	Missile.T03.Floor:
		"VLCY" HH 3 Bright { A_FaceTarget(); }
		"VLCY" I 6 Bright { A_SpawnProjectile("RS_IceStartVile4", 64, 0); }
		"VLCY" PON 7 Bright { A_FaceTarget(); }
		"VLCY" N 0 { A_SpawnProjectile("RS_IceToMeetVile1", 32, 0, 0); }
		"VLCY" N 0 { A_SpawnProjectile("RS_IceToMeetVile1", 32, 0, 33); }
		"VLCY" N 0 { A_SpawnProjectile("RS_IceToMeetVile1", 32, 0, -33); }
		"VLCY" N 0 { A_SpawnProjectile("RS_IceToMeetVile1", 32, 0, 66); }
		"VLCY" N 0 { A_SpawnProjectile("RS_IceToMeetVile1", 32, 0, -66); }
		Goto See;
	Missile.T03.Classical:
		"VLCY" GH 3 Bright { A_FaceTarget(); }
		"VLCY" I 3 Bright { A_VileTarget("RS_IceStartVile1"); }
		"VLCY" HG 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See");
		"VLCY" HIH 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See.T03.Dodger");
		"VLCY" G 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See");
		"VLCY" HIH 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See.T03.Dodger");
		"VLCY" G 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See");
		"VLCY" HIH 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See.T03.Dodger");
		"VLCY" G 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See");
		"VLCY" HI 3 Bright { A_FaceTarget(); }
		"VLCY" A 0 A_CheckSight("See.T03.Dodger");
		"VLCY" G 3 Bright { A_FaceTarget(); }
		"VLCY" H 3 Bright { A_VileAttack("ice/hit", random(10, 60), random(10, 60), 64, -5, "Ice"); }
		"VLCY" H 0 { A_VileTarget("RS_IceStartVile3"); }
		"VLCY" I 3 Bright { A_FaceTarget(); }
		Goto See;
	Heal.T03:
		"VLC2" A 10 Bright;
		"VLCY" B 2 Bright;
		"VLC2" BB 5 Bright { SummonMinion("RS_LostSoul", -1, 96.0); }
		"VLC2" C 4 Bright;
		"VLC2" C 4;
		Goto See;
	Pain.T03:
		"VLCY" Q 5;
		"VLCY" Q 5 { A_Pain(); }
		"VLCY" Q 0 A_Jump(128, "See.T03.DashBack");
		Goto See;
	Death.T03:
		"VLCY" Q 7;
		"VLCY" R 7 { A_Scream(); }
		"VLCY" S 7 { A_NoBlocking(); }
		"VLCY" TUVW 7;
		"VLCY" XY 5;
		"VLCY" Z 10;
		// CHP burst it into IceChunk_C and dropped a joke pickup; the
		// engine's own shatter is the same read without either.
		"VLCY" Z 1 { A_StartSound("misc/icebreak", CHAN_BODY); A_IceGuyDie(); }
		Stop;

	// =================================================================
	// T04 PURPLE (14_P -- CommonPurpleArch : PurpleArch). VILP.
	// Monarchy: soul-fire "worry" pillar, or it calls a revenant.
	// Eight summons is the cap; pain resets the count.
	// =================================================================
	Spawn.T04:
		"VILP" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"VILP" AABBCCDDEEFF 2 { A_VileChase(); }
		"VILP" A 0 A_Jump(12, "Missile.T04.Summon");
		Loop;
	Missile.T04:
		"VILP" G 0 A_Jump(64, "Missile.T04.Classic2");
		"VILP" G 0 A_Jump(256, "Missile.T04.Classic2", "Missile.T04.Summon");
		Goto See;
	Missile.T04.Classic2:
		"VILP" G 0 { A_StartSound("vile/start", CHAN_VOICE); }
		"VILP" G 13 Bright { A_FaceTarget(); }
		"VILP" H 8 Bright { A_VileTarget("RS_PurpleWorry"); }
		"VILP" IJKLM 11 Bright { A_FaceTarget(); }
		"VILP" N 0 A_CheckSight("See");
		"VILP" N 9 Bright { A_VileTarget("RS_PurpleWorry2"); }
		"VILP" O 7 Bright;
		"VILP" P 16 Bright;
		Goto See;
	Missile.T04.Summon:
		"VILP" G 1 { if (rsSummonCount >= 8) return ResolveState("See"); return ResolveState(null); }
		"VILP" G 8 { A_FaceTarget(); }
		"VILP" G 8 { A_StartSound("vile/sight", CHAN_VOICE); }
		"VILP" H 7;
		"VILP" IJKH 11 Bright { A_FaceTarget(); }
		"VILP" G 3 Bright { SummonMinion("RS_Revenant", -2, 72.0); }
		"VILP" P 9 Bright { rsSummonCount++; }
		"VILP" P 2;
		Goto See;
	Heal.T04:
		"VILP" A 1 { A_SpawnItemEx("RS_PurpleWorry", 0, 0, 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"VILP" A 1;
		"VLP2" ABC 10 Bright;
		Goto See;
	Pain.T04:
		"VILP" Q 5 { rsSummonCount = 0; }
		"VILP" Q 5 { A_Pain(); }
		Goto See;
	Death.T04:
		"VILP" Q 7;
		"VILP" R 7 { A_Scream(); }
		"VILP" S 7 { A_NoBlocking(); }
		"VILP" TUVWXY 7;
		"VILP" Z -1;
		Stop;

	// =================================================================
	// T05 YELLOW (14_Y -- CommonYellowArch : YellowArch). VILY.
	// The Golden Archvile: arc-ring airstrikes, or it seeds hunting
	// orbs. CHP's ArchSpawnerOrb rolled its own monster; here the orb
	// still flies and drops the fire, and the actual add goes through
	// RS_Conjure's live cap.
	// =================================================================
	Spawn.T05:
		"VILY" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"VILY" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T05:
		"VILY" G 0 A_Jump(64, "Missile.T05.Fires");
		"VILY" G 0 A_Jump(256, "Missile.T05.Fires", "Missile.T05.Summon");
		Goto See;
	Missile.T05.Fires:
		"VILY" G 0 { A_StartSound("vile/start", CHAN_VOICE); }
		"VILY" G 13 Bright { A_FaceTarget(); }
		"VILY" H 6 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILY" IJKLM 7 Bright { A_FaceTarget(); }
		"VILY" N 7 Bright { A_VileTarget("RS_ArcRing1"); }
		"VILY" O 0 A_CheckSight("See");
		"VILY" O 7 Bright { A_VileTarget("RS_ArcRing2"); }
		"VILY" O 4 Bright { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(-3, 3)); }
		"VILY" O 2 Bright { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(-3, 3)); }
		"VILY" P 12 Bright;
		Goto See;
	Missile.T05.Summon:
		"VILY" G 1 { if (rsOrbCount >= 8) return ResolveState("See"); return ResolveState(null); }
		"VILY" G 8 { A_FaceTarget(); }
		"VILY" G 8 { A_StartSound("vile/sight", CHAN_VOICE); }
		"VILY" H 7 { rsOrbCount++; }
		"VILY" IJKH 11 Bright { A_FaceTarget(); }
		"VILY" G 3 Bright { A_SpawnItemEx("RS_ArchSpawnerOrb", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"VILY" G 2 Bright { A_SpawnItemEx("RS_ArchSpawnerOrb", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"VILY" G 1 Bright { A_SpawnItemEx("RS_ArchSpawnerOrb", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"VILY" P 2 { RS_Conjure(); }
		Goto See;
	Heal.T05:
		"VILY" A 1 { A_SpawnItemEx("RS_ArcRing1", 0, 0, 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"VLY2" ABC 10 Bright;
		"VILY" A 1 Bright { RS_Conjure(); }
		Goto See;
	Pain.T05:
		// CHP kept a separate Pain.fire that rolled straight into the
		// summon; the roll is folded in here so the tier dispatcher
		// still owns a single Pain entry.
		"VILY" Q 5 { rsOrbCount = max(0, rsOrbCount - 4); }
		"VILY" Q 5 { A_Pain(); }
		"VILY" Q 0 A_Jump(24, "Missile.T05.Summon");
		Goto See;
	Death.T05:
		"VILY" Q 7 { A_KillChildren(); }
		"VILY" R 7 { A_Scream(); }
		"VILY" S 7 { A_NoBlocking(); }
		"VILY" TUVWXY 7;
		"VILY" Z -1;
		Stop;

	// =================================================================
	// T06 ABYSS (14_A -- CommonAbyssArch : AbyssVile). DGRD.
	// Not an archvile at all: an alien thing that wades in bile,
	// tangles your head, seeds tentacles, throws icicles, and MELEES.
	// The only tier in the family with a melee. Its heal opens a
	// portal.
	// =================================================================
	Spawn.T06:
		"DGRD" A 10 { A_Look(); }
		Loop;
	See.T06:
		"DGRD" BBCC 3 { A_VileChase(); }
		"DGRD" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 62)); }
		"DGRD" DDEE 3 { A_VileChase(); }
		"DGRD" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 62), 1, 0, 2, random(0, 359)); }
		Loop;
	See.T06.Alt:
		"DGRD" BB 2 { A_VileChase(); }
		"DGRD" A 0 { A_SpawnItemEx("RS_SplashAbyssVile", -2, 0, random(5, 24), 0, 0, 0, 0, 0, 128); }
		"DGRD" CC 2 { A_VileChase(); }
		"DGRD" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 62), 1, 0, 2, random(0, 359)); }
		"DGRD" A 0 { A_SpawnItemEx("RS_SplashAbyssVile", -2, 0, random(5, 24), 0, 0, 0, 0, 0, 128); }
		"DGRD" DD 2 { A_VileChase(); }
		"DGRD" A 0 { A_SpawnItemEx("RS_SplashAbyssVile", -2, 0, random(5, 24)); }
		"DGRD" EE 2 { A_VileChase(); }
		"DGRD" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 62), 1, 0, 2, random(0, 359)); }
		"DGRD" A 0 { A_SpawnItemEx("RS_SplashAbyssVile", -2, 0, random(5, 24), 0, 0, 0, 0, 0, 128); }
		"DGRD" A 0 A_CheckSight("See");
		Loop;
	Missile.T06:
		"DGRD" A 1 { A_FaceTarget(); }
		"DGRD" A 0 A_JumpIfCloser(1500, "Missile.T06.Choice");
		Goto Missile.T06.DarkTangle;
	Missile.T06.Choice:
		"DGRD" A 0 A_Jump(256, "Missile.T06.Bleck", "Missile.T06.DarkTangle", "Missile.T06.Icicles");
		Goto See.T06.Alt;
	Missile.T06.DarkTangle:
		"DGRD" A 5 Bright { A_FaceTarget(); }
		"DGRD" A 4 Bright { A_StartSound("vile/sight", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
	Missile.T06.Tangle:
		"DGRD" K 6 Bright { A_FaceTarget(); }
		"DGRD" K 1 Bright A_CheckSight("See.T06.Alt");
		"DGRD" K 5 Bright { A_VileTarget("RS_PsychicTangleAbyVile"); }
		"DGRD" K 2 A_MonsterRefire(128, "See.T06.Alt");
		Goto Missile.T06.Tangle;
	Missile.T06.Bleck:
		"DGRD" AAA 5 Bright { A_FaceTarget(); }
		"DGRD" J 5 Bright { A_VileTarget("RS_ABVileTend"); }
		"DGRD" I 5;
		"DGRD" AAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyssVile2", random(32, 728), random(-78, 78), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto See.T06.Alt;
	Missile.T06.Icicles:
		"DGRD" I 15 Bright { A_FaceTarget(); }
	Missile.T06.IceIt:
		"DGRD" J 2 Bright { A_FaceTarget(); }
		"DGRD" JJJ 2 Bright { A_SpawnProjectile("RS_IceABVile", random(24, 42), 0, random(-9, 9)); }
		"DGRD" J 1 A_CheckSight("See");
		"DGRD" J 1 A_MonsterRefire(128, "See");
		Goto Missile.T06.IceIt;
	Missile.T06.Jumpy:
		"DGRD" R 6 { A_FaceTarget(); }
		"DGRD" S 1 { A_ChangeVelocity(0, 0, 8, CVF_REPLACE); }
		"DGRD" S 1 { A_ChangeVelocity(-12, 0, 0, CVF_RELATIVE); }
		"DGRD" S 5;
		"DGRD" T 12;
		Goto See;
	Missile.T06.Warp:
		"DGRD" A 1;
		"DGRD" A 1 { bNOPAIN = true; }
		"DGRD" A 1 { bNOGRAVITY = true; }
		"DGRD" A 1 { bFLOAT = true; }
		"DGRD" A 1 { A_SetSpeed(99); }
		"DGRD" A 0 { A_SetTranslucent(0.45); }
		"DGRD" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 128), random(-128, 128), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"DGRD" BCDEFBCDEFBCDEFBCDEF 1 { A_Wander(); }
		"DGRD" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 128), random(-128, 128), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"DGRD" A 1 { A_SetSpeed(25); }
		"DGRD" A 0 { A_SetTranslucent(1.0); }
		"DGRD" A 1 { bNOGRAVITY = false; }
		"DGRD" A 1 { bFLOAT = false; }
		"DGRD" A 1 { bNOPAIN = false; }
		Goto See;
	Melee.T06:
		"DGRD" F 6 { A_FaceTarget(); }
		"DGRD" G 6 { A_CustomMeleeAttack(random(16, 62), "imp/melee"); }
		"DGRD" AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 0, random(-25, 25), CMF_OFFSETPITCH, random(-25, -5)); }
		"DGRD" H 6 { A_CustomMeleeAttack(random(16, 62), "imp/melee"); }
		"DGRD" AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 0, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		"DGRD" A 0 A_Jump(32, "Missile.T06.Jumpy");
		Goto See;
	Heal.T06:
		"DGRD" A 4 Bright { A_SpawnItemEx("RS_AbyssBaronRing", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"DGRD" A 10 Bright;
		"DGRD" AAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyssVile", random(-258, 258), random(-258, 258), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"DGRD" A 0 A_Jump(76, "Heal.T06.Portal");
		"DGRD" A 0 A_Jump(32, "Missile.T06.Jumpy");
		Goto See.T06.Alt;
	Heal.T06.Portal:
		"DGRD" A 4 Bright;
		// CHP spawned its own AbyssPortalVile here. RS already owns that
		// escalation -- RS_VilePortal -- so this drops one of ours,
		// forced past the normal T08 gate because CHP put it on T06.
		"DGRD" A 6 Bright { RS_DropPortal(true); }
		Goto Missile.T06.Jumpy;
	Pain.T06:
		"DGRD" L 3;
		"DGRD" L 3 { A_Pain(); }
		"DGRD" L 1 A_Jump(64, "Missile.T06.Warp");
		"DGRD" L 0 A_Jump(32, "Missile.T06.Jumpy");
		Goto See;
	Death.T06:
		"DGRD" L 6;
		"DGRD" M 6 { A_Scream(); }
		"DGRD" N 6 { A_NoBlocking(); }
		"DGRD" OP 6;
		"DGRD" Q -1;
		Stop;

	// =================================================================
	// T07 FIREBLU (14_F -- CommonFirebluArch : FirebluArch2). VILF.
	// A very long, very visible wind-up -- it flickers in and out for
	// nearly three seconds before the fireblu pillar lands. Its heal
	// spawns a friend instead of raising one.
	// =================================================================
	Spawn.T07:
		"VILF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"VILF" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T07:
		"VILF" G 0 { A_VileStart(); }
		"VILF" G 16 Bright { A_FaceTarget(); }
		TNT1 A 3;
		"VILF" G 3 Bright { A_FaceTarget(); }
		TNT1 A 3 A_CheckSight("See");
		"VILF" G 2 Bright { A_FaceTarget(); }
		TNT1 A 2 A_CheckSight("See");
		"VILF" G 2 Bright { A_FaceTarget(); }
		TNT1 A 2 A_CheckSight("See");
		"VILF" G 2 Bright { A_FaceTarget(); }
		TNT1 A 1 A_CheckSight("See");
		"VILF" G 1 Bright { A_FaceTarget(); }
		TNT1 A 1 A_CheckSight("See");
		"VILF" G 1 Bright { A_FaceTarget(); }
		TNT1 A 1 A_CheckSight("See");
		"VILF" G 1 Bright { A_StartSound("vile/sight", CHAN_VOICE); }
		"VILF" G 6 Bright { A_FaceTarget(); }
		"VILF" H 5 Bright { A_VileTarget("RS_FirebluVileFX"); }
		"VILF" IJKL 5 Bright { A_FaceTarget(); }
		"VILF" M 0 A_CheckSight("See");
		"VILF" M 9 Bright { A_VileTarget("RS_FirebluVileFX"); }
		"VILF" N 3 Bright;
		"VILF" O 7 Bright { A_VileAttack("vile/stop", random(6, 64), random(6, 64), 128, 2, "Fire"); }
		"VILF" P 16 Bright;
		Goto See;
	Heal.T07:
		"VLF2" ABC 10 Bright;
		"VILF" G 0 { RS_Conjure(); }
		Goto See;
	Pain.T07:
		"VILF" Q 5;
		"VILF" Q 5 { A_Pain(); }
		"VILF" Q 0 { if (random(0, 255) < 128) RS_Conjure(); }
		Goto See;
	Death.T07:
		"VILF" Q 7;
		"VILF" R 7 { A_Scream(); }
		"VILF" S 7 { A_NoBlocking(); }
		"VILF" TUVWXY 7;
		"VILF" Z -1;
		Stop;

	// =================================================================
	// T08 BROWN (14_BR -- CommonBrownArch : BrownVile). WICK.
	// The Wicked: wears a shell of orbiting rocks, alternates two walk
	// gaits, and picks between a ground spike, a five-boulder barrage,
	// and a support cast that heals and shields everything around it.
	// Its robe collapses into a torso when it dies.
	// =================================================================
	Spawn.T08:
		"WICK" AAAAAAAA 9 { A_SpawnItemEx("RS_BrownVileRock", 0, 0, 0, 0, 0, 0, 0, SXF_SETMASTER); }
		"WICK" A 0 { bNOPAIN = false; }
		Goto Spawn.T08.Idle;
	Spawn.T08.Idle:
		"WICK" A 0 { A_SetSize(24, 72); }
		"WICK" ABCD 8 { A_Look(); }
		"WICK" AA 0 { A_SpawnItemEx("RS_BrownVileRock", 0, 0, 0, 0, 0, 0, 0, SXF_SETMASTER, 128); }
		Loop;
	See.T08:
		"WICK" A 0 { A_SetSpeed(19); }
		"WICK" AABBCCDD 3 { A_Chase(); }
		"WICK" AA 0 { A_SpawnItemEx("RS_BrownVileRock", 0, 0, 0, 0, 0, 0, 0, SXF_SETMASTER, 128); }
		"WICK" A 0 A_Jump(32, "See.T08.Alt");
		Goto See.T08;
	See.T08.Alt:
		"WICK" A 0 { A_SetSpeed(25); }
		"WICK" EEFFGGHH 2 { A_Chase(); }
		"WICK" AA 0 { A_SpawnItemEx("RS_BrownVileRock", 0, 0, 0, 0, 0, 0, 0, SXF_SETMASTER, 128); }
		"WICK" E 0 A_Jump(32, "See.T08");
		Goto See.T08.Alt;
	Missile.T08:
		"WICK" I 1;
		"WICK" I 1 A_Jump(64, "Missile.T08.CheckThem");
		"WICK" I 1 A_Jump(128, "Missile.T08.Boi");
	Missile.T08.Spike:
		"WICK" I 1 { A_StartSound("vile/start", CHAN_VOICE); }
		"WICK" I 4 { A_FaceTarget(); }
		"WICK" J 5 Bright { A_FaceTarget(); }
		"WICK" K 6 Bright { A_VileTarget("RS_VileGroundSpikeBrown"); }
		"WICK" L 4;
		Goto See;
	Missile.T08.Boi:
		"WICK" I 1 { A_StartSound("vile/start", CHAN_WEAPON); }
		"WICK" I 3 { A_FaceTarget(); }
		"WICK" J 4 Bright { A_FaceTarget(); }
		"WICK" K 9 Bright { A_SpawnItemEx("RS_BrownBoiVile", 32,  76, 32, 0, 0, 0, 0, SXF_SETTRACER | SXF_NOCHECKPOSITION); }
		"WICK" K 9 Bright { A_SpawnItemEx("RS_BrownBoiVile", 32,  32, 46, 0, 0, 0, 0, SXF_SETTRACER | SXF_NOCHECKPOSITION); }
		"WICK" K 9 Bright { A_SpawnItemEx("RS_BrownBoiVile", 32,   0, 64, 0, 0, 0, 0, SXF_SETTRACER | SXF_NOCHECKPOSITION); }
		"WICK" K 9 Bright { A_SpawnItemEx("RS_BrownBoiVile", 32, -32, 46, 0, 0, 0, 0, SXF_SETTRACER | SXF_NOCHECKPOSITION); }
		"WICK" K 9 Bright { A_SpawnItemEx("RS_BrownBoiVile", 32, -76, 32, 0, 0, 0, 0, SXF_SETTRACER | SXF_NOCHECKPOSITION); }
		"WICK" L 4;
		Goto See;
	// CHP's corpse/ally sweep, kept whole: dead friends nearby -> the
	// big revive; living friends nearby -> the shield-and-heal; neither
	// -> fall back to the spike.
	Missile.T08.CheckThem:
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "Arachnotron", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "HellKnight", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "Cacodemon", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "Demon", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "Spectre", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "ChaingunGuy", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "DoomImp", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "Fatso", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "Revenant", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "ShotgunGuy", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" A 0 A_CheckProximity("Missile.T08.HealNo", "ZombieMan", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_DEADONLY);
		"WICK" I 0 A_Jump(128, "Missile.T08.Spike");
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "Arachnotron", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "HellKnight", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "Cacodemon", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "Demon", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "Spectre", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "ChaingunGuy", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "DoomImp", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "Fatso", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "Revenant", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "ShotgunGuy", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "ZombieMan", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"WICK" A 0 A_CheckProximity("Missile.T08.CalmDown", "PainElemental", 320, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		Goto Missile.T08.Spike;
	Missile.T08.CalmDown:
		"WICK" II 8 Bright;
		"WICK" J 3 { A_RadiusGive("RS_ShieldUpVile2", 420, RGF_MONSTERS, 1); }
		"WICK" JJJJ 1 { A_SpawnItemEx("RS_MediCacoBrown", random(-64, 64), random(-64, 64), random(-16, 64), random(1, 9), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		"WICK" K 3 { A_RadiusGive("Health", 1200, RGF_MONSTERS, 500); }
		"WICK" KKKKK 1 { A_SpawnItemEx("RS_MediCacoBrown", random(-64, 64), random(-64, 64), random(-16, 64), random(1, 9), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		"WICK" K 2;
		"WICK" L 5;
		Goto See;
	Missile.T08.HealNo:
		"WICK" I 4 Bright;
		"WICK" I 1 { A_SpawnItemEx("RS_Drt2", 0, 164, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt3", -164, 0, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt1", 0, -164, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt2", -164, 164, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt3", -164, -164, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt1", 164, 0, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt2", 0, 164, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt3", 164, 0, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt1", 164, 0, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt2", 164, 164, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" I 1 { A_SpawnItemEx("RS_Drt3", 164, 0, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		"WICK" IIII 1 Bright { A_SpawnItemEx("RS_ArchRingHelp", random(-64, 64), random(-64, 64), 3); }
		"WICK" IIII 1 Bright { A_SpawnItemEx("RS_ArchRingHelp", random(-128, 128), random(-128, 128), 3); }
		"WICK" IIIIII 1 Bright { A_SpawnItemEx("RS_ArchRingHelp", random(-252, 252), random(-252, 252), 3); }
		"WICK" IIIIIIIII 1 Bright { A_SpawnItemEx("RS_ArchRingHelp", random(-352, 352), random(-352, 352), 3); }
		"WICK" J 5 Bright;
		"WICK" K 8 Bright;
		"WICK" L 5 Bright;
		"WICK" I 1 { A_SpawnItemEx("RS_Drt1", 164, 0, -16, random(1, 5), 0, random(1, 5), random(0, 360)); }
		Goto Missile.T08.CalmDown;
	Heal.T08:
		// CHP folds the brown vile's resurrect into the CalmDown cast --
		// there is no separate Heal block on 14_BR.
		Goto Missile.T08.CheckThem;
	Pain.T08:
		"WICK" M 3;
		"WICK" M 6 { A_Pain(); }
		Goto See;
	Death.T08:
		"WICK" N 5 { A_Scream(); }
		"WICK" O 5 { bFLOATBOB = false; }
		"WICK" P 5 { A_KillChildren("Extreme", KILS_FOILINVUL | KILS_KILLMISSILES); }
		"WICK" P 0 { A_SpawnItemEx("RS_WickedTorso", 0, 0, 48, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WICT" A 5 { A_NoBlocking(); }
		"WICT" BCDEF 5;
		"WICT" G -1 { A_SetFloorClip(); }
		Stop;

	// =================================================================
	// T09 GRAY (14_GY -- CommonGrayArch : GrayArch2). VGRY.
	// Like a stone: a two-target rock drop, or a three-fan of ground
	// spikes. Its heal spawns a friend, and half its pain rolls turn
	// it invisible and let it walk somewhere else entirely.
	// =================================================================
	Spawn.T09:
		"VGRY" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"VGRY" AABBCCDDEEFF 2 { A_VileChase(); }
		Loop;
	Missile.T09:
		"VGRY" G 2 Bright { A_VileStart(); }
		"VGRY" G 0 A_Jump(128, "Missile.T09.GroundSpike");
		"VGRY" GG 6 Bright { A_FaceTarget(); }
		"VGRY" G 1 Bright { A_StartSound("vile/sight", CHAN_VOICE); }
		"VGRY" G 6 Bright { A_FaceTarget(); }
		"VGRY" H 5 Bright { A_VileTarget("RS_CHBSTarget"); }
		"VGRY" IJ 5 Bright { A_FaceTarget(); }
		"VGRY" K 5 Bright { A_VileTarget("RS_CHBSTarget"); }
		"VGRY" L 5 Bright { A_FaceTarget(); }
		"VGRY" M 0 A_CheckSight("See");
		"VGRY" M 9 Bright { A_VileTarget("RS_RockVileDrop"); }
		"VGRY" N 3 Bright;
		"VGRY" O 7 Bright;
		"VGRY" P 16 Bright;
		Goto See;
	Missile.T09.GroundSpike:
		"VGRY" GG 6 Bright { A_FaceTarget(); }
		"VGRY" HIJ 4 Bright;
		"VGR2" ABC 4 { A_FaceTarget(); }
		"VGR2" ABC 2 Bright { A_SpawnProjectile("RS_VileGroundSpike", 0, 0, 0); }
		"VGR2" ABC 1 Bright { A_SpawnProjectile("RS_VileGroundSpike", 0, 0, -45); }
		"VGR2" ABC 1 Bright { A_SpawnProjectile("RS_VileGroundSpike", 0, 0, 45); }
		"VGR2" ABC 4;
		Goto See;
	Heal.T09:
		"VGR2" ABC 10 Bright;
		"VGRY" G 0 { RS_Conjure(); }
		Goto See;
	Pain.T09:
		"VGRY" Q 5;
		"VGRY" Q 5 { A_Pain(); }
		"VGRY" Q 0 A_Jump(128, "Pain.T09.Seeya");
		Goto See;
	Pain.T09.Seeya:
		"VGRY" G 0 { bNOPAIN = false; bSHOOTABLE = false; bSOLID = false; }
		"VGRY" GGG 8 { A_FadeOut(0.33); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 { A_Wander(); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 { A_Wander(); }
		"VGRY" G 0 { bSHOOTABLE = true; bNOPAIN = true; bSOLID = true; }
		"VGRY" GGG 8 { A_FadeIn(0.33); }
		Goto See;
	Death.T09:
		"VGRY" Q 7;
		"VGRY" R 7 { A_Scream(); }
		"VGRY" S 7 { A_NoBlocking(); }
		"VGRY" TUVWXY 7;
		"VGRY" Z -1;
		Stop;

	// =================================================================
	// T10 RED (14_R -- CommonRedArch3 : RedArch3). DIAB.
	// The Grand Redfirevile. Four patterns: a triple-blast pillar, a
	// long flare storm, a soul summon, and a ground whirl. Below half
	// health it enrages ONCE, permanently, and gains MISSILEEVENMORE.
	// CHP's OldClassical is dead code -- nothing jumps to it -- and is
	// carried here in the same unreachable position for parity.
	// =================================================================
	Spawn.T10:
		"DIAB" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"DIAB" AABBCCDDEEFF 2 { A_Chase(); }
		Loop;
	Missile.T10:
		"DIAB" G 0 A_JumpIfHealthLower(1650, "Missile.T10.AggroUp");
	Missile.T10.Pick:
		"DIAB" G 0 A_Jump(60, "Missile.T10.Fires");
		"DIAB" G 0 A_Jump(132, "Missile.T10.Fires", "Missile.T10.SummonSouls", "Missile.T10.GroundVhirl");
		Goto Missile.T10.Classical;
	Missile.T10.OldClassical:
		"DIAB" GH 3 Bright { A_FaceTarget(); }
		"DIAB" I 3 { A_SpawnProjectile("RS_DFire", 32, 0, 0); }
		"DIAB" HGHIHGHIHGHIGHI 3 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T10.Classical:
		"DIAB" G 0 { A_VileStart(); }
		"DIAB" G 10 Bright { A_FaceTarget(); }
		"DIAB" H 10 Bright { A_VileTarget("RS_ReAFireNew"); }
		"DIAB" IJKLMN 10 Bright { A_FaceTarget(); }
		"DIAB" O 6 Bright { A_VileAttack("vile/stop", random(15, 20), random(30, 40), 64, 1, "Fire"); }
		"DIAB" N 6 Bright { A_FaceTarget(); }
		"DIAB" O 6 Bright { A_VileAttack("vile/stop", random(15, 20), random(30, 40), 64, 1, "Fire"); }
		"DIAB" N 6 Bright { A_FaceTarget(); }
		"DIAB" O 6 Bright { A_VileAttack("vile/stop", random(15, 20), random(30, 40), 64, 1, "Fire"); }
		"DIAB" N 6 Bright { A_FaceTarget(); }
		"DIAB" P 15 Bright;
		Goto See;
	Missile.T10.Fires:
		"DIA2" A 2 Bright { A_SpawnProjectile("RS_BaronRing", 1, 0); }
		"DIA2" ABC 10 Bright { A_StartSound("spell/spellcast1", CHAN_WEAPON); }
		"DIAB" PON 9 Bright { A_FaceTarget(); }
		"DIAB" I 6 Bright { A_SpawnProjectile("RS_BaronRing", 64, 0); }
		"DIAB" IH 7 Bright;
		"DIAB" GHGH 2 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-12, 12)); }
		"DIAB" GHGH 1 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" GHGH 2 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" GHGH 1 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" GHGH 2 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" GHGH 2 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-12, 12)); }
		"DIAB" GHGH 1 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" GHGH 2 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" GHGH 1 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" GHI 2 Bright { A_SpawnProjectile("RS_DFlare", random(20, 46), 0, random(-180, 180)); }
		"DIAB" I 1 Bright A_Jump(48, "Missile.T10.GroundVhirl");
		"DIAB" I 1 Bright A_Jump(24, "Missile.T10.SummonSouls");
		Goto See;
	Missile.T10.SummonSouls:
		"DIA2" A 10 Bright { A_FaceTarget(); }
		"DIAB" B 2 Bright { A_StartSound("vile/sight", CHAN_VOICE); }
		"DIA2" BB 6 Bright { A_SpawnItemEx("RS_ArchSpawnerOrb", 0, -5, 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"DIA2" C 4 Bright { A_FaceTarget(); }
		"DIA2" CC 6 { A_SpawnItemEx("RS_ArchSpawnerOrb", 0, -5, 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"DIA2" C 0 { RS_Conjure(); }
		Goto See;
	Missile.T10.GroundVhirl:
		"DIA2" A 12 Bright { A_FaceTarget(); }
		"DIA2" A 2 Bright { A_SpawnProjectile("RS_BaronRing", 64, 0); }
		"DIA2" B 2 Bright { A_FaceTarget(); }
		"DIA2" C 5 Bright;
		"DIA2" C 0 { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(-13, -3)); }
		"DIA2" C 0 { A_SpawnProjectile("RS_ArcRing2", 12, 0, random(3, 13)); }
		Goto See;
	Missile.T10.AggroUp:
		"DIAB" G 1;
		"DIAB" G 2 { if (rsRage >= 1) return ResolveState("Missile.T10.Pick"); return ResolveState(null); }
		"DIAB" G 0 { bNOPAIN = true; }
		"DIAB" GG 1 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, 0, CMF_AIMOFFSET, random(0, 360)); }
		"DIAB" G 9 { A_StartSound("vile/sight", CHAN_VOICE); }
		"DIAB" GGGGGGGGGG 1 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, 0, CMF_AIMOFFSET, random(0, 360)); }
		"DIAB" G 1 { bMISSILEEVENMORE = true; bNOPAIN = false; }
		"DIAB" G 2 { rsRage++; MarkEnrageTell(); }
		Goto Missile.T10.Pick;
	Heal.T10:
		"DIAB" G 0 { RS_Conjure(); }
		"DIA2" ABC 8 Bright;
		Goto See;
	Pain.T10:
		"DIAB" Q 5;
		"DIAB" Q 5 { A_Pain(); }
		Goto See;
	Death.T10:
		"DIAB" Q 7;
		"DIAB" R 7 { A_Scream(); }
		"DIAB" S 7 { A_NoBlocking(); }
		"DIAB" TUVW 7;
		"DIAB" XY 5;
		"DIAB" Z -1;
		Stop;

	// =================================================================
	// T11 BLACK (14_K -- CommonBlackArch2 : BlackVile). VILE + void.
	// The Void Gazes Back. It trails a cloud of itself everywhere it
	// walks and fires clouds while chasing. Three patterns: bouncing
	// orbs, a dark-flame ground sweep, and a summon capped at two live
	// batches -- pain refunds one. CHP bolts two BVileEye actors on at
	// spawn; RS already does that via OnTierApplied.
	// =================================================================
	Spawn.T11:
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" A 5 { A_Look(); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" B 5 { A_Look(); }
		Loop;
	See.T11:
		"VILE" AA 1 { A_Chase(); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" BB 1 { A_Chase(); }
		"VILE" A 0 { A_SpawnProjectile("RS_BVileCloud", 1, random(-5, 5), 0, CMF_AIMOFFSET, random(0, 90)); }
		"VILE" CC 1 { A_Chase(); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" DD 1 { A_Chase(); }
		"VILE" A 0 { A_SpawnProjectile("RS_BVileCloud", 1, random(-5, 5), 0, CMF_AIMOFFSET, random(0, 90)); }
		"VILE" EE 1 { A_Chase(); }
		"VILE" FF 1 { A_Chase(); }
		"VILE" A 0 { A_SpawnProjectile("RS_BVileCloud", 1, random(-5, 5), 0, CMF_AIMOFFSET, random(0, 90)); }
		Loop;
	Missile.T11:
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" A 8 { A_FaceTarget(); }
		"VILE" A 0 A_Jump(256, "Missile.T11.GroundFlame", "Missile.T11.Balls", "Missile.T11.Summon");
		Goto Missile.T11.Balls;
	Missile.T11.Balls:
		"VILE" M 6 { A_FaceTarget(); }
		"VILE" N 5 { A_SpawnProjectile("RS_BVileOrb1", 32, 0, random(-5, 5)); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" M 3 { A_FaceTarget(); }
		"VILE" N 3 { A_SpawnProjectile("RS_BVileOrb1", 32, 0, random(-12, 12)); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" M 3 { A_FaceTarget(); }
		"VILE" N 3 { A_SpawnProjectile("RS_BVileOrb1", 32, 0, random(-19, 19)); }
		Goto See;
	Missile.T11.Summon:
		"VILE" G 0 { if (rsVoidLimit >= 1) return ResolveState("Missile.T11.Balls"); return ResolveState(null); }
		"VILE" G 12 { A_StartSound("vile/sight", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" GGGGGGGGGGGGG 4 { A_SpawnProjectile("RS_DFlamePuffVile2", random(42, 72), random(-34, 34), random(-180, 180), 0, random(-64, 64)); }
		"VILE" J 15 { A_StartSound("vile/start", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" NOP 15 Bright;
		"VILE" A 0 { SummonMinion("RS_Revenant", -1, 96.0); }
		"VILE" A 0 { RS_Conjure(); }
		"VILE" A 0 { RS_Conjure(); }
		"VILE" GGGGGGGGGG 0 { A_SpawnProjectile("RS_DFlamePuffVile2", random(6, 32), random(-34, 34), random(-180, 180), 0, random(-64, 64)); }
		"VILE" A 1 { rsVoidLimit += 2; }
		Goto See;
	Missile.T11.GroundFlame:
		"VILE" G 8 { A_FaceTarget(); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" JJJJJJJJJ 1 { A_SpawnProjectile("RS_DFlamePuffVile2", random(4, 42), 0, random(-64, 64), 0, random(-64, 64)); }
		"VILE" A 0 { A_SpawnItemEx("RS_BVileCloud2", random(-7, 7), random(-7, 7), 1, frandom(-1.1, 1.1), frandom(-1.1, 1.1), 0.1, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPITCH); }
		"VILE" NOP 10 Bright;
		"VILE" A 0 { A_SpawnProjectile("RS_DarkFlameVile", 3, 23, 12, CMF_AIMDIRECTION); }
		"VILE" A 0 { A_SpawnProjectile("RS_DarkFlameVile", 3, -23, -12, CMF_AIMDIRECTION); }
		Goto See;
	Heal.T11:
		"VILE" NOP 8 Bright;
		"VILE" A 0 { RS_Conjure(); }
		Goto See;
	Pain.T11:
		"VILE" Q 5;
		"VILE" Q 5 { A_Pain(); }
		"VILE" Q 5 A_Jump(88, "Pain.T11.Phase");
		Goto See;
	Pain.T11.Phase:
		"VILE" Q 1 { A_SetSpeed(99); }
		"VILE" ABCDEF 1 { A_Wander(); }
		"VILE" Q 1 { A_SetSpeed(17); }
		"VILE" Q 1 { rsVoidLimit = max(0, rsVoidLimit - 1); }
		Goto See;
	Death.T11:
		"VILE" Q 7;
		"VILE" Q 7 { A_Scream(); }
		"VILE" Q 7 { A_NoBlocking(); }
		"VILE" Q 1 { A_KillChildren("Extreme", KILS_FOILINVUL | KILS_KILLMISSILES); }
		"VILE" QQQQQQQ 7 { A_FadeOut(0.1); }
		Stop;

	// =================================================================
	// T12 WHITE (14_W -- CommonWhiteArch2 : WhiteVile). LMWZ + FLWM.
	// "Here I Am." A floating eye that will not commit until it has
	// worked itself up: a courage counter climbs while it stalks
	// invisibly, and each rung unlocks a faster, braver walk. Its
	// attacks spend courage back down. It reseeds resurrection fields
	// constantly, and up close it screams the room into a quake.
	// =================================================================
	Spawn.T12:
		"LMWZ" E 10 { A_Look(); }
		Loop;
	See.T12:
		"LMWZ" EEFFEEFF 1 { A_Chase(); }
		"LMWZ" E 1 { bNOCLIP = true; }
		Goto See.T12.Clippy;
	See.T12.Clippy:
		"LMWZ" E 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWZ" E 0 { if (rsCourage >= 160) return ResolveState("See.T12.Agro2"); return ResolveState(null); }
		"LMWZ" E 0 { if (rsCourage >= 100) return ResolveState("See.T12.Agro"); return ResolveState(null); }
		"LMWZ" E 0 { if (rsCourage >= 60) return ResolveState("See.T12.Approach"); return ResolveState(null); }
		"LMWZ" E 1 { A_FastChase(); }
		"LMWZ" E 1 { A_FaceTarget(); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.75); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.5); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.25); }
		"LMWZ" E 3 { A_Stop(); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.01); }
		"LMWZ" EE 2 { A_Chase(); }
		"LMWZ" E 0 A_CheckSight("See.T12.NoWander");
		"LMWZ" EEEEEE 10 { A_Wander(); }
		"LMWZ" EEEEEE 10 { A_Wander(); }
		"LMWZ" EE 2 { A_Chase(); }
		"LMWZ" E 0 { rsCourage++; }
		"LMWZ" F 1 { A_SetTranslucent(0.25); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.5); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.75); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(1.0); }
		"LMWZ" E 15 { A_Stop(); }
		Loop;
	See.T12.Approach:
		"LMWZ" E 0 { A_SetSpeed(30); }
		TNT1 A 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWZ" EE 6 { A_Chase(); }
		"LMWZ" E 0 { rsCourage += 2; }
		"LMWZ" E 5 { A_FastChase(); }
		"LMWZ" E 3 { A_Stop(); }
		Loop;
	See.T12.NoWander:
		"LMWZ" EE 2 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWZ" F 1 { A_SetTranslucent(0.25); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.5); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(0.75); }
		"LMWZ" E 1 { A_Chase(); }
		"LMWZ" F 1 { A_SetTranslucent(1.0); }
		"LMWZ" E 0 { rsCourage += 3; }
		"LMWZ" E 15 { A_Stop(); }
		Goto See.T12.Clippy;
	See.T12.Agro:
		"LMWZ" E 0 { A_SetSpeed(30); bMISSILEMORE = true; }
		TNT1 A 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWZ" EE 6 { A_Chase(); }
		"LMWZ" E 4 { A_FastChase(); }
		"LMWZ" E 1 { A_Stop(); }
		"LMWZ" E 0 { rsCourage += 4; }
		"LMWZ" E 5 { A_Chase(); }
		"LMWZ" E 4 { A_FastChase(); }
		"LMWZ" E 1 { A_Stop(); }
		Loop;
	See.T12.Agro2:
		"LMWZ" E 0 { A_SetSpeed(38); bMISSILEEVENMORE = true; }
		TNT1 A 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWZ" E 0 { rsCourage += 100; }
		"LMWZ" E 4 { A_Chase(); }
		"LMWZ" E 4 { A_FastChase(); }
		"LMWZ" E 4 { A_Chase(); }
		Loop;
	Missile.T12:
		"LMWZ" E 0 { A_SetTranslucent(1.0); }
		"LMWZ" E 0 { if (rsHoho >= 1) return ResolveState("Missile.T12.EyeSeekers"); return ResolveState(null); }
		"LMWZ" E 0 A_JumpIfCloser(1500, "Missile.T12.Choices2", true);
		"LMWZ" E 0 A_Jump(256, "Missile.T12.Choices1");
		Goto See.T12.Clippy;
	Missile.T12.Choices1:
		"LMWZ" E 0 A_Jump(256, "Missile.T12.SpawnEye", "Missile.T12.EyeSees", "Missile.T12.Bolts");
		Goto See.T12.Clippy;
	Missile.T12.Choices2:
		"LMWZ" E 0 A_Jump(256, "Missile.T12.Scream", "Missile.T12.SpawnEye", "Missile.T12.EyeSees", "Missile.T12.BoltVolley");
		Goto See.T12.Clippy;
	Missile.T12.SpawnEye:
		"LMWZ" EF 10 { A_FaceTarget(); }
		"LMWZ" GGG 5 Bright { A_SpawnItemEx("RS_WVileSpot", random(-128, 128), random(-128, 128), 1, 0, 0, 0, 0, SXF_TRANSFERPOINTERS | SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWZ" HG 12;
		"LMWZ" E 2 { rsCourage = max(0, rsCourage - 15); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_WhiteVileResser", random(-128, 128), random(-128, 128), 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		Goto See.T12.Clippy;
	Missile.T12.Bolts:
		"LMWZ" EF 12 { A_FaceTarget(); }
		"LMWZ" G 5 Bright { A_SpawnProjectile("RS_WVileBolt1", 42, 0, random(-1, 1)); }
		"LMWZ" G 5 Bright { A_SpawnProjectile("RS_WVileBolt1", 42, 0, 0); }
		"LMWZ" G 5 Bright { A_SpawnProjectile("RS_WVileBolt1", 42, 0, random(-1, 1)); }
		"LMWZ" G 5 Bright { A_SpawnProjectile("RS_WVileBolt1", 42, 0, random(-3, 3)); }
		"LMWZ" HG 12;
		"LMWZ" E 2 { rsCourage = max(0, rsCourage - 10); }
		Goto See.T12.Clippy;
	Missile.T12.BoltVolley:
		"LMWZ" EFG 10 Bright { A_FaceTarget(); }
		"LMWZ" G 0 { A_SpawnProjectile("RS_WVileBolt1", 42, 0, 6); }
		"LMWZ" G 0 { A_SpawnProjectile("RS_WVileBolt1", 42, 0, 0); }
		"LMWZ" G 0 { A_SpawnProjectile("RS_WVileBolt1", 42, 0, -6); }
		"LMWZ" G 0 { A_SpawnProjectile("RS_WVileBolt1", 42, 0, -12); }
		"LMWZ" G 0 { A_SpawnProjectile("RS_WVileBolt1", 42, 0, 12); }
		"LMWZ" HG 12;
		"LMWZ" E 2 { rsCourage = max(0, rsCourage - 15); }
		Goto See.T12.Clippy;
	Missile.T12.Scream:
		"FLWM" A 24 Bright;
		"FLWM" A 0 A_CheckSight("See");
		"FLWM" A 24 Bright;
		"FLWM" A 0 A_CheckSight("See");
		"FLWM" B 14 Bright { A_SpawnItemEx("RS_WVileQuake", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		"FLWM" B 14 Bright { A_StartSound("vile/sight", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		TNT1 AAAAAAAAA 0 { A_SpawnItemEx("RS_WhiteVileResser", random(-728, 728), random(-728, 728), 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_BrightUpVile2", random(-128, 128), random(-128, 128), random(1, 12), 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"FLWM" C 12 Bright;
		TNT1 AAAA 0 { A_SpawnItemEx("RS_BrightUpVile2", random(-328, 328), random(-328, 328), random(1, 12), 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"FLWM" DE 10 Bright;
		TNT1 AAAAAA 0 { A_SpawnItemEx("RS_WhiteVileResser", random(-128, 128), random(-128, 128), 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"FLWM" EDCBA 5 Bright;
		"LMWZ" E 0 { rsCourage = max(0, rsCourage - 15); }
		Goto See.T12.Clippy;
	Missile.T12.EyeSees:
		"LMWZ" E 1 { A_StartSound("vile/active", CHAN_VOICE); }
		"LMWZ" EFG 10 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnProjectile("RS_WVileEye", 78, 0); }
		TNT1 A 0 { A_SpawnProjectile("RS_WVileEye", 64, 12); }
		TNT1 A 0 { A_SpawnProjectile("RS_WVileEye", 64, -12); }
		TNT1 A 0 { A_SpawnProjectile("RS_WVileEye", 48, 24); }
		TNT1 A 0 { A_SpawnProjectile("RS_WVileEye", 48, -24); }
		TNT1 A 0 { rsHoho++; }
		"LMWZ" HG 10;
		"LMWZ" E 2;
		Goto See.T12.Clippy;
	Missile.T12.EyeSeekers:
		// CH released the hovering eyes with an inventory token handed
		// out by ACS. RS_WVileEye charges on its own timer, so this is
		// now just the tell and the bookkeeping.
		"LMWZ" G 5 Bright { A_FaceTarget(); }
		"LMWZ" E 0 { rsCourage = max(0, rsCourage - 10); rsHoho = max(0, rsHoho - 1); }
		Goto Missile.T12;
	Pain.T12:
		"LMWZ" I 3;
		"LMWZ" E 0 { rsCourage += 5; }
		"LMWZ" I 5 { A_Pain(); }
		"LMWZ" I 3 A_Jump(128, "Pain.T12.Whatthe");
		Goto See.T12.Clippy;
	Pain.T12.Whatthe:
		"LMWZ" F 1 { bNOPAIN = true; }
		"LMWZ" F 1 { A_SetTranslucent(0.66); }
		"LMWZ" F 1 { A_SetTranslucent(0.33); }
		"LMWZ" F 1 { A_SetTranslucent(0.01); }
		"LMWZ" EEEEEEEEEEEEEEEEEEEEEEEEEE 1 { A_Wander(); }
		"LMWZ" EEEEEEEEEEEEEEEEEEEEEEEEEE 1 { A_Wander(); }
		"LMWZ" F 1 { A_SetTranslucent(0.5); }
		"LMWZ" F 1 { A_SetTranslucent(1.0); }
		"LMWZ" F 1 { bNOPAIN = false; }
		"LMWZ" E 0 { rsCourage = max(0, rsCourage - 15); }
		"LMWZ" F 4 { A_Stop(); }
		Goto See.T12.Clippy;
	Heal.T12:
		// The white vile never resurrects by hand -- its fields do it.
		"LMWZ" E 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWZ" EF 6 Bright;
		Goto See.T12.Clippy;
	Death.T12:
		"LMWZ" J 6 { A_Scream(); }
		TNT1 A 0 { A_KillChildren("Extreme", KILS_FOILINVUL | KILS_KILLMISSILES); }
		"LMWZ" K 6 { A_NoBlocking(); }
		"LMWZ" LMNO 6;
		"LMWZ" P -1;
		Stop;

	// =================================================================
	// TEX BLACK-EX (14_KX -- CommonBlackArchEX2). SILE + SPIN + FX07.
	// "AHH HELP!!!" -- the tornado vile. It is not a caster at all: it
	// is a WEATHER SYSTEM. It sheds a damaging dust cloud on every
	// single step, and its whole roster is wind:
	//   Leaves    -- a RadiusThrust shove plus sheets of leaf shrapnel
	//   Shadowing -- a wall of blinding shadow waves
	//   KABAM     -- one seeking mind-wave that trails ripping shadow
	//   Wooosh    -- four floor-hugging tornadoes
	//   Woahoahoahoah -- it BECOMES the tornado: NOPAIN, wanders,
	//                    sucks you in (negative RadiusThrust) for up to
	//                    40 beats, then reforms
	// TWO health gates, and unlike every other vile here they widen the
	// roster instead of replacing it: below 1800 it drops the leaf
	// storm for Shadowing/KABAM and speeds to 24; below 900 it runs all
	// five and speeds to 30.
	// =================================================================
	Spawn.TEX:
		"SILE" A 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" A 5 { A_Look(); }
		"SILE" A 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" A 5 { A_Look(); }
		"SILE" A 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" B 5 { A_Look(); }
		"SILE" A 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" B 5 { A_Look(); }
		Loop;
	See.TEX:
		"SILE" A 0 { A_StartSound("Bvile/Air6", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		Goto See.TEX.Walk;
	See.TEX.Walk:
		"SILE" A 0 A_JumpIfHealthLower(900, "See.TEX.Phase3");
		"SILE" A 0 A_JumpIfHealthLower(1800, "See.TEX.Phase2");
	See.TEX.Walk.Loop:
		"SILE" A 2 { A_Chase(); }
		"SILE" A 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" A 2 { A_Chase(); }
		"SILE" A 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" B 2 { A_Chase(); }
		"SILE" B 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" B 2 { A_Chase(); }
		"SILE" B 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" C 2 { A_Chase(); }
		"SILE" C 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" C 2 { A_Chase(); }
		"SILE" C 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" D 2 { A_Chase(); }
		"SILE" D 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" D 2 { A_Chase(); }
		"SILE" D 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" E 2 { A_Chase(); }
		"SILE" E 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" E 2 { A_Chase(); }
		"SILE" E 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" F 2 { A_Chase(); }
		"SILE" F 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" F 2 { A_Chase(); }
		"SILE" F 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" F 0 A_Jump(128, "See.TEX.Moveit");
		Goto See.TEX.Walk;
	See.TEX.Moveit:
		"SILE" F 0 A_Jump(128, "See.TEX.Moveit.Long");
		"SILE" AAAA 0 { A_Wander(); }
		Goto See.TEX.Walk;
	See.TEX.Moveit.Long:
		"SILE" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
		Goto See.TEX.Walk;
	See.TEX.Phase2:
		"SILE" A 0 { A_SetSpeed(24); }
		Goto See.TEX.Walk.Loop;
	See.TEX.Phase3:
		"SILE" A 0 { A_SetSpeed(30); }
		Goto See.TEX.Walk.Loop;
	Missile.TEX:
		"SILE" AAAA 0 { A_SpawnItemEx("RS_BVileEXCloud2", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 15.0), 0, 32); }
		"SILE" A 0 A_JumpIfHealthLower(900, "Missile.TEX.Phase3Jumps");
		"SILE" A 0 A_JumpIfHealthLower(1800, "Missile.TEX.Phase2Jumps");
		"SILE" A 0 A_Jump(192, "Missile.TEX.Leaves");
		Goto Missile.TEX.Vortex;
	Missile.TEX.Phase2Jumps:
		"SILE" A 0 A_Jump(256, "Missile.TEX.Shadowing", "Missile.TEX.Kabam");
		Goto See;
	Missile.TEX.Phase3Jumps:
		"SILE" A 0 A_Jump(32, "Missile.TEX.Vortex");
		"SILE" A 0 A_Jump(256, "Missile.TEX.Shadowing", "Missile.TEX.Kabam", "Missile.TEX.Leaves", "Missile.TEX.Wooosh");
		Goto See;
	Missile.TEX.Leaves:
		"SILE" G 0 { A_StartSound("tornado/form"); }
		"SILE" G 0 { A_FaceTarget(); }
		"SILE" GH 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" H 0 { A_FaceTarget(); }
		"SILE" IJK 3 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" K 0 { A_FaceTarget(); }
		"SILE" LMN 3 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 0 { A_StartSound("wind/away"); }
		"SILE" O 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" NNNNNN 0 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" N 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" NNNNNN 0 { A_SpawnProjectile("RS_Leaves2", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_Leaves2", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" NNNNNN 0 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" O 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" OOOOOO 0 { A_SpawnProjectile("RS_Leaves2", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" O 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" O 4 { A_SpawnProjectile("RS_Leaves2", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" PPP 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		Goto See;
	// "Woahoahoahoah" -- it stops being a body and becomes the storm.
	// NOPAIN for the whole move; the spin loop runs up to 40 beats
	// (CHP's TornadoToken counter, an int here) and PULLS you inward.
	Missile.TEX.Vortex:
		SPIN A 0 { bNOPAIN = true; rsExTornado = 0; }
		SPIN ABCD 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN ABCD 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		FX07 ABC 2;
	Missile.TEX.Vortex.Spin:
		FX07 A 0 { A_StartSound("tornado/form"); }
		FX07 A 0 { A_RadiusThrust(-1000, 400, RTF_NOTMISSILE); }
		FX07 A 0 { A_SpawnItemEx("RS_BVileEXCloud5", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		FX07 AAA 0 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-32, 32), random(0, 360), 0, random(-5, 5)); }
		FX07 A 2 { A_Wander(); }
		FX07 B 0 { A_RadiusThrust(-1000, 400, RTF_NOTMISSILE); }
		FX07 A 0 { A_SpawnItemEx("RS_BVileEXCloud5", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		FX07 BBB 0 { A_SpawnProjectile("RS_Leaves2", random(16, 64), random(-32, 32), random(0, 360), 0, random(-5, 5)); }
		FX07 B 2 { A_Wander(); }
		FX07 C 0 { A_RadiusThrust(-1000, 400, RTF_NOTMISSILE); }
		FX07 A 0 { A_SpawnItemEx("RS_BVileEXCloud5", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		FX07 CCC 0 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-32, 32), random(0, 360), 0, random(-5, 5)); }
		FX07 C 2 { A_Wander(); }
		FX07 A 0
		{
			if (rsExTornado >= 40)
				return ResolveState("Missile.TEX.Vortex.End");
			rsExTornado++;
			return ResolveState(null);
		}
		Goto Missile.TEX.Vortex.Spin;
	Missile.TEX.Vortex.End:
		SPIN A 0 { rsExTornado = 0; }
		SPIN ABCD 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN ABCD 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1;
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN A 0 { bNOPAIN = false; }
		Goto See;
	Missile.TEX.Shadowing:
		"SILE" A 0 { A_StartSound("Bvile/Air1", CHAN_7, 0, 1.0, ATTN_NONE); }
		"SILE" G 0 { A_FaceTarget(); }
		"SILE" GH 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" H 0 { A_FaceTarget(); }
		"SILE" IJK 3 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" K 0 { A_FaceTarget(); }
		"SILE" LMN 3 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 3 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-5, 5)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-5, 5)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-5, 35)); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-5, 35)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-35, 5)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-35, 5)); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-50, 50)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-50, 50)); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-50, 50)); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-50, 50)); }
		"SILE" O 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" O 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-50, 50)); }
		"SILE" O 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" O 4 { A_SpawnProjectile("RS_BVileEXWAVE3", random(16, 64), random(-64, 64), random(-50, 50)); }
		"SILE" PPP 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		Goto See;
	Missile.TEX.Kabam:
		"SILE" A 0 { A_StartSound("Bvile/Air2", CHAN_7, 0, 1.0, ATTN_NONE); }
		SPIN ABCD 1 { A_FaceTarget(); }
		"SILE" D 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1 { A_FaceTarget(); }
		"SILE" H 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN ABCD 1 { A_FaceTarget(); }
		"SILE" D 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1 { A_FaceTarget(); }
		"SILE" H 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" H 0 { A_FaceTarget(); }
		"SILE" LM 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 4 { A_SpawnProjectile("RS_BVileEXMindWave", 32, 0, 0); }
		"SILE" OPPP 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		Goto See;
	Missile.TEX.Wooosh:
		"SILE" G 0 { A_StartSound("tornado/form"); }
		SPIN ABCD 1 { A_FaceTarget(); }
		"SILE" D 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1 { A_FaceTarget(); }
		"SILE" H 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN ABCD 1 { A_FaceTarget(); }
		"SILE" D 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		SPIN EFGH 1 { A_FaceTarget(); }
		"SILE" H 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" H 0 { A_FaceTarget(); }
		"SILE" LM 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 0 { A_StartSound("wind/away"); }
		"SILE" N 0 { A_SpawnProjectile("RS_BVileEXTornado", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" O 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" NN 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 0 { A_SpawnProjectile("RS_BVileEXTornado", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" N 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" NN 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 0 { A_SpawnProjectile("RS_BVileEXTornado", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" N 0 { A_FaceTarget(); }
		"SILE" N 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" NN 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" N 0 { A_SpawnProjectile("RS_BVileEXTornado", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" O 0 { A_RadiusThrust(3000, 400, RTF_NOTMISSILE); }
		"SILE" OO 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" O 0 { A_SpawnProjectile("RS_BVileEXTornado", random(16, 64), random(-64, 64), random(-64, 64), 0, random(-5, 5)); }
		"SILE" PPP 4 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		Goto See;
	Pain.TEX:
		"SILE" AAAA 0 { A_SpawnItemEx("RS_BVileEXCloud2", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 15.0), 0, 32); }
		"SILE" Q 3;
		"SILE" Q 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" A 0 { A_StartSound("Bvile/Air6"); }
		"SILE" Q 3 { A_Pain(); }
		"SILE" Q 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" Q 3 A_Jump(156, "Pain.TEX.Wee");
		"SILE" A 0 { A_SpawnItemEx("RS_MrBones", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_TRANSFERRENDERSTYLE | SXF_TRANSFERSTENCILCOL | SXF_SETMASTER | SXF_NOCHECKPOSITION); }
		Goto See;
	Pain.TEX.Wee:
		"SILE" Q 1 { A_SetSpeed(99); }
		"SILE" Q 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" ABC 1 { A_Wander(); }
		"SILE" Q 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" DEF 1 { A_Wander(); }
		"SILE" Q 0 { A_SpawnItemEx("RS_BVileEXCloud", -4, random(-7, 7), 1, 0, 0, frandom(1.0, 2.0), 0, 32); }
		"SILE" Q 1 { A_SetSpeed(20); }
		"SILE" A 0 { A_SpawnItemEx("RS_MrBones", random(-24, 24), random(-24, 24), 6, 0, 0, 0, 0, SXF_TRANSFERRENDERSTYLE | SXF_TRANSFERSTENCILCOL | SXF_SETMASTER | SXF_NOCHECKPOSITION); }
		Goto See;
	// CHP's TEX has no Heal of its own -- A_VileChase is never in its
	// state set, so it never resurrects. Routed to See so the family
	// Heal dispatcher cannot dead-end on it.
	Heal.TEX:
		"SILE" A 0;
		Goto See;
	Death.TEX:
		// IT DOES NOT DIE HERE. CHP spawns three CommonBlackArchEX3 the
		// instant the body drops -- the storm breaks into three void
		// phantoms and the fight's second half starts. Verbatim: three,
		// not one, and not master-linked.
		"SILE" AAA 0 { A_SpawnItemEx("RS_ArchvilePhantomEX", 0, 0, 0, 0, 0, 0, 0, 32); }
		"SILE" AAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BVileEXCloud2", random(-7, 7), random(-7, 7), 1, frandom(-15.0, 15.0), frandom(-15.0, 15.0), frandom(0.0, 15.0), 0, 32); }
		"SILE" Q 7;
		"SILE" R 7 { A_Scream(); }
		"SILE" S 7 { A_NoBlocking(); }
		"SILE" T 7 { A_KillChildren("Extreme", KILS_FOILINVUL | KILS_KILLMISSILES); }
		"SILE" UVW 7;
		"SILE" XY 5;
		"SILE" Z -1;
		Stop;

	// =================================================================
	// T14 (14_WX -- CommonWhiteArchEX2). LMWX. "Time to die."
	// THE MASTER OF TIME. 20800 HP, speed 60, NOCLIP, VISIBILITYPULSE.
	//
	// It reuses T12's courage machinery and takes it further: a coward
	// that will not commit until it has worked itself up, except this
	// one can also STOP THE CLOCK on you.
	//
	//   COURAGE LADDER   60 -> Approach (speed 45)
	//                   100 -> Agro     (speed 45, +MISSILEMORE)
	//                   160 -> Agro2    (speed 60, +100 courage at once)
	//                   every attack spends courage back down (-10/-15,
	//                   -150 for ENDOFTIME), pain pays +5.
	//
	//   RANGE SPLIT     beyond 1000: ScreamofTime / RailofTime /
	//                                StealofTime
	//                   inside 1000: BoltsofTime / RingsofTime /
	//                                EyeofTime / CloneofTime
	//
	//   HEALTH GATE     12500 -> ShouldI: a 1-in-16 roll into ENDOFTIME.
	//                   Also the gate on StealofTime and CloneofTime --
	//                   neither is available while it is above 12500.
	//
	//   FREEZE GATE     RingsofTime deals NO damage; it stacks
	//                   RS_MOTFreezeToken on you. FOUR of them and it
	//                   cashes them in for a real TimeFreezer.
	//
	//   EYE GATE        EyeofTime plants eight RS_WVileEye and sets
	//                   rsHohoMOT; while that is set its NEXT missile is
	//                   EyeofTime2, which detonates all of them at once.
	//
	//   THE COUNTDOWN   ENDOFTIME starts a 300-SECOND clock (CHP's
	//                   WVileEXTimer2_C is Delay(10500), read from the
	//                   ACS source, not guessed). When it expires the
	//                   boss goes INVULNERABLE and drops into TIMESUP:
	//                   it freezes you, warps onto you, and machine-guns
	//                   TimeShock until you are a corpse. Kill it inside
	//                   five minutes or the fight is simply over.
	// =================================================================
	Spawn.T14:
		"LMWX" E 0
		{
			A_SetSize(20, 80, true);
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
	Spawn.T14.Idle:
		"LMWX" A 0 { bNOPAIN = false; rsTimesUpTic = 0; }
		"LMWX" E 10 { A_Look(); }
		Loop;
	See.T14:
	See.T14.Clippy:
		"LMWX" E 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWX" E 0
		{
			if (rsCourageMOT >= 160) return ResolveState("See.T14.Agro2");
			if (rsCourageMOT >= 100) return ResolveState("See.T14.Agro");
			if (rsCourageMOT >= 60)  return ResolveState("See.T14.Approach");
			return ResolveState(null);
		}
		"LMWX" E 1 { A_FastChase(); }
		"LMWX" E 1 { A_FaceTarget(); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" A 0 { bVISIBILITYPULSE = false; }
		"LMWX" F 1 { A_SetTranslucent(0.75, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(0.5, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(0.25, 1); }
		"LMWX" E 3 { A_Stop(); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(0.01, 1); }
		"LMWX" EE 2 { A_Chase(); }
		"LMWX" E 0 A_CheckSight("See.T14.NoWander");
		"LMWX" EEEEEE 10 { A_Wander(); }
		"LMWX" A 0 A_Jump(8, "Missile.T14.Rings");
		TNT1 A 0 { return RS_TimesUpMOT(); }
		"LMWX" A 0 A_JumpIfCloser(500, "See.T14.Maybe");
	See.T14.Clippy2:
		"LMWX" EEEEEE 10 { A_Wander(); }
		"LMWX" EE 2 { A_Chase(); }
		"LMWX" E 0 { rsCourageMOT++; }
		"LMWX" A 0
		{
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
		"LMWX" F 1 { A_SetTranslucent(0.25, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(0.5, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(0.75, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(1, 1); }
		"LMWX" E 15 { A_Stop(); }
		Goto See.T14.Clippy;
	See.T14.Maybe:
		"LMWX" A 0 A_CheckSight("See.T14.Clippy2");
		Goto Missile.T14;
	See.T14.NoWander:
		"LMWX" EE 2 { A_Chase(); }
		"LMWX" A 0
		{
			A_SpawnItemEx("RS_WhiteVileResser");
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
		"LMWX" F 1 { A_SetTranslucent(0.25, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(0.5, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(0.75, 1); }
		"LMWX" E 1 { A_Chase(); }
		"LMWX" F 1 { A_SetTranslucent(1, 1); }
		"LMWX" E 0 { rsCourageMOT += 3; }
		"LMWX" E 15 { A_Stop(); }
		TNT1 A 0 { return RS_TimesUpMOT(); }
		Goto See.T14.Clippy;
	See.T14.Approach:
		"LMWX" E 0 { A_SetSpeed(45); }
		"LMWX" A 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWX" EE 6 { A_Chase(); }
		"LMWX" E 0 { rsCourageMOT += 2; }
		"LMWX" E 5 { A_FastChase(); }
		"LMWX" E 3 { A_Stop(); }
		TNT1 A 0 { return RS_TimesUpMOT(); }
		Loop;
	See.T14.Agro:
		"LMWX" E 0 { A_SetSpeed(45); }
		"LMWX" A 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWX" E 0 { bMISSILEMORE = true; }
		"LMWX" EE 6 { A_Chase(); }
		"LMWX" E 4 { A_FastChase(); }
		"LMWX" E 1 { A_Stop(); }
		"LMWX" E 0 { rsCourageMOT += 4; }
		"LMWX" E 5 { A_Chase(); }
		"LMWX" E 4 { A_FastChase(); }
		"LMWX" E 1 { A_Stop(); }
		TNT1 A 0 { return RS_TimesUpMOT(); }
		Loop;
	See.T14.Agro2:
		"LMWX" E 0 { A_SetSpeed(60); }
		"LMWX" A 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWX" E 0 { bMISSILEMORE = true; rsCourageMOT += 100; }
		"LMWX" E 4 { A_Chase(); }
		"LMWX" E 4 { A_FastChase(); }
		"LMWX" E 4 { A_Chase(); }
		TNT1 A 0 { return RS_TimesUpMOT(); }
		Loop;
	Missile.T14:
		"LMWX" A 0 A_JumpIfHealthLower(12500, "Missile.T14.ShouldI");
	Missile.T14.Pick:
		"LMWX" A 0
		{
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SetTranslucent(1, 1);
		}
		"LMWX" E 0 { if (rsHohoMOT >= 1) return ResolveState("Missile.T14.EyeBoom"); return ResolveState(null); }
		TNT1 A 0 { return RS_TimesUpMOT(); }
	Missile.T14.Choices:
		"LMWX" A 0 A_JumpIfCloser(1000, "Missile.T14.Choices2", true);
		"LMWX" A 0 A_Jump(256, "Missile.T14.Choices1");
		Goto See.T14.Clippy;
	Missile.T14.Choices1:
		"LMWX" A 0 A_Jump(256, "Missile.T14.Scream", "Missile.T14.Rail", "Missile.T14.Steal");
		Goto See.T14.Clippy;
	Missile.T14.Choices2:
		"LMWX" A 0 A_Jump(256, "Missile.T14.Bolts", "Missile.T14.Rings", "Missile.T14.Eye", "Missile.T14.Clone");
		Goto See.T14.Clippy;
	Missile.T14.Bolts:
		"LMWX" EFG 8 Bright { A_FaceTarget(); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, 6); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, 0); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, -6); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, -12); }
		"LMWX" G 0 { A_SpawnProjectile("RS_BoltMOT", 42, 0, 12); }
		"LMWX" HG 10;
		"LMWX" E 0 A_Jump(128, "Missile.T14.Choices");
		"LMWX" E 2 { rsCourageMOT -= 15; }
		Goto See.T14.Clippy;
	// The room-clearing scream: it roots itself, takes half damage for
	// the duration, seeds the whole arena with resurrection fields and
	// quakes the place.
	Missile.T14.Scream:
		"LMWX" A 0
		{
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SetTranslucent(1, 1);
			bNOPAIN = true;
			A_GiveInventory("RS_WVileResist", 1);
		}
		"LMWX" Q 8 { A_FaceTarget(); }
		"LMWX" A 0 { A_StartSound("SPMDING", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" A 0 { A_SpawnItemEx("RS_SuperEye01", 4, 8, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"LMWX" A 0 { A_SpawnItemEx("RS_OldTimeyMOT", 0, 0, 16, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"LMWX" QQ 8 { A_FaceTarget(); }
		"LMWX" A 0 A_CheckSight("See.T14.Clippy");
		"LMWX" QQQ 8 { A_FaceTarget(); }
		"LMWX" A 0 A_CheckSight("See.T14.Clippy");
		"LMWX" R 14 Bright { A_SpawnItemEx("RS_WVileQuake", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		"LMWX" R 14 Bright { A_StartSound("Wvile/scream", CHAN_7, 0, 1.0, ATTN_NONE); }
		"LMWX" AAAAAAAAA 0 { A_SpawnItemEx("RS_WhiteVileResser", random(-728, 728), random(-728, 728), 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" AAAA 0 { A_SpawnItemEx("RS_BrightUpVile2", random(-128, 128), random(-128, 128), random(1, 12), 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" S 12 Bright { A_VileTarget("RS_EyeSpawnerMOT"); }
		"LMWX" AAAA 0 { A_SpawnItemEx("RS_BrightUpVile2", random(-328, 328), random(-328, 328), random(1, 12), 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" TU 10 Bright;
		"LMWX" AAAAAA 0 { A_SpawnItemEx("RS_WhiteVileResser", random(-128, 128), random(-128, 128), 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" UTSRQ 5 Bright;
		"LMWX" E 0 { rsCourageMOT -= 15; bNOPAIN = false; }
		Goto See.T14.Clippy;
	// Blinks out, warps behind you, and fires four freeze rings. Four
	// tokens on you and it cashes them in.
	Missile.T14.Rings:
		"LMWX" A 0 { A_TakeInventory("RS_MOTFreezeToken", 0, 0, AAPTR_TARGET); }
		"LMWX" A 30 Bright { A_StartSound("wizard/sight", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" A 0 { bVISIBILITYPULSE = false; }
		"LMWX" A 1 Bright { A_SetTranslucent(0.75, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.5, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.25, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.25, 1); }
		"LMWX" A 8 Bright { A_SetTranslucent(0.01, 1); }
		"LMWX" A 8 Bright { A_Warp(AAPTR_TARGET, -80, 0, 0, random(0, 360), WARPF_NOCHECKPOSITION); }
		"LMWX" A 0
		{
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
		"LMWX" A 1 Bright { A_SetTranslucent(0.25, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.5, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.75, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(1, 1); }
		"LMWX" A 0 { A_SpawnItemEx("RS_OldTimeyMOT", 0, 0, 16, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"LMWX" A 0 { A_StartSound("TIME02"); }
		"LMWX" A 5 Bright { A_FaceTarget(); }
		"LMWX" A 0 { A_StartSound("PUZSLV"); }
		"LMWX" AAAA 12 Bright { A_SpawnProjectile("RS_TimeShockMOT", 42, 0, random(-10, 10)); }
		"LMWX" A 10 Bright { A_FaceTarget(); }
		TNT1 A 0 { return RS_FreezeReadyMOT(); }
		"LMWX" E 2 { rsCourageMOT -= 15; }
		"LMWX" E 0 A_Jump(32, "Missile.T14.Steal");
		Goto Missile.T14.Bolts;
	// Cashing in. Every four tokens buys one real TimeFreezer tick.
	Missile.T14.Freeze:
		"LMWX" A 0 { A_GiveInventory("RS_TimeSlowMOT", 1); }
		"LMWX" A 0 { A_TakeInventory("RS_MOTFreezeToken", 4, 0, AAPTR_TARGET); }
		TNT1 A 0 { return RS_FreezeReadyMOT(); }
		"LMWX" A 0 { A_StartSound("TIME02"); }
		"LMWX" A 0 A_Jump(128, "Missile.T14.Bolts");
		"LMWX" E 2 { rsCourageMOT -= 15; }
		Goto See.T14.Clippy;
	Missile.T14.Rail:
		"LMWX" A 20 Bright { A_StartSound("WVEXACTV", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" EFG 10 Bright { A_FaceTarget(); }
		"LMWX" H 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"LMWX" H 15 Bright
		{
			A_CustomRailgun(random(40, 90), 0, 0, 0,
			                RGF_NOPIERCING | RGF_SILENT, 1, 0,
			                "RS_WhiteFatRB", 0, 0, 0, 0, 0.4, 1.0,
			                "RS_WhiteFatRB4", 10);
		}
		"LMWX" G 15 Bright { A_FaceTarget(); }
		"LMWX" H 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"LMWX" H 15 Bright
		{
			A_CustomRailgun(random(40, 90), 0, 0, 0,
			                RGF_NOPIERCING | RGF_SILENT, 1, 0,
			                "RS_WhiteFatRB", 0, 0, 0, 0, 0.4, 1.0,
			                "RS_WhiteFatRB4", 10);
		}
		"LMWX" G 15 Bright { A_FaceTarget(); }
		"LMWX" E 0 { A_SpawnItemEx("RS_WVileSpot", random(-128, 128), random(-128, 128), 1, 0, 0, 0, 0, SXF_TRANSFERPOINTERS | SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" E 0 A_Jump(128, "Missile.T14.Choices");
		"LMWX" E 2 { rsCourageMOT -= 15; }
		Goto See.T14.Clippy;
	// Plants eight eyes in a fan and remembers it did. They do NOT fire
	// yet -- the next missile detonates the whole set at once.
	Missile.T14.Eye:
		"LMWX" E 1 { A_StartSound("Forgotten/active"); }
		"LMWX" EFG 8 { A_FaceTarget(); }
		"LMWX" AAAA 0 { A_SpawnItemEx("RS_BrightUpVile2", random(-328, 328), random(-328, 328), random(1, 12), 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 78, 0); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 78, 24); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 78, -24); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 64, 12); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 64, -12); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 48, 0); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 48, 24); }
		"LMWX" A 0 { A_SpawnProjectile("RS_WVileEye", 48, -24); }
		"LMWX" A 0 { rsHohoMOT++; }
		"LMWX" HG 10;
		"LMWX" AAAA 0 { A_SpawnItemEx("RS_BrightUpVile2", random(-328, 328), random(-328, 328), random(1, 12), 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		"LMWX" E 2;
		Goto See.T14.Clippy;
	Missile.T14.EyeBoom:
		"LMWX" G 5 Bright { A_FaceTarget(); }
		"LMWX" A 0 { A_RadiusGive("RS_WVEyeGo", 320, RGF_MISSILES, 10); }
		"LMWX" E 0 { rsCourageMOT -= 10; rsHohoMOT--; }
		"LMWX" E 0 { A_SpawnItemEx("RS_WVileSpot", random(-128, 128), random(-128, 128), 1, 0, 0, 0, 0, SXF_TRANSFERPOINTERS | SXF_NOCHECKPOSITION | SXF_SETMASTER); }
		Goto Missile.T14.Choices;
	// Only below 12500. CHP finishes this with an ACS script that strips
	// the player's armour and slows them; the ACS is stripped, so the
	// two things it actually DID are done here directly.
	Missile.T14.Steal:
		"LMWX" A 0 A_JumpIfHealthLower(12500, "Missile.T14.Steal.Do");
		Goto Missile.T14.Choices;
	Missile.T14.Steal.Do:
		"LMWX" A 0 { A_StartSound("TIME02", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" QQQQRSTU 10 Bright { A_VileTarget("RS_TIMESTEALMOT"); }
		"LMWX" U 0 A_CheckSight("See.T14.Clippy");
		"LMWX" U 40 Bright
		{
			A_StartSound("WVEXTAKE", CHAN_AUTO, 0, 1.0, ATTN_NONE);
			if (target)
			{
				target.A_GiveInventory("RS_WVileEXSpeedNerf", 1);
				target.A_TakeInventory("Armor", 0);
				target.DamageMobj(self, self, 20, "Normal");
			}
		}
		"LMWX" E 0 A_Jump(128, "Missile.T14.Choices");
		"LMWX" E 2 { rsCourageMOT -= 15; }
		Goto See.T14.Clippy;
	// Only below 12500, and only half the time. Lobs a bouncing seed
	// that stands up a 500 HP copy of the boss where it lands.
	Missile.T14.Clone:
		"LMWX" A 0 A_Jump(128, "Missile.T14.Clone.Do");
		Goto Missile.T14.Choices;
	Missile.T14.Clone.Do:
		"LMWX" A 0 A_JumpIfHealthLower(12500, "Missile.T14.Clone.Throw");
		Goto Missile.T14.Choices;
	Missile.T14.Clone.Throw:
		"LMWX" EFG 8 Bright { A_FaceTarget(); }
		"LMWX" G 0 { A_SpawnProjectile("RS_CloneSummonMOT", 42, 0, random(0, 360), 2, 12); }
		"LMWX" HG 10;
		"LMWX" E 2 { rsCourageMOT -= 15; }
		Goto See.T14.Clippy;
	Missile.T14.ShouldI:
		"LMWX" A 0 { if (rsEndOfTimeMOT > 0) return ResolveState("Missile.T14.Pick"); return ResolveState(null); }
		"LMWX" A 0 A_Jump(16, "Missile.T14.EndOfTime");
		Goto Missile.T14.Pick;
	// THE COUNTDOWN. Fires once. 10500 tics = 300 seconds.
	Missile.T14.EndOfTime:
		"LMWX" A 0
		{
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SetTranslucent(1, 1);
			bNOPAIN = true;
			A_GiveInventory("RS_WVileResist", 1);
			A_StartSound("WVEXSIGT", CHAN_AUTO, 0, 1.0, ATTN_NONE);
		}
		"LMWX" AAAA 0 { A_SpawnItemEx("RS_OldTimeyMOT", 0, 0, 16, frandom(-2, 2), frandom(-2, 2), frandom(0, 4), 0, SXF_NOCHECKPOSITION); }
		"LMWX" AA 10 Bright { A_VileTarget("RS_TIMESTEALMOT"); }
		"LMWX" A 0 { A_QuakeEx(180, 180, 180, 180, 0, 57600, ""); }
		"LMWX" AAA 10 Bright { A_VileTarget("RS_TIMESTEALMOT"); }
		"LMWX" A 0 { A_StartSound("Wvile/scream", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" QRSTUQRSTUQRSTU 4 Bright { A_VileTarget("RS_TIMESTEALMOT"); }
		"LMWX" U 40 Bright
		{
			// CHP: ACS "WVileEXTimer2_C" -> Delay(10500) -> invulnerable
			// + TIMESUPMOT. The HUD countdown half of that ACS is an
			// announcer and is stripped; the deadline is real.
			rsEndOfTimeMOT = 1;
			rsTimesUpTic = level.time + 10500;
		}
		"LMWX" E 2 { rsCourageMOT -= 150; bNOPAIN = false; }
		Goto Missile.T14.Clone;
	// Time is up. It cannot be hurt any more; it freezes you, warps onto
	// you, and does not stop until you are a corpse.
	Missile.T14.TimesUp:
		"LMWX" A 0
		{
			bINVULNERABLE = true;
			A_GiveInventory("RS_TimeSlowMOT2", 1);
			bNOPAIN = true;
			bVISIBILITYPULSE = false;
			if (target)
			{
				target.A_GiveInventory("RS_TimeSlowMOT3", 1);
				target.vel = (0, 0, 0);
			}
			A_StartSound("Forgotten/Attack", CHAN_AUTO, 0, 1.0, ATTN_NONE);
		}
		"LMWX" A 1 Bright { A_SetTranslucent(0.75, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.5, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.25, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.25, 1); }
		"LMWX" A 10 Bright { A_SetTranslucent(0.01, 1); }
		"LMWX" A 10 Bright { A_Warp(AAPTR_TARGET, -80, 0, 0, random(0, 360), WARPF_NOCHECKPOSITION); }
		"LMWX" A 0
		{
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
		"LMWX" A 1 Bright { A_SetTranslucent(0.25, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.5, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(0.75, 1); }
		"LMWX" A 1 Bright { A_SetTranslucent(1, 1); }
		"LMWX" A 0 { A_SpawnItemEx("RS_OldTimeyMOT", 0, 0, 16, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"LMWX" A 0 { A_StartSound("TIME02"); }
		"LMWX" A 5 Bright { A_FaceTarget(); }
		"LMWX" A 0 { A_StartSound("PUZSLV"); }
	Missile.T14.TimesUp2:
		"LMWX" AAAA 2 Bright { A_SpawnProjectile("RS_TimeShockMOT", 42, 0, random(-10, 10)); }
		"LMWX" A 0
		{
			A_GiveInventory("RS_TimeSlowMOT2", 1);
			if (target)
				target.A_GiveInventory("RS_TimeSlowMOT3", 1);
		}
		"LMWX" A 0 { if (!target || target.health <= 0) return ResolveState("Spawn.T14.Idle"); return ResolveState(null); }
		Loop;
	// CHP's TEX/T14 never resurrects by hand -- its fields do it.
	Heal.T14:
		"LMWX" E 0 { A_SpawnItemEx("RS_WhiteVileResser"); }
		"LMWX" EF 6 Bright;
		Goto See.T14.Clippy;
	Pain.T14:
		"LMWX" A 0
		{
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
		"LMWX" I 3 { A_SetTranslucent(1, 1); }
		"LMWX" E 0 { rsCourageMOT += 5; }
		"LMWX" I 5 { A_Pain(); }
		Goto Pain.T14.Whatthe;
	Pain.T14.Whatthe:
		"LMWX" F 1 { bVISIBILITYPULSE = false; }
		"LMWX" F 1 { A_SetTranslucent(0.66, 1); }
		"LMWX" F 1 { A_SetTranslucent(0.33, 1); }
		"LMWX" F 1 { A_SetTranslucent(0.01, 1); }
		"LMWX" EEEEEEEEEEEEEEEEEEEEEEEEEE 2 { A_Wander(); }
		"LMWX" A 0
		{
			bVISIBILITYPULSE = true;
			A_SpawnItemEx("RS_FaceMOT", 4, 4, 84, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
			A_SpawnItemEx("RS_EffectMOT", 4, 4, 80, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_SETMASTER);
		}
		"LMWX" F 1 { A_SetTranslucent(0.5, 1); }
		"LMWX" F 1 { A_SetTranslucent(1, 1); }
		"LMWX" E 0 { rsCourageMOT -= 15; }
		"LMWX" F 4 { A_Stop(); }
		Goto See.T14.Clippy;
	Death.T14:
		TNT1 A 0 { bVISIBILITYPULSE = false; }
		"LMWX" A 0 { A_SetTranslucent(1, 1); }
		"LMWX" A 0 { A_QuakeEx(180, 180, 180, 250, 0, 57600, ""); }
		"LMWX" I 0 { A_StartSound("WVEXDSCR", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"LMWX" I 0 { bNOGRAVITY = true; }
		// CHP: ThrustThingZ(0, 10, 0, 0) -- its zthrust unit is 1/4 of a
		// map unit per tic, so 10 is 2.5.
		"LMWX" I 12 Bright { vel.z += 2.5; }
		"LMWX" I 0 { vel = (0, 0, 0); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" I 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" II 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" II 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" II 5 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" II 0 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" I 1 Bright { A_SetAngle(frandom(0, 360)); }
		"LMWX" III 3 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" I 0 { A_SetAngle(frandom(0, 360)); }
		"LMWX" IIIII 2 { A_SpawnProjectile("RS_HKRedDeath", random(20, 80), random(-20, 20), random(0, 360), CMF_AIMOFFSET, -10); }
		"LMWX" I 0 { bNOGRAVITY = false; }
		"LMWX" J 6 { A_Scream(); }
		TNT1 A 0 { A_KillChildren("Extreme", KILS_FOILINVUL | KILS_KILLMISSILES); }
		"LMWX" K 6 { A_NoBlocking(); }
		"LMWX" LMNO 6;
		"LMWX" P -1;
		Stop;
	}

	// The 300-second deadline. Called from every walk loop where CHP
	// tests its TIMESUPMOT latch and drops into its TIMESUP state.
	private State RS_TimesUpMOT()
	{
		if (rsTimesUpTic > 0 && level.time >= rsTimesUpTic)
			return ResolveState("Missile.T14.TimesUp");
		return ResolveState(null);
	}

	// Four freeze tokens on the player is what buys one real
	// TimeFreezer tick. Read off the target rather than through
	// A_JumpIfInTargetInventory so the label stays a label.
	private State RS_FreezeReadyMOT()
	{
		if (target && target.CountInv("RS_MOTFreezeToken") >= 4)
			return ResolveState("Missile.T14.Freeze");
		return ResolveState(null);
	}
}
