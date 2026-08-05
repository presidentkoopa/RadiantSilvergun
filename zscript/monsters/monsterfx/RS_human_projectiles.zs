// =====================================================================
// RS_human_projectiles.zs
// ---------------------------------------------------------------------
// Monster attack components, extracted per docs/catalog_notes.txt: every
// projectile is a standalone catalogued entry with its own visual
// identity, audio, movement and damage properties, so monster attacks
// can be recombined the same way weapon attacks are, rather than each
// monster owning a hardcoded projectile.
//
// Converted from the earlier port's library and RS_-prefixed.
//
// SPRITE REFERENCES ARE NOT FULLY VERIFIED. An earlier version of this
// header claimed they were; they were not. The lint that was supposed to
// check them (verify.py) used a ^-anchored regex and therefore never read
// a single inline `States { ... }` block -- which is how most of this file
// is written -- so it reported OK on code it had not looked at. That is
// fixed now, and the broken references it exposed are listed at the bottom
// of this file. Trust the lint, not this comment.
// =====================================================================

// ============================================================================
// hf_human_projectiles.zs -- Zombieman / Shotgunner / Chaingunner projectiles.
// The humans are hitscan grunts; colors add a projectile twist. Reuses pool:
// RS_FireSGguy2, RS_ZombieRock, RS_PurpFire2, RS_SplashAbyss2, RS_HKRedDeath,
// RS_PlasmaBallSP3, RS_FireBCGguy (already built). New below. Damage->constants.
// ============================================================================

