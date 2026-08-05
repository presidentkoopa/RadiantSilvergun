// =====================================================================
// RS_Imp -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\03\03_<code>.txt
// One CHP file per colour; each is a genuinely different creature with
// its OWN sprite set, stats and attack. Nothing inferred, nothing
// tinted, nothing shared unless CHP shares it.
//
//   tier  CHP    body   HP    what it actually is
//   T00   03_C   TROO     60  vanilla imp: combo claw/fireball
//   T01   03_G   IMPG     75  green: seeking plasma ball
//   T02   03_B   IMPB     92  blue: fast straight fireball
//   T03   03_CY  CIMP     89  cyan: 11-shot frost fan close, ball
//                             burst far, bounce-dodges on pain
//   T04   03_P   TRO3    125  purple: twin bouncing fireballs
//   T05   03_Y   TRO4    165  yellow: spitfire, dodge-weaves, and a
//                             360-degree flare burst when hurt
//   T06   03_A   IMPA    320  abyss: twin abyss balls, splash trail,
//                             NOPAIN charge-dash up close
//   T07   03_F   IMPF    145  fireblu: alternating red/blue bombs
//                             plus a close-range shotgun burst
//   T08   03_BR  WARI    150  BROWN WARLORD: spike volley, parry that
//                             yanks you in, drops mace and shield
//   T09   03_GY  GIMP    150  gray: two 5-nail rings; corpse bursts
//                             into a full nail ring
//   T10   03_R   PRIM    215  red: 5-ball burst, permanently enrages
//                             on pain (NOPAIN + MISSILEEVENMORE)
//   T11   03_K   AGUR   3800  BLACK AGAURES: three attack modes and
//                             ally-healing death breath
//   T12   03_W   HELN   6666  WHITE apex: colour-ball storm, megaball
//                             spark barrage, or a summon
//   TEX   03_KX  AGUR  10750  GREEN SMOKING IMP EX: the EX tier. Five
//                             modes -- a charged RAILGUN kamehameha, a
//                             homing smoke-cloud hunter, a 30-shot
//                             tightening fan, a charged megaball, and a
//                             40-round rain -- and it WARPS out of pain
//
// TEX re-wears T11's AGUR body: CHP ships no separate EX imp sprite set
// and distinguishes the EX with a green palette remap, so TEX is the one
// tier in this family carrying a TintTable entry (rs_imp_tex). CHP's
// XScale 1.15 is a Default-only property with no per-tier setter in this
// template and is not reproduced -- the same simplification T11 already
// ships for CH's yScale 1.4 / XScale 1.05.
// =====================================================================

class RS_Imp : RS_MonsterMaster replaces DoomImp
{
	private int rsEnraged;

	Default
	{
		Health 60;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "imp/sight";   PainSound "imp/pain";
		DeathSound "imp/death"; ActiveSound "imp/active";
		HitObituary "$OB_IMPHIT";
		Obituary "$OB_IMP";
		Tag "Imp";
	}

