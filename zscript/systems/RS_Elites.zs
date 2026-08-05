// =====================================================================
// RS_Elites -- hidden elite monsters.
// ---------------------------------------------------------------------
// Design of record: docs/rs_25_elites_design.txt. Read it before editing.
//
// THE MODEL, in one paragraph, because no single function shows it:
// at level load we sweep the map and MARK some monsters. A marked monster
// gets a health boost and NOTHING ELSE -- no colour, no icon, no sound.
// The only tell is that the fight takes suspiciously long. When it drops
// to 50% it REVEALS: heals to full, gains the elite flag set and damage
// multiplier, throws a lit pentagram, and only THEN rolls whether it also
// gets a behaviour profile and/or a tier bump. A marked monster killed
// above 50% never reveals and never had a profile.
//
// WHY THE ORDER MATTERS: rolling the profile at reveal rather than at
// marking means there is no dormant state to gate. A gate would be a bool
// tested in a dozen places and it would leak -- one call site forgetting
// it is a profile firing on a monster that has not woken up. Here the
// controller simply has no profile to call before reveal. Nothing to leak.
//
// NOT HERE YET (rs_25 parts 2 and 4):
//   * the behaviour profiles. RS_EliteProfile below declares the six hooks
//     and the controller calls them; nothing subclasses it yet. That is
//     the next phase and it is why the hooks exist now.
//   * drops of any kind, the triptych, the arsenal function, gold summons.
// This file is complete and playable without them: mark, long fight,
// reveal, meaner monster.
//
// TWO ENGINE FACTS THAT SHAPED IT:
//   1. +MISSILEMORE and +MISSILEEVENMORE ARE DEPRECATED ON THIS BUILD.
//      They cannot be set as flags at all; they are MissileChanceMult
//      maths. RS_BlackSGTrooper.zs:35 documents the same conversion.
//   2. THE TURRET VALVE ALREADY EXISTS. rs_mon_missilechance_floor is this
//      repo's own limiter and its CVARINFO comment describes the exact
//      failure: at MissileChanceMult 0.0625 a monster stops moving and
//      hoses. We go through that valve rather than inventing a second one.
//
// ART AND AUDIO ARE PLACEHOLDERS. Confirmed-working calls first, real
// assets after. Do not treat any sprite or sound token here as final.
// =====================================================================

// ---------------------------------------------------------------------
// Tokens. Bare Inventory on purpose -- all the behaviour is in who holds
// them. RS_EliteMark additionally carries the controller pointer, which is
// how the event handler finds a monster's controller again later.
// ---------------------------------------------------------------------
class RS_EliteMark : Inventory
{
	RS_EliteController ctl;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}
}

class RS_EliteRevealed : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}
}

// A permanent protection powerup hung on a revealed elite. Currently
// carries no damage factors -- it exists so per-profile and per-tier
// resistances have somewhere to live without another inventory item.
class RS_EliteResist : PowerProtection
{
	Default
	{
		Powerup.Duration -0x7FFFFFFF;
	}
}

// ---------------------------------------------------------------------
// RS_EliteProfile -- the six hooks, and the whole point of the next phase.
//
// One of these is assigned AT REVEAL, never at marking. Subclasses
// override only what they need; an empty hook is a legitimate profile,
// not an unfinished one.
// ---------------------------------------------------------------------
class RS_EliteProfile : Object
{
	RS_EliteController ctl;
	Actor mon;

	// Tics between OnTick calls. 0 means "never ticks", which several
	// profiles legitimately are -- they live entirely in OnReveal or
	// OnDeath.
	int tickInterval;

	virtual void OnSelected() {}
	virtual void OnReveal() {}
	virtual void OnTick() {}
	virtual void OnHit(int damage) {}
	virtual void OnDeath() {}
	virtual void OnMissileSpawned(Actor missile) {}

