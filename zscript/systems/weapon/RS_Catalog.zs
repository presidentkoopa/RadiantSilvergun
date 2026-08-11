// =====================================================================
// RS_Catalog -- AUTHOR-TIME NAMED CONSTANTS. Not an index.
// ---------------------------------------------------------------------
// Read this first, because the name is misleading and cost a day:
// nothing QUERIES this file. It exposes named accessors -- PROJ_Ballistic(),
// SND_Revolver_Resolve(), SCALE_Pellet, ScaleForArchetype() -- that a
// weapon calls BY NAME at compile time inside BuildAttackProfiles. 60+
// weapon files depend on those exact names.
//
// The runtime index is RS_FXRegistry, which tags actors by axis, role
// and theme so a card can ask for a kind of thing rather than a
// specific one. 51 of the actors named here also appear there; that is
// not duplication, it is the same actor with a name here and tags
// there. The 26 that were here and NOT there -- every GH and PS part --
// were added to the registry 2026-08-11, because until then no card
// could draw anything belonging to either imported weapon set.
//
// The third file is RS_PACKCatalog, the 409 monster attacks. Zero
// actor overlap with this file.
// ---------------------------------------------------------------------
// See docs/catalog_notes.txt. The rule: an imported weapon does NOT own
// its attack. Its projectile, sounds, and effects are extracted into
// standalone, ID-named entries here, and the weapon merely REFERENCES
// those IDs. Two weapons that fire the same kind of round point at the
// same catalog entry instead of each carrying a private copy of it.
//
// The payoff is that new attacks get ASSEMBLED from existing parts --
// pick a projectile ID, a fire sound ID, an impact ID -- rather than
// written as new code per weapon. That's what makes GunBonsai able to
// hand out a genuinely new attack later without anyone having authored
// that specific combination.
//
// ID CONVENTION:  RS_<CATEGORY>_<NAME>
//   RS_PROJ_*   projectile behaviour entries
//   RS_SND_*    fire / impact sound entries
// Set-specific assets keep their set in the path, not the ID -- an ID is
// a behaviour, not a filename, so a GH bullet and an RS bullet that
// behave identically should share one entry.
// =====================================================================

class RS_Catalog
{
	// -----------------------------------------------------------------
	// PROJECTILE ENTRIES
	// Each returns the actor class that carries the attack's movement,
	// visual identity and impact behaviour. Everything numeric --
	// damage, velocity, crit -- is supplied per-shot by the firing
	// weapon's rolled stats (see RS_Weapon.A_RS_FireSlot), so one entry
	// serves a Basic-tier and a Prototype-tier gun alike.
	// -----------------------------------------------------------------

	// Standard travelling ballistic round. The main-arsenal default.
	// =================================================================
	// PROJECTILE SCALE -- derived from whatever is FIRING, not authored
	// per attack.
	// -----------------------------------------------------------------
	// The problem this solves: the monster projectile library is 474
	// entries drawn for the monsters that originally threw them. Hand a
	// Cacodemon ball to a chaingunner and you get a sprite bigger than
	// the chaingunner. Hand-resizing 474 actors per possible user is not
	// a plan.
	//
	// So scale is a property of the FIRER's archetype. A rifle firing
	// Lost Souls asks its own archetype: keyword, gets "rifle", and the
	// Lost Soul comes out bullet-sized. Nobody authored that pairing --
	// the weapon already knows what it is.
	//
	// This is the DEFAULT only. RS_ShotKeywordMods.ScaleMult multiplies
	// on top, which is how an affix like "Giant Pellet" overrides it --
	// exactly the same fold-in shape as damage, pellets and spread.
	//
	// PRACTICAL NOTE: scaling DOWN reads clean; scaling up gets chunky
	// fast. The library was drawn for big monsters, so almost every
	// entry here is a reduction, which is the direction that looks good.
	// =================================================================

	static double SCALE_Pellet() { return 0.35; }
	static double SCALE_Bullet() { return 0.50; }
	static double SCALE_Normal() { return 1.00; }
	static double SCALE_Heavy()  { return 1.40; }
	static double SCALE_Huge()   { return 2.00; }

