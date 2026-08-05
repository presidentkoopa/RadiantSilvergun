// =====================================================================
// RS_CG_T0002 -- Blue Chaingunner (CH "BlueCGuy")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:1178-1298
// ACTOR:   BlueCGuy : ChaingunGuy
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
// (For the record: CHP gives this colour Health 111, CH gives it 105.)
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Game Doom                     :1180
//   Health 105                    :1181
//   Species "Cguy"                :1182
//   BloodColor "blue"             :1183
//   DamageFactor "Exorcist", 3.0  :1184
//   DamageFactor "DIMp", 0        :1185
//   PainChance "DIMp", 0          :1186
//   Radius 20                     :1187
//   Height 56                     :1188
//   Mass 100                      :1189
//   Speed 8                       :1190
//   PainChance 150                :1191
//   MONSTER                       :1192
//   +FLOORCLIP                    :1193
//   +AVOIDMELEE                   :1194
//   +DONTHARMSPECIES              :1195
//   SeeSound    "cguy2/see"       :1196
//   PainSound   "form2/hurt"      :1197
//   DeathSound  "cguy2/die"       :1198
//   ActiveSound "form2/active"    :1199
//   AttackSound "chainguy/attack" :1200
//   Obituary                      :1201
//   DropItem x6                   :1202-1207  (see the omission list)
//   Translation (2 ranges)        :1208
//   Tag "Blue Chaingunner"        :1209
//
// SPECIES "Cguy" -- ONE LETTER'S CASE apart from T00's "CGuy", and it is
// carried as CH spells it rather than tidied. ZScript Names ARE case
// sensitive, so "Cguy" and "CGuy" are two different species and with
// +DONTHARMSPECIES the blue captain and the common captain WILL shoot
// each other. That is a deliberate infighting web in CH, not a typo, and
// zscript/monsters/RS_Chaingunner.zs:162-166 reads it the same way.
//
// SOUNDS NOT YET IN THIS REPO'S SNDINFO -- carried verbatim anyway.
// "cguy2/see" and "cguy2/die" have no entry in E:\RS_Main\SNDINFO. CH
// defines them at CH/SNDINFO.txt:1112 (CGUY2/See = D64FORME) and :1117
// (CGuy2/Die = D64FORD3), and neither lump is in sounds/. Until those two
// lines exist this captain's sight and death cries are silent -- an
// undefined sound name is a no-op, not an error. They are kept in the
// Default block rather than deleted so that (a) the value is not lost and
// (b) two SNDINFO lines fix it with no code change. "form2/hurt" and
// "form2/active" ARE defined (SNDINFO:640, :671) and work today.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH3 (:1214, :1218, :1220, :1224, :1265) -- CH sprinkles
//                       this spawn into Spawn/See/Missile/Pain as a
//                       floating tier marker. Not in our tree, and
//                       RS_HealthBars already shows tier over the
//                       monster's head. See the STATE-INDEX note below --
//                       dropping it does NOT move `Goto Missile+1`.
//   * Tickles (:1268-1270) / ThePlanBoner / CHBoner -- a joke death branch
//                       keyed to a CH-only inventory token that nothing
//                       here grants, so the branch is unreachable by
//                       construction. The Death: guard at :1272 goes with
//                       it.
//   * CHRandom_GibGenerator (:1280) + the A_SpawnParticle("Blue")
//                       confetti (:1285) in XDeath -- the gib actor is
//                       CH-only and absent from our tree. The particle
//                       calls are engine intrinsics and WOULD work; they
//                       are dropped only to stay identical to
//                       RS_Chaingunner_C0001_Common.zs, which drops the
//                       pair together.
//   * SplashAbyss burst in Pain.AbyssPE (:1253-1254, 45 spawns each) --
//                       omitted to match C0001's Pain.AbyssPE exactly.
//                       NOTE: RS_SplashAbyss DOES exist in our tree
//                       (zscript/monsters/monsterfx/RS_imp_projectiles.zs
//                       :203), so this one is restorable today -- but it
//                       must go back into every captain at once or the
//                       abyss conversion will look different depending on
//                       who is being converted.
//   * DropItem "implyingclip" (:1203), "implyingclip",128 (:1204),
//     "CH_ClipBox",32 (:1205) and "HealthBundle" (:1206) -- none of these
//                       pickup classes exist anywhere in this repo
//                       (checked *.zs/*.zsc/*.txt; there is no DECORATE
//                       lump). CH's two vanilla drops, Chaingun (:1202)
//                       and ArmorBonus,128 (:1207), are carried. Restore
//                       the rest verbatim the day the CH pickups are
//                       imported.
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * BlueChainPuff2 -> RS_BlueChainPuff2 (RS_human_projectiles.zs:725)
//   * BlueChainPuff3 -> RS_BlueChainPuff3 (RS_human_projectiles.zs:147.
//                       HEADS UP: our copy was built from CHP, not CH --
//                       Radius 4 / +NOGRAVITY / Scale 0.6 / no seesound,
//                       against CH's Radius 12 / Height 12 / Alpha 0.73 /
//                       Scale 0.55 / Seesound "prox/beep" at
//                       Chaingunners.txt:1323. Not my file to change;
//                       flagged so the difference is on the record.)
//   * PurpleCGuy     -> RS_CG_T0004       (CH's Grow target, :1294)
//   * AbyssCGuy2     -> RS_CG_T0008       (CH's Pain.AbyssPE target,
//                       :1255 -- name follows
//                       RS_Chaingunner_C0001_Common.zs:132. FLAGGED: the
//                       older single-class ladder in
//                       zscript/monsters/RS_Chaingunner.zs:190 puts
//                       AbyssCGuy2 at tier SIX, and RS_MonsterMaster's own
//                       generic conversion calls SetTier(6). T0008 here is
//                       consistency with the pattern file, not a second
//                       opinion.)
//   * GrowRaisin     -> RS_CG_GrowRaisin  (defined in C0001)
//   * A_CustomRailgun colours: CH writes "none" and "Blue" (:1228, :1235).
//     Carried as "" and "00 00 FF" -- the exact forms
//     RS_Chaingunner.zs:703-704 and RS_Chaingunner_T0005_Yellow.zs:179
//     use, so the family agrees with itself.
//   * A_CustomMissile is kept (NOT rewritten to A_SpawnProjectile). The
//     two are not quite the same call: A_CustomMissile forwards
//     flags|CMF_BADPITCH. Here the pitch argument is 0 so it makes no
//     difference, but keeping CH's spelling costs nothing and removes the
//     question. RS_Chaingunner_T0009_Fireblu.zs:149 does the same.
//
// STATE-INDEX NOTE -- checked, not assumed. Missile, M1 and Closer all
// end `Goto Missile+1`. In CH index 1 is the dropped 0-tic
// ColorTierIconCH3 spawn, which falls straight through to index 2, the
// A_JumpIfCloser(600,"Closer") range test. With the icon gone, index 1 IS
// that range test. The offset lands on the same state either way, so the
// refire loop still RE-EVALUATES the range band on every pass (it must:
// that is how the blue captain switches between rail, mid-rail and the
// point-blank burst) and `Goto Missile+1` is carried verbatim.
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor;
// its rolls live in the action calls -- A_CustomRailgun's random(1,2)
// (:1228) and random(1,3) (:1235), and A_CustomBulletAttack's random(1,4)
// (:1229) and random(2,8) (:1236, :1243) -- and every one is carried
// verbatim. Nothing was flattened to a constant.
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

