// =====================================================================
// RS_Chaingunner -- the family base. FAMILY 04.
// ---------------------------------------------------------------------
// This file used to be 1,434 lines: ONE class holding all fourteen
// chaingunners as tier state-clusters, built from CHP and carrying CHP's
// numbers. It was replaced 2026-08-05 by the CH rebuild in
// zscript/monsters/chaingunner/ -- fourteen classes, one per creature,
// with CH's own numbers.
//
// WHAT THIS FILE IS NOW: the shared base the fourteen inherit, holding
// the parts that are OURS rather than CH's.
//
// WHY IT EXISTS AT ALL -- two reasons, both load-bearing:
//
//  1. A SHARED TYPE. Something asks "is there a chaingunner near me":
//     RS_Zombieman.zs:1074 runs A_CheckProximity(..., "RS_Chaingunner",
//     CPXF_ANCESTOR ...) so a zombieman takes cover when one is close.
//     CPXF_ANCESTOR matches DESCENDANTS of the named class. With the
//     fourteen inheriting RS_MonsterMaster directly, the nearest common
//     ancestor was RS_MonsterMaster -- every monster in the mod -- and
//     that check would have matched a cacodemon.
//
//  2. THE RS MECHANICS THE CH IMPORT COULD NOT CARRY. The agents that
//     built the fourteen were told to transcribe COLOURFUL HELL. These
//     four are not Colourful Hell's, they are ours, so a faithful CH
//     import was never going to produce them -- and deleting the old
//     file removed their only home. Restored here, which is where they
//     belonged all along: written once, inherited by all fourteen,
//     instead of copy-pasted into each.
//
// DELIBERATELY NOT RESTORED: BodyTable() and TintTable(). Those mapped
// "tier N -> which sprite / which tint" INSIDE one class. With one class
// per creature each file carries its own sprites and its own
// Translation, so they have no job left. They are obsolete by design,
// not lost.
//
// DO NOT PUT PER-CREATURE BEHAVIOUR HERE. The last thing this file was,
// was a god-class. The fourteen genuinely differ -- that is the point of
// the CH rebuild.
// =====================================================================

class RS_Chaingunner : RS_MonsterMaster abstract
{
	// Keyword-system identity for the whole family. Read by
	// RS_MonsterKeywordIndex; every creature in family 04 is a
	// ground-based bullet skirmisher regardless of which one it is.
	override string GetBaseKeywords()
	{
		return "species:chaingunner role:skirmisher delivery:bullet element:kinetic mobility:ground";
	}

	// A chaingunner's summoned pack dies with it. Without this a boss
	// that calls for help leaves its minions standing after it dies.
	override bool MinionsDieWithMe() { return true; }

	// -----------------------------------------------------------------
	// THE RAGE GATE. CH's high-tier chaingunners enrage around two
	// thirds health and PERMANENTLY gain a summon they did not have
	// before -- the second half of the fight is a different fight.
	//
	// One-shot: CheckThreshold latches, so this fires once per monster
	// however many times Pain runs.
	// -----------------------------------------------------------------
	const RS_CG_RAGE_SLOT = 0;

	// Which creatures rage. The old file gated on `Tier >= 8`, which
	// worked when one class held a ladder. There is no ladder now, so
	// each creature answers for itself and the default is no.
	virtual bool CanRage() { return false; }

	void RS_CheckRage()
	{
		if (CanRage() && CheckThreshold(RS_CG_RAGE_SLOT, 0.66))
		{
			Enrage(1.2);
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	// True once the gate has fired -- the creatures that summon check
	// this before rolling for it.
	bool RS_Raging() { return ThresholdFired(RS_CG_RAGE_SLOT); }
}
