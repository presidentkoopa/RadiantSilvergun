// =====================================================================
// RS_Weapon -- generic weapon base class.
// ---------------------------------------------------------------------
// Every future weapon type (Revolver, Rifle, SMG, etc.) inherits from
// this instead of from Weapon directly. Holds everything universal
// across weapon types: tier, the rolled/assigned stats, Condition,
// XP/Level, GunBonai socket count, and every function that doesn't
// care what specific kind of gun it's attached to. RollStats() is a
// stub here -- each weapon type overrides it to call its own
// type-specific roll function in RS_Roll (e.g. RollRevolverStats).
// =====================================================================

class RS_Weapon : Weapon abstract
{
	EVR_Tier Tier;

	int    DamagePerShot;    // rolled
	double Accuracy;         // rolled, 0-100 scale
	double Velocity;         // rolled
	double CritChance;       // rolled, 0-1
	int    Capacity;         // rolled

	int    RateOfFire;       // assigned by weapon identity, fixed by the
	                         // real fire animation length -- this is now
	                         // the only cadence stat stored. TimeBetween
	                         // Shots was always just 1.0/RateOfFire with
	                         // no independent input, so it's derived on
	                         // demand (GetTimeBetweenShots below) instead
	                         // of stored as a second, redundant field.
	double ReloadSpeed;      // rolled -- tier-scaled multiplier on how fast
	                         // the reload sequence completes. This is what
	                         // tier actually affects now, not fire cadence.
	int    PelletCount;      // assigned
	int    GunBonaiSockets;  // assigned by tier
	double Condition;        // rolled, 1-100%, degrades/repairs via RS_Roll
	double Choke;            // pellet cone/spread control, dormant until PelletCount > 1

	// How many times this weapon has been sacrificed from Prototype back to
	// Basic via Promote() below. Never resets, never decreases. Vanity as
	// storage, but read by two real systems: RS's own stat level-up
	// magnitude (a promoted weapon's picks are worth more), and eventually
	// GunBonsai's affix rank selection once a promoted weapon climbs back
	// to a socket-bearing tier. See docs/rs_01_promotion_system.txt.
	int PromotionCount;

	bool LockedDamage, LockedAccuracy, LockedVelocity, LockedCritChance, LockedCapacity;

	bool bStatsRolled;

	Class<RS_BallisticFired> ProjectileClass; // swappable at runtime by future upgrade systems

	// The heavy-ordnance equivalent of ProjectileClass, for weapons that
	// fire a single explosive/energy round rather than a bullet volley.
	// Two fields rather than one because the firing shapes genuinely
	// differ (volley with pellet count + spread cone vs. one round with
	// splash), and because Rocket/PlasmaBall/BFGBall each inherit real,
	// different vanilla explosion behavior -- they can't share
	// RS_BallisticFired as an ancestor without reimplementing all of it.
	// Seeded from GetHeavyProjectile() at spawn; read fresh every shot, so
	// writing it at runtime changes what launches immediately.
	Class<Actor> HeavyProjectileClass;

	// --- True semi-auto enforcement ---
	// A shot marks this true; it only clears once the trigger is
	// physically released. Fire cannot proceed again until it's false.
	// This is what makes "one trigger pull = one shot" real instead of
	// vanilla Doom's default (holds fire = keeps firing as fast as the
	// animation allows).
	bool bWaitingForRelease;

	// --- Real Rate of Fire / Time Between Shots enforcement ---
	// The actual tic timestamp the weapon becomes fireable again. This
	// is what makes RateOfFire/TimeBetweenShots real stats instead of
	// unused numbers -- nothing can fire before this, full-auto or not.
	int NextFireTic;

	double GetTimeBetweenShots()
	{
		return 1.0 / max(1, RateOfFire);
	}

	bool CanFireSemiAuto()
	{
		return !bWaitingForRelease;
	}

	// For full-auto weapons only: a real hard gate on TimeBetweenShots.
	// Unlike semi-auto (soft accuracy penalty for outpacing cadence,
	// since a human trigger pull is doing the pacing), a held-down
	// full-auto weapon's rate of fire IS the cadence -- it has to be a
	// hard limit or ROF stops meaning anything for these weapons.
	action bool AutoCooldownReady()
	{
		return level.time >= invoker.NextFireTic;
	}

