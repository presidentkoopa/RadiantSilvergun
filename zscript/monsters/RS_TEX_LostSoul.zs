// ----------------------------------------------------------------------------
// WHITE LOST SOUL EX -- "Soul Eater" mega-mimic (HP ~9000). CH WhiteLSoulEX.
//   The apex Lost Soul: a soul that DEVOURS and mimics SIX monster forms -- it
//   transforms (ETHS ghost-flash) then BECOMES a Caco/Revenant/Hell Knight/Baron/
//   Arch-vile/Mancubus and unloads that monster's full signature, OR fires its own
//   soul-beam / soul-charge homing barrage. Phase-2 enrage <6000HP. Derives HF_LostSoul.
//   Reuses the ENTIRE pool (Caco fire, Baron waves, Revenant tracers, Vile bolts,
//   Fatso shots) + the new soul projectiles. Floats (+FLOAT +NOGRAVITY).
// ----------------------------------------------------------------------------
class HF_WhiteLostSoulEX : HF_LostSoul
{
	Default
	{
		Health 9000;
		GibHealth -900;
		Radius 24;
		Height 56;
		Mass 400;
		Speed 10;
		PainChance 40;
		Monster;
		+BOSS +FLOAT +NOGRAVITY +MISSILEMORE +MISSILEEVENMORE +DONTFALL +NOICEDEATH +NOBLOOD
		RenderStyle "Add";
		Alpha 1;
		Species "whitelsoul";
		SeeSound "skull/active";
		PainSound "skull/pain";
		DeathSound "skull/death";
		ActiveSound "skull/active";
		Obituary "$OB_WHITESOULEX";
		Tag "Soul Eater";
	}

	override string MonIdentity()
	{
		return "class:lostsoul species:lostsoul role:miniboss trait:ex trait:mimic trait:summon faction:hell set:hf";
	}
	override bool TierLocked() { return true; }   // fixed raid boss: ignore the colour dial (its OWN states summon dial-tiered adds)

	// ---- HYBRID SUMMONER: real tiered HF monsters fight alongside the mimicry ----
	// Pack cap 3, tier SCALES WITH HEALTH (healthy -> weak colors, near-death -> white/black).
	const SOULEX_PACKCAP = 3;

	// count living minions that point to this Soul Eater as their master
	int LivingPack()
	{
		int n = 0;
		ThinkerIterator it = ThinkerIterator.Create("HF_Monster");
		HF_Monster m;
		while (m = HF_Monster(it.Next()))
			if (m.master == self && m.health > 0)
				n++;
		return n;
	}

	// map current health fraction -> a tier. Full HP = early colors; the more hurt it
	// is, the nastier the summons get (white/black appear as it nears death).
	int SummonTierByHealth()
	{
		double frac = double(health) / double(SpawnHealth());
		if (frac > 0.85) return random(1, 3);    // green / blue / cyan
		if (frac > 0.65) return random(3, 5);    // cyan / purple / yellow
		if (frac > 0.45) return random(5, 8);    // yellow / abyss / fireblu / brown
		if (frac > 0.25) return random(8, 10);   // brown / gray / red
		return random(10, 12);                   // red / black / white (desperate)
	}

	// summon one real tiered HF monster near the player, mastered to this boss.
	void SoulEaterSummon()
	{
		if (LivingPack() >= SOULEX_PACKCAP) return;
		if (!target) return;

		// the roster the Soul Eater can pull from (the monsters it mimics, made real)
		string pick;
		switch (random(0, 5))
		{
		case 0:  pick = "HF_Caco";      break;
		case 1:  pick = "HF_Revenant";  break;
		case 2:  pick = "HF_HellKnight";break;
		case 3:  pick = "HF_Baron";     break;
		case 4:  pick = "HF_Archvile";  break;
		default: pick = "HF_Mancubus";  break;
		}

		// spawn a short distance toward the target (a rift opening)
		double ang = angle + frandom(-45, 45);
		vector3 spot = Vec3Angle(frandom(96, 160), ang, frandom(0, 48));
		Actor a = Actor.Spawn(pick, spot, ALLOW_REPLACE);
		if (!a) return;
		a.A_StartSound("misc/teleport");

		let mon = HF_Monster(a);
		if (mon)
		{
			mon.master = self;                       // tie to the pack
			mon.SetTier(SummonTierByHealth(), true); // health-scaled color, instant
			mon.target = target;                     // sic it on the player
			mon.bAmbush = false;
		}
		// a flashy rift puff at the spawn point
		Actor.Spawn("HF_WSSmore", spot, ALLOW_REPLACE);
	}

