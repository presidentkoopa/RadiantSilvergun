// =====================================================================
// RS_VP_Weapon -- shared base for the "Vanilla+" weapon set (GNRCWPN).
// ---------------------------------------------------------------------
// Genuinely an RS_Weapon underneath -- full RollStats/Condition/tier
// capability is never removed, just not exercised through the normal
// elite-drop/tier loop (Vanilla+ grants these at a fixed configuration
// instead). If these ever join the main loot pool, nothing needs
// rebuilding: flip the purist cvar and the rolls are already there.
//
// Deliberate consolidation vs the main arsenal: A_RS_Backfire is
// byte-identical in all ten main weapon files. Here it lives once, on
// the base.
//
// Magazine reload used to live here too (A_RS_VP_MagLoad), reading
// AmmoType1 directly instead of a hardcoded reserve class name -- the
// main arsenal had the same bookkeeping duplicated ten separate times
// with a literal string baked into each copy. That fix has since moved
// up one more level, to RS_Weapon.A_RS_ReloadAtomic(), so both sets
// share the exact same reload plumbing rather than each set having its
// own copy of an identical fix.
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

	// Each mainhand weapon that has a floor-pickup presence (i.e. carries
	// `replaces <VanillaClass>`) overrides this to name its own "2"-suffixed
	// off-hand sibling. Null here means "no off-hand morph for this
	// weapon" -- the default for anything that doesn't override it (the
	// Assault Rifle never spawns via replaces at all, so it never reaches
	// this path either).
	virtual Class<Weapon> GetOffhandClass()
	{
		return null;
	}

	// Makes Vanilla+ behave like real vanilla Doom pickups, with dual-wield
	// layered on top: the first copy of a weapon gives you the mainhand
	// (ordinary Weapon.TryPickup handles that below). Walking over a SECOND
	// copy while you already hold the mainhand -- vanilla behavior would be
	// "ammo only, you already have this weapon" -- instead morphs into the
	// off-hand identity. Once both hands are filled, it's back to ordinary
	// vanilla ammo-only behavior; nothing below ever fires a third time.
	override bool TryPickup(in out Actor toucher)
	{
		let plr = toucher.player;
		Class<Weapon> offhandCls = GetOffhandClass();
		if (plr && offhandCls)
		{
			bool hasMain = !!plr.mo.FindInventory(GetClass());
			bool hasOff  = !!plr.mo.FindInventory(offhandCls);
			if (hasMain && !hasOff)
			{
				let offhandItem = Weapon(Spawn(offhandCls, Pos));
				bool ok = offhandItem.TryPickup(toucher);
				Destroy();
				return ok;
			}
		}
		return Super.TryPickup(toucher);
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
