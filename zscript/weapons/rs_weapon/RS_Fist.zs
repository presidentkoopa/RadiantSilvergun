// VR_Fist2 -- off-hand melee baseline.
// ---------------------------------------------------------------------
// The main hand always has vanilla "Fist" as its baseline weapon; the
// off-hand had no equivalent, which meant the off-hand slot had nothing
// to fall back on even when an offhand-flagged ranged weapon (e.g.
// VR_Pistol4) was granted alongside it. This mirrors vanilla Fist
// exactly, just flagged for the off-hand.
// =====================================================================
class VR_Fist2 : Fist
{
  Default
  {
    Tag "Off-Hand Fist";
    Weapon.SelectionOrder 3699; // distinct from vanilla Fist's own --
                                // sharing one made the two indistinguishable
    +WEAPON.NOHANDSWITCH;
    +WEAPON.OFFHANDWEAPON;
  }

  // Doesn't inherit from RS_Weapon (vanilla Fist doesn't either), so it
  // needs its own copy of the same acquisition-time seating.
  override void AttachToOwner(Actor newOwner)
  {
    Super.AttachToOwner(newOwner);
    if (newOwner.player)
      newOwner.player.OffhandWeapon = self;
  }
}