	// How many tics the last shot came early by, relative to
	// TimeBetweenShots -- 0 if the shot was at or slower than the
	// weapon's real cadence. Used to compute an accuracy penalty, not
	// to block firing; the semi-auto release gate above is the only
	// hard block. Firing faster than intended costs Accuracy instead.
	action int GetCadenceOvershoot()
	{
		int shortfall = invoker.NextFireTic - level.time;
		return max(0, shortfall);
	}

	// Called once per shot fired, by every weapon type, semi-auto or
	// full-auto alike -- sets the release gate and records when the
	// weapon's real cadence next expects a shot.
	action void A_RS_MarkFired()
	{
		invoker.bWaitingForRelease = true;
		invoker.NextFireTic = level.time + max(1, int(invoker.GetTimeBetweenShots() * 35));
	}

	// Called every tic while in Ready -- the moment the trigger is
	// physically released, the semi-auto gate clears, allowing the
	// next pull to fire. Full-auto weapons don't need this call in
	// their Ready state (they don't use the release gate at all), but
	// it's harmless if present.
	// ReloadSpeed bonus: since reload animation frames stay exact
	// (tied to the real MODELDEF), ReloadSpeed can't scale per-frame
	// timing without breaking that. Instead, a higher roll grants
	// bonus rounds loaded instantly on top of whatever the animation's
	// guaranteed fill already did -- the visual stays frame-exact, the
	// stat still does something real.
	action int GetReloadBonusRounds()
	{
		return max(0, int((invoker.ReloadSpeed - 1.0) * 3));
	}

	action void A_RS_ClearTriggerGate()
	{
		if (!(player.cmd.buttons & BT_ATTACK))
			invoker.bWaitingForRelease = false;
	}

	// -------------------------------------------------------------
	// Universal reload plumbing.
	//
	// Every reloadable weapon in both sets reduces to one of two
	// bookkeeping shapes -- magazine swap, speed-loader, and break-action
	// are all "fill AmmoType2 to Capacity in one call," differing only in
	// the animation wrapped around it; per-shell weapons need the
	// incremental version instead, since their Reload: state is a loop
	// with no single final-tally moment.
	//
	// Both read AmmoType1 generically rather than a hardcoded reserve
	// class name. Before this, six main-arsenal weapons each carried
	// their own copy of the atomic version with a different literal
	// string ("Clip", "VR_Shell") baked in -- the same bug the Vanilla+
	// set's own A_RS_VP_MagLoad had already fixed once, just not carried
	// back to where it started. This is that fix, generalized to a
	// single shared base for both sets.
	// -------------------------------------------------------------

	// capacityOffset models the "chambered round" distinction the source
	// set draws on several weapons: reloading a gun that still has a round
	// in the chamber tops out one higher than reloading a completely empty
	// one (Pistol 11 vs 10, Assault Rifle 31 vs 30). Pass -1 from the
	// empty-gun reload branch, leave it 0 for the chambered branch. Lives
	// here rather than in each weapon because more than one weapon in the
	// set has exactly this two-branch reload.
	action void A_RS_ReloadAtomic(int capacityOffset = 0)
	{
		Class<Ammo> reserve = invoker.AmmoType1;
		if (!reserve)
			return;

		int needed = (invoker.Capacity + capacityOffset) - CountInv(invoker.AmmoType2);
		int available = CountInv(reserve);
		int toLoad = min(needed, available);
		if (toLoad <= 0)
			return;

		int cost = max(1, toLoad - invoker.GetReloadBonusRounds());
		cost = min(cost, available);
		TakeInventory(reserve, cost);
		GiveInventory(invoker.AmmoType2, toLoad);
	}

	// Loads one round per call. ReloadSpeed still matters here -- since
	// there's no single final tally to apply GetReloadBonusRounds
	// against, a faster-rolling weapon instead gets a real chance at a
	// free second shell on the same pass.
	action void A_RS_ReloadIncremental(double bonusChance = 0.25)
	{
		Class<Ammo> reserve = invoker.AmmoType1;
		if (!reserve)
			return;
		if (CountInv(invoker.AmmoType2) >= invoker.Capacity || CountInv(reserve) <= 0)
			return;

		GiveInventory(invoker.AmmoType2, 1);
		TakeInventory(reserve, 1);

		if (invoker.GetReloadBonusRounds() > 0 && FRandom(0, 1) < bonusChance
			&& CountInv(invoker.AmmoType2) < invoker.Capacity && CountInv(reserve) > 0)
		{
			GiveInventory(invoker.AmmoType2, 1);
			TakeInventory(reserve, 1);
		}
	}

