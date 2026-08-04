// =====================================================================
// RS_Mastermind -- rebuilt from Colourful Hell Plus family 16, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\16\16_<code>.txt
// One CHP file per colour; the FIRST actor in each file is the creature
// (Common<Colour>Mind). Each is a genuinely different boss with its own
// sprite set, stats and attack kit. Nothing here is inferred or tinted.
// CH (decorate\MASTERMINDS.txt) was consulted only where CHP leaves a
// state undefined -- noted inline where that happened.
//
//   tier CHP    parent (CH)   body   HP     what it actually is
//   T00  16_C   CommonMind    SPID    3000  vanilla mind: twin shotgun bursts
//   T01  16_G   GreenMind     SPIG    3750  green: poison spider-shot pair
//   T02  16_B   BlueMind      SPIB    4800  frost: breath / orbs / long lances
//   T03  16_CY  CyanMind2     SPCY    4444  cyanide: floats, blinks, ice storm
//   T04  16_P   PurpleMind    DEMO    6100  queen: bullets, orb wall, spider adds
//   T05  16_Y   YellowMind    SUPS    7777  supreme: plasma, BFG fan, homing bombs
//   T06  16_A   AbyssMind2    AMIN   12222  abyss: tentacles, mind waves, floorbreak
//   T07  16_F   FirebluMind2  SPIF    5100  eyesore: fireblu flames, hardens at 3000
//   T08  16_BR  BrownMind2    B05P    5000  death'n'decay: bone orbs, spikes, devour
//   T09  16_GY  GrayMind2     SPGY    6000  rocky road: rock chaingun, nail storm
//   T10  16_R   RedMind       APYT    9001  arachnophyte: railguns, saws, phase 2
//   T11  16_K   BlackMind2    ARNQ   11111  pseudo old god: waves, psyche, summons
//   T12  16_W   (standalone)  W5PD   20000  EVERLASTING: three phases + flight
//
// Tier stats are CHP's own Health/Speed/PainChance per file, applied
// through TierData below (expressed as multipliers off this class's
// Default so the base class's recompute contract still holds).
//
// CHP CRUFT STRIPPED (per port rules): NewIcon*/ColorTierIcon* spawns,
// the ACS Announce/Scripted states, CallACS/ACS_NamedExecute*,
// A_GivetoChildren("GoAway")/A_KillMaster/A_KillChildren (RS types its
// minions -- ReleaseMinions() does that job), RandomLetterSpawner,
// A_SpawnParticle walls, CH_Cirno death gags, and the CHP inventory
// tokens used purely as self-latches (now private int fields, the same
// treatment rsPhase2Done gets in RS_Cacodemon.zs).
//
// DELIBERATE REDUCTIONS (all cosmetic, none of them an attack):
//   T06 AbyssMindWalk footfall decals and the WVileSpot pain-ritual
//       (that ritual is CHP-14 white-archvile content with eight further
//       dependencies; the tier's attacks are all present).
//   T08 RedMessMindB gore spray and the MediCacoBrown medkit scatter.
//   T12 ESShade after-images, ESFlyDummy flight motes, WhiteMindFlare
//       muzzle glints.
//   T06 See used sprite AMIN for frames K/L/M, which AMIN does not have
//       (A-I only); those lines are ANIM, which does. Same artwork set.
// =====================================================================

class RS_Mastermind : RS_MonsterMaster replaces SpiderMastermind
{
	// CHP user vars, rewritten as fields (A_SetUserVar is stripped).
	private int rsRageMind;      // T04 User_Ragemind
	private int rsHalpMe;        // T05 User_HalpMe
	private int rsToughUp;       // T07 one-shot hardening below 3000
	private int rsDewzan;        // T08 DewzanToken (bone shield, once)
	private int rsPhase2;        // T10 User_Phase2
	private int rsScree;         // T11 user_sce
	private int rsEverlasting;   // T12 user_everlasting
	private int rsChaotic;       // T12 user_chaotic
	private int rsCamo;          // T12 user_camo
	private int rsFlight;        // T12 FlightToken
	private int rsShield;        // T12 ESCHProtect

	Default
	{
		Health 3000;
		Radius 100;
		Height 100;
		Mass 1000;
		Speed 12;
		PainChance 40;
		Monster;
		Species "MMind";
		RadiusDamageFactor 0.25;
		+BOSS +MISSILEMORE +FLOORCLIP +BOSSDEATH
		+DONTMORPH +DONTHARMSPECIES +NOFEAR
		-NORADIUSDMG
		SeeSound "spider/sight";   AttackSound "spider/attack";
		PainSound "spider/pain";   DeathSound "spider/death";
		ActiveSound "spider/active";
		Obituary "$OB_SPIDER";
		Tag "Spider Mastermind";
	}

	// CHP's real per-colour numbers, read out of 16_*.txt. Health and
	// Speed are absolute in CHP; converted to multipliers off the
	// Default block (Health 3000, Speed 12).
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 40; r.dmgMul = 1.0;
		int hp = 3000; int spd = 12;
		switch (t)
		{
			case 0:  hp = 3000;  spd = 12; r.painChance = 40; r.dmgMul = 1.0; break;
			case 1:  hp = 3750;  spd = 12; r.painChance = 40; r.dmgMul = 1.1; break;
			case 2:  hp = 4800;  spd = 18; r.painChance = 25; r.dmgMul = 1.2; break;
			case 3:  hp = 4444;  spd = 21; r.painChance = 10; r.dmgMul = 1.3; break;
			case 4:  hp = 6100;  spd = 12; r.painChance = 20; r.dmgMul = 1.4; break;
			case 5:  hp = 7777;  spd = 12; r.painChance = 10; r.dmgMul = 1.5; break;
			case 6:  hp = 12222; spd = 21; r.painChance = 48; r.dmgMul = 1.7; break;
			case 7:  hp = 5100;  spd = 21; r.painChance = 40; r.dmgMul = 1.5; break;
			case 8:  hp = 5000;  spd = 16; r.painChance = 64; r.dmgMul = 1.4; break;
			case 9:  hp = 6000;  spd = 9;  r.painChance = 40; r.dmgMul = 1.5; break;
			case 10: hp = 9001;  spd = 18; r.painChance = 1;  r.dmgMul = 1.9; break;
			case 11: hp = 11111; spd = 20; r.painChance = 45; r.dmgMul = 2.4; break;
			case 12: hp = 20000; spd = 24; r.painChance = 0;  r.dmgMul = 3.0; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 3000.0;
		r.spdMul = double(spd) / 12.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SPID SPIG SPIB SPCY DEMO SUPS AMIN SPIF B05P SPGY APYT ARNQ W5PD";
	}

