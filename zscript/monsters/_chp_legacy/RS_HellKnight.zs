// =====================================================================
// RS_HellKnight -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\11\11_<code>.txt
// One CHP file per colour; each is a genuinely different creature with
// its OWN sprite set, stats, and attack. Nothing here is inferred,
// tinted, or shared -- every tier below was read out of its CHP file.
// CH decorate/Hellknights.txt was consulted ONLY where CHP leaves a
// state undefined (noted per tier).
//
//   tier  CHP    body   HP    what it actually is
//   T00   11_C   BOS2    500  vanilla bruiser: ball/claw combo
//   T01   11_G   HKGR    600  green: combo, then a second arm's combo
//   T02   11_B   HKBL    666  blue: four-shot LOS-checked bolt string
//   T03   11_CY  HFRY    700  cyan frost knight: six-shot ice string
//                             (flips throwing arm), or the orb+spike
//                             burst; shades, hops and dodges
//   T04   11_P   HKPR    810  royal: two-arm bolt chain, or a
//                             close-range purple fire breath
//   T05   11_Y   BRUS    999  golden bruiser: two-arm rapid fire, or
//                             the spark wind-up into the big ball
//   T06   11_A   HKAB   1850  abyss bruiser: ball spam, bar volley,
//                             or the mist phase (NOPAIN, speed 99)
//   T07   11_F   HKFB    900  fireblu clown: bolt chain or scatter storm
//   T08   11_BR  HWAR    700  Hellion warrior: hellion ball, a real
//                             reflective PARRY, a shield rush and a
//                             point-blank blast
//   T09   11_GY  HKGY    800  gray: moloch nails, mines up close
//   T10   11_R   BRUR   1300  red knightmare: bee DoT / blood bolts,
//                             and a one-shot enrage below 800 HP
//   T11   11_K   BRUC   5555  T-800 BARON: two weapon modes -- missiles
//                             and cluster/nades, or laser + death beam
//   T12   11_W   PHAN   5000  GHOST OF E1M8: spawns its twin, phases
//                             through walls, ghost bombs, spectre
//                             summons, soul bombs
//   TEX   11_KX  KKEX  11000  T-800 BARON MK II: the EX tier. One-time
//                             arming sequence, range-banded weapon
//                             modes, a squash-and-wander WARP, a
//                             damage-resist "Resistance" move, and a
//                             one-shot phase 2 below 5000 HP that
//                             extends the warp and the resistance both
//                             (CommonBlackHKEX2, the file's first ACTOR)
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
//
// RS mechanics preserved: RS_Split (the twin -- CHP puts it on WHITE,
// so the gate moved from T11 to T12) and RS_CallEscort (T07+ imp call,
// rolled in the Missile dispatcher into per-tier Escort clusters).
// =====================================================================

class RS_HellKnight : RS_MonsterMaster replaces HellKnight
{
	const RS_HK_TIER_CLONE  = 12;   // CHP: only the WHITE knight twins
	const RS_HK_TIER_ESCORT = 7;

	private bool rsIsClone;
	private bool rsSplitDone;
	private int  rsRage;            // 11_R's User_Rage2
	private int  rsExReady;         // 11_KX's User_ready -- arming sequence done
	private int  rsExRage;          // 11_KX's User_rage  -- phase 2 fired

	Default
	{
		Health 500;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 50;
		MeleeDamage 13;             // 11_K's A_MeleeAttack
		Monster;
		+FLOORCLIP
		SeeSound "knight/sight";   PainSound "knight/pain";
		DeathSound "knight/death"; ActiveSound "knight/active";
		Obituary "$OB_KNIGHT";
		HitObituary "$OB_KNIGHTHIT";
		Tag "Hell Knight";
	}