// ---------- ZOMBIEMAN color projectiles ----------
class RS_Gas11 : Actor
{
	Default { Radius 6; Height 8; Speed 12; Damage 8; DamageType "Poison"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.7; Scale 0.8;
		SeeSound "grenade/fuse"; DeathSound "weapons/grenade"; Translation "0:255=%[0.20,0.40,0.00]:[0.70,1.20,0.20]"; }
	// RESTORED 1:1 TO CHP 01_G.txt:1418 -- `PSBG FGHI 6 Bright
	// A_Explode(random(1,8),32)`. This was the single worst numeric error
	// in family 01 and it is the whole point of the green zombie: the roll
	// was flattened to a constant 24 and the radius inflated 32 -> 48, so
	// it covered 2.25x the area. Four frames means four detonations, which
	// is CH's deliberate idiom (see the header note on the A_Explode
	// reversal) -- not a bug to convert.
	States { Spawn: PSBG CDE 4 Bright; Loop; Death: PSBG FGHI 6 Bright A_Explode(random(1, 8), 32); Stop; }
}
class RS_IceZombieShot : Actor
{
	Default { Radius 6; Height 8; Speed 33; /* CH: Damage (random(6,16))  Zombies.txt:216 -- was flattened to `Damage 11`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(6,16)); DamageType "Ice"; Projectile; RenderStyle "Add"; Alpha 0.9; SeeSound "ice/Cast"; DeathSound "Ice/Hit2"; Translation "Ice"; }
	States { Spawn: ICEY AB 3 Bright; Loop; Death: ICEY C 4 Bright A_Explode(33, 40, XF_HURTSOURCE, false, 13); ICEY FG 4 Bright; Stop; }
}
// NOT CORRECTED -- SHARED WITH THE SHOTGUNNER. See the report.
// CH Zombies.txt:236 is
//     ACTOR IceZombieShot2 : IceZombieShot
//     { radius 2  xscale 0.95  yscale 0.1  speed 42  Damage (random(4,14)) }
// so ours is wrong on every line (Speed 28 vs 42, a flattened `Damage 9` where
// CH rolls 4..14, and no radius/scale overrides at all). It is left alone
// because RS_Shotgunner.zs:667 (Missile.T03.Proj, the cyan shotgunner) fires
// it too -- exactly as CH's own Shotgunners.txt:295 does -- so correcting it
// changes a NON-chaingunner family's behaviour and that is not this pass's
// call to make. The parent RS_IceZombieShot is family 01's and is also still
// CHP's (CH Zombies.txt:211: Radius 3/Height 2, Damage (random(6,16)),
// Alpha 0.75, xScale 1.15/yScale 0.15, SeeSound "Ice/Hit2",
// DeathSound "spike/spiked", Spawn ICEY ABC 3, Death ICEY FGHI 5, no explode).
class RS_IceZombieShot2 : RS_IceZombieShot { Default { Speed 28; /* CH: Damage (random(4,14))  Zombies.txt:242 -- was flattened to `Damage 9`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(4,14)); } }
class RS_Orbb11 : Actor
{
	Default { Radius 6; Height 8; Speed 21; /* CH: Damage (random(2,18))  Zombies.txt:1252 -- was flattened to `Damage 10`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(2,18)); DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.9; Scale 0.7;
		SeeSound "imp/attack"; DeathSound "imp/shotx"; Translation "0:255=%[0.40,0.00,0.60]:[1.30,0.30,1.70]"; }
	States { Spawn: BAL1 AB 3 Bright A_SeekerMissile(2,2); Loop; Death: BAL1 C 4 Bright A_Explode(30, 40, XF_HURTSOURCE, false, 13); BAL1 DE 4 Bright; Stop; }
}
class RS_MiniRKTZombie : Actor
{
	Default { Radius 6; Height 8; Speed 22; /* CH: Damage (random(5,40))  Zombies.txt:1417 -- was flattened to `Damage 22`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(5,40)); DamageType "Fire"; Projectile; +RANDOMIZE; +ROCKETTRAIL; Scale 0.6; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States { Spawn: MISL A 3 Bright; Loop; Death: MISL B 4 Bright A_Explode(120, 80, XF_HURTSOURCE, false, 26); MISL CD 4 Bright; Stop; }
}
class RS_AbyssZshotCH : Actor
{
	Default { Radius 6; Height 8; Speed 32; /* CH: Damage (random(5,30))  Zombies.txt:651 -- was flattened to `Damage 17`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(5,30)); DamageType "Ice"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; Translation "Ice"; SeeSound "imp/attack"; DeathSound "imp/shotx"; }
	States { Spawn: BAL7 AB 3 Bright; Loop; Death: BAL7 C 4 Bright A_Explode(51, 48, XF_HURTSOURCE, false, 16); BAL7 DE 4 Bright; Stop; }
}
class RS_AbyssZshotCH2 : RS_AbyssZshotCH { Default { Speed 45; } }
// CH Zombies.txt:686. CH's AbyssZShotCH3 overrides ONLY Radius/Height/Speed and
// the two scales -- it carries NO Damage of its own, it inherits the parent's
// roll. The `Damage 22` that used to sit here was CHP's and is deleted.
// WARNING: the parent RS_AbyssZshotCH above is the ZOMBIEMAN's actor and is
// still CHP's (CH Zombies.txt:~640 has Damage (random(5,30)), a Fly state with
// a_weave, Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]" and a death of
// TNT1 A 0 A_setscale(0.85,0.85) + BAL7 CDE 4 A_Explode(random(1,8),42)).
// Not corrected here: it is family 01's, not the chaingunner's. See report.
class RS_AbyssZShotCH3 : RS_AbyssZshotCH { Default { Radius 2; Height 2; Speed 60; XScale 0.35; YScale 0.15; } }

// ---------- SHOTGUNNER color projectiles ----------
class RS_FireSGguy : Actor
{
	Default { Radius 4; Height 4; Speed 21; /* CH: Damage (random(5,15))  Shotgunners.txt:791 -- was flattened to `Damage 10`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(5,15)); DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "161:161=200:200","163:163=204:204","165:165=204:204","167:167=207:207"; }
	States { Spawn: FIRE AB 3 Bright; Loop; Death: FIRE CDE 3 Bright; Stop; }
}
class RS_SGshot1 : Actor
{
	Default { Radius 4; Height 4; Speed 55; /* CH: Damage (random(2,6))  Shotgunners.txt:1013 -- was flattened to `Damage 4`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(2,6)); DamageType "Plasma"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.85; Scale 0.6; SeeSound "weapons/shotgf"; DeathSound "weapons/plasmax"; }
	States { Spawn: BAL1 AB 2 Bright; Loop; Death: BAL1 CD 3 Bright; Stop; }
}
class RS_SGLance1 : Actor
{
	Default { Radius 6; Height 8; Speed 20; Damage 35; DamageType "Plasma"; Projectile; +RANDOMIZE; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.9; SeeSound "weapons/plasmaf"; DeathSound "weapons/plasmax"; }
	States { Spawn: PLSE AB 3 Bright A_SeekerMissile(2,2); Loop; Death: PLSE C 4 Bright A_Explode(105, 64, XF_HURTSOURCE, false, 21); PLSE DE 4 Bright; Stop; }
}
class RS_RedMessImp3 : Actor
{
	Default { Radius 6; Height 8; Speed 26; Damage 30; DamageType "Fire"; Projectile; +RANDOMIZE; RenderStyle "Add"; Alpha 0.9; SeeSound "imp/attack"; DeathSound "imp/shotx";
		Translation "0:255=%[0.60,0.00,0.00]:[2.00,0.30,0.30]"; }
	States { Spawn: BAL1 AB 3 Bright; Loop; Death: BAL1 C 4 Bright A_Explode(90, 48, XF_HURTSOURCE, false, 16); BAL1 DE 4 Bright; Stop; }
}
class RS_SGGasNade : Actor
{
	// RESTORED 1:1 TO CHP. CH's death is a SINGLE frame -- MISL B 8 Bright
	// A_Explode(random(20,50),128) -- so the "fires once per frame" concern
	// never applied to this actor at all, yet an earlier pass still replaced
	// it with an invented two-stage 120/72 + 60/160 burst and flattened
	// Damage (random(20,75)) to a constant 40. Both undone.
	Default { Radius 6; Height 8; Speed 25; DamageFunction (random(20, 75)); DamageType "Poison";
		Projectile; +GRENADETRAIL; -NOGRAVITY; Gravity 0.4; BounceType "Doom"; BounceCount 2;
		SeeSound "weapons/grenade"; DeathSound "weapons/grenade"; }
	States { Spawn: GRND A 4 Bright; Loop;
		Death: MISL B 8 Bright A_Explode(random(20, 50), 128); Stop; }
}
// A thrown shotgun that falls, rolls, throbs and cooks off. Ported 1:1 from
// CH's MineShotgun (Shotgunners.txt:2473) -- gravity, the scale throb, the
// random cook-off and the bounce kick are all load-bearing for how it reads.
class RS_MineShotgun : Actor
{
	// DamageFunction, not Damage: a non-constant Damage property in a Default
	// block is the "damage: non-constant parameter" compile blocker. CH's roll
	// is kept. (Phrased without the literal pattern so it does not show up in
	// the tree-wide grep the other lanes are using to find real instances.)
	Default { Radius 12; Height 12; Speed 20; DamageFunction (random(10, 50)); DamageType "Fire"; Projectile;
		RenderStyle "SoulTrans"; Alpha 0.95; -NOGRAVITY; Gravity 0.9;
		+BOUNCEONWALLS; +THRUGHOST; BounceType "Doom"; BounceCount 11; BounceFactor 0.75; WallBounceFactor 1.2;
		SeeSound "weapons/sshotl"; BounceSound "weapons/sshotl"; DeathSound "weapons/rockx"; }
	States
	{
	Spawn:
		SHOT A 1 Bright A_SetScale(1.15);
		SHOT A 1 Bright A_SetScale(1.3);
		SHOT A 0 A_Jump(6, "Death");
		SHOT A 0 A_Jump(32, "Bounce");
		SHOT A 1 Bright A_SetScale(1.15);
		SHOT A 1 Bright A_SetScale(1.0);
		Loop;
	Bounce:
		// CH: ThrustThing(angle*256/(random(1,360)), 15, 0, 0). The expression is
		// byte-angle nonsense that lands on a scrambled direction; kept verbatim
		// and converted back to degrees rather than "tidied" into something else.
		SHOT A 2 Bright
		{
			double deg = ((angle * 256.0) / random(1, 360)) * (360.0 / 256.0);
			Vel.X += 15 * cos(deg);
			Vel.Y += 15 * sin(deg);
		}
		Goto Spawn;
	Death:
		// RESTORED 1:1 TO CHP: MISL BCD 5 Bright A_Explode(random(5,50),128).
		// Three frames, so three rolls -- CH's intent, not a bug. The earlier
		// two-stage rewrite invented a 96/192 radius split CH never had.
		MISL BCD 5 Bright A_Explode(random(5, 50), 128);
		Stop;
	}
}

// ---------- CHAINGUNNER color projectiles ----------
// T02 BLUE -- the proximity beeper the blue chaingunner lobs out ahead of its
// rail bursts. CORRECTED TO CH Chaingunners.txt:1323. Every property here was
// CHP's: Radius/Height 4 (CH 12), +NOGRAVITY and no Projectile at all, Alpha
// 0.7 (CH 0.73), Scale 0.6 (CH 0.55), no seesound, and an SSBL ABCD spawn that
// is not CH's frame set. The beep IS the actor -- CH plays "prox/beep" twice,
// once as SeeSound and once on the second frame.
class RS_BlueChainPuff3 : Actor
{
	Default { Radius 12; Height 12; Speed 1; Projectile; +NOINTERACTION;
		RenderStyle "Add"; Alpha 0.73; Scale 0.55; SeeSound "prox/beep"; }
	States
	{
	Spawn:
		SSBL KIJ 1 Bright;
		SSBL I 1 Bright A_StartSound("prox/beep");
		SSBL J 1 Bright A_SetScale(0.3, 0.3);
		Goto Death;
	Death:
		SSBL KJI 1 Bright;
		Stop;
	}
}
// T06 BROWN -- CORRECTED TO CH Chaingunners.txt:204. This was built from CHP
// and the single biggest loss was the ARC: CH gives it `Gravity 0.05` and
// `-NOGRAVITY`, so the brown gunner's orb DROPS over distance instead of
// flying flat. Also restored: Radius/Height 3 -> 2, Mass 10, +MTHRUSPECIES,
// CH's own sounds (fire/fire3, weapons/boom1 -- both resolve, SNDINFO:1524
// and :1406), CH's desaturating translation, Scale 0.5 -> 0.33, and the death,
// which in CH is five RIP1 frames each rolling random(1,5) at radius 32, not
// one flat 27 at radius 40. +RANDOMIZE, RenderStyle Add and Alpha 0.9 were all
// CHP additions and are gone; CH renders it opaque.
class RS_BrownOrbCguy : Actor
{
	Default { Radius 2; Height 2; Speed 32; Mass 10; DamageFunction (random(3, 9)); DamageType "Fire";
		Gravity 0.05; Projectile; -NOGRAVITY; +MTHRUSPECIES; +THRUGHOST; Scale 0.33;
		SeeSound "fire/fire3"; DeathSound "weapons/boom1"; Translation "0:255=@74[77,52,26]"; }
	States
	{
	Spawn:
		BAL1 AB 4 Bright;
		Loop;
	Death:
		RIP1 D 0 A_SetScale(1.0, 1.0);
		// CH is `a_settranslation("BBEASTEX5")` here, and CH's TRNSLATE.txt:5
		// defines BBEASTEX5 = "0:0=0:0" -- an identity map, i.e. this line
		// CLEARS the brown tint so the burst renders untinted. Our TRNSLATE.txt
		// does not define BBEASTEX5, so the call is left out rather than
		// emitting a runtime warning on every shot. Kept as an explicit 0-tic
		// placeholder so the frame count of this state is unchanged.
		TNT1 A 0;
		RIP1 DEFGH 3 Bright A_Explode(random(1, 5), 32);
		Stop;
	}
}
class RS_CGBigOne : Actor
{
	// VERIFIED AGAINST CH Chaingunners.txt:2389 -- clean, no edit needed.
	// Every property and every state line matches CH: Radius 6 / Height 8 /
	// Speed 19, Damage (random(30,80)) Plasma, +NOGRAVITY +SEEKERMISSILE,
	// Add / Alpha 0.75, Spell/SpellCast1 + Fire/Fire4, spawn RED9 B / AA / A,
	// death SPIR A A_SetScale(2) -> SPIR ABCDEDCBA A_Explode(random(5,30),164)
	// -> SPIR E 1. (The old header credited CHP 04_K.txt:2268 for these
	// numbers; they are CH's, and CHP was never opened for this pass.)
	// SPIR ABCDEDCBA is NINE frames, so nine blasts -- a grow-then-shrink
	// pulse, and CH's deliberate idiom. Do not collapse it.
	Default { Radius 6; Height 8; Speed 19; DamageFunction (random(30, 80)); DamageType "Plasma";
		Projectile; +NOGRAVITY; +SEEKERMISSILE; RenderStyle "Add"; Alpha 0.75;
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4"; }
	States
	{
	Spawn:
		RED9 B 1 Bright A_SeekerMissile(3, 6);
		RED9 AA 1 Bright A_SpawnItemEx("RS_SpiralSaw5", 0,0,0, 0,0,0, 0, 128);
		RED9 A 0 A_CustomMissile("RS_GroundRedCyb", 0, 0);
		Loop;
	Death:
		SPIR A 1 Bright A_SetScale(2);
		// NINE frames, so nine blasts. CH's own intent -- see the comment on
		// RS_DIBigOne, which carries the identical pattern at radius 178.
		SPIR ABCDEDCBA 5 Bright A_Explode(random(5, 30), 164);
		SPIR E 1;
		Stop;
	}
}
// B01 BLACK (The General) -- CORRECTED TO CH Chaingunners.txt:2442.
// The old body here ("orbiting shield bubble") was an invention: it looped
// BFE1 ABCD forever and died into two frames doing nothing. CH's GenShield is
// a SHIELD THAT COUNTER-FIRES. It hangs on the General for 45 tics (BFS1 ABA
// 15) and then bursts, and its last three frames each launch a live
// TrailSPCguy bolt on a randomised vector -- so popping the shield is what
// puts three plasma bolts in the air. It also drops a Cell.
// Restored: Radius/Height 8 -> 20, Alpha 0.4 -> 0.75, Scale 1.2 -> 1.5,
// DamageType Plasma, +SEEKERMISSILE, DropItem Cell, and both states.
// CHP-only flags +NOGRAVITY and +THRUACTORS removed -- CH sets neither.
class RS_GenShield : Actor
{
	Default { Radius 20; Height 20; Speed 1; Damage 0; DamageType "Plasma";
		Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.75; Scale 1.5; DropItem "Cell"; }
	States
	{
	Spawn:
		BFS1 ABA 15 Bright;
		Goto Death;
	Death:
		BFE1 A 8 Bright A_SetScale(1.15);
		BFE1 B 8 Bright A_SetScale(0.8);
		BFE1 C 8 Bright A_SetScale(0.6);
		BFE1 C 0 A_NoBlocking();
		BFE1 DEF 8 Bright A_SpawnProjectile("RS_TrailSPCguy", random(-2, 2), random(-2, 2), random(-4, 4), CMF_AIMDIRECTION | CMF_SAVEPITCH);
		Stop;
	}
}
// B02 WHITE (the crazy lady scientist) -- CORRECTED TO CH Chaingunners.txt:2825.
// Ours had Spawn and Death INVERTED (it flew as a 6PUF smoke puff and died into
// BLAD blades; CH flies the BLAD needle and dies into the 6PUF/FBL1 burst), and
// the entire two-stage explosion was missing. Restored: Radius 2/Height 2 -> 5/4,
// Decal BulletChip, AttackSound "moloch/nailhitbleed" (SNDINFO:591), the
// A_PlaySound("moloch/nailhit") on impact (SNDINFO:1671), both A_Explode rolls,
// and the RS_Trail12 spawn that seeds the residue. +RANDOMIZE was CHP's, removed.
class RS_NeedlesCg1 : Actor
{
	Default { Radius 5; Height 4; Speed 35; DamageFunction (random(5, 25)); DamageType "Melee";
		Projectile; +SPAWNSOUNDSOURCE; +BLOODSPLATTER; YScale 0.6; XScale 1.4; Decal "BulletChip";
		SeeSound "Jam/Jamd"; AttackSound "moloch/nailhitbleed"; DeathSound "gas/gas1"; }
	States
	{
	Spawn:
		BLAD A 1 Bright;
		Loop;
	Death:
		"6PUF" A 0 A_StartSound("moloch/nailhit");
		// Six frames and three frames: six rolls then three. CH's idiom, kept.
		"6PUF" ABCDEF 1 Bright A_Explode(random(2, 5), 64);
		FBL1 EFG 1 Bright A_Explode(random(2, 8), 64);
		FBL1 G 1 Bright A_SpawnItemEx("RS_Trail12", 0, 0, 1);
		Stop;
	}
}
// CH Chaingunners.txt:2772. NOT a subclass in CH -- NeedlesCg2 is a standalone
// actor with its own body and its own, LONGER death. Ours was
// `: RS_NeedlesCg1 { PoisonDamage 6 }`, which got the poison wrong (CH 15),
// the speed wrong (inherited 35, CH 25), both scales wrong (CH 1.55/0.75) and
// dropped CH's whole trail mechanic. Kept as a subclass here only so the diff
// stays readable -- every property CH declares is re-declared, and the states
// are fully overridden, so nothing of NeedlesCg1's body survives.
class RS_NeedlesCg2 : RS_NeedlesCg1
{
	Default { Radius 6; Height 5; Speed 25; DamageFunction (random(5, 45)); DamageType "Poison";
		PoisonDamage 15; PoisonDamageType "Poison"; YScale 0.75; XScale 1.55; }
	States
	{
	Spawn:
		BLAD A 1 Bright A_SpawnItemEx("RS_Trail14", 0, 0, 2);
		Loop;
	Death:
		"6PUF" A 0 A_StartSound("moloch/nailhit");
		"6PUF" ABCDEF 1 Bright A_Explode(random(2, 8), 64);
		FBL1 GGG 0 A_SpawnItemEx("RS_Trail14", random(-8, 8), random(-8, 8), random(-8, 8));
		FBL1 EFG 1 Bright A_Explode(random(2, 12), 64);
		FBL1 GGG 0 A_SpawnItemEx("RS_Trail12", random(-8, 8), random(-8, 8), random(-8, 8));
		Stop;
	}
}
// The trail RS_NeedlesCg2 lays and scatters. CH Chaingunners.txt:2805 (Trail14).
// Added because the corrected NeedlesCg2 references it and nothing in the repo
// defined it; a string class name that does not resolve is a compile error.
class RS_Trail14 : Actor
{
	Default { Radius 6; Height 16; Speed 16; FastSpeed 23; Projectile; +NOINTERACTION;
		RenderStyle "Add"; Scale 0.3; Alpha 0.5; }
	States { Spawn: BAL7 CDE 4 Bright; Stop; }
}
// B02 WHITE -- CORRECTED TO CH Chaingunners.txt:2745. Ours was a static
// floorhugging gas patch that faded out: Speed 0, +NOCLIP +FLOORHUGGER, a green
// translation, and a Spawn that just ran BOGY ABCD twice and stopped. None of
// that is CH. CH's Puddle1 is a LOBBED, GRAVITY-BOUND slime ball (Speed 14,
// -NOGRAVITY) that on impact turns its gravity off and sprays THREE Puddle2s at
// randomised angles and pitches -- and Puddle2 is the thing that then crawls,
// bounces off walls and keeps spitting. The area denial is two stages deep.
class RS_Puddle1 : Actor
{
	Default { Radius 4; Height 4; Speed 14; Damage 4; PoisonDamage 15; PoisonDamageType "Poison";
		Projectile; -NOGRAVITY; Scale 0.5; Decal "PlasmaScorchLower";
		SeeSound ""; DeathSound "slimeball/splat"; }
	States
	{
	Spawn:
		BOGY ABC 2 Bright;
		Loop;
	Death:
		BOGY D 0 { bNOGRAVITY = true; }
		BOGY DEF 4 Bright A_SpawnProjectile("RS_Puddle2", random(2, 16), random(-16, 16), random(-20, 20), CMF_SAVEPITCH, random(5, 15));
		BOGY F 1;
		Stop;
	}
}
// The second stage. CH Chaingunners.txt:2707 (Puddle2). Added for the same
// reason as RS_Trail14: RS_Puddle1's corrected death names it.
// This is the actual area-denial mechanic -- it wanders, ricochets off walls
// almost 1000 times, and throws a RS_SlimeBall4 out of every frame it crawls.
class RS_Puddle2 : Actor
{
	Default { Radius 12; Height 3; Speed 12; Damage 4; PoisonDamage 15; PoisonDamageType "Poison";
		Species "Science"; XScale 1.1; YScale 0.3;
		+FLOORHUGGER; +DONTHARMCLASS; +DONTHARMSPECIES; +THRUACTORS; +RANDOMIZE; +BOUNCEONWALLS;
		BounceCount 999; BounceType "Doom"; BounceFactor 1; WallBounceFactor 1.5;
		RenderStyle "Add"; SeeSound ""; DeathSound "slimeball/splat"; }
	States
	{
	Spawn:
		BOGY ABC 2 Bright A_SpawnProjectile("RS_SlimeBall4", random(5, 15), random(-8, 8), random(-180, 180), CMF_AIMDIRECTION, random(10, 60));
		BOGY A 0 A_Jump(16, "Death");
		BOGY ABC 2 Bright A_Wander();
		Loop;
	Death:
		BOGY D 0 { bNOGRAVITY = true; }
		BOGY DEF 4 Bright;
		Stop;
	}
}


// =====================================================================
// REBUILD ADDITIONS (rs_09 per-tier state port). These are CH attacks
// the earlier HF port never imported; ported from CH decorate
// (Zombies.txt / Shotgunners.txt / Chaingunners.txt) per the spec's
// "no RS_ port -> add it here" rule.
//
// [CORRECTED 2026-08-04] This header used to end "Damage -> constants,
// house style." THERE IS NO SUCH HOUSE STYLE and there never was -- it
// is the exact practice CLAUDE.md forbids, because a roll turned into a
// constant leaves no `random(` for any later sweep to find and no reader
// can tell a spread was ever there. Two independent cataloguing passes
// found the same flattenings here on the same day.
// Worse, the constants were not even means: CHP's random(10,45) (mean
// 27.5) had become 20, and random(1,9) had become 4.
// RS_PlayerEXBFG, further down THIS SAME FILE, already used
// DamageFunction (random(100,200)) correctly -- so the working pattern
// was sitting eleven hundred lines below the note telling people not to
// use it. Rolls restored against CHP 01_W.txt, cited at each actor.
// =====================================================================

// ---------- UNDERTAKER (white zombieman) bone kit ----------
// BBBN / RNGG sprites copied from ART SOURCE (CH sprites/theride, fx)
// into sprites/monsters/projectiles/.
class RS_BoneProjZM : Actor
{
	Default { Radius 8; Height 8; Speed 32; DamageFunction (random(4, 16)); Projectile; +BLOODLESSIMPACT; +SKYEXPLODE; +FORCEPAIN; Scale 0.75;
		SeeSound "skeleton/attack"; DeathSound "skeleton/melee"; Translation "0:255=[129,129,129]:[255,255,255]"; }
	States
	{
	Spawn:
		BBBN ABCD 4;
		Loop;
	Death:
		MISL B 0 A_SetScale(0.3);
		MISL BCD 3;
		Stop;
	}
}
class RS_BoneProjZM2 : RS_BoneProjZM { Default { Speed 36; DamageFunction (random(8, 20)); } }
class RS_BoneProjZM3 : RS_BoneProjZM { Default { Speed 40; DamageFunction (random(12, 26)); } }

// The shovel: a big blade fan. CH ShoveZM sprays ShoveZM2/3 side
// blades both forward and backward; kept, at reduced count.
class RS_ShoveZM2 : Actor
{
	Default { Radius 6; Height 8; Speed 25; DamageFunction (random(1, 5)); DamageType "Melee"; Alpha 0.75; Scale 1.8; Decal "BulletChip";
		Projectile; +SPAWNSOUNDSOURCE; +EXTREMEDEATH; +BLOODSPLATTER; DeathSound ""; }
	States
	{
	Spawn:
		BLAD AAAA 3 Bright;
	Death:
		BLAD AA 1 Bright A_FadeOut(0.15);
		BLAD AAAA 1 Bright A_FadeOut(0.15);
		Stop;
	}
}
class RS_ShoveZM3 : RS_ShoveZM2 { Default { Speed 27; DamageFunction (random(3, 12)); Scale 1.55; } }
class RS_ShoveZM : Actor
{
	Default { Radius 6; Height 8; Speed 25; DamageFunction (random(10, 45)); DamageType "Melee"; Scale 2.0; Decal "BulletChip";
		Projectile; +SPAWNSOUNDSOURCE; +EXTREMEDEATH; +BLOODSPLATTER;
		AttackSound "skeleton/swing"; DeathSound "moloch/nailhitbleed"; }
	States
	{
	Spawn:
		BLAD AA 2 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
		BLAD AAA 0 A_SpawnProjectile("RS_ShoveZM3", 0, 0);
		BLAD A 2 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
		BLAD A 3 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
		BLAD AA 0 A_SpawnProjectile("RS_ShoveZM3", 0, 3, -180);
		BLAD AA 0 A_SpawnProjectile("RS_ShoveZM3", 0, -3, -180);
		BLAD A 3 Bright A_SpawnProjectile("RS_ShoveZM2", 0, 0);
	Death:
		BLAD A 1 Bright;
		6PUF ABCDEF 1 Bright;
		TNT1 A 0 A_Explode(12, 64);
		Stop;
	}
}

// Orbiting bone satellite for the tornado. One class with a
// randomized orbit replaces CH's seven near-identical BoneStormer1-7.
class RS_BoneStormer : Actor
{
	double OrbR;
	double OrbH;
	double OrbA;
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		OrbR = frandom(12, 80);
		OrbH = frandom(10, 128);
		OrbA = frandom(0, 359);
	}
	Default { Radius 8; Height 8; Speed 120; Damage 2; Projectile; +BLOODLESSIMPACT; +RIPPER; +FORCEPAIN; Scale 0.75;
		Translation "0:255=[129,129,129]:[255,255,255]"; DeathSound "skeleton/melee"; }
	States
	{
	Spawn:
		BBBN A 1 Bright NoDelay
		{
			A_Warp(AAPTR_MASTER, OrbR, 0, OrbH, OrbA,
			       WARPF_ABSOLUTEANGLE | WARPF_NOCHECKPOSITION | WARPF_INTERPOLATE);
			OrbA += 8;
		}
		TNT1 A 0 A_Jump(6, "Death");
		Loop;
	Death:
		MISL B 0 A_SetScale(0.3);
		MISL BCD 3;
		Stop;
	}
}

// The wandering bone tornado (RNGG). Floorhugging bouncer that drags
// an orbiting bone storm with it and spits bones as it goes.
class RS_BoneTorn2 : Actor
{
	Default { Radius 6; Height 8; Speed 18; Mass 25; Projectile; +FLOORHUGGER; +THRUACTORS; +DONTBLAST; +DONTTHRUST;
		+BOUNCEONWALLS; BounceType "Doom"; BounceCount 999; BounceFactor 1; WallBounceFactor 1.1;
		RenderStyle "Add"; Alpha 0.75; SeeSound "skeleton/attack"; }
	States
	{
	Spawn:
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer", 0, 0, 4, 0, 0, 0, 0, SXF_SETMASTER | SXF_ORIGINATOR);
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer", 0, 0, 4, 0, 0, 0, 0, SXF_SETMASTER | SXF_ORIGINATOR);
		RNGG CCDD 1 Bright A_SpawnProjectile("RS_BoneProjZM3", 4, random(-20, 20), random(0, 359), CMF_AIMDIRECTION | CMF_OFFSETPITCH, random(-20, 5));
		RNGG AB 1 Bright A_Wander;
		RNGG CCCCCCC 1 Bright A_SpawnItemEx("RS_BoneStormer", 0, 0, 4, 0, 0, 0, 0, SXF_SETMASTER | SXF_ORIGINATOR);
		RNGG CCDD 1 Bright A_SpawnProjectile("RS_BoneProjZM3", 4, random(-20, 20), random(0, 359), CMF_AIMDIRECTION | CMF_OFFSETPITCH, random(-20, 5));
		RNGG D 0 A_Jump(8, "Death");
		Loop;
	Death:
		RNGG ABCD 4 Bright;
		Stop;
	}
}

// ---------- SHOTGUNNER rebuild additions ----------
// Brown SG mud pellet: fast, near-invisible, knocks the target around.
class RS_BrownSGshot : Actor
{
	Default { Radius 2; Height 2; Speed 64; /* CH: Damage (random(1,5))  Shotgunners.txt:169 -- was flattened to `Damage 3`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(1,5)); Projectile; +DONTBLAST; +DONTTHRUST; RenderStyle "Add"; Alpha 0.85;
		DeathSound "imp/shotx"; }
	States
	{
	Spawn:
		TNT1 A 5 Bright;
		Goto Death;
	Death:
		TNT1 A 0 A_Stop;
		PUFF C 6 Bright;
		TNT1 A 0 A_Blast(BF_NOIMPACTDAMAGE, 128, 32, 20.0);
		PUFF D 12 Bright;
		Stop;
	}
}
// Gray SG sniper laser-dot puff (the telegraph).
class RS_RedDotSGPuff : BulletPuff
{
	Default { +NOBLOOD; +PAINLESS; +ALWAYSPUFF; Translation "0:255=175:191"; Scale 0.5; }
	States
	{
	Spawn:
		TNT1 A 0;
	Melee:
	Death:
		PUFF A 6 Bright;
		Stop;
	}
}

// ---------- CHAINGUNNER rebuild additions ----------
// T07 GRAY -- CORRECTED TO CH Chaingunners.txt:742. This is not a plain tracer
// puff: in CH every round that lands throws a RING OF TWELVE NAILS (via
// CGthing3), which is the gray gunner's whole close-range identity and was
// missing entirely. Also restored: A_Explode's roll (ours had a flat 6 where CH
// rolls 1..12), VSpeed 1, SeeSound "weapons/firex4" (SNDINFO:654) in place of
// an invented DeathSound "imp/shotx", CH's translation, and the removal of
// +ALWAYSPUFF, which CH does not set on this one (only on DetoPuffCG).
// CH declares no Death state -- Spawn falls through into Melee, and a puff that
// hits an actor is put straight into Melee, so both paths detonate. The `Death:`
// alias that used to sit here was ours; every caller is A_CustomBulletAttack.
class RS_GrayCGuff : Actor
{
	Default { Projectile; +NOGRAVITY; +ALLOWPARTICLES; +PUFFONACTORS; RenderStyle "Add"; Alpha 0.85;
		VSpeed 1; Scale 0.25; Mass 5; DamageType "Fire"; SeeSound "weapons/firex4";
		Translation "0:249=%[0.00,0.00,0.00]:[2.00,2.00,2.00]","128:143=80:95","144:151=87:95","13:15=93:95","96:111=80:95","236:239=95:95","152:159=80:89","5:12=85:95","0:2=92:95","168:191=0:2","192:207=0:0","32:47=0:0"; }
	States
	{
	Spawn:
		MISL BC 2 Bright;
	Melee:
		MISL D 4 Bright A_Explode(random(1, 12), 64);
		MISL D 1 Bright A_SpawnItemEx("RS_CGthing3", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION);
		MISL E 4 Bright;
		Stop;
	}
}
// The nail ring. CH Chaingunners.txt:769 (CGthing3). Added because the corrected
// GrayCGuff names it and nothing in the repo defined it. Twelve CGNails at 30
// degree intervals, all on 0-tic frames, so the whole ring leaves at once.
// RS_CGNail already exists at RS_imp_projectiles.zs:271.
class RS_CGthing3 : Actor
{
	Default { Speed 0; Height 1; Radius 1; Projectile; +NOCLIP; }
	States
	{
	Spawn:
		TNT1 A 0;
		Goto Death;
	Death:
		// CH passes flags 0, i.e. aimmode 0 -- the twelve angles are offsets
		// from the direction back to the shooter, not from this actor's own
		// facing. Kept as 0 (the argument is omitted) rather than "tidied" to
		// CMF_AIMDIRECTION, which would orient the ring differently.
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 15);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 45);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 75);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 105);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 135);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 165);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 195);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 225);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 255);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 285);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 315);
		MISL D 0 A_SpawnProjectile("RS_CGNail", 0, 0, 345);
		Stop;
	}
}
// T10 RED -- the detonating puffs, three range grades.
// CORRECTED TO CH Chaingunners.txt:1820 / :1847 / :1860.
// The A_Explode rolls and radii were already right. What was wrong:
//   * DeathSound "imp/shotx" was invented -- CH has SeeSound "weapons/firex4"
//     (SNDINFO:654) and no DeathSound at all.
//   * VSpeed 1 was missing, so these did not drift upward the way CH's do.
//   * CH sizes the grades with A_SetScale in the SPAWN frames (0.35 / 0.28 /
//     0.2), not with a Scale property override -- and the property is 0.35 on
//     all three. Ours used Scale 0.30 / 0.25 on the subclasses, so the two
//     short grades read a size larger than CH's.
//   * CH has no Death label; Spawn falls through into Melee, and a puff that
//     hits an actor is put straight into Melee, so both paths detonate.
//     Because CH's subclasses override SPAWN (not Death), the grades are
//     written that way here too.
class RS_DetoPuffCG : Actor
{
	Default { Projectile; +NOGRAVITY; +ALLOWPARTICLES; +RANDOMIZE; +PUFFONACTORS; +ALWAYSPUFF;
		RenderStyle "Add"; Alpha 0.85; VSpeed 1; Scale 0.35; Mass 5; DamageType "Fire";
		SeeSound "weapons/firex4"; }
	States
	{
	Spawn:
		MISL BC 4 Bright A_SetScale(0.35);
	Melee:
		MISL D 4 Bright A_Explode(random(2, 6), 42);
		MISL E 4 Bright;
		Stop;
	}
}
class RS_DetoPuff2 : RS_DetoPuffCG
{
	States
	{
	Spawn:
		MISL BC 4 Bright A_SetScale(0.28);
	Melee:
		MISL D 4 Bright A_Explode(random(1, 4), 38);
		MISL E 4 Bright;
		Stop;
	}
}
class RS_DetoPuff3 : RS_DetoPuffCG
{
	States
	{
	Spawn:
		MISL BC 4 Bright A_SetScale(0.2);
	Melee:
		MISL D 4 Bright A_Explode(random(1, 3), 32);
		MISL E 4 Bright;
		Stop;
	}
}
// B01 BLACK (The General) -- his plasma bombs. CH Chaingunners.txt:2472.
// Every property and both A_Explode/damage rolls already matched CH. ONE fix:
// the spawn frame carried `A_SeekerMissile(2, 3)`, which CH does not have.
// CH sets +SEEKERMISSILE but never calls A_SeekerMissile, so in CH these fly
// DEAD STRAIGHT -- the flag alone does nothing. They are volume, not tracking;
// RS_CGBigOne is the General's seeker. (BFS1/BFE1 are IWAD BFG sprites.)
class RS_SpamShotsCguy : Actor
{
	Default { Radius 14; Height 9; Speed 25; DamageFunction (random(10, 60)); DamageType "Plasma";
		Projectile; +RANDOMIZE; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.75; Scale 0.55; SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx"; }
	States
	{
	Spawn:
		BFS1 AB 2 Bright;
		Loop;
	Death:
		BFE1 AB 8 Bright A_SetScale(1.15);
		BFE1 C 8 Bright A_Explode(random(5, 45), 128);
		BFE1 DEF 8 Bright;
		Stop;
	}
}

// =====================================================================
// CHP 02 (SHOTGUNNER) REBUILD ADDITIONS
// ---------------------------------------------------------------------
// Ported for the RS_Shotgunner per-tier rebuild. Source of truth is
// CHP/DECORATE/02/02_<code>.txt; where a CHP actor only overrides a
// couple of properties on a CH parent, the CH parent supplied the rest
// and CHP's values were applied on top (CHP always wins).
// =====================================================================

// T03 cyan pellet puff. CHP CyanSGPuff_C is an empty-bodied BulletPuff
// subclass with an ice hit sound -- the frost read is the sound plus the
// particle burst, there is no sprite of its own.
class RS_CyanSGPuff : BulletPuff
{
	Default { +ALWAYSPUFF; +PUFFONACTORS; DeathSound "ice/hit2"; }
	States
	{
	Spawn:
		TNT1 A 1;
	Melee:
	Death:
		TNT1 A 0 { A_Scream(); }
		Stop;
	}
}

// T11 black commander kit ------------------------------------------------
// Smoke motes the detonating puffs and airstrike missiles burst into.
class RS_PufFCHBS : Actor
{
	Default { Radius 1; Height 1; Speed 8; /* CH: Damage (random(0,1))  Shotgunners.txt:1802 -- was flattened to `Damage 1`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(0,1)); Projectile; +NOCLIP; +NOGRAVITY;
		RenderStyle "Add"; Alpha 0.75; }
	States { Spawn: SMK2 ABCDE 2; Stop; }
}

// The sniped mark: a detonating puff planted on the target by A_VileTarget.
class RS_DetoPuffCG2 : Actor
{
	Default { Radius 2; Height 1; Mass 1; Projectile; RenderStyle "Add"; Alpha 1.0; Scale 0.55;
		DamageType "Fire"; SeeSound "weapons/firex4"; }
	States
	{
	Spawn:
		MISL BC 1 Bright;
		Goto Death;
	Death:
		MISL D 4 Bright { A_Explode(random(12, 36), 42); }
		MISL E 4 Bright { A_Burst("RS_PufFCHBS"); }
		Stop;
	}
}

// The bomblets the airstrike rains down while it flies overhead.
class RS_MissileCHBS : Actor
{
	Default { Radius 11; Height 8; Speed 10; /* CH: Damage (random(10,50))  Shotgunners.txt:1771 -- was flattened to `Damage 30`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(10,50)); DamageType "Fire"; Projectile; -NOGRAVITY;
		Gravity 1.5; Scale 0.7; SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; }
	States
	{
	Spawn:
		MSLH A 2 Bright;
		Loop;
	Death:
		MISL B 0 { A_SetTranslucent(0.8, 1); }
		MISL B 4 Bright { A_Explode(random(5, 40), 98); }
		MISL C 5 Bright;
		MISL D 6 Bright { A_Burst("RS_PufFCHBS"); }
		Stop;
	}
}

// The airstrike itself: hugs the ceiling toward the marked spot, seeding
// bomblets the whole way, then detonates twice on impact.
class RS_AirStrikeCHBS : Actor
{
	Default { Radius 6; Height 8; Speed 28; Mass 50; /* CH: Damage (random(5,40))  Shotgunners.txt:1739 -- was flattened to `Damage 22`. A bare constant is multiplied by random(1,8) by the engine and a DamageFunction is not, so that also inflated the top end. */ DamageFunction (random(5,40)); DamageType "Fire"; Projectile;
		+CEILINGHUGGER; +FLOAT; +NOGRAVITY; RenderStyle "Add"; Gravity 7; Alpha 0.35; Scale 0.5;
		SeeSound "caco/attack"; DeathSound "fire/fire5"; }
	States
	{
	Spawn:
		HEAD DD 2 Bright { A_SpawnItemEx("RS_MissileCHBS", random(-80, 80), random(-80, 80), -32, random(-10, 13), random(-10, 25), 1, 0, SXF_NOCHECKPOSITION); }
		HEAD DD 3 Bright { A_SpawnItemEx("RS_MissileCHBS", random(-200, 200), random(-200, 200), -32, random(-10, 13), random(-10, 25), 1, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		BBOM A 2 Bright { A_SetScale(1); }
		BBOM B 2 { A_SetTranslucent(0.65); }
		BBOM CD 3 Bright { A_Explode(random(10, 40), 108); }
		BBOM EFG 6 Bright { A_Explode(random(10, 45), 108); }
		Stop;
	}
}

// T12 Benellus' punisher ------------------------------------------------
// A_VileTarget plants the invisible carrier on the victim; it immediately
// hangs a shotgun on either flank, each of which cocks, fires once, and
// blows itself up.
class RS_ShotgunPunishNerf : Actor
{
	Default { Radius 12; Height 12; Speed 1; Health 300; RenderStyle "SoulTrans"; Alpha 0.95;
		Monster; +NOTRIGGER; +NOCLIP; +NOBLOOD; -COUNTKILL;
		SeeSound "weapons/sshotl"; DeathSound "weapons/rockx"; }
	States
	{
	Spawn:
		SHOT A 6 Bright { A_SetScale(0.8, 0.3); }
		SHOT A 6 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 6 Bright { A_SetScale(1.6, 0.9); }
		SHOT A 6 Bright { A_SetScale(1.2, 1.1); }
		SHOT A 6 Bright { A_SetScale(1.0, 1.0); }
		SHOT A 6 Bright { A_SetScale(1.3, 0.6); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 18 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(1, 7), random(1, 5), "BulletPuff", 0); }
		SHOT A 4 Bright { A_SetScale(1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(0.1, 0.1); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The mirrored twin. CH gives it negative X scale so the two read as a
// pair closing in from both sides.
class RS_ShotgunPunishNerf2 : RS_ShotgunPunishNerf
{
	States
	{
	Spawn:
		SHOT A 6 Bright { A_SetScale(-0.8, 0.3); }
		SHOT A 6 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 6 Bright { A_SetScale(-1.6, 0.9); }
		SHOT A 6 Bright { A_SetScale(-1.2, 1.1); }
		SHOT A 6 Bright { A_SetScale(-1.0, 1.0); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 18 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(1, 7), random(1, 5), "BulletPuff", 0); }
		SHOT A 3 Bright { A_SetScale(-1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(-0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(-0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(-0.1, 0.1); }
		TNT1 A 0 { A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The carrier A_VileTarget actually spawns.
class RS_ShotgunpunisherNerfed : Actor
{
	Default { Speed 1; Projectile; +NOCLIP; -COUNTKILL; Alpha 0.01; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0 Bright { A_SpawnItemEx("RS_ShotgunPunishNerf", 0, 128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_ShotgunPunishNerf2", 0, -128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		Stop;
	}
}

// =====================================================================
// CHP 01 (Zombieman) REBUILD ADDITIONS -- ported for RS_Zombieman.zs.
// Each is a CHP `*_C` class; the `_C` suffix is stripped and RS_ added.
// Where CHP's `_C` class only re-declares its CH parent with no changes
// (BloodyPuff_C : BloodyPuff {}, CH_BoneGib_C : CH_BoneGib { ... }),
// the CH parent supplies the body and CHP's overrides go on top.
// =====================================================================

// Red ZombieUnman's slug puff. CH BloodyPuff; CHP BloodyPuff_C adds
// nothing to the Common colour. DBLD sprites copied from CH/sprites/
// zombies into sprites/monsters/projectiles/.
class RS_BloodyPuff : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +PUFFONACTORS; +EXTREMEDEATH; }
	States
	{
	Spawn:
	Crash:
		DBLD A 4 Bright;
		DBLD BCD 4;
		Stop;
	}
}

// "Player 9"'s rocket. CHP Rocket_C is a FastProjectile, not the stock
// Rocket -- kept as CHP has it.
class RS_Rocket : FastProjectile
{
	Default { Radius 11; Height 8; Speed 20; Damage 20; Projectile; +RANDOMIZE; +DEHEXPLOSION; +ROCKETTRAIL;
		SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; Obituary "$OB_MPROCKET"; }
	States
	{
	Spawn:
		MISL A 1 Bright;
		Loop;
	Death:
		MISL B 8 Bright A_Explode();
		MISL C 6 Bright;
		MISL D 4 Bright;
		Stop;
	}
}

// The Undertaker's bone shrapnel (XDeath). CH CH_BoneGib body, CHP's
// Speed 2 override. Bounces, then rattles to a stop and fades.
class RS_CH_BoneGib : Actor
{
	Default { Radius 2; Height 3; Damage 0; Speed 2; Projectile; BounceType "Doom"; +MOVEWITHSECTOR; +CANNOTPUSH;
		-NOGRAVITY; +NOTONAUTOMAP; BounceFactor 0.5; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 { vel.z += 13.75; }
		Goto Wee;
	Wee:
		BBBN ABCD random(3, 6);
		Loop;
	Crash:
	Death:
		BBBN ABD 1;
		BBBN C 850;
		Stop;
	}
}

// =====================================================================
// CHAINGUNNER -- CHP rebuild additions (DECORATE/04/04_*.txt, CHP is
// authoritative; CH parents consulted only where CHP left a property or
// state undefined). Damage rolls collapse to constants per this file's
// house style; the A_Explode rolls stay as rolls because they are the
// attack, not the contact damage.
// =====================================================================

// T01 GREEN -- the green chaingunner's tracer, used as a bullet PUFF
// (CHP 08_G Trail11_C). Non-interacting: it is the visible tracer, the
// A_CustomBulletAttack hitscan is what actually hurts.
class RS_Trail11 : Actor
{
	Default { Radius 6; Height 16; Speed 16; FastSpeed 23; Projectile; +RANDOMIZE; +NOINTERACTION;
		RenderStyle "Add"; Scale 0.5; Alpha 0.6; Translation "168:255=112:127"; }
	States { Spawn: BAL1 CDE 6 Bright; Goto Death; Death: BAL1 CDE 6 Bright; Stop; }
}

// T02 BLUE -- rail impact spark (CH BlueChainPuff2, CHP _C sets Speed 2).
class RS_BlueChainPuff2 : Actor
{
	Default { Radius 12; Height 12; Speed 2; Projectile; +NOINTERACTION; +ALWAYSPUFF;
		RenderStyle "Add"; Alpha 0.73; Scale 0.25; }
	States { Spawn: SSBL KIJ 1 Bright; Goto Death; Death: SSBL KIJ 1 Bright; Stop; }
}

// T04 PURPLE -- three grades of seeking micro-rocket, one per range band.
// CH Chaingunners.txt:1461 / :1488 / :1499. 1 = point blank and hardest-seeking
// (8,8), 2 = mid (4,4), 3 = long range and dumb-fired (-SEEKERMISSILE).
// CORRECTED: all three had their damage rolls FLATTENED (Boomer1 4 for CH's
// random(1,8), Boomer2 and Boomer3 both 3 where CH rolls random(1,7) and
// random(1,6) -- so the two long grades were identical). A bare `Damage N` on a
// projectile is multiplied by random(1,8) by the engine and a DamageFunction is
// not, so those constants were also ~8x hot at the top end.
// Also restored: +DEHEXPLOSION, CH's own SeeSound "SNPRFIRE" (SNDINFO:650) and
// DeathSound "weapons/firex4" (SNDINFO:654) in place of the rocket sounds, and
// Boomer3's own Spawn frame, which CH declares with A_SeekerMissile(7,7) even
// though it has just cleared the flag. Base changed FastProjectile -> Actor:
// CH's is a plain ACTOR, and FastProjectile substepping changes how a Speed 68
// missile reads at close range.
class RS_Boomer1 : Actor
{
	Default { Radius 3; Height 2; Speed 68; DamageFunction (random(1, 8)); DamageType "Fire";
		Projectile; +DEHEXPLOSION; +SEEKERMISSILE;
		Scale 0.15; SeeSound "SNPRFIRE"; DeathSound "weapons/firex4"; }
	States
	{
	Spawn:
		MISL A 1 Bright A_SeekerMissile(8, 8);
		Loop;
	Death:
		MISL B 8 Bright A_Explode(random(1, 8), 46);
		MISL C 6 Bright;
		MISL D 4 Bright;
		Stop;
	}
}
class RS_Boomer2 : RS_Boomer1
{
	Default { DamageFunction (random(1, 7)); }
	States { Spawn: MISL A 1 Bright A_SeekerMissile(4, 4); Loop; }
}
class RS_Boomer3 : RS_Boomer1
{
	Default { -SEEKERMISSILE; DamageFunction (random(1, 6)); }
	States { Spawn: MISL A 1 Bright A_SeekerMissile(7, 7); Loop; }
}

// T05 YELLOW -- the plasma gunner's rail spark: A_CustomRailgun lays a line of
// these along the beam and they pop. CH Chaingunners.txt:1677.
// CORRECTED: THREE flattened rolls. Contact damage was `Damage 2` where CH has
// Damage (random(1,3)), and BOTH A_Explode calls were flat 2 where CH rolls
// random(1,2). Base changed FastProjectile -> Actor to match CH's plain ACTOR.
class RS_CGRailBuff : Actor
{
	Default { Radius 4; Height 4; Speed 14; FastSpeed 26; DamageFunction (random(1, 3)); DamageType "Plasma";
		Projectile; +RANDOMIZE; +SEEKERMISSILE; Scale 0.33; RenderStyle "Add"; Alpha 0.85;
		Translation "168:191=193:205", "208:223=192:197", "160:167=4:4", "224:231=4:4",
		            "232:235=199:199", "248:249=193:193", "0:0=0:0"; }
	States
	{
	Spawn:
		BAL1 AB 3 Bright;
		Goto Death;
	Death:
		TNT1 A 0 A_SetScale(0.22, 0.22);
		BAL1 A 3 Bright A_Explode(random(1, 2), 24);
		TNT1 A 0 A_SetScale(0.11, 0.11);
		BAL1 B 3 Bright A_Explode(random(1, 2), 24);
		Stop;
	}
}

// T08 ABYSS -- the captain's ground splash. Spawned ON the target by
// A_VileTarget; its Spawn frame falls straight through into Death, so it
// detonates where it lands rather than travelling. CH Chaingunners.txt:553.
// CORRECTED: TWO flattened rolls -- contact `Damage 5` where CH has
// Damage (random(1,9)), and A_Explode(7,32) where CH rolls random(2,12).
// The translation was CHP's, and it is EXACTLY DOUBLE CH's on every channel
// (0.04/0.04/0.06 -> 0.29/0.49/0.65 becomes 0.08.../1.30), i.e. the abyss
// captain's splash was rendering twice as bright as CH's. CH's restored.
class RS_SplashAbyssCguy : Actor
{
	Default { Radius 6; Height 16; DamageFunction (random(1, 9)); DamageType "Ice";
		Speed 16; FastSpeed 23; Projectile;
		+THRUACTORS; +FLOATBOB; +FORCERADIUSDMG; Scale 0.3;
		Translation "0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"; }
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		BAL7 C 1 Bright A_SetScale(0.5);
		// CH spawns an AbyssShotIdentifier here (Chaingunners.txt:574). That
		// actor (CH Revenants.txt:217) is a marker gated behind
		// CallACS("CH_AbyssMark"), and neither the actor nor the ACS script
		// exists in this repo, so it is left out. Kept as an explicit 0-tic
		// placeholder because dropping the line would shift every later frame
		// index in this state.
		TNT1 A 0;
		TNT1 A 0 ThrustThingZ(0, random(1, 33), 0, 0);
		TNT1 A 0 A_Explode(random(2, 12), 32);
		BAL7 CDE 3 Bright;
		Stop;
	}
}

// T06 BROWN -- the deployable sandbag. Thrown, inflates, wanders a step,
// turns solid, then rots. This is the brown chaingunner's whole identity:
// it builds cover instead of pushing. CH Chaingunners.txt:162.
// CORRECTED, and the biggest one is structural: CH's sandbag is a MONSTER with
// health 80 and -COUNTKILL, so it is SHOOTABLE -- you can blow the cover away.
// Ours was a plain Actor with +SOLID, i.e. permanent, indestructible cover.
// Restored: health 80, Monster, +NOTRIGGER, +NOTARGET, +DONTTHRUST, +NOBLOOD,
// +FLOORCLIP, -COUNTKILL; the missing first `SB4G X 3` frame of Flier; and
// every A_SetScale value, all six of which were CHP's 1.5x inflation
// (0.3/0.4,0.5/0.7,0.8/1.0 inflate, 0.7/0.5/0.2,0.1 rot). At CHP's numbers the
// deployed bag stood half again as tall as CH's.
class RS_BrownSandBagCGuy : Actor
{
	Default { Radius 42; Height 24; Speed 3; Health 80; Species "BrownCguy";
		Monster; +NOTRIGGER; +NOTARGET; +DONTTHRUST; +NOBLOOD; +FLOORCLIP; -COUNTKILL;
		+THRUSPECIES; +THRUACTORS; Gravity 1; }
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		SB4G X 3 Bright A_SetScale(0.3, 0.3);
		SB4G X 3 Bright A_SetScale(0.4, 0.5);
		SB4G X 3 Bright A_SetScale(0.7, 0.8);
		SB4G X 3 Bright A_SetScale(1.0, 1.0);
		SB4G XX 1 A_Wander();
		TNT1 A 0 { bTHRUACTORS = false; }
	Flier:
		SB4G X 3 Bright;
		SB4G X 300 Bright;
		Goto Death;
	Death:
		SB4G X 2 Bright A_NoBlocking();
		SB4G X 2 Bright A_SetScale(0.7, 0.7);
		SB4G X 2 Bright A_SetScale(0.5, 0.5);
		SB4G X 2 Bright A_SetScale(0.2, 0.1);
		Stop;
	}
}

// T09 GRAY -- the hopping gunner's fast tracer (CHP 04_GY GrayPewPew_C).
class RS_GrayPewPew : Actor
{
	Default { Radius 4; Height 5; Speed 60; DamageFunction (random(8,24)); /* CHP 04/04_GY.txt:1549 - roll restored */ DamageType "Fire"; Projectile; +RANDOMIZE;
		SeeSound "weapons/rocklf"; DeathSound "weapons/rocklx"; Scale 0.28;
		Translation "0:255=%[0.28,0.25,0.22]:[1.01,1.01,1.01]"; }
	States
	{
	Spawn:
		RIP1 ABC 2 Bright;
		Loop;
	Death:
		RIP1 D 0 A_SetTranslucent(0.75, 1);
		RIP1 DEFGH 2 Bright;
		Stop;
	}
}

// T09 GRAY -- the close-range lob. Trails for a randomised fuse, drops
// out of the air, coasts to a dead stop, sits there, then detonates.
// CHP counts the fuse in a GrayKaboomInv inventory item capped at 6;
// here it is a plain field (rs_09 spec: user vars -> private ints).
class RS_GrayKaboom : Actor
{
	private int rsFuse;

	Default { Radius 8; Height 12; Speed 6; DamageFunction (random(20,75)); /* CHP 04/04_GY.txt:1721 - roll restored */ Scale 1.15; DamageType "Fire"; Projectile;
		RenderStyle "Normal"; +THRUGHOST; +NOEXPLODEFLOOR; Decal "Scorch"; SeeSound "weapons/rocklf"; }
	States
	{
	Spawn:
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 1 Bright;
		FBR2 A 1 Bright A_SpawnItemEx("RS_BruiserTrail", 0, 0, 0, 0, 0, 0, 0, 128);
		FBR2 A 0
		{
			rsFuse += random(1, 2);
			if (rsFuse >= 6) return ResolveState("Coast");
			return ResolveState(null);
		}
		Loop;
	Coast:
		FBR2 A 0 { bNOGRAVITY = false; }
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.9);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.8);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.7);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.6);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.5);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0.4);
		FBR2 AAAAAAAAAA 1 Bright A_ScaleVelocity(0);
	Sit:
		FBR2 A random(50, 750) Bright;
	Death:
	XDeath:
	Crash:
		BAL3 C 0 { bNOGRAVITY = true; }
		BAL3 C 0 Bright A_SetTranslucent(0.67, 1);
		BAL3 C 0 Bright A_StartSound("weapons/rocklx", CHAN_BODY);
		BAL3 C 6 Bright A_SetScale(1.5);
		BAL3 D 6 Bright A_Explode(random(20, 75), 128, 0);
		BAL3 E 6 Bright;
		Stop;
	}
}

// T11 BLACK -- the General's shielded volley bolt and its own sub-trail
// (CHP 04_K TrailSPCguy_C / CHP 16_Y TrailSP2_C).
class RS_TrailSP2 : FastProjectile
{
	Default { Radius 6; Height 16; Speed 20; DamageType "Plasma"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.35; Scale 0.25; Decal "ArachnotronScorch"; }
	States
	{
	Spawn:
		SPPL AB 2 Bright;
		Goto Death;
	Death:
		APBX ABCDE 4 Bright A_Explode(7, 32);
		Stop;
	}
}
// CH Chaingunners.txt:2418. Every property and both states already matched CH.
// ONE fix: base changed FastProjectile -> Actor, which is what CH declares.
class RS_TrailSPCguy : Actor
{
	Default { Radius 6; Height 16; Speed 22; DamageType "Plasma"; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 0.65; Scale 0.55; Decal "ArachnotronScorch"; }
	States
	{
	Spawn:
		SPPL AB 2 Bright A_SpawnItemEx("RS_TrailSP2", 0, 0, 2);
		Loop;
	Death:
		APBX ABCDE 4 Bright A_Explode(10, 32);
		Stop;
	}
}

// ---------------------------------------------------------------------
// B02 WHITE -- the crazy lady scientist's three live experiments. These are
// real monsters, not projectiles, but they exist only as her summons, so
// they live with the rest of her kit.
//
// [CORRECTED] This header used to read "All are -COUNTKILL per CHP: a boss
// that spawns forever must not make 100% kills impossible." CH sets
// -COUNTKILL on NONE of VolativeCaco (Chaingunners.txt:2957), SlimyWorm
// (:2855) or SpliceBaron (:3020), so it has been removed from all three --
// CH wins. The consequence is real and is flagged in the report: they now
// count toward the level kill total and become eligible for elite promotion
// (RS_Elites.zs:870 gates on bCOUNTKILL). RS_BabyCaco below is untouched;
// it was not part of this pass's scope.
// ---------------------------------------------------------------------

// Her first experiment: a cacodemon wired to blow. It swells as it
// closes, its "melee" is detonating on you, and it seeds five babies.
class RS_BabyCacoBall : Actor
{
	Default { Radius 3; Height 4; Speed 11; FastSpeed 10; Damage 3; Projectile; +RANDOMIZE;
		RenderStyle "Add"; Alpha 1.0; SeeSound "caco/attack"; DeathSound "caco/shotx"; Decal "DoomImpScorch"; }
	States
	{
	Spawn:
		BCAB AB 4 Bright;
		Loop;
	Death:
		BCAB CDE 6 Bright;
		Stop;
	}
}
class RS_BabyCaco : Actor
{
	Default
	{
		Health 125; Radius 18; Height 36; Mass 200; Speed 11; PainChance 176;
		Monster; +NOGRAVITY; +FLOAT; +THRUSPECIES; -COUNTKILL;
		Scale 0.9; BloodColor "Blue"; Species "Science";
		SeeSound "caco/sight"; PainSound "caco/pain"; DeathSound "caco/death"; ActiveSound "caco/active";
		Obituary "%o underestimated a Baby Cacodemon.";
		HitObituary "%o was nibbled to death by a Baby Cacodemon.";
		Tag "smol babby caco";
	}
	States
	{
	Spawn:
		CACB A 10 A_Look();
		Loop;
	See:
		CACB A 3 A_Chase();
		Loop;
	Melee:
	Missile:
		CACB AB 5 A_FaceTarget();
		CACB C 5 Bright A_CustomComboAttack("RS_BabyCacoBall", 17, random(1, 8) * 3, "caco/attack");
		Goto See;
	Pain:
		CACB D 3;
		CACB D 3 A_Pain();
		CACB E 6;
		Goto See;
	Death:
		CACB F 8;
		CACB G 8 A_Scream();
		CACB HI 8;
		CACB J 8 A_NoBlocking();
		CACB K 8;
		CACB L -1 A_SetFloorClip();
		Stop;
	Raise:
		CACB L 8 A_UnSetFloorClip();
		CACB KJIHGF 8;
		Goto See;
	}
}
// CORRECTED TO CH Chaingunners.txt:2957.
// Restored: GibHealth 65 (missing entirely); +MISSILEMORE +MISSILEEVENMORE in
// place of `MissileChanceMult 0.0625`, which is a different mechanism and a
// different number; CH's obituary verbatim, typo and all ("stood to close" --
// the law says a name comes from CH or there is no name, and that includes not
// silently rewriting CH's strings); and the five-baby birth, which CH does with
// A_DualPainAttack/A_PainAttack (a pain-elemental fan that launches them AT the
// player) and ours had replaced with A_SpawnItemEx at random offsets, i.e. the
// babies just fell on the floor. -COUNTKILL and FloatSpeed 4 removed -- neither
// is in CH. (-COUNTKILL was a deliberate house call, noted in the report.)
class RS_VolativeCaco : Actor
{
	Default
	{
		Health 100; GibHealth 65; Radius 31; Height 56; Mass 500; Speed 11; PainChance 90;
		Monster; +MISSILEMORE; +MISSILEEVENMORE; +TOUCHY; +LOOKALLAROUND; +FLOAT; +NOGRAVITY;
		+DONTHARMSPECIES;
		Scale 1.1; XScale 1.3; BloodColor "Blue"; Species "Science";
		SeeSound "caco/sight"; PainSound "caco/pain"; DeathSound "weapons/rocklx"; ActiveSound "caco/active";
		Obituary "%o stood to close to the unstable cacodemon";
		Tag "Unstable cacodemon";
	}
	States
	{
	Spawn:
		HEAD A 10 A_Look();
		Loop;
	See:
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.4, 1.3);
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.5, 1.4);
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.4, 1.3);
		HEAD A 1 A_Chase();
		HEAD A 1 A_SetScale(1.3, 1.2);
		Loop;
	Melee:
		HEAD BC 4;
		Goto Death;
	Pain:
		HEAD E 3;
		HEAD E 3 A_Pain();
		HEAD F 6;
		Goto See;
	Death:
		HEAD D 8;
		HEAD D 1 A_Scream();
		// TWO frames, so two blasts. CH's idiom, not a bug.
		MISL CD 6 A_Explode(random(20, 60), 128);
		// CH Chaingunners.txt:3012-3014 -- 2 + 1 + 2 = five babies, thrown out
		// pain-elemental style rather than dropped at random offsets.
		MISL E 1 A_DualPainAttack("RS_BabyCaco");
		MISL E 2 A_PainAttack("RS_BabyCaco");
		MISL E 1 A_DualPainAttack("RS_BabyCaco");
		TNT1 A 0 A_Die();
		Stop;
	}
}

