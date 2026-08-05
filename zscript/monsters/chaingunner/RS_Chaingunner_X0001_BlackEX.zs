// =====================================================================
// RS_CG_X0001 -- Black ChainGunner EX (CH "BlackCGuyEX")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:1909-2048
// ACTOR:   BlackCGuyEX   (a BARE Actor in CH -- it does NOT inherit
//                         ChaingunGuy, so nothing is carried in from
//                         vanilla and every number below is stated by CH
//                         itself)
// ROLE:    X -- the EX rung. 8999 HP, four heavy attacks, a permanent
//               phase 2, and pain-lock immunity between attacks.
//
// THE NAME. "Black ChainGunner EX" is CH's own word, out of its obituary
// on line 1911; the Tag is "LET ME SEE YOUR WARFACE" (line 1947).
// Nothing here is invented flavour -- if a name is not in CH it is not
// in this file.
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// EVERY PROPERTY CH SETS, so a differ can check the list:
//   Health 8999     Radius 20       Height 56       Mass 1000
//   Speed 20        PainChance 12
//   DamageFactor "Heroic", 3.0      DamageFactor "DIMp", 0
//   PainChance "DIMp", 0
//   MONSTER, +BOSS, +MISSILEMORE, +DONTHARMCLASS, +DONTMORPH,
//   -NORADIUSDMG, +FLOORCLIP, +NOFEAR
//   SeeSound    "genEx/see"         PainSound   "genEx/pain"
//   DeathSound  "GRALDEAD"          ActiveSound "chainguy/active"
//   Obituary "%o was made to peel potatoes for eternity by
//             Black ChainGunner EX"
//   Tag "LET ME SEE YOUR WARFACE"
//   Translation (4 ranges, line 1948) -- carried verbatim. This one is
//   load-bearing: HCPO is not a black sprite set, the desaturate-to-
//   black translation is what makes this creature look like the EX.
//   DropItem CH_BFG9000 / CH_CellPack / CH_CellPack / CH_CellPack,128 /
//            CH_CellPack,128 / CH_Berserk / BackPack / Chaingun /
//            BackPack / BackPackBundle / RareArmorPool,64 /
//            RLRoystensCommandArmorPickup,42 / RLBFG10KPickup,32 /
//            RLUniqueWeaponSpawner,24
//   (BackPack really is listed twice in CH, lines 1928 and 1930. Both
//   are kept -- that is a drop-rate decision, not a typo to tidy.)
// CH states NO Species and NO Game for this actor, and ships NO XDeath
// and NO Raise. That is CH's choice, not a transcription gap.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH10 -- CH sprinkles this spawn into Idle/See/See2/
//                         Missile/Pain as a floating tier marker. Not in
//                         our tree, and RS_HealthBars already shows tier
//                         over the monster's head.
//
//                         >>> READ THIS BEFORE TOUCHING Missile: <<<
//                         In Missile the icon spawn is at INDEX 0, and
//                         Phase2 ends with `Goto Missile+2`. Deleting
//                         the line outright would slide +2 off the
//                         attack roll and onto the first line of
//                         YellowBomb -- i.e. the boss would stop rolling
//                         its four attacks the moment it dropped below
//                         5000 HP and would lob yellow bombs forever.
//                         That is exactly the offset bug this project
//                         has now hit three times, so the icon's slot is
//                         kept as an explicit 0-tic `TNT1 A 0;`
//                         placeholder and the offset is copied
//                         unchanged. The placeholder is load-bearing.
//                         Do not "clean it up".
//
//                         Every other icon line in this actor sits in a
//                         state nothing jumps into by offset (Idle, See,
//                         See2, Pain), so those are simply dropped.
//                         RapidFire's `Goto Rapidfire+1` is unaffected:
//                         RapidFire contains no icon line at all, so
//                         index 1 is the prox/beep before and after.
//                         Counted line by line, not assumed.
//   * ACS_NamedExecuteAlways("AnnounceBlackCguy") on line 1956 -- CH's
//                         boss-arrival announcer script. No ACS by that
//                         name exists in this repo, and the repo's own
//                         convention (see RS_Chaingunner.zs header) is
//                         to strip ACS rather than leave a dangling
//                         call. A_Log on the NEXT line is NOT ACS and is
//                         kept -- "A chill runs down your spine" is the
//                         only arrival tell left.
//   * Tickles / CHBoner / ThePlanBoner -- CH does not give the EX this
//                         branch at all. Listed only so the absence is
//                         not read as a deletion.
//   * ELEVEN CH-ONLY DROPITEMS, none of which is a class in this tree.
//     Four of them are DoomRL Arsenal's, not CH's own. Itemised with
//     CH's own line so a differ can put them back the day the pickups
//     are ported:
//         DropItem "CH_BFG9000"                       :1922
//         DropItem "CH_CellPack"                      :1923
//         DropItem "CH_CellPack"                      :1924
//         DropItem "CH_CellPack", 128                 :1925
//         DropItem "CH_CellPack", 128                 :1926
//         DropItem "CH_Berserk"                       :1927
//         DropItem "BackPackBundle"                   :1931
//         DropItem "RareArmorPool", 64                :1932
//         DropItem "RLRoystensCommandArmorPickup", 42 :1933
//         DropItem "RLBFG10KPickup", 32               :1934
//         DropItem "RLUniqueWeaponSpawner", 24        :1935
//     CH's three vanilla drops (BackPack :1928, Chaingun :1929,
//     BackPack :1930) are carried live below -- both BackPacks.
//
// SOUNDS: "chainguy/active" is vanilla and "prox/beep" IS in this repo's
// SNDINFO. "genEx/see", "genEx/pain" and "GRALDEAD" are NOT (checked
// 2026-08-05). They are carried verbatim anyway -- an unresolved sound
// name is inert, and deleting CH's value would lose the only record of
// what this boss is supposed to sound like. Three SNDINFO lines fix it.
//
// RETARGETED, NOT DROPPED:
//   * SparkPuff1        -> RS_SparkPuff1        (RS_hk_projectiles.zs:378)
//   * YellowBombCguyEX  -> RS_YellowBombCGuyEX  (RS_human_projectiles.zs:1437)
//   * RedRevLoad        -> RS_RedRevLoad        (RS_hk_projectiles.zs:747)
//   * SpiralLoadGeneEX  -> RS_SpiralLoadGeneEX  (RS_human_projectiles.zs:1614)
//   * CGBigEX           -> RS_CGBigEX           (RS_human_projectiles.zs:1571)
//   * DetoPuffCG        -> RS_DetoPuffCG        (RS_human_projectiles.zs:405)
//   * SpamShotsCguyEX   -> RS_SpamShotsCGuyEX   (RS_human_projectiles.zs:1485)
//   * SpamShotsCguyEX2  -> RS_SpamShotsCGuyEX2  (RS_human_projectiles.zs:1513)
//   * HKRedDeath        -> RS_HKRedDeath        (RS_hk_projectiles.zs:357)
//
// TRANSLATED, NOT REWRITTEN:
//   * CH's `A_Quake(2,12,0,128,None)` becomes `A_Quake(2, 12, 0, 128,
//     "")`. `None` is DECORATE's way of saying "no quake sound";
//     ZScript's sound parameter spells the same thing "". Same four
//     numbers, same silence.
//   * CH writes A_ChangeFlag's flag name unquoted (MISSILEEVENMORE,
//     ALWAYSFAST, NOPAIN). ZScript's A_ChangeFlag takes a string, so
//     they are quoted here. Same flags, same order.
//
// MULTI-FRAME ACTIONS, DELIBERATE, DO NOT "FIX". CH stacks frames on a
// single action line specifically to fire it N times:
//   * YE       `TNT1 AA 0       A_CustomMissile("SparkPuff1",...)`   = 2
//   * YE       `HCPO EEEEEEE 1  A_CustomMissile("SparkPuff1",...)`   = 7
//   * RapidFire`HCPO FE 4       A_CustomBulletAttack(...)`           = 2
//   * RedSpam  `HCPO FEFE 3     A_CustomMissile("SpamShotsCguyEX"..)`= 4
//   * RedSpam  `HCPO FEFE 3     A_CustomMissile("...EX2",...)`       = 4
//   * RedSpam  `HCPO FE 3       A_CustomMissile(...)` x2             = 2 each
//   * Death    `HCPO HHHHHHH 5  A_CustomMissile("HKRedDeath",...)`   = 7
// The nine-frame SparkPuff halo in YE is the wind-up tell for the
// yellow bomb; collapsing it to one call removes the warning as well as
// the effect.
//
// CH QUIRKS KEPT ON PURPOSE:
//   * PAIN-LOCK IMMUNITY IS A REAL MECHANIC HERE, and it is the reason
//     this boss reads as heavy. Pain: ends by setting NOPAIN TRUE, and
//     each of the four attacks sets NOPAIN FALSE on the tic immediately
//     before its damaging frame. So the EX can be staggered once, then
//     shrugs everything off until it commits to its next attack. Do not
//     "simplify" either half -- they only work as a pair.
//   * `A_CustomMissile("SparkPuff1",40,0,CMF_AIMOFFSET,random(0,360),
//     random(0,360))` passes CMF_AIMOFFSET in the ANGLE slot (so angle =
//     4 degrees) and a random 0..360 in the FLAGS slot. Read
//     positionally that is almost certainly not what CH meant, but it is
//     what CH ships and what CH plays like -- DECORATE has the identical
//     parameter order, so this is not a porting artefact. Transcribed
//     verbatim. The same shape appears on the HKRedDeath death throes,
//     where the repo's own projectile files already carry it.
//   * `A_Jump(255, ...)` in Missile is 255, not 256, so roughly one roll
//     in 256 falls through into YellowBomb instead of jumping. Kept.
//
//
// SOUNDS: RESOLVED 2026-08-05. Any note below saying a sound name is
// NOT in this repo SNDINFO is STALE. CH sound library was imported
// that day -- 693 lumps into sounds/ch/ and 804 SNDINFO definitions,
// including the $random directives. Every sound name this file uses
// now resolves end to end to a real lump. Verified, not assumed.
// TIER ICONS: RESTORED 2026-08-05, and NOT from this file.
// CH pastes an A_SpawnItemEx("ColorTierIconCH<n>") line into Spawn,
// See, Missile and Pain of every actor. Those lines are 0-tic, and
// `Goto X+N` offsets COUNT FRAMES -- so adding or removing one silently
// retargets every jump after it in that state. That hazard already cost
// two placeholder frames in this family.
// RS_MonsterMaster emits the icon on a timer instead (RS_EmitTierIcon).
// Identical on screen, cannot shift an offset, and every one of the
// seventeen families gets it rather than just the ones edited by hand.
// Gated on rs_mon_tiericons, off by default exactly as CH ships it.
// Anything below claiming the icons were dropped is superseded by this.