	// Called from each weapon's Flash: state. Only ever does anything at
	// Hi-Fi tier -- RS_HiFiFX itself decides that, this call site never
	// needs to know or check the tier.
	action void A_RS_MuzzleFlash()
	{
		RS_HiFiFX.SpawnMuzzleLight(self);
	}

	// =================================================================
	// ATTACK SLOTS -- the assembly system. See RS_AttackProfile.zs for
	// the full rationale; the short version:
	//
	//   Primary slot   = main trigger.  Secondary slot = alt-fire.
	//   Each slot is an ordered LIST of RS_AttackProfile plus a cursor.
	//   Firing a slot fires the profile at the cursor, then advances.
	//
	// Every weapon in both the main arsenal and the GH set now authors
	// BuildAttackProfiles() and fires exclusively through A_RS_FireSlot;
	// the old per-weapon direct-fire path this migration replaced is
	// gone. A weapon that somehow ships without BuildAttackProfiles()
	// just has empty slots and A_RS_FireSlot does nothing.
	// =================================================================

	RS_AttackSlot PrimarySlot;
	RS_AttackSlot SecondarySlot;

	// 0 = primary (main trigger), 1 = secondary (alt-fire).
	RS_AttackSlot GetSlot(int which)
	{
		return (which == 0) ? PrimarySlot : SecondarySlot;
	}

	// Each weapon overrides this to author what it SHIPS with -- the
	// hand-tuned starting content of each slot. Virtual rather than a
	// Default property for the same reason GetHeavyProjectile() is:
	// ZScript can't build objects in a Default block.
	//
	// Authoring a normal single-attack weapon is one Append into
	// PrimarySlot. A weapon with a real alt-fire appends into
	// SecondarySlot too. GunBonsai grows these later; it never has to
	// have designed the starting point.
	virtual void BuildAttackProfiles()
	{
	}

	// -----------------------------------------------------------------
	// GunBonsai-facing API. Three write targets, all one call:
	//   grow the rotation  -> AppendProfile / InsertProfileAt
	//   swap one entry     -> ReplaceProfile
	// An affix that says "every 3rd shot is explosive" is:
	//   PadSlotTo(0, 3); ReplaceProfile(0, 2, explosiveProfile);
	// -----------------------------------------------------------------

	void AppendProfile(int which, RS_AttackProfile p)
	{
		let s = GetSlot(which);
		if (s) s.Append(p);
	}

	void InsertProfileAt(int which, int index, RS_AttackProfile p)
	{
		let s = GetSlot(which);
		if (s) s.InsertAt(index, p);
	}

	void ReplaceProfile(int which, int index, RS_AttackProfile p)
	{
		let s = GetSlot(which);
		if (s) s.Replace(index, p);
	}

	void PadSlotTo(int which, int length)
	{
		let s = GetSlot(which);
		if (!s) return;
		let filler = s.PeekAt(0);
		if (filler) s.PadTo(length, filler);
	}

	int GetSlotCount(int which)
	{
		let s = GetSlot(which);
		return s ? s.Count() : 0;
	}

	// -----------------------------------------------------------------
	// Dispatch. One entry point for every attack type -- the profile's
	// own Mode decides which firing path runs, so a slot can rotate
	// through a bullet, then a rocket, then a melee swing with none of
	// them being a special case.
	//
	// Fire: states call A_RS_FireSlot(0); AltFire: states call
	// A_RS_FireSlot(1).
	// -----------------------------------------------------------------
	action bool A_RS_FireSlot(int which = 0)
	{
		let slot = invoker.GetSlot(which);
		if (!slot || slot.IsEmpty())
			return false;

		// Peek before spending anything -- an unaffordable shot must not
		// advance the rotation, or a dry trigger pull would silently eat
		// the player's place in the cycle.
		let p = slot.Peek();
		if (!p)
			return false;

		// Resolve the pool this profile draws from. Null AmmoClass with a
		// real cost means the weapon's own magazine, which differs per
		// identity subclass (VR_RevLoaded vs VR_RevLoaded4) -- so it has
		// to be read off the instance here, not baked into the profile.
		Class<Ammo> pool = p.AmmoClass;
		if (!pool && p.AmmoCost > 0)
			pool = invoker.AmmoType2;

		if (pool && p.AmmoCost > 0 && CountInv(pool) < p.AmmoCost)
			return false;

		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		// Backfire eats the ammo and the shot but does NOT advance the
		// rotation -- a jam shouldn't cost you your place in the cycle.
		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			if (pool && p.AmmoCost > 0)
				TakeInventory(pool, p.AmmoCost);
			A_RS_MarkFired();
			return false;
		}

