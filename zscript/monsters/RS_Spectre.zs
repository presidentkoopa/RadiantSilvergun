// =====================================================================
// RS_Spectre -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\07\07_<code>.txt
// One CHP file per colour; the FIRST actor in each file is that colour's
// spectre and each is a genuinely different creature with its OWN sprite
// set, stats and attack. Nothing here is inferred or tinted -- every tier
// below was read out of its CHP file.
//
//   tier  CHP   body   HP    what it actually is
//   T00   07_C  SARG   150   vanilla shadow pinky, plain bite
//   T01   07_G  SRGG   175   green shadow demon, harder bite
//   T02   07_B  SRGB   210   blue: bite, or a skull-rush inside 800
//   T03   07_CY WRM2   200   SNEAKY ICE WORM: shrinks out of sight,
//                            sows ice spikes, hisses (rush), shatters
//   T04   07_P  SAR2   250   purple hound: bite + a long 25-speed rush
//   T05   07_Y  SRG2   320   blood demon: bite, then a pain-triggered
//                            speed buff that drops its stealth
//   T06   07_A  DOGA   600   abyss dog: submerged, surfaces to bite or
//                            to spit a three-shot fire fan, re-hides
//   T07   07_F  SRGF   205   fireblu: five-hit chained skull-rush
//   T08   07_BR BPWA   300   brown prowler: bite, or rallies the pack
//                            (heal + medi-orbs) when it spots friends
//   T09   07_GY SRGY   330   GRAY: near-invisible stomper -- leaps and
//                            lands a four-way ground quake
//   T10   07_R  SRGR   394   red blood demon: bite + blood-bolt spray,
//                            pain-triggered NOPAIN buff
//   T11   07_K  SHDW  3000   THE ROGUE: shadow balls, teleport blinks,
//                            stalks unseen then warps in and backstabs
//   T12   07_W  SLGM  5600   SLIME GOLEM: invulnerable while submerged,
//                            three slime volleys, spawns a Wakawaka
//   TEX   07_KX GKEX  7250   THE BACKSTABBER UNSILENCED: the rogue with
//                            two walk modes it flips between (solid, or
//                            a NOCLIP ghost that walks through geometry),
//                            bouncing shadow balls, a 100-200 spiral that
//                            scatters seventy-two bouncers when it dies, a
//                            beam that BLINDS instead of hurting, and a
//                            stalk counter that ends in a flank warp
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and are
// applied through TierData below, replacing the generic ladder.
//
// TEX SOURCE: CHP 07_KX.txt, ACTOR CommonBlackSpectreEX2 (the first
// actor in the file). It declares no parent -- every property it has is
// its own, so nothing was inherited in.
//
// TEX CHP properties with no TierData channel, recorded rather than
// silently dropped: XScale 1.2 / YScale 0.85, Mass 500, Radius 20,
// RadiusDamageFactor 0.5, DamageFactor Melee 2.5, MeleeThreshold 200,
// and the +LOOKALLAROUND / +QUICKTORETALIATE / +NOFEAR / +BOSS flag set.
// The row carries Health / Speed / PainChance / damage only.
//
// Where CHP left a state undefined it was taken from the CHP parent:
//   T06 stats  <- CHP 06_A CommonAbyssDemon (07_A overrides only Alpha)
//   T07 stats + See/Missile/Rush/Melee/Pain/Death <- CHP 06_F
//              CommonFirebluDemon (07_F defines only Spawn/Idle/Raise)
// Every other tier's states are 07_*.txt's own.
//
// NOT PORTED (with reason):
//   * NewIcon* spawns, A_GivetoChildren, CHWhitePlan / "Tickles",
//     "Grow"/GrowRaisin promotion, Death.Nocorpse,
//     CHRandom_GibGenerator, RandomLetterSpawner, A_SpawnParticle walls,
//     ACS_NamedExecuteAlways announcers -- CHP infrastructure cruft.
//   * [REVERSED 2026-08-04 -- this entry was WRONG and is kept, corrected,
//     rather than deleted, because a deleted claim gets rediscovered.]
//     T08's A_RadiusGive("BrownImpCommand") and ("SpeedBuffPE") were
//     dropped on the reasoning that both CH items "are pure
//     ACS_NamedExecuteAlways wrappers with no other body, so porting them
//     would import nothing." The wrapper is empty BECAUSE the behaviour
//     lives in the ACS script -- PESPEED and BrownImpCommand give +10
//     speed, ALWAYSFAST and a shove for 600/180 tics. Dropping the wrapper
//     dropped the mechanic, invisibly. Both are rebuilt in
//     RS_MonsterCommands.zs and wired back into See.T08.Scatter, which is
//     what makes the Prowler's rally an actual rally rather than a heal.
//     See docs/rs_19_acs_inventory.txt for the full audit.
//   * T07's Pain.Fire -- a damage-type pain state; the tier dispatch has
//     no per-damage-type channel.
//   * SLGM frame F and SLGM frame '\' (used by CHP's Idle and PeekUp)
//     have NO file in sprites/monsters/_src, CH/sprites/trashmon or
//     CHP/sprites/dem&spec -- a backslash frame is not even a legal
//     Windows filename, so it never survived extraction. Those two
//     frames are dropped from the golem's idle/peek animation ONLY;
//     every attack, pain and death frame it uses is present. Nothing
//     was substituted.
// =====================================================================

class RS_Spectre : RS_DemonBase replaces Spectre
{
	// CHP user vars, re-expressed as private fields (no A_SetUserVar).
	private int rsCalm;      // 07_Y  User_Calm
	private int rsHidden;    // 07_A  user_hidd
	private int rsRisen;     // 07_W  RiseCheck inventory
	private int rsExMode;    // 07_KX DewzanToken -- solid vs ghost walk
	private int rsExStalk;   // 07_KX user_hm -- the flank-warp counter

	Default
	{
		Health 150;
		Radius 30;
		Height 56;
		Mass 400;
		Speed 10;
		PainChance 180;
		Monster;
		+FLOORCLIP
		+SHADOW
		RenderStyle "OptFuzzy";
		Alpha 0.5;
		SeeSound "spectre/sight";   PainSound "spectre/pain";
		DeathSound "spectre/death"; ActiveSound "spectre/active";
		AttackSound "spectre/melee";
		Obituary "$OB_SPECTRE";
		Tag "Spectre";
	}

