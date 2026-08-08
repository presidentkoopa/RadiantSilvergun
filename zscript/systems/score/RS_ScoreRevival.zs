// =====================================================================
// RS_ScoreRevival -- the death save and the fire cone.
//
// WHAT THIS FILE IS
//   The PAYLOAD half of the extra-life system: the thing that happens
//   at the instant a banked life is spent. The ECONOMY half -- how a
//   life is earned, kept across a level, reported to the HUD -- lives
//   next door in RS_ScoreLives.zs.
//
// THE MECHANISM CHANGED, 2026-08-07, AT THE OWNER'S ORDER.
//   The old system kept CF_BUDDHA on the player so lethal damage
//   floored at 1hp, then watched for health <= 1 and called that a
//   death. Two bugs, both confirmed:
//
//     1. A life was spent for ANY arrival at 1hp. A hit that
//        legitimately left you alive on your last point of health --
//        the most dramatic survival in the game -- was billed as a
//        death and cost you a life.
//     2. At zero lives it ran `pi.cheats &= ~CF_BUDDHA` EVERY TIC,
//        which silently cancelled the player's own `buddha` console
//        cheat, and any other mod's grant of it, forever.
//
//   Both are gone because the mechanism is gone. RS_LifeForce is an
//   inventory item that overrides AbsorbDamage, which the engine calls
//   at p_interaction.cpp:1350 -- AFTER armour and powerups have had
//   their say and BEFORE `player->health -= damage` on line 1374. It
//   is handed the real, final number, and it can rewrite it. So the
//   test is exactly the right one:
//
//        damage >= owner.health   ->  this hit WOULD have killed you
//
//   A hit that leaves you at 1hp has damage == health-1 and does not
//   match. Nothing reads the cheat flags except to LOOK at them, and
//   nothing ever writes them.
//
// WHY THE ITEM MOVES TO THE TAIL OF THE INVENTORY CHAIN
//   AActor::AbsorbDamage (p_mobj.cpp:3523) walks the chain in order,
//   threading `damage` through by reference, so each item sees what the
//   ones before it left behind. Armour is normally inserted ahead of
//   us. Sitting at the tail is what guarantees we are looking at the
//   damage that is actually about to land, not the pre-armour figure.
//   (Technique taken from the Indestructable reference mod, which
//   documents the same reasoning; verified against the engine here.)
//
// WHAT STILL GETS THROUGH, HONESTLY STATED
//   AbsorbDamage is skipped for DMG_FORCED and DMG_NO_ARMOR, and on
//   telefrag damage the engine discards our rewrite (line 1352). Those
//   kills are not saveable by any mod using this hook. They are rare.
//
// THE FIRE CONE IS UNCHANGED AND IS NOT TO BE LOST.
//   Eight flame streams thrown outward and eight more raked along the
//   floor, from an emitter that spins 2.5 degrees per tic for ~70 tics.
//   Every dimension of it is still a cvar. The owner likes this; it
//   survives every rewrite.
//
// SPRITES: uses RSI1/RSI2 (sprites/combatfx/fire/), the same flame
// sheets RS_FireLoop already draws from -- verified present on disk, 13
// and 10 frames respectively. No new art dependency.
// =====================================================================


