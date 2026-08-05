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
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY FGHI 4 Bright A_Explode(14,48); Stop; }
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
		ICEY FGHI 4 Bright A_Explode(30,64);
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
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY FGHI 4 Bright A_Explode(55,80); Stop; }
}
class RS_IceToMeetWhiteRev : Actor
{
	Default { Radius 2; Height 2; Speed 28; Alpha 0.67; Projectile; +THRUACTORS; +THRUGHOST; +MTHRUSPECIES; -NOGRAVITY; +USEBOUNCESTATE;
		BounceType "Doom"; BounceCount 99; BounceFactor 1.0; WallBounceFactor 1.0; Damage 22; DamageType "Ice"; RenderStyle "Add";
		Translation "0:255=%[0.49,0.51,1.52]:[1.10,2.00,1.97]"; }
	States { Spawn: ICEY AB 2 Bright; Loop; Death: ICEY FGHI 3 Bright; Stop; }
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

// =====================================================================
// CHP 08 rebuild additions -- every actor below is referenced by
// RS_Revenant.zs / RS_RevenantShade and was ported from its CH/CHP
// source, not invented. A_SpawnParticle walls are stripped throughout.
// =====================================================================

// ---------- shared: the bone shards every revenant XDeath throws ----------
// CH Gibs.txt CH_BoneGib.
class RS_CHBoneGib : Actor
{
	Default { Radius 2; Height 3; Damage 0; Speed 2; Projectile;
		BounceType "Doom"; +MOVEWITHSECTOR; +CANNOTPUSH; -NOGRAVITY; +NOTONAUTOMAP;
		BounceFactor 0.5; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 ThrustThingZ(0, 55, 0, 1);
		Goto Wee;
	Wee:
		BBBN ABCD 4;
		Loop;
	Crash:
	Death:
		BBBN ABD 1;
		BBBN C 850;
		Stop;
	}
}

// ---------- T04 PURPLE: the railgun's puff ----------
// CH Fatsos.txt FatsoPuff3.
// Defined in RS_manc_projectiles.zs, where the rest of the Fatsos.txt shots
// live. That copy is a verbatim match for the source actor.

// ---------- T05 YELLOW: the ring of fire its gib-death lays down ----------
// CH Revenants.txt archvilefire2 : archvilefire (stock GZDoom parent).
class RS_ArchvileFire2 : ArchvileFire
{
	Default { Speed 5; Damage 0; Projectile; +NOCLIP; +THRUACTORS; }
}

// ---------- T07 FIREBLU: the red/blue weaving barrage ----------
// CH Revenants.txt FBSkelCH02/03/04 + their trailers.
class RS_FBSkelTrailer : Actor
{
	Default { Radius 2; Height 2; Speed 0; +NOCLIP; +NOGRAVITY;
		RenderStyle "Add"; Alpha 0.45;
		Translation "0:255=%[0.35,0.00,0.00]:[2.00,0.50,0.50]"; }
	States { Spawn: PLSS AB 4 Bright; Death: TNT1 A 0; Stop; }
}
class RS_FBSkelTrailer2 : RS_FBSkelTrailer
{
	Default { Translation "0:255=%[0.00,0.00,0.94]:[0.80,0.80,2.00]"; }
}
class RS_FBSkelCH02 : Actor
{
	Default { Radius 8; Height 8; Speed 20; Damage 3; DamageType "Fire";
		Projectile; +RANDOMIZE; +MTHRUSPECIES; +NOGRAVITY; RenderStyle "Add";
		Alpha 0.95; SeeSound "fire/fire3"; DeathSound "weapons/plasmax";
		Translation "0:255=%[0.00,0.00,0.94]:[0.80,0.80,2.00]"; }
	States
	{
	Spawn:
		PLSS AB 6 Bright;
		Goto Fly;
	Fly:
		TNT1 A 0 { bNOGRAVITY = false; }
		PLSS AB 6 Bright;
		Loop;
	XDeath:
	Death:
		MISL BCD 6 Bright { A_Explode(random(7, 18), 64, 0); }
		Stop;
	}
}
class RS_FBSkelCH03 : Actor
{
	Default { Radius 8; Height 8; Speed 17; Damage 3; DamageType "Fire";
		Projectile; +RANDOMIZE; +MTHRUSPECIES; SeeSound "fire/fire3";
		DeathSound "weapons/plasmax"; RenderStyle "Add"; Alpha 0.95;
		WeaveIndexXY 10; WeaveIndexZ 1;
		Translation "0:255=%[0.35,0.00,0.00]:[2.00,0.50,0.50]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		PLSS A 3 Bright { A_Weave(6, 0, -1.5, 0.0); }
		TNT1 A 0 { A_SpawnItemEx("RS_FBSkelTrailer2", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		PLSS B 3 Bright { A_Weave(6, 0, -1.5, 0.0); }
		TNT1 A 0 { A_SpawnItemEx("RS_FBSkelTrailer2", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		MISL BCD 6 Bright { A_Explode(random(5, 15), 64, 0); }
		Stop;
	}
}
class RS_FBSkelCH04 : Actor
{
	Default { Radius 8; Height 8; Speed 17; Damage 3; DamageType "Fire";
		Projectile; +RANDOMIZE; +MTHRUSPECIES; RenderStyle "Add"; Alpha 0.95;
		SeeSound "fire/fire3"; DeathSound "weapons/plasmax";
		WeaveIndexXY 10; WeaveIndexZ 1;
		Translation "0:255=%[0.00,0.00,0.94]:[0.80,0.80,2.00]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		PLSS A 3 Bright { A_Weave(6, 0, 1.5, 0.0); }
		TNT1 A 0 { A_SpawnItemEx("RS_FBSkelTrailer", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		PLSS B 3 Bright { A_Weave(6, 0, 1.5, 0.0); }
		TNT1 A 0 { A_SpawnItemEx("RS_FBSkelTrailer", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		MISL BCD 6 Bright { A_Explode(random(5, 15), 64, 0); }
		Stop;
	}
}
// The exploding punch.
class RS_BoomSkel1 : Actor
{
	Default { Radius 2; Height 2; Speed 10; Damage 4; DamageType "Fire";
		Projectile; +RANDOMIZE; +MTHRUSPECIES; RenderStyle "Add"; Alpha 0.75; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Death;
	Death:
		MISL B 2 Bright { A_Explode(random(20, 50), 64, 0); }
		MISL CD 2 Bright;
		Stop;
	}
}

// ---------- T11 BLACK KNIGHT: the shield, its blast, and the drops ----------
// CH Revenants.txt RevShieldWalk / ShieldBlastRev / DKSword / DKShield.
class RS_RevShieldWalk : Actor
{
	Default { Radius 64; Height 56; Speed 0; Species "MontyP"; Health 999;
		Monster; +NOTRIGGER; +NOTARGET; +DONTTHRUST; +NOGRAVITY;
		+INVULNERABLE; +REFLECTIVE; +DEFLECT; +SHIELDREFLECT; +THRUSPECIES;
		-COUNTKILL; RenderStyle "Add"; Alpha 1.0; Scale 1.25; }
	States
	{
	Spawn:
		DKNT Z 3 Bright { A_Warp(AAPTR_MASTER, 24, 0, 42, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		DKNT Z 3 Bright { A_Warp(AAPTR_MASTER, 24, 0, 42, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		DKNT Z 3 Bright { A_Warp(AAPTR_MASTER, 24, 0, 42, 0, WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		Loop;
	Death:
		DKNT Z 2 Bright { A_NoBlocking(); }
		DKNT Z 2 Bright { A_SetScale(1.0); }
		DKNT Z 2 Bright { A_SetScale(0.7); }
		DKNT Z 2 Bright { A_SetScale(0.4); }
		TNT1 A 0 { A_Die(); }
		Stop;
	}
}
class RS_ShieldBlastRev : Actor
{
	Default { Radius 6; Height 8; Speed 12; Damage 37; DamageType "Fire";
		Projectile; +SEEKERMISSILE; +MTHRUSPECIES; RenderStyle "Add";
		Alpha 0.75; XScale 1.0; YScale 1.45; SeeSound "fire/fire3";
		DeathSound "spell/Impact1";
		Translation "76:79=44:47", "136:143=184:191", "128:136=175:183",
			"64:79=176:191", "208:223=171:181", "161:161=170:170", "144:151=180:191"; }
	States
	{
	Spawn:
		FRGO CC 2 Bright { A_SeekerMissile(12, 18); }
		FRGO DD 2 Bright { A_SetSpeed(16); }
		FRGO CC 2 Bright { A_SeekerMissile(12, 18); }
		FRGO DD 2 Bright { A_SetSpeed(20); }
		FRGO CC 2 Bright { A_SeekerMissile(12, 18); }
		FRGO DD 2 Bright { A_SetSpeed(24); }
		FRGO CC 2 Bright { A_SeekerMissile(12, 18); }
		FRGO DD 2 Bright { A_SetSpeed(30); }
	Fly:
		FRGO CC 2 Bright { A_SeekerMissile(12, 18); }
		FRGO DD 2 Bright { A_SeekerMissile(12, 18); }
		Loop;
	Death:
		BBOM A 2 Bright { A_SetScale(1.5); }
		BBOM B 2 { A_SetTranslucent(0.65); }
		BBOM CD 3 Bright { A_Explode(random(5, 25), 148); }
		BBOM EFG 6 Bright { A_Explode(random(5, 20), 148); }
		Stop;
	}
}
class RS_DKSword : Actor
{
	Default { Radius 8; Height 8; Speed 1; Projectile; RenderStyle "Normal";
		-NOGRAVITY; Gravity 0.125; }
	States
	{
	Spawn:
		SWRD KLMNOPQ 3 Bright;
		Goto Death;
	Death:
		SWRD RS 4 Bright;
		SWRD T 4 Bright;
		SWRD U 4;
		SWRD T 4 Bright;
		SWRD U 8;
		SWRD T 4 Bright;
		SWRD U 16;
		SWRD T 4 Bright;
		SWRD U -1;
		Stop;
	}
}
class RS_DKShield : Actor
{
	Default { Radius 8; Height 8; Speed 1; Projectile; RenderStyle "Normal";
		-NOGRAVITY; Gravity 0.125; }
	States
	{
	Spawn:
		SHLD ABCDEFGHI 3;
		Goto Death;
	Death:
		SHLD H -1;
		Stop;
	}
}

// ---------- SHADE (CHP CommonBlackRev2): its three attacks ----------
// CH Revenants.txt RevSol / DKFire2 / DKFire / SoulSeekerRev.
class RS_RevSol : Actor
{
	Default { Radius 3; Height 12; Speed 32; Damage 30; RenderStyle "Add";
		DamageType "Fire"; Alpha 0.85; Projectile; +THRUGHOST;
		SeeSound "monster/dkndrt"; DeathSound "weapons/firex2";
		Translation "175:191=160:167"; }
	States
	{
	Spawn:
		DKAT ABC 3 Bright;
		Loop;
	Death:
		DKAT D 0 { A_SetTranslucent(0.85, 1); }
		DKAT D 3 Bright { A_SetScale(1.5); }
		DKAT E 3 Bright { A_Explode(random(5, 30), 128); }
		DKAT FGH 3 Bright;
		DKAT IJKLM 3 Bright;
		Stop;
	}
}
class RS_DKFire : Actor
{
	Default { Radius 2; Height 6; Speed 6; Damage 0; ExplosionDamage 4;
		ExplosionRadius 8; RenderStyle "Add"; Alpha 0.95; Projectile;
		+THRUGHOST; +MTHRUSPECIES; DeathSound "weapons/scorch"; }
	States
	{
	Spawn:
		DKAT NOPQRSTNOPQRSTNOPQRST 3 Bright { A_Explode(); }
		Goto Death;
	Death:
		DKAT UVW 3 Bright { A_Explode(); }
		Stop;
	}
}
class RS_DKFire2 : Actor
{
	Default { Radius 2; Height 6; Speed 8; Damage 0; RenderStyle "Add";
		Alpha 0.95; Projectile; +THRUGHOST; +MTHRUSPECIES;
		DeathSound "weapons/scorch";
		Translation "168:191=192:208", "32:47=201:207"; }
	States
	{
	Spawn:
		DKAT NOPQRSTNOPQRSTNOPQRST 3 Bright { A_Explode(random(5, 15), 12); }
		DKAT N 4 A_Jump(12, "Death");
		Loop;
	Death:
		DKAT UVW 3 Bright { A_Explode(random(5, 20), 20); }
		DKAT H 0 { A_SpawnProjectile("RS_DKFire", 0, 0, 45, 2); }
		DKAT H 0 { A_SpawnProjectile("RS_DKFire", 0, 0, 90, 2); }
		DKAT H 0 { A_SpawnProjectile("RS_DKFire", 0, 0, 135, 2); }
		DKAT H 0 { A_SpawnProjectile("RS_DKFire", 0, 0, 180, 2); }
		DKAT H 0 { A_SpawnProjectile("RS_DKFire", 0, 0, 225, 2); }
		DKAT H 0 { A_SpawnProjectile("RS_DKFire", 0, 0, 270, 2); }
		DKAT H 0 { A_SpawnProjectile("RS_DKFire", 0, 0, 315, 2); }
		DKAT H 3 Bright { A_SpawnProjectile("RS_DKFire", 0, 0, 0, 2); }
		Stop;
	}
}
class RS_SoulSeekerRev : Actor
{
	Default { Radius 4; Height 8; Speed 22; Damage 12; RenderStyle "Add";
		DamageType "Melee"; Alpha 0.85; Scale 0.45; Projectile;
		+THRUGHOST; +MTHRUSPECIES; +SEEKERMISSILE;
		SeeSound "skull/melee"; DeathSound "weapons/firex2";
		Translation "175:191=193:207", "32:47=240:246"; }
	States
	{
	Spawn:
		UNHE AB 4 Bright { A_SeekerMissile(12, 24, SMF_PRECISE); }
		Loop;
	Death:
		DKAT D 0 { A_SetTranslucent(0.85, 1); }
		DKAT D 3 Bright { A_SetScale(1.0); }
		DKAT E 3 Bright { A_Explode(random(5, 20), 64); }
		DKAT FGH 3 Bright;
		DKAT IJKLM 3 Bright;
		Stop;
	}
}

// ---------- T12 THE LICH: shades, frost, ground channel, summons ----------
// CH Revenants.txt EvilShadeWhiteRev(2), IceGroundWhiteRev,
// DarkChannelWhiteRev, ByeWhiteRevCast; CH Barons.txt FrostWingBaron2;
// CH Zombies.txt MrBones; CH CYBIES.txt PortalSummons.
class RS_EvilShadeWhiteRev : Actor
{
	Default { Radius 20; Height 56; Speed 14; Damage 4; DamageType "Melee";
		Projectile; +NOCLIP; +DONTHARMCLASS; }
	States
	{
	Spawn:
		REVW NOPQRS 2;
		Goto Death;
	Death:
		TNT1 A 1;
		Stop;
	}
}
class RS_EvilShadeWhiteRev2 : RS_EvilShadeWhiteRev
{
	Default { XScale 1.0; YScale 0.15; }
}
// RS_FrostWingBaron2 is defined in RS_baron_projectiles.zs (CH Barons.txt), a
// verbatim match for the source actor.
class RS_IceGroundWhiteRev : Actor
{
	Default { Radius 9; Height 9; DamageType "Ice"; Damage 49; Projectile;
		+FLOORHUGGER; DeathSound "Ice/Splode"; }
	States
	{
	Spawn:
		"1C3F" DCB 10 Bright;
	Fly:
		"1C3F" AA 15 Bright;
		TNT1 A 0 A_Jump(12, "Death");
		Loop;
	Death:
		PUFI ABCD 3 Bright;
		TNT1 AAAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", random(-6, 6), random(-6, 6), random(12, 64), random(1, 13), 0, random(1, 13), random(0, 360)); }
		TNT1 AAAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", random(-6, 6), random(-6, 6), random(12, 64), random(1, 13), 0, random(1, 13), random(0, 360)); }
		TNT1 AAAAAA 0 { A_SpawnItemEx("RS_SpikeCyanRev", random(-6, 6), random(-6, 6), random(12, 64), random(1, 13), 0, random(1, 13), random(0, 360)); }
		PUFI EFGH 2 Bright;
		Stop;
	}
}
class RS_ByeWhiteRevCast : Inventory { Default { Inventory.MaxAmount 1; } }
// The lich's ground channel. CH's CastTargetingWhiteRev1-4 reticles and
// CybieZappy sparks are decoration only and are not ported; the damaging
// pulse loop, its growth stages and the ByeWhiteRevCast dismiss are.
class RS_DarkChannelWhiteRev : Actor
{
	Default { Radius 12; Height 9; Speed 0; Alpha 0.95; DamageType "Plasma";
		Projectile; +DONTHARMCLASS; +FLOORHUGGER; +THRUACTORS; +FLATSPRITE;
		DeathSound "Litn/litn3"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Mark:
		TNT1 A 0 { A_StartSound("Forgotten/Attack", CHAN_BODY); }
		TNT1 A 10;
		TNT1 A 10;
		D4RC A 8 { A_SetScale(0.1, 0.1); }
		D4RC B 8 { A_SetScale(0.3, 0.3); }
		D4RC C 8 { A_SetScale(0.5, 0.5); }
		D4RC D 8 { A_SetScale(0.7, 0.7); }
		D4RC E 8 { A_SetScale(1.0, 1.0); }
		Goto Fly;
	Fly:
		TNT1 A 0 A_JumpIfInventory("RS_ByeWhiteRevCast", 1, "Death");
		TNT1 A 0 { A_StartSound("Litn/litn3", CHAN_BODY); }
		D4RC ABCDE 5 Bright { A_Explode(random(10, 80), 256, 0); }
		D4RC A 1 Bright { A_Explode(random(10, 80), 256, 0); }
		D4RC E 1 Bright { A_Explode(random(10, 80), 256, 0); }
		TNT1 A 0 A_Jump(102, "Fly2");
		Loop;
	Fly2:
		D4RC A 1 { A_SetScale(1.1, 1.1); }
		D4RC B 1 { A_SetScale(1.3, 1.3); }
		D4RC C 1 { A_SetScale(1.5, 1.5); }
		D4RC D 1 { A_SetScale(1.7, 1.7); }
		D4RC E 1 { A_SetScale(2.0, 2.0); }
	Fly3:
		TNT1 A 0 A_JumpIfInventory("RS_ByeWhiteRevCast", 1, "Death");
		TNT1 A 0 { A_StartSound("Litn/litn3", CHAN_BODY); }
		D4RC ABCDE 3 Bright { A_Explode(random(10, 80), 512, 0); }
		D4RC A 1 Bright { A_Explode(random(10, 80), 512, 0); }
		D4RC E 1 Bright { A_Explode(random(10, 80), 256, 0); }
		Loop;
	Death:
		D4RC A 1 { A_SetScale(0.6, 0.6); }
		D4RC B 1 { A_SetScale(0.4, 0.4); }
		D4RC C 1 { A_SetScale(0.2, 0.2); }
		D4RC D 1 { A_SetScale(0.1, 0.1); }
		Stop;
	}
}
// The skeletons the lich raises. CH Zombies.txt MrBones; its ACS-free
// halves are kept, its ammo DropItems and BoneUp radius-gives are not.
class RS_MrBones : Actor
{
	Default
	{
		Health 50;
		PainChance 180;
		Speed 12;
		Radius 24;
		Height 56;
		Mass 100;
		GibHealth -60;
		Scale 0.9;
		Species "UnderTaker";
		SeeSound "skelsit"; PainSound "skelpai"; DeathSound "skeldth";
		Monster;
		+NOBLOOD +LOOKALLAROUND +NOBLOCKMONST +NOFEAR +DONTDRAIN +NOCLIP
		+DONTHARMSPECIES
		-COUNTKILL
		HitObituary "%o's funnybone was tickled by a skeleton";
		Tag "The ride";
	}
	States
	{
	Spawn:
		SKLT R 10 { A_Look(); }
		Loop;
	See:
		SKLT AABB 2 { A_Chase("Melee", null, CHF_STOPIFBLOCKED); }
		SKLT DDCC 2 { A_Chase("Melee", null, CHF_STOPIFBLOCKED); }
		SKLT EEFF 2 { A_Chase("Melee", null, CHF_STOPIFBLOCKED); }
		Loop;
	Melee:
		SKLT GH 4 { A_FaceTarget(); }
		SKLT I 4 { A_StartSound("skelatt", CHAN_AUTO); }
		SKLT J 4 { A_CustomMeleeAttack(random(1, 6) * 4, "swordhit", "none"); }
		SKLT K 4 { A_FaceTarget(); }
		Goto See;
	Pain:
		SKLT L 2;
		SKLT L 2 { A_Pain(); }
		Goto See;
	Death:
		SKLT M 4 { A_Scream(); }
		SKLT N 4 { A_NoBlocking(); }
		SKLT O 8 { A_NoBlocking(); }
		// RESTORED. CHP 01_W.txt:3027-3029 pays the Undertaker on this
		// exact frame: random(12,128) health and one BoneUp, radius 528,
		// filtered to the boss class. THIS IS THE WHOLE MECHANIC --
		// killing the skeletons is what heals and levels the Undertaker.
		// Our port had MrBones defined and never spawned, and the boss
		// climbing its ladder from Pain instead. See
		// zscript/monsters/Zombieman/attacks/RS_Zombieman_Undertaker.zs.
		SKLT P 12 { A_SpawnItemEx("RS_BoneTithe", 0, 0, 4, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto Vanish;
	Vanish:
		SKLT Q 20 { A_FadeOut(0.3); }
		SKLT Q 15 { A_FadeOut(0.3); }
		SKLT Q 10 { A_FadeOut(0.3); }
		Stop;
	}
}
// The lich's portal. CH PortalSummons is a RandomSpawner over CH monster
// classes; each is mapped to the RS class that replaces it, so the same
// creatures come through the portal.
class RS_PortalSummons : RandomSpawner
{
	Default
	{
		DropItem "RS_Revenant", 255, 300;
		DropItem "RS_LostSoul", 255, 200;
		DropItem "RS_Zombieman", 255, 80;
		DropItem "RS_Shotgunner", 255, 50;
		DropItem "RS_Chaingunner", 255, 70;
		DropItem "RS_Imp", 255, 300;
		DropItem "RS_Demon", 255, 150;
		DropItem "RS_Cacodemon", 255, 50;
	}
}

// =====================================================================
// CHP 08_KX -- BLACK REVENANT EX / THE BLACK KNIGHT UNLEASHED
// (the TEX rung of RS_Revenant).
// ---------------------------------------------------------------------
// The four pieces the TEX cluster needs that the T11 knight did not.
// Bodies from CH decorate/Revenants.txt; call sites from CHP 08_KX.txt.
// =====================================================================

// The black smear the EX knight leaves on every stride. CH BlackRevShade.
class RS_BlackRevShade : Actor
{
	Default { Radius 6; Height 6; Speed 1; Projectile; +NOCLIP; +NOINTERACTION;
		RenderStyle "Stencil"; StencilColor "black"; SeeSound "Imp/Attack";
		DeathSound "Fire/fire5"; Alpha 0.55; YScale 3.25; XScale 1.95; }
	States { Spawn: FLUM ACDBE 3 Bright; Stop; }
}

// The grapple. CH BlackRevHook inherits Loreshot, which lives in neither
// the CH nor the CHP decorate tree (it is a DoomRL Arsenal actor), so the
// properties CH sets on top of it are declared outright here -- PROJECTILE
// is in CH's own block, nothing was inferred from the missing parent.
class RS_BlackRevHook : Actor
{
	Default { Radius 6; Height 6; Speed 42; DamageFunction (random(5, 30)); Projectile;
		DamageType "Melee"; +THRUGHOST; +MTHRUSPECIES;
		SeeSound "monster/dknmsl"; DeathSound "weapons/firex4"; }
	States
	{
	Spawn:
		BLAD A 1 Bright { A_SpawnItemEx("RS_FatsoSpikes2", 0, 0, 1, 0, 0, 0, 0, SXF_NOPOINTERS|SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		BLAD A 10;
		BLAD A 10;
		BLAD AAA 10 { A_FadeOut(0.33); }
		Stop;
	}
}

// The second shield disc. RS_RevShieldWalk (already in this file) hangs off
// the master; this one hangs off TARGET and orbits, so the pair sweep the
// knight from two sides at once. CHP's user_angle is the private field.
class RS_RevShieldWalk2 : Actor
{
	private int rsOrbitAngle;

	Default
	{
		Radius 64;
		Height 56;
		Speed 16;
		Health 999;
		Monster;
		+NOTRIGGER +NOTARGET +DONTTHRUST +NOGRAVITY +INVULNERABLE
		+MTHRUSPECIES +REFLECTIVE +DEFLECT +SHIELDREFLECT +THRUSPECIES
		-COUNTKILL
		Species "MontyP";
		RenderStyle "Add";
		Alpha 1.0;
		Scale 1.25;
	}

	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 { rsOrbitAngle += 8; }
		DKNT Z 1 Bright { A_Warp(AAPTR_TARGET, 64, 0, 64, rsOrbitAngle + 8, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE); }
		TNT1 A 0 A_Jump(2, "Death");
		Loop;
	Death:
		DKNT Z 2 Bright { A_NoBlocking(); }
		DKNT Z 2 Bright { A_SetScale(1.0); }
		DKNT Z 2 Bright { A_SetScale(0.7); }
		DKNT Z 2 Bright { A_SetScale(0.4); }
		Stop;
	}
}

// The thirty-two-shot cluster the EX shield blast throws before the blast
// itself lands. CH ShieldBombRev.
class RS_ShieldBombRev : Actor
{
	Default { Radius 4; Height 6; Mass 5; Speed 34; Projectile; Scale 0.55;
		DamageFunction (random(2, 25)); DamageType "Fire"; SeeSound "imp/attack";
		DeathSound "weapons/firex4"; Translation "208:223=176:191", "224:231=176:176"; }
	States
	{
	Spawn:
		BAL1 ABA 1;
		Loop;
	Death:
		BAL1 CDE 1 { A_SetTranslucent(0.35); }
		Stop;
	}
}
