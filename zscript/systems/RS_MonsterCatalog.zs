// =====================================================================
// RS_MonsterCatalog -- the monster-side parts bin.
// ---------------------------------------------------------------------
// Exactly the same job RS_Catalog.zs does for weapons, and deliberately
// a SEPARATE file rather than entries bolted into that one:
//   * weapon lookups shouldn't have to wade past monster entries;
//   * monsters need entry kinds weapons don't have -- summon rosters,
//     satellites, portals, morph stages;
//   * it mirrors the subsystem-split convention already in the tree
//     rather than growing one god-file.
//
// THE RULE: no monster file names a raw projectile, minion, satellite,
// or effect class inline. Everything routes through here, so swapping
// what an Archvile summons is a one-line edit in one known place rather
// than a hunt through fifteen monster files.
//
// Also defines the small shared actor bases the primitives depend on
// (RS_MonsterSatellite, RS_SummonPortal) -- they're catalog machinery,
// not monster content.
// =====================================================================

class RS_MonsterCatalog
{
	// =================================================================
	// SUMMON ROSTERS
	// -----------------------------------------------------------------
	// Colourful Hell's summoners don't spawn one fixed thing -- they
	// pick from a table, and the table gets nastier as a charge counter
	// climbs. These return a class by roster + step, so a monster asks
	// for "tier 2 of the archvile roster" and never names a class.
	//
	// Comparison chains, not static const arrays: this engine build
	// doesn't resolve `static const TYPE name[] = {...}` in a class body
	// reliably (three real bugs so far).
	// =================================================================

	// The Archvile's escalating portal roster. CHP's Abyss portal ramps
	// Revenant -> Imp -> Cacodemon as its charge climbs; this is that
	// ladder, widened slightly at the top so a long fight keeps
	// escalating instead of flatlining on Cacodemons.
	static Class<Actor> ROSTER_VilePortal(int step)
	{
		if (step <= 0) return "RS_Imp";
		if (step == 1) return "RS_Revenant";
		if (step == 2) return "RS_Cacodemon";
		if (step == 3) return "RS_HellKnight";
		return "RS_Baron";
	}

	// The Gray Archvile's flat conjure -- CHP picks one of six with
	// equal odds and no escalation. Kept flat on purpose: it's the
	// "wide but shallow" counterpart to the portal's "narrow but
	// deepening" ladder, and the contrast is the design.
	static Class<Actor> ROSTER_VileConjure(int pick)
	{
		if (pick <= 0) return "RS_Demon";
		if (pick == 1) return "RS_Chaingunner";
		if (pick == 2) return "RS_Revenant";
		if (pick == 3) return "RS_HellKnight";
		if (pick == 4) return "RS_Spectre";
		return "RS_Cacodemon";
	}

	static int ROSTER_VileConjureCount() { return 6; }

	// Baron's tentacle pack -- two different minion shapes from one
	// summoner, a melee rusher and a ranged plinker, so the pack has
	// internal structure rather than being four copies of one thing.
	static Class<Actor> MINION_BaronRusher()  { return "RS_BaronTentacle"; }
	static Class<Actor> MINION_BaronRanger()  { return "RS_BaronTentacleRanged"; }

	// Pain Elemental's permanent escort. Small, fast, replaced when it
	// dies -- the thing that makes the White PE fight feel maintained
	// rather than a one-shot summon.
	static Class<Actor> MINION_Sentinel()     { return "RS_PainSentinel"; }

	// The Butcher's pack -- fast fragile harassers released by a
	// hit-counter rather than summoned on a timer.
	static Class<Actor> MINION_DemonDog()     { return "RS_DemonDog"; }

	// =================================================================
	// SATELLITES -- orbiting attached children.
	// =================================================================

	static Class<Actor> SAT_VileEye()  { return "RS_VileEye"; }

	// =================================================================
	// PORTALS / SPAWNERS -- free-standing objects that summon on their
	// own schedule rather than the monster summoning directly.
	// =================================================================

	static Class<Actor> PORTAL_Vile()  { return "RS_VilePortal"; }

	// =================================================================
	// MORPH STAGES -- the "death is a phase change" chain.
	// =================================================================