// Her second experiment: a noclipping worm that surfaces, then spits a
// five-ball slime volley. Reuses the arachnotron slime pool.
class RS_SlimyWorm : Actor
{
	// CORRECTED TO CH Chaingunners.txt:2855.
	// The sounds were the big one: all five were remapped to demon/* by an
	// earlier pass because CH's lumps had never been imported. They have been
	// now -- slimeworm/sight :1334, /melee :593, /pain :1662 ($random),
	// /death :1335, /active :1336 in SNDINFO -- so CH's own names are restored
	// and this thing stops sounding like a pinky.
	// Also restored: +MISSILEMORE (was `MissileChanceMult 0.5`),
	// +SHORTMISSILERANGE (was `MaxTargetRange 896`, a different mechanism),
	// all three DamageFactor/PainChance rows, and CH's obituary verbatim
	// ("by slimy minion worm", no article). -COUNTKILL removed: not in CH.
	// CH's DropItem table is NOT carried, because none of the four pickup
	// classes exist in this repo yet. Itemised so it is not silently gutted:
	//     DropItem "CH_Shell",128        CH Chaingunners.txt:2881
	//     DropItem "implyingclip",174    CH Chaingunners.txt:2882
	//     DropItem "CH_RocketAmmo",64    CH Chaingunners.txt:2883
	//     DropItem "CH_Cell",32          CH Chaingunners.txt:2884
	Default
	{
		Health 250; Radius 30; Height 56; Mass 400; Speed 8; PainChance 90;
		Monster; +THRUSPECIES; +FLOORCLIP; +MISSILEMORE; +SHORTMISSILERANGE; +NOCLIP;
		BloodColor "Yellow"; Species "Science";
		DamageFactor "Heroic", 3.0; DamageFactor "DIMp", 0; PainChance "DIMp", 0;
		SeeSound "slimeworm/sight"; AttackSound "slimeworm/melee"; PainSound "slimeworm/pain";
		DeathSound "slimeworm/death"; ActiveSound "slimeworm/active";
		Obituary "%o got melted up good by slimy minion worm";
		HitObituary "%o was digested by a slimy minion worm.";
		Tag "Worm minion";
	}
	States
	{
	Spawn:
		WORM AB 10 A_Look();
		Loop;
	See:
		WORM AABBCCDD 3 A_Chase();
		WORM A 0 { bNOCLIP = false; }
		Loop;
	Missile:
		WORM E 8 A_FaceTarget();
		WORM F 8 A_StartSound("SlimeBall/Shoot", CHAN_WEAPON);
		WORM F 0 A_SpawnProjectile("RS_SlimeBall1", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall2", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall3", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall4", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM F 0 A_SpawnProjectile("RS_SlimeBall5", 40, 0, random(-10, 10), 2, random(10, 20));
		WORM G 8;
		Goto See;
	Melee:
		WORM EF 8 A_FaceTarget();
		// CH is A_SargAttack, which is a Demon-class method and therefore not
		// callable from a plain Actor in ZScript. A_CustomMeleeAttack with the
		// identical roll (random(1,10)*4) is the same damage; the AttackSound
		// is already CH's. Kept, not "corrected" back to a name that would not
		// compile here.
		WORM G 8 A_CustomMeleeAttack(random(1, 10) * 4);
		Goto See;
	Pain:
		WORM H 2;
		WORM H 2 A_Pain();
		Goto See;
	Death:
		WORM I 8;
		WORM J 8 A_Scream();
		WORM K 4;
		WORM L 4 A_NoBlocking();
		WORM M 4;
		WORM N -1;
		Stop;
	Raise:
		WORM NMLKJI 5;
		Goto See;
	}
}

// Her third experiment, and the one the phase change hands you: an
// arachnotron spliced onto a baron. Painless, alternates the spider's
// refire loop with a three-ball baron fan.
class RS_SpliceBaron : Actor
{
	// CORRECTED TO CH Chaingunners.txt:3020.
	// Restored: DeathSound "arachnobaron/death" (SNDINFO:1349 -> DSABRDTH.ogg
	// -- it was remapped to "baron/death" back when CH's lumps were missing);
	// +MISSILEMORE +MISSILEEVENMORE in place of `MissileChanceMult 0.0625`;
	// DamageFactor "Heroic",3.0 / "DIMp",0 and PainChance "DIMp",0, all three
	// absent. -COUNTKILL removed: not in CH.
	// CH's DropItem table is NOT carried -- neither pickup class exists here.
	// Itemised rather than silently dropped:
	//     DropItem "CH_CellPack"         CH Chaingunners.txt:3048
	//     DropItem "CH_MediKit",174      CH Chaingunners.txt:3049
	Default
	{
		Health 1000; Radius 64; Height 70; Mass 1000; Speed 12; PainChance 0;
		Monster; +FLOORCLIP; +THRUSPECIES; +DONTHARMSPECIES; +MISSILEMORE; +MISSILEEVENMORE;
		+DONTMORPH; +NOCLIP;
		BloodColor "Green"; Species "Science";
		DamageFactor "Plasma", 1.2; DamageFactor "Fire", 1.1;
		DamageFactor "Heroic", 3.0; DamageFactor "DIMp", 0; PainChance "DIMp", 0;
		SeeSound "baron/sight"; PainSound "baron/pain"; DeathSound "arachnobaron/death"; ActiveSound "baby/active";
		Obituary "what has science done; %o was killed by a horrible abomination";
		Tag "Splice hell";
	}
	States
	{
	Spawn:
		ARBR AB 10 A_Look();
		Loop;
	See:
		// CH is `ARBR A 3 A_BabyMetal` -- ONE frame that both chases and plays
		// the walk sound. A_BabyMetal is an Arachnotron-class method and is not
		// callable from a plain Actor here, so it is inlined; it must stay ONE
		// frame, because Missile2 below ends `Goto See+1` and See+1 must land on
		// the first ARBR A of `ARBR ABBCC`. It used to be split across two
		// frames (a 0-tic A_Chase plus a 3-tic A_StartSound), which pushed every
		// index in this state along by one.
		ARBR A 3 { A_StartSound("baby/walk", CHAN_BODY); A_Chase(); }
		ARBR ABBCC 3 A_Chase();
		ARBR A 0 { bNOCLIP = false; }
		ARBR D 3 { A_StartSound("baby/walk", CHAN_BODY); A_Chase(); }
		ARBR DEEFF 3 A_Chase();
		Goto See;
	Missile:
		// CH is A_Jump(127, ...), not 128.
		ARBR A 1 Bright A_Jump(127, "Missile2");
		// THE LOOP TARGET IS THE SHOT, NOT THE AIM FRAME.
		// CH is `Goto Missile+2` (Chaingunners.txt:3069), and Missile+2 is the
		// ARBR G 3 firing frame -- +1 is the 20-tic A_FaceTarget. The label used
		// to sit on +1, so every refire cycle re-paid twenty tics of aiming:
		// 26 tics per shot against CH's 6, i.e. this minion's gun ran at roughly
		// a QUARTER speed. Exactly the Goto X+N class that has bitten three
		// times. MissileLoop below IS Missile+2; it is a named label rather than
		// an offset so it cannot drift again.
		ARBR A 20 Bright A_FaceTarget();
	MissileLoop:
		ARBR G 3 Bright A_SpawnProjectile("ArachnotronPlasma", 15, 0, 0);
		ARBR H 2 Bright;
		ARBR H 1 Bright A_SpidRefire();
		Goto MissileLoop;
	Missile2:
		ARBR P 2 Bright A_FaceTarget();
		ARBR P 5 Bright A_SpawnProjectile("BaronBall", 30, 0, 5);
		ARBR Q 5 Bright A_SpawnProjectile("BaronBall", 30, 0, 0);
		ARBR R 5 Bright A_SpawnProjectile("BaronBall", 30, 0, -5);
		// CH is `Goto See+1` (Chaingunners.txt:3075) -- it re-enters the walk
		// cycle one frame in, skipping the A_BabyMetal step. This was `Goto See`.
		Goto See+1;
	Death:
		ARBR J 20 A_Scream();
		ARBR K 7 A_NoBlocking();
		ARBR LMNO 7;
		ARBR O -1 A_BossDeath();
		Stop;
	}
}

// =====================================================================
// TEX ADDITIONS -- the fourteenth tier (the CHP "EX" bosses).
// ---------------------------------------------------------------------
// Zombieman TEX is CHP 01_KX CommonBlackZombieEX2, a COMMON boss, so its
// projectiles are the `_C` colour. Shotgunner TEX (02_WX
// GreenWhiteSGEX2) and Chaingunner TEX (04_KX GreenBlackCGuyEX2) are
// GREEN bosses, so theirs are the `_G` colour. The suffix is stripped on
// import, so one RS_ class serves each -- and the numbers below are the
// ones the boss that actually fires it uses, not a different colour's.
//
// Every CHP `_C`/`_G` class here was checked against its CH parent; where
// CHP redeclares the whole body (which it does for all of these) CHP
// wins outright and CH was only read to confirm nothing was left
// undefined.
// =====================================================================

// ---------- ZOMBIEMAN TEX: PLAYER X (01_KX) -------------------------
// The BFG. Player X's panic button: a fat, slow orb that detonates into
// a cloud of thirty smaller ones, so the real damage arrives a beat
// AFTER you dodged the thing you saw.
class RS_PlayerEXBFG : FastProjectile
{
	Default
	{
		Radius 12; Height 12; Speed 25;
		DamageFunction (random(100, 200)); DamageType "Plasma";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 1.25; Scale 1.0;
		DeathSound "weapons/bfgx";
	}
	States
	{
	Spawn:
		BFS1 A 2 Bright { A_SpawnItemEx("RS_TrailSPCguy", random(-2, 2), random(-2, 2), random(-1, 1), 20, 0, random(-5, 5), random(-270, 270)); }
		BFS1 B 2 Bright { A_SpawnItemEx("RS_TrailSPCguy", random(-2, 2), random(-2, 2), random(-1, 1), 20, 0, random(-5, 5), random(-270, 270)); }
		Loop;
	Death:
		BFE1 AB 8 Bright { A_SetScale(1.25); }
		TNT1 A 0 { A_Quake(15, 15, 0, 40); }
		BFE1 C 8 Bright { A_Explode(random(45, 125), 156); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_PlayerEXBFG2", random(-12, 12), random(-12, 12), random(-1, 1), random(2, 19), 0, random(-9, 9), random(-359, 359), SXF_NOCHECKPOSITION); }
		BFE1 DEF 8 Bright;
		Stop;
	}
}

// The shrapnel. Each one also self-destructs on a small random roll, so
// the cloud thins out instead of hanging around forever.
class RS_PlayerEXBFG2 : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 10;
		DamageFunction (random(20, 80)); DamageType "Plasma";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 1.25; Scale 0.55;
		Translation "0:255=%[0.00,0.17,0.00]:[0.81,1.35,0.28]";
	}
	States
	{
	Spawn:
		BFS1 A 2 Bright { A_SetScale(0.55, 0.75); }
		BFS1 B 2 Bright { A_SetScale(0.75, 0.55); }
		TNT1 A 0 A_Jump(2, "Death");
		Loop;
	Death:
		BFS1 ABABAB 2 Bright { A_FadeOut(0.33); }
		Stop;
	}
}

