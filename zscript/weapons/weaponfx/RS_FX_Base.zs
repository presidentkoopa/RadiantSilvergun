// =====================================================================
// RS_FXBase -- shared base classes every other RS_FX* file builds on.
// Split out of the original monolithic RS_EnhancedFX.zs so each FX
// category (particles, sparks, smoke, ricochet, puffs, rocket, plasma,
// BFG, muzzle light, casings) can live in its own file. This one loads
// first since RS_DebrisGeneral/RS_FlareGeneral/RS_DummyChecker are
// inherited from everywhere else in the RS_FX* tree.
//
// Every class across the whole RS_FX* split still carries the RS_
// prefix -- this is a restyled rebuild of a real, popular, standalone
// GZDoom mod, and reusing its class names unchanged would throw a
// duplicate-class-definition error for anyone running both.
// =====================================================================

class RS_DebrisGeneral : Actor
{
	Default
	{
		+FIXMAPTHINGPOS
		+LOOKALLAROUND
		+NOTAUTOAIMED
		+MISSILE
		+NOBLOCKMAP
		+MOVEWITHSECTOR
		+NOGRAVITY
		+DROPOFF
		+NOTELEPORT
		+FORCEXYBILLBOARD
		+GHOST
		+THRUACTORS
		+FLOORCLIP
		RenderStyle "Translucent";
		Alpha 1.0;
		Radius 1;
		Height 1;
		Mass 1;
		Damage 0;
	}
}

class RS_DummyChecker : Inventory
{
	Default
	{
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		-COUNTITEM
		-INVENTORY.INVBAR
		+INVENTORY.PERSISTENTPOWER
		Inventory.Amount 1;
		Inventory.MaxAmount 9999;
	}
}

class RS_FlareGeneral : RS_DebrisGeneral
{
	Default
	{
		+NOINTERACTION
		+NOCLIP
		-MISSILE
		-FORCEXYBILLBOARD
		RenderStyle "Add";
		Alpha 0.4;
		Scale 0.4;
	}
}