		// Committed. Spend, and step the rotation forward.
		slot.Advance();
		if (pool && p.AmmoCost > 0)
			TakeInventory(pool, p.AmmoCost);

		// Declare who's firing, right here, before any mode-specific path
		// runs -- this is the one place that already knows for certain,
		// for every Mode (bullet/heavy/hitscan/melee) uniformly. See
		// RS_GunBonsaiBridge.zs for why this replaces trying to infer the
		// firing hand after the fact from a projectile's master pointer.
		RS_GunBonsaiBridge.NotifyFired(self, invoker);

		double dmg = invoker.DamagePerShot * dmgMult * p.DamageMult;
		if (FRandom(0, 1) < (invoker.CritChance + p.CritBonus))
			dmg *= 2.0;

		int pellets = (p.PelletOverride > 0) ? p.PelletOverride : invoker.PelletCount;
		pellets = max(1, int(pellets * pelletMult));

		double choke = p.UsesChoke ? (1.0 - invoker.Choke * 0.5) : 1.0;
		double spread = (100.0 - invoker.Accuracy) * p.SpreadScale * choke + p.SpreadBonus;
		if (p.UsesCadence)
			spread += invoker.GetCadenceOvershoot() * 0.15;

		// Hitscan and melee run inline because A_FireBullets/A_CustomPunch
		// are action functions -- they can't be reached from the play-scope
		// helpers the projectile modes use.
		if (p.Mode == RS_ATK_HITSCAN)
		{
			Class<Actor> hitscanPuff = p.ImpactPuff;
			if (!hitscanPuff) hitscanPuff = "bulletpuff";
			A_FireBullets(spread, spread, pellets, int(dmg), hitscanPuff, FBF_NORANDOM);
		}
		else if (p.Mode == RS_ATK_MELEE)
		{
			Class<Actor> puff = p.MeleePuff;
			if (!puff) puff = "BulletPuff";
			A_CustomPunch(int(dmg), false, 0, puff, p.MeleeRange);
		}
		else if (p.Mode == RS_ATK_HEAVY)
		{
			invoker.RS_FireProfileHeavy(self, p, dmg);
		}
		else
		{
			invoker.RS_FireProfileBullet(self, p, dmg, pellets, spread);
		}

		if (p.FireSound)
			A_PlaySound(invoker.GetEffectiveFireSound(p.FireSound), CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, p.BigMuzzle, p.MuzzleSmoke);
		if (p.CasingClass != "")
			RS_HiFiFX.CasingEject(self, p.CasingClass);