	// Comparison chain, not a static const table -- this engine build
	// doesn't resolve `static const TYPE name[] = {...}` in a class body.
	static double ScaleForArchetype(string archetype)
	{
		// Many small things.
		if (archetype == "shotgun" || archetype == "supershotgun"
		 || archetype == "smg")
			return SCALE_Pellet();

		// Single aimed rounds.
		if (archetype == "pistol" || archetype == "revolver"
		 || archetype == "rifle"  || archetype == "chaingun")
			return SCALE_Bullet();

		// Energy sits at native size -- the library's plasma/fire entries
		// were already drawn at roughly this weight.
		if (archetype == "energy" || archetype == "plasma")
			return SCALE_Normal();

		if (archetype == "launcher")
			return SCALE_Heavy();

		if (archetype == "bfg")
			return SCALE_Huge();

		// Melee archetypes never reach here (no projectile), and an
		// unknown archetype falling through at native size is the safe
		// failure: visibly wrong rather than invisibly tiny.
		return SCALE_Normal();
	}

	// Apply a resolved scale to a freshly spawned projectile.
	//
	// Scales THREE things together, because scaling only the sprite is
	// the classic mistake: a pellet-sized visual with a cacodemon-sized
	// hitbox reads as the game cheating. Damage is deliberately NOT
	// touched here -- that already rides DamageMult on the profile.
	//
	// No-ops at scale ~1.0, which is the overwhelmingly common case.
	static play void ApplyProjectileScale(Actor proj, double scale)
	{
		if (!proj || scale <= 0 || abs(scale - 1.0) < 0.01)
			return;

		proj.A_SetScale(proj.Scale.X * scale, proj.Scale.Y * scale);

		// Collision follows the visual. Floor at 1 so a heavily shrunk
		// round doesn't end up with a zero-size hitbox and pass through
		// everything it should hit.
		proj.A_SetSize(max(1.0, proj.Radius * scale),
		               max(1.0, proj.Height * scale));
	}

	// Monster-side equivalent, keyed on the role the monster declares.
	// Same idea, different input -- a chaingunner firing Cacodemon balls
	// is a bullet-delivery skirmisher, so it gets bullet scale.
	static double ScaleForMonsterRole(string role, string delivery)
	{
		if (delivery == "bullet")   return SCALE_Bullet();
		if (role == "fodder")       return SCALE_Bullet();
		if (role == "skirmisher")   return SCALE_Bullet();
		if (role == "artillery")    return SCALE_Normal();
		if (role == "bruiser")      return SCALE_Heavy();
		if (role == "summoner")     return SCALE_Normal();
		return SCALE_Normal();
	}

	static Class<Actor> PROJ_Ballistic()
	{
		return "RS_BallisticType1";
	}

	// Second selectable ballistic visual -- MeatGrinder's `Bullet` (TRAC).
	// Not a reskin of Type1: TRAC is an 8-way rotation set, so the round
	// holds its orientation as you strafe around it, where RSB0 cycles
	// five shapes regardless of viewing angle. See RS_PS_FX.zs.
	static Class<Actor> PROJ_Ballistic2()
	{
		return "RS_BallisticType2";
	}

	// Launched grenade -- arcs under gravity, bounces, two-stage blast.
	// Referenced by the GH Machine Gun's underbarrel alt-fire; the same
	// entry a Grenade Launcher import points at rather than duplicating.
	static Class<Actor> PROJ_GrenadeLaunched()
	{
		return "RS_GH_GrenadeLaunched";
	}

	// Hand-thrown variant -- same explosion, real slower toss arc. Was
	// missing entirely; HandGrenade shared the launcher's own projectile
	// (and its faster speed) with nothing distinguishing a toss from a
	// launched round.
	static Class<Actor> PROJ_GrenadeThrown()
	{
		return "RS_GH_GrenadeThrown";
	}

	// Heavy ordnance -- Rocket/Plasma/BFG, each carrying real vanilla
	// explosion behaviour plus SetupStats() (see RS_FX_HeavyProjectiles.zs).
	// Read via GetHeavyProjectile() rather than a bullet AttackProfile, but
	// still belongs in the catalog for the same reason every other
	// projectile does: a future affix or a different weapon shouldn't have
	// to know the literal class name to reuse the attack.
	static Class<Actor> PROJ_Rocket()
	{
		return "RS_EnhancedRocket";
	}

	static Class<Actor> PROJ_PlasmaBall()
	{
		return "RS_EnhancedPlasmaBall";
	}

	static Class<Actor> PROJ_BFGBall()
	{
		return "RS_EnhancedBFGBall";
	}

