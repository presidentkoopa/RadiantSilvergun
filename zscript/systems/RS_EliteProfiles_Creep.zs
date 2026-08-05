// =====================================================================
// RS_EliteProfiles_Creep -- the two ground-hazard elite profiles, and the
// shared creep system underneath them.
// ---------------------------------------------------------------------
// Design of record: docs/rs_25_elites_design.txt and rs_26. The contract
// this file writes against is RS_EliteProfile in RS_Elites.zs; read that
// first if you have not.
//
// WHAT A "CREEP" ELITE IS: it does not shoot you more, it takes the floor
// away from you. While it has a target it drips a patch of hazard behind
// itself roughly three times a second, so a fight that moves through a
// corridor leaves the corridor poisoned. The two profiles here are the
// same delivery mechanism with two completely different payloads:
//
//   DARKGREEN  the patch poisons -- damage over time, and the ONLY defence
//              is a radiation suit. Kill it or leave the room.
//   WHITE      the patch slows you to a third of your speed. It does no
//              damage at all; it just makes everything ELSE in the room
//              lethal, which is worse.
//
// ONE BASE, TWO PROFILES, AND WHY THE ORDER OF THIS FILE MATTERS:
// RS_EliteCreepBase is defined first because both profiles' patches
// inherit from it. Everything that differs between them -- colour, how
// long a patch lives, how often it pulses, what it hands the player when
// it does -- is a property on the base, set per subclass in Default. The
// base has no idea what a poison or a slow is; it just hands out an item
// on a timer. That is deliberate: a third creep profile should need a new
// item and a new Default block, and nothing else.
//
// THE MISSILE HALF. These are the only two profiles whose PROJECTILES also
// lay creep, and it is the whole reason RS_EliteProfile has an
// OnMissileSpawned hook -- a missile is not visible from the profile any
// other way. The controller routes every missile fired by its monster to
// us, and we hang a small trailer item on it. The trailer drips a reduced
// patch every 3 tics, drops one full-size patch when the missile stops or
// dies, and removes itself. So a revealed creep elite does not just poison
// where it walked, it poisons where it SHOT, which is the difference
// between a hazard you can walk around and a hazard that is coming to you.
//
// TWO PLACEHOLDERS, BOTH DELIBERATE, BOTH MARKED IN PLACE:
//   * the patch sprite is the existing poison-blob token, stencilled. See
//     RS_EliteCreepBase's states.
//   * the poison damage type has no MAPINFO DamageType block in this repo,
//     so it has no obituary. The engine accepts an undeclared type; the
//     only thing missing is the death message.
// =====================================================================

// ---------------------------------------------------------------------
// RS_EliteCreepBase -- one patch of hazard on the floor.
//
// TWO RENDER MODES, ONE ACTOR. A patch is either a flat decal lying on the
// floor plane (FLATSPRITE, re-anchored to floorz every tic so it follows
// stairs and lifts) or an upright sprite. Flat reads far better in the open
// and far worse in tight geometry, which is why it is an option rather
// than a decision.
//
// BOTH MODES STENCIL. The patch is drawn as a solid silhouette in its own
// colour rather than as its own art, in both modes. Colour identity is the
// entire point of these profiles -- a white elite laying green patches is
// nonsense -- and a stencil gets that without a palette translation per
// colour. It also means one sprite serves every future creep colour.
//
// THE PULSE IS ON LEVEL TIME, NOT ON THE PATCH'S OWN AGE. Every patch of
// the same CreepTick fires on the same tic. That is not laziness: it means
// standing in an overlap of four patches costs you four hits at once
// instead of a smeared trickle, so thick creep FEELS thick. Do not change
// this to GetAge() to "spread the load".
// ---------------------------------------------------------------------
class RS_EliteCreepBase : Actor
{
	class<Inventory> creepEffect;   // what a pulse hands the player
	int    creepRadius;             // cube half-extent of a pulse
	int    creepTick;               // tics between pulses
	int    creepLife;               // seconds of life before it fades
	double spriteScale;             // scale when upright
	double flatScale;               // scale when lying on the floor

	property CreepEffect : creepEffect;
	property CreepRadius : creepRadius;
	property CreepTick   : creepTick;
	property CreepLife   : creepLife;
	property SpriteScale : spriteScale;
	property FlatScale   : flatScale;

	int secondsAlive;               // counted at 35-tic marks, not per tic

