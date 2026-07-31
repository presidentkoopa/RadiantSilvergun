// =====================================================================
// RS_AttackProfile / RS_AttackSlot -- the attack-assembly bricks.
// ---------------------------------------------------------------------
// One AttackProfile describes ONE way a weapon attacks: what leaves the
// barrel, what it costs, its own shot shape, its own sound. Nothing in
// it is hardcoded to a specific weapon -- it's a reference bundle, so
// the same profile can sit on several weapons, and a weapon can carry
// several different ones.
//
// An AttackSlot is an ORDERED LIST of profiles plus a cursor. Firing the
// slot fires the profile at the cursor, then advances one step, wrapping
// at the end. That single mechanism covers everything:
//
//   list of 1                -> a normal weapon. Cursor never visibly
//                               moves; looks like no cycling at all.
//   list of [A, A, B]        -> "every third shot is B"
//   list of [A, B]           -> "alternates A and B"
//
// A weapon has two slots -- Primary (main trigger) and Secondary
// (alt-fire). They are fully independent: different profiles, different
// ammo, different everything. Nothing is shared between them.
//
// WHY IT'S SHAPED THIS WAY: GunBonsai upgrades write into this at two
// altitudes, and both are one-line operations on the structures below:
//   * grow the list   -> AppendProfile() / InsertProfile()  ("your
//                        revolver now fires a plasma bolt every 3rd shot")
//   * swap an entry   -> ReplaceProfile()                   ("your
//                        alt-fire is now something else entirely")
// The upgrade-card sentence and the data structure are the same thing
// described two ways.
//
// The weapon's OWN rolled stats (Tier, Condition, DamagePerShot,
// Accuracy, CritChance, Velocity) are NOT duplicated per profile. They
// stay on RS_Weapon and modulate whatever profile just fired -- a
// Prototype-tier gun's plasma entry hits harder than a Basic-tier gun's
// plasma entry, and the profile never needs to know that happened.
// =====================================================================

// Which firing path a profile uses. Lives on the individual profile, not
// on the weapon, so one weapon can rotate through wildly different attack
// types without any of them being a special case.
const RS_ATK_BULLET  = 0;   // volley of travelling rounds (RS_BallisticFired)
const RS_ATK_HEAVY   = 1;   // one explosive/energy round (Rocket/Plasma/BFG)
const RS_ATK_MELEE   = 2;   // short-range hit, no projectile
const RS_ATK_HITSCAN = 3;   // instant A_FireBullets trace (chaingun)

class RS_AttackProfile : Object
{
	// --- What this attack is ---
	int Mode;                       // RS_ATK_*
	Class<Actor> ProjectileClass;   // bullet class or heavy class, by Mode.
	                                // null on a bullet profile = fall back to
	                                // the weapon's own ProjectileClass.

	// --- Shot shape ---
	// Everything here MODIFIES the weapon's rolled stats rather than
	// replacing them. That's the whole reason tier and Condition keep
	// meaning something no matter which profile in a rotation fired.
	//
	// Final spread reproduces what each weapon computed inline before:
	//   (100 - Accuracy) * SpreadScale * chokeFactor
	//     + (UsesCadence ? overshoot * 0.15 : 0)
	//     + SpreadBonus
	// SpreadScale 0.05 = tight (pistol/revolver/smg/rifle/chaingun),
	// 0.1 = shotgun family. chokeFactor = (1 - Choke*0.5) when UsesChoke.
	int    PelletOverride;   // 0 = use the weapon's own rolled PelletCount
	double SpreadScale;
	bool   UsesChoke;
	double SpreadBonus;      // flat extra degrees on top
	bool   UsesCadence;      // semi-auto: firing early widens the cone.
	                         // full-auto leaves this false -- RateOfFire IS
	                         // the cadence there, so there's nothing to
	                         // outpace.
	double DamageMult;       // x weapon's rolled DamagePerShot
	double VelocityMult;     // x weapon's rolled Velocity
	double CritBonus;        // added to weapon's rolled CritChance (0-1)

	// --- Cost ---
	// AmmoClass null + AmmoCost > 0 means "the weapon's own AmmoType2"
	// (its magazine), resolved at fire time. That one rule covers all 66
	// ballistic identities without any of them naming their own chamber
	// class here -- VR_RevLoaded vs VR_RevLoaded4 sorts itself out.
	// AmmoCost 0 = this profile is free at the profile layer (melee, or a
	// weapon metering ammo in its own states).
	Class<Ammo> AmmoClass;
	int AmmoCost;

