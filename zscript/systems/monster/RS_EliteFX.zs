// =====================================================================
// RS_EliteFX -- support actors for the Elite colour powers.
// ---------------------------------------------------------------------
// Everything a colour spawns or grants lives here: explosions, creeps,
// fireballs, leaves, shadows, sparkles, the resurrection corpse, the
// slow/poison payloads, and the marker tokens. RS_EliteColors.zs
// references these by string only.
//
// Sprites: sprites/monsters/elitefx/ (OEXP BSPL CRPG XXST MAGN RSPL
// CROS), plus LEF1/LEF2/CBAL which already resolve from
// sprites/monsters/fx/ and FIRE/TFOG from the IWAD.
// =====================================================================

// --- marker tokens ---------------------------------------------------

// Carried by actors the Elite system must never touch again: clones,
// converted monsters. The handler skips anything holding one.
class RS_EliteNullToken : Inventory
{
	Default
	{
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNDROPPABLE;
	}
}

// Marks a death-clone (C09) -- kept distinct from the null token so
// later systems can tell "never elite" from "is a copy".
class RS_EliteCloneToken : Inventory {}

// Marks a monster already converted by the C17 aura.
class RS_EliteMidasToken : Inventory
{
	Default
	{
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.UNDROPPABLE;
	}
}

// Pitch-shifts the owner's voice -- clones squeak (factor > 1).
class RS_EliteFX_VoiceChanger : Inventory
{
	double factor;

	override void Tick()
	{
		Super.Tick();
		if (owner != null)
			owner.A_SoundPitch(CHAN_VOICE, factor);
	}
}

// --- the wake flash --------------------------------------------------

// Vile-style flame column spawned the moment an Elite reveals. FIRE is
// the IWAD sprite; the spawner transfers the elite's translation.
class RS_EliteFX_WakeFire : Actor
{
	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+ZDOOMTRANS
		RenderStyle "Add";
		Alpha 1;
	}
	States
	{
	Spawn:
		FIRE A 2 BRIGHT;
		FIRE BAB 2 BRIGHT;
		FIRE C 2 BRIGHT;
		FIRE BCBCDCDCDEDED 2 BRIGHT;
		FIRE E 2 BRIGHT;
		FIRE FEFEFGHGHGH 2 BRIGHT;
		Stop;
	}
}

// --- C01 Dark Red: the vulnerable remains ----------------------------

// While the dark red elite is "dead", this is what actually lies on the
// floor. Destroy it before the timer runs out or the elite comes back.
class RS_EliteFX_Corpse : Actor
{
	Default
	{
		+SOLID;
		+SHOOTABLE;
		+ISMONSTER;
		Health 30;
		Radius 16;
		Height 16;
		YScale 0.66;
	}
	States
	{
	Spawn:
		RSPL A 1;
		wait;
	Death:
		TNT1 A 0
		{
			for (int i; i < 32; i++)
			{
				A_SpawnItemEx("Blood", xvel: frandom(3.0, 8.0), zvel: frandom(4.0, 8.0),
					angle: frandom(0.0, 359.9), flags: SXF_USEBLOODCOLOR);
			}
		}
		TNT1 A 35;
		stop;
	}
}

// --- C03 Orange: death explosions ------------------------------------

class RS_EliteFX_Explosion : Rocket
{
	Default
	{
		-ROCKETTRAIL;
		Speed 0;
	}
	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_StartSound("weapons/rocklx");
	Death:
		OEXP A 8 Bright A_Explode();
		OEXP B 6 Bright;
		OEXP C 4 Bright;
		stop;
	}
}

