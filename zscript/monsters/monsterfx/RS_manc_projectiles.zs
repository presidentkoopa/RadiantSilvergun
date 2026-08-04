// =====================================================================
// RS_manc_projectiles.zs
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
// hf_manc_projectiles.zs -- Mancubus projectiles (color ladder).
// Neutral + many colors use stock A_FatAttack (dual-fireball volley) -> no custom projectile.
// Heavier colors have real shots below. Owns RS_RocketShotFatso, which the
// Arachnotron's BSP2 tier also fires (same actor in CH/CHP -- see below).
// SlowChunks gib-cosmetic dropped -> cosmetic pass. Damage->constants.
// ============================================================================

// ---------- YELLOW: seeking fatso shots (INCB body) ----------
class RS_FatsoShotYE : Actor
{
	Default { Radius 12; Height 12; Speed 14; FastSpeed 19; Damage 25; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 1; Scale 0.65;
		SeeSound "fatso/attack"; DeathSound "fatso/shotx"; Translation "0:255=%[1.00,0.80,0.00]:[2.00,1.60,0.40]"; }
	States
	{
	Spawn:
		MANF AB 4 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		MANF CDE 5 Bright A_Explode(25,48);
		Stop;
	}
}

// ---------- ABYSS: bouncing ice bombs + plasma wave (UNMB body) ----------
class RS_AbyssFatsoBomb : Actor
{
	Default { Radius 7; Height 7; Speed 28; Damage 50; DamageType "Ice"; Projectile; +USEBOUNCESTATE; +BOUNCEONWALLS; BounceFactor 1.1; BounceCount 3; WallBounceFactor 1.1;
		BounceType "Doom"; RenderStyle "Add"; Alpha 0.9; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States { Spawn: BAL2 AB 3 Bright; Loop; Death: BAL2 CDE 4 Bright A_Explode(50,80); Stop; }
}
class RS_FatAbysswave : Actor
{
	Default { Radius 20; Height 16; Speed 25; Damage 35; DamageType "Plasma"; Projectile; +MTHRUSPECIES; +DONTHARMCLASS; RenderStyle "Add"; Alpha 1; XScale 1.0; YScale 0.5;
		SeeSound "Crack/see"; DeathSound "Crack/death"; Translation "Ice"; }
	States { Spawn: BFE1 AB 3 Bright; Loop; Death: BFE1 CDE 4 Bright A_Explode(35,96); Stop; }
}

// ---------- FIREBLU: fireblu balls (small spray + big bomb) (HBST body) ----------
class RS_FireBluFatsoBal1 : Actor
{
	Default { Radius 3; Height 3; Speed 45; Damage 15; DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 0.95; Scale 0.33;
		SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States { Spawn: FIRE AB 2 Bright; Loop; Death: FIRE CDE 3 Bright; Stop; }
}
class RS_FireBluFatsoBal2 : Actor
{
	Default { Radius 20; Height 20; Mass 600; Speed 8; Damage 30; DamageType "Plasma"; Projectile; Scale 1.5; RenderStyle "Add"; Alpha 0.95;
		SeeSound "Spell/spellCast1"; DeathSound "weapons/rocklx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States { Spawn: BAL1 AB 3 Bright; Loop; Death: BAL1 CDE 5 Bright A_Explode(60,128); Stop; }
}
class RS_HBeastSmoke : Actor
{
	Default { Radius 0; Height 0; Speed 0; Alpha 0.3; Scale 0.55; Projectile; RenderStyle "Add"; }
	States { Spawn: BISH QRSTUVW 3; BISH W 3 A_FadeOut(0.5); Stop; }
}

// ---------- BROWN: yellow zap orb (FFAT body) ----------
// RS_ZapFFAT2 lives further down with the rest of the zap arc -- that copy is
// the CH Fatsos.txt one. The earlier sketch here looped its Fly state forever
// on A_Explode, which CH's version does not do.

// ---------- RED: "Hell Beast" floor-hugging shots + spray (HBST body) ----------
class RS_HBeastShot : Actor
{
	// FLOOR-HUGGER (pattern #4) -- crawls the ground toward the target
	Default { Radius 2; Height 3; Speed 23; Alpha 0.8; Projectile; RenderStyle "Add"; DamageType "Fire"; Damage 22; +FLOORHUGGER; -NOBLOCKMAP;
		SeeSound "horn/attack"; DeathSound "horn/shotx"; }
	States { Spawn: BFS1 AB 3 Bright; Loop; Death: BFS1 CDE 4 Bright A_Explode(22,48); Stop; }
}
class RS_Shot2Fatso : Actor
{
	Default { Radius 7; Height 9; Scale 1.15; Speed 24; Damage 8; Projectile; DamageType "Fire"; RenderStyle "Add"; Alpha 0.95;
		SeeSound "fatso/attack"; DeathSound "fatso/shotx"; }
	States { Spawn: MANF AB 4 Bright; Loop; Death: MANF CDE 5 Bright A_Explode(20,64); Stop; }
}
// (RS_SparkPuff1 already defined in hf_hk_projectiles.zs -- shared)

// ---------- BLACK: "Shadow Beast" (BDEM, HP9001) -- poison balls, ripping fire,
//            big bombs, floor-hugging splash, long-range shots ----------
class RS_BlackFatShotLongRange : Actor
{
	Default { Radius 7; Height 6; Speed 42; Damage 50; DamageType "Fire"; Projectile; RenderStyle "Add"; Alpha 1; Scale 1.25;
		SeeSound "fatso/attack"; DeathSound "fatso/shotx"; }
	States { Spawn: MANF AB 3 Bright; Loop; Death: MANF CDE 4 Bright A_Explode(50,80); Stop; }
}
class RS_ShadowBeast_Ball1 : Actor
{
	Default { Alpha 1.0; RenderStyle "Add"; Speed 15; Radius 10; Height 6; Damage 35; DamageType "Poison"; Projectile; SeeSound "shadowbeast/pr1sit"; DeathSound "shadowbeast/pr1death";
		Translation "0:255=%[0.30,0.00,0.40]:[1.20,0.40,1.60]"; }
	States { Spawn: BDP1 AB 3 Bright; Loop; Death: BDP1 CDE 4 Bright A_Explode(35,64); Stop; }
}
class RS_ShadowBeast_Ball2 : RS_ShadowBeast_Ball1 { Default { Radius 8; Speed 16; Damage 27; DamageType "Plasma"; } }
class RS_ShadowBeast_Ball3 : RS_ShadowBeast_Ball1 { Default { Scale 1.4; Radius 8; Speed 20; Damage 40; DamageType "Plasma"; } }
class RS_ShadowBeast_BallFire : Actor
{
	Default { Alpha 1.0; RenderStyle "Add"; Speed 15; Radius 10; Height 6; Damage 3; DamageType "Poison"; Projectile; +RIPPER; +THRUACTORS;
		SeeSound "shadowbeast/pr1sit"; DeathSound "shadowbeast/pr1death"; Translation "0:255=%[0.30,0.00,0.40]:[1.20,0.40,1.60]"; }
	States { Spawn: BDP2 AB 3 Bright; Loop; Death: BDP2 CD 3 Bright; Stop; }
}
class RS_ShadowBombBig : Actor
{
	Default { Alpha 1.0; RenderStyle "Add"; Speed 8; Radius 14; Height 9; Damage 50; Scale 1.8; DamageType "Plasma"; Projectile;
		SeeSound "shadowbeast/pr2sit"; DeathSound "shadowbeast/pr2death"; Translation "0:255=%[0.30,0.00,0.40]:[1.20,0.40,1.60]"; }
	States { Spawn: BDP2 AB 4 Bright; Loop; Death: BDP2 CDE 5 Bright A_Explode(80,128); Stop; }
}
class RS_ShadowSplash : Actor
{
	// floor-hugging bouncing splash
	Default { Radius 6; Height 8; Speed 23; Mass 25; Damage 15; Projectile; +FLOORHUGGER; +THRUACTORS; +RANDOMIZE; +BOUNCEONWALLS; BounceCount 999; BounceType "Doom"; BounceFactor 0.9;
		RenderStyle "Add"; Alpha 0.85; DamageType "Plasma"; Translation "0:255=%[0.30,0.00,0.40]:[1.20,0.40,1.60]"; }
	States { Spawn: BDP1 AB 3 Bright; Loop; Death: BDP1 CD 3 Bright; Stop; }
}

// ---------- WHITE: "Queen" (QUEE, HP15000) -- 7 seeking fat-balls + scatter ----------
class RS_WhiteFatBall1 : Actor
{
	Default { Radius 9; Height 9; Speed 21; Damage 35; DamageType "Fire"; Projectile; Scale 1.5; +DONTHARMCLASS; +SEEKERMISSILE; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States { Spawn: MANF AB 3 Bright A_SeekerMissile(3,3); Loop; Death: MANF CDE 4 Bright A_Explode(35,64); Stop; }
}
class RS_WhiteFatBall2 : RS_WhiteFatBall1 { Default { Speed 11; } }
class RS_WhiteFatBall3 : RS_WhiteFatBall1 { Default { Speed 25; } }
class RS_WhiteFatBall4 : RS_WhiteFatBall1 { Default { Speed 15; Scale 1.2; } }
class RS_WhiteFatBall5 : RS_WhiteFatBall1 { Default { Speed 28; Scale 1.0; } }
class RS_WhiteFatBall6 : RS_WhiteFatBall1 { Default { Speed 18; Scale 1.7; } }
class RS_WhiteFatBall7 : RS_WhiteFatBall1 { Default { Speed 23; Scale 0.9; } }
class RS_WhiteFatScatter : Actor
{
	Default { Radius 8; Height 8; Speed 26; Damage 20; DamageType "Melee"; Projectile; +DONTHARMCLASS; XScale 0.77; YScale 0.33;
		SeeSound "imp/attack"; DeathSound "spit/spit"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States { Spawn: MANF AB 3 Bright; Loop; Death: MANF CD 3 Bright; Stop; }
}

// ============================== EX PROJECTILES ==============================
// Black Mancubus EX "Shadow Beast EX" -- buffed shadow balls + burp + big bombs.
class RS_BlackFatsoBurp : Actor
{
	Default { Radius 10; Height 8; Speed 18; Damage 30; DamageType "Poison"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; Scale 1.2;
		SeeSound "fatso/attack"; DeathSound "fatso/shotx"; Translation "0:255=%[0.30,0.00,0.40]:[1.20,0.40,1.60]"; }
	States { Spawn: BDP1 AB 3 Bright; Loop; Death: BDP1 CD 3 Bright A_Explode(30,64); Stop; }
}
class RS_ShadowBeast_Ballex1 : RS_ShadowBeast_Ball1 { Default { Damage 40; } }
class RS_ShadowBeast_Ballex2 : Actor
{
	Default { Alpha 1.0; RenderStyle "Add"; Radius 16; Height 9; DamageType "Plasma"; Damage 45; Speed 21; Scale 2.5; Projectile; +RANDOMIZE;
		SeeSound "shadowbeast/pr2sit"; DeathSound "shadowbeast/pr2death"; Translation "0:255=%[0.30,0.00,0.40]:[1.20,0.40,1.60]"; }
	States { Spawn: BDP2 AB 3 Bright; Loop; Death: BDP2 CDE 4 Bright A_Explode(45,96); Stop; }
}
class RS_ShadowBeast_Ballex3 : RS_ShadowBeast_Ballex2 { Default { Scale 2.4; Radius 12; Height 8; Damage 40; Speed 8; } }
class RS_ShadowBeast_BallFireEX : RS_ShadowBeast_BallFire { Default { Speed 20; } }
class RS_ShadowBombBigEX : Actor
{
	Default { Alpha 1.0; RenderStyle "Add"; Speed 38; Radius 14; Height 9; Damage 120; XScale 2.55; YScale 1.75; DamageType "Plasma"; Projectile;
		SeeSound "shadowbeast/pr2sit"; DeathSound "shadowbeast/pr2death"; Translation "0:255=%[0.30,0.00,0.40]:[1.20,0.40,1.60]"; }
	States { Spawn: BDP2 AB 4 Bright; Loop; Death: BDP2 CDE 5 Bright A_Explode(150,160); Stop; }
}

// ---------- CYAN: ice fat-ball (FATT body, cyan tint) ----------
// Added by the rs_09 per-tier rebuild: the HF port had flattened the
// Cyan Mancubus to the stock triple volley; CH's real attack (CH
// decorate/Fatsos.txt CyanFatso2) is paired ice fat-balls that burst
// into a RS_FrostLong2 shard ring (shared, RS_imp_projectiles.zs).
// CH "Ice/Hit2" death sound has no RS lump -> rs_fx_ice_hit.
class RS_IceFattTrail : Actor
{
	Default { Radius 2; Height 2; Speed 0; Alpha 0.4; RenderStyle "Add"; +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; }
	States
	{
	Spawn:
		CHCY ABCDFG 3 Bright A_Jump(32, "Death");
		Loop;
	Death:
		TNT1 A 1;
		Stop;
	}
}
class RS_CyanFatBall : Actor
{
	Default { Radius 8; Height 8; Speed 32; Scale 1.1; Damage 25; DamageType "Ice"; Projectile; +DONTHARMCLASS;
		SeeSound "imp/attack"; DeathSound "rs_fx_ice_hit"; }
	States
	{
	Spawn:
		CHCY ABCDFG 2 Bright { A_SpawnItemEx("RS_IceFattTrail", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		TNT1 A 0 { A_Scream(); }
		TNT1 AAAAAAA 0 { A_SpawnProjectile("RS_FrostLong2", 0, 0, random(0, 359), CMF_OFFSETPITCH, random(-25, -5)); }
		Stop;
	}
}

// ---------------------------------------------------------------------
// Ported from CH decorate/Fatsos.txt. These four had no RS_ equivalent
// and their attacks would otherwise have been silently dropped.
// ---------------------------------------------------------------------

// The Brown (Fleshy) Fatso's lightning arc -- a stationary crackle that
// paints the air between it and you. Cosmetic-fast, tiny splash.
class RS_ZapFFAT : Actor
{
	Default
	{
		Speed 1;
		Projectile;
		RenderStyle "Add";
		Alpha 0.65;
		Scale 0.65;
		Translation "0:255=#[255,255,0]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 A_Jump(128, "FlyAlt");
		LITN ABCD 1 Bright;
		TNT1 A 0 { A_SetScale(0.85, 0.4); }
		LITN EFG 1 Bright;
		TNT1 A 0 { A_SetScale(0.4, 0.85); }
		LITN FEDB 1 Bright;
		Stop;
	FlyAlt:
		LITN ABCD 1 Bright;
		TNT1 A 0 { A_SetScale(0.4, 0.85); }
		LITN EFG 1 Bright;
		TNT1 A 0 { A_SetScale(0.85, 0.4); }
		LITN FEDB 1 Bright;
		Stop;
	}
}

// The heavier arc: sheds RS_ZapFFAT sparks around itself and does real
// (if small) repeated splash -- CH's "walk into it and regret it" zone.
class RS_ZapFFAT2 : Actor
{
	Default
	{
		Speed 1;
		Projectile;
		RenderStyle "Add";
		DamageType "Plasma";
		Alpha 0.65;
		Scale 0.9;
		Translation "0:255=#[255,255,0]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 AAAA 0 { A_SpawnItemEx("RS_ZapFFAT", random(-24, 24), random(-24, 24), random(-2, 32)); }
		LITN ABCD 1 Bright { A_Explode(random(1, 2), 32, 0); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_ZapFFAT", random(-24, 24), random(-24, 24), random(-2, 32)); }
		LITN EFG 1 Bright { A_Explode(random(1, 2), 32, 0); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_ZapFFAT", random(-24, 24), random(-24, 24), random(-2, 32)); }
		LITN FEDB 1 Bright { A_Explode(random(1, 2), 32, 0); }
		Stop;
	}
}

// The Gray Fatso's spike bomb. Sheds small gravity spikes in flight and
// bursts into a six-way nail ring on impact.
class RS_FatsoSpikes : Actor
{
	Default
	{
		Radius 12;
		Height 12;
		Speed 32;
		DamageFunction (random(28, 85));
		Projectile;
		DamageType "Melee";
		+NOGRAVITY
		+THRUGHOST
		SeeSound "monster/dknmsl";
		DeathSound "weapons/rocklx";
		Translation "144:151=90:95", "64:79=96:109", "236:239=104:111", "1:2=111:111";
	}
	States
	{
	Spawn:
		RIP1 ABC 3 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 0, 0, 1, 0, 0, 0, 0, SXF_NOPOINTERS | SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		RIP1 A 0 { bNOGRAVITY = false; }
		RIP1 ABCABC 8 { A_Explode(random(1, 8), 16); }
		MISL D 0 { A_SpawnProjectile("RS_CGNail", 0, 0, 45); }
		MISL D 0 { A_SpawnProjectile("RS_CGNail", 0, 0, 105); }
		MISL D 0 { A_SpawnProjectile("RS_CGNail", 0, 0, 165); }
		MISL D 0 { A_SpawnProjectile("RS_CGNail", 0, 0, 225); }
		MISL D 0 { A_SpawnProjectile("RS_CGNail", 0, 0, 285); }
		MISL D 1 { A_SpawnProjectile("RS_CGNail", 0, 0, 345); }
		Stop;
	}
}

// The Incubus (T05) rocket. This is the CH/CHP actor: CH Fatsos.txt
// RocketShotFatso and CHP 13_Y.txt RocketShotFatso_C are the same shot (MSLH
// sprite, HomingRocketTrailFatso trail, Radius 11 / Speed 28 / Fire), and the
// CHP arachnotron (12_R.txt, BSP2 frames) fires it too -- so RS_Arachnotron
// T10 and RS_Mancubus T05 both correctly resolve to this one class.
//
// It does NOT home, despite the trail's name and CH's "hominglaunch" see-sound:
// neither source actor has +SEEKERMISSILE or A_SeekerMissile. An RS copy of this
// class did add a per-tic A_SeekerMissile(4, 8, SMF_LOOK); that is dropped here
// to match source. Eight tracking rockets per Incubus volley is a difficulty
// change, and it would have silently landed on the Arachnotron too.
//
// Sounds stay on "weapons/rocklx" rather than CH's "weapons/homingexplode" /
// "weapons/hominglaunch" -- neither lump is defined in this project's SNDINFO,
// so matching source there would just make the rocket silent.
class RS_RocketShotFatso : Actor
{
	Default
	{
		Radius 11;
		Height 8;
		Speed 28;
		DamageFunction (random(10, 40));
		DamageType "Fire";
		Projectile;
		Scale 0.7;
		DeathSound "weapons/rocklx";
	}
	States
	{
	Spawn:
		MSLH A 2 Bright { A_SpawnItemEx("RS_HomingRocketTrailFatso", 0, 0, 0, 0, 0, 0, 0, 128); }
		Loop;
	Death:
		MISL B 0 { A_SetTranslucent(0.8, 1); }
		MISL B 4 Bright { A_Explode(random(5, 35), 88); }
		MISL C 5 Bright;
		MISL D 6 Bright;
		Stop;
	}
}

// =====================================================================
// CHP 13 REBUILD ADDITIONS
// ---------------------------------------------------------------------
// Ported for the per-tier RS_Mancubus rebuild off CHP DECORATE/13, with
// CH decorate/Fatsos.txt as the inherited parent. Everything below is a
// shot the rebuilt monster actually fires (or a corpse/telegraph actor
// its states spawn) that had no RS_ equivalent already in the library.
// =====================================================================

// ---------- T00 COMMON: CH FatShot2 (CH replaces the IWAD FatShot) ----------
class RS_FatShot2 : Actor
{
	Default { Radius 6; Height 8; Speed 20; Damage 8; DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 1;
		SeeSound "fatso/attack"; DeathSound "fatso/shotx"; }
	States { Spawn: MANF AB 4 Bright; Loop; Death: MISL B 8 Bright; MISL C 6 Bright; MISL D 4 Bright; Stop; }
}

// ---------- T00/T01/T02: the armed corpse the death chain drops ----------
class RS_FatsoArmed : Actor
{
	Default { Speed 0; Mass 50; +THRUACTORS; -NOGRAVITY; }
	States { Spawn: FAT2 I -1; Stop; Death: TNT1 A 0; Stop; }
}
class RS_FatsoArmed2 : RS_FatsoArmed
{
	Default { Translation "48:63=112:112","64:79=112:127","13:15=125:127","236:239=125:127","144:151=125:127"; }
}
class RS_FatsoArmed3 : RS_FatsoArmed
{
	Default { Translation "48:63=193:193","64:79=193:207","13:15=205:207","236:239=244:247","144:151=244:247"; }
}

// ---------- T01 GREEN: the acid bomb ----------
class RS_GreenBomb1 : Actor
{
	Default { Radius 8; Height 10; Speed 14; FastSpeed 16; DamageFunction (random(20, 75)); DamageType "Plasma"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 1; Scale 1.6; SeeSound "spit/spit"; DeathSound "spit/spit2";
		Translation "168:191=112:127","208:223=112:118","250:254=112:118","32:47=120:127","144:151=125:127"; }
	States
	{
	Spawn:
		GBLL ABC 6 Bright { A_SpawnItemEx("RS_Trail12", 0, 0, 5); }
		Loop;
	Death:
		BAL2 CDE 6 Bright A_Explode(random(8, 37), 64);
		Stop;
	}
}

// ---------- T02 BLUE: the plasma wave, its afterimage, and the beam ----------
class RS_Bluewave2 : Actor
{
	Default { Radius 1; Height 1; Speed 17; Projectile; +RANDOMIZE; +THRUACTORS; RenderStyle "Add"; Alpha 0.35; Scale 0.66; YScale 0.2;
		Translation "112:127=192:207"; }
	States { Spawn: DIS1 ACFEDB 5 Bright; Stop; }
}
class RS_Bluewave1 : Actor
{
	Default { Radius 16; Height 8; Speed 14; DamageFunction (random(10, 69)); DamageType "Plasma"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.65; Scale 0.75; YScale 0.4; SeeSound "fatso/attack"; DeathSound "weapons/bfgx";
		Translation "112:127=192:207"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 { A_SetScale(0.33, 0.1); }
		DIS1 A 3 Bright;
		DIS1 C 3 Bright { A_SetScale(0.55, 0.2); }
		DIS1 F 3 Bright { A_SetScale(0.75, 0.3); }
		DIS1 D 3 Bright { A_ScaleVelocity(1.5); }
	Fly2:
		DIS1 A 1 Bright { A_SpawnItemEx("RS_Bluewave2", -1, 0, 3, 3, 0, 0); }
		DIS1 CFEDB 2 Bright A_Explode(random(7, 17), 72, 0);
		DIS1 B 1 Bright { A_SpawnItemEx("RS_Bluewave2", -1, 0, 3, 3, 0, 0); }
		Loop;
	Death:
		DIS1 G 6 Bright A_Explode(random(5, 19), 72);
		DIS1 H 4 Bright A_Explode(random(5, 19), 72);
		DIS1 I 2 Bright A_Explode(random(5, 19), 72);
		BFS1 BBBBBB 0 { A_SpawnItemEx("RS_PlasmaBallSP4", random(-8, 8), random(-8, 20), 0, random(15, 60), 0, random(-33, 33), random(0, 120)); }
		BFS1 BBBBBB 0 { A_SpawnItemEx("RS_PlasmaBallSP4", random(-8, 8), random(-8, 20), 0, random(15, 60), 0, random(-33, 33), random(120, 240)); }
		BFS1 BBBBBB 0 { A_SpawnItemEx("RS_PlasmaBallSP4", random(-8, 8), random(-8, 20), 0, random(15, 60), 0, random(-33, 33), random(240, 359)); }
		Stop;
	}
}
class RS_BlueFT : Actor
{
	Default { Radius 13; Height 8; Speed 0; Damage 0; DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 1.0; Scale 2;
		SeeSound "Spell/Lightn"; Translation "112:127=192:207"; }
	States
	{
	Spawn:
		BFS1 A 6 Bright;
		Goto Death;
	Death:
		BFS1 A 4 Bright { A_SetScale(1.6, 1.6); }
		BFS1 A 4 Bright { A_SetScale(1.2, 0.2); }
		BFS1 A 4 Bright { A_SetScale(0.8, 0.8); }
		BFS1 A 4 Bright { A_SetScale(0.5, 0.5); }
		BFS1 A 4 Bright { A_SetScale(0.1, 0.1); }
		Stop;
	}
}
class RS_BlueFT3 : Actor
{
	Default { Radius 13; Height 8; Speed 25; Damage 0; Projectile; +NOINTERACTION; Scale 0.5; RenderStyle "Add"; Alpha 1.0;
		Translation "112:127=192:207"; }
	States
	{
	Spawn:
		BFS1 AB 2 Bright;
		Goto Death;
	Death:
		BFS1 A 2 Bright { A_SetScale(0.6, 0.6); }
		BFS1 B 2 Bright { A_SetScale(0.4, 0.4); }
		BFS1 A 2 Bright { A_SetScale(0.2, 0.2); }
		Stop;
	}
}
class RS_BlueFT2 : Actor
{
	Default { Radius 13; Height 8; Speed 50; DamageFunction (random(10, 70)); DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 1.0; Scale 0.5;
		SeeSound "fatso/attack"; DeathSound "weapons/bfgx"; Translation "112:127=192:207"; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		BFS1 A 1 Bright { A_SpawnItemEx("RS_BlueFT3", 0, 0, 1); }
		BFS1 B 1 Bright { A_SpawnItemEx("RS_BlueFT3", 0, 0, 0); }
		Loop;
	Death:
		TNT1 A 0 { A_SetScale(0.3, 0.3); }
		BFE1 AB 8 Bright;
		TNT1 A 0 { A_SetScale(0.1, 0.1); }
		BFE1 CDEF 8 Bright;
		Stop;
	}
}

// ---------- T04 PURPLE: bouncing hex-bomb + its shrapnel ----------
class RS_MiniFatsoPurpleBomb : Actor
{
	Default { Radius 4; Height 4; Speed 18; Scale 0.5; DamageFunction (random(5, 20)); DamageType "Fire"; Projectile; +BOUNCEONWALLS;
		RenderStyle "Add"; Alpha 0.75; BounceType "Hexen"; WallBounceFactor 0.7; BounceFactor 0.7; BounceCount 4;
		BounceSound "Bomb/bounce"; SeeSound "imp/attack"; DeathSound "weapons/plasmax";
		Translation "168:191=250:254","208:223=250:254"; }
	States
	{
	Spawn:
		SBS1 ABCD 6 Bright A_Jump(8, "Death");
		Loop;
	Death:
		BAL1 CD 3 Bright A_Explode(random(2, 10), 42);
		BAL1 E 3 Bright A_Explode(random(2, 10), 42);
		Stop;
	}
}
class RS_PurpleBomb1 : Actor
{
	Default { Radius 7; Height 7; Speed 18; FastSpeed 32; Mass 23; Gravity 0.3; DamageFunction (random(10, 65)); DamageType "Fire";
		Projectile; -NOGRAVITY; +RANDOMIZE; +BOUNCEONFLOORS; +USEBOUNCESTATE; +EXPLODEONWATER;
		RenderStyle "Add"; Alpha 0.88; BounceType "Hexen"; BounceCount 8; BounceFactor 1.25; WallBounceFactor 1.1; Scale 1;
		SeeSound "caco/attack"; BounceSound "Bomb/bounce"; DeathSound "Bomb/boom"; Translation "168:191=250:254"; }
	States
	{
	Spawn:
		SBS1 ABCD 6 Bright;
		Loop;
	Bounce.Wall:
		SBS4 DE 6 Bright { A_SetTranslucent(0.4); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_MiniFatsoPurpleBomb", random(-1, 1), random(-1, 1), random(-1, 1), random(-3, 12), random(-1, 1), random(-25, 45), random(0, 120)); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_MiniFatsoPurpleBomb", random(-1, 1), random(-1, 1), random(-1, 1), random(-3, 12), random(-1, 1), random(-25, 45), random(120, 240)); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_MiniFatsoPurpleBomb", random(-1, 1), random(-1, 1), random(-1, 1), random(-3, 12), random(-1, 1), random(-25, 45), random(240, 359)); }
		TNT1 A 0 { A_Stop(); }
		Goto Death.Blast;
	Death:
		SBS4 DE 6 Bright { A_SetTranslucent(0.4); }
	Death.Blast:
		SBS4 FGH 6 Bright A_Explode(random(5, 28), 88);
		Stop;
	}
}
// The Hectebus hitscan "swoosh" uses this as its puff.
class RS_FatsoPuff3 : Actor
{
	Default { Radius 6; Height 16; Speed 16; FastSpeed 23; Projectile; +RANDOMIZE; +MTHRUSPECIES; +NOINTERACTION;
		RenderStyle "Add"; Scale 0.5; Alpha 0.6; Translation "168:191=250:254","208:223=250:254"; }
	States { Spawn: BAL1 CDE 6 Bright; Goto Death; Death: BAL1 CDE 6 Bright; Stop; }
}

// ---------- T07 FIREBLU: the fast little fireblu ball (CHP-only actor) ----------
class RS_FireBluFatsoBall : FastProjectile
{
	Default { Radius 3; Height 3; Speed 45; DamageFunction (random(10, 20)); DamageType "Plasma"; Projectile;
		RenderStyle "Add"; Alpha 0.95; Scale 0.33; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "208:223=195:207","225:231=192:195"; }
	States { Spawn: BAL1 AB 4 Bright; Loop; Death: BAL1 CDE 6 Bright A_Explode(random(1, 7), 32); Stop; }
}

// ---------- T08 BROWN: the bass soundwave and its afterimage ----------
class RS_FatsoSoundWaveTrail : Actor
{
	Default { ProjectileKickBack 500; Radius 12; Height 6; Speed 56; DamageFunction (random(10, 55)); DamageType "Plasma"; Projectile;
		+MTHRUSPECIES; RenderStyle "Add"; Alpha 0.15; XScale 2.0; YScale 0.55; DeathSound "spit/spit2";
		Translation "0:255=#[255,255,0]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		GBLL A 3 Bright;
		GBLL B 3 Bright { A_SetScale(1.5, 0.45); }
		GBLL C 3 Bright { A_SetScale(1.1, 0.25); }
	Death:
		GBLL C 3 Bright { A_SetScale(0.15, 0.15); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_ZapFFAT", random(-42, 42), random(-42, 42), random(-8, 8)); }
		LITN ABCD 1 Bright A_Explode(random(8, 12), 64, 0);
		TNT1 AAAA 0 { A_SpawnItemEx("RS_ZapFFAT", random(-42, 42), random(-42, 42), random(-8, 8)); }
		LITN EFG 1 Bright A_Explode(random(8, 12), 64, 0);
		Stop;
	}
}
class RS_FatsoSoundWave : Actor
{
	Default { ProjectileKickBack 9001; Radius 12; Height 6; Speed 56; DamageFunction (random(10, 55)); DamageType "Plasma"; Projectile;
		+MTHRUSPECIES; +DONTTHRUST; +DONTBLAST; RenderStyle "Add"; Alpha 0.33; XScale 2.1; YScale 0.65;
		SeeSound "fatso/attack"; DeathSound "weapons/bfgx"; Translation "0:255=#[255,255,0]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		GBLL ABC 1 Bright { A_SpawnItemEx("RS_FatsoSoundWaveTrail", 0, 0, 0, 6, 0, 0); }
		Loop;
	Death:
		GBLL A 6 Bright { A_SetScale(2.5, 1.2); }
		GBLL B 6 Bright A_Explode(random(20, 80), 128, 0);
		GBLL C 6 Bright { A_SetScale(3.0, 1.5); }
		GBLL CC 3 { A_FadeOut(0.11); }
		Stop;
	}
}

// ---------- T12 WHITE: the railgun pair, the ground/air zaps, the nuke ----------
class RS_WhiteFatRB : Actor
{
	Default { Radius 20; Height 20; Speed 1; DamageFunction (random(30, 95)); DamageType "Plasma"; Projectile; +ALWAYSPUFF;
		RenderStyle "Add"; Alpha 0.75; Scale 2.25; DeathSound "NETHERDE";
		Translation "112:120=80:88","120:127=192:199","160:167=4:4","224:235=192:192","64:79=192:199","144:151=4:4","128:143=4:4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		TNT1 A 0 { A_Scream(); }
		BFE1 AB 5 Bright;
		BFE1 C 8 Bright A_Explode(random(50, 125), 252);
		TNT1 A 0 { A_Quake(15, 15, 0, 2560); }
		BFE1 DEF 8 Bright;
		Stop;
	}
}
class RS_WhiteFatRB3 : Actor
{
	Default { Radius 20; Height 20; Speed 1; DamageFunction (random(30, 95)); DamageType "Plasma"; Projectile; +ALWAYSPUFF;
		RenderStyle "Add"; Alpha 0.75; Scale 1.33; DeathSound "NETHERDE";
		Translation "112:120=80:88","120:127=192:199","160:167=4:4","224:235=192:192","64:79=192:199","144:151=4:4","128:143=4:4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		TNT1 A 0 { A_Scream(); }
		BFE1 AB 5 Bright;
		BFE1 C 8 Bright A_Explode(random(30, 95), 128);
		TNT1 A 0 { A_Quake(9, 9, 0, 1920); }
		BFE1 DEF 8 Bright;
		Stop;
	}
}
class RS_WhiteFatRB2 : Actor
{
	Default { Radius 20; Height 20; Speed 11; DamageFunction (random(30, 50)); DamageType "Plasma"; Projectile; Scale 2;
		RenderStyle "Add"; Alpha 0.95; SeeSound "Spell/spellCast1"; DeathSound "Crack/death";
		Translation "231:231=4:4","208:223=80:86","168:191=192:196","32:47=4:4","250:254=4:4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL2 A 3 { A_SetScale(2.0, 2.0); }
		BAL2 B 3 { A_SetScale(1.75, 1.75); }
		BAL2 A 3 { A_SetScale(1.5, 1.5); }
		BAL2 B 3 { A_SetScale(1.75, 1.75); }
	Death:
		BAL2 C 4 { A_SetTranslucent(0.55); }
		BAL2 D 1 A_Explode(random(15, 30), 128);
		BAL2 E 2 A_Explode(random(15, 30), 128);
		Stop;
	}
}
class RS_WhiteFatRB4 : Actor
{
	Default { Radius 20; Height 20; Speed 11; DamageFunction (random(15, 30)); DamageType "Plasma"; Projectile; Scale 1.33;
		RenderStyle "Add"; Alpha 0.95; SeeSound "Spell/spellCast1"; DeathSound "Crack/death";
		Translation "231:231=4:4","208:223=80:86","168:191=192:196","32:47=4:4","250:254=4:4"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		BAL2 A 3 { A_SetScale(1.33, 1.33); }
		BAL2 B 3 { A_SetScale(1.15, 1.15); }
		BAL2 A 3 { A_SetScale(0.85, 0.85); }
		BAL2 B 3 { A_SetScale(1.15, 1.15); }
	Death:
		BAL2 C 4 { A_SetTranslucent(0.55); }
		BAL2 D 1 A_Explode(random(10, 20), 88);
		BAL2 E 2 A_Explode(random(10, 20), 88);
		Stop;
	}
}
class RS_WhiteFatsoGroundZap : Actor
{
	Default { Radius 12; Species "Fatso"; Height 16; Speed 18; DamageFunction (random(10, 30)); DamageType "Plasma"; Projectile;
		+DONTHURTSPECIES; +DONTHARMCLASS; +THRUSPECIES; +FLOORHUGGER; RenderStyle "Add"; Alpha 1.0; Translation "Ice"; }
	States
	{
	Spawn:
	Death:
		TNT1 A 1 NoDelay { A_StartSound("prieinfu", CHAN_BODY); }
		LITN ABCDEFGOPABCDEFGOPABCDEFGOP 2 Bright A_Explode(random(2, 9), 64, 0);
		Stop;
	}
}
class RS_WhiteFatsoAirZap : Actor
{
	Default { Radius 8; Species "Fatso"; Height 8; Speed 17; DamageFunction (random(1, 2)); DamageType "Plasma"; Projectile;
		+DONTHURTSPECIES; +DONTHARMCLASS; +SEEKERMISSILE; +THRUSPECIES; +RIPPER; RenderStyle "Add"; Alpha 1.0; Translation "Ice"; }
	States
	{
	Spawn:
	Death:
		TNT1 A 1 NoDelay { A_StartSound("prieinfu", CHAN_BODY); }
		LITN ABCDEFGOPABCDEFGOPABCDEFGOPABCDEFGOP 2 Bright { A_Weave(3, 2, 5, 2); }
		Stop;
	}
}
// NOTE: RS_WhiteFatNukeShow / RS_WhiteFatMark / RS_WhiteFatNuke -- the
// orbital-nuke trio the Angry Mama GroundNuke spawns -- are already
// ported in RS_spidermind_projectiles.zs (the White Spider Mastermind
// uses the same CH actors). Reused from there, not duplicated here.