	// The profile's identity colour. Drives the aura, the particles and
	// optionally the pentagram. Base is white; every real profile
	// overrides it.
	virtual color GetShade() { return "FFFFFF"; }
}

// ---------------------------------------------------------------------
// RS_EliteRoster -- which profiles exist, and how one gets picked.
//
// A SWITCH, NOT AN ARRAY. `static const class<X> name[] = {...}` at class
// scope does not resolve reliably on this engine build -- it has been
// found and fixed three separate times in unrelated files, and the symptom
// is a confusing "Unknown identifier" pointing at something that plainly
// exists. Every lookup here is a switch or a comparison chain. Do not
// "tidy" this into a table.
//
// Adding a profile means: add its case here, bump Count(), and add its
// include. Nothing else in this file needs to change.
// ---------------------------------------------------------------------
class RS_EliteRoster
{
	// Bump this as profiles land. It is the only number that has to move.
	static int Count()
	{
		return 17;
	}

	static Name ProfileAt(int i)
	{
		switch (i)
		{
			case 0: return 'RS_EliteProfile_Red';
			case 1: return 'RS_EliteProfile_Black';
			case 2: return 'RS_EliteProfile_Yellow';
			case 3: return 'RS_EliteProfile_Bronze';
			case 4: return 'RS_EliteProfile_Blue';
			case 5: return 'RS_EliteProfile_Violet';
			case 6: return 'RS_EliteProfile_Orange';
			case 7: return 'RS_EliteProfile_DarkGreen';
			case 8: return 'RS_EliteProfile_White';
			case 9:  return 'RS_EliteProfile_Cyan';
			case 10: return 'RS_EliteProfile_Silver';
			case 11: return 'RS_EliteProfile_Grey';
			case 12: return 'RS_EliteProfile_Green';
			case 13: return 'RS_EliteProfile_DarkRed';
			case 14: return 'RS_EliteProfile_Pink';
			case 15: return 'RS_EliteProfile_Indigo';
			case 16: return 'RS_EliteProfile_Gold';
			default: return 'None';
		}
	}

	// Uniform for now. When per-profile weights are wanted this becomes a
	// weight switch and a running total -- still no array.
	static Name RollProfile()
	{
		int n = Count();
		if (n <= 0)
			return 'None';
		return ProfileAt(random(0, n - 1));
	}
}

// ---------------------------------------------------------------------
// RS_EliteAura -- the persistent tell on a revealed elite, and NOT what
// it looks like from the outside.
//
// This is not a light on the monster. One ghost is spawned PER TIC at the
// monster's position, copying its CURRENT SPRITE FRAME, scale and alpha.
// The ghost halves its alpha, takes a single upward impulse, then fades
// 0.12 per tic while stretching ONLY its Y scale by 1.02-1.04 each tic,
// and self-destructs when it reaches zero alpha. About five tics of life.
//
// So the "glow" is a trailing stack of roughly five overlapping, rising,
// vertically-stretching stencil after-images of the monster, each with its
// own short-lived dynamic light. Not a lamp. Getting this wrong makes the
// reveal look like a torch instead of a haunting, and the haunting is the
// entire visual identity of the thing.
//
// THE BODY IS NEVER TINTED. Our monster art is bespoke per tier and a tint
// on top of bespoke art corrupts it -- see the note at RS_Zombieman.zs:333.
// The elite reads as its shade through this aura, its particles, the
// pentagram and the light. The sprite itself is left alone.
//
// A NOTE ON STENCIL COLOURS: GZDoom rejects some values outright. 800000,
// 800080 and 202020 are all illegal as stencils and must be nudged
// (A00000, A00080, and the named "Black" respectively). If a profile's
// shade goes black on screen, that is why.
// ---------------------------------------------------------------------
class RS_EliteAura : Actor
{
	Default
	{
		Radius 16;
		Height 8;
		Scale 1.0;
		Alpha 1.0;
		RenderStyle "AddStencil";
		+NOGRAVITY
		+THRUACTORS
		+NOTONAUTOMAP
		+NOTIMEFREEZE
		+NOBLOCKMAP
		+NOINTERACTION
		-FORCEXYBILLBOARD
		-VISIBILITYPULSE
	}

