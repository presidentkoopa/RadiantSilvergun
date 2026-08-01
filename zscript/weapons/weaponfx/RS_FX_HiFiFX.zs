// =====================================================================
// RS_HiFiFX -- the shared toolbox for muzzle smoke, casing ejection,
// magazine drops, and dynamic muzzle light.
// ---------------------------------------------------------------------
// Deliberately a plain static utility, not a mixin or a method on
// RS_Weapon -- any weapon's own action function can call into this
// regardless of what class it inherits from. That's what makes it
// usable by a future, entirely different weapon set later without
// rebuilding any of this: only the one-line call sites in that new
// set's own fire/reload actions would need to exist, not this file.
//
// Every method here reads the Hi-Fi tier itself and no-ops appropriately
// when a feature isn't active at the current tier -- callers never need
// to know or check the tier themselves.
// =====================================================================

class RS_HiFiFX
{
	enum ETier
	{
		RSFX_OFF = 0,
		RSFX_STANDARD = 1,
		RSFX_HIFI = 2
	}

	static int Tier()
	{
		let cv = CVar.GetCVar("rs_fx_hifitier", null);
		return cv ? cv.GetInt() : RSFX_OFF;
	}

	static bool RicochetOn()
	{
		let cv = CVar.GetCVar("rs_fx_ricochet", null);
		return cv ? cv.GetBool() : true;
	}

	// Barrel smoke. At Standard, only sustained/heavy fire spawns it
	// (caller passes heavyFire=true for full-auto/high-rate weapons);
	// at Hi-Fi, every shot gets a wisp.
	static play void MuzzleEffects(Actor shooter, bool heavyFire = false)
	{
		int tier = Tier();
		if (tier == RSFX_OFF)
			return;
		if (tier == RSFX_STANDARD && !heavyFire)
			return;

		double scaleVal = (tier == RSFX_HIFI) ? 0.18 : 0.12;
		double alphaVal = (tier == RSFX_HIFI) ? 0.35 : 0.22;

		let wisp = RS_SmokeWisp(shooter.Spawn("RS_SmokeWisp", shooter.Pos + (0, 0, shooter.Height * 0.5)));
		if (wisp)
			wisp.SetupVisual(alphaVal, scaleVal, 0.3);
	}

	// Shell/casing ejection -- cosmetic prop only, no gameplay effect.
	static play void CasingEject(Actor shooter, string casingClass, double xoff = 4.0, double zoff = 0.0)
	{
		if (Tier() == RSFX_OFF)
			return;
		if (!casingClass.Length())
			return;
		shooter.A_SpawnItemEx(casingClass, xoff, 0, zoff,
			FRandom(0.5, 1.5), FRandom(-1.0, 1.0), FRandom(2.0, 4.0), 0, 0, 128);
	}

	// Spent magazine/clip drop on reload -- a Hi-Fi-only flourish, since
	// it's the most visually "extra" of the three.
	static play void MagDrop(Actor shooter, string dropClass)
	{
		if (Tier() != RSFX_HIFI)
			return;
		if (!dropClass.Length())
			return;
		shooter.A_SpawnItemEx(dropClass, 0, 0, -4.0,
			FRandom(-1.0, 1.0), FRandom(-1.0, 1.0), 0, 0, 0, 128);
	}

	// Dynamic lights are the genuinely expensive part of Hi-Fi tier --
	// each one costs a real lighting pass, and a busy firefight (several
	// shooters, all firing at once) can otherwise stack many of them
	// simultaneously even though each only lives 3 tics. This cap is
	// what keeps that from becoming a real framerate problem regardless
	// of whose GPU is running it, not just a "should be fine" hope.
	//
	// User-adjustable (rs_fx_maxmuzzlelights) rather than a fixed
	// constant, since the right ceiling depends heavily on the GPU
	// running it -- 12 is a conservative default, not a hard limit.
	static int MaxMuzzleLights()
	{
		let cv = CVar.GetCVar("rs_fx_maxmuzzlelights", null);
		return cv ? cv.GetInt() : 12;
	}

	// Dynamic muzzle light -- Hi-Fi tier only; this is the expensive one.
	static play void SpawnMuzzleLight(Actor shooter)
	{
		if (Tier() != RSFX_HIFI)
			return;

		int cap = MaxMuzzleLights();
		int count = 0;
		let it = ThinkerIterator.Create("RS_MuzzleLight");
		while (it.Next())
		{
			count++;
			if (count >= cap)
				return; // at cap -- skip this one rather than add to the pile
		}

		shooter.A_SpawnItemEx("RS_MuzzleLight", 0, 0, 0, 0, 0, 0, 0, 0, 128);
	}
}