	// CHP ships bespoke artwork per colour -- a palette remap on top of
	// hand-drawn art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:mastermind role:boss delivery:bullet element:kinetic mobility:ground";
	}

	// T11's portal roster. CHP's PortalSummons2_C is a RandomSpawner
	// over ten CH monsters (revenants, lost souls, tentacles, spiders,
	// spectres, demons, cacodemons); this is that spread mapped onto the
	// RS families present in this tree. Comparison chain, not a static
	// const array -- those do not resolve reliably on this build.
	private Class<Actor> BlackPortalPick(int i)
	{
		if (i <= 0) return "RS_Revenant";
		if (i == 1) return "RS_LostSoul";
		if (i == 2) return "RS_BaronTentacle";
		if (i == 3) return "RS_Arachnotron";
		if (i == 4) return "RS_Spectre";
		if (i == 5) return "RS_Demon";
		return "RS_Cacodemon";
	}

	// Ground tiers must undo the flight flags a floating tier may have
	// set, or a retier leaves a walker hovering.
	private void RS_GroundStance()
	{
		bFLOAT = false; bFLOATBOB = false; bNOGRAVITY = false;
	}

	private void RS_FlyStance()
	{
		bFLOAT = true; bFLOATBOB = true; bNOGRAVITY = true;
	}

	States
	{
	// ================= T00 COMMON (16_C) =================
	// Vanilla mind: two shotgun bursts and A_SpidRefire.
	Spawn.T00:
		"SPID" AB 10 { A_Look(); }
		Loop;
	See.T00:
		TNT1 A 0 { RS_GroundStance(); }
		"SPID" A 0 { A_Chase(); }
		"SPID" A 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPID" ABB 3 { A_Chase(); }
		"SPID" A 0 { A_Chase(); }
		"SPID" C 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPID" CDD 3 { A_Chase(); }
		"SPID" A 0 { A_Chase(); }
		"SPID" E 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPID" EFF 3 { A_Chase(); }
		Loop;
	Missile.T00:
		"SPID" A 20 Bright { A_FaceTarget(); }
	Missile.T00.Burst:
		"SPID" G 0 { A_StartSound("shotguy/attack", CHAN_WEAPON); }
		"SPID" G 4 Bright { A_CustomBulletAttack(22.5, 0, 3, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"SPID" H 0 { A_StartSound("shotguy/attack", CHAN_WEAPON); }
		"SPID" H 4 Bright { A_CustomBulletAttack(22.5, 0, 3, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"SPID" H 1 Bright A_SpidRefire;
		Goto Missile.T00.Burst;
	Pain.T00:
		"SPID" I 3;
		"SPID" I 3 { A_Pain(); }
		Goto See;
	Death.T00:
		"SPID" J 20 { A_Scream(); }
		"SPID" K 10 { A_NoBlocking(); }
		"SPID" LMNOPQR 10;
		"SPID" S 30;
		"SPID" S -1 { A_BossDeath(); }
		Stop;

	// ================= T01 GREEN (16_G) =================
	// Poison spider-shot: a tight pair, then MonsterRefire.
	Spawn.T01:
		"SPIG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		TNT1 A 0 { RS_GroundStance(); }
		"SPIG" A 0 { A_Chase(); }
		"SPIG" A 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPIG" ABB 3 { A_Chase(); }
		"SPIG" A 0 { A_Chase(); }
		"SPIG" C 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPIG" CDD 3 { A_Chase(); }
		"SPIG" A 0 { A_Chase(); }
		"SPIG" E 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPIG" EFF 3 { A_Chase(); }
		Loop;
	Missile.T01:
		"SPIG" A 20 Bright { A_FaceTarget(); }
	Missile.T01.Shoot:
		"SPIG" H 2 Bright { A_FaceTarget(); }
		"SPIG" G 2 Bright { A_SpawnProjectile("RS_SpidieShot1", 35, 0, random(-3, 3)); }
		"SPIG" H 2 Bright { A_SpawnProjectile("RS_SpidieShot1", 35, 0, random(-10, 10)); }
		"SPIG" H 1 Bright A_MonsterRefire(188, "See");
		Goto Missile.T01.Shoot;
	Pain.T01:
		"SPIG" I 3;
		"SPIG" I 3 { A_Pain(); }
		Goto See;
	Death.T01:
		"SPIG" J 20 { A_Scream(); }
		"SPIG" K 10 { A_NoBlocking(); }
		"SPIG" LMNOPQR 10;
		"SPIG" S 30;
		"SPIG" S -1 { A_BossDeath(); }
		Stop;

	// ================= T02 BLUE (16_B) =================
	// Frosty: close breath, mid orbs, long lances -- and a high-angle
	// lob when the target is above it. Below 2800 HP it drops the
	// breath and alternates the two nastier patterns.
	Spawn.T02:
		"SPIB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		TNT1 A 0 { RS_GroundStance(); }
		"SPIB" A 3 { A_StartSound("bluemind/step", CHAN_BODY); }
		"SPIB" ABB 3 { A_Chase(); }
		"SPIB" C 3 { A_StartSound("bluemind/step", CHAN_BODY); }
		"SPIB" CDD 3 { A_Chase(); }
		"SPIB" E 3 { A_StartSound("bluemind/step", CHAN_BODY); }
		"SPIB" EFF 3 { A_Chase(); }
		Loop;
	Missile.T02:
		"SPIB" A 10 Bright { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(420, "Missile.T02.FrostBreath");
		TNT1 A 0 A_JumpIfHealthLower(2800, "Missile.T02.OrMaybe");
		TNT1 A 0 A_JumpIfCloser(1200, "Missile.T02.FrostOrbs");
		TNT1 A 0 A_Jump(256, "Missile.T02.LongFrost");
		Goto See;
	Missile.T02.OrMaybe:
		TNT1 A 0 A_Jump(256, "Missile.T02.LongFrost2", "Missile.T02.FrostOrbs");
		Goto See;
	Missile.T02.FrostBreath:
		"SPIB" H 0 { A_StartSound("Ice/Inhale", CHAN_VOICE, CHANF_DEFAULT, 1.5); }
		"SPIB" H 2 Bright { A_FaceTarget(); }
		// CHP jumps to the high-lob when the target is 28 units or more
		// above it; written out so it does not depend on the arg shape
		// of the DECORATE-era higher/lower jump.
		TNT1 A 0 { if (target && target.pos.z > pos.z + 28) return ResolveState("Missile.T02.HighShot"); return ResolveState(null); }
		"SPIB" G 1 Bright { A_SpawnProjectile("RS_FrostMind", 30, 0, random(-3, 3)); }
		"SPIB" G 2 Bright { A_SpawnProjectile("RS_FrostMind", 30, 0, random(-7, 7)); }
		"SPIB" H 1 Bright A_MonsterRefire(80, "See");
		Goto Missile.T02.FrostBreath;
	Missile.T02.HighShot:
		"SPIB" G 6 Bright { A_StartSound("Spell/SpellCast1", CHAN_WEAPON, CHANF_DEFAULT, 1.0, 3); }
		"SPIB" G 0 { A_SpawnItemEx("RS_IceOrb", 0, 0, 64, random(6, 12), 0, random(6, 14), 0); }
		"SPIB" G 0 { A_SpawnItemEx("RS_IceOrb", 0, 0, 64, random(6, 12), 0, random(6, 14), -7); }
		"SPIB" G 0 { A_SpawnItemEx("RS_IceOrb", 0, 0, 64, random(6, 12), 0, random(6, 14), 7); }
		Goto Missile.T02.FrostBreath;
	Missile.T02.FrostOrbs:
		"SPIB" H 6 Bright { A_FaceTarget(); }
		TNT1 A 0 { if (target && target.pos.z > pos.z + 28) return ResolveState("Missile.T02.HighShot"); return ResolveState(null); }
		"SPIB" G 6 Bright { A_StartSound("Spell/SpellCast1", CHAN_WEAPON, CHANF_DEFAULT, 1.0, 3); }
		"SPIB" G 0 { A_SpawnProjectile("RS_IceOrb", 52, -32, random(-5, 5)); }
		"SPIB" G 0 { A_SpawnProjectile("RS_IceOrb", 52, 32, random(-5, 5)); }
		"SPIB" G 0 { A_SpawnProjectile("RS_IceOrb", 36, 0, random(-1, 1)); }
		"SPIB" H 6 A_Jump(128, "Missile.T02");
		Goto See;
	Missile.T02.LongFrost:
		"SPIB" H 2 Bright { A_FaceTarget(); }
		"SPIB" G 2 Bright { A_SpawnProjectile("RS_FrostLong", 34, 0, random(-1, 1)); }
		"SPIB" G 2 Bright { A_SpawnProjectile("RS_FrostLong", 34, 0, random(-6, 6)); }
		"SPIB" H 1 Bright A_MonsterRefire(80, "See");
		Goto Missile.T02.FrostBreath;
	Missile.T02.LongFrost2:
		"SPIB" H 2 Bright { A_FaceTarget(); }
		"SPIB" G 2 Bright { A_SpawnProjectile("RS_FrostLong", 34, 0, random(-1, 1)); }
		"SPIB" G 2 Bright { A_SpawnProjectile("RS_FrostLong", 34, 0, random(-15, 15)); }
		"SPIB" H 1 Bright A_MonsterRefire(70, "See");
		Goto Missile.T02.LongFrost2;
	Pain.T02:
		"SPIB" I 3;
		"SPIB" I 3 { A_Pain(); }
		Goto See;
	Death.T02:
		"SPIB" J 20 { A_Scream(); }
		"SPIB" K 10 { A_NoBlocking(); }
		"SPIB" LMNOPQR 10;
		"SPIB" S 30;
		"SPIB" S -1 { A_BossDeath(); }
		Stop;

	// ================= T03 CYAN (16_CY) =================
	// Cyanide Master: floats, leaves an ice trail, blink-dodges, and
	// teleports out of pain onto one of its own trail markers.
	Spawn.T03:
		"SPCY" A 4 { A_Look(); }
		Loop;
	See.T03:
		TNT1 A 0 { RS_FlyStance(); }
		"SPCY" A 0 { A_StartSound("ice/cast", CHAN_BODY); }
		"SPCY" A 0 { A_SpawnItemEx("RS_CyanSpidTrail", -4, 0, 1, random(-1, 12), 0, random(-1, 1), angle + random(-90, 90)); }
		"SPCY" A 3 { A_Chase(); }
		"SPCY" A 0 { A_SpawnItemEx("RS_CyanSpidTrail", -4, 0, 1, random(-1, 12), 0, random(-1, 1), angle + random(-90, 90)); }
		"SPCY" A 3 { A_Chase(); }
		"SPCY" A 0 { A_SpawnItemEx("RS_CyanSpidTrail", -4, 0, 1, random(-1, 12), 0, random(-1, 1), angle + random(-90, 90)); }
		"SPCY" A 0 A_Jump(64, "See.T03.Dodge");
		"SPCY" A 3 { A_Chase(); }
		"SPCY" A 0 { A_SpawnItemEx("RS_CyanSpidTrail", -4, 0, 1, random(-1, 12), 0, random(-1, 1), angle + random(-90, 90)); }
		"SPCY" A 3 { A_Chase(); }
		"SPCY" A 0 A_Jump(24, "See.T03.Jumps");
		Loop;
	See.T03.Dodge:
		"SPCY" A 0 { A_StartSound("ice/cast", CHAN_BODY); }
		"SPCY" A 3 { A_FastChase(); }
		"SPCY" A 0 { A_SpawnItemEx("RS_CyanSpidTrail", -4, 0, 1, random(-1, 12), 0, random(-1, 1), angle + random(-90, 90)); }
		"SPCY" A 3 { A_FastChase(); }
		"SPCY" A 0 { A_SpawnItemEx("RS_CyanSpidTrail", -4, 0, 1, random(-1, 12), 0, random(-1, 1), angle + random(-90, 90)); }
		Goto See;
	See.T03.Jumps:
		"SPCY" A 5 { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 2, 0, 0, 3, 0, SXF_NOCHECKPOSITION); }
		"SPCY" A 1 { A_StartSound("monster/heltel", CHAN_VOICE); }
		"SPCY" A 1 { A_SetTranslucent(0.90); }
		"SPCY" A 1 { A_SetTranslucent(0.70); }
		"SPCY" A 1 { A_SetTranslucent(0.50); }
		"SPCY" A 1 { A_SetTranslucent(0.30); }
		"SPCY" A 1 { A_SetTranslucent(0.10); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		"SPCY" A 1 { A_StartSound("monster/heltel", CHAN_VOICE); }
		"SPCY" A 1 { A_SetTranslucent(0.30); }
		"SPCY" A 1 { A_SetTranslucent(0.50); }
		"SPCY" A 1 { A_SetTranslucent(0.70); }
		"SPCY" A 1 { A_SetTranslucent(0.90); }
		"SPCY" A 1 { A_SetTranslucent(1.0); }
		"SPCY" A 5 { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 2, 0, 0, 3, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Missile.T03:
		"SPCY" B 0 A_JumpIfCloser(1500, "Missile.T03.FrostMode");
		"SPCY" B 0 A_Jump(255, "Missile.T03.RapidFire");
		Goto See;
	Missile.T03.RapidFire:
		"SPCY" B 4 Bright { A_FaceTarget(); }
		"SPCY" F 2 Bright { A_SpawnProjectile("RS_SpiderCyanBomb", 30, 0, 0); }
		"SPCY" E 2 Bright { A_FaceTarget(); }
		"SPCY" B 1 Bright A_CheckSight("See");
		"SPCY" F 2 Bright { A_SpawnProjectile("RS_SpiderCyanBomb", 30, 0, random(-3, 3)); }
		"SPCY" E 2 Bright { A_FaceTarget(); }
		"SPCY" B 1 Bright A_CheckSight("See");
		"SPCY" F 2 Bright { A_SpawnProjectile("RS_SpiderCyanBomb", 30, 0, random(-1, 1)); }
		"SPCY" E 2 Bright A_MonsterRefire(128, "See");
		Goto Missile.T03.RapidFire;
	Missile.T03.FrostMode:
		TNT1 A 0 A_Jump(64, "Missile.T03.RapidFire");
		"SPCY" B 10 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(72, "Missile.T03.Frost2");
		"SPCY" B 0 { A_StartSound("fiend/bomb", CHAN_WEAPON); }
		"SPCY" OPQ 5 Bright { A_FaceTarget(); }
		"SPCY" QQQQQQQQQQQQQQQQQQQQQQQQ 1 { A_SpawnProjectile("RS_IceOrbCyanMind", 30, 0, random(-1, 1)); }
		"SPCY" QPO 5 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T03.Frost2:
		"SPCY" OPQ 5 Bright { A_FaceTarget(); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 0); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 15); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -15); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -30); }
		"SPCY" Q 0 { A_FaceTarget(); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 30); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -45); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 45); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -60); }
		"SPCY" Q 0 { A_FaceTarget(); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -60); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -75); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 75); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -45); }
		"SPCY" Q 0 { A_FaceTarget(); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 45); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 15); }
		"SPCY" Q 3 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, -15); }
		"SPCY" Q 5 Bright { A_FaceTarget(); }
		"SPCY" A 0 A_CheckSight("See");
		"SPCY" QQQQQQQQ 5 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, random(-5, 5)); }
		"SPCY" Q 5 Bright { A_FaceTarget(); }
		"SPCY" A 0 A_CheckSight("See");
		"SPCY" QQQQ 7 { A_SpawnProjectile("RS_IceOrbCyanMind2", 30, 0, 0); }
		"SPCY" QPO 5 Bright { A_FaceTarget(); }
		Goto See;
	Pain.T03:
		"SPCY" A 2 { A_SetTranslucent(1.0); }
		"SPCY" A 4 A_Teleport("See", "RS_CyanSpidTrail", "RS_BaronCyanBombTrail", TF_KEEPVELOCITY);
		Goto See;
	Death.T03:
		"SPCY" G 0 { bFLOATBOB = false; A_SetTranslucent(1.0); ReleaseMinions(); }
		"SPCY" G 10 { A_Scream(); }
		"SPCY" H 10;
		"SPCY" I 10 { A_Fall(); }
		"SPCY" JKLM 10;
		"SPCY" N 20 { A_BossDeath(); }
		"SPCY" N 10 { A_SetScale(1.0, 0.5); }
		"SPCY" N 10 { A_SetScale(1.0, 0.25); }
		"SPCY" N 10 { A_SetScale(0.66, 0.1); }
		"SPCY" N 10 { A_SetScale(0.44, 0.05); }
		"SPCY" N 10 { A_SetScale(0.22, 0.03); }
		Stop;

	// ================= T04 PURPLE (16_P) =================
	// Royal Spider Queen: hitscan volley, an orb wall, a rocket, and a
	// rage counter fed by pain that eventually buys her two spider adds.
	Spawn.T04:
		"DEMO" AB 10 { A_Look(); }
		Loop;
	See.T04:
		TNT1 A 0 { RS_GroundStance(); }
		"DEMO" A 0 { A_Chase(); }
		"DEMO" A 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"DEMO" ABB 3 { A_Chase(); }
		"DEMO" A 0 { A_Chase(); }
		"DEMO" C 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"DEMO" CDD 3 { A_Chase(); }
		"DEMO" A 0 { A_Chase(); }
		"DEMO" E 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"DEMO" EFF 3 { A_Chase(); }
		Loop;
	Missile.T04:
		"DEMO" A 5 { A_FaceTarget(); }
		TNT1 A 0 { if (rsRageMind >= 10) return ResolveState("Missile.T04.RageSummon"); return ResolveState(null); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T04.PewPew");
		TNT1 A 0 A_Jump(256, "Missile.T04.HitScanHell", "Missile.T04.Borb");
		Goto See;
	Missile.T04.PewPew:
		TNT1 A 0 A_Jump(64, "Missile.T04.PewPew2", "Missile.T04.Borb");
		TNT1 A 0 A_Jump(256, "Missile.T04.PewPew2", "Missile.T04.HitScanHell");
		Goto See;
	Missile.T04.PewPew2:
		"DEMO" A 6 { A_FaceTarget(); }
		"DEMO" T 8 Bright { A_StartSound("spider/sight", CHAN_VOICE); }
		"DEMO" U 10 Bright { A_SpawnProjectile("RS_DemoMissile", 32, 0, 0); }
		"DEMO" U 10;
		"DEMO" A 8 A_Jump(88, "Missile.T04");
		Goto See;
	Missile.T04.HitScanHell:
		"DEMO" G 5 { A_FaceTarget(); }
		"DEMO" G 0 { A_StartSound("spider/attack", CHAN_WEAPON); }
		"DEMO" G 0 { A_CustomBulletAttack(8, 8, random(1, 7), random(1, 2), "BulletPuff"); }
		"DEMO" G 0 { A_StartSound("spider/attack", CHAN_WEAPON); }
		"DEMO" G 4 Bright { A_CustomBulletAttack(5, 5, random(1, 7), random(1, 2), "BulletPuff"); }
		"DEMO" G 0 { A_StartSound("spider/attack", CHAN_WEAPON); }
		"DEMO" H 0 { A_CustomBulletAttack(12, 12, random(1, 7), random(1, 2), "BulletPuff"); }
		"DEMO" G 0 { A_StartSound("spider/attack", CHAN_WEAPON); }
		"DEMO" H 4 Bright { A_CustomBulletAttack(2, 2, random(1, 7), random(1, 2), "BulletPuff"); }
		"DEMO" G 0 { A_StartSound("spider/attack", CHAN_WEAPON); }
		"DEMO" H 1 Bright A_SpidRefire;
		Goto Missile.T04.HitScanHell;
	Missile.T04.Borb:
		"DEMO" G 5 { A_FaceTarget(); }
		"DEMO" G 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" H 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" H 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" G 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_FaceTarget(); }
		"DEMO" H 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" H 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" G 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" H 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" H 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" G 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" H 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" H 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" G 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_FaceTarget(); }
		"DEMO" H 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" H 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" G 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" G 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		"DEMO" H 2 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, 12, random(-1, 1)); }
		"DEMO" H 3 Bright { A_SpawnProjectile("RS_OrbPurpleMind", 32, -12, random(-1, 1)); }
		Goto See;
	Missile.T04.RageSummon:
		"DEMO" A 12 Bright { A_StartSound("spider/sight", CHAN_VOICE); }
		"DEMO" I 8 Bright { bNOPAIN = true; }
		"DEMO" I 12 Bright { A_StartSound("spider/sight", CHAN_VOICE); }
		// CHP's SpecialSpider_C is a blue CH arachnotron escort.
		"DEMO" G 4 Bright { SummonMinion("RS_Arachnotron", -2, 96.0); }
		"DEMO" G 4 Bright { SummonMinion("RS_Arachnotron", -2, 96.0); }
		"DEMO" A 4 { rsRageMind = max(0, rsRageMind - 8); }
		"DEMO" I 8 Bright { bNOPAIN = false; }
		Goto See;
	Pain.T04:
		"DEMO" I 3 { rsRageMind++; }
		"DEMO" I 3 { A_Pain(); }
		Goto See;
	Death.T04:
		"DEMO" A 0 { ReleaseMinions(); }
		"DEMO" J 20 Bright { A_Scream(); }
		"DEMO" K 10 Bright { A_NoBlocking(); }
		"DEMO" LMNOPQR 10 Bright;
		"DEMO" S 30;
		"DEMO" S -1 { A_BossDeath(); }
		Stop;

	// ================= T05 YELLOW (16_Y) =================
	// Supreme Yellow: hovers. Plasma spam, a five-ball BFG fan, a
	// twin-cannon rapid mode, homing remote bombs, and one panic
	// summon of four spider escorts below 3500 HP.
	Spawn.T05:
		"SUPS" A 4 { A_Look(); }
		Loop;
	See.T05:
		TNT1 A 0 { RS_FlyStance(); }
		"SUPS" A 0 { A_StartSound("fiend/hover", CHAN_BODY); }
		"SUPS" AAAA 2 { A_Chase(); }
		Loop;
	Missile.T05:
		"SUPS" B 0 A_JumpIfHealthLower(3500, "Missile.T05.Halp");
	Missile.T05.Pick:
		"SUPS" B 0 A_JumpIfCloser(500, "Missile.T05.BFGd");
		"SUPS" B 0 A_JumpIfCloser(2000, "Missile.T05.OrMaybe");
		"SUPS" B 0 A_Jump(256, "Missile.T05.Homers");
		Goto See;
	Missile.T05.OrMaybe:
		"SUPS" B 0 A_Jump(256, "Missile.T05.Homers", "Missile.T05.PlasmaSpam", "Missile.T05.RapidPlasma");
		Goto See;
	Missile.T05.Halp:
		TNT1 A 0 { if (rsHalpMe >= 1) return ResolveState("Missile.T05.Pick"); return ResolveState(null); }
		"SUPS" E 12 { A_StartSound("spider2/sight", CHAN_VOICE); }
		"SUPS" B 24 { bMISSILEEVENMORE = true; }
		"SUPS" B 4 { SummonMinion("RS_Arachnotron", 0, 72.0); }
		"SUPS" B 4 { SummonMinion("RS_Arachnotron", 0, 72.0); }
		"SUPS" B 4 { SummonMinion("RS_Arachnotron", 0, 72.0); }
		"SUPS" B 4 { SummonMinion("RS_Arachnotron", 0, 72.0); }
		"SUPS" B 26 { bTHRUACTORS = true; }
		"SUPS" B 8 { rsHalpMe++; }
		"SUPS" B 2 { bTHRUACTORS = false; }
		Goto See;
	Missile.T05.PlasmaSpam:
		"SUPS" B 0 { A_StartSound("fiend/hover", CHAN_BODY); }
		"SUPS" B 6 Bright { A_FaceTarget(); }
		"SUPS" B 0 { A_StartSound("fiend/hover", CHAN_BODY); }
		"SUPS" B 6 Bright { A_FaceTarget(); }
		"SUPS" F 2 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, 0); }
		"SUPS" E 2 Bright;
		"SUPS" B 1 Bright A_SpidRefire;
		"SUPS" F 2 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, random(-3, 3)); }
		"SUPS" E 2 Bright;
		"SUPS" B 1 Bright A_SpidRefire;
		"SUPS" F 2 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, random(-8, 8)); }
		"SUPS" E 2 Bright;
		Goto Missile.T05;
	Missile.T05.BFGd:
		"SUPS" B 0 { A_StartSound("fiend/hover", CHAN_BODY); }
		"SUPS" B 8 Bright { A_FaceTarget(); }
		"SUPS" B 0 { A_StartSound("fiend/hover", CHAN_BODY); }
		"SUPS" B 8 Bright { A_FaceTarget(); }
		"SUPS" B 8 Bright { A_StartSound("fiend/bfg", CHAN_WEAPON); }
		"SUPS" E 10 Bright { A_FaceTarget(); }
		"SUPS" F 10 Bright;
		"SUPS" F 0 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, 0); }
		"SUPS" F 0 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, -6); }
		"SUPS" F 0 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, 6); }
		"SUPS" F 0 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, -12); }
		"SUPS" F 0 Bright { A_SpawnProjectile("RS_FiendPlasmaBall", 30, 0, 12); }
		TNT1 A 0 A_Jump(128, "Missile.T05.PlasmaSpam", "Missile.T05.RapidPlasma");
		Goto See;
	Missile.T05.RapidPlasma:
		"SUPS" B 10 Bright { A_FaceTarget(); }
		"SUPS" B 0 { A_StartSound("fiend/bomb", CHAN_WEAPON); }
		"SUPS" OPQ 7 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(128, "Missile.T05.HitIt2");
	Missile.T05.HitIt:
		"SUPS" Q 1 Bright { A_FaceTarget(); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_PlasmaBallSP3", 22, 20, random(-11, 1)); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_PlasmaBallSP3", 22, -20, random(-1, 11)); }
		"SUPS" Q 1 { A_FaceTarget(); }
		"SUPS" Q 1 Bright { A_FaceTarget(); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_PlasmaBallSP3", 22, 20, random(1, 5)); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_PlasmaBallSP3", 22, -20, random(-5, -1)); }
		"SUPS" Q 1 { A_FaceTarget(); }
		"SUPS" Q 1 Bright { A_FaceTarget(); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_PlasmaBallSP3", 22, 20, 1); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_PlasmaBallSP3", 22, -20, -1); }
		"SUPS" Q 1 { A_FaceTarget(); }
		"SUPS" Q 1 A_CheckSight("Missile.T05.StopIt");
		TNT1 A 0 A_Jump(64, "Missile.T05.HitIt2");
		// CHP: A_CheckFlag("SOLID","HitIt",AAPTR_TARGET) -- written out.
		TNT1 A 0 { if (target && target.bSOLID) return ResolveState("Missile.T05.HitIt"); return ResolveState(null); }
		Goto See;
	Missile.T05.HitIt2:
		"SUPS" Q 1 Bright { A_FaceTarget(); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_AracnorbBall", 22, 20, random(-11, 1)); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_AracnorbBall", 22, -20, random(-1, 11)); }
		"SUPS" Q 1 { A_FaceTarget(); }
		"SUPS" Q 1 Bright { A_FaceTarget(); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_AracnorbBall", 22, 20, random(1, 5)); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_AracnorbBall", 22, -20, random(-5, -1)); }
		"SUPS" Q 1 { A_FaceTarget(); }
		"SUPS" Q 1 Bright { A_FaceTarget(); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_AracnorbBall", 22, 20, 1); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_AracnorbBall", 22, -20, -1); }
		"SUPS" Q 1 { A_FaceTarget(); }
		"SUPS" Q 1 A_CheckSight("Missile.T05.StopIt");
		TNT1 A 0 A_Jump(64, "Missile.T05.HitIt");
		TNT1 A 0 { if (target && target.bSOLID) return ResolveState("Missile.T05.HitIt2"); return ResolveState(null); }
		Goto See;
	Missile.T05.StopIt:
		"SUPS" QPO 10 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T05.Homers:
		"SUPS" B 10 Bright { A_FaceTarget(); }
		"SUPS" B 0 { A_StartSound("fiend/bomb", CHAN_WEAPON); }
		"SUPS" OPQ 7 Bright { A_FaceTarget(); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_RemoteBombV2", 22, 20, 45); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_RemoteBombV2", 22, -20, -45); }
		"SUPS" Q 16 Bright { A_FaceTarget(); }
		"SUPS" B 0 { A_StartSound("fiend/bomb", CHAN_WEAPON); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_RemoteBombV2", 22, 20, 33); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_RemoteBombV2", 22, -20, -33); }
		"SUPS" Q 16 Bright { A_FaceTarget(); }
		"SUPS" B 0 { A_StartSound("fiend/bomb", CHAN_WEAPON); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_RemoteBombV2", 22, 20, 15); }
		"SUPS" Q 0 { A_SpawnProjectile("RS_RemoteBombV2", 22, -20, -15); }
		"SUPS" QPO 10 Bright { A_FaceTarget(); }
		Goto See;
	// Neither CHP 16_Y nor CH's YellowMind defines a Pain state -- this
	// boss genuinely does not flinch. A zero-tic cluster keeps that
	// behaviour and still gives the tier audit something to find.
	Pain.T05:
		"SUPS" B 0;
		Goto See;
	Death.T05:
		"SUPS" G 0 { bFLOATBOB = false; ReleaseMinions(); }
		"SUPS" G 10 { A_Scream(); }
		"SUPS" H 10;
		"SUPS" I 10 { A_Fall(); }
		"SUPS" JKLM 10;
		"SUPS" N -1 { A_BossDeath(); }
		Stop;

	// ================= T06 ABYSS (16_A) =================
	// Abyssal mind: three walk cycles that randomly warp, tentacle
	// fields, psychic tangles, a mind-wave fan, and the BigZap that
	// cracks the floor open.
	Spawn.T06:
		"AMIN" ABCDEFGHI 10 { A_Look(); }
		Loop;
	See.T06:
		TNT1 A 0 { RS_FlyStance(); }
		TNT1 A 0 A_Jump(99, "See.T06.Two", "See.T06.Three");
		"AMIN" A 3 { A_Chase(); }
		"AMIN" B 3 { A_Chase(); }
		"AMIN" C 3 { A_Chase(); }
		"ANIM" KLMLK 1 { A_Chase(); }
		TNT1 A 1 A_Jump(12, "See.T06.Warp");
		Loop;
	See.T06.Two:
		"AMIN" D 3 { A_Chase(); }
		"AMIN" E 3 { A_Chase(); }
		"AMIN" F 3 { A_Chase(); }
		TNT1 A 1 A_Jump(12, "See.T06.Warp");
		"ANIM" KLMLK 1 { A_Chase(); }
		TNT1 A 1 A_Jump(99, "See", "See.T06.Three");
		Loop;
	See.T06.Three:
		"AMIN" G 3 { A_Chase(); }
		"AMIN" H 3 { A_Chase(); }
		"AMIN" I 3 { A_Chase(); }
		TNT1 A 1 A_Jump(12, "See.T06.Warp");
		"ANIM" KLMLK 1 { A_Chase(); }
		TNT1 A 1 A_Jump(99, "See", "See.T06.Two");
		Loop;
	See.T06.Warp:
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		"ANIM" K 1;
		Goto See;
	Missile.T06:
		"ANIM" K 3 { A_FaceTarget(); }
		"ANIM" K 8 Bright { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T06.Choice1");
		TNT1 A 0 A_Jump(256, "Missile.T06.Choice2");
		Goto See;
	Missile.T06.Choice1:
		TNT1 A 0 A_Jump(256, "Missile.T06.Tentacles", "Missile.T06.MindWave", "Missile.T06.BigZap");
		Goto See;
	Missile.T06.Choice2:
		TNT1 A 0 A_Jump(256, "Missile.T06.Tentacles", "Missile.T06.MindTangle");
		Goto See;
	Missile.T06.Tentacles:
		"ANIM" K 1 { A_StartSound("queen/sight", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"ANIM" V 8 Bright { A_VileTarget("RS_ABVileTend"); }
		"ANIM" XWU 8 Bright;
		"ANIM" KLMMLK 2 Bright;
		TNT1 A 0 A_Jump(64, "See.T06.Warp");
		Goto See;
	Missile.T06.MindTangle:
		"ANIM" K 1 { A_StartSound("queen/sight", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
	Missile.T06.MindTangleLoop:
		"ANIM" VXWU 8 Bright { A_VileTarget("RS_PsychicTangleAbyVile"); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T06.BigZap");
		TNT1 A 0 A_SpidRefire;
		Goto Missile.T06.MindTangleLoop;
	Missile.T06.BigZap:
		"ANIM" K 1 { A_FaceTarget(); }
		"ANIM" KJN 9 Bright;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		"ANIM" NJK 6 Bright;
		"ANIM" K 12 { A_FaceTarget(); }
		"ANIM" K 12 { A_SpawnProjectile("RS_AbyssMindBigZap", 42, 0, 0); }
		"ANIM" K 0 { bNOPAIN = true; }
		"ANIM" VWOQPRUTYK 5 Bright { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-359, 359)); }
		TNT1 AAAAAA 0 { A_SpawnItemEx("RS_CrackedAbyssMindFall", random(-1028, 1028), random(-1028, 1028), random(32, 128), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-15, 15)); }
		TNT1 A 0 { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-1, 1)); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-359, 359)); }
		"ANIM" VYWOQRSTUY 5 Bright { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-359, 359)); }
		TNT1 AAAAAA 0 { A_SpawnItemEx("RS_CrackedAbyssMindFall", random(-1528, 1528), random(-1528, 1528), random(32, 128), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-359, 359)); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-15, 15)); }
		TNT1 A 0 { A_SpawnProjectile("RS_CrackedAbyssMindFloor", 1, 0, random(-1, 1)); }
		"ANIM" KJN 4 Bright;
		TNT1 AAAAAAAAAA 0 { A_Wander(); }
		"ANIM" NJK 3 Bright;
		"ANIM" K 0 { bNOPAIN = false; }
		Goto See;
	Missile.T06.MindWave:
		"ANIM" K 1 { A_FaceTarget(); }
	Missile.T06.MindWaveLoop:
		"ANIM" OP 8 Bright { A_SpawnProjectile("RS_AbyssMindWave", 35, 0, random(-6, 6)); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_AbyssMindWave", 35, 0, random(-20, 20)); }
		TNT1 A 0 { A_FaceTarget(); }
		"ANIM" QR 8 Bright { A_SpawnProjectile("RS_AbyssMindWave", 35, 0, random(-2, 2)); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_AbyssMindWave", 35, 0, random(-20, 20)); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_AbyssMindWave", 35, 0, random(-50, 50)); }
		"ANIM" R 10 Bright;
		"ANIM" KLMMLK 2 Bright;
		TNT1 A 0 A_Jump(32, "See.T06.Warp");
		TNT1 A 0 A_SpidRefire;
		Goto Missile.T06.MindWaveLoop;
	Pain.T06:
		"ANIM" KJ 2;
		"ANIM" N 2 { A_Pain(); }
		"ANIM" N 0 A_Jump(128, "See.T06.Warp");
		Goto See;
	Death.T06:
		"ANIM" K 10;
		"ABSP" G 0 { A_BossDeath(); }
		TNT1 A 0 { A_Scream(); }
		"ANIM" KY 10;
		TNT1 A 0 { bFLOAT = false; bFLOATBOB = false; bNOGRAVITY = false; }
		"ANIM" ST 10;
		TNT1 A 0 { A_NoBlocking(); }
		"ANIM" T 10 { A_SetScale(1.0, 0.7); }
		"ANIM" T 10 { A_SetScale(1.0, 0.4); }
		"ANIM" T 10 { A_SetScale(1.0, 0.1); }
		"ANIM" TTT 10 { A_FadeOut(0.33); }
		Stop;

	// ================= T07 FIREBLU (16_F) =================
	// Horrifying eyesore: fireblu flame-walls, a ground flame spread,
	// and a fireball spam. Below 3000 HP it stops flinching, gains
	// MISSILEEVENMORE and speeds up -- once.
	Spawn.T07:
		"SPIF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		TNT1 A 0 { RS_GroundStance(); }
		"SPIF" A 0 { A_Chase(); }
		"SPIF" A 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPIF" ABB 3 { A_Chase(); }
		"SPIF" A 0 { A_Chase(); }
		"SPIF" C 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPIF" CDD 3 { A_Chase(); }
		"SPIF" A 0 { A_Chase(); }
		"SPIF" E 3 { A_StartSound("spider/walk", CHAN_BODY); }
		"SPIF" EFF 3 { A_Chase(); }
		Loop;
	Missile.T07:
		"SPIF" A 0 A_JumpIfCloser(1500, "Missile.T07.Choices");
		"SPIF" A 0 A_Jump(80, "Missile.T07.Flames");
		Goto Missile.T07.Choices;
	Missile.T07.Flames:
		"SPIF" I 25 Bright { A_StartSound("spider/sight", CHAN_VOICE); }
		"SPIF" A 10 Bright { A_FaceTarget(); }
		"SPIF" T 5 Bright A_CheckSight("See");
		"SPIF" U 5 Bright { A_VileTarget("RS_FireBluMindFlame1"); }
		"SPIF" A 0 { A_FaceTarget(); }
		"SPIF" T 5 Bright A_CheckSight("See");
		"SPIF" U 5 Bright { A_VileTarget("RS_FireBluMindFlame1"); }
		"SPIF" A 0 { A_FaceTarget(); }
		"SPIF" T 5 Bright A_CheckSight("See");
		"SPIF" U 5 Bright { A_VileTarget("RS_FireBluMindFlame1"); }
		"SPIF" A 10;
		Goto See;
	Missile.T07.Choices:
		"SPIF" A 0 A_Jump(256, "Missile.T07.Spam", "Missile.T07.GroundFlame");
		Goto See;
	Missile.T07.GroundFlame:
		"SPIF" A 14 Bright { A_FaceTarget(); }
		"SPIF" U 2 Bright { A_FaceTarget(); }
		"SPIF" T 2 Bright { A_SpawnProjectile("RS_FireBluMindFlame3", 31, 4, random(-3, 3)); }
		"SPIF" A 0 { A_SpawnProjectile("RS_FireBluMindFlame3", 31, 4, random(30, 150)); }
		"SPIF" U 3 Bright { A_SpawnProjectile("RS_FireBluMindFlame3", 31, 4, random(-150, 30)); }
		Goto See;
	Missile.T07.Spam:
		"SPIF" A 15 Bright { A_FaceTarget(); }
	Missile.T07.SpamLoop:
		"SPIF" H 2 Bright { A_FaceTarget(); }
		"SPIF" G 2 Bright { A_SpawnProjectile("RS_FireBCguy", 31, 4, random(-3, 3)); }
		"SPIF" A 0 { A_SpawnProjectile("RS_FireBCguy", 31, 4, random(-15, 15)); }
		"SPIF" H 2 Bright { A_SpawnProjectile("RS_FireBCguy", 31, 4, random(-35, 35)); }
		"SPIF" H 1 Bright A_MonsterRefire(188, "See");
		Goto Missile.T07.SpamLoop;
	Pain.T07:
		"SPIF" I 3;
		"SPIF" I 3 { A_Pain(); }
		"SPIF" I 0 A_JumpIfHealthLower(3000, "Pain.T07.ToughUp");
		Goto See;
	Pain.T07.ToughUp:
		TNT1 A 0 { if (rsToughUp >= 1) return ResolveState("See"); return ResolveState(null); }
		"SPIF" I 0 { bNOPAIN = true; bMISSILEEVENMORE = true; A_SetSpeed(26); rsToughUp = 1; }
		Goto See;
	Death.T07:
		"SPIF" J 20 { A_Scream(); }
		"SPIF" K 10 { A_NoBlocking(); }
		"SPIF" LMNOPQR 10;
		"SPIF" S 30;
		"SPIF" S -1 { A_BossDeath(); }
		Stop;

	// ================= T08 BROWN (16_BR) =================
	// Death'n'Decay Master: bone orbs, a burrowing bone, ground spikes,
	// a rock-and-wind spiral, and below 3000 HP either a life-draining
	// devour or a one-shot bone shield handed out to every nearby demon.
	Spawn.T08:
		"B05P" AB 10 { A_Look(); }
		Loop;
	See.T08:
		TNT1 A 0 { RS_GroundStance(); }
		"B05P" A 0 { A_StartSound("brownmind/step", CHAN_BODY); }
		"B05P" AABB 3 { A_Chase(); }
		"B05P" C 0 { A_StartSound("brownmind/step", CHAN_BODY); }
		"B05P" CCDD 3 { A_Chase(); }
		"B05P" E 0 { A_StartSound("brownmind/step", CHAN_BODY); }
		"B05P" EEFF 3 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "See.T08.Fast");
		Loop;
	See.T08.Fast:
		"B05P" A 0 { A_StartSound("brownmind/step", CHAN_BODY); }
		"B05P" AABB 1 { A_Chase(); }
		"B05P" C 0 { A_StartSound("brownmind/step", CHAN_BODY); }
		"B05P" CCDD 1 { A_Chase(); }
		"B05P" E 0 { A_StartSound("brownmind/step", CHAN_BODY); }
		"B05P" EEFF 1 { A_Chase(); }
		TNT1 A 0 A_Jump(176, "See.T08.Fast");
		Goto See;
	Missile.T08:
		"B05P" A 0 A_JumpIfHealthLower(3000, "Missile.T08.Choose");
	Missile.T08.Choose2:
		"B05P" A 0 A_Jump(48, "Missile.T08.GroundBreak");
		"B05P" A 0 A_Jump(96, "Missile.T08.Spiral");
	Missile.T08.Orbs:
		"B05P" A 3 Bright { A_FaceTarget(); }
		"B05P" GG 5 Bright { A_FaceTarget(); }
		"B05P" HHH 4 Bright { A_SpawnProjectile("RS_BrownOrbMind", 42, 0, random(-20, 20), 0, random(-1, 1)); }
		"B05P" A 0 A_Jump(64, "Missile.T08.Worm");
	Missile.T08.Orbs2:
		"B05P" G 0 A_CheckSight("Missile.T08.Worm");
		"B05P" G 8 Bright { A_FaceTarget(); }
		"B05P" HHH 4 Bright { A_SpawnProjectile("RS_BrownOrbMind", 42, 0, random(-20, 20), 0, random(-1, 1)); }
		"B05P" A 0 A_Jump(192, "Missile.T08.Orbs2");
		"B05P" A 0 A_Jump(128, "Missile.T08.Worm");
		"B05P" A 8 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T08.Worm:
		"B05P" G 8 Bright { A_FaceTarget(); }
		"B05P" HHH 8 Bright { A_SpawnProjectile("RS_BrownMindBone2", 42, 0, 0, 0, 0); }
		"B05P" A 8 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T08.GroundBreak:
		TNT1 A 0 { A_StartSound("ECHOIMPB", CHAN_VOICE); }
		"B05P" TUV 8 Bright { A_FaceTarget(); }
		"B05P" VVV 8 Bright { A_VileTarget("RS_MindGroundSpikeBrown"); }
		"B05P" VUT 8;
		Goto See;
	Missile.T08.Spiral:
		"B05P" A 6 Bright A_JumpIfCloser(700, "Missile.T08.SpiralGo");
		Goto Missile.T08.Orbs;
	Missile.T08.SpiralGo:
		"B05P" G 8 Bright { A_FaceTarget(); }
		"B05P" HHHHHHHHHHHHHHHHHHHHHHHH 0 { A_SpawnProjectile("RS_ZombieRock", random(28, 35), random(-5, 5), random(-4, 4), CMF_OFFSETPITCH, random(-3, 5)); }
		"B05P" H 1 Bright { A_SpawnProjectile("RS_WindBlastMasterMind", 32, 0, 0); }
		"B05P" H 1 Bright { A_SpawnProjectile("RS_WindBlastMasterMind2", 32, 0, 0); }
		"B05P" H 1 Bright { A_SpawnProjectile("RS_WindBlastMasterMind3", 32, 0, 0); }
		"B05P" HA 8 Bright;
		Goto See;
	Missile.T08.Choose:
		"B05P" A 0 A_Jump(192, "Missile.T08.Choose2");
		TNT1 A 0 A_Jump(256, "Missile.T08.YumYum", "Missile.T08.SaveYourself");
		Goto Missile.T08.Choose2;
	Missile.T08.YumYum:
		TNT1 A 0 A_JumpIfCloser(450, "Missile.T08.YumYumGo");
		Goto Missile.T08.Orbs;
	Missile.T08.YumYumGo:
		// CHP: a_checkflag("Boss","SaveYourself",AAPTR_TARGET)
		TNT1 A 0 { if (target && target.bBOSS) return ResolveState("Missile.T08.SaveYourself"); return ResolveState(null); }
		TNT1 A 0 { bNOTARGETSWITCH = true; bNOPAIN = true; }
		"B05P" H 8 Bright { A_FaceTarget(); }
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 { A_VileTarget("RS_Drt3"); }
		"B05P" H 0 { A_RadiusThrust(-800, 302, RTF_NOTMISSILE, 300); }
		"B05P" H 0 { A_VileAttack("", 20, 0, 0, 1.75); }
		TNT1 A 0 { A_StartSound("CUCHUM01", CHAN_VOICE); }
		"B05P" H 0 { A_RadiusThrust(-500, 302, RTF_NOTMISSILE, 300); }
		"B05P" G 8 Bright;
		"B05P" H 8 Bright { A_GiveInventory("Health", 500); }
		"B05P" G 8 Bright { A_StartSound("CUCHUM01", CHAN_VOICE); }
		"B05P" H 8 Bright;
		"B05P" G 8 Bright { A_StartSound("CUCHUM01", CHAN_VOICE); }
		TNT1 A 0 { bNOTARGETSWITCH = false; bNOPAIN = false; }
		Goto See;
	Missile.T08.SaveYourself:
		TNT1 A 0 { if (rsDewzan >= 1) return ResolveState("Missile.T08.YumYum"); return ResolveState(null); }
		TNT1 A 0 { A_StartSound("BONEBR3K", CHAN_VOICE); }
		"B05P" TUV 8 Bright;
		TNT1 A 0 { A_StartSound("BONEBR3K", CHAN_VOICE); }
		TNT1 A 0 { A_RadiusGive("RS_ShieldUpMind2", 732, RGF_MONSTERS, 1); }
		"B05P" A 0 { rsDewzan = 1; }
		"B05P" VUTT 10 { A_GiveInventory("RS_ShieldUpMind2", 1); }
		Goto See;
	Pain.T08:
		"B05P" I 3;
		"B05P" I 3 { A_Pain(); }
		Goto See.T08.Fast;
	Death.T08:
		"B05P" J 20 { A_Scream(); }
		"B05P" K 10 { A_NoBlocking(); }
		"B05P" LMNOPQR 10;
		"B05P" S 30;
		TNT1 AAAAAAAAAAAA 0 { A_SpawnProjectile("RS_CH_BoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"B05P" S -1 { A_BossDeath(); }
		Stop;

	// ================= T09 GRAY (16_GY) =================
	// Rocky Road: a rock chaingun, a shotgun-spread of stone shots, and
	// the 46-shot nail storm.
	Spawn.T09:
		"SPGY" A 0 NoDelay { A_SpawnItemEx("RS_BrainPainGray", 0, 0, 32, 0, 0, 0, 0, SXF_SETMASTER); }
		"SPGY" AB 10 { A_Look(); }
		Loop;
	See.T09:
		TNT1 A 0 { RS_GroundStance(); }
		"SPGY" A 3 { A_StartSound("bluemind/step", CHAN_BODY); }
		"SPGY" ABB 3 { A_Chase(); }
		"SPGY" C 3 { A_StartSound("bluemind/step", CHAN_BODY); }
		"SPGY" CDD 3 { A_Chase(); }
		"SPGY" E 3 { A_StartSound("bluemind/step", CHAN_BODY); }
		"SPGY" EFF 3 { A_Chase(); }
		Loop;
	Missile.T09:
		TNT1 A 0 A_JumpIfCloser(1500, "Missile.T09.HellOnEarth");
		TNT1 A 0 A_JumpIfHealthLower(4000, "Missile.T09.NotJoking");
		"SPGY" A 25 Bright { A_FaceTarget(); }
	Missile.T09.Chaingun:
		"SPGY" H 2 Bright { A_FaceTarget(); }
		"SPGY" GG 1 Bright { A_CustomBulletAttack(3, 3, 1, random(1, 8), "RS_GrayCGuff", 9999); }
		"SPGY" HH 1 Bright { A_CustomBulletAttack(15, 3, 3, random(1, 8), "RS_GrayCGuff", 9999); }
		"SPGY" H 1 Bright A_MonsterRefire(188, "See");
		Goto Missile.T09.Chaingun;
	Missile.T09.HellOnEarth:
		"SPGY" H 2 Bright { A_FaceTarget(); }
		"SPGY" G 1 Bright { A_SpawnProjectile("RS_SpidieShotGray", 35, 0, random(-3, 3)); }
		"SPGY" H 1 Bright { A_SpawnProjectile("RS_SpidieShotGray", 35, 0, random(-5, 5)); }
		"SPGY" GG 1 Bright { A_SpawnProjectile("RS_SpidieShotGray", 35, 0, random(-13, 13), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-10, 10)); }
		"SPGY" HH 1 Bright { A_SpawnProjectile("RS_SpidieShotGray", 35, 0, random(-15, 15), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-10, 10)); }
		"SPGY" G 0 { A_SpawnProjectile("RS_SpidieShotGray", 35, 0, random(-10, 10), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-10, 10)); }
		"SPGY" G 0 { A_SpawnProjectile("RS_SpidieShotGray", 35, 0, random(-10, 10), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-10, 10)); }
		"SPGY" H 3 Bright { A_SpawnProjectile("RS_SpidieShotGray", 35, 0, random(-10, 10)); }
		TNT1 A 0 A_Jump(32, "Missile.T09.SpikeYou");
		"SPGY" H 15 Bright { A_FaceTarget(); }
		"SPGY" H 1 Bright A_MonsterRefire(188, "See");
		Goto Missile.T09.HellOnEarth;
	Missile.T09.SpikeYou:
		"SPGY" H 15 Bright { A_FaceTarget(); }
		"SPGY" GHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGHGH 1 Bright { A_SpawnProjectile("RS_SpidieNail", 35, random(-15, 15), random(-8, 8), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-5, 5)); }
		"SPGY" H 15 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T09.NotJoking:
		TNT1 A 0 A_Jump(128, "Missile.T09.Chaingun", "Missile.T09.SpikeYou");
		Goto Missile.T09.HellOnEarth;
	Pain.T09:
		"SPGY" I 3;
		"SPGY" I 3 { A_Pain(); }
		Goto See;
	Death.T09:
		"SPGY" A 0 { ReleaseMinions(); }
		"SPGY" J 20 { A_Scream(); }
		"SPGY" K 10 { A_NoBlocking(); }
		"SPGY" LMNOPQR 10;
		"SPGY" S 30;
		"SPGY" S -1 { A_BossDeath(); }
		Stop;

	// ================= T10 RED (16_R) =================
	// Red Arachnophyte: hovers, twin railguns, saw waves, ring mines
	// and bomb drops. Below 5000 HP it detonates into phase 2 and the
	// railgun cadence tightens for the rest of the fight.
	Spawn.T10:
		"APYT" A 0 { A_StartSound("arachnophyte/engine", CHAN_BODY); }
		"APYT" ABABAB 4 { A_Look(); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	See.T10:
		TNT1 A 0 { RS_FlyStance(); }
		"APYT" A 0 { A_StartSound("arachnophyte/engine", CHAN_BODY); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"APYT" AABBAABBAABB 2 { A_Chase(); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"APYT" A 0 A_Jump(128, "See.T10.Fast");
		Loop;
	See.T10.Fast:
		"APYT" A 0 { A_StartSound("arachnophyte/engine", CHAN_BODY); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"APYT" AABBAABBAABB 2 { A_FastChase(); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"APYT" A 0 A_Jump(128, "See");
		Loop;
	Missile.T10:
		"APYT" A 0 { A_StartSound("arachnophyte/engine", CHAN_BODY); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { if (rsPhase2 >= 1) return ResolveState("Missile.T10.Phase2Jumps"); return ResolveState(null); }
		"APYT" A 0 A_JumpIfHealthLower(5000, "Missile.T10.Phase2");
		"APYT" A 0 A_Jump(256, "Missile.T10.Lasers", "Missile.T10.Blobs", "Missile.T10.FireWave", "Missile.T10.GroundHogs");
		Goto See;
	Missile.T10.Phase2Jumps:
		"APYT" A 0 A_JumpIfCloser(1500, "Missile.T10.Phase2Jumps2");
		"APYT" A 0 A_Jump(256, "Missile.T10.Lasers2");
		Goto See;
	Missile.T10.Phase2Jumps2:
		"APYT" A 0 A_Jump(256, "Missile.T10.Lasers2", "Missile.T10.Blobs", "Missile.T10.FireWave", "Missile.T10.GroundHogs");
		Goto See;
	Missile.T10.Lasers2:
		"APYT" BABAB 1 { A_FaceTarget(); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
	Missile.T10.Lasers2Go:
		"APYT" A 0 { A_StartSound("arachnophyte/engine", CHAN_BODY); }
		"APYT" C 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"APYT" C 3 { A_CustomRailgun(random(5, 25), 0, "", "Red", RGF_FULLBRIGHT | RGF_SILENT, 1, 12, "None", 0, 0, 0, 34, 1, 15); }
		"APYT" D 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"APYT" D 3 { A_CustomRailgun(random(5, 25), 0, "", "Red", RGF_FULLBRIGHT | RGF_SILENT, 1, 12, "None", 0, 0, 0, 34, 1, 15); }
		"APYT" D 0 A_Jump(20, "Missile.T10.Blobs");
		"APYT" A 0 A_JumpIfCloser(600, "Missile.T10.FireWave");
		"APYT" D 2 A_MonsterRefire(128, "See");
		Goto Missile.T10.Lasers2Go;
	Missile.T10.Phase2:
		"APYT" A 6 { A_StartSound("arachnophyte/sight", CHAN_VOICE); }
		"APYT" A 2 { bMISSILEEVENMORE = true; }
		"APYT" AB 4 { A_FaceTarget(); }
		"APYT" ABABABABABAB 4 { A_SpawnProjectile("RS_RedMessImp", 32, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"APYT" AB 4 { A_FaceTarget(); }
		"APYT" A 4 { rsPhase2++; }
		Goto Missile.T10.Blobs;
	Missile.T10.GroundHogs:
		"APYT" BA 5 { A_FaceTarget(); }
		"APYT" C 6 { A_FaceTarget(); }
		"APYT" DDDCCCDDDCCCDDDCCCDDDCCCDDD 2 { A_SpawnProjectile("RS_RedMindRingNew", 0, random(-32, 32), random(-64, 64)); }
		Goto See;
	Missile.T10.FireWave:
		"APYT" BA 5 { A_FaceTarget(); }
		"APYT" C 6 { A_FaceTarget(); }
		"APYT" DCDCDCD 6 { A_SpawnProjectile("RS_SpiralSawMind1", 18, random(-32, 32), random(-32, 32)); }
		Goto See;
	Missile.T10.Blobs:
		"APYT" A 0 A_Jump(80, "Missile.T10.BlobsGo");
		"APYT" A 0 A_JumpIfHealthLower(5000, "Missile.T10.BlobsGo");
		"APYT" A 0 A_Jump(256, "Missile.T10.Lasers", "Missile.T10.FireWave", "Missile.T10.GroundHogs");
	Missile.T10.BlobsGo:
		"APYT" BA 5 { A_FaceTarget(); }
		"APYT" C 16 { A_FaceTarget(); }
		"APYT" CCCCC 6 { A_SpawnItemEx("RS_RedMindBomb", random(-60, 60), random(-60, 60), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Missile.T10.Lasers:
		"APYT" BABAB 1 { A_FaceTarget(); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
	Missile.T10.LasersGo:
		"APYT" A 0 { A_StartSound("arachnophyte/engine", CHAN_BODY); }
		"APYT" C 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"APYT" C 5 { A_CustomRailgun(random(5, 25), 0, "", "Red", RGF_FULLBRIGHT | RGF_SILENT, 1, 12, "None", 0, 0, 0, 34, 1, 15); }
		"APYT" D 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"APYT" D 5 { A_CustomRailgun(random(5, 25), 0, "", "Red", RGF_FULLBRIGHT | RGF_SILENT, 1, 12, "None", 0, 0, 0, 34, 1, 15); }
		"APYT" D 0 A_Jump(20, "Missile.T10.Blobs");
		"APYT" A 0 A_JumpIfCloser(600, "Missile.T10.FireWave");
		"APYT" D 2 A_MonsterRefire(128, "See");
		Goto Missile.T10.LasersGo;
	Pain.T10:
		"APYT" A 1 { A_Pain(); }
		"APYT" AAABBB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(-15, 40), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Death.T10:
		"APYT" A 0 { A_StartSound("monster/demdth", CHAN_VOICE); }
		"APYT" A 4 { A_Scream(); }
		"APYT" B 4;
		"APYT" EF 8;
		"APYT" G 6 { A_Explode(random(5, 45), 128); }
		"APYT" H 6 { A_Fall(); }
		"APYT" IJ 6;
		"APYT" J -1 { A_BossDeath(); }
		Stop;

	// ================= T11 BLACK (16_K) =================
	// Pseudo Old God: floats, sheds damaging shades, five firing
	// patterns and a portal summon. Below 7777 HP it screams once and
	// turns off pain for good.
	Spawn.T11:
		"ARNQ" A 1 { A_Look(); }
		Loop;
	See.T11:
		TNT1 A 0 { RS_FlyStance(); }
		"ARNQ" A 2 { A_Chase(); }
		"ARNQ" A 0 { A_SpawnProjectile("RS_BlackSpidShade", random(-5, 55), random(-15, 15), random(0, 360), CMF_AIMOFFSET, random(0, 360));
		             A_SpawnItemEx("RS_BlackSpidSpot", 0, 0, 8, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ARNQ" A 2 { A_Chase(); }
		"ARNQ" A 0 { A_SpawnProjectile("RS_BlackSpidShade", random(-5, 55), random(-15, 15), random(0, 360), CMF_AIMOFFSET, random(0, 360));
		             A_SpawnItemEx("RS_BlackSpidSpot", 0, 0, 8, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ARNQ" A 0 A_Jump(12, "Pain.T11.Tele");
		Loop;
	Missile.T11:
		TNT1 A 0 A_JumpIfHealthLower(7777, "Missile.T11.Scree");
		TNT1 A 0 A_JumpIfCloser(512, "Missile.T11.CloseRange");
		TNT1 A 0 A_JumpIfCloser(2028, "Missile.T11.Choose");
		TNT1 A 0 A_Jump(256, "Missile.T11.Psyche2");
		Goto See;
	Missile.T11.Choose:
		TNT1 A 0 A_Jump(256, "Missile.T11.BigBam", "Missile.T11.LongRange");
		Goto See;
	Missile.T11.Miss2:
		TNT1 A 0 A_JumpIfCloser(512, "Missile.T11.CloseRange2");
		TNT1 A 0 A_JumpIfCloser(2028, "Missile.T11.Choose2");
		TNT1 A 0 A_Jump(256, "Missile.T11.Psyche2");
		Goto See;
	Missile.T11.Scree:
		TNT1 A 0 { if (rsScree >= 1) return ResolveState("Missile.T11.Miss2"); return ResolveState(null); }
		"ARNQ" E 0 { bNOPAIN = true; }
		"ARNQ" E 10 Bright { bMISSILEEVENMORE = true; }
		"ARNQ" E 10 Bright { A_StartSound("DeepOne/active", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"ARNQ" E 10 Bright { rsScree++; }
		"ARNQ" EEEEEE 2 Bright;
		"ARNQ" E 10 Bright;
		"ARNQ" E 8 Bright;
		Goto See;
	Missile.T11.CloseRange2:
		TNT1 A 0 A_Jump(200, "Missile.T11.RapidFire", "Missile.T11.Waves2", "Missile.T11.Psyche2", "Missile.T11.Summons");
		Goto Missile.T11;
	Missile.T11.Choose2:
		TNT1 A 0 A_Jump(212, "Missile.T11.Choose", "Missile.T11.BigBam", "Missile.T11.Waves2", "Missile.T11.Psyche2", "Missile.T11.Summons");
		Goto Missile.T11;
	Missile.T11.CloseRange:
		TNT1 A 0 A_Jump(176, "Missile.T11.RapidFire", "Missile.T11.Waves");
		Goto Missile.T11.SpreadFire;
	Missile.T11.LongRange:
		TNT1 A 0 A_Jump(176, "Missile.T11.SpreadFire", "Missile.T11.Waves", "Missile.T11.Psyche2");
		Goto Missile.T11.RapidFire;
	Missile.T11.BigBam:
		TNT1 A 0 { A_StartSound("queen/fire", CHAN_WEAPON); }
		"ARNQ" BCD 6 { A_FaceTarget(); }
		"ARNQ" E 10 Bright { A_SpawnProjectile("RS_QueenMindWave", 64, 0, 0); }
		Goto See;
	Missile.T11.Waves:
		TNT1 A 0 { A_StartSound("queen/fire", CHAN_WEAPON); }
		"ARNQ" BCD 4 { A_FaceTarget(); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 30, -10, 0); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 54, -2, random(-5, 5)); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 72, 10, random(-8, 8)); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 64, -10, random(-12, 12)); }
		"ARNQ" E 6 Bright { A_SpawnProjectile("RS_ZWAVE3", 44, 18, random(-15, 15)); }
		"ARNQ" E 0 A_Jump(72, "Missile.T11");
		Goto See;
	Missile.T11.Waves2:
		TNT1 A 0 { A_StartSound("queen/fire", CHAN_WEAPON); }
		"ARNQ" BCD 4 { A_FaceTarget(); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 64, -10, random(-12, 12)); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 54, 10, random(-12, 12)); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 44, 0, random(-1, 1)); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 74, 20, random(-12, 12)); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 64, -30, random(-4, 4)); }
		"ARNQ" E 0 { A_SpawnProjectile("RS_ZWAVE3", 54, 30, random(-12, 12)); }
		"ARNQ" E 6 Bright { A_SpawnProjectile("RS_ZWAVE3", 64, -20, random(-12, 12)); }
		"ARNQ" E 0 A_Jump(84, "Missile.T11.BigBam", "Missile.T11.ClusterEf");
		Goto Missile.T11.Waves;
	Missile.T11.ClusterEf:
		"ARNQ" BCD 4 { A_FaceTarget(); }
		"ARNQ" EEE 1 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 1 Bright { A_SpawnProjectile("RS_ZWAVE3", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 1 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 1 Bright { A_SpawnProjectile("RS_ZWAVE3", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 1 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 1 Bright { A_SpawnProjectile("RS_ZWAVE3", 62, 0, random(-11, 11)); }
		Goto See;
	Missile.T11.Summons:
		"ARNQ" E 0 A_Jump(128, "Missile.T11");
		"ARNQ" E 10 Bright { A_FaceTarget(); }
		"ARNQ" E 10 Bright { A_StartSound("DeepOne/active", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"ARNQ" CD 8 Bright;
		"ARNQ" BABAB 3 Bright { SummonMinion(BlackPortalPick(random(0, 6)), -3, random(64, 178)); }
		"ARNQ" C 7 Bright;
		Goto See;
	Missile.T11.RapidFire:
		"ARNQ" BCD 4 { A_FaceTarget(); }
		"ARNQ" EEE 2 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-4, 4)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 2 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-7, 7)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 2 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 2 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 2 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-7, 7)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 2 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-7, 7)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEE 2 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-4, 4)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEEEE 1 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-4, 7)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEEEEEE 1 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-11, 11)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEEEEEE 1 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-7, 4)); }
		"ARNQ" D 0 { A_FaceTarget(); }
		"ARNQ" EEEEEEEEEEEE 1 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 62, 0, random(-3, 3)); }
		"ARNQ" D 5 { A_FaceTarget(); }
		"ARNQ" D 1 A_CheckSight("Pain.T11.Tele");
		"ARNQ" D 1 A_Jump(72, "Missile.T11.BigBam", "Missile.T11.ClusterEf");
		"ARNQ" D 1 A_Jump(94, "Missile.T11");
		Goto See;
	Missile.T11.Psyche2:
		"ARNQ" E 5 Bright { A_FaceTarget(); }
		"ARNQ" E 9 Bright { A_StartSound("queen/sight", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
	Missile.T11.Psyche2Loop:
		"ARNQ" E 9 Bright { A_FaceTarget(); }
		"ARNQ" E 3 Bright { A_FaceTarget(); }
		"ARNQ" E 0 A_CheckSight("See");
		"ARNQ" E 4 Bright { A_VileTarget("RS_PsychicAra2"); }
		"ARNQ" E 2 A_MonsterRefire(128, "See");
		Goto Missile.T11.Psyche2Loop;
	Missile.T11.SpreadFire:
		"ARNQ" BCD 6 { A_FaceTarget(); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-7, 1), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-1, 7), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-15, -7), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(7, 15), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-7, 7), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		"ARNQ" E 5 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-4, 4)); }
		"ARNQ" B 1 Bright A_CheckSight("See");
		"ARNQ" BCD 5 { A_FaceTarget(); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-7, 1), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-1, 7), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AAAA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-15, 15), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-7, 17), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		TNT1 AA 0 { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-17, 7), CMF_AIMOFFSET | CMF_OFFSETPITCH, random(-3, 3)); }
		"ARNQ" E 5 Bright { A_SpawnProjectile("RS_QueenPlasmaBlast", 64, 0, random(-4, 4)); }
		"ARNQ" D 5 { A_FaceTarget(); }
		"ARNQ" D 1 A_Jump(64, "Missile.T11", "Missile.T11.ClusterEf");
		Goto See;
	Pain.T11:
		TNT1 A 0 A_Jump(64, "Pain.T11.Tele");
		"ARNQ" F 4;
		"ARNQ" F 4 { A_Pain(); }
		Goto See;
	Pain.T11.Tele:
		"ARNQ" E 2 A_Teleport("See", "RS_BlackSpidSpot", "RS_ZWAVE2", TF_KEEPVELOCITY);
		Goto See;
	Death.T11:
		TNT1 A 0 { A_NoBlocking(); ReleaseMinions(); }
		"ARNQ" G 0 { A_StartSound("deepone/death", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); bFLOATBOB = false; }
		"ARNQ" G 9 { A_Scream(); }
		"ARNQ" G 3;
		"ARNQ" HIJKL 9;
		"ARNQ" L 2 { A_Quake(60, 60, 0, 80); }
		"ARNQ" M -1 { A_BossDeath(); }
		Stop;

	// ================= T12 WHITE -- EVERLASTING (16_W) =================
	// Three phases plus a flight mode it unlocks below 13000 HP, a
	// self-heal on every walk cycle, a reflective shield, orbital
	// nukes, a floor-crack quake, a lightning caller, mini-sentinel
	// spawns, and a chaos ball once it goes Everlasting below 6000.
	Spawn.T12:
		"W5PD" AB 10 { A_Look(); }
		Loop;
	See.T12:
		TNT1 A 0 { A_StopSound(CHAN_6); rsFlight = 0; bFLOAT = false; bNOGRAVITY = false; }
		"W5PD" F 15;
	See.T12.Walk:
		"W5PD" AABBCCDD 2 { A_Chase(); }
		// CHP heals 4 per walk cycle up to its 20000 ceiling.
		"W5PD" A 0 { if (health < 20000) A_SetHealth(min(health + 4, 20000)); }
		TNT1 A 0 A_Jump(40, "See.T12.Dodge1");
		TNT1 A 0 A_Jump(40, "See.T12.FlyCheck", "See.T12.Wander");
		Goto See.T12.Walk;
	See.T12.FlyCheck:
		"W5PD" A 0 A_JumpIfHealthLower(13000, "See.T12.Flying");
		Goto See.T12.Walk;
	See.T12.Flying:
		"W5PD" F 0 { rsFlight = 1; A_ChangeVelocity(0, 0, 10.5, CVF_REPLACE); bFLOAT = true; }
		"W5PD" F 15 { bNOGRAVITY = true; A_StartSound("WMINDFLY", CHAN_6, CHANF_LOOPING); }
	See.T12.Fly:
		"W5PD" FFFFFFFF 2 { A_FastChase(); }
		"W5PD" A 0 { if (health < 20000) A_SetHealth(min(health + 4, 20000)); }
		TNT1 A 0 A_Jump(40, "See.T12.Dodge3");
		TNT1 A 0 A_Jump(40, "See", "See.T12.Wander2");
		Goto See.T12.Fly;
	See.T12.Wander:
		"W5PD" A 0 { if (rsEverlasting > 0) return ResolveState("See.T12.Camo"); return ResolveState(null); }
		"W5PD" AABBCCDD 1 { A_Wander(); }
		Goto See.T12.Walk;
	See.T12.Wander2:
		"W5PD" A 0 { if (rsEverlasting > 0) return ResolveState("See.T12.Camo"); return ResolveState(null); }
		"W5PD" AABBCCDD 1 { A_Wander(); }
		Goto See.T12.Fly;
	See.T12.Camo:
		"W5PD" F 10 { if (rsCamo >= 1) return ResolveState("See.T12.NoCamo"); return ResolveState(null); }
		"W5PD" F 0 { rsCamo++; A_StartSound("SPMWARP2", CHAN_VOICE); }
		"W5PD" F 2 { A_SetTranslucent(0.9, 0); }
		"W5PD" F 2 { A_SetTranslucent(0.7, 0); }
		"W5PD" F 2 { A_SetTranslucent(0.5, 0); }
		"W5PD" F 2 { A_SetTranslucent(0.3, 0); }
		"W5PD" F 2 { A_SetTranslucent(0.2, 0); }
		Goto Missile.T12.Check;
	See.T12.NoCamo:
		"W5PD" F 0 A_Jump(144, "Missile.T12.Check");
		"W5PD" F 0 { A_StartSound("SPMWARP1", CHAN_VOICE); rsCamo = max(0, rsCamo - 1); }
		"W5PD" F 2 { A_SetTranslucent(0.4, 0); }
		"W5PD" F 2 { A_SetTranslucent(0.6, 0); }
		"W5PD" F 2 { A_SetTranslucent(0.8, 0); }
		"W5PD" F 2 { A_SetTranslucent(1.0, 0); }
		Goto Missile.T12.Check;
	See.T12.Dodge1:
		TNT1 A 0 { A_StartSound("SPMDASH", CHAN_VOICE); }
		TNT1 A 0 A_Jump(128, "See.T12.Dodge2");
		"W5PD" A 2 { A_ChangeVelocity(cos(angle + 90) * 48, sin(angle + 90) * 48, 0, CVF_REPLACE); }
		"W5PD" AABBCCDD 2;
		Goto See.T12.Walk;
	See.T12.Dodge2:
		"W5PD" A 2 { A_ChangeVelocity(cos(angle - 90) * 48, sin(angle - 90) * 48, 0, CVF_REPLACE); }
		"W5PD" AABBCCDD 2;
		Goto See.T12.Walk;
	See.T12.Dodge3:
		TNT1 A 0 { A_StartSound("SPMDASH", CHAN_VOICE); }
		TNT1 A 0 A_Jump(128, "See.T12.Dodge4");
		"W5PD" F 2 { A_ChangeVelocity(cos(angle + 90) * 48, sin(angle + 90) * 48, 0, CVF_REPLACE); }
		"W5PD" FFFFFFFF 2;
		Goto See.T12.Fly;
	See.T12.Dodge4:
		"W5PD" F 2 { A_ChangeVelocity(cos(angle - 90) * 48, sin(angle - 90) * 48, 0, CVF_REPLACE); }
		"W5PD" FFFFFFFF 2;
		Goto See.T12.Fly;
	Melee.T12:
		Goto Missile.T12.Shocker2;
	Missile.T12:
		"W5PD" A 4 Bright { A_StartSound("WMIND/IDLE", CHAN_5); }
		"W5PD" A 0 A_JumpIfHealthLower(6000, "Missile.T12.Phase3");
		"W5PD" A 0 A_JumpIfHealthLower(13000, "Missile.T12.Phase2");
	Missile.T12.Phase1:
		"W5PD" A 0 A_JumpIfCloser(350, "Missile.T12.Close");
		"W5PD" A 0 A_JumpIfCloser(1300, "Missile.T12.Phase1Near");
		Goto Missile.T12.Phase1Far;
	Missile.T12.Phase1Near:
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire", "Missile.T12.SpreadFire", "Missile.T12.Rockabye", "Missile.T12.OrbShot");
		Goto Missile.T12.Check;
	Missile.T12.Phase1Far:
		"W5PD" A 0 A_Jump(128, "Missile.T12.EyeBeam");
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire", "Missile.T12.Rockabye", "Missile.T12.Charge");
		Goto Missile.T12.Check;
	Missile.T12.Phase2:
		"W5PD" A 0 A_JumpIfCloser(350, "Missile.T12.Close");
		"W5PD" A 0 { if (rsFlight >= 1) return ResolveState("Missile.T12.Phase2Flight"); return ResolveState(null); }
		"W5PD" A 0 A_JumpIfCloser(1300, "Missile.T12.Phase2Near");
		Goto Missile.T12.Phase2Far;
	Missile.T12.Phase2Near:
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire", "Missile.T12.SpreadFire", "Missile.T12.Rockabye", "Missile.T12.FloorCrack", "Missile.T12.Shield", "Missile.T12.Nukes");
		Goto Missile.T12.Check;
	Missile.T12.Phase2Far:
		"W5PD" A 0 A_Jump(128, "Missile.T12.FloorCrack");
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire", "Missile.T12.Rockabye", "Missile.T12.Charge");
		Goto Missile.T12.Check;
	Missile.T12.Phase2Flight:
		"W5PD" A 0 A_JumpIfCloser(1300, "Missile.T12.Phase2FlightNear");
		Goto Missile.T12.Phase2FlightFar;
	Missile.T12.Phase2FlightNear:
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire2", "Missile.T12.SpreadFire2", "Missile.T12.Rockabye2", "Missile.T12.Lightning", "Missile.T12.Sentinels", "Missile.T12.Webb");
		Goto Missile.T12.Check;
	Missile.T12.Phase2FlightFar:
		"W5PD" A 0 A_Jump(128, "Missile.T12.Lightning");
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire2", "Missile.T12.Rockabye", "Missile.T12.Charge2");
		Goto Missile.T12.Check;
	Missile.T12.Phase3:
		"W5PD" F 0 { if (rsEverlasting < 1) return ResolveState("Missile.T12.Everlasting"); return ResolveState(null); }
		"W5PD" F 0 { rsChaotic = max(0, rsChaotic - 1); }
		"W5PD" A 0 A_JumpIfCloser(350, "Missile.T12.Close");
		"W5PD" A 0 A_Jump(15, "Missile.T12.Chaos");
		"W5PD" A 0 { if (rsFlight >= 1) return ResolveState("Missile.T12.Phase3Flight"); return ResolveState(null); }
		"W5PD" A 0 A_JumpIfCloser(1300, "Missile.T12.Phase3Near");
		Goto Missile.T12.Phase3Far;
	Missile.T12.Phase3Near:
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire2", "Missile.T12.SpreadFire2", "Missile.T12.FloorCrack", "Missile.T12.Shield", "Missile.T12.OrbShot");
		Goto Missile.T12.Check;
	Missile.T12.Phase3Far:
		"W5PD" A 0 A_Jump(128, "Missile.T12.FloorCrack");
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire", "Missile.T12.Rockabye", "Missile.T12.Charge");
		Goto Missile.T12.Check;
	Missile.T12.Phase3Flight:
		"W5PD" A 0 A_JumpIfCloser(1300, "Missile.T12.Phase3FlightNear");
		Goto Missile.T12.Phase3FlightFar;
	Missile.T12.Phase3FlightNear:
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire2", "Missile.T12.SpreadFire2", "Missile.T12.Sentinels", "Missile.T12.Webb", "Missile.T12.Lightning");
		Goto Missile.T12.Check;
	Missile.T12.Phase3FlightFar:
		"W5PD" A 0 A_Jump(128, "Missile.T12.EyeBeam", "Missile.T12.Lightning");
		"W5PD" A 0 A_Jump(256, "Missile.T12.RapidFire2", "Missile.T12.Rockabye", "Missile.T12.Charge2");
		Goto Missile.T12.Check;
	Missile.T12.Close:
		"W5PD" A 0 { if (rsFlight >= 1) return ResolveState("Missile.T12.Close3"); return ResolveState(null); }
		"W5PD" A 0 A_JumpIfHealthLower(13000, "Missile.T12.CloseMix");
		Goto Missile.T12.Shocker;
	Missile.T12.CloseMix:
		"W5PD" A 0 A_Jump(256, "Missile.T12.Shocker", "Missile.T12.FloorCrack");
		Goto Missile.T12.Shocker;
	Missile.T12.Close2:
		"W5PD" A 0 A_JumpIfCloser(350, "Missile.T12.Close2Go");
		Goto Missile.T12;
	Missile.T12.Close2Go:
		"W5PD" A 0 { if (rsFlight >= 1) return ResolveState("Missile.T12.Close3"); return ResolveState(null); }
		"W5PD" A 0 A_JumpIfHealthLower(13000, "Missile.T12.Close2Mix");
		Goto Missile.T12.Shocker;
	Missile.T12.Close2Mix:
		"W5PD" A 0 A_Jump(256, "Missile.T12.Shocker", "Missile.T12.FloorCrack", "Missile.T12.Webb");
		Goto Missile.T12.Shocker;
	Missile.T12.Close3:
		"W5PD" A 0 A_JumpIfHealthLower(13000, "Missile.T12.Close3Mix");
		Goto Missile.T12.Shocker;
	Missile.T12.Close3Mix:
		"W5PD" A 0 A_Jump(256, "Missile.T12.Shocker", "Missile.T12.Webb");
		Goto Missile.T12.Shocker;
	Missile.T12.Check:
		"W5PD" A 0 { if (rsFlight >= 1) return ResolveState("See.T12.Fly"); return ResolveState("See.T12.Walk"); }
		Goto See;
	Missile.T12.Charge:
		TNT1 A 0 { A_StartSound("SPMDASH", CHAN_VOICE); }
		"W5PD" A 0 { if (rsFlight >= 1) return ResolveState("Missile.T12.Charge2"); return ResolveState(null); }
		"W5PD" F 1 { A_FaceTarget(); }
		"W5PD" F 1 { A_Recoil(-80); }
		"W5PD" AABBCCDD 2;
		"W5PD" A 0 A_JumpIfHealthLower(13000, "Missile.T12.Close2");
		Goto Missile.T12;
	Missile.T12.Charge2:
		"W5PD" F 1 { A_FaceTarget(); }
		"W5PD" F 1 { A_Recoil(-80); }
		"W5PD" FFFFFFFF 2;
		"W5PD" A 0 A_JumpIfHealthLower(13000, "Missile.T12.Close2");
		Goto Missile.T12;
	Missile.T12.RapidFire:
		"W5PD" FE 5 Bright { A_FaceTarget(); }
	Missile.T12.RapidFireGo:
		"W5PD" E 0 { A_FaceTarget(); }
		"W5PD" F 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, 0); }
		"W5PD" F 4 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 0); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, 0); }
		"W5PD" E 4 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 0); }
		"W5PD" F 0 A_Jump(48, "Missile.T12.Charge", "Missile.T12.Check");
		"W5PD" F 0 A_CheckSight("Missile.T12.RapidFireGo");
		"W5PD" F 0 A_Jump(192, "Missile.T12.RapidFireGo");
		Goto Missile.T12.Check;
	Missile.T12.RapidFire2:
		"W5PD" FE 5 Bright { A_FaceTarget(); }
	Missile.T12.RapidFire2Go:
		"W5PD" E 0 { A_FaceTarget(); }
		"W5PD" F 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, 6); }
		"W5PD" F 2 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 6); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -6); }
		"W5PD" E 2 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, -6); }
		"W5PD" E 0 { A_FaceTarget(); }
		"W5PD" F 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, 6); }
		"W5PD" F 2 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 6); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, 0); }
		"W5PD" E 2 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 0); }
		"W5PD" F 0 A_Jump(24, "Missile.T12.Charge", "Missile.T12.Check");
		"W5PD" F 0 A_CheckSight("Missile.T12.RapidFire2Go");
		"W5PD" F 0 A_Jump(224, "Missile.T12.RapidFire2Go");
		Goto Missile.T12.Check;
	Missile.T12.SpreadFire:
		"W5PD" F 4 Bright { A_FaceTarget(); }
	Missile.T12.SpreadFireGo:
		"W5PD" E 4 { A_FaceTarget(); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, 0); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -8); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -16); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -24); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -32); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -40); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 0); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 8); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 16); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 24); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 32); }
		"W5PD" E 4 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 40); }
		"W5PD" FFF 4 { A_FaceTarget(); }
		"W5PD" F 0 A_Jump(72, "Missile.T12.Charge", "Missile.T12.Check");
		"W5PD" F 0 A_CheckSight("Missile.T12.SpreadFireGo");
		"W5PD" F 0 A_Jump(128, "Missile.T12.SpreadFireGo");
		Goto Missile.T12.Check;
	Missile.T12.SpreadFire2:
		"W5PD" F 4 Bright { A_FaceTarget(); }
	Missile.T12.SpreadFire2Go:
		"W5PD" E 2 { A_FaceTarget(); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, 0); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -8); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -16); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -24); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -32); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, 24, -40); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 0); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 8); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 16); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 24); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 32); }
		"W5PD" E 2 Bright { A_SpawnProjectile("RS_WhiteMindshot1", 40, -24, 40); }
		"W5PD" FFF 2 { A_FaceTarget(); }
		"W5PD" F 0 A_Jump(36, "Missile.T12.Charge", "Missile.T12.Check");
		"W5PD" F 0 A_CheckSight("Missile.T12.SpreadFire2Go");
		"W5PD" F 0 A_Jump(192, "Missile.T12.SpreadFire2Go");
		Goto Missile.T12.Check;
	Missile.T12.Rockabye:
		// CHP: ThrustThingZ(0,100,..) + ThrustThing(angle+-90,100,..)
		"W5PD" F 0 { double a = angle + randompick(90, -90); A_ChangeVelocity(cos(a) * 25, sin(a) * 25, 25, CVF_REPLACE); }
		"W5PD" FE 5 Bright { A_FaceTarget(); }
	Missile.T12.RockabyeGo:
		"W5PD" E 0 { A_FaceTarget(); }
		"W5PD" F 0 { A_SpawnProjectile("RS_ESPlasmaRocket", 40, 24, 0); }
		"W5PD" F 6 Bright { A_SpawnProjectile("RS_ESPlasmaRocket", 40, -24, 0); }
		"W5PD" E random(3, 9) { A_FaceTarget(); }
		"W5PD" F 0 A_Jump(48, "Missile.T12.Charge", "Missile.T12.Check");
		"W5PD" F 0 A_CheckSight("Missile.T12.RockabyeGo");
		"W5PD" F 0 A_Jump(192, "Missile.T12.RockabyeGo");
		Goto Missile.T12.Check;
	Missile.T12.Rockabye2:
		"W5PD" F 0 { double a = angle + randompick(90, -90); A_ChangeVelocity(cos(a) * 25, sin(a) * 25, 25, CVF_REPLACE); }
		"W5PD" FE 5 Bright { A_FaceTarget(); }
	Missile.T12.Rockabye2Go:
		"W5PD" E 0 { A_FaceTarget(); }
		"W5PD" F 0 { A_SpawnProjectile("RS_ESPlasmaRocket", 40, 24, random(-5, 5)); }
		"W5PD" F 3 Bright { A_SpawnProjectile("RS_ESPlasmaRocket", 40, -24, random(-5, 5)); }
		"W5PD" E random(2, 5) { A_FaceTarget(); }
		"W5PD" F 0 A_Jump(24, "Missile.T12.Charge", "Missile.T12.Check");
		"W5PD" F 0 A_CheckSight("Missile.T12.Rockabye2Go");
		"W5PD" F 0 A_Jump(224, "Missile.T12.Rockabye2Go");
		Goto Missile.T12.Check;
	Missile.T12.Shocker:
		"W5PD" F 0 A_CheckSight("Missile.T12.Check");
		"W5PD" F 4 Bright { A_FaceTarget(); }
		"W5PD" F 5 Bright { A_StartSound("weapons/bfgf", CHAN_WEAPON); }
		"W5PD" FFFEE 5 Bright { A_FaceTarget(); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, 24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, 24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, -24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, -24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EF 9;
		Goto Missile.T12.Check;
	Missile.T12.Shocker2:
		"W5PD" F 0 A_CheckSight("Missile.T12.Check");
		"W5PD" F 4 Bright { A_FaceTarget(); }
		"W5PD" F 5 Bright { A_StartSound("weapons/bfgf", CHAN_WEAPON); }
		"W5PD" FFFEE 5 Bright { A_FaceTarget(); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, 24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, 24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, 24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, 24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, -24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, -24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, -24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" EEEEEEEEEEEEEEEEEEEEEEEE 0 { A_SpawnProjectile("RS_ESZapper", 40, -24, random(-40, 40), 32, random(-3, 3)); }
		"W5PD" E 9 Bright { A_FaceTarget(); }
		"W5PD" F 9 A_Jump(96, "Missile.T12");
		Goto Missile.T12.Check;
	Missile.T12.OrbShot:
		"W5PD" A 0 { A_StartSound("ELECFATT", CHAN_WEAPON); }
		"W5PD" FE 5 Bright { A_FaceTarget(); }
		"W5PD" F 2 Bright { A_SpawnProjectile("RS_WhiteMindCrackleOrb", 40, 0, 0); }
		"W5PD" F 20;
		"W5PD" F 0 A_Jump(64, "Missile.T12.OrbShot");
		Goto Missile.T12.Check;
	Missile.T12.EyeBeam:
		"W5PD" F 0 A_CheckSight("Missile.T12.Check");
		"W5PD" F 5 Bright { A_FaceTarget(); }
		"W5PD" F 5 Bright { A_StartSound("ECHOIMPB", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"W5PD" FFFF 5 Bright { A_FaceTarget(); }
		"W5PD" F 6 Bright { A_CustomRailgun(0, 0, "", "Cyan", RGF_NOPIERCING | RGF_SILENT, 1); }
		"W5PD" F 6 Bright { A_CustomRailgun(0, 0, "", "Cyan", RGF_NOPIERCING | RGF_SILENT, 1); }
		"W5PD" F 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"W5PD" E 4 Bright { A_CustomRailgun(random(10, 40), 0, "Cyan", "Cyan", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ | RGF_SILENT, 1, 0, "RS_WhiteMindRB3", 0, 0, 0, 66, 0.7, 0.9, "RS_WhiteMindRB4", 7, 10); }
		"W5PD" F 20 A_Jump(96, "Missile.T12");
		Goto Missile.T12.Check;
	Missile.T12.FloorCrack:
		"W5PD" E 4 Bright { A_FaceTarget(); }
		"W5PD" F 0 { bTHRUACTORS = true; A_StartSound("SPMHOP1", CHAN_VOICE); A_ChangeVelocity(0, 0, 25, CVF_REPLACE); }
	Missile.T12.FloorCrackHang:
		"W5PD" FFF 8 Bright { A_FaceTarget(); }
		"W5PD" E 1 Bright A_CheckFloor("Missile.T12.Cracked");
		Goto Missile.T12.FloorCrackHang;
	Missile.T12.Cracked:
		"W5PD" E 0 { for (int i = 0; i < 36; i++) A_SpawnProjectile("RS_MolochQuake", 0, 0, i * 10); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteSpidWinder", 8, 16, -112); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteSpidWinder", 8, -16, 112); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteSpidWinder", 8, 16, -72); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteSpidWinder", 8, -16, 72); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteSpidWinder", 8, 16, -32); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteSpidWinder", 8, -16, 32); }
		"W5PD" E 5 { A_StartSound("monster/hadexp", CHAN_WEAPON); }
		"W5PD" F 0 { bTHRUACTORS = false; }
		Goto Missile.T12.Check;
	Missile.T12.Shield:
		"W5PD" F 4 Bright { if (rsShield >= 1) return ResolveState("Missile.T12"); return ResolveState(null); }
		"W5PD" F 0 { rsShield = 1; }
		"W5PD" FFFFF 9 Bright { A_SpawnItemEx("RS_WhiteSpidShieldWalk", 0, 4, 128, 0, 0, 0, 0, SXF_SETMASTER); }
		Goto Missile.T12;
	Missile.T12.Nukes:
		"W5PD" F 8 Bright { A_FaceTarget(); }
		"W5PD" FFFFFFFFF 2 Bright { A_SpawnItemEx("RS_WhiteFatNukeShow", random(-70, 70), random(-70, 70), 64, 0, 0, 12, 0, SXF_NOCHECKPOSITION); }
		"W5PD" EEEEEEEEE 2 Bright { A_SpawnItemEx("RS_WhiteFatMark", random(-1524, 1524), random(-1524, 1524), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"W5PD" F 8 A_Jump(96, "Missile.T12");
		Goto Missile.T12.Check;
	Missile.T12.Lightning:
		"W5PD" F 9 Bright { A_FaceTarget(); }
		"W5PD" E 12 Bright { A_VileTarget("RS_WhiteSpidMegaStrike"); }
		"W5PD" F 9 Bright A_Jump(64, "Missile.T12.Lightning");
		"W5PD" F 0 A_Jump(96, "Missile.T12");
		Goto Missile.T12;
	Missile.T12.Sentinels:
		"W5PD" F 4 Bright { A_StartSound("SPMTARG2", CHAN_VOICE); }
		"W5PD" E 8 Bright { A_FaceTarget(); }
		"W5PD" EEEEEE 3 { A_PainAttack("RS_MiniSentinelSpider"); }
		"W5PD" F 4 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(96, "Missile.T12");
		Goto Missile.T12.Check;
	Missile.T12.Webb:
		"W5PD" FE 5 Bright { A_FaceTarget(); }
		"W5PD" E 0 { A_FaceTarget(); }
		"W5PD" FF 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, 24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" F 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" F 2 Bright { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" EE 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, 24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" E 2 Bright { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" FF 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, 24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" F 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" F 2 Bright { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" EE 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, 24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" E 2 Bright { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" FF 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, 24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" F 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" F 2 Bright { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" EE 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, 24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" E 0 { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		"W5PD" E 2 Bright { A_SpawnProjectile("RS_WhiteMindWebShot", 40, -24, random(-64, 64), 32, random(-5, 5)); }
		Goto Missile.T12.Check;
	Missile.T12.Chaos:
		"W5PD" F 0 { if (rsChaotic > 0) return ResolveState("Missile.T12"); return ResolveState(null); }
		"W5PD" F 0 { A_StartSound("WMINDAGR", CHAN_5); }
		"W5PD" FE 8 Bright { A_FaceTarget(); }
		"W5PD" F 0 { rsChaotic += 12; A_SpawnProjectile("RS_WhiteSpidChaosBall", 40, 0, random(0, 360), CMF_AIMOFFSET, 12); }
		"W5PD" FFFFEEEE 2 { A_SetAngle(angle + 45); }
		Goto Missile.T12.Check;
	Missile.T12.Everlasting:
		"W5PD" F 9 Bright { A_Quake(180, 90, 0, 900); }
		"W5PD" E 12 Bright { A_StartSound("WMINDRAG", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"W5PD" F 3 Bright { rsEverlasting = 1; }
		"W5PD" E 3;
		"W5PD" F 3 Bright { A_SetSpeed(36); }
		"W5PD" EF 3 Bright;
		"W5PD" F 0 { if (rsFlight >= 1) return ResolveState("Missile.T12.EyeBeam"); return ResolveState(null); }
		Goto Missile.T12.FloorCrack;
	Pain.T12:
		"W5PD" F 3;
		"W5PD" F 3 { A_Pain(); }
		Goto See;
	Death.T12:
		"W5PD" F 0 { bFLOAT = false; bNOGRAVITY = false; A_StopSound(CHAN_6); ReleaseMinions(); }
		"W5PD" F 10 { A_NoBlocking(); }
		"W5PD" FABDF 10 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-60, 60), 0, CMF_AIMOFFSET, -10); }
		"W5PD" AFDCF 8 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-60, 60), 0, CMF_AIMOFFSET, -10); }
		"W5PD" BFDCD 3 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-60, 60), 0, CMF_AIMOFFSET, -10); }
		"W5PD" FFFFFFFFFFF 1 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-60, 60), 0, CMF_AIMOFFSET, -10); }
		"W5PD" F 20 { A_Scream(); }
		"W5PD" F 1 { A_BossDeath(); }
		"W5PD" F 0 { A_SetTranslucent(1.0); A_SetScale(2, 2); A_StartSound("weapons/rocklx", CHAN_5); }
		"MISL" XYZ 4 Bright;
		"MISL" X 0 { A_StartSound("weapons/rocklx", CHAN_5); }
		"MISL" XYZ 4 Bright;
		"MISL" X 0 { A_StartSound("weapons/rocklx", CHAN_5); }
		"MISL" XYZ 4 Bright;
		TNT1 A -1;
		Stop;
	}
}
