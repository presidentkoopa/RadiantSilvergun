// =====================================================================
// RS_Zombieman -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\01\01_<code>.txt
// One CHP file per colour; the FIRST ACTOR in each file is the monster.
// CH (ART SOURCE\CH\decorate\Zombies.txt) was consulted ONLY to fill
// state blocks CHP leaves undefined -- where both define a block, CHP
// wins. Nothing here is inferred, tinted, or shared.
//
//   tier  CHP    body  HP    spd pain  what it actually is
//   T00   01_C   POSS    20   7  200  vanilla grunt, one aimed bullet
//   T01   01_G   ZOMG    30   9  180  green: two bullet cycles, trails
//                                     poison gas on walk / pain / death
//   T02   01_B   ZOMB    40   9  140  blue: 3-round burst, alternates
//                                     chase with fastchase
//   T03   01_CY  CYNT    30   9   40  cyan: translucent, ice shot,
//                                     SHATTERS on death (A_Burst)
//   T04   01_P   BPOS    65  10  120  purple: hitscan inside 800, else a
//                                     three-orb seeker volley
//   T05   01_Y   CZOW    90  13  100  orange zombiewoman: 3-shot burst or
//                                     mini-rockets that JAM after three
//   T06   01_A   ABTR   200  14   18  abyss infected: twin abyss bolts,
//                                     sows splash on walk, bursts on pain
//   T07   01_F   ZOMF    50  12  255  fireblu KAMIKAZE: NO ranged attack
//                                     at all -- trails fire and detonates
//   T08   01_BR  SGAR   100   4  128  bodyguard: sniper bullet, front-leap,
//                                     and the GET DOWN roll that heals
//                                     nearby demons
//   T09   01_GY  SHDT    80   4   40  gray: three-rock volley, gibs into a
//                                     13-rock ring
//   T10   01_R   ZUNM   115   8  100  red zombieunman: slug, or the
//                                     five-beam Unmaker rail barrage
//   T11   01_K   ZOMK  2000  26   16  PLAYER 9: SSG (one shell then a
//                                     reload), plasma spam, rockets by
//                                     range, real fist in melee
//   T12   01_W   MAGE  3500  10   16  THE UNDERTAKER: shovel blades close,
//                                     bone shotgun mid, rapid bones far;
//                                     the ladder upgrades bone grade and
//                                     finally unlocks the bone tornado
//   TEX   01_KX  ZMKX  5000  28   16  PLAYER X: the EX tier. A marine with
//                                     the whole arsenal on a range ladder
//                                     (SSG / plasma / chaingun+rockets),
//                                     a real SSG reload window, a rocket
//                                     barrage answer to pain, a BFG that
//                                     any branch can escalate into -- and
//                                     it stops to taunt over corpses
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
//
// RS mechanics preserved: the Undertaker charge ladder (RS_ClimbLadder,
// consts RS_ZM_TIER_LADDER / STEP1-3), rolled in the Pain DISPATCHER;
// GetBaseKeywords(); BodyTable() audit data; TintTable(). CH's
// user_skel1 / BoneUp staircase IS that ladder: CH buffs at BoneUp
// 5 / 9 / 12 -> user_skel1 2 / 3 / 4, which maps exactly onto rsStep
// 1 / 2 / 3, so T12's `user_skel1==3` gates become `rsStep >= 2` and
// `user_skel1==4` becomes `rsStep >= 3`.
//
// CHP cruft stripped per spec: NewIconCHP*/ColorTierIcon spawns,
// CHRandom_GibGenerator, A_SpawnParticle dressing, A_GivetoChildren,
// the CHBoner / CHWhitePlan / GrowRaisin inventory jumps, the
// CHAbyssMark/Grow/AbyssGrow colour-promotion chain (RS owns tiering),
// RandomLetterSpawner, and ACS_NamedExecuteAlways boss announcements.
// User vars became private int fields: RocketCounter -> rsRockets,
// ShotgunWhere -> rsShellUsed, BoneUp/user_skel1 -> ChargeCounter/rsStep.
//
// HONEST OMISSIONS (detail in the rebuild report):
//   * ZOMG frame U does not exist in CH or CHP; T01's XDeath tail uses
//     ZOMG T, the last real gib frame.
//   * No Raise for T03 / T11 / T12 -- neither CHP nor CH defines one.
//   * Per-tier BloodColor and GibHealth are CH/CHP actor properties with
//     no safe runtime setter here; not ported.
// =====================================================================

class RS_Zombieman : RS_MonsterMaster replaces Zombieman
{
	// ---- The Undertaker's ladder (CH BoneUp -> user_skel1 staircase) ----
	// Charge rises on every hit it takes. Steps at 5 / 9 / 12, exactly
	// CH's BoneUp thresholds. Tier-gated so only the heavy tiers climb.
	// T12 ONLY. CHP filters every BoneUp and heal to CommonWhiteZombie1,
	// the White Zombieman -- the ladder is the Undertaker's alone. This was
	// 6, which let six lower tiers climb a ladder CHP never gives them.
	const RS_ZM_TIER_LADDER = 12;
	const RS_ZM_STEP1 = 5;
	const RS_ZM_STEP2 = 9;
	const RS_ZM_STEP3 = 12;

	private int rsStep;       // T12 bone grade  (CH user_skel1 - 1)
	private int rsRockets;    // T05 rocket jam  (CH RocketCounter)
	private bool rsShellUsed; // T11 SSG shell   (CH ShotgunWhere)

	Default
	{
		Health 20;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "grunt/sight";  PainSound "grunt/pain";
		DeathSound "grunt/death"; ActiveSound "grunt/active";
		AttackSound "grunt/attack";
		Obituary "$OB_ZOMBIE";
		Tag "Zombieman";
	}