	// GunstarHeroes-specific heavy rounds -- real ported art/behavior, not
	// the vanilla-based Enhanced* skins above. See RS_GH_HeavyProjectiles.zs.
	static Class<Actor> PROJ_GH_BFGShot()
	{
		return "RS_GH_BFGShot";
	}

	static Class<Actor> PROJ_GH_PlasmaShot()
	{
		return "RS_GH_PlasmaShot";
	}

	static Class<Actor> PROJ_GH_UnmakerShot()
	{
		return "RS_GH_UnmakerShot";
	}

	// Real travelling bolts, not hitscan -- see RS_FX_RailProjectiles.zs
	// for why. Primary = coiled helix, secondary = straight BD-faithful.
	// Not GH-specific despite where it was first used -- generic shared
	// building block, same as PROJ_Ballistic() above, just built for the
	// Railgun first.
	static Class<Actor> PROJ_RailBolt()
	{
		return "RS_RailBolt";
	}

	static Class<Actor> PROJ_RailBoltStraight()
	{
		return "RS_RailBoltStraight";
	}

	// No source class existed for this in this project -- genuine new
	// build, real DamageType "Fire". See RS_GH_HeavyProjectiles.zs.
	static Class<Actor> PROJ_GH_FlameJet()
	{
		return "RS_GH_FlameJet";
	}

	// MeatGrinder set -- real ported art and behaviour, NOT a fallback to
	// the vanilla-derived Enhanced* skins. The pack's own plasma ball,
	// BFG ball and rocket, each its own selectable entry alongside the
	// existing ones rather than replacing them. See RS_PS_FX.zs.
	static Class<Actor> PROJ_PS_PlasmaShot()
	{
		return "RS_PS_PlasmaShot";
	}

	static Class<Actor> PROJ_PS_BFGShot()
	{
		return "RS_PS_BFGShot";
	}

	static Class<Actor> PROJ_PS_Rocket()
	{
		return "RS_PS_Rocket";
	}

	// Streak set (RS_ST_) -- PACK resources only, no weapons imported.
	// FlameJet is a real travelling round usable as a profile's
	// ProjectileClass (same shape as PROJ_GH_FlameJet); Grenade is a
	// re-skin of the launched-grenade body, arc/bounce/blast unchanged.
	// See RS_FX_Streak.zs.
	static Class<Actor> PROJ_ST_FlameJet()   { return "RS_ST_FlameJet"; }
	static Class<Actor> PROJ_ST_EnergyShot() { return "RS_ST_EnergyShot"; }
	static Class<Actor> PROJ_ST_Grenade()    { return "RS_ST_Grenade"; }

	// -----------------------------------------------------------------
	// CASING ENTRIES
	// Ejected shell/casing actors, read by RS_HiFiFX.CasingEject() as a
	// string (not Class<Actor> -- see its signature). Real classes live in
	// RS_FX_Casings.zs.
	// -----------------------------------------------------------------
	static string CASING_Small()  { return "RS_CasingSmall"; }
	static string CASING_Rifle()  { return "RS_CasingRifle"; }
	static string CASING_Shell()  { return "RS_CasingShell"; }

	// MeatGrinder brass -- settles into one of five resting frames, so a
	// littered floor doesn't tile. Second selectable casing pair.
	static string CASING_PS_Rifle() { return "RS_PS_CasingRifle"; }
	static string CASING_PS_Shell() { return "RS_PS_CasingShell"; }

	// -----------------------------------------------------------------
	// PLAYER FEEDBACK ENTRIES -- impact puffs, impact sparks, muzzle
	// smoke. Read by RS_AttackProfile.ImpactPuff/ImpactSparks/MuzzleSmoke
	// (bullet/hitscan profiles only). Real classes live in
	// RS_FX_Puffs.zs / RS_FX_Sparks.zs / RS_FX_Ricochet.zs / RS_FX_Smoke.zs.
	// -----------------------------------------------------------------
	static Class<Actor> PUFF_Bullet()   { return "RS_StreakPuff"; }
	static Class<Actor> PUFF_Shot()     { return "RS_EnhancedShotPuff"; }
	static Class<Actor> PUFF_Chainsaw() { return "RS_ChainsawPuff"; }
	static Class<Actor> PUFF_Vanilla()  { return "BulletPuff"; }

	// MeatGrinder impact puffs -- additive 10-frame flash with a 50/50
	// horizontal mirror so repeated hits don't rubber-stamp.
	static Class<Actor> PUFF_PS_Hit()  { return "RS_PS_HitPuff"; }
	static Class<Actor> PUFF_PS_Saw()  { return "RS_PS_SawPuff"; }

