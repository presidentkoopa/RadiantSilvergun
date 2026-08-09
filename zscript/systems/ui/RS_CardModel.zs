// =====================================================================
// RS_CardModel -- the weapon, as a real 3D model, turning on the card.
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
// card model ships a 1x1 fully transparent PNG (sprites/rs_cardmodel/RSPLA0.png)
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

class RS_CardModel : Actor
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

	// The model rides its card rather than being placed once: a card
	// that moves with the player would otherwise leave its model behind.
	// Called by whatever owns the card.
	void PlaceAt(Vector3 where)
	{
		SetOrigin(where, true);
	}

	// RSPL A is the frame every card-model MODELDEF block binds to. Without a
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
// Fist model: VR_Fist has no model block of its own to copy, and a class
// with no binding spawns, turns, and draws NOTHING -- silently. Melee
// maps to the chainsaw instead, which does have one.
// ---------------------------------------------------------------------
class RS_CardModel_Pistol        : RS_CardModel {}
class RS_CardModel_Revolver      : RS_CardModel {}
class RS_CardModel_Rifle         : RS_CardModel {}
class RS_CardModel_SMG           : RS_CardModel {}
class RS_CardModel_Shotgun       : RS_CardModel {}
class RS_CardModel_SuperShotgun  : RS_CardModel {}
class RS_CardModel_Chaingun      : RS_CardModel {}
class RS_CardModel_PlasmaRifle   : RS_CardModel {}
class RS_CardModel_RocketLauncher: RS_CardModel {}
class RS_CardModel_BFG           : RS_CardModel {}
class RS_CardModel_Chainsaw      : RS_CardModel {}

// ---------------------------------------------------------------------
// WHICH MODEL FOR WHICH WEAPON.
//
// Keyed on the weapon's own archetype keyword rather than on its class,
// so a GH_ or PS_ set weapon of the same archetype gets the right model
// without needing its own entry. Returns null for anything unmapped, and
// a null is a legitimate answer -- the card simply shows no model rather
// than a wrong one.
// ---------------------------------------------------------------------
// `play`, NOT a bare class. A class with no scope qualifier defaults to
// DATA context, and GetPaletteArchetype is a play function -- so the
// lookup could not read the weapon it was handed. The eleven "Unknown
// identifier 'a'" errors that followed were fallout: the declaration
// failed, so the variable never existed.
class RS_CardModelFor play
{
	static Class<Actor> ForWeapon(RS_Weapon w)
	{
		if (!w) return null;

		string a = w.GetPaletteArchetype();

		if (a == "pistol")        return "RS_CardModel_Pistol";
		if (a == "revolver")      return "RS_CardModel_Revolver";
		if (a == "rifle")         return "RS_CardModel_Rifle";
		if (a == "smg")           return "RS_CardModel_SMG";
		if (a == "shotgun")       return "RS_CardModel_Shotgun";
		if (a == "supershotgun")  return "RS_CardModel_SuperShotgun";
		if (a == "chaingun")      return "RS_CardModel_Chaingun";
		if (a == "energy")        return "RS_CardModel_PlasmaRifle";
		if (a == "launcher")      return "RS_CardModel_RocketLauncher";
		if (a == "bfg")           return "RS_CardModel_BFG";
		if (a == "melee")         return "RS_CardModel_Chainsaw";

		return null;
	}
}
