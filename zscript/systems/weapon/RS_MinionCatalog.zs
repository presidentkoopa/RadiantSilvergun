// =====================================================================
// RS_MinionCatalog -- what a payload affix is allowed to summon, and
// what each one costs.
// ---------------------------------------------------------------------
// Generated 2026-08-11 from a census of all 17 monster families and
// their Colourful Hell colourset variants. 143 summon-safe classes; every
// name here was verified to resolve against zscript/monsters/**.
//
// COST is a power number, 1..50, so an affix can be given a BUDGET rather
// than a hardcoded creature. "Cluster grenade spawning 2x skeletons" is
// two RS_CommonRevenant at 15 = 30. Anchors: zombieman 2, imp 5, demon 8,
// revenant 15, hellknight 20, baron 30.
//
// WHAT IS NOT IN HERE, and why, because the absences are load-bearing:
//
//   CYBERDEMONS and MASTERMINDS -- every variant carries +BOSS, including
//   the commons. Illegal by flag, not by price.
//
//   PAIN ELEMENTALS -- every tier's Missile state is A_PainAttack. A
//   minion that mints minions has no bound.
//
//   ARCHVILES -- worse than the others: a raised monster never passes
//   through RS_SummonMarker.WorldThingSpawned (reviving is not spawning),
//   so it keeps paying full score and Bits. A player-owned vile is a
//   reward-duplication engine. See RS_SummonMark.zs:80-83.
//
// Full reasoning, the spawn contract, and the per-family notes are in
// docs/rs_payload_bestiary.md. This file is the machine-readable half;
// that document is the argument.
// =====================================================================