	// CHP's real per-colour numbers, read from 11_*.txt. Health is
	// absolute (not a multiplier) -- these are hand-tuned creatures.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 50; r.dmgMul = 1.0;
		int hp = 500; int spd = 8;
		switch (t)
		{
			case 0:  hp = 500;  spd = 8;  r.painChance = 50; r.dmgMul = 1.0; break;
			case 1:  hp = 600;  spd = 9;  r.painChance = 50; r.dmgMul = 1.1; break;
			case 2:  hp = 666;  spd = 10; r.painChance = 50; r.dmgMul = 1.2; break;
			case 3:  hp = 700;  spd = 16; r.painChance = 80; r.dmgMul = 1.3; break;
			case 4:  hp = 810;  spd = 11; r.painChance = 50; r.dmgMul = 1.4; break;
			case 5:  hp = 999;  spd = 10; r.painChance = 50; r.dmgMul = 1.5; break;
			case 6:  hp = 1850; spd = 15; r.painChance = 64; r.dmgMul = 1.8; break;
			case 7:  hp = 900;  spd = 13; r.painChance = 50; r.dmgMul = 1.5; break;
			case 8:  hp = 700;  spd = 12; r.painChance = 50; r.dmgMul = 1.4; break;
			case 9:  hp = 800;  spd = 15; r.painChance = 16; r.dmgMul = 1.6; break;
			case 10: hp = 1300; spd = 11; r.painChance = 50; r.dmgMul = 1.9; break;
			case 11: hp = 5555; spd = 6;  r.painChance = 30; r.dmgMul = 2.5; break;
			case 12: hp = 5000; spd = 8;  r.painChance = 50; r.dmgMul = 3.0; break;
			// TEX -- 11_KX CommonBlackHKEX2, CHP's own numbers.
			case 13: hp = 11000; spd = 14; r.painChance = 30; r.dmgMul = 3.5; break;
			default: return false;
		}
		// Default Health is 500, Default Speed 8 -- express CHP's absolute
		// numbers as multipliers so the base class's recompute-from-
		// defaults contract still holds.
		r.hpMul  = double(hp) / 500.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/HellKnight/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		return "BOS2 HKGR HKBL HFRY HKPR BRUS HKAB HKFB HWAR HKGY BRUR BRUC PHAN KKEX";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:hellknight role:bruiser delivery:heavy delivery:melee element:thermal mobility:ground";
	}

	override bool MinionsDieWithMe()
	{
		return false;
	}

	// -----------------------------------------------------------------
	// THE GHOST OF E1M8. CHP's WHITE knight spawns a second, full-power
	// copy of itself the instant it lands (11_W: A_SpawnItemEx
	// "CommonWhiteHK2"). Not a pet, a genuine duplicate -- deliberately
	// not master-linked, so killing one does nothing to the other.
	//
	// Guarded so the clone doesn't clone: only an original (no clone
	// flag, split not yet done) ever splits.
	// -----------------------------------------------------------------
	void RS_Split()
	{
		if (Tier < RS_HK_TIER_CLONE || rsIsClone || rsSplitDone)
			return;
		rsSplitDone = true;

		Vector3 p = (pos.xy + (cos(angle + 90), sin(angle + 90)) * 40.0, pos.z);
		let mo = RS_HellKnight(Spawn("RS_HellKnight", p, ALLOW_REPLACE));
		if (!mo)
			return;

		mo.rsIsClone   = true;     // it will not split again
		mo.rsSplitDone = true;
		mo.SetTier(Tier, true);
		mo.target = target;
		mo.angle  = angle;
		A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	void RS_CallEscort()
	{
		if (Tier < RS_HK_TIER_ESCORT)
			return;
		if (SummonPack("RS_Imp", 2, 4, -3, 96.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	// ================= FAMILY-WIDE DISPATCHERS =================
	// Only two overrides: the twin fires once on spawn, and the escort
	// roll routes into the tier's OWN Escort cluster (no shared body,
	// no runtime sprite -- every frame below is a literal token).
	Spawn:
		TNT1 A 0 NoDelay { RS_Split(); }
		TNT1 A 0 { return TierState("Spawn"); }
		Goto Spawn.T00;
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_HK_TIER_ESCORT && random(0, 255) < 48)
			{
				State st = FindStateByString("Escort." .. TierLabel(Tier), true);
				if (st) return st;
			}
			return TierState("Missile");
		}
		Goto See;

	// ================= T00 COMMON (11_C) =================
	// Vanilla bruiser. Parent CommonHK adds nothing CHP doesn't restate.
	Spawn.T00:
		"BOS2" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"BOS2" AABBCCDD 3 { A_Chase(); }
		Loop;
	// CHP stacks Melee: on Missile: -- one combo covers both ranges.
	Melee.T00:
	Missile.T00:
		"BOS2" EF 8 { A_FaceTarget(); }
		"BOS2" G 8 { A_CustomComboAttack("RS_BaronBall", 32, 10 * random(1, 8), "baron/melee"); }
		Goto See;
	Pain.T00:
		"BOS2" H 2;
		"BOS2" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
		"BOS2" I 8;
		"BOS2" J 8 { A_Scream(); }
		"BOS2" K 8;
		"BOS2" L 8 { A_NoBlocking(); }
		"BOS2" MN 8;
		"BOS2" O -1;
		Stop;
	XDeath.T00:
		"BOS2" I 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"BOS2" I 0 { A_Stop(); }
		"BOS2" I 8;
		"HKGB" A 0 { A_ScreamAndUnblock(); }
		"HKGB" A -1;
		Stop;
	Raise.T00:
		"BOS2" O 5;
		"BOS2" NMLKJI 5;
		Goto See;

	// ================= T01 GREEN (11_G) =================
	// Combo, then a chance at the second arm's combo, which can loop
	// back. (CHP's Missile2 branches through an ACS intercept check --
	// stripped; the Miss2 arm it falls back to is what ships.)
	Spawn.T01:
		"HKGR" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"HKGR" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T01:
	Missile.T01:
		"HKGR" EF 8 { A_FaceTarget(); }
		"HKGR" G 8 { A_CustomComboAttack("RS_BaronBall", 32, 11 * random(1, 8), "baron/melee/c"); }
		"HKGR" G 2 A_Jump(164, "Missile.T01.Second");
		Goto See;
	Missile.T01.Second:
		"HKGR" PQ 8 { A_FaceTarget(); }
		// RESTORED (rs_19 / L5). CHP 11_G.txt:28-29 gates this behind
		// CH_Intercept and fires BaronMissile -- a ProjInt_Brute LED shot.
		// The import kept only the Miss2 body below. Falls through to it
		// when the option is off, exactly as CH's jump does.
		"HKGR" Q 0
		{
			if (!FireLeadShot("RS_BaronBall", 32.0, 0.0))
				return ResolveState("Missile.T01.Miss2");
			return ResolveState(null);
		}
		"HKGR" R 8;
		"HKGR" R 2 A_Jump(128, "Missile.T01");
		Goto See;
	Missile.T01.Miss2:
		"HKGR" R 8 { A_CustomComboAttack("RS_BaronBall", 32, 11 * random(1, 8), "baron/melee/c"); }
		"HKGR" R 2 A_Jump(128, "Missile.T01");
		Goto See;
	Pain.T01:
		"HKGR" H 2;
		"HKGR" H 2 { A_Pain(); }
		Goto See;
	Death.T01:
		"HKGR" I 8;
		"HKGR" J 8 { A_Scream(); }
		"HKGR" K 8;
		"HKGR" L 8 { A_NoBlocking(); }
		"HKGR" MN 8;
		"HKGR" O -1;
		Stop;
	XDeath.T01:
		"HKGR" I 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"HKGR" I 0 { A_Stop(); }
		"HKGR" I 8;
		"HKG2" A 0 { A_ScreamAndUnblock(); }
		"HKG2" A -1;
		Stop;
	Raise.T01:
		"HKGR" O 5;
		"HKGR" NMLKJI 5;
		Goto See;

	// ================= T02 BLUE (11_B) =================
	// A four-shot bolt string, each link LOS-checked so it stops the
	// moment you break sight.
	Spawn.T02:
		"HKBL" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"HKBL" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T02:
		"HKBL" EF 8;
		"HKBL" G 8 { A_CustomMeleeAttack(random(10, 70), "baron/melee"); }
		Goto See;
	Missile.T02:
		"HKBL" EF 8 { A_FaceTarget(); }
		"HKBL" G 8 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-1, 1)); }
		"HKBL" G 0 A_CheckSight("See");
		"HKBL" PQ 6 { A_FaceTarget(); }
		"HKBL" R 6 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-3, 3)); }
		"HKBL" G 0 A_CheckSight("See");
		"HKBL" EF 4 { A_FaceTarget(); }
		"HKBL" G 4 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-5, 5)); }
		"HKBL" PQ 3 { A_FaceTarget(); }
		"HKBL" R 3 { A_SpawnProjectile("RS_BaronsBlueBalls", 32, 3, random(-7, 7)); }
		Goto See;
	Pain.T02:
		"HKBL" H 2;
		"HKBL" H 2 { A_Pain(); }
		Goto See;
	Death.T02:
		"HKBL" I 8;
		"HKBL" J 8 { A_Scream(); }
		"HKBL" K 8;
		"HKBL" L 8 { A_NoBlocking(); }
		"HKBL" MN 8;
		"HKBL" O -1;
		Stop;
	XDeath.T02:
		"HKBL" I 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"HKBL" I 0 { A_Stop(); }
		"HKBL" I 8;
		"HKG3" A 0 { A_ScreamAndUnblock(); }
		"HKG3" A -1;
		Stop;
	Raise.T02:
		"HKBL" O 5;
		"HKBL" NMLKJI 5;
		Goto See;

	// ================= T03 CYAN (11_CY) =================
	// The frost knight. Six ice shots, flipping its X scale between each
	// so it visibly swaps throwing arm; or the orb + spike burst. It
	// leaves shades behind it when it dodges, and it JUMPS.
	Spawn.T03:
		"HFRY" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"HFRY" A 0 { A_SetScale(1.0, 1.0); }
		"HFRY" AABBCCDD 3 { A_Chase(); }
		"HFRY" A 0 A_Jump(64, "See.T03.Fast");
		"HFRY" A 0 A_Jump(232, "See.T03.Hop");
		Loop;
	See.T03.Hop:
		// CHP gates this on an ACS bounce counter -- stripped, the LOS
		// check that follows is the real condition.
		"HFRY" A 0 A_JumpIfInTargetLOS("See.T03.Jumpy", 0, JLOSF_DEADNOJUMP, 750);
		Goto See;
	See.T03.Jumpy:
		"HFRY" A 2 { A_FastChase(); }
		"HFRY" A 1 { A_ChangeVelocity(0, 0, 8, CVF_REPLACE); }
		"HFRY" A 3 { A_ChangeVelocity(0, 12, 0, CVF_RELATIVE); }
		"HFRY" A 1 { A_ChangeVelocity(0, 0, 4, CVF_REPLACE); }
		"HFRY" A 1 { A_ChangeVelocity(24, 0, 0, CVF_RELATIVE); }
		Goto See;
	See.T03.Fast:
		"HFRY" A 0 { A_SetScale(1.0, 1.0); }
		"HFRY" AABBCCDD 2 { A_FastChase(); }
		Goto See;
	Missile.T03:
		"HFRY" E 0 A_Jump(128, "Missile.T03.Burst");
		"HFRY" EF 6 { A_FaceTarget(); }
		"HFRY" G 6 { A_SpawnProjectile("RS_IceHKShot", 42, 0, 0); }
		"HFRY" A 0 A_CheckSight("See");
		"HFRY" A 0 { A_SetScale(-1.0, 1.0); }
		"HFRY" EF 6 { A_FaceTarget(); }
		"HFRY" G 6 { A_SpawnProjectile("RS_IceHKShot", 42, 0, random(-3, 3)); }
		"HFRY" A 0 { A_SetScale(1.0, 1.0); }
		"HFRY" A 0 A_CheckSight("See");
		"HFRY" EF 4 { A_FaceTarget(); }
		"HFRY" G 5 { A_SpawnProjectile("RS_IceHKShot", 42, 0, random(-1, 1)); }
		"HFRY" A 0 A_CheckSight("See");
		"HFRY" A 0 { A_SetScale(-1.0, 1.0); }
		"HFRY" EF 4 { A_FaceTarget(); }
		"HFRY" G 5 { A_SpawnProjectile("RS_IceHKShot", 42, 0, random(-5, 5)); }
		"HFRY" A 0 { A_SetScale(1.0, 1.0); }
		"HFRY" A 0 A_CheckSight("See");
		"HFRY" EF 3 { A_FaceTarget(); }
		"HFRY" G 3 { A_SpawnProjectile("RS_IceHKShot", 42, 0, random(-3, 3)); }
		"HFRY" A 0 A_CheckSight("See");
		"HFRY" A 0 { A_SetScale(-1.0, 1.0); }
		"HFRY" EF 3 { A_FaceTarget(); }
		"HFRY" G 3 { A_SpawnProjectile("RS_IceHKShot", 42, 0, random(-7, 7)); }
		"HFRY" A 0 { A_SetScale(1.0, 1.0); }
		Goto See;
	Missile.T03.Burst:
		"HFRY" P 8 { A_FaceTarget(); }
		"HFRY" PP 6 { A_SpawnProjectile("RS_CyanHKShade", 20, 0, 180); }
		"HFRY" Q 8 { A_SpawnProjectile("RS_IceOrbCyanHK", 60, 0, 0); }
		"HFRY" AAAAAAAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 12, -21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"HFRY" AAAAAAAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 12, 21, 24, random(12, 33), 0, random(1, 3), frandom(-5, 5)); }
		"HFRY" AAAAAAAAAA 0 { A_SpawnProjectile("RS_SpikeCyanRev", 60, 0, randompick(-10, -5, 0, 5, 10)); }
		"HFRY" A 0 A_Jump(64, "Missile.T03.Dodge1", "Missile.T03.Dodge2");
		Goto See;
	Melee.T03:
		"HFRY" EF 8 { A_FaceTarget(); }
		"HFRY" G 8 { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		"HFRY" AAAAAAAAAAAAAAAA 0 { A_SpawnProjectile("RS_SpikeCyanRev", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		"HFRY" A 0 A_Jump(64, "Missile.T03");
		"HFRY" A 0 A_Jump(64, "Missile.T03.Dodge1", "Missile.T03.Dodge2");
		Goto See;
	Missile.T03.Dodge1:
		"HFRY" A 0 { A_SpawnProjectile("RS_CyanHKShade", 20, 0, 180); }
		"HFRY" A 1 { A_ChangeVelocity(0, 0, 3, CVF_REPLACE); }
		"HFRY" A 1 { A_ChangeVelocity(0, -29, 0, CVF_RELATIVE); }
		Goto See.T03.Fast;
	Missile.T03.Dodge2:
		"HFRY" A 0 { A_SpawnProjectile("RS_CyanHKShade", 20, 0, 180); }
		"HFRY" A 1 { A_ChangeVelocity(0, 0, 3, CVF_REPLACE); }
		"HFRY" A 1 { A_ChangeVelocity(0, 29, 0, CVF_RELATIVE); }
		Goto See.T03.Fast;
	Pain.T03:
		"HFRY" A 0 { A_SetScale(1.0, 1.0); }
		"HFRY" H 2 { A_SpawnProjectile("RS_CyanHKShade", 20, 0, 180); }
		"HFRY" H 2 { A_Pain(); }
		"HFRY" A 0 A_Jump(128, "Missile.T03.Dodge1", "Missile.T03.Dodge2");
		Goto See;
	Death.T03:
		"HFRY" I 8 { A_Scream(); }
		"HFRY" JK 8;
		"HFRY" L 8 { A_NoBlocking(); }
		"HFRY" MN 8;
		"HFRY" N 0 { A_StartSound("misc/icebreak"); }
		"HFRY" N 1 { A_Burst("IceChunk"); }
		"HFRY" O -1;
		Stop;

	// ================= T04 PURPLE (11_P) =================
	// Two-arm bolt chain at range; inside 300 units it switches to a
	// three-shot purple fire breath that refires off A_MonsterRefire.
	Spawn.T04:
		"HKPR" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"HKPR" A 0 { A_SetScale(1.0, 1.0); }
		"HKPR" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T04:
		"HKPR" EF 8;
		"HKPR" G 8 { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		Goto See;
	Missile.T04:
		"HKPR" E 0 A_JumpIfCloser(300, "Missile.T04.Fire");
		"HKPR" E 0 A_Jump(256, "Missile.T04.Bolt3");
		Goto See;
	Missile.T04.Bolt3:
		"HKPR" A 0 { A_SetScale(1.0, 1.0); }
		"HKPR" EF 8 { A_FaceTarget(); }
		"HKPR" G 8 { A_SpawnProjectile("RS_HKBolt2", 32, 3, random(-1, 1)); }
		"HKPR" G 0 A_Jump(128, "Missile.T04.Bolt4");
		Goto See;
	Missile.T04.Bolt4:
		"HKPR" A 0 { A_SetScale(-1.0, 1.0); }
		"HKPR" EF 8 { A_FaceTarget(); }
		"HKPR" G 8 { A_SpawnProjectile("RS_HKBolt2", 32, 3, random(-1, 1)); }
		"HKPR" G 0 A_Jump(76, "Missile.T04.Bolt3");
		Goto See;
	Missile.T04.Fire:
		"HKPR" I 1 A_JumpIfCloser(300, "Missile.T04.Breath");
		"HKPR" I 1 A_Jump(256, "See");
		Goto See;
	Missile.T04.Breath:
		"HKPR" I 4 Bright { A_FaceTarget(); }
		"HKPR" I 2 Bright { A_SpawnProjectile("RS_PurpFire2", 32, 1, random(-1, 1)); }
		"HKPR" I 1 Bright { A_FaceTarget(); }
		"HKPR" I 1 Bright { A_SpawnProjectile("RS_PurpFire2", 32, 1, random(-3, 3)); }
		"HKPR" I 1 Bright { A_FaceTarget(); }
		"HKPR" I 1 Bright { A_SpawnProjectile("RS_PurpFire2", 32, 1, random(-5, 5)); }
		"HKPR" I 1 Bright A_MonsterRefire(150, "See");
		Goto Missile.T04.Fire;
	Pain.T04:
		"HKPR" J 2 { A_SetScale(1.0, 1.0); }
		"HKPR" J 2 { A_Pain(); }
		Goto See;
	Death.T04:
		"HKPR" K 8 { A_SetScale(1.0, 1.0); }
		"HKPR" L 8 { A_Scream(); }
		"HKPR" M 8;
		"HKPR" O 8 { A_NoBlocking(); }
		"HKPR" QS 8;
		"HKPR" T -1;
		Stop;
	XDeath.T04:
		"HKPR" J 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"HKPR" J 0 { A_Stop(); }
		"HKPR" J 8 { A_SetScale(1.0, 1.0); }
		"HKG4" A 0 { A_ScreamAndUnblock(); }
		"HKG4" A -1;
		Stop;
	Raise.T04:
		"HKPR" TSQOMLK 8;
		Goto See;

	// ================= T05 YELLOW (11_Y) =================
	// The golden bruiser. Alternating-arm rapid fire, or the spark
	// wind-up that ends in the big ball.
	Spawn.T05:
		"BRUS" AB 10 Bright { A_Look(); }
		Loop;
	See.T05:
		"BRUS" AABBCCDD 3 Bright { A_Chase(); }
		Loop;
	Melee.T05:
		"BRUS" EF 6 Bright { A_FaceTarget(); }
		"BRUS" G 6 Bright { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		"BRUS" G 1 Bright A_Jump(88, "Missile");
		Goto See;
	Missile.T05:
		"BRUS" E 0 A_Jump(256, "Missile.T05.Rapid", "Missile.T05.Boom");
		"BRUS" E 1 Bright;
		Goto See;
	Missile.T05.Rapid:
		"BRUS" EF 4 Bright { A_FaceTarget(); }
		"BRUS" G 2 Bright { A_SpawnProjectile("RS_FireHKBall1", 32, 2, random(-1, 1)); }
		"BRUS" G 1 Bright A_MonsterRefire(128, "See");
		Goto Missile.T05.Rapid2;
	Missile.T05.Rapid2:
		"BRUS" HI 4 Bright { A_FaceTarget(); }
		"BRUS" J 2 Bright { A_SpawnProjectile("RS_FireHKBall1", 32, 2, random(-1, 1)); }
		"BRUS" J 1 Bright A_MonsterRefire(128, "See");
		Goto Missile.T05.Rapid;
	Missile.T05.Boom:
		"BRUS" K 1 Bright { A_FaceTarget(); }
		"BRUS" K 12 Bright { A_StartSound("superbaron/scream"); }
		"BRUS" K 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 52, 34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" K 0 { A_SpawnProjectile("RS_SparkPuff1", 52, -34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" K 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 52, 34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" K 0 { A_SpawnProjectile("RS_SparkPuff1", 52, -34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" K 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 52, 34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" K 0 { A_SpawnProjectile("RS_SparkPuff1", 52, -34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" K 1 Bright { A_SpawnProjectile("RS_SparkPuff1", 52, 34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" K 0 { A_SpawnProjectile("RS_SparkPuff1", 52, -34, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"BRUS" KL 12 Bright { A_FaceTarget(); }
		"BRUS" M 10 Bright { A_SpawnProjectile("RS_BigHK", 32, 0); }
		"BRUS" M 8 Bright;
		Goto See;
	Pain.T05:
		"BRUS" N 5 Bright { A_Pain(); }
		"BRUS" N 1 Bright A_Jump(64, "Missile.T05.Boom");
		Goto See;
	Death.T05:
		"BRUD" A 6 Bright { A_Scream(); }
		"BRUD" BCD 4 Bright;
		"BRUD" EFG 4 Bright;
		"BRUD" H 4 Bright { A_Fall(); }
		"BRUD" IJKLMNOP 4 Bright;
		"BRUD" QRSTUV 4;
		"BRUD" W -1;
		Stop;
	Raise.T05:
		"BRUD" WVUTSRQPONMLKJIHGFEDCBA 2;
		Goto See;

	// ================= T06 ABYSS (11_A) =================
	// Ball spam that closes into the bar volley, or the MIST phase:
	// NOPAIN, translucent, speed 99, wandering while it fogs the room.
	Spawn.T06:
		"HKAB" AB 10 Bright { A_Look(); }
		Loop;
	See.T06:
		"HKAB" A 0 { A_SetSpeed(15); }
		"HKAB" AABBCCDD 3 Bright { A_Chase(); }
		Loop;
	See.T06.Wet:
		"HKAB" A 0 { A_SetSpeed(15); }
		"HKAB" AABB 3 Bright { A_Chase(); }
		"HKAB" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"HKAB" CCDD 3 Bright { A_Chase(); }
		"HKAB" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"HKAB" A 0 A_Jump(64, "Missile.T06.Dodge1", "Missile.T06.Dodge2");
		Loop;
	Missile.T06.Dodge1:
		"HKAB" A 1 { A_ChangeVelocity(0, 0, 3, CVF_REPLACE); }
		"HKAB" AAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-328, 328), random(-328, 328), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"HKAB" A 1 { A_ChangeVelocity(0, -29, 0, CVF_RELATIVE); }
		Goto See.T06.Wet;
	Missile.T06.Dodge2:
		"HKAB" A 1 { A_ChangeVelocity(0, 0, 3, CVF_REPLACE); }
		"HKAB" AAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-328, 328), random(-328, 328), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"HKAB" A 1 { A_ChangeVelocity(0, 29, 0, CVF_RELATIVE); }
		Goto See.T06.Wet;
	Melee.T06:
		"HKAB" E 4 Bright { A_FaceTarget(); }
		"HKAB" A 0 { A_SpawnItemEx("RS_SplashAbyss", 4, 26, 46); }
		"HKAB" F 4 Bright { A_FaceTarget(); }
		"HKAB" A 0 { A_SpawnItemEx("RS_SplashAbyss", 4, 13, 30); }
		"HKAB" G 5 Bright { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		"HKAB" AAAAAAAAAAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		"HKAB" G 1 Bright A_Jump(88, "Missile");
		Goto See.T06.Wet;
	Missile.T06:
		"HKAB" E 0 A_JumpIfCloser(1500, "Missile.T06.Choices");
		Goto Missile.T06.Spam;
	Missile.T06.Choices:
		"HKAB" E 0 A_JumpIfCloser(900, "Missile.T06.Choices2");
		"HKAB" E 0 A_Jump(256, "Missile.T06.Spam", "Missile.T06.Bar");
		Goto See.T06.Wet;
	Missile.T06.Choices2:
		"HKAB" E 0 A_Jump(256, "Missile.T06.Spam", "Missile.T06.Mist", "Missile.T06.Bar");
		Goto Missile.T06.Spam;
	Missile.T06.Spam:
		"HKAB" EF 4 Bright { A_FaceTarget(); }
		"HKAB" G 2 Bright { A_SpawnProjectile("RS_AbyssHKBall", 32, 2, random(-1, 1)); }
		"HKAB" A 0 A_Jump(64, "Missile.T06.CL2");
		"HKAB" G 1 Bright A_MonsterRefire(128, "See");
		Goto Missile.T06.Spam2;
	Missile.T06.Spam2:
		"HKAB" HI 4 Bright { A_FaceTarget(); }
		"HKAB" J 2 Bright { A_SpawnProjectile("RS_AbyssHKBall", 32, 2, random(-1, 1)); }
		"HKAB" A 0 A_Jump(64, "Missile.T06.CL2");
		"HKAB" J 1 Bright A_MonsterRefire(128, "See");
		Goto Missile.T06.Spam;
	Missile.T06.CL2:
		"HKAB" E 0 A_JumpIfCloser(800, "Missile.T06.Bar");
		Goto Missile.T06.Spam;
	Missile.T06.Bar:
		"HKAB" K 7 Bright { A_FaceTarget(); }
		"HKAB" KL 6 Bright { A_FaceTarget(); }
		"HKAB" M 1 Bright { A_SpawnProjectile("RS_AbyssHKBall", 32, 0, 0); }
		"HKAB" AAA 0 { A_SpawnProjectile("RS_AbyssHKBall", 32, 0, random(1, 14)); }
		"HKAB" AAA 0 { A_SpawnProjectile("RS_AbyssHKBall", 32, 0, random(-14, -1)); }
		"HKAB" M 16 Bright;
		Goto See.T06.Wet;
	Missile.T06.Mist:
		"HKAB" K 1 Bright { A_FaceTarget(); }
		"HKAB" K 12 Bright { A_StartSound("superbaron/scream"); }
		"HKAB" KL 12 Bright { A_FaceTarget(); }
		"HKAB" M 1 Bright { bNOPAIN = true; }
		"HKAB" M 1 { A_SetTranslucent(0.45); }
		"HKAB" M 1 { A_SetSpeed(99); }
		"HKAB" MMMMMMMM 0 { A_SpawnItemEx("RS_AbyssHKMist", random(-256, 256), random(-256, 256), 6, random(1, 33), 0, 0, random(-359, 359), SXF_NOCHECKPOSITION); }
		"HKAB" MMMMMMMM 1 { A_SpawnItemEx("RS_AbyssHKMist", random(-256, 256), random(-256, 256), 6, random(1, 33), 0, 0, random(-359, 359), SXF_NOCHECKPOSITION); }
		"HKAB" MMMMMMM 1 { A_Wander(); }
		"HKAB" MMMMMMMMMM 0 { A_SpawnItemEx("RS_AbyssHKMist", random(-256, 256), random(-256, 256), 6, random(1, 33), 0, 0, random(-359, 359), SXF_NOCHECKPOSITION); }
		"HKAB" MMMMMMMMMM 1 { A_SpawnItemEx("RS_AbyssHKMist", random(-256, 256), random(-256, 256), 6, random(1, 33), 0, 0, random(-359, 359), SXF_NOCHECKPOSITION); }
		"HKAB" MMMMMMMM 1 { A_Wander(); }
		"HKAB" MMMMMMMMM 0 { A_SpawnItemEx("RS_AbyssHKMist", random(-256, 256), random(-256, 256), 6, random(1, 33), 0, 0, random(-359, 359), SXF_NOCHECKPOSITION); }
		"HKAB" MMMMMMMMM 1 { A_SpawnItemEx("RS_AbyssHKMist", random(-256, 256), random(-256, 256), 6, random(1, 33), 0, 0, random(-359, 359), SXF_NOCHECKPOSITION); }
		"HKAB" MMMMMMMMMM 1 { A_Wander(); }
		"HKAB" M 1 Bright;
		"HKAB" M 1 { A_SetTranslucent(1.0); }
		"HKAB" M 1 { A_SetSpeed(15); }
		"HKAB" M 10 Bright;
		"HKAB" M 8 Bright { bNOPAIN = false; }
		"HKAB" A 0 A_Jump(64, "Missile.T06.Dodge1", "Missile.T06.Dodge2");
		Goto See.T06.Wet;
	Pain.T06:
		"HKAB" N 5 Bright { A_Pain(); }
		"HKAB" A 0 { A_SetSpeed(15); }
		"HKAB" N 1 Bright A_Jump(64, "Missile.T06.Choices", "Missile.T06.Dodge1", "Missile.T06.Dodge2");
		Goto See.T06.Wet;
	Death.T06:
		"HKA2" A 6 Bright { A_Scream(); }
		"HKA2" BCDEFG 4 Bright;
		"HKA2" H 4 Bright { A_Fall(); }
		"HKA2" IJKLMNOP 4 Bright;
		"HKA2" QRSTUV 4;
		"HKA2" W -1;
		Stop;
	Escort.T06:
		"HKAB" EF 8 { A_FaceTarget(); }
		"HKAB" G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ================= T07 FIREBLU (11_F) =================
	// Bolt chain, or the wide scatter storm.
	Spawn.T07:
		"HKFB" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"HKFB" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T07:
		"HKFB" EF 8;
		"HKFB" G 8 { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		"HKFB" PQ 8;
		"HKFB" R 8 { A_CustomMeleeAttack(random(20, 90), "baron/melee"); }
		Goto See;
	Missile.T07:
		"HKFB" E 0 A_Jump(255, "Missile.T07.Bolt", "Missile.T07.Storm");
		Goto See;
	Missile.T07.Bolt:
		"HKFB" EF 6 { A_FaceTarget(); }
		"HKFB" G 6 { A_SpawnProjectile("RS_FireBluHKBall1", 32, 3, random(-1, 1)); }
		"HKFB" PQ 5 { A_FaceTarget(); }
		"HKFB" R 5 { A_SpawnProjectile("RS_FireBluHKBall1", 32, 3, random(-9, 9)); }
		"HKFB" R 0 A_Jump(76, "Missile.T07.Bolt");
		Goto See;
	Missile.T07.Storm:
		"HKFB" H 12 Bright { A_FaceTarget(); }
		"HKFB" HHHHHH 0 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), 0, random(-15, 15)); }
		"HKFB" HHHH 1 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), 0, random(-15, 15)); }
		"HKFB" HHHHHH 0 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), 0, random(-15, 15)); }
		"HKFB" HHHH 1 Bright { A_SpawnProjectile("RS_FireBluHKBall2", 54, 1, random(-25, 25), 0, random(-15, 15)); }
		"HKFB" H 6 Bright;
		"HKFB" H 4;
		Goto See;
	Pain.T07:
		"HKFB" H 2;
		"HKFB" H 2 { A_Pain(); }
		Goto See;
	Death.T07:
		"HKFB" I 8;
		"HKFB" J 8 { A_Scream(); }
		"HKFB" K 8;
		"HKFB" L 8 { A_NoBlocking(); }
		"HKFB" MN 8;
		"HKFB" O -1;
		Stop;
	XDeath.T07:
		"HKFB" J 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"HKFB" J 0 { A_Stop(); }
		"HKFB" J 8;
		"HKFB" U 0 { A_ScreamAndUnblock(); }
		"HKFB" U -1;
		Stop;
	Raise.T07:
		"HKFB" ONMLKJI 8;
		Goto See;
	Escort.T07:
		"HKFB" EF 8 { A_FaceTarget(); }
		"HKFB" G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ================= T08 BROWN (11_BR) =================
	// The Hellion warrior. It PARRIES -- a real reflective shield that
	// sends shots back -- then rushes behind it and detonates at
	// point-blank. The whole tier is one interlocked loop.
	Spawn.T08:
		"HWAR" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"HWAR" AABB 3 { A_Chase(); }
		TNT1 A 0 A_Jump(32, "Missile.T08.MaybeParry1");
	See.T08.Half:
		"HWAR" CCDD 3 { A_Chase(); }
		TNT1 A 0 A_Jump(32, "Missile.T08.MaybeParry2");
		Goto See;
	Missile.T08.MaybeParry1:
		TNT1 A 0 A_JumpIfInTargetLOS("Missile.T08.Parry", 0, JLOSF_DEADNOJUMP, 1200, 200);
		Goto See.T08.Half;
	Missile.T08.MaybeParry2:
		TNT1 A 0 A_JumpIfInTargetLOS("Missile.T08.Parry", 0, JLOSF_DEADNOJUMP, 1200, 200);
		Goto See;
	Missile.T08.MaybeParry3:
		TNT1 A 0 A_JumpIfInTargetLOS("Missile.T08.Parry", 0, JLOSF_DEADNOJUMP, 1200, 200);
		Goto Missile.T08.Fire;
	Missile.T08:
		"HWAR" E 1 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(32, "Missile.T08.MaybeParry3");
		"HWAR" E 1 { A_FaceTarget(); }
		"HWAR" E 8 { A_FaceTarget(); }
	Missile.T08.Fire:
		"HWAR" F 8 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(88, "Missile.T08.MeleeMaybe");
		"HWAR" G 6 { A_SpawnProjectile("RS_HellionBall", 32, 0); }
		TNT1 A 0 A_JumpIfCloser(88, "Melee.T08");
		Goto See;
	Missile.T08.MeleeMaybe:
		TNT1 A 0 A_JumpIfCloser(88, "Melee.T08.Swing");
		"HWAR" FJ 2;
		Goto Missile.T08.Rush;
	Missile.T08.Parry:
		"HWAR" HHII 3 { A_FaceTarget(); }
		"HWAR" H 1 { A_FaceTarget(); }
		"HWAR" I 3 { A_SpawnItemEx("RS_BrownHKShield", 18, 0, 24, 1, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"HWAR" HIHI 3;
		TNT1 A 0 A_JumpIfCloser(252, "Missile.T08.Rush");
		TNT1 A 0 A_JumpIfCloser(128, "Missile.T08.BlastEm");
		"HWAR" IHII 3;
		Goto See;
	Melee.T08:
		"HWAR" EF 8 { A_FaceTarget(); }
	Melee.T08.Swing:
		"HWAR" G 8 { A_CustomMeleeAttack(random(10, 60), "Baron/Melee", "none"); }
		"HWAR" H 6 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(252, "Missile.T08.Rush");
		Goto See;
	Missile.T08.Rush:
		"HWAR" I 12 { A_ChangeVelocity(32, 0, 0, CVF_RELATIVE); }
		"HWAR" H 3 Bright { A_SpawnProjectile("RS_BrownHKShieldCheck", 32, 0); }
		TNT1 A 0 A_JumpIfCloser(176, "Missile.T08.BlastEm");
		"HWAR" H 1 { A_SpawnProjectile("RS_HKRedDeath", 32, 0); }
		Goto See;
	Missile.T08.BlastEm:
		"HWAR" H 1 Bright;
		"HWAR" H 1 { A_SpawnProjectile("RS_HKRedDeath", 32, 0); }
		"HWAR" H 2 { A_VileAttack("bomb/boom", 5, 5, 128, 1.35); }
		"HWAR" H 1 { A_RadiusThrust(2040, 400, RTF_NOTMISSILE); }
		Goto See;
	Pain.T08:
		"HWAR" I 0 { A_SetSpeed(12); }
		"HWAR" J 6 { A_Pain(); }
		"HWAR" J 1 A_Jump(84, "Missile.T08.Parry");
		Goto See;
	Death.T08:
		"HWAR" K 0 { A_FaceTarget(); }
		"HWAR" K 5 { A_SpawnItemEx("RS_HellWarriorShield", 0, 0, 25, 6, 0, 0, 60, 128); }
		"HWAR" L 5 { A_Scream(); }
		"HWAR" M 5;
		"HWAR" N 5 { A_NoBlocking(); }
		"HWAR" OPQRS 5;
		"HWAR" T -1;
		Stop;
	XDeath.T08:
		"HWAR" J 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"HWAR" J 0 { A_Stop(); }
		"HWAR" J 8;
		"HWAR" U 0 { A_ScreamAndUnblock(); }
		"HWAR" U -1;
		Stop;
	Raise.T08:
		"HWAR" QPONMLK 5;
		Goto See;
	Escort.T08:
		"HWAR" EF 8 { A_FaceTarget(); }
		"HWAR" G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ================= T09 GRAY (11_GY) =================
	// Two-arm moloch nails at range; inside 600 units, mines.
	Spawn.T09:
		"HKGY" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"HKGY" AABBCCDD 3 { A_Chase(); }
		Loop;
	Melee.T09:
	Missile.T09:
		"HKGY" E 0 A_JumpIfCloser(600, "Missile.T09.Mines");
		"HKGY" E 0 A_Jump(256, "Missile.T09.Bolt3");
		Goto See;
	Missile.T09.Bolt3:
		"HKGY" EF 8 { A_FaceTarget(); }
		"HKGY" G 8 { A_SpawnProjectile("RS_MolochNail", 32, 3, random(-1, 1)); }
		"HKGY" G 0 A_Jump(128, "Missile.T09.Bolt4");
		Goto See;
	Missile.T09.Bolt4:
		"HKGY" PQ 8 { A_FaceTarget(); }
		"HKGY" R 8 { A_SpawnProjectile("RS_MolochNail", 32, 3, random(-1, 1)); }
		"HKGY" R 0 A_Jump(76, "Missile.T09.Bolt3");
		Goto See;
	Missile.T09.Mines:
		"HKGY" H 10 Bright { A_FaceTarget(); }
		"HKGY" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-1, 1)); }
		"HKGY" H 12 Bright { A_FaceTarget(); }
		"HKGY" H 9 Bright { A_SpawnProjectile("RS_MinesHK", 54, 1, random(-25, 25)); }
		Goto See;
	Pain.T09:
		"HKGY" H 2;
		"HKGY" H 2 { A_Pain(); }
		Goto See;
	Death.T09:
		"HKGY" I 8;
		"HKGY" J 8 { A_Scream(); }
		"HKGY" K 8;
		"HKGY" L 8 { A_NoBlocking(); }
		"HKGY" MN 8;
		"HKGY" O -1;
		Stop;
	XDeath.T09:
		"HKGY" J 0 { A_SpawnItemEx("RS_HKSplashDed", 0, 2, 47, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_USEBLOODCOLOR); }
		"HKGY" J 0 { A_Stop(); }
		"HKGY" J 8;
		"HKGY" U 0 { A_ScreamAndUnblock(); }
		"HKGY" U -1;
		Stop;
	Raise.T09:
		"HKGY" O 8;
		"HKGY" NMLKJI 8;
		Goto See;
	Escort.T09:
		"HKGY" EF 8 { A_FaceTarget(); }
		"HKGY" G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ================= T10 RED (11_R) =================
	// The knightmare. Blood bolts off both arms, a bee-swarm DoT, and a
	// ONE-TIME enrage below 800 HP (NOPAIN + MISSILEEVENMORE). CHP holds
	// that once-only with a user var; here it's rsRage.
	Spawn.T10:
		"BRUR" AB 10 Bright { A_Look(); }
		Loop;
	See.T10:
		"BRUR" AABBCCDD 3 Bright { A_Chase(); }
		Loop;
	Missile.T10.Dodge1:
		"BRUR" A 5 { A_ChangeVelocity(0, 20, 0, CVF_RELATIVE); }
		Goto See;
	Missile.T10.Dodge2:
		"BRUR" A 5 { A_ChangeVelocity(0, -20, 0, CVF_RELATIVE); }
		Goto See;
	Melee.T10:
		"BRUR" EF 6 Bright { A_FaceTarget(); }
		"BRUR" G 6 Bright { A_CustomMeleeAttack(random(20, 99), "baron/melee"); }
		"BRUR" G 1 Bright A_Jump(88, "Missile");
		Goto See;
	Missile.T10:
		"BRUR" A 0 Bright A_JumpIfHealthLower(800, "Missile.T10.Enrage");
	Missile.T10.Pick:
		"BRUR" A 1 Bright A_Jump(255, "Missile.T10.DoT", "Missile.T10.Bolt");
		Goto See;
	Missile.T10.DoT:
		"BRUR" K 6 Bright { A_FaceTarget(); }
		"BRUR" KL 8 Bright;
		"BRUR" M 1 Bright { A_SpawnProjectile("RS_THEBEEHK", 32, 2); }
		"BRUR" M 9 Bright { A_SpawnProjectile("RS_EffectHK", 30, 0); }
		Goto See;
	Missile.T10.Bolt:
		"BRUR" EF 6 Bright { A_FaceTarget(); }
		"BRUR" G 3 Bright { A_SpawnProjectile("RS_BloodBoltHK", 32, 2, random(-1, 1)); }
		"BRUR" G 2 Bright A_MonsterRefire(128, "See");
		"BRUR" G 1 Bright A_Jump(22, "Missile.T10.DoT");
		Goto Missile.T10.Bolt2;
	Missile.T10.Bolt2:
		"BRUR" HI 6 Bright { A_FaceTarget(); }
		"BRUR" J 3 Bright { A_SpawnProjectile("RS_BloodBoltHK", 32, 2, random(-1, 1)); }
		"BRUR" J 2 Bright A_MonsterRefire(128, "See");
		"BRUR" G 1 Bright A_Jump(22, "Missile.T10.DoT");
		Goto Missile.T10.Bolt;
	Missile.T10.Enrage:
		TNT1 A 0 { if (rsRage >= 1) return ResolveState("Missile.T10.Pick"); return ResolveState(null); }
		"BRUR" K 1 { bNOPAIN = true; }
		"BRUR" K 12 Bright { A_StartSound("superbaron/scream"); }
		"BRUR" KL 12 Bright { A_SpawnProjectile("RS_EffectHK", 48, 0); }
		"BRUR" M 10 Bright { bMISSILEEVENMORE = true; }
		"BRUR" MMM 2 Bright { A_SpawnProjectile("RS_EffectHK", 24, 0); }
		"BRUR" M 8 Bright { rsRage++; MarkEnrageTell(); }
		Goto See;
	Pain.T10:
		"BRUR" N 5 Bright { A_Pain(); }
		"BRUR" N 1 Bright A_Jump(74, "Missile.T10.Dodge1", "Missile.T10.Dodge2");
		Goto See;
	Death.T10:
		"BRUR" N 6 Bright { A_Scream(); }
		"BRUR" N 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 100, -30, 0, CMF_AIMOFFSET, -10); }
		"BRUR" N 2 Bright { A_SpawnProjectile("RS_HKRedDeath", 100, 50, 0, CMF_AIMOFFSET, 10); }
		"BRUR" N 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 20, 30, 0, CMF_AIMOFFSET, 10); }
		"BRUR" N 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 60, 5, 0, CMF_AIMOFFSET, -10); }
		"BRUR" N 4 { A_SpawnProjectile("RS_HKRedDeath", 100, 50, 0, CMF_AIMOFFSET, 10); }
		"BRUR" N 5 Bright { A_Fall(); }
		"BRUR" N 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 60, 5, 0, CMF_AIMOFFSET, -10); }
		"BRUR" N 4 { A_SpawnProjectile("RS_HKRedDeath", 100, 50, 0, CMF_AIMOFFSET, 10); }
		"BRUR" N 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 20, 30, 0, CMF_AIMOFFSET, 10); }
		"BRUR" N 4 Bright { A_SpawnProjectile("RS_HKRedDeath", 60, 5, 0, CMF_AIMOFFSET, -10); }
		"BRUR" N 2 { A_SpawnProjectile("RS_HKRedDeath", 100, -30, 0, CMF_AIMOFFSET, -10); }
		"TROO" QRST 5;
		"TROO" U -1;
		Stop;
	Escort.T10:
		"BRUR" EF 8 Bright { A_FaceTarget(); }
		"BRUR" G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ================= T11 BLACK -- THE T-800 BARON (11_K) =================
	// Two weapon modes held in RS_BrusMode. Default: big missile,
	// cluster missiles, grenade toss. Mode 3: laser sweep, death beam,
	// grenade toss. Pain flips the mode. The See intro showers sparks.
	Spawn.T11:
		"BRUC" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"BRUC" E 8 { A_FaceTarget(); }
		"BRUC" E 5 Bright { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 4 { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 5 Bright { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 3 { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 3 Bright { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 2 { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 2 Bright { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 1 { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 1 Bright { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 1 { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		"BRUC" E 1 Bright { A_SpawnProjectile("RS_SparkPuff1", random(12, 66), random(-20, 20), 0, CMF_AIMOFFSET, random(0, 360)); }
		Goto See.T11.Walk;
	See.T11.Walk:
		"BRUC" A 1 { A_StartSound("monster/bruwlk"); }
		"BRUC" AABB 3 { A_Chase(); }
		"BRUC" C 1 { A_StartSound("monster/bruwlk"); }
		"BRUC" CCDD 3 { A_Chase(); }
		"BRUC" D 0 A_Jump(8, "Missile.T11.Mode1", "Missile.T11.Mode2");
		Loop;
	Missile.T11:
		"BRUC" E 8 { A_FaceTarget(); }
		TNT1 A 0 { if (CountInv("RS_BrusMode") >= 3) return ResolveState("Missile.T11.ModeB"); return ResolveState(null); }
		"BRUC" E 0 A_Jump(256, "Missile.T11.BigMis", "Missile.T11.Cluster", "Missile.T11.Nade");
		Goto See.T11.Walk;
	Missile.T11.ModeB:
		"BRUC" E 0 A_Jump(256, "Missile.T11.Laser", "Missile.T11.DeathBeam", "Missile.T11.Nade");
		Goto See.T11.Walk;
	Missile.T11.Laser:
		"BRUC" E 0 { A_StartSound("prox/beep"); }
	Missile.T11.LaserLoop:
		"BRUC" E 4 Bright { A_FaceTarget(); }
		"BRUC" FE 4 Bright { A_SpawnProjectile("RS_BluCybFX", 38, 15, 0, 0); }
		"BRUC" FFF 4 Bright { A_SpawnProjectile("RS_SwooshCBBar1", 38, 15, random(-7, 7), 0); }
		"BRUC" F 0 A_CheckSight("See.T11.Walk");
		"BRUC" E 2 Bright { A_FaceTarget(); }
		"BRUC" FE 4 Bright { A_SpawnProjectile("RS_BluCybFX", 38, 15, 0, 0); }
		"BRUC" FFF 4 Bright { A_SpawnProjectile("RS_SwooshCBBar1", 38, 15, random(-14, 14), 0); }
		"BRUC" E 2 Bright A_MonsterRefire(128, "See.T11.Walk");
		Goto Missile.T11.LaserLoop;
	Missile.T11.DeathBeam:
		"BRUC" EE 8 { A_FaceTarget(); }
		"BRUC" E 0 { A_StartSound("prox/beep"); }
		"BRUC" F 8 Bright { A_SpawnProjectile("RS_RedRevLoad", 38, 15, random(-1, 1), 0); }
		"BRUC" F 6 Bright { A_FaceTarget(); }
		"BRUC" F 6 Bright { A_SpawnProjectile("RS_MegaRedRev", 38, 15, random(-1, 1), 0); }
		"BRUC" F 5 A_Jump(60, "Missile.T11.Laser");
		Goto See.T11.Walk;
	Missile.T11.BigMis:
		"BRUC" F 0 { A_StartSound("prox/beep"); }
		"BRUC" F 12 Bright { A_SpawnProjectile("RS_BruiserMissile", 38, 15, 0, 0); }
		"BRUC" F 0 A_CheckSight("See.T11.Walk");
		"BRUC" EE 10 { A_FaceTarget(); }
		"BRUC" F 0 { A_StartSound("prox/beep"); }
		"BRUC" F 7 Bright { A_SpawnProjectile("RS_BruiserMissile", 38, 15, random(-3, 3), 0); }
		"BRUC" F 0 A_CheckSight("See.T11.Walk");
		"BRUC" EE 10 { A_FaceTarget(); }
		"BRUC" F 0 { A_StartSound("prox/beep"); }
		"BRUC" F 7 Bright { A_SpawnProjectile("RS_BruiserMissile", 38, 15, random(-7, 7), 0); }
		"BRUC" E 1 A_Jump(60, "Missile.T11.Cluster");
		Goto See.T11.Walk;
	Missile.T11.Cluster:
		"BRUC" F 9 Bright { A_SpawnProjectile("RS_SpreadMisBar1", 38, 15, random(-5, 5), 0); }
		"BRUC" F 5 Bright { A_SpawnProjectile("RS_SpreadMisBar1", 38, 15, random(-14, 14), 0); }
		"BRUC" F 0 A_CheckSight("See.T11.Walk");
		"BRUC" EEE 5 { A_FaceTarget(); }
		"BRUC" F 9 Bright { A_SpawnProjectile("RS_SpreadMisBar1", 38, 15, random(-7, 7), 0); }
		"BRUC" F 5 Bright { A_SpawnProjectile("RS_SpreadMisBar1", 38, 15, random(-16, 16), 0); }
		"BRUC" E 1 A_Jump(42, "Missile");
		Goto See.T11.Walk;
	Missile.T11.Nade:
		"BRUC" GH 7 { A_FaceTarget(); }
		"BRUC" I 9 { A_SpawnProjectile("RS_BaronNade", 38, 2, random(-9, 9), 0, random(3, 12)); }
		"BRUC" I 1 A_Jump(42, "Missile");
		Goto See.T11.Walk;
	Melee.T11:
		"BRUC" GH 6 { A_FaceTarget(); }
		"BRUC" I 4 { A_CustomMeleeAttack(MeleeDamage, MeleeSound, "", "Melee", true); }
		"BRUC" I 0 A_Jump(128, "Missile");
		Goto See.T11.Walk;
	Pain.T11:
		"BRUC" J 2;
		"BRUC" J 2 { A_Pain(); }
		"BRUC" J 2 A_Jump(256, "Missile.T11.Mode1", "Missile.T11.Mode2");
		Goto See.T11.Walk;
	Missile.T11.Mode1:
		"BRUC" A 0 { A_GiveInventory("RS_BrusMode", 3); }
		Goto See.T11.Walk;
	Missile.T11.Mode2:
		"BRUC" A 0 { A_TakeInventory("RS_BrusMode", 3); }
		Goto See.T11.Walk;
	Death.T11:
		"BRUC" KKK 4 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"BRUC" K 8 Bright { A_Scream(); }
		"BRUC" LLMMNN 6 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"BRUC" O 6 Bright { A_NoBlocking(); }
		"BRUC" QR 6 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"BRUC" S 6;
		"BRUC" T -1 { A_BossDeath(); }
		Stop;
	Escort.T11:
		"BRUC" EF 8 { A_FaceTarget(); }
		"BRUC" G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ================= T12 WHITE -- THE GHOST OF E1M8 (11_W) =================
	// Spawns its twin (RS_Split, in the Spawn dispatcher). Chases with
	// NOCLIP on, drops it to fast-chase, and cycles ghost bombs /
	// spectre summons / the triple soul bomb.
	Spawn.T12:
		"PHAN" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"PHAN" A 0 { A_Stop(); bNOCLIP = true; }
	See.T12.Phase:
		"PHAN" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.T12.Solid:
		"PHAN" A 0 { bNOCLIP = false; }
		"PHAN" AABBCCDD 3 { A_FastChase(); }
		"PHAN" A 0 A_Jump(14, "See");
		Loop;
	Melee.T12:
	Missile.T12:
		"PHAN" E 0 A_Jump(64, "Missile.T12.Summons");
		"PHAN" E 0 A_Jump(256, "Missile.T12.Bombs", "Missile.T12.BigBomb");
	Missile.T12.Bombs:
		"PHAN" EF 7 { A_FaceTarget(); }
		"PHAN" G 8 { A_SpawnProjectile("RS_PhantomEgg", 32, 0, random(-5, 5), 0); }
		"PHAN" G 0 A_CheckSight("See");
		"PHAN" OP 7 { A_FaceTarget(); }
		"PHAN" Q 8 { A_SpawnProjectile("RS_PhantomEgg", 32, 0, random(-10, 10), 0); }
		"PHAN" Q 0 A_MonsterRefire(128, "See");
		Goto Missile.T12.Bombs;
	Missile.T12.Summons:
		"PHAN" H 8 { A_FaceTarget(); }
		"PHAN" H 8 { A_StartSound("Baron/Sight"); }
		"PHAN" HHHH 4
		{
			if (SummonPack("RS_Spectre", 1, 6, -3, 64.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		"PHAN" A 0 A_Jump(88, "Missile.T12.BigBomb");
		Goto See;
	Missile.T12.BigBomb:
		"PHAN" EFG 7 { A_FaceTarget(); }
		"PHAN" QPO 7 { A_StartSound("Baron/Pain"); }
		"PHAN" OP 5 { A_FaceTarget(); }
		"PHAN" Q 9 { A_SpawnProjectile("RS_SoulBomb", 32, 0, 0, 0); }
		"PHAN" Q 7 { A_SpawnProjectile("RS_SoulBomb", 32, 0, random(-8, 8), 0); }
		"PHAN" Q 5 { A_SpawnProjectile("RS_SoulBomb", 32, 0, random(-14, 14), 0); }
		"PHAN" PO 4;
		"PHAN" A 1 A_Jump(64, "Missile.T12.Bombs", "Missile.T12.Summons", "Missile.T12.BigBomb");
		Goto See;
	Pain.T12:
		"PHAN" H 2;
		"PHAN" H 2 { A_Pain(); }
		"PHAN" A 0 A_Jump(128, "See.T12.Solid");
		Goto See;
	Death.T12:
		"PHAN" I 8;
		"PHAN" J 8 { A_Scream(); }
		"PHAN" K 8;
		"PHAN" L 8 { A_NoBlocking(); }
		"PHAN" MN 8;
		"PHAN" R -1 { A_BossDeath(); }
		Stop;
	Escort.T12:
		"PHAN" EF 8 { A_FaceTarget(); }
		"PHAN" G 12 Bright { RS_CallEscort(); }
		Goto See;

	// ================= TEX BLACK-EX -- T-800 BARON MK II (11_KX) =========
	// CHP's BlackEX knight: the T-800 taken past its own ceiling. Same
	// two-mode idea as T11 but the modes are now RANGE BANDS, not a
	// toggle -- inside 500 it is all beams and clusters, out past 1500 it
	// is homing missiles and the death beam. Three things T11 does not
	// have:
	//   * a ONE-TIME arming sequence (rsExReady) before it will fight;
	//   * a WARP -- squashes to a sliver, wanders, and reforms, rolled
	//     off the walk loop and off pain, NOPAIN while it is gone;
	//   * a RESISTANCE move that gives it RS_HKEXProtect (0.6 damage
	//     factor, 7s) behind a curtain of zap decals.
	// Phase 2 fires ONCE below 5000 HP: speed up, MISSILEEVENMORE on, and
	// the Warp and Resistance moves both gain a second half (Warp2/Res2).
	Spawn.TEX:
		"KKEX" A 0 { A_SetScale(1.45, 1.45); }
		"KKEX" AB 10 { A_Look(); }
		Loop;
	See.TEX:
		// The arming sequence. Runs once, then every later See goes
		// straight to the walk.
		TNT1 A 0
		{
			if (rsExReady >= 1)
				return ResolveState("See.TEX.Walk");
			return ResolveState(null);
		}
		"KKEX" E 8 { A_FaceTarget(); }
		"KKEX" E 5 Bright { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 4 { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 5 Bright { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 3 { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 2 Bright { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 1 { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 1 Bright { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 1 { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		"KKEX" E 1 Bright;
		"KKEX" E 1;
		"KKEX" E 1 Bright;
		"KKEX" E 1 { rsExReady++; }
		"KKEX" E 1 Bright;
		"KKEX" E 1;
		Goto See.TEX.Walk;
	See.TEX.Walk:
		"KKEX" A 0 { A_StartSound("monster/bruwlk", CHAN_6); }
		"KKEX" AABB 3 { A_Chase(); }
		"KKEX" C 0 { A_StartSound("monster/bruwlk", CHAN_7); }
		"KKEX" CCDD 3 { A_Chase(); }
		"KKEX" D 0 A_Jump(24, "See.TEX.Warp");
		Loop;
	Melee.TEX:
	Missile.TEX:
		TNT1 A 0 A_JumpIfHealthLower(5000, "Missile.TEX.Phase2");
	// CHP's "Nah" branch is a Goto Missile+1 -- this label IS that line.
	Missile.TEX.Pick:
		"KKEX" E 8 { A_FaceTarget(); }
		"KKEX" E 0 A_JumpIfCloser(500, "Missile.TEX.Mode2");
		"KKEX" E 0 A_JumpIfCloser(1500, "Missile.TEX.Mode1");
		TNT1 A 0 A_Jump(256, "Missile.TEX.Homing", "Missile.TEX.DeathBeam", "Missile.TEX.BigMis");
		Goto See.TEX.Walk;
	Missile.TEX.Phase2:
		// One-shot. Once rsExRage is set the gate falls straight back
		// into the range-band dispatcher (CHP's "Nah" -> Missile+1).
		TNT1 A 0
		{
			if (rsExRage >= 1)
				return ResolveState("Missile.TEX.Pick");
			return ResolveState(null);
		}
		TNT1 A 0 { A_SetSpeed(18); bMISSILEEVENMORE = true; }
		"KKEX" E 6 Bright { rsExRage++; MarkEnrageTell(); }
		"KKEX" EGGGG 2 Bright { A_SpawnProjectile("RS_ZapDecHKex", random(12, 88), random(-20, 20), 0); }
		Goto See.TEX.Walk;
	Missile.TEX.Mode1:
		"KKEX" E 0 A_Jump(256, "Missile.TEX.BigMis", "Missile.TEX.MisBar", "Missile.TEX.NadeToss", "Missile.TEX.DeathBeam", "Missile.TEX.FastBeam");
		Goto See.TEX.Walk;
	Missile.TEX.Mode2:
		"KKEX" E 0 A_Jump(256, "Missile.TEX.MisBar", "Missile.TEX.FastBeam", "Missile.TEX.NadeToss");
		Goto See.TEX.Walk;
	Missile.TEX.FastBeam:
		"KKEX" E 0 { A_StartSound("prox/beep"); }
	Missile.TEX.FastBeamLoop:
		"KKEX" E 3 Bright { A_FaceTarget(); }
		"KKEX" S 0 { A_SpawnProjectile("RS_BluCybFX", 44, -18, 0, 0); }
		"KKEX" S 3 Bright { A_SpawnProjectile("RS_BluCybFX", 44, 18, 0, 0); }
		"KKEX" S 0 { A_SpawnProjectile("RS_BluCybFX", 44, -18, 0, 0); }
		"KKEX" S 3 Bright { A_SpawnProjectile("RS_BluCybFX", 44, 18, 0, 0); }
		"KKEX" S 1 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, 18, 0, 0); }
		"KKEX" S 2 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, -18, random(-14, 14), 0); }
		"KKEX" S 2 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, 18, random(-14, 14), 0); }
		"KKEX" S 2 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, -18, random(-14, 14), 0); }
		"KKEX" S 0 A_Jump(32, "Missile.TEX.AccurateBeam");
		"KKEX" S 0 A_CheckSight("See.TEX.Walk");
		"KKEX" E 2 Bright { A_FaceTarget(); }
		"KKEX" S 0 { A_SpawnProjectile("RS_BluCybFX", 44, -18, 0, 0); }
		"KKEX" S 3 Bright { A_SpawnProjectile("RS_BluCybFX", 44, 18, 0, 0); }
		"KKEX" S 0 { A_SpawnProjectile("RS_BluCybFX", 44, -18, 0, 0); }
		"KKEX" S 3 Bright { A_SpawnProjectile("RS_BluCybFX", 44, 18, 0, 0); }
		"KKEX" S 1 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, 18, 0, 0); }
		"KKEX" S 2 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, -18, random(-14, 14), 0); }
		"KKEX" S 2 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, 18, random(-14, 14), 0); }
		"KKEX" S 2 Bright { A_SpawnProjectile("RS_HKEXFastBeam", 44, -18, random(-14, 14), 0); }
		"KKEX" S 0 A_Jump(64, "Missile.TEX.AccurateBeam");
		"KKEX" S 0 A_Jump(18, "Missile.TEX.NadeToss");
		"KKEX" E 2 Bright A_MonsterRefire(128, "See.TEX.Walk");
		Goto Missile.TEX.FastBeamLoop;
	Missile.TEX.AccurateBeam:
		"KKEX" S 0 { A_StartSound("weapons/railgf", CHAN_5); }
		"KKEX" S 6 Bright
		{
			A_CustomRailgun(random(1, 4), 0, 0, 0,
			                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ | RGF_SILENT, 1, 0,
			                "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9,
			                "RS_CGRailBuff", 7, 10);
		}
		"KKEX" S 0 { A_StartSound("weapons/railgf", CHAN_5); }
		"KKEX" S 6 Bright
		{
			A_CustomRailgun(random(1, 4), 0, 0, 0,
			                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ | RGF_SILENT, 1, 0,
			                "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9,
			                "RS_CGRailBuff", 7, 10);
		}
		"KKEX" S 0 A_CheckSight("See.TEX.Walk");
		"KKEX" E 2 Bright A_MonsterRefire(128, "See.TEX.Walk");
		Goto Missile.TEX.FastBeamLoop;
	Missile.TEX.Homing:
		"KKEX" E 9 Bright { A_StartSound("prox/beep"); }
		"KKEX" E 9 { A_FaceTarget(); }
		"KKEX" E 9 Bright { A_StartSound("prox/beep"); }
		"KKEX" E 9 { A_FaceTarget(); }
		"KKEX" R 0 { A_SpawnProjectile("RS_BruiserMissileEx2", 80, -18, 0, 0); }
		"KKEX" R 9 Bright { A_SpawnProjectile("RS_BruiserMissileEx2", 80, 18, 0, 0); }
		"KKEX" E 6;
		Goto See.TEX.Walk;
	Missile.TEX.DeathBeam:
		"KKEX" EE 9 { A_FaceTarget(); }
		"KKEX" E 0 { A_StartSound("prox/beep"); }
		"KKEX" S 0 { A_SpawnProjectile("RS_RedRevLoad", 44, -18, random(-1, 1), 0); }
		"KKEX" S 7 Bright { A_SpawnProjectile("RS_RedRevLoad", 44, 18, random(-1, 1), 0); }
		"KKEX" S 5 Bright { A_FaceTarget(); }
		"KKEX" S 0 { A_SpawnProjectile("RS_MegaRedRev", 44, -18, random(-1, 1), 0); }
		"KKEX" S 5 Bright { A_SpawnProjectile("RS_MegaRedRev", 44, 18, random(-1, 1), 0); }
		"KKEX" S 0 { A_SpawnItemEx("Cell", 8, 4, 48, 3, 3, 3, angle + 1); }
		"KKEX" S 5 A_Jump(60, "Missile.TEX.BigMis");
		Goto See.TEX.Walk;
	Missile.TEX.BigMis:
		"KKEX" S 0 { A_StartSound("prox/beep"); }
		"KKEX" S 0 { A_SpawnProjectile("RS_BruiserMissileEx", 46, -20, 0, 0); }
		"KKEX" S 9 Bright { A_SpawnProjectile("RS_BruiserMissileEx", 46, 20, 0, 0); }
		"KKEX" S 0 A_CheckSight("See.TEX.Walk");
		"KKEX" EE 7 { A_FaceTarget(); }
		"KKEX" S 0 { A_StartSound("prox/beep"); }
		"KKEX" S 0 { A_SpawnProjectile("RS_BruiserMissileEx", 46, -20, random(-7, 7), 0); }
		"KKEX" S 6 Bright { A_SpawnProjectile("RS_BruiserMissileEx", 46, 20, random(-7, 7), 0); }
		"KKEX" S 0 A_CheckSight("See.TEX.Walk");
		"KKEX" EE 7 { A_FaceTarget(); }
		"KKEX" S 0 { A_StartSound("prox/beep"); }
		"KKEX" S 0 { A_SpawnProjectile("RS_BruiserMissileEx", 46, -20, random(-17, 17), 0); }
		"KKEX" S 6 Bright { A_SpawnProjectile("RS_BruiserMissileEx", 46, 20, random(-17, 17), 0); }
		"KKEX" S 0 { A_SpawnItemEx("RocketBox", 8, 4, 48, 3, 3, 3, angle + 1); }
		"KKEX" S 0 A_Jump(64, "Missile.TEX.Homing");
		"KKEX" E 1 A_Jump(60, "Missile.TEX.MisBar");
		Goto See.TEX.Walk;
	Missile.TEX.MisBar:
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, -18, random(-5, 5), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-1, 1)); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, 18, random(-5, 5), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-1, 1)); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, -18, random(-14, 14), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, 18, random(-14, 14), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, -18, random(-14, 14), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, 18, random(-14, 14), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"KKEX" F 0 A_CheckSight("See.TEX.Walk");
		"KKEX" EEE 5 { A_FaceTarget(); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, -18, random(-14, 14), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-5, 5)); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, 18, random(-14, 14), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-5, 5)); }
		"KKEX" F 2 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, -18, random(-14, 14), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-5, 5)); }
		"KKEX" F 1 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, 18, random(-24, 24), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-7, 7)); }
		"KKEX" F 1 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, -18, random(-24, 24), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-7, 7)); }
		"KKEX" F 1 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, 18, random(-24, 24), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-7, 7)); }
		"KKEX" F 1 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, -18, random(-24, 24), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-7, 7)); }
		"KKEX" F 1 Bright { A_SpawnProjectile("RS_SpreadMisBarEX", 44, 18, random(-24, 24), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-7, 7)); }
		"KKEX" FFF 0 { A_SpawnItemEx("Shell", 8, 4, 48, 3, 3, 3, angle + 1); }
		"KKEX" E 1 A_Jump(42, "Missile");
		Goto See.TEX.Walk;
	Missile.TEX.NadeToss:
		"KKEX" EG 7 { A_FaceTarget(); }
		"KKEX" G 9 { A_SpawnProjectile("RS_BaronHellNade", 60, 2, random(-9, 9), 0, random(3, 12)); }
		"KKEX" G 1 A_Jump(42, "Missile");
		Goto See.TEX.Walk;
	Missile.TEX.Resistance:
		// The damage-resist curtain. Ends by handing itself
		// RS_HKEXProtect (CHP: DamageFactor 0.6 for 7 seconds).
		"KKEX" E 4;
		"KKEX" G 5;
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 36, 2, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 39, 6, 0); }
		"KKEX" G 1 { A_SpawnProjectile("RS_ZapDecHKex", 39, -6, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 42, 9, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 42, -9, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 42, 4, 0); }
		"KKEX" G 1 { A_SpawnProjectile("RS_ZapDecHKex", 42, -4, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 45, 9, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 45, -9, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 45, 4, 0); }
		"KKEX" G 1 { A_SpawnProjectile("RS_ZapDecHKex", 45, -4, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 48, 9, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 48, -9, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 48, 4, 0); }
		"KKEX" G 1 { A_SpawnProjectile("RS_ZapDecHKex", 48, -4, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 54, 2, 0); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapDecHKex", 51, 6, 0); }
		"KKEX" G 1 { A_SpawnProjectile("RS_ZapDecHKex", 51, -6, 0); }
		"KKEX" G 0 { A_GiveInventory("RS_HKEXProtect", 1); }
		"KKEX" G 6 { A_SpawnProjectile("RS_ZapOrbHKEX", 78, 0, 0); }
		TNT1 A 0
		{
			if (rsExRage >= 1)
				return ResolveState("Missile.TEX.Res2");
			return ResolveState(null);
		}
		Goto See.TEX.Walk;
	Missile.TEX.Res2:
		"KKEX" G 6 Bright;
		"KKEX" EG 8 Bright { A_FaceTarget(); }
		"KKEX" EEEE 1 Bright { A_SpawnProjectile("RS_ZapDecHKex", 64, 12, 0); }
		"KKEX" GEE 3 Bright;
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapOrbHKEX2", 44, 0, random(-12, 1)); }
		"KKEX" G 0 { A_SpawnProjectile("RS_ZapOrbHKEX2", 44, 0, random(-1, 12)); }
		"KKEX" G 4 { A_SpawnProjectile("RS_ZapOrbHKEX2", 44, 0, 0); }
		Goto See;
	See.TEX.Warp:
		// Squashes to a sliver, wanders at speed 99, reforms. NOPAIN for
		// the whole move -- you cannot stunlock it out of the warp.
		"KKEX" G 1 { bNOPAIN = true; }
		"KKEX" G 0 { A_StartSound("misc/teleport", CHAN_AUTO); }
		"KKEX" G 2 { A_SetScale(1.6, 1.0); }
		"KKEX" G 1 { A_SetScale(2.0, 0.7); }
		"KKEX" G 1 { A_SetScale(2.3, 0.4); }
		"KKEX" G 2 { A_SetScale(2.7, 0.2); }
		"KKEX" G 1 { A_SetScale(3.1, 0.05); }
		"KKEX" G 0 { A_SetSpeed(99); }
		TNT1 AAAA 0 { A_Wander(); }
		TNT1 AA 1 { A_Wander(); }
		TNT1 AAAA 0 { A_Wander(); }
		"KKEX" G 0
		{
			if (rsExRage >= 1)
				return ResolveState("See.TEX.Warp2");
			return ResolveState(null);
		}
		"KKEX" G 0 { A_SetSpeed(14); }
		"KKEX" G 1 { A_SetScale(3.1, 0.05); }
		"KKEX" G 0 { A_StartSound("misc/teleport", CHAN_AUTO); }
		"KKEX" G 2 { A_SetScale(2.7, 0.2); }
		"KKEX" G 1 { A_SetScale(2.3, 0.4); }
		"KKEX" G 1 { A_SetScale(2.0, 0.7); }
		"KKEX" G 2 { A_SetScale(1.6, 1.0); }
		"KKEX" G 2 { A_SetScale(1.45, 1.45); }
		"KKEX" G 1 { bNOPAIN = false; }
		"KKEX" G 0 A_Jump(64, "Missile.TEX.Resistance");
		Goto See.TEX.Walk;
	See.TEX.Warp2:
		"KKEX" G 0 { A_SetSpeed(18); }
		"KKEX" G 1 { A_SetScale(3.1, 0.05); }
		"KKEX" G 0 { A_StartSound("misc/teleport", CHAN_AUTO); }
		"KKEX" G 2 { A_SetScale(2.7, 0.2); }
		"KKEX" G 1 { A_SetScale(2.3, 0.4); }
		"KKEX" G 1 { A_SetScale(2.0, 0.7); }
		"KKEX" G 2 { A_SetScale(1.6, 1.0); }
		"KKEX" G 2 { A_SetScale(1.45, 1.45); }
		"KKEX" G 1 { bNOPAIN = false; }
		"KKEX" G 0 A_Jump(78, "Missile.TEX.Resistance");
		Goto See.TEX.Walk;
	Pain.TEX:
		"KKEX" G 2;
		"KKEX" G 2 { A_Pain(); }
		"KKEX" G 2 A_Jump(128, "See.TEX.Warp");
		Goto See.TEX.Walk;
	Death.TEX:
		"KKEX" H 0 { A_SetScale(1.45, 1.45); }
		"KKEX" HHHH 3 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), random(0, 360), CMF_AIMOFFSET, -10); }
		"KKEX" H 8 Bright { A_Scream(); }
		"KKEX" IIIIJJJJJJKKKKKK 2 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), random(0, 360), CMF_AIMOFFSET, -10); }
		"KKEX" L 6 Bright { A_NoBlocking(); }
		MISL XXXYYY 2 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), random(0, 360), CMF_AIMOFFSET, -10); }
		MISL Z 6;
		"KKEX" Q 10 { A_SetTranslucent(0.1); }
		"KKEX" Q 10 { A_SetTranslucent(0.4); }
		"KKEX" Q 10 { A_SetTranslucent(0.7); }
		"KKEX" Q 0 { A_SetTranslucent(1.0); }
		"KKEX" Q -1 { A_BossDeath(); }
		Stop;
	Escort.TEX:
		"KKEX" EG 8 { A_FaceTarget(); }
		"KKEX" G 12 Bright { RS_CallEscort(); }
		Goto See;
	}
}
