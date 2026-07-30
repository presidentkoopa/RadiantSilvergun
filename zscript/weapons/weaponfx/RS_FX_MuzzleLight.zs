// =====================================================================
// RS_FXMuzzleLight -- dynamic muzzle light, Hi-Fi tier only
// (RS_HiFiFX.SpawnMuzzleLight gates this before ever spawning one).
// Split out of the original monolithic RS_EnhancedFX.zs -- see
// RS_FXBase.zs. Standalone (PointLight base), no dependency on the
// rest of the RS_FX* tree.
//
// Color/radius are a first-pass guess, meant to be tuned once actually
// seen in a headset rather than assumed correct on paper.
// =====================================================================

class RS_MuzzleLight : PointLight
{
	Default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+DONTSPLASH
		+THRUACTORS
		+NOTELEPORT
		Args 255, 200, 120, 96; // R, G, B, radius -- warm muzzle-flash color, randomized per-spawn below
	}

	// Every real muzzle flash looks slightly different shot to shot --
	// randomize brightness (color scaled together, hue kept warm) and
	// radius a little so Hi-Fi tier doesn't look identically robotic
	// every single trigger pull.
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		double brightness = FRandom(0.8, 1.15);
		args[0] = Clamp(int(255 * brightness), 0, 255);
		args[1] = Clamp(int(200 * brightness), 0, 255);
		args[2] = Clamp(int(120 * brightness), 0, 255);
		args[3] = int(FRandom(72, 116));
	}
	States
	{
	Spawn:
		TNT1 A 3 Bright;
		Stop;
	}
}
