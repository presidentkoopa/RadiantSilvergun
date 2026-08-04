// =====================================================================
// RS_Spectre -- on RS_DemonBase (RS_MonsterMaster.zs). Replaces Spectre.
// Rebuilt to the per-tier state architecture (docs/rs_09 spec,
// RS_Imp.zs is the template). CH's low spectres are the demon body
// plus a fuzz render style -- SARG, not a dedicated sprite set; the
// high tiers get real bodies of their own.
//
// THIRTEEN REAL CREATURES (all wearing the family fuzz):
//   T00 SARG shadow pinky         T01 SARG+tint faster shadow
//   T02 SARG+tint tough shadow    T03 WORM ice-spike shadow worm
//   T04 SARG+tint heavy shadow    T05 SRG2 fast heavy biter
//   T06 HDOG Hell Hound shadow: seeking fire + bite
//   T07 SARG+tint fireblu shadow  T08 BPWA brown prowler: bite + bolt
//   T09 TRIT bouncing ice-orb shadow
//   T10 SRG2 blood-bolt shadow    T11 SHDW the Shadow: balls + blink
//   T12 SLGM Slime Golem: heavy bruiser, triple volley
//
// RS mechanics preserved from the previous file: the Rogue stalk
// counter + backstab warp (RS_Stalk / RS_Backstab) now lives in the
// See DISPATCHER, and every tier's See cluster ends with `Goto See`
// (not Loop) so the counter still ticks once per walk cycle.
//
// SUBSTITUTIONS (verified on disk):
//   * T08 BPWA has ONLY frames A-D (CH's BrownSpectre2 used BPBI for
//     attacks and BPDE for its death -- neither imported). Attacks
//     reuse A-D; the death is a shadow fade-out.
//   * T09 death: CH's TRIT J + MISL B-D explosion -- MISL is the IWAD
//     rocket-blast sprite, no files needed.
//   * T11 death: CH used SHDX (not imported); SHDW I-V on disk ARE a
//     collapse sequence (verified by eye) and are used instead.
//   * T12 SLGM has no F frame on disk; CH's own walk/attack frames
//     (A-E,G,H,V-Y walk; I-N,O attack) are used, F skipped.
// =====================================================================

class RS_Spectre : RS_DemonBase replaces Spectre
{
	Default
	{
		Health 150;
		Radius 30;
		Height 56;
		Mass 400;
		Speed 10;
		PainChance 180;
		Monster;
		+FLOORCLIP
		+SHADOW
		RenderStyle "OptFuzzy";
		Alpha 0.5;
		SeeSound "spectre/sight";   PainSound "spectre/pain";
		DeathSound "spectre/death"; ActiveSound "spectre/active";
		AttackSound "spectre/melee";
		Obituary "$OB_SPECTRE";
		Tag "Spectre";
	}

