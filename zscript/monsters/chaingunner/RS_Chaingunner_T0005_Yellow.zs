// =====================================================================
// RS_CG_T0005 -- Orange Former Captain (CH "YellowCGuy")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:1511-1675
// ACTOR:   YellowCGuy            (a bare Actor in CH -- NOT : ChaingunGuy)
// ROLE:    T -- a CH colour tier in its own right, not vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// CH's tag says "Orange Former Captain" while the actor is named
// YellowCGuy and its BloodColor is "Yellow". Both are transcribed as CH
// spells them; the mismatch is CH's, not ours.
//
// EVERY PROPERTY CH STATES, so a later differ can check the lot:
//   Health 200                    :1513
//   Species "Cguy3"               :1514   (T07 FireBlu shares this string)
//   BloodColor "Yellow"           :1515
//   DamageFactor "Exorcist", 3.0  :1516
//   DamageFactor "DIMp", 0        :1517
//   PainChance "DIMp", 0          :1518
//   Radius 20                     :1519
//   Height 56                     :1520
//   Speed 10                      :1521
//   PainChance 135                :1522
//   MONSTER                       :1523
//   +FLOORCLIP                    :1524
//   +DONTHARMSPECIES              :1525
//   +MISSILEMORE                  :1526
//   +MISSILEEVENMORE              :1527
//   SeeSound    "lady/aggro"      :1528
//   PainSound   "lady/hurt"       :1529
//   DeathSound  "lady/die"        :1530
//   ActiveSound "lady/active"     :1531
//   Obituary                      :1532
//   DropItem x7                   :1533-1539  (see the omission list)
//   Translation (4 ranges)        :1540
//   Tag "Orange Former Captain"   :1541
// CH states no Mass and no Game for this actor -- both are left unstated
// here rather than invented. An unstated property in CH means "engine
// default", and writing a number would make one up.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH5 -- CH sprinkles this spawn into Spawn/See/Dodge/
//                       Missile/Pain as a floating tier marker (:1546,
//                       :1550, :1552, :1557, :1559, :1564, :1645). Not in
//                       our tree, and RS_HealthBars already shows tier
//                       over the monster's head.
//   * Tickles (:1649-1651) / ThePlanBoner / CHBoner -- a joke death
//                       branch keyed to a CH-only inventory token that
//                       nothing here grants, so the branch is unreachable
//                       by construction. The Death: guard at :1653 goes
//                       with it.
//   * CHRandom_GibGenerator (:1661) + the A_SpawnParticle("Yellow")
//                       confetti (:1663, :1666) in XDeath -- the gib
//                       actor is CH-only and absent from our tree. The
//                       particle calls are engine intrinsics and WOULD
//                       work; they are dropped only to stay identical to
//                       RS_Chaingunner_C0001_Common.zs, which drops the
//                       pair together.
//   * CH_Pantsu (:1668) in XDeath -- CH-only drop actor, absent here.
//   * SplashAbyss burst in Pain.AbyssPE (:1633-1634, 45 spawns each) --
//                       omitted to match C0001's Pain.AbyssPE exactly.
//                       NOTE: RS_SplashAbyss DOES exist in our tree
//                       (zscript/monsters/monsterfx/RS_imp_projectiles.zs
//                       :203), so this one is restorable today -- but it
//                       must go back into all five captains at once or
//                       the abyss conversion will look different
//                       depending on who is being converted.
//   * DropItem "CH_Cell" (:1533), "CH_Plasmarifle",64 (:1534),
//     "ArmorBundle",64 (:1535), "HealthBundle" (:1536),
//     "HealthBundle",128 (:1538), "RLOverchargeSystemArmorPickup",32
//     (:1539) -- none of these pickup classes exist anywhere in this
//     repo (checked *.zs/*.zsc/*.txt; there is no DECORATE lump). Only
//     CH's vanilla drop, Chaingun (:1537), is carried. Restore the rest
//     verbatim the day the CH pickups are imported.
//
// TRANSCRIPTION NOTES -- 1:1 renames, no behaviour intended:
//   * A_CustomMissile -> A_SpawnProjectile (same signature, ZScript's
//     current name), matching zscript/monsters/RS_Chaingunner.zs.
//   * A_Fall -> A_NoBlocking (same function; A_Fall is the alias).
//   * A_CustomRailgun colours: CH writes "blue" and "none". Carried as
//     "00 00 FF" and "" -- the exact forms the already-ported T05 body
//     in RS_Chaingunner.zs:703-704 uses, so the two agree.
//   * CH's `Goto see` targets are all plain labels here; this actor has
//     no numeric state offsets to preserve.
//
// EVERY DAMAGE ROLL IS INTACT. CH puts no Damage property on this actor
// at all; its rolls live in the action calls -- A_CustomRailgun's
// random(1,2) / random(1,3) / random(1,4) -- and every one is carried
// verbatim. Nothing was flattened to a constant.
//
// DIVERGENCE FROM C0001, DELIBERATE AND FLAGGED:
//   * TierData sets r.flags and r.missileChance. It has to.
//     RS_MonsterMaster.RS_ApplyTierProperties ASSIGNS the flag set
//     absolutely (RS_MonsterMaster.zs:714-776) -- with r.flags left 0 it
//     runs `bDONTHARMSPECIES = false` at PostBeginPlay and the Default
//     block's +DONTHARMSPECIES is silently gone. The infighting web is
//     the whole point of the species strings, so the row states it.
//   * The Spawn.T00/See.T00/... alias block at the end of States. See
//     the comment there -- without it MissileState is nulled and this
//     captain never fires a shot.
// =====================================================================