	Default
	{
		+NOGRAVITY
		+BRIGHT
		Alpha 0.0;                  // faded in by the spawn states
		RenderStyle "Stencil";

		RS_EliteCreepBase.CreepRadius 48;
		RS_EliteCreepBase.CreepLife   3;
		RS_EliteCreepBase.CreepTick   35;
		RS_EliteCreepBase.SpriteScale 0.6;
		RS_EliteCreepBase.FlatScale   0.3;
	}

	// Flat patches on or off. Read through FindCVar rather than as a bare
	// identifier so this file compiles whether or not the option exists
	// yet -- a bare cvar name that is not declared is a hard compile error,
	// and this file is not allowed to declare one.
	static bool FlatCreep()
	{
		let cv = CVar.FindCVar("rs_elite_creep_flat");
		return cv ? cv.GetBool() : true;
	}

	// Whether missiles trail creep as well as the monster.
	//
	// JUDGEMENT CALL, FLAGGED: defaults ON here. The projectile trail is a
	// per-elite cost and elites are rare -- a handful per map, and only the
	// fraction of those that both reveal and roll one of these two
	// profiles. Turn it into a real option if a stress map says otherwise.
	static bool ProjectileCreepOn()
	{
		let cv = CVar.FindCVar("rs_elite_projectile_creep");
		return cv ? cv.GetBool() : true;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();

		bFLATSPRITE = FlatCreep();
		bSPRITEFLIP = (random(0, 1) == 1);

		if (bFLATSPRITE)
		{
			// Snap to the floor once here, then every tic in Tick(). The
			// second argument is "moving" -- false on the initial placement
			// so it does not interpolate in from wherever it spawned.
			SetOrigin((pos.x, pos.y, floorz + 1), false);

			double s = FRandom(flatScale, flatScale + (flatScale * 0.2));
			Scale.X = s;
			Scale.Y = s;

			// Free rotation only makes sense lying down; upright patches
			// keep the spawner's angle so they face the player.
			angle = FRandom(0.0, 360.0);
		}
		else
		{
			double s = FRandom(spriteScale, spriteScale + (spriteScale * 0.2));
			Scale.X = s;
			Scale.Y = s;
		}
	}

	override void Tick()
	{
		Super.Tick();

		if (isFrozen())
			return;

		if (level.Time % creepTick == 0)
			A_RadiusGive(creepEffect, creepRadius, RGF_CUBE | RGF_PLAYERS, 1);

		// Life is counted in whole seconds rather than tics so that
		// CreepLife reads as "how many seconds does this patch last".
		if (GetAge() % 35 == 0)
		{
			secondsAlive++;
			if (secondsAlive > creepLife)
				SetStateLabel("Disappear");
		}

		if (bFLATSPRITE)
			SetOrigin((pos.x, pos.y, floorz + 1), true);
	}

	States
	{
	Spawn:
		// NoDelay because BeginPlay has already chosen the mode and this
		// has to branch on it before the first frame is drawn.
		TNT1 A 1 NoDelay A_JumpIf(bFLATSPRITE, "SpawnFlat");
		Goto SpawnSprite;

	// The fade-ins stop where they stop. Five steps flat, three upright:
	// a flat patch settles at 0.5 alpha and an upright one at 0.3, because
	// an upright sprite occludes the fight behind it and a floor decal
	// does not. These are the ceiling, not a stage -- there is nothing
	// after them that raises alpha further.
	SpawnFlat:
		CRPG EEEEE 1 A_FadeIn(0.1);
	SpawnFlatLoop:
		CRPG E 35;
		Loop;

	SpawnSprite:
		CRPG III 1 A_FadeIn(0.1);
	SpawnSpriteLoop:
		CRPG EFGHI 6;
		Loop;

	// Fade and shrink together, so a patch dies by drying up rather than
	// by blinking out. A_FadeOut removes the actor by itself at zero alpha;
	// the scale test is the belt to its braces.
	Disappear:
		"####" "#" 1
		{
			A_FadeOut(0.1);
			A_SetScale(Scale.X - (Scale.X * 0.05));
			if (Scale.X < 0.00001)
				Destroy();
		}
		Wait;
	}
}

// ---------------------------------------------------------------------
// RS_EliteCreepDamage -- one poison tick.
//
// Handed to the player by a green patch's pulse. AUTOACTIVATE means it
// fires its Use state the instant it lands and is consumed, so it is a
// message rather than an item.
//
// THE RADIATION SUIT IS THE COUNTER AND IT IS TOTAL. Not a damage
// reduction -- the tick is skipped outright. That is the deal: green creep
// is the profile a rad suit trivialises, and it is meant to make finding
// one matter.
//
// The damage type has no DamageType block in this repo's MAPINFO, so there
// is no custom obituary. The engine is happy with an undeclared name; if a
// "poisoned" death message is wanted later, that is a MAPINFO edit, not a
// change here.
// ---------------------------------------------------------------------
class RS_EliteCreepDamage : CustomInventory
{
	Default
	{
		+INVENTORY.AUTOACTIVATE
		Inventory.MaxAmount 1;
	}