	void SetupFrom(Actor src, color shade, double intensity)
	{
		if (!src)
		{
			Destroy();
			return;
		}

		sprite = src.sprite;
		frame  = src.frame;
		Scale  = src.Scale;
		alpha  = src.alpha;

		SetShade(shade);

		alpha *= 0.5;
		Vel.Z = 1.0;

		if (intensity > 0)
			A_AttachLight('RS_EliteAuraGlow', DynamicLight.FlickerLight,
			              shade,
			              int(80 * intensity),
			              int(100 * intensity),
			              DYNAMICLIGHT.LF_ATTENUATE);
	}

	States
	{
	Spawn:
		"####" "#" 0 Bright;
		Goto SpawnLoop;
	SpawnLoop:
		// A_FadeTo's third argument is "destroy when the target is
		// reached" -- that is the ghost's entire lifetime mechanism.
		// There is no counter and there does not need to be one.
		"####" "#" 0 Bright A_FadeTo(0, 0.12, 1);
		"####" "#" 1 Bright { Scale.Y *= FRandom(1.02, 1.04); }
		Loop;
	}
}

// ---------------------------------------------------------------------
// RS_ElitePentagramLight -- the light half of the reveal.
//
// The pentagram particles are fullbright but emit nothing on their own, so
// without this the ring reads as a glowing shape that lights nothing. One
// light at the monster's feet, not one per particle: it blooms fast and
// decays slowly, riding the same curve the particles fade on.
//
// It is attached from ZScript rather than declared in GLDEFS because
// GLDEFS is static and cannot read a cvar, and the colour and intensity
// are both player-facing options.
// ---------------------------------------------------------------------
class RS_ElitePentagramLight : Actor
{
	color  lightShade;
	double peakSize;
	int    life;
	int    age;

	Default
	{
		Radius 1;
		Height 1;
		+NOBLOCKMAP
		+NOGRAVITY
		+NOINTERACTION
		+NOCLIP
		RenderStyle "None";
	}

	void Setup(color shade, double sizePeak, int lifeTics)
	{
		lightShade = shade;
		peakSize   = sizePeak;
		life       = max(1, lifeTics);
	}

	override void Tick()
	{
		Super.Tick();

		age++;
		if (age >= life)
		{
			A_RemoveLight('RS_ElitePentagram');
			Destroy();
			return;
		}

		// Fast bloom, slow decay -- roughly one tenth of the life rising
		// and the rest falling.
		double f;
		int bloom = int(life * 0.09);
		if (age <= bloom)
			f = double(age) / double(max(1, bloom));
		else
			f = 1.0 - (double(age - bloom) / double(max(1, life - bloom)));

		f = clamp(f, 0.0, 1.0);

		int sz = int(peakSize * f);
		if (sz > 0)
			A_AttachLight('RS_ElitePentagram', DynamicLight.PointLight,
			              lightShade, sz, 0, DYNAMICLIGHT.LF_ATTENUATE);
		else
			A_RemoveLight('RS_ElitePentagram');
	}

	States
	{
	Spawn:
		TNT1 A 1;
		Wait;
	}
}

// ---------------------------------------------------------------------
// RS_EliteController -- one per marked monster.
// ---------------------------------------------------------------------
class RS_EliteController : Thinker
{
	Actor mon;

	int  baseHealth;      // SpawnHealth() before we touched it
	int  boostedMax;      // what we boosted it to, and what reveal restores
	int  oldHealth;       // for OnHit edge detection
	bool revealed;
	bool isBoss;
	int  tickAcc;

	RS_EliteProfile profile;