	// CHP's real per-colour numbers, read from 03_*.txt.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 200; r.dmgMul = 1.0;
		int hp = 60; int spd = 8;
		switch (t)
		{
			case 0:  hp = 60;   spd = 8;  r.painChance = 200; r.dmgMul = 1.0; break;
			case 1:  hp = 75;   spd = 8;  r.painChance = 180; r.dmgMul = 1.1; break;
			case 2:  hp = 92;   spd = 9;  r.painChance = 170; r.dmgMul = 1.2; break;
			case 3:  hp = 89;   spd = 14; r.painChance = 84;  r.dmgMul = 1.3; break;
			case 4:  hp = 125;  spd = 10; r.painChance = 150; r.dmgMul = 1.4; break;
			case 5:  hp = 165;  spd = 10; r.painChance = 120; r.dmgMul = 1.5; break;
			case 6:  hp = 320;  spd = 11; r.painChance = 120; r.dmgMul = 1.6; break;
			case 7:  hp = 145;  spd = 9;  r.painChance = 150; r.dmgMul = 1.5; break;
			case 8:  hp = 150;  spd = 9;  r.painChance = 128; r.dmgMul = 1.5; break;
			case 9:  hp = 150;  spd = 8;  r.painChance = 100; r.dmgMul = 1.6; break;
			case 10: hp = 215;  spd = 10; r.painChance = 100; r.dmgMul = 1.8; break;
			case 11: hp = 3800; spd = 12; r.painChance = 28;  r.dmgMul = 2.5; break;
			case 12: hp = 6666; spd = 18; r.painChance = 24;  r.dmgMul = 3.0; break;
			// TEX -- CHP 03_KX GreenBlackImpEX2, verbatim.
			case 13: hp = 10750; spd = 18; r.painChance = 22; r.dmgMul = 3.5; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 60.0;
		r.spdMul = double(spd) / 8.0;

		// =============================================================
		// THE CH PARENT PROPERTIES.  CH/decorate/Imps.txt.
		// See docs/rs_24_ch_parent_properties.txt. Parent name and line
		// on every case.
		//
		// THIS FAMILY IS THE UNIFORM ONE. Species is "Imp" on all
		// fourteen tiers -- no splits, no blanks. Imps never infight
		// each other, at any tier, and that is deliberate: it is the
		// horde family. Do not read the absence of variation here as a
		// gap; families 02 and 04 vary because THEY are soldiers.
		//
		// +AVOIDMELEE APPEARS ON NO IMP TIER AT ALL. Grepped the whole
		// of Imps.txt: zero hits. Every imp closes.
		//
		// +MISSILEMORE on twelve of fourteen -- everything except T00
		// and T01. This is the most aggressive low-tier ladder in the
		// bestiary, and unlike the gunner families there is no cautious
		// counterweight anywhere in it.
		//
		// GibHealth is stated on NO CH imp parent. Every GibHealth this
		// family has is CHP-side, so it is absent from this table by
		// design, not oversight.
		// =============================================================
		r.mass = 100; r.scale = 1.0;
		switch (t)
		{
			case 0:   // CommonImp : Doomimp          Imps.txt:987
				// Inherits its whole body from Doomimp -- CH states no
				// radius, height or mass. Left unstated here too; see
				// rs_24's rule 2.
				r.species = "Imp";
				r.flags = RS_TF_DONTHARMSPECIES;
				r.mass = 0;
				break;
			case 1:   // GreenImp : Doomimp          Imps.txt:1072
				// No MISSILEMORE. With T00, the only two that lack it.
				r.species = "Imp"; r.bloodColor = "Green";
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_DONTHARMSPECIES;
				break;
			case 2:   // BlueImp : Doomimp           Imps.txt:1207
				r.species = "Imp"; r.bloodColor = "blue";
				r.radius = 20; r.height = 56;
				r.flags = RS_TF_DONTHARMSPECIES;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 3:   // CyanImp2 (no parent)         Imps.txt:297
				// Mass 500 and the only imp with a RenderStyle.
				r.species = "Imp"; r.bloodColor = "Blue";
				r.radius = 20; r.height = 56; r.mass = 500;
				r.alpha = 0.99; r.renderStyle = STYLE_Add;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_QUICKTORETALIATE
				        | RS_TF_NOICEDEATH | RS_TF_NOFEAR
				        | RS_TF_LAXTELEFRAGDMG;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 4:   // PurpleImp : Doomimp         Imps.txt:1363
				r.species = "Imp"; r.bloodColor = "Purple";
				r.radius = 20; r.height = 56; r.mass = 130;
				r.meleeRange = 64;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_QUICKTORETALIATE
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 5:   // YellowImp : Doomimp         Imps.txt:1535
				r.species = "Imp"; r.bloodColor = "Yellow";
				r.radius = 20; r.height = 56; r.mass = 130;
				r.meleeRange = 68;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_QUICKTORETALIATE
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 6:   // AbyssImp2 (no parent)        Imps.txt:514
				// +CANTSEEK is unique to this tier in the family --
				// seeker missiles cannot lock onto it.
				r.species = "Imp"; r.bloodColor = "Black";
				r.radius = 20; r.height = 56; r.mass = 130;
				r.meleeRange = 68;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_QUICKTORETALIATE
				        | RS_TF_NOFEAR | RS_TF_CANTSEEK;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 7:   // FireBluImp2 : Doomimp        Imps.txt:726
				r.species = "Imp"; r.bloodColor = "Purple";
				r.radius = 20; r.height = 56; r.mass = 130;
				r.meleeRange = 64;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_QUICKTORETALIATE
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 8:   // BrownImp2 (no parent)         Imps.txt:40
				r.species = "Imp"; r.bloodColor = "red";
				r.radius = 20; r.height = 56; r.mass = 130;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 9:   // GrayImp2 (no parent)         Imps.txt:854
				r.species = "Imp"; r.bloodColor = "White";
				r.radius = 20; r.height = 56; r.mass = 130;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 10:  // RedImp : DoomImp            Imps.txt:1688
				r.species = "Imp";
				r.radius = 20; r.height = 56; r.mass = 130;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_QUICKTORETALIATE
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;                    // +MISSILEMORE
				break;
			case 11:  // BlackImp1 (no parent)       Imps.txt:2300
				// BOTH missile flags, and CHP does NOT strip them here.
				r.species = "Imp";
				r.radius = 20; r.height = 56; r.mass = 500; r.scale = 1.2;
				r.radiusDamageFactor = 0.45;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_BOSS
				        | RS_TF_TAKESRADIUSDMG | RS_TF_DONTMORPH
				        | RS_TF_QUICKTORETALIATE | RS_TF_NOTARGET
				        | RS_TF_NOFEAR;
				r.missileChance = 0.0625;   // MORE *and* EVENMORE
				break;
			case 12:  // WhiteImp2 (no parent)       Imps.txt:2776
				// CHP quadruples CH's Mass 120 to 500 (03_W.txt:7) and
				// bumps Scale 1.25 -> 1.33. CHP wins on both.
				r.species = "Imp";
				r.radius = 20; r.height = 56; r.mass = 500; r.scale = 1.33;
				r.radiusDamageFactor = 0.33;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_DONTHARMCLASS
				        | RS_TF_BOSS | RS_TF_TAKESRADIUSDMG
				        | RS_TF_DONTMORPH | RS_TF_QUICKTORETALIATE
				        | RS_TF_NOTARGET;
				r.missileChance = 0.0625;   // MORE *and* EVENMORE
				break;
			case 13:  // BlackImpEX (no parent)      Imps.txt:2085
				// CH gives it +Missileevenmore at Imps.txt:2112 and CHP
				// STRIPS IT BACK OFF at 03_KX.txt:8. The shipping EX has
				// MISSILEMORE only. This is the whole reason the row is
				// an absolute statement rather than a union -- read CH
				// alone and this tier is four times as trigger-happy as
				// it ships.
				r.species = "Imp";
				r.radius = 20; r.height = 56; r.mass = 5000; r.scale = 1.15;
				r.radiusDamageFactor = 0.33;
				r.flags = RS_TF_DONTHARMSPECIES | RS_TF_BOSS
				        | RS_TF_TAKESRADIUSDMG | RS_TF_DONTMORPH
				        | RS_TF_QUICKTORETALIATE | RS_TF_NOTARGET
				        | RS_TF_NOFEAR;
				r.missileChance = 0.5;      // MORE only -- CHP stripped
				break;
			default:
				break;
		}
		return true;
	}

	// CH's per-tier DamageFactors, CH/decorate/Imps.txt.
	//
	// "Extinguishing" is the anti-imp type on T00-T10; the three bosses
	// swap it for "Heroic". Both at 3.0 -- the same tell family 01 and
	// 02 use.
	override double TierDamageFactor(int t, Name damageType)
	{
		if (damageType == 'DIMp')
			return 0.0;
		if (damageType == 'Extinguishing')
			return (t >= 11) ? 1.0 : 3.0;
		if (damageType == 'Heroic')
			return (t >= 11) ? 3.0 : 1.0;

		switch (t)
		{
			case 3:   // CyanImp2 -- the frost imp
				if (damageType == 'Melee')   return 1.5;
				if (damageType == 'Fire')    return 1.5;
				if (damageType == 'Ice')     return 0.15;
				if (damageType == 'PLWater') return 0.25;
				if (damageType == 'Falling') return 0.0;
				break;
			case 5:   // YellowImp
				if (damageType == 'PLWater') return 1.5;
				if (damageType == 'Fire')    return 0.75;
				if (damageType == 'Ice')     return 0.85;
				break;
			case 7:   // FireBluImp2 -- it IS the fire one
				if (damageType == 'Fire')    return 0.5;
				break;
			case 8:   // BrownImp2
				if (damageType == 'Melee')   return 0.5;
				break;
			case 9:   // GrayImp2
				if (damageType == 'Melee')   return 2.0;
				break;
			case 10:  // RedImp
				if (damageType == 'Melee')   return 2.0;
				if (damageType == 'Ice')     return 1.45;
				break;
			case 11:  // BlackImp1
				if (damageType == 'Melee')   return 1.75;
				if (damageType == 'Plasma')  return 1.1;
				break;
			case 12:  // WhiteImp2 -- 3.3x melee, the family's glass jaw
				if (damageType == 'Melee')   return 3.3;
				if (damageType == 'Plasma')  return 1.1;
				break;
			case 13:  // BlackImpEX
				if (damageType == 'Melee')      return 1.5;
				if (damageType == 'Plasma')     return 1.1;
				if (damageType == 'PlayerVoid') return 0.6;
				break;
			default:
				break;
		}
		return 1.0;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		return "TROO IMPG IMPB CIMP TRO3 TRO4 IMPA IMPF WARI GIMP PRIM AGUR HELN AGUR";
	}

