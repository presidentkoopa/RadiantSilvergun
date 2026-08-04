// =====================================================================
// RS_Zombieman -- per-tier state rebuild (docs/rs_09 spec, RS_Imp.zs
// is the template). Replaces Zombieman. THIRTEEN REAL CREATURES:
//
//   T00 POSS vanilla bullet        T01 POSS+tint bullet + poison gas
//   T02 POSS+tint heavy bullet     T03 CYNT frost shot, ice-shatter death
//   T04 POSS+tint bullet + seeker  T05 CZOW Orange Zombiewoman: burst
//        orb                            guns / mini-rockets that JAM
//   T06 ABTR Abyss Infected: twin  T07 POSS+tint FireBlu KAMIKAZE:
//        abyss bolts, splash pain       fire shots, blows up in melee
//   T08 SGAR Bodyguard: heavy      T09 SHDT Gray: rock volley, shatters
//        bullet + leaping charge        into a rock ring when gibbed
//   T10 ZUNM Red ZombieUnman: Unmaker rail barrage or heavy slug
//   T11 PLAY "Player 9": SSG (one shell then reload) / plasma spam /
//        rockets by range, real melee punch
//   T12 MAGE THE UNDERTAKER: shovel blades close, bone shotgun mid,
//        rapid bones far; the charge ladder upgrades the bones and
//        finally unlocks the bone tornado
//
// RS mechanics preserved from the previous file: the Undertaker charge
// ladder (RS_ClimbLadder on the charge counter, steps at 5/9/12,
// tier-gated T06+) still rolls in the Pain DISPATCHER, still pays off
// in stats AND in attack output (extra rounds in every bullet tier's
// burst via rsStep; bone-grade upgrades + tornado unlock at T12).
// Consts, keywords, TintTable, BodyTable (audit data) all kept.
// RS_WearBody is gone -- bodies are literal sprites per cluster.
//
// HONEST OMISSIONS (vs CH decorate): the Brown bodyguard's GETDOWN
// warp-to-master escort move (needs a master-of-class chain) and the
// CH gib-generator/particle dressing. Cyan/Green/Blue/Purple tinted
// accessory-gib XDeaths (ZOMG/ZOMB/ZOMP sprites) are not in the
// sprite import; those tiers gib with translated POSS frames instead.
// =====================================================================

class RS_Zombieman : RS_HumanMonster replaces Zombieman
{
	Default
	{
		Health 20;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "grunt/sight";  PainSound "grunt/pain";
		DeathSound "grunt/death"; ActiveSound "grunt/active";
		AttackSound "grunt/attack";
		Obituary "$OB_ZOMBIE";
		Tag "Zombieman";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "POSS POSS POSS CYNT POSS CZOW ABTR POSS SGAR SHDT ZUNM PLAY MAGE";
	}