	// CHP's real per-colour numbers, read from 07_*.txt. Default Health is
	// 150 and Default Speed 10, so the absolute numbers are expressed as
	// multipliers to keep the base class's recompute-from-defaults
	// contract intact.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 180; r.dmgMul = 1.0;
		int hp = 150; int spd = 10;
		switch (t)
		{
			case 0:  hp = 150;  spd = 10; r.painChance = 150; r.dmgMul = 1.0; break;
			case 1:  hp = 175;  spd = 12; r.painChance = 130; r.dmgMul = 1.1; break;
			case 2:  hp = 210;  spd = 14; r.painChance = 110; r.dmgMul = 1.2; break;
			case 3:  hp = 200;  spd = 27; r.painChance = 64;  r.dmgMul = 1.3; break;
			case 4:  hp = 250;  spd = 16; r.painChance = 80;  r.dmgMul = 1.4; break;
			case 5:  hp = 320;  spd = 17; r.painChance = 60;  r.dmgMul = 1.5; break;
			case 6:  hp = 600;  spd = 19; r.painChance = 128; r.dmgMul = 1.6; break;
			case 7:  hp = 205;  spd = 5;  r.painChance = 180; r.dmgMul = 1.5; break;
			case 8:  hp = 300;  spd = 17; r.painChance = 33;  r.dmgMul = 1.6; break;
			case 9:  hp = 330;  spd = 8;  r.painChance = 0;   r.dmgMul = 1.8; break;
			case 10: hp = 394;  spd = 16; r.painChance = 30;  r.dmgMul = 1.9; break;
			case 11: hp = 3000; spd = 15; r.painChance = 40;  r.dmgMul = 2.5; break;
			case 12: hp = 5600; spd = 8;  r.painChance = 32;  r.dmgMul = 3.0; break;
			// TEX -- CHP 07_KX CommonBlackSpectreEX2's own numbers.
			case 13: hp = 7250; spd = 20; r.painChance = 30;  r.dmgMul = 4.0; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 150.0;
		r.spdMul = double(spd) / 10.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		return "SARG SRGG SRGB WRM2 SAR2 SRG2 DOGA SRGF BPWA SRGY SRGR SHDW SLGM GKEX";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:spectre role:bruiser delivery:melee element:kinetic mobility:ground trait:stealth";
	}

	// -----------------------------------------------------------------
	// THE ROGUE (named RS mechanic, preserved). Builds a counter while
	// stalking, then warps behind you and opens with a free hit. This is
	// the RS expression of CHP 07_K's user_hm / GETTO / BACKSTABBUU: the
	// T11 See cluster below feeds the same counter with CHP's own sight
	// accounting (+2 while unseen, -1 while watched).
	// -----------------------------------------------------------------
	const RS_SPEC_TIER_BACKSTAB = 6;
	const RS_SPEC_STAB_AT       = 10;

	void RS_Stalk()
	{
		if (Tier < RS_SPEC_TIER_BACKSTAB)
			return;
		AddCharge(1);
	}

	// Warp to just behind the target. Returns false if there was nowhere
	// to land, so the caller can fall through to a normal approach.
	bool RS_Backstab()
	{
		if (!target || ChargeCounter < RS_SPEC_STAB_AT)
			return false;

		ResetCharge();

		// Behind the target, relative to the way IT is facing.
		double ang = target.angle + 180;
		Vector3 p = (target.pos.xy + (cos(ang), sin(ang)) * 56.0, target.pos.z);

		if (!TeleportMove(p, false))
			return false;

		angle = target.angle;      // facing its back
		A_StartSound("spectre/sight", CHAN_VOICE);
		return true;
	}

