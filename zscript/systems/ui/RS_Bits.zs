// =====================================================================
// RS_Bits -- universal kill-reward pickups (Health/Armor/Ammo Bits).
// Ported from "SoM Universal(ish?) Kill Rewards" (som_kr_*), renamed to
// this project's convention. Faithful port -- same modes, same ratios,
// same bit-life expiry, same Ammo Bit current-weapon/all-owned-weapons
// logic, same AmmoType1/2 toggles, same blacklist mechanism. No new
// bit types added.
// =====================================================================

// Shared bit-life countdown -- was duplicated three times (once per bit
// class) in the source; consolidated into one static helper. Each bit
// class still owns its own bit_life field, since Health/BasicArmorBonus/
// CustomInventory are three unrelated engine base classes with no shared
// ancestor to hang common state on.
// `play`: ApplyBlind reaches the player's curse ledger, which is an
// Inventory and therefore play scope. An unscoped Object is DATA scope
// and cannot call into it.
class RS_BitUtil play
{
	// -----------------------------------------------------------------
	// IS THIS ACTOR A BIT? Lives HERE, with the bits, because it is a
	// fact about bits and nothing else.
	//
	// Two unrelated systems ask: the grappling hook (which sweeps loose
	// bits toward the player on every shot) and bit-repellent (a player
	// curse that pushes them away). Neither of those owns the answer and
	// neither should have to ask the other -- an earlier version had the
	// hook calling into the curse system purely to run this test, which
	// coupled a default mechanic to an optional one for no reason.
	//
	// Named explicitly rather than testing a shared base: Health,
	// BasicArmorBonus, CustomInventory and Inventory are four unrelated
	// engine bases (see the classes below), so there IS no common
	// ancestor to test against.
	// -----------------------------------------------------------------
	static bool IsBit(Actor mo)
	{
		return mo is "RS_Bit_Health"
		    || mo is "RS_Bit_Armor"
		    || mo is "RS_Bit_Ammo"
		    || mo is "RS_Bit_Grey"
		    || mo is "RS_Bit_Gold"
		    || mo is "RS_Bit_Curse";
	}

	// -----------------------------------------------------------------
	// BLIND (OFFHAND) -- the bit is still there, you just cannot see it.
	//
	// Owner ruling 2026-08-07: "offhand blind hides bit drops - they're
	// there but you cnt see them". So this hides the SPRITE and nothing
	// else: the pickup still works, the expiry still runs, the hook still
	// sweeps it in. You can walk over a bit you cannot see and get it.
	//
	// Called from every bit's Tick alongside TickLife, which is the one
	// path all six bit classes already share -- they have four unrelated
	// engine base classes between them, so a common override is not
	// available.
	// -----------------------------------------------------------------
	static void ApplyBlind(Actor bit)
	{
		if (!bit) return;
		let mo = players[consoleplayer].mo;
		bit.bInvisible = mo && RS_CurseLedger.BitsHidden(mo);
	}

	static bool TickLife(in out int bitLife)
	{
		int ticks = CVar.GetCVar("rs_bits_life_ticks", null).GetInt();
		int mult = CVar.GetCVar("rs_bits_life_mult", null).GetInt();
		int total = ticks * mult;
		if (total <= 0)
			return false;
		bitLife++;
		return bitLife >= total;
	}
}

class RS_KillRewardsHandler : EventHandler
{
	// Plain comparison chain, not a static const array -- this engine
	// build doesn't resolve `static const string X[] = {...}` reliably.
	bool IsBlacklisted(string actor)
	{
		// Brutal Doom gib actors -- not real monsters.
		return actor == "BootSmearerRed"
			|| actor == "BootSmearerBlue"
			|| actor == "BootSmearerGreen";
	}

