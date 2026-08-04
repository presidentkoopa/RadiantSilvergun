// =====================================================================
// RS_PainElemental -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\10\10_<code>.txt
// One CHP file per colour; each is a genuinely different creature with
// its OWN sprite set, stats, and attack. Nothing here is inferred,
// tinted, or shared -- every tier below was read out of its CHP file.
// CH decorate/thepains.txt was consulted ONLY where CHP leaves a state
// undefined (noted per tier).
//
//   tier  CHP    body   HP    what it actually is
//   T00   10_C   PAIN    400  vanilla: bite, or a soul
//   T01   10_G   PAIG    500  green: a soul, or a wall of poison gas
//                             sown across the room inside 265 units
//   T02   10_B   PAIB    610  blue: a five-shot seeking plasma spray,
//                             or a double soul spit
//   T03   10_CY  PACY    963  cyan: twin bouncing ice orbs / a soul.
//                             It RESURRECTS the dead (A_VileChase) and
//                             on a successful raise it GROWS to double
//                             size and becomes a permanent soul
//                             fountain. Shatters on death.
//   T04   10_P   PAIP    790  purple: DUAL soul spit on a self-imposed
//                             budget, a purple triple, or one big
//                             seeking bomb
//   T05   10_Y   INFR    900  yellow volcano: bouncing lavaballs, the
//                             weaving firebomb pair, souls, and it
//                             erupts four lavaballs when it dies
//   T06   10_A   AYPE   1600  abyss skull: leaves afterimages, spams
//                             volleys, throws healing coils, spits
//                             abyss-baron souls, or fires a 36-shot
//                             360-degree pulse ring
//   T07   10_F   PAIF    800  fireblu: PainChance 0 -- it never
//                             flinches. Ram at range, boom breath
//                             inside 700, and a suicide detonation if
//                             it gets within 320
//   T08   10_BR  FLSP    800  brown flesh ball: leaks constantly,
//                             lurches sideways at random, hangs meat in
//                             the air and births a soul out of it, or
//                             fires a flesh shot
//   T09   10_GY  PAGR   1450  gray hive: speed 1, and it does nothing
//                             but pump out souls -- eight in a row on
//                             the DualPainAttack
//   T10   10_R   TORT   1111  red rage: a ten-shot corpse-breath fan, a
//                             triple spike bomb, a skull dash, or a soul
//   T11   10_K   OVER   5000  THE OVERLORD: cube bundles, the storm
//                             shot, hades/over-ball barrage, and below
//                             2500 HP it switches to bee swarms and the
//                             skull-death volley
//   T12   10_W   WATC   4000  THE MASTER SENTINEL: maintains its escort,
//                             drops buff and health fountains, and
//                             fires a red railgun
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
//
// RS mechanics preserved: the maintained sentinel escort (RS_TickEscort
// off Tick, T06+), DeathMorphClass into RS_PainPilot -- CHP only gives
// the WHITE elemental a second stage (CommonWhitePE3), so the gate moved
// from T11 to T12 -- MinionsDieWithMe, GetBaseKeywords.
//
// SOUL NOTE: CHP ships thirteen colour-specific lost souls
// (CommonGreenLSoul, CommonCyanLSoul, ...). RS already owns that ladder
// as RS_LostSoul's thirteen tiers, so every A_PainAttack/A_PainDie here
// names RS_LostSoul rather than adding a fourteenth soul family.
// =====================================================================

class RS_PainElemental : RS_MonsterMaster replaces PainElemental
{
	const RS_PE_TIER_ESCORT = 6;
	const RS_PE_TIER_HEAVY  = 9;
	const RS_PE_TIER_PILOT  = 12;   // CHP: only WHITE has a second stage

	const RS_PE_CHECK_INTERVAL = 70;   // 2s between escort headcounts

	private int rsNextEscortCheck;
	private int rsSlowdownBuddy;       // 10_P's user_slowdownbuddy

	Default
	{
		Health 400;
		Radius 31;
		Height 56;
		Mass 400;
		Speed 8;
		FloatSpeed 4;
		PainChance 128;
		Monster;
		+FLOAT +NOGRAVITY
		SeeSound "pain/sight";   PainSound "pain/pain";
		DeathSound "pain/death"; ActiveSound "pain/active";
		Tag "Pain Elemental";
	}

