// =====================================================================
// RS_MG_Shotgunner -- rebuilt native from MeatGrinder V2C zombieman.txt
// (ACTOR ShotgunGuy1). Gore actors live in RS_MG_Gore.zs.
//
// *** DELIBERATELY DOES NOT `replaces ShotgunGuy`, though the source does. ***
// Same reason as the zombieman: RS_ShotgunnerColourset already claims that
// slot, and the rs_roster_pack selector decides which roster is live.
//
// WHAT IT IS: the shotgun sergeant. Fires THREE RS_MG_EnemyBullet
// projectiles in one A_CustomMissile burst -- a real spread, not a
// hitscan cone -- then works the pump (SPSR) before returning to chase.
// Decision-making is vanilla; the character is in the deaths.
//
// Its head-death is gorier than the zombieman's: on top of the shared
// meat and chunk spray it throws GibHeadPiece x3, GibTeeth and GibEyeball.
//
// SOURCE QUIRKS, LEFT ALONE (both verbatim, neither is a transcription
// slip -- flagged so nobody "fixes" them later without the owner):
//   * XDeath, Death.Saw and the XDeath tail all draw POSS frames, i.e.
//     the ZOMBIEMAN's sprite, not SPOS. A gibbed sergeant renders as a
//     gibbed rifleman in the original.
//   * Death3 ends `SPDH DE 6` then rests on `SPDH E -1` -- frame E twice,
//     so the last animation frame holds rather than advancing to F.
// =====================================================================

class RS_MG_Shotgunner : RS_RosterMonster
{
	Default
	{
		// Self-registration -- see RS_Roster.zs. No central list.
		RS_RosterMonster.RosterFamily "ShotgunGuy";
		RS_RosterMonster.RosterSet    "RSMG";

		Health 30;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "shotguy/sight";
		AttackSound "shotguy/attack";
		PainSound "shotguy/pain";
		DeathSound "shotguy/death";
		ActiveSound "shotguy/active";
		Obituary "$OB_SHOTGUY";
		DropItem "Shotgun";
		BloodColor "darkred";
		Tag "Shotgun Guy";
	}

	States
	{
	Spawn:
		SPOS AB 10 A_Look;
		Loop;
	See:
		SPOS AABBCCDD 3 A_Chase;
		Loop;
	Missile:
		SPOS E 10 A_FaceTarget;
		TNT1 A 0 A_StartSound("ENEMYGUN", 1);
		TNT1 A 0 A_StartSound("enemysg", 4);
		TNT1 AAA 0 A_CustomMissile("RS_MG_EnemyBullet", 38, 0, random(-6,6), 1, random(-1,1));
		SPOS F 10 Bright;
		SPOS E 10;
		TNT1 A 0 A_StartSound("STGPUMP", 4);
		SPSR ABA 4;
		Goto See;
	Pain:
		SPOS G 3;
		SPOS G 3 A_Pain;
		Goto See;
	Death:
		SPOS H 0;
		TNT1 A 0 A_CustomMissile("RS_MG_CeilingBloodChecker", 50, 0, random(0,360), 2, random(60,90));
		SPOS H 0 A_Jump(192, "Death1", "Death2", "Death3", "Death4", "Death5");
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 40, 0, random(0,360), 2, random(0,90));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		SPOS H 5;
		SPOS I 5 A_Scream;
		SPOS J 5 A_NoBlocking;
		SPOS K 5;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		SPOS L -1;
		Stop;
	Death1: // Leg
		TNT1 AAAA 0 A_CustomMissile("RS_MG_BloodFast", 20, 0, random(0,360), 2, random(0,90));
		TNT1 A 0 A_CustomMissile("RS_MG_ShotgunnerLeg", 10, 0, random(0,360), 2, random(40,50));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		SPO3 A 6 A_Scream;
		SPO3 B 6 A_NoBlocking;
		SPO3 CGH 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		SPO3 F -1;
		Stop;
	Death2: // Arm
		TNT1 AAA 0 A_CustomMissile("RS_MG_BloodFast", 20, 0, random(0,360), 2, random(0,90));
		TNT1 A 0 A_CustomMissile("RS_MG_Arm", 50, 0, random(0,360), 2, random(40,60));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		SPO5 A 6 A_Scream;
		SPO5 B 6 A_NoBlocking;
		SPO5 CD 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		SPO5 E -1;
		Stop;
	Death3: // Head
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 50, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meatb", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2b", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		TNT1 AAA 0 A_CustomMissile("RS_MG_GibHeadPiece", 55, 0, random(0,360), 2, random(45,50));
		TNT1 A 0 A_CustomMissile("RS_MG_GibTeeth", 55, 0, random(0,360), 2, random(45,50));
		TNT1 A 0 A_CustomMissile("RS_MG_GibEyeball", 55, 0, random(0,360), 2, random(45,50));
		SPDH B 6 A_Scream;
		SPDH C 6 A_NoBlocking;
		SPDH DE 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		SPDH E -1;
		Stop;
	Death4: // Guts
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 30, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meatb", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2b", 30, 0, random(0,360), 2, random(10,45));
		ZXZ7 A 6 A_Scream;
		ZXZ7 B 6 A_NoBlocking;
		ZXZ7 BCD 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		ZXZ7 E -1;
		Stop;
	Death5: // Heavy
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 30, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meatb", 30, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2b", 30, 0, random(0,360), 2, random(10,45));
		ZXZ6 A 6 A_Scream;
		ZXZ6 B 6 A_NoBlocking;
		ZXZ6 BCD 6;
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 20, 0, random(0,360), 2, random(10,45));
		ZXZ6 E -1;
		Stop;
	XDeath:
		// POSS frames verbatim from source -- see header.
		POSS M 4;
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodFast", 60, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_BloodBig", 50, 0, random(0,360), 2, random(30,90));
		TNT1 AAAA 0 A_CustomMissile("RS_MG_BloodBig", 30, 0, random(0,360), 2, random(10,45));
		TNT1 A 0 A_CustomMissile("RS_MG_Chunk", 40, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Chunkb", 40, 0, random(0,360), 2, random(45,50));
		TNT1 AA 0 A_CustomMissile("RS_MG_Arm", 50, 0, random(0,360), 2, random(40,60));
		TNT1 AAA 0 A_CustomMissile("RS_MG_Meat", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AAA 0 A_CustomMissile("RS_MG_Meat2", 50, 0, random(0,360), 2, random(10,45));
		POSS N 5 A_XScream;
		POSS O 5 A_NoBlocking;
		POSS PQRST 5;
		POSS U -1;
		Stop;
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
	Raise:
		SPOS L 5;
		SPOS KJIH 5;
		Goto See;
	Crush:
		TNT1 AAAAAAAAAA 0 A_CustomMissile("RS_MG_BloodCrushed", 0, 0, random(0,360), 2, random(0,90));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat", 50, 0, random(0,360), 2, random(10,45));
		TNT1 AA 0 A_CustomMissile("RS_MG_Meat2", 50, 0, random(0,360), 2, random(10,45));
		CRSH A 1;
		CRSH A -1;
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
	}
}
