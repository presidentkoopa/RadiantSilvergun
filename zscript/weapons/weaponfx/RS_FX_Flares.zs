// =====================================================================
// RS_FXFlares -- standalone lens-flare/point-light bursts. Built on
// RS_FlareGeneral (RS_FX_Base.zs). Unlike RS_RocketFlare/RS_BFGTrail/etc,
// these aren't warped to a master each tic -- they're one-shot bursts
// meant to be spawned at a fixed point (muzzle, impact) and fade out on
// their own. Read through RS_Catalog.FLARE_*.
//
// Sprites (RSF3-RSF6) were already renamed and filed under
// sprites/combatfx/flares/ during an earlier combat-FX pass, but
// nothing referenced them until now.
// =====================================================================

class RS_LensFlare : RS_FlareGeneral
{
	Default
	{
		RenderStyle "Add";
		Alpha 0.6;
		Scale 0.3;
	}
	States
	{
	Spawn:
		RSF3 A 3 Bright;
		RSF3 A 4 Bright A_FadeOut(0.15);
		Stop;
	}
}

class RS_LensFlareAlt1 : RS_LensFlare
{
	States
	{
	Spawn:
		RSF4 A 3 Bright;
		RSF4 A 4 Bright A_FadeOut(0.15);
		Stop;
	}
}

class RS_LensFlareAlt2 : RS_LensFlare
{
	States
	{
	Spawn:
		RSF5 A 3 Bright;
		RSF5 A 4 Bright A_FadeOut(0.15);
		Stop;
	}
}

class RS_LensFlareAlt3 : RS_LensFlare
{
	States
	{
	Spawn:
		RSF6 A 3 Bright;
		RSF6 A 4 Bright A_FadeOut(0.15);
		Stop;
	}
}
