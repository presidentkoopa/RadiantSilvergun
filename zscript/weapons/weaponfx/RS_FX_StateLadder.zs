// =====================================================================
// RS_FX_StateLadder -- the gun's LOOK reflects its stat state (owner
// directive, rs_11): a weapon whose damage has climbed toward its
// promotion ceiling fires visibly hotter rounds; a worn gun's rounds
// dim and sputter. This is the stat sheet made visible in the world --
// no UI, no weapon-sprite effects (VR law), just the projectile
// itself telling the truth.
//
// LADDER RULE: these bodies replace ONLY the arsenal default
// (RS_BallisticType1). A beat-authored class, a weapon's own swapped
// ProjectileClass, and every affix part outrank the ladder -- state
// never overrides identity. Selection lives in
// RS_Weapon.RS_StateLadderBody(); condition outranks damage (a
// failing gun sputters no matter how hot its loads are).
//
// All sprites verified in-repo: RSB0 (bullets), RSK0 (smoke),
// RS_HitSpark / RS_LensFlare (sparks/flares files).
// =====================================================================

// HIGH damage state (>= 65% of ceiling): the round runs hot -- brighter,
// shedding sparks.
class RS_BallisticHot : RS_BallisticFired
{
	int shedTimer;

	Default
	{
		RenderStyle "Add";
		Alpha 1.0;
		+BRIGHT
	}

	override void Tick()
	{
		Super.Tick();
		if (++shedTimer >= 3)
		{
			shedTimer = 0;
			Spawn("RS_HitSpark", pos);
		}
	}

	States
	{
	Spawn:
		RSB0 ABCDE 2 Bright;
		Loop;
	}
}

// PEAK damage state (>= 90% of ceiling): radiant -- the gun is at the
// top of its ladder and everyone can see it.
class RS_BallisticPeak : RS_BallisticFired
{
	int shedTimer;

	Default
	{
		RenderStyle "Add";
		Alpha 1.0;
		Scale 1.15;
		+BRIGHT
	}

	override void Tick()
	{
		Super.Tick();
		if (++shedTimer >= 2)
		{
			shedTimer = 0;
			Spawn("RS_HitSpark", pos);
		}
	}

	States
	{
	Spawn:
		RSB0 ABCDE 2 Bright;
		Loop;
	}
}

// WORN condition state (< 50): the round dims and trails thin smoke.
class RS_BallisticWorn : RS_BallisticFired
{
	int shedTimer;

	Default
	{
		Alpha 0.65;
	}

	override void Tick()
	{
		Super.Tick();
		if (++shedTimer >= 5)
		{
			shedTimer = 0;
			let s = RS_SmokeWisp(Spawn("RS_SmokeWisp", pos));
			if (s) s.SetupVisual(0.2, 0.1, 0.2);
		}
	}

	States
	{
	Spawn:
		RSB0 ABCDE 3;
		Loop;
	}
}

// FAILING condition state (< 20): dark, sputtering, visibly dying --
// matching the backfire band it lives in.
class RS_BallisticFailing : RS_BallisticFired
{
	int shedTimer;

	Default
	{
		Alpha 0.45;
	}

	override void Tick()
	{
		Super.Tick();
		if (++shedTimer >= 2)
		{
			shedTimer = 0;
			let s = RS_SmokeWisp(Spawn("RS_SmokeWisp", pos));
			if (s) s.SetupVisual(0.3, 0.14, 0.25);
		}
	}

	States
	{
	Spawn:
		RSB0 ABCDE 4;
		Loop;
	}
}
