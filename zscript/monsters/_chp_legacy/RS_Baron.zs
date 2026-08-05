// =====================================================================
// RS_Baron -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\15\15_<code>.txt
// One CHP file per colour; the FIRST ACTOR in each file is that tier's
// creature. Each is a genuinely different monster with its OWN sprite
// set, stats and attack. Nothing here is inferred, tinted or shared --
// every tier below was read out of its CHP file. Where CHP inherits a
// state rather than defining it, the CH parent named on the ACTOR line
// (CH\decorate\Barons.txt) supplied it.
//
//   tier  CHP    actor / CH parent               body   HP     what it is
//   T00   15_C   CommonCommonBaron :CommonBaron  BOSS    1000  vanilla + follow-up
//   T01   15_G   CommonGreenBaron  :GreenBaron   BOSG    1170  spit / close spit / puke
//   T02   15_B   CommonBlueBaron   :BlueBaron    BOSB    1309  smash balls or a comet
//   T03   15_CY  CommonCyanBaron   :CyanBaron2   BOSC    1666  frost-winged dodger
//   T04   15_P   CommonPurpleBaron :PurpleBaron  BOS3    1500  Royal: waves + spear
//   T05   15_Y   CommonYellowBaron :YellowBaron  LOHS    1888  Grand Gold: stars/fire
//   T06   15_A   CommonAbyssBaron  :AbyssBaron2  AZEW    3333  Abyssal: hands + souls
//   T07   15_F   CommonFirebluBaron:FirebluBaron2 BSF2   1800  three-combo bruiser
//   T08   15_BR  CommonBrownBaron  :BrownBaron2  STYR    2250  Brown Baron Jam
//   T09   15_GY  CommonGrayBaron   :GrayBaron2   BSGR    2400  stone thrower
//   T10   15_R   CommonRedBaron3   :RedBaron3    BOS4    3200  Power Baron -> Fallen
//   T11   15_K   CommonBlackBaron2 :BlackBaron2  CUTH    8907  deep one + tentacles
//   T12   15_W   CommonWhiteBaron2 :WhiteBaron2  VSTL   13070  Hell's Slice and Dicer
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
//
// RS mechanics preserved from the previous file, all of them:
//   * RS_SummonPack -- the mixed tendril pack (rusher + caster). CHP's
//     black baron (15_K) summons exactly these two tentacle types, so
//     the T11 cluster drives RS_SummonPack directly instead of
//     spawning loose actors, and the cap/tier-offset economy holds;
//   * a permanent one-shot Enrage at half health, rolled in the Pain
//     DISPATCHER so every tier cluster gets it -- CHP has its own
//     half-health rage on T10/T12, which now routes through it;
//   * DeathMorphClass -> RS_BaronFallen at T10+, which is exactly what
//     CHP's 15_R does when CommonRedBaron3 dies into CommonRedBaron2;
//   * MinionsDieWithMe, GetBaseKeywords, TintTable, BuildTierAttacks.
//
// CHP cruft stripped per docs/rs_09_monster_rebuild_spec.txt: NewIcon*
// trackers, A_GivetoChildren, the CHWhitePlan "Tickles" gore branch,
// CHRandom_GibGenerator, ACS_NamedExecute* / CallACS, A_SetUserVar
// (replaced by the private int fields below), RandomLetterSpawner and
// A_SpawnParticle walls. Bracket sprite frames (BSF2 / BSGR / BOS4 "[")
// are dropped -- bracket tokens broke the parse in this project once
// already, and each one is a single tail frame of a death animation.
// =====================================================================

class RS_Baron : RS_MonsterLadder replaces BaronOfHell
{
	const RS_BARON_ENRAGE_SLOT = 0;

	const RS_BARON_TIER_RING   = 5;
	const RS_BARON_TIER_PACK   = 7;
	const RS_BARON_TIER_FALLEN = 10;

	// CHP user vars, rebuilt as real fields.
	private int rsBuildUp;    // 15_R  User_BuildUP
	private int rsRageUp;     // 15_R  User_RageUP / 15_K User_uhoh
	private int rsRude;       // 15_W  user_rude
	private int rsSpinCount;  // 15_W  the UltimateSpin inventory counter

	Default
	{
		Health 1000;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 50;
		Monster;
		+FLOORCLIP +BOSSDEATH
		SeeSound "baron/sight";   PainSound "baron/pain";
		DeathSound "baron/death"; ActiveSound "baron/active";
		Obituary "$OB_BARON";
		HitObituary "$OB_BARONHIT";
		Tag "Baron of Hell";
	}

	// CHP's real per-colour numbers, read from 15_*.txt, expressed as
	// multipliers off the Default (1000 HP, speed 8) so the base class's
	// recompute-from-defaults contract still holds.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 50; r.dmgMul = 1.0;
		int hp = 1000; int spd = 8;
		switch (t)
		{
			case 0:  hp = 1000;  spd = 8;  r.painChance = 50; r.dmgMul = 1.0; break;
			case 1:  hp = 1170;  spd = 9;  r.painChance = 40; r.dmgMul = 1.1; break;
			case 2:  hp = 1309;  spd = 11; r.painChance = 30; r.dmgMul = 1.2; break;
			case 3:  hp = 1666;  spd = 18; r.painChance = 64; r.dmgMul = 1.3; break;
			case 4:  hp = 1500;  spd = 11; r.painChance = 30; r.dmgMul = 1.4; break;
			case 5:  hp = 1888;  spd = 15; r.painChance = 20; r.dmgMul = 1.5; break;
			case 6:  hp = 3333;  spd = 14; r.painChance = 24; r.dmgMul = 1.8; break;
			case 7:  hp = 1800;  spd = 20; r.painChance = 32; r.dmgMul = 1.6; break;
			case 8:  hp = 2250;  spd = 28; r.painChance = 20; r.dmgMul = 1.7; break;
			case 9:  hp = 2400;  spd = 8;  r.painChance = 6;  r.dmgMul = 1.8; break;
			case 10: hp = 3200;  spd = 10; r.painChance = 20; r.dmgMul = 2.0; break;
			case 11: hp = 8907;  spd = 13; r.painChance = 42; r.dmgMul = 2.5; break;
			case 12: hp = 13070; spd = 16; r.painChance = 18; r.dmgMul = 3.0; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 1000.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BOSS BOSG BOSB BOSC BOS3 LOHS AZEW BSF2 STYR BSGR BOS4 CUTH VSTL";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:baron role:bruiser delivery:heavy delivery:melee element:thermal mobility:ground";
	}

	// The tendrils are part of the Baron, not independent monsters --
	// they go when it goes. Opposite call to the Pain Elemental's
	// escort, deliberately: these exist to pressure you DURING the
	// Baron fight, and leaving them behind would just pad it.
	override bool MinionsDieWithMe()
	{
		return true;
	}

