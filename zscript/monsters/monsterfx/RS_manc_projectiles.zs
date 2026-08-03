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
// Heavier colors have real shots below. Shares RS_RocketShotFatso (from Arachnotron).
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
class RS_ZAPFFAT2 : Actor
{
	Default { Speed 1; Projectile; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.65; Scale 0.9; Damage 10; Translation "0:255=#[255,255,0]"; }
	States { Spawn: TNT1 A 0; Fly: LITN ABCDEF 2 Bright A_Explode(8,40); Loop; Death: LITN A 2 Bright; Stop; }
}

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