// ---------- SHOTGUNNER TEX: GREEN BENELLUS (02_WX) ------------------
// The full-strength Punisher pair. The T12 Benellus already ships the
// NERFED twins (RS_ShotgunPunishNerf/2); these are CH's originals, which
// wind up faster and throw a bigger pellet spread. Kept as separate
// classes rather than tuning the nerfed ones, because BOTH exist in the
// source and T12 must not silently get the EX version's teeth.
class RS_ShotgunPunish : Actor
{
	Default
	{
		Radius 12; Height 12; Speed 1; Health 375;
		RenderStyle "SoulTrans"; Alpha 0.95;
		Monster; +NOTRIGGER; +NOCLIP; +NOBLOOD; -COUNTKILL;
		SeeSound "weapons/sshotl"; DeathSound "weapons/rocklx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		SHOT A 2 Bright { A_SetScale(0.8, 0.3); }
		SHOT A 2 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 4 Bright { A_SetScale(1.6, 0.9); }
		SHOT A 4 Bright { A_SetScale(1.2, 1.1); }
		SHOT A 4 Bright { A_SetScale(1.0, 1.0); }
		SHOT A 3 Bright { A_SetScale(1.3, 0.6); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 13 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(3, 10), random(1, 6), "BulletPuff", 0); }
		SHOT A 4 Bright { A_SetScale(1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(0.1, 0.1); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The mirrored twin -- negative X scale, so the pair reads as closing in
// from both sides at once.
class RS_ShotgunPunish2 : RS_ShotgunPunish
{
	States
	{
	Spawn:
		SHOT A 2 Bright { A_SetScale(-0.8, 0.3); }
		SHOT A 4 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 4 Bright { A_SetScale(-1.6, 0.9); }
		SHOT A 4 Bright { A_SetScale(-1.2, 1.1); }
		SHOT A 3 Bright { A_SetScale(-1.0, 1.0); }
	Shoot:
		SHOT A 0 { A_FaceTarget(); }
		SHOT A 13 Bright;
		SHOT A 4 Bright { A_StartSound("weapons/sshotf", CHAN_WEAPON); }
		SHOT A 4 Bright { A_SetScale(-1.3, 0.6); }
		SHOT A 6 Bright { A_CustomBulletAttack(7, 5, random(3, 10), random(1, 6), "BulletPuff", 0); }
		SHOT A 3 Bright { A_SetScale(-1.0, 1.0); }
		Goto Death;
	Death:
		SHOT A 3 Bright { A_SetScale(-0.7, 0.7); }
		SHOT A 3 Bright { A_SetScale(-0.4, 0.4); }
		SHOT A 3 Bright { A_SetScale(-0.1, 0.1); }
		TNT1 A 0 { A_Scream(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 64); }
		Stop;
	}
}

// The carrier A_VileTarget plants on you -- it hangs one gun on each
// flank and vanishes.
class RS_ShotgunPunisher : Actor
{
	Default { Speed 1; Projectile; +NOCLIP; -COUNTKILL; Alpha 0.01;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 Bright { A_SpawnItemEx("RS_ShotgunPunish", 0, 128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_ShotgunPunish2", 0, -128, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		Stop;
	}
}

// The OTHER carrier: same idea, but it plants two SHRINES instead of two
// guns -- turrets that stay, chase, and have to be killed.
class RS_ShotgunPunisher2 : Actor
{
	Default { Speed 1; Projectile; +NOCLIP; -COUNTKILL; Alpha 0.01;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]"; }
	States
	{
	Spawn:
		TNT1 A 0;
		TNT1 A 0 Bright { A_SpawnItemEx("RS_ShotgunShrine", 0, 178, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		TNT1 A 1 Bright { A_SpawnItemEx("RS_ShotgunShrine", 0, -178, 12, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS); }
		Stop;
	}
}

// A shrine is a walking gun emplacement: it chases you, opens up with a
// spark barrage, and DAMAGES ITSELF every burst, so it burns down on its
// own if you can survive it. Dies into an explosion plus two mines.
class RS_ShotgunShrine : Actor
{
	Default
	{
		Radius 30; Height 64; Speed 10; Health 1000;
		Monster;
		+NOTRIGGER; +THRUSPECIES; MissileChanceMult 0.0625;
		+DONTHARMCLASS; +DONTHARMSPECIES; +NOTARGETSWITCH; +NOCLIP; +NOBLOOD;
		Species "BENE";
		SeeSound "weapons/sshotl"; DeathSound "weapons/rocklx";
		Obituary "$OB_SHOTGUY";
		Tag "Green Shotgun Shrine";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		BENE M 2 Bright { A_SetScale(1.0, 0.1); }
		BENE M 2 Bright { A_SetScale(1.0, 0.4); }
		BENE M 2 Bright { A_SetScale(1.0, 0.7); }
		BENE M 2 Bright { A_SetScale(1.0, 1.0); }
	Idle:
		BENE MNOP 6 { A_Chase(); }
		Loop;
	Missile:
		BENE M 6 { A_FaceTarget(); }
		BENE M 6 Bright;
		BENE Q 1 Bright { A_StartSound("shotguy/attack", CHAN_WEAPON); }
		BENE QRQRQRQR 1 Bright { A_SpawnProjectile("RS_SparkFireBen", 84, 0, random(-3, 3)); }
		// CHP's damagething(80): the shrine pays for every burst it fires.
		TNT1 A 0 { A_DamageSelf(80); }
		Goto Missile;
	Death:
		BENE M 2 Bright { A_SetScale(0.8, 1.0); }
		BENE M 2 Bright { A_SetScale(0.5, 1.2); }
		BENE M 2 Bright { A_SetScale(0.3, 1.5); }
		BENE M 2 Bright { A_SetScale(0.1, 1.8); }
		TNT1 A 0 { A_SetScale(1.0, 1.0); A_Scream(); A_NoBlocking(); }
		MISL XYZ 5 Bright { A_Explode(random(5, 15), 128); }
		TNT1 AA 0 { A_SpawnProjectile("RS_MineShotgun", random(20, 60), random(-15, 15), random(-20, 20), 0); }
		Stop;
	}
}

// The bubble Benellus wraps itself in before the focused-fire barrage --
// forty of these, purely a tell that the big one is coming.
class RS_SparkShieldBen : Actor
{
	Default
	{
		+NOGRAVITY; +SPAWNFLOAT; +NOINTERACTION;
		RenderStyle "Add"; Speed 1; Alpha 0.95; Scale 1.33; Mass 2;
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		PUFF ABABABAB 10 Bright;
		PUFF BBB 5 { A_FadeOut(0.33); }
		Stop;
	}
}

// The barrage itself: tiny, very fast, and it lays a spark puff on every
// single tic of flight, so the volume on screen is the point.
class RS_SparkFireBen : FastProjectile
{
	Default
	{
		Radius 2; Height 2; Speed 68; FastSpeed 100;
		DamageFunction (random(8, 15));
		Projectile; +MTHRUSPECIES;
		RenderStyle "Add"; Alpha 0.85; Scale 0.15;
		DeathSound "imp/shotx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		PUFF AB 1 Bright { A_SpawnItemEx("RS_SparkPuff1", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		TNT1 AAAAAAAAAAAA 0 { A_SpawnItemEx("RS_SparkPuff1", 0, 0, 0, random(-3, 3), random(-3, 3), random(-3, 3), random(-358, 358), SXF_NOCHECKPOSITION); }
		Stop;
	}
}

// ---------- CHAINGUNNER X0001 (the EX boss) ------------------------
// The lobbed bomb. Floats for its first arc, then gravity comes back on
// and it drops -- and the detonation is an EIGHT-STAGE escalating blast,
// each ring wider than the last. Getting out of the first one is not
// getting out of it. CORRECTED TO CH Chaingunners.txt:2050.
// This one was CHP top to bottom. Every single number moved:
//   Speed 48 -> 38; contact roll (25,100) -> CH's (20,80); the translation was
//   GREEN and CH's is ORANGE/YELLOW; and all EIGHT A_Explode rolls were CHP's
//   1.25x inflation of CH's -- (13,25)->(10,20), (13,37)->(10,30),
//   (25,75)->(20,60), (25,100)->(20,80), and the last four (38,112)->(30,90).
// Restored structurally: CH's SeeSound "spit/spit" and DeathSound "spit/spit2"
// (SNDINFO:1255/:1256, both real lumps), the third `GBLL ABC 6` frame of Fly
// that ours dropped, and the two A_PlaySound cues in the death chain --
// "spell/Impact1" at the start of the detonation (SNDINFO:1526) and
// "Bomb/boom" before the fifth ring (SNDINFO:1254). Without those the
// eight-stage blast landed in silence.
class RS_YellowBombCGuyEX : Actor
{
	Default
	{
		Radius 6; Height 6; Speed 38;
		DamageFunction (random(20, 80)); DamageType "Fire";
		Projectile; +RANDOMIZE; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 1.0; Scale 1.25;
		SeeSound "spit/spit"; DeathSound "spit/spit2";
		Translation "0:255=%[1.29,0.65,0.00]:[2.00,2.00,1.01]";
	}
	States
	{
	Spawn:
		GBLL ABC 6 Bright;
	Fly:
		GBLL ABC 6 Bright;
		TNT1 A 0 { bNOGRAVITY = false; }
		GBLL ABC 6 Bright;
		Loop;
	Death:
		GBLL A 6 Bright { A_SetScale(1.0, 1.0); }
		GBLL B 6 Bright { A_SetScale(0.75, 0.75); }
		GBLL C 6 Bright { A_SetScale(0.5, 0.5); }
		GBLL A 6 Bright { A_SetScale(0.25, 0.25); }
		GBLL BC 6 Bright;
		GBLL ABC 6 Bright;
		TNT1 A 0 { A_StartSound("spell/Impact1", CHAN_AUTO); }
		BBOM A 2 Bright { A_SetScale(0.5, 0.5); }
		TNT1 A 0 { A_Explode(random(10, 20), 32, 0); }
		BBOM B 2 Bright { A_SetScale(0.75, 0.75); }
		TNT1 A 0 { A_Explode(random(10, 30), 64, 0); }
		BBOM C 2 Bright { A_SetScale(1.25, 1.25); }
		TNT1 A 0 { A_Explode(random(20, 60), 74, 0); }
		BBOM C 2 Bright { A_SetScale(2.0, 2.0); }
		TNT1 A 0 { A_Explode(random(20, 80), 128, 0); }
		BBOM C 2 Bright { A_SetScale(2.5, 2.5); }
		TNT1 A 0 { A_StartSound("Bomb/boom", CHAN_AUTO); }
		TNT1 A 0 { A_Explode(random(30, 90), 176, 0); }
		BBOM C 2 Bright { A_SetScale(3.0, 3.0); }
		TNT1 A 0 { A_Explode(random(30, 90), 256, 0); }
		BBOM C 2 Bright { A_SetScale(3.5, 3.5); }
		TNT1 A 0 { A_Explode(random(30, 90), 256, 0); }
		BBOM C 2 Bright { A_SetScale(4.0, 4.0); }
		TNT1 A 0 { A_Explode(random(30, 90), 312, 0); }
		BBOM CCCBA 4 Bright { A_FadeOut(0.20); }
		Stop;
	}
}

// The spam round. Wide damage roll so a burst of these is genuinely swingy,
// and each one dies into a small cluster bomb.
// CORRECTED TO CH Chaingunners.txt:2106. Speed 35 -> 28, contact roll
// (13,150) -> CH's (10,120), death blast (28,110) -> CH's (22,88), and the
// green translation deleted -- CH declares none on this actor at all, so the
// round was being tinted a colour it does not have. Base changed
// FastProjectile -> Actor to match CH's plain ACTOR. CH's Spawn is a TNT1 A 0
// falling into a `Fly:` label, restored so any Goto into Spawn behaves as CH's.
class RS_SpamShotsCGuyEX : Actor
{
	Default
	{
		Radius 12; Height 9; Speed 28;
		DamageFunction (random(10, 120)); DamageType "Plasma";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 0.95; Scale 0.25;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		// CH also runs A_SpawnParticle("red", ...) on this frame and on two
		// 10x TNT1 lines in Death; the particle calls are omitted rather than
		// guessed at, and the two death lines are kept as explicit 0-tic
		// placeholders below so no frame index shifts.
		GRFZ DEFGH 2 Bright;
		Loop;
	Death:
		GRFZ IJ 4 Bright { A_SetScale(1.0, 1.0); }
		GRFZ K 4 Bright { A_Explode(random(22, 88), 256, 0); }
		TNT1 AAAAAAAAAA 0;
		GRFZ LMN 3 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-64, 64), random(-64, 64), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-128, 128), random(-128, 128), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAA 0;
		GRFZ OP 4 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-32, 32), random(-32, 32), random(-64, 128), random(12, 99), 0, random(-25, 25), random(0, 359), SXF_NOCHECKPOSITION); }
		Stop;
	}
}

// Identical round, fire damage type -- CH alternates the two through the volley
// so resistances can't cover the whole burst.
// CH Chaingunners.txt:2140: `ACTOR SpamShotsCguyEX2 : SpamShotsCguyEX
// { damagetype fire }`. Matches.
class RS_SpamShotsCGuyEX2 : RS_SpamShotsCGuyEX { Default { DamageType "Fire"; } }

// The sub-munition. Spawns already dead: it exists only to be an
// explosion at a random offset.
class RS_ExplosionsCGuyEX : FastProjectile
{
	Default
	{
		Radius 12; Height 9; Speed 35;
		DamageFunction (random(25, 75)); DamageType "Fire";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 0.95; Scale 0.42;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		GRFZ IJ 3 Bright;
		GRFZ K 3 Bright { A_Explode(random(14, 96), 128, 0); }
		GRFZ LMN 2 Bright;
		GRFZ OP 3 Bright;
		Stop;
	}
}

// Same, but it FLIES for eleven tics first. That delay is the whole
// trick: the second wave lands where you ran to.
class RS_ExplosionsCGuyEXDelayed : FastProjectile
{
	Default
	{
		Radius 3; Height 3; Speed 63;
		DamageFunction (random(25, 75)); DamageType "Fire";
		Projectile; +DONTHARMCLASS;
		RenderStyle "Add"; Alpha 0.95; Scale 0.42;
		SeeSound "weapons/bfgf"; DeathSound "weapons/bfgx";
		Translation "0:255=%[0.04,0.29,0.04]:[0.18,1.32,0.18]";
	}
	States
	{
	Spawn:
		TNT1 A 11;
	Death:
		TNT1 A 0 { A_Stop(); }
		GRFZ IJ 3 Bright;
		GRFZ K 3 Bright { A_Explode(random(14, 96), 128, 0); }
		GRFZ LMN 2 Bright;
		GRFZ OP 3 Bright;
		Stop;
	}
}

// THE big one. A seeker that trails saws and small blasts on the way in,
// then detonates into a two-stage 386-radius field seeded with roughly
// two hundred delayed sub-munitions. It is the general's finisher.
// CORRECTED TO CH Chaingunners.txt:2142. Speed 26 -> 21, contact roll
// (38,100) -> CH's (30,80), and all three death blasts were CHP's inflation:
// (6,38) -> CH's (5,30), (68,139) -> (55,111), (83,160) -> (66,128).
// The green translation is deleted -- CH declares none. Base changed
// FastProjectile -> Actor to match CH's plain ACTOR.
class RS_CGBigEX : Actor
{
	Default
	{
		Radius 8; Height 8; Speed 21;
		DamageFunction (random(30, 80)); DamageType "Plasma";
		Projectile; +NOGRAVITY; +SEEKERMISSILE;
		RenderStyle "Add"; Alpha 0.75; Scale 0.75;
		SeeSound "Spell/SpellCast1"; DeathSound "Fire/Fire4";
	}
	States
	{
	Spawn:
		RED9 B 1 Bright { A_SeekerMissile(2, 4); }
		RED9 AA 1 Bright { A_SpawnItemEx("RS_SpiralSaw5", 0, 0, 0, 0, 0, 0, 0, 128); }
		RED9 A 0 { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-128, 24), random(-64, 64), random(-32, 32), 1, 0, random(-1, 1), random(0, 359), SXF_NOCHECKPOSITION); }
		Loop;
	Death:
		SPIR A 1 Bright { A_SetScale(1.5); }
		// NINE frames, so nine blasts -- the grow-then-shrink pulse. CH's.
		SPIR ABCDEDCBA 5 Bright { A_Explode(random(5, 30), 164); }
		SPIR E 1 Bright { A_SetScale(3.0); }
		GRFZ IJ 4 Bright;
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-24, 68), random(12, 99), 0, random(-25, 25), random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-14, 28), random(12, 99), 0, random(-25, 25), random(180, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(0, 180), SXF_NOCHECKPOSITION); }
		GRFZ K 4 Bright { A_Explode(random(55, 111), 386, 0); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-6, 28), random(12, 99), 0, random(-25, 25), random(180, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(0, 180), SXF_NOCHECKPOSITION); }
		GRFZ LMN 3 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-64, 64), random(-64, 64), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(0, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-4, 28), random(12, 99), 0, random(-25, 25), random(180, 359), SXF_NOCHECKPOSITION); }
		TNT1 AAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_SpawnItemEx("RS_ExplosionsCGuyEXDelayed", random(-12, 12), random(-12, 12), random(-64, 128), random(12, 99), 0, random(-25, 25), random(0, 180), SXF_NOCHECKPOSITION); }
		TNT1 A 0 { A_Explode(random(66, 128), 386, 0); }
		GRFZ OP 4 Bright { A_SpawnItemEx("RS_ExplosionsCGuyEX", random(-64, 64), random(-124, 124), random(-32, 32), 0, 0, 0, random(0, 359), SXF_NOCHECKPOSITION); }
		GRFZ III 2 { A_FadeOut(0.20); }
		Stop;
	}
}

