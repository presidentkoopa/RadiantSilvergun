// =====================================================================
// RS_Arachnotron -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\12\12_<code>.txt
// One CHP file per colour; the FIRST actor in each file is the creature
// this tier wears. Each has its OWN sprite set, stats and attack --
// nothing here is inferred, tinted or shared unless CHP shares it.
// CH (decorate/Spiders.txt) was consulted only for states CHP leaves
// undefined; every tier below turned out to be fully defined in CHP.
//
//   tier  CHP     actor                  body  HP     what it actually is
//   T00   12_C    CommonCommonSpider     BSPI    500  vanilla: plasma-arc spam
//   T01   12_G    CommonGreenSpider      BSPG    600  green: twin spider-spit,
//                                                     50% chance to re-fire
//   T02   12_B    CommonBlueSpider       BSPB    700  blue: fast plasma stream
//   T03   12_CY   CommonCyanSpider       BSCY    555  cyan FLYER: ice-bomb
//                                                     barrage or a 3-orb fan,
//                                                     blink-wanders, shatters
//   T04   12_P    CommonPurpleSpider     CSPI    800  purple: HITSCAN chaingun
//   T05   12_Y    CommonYellowSpider     ACNB    777  yellow Brainchoton FLYER:
//                                                     arachnorb spam up close,
//                                                     psychic railgun far, bite
//   T06   12_A    CommonAbyssSpider      ABSP   1850  abyss "Eye see": holy
//                                                     bolts / ice breath /
//                                                     psychic void, blink-warps
//   T07   12_F    CommonFirebluSpider    BSPF    999  fireblu FLYER: 12-way
//                                                     seeking ring up close,
//                                                     paired stream at range
//   T08   12_BR   CommonBrownSpider      ARAC    915  Brown Recluse: heals and
//                                                     seeds medikits, then orb
//                                                     volley or 64-deg spam
//   T09   12_GY   CommonGraySpider       CSPG    600  Metal Spider: painted
//                                                     stone rockets, or a
//                                                     point-blank spike vent
//   T10   12_R    CommonRedSpider        BSP2   1444  Red Rage: NOPAIN seeking
//                                                     bombs, or fatso rockets
//   T11   12_K    CommonBlackSpider2     MSPI   5342  MACROSS MISSILE SPAM:
//                                                     four modes incl. a
//                                                     hovering 20-missile dump
//   T12   12_W    CommonWhiteSpider2     TRIT  10000  WHITE SPIDER: nine
//                                                     patterns, webs, egg-layer
//                                                     below 4000 HP
//   TEX   12_KX   CommonBlackSpiderEX2   KSPX  12000  MACROSS MISSILE SPAM EX:
//                                                     four patterns, and below
//                                                     7000 HP the pool does not
//                                                     widen -- it SWAPS to five
//                                                     different ones
//   T14   12_WX   CommonWhiteSpiderEX2   WSPX   9500  WHITE HOT SPIDER: range
//                                                     bands pick the pattern,
//                                                     lifts off to unload, and
//                                                     below 5000 HP unlocks
//                                                     KRAKATOA
//   T15   12_W3   CommonWhiteSpider3     TRIT   4000  WHITE SPIDER OF TERROR:
//                                                     the T12 body's next
//                                                     stage; four patterns,
//                                                     six below 2500 HP
//
// THE LADDER IS OPEN-ENDED (see RS_MonsterMaster): TEX/T14/T15 are simply
// three more kinds of arachnotron above the thirteen CH colours, so
// MaxTier() is raised to 15 rather than the base's 13.
//
// Tier stats are CHP's own Health/Speed/PainChance per file, applied
// through TierData() as multipliers off the Default block.
//
// RS mechanics preserved from the previous file: RS_HoverBarrage (now
// wired to the two attacks CHP itself lifts off for -- T11's missile
// dump and T12's bolt storm), BuildTierAttacks, the T11+ shrinking
// death chain (DeathMorphClass -> RS_ArachnotronStage2, stages live in
// RS_MonsterStages.zs), GetBaseKeywords, and +MAP07BOSS2.
// =====================================================================

class RS_Arachnotron : RS_MonsterMaster replaces Arachnotron
{
	// CHP's white arachnotron EX dies into a smaller copy of itself,
	// twice, keeping its kit at reduced scale before shattering.
	const RS_ARACH_TIER_CHAIN = 11;

	Default
	{
		Health 500;
		Radius 64;
		Height 64;
		Mass 600;
		Speed 12;
		PainChance 128;
		Monster;
		+FLOORCLIP +BOSSDEATH
		+MAP07BOSS2   // last arachnotron on MAP07 raises floor tag 667
		SeeSound "baby/sight";   PainSound "baby/pain";
		DeathSound "baby/death"; ActiveSound "baby/active";
		// T05's Brainchoton is the only tier with a bite; MeleeDamage /
		// MeleeSound are Default-only properties in CHP's YellowSP1 and
		// are inert for every other tier (none has a Melee state).
		MeleeDamage 6;
		MeleeSound "aracnorb/melee";
		Obituary "$OB_BABY";
		Tag "Arachnotron";
	}

