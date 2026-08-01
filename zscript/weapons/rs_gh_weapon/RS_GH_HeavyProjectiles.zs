// =====================================================================
// RS_GH_ heavy projectiles -- catalog entries for the GunstarHeroes set,
// mirroring RS_FX_HeavyProjectiles.zs's role for the main arsenal.
// ---------------------------------------------------------------------
// Ported from the HB master (hf_hb_weapons.zs) art/behavior, NOT the
// generic vanilla-based fallbacks the broken import left in place. Same
// SetupStats(int, double) contract as RS_EnhancedRocket/PlasmaBall/
// BFGBall, so RS_Weapon.A_RS_FireHeavyProjectile / RS_FireProfileHeavy
// reach these exactly the same way.
//
// Sprites: BFS1 -> RSR5, BFGB -> RSE9, SHOK -> RSF7, PBAL -> RSP7,
// EXPL -> RSI4, FRFX -> RSI5/RSI6, LEYS(R) -> RSF8. See EFFECT_CATALOG.md.
// =====================================================================

// -----------------------------------------------------------------
// BFG9000 / BFG10k -- source: HF_HB_BFGShot. Real green BFG ball +
// A_BFGSpray + shockwave, "New folder" art -- visually distinct from
// the vanilla-based RS_EnhancedBFGBall the broken import fell back to.
// Damage unchanged in spirit from vanilla (A_BFGSpray 40/15 + 100
// impact was the source's own note), scaled by the weapon's rolled
// DamagePerShot via SetupStats like every other heavy round here.
// -----------------------------------------------------------------
class RS_GH_BFGShot : Actor
{
	int RolledDamage;
	double ShotCritChance;

	Default
	{
		Projectile;
		Radius 13; Height 8; Speed 30;
		Damage 100;
		Scale 0.9; Alpha 0.95; RenderStyle "Add";
		+BRIGHT +FORCEXYBILLBOARD
		DeathSound "BFGEXPLO";
	}

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		ShotCritChance = critChance;
		SetDamage(finalDamage);
	}

	States
	{
	Spawn:
		RSR5 AB 4 Bright;
		Loop;
	Death:
		TNT1 A 0 A_BFGSpray("RS_GH_BFGExtra", 40, 15);
		TNT1 A 0 A_SpawnItemEx("RS_GH_BFGShock");
		RSE9 ABCDEFGH 3 Bright;
		Stop;
	}
}

// Green ray-hit flash spawned by A_BFGSpray.
class RS_GH_BFGExtra : Actor
{
	Default { +NOBLOCKMAP +NOGRAVITY +BRIGHT RenderStyle "Add"; Alpha 0.85; Scale 0.6; DamageType "Disintegrate"; }
	States { Spawn: RSE9 ABCDEFGH 3 Bright; Stop; }
}

// Green expanding shockwave ring.
class RS_GH_BFGShock : Actor
{
	Default { +NOBLOCKMAP +NOGRAVITY +CLIENTSIDEONLY +BRIGHT RenderStyle "Add"; Alpha 0.9; Scale 2.0; }
	States
	{
	Spawn:
		RSF7 A 1 Bright;
		RSF7 BCDEFGHIJKLMNOPQR 1 Bright A_FadeOut(0.05);
		Stop;
	}
}

// -----------------------------------------------------------------
// Plasma Rifle -- source: HF_HB_PlasmaShot. Same damage/speed shape as
// vanilla PlasmaBall (no override in the source either), the real
// difference is purely the PBAL art -- rounder, distinct from the
// vanilla-based RS_EnhancedPlasmaBall the broken import fell back to.
// -----------------------------------------------------------------
class RS_GH_PlasmaShot : PlasmaBall
{
	Default
	{
		RenderStyle "Add"; Alpha 0.9; Scale 0.45;
		+FORCEXYBILLBOARD
		SeeSound "";
	}

	void SetupStats(int finalDamage, double critChance)
	{
		SetDamage(finalDamage);
	}

	States
	{
	Spawn:
		RSP7 ABCDE 2 Bright;
		Loop;
	Death:
		RSP7 ABCDE 2 Bright A_FadeOut(0.25);
		Stop;
	}
}

