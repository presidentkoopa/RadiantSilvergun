// =====================================================================
// RS_CG_B0001 -- The General (CH "BlackCGuy2")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:2280-2387
// ACTOR:   BlackCGuy2   (a BARE Actor in CH -- it does NOT inherit
//                        ChaingunGuy, so nothing is carried in from
//                        vanilla and every number below is stated by CH
//                        itself)
// ROLE:    B -- boss body. 4500 HP, +BOSS, three attack modes.
//
// THE NAME. "The General" is CH's own word, out of its obituary on line
// 2282 ("%o was vapourized by The General") and its Tag on line 2317.
// Nothing here is invented flavour -- if a name is not in CH it is not
// in this file.
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// EVERY PROPERTY CH SETS, so a differ can check the list:
//   Health 4500     Radius 20       Height 56       Mass 1000
//   Speed 10        PainChance 25
//   DamageFactor "Heroic", 3.0      DamageFactor "DIMp", 0
//   PainChance "DIMp", 0
//   MONSTER, +BOSS, +MISSILEMORE, +DONTHARMCLASS, +DONTMORPH,
//   -NORADIUSDMG, +FLOORCLIP, +NOFEAR
//   SeeSound    "gen/see"           PainSound   "gen/hurt"
//   DeathSound  "gen/huh"           ActiveSound "chainguy/active"
//   Obituary "%o was vapourized by The General"
//   Tag "ITS MR GENERAL TO YOU,MAGGOT"
//   DropItem CH_BFG9000 / CH_CellPack / CH_CellPack / CH_CellPack,128 /
//            CH_CellPack,128 / CH_Berserk / BackPack / BackPackBundle /
//            Chaingun / RareArmorPool,64 /
//            RLRoystensCommandArmorPickup,42 / RLBFG10KPickup,32 /
//            RLUniqueWeaponSpawner,12
// CH states NO Species, NO Translation and NO Game for this actor. The
// BFGZ sprite set is already the black body; there is nothing to tint.
// CH also ships NO XDeath and NO Raise for The General -- that is CH's
// choice, not a transcription gap. It gores into its normal Death and it
// does not get up.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH10 -- CH sprinkles this spawn into Idle/See/Missile/
//                         Pain as a floating tier marker. Not in our
//                         tree, and RS_HealthBars already shows tier over
//                         the monster's head.
//                         OFFSET CHECK: this actor has one `Goto <state>
//                         +N` -- ShieldBlast's `Goto Shield+6`. Shield
//                         contains NO icon line, so index 6 is the first
//                         TrailSPCguy shot before and after. The only
//                         icon that sits at index 0 of anything is
//                         Missile's, and nothing jumps to Missile+N.
//                         Checked line by line, not assumed.
//   * ACS_NamedExecuteAlways("AnnounceBlackCguy") on line 2324 -- CH's
//                         boss-arrival announcer script. No ACS by that
//                         name exists in this repo, and the repo's own
//                         convention (see RS_Chaingunner.zs header) is
//                         to strip ACS rather than leave a dangling
//                         call. The Spawn -> Scripted -> Idle shape is
//                         kept so the state layout still matches CH and
//                         the announcer can be dropped straight back in.
//   * Tickles / CHBoner / ThePlanBoner -- CH does not give The General
//                         this branch at all. Listed only so the absence
//                         is not read as a deletion.
//   * ELEVEN CH-ONLY DROPITEMS, none of which is a class in this tree.
//     Four of them are DoomRL Arsenal's, not CH's own. Itemised with
//     CH's own line so a differ can put them back the day the pickups
//     are ported:
//         DropItem "CH_BFG9000"                       :2293
//         DropItem "CH_CellPack"                      :2294
//         DropItem "CH_CellPack"                      :2295
//         DropItem "CH_CellPack", 128                 :2296
//         DropItem "CH_CellPack", 128                 :2297
//         DropItem "CH_Berserk"                       :2298
//         DropItem "BackPackBundle"                   :2300
//         DropItem "RareArmorPool", 64                :2302
//         DropItem "RLRoystensCommandArmorPickup", 42 :2303
//         DropItem "RLBFG10KPickup", 32               :2304
//         DropItem "RLUniqueWeaponSpawner", 12        :2305
//     CH's two vanilla drops (BackPack :2299, Chaingun :2301) are
//     carried live below.
//
// SOUNDS: "chainguy/active" is vanilla. "gen/see", "gen/hurt" and
// "gen/huh" are NOT in this repo's SNDINFO (checked 2026-08-05). They
// are carried verbatim anyway -- an unresolved sound name is inert, and
// deleting CH's value would lose the only record of what this boss is
// supposed to sound like. Three SNDINFO lines fix it.
//
// RETARGETED, NOT DROPPED:
//   * SpamShotsCguy -> RS_SpamShotsCguy   (RS_human_projectiles.zs:449)
//   * GenShield     -> RS_GenShield       (RS_human_projectiles.zs:192)
//   * TrailSPCguy   -> RS_TrailSPCguy     (RS_human_projectiles.zs:918)
//   * RedRevLoad    -> RS_RedRevLoad      (RS_hk_projectiles.zs:747)
//   * CGBigOne      -> RS_CGBigOne        (RS_human_projectiles.zs:158)
//   * HKRedDeath    -> RS_HKRedDeath      (RS_hk_projectiles.zs:357)
//
// MULTI-FRAME ACTIONS, DELIBERATE, DO NOT "FIX":
//   * Shield: `BFGZ FEFEFE 3 Bright A_CustomMissile("TrailSPCguy",...)`
//     is SIX frames, so SIX shots, one every 3 tics. That burst is the
//     payoff for the invulnerable wind-up and collapsing it to one shot
//     would gut the attack.
//   * Death: `BFGZ HHH 8 A_CustomMissile("HKRedDeath",...)` is THREE
//     frames, so three death-throe seekers.
//
// CH QUIRKS KEPT ON PURPOSE:
//   * Shield sets NOPAIN true and NOTHING in this actor ever sets it
//     false. After the first shield goes up The General is permanently
//     painless -- which also means Pain: can never route back into
//     Shield again, and every later shield has to come from Missile's
//     own SHIELDBLAST roll. That is what CH ships. Left alone.
//   * Missile's `A_Jump(256, ...)` always takes one of the three labels,
//     so the fall-through into SpamShots is unreachable. Kept verbatim.
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

