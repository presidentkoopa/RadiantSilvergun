// =====================================================================
// RS_CG_C0001 -- Former Captain (CH "CommonCGuy")
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt:995
// ACTOR:   CommonCGuy : ChaingunGuy
// ROLE:    C -- common / vanilla-derived
//
// THIS IS A CH IMPORT, NOT A CHP ONE. Every property below is CH's own.
// Where CHP later overrides a value it is NOT applied here -- CHP is a
// separate layer and lands on top of this one, later, deliberately.
//
// CH states no Health/Speed/PainChance for this actor; it inherits
// vanilla ChaingunGuy (70 / 8 / 170). That is not an omission on our
// part -- an unstated property in CH means "vanilla", and writing a
// number here would invent one.
//
// WHAT WAS LEFT OUT OF CH'S ORIGINAL, AND WHY. Each of these is a call,
// not an oversight; say the word and any of them comes back.
//   * ColorTierIconCH  -- CH sprinkles this spawn into Spawn/See/Missile/
//                         Pain as a floating tier marker. Not in our
//                         tree, and RS_HealthBars already shows tier
//                         over the monster's head.
//   * Tickles / CHBoner / ThePlanBoner -- a joke death branch keyed to a
//                         CH-only inventory token that nothing here
//                         grants, so the branch is unreachable by
//                         construction.
//   * CHRandom_GibGenerator + A_SpawnParticle confetti in XDeath --
//                         CH-only gib actors, absent from our tree.
//
// WHAT WAS KEPT THAT EARLIER PASSES DROPPED:
//   * Grow / GrowRaisin. This is CH's OWN promotion ladder -- a common
//     captain that gets resurrected while holding GrowRaisin comes back
//     as the GREEN one. It is real CH mechanics, not cruft, and every
//     previous import deleted it. RS_CG_GrowRaisin carries it.
//   * Pain.AbyssPE -- the Abyss Pain Elemental's conversion attack turns
//     this into the abyss captain. Retargeted to RS_CG_T0008_Abyss.
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

// `replaces ChaingunGuy` sits on the COMMON captain deliberately: it is
// CH's own most-likely roll (weight 640 of 1748 in Colourset12) and it is
// the dial at position zero. It is NOT a spawner and does not pick a
// colour -- every map chaingunner becomes this one until the tier dial
// drives the choice. Moved here from RS_Chaingunner.zs, which carried it
// until 2026-08-05; only one actor may replace a given class.
class RS_CG_C0001 : RS_MonsterMaster replaces ChaingunGuy
{
	Default
	{
		// CH states `Game Doom`; ZScript has no Game actor property (DECORATE
		// only), so it is recorded here rather than declared. Not a loss --
		// this mod is Doom-only.
		Species "CGuy";
		Tag "Former Captain";
		DamageFactor "Exorcist", 3.0;
		DamageFactor "DIMp", 0;
		PainChance "DIMp", 0;
		Monster;
		+AVOIDMELEE
		+DONTHARMSPECIES
		// Vanilla ChaingunGuy's own numbers -- CH states none, so these
		// ARE CH's values. Kept explicit so the differ can read them.
		Health 70;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 170;
		SeeSound "chainguy/sight";
		PainSound "chainguy/pain";
		DeathSound "chainguy/death";
		ActiveSound "chainguy/active";
		AttackSound "chainguy/attack";
		Obituary "$OB_CHAINGUY";
		DropItem "Clip";
	}