	States
	{
	Use:
		TNT1 A 0
		{
			// invoker is the item, self is whoever picked it up.
			if (invoker.owner && invoker.owner.CountInv("PowerIronFeet"))
				return;

			// AAPTR_NULL for the source so nothing is credited with the
			// kill and no infighting is triggered by the floor.
			A_DamageSelf(5, "RS_EliteToxic", src: AAPTR_NULL);
		}
		Stop;
	}
}

// ---------------------------------------------------------------------
// The green family. CreepLife 3 seconds at the base pulse rate; the red
// upgrade lives twice as long and pulses at better than twice the rate,
// which is where the reveal actually lands -- the patches stop being an
// area to avoid and start being an area you cannot cross.
// ---------------------------------------------------------------------
class RS_EliteCreepGreen : RS_EliteCreepBase
{
	Default
	{
		StencilColor "00E600";

		RS_EliteCreepBase.CreepEffect "RS_EliteCreepDamage";
		RS_EliteCreepBase.CreepLife 3;
	}
}

class RS_EliteCreepRed : RS_EliteCreepGreen
{
	Default
	{
		StencilColor "CC0000";

		RS_EliteCreepBase.CreepLife 6;
		RS_EliteCreepBase.CreepTick 17;
	}
}

// The small variants exist for the projectile trail only. A missile drips
// one of these every 3 tics, so at full size the trail would be a solid
// wall of overlapping hazard rather than a trail.
class RS_EliteCreepGreenSmall : RS_EliteCreepGreen
{
	Default
	{
		RS_EliteCreepBase.CreepRadius 32;
		RS_EliteCreepBase.SpriteScale 0.3;
		RS_EliteCreepBase.FlatScale   0.15;
	}
}

class RS_EliteCreepRedSmall : RS_EliteCreepRed
{
	Default
	{
		RS_EliteCreepBase.CreepRadius 32;
		RS_EliteCreepBase.SpriteScale 0.3;
		RS_EliteCreepBase.FlatScale   0.15;
	}
}

// ---------------------------------------------------------------------
// The slow, in three parts.
//
// RS_EliteSlowEffect is the powerup that actually holds the player at a
// third of their speed. RS_EliteSlow3 and RS_EliteSlow6 are the givers --
// the same effect at 3 and 6 seconds.
//
// WHY IT IS A POWERUP AND NOT A VELOCITY SCALE: a powerup re-applied every
// pulse just refreshes its own timer, so standing in creep is a constant
// slow and stepping out of it expires on a clock the player can feel. A
// per-tic velocity scale would fight the movement code and would end the
// instant the patch stopped pulsing, which reads as stutter, not weight.
//
// NOSCREENBLINK on the effect, plus a very light white tint on the giver:
// the player should see that the world has gone white-ish, not that a
// powerup icon appeared. There is no HUD icon on purpose.
// ---------------------------------------------------------------------
class RS_EliteSlowEffect : PowerSpeed
{
	Default
	{
		Inventory.Icon "";
		Speed 0.33;
		+POWERSPEED.NOTRAIL
		+INVENTORY.NOSCREENBLINK
	}
}

class RS_EliteSlow3 : PowerupGiver
{
	Default
	{
		Powerup.Type "RS_EliteSlowEffect";
		Powerup.Duration -3;            // negative is SECONDS, not tics
		Powerup.Color "FF FF FF", 0.2;
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.ALWAYSPICKUP
	}
}

class RS_EliteSlow6 : RS_EliteSlow3
{
	Default
	{
		Powerup.Duration -6;
	}
}

// ---------------------------------------------------------------------
// The white family. Note these pulse roughly twice as fast as green's
// base patch and live twice as long: a slow that flickers is not a slow,
// it has to be continuous while you are standing in it.
//
// The big variant is identical in every dimension except what it hands
// out -- the reveal upgrade here is duration of the slow, not size or
// reach of the patch.
// ---------------------------------------------------------------------
class RS_EliteCreepWhite : RS_EliteCreepBase
{
	Default
	{
		RenderStyle "Stencil";
		StencilColor "F2F2F2";

		RS_EliteCreepBase.CreepEffect "RS_EliteSlow3";
		RS_EliteCreepBase.CreepLife 6;
		RS_EliteCreepBase.CreepTick 18;
	}
}

