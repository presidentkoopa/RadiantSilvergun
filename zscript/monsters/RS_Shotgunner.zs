// =====================================================================
// RS_Shotgunner -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\02\02_<code>.txt
// (first ACTOR block of each file). Where a CHP actor left a state
// undefined it inherits from its CH parent in
// E:\New folder\ART SOURCE\CH\decorate\Shotgunners.txt -- CHP always
// wins, CH only fills gaps. Every tier below is a genuinely different
// creature with its own sprite set, stats, voice and attack.
//
//   tier  CHP    parent      body   HP    what it actually is
//   T00   02_C   CommonSG    SPOS     30  vanilla 3-pellet blast
//   T01   02_G   GreenSG     SGUG     50  seven-bolt plasma shell fan
//   T02   02_B   BlueSG      SGUB     62  triple railgun, lance up close
//   T03   02_CY  CyanSG2     CNSG     60  frost buckshot / ice shot,
//                                         bunny-hops out of your line
//   T04   02_P   PurpleSG    HMZP     83  hazmat: charges in, then a
//                                         three-shot purple fire burst
//   T05   02_Y   YellowSG    ASGZ     96  assault shotgun, 16 volleys
//                                         then a real reload window
//   T06   02_A   AbyssSG2    ABSG    333  abyss chief: leaping shotgun
//                                         + splash rain, enrages on pain
//   T07   02_F   FirebluSG2  SGUF    111  five-way fireblu shell
//   T08   02_BR  BrownSG2    QSZM     90  twenty mud pellets, or a charge
//   T09   02_GY  GraySG2     GRSH    100  sniper: one hard shot, or digs
//                                         in and becomes a turret
//   T10   02_R   RedSG       GPOS    150  RNG sergeant: 15-20 pellet
//                                         spray that jams, or red mess
//   T11   02_K   BlackSG3    ZSP2   2450  CREW COMMANDER: airstrike,
//                                         sniper mark, gas nade, squad
//   T12   02_W   WhiteSG2    BENE   5000  BENELLUS, GOD OF SHOTGUNS
//
// RS mechanics preserved from the previous file: the T07+ squad summon
// (RS_CallSquad / RS_SG_TIER_SQUAD), GetBaseKeywords(), and
// MinionsDieWithMe(). The squad roll lives in the Missile DISPATCHER so
// every eligible tier inherits it without repeating it thirteen times.
//
// CHP-only cruft stripped throughout: NewIconCHP*/ColorTierIcon spawns,
// CHRandom_GibGenerator, A_GivetoChildren("GoAway"), CHWhitePlan /
// CHBoner "Tickles" paths, ACS_NamedExecuteAlways announcements,
// CallACS() gates, RandomLetterSpawner, and CH's GrowRaisin colour
// promotion (the tier dial owns that now).
// =====================================================================

class RS_Shotgunner : RS_HumanMonster replaces ShotgunGuy
{
	// --- RS mechanic: the crew commander's squad call -----------------
	// CHP's black shotgunner calls in a squad of its own kind. Summoning
	// our OWN species at a lower tier is the cleanest version of that --
	// no bespoke minion class, and the squad inherits the whole tier
	// system for free.
	const RS_SG_TIER_SQUAD = 7;

	// CHP tracks these with user vars / dummy inventory items; the spec
	// says private int fields instead.
	private int rsAsgAmmo;      // T05 ASGZAmmo   -- volleys before reload
	private int rsSniperReady;  // T09 User_Ready -- dug in as a turret
	private int rsShotgunJam;   // T10 ShotgunWhere -- the RNG gun jammed
	private int rsEscortDone;   // T11 -- the two spawn-time bodyguards

	Default
	{
		Health 30;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "shotguy/sight";  PainSound "shotguy/pain";
		DeathSound "shotguy/death"; ActiveSound "shotguy/active";
		AttackSound "shotguy/attack";
		Obituary "$OB_SHOTGUY";
		Tag "Shotgun Guy";
		DropItem "Shotgun";
	}

