// =====================================================================
// RS_CG_T0004 -- Purple Chaingunner (CH "PurpleCGuy")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:1348-1459
// ACTOR:   PurpleCGuy : ChaingunGuy
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
// (For the record: CHP gives this colour Health 146 and the UCHA sprite
// sheet; CH gives it 120 and translated CPOS. This file is CH's.)
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Game Doom                     :1350
//   Health 120                    :1351
//   Species "Cguy2"               :1352
//   BloodColor "purple"           :1353
//   DamageFactor "Exorcist", 3.0  :1354
//   DamageFactor "DIMp", 0        :1355
//   PainChance "DIMp", 0          :1356
//   Radius 20                     :1357
//   Height 56                     :1358
//   Mass 100                      :1359
//   Speed 8                       :1360
//   PainChance 150                :1361
//   MONSTER                       :1362
//   +FLOORCLIP                    :1363
//   +AVOIDMELEE                   :1364
//   +DONTHARMSPECIES              :1365
//   SeeSound    "cguy2/see"       :1366
//   PainSound   "form2/hurt"      :1367
//   DeathSound  "cguy2/die"       :1368
//   ActiveSound "form2/active"    :1369
//   AttackSound ""                :1370   -- CH deliberately silences it
//   Obituary                      :1371
//   DropItem x9                   :1372-1380  (see the omission list)
//   Translation (13 ranges)       :1381
//   Tag "Purple Chaingunner"      :1382
//
// SPECIES "Cguy2" -- its own group again, a third string after T00's
// "CGuy" and T02's "Cguy". With +DONTHARMSPECIES the purple captain will
// trade fire with both of them. zscript/monsters/RS_Chaingunner.zs:177-181
// reads it the same way. The one-letter-case web across this family is
// deliberate in CH; it is not normalised here.
//
// ATTACKSOUND "" IS NOT AN OVERSIGHT. CH explicitly blanks the inherited
// "chainguy/attack" because this captain fires micro-rockets, not
// bullets, and RS_Boomer1's own SeeSound ("weapons/rocklf") is the noise
// it should make. Carried as the empty string CH writes.
//
// SOUNDS NOT YET IN THIS REPO'S SNDINFO -- carried verbatim anyway.
// "cguy2/see" and "cguy2/die" have no entry in E:\RS_Main\SNDINFO. CH
// defines them at CH/SNDINFO.txt:1112 (CGUY2/See = D64FORME) and :1117
// (CGuy2/Die = D64FORD3), and neither lump is in sounds/. Until those two
// lines exist this captain's sight and death cries are silent -- an
// undefined sound name is a no-op, not an error. "form2/hurt" and
// "form2/active" ARE defined (SNDINFO:640, :671) and work today.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH4 (:1387, :1391, :1393, :1397, :1432) -- CH sprinkles
//                       this spawn into Spawn/See/Missile/Pain as a
//                       floating tier marker. Not in our tree, and
//                       RS_HealthBars already shows tier over the
//                       monster's head. See the STATE-INDEX note below --
//                       dropping it does NOT move `Goto Missile+1`.
//   * Tickles (:1435-1437) / ThePlanBoner / CHBoner -- a joke death branch
//                       keyed to a CH-only inventory token that nothing
//                       here grants, so the branch is unreachable by
//                       construction. The Death: guard at :1439 goes with
//                       it.
//   * CHRandom_GibGenerator (:1447) + the A_SpawnParticle("Purple")
//                       confetti (:1452) in XDeath -- the gib actor is
//                       CH-only and absent from our tree. The particle
//                       calls are engine intrinsics and WOULD work; they
//                       are dropped only to stay identical to
//                       RS_Chaingunner_C0001_Common.zs, which drops the
//                       pair together.
//   * SplashAbyss burst in Pain.AbyssPE (:1420-1421, 45 spawns each) --
//                       omitted to match C0001's Pain.AbyssPE exactly.
//                       NOTE: RS_SplashAbyss DOES exist in our tree
//                       (zscript/monsters/monsterfx/RS_imp_projectiles.zs
//                       :203), so this one is restorable today -- but it
//                       must go back into every captain at once or the
//                       abyss conversion will look different depending on
//                       who is being converted.
//   * DropItem "CH_RocketAmmo" (:1373), "CH_RocketBox",64 (:1374),
//     "implyingclip" (:1375), "CH_ClipBox",64 (:1376), "HealthBundle"
//     (:1378) and "CH_GreenArmor",24 (:1380) -- none of these pickup
//                       classes exist anywhere in this repo (checked
//                       *.zs/*.zsc/*.txt; there is no DECORATE lump).
//                       CH's three vanilla drops -- Chaingun (:1372),
//                       HealthBonus,128 (:1377) and ArmorBonus,128
//                       (:1379) -- are carried. Restore the rest verbatim
//                       the day the CH pickups are imported.
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * Boomer1 -> RS_Boomer1, Boomer2 -> RS_Boomer2, Boomer3 -> RS_Boomer3
//                       (all three at RS_human_projectiles.zs:735-756)
//   * AbyssCGuy2 -> RS_CG_T0008 (CH's Pain.AbyssPE target, :1422 -- name
//                       follows RS_Chaingunner_C0001_Common.zs:132.
//                       FLAGGED: the older single-class ladder in
//                       zscript/monsters/RS_Chaingunner.zs:190 puts
//                       AbyssCGuy2 at tier SIX, and RS_MonsterMaster's own
//                       generic conversion calls SetTier(6). T0008 here is
//                       consistency with the pattern file, not a second
//                       opinion.)
//   * A_CustomMissile is kept (NOT rewritten to A_SpawnProjectile). The
//     two are not quite the same call: A_CustomMissile forwards
//     flags|CMF_BADPITCH. Here no pitch argument is passed so it makes no
//     difference, but keeping CH's spelling costs nothing and removes the
//     question. RS_Chaingunner_T0009_Fireblu.zs:149 does the same.
//
// NO GROW LADDER, AND THAT IS CH'S. CommonCGuy, GreenCGuy and BlueCGuy
// all check GrowRaisin in Raise and promote one colour. PurpleCGuy does
// NOT -- its Raise (:1455-1457) is a plain reverse-death. The CH chain
// therefore ends here: Common -> Green -> Blue -> Purple -> (nothing).
// Do not "complete" it by pointing this at T0005; that promotion does not
// exist in CH.
//
// STATE-INDEX NOTE -- checked, not assumed. Missile, M2 and M1 all end
// `Goto Missile+1`. In CH index 1 is the dropped 0-tic ColorTierIconCH4
// spawn, which falls straight through to index 2, the
// A_JumpIfCloser(650,"M1") range test. With the icon gone, index 1 IS
// that range test. The offset lands on the same state either way, so the
// refire loop still RE-EVALUATES the range band on every pass (it must:
// that is how the purple captain picks Boomer1/2/3) and `Goto Missile+1`
// is carried verbatim.
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor;
// the damage lives in the boomers themselves (RS_Boomer1 already carries
// its A_Explode(random(1,8),46) roll). What this actor rolls is AIM --
// the six random(-1,1) angle jitters at :1400, :1401, :1405, :1406,
// :1410, :1411 -- and all six are carried verbatim. Nothing was
// flattened to a constant. Note also that `CPOS FE 5` is TWO frames, so
// each of those lines fires TWICE: the default band puts FOUR Boomer3 in
// the air per pass, not two. That is CH's own doubling and is preserved.
//
// DIVERGENCE FROM C0001, DELIBERATE AND FLAGGED:
//   * TierData sets r.flags. It has to.
//     RS_MonsterMaster.RS_ApplyTierProperties ASSIGNS the flag set
//     absolutely (RS_MonsterMaster.zs:712-776) -- with r.flags left 0 it
//     runs `bAVOIDMELEE = false; bDONTHARMSPECIES = false` at
//     PostBeginPlay and the Default block's flags are silently gone.
//   * The Spawn.T00/See.T00/... alias block at the end of States. See
//     the comment there -- without it MissileState is nulled and this
//     captain never fires a shot.
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

