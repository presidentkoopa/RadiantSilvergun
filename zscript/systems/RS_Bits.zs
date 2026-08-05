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
class RS_BitUtil
{
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
		let rsmon = RS_SystemsMaster(a);
		if (rsmon && (rsmon.IsSummonedMinion() || rsmon.IsTransientStage()))
			return;

		int bossMult = CVar.GetCVar("rs_bits_boss_mult", null).GetInt();
		int mode = CVar.GetCVar("rs_bits_mode", null).GetInt();
		int mult = a.bBoss ? bossMult : 1;
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

			if (spawn != "")
				a.A_SpawnItemEx(spawn, 0, 0, 32, random(1, 6), 0, random(1, 6), random(0, 360));
		}

		// Curse Bits: STUBBED OFF along with curse-rolling on Promote() --
		// no point dropping currency with nothing to spend it on yet.
		// `false &&` short-circuits the roll below without touching the
		// cvar or the drop-chance math, so re-enabling is a one-word flip.
		int curseChance = CVar.GetCVar("rs_bits_curse_chance", null).GetInt();
		if (false && curseChance > 0 && random(1, 100) <= curseChance)
			a.A_SpawnItemEx("RS_Bit_Curse", 0, 0, 32, random(1, 6), 0, random(1, 6), random(0, 360));
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

// Repair currency -- accumulates in inventory like ammo, spent later via
// RS_Weapon.RepairWithGreyBits() (the spend UI itself isn't built yet).
// Deliberately NOT an instant-effect bit like Health/Armor/Ammo above --
// no auto-activate, just stacks. Reuses the Health Bit's gem sprite,
// recolored via STYLE_Shaded + SetShade instead of new art -- same
// color-variant trick this project already uses elsewhere (monster
// tiers), just without a TRNSLATE lump.
class RS_Bit_Grey : Inventory
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