// ---------------------------------------------------------------------
// THE FORCE -- the invisible inventory item that catches lethal damage.
//
// Named "force" after the pattern it is built on: an item whose only
// job is to give a player an actor-local damage hook, because there is
// no other place to stand between "the engine computed the damage" and
// "the engine applied it".
// ---------------------------------------------------------------------
class RS_LifeForce : Inventory
{
	// The player's life ledger. Owned by RS_LivesHandler, pointed at
	// from here so the damage hook can reach it without a lookup on
	// every hit.
	RS_LifeInfo info;

	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		+INVENTORY.IGNORESKILL
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNDROPPABLE
		+INVENTORY.QUIET
	}

	// -----------------------------------------------------------------
	// cvar readers. Local copies rather than reaching into the handler,
	// so the damage hook never depends on the handler being findable.
	// -----------------------------------------------------------------
	static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	void Initialize(RS_LifeInfo newInfo)
	{
		info = newInfo;
		info.force = self;
		MoveToTail();
		info.Report();
	}

	// Move to the end of the owner's inventory chain, so AbsorbDamage
	// sees the post-armour figure. Items are always inserted at the
	// head and the player's starting kit usually includes armour, so on
	// first grant there is a good chance something is behind us. Once
	// we are at the tail we stay there -- new items go in at the head.
	void MoveToTail()
	{
		if (self.inv == null)
			return;

		Actor head, tail;
		Actor item = owner;

		while (item)
		{
			if (item.inv == self) head = item;
			if (item.inv == null) tail = item;
			item = item.inv;
		}

		if (!head || !tail || tail == self)
			return;

		head.inv = self.inv;
		tail.inv = self;
		self.inv = null;
	}

	// READ ONLY. The player's cheat flags are the player's. The old
	// system wrote to these and that was the second confirmed bug --
	// it quietly cancelled a `buddha` the player had typed themselves.
	// We look, so that we do not spend a life saving someone who was
	// never in danger, and we never touch.
	static bool IsUndying(PlayerInfo p)
	{
		if (!p)
			return false;
		return (p.cheats & (CF_BUDDHA | CF_BUDDHA2 | CF_GODMODE | CF_GODMODE2)) != 0;
	}

	// -----------------------------------------------------------------
	// THE HOOK.
	// -----------------------------------------------------------------
	override void AbsorbDamage(int damage, Name damageType, out int newdamage,
		Actor inflictor, Actor source, int flags)
	{
		if (!info || !owner || !owner.player)
			return;

		if (!CVBool("rs_lives_enable", true))
			return;

		// Already immortal by their own hand or another mod's grant.
		// Not our business, and spending a life here would be theft.
		if (IsUndying(owner.player))
			return;

		// SURVIVABLE HIT. This is the whole fix for bug 1: arriving at
		// 1hp is not dying, so it does not cost a life. It pays INTO
		// the ledger instead -- damage taken is one of the two ways a
		// life is earned.
		if (damage < owner.health)
		{
			info.AddDamageTaken(damage);
			return;
		}

		// LETHAL. Nothing banked -- let it land. We do not intervene,
		// we do not set a flag, we do not touch the player.
		if (info.lives <= 0)
			return;

		// Leave them on one point of health. The engine's own
		// `player->health -= damage` on the next line then lands on 1
		// rather than 0, so nothing downstream ever sees a dead player
		// and no resurrection is needed -- which is what keeps the
		// weapon state, the view height and the VR hand poses intact.
		newdamage = owner.health - 1;

		// Read BEFORE the adjustment: this tells us whether the life we
		// are about to spend is the LAST one.
		bool wasLastLife = (info.lives <= 1);

		info.AdjustLives(-1, false, RS_LifeInfo.SRC_SPENT);
		FireSave(source);

		// THE DEATH TAX. Added 2026-08-07 with the curse rework.
		//
		// Two severities on one trigger, deliberately split:
		//   * EVERY save costs Condition -- the "that hurt" tax, and the
		//     same shape as the existing rule where any hit over 20 raw
		//     damage already costs 3 Condition on both hands.
		//   * The LAST-LIFE save costs a CURSE -- the "you're out" tax.
		//
		// Owner ruling 2026-08-07: promotion is where stat-locks come
		// from, death is where player curses come from.
		ApplyDeathCondition();
		RollDeathCurse(wasLastLife);
	}

	// -----------------------------------------------------------------
	// Condition loss on every save, both hands.
	//
	// BOTH HANDS because the hit landed on the PLAYER, not on a gun --
	// the same reasoning the existing per-hit degrade uses, and the same
	// reasoning behind repairing both hands together in RS_Bit_Grey.
	// -----------------------------------------------------------------
	void ApplyDeathCondition()
	{
		if (!owner || !owner.player) return;

		int loss = RS_Curse.CVInt("rs_curse_death_condition", 10);
		if (loss <= 0) return;

		let main = RS_Weapon(owner.player.ReadyWeapon);
		if (main) main.Condition = max(0.0, main.Condition - loss);

		let off = RS_Weapon(owner.player.OffhandWeapon);
		if (off && off != main) off.Condition = max(0.0, off.Condition - loss);
	}

	// -----------------------------------------------------------------
	// The player curse roll.
	//
	// Lands on whichever hand fired most recently -- owner, 2026-08-07:
	// "i dunno whatever gun ytou firted last". RS_Weapon's fire dispatch
	// stamps that on the ledger.
	//
	// Guaranteed by default on the last-life save (chance 100) and off
	// entirely on earlier ones, because that moment should read as "you
	// are out, and it cost you" rather than one more dice roll. Both are
	// cvars.
	// -----------------------------------------------------------------
	void RollDeathCurse(bool wasLastLife)
	{
		if (!owner) return;

		int chance = wasLastLife
			? RS_Curse.CVInt("rs_curse_death_chance", 100)
			: RS_Curse.CVInt("rs_curse_death_chance_early", 0);

		if (chance <= 0 || random(1, 100) > chance)
			return;

		let led = RS_CurseLedger.Fetch(owner);
		if (!led) return;

		int slot = led.RollCurse(led.mLastFiredHand);
		if (slot < 0)
			return;

		Console.Printf("\c[Red]CURSED:\c- %s -- %s",
			RS_Curse.SlotName(slot),
			RS_Curse.FlawBlurb(RS_Curse.FlawOfSlot(slot), RS_Curse.HandOfSlot(slot)));
	}

	// -----------------------------------------------------------------
	// The save, part one: everything that must happen THIS tic.
	// -----------------------------------------------------------------
	void FireSave(Actor killer)
	{
		// Invulnerability first and immediately. Powerup::CreateCopy
		// calls InitEffect() during the grant (powerups.zs:161) and
		// PowerInvulnerable::InitEffect sets Owner.bInvulnerable
		// (powerups.zs:335), so the flag is live before this function
		// returns. That matters: the engine tests invulnerability at
		// p_interaction.cpp:1337, BEFORE AbsorbDamage, so a second
		// lethal hit in this same tic is now bounced before it can
		// reach us and bill a second life.
		int invuln = clamp(CVInt("rs_score_revive_invuln", 70), 0, 35 * 60);
		if (invuln > 0)
			GrantPower("RS_SavePowerInvuln", invuln);

		if (CVBool("rs_score_revive_dmgbonus", true) && invuln > 0)
			GrantPower("RS_SavePowerDamage", invuln);

		if (CVBool("rs_score_revive_flash", true))
			owner.A_SetBlend("FF 7F 00", 0.75, 40);

		if (CVBool("rs_score_revive_sound", true))
			owner.A_StartSound("misc/i_pkup", CHAN_ITEM, CHANF_DEFAULT, 1.0, ATTN_NONE);

		RS_BulletTimeHook.Trigger();

		// Part two runs a tic later. See the state block for why.
		SetStateLabel("Saved");
	}

	// max(), never assignment: an invulnerability the player already
	// had from a pickup is longer than ours and must not be shortened
	// by being saved.
	void GrantPower(class<Powerup> type, int tics)
	{
		let p = Powerup(owner.FindInventory(type));
		if (p)
		{
			p.EffectTics = max(p.EffectTics, tics);
			return;
		}

		p = Powerup(owner.GiveInventoryType(type));
		if (p)
			p.EffectTics = tics;
	}

	// -----------------------------------------------------------------
	// The save, part two: one tic later.
	//
	// TWO SEPARATE REASONS THIS IS DELAYED, BOTH REAL:
	//
	//   1. HEALTH. We are still inside DamageMobj when FireSave runs;
	//      the engine has not subtracted the damage yet. Healing now
	//      would just be overwritten by the subtraction on the very
	//      next line. Waiting one tic means we set the final number.
	//
	//   2. THE CONE. RS_ReviveExplosion opens with A_Explode. Spawning
	//      it from inside AbsorbDamage would run a damage pass from
	//      inside a damage pass, re-entering DamageMobj on every actor
	//      in the blast. One tic of separation costs nothing visible
	//      and removes the whole class of problem.
	// -----------------------------------------------------------------
	void CompleteSave()
	{
		if (!owner)
			return;

		int heal = clamp(CVInt("rs_score_revive_health", 100), 1, 2000);
		if (owner.health < heal)
			owner.GiveInventory("Health", heal - owner.health);

		if (CVBool("rs_score_revive_cone", true))
		{
			// target = the player, and it is load-bearing: the cone's
			// A_Explode calls all pass flags 0, which leaves
			// XF_HURTSOURCE clear, so the source is spared. Drop this
			// assignment and the cone kills the person it just saved.
			Actor cone = Actor.Spawn("RS_ReviveExplosion", owner.pos + (0, 0, 32), ALLOW_REPLACE);
			if (cone)
			{
				cone.target = owner;
				cone.angle = owner.angle;
			}
		}

		if (info)
			info.OnSaved();
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;

	Saved:
		// A full tic of nothing, deliberately. See CompleteSave().
		TNT1 A 1;
		TNT1 A 0 { CompleteSave(); }
		Goto Spawn;
	}
}


