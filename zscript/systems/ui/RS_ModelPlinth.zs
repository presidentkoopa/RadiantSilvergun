// =====================================================================
// RS_ModelPlinth -- the weapon, as a real 3D model, turning on the card.
// ---------------------------------------------------------------------
// Built 2026-08-09. The owner asked for this twice: "i'd love to see a
// 3d spinning weapon model instead of the sprite above the word Manners"
// and then "3d model rotating, like the template".
//
// ---------------------------------------------------------------------
// WHY IT NEEDS A DUMMY SPRITE
//
// A model-only actor still has to bind its model to a real SPRITE FRAME.
// TNT1 is special-cased as invisible and will not carry one, so the
// plinth ships a 1x1 fully transparent PNG (sprites/rs_plinth/RSPLA0.png)
// purely as something for MODELDEF to attach to. Nothing ever sees it --
// if the model fails to load you get nothing rather than a stray pixel,
// which is the correct failure.
//
// WHY ONE SUBCLASS PER FAMILY
//
// MODELDEF blocks are keyed on ACTOR CLASS, not on sprite. One class can
// therefore carry exactly one model. Showing thirteen different weapons
// means thirteen classes that all share the same RSPL A frame, each with
// its own block naming its own .md3.
//
// This is also why the models could not simply be reused as-is: every
// existing MODELDEF binding in this project points at a HUD frame (PISG,
// SMGR, SHTG...) under Models/Weapons/hud/. Those are first-person view
// frames. A thing standing in the world has no PISG state, so it can
// never resolve one of those bindings -- the art is shared, the binding
// cannot be.
//
// ---------------------------------------------------------------------
// SCALE IS DELIBERATELY SMALL
//
// These are HUD models, authored to fill the bottom of a screen at
// arm's length. On a card they are furniture. The base Scale here is a
// starting point the owner is expected to tune, not a measured value --
// there is no way to know what reads well without looking at it.
// =====================================================================

class RS_ModelPlinth : Actor
{
	// Degrees per tic. 3.0 is a full turn in ~4 seconds, slow enough to
	// read the weapon's silhouette rather than smear it.
	double SpinRate;

	Default
	{
		Radius 1;
		Height 1;
		+NOGRAVITY
		+NOINTERACTION
		+DONTSPLASH
		+CLIENTSIDEONLY
		+NOTIMEFREEZE
		Scale 0.35;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (SpinRate == 0)
			SpinRate = 3.0;
	}

	override void Tick()
	{
		Super.Tick();
		// NOTIMEFREEZE above is why this keeps turning while a menu or a
		// level-up card is open -- which is exactly when someone is
		// looking at it.
		angle += SpinRate;
	}

	// The plinth rides its card rather than being placed once: a card
	// that moves with the player would otherwise leave its model behind.
	// Called by whatever owns the card.
	void PlaceAt(Vector3 where)
	{
		SetOrigin(where, true);
	}

	// RSPL A is the frame every plinth MODELDEF block binds to. Without a
	// States block the actor has NO frame at all and the model can never
	// resolve -- it would spawn, tick, turn, and draw nothing, with no
	// error anywhere. -1 duration because the model is the whole visual;
	// there is nothing to animate on the sprite side.
	States
	{
	Spawn:
		RSPL A -1;
		Stop;
	}
}

// ---------------------------------------------------------------------
// One per family. Empty bodies on purpose -- the whole difference
// between these is which MODELDEF block names them, and a block cannot
// be keyed on anything but the class.
//
// ELEVEN, matching the eleven MODELDEF blocks exactly. There is no Fist
// plinth: VR_Fist has no model block of its own to copy, and a class
// with no binding spawns, turns, and draws NOTHING -- silently. Melee
// maps to the chainsaw instead, which does have one.
// ---------------------------------------------------------------------
class RS_Plinth_Pistol        : RS_ModelPlinth {}
class RS_Plinth_Revolver      : RS_ModelPlinth {}
class RS_Plinth_Rifle         : RS_ModelPlinth {}
class RS_Plinth_SMG           : RS_ModelPlinth {}
class RS_Plinth_Shotgun       : RS_ModelPlinth {}
class RS_Plinth_SuperShotgun  : RS_ModelPlinth {}
class RS_Plinth_Chaingun      : RS_ModelPlinth {}
class RS_Plinth_PlasmaRifle   : RS_ModelPlinth {}
class RS_Plinth_RocketLauncher: RS_ModelPlinth {}
class RS_Plinth_BFG           : RS_ModelPlinth {}
class RS_Plinth_Chainsaw      : RS_ModelPlinth {}

// ---------------------------------------------------------------------
// WHICH PLINTH FOR WHICH WEAPON.
//
// Keyed on the weapon's own archetype keyword rather than on its class,
// so a GH_ or PS_ set weapon of the same archetype gets the right model
// without needing its own entry. Returns null for anything unmapped, and
// a null is a legitimate answer -- the card simply shows no model rather
// than a wrong one.
// ---------------------------------------------------------------------
class RS_PlinthFor
{
	static Class<Actor> ForWeapon(RS_Weapon w)
	{
		if (!w) return null;

		string a = w.GetPaletteArchetype();

		if (a == "pistol")        return "RS_Plinth_Pistol";
		if (a == "revolver")      return "RS_Plinth_Revolver";
		if (a == "rifle")         return "RS_Plinth_Rifle";
		if (a == "smg")           return "RS_Plinth_SMG";
		if (a == "shotgun")       return "RS_Plinth_Shotgun";
		if (a == "supershotgun")  return "RS_Plinth_SuperShotgun";
		if (a == "chaingun")      return "RS_Plinth_Chaingun";
		if (a == "energy")        return "RS_Plinth_PlasmaRifle";
		if (a == "launcher")      return "RS_Plinth_RocketLauncher";
		if (a == "bfg")           return "RS_Plinth_BFG";
		if (a == "melee")         return "RS_Plinth_Chainsaw";

		return null;
	}
}