	States
	{
	// ===== dispatcher override: the Rogue stalks between walk cycles.
	// Tier See clusters end with `Goto See`, so this runs once per
	// cycle. =====
	See:
		TNT1 A 0
		{
			RS_Stalk();
			if (ChargeCounter >= RS_SPEC_STAB_AT && RS_Backstab())
				return ResolveState("Melee");
			return TierState("See");
		}
		TNT1 A 4 { A_Chase(); }
		Goto See;

	// ================= T00 COMMON (07_C) =================
	Spawn.T00:
		"SARG" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"SARG" AABBCCDD 2 Fast { A_Chase(); }
		Goto See;
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
	Raise.T00:
		"SARG" N 5;
		"SARG" MLKJI 5;
		Goto See;

	// ================= T01 GREEN (07_G) =================
	Spawn.T01:
		"SRGG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"SRGG" AABBCCDD 2 Fast { A_Chase(); }
		Goto See;
	Melee.T01:
		"SRGG" EF 7 Fast { A_FaceTarget(); }
		"SRGG" G 7 Fast { A_CustomMeleeAttack(random(13, 40), "demon/melee", "none"); }
		Goto See;
	Pain.T01:
		"SRGG" H 2 Fast;
		"SRGG" H 2 Fast { A_Pain(); }
		Goto See;
	Death.T01:
		"SRGG" I 8;
		"SRGG" J 8 { A_Scream(); }
		"SRGG" K 4;
		"SRGG" L 4 { A_NoBlocking(); }
		"SRGG" M 4;
		"SRGG" N -1;
		Stop;
	Raise.T01:
		"SRGG" N 5;
		"SRGG" MLKJI 5;
		Goto See;

	// ================= T02 BLUE (07_B) =================
	// Bites in close; rushes like a lost soul from inside 800.
	Spawn.T02:
		"SRGB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"SRGB" AABBCCDD 2 Fast { A_Chase(); }
		Goto See;
	Missile.T02:
		"SRGB" E 0 A_JumpIfCloser(800, "Missile.T02.Rush");
		Goto See;
	Missile.T02.Rush:
		"SRGB" F 1 { A_FaceTarget(); }
		"SRGB" F 3 { A_SkullAttack(15); }
		Goto See;
	Melee.T02:
		"SRGB" EF 7 Fast { A_FaceTarget(); }
		"SRGB" G 7 Fast { A_CustomMeleeAttack(random(15, 43), "demon/melee", "none"); }
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
	Raise.T02:
		"SRGB" N 5;
		"SRGB" MLKJI 5;
		Goto See;

	// ============ T03 CYAN -- SNEAKY ICE WORM (07_CY) ============
	// Shrinks out of sight leaving a ring of ice spikes, wanders at speed
	// 77 while hidden, and shatters on death.
	Spawn.T03:
		"WRM2" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"WRM2" AABB 3 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "Missile.T03.HideMe");
		"WRM2" CCDD 3 { A_Chase(); }
		TNT1 A 0 A_Jump(64, "Missile.T03.HideMe");
		Goto See;
	See.T03.Open:
		"WRM2" AABB 3 { A_Chase(); }
		"WRM2" CCDD 3 { A_FastChase(); }
		Goto See;
	Missile.T03:
		"WRM2" G 2 { A_SetScale(1.0, 0.25); }
		"WRM2" G 2 { A_SetScale(1.0, 0.5); }
		"WRM2" G 2 { A_SetScale(1.0, 1.0); }
		TNT1 A 0 { bNOPAIN = false; }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(0, 90)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(89, 180)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(181, 270)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 0, 0, 1, random(12, 20), 0, random(15, 25), random(271, 359)); }
		"WRM2" E 8 { A_FaceTarget(); }
		"WRM2" E 0 A_JumpIfCloser(72, "Melee.T03");
		"WRM2" E 8 A_JumpIfCloser(700, "Missile.T03.Hiss");
		// falls through into HideMe, exactly as CHP does
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
		Goto See.T03.Open;
	Missile.T03.Hiss:
		"WRM2" EF 4 { A_FaceTarget(); }
		"WRM2" G 8 { A_SkullAttack(40); }
		Goto See;
	Melee.T03:
		"WRM2" G 1 { A_SetScale(1.0, 1.0); }
		TNT1 A 0 { bNOPAIN = false; }
		"WRM2" EF 4 { A_FaceTarget(); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 24, random(9, 33), 0, random(3, 9), frandom(-9, 9)); }
		TNT1 AAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 29, random(9, 33), 0, random(4, 12), frandom(-4, 4)); }
		"WRM2" G 4 { A_CustomMeleeAttack(random(10, 48), "slimeworm/melee", "none"); }
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
		TNT1 A 0 { A_SpawnItemEx("RS_CHCirno", 0, 0, 24, vel.x, vel.y, vel.z, 0, SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION, 253); }
		"WRM2" N 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		"WRM2" N 1 { A_Burst("IceChunk"); }
		Stop;

	// ================= T04 PURPLE (07_P) =================
	// Barking hound: bite, or a long 25-speed rush from inside 800.
	Spawn.T04:
		"SAR2" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"SAR2" A 4;
		"SAR2" AABBCCDD 2 Fast { A_Chase(); }
		Goto See;
	Missile.T04:
		"SAR2" E 0 A_JumpIfCloser(800, "Missile.T04.Rush");
		Goto See;
	Missile.T04.Rush:
		"SAR2" F 2 { A_FaceTarget(); }
		"SAR2" F 10 { A_SkullAttack(25); }
		Goto See;
	Melee.T04:
		"SAR2" EF 7 Fast { A_FaceTarget(); }
		"SAR2" G 6 Fast { A_CustomMeleeAttack(random(13, 46), "monster/dogatk", "none"); }
		Goto See;
	Pain.T04:
		"SAR2" H 2 Fast;
		"SAR2" H 2 Fast { A_Pain(); }
		"SAR2" H 2 Bright A_Jump(100, "Missile.T04");
		Goto See;
	Death.T04:
		"SAR2" I 8;
		"SAR2" J 8 { A_Scream(); }
		"SAR2" K 4;
		"SAR2" L 4 { A_NoBlocking(); }
		"SAR2" M 4;
		"SAR2" N -1;
		Stop;
	Raise.T04:
		"SAR2" N 5;
		"SAR2" MLKJI 5;
		Goto See;

	// ============ T05 YELLOW -- BLOOD DEMON (07_Y) ============
	// Pain rolls a speed buff that drops its stealth; the next walk cycle
	// calms it back down. rsCalm is CHP's User_Calm, including CHP's own
	// self-assignment idiom.
	Spawn.T05:
		"SRG2" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"SRG2" A 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRG2" AABB 2 { A_Chase(); }
		"SRG2" C 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRG2" CCDD 2 { A_Chase(); }
		"SRG2" A 0 { if (rsCalm == 1) return ResolveState("See.T05.Calm"); return ResolveState(null); }
		Goto See;
	See.T05.Calm:
		"SRG2" E 1 { A_SetSpeed(17); }
		"SRG2" E 1 { bSTEALTH = true; }
		Goto See;
	Melee.T05:
		"SRG2" EF 8 { A_FaceTarget(); }
		"SRG2" G 8 { A_CustomMeleeAttack(random(13, 52), "blooddemon/melee", "none"); }
		"SRG2" G 1 { rsCalm = (rsCalm == 1) ? 1 : 0; }
		Goto See;
	Pain.T05:
		"SRG2" H 2;
		"SRG2" H 2 { A_Pain(); }
		"SRG2" H 1 A_Jump(128, "Pain.T05.SpeedBuff");
		Goto See;
	Pain.T05.SpeedBuff:
		"SRG2" E 1 { A_SetSpeed(31); }
		"SRG2" E 1 { bSTEALTH = false; }
		"SRG2" E 1 { rsCalm = (rsCalm == 0) ? 1 : 0; }
		Goto See;
	Death.T05:
		"SRG2" I 8;
		"SRG2" I 0 { A_FaceTarget(); }
		"SRG2" J 0 { A_SpawnItemEx("RS_BloodDemonArm", 10, 0, 32, 0, 8, 0, 0, SXF_NOCHECKPOSITION|SXF_TRANSFERRENDERSTYLE); }
		"SRG2" J 8 { A_Scream(); }
		"SRG2" K 4;
		"SRG2" L 4 { A_NoBlocking(); }
		"SRG2" M 4;
		"SRG2" N -1;
		Stop;
	XDeath.T05:
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		"POSS" PPPPPP 1;
		"POSS" R 4 { A_XScream(); }
		"POSS" S 5;
		"POSS" T 4 { A_NoBlocking(); }
		"POSS" U -1;
		Stop;
	Raise.T05:
		"SRG2" NMLKJI 5;
		Goto See;

	// ============ T06 ABYSS -- ABYSS DOG (07_A) ============
	// Stats from CHP 06_A CommonAbyssDemon (07_A overrides only Alpha).
	// Prowls submerged at alpha 0.10 trailing abyss splash; surfacing to
	// attack makes it solid, and it re-hides afterwards.
	Spawn.T06:
		"DOGA" A 10 { A_Look(); }
		Loop;
	See.T06:
		TNT1 A 0 { if (rsHidden >= 1) return ResolveState("See.T06.Rehide"); return ResolveState(null); }
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
		Goto See;
	See.T06.Rehide:
		"DOGA" G 1 Bright;
		"DOGA" G 1 Bright { A_SetTranslucent(0.70); }
		"DOGA" G 1 Bright { A_SetTranslucent(0.40); }
		"DOGA" G 1 Bright { A_SetTranslucent(0.10); }
		"DOGA" G 1 { rsHidden = 0; }
		Goto See;
	Melee.T06:
		"DOGA" G 0 { A_FaceTarget(); }
		"DOGA" G 2 { A_SetTranslucent(1.00); }
		"DOGA" G 3 { rsHidden++; }
		"DOGA" H 4 { A_FaceTarget(); }
		"DOGA" I 6 { A_CustomMeleeAttack(random(17, 58), "blooddemon/melee", "none"); }
		"DOGA" I 1 A_Jump(86, "Missile.T06");
		Goto See;
	Missile.T06:
		"DOGA" G 2 { A_SetTranslucent(1.00); }
		"DOGA" G 3 { rsHidden++; }
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
	Raise.T06:
		"DOGA" QPONMLK 5;
		Goto See;

	// ================= T07 FIREBLU (07_F) =================
	// 07_F defines only Spawn/Idle/Raise -- See, Missile/Rush, Melee,
	// Pain and Death all come from its CHP parent 06_F
	// CommonFirebluDemon, as do Health/Speed/PainChance.
	Spawn.T07:
		"SRGF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"SRGF" A 4;
		"SRGF" ABBCCDDA 4 Fast { A_Chase(); }
		Goto See;
	Missile.T07:
		"SRGF" E 0 Bright A_JumpIfCloser(800, "Missile.T07.Rush");
		Goto See;
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
		"SRGF" G 8 Fast { A_CustomMeleeAttack(random(15, 50), "demon/melee", "none"); }
		Goto See;
	Pain.T07:
		"SRGF" H 2 Fast;
		"SRGF" H 2 Fast { A_Pain(); }
		Goto See;
	Death.T07:
	XDeath.T07:
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		"ZOMF" PPPPPP 1;
		"ZOMF" R 4 { A_XScream(); }
		"ZOMF" S 5;
		"ZOMF" AAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 2, random(-359, 359), SXF_NOCHECKPOSITION, 64); }
		"ZOMF" T 4 { A_NoBlocking(); }
		"ZOMF" U -1;
		Stop;
	Raise.T07:
		"SRGF" N 5;
		"SRGF" MLKJI 5;
		Goto See;

	// ============ T08 BROWN -- PROWLER (07_BR) ============
	// Occasionally checks for pack-mates it can see; if any demon or
	// spectre is within 300 it rallies them -- heals the pack and throws
	// medi-orbs. CHP's ACS-only BrownImpCommand / SpeedBuffPE tokens are
	// dropped (see header).
	Spawn.T08:
		"BPWA" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"BPWA" AABBCCDD 2 { A_Chase(); }
		"BPWA" A 0 A_Jump(16, "See.T08.CheckFriends");
		Goto See;
	See.T08.CheckFriends:
		"BPBI" A 0 A_CheckSight("See.T08.Meh");
		"BPBI" A 0 { A_CheckProximity("See.T08.Scatter", "RS_Demon", 300, 1, CPXF_ANCESTOR|CPXF_CHECKSIGHT); }
		"BPBI" A 0 { A_CheckProximity("See.T08.Scatter", "RS_Spectre", 300, 1, CPXF_ANCESTOR|CPXF_CHECKSIGHT); }
		"BPBI" A 0 { A_StartSound("BPinky/Idle", CHAN_VOICE); }
		"BPBI" AC 5;
		// falls through into Meh, exactly as CHP does
	See.T08.Meh:
		"BPWA" AABBCCDD 2 { A_Wander(); }
		Goto See;
	See.T08.Scatter:
		// RESTORED (rs_19 / L2). CHP 07_BR.txt:38-41 opens Scatter with FOUR
		// A_RadiusGive lines that this port dropped, on the since-disproven
		// reasoning that BrownImpCommand and SpeedBuffPE were empty ACS
		// wrappers. They are not: their ACS gives +10 speed, ALWAYSFAST and
		// a physical shove for 180/600 tics. Rebuilt in RS_MonsterCommands.zs.
		// This is what makes the Prowler a RALLY -- without it, "scatter"
		// only healed and threw medi-orbs, and the pack never sped up.
		// CHP splits each buff across species "Demon1" and "Spectre"; our
		// monsters do not set Species, so one call covers both -- the same
		// simplification the Health line below already makes.
		"BPBI" A 0 { A_RadiusGive("RS_BrownImpCommand", 320, RGF_MONSTERS|RGF_EXFILTER, 1, "RS_Spectre"); }
		"BPBI" A 0 { A_RadiusGive("RS_PESpeedBuff",     320, RGF_MONSTERS|RGF_EXFILTER, 1, "RS_Spectre"); }
		"BPBI" A 0 { A_StartSound("BPinky/Sight", CHAN_VOICE); }
		"BPBI" AC 3 { A_SpawnItemEx("RS_MediCacoBrown", random(-164, 164), random(-164, 164), random(8, 64), random(1, 9), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		"BPBI" A 3 { A_RadiusGive("Health", 1200, RGF_MONSTERS|RGF_EXFILTER, 200, "RS_Spectre"); }
		"BPBI" C 3 { A_RadiusGive("Health", 1200, RGF_MONSTERS|RGF_EXFILTER, 200, "RS_Spectre"); }
		"BPBI" ACAC 3 { A_SpawnItemEx("RS_MediCacoBrown", random(-164, 164), random(-164, 164), random(8, 64), random(1, 9), 0, random(-5, 5), random(0, 359), SXF_NOCHECKPOSITION); }
		"BPBI" A 0 { A_StartSound("BPinky/Sight", CHAN_VOICE); }
		"BPBI" ACAC 6;
		Goto See;
	Melee.T08:
		"BPBI" AB 6 { A_FaceTarget(); }
		"BPBI" C 6 { A_CustomMeleeAttack(random(1, 10) * 8 + random(1, 10), "Bite/bite4", "", "Melee"); }
		Goto See;
	Pain.T08:
		"BPPA" A 2 { A_Pain(); }
		Goto See;
	Death.T08:
		"BPDE" A 0 { A_NoBlocking(); }
		"BPDE" A 0 { A_ScreamAndUnblock(); }
		"BPDE" ABCDEF 6;
		"BPDE" F -1;
		Stop;
	Raise.T08:
		"BPDE" FEDCBA 6;
		Goto See;

	// ============ T09 GRAY -- STOMPER (07_GY) ============
	// Standalone CHP actor (no parent). Near-invisible (Add, alpha 0.05),
	// leaps and lands a four-way ground quake. Chases with an explicit
	// melee state and no missile state, exactly as CHP does.
	Spawn.T09:
		"SRGY" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"SRGY" A 0 { A_SetSpeed(8); }
		"SRGY" A 0 { A_SetScale(1.10, 1.00); }
		"SRGY" A 3 Fast { A_Chase(); }
		"SRGY" ABBCCDD 3 Fast { A_Chase("Melee.T09", null); }
		Goto See;
	Missile.T09:
		"SRGY" EEEE 8 Fast { A_FaceTarget(); }
		"SRGY" F 0 { A_StartSound("monster/dogatk", CHAN_VOICE); }
		"SRGY" F 0 { A_Recoil(-100); }
		"SRGY" F 1 ThrustThingZ(0, 20, 0, 0);
	Missile.T09.Air:
		"SRGY" F 1 A_CheckFloor("Missile.T09.Land");
		Loop;
	Missile.T09.Land:
		"SRGY" E 0 Radius_Quake(2, 60, 0, 40, 0);
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
		Goto Missile.T09;
	Melee.T09.BiteIt:
		"SRGY" G 6 Fast { A_CustomMeleeAttack(random(1, 10) * 8 + random(1, 10), "Bite/bite4", "", "Melee"); }
		Goto See;
	Pain.T09:
		// CHP's gray spectre has PainChance 0, defines NO pain state, and
		// has no parent to inherit one from. This two-frame stub exists
		// only so the tier dispatch never falls back to T00's SARG body;
		// with PainChance 0 it is unreachable in normal play.
		"SRGY" H 2;
		"SRGY" H 2 { A_Pain(); }
		Goto See;
	Death.T09:
		"SRGY" I 8;
		"SRGY" J 8 { A_Scream(); }
		"SRGY" K 4;
		"SRGY" L 4 { A_NoBlocking(); }
		"SRGY" M 4;
		"SRGY" N -1;
		Stop;
	Raise.T09:
		"SRGY" NMLKJI 5;
		Goto See;

	// ============ T10 RED -- BLOOD DEMON (07_R) ============
	// Bite plus a six-bolt blood spray; pain rolls a buff that turns on
	// NOPAIN, drops stealth and raises speed to 25.
	Spawn.T10:
		"SRGR" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"SRGR" A 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRGR" AABB 2 { A_Chase(); }
		"SRGR" C 0 { A_StartSound("blooddemon/walk", CHAN_BODY); }
		"SRGR" CCDD 2 { A_Chase(); }
		Goto See;
	Melee.T10:
		"SRGR" EF 6 { A_FaceTarget(); }
		"SRGR" G 4 { A_CustomMeleeAttack(random(10, 55), "blooddemon/melee", "none"); }
		"SRGR" G 1 { A_SpawnItemEx("RS_RedThingsLS", 1, 3, 15, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SRGR" G 0 { A_SpawnItemEx("RS_RedThingsLS", 6, 3, 15, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"SRGR" GGGGGG 0 { A_SpawnProjectile("RS_RedDemonBloodBolt3", random(32, 48), 0, random(-17, 17)); }
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
		"SRGR" E 1 { bSTEALTH = false; }
		"SRGR" E 1 { A_SetTranslucent(1); }
		Goto See;
	Death.T10:
		"SRGR" I 8;
		"SRGR" I 0 { A_FaceTarget(); }
		"SRGR" J 0 { A_SpawnItemEx("RS_BloodDemonArm2", 10, 0, 32, 0, 8, 0, 0, SXF_NOCHECKPOSITION|SXF_TRANSFERRENDERSTYLE); }
		"SRGR" J 8 { A_Scream(); }
		"SRGR" K 4;
		"SRGR" L 4 { A_NoBlocking(); }
		"SRGR" M 4;
		"SRGR" N -1;
		Stop;
	XDeath.T10:
		TNT1 A 0 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		"POSS" PPPPPP 1;
		"POSS" R 4 { A_XScream(); }
		"POSS" S 5;
		"POSS" T 4 { A_NoBlocking(); }
		"POSS" U -1;
		Stop;
	Raise.T10:
		"SRGR" NMLKJI 5;
		Goto See;

	// ============ T11 BLACK -- THE ROGUE (07_K) ============
	// Fades to 0.12 and stalks, leaving after-images. While it is unseen
	// the stalk counter climbs (+2); while watched it falls (-1). At 10
	// the See dispatcher warps it behind you (RS_Backstab -- CHP's GETTO)
	// and it opens with a free hit.
	Spawn.T11:
		"SHDW" EE 1 { A_Look(); }
		Loop;
	See.T11:
		"SHDW" E 15;
		"SHDW" E 0 { A_SetTranslucent(0.45); }
		"SHDW" AAA 1 { A_Chase(); }
		"SHDW" A 0 { A_SpawnItemEx("RS_ShadowGhostA", 0, 0, 0, 0, 0, 0, 0, 128); }
		"SHDW" BBB 1 { A_Chase(); }
		"SHDW" B 0 { A_SpawnItemEx("RS_ShadowGhostB", 0, 0, 0, 0, 0, 0, 0, 128); }
		"SHDW" CCC 1 { A_Chase(); }
		"SHDW" C 0 { A_SpawnItemEx("RS_ShadowGhostC", 0, 0, 0, 0, 0, 0, 0, 128); }
		"SHDW" DDD 1 { A_Chase(); }
		"SHDW" D 0 { A_SpawnItemEx("RS_ShadowGhostD", 0, 0, 0, 0, 0, 0, 0, 128); }
		"SHDW" AAA 1 { A_Chase(); }
		"SHDW" A 0 { A_SpawnItemEx("RS_ShadowGhostA", 0, 0, 0, 0, 0, 0, 0, 128); }
		"SHDW" BBB 1 { A_Chase(); }
		"SHDW" B 0 { A_SpawnItemEx("RS_ShadowGhostB", 0, 0, 0, 0, 0, 0, 0, 128); }
		"SHDW" CCC 1 { A_Chase(); }
		"SHDW" C 0 { A_SpawnItemEx("RS_ShadowGhostC", 0, 0, 0, 0, 0, 0, 0, 128); }
		"SHDW" DDD 1 { A_Chase(); }
		"SHDW" D 0 { A_SpawnItemEx("RS_ShadowGhostD", 0, 0, 0, 0, 0, 0, 0, 128); }
		Goto See.T11.Deep;
	See.T11.Deep:
		"SHDW" E 5 { A_SetTranslucent(0.12); }
		"SHDW" AAABBBCCCDDDAAABBBCCCDDD 1 { A_Chase(); }
		"SHDW" D 0 A_CheckSight("See.T11.Unseen");
		"SHDW" D 0 { AddCharge(-1); }
		"SHDW" E 5 { A_SetTranslucent(0.45); }
		Goto See;
	See.T11.Unseen:
		TNT1 A 0 A_CheckRange(1000, "See");
		"SHDW" D 0 { AddCharge(2); }
		Goto See;
	Melee.T11:
		"SHDW" E 0 { bTHRUACTORS = false; }
		"SHDW" E 0 { A_SetTranslucent(0.45); }
		"SHDW" EF 4 { A_FaceTarget(); }
		"SHDW" G 2 { A_CustomMeleeAttack(random(25, 65), "Shadow/attack", "none"); }
		"SHDW" G 0 A_Jump(12, "Missile.T11.Teleport");
		Goto See;
	Missile.T11:
		"SHDW" E 0 { bTHRUACTORS = false; }
		"SHDW" E 0 { A_SetTranslucent(0.45); }
		"SHDW" E 0 A_Jump(256, "Missile.T11.Balls", "Missile.T11.Teleport");
		Goto See;
	Missile.T11.Balls:
		"SHDW" E 6 { A_FaceTarget(); }
		"SHDW" F 4 { A_FaceTarget(); }
		"SHDW" GGG 5 Bright { A_SpawnProjectile("RS_ShadowBall", 32, 0, random(-3, 3)); }
		"SHDW" F 4 { A_FaceTarget(); }
		"SHDW" E 2 A_CheckSight("Missile.T11.Teleport");
		"SHDW" E 0 A_Jump(82, "Missile.T11.BigOne");
		"SHDW" E 1 { A_SpidRefire(); }
		Goto Missile.T11;
	Missile.T11.BigOne:
		"SHDW" F 8 Bright { A_FaceTarget(); }
		"SHDW" G 8 Bright { A_SpawnProjectile("RS_ShadowBall2", 32, 0, random(-3, 3)); }
		Goto Missile.T11.Balls;
	Missile.T11.Teleport:
		"SHDW" F 2 { A_SpawnItemEx("RS_TeleporterSpotSH", 0, 0, 3, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"SHDW" E 8 { A_StartSound("Shadow/active", CHAN_VOICE); }
		"SHDW" E 4 { bTHRUACTORS = true; }
		"SHDW" E 4 { AddCharge(3); }
		"SHDW" E 2 { A_Teleport("See", "RS_TeleporterSpotSH", null, TF_KEEPVELOCITY); }
		Goto See;
	Pain.T11:
		"SHDW" H 4 { A_SetTranslucent(0.45); }
		"SHDW" H 4 { A_Pain(); }
		"SHDW" H 2 A_Jump(88, "Missile.T11.Teleport");
		Goto See;
	Death.T11:
		"SHDX" A 12;
		"SHDX" B 12 { A_Scream(); }
		"SHDX" C 13;
		"SHDX" D 13 { A_NoBlocking(); }
		"SHDX" EF 13;
		"SHDX" G -1;
		Stop;

	// ============ T12 WHITE -- SLIME GOLEM (07_W) ============
	// Submerged it is invulnerable and untargetable; it surfaces to peek,
	// to bite, or to throw one of three slime volleys, and under 2500 HP
	// it turns on MISSILEMORE/MISSILEEVENMORE. Pain can spawn a Wakawaka.
	// SLGM frames F and '\' have no file anywhere in CH/CHP (see header)
	// and are dropped from Idle/PeekUp only.
	Spawn.T12:
		"SLGM" ZZZZZZHHHHHHGGGGGG 1 { A_Look(); }
		"SLGM" GGGGGGHHHHHHZZZZZZ 1 { A_Look(); }
		Loop;
	See.T12:
		TNT1 A 0 { bNOTARGET = false; }
		TNT1 A 0 { if (rsRisen >= 1) return ResolveState("See.T12.Walk"); return ResolveState(null); }
		TNT1 A 0 { rsRisen = 1; }
		TNT1 A 0 { A_UnsetInvulnerable(); }
		"SLGM" GEDCBA 3;
		Goto See.T12.Walk;
	See.T12.Walk:
		TNT1 A 0 { A_SetInvulnerable(); }
		TNT1 A 0 { bNOTARGET = true; }
		TNT1 AA 2 { A_Chase(); }
		TNT1 A 0 A_Jump(8, "See.T12.PeekUp");
		Goto See;
	See.T12.FastWalk:
		TNT1 A 0 { A_SetInvulnerable(); }
		TNT1 A 0 { bNOTARGET = true; }
		TNT1 A 0 { A_SetSpeed(19); }
		TNT1 AA 2 { A_Chase(); }
		TNT1 A 0 A_Jump(8, "See.T12.PeekUp");
		Goto See;
	See.T12.PeekUp:
		TNT1 A 0 { bNOTARGET = false; }
		TNT1 A 0 { A_UnsetInvulnerable(); }
		TNT1 A 0 { A_SetSpeed(8); }
		"SLGM" ABCDEG 4;
		"SLGM" HZ 5;
		"SLGM" ZH 5;
		"SLGM" VWXY 4;
		Goto See.T12.Walk;
	Melee.T12:
		TNT1 A 0 { bNOTARGET = false; }
		TNT1 A 0 { A_UnsetInvulnerable(); }
		TNT1 A 0 { A_SetSpeed(8); }
		"SLGM" IJKLMN 1;
		"SLGM" OOO 4 { A_CustomMeleeAttack(random(20, 50), "slgmbite", "slgmbite", "Normal", true); }
		"SLGM" NMLKJI 1;
		Goto See.T12.Walk;
	Missile.T12:
		TNT1 A 0 { bNOTARGET = false; }
		TNT1 A 0 { A_UnsetInvulnerable(); }
		TNT1 A 0 { A_SetSpeed(8); }
		"SLGM" A 0 A_JumpIfHealthLower(2500, "Missile.T12.Angar");
	Missile.T12.Wind:
		"SLGM" IJKLMN 1;
		"SLGM" N 0 A_Jump(256, "Missile.T12.Atk1", "Missile.T12.Atk2", "Missile.T12.Atk3");
		Goto See;
	Missile.T12.Angar:
		TNT1 A 0 { bMISSILEMORE = true; }
		TNT1 A 0 { bMISSILEEVENMORE = true; }
		Goto Missile.T12.Wind;
	Missile.T12.Atk1:
		"SLGM" N 5 { A_FaceTarget(); }
		"SLGM" O 0 { A_SpawnProjectile("RS_SpecSlime1", 40, 0, 7); }
		"SLGM" O 0 { A_SpawnProjectile("RS_SpecSlime1", 40, 0, -7); }
		"SLGM" O 5 Bright { A_SpawnProjectile("RS_SpecSlime1", 40, 0); }
		"SLGM" NMLKJI 1;
		Goto See;
	Missile.T12.Atk2:
		"SLGM" N 5 { A_FaceTarget(); }
		"SLGM" O 3 Bright { A_SpawnProjectile("RS_SpecSlime2", 40, 0, random(-1, 1)); }
		"SLGM" O 1 Bright { A_SpawnProjectile("RS_SpecSlime2", 40, 0, random(-12, 12)); }
		"SLGM" N 1 { A_FaceTarget(); }
		"SLGM" O 3 Bright { A_SpawnProjectile("RS_SpecSlime2", 40, 0, random(-12, 12)); }
		"SLGM" O 1 Bright { A_SpawnProjectile("RS_SpecSlime2", 40, 0, random(-1, 1)); }
		"SLGM" N 1 { A_FaceTarget(); }
		"SLGM" O 3 Bright { A_SpawnProjectile("RS_SpecSlime2", 40, 0, random(-6, 6)); }
		"SLGM" O 3 Bright { A_SpawnProjectile("RS_SpecSlime2", 40, 0, random(-6, 6)); }
		"SLGM" NMLKJI 1;
		Goto See;
	Missile.T12.Atk3:
		"SLGM" N 12 { A_FaceTarget(); }
		"SLGM" O 5 Bright { A_SpawnProjectile("RS_SpecSlime3", 15, 0); }
		"SLGM" NMLKJI 1;
		Goto See;
	Pain.T12:
		"SLGM" J 5;
		"SLGM" J 5 { A_Pain(); }
		"SLGM" I 3 A_Jump(64, "Pain.T12.FaceSpawn");
		"SLGM" NMLKJI 1;
		Goto See.T12.FastWalk;
	Pain.T12.FaceSpawn:
		"SLGM" J 4;
		"SLGM" K 6 { A_SpawnItemEx("RS_Wakawaka", 0, 0, 0, 0, 0, 4, 0, SXF_NOCHECKPOSITION|SXF_SETMASTER); }
		"SLGM" NMLKJI 1;
		Goto See.T12.FastWalk;
	Death.T12:
		"SLGM" VWXY 5;
		TNT1 A 5;
		TNT1 AAAA 0 { A_Wander(); }
		"SLGM" P 5 { A_Scream(); }
		"SLGM" QRST 5;
		"SLGM" U 5 { A_NoBlocking(); }
		"SLGM" U -1;
		Stop;

	// ============ TEX BLACK EX -- THE BACKSTABBER UNSILENCED (07_KX) ============
	// The T11 rogue, promoted. Two walk modes it flips between on its own:
	// mode 1 is solid at alpha 0.45 and speed 20 and answers with Missile;
	// mode 2 is a NOCLIP ghost at alpha 0.12 and speed 12 that answers with
	// Charge instead -- it walks through the geometry to reach you.
	//
	// THE STALK COUNTER (CHP user_hm, rsExStalk here) is the fight. Every
	// tick of distance you keep adds to it; at 10 it stops shooting, warps
	// to a point 38 units off your flank, and opens with two 40-99 melee
	// hits. Backstabbing costs it 6 more on the counter, so the punish is
	// self-limiting -- but running away is what loads it.
	//
	// Every stride drops a ghost of that stride's frame, so the silhouette
	// you are tracking is four frames behind the thing that is actually
	// there. Its dark beam blinds on impact rather than hurting.
	Spawn.TEX:
		"GKEX" AA 1 { A_Look(); }
		Loop;
	See.TEX:
		"GKEX" E 0
		{
			if (rsExMode != 0)
				return ResolveState("See.TEX.Mode2");
			return ResolveState(null);
		}
		Goto See.TEX.Mode1;
	// The mode flip. CHP latches this on a DewzanToken; rsExMode is the
	// same latch as a field.
	See.TEX.Switch:
		TNT1 A 0
		{
			if (rsExMode != 0)
			{
				rsExMode = 0;
				return ResolveState("See.TEX.Mode1");
			}
			rsExMode = 1;
			return ResolveState("See.TEX.Mode2");
		}
		Goto See;
	See.TEX.Mode1:
		"GKEX" A 0 { A_SetTranslucent(0.45); }
		"GKEX" A 0 { A_SetSpeed(20); }
		"GKEX" A 8 { bNOCLIP = false; }
	See.TEX.Mode1B:
		"GKEX" BBB 1 { A_Chase("Melee", "Missile", CHF_NOPLAYACTIVE); }
		"GKEX" B 0 { A_SpawnItemEx("RS_ShadowGhostEXB", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"GKEX" CCC 1 { A_Chase("Melee", "Missile", CHF_NOPLAYACTIVE); }
		"GKEX" C 0 { A_SpawnItemEx("RS_ShadowGhostEXC", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"GKEX" DDD 1 { A_Chase("Melee", "Missile", CHF_NOPLAYACTIVE); }
		"GKEX" D 0 { A_SpawnItemEx("RS_ShadowGhostEXD", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"GKEX" EEE 1 { A_Chase("Melee", "Missile"); }
		"GKEX" E 0 { A_SpawnItemEx("RS_ShadowGhostEXE", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"GKEX" E 0 A_Jump(8, "See.TEX.Stalk");
		"GKEX" E 0 A_Jump(3, "See.TEX.Switch");
		Loop;
	See.TEX.Mode2:
		"GKEX" A 0 { A_SetTranslucent(0.12); }
		"GKEX" A 0 { A_SetSpeed(12); }
		"GKEX" A 8 { bNOCLIP = true; }
	See.TEX.Mode2B:
		"GKEX" BBBCCCDDD 2 { A_Chase("Melee", "Missile.TEX.Charge", CHF_NOPLAYACTIVE); }
		"GKEX" EEE 2 { A_Chase("Melee", "Missile.TEX.Charge"); }
		"GKEX" E 0 A_Jump(16, "See.TEX.Stalk");
		"GKEX" E 0 A_Jump(6, "See.TEX.Switch");
		Loop;
	// Distance is what loads the counter -- inside 1000 it never ticks.
	See.TEX.Stalk:
		"GKEX" A 0 A_JumpIfCloser(1000, "See");
		TNT1 A 0
		{
			if (rsExStalk >= 10)
				return ResolveState("See.TEX.Getto");
			rsExStalk += 2;
			return ResolveState(null);
		}
		Goto See;
	// Three flank offsets tried in order; the fourth is the bail-out that
	// just drops it into ghost mode wherever it lands.
	See.TEX.Getto:
		"GKEX" A 20 { A_StartSound("Shadow/pain", CHAN_7, 0, 2.0, ATTN_NONE); }
		"GKEX" A 0 { A_Warp(AAPTR_TARGET, -38, 0, 16, 0, WARPF_INTERPOLATE, "Melee.TEX.Backstab"); }
		"GKEX" A 0 { A_Warp(AAPTR_TARGET, 0, -38, 16, 0, WARPF_INTERPOLATE, "Melee.TEX.Backstab"); }
		"GKEX" A 0 { A_Warp(AAPTR_TARGET, 0, 38, 16, 0, WARPF_INTERPOLATE, "Melee.TEX.Backstab"); }
		"GKEX" A 0 { A_Warp(AAPTR_TARGET, -38, 0, 16, 0, WARPF_INTERPOLATE|WARPF_NOCHECKPOSITION, "See.TEX.Mode2"); }
		Goto See;
	Melee.TEX.Backstab:
		"GKEX" A 5 Bright { A_FaceTarget(); }
		"GKEX" F 15 Bright { A_FaceTarget(); }
		"GKEX" G 5 { A_CustomMeleeAttack(random(40, 99), "Butcher/Melee", "none"); }
		"GKEX" F 5 Bright { A_FaceTarget(); }
		"GKEX" G 5 { A_CustomMeleeAttack(random(40, 99), "Butcher/Melee", "none"); }
		"GKEX" G 0 { rsExStalk += 6; }
		Goto Melee.TEX.GetBackHere;
	// The blink. NOPAIN for the duration, speed 99, and it leaves a
	// fading copy of itself standing where it was.
	Missile.TEX.Warp:
		"GKEX" A 8 { bNOPAIN = true; }
		"GKEX" A 0 { bNOCLIP = false; }
		"GKEX" A 0 { A_SpawnItemEx("RS_ShadowWarpGhostEX", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_TRANSFERALPHA); }
		"GKEX" A 0 { rsExStalk += 3; }
		TNT1 A 1 { A_SetSpeed(99); }
		TNT1 AAAAAAAAAAAAAAAA 0 { A_Wander(); }
		TNT1 A 1 { bNOPAIN = false; }
		TNT1 A 0 A_Jump(128, "See.TEX.Switch");
		Goto See;
	// Ghost mode's answer: kill its own momentum, then rocket in.
	Missile.TEX.Charge:
		"GKEX" A 0 A_JumpIfCloser(800, "Missile.TEX.Charge.Go");
		Goto Missile;
	Missile.TEX.Charge.Go:
		"GKEX" AA 8 { A_FaceTarget(); }
		"GKEX" A 6 { A_FaceTarget(); }
		"GKEX" A 2 { A_ScaleVelocity(0.01); }
		"GKEX" A 0 { A_StartSound("Ice/Fly", CHAN_BODY); }
		"GKEX" A 0 { A_Recoil(-48); }
		"GKEX" A 0 ThrustThingZ(0, 30, 0, 0);
		Goto Melee;
	Melee.TEX:
		"GKEX" A 0 { A_SetTranslucent(0.45); }
		"GKEX" FG 3 { A_FaceTarget(); }
		"GKEX" H 2 { A_CustomMeleeAttack(random(40, 99), "Obsidian/Melee", "none"); }
	Melee.TEX.GetBackHere:
		"GKEX" H 0 A_Jump(64, "Melee.TEX.GetBackHere.Chase");
		Goto See;
	Melee.TEX.GetBackHere.Chase:
		"GKEX" H 0 A_JumpIfCloser(200, "Missile");
		"GKEX" H 0 A_JumpIfCloser(500, "Missile.TEX.Charge");
		Goto Missile;
	Missile.TEX:
		SHDW A 0 A_Jump(200, "Missile.TEX.Standard", "Missile.TEX.Charge");
		Goto Missile.TEX.DarkBeam;
	Missile.TEX.Standard:
		"GKEX" A 6 { A_FaceTarget(); }
		"GKEX" F 4 { A_FaceTarget(); }
		"GKEX" GGGGGGGG 2 Bright { A_SpawnProjectile("RS_ShadowBallEX1", 32, 0, random(-30, 30)); }
		"GKEX" F 4 { A_FaceTarget(); }
		"GKEX" A 0 A_Jump(82, "Missile.TEX.BigOne");
		"GKEX" A 0 A_Jump(64, "Missile.TEX.Warp");
		Goto See;
	Missile.TEX.BigOne:
		"GKEX" A 6 { A_FaceTarget(); }
		"GKEX" F 4 { A_FaceTarget(); }
		"GKEX" G 8 Bright { A_SpawnProjectile("RS_ShadowSpiralEX", 32, 0, random(-30, 30)); }
		"GKEX" F 8 { A_FaceTarget(); }
		"GKEX" A 0 A_Jump(64, "Missile.TEX.Warp");
		Goto See;
	Missile.TEX.DarkBeam:
		"GKEX" A 6 { A_FaceTarget(); }
		"GKEX" F 4 { A_FaceTarget(); }
		"GKEX" GGGGGGGG 1 Bright { A_SpawnProjectile("RS_ShadowDarkBeamEX", 32); }
		"GKEX" G 0 { A_FaceTarget(); }
		"GKEX" GGGGGGGG 1 Bright { A_SpawnProjectile("RS_ShadowDarkBeamEX", 32); }
		"GKEX" G 0 { A_FaceTarget(); }
		"GKEX" GGGGGGGG 1 Bright { A_SpawnProjectile("RS_ShadowDarkBeamEX", 32); }
		"GKEX" G 0 { A_FaceTarget(); }
		"GKEX" GGGGGGGG 1 Bright { A_SpawnProjectile("RS_ShadowDarkBeamEX", 32); }
		"GKEX" F 8 { A_FaceTarget(); }
		"GKEX" A 0 A_Jump(64, "Missile.TEX.Warp");
		Goto See;
	Pain.TEX:
		"GKEX" H 4;
		"GKEX" H 4 { A_Pain(); }
		"GKEX" H 0 A_Jump(88, "Missile.TEX.Warp");
		Goto See;
	Death.TEX:
		"GKEX" NNNNNNNNNNNNNNNN 0 { A_SpawnItemEx("RS_ShadowDeathGhostEX", 0, 0, 4, frandom(-3, 3), frandom(-3, 3), 1, 0, SXF_NOCHECKPOSITION); }
		"GKEX" N 12;
		"GKEX" O 12 { A_Scream(); }
		"GKEX" P 13;
		"GKEX" Q 13 { A_Fall(); }
		"GKEX" RS 13;
		"GKEX" T -1;
		Stop;
	// CHP defines Raise as a bare Stop: the EX rogue cannot be resurrected.
	Raise.TEX:
		Stop;
	}
}
