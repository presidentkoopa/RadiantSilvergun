// =====================================================================
// RS_Zombieman_Undertaker -- the T12 White Zombieman's bone economy.
// ---------------------------------------------------------------------
// CHP source: CHP/DECORATE/01/01_W.txt. CH parent: CH/decorate/Zombies.txt:2282.
//
// THE MECHANIC, because it is not obvious from any single line of it:
// the Undertaker turns the whole level into its power supply, and both
// of the player's options are bad.
//
//   1. ON SPAWN it marks EVERY monster on the map -- CHP 01_W.txt:18,
//      A_Radiusgive("CHWhitePlan", 16383, RGF_NOSIGHT|RGF_MONSTERS).
//      Radius 16383, no line of sight required, straight through walls.
//   2. EVERY MARKED CORPSE HATCHES A SKELETON. Not only what the
//      Undertaker kills -- what the PLAYER kills. Its bone bolts leave
//      more (CHP 01_W.txt:6608, a 250/256 fail = ~2.3%) and its shovel
//      leaves them half the time (:7126, 128/256).
//   3. KILLING A SKELETON FEEDS THE BOSS. CHP 01_W.txt:3027-3029, on
//      MrBones' death:
//        A_Radiusgive("Health", 528, RGF_MONSTERS, random(12,128), <boss>)
//        A_Radiusgive("BoneUp", 528, RGF_MONSTERS, 1,              <boss>)
//      So clearing the adds heals the Undertaker 12-128 AND advances its
//      escalation ladder.
//   4. IGNORING THEM IS WORSE. Left alone the skeletons self-raise twice
//      and come back as Revenants.
//
// The ladder itself (BoneUp 5 / 9 / 12 -> Speed 16/21/28, Scale
// 1.1/1.25/1.45, +NOPAIN and the bone tornado at rung 3) lives in
// RS_Zombieman.zs's RS_ClimbLadder, which is where the tier's states
// can reach it.
//
// WHERE WE DIVERGE FROM CH, and why, per rs_21 s2:
//   * CH hatches the skeleton by editing the Death state of every
//     monster in the game -- 128 CHP files carry a `Tickles` jump. We
//     hook RS_MonsterMaster.Die() once instead. Identical behaviour, one
//     site rather than 128, and it cannot rot out of sync.
//   * The mark is never cleared when the Undertaker dies. CH does not
//     clear it either. A level it walked through keeps hatching, which
//     is the point.
// =====================================================================

// The mark. CH's CHWhitePlan is a bare Inventory token and so is this;
// all the behaviour is in who holds it and what reads it.
class RS_UndertakerPlan : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.QUIET
		-INVENTORY.INVBAR
	}
}

// The feed, spawned by RS_MrBones' death. A one-shot actor that pays the
// Undertaker and expires.
//
// A SEPARATE ACTOR RATHER THAN A_RadiusGive ON THE CORPSE because CH's
// call is filtered to the boss CLASS ("CommonWhiteZombie1") -- it pays
// the Undertaker and nothing else. RGF_EXFILTER cannot express "give to
// ONLY this class", only "give to everything EXCEPT". Doing it here lets
// the filter be a real class check.
class RS_BoneTithe : Actor
{
	Default
	{
		Radius 1; Height 1;
		+NOBLOCKMAP +NOGRAVITY +NOINTERACTION +NOCLIP
		RenderStyle "None";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		// CHP 01_W.txt:3027-3029 -- radius 528, boss only.
		ThinkerIterator it = ThinkerIterator.Create("RS_Zombieman");
		Actor a;
		while (a = Actor(it.Next()))
		{
			if (a.health <= 0)
				continue;
			if (a.Distance3D(self) > 528)
				continue;

			let zm = RS_MonsterMaster(a);
			if (!zm)
				continue;

			// Heal, then advance the ladder by one rung's worth of
			// charge. The roll is CH's and stays a roll.
			a.GiveBody(random(12, 128));
			zm.AddCharge(1);
		}

		Destroy();
	}
}
