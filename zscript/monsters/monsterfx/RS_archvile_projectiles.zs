// =====================================================================
// RS_archvile_projectiles.zs
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
// hf_archvile_projectiles.zs -- Arch-vile projectiles (fire-pillar + color ladder).
// Signature = the A_VileTarget fire-pillar airstrike + A_VileChase resurrection.
// Reuses pool: RS_BigBolt2, RS_ArcRing1/2, RS_ReAComet, RS_CHBSTarget, RS_VileGroundSpike,
// RS_VileGroundSpikeBrown, RS_BaronRing, RS_SplashAbyss2 (already built). New below.
// Damage->constants.
// ============================================================================

// ---------- GREEN: poison "greenening" balls (GBLL) ----------
class RS_Greenening : Actor
{
	Default { Radius 6; Height 8; Speed 5; Damage 20; DamageType "Poison"; Projectile; RenderStyle "Add"; Alpha 0.9; SeeSound "vile/start"; DeathSound "vile/stop";
		Translation "0:255=%[0.10,0.50,0.00]:[0.50,1.50,0.20]"; }
	States { Spawn: GBLL AB 4 Bright; Loop; Death: GBLL CDE 4 Bright A_Explode(20,64); Stop; }
}
class RS_Greenening2 : RS_Greenening { Default { Speed 8; Damage 30; }
	States { Spawn: GBLL AB 3 Bright; Loop; Death: BFE2 ABCDE 4 Bright A_Explode(40,80); Stop; } }

// ---------- BLUE: plasma gash (PLSE/PLSS) ----------
class RS_BlueGash3 : Actor
{
	Default { Radius 6; Height 8; Speed 12; Damage 35; DamageType "Plasma"; Projectile; +NOGRAVITY; RenderStyle "Add"; Alpha 0.9; SeeSound "vile/start"; DeathSound "vile/stop"; }
	States { Spawn: PLSE AB 3 Bright; Loop; Death: PLSS CDE 4 Bright A_Explode(35,64); Stop; }
}

// ---------- PURPLE: hovering "worry" soul-fire (SBFX) ----------
class RS_PurpleWorry : Actor
{
	Default { Radius 6; Height 8; Speed 12; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; +SEEKERMISSILE;
		SeeSound "vile/start"; DeathSound "vile/stop"; Translation "0:255=%[0.40,0.00,0.60]:[1.30,0.30,1.70]"; }
	States { Spawn: SBFX AB 3 Bright A_SeekerMissile(2,2); Loop; Death: SBFX CDE 4 Bright A_Explode(30,48); Stop; }
}
class RS_PurpleWorry2 : RS_PurpleWorry { Default { Speed 16; Damage 40; } }

// ---------- CYAN: ice-start bolt (C3BB/GBLL) ----------
class RS_IceStartVile1 : Actor
{
	Default { Radius 6; Height 8; Speed 16; Damage 30; DamageType "Ice"; Projectile; RenderStyle "Add"; Alpha 0.9; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States { Spawn: C3BB AB 3 Bright; Loop; Death: C3BB CDE 4 Bright A_Explode(30,64); Stop; }
}
class RS_IceStartVile2 : RS_IceStartVile1 { Default { Speed 20; } }
class RS_IceStartVile3 : RS_IceStartVile1 { Default { Speed 12; Damage 25; } }
class RS_IceStartVile4 : RS_IceStartVile1 { Default { Speed 24; Scale 1.2; } }
class RS_IceToMeetVile1 : RS_IceStartVile1 { Default { Speed 18; Damage 35; }
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY CDE 4 Bright A_Explode(35,80); Stop; } }

// ---------- ABYSS: fast ice bolt (ICEY) ----------
class RS_IceABVile : Actor
{
	Default { Radius 6; Height 8; Speed 46; Damage 30; DamageType "Ice"; Projectile; RenderStyle "Add"; Alpha 0.9; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States { Spawn: ICEY AB 2 Bright; Loop; Death: ICEY CDE 4 Bright A_Explode(30,64); Stop; }
}

// ---------- GRAY: rock-drop airstrike (BAL1) ----------
class RS_RockVileDrop : Actor
{
	Default { Radius 8; Height 8; Speed 0; Damage 40; DamageType "Fire"; Projectile; +NOGRAVITY; -NOGRAVITY; Gravity 0.6; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States { Spawn: BAL1 AB 4; Loop; Death: BAL1 CDE 4 A_Explode(40,80); Stop; }
}

// ---------- RED: dark-fire pillar + flare (HLFR / CBAL) ----------
class RS_DFire : Actor
{
	Default { Radius 8; Height 8; Speed 0; Damage 4; DamageType "Fire"; Projectile; +NOINTERACTION; +NOGRAVITY; RenderStyle "Add"; Alpha 0.9;
		SeeSound "vile/start"; DeathSound "vile/stop"; }
	States
	{
	Spawn:
		HLFR A 3 Bright A_Explode(20,40,0);
		HLFR BCDEFG 3 Bright;
		Stop;
	}
}
class RS_DFlare : Actor
{
	Default { Radius 12; Height 12; Speed 25; Damage 24; RenderStyle "Add"; DamageType "Fire"; Alpha 0.85; Projectile; +THRUGHOST; SeeSound "vile/start"; DeathSound "vile/stop"; }
	States { Spawn: CBAL AB 3 Bright; Loop; Death: VBA3 ABCDE 4 Bright A_Explode(50,80); Stop; }
}

// ---------- BLACK: dark-flame cloud swarm (VILE-tinted) ----------
class RS_BVileCloud : Actor
{
	Default { Radius 8; Height 8; Speed 14; Damage 2; DamageType "Fire"; Projectile; +SEEKERMISSILE; +RIPPER; RenderStyle "Add"; Alpha 0.6; Scale 1.4;
		SeeSound "vile/start"; DeathSound "vile/stop"; Translation "0:255=%[0.10,0.00,0.20]:[0.50,0.20,0.70]"; }
	States { Spawn: VILE OPQ 4 Bright A_SeekerMissile(4,4); Loop; Death: VILE R 3 Bright; Stop; }
}

// ---------- WHITE: floating-eye bolts (FATB/BFE2) ----------
class RS_WVileBolt1 : Actor
{
	Default { Radius 6; Height 8; Speed 21; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.95;
		SeeSound "vile/start"; DeathSound "vile/stop"; Translation "0:255=%[0.80,0.80,1.00]:[2.00,2.00,2.00]"; }
	States { Spawn: FATB AB 3 Bright A_SeekerMissile(3,3); Loop; Death: BFE2 ABCDE 4 Bright A_Explode(30,64); Stop; }
}
class RS_WVileBolt2 : RS_WVileBolt1 { Default { Speed 28; Damage 40; } }

// ---------- FIREBLU: fire-soldier flame (FIRE) ----------
class RS_FireSGguy2 : Actor
{
	Default { Radius 4; Height 4; Speed 17; Damage 10; DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States { Spawn: FIRE AB 3 Bright; Loop; Death: FIRE CDE 3 Bright; Stop; }
}


// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * FBXP -> BFE2 (FBXP exists nowhere; BFE2 is the vanilla BFG blast)  (2 occurrences)