	// CHP 15_R: CommonRedBaron3's death spawns CommonRedBaron2, the
	// flying second stage. That is this chain, kept intact.
	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_BARON_TIER_FALLEN) ? RS_MonsterCatalog.MORPH_BaronFallen() : null;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_BARON_TIER_RING)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));

		// Two aimed shots then a ring. The ring is the beat that makes
		// standing still lethal; the aimed shots are what punish you for
		// running in a straight line away from it.
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 1, 0.0,
			"baron/attack", 1.0, 0.0, "Star"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 3, 30.0,
			"baron/attack", 1.0, 0.0, "Star Fan"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronRing(),
			t >= 11 ? 24 : 14, 360.0,
			"baron/attack", 1.0, 4.0, "Hell Ring"));

		// The enrage unlock. Present in the table only once the gate has
		// actually fired, so the Baron cannot roll it early.
		if (ThresholdFired(RS_BARON_ENRAGE_SLOT))
		{
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_BaronBomb(), 1, 0.0,
				"baron/attack", 1.4, 0.0, "Hellbomb"));
		}

		return slot;
	}

	// Mixed pack: rushers plus one caster. The caster is what stops the
	// pack being solvable by standing on a ledge. CHP's black baron
	// summons CommonRoseTentacle and CommonDeepTentacle -- these two,
	// exactly -- so T11 calls straight into this.
	void RS_SummonPack()
	{
		if (Tier < RS_BARON_TIER_PACK)
			return;

		int cap = (Tier >= 11) ? 6 : 4;
		if (CountLiveMinions() >= cap)
			return;

		int n = SummonPack(RS_MonsterCatalog.MINION_BaronRusher(), 2, cap, -3, 96.0);
		if (Tier >= 9)
			n += SummonPack(RS_MonsterCatalog.MINION_BaronRanger(), 1, cap, -3, 120.0);

		if (n > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	// ===== dispatcher override: the family-wide enrage rolls here =====
	Pain:
		TNT1 A 0
		{
			if (CheckThreshold(RS_BARON_ENRAGE_SLOT, 0.5))
			{
				Enrage(1.3);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
				// Rebuild the rotation so the unlocked attack is
				// actually reachable from here on.
				BuildAttacksForTier(-1);
				BuildAttacksForTier(Tier);
				// It arrives angry, not just stronger.
				RS_SummonPack();
			}
			return TierState("Pain");
		}
		Goto See;

	// The RS pack beat, reachable from any tier that has earned it.
	SummonPack:
		"BOSS" E 10 { A_FaceTarget(); }
		"BOSS" F 12 Bright { RS_SummonPack(); }
		"BOSS" G 8;
		Goto See;

	// =================================================================
	// T00 COMMON (15_C -- CommonCommonBaron : CommonBaron). BOSS.
	// Vanilla combo, then a second swing at it before it lets go.
	// CHP's follow-up was an ACS-dispatched missile with an intercept
	// check; the ACS is stripped and its own Miss2 fallback -- the same
	// combo again -- carries the beat.
	// =================================================================
	Spawn.T00:
		"BOSS" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"BOSS" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T00:
	Missile.T00:
		"BOSS" EF 8 { A_FaceTarget(); }
		"BOSS" G 8 { A_CustomComboAttack("RS_BaronBall", 32, 10 * random(1, 8), "baron/melee"); }
		"BOSS" PQ 8 { A_FaceTarget(); }
		// RESTORED (rs_19 / L5). CHP 15_C.txt:29-31 is:
		//   BOSS Q 0 A_JumpIf(CallACS("CH_Intercept") == true,"Miss2")
		//   BOSS R 8 ACS_NamedExecuteWithResult("BaronMissile_C",1)
		// BaronMissile is a ProjInt_Brute call -- a LED shot, solved at
		// the target's velocity. The import dropped the branch and left a
		// bare `Goto Miss2`, so the Baron has only ever fired the dumb
		// fallback. FireLeadShot returns false when the option is off,
		// which falls through to Miss2 exactly as CH's jump does.
		"BOSS" R 8
		{
			if (!FireLeadShot("RS_BaronBall", 32.0, 16.0))
				return ResolveState("Missile.T00.Miss2");
			return ResolveState(null);
		}
		"BOSS" R 0 A_Jump(75, "Missile.T00");
		Goto See;
	Missile.T00.Miss2:
		"BOSS" R 8 { A_CustomComboAttack("RS_BaronBall", 32, 10 * random(1, 8), "baron/melee"); }
		"BOSS" R 0 A_Jump(75, "Missile.T00");
		Goto See;
	Pain.T00:
		"BOSS" H 2;
		"BOSS" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
		"BOSS" I 8;
		"BOSS" J 8 { A_Scream(); }
		"BOSS" K 8;
		"BOSS" L 8 { A_NoBlocking(); }
		"BOSS" MN 8;
		"BOSS" O -1 { A_BossDeath(); }
		Stop;
	XDeath.T00:
		"BOSS" I 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); A_Stop(); }
		"BOSS" I 8;
		"HKGB" B 0 { A_NoBlocking(); }
		"HKGB" B -1 { A_XScream(); }
		Stop;
	Raise.T00:
		"BOSS" O 5;
		"BOSS" NMLKJI 5;
		Goto See;

	// =================================================================
	// T01 GREEN (15_G -- CommonGreenBaron : GreenBaron). BOSG.
	// Spits at range, a heavier spit up close, and a point-blank puke
	// of greenies when you are below it.
	// =================================================================
	Spawn.T01:
		"BOSG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"BOSG" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T01:
		"BOSG" EF 8 { A_FaceTarget(); }
		"BOSG" G 8 { A_CustomMeleeAttack(random(10, 65), "baron/melee"); }
		Goto See;
	Missile.T01:
		"BOSG" E 0 A_JumpIfCloser(500, "Missile.T01.Spit", true);
		"BOSG" EF 8 { A_FaceTarget(); }
		"BOSG" G 8 { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-1, 1)); }
		"BOSG" PQ 6 { A_FaceTarget(); }
		"BOSG" R 6 { A_SpawnProjectile("RS_Spspit2", 32, 5, random(-1, 1)); }
		Goto See;
	Missile.T01.Spit:
		TNT1 A 0 A_JumpIfHigherOrLower(null, "Missile.T01.Puke", 0, -32);
		"BOSG" HEF 5 { A_FaceTarget(); }
		"BOSG" G 8 { A_SpawnProjectile("RS_Spspit3", 32, 0, random(-1, 1)); }
		"BOSG" HPQ 4 { A_FaceTarget(); }
		"BOSG" R 6 { A_SpawnProjectile("RS_Spspit3", 32, 0, random(-1, 1)); }
		Goto See;
	Missile.T01.Puke:
		"BOSG" H 5 Bright { A_FaceTarget(); }
		"BOSG" H 2 Bright { A_SpawnProjectile("RS_GreeniesBR", 56, 0, random(-6, 6)); }
		"BOSG" H 0 { A_SpawnProjectile("RS_GreeniesBR", 56, 0, random(-6, 6)); }
		"BOSG" H 2 Bright { A_SpawnProjectile("RS_GreeniesBR", 56, 0, random(-13, 13)); }
		"BOSG" H 0 { A_SpawnProjectile("RS_GreeniesBR", 56, 0, random(-6, 6)); }
		"BOSG" H 2 Bright { A_SpawnProjectile("RS_GreeniesBR", 56, 0, random(-14, 14)); }
		"BOSG" H 0 { A_SpawnProjectile("RS_GreeniesBR", 56, 0, random(-6, 6)); }
		"BOSG" H 0 A_CheckSight("See");
		Goto Missile.T01;
	Pain.T01:
		"BOSG" H 2;
		"BOSG" H 2 { A_Pain(); }
		Goto See;
	Death.T01:
		"BOSG" I 8;
		"BOSG" J 8 { A_Scream(); }
		"BOSG" K 8;
		"BOSG" L 8 { A_NoBlocking(); }
		"BOSG" MN 8;
		"BOSG" O -1 { A_BossDeath(); }
		Stop;
	XDeath.T01:
		"BOSG" I 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"BOSG" I 8 { A_Stop(); }
		"HKG2" B 0 { A_NoBlocking(); }
		"HKG2" B -1 { A_XScream(); }
		Stop;
	Raise.T01:
		"BOSG" O 5;
		"BOSG" NMLKJI 5;
		Goto See;

	// =================================================================
	// T02 BLUE (15_B -- CommonBlueBaron : BlueBaron). BOSB.
	// Based: a twin smash-ball spread in the open, a single tracking
	// comet if you are above it or far away.
	// =================================================================
	Spawn.T02:
		"BOSB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"BOSB" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T02:
	Missile.T02:
		"BOSB" EF 12 { A_FaceTarget(); }
		"BOSB" G 2 Bright;
		"BOSB" G 0 A_JumpIfHigherOrLower("Missile.T02.Cometto", null, 28, 0, true);
		"BOSB" G 0 A_JumpIfCloser(1000, "Missile.T02.Atk1", true);
		"BOSB" G 0 A_Jump(256, "Missile.T02.Cometto");
		Goto See;
	Missile.T02.Atk1:
		"BOSB" G 0 { A_SpawnProjectile("RS_SmashBalls2", 32, 5, random(-5, 5)); }
		"BOSB" G 6 { A_SpawnProjectile("RS_SmashBalls2", 32, 5, randompick(random(-15, -5), random(5, 15), random(-21, -15), random(15, 21))); }
		Goto See;
	Missile.T02.Cometto:
		"BOSB" G 6 { A_SpawnProjectile("RS_SmashBall4", 32, 5, random(-1, 1)); }
		Goto See;
	Pain.T02:
		"BOSB" H 2;
		"BOSB" H 2 { A_Pain(); }
		Goto See;
	Death.T02:
		"BOSB" I 8;
		"BOSB" J 8 { A_Scream(); }
		"BOSB" K 8;
		"BOSB" L 8 { A_NoBlocking(); }
		"BOSB" MN 8;
		"BOSB" O -1 { A_BossDeath(); }
		Stop;
	XDeath.T02:
		"BOSB" I 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); A_Stop(); }
		"BOSB" I 8;
		"HKG3" B 0 { A_NoBlocking(); }
		"HKG3" B -1 { A_XScream(); }
		Stop;
	Raise.T02:
		"BOSB" O 5;
		"BOSB" NMLKJI 5;
		Goto See;

	// =================================================================
	// T03 CYAN (15_CY -- CommonCyanBaron : CyanBaron2). BOSC.
	// Cyanide-bitten: it trails frost wings from eight points on its
	// body every step, sidesteps and back-dashes constantly, and picks
	// between a two-beat star volley, a heavy bomb, and a twelve-shot
	// seeker fan off the wings.
	// =================================================================
	Spawn.T03:
		"BOSC" AB 10 { A_Look(); }
		Loop;
	See.T03:
		TNT1 A 0 { RS_CyanWings(2.0); }
		"BOSC" AABB 2 { A_Chase(); }
		TNT1 A 0 { RS_CyanWings(2.0); }
		"BOSC" CCDD 2 { A_Chase(); }
		"BOSC" A 0 A_Jump(92, "See.T03.Dodger");
		"BOSC" A 0 A_Jump(32, "See.T03.DashBack");
		Loop;
	See.T03.Dodger:
		TNT1 A 0 { RS_CyanWings(2.0); }
		"BOSC" AABB 2 { A_FastChase(); }
		"BOSC" A 0 A_Jump(64, "See");
		TNT1 A 0 { RS_CyanWings(2.0); }
		"BOSC" CCDD 2 { A_FastChase(); }
		"BOSC" A 0 A_Jump(128, "See");
		"BOSC" A 0 A_Jump(64, "See.T03.DashBack");
		Loop;
	See.T03.DashBack:
		"BOSC" G 3 { A_ChangeVelocity(0, 0, 9, CVF_REPLACE); }
		"BOSC" A 0 A_Jump(102, "See.T03.Bon");
		"BOSC" G 3 { A_ChangeVelocity(-18, 0, 0, CVF_RELATIVE); }
		Goto See;
	See.T03.Bon:
		"BOSC" G 3 { A_ChangeVelocity(11, 0, 0, CVF_RELATIVE); }
		Goto See;
	Melee.T03:
		"BOSC" E 8 { A_FaceTarget(); }
		TNT1 A 0 { RS_CyanWings(6.0); }
		"BOSC" F 8 { A_FaceTarget(); }
		"BOSC" G 8 { A_CustomMeleeAttack(random(10, 90), "baron/melee"); }
		"BOSC" A 0 A_Jump(76, "See.T03.DashBack");
		Goto Missile.T03;
	Missile.T03:
		"BOSC" A 0 A_JumpIfCloser(1200, "Missile.T03.CheckAgain");
		"BOSC" A 0 A_Jump(212, "Missile.T03.WingBlast");
		"BOSC" A 0 A_Jump(128, "Missile.T03.BigBlast");
		Goto Missile.T03.Stars;
	Missile.T03.Stars:
		"BOSC" E 8 { A_FaceTarget(); }
		TNT1 A 0 { RS_CyanWings(6.0); }
		"BOSC" F 8 { A_FaceTarget(); }
		"BOSC" G 5 { A_SpawnProjectile("RS_BaronStarCyan", 42, 0); }
		"BOSC" E 0 A_CheckSight("See");
		"BOSC" E 0 A_Jump(64, "Missile.T03");
		Goto Missile.T03.Stars2;
	Missile.T03.Stars2:
		"BOSC" P 8 { A_FaceTarget(); }
		TNT1 A 0 { RS_CyanWings(6.0); }
		"BOSC" Q 8 { A_FaceTarget(); }
		"BOSC" R 5 { A_SpawnProjectile("RS_BaronStarCyan", 42, 0); }
		"BOSC" E 0 A_CheckSight("See");
		"BOSC" E 0 A_Jump(64, "Missile.T03");
		Goto Missile.T03.Stars;
	Missile.T03.CheckAgain:
		"BOSC" A 0 A_Jump(128, "Missile.T03.Stars", "Missile.T03.BigBlast");
		"BOSC" A 0 A_Jump(256, "Missile.T03.Stars", "Missile.T03.BigBlast", "Missile.T03.WingBlast");
		Goto See;
	Missile.T03.BigBlast:
		TNT1 A 0 { RS_CyanWings(6.0); RS_CyanWings(6.0); }
		"BOSC" EF 8 { A_FaceTarget(); }
		"BOSC" G 5 { A_SpawnProjectile("RS_BaronCyanBomb", 42, 0); }
		"BOSC" G 12;
		Goto Missile.T03.WingBlast;
	Missile.T03.WingBlast:
		"BOSC" H 2 { A_FaceTarget(); }
		TNT1 A 0 { RS_CyanWings2(); }
		"BOSC" HH 13 { A_FaceTarget(); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 74, 15, -9); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 74, -15, 9); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 82, -25, -6); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 82, 25, 6); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 76, -19, 5); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 76, 19, -5); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 92, 12, -7); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 92, 12, 7); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 74, -29, 9); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 74, 29, -9); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 64, -32, -14); }
		"BOSC" H 1 { A_SpawnProjectile("RS_IceSeekerBaron", 64, 32, 14); }
		"BOSC" H 8 { A_FaceTarget(); }
		Goto See;
	Pain.T03:
		"BOSC" H 2;
		TNT1 A 0 { RS_CyanWings(-6.0); }
		"BOSC" H 2 { A_Pain(); }
		"BOSC" H 2 A_Jump(128, "See.T03.Dodger");
		Goto See;
	Death.T03:
		"BOSC" I 8;
		"BOSC" J 8 { A_Scream(); }
		"BOSC" K 8;
		"BOSC" L 8 { A_NoBlocking(); }
		"BOSC" MN 8;
		"BOSC" O 10 { A_BossDeath(); }
		// CHP shattered it into IceChunk and dropped a joke pickup; the
		// engine's own shatter is the same read without either.
		"BOSC" O 1 { A_StartSound("misc/icebreak", CHAN_BODY); A_IceGuyDie(); }
		Stop;
	Raise.T03:
		"BOSC" O 5;
		"BOSC" NMLKJI 5;
		Goto See;

	// =================================================================
	// T04 PURPLE (15_P -- CommonPurpleBaron : PurpleBaron). BOS3.
	// The Royal Baron: seven-wide ground waves up close, a lightning
	// spear at range, and below 900 HP it stops choosing and rolls both.
	// =================================================================
	Spawn.T04:
		"BOS3" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"BOS3" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T04:
	Missile.T04:
		"BOS3" E 8 { A_FaceTarget(); }
		"BOS3" E 0 A_JumpIfHealthLower(900, "Missile.T04.Both");
		"BOS3" E 0 A_JumpIfCloser(800, "Missile.T04.Wave1");
		"BOS3" E 0 A_Jump(256, "Missile.T04.Spear");
		Goto See;
	Missile.T04.Both:
		"BOS3" E 0 A_Jump(256, "Missile.T04.Spear", "Missile.T04.Wave1");
		Goto See;
	Missile.T04.Wave1:
		"BOS3" F 6 Bright;
		"BOS3" G 5 Bright;
		"BOS3" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 1); }
		"BOS3" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 3); }
		"BOS3" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -3); }
		"BOS3" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 6); }
		"BOS3" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -6); }
		"BOS3" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 9); }
		"BOS3" G 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -9); }
		"BOS3" G 0 A_Jump(100, "Missile.T04.Wave2");
		Goto See;
	Missile.T04.Wave2:
		"BOS3" ST 8 { A_FaceTarget(); }
		"BOS3" U 8 Bright;
		"BOS3" U 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 1); }
		"BOS3" U 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 3); }
		"BOS3" U 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -3); }
		"BOS3" U 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 6); }
		"BOS3" U 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -6); }
		"BOS3" U 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, 9); }
		"BOS3" U 0 { A_SpawnProjectile("RS_BaronWave", 32, 5, -9); }
		Goto See;
	Missile.T04.Spear:
		"BOS3" E 0 { A_StartSound("spell/spellcast1", CHAN_WEAPON); }
		"BOS3" E 12 Bright { A_SpawnProjectile("RS_Zap88", 48, 8); }
		"BOS3" G 5 Bright { A_SpawnProjectile("RS_Spear11", 38, 5); }
		"BOS3" ST 5;
		"BOS3" U 5 Bright { A_SpawnProjectile("RS_Spear11", 38, -5); }
		"BOS3" U 0 A_Jump(115, "Missile.T04");
		Goto See;
	Pain.T04:
		"BOS3" H 2;
		"BOS3" H 2 { A_Pain(); }
		Goto See;
	Death.T04:
		"BOS3" I 8;
		"BOS3" J 8 { A_Scream(); }
		"BOS3" K 8;
		"BOS3" L 8 { A_NoBlocking(); }
		"BOS3" MN 8;
		"BOS3" O -1 { A_BossDeath(); }
		Stop;
	XDeath.T04:
		"BOS3" I 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); A_Stop(); }
		"BOS3" I 8;
		"HKG4" B 0 { A_NoBlocking(); }
		"HKG4" B -1 { A_XScream(); }
		Stop;
	Raise.T04:
		"BOS3" NMLKJI 8;
		Goto See;

	// =================================================================
	// T05 YELLOW (15_Y -- CommonYellowBaron : YellowBaron). LOHS.
	// The Grand Gold Baron: sheds sparks constantly, dodges, and picks
	// between a two-beat star barrage, a ring-plus-bomb, a leap, and a
	// fire-hand cast that plants a burning pillar on you.
	// =================================================================
	Spawn.T05:
		"LOHS" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"LOHS" A 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" AABB 3 { A_Chase(); }
		"LOHS" B 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" CCDD 3 { A_Chase(); }
		"LOHS" D 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" A 0 A_Jump(48, "See.T05.Dodger");
		Loop;
	See.T05.Dodger:
		"LOHS" A 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" AABB 3 { A_FastChase(); }
		"LOHS" B 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" CCDD 3 { A_FastChase(); }
		"LOHS" D 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" A 0 A_Jump(128, "See");
		Loop;
	Melee.T05:
		"LOHS" EF 8 { A_FaceTarget(); }
		"LOHS" G 8 { A_CustomMeleeAttack(random(10, 90), "baron/melee"); }
		Goto Missile.T05;
	Missile.T05:
		"LOHS" A 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" E 8 { A_FaceTarget(); }
		"LOHS" E 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" E 0 A_JumpIfCloser(1000, "Missile.T05.RumbleIt");
		"LOHS" E 0 A_JumpIfCloser(1500, "Missile.T05.Dash");
		"LOHS" E 0 A_Jump(256, "Missile.T05.FireSummon");
		Goto See;
	Missile.T05.Dash:
		"LOHS" G 5 { A_ChangeVelocity(11, 0, 6, CVF_RELATIVE); }
		Goto See;
	Missile.T05.RumbleIt:
		"LOHS" E 0 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" E 0 A_Jump(256, "Missile.T05.StarShot", "Missile.T05.FireBlast");
		Goto See;
	Missile.T05.StarShot:
		"LOHS" EF 6 Bright { A_FaceTarget(); }
		"LOHS" G 6 Bright { A_SpawnProjectile("RS_BaronStar", 32, 3, 1); }
		"LOHS" G 2 A_MonsterRefire(80, "See");
		Goto Missile.T05.StarShot2;
	Missile.T05.StarShot2:
		"LOHS" PQ 8 Bright { A_FaceTarget(); }
		"LOHS" R 6 Bright { A_SpawnProjectile("RS_BaronStar2", 32, 3, 1); }
		"LOHS" R 2 A_MonsterRefire(80, "See");
		Goto Missile.T05.StarShot;
	Missile.T05.FireBlast:
		"LOHS" E 12 Bright { A_SpawnProjectile("RS_BaronRing", 80, 0, 0); }
		"LOHS" E 12 Bright { A_FaceTarget(); }
		"LOHS" F 9 Bright;
		"LOHS" G 6 Bright { A_SpawnProjectile("RS_BaronFBomb", 32, 3, 0); }
		"LOHS" G 6;
		Goto See;
	Missile.T05.FireSummon:
		"LOHS" P 14 Bright { A_SpawnProjectile("RS_FireHand1", 46, -26); }
		"LOHS" Q 12 Bright { A_FaceTarget(); }
		"LOHS" R 13 Bright { A_VileTarget("RS_BigBadFire1"); }
		Goto See;
	Pain.T05:
		"LOHS" H 2 { A_SpawnProjectile("RS_SparkPuff1", 34, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"LOHS" H 2 { A_Pain(); }
		"LOHS" H 2 A_Jump(128, "See.T05.Dodger");
		Goto See;
	Death.T05:
		"LOHS" I 8;
		"LOHS" J 8 { A_Scream(); }
		"LOHS" K 8;
		"LOHS" L 8 { A_NoBlocking(); }
		"LOHS" MN 8;
		"LOHS" O -1 { A_BossDeath(); }
		Stop;
	Raise.T05:
		"LOHS" NMLKJI 8;
		Goto See;

	// =================================================================
	// T06 ABYSS (15_A -- CommonAbyssBaron : AbyssBaron2). AZEW/AZEA/
	// AZEP/AZED. The Abyssal Baron: it strafes sideways and warps,
	// resurrects with a bile ring, and casts from either hand -- flare,
	// lightning, defile, a charged soul, and a soul summon.
	// =================================================================
	Spawn.T06:
		"AZEW" A 5 { A_Look(); }
		Loop;
	See.T06:
		"AZEW" AABB 3 { A_VileChase(); }
		TNT1 A 0 A_Jump(24, "See.T06.Dodge1", "See.T06.Dodge2");
		"AZEW" CCDD 3 { A_VileChase(); }
		TNT1 A 0 A_Jump(24, "See.T06.Dodge1", "See.T06.Dodge2");
		Loop;
	See.T06.Dodge1:
		"AZEW" A 0 A_CheckSight("See");
		"AZEW" A 1 { A_ChangeVelocity(0, 0, 1.75, CVF_REPLACE); }
		"AZEW" A 1 { A_ChangeVelocity(0, 29, 0, CVF_RELATIVE); }
		"AZEW" A 0 A_Jump(64, "See.T06.Warp");
		Goto See;
	See.T06.Dodge2:
		"AZEW" A 0 A_CheckSight("See");
		"AZEW" A 1 { A_ChangeVelocity(0, 0, 1.75, CVF_REPLACE); }
		"AZEW" A 1 { A_ChangeVelocity(0, -29, 0, CVF_RELATIVE); }
		"AZEW" A 0 A_Jump(64, "See.T06.Warp");
		Goto See;
	See.T06.Warp:
		"AZEP" A 1;
		"AZEP" AAAAAAAA 0 { A_Wander(); }
		"AZEP" A 1;
		Goto See;
	Heal.T06:
		"AZEP" A 4 Bright { A_SpawnItemEx("RS_AbyssBaronRing", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"AZEP" A 10 Bright;
		"AZEA" FFFF 1 Bright { A_SpawnItemEx("RS_ArchRingHelp", random(-128, 128), random(-128, 128), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Melee.T06:
		"AZEA" AB 4 { A_FaceTarget(); }
		"AZEA" C 4 { A_CustomMeleeAttack(random(42, 99), "baron/melee"); }
		TNT1 AAAAAAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-25, 25), CMF_OFFSETPITCH, random(-25, -5)); }
		"AZEA" DE 4 { A_FaceTarget(); }
		"AZEA" F 4 { A_CustomMeleeAttack(random(42, 99), "baron/melee"); }
		TNT1 AAAAAAAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, -3, random(-25, 25), CMF_OFFSETPITCH, random(-25, -5)); }
		Goto Missile.T06;
	Missile.T06:
		"AZEA" A 0 A_JumpIfCloser(1500, "Missile.T06.Choice");
		"AZEA" A 0 A_Jump(64, "Missile.T06.SoulSummon");
		"AZEA" A 1 { A_FaceTarget(); }
		"AZEA" A 1 { A_SpawnProjectile("RS_AbyssBaronHandFire", 64, 30, 0); }
		"AZEA" A 6 { A_FaceTarget(); }
		"AZEA" A 1 Bright { A_SpawnProjectile("RS_ESZapZap", 64, 30, 0); }
		"AZEA" AA 6 { A_FaceTarget(); }
		"AZEA" B 4 Bright { A_FaceTarget(); }
		"AZEA" C 7 Bright { A_SpawnProjectile("RS_AbyssBaronLightning", 38, 5, 0); }
		"AZEA" C 10;
		"AZEP" A 5;
		Goto See;
	Missile.T06.Choice:
		TNT1 A 0 A_Jump(36, "Missile.T06.SoulSummon");
		TNT1 A 0 A_Jump(256, "Missile.T06.MLeftHand", "Missile.T06.Defile", "Missile.T06.SoulCharge");
		Goto See;
	Missile.T06.Defile:
		"AZEA" D 1 { A_FaceTarget(); }
		"AZEA" D 1 { A_SpawnProjectile("RS_AbyssBaronHandFire", 64, -30, 0); }
		"AZEA" D 12 Bright { A_FaceTarget(); }
		"AZEA" E 3 Bright { A_FaceTarget(); }
		"AZEA" FCB 3 Bright;
		"AZEA" A 8 Bright { A_VileTarget("RS_AbyssBaronDefile"); }
		Goto See;
	Missile.T06.SoulCharge:
		"AZEP" A 16 Bright { A_FaceTarget(); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 32, -30, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 32, 30, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 32, 0, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 64, -30, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 64, 30, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 64, 0, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 0, -30, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 0, 30, 0); }
		"AZEP" A 1 Bright { A_SpawnProjectile("RS_AbyssBaronHandFire", 0, 0, 0); }
		"AZEP" AA 12 Bright { A_FaceTarget(); }
		"AZEW" A 8 Bright { A_SpawnProjectile("RS_AbyssBaronSoulCharge", 42, 0, 0); }
		"AZEW" A 7 { A_ChangeVelocity(0, 0, 1.75, CVF_REPLACE); }
		Goto See;
	Missile.T06.SoulSummon:
		"AZEA" D 10 { A_FaceTarget(); }
		"AZEA" D 1 { A_SpawnProjectile("RS_AbyssBaronHandFire3", 64, -30, 0); }
		"AZEA" D 10 { A_FaceTarget(); }
		"AZEA" D 1 { A_SpawnProjectile("RS_AbyssBaronHandFire3", 76, 0, 0); }
		"AZEA" D 10 { A_FaceTarget(); }
		"AZEA" D 1 { A_SpawnProjectile("RS_AbyssBaronHandFire3", 64, 30, 0); }
		"AZEA" D 10 { A_FaceTarget(); }
		"AZEA" E 16 Bright;
		Goto See;
	Missile.T06.MLeftHand:
		"AZEA" D 1 { A_FaceTarget(); }
		"AZEA" D 1 { A_SpawnProjectile("RS_AbyssBaronHandFire", 64, -30, 0); }
		"AZEA" D 6 { A_FaceTarget(); }
		"AZEA" E 4 { A_FaceTarget(); }
		"AZEA" F 7 { A_SpawnProjectile("RS_AbyssBaronFlare", 38, -5, 0); }
		"AZEA" F 1 A_CheckSight("See");
	Missile.T06.MRightHand:
		"AZEA" A 1 { A_FaceTarget(); }
		"AZEA" A 1 { A_SpawnProjectile("RS_AbyssBaronHandFire", 64, 30, 0); }
		"AZEA" A 6 { A_FaceTarget(); }
		"AZEA" B 4 { A_FaceTarget(); }
		"AZEA" C 7 { A_SpawnProjectile("RS_AbyssBaronFlare", 38, 5, 0); }
		Goto See;
	Pain.T06:
		"AZEP" A 2;
		"AZEP" A 6 { A_Pain(); }
		"AZEP" A 0 A_Jump(128, "See.T06.Dodge1", "See.T06.Dodge2", "See.T06.Warp");
		Goto See;
	Death.T06:
		"AZED" A 5;
		"AZED" B 5 { A_Scream(); }
		"AZED" C 5;
		"AZED" D 4 { A_NoBlocking(); }
		"AZED" E 4;
		"AZED" AAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32), 1, 1, 2, random(-359, 359)); }
		"AZED" AAAA 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(-68, 68), random(-68, 68), random(5, 32), 1, 1, 3, random(-359, 359), SXF_NOCHECKPOSITION); }
		"AZED" F 3;
		"AZED" G -1 { A_BossDeath(); }
		Stop;

	// =================================================================
	// T07 FIREBLU (15_F -- CommonFirebluBaron : FirebluArch2's cousin
	// FirebluBaron2). BSF2/BSF3. Three-combo bruiser: a red/blue ball
	// alternation, a charged blue bomb, and a charged red bomb -- both
	// bombs make it briefly immune to pain while it winds up.
	// =================================================================
	Spawn.T07:
		"BSF2" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"BSF2" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T07:
		"BSF2" EF 6 Bright { A_FaceTarget(); }
		"BSF2" G 3 Bright { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BSF2" H 3 Bright;
		"BSF2" H 0 A_Jump(128, "Melee.T07.Two");
		Goto See;
	Melee.T07.Two:
		"BSF2" IJ 6 Bright { A_FaceTarget(); }
		"BSF2" K 3 Bright { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BSF2" L 3 Bright;
		"BSF2" L 0 A_Jump(64, "Melee.T07.Three");
		Goto See;
	Melee.T07.Three:
		"BSF2" MN 6 Bright { A_FaceTarget(); }
		"BSF2" O 0 { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BSF2" O 3 Bright { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BSF2" P 3 Bright;
		Goto See;
	Missile.T07:
		"BSF2" B 0 A_Jump(256, "Missile.T07.A1", "Missile.T07.A2", "Missile.T07.A3");
		Goto See;
	Missile.T07.A1:
		"BSF2" EF 8 Bright { A_FaceTarget(); }
		"BSF2" G 0 { A_SpawnProjectile("RS_RedBBall", 28, 0, -4, 0); }
		"BSF2" G 0 { A_SpawnProjectile("RS_BluBBall", 28, 0, 0, 0); }
		"BSF2" G 3 Bright { A_SpawnProjectile("RS_RedBBall", 28, 0, 4, 0); }
		"BSF2" H 3 Bright A_MonsterRefire(128, "See");
		"BSF2" IJ 8 Bright { A_FaceTarget(); }
		"BSF2" K 0 { A_SpawnProjectile("RS_BluBBall", 28, 0, -4, 0); }
		"BSF2" K 0 { A_SpawnProjectile("RS_RedBBall", 28, 0, 0, 0); }
		"BSF2" K 3 Bright { A_SpawnProjectile("RS_BluBBall", 28, 0, 4, 0); }
		"BSF2" L 3 Bright A_MonsterRefire(128, "See");
		Goto Missile.T07;
	Missile.T07.A3:
		"BSF2" O 6 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BSF2" O 6 Bright { bNOPAIN = true; }
		"BSF2" ON 8 Bright { A_FaceTarget(); }
		"BSF2" M 6 Bright { A_SpawnProjectile("RS_BluPowerBomb", 40, 0, 0, 0); }
		"BSF2" MN 2;
		"BSF2" M 0 { bNOPAIN = false; }
		Goto See;
	Missile.T07.A2:
		"BSF2" M 4 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BSF2" M 3 Bright { bNOPAIN = true; }
		"BSF2" M 6 Bright { A_SpawnProjectile("RS_RedPower", 10, 0, 0, 0); }
		"BSF2" M 4 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BSF2" M 8 Bright { A_SpawnProjectile("RS_RedPower", 10, 0, 0, 0); }
		"BSF2" MN 8 Bright { A_FaceTarget(); }
		"BSF2" O 6 Bright { A_SpawnProjectile("RS_RedPowerBomb", 32, 0, 0, 0); }
		"BSF2" O 2 { bNOPAIN = false; }
		Goto See;
	Pain.T07:
		"BSF2" Q 2;
		"BSF2" Q 4 { A_Pain(); }
		Goto See;
	Death.T07:
		"BSF2" R 6 Bright;
		"BSF2" S 6 Bright { A_Scream(); }
		"BSF2" T 6 Bright;
		"BSF2" U 6 Bright { A_NoBlocking(); }
		"BSF2" VWXYZ 6 Bright;
		"BSF3" RST 5;
		"BSF3" U -1 { A_BossDeath(); }
		Stop;

	// =================================================================
	// T08 BROWN (15_BR -- CommonBrownBaron : BrownBaron2). STYR.
	// Brown Baron Jam: it stomps dust with every step, throws rocks and
	// flame, opens a spiral when it has clean line of sight, and if it
	// closes to melee it SLAMS -- a blast plus a radius throw.
	// =================================================================
	Spawn.T08:
		"STYR" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"STYR" AA 8 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"STYR" BB 8 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"STYR" CC 8 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"STYR" DD 8 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Melee.T08:
		"STYR" PQ 7 { A_FaceTarget(); }
		"STYR" R 6 { A_CustomMeleeAttack(random(30, 80), "baron/melee"); }
		TNT1 A 0 A_JumpIfCloser(128, "Melee.T08.Slam");
		Goto See;
	Melee.T08.Slam:
		TNT1 A 0 { A_SpawnProjectile("RS_BBaronCmonAndSlam", 32, 0); }
		"STYR" R 1 { A_VileAttack("baron/melee", 5, 5, 128, 1.75); }
		"STYR" R 1 { A_RadiusThrust(3040, 400, RTF_NOTMISSILE); }
		Goto See;
	Missile.T08:
		TNT1 A 0 A_JumpIfInTargetLOS("Missile.T08.Spiral", 0, JLOSF_DEADNOJUMP, 850, 100);
	Missile.T08.Rocks:
		"STYR" E 1 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnProjectile("RS_BrownBaronFlame", 46, 34); }
		"STYR" E 8 { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnProjectile("RS_BrownBaronFlame", 46, 34); }
		"STYR" F 12 { A_FaceTarget(); }
		"STYR" G 6 Bright { A_SpawnProjectile("RS_BaronBrownRock", 46, 0); }
		"STYR" PQ 3 { A_FaceTarget(); }
		"STYR" R 5 Bright { A_SpawnProjectile("RS_BaronBrownRock", 46, 0); }
		Goto See;
	Missile.T08.Spiral:
		TNT1 A 0 A_Jump(128, "Missile.T08.Rocks");
		"STYR" QR 3 { A_FaceTarget(); }
		"STYR" G 6 Bright { A_SpawnProjectile("RS_BrownBaronSpiral", 32, 0); }
		"STYR" F 6;
		Goto See;
	Pain.T08:
		"STYR" H 2;
		"STYR" H 2 { A_Pain(); }
		Goto See;
	Death.T08:
		"STYR" I 5;
		"STYR" J 5 { A_Scream(); }
		"STYR" K 6;
		"STYR" L 7 { A_NoBlocking(); }
		"STYR" M 4;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(8, 32), random(1, 12), 0, random(2, 9), random(0, 360), SXF_NOCHECKPOSITION); }
		"STYR" N 4;
		"STYR" O -1 { A_BossDeath(); }
		Stop;

	// =================================================================
	// T09 GRAY (15_GY -- CommonGrayBaron : GrayBaron2). BSGR/BSG2.
	// A Gray's Baron: a two-handed rock volley, or a quake-backed dirt
	// bomb. It shrugs off elemental hits with a distinct pain sound,
	// and any pain at all turns MISSILEEVENMORE on permanently.
	// =================================================================
	Spawn.T09:
		"BSGR" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"BSGR" AABB 6 { A_Chase(); }
		"BSGR" CCDD 6 { A_Chase(); }
		Loop;
	Missile.T09:
		"BSGR" B 0 A_Jump(256, "Missile.T09.A1", "Missile.T09.A2");
		Goto Missile.T09.A1;
	Missile.T09.A1:
		"BSGR" E 8 Bright { A_FaceTarget(); }
		"BSGR" E 16 Bright { A_SpawnProjectile("RS_WDRock1", 64, 26, 0, 0); }
		"BSGR" F 8 Bright { A_FaceTarget(); }
		"BSGR" G 6 Bright { A_SpawnProjectile("RS_BaronOfDirtCH3", 28, 0, 0, 0); }
		"BSGR" H 4 Bright A_MonsterRefire(128, "See");
		"BSGR" I 8 Bright { A_FaceTarget(); }
		"BSGR" I 16 Bright { A_SpawnProjectile("RS_WDRock1", 64, -26, 0, 0); }
		"BSGR" J 8 Bright { A_FaceTarget(); }
		"BSGR" K 6 Bright { A_SpawnProjectile("RS_BaronOfDirtCH3", 28, 0, 0, 0); }
		"BSGR" L 3 Bright A_MonsterRefire(128, "See");
		Goto Missile.T09;
	Missile.T09.A2:
		"BSGR" M 4 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BSGR" M 3 Bright { bNOPAIN = true; }
		TNT1 A 0 { A_QuakeEx(3, 3, 3, 45, 0, 640, ""); }
		"BSGR" M 6 Bright { A_SpawnProjectile("RS_BaronOfDirtCH", 10, 0, 0, 0); }
		"BSGR" M 4 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BSGR" MMN 8 Bright { A_FaceTarget(); }
		"BSGR" O 6 Bright { A_SpawnProjectile("RS_BaronOfDirtCH2", 32, 0, 0, 0); }
		"BSGR" O 2 { bNOPAIN = true; }
		Goto See;
	Pain.T09:
		"BSGR" Q 2;
		"BSGR" Q 4 { A_Pain(); }
		"BSGR" Q 0 { bMISSILEEVENMORE = true; }
		Goto See;
	Death.T09:
		"BSGR" R 6 Bright;
		"BSGR" S 6 Bright { A_Scream(); }
		"BSGR" T 6 Bright;
		"BSGR" U 6 Bright { A_NoBlocking(); }
		"BSGR" VWXYZ 6 Bright;
		"BSG2" RST 5;
		"BSG2" U -1 { A_BossDeath(); }
		Stop;

	// =================================================================
	// T10 RED (15_R -- CommonRedBaron3 : RedBaron3). BOS4.
	// The Power Baron: two triple-ball volleys that BUILD CHARGE, and
	// at six charges it spends them on a bouncing Archon comet. Below
	// 1250 HP it rages once -- speed 28, MISSILEEVENMORE -- and when it
	// finally dies it gets back up as the Fallen (DeathMorphClass).
	// =================================================================
	Spawn.T10:
		"BOS4" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"BOS4" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T10:
		"BOS4" B 0 A_JumpIfHealthLower(1250, "Missile.T10.Buff");
	Missile.T10.Pick:
		"BOS4" B 0 { if (rsBuildUp >= 6) return ResolveState("Missile.T10.Bomb"); return ResolveState(null); }
		"BOS4" B 0 A_Jump(255, "Missile.T10.Trio");
		Goto See;
	Missile.T10.Trio:
		"BOS4" EF 6 Bright { A_FaceTarget(); }
		"BOS4" G 0 { A_SpawnProjectile("RS_RedBBall", 28, 0, 0, 0); }
		"BOS4" G 0 { A_SpawnProjectile("RS_RedBBall", 28, 0, -6, 0); }
		"BOS4" G 3 Bright { A_SpawnProjectile("RS_RedBBall", 28, 0, 6, 0); }
		"BOS4" G 0 { rsBuildUp++; }
		"BOS4" H 3 Bright A_MonsterRefire(128, "See");
		Goto Missile.T10.Trio2;
	Missile.T10.Trio2:
		"BOS4" IJ 6 Bright { A_FaceTarget(); }
		"BOS4" K 0 { A_SpawnProjectile("RS_RedBBall", 28, 0, 0, 0); }
		"BOS4" K 0 { A_SpawnProjectile("RS_RedBBall", 28, 0, -6, 0); }
		"BOS4" K 3 Bright { A_SpawnProjectile("RS_RedBBall", 28, 0, 6, 0); }
		"BOS4" G 0 { rsBuildUp++; }
		"BOS4" L 3 Bright A_MonsterRefire(128, "See");
		Goto Missile.T10;
	Missile.T10.Bomb:
		"BOS4" M 4 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BOS4" M 1 Bright { bNOPAIN = true; }
		"BOS4" M 3 Bright { A_SpawnProjectile("RS_RedPower", 10, 0, 0, 0); }
		"BOS4" MN 10 Bright { A_FaceTarget(); }
		"BOS4" O 6 Bright { A_SpawnProjectile("RS_ArchonComet", 28, 0, 0, 0); }
		"BOS4" O 0 { rsBuildUp = max(0, rsBuildUp - 5); }
		"BOS4" P 4 Bright { bNOPAIN = false; }
		"BOS4" P 1;
		Goto See;
	Missile.T10.Buff:
		"BOS4" B 0 { if (rsRageUp >= 1) return ResolveState("Missile.T10.Pick"); return ResolveState(null); }
		"BOS4" M 4 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BOS4" M 1 Bright { bNOPAIN = true; }
		"BOS4" M 3 Bright { A_SpawnProjectile("RS_RedPower", 10, 0, 0, 0); }
		"BOS4" M 4 Bright { A_StartSound("baron/sight", CHAN_VOICE); }
		"BOS4" M 2 Bright { A_QuakeEx(5, 5, 5, 30, 0, 256, ""); }
		"BOS4" M 3 Bright { A_SpawnProjectile("RS_RedPower", 10, 0, 0, 0); }
		"BOS4" M 3 Bright { bMISSILEEVENMORE = true; bNOPAIN = false; }
		"BOS4" MN 6 Bright;
		"BOS4" O 6 Bright { A_SpawnProjectile("RS_RedPower", 10, 0, 0, 0); }
		"BOS4" O 2 Bright { A_SetSpeed(28); }
		"BOS4" O 2 { rsRageUp++; MarkEnrageTell(); }
		"BOS4" O 2;
		Goto See;
	Melee.T10:
		"BOS4" EF 6 Bright { A_FaceTarget(); }
		"BOS4" G 3 Bright { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BOS4" H 3 Bright;
		"BOS4" H 0 A_Jump(128, "Melee.T10.Two");
		Goto See;
	Melee.T10.Two:
		"BOS4" IJ 6 Bright { A_FaceTarget(); }
		"BOS4" K 3 Bright { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BOS4" L 3 Bright;
		"BOS4" L 0 A_Jump(64, "Melee.T10.Three");
		Goto See;
	Melee.T10.Three:
		"BOS4" MN 6 Bright { A_FaceTarget(); }
		"BOS4" O 0 { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BOS4" O 3 Bright { A_CustomMeleeAttack(10 * random(1, 8), "baron/melee"); }
		"BOS4" P 3 Bright;
		Goto See;
	Pain.T10:
		"BOS4" Q 2;
		"BOS4" Q 2 { A_Pain(); }
		"BOS4" Q 2 { rsBuildUp++; }
		Goto See;
	Death.T10:
		"BOS4" R 6 Bright;
		"BOS4" S 6 Bright { A_Scream(); }
		"BOS4" T 6 Bright;
		"BOS4" U 6 Bright { A_NoBlocking(); }
		"BOS4" VW 6 Bright;
		// CHP spawns CommonRedBaron2 right here; RS routes the same
		// hand-off through DeathMorphClass so the tier dial carries.
		"BOS4" X 6 Bright;
		"BOS4" YZ 6 Bright { A_BossDeath(); }
		Stop;

	// =================================================================
	// T11 BLACK (15_K -- CommonBlackBaron2 : BlackBaron2). CUTH.
	// The Black Baron from the Abyss: a three-shot deep-one spread, a
	// charged railgun beam, and tentacle summons -- the bashers up
	// close, the rangers once it has raged. Below 4500 HP it goes
	// NOPAIN + MISSILEEVENMORE, speeds up and plants two rangers.
	// The tentacles are RS_SummonPack's own two classes, so the summon
	// runs through the RS live cap.
	// =================================================================
	Spawn.T11:
		"CUTH" DD 6 { A_Look(); }
		Loop;
	See.T11:
		"CUTH" ABCD 6 { A_Chase(); }
		Loop;
	Melee.T11:
		"CUTH" E 0 { A_FaceTarget(); }
		"CUTH" E 4 { A_StartSound("baron/sight", CHAN_VOICE); }
		"CUTH" F 4 { A_FaceTarget(); }
		"CUTH" G 2 { A_CustomMeleeAttack(random(42, 99), "baron/melee"); }
		"CUTH" HI 2;
		"CUTH" I 0 A_Jump(128, "Missile.T11");
		Goto See;
	Missile.T11:
		"CUTH" J 0 A_JumpIfCloser(32, "Melee.T11");
		"CUTH" J 0 A_JumpIfHealthLower(4500, "Missile.T11.AggroUp");
		"CUTH" J 0 A_Jump(256, "Missile.T11.Basic", "Missile.T11.BeamThing", "Missile.T11.TentacleBashers");
		Goto See;
	Missile.T11.TentacleBashers:
		"CUTH" I 8 { A_StartSound("baron/active", CHAN_VOICE); }
		"CUTH" IIII 2 Bright { RS_SummonPack(); }
		"CUTH" L 8;
		"CUTH" H 5;
		Goto See;
	Missile.T11.TentacleRangers:
		"CUTH" F 12 { A_StartSound("baron/active", CHAN_VOICE); }
		"CUTH" II 2 Bright { RS_SummonPack(); }
		"CUTH" L 8;
		"CUTH" H 5 A_Jump(88, "Missile.T11.TentacleBashers");
		Goto See;
	Missile.T11.BeamThing:
		"CUTH" J 4 { A_FaceTarget(); }
		"CUTH" J 1 Bright { A_SpawnProjectile("RS_DeepCharge1", 42, 25); }
		"CUTH" K 18 Bright { A_FaceTarget(); }
		"CUTH" K 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"CUTH" K 0 { A_CustomRailgun(random(25, 75), 25, Color(255, 255, 255), Color(255, 255, 255), RGF_FULLBRIGHT | RGF_SILENT, 1, 0, "RS_DeepBeam1", 0, 0, 0, 35, 0.1, 0.1, "RS_DeepBeam1"); }
		"CUTH" K 8 Bright A_CheckSight("See");
		"CUTH" K 0 A_Jump(88, "Missile.T11.BeamThing");
		Goto See;
	Missile.T11.Basic:
		"CUTH" J 8 { A_FaceTarget(); }
		"CUTH" K 0 { A_SpawnProjectile("RS_DeepOneBall", 42, 20); }
		"CUTH" K 0 { A_SpawnProjectile("RS_DeepOneBall", 42, 5, random(-13, -5)); }
		"CUTH" K 8 Bright { A_SpawnProjectile("RS_DeepOneBall", 42, 35, random(5, 13)); }
		"CUTH" K 0 A_CheckSight("See");
		"CUTH" K 0 A_Jump(168, "Missile.T11.Basic");
		Goto See;
	Missile.T11.Basic2:
		"CUTH" J 8 { A_FaceTarget(); }
		"CUTH" K 0 { A_SpawnProjectile("RS_DeepOneBall", 42, 20); }
		"CUTH" K 0 { A_SpawnProjectile("RS_DeepOneBall", 42, 5, random(-13, -5)); }
		"CUTH" K 0 { A_SpawnProjectile("RS_DeepOneBall", 42, 35, random(5, 13)); }
		"CUTH" K 0 { A_SpawnProjectile("RS_DeepOneBall", 42, -5, random(-20, -13)); }
		"CUTH" K 8 Bright { A_SpawnProjectile("RS_DeepOneBall", 42, 45, random(13, 20)); }
		"CUTH" K 0 A_CheckSight("See");
		"CUTH" K 0 A_Jump(168, "Missile.T11.Basic2");
		Goto See;
	Missile.T11.AggroUp:
		"CUTH" D 0 { if (rsRageUp >= 1) return ResolveState("Missile.T11.Nah"); return ResolveState(null); }
		"CUTH" DDDDD 1 Bright { A_SpawnProjectile("RS_DeepCharge1", random(5, 76), random(-88, 88)); }
		"CUTH" D 1 Bright { bNOPAIN = true; }
		"CUTH" D 1 Bright { bMISSILEEVENMORE = true; }
		"CUTH" D 1 Bright { A_SetSpeed(17); }
		"CUTH" D 8 Bright { A_StartSound("baron/pain", CHAN_VOICE); }
		"CUTH" D 1 { rsRageUp++; MarkEnrageTell(); }
		"CUTH" D 2 { RS_SummonPack(); }
		Goto See;
	Missile.T11.Nah:
		"CUTH" J 0 A_Jump(256, "Missile.T11.Basic2", "Missile.T11.BeamThing", "Missile.T11.TentacleBashers", "Missile.T11.TentacleRangers");
		Goto See;
	Pain.T11:
		"CUTH" L 2;
		"CUTH" L 2 { A_Pain(); }
		Goto See;
	Death.T11:
		"CUTH" M 0 A_Jump(128, "Death.T11.Alt");
		"CUTH" M 10;
		"CUTH" N 10 { A_Scream(); }
		"CUTH" O 10;
		"CUTH" P 10 { A_NoBlocking(); }
		"CUTH" Q -1 { A_BossDeath(); }
		Stop;
	Death.T11.Alt:
		"CUTH" R 5;
		"CUTH" S 5 { A_Scream(); }
		"CUTH" T 5;
		"CUTH" U 5 { A_NoBlocking(); }
		"CUTH" V 5;
		"CUTH" W -1 { A_BossDeath(); }
		Stop;

	// =================================================================
	// T12 WHITE (15_W -- CommonWhiteBaron2 : WhiteBaron2). VSTL/VSTK.
	// Hell's Slice and Dicer. Eight patterns off one rotation: three
	// slice fans, a spin, a homing slice fan, stars, ground spikes, a
	// floor crack, and a skull-attack dash it uses to close. Below
	// 6666 HP it leaps on every approach and the spin becomes the
	// Ultimate Spin -- a full 360 of blades, repeated.
	// =================================================================
	Spawn.T12:
		"VSTL" IJK 8 { A_Look(); }
		Loop;
	See.T12:
		"VSTL" A 0 { bTHRUACTORS = false; }
		"VSTL" AABBCCDDEEFFGGHH 3 { A_Chase(); }
		TNT1 A 0 A_Jump(128, "See.T12.Fast");
		Loop;
	See.T12.Fast:
		"VSTL" AABBCCDDEEFFGGHH 3 { A_FastChase(); }
		TNT1 A 0 A_Jump(128, "See");
		Goto See;
	Melee.T12:
		"VSTL" L 0 { A_FaceTarget(); A_StartSound("baron/melee", CHAN_WEAPON); }
		"VSTL" LM 4 { A_FaceTarget(); }
		"VSTL" NNN 2 { A_Recoil(-12); }
		"VSTL" O 8 { A_CustomMeleeAttack(random(10, 15) * 7, "baron/melee"); }
		"VSTL" P 6 A_Jump(128, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3");
		Goto See;
	Missile.T12.Yahoo:
		"VSTL" U 0 { A_ChangeVelocity(0, 0, 6.25, CVF_REPLACE); }
		"VSTL" U 0 { A_ChangeVelocity(0, frandompick(-6.25, 6.25), 0, CVF_RELATIVE); }
		Goto Missile.T12.Wind;
	Missile.T12.Yahoo2:
		"VSTL" U 0 A_Jump(160, "Missile.T12.Wind");
		"VSTL" U 0 { A_ChangeVelocity(0, 0, 6.25, CVF_REPLACE); }
		"VSTL" U 0 { A_ChangeVelocity(0, frandompick(-6.25, 6.25), 0, CVF_RELATIVE); }
		Goto Missile.T12.Wind;
	Missile.T12:
		"VSTL" W 0 A_JumpIfHealthLower(6666, "Missile.T12.Yahoo2");
		"VSTL" U 0 A_Jump(64, "Missile.T12.Yahoo");
	Missile.T12.Wind:
		"VSTL" U 5 { A_FaceTarget(); }
		"VSTL" QR 5 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(800, "Missile.T12.Dash");
	Missile.T12.Two:
		"VSTL" S 10 { A_StartSound("baron/attack", CHAN_WEAPON); }
		"VSTL" T 5 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(1800, "Missile.T12.Roll");
		Goto Missile.T12.Dash;
	Missile.T12.Roll:
		TNT1 A 0 A_Jump(64, "Missile.T12.SliceHoming", "Missile.T12.Stars", "Missile.T12.Spikes", "Missile.T12.FloorCrack");
		TNT1 A 0 A_Jump(252, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.SpinSlice", "Missile.T12.SliceHoming", "Missile.T12.Stars", "Missile.T12.Spikes", "Missile.T12.FloorCrack");
		Goto Missile.T12.Dash;
	Missile.T12.FloorCrack:
		"VSTL" R 10 { A_FaceTarget(); }
		"VSTL" PPP 3 { A_SpawnProjectile("RS_WhiteBaronGround", 32, 0, randompick(16, 8, 0, -8, -16)); }
		TNT1 A 0 A_Jump(252, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.SpinSlice", "Missile.T12.SliceHoming", "Missile.T12.Stars", "Missile.T12.Spikes");
		Goto See;
	Missile.T12.Spikes:
		"VSTL" R 5 { A_FaceTarget(); }
		"VSTL" PPPPP 2 { A_VileTarget("RS_VileGroundSpikeBrown"); }
		TNT1 A 0 A_Jump(252, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.SpinSlice", "Missile.T12.SliceHoming", "Missile.T12.Stars", "Missile.T12.FloorCrack");
		Goto See;
	Missile.T12.Stars:
		"VSTL" R 8 { A_FaceTarget(); }
		"VSTL" P 10 { A_SpawnProjectile("RS_WhiteBaronStar", 42, 0); }
		"VSTL" P 0 { A_SpawnProjectile("RS_WhiteBaronStar", 42, 16); }
		"VSTL" P 0 { A_SpawnProjectile("RS_WhiteBaronStar", 42, -16); }
		"VSTL" R 8 { A_FaceTarget(); }
		"VSTL" P 10 { A_SpawnProjectile("RS_WhiteBaronStar", 42, 0); }
		"VSTL" P 0 { A_SpawnProjectile("RS_WhiteBaronStar", 42, 16); }
		"VSTL" P 0 { A_SpawnProjectile("RS_WhiteBaronStar", 42, -16); }
		TNT1 A 0 A_Jump(64, "Missile.T12.SliceHoming", "Missile.T12.Stars");
		TNT1 A 0 A_Jump(252, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.SpinSlice", "Missile.T12.SliceHoming", "Missile.T12.Stars", "Missile.T12.FloorCrack", "Missile.T12.Spikes");
		Goto See;
	Missile.T12.SliceHoming:
		"VSTL" L 4 { A_FaceTarget(); }
		"VSTL" M 6 { A_FaceTarget(); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 48, 28); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 32, 14); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 26, -2); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 18, -14); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 2, -28); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 48, -28); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 32, -14); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 26, 2); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 18, 14); }
		"VSTL" N 4 { A_SpawnProjectile("RS_WhiteBaronSliceHoming", 2, 28); }
		"VSTL" O 8;
		"VSTL" P 6;
		"VSTL" P 0 A_Jump(96, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.Dash");
		Goto See;
	Missile.T12.Dash:
		"VSTL" T 0 A_Jump(128, "Missile.T12.Two");
		"VSTL" T 5 { A_FaceTarget(); }
		"VSTL" T 0 { A_StartSound("baron/attack", CHAN_WEAPON); }
		"VSTL" T 5 { A_SkullAttack(30); }
		"VSTL" L 5 { A_Recoil(-30); }
		"VSTL" LLLLLLLLLLLL 2 A_JumpIfCloser(250, "Missile.T12.SpinSlice");
		"VSTL" T 5;
		"VSTL" T 5 { A_Stop(); }
		"VSTL" T 0 A_Jump(200, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.Dash");
		Goto See;
	Missile.T12.Slice1:
		"VSTL" L 4 { A_FaceTarget(); }
		"VSTL" M 6 { A_FaceTarget(); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 48, 24); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 40, 16); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 8); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 26, 0); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 18, -8); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 10, -16); }
		"VSTL" N 4 { A_SpawnProjectile("RS_WhiteBaronSlice", 2, -24); }
		"VSTL" M 6 { A_FaceTarget(); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 48, -24); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 40, -16); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, -8); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 26, 0); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 18, 8); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 10, 16); }
		"VSTL" N 4 { A_SpawnProjectile("RS_WhiteBaronSlice", 2, 24); }
		"VSTL" O 8;
		"VSTL" P 6;
		"VSTL" P 0 A_Jump(96, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.Dash");
		Goto See;
	Missile.T12.Slice2:
		"VSTL" L 4 { A_FaceTarget(); }
		"VSTL" M 6 { A_FaceTarget(); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 44, 44); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 42, 33); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 40, 22); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 38, 11); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 36, 0); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 34, -11); }
		"VSTL" N 4 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, -22); }
		"VSTL" M 6 { A_FaceTarget(); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 44, -44); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 42, -33); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 40, -22); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 38, -11); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 36, 0); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 34, 11); }
		"VSTL" N 4 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 22); }
		"VSTL" O 8;
		"VSTL" P 6;
		"VSTL" P 0 A_Jump(96, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.Dash");
		Goto See;
	Missile.T12.Slice3:
		"VSTL" L 4 { A_FaceTarget(); }
		"VSTL" M 6 { A_FaceTarget(); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 44, -4); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 33, -2); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 22); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 11, 2); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 0, 4); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, -11, 6); }
		"VSTL" N 4 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, -22, 8); }
		"VSTL" M 6 { A_FaceTarget(); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 44, 4); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 33, 2); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 22); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 11, -2); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 0, -4); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, -11, -6); }
		"VSTL" N 4 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, -22, -8); }
		"VSTL" O 8;
		"VSTL" P 6;
		"VSTL" P 0 A_Jump(96, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.Dash");
		Goto See;
	Missile.T12.SpinSlice:
		"VSTL" W 0 A_JumpIfHealthLower(6666, "Missile.T12.UltimateSpin");
		"VSTL" LLM 2 { A_FaceTarget(); }
	Missile.T12.SpinBeat:
		"VSTL" M 2 { A_SetAngle(45 + angle); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, -30); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, -24); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, -18); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, -12); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, -6); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 0); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 6); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 12); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 18); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 24); }
		"VSTL" N 2 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 30); }
		"VSTL" L 4 { A_SetAngle(45 + angle); rsSpinCount++; }
		"VSTL" L 0 { if (rsSpinCount < 8) return ResolveState("Missile.T12.SpinBeat"); rsSpinCount = 0; return ResolveState(null); }
		"VSTL" O 8 { A_SetAngle(45 + angle); }
		"VSTL" P 6;
		"VSTL" P 0 A_Jump(96, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.Dash");
		Goto See;
	Missile.T12.UltimateSpin:
		"VSTL" LLL 2 { A_FaceTarget(); }
	Missile.T12.UltimateBeat:
		"VSTL" LM 2 { A_SetAngle(45 + angle); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 0); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 20); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 40); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 60); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 80); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 100); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 120); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 140); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 160); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 180); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 200); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 220); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 240); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 260); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 280); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 300); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 320); }
		"VSTL" N 2 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 340); }
		"VSTL" LM 2 { A_SetAngle(45 + angle); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 10); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 30); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 50); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 70); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 90); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 110); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 130); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 150); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 170); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 190); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 210); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 230); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 250); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 270); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 290); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 310); }
		"VSTL" N 0 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 330); }
		"VSTL" N 2 { A_SpawnProjectile("RS_WhiteBaronSlice", 32, 1, 350); }
		// CHP counted the repeats with an inventory item on a coin flip.
		"VSTL" N 0 { rsSpinCount += random(0, 1); }
		"VSTL" N 0 { if (rsSpinCount < 8) return ResolveState("Missile.T12.UltimateBeat"); rsSpinCount = 0; return ResolveState(null); }
		"VSTL" O 8 { A_FaceTarget(); }
		"VSTL" P 6;
		Goto See;
	Pain.T12:
		"VSTL" W 0 A_JumpIfHealthLower(6666, "Pain.T12.RageUp");
	Pain.T12.Normal:
		"VSTL" W 4;
		"VSTL" X 4 { A_Pain(); }
		"VSTL" YZ 4;
		"VSTL" P 0 A_Jump(96, "Missile.T12.Slice1", "Missile.T12.Slice2", "Missile.T12.Slice3", "Missile.T12.Dash");
		Goto See;
	Pain.T12.RageUp:
		"VSTL" W 0 { if (rsRude >= 1) return ResolveState("Pain.T12.Normal"); return ResolveState(null); }
		"VSTL" I 0 { bNOPAIN = true; }
		"VSTL" I 8 { A_QuakeEx(4, 4, 4, 100, 0, 640, ""); }
		"VSTL" J 8 { A_StartSound("baron/sight", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"VSTL" K 8 { bMISSILEEVENMORE = true; }
		"VSTL" M 3 { A_SetSpeed(20); }
		"VSTL" N 3 { rsRude = 1; }
		"VSTL" MMMNNNMMM 1 { A_SpawnProjectile("RS_EffectHK", random(10, 60), random(-20, 20), random(0, 360)); }
		Goto Missile.T12.Yahoo;
	Death.T12:
		"VSTK" A 8;
		"VSTK" B 8 { A_Scream(); }
		"VSTK" C 8;
		"VSTK" D 8 { A_NoBlocking(); }
		"VSTK" E 8;
		"VSTK" F -1 { A_BossDeath(); }
		Stop;
	}

	// -----------------------------------------------------------------
	// T03's frost wings. CHP writes the same eight A_SpawnItemEx lines
	// out by hand in ten different states; a helper keeps the state
	// blocks readable without changing a single offset.
	// -----------------------------------------------------------------
	void RS_CyanWings(double zvel)
	{
		A_SpawnItemEx("RS_FrostWingBaron", -1, -12, 42, 8, 0, zvel,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron", -1,  12, 42, 8, 0, zvel, -45, 128);
		A_SpawnItemEx("RS_FrostWingBaron", -1, -20, 56, 8, 0, zvel,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron", -1,  20, 56, 8, 0, zvel, -45, 128);
		A_SpawnItemEx("RS_FrostWingBaron", -1, -28, 56, 8, 0, zvel,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron", -1,  28, 56, 8, 0, zvel, -45, 128);
		A_SpawnItemEx("RS_FrostWingBaron", -1, -36, 68, 8, 0, zvel,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron", -1,  36, 68, 8, 0, zvel, -45, 128);
	}

	void RS_CyanWings2()
	{
		A_SpawnItemEx("RS_FrostWingBaron2", -1, -12, 42, 1, 0, 4,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron2", -1,  12, 42, 1, 0, 4, -45, 128);
		A_SpawnItemEx("RS_FrostWingBaron2", -1, -20, 56, 1, 0, 4,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron2", -1,  20, 56, 1, 0, 4, -45, 128);
		A_SpawnItemEx("RS_FrostWingBaron2", -1, -28, 56, 1, 0, 4,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron2", -1,  28, 56, 1, 0, 4, -45, 128);
		A_SpawnItemEx("RS_FrostWingBaron2", -1, -36, 68, 1, 0, 4,  45, 128);
		A_SpawnItemEx("RS_FrostWingBaron2", -1,  36, 68, 1, 0, 4, -45, 128);
	}
}

// =====================================================================
// RS_BaronFallen -- stage two.
// ---------------------------------------------------------------------
// CHP 15_R's CommonRedBaron2, straight out of the file: the Power Baron
// dies and this gets airborne off its corpse. Faster than you, it
// trades the pack for relentless direct fire and a wing-trail that
// marks where it has been.
//
// CHP ships exactly ONE Fallen -- the red one -- so every tier wears
// the same FALN body and the clusters are stacked rather than
// duplicated. The tier dial still moves its numbers: TierData scales
// CHP's own 1000 HP / speed 20 by the tier the Baron died at, so a T12
// Baron's Fallen is a different animal from a T10 Baron's.
// =====================================================================

class RS_BaronFallen : RS_MonsterLadder
{
	Default
	{
		Health 1000;
		Radius 24;
		Height 56;
		Mass 400;
		Speed 20;
		FloatSpeed 25;
		PainChance 128;
		Monster;
		+FLOAT +NOGRAVITY +DONTFALL MissileChanceMult 0.5;
		RenderStyle "Add";
		Alpha 0.9;
		SeeSound "baron/sight";   PainSound "baron/pain";
		DeathSound "baron/death"; ActiveSound "baron/active";
		Obituary "$OB_BARON";
		Tag "Fallen Baron";
	}

	// CHP's Fallen is a fixed 1000 HP / speed 20; the ladder here is RS
	// carrying the parent Baron's tier through the morph so the second
	// stage of a white Baron is not the second stage of a red one.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 128; r.dmgMul = 1.0;
		switch (t)
		{
			case 0:  r.hpMul = 1.00; r.spdMul = 1.00; r.painChance = 128; r.dmgMul = 1.0; break;
			case 1:  r.hpMul = 1.10; r.spdMul = 1.00; r.painChance = 120; r.dmgMul = 1.1; break;
			case 2:  r.hpMul = 1.20; r.spdMul = 1.05; r.painChance = 112; r.dmgMul = 1.2; break;
			case 3:  r.hpMul = 1.35; r.spdMul = 1.20; r.painChance = 104; r.dmgMul = 1.3; break;
			case 4:  r.hpMul = 1.45; r.spdMul = 1.05; r.painChance = 96;  r.dmgMul = 1.4; break;
			case 5:  r.hpMul = 1.60; r.spdMul = 1.15; r.painChance = 88;  r.dmgMul = 1.5; break;
			case 6:  r.hpMul = 2.00; r.spdMul = 1.10; r.painChance = 80;  r.dmgMul = 1.8; break;
			case 7:  r.hpMul = 1.70; r.spdMul = 1.25; r.painChance = 72;  r.dmgMul = 1.6; break;
			case 8:  r.hpMul = 1.85; r.spdMul = 1.40; r.painChance = 64;  r.dmgMul = 1.7; break;
			case 9:  r.hpMul = 1.95; r.spdMul = 1.00; r.painChance = 56;  r.dmgMul = 1.8; break;
			case 10: r.hpMul = 2.20; r.spdMul = 1.10; r.painChance = 48;  r.dmgMul = 2.0; break;
			case 11: r.hpMul = 3.00; r.spdMul = 1.20; r.painChance = 40;  r.dmgMul = 2.5; break;
			case 12: r.hpMul = 3.60; r.spdMul = 1.30; r.painChance = 32;  r.dmgMul = 3.0; break;
			default: return false;
		}
		return true;
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "FALN FALN FALN FALN FALN FALN FALN FALN FALN FALN FALN FALN FALN";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:baron role:artillery delivery:heavy element:thermal mobility:flying trait:secondstage";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 2, 18.0,
			"baron/attack", 1.0, 0.0, "Twin Star"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronBomb(), 1, 0.0,
			"baron/attack", 1.2, 0.0, "Hellbomb"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronRing(), 18, 360.0,
			"baron/attack", 1.0, 5.0, "Hell Ring"));
		return slot;
	}

	States
	{
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T03:
	Spawn.T04:
	Spawn.T05:
	Spawn.T06:
	Spawn.T07:
	Spawn.T08:
	Spawn.T09:
	Spawn.T10:
	Spawn.T11:
	Spawn.T12:
		"FALN" ABCDB 8 Bright { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T03:
	See.T04:
	See.T05:
	See.T06:
	See.T07:
	See.T08:
	See.T09:
	See.T10:
	See.T11:
	See.T12:
		"FALN" A 0 A_Jump(96, "See.T00.Trail");
		"FALN" A 1 Bright { A_StartSound("baron/active", CHAN_VOICE); }
		"FALN" AABBCCDDBB 2 Bright { A_Chase(); }
		Loop;
	See.T00.Trail:
		"FALN" B 2 Bright { A_FastChase(); }
		"FALN" B 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" B 2 Bright { A_FastChase(); }
		"FALN" B 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" B 2 Bright { A_FastChase(); }
		"FALN" B 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" B 2 Bright { A_FastChase(); }
		"FALN" B 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" B 0 A_Jump(64, "See");
		Loop;
	Missile.T00:
	Missile.T01:
	Missile.T02:
	Missile.T03:
	Missile.T04:
	Missile.T05:
	Missile.T06:
	Missile.T07:
	Missile.T08:
	Missile.T09:
	Missile.T10:
	Missile.T11:
	Missile.T12:
		"FALN" C 0 A_Jump(128, "Missile.T00.Strafe");
		"FALN" CE 2 Bright { A_FaceTarget(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" E 2 Bright { A_FaceTarget(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" E 2 Bright { A_FaceTarget(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" E 2 Bright { A_FaceTarget(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" E 2 Bright { A_FaceTarget(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" E 5 Bright;
		Goto See;
	Missile.T00.Strafe:
		"FALN" C 0 { A_FastChase(); }
		"FALN" C 2 Bright { A_FaceTarget(); }
		"FALN" E 0 { A_FastChase(); }
		"FALN" E 2 Bright { A_FaceTarget(); }
		"FALN" F 0 { A_FastChase(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" F 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" C 0 { A_FastChase(); }
		"FALN" C 2 Bright { A_FaceTarget(); }
		"FALN" E 0 { A_FastChase(); }
		"FALN" E 2 Bright { A_FaceTarget(); }
		"FALN" F 0 { A_FastChase(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" F 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" C 0 { A_FastChase(); }
		"FALN" C 5 Bright { A_FaceTarget(); }
		"FALN" E 0 { A_FastChase(); }
		"FALN" E 2 Bright { A_FaceTarget(); }
		"FALN" F 0 { A_FastChase(); }
		"FALN" F 3 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" F 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" C 0 { A_FastChase(); }
		"FALN" C 2 Bright { A_FaceTarget(); }
		"FALN" E 0 { A_FastChase(); }
		"FALN" E 3 Bright { A_FaceTarget(); }
		"FALN" F 0 { A_FastChase(); }
		"FALN" F 2 Bright { A_SpawnProjectile("RS_RedBBall2", 40, 0, 0); }
		"FALN" F 0 { A_SpawnItemEx("RS_FallenFX", 0, 0, 40, 0, 0, 0, 0, 128); }
		"FALN" E 5 Bright;
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T03:
	Pain.T04:
	Pain.T05:
	Pain.T06:
	Pain.T07:
	Pain.T08:
	Pain.T09:
	Pain.T10:
	Pain.T11:
	Pain.T12:
		"FALN" E 3 Bright;
		"FALN" E 3 Bright { A_Pain(); }
		"FALN" E 3 Bright;
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T03:
	Death.T04:
	Death.T05:
	Death.T06:
	Death.T07:
	Death.T08:
	Death.T09:
	Death.T10:
	Death.T11:
	Death.T12:
		"FALN" G 5 Bright;
		"FALN" H 5 Bright { A_Scream(); }
		"FALN" IIIJJJKKK 2 Bright { A_SpawnProjectile("RS_HKRedDeath", random(5, 70), random(5, 35), 0, CMF_AIMOFFSET, -10); }
		"FALN" L 5 Bright { A_NoBlocking(); }
		"FALN" M -1 { A_SetFloorClip(); }
		Stop;
	}
}
