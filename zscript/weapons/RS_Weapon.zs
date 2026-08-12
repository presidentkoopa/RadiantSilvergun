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
	double CritMult;         // rolled -- what a crit multiplies by. The
	                         // twelfth stat (took TimeBetweenShots' sheet
	                         // slot, owner ruling 2026-08-05). 0 = weapon
	                         // never rolled it; dispatch falls back to the
	                         // legacy 2.0.
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

	// -----------------------------------------------------------------
	// CURSE BOOKKEEPING. Added 2026-08-07 with the curse rework.
	//
	// PRE-CURSE VALUES. A curse HALVES a stat; lifting it must restore
	// the stat to what it was BEFORE, not multiply the halved number.
	//
	// This is the bug the rework exists to fix and it is worth stating
	// plainly, because the old code looked correct: a curse did x0.5 and
	// a lift did x1.5, so 100 -> 50 -> 75. You paid Curse Bits to end up
	// 25% BELOW where you started. The "reward" was a punishment, and
	// with stacking curses it got worse -- 100 -> 50 -> 25, one lift,
	// x1.5, 37. The un-halving IS the reward; the bonus rides on top of
	// a real restore.
	//
	// Damage already had this in PromotionDamageBaseline (captured before
	// the curse roll, deliberately -- see AttachToOwner). The other four
	// had no equivalent, which is why they are here.
	//
	// 0 means "never cursed, nothing to restore".
	double PreCurseAccuracy, PreCurseVelocity, PreCurseCritChance;
	int    PreCurseDamage, PreCurseCapacity;

	// How many curses are stacked on each stat. Owner ruling 2026-08-07:
	// "double curses on a stat or more is fine with me if penalties and
	// rewards are legit." Each stack halves again; each LIFT restores and
	// pays an escalating bonus, so a triple-cursed stat cleared out is
	// worth more than an entire promotion cycle of level-up cards.
	int CurseStackDamage, CurseStackAccuracy, CurseStackVelocity;
	int CurseStackCritChance, CurseStackCapacity;

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

	// "" (default) = use this weapon's own real archetype: keyword for
	// RS_FamilyPalette lookups. Set by a future GunBonsai affix to make a
	// weapon draw from a DIFFERENT archetype's palette without touching
	// its real GetBaseKeywords() identity -- e.g. an affix that makes a
	// Shotgun temporarily roll from the "energy" palette. Nothing sets
	// this yet.
	string PaletteArchetypeOverride;

	string GetPaletteArchetype()
	{
		if (PaletteArchetypeOverride != "")
			return PaletteArchetypeOverride;
		return GetKeywordValue("archetype");
	}

	// -----------------------------------------------------------------
	// AFFIX PART OVERRIDES -- the part-swap layer. Two kinds of affix
	// exist: math-changers (GrantKeyword, handled by RS_KeywordEffects)
	// and part-swappers ("your SMG now fires rail bolts") -- these
	// fields are the second kind's write target. Null/"" = no override.
	//
	// PRECEDENCE RULE, decided once, applies everywhere these are read:
	//   affix override  >  profile (beat-authored)  >  weapon fallback
	//   >  catalog default.
	// For FireSound the affix also beats the player's sound-choice cvar
	// -- an affix that changed WHAT the gun is outranks a cosmetic
	// preference for how the old gun sounded.
	//
	// KNOWN LIMIT, on purpose: one override slot per part, last writer
	// wins. Two part-swap affixes fighting over the same slot is a
	// content-design error, not a runtime case worth a stack -- the
	// affix GENERATOR must simply never deal two projectile-swappers to
	// one weapon. OnDeactivate should null only the fields it set.
	// -----------------------------------------------------------------
	Class<Actor> AffixProjectile;      // bullet path checked-casts this; heavy path fences ballistic classes out
	sound        AffixFireSound;
	// LAYERED, NOT AXIS 5. Plays IN ADDITION to whatever axis 5 resolved
	// to, on its own channel, so the gun keeps its own report and the
	// affix's voice rides underneath it.
	//
	// Added 2026-08-08 because AffixFireSound is an OVERRIDE: an affix
	// setting it silenced the weapon entirely for that shot. A caco-round
	// shotgun sounded like only a caco, which is precisely backwards --
	// the owner's rule is that the weapon's own report is an IDENTITY
	// ANCHOR and must survive whatever gets bolted onto the gun.
	//
	// AffixFireSound is kept for the genuine replace case (a suppressor,
	// a weapon that stops being a firearm). Themed voices belong here.
	sound        AffixExtraFireSound;
	Class<Actor> AffixImpactPuff;
	Class<Actor> AffixImpactSparks;
	Class<Actor> AffixMuzzleSmoke;
	Class<Actor> AffixMuzzleFlash;  // MUZZLE axis, light half -- null = defer to GITD
	Class<Actor> AffixTrail;
	Class<Actor> AffixExplosionVisual;
	string       AffixCasing;          // "" = no override, "none" = suppress casing entirely

	// =================================================================
	// THE AXIS LEDGER -- who owns each of the eight overrides.
	//
	// THE PROBLEM THIS SOLVES. Four separate things write these fields
	// and they had three different disciplines between them:
	//
	//   SlateBase.ClaimX (cards)   remembered what it wrote and cleared
	//                              only if the weapon still showed it
	//   Bonecaller / Cacospit      same, hand-rolled per affix
	//   RS_AffixInstall            wrote, then cleared with
	//                              ClearAffixParts() -- ALL EIGHT,
	//                              including other systems' work
	//   ClearAffixParts()          the deliberate nuke
	//
	// So three writers were careful and one was not, and the careful
	// ones' correctness depended on the careless one never running. That
	// is the same shape as the PACK beat collision fixed earlier today
	// (nine cards silently deleting each other for want of an owner
	// tag), in a second system, and it is why these parts felt like they
	// were "80% working together": each one is right on its own and
	// nothing arbitrated between them.
	//
	// One ledger, indexed by RS_FXRegistry's axis numbering so there is
	// a single set of axis IDs in the mod rather than one per system.
	// EXPLOSIONVISUAL has no axis of its own and files under PAYLOAD.
	//
	// Last writer wins -- deliberately, because a card taken later
	// SHOULD override an earlier roll. What the ledger prevents is the
	// reverse: something clearing a field it does not own.
	// =================================================================
	private string mAxisOwner[9];   // == RS_FXRegistry.RS_FXAXIS_COUNT.
	                                // Literal because ZScript needs a
	                                // compile-time constant for an array
	                                // bound and a cross-class const does
	                                // not reliably resolve there on this
	                                // engine build. AXIS_SLOTS below is
	                                // what every loop uses.
	const AXIS_SLOTS = 9;

	void SetAxisOwner(int axis, string owner)
	{
		if (axis >= 0 && axis < AXIS_SLOTS) mAxisOwner[axis] = owner;
	}
	string GetAxisOwner(int axis) const
	{
		return (axis >= 0 && axis < AXIS_SLOTS) ? mAxisOwner[axis] : "";
	}
	// True when nobody holds it, or the asker already does. An unowned
	// field is fair game -- that keeps the hand-rolled affixes that
	// predate this ledger working untouched.
	bool CanWriteAxis(int axis, string owner) const
	{
		string cur = GetAxisOwner(axis);
		return cur == "" || cur == owner;
	}

	// Typed setters. Three types across the eight axes, so they cannot
	// collapse into one function -- but they share the one ledger.
	void SetAxisClass(int axis, Class<Actor> c, string owner)
	{
		if (!c) return;
		if (axis == RS_FXRegistry.RS_FXAXIS_PROJECTILE) AffixProjectile      = c;
		else if (axis == RS_FXRegistry.RS_FXAXIS_PUFF)  AffixImpactPuff      = c;
		else if (axis == RS_FXRegistry.RS_FXAXIS_SPARKS)AffixImpactSparks    = c;
		else if (axis == RS_FXRegistry.RS_FXAXIS_SMOKE) AffixMuzzleSmoke     = c;
		else if (axis == RS_FXRegistry.RS_FXAXIS_MUZZLE)AffixMuzzleFlash     = c;
		else if (axis == RS_FXRegistry.RS_FXAXIS_TRAIL) AffixTrail           = c;
		else if (axis == RS_FXRegistry.RS_FXAXIS_PAYLOAD) AffixExplosionVisual = c;
		else return;
		SetAxisOwner(axis, owner);
	}
	void SetAxisSound(sound s, string owner, bool replaceGunReport = false)
	{
		if (s == "") return;
		// Default to the LAYERED channel. AffixFireSound is an override
		// that silences the gun's own report, and the owner's rule is
		// that the report is an identity anchor -- so replacing it has
		// to be asked for explicitly.
		if (replaceGunReport) AffixFireSound = s;
		else                  AffixExtraFireSound = s;
		SetAxisOwner(RS_FXRegistry.RS_FXAXIS_SOUND, owner);
	}
	void SetAxisCasing(string c, string owner)
	{
		if (c == "") return;
		AffixCasing = c;
		SetAxisOwner(RS_FXRegistry.RS_FXAXIS_CASING, owner);
	}

	// Clear one axis, but ONLY if this owner holds it.
	void ReleaseAxis(int axis, string owner)
	{
		if (GetAxisOwner(axis) != owner) return;
		if (axis == RS_FXRegistry.RS_FXAXIS_PROJECTILE) AffixProjectile      = null;
		else if (axis == RS_FXRegistry.RS_FXAXIS_PUFF)  AffixImpactPuff      = null;
		else if (axis == RS_FXRegistry.RS_FXAXIS_SPARKS)AffixImpactSparks    = null;
		else if (axis == RS_FXRegistry.RS_FXAXIS_SMOKE) AffixMuzzleSmoke     = null;
		else if (axis == RS_FXRegistry.RS_FXAXIS_MUZZLE)AffixMuzzleFlash     = null;
		else if (axis == RS_FXRegistry.RS_FXAXIS_TRAIL) AffixTrail           = null;
		else if (axis == RS_FXRegistry.RS_FXAXIS_PAYLOAD) AffixExplosionVisual = null;
		else if (axis == RS_FXRegistry.RS_FXAXIS_CASING) AffixCasing         = "";
		else if (axis == RS_FXRegistry.RS_FXAXIS_SOUND)
		{
			AffixFireSound      = "";
			AffixExtraFireSound = "";
		}
		SetAxisOwner(axis, "");
	}

	// Everything one owner holds. This is what a system's uninstall
	// should call -- never ClearAffixParts.
	void ReleaseAxesBy(string owner)
	{
		for (int a = 0; a < AXIS_SLOTS; a++)
			ReleaseAxis(a, owner);
	}

	// THE NUKE. Every axis regardless of owner, ledger included.
	//
	// ZERO CALLERS, and that is the correct state -- checked, not
	// assumed. The one path that plausibly wants it is the promotion
	// strip, and RS_GunBonsaiBridge does not use it: it calls
	// info.upgrades.OnDeactivate() and then clears the bag, so every
	// affix releases its own axes on the way out and the gun ends bare
	// without anything having to reach past an owner.
	//
	// Kept as a backstop for a future caller that genuinely wants the
	// whole gun reset in one move -- a debug command, a respec-all. Any
	// system undoing its OWN work wants ReleaseAxesBy instead, and
	// reaching for this by mistake is precisely the bug that made the
	// ledger necessary.
	void ClearAffixParts()
	{
		AffixProjectile      = null;
		AffixFireSound       = "";
		AffixExtraFireSound  = "";
		AffixImpactPuff      = null;
		AffixImpactSparks    = null;
		AffixMuzzleSmoke     = null;
		AffixMuzzleFlash     = null;
		AffixTrail           = null;
		AffixExplosionVisual = null;
		AffixCasing          = "";
		for (int a = 0; a < AXIS_SLOTS; a++) mAxisOwner[a] = "";
	}

	// -----------------------------------------------------------------
	// THE GUN'S OWN 8 -- the identity layer (owner ruling, this session).
	// -----------------------------------------------------------------
	// rs_05 lists 8 presentation axes and says every one should be a
	// deliberate choice. Four of them already resolved to something real
	// when a profile left them blank (projectile/puff/sparks/trail); the
	// other four resolved to NOTHING -- blank sound meant a silent gun,
	// blank casing meant no brass, blank smoke meant no smoke.
	//
	// Measured before this existed: of 45 weapons that build profiles,
	// 42 set a fire sound, 19 set a casing, and ZERO set barrel smoke.
	// So 26 guns ejected nothing when fired and no gun in the arsenal
	// ever smoked. Worse, a profile ADDED later (a GunBonsai beat, an
	// affix, a monster attack worn by a weapon) starts blank in all
	// eight -- so the added shot fired silently off a gun that sounds
	// fine on its own beat.
	//
	// THE RULE: a gun always presents as itself. A shot may ADD to that
	// or name its own part, but leaving an axis blank can never subtract
	// the gun's identity. Resolution order, highest first:
	//
	//     affix  ->  the shot's own  ->  THE GUN'S  ->  catalog default
	//
	// Resolved at FIRE time, not baked in at build time, because affixes
	// rewrite slots at runtime and GetEffectiveFireSound already works
	// this way (a sound-choice cvar change takes effect on the next shot,
	// not on re-equip). ResolveGunAxes() below is the one place it lives.
	sound        GunFireSound;
	string       GunCasing;
	bool         GunBigMuzzle;
	Class<Actor> GunMuzzleSmoke;
	Class<Actor> GunImpactPuff;
	Class<Actor> GunImpactSparks;
	Class<Actor> GunTrail;
	// The 8th, ProjectileClass, already lived on the weapon and already
	// worked exactly this way -- it is the precedent the other seven are
	// being brought in line with, not a new field.

	// Capture the gun's identity from the beat it SHIPS with, then fill
	// anything that beat left blank from the catalog. Called once, after
	// BuildAttackProfiles(), so it reads the weapon's authored intent
	// rather than whatever an affix later did to slot 0.
	void CaptureGunAxes()
	{
		let own = PrimarySlot ? PrimarySlot.PeekAt(0) : null;
		if (own)
		{
			GunFireSound    = own.FireSound;
			GunCasing       = own.CasingClass;
			GunBigMuzzle    = own.BigMuzzle;
			GunMuzzleSmoke  = own.MuzzleSmoke;
			GunImpactPuff   = own.ImpactPuff;
			GunImpactSparks = own.ImpactSparks;
			GunTrail        = own.Trail;
		}

		// Brass and barrel smoke only make sense on a gun that fires
		// rounds. A rocket launcher, a plasma rifle and a fist eject
		// nothing and smoke from no barrel, so the default is scoped to
		// the two modes that chamber something -- that is why this reads
		// the shipping beat's Mode rather than defaulting universally.
		bool chambers = false;
		if (own)
			chambers = (own.Mode == RS_ATK_BULLET || own.Mode == RS_ATK_HITSCAN);
		if (chambers && GunCasing == "")
			GunCasing = RS_Catalog.CASING_Small();
	}

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

	// Tic of the last committed trigger pull (including backfires -- the
	// gun still went bang). 0 = never fired. Read by the resolver for
	// Overcharged's Focus Mastery ("first shot after a deliberate pause
	// pays no spread penalty"); stamped by A_RS_FireSlot.
	int RS_LastShotTic;

	// Momentum (wave D2): consecutive crits landed. Incremented on a
	// crit, reset the moment a shot doesn't crit -- read by the resolver
	// to build the chain bonus. Lives on the weapon so each hand keeps
	// its own streak.
	int RS_CritStreak;

	// Did THIS pull of the trigger crit? Set by the dispatch below, read
	// by both fire paths so the rounds they spawn can be marked in
	// flight (see RS_CritMark in zscript/systems/weapon/RS_Crits.zs).
	//
	// A FIELD RATHER THAN A PARAMETER, deliberately. The crit is rolled
	// once in the dispatch and the result is already folded into `dmg`
	// before either RS_FireProfile* is called -- so by the time a
	// projectile is spawned, nothing downstream can tell a critical shot
	// from an ordinary one that happened to roll high damage. Threading a
	// bool through both signatures would touch every call site and every
	// override; both functions are methods on this class and can simply
	// read it.
	//
	// Lives on the WEAPON, so each hand keeps its own answer -- same
	// reason RS_CritStreak does.
	bool RS_ShotWasCrit;

	// -----------------------------------------------------------------
	// ALLCLEAR (rs_11) -- the ready-to-fire beep. ONE imported sound
	// (rs_allclear_ready, the li-gnrcwpn plasma beep -- the owner's own
	// prototype pattern), given per-archetype identity purely through
	// pitch. Audio-only ON PURPOSE: VR, 3D weapon models, nothing is
	// ever drawn on the weapon or screen.
	//
	// Pitch <= 0 means NO AllClear for that archetype: the shotgun family's
	// pump/break action IS its tell (you physically can't fire early),
	// and melee has no cadence worth signalling.
	// -----------------------------------------------------------------
	double AllClearPitch()
	{
		string arch = GetPaletteArchetype();
		if (arch == "shotgun")       return 0;
		if (arch == "supershotgun")  return 0;
		if (arch == "melee")         return 0;
		if (arch == "pistol")        return 1.30;
		if (arch == "revolver")      return 1.15;
		if (arch == "rifle")         return 1.00;
		if (arch == "smg")           return 1.45;
		if (arch == "chaingun")      return 1.35;
		if (arch == "railgun")       return 0.80;
		if (arch == "launcher")      return 0.70;
		if (arch == "energy")        return 1.00;   // the original beep, unshifted
		if (arch == "bfg")           return 0.55;
		if (arch == "flamethrower")  return 0.90;
		return 1.0;   // unmapped archetype: neutral beep beats silence
	}

	// Fires AllClear at the exact tic the weapon's cadence reopens --
	// once per fire cycle, only while this weapon is in a hand. DoEffect
	// ticks on the owner every game tic while the weapon is possessed;
	// NextFireTic is stamped by A_RS_MarkFired on every committed shot,
	// so equality happens exactly once per cycle (and never on a weapon
	// that hasn't fired: NextFireTic 0 is always in the past).
	override void DoEffect()
	{
		Super.DoEffect();
		if (!owner || !owner.player) return;
		if (owner.player.ReadyWeapon != self && owner.player.OffhandWeapon != self)
			return;
		RetimeReload();
		if (NextFireTic == 0 || Level.maptime != NextFireTic) return;
		// Held-trigger guard (rs_14 survey, F1): a held full-auto weapon
		// refires the instant its cadence reopens -- a beep every cycle
		// would be 35/sec noise on the GH Minigun. The tell exists for a
		// WAITING trigger finger, so a held trigger silences it.
		//
		// PER-HAND, same reason as A_RS_ClearTriggerGate above: this read
		// BT_ATTACK for both hands until 2026-08-07, so an offhand
		// full-auto beeped every cycle while its own trigger was held
		// (the exact noise this guard exists to stop), and a held MAIN
		// trigger wrongly silenced the offhand's legitimate beep.
		int trigger = bOffhandWeapon ? BT_OFFHANDATTACK : BT_ATTACK;
		if (owner.player.cmd.buttons & trigger) return;
		if (!CVar.GetCVar("rs_allclear_enable", owner.player).GetBool()) return;

		double pitch = AllClearPitch();
		if (pitch <= 0) return;
		owner.A_StartSound("rs_allclear_ready", CHAN_AUTO, CHANF_DEFAULT, 0.65,
			ATTN_NORM, pitch);
	}

	// Does any beat on ANY slot run in the given RS_ATK_* mode?
	// Suitability gate for designed affixes -- Splitter wants a bullet
	// or hitscan beat, Ghost a bullet beat, etc.
	//
	// Was `s < 2` and is now RS_SLOT_COUNT. Left at 2 it could not see
	// the modifier slots, so a gun whose ONLY bullet beat lived on
	// modifier-fire would be judged to have none and every affix gating
	// on HasBeatMode would refuse to offer -- silently, since a card
	// that declines to appear looks identical to a card you were simply
	// unlucky not to roll.
	bool HasBeatMode(int mode)
	{
		for (int s = 0; s < RS_SLOT_COUNT; s++)
		{
			let slot = GetSlot(s);
			if (!slot) continue;
			for (int i = 0; i < slot.Count(); i++)
			{
				let prof = slot.PeekAt(i);
				if (prof && prof.Mode == mode)
					return true;
			}
		}
		return false;
	}

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
		return Level.maptime >= invoker.NextFireTic;
	}

	// How many tics the last shot came early by, relative to
	// TimeBetweenShots -- 0 if the shot was at or slower than the
	// weapon's real cadence. Used to compute an accuracy penalty, not
	// to block firing; the semi-auto release gate above is the only
	// hard block. Firing faster than intended costs Accuracy instead.
	action int GetCadenceOvershoot()
	{
		int shortfall = invoker.NextFireTic - Level.maptime;
		return max(0, shortfall);
	}

	// Called once per shot fired, by every weapon type, semi-auto or
	// full-auto alike -- sets the release gate and records when the
	// weapon's real cadence next expects a shot.
	action void A_RS_MarkFired()
	{
		invoker.bWaitingForRelease = true;
		// ONE CLOCK: Level.maptime, everywhere in the cadence system.
		//
		// This stamped from level.time while DoEffect compared against
		// Level.maptime (and AutoCooldownReady / GetCadenceOvershoot read
		// level.time too). They are identical on a single-map run, so it
		// tested clean forever -- and diverge in a HUB, where level.time
		// is the accumulated total and maptime restarts per map. After
		// one hub transition the equality in DoEffect could never be
		// satisfied again and the AllClear beep went permanently silent,
		// with the full-auto cooldown gate reading a different clock than
		// the thing that set it. Unified 2026-08-07.
		// ROUND, DON'T TRUNCATE. Fixed 2026-08-07.
		//
		// This was int(...), which floors. Tics are integers, so any
		// rate of fire that does not divide 35 evenly came out FASTER
		// than the sheet claimed -- Plasma's ROF 9 is 3.89 tics, floored
		// to 3, so it actually fired at 11.7/sec against a stated 9. The
		// error is always in the same direction (never slower), so every
		// non-dividing weapon in the arsenal has been quietly
		// out-shooting its own displayed stat.
		//
		// Rounding costs nothing and is right to within half a tic.
		invoker.NextFireTic = Level.maptime
			+ max(1, int(round(invoker.GetTimeBetweenShots() * 35)));
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
	// Bonus rounds are ReloadSpeed's OVERFLOW (owner ruling, rs_32 D1):
	// the stat's first stretch buys visible animation speed (clamped
	// [0.7, 1.5] in RetimeReload), everything past the visual cap buys
	// ammo instead -- hands so fast they thumb in an extra round. With
	// stock rolls capping ~1.4 this pays only once reload cards push the
	// stat past 1.5; that is the ruling, not an accident.
	action int GetReloadBonusRounds()
	{
		return max(0, int((invoker.ReloadSpeed - 1.5) * 4));
	}

	// --- ReloadSpeed -> reload animation retimer (owner rulings, rs_32
	// D1: "clamp the animation not the stat"). While this weapon's
	// psprite walks its own Reload sequence, each new frame's duration
	// is rescaled by the clamped stat -- a 1.3 roll visibly reloads
	// ~30% faster, a 0.85 roll slower, and the 3D model tracks because
	// the frames themselves are unchanged. Drives BOTH hands: the fork
	// renders the offhand through its own psprite layer
	// (PSP_OFFHANDWEAPON, engine p_pspr.h), same ticking machinery.
	// v1 is retime-only: a 1-tic frame can't be shortened further and
	// is left alone rather than skipped -- arsenal reload frames are
	// 2-6 tics, so the clamp's full range is expressible without
	// mid-tick state surgery.
	state RS_ReloadTrackState;

	void RetimeReload()
	{
		bool isOff = owner.player.OffhandWeapon == self;
		let psp = owner.player.FindPSprite(isOff ? PSP_OFFHANDWEAPON : PSP_WEAPON);
		if (!psp)
		{
			RS_ReloadTrackState = null;
			return;
		}

		state reload = FindState("Reload");
		if (!reload || !InStateSequence(psp.CurState, reload))
		{
			RS_ReloadTrackState = null;
			return;
		}

		// Retime each frame once, on entry.
		if (psp.CurState == RS_ReloadTrackState)
			return;
		RS_ReloadTrackState = psp.CurState;

		double speed = clamp(ReloadSpeed, 0.7, 1.5);
		if (psp.Tics > 0 && speed != 1.0)
			psp.Tics = max(1, int(round(psp.Tics / speed)));
	}

	// HAND-AWARE. The offhand fires on BT_OFFHANDATTACK, never BT_ATTACK
	// (engine player.zs:463-479 -- the offhand path sets its own bit and
	// does not touch BT_ATTACK). Testing BT_ATTACK for both hands, which
	// this did until 2026-08-07, broke every offhand semi-auto in two
	// opposite ways at once: holding the OFFHAND trigger left BT_ATTACK
	// up, so the gate cleared every Ready tic and the gun went full-auto;
	// holding the MAIN trigger held BT_ATTACK down, so the offhand gate
	// never cleared and the gun fired once then locked until you let go
	// of the other hand.
	action void A_RS_ClearTriggerGate()
	{
		// Inlined deliberately -- do NOT factor this back out into an
		// `action` helper. Inside an action function `self` is the PAWN
		// and `invoker` is the weapon, so an unqualified call to a second
		// action function leans on invoker-chaining that is subtle at
		// best. This runs from every weapon's Ready state, every tic, on
		// both hands; it is the last place in the mod that should be
		// clever. One ternary, read straight off invoker.
		int trigger = invoker.bOffhandWeapon ? BT_OFFHANDATTACK : BT_ATTACK;
		if (!(player.cmd.buttons & trigger))
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

		// Overflow feeds the shell chance too: past the animation cap,
		// each point of stat adds itself to the free-shell odds.
		if (invoker.GetReloadBonusRounds() > 0
			&& FRandom(0, 1) < (bonusChance + max(0, invoker.ReloadSpeed - 1.5))
			&& CountInv(invoker.AmmoType2) < invoker.Capacity && CountInv(reserve) > 0)
		{
			GiveInventory(invoker.AmmoType2, 1);
			TakeInventory(reserve, 1);
		}
	}

	// Called from each weapon's Flash: state, in 43 places. DELIBERATELY
	// DOES NOTHING NOW -- owner ruling 2026-08-11: RS_Main never emits a
	// muzzle light of its own; that is GlowInTheDark's job, always.
	//
	// What it used to do, and why it had to stop:
	//
	//   RS_HiFiFX.SpawnMuzzleLight(self)
	//     -> shooter.A_SpawnItemEx("RS_MuzzleLight", 0,0,0, ...)
	//
	// `self` in a weapon action function is the PLAYER PAWN, and an
	// actor's origin is at its FEET. So every shot spawned an
	// unattenuated 72-116 unit PointLight at the player's feet, which in
	// play reads as the floor lighting up around you rather than a flash
	// on what you are shooting. Worst on the pistol, purely because of
	// fire rate. The smoke in the same file spawns at Height * 0.5 and
	// was always correct; the light took the wrong convention and the
	// file's own header admits it was "a first-pass guess, meant to be
	// tuned once actually seen in a headset". It never was.
	//
	// Kept as an empty function rather than removed because 43 weapon
	// Flash: states call it. Emptying it here turns all 43 off at once
	// and leaves the hook available if a per-weapon flash is ever wanted.
	//
	// A beat that explicitly names a MuzzleFlash still gets one -- see
	// the shot path, which has the profile in hand and this does not.
	action void A_RS_MuzzleFlash()
	{
	}

	// =================================================================
	// ATTACK SLOTS -- the assembly system. See RS_AttackProfile.zs for
	// the full rationale; the short version:
	//
	//   FOUR slots, one per input:
	//     0 primary    = fire
	//     1 secondary  = alt-fire
	//     2 tertiary   = modifier + fire
	//     3 quaternary = modifier + alt-fire
	//   Each slot is an ordered LIST of RS_AttackProfile plus a cursor.
	//   Firing a slot fires the profile at the cursor, then advances.
	//
	// WHY FOUR AND NOT TWO. Two slots meant every added attack had to
	// share a trigger with the gun's own shot and arrive on a counter --
	// "every 3rd shot is a grenade" instead of "alt-fire is a grenade".
	// Two things were wrong with that. You could never save the big shot
	// for the big target, because the gun decided when it came out. And
	// a beat sharing a trigger inherits that trigger's cadence, so a
	// rocket in a chaingun's primary fires at chaingun speed.
	//
	// Rotation is NOT replaced by this -- it lives inside every one of
	// the four slots exactly as before. An affix can still say "every 3rd
	// shot", and can now equally say "every 3rd ALT-fire" or "every 2nd
	// modifier-fire". The slot is the input; the rotation is the pattern
	// within that input. Both dimensions, instead of one.
	//
	// Every weapon in both the main arsenal and the GH set now authors
	// BuildAttackProfiles() and fires exclusively through A_RS_FireSlot;
	// the old per-weapon direct-fire path this migration replaced is
	// gone. A weapon that somehow ships without BuildAttackProfiles()
	// just has empty slots and A_RS_FireSlot does nothing. The same is
	// true per-slot: a weapon that authors nothing into slot 2 or 3 has
	// no modifier attacks until an affix installs one, which is the
	// normal case for every weapon that exists today.
	// =================================================================

	const RS_SLOT_PRIMARY    = 0;
	const RS_SLOT_SECONDARY  = 1;
	const RS_SLOT_TERTIARY   = 2;   // modifier + fire
	const RS_SLOT_QUATERNARY = 3;   // modifier + alt-fire
	const RS_SLOT_COUNT      = 4;

	RS_AttackSlot PrimarySlot;
	RS_AttackSlot SecondarySlot;
	RS_AttackSlot TertiarySlot;
	RS_AttackSlot QuaternarySlot;

	RS_AttackSlot GetSlot(int which)
	{
		if (which == RS_SLOT_SECONDARY)  return SecondarySlot;
		if (which == RS_SLOT_TERTIARY)   return TertiarySlot;
		if (which == RS_SLOT_QUATERNARY) return QuaternarySlot;
		return PrimarySlot;
	}

	// True if this slot has anything to fire. The dispatcher uses it to
	// fall back: pressing modifier+fire on a gun with an empty slot 2
	// should fire normally rather than do nothing, so the modifier is
	// never a dead key.
	bool SlotHasContent(int which)
	{
		let s = GetSlot(which);
		return s && !s.IsEmpty();
	}

	// The slot an input should actually fire, after falling back. Base is
	// 0 or 1; held is whether the modifier is down.
	int ResolveSlot(int base, bool held)
	{
		if (!held) return base;
		int want = base + 2;                       // 0->2, 1->3
		return SlotHasContent(want) ? want : base;
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

	// Same, but the padding carries an owner so the installer can take it
	// back. Anything installing a rotation beat wants THIS -- unowned
	// padding is permanent, and permanent padding means a card's "every
	// Nth shot" is frozen at whatever its first install produced. See
	// RS_AttackSlot.PadToOwned for the full walk-through.
	void PadSlotToOwned(int which, int length, string ownerTag)
	{
		let s = GetSlot(which);
		if (!s) return;
		let filler = s.PeekAt(0);
		if (filler) s.PadToOwned(length, filler, ownerTag);
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
		// MODIFIER RESOLUTION, done here rather than at the call sites.
		// There are ~60 A_RS_FireSlot calls across 46 weapon files; doing
		// this in the dispatcher means every weapon gains modifier
		// attacks the moment an affix installs one, with no weapon file
		// touched and no chance of one being missed.
		//
		// Only bases 0 and 1 resolve. An explicit A_RS_FireSlot(2) means
		// "fire slot 2", not "resolve from slot 2".
		if (which <= RS_SLOT_SECONDARY && player)
		{
			bool held = (player.original_cmd.buttons & BT_USER2) != 0;
			which = invoker.ResolveSlot(which, held);
		}

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

		// PLAYER CURSE: `hungry` -- this hand eats multiplied ammo.
		// Resolved BEFORE the affordability check, so a hungry hand can
		// genuinely run dry on a shot a clean hand would have made.
		int hand = invoker.bOffhandWeapon ? RS_Curse.HAND_OFF : RS_Curse.HAND_MAIN;
		int ammoCost = p.AmmoCost;
		if (ammoCost > 0 && RS_CurseLedger.Has(self, RS_Curse.FLAW_HUNGRY, hand))
			ammoCost = max(1, ammoCost * RS_Curse.CVInt("rs_curse_hungry_mult", 200) / 100);

		// LIFT REWARD, `hungry` cured: ammo efficiency. A shot has a
		// chance to cost nothing -- the only shape that can express "a
		// bit cheaper" when the cost is an integer, usually 1.
		double effBonus = RS_CurseLedger.BonusFor(self, RS_Curse.FLAW_HUNGRY, hand);
		if (ammoCost > 0 && effBonus > 0 && FRandom(0, 1) < effBonus)
			ammoCost = 0;

		if (pool && ammoCost > 0 && CountInv(pool) < ammoCost)
			return false;

		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		// PLAYER CURSE: `jam-prone` -- flat percentage points of backfire
		// added to whatever Condition already produced, INDEPENDENT of
		// Condition. A pristine weapon in a cursed hand still jams; that
		// is the difference between this and simply being worn out.
		if (RS_CurseLedger.Has(self, RS_Curse.FLAW_JAMPRONE, hand))
			backfireChance += RS_Curse.CVInt("rs_curse_jam_add", 12) / 100.0;

		// LIFT REWARD, `jam-prone` cured: the hand is steadier than it
		// ever was. Multiplies DOWN whatever backfire chance Condition
		// produced, so it stays useful at any state of repair rather than
		// only mattering on a worn weapon.
		double jamCured = RS_CurseLedger.BonusFor(self, RS_Curse.FLAW_JAMPRONE, hand);
		if (jamCured > 0)
			backfireChance *= max(0.0, 1.0 - jamCured);

		// Granted-keyword layer -- composes with Condition, doesn't
		// replace it. An affix's whole job is wpn.GrantKeyword(...) /
		// p.GrantLocal(...); this one resolved bundle is what turns that
		// into a different-feeling shot, every time, without touching the
		// shared profile object. One container instead of per-axis
		// out-params so new behavior/drawback values never change this
		// call site again.
		let mods = RS_ShotKeywordMods.Resolve(invoker, p);
		dmgMult *= mods.DmgMult;
		pelletMult *= mods.PelletMult;

		// Backfire eats the ammo and the shot but does NOT advance the
		// rotation -- a jam shouldn't cost you your place in the cycle.
		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			if (pool && p.AmmoCost > 0)
				TakeInventory(pool, p.AmmoCost);
			invoker.RS_LastShotTic = Level.maptime;
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
		// Crit, plus whatever Momentum's chain has built up. The streak
		// is tracked here because this is the one place that knows
		// whether a pull actually critted.
		if (FRandom(0, 1) < (invoker.CritChance + p.CritBonus + mods.CritAdd))
		{
			dmg *= invoker.CritMult > 0 ? invoker.CritMult : 2.0;
			invoker.RS_CritStreak++;
			invoker.RS_ShotWasCrit = true;
		}
		else
		{
			invoker.RS_CritStreak = 0;
			// Must be cleared, not just set -- it is a field, so a crit
			// left standing would mark every subsequent round until the
			// next crit happened to reset it.
			invoker.RS_ShotWasCrit = false;
		}

		int pellets = (p.PelletOverride > 0) ? p.PelletOverride : invoker.PelletCount;
		pellets = max(1, int(pellets * pelletMult));

		// Choke keys off the RESOLVED volley, not a per-profile opt-in --
		// owner ruling 2026-08-05: "choke should work on anything with
		// more than 1 pellet for any reason" (rolled, promoted,
		// affix-split, condition-doubled). UsesChoke is no longer read.
		double choke = (pellets >= 2 && invoker.Choke > 0) ? (1.0 - invoker.Choke * 0.5) : 1.0;
		double spread = (100.0 - invoker.Accuracy) * p.SpreadScale * choke + p.SpreadBonus;
		if (p.UsesCadence)
		{
			int overshoot = invoker.GetCadenceOvershoot();
			if (overshoot > 0)
			{
				// Fired before the sequence finished: the standing penalty.
				spread += overshoot * 0.15;
			}
			else
			{
				// Waited the full firing sequence out: the patience bonus
				// (owner ruling 2026-08-05 -- 40% tighter by default,
				// scalable). Semi-auto only by construction: full-auto
				// profiles leave UsesCadence false because the hard gate
				// does their pacing, so they can't collect this for free.
				spread *= 1.0 - clamp(CVar.FindCVar("rs_cadence_patience").GetInt(), 0, 90) / 100.0;
			}
		}
		spread *= mods.SpreadMult;

		// Hitscan and melee run inline because A_FireBullets/A_CustomPunch
		// are action functions -- they can't be reached from the play-scope
		// helpers the projectile modes use.
		if (p.Mode == RS_ATK_HITSCAN)
		{
			// Same four-rung chain as the other two paths. The final
			// default was the literal vanilla "bulletpuff" string rather
			// than the catalog's own entry -- rs_05 flagged that as a real
			// inconsistency and left it; it is closed here, so hitscan and
			// bullet impacts now land on the same puff.
			Class<Actor> hitscanPuff = invoker.AffixImpactPuff;
			if (!hitscanPuff) hitscanPuff = p.ImpactPuff;
			if (!hitscanPuff) hitscanPuff = invoker.GunImpactPuff;
			if (!hitscanPuff) hitscanPuff = RS_Catalog.PUFF_Bullet();
			if (!hitscanPuff) hitscanPuff = "bulletpuff";
			if (mods.MasteryFan && pellets > 1)
			{
				// Splitter Mastery: deterministic even fan instead of
				// random scatter. A_FireBullets can't do fixed per-pellet
				// angles, so aim the player for each trace and restore.
				double fanSpread = spread * 1.25;
				double baseAngle = angle;
				for (int i = 0; i < pellets; i++)
				{
					angle = baseAngle - fanSpread + (2.0 * fanSpread) * i / double(pellets - 1);
					A_FireBullets(0, 0, 1, int(dmg), hitscanPuff, FBF_NORANDOM);
				}
				angle = baseAngle;
			}
			else
				A_FireBullets(spread, spread, pellets, int(dmg), hitscanPuff, FBF_NORANDOM);
		}
		else if (p.Mode == RS_ATK_MELEE)
		{
			Class<Actor> puff = p.MeleePuff;
			if (!puff) puff = "BulletPuff";
			// norandom=TRUE. `dmg` already has Condition, crit and every
			// keyword multiplier folded in; it IS the number that should
			// land. This passed false until 2026-08-07, and the engine
			// then did `damage *= random(1,8)` on top of all of it
			// (stateprovider.zs:332-333) -- so every fist and chainsaw
			// swing was 1x to 8x the sheet, with a crit multiplying
			// underneath the random. The hitscan branch six lines up
			// already passes FBF_NORANDOM for exactly this reason; melee
			// was the one mode that never got the memo.
			A_CustomPunch(int(dmg), true, 0, puff, p.MeleeRange);
		}
		else if (p.Mode == RS_ATK_HEAVY)
		{
			invoker.RS_FireProfileHeavy(self, p, dmg, pellets, mods.Homing);
		}
		else
		{
			invoker.RS_FireProfileBullet(self, p, dmg, pellets, spread, mods);
		}

		// --- THE 8 AXES, RESOLVED --------------------------------------
		// Precedence, highest first, same on every axis:
		//     affix  ->  the shot's own  ->  THE GUN'S  ->  catalog default
		// A blank axis on the shot can never subtract the gun's identity.
		// Before the gun rung existed, a shot that named no sound fired
		// SILENTLY and one that named no casing ejected NOTHING -- which
		// is what every profile added after ship (GunBonsai beats, affix
		// beats, a monster attack worn by a weapon) looked like.
		sound fxSound = p.FireSound;
		if (!fxSound) fxSound = invoker.GunFireSound;
		if (fxSound)
			A_PlaySound(invoker.GetEffectiveFireSound(fxSound), CHAN_WEAPON);

		// LAYERED, NOT PRECEDENCE. Every other axis on this shot follows
		// the "highest rung wins, replaces everything below" rule stated
		// two blocks up -- this is deliberately the one exception. Owner,
		// 2026-08-08: a shotgun firing a caco-themed beat should sound
		// like a shotgun, PLUS whatever the beat itself is (a fireball
		// whoosh, a lightning crack, a plasma sizzle), not one silencing
		// the other. A second A_PlaySound on a DIFFERENT channel from
		// fxSound's CHAN_WEAPON, so ZDoom's per-channel one-sound-at-a-
		// time behaviour can't let this steal or be stolen by the gun's
		// own report -- both are audible together, which is the entire
		// point.
		// Both layered sources play. The profile's is the PACK beat's own
		// theme; the weapon's is an affix installed on the gun. They are
		// independent and an affix should not silence a themed beat, so
		// they get separate channels rather than one winning.
		if (p.ExtraFireSound)
			A_PlaySound(p.ExtraFireSound, CHAN_ITEM);
		if (invoker.AffixExtraFireSound)
			A_PlaySound(invoker.AffixExtraFireSound, CHAN_7);

		Class<Actor> fxSmoke = invoker.AffixMuzzleSmoke;
		if (!fxSmoke) fxSmoke = p.MuzzleSmoke;
		if (!fxSmoke) fxSmoke = invoker.GunMuzzleSmoke;
		// Worn guns smoke on every shot regardless of tier rules -- the
		// condition state made audible-visible at the muzzle. GunBigMuzzle
		// is OR'd rather than used as a fallback on purpose: the gun's
		// flash is a FLOOR, so a beat that says nothing still flashes.
		RS_HiFiFX.MuzzleEffects(self, p.BigMuzzle || invoker.GunBigMuzzle || invoker.Condition < 50.0, fxSmoke);

		// MUZZLE AXIS, light half. Affix first, then the beat -- and NO
		// gun fallback, deliberately. The gun defers to GlowInTheDark;
		// only a card or a beat that explicitly names a flash gets one,
		// and when it does it LAYERS with GITD rather than replacing it.
		Class<Actor> fxFlash = invoker.AffixMuzzleFlash;
		if (!fxFlash) fxFlash = p.MuzzleFlash;
		if (fxFlash)
			RS_HiFiFX.BeatMuzzleFlash(self, fxFlash);

		// Casing sentinel: AffixCasing "" = no override, "none" = suppress
		// entirely. "none" stays the one deliberate way to eject nothing --
		// without it, blank and "deliberately empty" are indistinguishable.
		string fxCasing = p.CasingClass;
		if (fxCasing == "") fxCasing = invoker.GunCasing;
		if (invoker.AffixCasing != "")
			fxCasing = (invoker.AffixCasing ~== "none") ? "" : invoker.AffixCasing;
		if (fxCasing != "")
			RS_HiFiFX.CasingEject(self, fxCasing);

		invoker.RS_LastShotTic = Level.maptime;

		// WHICH HAND FIRED LAST. Stamped here because this is the one
		// place that knows for certain, for every Mode, on both hands --
		// the same reason RS_GunBonsaiBridge.NotifyFired sits here.
		//
		// Read by the death hook (RS_ScoreRevival) to decide which hand a
		// player curse lands on: "whatever gun you fired last".
		RS_Weapon.StampFiringHand(self, invoker.bOffhandWeapon);

		A_RS_MarkFired();
		return true;
	}

	// The stamp itself. A static on the weapon rather than a field on the
	// pawn, so it works for any PlayerPawn subclass without requiring one
	// -- the GH/PS Weaponset classes are not VR_DualClassBase.
	//
	// Stored on the curse ledger because that is the one per-player object
	// guaranteed to exist for the whole run and already reachable from
	// both the fire path and the damage hook.
	static void StampFiringHand(Actor pawn, bool offhand)
	{
		if (!pawn) return;
		let led = RS_CurseLedger.Fetch(pawn);
		if (!led) return;

		int hand = offhand ? RS_Curse.HAND_OFF : RS_Curse.HAND_MAIN;
		led.mLastFiredHand = hand;

		// PLAYER CURSE: `loud` -- each shot from this hand deafens you
		// briefly. Owner ruling 2026-08-07: "loud drops the player's
		// hearing for two tics after each shot. music is unaffected."
		if (led.IsActive(RS_Curse.SlotOf(RS_Curse.FLAW_LOUD, hand)))
			led.Deafen();
	}

	// -----------------------------------------------------------------
	// WHICH GUN LANDED THIS HIT -- answered at the moment of IMPACT, not
	// at the moment of firing.
	//
	// Damage numbers need two things this file already owns and nothing
	// downstream of the trigger can otherwise see: whether the pull
	// critted (RS_ShotWasCrit) and which hand it came from
	// (bOffhandWeapon). Both live on the weapon, so the whole problem is
	// getting from an inflictor back to the gun.
	//
	// `master` is that route and it is exact: every spawn site in this
	// file stamps `proj.master = self`, it is per round rather than per
	// pull, and it survives however long the round is in the air. It is
	// already documented above as the sacred pointer because GunBonsai
	// attributes XP through it -- this reads it and changes nothing.
	//
	// HITSCAN PUFFS AND MELEE CARRY NO MASTER (the engine spawns them,
	// not us), so those fall back to whichever of the two held weapons
	// fired most recently. RS_LastShotTic is stamped by A_RS_FireSlot on
	// both hands, so the comparison is real rather than a guess at which
	// hand is "the" hand.
	//
	// Returns null when nothing here fired it -- monster damage, floor
	// damage, crushers. Callers must expect that.
	//
	// KNOWN AND ACCEPTED IMPRECISION: RS_ShotWasCrit is the state of the
	// LAST pull from that gun, not a record carried by this individual
	// round. For a bullet that is the same thing -- these are
	// FastProjectiles, they cross a room in a tic or two, and no weapon
	// can fire again in that window. For a slow round (a lobbed grenade,
	// a rocket at low velocity) a second pull can land between the shot
	// and its impact and flip the answer. Fixing it properly means a
	// bool on the projectile, which is a field on a class this file does
	// not own; it is worth doing when that file is next opened for
	// another reason, and it is not worth opening it for this alone.
	// -----------------------------------------------------------------
	static RS_Weapon FiringWeaponOf(Actor inflictor, Actor source)
	{
		if (inflictor)
		{
			let w = RS_Weapon(inflictor.master);
			if (w)
				return w;
		}

		if (!source || !source.player)
			return null;

		let mainW = RS_Weapon(source.player.ReadyWeapon);
		let offW  = RS_Weapon(source.player.OffhandWeapon);
		if (!offW)
			return mainW;
		if (!mainW)
			return offW;
		return (offW.RS_LastShotTic > mainW.RS_LastShotTic) ? offW : mainW;
	}

	// Condition backfire -- was an identical copy on all 11 weapons.
	// Same DamagePerShot + crit roll a normal shot gets.
	action void A_RS_Backfire()
	{
		A_PlaySound("rs_fx_weapon_empty", CHAN_WEAPON);
		// The price reads the VOLLEY the jam ate, not the per-pellet
		// number: DamagePerShot is per-pellet on the shotgun family and
		// per-round on the heavies, so the raw stat made a backfire cost
		// an SSG 5-12 and a launcher 110-320 at identical odds -- a free
		// gamble on one end of the arsenal and a death sentence on the
		// other. A quarter of the volley's worth lands both in the same
		// survivable band and keeps the price proportional to what the
		// shot would have been.
		double dmg = invoker.DamagePerShot * max(1, invoker.PelletCount) * 0.25;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= invoker.CritMult > 0 ? invoker.CritMult : 2.0;
		player.mo.DamageMobj(invoker, player.mo, max(1, int(dmg)), 'BackfireDamage');
	}

	// Bullet volley. Damage/pellets/spread are resolved by the dispatch
	// above and passed in, so this stays a pure spawn loop -- and so the
	// same numbers the dispatch computed are the ones that actually fly.
	void RS_FireProfileBullet(Actor shooter, RS_AttackProfile p, double dmg, int pellets, double spread, RS_ShotKeywordMods mods = null)
	{
		// Part precedence, highest first: affix-installed projectile ->
		// this beat's authored class -> the weapon's own -> the default.
		// The affix override is CHECKED-CAST to the bullet base class:
		// if a part-swap affix ever installs a non-ballistic class on a
		// bullet weapon, the override is ignored instead of spawning a
		// round that silently skips SetupStats -- the exact old
		// pool bug, fenced at the one place it could re-enter.
		Class<Actor> cls = (Class<RS_BallisticFired>)(AffixProjectile);

		// Plain-Actor affix parts (RS_AffixPartActor) are the ONE class
		// of non-ballistic projectile the bullet path fires -- they exist
		// precisely because FastProjectile can't bounce, so a bouncing
		// round (Cryo's Mastery orb) must be a plain Actor. They carry
		// their own exact-damage override; they use their own authored
		// Speed (a lobbed orb at rolled bullet velocity would be a beam),
		// and skip ballistic-only features (homing/rip/trail plumbing).
		if (!cls)
		{
			Class<RS_AffixPartActor> partCls = (Class<RS_AffixPartActor>)(AffixProjectile);
			if (partCls)
			{
				RS_FireAffixPartRound(shooter, partCls, p, dmg, pellets, spread, mods);
				return;
			}
		}

		if (!cls) cls = p.ProjectileClass;
		if (!cls) cls = ProjectileClass;
		if (!cls) cls = "RS_BallisticType1";

		// STAT-STATE LADDER (rs_11): only the arsenal DEFAULT body is
		// eligible -- authored/profile/affix bodies keep their identity.
		// Condition outranks damage: a failing gun sputters no matter
		// how hot its loads are.
		if (cls == (Class<Actor>)("RS_BallisticType1"))
			cls = RS_StateLadderBody();

		int aimflags = bOffhandWeapon ? ALF_ISOFFHAND : 0;
		double vel = Velocity * p.VelocityMult * (mods ? mods.VelMult : 1.0);
		double crit = CritChance + p.CritBonus;

		// Same four-rung chain as the dispatch above: affix -> the shot's
		// own -> the gun's -> the round's built-in default. These three
		// already ended at a real default (PUFF_Bullet / SPARK_Hit /
		// TRAIL_Ballistic, inside RS_BallisticFired), so the gun rung is
		// added here for uniformity across all 8 axes -- a null still
		// lands on the same default it always did.
		Class<Actor> fxPuff  = AffixImpactPuff;
		if (!fxPuff)  fxPuff  = p.ImpactPuff;
		if (!fxPuff)  fxPuff  = GunImpactPuff;
		Class<Actor> fxSpark = AffixImpactSparks;
		if (!fxSpark) fxSpark = p.ImpactSparks;
		if (!fxSpark) fxSpark = GunImpactSparks;
		Class<Actor> fxTrail = AffixTrail;
		if (!fxTrail) fxTrail = p.Trail;
		if (!fxTrail) fxTrail = GunTrail;

		// PROJECTILE SIZE. Derived from THIS weapon's archetype unless the
		// profile forces a size, then multiplied by whatever affixes have
		// to say. This is what lets a rifle fire a Cacodemon ball at
		// bullet size without anyone authoring that pairing.
		double projScale = (p.ProjScale > 0)
			? p.ProjScale
			: RS_Catalog.ScaleForArchetype(GetPaletteArchetype());
		if (mods) projScale *= mods.ScaleMult;

		bool fan = mods && mods.MasteryFan && pellets > 1;
		double fanSpread = spread * 1.25;

		for (int i = 0; i < pellets; i++)
		{
			double a, pt;
			if (fan)
			{
				// Splitter Mastery: fixed even geometry, flat pitch. The
				// wall is readable and reliable, that's the whole point.
				a  = shooter.angle - fanSpread + (2.0 * fanSpread) * i / double(pellets - 1);
				pt = shooter.pitch;
			}
			else
			{
				a  = shooter.angle + FRandom(-spread, spread);
				pt = shooter.pitch + FRandom(-spread, spread);
			}
			let proj = RS_BallisticFired(
				shooter.SpawnPlayerMissile(cls, a, pitch: pt, aimflags: aimflags));
			if (proj)
			{
				proj.SetupStats(int(dmg), vel, crit);
				proj.SetupFeedback(fxPuff, fxSpark, fxTrail);
				RS_Catalog.ApplyProjectileScale(proj, projScale);
				// Mark it if this pull critted, so the round is visibly
				// a crit while it is still in the air. Every pellet of a
				// volley is marked -- the crit was rolled for the shot,
				// not per pellet, so marking only some would misreport it.
				if (RS_ShotWasCrit) RS_CritMark.Apply(proj);
				if (mods)
				{
					proj.Homing = mods.Homing;
					// Bonecaller mid-levels: each PELLET rolls its own
					// chance to seek -- a mixed volley of straight and
					// hunting rounds, per shot, per pellet.
					if (!proj.Homing && mods.HomingChance > 0)
						proj.Homing = FRandom(0, 1) < mods.HomingChance;
					proj.SeekLevel   = mods.SeekLevel;
					proj.SeekPrecise = mods.SeekPrecise;
					proj.SeekTurn    = mods.SeekTurn;
					proj.SprayCount  = mods.SprayCount;
					proj.SpraySeek   = mods.SpraySeek;
					// Pain Train: rolled PER PELLET, so a shotgun's spread
					// staggers a crowd probabilistically rather than
					// all-or-nothing.
					if (mods.ForcePain
						|| (mods.FlinchChance > 0 && FRandom(0, 1) < mods.FlinchChance))
						proj.bFORCEPAIN = true;
					// Native ripper -- the round passes through monsters,
					// damaging each. Real GZDoom flag, no custom logic.
					proj.bRIPPER = mods.Piercing;
					proj.PierceLimit     = mods.PierceLevel;
					proj.PierceRetention = mods.PierceRetention;
					proj.StitchOnKill    = mods.Stitch;
					if (mods.MasteryKick)
						proj.ProjectileKickback = 600;
					if (mods.MasteryIgnite)
						proj.ImpactSpawnExtra = "RS_AffixGroundFire";
				}
				// THE SACRED POINTER -- GunBonsai reads master to attribute
				// XP to the hand that actually fired. Never break it.
				proj.master = self;
			}
		}
	}

	// Which body the arsenal-default round wears, given this weapon's
	// live state. See RS_FX_StateLadder.zs for the bodies and the rule.
	Class<RS_BallisticFired> RS_StateLadderBody()
	{
		if (Condition < 20.0) return "RS_BallisticFailing";
		if (Condition < 50.0) return "RS_BallisticWorn";
		double ceilingRatio = double(DamagePerShot) / max(1, GetDamageCeiling());
		if (ceilingRatio >= 0.90) return "RS_BallisticPeak";
		if (ceilingRatio >= 0.65) return "RS_BallisticHot";
		return "RS_BallisticType1";
	}

	// The plain-Actor sibling of the loop above, for RS_AffixPartActor
	// rounds (bouncing orbs and future non-FastProjectile parts). Kept
	// deliberately lean: exact damage, scale, master pointer, and the
	// part's own authored flight -- no homing/rip/trail plumbing, which
	// all assumes RS_BallisticFired.
	void RS_FireAffixPartRound(Actor shooter, Class<RS_AffixPartActor> cls,
		RS_AttackProfile p, double dmg, int pellets, double spread,
		RS_ShotKeywordMods mods)
	{
		int aimflags = bOffhandWeapon ? ALF_ISOFFHAND : 0;
		double projScale = (p.ProjScale > 0)
			? p.ProjScale
			: RS_Catalog.ScaleForArchetype(GetPaletteArchetype());
		if (mods) projScale *= mods.ScaleMult;

		for (int i = 0; i < pellets; i++)
		{
			double a = shooter.angle + FRandom(-spread, spread);
			let proj = RS_AffixPartActor(
				shooter.SpawnPlayerMissile(cls, a, aimflags: aimflags));
			if (proj)
			{
				proj.ExactDamage = int(dmg);
				RS_Catalog.ApplyProjectileScale(proj, projScale);
				proj.master = self;
			}
		}
	}

	// Heavy round(s). Same per-type SetupStats branching for the same
	// reason as before: Rocket/PlasmaBall/BFGBall inherit three unrelated
	// vanilla bases and share no ancestor to cast to.
	//
	// pellets defaults to 1 (every existing weapon's real behavior,
	// unchanged) but is READ from the exact same generic pellets value
	// A_RS_FireSlot already computes for Bullet mode -- payload:cluster/
	// multi granted to a Rocket Launcher now actually fires multiple
	// rockets instead of silently doing nothing, closing the gap where
	// payload's damage half leaked into Heavy mode but the pellet half
	// didn't. dmg is computed once, upstream, same as Bullet -- each
	// spawned round gets the same already-divided number, not a fresh
	// roll per round.
	void RS_FireProfileHeavy(Actor shooter, RS_AttackProfile p, double dmg, int pellets = 1, bool homing = false)
	{
		// Affix override first, but FENCED: a ballistic (bullet-base)
		// class is refused here -- the mirror of the checked-cast in
		// RS_FireProfileBullet, so a part-swap affix pointed at the
		// wrong mode degrades to "no swap" instead of spawning a round
		// that skips SetupStats.
		Class<Actor> cls = AffixProjectile;
		if (cls && (Class<RS_BallisticFired>)(cls))
			cls = null;
		if (!cls) cls = p.ProjectileClass;
		if (!cls) cls = HeavyProjectileClass;
		if (!cls) return;

		int aimflags = bOffhandWeapon ? ALF_ISOFFHAND : 0;
		double crit = CritChance + p.CritBonus;

		// Small fixed fan-out so multiple rounds don't spawn perfectly
		// overlapped -- Heavy mode has no SpreadScale/Accuracy-driven
		// cone the way Bullet mode does, so this is a flat constant, not
		// a rolled stat. 4 degrees is a first pass, not a tuned number.
		double fanStep = 4.0;
		double fanStart = -fanStep * (pellets - 1) / 2.0;

		for (int i = 0; i < pellets; i++)
		{
			double a = shooter.angle + fanStart + fanStep * i;
			let proj = shooter.SpawnPlayerMissile(cls, a, 0, 0, p.SpawnHeight,
				noautoaim: true, aimflags: aimflags, pitch: shooter.pitch);

		// Same derivation as the bullet path -- a launcher firing a
		// borrowed monster projectile still gets launcher-weight size.
		if (proj)
		{
			double hvScale = (p.ProjScale > 0)
				? p.ProjScale
				: RS_Catalog.ScaleForArchetype(GetPaletteArchetype());
			let hvMods = RS_ShotKeywordMods.Resolve(self, p);
			if (hvMods) hvScale *= hvMods.ScaleMult;
			RS_Catalog.ApplyProjectileScale(proj, hvScale);
		}
			if (!proj)
				continue;
			// Same marking as the bullet path -- a critical rocket should
			// be as readable in flight as a critical bullet.
			if (RS_ShotWasCrit) RS_CritMark.Apply(proj);
			proj.master = self;   // see RS_FireProfileBullet

			// Blast-look precedence: affix > this beat's authored visual >
			// the projectile class's own default (set in its PostBeginPlay).
			Class<Actor> fxBoom = AffixExplosionVisual ? AffixExplosionVisual : p.ExplosionVisual;
			if (proj is "RS_EnhancedRocket")
			{
				let r = RS_EnhancedRocket(proj);
				r.SetupStats(int(dmg), crit);
				r.Homing = homing;
				if (fxBoom)
					r.ExplosionVisual = fxBoom;
			}
			else if (proj is "RS_EnhancedPlasmaBall")
			{
				let pb = RS_EnhancedPlasmaBall(proj);
				pb.SetupStats(int(dmg), crit);
				pb.Homing = homing;
				if (fxBoom)
					pb.ExplosionVisual = fxBoom;
			}
			else if (proj is "RS_EnhancedBFGBall")
			{
				let bb = RS_EnhancedBFGBall(proj);
				bb.SetupStats(int(dmg), crit);
				bb.Homing = homing;
				if (fxBoom)
					bb.ExplosionVisual = fxBoom;
			}
			else if (proj is "RS_GH_BFGShot")
				RS_GH_BFGShot(proj).SetupStats(int(dmg), crit);
			else if (proj is "RS_GH_PlasmaShot")
				RS_GH_PlasmaShot(proj).SetupStats(int(dmg), crit);
			else if (proj is "RS_GH_UnmakerShot")
				RS_GH_UnmakerShot(proj).SetupStats(int(dmg), crit);
			// --- MeatGrinder heavies. Added 2026-08-07; they had shipped
			// with SetupStats written and NEVER CALLED, because this chain
			// only ever learned the VR_ and GH class names. RS_PS_Rocket
			// and RS_PS_BFGShot declare no Default Damage at all, so their
			// direct hits dealt ZERO -- and since the PS rocket then had
			// only splash, and Cyberdemon/Mastermind are splash-immune, the
			// Grinder rocket launcher could not hurt them at all. PS plasma
			// meanwhile ran at inherited vanilla PlasmaBall damage (5) at
			// every tier. Tier, Condition, promotion and crit were
			// decorative for this whole set.
			else if (proj is "RS_PS_Rocket")
				RS_PS_Rocket(proj).SetupStats(int(dmg), crit);
			else if (proj is "RS_PS_BFGShot")
				RS_PS_BFGShot(proj).SetupStats(int(dmg), crit);
			else if (proj is "RS_PS_PlasmaShot")
				RS_PS_PlasmaShot(proj).SetupStats(int(dmg), crit);
			// --- GH grenades. Same omission. These carry Damage 0 by
			// design and pay out through A_Explode(Splash1/Splash2), which
			// scale off RolledDamage -- so with SetupStats never called,
			// DamageRatio() returned its 1.0 baseline forever and every
			// grenade in the game was a fixed vanilla-weight blast.
			// RS_GH_GrenadeThrown inherits Launched, so the `is` test
			// covers both.
			else if (proj is "RS_GH_GrenadeLaunched")
				RS_GH_GrenadeLaunched(proj).SetupStats(int(dmg), crit);
			// --- NOT SILENT ANY MORE.
			// The three defects above were all the same defect: a heavy
			// projectile class this chain does not name gets spawned,
			// flies, hits, and quietly uses whatever its Default block
			// said -- no error, no warning, nothing to grep for. It went
			// unnoticed across two whole weapon sets. Any future heavy
			// class that is added without a branch here now says so out
			// loud the first time it is fired.
			else
			{
				Console.Printf("\cgRS_Weapon: heavy projectile %s has no "
					"SetupStats branch in RS_FireProfileHeavy -- it is "
					"firing at its Default damage, ignoring tier, "
					"Condition, crit and keywords.",
					proj.GetClassName() .. "");
			}
		}
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
	// Weapon Sound Assignment (the "Fire Sounds" section of MENUDEF's
	// RS_WeaponOptions). No
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
		// Affix beats everything, including the player's sound-choice
		// cvar -- an affix that changed WHAT this gun is outranks a
		// cosmetic preference for how the old gun sounded. See the
		// AFFIX PART OVERRIDES block for the full precedence rule.
		if (AffixFireSound)
			return AffixFireSound;

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
	// Is this the empty-slot PLACEHOLDER a class grants so a hand is never
	// literally empty, rather than a weapon the player chose to carry?
	//
	// A filler must lose the hand to any real weapon, but still be seated
	// when it is genuinely all there is. VR_DualClassBase.SeatHands reads
	// this to break that tie.
	//
	// A VIRTUAL, not a bMeleeWeapon test and not a class-name comparison.
	// bMeleeWeapon is unreliable here -- only VR_Fist and VR_Chainsaw
	// declare +WEAPON.MELEEWEAPON in the entire arsenal, so MeatGrinder's
	// and Vanilla+'s own fists read as guns. And a name check would break
	// the rule that a new weapon inherits correct behaviour from its flags
	// alone. Each filler class answers for itself.
	virtual bool IsHandFiller()
	{
		return false;
	}

	virtual void RollStats(EVR_Tier t)
	{
		Tier = t;
	}

	// =================================================================
	// LIFTING A CURSE. Rewritten 2026-08-07.
	//
	// The old version multiplied the CURRENT (halved) value by 1.5, so
	// clearing a curse left the weapon 25% WORSE than if it had never
	// been cursed: 100 -> 50 -> 75. You paid to lose. See the PreCurse*
	// field comments for the full history.
	//
	// Now: RESTORE the stat to its pre-curse value, then add a bonus
	// that ESCALATES with how deep the stack was.
	//
	//   1st lift on a stat   +25% of base
	//   2nd                  +35%
	//   3rd and beyond       +50%
	//
	// Why escalating: a flat bonus small enough to be safe on a single
	// curse doesn't beat a few level-up cards, so lifting would be a
	// worse use of resources than just playing. At these numbers one
	// lift already beats several levels, and a cleared triple stack
	// (+110%) beats an entire promotion cycle's worth of cards -- which
	// is the payoff that justifies carrying a crippled weapon around.
	//
	// Owner ruling 2026-08-07: "we need to make lifitng curses worth it,
	// and rewarding, more than just what a few levels would give you."
	//
	// Returns true if a curse was actually lifted.
	// =================================================================
	int LiftBonusPercent(int stackDepthCleared)
	{
		// stackDepthCleared is 1 for the first lift on this stat, 2 for
		// the second, and so on.
		if (stackDepthCleared <= 1)
			return RS_Curse.CVInt("rs_curse_lift_bonus1", 25);
		if (stackDepthCleared == 2)
			return RS_Curse.CVInt("rs_curse_lift_bonus2", 35);
		return RS_Curse.CVInt("rs_curse_lift_bonus3", 50);
	}

	bool UnlockStat(String statName)
	{
		bool lifted = false;
		int bonusPct = 0;

		if (statName == "damage" && LockedDamage)
		{
			bonusPct = LiftBonusPercent(CurseStackDamage);
			int base = PreCurseDamage > 0 ? PreCurseDamage : DamagePerShot;

			CurseStackDamage = max(0, CurseStackDamage - 1);
			// Only the LAST lift on a stat frees it. A stat cursed twice
			// stays locked (and stays halved-once) after one lift.
			if (CurseStackDamage <= 0)
			{
				LockedDamage = false;
				DamagePerShot = max(1, int(base * (1.0 + bonusPct / 100.0)));
				PreCurseDamage = 0;
			}
			else
			{
				// Partial: undo one halving, no bonus until it is clean.
				DamagePerShot = max(1, DamagePerShot * 2);
			}
			lifted = true;
		}
		else if (statName == "accuracy" && LockedAccuracy)
		{
			bonusPct = LiftBonusPercent(CurseStackAccuracy);
			double base = PreCurseAccuracy > 0 ? PreCurseAccuracy : Accuracy;

			CurseStackAccuracy = max(0, CurseStackAccuracy - 1);
			if (CurseStackAccuracy <= 0)
			{
				LockedAccuracy = false;
				Accuracy = base * (1.0 + bonusPct / 100.0);
				PreCurseAccuracy = 0;
			}
			else Accuracy *= 2.0;
			lifted = true;
		}
		else if (statName == "velocity" && LockedVelocity)
		{
			bonusPct = LiftBonusPercent(CurseStackVelocity);
			double base = PreCurseVelocity > 0 ? PreCurseVelocity : Velocity;

			CurseStackVelocity = max(0, CurseStackVelocity - 1);
			if (CurseStackVelocity <= 0)
			{
				LockedVelocity = false;
				Velocity = base * (1.0 + bonusPct / 100.0);
				PreCurseVelocity = 0;
			}
			else Velocity *= 2.0;
			lifted = true;
		}
		else if (statName == "critchance" && LockedCritChance)
		{
			bonusPct = LiftBonusPercent(CurseStackCritChance);
			double base = PreCurseCritChance > 0 ? PreCurseCritChance : CritChance;

			CurseStackCritChance = max(0, CurseStackCritChance - 1);
			if (CurseStackCritChance <= 0)
			{
				LockedCritChance = false;
				CritChance = base * (1.0 + bonusPct / 100.0);
				PreCurseCritChance = 0;
			}
			else CritChance *= 2.0;
			lifted = true;
		}
		else if (statName == "capacity" && LockedCapacity)
		{
			bonusPct = LiftBonusPercent(CurseStackCapacity);
			int base = PreCurseCapacity > 0 ? PreCurseCapacity : Capacity;

			CurseStackCapacity = max(0, CurseStackCapacity - 1);
			if (CurseStackCapacity <= 0)
			{
				LockedCapacity = false;
				Capacity = max(1, int(base * (1.0 + bonusPct / 100.0)));
				PreCurseCapacity = 0;
			}
			else Capacity = max(1, Capacity * 2);
			lifted = true;
		}

		if (!lifted)
			return false;

		// -------------------------------------------------------------
		// RAISE THE CEILING BY WHAT WE JUST PAID.
		//
		// GetDamageCeiling() is PromotionDamageBaseline * 1.8, and the
		// GunBonsai damage card stops being OFFERED at the ceiling
		// (IsSuitableForWeapon returns false). Without this, clearing a
		// deep stack pushes damage past the ceiling and silently disables
		// your own upgrades for the rest of the cycle -- you would have
		// spent Curse Bits to lock yourself out of level-ups.
		//
		// Conceptually right as well as mechanically necessary: the curse
		// was suppressing the weapon's POTENTIAL, not just its number.
		// -------------------------------------------------------------
		if (bonusPct > 0 && RS_Curse.CVBool("rs_curse_lift_raises_ceiling", true))
			PromotionDamageBaseline = max(PromotionDamageBaseline,
				int(PromotionDamageBaseline * (1.0 + bonusPct / 100.0)));

		// -------------------------------------------------------------
		// TIER UP. Owner ruling 2026-08-07: lifting a curse "causes the
		// weapon to tier-up as a reward".
		//
		// Capped at Prototype. Fires per lift, so a stat cursed three
		// times pays three tiers as it is cleaned.
		// -------------------------------------------------------------
		if (RS_Curse.CVBool("rs_curse_lift_tiers_up", true) && Tier < VRT_Prototype)
		{
			// int, then plain assignment. EVR_Tier(x) is NOT a cast --
			// ZScript has no enum-constructor syntax, so it parses as a
			// call to an undefined function ("Call to unknown function
			// 'EVR_Tier'"). An int converts to the enum on its own.
			// Same trap, same fix, as RS_EliteDrop.zs:131.
			int nextTier = int(Tier) + 1;
			Tier = nextTier;
			GunBonaiSockets = RS_Roll.SocketsForTier(Tier);
		}

		// -------------------------------------------------------------
		// DIVINE. Both pools report into ONE player-wide counter.
		//
		// Owner ruling 2026-08-07: "fuck weapon divinity, all cured
		// curses (player or weapon) move the player themselves closer to
		// divine status (need 10 cured curses) upon which curses no
		// longer apply."
		// -------------------------------------------------------------
		if (owner)
		{
			let led = RS_CurseLedger.Fetch(owner);
			if (led) led.CountCure();
		}

		return true;
	}

	// Does this weapon carry ANY stat-lock right now? Drives the imprint
	// gate below and the "cursed" tell on the weapon sheet.
	bool HasAnyCurse() const
	{
		return LockedDamage || LockedAccuracy || LockedVelocity
		    || LockedCritChance || LockedCapacity;
	}

	int TotalCurseStacks() const
	{
		return CurseStackDamage + CurseStackAccuracy + CurseStackVelocity
		     + CurseStackCritChance + CurseStackCapacity;
	}

	// Is this named stat STILL cursed? Asked after a lift, because a stat
	// cursed twice is still cursed after the first one -- which is what
	// decides whether the `curse:` keyword comes off.
	bool IsStatCursed(String statName) const
	{
		if (statName == "damage")     return LockedDamage;
		if (statName == "accuracy")   return LockedAccuracy;
		if (statName == "velocity")   return LockedVelocity;
		if (statName == "critchance") return LockedCritChance;
		if (statName == "capacity")   return LockedCapacity;
		return false;
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

	// =================================================================
	// THE IMPRINT GATE. Owner ruling 2026-08-07:
	//
	//   "a weapon with curses cannot accept a dropped elite imprint that
	//    is higher than its current tier until curse is lifted, which
	//    also causes the weapon to tier-up as a reward"
	//
	// So curses GATE progress; they do not CAP it. An earlier design made
	// the curse count the weapon's maximum tier and the owner rejected it
	// for the right reason -- "you'll never get to promote your shit."
	//
	// NOTE WHAT THIS DELIBERATELY LEAVES OPEN. Promotion applies a BASIC
	// card to a PROTOTYPE weapon, and Basic is LOWER, so a cursed weapon
	// can still promote. Only climbing is blocked. That is intended:
	// curses stall you, they do not trap you.
	// =================================================================
	bool CanAcceptImprint(EVR_Tier newTier) const
	{
		if (!RS_Curse.CVBool("rs_curse_blocks_imprint", true))
			return true;
		if (!HasAnyCurse())
			return true;
		// Same tier or lower is always allowed -- including the
		// Prototype -> Basic promotion sacrifice.
		return int(newTier) <= int(Tier);
	}

	// =================================================================
	// *** THIS IS NOT THE IMPRINT APPLY PATH. DO NOT WIRE IT UP AS ONE.
	//
	// Added 2026-08-08, when imprints were built, because the name reads
	// like the obvious hook and taking it would be three silent
	// regressions in one call:
	//
	//   1. RollStats() is a DESTRUCTIVE WHOLE-WEAPON RE-ROLL. It assigns
	//      PelletCount (`PelletCount = 1` on the Revolver), so every
	//      Promotion the player has ever paid for is erased -- and
	//      Promotion is the mechanic that OWNS permanent pellet growth.
	//   2. It clears every Locked* flag while leaving the CurseStack*
	//      counters non-zero: a free curse-wipe AND a desync.
	//   3. The Prototype -> Basic branch below means a BASIC imprint
	//      landing on a PROTOTYPE weapon would PROMOTE it -- cutting all
	//      five stats 20% and dropping it to Basic -- without the player
	//      ever choosing to. Promotion is a decision, not something a
	//      loot drop does to you.
	//
	// This function is the PROMOTION-CARD path: a tier handed to a
	// weapon, nothing else. Nothing calls it today.
	//
	// An imprint is a PACKAGE (rolled values), not a tier, and it is
	// applied field by field with an explicit keep-list --
	// RS_Imprint.ApplyTo, zscript/systems/weapon/RS_Imprint.zs. That is
	// also the first and only caller CanAcceptImprint() has ever had.
	// =================================================================
	virtual void ApplyUpgradeCard(EVR_Tier newTier)
	{
		if (!CanAcceptImprint(newTier))
		{
			if (owner && owner.player == players[consoleplayer])
				Console.Printf("\c[Red]The curse refuses it.\c- Lift a curse before this weapon can take a higher imprint.");
			return;
		}

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

	// The "or the initial roll, if never promoted" half of that contract had
	// no writer -- Promote() was the only thing that ever set it. On a gun
	// that had never been promoted it stayed 0, so GetDamageCeiling() returned
	// max(1, 0) == 1, and three things silently broke:
	//   - the sheet printed "(ceiling 1)"
	//   - CardDamage/CardHotLoads gate on DamagePerShot < ceiling, so neither
	//     was ever OFFERED before a first promotion
	//   - RS_StateLadderBody()'s damage/ceiling ratio pinned at >= 0.90 for any
	//     damage >= 1, so every unpromoted gun always fired the Peak body and
	//     the Type1/Hot/Peak ladder never stepped
	// Called after the roll, which is where DamagePerShot first gets its real
	// value. Guarded, so it can never overwrite a real Promote() baseline and
	// is safe to call from both roll sites in either order.
	void CaptureInitialDamageBaseline()
	{
		if (PromotionDamageBaseline <= 0)
			PromotionDamageBaseline = DamagePerShot;
	}

	// Forget the captured baseline so the next CaptureInitialDamageBaseline
	// takes a fresh reading.
	//
	// Needed because PostBeginPlay ALWAYS rolls Basic and captures from it,
	// while anything that re-rolls a weapon at a real tier afterwards --
	// today that is only the elite drop (RS_EliteDrop.zs's RollStats(tier)
	// call) -- left the throwaway Basic number in place. The guard above is
	// "capture once", which is right for the normal life of a weapon and
	// exactly wrong for a weapon that is re-rolled before the player ever
	// sees it.
	//
	// The damage the player is looking at then had no relationship to the
	// ceiling measured against it: GetDamageCeiling() is baseline * 1.8, so
	// a Prototype drop rolling well above a stale Basic baseline sat pinned
	// at ceilingRatio >= 0.90 for the rest of its life -- which pins the
	// state-ladder tracer to its "Peak" body permanently (the ladder never
	// steps) and feeds the GunBonsai damage-card gate a number it was never
	// meant to compare against.
	void ResetDamageBaseline()
	{
		PromotionDamageBaseline = 0;
	}

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
		// Held-affix count, read BEFORE the strip below runs -- this is
		// the number RollPromotionCurse's mitigation reads. A Prototype
		// promoted loaded with affixes walks away luckier than one
		// promoted bare; see RollPromotionCurse's own comment for why.
		int heldAffixes = RS_GunBonsaiBridge.CountActiveAffixes(self);

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

		RollPromotionCurse(heldAffixes);
		RS_GunBonsaiBridge.OnWeaponPromoted(self);
	}

	const PROMOTION_CURSE_CHANCE = 0.15;

	// Chance that a freshly rolled weapon arrives with one stat cursed.
	// Overridden by rs_curse_chance; the Cursed tier floors much higher.
	const ROLL_CURSE_CHANCE = 0.12;
	const ROLL_CURSE_CHANCE_CURSEDTIER = 0.85;

	// Each held affix at promote-time takes a FIFTH off every rung of the
	// curse ladder -- see RollPromotionCurse for why a proportion rather
	// than a subtraction. Owner, 2026-08-11: 20% per affix.
	const PROMOTION_CURSE_MITIGATION_PER_AFFIX = 0.20;

	// No longer used: multiplicative mitigation cannot reach zero, so the
	// ladder needs no floor. Kept named so the old intent is legible if
	// anyone finds it referenced in an older comment.
	const PROMOTION_CURSE_CHANCE_FLOOR = 0.02;

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
	//
	// UN-STUBBED 2026-08-07. This opened with `if (true) return;` so
	// promotion never cursed anything -- promotion was pure upside, and
	// the whole risk half of the mechanic was inert.
	// THE LADDER, ONCE PER PROMOTION. Owner, 2026-08-11.
	//
	// This was a FLAT 15% per roll. It is now a descending ladder -- 50 for
	// the first stat, then 30, 15, 10, 5 -- so a promotion usually costs you
	// something and occasionally costs you a lot, instead of usually costing
	// nothing. Bare, that is a 75% chance of at least one curse and 1.1
	// cursed stats expected; the tail where four or five land is rare enough
	// to be a story rather than a pattern.
	//
	// Five rungs because there are five lockable stats. The ladder cannot
	// ask for a sixth curse, so it needs no cap.
	//
	// PROMOTION COUNT STILL ESCALATES -- owner ruled explicitly. The whole
	// ladder runs once per promotion, so a third promotion walks it three
	// times. That is the compounding cost of promoting the same gun over and
	// over, on top of the -20% every stat already takes each time.
	//
	// MITIGATION IS MULTIPLICATIVE, not a subtraction. Each affix held at
	// promote-time takes a FIFTH off every rung: one affix turns 50 into 40,
	// two into 32, three into 25.6. Percentage points would have punched
	// through the low rungs to zero and made the 5% rung meaningless after
	// two affixes, while barely touching the 50. A fifth scales the whole
	// ladder evenly and can never reach zero, so investment always helps and
	// never makes you safe.
	//
	// The direction is the design: PromotionCount drives the ESCALATION,
	// held affixes drive the MITIGATION. A gun promoted loaded is insurance
	// you bought by investing in it.
	void RollPromotionCurse(int heldAffixes = 0)
	{
		static const double LADDER[] = { 0.50, 0.30, 0.15, 0.10, 0.05 };

		double mitigation = 1.0;
		for (int a = 0; a < heldAffixes; a++)
			mitigation *= (1.0 - PROMOTION_CURSE_MITIGATION_PER_AFFIX);

		for (int i = 0; i < PromotionCount; i++)
			for (int rung = 0; rung < LADDER.Size(); rung++)
				RollOneCurse(LADDER[rung] * mitigation);
	}

	// CURSES ON THE INITIAL ROLL. Owner ruling 2026-08-07: "curses have a
	// % chance to happen when a class weapon or imprint is rolled."
	//
	// Before this, the only curse source was Promotion -- so a weapon you
	// found could never be cursed, which made the whole Cursed tier and
	// the gold-lifting economy unreachable on anything but a promoted gun.
	//
	// Runs exactly once per weapon (bCursesRolled), from AttachToOwner
	// after the statline exists. A Cursed-tier weapon rolls at a much
	// higher chance -- that is what the tier MEANS -- and everything else
	// takes the base rate.
	bool bCursesRolled;

	void RollInitialCurses()
	{
		if (bCursesRolled) return;
		bCursesRolled = true;

		double chance = ROLL_CURSE_CHANCE;
		let cv = CVar.FindCVar("rs_curse_chance");
		if (cv) chance = clamp(cv.GetInt(), 0, 100) / 100.0;

		// THE CURSED-TIER BRANCH IS GONE, because it could never fire.
		// Removed 2026-08-09.
		//
		// It read: if this weapon is Cursed tier, force the curse chance
		// to 85%. Correct in itself and completely unreachable -- nothing
		// can drop at Cursed tier. CVARINFO says so in capitals: "THERE IS
		// NO rs_elite_dropweight_cursed AND THERE MUST NOT BE ONE", and
		// RS_Imprint's own comment calls such a cvar "one that can never
		// affect anything". The owner zeroed that tier deliberately.
		//
		// Left in place it is worse than dead weight: it reads as live
		// behaviour, so the next person tuning curse rates budgets around
		// an 85% case that does not exist. ROLL_CURSE_CHANCE_CURSEDTIER
		// is kept as a named constant so the intended value survives if
		// the tier is ever re-enabled.

		RollOneCurse(chance);
	}

	// =================================================================
	// ROLL ONE STAT-LOCK.
	//
	// Each hit HALVES the stat and stacks -- owner ruling 2026-08-07:
	// "double curses on a stat or more is fine with me if penalties and
	// rewards are legit." Two curses on damage is x0.25, three is
	// x0.125. That is a dead weapon, and it is meant to be: the escalating
	// lift bonus in UnlockStat is what makes clearing it the jackpot.
	//
	// THE PRE-CURSE VALUE IS CAPTURED ON THE FIRST STACK ONLY, so a
	// second curse cannot overwrite the honest baseline with an already-
	// halved one. Without that, lifting could never restore the real
	// number and the whole reward collapses.
	//
	// Refuses entirely if the player is Divine.
	// =================================================================
	void RollOneCurse(double chance = PROMOTION_CURSE_CHANCE)
	{
		if (!RS_Curse.CVBool("rs_curse_enable", true))
			return;

		// DIVINE: no curse of any kind takes hold again. Checked here
		// rather than at the call sites so every present and future
		// source of a stat-lock obeys it automatically.
		if (owner && RS_CurseLedger.IsDivine(owner))
			return;

		if (FRandom(0, 1) >= chance)
			return;

		switch (Random(0, 4))
		{
			case 0:
				if (CurseStackDamage == 0) PreCurseDamage = DamagePerShot;
				CurseStackDamage++;
				DamagePerShot = max(1, int(DamagePerShot * 0.5));
				LockedDamage = true;
				GrantKeyword("curse", "damage");
				break;
			case 1:
				if (CurseStackAccuracy == 0) PreCurseAccuracy = Accuracy;
				CurseStackAccuracy++;
				Accuracy *= 0.5;
				LockedAccuracy = true;
				GrantKeyword("curse", "accuracy");
				break;
			case 2:
				if (CurseStackVelocity == 0) PreCurseVelocity = Velocity;
				CurseStackVelocity++;
				Velocity *= 0.5;
				LockedVelocity = true;
				GrantKeyword("curse", "velocity");
				break;
			case 3:
				if (CurseStackCritChance == 0) PreCurseCritChance = CritChance;
				CurseStackCritChance++;
				CritChance *= 0.5;
				LockedCritChance = true;
				GrantKeyword("curse", "critchance");
				break;
			case 4:
				if (CurseStackCapacity == 0) PreCurseCapacity = Capacity;
				CurseStackCapacity++;
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
		// PLAYER CURSE: `fragile` -- this hand's weapon wears out faster.
		// Applied by scaling the LOSS, not by calling the degrade twice:
		// DegradeCondition has a damage threshold, and running it twice
		// would also double-test that threshold rather than double the
		// wear from one qualifying hit.
		if (owner)
		{
			int h = bOffhandWeapon ? RS_Curse.HAND_OFF : RS_Curse.HAND_MAIN;
			bool cursed = RS_CurseLedger.Has(owner, RS_Curse.FLAW_FRAGILE, h);
			// LIFT REWARD, `fragile` cured: the hand's weapon holds up
			// better than stock. Scales the same loss the other way.
			double cured = RS_CurseLedger.BonusFor(owner, RS_Curse.FLAW_FRAGILE, h);

			if (cursed || cured > 0)
			{
				double before = Condition;
				double after = RS_Roll.DegradeCondition(Condition, rawDamageTaken);
				double loss = before - after;

				if (cursed)
					loss *= RS_Curse.CVInt("rs_curse_fragile_mult", 200) / 100.0;
				if (cured > 0)
					loss *= max(0.0, 1.0 - cured);

				Condition = max(0.0, before - loss);
				return;
			}
		}

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
		CaptureInitialDamageBaseline();
		EnsureAttackProfiles();

		// The curse roll goes AFTER the baseline capture, deliberately.
		// A curse halves a stat, and the promotion ceiling is measured
		// from the baseline -- capturing after the curse would bake the
		// halved number in as this weapon's "normal" and permanently
		// lower its ceiling. Lifting the curse would then never restore
		// it. Capture the honest roll, then curse it.
		RollInitialCurses();

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
		PrimarySlot    = RS_AttackSlot(new("RS_AttackSlot"));
		SecondarySlot  = RS_AttackSlot(new("RS_AttackSlot"));
		// Slots 2 and 3 are built empty for every weapon. No gun in the
		// arsenal authors a modifier attack today, so these stay empty
		// until an affix installs one -- and ResolveSlot falls back to
		// the base input while they are, so the modifier is never a key
		// that does nothing.
		TertiarySlot   = RS_AttackSlot(new("RS_AttackSlot"));
		QuaternarySlot = RS_AttackSlot(new("RS_AttackSlot"));
		BuildAttackProfiles();
		// Immediately after, and never again: the gun's identity is what
		// it SHIPPED with, not what an affix later made slot 0.
		CaptureGunAxes();
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (!bStatsRolled)
			RollStats(VRT_Basic);
		CaptureInitialDamageBaseline();
		if (!ProjectileClass)
			ProjectileClass = "RS_BallisticType1";
		if (!HeavyProjectileClass)
			HeavyProjectileClass = GetHeavyProjectile();
		EnsureAttackProfiles();
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
		string needle = RS_Keywords.Norm(key) .. ":" .. RS_Keywords.Norm(value);
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
		string prefix = RS_Keywords.Norm(key) .. ":";
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
		string prefix = RS_Keywords.Norm(key) .. ":";
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i].Left(prefix.Length()) == prefix)
				results.Push(GrantedKeywords[i].Mid(prefix.Length()));
	}

	// GRANTED-only multi-value lookup. The shot-math resolver
	// (RS_ShotKeywordMods.Resolve) reads THIS, not GetKeywordValues:
	// BASE keywords are descriptive identity (palette/archetype/flavor
	// queries), never live math. Before this split, payload:multi in
	// the shotgun family's BASE strings silently double-fired every
	// shotgun in the arsenal at half damage per pellet.
	void GetGrantedValues(string key, out Array<string> results)
	{
		string prefix = RS_Keywords.Norm(key) .. ":";
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i].Left(prefix.Length()) == prefix)
				results.Push(GrantedKeywords[i].Mid(prefix.Length()));
	}

	// GunBonsai/Promotion-facing write API. Idempotent -- GunBonsai's own
	// docs require OnActivate to be safely callable multiple times
	// without an intervening OnDeactivate (reselecting the weapon,
	// re-leveling, etc.), so a repeat grant must not stack duplicate
	// entries.
	// Stored NORMALISED (RS_Keywords.Norm), so the array only ever holds
	// lowercase entries and every reader below can compare directly. See
	// Norm's own comment for the bug this closes -- String == is
	// case-sensitive in a language where everything else is not.
	void GrantKeyword(string key, string value)
	{
		string entry = RS_Keywords.Norm(key) .. ":" .. RS_Keywords.Norm(value);
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i] == entry)
				return;
		GrantedKeywords.Push(entry);
	}

	// The OnDeactivate half -- an affix that grants a keyword on
	// activation must be able to cleanly take it back. Safe to call even
	// if the entry isn't present (no-op).
	void UngrantKeyword(string key, string value)
	{
		string entry = RS_Keywords.Norm(key) .. ":" .. RS_Keywords.Norm(value);
		for (int i = 0; i < GrantedKeywords.Size(); i++)
		{
			if (GrantedKeywords[i] == entry)
			{
				GrantedKeywords.Delete(i);
				return;
			}
		}
	}
}