	static Class<Actor> MORPH_CacoReal()   { return "RS_CacodemonReal"; }
	static Class<Actor> MORPH_PainPilot()  { return "RS_PainPilot"; }
	static Class<Actor> MORPH_BaronFallen(){ return "RS_BaronFallen"; }

	// Revenant chain: body -> shade -> (shade brings a bound shadow).
	static Class<Actor> MORPH_RevShade()   { return "RS_RevenantShade"; }
	static Class<Actor> MORPH_RevShadow()  { return "RS_RevenantShadow"; }

	// Arachnotron shrink chain: full -> split -> remnant -> shards.
	static Class<Actor> MORPH_ArachStage2(){ return "RS_ArachnotronStage2"; }
	static Class<Actor> MORPH_ArachStage3(){ return "RS_ArachnotronStage3"; }

	// EX tier -- the vile boss dies into a phantom rather than ending.
	static Class<Actor> MORPH_ExVilePhantom(){ return "RS_EX_ArchvilePhantom"; }

	// =================================================================
	// MONSTER PROJECTILES
	// -----------------------------------------------------------------
	// Every entry below resolves to a real class in
	// zscript/monsters/monsterfx/ -- the 474-entry library extracted per
	// docs/catalog_notes.txt. Nothing here is a placeholder name.
	//
	// The point of routing through these accessors rather than naming
	// the class in the monster file: swapping what the Baron's tendrils
	// throw is one edit here, and the same projectile can be handed to
	// an affix or a weapon later without hunting for it.
	// =================================================================

	// --- Archvile ---
	static Class<Actor> PROJ_VileSpike()     { return "RS_VileGroundSpike"; }
	static Class<Actor> PROJ_VileBolt()      { return "RS_WVileBolt1"; }
	static Class<Actor> PROJ_VileBoltHeavy() { return "RS_WVileBolt2"; }
	static Class<Actor> PROJ_VileIce()       { return "RS_IceABVile"; }
	static Class<Actor> PROJ_VileDrop()      { return "RS_RockVileDrop"; }

	// --- Baron / tendrils ---
	static Class<Actor> PROJ_BaronStar()     { return "RS_BaronStar"; }
	static Class<Actor> PROJ_BaronRing()     { return "RS_BaronRing"; }
	static Class<Actor> PROJ_BaronBomb()     { return "RS_BaronFbomb"; }
	static Class<Actor> PROJ_TendrilBolt()   { return "RS_Firehand1"; }

	// --- Cacodemon ---
	static Class<Actor> PROJ_CacoBall()      { return "RS_CacoBallBase"; }
	static Class<Actor> PROJ_CacoFire()      { return "RS_CacoFire3"; }
	static Class<Actor> PROJ_CacoIce()       { return "RS_BigIceCaco"; }

	// --- Pain Elemental / sentinels ---
	static Class<Actor> PROJ_SentinelFlare() { return "RS_PlasmaPE"; }
	static Class<Actor> PROJ_PainPulse()     { return "RS_AbyssPEPulse"; }
	static Class<Actor> PROJ_PainStorm()     { return "RS_StormShot1"; }

	// --- Mancubus / Arachnotron ---
	static Class<Actor> PROJ_MancFire()      { return "RS_FatsoShotYE"; }
	static Class<Actor> PROJ_ArachPlasma()   { return "RS_ArachnotronPlasma"; }

	// =================================================================
	// SOUNDS
	// =================================================================

	static sound SND_Summon()   { return "vile/firecrkl"; }
	static sound SND_Enrage()   { return "vile/sight"; }
	static sound SND_Morph()    { return "misc/spawn"; }
}

// =====================================================================
// RS_MonsterSatellite -- base for anything that orbits its master.
// ---------------------------------------------------------------------
// The lifecycle CHP arrived at (and R2 of the earlier research pass
// confirmed as the pattern worth adopting): spawn attached via master,
// warp to the master every tic, and die when the master does. The
// master-death check is what stops orphaned satellites hanging in the
// air over a corpse forever.
//
// Cosmetic-only by default -- no damage, no blocking. A subclass that
// wants to be dangerous overrides that itself.
// =====================================================================

class RS_MonsterSatellite : Actor
{
	double OrbitRadius;
	double OrbitHeight;
	double OrbitAngle;
	double OrbitSpeed;