// ---------------------------------------------------------------------
// The save's powerups. Subclassed rather than reused so that a save
// never extends, shortens or is confused with a pickup the player
// found -- and so a HUD can tell the two apart.
// ---------------------------------------------------------------------
class RS_SavePowerInvuln : PowerInvulnerable
{
	Default
	{
		Powerup.Duration -3;
	}
}

class RS_SavePowerDamage : Powerup
{
	Default
	{
		Powerup.Duration -3;
		+INVENTORY.NOSCREENBLINK
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage,
		bool passive, Actor inflictor, Actor source, int flags)
	{
		// passive is damage coming IN. We only touch what goes out.
		if (passive)
			return;

		let c = CVar.GetCVar("rs_score_revive_dmgmult", null);
		double mult = c ? c.GetFloat() : 2.0;
		newdamage = int(damage * clamp(mult, 1.0, 16.0));
	}
}


// ---------------------------------------------------------------------
// BULLET TIME X HOOK -- optional, sideload-safe, does nothing when that
// mod is absent.
//
// WE DO NOT BUNDLE BULLET TIME X AND WE DO NOT DEPEND ON IT.
//
// Its public trigger surface is a netevent. Its KEYCONF binds
//     alias bullettime "netevent bt_activate"
// and its handler answers `e.Name == "bt_activate"` in NetworkProcess
// (zscripts/handlers/BulletTime.zs:80). That is the entire contract,
// and a netevent is the one integration point that cannot fail when
// the other side is missing.
//
// WHY THE SEND IS SAFE ON ITS OWN, verified in the engine source:
//   EventManager::SendNetworkEvent (events.cpp:382) checks gamestate
//   and then writes DEM_NETEVENT to the network stream. It performs NO
//   lookup of any handler and cannot fail on a name nobody answers. On
//   receipt (d_net.cpp:2775) the event is handed to
//   localEventManager->Console(), which walks the registered handlers
//   and calls NetworkProcess on each. With Bullet Time X absent there
//   is no handler that matches the name, so the event is simply
//   dropped -- no error, no warning, no console line.
//
// WHY WE STILL GATE IT:
//   Firing an event nobody answers on every death save is noise on a
//   demo and in a netgame packet. The gate is a cvar presence test,
//   which is exact: CVar.GetCVar returns nullptr for a cvar belonging
//   to a mod that is not loaded -- see c_cvars.cpp:1455, whose own
//   comment reads "Either the cvar doesn't exist, or it's for a mod
//   that isn't loaded, so return nullptr." bt_multiplier is declared
//   in that mod's CVARINFO and nowhere else.
//
// WHAT WE DELIBERATELY DO NOT DO:
//   We never name one of its classes. A CONSTANT string cast to a
//   class type is resolved at COMPILE time, and an unknown name there
//   is a hard error that stops the mod building
//   (codegen.cpp:12337-12349, MSG_OPTERROR then `return nullptr` for
//   non-DECORATE). So the only safe way to touch a foreign class is a
//   non-constant string through BuiltinNameToClass, which returns null
//   silently -- and we do not need to, because the netevent is enough.
//   Nothing in this file mentions a Bullet Time X class name.
// ---------------------------------------------------------------------
class RS_BulletTimeHook
{
	// Declared in Bullet Time X's CVARINFO and nowhere else. Its
	// presence is a load test for that mod, and its absence is a
	// nullptr from the engine rather than an error.
	const PROBE_CVAR = "bt_multiplier";

