// =====================================================================
// RS_FXPlasma -- plasma-specific trail/flare/debris effects. Split out
// of the original monolithic RS_EnhancedFX.zs -- see RS_FXBase.zs.
// Depends on RS_FXBase.zs (RS_FlareGeneral, RS_DebrisGeneral,
// RS_DummyChecker). RS_FXBFG.zs depends on several classes here
// (RS_BluePlasmaPiece, RS_BluePlasmaShred/Trail, RS_PlasmaRailBall), so
// this file must load before it.
// The projectile itself (RS_EnhancedPlasmaBall) lives in
// RS_HeavyProjectiles.zs, not here -- see that file's own header.
// =====================================================================

class RS_BlueFlarePlasma : RS_FlareGeneral
{
	Default
	{
		RenderStyle "Add";
		Alpha 0.5;
		Scale 0.1;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_Warp(AAPTR_MASTER);
	Spawn1:
		TNT1 A 0 A_JumpIfMasterCloser(1, "Spawn1");
		RSF0 A 1 Bright A_FadeOut(0.1);
		Wait;
	}
}

// Appears behind the plasma ball as a fading trail.
class RS_BlueFlarePlasmaTrail : RS_FlareGeneral
{
	Default
	{
		+FORCEXYBILLBOARD
		Alpha 0.4;
		Scale 0.07;
	}
	States
	{
	Spawn:
		RSF0 A 1 Bright A_FadeOut(0.15);
		TNT1 A 0 A_SetScale(Scale.X * 0.9, Scale.Y * 0.9);
		Loop;
	}
}

class RS_BluePlasmaPiece : RS_DebrisGeneral
{
	Default
	{
		+DONTSPLASH
		-NOGRAVITY
		RenderStyle "Add";
		Alpha 1.0;
		Scale 0.08;
		Speed 6;
		Gravity 0.8;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		RSP4 A 1 Bright A_FadeOut(0.03);
		Loop;
	}
}

class RS_PlasmaRailBall : RS_DebrisGeneral
{
	Default
	{
		-MISSILE
		+NOINTERACTION
		RenderStyle "Add";
		Alpha 0.8;
		Scale 0.03;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_SpawnItem("RS_PlasmaRailFlare");
		RSP6 "ABCDEF" 1 Bright A_FadeOut(0.0025);
		RSP6 "GHIJKLM" 2 Bright A_FadeOut(0.0025);
		Stop;
	}
}

class RS_BluePlasmaShred : RS_DebrisGeneral
{
	Default
	{
		+NOINTERACTION
		RenderStyle "Add";
		Speed 5;
		Scale 0.05;
		Alpha 0.6;
	}
	States
	{
	Spawn:
		RSP3 "ABCDE" 1 Bright A_SpawnItem("RS_BluePlasmaShredTrail");
		Stop;
	}
}

class RS_BluePlasmaShredTrail : RS_BluePlasmaShred
{
	Default
	{
		Speed 0;
		Alpha 0.5;
	}
	States
	{
	Spawn:
		RSP3 "ABCDE" 2 Bright;
		Stop;
	}
}

class RS_PlasmaRailFlareCounter : RS_DummyChecker
{
	Default
	{
		Inventory.MaxAmount 500;
	}
}

class RS_PlasmaRailFlare : RS_BlueFlarePlasmaTrail
{
	Default
	{
		Alpha 0.1;
		Scale 0.07;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 A_GiveInventory("RS_PlasmaRailFlareCounter", 1, AAPTR_PLAYER1);
		TNT1 A 0 A_JumpIfInventory("RS_PlasmaRailFlareCounter", 250, "Disappear", AAPTR_PLAYER1);
		TNT1 A 1;
		TNT1 A 0 A_TakeInventory("RS_PlasmaRailFlareCounter", 1, 0, AAPTR_PLAYER1);
		RSF0 A 1 Bright A_FadeOut(0.0025);
		Wait;
	Disappear:
		TNT1 A 1 A_TakeInventory("RS_PlasmaRailFlareCounter", 1, 0, AAPTR_PLAYER1);
		Stop;
	}
}

// Impact splash -- standalone, spawn-and-forget, no damage of its own
// (the hit is already resolved by whatever spawned it). Read through
// RS_Catalog.PLASMA_Splash()/PLASMA_SplashAlt(). Sprites (RSP1/RSP5)
// were already renamed and filed under sprites/combatfx/plasma/ during
// an earlier combat-FX pass, but nothing referenced them until now.
class RS_PlasmaSplash : Actor
{
	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+CLIENTSIDEONLY
		RenderStyle "Add";
		Alpha 0.9;
		Scale 0.35;
	}
	States
	{
	Spawn:
		RSP1 "ABCDE" 2 Bright;
		Stop;
	}
}

class RS_PlasmaSplashAlt : RS_PlasmaSplash
{
	States
	{
	Spawn:
		RSP5 "ABCDEF" 2 Bright;
		Stop;
	}
}