class RS_EliteFX_ClusterExplosion : Rocket
{
	Default
	{
		-ROCKETTRAIL;
		Speed 0;
	}
	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_StartSound("weapons/rocklx");
	Death:
		OEXP A 8 Bright
		{
			for (int i = 0; i < 8; i++)
			{
				A_SpawnItemEx("RS_EliteFX_MiniCluster", xvel: frandom(4.0, 8.0),
					zvel: frandom(4.0, 8.0), angle: random(0, 360));
			}
			A_Explode();
		}
		OEXP B 6 Bright;
		OEXP C 4 Bright;
		stop;
	}
}

class RS_EliteFX_MiniCluster : RS_EliteFX_Fireball1
{
	Default
	{
		DamageFunction (0);
		Gravity 0.6;
		Scale 0.75;
		DeathSound "";
		Translation "rs_elite_c13";
		RenderStyle "Normal";
		+DEHEXPLOSION;
	}
	States
	{
	Death:
		OEXP A 8 Bright
		{
			A_SetTranslation("none");
			A_Explode(64, 64);
			A_StartSound("weapons/rocklx", CHAN_BODY, volume: 0.2);
		}
		OEXP B 6 Bright;
		OEXP C 4 Bright;
		stop;
	}
}

// --- C08 / C10: fireballs --------------------------------------------

// Gravity-arc fireball. Won't hurt the thrower's own kind.
class RS_EliteFX_Fireball1 : DoomImpBall
{
	Default
	{
		-NOGRAVITY;
		Speed 10;
		Damage 3;
		Gravity 0.1;
	}
	override int SpecialMissileHit(Actor victim)
	{
		if (victim && target && victim is target.GetClassName())
			return 1;
		return -1;
	}
	States
	{
	Spawn:
		CBAL AB 4 Bright;
		loop;
	Death:
		CBAL CDE 4 Bright;
		stop;
	}
}

// Seeker variant for C10's volleys.
class RS_EliteFX_Fireball2 : DoomImpBall
{
	Default
	{
		-NOGRAVITY;
		+SEEKERMISSILE;
		Speed 10;
		Gravity 0.1;
	}
	States
	{
	Spawn:
		CBAL AB 4 Bright A_SeekerMissile(0, 4);
		loop;
	Death:
		CBAL CDE 4 Bright;
		stop;
	}
}

// --- creep: the shared floor-hazard body (C05 / C14) -----------------

class RS_EliteFX_CreepBase : Actor
{
	int count;

	property CreepEffect: CreepEffect;	class<Inventory> CreepEffect;
	property CreepRadius: CreepRadius;	int CreepRadius;
	property CreepTick: CreepTick;		int CreepTick;
	property CreepLife: CreepLife;		int CreepLife;
	property SpriteScale: SpriteScale;	double SpriteScale;
	property FlatScale: FlatScale;		double FlatScale;

	Default
	{
		+NOGRAVITY;
		+BRIGHT;
		Alpha 0.0;
		RenderStyle "Stencil";
		RS_EliteFX_CreepBase.CreepRadius 48;
		RS_EliteFX_CreepBase.CreepLife 3;
		RS_EliteFX_CreepBase.CreepTick 35;
		RS_EliteFX_CreepBase.SpriteScale 0.6;
		RS_EliteFX_CreepBase.FlatScale 0.3;
	}

	override void BeginPlay()
	{
		Super.BeginPlay();
		bFLATSPRITE = CVar.FindCVar("rs_elite_flatcreep").GetBool();
		bSPRITEFLIP = random(0, 1);
		if (bFLATSPRITE)
		{
			SetOrigin((pos.x, pos.y, floorz + 1), false);
			scale.x = scale.y = frandom(flatScale, flatScale + (flatScale * 0.2));
			angle = frandom(0.0, 360.0);
		}
		else
		{
			A_SetRenderStyle(0.0, STYLE_TRANSLUCENT);
			scale.x = scale.y = frandom(spriteScale, spriteScale + (spriteScale * 0.2));
		}
	}