	// Cached at construction so every controller is not hitting
	// CVar.FindCVar every tic.
	double dmgMult;
	bool   useMissileMore;
	bool   useMissileEvenMore;
	int    revealPct;
	bool   friendlyStaysFriendly;
	bool   pentagramOn;
	bool   pentagramFollowShade;
	color  pentagramFixed;
	double pentagramIntensity;
	bool   glowOn;
	color  revealShade;

	// -----------------------------------------------------------------
	// Marking. The health boost happens HERE, not at reveal -- the
	// overlong fight IS the tell, and it only works if the monster is
	// already tanky while it still looks ordinary. The reveal later
	// restores this same number; it is never multiplied twice.
	//
	// We cap the BONUS rather than the total. A total cap can land below
	// a big monster's base health and silently NERF it; capping the bonus
	// cannot. Our largest actors are 9999 HP, where an uncapped x3 plus
	// the refill is a ~45,000 damage war of attrition nobody finishes.
	// -----------------------------------------------------------------
	void Init(Actor a, bool boss, int healthPct, int bonusCap)
	{
		mon        = a;
		isBoss     = boss;
		baseHealth = a.SpawnHealth();

		int bonus = int(baseHealth * (double(healthPct) / 100.0 - 1.0));
		if (bonus < 0)
			bonus = 0;
		if (bonusCap > 0)
			bonus = min(bonus, bonusCap);

		boostedMax = baseHealth + bonus;

		mon.health      = boostedMax;
		// StartHealth too, so health bars read 100% on a marked monster.
		// That is concealment, not cosmetics: a bar showing 40/120 would
		// hand the player the tell the dormancy exists to withhold.
		mon.StartHealth = boostedMax;

		oldHealth = boostedMax;
	}

	// -----------------------------------------------------------------
	// The aggression flags cannot be set as flags on this build, so they
	// are multiplier maths -- and they go through the repo's existing
	// floor. Monster tiers already set their own MissileChanceMult, so we
	// multiply the CURRENT value rather than assigning from 1.0. Lower
	// fires MORE. The floor is the only thing standing between a revealed
	// zombieman and a turret.
	// -----------------------------------------------------------------
	private void RS_SetEliteMissileRate()
	{
		double mult = 1.0;
		if (useMissileMore)     mult *= 0.5;
		if (useMissileEvenMore) mult *= 0.125;

		double target = mon.MissileChanceMult * mult;

		double floorMult = 0.125;
		let cv = CVar.FindCVar("rs_mon_missilechance_floor");
		if (cv) floorMult = cv.GetFloat();

		mon.MissileChanceMult = (floorMult > 0) ? max(target, floorMult) : target;
	}

	// -----------------------------------------------------------------
	// THE REVEAL.
	// -----------------------------------------------------------------
	// The profile roll. This is the ONLY place it happens -- see the file
	// header for why it is at reveal and not at marking. A failed roll is
	// a complete, legitimate elite: boosted and mean, with no behaviour
	// layer. That is the common case by design.
	private void RollProfile()
	{
		let cv = CVar.FindCVar("rs_elite_profile_chance");
		int chance = cv ? cv.GetInt() : 50;

		if (chance <= 0 || random(1, 100) > chance)
			return;

		Name cls = RS_EliteRoster.RollProfile();
		if (cls == 'None')
			return;

		profile = RS_EliteProfile(new(cls));
		if (profile)
		{
			profile.ctl = self;
			profile.mon = mon;
		}
	}

