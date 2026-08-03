// =====================================================================
// RS_FXFire -- standalone burn-loop visual. Bounded duration (one pass
// through the sequence, then Stop) rather than looping forever -- same
// shape GunBonsai's own Fire.zsc uses for its RSI3 ignite visual, so a
// spawner never has to remember to clean these up. Read through
// RS_Catalog.FIRE_*.
//
// Sprites (RSI1/RSI2) were already renamed and filed under
// sprites/combatfx/fire/ during an earlier combat-FX pass, but nothing
// referenced them until now.
// =====================================================================

class RS_FireLoop : Actor
{
	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+CLIENTSIDEONLY
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.4;
	}
	States
	{
	Spawn:
		RSI1 "ABCDEFGHIJKLM" 3 Bright;
		Stop;
	}
}

class RS_FireLoopAlt : RS_FireLoop
{
	States
	{
	Spawn:
		RSI2 "ABCDEFGHIJ" 3 Bright;
		Stop;
	}
}