	static Class<Actor> SPARK_Hit()        { return "RS_HitSpark"; }
	static Class<Actor> SPARK_X()          { return "RS_SparkX"; }
	static Class<Actor> SPARK_XNoModel()   { return "RS_SparkXNoModel"; }
	static Class<Actor> SPARK_XHeavy()     { return "RS_SparkXHeavy"; }
	static Class<Actor> SPARK_Ricochet()   { return "RS_RicochetSpark"; }
	static Class<Actor> SPARK_Rail()       { return "RS_RailImpactSpark"; }

	static Class<Actor> SMOKE_Wisp() { return "RS_SmokeWisp"; }

	// In-flight trail piece dropped periodically behind a travelling
	// bullet -- see RS_FX_BallisticFired.zs's RS_BallisticFired.Tick().
	// Read as the default when an AttackProfile doesn't set its own
	// Trail override (RS_AttackProfile.Trail), same null-means-default
	// shape as the puff/spark/smoke entries above.
	// RS_TracerBit, not RS_StreakTrail, since 2026-08-08: the trail is a
	// DENSE distance-spaced line now rather than a few sparse bits, and
	// RST0's long smear turns into a solid bar when overlapped at that
	// density. RSB0's small dot is what the reference implementation
	// uses and it tapers correctly. RS_StreakTrail is kept as a named
	// option (TRAIL_Streak) rather than deleted -- it is still the right
	// look for anything that wants a sparse smear.
	static Class<Actor> TRAIL_Ballistic() { return "RS_TracerBit"; }
	static Class<Actor> TRAIL_Streak()    { return "RS_StreakTrail"; }

	// Streak set cosmetics -- no damage of their own, safe in any
	// ImpactPuff/Trail/ExplosionVisual slot. Kept as separate entries
	// rather than one composite so an affix can take the burst without
	// the ball. See RS_FX_Streak.zs.
	static Class<Actor> TRAIL_ST_Ember()     { return "RS_ST_EmberTrail"; }
	static Class<Actor> FIRE_ST_Flame()      { return "RS_ST_Flame"; }
	static Class<Actor> FIRE_ST_Cloud()      { return "RS_ST_FireCloud"; }
	static Class<Actor> PLASMA_ST_ArcImpact(){ return "RS_ST_ArcImpact"; }
	static Class<Actor> PLASMA_ST_Spray()    { return "RS_ST_EnergySpray"; }
	static Class<Actor> FLARE_ST_Glow()      { return "RS_ST_Glow"; }
	static Class<Actor> SPARK_ST_Scrap()     { return "RS_ST_ScrapShard"; }

	// Particle for RS_ST_Beam.Draw(). The beam GENERATOR is not a catalog
	// entry -- it's a static call, not a spawnable class -- but the thing
	// it spawns is, so a caller can swap the beam's look without touching
	// the generator:
	//     RS_ST_Beam.Draw(muzzlePos, hitPos, RS_Catalog.BEAM_ST_Arc());
	static Class<Actor> BEAM_ST_Arc()        { return "RS_ST_ArcTrail"; }

	// Ring-burst blast. EXPLOSION_ST_Ring is the assembled look and is the
	// one an ExplosionVisual slot wants; the three pieces below are
	// separate entries so an affix can take the sparks without the ring,
	// same reasoning as the MG blast set above. None of them carry damage.
	static Class<Actor> EXPLOSION_ST_Ring()  { return "RS_ST_Explosion"; }
	static Class<Actor> SPARK_ST_Ring()      { return "RS_ST_RingParticle"; }
	static Class<Actor> SPARK_ST_Blast()     { return "RS_ST_BlastSpark"; }
	static Class<Actor> SMOKE_ST_Blast()     { return "RS_ST_BlastSmoke"; }
	static Class<Actor> SPARK_ST_ScrapAlt()  { return "RS_ST_ScrapShardAlt"; }