	private void DoReveal()
	{
		revealed = true;

		// Rolled first so the shade, the aura and the pentagram can all
		// read the profile's identity in the same tic it is assigned.
		RollProfile();

		mon.health = boostedMax;
		mon.GiveInventory("RS_EliteRevealed", 1);
		mon.GiveInventory("RS_EliteResist", 1);

		// Set, not multiplied into.
		mon.DamageMultiply = dmgMult;

		// It forgets what it was doing and re-acquires -- usually you.
		mon.A_ClearTarget();

		mon.bALWAYSFAST       = true;
		mon.bNOINFIGHTING     = true;
		mon.bNOTARGET         = true;
		mon.bQUICKTORETALIATE = true;
		mon.bNOFEAR           = true;
		mon.bNOTIMEFREEZE     = true;
		mon.bSEEINVISIBLE     = true;
		mon.bDONTDRAIN        = true;
		mon.bNOBLOODDECALS    = true;
		mon.bNOICEDEATH       = true;
		mon.bDONTGIB          = true;
		mon.bDROPOFF          = true;
		mon.bBRIGHT           = true;

		if (isBoss)
		{
			// A boss never flinches and cannot be pushed around, but it
			// does not throw itself off ledges the way a regular elite
			// will. Deliberately not symmetrical.
			mon.bNOPAIN     = true;
			mon.bDONTTHRUST = true;
		}
		else
		{
			mon.bJUMPDOWN = true;
		}

		RS_SetEliteMissileRate();

		// A friendly monster stops being friendly when it wakes up,
		// unless the option says otherwise.
		if (mon.bFRIENDLY && !friendlyStaysFriendly)
			mon.bFRIENDLY = false;

		// The 5th argument is ATTENUATION, not pitch -- lower carries
		// FURTHER. The boss sting at 0.1 is very nearly map-wide, and
		// that is the intent: everyone should know.
		mon.A_StartSound("rs_elite_loop", 6, CHANF_LOOPING, 0.8,
		                 isBoss ? 0.4 : 1.2);
		mon.A_StartSound("rs_elite_reveal", 7, 0, 1.0, 0.6);
		if (isBoss)
			mon.A_StartSound("rs_elite_reveal_boss", 5, 0, 1.0, 0.1);

		// Held for the aura, which respawns every tic from here on.
		revealShade = (pentagramFollowShade && profile)
		            ? profile.GetShade()
		            : pentagramFixed;

		if (pentagramOn)
			DrawPentagram(revealShade);

		if (profile)
		{
			profile.OnSelected();
			profile.OnReveal();
		}
	}

	// -----------------------------------------------------------------
	// The pentagram: a particle circle plus a five-point star, drawn by
	// stepping two vertices at a time so the lines cross.
	//
	// Emitted ONCE with self-fading particles rather than redrawn every
	// tic. A per-tic redraw of this shape is ~740 particles a tic for
	// ~140 tics, which sails past the particle cap the moment two elites
	// reveal together -- so the effect would die exactly when it matters
	// most. The trade is that we lose the fade-IN, since particles can
	// fade out but not in; the light blooms instead, which reads the same.
	// -----------------------------------------------------------------
	private void DrawPentagram(color shade)
	{
		if (!mon)
			return;

		double radius = mon.Radius * 2.0;
		int    life   = 140;
		double zoff   = 2.0;
		double fade   = 1.0 / double(life);

		for (int i = 0; i < 360; i++)
		{
			double ang = double(i);
			mon.A_SpawnParticle(shade,
			                    SPF_FULLBRIGHT,
			                    life,
			                    frandom(1.0, 3.0),
			                    0,
			                    radius * cos(ang), radius * sin(ang), zoff,
			                    0, 0, 0,
			                    0, 0, 0,
			                    1.0, fade);
		}

		double px[5];
		double py[5];
		for (int v = 0; v < 5; v++)
		{
			double ang = 360.0 / 5.0 * double(v);
			px[v] = radius * cos(ang);
			py[v] = radius * sin(ang);
		}

		int p1 = 0;
		int p2 = 2;
		int steps = int(radius * 1.9);
		for (int lineN = 0; lineN < 5; lineN++)
		{
			double dx = px[p2] - px[p1];
			double dy = py[p2] - py[p1];
			double vecAng = atan2(dy, dx);

			for (int s = steps; s > 0; s--)
			{
				mon.A_SpawnParticle(shade,
				                    SPF_FULLBRIGHT,
				                    life,
				                    frandom(1.0, 3.0),
				                    0,
				                    px[p1] + double(s) * cos(vecAng),
				                    py[p1] + double(s) * sin(vecAng),
				                    zoff,
				                    0, 0, 0,
				                    0, 0, 0,
				                    1.0, fade);
			}

			p1 = p2;
			p2 = (p1 + 2) % 5;
		}

		let lit = RS_ElitePentagramLight(
			mon.Spawn("RS_ElitePentagramLight", mon.Pos, ALLOW_REPLACE));
		if (lit)
			lit.Setup(shade, radius * 2.0 * pentagramIntensity, life);
	}