	// CHP's real per-colour numbers, read from 02_*.txt. Health is
	// absolute (not a multiplier) -- these are hand-tuned creatures.
	// Default Health is 30 and Default Speed 8, so the absolute numbers
	// are expressed as multipliers and the base class's
	// recompute-from-defaults contract still holds.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 170; r.dmgMul = 1.0;
		int hp = 30; int spd = 8;
		switch (t)
		{
			case 0:  hp = 30;   spd = 8;  r.painChance = 170; r.dmgMul = 1.0; break;
			case 1:  hp = 50;   spd = 8;  r.painChance = 160; r.dmgMul = 1.1; break;
			case 2:  hp = 62;   spd = 9;  r.painChance = 150; r.dmgMul = 1.2; break;
			case 3:  hp = 60;   spd = 8;  r.painChance = 128; r.dmgMul = 1.2; break;
			case 4:  hp = 83;   spd = 9;  r.painChance = 150; r.dmgMul = 1.3; break;
			case 5:  hp = 96;   spd = 9;  r.painChance = 128; r.dmgMul = 1.4; break;
			case 6:  hp = 333;  spd = 13; r.painChance = 168; r.dmgMul = 1.6; break;
			case 7:  hp = 111;  spd = 12; r.painChance = 110; r.dmgMul = 1.5; break;
			case 8:  hp = 90;   spd = 9;  r.painChance = 102; r.dmgMul = 1.4; break;
			case 9:  hp = 100;  spd = 8;  r.painChance = 150; r.dmgMul = 1.7; break;
			case 10: hp = 150;  spd = 9;  r.painChance = 110; r.dmgMul = 1.8; break;
			case 11: hp = 2450; spd = 16; r.painChance = 40;  r.dmgMul = 2.2; break;
			case 12: hp = 5000; spd = 28; r.painChance = 8;   r.dmgMul = 3.0; break;
			// TEX -- CHP 02_WX GreenWhiteSGEX2, verbatim (FloatSpeed 39
			// is a Default-only property with no per-tier setter here, so
			// only Speed carries; noted in the header).
			case 13: hp = 10671; spd = 39; r.painChance = 6; r.dmgMul = 3.5; break;
			default: return false;
		}
		r.hpMul  = double(hp) / 30.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/Shotgunner/T<nn>/ (T00's SPOS
	// is the stock IWAD body and needs no files).
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX
		return "SPOS SGUG SGUB CNSG HMZP ASGZ ABSG SGUF QSZM GRSH GPOS ZSP2 BENE BENE";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	// TEX is the ONE exception in this family: it shares T12's BENE
	// artwork (CHP ships no separate EX sprite set for Benellus) and CHP
	// distinguishes it with a real green palette remap
	// ("0:255=%[0.00,0.00,0.00]:[0.18,1.32,0.18]" on GreenWhiteSGEX2), so
	// TEX carries a translation while every other tier stays "-".
	// Recipe lives in TRNSLATE.txt as rs_sgun_tex.
	override string TintTable()
	{
		//      T00 T01 T02 T03 T04 T05 T06 T07 T08 T09 T10 T11 T12 TEX
		return "- - - - - - - - - - - - - rs_sgun_tex";
	}

	override string GetBaseKeywords()
	{
		return "species:shotgunner role:fodder delivery:bullet payload:multi element:kinetic mobility:ground";
	}

	override bool MinionsDieWithMe() { return false; }

	void RS_CallSquad()
	{
		if (Tier < RS_SG_TIER_SQUAD)
			return;
		int cap = (Tier >= 11) ? 4 : 2;
		if (SummonPack("RS_Shotgunner", 2, cap, -4, 88.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	// CHP sets the voice per colour as ACTOR properties; one class with
	// thirteen bodies has to apply them on tier change instead. Same
	// class of thing as the tint -- data applied when the creature
	// changes, never per state. (Lumps + SNDINFO entries: sounds/monsters
	// and the "Shotgunner line" block in SNDINFO.)
	override void OnTierApplied(int t)
	{
		Super.OnTierApplied(t);

		// Benellus floats; every other body is a ground grunt.
		bool floaty = (t == 12);
		bNOGRAVITY = floaty;
		bFLOAT     = floaty;
		bFLOATBOB  = floaty;

		switch (t)
		{
			case 2:
			case 4:
				SeeSound = "SGUY2/See";     PainSound   = "Form2/Hurt";
				DeathSound = "Sguy2/Die";   ActiveSound = "shotguy/active";
				if (t == 2) AttackSound = "shotguy/attack";
				else        AttackSound = "";
				break;
			case 3:
			case 11:
				SeeSound = "ZSpecOps/Sight";  PainSound   = "ZSpecOps/Pain";
				DeathSound = "ZSpecOps/Death"; ActiveSound = "ZSpecOps/Sight";
				AttackSound = "";
				break;
			case 5:
			case 6:
				SeeSound = "SGUY2/See";     PainSound   = "Form2/Hurt";
				DeathSound = "Sguy2/Die";   ActiveSound = "grunt/active";
				AttackSound = "asgguy/asgfir";
				break;
			case 7:
			case 10:
				SeeSound = "SSGUNER/sight"; PainSound   = "grunt/pain";
				DeathSound = "SSGUNER/death"; ActiveSound = "SSGUNER/idle";
				AttackSound = "SSGUNER/SSG";
				break;
			case 8:
				SeeSound = "SSGUNER/sight"; PainSound   = "Form2/Hurt";
				DeathSound = "Sguy2/Die";   ActiveSound = "shotguy/active";
				AttackSound = "";
				break;
			case 9:
				SeeSound = "SGUY2/See";     PainSound   = "Form2/Hurt";
				DeathSound = "Sguy2/Die";   ActiveSound = "shotguy/active";
				AttackSound = "SNPRFIRE";
				break;
			case 12:
				SeeSound = "weapons/sshotl"; PainSound   = "weapons/sshotf";
				DeathSound = "weapons/sshotf"; ActiveSound = "weapons/sshotf";
				AttackSound = "shotguy/attack";
				break;
			default:   // T00 / T01 keep the stock sergeant voice
				SeeSound = "shotguy/sight"; PainSound   = "shotguy/pain";
				DeathSound = "shotguy/death"; ActiveSound = "shotguy/active";
				AttackSound = "shotguy/attack";
				break;
		}
	}

	// CH's ThrustThing/ThrustThingZ hops, as plain velocity. The DECORATE
	// specials take angle in 256ths of a circle and CHP feeds them
	// degrees; expressing the intent directly is both correct and
	// readable.
	private void RS_HopZ(double amount)
	{
		vel.z += amount;
	}
	private void RS_HopDir(double deg, double force)
	{
		vel.xy += (cos(deg), sin(deg)) * force;
	}

	States
	{
	// =================================================================
	// DISPATCHER. The family-wide RS squad roll happens here, once, so
	// no tier has to repeat it. It does NOT replace the tier's attack --
	// the shout goes out and the shotgun still comes up.
	// =================================================================
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_SG_TIER_SQUAD && random(0, 255) < 50)
				RS_CallSquad();
			return TierState("Missile");
		}
		Goto See;

	// ================= T00 COMMON (02_C) =================
	Spawn.T00:
		"SPOS" AB 10 { A_Look(); }
		Loop;
	See.T00:
		"SPOS" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T00:
		"SPOS" E 10 { A_FaceTarget(); }
		"SPOS" F 0 Bright { A_StartSound("shotguy/attack", CHAN_WEAPON); }
		"SPOS" F 10 Bright { A_CustomBulletAttack(22.5, 0, 3, random(1, 5) * 3, "BulletPuff", 0, CBAF_NORANDOM); }
		"SPOS" E 10;
		Goto See;
	Pain.T00:
		"SPOS" G 3;
		"SPOS" G 3 { A_Pain(); }
		Goto See;
	Death.T00:
		"SPOS" H 5;
		"SPOS" I 5 { A_Scream(); }
		"SPOS" J 5 { A_NoBlocking(); }
		"SPOS" K 5;
		"SPOS" L -1;
		Stop;
	XDeath.T00:
		"SPOS" M 5;
		"SPOS" N 5 { A_XScream(); }
		"SPOS" OP 5;
		"SPOS" Q 5 { A_NoBlocking(); }
		"SPOS" RST 5;
		"SPOS" U -1;
		Stop;
	Raise.T00:
		"SPOS" L 5;
		"SPOS" KJIH 5;
		Goto See;

	// ================= T01 GREEN (02_G) =================
	// A seven-bolt plasma-shell fan; the last bolt goes out as it
	// lowers the gun.
	Spawn.T01:
		"SGUG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		"SGUG" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T01:
		"SGUG" E 12 { A_FaceTarget(); }
		"SGUG" F 5 Bright;
		"SGUG" F 0 Bright { A_StartSound("shotguy/attack", CHAN_WEAPON); }
		"SGUG" F 0 Bright { A_SpawnProjectile("RS_SGshot1", 34, -2, 1); }
		"SGUG" F 0 Bright { A_SpawnProjectile("RS_SGshot1", 34, -2, 0); }
		"SGUG" F 0 Bright { A_SpawnProjectile("RS_SGshot1", 34, -2, -1); }
		"SGUG" F 0 Bright { A_SpawnProjectile("RS_SGshot1", 34, -2, 2); }
		"SGUG" F 0 Bright { A_SpawnProjectile("RS_SGshot1", 34, -2, -2); }
		"SGUG" F 0 Bright { A_SpawnProjectile("RS_SGshot1", 34, -2, 3); }
		"SGUG" E 9 { A_SpawnProjectile("RS_SGshot1", 34, -2, -3); }
		Goto See;
	Pain.T01:
		"SGUG" G 3;
		"SGUG" G 3 { A_Pain(); }
		Goto See;
	Death.T01:
		"SGUG" H 5;
		"SGUG" I 5 { A_Scream(); }
		"SGUG" J 5 { A_NoBlocking(); }
		"SGUG" K 5;
		"SGUG" L -1;
		Stop;
	XDeath.T01:
		"SGUG" N 3;
		"SGUG" N 2 { A_XScream(); }
		"SGUG" O 5 { A_NoBlocking(); }
		"SGUG" PQRST 5;
		"SGUG" U -1;
		Stop;
	Raise.T01:
		"SGUG" L 5;
		"SGUG" KJIH 5;
		Goto See;

	// ================= T02 BLUE (02_B) =================
	// Three stacked railgun beams at range; a seeking lance up close.
	Spawn.T02:
		"SGUB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		"SGUB" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T02:
		"SGUB" E 10 { A_FaceTarget(); }
		"SGUB" E 5 A_JumpIfCloser(350, "Missile.T02.Lance");
		"SGUB" F 5;
		"SGUB" F 0 { A_CustomRailgun(random(2, 8), 1, "", "White", RGF_NOPIERCING, 1, 25, "None", 0, 0, 0, 0, 3); }
		"SGUB" F 0 { A_CustomRailgun(random(2, 8), 1, "", "Blue",  RGF_NOPIERCING, 1, 12, "None", 0, 0, 0, 0, 1); }
		"SGUB" F 0 { A_CustomRailgun(random(2, 8), 1, "", "White", RGF_NOPIERCING, 1, 33, "None", 0, 0, 0, 0, 1); }
		"SGUB" E 9;
		Goto See;
	Missile.T02.Lance:
		"SGUB" F 2 Bright { A_FaceTarget(); }
		"SGUB" F 4 Bright { A_SpawnProjectile("RS_SGLance1", 34, -2); }
		"SGUB" E 9;
		Goto See;
	Pain.T02:
		"SGUB" G 3;
		"SGUB" G 3 { A_Pain(); }
		Goto See;
	Death.T02:
		"SGUB" H 5;
		"SGUB" I 5 { A_Scream(); }
		"SGUB" J 5 { A_NoBlocking(); }
		"SGUB" K 5;
		"SGUB" L -1;
		Stop;
	XDeath.T02:
		"SGUB" N 6 { A_XScream(); }
		"SGUB" O 6 { A_NoBlocking(); }
		"SGUB" PQRST 6;
		"SGUB" U -1;
		Stop;
	Raise.T02:
		"SGUB" L 5;
		"SGUB" KJIH 5;
		Goto See;

	// ================= T03 CYAN (02_CY) =================
	// Frost buckshot or an ice shot, and it will not stand still: it
	// bunny-hops sideways out of your line, on sight and on pain.
	// CHP gated the hop behind CallACS("CH_CyanBounce"); the ACS is
	// gone, so the hop is simply always available.
	Spawn.T03:
		"CNSG" AAAAAAAAAABBBBBBBBBB 1 { A_Look(); }
		Loop;
	See.T03:
		TNT1 A 0 A_Jump(232, "See.T03.Peek");
		"CNSG" AAAAAAAABBBBBBBB 1 { A_Chase(); }
		TNT1 A 0 A_Jump(232, "See.T03.Peek", "See.T03.Fast");
		Loop;
	See.T03.Fast:
		"CNSG" AAAABBBB 1 { A_FastChase(); }
		Goto See;
	See.T03.Peek:
		"CNSG" A 0 A_JumpIfInTargetLOS("See.T03.Bounce", 0, JLOSF_CLOSENOJUMP | JLOSF_DEADNOJUMP, 750, 300);
		Goto See;
	See.T03.Bounce:
		"CNSG" A 2 { A_FastChase(); }
		"CNSG" A 1 { RS_HopZ(12); }
		"CNSG" A 1 { RS_HopDir(angle - randompick(130, 180, 230), 12); }
		"CNSG" AA 1;
		"CNSG" A 1 { RS_HopZ(7); }
		"CNSG" A 1 { RS_HopDir(angle, 24); }
		Goto See;
	Missile.T03:
		"CNSG" EEE 4 { A_FaceTarget(); }
		"CNSG" F 0 Bright { A_StartSound("weapons/shotgf", CHAN_WEAPON); }
		TNT1 A 0 A_Jump(128, "Missile.T03.Proj");
		"CNSG" F 0 Bright { A_CustomBulletAttack(4, 4, 1, random(1, 5), "RS_CyanSGPuff", 8000, CBAF_EXPLICITANGLE); }
		"CNSG" F 0 Bright { A_CustomBulletAttack(-4, -4, 1, random(1, 4), "RS_CyanSGPuff", 8000, CBAF_EXPLICITANGLE); }
		"CNSG" F 0 Bright { A_CustomBulletAttack(5, 5, 2, random(1, 2), "RS_CyanSGPuff"); }
		"CNSG" F 0 Bright { A_CustomBulletAttack(4, -4, 1, random(1, 4), "RS_CyanSGPuff", 8000, CBAF_EXPLICITANGLE); }
		"CNSG" F 2 Bright { A_CustomBulletAttack(-4, 4, 1, random(1, 5), "RS_CyanSGPuff", 8000, CBAF_EXPLICITANGLE); }
		"CNSG" EE 2 { A_FaceTarget(); }
		"CNSG" E 2 A_CheckSight("See");
		"CNSG" E 0 A_Jump(102, "Missile");
		Goto See;
	Missile.T03.Proj:
		"CNSG" FFFFF 0 { A_SpawnProjectile("RS_IceZombieShot2", 32, 0, random(-5, 5), 0, random(-2, 2)); }
		"CNSG" F 0 Bright { A_CustomBulletAttack(-2, 2, 1, random(1, 6), "RS_CyanSGPuff", 8000, CBAF_EXPLICITANGLE); }
		"CNSG" F 2 Bright;
		"CNSG" EE 2 { A_FaceTarget(); }
		"CNSG" E 2 A_CheckSight("See");
		"CNSG" E 0 A_Jump(102, "Missile");
		Goto See;
	Missile.T03.Hop:
		"CNSG" G 2;
		"CNSG" E 1 { RS_HopZ(3); }
		"CNSG" E 1 { RS_HopDir(angle + randompick(90, 180, 270), 32); }
		"CNSG" A 4;
		Goto See;
	Pain.T03:
		"CNSG" G 4;
		"CNSG" G 4 { A_Pain(); }
		"CNSG" G 0 A_Jump(96, "Missile.T03.Hop");
		Goto See;
	// Cyan has no XDeath and no Raise in CHP OR in CH's CyanSG2 -- it is
	// an ice-death monster and always shatters.
	Death.T03:
		"CNSG" H 5;
		"CNSG" I 5 { A_Scream(); }
		"CNSG" J 5;
		"CNSG" K 5 { A_NoBlocking(false); }
		TNT1 A 0 { A_StartSound("misc/icebreak", CHAN_BODY); A_IceGuyDie(); }
		"CNSG" L -1;
		Stop;

	// ================= T04 PURPLE (02_P) =================
	// Hazmat sergeant. Outside 300 it hisses and charges; inside, three
	// purple fire shells, then refire or break off.
	Spawn.T04:
		"HMZP" AB 10 { A_Look(); }
		Loop;
	See.T04:
		"HMZP" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T04:
		"HMZP" E 2 A_JumpIfCloser(300, "Missile.T04.Fire1");
		"HMZP" E 2 A_Jump(255, "Missile.T04.Close");
		Goto See;
	Missile.T04.Close:
		"HMZP" A 0 { A_StartSound("gas/gas1", CHAN_BODY); }
		"HMZP" AB 3 { A_SkullAttack(12); }
		Goto See;
	Missile.T04.Fire1:
		"HMZP" E 2 A_JumpIfCloser(300, "Missile.T04.Fire2");
		"HMZP" E 2 A_Jump(255, "See");
		Goto See;
	Missile.T04.Fire2:
		"HMZP" E 3 { A_FaceTarget(); }
		"HMZP" F 3 Bright { A_SpawnProjectile("RS_PurpFire2", 42, 1, random(-1, 1)); }
		"HMZP" E 3 { A_FaceTarget(); }
		"HMZP" F 3 Bright { A_SpawnProjectile("RS_PurpFire2", 42, 1, random(-1, 1)); }
		"HMZP" E 3 { A_FaceTarget(); }
		"HMZP" F 3 Bright { A_SpawnProjectile("RS_PurpFire2", 42, 1, random(-1, 1)); }
		"HMZP" E 2 A_MonsterRefire(180, "See");
		Goto Missile.T04.Fire1;
	Pain.T04:
		"HMZP" G 3;
		"HMZP" G 3 { A_Pain(); }
		Goto See;
	Death.T04:
		"HMZP" H 5;
		"HMZP" I 5 { A_Scream(); }
		"HMZP" J 5 { A_NoBlocking(); }
		"HMZP" K 5;
		"HMZP" L -1;
		Stop;
	// CHP gibs the purple one into the SGUP body. SGUP ships N..U only;
	// CHP's leading zero-tic "SGUP M 0" has no art anywhere and is
	// dropped rather than faked.
	XDeath.T04:
		"SGUP" N 5 { A_XScream(); }
		"SGUP" O 5 { A_NoBlocking(); }
		"SGUP" PQRST 5;
		"SGUP" U -1;
		Stop;
	Raise.T04:
		"HMZP" L 5;
		"HMZP" KJIH 5;
		Goto See;

	// ================= T05 YELLOW (02_Y) =================
	// Assault shotgun: four three-pellet volleys per press, a hard cap
	// of sixteen before it has to eject the mag and reload -- and it is
	// NOPAIN through the whole reload, so the window is real.
	Spawn.T05:
		"ASGZ" AB 10 { A_Look(); }
		Loop;
	See.T05:
		"ASGZ" AABBCCDD 4 { A_Chase(); }
		"ASGZ" A 0 A_Jump(88, "See.T05.Dodge");
		Loop;
	See.T05.Dodge:
		"ASGZ" AABBCCDD 4 { A_FastChase(); }
		"ASGZ" A 0 A_Jump(88, "See");
		Loop;
	Missile.T05:
		TNT1 A 0 { if (rsAsgAmmo >= 16) return ResolveState("Missile.T05.Reload"); return ResolveState(null); }
		TNT1 A 0 { A_Stop(); }
		"ASGZ" E 5 { A_FaceTarget(); }
		TNT1 A 0 { rsAsgAmmo++; }
		"ASGZ" F 5 Bright { A_CustomBulletAttack(5, 4, 3, 3, "BulletPuff", 0); }
		"ASGZ" E 7 { if (rsAsgAmmo >= 16) return ResolveState("Missile.T05.Reload"); return ResolveState(null); }
		TNT1 A 0 { A_StartSound("asgguy/asgld1", CHAN_WEAPON); }
		"ASGZ" E 5 A_CPosRefire();
		TNT1 A 0 { rsAsgAmmo++; }
		"ASGZ" F 5 Bright { A_CustomBulletAttack(5, 4, 3, 3, "BulletPuff", 0); }
		"ASGZ" E 7 { if (rsAsgAmmo >= 16) return ResolveState("Missile.T05.Reload"); return ResolveState(null); }
		TNT1 A 0 { A_StartSound("asgguy/asgld1", CHAN_WEAPON); }
		"ASGZ" E 5 A_CPosRefire();
		TNT1 A 0 { rsAsgAmmo++; }
		"ASGZ" F 5 Bright { A_CustomBulletAttack(5, 4, 3, 3, "BulletPuff", 0); }
		"ASGZ" E 7 { if (rsAsgAmmo >= 16) return ResolveState("Missile.T05.Reload"); return ResolveState(null); }
		TNT1 A 0 { A_StartSound("asgguy/asgld1", CHAN_WEAPON); }
		"ASGZ" E 5 A_CPosRefire();
		TNT1 A 0 { rsAsgAmmo++; }
		"ASGZ" F 5 Bright { A_CustomBulletAttack(5, 4, 3, 3, "BulletPuff", 0); }
		"ASGZ" E 7 { A_StartSound("asgguy/asgld1", CHAN_WEAPON); }
		TNT1 A 0 { if (rsAsgAmmo >= 16) return ResolveState("Missile.T05.Reload"); return ResolveState(null); }
		Goto See;
	Missile.T05.Reload:
		TNT1 A 0 { bNOPAIN = true; }
		TNT1 A 0 { A_StartSound("asgguy/asgout", CHAN_WEAPON); }
		"ASGZ" E 60 { rsAsgAmmo = 0; }
		"ASGZ" E 8 { A_StartSound("asgguy/asgin", CHAN_WEAPON); }
		TNT1 A 0 { bNOPAIN = false; }
		Goto See;
	Pain.T05:
		"ASGZ" G 3;
		"ASGZ" G 3 { A_Pain(); }
		"ASGZ" G 3 A_Jump(88, "See.T05.Dodge");
		Goto See;
	Death.T05:
		"ASGZ" H 5;
		"ASGZ" I 5 { A_Scream(); }
		"ASGZ" J 5 { A_NoBlocking(); }
		"ASGZ" KLM 5;
		"ASGZ" N -1;
		Stop;
	XDeath.T05:
		"ASGZ" O 5;
		"ASGZ" P 5 { A_XScream(); }
		"ASGZ" Q 5 { A_NoBlocking(); }
		"ASGZ" RSTUV 5;
		"ASGZ" W -1;
		Stop;
	Raise.T05:
		"ASGZ" NMLKJIH 5;
		Goto See;

	// ================= T06 ABYSS (02_A) =================
	// The abyss chief. It trails abyss splash as it walks. Beyond 800
	// it just spits three abyss shots; inside, it runs the leap routine:
	// shoot, seed a wide field of splash, kick backward, shoot again --
	// three times. First time it takes pain it goes permanently NOPAIN
	// and speeds up to 21.
	Spawn.T06:
		"ABSG" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"ABSG" AABB 3 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		"ABSG" CCDD 3 { A_Chase(); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(5, 32)); }
		Loop;
	Missile.T06:
		"ABSG" E 1;
		"ABSG" E 1 A_JumpIfCloser(800, "Missile.T06.Jumper");
		"ABSG" E 5 { A_FaceTarget(); }
		"ABSG" FFF 2 Bright { A_SpawnProjectile("RS_AbyssZshotCH2", 36, 3, random(-2, 2)); }
		Goto See;
	Missile.T06.Jumper:
		"ABSG" E 5 { A_FaceTarget(); }
		"ABSG" F 5 Bright { A_CustomBulletAttack(6, 7, random(2, 4), 1, "BulletPuff", 0); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		"ABSG" F 1 A_CheckSight("See");
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 328), random(-178, 178), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"ABSG" E 0 { A_FaceTarget(); }
		"ABSG" E 1 { RS_HopZ(3); }
		"ABSG" E 1 { RS_HopDir(angle + 180, 32); }
		"ABSG" E 5 { A_FaceTarget(); }
		"ABSG" F 5 Bright { A_CustomBulletAttack(6, 7, random(2, 4), 2, "BulletPuff", 0); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		"ABSG" F 1 A_CheckSight("See");
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 328), random(-178, 178), random(6, 16), 0, 0, 2, 0, SXF_NOCHECKPOSITION); }
		"ABSG" E 0 { A_FaceTarget(); }
		"ABSG" E 1 { RS_HopZ(3); }
		"ABSG" E 1 { RS_HopDir(angle - 180, 32); }
		"ABSG" E 5 { A_FaceTarget(); }
		"ABSG" F 5 Bright { A_CustomBulletAttack(6, 7, random(2, 4), 2, "BulletPuff", 0); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 56, 3, random(-15, 15), CMF_OFFSETPITCH, random(-25, -5)); }
		Goto See;
	Pain.T06:
		"ABSG" G 3;
		"ABSG" G 6 { A_Pain(); }
		// CHP's PEP: hurt it once and it stops flinching forever.
		TNT1 A 0 { bNOPAIN = true; A_SetSpeed(21); }
		Goto See;
	Death.T06:
		"ABSG" H 5;
		"ABSG" I 5 { A_Scream(); }
		"ABSG" J 5 { A_NoBlocking(); }
		"ABSG" KLM 5;
		"ABSG" N -1;
		Stop;
	XDeath.T06:
		"ABSG" O 5;
		"ABSG" P 5 { A_XScream(); }
		"ABSG" Q 5 { A_NoBlocking(); }
		"ABSG" RSTUV 5;
		"ABSG" W -1;
		Stop;
	Raise.T06:
		"ABSG" NMLKJIH 5;
		Goto See;

	// ================= T07 FIREBLU (02_F) =================
	// One press, five fireblu shells on five different offsets.
	Spawn.T07:
		"SGUF" A 10 { A_Look(); }
		Loop;
	See.T07:
		"SGUF" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T07:
		"SGUF" E 10 Bright { A_FaceTarget(); }
		"SGUF" F 0 Bright { A_SpawnProjectile("RS_FireSGguy", 34, -2, 0); }
		"SGUF" F 0 Bright { A_SpawnProjectile("RS_FireSGguy", 34, 6, 8); }
		"SGUF" F 0 Bright { A_SpawnProjectile("RS_FireSGguy", 34, 9, 13); }
		"SGUF" F 0 Bright { A_SpawnProjectile("RS_FireSGguy", 34, -13, -13); }
		"SGUF" F 8 Bright { A_SpawnProjectile("RS_FireSGguy", 34, -10, -8); }
		"SGUF" E 8 Bright;
		Goto See;
	Pain.T07:
		"SGUF" G 3;
		"SGUF" G 3 { A_Pain(); }
		"SGUF" G 3 { bNOPAIN = true; }
		Goto See;
	Death.T07:
		"SGUF" H 7;
		"SGUF" I 7 { A_Scream(); }
		"SGUF" J 7 { A_NoBlocking(); }
		"SGUF" K 7;
		"SGUF" L 7;
		"SGUF" M 7;
		"SGUF" N -1;
		Stop;
	XDeath.T07:
		"SGUF" O 5;
		"SGUF" P 5 { A_XScream(); }
		"SGUF" Q 5 { A_NoBlocking(); }
		"SGUF" RS 5;
		"SGUF" T -1;
		Stop;
	Raise.T07:
		"SGUF" NMLKJIH 5;
		Goto See;

	// ================= T08 BROWN (02_BR) =================
	// The mud guy. Beyond 500 it hisses and charges; inside, twenty mud
	// pellets in one wide dirty cone.
	Spawn.T08:
		"QSZM" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"QSZM" AABB 3 { A_Chase(); }
		"QSZM" A 0 { A_SpawnItemEx("RS_Drt1", 0, 0, 0, 5, 0, 3, random(0, 360), 0, 32); }
		"QSZM" CCDD 3 { A_Chase(); }
		"QSZM" A 0 { A_SpawnItemEx("RS_Drt2", 0, 0, 0, 5, 0, 3, random(0, 360), 0, 32); }
		Loop;
	Missile.T08:
		"QSZM" E 2 A_JumpIfCloser(500, "Missile.T08.Fire1");
		"QSZM" E 2 A_Jump(255, "Missile.T08.Close");
		Goto See;
	Missile.T08.Close:
		"QSZM" A 0 { A_StartSound("gas/gas1", CHAN_BODY); }
		"QSZM" AA 0 { A_SpawnItemEx("RS_Drt1", 0, 0, 0, 5, 0, 3, random(0, 360), 0, 32); }
		"QSZM" AA 0 { A_SpawnItemEx("RS_Drt2", 0, 0, 0, 5, 0, 3, random(0, 360), 0, 32); }
		"QSZM" AA 0 { A_SpawnItemEx("RS_Drt3", 0, 0, 0, 5, 0, 3, random(0, 360), 0, 32); }
		"QSZM" AB 3 { A_SkullAttack(24); }
		Goto See;
	Missile.T08.Fire1:
		"QSZM" E 10 { A_FaceTarget(); }
		"QSZM" F 4 Bright { A_StartSound("SSGUNER/SSG", CHAN_WEAPON); }
		"QSZM" FFFFFFFFFF 0 Bright { A_SpawnProjectile("RS_BrownSGshot", 32, random(-5, 5), random(-15, 15), CMF_OFFSETPITCH, random(-9, 1)); }
		"QSZM" FFFFFFFFFF 0 Bright { A_SpawnProjectile("RS_BrownSGshot", 32, random(-5, 5), random(-15, 15), CMF_OFFSETPITCH, random(-1, 9)); }
		"QSZM" F 4 Bright;
		"QSZM" E 2 { A_FaceTarget(); }
		Goto See;
	Pain.T08:
		"QSZM" G 3;
		"QSZM" G 3 { A_Pain(); }
		Goto See;
	Death.T08:
		"QSZM" H 5;
		"QSZM" I 5 { A_Scream(); }
		"QSZM" J 5 { A_NoBlocking(); }
		"QSZM" K 5;
		"QSZM" L -1;
		Stop;
	XDeath.T08:
		"QSZM" N 5;
		"QSZM" O 5 { A_NoBlocking(); }
		"QSZM" PQRST 5;
		"QSZM" U -1;
		Stop;
	Raise.T08:
		"QSZM" L 5;
		"QSZM" KJIH 5;
		Goto See;

	// ================= T09 GRAY (02_GY) =================
	// The sniper. Inside 800 it takes one hard, dead-accurate shot.
	// Outside, it digs in ONCE -- shrinks flat, drops to speed 2, goes
	// NOPAIN -- and from then on it is a turret that tracks and fires on
	// a long, deliberate rhythm.
	Spawn.T09:
		"GRSH" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"GRSH" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T09:
		"GRSH" E 2 A_JumpIfCloser(800, "Missile.T09.Fire1");
		"GRSH" E 2 A_Jump(255, "Missile.T09.DigIn");
		Goto See;
	Missile.T09.Fire1:
		"GRSH" E 8 { A_FaceTarget(); }
		"GRSH" F 8 Bright { A_CustomBulletAttack(1, 0, 1, random(5, 20), "BulletPuff", 16000); }
		Goto See;
	Missile.T09.DigIn:
		"GRSH" E 0 { if (rsSniperReady >= 1) return ResolveState("Missile.T09.Turret"); return ResolveState(null); }
		"GRSH" E 8 { A_FaceTarget(); }
		"GRSH" E 3 { A_SetScale(1.0, 0.7); }
		"GRSH" E 3 { A_SetScale(1.0, 0.5); }
		"GRSH" E 3 { A_SetScale(1.0, 0.3); }
		"GRSH" E 1 { A_SetSpeed(2); }
		"GRSH" E 1 { bNOPAIN = true; }
		"GRSH" E 3 { rsSniperReady++; }
		Goto See;
	Missile.T09.Turret:
		"GRSH" EE 6 { A_FaceTarget(); }
		"GRSH" EE 5 { A_FaceTarget(); }
		"GRSH" EE 4 { A_FaceTarget(); }
		"GRSH" EEE 3 { A_FaceTarget(); }
		"GRSH" F 6 Bright { A_CustomBulletAttack(1, 0, 1, random(5, 20), "BulletPuff", 16000); }
		"GRSH" EEEE 6 { A_FaceTarget(); }
		"GRSH" E 2 A_MonsterRefire(180, "See");
		Goto Missile.T09.Turret;
	Pain.T09:
		"GRSH" G 3;
		"GRSH" G 3 { A_Pain(); }
		Goto See;
	Death.T09:
		"GRSH" H 5 { A_SetScale(1.0, 1.0); }
		"GRSH" I 5 { A_Scream(); }
		"GRSH" JK 5 { A_NoBlocking(); }
		"GRSH" L -1;
		Stop;
	// GRSH ships no M or N frame; CHP's gib run is V W X P Q R S T U.
	XDeath.T09:
		TNT1 A 0 { A_SetScale(1.0, 1.0); }
		"GRSH" V 5 { A_XScream(); }
		"GRSH" W 5 { A_NoBlocking(); }
		"GRSH" XPQRST 5;
		"GRSH" U -1;
		Stop;
	Raise.T09:
		"GRSH" LKJIH 5;
		Goto See;

	// ================= T10 RED (02_R) =================
	// The RNG sergeant. Beyond 650 it lobs five red mess bombs on wildly
	// random offsets. Inside, a fifteen-to-twenty pellet spray -- and
	// then the gun JAMS, so every second close-range attack is it
	// swearing at a stuck shell instead of shooting.
	Spawn.T10:
		"GPOS" A 10 { A_Look(); }
		Loop;
	See.T10:
		"GPOS" AABBCCDD 4 { A_Chase(); }
		Loop;
	Missile.T10:
		"GPOS" E 0 A_JumpIfCloser(650, "Missile.T10.Shotgunned");
		"GPOS" E 10 Bright { A_FaceTarget(); }
		"GPOS" G 0 { A_SpawnProjectile("RS_RedMessImp3", 42, 12, 0); }
		"GPOS" G 0 { A_SpawnProjectile("RS_RedMessImp3", 32, random(4, 8), 0); }
		"GPOS" G 0 { A_SpawnProjectile("RS_RedMessImp3", 22, random(14, 26), 0); }
		"GPOS" G 0 { A_SpawnProjectile("RS_RedMessImp3", 22, 12, 0); }
		"GPOS" G 0 { A_SpawnProjectile("RS_RedMessImp3", 42, random(6, 18), 0); }
		"GPOS" E 8 Bright;
		Goto See;
	Missile.T10.Shotgunned:
		"GPOS" E 5 Bright { A_FaceTarget(); }
		TNT1 A 0 { if (rsShotgunJam >= 1) return ResolveState("Missile.T10.Jammed"); return ResolveState(null); }
		"GPOS" E 5 Bright { A_FaceTarget(); }
		"GPOS" F 8 Bright { A_CustomBulletAttack(11.2, 7.1, random(15, 20), random(1, 3), "BulletPuff"); }
		"GPOS" E 8 Bright;
		TNT1 A 0 { rsShotgunJam = 1; }
		Goto See;
	Missile.T10.Jammed:
		"GPOS" E 8 Bright;
		"GPOS" G 2 { A_StartSound("weapons/sshotl", CHAN_WEAPON); }
		"GPOS" G 10 { rsShotgunJam = 0; }
		Goto See;
	Pain.T10:
		"GPOS" G 3;
		"GPOS" G 3 { A_Pain(); }
		"GPOS" G 3 { bNOPAIN = true; }
		Goto See;
	Death.T10:
		"GPOS" H 7;
		"GPOS" I 7 { A_Scream(); }
		"GPOS" J 7 { A_NoBlocking(); }
		"GPOS" KLM 7;
		"GPOS" N -1;
		Stop;
	XDeath.T10:
		"GPOS" O 5;
		"GPOS" P 5 { A_XScream(); }
		"GPOS" Q 5 { A_NoBlocking(); }
		"GPOS" RS 5;
		"GPOS" T -1;
		Stop;
	Raise.T10:
		"GPOS" NMLKJIH 5;
		Goto See;

	// ================= T11 BLACK -- CREW COMMANDER (02_K) =================
	// Four modes. Inside 500 it fires detonating buckshot and sometimes
	// follows with a gas grenade. Otherwise it rolls between painting a
	// target for an ORBITAL AIRSTRIKE, a long-range sniper mark that
	// detonates on the victim, and calling in the crew. It spawns with
	// two bodyguards already at its shoulders.
	Spawn.T11:
		TNT1 A 0 NoDelay
		{
			if (rsEscortDone == 0)
			{
				rsEscortDone = 1;
				SummonMinion("RS_Shotgunner", -4, 40.0);
				SummonMinion("RS_Shotgunner", -4, 40.0);
			}
		}
		"ZSP2" AAAAAAAAAABBBBBBBBBB 1 { A_Look(); }
		Loop;
	See.T11:
		"ZSP2" ABCD 3 { A_Chase(); }
		"ZSP2" A 0 A_Jump(64, "See.T11.Odd");
		Loop;
	See.T11.Odd:
		"ZSP2" A 2 { A_Wander(); }
		"ZSP2" BC 3 { A_FastChase(); }
		"ZSP2" D 2 { A_Wander(); }
		Goto See;
	Missile.T11:
		"ZSP2" A 0 A_JumpIfCloser(500, "Missile.T11.Shotgunned");
		"ZSP2" A 0 A_Jump(128, "Missile.T11.AirStrike", "Missile.T11.Snipe");
		"ZSP2" A 0 A_Jump(255, "Missile.T11.Summon", "Missile.T11.AirStrike", "Missile.T11.Snipe");
		Goto See;
	Missile.T11.Summon:
		"ZSP2" G 3 Bright { A_StartSound("ZSpecOps/Sight", 7, 0, 1.0, ATTN_NONE); }
		"ZSP2" G 3 Bright { A_StartSound("ZSpecOps/Sight", 7, 0, 1.0, ATTN_NONE); }
		"ZSP2" G 3 Bright { A_StartSound("ZSpecOps/Sight", 7, 0, 1.0, ATTN_NONE); }
		"ZSP2" A 9 Bright { A_FaceTarget(); }
		"ZSP2" A 0 Bright { SummonMinion("RS_Shotgunner", -4, 48.0); }
		"ZSP2" A 1 Bright { SummonMinion("RS_Shotgunner", -4, 48.0); }
		"ZSP2" A 1 Bright { SummonMinion("RS_Shotgunner", -4, 64.0); }
		"ZSP2" A 1 Bright { SummonMinion("RS_Shotgunner", -4, 64.0); }
		Goto See;
	Missile.T11.Shotgunned:
		"ZSP2" EEE 4 { A_FaceTarget(); }
		"ZSP2" F 0 Bright { A_StartSound("weapons/shotgf", CHAN_WEAPON); }
		"ZSP2" F 2 Bright { A_CustomBulletAttack(random(1, 12), random(1, 12), random(3, 9), random(1, 8), "RS_DetoPuffCG"); }
		"ZSP2" F 0 Bright A_Jump(64, "Missile.T11.Nadetoss");
		"ZSP2" EE 2 { A_FaceTarget(); }
		"ZSP2" E 2 A_CheckSight("See");
		"ZSP2" E 0 A_JumpIfCloser(450, "Missile");
		Goto See;
	Missile.T11.Snipe:
		"ZSP2" EEE 8 Bright { A_FaceTarget(); }
		"ZSP2" E 1 A_CheckSight("See");
		"ZSP2" E 5 Bright { A_StartSound("ZSpecOps/Sight", 7, 0, 1.0, ATTN_NONE); }
		"ZSP2" E 1 A_CheckSight("See");
		"ZSP2" E 1 { A_FaceTarget(); }
		"ZSP2" F 0 Bright { A_StartSound("weapons/shotgf", CHAN_WEAPON); }
		"ZSP2" F 4 Bright { A_VileTarget("RS_DetoPuffCG2"); }
		Goto See;
	Missile.T11.AirStrike:
		"ZSP2" GG 6 Bright { A_FaceTarget(); }
		"ZSP2" E 8 Bright { A_VileTarget("RS_CHBSTarget"); }
		"ZSP2" EF 5 Bright;
		"ZSP2" F 4 Bright { A_SpawnProjectile("RS_AirStrikeCHBS", 64, 0, 1); }
		"ZSP2" E 2;
		Goto See;
	Missile.T11.Nadetoss:
		"ZSP2" E 8 { A_FaceTarget(); }
		"ZSP2" E 2 { A_StartSound("fire/fire4", CHAN_WEAPON); }
		"ZSP2" E 2 { A_SpawnProjectile("RS_SGGasNade", 48, 0, random(-3, 3), 0, random(3, 12)); }
		"ZSP2" E 2;
		Goto See;
	Pain.T11:
		"ZSP2" G 4;
		"ZSP2" G 4 { A_Pain(); }
		"ZSP2" G 0 A_Jump(96, "See");
		Goto See.T11.Odd;
	// No XDeath and no Raise -- CHP's BlackSG3 has neither, and neither
	// does CH's BlackSG3 parent.
	Death.T11:
		"ZSP2" H 5;
		"ZSP2" I 5 { A_Scream(); }
		"ZSP2" J 5;
		"ZSP2" K 5 { A_NoBlocking(); }
		"ZSP2" L -1;
		Stop;

	// ================= T12 WHITE -- BENELLUS (02_W) =================
	// God of Shotguns. Floats, and rolls between three things: the SG
	// storm (huge randomised pellet counts on a refire loop), GIFTS (a
	// four-mine bounce spread), and the PUNISHER, which hangs two
	// enormous shotguns either side of you and fires them.
	Spawn.T12:
		"BENE" A 0 { A_SetSize(30, 64, 1); }
		"BENE" ABCD 5 { A_Look(); }
		Loop;
	See.T12:
		"BENE" A 0 { A_SetSize(30, 64, 1); }
		"BENE" ABCD 2 { A_Chase(); }
		"BENE" A 0 A_Jump(128, "See.T12.Fast");
		Loop;
	See.T12.Fast:
		"BENE" ABCD 2 { A_FastChase(); }
		"BENE" A 0 A_Jump(128, "See.T12.Fast");
		Loop;
	Missile.T12:
		"BENE" A 0 A_Jump(256, "Missile.T12.SG", "Missile.T12.Gifts", "Missile.T12.Punisher");
		Goto See;
	Missile.T12.Gifts:
		"BENE" A 8 Bright { A_StartSound("DSDBLOAD", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"BENE" A 8 Bright { A_StartSound("DSDBCLS", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"BENE" ABCD 1 Bright { A_SpawnProjectile("RS_MineShotgun", random(20, 60), random(-15, 15), random(-20, 20), 0); }
		Goto See;
	Missile.T12.Punisher:
		"BENE" A 10 Bright { A_StartSound("DSDSHTGN", 7, 0, 1.0, ATTN_NONE); }
		"BENE" A 8 Bright;
		"BENE" K 2 Bright { A_VileTarget("RS_ShotgunpunisherNerfed"); }
		Goto See;
	Missile.T12.SG:
		"BENE" A 2 { A_FaceTarget(); }
		"BENE" AAA 7 Bright { A_StartSound("DSSGCOCK", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"BENE" KBJCGDF 6 Bright { A_CustomBulletAttack(random(5, 180), random(0, 50), random(5, 30), random(1, 3), "BulletPuff", 0); }
		"BENE" K 0 Bright A_CheckSight("See");
		"BENE" K 0 Bright A_CheckRange(1250, "See");
		"BENE" KB 2 Bright { A_CustomBulletAttack(22.5, 0, random(5, 18), random(1, 5), "BulletPuff", 0); }
		"BENE" EAHBICLD 6 Bright { A_CustomBulletAttack(random(5, 180), random(0, 50), random(5, 30), random(1, 3), "BulletPuff", 0); }
		"BENE" A 1 A_MonsterRefire(128, "See");
		Goto Missile.T12.SG;
	Pain.T12:
		"BENE" D 4;
		"BENE" D 5 { A_Pain(); }
		"BENE" D 2 A_Jump(128, "Missile.T12.Gifts");
		Goto See.T12.Fast;
	// No XDeath and no Raise -- CHP's WhiteSG2 has neither, and neither
	// does CH's WhiteSG2 parent. It leaves an armoury behind instead of
	// a corpse.
	Death.T12:
		"BENE" AAAAAA 1 { A_Scream(); }
		"BENE" A 8 { A_NoBlocking(); }
		"BENE" AAABCDDDD 6 { A_SpawnProjectile("RS_HKRedDeath", random(0, 80), random(-30, 50), 0, CMF_AIMOFFSET, -10); }
		"BENE" DDDDDDDDDDDDDDDDDDDD 1 { A_SpawnItemEx("Shotgun", random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80)); }
		"BENE" D 8 { A_Quake(40, 60, 0, 40); }
		"BENE" DDDDDDDDDDDDDDDDDDDD 1 { A_SpawnItemEx("Shotgun", random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80), random(-80, 80)); }
		"BENE" D 6 { A_SetTranslucent(0.75); }
		"BENE" D 6 { A_SetTranslucent(0.5); }
		"BENE" D 6 { A_SetTranslucent(0.25); }
		Stop;
	}
}
