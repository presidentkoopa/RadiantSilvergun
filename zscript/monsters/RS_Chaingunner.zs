// =====================================================================
// RS_Chaingunner -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\04\04_<code>.txt
// One CHP file per colour; each is a genuinely different creature with
// its OWN sprite set, stats, and attack. Nothing here is inferred,
// tinted, or shared -- every tier below was read out of its CHP file.
// CH's Chaingunners.txt was consulted ONLY for states CHP leaves
// undefined; where the two disagree, CHP wins.
//
//   tier  CHP   body   HP    what it actually is
//   T00   04_C  CPOS     70  vanilla captain: twin-frame chaingun loop
//   T01   04_G  CGUG     90  green: wide, jittery tracer burst
//   T02   04_B  CGUB    111  blue: RAILGUN at range, prox-puff up close
//   T03   04_CY CGCY    150  cyan "Jetpack Larry": rocket-hop dodges,
//                            then a 10-stage tightening ice barrage
//   T04   04_P  UCHA    146  purple: seeking micro-rockets, three
//                            grades by range band
//   T05   04_Y  PZOW    192  yellow plasma gunner: paired railgun
//                            volleys far out, plasma spam close in
//   T06   04_A  MPOS    400  abyss captain: fades to 10% alpha while
//                            stalking; splash charges or ice rapid-fire
//   T07   04_F  CGUF    175  fireblu: fastest non-boss, 14-shot volley
//   T08   04_BR CZV1    144  brown: DEPLOYS SANDBAG COVER, then walks
//                            its aim in, or lobs orbs past 1400
//   T09   04_GY UCH2    300  gray: hops constantly, refuses to fire in
//                            mid-air; ripper tracers or a lobbed bomb
//   T10   04_R  CPS2    250  red: detonating rounds, three grades, and
//                            it side-steps when hurt
//   T11   04_K  BFGZ   4500  THE GENERAL: seeker spam / reflective
//                            invulnerable shield + burst / BFG windup
//   T12   04_W  FSZS   6666  the crazy lady scientist: puddles, dart
//                            storms, three live experiments, and a
//                            phase-2 at 4444 HP
//   TEX   04_KX HCPO  11249  GREEN WARFACE: the EX tier. Four heavy
//                            options (nine-stage bomb, seeking mega-
//                            bomb, detonating rapid fire, spam volley),
//                            each behind its own range gate, and a
//                            phase-2 at 6250 HP that turns MISSILEEVEN-
//                            MORE and ALWAYSFAST on permanently
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
//
// RS mechanics preserved from the previous file: the T08+ threshold
// rage + CallHelp summon (RS_CG_RAGE_SLOT / RS_CG_TIER_PHASE /
// RS_CheckRage), GetBaseKeywords(), MinionsDieWithMe(). Family-wide
// rolls live in the Missile:/Pain: dispatcher overrides, exactly as
// RS_Cacodemon does it.
//
// REBUILD NOTES (what is NOT verbatim, and why):
//  * CHP-only cruft stripped everywhere: NewIconCHP*_T1_C spawners,
//    ColorTierIconCH*, CHRandom_GibGenerator, A_SpawnParticle gib
//    confetti, the CHWhitePlan inventory check and its Tickles state,
//    Random-
//    LetterSpawner_C, CH_Cirno_C, CH_Cactus_C, A_GivetoChildren
//    ("GoAway"), the Grow/GrowRaisin ladder (CH's own tiering -- RS
//    owns that now), and every ACS call (AnnounceBlackCGuy_C,
//    AnnounceWhiteCG_C, CH_CyanBounce).
//  * user_hide (T06) and User_Ph2 (T12) become private int fields.
//  * T03 and T11 ship no Raise in CHP or CH, and T12 ships
//    "Raise: Stop". The base class always exposes a Raise dispatcher,
//    so "cannot be raised" is not representable here; those three get a
//    reverse-death Raise in their OWN body rather than falling through
//    to T00's CPOS, which is the wrong-creature bug this rebuild exists
//    to kill.
//  * CH colour voices (cguy2/*, form2/*, lady/*, SSGUNER/*, Science/*,
//    SPMHOP2, misc/gibbed/c) have no SNDINFO entry in this repo yet, so
//    those A_PlaySound calls are dropped rather than left dangling.
// =====================================================================

class RS_Chaingunner : RS_MonsterMaster replaces ChaingunGuy
{
	// CHP's abyss captain hides once per approach; the lady scientist's
	// phase change fires once. Both are user_ vars in CHP.
	private int rsHideUsed;
	private int rsPhase2Done;

	Default
	{
		Health 70;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "chainguy/sight";  PainSound "chainguy/pain";
		DeathSound "chainguy/death"; ActiveSound "chainguy/active";
		AttackSound "chainguy/attack";
		Obituary "$OB_CHAINGUY";
		Tag "Chaingunner";
		DropItem "Chaingun";
	}

	// CHP's real per-colour numbers, read from 04_*.txt. Health is
	// absolute (not a multiplier) -- these are hand-tuned creatures.
	// The curve is NOT monotonic and that is deliberate: T09 is the
	// slowest tier in the family (speed 5) yet the toughest of the
	// middle band, and T07 is faster than either boss.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 170; r.dmgMul = 1.0;
		int hp = 70; int spd = 8;
		switch (t)
		{
			case 0:  hp = 70;   spd = 8;  r.painChance = 170; r.dmgMul = 1.0; break;
			case 1:  hp = 90;   spd = 8;  r.painChance = 150; r.dmgMul = 1.1; break;
			case 2:  hp = 111;  spd = 8;  r.painChance = 150; r.dmgMul = 1.2; break;
			case 3:  hp = 150;  spd = 11; r.painChance = 88;  r.dmgMul = 1.3; break;
			case 4:  hp = 146;  spd = 8;  r.painChance = 150; r.dmgMul = 1.4; break;
			case 5:  hp = 192;  spd = 10; r.painChance = 135; r.dmgMul = 1.5; break;
			case 6:  hp = 400;  spd = 8;  r.painChance = 80;  r.dmgMul = 1.6; break;
			case 7:  hp = 175;  spd = 18; r.painChance = 135; r.dmgMul = 1.5; break;
			case 8:  hp = 144;  spd = 6;  r.painChance = 102; r.dmgMul = 1.4; break;
			case 9:  hp = 300;  spd = 5;  r.painChance = 135; r.dmgMul = 1.7; break;
			case 10: hp = 250;  spd = 10; r.painChance = 88;  r.dmgMul = 1.8; break;
			case 11: hp = 4500; spd = 10; r.painChance = 25;  r.dmgMul = 2.5; break;
			case 12: hp = 6666; spd = 14; r.painChance = 20;  r.dmgMul = 3.0; break;
			// TEX -- CHP 04_KX CommonBlackCGuyEX2, THE FIRST ACTOR (04_KX.txt:1).
			// WAS GreenBlackCGuyEX2 (04_KX.txt:114), the SECOND actor:
			//   Common  8999 / 20 / 12   04_KX.txt:3,:4,:5
			//   Green  11249 / 25 / 10   04_KX.txt:116,:117,:118
			case 13: hp = 8999;  spd = 20; r.painChance = 12; r.dmgMul = 3.5; break;
			default: return false;
		}