//
// STATE DISPATCH: SIMPLIFIED 2026-08-05. Any note below describing a
// "Spawn.T00/See.T00/... alias block" is STALE -- those aliases are
// GONE from this file, 56 lines of them across the family.
// RS_MonsterMaster.TierState now falls back to the PLAIN label, which
// is what this file writes and what any ordinary actor writes. The
// ".T00" requirement belonged to the CHP-era ladder, which now lives
// in RS_MonsterLadder and is not in this class hierarchy at all.
// That requirement is why five files in this family could not fire a
// shot: an exact lookup does not match a plain Missile: label, so
// MissileState came back null. It cannot happen again.
// =====================================================================

class RS_CG_T0004 : RS_Chaingunner
{
	Default
	{
		// CH states `Game Doom`; ZScript has no Game actor property (DECORATE
		// only), so it is recorded here rather than declared. Not a loss --
		// this mod is Doom-only.
		Health 120;
		Species "Cguy2";       // CH's third species string in this family
		BloodColor "purple";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 150;
		Monster;
		+FLOORCLIP
		+AVOIDMELEE
		+DONTHARMSPECIES
		// cguy2/* have no SNDINFO entry in this repo yet -- see header.
		SeeSound "cguy2/see";
		PainSound "form2/hurt";
		DeathSound "cguy2/die";
		ActiveSound "form2/active";
		AttackSound "";        // CH blanks it deliberately -- see header
		Obituary "%o , purple and black was the pile left of them";
		// CH's vanilla drops only -- the six CH-only pickups are itemised
		// in the header.
		DropItem "Chaingun";
		DropItem "HealthBonus", 128;
		DropItem "ArmorBonus", 128;
		Translation "48:63=[233,163,248]:[180,24,156]", "169:191=0:0",
		            "64:79=[226,69,239]:[41,12,13]",
		            "128:143=[238,133,250]:[117,23,56]",
		            "144:151=[175,16,216]:[125,26,28]",
		            "152:159=[176,27,214]:[100,19,21]", "160:167=0:2",
		            "215:223=106:111", "117:125=0:2", "21:21=27:31",
		            "32:47=240:247", "31:31=203:203",
		            "9:12=[194,53,230]:[68,13,14]";
		Tag "Purple Chaingunner";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 150; r.dmgMul = 1.0;
		r.species = "Cguy2";
		r.bloodColor = "purple";
		// Assigned absolutely by the base class -- see the header.
		r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		CPOS AB 10 A_Look;
		Loop;
	See:
		CPOS AABB 3 A_Chase;
		CPOS CCDD 3 A_Chase;
		Loop;
	// Three range bands, one boomer grade each. Inside 650 the
	// hardest-seeking Boomer1 (M1), 650-1300 the Boomer2 (M2), beyond
	// 1300 the dumb-fired Boomer3. All three return to Missile+1 so the
	// band is re-tested every pass.
	Missile:
		CPOS E 12 A_FaceTarget;
		TNT1 A 0 A_JumpIfCloser(650, "M1");
		TNT1 A 0 A_JumpIfCloser(1300, "M2");
		CPOS FE 5 Bright A_CustomMissile("RS_Boomer3", 32, -2, random(-1,1));
		CPOS FE 5 Bright A_CustomMissile("RS_Boomer3", 32, -2, random(-1,1));
		CPOS F 1 A_MonsterRefire(150, "See");
		Goto Missile+1;
	M2:
		CPOS FE 4 Bright A_CustomMissile("RS_Boomer2", 32, -2, random(-1,1));
		CPOS FE 5 Bright A_CustomMissile("RS_Boomer2", 32, -2, random(-1,1));
		CPOS F 1 A_MonsterRefire(150, "See");
		Goto Missile+1;
	M1:
		CPOS FE 4 Bright A_CustomMissile("RS_Boomer1", 32, -2, random(-1,1));
		CPOS FE 4 Bright A_CustomMissile("RS_Boomer1", 32, -2, random(-1,1));
		CPOS F 1 A_MonsterRefire(150, "See");
		Goto Missile+1;
	Pain:
		CPOS G 3;
		CPOS G 3 A_Pain;
		Goto See;
	Death:
		CPOS H 5;
		CPOS I 5 A_Scream;
		CPOS J 5 A_NoBlocking;
		CPOS KLM 5;
		CPOS N -1;
		Stop;
	// CH switches the gib frames to the purple-tinted CGUP sheet rather
	// than translating CPOS -- gore does not remap cleanly. CGUP O..T
	// ship in sprites/monsters/_src/ (the only place they exist in this
	// repo; the Chaingunner/T04 folder holds CHP's UCHA sheet instead).
	// Chaingunners.txt:1446.
	XDeath:
		CGUP O 5;
		CGUP P 5 A_XScream;
		CGUP Q 5 A_NoBlocking;
		CGUP RS 5;
		CGUP T -1;
		Stop;
	// No GrowRaisin check and no Grow branch -- CH ends its own promotion
	// ladder here. See the header. Chaingunners.txt:1455.
	Raise:
		CPOS NMLKJIH 5;
		Goto See;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:1414.
	Pain.AbyssPE:
		TNT1 A 0 A_ChangeFlag("NOPAIN", true);
		TNT1 A 0 A_SetScale(0.8, 0.8);
		AYPB AAB 5 Bright;
		AYPB B 5 Bright A_PlaySound("AbyssForm", 0);
		AYPB BBACDE 5 Bright;
		TNT1 A 0 A_SpawnItemEx("RS_CG_T0008", 0, 0, 0, 0, 0, 0, 0,
		                       SXF_NOCHECKPOSITION | SXF_TRANSFERSPECIAL |
		                       SXF_TRANSFERAMBUSHFLAG);
		AYPB FGH 3 Bright;
		AYPB I 5 Bright A_SetScale(1, 0.75);
		AYPB H 5 Bright A_SetScale(1, 0.5);
		AYPB I 5 Bright A_SetScale(1, 0.25);
		AYPB H 5 Bright A_SetScale(1, 0.05);
		TNT1 A 0 A_Die;
		Stop;

	// TIER-CLUSTER ALIASES -- NOT COSMETIC, AND NOT IN CH.
	// RS_MonsterMaster.ApplyTier does `MissileState = TierState("Missile")`
	// (RS_MonsterMaster.zs:640-641), and TierState looks up
	// "Missile.<tier>" then "Missile.T00" with exact=true
	// (RS_MonsterMaster.zs:1015-1020). A plain `Missile:` label does NOT
	// satisfy that, so MissileState would be assigned NULL at
	// PostBeginPlay and this captain would never fire. The same lookup
	// drives the post-retier pendingStateJump into "Spawn.T00"/"See.T00".
	// A label whose whole body is a Goto resolves at compile time, so
	// these are true aliases and cost nothing at runtime.
	}
}
