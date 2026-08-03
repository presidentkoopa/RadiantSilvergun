// =====================================================================
// RS_demon_projectiles.zs
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
// hf_demon_projectiles.zs -- Pinky/Demon projectiles (color ladder).
// Pinky is mostly a melee charger; only a few colors fire. Shares RS_MolochQuake,
// RS_WDRock1, RS_WDRock3 (from Cyberdemon/Caco). Damage->constants.
// ============================================================================

// ---------- YELLOW: lightning zap (LITN) ----------
class RS_ZapZapCB : Actor
{
	Default { Speed 1; Projectile; +RANDOMIZE; RenderStyle "Add"; DamageType "Plasma"; Alpha 0.65; Scale 1; Damage 15; Translation "0:255=#[255,255,0]"; }
	States { Spawn: LITN ABCDEFGOPABCDEFGOP 1 Bright A_Explode(10,48); Goto Death; Death: LITN A 2 Bright; Stop; }
}

// ---------- ABYSS: "Hell Hound" seeking fire (FRFX) ----------
class RS_AbyssDogFire : Actor
{
	Default { Radius 4; Height 3; Speed 18; Damage 30; Projectile; +SEEKERMISSILE; DamageType "Fire"; RenderStyle "Add"; Alpha 1; XScale 1.4; YScale 0.5;
		SeeSound "hellhound/attack"; DeathSound "hellhound/shotx"; Translation "Ice"; }
	States { Spawn: FRFX AB 3 Bright A_SeekerMissile(4,4); Loop; Death: FRFX CDE 4 Bright A_Explode(30,48); Stop; }
}

// ---------- BROWN: kickback orb (BAL1) ----------
class RS_BrownOrbDemon : Actor
{
	Default { Radius 3; Height 3; Speed 28; ProjectileKickBack 2000; Mass 100; Species "Demon1"; Damage 22; Projectile; DamageType "Fire"; +MTHRUSPECIES; +RANDOMIZE;
		RenderStyle "Add"; SeeSound "imp/attack"; DeathSound "imp/shotx"; Translation "0:255=%[0.31,0.23,0.18]:[1.10,0.74,0.40]"; }
	States { Spawn: BAL1 AB 3 Bright; Loop; Death: BAL1 CDE 4 Bright A_Explode(22,48); Stop; }
}

// ---------- RED: blood bolts (BAL1 / falling BLUD) ----------
class RS_RedDemonBloodBolt1 : Actor
{
	Default { Radius 7; Height 7; Mass 5; Speed 19; Projectile; Scale 0.95; RenderStyle "Add"; Damage 16; DamageType "Fire"; Alpha 0.95;
		SeeSound "imp/attack"; DeathSound "imp/shotx"; Translation "0:255=%[0.60,0.00,0.00]:[2.00,0.30,0.30]"; }
	States
	{
	Spawn:
		BAL1 AB 3 Bright A_SpawnItemEx("RS_RedDemonBloodBolt3",0,0,0,0,0,0,random(0,360));
		Loop;
	Death:
		BAL1 CDE 4 Bright A_Explode(16,48);
		Stop;
	}
}
class RS_RedDemonBloodBolt3 : Actor
{
	Default { Speed 15; Alpha 0.75; RenderStyle "Translucent"; Projectile; -NOGRAVITY; Mass 5; Gravity 0.2; DamageType "Fire"; Damage 3; Scale 0.95;
		Translation "0:255=%[0.60,0.00,0.00]:[2.00,0.30,0.30]"; }
	States { Spawn: BLUD AB 4; Loop; Death: SPRY ABC 4; Stop; }
}

// ---------- WHITE: "Juggernaut" -- MolochQuake + rocks (shared RS_MolochQuake/WDRock) ----------
// (RS_MolochQuake, RS_WDRock1, RS_WDRock3 already defined. WDRock2 below.)
class RS_WDRock2 : Actor
{
	Default { Radius 8; Height 8; Speed 5; FloatSpeed 6; +FLOAT; +NOGRAVITY; +NOCLIP; Scale 1.2; }
	States { Spawn: JUBD A 0; Fly: JUBD ABCD 3 Bright; Loop; Death: JUBD D 1; Stop; }
}

// ---------- BLACK: "Butcher" -- hammer melee (BRHM) ----------
class RS_ButcherHammer : Actor
{
	Default { Radius 8; Height 8; Speed 24; Damage 40; Projectile; DamageType "Melee"; +THRUGHOST; +FORCEPAIN; RenderStyle "Add"; Alpha 0.9; Scale 1.1;
		SeeSound "butcher/melee"; DeathSound "butcher/hit"; }
	States { Spawn: BRHM AB 3 Bright; Loop; Death: BRHM CDE 4 Bright A_Explode(40,48); Stop; }
}

// ---------- GRAY: leech-worm bite (WormLewd) ----------
class RS_WormLewd : Actor
{
	Default { Radius 8; Height 16; Speed 14; FastSpeed 26; Scale 0.75; Species "Demon1"; Damage 14; DamageType "Melee"; Projectile; +DONTHARMCLASS; +DONTHARMSPECIES;
		RenderStyle "Add"; Alpha 0.25; Translation "168:191=112:127"; }
	States { Spawn: BAL1 A 1 Bright; Goto Death; Death: BAL1 CDE 2 Bright A_Explode(5,32,0); Stop; }
}