class RS_CG_T0005 : RS_MonsterMaster
{
	Default
	{
		Health 200;
		Species "Cguy3";
		BloodColor "Yellow";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Radius 20;
		Height 56;
		Speed 10;
		PainChance 135;
		Monster;
		+FLOORCLIP
		+DONTHARMSPECIES
		+MISSILEMORE
		+MISSILEEVENMORE
		SeeSound "lady/aggro";
		PainSound "lady/hurt";
		DeathSound "lady/die";
		ActiveSound "lady/active";
		Obituary "%o got plasma fried by Orange Former Captain";
		// CH's vanilla drop only -- the six CH-only pickups are itemised
		// in the header.
		DropItem "Chaingun";
		Translation "112:124=210:223", "125:127=189:191",
		            "32:47=178:187", "168:191=114:127";
		Tag "Orange Former Captain";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 135; r.dmgMul = 1.0;
		r.species = "Cguy3";
		r.bloodColor = "Yellow";
		// Assigned absolutely by the base class -- see the header.
		r.flags = RS_TF_DONTHARMSPECIES;
		// +MISSILEMORE and +MISSILEEVENMORE stacked = 0.0625. LOWER FIRES
		// MORE (RS_MonsterMaster.zs:94-98).
		r.missileChance = 0.0625;
		return true;
	}

	override int MaxTier() { return 0; }

