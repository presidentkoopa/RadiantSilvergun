// =====================================================================
// RS_VP_Weapon -- shared base for the "Vanilla+" weapon set (GNRCWPN).
// ---------------------------------------------------------------------
// Genuinely an RS_Weapon underneath -- full RollStats/Condition/tier
// capability is never removed, just not exercised through the normal
// elite-drop/tier loop (Vanilla+ grants these at a fixed configuration
// instead). If these ever join the main loot pool, nothing needs
// rebuilding: flip the purist cvar and the rolls are already there.
//
// Deliberate consolidation vs the main arsenal: A_RS_MagLoad and
// A_RS_Backfire are byte-identical in all ten main weapon files. Here
// they live once, on the base. Same for the reserve-ammo name, which the
// magazine reload needs and previously had to be hardcoded per weapon.
// =====================================================================
class RS_VP_Weapon : RS_Weapon abstract
{
	// Purist mode (default ON): Vanilla+ weapons use exact, deterministic
	// classic-Doom stats instead of rolled ranges. Each weapon's own
	// RollStats branches on this.
	bool Purist()
	{
		let cv = CVar.GetCVar("rs_vanillaplus_purist", null);
		return cv ? cv.GetBool() : true;
	}

	// Shared magazine reload -- pulls from AmmoType1 (the reserve /
	// world-pickup ammo) into the weapon's own chambered AmmoType2, up to
	// Capacity. Reading AmmoType1 directly is why no weapon here needs
	// its own copy of this function, unlike the main arsenal where the
	// reserve class name is hardcoded ten separate times.
	action void A_RS_VP_MagLoad()
	{
		Class<Ammo> reserve = invoker.AmmoType1;
		if (!reserve)
			return;

		int needed = invoker.Capacity - CountInv(invoker.AmmoType2);
		int available = CountInv(reserve);
		int toLoad = min(needed, available);
		if (toLoad > 0)
		{
			int clipCost = max(1, toLoad - invoker.GetReloadBonusRounds());
			clipCost = min(clipCost, available);
			TakeInventory(reserve, clipCost);
			GiveInventory(invoker.AmmoType2, toLoad);
		}
	}

	// Spent-magazine drop, Hi-Fi tier only (RS_HiFiFX gates it). Called
	// from each weapon's Reload state so the old mag physically falls
	// away as the new one goes in.
	action void A_RS_VP_DropMag()
	{
		RS_HiFiFX.MagDrop(self, "RS_MagDrop");
	}

	action void A_RS_VP_Backfire()
	{
		A_PlaySound("AKEMPT", CHAN_WEAPON);
		double dmg = invoker.DamagePerShot;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;
		player.mo.DamageMobj(invoker, player.mo, int(dmg), 'BackfireDamage');
	}

	// Shared hitscan-replacement fire path. Every bullet-firing Vanilla+
	// weapon routes through this: real traveling projectiles via the
	// existing ProjectileClass system, never A_FireBullets.
	action void A_RS_VP_Fire(String fireSound, bool heavyFire = false, String casingClass = "")
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_VP_Backfire();
			TakeInventory(invoker.AmmoType2, 1);
			A_RS_MarkFired();
			return;
		}

		double dmg = invoker.DamagePerShot * dmgMult;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		int pellets = max(1, int(invoker.PelletCount * pelletMult));
		int overshoot = invoker.GetCadenceOvershoot();
		double spread = (100.0 - invoker.Accuracy) * (1.0 - invoker.Choke * 0.5) * 0.05 + (overshoot * 0.15);

		A_RS_FireBallisticVolley(pellets, spread, int(dmg), invoker.CritChance, invoker.Velocity);
		A_PlaySound(fireSound, CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, heavyFire);
		RS_HiFiFX.CasingEject(self, casingClass);
		TakeInventory(invoker.AmmoType2, 1);
		A_RS_MarkFired();
	}
}