// The wind-up glyph. Harmless -- it exists purely so the two-second
// charge before the general's heavy shots is READABLE. Spawns straight
// into its own Death, which is the whole animation.
// CH Chaingunners.txt:2247. Both states already matched CH exactly. Two fixes:
// Speed 3 -> 2, and the green translation deleted -- CH declares none, so the
// wind-up glyph was being tinted a colour it does not have.
class RS_SpiralLoadGeneEX : Actor
{
	Default
	{
		Radius 2; Height 2; Speed 2;
		Projectile; +NOINTERACTION; +THRUACTORS;
		RenderStyle "Add"; Alpha 0.95; Scale 1.0;
	}
	States
	{
	Spawn:
		TNT1 A 0;
	Death:
		GRFZ CBA 4 Bright;
		TNT1 A 0 { A_SetScale(0.75, 0.75); }
		GRFZ BA 4 Bright;
		TNT1 A 0 { A_SetScale(0.5, 0.5); }
		GRFZ BA 4 Bright;
		TNT1 A 0 { A_SetScale(0.25, 0.25); }
		GRFZ BA 4 Bright;
		GRFZ I 1 Bright;
		TNT1 A 0 { A_SetScale(0.5, 0.5); }
		GRFZ I 1 Bright;
		TNT1 A 0 { A_SetScale(0.75, 0.75); }
		GRFZ I 1 Bright;
		Stop;
	}
}