class RS_EliteCreepWhiteBig : RS_EliteCreepWhite
{
	Default
	{
		RS_EliteCreepBase.CreepEffect "RS_EliteSlow6";
		RS_EliteCreepBase.CreepLife 6;
		RS_EliteCreepBase.CreepTick 18;
	}
}

class RS_EliteCreepWhiteSmall : RS_EliteCreepWhite
{
	Default
	{
		RS_EliteCreepBase.CreepEffect "RS_EliteSlow3";
		RS_EliteCreepBase.CreepLife 6;
		RS_EliteCreepBase.CreepTick 18;

		RS_EliteCreepBase.CreepRadius 32;
		RS_EliteCreepBase.SpriteScale 0.3;
		RS_EliteCreepBase.FlatScale   0.15;
	}
}

// ---------------------------------------------------------------------
// The projectile trailers.
//
// Hung on a missile by the profile's OnMissileSpawned. DoEffect runs every
// tic for as long as the missile carries it, which gives us three things a
// missile cannot otherwise tell us:
//
//   * every third tic of flight -> a small patch, so the trail is dotted
//     rather than a continuous wall.
//   * the missile entering its Death sequence -> one FULL patch at the
//     impact point. The impact is the payload; the trail is the tax.
//   * the missile stopping dead (both horizontal velocities zero) -> the
//     same full patch. This catches the projectiles that never enter a
//     Death state at all, and without it those simply stop trailing and
//     leave the hazard hanging in mid-air.
//
// Both terminal cases destroy the trailer, so the full patch drops exactly
// once however the missile ends.
// ---------------------------------------------------------------------
class RS_EliteMissileCreepGreen : Inventory
{
	override void DoEffect()
	{
		Super.DoEffect();

		// Guarded up front: DoEffect is reachable during the tic in which
		// the owner is being torn down.
		if (!owner)
			return;

		if (owner.GetAge() % 3 == 0)
			owner.A_SpawnItemEx("RS_EliteCreepGreenSmall",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);

		if (owner.InStateSequence(owner.CurState, owner.FindState("Death")))
		{
			owner.A_SpawnItemEx("RS_EliteCreepGreen",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);
			Destroy();
			return;
		}

		if (owner.vel.x == 0 && owner.vel.y == 0)
		{
			owner.A_SpawnItemEx("RS_EliteCreepGreen",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}
	}
}

class RS_EliteMissileCreepRed : Inventory
{
	override void DoEffect()
	{
		Super.DoEffect();

		if (!owner)
			return;

		if (owner.GetAge() % 3 == 0)
			owner.A_SpawnItemEx("RS_EliteCreepRedSmall",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);

		if (owner.InStateSequence(owner.CurState, owner.FindState("Death")))
		{
			owner.A_SpawnItemEx("RS_EliteCreepRed",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);
			Destroy();
			return;
		}

		if (owner.vel.x == 0 && owner.vel.y == 0)
		{
			owner.A_SpawnItemEx("RS_EliteCreepRed",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}
	}
}

class RS_EliteMissileCreepWhite : Inventory
{
	override void DoEffect()
	{
		Super.DoEffect();

		if (!owner)
			return;

		if (owner.GetAge() % 3 == 0)
			owner.A_SpawnItemEx("RS_EliteCreepWhiteSmall",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);

		if (owner.InStateSequence(owner.CurState, owner.FindState("Death")))
		{
			owner.A_SpawnItemEx("RS_EliteCreepWhite",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);
			Destroy();
			return;
		}

		if (owner.vel.x == 0 && owner.vel.y == 0)
		{
			owner.A_SpawnItemEx("RS_EliteCreepWhite",
			                    xofs: -16, yofs: FRandom(-16.0, 16.0),
			                    angle: FRandom(0.0, 360.0),
			                    flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}
	}
}

// =====================================================================
// RS_EliteProfile_DarkGreen -- poisons the ground it walks on.
//
// Ticks every 10 tics and drops one patch behind itself whenever it has a
// target. THE TARGET GATE IS THE WHOLE DESIGN: an elite that has not seen
// anybody lays no creep at all, so a map does not slowly fill with hazard
// from monsters nobody has met. It starts poisoning the moment it starts
// hunting, and not before.
//
// The patch is dropped 16 units BEHIND the monster with a random sideways
// jitter, so the trail reads as something shed while moving rather than
// something planted under its feet.
//
// The reveal swaps green for red across the board -- ground patches and
// projectile trails together, since they read as one effect and a red
// elite dripping green would look like a bug.
// =====================================================================
class RS_EliteProfile_DarkGreen : RS_EliteProfile
{
	class<Actor>     creep;         // what the monster drips
	class<Inventory> missileCreep;  // what its projectiles drip