	// CHP ships real artwork per colour -- a palette remap on top would
	// corrupt it. TEX is the exception: it re-wears T11's AGUR body
	// (CHP ships no separate EX imp sprite set) and is distinguished by a
	// green remap instead, so it is the one tier here with a real entry.
	// Recipe lives in TRNSLATE.txt as rs_imp_tex.
	override string TintTable()
	{
		//      T00 T01 T02 T03 T04 T05 T06 T07 T08 T09 T10 T11 T12 TEX
		return "- - - - - - - - - - - - - rs_imp_tex";
	}

	override string GetBaseKeywords()
	{
		return "species:imp role:fodder delivery:melee delivery:heavy element:thermal mobility:ground";
	}

	// Per-tier voice: red wears the Doom 64 imp, black wears Agaures.
	override void OnTierApplied(int t)
	{
		if (t == 10)
		{
			SeeSound = "imp2/see";      PainSound = "imp2/hurt";
			DeathSound = "imp2/die";    ActiveSound = "imp2/active";
		}
		else if (t == 11 || t == 13)
		{
			// T11 black Agaures and TEX green Agaures share the voice.
			SeeSound = "agaures/sight"; PainSound = "agaures/pain";
			DeathSound = "agaures/death"; ActiveSound = "agaures/active";
		}
		else
		{
			SeeSound = "imp/sight";     PainSound = "imp/pain";
			DeathSound = "imp/death";   ActiveSound = "imp/active";
		}
	}