	States
	{
	Spawn:
		PZOW AB 10 A_Look;
		Loop;
	See:
		PZOW AABB 4 A_Chase;
		PZOW CCDD 4 A_Chase;
		PZOW A 0 A_Jump(88, "Dodge");
		Loop;
	Dodge:
		PZOW AABB 4 A_FastChase;
		PZOW CCDD 4 A_FastChase;
		PZOW A 0 A_Jump(94, "See");
		Loop;
	Missile:
		PZOW E 10 A_FaceTarget;
		TNT1 A 0 A_JumpIfCloser(300, "Spam2");
		TNT1 A 0 A_JumpIfCloser(750, "Spam");
		TNT1 A 0 A_JumpIfCloser(1250, "M1");
		TNT1 A 0 A_JumpIfCloser(1900, "M2");
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 5 Bright A_CustomRailgun(random(1,2), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0,
		                                "RS_CGRailBuff", 2, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 4 A_FaceTarget;
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 5 Bright A_CustomRailgun(random(1,2), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0,
		                                "RS_CGRailBuff", 3, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 4 A_FaceTarget;
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 5 Bright A_CustomRailgun(random(1,2), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0,
		                                "RS_CGRailBuff", 3, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 2;
		Goto See;
	M2:
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 4 Bright A_CustomRailgun(random(1,3), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0,
		                                "RS_CGRailBuff", 1, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 3 A_FaceTarget;
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 4 Bright A_CustomRailgun(random(1,3), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0,
		                                "RS_CGRailBuff", 2, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 3 A_FaceTarget;
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 4 Bright A_CustomRailgun(random(1,3), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 1, 0,
		                                "RS_CGRailBuff", 2, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 2;
		Goto See;
	M1:
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 4 Bright A_CustomRailgun(random(1,4), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 0, 0,
		                                "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 2 A_FaceTarget;
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 4 Bright A_CustomRailgun(random(1,4), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 0, 0,
		                                "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 2 A_FaceTarget;
		PZOW F 5 Bright A_CustomRailgun(0, 0, "", "00 00 FF", RGF_NOPIERCING);
		PZOW F 4 Bright A_CustomRailgun(random(1,4), 0, "00 00 FF", "00 00 FF",
		                                RGF_FULLBRIGHT | RGF_NORANDOMPUFFZ, 0, 0,
		                                "RS_CGRailBuff", 0, 0, 0, 66, 0.7, 0.9,
		                                "RS_CGRailBuff", 7, 10);
		PZOW E 2;
		Goto See;
	Spam:
		PZOW F 4 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1,1));
		PZOW E 2 A_FaceTarget;
		PZOW F 4 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1,1));
		PZOW E 2 A_FaceTarget;
		PZOW F 3 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-3,3));
		PZOW E 2 A_FaceTarget;
		PZOW F 3 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-2,2));
		PZOW E 2 A_FaceTarget;
		PZOW F 2 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1,1));
		PZOW FF 1 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1,1));
		PZOW FF 1 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, random(-1,1));
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 A_Jump(82, "Spam2");
		Goto See;
	Spam2:
		PZOW E 5 A_FaceTarget;
		PZOW F 1 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 3);
		PZOW F 2 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, -3);
		PZOW F 2 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, -6);
		PZOW F 3 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, -3);
		PZOW F 3 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 0);
		PZOW F 2 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 3);
		PZOW F 2 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 6);
		PZOW F 1 A_SpawnProjectile("RS_PlasmaBallSP3", 31, 4, 0);
		Goto Dodge;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:1627.
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
	Pain:
		PZOW G 3;
		PZOW G 3 A_Pain;
		PZOW G 1 A_Jump(128, "Dodge");
		Goto See;
	Death:
		PZOW H 5;
		PZOW I 5 A_Scream;
		PZOW J 5 A_NoBlocking;
		PZOW KLM 5;
		PZOW N -1;
		Stop;
	XDeath:
		PZOW O 5;
		PZOW P 5 A_XScream;
		PZOW Q 5 A_NoBlocking;
		PZOW RSTUV 5;
		PZOW W -1;
		Stop;
	Raise:
		PZOW MLKJIH 5;
		Goto See;

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
	// RS_Chaingunner_C0001_Common.zs has the same hole and no aliases --
	// flagged for the owner rather than edited from here.
	Spawn.T00:
		Goto Spawn;
	See.T00:
		Goto See;
	Missile.T00:
		Goto Missile;
	Pain.T00:
		Goto Pain;
	Death.T00:
		Goto Death;
	XDeath.T00:
		Goto XDeath;
	Raise.T00:
		Goto Raise;
	}
}