class RS_CG_B0001 : RS_MonsterMaster
{
	Default
	{
		Health 4500;
		Radius 20;
		Height 56;
		Mass 1000;
		Speed 10;
		PainChance 25;
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
		SeeSound "gen/see";
		PainSound "gen/hurt";
		DeathSound "gen/huh";
		ActiveSound "chainguy/active";
		Obituary "%o was vapourized by The General";
		Tag "ITS MR GENERAL TO YOU,MAGGOT";
		// CH's vanilla drops only -- the eleven CH-only pickups are
		// itemised in the header.
		DropItem "BackPack";
		DropItem "Chaingun";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	//
	// species stays "" ("leave alone") because CH states no Species on
	// BlackCGuy2. dmgMul stays 1.0: CH states no damage multiplier, the
	// field is data-only (RS_MonsterTierRow does not apply it), and any
	// other number would be invented rather than transcribed -- a boss
	// multiplier is a design decision, not a CH fact.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 25; r.dmgMul = 1.0;
		r.species = "";
		// REQUIRED. RS_ApplyTierProperties assigns these ABSOLUTELY, so
		// omitting the word strips the Default block's flags at spawn.
		// +FLOORCLIP and +MISSILEMORE are NOT in this word on purpose --
		// the tier system does not manage either, so they survive.
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
	// CH fires ACS_NamedExecuteAlways("AnnounceBlackCguy") here. The
	// script is not in this repo; the state is kept so the layout still
	// matches CH and the announcer drops straight back in.
	Scripted:
		BFGZ A 0;
		Goto Idle;
	Idle:
		BFGZ AB 10 A_Look;
		Loop;
	See:
		BFGZ AABB 3 A_Chase;
		BFGZ CCDD 3 A_Chase;
		Loop;
	Missile:
		BFGZ E 0 A_Jump(256, "SpamShots", "ShieldBlast", "BigOne");
	SpamShots:
		BFGZ E 14 A_FaceTarget;
		BFGZ FEF 5 Bright A_CustomMissile("RS_SpamShotsCguy", 26, 8, random(-7, 7));
		BFGZ E 0 A_CheckSight("See");
		BFGZ FEF 5 Bright A_CustomMissile("RS_SpamShotsCguy", 26, 8, random(-15, 15));
		BFGZ E 0 A_CheckSight("See");
		BFGZ FEF 5 Bright A_CustomMissile("RS_SpamShotsCguy", 26, 8, random(-20, 20));
		BFGZ E 8 A_CheckSight("See");
		BFGZ E 0 A_Jump(128, "SpamShots");
		Goto See;
	// Index 6 of this state is the first TrailSPCguy shot -- ShieldBlast
	// below jumps straight to it, skipping the shield itself.
	Shield:
		BFGZ E 8 A_FaceTarget;
		BFGZ E 0 A_ChangeFlag("NOPAIN", true);
		BFGZ E 0 A_SetReflectiveInvulnerable;
		BFGZ E 2 A_CustomMissile("RS_GenShield", 20, 0, random(-7, 7));
		BFGZ E 46;
		BFGZ E 1 A_FaceTarget;
		BFGZ FEFEFE 3 Bright A_CustomMissile("RS_TrailSPCguy", 32, 0, random(-7, 7));
		BFGZ E 1 A_UnSetReflectiveInvulnerable;
		BFGZ A 1 A_Jump(64, "SpamShots", "BigOne");
		Goto See;
	ShieldBlast:
		BFGZ E 6;
		Goto Shield+6;
	BigOne:
		BFGZ E 20 A_FaceTarget;
		BFGZ E 15 Bright A_FaceTarget;
		BFGZ F 5 Bright A_CustomMissile("RS_RedRevLoad", 32, 8, 0);
		BFGZ E 8 Bright A_FaceTarget;
		BFGZ F 5 Bright A_CustomMissile("RS_RedRevLoad", 32, 8, 0);
		BFGZ E 8 Bright A_FaceTarget;
		BFGZ F 8 Bright A_CustomMissile("RS_CGBigOne", 32, 8, 0);
		BFGZ E 2;
		Goto See;
	Pain:
		BFGZ G 3;
		BFGZ G 3 A_Pain;
		BFGZ G 3 A_Jump(128, "Shield");
		Goto See;
	Death:
		BFGZ HHH 8 A_CustomMissile("RS_HKRedDeath", random(20, 100), random(-30, 30), CMF_AIMOFFSET, 2, -10);
		BFGZ I 5 A_Scream;
		BFGZ J 5 A_NoBlocking;
		BFGZ KLM 5;
		BFGZ N -1;
		Stop;

	// TIER DISPATCH ALIASES -- LOAD-BEARING. RS_MonsterMaster resolves
	// every state via FindStateByString(prefix..".T00", EXACT), which a
	// plain `Missile:` label does not satisfy -- without these the
	// General never fires a shot. No Melee/XDeath/Raise alias: CH gives
	// BlackCGuy2 none, and a null MeleeState is what earns the engine's
	// `if (MeleeState == NULL) dist -= 128` range bonus.
	Spawn.T00:   Goto Spawn;
	See.T00:     Goto See;
	Missile.T00: Goto Missile;
	Pain.T00:    Goto Pain;
	Death.T00:   Goto Death;
	}
}