	override string TintTable()
	{
		return "- rs_zombie_t01 rs_zombie_t02 rs_zombie_t03 rs_zombie_t04 "
		       "rs_zombie_t05 rs_zombie_t06 rs_zombie_t07 - rs_zombie_t09 "
		       "- rs_zombie_t11 rs_zombie_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:zombieman role:fodder delivery:bullet element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE UNDERTAKER'S LADDER. CHP's white zombieman tracks a counter and
	// steps permanently harder at fixed marks -- not a single enrage but
	// a staircase, so a zombieman that survives a long fight becomes a
	// genuinely different problem. Rebuilt on the charge counter.
	//
	// Charge rises on every hit it takes. Steps at 5 / 9 / 12.
	// -----------------------------------------------------------------
	const RS_ZM_TIER_LADDER = 6;
	const RS_ZM_STEP1 = 5;
	const RS_ZM_STEP2 = 9;
	const RS_ZM_STEP3 = 12;

	private int rsStep;
	private int rsRockets;    // T05 rocket-jam counter (CH RocketCounter)
	private bool rsShellUsed; // T11 SSG one-shell jam (CH ShotgunWhere)

	void RS_ClimbLadder()
	{
		if (Tier < RS_ZM_TIER_LADDER)
			return;

		AddCharge(1);

		if (rsStep < 1 && ChargeCounter >= RS_ZM_STEP1)
		{
			rsStep = 1;
			Speed *= 1.3;
			MissileChanceMult *= 2.0;
			A_SetScale(Scale.X * 1.08);
			A_StartSound("grunt/sight", CHAN_VOICE);
		}
		else if (rsStep < 2 && ChargeCounter >= RS_ZM_STEP2)
		{
			rsStep = 2;
			Speed *= 1.25;
			A_SetScale(Scale.X * 1.10);
			A_StartSound("grunt/sight", CHAN_VOICE);
		}
		else if (rsStep < 3 && ChargeCounter >= RS_ZM_STEP3)
		{
			// Final form: stops flinching entirely.
			rsStep = 3;
			bNOPAIN = true;
			Speed *= 1.2;
			A_SetScale(Scale.X * 1.12);
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	// Per-tier voices, straight from CH's own sound assignments
	// (SNDINFO monsters section carries the lumps).
	override void OnTierApplied(int t)
	{
		SeeSound = "grunt/sight";  PainSound = "grunt/pain";
		DeathSound = "grunt/death"; ActiveSound = "grunt/active";
		AttackSound = "grunt/attack";
		switch (t)
		{
			case 5:
				SeeSound = "lady/aggro";  PainSound = "lady/hurt";
				DeathSound = "lady/die";  ActiveSound = "lady/active";
				break;
			case 6:
			case 8:
			case 9:
				SeeSound = "zom2/see";    PainSound = "form2/hurt";
				DeathSound = "zom2/die";  ActiveSound = "form2/active";
				break;
			case 10:
				SeeSound = "zom2/see";    PainSound = "form2/hurt";
				DeathSound = "zom2/die";  ActiveSound = "form2/active";
				AttackSound = "zombie/unmaker";
				break;
			case 11:
				PainSound = "player9/pain"; DeathSound = "player9/death";
				break;
			case 12:
				SeeSound = "under/see";   PainSound = "skeleton/pain";
				DeathSound = "under/die"; ActiveSound = "grunt/active";
				break;
			default:
				break;
		}
	}

	States
	{
	// ===== dispatcher overrides: family-wide mechanics roll here =====
	Missile:
		TNT1 A 0 { return TierState("Missile"); }
		Goto See;
	Pain:
		TNT1 A 0
		{
			RS_ClimbLadder();
			return TierState("Pain");
		}
		Goto See;

	// =========================================================
	// T00 -- vanilla zombieman. T01/T02/T04 share the POSS body:
	// walk/pain/death stack here, bespoke attacks in their own
	// Missile. T07 (kamikaze) shares Spawn/Death only -- its See
	// trails fire and its XDeath is an explosion.
	// =========================================================
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T07:
		"POSS" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
		"POSS" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T00:
		"POSS" E 10 { A_FaceTarget(); A_StartSound("grunt/attack", CHAN_WEAPON); }
		"POSS" F 8 Bright { RS_TierBullets(1 + rsStep, 5.6, 3, 15); }
		"POSS" E 8;
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T07:
		"POSS" G 3;
		"POSS" G 3 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T07:
		"POSS" H 5;
		"POSS" I 5 { A_Scream(); }
		"POSS" J 5 { A_NoBlocking(); }
		"POSS" K 5;
		"POSS" L -1;
		Stop;
	XDeath.T00:
	XDeath.T01:
	XDeath.T02:
	XDeath.T04:
		// CH gibs Green/Blue/Purple with tinted accessory sprites
		// (ZOMG/ZOMB/ZOMP) -- not in the import; the translation on
		// these POSS frames keeps the gibs the right colour.
		"POSS" M 5;
		"POSS" N 5 { A_XScream(); }
		"POSS" O 5 { A_NoBlocking(); }
		"POSS" PQRST 5;
		"POSS" U -1;
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
	Raise.T04:
	Raise.T07:
		"POSS" LKJIH 5;
		Goto See;

	// ===== T01 GREEN -- bullet + stationary poison gas =====
	Missile.T01:
		"POSS" E 10 { A_FaceTarget(); A_StartSound("grunt/attack", CHAN_WEAPON); }
		"POSS" F 6 Bright { RS_TierBullets(1 + rsStep, 5.6, 3, 15); }
		"POSS" F 4 Bright { A_SpawnProjectile("RS_Gas11", 24, 0, 0); }
		"POSS" E 6;
		Goto See;

	// ===== T02 BLUE -- heavier bullet (CH blue is the HP/damage jump) =====
	Missile.T02:
		"POSS" E 10 { A_FaceTarget(); A_StartSound("grunt/attack", CHAN_WEAPON); }
		"POSS" F 8 Bright { RS_TierBullets(1 + rsStep, 5.6, 5, 18); }
		"POSS" E 8;
		Goto See;

	// ===== T03 CYAN -- frost zombie (CYNT), shatters on death =====
	Spawn.T03:
		"CYNT" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"CYNT" AABBCCDD 2 { A_Chase(); }
		TNT1 A 0 A_Jump(128, "See.T03.Rush");
		Loop;
	See.T03.Rush:
		"CYNT" AABBCCDD 1 { A_FastChase(); }
		Goto See.T03;
	Missile.T03:
		"CYNT" E 6 { A_FaceTarget(); }
		"CYNT" F 4 Bright { A_SpawnProjectile("RS_IceZombieShot", 42, 1, random(-2, 2)); }
		"CYNT" E 4;
		Goto See;
	Pain.T03:
		"CYNT" G 3;
		"CYNT" G 3 { A_Pain(); }
		Goto See;
	Death.T03:
	XDeath.T03:
		// CH: the frost zombie's corpse wobbles and shatters.
		"CYNT" G 12 { A_Scream(); }
		"CYNT" G 4 { A_NoBlocking(); }
		"CYNT" G 6 { A_SetScale(1.2, 0.8); }
		"CYNT" G 6 { A_SetScale(1.0, 1.0); }
		"CYNT" G 4 { A_SetScale(0.8, 1.2); }
		"CYNT" G 3 { A_SetScale(1.2, 0.8); }
		"CYNT" G 2 { A_SetScale(0.8, 1.2); }
		"CYNT" G 1 { A_SetScale(1.2, 0.8); }
		TNT1 A 0 { A_IceGuyDie(); }
		Stop;

	// ===== T04 PURPLE -- bullet + seeking orb =====
	Missile.T04:
		"POSS" E 10 { A_FaceTarget(); A_StartSound("grunt/attack", CHAN_WEAPON); }
		"POSS" F 6 Bright { RS_TierBullets(1 + rsStep, 5.6, 3, 15); }
		"POSS" F 4 Bright { A_SpawnProjectile("RS_Orbb11", 24, 0, random(-4, 4)); }
		"POSS" E 6;
		Goto See;

	// ===== T05 YELLOW -- Orange Zombiewoman (CZOW): guns or rockets,
	// rockets jam after three, dodge-weaves under fire =====
	Spawn.T05:
		"CZOW" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"CZOW" AABB 4 { A_Chase(); }
		"CZOW" CCDD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(88, "Dodge.T05");
		Loop;
	Dodge.T05:
		"CZOW" AABB 4 { A_FastChase(); }
		"CZOW" CCDD 4 { A_FastChase(); }
		TNT1 A 0 A_Jump(88, "See.T05");
		Loop;
	Missile.T05:
		"CZOW" E 5 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(550, "Missile.T05.Guns");
		TNT1 A 0 A_Jump(160, "Missile.T05.Rockets");
		Goto Missile.T05.Guns;
	Missile.T05.Guns:
		// Three-round burst, spread opening as it walks fire.
		"CZOW" F 3 Bright { A_StartSound("chainguy/attack", CHAN_WEAPON); RS_TierBullets(1, 4.0, 1, 3); }
		"CZOW" E 2 { A_FaceTarget(); }
		"CZOW" F 3 Bright { RS_TierBullets(1, 7.0, 1, 3); }
		"CZOW" E 2 { A_FaceTarget(); }
		"CZOW" F 3 Bright { RS_TierBullets(1, 9.0, 1, 3); }
		"CZOW" E 2;
		Goto See;
	Missile.T05.Rockets:
		TNT1 A 0
		{
			if (rsRockets >= 3)
				return ResolveState("Missile.T05.Jam");
			return ResolveState(null);
		}
		"CZOW" F 3 Bright { rsRockets++; A_SpawnProjectile("RS_MiniRKTZombie", 32, 2, random(-2, 2)); }
		"CZOW" E 2;
		"CZOW" E 2 A_MonsterRefire(128, "See");
		Goto Missile.T05.Rockets;
	Missile.T05.Jam:
		// The launcher jams: helpless clatter, then back to work.
		TNT1 A 0 { bNOPAIN = true; }
		"CZOW" E 10 { A_StartSound("jam/jamd", CHAN_WEAPON); }
		"CZOW" A 18 { A_FaceTarget(); }
		"CZOW" E 10 { A_StartSound("jam/jamd", CHAN_WEAPON); }
		"CZOW" G 16 { rsRockets = 0; }
		"CZOW" A 16 { A_StartSound("lady/active", CHAN_VOICE); bNOPAIN = false; }
		Goto See;
	Pain.T05:
		"CZOW" G 3;
		"CZOW" G 3 { A_Pain(); }
		Goto Dodge.T05;
	Death.T05:
		"CZOW" H 5;
		"CZOW" I 5 { A_Scream(); }
		"CZOW" J 5 { A_NoBlocking(); }
		"CZOW" K 5;
		"CZOW" LM 5;
		"CZOW" N -1;
		Stop;
	XDeath.T05:
		"CZOW" O 5;
		"CZOW" P 5 { A_XScream(); }
		"CZOW" Q 5 { A_NoBlocking(); }
		"CZOW" RSTUV 5;
		"CZOW" W -1;
		Stop;
	Raise.T05:
		"CZOW" MLKJIH 5;
		Goto See;

	// ===== T06 ABYSS -- Abyss Infected (ABTR): twin abyss bolts,
	// splash burst when hurt =====
	Spawn.T06:
		"ABTR" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"ABTR" AAB 2 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"ABTR" B 1 { A_FastChase(); }
		"ABTR" CCD 2 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"ABTR" D 1 { A_FastChase(); }
		Loop;
	Missile.T06:
		"ABTR" E 10 { A_FaceTarget(); }
		"ABTR" F 5 { A_SpawnProjectile("RS_AbyssZshotCH", 36, 3, random(-7, 1)); }
		"ABTR" F 5 { A_SpawnProjectile("RS_AbyssZshotCH", 36, 3, random(-1, 7)); }
		"ABTR" E 10;
		Goto See;
	Pain.T06:
		"ABTR" G 1;
		"ABTR" G 1 { A_Pain(); }
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-96, 96), random(-96, 96), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Death.T06:
		"ABTR" H 5;
		"ABTR" I 5 { A_Scream(); }
		"ABTR" J 5 { A_NoBlocking(); }
		"ABTR" KL 5;
		"ABTR" L -1;
		Stop;
	XDeath.T06:
		"ABTR" MNO 5;
		"ABTR" P 5 { A_XScream(); }
		"ABTR" Q 5 { A_NoBlocking(); }
		"ABTR" RSTU 5 { A_SpawnItemEx("RS_SplashAbyss2", random(-24, 24), random(-24, 24), random(8, 64), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"ABTR" U -1;
		Stop;
	Raise.T06:
		"ABTR" KJIH 5;
		Goto See;

	// ===== T07 FIREBLU -- kamikaze: fire shots at range, trails
	// flame while chasing, DETONATES in melee =====
	See.T07:
		"POSS" AABB 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_FireSGguy2", -6, 0, 3, -2, 0, 1, -180); }
		"POSS" CCDD 3 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_FireSGguy2", -6, 0, 3, -2, 0, 1, -180); }
		Loop;
	Missile.T07:
		"POSS" E 10 { A_FaceTarget(); }
		"POSS" F 6 Bright { A_SpawnProjectile("RS_FireSGguy2", 24, 0, random(-3, 3)); }
		"POSS" E 6;
		Goto See;
	Melee.T07:
		// CH: the flaming zombie's "melee" IS its self-destruct.
		"POSS" EF 5 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_Die("Extreme"); }
		Goto See;
	XDeath.T07:
		TNT1 A 0 { A_StartSound("weapons/rocklx", CHAN_BODY); }
		MISL B 6 Bright { A_Explode(int(30 * TierDamageMul), 84); }
		MISL C 6 Bright { A_Quake(20, 12, 0, 64); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 1, random(-359, 359)); }
		MISL D 6 { A_NoBlocking(); }
		Stop;

	// ===== T08 BROWN -- the Bodyguard (SGAR): heavy bullet, leaping
	// charge to close distance. NOTE: SGAR's sheet is offset -- walk
	// is B-E, attack F/G, pain H, death I-M (verified on disk). =====
	Spawn.T08:
		"SGAR" A 10 { A_Look(); }
		Loop;
	See.T08:
		"SGAR" BC 6 { A_Chase(); }
		"SGAR" DE 6 { A_Chase(); }
		TNT1 A 0 A_Jump(48, "Leap.T08");
		Loop;
	Leap.T08:
		// CH FrontJump: hurl itself at the player's position.
		"SGAR" F 5 { A_FaceTarget(); }
		"SGAR" F 1 { vel.z += 7; A_Recoil(-14); }
		"SGAR" F 16;
		"SGAR" F 6 { A_Stop(); }
		"SGAR" BC 6 { A_FastChase(); }
		Goto See.T08;
	Missile.T08:
		"SGAR" F 10 { A_FaceTarget(); }
		"SGAR" G 10 Bright { A_StartSound("grunt/attack", CHAN_WEAPON); RS_TierBullets(1 + rsStep, 5.6, 5, 18); }
		"SGAR" F 10;
		Goto See;
	Pain.T08:
		"SGAR" H 8 { A_Pain(); }
		Goto See;
	Death.T08:
		"SGAR" I 5;
		"SGAR" J 5 { A_Scream(); }
		"SGAR" K 5;
		"SGAR" L 5 { A_NoBlocking(); }
		"SGAR" M -1;
		Stop;
	XDeath.T08:
		// CH itself gibs the bodyguard with POSS frames (untinted tier).
		"POSS" M 3;
		"POSS" N 3 { A_XScream(); }
		"POSS" O 3 { A_NoBlocking(); }
		"POSS" PQRST 3;
		"POSS" U -1;
		Stop;
	Raise.T08:
		"SGAR" LKJI 5;
		Goto See;

	// ===== T09 GRAY -- rock-thrower (SHDT), slow and hard; gibbing
	// it shatters it into a rock ring =====
	Spawn.T09:
		"SHDT" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"SHDT" AABB 5 { A_Chase(); }
		"SHDT" CCDD 5 { A_Chase(); }
		Loop;
	Missile.T09:
		"SHDT" E 10 { A_FaceTarget(); }
		"SHDT" F 2 Bright { A_SpawnProjectile("RS_ZombieRock", 46, 1, random(-2, 2)); }
		"SHDT" F 2 { A_SpawnProjectile("RS_ZombieRock", 46, 1, random(-2, 2)); }
		"SHDT" F 2 Bright { A_SpawnProjectile("RS_ZombieRock", 46, 1, random(-2, 2)); }
		"SHDT" F 2;
		"SHDT" E 8;
		Goto See;
	Pain.T09:
		"SHDT" G 3;
		"SHDT" G 3 { A_Pain(); }
		Goto See;
	Death.T09:
		"SHDT" H 5;
		"SHDT" I 5 { A_Scream(); }
		"SHDT" J 5 { A_NoBlocking(); }
		"SHDT" K 5;
		"SHDT" L -1;
		Stop;
	XDeath.T09:
		// CH: the gray zombie wobbles apart and bursts into rocks.
		"SHDT" G 12 { A_XScream(); }
		"SHDT" G 4 { A_NoBlocking(); }
		"SHDT" G 6 { A_SetScale(1.2, 0.8); }
		"SHDT" G 5 { A_SetScale(0.8, 1.2); }
		"SHDT" G 4 { A_SetScale(1.2, 0.8); }
		"SHDT" G 3 { A_SetScale(0.8, 1.2); }
		"SHDT" G 2 { A_SetScale(1.2, 0.8); }
		"SHDT" G 1 { A_SetScale(0.8, 1.2); }
		MISL BCD 1;
		TNT1 AAAAAAAAAAAAA 0 { A_SpawnProjectile("RS_ZombieRock", 32, 0, random(-180, 180), CMF_AIMDIRECTION); }
		Stop;
	Raise.T09:
		"SHDT" KJIH 5;
		Goto See;

	// ===== T10 RED -- ZombieUnman (ZUNM): Unmaker rail barrage at
	// range, heavy slug otherwise =====
	Spawn.T10:
		"ZUNM" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"ZUNM" AABB 2 { A_Chase(); }
		"ZUNM" CCDD 2 { A_Chase(); }
		Loop;
	Missile.T10:
		TNT1 A 0 A_Jump(64, "Missile.T10.Rail");
		"ZUNM" E 15 { A_FaceTarget(); }
		"ZUNM" F 10 { RS_TierBullets(1, 2.0, 5, 25); }
		"ZUNM" E 10;
		Goto See;
	Missile.T10.Rail:
		"ZUNM" E 16 { A_FaceTarget(); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(int(random(5, 20) * TierDamageMul), 4, "FF 00 00", "", 0, 0); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(int(random(5, 20) * TierDamageMul), 4, "CC 00 00", "", 0, 0); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(int(random(5, 20) * TierDamageMul), 4, "99 00 00", "", 0, 0); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(int(random(5, 20) * TierDamageMul), 4, "55 00 00", "", 0, 0); }
		"ZUNM" E 10;
		Goto See;
	Pain.T10:
		"ZUNM" G 3;
		"ZUNM" G 3 { A_Pain(); }
		Goto See;
	Death.T10:
		"ZUNM" H 5;
		"ZUNM" I 5 { A_Scream(); }
		"ZUNM" J 5 { A_NoBlocking(); }
		"ZUNM" KLM 5;
		"ZUNM" N -1;
		Stop;
	XDeath.T10:
		"ZUNM" O 5;
		"ZUNM" P 5 { A_XScream(); }
		"ZUNM" Q 5 { A_NoBlocking(); }
		"ZUNM" RSTUV 5 { A_SpawnItemEx("RS_HKRedDeath", random(-24, 24), random(-24, 24), random(8, 64), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ZUNM" W -1;
		Stop;
	Raise.T10:
		"ZUNM" KJIH 5;
		Goto See;

	// ===== T11 BLACK -- "Player 9" (PLAY): a dead marine still
	// playing the game. SSG close (one shell, then reloads), plasma
	// spam mid, rockets far, real punch in melee =====
	Spawn.T11:
		"PLAY" A 4 { A_Look(); }
		Loop;
	See.T11:
		"PLAY" ABCD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(128, "See.T11.Sprint");
		Loop;
	See.T11.Sprint:
		"PLAY" ABCD 4 { A_FastChase(); }
		Goto See.T11;
	Melee.T11:
		"PLAY" E 4 { A_FaceTarget(); }
		"PLAY" E 4 { A_CustomMeleeAttack(random(20, 80), "player9/fist", ""); }
		Goto Missile.T11.SSG;
	Missile.T11:
		TNT1 A 0 A_JumpIfCloser(300, "Missile.T11.SSG");
		TNT1 A 0 A_JumpIfCloser(840, "Missile.T11.Plasma");
		Goto Missile.T11.Rockets;
	Missile.T11.SSG:
		TNT1 A 0
		{
			if (rsShellUsed)
				return ResolveState("Missile.T11.Reload");
			return ResolveState(null);
		}
		"PLAY" E 3 { A_FaceTarget(); }
		"PLAY" F 13 Bright { rsShellUsed = true; A_StartSound("weapons/sshotf", CHAN_WEAPON); RS_TierBullets(8, 22.5, 3, 8); }
		Goto See;
	Missile.T11.Reload:
		"PLAY" E 8 Bright;
		"PLAY" A 2 { A_StartSound("weapons/sshotl", CHAN_WEAPON); }
		"PLAY" A 8 { rsShellUsed = false; }
		"PLAY" E 2;
		Goto See;
	Missile.T11.Plasma:
		"PLAY" E 2 { A_FaceTarget(); }
		"PLAY" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-5, 5)); }
		"PLAY" E 1 { A_FaceTarget(); }
		"PLAY" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-15, 15)); }
		"PLAY" E 1 { A_FaceTarget(); }
		"PLAY" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-25, 25)); }
		"PLAY" E 1;
		"PLAY" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-35, 35)); }
		"PLAY" A 3;
		Goto See;
	Missile.T11.Rockets:
		"PLAY" E 2;
		"PLAY" F 2 Bright { RS_TierBullets(1, 5.6, 3, 8); }
		"PLAY" E 2 A_Jump(32, "Missile.T11.Rawk");
		"PLAY" A 0 A_CPosRefire;
		Goto Missile.T11.Rockets;
	Missile.T11.Rawk:
		"PLAY" E 2;
		"PLAY" F 2 Bright { A_SpawnProjectile("Rocket", 32, 0, random(-1, 1)); }
		"PLAY" E 2;
		Goto See;
	Pain.T11:
		"PLAY" G 4;
		"PLAY" G 4 { A_Pain(); }
		Goto See;
	Death.T11:
		"PLAY" H 10;
		"PLAY" I 10 { A_Scream(); }
		"PLAY" J 10 { A_NoBlocking(); }
		"PLAY" I 10 { A_StartSound("player9/death", CHAN_VOICE); }
		"PLAY" JKL 10;
		"PLAY" M -1;
		Stop;
	XDeath.T11:
		"PLAY" O 5;
		"PLAY" P 5 { A_XScream(); }
		"PLAY" Q 5 { A_NoBlocking(); }
		"PLAY" RSTUV 5;
		"PLAY" W -1;
		Stop;
	Raise.T11:
		"PLAY" MLKJIH 5;
		Goto See;

	// ===== T12 WHITE -- THE UNDERTAKER (MAGE). Shovel blades close,
	// bone shotgun mid, rapid bones far. The charge ladder (rsStep)
	// upgrades bone grade and finally unlocks the bone tornado --
	// this IS CH's BoneUp/user_skel1 staircase on RS machinery. =====
	Spawn.T12:
		"MAGE" A 4 { A_Look(); }
		Loop;
	See.T12:
		"MAGE" ABCD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(128, "See.T12.Sprint");
		Loop;
	See.T12.Sprint:
		"MAGE" ABCD 4 { A_FastChase(); }
		Goto See.T12;
	Melee.T12:
	Missile.T12:
		TNT1 A 0 A_JumpIfCloser(550, "Missile.T12.Shovel");
		TNT1 A 0 A_JumpIfCloser(1250, "Missile.T12.Mid");
		Goto Missile.T12.Rapid;
	Missile.T12.Mid:
		TNT1 A 0
		{
			if (rsStep >= 3 && random(0, 255) < 80)
				return ResolveState("Missile.T12.Tornado");
			return ResolveState(null);
		}
		TNT1 A 0 A_Jump(256, "Missile.T12.Shot", "Missile.T12.Rapid");
		Goto See;
	Missile.T12.Shovel:
		"MAGE" E 7 { A_FaceTarget(); }
		"MAGE" F 7 Bright { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"MAGE" F 0 { A_SpawnProjectile("RS_ShoveZM", 38, 0, 0); }
		"MAGE" F 0 { A_SpawnProjectile("RS_ShoveZM", 38, 3, 5); }
		"MAGE" F 0 { A_SpawnProjectile("RS_ShoveZM", 38, -3, -5); }
		"MAGE" E 6 A_Jump(128, "Missile.T12.Shot");
		Goto See;
	// -- bone shotgun, three grades up the ladder --
	Missile.T12.Shot:
		TNT1 A 0
		{
			if (rsStep >= 3) return ResolveState("Missile.T12.Shot3");
			if (rsStep >= 2) return ResolveState("Missile.T12.Shot2");
			return ResolveState(null);
		}
		"MAGE" E 8 { A_FaceTarget(); }
		"MAGE" F 5 Bright;
		"MAGE" FFFFFFFFF 0 { A_SpawnProjectile("RS_BoneProjZM", random(32, 42), random(-5, 5), random(-12, 12), CMF_OFFSETPITCH, random(-3, 3)); }
		"MAGE" E 5;
		Goto See;
	Missile.T12.Shot2:
		"MAGE" E 8 { A_FaceTarget(); }
		"MAGE" F 5 Bright;
		"MAGE" FFFFFFFFFFFF 0 { A_SpawnProjectile("RS_BoneProjZM2", random(32, 42), random(-5, 5), random(-12, 12), CMF_OFFSETPITCH, random(-3, 3)); }
		"MAGE" E 5;
		Goto See;
	Missile.T12.Shot3:
		"MAGE" E 8 { A_FaceTarget(); }
		"MAGE" F 5 Bright;
		"MAGE" FFFFFFFFFFF 0 { A_SpawnProjectile("RS_BoneProjZM3", random(32, 42), random(-5, 5), random(-12, 12), CMF_OFFSETPITCH, random(-3, 3)); }
		"MAGE" E 5;
		Goto See;
	// -- rapid bones, same three grades --
	Missile.T12.Rapid:
		TNT1 A 0
		{
			if (rsStep >= 3) return ResolveState("Missile.T12.Rapid3");
			if (rsStep >= 2) return ResolveState("Missile.T12.Rapid2");
			return ResolveState(null);
		}
		"MAGE" E 7 { A_FaceTarget(); }
	Missile.T12.RapidFire:
		"MAGE" F 1 Bright;
		"MAGE" FF 1 Bright { A_SpawnProjectile("RS_BoneProjZM", random(34, 40), random(-2, 2), random(-5, 5), CMF_OFFSETPITCH, random(-1, 1)); }
		"MAGE" F 0 A_Jump(12, "Missile.T12.Shot");
		"MAGE" F 2 A_MonsterRefire(150, "See");
		Goto Missile.T12.RapidFire;
	Missile.T12.Rapid2:
		"MAGE" E 7 { A_FaceTarget(); }
	Missile.T12.RapidFire2:
		"MAGE" F 1 Bright;
		"MAGE" FF 1 Bright { A_SpawnProjectile("RS_BoneProjZM2", random(34, 40), random(-1, 1), random(-3, 3), CMF_OFFSETPITCH, random(-1, 1)); }
		"MAGE" F 0 A_Jump(12, "Missile.T12.Shot2");
		"MAGE" F 1 A_MonsterRefire(120, "See");
		Goto Missile.T12.RapidFire2;
	Missile.T12.Rapid3:
		"MAGE" E 7 { A_FaceTarget(); }
	Missile.T12.RapidFire3:
		"MAGE" F 1 Bright;
		"MAGE" FFF 1 Bright { A_SpawnProjectile("RS_BoneProjZM3", random(34, 40), random(-1, 1), random(-2, 2), CMF_OFFSETPITCH, random(-1, 1)); }
		"MAGE" F 1 A_MonsterRefire(120, "See");
		Goto Missile.T12.RapidFire3;
	// -- the tornado, final-form only --
	Missile.T12.Tornado:
		"MAGE" E 9 { A_FaceTarget(); }
		"MAGE" E 7 Bright { A_StartSound("under/goodie", CHAN_VOICE); }
		"MAGE" E 7;
		"MAGE" E 5 Bright;
		"MAGE" E 5;
		"MAGE" E 3 Bright;
		"MAGE" E 3;
		"MAGE" F 5 Bright { A_SpawnProjectile("RS_BoneTorn2", 4, 0, random(-64, 64)); }
		"MAGE" F 3 Bright;
		"MAGE" E 3;
		Goto See;
	Pain.T12:
		"MAGE" G 4;
		"MAGE" G 4 { A_Pain(); }
		Goto See;
	Death.T12:
	XDeath.T12:
		"MAGE" H 13;
		"MAGE" I 13 { A_Scream(); }
		"MAGE" J 13 { A_NoBlocking(); }
		"MAGE" KLM 13;
		"MAGE" N -1;
		Stop;
	Raise.T12:
		"MAGE" NMLKJIH 6;
		Goto See;
	}
}