class RS_MinionCatalog
{
	// Parallel arrays rather than a class-per-entry: this is read at
	// affix-install time to pick a bundle, never per tic, and a flat table
	// keeps the generated block reviewable as one diff.
	private static void Build(out Array<string> cls, out Array<int> cost,
		out Array<string> fam, out Array<int> hp, out Array<int> weight,
		out Array<bool> flying)
	{
		E(cls,cost,fam,hp,weight,flying, "RS_BlackLSoul2", 1, "lostsoul", 18, 0, true);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonZombie", 2, "zombieman", 20, 540, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanZombie2", 3, "zombieman", 30, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenZombie", 3, "zombieman", 40, 320, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonSG", 3, "shotgunner", 30, 600, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueZombie", 4, "zombieman", 60, 220, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenSG", 4, "shotgunner", 45, 300, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonCGuy", 4, "chaingunner", 70, 640, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonLSoul", 4, "lostsoul", 100, 429, true);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonImp", 5, "imp", 60, 630, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownZombie2", 5, "zombieman", 100, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueSG", 5, "shotgunner", 55, 280, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenCGuy", 5, "chaingunner", 85, 460, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenLSoul", 5, "lostsoul", 120, 320, true);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanLSoul2", 5, "lostsoul", 80, 60, true);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenImp", 6, "imp", 70, 360, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleZombie", 6, "zombieman", 95, 80, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluZombie2", 6, "zombieman", 70, 50, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayZombie2", 6, "zombieman", 110, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleSG", 6, "shotgunner", 75, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueCGuy", 6, "chaingunner", 105, 200, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueLSoul", 6, "lostsoul", 145, 175, true);
		E(cls,cost,fam,hp,weight,flying, "RS_WHOLETTHEDOGSOUT", 6, "demon", 120, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueImp", 7, "imp", 83, 180, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowSG", 7, "shotgunner", 85, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleLSoul", 7, "lostsoul", 150, 50, true);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonDemon", 8, "demon", 150, 500, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonSpectre", 8, "spectre", 150, 510, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleImp", 8, "imp", 105, 115, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowZombie", 8, "zombieman", 140, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GraySG2", 8, "shotgunner", 155, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleCGuy", 8, "chaingunner", 120, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanCGuy2", 8, "chaingunner", 125, 130, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluLSoul2", 8, "lostsoul", 175, 50, true);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownLSoul2", 8, "lostsoul", 125, 120, true);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenDemon", 9, "demon", 170, 400, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenSpectre", 9, "spectre", 175, 400, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedSG", 9, "shotgunner", 150, 33, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownSG2", 9, "shotgunner", 155, 40, false);
		E(cls,cost,fam,hp,weight,flying, "RS_SlimyWorm", 9, "chaingunner", 250, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueDemon", 10, "demon", 205, 180, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedZombie", 10, "zombieman", 186, 26, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownCGuy2", 10, "chaingunner", 250, 35, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowImp", 10, "imp", 145, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluImp2", 10, "imp", 125, 75, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedLSoul", 10, "lostsoul", 240, 20, true);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueSpectre", 11, "spectre", 210, 155, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowCGuy", 11, "chaingunner", 200, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluSG2", 11, "shotgunner", 225, 43, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonCaco", 12, "cacodemon", 400, 700, true);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleDemon", 12, "demon", 260, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleSpectre", 12, "spectre", 250, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluDemon2", 12, "demon", 205, 70, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanImp2", 12, "imp", 125, 120, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayCGuy2", 12, "chaingunner", 275, 35, false);
		E(cls,cost,fam,hp,weight,flying, "RS_Wakawaka", 12, "spectre", 320, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedImp", 13, "imp", 200, 55, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedCGuy", 13, "chaingunner", 300, 35, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluSpectre2", 13, "spectre", 205, 70, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlackSG2", 13, "shotgunner", 280, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssSG2", 14, "shotgunner", 300, 50, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownImp2", 14, "imp", 215, 65, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenCaco", 14, "cacodemon", 450, 400, true);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssLSoul2", 14, "lostsoul", 380, 40, true);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonRevenant", 15, "revenant", 300, 500, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayImp2", 15, "imp", 265, 65, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueCaco", 15, "cacodemon", 480, 200, true);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowDemon", 15, "demon", 325, 55, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowSpectre", 15, "spectre", 320, 40, false);
		E(cls,cost,fam,hp,weight,flying, "RS_ShotgunShrine", 15, "shotgunner", 800, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenRevenant", 16, "revenant", 360, 360, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssImp2", 16, "imp", 300, 75, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownCaco2", 16, "cacodemon", 500, 130, true);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanDemon2", 16, "demon", 270, 120, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanSpectre2", 16, "spectre", 270, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluCGuy2", 16, "chaingunner", 450, 20, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueRevenant", 17, "revenant", 420, 150, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleCaco", 17, "cacodemon", 528, 60, true);
		E(cls,cost,fam,hp,weight,flying, "RS_PinkDemon", 17, "demon", 500, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonSP1", 18, "spider", 500, 449, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssCGuy2", 18, "chaingunner", 500, 30, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanCaco2", 18, "cacodemon", 500, 100, true);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanRevenant2", 18, "revenant", 480, 120, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedDemon", 18, "demon", 400, 40, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownDemon2", 18, "demon", 420, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedSpectre", 18, "spectre", 394, 33, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleRevenant", 19, "revenant", 515, 75, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonFatso", 19, "fatso", 600, 400, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenSP1", 19, "spider", 600, 235, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownSP2", 19, "spider", 600, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GraySP2", 19, "spider", 600, 45, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonHK", 20, "hellknight", 500, 500, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayCaco2", 20, "cacodemon", 650, 60, true);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownSpectre2", 20, "spectre", 300, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GraySpectre2", 20, "spectre", 450, 45, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenFatso", 21, "fatso", 750, 220, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanFatso2", 21, "fatso", 720, 90, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueSP1", 21, "spider", 700, 155, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenHK", 22, "hellknight", 600, 400, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowCaco", 22, "cacodemon", 720, 40, true);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssDemon2", 22, "demon", 600, 40, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownRevenant2", 22, "revenant", 666, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayRevenant2", 22, "revenant", 660, 100, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanSP2", 22, "spider", 777, 90, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueHK", 23, "hellknight", 666, 150, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluRevenant2", 23, "revenant", 720, 50, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueFatso", 23, "fatso", 850, 130, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownFatso2", 23, "fatso", 850, 60, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleSP1", 23, "spider", 800, 65, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowSP1", 23, "spider", 777, 30, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluCaco2", 24, "cacodemon", 800, 35, true);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleHK", 25, "hellknight", 730, 75, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreyDemon2", 25, "demon", 700, 45, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleFatso", 25, "fatso", 950, 50, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedCaco", 26, "cacodemon", 830, 40, true);
		E(cls,cost,fam,hp,weight,flying, "RS_RedRevenant", 26, "revenant", 830, 21, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayFatso2", 26, "fatso", 1000, 33, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownHK2", 27, "hellknight", 700, 120, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanHK2", 27, "hellknight", 700, 120, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedSP1", 27, "spider", 1000, 25, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CommonBaron", 28, "baron", 1000, 500, false);
		E(cls,cost,fam,hp,weight,flying, "RS_SpliceBaron", 28, "chaingunner", 1000, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssRevenant2", 28, "revenant", 1000, 30, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GreenBaron", 30, "baron", 1170, 400, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowHK", 30, "hellknight", 999, 50, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayHK2", 30, "hellknight", 800, 75, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowFatso", 30, "fatso", 1250, 30, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BlueBaron", 32, "baron", 1309, 220, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluHK2", 32, "hellknight", 900, 20, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssCaco2", 32, "cacodemon", 1100, 40, true);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluFatso2", 32, "fatso", 1400, 20, false);
		E(cls,cost,fam,hp,weight,flying, "RS_PurpleBaron", 34, "baron", 1500, 145, false);
		E(cls,cost,fam,hp,weight,flying, "RS_CyanBaron2", 35, "baron", 1666, 135, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedFatso", 35, "fatso", 1600, 15, false);
		E(cls,cost,fam,hp,weight,flying, "RS_YellowBaron", 38, "baron", 1888, 50, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssSP2", 38, "spider", 1850, 45, false);
		E(cls,cost,fam,hp,weight,flying, "RS_GrayBaron2", 40, "baron", 2000, 35, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssFatso2", 40, "fatso", 2150, 35, false);
		E(cls,cost,fam,hp,weight,flying, "RS_RedBaron1", 40, "baron", 2000, ~0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_BrownBaron2", 42, "baron", 2250, 80, false);
		E(cls,cost,fam,hp,weight,flying, "RS_FireBluBaron2", 42, "baron", 2300, 35, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssHK2", 45, "hellknight", 1850, 0, false);
		E(cls,cost,fam,hp,weight,flying, "RS_AbyssBaron2", 50, "baron", 3333, 40, false);
	}

	private static void E(out Array<string> cls, out Array<int> cost,
		out Array<string> fam, out Array<int> hp, out Array<int> weight,
		out Array<bool> flying,
		string c, int co, string fa, int h, int w, bool fly)
	{
		cls.Push(c); cost.Push(co); fam.Push(fa);
		hp.Push(h); weight.Push(w); flying.Push(fly);
	}

	// -----------------------------------------------------------------
	// Everything the affix layer actually asks.
	// -----------------------------------------------------------------

	static int Count()
	{
		Array<string> c; Array<int> co; Array<string> f;
		Array<int> h; Array<int> w; Array<bool> fl;
		Build(c, co, f, h, w, fl);
		return c.Size();
	}

	// Cost of one named class, or -1 if it is not summon-safe. A -1 here
	// is the answer to "may I spawn this?" as well as "what does it cost?"
	static int CostOf(string what)
	{
		Array<string> c; Array<int> co; Array<string> f;
		Array<int> h; Array<int> w; Array<bool> fl;
		Build(c, co, f, h, w, fl);
		for (int i = 0; i < c.Size(); i++)
			if (c[i] == what) return co[i];
		return -1;
	}

	static bool IsSafe(string what) { return CostOf(what) >= 0; }

	// Everything affordable at or under a budget. The filter an affix uses
	// to roll a bundle: ask for the pool, then draw from it.
	// family "" means any; flyingOnly restricts to floaters, which is how
	// a payload avoids putting a ground monster in a pit it cannot leave.
	static void Affordable(int budget, out Array<string> outv,
		string family = "", bool flyingOnly = false)
	{
		outv.Clear();
		if (budget <= 0) return;

		Array<string> c; Array<int> co; Array<string> f;
		Array<int> h; Array<int> w; Array<bool> fl;
		Build(c, co, f, h, w, fl);

		for (int i = 0; i < c.Size(); i++)
		{
			if (co[i] > budget) continue;
			if (family != "" && f[i] != family) continue;
			if (flyingOnly && !fl[i]) continue;
			outv.Push(c[i]);
		}
	}

	// The most expensive thing a budget affords, which is how "one big one"
	// reads against "several small ones". Empty string if nothing fits.
	static string BestFor(int budget, string family = "", bool flyingOnly = false)
	{
		Array<string> c; Array<int> co; Array<string> f;
		Array<int> h; Array<int> w; Array<bool> fl;
		Build(c, co, f, h, w, fl);

		string best = ""; int bestCost = -1;
		for (int i = 0; i < c.Size(); i++)
		{
			if (co[i] > budget || co[i] <= bestCost) continue;
			if (family != "" && f[i] != family) continue;
			if (flyingOnly && !fl[i]) continue;
			best = c[i]; bestCost = co[i];
		}
		return best;
	}

	// N copies of one class, if the budget covers all N. Returns the class
	// or "" -- this is the "2x skeletons" question asked directly.
	static string BundleOf(int budget, int n, string family = "", bool flyingOnly = false)
	{
		if (n <= 0) return "";
		return BestFor(budget / n, family, flyingOnly);
	}
}
