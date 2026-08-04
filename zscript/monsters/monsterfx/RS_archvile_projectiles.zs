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

// ---------------------------------------------------------------------
// RS_WVileEye -- the White Archvile's floating eyes. Ported from CH
// Archviles.txt (WVileEye1). They hover in a ring around the summoner,
// then commit: drop the noclip, accelerate, and home in weaving.
//
// CH gated the charge on an inventory token handed out by an ACS chain
// (WVEyeGo). Rebuilt as a plain tic countdown instead -- same read for
// the player (a beat of menace, then they come at you), no ACS.
// Sprites WVEY (imported) + SSUL burst.
// ---------------------------------------------------------------------
class RS_WVileEye : Actor
{
	Default
	{
		Height 6;
		Radius 6;
		Damage (random(10, 40));
		Speed 0;
		Projectile;
		+SEEKERMISSILE
		+NOCLIP
		+SCREENSEEKER
		Scale 0.5;
		RenderStyle "Add";
		DeathSound "vile/firecrkl";
	}
	States
	{
	Spawn:
		WVEY FGO 7 Bright;
		WVEY P 2 Bright { A_SetScale(0.3, 0.5); }
	Orbit:
		// Hold station on the summoner. ~2.3s of hovering before the
		// commit, so the player sees them arrive and has a moment.
		WVEY P 1 Bright
		{
			A_Warp(AAPTR_TARGET, 2, random(-24, 24), random(42, 78), 0,
			       WARPF_NOCHECKPOSITION | WARPF_COPYVELOCITY);
		}
		WVEY P 3 Bright;
		WVEY P 1 Bright A_JumpIf(GetAge() > 80, "Charge");
		Loop;
	Charge:
		WVEY P 1 Bright { A_FaceTarget(); }
		WVEY P 1 Bright { bNOCLIP = false; }
		WVEY P 2 Bright { A_SetSpeed(21); }
	Fly:
		WVEY P 1 Bright { A_StartSound("fire/fire1", CHAN_BODY); }
		WVEY P 2 Bright { A_SeekerMissile(21, 30, SMF_LOOK); }
		WVEY P 2 Bright { A_Weave(1, 1, 1, 1); }
		Loop;
	Death:
		TNT1 A 0 { A_SetScale(1.0, 1.0); }
		SSUL ABCD 4 Bright;
		Stop;
	}
}

// =====================================================================
// CHP 14 REBUILD ADDITIONS
// ---------------------------------------------------------------------
// Everything below was ported when RS_Archvile was rebuilt straight from
// E:\New folder\ART SOURCE\CHP\DECORATE\14\14_<code>.txt (first ACTOR in
// each file = that tier's creature), falling back to the CH parent in
// CH\decorate\Archviles.txt for anything CHP inherits rather than
// defines. CHP's `_C` suffix is stripped and RS_ prefixed.
//
// Cruft stripped on the way in, per docs/rs_09_monster_rebuild_spec.txt:
// NewIcon*/ColorTierIcon* trackers, CHGore/CHRandom gib generators,
// A_GivetoChildren, CallACS/ACS_NamedExecuteAlways, RandomLetterSpawner,
// A_SpawnParticle walls, and the CHBoner/CHWhitePlan inventory gates.
// =====================================================================

// ---------- T00 COMMON: the plain vanilla pillar ----------
// CHP's ArchvileFire_C is a bare ": ArchvileFire" with no overrides.
class RS_ArchvileFire : ArchvileFire {}

// ---------- T02 BLUE: ambient plasma gash it sheds while it walks ----------
class RS_BlueGash : Actor
{
	Default { Radius 13; Height 8; Speed 0; +RANDOMIZE +NOGRAVITY +NOBLOCKMAP
		RenderStyle "Add"; Alpha 0.45; Scale 2.0; }
	States { Spawn: PLSS AB 6 Bright; Goto Death; Death: PLSE ABCDE 4; Stop; }
}

// ---------- SHARED: the resurrection ring ----------
// CH's ArchRingHelp -- a tiny crawler that A_VileChases corpses back up.
// Used by the blue heal, the abyss floor waves and the brown mass-revive.
class RS_ArchRingHelp : Actor
{
	Default
	{
		Health 9999; Radius 12; Height 2; Speed 4; Mass 5000;
		Monster;
		-COUNTKILL -SHOOTABLE -ACTIVATEMCROSS
		+NOTARGET +NEVERTARGET +THRUACTORS +NOCLIP +NOBLOOD +NOTELEPORT
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Goto See;
	See:
		RNGG A 3 Bright { A_VileChase(); }
		RNGG A 3 Bright { A_VileChase(); }
		RNGG A 3 Bright { A_VileChase(); }
		RNGG A 3 Bright { A_VileChase(); }
		Goto Death;
	Heal:
		BBOM CDE 2 Bright;
		Goto Death;
	Death:
		TNT1 A 2;
		Stop;
	}
}