	clearscope static bool Present()
	{
		return CVar.GetCVar(PROBE_CVAR, null) != null;
	}

	static void Trigger()
	{
		let c = CVar.GetCVar("rs_score_revive_bullettime", null);
		if (c && !c.GetBool())
			return;

		if (!Present())
			return;

		// Its own adrenaline economy still governs whether the slow-mo
		// actually starts. That is its business, not ours -- we ask,
		// we do not reach into its inventory.
		EventHandler.SendNetworkEvent("bt_activate");
	}
}


// ---------------------------------------------------------------------
// The emitter. Spawned on the reviving player, spins, throws flame.
// ---------------------------------------------------------------------
class RS_ReviveExplosion : Actor
{
	// NOTE ON `invoker`: these are Actor states, not Weapon/Inventory
	// states, so the state code already runs on this actor -- member
	// fields are reached directly. `invoker` is only meaningful where an
	// item's states execute on its owner, and using it here does not
	// compile.
	int fireStep;
	int maxSteps;

	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+FORCERADIUSDMG
		+NODAMAGETHRUST
		Radius 4;
		Height 4;
		Obituary "%o was caught in %k's revival.";
	}

	static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	// One rotation step: eight airborne streams + eight ground rakes.
	// A loop, not sixteen hand-written A_SpawnItemEx lines -- which is
	// what makes rs_score_revive_arms a real knob rather than a comment.
	void SpawnRing()
	{
		int arms = clamp(CVInt("rs_score_revive_arms", 8), 1, 32);
		double step = 360.0 / arms;
		double dist = 80.0;

		for (int i = 0; i < arms; i++)
		{
			double ang = i * step;

			A_SpawnItemEx("RS_RevivalFlame",
				dist, 0, -32,
				frandom(-0.5, 0.5), frandom(-0.5, 0.5), 2.5,
				ang, SXF_TRANSFERPOINTERS);

			A_SpawnItemEx("RS_RevivalFlameGround",
				dist, 0, -32,
				frandom(-0.2, 0.2), frandom(0.8, 1.2), 0,
				ang, SXF_TRANSFERPOINTERS);
		}
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			maxSteps = clamp(CVInt("rs_score_revive_tics", 70), 5, 210);

			if (CVBool("rs_score_revive_sound", true))
			{
				A_StartSound("weapons/rocklx", CHAN_BODY, CHANF_DEFAULT, 1.0, ATTN_NONE);
			}

			// The opening thump. 384 damage at radius 256 is a genuine
			// room-clearer, which is the point of spending a life.
			// Tunable, and settable to 0 for a cosmetic-only cone.
			int dmg = clamp(CVInt("rs_score_revive_blast", 384), 0, 2000);
			int rad = clamp(CVInt("rs_score_revive_blastradius", 256), 16, 1024);
			if (dmg > 0)
				A_Explode(dmg, rad, 0);
		}
		goto Burn;

	Burn:
		TNT1 A 1
		{
			SpawnRing();
			A_SetAngle(angle + 2.5);
			fireStep++;
		}
		TNT1 A 0 A_JumpIf(fireStep > maxSteps, "Finish");
		loop;

	Finish:
		// A final dense burst so the cone ends on a punch rather than
		// just stopping.
		TNT1 AAAA 0 { SpawnRing(); }
		TNT1 A 8;
		Stop;
	}
}


