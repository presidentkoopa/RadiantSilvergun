// =====================================================================
// RS_Demon -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\06\06_<code>.txt
// One CHP file per colour; the first ACTOR in each is the creature, and
// each is a genuinely different creature with its OWN sprite set, stats
// and attack. CH decorate/Demons.txt only fills what CHP leaves
// undefined (CHP's actors inherit from those CH parents).
//
//   tier  CHP    parent          body   HP    what it actually is
//   T00   06_C   CommonDemon     SARG   150   vanilla pinky
//   T01   06_G   GreenDemon      SRGG   170   green: gas-bag, pops on gib
//   T02   06_B   BlueDemon       SRGB   205   blue: adds a lunge at 800
//   T03   06_CY  CyanDemon2      WRM2   200   ICE WORM: spike bite, hiss
//                                             lunge, burrow-and-reposition
//   T04   06_P   PurpleDemon     SAR2   260   purple: long skull-rush
//   T05   06_Y   YellowDemon     SRG2   325   blood demon: bite into a
//                                             lightning rush, rage/calm
//   T06   06_A   AbyssDemon2     DOGA   600   ABYSS HOUND: triple fire
//                                             breath, drips the abyss
//   T07   06_F   FirebluDemon2   SRGF   205   fireblu: five-lunge combo
//   T08   06_BR  BrownDemon2     IFIN   310   FIEND: ghost-trail dash with
//                                             armour, orb shot, bolt chain
//   T09   06_GY  CommonGrayDemon SRGY   370   the STOMPER: leap-quakes and
//                                             a recoil charge
//   T10   06_R   RedDemon        SRGR   400   red: blood bolt, rage buff
//   T11   06_K   BlackDemon3     BCHR  4500   THE BUTCHER: hop-rushes and
//                                             lets the hounds out
//   T12   06_W   WhiteDemon2     JUGG  8000   THE JUGGERNAUT: quake dash,
//                                             thrown rocks, and a meteor
//
// Tier stats are CHP's own Health/Speed/PainChance per file, applied
// through TierData below as multipliers off this class's defaults.
//
// RS MECHANICS PRESERVED from the previous file: RS_ButcherHit (the
// hit-counter pack release + one-way no-flinch enrage) still rolls in
// the Pain DISPATCHER so every tier cluster gets it; DemonDog summons;
// MinionsDieWithMe; GetBaseKeywords; the tier consts.
//
// CHP's GROW mechanic is preserved in RS terms: a demon raised while
// holding RS_GrowRaisin (handed out by RS_ArchRingHelp) comes back one
// TIER up instead of spawning the next colour's actor and self-deleting
// -- same result on the one-actor tier dial, so CHP's Death.Nocorpse
// bookkeeping state is not needed.
//
// NOT PORTED (and why):
//   * NewIcon*/ColorTierIcon*, CHRandom_GibGenerator, CHGore*,
//     A_GivetoChildren GoAway, the CHWhitePlan inventory check and its
//     Tickles / WhiteZombiePlan branch, RandomLetterSpawner,
//     A_SpawnParticle walls -- CHP HUD/gore/bookkeeping cruft.
//   * ACS_NamedExecuteAlways("AnnounceBlackDemon"/"AnnounceWhiteDemon")
//     and T08's BrownImpCommand radiusgive (a CustomInventory whose only
//     body is an ACS call) -- ACS.
//   * T03's CH_Cirno death easter-egg: referenced all over CH and CHP,
//     DEFINED NOWHERE in either tree. Dropped, not substituted.
//   * Damagetype-specific deaths that CHP gives to only ONE colour
//     (T01 Death.Melee / Death.Fire, T02+T07 Pain.Fire): those labels
//     are class-wide in this architecture and would leak across tiers,
//     so they are omitted; the normal Death/Pain clusters cover them.
//
// SPRITE NOTES (verified against sprites/monsters/_src):
//   * IFN2 ships only frames A and B. CHP's T08 names IFN2 C and F on
//     zero-tic lines; those are carried on TNT1 (a 0-tic frame never
//     renders, so nothing is lost).
//   * CHP's T03 melee writes "TNT1 HHHHH" -- TNT1 has only frame A;
//     shipped as TNT1 AAAAA, same five zero-tic spike bursts.
//   * SARG/POSS/MISL/BAL1 are IWAD sprites; every other token here is a
//     real CHP/CH sprite set copied into sprites/monsters/Demon/T<nn>/.
//   * CHP gives no Raise to T03, T11 or T12. Rather than let those fall
//     back to the pinky's Raise, each gets the reverse of its own death
//     run on its own frames.
// =====================================================================

class RS_Demon : RS_DemonBase replaces Demon
{
	// CHP user vars -> private int fields.
	private int rsCalm;   // T05 / T08  User_Calm
	private int rsHop;    // T11        User_HOP
	private int rsRock;   // T12        user_rock

	Default
	{
		Health 150;
		Radius 30;
		Height 56;
		Mass 400;
		Speed 10;
		PainChance 150;
		Monster;
		+FLOORCLIP
		SeeSound "demon/sight";   PainSound "demon/pain";
		DeathSound "demon/death"; ActiveSound "demon/active";
		AttackSound "demon/melee";
		Obituary "$OB_DEMON";
		Tag "Demon";
	}