	States
	{
	// ================= T00 COMMON (03_C) =================
	Spawn.T00:
		"TROO" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"TROO" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T00:
		"TROO" EF 8 { A_FaceTarget(); }
		"TROO" G 6 { A_CustomComboAttack("RS_DoomImpBall", 32, 3 * random(1, 8), "imp/melee"); }
		Goto See;
	Pain.T00:
		"TROO" H 2;
		"TROO" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
		"TROO" I 8;
		"TROO" J 8 { A_Scream(); }
		"TROO" K 6;
		"TROO" L 6 { A_NoBlocking(); }
		"TROO" M -1;
		Stop;
	XDeath.T00:
		"TROO" O 5 { A_XScream(); }
		"TROO" P 5;
		"TROO" Q 5 { A_NoBlocking(); }
		"TROO" RSTU 5;
		"TROO" U -1;
		Stop;
	Raise.T00:
		"TROO" MLKJI 8;
		Goto See;

	// ================= T01 GREEN (03_G) =================
	Spawn.T01:
		"IMPG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"IMPG" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T01:
		"IMPG" EF 8;
		"IMPG" G 6 { A_CustomMeleeAttack(random(6, 16), "imp/melee"); }
		Goto See;
	Missile.T01:
		"IMPG" EF 8 { A_FaceTarget(); }
		"IMPG" G 6 { A_SpawnProjectile("RS_GreenIBall", 42, 3); }
		Goto See;
	Pain.T01:
		"IMPG" H 2;
		"IMPG" H 2 { A_Pain(); }
		Goto See;
	Death.T01:
		"IMPG" I 8;
		"IMPG" J 8 { A_Scream(); }
		"IMPG" K 6;
		"IMPG" L 6 { A_NoBlocking(); }
		"IMPG" M -1;
		Stop;
	XDeath.T01:
		"IMPG" N 5;
		"IMPG" O 5 { A_XScream(); }
		"IMPG" P 5;
		"IMPG" Q 5 { A_NoBlocking(); }
		"IMPG" RST 5;
		"IMPG" U -1;
		Stop;
	Raise.T01:
		"IMPG" MLKJI 8;
		Goto See;

	// ================= T02 BLUE (03_B) =================
	Spawn.T02:
		"IMPB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"IMPB" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T02:
		"IMPB" EF 8;
		"IMPB" G 6 { A_CustomMeleeAttack(random(7, 19), "imp/melee"); }
		Goto See;
	Missile.T02:
		"IMPB" EF 8 { A_FaceTarget(); }
		"IMPB" G 6 { A_SpawnProjectile("RS_BluFier1", 42, 3, random(-1, 1)); }
		Goto See;
	Pain.T02:
		"IMPB" H 2;
		"IMPB" H 2 { A_Pain(); }
		Goto See;
	Death.T02:
		"IMPB" I 8;
		"IMPB" J 8 { A_Scream(); }
		"IMPB" K 6;
		"IMPB" L 6 { A_NoBlocking(); }
		"IMPB" M -1;
		Stop;
	XDeath.T02:
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_Blutrail1", 0, 0, 32, vel.x, vel.y, vel.z, random(-180, 180), SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION); }
		"IMPB" N 5;
		"IMPB" O 5 { A_XScream(); }
		"IMPB" P 5;
		"IMPB" Q 5 { A_NoBlocking(); }
		"IMPB" RST 5;
		"IMPB" U -1;
		Stop;
	Raise.T02:
		"IMPB" MLKJI 8;
		Goto See;

	// ================= T03 CYAN (03_CY) =================
	// Fast frost imp. Frost fan up close, ball burst at range, and it
	// bounce-dodges away when hurt. Shatters on death.
	Spawn.T03:
		"CIMP" AB 10 { A_Look(); }
		Loop;
	See.T03:
		TNT1 A 0 { A_SetScale(1.0, 1.0); }
		"CIMP" AABBCCDD 3 { A_Chase(); }
		TNT1 A 0 A_Jump(232, "See.T03.Check");
		Loop;
	See.T03.Check:
		"CIMP" E 0 A_JumpIfInTargetLOS("Missile.T03.Jumpy", 0, JLOSF_DEADNOJUMP, 650);
		Goto See;
	Melee.T03:
		"CIMP" EF 5 { A_FaceTarget(); }
		"CIMP" G 5 { A_CustomMeleeAttack(random(10, 30), "imp/melee", "", "Ice"); }
		Goto See;
	Missile.T03:
		TNT1 A 0 A_JumpIfCloser(600, "Missile.T03.Weave");
		Goto Missile.T03.Balls;
	Missile.T03.Balls:
		"CIMP" EF 3 { A_FaceTarget(); }
		"CIMP" G 3;
		"CIMP" G 0 { A_SpawnProjectile("RS_CyanImpBall", 32, 12, 0); }
		"CIMP" E 4 { A_SetScale(-1.0, 1.0); }
		"CIMP" EF 3 { A_FaceTarget(); }
		"CIMP" G 2 A_Jump(128, "Missile.T03.Spin");
		"CIMP" G 0 { A_SpawnProjectile("RS_CyanImpBall", 32, 12, random(1, 15)); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); }
		Goto See;
	Missile.T03.Spin:
		"CIMP" G 0 { A_SpawnProjectile("RS_CyanImpBall", 32, 12, random(-15, -1)); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); }
		Goto See;
	Missile.T03.Weave:
		TNT1 A 0 A_Jump(102, "Missile.T03.Balls");
		"CIMP" E 6 { A_FaceTarget(); }
		"CIMP" F 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -10); }
		"CIMP" F 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -8); }
		"CIMP" F 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -6); }
		"CIMP" F 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -4); }
		"CIMP" F 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, -2); }
		"CIMP" G 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 0); }
		"CIMP" G 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 2); }
		"CIMP" G 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 4); }
		"CIMP" G 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 6); }
		"CIMP" G 2 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 8); }
		"CIMP" G 3 { A_SpawnProjectile("RS_FrostLong2", 32, 12, 10); }
		"CIMP" FE 4 { A_FaceTarget(); }
		Goto See;
	Missile.T03.Jumpy:
		"CIMP" AA 2 { A_FastChase(); }
		"CIMP" A 1 { ThrustThingZ(0, 42, 0, 0); }
		"CIMP" B 1 { ThrustThing(angle * 256 / 360 - randompick(160, 180, 200), 12, 0, 0); }
		"CIMP" AB 5;
		"CIMP" A 1 { ThrustThingZ(0, 24, 0, 0); }
		"CIMP" B 1 { ThrustThing(angle * 256 / 360, 12, 0, 0); }
		Goto See;
	Pain.T03:
		"CIMP" H 3 { A_Pain(); }
		"CIMP" H 5 A_Jump(128, "Missile.T03.Jumpy");
		Goto See;
	Death.T03:
		"CIMP" I 5 { A_NoBlocking(); }
		"CIMP" J 5 { A_Scream(); }
		"CIMP" KL 5;
		"CIMP" M 5 { A_StartSound("misc/icebreak", CHAN_BODY); A_IceGuyDie(); }
		Stop;
	XDeath.T03:
		"CIMP" N 3 { A_NoBlocking(); }
		"CIMP" O 3 { A_XScream(); }
		"CIMP" PQRST 3;
		"CIMP" U 3 { A_StartSound("misc/icebreak", CHAN_BODY); A_IceGuyDie(); }
		Stop;

	// ================= T04 PURPLE (03_P) =================
	Spawn.T04:
		"TRO3" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"TRO3" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T04:
		"TRO3" EF 8;
		"TRO3" G 6 { A_CustomMeleeAttack(random(10, 29), "imp/melee"); }
		Goto See;
	Missile.T04:
		"TRO3" EF 8 { A_FaceTarget(); }
		"TRO3" G 7 { A_SpawnProjectile("RS_Bounc11", 42, 3, random(-1, 1)); }
		"TRO3" G 0 A_CheckSight("See");
		"TRO3" EF 8 { A_FaceTarget(); }
		"TRO3" G 7 { A_SpawnProjectile("RS_Bounc11", 42, 3, random(-9, 9)); }
		TNT1 A 0 A_Jump(96, "Missile.T04.Spread");
		Goto See;
	Missile.T04.Spread:
		"TRO3" EF 6 Bright;
		"TRO3" G 6 Bright { A_FaceTarget(); }
		"TRO3" GG 2 Bright { A_SpawnProjectile("RS_Bounc11", 42, 3, random(-13, 13)); }
		Goto See;
	Pain.T04:
		"TRO3" H 2;
		"TRO3" H 2 { A_Pain(); }
		Goto See;
	Death.T04:
		"TRO3" I 8;
		"TRO3" J 8 { A_Scream(); }
		"TRO3" K 6;
		"TRO3" L 6 { A_NoBlocking(); }
		"TRO3" M -1;
		Stop;
	Raise.T04:
		"TRO3" MLKJI 8;
		Goto See;

	// ================= T05 YELLOW (03_Y) =================
	// Weaves between chase and fast-chase; a flare burst on pain.
	Spawn.T05:
		"TRO4" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"TRO4" AABBCCDD 3 { A_Chase(); }
		TNT1 A 0 A_Jump(34, "See.T05.Dodge");
		Loop;
	See.T05.Dodge:
		"TRO4" AABBCCDD 3 { A_FastChase(); }
		TNT1 A 0 A_Jump(64, "See");
		Loop;
	Melee.T05:
		"TRO4" EF 8;
		"TRO4" G 6 { A_CustomMeleeAttack(random(10, 32), "imp/melee"); }
		Goto See;
	Missile.T05:
		"TRO4" EF 8 { A_FaceTarget(); }
		"TRO4" G 6 { A_SpawnProjectile("RS_SpitFireImp", 42, 3, random(-1, 1)); }
		Goto See;
	Pain.T05:
		"TRO4" H 1;
		"TRO4" H 2 { A_Pain(); }
		"TRO4" H 1 A_Jump(64, "Pain.T05.Firey");
		Goto See;
	Pain.T05.Firey:
		"TRO4" E 5 Bright;
		"TRO4" H 5 { A_SpawnProjectile("RS_Firespe1", 42, 0, random(-360, 360)); }
		"TRO4" H 1;
		Goto See.T05.Dodge;
	Death.T05:
		"TRO4" I 8;
		"TRO4" J 8 { A_Scream(); }
		"TRO4" K 6;
		"TRO4" L 6 { A_NoBlocking(); }
		"TRO4" M -1;
		Stop;
	Raise.T05:
		"TRO4" MLKJI 8;
		Goto See;

	// ================= T06 ABYSS (03_A) =================
	// Trails abyss splash as it walks; goes NOPAIN and charge-dashes
	// when you get close.
	Spawn.T06:
		"IMPA" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"IMPA" AABB 2 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"IMPA" CCDD 2 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		Loop;
	Melee.T06:
		"IMPA" EF 6;
		"IMPA" G 5 { A_CustomMeleeAttack(random(16, 42), "imp/melee"); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		Goto See;
	Missile.T06:
		TNT1 A 0 { bNOPAIN = false; }
		TNT1 A 0 A_JumpIfCloser(700, "Missile.T06.Dash");
		"IMPA" EF 8 { A_FaceTarget(); }
		"IMPA" G 6 { A_SpawnProjectile("RS_AbyssBallCH", 32, 3, random(-1, 1)); }
		"IMPA" EF 4 { A_FaceTarget(); }
		"IMPA" GG 1 { A_SpawnProjectile("RS_AbyssBallCH", 32, 3, random(-9, 9)); }
		Goto See;
	Missile.T06.Dash:
		"IMPA" EF 9 Bright;
		"IMPA" G 1 { ThrustThingZ(0, 16, 0, 0); }
		"IMPA" G 7 { ThrustThing(angle * 256 / 360, 42, 0, 0); }
		"IMPA" G 1;
		"IMPA" F 5 { A_FaceTarget(); }
		TNT1 AAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(32, 256), random(-252, 252), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"IMPA" G 2;
		"IMPA" F 5 { A_FaceTarget(); }
		TNT1 AAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 328), random(-178, 178), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"IMPA" G 2;
		Goto See;
	Pain.T06:
		"IMPA" H 1 { bNOPAIN = true; }
		"IMPA" H 1 { A_Pain(); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"IMPA" H 1 A_Jump(64, "Missile.T06.Dash");
		Goto See;
	Death.T06:
		"IMPA" I 8;
		"IMPA" J 8 { A_Scream(); }
		"IMPA" K 6;
		"IMPA" L 6 { A_NoBlocking(); }
		"IMPA" M -1;
		Stop;
	Raise.T06:
		"IMPA" MLKJI 8;
		Goto See;

	// ================= T07 FIREBLU (03_F) =================
	// Red bomb, blue bomb, then a shotgun burst if you're still close.
	Spawn.T07:
		"IMPF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"IMPF" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T07:
		"IMPF" EF 8;
		"IMPF" G 6 { A_CustomMeleeAttack(random(10, 29), "imp/melee"); }
		Goto See;
	Missile.T07:
		"IMPF" EF 7 { A_FaceTarget(); }
		"IMPF" G 7 { A_SpawnProjectile("RS_RedBBallImp", 32, 3, random(-5, 1)); }
		"IMPF" E 0 A_CheckSight("See");
		"IMPF" EF 7 { A_FaceTarget(); }
		"IMPF" G 7 { A_SpawnProjectile("RS_BluBBallImp", 32, 3, random(-1, 5)); }
		"IMPF" E 0 A_CheckSight("See");
		TNT1 A 0 A_JumpIfCloser(400, "Missile.T07.Burst");
		Goto See;
	Missile.T07.Burst:
		"IMPF" H 4;
		"IMPF" HHH 2 { A_SpawnProjectile("RS_FireSGguy", 32, random(-8, 8), random(-64, 64)); }
		"IMPF" H 4;
		Goto See;
	Pain.T07:
		"IMPF" H 2;
		"IMPF" H 2 { A_Pain(); }
		Goto See;
	Death.T07:
		"IMPF" I 8;
		"IMPF" J 8 { A_Scream(); }
		"IMPF" K 6;
		"IMPF" L 6 { A_NoBlocking(); }
		"IMPF" M -1;
		Stop;
	Raise.T07:
		"IMPF" MLKJI 8;
		Goto See;

	// ================= T08 BROWN -- THE WARLORD (03_BR) =================
	// Spike volley at range; the parry YANKS you into melee. Drops its
	// mace and shield on death.
	Spawn.T08:
		"WARI" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"WARI" AABB 3 { A_Chase(); }
		TNT1 A 0 A_Jump(32, "See.T08.ParryCheck");
		"WARI" CCDD 3 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "See.T08.ParryCheck");
		Loop;
	See.T08.ParryCheck:
		TNT1 A 0 A_JumpIfInTargetLOS("Missile.T08.Parry", 0, JLOSF_DEADNOJUMP, 1200, 200);
		Goto See;
	Melee.T08:
		"WARI" E 6 { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("skeleton/swing", CHAN_WEAPON); }
		"WARI" F 4 { A_FaceTarget(); }
		"WARI" G 5 { A_CustomMeleeAttack(random(1, 8) * 7, "skeleton/melee", ""); }
		Goto See;
	Missile.T08:
		"WARI" A 1 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(32, "See.T08.ParryCheck");
		"WARI" A 1 { A_FaceTarget(); }
		Goto Missile.T08.Spikes;
	Missile.T08.Spikes:
		"WARI" E 3;
		"WARI" L 6 Bright { A_FaceTarget(); }
		"WARI" M 3 Bright;
		"WARI" N 0 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 8, 28, random(20, 45), 0, random(-1, 2), frandom(-5, -2)); }
		"WARI" N 0 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 8, 28, random(20, 45), 0, random(-1, 2), frandom(-1, 1)); }
		"WARI" N 0 Bright { A_SpawnProjectile("RS_FatsoSpikes2", 32, 12, 0); }
		"WARI" N 3 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 8, 28, random(20, 45), 0, random(-1, 2), frandom(2, 5)); }
		"WARI" G 3;
		TNT1 A 0 A_Jump(64, "See.T08.ParryCheck");
		Goto See;
	Missile.T08.Parry:
		"WARI" IIJJ 3 { A_FaceTarget(); }
		"WARI" K 1 { A_FaceTarget(); }
		"WARI" K 3 { A_SpawnItemEx("RS_BrownImpShieldMini", 18, 0, 24, 1, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		"WARI" K 12 { A_RadiusThrust(-420, 252, RTF_NOIMPACTDAMAGE | RTF_THRUSTZ | RTF_NOTMISSILE, 128); }
		"WARI" K 12;
		"WARI" JJII 3;
		Goto See;
	Pain.T08:
		"WARI" H 2;
		"WARI" H 2 { A_Pain(); }
		"WARI" H 4 A_Jump(64, "Missile.T08.Parry");
		Goto See;
	Death.T08:
		TNT1 A 0 { A_FaceTarget(); A_SpawnItemEx("RS_WarlordMace", 0, 0, 32, 4, 0, 0, -90, 128); }
		"WARI" R 8 { A_SpawnItemEx("RS_WarlordShield", 0, 0, 32, 5, 0, 0, 90, 128); }
		"WARI" S 8 { A_Scream(); }
		"WARI" T 6;
		"WARI" U 6 { A_NoBlocking(); }
		"WARI" V -1;
		Stop;
	Raise.T08:
		"WARI" VUTSR 8;
		Goto See;

	// ================= T09 GRAY (03_GY) =================
	// Two 5-nail rings per volley; the corpse bursts into a full ring.
	Spawn.T09:
		"GIMP" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"GIMP" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T09:
		"GIMP" EF 8 { A_FaceTarget(); }
		"GIMP" G 6 { A_FaceTarget(); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 0); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 45); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 135); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 225); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 315); }
		"GIMP" EF 6 { A_FaceTarget(); }
		"GIMP" G 5 { A_FaceTarget(); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 15); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 75); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 105); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 165); }
		"GIMP" D 0 { A_SpawnProjectile("RS_GImpNail", 32, 0, 195); }
		Goto See;
	Pain.T09:
		"GIMP" H 3 { A_Pain(); }
		"GIMP" H 2 A_Jump(128, "Missile");
		Goto See;
	Death.T09:
		"GIMP" I 5 { A_SpawnProjectile("RS_Impthing3", 0, 0, 0); }
		"GIMP" J 5 { A_XScream(); }
		"GIMP" K 5;
		"GIMP" L 2 { A_NoBlocking(); }
		TNT1 AAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_PuffCybieRed", 0, 0, 2, random(3, 9), 0, random(1, 15), random(0, 359)); }
		"GIMP" RSTU 5;
		"GIMP" U -1;
		Stop;

	// ================= T10 RED (03_R) =================
	// 5-ball burst. Permanently enrages the first time it takes pain.
	Spawn.T10:
		"PRIM" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"PRIM" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T10:
		"PRIM" EF 8 { A_FaceTarget(); }
		"PRIM" G 6 { A_CustomMeleeAttack(random(10, 38), "imp/melee"); }
		Goto See;
	Missile.T10:
		"PRIM" EF 4 { A_FaceTarget(); }
		"PRIM" G 3;
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 32, 12, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 32, 4, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 32, 20, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 22, 12, 0); }
		"PRIM" G 0 { A_SpawnProjectile("RS_RedMessImp2", 42, 12, 0); }
		Goto See;
	Pain.T10:
		"PRIM" H 3 { A_Pain(); }
		"PRIM" H 3 { bNOPAIN = true; }
		"PRIM" H 3 { bMISSILEEVENMORE = true; }
		"PRIM" H 2 { A_StartSound("imp/pain", CHAN_VOICE); }
		"PRIM" H 4 { A_SetSpeed(14); rsEnraged = 1; MarkEnrageTell(); }
		Goto See;
	Death.T10:
		"PRIM" N 5 { A_SpawnProjectile("RS_HKRedDeath", 32, 0); }
		"PRIM" O 5 { A_XScream(); }
		"PRIM" P 5;
		"PRIM" Q 5 { A_NoBlocking(); }
		"PRIM" RST 5;
		"PRIM" U -1;
		Stop;

	// ================= T11 BLACK -- AGAURES (03_K) =================
	// Three attack modes, ally-healing death breath on melee and before
	// every volley.
	Spawn.T11:
		"AGUR" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"AGUR" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T11:
		"AGUR" W 6 { A_FaceTarget(); }
		"AGUR" X 6 { A_FaceTarget(); }
		"AGUR" Y 6 { A_CustomMeleeAttack(random(20, 65), "agaures/swing", ""); }
		"AGUR" YYY 0 { A_SpawnItemEx("RS_DeathBreathDI", random(-118, 118), random(-118, 118), random(-6, 32), 0, 0, 0, 0, 128); }
		"AGUR" Y 0 A_Jump(88, "Missile");
		Goto See;
	Missile.T11:
		"AGUR" AAA 0 { A_SpawnItemEx("RS_DeathBreathDI", random(-88, 88), random(-88, 88), random(-6, 27), 0, 0, 0, 0, 128); }
		"AGUR" A 0 { A_SetTranslucent(1.0); }
		"AGUR" A 0 A_Jump(256, "Missile.T11.One", "Missile.T11.Spam", "Missile.T11.Big");
		Goto See;
	Missile.T11.One:
		"AGUR" EF 12 { A_FaceTarget(); }
		"AGUR" G 6 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, 0); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, random(-15, 15)); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, random(-25, 25)); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall1", 37, 0, random(-15, 15)); }
		"AGUR" G 0 A_Jump(128, "Missile.T11.Spam");
		Goto See;
	Missile.T11.Spam:
		"AGUR" EF 8 { A_FaceTarget(); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, -5); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 0); }
		"AGUR" G 0 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 5); }
		"AGUR" G 0 A_CheckSight("See");
		"AGUR" EF 5 { A_FaceTarget(); }
		"AGUR" G 4 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 0); }
		"AGUR" G 0 A_CheckSight("See");
		"AGUR" EF 4 { A_FaceTarget(); }
		"AGUR" G 3 { A_SpawnProjectile("RS_AgauresBall2", 37, 0, 0); }
		Goto See;
	Missile.T11.Big:
		"AGUR" E 12 Bright { A_FaceTarget(); }
		"AGUR" F 12 Bright { A_FaceTarget(); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 28, 0); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 32, 0); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 36, 0); }
		"AGUR" G 8 Bright { A_SpawnProjectile("RS_DIBigOne", 38, 0, 0); }
		"AGUR" G 4;
		"AGUR" A 10;
		Goto See;
	Pain.T11:
		"AGUR" H 2 { A_SetTranslucent(1.0); }
		"AGUR" H 2 { A_Pain(); }
		Goto See;
	Death.T11:
		"AGUR" J 12 { A_Scream(); }
		"AGUR" KL 12;
		"AGUR" M 12 { A_NoBlocking(); }
		"AGUR" N -1;
		Stop;

	// ================= T12 WHITE (03_W) =================
	// Weaves chase/fast-chase. Three modes: colour-ball storm, megaball
	// spark barrage, or a summon that also rains hellion rounds.
	Spawn.T12:
		"HELN" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"HELN" AABBCC 2 { A_Chase(); }
		"HELN" C 0 A_Jump(42, "See.T12.Fast");
		"HELN" DDEEFF 2 { A_Chase(); }
		"HELN" F 0 A_Jump(64, "See.T12.Fast");
		Loop;
	See.T12.Fast:
		"HELN" AABBCC 2 { A_FastChase(); }
		"HELN" C 0 A_Jump(84, "See");
		"HELN" DDEEFF 2 { A_FastChase(); }
		"HELN" F 0 A_Jump(128, "See");
		Loop;
	Missile.T12:
		"HELN" G 0 A_Jump(256, "Missile.T12.Colors", "Missile.T12.Mega", "Missile.T12.Summon");
		Goto See;
	Missile.T12.Colors:
		"HELN" JIG 6 Bright { A_FaceTarget(); }
		"HELN" H 6 Bright { A_StartSound("imp/sight", CHAN_VOICE); }
		"HELN" J 5 Bright { A_FaceTarget(); }
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall1", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 2 Bright { A_SpawnProjectile("RS_WimpBall2", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall3", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 2 Bright { A_SpawnProjectile("RS_WimpBall4", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall5", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 2 Bright { A_SpawnProjectile("RS_WimpBall1", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 1 Bright { A_SpawnProjectile("RS_WimpBall2", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" L 1 Bright { A_SpawnProjectile("RS_WimpBall3", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		"HELN" K 2 Bright { A_SpawnProjectile("RS_WimpBall4", random(15, 40), random(-12, 12), random(-12, 12), CMF_OFFSETPITCH, random(-4, 9)); }
		Goto See;
	Missile.T12.Mega:
		"HELN" G 0 { A_FaceTarget(); }
		"HELN" GG 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 74, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" HH 1 { A_SpawnProjectile("RS_SparkPuff1", 74, random(-2, 2), random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" GG 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 64, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" HH 1 { A_SpawnProjectile("RS_SparkPuff1", 74, random(-2, 2), random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" GG 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 74, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" II 2 Bright { A_SpawnProjectile("RS_SparkPuff1", 56, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" JJ 2 Bright { A_SpawnProjectile("RS_SparkPuff1", 42, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" JK 5 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T12.Summon:
		"HELN" H 11 Bright { A_SpawnProjectile("RS_BaronRing", 64, 0); }
		"HELN" K 9 Bright { A_Pain(); }
		"HELN" H 10 Bright { A_Pain(); }
		"HELN" K 8 Bright { A_SpawnProjectile("RS_BaronRing", 64, 0); }
		"HELN" J 6 Bright { A_Pain(); }
		"HELN" I 5 Bright { A_Pain(); }
		"HELN" GGGGGGG 2 Bright { SummonMinion("RS_Imp", -5, 88.0); }
		"HELN" H 12 Bright A_Jump(84, "Missile.T12.Rain");
		Goto See;
	Missile.T12.Rain:
		"HELN" GGGGGGGGG 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 74, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"HELN" HHHHHHHHH 1 Bright { A_SpawnProjectile("RS_Hel2", 64, 0, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		Goto See;
	Pain.T12:
		"HELN" M 2;
		"HELN" M 2 { A_Pain(); }
		"HELN" M 0 A_Jump(84, "Missile.T12.Rain");
		Goto See;
	Death.T12:
		"HELN" O 6 { A_Scream(); }
		"HELN" PQR 6;
		"HELN" S 6 { A_NoBlocking(); }
		"HELN" T -1;
		Stop;

	// ================= TEX GREEN AGAURES (03_KX) =================
	// The EX tier: CHP's GreenBlackImpEX2, "Smoking Green Imp EX". T11's
	// body, nearly three times the health, and a five-way roster that is
	// the widest in the family:
	//
	//   KAMEHAMEHA  a charged RAILGUN -- two charge orbs, a wind-up, then
	//               a hitscan beam that leaves a burning corridor behind
	//   SMOKEOUT    marks you with A_VileTarget, then plants a homing
	//               floor-hugging smoke cloud ON your position
	//   ONESHOT     thirty balls in a fan that TIGHTENS as it goes -- it
	//               starts wide and walks onto you
	//   BIGSHOT     charged megaball with a visible three-stage tell
	//   SPAMRAIN    forty arcing rounds lobbed from above
	//
	// The whole thing is wrapped in permanent DeathBreath smoke: it leaks
	// on every walk cycle, every melee, every volley and both deaths, so
	// the arena fills up and sightlines close as the fight goes on.
	//
	// WARP is the reason it is hard: on pain it can go NOPAIN, sprint at
	// speed 124 for about half a second, and reappear somewhere else.
	Spawn.TEX:
		"AGUR" AB 10 { A_Look(); }
		Loop;
	See.TEX:
		"AGUR" AA 3 { A_Chase(); }
		"AGUR" YYY 0 { A_SpawnItemEx("RS_DeathBreathDI", -1, random(-18, 18), random(2, 32), random(1, 5), 0, 1, random(90, 270)); }
		"AGUR" BB 3 { A_Chase(); }
		"AGUR" YYY 0 { A_SpawnItemEx("RS_DeathBreathDI", -2, random(-18, 18), random(2, 32), random(1, 5), 0, 2, random(90, 270)); }
		"AGUR" CC 3 { A_Chase(); }
		"AGUR" YYY 0 { A_SpawnItemEx("RS_DeathBreathDI", -3, random(-18, 18), random(2, 32), random(1, 5), 0, 3, random(90, 270)); }
		"AGUR" DD 3 { A_Chase(); }
		"AGUR" YYY 0 { A_SpawnItemEx("RS_DeathBreathDI", -4, random(-18, 18), random(2, 32), random(1, 5), 0, 4, random(90, 270)); }
		Loop;
	// Melee that can roll STRAIGHT into a volley -- closing on it is not
	// a way to shut the ranged game down.
	Melee.TEX:
		"AGUR" W 6 { A_FaceTarget(); }
		"AGUR" X 6 { A_FaceTarget(); }
		"AGUR" Y 6 { A_CustomMeleeAttack(random(25, 119), "agaures/swing", ""); }
		"AGUR" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, 0, random(1, 6), random(3, 15), 0, random(1, 12), random(-359, 359)); }
		"AGUR" YYY 0 { A_SpawnItemEx("RS_DeathBreathDI", random(-118, 118), random(-118, 118), random(-6, 32), 0, 0, 0, 0, 128, 0); }
		"AGUR" Y 0 A_Jump(88, "Missile");
		Goto See;
	// Beyond 1300 only the two long-range options; inside it, all five.
	Missile.TEX:
		"AGUR" AAA 0 { A_SpawnItemEx("RS_DeathBreathDI", random(-88, 88), random(-88, 88), random(-6, 27), random(1, 9), 0, 1, random(-359, 359)); }
		"AGUR" A 0 A_JumpIfCloser(1300, "Missile.TEX.Choice");
		"AGUR" A 0 A_Jump(256, "Missile.TEX.Kamehameha", "Missile.TEX.SmokeOut");
		Goto See;
	Missile.TEX.Choice:
		TNT1 A 0 A_Jump(256, "Missile.TEX.Kamehameha", "Missile.TEX.SmokeOut", "Missile.TEX.OneShot", "Missile.TEX.BigShot", "Missile.TEX.SpamRain");
	// The railgun. Two charge orbs at shoulder height, an eighteen-tic
	// hold, and then a beam that keeps burning where it passed.
	Missile.TEX.Kamehameha:
		"AGUR" W 2 { A_StartSound("agaures/sight", CHAN_VOICE, 0, 1.0, ATTN_NONE); }
		"AGUR" W 2 Bright { A_FaceTarget(); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 1, 32, 42); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 1, -32, 42); }
		"AGUR" W 18 Bright;
		"AGUR" X 8 { A_FaceTarget(); }
		"AGUR" Y 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"AGUR" Y 9 Bright
		{
			A_CustomRailgun(random(25, 100), 0, Color(255, 255, 255), Color(255, 255, 255),
			                RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_BlackImpBeam1",
			                0, 0, 0, 0, 0.4, 1.0, "RS_BlackImpBeam2", 1);
		}
		"AGUR" Y 16;
		"AGUR" YYY 0 { A_SpawnItemEx("RS_DeathBreathDI", random(-118, 118), random(-118, 118), random(-6, 32), random(1, 9), 0, 1, random(-359, 359)); }
		Goto See;
	// Marks you, then drops a floor-hugging smoke hunter on the mark.
	// You cannot outrun it by breaking line of sight -- that is the point.
	Missile.TEX.SmokeOut:
		"AGUR" Y 2;
		"AGUR" Y 2 { A_FaceTarget(); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 16, 3, 32); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 16, -3, 32); }
		"AGUR" Y 1 { A_VileTarget("RS_CHBSTarget"); }
		"AGUR" YYY 2 Bright { A_SpawnItemEx("RS_DeathBreathDI", -4, random(-18, 18), random(2, 32), random(1, 5), 0, 1, random(90, 270)); }
		"AGUR" YYYYYYYY 1 Bright { A_SpawnItemEx("RS_DeathBreathDI", -4, random(-18, 18), random(2, 32), random(1, 5), 0, 1, random(90, 270)); }
		"AGUR" YYYYY 0 Bright { A_SpawnItemEx("RS_DeathBreathDI", -4, random(-18, 18), random(2, 32), random(1, 5), 0, 1, random(90, 270)); }
		"AGUR" Y 3 Bright A_CheckSight("See");
		"AGUR" Y 9 Bright { A_FaceTarget(); }
		"AGUR" Y 4 Bright { A_VileTarget("RS_BlackImpSmokeOut"); }
		"AGUR" XW 6;
		Goto See;
	// Thirty balls whose spread narrows from +-30 to +-1 across the
	// burst, so the last shots land exactly where you dodged to.
	Missile.TEX.OneShot:
		"AGUR" EF 12 { A_FaceTarget(); }
		"AGUR" GGGGGGGGGGGG 1 Bright { A_SpawnProjectile("RS_BlackImpEXBall1", 42, 0, random(-30, 30)); }
		"AGUR" G 0 { A_FaceTarget(); }
		"AGUR" GGGGGGGGG 2 Bright { A_SpawnProjectile("RS_BlackImpEXBall1", 42, 0, random(-15, 15)); }
		"AGUR" G 0 { A_FaceTarget(); }
		"AGUR" GGGGGG 3 Bright { A_SpawnProjectile("RS_BlackImpEXBall1", 42, 0, random(-7, 7)); }
		"AGUR" G 0 { A_FaceTarget(); }
		"AGUR" GGG 4 Bright { A_SpawnProjectile("RS_BlackImpEXBall1", 42, 0, random(-1, 1)); }
		"AGUR" GF 6 A_Jump(24, "Missile.TEX.BigShot");
		Goto See;
	// The megaball. Two charge pairs and three rising sparks -- nearly a
	// second of unambiguous "move now".
	Missile.TEX.BigShot:
		"AGUR" E 12 Bright { A_FaceTarget(); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 1, 32, 38); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 1, -32, 38); }
		"AGUR" F 12 Bright { A_FaceTarget(); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 1, 32, 38); }
		"AGUR" A 0 { A_SpawnItemEx("RS_BlackImpEXCharge", 1, -32, 38); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 28, 0); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 32, 0); }
		"AGUR" F 2 Bright { A_SpawnProjectile("RS_EffectHK", 36, 0); }
		"AGUR" G 1 Bright { A_FaceTarget(); }
		"AGUR" G 8 Bright { A_SpawnProjectile("RS_BlackImpEXBigOne", 64, 0, 0); }
		"AGUR" G 4;
		"AGUR" A 10;
		Goto See;
	// Forty rounds lobbed from 70-90 units up -- area saturation rather
	// than aimed fire.
	Missile.TEX.SpamRain:
		"AGUR" EF 8 { A_FaceTarget(); }
		"AGUR" GGGGG 1 { A_SpawnProjectile("RS_BlackImpEXBall2", random(70, 90), 0, random(-15, 15)); }
		"AGUR" GGGGGGG 0 { A_SpawnProjectile("RS_BlackImpEXBall2", random(70, 90), 0, random(-15, 15)); }
		"AGUR" G 1 { A_FaceTarget(); }
		"AGUR" GGGG 2 { A_SpawnProjectile("RS_BlackImpEXBall2", random(70, 90), 0, random(-10, 10)); }
		"AGUR" GGGGGGGGGGG 0 { A_SpawnProjectile("RS_BlackImpEXBall2", random(70, 90), 0, random(-15, 15)); }
		"AGUR" G 1 { A_FaceTarget(); }
		"AGUR" GGG 3 { A_SpawnProjectile("RS_BlackImpEXBall2", random(70, 90), 0, random(-5, 5)); }
		"AGUR" GGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_BlackImpEXBall2", random(70, 90), 0, random(-15, 15)); }
		"AGUR" GF 6 A_Jump(24, "Missile.TEX.BigShot");
		Goto See;
	Pain.TEX:
		"AGUR" H 2;
		"AGUR" YYYYYYYYY 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, random(-18, 18), random(2, 32), random(3, 8), 0, 1, random(-359, 359)); }
		"AGUR" H 2 { A_Pain(); }
		"AGUR" A 0 A_Jump(64, "See.TEX.Warp");
		Goto See;
	// THE WARP. Speed 124, NOPAIN, ten tics of wandering, then back to
	// normal -- it is gone before the pain animation would have finished.
	See.TEX.Warp:
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, 0, random(1, 6), random(3, 15), 0, random(1, 12), random(-359, 359)); }
		TNT1 A 0 { bNOPAIN = true; A_SetSpeed(124); }
		TNT1 AAAA 0 { A_Wander(); }
		TNT1 AA 3 { A_Wander(); }
		TNT1 AAAA 1 { A_Wander(); }
		TNT1 A 0 { A_SetSpeed(18); bNOPAIN = false; }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, 0, random(1, 6), random(3, 15), 0, random(1, 12), random(-359, 359)); }
		Goto See;
	Death.TEX:
		"AGUR" I 12;
		"AGUR" J 12 { A_Scream(); }
		"AGUR" KL 12;
		"AGUR" M 12 { A_NoBlocking(); }
		"AGUR" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, 0, random(1, 6), random(3, 15), 0, random(1, 12), random(-359, 359)); }
		"AGUR" N -1;
		Stop;
	XDeath.TEX:
		TNT1 A 0 { A_StartSound("misc/gibbed", CHAN_BODY); }
		"AGUR" O 5 { A_XScream(); }
		"AGUR" P 5;
		"AGUR" Q 5 { A_NoBlocking(); }
		"AGUR" RSTU 5;
		"AGUR" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_DeathBreathDI", 0, 0, random(1, 6), random(3, 15), 0, random(1, 12), random(-359, 359)); }
		"AGUR" V -1;
		Stop;
	}
}