// ---------------------------------------------------------------------
// The outward flame stream. Damages, pierces, ignores invulnerability --
// the cone is bought with a life, so it is not politely stopped by armour
// or an invulnerability sphere on the thing that just killed you.
// ---------------------------------------------------------------------
class RS_RevivalFlame : Actor
{
	int burnLeft;

	Default
	{
		Radius 2;
		Height 2;
		Speed 25;
		Projectile;
		+MTHRUSPECIES
		+THRUACTORS
		+BLOODLESSIMPACT
		+NODAMAGETHRUST
		+FORCERADIUSDMG
		+FOILINVUL
		+PIERCEARMOR
		+DONTSPLASH
		RenderStyle "Add";
		Scale 0.35;
		Alpha 0.6;
		Obituary "%o basked in %k's revival.";
	}

	States
	{
	Spawn:
		RSI1 A 0 Bright NoDelay
		{
			A_ScaleVelocity(frandom(0.9, 1.1));
			burnLeft = 24;
			// Most of these pass through the world; a minority collide,
			// which keeps the cone from being stopped by the first wall.
			bPAINLESS = (random(0, 6) > 0);
		}
		goto Burn;

	Burn:
		RSI1 A 1 Bright
		{
			A_SpawnItemEx("RS_RevivalFlameVisual", 0, 0, 0, 0, 0,
				frandom(0.0, 2.0), 0, SXF_ABSOLUTEPOSITION);
			A_Explode(1, 64, 0, 0, 32);
			burnLeft--;
		}
		RSI1 A 0 A_JumpIf(burnLeft > 0, "Burn");
		Stop;

	Death:
		TNT1 A 0 A_JumpIf(burnLeft <= 0, "Gone");
		TNT1 A 1
		{
			A_SpawnItemEx("RS_RevivalFlameVisual", 0, 0, 0, 0, 0,
				frandom(0.0, 2.0), 0, SXF_ABSOLUTEPOSITION);
			A_Explode(1, 64, 0, 0, 32);
			burnLeft -= 3;
		}
		loop;

	Gone:
		TNT1 A 1;
		Stop;
	}
}


