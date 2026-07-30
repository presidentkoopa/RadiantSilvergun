// =====================================================================
// RS_FXTracer -- integrates directly with the existing ballistic system.
// This is the ProjectileClass value bullet weapons swap to when
// rs_fx_tracers is on; no weapon file needs to know this class exists.
// Split out of the original monolithic RS_EnhancedFX.zs -- see
// RS_FXBase.zs. Depends on RS_BallisticFired.zs (loaded earlier in
// zscript.txt) and RS_FXRicochet.zs (RS_RicochetBullet).
//
// See docs/HANDOFF.md's "Note on 'tracer' naming" -- the whizz sound and
// ricochet here are still coupled to this one visual variant rather than
// being universal bullet behaviors. Known debt, not fixed by this split.
// =====================================================================

class RS_BallisticTracer : RS_BallisticFired
{
	States
	{
	Spawn:
		BAL1 A 1 Bright A_JumpIfCloser(192, "SpawnNear");
		TNT1 A 0 A_FadeOut(0.1);
		Loop;
	SpawnNear:
		BAL1 A 30 Bright A_PlaySound("rs_fx_tracerwhizz", CHAN_AUTO, 1.0, false, ATTN_STATIC);
		Loop;
	Death:
		TNT1 A 0 A_JumpIf(!CVar.GetCVar("rs_fx_ricochet", null), "Super::Death");
		TNT1 A 0 A_SpawnProjectile("RS_RicochetBullet", 0, 0, Random(0, 360), 2, Random(-40, 40));
		Goto Super::Death;
	}
}