	// Audit data: which body each tier wears.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SARG SARG SARG WORM SARG SRG2 HDOG SARG BPWA TRIT SRG2 SHDW SLGM";
	}

	override string TintTable()
	{
		// Shares the demon recipes except T12. T09 uses the engine's
		// own built-in "ice" translation, which is a real named
		// translation GZDoom ships -- not one of ours, not a range table.
		return "- rs_demon_t01 rs_demon_t02 rs_demon_t03 rs_demon_t04 rs_demon_t05 "
		       "rs_demon_t06 rs_demon_t07 - ice rs_demon_t10 - rs_spectre_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:spectre role:bruiser delivery:melee element:kinetic mobility:ground trait:stealth";
	}

	// -----------------------------------------------------------------
	// THE ROGUE. Builds a counter while stalking, then warps behind you
	// and opens with a free hit. The counter is what makes it feel like
	// it is waiting for an opening rather than rolling dice every tic.
	// -----------------------------------------------------------------
	const RS_SPEC_TIER_BACKSTAB = 6;
	const RS_SPEC_STAB_AT       = 10;

	void RS_Stalk()
	{
		if (Tier < RS_SPEC_TIER_BACKSTAB)
			return;
		AddCharge(1);
	}

	// Warp to just behind the target. Returns false if there was nowhere
	// to land, so the caller can fall through to a normal approach.
	bool RS_Backstab()
	{
		if (!target || ChargeCounter < RS_SPEC_STAB_AT)
			return false;

		ResetCharge();

		// Behind the target, relative to the way IT is facing.
		double ang = target.angle + 180;
		Vector3 p = (target.pos.xy + (cos(ang), sin(ang)) * 56.0, target.pos.z);

		if (!TeleportMove(p, false))
			return false;

		angle = target.angle;      // facing its back
		A_StartSound("spectre/sight", CHAN_VOICE);
		return true;
	}

	States
	{
	// ===== dispatcher override: the Rogue stalks between walk cycles.
	// Tier See clusters end with `Goto See`, so this runs once per
	// cycle -- same cadence the old single-cluster file had. =====
	See:
		TNT1 A 0
		{
			RS_Stalk();
			if (ChargeCounter >= RS_SPEC_STAB_AT && RS_Backstab())
				return ResolveState("Melee");
			return TierState("See");
		}
		TNT1 A 4 { A_Chase(); }
		Goto See;

	// =========================================================
	// T00 -- shadow pinky. T01/T02/T04/T07 share the SARG body.
	// =========================================================
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
	Spawn.T07:
		"SARG" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
	See.T07:
		"SARG" AABBCCDD 2 { A_Chase(); }
		Goto See;
	Melee.T00:
	Melee.T01:
	Melee.T02:
	Melee.T04:
	Melee.T07:
		"SARG" EF 4 { A_FaceTarget(); }
		"SARG" G 4 { A_SargAttack(); }
		Goto See;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
	Pain.T07:
		"SARG" H 2;
		"SARG" H 2 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
	Death.T07:
		"SARG" I 8;
		"SARG" J 8 { A_Scream(); }
		"SARG" K 4;
		"SARG" L 4 { A_NoBlocking(); }
		"SARG" M 4;
		"SARG" N -1;
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
	Raise.T04:
	Raise.T07:
		"SARG" NMLKJI 5;
		Goto See;

	// ===== T03 CYAN -- ice-spike shadow worm (WORM) =====
	Spawn.T03:
		"WORM" AB 10 { A_Look(); }
		Loop;
	See.T03:
		"WORM" AABBCCDD 2 { A_Chase(); }
		Goto See;
	Melee.T03:
		"WORM" EF 4 { A_FaceTarget(); }
		"WORM" H 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 24, random(9, 33), 0, random(3, 9), frandom(-9, 9)); }
		"WORM" H 0 { A_SpawnItemEx("RS_SpikeCyanRev", 16, 0, 29, random(9, 33), 0, random(4, 12), frandom(-4, 4)); }
		"WORM" G 4 { A_CustomMeleeAttack(random(20, 60), "slimeworm/melee", ""); }
		Goto See;
	Pain.T03:
		"WORM" H 2;
		"WORM" H 2 { A_Pain(); }
		Goto See;
	Death.T03:
		"WORM" I 8;
		"WORM" J 8 { A_Scream(); }
		"WORM" K 4;
		"WORM" L 4 { A_NoBlocking(); }
		"WORM" M 4;
		"WORM" N 1 { A_IceGuyDie(); }
		Stop;

	// ===== T05 YELLOW -- fast heavy biter (SRG2). T10 RED shares
	// the body: walk/pain/death stack here. =====
	Spawn.T05:
	Spawn.T10:
		"SRG2" AB 10 { A_Look(); }
		Loop;
	See.T05:
	See.T10:
		"SRG2" AABBCCDD 2 { A_Chase(); }
		Goto See;
	Melee.T05:
		"SRG2" EF 4 { A_FaceTarget(); }
		"SRG2" G 4 { A_CustomMeleeAttack(random(15, 50), "demon/melee", ""); }
		Goto See;
	Pain.T05:
	Pain.T10:
		"SRG2" H 2;
		"SRG2" H 2 { A_Pain(); }
		Goto See;
	Death.T05:
	Death.T10:
		"SRG2" I 8;
		"SRG2" J 8 { A_Scream(); }
		"SRG2" K 4;
		"SRG2" L 4 { A_NoBlocking(); }
		"SRG2" M 4;
		"SRG2" N -1;
		Stop;
	Raise.T05:
	Raise.T10:
		"SRG2" NMLKJI 5;
		Goto See;

	// ===== T06 ABYSS -- Hell Hound shadow (HDOG) =====
	Spawn.T06:
		"HDOG" AB 10 { A_Look(); }
		Loop;
	See.T06:
		"HDOG" AABBCCDD 2 { A_Chase(); }
		Goto See;
	Melee.T06:
		"HDOG" EF 4 { A_FaceTarget(); }
		"HDOG" G 4 { A_CustomMeleeAttack(random(15, 55), "hellhound/melee", ""); }
		Goto See;
	Missile.T06:
		"HDOG" EF 6 { A_FaceTarget(); }
		"HDOG" G 5 Bright { A_SpawnProjectile("RS_AbyssDogFire", 24, 0, random(-4, 4)); }
		"HDOG" G 5 Bright { A_SpawnProjectile("RS_AbyssDogFire", 24, 0, random(-4, 4)); }
		Goto See;
	Pain.T06:
		"HDOG" H 2;
		"HDOG" H 2 { A_Pain(); }
		Goto See;
	Death.T06:
		"HDOG" K 8;
		"HDOG" L 8 { A_Scream(); }
		"HDOG" M 4;
		"HDOG" N 4 { A_NoBlocking(); }
		"HDOG" OP 4;
		"HDOG" Q -1;
		Stop;
	Raise.T06:
		"HDOG" QPONMLK 5;
		Goto See;

	// ===== T08 BROWN -- prowler (BPWA, frames A-D ONLY on disk;
	// CH's BPBI attack frames and BPDE death were never imported).
	// Bite + blood bolt on the four frames that exist; shadow-fade
	// death. =====
	Spawn.T08:
		"BPWA" ABCD 4 { A_Look(); }
		Loop;
	See.T08:
		"BPWA" AABBCCDD 2 { A_Chase(); }
		Goto See;
	Melee.T08:
		"BPWA" AB 6 { A_FaceTarget(); }
		"BPWA" C 6 { A_CustomMeleeAttack(random(12, 45), "demon/melee", ""); }
		Goto See;
	Missile.T08:
		"BPWA" AB 6 { A_FaceTarget(); }
		"BPWA" D 5 Bright { A_SpawnProjectile("RS_RedDemonBloodBolt3", 24, 0, random(-6, 6)); }
		Goto See;
	Pain.T08:
		"BPWA" A 2;
		"BPWA" A 2 { A_Pain(); }
		Goto See;
	Death.T08:
		// No death frames exist for this body -- the shadow drains away.
		"BPWA" A 6 { A_Scream(); }
		"BPWA" B 6 { A_NoBlocking(); }
		"BPWA" CDAB 5 { A_FadeOut(0.09); }
		"BPWA" CD 5 { A_FadeOut(0.09); }
		TNT1 A 1;
		Stop;

	// ===== T09 GRAY -- bouncing ice-orb shadow (TRIT) =====
	Spawn.T09:
		"TRIT" AB 10 { A_Look(); }
		Loop;
	See.T09:
		"TRIT" AABBCCDD 2 { A_Chase(); }
		Goto See;
	Melee.T09:
		"TRIT" EF 4 { A_FaceTarget(); }
		"TRIT" G 4 { A_CustomMeleeAttack(random(20, 55), "demon/melee", ""); }
		Goto See;
	Missile.T09:
		"TRIT" EF 6 { A_FaceTarget(); }
		"TRIT" G 5 Bright { A_SpawnProjectile("RS_IceOrbCH2", 24, 0, random(-5, 5)); }
		"TRIT" G 5 Bright { A_SpawnProjectile("RS_IceOrbCH2", 24, 0, random(-5, 5)); }
		Goto See;
	Pain.T09:
		"TRIT" H 2;
		"TRIT" H 2 { A_Pain(); }
		Goto See;
	Death.T09:
		// CH: the gray shadow detonates. MISL B-D is the IWAD rocket
		// blast -- the sprite CH itself used here.
		"TRIT" J 20 { A_ScreamAndUnblock(); }
		"MISL" BCD 10 Bright;
		Stop;

	// ===== T11 BLACK -- the Shadow (SHDW): balls + teleport-blink =====
	Spawn.T11:
		"SHDW" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"SHDW" AABBCCDD 2 { A_Chase(); }
		Goto See;
	Melee.T11:
		"SHDW" EF 4 { A_FaceTarget(); }
		"SHDW" G 4 { A_CustomMeleeAttack(random(30, 90), "demon/melee", ""); }
		Goto See;
	Missile.T11:
		"SHDW" A 0 A_JumpIfCloser(110, "Melee.T11");
		"SHDW" A 0 A_Jump(64, "Missile.T11.Blink");
		"SHDW" EF 6 Bright { A_FaceTarget(); }
		"SHDW" G 4 Bright { A_SpawnProjectile("RS_ShadowBall", 24, 0, random(-5, 5)); }
		"SHDW" G 4 Bright { A_SpawnProjectile("RS_ShadowBall2", 24, 0, random(-5, 5)); }
		"SHDW" G 4 A_MonsterRefire(40, "See");
		Goto See;
	Missile.T11.Blink:
		"SHDW" H 4 { A_FadeTo(0.05); }
		"SHDW" H 0 { A_StartSound("misc/teleport", CHAN_BODY); }
		"SHDW" H 0 { A_Warp(AAPTR_TARGET, random(96, 160), random(-64, 64), 0, random(-30, 30), WARPF_NOCHECKPOSITION); }
		"SHDW" H 4 { A_FadeTo(0.5, 0.15); }
		"SHDW" G 4 Bright { A_SpawnProjectile("RS_ShadowBall", 24, 0, 0); }
		Goto See;
	Pain.T11:
		"SHDW" H 2;
		"SHDW" H 2 { A_Pain(); }
		Goto See;
	Death.T11:
		// CH used the unimported SHDX set; SHDW I-V on disk is the
		// same collapse (standing figure -> heap, verified by eye).
		"SHDW" IJ 6;
		"SHDW" K 6 { A_Scream(); }
		"SHDW" LMNO 5;
		"SHDW" P 5 { A_NoBlocking(); }
		"SHDW" QRSTU 4;
		"SHDW" V -1;
		Stop;

	// ===== T12 WHITE -- Slime Golem (SLGM). No F frame on disk;
	// CH's own frame plan is used (walk A-E,G,H,V-Y; attack I-N,O). =====
	Spawn.T12:
		"SLGM" A 10 { A_Look(); }
		"SLGM" B 10 { A_Look(); }
		Loop;
	See.T12:
		"SLGM" ABCDEGHH 3 { A_Chase(); }
		"SLGM" VWXY 3 { A_Chase(); }
		Goto See;
	Melee.T12:
		"SLGM" IJKLMN 1 { A_FaceTarget(); }
		"SLGM" OOO 4 { A_CustomMeleeAttack(random(50, 140), "demon/melee", ""); }
		"SLGM" NMLKJI 1;
		Goto See;
	Missile.T12:
		"SLGM" A 0 A_JumpIfCloser(140, "Melee.T12");
		"SLGM" IJKLMN 1 { A_FaceTarget(); }
		"SLGM" O 4 Bright { A_SpawnProjectile("RS_ShadowBall2", 24, 0, random(-6, 6)); }
		"SLGM" O 4 Bright { A_SpawnProjectile("RS_IceOrbCH2", 24, 0, random(-6, 6)); }
		"SLGM" O 4 Bright { A_SpawnProjectile("RS_ShadowBall", 24, 0, random(-6, 6)); }
		"SLGM" N 8 A_MonsterRefire(40, "See");
		"SLGM" MLKJI 1;
		Goto See;
	Pain.T12:
		"SLGM" J 5;
		"SLGM" J 5 { A_Pain(); }
		Goto See;
	Death.T12:
		"SLGM" VWXY 5;
		"SLGM" P 5 { A_Scream(); }
		"SLGM" QRST 5;
		"SLGM" U 5 { A_NoBlocking(); }
		"SLGM" U -1;
		Stop;
	}
}