// ---------------------------------------------------------------------
// The floor rake -- pure visual, hugs the ground, no collision.
// ---------------------------------------------------------------------
class RS_RevivalFlameGround : Actor
{
	int burnLeft;

	Default
	{
		Radius 2;
		Height 2;
		+NOINTERACTION
		+DONTSPLASH
		RenderStyle "Add";
		Scale 0.3;
		Alpha 0.5;
	}

	States
	{
	Spawn:
		RSI2 A 0 Bright NoDelay { burnLeft = 12; }
		goto Burn;

	Burn:
		RSI2 A 1 Bright
		{
			A_SpawnItemEx("RS_RevivalFlameVisual", 0, 0, 0, 0, 0,
				frandom(0.0, 2.0), 0, SXF_ABSOLUTEPOSITION);
			burnLeft--;
		}
		RSI2 A 0 A_JumpIf(burnLeft > 0, "Burn");
		Stop;
	}
}


// ---------------------------------------------------------------------
// Client-side sparkle left behind by the streams. Purely decorative,
// so it is CLIENTSIDEONLY and cheap.
// ---------------------------------------------------------------------
class RS_RevivalFlameVisual : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		+NOINTERACTION
		+CLIENTSIDEONLY
		+DONTSPLASH
		RenderStyle "Add";
		Scale 0.22;
		Alpha 0.4;
	}

	States
	{
	Spawn:
		RSI1 A 0 Bright NoDelay
		{
			// Drift, so the trail has volume instead of being a line of
			// identical puffs.
			Vel3DFromAngle(frandom(0.0, 1.0), frandom(0, 360), frandom(-20, 20));
		}
		RSI1 "ABCDE" 2 Bright;
		Stop;
	}
}