class RS_CG_T0002 : RS_Chaingunner
{
	Default
	{
		// CH states `Game Doom`; ZScript has no Game actor property (DECORATE
		// only), so it is recorded here rather than declared. Not a loss --
		// this mod is Doom-only.
		Health 105;
		Species "Cguy";        // CH's own casing, cf. T00's "CGuy"
		BloodColor "blue";
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
		AttackSound "chainguy/attack";
		Obituary "%o was left as blue corpse";
		// CH's vanilla drops only -- the four CH-only pickups are itemised
		// in the header.
		DropItem "Chaingun";
		DropItem "ArmorBonus", 128;
		Translation "32:47=197:207", "31:31=197:197";
		Tag "Blue Chaingunner";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 150; r.dmgMul = 1.0;
		r.species = "Cguy";    // CH's own casing -- see the header
		r.bloodColor = "blue";
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
	// Three range bands. Beyond 1200 the long rail, 600-1200 the heavier
	// rail (M1), inside 600 the point-blank burst (Closer). All three
	// return to Missile+1 so the band is re-tested every pass.
	Missile:
		CPOS E 12 A_FaceTarget;
		CPOS E 0 A_JumpIfCloser(600, "Closer", false);
		CPOS E 0 A_JumpIfCloser(1200, "M1", false);
		CPOS E 3 Bright;
		CPOS F 6 Bright A_CustomRailgun(random(1,2), 0, "", "00 00 FF",
		                                RGF_NOPIERCING);
		CPOS E 0 A_CustomBulletAttack(0, 0, 1, random(1,4),
		                              "RS_BlueChainPuff2");
		CPOS E 5 Bright;
		CPOS F 1 A_MonsterRefire(150, "See");
		Goto Missile+1;
	M1:
		CPOS E 3 Bright;
		CPOS F 6 Bright A_CustomRailgun(random(1,3), 0, "", "00 00 FF",
		                                RGF_NOPIERCING);
		CPOS E 0 A_CustomBulletAttack(0, 0, 1, random(2,8),
		                              "RS_BlueChainPuff2");
		CPOS E 5 Bright;
		CPOS F 1 A_MonsterRefire(150, "See");
		Goto Missile+1;
	Closer:
		CPOS E 5 Bright;
		CPOS F 7 Bright A_CustomMissile("RS_BlueChainPuff3", 28, 15, 0, 0, 0);
		CPOS E 0 A_CustomBulletAttack(15, 15, 6, random(2,8),
		                              "RS_BlueChainPuff2", 8000);
		CPOS E 5 Bright;
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
	// CH switches the gib frames to the blue-tinted CGUB sheet rather
	// than translating CPOS -- gore does not remap cleanly. CGUB O..T
	// ship in sprites/monsters/Chaingunner/T02/. Chaingunners.txt:1279.
	XDeath:
		CGUB O 5;
		CGUB P 5 A_XScream;
		CGUB Q 5 A_NoBlocking;
		CGUB RS 5;
		CGUB T -1;
		Stop;
	Raise:
		CPOS N 5 A_JumpIfInventory("RS_CG_GrowRaisin", 1, "Grow");
		CPOS MLKJIH 5;
		Goto See;
	// CH's own tier promotion: resurrected while "growing" -> the purple
	// captain. Chaingunners.txt:1292.
	Grow:
		CPOS MLKJIH 5;
		// CH spawns the next creature and calls A_Die (Chaingunners.txt
		// Grow). That loses everything -- the promoted monster forgets its
		// target and returns at full health, which reads as "a new monster
		// appeared" rather than "that one changed". RS_PromoteTo runs the
		// COPPER promotion tell and carries target/master/vel/threshold and
		// health AS A FRACTION across the swap.
		CPOS A 0 { RS_PromoteTo("RS_CG_T0004"); }
		Stop;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:1247.
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
