// =====================================================================
// RS_ShowcaseStand -- a pedestal that displays a spinning weapon.
//
// Spawns the weapon actor itself as an untouchable display piece, so
// whatever the MODELDEF binds to that class is what turns; where no
// model is bound, the pickup sprite turns instead (which reads as
// nothing on a sprite -- models are the point).
//
// This is the world prop for the in-world UI scenes (drop cards, the
// armory, the bench). Test toggle: `netevent rs-showcase`, handled in
// RS_Screens.zs.
// =====================================================================
class RS_ShowcaseStand : Actor
{
	Actor mDisplay;
	double mSpinStep;

	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		Radius 8;
		Height 8;
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	static RS_ShowcaseStand Create(Vector3 spawnPos, class<Actor> what, double spinStep = 3)
	{
		let stand = RS_ShowcaseStand(Spawn("RS_ShowcaseStand", spawnPos));
		if (stand)
		{
			stand.mSpinStep = spinStep;
			stand.SetDisplay(what);
		}
		return stand;
	}

	void SetDisplay(class<Actor> what)
	{
		if (mDisplay) mDisplay.Destroy();
		mDisplay = null;
		if (!what) return;

		mDisplay = Spawn(what, pos);
		if (mDisplay)
		{
			// A display piece, not a pickup: untouchable, unmoving.
			mDisplay.bSpecial = false;
			mDisplay.bNoGravity = true;
			mDisplay.bNoInteraction = true;
			mDisplay.A_ChangeLinkFlags(1);   // bNoBlockmap is not directly assignable
		}
	}

	override void Tick()
	{
		Super.Tick();
		if (mDisplay)
		{
			mDisplay.SetOrigin(pos, true);
			mDisplay.angle += mSpinStep;
		}
	}

	override void OnDestroy()
	{
		if (mDisplay) mDisplay.Destroy();
		Super.OnDestroy();
	}
}
