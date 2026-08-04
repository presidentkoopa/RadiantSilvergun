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

// =====================================================================
// CHP 07 rebuild additions -- every actor below is referenced by
// RS_Spectre.zs and was ported from its CH/CHP source, not invented.
// =====================================================================

// ---------- T03 CYAN: the frozen fairy the ice worm leaves behind ----------
// CH Gibs.txt CH_cirno (CHP CH_Cirno_C adds only a tint).
class RS_CHCirno : Actor
{
	Default { Radius 3; Height 6; Speed 1; Scale 1.0; Damage 0; Projectile;
		+MOVEWITHSECTOR; +CANNOTPUSH; -NOGRAVITY; +NOTONAUTOMAP; Gravity 0.05; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 ThrustThingZ(0, 5, 0, 1);
		Goto Wee;
	Wee:
		CIRN A 5;
		Loop;
	Crash:
	Death:
		CIRN A -1;
		Stop;
	}
}

// ---------- T08 BROWN: the prowler's rally medi-orbs ----------
// CH Cacodemons.txt MediCacoBrown / MediCacoBrown2.
// [dedupe] duplicate class RS_MediCacoBrown removed -- defined earlier in the load order.
class RS_MediCacoBrown2 : Actor
{
	Default { Radius 2; Height 2; Mass 7; Speed 4; Projectile; +THRUACTORS;
		Scale 0.45; RenderStyle "Add"; Alpha 0.33;
		Translation "208:223=176:191", "224:231=176:176"; }
	States
	{
	Spawn:
		BAL1 AB 7;
		Goto Death;
	Death:
		BAL1 A 1 { A_SetTranslucent(0.1); }
		Stop;
	}
}

// ---------- T05 / T10 BLOOD DEMON: the arm that flies off on death ----------
// CH Demons.txt BloodDemonArm / BloodDemonArm2 (the 2 has no tint).
class RS_BloodDemonArm : Actor
{
	Default { Radius 8; Height 8; Speed 8; +DOOMBOUNCE; +DROPOFF; +MISSILE;
		Translation "168:191=160:167", "16:31=208:216", "32:40=215:223", "41:46=232:235", "47:47=190:190"; }
	States
	{
	Spawn:
		SG2A ABCDEFGH 2;
		Loop;
	Death:
		SG2A I -1;
		Stop;
	}
}
class RS_BloodDemonArm2 : Actor
{
	Default { Radius 8; Height 8; Speed 8; +DOOMBOUNCE; +DROPOFF; +MISSILE; }
	States
	{
	Spawn:
		SG2A ABCDEFGH 2;
		Loop;
	Death:
		SG2A I -1;
		Stop;
	}
}

// ---------- T11 BLACK: the Rogue's after-images ----------
// CH spectres.txt ShadowGhostA..D.
class RS_ShadowGhostA : Actor
{
	Default { Radius 4; Height 8; Speed 0; Damage 0; Mass 75;
		RenderStyle "Translucent"; Alpha 0.25; Projectile; }
	States { Spawn: SHDW A 10; Stop; }
}
class RS_ShadowGhostB : RS_ShadowGhostA { States { Spawn: SHDW B 10; Stop; } }
class RS_ShadowGhostC : RS_ShadowGhostA { States { Spawn: SHDW C 10; Stop; } }
class RS_ShadowGhostD : RS_ShadowGhostA { States { Spawn: SHDW D 10; Stop; } }

// ---------- T11 BLACK: the blink destination marker ----------
// CH spectres.txt TeleporterSpotSH -- a bouncing invisible SpecialSpot the
// Rogue throws ahead of itself and then A_Teleports onto. CH's DropItem
// ammo list is dropped (RS has its own drop system).
class RS_TeleporterSpotSH : SpecialSpot
{
	Default { Radius 6; Height 8; Speed 128; Mass 25; Projectile;
		+FLOORHUGGER; +THRUACTORS; +RANDOMIZE; +BOUNCEONWALLS; +INVISIBLE;
		BounceCount 999; BounceType "Doom"; DamageType "Fire";
		BounceFactor 1; WallBounceFactor 1.5; RenderStyle "Add";
		SeeSound "Fire/fire3"; Alpha 0.8; Scale 1.0; }
	States
	{
	Spawn:
		RED8 ABCCCCCCFGHHHHHH 1 Bright { A_Wander(); }
		RED8 D 0 A_Jump(32, "Death");
		Loop;
	Death:
		RED8 ABCD 4 Bright { A_SetScale(0.5); }
		RED8 CDE 1 { A_NoBlocking(); }
		Stop;
	}
}