	override void WorldThingDied(WorldEvent e)
	{
		super.WorldThingDied(e);

		if (!CVar.GetCVar("rs_bits_enable", null).GetBool())
			return;

		Actor a = e.Thing;
		if (!a)
			return;

		if (!a.bIsMonster || IsBlacklisted(a.GetClassName()))
			return;

		// --- RS monster payout policy --------------------------------
		// This gate lives HERE, not on the monster: deciding what pays
		// out is this system's job, and a monster shouldn't know the
		// loot system exists. The systems contract only reports facts about
		// itself; the rules below are ours to change.
		//
		// Two cases must not pay out today:
		//   * summoned minions -- a summoner that respawns its pack
		//     would be an infinite bit farm, and the Pain Elemental's
		//     escort is explicitly designed to respawn forever;
		//   * transient boss stages -- a body that morphs into the next
		//     stage hasn't really died, so the payout waits for the end
		//     of the chain.
		//
		// If either should later pay REDUCED bits rather than none,
		// that change belongs in this block.
		//
		// (Note the check above gates on bIsMonster only and never
		// looked at bCOUNTKILL, which is why both cases paid out before
		// this existed.)
		// SUMMONS PAY NOTHING -- same rule and the same single source as
		// RS_Score, so the two systems cannot disagree about what a kill
		// is worth. The RS_SystemsMaster cast that stood here was dead
		// code: nothing implements that contract.
		if (!RS_SummonMarker.PaysRewards(a))
			return;

		// C01 (Dark Red) elite REMAINS never pay. Owner ruling 2026-08-07.
		//
		// C01's whole gimmick is that it returns unless you destroy the
		// corpse it leaves behind, so that corpse is +ISMONSTER +SHOOTABLE
		// with real health -- which means killing it fires WorldThingDied
		// and passes the bIsMonster gate above, paying bits a second time
		// for the same elite. Every C01 in the game was worth two payouts.
		//
		// Fixed HERE rather than on the corpse actor: RS_EliteFX.zs is
		// under the protected /monsters/-rule set and the corpse genuinely
		// does need to be a shootable monster for the mechanic to work.
		// The defect is in what the reward system counts, so that is where
		// it is corrected. RS_Score.HandleKill carries the same exclusion.
		if (a is "RS_EliteFX_Corpse")
			return;

		int bossMult = CVar.GetCVar("rs_bits_boss_mult", null).GetInt();
		int mode = CVar.GetCVar("rs_bits_mode", null).GetInt();
		int mult = a.bBoss ? bossMult : 1;

		// -------------------------------------------------------------
		// ELITES PAY PROPERLY.
		//
		// Until now only bBoss got a multiplier, so an elite zombieman
		// dropped the same 1-3 bits as an ordinary one. The elite layer
		// is the hardest content in the mod and it was paying the same
		// currency rate as its own trash -- and now that Rarity Tokens
		// make elites the gate on the whole affix system, they are the
		// thing you go out of your way to fight. The payout should say
		// so.
		//
		// REVEALED, not merely elite. Same contract the food scatter and
		// the token drop use: an elite carried from above its half-health
		// line to dead in one hit never revealed and pays the ordinary
		// rate. You are paid for the fight, not for the label.
		//
		// Multiplies WITH bBoss rather than replacing it -- a revealed
		// elite Cyberdemon is both, and should pay like both.
		// -------------------------------------------------------------
		let etok = RS_EliteToken(a.FindInventory("RS_EliteToken"));
		if (etok && etok.revealed)
			mult *= max(1, CVar.GetCVar("rs_bits_elite_mult", null).GetInt());

		int num = 0;

		switch (mode)
		{
			case 0: // Fixed Range
			{
				int rangeChance = CVar.GetCVar("rs_bits_range_chance", null).GetInt();
				if ((random(1, 100) <= rangeChance) || a.bBoss)
				{
					int minB = CVar.GetCVar("rs_bits_min", null).GetInt();
					int maxB = CVar.GetCVar("rs_bits_max", null).GetInt();
					bool randomize = CVar.GetCVar("rs_bits_randomize", null).GetBool();
					int lo = min(minB, maxB);
					int hi = max(minB, maxB);

					if (randomize)
						num = random(lo * mult, hi * mult);
					else
						num = hi * mult;
				}
				break;
			}
			case 1: // Scale by Monster Health
			{
				double ratio = CVar.GetCVar("rs_bits_healthscale_ratio", null).GetFloat();
				num = max(1, round((a.SpawnHealth() * mult) / max(1.0, ratio)));
				break;
			}
		}

		// -------------------------------------------------------------
		// GLOBAL SCALE, applied last so it lands on whichever mode ran.
		//
		// The two modes each had their own dials -- min/max for Fixed
		// Range, a health ratio for Scale by Health -- and no single
		// knob that meant "more bits, everywhere". Turning the economy up
		// or down meant retuning whichever mode you happened to be on and
		// getting a different curve out of each.
		//
		// Percent, so 100 is exactly today's behaviour and the default
		// changes nothing.
		// -------------------------------------------------------------
		int scalePct = CVar.GetCVar("rs_bits_global_scale", null).GetInt();
		if (scalePct != 100 && num > 0)
			num = max(1, num * clamp(scalePct, 0, 1000) / 100);

		int dropChance = CVar.GetCVar("rs_bits_dropchance", null).GetInt();
		int ratioHealth = CVar.GetCVar("rs_bits_ratio_health", null).GetInt();
		int ratioArmor = CVar.GetCVar("rs_bits_ratio_armor", null).GetInt();
		int ratioAmmo = CVar.GetCVar("rs_bits_ratio_ammo", null).GetInt();
		int ratioGrey = CVar.GetCVar("rs_bits_ratio_grey", null).GetInt();
		int ratioGold = CVar.GetCVar("rs_bits_ratio_gold", null).GetInt();

		for (int i = 0; i < num; i++)
		{
			// Overall per-bit chance, guaranteed on bosses.
			if (!a.bBoss && random(1, 100) > dropChance)
				continue;

			int sum = ratioHealth + ratioArmor + ratioAmmo + ratioGrey + ratioGold;
			int roll = random(1, max(1, sum));
			string spawn = "";

			if (ratioHealth && roll <= ratioHealth)
			{
				spawn = "RS_Bit_Health";
			}
			else
			{
				roll -= ratioHealth;
				if (ratioArmor && roll <= ratioArmor)
				{
					spawn = "RS_Bit_Armor";
				}
				else
				{
					roll -= ratioArmor;
					if (ratioAmmo && roll <= ratioAmmo)
					{
						spawn = "RS_Bit_Ammo";
					}
					else
					{
						roll -= ratioAmmo;
						if (ratioGrey && roll <= ratioGrey)
						{
							spawn = "RS_Bit_Grey";
						}
						else
						{
							roll -= ratioGrey;
							if (ratioGold && roll <= ratioGold)
								spawn = "RS_Bit_Gold";
						}
					}
				}
			}

			// PLAYER CURSE: `gold-drain` -- no Gold while it is on the
			// hand that fired last. Suppressed at the SPAWN rather than
			// by zeroing the weight, so the roll distribution for every
			// other bit type is untouched: a cursed player gets the same
			// number of bits, just never a gold one.
			if (spawn == "RS_Bit_Gold" && GoldDrained())
				spawn = "";

			if (spawn != "")
				a.A_SpawnItemEx(spawn, 0, 0, 32, random(1, 6), 0, random(1, 6), random(0, 360));

			// Cured gold-drain: a chance at a second one.
			if (spawn == "RS_Bit_Gold" && GoldDoubled())
				a.A_SpawnItemEx(spawn, 0, 0, 32, random(1, 6), 0, random(1, 6), random(0, 360));
		}

		// CURSE BITS -- LIVE as of 2026-08-07.
		//
		// This was `if (false && ...)` for as long as curses had nothing
		// to spend them on. Both curse pools now exist and both lift
		// through RS_Curses.zs, so the currency has a sink and the stub
		// is gone. Independent per-kill roll, outside the weighted pool
		// above and not scaled by the batch settings -- deliberately
		// rarer than the routine bits.
		int curseChance = CVar.GetCVar("rs_bits_curse_chance", null).GetInt();
		if (curseChance > 0 && random(1, 100) <= curseChance)
			a.A_SpawnItemEx("RS_Bit_Curse", 0, 0, 32, random(1, 6), 0, random(1, 6), random(0, 360));
	}

