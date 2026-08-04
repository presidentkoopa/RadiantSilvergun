// =====================================================================
// RS_caco_projectiles.zs
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
// hf_caco_projectiles.zs -- Cacodemon projectiles (Neutral + 13 colors + Black EX).
// Neutral fires stock CacodemonBall (IWAD). RS_ color projectiles below.
// Shares RS_Trail12, RS_Splash11, RS_Drt3, RS_FireBluCacoBall (from earlier monsters).
// Hades balls (CH inherits CacodemonBall) -> based on plain RS projectile. Damage->constants.
// ============================================================================

// base caco-ball clone for the Hades family
class RS_CacoBallBase : Actor
{
	Default { Radius 6; Height 8; Speed 10; Damage 5; Projectile; +RANDOMIZE; RenderStyle "Add"; SeeSound "caco/attack"; DeathSound "caco/shotx"; }
	States { Spawn: BAL2 AB 4 Bright; Loop; Death: BAL2 CDE 4 Bright; Stop; }
}

// ---------- GREEN: cacospit (BAL7) ----------
class RS_Cacospit1 : Actor
{
	Default { Radius 6; Height 16; Speed 17; FastSpeed 20; Damage 27; DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.65;
		SeeSound "baron/attack"; DeathSound "baron/shotx"; Decal "BaronScorch"; }
	States
	{
	Spawn:
		BAL7 AB 4 Bright A_SpawnItemEx("RS_Trail12",0,0,3);
		Loop;
	Death:
		BAL7 CDE 6 A_Explode(20,48);
		Stop;
	}
}

// ---------- BLUE: holy bolt (SSBL) ----------
class RS_CacoFire2 : Actor
{
	Default { Radius 12; Height 12; Speed 18; Damage 20; DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 0.73; Scale 0.7;
		SeeSound "holy3/holy3"; DeathSound "holy2/holy2"; }
	States
	{
	Spawn:
		SSBL ABCDEFGH 3 Bright;
		Loop;
	Death:
		SSBL K 6 Bright A_SetScale(0.5);
		SSBL IJ 6 Bright;
		Stop;
	}
}

// ---------- PURPLE: seeking fire balls (SBS4) ----------
class RS_CacoFire3 : Actor
{
	Default { Radius 6; Height 8; Speed 15; FastSpeed 28; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 1;
		SeeSound "caco/attack"; DeathSound "caco/shotx"; }
	States
	{
	Spawn:
		SBS4 ABC 6 Bright A_SeekerMissile(4,4);
		Loop;
	Death:
		BAL2 CDE 6 Bright A_Explode(20,48);
		Stop;
	}
}
class RS_CacoFire4 : Actor
{
	Default { Radius 4; Height 6; Speed 16; FastSpeed 29; Damage 15; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 1; Scale 0.5;
		SeeSound "caco/attack"; DeathSound "caco/shotx"; }
	States
	{
	Spawn:
		SBS4 ABC 6 Bright A_SeekerMissile(6,6);
		Loop;
	Death:
		BAL2 CDE 6 Bright;
		Stop;
	}
}

// ---------- YELLOW: bouncing fire spit (FLUM) ----------
class RS_SpitFireCaco : Actor
{
	Default { Radius 6; Height 6; Speed 20; Damage 35; DamageType "Fire"; Projectile; +VISIBILITYPULSE; +BOUNCEONWALLS; RenderStyle "Add";
		SeeSound "CacoFlame/Attack"; DeathSound "Fire/fire5"; WallBounceFactor 0.8; BounceCount 8; BounceType "Doom"; Alpha 0.9; Scale 0.7; }
	States
	{
	Spawn:
		FLUM ABCDE 6 Bright;
		Loop;
	Death:
		FLUM FGH 4 Bright A_Explode(35,64);
		Stop;
	}
}

// ---------- CYAN: big & small ice (CHCY / ICEY) ----------
class RS_BigIceCaco : Actor
{
	Default { Radius 12; Height 12; Speed 32; Scale 0.95; RenderStyle "Add"; Alpha 0.95; Damage 24; DamageType "Ice"; Projectile; +DONTHARMCLASS;
		SeeSound "imp/attack"; DeathSound "Ice/Hit2"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		CHCY ABCDFG 3 Bright;
		Loop;
	Death:
		CHCY HIJ 4 Bright A_Explode(24,64);
		Stop;
	}
}
class RS_SmallIceCaco : Actor
{
	Default { Radius 3; Height 2; Speed 42; Damage 14; DamageType "Ice"; Projectile; RenderStyle "Add"; Alpha 0.75; XScale 1.55; YScale 0.25;
		SeeSound "Ice/Hit2"; DeathSound "spike/spiked"; Decal "BulletChip"; }
	States
	{
	Spawn:
		ICEY ABC 3 Bright;
		Loop;
	Death:
		ICEY FG 5 Bright;
		Stop;
	}
}