// ---------- T12 WHITE: the Slime Golem's three volleys ----------
// CH spectres.txt SpecSlime1/2/3. A_SpawnParticle trails stripped.
class RS_SpecSlime1 : Actor
{
	Default { Radius 4; Height 4; Speed 17; Damage 40; PoisonDamage 15;
		SeeSound "Shadow/attack"; DeathSound "imp/shotx"; Scale 0.75;
		Projectile; +BOUNCEONWALLS; WallBounceFactor 1; BounceCount 3; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		BOGY ABC 1 Bright;
		Loop;
	Death:
		BOGY DEF 4 Bright;
		Stop;
	}
}
class RS_SpecSlime2 : Actor
{
	Default { Radius 4; Height 4; Speed 24; Damage 25; PoisonDamage 5;
		SeeSound "Shadow/attack"; DeathSound "imp/shotx"; Scale 0.4; Projectile; }
	States
	{
	Spawn:
		BOGY ABC 1 Bright;
		Loop;
	Death:
		BOGY DEF 4 Bright;
		Stop;
	}
}
class RS_SpecSlime3 : Actor
{
	Default { Alpha 1.0; RenderStyle "Add"; Speed 7; Radius 14; Height 9;
		Damage 30; Scale (0.1, 1.8); DamageType "Plasma"; Projectile;
		+SEEKERMISSILE; +RIPPER; +FLOORHUGGER;
		SeeSound "shadowbeast/pr1sight"; DeathSound "shadowbeast/pr1death"; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Fly;
	Fly:
		BDP1 E 2 Bright { A_SeekerMissile(5, 4); }
		BDP1 D 2 Bright { A_SeekerMissile(3, 6); }
		BDP1 E 2 Bright { A_SeekerMissile(12, 7); }
		Loop;
	Death:
		BDP2 DE 4 Bright;
		BDP2 FGH 3 Bright;
		Stop;
	}
}

// ---------- T12 WHITE: the leaping worm the golem coughs up ----------
// CH spectres.txt Wakawaka.
class RS_Wakawaka : Actor
{
	Default
	{
		Health 320;
		PainChance 120;
		Species "Demon1";
		BloodColor "Green";
		Speed 16;
		Radius 30;
		Height 56;
		Damage 47;
		Mass 4000;
		Monster;
		+NEVERTARGET
		+NOINFIGHTING
		+DONTHARMSPECIES
		+DONTHURTSPECIES
		AttackSound "EWorm/Bite";
		SeeSound "EWorm/Sight";
		ActiveSound "EWorm/Idle";
		PainSound "Worm/Hurt";
		Obituary "%o got nommed up";
		MeleeRange 60;
		Tag "You're not pacman";
	}
	States
	{
	Spawn:
		EWRM A 8 { A_Look(); }
		Loop;
	See:
		EWRM A 1 { A_Chase(); }
		Loop;
	Missile:
		EWRM A 0 A_JumpIfCloser(60, "Melee");
		EWRM A 1 { A_FaceTarget(); }
		TNT1 A 0 { A_StartSound("Worm/Hurt", CHAN_VOICE); }
		EWRM A 0 ThrustThingZ(0, random(6, 13), 0, 0);
		TNT1 A 0 { ThrustThing(int(angle * 256 / 360), 21, 0, 0); }
	MidLeap:
		EWRM A 1 A_CheckFloor("Land");
		TNT1 A 0 A_CheckFloor("Land");
		Loop;
	Land:
		EWRM A 1 { A_Stop(); }
		Goto See;
	Melee:
		EWRM B 5 { A_FaceTarget(); }
		EWRM A 11 { A_CustomMeleeAttack(random(10, 45), "", "", "Melee", false); }
		Goto See;
	Pain:
		EWRM B 7 { A_Pain(); }
		Goto See;
	Death:
		TWIA ABAC 1;
		TNT1 A 0 { A_StartSound("Worm/Death", CHAN_VOICE); }
		TWIA ABACABACABACABAC 1;
		DEAE AB 4;
		TNT1 A 1 { A_StartSound("weapons/rocklx", CHAN_BODY); }
		MISL BCD 6 { A_Explode(random(10, 50), 64); }
		Stop;
	}
}