	// Is the hand that most recently fired carrying `gold-drain`?
	//
	// Reads the LAST-FIRED hand rather than testing both, because that
	// is the hand that made the kill -- the same stamp the death curse
	// uses. Single-player read of players[consoleplayer]; this whole
	// handler is already written against one local player.
	static bool GoldDrained()
	{
		let mo = players[consoleplayer].mo;
		if (!mo) return false;
		let led = RS_CurseLedger.Fetch(mo);
		if (!led) return false;
		return led.IsActive(RS_Curse.SlotOf(RS_Curse.FLAW_GOLDDRAIN, led.mLastFiredHand));
	}

	// LIFT REWARD, `gold-drain` cured: a chance for a kill to pay a
	// SECOND gold bit. The inverse of "no gold at all", and the only
	// shape available when a spawn is a yes/no rather than an amount.
	//
	// Rolled per spawned gold bit, so it composes with the weighting
	// above instead of overriding it.
	static bool GoldDoubled()
	{
		let mo = players[consoleplayer].mo;
		if (!mo) return false;
		let led = RS_CurseLedger.Fetch(mo);
		if (!led) return false;
		double b = led.LiftBonus(RS_Curse.FLAW_GOLDDRAIN, led.mLastFiredHand);
		return b > 0 && frandom(0, 1) < b;
	}
}

class RS_Bit_Ammo : CustomInventory
{
	Default
	{
		Radius 10;
		Height 8;
		Inventory.MaxAmount 0;
		Inventory.PickupMessage "";
		+INVENTORY.AUTOACTIVATE;
		+INVENTORY.ALWAYSPICKUP;
	}