	// -----------------------------------------------------------------
	// IMPACT / EXPLOSION ENTRIES -- standalone cosmetic-only visuals,
	// no damage of their own. Real classes live in RS_FX_Explosions.zs/
	// RS_FX_Flares.zs/RS_FX_Fire.zs/RS_FX_Plasma.zs. Read via a
	// projectile's own ExplosionVisual field (see RS_EnhancedRocket in
	// RS_FX_HeavyProjectiles.zs) so a weapon or future affix can swap
	// the blast look without touching the projectile's damage/splash
	// logic at all.
	// -----------------------------------------------------------------
	static Class<Actor> EXPLOSION_Fireball()    { return "RS_ExplosionFireball"; }
	static Class<Actor> EXPLOSION_FireballAlt() { return "RS_ExplosionFireballAlt"; }
	static Class<Actor> EXPLOSION_Small()       { return "RS_ExplosionSmall"; }
	static Class<Actor> EXPLOSION_Tiny()        { return "RS_ExplosionTiny"; }
	static Class<Actor> EXPLOSION_Flash()       { return "RS_ExplosionFlash"; }

	static Class<Actor> FLARE_Lens()     { return "RS_LensFlare"; }
	static Class<Actor> FLARE_LensAlt1() { return "RS_LensFlareAlt1"; }
	static Class<Actor> FLARE_LensAlt2() { return "RS_LensFlareAlt2"; }
	static Class<Actor> FLARE_LensAlt3() { return "RS_LensFlareAlt3"; }

	static Class<Actor> FIRE_Loop()    { return "RS_FireLoop"; }
	static Class<Actor> FIRE_LoopAlt() { return "RS_FireLoopAlt"; }

	static Class<Actor> PLASMA_Splash()    { return "RS_PlasmaSplash"; }
	static Class<Actor> PLASMA_SplashAlt() { return "RS_PlasmaSplashAlt"; }

	// ---- MeatGrinder blast assembly ---------------------------------
	// Deliberately kept as separate entries rather than one composite, so
	// an affix can take the shrapnel without the smoke. EXPLOSION_PS_Blast
	// is the assembled cosmetic half; it carries no damage of its own.
	static Class<Actor> EXPLOSION_PS_Blast()     { return "RS_PS_Explosion"; }
	static Class<Actor> EXPLOSION_PS_Fire()      { return "RS_PS_ExplosionFire"; }
	static Class<Actor> EXPLOSION_PS_FireSmall() { return "RS_PS_ExplosionFireSmall"; }
	static Class<Actor> EXPLOSION_PS_BFGBurst()  { return "RS_PS_BFGExtra"; }

	static Class<Actor> SPARK_PS_Shrapnel()      { return "RS_PS_Shrapnel"; }
	static Class<Actor> SPARK_PS_ShrapnelSmall() { return "RS_PS_ShrapnelSmall"; }

	static Class<Actor> SMOKE_PS_Blast()      { return "RS_PS_BlastSmoke"; }
	static Class<Actor> SMOKE_PS_BlastSmall() { return "RS_PS_BlastSmokeSmall"; }
	static Class<Actor> SMOKE_PS_BlastTiny()  { return "RS_PS_BlastSmokeTiny"; }
	static Class<Actor> SMOKE_PS_Pillar()     { return "RS_PS_SmokePillar"; }

	static Class<Actor> TRAIL_PS_Rocket()  { return "RS_PS_RocketTrail"; }
	static Class<Actor> FIRE_PS_Trail()    { return "RS_PS_FireTrail"; }
	static Class<Actor> PLASMA_PS_Particle() { return "RS_PS_PlasmaParticle"; }

	// -----------------------------------------------------------------
	// SOUND ENTRIES
	// Logical names, resolved through SNDINFO. A weapon references the
	// entry, never a raw lump path, so re-pointing a sound is one edit
	// here instead of one edit per weapon that used it.
	// -----------------------------------------------------------------

	// ---- Main arsenal: one fire-sound entry per weapon. ------------------
	// Logical names already declared in SNDINFO -- these wrap them, they
	// don't duplicate or rename them.
	static sound SND_Pistol()       { return "9mmshoot"; }
	static sound SND_Revolver()     { return "revolver"; }