	override void Tick()
	{
		Super.Tick();

		if (isFrozen())
			return;

		if (level.Time % creepTick == 0)
			A_RadiusGive(creepEffect, creepRadius, RGF_CUBE | RGF_PLAYERS, 1);

		if (GetAge() % 35 == 0)
		{
			count += 1;
			if (count > creepLife)
				SetStateLabel("Disappear");
		}

		if (bFLATSPRITE)
			SetOrigin((pos.x, pos.y, floorz + 1), true);
	}
	States
	{
	Spawn:
		TNT1 A 1 NoDelay A_JumpIf(bFLATSPRITE, "SpawnFlat");
		TNT1 A 0 A_Jump(256, "SpawnSprite");
	SpawnFlat:
		BSPL AAAAA 1 A_FadeIn(0.1);
	SpawnFlatLoop:
		BSPL A 35;
		loop;
	SpawnSprite:
		CRPG III 1 A_FadeIn(0.1);
	SpawnSpriteLoop:
		CRPG EFGHI 6;
		loop;
	Disappear:
		"####" "#" 1 { A_FadeOut(0.1); A_SetScale(scale.x - (scale.x * 0.05)); if (scale.x < 0.00001) { Destroy(); } }
		wait;
	}
}

class RS_EliteFX_DarkGreenCreep : RS_EliteFX_CreepBase
{
	Default
	{
		StencilColor "00e600";
		Translation "rs_elite_c06";
		RS_EliteFX_CreepBase.CreepEffect 'RS_EliteFX_CreepDamage';
		RS_EliteFX_CreepBase.CreepLife 3;
	}
}

// The boosted C05 trail: hotter, denser, longer-lived.
class RS_EliteFX_RedCreep : RS_EliteFX_DarkGreenCreep
{
	Default
	{
		Translation "rs_elite_c02";
		StencilColor "cc0000";
		RS_EliteFX_CreepBase.CreepLife 6;
		RS_EliteFX_CreepBase.CreepTick 17;
	}
}

class RS_EliteFX_SmallDarkGreenCreep : RS_EliteFX_DarkGreenCreep
{
	Default
	{
		RS_EliteFX_CreepBase.CreepRadius 32;
		RS_EliteFX_CreepBase.SpriteScale 0.3;
		RS_EliteFX_CreepBase.FlatScale 0.15;
	}
}

class RS_EliteFX_SmallRedCreep : RS_EliteFX_RedCreep
{
	Default
	{
		RS_EliteFX_CreepBase.CreepRadius 32;
		RS_EliteFX_CreepBase.SpriteScale 0.3;
		RS_EliteFX_CreepBase.FlatScale 0.15;
	}
}

class RS_EliteFX_WhiteCreep : RS_EliteFX_CreepBase
{
	Default
	{
		RenderStyle "Stencil";
		StencilColor "f2f2f2";
		Translation "rs_elite_c14";
		RS_EliteFX_CreepBase.CreepEffect 'RS_EliteFX_Slowness1';
		RS_EliteFX_CreepBase.CreepLife 6;
		RS_EliteFX_CreepBase.CreepTick 18;
	}
}

class RS_EliteFX_BigWhiteCreep : RS_EliteFX_WhiteCreep
{
	Default
	{
		RS_EliteFX_CreepBase.CreepEffect 'RS_EliteFX_Slowness2';
		RS_EliteFX_CreepBase.CreepLife 6;
		RS_EliteFX_CreepBase.CreepTick 18;
	}
}

class RS_EliteFX_SmallWhiteCreep : RS_EliteFX_WhiteCreep
{
	Default
	{
		RS_EliteFX_CreepBase.CreepEffect 'RS_EliteFX_Slowness1';
		RS_EliteFX_CreepBase.CreepLife 6;
		RS_EliteFX_CreepBase.CreepTick 18;
		RS_EliteFX_CreepBase.CreepRadius 32;
		RS_EliteFX_CreepBase.SpriteScale 0.3;
		RS_EliteFX_CreepBase.FlatScale 0.15;
	}
}