	int bit_life;

	override void Tick()
	{
		Super.Tick();
		RS_BitUtil.ApplyBlind(self);
		if (RS_BitUtil.TickLife(bit_life))
			Destroy();
	}

	action void RS_GiveAmmoBit()
	{
		PlayerInfo player = players[consoleplayer];
		PlayerPawn mo = player.mo;
		Class<Actor> ammoCls;
		Array<Class<Actor> > ammos;
		Class<Actor> a1, a2;

		int ammoMode = CVar.GetCVar("rs_bits_ammo_mode", null).GetInt();
		bool useType1 = CVar.GetCVar("rs_bits_ammo_usetype1", null).GetBool();
		bool useType2 = CVar.GetCVar("rs_bits_ammo_usetype2", null).GetBool();

		switch (ammoMode)
		{
			case 0: // Current Weapon
				if (player.readyweapon)
				{
					a1 = player.readyweapon.ammotype1;
					a2 = player.readyweapon.ammotype2;
					if (useType1 && a1) ammos.Push(a1);
					if (useType2 && a2) ammos.Push(a2);
				}
				break;
			case 1: // All Owned Weapons
				for (Inventory item = mo.inv; item != null; item = item.inv)
				{
					let wep = Weapon(item);
					if (wep)
					{
						a1 = wep.ammotype1;
						a2 = wep.ammotype2;
						if (useType1 && a1) ammos.Push(a1);
						if (useType2 && a2) ammos.Push(a2);
					}
				}
				break;
		}

		if (ammos.Size())
		{
			ammoCls = ammos[random(0, ammos.Size() - 1)];
			if (ammoCls)
				mo.GiveInventory(ammoCls.GetClassName(), 5);
		}
	}

	States
	{
	Spawn:
		MBIT A 4;
		MBIT A 4 BRIGHT;
		Loop;
	Pickup:
		TNT1 A 0 RS_GiveAmmoBit();
		Stop;
	}
}

class RS_Bit_Health : Health
{
	Default
	{
		Radius 10;
		Height 8;
		Inventory.Amount 25;
		Inventory.PickupMessage "";
	}

	int bit_life;

	override void Tick()
	{
		Super.Tick();
		RS_BitUtil.ApplyBlind(self);
		if (RS_BitUtil.TickLife(bit_life))
			Destroy();
	}

	States
	{
	Spawn:
		HBIT A 4;
		HBIT A 4 BRIGHT;
		Loop;
	}
}

class RS_Bit_Armor : BasicArmorBonus
{
	Default
	{
		Radius 10;
		Height 8;
		Inventory.PickupMessage "";
		Armor.SavePercent 33.335;
		Armor.SaveAmount 10;
		Armor.MaxSaveAmount 250;
	}

	int bit_life;

	override void Tick()
	{
		Super.Tick();
		RS_BitUtil.ApplyBlind(self);
		if (RS_BitUtil.TickLife(bit_life))
			Destroy();
	}

	States
	{
	Spawn:
		ABIT A 4;
		ABIT A 4 BRIGHT;
		Loop;
	}
}

// Repair currency. AUTOMATIC, NOT SPENT AT A VENDOR.
//
// Owner ruling 2026-08-07: "every 10 repair bits collected raises current
// equipped wpn by 1 ... i don't want a menu where people spend them, that
// seems wild." So there is no shop, no spend UI, no prompt: you pick
// these up, and every tenth one quietly repairs what you are holding.
//
// This also closes a real dead end. RS_Weapon.RepairWithGreyBits() had
// ZERO callers -- degradation ran all run (damage hits, hazard floors)
// and nothing in the game could ever undo it, so weapons only ever
// walked one direction, toward the backfire basement, while Grey Bits
// piled up against a vendor that was never built.
//
// BOTH HANDS. Repair applies to the mainhand and the offhand together --
// they wear down independently and separately, so repairing only the
// "current" one would leave the offhand permanently rotting on a
// dual-wield mod.
//
// Reuses the Health Bit's gem sprite, recolored via STYLE_Shaded +
// SetShade instead of new art -- the same color-variant trick this
// project uses for monster tiers, without a TRNSLATE lump.
class RS_Bit_Grey : Inventory
{
	// How many pickups buy one point of Condition. NOT a second copy of
	// the number -- RS_Roll already owns it as GREY_BITS_PER_CND_POINT
	// (and it already read 10, exactly matching the ruling), so this
	// tracks it and the two can never drift.
	const REPAIR_PER_POINT = RS_Roll.GREY_BITS_PER_CND_POINT;

