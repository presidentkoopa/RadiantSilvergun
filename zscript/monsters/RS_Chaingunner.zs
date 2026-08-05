// =====================================================================
// RS_Chaingunner -- the family base. FAMILY 04.
// ---------------------------------------------------------------------
// This file used to be 1,434 lines: ONE class holding all fourteen
// chaingunners as tier state-clusters, built from CHP and carrying CHP's
// numbers. It was replaced 2026-08-05 by the CH rebuild in
// zscript/monsters/chaingunner/ -- fourteen classes, one per creature,
// with CH's own numbers. The old body is DELETED, not disabled; it is in
// git history if anyone ever needs it (commit e56d0b5b and earlier).
//
// WHAT SURVIVES, AND WHY IT HAS TO:
//
// A shared base type. Without one there is no way to ask "is there a
// chaingunner near me" -- and something does ask. RS_Zombieman.zs:1074
// runs A_CheckProximity(..., "RS_Chaingunner", CPXF_ANCESTOR ...) so a
// zombieman takes cover when one is close. CPXF_ANCESTOR matches
// DESCENDANTS of the named class, so with the fourteen inheriting
// RS_MonsterMaster directly the only common ancestor was
// RS_MonsterMaster itself -- i.e. every monster in the mod. The check
// would have matched a cacodemon.
//
// So: abstract, empty, no Default block, no states. It contributes
// nothing to its children except a name that means "this is a
// chaingunner". Every family gets one of these as it is rebuilt.
//
// DO NOT PUT SHARED BEHAVIOUR HERE without deciding it belongs to all
// fourteen. The last thing this file was, was a god-class, and the
// fourteen creatures genuinely differ -- that is the whole point of the
// CH rebuild.
// =====================================================================

class RS_Chaingunner : RS_MonsterMaster abstract
{
}
