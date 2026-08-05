// ============================================================================
// RS_MonsterDebug.zs -- debug lineup spawner for the CH monster families.
// 2026-08-05, built with the chaingunner import at the owner's direction:
// "ensure my debug menu can spawn one of each monster with a little
// distance apart so they don't overlap."
//
// RS_MonsterDebugHandler MUST also be in MAPINFO.txt's AddEventHandlers --
// the two are a pair; a handler listed there without this class compiled is
// a hard crash at map load, and this class without the listing is a dead
// menu. Same rule as every other handler in this repo.
//
// Net events (menu buttons in MENUDEF's RS_MonsterDebug page, or console):
//   netevent rs_spawnall              -- every body from every family
//   netevent rs_spawnall_zombieman    -- one family
//   netevent rs_spawnall_shotgunner
//   netevent rs_spawnall_chaingunner
//
// Layout: one row per family, tier order 1..13 left to right (bosses at the
// right end), rows starting 256 in front of the player, 128 apart, columns
// 100 apart -- wide enough that a Radius-64 SpliceBaron summon won't stack.
// Spawned on the floor, facing the player, via the BODY classes directly
// (no stubs, no coloursets, no cvar rerolls -- the lineup is deterministic).
// ============================================================================

class RS_MonsterDebugHandler : EventHandler
{
	// One family's bodies, tier order. Minions/summons are not listed --
	// they arrive through their owners, same as in play.
	static void FamilyList(int family, out Array<Name> list)
	{
		list.Clear();
		switch (family)
		{
		case 0:   // Zombieman
			list.Push('RS_CommonZombie');    // T1
			list.Push('RS_GreenZombie');     // T2
			list.Push('RS_BlueZombie');      // T3
			list.Push('RS_PurpleZombie');    // T4
			list.Push('RS_YellowZombie');    // T5
			list.Push('RS_RedZombie');       // T6
			list.Push('RS_FireBluZombie2');  // T7
			list.Push('RS_GrayZombie2');     // T8
			list.Push('RS_AbyssZombie2');    // T9
			list.Push('RS_CyanZombie2');     // T12
			list.Push('RS_BrownZombie2');    // T13
			list.Push('RS_BlackZombie1');    // T10
			list.Push('RS_BlackZombieEX');   // T10 EX
			list.Push('RS_WhiteZombie1');    // T11
			break;
		case 1:   // Shotgunner
			list.Push('RS_CommonSG');
			list.Push('RS_GreenSG');
			list.Push('RS_BlueSG');
			list.Push('RS_PurpleSG');
			list.Push('RS_YellowSG');
			list.Push('RS_RedSG');
			list.Push('RS_FireBluSG2');
			list.Push('RS_GraySG2');
			list.Push('RS_AbyssSG2');
			list.Push('RS_CyanSG2');
			list.Push('RS_BrownSG2');
			list.Push('RS_BlackSG3');
			list.Push('RS_WhiteSG2');
			list.Push('RS_WhiteSGEX');
			break;
		case 2:   // Chaingunner
			list.Push('RS_CommonCGuy');
			list.Push('RS_GreenCGuy');
			list.Push('RS_BlueCGuy');
			list.Push('RS_PurpleCGuy');
			list.Push('RS_YellowCGuy');
			list.Push('RS_RedCGuy');
			list.Push('RS_FireBluCGuy2');
			list.Push('RS_GrayCGuy2');
			list.Push('RS_AbyssCGuy2');
			list.Push('RS_CyanCGuy2');
			list.Push('RS_BrownCGuy2');
			list.Push('RS_BlackCGuy2');
			list.Push('RS_BlackCGuyEX');
			list.Push('RS_WhiteCguy2');
			break;
		case 3:   // Imp
			list.Push('RS_CommonImp');
			list.Push('RS_GreenImp');
			list.Push('RS_BlueImp');
			list.Push('RS_PurpleImp');
			list.Push('RS_YellowImp');
			list.Push('RS_RedImp');
			list.Push('RS_FireBluImp2');
			list.Push('RS_GrayImp2');
			list.Push('RS_AbyssImp2');
			list.Push('RS_CyanImp2');
			list.Push('RS_BrownImp2');
			list.Push('RS_BlackImp1');
			list.Push('RS_BlackImpEX');
			list.Push('RS_WhiteImp2');
			break;
		}
	}

	// Spawns one family as a row. rowIndex 0 is the nearest row.
	static int SpawnFamilyRow(PlayerPawn pmo, int family, int rowIndex)
	{
		Array<Name> list;
		FamilyList(family, list);
		if (list.Size() == 0 || !pmo) return 0;

		double colSpacing = 100;
		double rowSpacing = 128;
		double baseDist = 256;

		Vector2 fwd = Actor.AngleToVector(pmo.Angle);
		Vector2 right = Actor.AngleToVector(pmo.Angle + 90);
		int spawned = 0;

		for (int i = 0; i < list.Size(); i++)
		{
			class<Actor> cls = list[i];
			if (!cls) continue;   // belt and braces; every name above is compiled in

			double lateral = (i - (list.Size() - 1) / 2.0) * colSpacing;
			Vector2 spot = pmo.Pos.XY
				+ fwd * (baseDist + rowIndex * rowSpacing)
				+ right * lateral;

			let mo = Actor.Spawn(cls, (spot.X, spot.Y, Actor.ONFLOORZ), ALLOW_REPLACE);
			if (mo)
			{
				mo.Angle = (pmo.Pos.XY - mo.Pos.XY).Angle();
				spawned++;
			}
		}
		return spawned;
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || !playeringame[e.Player]) return;
		let pmo = players[e.Player].mo;
		if (!pmo) return;

		int total = 0;
		if (e.Name == 'rs_spawnall')
		{
			total += SpawnFamilyRow(pmo, 0, 0);
			total += SpawnFamilyRow(pmo, 1, 1);
			total += SpawnFamilyRow(pmo, 2, 2);
			total += SpawnFamilyRow(pmo, 3, 3);
		}
		else if (e.Name == 'rs_spawnall_zombieman')   total = SpawnFamilyRow(pmo, 0, 0);
		else if (e.Name == 'rs_spawnall_shotgunner')  total = SpawnFamilyRow(pmo, 1, 0);
		else if (e.Name == 'rs_spawnall_chaingunner') total = SpawnFamilyRow(pmo, 2, 0);
		else if (e.Name == 'rs_spawnall_imp')         total = SpawnFamilyRow(pmo, 3, 0);
		else return;

		Console.Printf("RS_MonsterDebug: spawned %d monsters.", total);
	}
}