	// CHP's real per-colour numbers, read from 12_*.txt. Default Health
	// is 500 and Default Speed 12, so the absolute values are expressed
	// as multipliers and the base class's recompute contract still holds.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 128; r.dmgMul = 1.0;
		int hp = 500; int spd = 12;
		switch (t)
		{
			case 0:  hp = 500;   spd = 12; r.painChance = 128; r.dmgMul = 1.0; break;
			case 1:  hp = 600;   spd = 13; r.painChance = 100; r.dmgMul = 1.1; break;
			case 2:  hp = 700;   spd = 14; r.painChance = 80;  r.dmgMul = 1.2; break;
			case 3:  hp = 555;   spd = 20; r.painChance = 128; r.dmgMul = 1.3; break;
			case 4:  hp = 800;   spd = 16; r.painChance = 20;  r.dmgMul = 1.4; break;
			case 5:  hp = 777;   spd = 15; r.painChance = 150; r.dmgMul = 1.5; break;
			case 6:  hp = 1850;  spd = 24; r.painChance = 24;  r.dmgMul = 1.6; break;
			case 7:  hp = 999;   spd = 11; r.painChance = 150; r.dmgMul = 1.5; break;
			case 8:  hp = 915;   spd = 20; r.painChance = 32;  r.dmgMul = 1.5; break;
			case 9:  hp = 600;   spd = 13; r.painChance = 12;  r.dmgMul = 1.6; break;
			case 10: hp = 1444;  spd = 16; r.painChance = 68;  r.dmgMul = 1.8; break;
			case 11: hp = 5342;  spd = 21; r.painChance = 24;  r.dmgMul = 2.5; break;
			case 12: hp = 10000; spd = 28; r.painChance = 32;  r.dmgMul = 3.0; break;
			// TEX (13) -- 12_KX's own numbers, not an extrapolation.
			case 13: hp = 12000; spd = 20; r.painChance = 24;  r.dmgMul = 3.5; break;
			// T14/T15 -- absolute hand-assigned rows (r.hp / r.speed), which
			// ApplyTier prefers over the multiplier path. CHP's numbers:
			// 12_WX Health 9500 / Speed 22 / PainChance 32, and 12_W3
			// Health 4000 with Speed 28 / PainChance 32 inherited from
			// CommonWhiteSpider2 (the T12 body it is the next stage of).
			case 14: r.hp = 9500; r.speed = 22; r.painChance = 32; r.dmgMul = 4.0; return true;
			case 15: r.hp = 4000; r.speed = 28; r.painChance = 32; r.dmgMul = 4.5; return true;
			default: return false;
		}
		r.hpMul  = double(hp) / 500.0;
		r.spdMul = double(spd) / 12.0;
		return true;
	}

	// CHP ships three arachnotrons above the thirteen CH colours.
	override int MaxTier() { return 15; }

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/Arachnotron/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX  T14  T15
		return "BSPI BSPG BSPB BSCY CSPI ACNB ABSP BSPF ARAC CSPG BSP2 MSPI TRIT KSPX WSPX TRIT";
	}

	// CHP gives every colour its own ARTWORK, so no palette remap is
	// wanted -- a tint on top of bespoke art would corrupt it. T15 re-wears
	// T12's TRIT body and is the only tier that could have wanted a tint,
	// but CHP distinguishes CommonWhiteSpider3 with Translation "0:0=0:0"
	// -- an identity remap, i.e. no recolour at all. So "-" is correct, not
	// a placeholder: T15 is deliberately the same white spider, one stage on.
	override string TintTable()
	{
		return "- - - - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:arachnotron role:artillery delivery:heavy element:plasma mobility:ground";
	}

	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_ARACH_TIER_CHAIN) ? RS_MonsterCatalog.MORPH_ArachStage2() : null;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < 7)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(), 3, 20.0,
			"baby/attack", 1.0, 0.0, "Plasma Spread"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(),
			t >= 11 ? 20 : 12, 360.0,
			"baby/attack", 1.0, 5.0, "Plasma Ring"));
		return slot;
	}

	// Lift off and stop flinching for the duration of a big volley, so
	// interrupting it is a timing problem rather than a damage race.
	// Reverts itself via PulseStats; the two CHP attacks that call it
	// (T11 Miss3, T12 Atk1) also clear the flags themselves at the end.
	void RS_HoverBarrage()
	{
		bFLOAT = true;
		bNOGRAVITY = true;
		PulseStats(1.0, 1.0, 70, true);   // noPain for the volley
	}

	// CHP's cyan, yellow and fireblu spiders are genuine flyers (+FLOAT
	// +FLOATBOB +NOGRAVITY in their own Default blocks); everything else
	// walks. Re-asserted on every retier so a promoted spider does not
	// keep the previous body's locomotion.
	override void OnTierApplied(int t)
	{
		bool flies = (t == 3 || t == 5 || t == 7);
		bFLOAT     = flies;
		bNOGRAVITY = flies;
		bFLOATBOB  = flies;

		// TEX/T14/T15 all wear CHP's 56-unit chassis (Radius 56 in 12_KX,
		// 12_WX and 12_W3). Their Spawn clusters set it too, for the same
		// reason Spawn.T12 does; doing it here as well means a monster the
		// dial pushes into one of them mid-fight gets the right hitbox
		// without having to re-enter Spawn.
		if (t >= 13)
			A_SetSize(56, 64, true);
	}

	States
	{
	// =================================================================
	// T00 COMMON (12_C) -- BSPI, 500 HP. The vanilla plasma arc.
	// =================================================================
	Spawn.T00:
		"BSPI" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"BSPI" A 20;
	See.T00.Walk:
		"BSPI" A 0 { A_Chase(); }
		"BSPI" A 3 { A_StartSound("baby/walk"); }
		"BSPI" ABBCC 3 { A_Chase(); }
		"BSPI" A 0 { A_Chase(); }
		"BSPI" D 3 { A_StartSound("baby/walk"); }
		"BSPI" DEEFF 3 { A_Chase(); }
		Goto See.T00.Walk;
	Missile.T00:
		"BSPI" A 20 Bright { A_FaceTarget(); }
	Missile.T00.Loop:
		"BSPI" G 4 Bright { A_SpawnProjectile("RS_ArachnotronPlasma"); }
		"BSPI" H 4 Bright;
		"BSPI" H 1 Bright { A_SpidRefire(); }
		Goto Missile.T00.Loop;
	Pain.T00:
		"BSPI" I 3;
		"BSPI" I 3 { A_Pain(); }
		Goto See.T00.Walk;
	Death.T00:
		"BSPI" J 20 { A_Scream(); }
		"BSPI" K 7 { A_NoBlocking(); }
		"BSPI" LMNO 7;
		"BSPI" P -1 { A_BossDeath(); }
		Stop;
	XDeath.T00:
		"BSPI" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"BSPI" J 20 { A_Scream(); }
		"BSPI" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		"BSPI" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"BSPI" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARAG" A -1 { A_BossDeath(); }
		Stop;
	Raise.T00:
		"BSPI" P 5;
		"BSPI" ONMLKJ 5;
		Goto See.T00.Walk;

	// =================================================================
	// T01 GREEN (12_G) -- BSPG, 600 HP. Twin spider-spit, coin-flip
	// re-fire instead of the vanilla refire check.
	// =================================================================
	Spawn.T01:
		"BSPG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"BSPG" A 20;
	See.T01.Walk:
		"BSPG" A 0 { A_Chase(); }
		"BSPG" A 3 { A_StartSound("baby/walk"); }
		"BSPG" ABBCC 3 { A_Chase(); }
		"BSPG" A 0 { A_Chase(); }
		"BSPG" D 3 { A_StartSound("baby/walk"); }
		"BSPG" DEEFF 3 { A_Chase(); }
		Goto See.T01.Walk;
	Missile.T01:
		"BSPG" A 8 Bright { A_FaceTarget(); }
		"BSPG" G 7 Bright { A_SpawnProjectile("RS_SpSpit", 32, 0); }
		"BSPG" G 7 Bright { A_SpawnProjectile("RS_SpSpit", 32, 0, random(-1, 1)); }
		"BSPG" H 2 Bright A_Jump(128, "Missile.T01");
		Goto See;
	Pain.T01:
		"BSPG" I 3;
		"BSPG" I 3 { A_Pain(); }
		Goto See.T01.Walk;
	Death.T01:
		"BSPG" J 20 { A_Scream(); }
		"BSPG" K 7 { A_NoBlocking(); }
		"BSPG" LMNO 7;
		"BSPG" P -1 { A_BossDeath(); }
		Stop;
	XDeath.T01:
		"BSPG" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"BSPG" J 20 { A_Scream(); }
		"BSPG" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"BSPG" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"BSPG" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARA2" A -1 { A_BossDeath(); }
		Stop;
	Raise.T01:
		"BSPG" P 5;
		"BSPG" ONMLKJ 5;
		Goto See.T01.Walk;

	// =================================================================
	// T02 BLUE (12_B) -- BSPB, 700 HP. A fast, tight plasma stream.
	// =================================================================
	Spawn.T02:
		"BSPB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"BSPB" A 20;
	See.T02.Walk:
		"BSPB" A 0 { A_Chase(); }
		"BSPB" A 3 { A_StartSound("baby/walk"); }
		"BSPB" ABBCC 3 { A_Chase(); }
		"BSPB" A 0 { A_Chase(); }
		"BSPB" D 3 { A_StartSound("baby/walk"); }
		"BSPB" DEEFF 3 { A_Chase(); }
		Goto See.T02.Walk;
	Missile.T02:
		"BSPB" A 20 Bright { A_FaceTarget(); }
	Missile.T02.Loop:
		"BSPB" G 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 22, 0, random(-2, 2)); }
		"BSPB" H 3 Bright A_MonsterRefire(128, "See");
		Goto Missile.T02.Loop;
	Pain.T02:
		"BSPB" I 3;
		"BSPB" I 3 { A_Pain(); }
		Goto See.T02.Walk;
	Death.T02:
		"BSPB" J 20 { A_Scream(); }
		"BSPB" K 7 { A_NoBlocking(); }
		"BSPB" LMNO 7;
		"BSPB" P -1 { A_BossDeath(); }
		Stop;
	XDeath.T02:
		"BSPB" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"BSPB" J 20 { A_Scream(); }
		"BSPB" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"BSPB" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"BSPB" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARA3" A -1 { A_BossDeath(); }
		Stop;
	Raise.T02:
		"BSPB" P 5;
		"BSPB" ONMLKJ 5;
		Goto See.T02.Walk;

	// =================================================================
	// T03 CYAN (12_CY) -- BSCY, 555 HP. A FLYING spider: ice-bomb
	// barrage or a three-orb fan, blink-wanders mid-chase and on pain,
	// and shatters when it dies.
	// =================================================================
	Spawn.T03:
		"BSCY" A 1 { A_Look(); }
		Loop;
	See.T03:
		"BSCY" AAAAAAAAAAAA 2 { A_Chase(); }
		TNT1 A 0 A_Jump(144, "See.T03.Fast");
		TNT1 A 0 A_Jump(24, "See.T03.Blink");
		Loop;
	See.T03.Fast:
		"BSCY" A 2 { A_Chase(); }
		"BSCY" A 2 { A_FastChase(); }
		"BSCY" A 2 { A_Chase(); }
		"BSCY" A 2 { A_FastChase(); }
		Goto See.T03;
	See.T03.Blink:
		"BSCY" A 2 { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 2, 0, 0, 3, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_StartSound("ice/cast", 0); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		"BSCY" A 2 { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 2, 0, 0, 3, 0, SXF_NOCHECKPOSITION); }
		Goto See.T03;
	Melee.T03:
	Missile.T03:
		"BSCY" B 2 Bright { A_FaceTarget(); }
		"BSCY" B 0 A_Jump(256, "Missile.T03.IceBombing", "Missile.T03.IceOrbs");
	Missile.T03.IceBombing:
		"BSCY" BBB 2 Bright { A_FaceTarget(); }
		"BSCY" C 3 Bright { A_SpawnProjectile("RS_SpiderCyanBomb", 32, 0, random(-1, 1)); }
		"BSCY" B 0 A_CheckSight("See");
		"BSCY" B 2 Bright { A_SpidRefire(); }
		Goto Missile.T03.IceBombing;
	Missile.T03.IceOrbs:
		"BSCY" BB 6 Bright { A_FaceTarget(); }
		"BSCY" C 4 Bright;
		"BSCY" CC 0 { A_SpawnProjectile("RS_IceOrbCyanAra2", 32, 0, random(-10, 10)); }
		"BSCY" C 0 { A_SpawnProjectile("RS_IceOrbCyanAra1", 32, 0, -15); }
		"BSCY" C 10 Bright { A_SpawnProjectile("RS_IceOrbCyanAra1", 32, 0, 15); }
		Goto See;
	Pain.T03:
		"BSCY" I 2;
		"BSCY" I 2 { A_Pain(); }
		"BSCY" I 0 A_Jump(64, "See.T03.Blink");
		Goto See.T03.Fast;
	Death.T03:
		"BSCY" D 0 { bFLOATBOB = false; }
		"BSCY" D 0 { A_Scream(); }
		"BSCY" D 6 { A_NoBlocking(false); }
		"BSCY" D 10 { A_BossDeath(); }
		"BSCY" EFGH 8;
		TNT1 A 0 { A_SpawnItemEx("RS_CH_Cirno", 0, 0, 24, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM | SXF_NOCHECKPOSITION, 250); }
		TNT1 A 0 { A_StartSound("misc/icebreak"); }
		"BSCY" H 1 { A_Burst("IceChunk"); }
		"BSCY" H -1;
		Stop;
	XDeath.T03:
		Goto Death.T03;

	// =================================================================
	// T04 PURPLE (12_P) -- CSPI, 800 HP. Not a plasma spider at all:
	// a hitscan chaingun on a very long refire leash.
	// =================================================================
	Spawn.T04:
		"CSPI" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"CSPI" A 20;
	See.T04.Walk:
		"CSPI" A 0 { A_Chase(); }
		"CSPI" A 3 { A_StartSound("baby/walk"); }
		"CSPI" ABBCC 3 { A_Chase(); }
		"CSPI" A 0 { A_Chase(); }
		"CSPI" D 3 { A_StartSound("baby/walk"); }
		"CSPI" DEEFF 3 { A_Chase(); }
		Goto See.T04.Walk;
	Missile.T04:
		"CSPI" A 20 Bright { A_FaceTarget(); }
	Missile.T04.Loop:
		"CSPI" G 0 { A_StartSound("grunt/attack"); }
		"CSPI" G 3 Bright { A_CustomBulletAttack(6, 4, random(1, 4), random(1, 3), "BulletPuff"); }
		"CSPI" H 2 Bright A_MonsterRefire(200, "See");
		Goto Missile.T04.Loop;
	Pain.T04:
		"CSPI" I 3;
		"CSPI" I 3 { A_Pain(); }
		Goto See.T04.Walk;
	Death.T04:
		"CSPI" J 20 { A_Scream(); }
		"CSPI" K 7 { A_NoBlocking(); }
		"CSPI" LMNO 7;
		"CSPI" P -1 { A_BossDeath(); }
		Stop;
	XDeath.T04:
		"CSPI" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"CSPI" J 20 { A_Scream(); }
		"CSPI" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"CSPI" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"CSPI" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARA4" A -1 { A_BossDeath(); }
		Stop;
	Raise.T04:
		"CSPI" P 5;
		"CSPI" ONMLKJ 5;
		Goto See.T04.Walk;

	// =================================================================
	// T05 YELLOW (12_Y) -- ACNB, 777 HP. The Brainchoton: a FLOATING
	// brain-spider that bites in melee, spams arachnorbs inside 1300
	// units, and otherwise winds up a psychic railgun barrage that ends
	// in an arch-vile-style head-crush. Pain uses the ACNF sheet --
	// ACNB has no I frame, which is exactly why CHP switches sets.
	// =================================================================
	Spawn.T05:
		"ACNB" A 1 { A_Look(); }
		Loop;
	See.T05:
		"ACNB" A 0 { bFLOAT = true; }
		"ACNB" A 0 { bFLOATBOB = true; }
		"ACNB" A 0 { bNOGRAVITY = true; }
	See.T05.Chase:
		"ACNB" A 2 { A_Chase(); }
		Goto See.T05.Chase;
	Melee.T05:
		"ACNB" AB 5;
		"ACNB" C 6 { A_MeleeAttack(); }
		Goto See.T05.Chase;
	Missile.T05:
		"ACNB" B 12 Bright { A_FaceTarget(); }
		"ACNB" B 0 A_JumpIfCloser(1300, "Missile.T05.Psyche1");
		"ACNB" B 0 A_Jump(256, "Missile.T05.Psyche2");
		Goto See.T05.Chase;
	Missile.T05.Psyche2:
		"ACNB" C 9 Bright { A_FaceTarget(); }
		"ACNB" C 1 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		TNT1 A 0 { A_StartSound("Vile/Active", 7, 0, 2.0, ATTN_NONE); }
		"ACNB" C 3 Bright A_CheckSight("See");
		"ACNB" C 9 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ACNB" C 3 Bright A_CheckSight("See");
		"ACNB" C 1 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ACNB" C 3 Bright A_CheckSight("See");
		"ACNB" C 9 Bright { A_FaceTarget(); }
		"ACNB" C 1 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ACNB" C 3 Bright A_CheckSight("See");
		"ACNB" C 1 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ACNB" C 9 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ACNB" C 3 Bright A_CheckSight("See");
		"ACNB" C 9 Bright { A_FaceTarget(); }
		"ACNB" C 1 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ACNB" C 3 Bright A_CheckSight("See");
		"ACNB" C 1 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_VileTarget("RS_PsychicAra"); }
		"ACNB" C 1 Bright { A_FaceTarget(); }
		"ACNB" C 3 Bright { A_VileTarget("RS_PsychicAra"); }
		"ACNB" C 1 Bright A_CheckSight("See");
		TNT1 A 0 { A_StartSound("Vile/Active", 7, 0, 2.0, ATTN_NONE); }
		"ACNB" D 12 Bright { A_VileAttack("electricplasma/hit", random(40, 80), 0, 0, 0, "getoutofmyheadcharles"); }
		"ACNB" B 5;
		Goto Missile.T05;
	Missile.T05.Psyche1:
		"ACNB" C 2 Bright { A_SpawnProjectile("RS_AracnorbBall", 36, 0, random(-3, 3)); }
		"ACNB" B 2 Bright;
		"ACNB" D 0 A_Jump(42, "See");
		"ACNB" D 0 { A_SpidRefire(); }
		Goto Missile.T05.Psyche1;
	Pain.T05:
		"ACNF" I 2;
		"ACNF" I 2 { A_Pain(); }
		Goto See.T05.Chase;
	Death.T05:
		// CHP hovers on D with a Wait until the corpse lands and the
		// engine hands off to Crash (EFG/H). RS has no per-tier Crash
		// dispatch, so the flyer's flags are dropped here and the crash
		// chain plays inline -- same frames, same order.
		"ACNB" D 0 { bFLOATBOB = false; bFLOAT = false; bNOGRAVITY = false; }
		"ACNB" D 0 { A_Scream(); }
		"ACNB" D 6 { A_Fall(); }
		"ACNB" D 1 { A_BossDeath(); }
		"ACNB" EFG 6;
		"ACNB" H -1;
		Stop;
	XDeath.T05:
		Goto Death.T05;
	Raise.T05:
		"ACNB" HGFEDA 8;
		"ACNB" A 0 { bFLOATBOB = true; }
		Goto See.T05;

	// =================================================================
	// T06 ABYSS (12_A) -- ABSP, 1850 HP. "Eye see": a walking eye that
	// leaves after-images, blink-warps on a 6/256 roll and on pain, and
	// picks between a bolt stream, a psychic void barrage and an ice
	// breath depending on range.
	// =================================================================
	Spawn.T06:
		"ABSP" ABCDDDCB 10 { A_Look(); }
		Loop;
	See.T06:
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPwalk1", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" A 3 { A_Chase(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPwalk1", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" A 3 { A_Chase(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPwalk2", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" A 3 { A_Chase(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPwalk2", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 A_Jump(6, "See.T06.Warp");
		Loop;
	See.T06.Warp:
		"ABSP" AAAAAAAAAA 0 { A_Wander(); }
		Goto See.T06;
	Missile.T06:
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" A 3 { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" B 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 A_JumpIfCloser(450, "Missile.T06.Choice1", true);
		"ABSP" A 0 A_Jump(256, "Missile.T06.Choice2");
		Goto See;
	Missile.T06.Choice1:
		"ABSP" A 0 A_Jump(256, "Missile.T06.Breath", "Missile.T06.Missin");
		Goto See;
	Missile.T06.Choice2:
		"ABSP" A 0 A_Jump(256, "Missile.T06.Voidi", "Missile.T06.Missin");
		Goto See;
	Missile.T06.Missin:
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" B 2 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" C 2 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" D 2 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 2 Bright;
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
	Missile.T06.Miss2:
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" E 2 Bright { A_FaceTarget(); }
		"ABSP" F 3 Bright { A_SpawnProjectile("RS_AbyssSPBolt", 38, 0, random(-1, 1)); }
		"ABSP" F 1 Bright { A_SpidRefire(); }
		Goto Missile.T06.Miss2;
	Missile.T06.Voidi:
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" B 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" C 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" D 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 12 Bright;
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
	Missile.T06.Voidi2:
		"ABSP" G 5 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 1 Bright A_CheckSight("See");
		"ABSP" G 9 Bright { A_FaceTarget(); }
		"ABSP" G 1 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ABSP" A 0 { A_StartSound("Vile/Active", 7, 0, 2.0, ATTN_NONE); }
		"ABSP" G 3 Bright A_CheckSight("See");
		"ABSP" G 9 Bright { A_FaceTarget(); }
		"ABSP" G 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright A_CheckSight("See");
		"ABSP" G 1 Bright { A_FaceTarget(); }
		"ABSP" G 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright A_CheckSight("See");
		"ABSP" G 9 Bright { A_FaceTarget(); }
		"ABSP" G 1 Bright { A_FaceTarget(); }
		"ABSP" G 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright A_CheckSight("See");
		"ABSP" G 1 Bright { A_FaceTarget(); }
		"ABSP" G 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 9 Bright { A_FaceTarget(); }
		"ABSP" G 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright A_CheckSight("See");
		"ABSP" G 9 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 1 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright { A_CustomRailgun(0, 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_PsychicAra", 0, 0, 0, 0, 0.8, 1.0, "RS_PsychicPulse", 1); }
		"ABSP" G 3 Bright A_CheckSight("See");
		"ABSP" G 1 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright { A_VileTarget("RS_PsychicAra"); }
		"ABSP" G 1 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright { A_VileTarget("RS_PsychicAra"); }
		"ABSP" G 1 Bright A_CheckSight("See");
		"ABSP" A 0 { A_StartSound("Vile/Active", 7, 0, 2.0, ATTN_NONE); }
		"ABSP" G 0 { A_VileTarget("RS_PsychicAbyssSP"); }
		"ABSP" G 12 Bright { A_VileAttack("electricplasma/hit", random(60, 120), 0, 0, 0, "getoutofmyheadcharles"); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" B 5;
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" A 0 A_Jump(16, "See");
		"ABSP" G 1 Bright { A_SpidRefire(); }
		Goto Missile.T06.Voidi2;
	Missile.T06.Breath:
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" B 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" C 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" D 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" G 3 Bright;
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" I 3 Bright;
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" J 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" H 3 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
	Missile.T06.Breath2:
		"ABSP" H 2 Bright { A_FaceTarget(); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" HH 1 Bright { A_SpawnProjectile("RS_AbyssSPBreath", 22, 0, random(-12, 12)); }
		"ABSP" HHHHH 1 Bright { A_SpawnProjectile("RS_AbyssSPBreath", 22, 0, random(-22, 22)); }
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 A_Jump(32, "See.T06.Warp");
		"ABSP" H 1 Bright { A_SpidRefire(); }
		Goto Missile.T06.Breath2;
	Pain.T06:
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPPain", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" B 3;
		"ABSP" A 0 { A_SpawnItemEx("RS_AbyssSPPain", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ABSP" C 3 { A_Pain(); }
		"ABSP" C 0 A_Jump(88, "See.T06.Warp");
		Goto See;
	Death.T06:
		"ABSP" BCD 15;
		"ABSP" G 0 { A_BossDeath(); }
		TNT1 A 0 { A_Scream(); }
		"ABSP" JIGG 15;
		TNT1 A 0 { A_NoBlocking(); }
		"ABSP" G 10 { A_SetScale(1.0, 0.7); }
		"ABSP" G 10 { A_SetScale(1.0, 0.4); }
		"ABSP" G 10 { A_SetScale(1.0, 0.1); }
		"ABSP" GGG 10 { A_FadeOut(0.33); }
		Stop;
	XDeath.T06:
		Goto Death.T06;

	// =================================================================
	// T07 FIREBLU (12_F) -- BSPF, 999 HP. A FLOATING disco ball: a
	// twelve-way seeking ring plus a scatter burst inside 1300 units,
	// a paired seeking stream beyond it.
	// =================================================================
	Spawn.T07:
		"BSPF" A 1 { A_Look(); }
		Loop;
	See.T07:
		"BSPF" A 0 { bFLOAT = true; }
		"BSPF" A 0 { bFLOATBOB = true; }
		"BSPF" A 0 { bNOGRAVITY = true; }
	See.T07.Chase:
		"BSPF" A 2 { A_Chase(); }
		Goto See.T07.Chase;
	Missile.T07:
		"BSPF" B 12 Bright { A_FaceTarget(); }
		"BSPF" B 0 A_JumpIfCloser(1300, "Missile.T07.Psyche1");
	Missile.T07.Psyche2:
		"BSPF" C 2 Bright { A_FaceTarget(); }
		"BSPF" CC 1 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB3", 36, 0, 0); }
		"BSPF" CC 2 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB3", 36, 0, 0); }
		"BSPF" B 0 A_JumpIfCloser(700, "Missile.T07.Psyche1");
		"BSPF" B 2 A_MonsterRefire(128, "See");
		Goto Missile.T07.Psyche2;
	Missile.T07.Psyche1:
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB1", 20, 0, 15, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB2", 20, 0, 45, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB1", 20, 0, 75, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB2", 20, 0, 105, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB1", 20, 0, 135, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB2", 20, 0, 165, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB1", 20, 0, 195, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB2", 20, 0, 225, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB1", 20, 0, 255, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB2", 20, 0, 285, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB1", 20, 0, 315, 0); }
		"BSPF" C 0 { A_SpawnProjectile("RS_PlasmaBallSPFB2", 20, 0, 345, 0); }
		"BSPF" CCCC 0 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB3", 36, 0, random(-120, 120)); }
		"BSPF" CCCC 0 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB4", 36, 0, random(-120, 120)); }
		"BSPF" C 0 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB3", 36, 0, random(-12, 12)); }
		"BSPF" C 1 Bright { A_SpawnProjectile("RS_PlasmaBallSPFB4", 36, 0, random(-12, 12)); }
		"BSPF" C 5 Bright;
		"BSPF" B 2 Bright;
		"BSPF" D 0 A_Jump(32, "See");
		"BSPF" D 0 { A_SpidRefire(); }
		Goto Missile.T07.Psyche1;
	Pain.T07:
		"BSPF" I 2;
		"BSPF" I 2 { A_Pain(); }
		Goto See.T07.Chase;
	Death.T07:
		// Same inline-Crash handling as T05; CHP's chain is D then EFG/H.
		"BSPF" D 0 { bFLOATBOB = false; bFLOAT = false; bNOGRAVITY = false; }
		"BSPF" D 0 { A_Scream(); }
		"BSPF" D 6 { A_Fall(); }
		"BSPF" D 1 { A_BossDeath(); }
		"BSPF" EFG 6;
		"BSPF" H -1;
		Stop;
	XDeath.T07:
		Goto Death.T07;
	Raise.T07:
		"BSPF" HGFEDA 8;
		"BSPF" A 0 { bFLOATBOB = true; }
		Goto See.T07;

	// =================================================================
	// T08 BROWN (12_BR) -- ARAC, 915 HP. The Brown Recluse: every
	// attack opens by healing every monster within 320 units and
	// scattering medikits, then it either walks an orb volley across
	// the arena or dumps a 128-degree spam cone.
	// =================================================================
	Spawn.T08:
		"ARAC" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"ARAC" A 20;
	See.T08.Walk:
		"ARAC" A 0 { A_Chase(); }
		"ARAC" A 3 { A_StartSound("Aracknight/walk"); }
		"ARAC" ABBCC 3 { A_Chase(); }
		"ARAC" D 0 { A_Chase(); }
		"ARAC" D 3 { A_StartSound("Aracknight/walk"); }
		"ARAC" DEEFF 3 { A_Chase(); }
		Goto See.T08.Walk;
	Missile.T08:
		"ARAC" A 8 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_RadiusGive("Health", 320, RGF_MONSTERS, 200); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_MediCacoBrown", random(-164, 164), random(-164, 164), random(8, 64), random(1, 9), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		"ARAC" A 0 A_Jump(128, "Missile.T08.Special");
	Missile.T08.Orb:
		"ARAC" GG 2 Bright { A_SpawnProjectile("RS_BrownOrbSpiderCH", 32, 0, random(-1, 1)); }
		"ARAC" GG 2 Bright { A_SpawnProjectile("RS_BrownOrbSpiderCH", 32, 0, random(-7, -2)); }
		"ARAC" GH 2 Bright { A_SpawnProjectile("RS_BrownOrbSpiderCH", 32, 0, random(2, 7)); }
		"ARAC" HH 2 Bright { A_SpawnProjectile("RS_BrownOrbSpiderCH", 32, 0, random(-1, 1)); }
		Goto See;
	Missile.T08.Special:
		"ARAC" GGHH 1 Bright { A_SpawnProjectile("RS_BrownSpamSP", 32, 0, random(-64, 64)); }
		"ARAC" A 0 { A_FaceTarget(); }
		"ARAC" A 0 A_Jump(4, "Missile.T08.Orb");
		"ARAC" A 0 { A_SpidRefire(); }
		Goto Missile.T08.Special;
	Pain.T08:
		"ARAC" I 3;
		"ARAC" I 3 { A_Pain(); }
		Goto See.T08.Walk;
	Death.T08:
		"ARAC" J 20 { A_Scream(); }
		"ARAC" K 7 { A_NoBlocking(); }
		"ARAC" LMNO 7;
		"ARAC" P -1 { A_BossDeath(); }
		Stop;
	XDeath.T08:
		"ARAC" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"ARAC" J 20 { A_Scream(); }
		"ARAC" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		"ARAC" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ARAC" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARAC" P -1 { A_BossDeath(); }
		Stop;
	Raise.T08:
		"ARAC" PONMLKJ 5;
		Goto See.T08.Walk;

	// =================================================================
	// T09 GRAY (12_GY) -- CSPG, 600 HP. The Metal Spider: paints the
	// target with two vile-markers, then walks stone rockets onto it.
	// Inside 500 units it vents a spike spray instead.
	// =================================================================
	Spawn.T09:
		"CSPG" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"CSPG" A 20;
	See.T09.Walk:
		"CSPG" A 0 { A_Chase(); }
		"CSPG" A 3 { A_StartSound("baby/walk"); }
		"CSPG" ABBCC 3 { A_Chase(); }
		"CSPG" D 0 { A_Chase(); }
		"CSPG" D 3 { A_StartSound("baby/walk"); }
		"CSPG" DEEFF 3 { A_Chase(); }
		Goto See.T09.Walk;
	Missile.T09:
		"CSPG" A 0 A_JumpIfCloser(500, "Missile.T09.Scrap");
	Missile.T09.Rockets:
		"CSPG" A 8 Bright { A_FaceTarget(); }
		"CSPG" G 11 Bright { A_VileTarget("RS_CHBSTarget"); }
		"CSPG" G 11 Bright { A_FaceTarget(); }
		"CSPG" G 18 Bright { A_VileTarget("RS_CHBSTarget"); }
		"CSPG" GG 2 Bright { A_SpawnProjectile("RS_SpiderStoneRocket", 32, 0, random(-2, 2), 0, random(-1, 1)); }
		"CSPG" G 2 Bright { A_SpawnProjectile("RS_SpiderStoneRocket", 32, 0, 0); }
		"CSPG" H 2 Bright;
		Goto See;
	Missile.T09.Scrap:
		"CSPG" G 10 Bright { A_FaceTarget(); }
	Missile.T09.ScrapLoop:
		"CSPG" G 0 { A_FaceTarget(); }
		"CSPG" G 0 { A_StartSound("fire/fire3", 5); }
		"CSPG" GG 3 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 0, 24, random(12, 33), 0, random(1, 3), frandom(-9, 9)); }
		"CSPG" G 0 { A_FaceTarget(); }
		"CSPG" G 0 { A_StartSound("fire/fire3", 6); }
		"CSPG" GG 3 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 12, 0, 24, random(12, 33), 0, random(1, 3), frandom(-13, 13)); }
		"CSPG" A 0 A_JumpIfCloser(1000, "Missile.T09.ScrapRefire");
		Goto Missile.T09.Rockets;
	Missile.T09.ScrapRefire:
		"CSPG" H 0 { A_SpidRefire(); }
		Goto Missile.T09.ScrapLoop;
	Pain.T09:
		"CSPG" I 3;
		"CSPG" I 3 { A_Pain(); }
		Goto See.T09.Walk;
	Death.T09:
		"CSPG" J 20 { A_Scream(); }
		"CSPG" K 7 { A_NoBlocking(); }
		"CSPG" LMNO 7;
		"CSPG" P -1 { A_BossDeath(); }
		Stop;
	XDeath.T09:
		"CSPG" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"CSPG" J 20 { A_Scream(); }
		"CSPG" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"CSPG" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, 0, 21, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"CSPG" JI 4 { A_SpawnItemEx("RS_AraBoom2", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARA9" A -1 { A_BossDeath(); }
		Stop;
	Raise.T09:
		"CSPG" P 5;
		"CSPG" ONMLKJ 5;
		Goto See.T09.Walk;

	// =================================================================
	// T10 RED (12_R) -- BSP2, 1444 HP. Red Rage: goes NOPAIN the moment
	// it opens fire. Seeking bombs by default, twin fatso rockets on a
	// 64/256 roll -- and once it drops under 600 HP the rocket roll
	// jumps to 192/256.
	// =================================================================
	Spawn.T10:
		"BSP2" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"BSP2" A 20;
	See.T10.Walk:
		"BSP2" A 0 { bNOPAIN = false; }
		"BSP2" A 0 { A_Chase(); }
		"BSP2" A 3 { A_StartSound("baby/walk"); }
		"BSP2" ABBCC 3 { A_Chase(); }
		"BSP2" A 0 { A_Chase(); }
		"BSP2" D 3 { A_StartSound("baby/walk"); }
		"BSP2" DEEFF 3 { A_Chase(); }
		Goto See.T10.Walk;
	Missile.T10:
		"BSP2" A 20 Bright { A_FaceTarget(); }
		"BSP2" A 0 A_Jump(64, "Missile.T10.Rocketo");
		"BSP2" A 0 A_JumpIfHealthLower(600, "Missile.T10.Choice");
	Missile.T10.Bombs:
		"BSP2" A 5 Bright { bNOPAIN = true; }
	Missile.T10.BombLoop:
		"BSP2" G 2 Bright { A_SpawnProjectile("RS_RedBombSP", 20, -12, random(-30, 30)); }
		"BSP2" R 2 Bright;
		"BSP2" H 2 Bright { A_SpawnProjectile("RS_RedBombSP", 20, 12, random(-30, 30)); }
		"BSP2" Q 2 Bright { A_SpidRefire(); }
		Goto Missile.T10.BombLoop;
	Missile.T10.Choice:
		"BSP2" A 0 A_Jump(192, "Missile.T10.Rocketo");
		Goto Missile.T10.Bombs;
	Missile.T10.Rocketo:
		"BSP2" A 5 Bright { bNOPAIN = true; }
	Missile.T10.RocketLoop:
		"BSP2" G 5 Bright { A_SpawnProjectile("RS_RocketShotFatso", 20, -12, random(-2, 2)); }
		"BSP2" R 5 Bright { A_FaceTarget(); }
		"BSP2" H 5 Bright { A_SpawnProjectile("RS_RocketShotFatso", 20, 12, random(-2, 2)); }
		"BSP2" Q 6 Bright { A_FaceTarget(); }
		"BSP2" G 5 Bright { A_SpawnProjectile("RS_RocketShotFatso", 20, -12, random(-20, 20)); }
		"BSP2" R 5 Bright { A_FaceTarget(); }
		"BSP2" H 5 Bright { A_SpawnProjectile("RS_RocketShotFatso", 20, 12, random(-20, 20)); }
		"BSP2" Q 15 Bright { A_FaceTarget(); }
		"BSP2" Q 0 Bright { A_SpidRefire(); }
		Goto Missile.T10.RocketLoop;
	Pain.T10:
		"BSP2" I 3;
		"BSP2" I 3 { A_Pain(); }
		Goto See.T10.Walk;
	Death.T10:
		"BSP2" J 20 { A_Scream(); }
		"BSP2" K 7 { A_NoBlocking(); }
		"BSP2" LMN 5;
		"BSP2" O 5 { A_BossDeath(); }
		"BSP2" P -1;
		Stop;
	XDeath.T10:
		"BSP2" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 12, 26, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"BSP2" J 20 { A_Scream(); }
		"BSP2" JI 4 { A_SpawnItemEx("RS_HKRedDeath", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		"BSP2" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, -12, 24, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"BSP2" JI 4 { A_SpawnItemEx("RS_HKRedDeath", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARA5" A -1 { A_BossDeath(); }
		Stop;
	Raise.T10:
		"BSP2" PONMLKJ 5;
		Goto See.T10.Walk;

	// =================================================================
	// T11 BLACK (12_K) -- MSPI, 5342 HP. MACROSS MISSILE SPAM. Four
	// modes rolled evenly: a rocket duel, a six-tube broadside, the
	// hovering twenty-missile dump (this is the RS hover-barrage), and
	// a single cluster ball. Pain re-rolls straight back into an attack.
	// =================================================================
	Spawn.T11:
		"MSPI" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"MSPI" A 20;
	See.T11.Walk:
		"MSPI" A 0 { A_Chase(); }
		"MSPI" A 3 { A_StartSound("baby/walk"); }
		"MSPI" ABBCC 3 { A_Chase(); }
		"MSPI" A 0 { A_Chase(); }
		"MSPI" D 3 { A_StartSound("baby/walk"); }
		"MSPI" DEEFF 3 { A_Chase(); }
		Goto See.T11.Walk;
	Missile.T11:
		"MSPI" A 0 A_Jump(256, "Missile.T11.Miss1", "Missile.T11.Miss2", "Missile.T11.Miss3", "Missile.T11.Miss4");
		Goto See;
	Missile.T11.Miss1:
		"MSPI" A 20 Bright { A_FaceTarget(); }
	Missile.T11.Miss1Loop:
		"MSPI" G 2 Bright { A_SpawnProjectile("RS_SpRocket3", 19, -12, random(-2, 2)); }
		"MSPI" R 2 Bright { A_FaceTarget(); }
		"MSPI" H 2 Bright { A_SpawnProjectile("RS_SpRocket3", 19, 12, random(-6, 6)); }
		"MSPI" Q 2 Bright A_MonsterRefire(128, "See");
		"MSPI" Q 0 A_Jump(12, "Missile.T11.Miss3");
		Goto Missile.T11.Miss1Loop;
	Missile.T11.Miss2:
		"MSPI" A 6 Bright;
		"MSPI" Q 2 { A_FaceTarget(); }
		"MSPI" Q 9 { A_SpawnProjectile("RS_SpRocket4", 80, -34, random(-6, 6)); }
		"MSPI" Q 2 { A_FaceTarget(); }
		"MSPI" Q 9 { A_SpawnProjectile("RS_SpRocket4", 60, -64, random(-3, 9)); }
		"MSPI" Q 2 { A_FaceTarget(); }
		"MSPI" Q 9 { A_SpawnProjectile("RS_SpRocket4", 80, 34, random(-9, 3)); }
		"MSPI" Q 2 { A_FaceTarget(); }
		"MSPI" Q 9 { A_SpawnProjectile("RS_SpRocket4", 60, 64, random(-4, 7)); }
		"MSPI" Q 2 { A_FaceTarget(); }
		"MSPI" Q 0 { A_SpawnProjectile("RS_SpRocket4", 90, -14, random(-2, 2)); }
		"MSPI" Q 9 { A_SpawnProjectile("RS_SpRocket4", 90, 14, random(-2, 2)); }
		Goto See;
	Missile.T11.Miss3:
		"MSPI" A 10 Bright { A_FaceTarget(); }
		// CHP: ThrustThingZ(0,100,0,0) -- set vertical velocity to 12.5.
		// This is the arachnotron hover-barrage: lift off, stop
		// flinching, unload twenty missiles.
		"MSPI" I 8 Bright { vel.z = 12.5; }
		"MSPI" I 0 { RS_HoverBarrage(); }
		"MSPI" I 0 { bNOPAIN = true; }
		"MSPI" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-23, 23)); }
		"MSPI" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 25, -25, random(-41, 41)); }
		"MSPI" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 19, 12, random(-16, 16)); }
		"MSPI" Q 1 Bright { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"MSPI" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-22, 22)); }
		"MSPI" R 1 Bright { A_SpawnProjectile("RS_SPMM5", 49, 32, random(-9, 41)); }
		"MSPI" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 19, 12, random(-61, 6)); }
		"MSPI" Q 1 Bright { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"MSPI" G 1 Bright { A_SpawnProjectile("RS_SPMM3", 39, -32, random(-22, 22)); }
		"MSPI" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 19, -12, random(-34, 34)); }
		"MSPI" H 1 Bright { A_SpawnProjectile("RS_SPMM4", 29, 12, random(-16, 16)); }
		"MSPI" Q 1 Bright { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"MSPI" G 1 Bright { A_SpawnProjectile("RS_SPMM2", 19, -12, random(-22, 22)); }
		"MSPI" R 1 Bright { A_SpawnProjectile("RS_SPMM5", 59, -12, random(-14, 14)); }
		"MSPI" H 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, 32, random(-61, 61)); }
		"MSPI" Q 1 Bright { A_SpawnProjectile("RS_SPMM3", 19, 22, random(-39, 39)); }
		"MSPI" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-12, 12)); }
		"MSPI" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 26, -52, random(-4, 9)); }
		"MSPI" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 1, 12, random(-16, 16)); }
		"MSPI" Q 1 Bright { A_SpawnProjectile("RS_SPMM2", 9, -42, random(-19, 19)); }
		"MSPI" A 0 { bFLOAT = false; }
		"MSPI" A 0 { bNOPAIN = false; }
		"MSPI" I 0 { bNOGRAVITY = false; }
		Goto See;
	Missile.T11.Miss4:
		"MSPI" A 9 { A_FaceTarget(); }
		"MSPI" I 8 { A_SpawnProjectile("RS_BBSP1", random(12, 80), random(-60, 60), random(-64, 64)); }
		Goto See;
	Pain.T11:
		"MSPI" I 3;
		"MSPI" I 3 { A_Pain(); }
		"MSPI" I 0 A_Jump(128, "Missile.T11.Miss4", "Missile.T11.Miss3");
		Goto See.T11.Walk;
	Death.T11:
		"MSPI" J 20 { A_Scream(); }
		"MSPI" K 9 { A_NoBlocking(); }
		"MSPI" LMN 8;
		"MSPI" O 9 { A_BossDeath(); }
		"MSPI" P -1;
		Stop;
	XDeath.T11:
		"MSPI" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 12, 26, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"MSPI" J 20 { A_Scream(); }
		"MSPI" JJIIJI 2 { A_SpawnItemEx("RS_HKRedDeath", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		"MSPI" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, -12, 24, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MSPI" JJIIJI 2 { A_SpawnItemEx("RS_HKRedDeath", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARA6" A -1 { A_BossDeath(); }
		Stop;

	// =================================================================
	// T12 WHITE (12_W) -- TRIT, 10000 HP. THE WHITE SPIDER. Six attack
	// patterns while healthy; under 4000 HP the pool widens to eight and
	// it starts laying eggs. Every pattern can chain into a web shot.
	// =================================================================
	Spawn.T12:
		"TRIT" A 0 { A_SetSize(80, 64, true); }
	Spawn.T12.Look:
		"TRIT" AB 10 { A_Look(); }
		Loop;
	See.T12:
		TNT1 A 0 { bFLOAT = false; bNOGRAVITY = false; bNOPAIN = false; }
		"TRIT" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T12:
		"TRIT" A 0 A_JumpIfHealthLower(4000, "Missile.T12.Set2");
		"TRIT" A 0 A_Jump(256, "Missile.T12.Atk1", "Missile.T12.Atk2", "Missile.T12.Web", "Missile.T12.Atk5", "Missile.T12.Atk6", "Missile.T12.Atk7");
		Goto See;
	Missile.T12.Set2:
		"TRIT" A 0 A_Jump(256, "Missile.T12.Atk1", "Missile.T12.Atk2", "Missile.T12.Atk3", "Missile.T12.Web", "Missile.T12.Atk5", "Missile.T12.Atk6", "Missile.T12.Atk7", "Missile.T12.Atk8");
		Goto See;
	Missile.T12.Web:
		"TRIT" A 12 Bright;
		"TRIT" E 12 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 42, 0, random(-1, 1)); }
		"TRIT" E 12 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 42, 0, randompick(-18, -12, 12, 18)); }
		"TRIT" F 12 Bright { A_FaceTarget(); }
		"TRIT" A 12 Bright;
		Goto See;
	Missile.T12.Atk1:
		"TRIT" A 2 Bright { A_FaceTarget(); }
		// CHP lifts off here (FLOAT/NOGRAVITY/NOPAIN + ThrustThingZ 40)
		// -- the RS hover-barrage, spelled out.
		"TRIT" I 0 { RS_HoverBarrage(); }
		"TRIT" I 0 { bNOPAIN = true; }
		"TRIT" A 1 Bright { vel.z = 5.0; }
		"TRIT" A 1 Bright { Thrust(32.0, angle); }
		"TRIT" EF 8 Bright;
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(3, 12)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-12, -3)); }
		"TRIT" F 20 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(3, 12)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-12, -3)); }
		"TRIT" I 0 { bFLOAT = false; }
		"TRIT" I 0 { bNOGRAVITY = false; }
		"TRIT" F 24 Bright { bNOPAIN = false; }
		TNT1 A 0 A_Jump(64, "Missile.T12.Web");
		Goto See;
	Missile.T12.Atk2:
		TNT1 A 0 A_JumpIfCloser(400, "Missile.T12.Atk4", true);
		"TRIT" A 12 Bright;
		"TRIT" E 12 Bright { A_FaceTarget(); }
		"TRIT" E 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 255, 255), RGF_FULLBRIGHT | RGF_SILENT, 0, 0, "RS_RedDotSGPuff", 0, 0, 0, 15, 0.5, 0.5, "RS_NothinPuff", -12); }
		"TRIT" E 12 Bright { A_StartSound("SHARPST1", 7, 0, 2.0, ATTN_NONE); }
		"TRIT" E 12 Bright { A_FaceTarget(); }
		"TRIT" E 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 255, 255), RGF_FULLBRIGHT | RGF_SILENT, 0, 0, "RS_RedDotSGPuff", 0, 0, 0, 15, 0.5, 0.5, "RS_NothinPuff", -12); }
		"TRIT" E 12 Bright { A_CustomRailgun(0, 0, 0, Color(255, 255, 255), RGF_FULLBRIGHT | RGF_SILENT, 0, 0, "RS_RedDotSGPuff", 0, 0, 0, 15, 0.5, 0.5, "RS_NothinPuff", -12); }
		"TRIT" E 0 { A_StartSound("weapons/railgf"); }
		"TRIT" E 12 Bright { A_CustomRailgun(random(40, 90), 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_WhiteFatRB", 0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB2", 0); }
		TNT1 A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"TRIT" EE 16 Bright;
		"TRIT" A 2 Bright { A_StartSound("kawai/sight", 0); }
		Goto See;
	Missile.T12.Atk3:
		TNT1 A 0 { bNOPAIN = true; }
		TNT1 A 0 { A_SetSpeed(45); }
		"TRIT" AAA 3 Bright { A_Wander(); }
		"TRIT" AAAAAAAAAA 1 Bright { A_Wander(); }
		"TRIT" E 1 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_PainAttack("RS_WhiteSpidegg"); }
		"TRIT" AAA 3 Bright { A_Wander(); }
		"TRIT" AAAAAAAAAA 1 Bright { A_Wander(); }
		"TRIT" F 1 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_PainAttack("RS_WhiteSpidegg"); }
		"TRIT" F 3 Bright;
		"TRIT" F 1 Bright { A_PainAttack("RS_WhiteSpidegg"); }
		"TRIT" AAA 3 Bright { A_Wander(); }
		"TRIT" AAAAAAAAAA 1 Bright { A_Wander(); }
		TNT1 A 0 { A_SetSpeed(28); }
		TNT1 A 0 { bNOPAIN = false; }
		Goto See;
	Missile.T12.Atk4:
		"TRIT" A 12 Bright;
		"TRIT" E 17 Bright { A_FaceTarget(); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall1", 40, 0, random(-10, 10), 2, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall2", 40, 0, random(-10, 10), 2, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall3", 40, 0, random(-10, 10), 2, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall4", 40, 0, random(-10, 10), 2, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall5", 40, 0, random(-10, 10), 2, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall1", 40, 0, random(-12, -10), 2, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall2", 40, 0, random(-10, -8), 2, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall3", 40, 0, random(-10, 10), 2, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall4", 40, 0, random(8, 10), 2, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall5", 40, 0, random(10, 12), 2, random(13, 30)); }
		"TRIT" F 12 Bright { A_FaceTarget(); }
		"TRIT" A 12 Bright;
		TNT1 A 0 A_Jump(64, "Missile.T12.Web");
		Goto See;
	Missile.T12.Atk5:
		"TRIT" E 8 Bright;
		"TRIT" F 8 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-5, 5)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-7, 7)); }
		TNT1 A 0 A_Jump(64, "Missile.T12.Web");
		"TRIT" F 20 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-2, 2)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-2, 2)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		TNT1 A 0 A_Jump(64, "Missile.T12.Web");
		Goto See;
	Missile.T12.Atk6:
		"TRIT" E 8 Bright;
		"TRIT" F 12 Bright { A_FaceTarget(); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -15); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 15); }
		TNT1 A 0 A_Jump(64, "Missile.T12.Web", "Missile.T12.Atk7");
		Goto See;
	Missile.T12.Atk7:
		"TRIT" E 8 Bright;
		"TRIT" F 12 Bright { A_FaceTarget(); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 15); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -15); }
		TNT1 A 0 A_Jump(64, "Missile.T12.Web", "Missile.T12.Atk6");
		Goto See;
	Missile.T12.Atk8:
		"TRIT" A 12 Bright;
		"TRIT" E 17 Bright { A_FaceTarget(); }
		"TRIT" F 0 { A_SpawnProjectile("RS_WhiteSpiderHomer", 28, 0, 0); }
		"TRIT" F 12 Bright { A_FaceTarget(); }
		"TRIT" A 12 Bright;
		Goto See;
	Pain.T12:
		"TRIT" F 3;
		"TRIT" F 6 { A_Pain(); }
		Goto See;
	Death.T12:
		"TRIT" G 12 { A_ScreamAndUnblock(); }
		"TRIT" HIJ 10;
		"TRIT" H 0 { A_BossDeath(); }
		MISL XYZ 10;
		TNT1 A -1;
		Stop;
	XDeath.T12:
		Goto Death.T12;

	// =================================================================
	// TEX BLACK EX (12_KX) -- KSPX, 12000 HP. "MACROSS MISSILE SPAM EX".
	// Four patterns while healthy. Below 7000 HP the pool does not widen
	// the way the other bosses' do -- it SWAPS. Miss2/3/4 leave the roll
	// entirely and Miss6/7/8/9 take their place, so the second half is a
	// different fight rather than the same fight with extras. Miss1 is
	// the only pattern present in both halves, and it is the one that can
	// bail into the hover dump at either stage.
	// =================================================================
	Spawn.TEX:
		"KSPX" A 0 { A_SetSize(56, 64, true); }
	Spawn.TEX.Look:
		"KSPX" AB 10 { A_Look(); }
		Loop;
	See.TEX:
		"KSPX" A 20;
	See.TEX.Walk:
		"KSPX" A 0 { A_Chase(); }
		"KSPX" A 2 { A_StartSound("baby/walk"); }
		"KSPX" ABBCC 2 { A_Chase(); }
		"KSPX" A 0 { A_Chase(); }
		"KSPX" D 2 { A_StartSound("baby/walk"); }
		"KSPX" DEEFF 2 { A_Chase(); }
		Goto See.TEX.Walk;
	Missile.TEX:
		"KSPX" A 0 A_JumpIfHealthLower(7000, "Missile.TEX.ChoicesMore");
		"KSPX" A 0 A_Jump(256, "Missile.TEX.Miss1", "Missile.TEX.Miss2", "Missile.TEX.Miss3", "Missile.TEX.Miss4");
		Goto See;
	// THE GATE. 7000 of 12000 -- a hair under 60%, so it flips early.
	Missile.TEX.ChoicesMore:
		"KSPX" A 0 A_Jump(256, "Missile.TEX.Miss1", "Missile.TEX.Miss6", "Missile.TEX.Miss7", "Missile.TEX.Miss8", "Missile.TEX.Miss9");
		Goto See;
	// Miss1 -- the laser duel. Sheds an afterimage, alternates shoulders,
	// and re-rolls on A_MonsterRefire; a 12/256 chance per cycle to break
	// off into the hover dump.
	Missile.TEX.Miss1:
		"KSPX" A 20 Bright { A_FaceTarget(); }
	Missile.TEX.Miss1Loop:
		TNT1 A 0 { A_SpawnItemEx("RS_BlackSpideEXShade", 0, 0, random(12, 24), random(-1, 1), 0, random(-1, 1), random(160, 200), SXF_NOCHECKPOSITION); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_ExSpideLaser1", 24, -12, random(-5, 5)); }
		"KSPX" R 1 Bright { A_FaceTarget(); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_ExSpideLaser1", 24, 12, random(-5, 5)); }
		"KSPX" R 1 Bright A_MonsterRefire(128, "See");
		"KSPX" Q 0 A_Jump(12, "Missile.TEX.Miss3");
		Goto Missile.TEX.Miss1Loop;
	// Miss2 -- the broadside. Eleven dumb rockets walked out to +-86
	// degrees, then six seekers straight down the middle.
	Missile.TEX.Miss2:
		"KSPX" A 6 Bright { A_FaceTarget(); }
		"KSPX" Q 2 Bright { A_FaceTarget(); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, -34, random(-6, 6)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 80, -14, random(-6, 6)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 90, 0, random(-6, 6)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 80, 14, random(-6, 6)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, 34, random(-6, 6)); }
		"KSPX" Q 4 Bright { A_FaceTarget(); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, -58, random(-3, 9)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, -78, random(-3, 9)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, -86, random(-3, 9)); }
		"KSPX" Q 4 Bright { A_FaceTarget(); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, 58, random(-9, 3)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, 78, random(-9, 3)); }
		"KSPX" Q 2 Bright { A_SpawnProjectile("RS_SpRocket4", 60, 86, random(-9, 3)); }
		"KSPX" QQ 6 Bright { A_FaceTarget(); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SpRocket4EX", 80, -24, random(-2, 2)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SpRocket4EX", 80, 24, random(-2, 2)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SpRocket4EX", 60, -24, random(-2, 2)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SpRocket4EX", 60, 24, random(-2, 2)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SpRocket4EX", 70, -20, random(-2, 2)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SpRocket4EX", 70, 20, random(-2, 2)); }
		"KSPX" Q 12;
		Goto See;
	// Miss3 -- THE HOVER DUMP, and the reason this thing is called Macross
	// Missile Spam. Lifts off, stops flinching, and empties thirty-four
	// missiles in about two and a half seconds. Same RS hover-barrage the
	// T11 spider uses, at nearly double the payload.
	Missile.TEX.Miss3:
		"KSPX" A 10 Bright { A_FaceTarget(); }
		// CHP: ThrustThingZ(0,100,0,0) -- set vertical velocity to 12.5.
		"KSPX" I 8 Bright { vel.z = 12.5; }
		"KSPX" I 0 { RS_HoverBarrage(); }
		"KSPX" I 0 { bNOPAIN = true; }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-23, 23)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 25, -25, random(-41, 41)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 19, 12, random(-16, 16)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-22, 22)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM5", 49, 32, random(-9, 41)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 19, 12, random(-61, 6)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM3", 39, -32, random(-22, 22)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 19, -12, random(-34, 34)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM4", 29, 12, random(-16, 16)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM2", 19, -12, random(-22, 22)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM5", 59, -12, random(-14, 14)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, 32, random(-61, 61)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM3", 19, 22, random(-39, 39)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-12, 12)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 26, -52, random(-4, 9)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 1, 12, random(-16, 16)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM2", 9, -42, random(-19, 19)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-23, 23)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 25, -25, random(-41, 41)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 19, 12, random(-16, 16)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM1", 19, -12, random(-22, 22)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM5", 49, 32, random(-9, 41)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM3", 19, 12, random(-61, 6)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM3", 39, -32, random(-22, 22)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM2", 19, -12, random(-34, 34)); }
		"KSPX" H 1 Bright { A_SpawnProjectile("RS_SPMM4", 29, 12, random(-16, 16)); }
		"KSPX" Q 0 { A_SpawnProjectile("RS_SPMM4", 19, 12, random(-9, 9)); }
		"KSPX" G 1 Bright { A_SpawnProjectile("RS_SPMM2", 19, -12, random(-22, 22)); }
		"KSPX" R 1 Bright { A_SpawnProjectile("RS_SPMM5", 59, -12, random(-14, 14)); }
		"KSPX" A 0 { bFLOAT = false; }
		"KSPX" A 0 { bNOPAIN = false; }
		"KSPX" I 0 { bNOGRAVITY = false; }
		Goto See;
	// Miss4 -- three bubblegum cluster bombs, thrown high, mid and low.
	Missile.TEX.Miss4:
		"KSPX" AG 9 { A_FaceTarget(); }
		"KSPX" I 8 { A_SpawnProjectile("RS_BubblegumBombEXSpidie", random(34, 50), random(-40, 40), random(-18, -4)); }
		"KSPX" I 8 { A_SpawnProjectile("RS_BubblegumBombEXSpidie", random(34, 50), random(-40, 40), 0); }
		"KSPX" I 8 { A_SpawnProjectile("RS_BubblegumBombEXSpidie", random(34, 50), random(-40, 40), random(4, 18)); }
		Goto See;
	// Miss6 -- second-half seeker duel: three seekers per shoulder, over
	// and over, with a 15/256 bail into the hover dump after each triple.
	Missile.TEX.Miss6:
		"KSPX" A 20 Bright { A_FaceTarget(); }
	Missile.TEX.Miss6Loop:
		"KSPX" G 2 Bright { A_FaceTarget(); }
		"KSPX" G 0 { A_SpawnProjectile("RS_SpRocket4EX", 80, -14, random(-2, 2)); }
		"KSPX" G 0 { A_SpawnProjectile("RS_SpRocket4EX", 60, -14, random(-2, 2)); }
		"KSPX" G 0 { A_SpawnProjectile("RS_SpRocket4EX", 70, -10, random(-2, 2)); }
		"KSPX" G 2 Bright A_Jump(15, "Missile.TEX.Miss3");
		"KSPX" HG 4 Bright { A_FaceTarget(); }
		"KSPX" H 0 { A_SpawnProjectile("RS_SpRocket4EX", 80, 14, random(-2, 2)); }
		"KSPX" H 0 { A_SpawnProjectile("RS_SpRocket4EX", 60, 14, random(-2, 2)); }
		"KSPX" H 0 { A_SpawnProjectile("RS_SpRocket4EX", 70, 10, random(-2, 2)); }
		"KSPX" H 2 Bright A_Jump(15, "Missile.TEX.Miss3");
		"KSPX" H 2 Bright A_MonsterRefire(128, "See");
		Goto Missile.TEX.Miss6Loop;
	// Miss7 -- the spiral shot. One projectile, but it corkscrews.
	Missile.TEX.Miss7:
		"KSPX" A 10 Bright { A_FaceTarget(); }
		"KSPX" G 6 Bright { A_FaceTarget(); }
		"KSPX" R 6 Bright { A_SpawnProjectile("RS_BlackSpideSpiralShot", 32, 0, 0); }
		"KSPX" HQ 6 Bright;
		"KSPX" Q 0 A_Jump(128, "Missile.TEX.Miss3");
		Goto See;
	// Miss8 -- the sweep. Six magenta rails, then twelve bombs at close
	// spread. CHP gives the rails damage 0 on purpose: they are the tell
	// that tracks you across the room, and the bombs are the payload.
	// Half the time it does not commit and re-rolls the first-half pool.
	Missile.TEX.Miss8:
		"KSPX" A 0 A_Jump(128, "Missile.TEX.Miss1", "Missile.TEX.Miss2", "Missile.TEX.Miss3", "Missile.TEX.Miss4");
		"KSPX" A 10 Bright { A_FaceTarget(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BlackSpideEXShade", 0, 0, random(12, 24), random(-1, 1), 0, random(-1, 1), random(160, 200), SXF_NOCHECKPOSITION); }
		"KSPX" G 2 Bright { A_FaceTarget(); }
		"KSPX" R 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 0, 255), RGF_NOPIERCING | RGF_SILENT); }
		"KSPX" A 0 { A_FaceTarget(); }
		"KSPX" H 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 0, 255), RGF_NOPIERCING | RGF_SILENT); }
		"KSPX" A 0 { A_FaceTarget(); }
		"KSPX" Q 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 0, 255), RGF_NOPIERCING | RGF_SILENT); }
		"KSPX" A 0 { A_FaceTarget(); }
		"KSPX" R 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 0, 255), RGF_NOPIERCING | RGF_SILENT); }
		"KSPX" A 0 { A_FaceTarget(); }
		"KSPX" H 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 0, 255), RGF_NOPIERCING | RGF_SILENT); }
		"KSPX" A 0 { A_FaceTarget(); }
		"KSPX" Q 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 0, 255), RGF_NOPIERCING | RGF_SILENT); }
		"KSPX" GGGGGGGGGGGG 2 Bright { A_SpawnProjectile("RS_BubblegumBombEXSpidie", random(34, 50), random(-10, 10), random(-3, 3)); }
		Goto See;
	// Miss9 -- the wall. Eight seekers and sixteen lasers in one frame,
	// fanned +-40 degrees. No aiming, just volume.
	Missile.TEX.Miss9:
		"KSPX" A 10 Bright { A_FaceTarget(); }
		"KSPX" G 2 Bright;
		"KSPX" GGGG 0 { A_SpawnProjectile("RS_SpRocket4EX", 60, 15, random(-40, 40)); }
		"KSPX" GGGG 0 { A_SpawnProjectile("RS_SpRocket4EX", 60, -15, random(-40, 40)); }
		"KSPX" GGGGGGGG 0 { A_SpawnProjectile("RS_ExSpideLaser1", 24, 12, random(-40, 40)); }
		"KSPX" GGGGGGGG 0 { A_SpawnProjectile("RS_ExSpideLaser1", 24, -12, random(-40, 40)); }
		"KSPX" G 8 Bright { A_FaceTarget(); }
		"KSPX" R 4 Bright { A_FaceTarget(); }
		"KSPX" H 2 Bright;
		Goto See;
	// Pain re-rolls straight back into an attack half the time -- flinching
	// it is not a free window.
	Pain.TEX:
		"KSPX" I 3;
		"KSPX" I 3 { A_Pain(); }
		"KSPX" I 0 A_Jump(128, "Missile.TEX");
		Goto See.TEX.Walk;
	Death.TEX:
		"KSPX" J 20 { A_Scream(); }
		"KSPX" K 9 { A_NoBlocking(); }
		"KSPX" LMN 8;
		"KSPX" O 9 { A_BossDeath(); }
		"KSPX" P -1;
		Stop;
	XDeath.TEX:
		"KSPX" J 1 { A_SpawnItemEx("RS_AraBoom3", 0, 12, 26, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		"KSPX" J 20 { A_Scream(); }
		"KSPX" JJIIJI 2 { A_SpawnItemEx("RS_HKRedDeath", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		"KSPX" I 4 { A_SpawnItemEx("RS_AraBoom3", 0, -12, 24, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"KSPX" JJIIJI 2 { A_SpawnItemEx("RS_HKRedDeath", random(-5, 5), random(-32, 32), random(2, 42), 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		TNT1 A 8 { A_SpawnItemEx("RS_AraBoom1", 0, 0, 30, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		TNT1 AAAAAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 A 3 { A_NoBlocking(); }
		"ARA7" A -1 { A_BossDeath(); }
		Stop;

	// =================================================================
	// T14 WHITE EX (12_WX) -- WSPX, 9500 HP. THE WHITE HOT SPIDER.
	// The only arachnotron whose pattern is chosen by RANGE rather than
	// by a flat roll: inside 250 it leans on webs, inside 2000 it opens
	// the full midrange pool, beyond that it only has the long shots.
	// It walks in a trail of fire, dodges and hops between attacks, and
	// most patterns begin by LIFTING OFF (the RS hover-barrage) and end
	// by landing again through Getdown.
	//
	// THE GATE: KRAKATOA is in the midrange roll from the start but
	// refuses to fire above 5000 HP -- it bounces straight back into
	// Basic. So the second half of the fight is not a wider roll, it is
	// the same roll finally being allowed to land its biggest attack.
	// =================================================================
	Spawn.T14:
		"WSPX" A 0 { A_SetSize(56, 64, true); }
	Spawn.T14.Look:
		"WSPX" AB 10 { A_Look(); }
		Loop;
	See.T14:
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCD 2 { A_Chase(); }
		"WSPX" A 0 A_Jump(25, "See.T14.Dodger");
		Loop;
	See.T14.Dodger:
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCD 2 { A_FastChase(); }
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCD 2 { A_FastChase(); }
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCD 2 { A_FastChase(); }
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCD 2 { A_FastChase(); }
		"WSPX" A 0 A_Jump(100, "See.T14.Jumpy");
		Goto See;
	// The hop: a backwards leap at a randomised angle, then a forward one.
	See.T14.Jumpy:
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" A 2 { A_FastChase(); }
		"WSPX" B 1 { vel.z = 10.0; }
		"WSPX" B 1 { Thrust(40.0, angle - randompick(130, 180, 230)); }
		"WSPX" C 2;
		"WSPX" D 1 { vel.z = 5.0; }
		"WSPX" D 1 { Thrust(40.0, angle); }
		Goto See;
	Melee.T14:
	Missile.T14:
		"WSPX" C 0 { A_StartSound("WSPEXATK"); }
		"WSPX" C 0 A_JumpIfCloser(250, "Missile.T14.CloseShot");
		"WSPX" C 0 A_JumpIfCloser(2000, "Missile.T14.Midrange");
		Goto Missile.T14.FarShot;
	Missile.T14.Midrange:
		"WSPX" C 0 A_Jump(96, "Missile.T14.Basic");
		"WSPX" C 0 A_Jump(64, "Missile.T14.Spiders");
		"WSPX" C 0 A_Jump(256, "Missile.T14.Flares", "Missile.T14.FireBombs", "Missile.T14.FlameBlast", "Missile.T14.Spiders", "Missile.T14.Webs", "Missile.T14.Krakatoa");
		Goto See;
	Missile.T14.CloseShot:
		"WSPX" C 0 A_Jump(150, "Missile.T14.Webs");
		Goto Missile.T14.Midrange;
	Missile.T14.FarShot:
		"WSPX" C 0 A_Jump(150, "Missile.T14.FlameBlast", "Missile.T14.Flares");
		"WSPX" C 0 A_Jump(256, "Missile.T14.Spiders", "Missile.T14.Krakatoa");
	// Landing. Every lift-off pattern comes back through here.
	Missile.T14.Getdown:
		"WSPX" C 0 { bFLOAT = false; bNOGRAVITY = false; }
		"WSPX" C 12 Bright { bNOPAIN = false; }
		"WSPX" C 0 A_Jump(96, "Missile.T14.Spiders");
		Goto See;
	Missile.T14.Basic:
		"WSPX" C 2 Bright { A_FaceTarget(); }
		// CHP lifts off here (FLOAT/NOGRAVITY/NOPAIN + ThrustThingZ 40 and a
		// forward shove) -- the RS hover-barrage, spelled out.
		"WSPX" C 0 { RS_HoverBarrage(); }
		"WSPX" C 0 { bNOPAIN = true; }
		"WSPX" C 1 Bright { vel.z = 5.0; }
		"WSPX" C 1 Bright { Thrust(32.0, angle); }
		"WSPX" CF 8 Bright { A_FaceTarget(); }
		"WSPX" F 0 A_Jump(256, "Missile.T14.Basic1", "Missile.T14.Basic2", "Missile.T14.Basic4");
	Missile.T14.Basic1:
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-1, 1)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-12, 12)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(3, 12)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-3, 3)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-12, -3)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-3, 3)); }
		"WSPX" CC 8 Bright { A_FaceTarget(); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-1, 1)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-12, 12)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(3, 12)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-3, 3)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-12, -3)); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, random(-3, 3)); }
		"WSPX" F 0 A_Jump(160, "Missile.T14.Basic2", "Missile.T14.Basic3", "Missile.T14.Basic4");
		Goto Missile.T14.Getdown;
	// Twenty bolts in one frame: three stacked rows at pitch +2 / -2 / 0.
	Missile.T14.Basic2:
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 23, CMF_AIMOFFSET, 2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -23, CMF_AIMOFFSET, 2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 12, CMF_AIMOFFSET, 2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -12, CMF_AIMOFFSET, 2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 5, CMF_AIMOFFSET, 2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -5, CMF_AIMOFFSET, 2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 0, CMF_AIMOFFSET, 2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 23, CMF_AIMOFFSET, -2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -23, CMF_AIMOFFSET, -2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 12, CMF_AIMOFFSET, -2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -12, CMF_AIMOFFSET, -2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 5, CMF_AIMOFFSET, -2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -5, CMF_AIMOFFSET, -2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 0, CMF_AIMOFFSET, -2); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 29); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -29); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 15); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -15); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 6); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -6); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 0); }
		"WSPX" F 0 A_Jump(160, "Missile.T14.Basic3");
		Goto Missile.T14.Getdown;
	Missile.T14.Basic3:
		"WSPX" CC 8 Bright { A_FaceTarget(); }
		"WSPX" F 0 A_CheckSight("Missile.T14.Getdown");
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 22, 10, 0); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 22, -10, 0); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 62, 10, 0); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 62, -10, 0); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, 20, 0); }
		"WSPX" F 0 { A_SpawnProjectile("RS_BoilBoltL9", 42, -20, 0); }
		"WSPX" F 2 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 0); }
		Goto Missile.T14.Getdown;
	Missile.T14.Basic4B:
		"WSPX" AA 8 Bright { A_FaceTarget(); }
	// The sweep, left to right; Basic5 is the same thing backwards and the
	// two can chain into each other indefinitely.
	Missile.T14.Basic4:
		"WSPX" F 0 A_CheckSight("Missile.T14.Getdown");
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -15); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -11); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -7); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -3); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -1); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 1); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 3); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 7); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 11); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 15); }
		"WSPX" F 0 A_Jump(160, "Missile.T14.Basic5");
		Goto Missile.T14.Getdown;
	Missile.T14.Basic5:
		"WSPX" CC 8 Bright { A_FaceTarget(); }
		"WSPX" F 0 A_CheckSight("Missile.T14.Getdown");
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 15); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 11); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 7); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 3); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, 1); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -1); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -3); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -7); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -11); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_BoilBoltL9", 42, 0, -15); }
		"WSPX" F 0 A_Jump(96, "Missile.T14.Basic4B");
		Goto Missile.T14.Getdown;
	// Flares: scattered from the shoulders, re-firing on A_SpidRefire, so it
	// keeps going for as long as it can see you.
	Missile.T14.Flares:
		"WSPX" C 8 Bright { A_FaceTarget(); }
	Missile.T14.FlaresLoop:
		"WSPX" E 2 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-1, 1)); }
		"WSPX" EE 1 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-8, 8)); }
		"WSPX" C 4 Bright { A_FaceTarget(); }
		"WSPX" EE 1 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-20, 20)); }
		"WSPX" E 2 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-1, 1)); }
		"WSPX" EE 1 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-8, 8)); }
		"WSPX" EE 1 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-20, 20)); }
		"WSPX" C 4 Bright { A_FaceTarget(); }
		"WSPX" E 2 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-1, 1)); }
		"WSPX" EE 1 Bright { A_SpawnProjectile("RS_WhiteHotFlareL9", 42, random(-24, 24), random(-20, 20)); }
		"WSPX" C 8 Bright { A_FaceTarget(); }
		"WSPX" C 0 A_Jump(32, "Missile.T14.Webs");
		"WSPX" C 0 { A_SpidRefire(); }
		Goto Missile.T14.FlaresLoop;
	// Firebombs: lobbed with pitch, so they arc over cover.
	Missile.T14.FireBombs:
		"WSPX" C 8 Bright { A_FaceTarget(); }
	Missile.T14.FireBombsLoop:
		"WSPX" EEE 0 { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-9, 9), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" EE 2 Bright { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-30, 30), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" C 4 Bright { A_FaceTarget(); }
		"WSPX" EEE 0 { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-9, 9), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" EE 2 Bright { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-30, 30), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" EEE 0 { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-9, 9), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" EE 2 Bright { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-30, 30), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" C 4 Bright { A_FaceTarget(); }
		"WSPX" EEE 0 { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-9, 9), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" EE 2 Bright { A_SpawnProjectile("RS_FireBombL9", random(32, 52), random(-24, 24), random(-30, 30), CMF_AIMOFFSET, random(-4, 28)); }
		"WSPX" C 8 Bright { A_FaceTarget(); }
		"WSPX" C 0 A_JumpIfCloser(2000, "Missile.T14.FireBombsAgain");
		Goto Missile.T14.FarShot;
	Missile.T14.FireBombsAgain:
		"WSPX" C 0 A_Jump(32, "Missile.T14.Webs");
		"WSPX" C 0 { A_SpidRefire(); }
		Goto Missile.T14.FireBombsLoop;
	Missile.T14.FlameBlast:
		"WSPX" C 8 Bright { A_FaceTarget(); }
		"WSPX" EEEEEEEE 2 Bright { A_SpawnProjectile("RS_HSFlameBlast", 42, 0, frandom(-2.0, 2.0)); }
		Goto See;
	Missile.T14.Spiders:
		"WSPX" C 8 Bright { A_FaceTarget(); }
		"WSPX" E 1 Bright { A_FaceTarget(); }
		"WSPX" E 5 Bright { A_SpawnProjectile("RS_SPWHIL9", 42, 0, random(-1, 1)); }
		"WSPX" E 0 { A_SpawnProjectile("RS_SPWHIL9", 42, 0, random(3, 12)); }
		"WSPX" E 0 { A_SpawnProjectile("RS_SPWHIL9", 42, 0, random(-12, -3)); }
		"WSPX" F 1 Bright { A_FaceTarget(); }
		"WSPX" F 5 Bright { A_SpawnProjectile("RS_SPWHIL9", 42, 0, random(-7, 7)); }
		"WSPX" F 3 Bright { A_SpawnProjectile("RS_SPWHIL9", 42, 0, random(-17, 17)); }
		"WSPX" F 1 Bright { A_SpawnProjectile("RS_SPWHIL9", 42, 0, random(-12, 12)); }
		"WSPX" F 0 A_Jump(96, "Missile.T14.Webs");
		Goto See;
	Missile.T14.Webs:
		"WSPX" C 2 Bright { A_FaceTarget(); }
		"WSPX" E 5 Bright { A_FaceTarget(); }
		"WSPX" EEE 2 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 42, 0, random(-1, 1)); }
		"WSPX" E 5 Bright { A_FaceTarget(); }
		"WSPX" EEE 2 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 42, 0, random(-20, 20)); }
		"WSPX" E 5 Bright { A_FaceTarget(); }
		"WSPX" EEE 2 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 42, 0, randompick(-18, -12, 12, 18)); }
		"WSPX" FC 6 Bright;
		"WSPX" C 0 A_Jump(192, "Missile.T14.Midrange");
		Goto See;
	// THE GATE -- 5000 of 9500. Above it, KRAKATOA refuses and falls back
	// to Basic; below it, the spider goes NOPAIN, opens two burning eyes as
	// the tell, and pours twenty krakatoa rounds downrange.
	Missile.T14.Krakatoa:
		"WSPX" C 0 A_JumpIfHealthLower(5000, "Missile.T14.KrakatoaGo");
		Goto Missile.T14.Basic;
	Missile.T14.KrakatoaGo:
		"WSPX" C 0 { bNOPAIN = true; }
		"WSPX" C 0 { A_StartSound("WSPEXATK", CHAN_BODY, 0, 1.0, ATTN_NONE); }
		"WSPX" C 10 { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("SPMDING", CHAN_5, 0, 1.0, ATTN_NONE); }
		TNT1 A 0 { A_SpawnItemEx("RS_SuperEye02", 4, 0, 28, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_SpawnItemEx("RS_SuperEye02", 4, -8, 28, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" CCCF 10 { A_FaceTarget(); }
		"WSPX" FFFFF 2 Bright { A_SpawnProjectile("RS_KrakatoaL9", 42, 0, 0); }
		"WSPX" F 0 { A_FaceTarget(); }
		"WSPX" FFFFF 2 Bright { A_SpawnProjectile("RS_KrakatoaL9", 42, 0, 0); }
		"WSPX" F 0 { A_FaceTarget(); }
		"WSPX" FFFFF 2 Bright { A_SpawnProjectile("RS_KrakatoaL9", 42, 0, 0); }
		"WSPX" F 0 { A_FaceTarget(); }
		"WSPX" FFFFF 2 Bright { A_SpawnProjectile("RS_KrakatoaL9", 42, 0, 0); }
		"WSPX" FC 10 { A_FaceTarget(); }
		"WSPX" C 0 { bNOPAIN = false; }
		Goto See;
	Pain.T14:
		"WSPX" C 3;
		"WSPX" C 3 { A_Pain(); }
		"WSPX" C 0 A_Jump(88, "Pain.T14.Woa");
		Goto See;
	// Fire barely registers on something made of it.
	Pain.T14.Fire:
		"WSPX" C 3 { A_StartSound("ResistCH", 7); }
		Goto See;
	// The flinch that turns into a retreat, and can end in a hop.
	Pain.T14.Woa:
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCDABCD 1 { A_Wander(); }
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCDABCD 1 { A_Wander(); }
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCDABCD 1 { A_Wander(); }
		"WSPX" A 0 { A_SpawnItemEx("RS_FlaminFireAL9", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"WSPX" ABCDABCD 1 { A_Wander(); }
		"WSPX" A 0 A_Jump(100, "See.T14.Jumpy");
		Goto See;
	Death.T14:
		TNT1 A 0 { A_SetScale(1.62, 1.125); }
		"WSPX" G 20 Bright { A_Scream(); }
		"WSPX" H 5 { A_Explode(50, 200); }
		"WSPX" IJKL 5 Bright { A_Explode(50, 200); }
		"WSPX" MN 5 { A_NoBlocking(false); }
		"WSPX" OOOO 8 { A_SpawnItemEx("RS_BigBadFire1", random(-120, 120), random(-120, 120)); }
		"WSPX" O 0 { A_NoBlocking(); }
		"WSPX" O -1;
		Stop;
	XDeath.T14:
		Goto Death.T14;

	// =================================================================
	// T15 WHITE 3 (12_W3) -- TRIT, 4000 HP. THE WHITE SPIDER OF TERROR.
	// CHP's CommonWhiteSpider3 is literally the next stage of T12's
	// CommonWhiteSpider2: same body, 4000 HP instead of 10000, and a
	// tightened kit. Four patterns while healthy.
	//
	// THE GATE: below 2500 HP it turns on MISSILEEVENMORE -- it stops
	// pausing between attacks entirely -- and the roll widens from four
	// to six, adding the charged railgun and the egg-laying run.
	// =================================================================
	Spawn.T15:
		"TRIT" A 0 { A_SetSize(56, 64, true); }
	Spawn.T15.Look:
		"TRIT" AB 10 { A_Look(); }
		Loop;
	See.T15:
		TNT1 A 0 { bFLOAT = false; bNOGRAVITY = false; bNOPAIN = false; }
		"TRIT" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T15:
		"TRIT" A 0 A_JumpIfHealthLower(2500, "Missile.T15.Set2");
		"TRIT" A 0 A_Jump(256, "Missile.T15.Atk1", "Missile.T15.Web", "Missile.T15.Atk567", "Missile.T15.Atk8");
		Goto See;
	Missile.T15.Set2:
		"TRIT" A 0 { bMISSILEEVENMORE = true; }
		"TRIT" A 0 A_Jump(256, "Missile.T15.Atk1", "Missile.T15.Atk2", "Missile.T15.Atk3", "Missile.T15.Web", "Missile.T15.Atk567", "Missile.T15.Atk8");
		Goto See;
	Missile.T15.Web:
		"TRIT" A 2 Bright;
		"TRIT" E 6 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 42, 0, random(-1, 1)); }
		"TRIT" E 6 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderWebShot", 42, 0, randompick(-18, -12, 12, 18)); }
		"TRIT" F 6 Bright { A_FaceTarget(); }
		"TRIT" A 6 Bright;
		TNT1 A 0 A_Jump(96, "Missile.T15.Atk8");
		Goto See;
	// The hover storm: twelve plasma bolts in two bursts while airborne.
	Missile.T15.Atk1:
		"TRIT" A 2 Bright { A_FaceTarget(); }
		"TRIT" I 0 { RS_HoverBarrage(); }
		"TRIT" I 0 { bNOPAIN = true; }
		"TRIT" A 1 Bright { vel.z = 5.0; }
		"TRIT" A 1 Bright { Thrust(32.0, angle); }
		"TRIT" EF 8 Bright;
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-12, 12)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(3, 12)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-12, -3)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" F 20 Bright { A_FaceTarget(); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-12, 12)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(3, 12)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-12, -3)); }
		"TRIT" E 3 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" I 0 { bFLOAT = false; bNOGRAVITY = false; }
		"TRIT" F 18 Bright { bNOPAIN = false; }
		TNT1 A 0 A_Jump(96, "Missile.T15.Web", "Missile.T15.Atk8");
		Goto See;
	// SET2 ONLY. Three aiming lasers, then the charged shot. At knife range
	// it abandons the wind-up and vents slime instead.
	Missile.T15.Atk2:
		TNT1 A 0 A_JumpIfCloser(400, "Missile.T15.Atk4", true);
		"TRIT" A 2 Bright;
		"TRIT" E 12 Bright { A_FaceTarget(); }
		"TRIT" E 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 255, 255), RGF_FULLBRIGHT | RGF_SILENT, 0, 0, "RS_RedDotSGPuff", 0, 0, 0, 15, 0.5, 0.5, "RS_NothinPuff", -12); }
		"TRIT" E 12 Bright { A_StartSound("SHARPST1", 7, 0, 2.0, ATTN_NONE); }
		"TRIT" E 12 Bright { A_FaceTarget(); }
		"TRIT" E 6 Bright { A_CustomRailgun(0, 0, 0, Color(255, 255, 255), RGF_FULLBRIGHT | RGF_SILENT, 0, 0, "RS_RedDotSGPuff", 0, 0, 0, 15, 0.5, 0.5, "RS_NothinPuff", -12); }
		"TRIT" E 12 Bright { A_CustomRailgun(0, 0, 0, Color(255, 255, 255), RGF_FULLBRIGHT | RGF_SILENT, 0, 0, "RS_RedDotSGPuff", 0, 0, 0, 15, 0.5, 0.5, "RS_NothinPuff", -12); }
		"TRIT" E 0 { A_StartSound("weapons/railgf"); }
		"TRIT" E 12 Bright { A_CustomRailgun(random(40, 90), 0, Color(255, 255, 255), Color(255, 255, 255), RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_WhiteFatRB", 0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB2", 0); }
		TNT1 A 0 { A_SpawnItemEx("RS_AbyssSPShoot", 12, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"TRIT" EE 16 Bright;
		"TRIT" A 2 Bright { A_StartSound("kawai/sight", 0); }
		Goto See;
	// SET2 ONLY. The egg run: NOPAIN, speed 60, wander, lay, repeat.
	Missile.T15.Atk3:
		TNT1 A 0 { bNOPAIN = true; }
		TNT1 A 0 { A_SetSpeed(60); }
		"TRIT" AAA 3 Bright { A_Wander(); }
		"TRIT" AAAAAAAAAA 1 Bright { A_Wander(); }
		"TRIT" E 1 Bright { A_FaceTarget(); }
		"TRIT" EEE 2 Bright { A_PainAttack("RS_WhiteSpidegg"); }
		"TRIT" AAA 3 Bright { A_Wander(); }
		"TRIT" AAAAAAAAAA 1 Bright { A_Wander(); }
		"TRIT" F 1 Bright { A_FaceTarget(); }
		"TRIT" EEE 2 Bright { A_PainAttack("RS_WhiteSpidegg"); }
		"TRIT" F 3 Bright;
		"TRIT" FFF 1 Bright { A_PainAttack("RS_WhiteSpidegg"); }
		"TRIT" AAA 3 Bright { A_Wander(); }
		"TRIT" AAAAAAAAAA 1 Bright { A_Wander(); }
		TNT1 A 0 { A_SetSpeed(28); }
		TNT1 A 0 { bNOPAIN = false; }
		TNT1 A 0 A_Jump(96, "Missile.T15.Web", "Missile.T15.Atk8");
		Goto See;
	// Point-blank slime vent -- ten arcing balls, only reachable from Atk2.
	Missile.T15.Atk4:
		"TRIT" A 2 Bright;
		"TRIT" E 8 Bright { A_FaceTarget(); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall1", 40, 0, random(-10, 10), CMF_AIMDIRECTION, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall2", 40, 0, random(-10, 10), CMF_AIMDIRECTION, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall3", 40, 0, random(-10, 10), CMF_AIMDIRECTION, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall4", 40, 0, random(-10, 10), CMF_AIMDIRECTION, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall5", 40, 0, random(-10, 10), CMF_AIMDIRECTION, random(10, 20)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall1", 40, 0, random(-12, -10), CMF_AIMDIRECTION, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall2", 40, 0, random(-10, -8), CMF_AIMDIRECTION, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall3", 40, 0, random(-10, 10), CMF_AIMDIRECTION, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall4", 40, 0, random(8, 10), CMF_AIMDIRECTION, random(13, 30)); }
		"TRIT" F 0 { A_SpawnProjectile("RS_SlimeBall5", 40, 0, random(10, 12), CMF_AIMDIRECTION, random(13, 30)); }
		"TRIT" F 6 Bright { A_FaceTarget(); }
		"TRIT" A 6 Bright;
		TNT1 A 0 A_Jump(96, "Missile.T15.Web", "Missile.T15.Atk8");
		Goto See;
	Missile.T15.Atk567:
		"TRIT" A 0 A_Jump(256, "Missile.T15.Atk5", "Missile.T15.Atk6", "Missile.T15.Atk7");
		Goto See;
	Missile.T15.Atk5:
		"TRIT" E 4 Bright;
		"TRIT" F 4 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-5, 5)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-7, 7)); }
		TNT1 A 0 A_Jump(96, "Missile.T15.Web", "Missile.T15.Atk8");
		"TRIT" F 20 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-2, 2)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-1, 1)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-2, 2)); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, random(-3, 3)); }
		TNT1 A 0 A_Jump(96, "Missile.T15.Web", "Missile.T15.Atk8");
		Goto See;
	Missile.T15.Atk6:
		"TRIT" E 4 Bright;
		"TRIT" F 6 Bright { A_FaceTarget(); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -15); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 15); }
		TNT1 A 0 A_Jump(160, "Missile.T15.Atk7");
		TNT1 A 0 A_Jump(96, "Missile.T15.Web", "Missile.T15.Atk8");
		Goto See;
	Missile.T15.Atk7:
		"TRIT" E 4 Bright;
		"TRIT" F 6 Bright { A_FaceTarget(); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 15); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, 1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -1); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -3); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -7); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -11); }
		"TRIT" E 2 Bright { A_SpawnProjectile("RS_WhiteSpiderPBolt", 42, 0, -15); }
		TNT1 A 0 A_Jump(160, "Missile.T15.Atk6");
		TNT1 A 0 A_Jump(96, "Missile.T15.Web", "Missile.T15.Atk8");
		Goto See;
	// The spider-shot: seven seeking rounds, each of which hatches a tiny
	// white spider wherever it lands.
	Missile.T15.Atk8:
		"TRIT" A 8 Bright { A_FaceTarget(); }
		"TRIT" E 1 Bright { A_FaceTarget(); }
		"TRIT" E 5 Bright { A_SpawnProjectile("RS_SPWHI4", 42, 0, random(-1, 1)); }
		"TRIT" E 0 { A_SpawnProjectile("RS_SPWHI4", 42, 0, random(3, 12)); }
		"TRIT" E 0 { A_SpawnProjectile("RS_SPWHI4", 42, 0, random(-12, -3)); }
		"TRIT" F 1 Bright { A_FaceTarget(); }
		"TRIT" F 5 Bright { A_SpawnProjectile("RS_SPWHI4", 42, 0, random(-7, 7)); }
		"TRIT" F 3 Bright { A_SpawnProjectile("RS_SPWHI4", 42, 0, random(-17, 17)); }
		"TRIT" F 1 Bright { A_SpawnProjectile("RS_SPWHI4", 42, 0, random(-12, 12)); }
		TNT1 A 0 A_Jump(96, "Missile.T15.Web");
		Goto See;
	Pain.T15:
		"TRIT" F 3;
		"TRIT" F 6 { A_Pain(); }
		Goto See;
	Death.T15:
		"TRIT" G 12 { A_ScreamAndUnblock(); }
		"TRIT" HIJ 10;
		"TRIT" H 0 { A_BossDeath(); }
		MISL XYZ 10;
		TNT1 A -1;
		Stop;
	XDeath.T15:
		Goto Death.T15;
	}
}