	Default
	{
		Radius 10;
		Height 8;
		Inventory.Amount 1;
		Inventory.MaxAmount 999;
		Inventory.PickupMessage "";
		+INVENTORY.ALWAYSPICKUP;
	}

	int bit_life;

	// Counts pickups toward the next repair. Lives on the ITEM class as a
	// static-style counter carried by the owner's stack instead: see
	// AttachToOwner below, which does the work at the moment of pickup
	// rather than polling.
	override bool HandlePickup(Inventory item)
	{
		bool handled = Super.HandlePickup(item);
		if (item.GetClass() == "RS_Bit_Grey")
			TryRepair();
		return handled;
	}

	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		TryRepair();
	}

	// Every REPAIR_PER_POINT bits held, convert ten of them into one
	// point of Condition on both equipped weapons.
	//
	// Consuming the ten (rather than checking Amount % 10) keeps this
	// honest across save/load and means the counter can never drift out
	// of step with what the player actually collected.
	private void TryRepair()
	{
		if (!owner || !owner.player)
			return;

		while (Amount >= REPAIR_PER_POINT)
		{
			Amount -= REPAIR_PER_POINT;

			// RepairWithGreyBits takes BITS, not points -- it divides by
			// GREY_BITS_PER_CND_POINT internally. Handing it the ten we
			// just consumed yields exactly +1 Condition.
			bool any = false;
			let main = RS_Weapon(owner.player.ReadyWeapon);
			if (main) { main.RepairWithGreyBits(REPAIR_PER_POINT); any = true; }

			let off = RS_Weapon(owner.player.OffhandWeapon);
			if (off && off != main) { off.RepairWithGreyBits(REPAIR_PER_POINT); any = true; }

			if (any)
			{
				owner.A_StartSound("rs_bit_repair", CHAN_AUTO,
					CHANF_DEFAULT, 0.6);
			}
		}
	}

	override void Tick()
	{
		Super.Tick();
		RS_BitUtil.ApplyBlind(self);
		if (RS_BitUtil.TickLife(bit_life))
			Destroy();
	}

	States
	{
	Spawn:
		TNT1 A 0 A_SetRenderStyle(1.0, STYLE_Shaded);
		TNT1 A 0 SetShade("C0 C0 C8");
		HBIT A 4;
		HBIT A 4 BRIGHT;
		Loop;
	}
}

// Gold Bit -- rs_00's currency, finally real. Same stacking pattern as
// Grey; joins the weighted kill-reward pool via rs_bits_ratio_gold.
// First real spend: card-picker rerolls (RS_UIHandler). The big-ticket
// sink (SetPieces) stays a deferred future project on purpose.
class RS_Bit_Gold : Inventory
{
	Default
	{
		Radius 10;
		Height 8;
		Inventory.Amount 1;
		Inventory.MaxAmount 9999;
		Inventory.PickupMessage "";
		+INVENTORY.ALWAYSPICKUP;
	}

	int bit_life;

	override void Tick()
	{
		Super.Tick();
		RS_BitUtil.ApplyBlind(self);
		if (RS_BitUtil.TickLife(bit_life))
			Destroy();
	}

	States
	{
	Spawn:
		TNT1 A 0 A_SetRenderStyle(1.0, STYLE_Shaded);
		TNT1 A 0 SetShade("F8 D0 40");
		HBIT A 4;
		HBIT A 4 BRIGHT;
		Loop;
	}
}

// Curse-removal currency -- accumulates in inventory, spent later on a
// chosen weapon's chosen curse (menu work, not built yet). Deliberately
// rarer than the routine bits above -- see rs_bits_curse_chance in
// RS_KillRewardsHandler, an independent per-kill roll outside the
// weighted pool, not scaled by the batch-size settings the others use.
// Same recolor trick as RS_Bit_Grey, rust red instead of silver.
class RS_Bit_Curse : Inventory
{
	Default
	{
		Radius 10;
		Height 8;
		Inventory.Amount 1;
		Inventory.MaxAmount 999;
		Inventory.PickupMessage "";
		+INVENTORY.ALWAYSPICKUP;
	}

	int bit_life;

	override void Tick()
	{
		Super.Tick();
		RS_BitUtil.ApplyBlind(self);
		if (RS_BitUtil.TickLife(bit_life))
			Destroy();
	}

	States
	{
	Spawn:
		TNT1 A 0 A_SetRenderStyle(1.0, STYLE_Shaded);
		TNT1 A 0 SetShade("B7 41 0E");
		HBIT A 4;
		HBIT A 4 BRIGHT;
		Loop;
	}
}