// =====================================================================

class RS_CG_X0001 : RS_MonsterMaster
{
	Default
	{
		Health 8999;
		Radius 20;
		Height 56;
		Mass 1000;
		Speed 20;
		PainChance 12;
		DamageFactor "Heroic", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Monster;
		+BOSS
		+MISSILEMORE
		+DONTHARMCLASS
		+DONTMORPH
		-NORADIUSDMG
		+FLOORCLIP
		+NOFEAR
		SeeSound "genEx/see";
		PainSound "genEx/pain";
		DeathSound "GRALDEAD";
		ActiveSound "chainguy/active";
		Obituary "%o was made to peel potatoes for eternity by Black ChainGunner EX";
		Tag "LET ME SEE YOUR WARFACE";
		Translation "192:247=%[0.00,0.00,0.00]:[2.00,2.00,2.00]",
		            "32:47=%[0.00,0.00,0.00]:[2.00,2.00,2.00]",
		            "168:191=%[0.00,0.00,0.00]:[2.00,2.00,2.00]",
		            "16:31=%[0.00,0.00,0.00]:[2.00,2.00,2.00]";
		// CH's vanilla drops only -- the eleven CH-only pickups are
		// itemised in the header. BackPack twice is CH's own, kept.
		DropItem "BackPack";
		DropItem "Chaingun";
		DropItem "BackPack";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	//
	// species stays "" ("leave alone") because CH states no Species on
	// BlackCGuyEX. dmgMul stays 1.0: CH states no damage multiplier, the
	// field is data-only (RS_MonsterTierRow does not apply it), and any
	// other number would be invented rather than transcribed -- an EX
	// multiplier is a design decision, not a CH fact.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 12; r.dmgMul = 1.0;
		r.species = "";
		// REQUIRED -- see RS_Chaingunner_C0001_Common.zs. Assigned
		// absolutely; omitting it strips Default's flags at spawn.
		r.flags = RS_TF_BOSS | RS_TF_DONTHARMCLASS
		        | RS_TF_DONTMORPH | RS_TF_NOFEAR;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		BFGZ A 0;
		Goto Scripted;
	// CH fires ACS_NamedExecuteAlways("AnnounceBlackCguy") on the first
	// line here. The script is not in this repo; the A_Log below is CH's
	// own and stays.
	Scripted:
		BFGZ A 0;
		BFGZ A 0 A_Log("A chill runs down your spine");
		Goto Idle;
	Idle:
		HCPO AB 10 A_Look;
		Loop;
	See:
		HCPO AABB 3 A_Chase;
		HCPO CCDD 3 A_Chase;
		Loop;
	See2:
		HCPO AABB 3 A_FastChase;
		HCPO CCDD 3 A_FastChase;
		Goto See;
	// INDEX 0 BELOW IS A LOAD-BEARING PLACEHOLDER. Phase2's
	// `Goto Missile+2` has to land on the A_Jump attack roll; see the
	// header. Removing this 0-tic line breaks the boss silently.
	Missile:
		TNT1 A 0;   // CH: ColorTierIconCH10 spawn -- icon dropped, slot kept
		TNT1 A 0 A_JumpIfHealthLower(5000, "Phase2");
		TNT1 A 0 A_Jump(255, "RedSpam", "YellowBomb", "BigBomb", "RapidFire");
	YellowBomb:
		TNT1 A 0 A_JumpIfCloser(1200, "YE");
		Goto Missile;
	// Permanent, not a beat: once below 5000 HP both flags stay on for
	// the rest of the fight.
	Phase2:
		TNT1 A 0 A_ChangeFlag("MISSILEEVENMORE", true);
		TNT1 A 0 A_ChangeFlag("ALWAYSFAST", true);
		Goto Missile+2;
	YE:
		HCPO E 1 A_FaceTarget;
		TNT1 AA 0 A_CustomMissile("RS_SparkPuff1", 40, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360));
		HCPO E 3 Bright A_FaceTarget;
		HCPO EEEEEEE 1 Bright A_CustomMissile("RS_SparkPuff1", 40, 0, CMF_AIMOFFSET, random(0, 360), random(0, 360));
		HCPO E 2 Bright A_FaceTarget;
		HCPO F 0 A_Quake(2, 12, 0, 128, "");
		TNT1 A 0 A_ChangeFlag("NOPAIN", false);
		HCPO F 3 Bright A_CustomMissile("RS_YellowBombCGuyEX", 40, 0, 0);
		HCPO E 9 Bright;
		Goto See;
	BigBomb:
		HCPO E 1 A_FaceTarget;
		HCPO F 0 A_CustomMissile("RS_RedRevLoad", 40, 0, 0);
		HCPO E 20 Fast A_FaceTarget;
		HCPO F 0 A_CustomMissile("RS_SpiralLoadGeneEX", 40, 0, 0);
		HCPO E 20 Fast A_FaceTarget;
		HCPO F 0 A_Quake(2, 12, 0, 128, "");
		TNT1 A 0 A_ChangeFlag("NOPAIN", false);
		HCPO F 3 Bright A_CustomMissile("RS_CGBigEX", 40, 0, 0);
		HCPO E 9 Bright;
		Goto See;
	// Index 1 is the prox/beep -- the refire below replays the tell every
	// burst, which is why `Goto Rapidfire+1` is +1 and not +0 or +5.
	RapidFire:
		HCPO E 20 Fast A_FaceTarget;
		TNT1 A 0 A_PlaySound("prox/beep");
		HCPO E 4 A_FaceTarget;
		HCPO F 0 A_Quake(2, 12, 0, 128, "");
		TNT1 A 0 A_ChangeFlag("NOPAIN", false);
		HCPO FE 4 Bright A_CustomBulletAttack(6, 5, random(1, 3), random(1, 4), "RS_DetoPuffCG");
		HCPO E 2 A_MonsterRefire(188, "See");
		Goto RapidFire+1;
	RedSpam:
		HCPO E 1 A_FaceTarget;
		HCPO F 0 A_CustomMissile("RS_SpiralLoadGeneEX", 40, 0, 0);
		HCPO E 15 Fast A_FaceTarget;
		HCPO F 0 A_CustomMissile("RS_SpiralLoadGeneEX", 40, 0, 0);
		HCPO E 15 Fast A_FaceTarget;
		HCPO F 0 A_Quake(2, 12, 0, 128, "");
		TNT1 A 0 A_ChangeFlag("NOPAIN", false);
		HCPO FEFE 3 Bright A_CustomMissile("RS_SpamShotsCGuyEX", 40, 0, random(-5, 5), 0, random(-4, 4));
		HCPO E 1 A_FaceTarget;
		HCPO FEFE 3 Bright A_CustomMissile("RS_SpamShotsCGuyEX2", 40, 0, random(-9, 9), 0, random(-4, 4));
		HCPO E 1 A_FaceTarget;
		HCPO FE 3 Bright A_CustomMissile("RS_SpamShotsCGuyEX", 40, 0, random(-11, 11), 0, random(-4, 4));
		HCPO E 1 A_FaceTarget;
		HCPO FE 3 Bright A_CustomMissile("RS_SpamShotsCGuyEX2", 40, 0, random(-13, 13), 0, random(-4, 4));
		Goto See;
	// The NOPAIN latch goes UP here and comes back down inside each
	// attack. See the header -- the pair is the mechanic.
	Pain:
		HCPO G 3;
		HCPO G 3 A_Pain;
		TNT1 A 0 A_ChangeFlag("NOPAIN", true);
		HCPO G 3 A_Jump(128, "See2");
		Goto See;
	Death:
		HCPO HHHHHHH 5 A_CustomMissile("RS_HKRedDeath", random(20, 100), random(-30, 30), CMF_AIMOFFSET, 2, -10);
		HCPO I 5 A_Scream;
		HCPO J 5 A_NoBlocking;
		HCPO KL 5;
		HCPO L -1;
		Stop;

	// TIER DISPATCH ALIASES -- LOAD-BEARING, see C0001. Without these
	// MissileState resolves null and the EX boss never attacks.
	Spawn.T00:   Goto Spawn;
	See.T00:     Goto See;
	Missile.T00: Goto Missile;
	Pain.T00:    Goto Pain;
	Death.T00:   Goto Death;
	}
}