// ---------- T05 YELLOW / T10 RED: the wandering summoner orb ----------
// CH's ArchSpawnerOrb. It drifts, finds line of sight, then drops a fire
// pillar and burns out. CH also rolled a random CH monster on burnout
// (RandomizerArc); the monster half is RS's job -- RS_Archvile calls
// RS_Conjure() in the same state -- so the orb only delivers the fire.
class RS_ArchSpawnerOrb : Actor
{
	Default
	{
		Health 13; Radius 17; Height 13; Speed 33; FloatSpeed 33; Mass 2;
		Scale 0.75; Alpha 0.95; RenderStyle "Add";
		Monster;
		-COUNTKILL -ACTIVATEMCROSS
		+NOGRAVITY +SPAWNFLOAT +NOBLOOD +LOOKALLAROUND +THRUACTORS
		+MISSILEMORE +MISSILEEVENMORE
		ActiveSound "vile/active";
	}
	States
	{
	Spawn:
		VIOB A 1 Bright { A_SetScale(0.75, 0.65); }
		VIOB B 1 Bright { A_Wander(); }
		VIOB C 1 Bright { A_Look(); }
		VIOB D 1 Bright { A_SetScale(0.75, 0.75); }
		VIOB E 3 Bright { A_Wander(); }
		VIOB F 1 Bright { A_Look(); }
		VIOB G 1 Bright { A_SetScale(0.65, 0.75); }
		VIOB H 1 Bright { A_Wander(); }
		VIOB I 1 Bright { A_Look(); }
		VIOB J 1 Bright { A_SetScale(0.65, 0.75); }
		Loop;
	See:
		VIOB A 1 Bright { A_SetScale(0.75, 0.65); }
		VIOB B 1 Bright { A_Wander(); }
		VIOB C 1 Bright { A_Chase(); }
		VIOB D 1 Bright { A_SetScale(0.75, 0.75); }
		VIOB E 3 Bright { A_Wander(); }
		VIOB F 1 Bright { A_Chase(); }
		VIOB G 1 Bright { A_SetScale(0.65, 0.75); }
		VIOB H 1 Bright { A_Wander(); }
		VIOB I 1 Bright { A_Chase(); }
		VIOB J 1 Bright { A_SetScale(0.65, 0.75); }
		Loop;
	Missile:
		VIOB A 1 Bright { A_SetSpeed(40); }
	Hunt:
		VIOB A 2 Bright { A_Wander(); }
		VIOB C 2 Bright;
		VIOB E 2 Bright A_CheckSight("FireIt");
		VIOB G 2 Bright { A_Wander(); }
		VIOB I 2 Bright;
		Goto Hunt;
	FireIt:
		VIOB B 1 { A_SpawnItemEx("RS_ArchvileFire", 0, 0, 3, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_Die(); }
		Stop;
	Death:
		MISL BCD 3 Bright;
		Stop;
	}
}

// ---------- T06 ABYSS: the floor-hugging bile waves ----------
class RS_SplashAbyssVile : Actor
{
	Default
	{
		Radius 12; Height 1; Speed 1; Damage (random(10, 30));
		Scale 1.7;
		+FLOORHUGGER +THRUACTORS +RANDOMIZE +DONTHARMCLASS +BOUNCEONWALLS
		BounceCount 999; BounceType "Doom"; BounceFactor 1.0; WallBounceFactor 1.0;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
	}
	States
	{
	Spawn:
		TNT1 A 0 { A_SetScale(1.7, 0.15); }
	Fly:
		BOGY ABC 4 Bright;
		TNT1 A 0 { A_SpawnItemEx("RS_ArchRingHelp", random(-24, 24), random(-28, 28), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		BOGY CBA 4 Bright;
		TNT1 A 0 { A_SetScale(1.6, 0.15); }
		BOGY BACBCA 4 Bright;
		TNT1 A 0 { A_SetScale(1.5, 0.15); }
		BOGY ABC 4 Bright;
		TNT1 A 0 { A_SpawnItemEx("RS_ArchRingHelp", random(-24, 24), random(-28, 28), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		BOGY CBA 4 Bright;
		TNT1 A 0 { A_SetScale(1.8, 0.15); }
		BOGY ABCCBA 4 Bright;
		Goto Death;
	Death:
		TNT1 A 0 { A_SpawnItemEx("RS_ArchRingHelp", random(-24, 24), random(-28, 28), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		BOGY DEF 6 Bright;
		Stop;
	}
}

class RS_SplashAbyssVile2 : Actor
{
	Default
	{
		Radius 1; Height 1; Speed 1; Scale 1.85;
		+FLOORHUGGER +THRUACTORS +RANDOMIZE +NOCLIP -COUNTKILL
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
	}
	States
	{
	Spawn:
		TNT1 A 0 { A_SetScale(1.85, 0.15); }
		BOGY ABC 6 Bright;
		Goto Death;
	Death:
		BOGY DEF 6 Bright;
		TNT1 A 0 { A_SpawnItemEx("RS_ABVileTentacle", 0, 0, 3, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Stop;
	}
}

// The tendril marker: bursts into four outward waves.
class RS_ABVileTend : Actor
{
	Default { Radius 1; Height 1; Speed 1; +FLOORHUGGER +THRUACTORS +NOCLIP -COUNTKILL
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyssVile2",  64,   0, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyssVile2",   0,  64, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyssVile2", -64,   0, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_SpawnItemEx("RS_SplashAbyssVile2",   0, -64, 1, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Stop;
	}
}

// What comes up out of the wave: a rooted tentacle that flails and spits.
class RS_ABVileTentacle : Actor
{
	Default
	{
		Health 30; Radius 32; Height 112; MeleeRange 128; Mass 0x7FFFFFFF;
		PainChance 96; Scale 0.55;
		Monster;
		-COUNTKILL
		+FLOORCLIP +DONTHURTSPECIES +LOOKALLAROUND +NOTARGET +THRUACTORS
		+MISSILEEVENMORE
		SeeSound "vile/sight"; PainSound "vile/pain";
		DeathSound "vile/death"; ActiveSound "vile/active";
		Obituary "%o was tentacle-taken.";
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
	}
	States
	{
	Spawn:
		TNT1 A 0 { A_Look(); }
	See:
		T6TE ABCDE 6;
	SeeLoop:
		T6TE EFGH 2 { A_Chase(); }
		T5TE F 2 A_Jump(4, "Death");
		Loop;
	Melee:
		T6TE I 2 { A_FaceTarget(); }
		T6TE JLMNOP 2 { A_CustomMeleeAttack(random(1, 7)); }
		T6TE Q 2 { A_FaceTarget(); }
		T6TE RTS 2 { A_CustomMeleeAttack(random(1, 7)); }
		T6TE UVWZ 2 { A_SpawnProjectile("RS_SplashAbyss2", 64, 0, random(-25, 25), CMF_OFFSETPITCH, random(-45, -5)); }
		Goto SeeLoop;
	Missile:
		T5TE ABC 3 { A_FaceTarget(); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 64, 0, random(-25, 25), CMF_OFFSETPITCH, random(-45, -5)); }
		T5TE DE 3 { A_FaceTarget(); }
		TNT1 AAAAAAAA 0 { A_SpawnProjectile("RS_SplashAbyss2", 64, 0, random(-15, 15), CMF_OFFSETPITCH, random(-45, -5)); }
		T5TE F 3;
		Goto SeeLoop;
	Pain:
		T6TE E 3;
		T6TE E 3 { A_Pain(); }
		Goto SeeLoop;
	Death:
		T6TE E 4;
		T6TE D 4 { A_Scream(); }
		T6TE C 4 { A_NoBlocking(); }
		T6TE BA 4;
		TNT1 AAAA 0 { A_SpawnItemEx("RS_SplashAbyssVile", random(-128, 128), random(-128, 128), 0, 1, 0, 1, random(-359, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(-128, 128), random(-128, 128), 0, 1, 0, 1, random(-359, 359), SXF_NOCHECKPOSITION); }
		Stop;
	}
}

// The mind-tangle burst: a quake, a shock, and a spread of black threads.
class RS_PsychicTangleAbyVile : Actor
{
	Default
	{
		Projectile; +NOBLOCKMAP +NOGRAVITY
		RenderStyle "Stencil"; StencilColor "Black"; Alpha 0.95; Scale 0.4;
		Damage (random(1, 10)); Mass 50; Speed 20;
		DeathSound "vile/stop";
	}
	States
	{
	Spawn:
	Death:
		TNT1 A 0 { A_Explode(1, 32); A_QuakeEx(2, 2, 2, 30, 0, 320, ""); }
		SPIR ABCDE 1 Bright { A_SpawnItemEx("RS_PsychicTangleAbyVile2", random(1, 8), random(-12, 12), random(0, 3), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR ABCDEABCDE 1 Bright { A_SpawnItemEx("RS_PsychicTangleAbyVile2", random(-12, 12), random(-28, 28), random(0, 12), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Stop;
	}
}

class RS_PsychicTangleAbyVile2 : Actor
{
	Default { Projectile; +NOBLOCKMAP +NOGRAVITY +NOINTERACTION
		RenderStyle "Stencil"; StencilColor "Black"; Alpha 0.95; Scale 0.2; }
	States
	{
	Spawn:
		T6TE ABCDE 1 Bright;
	Death:
		TNT1 AAA 0 { A_SpawnItemEx("RS_ArchRingHelp", random(-24, 24), random(-28, 28), 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		T6TE JLMNOP 3 Bright;
		Stop;
	}
}

// The abyss heal-ring (CH Barons.txt AbyssBaronRing).
class RS_AbyssBaronRing : Actor
{
	Default
	{
		Radius 6; Height 8; Speed 3; Projectile;
		+FLOORHUGGER +THRUACTORS +RANDOMIZE +NOINTERACTION
		RenderStyle "Add"; Alpha 0.75; Scale 2.0;
		SeeSound "vile/start";
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]";
	}
	States
	{
	Spawn:
		TNT1 A 0 { A_SetScale(2.0, 0.75); }
		RNGG ABCDABCDABCDABCDABCDABCD 3 Bright;
		Goto Death;
	Death:
		RNGG ABCD 4 Bright;
		Stop;
	}
}

// ---------- T07 FIREBLU: the pillar that bursts into a twelve-way fan ----------
class RS_FirebluVileFX : Actor
{
	Default
	{
		Radius 12; Height 16; Speed 1; Damage (random(5, 23)); DamageType "Fire";
		Projectile; +RANDOMIZE +THRUACTORS; RenderStyle "Add"; Alpha 0.85;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","160:160=177:177","162:162=184:184","163:163=204:204","164:164=186:186","165:165=204:204","166:166=189:189","167:167=207:207";
	}
	States
	{
	Spawn:
		FIRE AB 1 Bright;
		Goto Death;
	Death:
		FIRE CDE 4 { A_Explode(random(3, 10), 64); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 15,  CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 45,  CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 75,  CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 105, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 135, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 165, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 195, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 225, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 255, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 285, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 315, CMF_AIMDIRECTION); }
		MISL D 0 { A_SpawnProjectile("RS_FireSGguy2", 0, 0, 345, CMF_AIMDIRECTION); }
		FIRE FGH 6 Bright { A_Explode(random(3, 10), 64); }
		Stop;
	}
}

// ---------- T08 BROWN: the orbiting debris field ----------
class RS_BrownVileGas : Actor
{
	Default { Radius 8; Height 8; Speed 0; Projectile; +NOCLIP +FLOATBOB +NOINTERACTION; Scale 0.5;
		Translation "0:255=%[0.18,0.13,0.13]:[1.73,1.51,1.30]"; }
	States
	{
	Spawn:
		TNT1 A 0 A_Jump(255, "A1", "A2", "A3", "A4");
	A1:
		PSBG CDEFGHI 3 Bright;
		Stop;
	A2:
		TNT1 A 0 { A_SetScale(0.7, 0.25); }
		PSBG CDEFGHI 3 Bright;
		Stop;
	A3:
		TNT1 A 0 { A_SetScale(0.3, 0.6); }
		PSBG CDEFGHI 3 Bright;
		Stop;
	A4:
		PSBG IHGFEDCDEFGHI 3 Bright;
		Stop;
	}
}

// CH tracked the orbit angle in a user var; here it is a real field.
class RS_BrownVileRock : Actor
{
	private int rsOrbitAngle;

	Default { Radius 2; Height 2; Speed 12; Projectile; +FLOAT +NOGRAVITY +NOCLIP +NOINTERACTION;
		Scale 0.5; Translation "0:255=@50[128,64,0]"; }
	States
	{
	Spawn:
		JUBD A 0;
	Fly:
		TNT1 A 0 { A_SpawnItemEx("RS_BrownVileGas", random(-2, 2), random(-2, 2), random(-2, 2), 0, 0, 0, 0, SXF_NOCHECKPOSITION, 232); }
		TNT1 A 0 A_Jump(255, "A1", "A2", "A3", "A4");
		Loop;
	A1:
		JUBD A 2 Bright;
		Goto Orbit;
	A2:
		JUBD B 2 Bright;
		Goto Orbit;
	A3:
		JUBD C 2 Bright;
		Goto Orbit;
	A4:
		JUBD D 2 Bright;
		Goto Orbit;
	Orbit:
		TNT1 A 0
		{
			A_Warp(AAPTR_MASTER, 28, 0, 9, rsOrbitAngle,
			       WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE);
			rsOrbitAngle += 16;
		}
		Goto Fly;
	Death:
		TNT1 AA 0 { A_SpawnItemEx("RS_Drt1", random(-2, 2), random(-2, 2), 0, 1, 0, 3, random(0, 360)); }
		TNT1 AA 0 { A_SpawnItemEx("RS_Drt2", random(-2, 2), random(-2, 2), 0, 1, 0, 3, random(0, 360)); }
		TNT1 AA 0 { A_SpawnItemEx("RS_Drt3", random(-2, 2), random(-2, 2), 0, 1, 0, 3, random(0, 360)); }
		Stop;
	}
}

// The five-boulder barrage: each one chases, then charges like a skull.
class RS_BrownBoiVile : Actor
{
	Default
	{
		Radius 12; Height 12; Speed 25; Mass 200; Health 50;
		Damage (random(10, 55)); DamageType "Melee";
		Monster;
		-COUNTKILL
		+FLOAT +FLOATBOB +NOTARGETSWITCH +NOGRAVITY +LOOKALLAROUND
		+MISSILEMORE +MISSILEEVENMORE +NOPAIN +NOBLOOD +THRUSPECIES
		+BOUNCEONWALLS +BOUNCEONFLOORS +BOUNCEONCEILINGS +USEBOUNCESTATE
		BounceCount 1; BounceFactor 0.05; WallBounceFactor 0.05;
		Scale 1.6;
		SeeSound "vile/start"; DeathSound "weapons/rocklx";
		Translation "0:255=%[0.19,0.14,0.09]:[1.35,1.17,1.12]";
		Obituary "%o got rock and rolled.";
	}
	States
	{
	Spawn:
		GBLL A 3 Bright;
		Goto See;
	See:
		TNT1 A 0 A_CheckFloor("Death");
		GBLL A 6 Bright { A_Chase(); }
		GBLL B 6 Bright { A_Chase(); }
		GBLL C 6 Bright { A_Chase(); }
		Goto See;
	Missile:
		GBLL A 6 Bright { A_FaceTarget(); }
		GBLL B 6 Bright { A_FaceTarget(); }
		GBLL C 30 Bright { A_SkullAttack(45); }
		GBLL ABC 6 Bright;
		TNT1 A 0 A_CheckFloor("Death");
		GBLL A 6 Bright { A_FaceTarget(); }
		GBLL B 6 Bright { A_FaceTarget(); }
		GBLL C 30 Bright { A_SkullAttack(45); }
		TNT1 A 0 A_CheckFloor("Death");
		GBLL A 6 Bright { A_FaceTarget(); }
		GBLL B 6 Bright { A_FaceTarget(); }
		GBLL C 30 Bright { A_SkullAttack(45); }
		GBLL C 60 Bright;
		TNT1 A 0 A_CheckFloor("Death");
		GBLL C 30 Bright { A_SkullAttack(45); }
		GBLL C 60 Bright;
		Goto Death;
	Bounce:
	Bounce.Floor:
	Bounce.Actor:
	Bounce.Wall:
		TNT1 A 0;
		Goto Death;
	XDeath:
	Death:
		MISL B 0 { A_SetScale(0.5, 0.5); A_ChangeVelocity(0, 0, 12, CVF_RELATIVE); }
		TNT1 A 0 { A_Scream(); }
		MISL BC 6 Bright { A_Explode(random(8, 37), 64); }
		MISL D 5;
		Stop;
	}
}

// The brown vile's ally-shield handout. CH routed the actual rock spawn
// through an ACS command; here the pickup spawns them directly.
class RS_ShieldUpVile2 : CustomInventory
{
	Default { Radius 20; Height 16; +INVENTORY.AUTOACTIVATE +INVENTORY.ALWAYSPICKUP; }
	States
	{
	Pickup:
	Use:
		TNT1 AAAA 0 { A_SpawnItemEx("RS_BrownVileRock", 0, 0, 0, 0, 0, 0, 0, SXF_SETMASTER, 128); }
		Stop;
	}
}

// Healing motes it throws over its friends.
class RS_MediCacoBrown : Actor
{
	Default { Radius 2; Height 2; Mass 7; Speed 4; Projectile; +THRUACTORS +NOINTERACTION;
		Scale 0.45; RenderStyle "Add"; Alpha 0.33;
		Translation "208:223=176:191","224:231=176:176"; }
	States
	{
	Spawn:
		BAL1 AB 6;
		Goto Death;
	Death:
		BAL1 A 1 { A_SetTranslucent(0.1); }
		Stop;
	}
}

// What is left when the Wicked robe collapses.
class RS_WickedTorso : Actor
{
	Default { Mass 1000000; Radius 1; Height 1; +ISMONSTER +CORPSE +NOBLOCKMAP; }
	States
	{
	Spawn:
		WICK Q 5 NoDelay;
		WICK R 5;
		Wait;
	Crash:
		WICK S 1 { A_SetFloorClip(); }
		WICK S 4;
		WICK TUV 5;
		WICK W -1;
		Stop;
	}
}

// ---------- T10 RED: the Grand Redfirevile pillar ----------
class RS_ReAFireNew : Actor
{
	Default { Radius 0; Height 1; Speed 0; RenderStyle "Add"; DamageType "Fire"; Alpha 1.0;
		+NOGRAVITY +SEEKERMISSILE +NOTARGET +NODAMAGETHRUST; }
	States
	{
	Spawn:
		HLFR A 0 { A_StartSound("vile/firestrt", CHAN_BODY); }
		HLFR ABABAB 2 Bright { A_Fire(); }
		HLFR C 0 { A_StartSound("vile/firecrkl", CHAN_BODY); }
		HLFR CBCBCBCDCDCD 2 Bright { A_Fire(); }
		HLFR E 0 { A_StartSound("vile/firecrkl", CHAN_BODY); }
		HLFR CDEDEDEDEFEF 2 Bright { A_Fire(); }
		HLFR E 0 { A_StartSound("vile/firecrkl", CHAN_BODY); }
		HLFR EFEFGHGHGHGH 2 Bright { A_Fire(); }
		Stop;
	}
}

// ---------- T11 BLACK: the void shroud and its ordnance ----------
class RS_BVileCloud2 : Actor
{
	Default { Radius 20; Height 56; Speed 2; RenderStyle "Stencil"; StencilColor "Black";
		Alpha 1.0; Projectile; +NOCLIP +NOINTERACTION; }
	States
	{
	Spawn:
		VILE A 1;
		VILE B 1 { A_FadeOut(0.15); }
		VILE C 1;
		VILE D 1 { A_FadeOut(0.15); }
		VILE C 1;
		VILE E 1 { A_FadeOut(0.15); }
		VILE E 1;
		VILE F 1 { A_FadeOut(0.15); }
		VILE F 1;
		Stop;
	}
}

class RS_BVileOrb2 : Actor
{
	Default { Radius 8; Height 9; Speed 2; Projectile; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.85; Scale 0.85;
		Translation "32:47=0:0","168:191=5:8","208:223=109:112","231:231=250:250"; }
	States
	{
	Spawn:
		BAL2 AB 6 Bright;
		Goto Death;
	Death:
		BAL2 A 6 Bright { A_SetScale(0.6, 0.6); }
		BAL2 B 6 Bright { A_SetScale(0.35, 0.35); }
		BAL2 A 6 Bright { A_SetScale(0.2, 0.2); }
		Stop;
	}
}

class RS_BVileOrb1 : Actor
{
	Default
	{
		Radius 8; Height 9; Speed 6; Damage (random(12, 45)); DamageType "Fire";
		Projectile; +BOUNCEONWALLS;
		BounceFactor 1.2; BounceType "Hexen"; WallBounceFactor 1.2; BounceCount 6;
		SeeSound "caco/attack"; DeathSound "caco/shotx";
		Translation "32:47=0:0","168:191=5:8","208:223=109:112","231:231=250:250";
	}
	States
	{
	Spawn:
		BAL2 A 6 Bright;
	Fly:
		BAL2 AB 8 Bright { A_SpawnItemEx("RS_BVileOrb2", 0, 0, 1); }
		Loop;
	Death:
		BAL2 C 6 Bright { A_SetScale(2.0, 2.0); }
		BAL2 DE 6 Bright { A_Explode(random(12, 64), 64); }
		Stop;
	}
}

class RS_DFlamePuffVile : Actor
{
	Default { Radius 1; Height 1; Speed 8; RenderStyle "Add"; Alpha 1.0; Projectile;
		+FLOORHUGGER -NOGRAVITY +DONTSPLASH +NOINTERACTION +THRUACTORS; Scale 1.0;
		Translation "32:47=0:0","176:191=5:8","208:223=104:111","224:231=105:105","160:167=103:103"; }
	States { Spawn: FTRA ABCDEFGHIJ 4 Bright { A_SetAngle(random(-360, 360)); } Stop; }
}

class RS_DFlamePuffVile2 : Actor
{
	Default { Radius 1; Height 1; Speed 7; RenderStyle "Add"; Alpha 1.0; Projectile;
		-NOGRAVITY +FLOATBOB +DONTSPLASH +NOINTERACTION +THRUACTORS; Scale 1.0;
		Translation "32:47=0:0","176:191=5:8","208:223=104:111","224:231=105:105","160:167=103:103"; }
	States { Spawn: FTRA ABCDEFGHIJ 4 Bright; Stop; }
}

class RS_DFlameBoomVile : Actor
{
	Default { Radius 8; Height 8; Speed 4; DamageType "Fire"; Projectile; +FLOATBOB +THRUACTORS;
		Scale 0.75;
		Translation "32:47=0:0","176:191=5:8","208:223=104:111","224:231=105:105","160:167=103:103"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		MISL B 8 Bright { A_Explode(random(12, 42), 42); }
		MISL C 6 Bright { A_StartSound("weapons/rocklx", CHAN_BODY); }
		MISL D 4 Bright;
		Stop;
	}
}

class RS_DarkFlameTrailVile : Actor
{
	Default { Radius 12; Height 1; Speed 0; +NOBLOCKMAP +NOINTERACTION; RenderStyle "Add"; Alpha 0.7;
		Translation "32:47=0:0","176:191=5:8","208:223=104:111","224:231=105:105","160:167=103:103"; }
	States { Spawn: FTRA KLMNO 3 Bright; Stop; }
}

// The floor-crawling dark flame that hunts you down a corridor.
class RS_DarkFlameVile : Actor
{
	Default
	{
		Radius 4; Height 4; Speed 7; DamageType "Fire"; Projectile;
		+FLOORHUGGER -NOGRAVITY +DONTSPLASH +THRUACTORS +SEEKERMISSILE;
		Scale 1.5; SeeSound "vile/start";
		Translation "32:47=0:0","176:191=5:8","208:223=104:111","224:231=105:105","160:167=103:103";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		FTRA C 1 Bright { A_SeekerMissile(0, 1); }
		FTRA C 1 Bright { A_Explode(random(4, 20), 32); }
		FTRA C 0 { A_SpawnItemEx("RS_DarkFlameTrailVile", 0, 0, 1); }
		FTRA C 0 { A_SpawnItemEx("RS_DFlamePuffVile", random(-16, 16), random(-16, 16), 1, 0, 0, 0, random(-180, 180), SXF_NOCHECKPOSITION); }
		FTRA C 1 Bright { A_SeekerMissile(1, 3); }
		FTRA D 1 Bright { A_Explode(random(4, 20), 32); }
		FTRA C 0 { A_SpawnItemEx("RS_DarkFlameTrailVile", 0, 0, 1); }
		FTRA E 1 Bright { A_SeekerMissile(1, 3); }
		FTRA F 1 Bright { A_Explode(random(4, 20), 32); }
		FTRA C 0 { A_SpawnItemEx("RS_DFlamePuffVile", random(-16, 16), random(-16, 16), 1, 0, 0, 0, random(-180, 180), SXF_NOCHECKPOSITION); }
		FTRA E 1 Bright { A_SeekerMissile(1, 3); }
		FTRA D 1 Bright { A_Explode(random(4, 20), 32); }
		Loop;
	Death:
		FTRA GHIJ 2 Bright { A_SpawnItemEx("RS_DFlameBoomVile", random(-128, 128), random(-128, 128), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_DarkFlameTrailVile", random(-32, 32), random(-32, 32), 1); }
		Stop;
	}
}

// ---------- T12 WHITE: the resurrection field, its spots, and the quake ----------
class RS_WhiteVileResser : Actor
{
	Default
	{
		Health 9999; Radius 32; Height 1; Speed 9; Mass 90000; Scale 1.25;
		Monster;
		-COUNTKILL -SHOOTABLE -ACTIVATEMCROSS
		+LOOKALLAROUND +NOTARGET +NEVERTARGET +THRUACTORS +NOCLIP +NOBLOOD
		RenderStyle "Translucent"; Alpha 0.01;
		Translation "32:47=0:0","176:191=5:8","208:223=104:111","224:231=105:105","160:167=103:103";
	}
	States
	{
	Spawn:
		RNGG A 0;
		Goto See;
	See:
		FTRA CDEFGH 12 Bright { A_Chase(null, null, CHF_RESURRECT); }
		FTRA IJ 3;
		Goto Death;
	Heal:
		FTRA IJ 1 Bright;
		Goto Death;
	Death:
		TNT1 A 0;
		Stop;
	}
}

class RS_WVileSpot : Actor
{
	private int rsSpotCharge;

	Default
	{
		Radius 12; Height 12; Health 9999; Speed 0; Mass 255;
		Monster;
		-COUNTKILL -SHOOTABLE -ACTIVATEMCROSS
		+INVULNERABLE +NOBLOOD +LOOKALLAROUND +NOTARGET +NEVERTARGET
		+THRUACTORS +MISSILEMORE +MISSILEEVENMORE
		RenderStyle "Stencil"; StencilColor "Black"; Alpha 1.0; Scale 0.75;
		SeeSound "vile/start";
	}
	States
	{
	Spawn:
		RNGG A 0;
	Charge:
		RNGG A 5 Bright;
		RNGG B 5 Bright { A_Chase(); }
		RNGG C 5 Bright { A_Chase(); }
		RNGG C 5 Bright { A_Chase(); }
		RNGG D 1 Bright { A_SpawnItemEx("RS_WhiteVileResser", 0, 0, 3, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		RNGG D 1 Bright { rsSpotCharge++; }
		RNGG D 5 Bright { if (rsSpotCharge >= 20) return ResolveState("Death"); return ResolveState(null); }
		Goto Charge;
	Death:
		TNT1 A 0;
		Stop;
	}
}

class RS_BrightUpVile2 : Actor
{
	Default { Projectile; +NOBLOCKMAP +NOGRAVITY +ALLOWPARTICLES;
		RenderStyle "Stencil"; StencilColor "White"; Alpha 0.95;
		Damage (random(5, 30)); Scale 1.0; Speed 2; Mass 50; DeathSound "vile/stop"; }
	States
	{
	Spawn:
		SPIR ABCDEABCDE 6 Bright { A_Explode(random(1, 3), 32); }
		SPIR ABCDE 6 Bright { A_Explode(random(1, 3), 32); }
	Death:
		SPIR ABCDE 6 Bright { A_Explode(random(1, 3), 32); }
		Stop;
	}
}

class RS_WVileQuake : Actor
{
	Default { Radius 1; Height 1; Speed 10; Mass 9999; Projectile; -NOGRAVITY;
		RenderStyle "Add"; Scale 1.0; Alpha 0.3; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		TNT1 A 20 Bright { A_QuakeEx(3, 3, 3, 90, 0, 900, ""); }
		TNT1 A 0 { A_VileTarget("RS_BrightUpVile2"); }
		TNT1 A 20 Bright { A_QuakeEx(4, 4, 4, 90, 0, 1200, ""); }
		TNT1 A 0 { A_VileTarget("RS_BrightUpVile2"); }
		TNT1 A 20 Bright { A_QuakeEx(5, 5, 5, 90, 0, 3000, ""); }
		TNT1 A 0 { A_VileTarget("RS_BrightUpVile2"); }
		Stop;
	}
}

// =====================================================================
// TEX BLACK-EX -- the tornado vile's kit (CHP 14_KX).
// ---------------------------------------------------------------------
// Ported verbatim from CHP\DECORATE\14\14_KX.txt (the _C colour, which
// is the one RS_Archvile's TEX cluster fires). Nothing here is shared
// with the T11 black vile -- the EX is a wind/leaf creature and every
// piece below is its own actor in CHP too.
// =====================================================================

// ---------- the dust it sheds constantly ----------
// Solid-looking but it IS a projectile with a melee-typed contact hit --
// walking through the vile's own wake costs you.
class RS_BVileEXCloud : Actor
{
	Default
	{
		Radius 20; Height 56; Speed 4;
		Damage (random(5, 15));
		DamageType "Melee";
		+FLOATBOB
		RenderStyle "Stencil"; Alpha 0.9;
		Projectile;
	}
	States
	{
	Spawn:
		"SILE" A 1;
		"SILE" B 1 { A_FadeOut(0.15); }
		"SILE" C 1;
		"SILE" D 1 { A_FadeOut(0.15); }
		"SILE" C 1;
		"SILE" E 1 { A_FadeOut(0.15); }
		"SILE" E 1;
		"SILE" F 1 { A_FadeOut(0.15); }
		"SILE" F 1 { A_SpawnItemEx("RS_ArchRingHelp", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION, 224); }
		Stop;
	Death:
		"SILE" G 1;
		"SILE" I 1 { A_FadeOut(0.15); }
		"SILE" I 1;
		"SILE" H 1 { A_FadeOut(0.15); }
		"SILE" G 1;
		"SILE" H 1 { A_FadeOut(0.15); }
		"SILE" H 1;
		"SILE" I 1 { A_FadeOut(0.15); }
		"SILE" I 1 { A_SpawnItemEx("RS_ArchRingHelp", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION, 224); }
		Stop;
	}
}

// The burst-out variant: CHP stacks Spawn on Death so it plays the
// dissipation animation immediately instead of the drift.
class RS_BVileEXCloud2 : RS_BVileEXCloud
{
	States
	{
	Spawn:
	Death:
		"SILE" G 1;
		"SILE" I 1 { A_FadeOut(0.15); }
		"SILE" I 1;
		"SILE" H 1 { A_FadeOut(0.15); }
		"SILE" G 1;
		"SILE" H 1 { A_FadeOut(0.15); }
		"SILE" H 1;
		"SILE" I 1 { A_FadeOut(0.15); }
		"SILE" I 1 { A_SpawnItemEx("RS_ArchRingHelp", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION, 224); }
		Stop;
	}
}

// The in-tornado variant -- same body, FX07 funnel art.
class RS_BVileEXCloud5 : RS_BVileEXCloud
{
	States
	{
	Spawn:
	Death:
		FX07 A 1;
		FX07 C 1 { A_FadeOut(0.15); }
		FX07 C 1;
		FX07 B 1 { A_FadeOut(0.15); }
		FX07 A 1;
		FX07 B 1 { A_FadeOut(0.15); }
		FX07 B 1;
		FX07 C 1 { A_FadeOut(0.15); }
		FX07 C 1 { A_SpawnItemEx("RS_ArchRingHelp", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION, 224); }
		Stop;
	}
}

// ---------- the leaves ----------
// Thrown in sheets by the wind moves. They accelerate ONCE, hard and
// randomly (A_ScaleVelocity), which is what makes the storm read as
// chaotic rather than as a fan.
class RS_Leaves1 : Actor
{
	Default
	{
		Radius 8; Height 16; Speed 1; Damage 3;
		Projectile;
		+RANDOMIZE +NOGRAVITY +FLOAT
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		LEF1 ABC 4 Bright;
		TNT1 A 0 { A_ScaleVelocity(random(5, 35)); }
		LEF1 DEFGHIABCDEFGHIABCDEFGHIABCDEFGHIABCDEFGHI 4 Bright;
		Goto Death;
	Death:
		LEF1 A 1 Bright;
		Stop;
	}
}

class RS_Leaves2 : Actor
{
	Default
	{
		Radius 8; Height 16; Speed 1; Damage 2;
		Projectile;
		+RANDOMIZE +NOGRAVITY +FLOAT
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		LEF2 ABC 4 Bright;
		TNT1 A 0 { A_ScaleVelocity(random(5, 20)); }
		LEF2 DEFGHIABCDEFGHIABCDEFGHIABCDEFGHIABCDEFGHI 4 Bright;
		Goto Death;
	Death:
		LEF2 A 1 Bright;
		Stop;
	}
}

// ---------- the tornado ----------
// A floor-hugging funnel that keeps exploding and shedding leaves for as
// long as it lives, then shrinks out. THRUACTORS -- it passes through
// bodies rather than stopping on the first one it touches.
class RS_BVileEXTornado : Actor
{
	Default
	{
		Radius 16; Height 16; Speed 18;
		RenderStyle "Translucent"; Alpha 0.6;
		SeeSound "tornado/form";
		Projectile;
		+RANDOMIZE +NOGRAVITY +FLOAT +THRUACTORS +FLOORHUGGER
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		FX07 A 4 Bright { A_Explode(random(5, 25), 70, 0); }
		FX07 AAA 0 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-32, 32), random(0, 360), 0, random(-5, 5)); }
		FX07 B 4 Bright { A_Explode(random(5, 25), 70, 0); }
		FX07 BBB 0 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-32, 32), random(0, 360), 0, random(-5, 5)); }
		FX07 C 4 Bright { A_Explode(random(5, 25), 70, 0); }
		FX07 CCC 0 { A_SpawnProjectile("RS_Leaves1", random(16, 64), random(-32, 32), random(0, 360), 0, random(-5, 5)); }
		Loop;
	Death:
		FX07 A 0 { A_Explode(random(5, 20), 50, 0); }
		FX07 A 4 Bright { A_SetScale(0.95, 0.8); }
		FX07 A 0 { A_Explode(random(5, 15), 40, 0); }
		FX07 B 4 Bright { A_SetScale(0.9, 0.6); }
		FX07 A 0 { A_Explode(random(5, 10), 30, 0); }
		FX07 C 4 Bright { A_SetScale(0.85, 0.4); }
		FX07 A 4 Bright { A_SetScale(0.8, 0.2); }
		FX07 B 4 Bright { A_SetScale(0.75, 0.1); }
		Stop;
	}
}

// ---------- the darkness token ----------
// CHP 16_K's BlackMindDarknessToken: a stacking screen-darkener the
// shadow waves hand out on contact. Additive time, so standing in the
// storm keeps you blind.
class RS_BlackMindDarknessToken : Powerup
{
	Default
	{
		Powerup.Color "00 00 00", 0.5;
		Powerup.Duration 60;
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
		+INVENTORY.ADDITIVETIME
		+INVENTORY.NOSCREENBLINK
	}
}

// ---------- the shadow waves ----------
// RS_BVileEXWAVE is the stationary ripper the seeker leaves behind it;
// RS_BVileEXWAVE3 is the thrown one that also blinds.
class RS_BVileEXWAVE : Actor
{
	Default
	{
		Radius 10; Height 10; Speed 0;
		SeeSound "queen/fire";
		Projectile;
		+NOCLIP +RIPPER
		Damage (random(1, 3));
		DamageType "Plasma";
		RenderStyle "Stencil";
		StencilColor "00 00 00";
	}
	States
	{
	Spawn:
		TNT1 A 4 { A_Explode(random(2, 7), 64); }
		BLST ABCD 1 Bright { A_FadeOut(0.0625); }
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		BLST EFGHI 1 Bright { A_FadeOut(0.0625); }
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		BLST JKLMN 1 Bright { A_FadeOut(0.0625); }
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		BLST OP 1 Bright { A_FadeOut(0.0625); }
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		Stop;
	}
}

class RS_BVileEXWAVE3 : FastProjectile
{
	Default
	{
		Radius 10; Height 10; Speed 15;
		SeeSound "queen/fire";
		Projectile;
		Damage 0;
		DamageType "Melee";
		RenderStyle "Stencil"; Alpha 0.65; Scale 0.3;
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		TNT1 A 0 { A_ScaleVelocity(frandom(0.65, 1.33)); }
	Fly.Loop:
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		BLST ABCD 1 Bright;
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		BLST EFGHI 1 Bright;
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		BLST JKLMN 1 Bright;
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		BLST OP 1 Bright;
		TNT1 A 0 { A_Explode(random(2, 7), 64); }
		TNT1 A 0 { A_RadiusGive("RS_BlackMindDarknessToken", 24, RGF_PLAYERS, 1); }
		Goto Fly.Loop;
	Death:
		TNT1 A 0;
		TNT1 A 0 { A_RadiusGive("RS_BlackMindDarknessToken", 42, RGF_PLAYERS, 1); }
		BLST A 1 Bright { A_SetScale(0.4, 0.4); }
		BLST B 1 Bright { A_Explode(random(4, 14), 64); }
		BLST CDEF 1 Bright { A_SetScale(0.6, 0.6); }
		BLST F 0 { A_Explode(random(6, 16), 78); }
		BLST FGHI 1 Bright { A_SetScale(0.8, 0.8); }
		BLST I 0 { A_Explode(random(8, 18), 94); }
		BLST JKLMOP 1 Bright { A_SetScale(1.0, 1.0); }
		Stop;
	}
}

// ---------- the seeker ----------
// Invisible in flight (TNT1) -- what you actually see is the trail of
// RS_BVileEXWAVE it drops every other tic. Detonates big.
class RS_BVileEXMindWave : FastProjectile
{
	Default
	{
		Radius 8; Height 8; Speed 12;
		Damage (random(30, 80));
		Projectile;
		+SEEKERMISSILE
		DamageType "Plasma";
		RenderStyle "Stencil";
		SeeSound "queen/fire";
		DeathSound "queen/hit";
		Decal "SwordLightning";
		StencilColor "00 00 00";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 2 Bright { A_SeekerMissile(3, 6); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(4, 8); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(4, 8); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(4, 8); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(3, 9); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(4, 8); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(6, 6); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(6, 6); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(6, 12); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		TNT1 A 2 Bright { A_SeekerMissile(6, 12); }
		TNT1 A 0 { A_SpawnItemEx("RS_BVileEXWAVE", 0, 0, 0, 0, 0, 0, 0, 32); }
		Loop;
	Death:
		// CHP: Radius_Quake(15, 15, 0, 40, 0) -- intensity 15, 15 tics,
		// no damage radius, tremor radius 40 (x64 map units).
		BLST A 0 { A_QuakeEx(15, 15, 15, 15, 0, 2560, ""); }
		BLST A 1 Bright { A_SetScale(1.2, 1.2); }
		BLST B 1 Bright { A_Explode(random(11, 50), 110); }
		BLST CDEF 1 Bright { A_SetScale(1.4, 1.4); }
		BLST F 0 { A_Explode(random(9, 40), 130); }
		BLST FGHI 1 Bright { A_SetScale(1.7, 1.7); }
		BLST I 0 { A_Explode(random(7, 30), 150); }
		BLST JKLM 1 Bright { A_SetScale(2, 2); }
		BLST OP 1 Bright { A_Explode(random(5, 20), 170); }
		Stop;
	}
}

// --- CHP-14 IMPORT CORRECTIONS ------------------------------------
//   * RS_ArchRingHelp drops the CH +INVISIBLE flag -- with it, the ring
//     sprite the actor exists to draw never appears. Rest is verbatim.
//   * RS_ArchSpawnerOrb no longer rolls a random CH monster on burnout
//     (CH RandomizerArc). RS_Archvile calls RS_Conjure() in the same
//     state, so the summon still happens -- through the RS live cap and
//     tier-offset economy instead of an unbounded spawner.
//   * The CH GrowRaisin corpse token has no RS equivalent, so the
//     A_RadiusGive calls that handed it out are dropped. Resurrection
//     itself is unaffected: it runs off A_VileChase / CHF_RESURRECT.
//   * A_SpawnParticle walls (WVileEye1, BrightUpVile2, WVileBolt1,
//     WVileSpot) are dropped per the rebuild spec.
//   * CHP WVileEye1_C maps to the existing RS_WVileEye above -- the same
//     actor, already ported, with the ACS token replaced by a countdown.
// ------------------------------------------------------------------