	Default
	{
		Radius 8;
		Height 8;
		+NOGRAVITY
		+NOBLOCKMAP
		+NOCLIP
		+DONTSPLASH
		+NOTELEPORT
		RenderStyle "Add";
		Alpha 0.85;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (OrbitRadius <= 0) OrbitRadius = 40;
		if (OrbitHeight <= 0) OrbitHeight = 40;
		if (OrbitSpeed  == 0) OrbitSpeed  = 6.0;
	}

	override void Tick()
	{
		Super.Tick();

		// No master, or the master is dead/gone -- we go too. This is
		// the cleanup that the old DECORATE version did by broadcasting
		// a "GoAway" inventory item; a direct check is cheaper and
		// can't be missed.
		if (!master || master.health <= 0)
		{
			Destroy();
			return;
		}

		OrbitAngle += OrbitSpeed;
		if (OrbitAngle >= 360.0) OrbitAngle -= 360.0;

		Vector3 p = (master.pos.xy + (cos(OrbitAngle), sin(OrbitAngle)) * OrbitRadius,
		             master.pos.z + OrbitHeight);
		SetOrigin(p, true);
		angle = OrbitAngle + 90;
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}
}

// =====================================================================
// RS_VileEye -- the Archvile's orbiting eye.
// Visual tell that the vile is in its summoning phase; the player
// learns "eyes out = adds incoming" without a HUD message.
// =====================================================================

class RS_VileEye : RS_MonsterSatellite
{
	Default
	{
		Scale 0.35;
		Alpha 0.9;
	}

	States
	{
	Spawn:
		PUFI ABCD 3 Bright;
		Loop;
	}
}

// =====================================================================
// RS_VilePortal -- a free-standing summoner.
// ---------------------------------------------------------------------
// CHP's Abyss Archvile doesn't summon directly: it drops one of these
// and the PORTAL does the escalating. That indirection is worth keeping
// because it changes the fight's shape -- the player gets a second
// object worth destroying, and killing it early denies the ramp.
//
// Charge climbs every tic it's alive. At each threshold it spawns the
// next entry from the roster, so leaving it alone is what makes the
// fight get worse.
// =====================================================================

class RS_VilePortal : Actor
{
	int  PortalCharge;
	int  PortalStep;
	int  PortalTier;        // set by whoever spawned it
	int  nextSpawnTic;

	const RS_PORTAL_INTERVAL = 105;   // 3 seconds between escalations
	const RS_PORTAL_MAXSTEP  = 4;

	Default
	{
		Health 120;
		Radius 20;
		Height 56;
		+NOGRAVITY
		+SHOOTABLE
		+NOBLOOD
		+DONTTHRUST
		-COUNTKILL
		RenderStyle "Add";
		Alpha 0.8;
		DeathSound "misc/spawn";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		nextSpawnTic = level.time + RS_PORTAL_INTERVAL;
	}

	override void Tick()
	{
		Super.Tick();

		if (health <= 0 || level.time < nextSpawnTic)
			return;

		nextSpawnTic = level.time + RS_PORTAL_INTERVAL;

		Class<Actor> cls = RS_MonsterCatalog.ROSTER_VilePortal(PortalStep);
		if (cls)
		{
			double ang = random(0, 359);
			Vector3 p = (pos.xy + (cos(ang), sin(ang)) * 64.0, pos.z);
			let mo = Spawn(cls, p, ALLOW_REPLACE);
			if (mo)
			{
				mo.bCOUNTKILL = false;
				mo.master = master;
				mo.target = target;
				let rm = RS_MonsterMaster(mo);
				if (rm)
					rm.SetTier(clamp(PortalTier - 2 + PortalStep, 0, 12), true);
			}
		}

		// Each spawn escalates the next one. This is the whole mechanic:
		// the longer the portal lives, the worse what comes out of it.
		if (PortalStep < RS_PORTAL_MAXSTEP)
			PortalStep++;
	}

	States
	{
	Spawn:
		TFOG ABABCDEFGHIJ 4 Bright;
		Goto Idle;
	Idle:
		TFOG GHIJ 6 Bright;
		Loop;
	Death:
		TFOG JIHG 5 Bright;
		Stop;
	}
}