// --- creep payloads --------------------------------------------------

// Toxic floor damage. A rad suit (PowerIronFeet) blocks it.
class RS_EliteFX_CreepDamage : CustomInventory
{
	Default
	{
		+INVENTORY.AUTOACTIVATE;
		Inventory.MaxAmount 1;
	}
	States
	{
	Use:
		TNT1 A 0
		{
			if (invoker.owner && invoker.owner.CountInv("PowerIronFeet"))
				return;
			A_DamageSelf(5, 'RSEliteToxic', src: AAPTR_NULL);
		}
		stop;
	}
}

// Lingering poison applied when a C05 elite lands a hit -- see
// RS_EliteHandler.WorldThingDamaged.
class RS_EliteFX_PoisonBase : Powerup
{
	override void InitEffect()
	{
		Super.InitEffect();
		owner.A_SetBlend("88cc00", 0.33, 35 * 5);
	}

	override void DoEffect()
	{
		Super.DoEffect();
		if (owner && level.time % 35 == 0)
			owner.A_DamageSelf(2, 'RSEliteToxic', src: AAPTR_NULL);
	}
}

class RS_EliteFX_Poison : PowerupGiver
{
	Default
	{
		Powerup.Type "RS_EliteFX_PoisonBase";
		Powerup.Duration -3;
		+INVENTORY.AUTOACTIVATE;
		+INVENTORY.ALWAYSPICKUP;
	}
}

// Slow: a third of normal move speed while it lasts.
class RS_EliteFX_SlownessEffect : PowerSpeed
{
	Default
	{
		Inventory.Icon "";
		Speed 0.33;
		+POWERSPEED.NOTRAIL;
		+INVENTORY.NOSCREENBLINK;
	}
}

class RS_EliteFX_Slowness1 : PowerupGiver
{
	Default
	{
		Powerup.Type "RS_EliteFX_SlownessEffect";
		Powerup.Duration -3;
		Powerup.Color "FF FF FF", 0.2;
		+INVENTORY.AUTOACTIVATE;
		+INVENTORY.ALWAYSPICKUP;
	}
}

class RS_EliteFX_Slowness2 : RS_EliteFX_Slowness1
{
	Default
	{
		Powerup.Duration -6;
	}
}

// --- missile creep riders (rs_elite_missilecreep) --------------------

