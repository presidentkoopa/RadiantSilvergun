// =====================================================================
// RS_MonsterKeywordIndex -- LIVING DRAFT, deliberately not compiled.
// ---------------------------------------------------------------------
// Not included in zscript.txt, same as its weapon-side counterpart
// RS_KeywordIndex.zs isn't. This is the documented taxonomy for monster
// keywords: what each key means, which values are REAL (something in
// the repo actually uses them today), RESERVED (planned, nothing reads
// them yet), or CUT (considered and rejected, recorded so it doesn't
// get reinvented).
//
// The parser is shared, not forked: monsters and weapons both go
// through RS_Keywords, and RS_Keywords.IsKnownKey() validates both
// vocabularies. Keys that genuinely mean the same thing on both sides
// (delivery, payload, element, set) are deliberately the SAME key, so a
// future affix can ask "is this thermal?" without caring whether it's
// looking at a gun or a monster.
//
// Storage mirrors RS_Weapon exactly: BASE (authored per class via
// GetBaseKeywords) + GRANTED (runtime, via GrantKeyword), with the same
// query API on RS_MonsterMaster.
// =====================================================================

// ---------------------------------------------------------------------
// species: -- what the monster fundamentally is. One per body.
// ---------------------------------------------------------------------
//   REAL: zombieman shotgunner chaingunner imp demon spectre lostsoul
//         cacodemon painelemental baron hellknight revenant mancubus
//         arachnotron archvile
//   REAL (summoned): tendril sentinel
//   RESERVED: mastermind cyberdemon
//
//   A recoloured/retiered variant does NOT get its own species -- a
//   Tier 12 Zombieman is still species:zombieman. Species is "what it
//   fundamentally is", tier is how dangerous. Keeping those separate is
//   what lets a future effect say "all zombiemen" without enumerating
//   thirteen tiers.
//
//   Second stages DO keep the parent's species (the Pain Pilot is still
//   species:painelemental) and mark themselves with trait:secondstage
//   instead -- they're the same creature revealed, not a new one.

// ---------------------------------------------------------------------
// role: -- combat function. What it's FOR in a fight.
// ---------------------------------------------------------------------
//   REAL: fodder skirmisher bruiser artillery summoner
//   RESERVED: support boss
//
//   "support" is RESERVED, not real -- no monster declares it today.
//   The Archvile is the obvious future candidate (it resurrects and
//   conjures for others) but it currently declares role:summoner, which
//   is the more useful read for a player deciding what to shoot first.
//
//   Read this as "how should the player prioritise it". A summoner is
//   worth killing first even at low health; fodder is worth ignoring.
//   Note role is NOT tier -- a Tier 12 zombieman is still fodder, it's
//   just fodder that hurts.

// ---------------------------------------------------------------------
// delivery: -- attack SHAPE. Multi-value; a monster with a melee swipe
//              and a fireball declares both.
// ---------------------------------------------------------------------
//   REAL: bullet melee heavy radial
//
//   Same discipline as the weapon side: this is shape, not resolution
//   timing. A hitscan-firing monster still says delivery:bullet.
//   Whether it resolves instantly or as a travelling projectile lives
//   in the attack profile's Mode, not here -- so a future tier unlock
//   can grant "fires as hitscan" without fighting a base keyword that
//   claims otherwise.
//
//   RESERVED: summon
//     Considered and NOT added, because summoning is already expressed
//     twice -- role:summoner (what it is) and RS_ATK_SUMMON (what the
//     profile does). A third representation would be one more thing to
//     keep in sync.

// ---------------------------------------------------------------------
// payload: -- what the attack does on arrival.
// ---------------------------------------------------------------------
//   REAL: multi
//   RESERVED: single explosive dot hazard
//
//   Only "multi" is real today (the Shotgunner's pellet spread). The
//   rest are reserved rather than invented, because nothing reads them
//   yet and a value nothing consumes is a lie in a table.

// ---------------------------------------------------------------------
// element: -- SAME vocabulary as the weapon side, deliberately shared.
// ---------------------------------------------------------------------
//   REAL: kinetic thermal plasma
//   RESERVED: corrosive poison shock void
//
//   This is the key most likely to pay off from being shared. The
//   imported projectile library already carries real DamageTypes
//   (Fire, Ice, Poison, Plasma) on 474 classes, so an elemental affix
//   or resistance system has both a keyword axis AND real damage types
//   to hang off.
//
//   OPEN: element is currently declared per-MONSTER, but a monster with
//   a rotation can throw thermal on one beat and ice on another. The
//   per-beat answer already exists on the weapon side
//   (RS_AttackProfile.LocalKeywords) -- monsters should probably move
//   to that rather than declaring one element for the whole creature.
//   Not done yet; flagged rather than pretended.

// ---------------------------------------------------------------------
// mobility: -- how it moves. Closed set, matters for AI and targeting.
// ---------------------------------------------------------------------
//   REAL: ground flying floating
//
//   flying vs floating is a real distinction, not flavour: floating
//   (Cacodemon, Pain Elemental) drifts and holds position; flying
//   (Lost Soul, Sentinel) charges and commits. Anything that wants to
//   punish airborne monsters cares which.

// ---------------------------------------------------------------------
// trait: -- multi-value modifiers. The open-ended axis.
// ---------------------------------------------------------------------
//   REAL: stealth homing resurrector summoned secondstage
//   RESERVED: regenerating armoured explosive-death
//
//   trait:summoned and trait:secondstage are structural -- they mark
//   monsters that exist because of another monster. Note these are
//   documentation, NOT the mechanism: RS_Bits reads the real facts
//   (IsSummonedMinion / IsTransientStage) rather than parsing strings,
//   because a payout rule shouldn't depend on someone remembering to
//   type a keyword. The keyword is for querying and display; the
//   pointer is for logic.
//
//   This is the key intended to grow. Runtime grants go here.

// ---------------------------------------------------------------------
// set: -- origin/lineage. Exactly parallel to weapons' set: key.
// ---------------------------------------------------------------------
//   RESERVED: colourfulhell meatgrinder vanilla
//
//   Nothing declares a set yet. The current 15 are rebuilt from CH's
//   data rather than ported from it, so "colourfulhell" would overstate
//   the relationship. Becomes real when the Meatgrinder set lands
//   alongside them and the distinction starts mattering.

// ---------------------------------------------------------------------
// NOT KEYWORDS -- recorded so they don't get reinvented as strings.
// ---------------------------------------------------------------------
//   tier      RS_MonsterMaster.Tier, a real int. Read and written far
//             too often (every retier, every threshold check) to route
//             through string parsing.
//   elite     A separate axis from tier per the design brief -- elites
//             drop class weapons, normal monsters drop bits. Orthogonal
//             to everything here; will be its own field, not a keyword.
//   faction   CUT. RS has no multi-faction system and inventing values
//             nothing consumes is how the old vocabulary rotted.