		A_RS_MarkFired();
		return true;
	}

	// Condition backfire -- was an identical copy on all 11 weapons.
	// Same DamagePerShot + crit roll a normal shot gets.
	action void A_RS_Backfire()
	{
		A_PlaySound("rs_fx_weapon_empty", CHAN_WEAPON);
		double dmg = invoker.DamagePerShot;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;
		player.mo.DamageMobj(invoker, player.mo, int(dmg), 'BackfireDamage');
	}

	// Bullet volley. Damage/pellets/spread are resolved by the dispatch
	// above and passed in, so this stays a pure spawn loop -- and so the
	// same numbers the dispatch computed are the ones that actually fly.
	void RS_FireProfileBullet(Actor shooter, RS_AttackProfile p, double dmg, int pellets, double spread)
	{
		Class<Actor> cls = p.ProjectileClass;
		if (!cls) cls = ProjectileClass;
		if (!cls) cls = "RS_BallisticType1";

		int aimflags = bOffhandWeapon ? ALF_ISOFFHAND : 0;
		double vel = Velocity * p.VelocityMult;
		double crit = CritChance + p.CritBonus;

		for (int i = 0; i < pellets; i++)
		{
			double a  = shooter.angle + FRandom(-spread, spread);
			double pt = shooter.pitch + FRandom(-spread, spread);
			let proj = RS_BallisticFired(
				shooter.SpawnPlayerMissile(cls, a, pitch: pt, aimflags: aimflags));
			if (proj)
			{
				proj.SetupStats(int(dmg), vel, crit);
				proj.SetupFeedback(p.ImpactPuff, p.ImpactSparks, p.Trail);
				// THE SACRED POINTER -- GunBonsai reads master to attribute
				// XP to the hand that actually fired. Never break it.
				proj.master = self;
			}
		}
	}

	// One heavy round. Same per-type SetupStats branching as the bullet
	// path's projectile-class switch below, for the same reason:
	// Rocket/PlasmaBall/BFGBall inherit three unrelated vanilla bases
	// and share no ancestor to cast to.
	void RS_FireProfileHeavy(Actor shooter, RS_AttackProfile p, double dmg)
	{
		Class<Actor> cls = p.ProjectileClass;
		if (!cls) cls = HeavyProjectileClass;
		if (!cls) return;

		int aimflags = bOffhandWeapon ? ALF_ISOFFHAND : 0;

		let proj = shooter.SpawnPlayerMissile(cls, shooter.angle, 0, 0, p.SpawnHeight,
			noautoaim: true, aimflags: aimflags, pitch: shooter.pitch);
		if (!proj)
			return;
		proj.master = self;   // see RS_FireProfileBullet

		double crit = CritChance + p.CritBonus;
		if (proj is "RS_EnhancedRocket")
			RS_EnhancedRocket(proj).SetupStats(int(dmg), crit);
		else if (proj is "RS_EnhancedPlasmaBall")
			RS_EnhancedPlasmaBall(proj).SetupStats(int(dmg), crit);
		else if (proj is "RS_EnhancedBFGBall")
			RS_EnhancedBFGBall(proj).SetupStats(int(dmg), crit);
		else if (proj is "RS_GH_BFGShot")
			RS_GH_BFGShot(proj).SetupStats(int(dmg), crit);
		else if (proj is "RS_GH_PlasmaShot")
			RS_GH_PlasmaShot(proj).SetupStats(int(dmg), crit);
		else if (proj is "RS_GH_UnmakerShot")
			RS_GH_UnmakerShot(proj).SetupStats(int(dmg), crit);
	}

	// Each heavy weapon overrides this to declare what it launches. A
	// virtual getter rather than a Default property because ZScript can't
	// assign a plain member in a Default block, and property support for
	// Class<> types is unreliable -- this is the version that definitely
	// compiles while staying declarative and per-weapon. Bullet weapons
	// leave it null and use ProjectileClass instead.
	virtual Class<Actor> GetHeavyProjectile()
	{
		return null;
	}

	// Class-gating family -- None by default (heavy ordnance, Fist,
	// Vanilla+ weapons all stay ungated). Each Dual_X-owned weapon type
	// overrides this to name its own family; see RS_ClassGating.zs.
	virtual EVR_Family GetFamily()
	{
		return EVR_Family_None;
	}

	// -----------------------------------------------------------------
	// Weapon Sound Assignment (MENUDEF's RS_WeaponSoundOptions). No
	// per-weapon overrides needed or wanted -- the cvar key is read
	// straight off the weapon's own archetype: keyword (every weapon
	// already declares one in GetBaseKeywords()), and the actual
	// choice -> sound mapping lives entirely in RS_Catalog
	// (ResolveArchetypeSound), not scattered across weapon files. Adding
	// a new archetype's alternates later means editing RS_Catalog.zs
	// once, never touching an individual weapon file. Checked fresh
	// every shot (called from A_RS_FireSlot) rather than baked in at
	// BuildAttackProfiles() time, so changing the menu selection
	// mid-game takes effect on the very next shot, not after a re-equip.
	// -----------------------------------------------------------------
	sound GetEffectiveFireSound(sound defaultSound)
	{
		string archetype = GetKeywordValue("archetype");
		if (archetype == "")
			return defaultSound;

		CVar cv = CVar.FindCVar("rs_soundchoice_" .. archetype);
		if (!cv || cv.GetInt() <= 0)
			return defaultSound;

		return RS_Catalog.ResolveArchetypeSound(archetype, cv.GetInt(), defaultSound);
	}

	// Each weapon type overrides this to call its own RS_Roll function
	// (e.g. RS_Roll.RollRevolverStats) and set its type-specific stats.
	virtual void RollStats(EVR_Tier t)
	{
		Tier = t;
	}

	// Lifting a curse (Cursed-tier's original lock, or a Promotion-rolled
	// one from RollPromotionCurse below -- same Locked* flags, same unlock
	// path either way) doesn't just free the stat, it rewards clearing it:
	// a 1.5x boost on top of whatever the stat was sitting at while locked.
	// Guarded on the flag actually being set so calling this twice (or on
	// a stat that was never locked) can't double-dip the boost.
	void UnlockStat(String statName)
	{
		if (statName == "damage" && LockedDamage)
		{
			LockedDamage = false;
			DamagePerShot = max(1, int(DamagePerShot * 1.5));
		}
		else if (statName == "accuracy" && LockedAccuracy)
		{
			LockedAccuracy = false;
			Accuracy *= 1.5;
		}
		else if (statName == "velocity" && LockedVelocity)
		{
			LockedVelocity = false;
			Velocity *= 1.5;
		}
		else if (statName == "critchance" && LockedCritChance)
		{
			LockedCritChance = false;
			CritChance *= 1.5;
		}
		else if (statName == "capacity" && LockedCapacity)
		{
			LockedCapacity = false;
			Capacity = max(1, int(Capacity * 1.5));
		}
	}

	// The DamagePerShot ceiling a stat level-up may not exceed until the
	// next Promotion. Placeholder curve -- 1.8x headroom off whatever
	// DamagePerShot was set to at the moment of the last Promote() (or off
	// the initial roll, pre-promotion). This is the exact multiplier that
	// fell out of the worked Cyberdemon-math sanity check in
	// docs/rs_01_promotion_system.txt (cycle 0 42->cycle-1-peak ~58 is a
	// 1.38x *increase from the cut point*, i.e. cut-point 34 * 1.8 ~= 61 --
	// close enough to use as the starting number), not independently
	// re-derived. Nothing calls this yet -- RS doesn't own the level-up
	// picker UI (that's GunBonsai's, see docs/rs_01), so this is the data
	// half of the mechanism, ready for that hook to read once it exists.
	int GetDamageCeiling()
	{
		return max(1, int(PromotionDamageBaseline * 1.8));
	}

	virtual void ApplyUpgradeCard(EVR_Tier newTier)
	{
		if (Tier == VRT_Prototype && newTier == VRT_Basic)
			Promote();
		else
			RollStats(newTier);
	}

	// The value DamagePerShot was cut to at the moment of the most recent
	// Promote() (or the initial roll, if never promoted) -- the anchor
	// GetDamageCeiling() scales off of. Not the live DamagePerShot value,
	// which keeps climbing from here via normal level-ups.
	int PromotionDamageBaseline;

	// The Prototype -> Basic sacrifice. See docs/rs_01_promotion_system.txt
	// for the full worked-out design; this is the locked mechanical core:
	//   - Tier drops to Basic, sockets go to 0 with it (RS_Roll.SocketsForTier
	//     is the single source of truth for that -- read it fresh rather
	//     than hardcoding 0, so a future tier table change can't drift).
	//   - Every rolled stat takes a proportional 20% cut from its CURRENT
	//     value -- 20% OF the current number, not a fresh Basic-range
	//     re-roll and not a flat 20-point subtraction. An 88 Accuracy
	//     becomes 88*0.8 = 70.4, not 66 and not 68. Applies regardless of
	//     Locked state -- Locked only blocks upward level-up gains, it
	//     doesn't exempt a stat from this cut.
	//   - PelletCount +1, permanent. (Flat +1 for every weapon type today;
	//     docs/rs_01 flags that shotgun-family probably wants a different
	//     number here, not yet decided.)
	//   - PromotionCount +1, permanent, never resets.
	//   - A chance to additionally curse one rolled stat -- see
	//     RollPromotionCurse below.
	// Deliberately does NOT touch GunBonsai Level/XP -- that axis is
	// GunBonsai's, not RS's, and keeps climbing regardless of Tier.
	// Deliberately does NOT strip GunBonsai-granted affixes here -- that
	// has to happen on GunBonsai's side (its upgrade bag, not anything
	// stored on RS_Weapon), via the extend-class hook described in
	// docs/rs_01_promotion_system.txt. Until that hook exists, an affix
	// picked before promoting will keep functioning even though the
	// weapon is nominally back at 0 sockets -- known gap, not silent.
	void Promote()
	{
		DamagePerShot = max(1, int(DamagePerShot * 0.8));
		Accuracy      *= 0.8;
		Velocity      *= 0.8;
		CritChance    *= 0.8;
		Capacity      = max(1, int(Capacity * 0.8));

		Tier = VRT_Basic;
		GunBonaiSockets = RS_Roll.SocketsForTier(VRT_Basic);
		PelletCount += 1;
		PromotionCount += 1;
		PromotionDamageBaseline = DamagePerShot;

		RollPromotionCurse();
		RS_GunBonsaiBridge.OnWeaponPromoted(self);
	}

	const PROMOTION_CURSE_CHANCE = 0.15;

	// Escalates with PromotionCount instead of one flat roll forever: your
	// 1st promotion gets 1 independent curse chance, 2nd gets 2 rolls, 3rd
	// gets 3, etc. -- PromotionCount is already incremented by the time
	// this runs, so it reads directly as "how many rolls this time."
	// Each roll can land on any of the five stats (no dedupe against a
	// stat already hit this call -- keep it simple).
	//
	// A hit: locks the stat (the same Locked* flags Cursed-tier weapons
	// use at creation -- UnlockStat already knows how to lift either kind)
	// at 50% of whatever it was just cut to, and tags the weapon with a
	// curse: keyword. WHICH stat gets hit is picked here; the curse's
	// actual flavor/name is a placeholder ("curse:<statname>") until a
	// real curse list exists to roll the keyword's value from instead --
	// "we will roll from a list later," per design discussion.
	// STUBBED OFF -- disabled for now, mechanism kept intact for later.
	// Same shape as RS_Roll.GetConditionEffects' own disable.
	void RollPromotionCurse()
	{
		if (true)
			return;

		for (int i = 0; i < PromotionCount; i++)
			RollOneCurse();
	}

	void RollOneCurse()
	{
		if (FRandom(0, 1) >= PROMOTION_CURSE_CHANCE)
			return;

		switch (Random(0, 4))
		{
			case 0:
				DamagePerShot = max(1, int(DamagePerShot * 0.5));
				LockedDamage = true;
				GrantKeyword("curse", "damage");
				break;
			case 1:
				Accuracy *= 0.5;
				LockedAccuracy = true;
				GrantKeyword("curse", "accuracy");
				break;
			case 2:
				Velocity *= 0.5;
				LockedVelocity = true;
				GrantKeyword("curse", "velocity");
				break;
			case 3:
				CritChance *= 0.5;
				LockedCritChance = true;
				GrantKeyword("curse", "critchance");
				break;
			case 4:
				Capacity = max(1, int(Capacity * 0.5));
				LockedCapacity = true;
				GrantKeyword("curse", "capacity");
				break;
		}
	}

	void RepairWithGreyBits(int greyBitsSpent)
	{
		Condition = RS_Roll.RepairCondition(Condition, greyBitsSpent);
	}

	// Called once per currently-equipped weapon whenever the player
	// takes a hit (both hands independently).
	void OnPlayerDamaged(int rawDamageTaken)
	{
		Condition = RS_Roll.DegradeCondition(Condition, rawDamageTaken);
	}

	// Seats this weapon into the off-hand the instant it actually enters
	// the player's inventory, unless the off-hand already holds a REAL
	// weapon. VR_Fist2 (the off-hand's melee fallback, see
	// RS_Fist.zs) are explicitly exempt from "already holds something" --
	// every class's Player.StartItem list grants the fist filler BEFORE
	// the real starting weapon specifically so it gets bumped immediately,
	// and that ordering must keep working. What changes is what happens
	// AFTER that: once a real weapon is seated (by this, or by a
	// deliberate choice from RS_WeaponSelect.zs), a later pickup of
	// another offhand-flagged weapon no longer silently steals the slot
	// -- it just joins inventory, selectable from that menu like any
	// other owned weapon. Main-hand placement isn't handled here; the
	// engine's own default ReadyWeapon assignment already does that
	// correctly.
	override void AttachToOwner(Actor newOwner)
	{
		Super.AttachToOwner(newOwner);
		if (bOffhandWeapon && newOwner.player)
		{
			let current = newOwner.player.OffhandWeapon;
			bool slotIsFillerOrEmpty = !current || current is "VR_Fist2";
			if (slotIsFillerOrEmpty)
				newOwner.player.OffhandWeapon = self;
		}

		// A found gun arrives with rounds already in it. Picking up a new
		// weapon mid-firefight and having to reload before it can shoot is
		// a death sentence, so the magazine comes filled.
		//
		// Capacity is set by RollStats, and AttachToOwner can fire before
		// PostBeginPlay has run for a StartItem grant, so the roll is
		// forced here if it hasn't happened yet -- same guard PostBeginPlay
		// uses, safe to run either order.
		if (!bStatsRolled)
			RollStats(VRT_Basic);
		EnsureAttackProfiles();

		// AmmoType2 is this project's magazine slot (AmmoType1 is reserve).
		// Weapons with no magazine at all -- fists, chainsaw, and the heavy
		// ordnance that draws straight from reserve -- leave it null and are
		// skipped. Tops up to Capacity rather than adding to it, so an
		// explicit Player.StartItem grant of chambered rounds isn't doubled.
		if (AmmoType2 && Capacity > 0)
		{
			int loaded = newOwner.CountInv(AmmoType2);
			if (loaded < Capacity)
				newOwner.GiveInventory(AmmoType2, Capacity - loaded);
		}
	}

	// Slots are created once and then owned for the weapon's lifetime --
	// GunBonsai appends to the live lists, so they must survive across
	// re-equips. Guarded like bStatsRolled because AttachToOwner and
	// PostBeginPlay can run in either order depending on how the weapon
	// was acquired.
	bool bProfilesBuilt;

	void EnsureAttackProfiles()
	{
		if (bProfilesBuilt)
			return;
		bProfilesBuilt = true;
		PrimarySlot   = RS_AttackSlot(new("RS_AttackSlot"));
		SecondarySlot = RS_AttackSlot(new("RS_AttackSlot"));
		BuildAttackProfiles();
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (!bStatsRolled)
			RollStats(VRT_Basic);
		if (!ProjectileClass)
			ProjectileClass = "RS_BallisticType1";
		if (!HeavyProjectileClass)
			HeavyProjectileClass = GetHeavyProjectile();
		EnsureAttackProfiles();
		RS_Keywords.Validate(GetBaseKeywords(), GetClassName());
	}

	// =================================================================
	// KEYWORDS -- see docs/rs_03_keywords_v2.txt for the full schema.
	// BASE ships on the class (GetBaseKeywords, authored per weapon type
	// as space-delimited "key:value" tokens). GRANTED is added at
	// runtime by GunBonsai affixes / Promotion / sockets. Queries check
	// the union of both, same shape as the AttackProfile system: BASE is
	// what the weapon ships with, GRANTED is what got added since.
	// =================================================================

	Array<string> GrantedKeywords;

	// Each weapon type overrides this with its own real, authored BASE
	// tags. Empty default -- matches every other opt-in virtual already
	// on this class (BuildAttackProfiles, GetHeavyProjectile, GetFamily).
	virtual string GetBaseKeywords()
	{
		return "";
	}

	bool HasKeyword(string key, string value)
	{
		if (RS_Keywords.StringHas(GetBaseKeywords(), key, value))
			return true;
		string needle = key .. ":" .. value;
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i] == needle)
				return true;
		return false;
	}

	// Single-value key lookup (archetype, delivery, feed, reserve, set,
	// promotion, element). GRANTED overrides BASE when both are present,
	// so a Promotion/affix that changes e.g. element actually sticks.
	string GetKeywordValue(string key)
	{
		string v = RS_Keywords.GetValue(GetBaseKeywords(), key);
		string prefix = key .. ":";
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i].Left(prefix.Length()) == prefix)
				v = GrantedKeywords[i].Mid(prefix.Length());
		return v;
	}

	// Multi-value key lookup (trigger, payload, behavior, curse,
	// characteristic). Union of every BASE and GRANTED entry, no
	// overriding -- a weapon can genuinely have more than one.
	void GetKeywordValues(string key, out Array<string> results)
	{
		RS_Keywords.GetValues(GetBaseKeywords(), key, results);
		string prefix = key .. ":";
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i].Left(prefix.Length()) == prefix)
				results.Push(GrantedKeywords[i].Mid(prefix.Length()));
	}

	// GunBonsai/Promotion-facing write API.
	void GrantKeyword(string key, string value)
	{
		GrantedKeywords.Push(key .. ":" .. value);
	}
}