	// --- Presentation ---
	sound FireSound;
	// String, not Class<Actor> -- RS_HiFiFX.CasingEject's own signature
	// takes a string. "" = no casing ejected.
	string CasingClass;
	bool   BigMuzzle;           // RS_HiFiFX.MuzzleEffects(self, <this>)
	double SpawnHeight;         // muzzle offset, heavy profiles

	// --- Melee only ---
	double MeleeRange;
	Class<Actor> MeleePuff;

	// Display name for menus/upgrade cards. Optional.
	string ProfileName;

	// -----------------------------------------------------------------
	// Factories. Authoring a profile is one call, not eight assignments
	// at every call site -- and defaults mean a half-specified profile
	// still fires something safe rather than nothing.
	// -----------------------------------------------------------------

	// Shared neutral defaults, so a factory only has to name what it
	// actually differs on.
	private void InitDefaults()
	{
		Mode          = RS_ATK_BULLET;
		PelletOverride = 0;
		SpreadScale   = 0.05;
		UsesChoke     = false;
		SpreadBonus   = 0.0;
		UsesCadence   = false;
		DamageMult    = 1.0;
		VelocityMult  = 1.0;
		CritBonus     = 0.0;
		AmmoCost      = 0;
		BigMuzzle     = false;
		MeleeRange    = 64.0;
	}

	// Travelling-round volley -- the main-arsenal ballistic path.
	static RS_AttackProfile MakeBullet(
		sound fireSnd = "",
		double spreadScale = 0.05,
		bool usesCadence = true,
		int ammoCost = 1,
		string casing = "",
		bool bigMuzzle = false,
		bool usesChoke = false,
		double dmgMult = 1.0,
		Class<Actor> proj = null,
		string profName = "")
	{
		let p = RS_AttackProfile(new("RS_AttackProfile"));
		p.InitDefaults();
		p.Mode            = RS_ATK_BULLET;
		p.FireSound       = fireSnd;
		p.SpreadScale     = spreadScale;
		p.UsesCadence     = usesCadence;
		p.AmmoCost        = ammoCost;
		p.CasingClass     = casing;
		p.BigMuzzle       = bigMuzzle;
		p.UsesChoke       = usesChoke;
		p.DamageMult      = dmgMult;
		p.ProjectileClass = proj;
		p.ProfileName     = profName;
		return p;
	}

	// Instant trace. No projectile actor exists, so nothing carries the
	// GunBonsai master pointer -- see RS_Weapon's dispatch for the note.
	static RS_AttackProfile MakeHitscan(
		sound fireSnd = "",
		double spreadScale = 0.05,
		int ammoCost = 1,
		Class<Ammo> ammo = null,
		string casing = "",
		bool bigMuzzle = false,
		string profName = "")
	{
		let p = RS_AttackProfile(new("RS_AttackProfile"));
		p.InitDefaults();
		p.Mode        = RS_ATK_HITSCAN;
		p.FireSound   = fireSnd;
		p.SpreadScale = spreadScale;
		p.AmmoCost    = ammoCost;
		p.AmmoClass   = ammo;
		p.CasingClass = casing;
		p.BigMuzzle   = bigMuzzle;
		p.ProfileName = profName;
		return p;
	}

	static RS_AttackProfile MakeHeavy(
		Class<Actor> proj = null,
		sound fireSnd = "",
		int ammoCost = 0,
		Class<Ammo> ammo = null,
		bool bigMuzzle = true,
		double spawnHeight = 0.0,
		double dmgMult = 1.0,
		string profName = "")
	{
		let p = RS_AttackProfile(new("RS_AttackProfile"));
		p.InitDefaults();
		p.Mode            = RS_ATK_HEAVY;
		p.ProjectileClass = proj;
		p.FireSound       = fireSnd;
		p.AmmoCost        = ammoCost;
		p.AmmoClass       = ammo;
		p.BigMuzzle       = bigMuzzle;
		p.SpawnHeight     = spawnHeight;
		p.DamageMult      = dmgMult;
		p.ProfileName     = profName;
		return p;
	}

	static RS_AttackProfile MakeMelee(
		double range = 64.0,
		sound fireSnd = "",
		Class<Actor> puff = null,
		bool bigMuzzle = true,
		double dmgMult = 1.0,
		string profName = "")
	{
		let p = RS_AttackProfile(new("RS_AttackProfile"));
		p.InitDefaults();
		p.Mode        = RS_ATK_MELEE;
		p.MeleeRange  = range;
		p.FireSound   = fireSnd;
		p.MeleePuff   = puff;
		p.BigMuzzle   = bigMuzzle;
		p.DamageMult  = dmgMult;
		p.ProfileName = profName;
		return p;
	}