	// CHP's real per-colour numbers, read from 01_*.txt. Health and Speed
	// are absolute in CHP -- expressed here as multipliers of the Default
	// (Health 20, Speed 8) so the base class's recompute-from-defaults
	// contract still holds.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 200; r.dmgMul = 1.0;
		int hp = 20; int spd = 7;
		switch (t)
		{
			case 0:  hp = 20;   spd = 7;  r.painChance = 200; r.dmgMul = 1.0; break;
			case 1:  hp = 30;   spd = 9;  r.painChance = 180; r.dmgMul = 1.1; break;
			case 2:  hp = 40;   spd = 9;  r.painChance = 140; r.dmgMul = 1.2; break;
			case 3:  hp = 30;   spd = 9;  r.painChance = 40;  r.dmgMul = 1.3; break;
			case 4:  hp = 65;   spd = 10; r.painChance = 120; r.dmgMul = 1.4; break;
			case 5:  hp = 90;   spd = 13; r.painChance = 100; r.dmgMul = 1.5; break;
			case 6:  hp = 200;  spd = 14; r.painChance = 18;  r.dmgMul = 1.7; break;
			case 7:  hp = 50;   spd = 12; r.painChance = 255; r.dmgMul = 1.5; break;
			case 8:  hp = 100;  spd = 4;  r.painChance = 128; r.dmgMul = 1.6; break;
			case 9:  hp = 80;   spd = 4;  r.painChance = 40;  r.dmgMul = 1.5; break;
			case 10: hp = 115;  spd = 8;  r.painChance = 100; r.dmgMul = 1.8; break;
			case 11: hp = 2000; spd = 26; r.painChance = 16;  r.dmgMul = 2.5; break;
			case 12: hp = 3500; spd = 10; r.painChance = 16;  r.dmgMul = 3.0; break;
			// TEX -- CHP 01_KX CommonBlackZombieEX2, verbatim.
			case 13: hp = 5000; spd = 28; r.painChance = 16;  r.dmgMul = 3.5; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 20.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/Zombieman/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		return "POSS ZOMG ZOMB CYNT BPOS CZOW ABTR ZOMF SGAR SHDT ZUNM ZOMK MAGE ZMKX";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	// =================================================================
	// ATTACK PROFILES -- rs_21 section 5, first family to have them.
	//
	// Every tier that fires a PROJECTILE gets an RS_AttackProfile entry
	// here, so the attack exists as DATA and not only as a hardcoded
	// class name inside a state. That is what makes the catalog in
	// docs/monsters/Zombieman.md mean something: an attack described
	// there can actually be pointed at something else.
	//
	// WHAT THIS DOES NOT DO, stated plainly so nobody reads more into it
	// than is here. The tier states still fire their own attacks; this
	// slot is the machine-readable description ALONGSIDE them, not a
	// replacement for them. Converting the states to fire THROUGH the
	// slot is a separate job and it is not done for this family --
	// rs_17 s4 records the reason: MakeVolley fires its whole count on
	// ONE tic, so a double-tap, a refire loop or a walking burst cannot
	// be expressed by it yet. Four of Zombieman's attacks are exactly
	// those shapes, and three more fire from Pain, XDeath or the walk
	// cycle, which the slot has no hook for at all.
	//
	// HITSCAN TIERS ARE ABSENT ON PURPOSE. T00/T02/T05/T08/T10/T11 are
	// A_CustomBulletAttack, and MakeHitscan carries no bullet-count
	// field, so a profile for them would claim a fidelity it does not
	// have. Recorded in the catalog as a gap rather than faked here.
	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));

		switch (t)
		{
			case 1:   // GREEN -- gas rifle. CHP 01_G.txt:25,30
				// A DOUBLE-TAP, not one shot: CHP fires the gas, waits 8
				// tics on ZOMG F, and fires again. Now expressible --
				// MakeBurst is MakeVolley plus spacing.
				slot.Append(RS_AttackProfile.MakeBurst(
					RS_MonsterCatalog.PROJ_ZM_Gas(), 2, 8, 0.0,
					"grunt/attack", 1.0, 0.0, RS_FIRE_MISSILE, "Gas Double-Tap"));
				break;

			case 3:   // CYAN -- ice bolt. CHP 01_CY.txt
				slot.Append(RS_AttackProfile.MakeVolley(
					RS_MonsterCatalog.PROJ_ZM_IceBolt(), 1, 4.0,
					"ice/Cast", 1.0, 0.0, "Ice Bolt"));
				break;

			case 6:   // ABYSS -- the pincer. Two bolts, opposite arcs:
				// CHP 01_A.txt:33,34 is random(-7,1) then random(-1,7),
				// which is a squeeze, not a spread. FIVE tics apart, so
				// it is a burst; a single-tic volley would fire them
				// together and lose the pincer entirely.
				slot.Append(RS_AttackProfile.MakeBurst(
					RS_MonsterCatalog.PROJ_ZM_AbyssBolt(), 2, 5, 14.0,
					"imp/attack", 1.0, 0.0, RS_FIRE_MISSILE, "Pincer Bolts"));
				// THE INFECTION AURA -- fires once on SPAWN, not from
				// Missile, and could not be held in a slot at all until
				// FireTrigger existed. See Spawn.T06 and
				// RS_MonsterMaster.RS_HatchAbyss().
				slot.Append(RS_AttackProfile.MakeBurst(
					"RS_AbyssMark", 1, 0, 0.0,
					"", 1.0, 0.0, RS_FIRE_SPAWN, "Abyss Mark"));
				break;

			case 9:   // GRAY -- stone volley. CHP 01_GY.txt
				slot.Append(RS_AttackProfile.MakeVolley(
					RS_MonsterCatalog.PROJ_ZM_Rock(), 1, 0.0,
					"grunt/attack", 1.0, 0.0, "Stone Volley"));
				break;

			case 12:  // WHITE -- THE UNDERTAKER. Its rotation is the
				// escalation ladder: bone grade rises with BoneUp, and
				// the tornado only exists at rung 3. Listed in ladder
				// order so the slot reads the way the fight does.
				slot.Append(RS_AttackProfile.MakeVolley(
					RS_MonsterCatalog.PROJ_ZM_Bone1(), 1, 0.0,
					"skeleton/attack", 1.0, 0.0, "Bone Bolt"));
				slot.Append(RS_AttackProfile.MakeVolley(
					RS_MonsterCatalog.PROJ_ZM_Bone2(), 1, 0.0,
					"skeleton/attack", 1.0, 0.0, "Bone Bolt II"));
				slot.Append(RS_AttackProfile.MakeVolley(
					RS_MonsterCatalog.PROJ_ZM_Bone3(), 11, 24.0,
					"skeleton/attack", 1.0, 6.0, "Bone Shotgun"));
				slot.Append(RS_AttackProfile.MakeVolley(
					RS_MonsterCatalog.PROJ_ZM_Shovel(), 1, 0.0,
					"skeleton/attack", 1.0, 0.0, "Shovel"));
				slot.Append(RS_AttackProfile.MakeVolley(
					RS_MonsterCatalog.PROJ_ZM_Tornado(), 1, 0.0,
					"Under/Goodie", 1.0, 0.0, "Bone Tornado"));
				// THE PLAN -- fires once on spawn, marks the whole level.
				// Same case as the Abyss mark: a real attack that lives
				// nowhere near a Missile state.
				slot.Append(RS_AttackProfile.MakeBurst(
					"RS_UndertakerPlan", 1, 0, 0.0,
					"", 1.0, 0.0, RS_FIRE_SPAWN, "The Plan"));
				// THE SKELETON SEED -- MrBones arrives from a CORPSE, so
				// its trigger is DEATH and it is the map's, not the
				// boss's. Recorded here because the catalog has to be
				// able to name the Undertaker's actual win condition.
				slot.Append(RS_AttackProfile.MakeBurst(
					RS_MonsterCatalog.MINION_ZM_Bones(), 1, 0, 0.0,
					"", 1.0, 0.0, RS_FIRE_DEATH, "Skeleton Seed"));
				break;

			default:
				return null;   // this tier is hitscan or has no projectile
		}

		return slot;
	}

	override string TintTable()
	{
		return "- - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:zombieman role:fodder delivery:bullet element:kinetic mobility:ground";
	}

	// CH's ThrustThing/ThrustThingZ hops, as plain velocity -- same two
	// helpers RS_Shotgunner uses. The DECORATE specials take Z thrust in
	// quarter-units, hence the /4 already folded into the call sites.
	private void RS_HopZ(double amount)
	{
		vel.z += amount;
	}
	private void RS_HopDir(double deg, double force)
	{
		vel.xy += (cos(deg), sin(deg)) * force;
	}

	void RS_ClimbLadder()
	{
		if (Tier < RS_ZM_TIER_LADDER)
			return;

		AddCharge(1);

		if (rsStep < 1 && ChargeCounter >= RS_ZM_STEP1)
		{
			// CH Buff1: MISSILEEVENMORE, speed up, grow.
			// ABSOLUTE, NOT MULTIPLICATIVE. CHP 01_W.txt:124,125 is
			// A_Setspeed(16) / A_SetScale(1.1,1.1) -- it SETS values, it
			// does not scale them. Multiplying compounded across the three
			// rungs and landed the final form at Speed ~19.5 against CHP's
			// 28, roughly 30% slower, with the error growing at every step.
			rsStep = 1;
			Speed = 16;
			MissileChanceMult *= 0.125;   // == +MISSILEEVENMORE; lower fires MORE
			A_SetScale(1.1);
			A_StartSound("under/goodie", CHAN_VOICE);
		}
		else if (rsStep < 2 && ChargeCounter >= RS_ZM_STEP2)
		{
			// CH Buff2: user_skel1 == 3 -- bone grade 2 unlocks.
			// CHP 01_W.txt:134,135 -- A_Setspeed(21) / A_SetScale(1.25).
			rsStep = 2;
			Speed = 21;
			A_SetScale(1.25);
			A_StartSound("under/goodie", CHAN_VOICE);
		}
		else if (rsStep < 3 && ChargeCounter >= RS_ZM_STEP3)
		{
			// CH Buff3: user_skel1 == 4 -- final form, stops flinching,
			// bone grade 3 and the tornado unlock.
			// CHP 01_W.txt:145,147 -- A_Setspeed(28) / A_SetScale(1.45).
			rsStep = 3;
			bNOPAIN = true;
			Speed = 28;
			A_SetScale(1.45);
			A_StartSound("under/goodie", CHAN_VOICE);
		}
	}

	// Per-tier voices, plus the handful of per-tier actor properties CHP
	// sets that the tier row cannot carry. Sound names are CHP's own,
	// falling back to CH's parent actor where CHP declares none.
	override void OnTierApplied(int t)
	{
		SeeSound = "grunt/sight";   PainSound = "grunt/pain";
		DeathSound = "grunt/death"; ActiveSound = "grunt/active";
		AttackSound = "grunt/attack";
		Mass = 100;
		bROLLSPRITE = false;
		A_SetRenderStyle(1.0, STYLE_Normal);

		switch (t)
		{
			case 2:
			case 3:
			case 4:
			case 9:
				SeeSound = "zom2/see";    PainSound = "form2/hurt";
				DeathSound = "zom2/die";  ActiveSound = "form2/active";
				break;
			case 5:
				SeeSound = "lady/aggro";  PainSound = "lady/hurt";
				DeathSound = "lady/die";  ActiveSound = "lady/active";
				break;
			case 6:
				SeeSound = "zom2/see";    PainSound = "form2/hurt";
				DeathSound = "imp2/die";  ActiveSound = "form2/active";
				break;
			case 8:
				SeeSound = "zom2/see";    PainSound = "form2/hurt";
				DeathSound = "zom2/die";  ActiveSound = "form2/active";
				AttackSound = "snprfire";
				Mass = 1000;
				bROLLSPRITE = true;   // CH BrownZombie2 +ROLLSPRITE
				break;
			case 10:
				SeeSound = "zom2/see";    PainSound = "form2/hurt";
				DeathSound = "zom2/die";  ActiveSound = "form2/active";
				AttackSound = "zombie/unmaker";
				break;
			case 11:
			case 13:   // TEX -- Player X wears the player's own voice too
				PainSound = "*pain50";    DeathSound = "*death";
				break;
			case 12:
				SeeSound = "under/see";   PainSound = "skelpai";
				DeathSound = "under/die"; ActiveSound = "grunt/active";
				Mass = 400;
				break;
			default:
				break;
		}

		// CHP's cyan zombie is Renderstyle Translucent / Alpha 0.75.
		if (t == 3)
			A_SetRenderStyle(0.75, STYLE_Translucent);
		// CHP gives the gray zombie Mass 400.
		if (t == 9)
			Mass = 400;
	}

	States
	{
	// ===== dispatcher overrides: family-wide rolls happen here =====
	Missile:
		TNT1 A 0 { return TierState("Missile"); }
		Goto See;
	// ABYSS CONVERSION -- CH Zombies.txt:136, and inherited by EVERY zombie
	// parent (:136 :300 :414 :546 :813 :927 :1064 :1190 :1363 :1507). CHP
	// redefines it nowhere, so all ten tiers run it live. Our port had it
	// on none of them.
	//
	// TRIGGER: DamageType "AbyssPE", dealt only by the Abyss Pain
	// Elemental's pulse (CH thepains.txt:874, ours RS_AbyssPEPulse). The
	// pulse was typed "Plasma" here until today, which made this entire
	// chain unreachable -- so the state and its trigger were BOTH missing
	// and each hid the other.
	//
	// WHAT IT DOES: the zombie seizes up, sprouts the abyss shell over
	// twelve frames, throws ninety splash particles, and comes out an
	// ABYSS ZOMBIE. A conversion attack -- the Abyss PE does not kill its
	// allies, it recruits them upward.
	//
	// WE RETIER INSTEAD OF SWAPPING ACTORS. CH must spawn AbyssZombie2 and
	// A_die the original because its tiers are separate classes. Ours are
	// one class with a tier, and SetTier is documented safe mid-fight and
	// idempotent -- so the monster keeps its position, its target, its
	// threshold flags and its kill credit rather than dying and being
	// replaced. Same outcome, none of the actor-swap side effects.
	Pain.AbyssPE:
		TNT1 A 0
		{
			// Already Abyss or beyond? Nothing to convert to. CH has no
			// such guard because a T06 zombie is simply a different class
			// there and never carries this state.
			if (Tier >= 6)
				return ResolveState("Pain");
			bNOPAIN = true;
			A_SetScale(0.8);
			return ResolveState(null);
		}
		"AYPB" AAB 5 Bright;
		// CH Zombies.txt:139. The lump is imported and SNDINFO now
		// defines the PLAIN token -- CHP only ever defined AbyssForm/G,
		// /B, /P ... so its own Common tier called a name that resolved
		// to nothing.
		"AYPB" B 5 Bright { A_StartSound("AbyssForm", CHAN_VOICE); }
		"AYPB" BBACDE 5 Bright;
		TNT1 A 0
		{
			// CH throws 45 + 45 SplashAbyss at two velocities. One loop
			// rather than two 45-character frame runs; same count.
			for (int i = 0; i < 45; i++)
			{
				A_SpawnItemEx("RS_SplashAbyss", random(-16, 16), random(-16, 16), random(4, 32),
				              16, 0, 3, random(-359, 359), SXF_NOCHECKPOSITION|SXF_TRANSFERSPECIAL|SXF_TRANSFERAMBUSHFLAG);
				A_SpawnItemEx("RS_SplashAbyss", random(-16, 16), random(-16, 16), random(4, 32),
				              12, 0, 8, random(-359, 359), SXF_NOCHECKPOSITION|SXF_TRANSFERSPECIAL|SXF_TRANSFERAMBUSHFLAG);
			}
		}
		"AYPB" FGH 3 Bright;
		"AYPB" I 5 Bright;
		"AYPB" H 5 Bright;
		TNT1 A 0
		{
			// The conversion. CH: spawn AbyssZombie2 + A_die.
			bNOPAIN = false;
			A_SetScale(1.0);
			SetTier(6, true);
		}
		Goto See;

	Pain:
		// RS_ClimbLadder() USED TO BE CALLED HERE and that was the single
		// biggest behavioural error in this family: it fed the Undertaker's
		// escalation from damage TAKEN. CHP feeds it from skeleton DEATHS
		// (01_W.txt:3027-3029) -- the same variable names wired to the
		// opposite trigger. The feed now arrives via RS_BoneTithe; see
		// zscript/monsters/Zombieman/attacks/RS_Zombieman_Undertaker.zs.
		TNT1 A 0 { return TierState("Pain"); }
		Goto See;

	// ================= T00 COMMON (01_C) =================
	// Pain comes from CH CommonZombie's own parent (vanilla ZombieMan);
	// CHP's Common block does not redefine it.
	Spawn.T00:
		"POSS" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"POSS" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T00:
		"POSS" E 10 { A_FaceTarget(); }
		"POSS" F 8 { A_CustomBulletAttack(22.5, 0, 1, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"POSS" E 8;
		Goto See;
	Pain.T00:
		"POSS" G 3;
		"POSS" G 3 { A_Pain(); }
		Goto See;
	Death.T00:
		"POSS" H 5;
		"POSS" I 5 { A_Scream(); }
		"POSS" J 5 { A_NoBlocking(); }
		"POSS" K 5;
		"POSS" L -1;
		Stop;
	XDeath.T00:
		"POSS" M 3;
		"POSS" N 3 { A_XScream(); }
		"POSS" O 3 { A_NoBlocking(); }
		"POSS" PQRST 3;
		"POSS" U -1;
		Stop;
	Raise.T00:
		"POSS" K 5;
		"POSS" JIH 5;
		Goto See;

	// ================= T01 GREEN (01_G) =================
	// Fires TWO bullet/gas cycles per Missile pass, and once engaged it
	// walks inside its own poison cloud forever (CHP's See2).
	Spawn.T01:
		"ZOMG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"ZOMG" AABBCCDD 4 { A_Chase(); }
		Loop;
	See.T01.Gas:
		"ZOMG" AABBCCDD 4 { A_Chase(); }
		"ZOMG" A 0 { A_SpawnProjectile("RS_Gas11", 32, 0); }
		Loop;
	Missile.T01:
		"ZOMG" E 0 { A_SpawnProjectile("RS_Gas11", 32, 0); }
		"ZOMG" E 10 { A_FaceTarget(); }
		"ZOMG" F 8 { A_CustomBulletAttack(22.5, 0, 1, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"ZOMG" E 8 { A_SpawnProjectile("RS_Gas11", 32, 0); }
		"ZOMG" E 10 { A_FaceTarget(); }
		"ZOMG" F 8 { A_CustomBulletAttack(22.5, 0, 1, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"ZOMG" E 8 { A_SpawnProjectile("RS_Gas11", 32, 0); }
		Goto See.T01.Gas;
	Pain.T01:
		"ZOMG" G 3 { A_SpawnProjectile("RS_Gas11", 32, 0); }
		"ZOMG" G 3 { A_Pain(); }
		Goto See.T01.Gas;
	Death.T01:
		"ZOMG" H 5;
		"ZOMG" I 5 { A_Scream(); }
		"ZOMG" J 5 { A_NoBlocking(); }
		"ZOMG" K 5 { A_SpawnProjectile("RS_Gas11", 32, 0); }
		"ZOMG" L -1;
		Stop;
	XDeath.T01:
		// CHP's last three lines use ZOMG frame U; no such frame ships in
		// CH or CHP, so the gas burst rides the last real frame, T.
		"ZOMG" M 5 { A_SetTranslucent(0.8); }
		"ZOMG" N 5 { A_XScream(); }
		"ZOMG" O 5 { A_NoBlocking(); }
		"ZOMG" PQR 5 { A_SetTranslucent(0.5); }
		"ZOMG" RST 5 { A_SetTranslucent(0.3); }
		"ZOMG" T 5 { A_SpawnProjectile("RS_Gas11", 49, 0); }
		"ZOMG" T 0 { A_SpawnProjectile("RS_Gas11", 32, 7); }
		"ZOMG" T 0 { A_SpawnProjectile("RS_Gas11", 32, -7); }
		Stop;
	Raise.T01:
		"ZOMG" K 5;
		"ZOMG" JIH 5;
		Goto See.T01.Gas;

	// ================= T02 BLUE (01_B) =================
	Spawn.T02:
		"ZOMB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"ZOMB" AABBCCDD 4 { A_Chase(); }
		"ZOMB" AABBCCDD 4 { A_FastChase(); }
		Loop;
	Missile.T02:
		"ZOMB" E 10 { A_FaceTarget(); }
		"ZOMB" F 7 { A_CustomBulletAttack(7, 7, 3, random(1, 3), "BulletPuff"); }
		"ZOMB" E 8;
		Goto See;
	Pain.T02:
		"ZOMB" G 3;
		"ZOMB" G 3 { A_Pain(); }
		Goto See;
	Death.T02:
		"ZOMB" H 5;
		"ZOMB" I 5 { A_Scream(); }
		"ZOMB" J 5 { A_NoBlocking(); }
		"ZOMB" K 5;
		"ZOMB" L -1;
		Stop;
	XDeath.T02:
		"ZOMB" N 5 { A_XScream(); }
		"ZOMB" O 5 { A_NoBlocking(); }
		"ZOMB" PQRST 5;
		"ZOMB" U -1;
		Stop;
	Raise.T02:
		"ZOMB" K 5;
		"ZOMB" JIH 5;
		Goto See;

	// ================= T03 CYAN (01_CY) =================
	// Translucent, barely flinches, and its corpse wobbles then SHATTERS.
	// CHP and CH both give it no XDeath and no Raise.
	Spawn.T03:
		"CYNT" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"CYNT" AABBCCDD 2 { A_Chase(); }
		"CYNT" A 0 A_Jump(128, "See.T03.Rush");
		Loop;
	See.T03.Rush:
		"CYNT" AABBCCDD 1 { A_FastChase(); }
		Goto See.T03;
	Missile.T03:
		"CYNT" E 6 { A_FaceTarget(); }
		"CYNT" F 4 { A_SpawnProjectile("RS_IceZombieShot", 42, 1, random(-2, 2)); }
		"CYNT" E 4;
		Goto See;
	Pain.T03:
		"CYNT" G 3;
		"CYNT" G 3 { A_Pain(); }
		Goto See;
	Death.T03:
		"CYNT" G 12 { A_Scream(); }
		"CYNT" G 4 { A_NoBlocking(); }
		"CYNT" G 6 { A_SetScale(1.2, 0.8); }
		"CYNT" G 6 { A_SetScale(1.0, 1.0); }
		"CYNT" G 6 { A_SetScale(0.8, 1.2); }
		"CYNT" G 4 { A_SetScale(1.2, 0.8); }
		"CYNT" G 4 { A_SetScale(0.8, 1.2); }
		"CYNT" G 3 { A_SetScale(1.2, 0.8); }
		"CYNT" G 3 { A_SetScale(0.8, 1.2); }
		"CYNT" G 2 { A_SetScale(1.2, 0.8); }
		"CYNT" G 2 { A_SetScale(0.8, 1.2); }
		"CYNT" G 1 { A_SetScale(1.2, 0.8); }
		"CYNT" G 1 { A_SetScale(0.8, 1.2); }
		// MISL A, not MISL X -- CHP 01_CY.txt:55-56. Zero-tic so nothing
		// renders either way, but X is a real frame on this token and the
		// wrong one. NOTE the T09 rock site further down DOES use MISL X
		// and is correct (CHP 01_GY.txt:65) -- do not blanket-replace.
		MISL A 0 { A_StartSound("misc/icebreak", CHAN_BODY); }
		MISL A 0 { A_Burst("IceChunk"); }
		Stop;

	// ================= T04 PURPLE (01_P) =================
	// Hitscan inside 800 units, otherwise a three-orb seeker volley.
	Spawn.T04:
		"BPOS" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"BPOS" AABBCCDD 4 { A_Chase(); }
		"BPOS" AABBCCDD 4 { A_FastChase(); }
		Loop;
	Missile.T04:
		"BPOS" E 2 A_JumpIfCloser(800, "Missile.T04.Hitscan");
		"BPOS" E 0 A_Jump(255, "Missile.T04.Orb");
		// CHP falls straight through into Hitscanne on the rare miss.
	Missile.T04.Hitscan:
		"BPOS" E 10 { A_FaceTarget(); }
		"BPOS" F 7 { A_CustomBulletAttack(9, 9, 3, random(1, 2), "BulletPuff"); }
		"BPOS" F 4 { A_CustomBulletAttack(7, 7, 2, random(1, 2), "BulletPuff"); }
		"BPOS" E 8 A_MonsterRefire(128, "See");
		Goto Missile;
	Missile.T04.Orb:
		"BPOS" E 5 { A_FaceTarget(); }
		"BPOS" F 5 Bright { A_SpawnProjectile("RS_Orbb11", 46, 1); }
		"BPOS" F 5 Bright { A_SpawnProjectile("RS_Orbb11", 46, 1); }
		"BPOS" F 5 Bright { A_SpawnProjectile("RS_Orbb11", 46, 1); }
		"BPOS" E 5;
		Goto See;
	Pain.T04:
		"BPOS" G 3;
		"BPOS" G 3 { A_Pain(); }
		Goto See;
	Death.T04:
		"BPOS" H 5;
		"BPOS" I 5 { A_Scream(); }
		"BPOS" J 5 { A_NoBlocking(); }
		"BPOS" K 5;
		"BPOS" L -1;
		Stop;
	XDeath.T04:
		"BPOS" M 5;
		"BPOS" N 5 { A_XScream(); }
		"BPOS" O 5 { A_NoBlocking(); }
		"BPOS" PQRST 5;
		"BPOS" U -1;
		Stop;
	Raise.T04:
		"BPOS" K 5;
		"BPOS" JIH 5;
		Goto See;

	// ================= T05 ORANGE ZOMBIEWOMAN (01_Y) =================
	// Bursts inside 550, else a coin-flip between more bursts and
	// mini-rockets. Three rockets and the launcher JAMS -- she stands
	// there hammering it, NOPAIN, until it clears.
	Spawn.T05:
		"CZOW" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"CZOW" AABBCCDD 4 { A_Chase(); }
		Loop;
	See.T05.Dodge:
		"CZOW" AABBCCDD 4 { A_FastChase(); }
		"CZOW" A 0 A_Jump(88, "See.T05");
		Loop;
	Missile.T05:
		"CZOW" E 5 { A_FaceTarget(); }
		"CZOW" E 0 A_JumpIfCloser(550, "Missile.T05.Bullets");
		"CZOW" E 0 A_Jump(256, "Missile.T05.RocketsOr");
		Goto See;
	Missile.T05.RocketsOr:
		"CZOW" E 0 A_Jump(255, "Missile.T05.Rockets", "Missile.T05.Bullets");
		Goto See;
	Missile.T05.Bullets:
		"CZOW" F 0 { A_StartSound("chainguy/attack", CHAN_WEAPON); }
		"CZOW" F 3 Bright { A_CustomBulletAttack(4, 4, 1, random(1, 3), "BulletPuff"); }
		"CZOW" E 2 { A_FaceTarget(); }
		"CZOW" F 3 Bright { A_CustomBulletAttack(7, 7, 1, random(1, 3), "BulletPuff"); }
		"CZOW" E 2 { A_FaceTarget(); }
		"CZOW" F 3 Bright { A_CustomBulletAttack(9, 9, 1, random(1, 3), "BulletPuff"); }
		"CZOW" E 2 A_MonsterRefire(128, "See");
		Goto Missile;
	Missile.T05.Rockets:
		"CZOW" F 0 { if (rsRockets >= 3) return ResolveState("Missile.T05.Jam"); return ResolveState(null); }
		"CZOW" F 3 Bright { A_SpawnProjectile("RS_MiniRKTZombie", 32, 2, random(-2, 2)); }
		"CZOW" E 2 { rsRockets++; }
		"CZOW" E 2 A_MonsterRefire(128, "See");
		Goto Missile;
	Missile.T05.Jam:
		"CZOW" E 0 { bNOPAIN = true; }
		"CZOW" E 10 { A_StartSound("jam/jamd", CHAN_AUTO, 0, 1.9); }
		"CZOW" A 18 { A_FaceTarget(); }
		"CZOW" E 10 { A_StartSound("jam/jamd", CHAN_AUTO, 0, 1.9); }
		"CZOW" E 10 { A_StartSound("jam/jamd", CHAN_AUTO, 0, 1.9); }
		"CZOW" E 10 { A_StartSound("jam/jamd", CHAN_AUTO, 0, 1.9); }
		"CZOW" G 16 { rsRockets = 0; }
		"CZOW" A 16 { A_StartSound("lady/active", CHAN_VOICE); }
		"CZOW" A 0 { bNOPAIN = false; }
		Goto See;
	Pain.T05:
		"CZOW" G 3;
		"CZOW" G 3 { A_Pain(); }
		Goto See.T05.Dodge;
	Death.T05:
		"CZOW" H 5;
		"CZOW" I 5 { A_Scream(); }
		"CZOW" J 5 { A_NoBlocking(); }
		"CZOW" KLM 5;
		"CZOW" N -1;
		Stop;
	XDeath.T05:
		"CZOW" O 5;
		"CZOW" P 5 { A_XScream(); }
		"CZOW" Q 5 { A_NoBlocking(); }
		"CZOW" RSTUV 5;
		"CZOW" W -1;
		Stop;
	Raise.T05:
		"CZOW" MLKJIH 5;
		Goto See;

	// ================= T06 ABYSS INFECTED (01_A) =================
	// Leaks abyss splash as it walks, twin bolts at range, and being hurt
	// detonates a wide splash field around it.
	Spawn.T06:
		// FLING -- CHP 01_A.txt:18-19. CH puts this in its own state
		// between Spawn and Idle, which means it runs unconditionally the
		// instant the monster exists; NoDelay on the spawn tic is the
		// same thing without a state that exists only to fall through.
		//
		// An INFECTION AURA: every zombie within 528 units, through walls,
		// gets marked, and a marked zombie that dies comes back as an
		// Abyss Zombie.
		//
		// NO FILTER, DELIBERATELY, AND THIS IS THE INTERESTING PART.
		// CH gives to species "Zombie" with EXFILTER "CommonAbyssZombie"
		// -- mark the zombies, skip the ones already Abyss. It can do
		// that because every CH tier is a separate CLASS. Ours are one
		// class with a tier field, so the same filter would read
		// EXFILTER "RS_Zombieman" and exclude EVERY zombie, i.e. exactly
		// the monsters the aura exists to infect. A_RadiusGive cannot
		// express "same class, different tier".
		// So the mark goes out unfiltered and the tier test lives on the
		// receiving end: RS_MonsterMaster.RS_HatchAbyss() converts only a
		// Zombieman below tier 6. A non-zombie that catches the token
		// simply carries an inert item and nothing happens.
		TNT1 A 0 NoDelay { A_RadiusGive("RS_AbyssMark", 528, RGF_MONSTERS|RGF_NOSIGHT, 1); }
		"ABTR" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"ABTR" AAB 2 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"ABTR" B 2 { A_FastChase(); }
		"ABTR" CCD 2 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"ABTR" D 2 { A_FastChase(); }
		Loop;
	Missile.T06:
		"ABTR" E 10 { A_FaceTarget(); }
		"ABTR" F 5 { A_SpawnProjectile("RS_AbyssZshotCH", 36, 3, random(-7, 1)); }
		"ABTR" F 5 { A_SpawnProjectile("RS_AbyssZshotCH", 36, 3, random(-1, 7)); }
		"ABTR" E 10;
		Goto See;
	Pain.T06:
		"ABTR" G 1;
		"ABTR" G 1 { A_Pain(); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-178, 178), random(-178, 178), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		Goto See;
	Death.T06:
		"ABTR" H 5;
		"ABTR" I 5 { A_Scream(); }
		"ABTR" J 5 { A_NoBlocking(); }
		"ABTR" KL 5;
		"ABTR" L -1;
		Stop;
	XDeath.T06:
		"ABTR" M 5;
		"ABTR" N 5 { A_XScream(); }
		"ABTR" O 5 { A_NoBlocking(); }
		"ABTR" PQ 5;
		"ABTR" RSTU 5 { A_SpawnItemEx("RS_SplashAbyss2", random(-24, 24), random(-24, 24), random(8, 64), 0, 0, 2, random(-359, 359), SXF_NOCHECKPOSITION); }
		"ABTR" U -1;
		Stop;
	Raise.T06:
		"ABTR" KJIH 5;
		Goto See;

	// ================= T07 FIREBLU KAMIKAZE (01_F) =================
	// CHP gives this one NO ranged attack: Missile is a single blank tic
	// that dumps it straight back into the fire-trailing chase. Its whole
	// kit is the melee self-detonation.
	Spawn.T07:
		"ZOMF" AB 10 { A_Look(); }
		Loop;
	See.T07:
		"ZOMF" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.T07.Fire:
		"ZOMF" AABB 2 { A_Chase(); }
		"ZOMF" A 0 { A_SpawnItemEx("RS_FireSGguy2", -6, 0, 3, -2, 0, 1, -180); }
		"ZOMF" CCDD 2 { A_Chase(); }
		"ZOMF" A 0 { A_SpawnItemEx("RS_FireSGguy2", -6, 0, 3, -2, 0, 1, -180); }
		Loop;
	Missile.T07:
		TNT1 A 0;
		Goto See.T07.Fire;
	Melee.T07:
		"ZOMF" EF 5 Bright { A_FaceTarget(); }
		"ZOMF" E 0 { A_DamageSelf(9999); }
		Goto XDeath.T07;
	Pain.T07:
		"ZOMF" G 3 { A_SpawnItemEx("RS_FireSGguy2", 6, 0, 3, 9, 0, 1, random(0, 359)); }
		"ZOMF" G 3 { A_Pain(); }
		Goto See.T07.Fire;
	Death.T07:
		"ZOMF" H 5;
		"ZOMF" I 5 { A_Scream(); }
		"ZOMF" J 5 { A_NoBlocking(); }
		"ZOMF" K 5;
		"ZOMF" L -1;
		Stop;
	XDeath.T07:
		"ZOMF" P 0 Bright { A_StartSound("weapons/rocklx", 7, 0, 1.0); }
		MISL X 6 Bright { A_Explode(random(12, 44), 84); }
		MISL Y 6 Bright { A_Quake(20, 12, 0, 64, ""); }
		"ZOMF" AAAAA 0 { A_SpawnItemEx("RS_FireSGguy2", 0, 0, 3, random(3, 9), 0, 1, random(-359, 359)); }
		"ZOMF" U 0 { A_SpawnProjectile("RS_FireSGguy2", 32, 7); }
		"ZOMF" U 0 { A_SpawnProjectile("RS_FireSGguy2", 32, -7); }
		MISL Z 6 { A_NoBlocking(); }
		Stop;
	Raise.T07:
		"ZOMF" KJIH 5;
		Goto See.T07.Fire;

	// ================= T08 BODYGUARD (01_BR) =================
	// Slow sniper. Randomly scans for a big demon to bodyguard; if it
	// finds one it dives in front of it, rolling, and heals everything
	// nearby. Otherwise it hurls itself at the player (FrontJump).
	// CHP's thrust specials become explicit velocity: ThrustThingZ(n) is
	// n/4 units of vel.z, ThrustThing(n) is n units along facing.
	Spawn.T08:
		"SGAR" A 5 { A_Look(); }
		Loop;
	See.T08:
		"SGAR" BC 5 { A_Chase(); }
		TNT1 A 0 A_Jump(128, "See.T08.Checks");
	See.T08.Half:
		"SGAR" DE 5 { A_Chase(); }
		TNT1 A 0 A_Jump(200, "See.T08");
		TNT1 A 0 A_CheckLOF("Missile.T08.FrontJump", CLOFF_NOAIM_VERT | CLOFF_JUMPENEMY | CLOFF_SKIPOBSTACLES, 800);
		Goto See.T08;
	See.T08.Checks:
		// CHP scans for the vanilla class names; RS's replacements do not
		// inherit from them, so the RS classes are named directly.
		// Cyberdemon has no RS_ port yet -- the IWAD class is used.
		TNT1 A 0 A_CheckProximity("Missile.T08.GetDown", "RS_Archvile", 1000, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_SETMASTER | CPXF_CLOSEST);
		TNT1 A 0 A_CheckProximity("Missile.T08.GetDown", "RS_Baron", 1000, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_SETMASTER | CPXF_CLOSEST);
		TNT1 A 0 A_CheckProximity("Missile.T08.GetDown", "RS_HellKnight", 1000, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_SETMASTER | CPXF_CLOSEST);
		TNT1 A 0 A_CheckProximity("Missile.T08.GetDown", "Cyberdemon", 1000, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_SETMASTER | CPXF_CLOSEST);
		TNT1 A 0 A_CheckProximity("Missile.T08.GetDown", "RS_Chaingunner", 1000, 1, CPXF_ANCESTOR | CPXF_CHECKSIGHT | CPXF_SETMASTER | CPXF_CLOSEST);
		Goto See.T08.Half;
	Missile.T08:
		"SGAR" F 10 { A_FaceTarget(); }
		"SGAR" G 10 Bright { A_CustomBulletAttack(5, 0, 1, 10, "BulletPuff", 0, CBAF_NORANDOM); }
		"SGAR" F 10;
		Goto See;
	Missile.T08.GetDown:
		TNT1 A 0 A_CheckLOF("Missile.T08.GetDown2", CLOFF_NOAIM_VERT | CLOFF_JUMPENEMY | CLOFF_SKIPOBSTACLES, 800);
		Goto See.T08.Half;
	Missile.T08.GetDown2:
		"SGAR" F 5 { A_FaceMaster(); }
		"SGAR" F 1 { vel.z += 7.5; }
		"SGAR" F 1 { A_Recoil(-40); }
		"SGAR" F 1 { A_SetRoll(20); }
		"SGAR" F 1 { A_SetRoll(40); }
		"SGAR" F 1 { A_SetRoll(60); }
		"SGAR" F 1 { A_SetRoll(80); }
		"SGAR" F 1 { A_SetRoll(100); }
		"SGAR" F 1 { A_SetRoll(120); }
		"SGAR" F 1 { A_SetRoll(140); }
		"SGAR" F 1 { A_SetRoll(160); }
		"SGAR" F 1 { A_SetRoll(180); }
		TNT1 A 0 { A_RadiusGive("Health", 100, RGF_MONSTERS, 50); }
		"SGAR" F 1 { A_SetRoll(200); }
		"SGAR" F 1 { A_SetRoll(220); }
		"SGAR" F 1 { A_SetRoll(240); }
		"SGAR" F 1 { A_SetRoll(260); }
		"SGAR" F 1 { A_SetRoll(280); }
		"SGAR" F 1 { A_SetRoll(300); }
		"SGAR" F 1 { A_SetRoll(320); }
		"SGAR" F 1 { A_SetRoll(340); }
		"SGAR" F 1 { A_SetRoll(0); }
		"SGAR" F 6 { A_Stop(); }
		Goto See;
	Missile.T08.FrontJump:
		"SGAR" F 5 { A_FaceTarget(); }
		"SGAR" F 1 { vel.z += 7.0; }
		"SGAR" F 17 { A_Recoil(-14); }
		"SGAR" F 6 { A_Stop(); }
		"SGAR" BC 6 { A_FastChase(); }
		Goto See;
	Pain.T08:
		TNT1 A 0 { A_SetRoll(0); }
		"SGAR" H 8 { A_Pain(); }
		Goto See;
	Death.T08:
		TNT1 A 0 { A_SetRoll(0); }
		"SGAR" I 5;
		"SGAR" J 5 { A_Scream(); }
		"SGAR" K 5;
		"SGAR" L 5 { A_NoBlocking(); }
		"SGAR" M -1;
		Stop;
	XDeath.T08:
		// CHP itself gibs the bodyguard with plain POSS frames.
		"POSS" M 5;
		"POSS" N 5 { A_XScream(); }
		"POSS" O 5 { A_NoBlocking(); }
		"POSS" PQRST 5;
		"POSS" U -1;
		Stop;
	Raise.T08:
		"SGAR" LKJI 5;
		Goto See;

	// ================= T09 GRAY (01_GY) =================
	// Slow, heavy, three-rock volley. Gibbing it wobbles the corpse apart
	// and fires a 13-rock ring in every direction.
	Spawn.T09:
		"SHDT" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"SHDT" AABBCCDD 5 { A_Chase(); }
		Loop;
	Missile.T09:
		"SHDT" E 10 { A_FaceTarget(); }
		"SHDT" F 2 Bright { A_SpawnProjectile("RS_ZombieRock", 46, 1, random(-2, 2)); }
		"SHDT" F 2 { A_SpawnProjectile("RS_ZombieRock", 46, 1, random(-2, 2)); }
		"SHDT" F 2 Bright { A_SpawnProjectile("RS_ZombieRock", 46, 1, random(-2, 2)); }
		"SHDT" FEEEE 2;
		Goto See;
	Pain.T09:
		"SHDT" G 3;
		"SHDT" G 3 { A_Pain(); }
		Goto See;
	Death.T09:
		"SHDT" H 5;
		"SHDT" I 5 { A_Scream(); }
		"SHDT" J 5 { A_NoBlocking(); }
		"SHDT" K 5;
		"SHDT" L -1;
		Stop;
	XDeath.T09:
		"SHDT" G 12 { A_Scream(); }
		"SHDT" G 4 { A_NoBlocking(); }
		"SHDT" G 6 { A_SetScale(1.2, 0.8); }
		"SHDT" G 6 { A_SetScale(1.0, 1.0); }
		"SHDT" G 6 { A_SetScale(0.8, 1.2); }
		"SHDT" G 4 { A_SetScale(1.2, 0.8); }
		"SHDT" G 4 { A_SetScale(0.8, 1.2); }
		"SHDT" G 3 { A_SetScale(1.2, 0.8); }
		"SHDT" G 3 { A_SetScale(0.8, 1.2); }
		"SHDT" G 2 { A_SetScale(1.2, 0.8); }
		"SHDT" G 2 { A_SetScale(0.8, 1.2); }
		"SHDT" G 1 { A_SetScale(1.2, 0.8); }
		"SHDT" G 1 { A_SetScale(0.8, 1.2); }
		MISL X 0 { A_StartSound("weapons/rocklx", CHAN_BODY); }
		MISL XYZ 2;
		TNT1 AAAAAAAAAAAAA 0 { A_SpawnProjectile("RS_ZombieRock", 32, 0, random(-359, 359)); }
		Stop;
	Raise.T09:
		"SHDT" KJIH 5;
		Goto See;

	// ================= T10 RED ZOMBIEUNMAN (01_R) =================
	// One heavy slug, or -- one roll in four -- the Unmaker: five rail
	// beams fading red to black, then A_SentinelRefire to keep going.
	Spawn.T10:
		"ZUNM" AB 10 { A_Look(); }
		Loop;
	See.T10:
		"ZUNM" AABBCCDD 2 { A_Chase(); }
		Loop;
	Missile.T10:
		"ZUNM" E 0 A_Jump(64, "Missile.T10.Rail");
		"ZUNM" E 15 { A_FaceTarget(); }
		"ZUNM" F 10 { A_CustomBulletAttack(10, 2, 1, random(5, 15), "RS_BloodyPuff"); }
		"ZUNM" E 10;
		Goto See;
	Missile.T10.Rail:
		"ZUNM" E 16 { A_FaceTarget(); }
	Missile.T10.RailLoop:
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(random(5, 10), 4, "FF 00 00", 0, 0); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(random(5, 10), 4, "CC 00 00", 0, 0); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(random(5, 10), 4, "99 00 00", 0, 0); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(random(5, 10), 4, "55 00 00", 0, 0); }
		"ZUNM" E 0 { A_StartSound("zombie/unpower", CHAN_WEAPON); }
		"ZUNM" F 1 Bright { A_CustomRailgun(random(5, 10), 4, "33 00 00", 0, 0); }
		"ZUNM" E 10 { A_SentinelRefire(); }
		Goto Missile.T10.RailLoop;
	Pain.T10:
		"ZUNM" G 3;
		"ZUNM" G 3 { A_Pain(); }
		Goto See;
	Death.T10:
		"ZUNM" H 5;
		"ZUNM" I 5 { A_Scream(); }
		"ZUNM" J 5 { A_NoBlocking(); }
		"ZUNM" KLM 5;
		"ZUNM" N -1;
		Stop;
	XDeath.T10:
		"ZUNM" O 5;
		"ZUNM" P 5 { A_XScream(); }
		"ZUNM" Q 5 { A_NoBlocking(); }
		"ZUNM" RSTUV 5 { A_SpawnItemEx("RS_HKRedDeath", random(-24, 24), random(-24, 24), random(8, 64), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ZUNM" W -1;
		Stop;
	Raise.T10:
		"ZUNM" KJIH 5;
		Goto See;

	// ================= T11 PLAYER 9 (01_K) =================
	// A dead marine still playing the game. SSG inside 300 -- one shell,
	// then a real reload; plasma to 840; rocket-and-bullet mix beyond.
	// Neither CHP nor CH gives it a Raise.
	Spawn.T11:
		"ZOMK" A 4 { A_Look(); }
		Loop;
	See.T11:
		"ZOMK" ABCD 4 { A_Chase(); }
		"ZOMK" A 0 A_Jump(128, "See.T11.Sprint");
		Loop;
	See.T11.Sprint:
		"ZOMK" ABCD 4 { A_FastChase(); }
		"ZOMK" A 0 A_Jump(128, "See.T11");
		Loop;
	Melee.T11:
		"ZOMK" E 4 { A_FaceTarget(); }
		"ZOMK" E 4 { A_CustomMeleeAttack(random(20, 80), "*fist", ""); }
		Goto Missile.T11.SSG;
	Missile.T11:
		"ZOMK" E 0 A_JumpIfCloser(300, "Missile.T11.SSG");
		"ZOMK" E 0 A_JumpIfCloser(840, "Missile.T11.Plasma");
		"ZOMK" E 0 A_Jump(256, "Missile.T11.Rockets");
		Goto See;
	Missile.T11.SSG:
		"ZOMK" E 3 { A_FaceTarget(); }
		"ZOMK" F 0 { if (rsShellUsed) return ResolveState("Missile.T11.Jammed"); return ResolveState(null); }
		"ZOMK" F 0 { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		"ZOMK" F 13 Bright { A_CustomBulletAttack(22.5, 5, 8, 6, "BulletPuff", 0); }
		"ZOMK" F 0 { rsShellUsed = true; }
		Goto See;
	Missile.T11.Jammed:
		"ZOMK" E 8 Bright;
		"ZOMK" A 2 { A_StartSound("weapons/sshotl", CHAN_WEAPON); }
		"ZOMK" A 8 { rsShellUsed = false; }
		"ZOMK" E 2 { A_SpawnItemEx("Shell", 8, 4, 32, 3, 3, 1, angle + 5); }
		"ZOMK" E 0;
		Goto Missile;
	Missile.T11.Plasma:
		"ZOMK" E 2 { A_FaceTarget(); }
		"ZOMK" E 0 { A_FaceTarget(); }
		"ZOMK" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-5, 5)); }
		"ZOMK" E 1 { A_FaceTarget(); }
		"ZOMK" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-15, 15)); }
		"ZOMK" E 1 { A_FaceTarget(); }
		"ZOMK" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-25, 25)); }
		"ZOMK" E 1;
		"ZOMK" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-35, 35)); }
		"ZOMK" A 0 A_MonsterRefire(128, "Missile.T11.CellEject");
		Goto Missile;
	Missile.T11.CellEject:
		"ZOMK" A 8;
		"ZOMK" GG 3 { A_SpawnItemEx("Cell", 8, 4, 32, 3, 3, 1, angle + 5); }
		"ZOMK" A 3;
		Goto See;
	Missile.T11.Rockets:
		"ZOMK" E 2;
		"ZOMK" F 2 Bright { A_CustomBulletAttack(5.6, 0, 1, 5, "BulletPuff"); }
		"ZOMK" E 2 A_Jump(32, "Missile.T11.Rawk");
		"ZOMK" A 0 { A_CPosRefire(); }
		Goto Missile;
	Missile.T11.Rawk:
		"ZOMK" E 2;
		"ZOMK" F 2 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZOMK" E 2;
		Goto Missile;
	Pain.T11:
		"ZOMK" G 4;
		"ZOMK" G 4 { A_Pain(); }
		Goto See;
	Death.T11:
		"ZOMK" H 10;
		"ZOMK" I 10 { A_Scream(); }
		"ZOMK" J 10 { A_NoBlocking(); }
		"ZOMK" I 10 { A_StartSound("*death", CHAN_VOICE); }
		"ZOMK" J 10;
		"ZOMK" I 10 { A_StartSound("*death", CHAN_VOICE); }
		"ZOMK" J 10;
		"ZOMK" I 10 { A_StartSound("*death", CHAN_VOICE); }
		"ZOMK" J 10;
		"ZOMK" KLM 10;
		"ZOMK" M -1;
		Stop;
	XDeath.T11:
		"ZOMK" H 5;
		"ZOMK" H 20 { A_StartSound("*xdeath", CHAN_AUTO, 0, 1.0, ATTN_NONE); }
		"ZOMK" O 5 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		"ZOMK" P 5 { A_XScream(); }
		"ZOMK" Q 5 { A_NoBlocking(); }
		"ZOMK" RSTUV 5;
		"ZOMK" W -1;
		Stop;

	// ================= T12 THE UNDERTAKER (01_W) =================
	// Melee and Missile are the same block in CHP. Range picks the mode;
	// the ladder (rsStep, CH's user_skel1) upgrades bone grade at step 2
	// and opens the FinalForm branch -- and the bone tornado -- at 3.
	// Neither CHP nor CH gives it a Raise.
	Spawn.T12:
		// THE PLAN -- CHP 01_W.txt:18. Radius 16383 with RGF_NOSIGHT:
		// through walls, no line of sight, effectively the whole level.
		// Every monster alive when the Undertaker arrives is marked, and
		// every marked corpse hatches a skeleton (RS_MonsterMaster.Die).
		// NoDelay so it fires on the spawn tic, exactly as CHP's does.
		TNT1 A 0 NoDelay { A_RadiusGive("RS_UndertakerPlan", 16383, RGF_MONSTERS|RGF_NOSIGHT, 1); }
		"MAGE" A 4 { A_Look(); }
		Loop;
	See.T12:
		"MAGE" ABCD 4 { A_Chase(); }
		"MAGE" A 0 A_Jump(128, "See.T12.Sprint");
		Loop;
	See.T12.Sprint:
		"MAGE" ABCD 4 { A_FastChase(); }
		"MAGE" A 0 A_Jump(128, "See.T12");
		Loop;
	Melee.T12:
	Missile.T12:
		"MAGE" E 0 { if (rsStep >= 3) return ResolveState("Missile.T12.FinalForm"); return ResolveState(null); }
		"MAGE" E 0 A_JumpIfCloser(550, "Missile.T12.Shovel", true);
		"MAGE" E 0 A_JumpIfCloser(1250, "Missile.T12.MedRange");
		"MAGE" E 0 A_Jump(256, "Missile.T12.RapidBone");
		Goto See;
	Missile.T12.FinalForm:
		"MAGE" E 0 A_JumpIfCloser(550, "Missile.T12.Close2", true);
		"MAGE" E 0 A_JumpIfCloser(1250, "Missile.T12.MedRange2");
		"MAGE" E 0 A_Jump(256, "Missile.T12.RapidBone3");
		Goto See;
	Missile.T12.Close2:
		"MAGE" E 0 A_Jump(256, "Missile.T12.ShotBone3", "Missile.T12.Shovel");
		Goto See;
	Missile.T12.MedRange2:
		"MAGE" E 0 A_Jump(256, "Missile.T12.ShotBone3", "Missile.T12.BoneTornado", "Missile.T12.RapidBone3");
		Goto See;
	Missile.T12.BoneTornado:
		"MAGE" E 9 { A_FaceTarget(); }
		"MAGE" E 7 Bright { A_StartSound("under/goodie", 7, 0, 2.0, ATTN_NONE); }
		"MAGE" E 7;
		"MAGE" E 5 Bright;
		"MAGE" E 5;
		"MAGE" E 3 Bright;
		"MAGE" E 3;
		// RS_BoneTornado, not the old RS_BoneTorn2. CHP 01_W.txt:60 throws
		// one emitter and the whole attack lives inside it: seven distinct
		// orbiter rings interleaved over ~90 tics, plus periodic bolts.
		// The old actor spawned ONE stormer type from three lines against
		// CHP's thirty-two, and its orbiters were a static frandom cloud
		// rather than rings advancing 8 degrees a tic.
		// See zscript/monsters/Zombieman/attacks/RS_Zombieman_BoneTornado.zs.
		"MAGE" F 5 Bright { A_SpawnProjectile("RS_BoneTornado", 4, 0, random(-64, 64)); }
		"MAGE" F 3 Bright;
		"MAGE" E 3;
		Goto See;
	Missile.T12.RapidBone3:
		"MAGE" E 7 { A_FaceTarget(); }
	Missile.T12.RapidBone3Loop:
		"MAGE" F 1 Bright;
		"MAGE" FFF 1 Bright { A_SpawnProjectile("RS_BoneProjZM3", random(34, 40), random(-1, 1), random(-2, 2), CMF_OFFSETPITCH, random(-1, 1)); }
		"MAGE" F 1 A_MonsterRefire(120, "See");
		Goto Missile.T12.RapidBone3Loop;
	Missile.T12.ShotBone3:
		"MAGE" E 8 { A_FaceTarget(); }
		"MAGE" F 5 Bright;
		"MAGE" FFFFFFFFFFF 0 { A_SpawnProjectile("RS_BoneProjZM3", random(32, 42), random(-5, 5), random(-12, 12), CMF_OFFSETPITCH, random(-3, 3)); }
		"MAGE" E 5;
		Goto See;
	Missile.T12.MedRange:
		"MAGE" E 0 A_Jump(256, "Missile.T12.ShotBone", "Missile.T12.RapidBone");
		Goto See;
	Missile.T12.ShotBone:
		"MAGE" E 8 { A_FaceTarget(); }
		"MAGE" F 6 Bright { if (rsStep >= 2) return ResolveState("Missile.T12.ShotBone2"); return ResolveState(null); }
		"MAGE" FFFFFFFFF 0 { A_SpawnProjectile("RS_BoneProjZM", random(32, 42), random(-5, 5), random(-12, 12), CMF_OFFSETPITCH, random(-3, 3)); }
		"MAGE" E 5;
		Goto See;
	Missile.T12.ShotBone2:
		"MAGE" FFFFFFFFFFFF 0 { A_SpawnProjectile("RS_BoneProjZM2", random(32, 42), random(-5, 5), random(-12, 12), CMF_OFFSETPITCH, random(-3, 3)); }
		"MAGE" E 5;
		Goto See;
	Missile.T12.RapidBone:
		"MAGE" E 0 { if (rsStep >= 2) return ResolveState("Missile.T12.RapidBone2"); return ResolveState(null); }
		"MAGE" E 7 { A_FaceTarget(); }
	Missile.T12.RapidBoneLoop:
		"MAGE" F 1 Bright;
		"MAGE" FF 1 Bright { A_SpawnProjectile("RS_BoneProjZM", random(34, 40), random(-2, 2), random(-5, 5), CMF_OFFSETPITCH, random(-1, 1)); }
		"MAGE" F 0 A_Jump(12, "Missile.T12.ShotBone");
		"MAGE" F 2 A_MonsterRefire(150, "See");
		Goto Missile.T12.RapidBoneLoop;
	Missile.T12.RapidBone2:
		"MAGE" E 7 { A_FaceTarget(); }
	Missile.T12.RapidBone2Loop:
		"MAGE" F 1 Bright;
		"MAGE" FF 1 Bright { A_SpawnProjectile("RS_BoneProjZM2", random(34, 40), random(-1, 1), random(-3, 3), CMF_OFFSETPITCH, random(-1, 1)); }
		"MAGE" F 0 A_Jump(12, "Missile.T12.ShotBone2");
		"MAGE" F 1 A_MonsterRefire(120, "See");
		Goto Missile.T12.RapidBone2Loop;
	Missile.T12.Shovel:
		"MAGE" E 7 { A_FaceTarget(); }
		"MAGE" F 7 Bright { A_StartSound("spell/spellcast1", CHAN_WEAPON); }
		"MAGE" F 0 { A_SpawnProjectile("RS_ShoveZM", 38, 0, 0); }
		"MAGE" F 0 { A_SpawnProjectile("RS_ShoveZM", 38, 3, 5); }
		"MAGE" F 0 { A_SpawnProjectile("RS_ShoveZM", 38, -3, -5); }
		"MAGE" E 0 { if (rsStep >= 2) return ResolveState("Missile.T12.ShotBone2"); return ResolveState(null); }
		"MAGE" E 6 A_Jump(128, "Missile", "Missile.T12.ShotBone");
		Goto See;
	Pain.T12:
		"MAGE" G 4;
		"MAGE" G 4 { A_Pain(); }
		Goto See;
	Death.T12:
		"MAGE" H 13;
		"MAGE" I 13 { A_Scream(); }
		"MAGE" J 13 { A_NoBlocking(); }
		"MAGE" KLM 13;
		"MAGE" N -1;
		Stop;
	XDeath.T12:
		TNT1 A 0 { A_StartSound("undergib", CHAN_VOICE, 0, 1.0, ATTN_NONE); }
		TNT1 AAAA 0 { A_SpawnProjectile("RS_CH_BoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		TNT1 AAAAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-12, 12), random(-12, 12), random(20, 52)); }
		TNT1 AAAAAAAA 0 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-32, 32), random(-32, 32), random(10, 64)); }
		TNT1 AAA 1 { A_SpawnItemEx("RS_HomingRocketTrailFatso", random(-2, 2), random(-2, 2), random(26, 34)); }
		TNT1 A 0 { A_SetTranslucent(0.1); }
		REVB A 1 { vel.z += 11.25; }
		"MAGE" X 12;
		TNT1 A 0 { A_SetTranslucent(0.35); }
		TNT1 AAA 0 { A_SpawnProjectile("RS_CH_BoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"MAGE" X 12;
		TNT1 A 0 { A_SetTranslucent(0.7); }
		TNT1 AA 0 { A_SpawnProjectile("RS_CH_BoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"MAGE" X 12;
		TNT1 A 0 { A_SetTranslucent(1.0); }
		TNT1 A 0 { A_SpawnProjectile("RS_CH_BoneGib", 0, 12, random(-180, 180), 0, random(0, 90)); }
		"MAGE" X -1;
		Stop;

	// ================= TEX PLAYER X (01_KX) =================
	// The EX tier: CHP's CommonBlackZombieEX2. Not a zombie at all -- a
	// black-silhouetted PLAYER carrying the whole arsenal, and the fight
	// is a duel against a marine who dodges, reloads, and taunts you.
	//
	// Its structure is a RANGE LADDER, not a rotation:
	//   under 300  -> super shotgun (one shell, then a real reload)
	//   under 840  -> plasma spam, which can escalate into the BFG
	//   beyond     -> chaingun taps with a rocket mixed in
	// and every branch can roll into the rocket barrage or the BFG, so no
	// distance is ever safe for long.
	//
	// The reload is the fight's real window: after the SSG shell it must
	// stand still, rack the gun, and eject a shell -- and CHP makes it
	// COMMIT by jumping straight from there into a barrage. rsShellUsed
	// is CH's ShotgunWhere token; the same field T11 already uses, which
	// is the same mechanic.
	//
	// It also TAUNTS. Every attack ends in A_CheckFlag("CORPSE", ...) on
	// its target: kill a teammate in front of it and it stops shooting to
	// laugh at you. That is content, not cruft, so it is ported whole.
	Spawn.TEX:
		"ZMKX" A 4 { A_Look(); }
		Loop;
	See.TEX:
		"ZMKX" ABCD 4 { A_Chase(); }
		"ZMKX" A 0 A_Jump(128, "See.TEX.Fast");
		Loop;
	See.TEX.Fast:
		"ZMKX" ABCD 4 { A_FastChase(); }
		"ZMKX" A 0 A_Jump(128, "See.TEX");
		Loop;
	Melee.TEX:
		"ZMKX" E 4 { A_FaceTarget(); }
		"ZMKX" E 4 { A_CustomMeleeAttack(random(60, 120), "*fist", ""); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		Goto Missile.TEX.Shotgun;
	Missile.TEX:
		"ZMKX" E 0 A_JumpIfCloser(300, "Missile.TEX.Shotgun");
		"ZMKX" E 0 A_JumpIfCloser(840, "Missile.TEX.PlasmaSpam");
		"ZMKX" E 0 A_Jump(256, "Missile.TEX.Chaingun");
		Goto See;
	// Pure showboating -- and it is the only time the fight pauses.
	// CHP 01_KX.txt:46-65. The laugh lands on twelve of the nineteen
	// frames, always the G ones.
	//
	// IT WAS SILENT UNTIL 2026-08-04 AND SO IS CHP'S. CHP hangs
	// A_Playsound("HEHEEENH",0) on these frames but its SNDINFO defines
	// only HEHEEENH/A /B /BR /CY /F /G /GY /K /KX /P /R /W /WX /Y -- no
	// plain token and no /C -- so the Common Player X calls a name that
	// resolves to nothing. Nothing in CH defines it either. The lump does
	// exist (CH/sounds/HEHEEENH.wav); only the mapping was missing.
	// Imported to sounds/monsters/ and mapped to the plain token in
	// SNDINFO, so ours actually laughs.
	Missile.TEX.Taunt:
		"ZMKX" A 4;
		"ZMKX" G 4 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" A 4;
		"ZMKX" G 4 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" A 4;
		"ZMKX" G 4 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" A 4;
		"ZMKX" G 4 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" A 4;
		"ZMKX" G 4 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" A 3;
		"ZMKX" G 3 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" A 3;
		"ZMKX" G 3 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" A 3;
		"ZMKX" G 3 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" GAG 4 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" AGA 3 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		"ZMKX" GAG 2 { A_StartSound("HEHEEENH", CHAN_VOICE); }
		Goto See;
	// Closes the last of the gap with a hop before it fires.
	Missile.TEX.Shotgun:
		"ZMKX" E 3 { A_FaceTarget(); }
		"ZMKX" E 1 A_JumpIfCloser(300, "Missile.TEX.ShotgunFire");
		"ZMKX" E 1 { RS_HopZ(16); }
		"ZMKX" E 1 { RS_HopDir(angle, 12); }
		"ZMKX" E 10 { A_FaceTarget(); }
	Missile.TEX.ShotgunFire:
		"ZMKX" F 0 { if (rsShellUsed) return ResolveState("Missile.TEX.Reload"); return ResolveState(null); }
		"ZMKX" F 0 { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		"ZMKX" F 13 Bright { A_CustomBulletAttack(22.5, 5, 8, 6, "BulletPuff", 0); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" F 0 { rsShellUsed = true; }
		Goto See;
	// THE WINDOW. Racks the gun, throws the shell, and then commits to a
	// barrage or the BFG rather than going back to neutral.
	Missile.TEX.Reload:
		"ZMKX" E 8 Bright;
		"ZMKX" A 2 { A_StartSound("weapons/sshotl", CHAN_WEAPON); }
		"ZMKX" A 8 { rsShellUsed = false; }
		"ZMKX" E 2 { A_SpawnItemEx("Shell", 8, 4, 32, 3, 3, 1, angle + 5); }
		"ZMKX" E 0 A_Jump(84, "Missile.TEX.Barrage");
		"ZMKX" E 0 A_Jump(64, "Missile.TEX.BFG");
		Goto Missile.TEX;
	// Backpedals, strafes, and puts three rockets downrange from the side
	// you did not expect -- the strafe direction is itself a coin flip.
	Missile.TEX.Barrage:
		"ZMKX" E 1 { RS_HopZ(16); }
		"ZMKX" E 1 { RS_HopDir(angle - 180, 12); }
		"ZMKX" E 6 { A_FaceTarget(); }
		TNT1 A 0 A_Jump(128, "Missile.TEX.BarrageAlt");
		"ZMKX" E 1 { RS_HopZ(16); }
		"ZMKX" E 3 { RS_HopDir(angle + 90, 12); }
		"ZMKX" F 4 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" F 4 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" F 4 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		Goto See;
	Missile.TEX.BarrageAlt:
		"ZMKX" E 1 { RS_HopZ(16); }
		"ZMKX" E 3 { RS_HopDir(angle - 90, 12); }
		"ZMKX" F 4 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" F 4 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" F 4 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		Goto See;
	// A long, loud, deliberately readable wind-up -- twenty-four tics of
	// standing still telling you exactly what is about to happen.
	Missile.TEX.BFG:
		"ZMKX" E 1;
		"ZMKX" E 1 { A_StartSound("weapons/bfgf", CHAN_WEAPON); }
		"ZMKX" E 10 Bright;
		"ZMKX" E 8 Bright { A_FaceTarget(); }
		"ZMKX" E 6 Bright { A_FaceTarget(); }
		"ZMKX" F 4 Bright { A_SpawnProjectile("RS_PlayerEXBFG", 32, 0, 0); }
		"ZMKX" E 12;
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		Goto See;
	// Mid-range: four plasma bolts that WIDEN as the burst goes, so the
	// safe lane closes while you are standing in it.
	Missile.TEX.PlasmaSpam:
		"ZMKX" E 0 A_Jump(84, "Missile.TEX.Barrage");
		"ZMKX" E 2 { A_FaceTarget(); }
		"ZMKX" E 0 { A_FaceTarget(); }
		"ZMKX" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-5, 5)); }
		"ZMKX" E 1 { A_FaceTarget(); }
		"ZMKX" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-15, 15)); }
		"ZMKX" E 1 { A_FaceTarget(); }
		"ZMKX" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-25, 25)); }
		"ZMKX" E 1 { A_FaceTarget(); }
		"ZMKX" E 0 A_Jump(34, "Missile.TEX.BFG");
		"ZMKX" F 3 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 32, 0, random(-35, 35)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" A 0 A_MonsterRefire(128, "Missile.TEX.CellEject");
		Goto Missile.TEX;
	Missile.TEX.CellEject:
		"ZMKX" A 8;
		"ZMKX" GG 3 { A_SpawnItemEx("Cell", 8, 4, 32, 3, 3, 1, angle + 5); }
		"ZMKX" A 3;
		Goto See;
	// Long range: single chaingun taps on a refire loop, with a small
	// chance each tap of becoming a rocket instead.
	Missile.TEX.Chaingun:
		"ZMKX" E 2 { A_FaceTarget(); }
		"ZMKX" F 2 Bright { A_CustomBulletAttack(5.6, 0, 1, 5, "BulletPuff"); }
		"ZMKX" E 2 A_Jump(32, "Missile.TEX.Rocket");
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" E 0 A_Jump(8, "Missile.TEX.BFG");
		"ZMKX" A 0 A_CPosRefire();
		Goto Missile.TEX;
	Missile.TEX.Rocket:
		"ZMKX" E 2 { A_FaceTarget(); }
		"ZMKX" F 2 Bright { A_SpawnProjectile("RS_Rocket", 32, 0, random(-1, 1)); }
		"ZMKX" E 0 { A_CheckFlag("CORPSE", "Missile.TEX.Taunt", AAPTR_TARGET); }
		"ZMKX" E 2 A_Jump(34, "Missile.TEX.BFG");
		Goto Missile.TEX;
	// Answers pain with rockets a third of the time. Being hurt makes it
	// MORE dangerous, not less.
	Pain.TEX:
		"ZMKX" G 4;
		"ZMKX" G 4 { A_Pain(); }
		"ZMKX" E 0 A_Jump(84, "Missile.TEX.Barrage");
		Goto See;
	// The long death -- it screams four separate times on the way down.
	Death.TEX:
		"ZMKX" H 10;
		"ZMKX" I 10 { A_Scream(); }
		"ZMKX" J 10 { A_NoBlocking(); }
		"ZMKX" I 10 { A_StartSound("*death", CHAN_VOICE); }
		"ZMKX" J 10;
		"ZMKX" I 10 { A_StartSound("*death", CHAN_VOICE); }
		"ZMKX" J 10;
		"ZMKX" I 10 { A_StartSound("*death", CHAN_VOICE); }
		"ZMKX" J 10;
		"ZMKX" KLM 10;
		"ZMKX" M -1;
		Stop;
	XDeath.TEX:
		"ZMKX" H 5;
		"ZMKX" H 20 { A_StartSound("*xdeath", CHAN_VOICE, 0, 1.0, ATTN_NONE); }
		"ZMKX" O 5 { A_StartSound("misc/gibbed/c", CHAN_BODY); }
		"ZMKX" P 5 { A_XScream(); }
		"ZMKX" Q 5 { A_NoBlocking(); }
		"ZMKX" RSTUV 5;
		"ZMKX" W -1;
		Stop;
	}
}