		// =============================================================
		// THE CH PARENT PROPERTIES.  CH/decorate/Chaingunners.txt.
		// See docs/rs_24_ch_parent_properties.txt for why these were
		// missing everywhere. Parent name and line on every case.
		//
		// THIS FAMILY HAS SIX SPECIES STRINGS. CH splits it across
		// "CGuy" (T00), "Cguy" (T02 -- ONE LETTER'S CASE apart from
		// T00, copied through as CH spells it rather than tidied),
		// "Cguy2" (T04), "Cguy3" (T05, T07), "BrownCguy" (T08) and
		// "Science" (T12). SEVEN TIERS STATE NONE AT ALL, which is not
		// the same as sharing one. With +DONTHARMSPECIES that is a
		// deliberate infighting web -- do not normalise it.
		//
		// SEVEN TIERS HAVE +AVOIDMELEE and seven do not, and T03/T08/T10
		// carry AVOIDMELEE *and* MISSILEMORE together -- back off and
		// keep firing.
		//
		// The two +MISSILEEVENMORE actors are MID-TIER (T05, T06), not
		// the bosses. The "bosses get evenmore" rule is true of the Imp
		// family and false here; it is not a family-agnostic pattern.
		// =============================================================
		r.mass = 100; r.scale = 1.0; r.renderStyle = -1;
		switch (t)
		{
			case 0:   // CommonCGuy : ChaingunGuy  Chaingunners.txt:995
				r.species = "CGuy";
				r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES;
				break;
			case 1:   // GreenCGuy                Chaingunners.txt:1077
				// CH states NO Species here -- it breaks the chain.
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES;
				break;
			case 2:   // BlueCGuy                 Chaingunners.txt:1178
				r.species = "Cguy";     // CH's own casing, cf. T00
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES;
				break;
			case 3:   // CyanCGuy2                 Chaingunners.txt:256
				// Mass 3500 and the only tier with BOTH AVOIDMELEE and
				// MISSILEMORE plus a real alpha.
				r.radius = 20; r.height = 56; r.mass = 3500;
				r.alpha = 0.95; r.renderStyle = STYLE_Add;
				r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES
				        | RS_TF_NOFEAR | RS_TF_NOICEDEATH
				        | RS_TF_LAXTELEFRAGDMG;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 4:   // PurpleCGuy               Chaingunners.txt:1348
				r.species = "Cguy2";
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES;
				break;
			case 5:   // YellowCGuy               Chaingunners.txt:1511
				// BOTH missile flags on a mid-tier grunt, and NO
				// AvoidMelee -- it closes and hoses.
				r.species = "Cguy3";
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_DONTHARMSPECIES;
				r.missileChance = 0.0625;   // MORE *and* EVENMORE
				break;
			case 6:   // AbyssCGuy2                Chaingunners.txt:434
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_DONTHARMSPECIES;
				r.missileChance = 0.0625;   // MORE *and* EVENMORE
				break;
			case 7:   // FireBluCGuy2              Chaingunners.txt:827
				r.species = "Cguy3";      // allied with the yellow
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_DONTHARMSPECIES;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 8:   // BrownCGuy2                 Chaingunners.txt:40
				// Its OWN species, so it infights the whole family, and
				// the only tier with +NOINFIGHTING to stop it retaliating.
				r.species = "BrownCguy";
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES
				        | RS_TF_NOINFIGHTING | RS_TF_NOFEAR
				        | RS_TF_NOTARGET;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 9:   // CommonGrayCGuy -- NO CH PARENT AT ALL.
				// Declared with no colon in CHP/DECORATE/04/04_GY.txt;
				// the whole property block is CHP's. Radius 18, not 20.
				// (There is an orphan copy at CHP/DECORATE/04GY.txt with
				// DIFFERENT values -- DECORATE.txt:704 includes the
				// FOLDER copy, so that one is dead. Do not read it.)
				r.radius = 18; r.height = 56; r.mass = 400;
				r.scale = 0.9; r.gibHealth = -100;
				r.flags = RS_TF_DONTHARMSPECIES;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 10:  // RedCGuy                  Chaingunners.txt:1707
				r.mass = 1000;
				r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 11:  // BlackCGuy2               Chaingunners.txt:2280
				// No DONTHARMSPECIES -- it uses DONTHARMCLASS instead.
				r.radius = 20; r.height = 56; r.mass = 1000;
				r.flags = RS_TF_BOSS | RS_TF_TAKESRADIUSDMG
				        | RS_TF_DONTHARMCLASS | RS_TF_DONTMORPH
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 12:  // WhiteCguy2               Chaingunners.txt:2520
				// Species "Science". Smallest body in the family at
				// 19/52 and Mass 90 -- the scientist is frail and light.
				r.species = "Science";
				r.radius = 19; r.height = 52; r.mass = 90;
				r.radiusDamageFactor = 0.5;
				r.flags = RS_TF_BOSS | RS_TF_TAKESRADIUSDMG
				        | RS_TF_THRUSPECIES | RS_TF_DONTHARMSPECIES
				        | RS_TF_DONTHARMCLASS | RS_TF_DONTMORPH
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 13:  // BlackCGuyEX              Chaingunners.txt:1909
				// +MISSILEMORE only. The EX turns MISSILEEVENMORE on at
				// phase 2 from its own states -- that is a state-layer
				// change and does not belong in this row.
				r.radius = 20; r.height = 56; r.mass = 1000;
				r.flags = RS_TF_BOSS | RS_TF_TAKESRADIUSDMG
				        | RS_TF_DONTHARMCLASS | RS_TF_DONTMORPH
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			default:
				break;
		}
		// Default Health is 70, Default Speed 8 -- express CHP's absolute
		// numbers as multipliers so the base class's recompute-from-
		// defaults contract still holds.
		r.hpMul  = double(hp) / 70.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/Chaingunner/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		return "CPOS CGUG CGUB CGCY UCHA PZOW MPOS CGUF CZV1 UCH2 CPS2 BFGZ FSZS HCPO";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	// TEX is the exception: CH's HCPO set is BLACK (it is CH BlackCGuyEX's
	// body) and CHP's EX variants recolour it per colour, so the green EX
	// carries a real translation. Recipe in TRNSLATE.txt as rs_cgun_tex.
	override string TintTable()
	{
		//      T00 T01 T02 T03 T04 T05 T06 T07 T08 T09 T10 T11 T12 TEX
		// TEX SLOT WAS rs_cgun_tex -- GreenBlackCGuyEX2's Translation
		// (04_KX.txt:125). CommonBlackCGuyEX2 has none. The old comment
		// here argued the tint was legitimate because "CHP recolours the
		// EX per colour" -- true of the GREEN EX, and exactly why it does
		// not belong on the tier we ship.
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:chaingunner role:skirmisher delivery:bullet element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// CHP's high-tier chaingunners enrage around 2/3 health and
	// PERMANENTLY gain a summon they did not have before -- the second
	// half of the fight is a different fight. That's the mechanic worth
	// keeping, and it is the one piece of the old file that survives.
	// -----------------------------------------------------------------
	const RS_CG_RAGE_SLOT  = 0;
	const RS_CG_TIER_PHASE = 8;

	override bool MinionsDieWithMe() { return true; }

	// Fires the one-shot rage gate. Called from Pain so the threshold is
	// checked whenever it actually takes damage.
	void RS_CheckRage()
	{
		if (Tier >= RS_CG_TIER_PHASE && CheckThreshold(RS_CG_RAGE_SLOT, 0.66))
		{
			Enrage(1.2);
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	States
	{
	// ===== dispatchers: family-wide rolls happen here =====
	Missile:
		TNT1 A 0
		{
			// Only reachable AFTER the rage threshold has fired.
			if (Tier >= RS_CG_TIER_PHASE && ThresholdFired(RS_CG_RAGE_SLOT)
			    && random(0, 255) < 60)
				return ResolveState("CallHelp");
			return TierState("Missile");
		}
		Goto See;
	Pain:
		TNT1 A 0
		{
			RS_CheckRage();
			return TierState("Pain");
		}
		Goto See;

	// The summon, routed per tier so it is always performed in the body
	// the monster is actually wearing -- no #### placeholder, no T00
	// fallback. Only T08+ can reach it, but T00 exists as the safety net.
	CallHelp:
		TNT1 A 0 { return TierState("CallHelp"); }
		Goto See;
	CallHelp.T00:
		"CPOS" E 10 { A_FaceTarget(); }
		"CPOS" F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	CallHelp.T08:
		"CZV1" E 10 { A_FaceTarget(); }
		"CZV1" F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	CallHelp.T09:
		"UCH2" E 10 { A_FaceTarget(); }
		"UCH2" F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	CallHelp.T10:
		"CPS2" E 10 { A_FaceTarget(); }
		"CPS2" F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	CallHelp.T11:
		"BFGZ" E 10 { A_FaceTarget(); }
		"BFGZ" F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	CallHelp.T12:
		"FSZS" E 10 { A_FaceTarget(); }
		"FSZS" F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	CallHelp.TEX:
		"HCPO" E 10 { A_FaceTarget(); }
		"HCPO" F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;

	// ================= T00 COMMON (04_C) =================
	// The vanilla captain -- but CHP fires on BOTH the F and the E frame
	// with its own bullet call rather than A_CPosAttack, and refires off
	// the F frame. The sustained loop is the whole family's spine.
	Spawn.T00:
		"CPOS" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"CPOS" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T00:
		"CPOS" E 10 { A_FaceTarget(); }
	Missile.T00.Loop:
		"CPOS" F 0 { A_StartSound("chainguy/attack", CHAN_WEAPON); }
		"CPOS" F 4 Bright { A_CustomBulletAttack(22.5, 0, 1, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"CPOS" E 0 { A_StartSound("chainguy/attack", CHAN_WEAPON); }
		"CPOS" E 4 Bright { A_CustomBulletAttack(22.5, 0, 1, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"CPOS" F 1 { A_CPosRefire(); }
		Goto Missile.T00.Loop;
	Pain.T00:
		"CPOS" G 3;
		"CPOS" G 3 { A_Pain(); }
		Goto See;
	Death.T00:
		"CPOS" H 5;
		"CPOS" I 5 { A_Scream(); }
		"CPOS" J 5 { A_NoBlocking(); }
		"CPOS" KLM 5;
		"CPOS" N -1;
		Stop;
	XDeath.T00:
		"CPOS" O 5 { A_XScream(); }
		"CPOS" P 5 { A_NoBlocking(); }
		"CPOS" QRS 5;
		"CPOS" T -1;
		Stop;
	Raise.T00:
		"CPOS" N 5;
		"CPOS" MLKJIH 5;
		Goto See;

	// ================= T01 GREEN (04_G) =================
	// Same silhouette, different gun: spread, vertical spread and shot
	// count are ALL rolls, so the burst sprays.
	Spawn.T01:
		"CGUG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"CGUG" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T01:
		"CGUG" E 12 { A_FaceTarget(); }
	Missile.T01.Loop:
		"CGUG" FE 4 Bright { A_CustomBulletAttack(random(6, 17), random(3, 13), random(1, 2), random(1, 8), "RS_Trail11"); }
		"CGUG" F 3 A_MonsterRefire(150, "See");
		Goto Missile.T01.Loop;
	Pain.T01:
		"CGUG" G 3;
		"CGUG" G 3 { A_Pain(); }
		Goto See;
	Death.T01:
		"CGUG" H 5;
		"CGUG" I 5 { A_Scream(); }
		"CGUG" J 5 { A_NoBlocking(); }
		"CGUG" KLM 5;
		"CGUG" N -1;
		Stop;
	XDeath.T01:
		"CGUG" O 5;
		"CGUG" P 5 { A_XScream(); }
		"CGUG" Q 5 { A_NoBlocking(); }
		"CGUG" RS 5;
		"CGUG" T -1;
		Stop;
	Raise.T01:
		"CGUG" N 5;
		"CGUG" MLKJIH 5;
		Goto See;

	// ================= T02 BLUE (04_B) =================
	// A RAILGUNNER. Past 1200 and 600-1200 it fires a rail plus a single
	// tracer round; inside 600 it drops the rail entirely for a beeping
	// proximity puff and a six-pellet burst.
	Spawn.T02:
		"CGUB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"CGUB" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T02:
		"CGUB" E 12 { A_FaceTarget(); }
	Missile.T02.Loop:
		TNT1 A 0 A_JumpIfCloser(600, "Missile.T02.Closer", false);
		TNT1 A 0 A_JumpIfCloser(1200, "Missile.T02.M1", false);
		"CGUB" E 3 Bright;
		"CGUB" F 6 Bright { A_CustomRailgun(random(1, 2), 0, "", "00 00 FF", RGF_NOPIERCING); }
		"CGUB" E 0 Bright { A_CustomBulletAttack(0, 0, 1, random(1, 4), "RS_BlueChainPuff2"); }
		"CGUB" E 5 Bright;
		"CGUB" F 1 A_MonsterRefire(150, "See");
		Goto Missile.T02.Loop;
	Missile.T02.M1:
		"CGUB" E 3 Bright;
		"CGUB" F 6 Bright { A_CustomRailgun(random(1, 3), 0, "", "00 00 FF", RGF_NOPIERCING); }
		"CGUB" E 0 Bright { A_CustomBulletAttack(0, 0, 1, random(2, 8), "RS_BlueChainPuff2"); }
		"CGUB" E 5 Bright;
		"CGUB" F 1 A_MonsterRefire(150, "See");
		Goto Missile.T02.Loop;
	Missile.T02.Closer:
		"CGUB" E 5 Bright;
		"CGUB" F 7 Bright { A_SpawnProjectile("RS_BlueChainPuff3", 28, 15, 0, 0, 0); }
		"CGUB" E 0 Bright { A_CustomBulletAttack(15, 15, 6, random(2, 8), "RS_BlueChainPuff2", 8000); }
		"CGUB" E 5 Bright;
		"CGUB" F 1 A_MonsterRefire(150, "See");
		Goto Missile.T02.Loop;
	Pain.T02:
		"CGUB" G 3;
		"CGUB" G 3 { A_Pain(); }
		Goto See;
	Death.T02:
		"CGUB" H 5;
		"CGUB" I 5 { A_Scream(); }
		"CGUB" J 5 { A_NoBlocking(); }
		"CGUB" KLM 5;
		"CGUB" N -1;
		Stop;
	XDeath.T02:
		"CGUB" O 5;
		"CGUB" P 5 { A_XScream(); }
		"CGUB" Q 5 { A_NoBlocking(); }
		"CGUB" RS 5;
		"CGUB" T -1;
		Stop;
	Raise.T02:
		"CGUB" N 5;
		"CGUB" MLKJIH 5;
		Goto See;

	// ================= T03 CYAN (04_CY) =================
	// "Jetpack Larry". Rocket-hops sideways and backwards constantly,
	// then opens with a ten-stage barrage whose spread tightens shot by
	// shot before settling into a dead-accurate sustained loop.
	// A_Burst on death -- it shatters, there is no corpse.
	Spawn.T03:
		"CGCY" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"CGCY" AABBCCDD 2 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "See.T03.Dodge");
		TNT1 A 0 A_Jump(232, "See.T03.Hunt", "See.T03.Fast");
		Loop;
	See.T03.Fast:
		"CGCY" AABBCCDD 1 { A_FastChase(); }
		Goto See;
	See.T03.Hunt:
		TNT1 A 0 A_JumpIfInTargetLOS("See.T03.Jumpy", 0, JLOSF_DEADNOJUMP, 750);
		Goto See;
	See.T03.Jumpy:
		"CGCY" A 2 { A_FastChase(); }
		"CGCY" A 1 ThrustThingZ(0, 64, 0, 0);
		"CGCY" A 3 ThrustThing(angle - randompick(130, 180, 230), 12, 0, 0);
		"CGCY" A 1 ThrustThingZ(0, 32, 0, 0);
		"CGCY" A 1 ThrustThing(angle, 24, 0, 0);
		Goto See;
	See.T03.Dodge:
		TNT1 A 0 A_Jump(256, "See.T03.Dodge1", "See.T03.Dodge2");
	See.T03.Dodge1:
		TNT1 A 0 ThrustThingZ(0, 68, 0, 0);
		"CGCY" A 5 ThrustThing(angle * 256 / 360 + 64, 20, 0, 0);
		Goto See;
	See.T03.Dodge2:
		TNT1 A 0 ThrustThingZ(0, 68, 0, 0);
		"CGCY" A 5 ThrustThing(angle * 256 / 360 + 192, 20, 0, 0);
		Goto See;
	Missile.T03:
		"CGCY" E 11 { A_FaceTarget(); }
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-11, 11), 0, random(-5, 5)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-10, 10), 0, random(-4, 4)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" E 0 { A_FaceTarget(); }
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-9, 9), 0, random(-4, 4)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-8, 8), 0, random(-3, 3)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" E 0 { A_FaceTarget(); }
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-7, 7), 0, random(-3, 3)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-6, 6), 0, random(-2, 2)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" E 0 { A_FaceTarget(); }
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-5, 5), 0, random(-2, 2)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-4, 4), 0, random(-1, 1)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" E 0 { A_FaceTarget(); }
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-3, 3), 0, random(-1, 1)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-2, 2)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" E 0 { A_FaceTarget(); }
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-1, 1)); }
		"CGCY" E 0 A_CheckSight("See");
		"CGCY" E 0 { A_FaceTarget(); }
	Missile.T03.Loop:
		"CGCY" FE 3 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, 0); }
		"CGCY" F 1 A_MonsterRefire(64, "See");
		Goto Missile.T03.Loop;
	Pain.T03:
		"CGCY" G 3;
		"CGCY" G 3 { A_Pain(); }
		"CGCY" G 1 A_Jump(128, "See.T03.Dodge");
		Goto See;
	Death.T03:
		"CGCY" H 5;
		"CGCY" I 5 { A_Scream(); }
		"CGCY" J 5 { A_NoBlocking(false); }
		"CGCY" KLMNO 5;
		"CGCY" P 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		"CGCY" P 5 { A_Burst("IceChunk"); }
		Stop;
	// Neither CHP nor CH gives cyan an XDeath -- it always shatters.
	XDeath.T03:
		Goto Death.T03;
	Raise.T03:
		"CGCY" ONMLKJIH 5;
		Goto See;

	// ================= T04 PURPLE (04_P) =================
	// Seeking micro-rockets, one grade per range band: hardest-seeking
	// point blank (Boomer1), dumb-fired at long range (Boomer3).
	Spawn.T04:
		"UCHA" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"UCHA" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T04:
		"UCHA" E 12 { A_FaceTarget(); }
	Missile.T04.Loop:
		TNT1 A 0 A_JumpIfCloser(650, "Missile.T04.M1");
		TNT1 A 0 A_JumpIfCloser(1300, "Missile.T04.M2");
		"UCHA" FE 5 Bright { A_SpawnProjectile("RS_Boomer3", 32, -2, random(-1, 1)); }
		"UCHA" FE 5 Bright { A_SpawnProjectile("RS_Boomer3", 32, -2, random(-1, 1)); }
		"UCHA" F 1 A_MonsterRefire(150, "See");
		Goto Missile.T04.Loop;
	Missile.T04.M2:
		"UCHA" FE 4 Bright { A_SpawnProjectile("RS_Boomer2", 32, -2, random(-1, 1)); }
		"UCHA" FE 5 Bright { A_SpawnProjectile("RS_Boomer2", 32, -2, random(-1, 1)); }
		"UCHA" F 1 A_MonsterRefire(150, "See");
		Goto Missile.T04.Loop;
	Missile.T04.M1:
		"UCHA" FE 4 Bright { A_SpawnProjectile("RS_Boomer1", 32, -2, random(-1, 1)); }
		"UCHA" FE 4 Bright { A_SpawnProjectile("RS_Boomer1", 32, -2, random(-1, 1)); }
		"UCHA" F 1 A_MonsterRefire(150, "See");
		Goto Missile.T04.Loop;
	Pain.T04:
		"UCHA" G 3;
		"UCHA" G 3 { A_Pain(); }
		Goto See;
	Death.T04:
		"UCHA" H 5;
		"UCHA" I 5 { A_Scream(); }
		"UCHA" J 5 { A_NoBlocking(); }
		"UCHA" KLM 5;
		"UCHA" N -1;
		Stop;
	XDeath.T04:
		"UCHA" O 5;
		"UCHA" P 5 { A_XScream(); }
		"UCHA" Q 5 { A_NoBlocking(); }
		"UCHA" RS 5;
		"UCHA" T -1;
		Stop;
	Raise.T04:
		"UCHA" N 5;
		"UCHA" MLKJIH 5;
		Goto See;

	// ================= T05 YELLOW (04_Y) =================
	// Plasma gunner, four range bands. Far out it fires PAIRS: a plain
	// sighting rail, then a rail that seeds seeking sparks along the
	// beam. Under 750 it switches to plasma spam, under 300 to a fan.
	Spawn.T05:
		"PZOW" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"PZOW" AABBCCDD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(88, "See.T05.Dodge");
		Loop;
	See.T05.Dodge:
		"PZOW" AABBCCDD 4 { A_FastChase(); }
		TNT1 A 0 A_Jump(94, "See");
		Loop;
	Missile.T05:
		"PZOW" E 10 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(300, "Missile.T05.Spam2");
		TNT1 A 0 A_JumpIfCloser(750, "Missile.T05.Spam");
		TNT1 A 0 A_JumpIfCloser(1250, "Missile.T05.M1");
		TNT1 A 0 A_JumpIfCloser(1900, "Missile.T05.M2");
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 5 Bright { A_CustomRailgun(random(1, 2), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0, "RS_CGRailBuff", 2, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 4 { A_FaceTarget(); }
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 5 Bright { A_CustomRailgun(random(1, 2), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0, "RS_CGRailBuff", 3, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 4 { A_FaceTarget(); }
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 5 Bright { A_CustomRailgun(random(1, 2), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0, "RS_CGRailBuff", 3, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 2;
		Goto See;
	Missile.T05.M2:
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 4 Bright { A_CustomRailgun(random(1, 3), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0, "RS_CGRailBuff", 1, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 3 { A_FaceTarget(); }
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 4 Bright { A_CustomRailgun(random(1, 3), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0, "RS_CGRailBuff", 2, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 3 { A_FaceTarget(); }
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 4 Bright { A_CustomRailgun(random(1, 3), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0, "RS_CGRailBuff", 2, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 2;
		Goto See;
	Missile.T05.M1:
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 4 Bright { A_CustomRailgun(random(1, 4), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 0, 0, "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 2 { A_FaceTarget(); }
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 4 Bright { A_CustomRailgun(random(1, 4), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 0, 0, "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 2 { A_FaceTarget(); }
		"PZOW" F 5 Bright { A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING); }
		"PZOW" F 4 Bright { A_CustomRailgun(random(1, 4), 0, "00 00 FF", "00 00 FF", RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 0, 0, "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9, "RS_CGRailBuff", 7, 10); }
		"PZOW" E 2;
		Goto See;
	Missile.T05.Spam:
		"PZOW" F 4 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1, 1)); }
		"PZOW" E 2 { A_FaceTarget(); }
		"PZOW" F 4 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1, 1)); }
		"PZOW" E 2 { A_FaceTarget(); }
		"PZOW" F 3 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-3, 3)); }
		"PZOW" E 2 { A_FaceTarget(); }
		"PZOW" F 3 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-2, 2)); }
		"PZOW" E 2 { A_FaceTarget(); }
		"PZOW" F 2 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1, 1)); }
		"PZOW" FF 1 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1, 1)); }
		"PZOW" FF 1 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1, 1)); }
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 A_Jump(82, "Missile.T05.Spam2");
		Goto See;
	Missile.T05.Spam2:
		"PZOW" E 5 { A_FaceTarget(); }
		"PZOW" F 1 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 3); }
		"PZOW" F 2 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, -3); }
		"PZOW" F 2 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, -6); }
		"PZOW" F 3 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, -3); }
		"PZOW" F 3 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 0); }
		"PZOW" F 2 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 3); }
		"PZOW" F 2 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 6); }
		"PZOW" F 1 { A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 0); }
		Goto See.T05.Dodge;
	Pain.T05:
		"PZOW" G 3;
		"PZOW" G 3 { A_Pain(); }
		"PZOW" G 1 A_Jump(128, "See.T05.Dodge");
		Goto See;
	Death.T05:
		"PZOW" H 5;
		"PZOW" I 5 { A_Scream(); }
		"PZOW" J 5 { A_NoBlocking(); }
		"PZOW" KLM 5;
		"PZOW" N -1;
		Stop;
	XDeath.T05:
		"PZOW" O 5;
		"PZOW" P 5 { A_XScream(); }
		"PZOW" Q 5 { A_NoBlocking(); }
		"PZOW" RSTUV 5;
		"PZOW" W -1;
		Stop;
	Raise.T05:
		"PZOW" MLKJIH 5;
		Goto See;

	// ================= T06 ABYSS (04_A) =================
	// The Abyss Captain. Fades to 10% alpha while stalking -- once per
	// approach -- and snaps back to solid the instant it fires or takes
	// a hit. Beyond 700 it drops splash charges ON you (A_VileTarget);
	// closer in it switches to ice rapid-fire.
	Spawn.T06:
		"MPOS" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"MPOS" AABBCCDD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(128, "See.T06.Hide");
		Loop;
	See.T06.Hide:
		TNT1 A 0 { if (rsHideUsed >= 1) return ResolveState("See"); return ResolveState(null); }
		"MPOS" A 1 { A_SetTranslucent(0.85); }
		"MPOS" A 1 { A_SetTranslucent(0.65); }
		"MPOS" A 1 { A_SetTranslucent(0.45); }
		"MPOS" A 1 { A_SetTranslucent(0.25); }
		"MPOS" A 1 { A_SetTranslucent(0.10); }
		"MPOS" A 1 { rsHideUsed++; }
		Goto See;
	Missile.T06:
		"MPOS" E 1 { A_SetTranslucent(1.00); }
		"MPOS" A 1 { rsHideUsed = 0; }
	Missile.T06.Loop:
		"MPOS" E 10 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(700, "Missile.T06.Rapids", true);
		"MPOS" F 4 Bright { A_VileTarget("RS_SplashAbyssCguy"); }
		"MPOS" E 2 { A_FaceTarget(); }
		"MPOS" F 4 Bright { A_VileTarget("RS_SplashAbyssCguy"); }
		"MPOS" E 2 { A_FaceTarget(); }
		TNT1 A 0 A_CheckSight("See");
		"MPOS" E 0 A_MonsterRefire(128, "See");
		Goto Missile.T06.Loop;
	Missile.T06.Rapids:
		"MPOS" F 3 Bright { A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1, 1)); }
		"MPOS" E 2 { A_FaceTarget(); }
		"MPOS" F 3 Bright { A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1, 1)); }
		"MPOS" E 2 { A_FaceTarget(); }
		TNT1 A 0 A_CheckSight("See");
		"MPOS" F 3 Bright { A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1, 1)); }
		"MPOS" E 2 { A_FaceTarget(); }
		"MPOS" F 3 Bright { A_SpawnProjectile("RS_AbyssZShotCH3", 31, 2, random(-1, 1)); }
		"MPOS" E 2 { A_FaceTarget(); }
		TNT1 A 0 A_CheckSight("See");
		"MPOS" E 0 A_MonsterRefire(128, "See");
		Goto Missile.T06.Loop;
	Pain.T06:
		"MPOS" H 3;
		"MPOS" E 1 { A_SetTranslucent(1.00); }
		"MPOS" A 1 { rsHideUsed = 0; }
		"MPOS" H 3 { A_Pain(); }
		"MPOS" H 1;
		Goto See;
	Death.T06:
		"MPOS" I 5;
		"MPOS" J 5 { A_Scream(); }
		"MPOS" K 5 { A_NoBlocking(); }
		"MPOS" L 5;
		"MPOS" M -1;
		Stop;
	XDeath.T06:
		"MPOS" N 5;
		"MPOS" O 5 { A_XScream(); }
		"MPOS" P 5 { A_NoBlocking(); }
		"MPOS" QRSTU 5;
		"MPOS" V -1;
		Stop;
	Raise.T06:
		"MPOS" MLKJ 5;
		Goto See;

	// ================= T07 FIREBLU (04_F) =================
	// Speed 18 -- the fastest non-boss chaingunner in the family.
	// Fourteen fireballs per loop; every third is thrown deliberately
	// wide, so you cannot simply strafe one plane.
	Spawn.T07:
		"CGUF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"CGUF" AABBCCDD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(88, "See.T07.Dodge");
		Loop;
	See.T07.Dodge:
		"CGUF" AABBCCDD 4 { A_FastChase(); }
		TNT1 A 0 A_Jump(88, "See");
		Loop;
	Missile.T07:
		"CGUF" E 10 { A_FaceTarget(); }
	Missile.T07.Loop:
		"CGUF" F 4 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-1, 1)); }
		"CGUF" F 1 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-15, 15)); }
		"CGUF" F 1 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-35, 35)); }
		"CGUF" E 2 { A_FaceTarget(); }
		"CGUF" F 4 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-1, 1)); }
		"CGUF" E 2 { A_FaceTarget(); }
		"CGUF" F 3 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-3, 3)); }
		"CGUF" F 1 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-15, 15)); }
		"CGUF" F 1 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-35, 35)); }
		"CGUF" E 2 { A_FaceTarget(); }
		"CGUF" F 3 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-2, 2)); }
		"CGUF" E 2 { A_FaceTarget(); }
		"CGUF" F 2 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-1, 1)); }
		"CGUF" F 1 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-15, 15)); }
		"CGUF" F 1 { A_SpawnProjectile("RS_FireBCGguy", 31, 4, random(-35, 35)); }
		"CGUF" E 2 A_MonsterRefire(128, "See");
		Goto Missile.T07.Loop;
	Pain.T07:
		"CGUF" G 3;
		"CGUF" G 3 { A_Pain(); }
		"CGUF" G 1 A_Jump(128, "See.T07.Dodge");
		Goto See;
	Death.T07:
		"CGUF" H 5;
		"CGUF" I 5 { A_Scream(); }
		"CGUF" J 5 { A_NoBlocking(); }
		"CGUF" KLM 5;
		"CGUF" N -1;
		Stop;
	XDeath.T07:
		"CGUF" O 5;
		"CGUF" P 5 { A_XScream(); }
		"CGUF" Q 5 { A_NoBlocking(); }
		"CGUF" RSTUV 5;
		"CGUF" W -1;
		Stop;
	Raise.T07:
		"CGUF" MLKJIH 5;
		Goto See;

	// ================= T08 BROWN (04_BR) =================
	// The Noise Maker. Speed 6 and +NOTARGET in CHP: it does not push,
	// it DIGS IN. Throws inflating sandbags for cover -- twice as many
	// if another chaingunner is within 300, i.e. it fortifies a squad --
	// then walks its aim in with a widening three-shot burst, or lobs
	// orbs past 1400.
	Spawn.T08:
		"CZV1" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"CZV1" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T08:
		"CZV1" U 5 { A_FaceTarget(); }
		TNT1 A 0 A_CheckProximity("Missile.T08.More", "RS_Chaingunner", 300, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT);
		"CZV1" UUU 10 { A_SpawnItemEx("RS_BrownSandBagCGuy", 32, random(-32, 32), 12, random(3, 9), 0, random(3, 9), random(-9, 9), SXF_NOCHECKPOSITION); }
	Missile.T08.Aim:
		"CZV1" U 5 { A_FaceTarget(); }
	Missile.T08.Loop:
		TNT1 A 0 A_JumpIfCloser(1400, "Missile.T08.M1");
		"CZV1" F 5 Bright { A_CustomBulletAttack(2, 2, 1, random(2, 9), "BulletPuff", 8000); }
		"CZV1" F 5 Bright { A_CustomBulletAttack(4, 4, 1, random(2, 9), "BulletPuff", 8000); }
		"CZV1" F 5 Bright { A_CustomBulletAttack(6, 6, 1, random(2, 9), "BulletPuff", 8000); }
		"CZV1" F 1 A_CheckSight("See");
		"CZV1" F 1 A_MonsterRefire(64, "See");
		Goto Missile.T08.Loop;
	Missile.T08.More:
		"CZV1" UUU 10 { A_SpawnItemEx("RS_BrownSandBagCGuy", 32, random(-64, 64), 12, random(3, 14), 0, random(4, 14), random(-18, 18), SXF_NOCHECKPOSITION); }
		"CZV1" UUU 10 { A_SpawnItemEx("RS_BrownSandBagCGuy", 64, random(-64, 64), 12, random(5, 14), 0, random(4, 14), random(-18, 18), SXF_NOCHECKPOSITION); }
		Goto Missile.T08.Aim;
	Missile.T08.M1:
		"CZV1" E 10 Bright;
	Missile.T08.M1Loop:
		"CZV1" E 5 { A_FaceTarget(); }
		"CZV1" FEFE 3 Bright { A_SpawnProjectile("RS_BrownOrbCguy", 32, -6, random(-5, 5), 0, random(-1, 5)); }
		"CZV1" F 1 A_CheckSight("See");
		"CZV1" F 1 A_MonsterRefire(64, "See");
		Goto Missile.T08.M1Loop;
	Pain.T08:
		"CZV1" G 3;
		"CZV1" G 4 { A_Pain(); }
		Goto See;
	Death.T08:
		"CZV1" H 5;
		"CZV1" I 5 { A_Scream(); }
		"CZV1" J 5 { A_NoBlocking(); }
		"CZV1" KLM 5;
		"CZV1" M -1;
		Stop;
	// CZV1 ships A-S then U (no T on disk) -- XDeath ends on S.
	XDeath.T08:
		"CZV1" NO 5;
		"CZV1" P 5 { A_XScream(); }
		"CZV1" Q 5 { A_NoBlocking(); }
		"CZV1" R 5;
		"CZV1" S -1;
		Stop;
	Raise.T08:
		"CZV1" MLKJIH 5;
		Goto See;

	// ================= T09 GRAY (04_GY) =================
	// Hops on every chase beat and REFUSES to fire while airborne --
	// A_CheckFloor gates the whole Missile block, so it lands, hops
	// again, and only then shoots. Ripping tracers at range, a lobbed
	// bomb with a randomised fuse inside 500. Dies throwing gore.
	Spawn.T09:
		"UCH2" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"UCH2" AABBCCDD 4 { A_Chase(); }
		TNT1 A 0 ThrustThingZ(0, 40, 0, 0);
		TNT1 A 0 A_Jump(64, "See.T09.Fast");
		"UCH2" AABBCCDD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "See.T09.Fast");
		Loop;
	See.T09.Fast:
		"UCH2" AABBCCDD 4 { A_FastChase(); }
		TNT1 A 0 ThrustThingZ(0, 40, 0, 0);
		TNT1 A 0 A_Jump(64, "See");
		"UCH2" AABBCCDD 4 { A_FastChase(); }
		TNT1 A 0 A_Jump(64, "See");
		Loop;
	Missile.T09:
		TNT1 A 0 A_CheckFloor("Missile.T09.Go");
		Goto See;
	Missile.T09.Go:
		TNT1 A 0 ThrustThingZ(0, 40, 0, 0);
		"UCH2" E 8 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(500, "Missile.T09.Rocket");
		"UCH2" FEFEF 3 Bright { A_SpawnProjectile("RS_GrayPewPew", 32, -2, frandom(-500, 500) / 1000); }
		"UCH2" E 3;
		Goto See;
	Missile.T09.Rocket:
		"UCH2" F 6 Bright { A_SpawnProjectile("RS_GrayKaboom", 28, -2); }
		"UCH2" E 6;
		Goto See;
	Pain.T09:
		"UCH2" G 3;
		"UCH2" G 3 { A_Pain(); }
		Goto See;
	Death.T09:
		"UCH2" H 0 ThrustThingZ(0, 40, 0, 0);
		"UCH2" H 5 { A_SpawnProjectile("RS_HKRedDeath", random(10, 70), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"UCH2" I 5 { A_Scream(); }
		"UCH2" J 5 { A_NoBlocking(); }
		"UCH2" KLM 5;
		"UCH2" N -1;
		Stop;
	XDeath.T09:
		"UCH2" O 0 ThrustThingZ(0, 40, 0, 0);
		"UCH2" O 5 { A_SpawnProjectile("RS_HKRedDeath", random(10, 70), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"UCH2" P 5 { A_XScream(); }
		"UCH2" Q 5 { A_NoBlocking(); }
		"UCH2" RS 5;
		"UCH2" T -1;
		Stop;
	Raise.T09:
		"UCH2" N 5;
		"UCH2" MLKJIH 5;
		Goto See;

	// ================= T10 RED (04_R) =================
	// Detonating rounds, three grades by range -- the closer you are,
	// the bigger the puff and the more of them per burst. Side-steps
	// left or right whenever it takes pain.
	Spawn.T10:
		"CPS2" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"CPS2" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.T10.Dodge1:
		"CPS2" A 5 ThrustThing(angle * 256 / 360 + 64, 20, 0, 0);
		Goto See;
	See.T10.Dodge2:
		"CPS2" A 5 ThrustThing(angle * 256 / 360 + 192, 20, 0, 0);
		Goto See;
	Missile.T10:
		"CPS2" E 11 { A_FaceTarget(); }
	Missile.T10.Loop:
		TNT1 A 0 A_JumpIfCloser(500, "Missile.T10.M1");
		TNT1 A 0 A_JumpIfCloser(1300, "Missile.T10.M2");
		"CPS2" FE 4 { A_CustomBulletAttack(random(3, 14), 0, random(1, 2), random(1, 2), "RS_DetoPuff3"); }
		"CPS2" F 1 A_MonsterRefire(64, "See");
		Goto Missile.T10.Loop;
	Missile.T10.M2:
		"CPS2" FE 4 { A_CustomBulletAttack(random(2, 11), 0, random(1, 2), random(1, 2), "RS_DetoPuff2"); }
		"CPS2" F 1 A_MonsterRefire(64, "See");
		Goto Missile.T10.Loop;
	Missile.T10.M1:
		"CPS2" FE 4 { A_CustomBulletAttack(random(1, 8), 0, random(1, 3), random(2, 4), "RS_DetoPuffCG"); }
		"CPS2" F 1 A_MonsterRefire(64, "See");
		Goto Missile.T10.Loop;
	Pain.T10:
		"CPS2" G 3;
		"CPS2" G 3 { A_Pain(); }
		"CPS2" G 1 A_Jump(128, "See.T10.Dodge1", "See.T10.Dodge2");
		Goto See;
	Death.T10:
		"CPS2" H 5;
		"CPS2" I 5 { A_Scream(); }
		"CPS2" J 5 { A_NoBlocking(); }
		"CPS2" KLMNO 5;
		"CPS2" P -1;
		Stop;
	XDeath.T10:
		"CPS2" Q 5;
		"CPS2" R 5 { A_XScream(); }
		"CPS2" S 5 { A_NoBlocking(); }
		"CPS2" TUVW 5;
		"CPS2" X -1;
		Stop;
	Raise.T10:
		"CPS2" P 5;
		"CPS2" ONMLKJIH 5;
		Goto See;

	// ================= T11 BLACK -- THE GENERAL (04_K) =================
	// Three patterns rolled evenly: a seeking plasma-bomb spam that can
	// re-roll into itself, a REFLECTIVE INVULNERABLE shield phase that
	// ends in a six-shot plasma burst, and a long BFG windup with two
	// telegraph flares. Pain has a coin flip to raise the shield.
	// CHP sets NOPAIN when the shield goes up and never clears it --
	// kept verbatim; that permanence IS the escalation.
	Spawn.T11:
		"BFGZ" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"BFGZ" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T11:
		TNT1 A 0 A_Jump(256, "Missile.T11.Spam", "Missile.T11.ShieldBlast", "Missile.T11.Big");
		Goto Missile.T11.Spam;
	Missile.T11.Spam:
		"BFGZ" E 14 { A_FaceTarget(); }
		"BFGZ" FEF 5 Bright { A_SpawnProjectile("RS_SpamShotsCguy", 26, 8, random(-7, 7)); }
		"BFGZ" E 0 A_CheckSight("See");
		"BFGZ" FEF 5 Bright { A_SpawnProjectile("RS_SpamShotsCguy", 26, 8, random(-15, 15)); }
		"BFGZ" E 0 A_CheckSight("See");
		"BFGZ" FEF 5 Bright { A_SpawnProjectile("RS_SpamShotsCguy", 26, 8, random(-20, 20)); }
		"BFGZ" E 8 A_CheckSight("See");
		TNT1 A 0 A_Jump(128, "Missile.T11.Spam");
		Goto See;
	Missile.T11.Shield:
		"BFGZ" E 8 { A_FaceTarget(); }
		"BFGZ" E 0 { bNOPAIN = true; }
		"BFGZ" E 0 { bREFLECTIVE = true; bINVULNERABLE = true; }
		"BFGZ" E 2 { A_SpawnProjectile("RS_GenShield", 20, 0, random(-7, 7)); }
		"BFGZ" E 45;
		"BFGZ" E 1;
	Missile.T11.ShieldFire:
		"BFGZ" E 1 { A_FaceTarget(); }
		"BFGZ" FEFEFE 3 Bright { A_SpawnProjectile("RS_TrailSPCguy", 32, 0, random(-7, 7)); }
		"BFGZ" E 1 { bREFLECTIVE = false; bINVULNERABLE = false; }
		"BFGZ" A 1 A_Jump(64, "Missile.T11.Spam", "Missile.T11.Big");
		Goto See;
	Missile.T11.ShieldBlast:
		"BFGZ" E 6;
		Goto Missile.T11.ShieldFire;
	Missile.T11.Big:
		"BFGZ" E 20 { A_FaceTarget(); }
		"BFGZ" E 15 Bright { A_FaceTarget(); }
		"BFGZ" F 5 Bright { A_SpawnProjectile("RS_RedRevLoad", 32, 8, 0); }
		"BFGZ" E 8 Bright { A_FaceTarget(); }
		"BFGZ" F 5 Bright { A_SpawnProjectile("RS_RedRevLoad", 32, 8, 0); }
		"BFGZ" E 8 Bright { A_FaceTarget(); }
		"BFGZ" F 8 Bright { A_SpawnProjectile("RS_CGBigOne", 32, 8, 0); }
		"BFGZ" E 2;
		Goto See;
	Pain.T11:
		"BFGZ" G 3;
		"BFGZ" G 3 { A_Pain(); }
		"BFGZ" G 3 A_Jump(128, "Missile.T11.Shield");
		Goto See;
	Death.T11:
		"BFGZ" HHH 8 { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), CMF_AIMOFFSET, 2, -10); }
		"BFGZ" I 5 { A_Scream(); }
		"BFGZ" J 5 { A_NoBlocking(); }
		"BFGZ" KLM 5;
		"BFGZ" N -1;
		Stop;
	XDeath.T11:
		"BFGZ" OOO 8 { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), CMF_AIMOFFSET, 2, -10); }
		"BFGZ" P 5 { A_XScream(); }
		"BFGZ" Q 5 { A_NoBlocking(); }
		"BFGZ" RS 5;
		"BFGZ" T -1;
		Stop;
	Raise.T11:
		"BFGZ" NMLKJIH 5;
		Goto See;

	// ================= T12 WHITE -- THE SCIENTIST (04_W) =================
	// Four opening patterns rolled evenly: poison puddles, a dart
	// barrage that sustains on A_MonsterRefire, and two live experiments
	// (an unstable cacodemon, a pack of slime worms). Below 4444 HP she
	// goes NOPAIN, speeds up to 19, drops two spliced baron-arachnotrons
	// and PERMANENTLY unlocks the harder pool -- Puddle2, DartStorm and
	// the third experiment. The phase change fires exactly once.
	Spawn.T12:
		"FSZS" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"FSZS" AABB 4 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "See.T12.Fast");
		"FSZS" CCDD 4 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "See.T12.Fast");
		Loop;
	See.T12.Fast:
		"FSZS" AABB 4 { A_FastChase(); }
		TNT1 A 0 A_Jump(64, "See");
		"FSZS" CCDD 4 { A_FastChase(); }
		TNT1 A 0 A_Jump(64, "See");
		Loop;
	Missile.T12:
		"FSZS" E 4 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfHealthLower(4444, "Missile.T12.Phase2");
		TNT1 A 0 A_Jump(256, "Missile.T12.Puddle", "Missile.T12.Summon1", "Missile.T12.Darts", "Missile.T12.Summon2");
		Goto See;
	Missile.T12.Puddle:
		"FSZS" E 8 { A_FaceTarget(); }
		"FSZS" F 9 Bright;
		"FSZS" FF 0 { A_SpawnProjectile("RS_Puddle1", 40, 0, random(-60, 60), 2, random(10, 30)); }
		Goto See;
	Missile.T12.Puddle2:
		"FSZS" E 8 { A_FaceTarget(); }
		"FSZS" F 9 Bright;
		"FSZS" FFFF 0 { A_SpawnProjectile("RS_Puddle1", 56, 0, random(-80, 80), 2, random(12, 35)); }
		Goto See;
	Missile.T12.Darts:
		"FSZS" E 1 { A_FaceTarget(); }
		"FSZS" F 6 Bright;
		"FSZS" F 1 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-5, 5)); }
		"FSZS" E 1 { A_FaceTarget(); }
		"FSZS" E 0 A_CheckSight("See");
		"FSZS" F 1 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15)); }
		"FSZS" E 1 { A_FaceTarget(); }
		"FSZS" E 0 A_CheckSight("See");
		"FSZS" F 1 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-25, 25)); }
		"FSZS" E 2 A_MonsterRefire(128, "See");
		Goto Missile.T12.Darts;
	Missile.T12.DartStorm:
		"FSZS" E 1 { A_FaceTarget(); }
		"FSZS" F 6 Bright;
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-35, 35)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-25, 25)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-35, 35)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15)); }
		"FSZS" F 1 Bright { A_SpawnProjectile("RS_NeedlesCg2", random(32, 42), 7, random(-5, 5)); }
		"FSZS" E 6 { A_FaceTarget(); }
		"FSZS" E 0 A_CheckSight("See");
		"FSZS" F 8 Bright { A_SpawnProjectile("RS_NeedlesCg2", random(32, 42), 7, random(-5, 5)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-15, 15)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-35, 35)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg1", random(32, 42), 7, random(-25, 25)); }
		"FSZS" E 6 { A_FaceTarget(); }
		"FSZS" E 0 A_CheckSight("See");
		"FSZS" F 8 Bright { A_SpawnProjectile("RS_NeedlesCg2", random(32, 42), 7, random(-5, 5)); }
		"FSZS" F 0 Bright { A_SpawnProjectile("RS_NeedlesCg2", random(32, 42), 7, random(-25, 25)); }
		"FSZS" E 6 { A_FaceTarget(); }
		"FSZS" E 2 A_Jump(128, "Missile.T12.DartStorm");
		"FSZS" E 2 A_Jump(64, "Missile.T12.Darts");
		Goto See;
	Missile.T12.Summon1:
		"FSZS" E 3 { A_FaceTarget(); }
		"FSZS" F 2;
		"FSZS" F 2 { A_SpawnItemEx("RS_VolativeCaco", 32, 0, 0, 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION); }
		"FSZS" FA 2;
		Goto See;
	Missile.T12.Summon2:
		"FSZS" E 3 { A_FaceTarget(); }
		"FSZS" F 2;
		"FSZS" FFF 3 { A_SpawnItemEx("RS_SlimyWorm", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION); }
		"FSZS" FA 2;
		Goto See;
	Missile.T12.Summon3:
		"FSZS" E 12 { A_FaceTarget(); }
		"FSZS" E 12;
		"FSZS" F 12;
		"FSZS" F 8 { A_SpawnItemEx("RS_SpliceBaron", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION); }
		"FSZS" F 12;
		"FSZS" A 8;
		Goto See;
	Missile.T12.Phase2:
		"FSZS" E 0 { bNOPAIN = true; }
		"FSZS" E 20 { if (rsPhase2Done >= 1) return ResolveState("Missile.T12.Nah"); return ResolveState(null); }
		"FSZS" G 8;
		"FSZS" G 7 { A_SetSpeed(19); }
		"FSZS" E 8 { rsPhase2Done++; }
		"FSZS" F 12;
		"FSZS" FF 0 { A_SpawnItemEx("RS_SpliceBaron", random(-64, 64), random(-64, 64), random(5, 15), 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION); }
		"FSZS" A 5;
		Goto See;
	Missile.T12.Nah:
		TNT1 A 0 A_Jump(256, "Missile.T12.Summon1", "Missile.T12.Puddle2", "Missile.T12.DartStorm", "Missile.T12.Summon2", "Missile.T12.Summon3");
		Goto See;
	Pain.T12:
		"FSZS" G 3;
		"FSZS" G 3 { A_Pain(); }
		Goto See;
	Death.T12:
		"FSZS" H 11;
		"FSZS" I 11 { A_Scream(); }
		"FSZS" J 11 { A_NoBlocking(); }
		"FSZS" KLM 11;
		"FSZS" N -1;
		Stop;
	XDeath.T12:
		"FSZS" O 5 { A_XScream(); }
		"FSZS" P 5 { A_NoBlocking(); }
		"FSZS" QRSTUV 5;
		"FSZS" W -1;
		Stop;
	Raise.T12:
		"FSZS" NMLKJIH 5;
		Goto See;

	// ================= TEX GREEN WARFACE (04_KX) =================
	// The EX tier: CHP's GreenBlackCGuyEX2, "LET ME SEE YOUR GREEN
	// WARFACE". 11249 HP on CH's black HCPO body with a green remap, and
	// unlike the rest of the family it is NOT a bullet skirmisher at all
	// -- every one of its four options is artillery:
	//
	//   YELLOWBOMB  the nine-stage escalating blast, gated under 1200
	//   BIGBOMB     two visible loads, then a SEEKING megabomb that
	//               detonates into a 386-radius field
	//   RAPIDFIRE   detonating rounds on a refire loop, gated under 2000,
	//               and each loop can roll into one of the heavies
	//   REDSPAM     two loads then twelve alternating plasma/fire rounds
	//
	// Three of the four end with A_Quake and clear NOPAIN on the firing
	// frame: it goes stagger-proof while winding up and drops that guard
	// exactly when it commits. Pain sets NOPAIN back on, so hitting it
	// mid-swing does not interrupt the shot -- only the recovery.
	//
	// PHASE 2 at 6250 HP (CHP's A_JumpIfHealthLower) turns MISSILEEVEN-
	// MORE and ALWAYSFAST on permanently. It does not heal, it does not
	// change bodies -- it just stops pausing.
	Spawn.TEX:
		"HCPO" AB 10 { A_Look(); }
		Loop;
	See.TEX:
		"HCPO" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.TEX.Fast:
		"HCPO" AABBCCDD 3 { A_FastChase(); }
		Goto See;
	Missile.TEX:
		"HCPO" A 0 A_JumpIfHealthLower(6250, "Missile.TEX.Phase2");
		"HCPO" A 0 A_Jump(255, "Missile.TEX.RedSpam", "Missile.TEX.YellowBomb", "Missile.TEX.BigBomb", "Missile.TEX.RapidFire");
		Goto See;
	// Not a transformation -- just the brakes coming off, for good.
	Missile.TEX.Phase2:
		"HCPO" A 0 { bMISSILEEVENMORE = true; bALWAYSFAST = true; }
		Goto Missile.TEX+1;
	// Range gates. Out of band, it re-rolls rather than firing blind.
	Missile.TEX.YellowBomb:
		"HCPO" A 0 A_JumpIfCloser(1200, "Missile.TEX.YellowBombFire");
		Goto Missile.TEX;
	Missile.TEX.YellowBombFire:
		"HCPO" E 1 { A_FaceTarget(); }
		"HCPO" AA 0 { A_SpawnProjectile("RS_SparkPuff1", 40, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HCPO" E 3 Bright { A_FaceTarget(); }
		"HCPO" EEEEEEE 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 40, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HCPO" E 2 Bright { A_FaceTarget(); }
		"HCPO" F 0 { A_Quake(2, 12, 0, 128); }
		"HCPO" A 0 { bNOPAIN = false; }
		"HCPO" F 3 Bright { A_SpawnProjectile("RS_YellowBombCGuyEX", 40, 0, 0); }
		"HCPO" E 9 Bright;
		Goto See;
	// Two loads, twenty tics apart, in full view. Then the seeker.
	Missile.TEX.BigBomb:
		"HCPO" E 1 { A_FaceTarget(); }
		"HCPO" F 0 Bright { A_SpawnProjectile("RS_RedRevLoad", 40, 0, 0); }
		"HCPO" E 20 Fast { A_FaceTarget(); }
		"HCPO" F 0 Bright { A_SpawnProjectile("RS_SpiralLoadGeneEX", 40, 0, 0); }
		"HCPO" E 20 Fast { A_FaceTarget(); }
		"HCPO" F 0 { A_Quake(2, 12, 0, 128); }
		"HCPO" A 0 { bNOPAIN = false; }
		"HCPO" F 3 Bright { A_SpawnProjectile("RS_CGBigEX", 40, 0, 0); }
		"HCPO" E 9 Bright;
		Goto See;
	Missile.TEX.RapidFire:
		"HCPO" A 0 A_JumpIfCloser(2000, "Missile.TEX.RapidFire2");
		Goto Missile.TEX;
	Missile.TEX.RapidFire2:
		"HCPO" E 20 Fast { A_FaceTarget(); }
	// The loop re-checks range every pass, so backing off past 2000
	// genuinely breaks it out instead of eating the whole magazine.
	Missile.TEX.RapidCheck:
		"HCPO" A 0 A_JumpIfCloser(2000, "Missile.TEX.RapidLoop");
		Goto Missile.TEX;
	Missile.TEX.RapidLoop:
		"HCPO" A 0 { A_StartSound("prox/beep", CHAN_WEAPON); }
		"HCPO" E 3 Fast { A_FaceTarget(); }
		"HCPO" F 0 { A_Quake(2, 12, 0, 128); }
		"HCPO" A 0 { bNOPAIN = false; }
		"HCPO" FE 3 Fast Bright { A_CustomBulletAttack(6, 5, random(1, 3), random(1, 4), "RS_DetoPuffCG"); }
		"HCPO" E 2 A_MonsterRefire(188, "See");
		"HCPO" A 0 A_Jump(25, "Missile.TEX.RedSpam", "Missile.TEX.YellowBomb", "Missile.TEX.BigBomb");
		Goto Missile.TEX.RapidCheck;
	// Twelve rounds alternating plasma and fire on a widening spread --
	// the resistance you brought only covers half of it.
	Missile.TEX.RedSpam:
		"HCPO" E 1 { A_FaceTarget(); }
		"HCPO" F 0 Bright { A_SpawnProjectile("RS_SpiralLoadGeneEX", 40, 0, 0); }
		"HCPO" E 15 Fast { A_FaceTarget(); }
		"HCPO" F 0 Bright { A_SpawnProjectile("RS_SpiralLoadGeneEX", 40, 0, 0); }
		"HCPO" E 15 Fast { A_FaceTarget(); }
		"HCPO" F 0 { A_Quake(2, 12, 0, 128); }
		"HCPO" A 0 { bNOPAIN = false; }
		"HCPO" FEFE 3 Bright { A_SpawnProjectile("RS_SpamShotsCGuyEX", 40, 0, random(-5, 5), 0, random(-4, 4)); }
		"HCPO" E 1 { A_FaceTarget(); }
		"HCPO" FEFE 3 Bright { A_SpawnProjectile("RS_SpamShotsCGuyEX2", 40, 0, random(-9, 9), 0, random(-4, 4)); }
		"HCPO" E 1 { A_FaceTarget(); }
		"HCPO" FE 3 Bright { A_SpawnProjectile("RS_SpamShotsCGuyEX", 40, 0, random(-11, 11), 0, random(-4, 4)); }
		"HCPO" E 1 { A_FaceTarget(); }
		"HCPO" FE 3 Bright { A_SpawnProjectile("RS_SpamShotsCGuyEX2", 40, 0, random(-13, 13), 0, random(-4, 4)); }
		Goto See;
	// Pain re-arms the stagger guard and half the time it breaks into a
	// sprint, so punishing it is a one-shot window, not a stunlock.
	Pain.TEX:
		"HCPO" G 3;
		"HCPO" G 3 { A_Pain(); }
		"HCPO" A 0 { bNOPAIN = true; }
		"HCPO" G 3 A_Jump(128, "See.TEX.Fast");
		Goto See;
	Death.TEX:
		"HCPO" HHHHHHH 5 { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), CMF_AIMOFFSET, 2, -10); }
		"HCPO" I 5 { A_Scream(); }
		"HCPO" J 5 { A_NoBlocking(); }
		"HCPO" KL 5;
		"HCPO" L -1;
		Stop;
	// THE T00 FALLBACK WAS FIRING FOR TIER 13.
	//
	// TierState falls back to "<prefix>.T00" when a tier has no cluster.
	// TEX defined no XDeath and no Raise, so a gibbed or resurrected
	// green EX general -- 11249 HP, HCPO body -- resolved through
	// XDeath.T00 / Raise.T00 and played VANILLA CPOS CAPTAIN FRAMES.
	// That is precisely the wrong-creature bug this rebuild exists to
	// kill, surviving in the one tier nothing checked: RS_AuditClusters
	// loops t = 1..12 and structurally cannot see tier 13.
	//
	// CHP and CH both genuinely give the EX no XDeath and no Raise, so
	// the fix is NOT to invent one from CHP -- it is the same call
	// already made for T03/T11/T12: route them to bodies that are at
	// least the right creature. Death.Ice likewise: every CHP actor in
	// this family aliases it onto its own Death, and ours had none, so
	// an ice-shattered TEX fell to T00 as well.
	XDeath.TEX:
	Death.Ice.TEX:
		Goto Death.TEX;
	Raise.TEX:
		"HCPO" LKJ 5;
		"HCPO" IH 5;
		Goto See;
	}
}
