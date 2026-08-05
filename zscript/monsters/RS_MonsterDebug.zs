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
//   netevent rs_spawnall_imp
//   netevent rs_spawnall_demon
//   netevent rs_spawnall_spectre
//   netevent rs_spawnall_lostsoul
//   netevent rs_spawnall_cacodemon
//   netevent rs_spawnall_painelemental
//   netevent rs_spawnall_hellknight
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
		case 4:   // Demon (Pinky)
			list.Push('RS_CommonDemon');     // T1
			list.Push('RS_GreenDemon');      // T2
			list.Push('RS_BlueDemon');       // T3
			list.Push('RS_PurpleDemon');     // T4
			list.Push('RS_YellowDemon');     // T5
			list.Push('RS_RedDemon');        // T6
			list.Push('RS_FireBluDemon2');   // T7
			list.Push('RS_GreyDemon2');      // T8
			list.Push('RS_AbyssDemon2');     // T9
			list.Push('RS_CyanDemon2');      // T12
			list.Push('RS_BrownDemon2');     // T13
			list.Push('RS_BlackDemon3');     // T10
			list.Push('RS_WhiteDemon2');     // T11
			list.Push('RS_PinkDemon');       // CH's orphan (Demons.txt:19, spawned
			                                 // by nothing in CH) -- only way to see it
			break;
		case 5:   // Spectre
			list.Push('RS_CommonSpectre');   // T1
			list.Push('RS_GreenSpectre');    // T2
			list.Push('RS_BlueSpectre');     // T3
			list.Push('RS_PurpleSpectre');   // T4
			list.Push('RS_YellowSpectre');   // T5
			list.Push('RS_RedSpectre');      // T6
			list.Push('RS_FireBluSpectre2'); // T7
			list.Push('RS_GraySpectre2');    // T8
			list.Push('RS_AbyssDemon2');     // T9 -- CH's abyss spectre IS the
			                                 // demon body (spectres.txt Pain.AbyssPE)
			list.Push('RS_CyanSpectre2');    // T12
			list.Push('RS_BrownSpectre2');   // T13
			list.Push('RS_BlackSpectre2');   // T10
			list.Push('RS_WhiteSpectre2');   // T11
			break;
		case 6:   // Lost Soul
			list.Push('RS_CommonLSoul');     // T1
			list.Push('RS_GreenLSoul');      // T2
			list.Push('RS_BlueLSoul');       // T3
			list.Push('RS_PurpleLSoul');     // T4
			list.Push('RS_YellowLSoul');     // T5
			list.Push('RS_RedLSoul');        // T6
			list.Push('RS_FireBluLSoul2');   // T7
			list.Push('RS_GrayLSoul2');      // T8
			list.Push('RS_AbyssLSoul2');     // T9
			list.Push('RS_CyanLSoul2');      // T12
			list.Push('RS_BrownLSoul2');     // T13
			list.Push('RS_BlackLSoul3');     // T10
			list.Push('RS_WhiteLSoul2');     // T11
			list.Push('RS_WhiteLSoulEX');    // T11 EX
			list.Push('RS_BlackLSoulOld3');  // CH's orphan (lostsouls.txt:1273,
			                                 // spawned by nothing in CH) -- only way to see it
			break;
		case 7:   // Cacodemon
			list.Push('RS_CommonCaco');      // T1
			list.Push('RS_GreenCaco');       // T2
			list.Push('RS_BlueCaco');        // T3
			list.Push('RS_PurpleCaco');      // T4
			list.Push('RS_YellowCaco');      // T5
			list.Push('RS_RedCaco');         // T6
			list.Push('RS_FireBluCaco2');    // T7
			list.Push('RS_GrayCaco2');       // T8
			list.Push('RS_AbyssCaco2');      // T9
			list.Push('RS_CyanCaco2');       // T12
			list.Push('RS_BrownCaco2');      // T13
			list.Push('RS_BlackCaco2');      // T10
			list.Push('RS_BlackCacoEX');     // T10 EX
			list.Push('RS_WhiteCaco2');      // T11 (phase 1; phase 2 hatches from its corpse)
			break;
		case 8:   // Pain Elemental
			list.Push('RS_CommonPE');        // T1
			list.Push('RS_GreenPE');         // T2
			list.Push('RS_BluePE');          // T3
			list.Push('RS_PurplePE');        // T4
			list.Push('RS_YellowPE');        // T5
			list.Push('RS_RedPE');           // T6
			list.Push('RS_FireBluPE2');      // T7
			list.Push('RS_GrayPE2');         // T8
			list.Push('RS_AbyssPE2');        // T9
			list.Push('RS_CyanPE2');         // T12
			list.Push('RS_BrownPE2');        // T13
			list.Push('RS_BlackPE2');        // T10
			list.Push('RS_WhitePE2');        // T11 (the Pilot phase spawns from its death)
			break;
		case 9:   // Hell Knight
			list.Push('RS_CommonHK');        // T1
			list.Push('RS_GreenHK');         // T2
			list.Push('RS_BlueHK');          // T3
			list.Push('RS_PurpleHK');        // T4
			list.Push('RS_YellowHK');        // T5
			list.Push('RS_RedHK');           // T6
			list.Push('RS_FireBluHK2');      // T7
			list.Push('RS_GrayHK2');         // T8
			list.Push('RS_AbyssHK2');        // T9
			list.Push('RS_CyanHK2');         // T12
			list.Push('RS_BrownHK2');        // T13
			list.Push('RS_BlackHK2');        // T10
			list.Push('RS_BlackHKEX');       // T10 EX
			list.Push('RS_WhiteHK3');        // T11 (spawns its twin ghost itself)
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
			total += SpawnFamilyRow(pmo, 4, 4);
			total += SpawnFamilyRow(pmo, 5, 5);
			total += SpawnFamilyRow(pmo, 6, 6);
			total += SpawnFamilyRow(pmo, 7, 7);
			total += SpawnFamilyRow(pmo, 8, 8);
			total += SpawnFamilyRow(pmo, 9, 9);
		}
		else if (e.Name == 'rs_spawnall_zombieman')     total = SpawnFamilyRow(pmo, 0, 0);
		else if (e.Name == 'rs_spawnall_shotgunner')    total = SpawnFamilyRow(pmo, 1, 0);
		else if (e.Name == 'rs_spawnall_chaingunner')   total = SpawnFamilyRow(pmo, 2, 0);
		else if (e.Name == 'rs_spawnall_imp')           total = SpawnFamilyRow(pmo, 3, 0);
		else if (e.Name == 'rs_spawnall_demon')         total = SpawnFamilyRow(pmo, 4, 0);
		else if (e.Name == 'rs_spawnall_spectre')       total = SpawnFamilyRow(pmo, 5, 0);
		else if (e.Name == 'rs_spawnall_lostsoul')      total = SpawnFamilyRow(pmo, 6, 0);
		else if (e.Name == 'rs_spawnall_cacodemon')     total = SpawnFamilyRow(pmo, 7, 0);
		else if (e.Name == 'rs_spawnall_painelemental') total = SpawnFamilyRow(pmo, 8, 0);
		else if (e.Name == 'rs_spawnall_hellknight')    total = SpawnFamilyRow(pmo, 9, 0);
		else return;

		Console.Printf("RS_MonsterDebug: spawned %d monsters.", total);
	}
}
