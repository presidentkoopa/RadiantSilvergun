// =====================================================================
// RS_rev_projectiles.zs
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
// hf_rev_projectiles.zs -- Revenant projectiles (Neutral homing/straight tracers + colors).
// Neutral fires the classic skeleton homing + straight tracers. CH_BoneGib gib-cosmetic
// dropped -> cosmetic pass. Shares RS_HKRedDeath, RS_SplashAbyss2, RS_MegaRedRev.
// Damage->constants.
// ============================================================================

// ---------- NEUTRAL: classic revenant tracers (homing + straight) ----------
class RS_RevenantTracerStraight : FastProjectile
{
	Default { Radius 11; Height 8; Speed 30; Damage 8; Projectile; +RANDOMIZE; +STRIFEDAMAGE; SeeSound "skeleton/attack"; DeathSound "skeleton/tracex";
		Decal "RevenantScorch"; RenderStyle "Add"; DamageType "Monster"; }
	States
	{
	Spawn:
		FATB AB 2 Bright;
		Loop;
	Death:
		BFE2 A 4 Bright;
		BFE2 BCDE 4 Bright;
		Stop;
	}
}
class RS_RevenantTracerHoming : RS_RevenantTracerStraight
{
	Default { Speed 15; Damage 8; +SEEKERMISSILE; }
	States
	{
	Spawn:
		FATB AB 2 Bright A_SeekerMissile(0,4,SMF_PRECISE);
		Loop;
	}
}
class RS_RevenantTracer2 : RS_RevenantTracerHoming { Default { DamageType "Fire"; Damage 25; } }

// ---------- GREEN: seeking acid blast ----------
class RS_AcidBlast1 : Actor
{
	Default { Radius 6; Height 16; Speed 14; FastSpeed 25; Damage 30; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 1;
		SeeSound "baron/attack"; DeathSound "baron/shotx"; Decal "BaronScorch"; Translation "0:255=%[0.10,0.40,0.10]:[0.40,1.60,0.40]"; }
	States
	{
	Spawn:
		BAL7 AB 4 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		BAL7 CDE 6 Bright A_Explode(30,48);
		Stop;
	}
}

// ---------- BLUE: zap bolts ----------
class RS_Zap7 : Actor
{
	Default { Radius 6; Height 16; Speed 15; FastSpeed 32; Damage 35; DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.75;
		SeeSound "weapons/plasmaf"; DeathSound "weapons/plasmax"; Translation "0:255=%[0.10,0.10,0.50]:[0.40,0.40,2.00]"; }
	States { Spawn: PLSE AB 2 Bright; Loop; Death: PLSE BCDE 4 Bright; Stop; }
}
class RS_Zap8 : RS_Zap7 { Default { Radius 3; Height 8; FastSpeed 38; Damage 22; Scale 0.5; } }