	// Independent copy -- so a GunBonsai upgrade that tweaks one entry in
	// a cycle can't accidentally mutate a profile shared with another
	// weapon or another slot.
	RS_AttackProfile Clone()
	{
		let p = RS_AttackProfile(new("RS_AttackProfile"));
		p.Mode            = Mode;
		p.ProjectileClass = ProjectileClass;
		p.PelletOverride  = PelletOverride;
		p.SpreadScale     = SpreadScale;
		p.UsesChoke       = UsesChoke;
		p.SpreadBonus     = SpreadBonus;
		p.UsesCadence     = UsesCadence;
		p.DamageMult      = DamageMult;
		p.VelocityMult    = VelocityMult;
		p.CritBonus       = CritBonus;
		p.AmmoClass       = AmmoClass;
		p.AmmoCost        = AmmoCost;
		p.FireSound       = FireSound;
		p.CasingClass     = CasingClass;
		p.BigMuzzle       = BigMuzzle;
		p.SpawnHeight     = SpawnHeight;
		p.MeleeRange      = MeleeRange;
		p.MeleePuff       = MeleePuff;
		p.ProfileName     = ProfileName;
		return p;
	}
}

// =====================================================================
// RS_AttackSlot -- one trigger's worth of attacks.
// ---------------------------------------------------------------------
// The cursor is deliberately NOT a player-facing selector. Within a
// slot the player has no control over which entry comes next: pulling
// the trigger advances the rotation, always, in order. Deliberate
// choice happens BETWEEN slots (main trigger vs alt-fire), not inside
// one.
// =====================================================================
class RS_AttackSlot : Object
{
	Array<RS_AttackProfile> Profiles;
	int Cursor;

	int Count()
	{
		return Profiles.Size();
	}

	bool IsEmpty()
	{
		return Profiles.Size() == 0;
	}

	// The profile that WOULD fire next, without advancing. Used by menus
	// and upgrade cards that want to show the rotation without touching it.
	RS_AttackProfile Peek()
	{
		if (Profiles.Size() == 0)
			return null;
		return Profiles[Cursor % Profiles.Size()];
	}

	RS_AttackProfile PeekAt(int index)
	{
		if (index < 0 || index >= Profiles.Size())
			return null;
		return Profiles[index];
	}

	// Read the current profile, THEN step the rotation forward. This is
	// the only thing that moves the cursor.
	RS_AttackProfile Advance()
	{
		int n = Profiles.Size();
		if (n == 0)
			return null;
		let p = Profiles[Cursor % n];
		Cursor = (Cursor + 1) % n;
		return p;
	}

	void ResetCursor()
	{
		Cursor = 0;
	}

	// --- Mutators. These are the GunBonsai write targets. ---

	void Append(RS_AttackProfile p)
	{
		if (p) Profiles.Push(p);
	}

	// Insert at a position so an upgrade can land on a specific beat of
	// the rotation ("every 3rd shot" wants index 2, not the tail).
	void InsertAt(int index, RS_AttackProfile p)
	{
		if (!p) return;
		if (index < 0) index = 0;
		if (index >= Profiles.Size())
		{
			Profiles.Push(p);
			return;
		}
		Profiles.Insert(index, p);
	}

	// Swap one entry out without disturbing the rest of the rotation.
	void Replace(int index, RS_AttackProfile p)
	{
		if (!p || index < 0 || index >= Profiles.Size()) return;
		Profiles[index] = p;
	}

	void RemoveAt(int index)
	{
		if (index < 0 || index >= Profiles.Size()) return;
		Profiles.Delete(index);
		if (Profiles.Size() == 0) Cursor = 0;
		else Cursor = Cursor % Profiles.Size();
	}

	void Clear()
	{
		Profiles.Clear();
		Cursor = 0;
	}

	// Pad the rotation with copies of an existing entry. This is what
	// turns "add an explosive shot" into "every THIRD shot is explosive":
	// author [normal], PadTo(3) -> [normal, normal, normal], then
	// Replace(2, explosive) -> [normal, normal, explosive].
	void PadTo(int length, RS_AttackProfile filler)
	{
		if (!filler) return;
		while (Profiles.Size() < length)
			Profiles.Push(filler.Clone());
	}
}