	// One ghost per tic while revealed. The offset puts it one unit BEHIND
	// the monster along its facing, so the trail reads as something
	// peeling off it rather than sitting on top of it.
	private void SpawnAura()
	{
		if (!mon || !glowOn)
			return;

		Vector3 at = mon.Vec3Offset(-cos(mon.angle), -sin(mon.angle), 0);

		let ghost = RS_EliteAura(mon.Spawn("RS_EliteAura", at, ALLOW_REPLACE));
		if (ghost)
			ghost.SetupFrom(mon, revealShade, pentagramIntensity);
	}

	// Routed in from the handler. Profiles that modify the monster's own
	// projectiles land here.
	void RouteMissile(Actor missile)
	{
		if (revealed && profile)
			profile.OnMissileSpawned(missile);
	}

	override void Tick()
	{
		Super.Tick();

		if (!mon)
		{
			Destroy();
			return;
		}

		if (level.isFrozen())
			return;

		if (mon.health <= 0)
		{
			if (revealed)
			{
				// The aura ghosts are deliberately NOT cleaned up -- they
				// just stop being spawned and fade out on their own.
				mon.A_StopSound(6);
				mon.bBRIGHT = false;
				if (profile)
					profile.OnDeath();
			}

			// HAND EVERYTHING BACK, not just health.
			//
			// Profiles mutate stats on the monster directly -- damage
			// multipliers, damage factor, pain chance, mass. The
			// controller dies with the monster, so anything left mutated
			// stays mutated on the corpse, and an Archvile raising it
			// produces a monster with elite stats and NOBODY DRIVING IT.
			// It would not be marked, would not reveal, and would never
			// give any of it back.
			//
			// Restoring from Default rather than from a snapshot is
			// deliberate: a snapshot taken at reveal would itself contain
			// whatever an earlier profile had already changed.
			mon.StartHealth     = mon.Default.StartHealth;
			mon.PainChance      = mon.Default.PainChance;
			mon.DamageFactor    = mon.Default.DamageFactor;
			mon.DamageMultiply  = mon.Default.DamageMultiply;
			mon.Mass            = mon.Default.Mass;

			Destroy();
			return;
		}

		if (!revealed)
		{
			// Flat across the board on purpose: a fixed threshold is a
			// rule the player can learn and play around. A randomised one
			// just feels arbitrary.
			int trigger = int(double(boostedMax) * double(revealPct) / 100.0);
			if (mon.health <= trigger)
				DoReveal();

			oldHealth = mon.health;
			return;
		}

		SpawnAura();

		if (mon.health > oldHealth)
			oldHealth = mon.health;

		if (mon.health < oldHealth)
		{
			int taken = oldHealth - mon.health;
			oldHealth = mon.health;
			if (profile)
				profile.OnHit(taken);
		}

		if (profile && profile.tickInterval > 0)
		{
			tickAcc++;
			if (tickAcc >= profile.tickInterval)
			{
				tickAcc = 0;
				profile.OnTick();
			}
		}
	}
}