// =====================================================================
// CHP 07_KX -- BLACK SPECTRE EX (the TEX rung of RS_Spectre).
// ---------------------------------------------------------------------
// Everything the TEX cluster in RS_Spectre.zs spawns or fires. Sources:
// CHP 07_KX.txt for the EX actors, CH decorate/spectres.txt for the one
// pre-EX parent (ShadowTrail). CHP's _C colour suffix is dropped -- RS
// carries one projectile per family and lets the tier dial colour it.
// =====================================================================

// The generic shadow smear every shadow projectile drags. CH ShadowTrail.
class RS_ShadowTrail : Actor
{
	Default { Radius 1; Height 1; Speed 0; Projectile; RenderStyle "Add"; Alpha 0.5; +NOCLIP; }
	States { Spawn: SHTR ABCDEF 4 Bright; Stop; }
}

// ---------- the walk ghosts ----------
// One per stride frame. The EX rogue drops one on every step, so what you
// are shooting at is usually four frames behind where it actually is --
// that is the whole read of the fight, not decoration.
class RS_ShadowGhostEXB : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +NOCLIP;
		RenderStyle "Translucent"; XScale 1.2; YScale 0.85; Alpha 0.25; }
	States { Spawn: GKEX B 10; Stop; }
}
class RS_ShadowGhostEXC : RS_ShadowGhostEXB { States { Spawn: GKEX C 10; Stop; } }
class RS_ShadowGhostEXD : RS_ShadowGhostEXB { States { Spawn: GKEX D 10; Stop; } }
class RS_ShadowGhostEXE : RS_ShadowGhostEXB { States { Spawn: GKEX E 10; Stop; } }

// The one it leaves at the mouth of a blink, and the one it leaves dying.
class RS_ShadowWarpGhostEX : RS_ShadowGhostEXB
{
	States { Spawn: GKEX AAAAAAAAAA 12 { A_FadeOut(alpha * 0.3); } Stop; }
}
class RS_ShadowDeathGhostEX : RS_ShadowGhostEXB
{
	States
	{
	Spawn:
		GKEX NO 12;
		GKEX PQRS 13 { A_FadeOut(0.1); }
		Stop;
	}
}

// ---------- the standard volley ----------
// Bounces twice off walls, so a corridor is worse than open ground.
class RS_ShadowBallEX1 : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 20;
		XScale 1.5;
		YScale 0.5;
		DamageFunction (random(20, 55));
		Projectile;
		+RANDOMIZE +BOUNCEONWALLS
		BounceCount 2;
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.75;
		SeeSound "Shadow/attack";
		DeathSound "imp/shotx";
		Decal "DoomImpScorch";
	}
	States
	{
	Spawn:
		SBAL A 0 { A_SpawnItemEx("RS_ShadowTrail", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_TRANSFERSCALE); }
		SBAL A 4 Bright { A_Weave(2, 1, 10, 1); }
		SBAL B 0 { A_SpawnItemEx("RS_ShadowTrail", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_TRANSFERSCALE); }
		SBAL B 4 Bright { A_Weave(2, 1, 10, 1); }
		SBAL C 0 { A_SpawnItemEx("RS_ShadowTrail", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_TRANSFERSCALE); }
		SBAL C 4 Bright { A_Weave(2, 1, 10, 1); }
		Loop;
	Death:
		SBAL CDEFGH 4 Bright;
		Stop;
	}
}

// The pair the spiral sheds sideways as it travels, and the seventy-two
// bouncers its death throws in every direction.
class RS_ShadowBallEX2 : RS_ShadowBall
{
	States
	{
	Spawn:
		SBAL DFH 4 Bright { A_SpawnItemEx("RS_ShadowTrail", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	}
}
class RS_ShadowBallEX3 : Actor
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 18;
		DamageFunction (random(20, 55));
		Projectile;
		+RANDOMIZE +BOUNCEONWALLS +BOUNCEONFLOORS +BOUNCEONCEILINGS
		BounceCount 6;
		BounceFactor 1;
		WallBounceFactor 1;
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.75;
		SeeSound "Shadow/attack";
		DeathSound "imp/shotx";
		Decal "DoomImpScorch";
	}
	States
	{
	Spawn:
		SBAL ABC 4 Bright { A_SpawnItemEx("RS_ShadowTrail", 0, 0, 0, 0, 0, 0, 0, 128); }
		Loop;
	Death:
		SBAL C 5 Bright;
		SBAL DEFGH 4 Bright;
		Stop;
	}
}