// ---------- GRAY: rock breath (JUBD/DIRT) ----------
class RS_WDRock4 : Actor
{
	Default { Radius 4; Height 4; Speed 42; Damage 12; DamageType "Melee"; Projectile; Scale 0.4; SeeSound "monster/hamflr"; DeathSound "Butcher/melee"; }
	States
	{
	Spawn:
		JUBD ABCD 2 Bright;
		Loop;
	Death:
		JUBD D 1 Bright A_SpawnItemEx("RS_Drt3",random(-2,2),random(-2,2),1,0,0,0,random(0,360));
		DIRT JKL 3;
		Stop;
	}
}
class RS_CacoRockBreath : RS_WDRock4 { Default { Damage 30; } }

// ---------- BROWN: grell ball (ICEY tinted, splash) ----------
class RS_GrellBallBrown : Actor
{
	Default { Radius 6; Height 8; Speed 15; Damage 4; Scale 0.75; DamageType "Melee"; RenderStyle "Add"; Alpha 0.67; Projectile; DeathSound "grell/projhit";
		Translation "0:255=%[0.31,0.23,0.18]:[1.10,0.74,0.40]"; }
	States
	{
	Spawn:
		ICEY AAABBBCCC 1 Bright A_SpawnItemEx("RS_Splash11",0,0,3,random(-2,2),0,random(1,3),random(0,360));
		Loop;
	Death:
		ICEY FG 5 Bright A_Explode(10,48);
		Stop;
	}
}

// ---------- FIREBLU: already have RS_FireBluCacoBall (from Cyberdemon) ----------

// ---------- ABYSS: void balls + hidi (BLL9/SPIR) ----------
class RS_AbyssCacoBalls : Actor
{
	Default { Radius 8; Species "Caco"; Height 6; Speed 21; Damage 30; DamageType "Ice"; Projectile; +THRUSPECIES; +DONTHURTSPECIES; +DONTHARMCLASS; Scale 1.25;
		RenderStyle "Add"; Alpha 0.8; SeeSound "Crack/see"; DeathSound "Crack/death"; Translation "Ice"; }
	States
	{
	Spawn:
		SPIR AB 4 Bright;
		Loop;
	Death:
		SPIR CDE 4 Bright A_Explode(30,64);
		Stop;
	}
}
class RS_AbyssCacoHidi : Actor
{
	Default { Radius 4; Height 3; Speed 55; Damage 60; Projectile; +SEEKERMISSILE; +THRUSPECIES; +DONTHURTSPECIES; +DONTHARMCLASS; Species "Caco"; DamageType "Plasma";
		RenderStyle "Add"; Alpha 0.95; XScale 1.4; YScale 0.35; SeeSound "weapons/bigbrn"; DeathSound "weapons/bigbrn"; Translation "Ice"; }
	States
	{
	Spawn:
		BLL9 AB 2 Bright A_SeekerMissile(4,4);
		Loop;
	Death:
		BLL9 CDE 4 Bright A_Explode(60,96);
		Stop;
	}
}

// ---------- RED: crackodemon ball + spike bomb + effect (BLL9/BAL1) ----------
class RS_CrackodemonBall : Actor
{
	Default { Radius 8; Species "Caco"; Height 6; Speed 15; Damage 30; DamageType "Plasma"; Projectile; RenderStyle "Add"; Alpha 0.8;
		SeeSound "Crack/see"; DeathSound "Crack/death"; Translation "192:207=171:191","240:247=191:191"; }
	States
	{
	Spawn:
		BLL9 AAAABBBB 1 Bright;
		Loop;
	Death:
		BLL9 CDE 4 Bright A_Explode(30,64);
		Stop;
	}
}
class RS_SBombCaco : Actor
{
	Default { Radius 20; Height 20; Mass 600; Speed 11; Damage 45; DamageType "Plasma"; Projectile; Scale 2; RenderStyle "Add"; Alpha 0.95;
		SeeSound "Spell/spellCast1"; DeathSound "Crack/death"; Translation "208:223=176:191","224:231=176:176"; }
	States
	{
	Spawn:
		BAL1 AB 3 Bright A_SpawnItemEx("RS_CrackodemonBall",0,0,0,0,0,0,random(0,360),SXF_NOCHECKPOSITION);
		Loop;
	Death:
		BAL1 CDE 6 Bright A_Explode(60,128);
		Stop;
	}
}

