// =====================================================================
// RS_MG_Zombieman -- rebuilt native from MeatGrinder V2C zombieman.txt
// (ACTOR Zombieman1). Gore actors live in RS_MG_Gore.zs.
//
// *** DELIBERATELY DOES NOT `replaces ZombieMan`, though the source does. ***
// RS_ZombieColourset already replaces ZombieMan, and two replacers on one
// vanilla class are resolved by parse order, silently, with the loser never
// spawning again. Which roster is live is decided by the rs_roster_pack
// selector instead -- see the RosterFamily/RosterSet lines below.
//
// WHAT IT IS: the rifle grunt. Vanilla stats, vanilla decision-making --
// A_Look / A_Chase / A_FaceTarget, no distance checks, no coordination.
// Its whole character is the DEATH WORK: five randomised dismemberment
// deaths plus separate saw, plasma and crush channels, eleven paths total.
//
// Behaviour is faithful to source and NOT embellished. The aggression and
// attack-variety work the owner asked about is a separate pass -- it does
// not exist in the source and is not invented here.
//
// CONVERSIONS: `Game Doom` and `SpawnID 4` deleted (DECORATE-only).
// A_PlaySound -> A_StartSound. Channel numbers kept as written.
//
// SOURCE QUIRK, LEFT ALONE: Death4 and Death5 are byte-identical -- both
// the ZXZ2 sequence with the same spray. A_Jump therefore has a 2-in-5
// chance of the same animation. Collapsing them is the kind of "obvious"
// tidy-up that has wrecked monster work in this repo before; it is the
// owner's call, not a transcription decision.
// =====================================================================

class RS_MG_Zombieman : RS_RosterMonster
{
	Default
	{
		// Self-registration. These two lines ARE the wiring -- there is no
		// central list to also update. See RS_Roster.zs.
		RS_RosterMonster.RosterFamily "ZombieMan";
		RS_RosterMonster.RosterSet    "RSMG";

		Health 20;
		Radius 20;
		Height 56;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "grunt/sight";
		AttackSound "grunt/attack";
		PainSound "grunt/pain";
		DeathSound "grunt/death";
		ActiveSound "grunt/active";
		Obituary "$OB_ZOMBIE";
		DropItem "Clip";
		BloodColor "darkred";
		Tag "Zombieman";
	}

	States
	{
	Spawn:
		POSS AB 10 A_Look;
		Loop;
	See:
		POSS AABBCCDD 4 A_Chase;
		Loop;
	Missile:
		POSS E 10 A_FaceTarget;
		TNT1 A 0 A_StartSound("ENEMYGUN", 1);
		TNT1 A 0 A_StartSound("MGUN2", 4);
		TNT1 A 0 A_CustomMissile("RS_MG_EnemyBullet", 38, 0, random(-6,6), 1, random(-1,1));
		POSS F 8;
		POSS E 8;
		Goto See;
	Pain:
		POSS G 3;
		POSS G 3 A_Pain;
		Goto See;
	Death.Melee:
		TNT1 A 0;
		TNT1 A 0 A_FaceTarget;
		TNT1 A 0 A_Recoil(10);
	Death:
		POSS H 0;
		TNT1 A 0 A_CustomMissile("RS_MG_CeilingBloodChecker", 50, 0, random(0,360), 2, random(60,90));
		POSS H 0 A_Jump(192, "Death1", "Death2", "Death3", "Death4", "Death5");
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 40, 0, random(0,360), 2, random(0,90));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		POSS H 5;
		POSS I 5 A_Scream;
		POSS J 5 A_NoBlocking;
		POSS K 5;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		POSS L -1;
		Stop;
	Death1: // Leg
		TNT1 AAAA 0 A_CustomMissile("RS_MG_BloodFast", 20, 0, random(0,360), 2, random(0,90));
		TNT1 A 0 A_CustomMissile("RS_MG_ZombiemanLeg", 10, 0, random(0,360), 2, random(40,50));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		POS7 A 6 A_Scream;
		POS7 B 6 A_NoBlocking;
		POS7 C 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		POS7 D -1;
		Stop;
	Death2: // Arm
		TNT1 AAA 0 A_CustomMissile("RS_MG_BloodFast", 20, 0, random(0,360), 2, random(0,90));
		TNT1 A 0 A_CustomMissile("RS_MG_Arm", 50, 0, random(0,360), 2, random(40,60));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		ZZD2 A 6 A_Scream;
		ZZD2 B 6 A_NoBlocking;
		ZZD2 CD 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		ZZD2 E -1;
		Stop;
	Death3: // Head
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 50, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meatb", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2b", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		ZZD6 B 6 A_Scream;
		ZZD6 C 6 A_NoBlocking;
		ZZD6 DEF 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		ZZD6 G -1;
		Stop;
	Death4: // Guts
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 30, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meatb", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2b", 30, 0, random(0,360), 2, random(10,45));
		ZXZ2 A 6 A_Scream;
		ZXZ2 B 6 A_NoBlocking;
		ZXZ2 BCD 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		ZXZ2 E -1;
		Stop;
	Death5: // Heavy -- identical to Death4 in source; see header.
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 30, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meatb", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2b", 30, 0, random(0,360), 2, random(10,45));
		ZXZ2 A 6 A_Scream;
		ZXZ2 B 6 A_NoBlocking;
		ZXZ2 BCD 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		ZXZ2 E -1;
		Stop;
	XDeath:
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 60, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 50, 0, random(0,360), 2, random(30,90));
		TNT1 AAAA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		TNT1 AA 0 A_CustomMissile("RS_MG_Arm", 50, 0, random(0,360), 2, random(40,60));
		TNT1 AAA 0 A_CustomMissile("RS_MG_Meat", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AAA 0 A_CustomMissile("RS_MG_Meat2", 50, 0, random(0,360), 2, random(10,45));
		POSS N 5 A_XScream;
		POSS O 5 A_NoBlocking;
		POSS PQRST 5;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 40, 0, random(0,360), 2, random(10,45));
		POSS U -1;
		Stop;
	Death.Saw:
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 60, 0, random(0,360), 2, random(0,90));
		TNT1 AAA 0 A_CustomMissile("RS_MG_BloodBig", 50, 0, random(0,360), 2, random(30,90));
		TNT1 AAA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AAA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(10,45));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 40, 0, random(0,360), 2, random(10,45));
		POSS N 5 A_XScream;
		POSS O 5 A_NoBlocking;
		POSS PQRST 5;
		POSS U -1;
		Stop;
	Raise:
		POSS K 5;
		POSS JIH 5;
		Goto See;
	Death.Plasma:
		DPS1 A 0 A_Stop;
		DPS1 A 0 A_XScream;
		DPS1 A 0 A_NoBlocking;
		TNT1 A 0 A_SpawnItem("RS_MG_SmokePillar");
		TNT1 A 0 A_CustomMissile("RS_MG_Meat", 50, 0, random(0,360), 2, random(10,45));
		TNT1 A 0 A_CustomMissile("RS_MG_Meat2", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 60, 0, random(0,360), 2, random(0,90));
		TNT1 AAA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 40, 0, random(0,360), 2, random(10,45));
		DPS1 ABCDEFG 4;
		DPS1 H -1;
		Stop;
	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("RS_MG_BloodCrushed", 0, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2", 50, 0, random(0,360), 2, random(10,45));
		CRSH A 1;
		CRSH A -1;
		Stop;
	}
}