	// Alternate fire-sound takes for the Weapon Sound Assignment options
	// menu (the "Fire Sounds" section of MENUDEF's RS_WeaponOptions,
	// rs_soundchoice_revolver).
	// Only the Revolver has real alternates staged today -- everything
	// else in the arsenal has exactly one cataloged fire sound, so their
	// menu rows only ever offer "Default" until more takes get sourced.
	static sound SND_Revolver_Resolve(int choice)
	{
		switch (choice)
		{
			case 1: return "rs_revolver_alt1";
			case 2: return "rs_revolver_alt2";
			case 3: return "rs_revolver_alt3";
			default: return SND_Revolver();
		}
	}
	static sound SND_Rifle()        { return "m16shoot"; }
	static sound SND_SMG()          { return "smgfire"; }
	static sound SND_Shotgun()      { return "shotgf"; }
	static sound SND_SuperShotgun() { return "wpn/shotgun2"; }
	static sound SND_Chaingun()     { return "chngun"; }
	static sound SND_Chainsaw()     { return "sawloop"; }
	static sound SND_RocketLauncher() { return "rocklf"; }
	static sound SND_PlasmaRifle()  { return "weapons/plasma/fire"; }
	static sound SND_BFG9000()      { return "bfgf"; }

	// ---- GunstarHeroes set: one fire-sound entry per weapon. -------------
	// Generated to match the SNDINFO block of the same names. A weapon
	// references the entry; nothing references a lump path directly.
	static sound SND_GH_Fist() { return "rs_gh/fist_fire"; }
	static sound SND_GH_Chainsaw() { return "rs_gh/chainsaw_fire"; }
	static sound SND_GH_Pistol() { return "rs_gh/pistol_fire"; }
	static sound SND_GH_Revolver() { return "rs_gh/revolver_fire"; }
	static sound SND_GH_PumpShotgun() { return "rs_gh/pumpshotgun_fire"; }
	static sound SND_GH_AssaultShotgun() { return "rs_gh/assaultshotgun_fire"; }
	static sound SND_GH_SSG() { return "rs_gh/ssg_fire"; }
	static sound SND_GH_Minigun() { return "rs_gh/minigun_fire"; }
	static sound SND_GH_Rifle() { return "rs_gh/rifle_fire"; }
	static sound SND_GH_SMG() { return "rs_gh/smg_fire"; }
	static sound SND_GH_MP40() { return "rs_gh/mp40_fire"; }
	static sound SND_GH_RocketLauncher() { return "rs_gh/rocketlauncher_fire"; }
	static sound SND_GH_GrenadeLauncher() { return "rs_gh/grenadelauncher_fire"; }
	static sound SND_GH_HandGrenade() { return "rs_gh/handgrenade_fire"; }
	static sound SND_GH_Plasma() { return "rs_gh/plasma_fire"; }
	static sound SND_GH_Railgun() { return "rs_gh/railgun_fire"; }
	static sound SND_GH_BFG9000() { return "rs_gh/bfg9000_fire"; }
	static sound SND_GH_BFG10k() { return "rs_gh/bfg10k_fire"; }
	static sound SND_GH_Unmaker() { return "rs_gh/unmaker_fire"; }
	static sound SND_GH_Flamethrower() { return "rs_gh/flamethrower_fire"; }
	static sound SND_GH_Machinegun() { return "rs_gh/machinegun_fire"; }

	// Grenade launch thump -- underbarrel and any future launcher.
	static sound SND_GH_GrenadeLaunch() { return "rs_gh/grenade_launch"; }

	// ---- MeatGrinder set: one fire-sound entry per weapon. --------------
	// The pack shipped five distinct fire sounds for nine weapons, so
	// several genuinely share one -- that sharing is the source's, not a
	// shortcut here. Declared in SNDINFO under the same logical names.
	static sound SND_PS_Fist()           { return "rs_ps/fist_fire"; }
	static sound SND_PS_Chainsaw()       { return "rs_ps/chainsaw_fire"; }
	static sound SND_PS_Machinegun()     { return "rs_ps/machinegun_fire"; }
	static sound SND_PS_AutoShotgun()    { return "rs_ps/autoshotgun_fire"; }
	static sound SND_PS_SSG()            { return "rs_ps/ssg_fire"; }
	static sound SND_PS_Chaingun()       { return "rs_ps/chaingun_fire"; }
	static sound SND_PS_RocketLauncher() { return "rs_ps/rocketlauncher_fire"; }
	static sound SND_PS_Plasma()         { return "rs_ps/plasma_fire"; }
	static sound SND_PS_BFG()            { return "rs_ps/bfg_fire"; }

	// Shotgun pump -- the source played this as a separate beat after the
	// SSG's second barrel, not as part of the fire sound.
	static sound SND_PS_ShotgunPump()    { return "rs_ps/shotgun_pump"; }

