// =====================================================================
// RS_FXExplosions -- standalone detonation visuals. Purely cosmetic:
// damage/splash radius is dealt by the caller's own A_Explode before
// spawning one of these, never by the visual actor itself. Read through
// RS_Catalog.EXPLOSION_* so a projectile's blast look is swappable via
// its AttackProfile (see RS_EnhancedRocket.ExplosionVisual) instead of
// hardcoded per class.
//
// Sprites (RSE0/RSE1/RSE3/RSE4/RSE5) were already renamed and filed
// under sprites/combatfx/explosions/ during an earlier combat-FX pass,
// but nothing referenced them until now -- these classes are the first
// real use.
// =====================================================================

class RS_ExplosionFireball : Actor
{
	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+CLIENTSIDEONLY
		RenderStyle "Add";
		Alpha 1.0;
		Scale 0.5;
	}
	States
	{
	Spawn:
		RSE0 "ABCDEFGHIJKLMNOPQRSTUVWXYZ" 2 Bright;
		Stop;
	}
}

// Same scale/role, different burn pattern -- pick of the two gives
// visual variety across repeated rocket hits instead of the exact same
// fireball every time.
class RS_ExplosionFireballAlt : RS_ExplosionFireball
{
	States
	{
	Spawn:
		RSE1 "ABCDEFGHIJKLMNOPQRSTUVWXY" 2 Bright;
		Stop;
	}
}

// Smaller blast -- grenade-scale, not rocket-scale.
class RS_ExplosionSmall : RS_ExplosionFireball
{
	Default
	{
		Scale 0.35;
	}
	States
	{
	Spawn:
		RSE3 "ABCDEF" 3 Bright;
		Stop;
	}
}

class RS_ExplosionTiny : RS_ExplosionFireball
{
	Default
	{
		Scale 0.25;
	}
	States
	{
	Spawn:
		RSE4 "ABCD" 3 Bright;
		Stop;
	}
}

// Single-frame flash -- for impacts too fast/small to want a full burn.
class RS_ExplosionFlash : RS_ExplosionFireball
{
	Default
	{
		Scale 0.4;
		Alpha 0.8;
	}
	States
	{
	Spawn:
		RSE5 A 5 Bright;
		RSE5 A 3 Bright A_FadeOut(0.3);
		Stop;
	}
}