	States
	{
	Spawn:
		ETHS AB 10 Bright A_Look;
		Loop;
	See:
		ETHS AB 6 Bright A_Chase;
		Loop;
	Missile:
		ETHS C 0 A_ChangeFlag("NOPAIN",true);
		ETHS C 2 Bright A_PlaySound("skull/active");
		ETHS E 2 Bright;
		ETHS FFFF 1 Bright A_CustomMissile("HF_WSSmore",16,0,CMF_AIMOFFSET,random(0,360),random(0,360));
		ETHS F 1 Bright A_JumpIfHealthLower(6000,"Missile.Phase2");
		ETHS F 0 A_Jump(256,"Missile.Caco","Missile.Rev","Missile.HK","Missile.Baron","Missile.Vile","Missile.Mancu","Missile.Beam","Missile.SoulShot","Missile.Summon");
		Goto See;

	// ---- CACO form ----
	Missile.Caco:
		HEAD F 6 Bright A_FaceTarget;
		HEAD G 4 Bright A_CustomMissile("HF_LSCacodemonBall",0,0,random(-5,5));
		HEAD G 4 Bright A_CustomMissile("HF_CacoFire2",0,0,random(-5,5));
		HEAD G 4 Bright A_CustomMissile("HF_SpitFireCaco",0,0,random(-5,5));
		HEAD G 4 Bright A_CustomMissile("HF_SBombCaco",0,0,0);
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- REVENANT form ----
	Missile.Rev:
		SKEL J 6 Bright A_FaceTarget;
		SKEL K 0 A_CustomMissile("HF_RevenantTracerHoming",50,7,5);
		SKEL K 0 A_CustomMissile("HF_RevenantTracerHoming",50,-7,-5);
		SKEL J 4 A_FaceTarget;
		SKEL K 5 A_CustomMissile("HF_AcidBlast1",50,7,12);
		SKEL K 5 A_CustomMissile("HF_Zap7",50,-7,-1);
		SKEL J 4 A_FaceTarget;
		SKEL K 5 A_CustomMissile("HF_Homer1",50,0,random(-6,6));
		SKEL K 5 A_CustomMissile("HF_Purp1",50,0,9);
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- HELL KNIGHT form ----
	Missile.HK:
		BOS2 F 6 Bright A_FaceTarget;
		BOS2 G 4 Bright A_CustomMissile("HF_HKBolt2",0,0,random(-5,5));
		BOS2 G 4 Bright A_CustomMissile("HF_BaronsBlueBalls",0,0,random(-5,5));
		BOS2 G 4 Bright A_CustomMissile("HF_BigHK",0,0,0);
		BOS2 G 4 Bright A_CustomMissile("HF_THEBEEHK",0,0,random(-8,8));
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- BARON form ----
	Missile.Baron:
		BOSS F 6 Bright A_FaceTarget;
		BOSS G 5 Bright A_CustomMissile("HF_BaronWave",32,0,0);
		BOSS G 5 Bright A_CustomMissile("HF_Spspit2",32,5,random(-8,8));
		BOSS G 4 Bright A_CustomMissile("HF_SmashBalls2",32,5,random(-8,8));
		BOSS G 4 Bright A_CustomMissile("HF_BaronStar",32,5,random(-8,8));
		BOSS G 4 Bright A_CustomMissile("HF_Spear11",32,5,0);
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- ARCH-VILE form ----
	Missile.Vile:
		VILE G 5 Bright A_FaceTarget;
		VILE IJKLM 5 Bright A_FaceTarget;
		VILE N 1 Bright A_CustomMissile("HF_BigBolt2",32,0,0);
		VILE G 5 Bright A_CustomMissile("HF_ReAComet",32,0,random(-6,6));
		VILE H 4 Bright A_CustomMissile("HF_ArcRing2",32,0,random(-12,12));
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- MANCUBUS form ----
	Missile.Mancu:
		FATT F 6 Bright A_FaceTarget;
		FATT G 5 Bright A_CustomMissile("HF_FatsoShotYE",32,0,random(-6,6));
		FATT G 5 Bright A_CustomMissile("HF_RocketShotFatso",32,0,0);
		FATT G 5 Bright A_CustomMissile("HF_Shot2Fatso",32,0,random(-8,8));
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- own SOUL-BEAM ----
	Missile.Beam:
		ETHS F 6 Bright A_FaceTarget;
		ETHS F 2 Bright A_CustomMissile("HF_SoulexBeam",16,0,0);
		ETHS F 2 Bright A_CustomMissile("HF_SoulexBeam2",16,0,random(-3,3));
		ETHS F 2 Bright A_CustomMissile("HF_SoulexBeam3",16,0,random(-3,3));
		ETHS F 8 A_MonsterRefire(40,"See");
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- own SOUL-CHARGE homing barrage ----
	Missile.SoulShot:
		ETHS F 6 Bright A_FaceTarget;
		ETHS F 3 Bright A_CustomMissile("HF_SOULEXSoulCharge",16,0,random(-10,10));
		ETHS F 3 Bright A_CustomMissile("HF_SOULEXSoulCharge",16,0,random(-10,10));
		ETHS F 3 Bright A_CustomMissile("HF_SOULEXSoulCharge",16,0,random(-10,10));
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- HYBRID: tear a rift and summon a real tiered monster (pack of up to 3) ----
	Missile.Summon:
		ETHS F 4 Bright A_FaceTarget;
		ETHS E 3 Bright A_PlaySound("WSOUL/form");
		ETHS FFFF 1 Bright A_CustomMissile("HF_WSSmore",16,0,CMF_AIMOFFSET,random(0,360),random(0,360));
		ETHS P 2 Bright { SoulEaterSummon(); }
		ETHS Q 4 Bright;
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	// ---- PHASE 2: rapid-fire soul beams + charges ----
	Missile.Phase2:
		ETHS A 0 A_ChangeFlag("MISSILEEVENMORE",true);
		ETHS F 4 Bright A_FaceTarget;
		ETHS F 2 Bright A_CustomMissile("HF_SoulexBeam",16,0,random(-4,4));
		ETHS F 2 Bright A_CustomMissile("HF_SoulexBeam3",16,0,random(-4,4));
		ETHS F 2 Bright A_CustomMissile("HF_SOULEXSoulCharge",16,0,random(-12,12));
		ETHS P 2 Bright { SoulEaterSummon(); }
		ETHS FFFF 1 Bright A_CustomMissile("HF_WSSmore",16,0,CMF_AIMOFFSET,random(0,360),random(0,360));
		ETHS F 6 A_MonsterRefire(48,"See");
		ETHS A 0 A_ChangeFlag("NOPAIN",false);
		Goto See;
	Pain:
		ETHS C 2 Bright; ETHS C 2 Bright A_Pain;
		Goto See;
	Death:
		SKUL F 6 Bright;
		SKUL G 6 Bright A_Scream;
		SKUL H 6 Bright;
		SKUL I 6 Bright A_NoBlocking;
		SKUL JK 6 Bright;
		Stop;
	}
}