// -----------------------------------------------------------------
// Unmaker -- source: HF_UnmakerShot. Real red MELT bolt (DamageType
// "Melt"), distinct from the vanilla-based RS_EnhancedPlasmaBall skin
// the broken import fell back to. Trail + burst FX ported from the same
// "New folder" art the source used (EXPL -> RSI4, FRFX -> RSI5/RSI6,
// LEYS -> RSF8).
// -----------------------------------------------------------------
class RS_GH_UnmakerBurst : Actor
{
	Default { +NOBLOCKMAP +NOGRAVITY +BRIGHT +FORCEXYBILLBOARD RenderStyle "Add"; Alpha 0.95; Scale 0.55; }
	States { Spawn: RSI4 ABCDEFGH 2 Bright; Stop; }
}

class RS_GH_UnmakerFlame : Actor
{
	Default { +MISSILE +FORCEXYBILLBOARD +THRUACTORS +THRUGHOST +NOBLOCKMONST RenderStyle "Add"; Alpha 0.9; Scale 0.3; Speed 6; Gravity 0.3; Damage 0; }
	States
	{
	Spawn:  RSI5 ABCDEFGHIJKLMNOPQRSTUVWXYZ 2 Bright A_FadeOut(0.04); RSI6 ABCDE 2 Bright A_FadeOut(0.04); Stop;
	Death:  TNT1 A 0; Stop;
	}
}

class RS_GH_UnmakerTrail : Actor
{
	Default { +NOBLOCKMAP +NOGRAVITY +NOINTERACTION +BRIGHT +FORCEXYBILLBOARD RenderStyle "Add"; Alpha 0.7; Scale 0.18; }
	States { Spawn: RSF8 R 2 Bright A_FadeOut(0.25); Stop; }
}

// -----------------------------------------------------------------
// Flamethrower -- no source class exists for this anywhere in this
// project (HF_FTFire was referenced by the source master file but never
// actually ported here). This is a genuine new build, not a
// wrong-fallback fix: real DamageType "Fire" and the fire-category art
// this weapon never had (RSI0, "long fire plume" -- already catalogued,
// no new import needed). Short range/lifespan matches a flame cone
// rather than a travelling round.
// -----------------------------------------------------------------
class RS_GH_FlameJet : RS_BallisticFired
{
	Default
	{
		DamageType "Fire";
		Scale 0.5;
		Alpha 0.9;
		RenderStyle "Add";
		+BRIGHT
	}

	States
	{
	Spawn:
		RSI0 "abcdefghijklmnopqrs" 2 Bright;
		Stop;

	Death:
		TNT1 A 0
		{
			A_PlaySound("rs_fx_impact_bullet", CHAN_AUTO);
			// Player Feedback override, same mechanism as the base
			// RS_BallisticFired.Death -- default here is genuinely "no
			// puff, just the sound," so only spawn something if a
			// profile actually set one.
			if (ImpactPuffOverride) Spawn(ImpactPuffOverride, pos);
			if (ImpactSparkOverride) Spawn(ImpactSparkOverride, pos);
		}
		Stop;
	}
}

class RS_GH_UnmakerShot : PlasmaBall
{
	int RolledDamage;
	double ShotCritChance;

	Default
	{
		DamageType "Melt";
		SeeSound "";
		RenderStyle "Add";
		Scale 0.28;
		Speed 40;
		+FORCEXYBILLBOARD
	}

	void SetupStats(int finalDamage, double critChance)
	{
		RolledDamage = finalDamage;
		ShotCritChance = critChance;
		SetDamage(finalDamage);
	}

	States
	{
	Spawn:
		RSF8 R 1 Bright A_SpawnItemEx("RS_GH_UnmakerTrail");
		Loop;
	Death:
		TNT1 A 0 A_SpawnItemEx("RS_GH_UnmakerBurst");
		TNT1 AA 0 A_SpawnProjectile("RS_GH_UnmakerFlame", 6, 0, random(0,360), 2, random(0,60));
		Stop;
	}
}
