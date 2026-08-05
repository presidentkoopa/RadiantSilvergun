// VR_Fist 1..6 -- the arsenal's bare-hands melee, as real RS_Weapons.
// ---------------------------------------------------------------------
// WHY THIS FILE CHANGED (owner, 2026-08-04): "fist is an RS_weapon and
// should be treated as such."
//
// It was not. This file used to hold exactly one class,
// `VR_Fist2 : Fist`, extending the VANILLA Fist, and every VR_Dual_*
// class started with plain "Fist" plus that. Slot 1's melee was
// therefore the ONLY weapon in the player arsenal with no rolled stats,
// no tier, no sockets, no condition and no attack profile -- unpromotable,
// uncardable, and invisible to every system that queries RS_Weapon.
// Meanwhile RS_GH_Fist has been a full six-variant RS_Weapon ladder the
// whole time, so the two halves of the arsenal disagreed about what a
// fist even is.
//
// THE LADDER IS 1..6 AND UNIVERSAL, owner's call: "i'd rather us have a
// universal Fist _1 - _6. for our chosen classes we only need fist 1 and
// 2, but for the Slappers Only! unbuilt class, we will use all six."
// So 1 is the mainhand and 2 the off-hand -- the pair every Dual_ class
// actually grants -- and 3..6 exist now so the melee class has a full
// rack waiting rather than needing this file reopened later.
//
// NOTE THE PAIRING DIFFERS FROM THE RANGED FAMILIES ON PURPOSE. Ranged
// class weapons pair 1&4, 2&5, 3&6 across slots 2/3/4 (see
// VR_Dual_Revolver: VR_Revolver + VR_Revolver4). The fist has only slot
// 1, so it pairs 1&2 and the rest are free. Do not "fix" this to match.
//
// NO MAGAZINE, BY DEFAULT AND ONLY BY DEFAULT. Capacity 0 / ReloadSpeed
// 1.0 describe bare knuckles, not "melee cannot have ammo". The owner's
// own example is the one to protect: electric brass knuckles SHOULD be
// able to take a magazine and spend it as charges. A variant that wants
// one sets it; nothing here assumes otherwise. Same
// capability-is-not-obligation rule rs_17 s1 sets for trigger fields.
//
// KNOWN GAP -- BERSERK. Vanilla Fist's PowerStrength multiplier lives
// inside A_Punch, which this does not call (it fires through
// A_RS_FireSlot like every other RS_Weapon), so a berserk pack currently
// does nothing here. VR_Chainsaw has the same property and it is correct
// there -- vanilla's chainsaw ignores berserk too -- but for the FIST it
// is a real loss. Filed as its own objective rather than papered over
// with a guessed multiplier.
// =====================================================================
class VR_Fist : RS_Weapon
{
	Default
	{
		Tag "Knuckles";
		Weapon.SelectionOrder 3700;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		+WEAPON.WIMPY_WEAPON;
		+WEAPON.MELEEWEAPON;
		+WEAPON.NOALERT;
		+WEAPON.NOHANDSWITCH;
	}

	override string GetBaseKeywords()
	{
		return "archetype:melee trigger:semi delivery:melee payload:single feed:none reserve:none element:kinetic promotion:pellet set:radiantsilvergun";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		// Deliberately under VR_Chainsaw at every tier: the chainsaw is a
		// weapon, this is what you have when you have nothing.
		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(2, 5);
				CritChance    = RS_Roll.RollDouble(0.02, 0.05);
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(3, 6);
				CritChance    = RS_Roll.RollDouble(0.025, 0.06);
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(4, 7);
				CritChance    = RS_Roll.RollDouble(0.03, 0.07);
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(5, 9);
				CritChance    = RS_Roll.RollDouble(0.035, 0.08);
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(6, 11);
				CritChance    = RS_Roll.RollDouble(0.04, 0.09);
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(7, 13);
				CritChance    = RS_Roll.RollDouble(0.05, 0.1);
				break;
			case VRT_Trash:
				DamagePerShot = RS_Roll.RollInt(1, 3);
				CritChance    = RS_Roll.RollDouble(0.01, 0.03);
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(3, 6);
				CritChance    = RS_Roll.RollDouble(0.04, 0.07);
				break;
		}

		Accuracy        = 100; // melee, always connects in range
		Velocity        = 0;   // melee, no projectile
		Capacity        = 0;   // bare knuckles carry no magazine -- see header
		RateOfFire      = 6;   // matches the punch animation below
		ReloadSpeed     = 1.0; // nothing to reload
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (t == VRT_Cursed)
		{
			LockedDamage     = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	// 64-unit reach, same as vanilla's punch and VR_Chainsaw's swing.
	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeMelee(
			range: 64.0,
			fireSnd: "*fist",
			puff: "BulletPuff",
			profName: "Jab"));
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;

	Ready:
		PUNG A 1 A_WeaponReady();
		Loop;

	Deselect:
		PUNG A 1 A_Lower;
		Loop;

	Select:
		PUNG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		PUNG B 4;
		PUNG C 4 A_RS_FireSlot(0);
		PUNG D 5;
		PUNG C 4;
		PUNG B 5 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		Stop;
	}
}

// --- 2: THE OFF-HAND -------------------------------------------------
// Keeps the class name, the Tag and the SelectionOrder it has always
// had, so every VR_Dual_* StartItem list still resolves untouched. The
// only change is its PARENT: it was `: Fist`, it is now a real
// RS_Weapon. That is the whole point of this file.
class VR_Fist2 : VR_Fist
{
	Default
	{
		Tag "Off-Hand Fist";
		Weapon.SelectionOrder 3699; // distinct from the mainhand's --
		                            // sharing one made them indistinguishable
		Weapon.SlotNumber 1;
		+WEAPON.OFFHANDWEAPON;
	}

	// Seat this as the off-hand the moment it is picked up. The flag
	// marks intent; this makes it happen. Carried over verbatim from the
	// old vanilla-derived class, which needed it for the same reason.
	override void AttachToOwner(Actor newOwner)
	{
		Super.AttachToOwner(newOwner);
		if (newOwner.player)
			newOwner.player.OffhandWeapon = self;
	}
}

// --- 3..6: THE RACK --------------------------------------------------
// Unused by any current class. They exist so "Slappers Only!" has a full
// six-weapon set to draw on without reopening this file. Odd numbers are
// mainhand, even are off-hand, matching 1 and 2 above.
// Names are placeholders for flavour, not statements of mechanics --
// none of these carry a magazine yet, and per the header note that is a
// per-variant decision, not a melee-wide rule.

class VR_Fist3 : VR_Fist
{
	Default
	{
		Tag "Brass Knuckles";
		Weapon.SelectionOrder 3698;
		Weapon.SlotNumber 1;
	}
}

class VR_Fist4 : VR_Fist2
{
	Default
	{
		Tag "Off-Hand Brass Knuckles";
		Weapon.SelectionOrder 3697;
		Weapon.SlotNumber 1;
	}
}

class VR_Fist5 : VR_Fist
{
	Default
	{
		Tag "Gauntlet";
		Weapon.SelectionOrder 3696;
		Weapon.SlotNumber 1;
	}
}

class VR_Fist6 : VR_Fist2
{
	Default
	{
		Tag "Off-Hand Gauntlet";
		Weapon.SelectionOrder 3695;
		Weapon.SlotNumber 1;
	}
}
