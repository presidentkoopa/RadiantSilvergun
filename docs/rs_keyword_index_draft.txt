// =====================================================================
// RS_KeywordIndex -- LIVING DRAFT, not wired into zscript.txt yet.
// Running notes for the weapon keyword system as we spitball it.
// Nothing here is final; update freely as decisions change.
// =====================================================================

// archetype: (10-12 values, closed set)
//   revolver pistol smg rifle shotgun supershotgun chaingun launcher
//   energy bfg melee
//   OPEN: does Vanilla+ ARifle share chaingun, or get its own bucket?
//   Future grenade launcher -> launcher, not rifle.

// set: (origin)
//   silvergun vanillaplus

// trigger:
//   REAL today:    semiauto fullauto heldbeam (chainsaw)
//   RESERVED:      burstX charge spool boltaction
//   CUT:           pump (no pump animation exists -- shotgun is semiauto)

// grip:
//   one-hand two-hand stabilizable

// delivery:
//   bullet heavy radial melee
//   Describes shot SHAPE, not resolution timing. "Instant, no travelling
//   projectile actor" is real today (RS_ATK_HITSCAN mode, e.g. the
//   Chaingun; every melee attack too -- A_CustomPunch has no projectile
//   either) but is NOT its own delivery value -- a hitscan gun still
//   says delivery:bullet, melee still says delivery:melee. The
//   projectile-vs-instant distinction lives at the code level
//   (RS_AttackProfile.Mode), not the keyword level, specifically so a
//   future affix can grant "fires as hitscan" onto any weapon without
//   fighting a base keyword that claims otherwise. See also: the shared
//   GunBonsai XP-attribution gap this same instant/no-projectile fact
//   causes for hitscan AND melee alike (task #6).

// payload:
//   REAL:      single multi explosive
//   RESERVED:  cluster hazard

// behavior:
//   granted-only, empty on all base weapons.
//   OPEN: does ricochet become affix-granted, replacing the current
//   global rs_fx_ricochet cvar, or stay separate?

// element:
//   REAL:      kinetic plasma
//   RESERVED:  thermal corrosive poison shock void
//   (poison split from corrosive to match GunBonsai's own upgrade trees)

// feed:
//   speedloader magazine per-shell break-action belt cell-direct none

// sockets:
//   universal offensive-only elemental-only none
//   (wires up the currently-dead GunBonaiSockets field)

// growth:  CUT for now, nothing to split on.
// model:   CUT -- no reason to swap models on promotion.
// reserve/ammotype: LEANING CUT -- likely redundant with AmmoType1.