// Given to a C05/C14 elite's projectiles at spawn: the shot drips small
// creep in flight and drops a full patch where it dies or stalls.
class RS_EliteFX_DarkGreenMissileCreep : Inventory
{
	override void DoEffect()
	{
		Super.DoEffect();

		if (owner.GetAge() % 3 == 0)
			owner.A_SpawnItemEx("RS_EliteFX_SmallDarkGreenCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);

		if (owner && owner.InStateSequence(owner.CurState, owner.FindState("Death")))
		{
			owner.A_SpawnItemEx("RS_EliteFX_DarkGreenCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}

		if (owner && owner.vel.x == 0 && owner.vel.y == 0)
		{
			owner.A_SpawnItemEx("RS_EliteFX_DarkGreenCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}
	}
}

class RS_EliteFX_RedMissileCreep : Inventory
{
	override void DoEffect()
	{
		Super.DoEffect();

		if (owner.GetAge() % 3 == 0)
			owner.A_SpawnItemEx("RS_EliteFX_SmallRedCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);

		if (owner && owner.InStateSequence(owner.CurState, owner.FindState("Death")))
		{
			owner.A_SpawnItemEx("RS_EliteFX_RedCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}

		if (owner && owner.vel.x == 0 && owner.vel.y == 0)
		{
			owner.A_SpawnItemEx("RS_EliteFX_RedCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}
	}
}

class RS_EliteFX_WhiteMissileCreep : Inventory
{
	override void DoEffect()
	{
		Super.DoEffect();

		if (owner.GetAge() % 3 == 0)
			owner.A_SpawnItemEx("RS_EliteFX_SmallWhiteCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);

		if (owner && owner.InStateSequence(owner.CurState, owner.FindState("Death")))
		{
			owner.A_SpawnItemEx("RS_EliteFX_WhiteCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}

		if (owner && owner.vel.x == 0 && owner.vel.y == 0)
		{
			owner.A_SpawnItemEx("RS_EliteFX_WhiteCreep", xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_TRANSFERPOINTERS);
			Destroy();
		}
	}
}

// --- C07 Cyan: the orbiting leaves -----------------------------------

class RS_EliteFX_Leaves : Actor
{
	Default
	{
		+NOINTERACTION;
		+FLOATBOB;
	}

	double orbitdist;
	double orbitheight;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (master)
		{
			orbitdist = double(frandom(master.radius, master.radius * 1.5));
			orbitheight = double(frandom(0, master.height));
		}
	}

	override void Tick()
	{
		Super.Tick();
		if (master)
		{
			A_SetAngle(angle + 12);
			A_Warp(AAPTR_MASTER, xofs: orbitdist, zofs: orbitheight,
				flags: WARPF_NOCHECKPOSITION | WARPF_USECALLERANGLE | WARPF_INTERPOLATE);
			if (master.health < 1)
				A_FadeOut();
		}
		else
		{
			A_FadeOut();
		}
	}
	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_Jump(128, "Spawn2");
	Spawn1:
		LEF1 ABCDEFGHI 1;
		loop;
	Spawn2:
		LEF2 ABCDEFGHI 1;
		loop;
	}
}

// --- C13 Grey: the lunge afterimage ----------------------------------

class RS_EliteFX_GreyShadowSpawner : Inventory
{
	const lifespan = 20;

	int age;

	Default
	{
		Inventory.MaxAmount 1;
	}

	override void DoEffect()
	{
		Super.DoEffect();

		age--;

		if (owner)
		{
			let shadow = owner.Spawn("RS_EliteFX_Shadow", owner.pos);
			if (shadow)
			{
				shadow.sprite = owner.sprite;
				shadow.frame = owner.frame;
				shadow.angle = owner.angle;
				shadow.translation = owner.translation;
				shadow.A_SetSize(owner.radius, owner.height);
			}
		}

		if (age <= 0)
			self.DepleteOrDestroy();
	}

	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		age = lifespan;
	}

	override bool HandlePickup(Inventory item)
	{
		age = lifespan;
		return Super.HandlePickup(item);
	}
}

class RS_EliteFX_Shadow : Actor
{
	Default
	{
		+NOBLOCKMAP;
		+NOGRAVITY;
		RenderStyle "Translucent";
		Alpha 0.75;
	}
	States
	{
	Spawn:
		"####" "#" 1 A_FadeOut();
		wait;
	}
}

// --- metallic sparkle (C15 / C16 / C17) ------------------------------

class RS_EliteFX_Sparkle : Actor
{
	Default
	{
		+NOINTERACTION;
		+NOGRAVITY;
		+ROLLSPRITE;
		+ROLLCENTER;
		Scale 0.25;
	}

	double dir;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		dir = randompick(-1, 1);
	}

	override void Tick()
	{
		Super.Tick();
		A_SetRoll(roll + 5 * dir, SPF_INTERPOLATE);
		A_SetScale(scale.x - (scale.x * 0.3));
		if (scale.x < 0.0001)
			Destroy();
	}
	States
	{
	Spawn:
		XXST A 1 Bright;
		wait;
	}
}

class RS_EliteFX_Sparkle2 : RS_EliteFX_Sparkle
{
	Default
	{
		Scale 1.0;
	}
}

// --- C16 Silver: the field visual ------------------------------------

class RS_EliteFX_Magnetism : Actor
{
	int zpos;

	Default
	{
		RenderStyle "Add";
		+BRIGHT;
		+NOBLOCKMAP;
		+NOGRAVITY;
		Scale 0.75;
		Alpha 0.00;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		bFLATSPRITE = CVar.FindCVar("rs_elite_flatcreep").GetBool();
		zpos = bFLATSPRITE ? 1 : int(master ? master.height * 0.5 : 0);

		if (bFLATSPRITE && master)
			SetOrigin((master.pos.x, master.pos.y, master.pos.z + zpos), true);
	}

	override void Tick()
	{
		Super.Tick();

		if (isFrozen())
			return;

		scale.x = scale.y = scale.y -= 0.01;

		if (master)
			SetOrigin((master.pos.x, master.pos.y, master.pos.z + zpos), true);

		if (scale.x <= 0 || !master || master.health < 1)
			Destroy();
	}
	States
	{
	Spawn:
		MAGN AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 1 A_FadeIn(0.04);
	FadeOut:
		MAGN A 1 A_FadeOut(0.005);
		wait;
	}
}

// --- C11 Pink: heal visuals ------------------------------------------

class RS_EliteFX_HealingCross : Actor
{
	Default
	{
		+NOINTERACTION;
		+NOGRAVITY;
		+BRIGHT;
		Scale 1.0;
		Alpha 0.0;
	}
	States
	{
	Spawn:
		CROS AAAA 1 A_FadeIn();
		CROS A 5;
		CROS AAAA 1 A_FadeOut();
		wait;
	}
}

class RS_EliteFX_HealingRing : Actor
{
	Default
	{
		+NOINTERACTION;
	}
	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			for (int i = 0; i < 12; i++)
				A_SpawnItemEx("RS_EliteFX_HealingCross", xofs: 32.0, zvel: 4.0, angle: i * 30);
		}
		stop;
	}
}

// --- C17 Gold: the conversion touch ----------------------------------

// Base aura payload: turns an ordinary monster into a gilded thrall --
// heavy, painless, tougher. Elites and prior converts are immune.
class RS_EliteFX_MidasTouch1 : CustomInventory
{
	Default
	{
		+INVENTORY.AUTOACTIVATE;
		+INVENTORY.ALWAYSPICKUP;
	}
	States
	{
	Use:
		TNT1 A 0
		{
			if (invoker.owner)
			{
				if (invoker.owner.bSPECIAL || invoker.owner.bWEAPONSPAWN)
					return;
				if (invoker.owner.CountInv("RS_EliteMidasToken") || invoker.owner.CountInv("RS_EliteToken"))
					return;

				invoker.owner.A_GiveInventory("RS_EliteMidasToken");
				invoker.owner.A_SetTranslation("rs_elite_c17");
				invoker.owner.mass *= 12;
				invoker.owner.painchance = int(invoker.owner.painchance * 0.1);
				invoker.owner.DamageFactor *= 0.66;
				invoker.owner.bNOBLOOD = true;
			}
		}
		stop;
	}
}

// Boosted touch: converts harder.
class RS_EliteFX_MidasTouch2 : CustomInventory
{
	Default
	{
		+INVENTORY.AUTOACTIVATE;
		+INVENTORY.ALWAYSPICKUP;
	}
	States
	{
	Use:
		TNT1 A 0
		{
			if (invoker.owner)
			{
				if (invoker.owner.bSPECIAL || invoker.owner.bWEAPONSPAWN)
					return;
				if (invoker.owner.CountInv("RS_EliteMidasToken") || invoker.owner.CountInv("RS_EliteToken"))
					return;

				invoker.owner.A_GiveInventory("RS_EliteMidasToken");
				invoker.owner.A_SetTranslation("rs_elite_c17");
				invoker.owner.mass *= 12;
				invoker.owner.painchance = int(invoker.owner.painchance * 0.1);
				invoker.owner.DamageFactor *= 0.33;
				invoker.owner.bNOBLOOD = true;
			}
		}
		stop;
	}
}
