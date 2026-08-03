// =====================================================================
// RS_PainElemental -- the escort summoner. Replaces PainElemental.
// ---------------------------------------------------------------------
// Already a summoner in vanilla, so the interesting question was what
// CHP does BEYOND "spawns lost souls." The answer, and what's kept:
//
//   * a MAINTAINED escort -- two sentinels kept alive by a proximity
//     check that respawns either one if it dies. This is the mechanic
//     worth having: you can't out-wait the summon, you have to kill the
//     summoner. It turns a burst into a sustained pressure.
//   * a two-stage reveal -- the thing you were fighting was the shell.
//     Killing it releases a smaller, faster pilot with its own kit.
//
// TIER GATING:
//   T00-T05  vanilla-ish. Vanilla lost-soul attack only.
//   T06+     maintains a two-sentinel escort.
//   T09+     escort grows to three, and it gains a ring burst.
//   T11+     death is a phase change -- the Pilot comes out.
// =====================================================================

class RS_PainElemental : RS_MonsterMaster replaces PainElemental
{
	const RS_PE_TIER_ESCORT = 6;
	const RS_PE_TIER_HEAVY  = 9;
	const RS_PE_TIER_PILOT  = 11;

	const RS_PE_CHECK_INTERVAL = 70;   // 2s between escort headcounts

	private int rsNextEscortCheck;

	Default
	{
		Health 400;
		Radius 31;
		Height 56;
		Mass 400;
		Speed 8;
		PainChance 128;
		Monster;
		+FLOAT +NOGRAVITY
		SeeSound "pain/sight";   PainSound "pain/pain";
		DeathSound "pain/death"; ActiveSound "pain/active";
		Tag "Pain Elemental";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "PAIN PAIN PAIN INFR TORT INFR AYPE PAIN FLSP INFR TORT OVER WATC";
	}

	override string TintTable()
	{
		return "- rs_pain_t01 rs_pain_t02 rs_pain_t03 rs_pain_t04 rs_pain_t05 "
		       "- rs_pain_t07 rs_pain_t08 rs_pain_t09 rs_pain_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:painelemental role:summoner delivery:heavy element:thermal mobility:floating";
	}

	// The escort explicitly does NOT die with the summoner -- CHP goes
	// both ways on this and here the sentinels outliving their parent is
	// the better fight: killing the elemental doesn't instantly clear
	// the room, you still have to mop up.
	override bool MinionsDieWithMe()
	{
		return false;
	}

	// Death is a phase change at high tier only. Below that it just dies.
	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_PE_TIER_PILOT) ? RS_MonsterCatalog.MORPH_PainPilot() : null;
	}

	int EscortSize()
	{
		if (Tier >= RS_PE_TIER_HEAVY)  return 3;
		if (Tier >= RS_PE_TIER_ESCORT) return 2;
		return 0;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_PE_TIER_HEAVY)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));

		// A rotation, so the fight has a rhythm instead of one repeated
		// attack: two pulses then a ring burst.
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainPulse(), 1, 0.0,
			"pain/attack", 1.0, 0.0, "Pulse"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainPulse(), 1, 0.0,
			"pain/attack", 1.0, 0.0, "Pulse"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainStorm(),
			t >= 12 ? 16 : 10, 360.0,       // full ring, denser at the top
			"pain/attack", 1.0, 6.0, "Storm Ring"));

		return slot;
	}

	// -----------------------------------------------------------------
	// THE MAINTAINED ESCORT.
	// A headcount on a throttle, not every tic. If we're short, top up
	// by one -- one at a time, so a wiped escort refills visibly rather
	// than popping back in a single frame.
	// -----------------------------------------------------------------
	private void RS_TickEscort()
	{
		int want = EscortSize();
		if (want <= 0 || health <= 0)
			return;

		if (level.time < rsNextEscortCheck)
			return;
		rsNextEscortCheck = level.time + RS_PE_CHECK_INTERVAL;

		Class<Actor> cls = RS_MonsterCatalog.MINION_Sentinel();
		if (CountLiveMinions(cls) >= want)
			return;

		if (SummonMinion(cls, -2, 88.0, 16.0))
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	override void Tick()
	{
		Super.Tick();
		RS_TickEscort();
	}

	States
	{
	Spawn:
		"PAIN" A 10  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"PAIN" AABBCC 3  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		"PAIN" D 5  { RS_WearBody(); A_FaceTarget(); }
		"PAIN" DE 5  { RS_WearBody(); A_FaceTarget(); }
		"PAIN" F 5  Bright
		{
			RS_WearBody();
			// High tier fires from the attack table; low tier keeps the
			// vanilla lost-soul spit, which is the whole "T00-T05 stays
			// recognisably Doom" posture.
			if (Tier >= RS_PE_TIER_HEAVY)
				A_RS_MonsterFire();
			else
				A_PainAttack();
		}
		Goto See;
	Pain:
		"PAIN" G 6 { RS_WearBody(); }
		"PAIN" G 6  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"PAIN" H 8  Bright { RS_WearBody(); }
		"PAIN" I 8  Bright { RS_WearBody(); A_Scream(); }
		"PAIN" JK 8  Bright { RS_WearBody(); }
		"PAIN" L 8  Bright { RS_WearBody(); A_PainDie(); }
		"PAIN" M 8  Bright { RS_WearBody(); }
		Stop;
	Raise:
		"PAIN" MLKJIH 8 { RS_WearBody(); }
		Goto See;
	}
}