// ---------- the big one ----------
// Slow, 100-200 damage, sheds a ball to each side twice per cycle, and
// its death is the real attack: a seventy-two-shot scatter.
class RS_ShadowSpiralTrailEX : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +NOCLIP;
		RenderStyle "Add"; XScale 4.0; YScale 0.8; Alpha 0.95; }
	States { Spawn: SHTR ABCDEF 4 Bright; Stop; }
}
class RS_ShadowSpiralEX : Actor
{
	Default
	{
		Radius 18;
		Height 13;
		Speed 8;
		XScale 2.0;
		YScale 0.4;
		DamageFunction (random(100, 200));
		Projectile;
		DamageType "Plasma";
		RenderStyle "Add";
		Alpha 0.95;
		SeeSound "fire/fire3";
		DeathSound "spell/Impact1";
	}
	States
	{
	Spawn:
		SPIR A 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, -30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR A 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR A 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR A 4 Bright { A_Weave(2, 1, 10, 1); }
		SPIR B 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, -30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR B 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR B 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR B 0 { A_SpawnProjectile("RS_ShadowBallEX2", 0, 0, 90, 6, 0); }
		SPIR B 0 { A_SpawnProjectile("RS_ShadowBallEX2", 0, 0, -90, 6, 0); }
		SPIR B 4 Bright { A_Weave(2, 1, 10, 1); }
		SPIR C 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, -30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR C 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR C 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR C 4 Bright { A_Weave(2, 1, 10, 1); }
		SPIR D 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, -30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR D 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR D 0 { A_SpawnItemEx("RS_ShadowSpiralTrailEX", 0, 30, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		SPIR D 0 { A_SpawnProjectile("RS_ShadowBallEX2", 0, 0, 90, 6, 0); }
		SPIR D 0 { A_SpawnProjectile("RS_ShadowBallEX2", 0, 0, -90, 6, 0); }
		SPIR D 4 Bright { A_Weave(2, 1, 10, 1); }
		Loop;
	Death:
		SBAL D 0 { A_SetScale(10.0, 2.0); }
		SBAL DDDDFFFFHHHHDDDDFFFFHHHHDDDDFFFFHHHHDDDDFFFFHHHHDDDDFFFFHHHHDDDDFFFFHHHH 1 Bright { A_SpawnProjectile("RS_ShadowBallEX3", 0, 0, random(0, 360), 6, random(75, 105)); }
		Stop;
	}
}

// ---------- the dark beam ----------
// Two damage a hit and it pierces armour, but every impact BLINDS: the
// darkness powerup is the payload, the damage is incidental.
class RS_ShadowDarkBeamTrailEX : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; +NOCLIP;
		RenderStyle "Stencil"; Alpha 1.0; Scale 0.6; }
	States { Spawn: BAL1 AAAABBBB 1 { A_FadeOut(0.125); } Stop; }
}
class RS_ShadowDarkBeamEX : FastProjectile
{
	Default
	{
		Radius 6;
		Height 8;
		Speed 35;
		Damage 2;
		Scale 0.6;
		Projectile;
		+BLOODLESSIMPACT +PIERCEARMOR
		RenderStyle "Stencil";
		StencilColor "00 00 00";
		SeeSound "imp/attack";
		DeathSound "imp/shotx";
	}
	States
	{
	Spawn:
		BAL1 A 1 { A_SpawnItemEx("RS_ShadowDarkBeamTrailEX", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION|SXF_TRANSFERSTENCILCOL); }
		Loop;
	Death:
		TNT1 A 0 { A_RadiusGive("RS_DarknessTokenSpectreEX", 42, RGF_PLAYERS, 1); }
		BAL1 CDE 4;
		Stop;
	}
}

// The blind itself. CHP's Pickup state also calls A_Light(-20/-30/-25);
// A_Light is a weapon action and has no meaning on an inventory item, so
// only the Powerup.Color half -- which is what actually darkens the
// screen -- is carried.
class RS_DarknessTokenSpectreEX : Powerup
{
	Default
	{
		Powerup.Color "00 00 00", 0.5;
		Powerup.Duration 30;
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
		+INVENTORY.ADDITIVETIME
		+INVENTORY.NOSCREENBLINK
	}
}
