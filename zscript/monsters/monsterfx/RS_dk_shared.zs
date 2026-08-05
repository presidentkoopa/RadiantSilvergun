// =====================================================================
// RS_dk_shared.zs
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

// RS_DKDart + RS_MinesRev -- the two Death-Knight projectiles the Black-revenant tier
// fires. Their full kit lives with the EX minibosses (carried later); these two are
// lifted byte-exact from the original hf_minibosses.zs so hf_revenant's Black tier
// resolves now. No external deps (stock MISL sprites + A_Explode).
class RS_DKDart : Actor
{
	Default { Radius 3; Height 12; Speed 28; Damage 12; RenderStyle "Add"; DamageType "Fire"; Alpha 1.0; Projectile; +THRUGHOST; +MTHRUSPECIES;
		SeeSound "monster/dkndrt"; DeathSound "weapons/firex4"; }
	States { Spawn: MISL A 2 Bright; Loop; Death: MISL BCD 3 Bright A_Explode(12,48); Stop; }
}
class RS_MinesRev : Actor
{
	Default { Radius 12; Height 12; Speed 24; /* CH: Damage (random(10,40))  Revenants.txt:3240 -- was flattened to `Damage 25`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(10,40)); RenderStyle "Translucent"; Alpha 0.95; Projectile; DamageType "Fire"; -NOGRAVITY; +BOUNCEONWALLS; +MTHRUSPECIES;
		BounceCount 4; BounceFactor 0.7; SeeSound "imp/attack"; DeathSound "weapons/rocklx"; }
	States { Spawn: MISL A 4 Bright; Loop; Death: MISL BCD 4 Bright A_Explode(40,96); Stop; }
}
