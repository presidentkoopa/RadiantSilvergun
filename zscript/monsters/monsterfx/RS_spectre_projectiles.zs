// =====================================================================
// RS_spectre_projectiles.zs
// ---------------------------------------------------------------------
// Monster attack components, extracted per docs/catalog_notes.txt: every
// projectile is a standalone catalogued entry with its own visual
// identity, audio, movement and damage properties, so monster attacks
// can be recombined the same way weapon attacks are, rather than each
// monster owning a hardcoded projectile.
//
// Converted from the earlier port's library and RS_-prefixed. Sprite
// references verified against ART SOURCE / IWAD -- see the import notes
// at the bottom of this file for anything that was corrected.
// =====================================================================

// ============================================================================
// hf_spectre_projectiles.zs -- Spectre projectiles (shadow Pinky color ladder).
// Spectre IS the shadow Demon -- reuses RS_AbyssDogFire, RS_RedDemonBloodBolt1/3,
// RS_SpikeCyanRev, RS_WormLewd (from Demon/HK). New: ShadowBall, IceOrbCH2. Damage->const.
// ============================================================================

// ---------- BLACK: "Shadow" -- shadow balls (SBAL) ----------
class RS_ShadowBall : Actor
{
	Default { Radius 6; Height 8; Speed 18; Damage 38; Projectile; +RANDOMIZE; DamageType "Plasma"; RenderStyle "Add"; Alpha 0.75;
		SeeSound "shadowbeast/pr1sit"; DeathSound "shadowbeast/pr1death"; Translation "0:255=%[0.10,0.05,0.20]:[0.60,0.30,0.90]"; }
	States { Spawn: SBAL AB 3 Bright; Loop; Death: SBAL CDE 4 Bright A_Explode(38,64); Stop; }
}
class RS_ShadowBall2 : RS_ShadowBall { Default { Speed 8; Damage 60; DamageType "Fire"; Scale 1.75; } }

// ---------- GRAY: bouncing ice orb (ICEY/ROSX) ----------
class RS_IceOrbCH2 : Actor
{
	Default { ProjectileKickBack 1999; Radius 8; Height 8; Speed 15; Damage 22; DamageType "Melee"; Projectile; +SEEKERMISSILE; +BOUNCEONWALLS; +USEBOUNCESTATE;
		BounceType "Doom"; BounceCount 4; BounceFactor 1.1; RenderStyle "Add"; Alpha 0.85; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States { Spawn: ICEY AB 3 Bright A_SeekerMissile(2,2); Loop; Death: ICEY CDE 4 Bright A_Explode(22,48); Stop; }
}