	// ---- Streak set (RS_ST_) -------------------------------------------
	// PACK audio, imported without any weapon that played it. Files in
	// sounds/rs_st_weapon/, logical names declared in SNDINFO.
	// The _explode/_shotgun_fire/_arc_fire entries are $random groups in
	// SNDINFO, not single files -- referencing one plays a different take
	// each time, which is why there is no _1/_2/_3 suffix here.
	static sound SND_ST_Pistol()      { return "rs_st/pistol_fire"; }
	static sound SND_ST_PistolAlt()   { return "rs_st/pistol_altfire"; }
	static sound SND_ST_Shotgun()     { return "rs_st/shotgun_fire"; }
	static sound SND_ST_ShotgunGren() { return "rs_st/shotgun_grenade"; }
	static sound SND_ST_SSG()         { return "rs_st/ssg_fire1"; }
	static sound SND_ST_SSGAlt()      { return "rs_st/ssg_altfire"; }
	static sound SND_ST_Chaingun()    { return "rs_st/chaingun_fire"; }
	static sound SND_ST_ChaingunAlt() { return "rs_st/chaingun_altfire"; }
	static sound SND_ST_Minigun()     { return "rs_st/minigun_fast"; }
	static sound SND_ST_MinigunSlow() { return "rs_st/minigun_slow"; }
	static sound SND_ST_SpinUp()      { return "rs_st/minigun_spinup"; }
	static sound SND_ST_SpinDown()    { return "rs_st/minigun_spindown"; }
	static sound SND_ST_Rocket()      { return "rs_st/rocket_fire"; }
	static sound SND_ST_RocketAlt()   { return "rs_st/rocket_altfire"; }
	static sound SND_ST_RocketFly()   { return "rs_st/rocket_fly"; }
	static sound SND_ST_Plasma()      { return "rs_st/plasma_fire"; }
	static sound SND_ST_PlasmaAlt()   { return "rs_st/plasma_altfire"; }
	static sound SND_ST_Arc()         { return "rs_st/arc_fire"; }
	static sound SND_ST_ArcCharge()   { return "rs_st/arc_charge"; }
	static sound SND_ST_ArcAlt()      { return "rs_st/arc_altfire"; }
	static sound SND_ST_BFG()         { return "rs_st/bfg_fire"; }
	static sound SND_ST_BFGAlt()      { return "rs_st/bfg_altfire"; }
	static sound SND_ST_Gyrojet()     { return "rs_st/gyrojet_fire"; }
	static sound SND_ST_Punch()       { return "rs_st/punch"; }

	// Flame is a three-beat set, not one sound: start once, loop while
	// held, stop on release. Both loops are $limit 1 in SNDINFO so a held
	// trigger can't stack them.
	static sound SND_ST_FlameStart()  { return "rs_st/flame_start"; }
	static sound SND_ST_FlameLoop()   { return "rs_st/flame_loop"; }
	static sound SND_ST_FlameStop()   { return "rs_st/flame_stop"; }

	// Impact / detonation.
	static sound SND_ST_Explode()        { return "rs_st/explode"; }
	static sound SND_ST_RocketExplode()  { return "rs_st/rocket_explode"; }
	static sound SND_ST_PlasmaExplode()  { return "rs_st/plasma_explode"; }
	static sound SND_ST_BFGExplode()     { return "rs_st/bfg_explode"; }
	static sound SND_ST_GyrojetExplode() { return "rs_st/gyrojet_explode"; }
	static sound SND_ST_ArcFry()         { return "rs_st/arc_fry"; }
	static sound SND_ST_ChaingunDet()    { return "rs_st/chaingun_detonate"; }
	static sound SND_ST_FistWall()       { return "rs_st/fist_wall"; }
	static sound SND_ST_HammerWall()     { return "rs_st/hammer_wall"; }

	// -----------------------------------------------------------------
	// WEAPON SOUND ASSIGNMENT DISPATCH
	// Single choke point for RS_Weapon.GetEffectiveFireSound(): given an
	// archetype (read straight off the weapon's own archetype: keyword,
	// not its class name) and a menu choice index, return the sound.
	// Add a new archetype's alternates here, and here only -- never by
	// touching an individual weapon file. fallback covers every
	// archetype with no case below (the common case today).
	// -----------------------------------------------------------------
	static sound ResolveArchetypeSound(string archetype, int choice, sound fallback)
	{
		if (archetype == "revolver")
			return SND_Revolver_Resolve(choice);
		return fallback;
	}
}