// =====================================================================
// RS_PainPilot -- what was actually flying the thing.
// ---------------------------------------------------------------------
// Stage two. Smaller, much faster, no longer summons -- it trades the
// escort for raw aggression, so the fight changes character rather than
// just repeating with a second health bar.
//
// TierLocked: it inherits its tier from the shell it came out of and
// then holds it. The ambient dial retiering a monster that only exists
// mid-fight would be noise.
// =====================================================================

class RS_PainPilot : RS_MonsterMaster
{
	Default
	{
		Health 350;
		Radius 20;
		Height 40;
		Mass 200;
		Speed 16;
		PainChance 60;
		Monster;
		+FLOAT +NOGRAVITY +MISSILEMORE
		RenderStyle "Add";
		Alpha 0.95;
		SeeSound "pain/sight";   PainSound "pain/pain";
		DeathSound "pain/death"; ActiveSound "pain/active";
		Tag "Pain Elemental (Pilot)";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SKUL SKUL SKUL LFX1 SKUL FRGO BST7 SKUL BOSF SKUL FRGO WASP ETHS";
	}

	override string TintTable()
	{
		return "- rs_soul_t01 rs_soul_t02 rs_soul_t03 rs_soul_t04 rs_soul_t05 "
		       "- rs_soul_t07 - rs_soul_t09 rs_soul_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:painelemental role:skirmisher delivery:heavy element:thermal mobility:flying trait:secondstage";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		// Three fast shots then a spread -- a pressure pattern, since it
		// no longer has minions doing the pressuring for it.
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainPulse(), 1, 0.0, "pain/attack", 1.0, 0.0, "Bolt"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainPulse(), 1, 0.0, "pain/attack", 1.0, 0.0, "Bolt"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_PainStorm(), 5, 50.0, "pain/attack", 1.0, 4.0, "Fan"));
		return slot;
	}

	States
	{
	Spawn:
		"SKUL" AB 6  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"SKUL" AB 4  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		"SKUL" C 6  { RS_WearBody(); A_FaceTarget(); }
		"SKUL" D 6  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	Pain:
		"SKUL" E 3 { RS_WearBody(); }
		"SKUL" E 3  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"SKUL" F 6  Bright { RS_WearBody(); }
		"SKUL" G 6  Bright { RS_WearBody(); A_Scream(); }
		"SKUL" H 6  Bright { RS_WearBody(); A_NoBlocking(); }
		"SKUL" IJ 6  Bright { RS_WearBody(); }
		Stop;
	}
}