// =====================================================================
// RS_EliteHandler -- the sweep, and the event routing.
//
// Selection happens ONCE, at level load. Consequence, accepted: mid-level
// summons and archvile revives are never marked -- which also means we
// never inherit the summon-farm problem RS_Bits had to gate against at
// RS_Bits.zs:75. The optional re-sweep timer is the way back if wanted.
// =====================================================================
class RS_EliteHandler : EventHandler
{
	bool   enabled;
	int    per100;
	int    healthPct;
	int    bonusCap;
	int    markCeiling;
	int    bossMode;          // 0 normal, 1 never, 2 always
	int    tierBossThreshold; // -1 disables the tier axis
	bool   friendlies;
	bool   resweep;
	int    resweepSecs;
	int    resweepAcc;

	double dmgMult;
	double dmgMultBoss;
	int    healthPctBoss;
	int    revealPct;
	bool   missileMore;
	bool   missileEvenMore;
	bool   pentagramOn;
	bool   pentagramFollowShade;
	color  pentagramFixed;
	double pentagramIntensity;
	bool   glowOn;
	int    tierBumpChance;
	bool   debugOn;

	private int CVi(string n, int def)
	{
		let cv = CVar.FindCVar(n);
		return cv ? cv.GetInt() : def;
	}

	private double CVf(string n, double def)
	{
		let cv = CVar.FindCVar(n);
		return cv ? cv.GetFloat() : def;
	}

	private bool CVb(string n, bool def)
	{
		let cv = CVar.FindCVar(n);
		return cv ? cv.GetBool() : def;
	}

	private void ReadCVars()
	{
		enabled              = CVb("rs_elites_enable", true);
		per100               = CVi("rs_elites_per_100", 5);
		healthPct            = CVi("rs_elite_health_pct", 300);
		healthPctBoss        = CVi("rs_elite_health_pct_boss", 200);
		bonusCap             = CVi("rs_elite_health_bonus_cap", 2000);
		markCeiling          = CVi("rs_elite_mark_health_ceiling", 4000);
		bossMode             = CVi("rs_elite_boss_mode", 0);
		tierBossThreshold    = CVi("rs_elite_tier_boss_at", 10);
		friendlies           = CVb("rs_elite_friendlies", false);
		resweep              = CVb("rs_elite_resweep", false);
		resweepSecs          = CVi("rs_elite_resweep_secs", 60);
		dmgMult              = CVf("rs_elite_damage", 2.0);
		dmgMultBoss          = CVf("rs_elite_damage_boss", 1.5);
		revealPct            = CVi("rs_elite_reveal_pct", 50);
		missileMore          = CVb("rs_elite_missilemore", false);
		missileEvenMore      = CVb("rs_elite_missileevenmore", true);
		pentagramOn          = CVb("rs_elite_pentagram", true);
		pentagramFollowShade = CVb("rs_elite_pentagram_follow_shade", false);
		pentagramIntensity   = CVf("rs_elite_light_intensity", 1.0);
		glowOn               = CVb("rs_elite_glow", true);
		tierBumpChance       = CVi("rs_elite_tierbump_chance", 0);
		debugOn              = CVb("rs_elite_debug", false);

		// Stored as three ints so the menu can expose it as three sliders
		// rather than a hex string nobody can type.
		int r = CVi("rs_elite_light_r", 179);
		int g = CVi("rs_elite_light_g", 0);
		int b = CVi("rs_elite_light_b", 0);
		pentagramFixed = Color(255, r, g, b);
	}

	override void WorldLoaded(WorldEvent e)
	{
		ReadCVars();
		resweepAcc = 0;

		if (!enabled)
			return;

		int marked = Sweep();

		if (debugOn)
			Console.Printf("\cdRS_Elites\c-: swept map, marked %d", marked);
	}

	// Optional: keep marking more monsters as the level runs.
	override void WorldTick()
	{
		if (!enabled || !resweep)
			return;

		resweepAcc++;
		if (resweepAcc < resweepSecs * 35)
			return;

		resweepAcc = 0;
		int marked = Sweep();

		if (debugOn && marked > 0)
			Console.Printf("\cdRS_Elites\c-: resweep marked %d", marked);
	}