// ---------- CYAN: big ball + chain-whip + ice orbs (SREV body) ----------
class RS_BigBallCrev : Actor
{
	Default { Radius 10; Height 10; Speed 38; XScale 1.25; YScale 0.75; RenderStyle "Add"; Alpha 0.95; Damage 16; DamageType "Ice"; Projectile; +SEEKERMISSILE; +DONTHARMCLASS;
		SeeSound "imp/attack"; DeathSound "Ice/Hit2"; Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States
	{
	Spawn:
		CHCY ABCD 3 Bright A_SeekerMissile(2,2);
		Loop;
	Death:
		CHCY EFG 4 Bright A_Explode(16,64);
		Stop;
	}
}
class RS_ChainWhipRev : Actor
{
	Default { Radius 2; Height 2; Speed 29; Mass 500; Damage 22; Projectile; DamageType "Melee"; +NOGRAVITY; +THRUGHOST; Gravity 1.25; Scale 0.25;
		DeathSound "weapons/boom1"; Translation "144:151=90:95"; }
	States { Spawn: BLL9 AB 2 Bright; Loop; Death: BLL9 CDE 3 Bright A_Explode(22,48); Stop; }
}
class RS_IceORBCyanRev : Actor
{
	Default { Radius 5; Height 5; Speed 20; Damage 14; DamageType "Ice"; Projectile; Scale 0.75; SeeSound "ice/Cast"; DeathSound "Ice/Hit2";
		Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"; }
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY CDE 4 Bright A_Explode(14,48); Stop; }
}

// ---------- PURPLE: seeking purp + zap99 lightning ----------
class RS_Purp1 : Actor
{
	Default { Radius 6; Height 16; Speed 13; FastSpeed 14; Damage 20; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.85;
		SeeSound "baron/attack"; DeathSound "weapons/plasmax"; Translation "16:47=250:254","128:143=250:254","152:191=250:254"; }
	States
	{
	Spawn:
		PLSS AB 4 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		PLSE ABCDE 4 Bright;
		Stop;
	}
}
class RS_Zap99 : Actor
{
	Default { Speed 1; Projectile; RenderStyle "Add"; Alpha 0.65; Scale 0.65; Damage 10; DamageType "Plasma"; Translation "16:47=250:254","152:191=250:254"; }
	States { Spawn: LITN ABCDEFGFEDB 1 Bright A_Explode(8,40); Goto Death; Death: LITN A 2 Bright; Stop; }
}

// ---------- YELLOW: lost-soul-like (uses skull-attack; no projectile in CH) ----------

// ---------- ABYSS: cracked-abyss + ice orbs (SplashAbyss2 shared) ----------
class RS_CrackedAbyssRev : Actor
{
	Default { Radius 4; Species "Revenant"; Height 4; Speed 18; Damage 36; DamageType "Plasma"; Projectile; +SEEKERMISSILE; Scale 0.85; RenderStyle "Add"; Alpha 1;
		SeeSound "Crack/see"; DeathSound "Crack/death"; Translation "Ice"; }
	States
	{
	Spawn:
		SPIR AB 3 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		SPIR CDE 4 Bright A_Explode(36,64);
		Stop;
	}
}
class RS_IceOrbAbyssRev : Actor
{
	Default { Radius 12; Height 12; Speed 15; Damage 30; DamageType "Ice"; Projectile; +SEEKERMISSILE; -NOGRAVITY; +BOUNCEONFLOORS; +USEBOUNCESTATE; BounceType "Doom"; BounceCount 2;
		RenderStyle "Add"; Alpha 0.85; Scale 1.5; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States
	{
	Spawn:
		ICEY AB 3 Bright A_SeekerMissile(2,2);
		Loop;
	Death:
		ICEY CDE 4 Bright A_Explode(30,64);
		Stop;
	}
}

// ---------- FIREBLU: fire skel balls ----------
class RS_FBSkelCH01 : Actor
{
	Default { Radius 8; Height 8; Speed 20; Damage 3; DamageType "Fire"; Projectile; +RANDOMIZE; +MTHRUSPECIES; +NOGRAVITY; RenderStyle "Add"; Alpha 0.95;
		SeeSound "fire/fire3"; DeathSound "weapons/plasmax";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States { Spawn: FIRE AB 2 Bright; Loop; Death: FIRE CDEFGH 3 Bright A_Explode(10,48); Stop; }
}

// ---------- BROWN: seeking brown balls (INCA body) ----------
class RS_BrownRevBall : Actor
{
	Default { Radius 8; Height 8; Speed 20; Damage 27; DamageType "Plasma"; Projectile; ProjectileKickBack 500; +RANDOMIZE; +DONTHARMCLASS; +SEEKERMISSILE;
		SeeSound "imp/attack"; DeathSound "weapons/rocklx"; Translation "0:255=%[0.31,0.23,0.18]:[1.10,0.74,0.40]"; }
	States
	{
	Spawn:
		BAL7 AB 4 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		BAL7 CDE 6 Bright A_Explode(27,64);
		Stop;
	}
}

// ---------- GRAY: bone-to-pick (RASK/ZKEL body) ----------
class RS_BoneToPickGrey : Actor
{
	Default { Radius 4; Height 4; Damage 25; Speed 36; DamageType "Melee"; Projectile; +BLOODLESSIMPACT; +SKYEXPLODE; +FORCEPAIN; Scale 0.75;
		Translation "0:255=[129,129,129]:[255,255,255]"; SeeSound "skeleton/attack"; DeathSound "spike/spiked"; }
	States { Spawn: BBBN AB 2 Bright; Loop; Death: BBBN CD 3 Bright; Stop; }
}

// ---------- RED: red death + mega (RASK body; MegaRedRev/HKRedDeath shared) ----------
class RS_RedDeathRev : Actor
{
	Default { Radius 5; Height 7; Speed 24; FastSpeed 38; Damage 55; DamageType "Fire"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.75; Scale 0.65;
		SeeSound "Forgotten/Attack"; DeathSound "weapons/rocklx"; Translation "0:255=%[0.50,0.00,0.00]:[2.00,0.40,0.40]"; }
	States
	{
	Spawn:
		BAL7 AB 3 Bright A_SeekerMissile(3,3);
		Loop;
	Death:
		BAL7 CDE 5 Bright A_Explode(55,80);
		Stop;
	}
}
// (RS_RedRevLoad already defined in hf_hk_projectiles.zs -- shared)

// ---------- WHITE: coils + frost bolts + ice-to-meet (REVW/WRTH body, HP8866) ----------
class RS_WhiteRevCoil : Actor
{
	Default { Radius 6; Height 6; Speed 24; Damage 55; DamageType "Melee"; Projectile; +THRUACTORS; +SEEKERMISSILE; Scale 0.15;
		SeeSound "baron/attack"; DeathSound "weapons/rocklx"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States { Spawn: BAL1 AB 2 Bright A_SeekerMissile(4,4); Loop; Death: BAL1 CDE 4 Bright A_Explode(55,48); Stop; }
}
class RS_WhiteRevCoil2 : RS_WhiteRevCoil {}
class RS_WhiteRevCoil3 : RS_WhiteRevCoil {}
class RS_WhiteRevCoil4 : RS_WhiteRevCoil {}
class RS_WhiteRevFrostBolt : Actor
{
	Default { Radius 8; Height 4; Speed 35; Projectile; +BRIGHT; RenderStyle "Add"; DamageType "Ice"; Damage 55; Scale 1.0;
		SeeSound "weapons/rocklf"; DeathSound "Bomb/boom"; Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY CDE 4 Bright A_Explode(55,80); Stop; }
}
class RS_IceToMeetWhiteRev : Actor
{
	Default { Radius 2; Height 2; Speed 28; Alpha 0.67; Projectile; +THRUACTORS; +THRUGHOST; +MTHRUSPECIES; -NOGRAVITY; +USEBOUNCESTATE;
		BounceType "Doom"; BounceCount 99; BounceFactor 1.0; WallBounceFactor 1.0; Damage 22; DamageType "Ice"; RenderStyle "Add";
		Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States { Spawn: ICEY AB 2 Bright; Loop; Death: ICEY CDE 3 Bright; Stop; }
}
// (RS_CyanCybieGunFlare already defined in hf_cyberdemon_projectiles.zs -- shared)

// ---------- YELLOW (REVN body): spitfire embers + hell-flame ----------
// Added by the rs_09 per-tier rebuild: the HF port had flattened the
// Yellow Revenant to a bare skull-charge; CH's real kit (CH decorate/
// Revenants.txt YellowRevenant) is spit embers, a Homer1 seeker pair
// (RS_Homer1 lives in RS_lostsoul_projectiles.zs, shared) and a
// vile-target hell-flame. CH's "Fire/fire*" sounds have no RS lumps ->
// vanilla vile fire sounds, per the alias policy in SNDINFO.
class RS_Firespe2 : Actor
{
	Default { Radius 1; Height 1; Speed 12; Mass 2; Gravity 0.4; BounceType "Heretic"; Damage 5; DamageType "Fire"; RenderStyle "Add"; Alpha 0.8;
		SeeSound "vile/firestrt"; }
	States
	{
	Spawn:
		FLUM ABCDE 4 Bright A_Jump(96, "Death");
		Loop;
	Death:
		MISL B 5 Bright;
		MISL C 5 Bright A_Explode(5, 40);
		MISL D 5 Bright;
		Stop;
	}
}
class RS_Firespe1 : Actor
{
	Default { Radius 1; Height 1; Speed 20; Mass 2; Gravity 0.4; BounceType "Heretic"; Damage 7; DamageType "Fire"; RenderStyle "Add"; Alpha 0.8;
		SeeSound "vile/firestrt"; }
	States
	{
	Spawn:
		FLUM ABCDE 4 Bright A_Jump(84, "Death");
		Loop;
	Death:
		MISL B 5 Bright;
		MISL C 5 Bright A_Explode(7, 64);
		MISL D 4 Bright
		{
			for (int i = 0; i < 6; i++)
				A_SpawnItemEx("RS_Firespe2", random(-32, 32), random(-32, 32), 2, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		}
		Stop;
	}
}
class RS_FirespeNewYel : Actor
{
	Default { Radius 4; Height 4; Speed 24; Mass 2; Damage 16; DamageType "Fire"; Projectile; RenderStyle "Add"; Alpha 0.8;
		SeeSound "vile/firestrt"; }
	States
	{
	Spawn:
		FLUM ABCDE 3 Bright;
		TNT1 A 0 { vel.z += random(2, 5); }
		FLUM ABCDE 3 Bright;
		Goto Death;
	Death:
		MISL B 5 Bright;
		MISL C 5 Bright A_Explode(7, 64);
		MISL D 5 Bright { A_SpawnItemEx("RS_Firespe2", 0, 0, 0, random(3, 9), 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		Stop;
	}
}
class RS_BigBadFire1 : Actor
{
	// Vile-target ground fire (A_VileTarget spawns it on the player).
	Default { Radius 1; Height 1; Speed 0; Mass 2; DamageType "Fire"; RenderStyle "Add"; Alpha 0.8; Scale 1.5;
		DeathSound "vile/firecrkl"; }
	States
	{
	Spawn:
		FLUM AB 3 Bright A_Explode(5, 25);
		FLUM CD 3 Bright A_Explode(5, 25);
		FLUM E 3 Bright A_Jump(104, "Death");
		Loop;
	Death:
		MISL B 5 Bright;
		MISL C 5 Bright A_Explode(random(4, 10), 64);
		MISL D 5 Bright
		{
			for (int i = 0; i < 5; i++)
				A_SpawnItemEx("RS_Firespe1", random(-32, 32), random(-32, 32), 2, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		}
		Stop;
	}
}


// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * FBXP -> BFE2 (FBXP exists nowhere; BFE2 is the vanilla BFG blast)  (2 occurrences)