// =====================================================================
// 2026-08-05 -- CH PASS OVER THE 31 CHAINGUNNER PROJECTILES.
// ---------------------------------------------------------------------
// The classes the 14 CH chaingunners fire were diffed against CH itself
// (CH/decorate/Chaingunners.txt, plus Zombies.txt and Revenants.txt for the
// three that live in other family files) and corrected. CHP was not opened.
// Where CH and CHP disagree, CH wins, because CH is what is being built.
//
// The sound remap list below is now PARTLY OBSOLETE and must not be trusted
// as a statement of what this file does. CH's sound library was imported this
// session (sounds/ch/, 804 new SNDINFO definitions), so the classes touched by
// this pass carry CH's own names again and every one of them was traced to a
// real lump: prox/beep, fire/fire3, weapons/boom1, weapons/firex4, SNPRFIRE,
// spit/spit, spit/spit2, spell/Impact1, Bomb/boom, slimeball/splat,
// moloch/nailhit, moloch/nailhitbleed, Jam/Jamd, arachnobaron/death,
// SlimeBall/Shoot and all five slimeworm/* names. The remaps that remain below
// belong to classes this pass did not touch.
//
// Three actors were ADDED because corrected classes name them and nothing in
// the repo defined them -- an unresolvable class-name string is a compile
// error, not a silent no-op: RS_Trail14 (CH :2805), RS_Puddle2 (CH :2707) and
// RS_CGthing3 (CH :769).
//
// Two of CH's spawns are deliberately NOT reproduced, each replaced by an
// explicit 0-tic TNT1 placeholder so no `Goto X+N` offset can shift:
// AbyssShotIdentifier in RS_SplashAbyssCguy (needs CallACS("CH_AbyssMark"),
// which does not exist here) and a_settranslation("BBEASTEX5") in
// RS_BrownOrbCguy (needs a TRNSLATE entry this repo does not have).
// =====================================================================