// ---------- BLACK: the "Hades" caco -- eye-beam, hades balls/bolt (HEFX/HADE/LITN) ----------
class RS_HadesBall : RS_CacoBallBase
{
	Default { Damage 18; Speed 17; Alpha 0.80; DamageType "Plasma"; +THRUGHOST; +FORCEXYBILLBOARD; SeeSound "Monster/hadtel"; DeathSound "Monster/hadsit"; Decal "CacoScorch"; }
	States { Spawn: HEFX AB 4 Bright; Loop; Death: HEFX CDE 5 Bright A_Explode(18,64); Stop; }
}
class RS_HadesBall2 : RS_HadesBall { Default { Damage 30; Speed 12; Scale 1.5; } }
class RS_HadesBall3 : RS_HadesBall { Default { Damage 30; Speed 4; Radius 12; Height 8; Scale 1.25; } }
class RS_HadesBolt : Actor
{
	Default { Radius 8; Height 8; Speed 5; Damage 1; DamageType "Plasma"; Projectile; SeeSound "weapons/none"; DeathSound "weapons/gntidl";
		YScale 4.0; XScale 0.7; ReactionTime 35; +FLOORHUGGER; +RIPPER; +FLOORCLIP; -NOGRAVITY; BounceType "Hexen"; RenderStyle "Add"; Alpha 0.8; }
	States { Spawn: HEFX AB 2 Bright A_Explode(8,48); Loop; Death: HEFX C 4 Bright; Stop; }
}
class RS_EyeBeamCaco : Actor
{
	Default { Radius 11; Height 9; Speed 178; Damage 1; DamageType "Plasma"; Projectile; +STRIFEDAMAGE; RenderStyle "Add"; Alpha 0.8; Scale 0.65;
		SeeSound "Crack/see"; DeathSound "Litn/litn3"; Translation "192:207=171:191","240:247=191:191"; }
	States { Spawn: LITN AB 2 Bright; Loop; Death: LITN CDE 3 Bright A_Explode(20,48); Stop; }
}
class RS_HadeLoad1 : Actor
{
	Default { Radius 1; Height 1; +NOCLIP; +NOGRAVITY; +NOINTERACTION; RenderStyle "Add"; Alpha 0.9; SeeSound "Weapons/BFGF"; }
	States { Spawn: HADE GFEDCBA 3 Bright; Stop; }
}

// ---------- WHITE: caco-bald balls + arm spawner (CEIE/CEYX/GBLL) ----------
class RS_CacobaldBall : Actor
{
	Default { Radius 6; Height 8; Speed 20; FastSpeed 24; Damage 5; Projectile; +RANDOMIZE; DamageType "Melee"; SeeSound "imp/attack"; DeathSound "imp/shotx"; Decal "DoomImpScorch"; }
	States { Spawn: CEIE ABCDEF 4 Bright; Loop; Death: CEYX ABC 5 Bright A_Explode(20,48); Stop; }
}
class RS_CacobaldBall2 : Actor
{
	Default { Radius 5; Height 7; Speed 18; Damage 5; Projectile; +SEEKERMISSILE; Scale 0.75; DamageType "Melee"; SeeSound "imp/attack"; DeathSound "imp/shotx"; Decal "DoomImpScorch"; }
	States { Spawn: CEIE ABC 3 Bright A_SeekerMissile(4,4); Loop; Death: CEYX ABC 5 Bright; Stop; }
}
class RS_ArmSpawnerCACO : Actor
{
	// CH arm-spawner is a real summon controller; folded to a stencil decoration burst.
	Default { Radius 32; Height 16; Speed 1; FloatSpeed 1; +NOGRAVITY; +FLOAT; RenderStyle "Stencil"; StencilColor "White"; }
	States { Spawn: GBLL A 0; Fly: GBLL AB 3 Bright A_SetScale(4.5,4.5); GBLL C 3 Bright A_FadeOut(0.1); Goto Fly; }
}

// =====================================================================
// Ported verbatim from CHP DECORATE/09 (cacodemon) and its shared
// dependencies. These five had no RS_ equivalent; without them the
// Yellow, Abyss, Red and Black cacodemons lose real attacks.
// =====================================================================

