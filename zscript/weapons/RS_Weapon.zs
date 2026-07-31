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

	int XP;
	int Level;
	int XPToNextLevel;

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

	// Shared by every bullet-firing weapon type instead of vanilla
	// A_FireBullets, so all of them get real traveling rounds through one
	// place rather than each weapon file managing its own projectile
	// spawn. ProjectileClass is read fresh every shot, so swapping it at
	// runtime changes what flies out immediately, no re-equip needed.
	//
	// aimflags passes ALF_ISOFFHAND (this engine's dual-wield fork,
	// DXR2 -- see QuestZDoom's Dual-Wield API changes) whenever the
	// firing weapon is an offhand identity, so the engine spawns the
	// shot from the tracked offhand controller's real position/angle
	// instead of always defaulting to the mainhand transform. Universal
	// fix, one call site -- every weapon in both sets already routes
	// through this function, so nothing per-weapon needs to change.
	action void A_RS_FireBallisticVolley(int pellets, double spread, int dmg, double critChance, double velocity)
	{
		Class<RS_BallisticFired> cls = invoker.ProjectileClass;
		if (!cls)
			cls = "RS_BallisticType1";

		int aimflags = invoker.bOffhandWeapon ? ALF_ISOFFHAND : 0;

		for (int p = 0; p < pellets; p++)
		{
			double a = angle + FRandom(-spread, spread);
			double pi = pitch + FRandom(-spread, spread);
			let proj = RS_BallisticFired(SpawnPlayerMissile(cls, a, pitch: pi, aimflags: aimflags));
			if (proj)
			{
				proj.SetupStats(dmg, velocity, critChance);
				// master is otherwise unused on these projectiles; GunBonsai's
				// offhand tracking reads it to attribute XP to the hand that
				// actually fired, since target is always the player, not the gun.
				proj.master = invoker;
			}
		}
	}

	// The heavy-ordnance counterpart to A_RS_FireBallisticVolley. Every
	// heavy weapon in both sets routes through this instead of naming its
	// projectile in a literal string, which is what makes the projectile
	// data rather than code -- and is why the rolled DamagePerShot now
	// reaches the projectile at all. Before this existed, all six heavy
	// weapons fired a stock vanilla class carrying its own fixed damage,
	// so tier, Condition, XP and purist mode had no effect on them.
	//
	// spawnHeight is a real per-weapon value (the muzzle offset each
	// weapon's own model needs), passed through rather than flattened to
	// one number.
	//
	// Fires via SpawnPlayerMissile rather than A_FireProjectile -- this
	// engine's dual-wield fork (DXR2 -- see QuestZDoom's Dual-Wield API
	// changes) never extended A_FireProjectile with an offhand flag, only
	// SpawnPlayerMissile/SpawnSubMissile/LineAttack/RailAttack/
	// AimLineAttack. SpawnPlayerMissile is what A_FireProjectile forwards
	// to internally, so angle/pitch/z-offset semantics carry over
	// directly: passing the actor's own angle/pitch (no offset) plus
	// noautoaim reproduces the old FPF_NOAUTOAIM, straight-ahead-only
	// behavior, while aimflags now lets an offhand-identity weapon spawn
	// from its real tracked controller transform instead of always
	// defaulting to mainhand's. Same universal, one-call-site fix as
	// A_RS_FireBallisticVolley above.
	//
	// Ammo is deliberately NOT touched here: the two sets meter it
	// differently (main arsenal draws AmmoType1 directly, Vanilla+ runs a
	// magazine through AmmoType2), so it stays each weapon's business,
	// exactly as it was before.
	action void A_RS_FireHeavyProjectile(double spawnHeight = 0)
	{
		Class<Actor> cls = invoker.HeavyProjectileClass;
		if (!cls)
			return;

		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		double dmg = invoker.DamagePerShot * dmgMult;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		int aimflags = invoker.bOffhandWeapon ? ALF_ISOFFHAND : 0;
		let proj = SpawnPlayerMissile(cls, angle, 0, 0, spawnHeight, noautoaim: true, aimflags: aimflags, pitch: pitch);
		if (!proj)
			return;
		proj.master = invoker; // see A_RS_FireBallisticVolley for why

		// Rocket/PlasmaBall/BFGBall inherit three different vanilla bases,
		// so there's no shared ancestor to cast to and SetupStats has to be
		// reached per type. If a fourth heavy projectile type is ever added,
		// it needs a branch here -- the honest cost of not reimplementing
		// vanilla explosion behavior just to get a common parent.
		if (proj is "RS_EnhancedRocket")
			RS_EnhancedRocket(proj).SetupStats(int(dmg), invoker.CritChance);
		else if (proj is "RS_EnhancedPlasmaBall")
			RS_EnhancedPlasmaBall(proj).SetupStats(int(dmg), invoker.CritChance);
		else if (proj is "RS_EnhancedBFGBall")
			RS_EnhancedBFGBall(proj).SetupStats(int(dmg), invoker.CritChance);
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
	// This is ADDITIVE and OPT-IN. A weapon that never calls
	// BuildAttackProfiles() has empty slots, A_RS_FireSlot does nothing,
	// and its existing Fire: states keep calling
	// A_RS_FireBallisticVolley / A_RS_FireHeavyProjectile exactly as
	// they do today. Nothing in the current arsenal changes until a
	// weapon deliberately opts in.
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
			A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
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
			A_PlaySound(p.FireSound, CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, p.BigMuzzle);
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
				// THE SACRED POINTER -- GunBonsai reads master to attribute
				// XP to the hand that actually fired. Never break it.
				proj.master = self;
			}
		}
	}

	// One heavy round. Mirrors A_RS_FireHeavyProjectile's per-type
	// SetupStats branching, for the same reason: Rocket/PlasmaBall/
	// BFGBall inherit three unrelated vanilla bases and share no ancestor
	// to cast to.
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

	// Each weapon type overrides this to call its own RS_Roll function
	// (e.g. RS_Roll.RollRevolverStats) and set its type-specific stats.
	virtual void RollStats(EVR_Tier t)
	{
		Tier = t;
	}

	void UnlockStat(String statName)
	{
		if (statName == "damage")     LockedDamage     = false;
		else if (statName == "accuracy")   LockedAccuracy   = false;
		else if (statName == "velocity")   LockedVelocity   = false;
		else if (statName == "critchance") LockedCritChance = false;
		else if (statName == "capacity")   LockedCapacity   = false;
	}

	virtual void ApplyUpgradeCard(EVR_Tier newTier)
	{
		RollStats(newTier);
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

	void GiveXP(int amount)
	{
		XP += amount;
		if (XPToNextLevel <= 0)
			XPToNextLevel = 100;

		while (XP >= XPToNextLevel)
		{
			XP -= XPToNextLevel;
			Level++;
			XPToNextLevel = 100 + Level * 50;
			if (!LockedDamage) DamagePerShot += 1;
		}
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
			ProjectileClass = CVar.GetCVar("rs_fx_tracers", null).GetBool() ? "RS_BallisticTracer" : "RS_BallisticType1";
		if (!HeavyProjectileClass)
			HeavyProjectileClass = GetHeavyProjectile();
		EnsureAttackProfiles();
	}
}