// --- IMPORT CORRECTIONS -------------------------------------------
// Broken sprite references inherited from the source, fixed on import:
//   * CHP sound names with no SNDINFO entry in this repo remapped to the
//     nearest vanilla logical name (SNPRFIRE/weapons/firex4 -> weapons/
//     rocklf|rocklx, monster/dknmsl -> weapons/rocklf, weapons/boom1 |
//     weapons/hellex -> weapons/rocklx, SlimeBall/Shoot -> imp/attack,
//     slimeworm/* -> demon/*, BabyCaco/* -> caco/*, arachnobaron/death
//     -> baron/death). Adding the CH oggs is task #2, not this pass.
//   * SGRN -> GRND, in RS_SGGasNade. THIS ENTRY USED TO BE WRONG and is
//     kept here as a warning. SGRN exists nowhere, so retargeting the token
//     was right -- but the entry was logged as done while three separate
//     things about it were still broken:
//       - it sat in Death (`GRND ABCD`) when CH puts the grenade in SPAWN
//         and explodes on MISL B/CD (Shotgunners.txt:1692). Same Spawn/Death
//         inversion as RS_MineShotgun below; both came in backwards.
//       - GRND art was never copied into the repo, so the reference could
//         not have resolved at load time regardless.
//       - to make the lint go quiet, 'GRND':'A' was added to verify.py's
//         VANILLA token table. GRND is not a Doom sprite. That entry has
//         been removed; the art now lives in sprites/monsters/projectiles/
//         (frames A-H,J,K from the top-level ART SOURCE weapon pack) and
//         resolves honestly through the repo sprite tree.
//   * RS_MineShotgun had Spawn and Death swapped against CH's MineShotgun
//     (Shotgunners.txt:2473): CH spawns SHOT A -- the IWAD shotgun PICKUP
//     lump, i.e. the mine is a thrown shotgun tumbling along the floor --
//     and dies on MISL BCD. The port had Spawn MISL A / Death SHOT ABCD;
//     SHOT has only frame A in any IWAD, so B/C/D never existed. Restored
//     to CH's split, and the rest of the actor restored 1:1 with it: the
//     gravity (it falls and rolls, it does not float), the scale throb, the
//     random cook-off jump, the bounce kick, BounceCount 11, and the
//     shotgun/rocket sounds. The port had flattened all of that away.
//     No art copied: the only SHOTA0 in ART SOURCE is in the top-level
//     weapon pack, and dropping it in sprites/ would silently reskin the
//     vanilla shotgun pickup mod-wide. SHOT A comes from the IWAD.
//   * RS_BrownSGshot's PUFF DE -> PUFF D. Vanilla PUFF is A-D; the E is a
//     typo carried verbatim from CH (Shotgunners.txt:186) and re-copied into
//     CHP's BrownSGshot_C. It is the only PUFF E reference in either pack --
//     every other PUFF line in CH/CHP stays inside A-D -- and no PUFF art
//     exists anywhere in ART SOURCE. Tics folded 6+6 -> 12 to keep the
//     post-A_Blast tail the same length.
//   * REVERSED 2026-08-04. This file used to record that "every A_Explode in
//     this file now fires ONCE", on the theory that a multi-frame line was a
//     bug. THE PREMISE WAS WRONG and the sweep is undone for the three actors
//     it rewrote (RS_CGBigOne, RS_MineShotgun, RS_SGGasNade).
//     Multi-frame A_Explode is CHP's deliberate idiom, not an accident: 4,545
//     of its ~14,100 A_Explode statements sit on multi-frame lines -- a third
//     of them. SPIR ABCDEDCBA is a grow-then-shrink cycle where the explosion
//     PULSES as it expands and collapses; MISL BCD is three rolls of a spread.
//     The repeat IS the attack.
//     The old note's own caveat -- that AGAS, LITN, B5P1, FIRE CDEEDCDE and
//     RIP1 must be left alone because the repeat is the mechanic -- was right,
//     and it turns out to generalise to the whole idiom rather than being a
//     list of exceptions.
//     Worse, the rewrite invented numbers CH never had (a 280/120 split on
//     CGBigOne "kept at 400", when CH's real total is random(5,30) x 9 =
//     45-270) and flattened two damage rolls to constants. RS_SGGasNade's
//     CH death is a SINGLE frame, so the sweep's own justification never even
//     applied to it.
//     DO NOT RE-RUN THIS PASS. See docs/rs_18 C1, closed as WON'T DO.
