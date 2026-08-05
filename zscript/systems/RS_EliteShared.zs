// =====================================================================
// RS_EliteShared -- helper actors used by more than one elite profile.
// ---------------------------------------------------------------------
// These live here rather than in whichever profile file happens to need
// them first, because ZScript is CASE-INSENSITIVE and a duplicate class
// name is a FATAL REDEFINITION, not a shadow. Two profile files each
// defining their own sparkle would stop the mod compiling, and the error
// would name two files neither of whose authors thought they shared
// anything.
//
// If you are writing a profile: use these, do not redefine them.
// =====================================================================

// Small drifting glint. Used by any profile that wants a "this thing is
// wrong" shimmer without a full particle system.
class RS_EliteSparkle : Actor
{
	Default
	{
		Radius 1;
		Height 1;
		Scale 0.5;
		Alpha 0.9;
		RenderStyle "Add";
		+NOBLOCKMAP
		+NOGRAVITY
		+NOINTERACTION
		+THRUACTORS
		+NOTONAUTOMAP
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay { Vel.Z = FRandom(0.2, 0.6); }
		TNT1 A 1 Bright A_FadeOut(0.04, 1);
		Wait;
	}
}

// Marks an actor that must never be raised by a resurrector -- our own
// Pink-style profile, an Archvile, or anything else. Carried by profile
// spawn, so a profile that clones the monster does not create an infinite
// revive loop.
class RS_EliteNoRevive : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}
}

// Pitch-shifts an owner's vocalisations. Profiles that make a monster
// bigger or smaller hang this on it so it sounds the part.
class RS_EliteVoiceChanger : Inventory
{
	double factor;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}
}