	// CHP's real per-colour numbers, read from 10_*.txt. Health is
	// absolute (not a multiplier) -- these are hand-tuned creatures.
	// T07's PainChance 0 and T09's Speed 1 are CHP's, not typos.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 128; r.dmgMul = 1.0;
		int hp = 400; int spd = 8;
		switch (t)
		{
			case 0:  hp = 400;  spd = 8;  r.painChance = 128; r.dmgMul = 1.0; break;
			case 1:  hp = 500;  spd = 8;  r.painChance = 112; r.dmgMul = 1.1; break;
			case 2:  hp = 610;  spd = 8;  r.painChance = 100; r.dmgMul = 1.2; break;
			case 3:  hp = 963;  spd = 17; r.painChance = 128; r.dmgMul = 1.4; break;
			case 4:  hp = 790;  spd = 6;  r.painChance = 128; r.dmgMul = 1.4; break;
			case 5:  hp = 900;  spd = 11; r.painChance = 128; r.dmgMul = 1.5; break;
			case 6:  hp = 1600; spd = 20; r.painChance = 80;  r.dmgMul = 1.8; break;
			case 7:  hp = 800;  spd = 20; r.painChance = 0;   r.dmgMul = 1.6; break;
			case 8:  hp = 800;  spd = 12; r.painChance = 128; r.dmgMul = 1.4; break;
			case 9:  hp = 1450; spd = 1;  r.painChance = 24;  r.dmgMul = 1.5; break;
			case 10: hp = 1111; spd = 11; r.painChance = 42;  r.dmgMul = 1.9; break;
			case 11: hp = 5000; spd = 14; r.painChance = 20;  r.dmgMul = 2.5; break;
			case 12: hp = 4000; spd = 28; r.painChance = 128; r.dmgMul = 3.0; break;
			default: return false;
		}
		// Default Health is 400, Default Speed 8 -- express CHP's absolute
		// numbers as multipliers so the base class's recompute-from-
		// defaults contract still holds.
		r.hpMul  = double(hp) / 400.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/PainElemental/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "PAIN PAIG PAIB PACY PAIP INFR AYPE PAIF FLSP PAGR TORT OVER WATC";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:painelemental role:summoner delivery:heavy element:thermal mobility:floating";
	}

	// The escort explicitly does NOT die with the summoner -- CHP goes
	// both ways on this and here the sentinels outliving their parent is
	// the better fight: killing the elemental doesn't instantly clear
	// the room, you still have to mop up.
	override bool MinionsDieWithMe()
	{
		return false;
	}

	// Death is a phase change at the top tier only. CHP's white
	// elemental drops CommonWhitePE3 -- "the Pilot" -- out of its own
	// wreckage; no other colour has a stage two.
	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_PE_TIER_PILOT) ? RS_MonsterCatalog.MORPH_PainPilot() : null;
	}

	// CHP scales two of these bodies in their own Default block
	// (BrownPE2 scale 2.0, RedPE scale 1.15). Scale is a Default
	// property and cannot be per-tier in one class, so it is applied on
	// the tier commit instead.
	override void OnTierApplied(int t)
	{
		if (t == 8)       Scale = (2.0, 2.0);
		else if (t == 10) Scale = (1.15, 1.15);
		else              Scale = (1.0, 1.0);
	}

	int EscortSize()
	{
		if (Tier >= RS_PE_TIER_HEAVY)  return 3;
		if (Tier >= RS_PE_TIER_ESCORT) return 2;
		return 0;
	}

	// -----------------------------------------------------------------
	// THE MAINTAINED ESCORT.
	// A headcount on a throttle, not every tic. If we're short, top up
	// by one -- one at a time, so a wiped escort refills visibly rather
	// than popping back in a single frame. This is what CHP's White
	// elemental does with MiniSentinelPE and A_CheckProximity; here it
	// runs off Tick so every escort-carrying tier gets it.
	// -----------------------------------------------------------------
	private void RS_TickEscort()
	{
		int want = EscortSize();
		if (want <= 0 || health <= 0)
			return;

		if (level.time < rsNextEscortCheck)
			return;
		rsNextEscortCheck = level.time + RS_PE_CHECK_INTERVAL;

		Class<Actor> cls = RS_MonsterCatalog.MINION_Sentinel();
		if (CountLiveMinions(cls) >= want)
			return;

		if (SummonMinion(cls, -2, 88.0, 16.0))
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	override void Tick()
	{
		Super.Tick();
		RS_TickEscort();
	}

	States
	{
	// ================= FAMILY-WIDE DISPATCHERS =================
	// The base class already routes Spawn/See/Missile/Melee/Pain/Death/
	// XDeath/Raise. These three are extra doors CHP's tiers knock on
	// that the base does not own: the cyan elemental's resurrect payoff,
	// the gray hive's fire-specific flinch, and the fireblu's
	// self-detonation exit.
	Heal:
		TNT1 A 0 { return TierState("Heal"); }
		Goto See;
	Pain.Fire:
		TNT1 A 0 { return TierState("Pain.Fire"); }
		Goto Pain;
	Death.Nocorpse:
		TNT1 A 0 { bCOUNTKILL = false; }
		Stop;

	// ================= T00 COMMON (10_C) =================
	Spawn.T00:
		"PAIN" A 10 { A_Look(); }
		Loop;
	See.T00:
		"PAIN" AABBCC 3 { A_Chase(); }
		Loop;
	Melee.T00:
		"PAIN" DEFE 3 { A_FaceTarget(); }
		"PAIN" D 3 { A_CustomMeleeAttack(random(8, 40), "Bite/bite4"); }
		Goto See;
	Missile.T00:
		"PAIN" D 5 { A_FaceTarget(); }
		"PAIN" E 5 { A_FaceTarget(); }
		"PAIN" F 4 Bright { A_FaceTarget(); }
		"PAIN" F 1 Bright { A_PainAttack("RS_LostSoul"); }
		Goto See;
	Pain.T00:
		"PAIN" G 6;
		"PAIN" G 6 { A_Pain(); }
		Goto See;
	Death.T00:
		"PAIN" H 8 Bright;
		"PAIN" I 8 Bright { A_Scream(); }
		"PAIN" JK 8 Bright;
		"PAIN" L 8 Bright { A_PainDie("RS_LostSoul"); }
		"PAIN" M 8 Bright;
		Stop;
	XDeath.T00:
		"PAIN" J 7 Bright { A_Pain(); }
		"PAIN" J 1 Bright { A_SetAngle(angle + 35); }
		"PAIN" J 7 Bright { A_Pain(); }
		"PAIN" J 1 Bright { A_SetAngle(angle - 90); }
		"PAIN" K 7 Bright;
		"PAIN" L 8 { A_StartSound("weapons/rocklx"); }
		"PAIN" M 8 Bright;
		Stop;
	Raise.T00:
		"PAIN" MLKJIH 8;
		Goto See;

	// ================= T01 GREEN (10_G) =================
	// Inside 265 units it stops shooting entirely and gasses the room.
	Spawn.T01:
		"PAIG" A 10 { A_Look(); }
		Loop;
	See.T01:
		"PAIG" AABBCC 3 { A_Chase(); }
		Loop;
	Melee.T01:
		"PAIG" DEFE 3 { A_FaceTarget(); }
		"PAIG" D 3 { A_CustomMeleeAttack(random(8, 40), "Bite/bite4"); }
		Goto See;
	Missile.T01:
		"PAIG" D 5 { A_FaceTarget(); }
		"PAIG" E 5 { A_FaceTarget(); }
		"PAIG" E 0 A_JumpIfCloser(265, "Missile.T01.Gas");
		Goto Missile.T01.Soul;
	Missile.T01.Soul:
		"PAIG" F 4 Bright { A_FaceTarget(); }
		"PAIG" F 1 Bright { A_PainAttack("RS_LostSoul"); }
		Goto See;
	Missile.T01.Gas:
		"PAIG" D 5 { A_StartSound("gas/gas1"); }
		"PAIG" G 5 { A_SpawnItemEx("RS_Gas13", random(-180, 180), random(-180, 180), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 4 { A_SpawnItemEx("RS_Gas13", random(-180, 180), random(-180, 180), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 3 { A_SpawnItemEx("RS_Gas13", random(-220, 220), random(-220, 220), random(-32, 64), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 2 { A_SpawnItemEx("RS_Gas13", random(-220, 220), random(-220, 220), random(-32, 64), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 1 { A_SpawnItemEx("RS_Gas13", random(-260, 260), random(-260, 260), random(-64, 88), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 0 { A_SpawnItemEx("RS_Gas13", random(-260, 260), random(-260, 260), random(-64, 88), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 1 { A_SpawnItemEx("RS_Gas13", random(-220, 220), random(-220, 220), random(-32, 64), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 2 { A_SpawnItemEx("RS_Gas13", random(-180, 180), random(-180, 180), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" G 3 { A_SpawnItemEx("RS_Gas13", random(-180, 180), random(-180, 180), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIG" A 4 { A_StartSound("Spell/Impact1"); }
		Goto See;
	Pain.T01:
		"PAIG" G 6;
		"PAIG" G 6 { A_Pain(); }
		Goto See;
	Death.T01:
		"PAIG" H 8 Bright;
		"PAIG" I 8 Bright { A_Scream(); }
		"PAIG" JK 8 Bright;
		"PAIG" L 8 Bright { A_PainDie("RS_LostSoul"); }
		"PAIG" M 8 Bright;
		Stop;
	XDeath.T01:
		"PAIG" J 7 Bright { A_Pain(); }
		"PAIG" J 1 Bright { A_SetAngle(angle + 35); }
		"PAIG" J 7 Bright { A_Pain(); }
		"PAIG" J 1 Bright { A_SetAngle(angle - 90); }
		"PAIG" K 7 Bright;
		"PAIG" L 8 { A_StartSound("weapons/rocklx"); }
		"PAIG" M 8 Bright;
		Stop;
	// CHP writes `Raise: Stop` for green and blue -- they do not come
	// back. Kept as authored.
	Raise.T01:
		Stop;

	// ================= T02 BLUE (10_B) =================
	Spawn.T02:
		"PAIB" A 10 { A_Look(); }
		Loop;
	See.T02:
		"PAIB" AABBCC 3 { A_Chase(); }
		Loop;
	Melee.T02:
		"PAIB" DEFE 3 { A_FaceTarget(); }
		"PAIB" D 3 { A_CustomMeleeAttack(random(8, 40), "Bite/bite4"); }
		Goto See;
	Missile.T02:
		"PAIB" DE 5 { A_FaceTarget(); }
		"PAIB" E 0 A_Jump(255, "Missile.T02.Soul", "Missile.T02.Plasma");
		Goto See;
	Missile.T02.Soul:
		"PAIB" F 4 Bright { A_FaceTarget(); }
		"PAIB" F 1 Bright { A_PainAttack("RS_LostSoul"); }
		"PAIB" EDE 8;
		"PAIB" F 3 Bright { A_PainAttack("RS_LostSoul", 0, PAF_NOSKULLATTACK); }
		Goto See;
	Missile.T02.Plasma:
		"PAIB" F 3 Bright;
		"PAIB" F 0 { A_SpawnProjectile("RS_PlasmaPE", 22, 0); }
		"PAIB" F 0 { A_SpawnProjectile("RS_PlasmaPE", 35, 0); }
		"PAIB" F 0 { A_SpawnProjectile("RS_PlasmaPE", 12, 0); }
		"PAIB" F 0 { A_SpawnProjectile("RS_PlasmaPE", 22, -12); }
		"PAIB" F 0 { A_SpawnProjectile("RS_PlasmaPE", 22, 12); }
		Goto See;
	Pain.T02:
		"PAIB" G 6;
		"PAIB" G 6 { A_Pain(); }
		Goto See;
	Death.T02:
		"PAIB" H 8 Bright;
		"PAIB" I 8 Bright { A_Scream(); }
		"PAIB" JK 8 Bright;
		"PAIB" L 8 Bright { A_PainDie("RS_LostSoul"); }
		"PAIB" M 8 Bright;
		Stop;
	XDeath.T02:
		"PAIB" J 7 Bright { A_Pain(); }
		"PAIB" J 1 Bright { A_SetAngle(angle + 35); }
		"PAIB" J 7 Bright { A_Pain(); }
		"PAIB" J 1 Bright { A_SetAngle(angle - 90); }
		"PAIB" K 7 Bright;
		"PAIB" L 8 { A_StartSound("weapons/rocklx"); }
		"PAIB" M 8 Bright;
		Stop;
	Raise.T02:
		Stop;

	// ================= T03 CYAN (10_CY) =================
	// It hunts CORPSES as well as you. A_VileChase means a successful
	// raise sends it to Heal, where it doubles in size, roots itself,
	// and becomes a permanent soul fountain (CHP's Turtle). PACY ships
	// no F frame; CHP never asks for one.
	Spawn.T03:
		"PACY" A 10 { A_Look(); }
		Loop;
	See.T03:
		"PACY" AA 2 { A_VileChase(); }
		TNT1 A 0 A_Jump(32, "See.T03.Fast");
		Goto See.T03;
	See.T03.Fast:
		"PACY" AAAAAAAAAA 1 { A_FastChase(); }
		Goto See.T03;
	Melee.T03:
		Goto Missile.T03;
	Missile.T03:
		"PACY" BC 5 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(85, "Missile.T03.Soul");
		"PACY" D 0 Bright { A_SpawnProjectile("RS_IceOrbCyanAra2", 24, 0, -5); }
		"PACY" D 0 Bright { A_SpawnProjectile("RS_IceOrbCyanAra2", 24, 0, 5); }
		"PACY" D 5 Bright { A_SpawnProjectile("RS_IceOrbCyanAra1", 24, 0, 0, 0, random(-3, 3)); }
		"PACY" DC 2;
		Goto See;
	Missile.T03.Soul:
		"PACY" D 5 Bright { A_PainAttack("RS_LostSoul"); }
		"PACY" DC 2;
		Goto See;
	Pain.T03:
		"PACY" E 3;
		"PACY" E 3 { A_Pain(); }
		"PACY" E 3;
		Goto See.T03.Fast;
	// The payoff for resurrecting something: it stops being a monster
	// and becomes terrain that births souls forever.
	Heal.T03:
		"PACY" BC 5 { A_FaceTarget(); }
		"PACY" D 5 { bNOPAIN = true; }
		"PACY" D 0 { bNODAMAGETHRUST = true; bDONTBLAST = true; bDONTTHRUST = true; }
		"PACY" D 0 { bNOGRAVITY = false; }
		"PACY" B 0 { A_StartSound("monster/infsit"); }
		"PACY" D 10 { A_SetScale(1.25, 1.0); }
		"PACY" D 10 { A_SetScale(1.5, 1.25); }
		"PACY" D 0 { A_SetSize(48, 80); }
		"PACY" D 10 { A_SetScale(1.75, 1.5); }
		"PACY" D 10 { A_SetScale(2.0, 1.5); }
		"PACY" D 3 { A_ChangeVelocity(0, 0, 8, CVF_REPLACE); }
	Heal.T03.Turtle:
		"PACY" CCCBBBAAABBBCCCDDDCCCBBBAAABBBCCCDDD 5;
		"PACY" DDD 30 { A_SpawnItemEx("RS_LostSoul", random(-16, 16), random(-16, 16), 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PACY" CCCBBBAAABBBCCCDDD 5;
		"PACY" B 0 { A_StartSound("caco/active"); }
		Loop;
	Death.T03:
		"PACY" G 8;
		"PACY" H 8 Bright { A_Scream(); }
		"PACY" I 8 Bright;
		"PACY" H 8 Bright { A_PainDie("RS_LostSoul"); }
		"PACY" G 8 Bright { A_NoBlocking(); }
		"PACY" G 1 { A_SetFloorClip(); }
		"PACY" G 0 { A_StartSound("misc/icebreak"); }
		"PACY" G 1 { A_Burst("IceChunk"); }
		Stop;
	XDeath.T03:
		"PACY" G 7 Bright { A_Pain(); }
		"PACY" G 1 Bright { A_SetAngle(angle + 35); }
		"PACY" H 7 Bright { A_Pain(); }
		"PACY" H 1 Bright { A_SetAngle(angle - 90); }
		"PACY" I 7 Bright;
		"PACY" J 8 { A_StartSound("weapons/rocklx"); }
		"PACY" K 8 Bright;
		Stop;

	// ================= T04 PURPLE (10_P) =================
	// The DUAL soul spit runs on a self-imposed budget: every use costs
	// one, pain refunds three, and past six it refuses and re-rolls.
	// CHP holds that in user_slowdownbuddy; here it is rsSlowdownBuddy.
	Spawn.T04:
		"PAIP" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"PAIP" AABBCC 3 { A_Chase(); }
		"PAIP" A 0 A_Jump(8, "Missile.T04.Soul");
		Loop;
	Missile.T04:
		"PAIP" D 10 { A_FaceTarget(); }
		"PAIP" E 6 { A_FaceTarget(); }
		"PAIP" E 0 A_JumpIfCloser(1200, "Missile.T04.Or1");
		"PAIP" E 0 A_Jump(256, "Missile.T04.Boom2");
		Goto See;
	Missile.T04.Or1:
		"PAIP" E 0 A_Jump(256, "Missile.T04.Soul", "Missile.T04.Boom1");
		Goto See;
	Missile.T04.Soul:
		TNT1 A 0 { if (rsSlowdownBuddy > 6) return ResolveState("Missile.T04.Maybe"); return ResolveState(null); }
		"PAIP" F 7 Bright { A_DualPainAttack("RS_LostSoul"); }
		"PAIP" D 6;
		"PAIP" D 0 { rsSlowdownBuddy++; }
		Goto See;
	Missile.T04.Maybe:
		"PAIP" F 0 A_CheckSight("See");
		Goto Missile.T04.Or1;
	Missile.T04.Boom1:
		"PAIP" E 0 { A_StartSound("Wraith/Wraith3/g"); }
		"PAIP" D 5 Bright { A_FaceTarget(); }
		"PAIP" D 0 { A_SpawnProjectile("RS_PurplePE2", 40, -8, -2); }
		"PAIP" D 0 { A_SpawnProjectile("RS_PurplePE2", 40, 0, 0); }
		"PAIP" D 0 { A_SpawnProjectile("RS_PurplePE2", 40, 8, 2); }
		Goto See;
	Missile.T04.Boom2:
		"PAIP" E 0 { A_StartSound("Spell/SpellCast1/g"); }
		"PAIP" D 5 { A_SpawnProjectile("RS_PurplePE1", 40, 0, 0); }
		Goto See;
	Pain.T04:
		"PAIP" G 3;
		"PAIP" G 0 { rsSlowdownBuddy = max(0, rsSlowdownBuddy - 3); }
		"PAIP" G 3 { A_Pain(); }
		Goto See;
	Death.T04:
		"PAIP" H 8;
		"PAIP" I 8 { A_Scream(); }
		"PAIP" JK 8;
		"PAIP" L 8 { A_Explode(random(15, 35), 64); }
		"PAIP" L 0 { A_PainDie("RS_LostSoul"); }
		"PAIP" M 8 { A_NoBlocking(); }
		"PAIP" N 8;
		Stop;
	XDeath.T04:
		"PAIP" J 7 Bright { A_Pain(); }
		"PAIP" J 1 Bright { A_SetAngle(angle + 35); }
		"PAIP" K 7 Bright { A_Pain(); }
		"PAIP" K 1 Bright { A_SetAngle(angle - 90); }
		"PAIP" L 7 Bright;
		"PAIP" M 8 { A_StartSound("weapons/rocklx"); }
		"PAIP" N 8 Bright;
		Stop;

	// ================= T05 YELLOW (10_Y) =================
	// Volcano elemental. Lavaballs, the crossing firebomb pair, souls
	// on a roll, and a four-way lavaball eruption when it dies.
	Spawn.T05:
		"INFR" A 10 { A_Look(); }
		Loop;
	See.T05:
		"INFR" A 3 { A_Chase(); }
		Loop;
	Missile.T05:
		"INFR" B 0 A_Jump(96, "Missile.T05.Hot");
		Goto Missile.T05.Volcano;
	Missile.T05.Volcano:
		"INFR" BC 5 { A_FaceTarget(); }
		"INFR" D 5 Bright { A_SpawnProjectile("RS_LavaballPE", 24, 0, 0, 0); }
		"INFR" D 2 A_Jump(96, "Missile.T05.Spawns");
		Goto See;
	Missile.T05.Hot:
		"INFR" BC 5 { A_FaceTarget(); }
		"INFR" D 0 { A_SpawnProjectile("RS_FirebombPE", 24, 0, 0, 0); }
		"INFR" D 5 Bright { A_SpawnProjectile("RS_FirebombPE2", 24, 0, 0, 0); }
		"INFR" D 2 A_Jump(128, "Missile.T05.Volcano");
		Goto See;
	Missile.T05.Spawns:
		"INFR" BC 5;
		"INFR" D 5 { A_PainAttack("RS_LostSoul"); }
		"INFR" D 0 A_CheckSight("See");
		Goto Missile.T05;
	Melee.T05:
		"INFR" ADC 3 { A_FaceTarget(); }
		"INFR" B 4 { A_CustomMeleeAttack(random(9, 48), "Caco/Melee2"); }
		Goto See;
	Pain.T05:
		"INFR" E 3;
		"INFR" E 3 { A_Pain(); }
		"INFR" E 6 A_Jump(128, "Missile.T05.Spawns");
		Goto See;
	Death.T05:
		"INFR" G 8;
		"INFR" H 8 Bright { A_Scream(); }
		"INFR" I 8 Bright;
		"INFR" I 0 { A_SpawnProjectile("RS_LavaballPE", 32, 0, 45, 2); }
		"INFR" I 0 { A_SpawnProjectile("RS_LavaballPE", 32, 0, 135, 2); }
		"INFR" I 0 { A_SpawnProjectile("RS_LavaballPE", 32, 0, 225, 2); }
		"INFR" I 0 { A_SpawnProjectile("RS_LavaballPE", 32, 0, 315, 2); }
		"INFR" J 8 Bright { A_PainDie("RS_LostSoul"); }
		"INFR" K 8 Bright { A_NoBlocking(); }
		"INFR" K 0 { A_SetFloorClip(); }
		Stop;

	// ================= T06 ABYSS (10_A) =================
	// Leaves an afterimage every other chase step. Four attack bands by
	// range; the closest is a 36-shot ring that fills the room.
	Spawn.T06:
		"AYPE" A 10 { A_Look(); }
		Loop;
	See.T06:
		"AYPE" AA 3 { A_Chase(); }
		"AYPE" A 0 { A_SpawnItemEx("RS_AbyssPEShadow", 3, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"AYPE" AA 3 { A_Chase(); }
		"AYPE" A 0 { A_SpawnItemEx("RS_AbyssPEShadow", 3, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Missile.T06:
		"AYPE" B 1 { A_StartSound("Ahead/at", CHAN_AUTO); }
		"AYPE" B 1 Bright { A_FaceTarget(); }
		"AYPE" B 1 A_JumpIfCloser(200, "Missile.T06.Pulse");
		"AYPE" B 1 A_JumpIfCloser(500, "Missile.T06.Choice1");
		"AYPE" B 1 A_JumpIfCloser(1200, "Missile.T06.Choice2");
	Missile.T06.Spam:
		"AYPE" B 1 { A_FaceTarget(); }
	Missile.T06.SpamLoop:
		"AYPE" B 8 { A_FaceTarget(); }
		"AYPE" AA 2 Bright { A_SpawnProjectile("RS_VollreyAbyPE", 32, random(-5, 5), random(-8, 8)); }
		"AYPE" B 2 { A_SpidRefire(); }
		Goto Missile.T06.SpamLoop;
	Missile.T06.Choice1:
		"AYPE" A 0 A_Jump(64, "Missile.T06.Pulse");
	Missile.T06.Choice2:
		"AYPE" A 0 A_Jump(256, "Missile.T06.Souls", "Missile.T06.Coil");
		Goto See;
	Missile.T06.Souls:
		"AYPE" B 3 { A_FaceTarget(); }
		"AYPE" C 8 Bright;
		"AYPE" CCC 6 { A_PainAttack("RS_AbyssBaronSoul"); }
		Goto See;
	Missile.T06.Coil:
		"AYPE" BDD 3 { A_FaceTarget(); }
		"AYPE" EEE 2 { A_SpawnProjectile("RS_AbyPECoil", 32, random(-15, 15), random(-18, 18)); }
		"AYPE" FED 8;
		Goto See;
	Missile.T06.Pulse:
		"AYPE" B 8 Bright { A_FaceTarget(); }
		"AYPE" A 5 Bright;
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 0); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 10); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 20); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 30); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 40); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 50); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 60); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 70); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 80); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 90); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 100); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 110); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 120); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 130); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 140); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 150); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 160); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 170); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 180); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 190); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 200); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 210); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 220); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 230); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 240); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 250); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 260); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 270); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 280); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 290); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 300); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 310); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 320); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 330); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 340); }
		"AYPE" A 0 { A_SpawnProjectile("RS_AbyssPEPulse", 12, 0, 350); }
		"AYPE" A 12 Bright;
		"AYPE" A 0 A_Jump(64, "Missile.T06");
		Goto See;
	// CHP falls out of Death with `Wait` and finishes in a Crash state
	// once the corpse lands. The base class owns no Crash dispatcher and
	// a family-wide one would swallow every other tier's corpse, so the
	// landing is inlined here instead.
	Death.T06:
		"AYPE" A 0 { bFLOATBOB = false; bFLOAT = false; }
		"AYPE" B 0 { bNOGRAVITY = false; }
		"AYPE" B 8 Bright { A_Stop(); }
		"AYPE" B 8 Bright { A_Scream(); }
		"AYPE" BBBB 8 Bright;
		"AYPE" B 8 Bright { A_NoBlocking(); }
		"AYPE" B 16;
		"MISL" X 0 { A_StartSound("weapons/rocklx", CHAN_5); }
		"MISL" XYZ 8 Bright;
		Stop;

	// ================= T07 FIREBLU (10_F) =================
	// PainChance 0: it does not flinch, ever. Getting inside 320 units
	// makes it kill itself on top of you.
	Spawn.T07:
		"PAIF" A 10 { A_Look(); }
		Loop;
	See.T07:
		"PAIF" AABBCC 3 { A_Chase(); }
		Loop;
	Melee.T07:
		"PAIF" DEFE 3 { A_FaceTarget(); }
		"PAIF" D 3 A_JumpIfCloser(320, "Melee.T07.Boom");
		Goto See;
	Melee.T07.Boom:
		"PAIF" H 5 Bright;
		"PAIF" I 5 Bright { A_Scream(); }
		"MISL" XYZ 4 Bright { A_Explode(random(20, 40), 64, 0); }
		TNT1 AAAAAAA 0 { A_SpawnItemEx("RS_BoomPEBlu2", random(-198, 198), random(-198, 198), random(-12, 64), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_PainDie("RS_LostSoul"); }
		TNT1 A 0 { A_Die("Nocorpse"); }
		Stop;
	Missile.T07:
		"PAIF" DE 5 { A_FaceTarget(); }
		"PAIF" F 4 Bright A_JumpIfCloser(700, "Missile.T07.Breath");
		"PAIF" F 5 Bright { A_SkullAttack(30); }
		Goto See;
	Missile.T07.Breath:
		"PAIF" F 8 Bright { A_SpawnProjectile("RS_BoomPEBlu", 42); }
		Goto See;
	Death.T07:
		"PAIF" H 8 Bright;
		"PAIF" I 8 Bright { A_Scream(); }
		"PAIF" J 8 Bright { A_Explode(random(20, 80), 64, 0); }
		"PAIF" K 8 Bright;
		"PAIF" AAAAAAAAA 0 { A_SpawnItemEx("RS_BoomPEBlu2", random(-198, 198), random(-198, 198), random(-12, 64), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAIF" L 8 Bright { A_PainDie("RS_LostSoul"); }
		"PAIF" M 8 Bright;
		Stop;

	// ================= T08 BROWN (10_BR) =================
	// A ball of wet meat. It leaks the whole time, lurches sideways at
	// random, and its main attack is hanging three lumps of itself in
	// the air before birthing a soul out of the mess.
	Spawn.T08:
		"FLSP" AB 8 { A_Look(); }
		Loop;
	See.T08:
		TNT1 AA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(-16, 16), random(-16, 16), random(5, 32)); }
		"FLSP" AA 2 { A_Chase(); }
		TNT1 AA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(-16, 16), random(-16, 16), random(5, 32)); }
		"FLSP" BB 2 { A_Chase(); }
		TNT1 A 0 A_Jump(32, "See.T08.Oi", "See.T08.Oi2");
		Loop;
	See.T08.Oi:
		"FLSP" A 15 { A_ChangeVelocity(0, 20, 0, CVF_RELATIVE); }
		"FLSP" B 6 { A_Stop(); }
		Goto See;
	See.T08.Oi2:
		"FLSP" A 15 { A_ChangeVelocity(0, -20, 0, CVF_RELATIVE); }
		"FLSP" B 6 { A_Stop(); }
		Goto See;
	Missile.T08:
		TNT1 AA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(-8, 8), random(-8, 8), random(5, 32)); }
		"FLSP" C 8 { A_FaceTarget(); }
		TNT1 AA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(-16, 16), random(-16, 16), random(5, 32)); }
		"FLSP" G 6 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(176, "Missile.T08.Shot");
		TNT1 A 0 { A_StartSound("ICKYPEBR", CHAN_AUTO); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(1, 8), random(-12, 12), random(28, 32), random(3, 12), 0, random(2, 6), random(-45, 45)); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownPEded", 12, 0, 24, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownPEded", 20, -14, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"FLSP" G 8 { A_SpawnItemEx("RS_BrownPEded", 16, 14, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_StartSound("ICKYPEBR", CHAN_AUTO); }
		"FLSP" H 12 Bright { A_PainAttack("RS_LostSoul"); }
		Goto See;
	Missile.T08.Shot:
		TNT1 AAAA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(1, 8), random(-8, 8), random(28, 32), random(3, 12), 0, random(2, 6), random(-45, 45)); }
		"FLSP" H 4 Bright { A_SpawnProjectile("RS_BrownPEShot", 32, 0, random(-1, 1)); }
		"FLSP" GC 8 Bright;
		Goto See;
	Melee.T08:
		"FLSP" CD 3 { A_FaceTarget(); }
		"FLSP" E 3 { A_CustomMeleeAttack(random(8, 12), "flesh/melee"); }
		TNT1 AA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(1, 8), random(-12, 12), random(28, 32), random(3, 12), 0, random(2, 6), random(-45, 45)); }
		"FLSP" FE 2 { A_CustomMeleeAttack(random(8, 12), "flesh/melee"); }
		TNT1 AA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(1, 8), random(-12, 12), random(28, 32), random(3, 12), 0, random(2, 6), random(-45, 45)); }
		"FLSP" FE 2 { A_CustomMeleeAttack(random(8, 12), "flesh/melee"); }
		Goto See;
	Pain.T08:
		"FLSP" I 3;
		TNT1 AAAA 0 { A_SpawnItemEx("RS_SplashBrownPE", random(-8, 8), random(-8, 8), random(5, 32), random(3, 12), 0, random(-2, 12), random(0, 360)); }
		"FLSP" I 3 { A_Pain(); }
		TNT1 A 0 A_Jump(128, "See.T08.Oi", "See.T08.Oi2");
		Goto See;
	Death.T08:
		"FLSP" I 5;
		"FLSP" J 5 { A_Scream(); }
		"FLSP" K 5;
		"FLSP" L 5 { A_NoBlocking(); }
		"FLSP" MN 5 { A_SetFloorClip(); }
		"FLSP" OOO 9 { A_FadeOut(0.25); }
		TNT1 AA 0 { A_SpawnItemEx("RS_BrownPEded", random(-12, 12), random(-12, 12), random(2, 24), random(1, 9), 0, random(0, 3), random(0, 360), SXF_NOCHECKPOSITION); }
		TNT1 AA 12 { A_SpawnItemEx("RS_BrownPEded", random(-12, 12), random(-12, 12), random(2, 24), random(1, 9), 0, random(0, 5), random(0, 360), SXF_NOCHECKPOSITION); }
		TNT1 AA 0 { A_SpawnItemEx("RS_BrownPEded", random(-12, 12), random(-12, 12), random(2, 24), random(1, 9), 0, random(0, 3), random(0, 360), SXF_NOCHECKPOSITION); }
		TNT1 AA 12 { A_SpawnItemEx("RS_BrownPEded", random(-12, 12), random(-12, 12), random(2, 24), random(1, 9), 0, random(0, 5), random(0, 360), SXF_NOCHECKPOSITION); }
		TNT1 A 25 { A_StartSound("ICKYPEBR", CHAN_AUTO); }
		TNT1 A 0 { A_StartSound("ICKYPEBR", CHAN_AUTO); }
		TNT1 AAA 21 { A_SpawnItemEx("RS_LostSoul", 0, 0, 16, random(1, 9), 0, random(8, 15), random(0, 360), SXF_NOCHECKPOSITION); }
		Stop;
	XDeath.T08:
		"FLSP" P 3;
		TNT1 A 0 { A_StartSound("misc/gibbed/c"); }
		"FLSP" Q 0 { A_FaceTarget(); }
		"FLSP" QQ 0 { A_SpawnItemEx("RS_FleshSpawnGibs", 0, 0, 0, 0, 0, 0, 0, 128); }
		"FLSP" Q 3;
		"FLSP" R 3 { A_NoBlocking(); }
		"FLSP" STU 3;
		Stop;

	// ================= T09 GRAY (10_GY) =================
	// The hive. Speed 1, PainChance 24, 1450 HP -- it barely moves and
	// exists only to flood the room with souls. Fire hurts it more, so
	// CHP gives it a longer fire-specific flinch.
	Spawn.T09:
		"PAGR" A 10 { A_Look(); }
		Loop;
	See.T09:
		"PAGR" A 4 { A_Chase(); }
		Loop;
	Missile.T09:
		"PAGR" BB 7 { A_FaceTarget(); }
		"PAGR" C 0 { A_StartSound("Wraith/Wraith3"); }
		"PAGR" C 0 A_Jump(192, "Missile.T09.Soul");
		Goto Missile.T09.Bug;
	Missile.T09.Soul:
		"PAGR" C 4 { A_PainAttack("RS_LostSoul"); }
		"PAGR" D 5;
		Goto See;
	Missile.T09.Bug:
		"PAGR" CCCCCCCC 1 { A_DualPainAttack("RS_LostSoul"); }
		"PAGR" D 5;
		Goto See;
	Pain.Fire.T09:
		"PAGR" E 6;
		"PAGR" E 12 Bright { A_Pain(); }
		"PAGR" E 6 Bright { A_Pain(); }
		Goto See;
	Pain.T09:
		"PAGR" E 1;
		"PAGR" E 3 { A_Pain(); }
		"PAGR" E 1 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAGR" E 1 { A_SpawnItemEx("RS_RedThingsLS", 5, 1, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAGR" E 1 { A_SpawnItemEx("RS_RedThingsLS", -3, 7, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAGR" E 1 { A_SpawnItemEx("RS_RedThingsLS", -9, 3, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"PAGR" E 1 A_Jump(128, "Missile.T09.Soul");
		Goto See;
	Death.T09:
		"PAGR" G 8;
		"PAGR" H 8 { A_Scream(); }
		"PAGR" I 8;
		"PAGR" X 2 { A_PainDie("RS_LostSoul"); }
		"PAGR" XXX 2 { A_SpawnItemEx("RS_LostSoul", random(-128, 128), random(-128, 128), 0, 0, 0, 0, 0, SXF_TRANSFERPOINTERS); }
		"PAGR" Y 8 { A_NoBlocking(); }
		"PAGR" Z 1;
		Stop;

	// ================= T10 RED (10_R) =================
	// Rage elemental. Four bands: corpse breath inside 450, soul or
	// spike-bomb triple inside 900, otherwise a skull dash. Both the
	// breath and the dash refire off A_MonsterRefire.
	Spawn.T10:
		"TORT" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"TORT" AABBCC 3 { A_Chase(); }
		"TORT" A 0 A_Jump(34, "Missile.T10.Soul");
		Loop;
	Missile.T10:
		"TORT" B 5 { A_FaceTarget(); }
		"TORT" B 2 { A_FaceTarget(); }
		"TORT" B 0 A_JumpIfCloser(450, "Missile.T10.Breath");
		"TORT" B 0 A_JumpIfCloser(900, "Missile.T10.Or1");
		"TORT" B 0 A_Jump(256, "Missile.T10.Dash");
		Goto See;
	Missile.T10.Or1:
		"TORT" E 0 A_Jump(256, "Missile.T10.Soul", "Missile.T10.Boom1");
		Goto See;
	Missile.T10.Breath:
		"TORT" C 5 { A_FaceTarget(); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, 16, 1); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, 12, 1); }
		"TORT" C 0 { A_FaceTarget(); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, 8, 1); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, 4, 1); }
		"TORT" C 0 { A_FaceTarget(); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, 0, 1); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, -4, 1); }
		"TORT" C 0 { A_FaceTarget(); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, -8, 1); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, -12, 1); }
		"TORT" C 0 { A_FaceTarget(); }
		"TORT" D 3 Bright { A_SpawnProjectile("RS_CorpseBreathPE", 21, 0, -16, 1); }
		"TORT" C 4 Bright;
		"TORT" C 1 Bright A_MonsterRefire(84, "See");
		Goto Missile.T10;
	Missile.T10.Soul:
		"TORT" C 9 Bright { A_PainAttack("RS_LostSoul"); }
		"TORT" D 5;
		Goto See;
	Missile.T10.Boom1:
		"TORT" C 0 { A_StartSound("Wraith/Wraith3"); }
		"TORT" C 4 Bright;
		"TORT" C 0 { A_SpawnProjectile("RS_SbombPE", 32, -8, -2); }
		"TORT" C 0 { A_SpawnProjectile("RS_SbombPE", 20, 0, 0); }
		"TORT" C 0 { A_SpawnProjectile("RS_SbombPE", 32, 8, 2); }
		Goto See;
	Missile.T10.Dash:
		"TORT" D 0 { A_StartSound("wraith/wraith2"); }
		"TORT" D 4 { A_SkullAttack(30); }
		"TORT" D 1 Bright A_MonsterRefire(84, "See");
		Goto Missile.T10;
	Pain.T10:
		"TORT" G 1;
		"TORT" G 3 { A_Pain(); }
		"TORT" G 1 { A_SpawnItemEx("RS_RedThingsLS", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"TORT" G 1 { A_SpawnItemEx("RS_RedThingsLS", 5, 1, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"TORT" G 1 { A_SpawnItemEx("RS_RedThingsLS", -3, 7, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"TORT" G 1 { A_SpawnItemEx("RS_RedThingsLS", -9, 3, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"TORT" G 1 A_Jump(128, "Missile.T10.Soul");
		Goto See;
	Death.T10:
		"TORT" H 8;
		"TORT" I 8 { A_Scream(); }
		"MISL" X 8 { A_StartSound("weapons/rocklx", CHAN_5); }
		"MISL" Y 8 { A_Explode(random(15, 65), 128); }
		"MISL" Z 8 { A_NoBlocking(); }
		Stop;

	// ================= T11 BLACK -- THE OVERLORD (10_K) =================
	// Below 2500 HP it stops using the cube/hades patterns and switches
	// to the bee swarm and the six-way skull-death volley. Its death
	// throws its own arms, horns and flesh across the room.
	Spawn.T11:
		"OVER" A 10 { A_Look(); }
		Loop;
	See.T11:
		"OVER" AABBAACC 3 { A_Chase(); }
		Loop;
	Missile.T11:
		"OVER" D 0 { A_FaceTarget(); }
		"OVER" D 0 A_JumpIfHealthLower(2500, "Missile.T11.Phase2");
		"OVER" D 0 A_Jump(256, "Missile.T11.M2", "Missile.T11.M3", "Missile.T11.M1");
		Goto See;
	Missile.T11.Phase2:
		"OVER" D 0 A_Jump(256, "Missile.T11.M4", "Missile.T11.M2", "Missile.T11.M5");
		Goto See;
	Missile.T11.M1:
		"OVER" DE 8 { A_FaceTarget(); }
		"OVER" FF 5 Bright { A_SpawnProjectile("RS_SkullBundle3", 32, 0, random(-10, 10)); }
		Goto See;
	Missile.T11.M2:
		"OVER" GH 8 Bright { A_FaceTarget(); }
		"OVER" H 1 Bright { A_StartSound("weapons/shock"); }
		"OVER" H 7 Bright { A_SpawnProjectile("RS_StormShot1", 43, 0, 0, 0, 0); }
		Goto See;
	Missile.T11.M3:
		"OVER" JJJJJJJJ 1 { A_FaceTarget(); }
	Missile.T11.M3Loop:
		"OVER" K 0 Bright { A_SpawnProjectile("RS_HadesBall4", 92, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 0 Bright { A_SpawnProjectile("RS_HadesBall4", 8, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 0 Bright { A_SpawnProjectile("RS_HadesBall4", 92, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 0 Bright { A_SpawnProjectile("RS_HadesBall4", 8, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 0 Bright { A_SpawnProjectile("RS_OverBall3", 54, -50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 4 Bright { A_SpawnProjectile("RS_OverBall3", 54, 50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" J 7 { A_SpidRefire(); }
		"OVER" J 0 A_Jump(32, "Missile.T11.M1");
		Goto Missile.T11.M3Loop;
	Missile.T11.M4:
		"OVER" JJJJJJJJ 1 { A_FaceTarget(); }
		"OVER" GHG 3 Bright;
		"OVER" K 4 Bright;
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 92, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 8, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 92, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 8, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 54, -50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 4 Bright { A_SpawnProjectile("RS_BEESHOT", 54, 50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" G 3 Bright A_CheckSight("See");
		"OVER" K 4 Bright;
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 92, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 8, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 92, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 8, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_BEESHOT", 54, -50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 4 Bright { A_SpawnProjectile("RS_BEESHOT", 54, 50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 0 A_Jump(88, "Missile.T11.M1");
		Goto See;
	Missile.T11.M5:
		"OVER" JJJJJJJJ 1 { A_FaceTarget(); }
		"OVER" GG 5 { A_FaceTarget(); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_LoadPE3", 92, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_LoadPE3", 8, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_LoadPE3", 92, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_LoadPE3", 8, 40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_LoadPE3", 54, -50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 1 Bright { A_SpawnProjectile("RS_LoadPE3", 54, 50, random(-3, 3), 0, random(-3, 3)); }
		"OVER" K 8 { A_FaceTarget(); }
		"OVER" H 4 { A_StartSound("monster/ovlsit"); }
		"OVER" H 2 Bright { A_SpawnProjectile("RS_SkullDeathPE", 92, -40, random(-8, 8), 0, random(-8, 8)); }
		"OVER" H 2 Bright { A_SpawnProjectile("RS_SkullDeathPE", 8, -40, random(-3, 3), 0, random(-3, 3)); }
		"OVER" H 2 Bright { A_SpawnProjectile("RS_SkullDeathPE", 92, 40, random(-12, 12), 0, random(-3, 3)); }
		"OVER" H 2 Bright { A_SpawnProjectile("RS_SkullDeathPE", 8, 40, random(-3, 9), 0, random(-9, 3)); }
		"OVER" H 2 Bright { A_SpawnProjectile("RS_SkullDeathPE", 54, -50, random(-9, 9), 0, random(-3, 3)); }
		"OVER" H 2 Bright { A_SpawnProjectile("RS_SkullDeathPE", 54, 50, random(-3, 3), 0, random(-12, 12)); }
		"OVER" GJ 2;
		Goto See;
	Melee.T11:
		"OVER" ADF 4 { A_FaceTarget(); }
		"OVER" E 4 { A_CustomMeleeAttack(20, "caco/melee"); }
		"OVER" E 0 A_Jump(128, "Missile");
		Goto See;
	Pain.T11:
		"OVER" L 6;
		"OVER" L 6 { A_Pain(); }
		Goto See;
	Death.T11:
		"OVER" M 1 Bright { A_FaceTarget(); }
		"OVER" M 9 Bright { A_ScreamAndUnblock(); }
		"OVER" NO 10 Bright;
		"OVER" PPPPP 0 Bright { A_SpawnProjectile("RS_OverFlesh1", random(0, 90), random(0, 40), random(-180, 180), 2, random(-15, 15)); }
		"OVER" PPPPP 0 Bright { A_SpawnProjectile("RS_OverFlesh2", random(0, 90), random(0, 40), random(-180, 180), 2, random(-15, 15)); }
		"OVER" PPPPPPPPPP 0 { A_SpawnProjectile("RS_OverFlesh3", random(0, 90), random(0, 40), random(-180, 180), 2, random(-15, 15)); }
		"OVER" PPPPPPPPPP 0 { A_SpawnProjectile("RS_OverFlesh4", random(0, 90), random(0, 40), random(-180, 180), 2, random(-15, 15)); }
		"OVER" PPPPPPPPPP 0 { A_SpawnProjectile("RS_OverFlesh5", random(0, 90), random(0, 40), random(-180, 180), 2, random(-15, 15)); }
		"OVER" PPPPPPPPPP 0 { A_SpawnProjectile("RS_OverFlesh6", random(0, 90), random(0, 40), random(-180, 180), 2, random(-15, 15)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverBigArm1", 40, -40, -90, 2, random(-1, 1)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverBigArm2", 40, 40, 90, 2, random(-1, 1)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverSmallArm1", 100, -30, -90, 2, random(-15, 15)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverSmallArm1", 100, 30, 90, 2, random(-15, 15)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverSmallArm2", 100, -30, -90, 2, random(-15, 15)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverSmallArm2", 100, 30, 90, 2, random(-15, 15)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverHorn1", 110, -16, -90, 2, random(-15, 15)); }
		"OVER" P 0 Bright { A_SpawnProjectile("RS_OverHorn2", 110, 16, 90, 2, random(-15, 15)); }
		"OVER" PQRSTUV 10 Bright;
		Stop;

	// ============ T12 WHITE -- THE MASTER SENTINEL (10_W) ============
	// The escort IS this creature. RS_TickEscort keeps the headcount up
	// off Tick; the blocks below add CHP's own top-ups when it notices a
	// gap, plus the buff drop, the health fountains, and the railgun.
	Spawn.T12:
		"WATC" X 0
		{
			SummonMinion(RS_MonsterCatalog.MINION_Sentinel(), -2, 48.0, 12.0);
			SummonMinion(RS_MonsterCatalog.MINION_Sentinel(), -2, 48.0, 12.0);
		}
	Spawn.T12.Idle:
		"WATC" X 2 { A_Look(); }
		Loop;
	See.T12:
		"WATC" XXX 2 { A_Chase(); }
		TNT1 A 0 A_Jump(32, "See.T12.Buff");
		"WATC" XXX 2 { A_Chase(); }
		"WATC" X 1 A_CheckProximity("See.T12.ReEye", "RS_PainSentinel", 128, 1, CPXF_LESSOREQUAL);
		TNT1 A 0 A_Jump(16, "See.T12.Wander");
		"WATC" XXX 2 { A_Chase(); }
		Loop;
	See.T12.ReEye:
		"WATC" XXXXXX 6 { SummonMinion(RS_MonsterCatalog.MINION_Sentinel(), -2, 48.0, 12.0); }
		Goto See;
	See.T12.Wander:
		"WATC" XXXXXXXXX 2 { A_Wander(); }
		Goto See;
	See.T12.Buff:
		"WATC" X 1;
		"WATC" Y 5;
		"WATC" W 5 { A_SpawnItemEx("RS_BufferWhitePE", random(-64, 64), random(-64, 64), random(-4, 6), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 A_Jump(32, "See.T12.Wander");
		Goto See;
	Missile.T12:
		"WATC" X 2 { SummonMinion(RS_MonsterCatalog.MINION_Sentinel(), -2, 48.0, 12.0); }
		"WATC" Y 5 { A_SetScale(0.9, 1.1); }
		"WATC" W 5 { A_SetScale(1.0, 1.0); }
		TNT1 A 0 A_Jump(256, "Missile.T12.Fountains", "Missile.T12.Beams");
		Goto See;
	Missile.T12.Fountains:
		"WATC" V 10 Bright { A_SpawnItemEx("RS_HealthFountainWhitePE", random(-266, 266), random(-266, 266), random(1, 6), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Missile.T12.Beams:
		"WATC" W 6 { A_FaceTarget(); }
		"WATC" V 0 { A_StartSound("weapons/railgf"); }
		"WATC" V 5 Bright
		{
			A_CustomRailgun(random(30, 60), 0, 0xFF0000, 0xFF0000,
			                RGF_FULLBRIGHT | RGF_SILENT, 1, 0, "RS_NothinPuff",
			                0, 0, 0, 60, 0.5, 0.2, "RS_DFlarePE", 3);
		}
		Goto See;
	Pain.T12:
		"WATC" Y 3;
		"WATC" Y 3 { A_Pain(); }
		"WATC" Y 6 { SummonMinion(RS_MonsterCatalog.MINION_Sentinel(), -2, 48.0, 12.0); }
		Goto See;
	Death.T12:
		"WATC" V 3 Bright;
		"WATC" V 3 Bright { A_Scream(); }
		"WATC" V 3 Bright { A_NoBlocking(); }
		"WATC" V 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 100, -30, 0, 2, -10); }
		"WATC" V 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 100, 50, 0, 2, 10); }
		"WATC" V 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 20, 30, 0, 2, 10); }
		"WATC" V 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 60, 5, 0, 2, -10); }
		"WATC" VVVV 4 Bright { A_SpawnProjectile("RS_HKRedDeath", random(15, 90), random(-50, 50), 0, 2, random(-10, 10)); }
		"WATC" VVVV 3 Bright { A_SpawnProjectile("RS_HKRedDeath", random(15, 90), random(-50, 50), 0, 2, random(-10, 10)); }
		"WATC" VVVV 2 Bright { A_SpawnProjectile("RS_HKRedDeath", random(15, 90), random(-50, 50), 0, 2, random(-10, 10)); }
		"WATC" VVVVV 1 Bright { A_SpawnProjectile("RS_HKRedDeath", random(15, 90), random(-50, 50), 0, 2, random(-10, 10)); }
		TNT1 A 0 { A_SetScale(2.0, 2.0); }
		"MISL" BCD 5 Bright;
		Stop;
	}
}

// =====================================================================
// RS_PainPilot -- what was actually flying the thing.
// ---------------------------------------------------------------------
// CHP's CommonWhitePE3 (10_W.txt): the stage two the Master Sentinel
// drops out of its own wreckage. Smaller, much faster (speed 46), no
// longer summons -- it trades the escort for a triple-flare railgun, so
// the fight changes character rather than repeating with a second
// health bar.
//
// CHP ships exactly ONE pilot, so the body table is one body across the
// whole ladder and the single T00 cluster serves every tier through the
// base class's fallback. No runtime sprite, no #### -- WATC is a literal
// token on every line below.
// =====================================================================

class RS_PainPilot : RS_MonsterMaster
{
	Default
	{
		Health 1000;
		Radius 24;
		Height 40;
		Mass 150;
		Speed 46;
		FloatSpeed 15;
		PainChance 128;
		Monster;
		+FLOAT +NOGRAVITY +MISSILEMORE +AVOIDMELEE +DONTHARMSPECIES
		+NOICEDEATH +DONTBLAST +DONTTHRUST
		Species "PE";
		SeeSound "pain/sight";   PainSound "pain/pain";
		DeathSound "pain/death"; ActiveSound "pain/active";
		Tag "Pain Elemental (Pilot)";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "WATC WATC WATC WATC WATC WATC WATC WATC WATC WATC WATC WATC WATC";
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:painelemental role:skirmisher delivery:heavy element:thermal mobility:flying trait:secondstage";
	}

	States
	{
	Spawn.T00:
		"WATC" A 10 { A_Look(); }
		Loop;
	See.T00:
		"WATC" AAA 3 { A_Chase(); }
		TNT1 A 0 A_Jump(24, "See.T00.Buff");
		"WATC" AAA 3 { A_FastChase(); }
		Loop;
	See.T00.Wander:
		"WATC" AAAAAAAAA 2 { A_Wander(); }
		Goto See;
	See.T00.Buff:
		"WATC" B 3;
		"WATC" C 4;
		"WATC" D 5 { A_SpawnItemEx("RS_BufferWhitePE", random(-64, 64), random(-64, 64), random(-4, 6), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_SpawnItemEx("RS_HealthFountainWhitePE", random(-266, 266), random(-266, 266), random(1, 6), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 A_Jump(64, "See.T00.Wander");
		Goto See;
	Missile.T00:
		"WATC" EF 5 { A_FaceTarget(); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, 0); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, random(-3, 3)); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, random(-9, 9)); }
		"WATC" G 0 { A_StartSound("weapons/railgf"); }
		"WATC" G 5 Bright
		{
			A_CustomRailgun(random(30, 60), 0, 0xFF0000, 0xFF0000,
			                RGF_FULLBRIGHT | RGF_SILENT, 1, 0, "RS_NothinPuff",
			                0, 0, 0, 60, 0.5, 0.2, "RS_DFlarePE", 7);
		}
		"WATC" F 5 { A_FaceTarget(); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, 0); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, random(-3, 3)); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, random(-9, 9)); }
		"WATC" G 0 { A_StartSound("weapons/railgf"); }
		"WATC" G 5 Bright
		{
			A_CustomRailgun(random(30, 60), 0, 0xFF0000, 0xFF0000,
			                RGF_FULLBRIGHT | RGF_SILENT, 1, 0, "RS_NothinPuff",
			                0, 0, 0, 60, 0.5, 0.2, "RS_DFlarePE", 7);
		}
		"WATC" F 5 { A_FaceTarget(); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, 0); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, random(-3, 3)); }
		"WATC" G 0 { A_SpawnProjectile("RS_DFlarePE", 15, 0, random(-9, 9)); }
		"WATC" G 0 { A_StartSound("weapons/railgf"); }
		"WATC" G 5 Bright
		{
			A_CustomRailgun(random(30, 60), 0, 0xFF0000, 0xFF0000,
			                RGF_FULLBRIGHT | RGF_SILENT, 1, 0, "RS_NothinPuff",
			                0, 0, 0, 60, 0.5, 0.2, "RS_DFlarePE", 7);
		}
		Goto See;
	Pain.T00:
		"WATC" H 3;
		"WATC" H 3 { A_Pain(); }
		"WATC" H 1 A_Jump(64, "See.T00.Wander");
		Goto See;
	Death.T00:
		"WATC" I 8 { A_Scream(); }
		"WATC" JKLM 6;
		"WATC" N 6 { A_NoBlocking(); }
		TNT1 A 0 { bFLOATBOB = false; }
		"WATC" N 0 { A_SetFloorClip(); }
		"WATC" O -1;
		Stop;
	}
}