// T05 YELLOW -- the Void Field. A stationary damaging zone the caco
// scatters around the arena; pulses scale and splash, then fades.
// Not a projectile: an invulnerable, non-solid hazard actor.
class RS_VoidField : Actor
{
	Default
	{
		Radius 46;
		Height 46;
		Health 6666;
		Species "Caco";
		Speed 0;
		Damage 0;
		Monster;
		+INVULNERABLE +DONTHARMSPECIES +DONTHARMCLASS +REFLECTIVE
		+NOTARGET +NOGRAVITY +DONTTHRUST
		-COUNTKILL -SOLID -CANPUSHWALLS -CANUSEWALLS -ACTIVATEMCROSS
		RenderStyle "Add";
		DamageType "Fire";
		Alpha 0.75;
		Scale 1.5;
		DeathSound "caco/death";
	}
	States
	{
	Spawn:
		BBOM B 1 Bright { A_SetScale(1.5); }
	Pulse:
		BBOM B 1 Bright { A_SetScale(1.3); }
		BBOM B 1 Bright { A_Explode(5, 64); }
		BBOM B 1 Bright { A_SetScale(1.0); }
		BBOM B 1 Bright A_Jump(2, "Death");
		Goto Pulse;
	Death:
		BBOM B 3 Bright { A_SetScale(1.3); }
		BBOM B 3 Bright { A_SetScale(1.0); }
		BBOM B 3 Bright { A_SetScale(0.7); }
		BBOM B 3 Bright { A_SetScale(0.3); }
		Stop;
	}
}

// T06 ABYSS -- the charge-up crackle that plays before the Hideous
// attack lands. Cosmetic only, no collision.
class RS_ESZapZap : Actor
{
	Default
	{
		+NOCLIP +NOBLOCKMAP +NOGRAVITY +THRUSPECIES +DONTHARMSPECIES
		Species "Caco";
		RenderStyle "Add";
		Alpha 0.90;
		Translation "0:255=%[0.21,0.29,0.68]:[1.07,2.00,2.00]";
	}
	States
	{
	Spawn:
		LITN BCDEFGOP 2 Bright;
		Stop;
	}
}

// T10 RED -- the sludge droplets that drip off the caco while it winds
// up the Sludgebomb. Gravity-bound spatter, tiny, cosmetic.
class RS_RedThingsLS : Actor
{
	Default
	{
		Radius 1;
		Height 1;
		Mass 8;
		Speed 9;
		Projectile;
		+THRUACTORS
		-NOGRAVITY
		Scale 0.15;
		Gravity 2;
		RenderStyle "Add";
		Alpha 0.8;
		Translation "208:223=176:191", "224:231=176:176";
	}
	States
	{
	Spawn:
		BAL1 AB 12;
		BAL1 A 2 A_Jump(32, "Death");
		Loop;
	Death:
		BAL1 A 1 { A_SetTranslucent(0.35); }
		Stop;
	}
}

// T11 BLACK (Hades) -- the seeking blast its bullet-attack leaves
// behind, and the aura ring that scatters those blasts.
class RS_HadeExpl : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 3;
		FastSpeed 9;
		DamageFunction (random(5, 10));
		DamageType "Fire";
		Projectile;
		+RANDOMIZE +SEEKERMISSILE
		RenderStyle "Add";
		Alpha 1.0;
		Scale 1.15;
		SeeSound "caco/attack";
	}
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Death;
	Death:
		HADE M 4 Bright { A_Explode(random(2, 10), 108); }
		HADE N 5 Bright { A_Explode(random(2, 12), 124); }
		HADE OP 5 Bright { A_Explode(random(2, 10), 138); }
		HADE Q 6 Bright { A_Explode(random(5, 25), 128); }
		Stop;
	}
}

class RS_HadeAra : Actor
{
	Default
	{
		+NOBLOCKMAP +NOGRAVITY +ALLOWPARTICLES +RANDOMIZE +PUFFONACTORS
		Projectile;
		RenderStyle "Add";
		DamageType "Melee";
		Alpha 0.95;
		VSpeed 1;
		Scale 2.0;
		SeeSound "vile/active";
		Mass 5;
	}
	States
	{
	Spawn:
		HADE ABCDEGH 3 Bright { A_Explode(random(2, 26), 64); }
	Melee:
		HADE AHGEDCBA 3 Bright { A_SpawnItemEx("RS_HadeExpl", random(-128, 128), random(-128, 128), random(-88, 88)); }
		Stop;
	}
}

// Vanilla-shaped caco fireball, kept as an RS_ class so every tier's
// projectile reference resolves inside this library.
class RS_CacodemonBall : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 10;
		FastSpeed 20;
		Damage 5;
		Projectile;
		+RANDOMIZE
		RenderStyle "Add";
		Alpha 1.0;
		SeeSound "caco/attack";
		DeathSound "caco/shotx";
	}
	States
	{
	Spawn:
		BAL2 AB 4 Bright;
		Loop;
	Death:
		BAL2 CDE 6 Bright;
		Stop;
	}
}
