// =====================================================================
// RS_FXCasings -- casing ejection + magazine drop, cosmetic-only props
// for RS_HiFiFX.CasingEject()/MagDrop(). Generic enough to be reused by
// any weapon in this project or a future weapon set, rather than one
// class per gun. Real, falling, physical props -- unlike the floaty
// debris in the other RS_FX* files, these actually drop and settle.
// Split out of the original monolithic RS_EnhancedFX.zs -- see
// RS_FXBase.zs. Depends on RS_FXBase.zs (RS_DebrisGeneral).
// =====================================================================

class RS_CasingSmall : RS_DebrisGeneral
{
	Default
	{
		-NOGRAVITY
		-FORCEXYBILLBOARD
		+DROPOFF
		RenderStyle "Normal";
		Alpha 1.0;
		Scale 0.6;
		Gravity 1.0;
		BounceType "Doom";
		BounceFactor 0.3;
		Speed 0;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("rs_fx_casing_pistol", CHAN_AUTO);
		RSC0 "ABCDE" 2;
		Loop;
	Death:
		Stop;
	}
}

class RS_CasingRifle : RS_CasingSmall
{
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("rs_fx_casing_chaingun", CHAN_AUTO);
		RSC1 "ABCDE" 2;
		Loop;
	}
}

class RS_CasingShell : RS_CasingSmall
{
	Default
	{
		Scale 0.8;
	}
	States
	{
	Spawn:
		TNT1 A 0 A_PlaySound("rs_fx_casing_shell", CHAN_AUTO);
		RSC2 "ABDGK" 3;
		Loop;
	}
}

class RS_MagDrop : RS_DebrisGeneral
{
	Default
	{
		-NOGRAVITY
		-FORCEXYBILLBOARD
		+DROPOFF
		RenderStyle "Normal";
		Alpha 1.0;
		Scale 1.0;
		Gravity 1.0;
		BounceType "Doom";
		BounceFactor 0.15;
		Speed 0;
	}
	States
	{
	Spawn:
		RSM0 "ABCDEFGH" 3;
		Loop;
	Death:
		Stop;
	}
}