	// CHP's real per-colour numbers, read out of 06_*.txt. Health and
	// Speed are absolute there, so they are expressed as multipliers off
	// Default Health 150 / Speed 10 to keep the base class's
	// recompute-from-defaults contract.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 150; r.dmgMul = 1.0;
		int hp = 150; int spd = 10;
		switch (t)
		{
			case 0:  hp = 150;  spd = 10; r.painChance = 150; r.dmgMul = 1.0; break;
			case 1:  hp = 170;  spd = 11; r.painChance = 130; r.dmgMul = 1.1; break;
			case 2:  hp = 205;  spd = 13; r.painChance = 110; r.dmgMul = 1.2; break;
			case 3:  hp = 200;  spd = 27; r.painChance = 64;  r.dmgMul = 1.3; break;
			case 4:  hp = 260;  spd = 15; r.painChance = 80;  r.dmgMul = 1.4; break;
			case 5:  hp = 325;  spd = 18; r.painChance = 75;  r.dmgMul = 1.6; break;
			case 6:  hp = 600;  spd = 19; r.painChance = 128; r.dmgMul = 1.7; break;
			case 7:  hp = 205;  spd = 5;  r.painChance = 180; r.dmgMul = 1.5; break;
			case 8:  hp = 310;  spd = 17; r.painChance = 33;  r.dmgMul = 1.6; break;
			case 9:  hp = 370;  spd = 8;  r.painChance = 8;   r.dmgMul = 1.8; break;
			case 10: hp = 400;  spd = 15; r.painChance = 30;  r.dmgMul = 2.0; break;
			case 11: hp = 4500; spd = 17; r.painChance = 68;  r.dmgMul = 2.6; break;
			case 12: hp = 8000; spd = 19; r.painChance = 16;  r.dmgMul = 3.2; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 150.0;
		r.spdMul = double(spd) / 10.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SARG SRGG SRGB WRM2 SAR2 SRG2 DOGA SRGF IFIN SRGY SRGR BCHR JUGG";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:demon role:bruiser delivery:melee element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE BUTCHER. Takes hits, and at a count releases the pack -- so
	// the reward for beating on it is more things biting you. Plus a
	// chance each hit to permanently stop flinching, which is what turns
	// a pinky into a freight train mid-fight.
	// -----------------------------------------------------------------
	const RS_DEMON_TIER_PACK = 7;
	const RS_DEMON_PACK_AT   = 8;

	override bool MinionsDieWithMe() { return true; }

	void RS_ButcherHit()
	{
		if (Tier < RS_DEMON_TIER_PACK)
			return;

		AddCharge(1);

		if (ChargeCounter >= RS_DEMON_PACK_AT)
		{
			ResetCharge();
			if (SummonPack(RS_MonsterCatalog.MINION_DemonDog(), 3, 6, -3, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}

		// Permanent, one-way. Guarded by the flag itself.
		if (!bNOPAIN && Tier >= 9 && random(0, 255) < 90)
		{
			bNOPAIN = true;
			MissileChanceMult *= 2.0;
			Speed *= 1.25;
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	// CHP's Grow: an arch-vile-raised demon comes back stronger. On the
	// RS tier dial that is simply +1 tier on the same actor.
	void RS_GrowTier()
	{
		TakeInventory("RS_GrowRaisin", 1);
		if (Tier < 12)
			SetTier(Tier + 1, true);
	}

	States
	{
	// ===== dispatcher override: the Butcher counts every flinch =====
	Pain:
		TNT1 A 0
		{
			RS_ButcherHit();
			return TierState("Pain");
		}
		Goto See;

	// ================= T00 COMMON (06_C) =================
	Spawn.T00:
		"SARG" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"SARG" AABBCCDD 2 Fast { A_Chase(); }
		Loop;
	Melee.T00:
		"SARG" EF 8 Fast { A_FaceTarget(); }
		"SARG" G 8 Fast { A_CustomMeleeAttack(random(1, 10) * 4); }
		Goto See;
	Pain.T00:
		"SARG" H 2 Fast;
		"SARG" H 2 Fast { A_Pain(); }
		Goto See;
	Death.T00:
		"SARG" I 8;
		"SARG" J 8 { A_Scream(); }
		"SARG" K 4;
		"SARG" L 4 { A_NoBlocking(); }
		"SARG" M 4;
		"SARG" N -1;
		Stop;
	XDeath.T00:
		POSS PPPPPP 1;
		POSS R 4 { A_XScream(); }
		POSS S 5;
		POSS T 4 { A_NoBlocking(); }
		POSS U -1;
		Stop;
	Raise.T00:
		"SARG" N 5 { if (CountInv("RS_GrowRaisin") > 0) return ResolveState("Raise.T00.Grow"); return ResolveState(null); }
		"SARG" MLKJI 5;
		Goto See;
	Raise.T00.Grow:
		"SARG" MLKJI 5;
		TNT1 A 0 { RS_GrowTier(); }
		Goto See;

	// ================= T01 GREEN (06_G) =================
	// A walking gas bag: 44/256 of its deaths go straight to the burst.
	Spawn.T01:
		"SRGG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"SRGG" AABBCCDD 2 Fast { A_Chase(); }
		Loop;
	Melee.T01:
		"SRGG" EF 7 Fast { A_FaceTarget(); }
		"SRGG" G 8 Fast { A_CustomMeleeAttack(random(13, 40), "Demon/melee", "none"); }
		Goto See;
	Pain.T01:
		"SRGG" H 2 Fast;
		"SRGG" H 2 Fast { A_Pain(); }
		Goto See;
	Death.T01:
		"SRGG" I 0 A_Jump(44, "XDeath");
	Death.T01.Body:
		"SRGG" I 8;
		"SRGG" J 8 { A_Scream(); }
		"SRGG" K 4;
		"SRGG" L 4 { A_NoBlocking(); }
		"SRGG" M 4;
		"SRGG" N -1;
		Stop;
	XDeath.T01:
		ZOMG P 0 { A_SpawnItemEx("RS_GreenDEDSmoke", 0, 0, 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		ZOMG P 0 { A_XScream(); }
		ZOMG P 0 { A_StartSound("weapons/rocklx", 7, 0, 1.0); }
		ZOMG P 8 Bright { A_Explode(random(12, 64), 78); }
		ZOMG Q 6 Bright { A_Quake(20, 12, 0, 64, ""); }
		ZOMG Q 0 { A_SpawnItemEx("RS_Gas14", random(-120, 120), random(-120, 120), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		ZOMG Q 0 { A_SpawnItemEx("RS_Splash11", random(-64, 64), random(-64, 64), random(3, 26), random(1, 24), random(1, 24), random(1, 64), random(-180, 180)); }
		ZOMG Q 0 { A_SpawnItemEx("RS_Gas14", random(-80, 80), random(-80, 80), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		ZOMG Q 0 { A_SpawnItemEx("RS_Splash11", random(-64, 64), random(-64, 64), random(3, 26), random(1, 24), random(1, 24), random(1, 64), random(-180, 180)); }
		ZOMG Q 0 { A_SpawnItemEx("RS_Gas14", random(-20, 20), random(-20, 20), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		ZOMG Q 0 { A_SpawnItemEx("RS_Splash11", random(-64, 64), random(-64, 64), random(3, 26), random(1, 24), random(1, 24), random(1, 64), random(-180, 180)); }
		ZOMG Q 0 { A_SpawnItemEx("RS_Gas14", random(-80, 80), random(-80, 80), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		ZOMG R 4 Bright { A_StartSound("slimeball/splat", 6, 0, 1.0); }
		ZOMG RRRRR 0 { A_SpawnItemEx("RS_Splash11", random(-64, 64), random(-64, 64), random(3, 26), random(1, 24), random(1, 24), random(1, 64), random(-180, 180)); }
		ZOMG S 3 Bright { A_SetTranslucent(0.5); }
		ZOMG T 3 Bright { A_SetTranslucent(0.3); }
		Stop;
	Raise.T01:
		"SRGG" N 5 { if (CountInv("RS_GrowRaisin") > 0) return ResolveState("Raise.T01.Grow"); return ResolveState(null); }
		"SRGG" MLKJI 5;
		Goto See;
	Raise.T01.Grow:
		"SRGG" MLKJI 5;
		TNT1 A 0 { RS_GrowTier(); }
		Goto See;

	// ================= T02 BLUE (06_B) =================
	Spawn.T02:
		"SRGB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"SRGB" AABBCCDD 2 Fast { A_Chase(); }
		Loop;
	Missile.T02:
		"SRGB" E 0 A_JumpIfCloser(800, "Missile.T02.Rush");
		Goto See;
	Missile.T02.Rush:
		"SRGB" F 1 { A_FaceTarget(); }
		"SRGB" F 3 { A_SkullAttack(15); }
		Goto See;
	Melee.T02:
		"SRGB" EF 7 Fast { A_FaceTarget(); }
		"SRGB" G 8 Fast { A_CustomMeleeAttack(random(15, 43), "Demon/melee", "none"); }
		Goto See;
	Pain.T02:
		"SRGB" H 2 Fast;
		"SRGB" H 2 Fast { A_Pain(); }
		Goto See;
	Death.T02:
		"SRGB" I 8;
		"SRGB" J 8 { A_Scream(); }
		"SRGB" K 4;
		"SRGB" L 4 { A_NoBlocking(); }
		"SRGB" M 4;
		"SRGB" N -1;
		Stop;
	XDeath.T02:
		ZOMB PPPPPP 1;
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		ZOMB R 4 { A_XScream(); }
		ZOMB S 5;
		ZOMB T 4 { A_NoBlocking(); }
		ZOMB U -1;
		Stop;
	Raise.T02:
		"SRGB" N 5 { if (CountInv("RS_GrowRaisin") > 0) return ResolveState("Raise.T02.Grow"); return ResolveState(null); }
		"SRGB" MLKJI 5;
		Goto See;
	Raise.T02.Grow:
		"SRGB" MLKJI 5;
		TNT1 A 0 { RS_GrowTier(); }
		Goto See;

	// ================= T03 CYAN -- ICE WORM (06_CY) =================
	// Speed 27. Bites through a cloud of ice spikes, lunges at range, and
	// when hurt it flattens itself, sprays spikes in four arcs, wanders
	// off at speed 77 and pops back up.
	Spawn.T03:
		"WRM2" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"WRM2" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T03:
		"WRM2" E 8 { A_FaceTarget(); }
		"WRM2" E 0 A_JumpIfCloser(72, "Melee.T03");
		"WRM2" E 8 A_JumpIfCloser(700, "Missile.T03.Hiss");
	Missile.T03.HideMe:
		TNT1 A 0 { bNOPAIN = true; }
		"WRM2" G 2 { A_SetScale(1.0, 0.5); }
		"WRM2" G 2 { A_SetScale(1.0, 0.25); }
		"WRM2" G 2 { A_SetScale(1.0, 0.1); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(0, 90)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(89, 180)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(181, 270)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(271, 359)); }
		"WRM2" G 8 { A_SetSpeed(77); }
		"WRM2" AABBCCDD 2 { A_Wander(); }
		"WRM2" AABBCCDD 1 { A_Wander(); }
		"WRM2" G 5 { A_SetSpeed(25); }
		"WRM2" G 2 { A_SetScale(1.0, 0.25); }
		"WRM2" G 2 { A_SetScale(1.0, 0.5); }
		"WRM2" G 2 { A_SetScale(1.0, 1.0); }
		TNT1 A 0 { bNOPAIN = false; }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(0, 90)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(89, 180)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(181, 270)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(271, 359)); }
		Goto See;
	Melee.T03:
		"WRM2" EF 4 { A_FaceTarget(); }
		// CHP writes "TNT1 HHHHH" -- TNT1 only has frame A.
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 24, random(9, 33), 0, random(3, 9), frandom(-9, 9)); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 29, random(9, 33), 0, random(4, 12), frandom(-4, 4)); }
		"WRM2" G 4 { A_CustomMeleeAttack(random(10, 48), "slimeworm/melee", "none"); }
		Goto See;
	Missile.T03.Hiss:
		"WRM2" EF 4 { A_FaceTarget(); }
		"WRM2" G 8 { A_SkullAttack(40); }
		Goto See;
	Pain.T03:
		"WRM2" H 2;
		"WRM2" H 2 { A_Pain(); }
		"WRM2" H 2 A_Jump(232, "Missile.T03.HideMe");
		Goto See;
	Death.T03:
		"WRM2" I 8;
		"WRM2" J 8 { A_Scream(); }
		"WRM2" K 4;
		"WRM2" L 4 { A_NoBlocking(false); }
		"WRM2" M 4;
		"WRM2" N 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		"WRM2" N 1 { A_Burst("IceChunk"); }
		Stop;
	XDeath.T03:
		Goto Death.T03;
	Raise.T03:
		"WRM2" NMLKJI 5;
		Goto See;

	// ================= T04 PURPLE (06_P) =================
	Spawn.T04:
		"SAR2" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"SAR2" A 4;
	See.T04.Walk:
		"SAR2" AABBCCDD 2 Fast { A_Chase(); }
		Goto See.T04.Walk;
	Missile.T04:
		"SAR2" E 0 A_JumpIfCloser(800, "Missile.T04.Rush2");
		Goto See.T04.Walk;
	Missile.T04.Rush2:
		"SAR2" F 2 { A_FaceTarget(); }
		"SAR2" F 10 { A_SkullAttack(24); }
		Goto See;
	Melee.T04:
		"SAR2" EF 7 Fast { A_FaceTarget(); }
		"SAR2" G 6 Fast { A_CustomMeleeAttack(random(13, 46), "monster/dogatk", "none"); }
		Goto See.T04.Walk;
	Pain.T04:
		"SAR2" H 2 Fast;
		"SAR2" H 2 Fast { A_Pain(); }
		"SAR2" H 2 Bright A_Jump(100, "Missile");
		Goto See.T04.Walk;
	Death.T04:
		"SAR2" I 8;
		"SAR2" J 8 { A_Scream(); }
		"SAR2" K 4;
		"SAR2" L 4 { A_NoBlocking(); }
		"SAR2" M 4;
		"SAR2" N -1;
		Stop;
	XDeath.T04:
		POSS PPPPPP 1;
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		POSS R 4 { A_XScream(); }
		POSS S 5;
		POSS T 4 { A_NoBlocking(); }
		POSS U -1;
		Stop;
	Raise.T04:
		"SAR2" N 5;
		"SAR2" MLKJI 5;
		Goto See.T04.Walk;

	// ================= T05 YELLOW -- BLOOD DEMON (06_Y) =================
	// Bites, then immediately converts the bite into a lightning rush it
	// cannot cancel. Pain rolls a speed buff; the buff's other half is a
	// "calm" pass that dumps zaps and drops back to walking pace.
	Spawn.T05:
		"SRG2" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"SRG2" A 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRG2" AABB 2 { A_Chase(); }
		"SRG2" C 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRG2" CCDD 2 { A_Chase(); }
		"SRG2" A 0 { if (rsCalm == 1) return ResolveState("See.T05.Calm"); return ResolveState(null); }
		Loop;
	Melee.T05:
		"SRG2" EF 7 { A_FaceTarget(); }
		"SRG2" G 6 { A_CustomMeleeAttack(random(13, 52), "blooddemon/melee", "none"); }
		"SRG2" G 1 { rsCalm = (rsCalm == 1) ? 1 : 0; }
		Goto Melee.T05.NoYouDont;
	Melee.T05.NoYouDont:
		"SRG2" G 8 { A_SkullAttack(30); }
		"SRG2" GGGGG 2 { A_SpawnProjectile("RS_ZapZapCB", 32, random(-32, 32), random(-32, 32)); }
		"SRG2" G 0 { A_StartSound("Litn/litn3", CHAN_WEAPON); }
		"SRG2" G 4 { A_Stop(); }
		"SRG2" G 0 { A_SetSpeed(16); }
		Goto See;
	Pain.T05:
		"SRG2" H 2;
		"SRG2" H 2 { A_Pain(); }
		"SRG2" H 1 A_Jump(174, "Pain.T05.SpeedBuff");
		Goto See;
	Pain.T05.SpeedBuff:
		"SRG2" E 1 { A_SetSpeed(30); }
		"SRG2" E 1 { rsCalm = (rsCalm == 0) ? 1 : 0; }
		Goto See;
	See.T05.Calm:
		"SRG2" E 1 { A_SetSpeed(16); }
		"SRG2" E 1 { A_StartSound("Litn/litn3", CHAN_WEAPON); }
		"SRG2" EEEEE 0 { A_SpawnProjectile("RS_ZapZapCB", 32, random(-32, 32), random(-32, 32)); }
		Goto See;
	Death.T05:
		"SRG2" I 8;
		"SRG2" I 0 { A_FaceTarget(); }
		"SRG2" J 0 { A_SpawnItemEx("RS_BloodDemonArm", 10, 0, 32, 0, 8, 0, 0, 128); }
		"SRG2" J 8 { A_Scream(); }
		"SRG2" K 4;
		"SRG2" L 4 { A_NoBlocking(); }
		"SRG2" M 4;
		"SRG2" N -1;
		Stop;
	XDeath.T05:
		POSS PPPPPP 1;
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		POSS R 4 { A_XScream(); }
		POSS S 5;
		POSS T 4 { A_NoBlocking(); }
		POSS U -1;
		Stop;
	Raise.T05:
		"SRG2" NMLKJI 5;
		Goto See;

	// ================= T06 ABYSS -- HOUND (06_A) =================
	// Drips the abyss as it runs; bites, and 86/256 of bites chain into a
	// three-shot fire breath.
	Spawn.T06:
		"DOGA" A 10 { A_Look(); }
		Loop;
	See.T06:
		"DOGA" AAAA 1 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"DOGA" BBBB 1 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(-8, 8), random(-8, 8), random(5, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION, 216); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"DOGA" CCCC 1 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"DOGA" DDDD 1 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(-8, 8), random(-8, 8), random(5, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION, 216); }
		"DOGA" EEEE 1 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"DOGA" FFFF 1 { A_Chase(); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(-8, 8), random(-8, 8), random(5, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION, 216); }
		Loop;
	Melee.T06:
		"DOGA" G 5;
		"DOGA" H 4 { A_FaceTarget(); }
		"DOGA" I 6 { A_CustomMeleeAttack(random(17, 58), "blooddemon/melee", "none"); }
		"DOGA" I 1 A_Jump(86, "Missile");
		Goto See;
	Missile.T06:
		"DOGA" G 5;
		"DOGA" G 8 { A_FaceTarget(); }
		"DOGA" H 1 { A_SpawnProjectile("RS_AbyssDogFire", 28, 0, 0, 0, 0); }
		"DOGA" H 1 { A_SpawnProjectile("RS_AbyssDogFire", 28, -5, -17, 0, 0); }
		"DOGA" H 1 { A_SpawnProjectile("RS_AbyssDogFire", 28, 5, 17, 0, 0); }
		"DOGA" I 6;
		Goto See;
	Pain.T06:
		"DOGA" J 1;
		"DOGA" J 4 { A_Pain(); }
		Goto See;
	Death.T06:
		"DOGA" K 8;
		"DOGA" L 8 { A_Scream(); }
		"DOGA" M 4;
		"DOGA" N 4 { A_NoBlocking(); }
		"DOGA" OP 4;
		"DOGA" Q -1;
		Stop;
	XDeath.T06:
		Goto Death.T06;
	Raise.T06:
		"DOGA" QPONMLK 5;
		Goto See;

	// ================= T07 FIREBLU (06_F) =================
	// Speed 5 on the ground, but its lunge is five chained skull-attacks.
	Spawn.T07:
		"SRGF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"SRGF" A 4;
	See.T07.Walk:
		"SRGF" ABBCCDDA 4 Fast { A_Chase(); }
		Goto See.T07.Walk;
	Missile.T07:
		"SRGF" E 0 Bright A_JumpIfCloser(800, "Missile.T07.Rush");
		Goto See.T07.Walk;
	Missile.T07.Rush:
		"SRGF" F 1 { A_FaceTarget(); }
		"SRGF" F 3 { A_SkullAttack(20); }
		"SRGF" F 3 Fast { A_FaceTarget(); }
		"SRGF" F 3 { A_SkullAttack(20); }
		"SRGF" F 3 Fast { A_FaceTarget(); }
		"SRGF" F 3 { A_SkullAttack(20); }
		"SRGF" F 3 Fast { A_FaceTarget(); }
		"SRGF" F 3 { A_SkullAttack(20); }
		"SRGF" F 3 Fast { A_FaceTarget(); }
		"SRGF" F 10 { A_SkullAttack(20); }
		Goto See;
	Melee.T07:
		"SRGF" EF 7 Fast { A_FaceTarget(); }
		"SRGF" G 8 Fast { A_CustomMeleeAttack(random(15, 50), "Demon/melee", "none"); }
		Goto See.T07.Walk;
	Pain.T07:
		"SRGF" H 2 Fast;
		"SRGF" H 2 Fast { A_Pain(); }
		Goto See.T07.Walk;
	// CHP stacks Death.Ice / Death / XDeath on one block for fireblu:
	// it always gibs.
	Death.T07:
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		ZOMF PPPPPP 1;
		ZOMF R 4 { A_XScream(); }
		ZOMF S 5;
		ZOMF AAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 2, random(-359, 359), SXF_NOCHECKPOSITION, 64); }
		ZOMF T 4 { A_NoBlocking(); }
		ZOMF U -1;
		Stop;
	XDeath.T07:
		Goto Death.T07;
	Raise.T07:
		"SRGF" N 5;
		"SRGF" MLKJI 5;
		Goto See.T07.Walk;

	// ================= T08 BROWN -- THE FIEND (06_BR) =================
	// Rolls a ghost-trail dash out of its walk cycle: NOPAIN, 0.6x damage
	// taken and speed 40 while it runs you down. Orb at range, chaingun
	// bolt-chain inside 200.
	Spawn.T08:
		"IFN2" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"IFIN" A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" AABB 2 { A_Chase(); }
		TNT1 A 0 A_Jump(40, "See.T08.MaybeDash");
		"IFIN" C 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
	See.T08.B:
		"IFIN" CCDD 2 { A_Chase(); }
		TNT1 A 0 { if (rsCalm == 1) return ResolveState("See.T08.Calm"); return ResolveState(null); }
		Goto See.T08;
	See.T08.MaybeDash:
		TNT1 A 0 A_JumpIfInTargetLOS("See.T08.Dash", 0, JLOSF_DEADNOJUMP, 1200, 200);
		Goto See.T08.B;
	See.T08.Dash:
		TNT1 A 0 { bNOPAIN = true; A_GiveInventory("RS_HKEXProtect", 1); }
		"IFIN" G 1 { A_SetSpeed(40); }
		"IFIN" AB 1 { A_Wander(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" CD 1 { A_Chase(null, null); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" AB 1 { A_Chase(null, null); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" CD 1 { A_Chase(null, null); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" AB 1 { A_Wander(); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" CD 1 { A_Chase(null, null); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" AB 1 { A_Chase(null, null); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		"IFIN" CD 1 { A_Chase(null, null); }
		TNT1 A 0 { A_SpawnItemEx("RS_BrownDemonGhost", 0, 0, 6); }
		TNT1 A 0 { A_StartSound("BrownDemon/Step", CHAN_BODY); }
		TNT1 A 0 { bNOPAIN = false; TakeInventory("RS_HKEXProtect", 1); }
		"IFIN" G 1 { A_SetSpeed(17); }
		Goto See;
	Missile.T08:
		TNT1 A 0 { rsCalm = (rsCalm == 1) ? 1 : 0; }
		TNT1 A 0 A_JumpIfCloser(200, "Melee.T08.Chain");
		"IFIN" E 8 Bright { A_FaceTarget(); }
		"IFIN" F 1 Bright { A_StartSound("SNPRFIRE", CHAN_WEAPON); }
		"IFIN" F 6 Bright { A_SpawnProjectile("RS_BrownOrbDemon", 32, 0, 0); }
		"IFIN" G 3 Bright;
		"IFIN" G 9;
		Goto See;
	Melee.T08:
		TNT1 A 0 A_JumpIfCloser(200, "Melee.T08.Chain");
		Goto See;
	Melee.T08.Chain:
		"IFIN" E 2 Bright { A_FaceTarget(); }
		"IFIN" F 0 { A_StartSound("chainguy/attack", CHAN_WEAPON); }
		"IFIN" FF 1 Bright { A_SpawnProjectile("RS_RedDemonBloodBolt3", 32, 0, random(-7, 7)); }
		"IFIN" F 1 Bright A_MonsterRefire(128, "See");
		Goto Melee.T08;
	Pain.T08:
		"IFIN" G 2;
		"IFIN" G 2 { A_Pain(); }
		"IFIN" G 1 A_Jump(174, "Pain.T08.SpeedBuff");
		Goto See;
	Pain.T08.SpeedBuff:
		"IFIN" G 1 { A_SetSpeed(30); }
		"IFIN" G 1 { rsCalm = (rsCalm == 0) ? 1 : 0; }
		Goto See;
	See.T08.Calm:
		"IFIN" G 2 { A_SetSpeed(15); }
		Goto See;
	Death.T08:
		"IFIN" H 8;
		"IFIN" I 0 { A_FaceTarget(); }
		"IFIN" I 8 { A_Scream(); }
		"IFIN" J 4 { A_Explode(random(5, 32), 64); }
		"IFIN" K 4 { A_NoBlocking(); }
		"IFIN" LM 4;
		"IFIN" N -1;
		Stop;
	XDeath.T08:
		Goto Death.T08;
	Raise.T08:
		"IFIN" NMLKJIH 5;
		Goto See;

	// ================= T09 GRAY -- THE STOMPER (06_GY) =================
	// PainChance 8, Mass 1000. Leaps and lands a quake; the charge version
	// recoils backwards first and lands four quakes in a cross.
	Spawn.T09:
		"SRGY" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"SRGY" AABBCCDD 3 Fast { A_Chase(); }
		Goto See.T09;
	Missile.T09:
		"SRGY" E 0 A_Jump(80, "Missile.T09.MegaCharge");
	Missile.T09.MegaStomp:
		"SRGY" E 0 { A_StartSound("monster/dogatk", CHAN_VOICE); }
		"SRGY" E 8 Fast { A_FaceTarget(); }
		"SRGY" F 1 { ThrustThingZ(0, 20, 0, 0); }
	Missile.T09.StompWait:
		"SRGY" F 1 A_CheckFloor("Missile.T09.StompLand");
		Goto Missile.T09.StompWait;
	Missile.T09.StompLand:
		"SRGY" E 0 { A_Quake(1, 30, 0, 40, ""); }
		"SRGY" E 6 Fast { A_SpawnProjectile("RS_MolochQuake", 0, 0, 0); }
		"SRGY" G 8 Fast;
		Goto See;
	Missile.T09.MegaCharge:
		"SRGY" EEEE 8 Fast { A_FaceTarget(); }
		"SRGY" F 0 { A_StartSound("monster/dogatk", CHAN_VOICE); }
		"SRGY" F 0 { A_Recoil(-100); }
		"SRGY" F 1 { ThrustThingZ(0, 20, 0, 0); }
	Missile.T09.ChargeWait:
		"SRGY" F 1 A_CheckFloor("Missile.T09.ChargeLand");
		Goto Missile.T09.ChargeWait;
	Missile.T09.ChargeLand:
		"SRGY" E 0 { A_Quake(2, 60, 0, 40, ""); }
		"SRGY" E 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 0); }
		"SRGY" E 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 90); }
		"SRGY" E 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 180); }
		"SRGY" E 6 Fast { A_SpawnProjectile("RS_MolochQuake", 0, 0, 270); }
		"SRGY" G 8 Fast;
		Goto See;
	Melee.T09:
		"SRGY" F 0 { A_StartSound("monster/dogatk", CHAN_VOICE); }
		"SRGY" EF 7 Fast { A_FaceTarget(); }
		"SRGY" FFFFFFFFFFFFFFFEEEEEEEEEEEEEEE 1 A_JumpIfTargetInsideMeleeRange("Melee.T09.BiteIt");
		Goto Missile.T09.MegaStomp;
	Melee.T09.BiteIt:
		"SRGY" G 6 Fast { A_CustomMeleeAttack(random(1, 10) * 8 + random(1, 10), "Bite/bite4", "", "Melee"); }
		Goto See;
	Pain.T09:
		"SRGY" H 2 Fast;
		"SRGY" H 2 Fast { A_Pain(); }
		"SRGY" H 2 Bright A_Jump(100, "Missile.T09.MegaStomp");
		Goto See;
	Death.T09:
		"SRGY" I 8;
		"SRGY" J 8 { A_Scream(); }
		"SRGY" K 4;
		"SRGY" L 4 { A_NoBlocking(); }
		"SRGY" M 4;
		"SRGY" N -1;
		Stop;
	XDeath.T09:
		SHDT PPPPPP 1;
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		SHDT R 4 { A_XScream(); }
		SHDT S 5;
		SHDT T 4 { A_NoBlocking(); }
		SHDT U -1;
		Stop;
	Raise.T09:
		"SRGY" N 5;
		"SRGY" MLKJI 5;
		Goto See;

	// ================= T10 RED (06_R) =================
	// Blood bolt at range, and pain rolls a one-way rage: +speed, NOPAIN,
	// MISSILEMORE.
	Spawn.T10:
		"SRGR" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"SRGR" A 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRGR" AABB 2 { A_Chase(); }
		"SRGR" C 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRGR" CCDD 2 { A_Chase(); }
		Loop;
	Missile.T10:
		"SRGR" EF 7 Bright { A_FaceTarget(); }
		"SRGR" F 3 Bright { A_SpawnProjectile("RS_RedDemonBloodBolt1", 32); }
		"SRGR" G 4;
		Goto See;
	Melee.T10:
		"SRGR" EF 7 { A_FaceTarget(); }
		"SRGR" G 7 { A_CustomMeleeAttack(random(13, 58), "blooddemon/melee", "none"); }
		"SRGR" G 1 { A_SpawnItemEx("RS_RedThingsLS", 1, 3, 15, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SRGR" G 0 { A_SpawnItemEx("RS_RedThingsLS", 6, 3, 15, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Pain.T10:
		"SRGR" H 2;
		"SRGR" H 2 { A_Pain(); }
		"SRGR" H 1 A_Jump(174, "Pain.T10.BuffUp");
		Goto See;
	Pain.T10.BuffUp:
		"SRGR" E 1 { A_SetSpeed(25); }
		"SRGR" EF 6 { A_SpawnProjectile("RS_EffectHK", 24, 0); }
		"SRGR" G 5 { bNOPAIN = true; }
		"SRGR" G 0 { bMISSILEMORE = true; }
		"SRGR" G 0;
		Goto See;
	Death.T10:
		"SRGR" I 8;
		"SRGR" I 0 { A_FaceTarget(); }
		"SRGR" J 0 { A_SpawnItemEx("RS_BloodDemonArm2", 10, 0, 32, 0, 8, 0, 0, 128); }
		"SRGR" J 8 { A_Scream(); }
		"SRGR" K 4;
		"SRGR" L 4 { A_NoBlocking(); }
		"SRGR" M 4;
		"SRGR" N -1;
		Stop;
	XDeath.T10:
		POSS PPPPPP 1;
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		POSS R 4 { A_XScream(); }
		POSS S 5;
		POSS T 4 { A_NoBlocking(); }
		POSS U -1;
		Stop;
	Raise.T10:
		"SRGR" NMLKJI 5;
		Goto See;

	// ================= T11 BLACK -- THE BUTCHER (06_K) =================
	// 4500 HP of hop-rushes. Every flinch adds a hop charge; at eight it
	// stops and lets the hounds out instead.
	Spawn.T11:
		"BCHR" AAAAAAAAAABBBBBBBBBB 1 { A_Look(); }
		Loop;
	See.T11:
		"BCHR" AABB 3 { A_Chase(); }
		"BCHR" C 0 { A_StartSound("Butcher/Step", 7); }
		"BCHR" CCDD 3 { A_Chase(); }
		"BCHR" A 0 { A_StartSound("Butcher/Step", 7); }
		"BCHR" A 0 A_Jump(64, "See.T11.Calm");
		Loop;
	See.T11.Calm:
		"BCHR" A 0 { A_SetSpeed(18); }
		Goto See;
	Missile.T11:
		"BCHR" E 0 { A_FaceTarget(); }
		"BCHR" E 0 { if (rsHop >= 8) return ResolveState("Missile.T11.Dogs"); return ResolveState(null); }
		"BCHR" E 0 { if (target && target.pos.z > pos.z + height + 128) return ResolveState("Missile.T11.AlleUp"); return ResolveState(null); }
		"BCHR" E 0 A_JumpIfCloser(500, "Missile.T11.BigHop");
		"BCHR" E 0 A_Jump(256, "Missile.T11.HopHop");
		Goto See;
	Missile.T11.AlleUp:
		"BCHR" E 0 { A_FaceTarget(); }
		"BCHR" E 4 { ThrustThingZ(0, 88, 0, 0); }
		"BCHR" E 0 A_JumpIfHigherOrLower("Missile.T11.AlleUp", "See", 26, -26);
		"BCHR" E 1 A_CheckRange(520, "See", true);
		"BCHR" E 0;
		Goto Missile;
	Missile.T11.HopHop:
		"BCHR" E 0 { A_FaceTarget(); }
		"BCHR" E 0 { ThrustThingZ(0, 12, angle + 360, 0); }
		"BCHR" EF 7 { A_SkullAttack(20); }
		"BCHR" E 0 A_JumpIfCloser(60, "Melee.T11");
		Goto Missile.T11.HopHop;
	Missile.T11.BigHop:
		"BCHR" EF 12 { A_SkullAttack(37); }
		"BCHR" E 3 { A_FaceTarget(); }
		"BCHR" E 0 A_Jump(64, "Missile.T11.HopHop");
		Goto Melee.T11;
	Missile.T11.Dogs:
		"BCHR" E 20 { A_FaceTarget(); }
		"BCHR" FFFF 12 { A_SpawnItemEx("RS_WHOLETTHEDOGSOUT", random(-65, 65), random(-66, 66), random(3, 24), 0, 0, 0, 0, SXF_SETMASTER|SXF_NOCHECKPOSITION); }
		"BCHR" G 12 { rsHop = max(0, rsHop - 8); }
		Goto See;
	Melee.T11:
		"BCHR" EF 5 { A_FaceTarget(); }
		"BCHR" G 7 { A_CustomMeleeAttack(random(30, 125), "Butcher/Melee", "Butcher/miss", "Extreme"); }
		"BCHR" G 1 { A_Stop(); }
		Goto See;
	Pain.T11:
		"BCHR" H 3 { A_SetSpeed(28); }
		"BCHR" H 3 { A_Pain(); }
		"BCHR" H 3 { rsHop++; }
		Goto See;
	Death.T11:
		"BCHR" H 12 { A_Scream(); }
		"BCHR" I 0 { A_StartSound("Butcher/Explode", CHAN_BODY); }
		"BCHR" IJK 6 { A_KillChildren(); }
		"BCHR" L 0 { A_FaceTarget(); }
		"BCHR" L 6 { A_SpawnItemEx("RS_ButcherHammer", 0, -18, 24, 3, 0, 3, -85, 128); }
		"BCHR" M 6 { A_NoBlocking(); }
		"BCHR" NOP 6;
		"BCHR" Q -1;
		Stop;
	XDeath.T11:
		Goto Death.T11;
	Raise.T11:
		"BCHR" QPONMLKJIH 5;
		Goto See;

	// ================= T12 WHITE -- THE JUGGERNAUT (06_W) =================
	// 8000 HP. Noclips out of anything it gets stuck in, dashes with a
	// four-hit trample that ends in a floor slam, throws rocks at range,
	// and on a rock counter goes airborne for a meteor drop.
	Spawn.T12:
		"JUGG" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"JUGG" A 3 { A_Chase(); }
		"JUGG" A 0 { bNOCLIP = false; }
		"JUGG" A 0 A_CheckBlock("See.T12.Unblock", CBF_DROPOFF);
		"JUGG" A 0 A_CheckBlock("See.T12.Unblock", CBF_DROPOFF);
		"JUGG" A 0 { A_StartSound("Juggernaut/Step", CHAN_BODY); }
		"JUGG" ABBC 3 { A_Chase(); }
		"JUGG" C 0 { A_StartSound("Juggernaut/Step", CHAN_BODY); }
		"JUGG" CDD 3 { A_Chase(); }
		"JUGG" D 0 A_Jump(1, "Missile.T12.Meteor");
		Loop;
	See.T12.Unblock:
		"JUGG" A 2 { bNOCLIP = true; }
		"JUGG" A 3 { A_FaceTarget(); }
		"JUGG" A 3 { A_SkullAttack(20); }
		"JUGG" A 2 { bNOCLIP = false; }
		Goto See;
	Missile.T12:
		"JUGG" E 0 { A_SetSpeed(20); }
		"JUGG" E 0 { if (rsRock >= 7) return ResolveState("Missile.T12.Meteor"); return ResolveState(null); }
		"JUGG" E 0 { if (target && target.pos.z > pos.z + height + 128) return ResolveState("Missile.T12.AlleUp"); return ResolveState(null); }
		"JUGG" E 0 A_JumpIfCloser(700, "Missile.T12.Dash", true);
	Missile.T12.Mid:
		"JUGG" E 0 A_JumpIfCloser(1400, "Missile.T12.Choice");
		"JUGG" E 0 A_Jump(256, "Missile.T12.Rocks");
	Missile.T12.Dash:
		"JUGG" E 0 { if (rsRock >= 7) return ResolveState("Missile.T12.Meteor"); return ResolveState(null); }
		"JUGG" E 0 { rsRock += 2; }
		"JUGG" EF 4 Bright { A_FaceTarget(); }
		"JUGG" G 4 Bright { bNOPAIN = true; }
		"JUGG" H 9 Bright { A_SkullAttack(37); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 160 - angle); }
		"JUGG" H 2 Bright { A_CustomMeleeAttack(random(50, 120), "", ""); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 180 - angle); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 190 - angle); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 160 - angle); }
		"JUGG" H 2 Bright { A_CustomMeleeAttack(random(50, 120), "", ""); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 180 - angle); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 190 - angle); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 160 - angle); }
		"JUGG" H 2 Bright { A_CustomMeleeAttack(random(50, 120), "", ""); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 180 - angle); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 190 - angle); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 160 - angle); }
		"JUGG" H 2 Bright { A_CustomMeleeAttack(random(50, 120), "", ""); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 180 - angle); }
		"JUGG" H 1 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 190 - angle); }
		"JUGG" J 1 { A_SetSpeed(0); }
		"JUGG" J 1 { A_ScaleVelocity(0.05); }
		Goto Missile.T12.Bam;
	Missile.T12.Bam:
		"JUGG" J 1 Bright { A_StartSound("monster/hamflr", CHAN_BODY); }
		"JUGG" J 8 Bright { A_Quake(30, 60, 0, 120, ""); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 0); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 20); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 40); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 60); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 80); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 100); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 120); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 140); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 160); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 180); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 200); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 220); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 240); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 260); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 280); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 300); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 320); }
		"JUGG" J 0 { A_SpawnProjectile("RS_MolochQuake", 0, -48, 340); }
		"JUGG" JJ 0 { A_SpawnItemEx("RS_Drt1", random(-128, 128), random(-128, 128), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" JJ 0 { A_SpawnItemEx("RS_Drt2", random(-128, 128), random(-128, 128), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" JJ 0 { A_SpawnItemEx("RS_Drt3", random(-128, 128), random(-128, 128), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" FE 7;
		"JUGG" E 0 { rsRock = max(0, rsRock - 1); }
		"JUGG" E 0 { A_ScaleVelocity(1); }
		"JUGG" E 0 { A_SetSpeed(18); }
		"JUGG" E 8 { bNOPAIN = false; }
		Goto See;
	Missile.T12.Maybenot:
		"JUGG" E 0;
		Goto Missile.T12.Mid;
	Missile.T12.Choice:
		"JUGG" E 0 A_Jump(256, "Missile.T12.Rocks", "Missile.T12.HopHop");
		Goto See;
	Missile.T12.Rocks:
		"JUGG" I 8 Bright { A_FaceTarget(); }
		"JUGG" I 2 { A_Quake(30, 60, 0, 900, ""); }
		"JUGG" I 8 Bright { A_SpawnProjectile("RS_WDRock1", 42, 15); }
		"JUGG" I 10 Bright { A_FaceTarget(); }
		"JUGG" J 6 Bright { A_SpawnProjectile("RS_WDRock2", 56, 0, random(-1, 1), CMF_OFFSETPITCH|CMF_ABSOLUTEPITCH, random(2, 6)); }
		"JUGG" FE 6 { A_FaceTarget(); }
		"JUGG" E 0 A_JumpIfCloser(1400, "Missile");
		Goto Missile.T12.Rocks2;
	Missile.T12.Rocks2:
		"JUGG" I 6 Bright { A_FaceTarget(); }
		"JUGG" J 0 { A_SpawnItemEx("RS_Drt1", random(-12, 12), random(-12, 12), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" J 0 { A_SpawnItemEx("RS_Drt2", random(-12, 12), random(-12, 12), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" J 0 { A_SpawnItemEx("RS_Drt3", random(-18, 12), random(-12, 12), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" J 7 Bright { A_SpawnProjectile("RS_WDRock3", 34, 0, random(-2, 2)); }
		"JUGG" J 0 A_CheckSight("See");
		"JUGG" G 6 Bright { A_FaceTarget(); }
		"JUGG" H 0 { A_SpawnItemEx("RS_Drt1", random(-12, 12), random(-12, 12), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" H 0 { A_SpawnItemEx("RS_Drt2", random(-12, 12), random(-12, 12), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" H 0 { A_SpawnItemEx("RS_Drt3", random(-18, 12), random(-12, 12), 0, 5, 0, 3, random(0, 360), 128); }
		"JUGG" H 6 Bright { A_SpawnProjectile("RS_WDRock3", 34, 0, random(-5, 5)); }
		"JUGG" H 0 A_CheckSight("See");
		"JUGG" H 0 A_Jump(22, "Missile.T12.Rocks2.Done");
		"JUGG" H 0 A_JumpIfCloser(700, "Missile.T12.Rocks2.Done");
		"JUGG" H 0 { rsRock++; }
		"JUGG" H 1 A_MonsterRefire(128, "See");
		Goto Missile.T12.Rocks2;
	Missile.T12.Rocks2.Done:
		"JUGG" H 0;
		Goto Missile.T12.Meteor;
	Missile.T12.Meteor:
		"JUGG" E 2 { bINVULNERABLE = true; }
		"JUGG" E 2 { bTHRUACTORS = true; }
		"JUGG" E 2 { bNOGRAVITY = true; }
		"JUGG" E 4 { ThrustThingZ(0, 90, 0, 0); }
		"JUGG" E 1 { A_SetScale(0.7, 1.0); }
		"JUGG" E 1 { A_SetScale(0.5, 1.0); }
		"JUGG" E 1 { A_SetScale(0.3, 1.0); }
		"JUGG" E 1 { A_SetScale(0.1, 1.0); }
		TNT1 AAA 1 { A_Wander(); }
		TNT1 A 3 { A_SetScale(1.0, 1.0); }
		TNT1 AAA 1 { A_Wander(); }
		TNT1 A 0 { A_VileTarget("RS_MeteorStrikeCH"); }
		TNT1 A 4 { A_Warp(AAPTR_TARGET, 0, 0, 128, 0, WARPF_NOCHECKPOSITION); }
		TNT1 A 30;
		"JUGG" E 2 { bINVULNERABLE = false; }
		"JUGG" E 2 { bTHRUACTORS = false; }
		"JUGG" E 2 { bNOGRAVITY = false; }
		"JUGG" E 6 Bright { ThrustThingZ(0, 90, 1, 0); }
		"JUGG" E 6 { A_Explode(random(30, 80), 128); }
		"JUGG" H 0 { rsRock = max(0, rsRock - 6); }
		Goto Missile.T12.Bam;
	Missile.T12.AlleUp:
		"JUGG" E 0 A_JumpIfCloser(700, "Missile.T12.Maybenot");
		"JUGG" E 0 { A_FaceTarget(); }
		"JUGG" E 4 { ThrustThingZ(0, 102, 0, 0); }
		"JUGG" E 0 A_JumpIfHigherOrLower("Missile.T12.AlleUp", "See", 26, -26);
		"JUGG" E 1 A_CheckRange(520, "See", true);
		Goto Missile;
	Missile.T12.HopHop:
		"JUGG" E 0 { A_FaceTarget(); }
		"JUGG" E 0 { ThrustThingZ(0, 16, 0, 0); }
		"JUGG" E 0 { A_Quake(10, 40, 0, 80, ""); }
		"JUGG" CC 7 { A_SkullAttack(32); }
		"JUGG" E 0 A_JumpIfCloser(120, "Missile.T12.Dash");
		Goto Missile.T12.HopHop;
	Missile.T12.BigHop:
		"JUGG" AA 12 { A_SkullAttack(42); }
		"JUGG" I 3 { A_FaceTarget(); }
		"JUGG" E 0 A_Jump(64, "Missile.T12.HopHop");
		Goto Melee.T12;
	Melee.T12:
		"JUGG" EFG 2 { A_FaceTarget(); }
		"JUGG" G 0 { A_StartSound("Juggernaut/Attack", 5); }
		"JUGG" G 0 { A_StartSound("Juggernaut/Pain", 6); }
		"JUGG" H 6 { A_CustomMeleeAttack(random(40, 120), "Juggernaut/Hit", "", "", true); }
		"JUGG" I 4 { A_FaceTarget(); }
		"JUGG" I 0 { A_StartSound("Juggernaut/Attack", 5); }
		"JUGG" I 0 { A_StartSound("Juggernaut/Pain", 6); }
		"JUGG" J 6 { A_CustomMeleeAttack(random(40, 120), "Juggernaut/Hit", "", "", true); }
		"JUGG" J 0 A_Jump(128, "Missile.T12.Dash");
		Goto See;
	Pain.T12:
		"JUGG" E 2;
		"JUGG" E 2 { A_Pain(); }
		"JUGG" E 2 { A_SetSpeed(30); }
		Goto See;
	Death.T12:
		"JUGG" K 6 { A_Scream(); }
		"JUGG" LM 6;
		"JUGG" N 6 { A_StartSound("Juggernaut/Thud", CHAN_BODY); }
		"JUGG" O 6 { A_NoBlocking(); }
		"JUGG" P 6;
		"JUGG" Q -1;
		Stop;
	XDeath.T12:
		Goto Death.T12;
	Raise.T12:
		"JUGG" QPONMLK 5;
		Goto See;
	}
}