	// One class, one tier -- the switch is gone. The row still exists
	// because RS_HealthBars, RS_Score, RS_Bits, RS_Elites and the debug
	// menu all read it off RS_MonsterMaster.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		if (t != 0) return false;
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 170; r.dmgMul = 1.0;
		r.species = "CGuy";
		// r.flags IS NOT OPTIONAL. RS_ApplyTierProperties assigns the flag
		// set ABSOLUTELY -- `bAVOIDMELEE = (f & RS_TF_AVOIDMELEE) != 0;`
		// -- and its own comment says the row is "a complete statement of
		// the tier, not a delta". Leaving this 0 runs `= false` at
		// PostBeginPlay and SILENTLY STRIPS the +AVOIDMELEE and
		// +DONTHARMSPECIES declared in Default above. Two independent
		// passes caught this on this file; it shipped broken.
		r.flags = RS_TF_AVOIDMELEE | RS_TF_DONTHARMSPECIES;
		return true;
	}

	override int MaxTier() { return 0; }

	// =================================================================
	// THE DIAL FOR FAMILY 04.
	//
	// This class carries `replaces ChaingunGuy`, so every chaingunner a
	// map places starts here and then becomes one of the fourteen. The
	// weights are CH's own, from Colourset12 (Chaingunners.txt:1-16) --
	// nothing here is invented. Total 1748, so CH's white boss really is
	// 1 in 1748 when every band is enabled.
	//
	// NO COLOUR NAMES. The entries are tier IDs and the gates are ROLE
	// BANDS, not colours. CH gates seven individual colours (CH_Cyan,
	// CH_Brown, CH_Gray, CH_Abyss, CH_FireBLU, CH_BlackBoss,
	// CH_WhiteBoss); those seven collapse cleanly into the three bands
	// this project already uses, and a band means the same thing in all
	// seventeen families where a colour does not.
	//
	// DIVERGENCE FROM CH, STATED: CH ships its five optional tiers OFF
	// (every one of those cvars defaults to 1 = "Off" in CH's own
	// CVARINFO, and its menu calls them "optional ... for extra
	// challenge"). We default them ON. Importing fourteen creatures and
	// showing six is the wrong default for this project; the switch is
	// right there if you want CH's.
	//
	// X0001 IS DELIBERATELY ABSENT from this table. CH does not put its
	// EX boss in Colourset12 at all -- CH_EXBoss is a separate
	// substitution roll (its menu offers Classic 10% / 50-50 / Always /
	// Never). Putting it here would invent a spawn path CH does not have.
	// =================================================================
	// Switch chains, not array literals -- CLAUDE.md: `static const TYPE
	// name[] = {...}` does not reliably resolve on this engine build, and
	// that has been rediscovered three separate times.
	override int SpawnRosterCount() { return 13; }

	override string SpawnRosterPick(int i)
	{
		switch (i)
		{
			case 0:  return "RS_CG_C0001";   // CommonCGuy    Colourset12:3
			case 1:  return "RS_CG_T0001";   // GreenCGuy               :4
			case 2:  return "RS_CG_T0002";   // BlueCGuy                :6
			case 3:  return "RS_CG_T0004";   // PurpleCGuy              :7
			case 4:  return "RS_CG_T0005";   // YellowCGuy              :12
			case 5:  return "RS_CG_T0010";   // RedCGuy                 :14
			case 6:  return "RS_CG_T0003";   // CyanCGuy                :5
			case 7:  return "RS_CG_T0007";   // GrayCGuy                :8
			case 8:  return "RS_CG_T0006";   // BrownCGuy               :9
			case 9:  return "RS_CG_T0008";   // AbyssCGuy               :10
			case 10: return "RS_CG_T0009";   // FireBLUCguy             :13
			case 11: return "RS_CG_B0001";   // BlackCGuy               :15
			case 12: return "RS_CG_B0002";   // WhiteCGuy               :16
		}
		return "";
	}

	override int SpawnRosterWeight(int i)
	{
		// Indices 6..10 are CH's optional band, 11..12 the boss band.
		if (i >= 11) return RS_MonOpt("rs_mon_band_boss", true)
		                  ? (i == 11 ? 2 : 1) : 0;
		if (i >= 6 && !RS_MonOpt("rs_mon_band_optional", true)) return 0;

		switch (i)
		{
			case 0:  return 640;
			case 1:  return 460;
			case 2:  return 200;
			case 3:  return 100;
			case 4:  return 60;
			case 5:  return 35;
			case 6:  return 130;
			case 7:  return 35;
			case 8:  return 35;
			case 9:  return 30;
			case 10: return 20;
		}
		return 0;
	}

	States
	{
	Spawn:
		CPOS AB 10 A_Look;
		Loop;
	See:
		CPOS AABB 3 A_Chase;
		CPOS CCDD 3 A_Chase;
		Loop;
	Missile:
		CPOS E 10 A_FaceTarget;
		CPOS FE 4 Bright A_CPosAttack;
		CPOS F 1 A_CPosRefire;
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
	XDeath:
		CPOS O 5 A_XScream;
		CPOS P 5 A_NoBlocking;
		CPOS QRS 5;
		CPOS T -1;
		Stop;
	Raise:
		CPOS N 5 A_JumpIfInventory("RS_CG_GrowRaisin", 1, "Grow");
		CPOS MLKJIH 5;
		Goto See;
	// CH's own tier promotion: resurrected while "growing" -> the green
	// captain. Chaingunners.txt:1071.
	Grow:
		CPOS MLKJIH 5;
		// CH spawns the next creature and calls A_Die (Chaingunners.txt
		// Grow). That loses everything -- the promoted monster forgets its
		// target and returns at full health, which reads as "a new monster
		// appeared" rather than "that one changed". RS_PromoteTo runs the
		// COPPER promotion tell and carries target/master/vel/threshold and
		// health AS A FRACTION across the swap.
		CPOS A 0 { RS_PromoteTo("RS_CG_T0001"); }
		Stop;
	// The Abyss Pain Elemental converts what it hits. Chaingunners.txt:1041.
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

	// =================================================================
	// TIER DISPATCH ALIASES -- LOAD-BEARING, DO NOT DELETE.
	// RS_MonsterMaster dispatches every state through
	// TierState(prefix), which does FindStateByString(prefix.".T00",
	// EXACT). An exact lookup does NOT match a plain `Missile:` label,
	// so without these the dispatcher resolves to null: ApplyTier sets
	// MissileState = null and THE MONSTER NEVER FIRES A SHOT.
	// Base class dispatch sites: RS_MonsterMaster.zs:640-641 and
	// :1872-1897.
	//
	// MELEE IS DELIBERATELY ABSENT. This captain has no melee attack,
	// and a null MeleeState is what earns it the engine's
	// `if (MeleeState == NULL) dist -= 128` in P_CheckMissileRange --
	// declaring an empty Melee.T00 here would trap it at point blank.
	// That defect was found and fixed family-wide once already; do not
	// reintroduce it by "completing the set".
	// =================================================================
	Spawn.T00:   Goto Spawn;
	See.T00:     Goto See;
	Missile.T00: Goto Missile;
	Pain.T00:    Goto Pain;
	Death.T00:   Goto Death;
	XDeath.T00:  Goto XDeath;
	Raise.T00:   Goto Raise;
	}
}

// CH's GrowRaisin token. Held by a captain that should come back one
// colour higher when resurrected. Chaingunners.txt Raise/Grow branches.
class RS_CG_GrowRaisin : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.QUIET
	}
}