	color shade;
	bool  shadePicked;

	override color GetShade()
	{
		// ROLLED ONCE AND KEPT. The controller reads this at reveal to fix
		// the aura and pentagram colour for the elite's whole life; a fresh
		// roll per call would strobe the moment anything asked twice.
		//
		// A SWITCH, NOT AN ARRAY -- `static const color x[] = {...}` does
		// not resolve on this engine build. See the note in RS_Elites.zs.
		if (!shadePicked)
		{
			shadePicked = true;
			switch (random(0, 3))
			{
				case 0:  shade = "00B300"; break;
				case 1:  shade = "008000"; break;
				case 2:  shade = "004D00"; break;
				default: shade = "001A00"; break;
			}
		}
		return shade;
	}

	override void OnSelected()
	{
		tickInterval = 10;
		creep        = "RS_EliteCreepGreen";
		missileCreep = "RS_EliteMissileCreepGreen";
	}

	override void OnReveal()
	{
		creep        = "RS_EliteCreepRed";
		missileCreep = "RS_EliteMissileCreepRed";
	}

	override void OnTick()
	{
		if (!mon || !mon.target)
			return;

		mon.A_SpawnItemEx(creep,
		                  xofs: -16, yofs: FRandom(-16.0, 16.0),
		                  angle: FRandom(0.0, 360.0),
		                  flags: SXF_SETTARGET);
	}

	// NO OnDeath ON PURPOSE. A death-burst patch was considered and is not
	// here: the corpse is where the player is standing when it dies, and a
	// guaranteed poison pool under a fresh kill punishes winning.

	override void OnMissileSpawned(Actor missile)
	{
		if (!missile || !missileCreep)
			return;

		if (!RS_EliteCreepBase.ProjectileCreepOn())
			return;

		missile.GiveInventory(missileCreep, 1);
	}
}

// =====================================================================
// RS_EliteProfile_White -- takes your speed instead of your health.
//
// Same drip mechanism as its green sibling and the same target gate, plus
// a second, separate slow: on half of its ticks it slows every player
// within a couple of body-widths DIRECTLY, with no patch involved. That
// second channel is what makes it dangerous rather than merely annoying --
// backing out of the creep does not free you while the elite is still on
// top of you, so the answer to a white elite is to kill it, not to move.
//
// The direct slow is always the LONG one even before the reveal. The
// reveal upgrades the patches (long slow instead of short) and widens the
// direct slow from two body-widths to three. Nothing here does damage;
// everything here is about denying the player the option to leave.
// =====================================================================
class RS_EliteProfile_White : RS_EliteProfile
{
	class<Actor>     creep;
	class<Inventory> missileCreep;
	int              radFactor;     // multiples of the monster's radius

	color shade;
	bool  shadePicked;

	override color GetShade()
	{
		if (!shadePicked)
		{
			shadePicked = true;
			switch (random(0, 2))
			{
				case 0:  shade = "FFFFFF"; break;
				case 1:  shade = "B3B3B3"; break;
				default: shade = "666666"; break;
			}
		}
		return shade;
	}

	override void OnSelected()
	{
		tickInterval = 10;
		creep        = "RS_EliteCreepWhite";
		missileCreep = "RS_EliteMissileCreepWhite";
		radFactor    = 2;
	}

	override void OnReveal()
	{
		// The projectile trailer does NOT change on reveal -- white has
		// only the one. Only the ground patches and the direct slow do.
		creep     = "RS_EliteCreepWhiteBig";
		radFactor = 3;
	}

	override void OnTick()
	{
		if (!mon || !mon.target)
			return;

		// Half the ticks, so the direct slow pulses rather than pins. At
		// every tick it would be indistinguishable from a permanent debuff
		// and the player would never learn where its reach ends.
		if (!random(0, 1))
			mon.A_RadiusGive("RS_EliteSlow6", mon.radius * radFactor,
			                 RGF_PLAYERS, 1);

		// No angle randomisation here, unlike green: white patches are
		// bright and near-featureless, and a rotating one flickers.
		mon.A_SpawnItemEx(creep,
		                  xofs: -16, yofs: FRandom(-16.0, 16.0),
		                  flags: SXF_SETTARGET);
	}

	override void OnMissileSpawned(Actor missile)
	{
		if (!missile || !missileCreep)
			return;

		if (!RS_EliteCreepBase.ProjectileCreepOn())
			return;

		missile.GiveInventory(missileCreep, 1);
	}
}