	private int Sweep()
	{
		int count = 0;
		ThinkerIterator it = ThinkerIterator.Create("Actor");
		Actor a;
		while (a = Actor(it.Next()))
		{
			if (TryMark(a))
				count++;
		}
		return count;
	}

	// True if this actor counts as a boss for RS_Elites.
	//
	// TWO AXES, and it is not a preference -- NO TIER IN THIS TREE SETS
	// bBOSS. +BOSS appears on six actors and every one is a FAMILY
	// (RS_Cyberdemon.zs:123, RS_Mastermind.zs:75, RS_ExBosses.zs:45/197/302,
	// RS_MonsterStages.zs:774/1109/1197). The ported Zombieman has none at
	// any tier, T10 through TEX. So the tier axis has to be a number
	// comparison; there is no flag behind it. See rs_25 part 5.
	private bool IsEliteBoss(Actor a)
	{
		if (a.bBOSS)
			return true;

		if (tierBossThreshold >= 0)
		{
			let mm = RS_MonsterMaster(a);
			if (mm && mm.Tier >= tierBossThreshold)
				return true;
		}

		return false;
	}

	private bool TryMark(Actor a)
	{
		if (!a || !a.bISMONSTER || a.health <= 0)
			return false;

		// Stops decorative and non-counting actors becoming elite.
		if (!a.bCOUNTKILL)
			return false;

		if (a.bSPECIAL)
			return false;

		if (a.CountInv("RS_EliteMark"))
			return false;

		if (a.bFRIENDLY && !friendlies)
			return false;

		bool boss = IsEliteBoss(a);

		if (boss && bossMode == 1)      // never
			return false;

		// The marking ceiling. A 9999 HP actor is already a set-piece;
		// making it secretly an elite on top just makes the dormant phase
		// unreachable.
		if (markCeiling > 0 && a.SpawnHealth() > markCeiling)
			return false;

		bool pass;
		if (boss && bossMode == 2)      // always
			pass = true;
		else if (per100 >= 100)
			pass = true;
		else if (per100 <= 0)
			pass = false;
		else
			pass = (random(1, 100) <= per100);

		if (!pass)
			return false;

		a.GiveInventory("RS_EliteMark", 1);
		let mark = RS_EliteMark(a.FindInventory("RS_EliteMark"));

		let ctl = RS_EliteController(new("RS_EliteController"));
		if (!ctl)
			return false;

		ctl.dmgMult               = boss ? dmgMultBoss : dmgMult;
		ctl.useMissileMore        = missileMore;
		ctl.useMissileEvenMore    = missileEvenMore;
		ctl.revealPct             = revealPct;
		ctl.friendlyStaysFriendly = friendlies;
		ctl.pentagramOn           = pentagramOn;
		ctl.pentagramFollowShade  = pentagramFollowShade;
		ctl.pentagramFixed        = pentagramFixed;
		ctl.pentagramIntensity    = pentagramIntensity;
		ctl.glowOn                = glowOn;

		ctl.Init(a, boss, boss ? healthPctBoss : healthPct, bonusCap);

		if (mark)
			mark.ctl = ctl;

		if (debugOn)
			Console.Printf("\cdRS_Elites\c-: marked %s (%d -> %d hp)%s",
			               a.GetClassName(), ctl.baseHealth, ctl.boostedMax,
			               boss ? ", boss" : "");

		return true;
	}

	// Profiles that modify the monster's own projectiles need to see them
	// at the moment they spawn; this is the only place that is visible.
	override void WorldThingSpawned(WorldEvent e)
	{
		if (!enabled || !e.Thing || !e.Thing.bMISSILE)
			return;

		Actor shooter = e.Thing.Target;
		if (!shooter)
			return;

		let mark = RS_EliteMark(shooter.FindInventory("RS_EliteMark"));
		if (mark && mark.ctl)
			mark.ctl.RouteMissile(e.Thing);
	}
}
