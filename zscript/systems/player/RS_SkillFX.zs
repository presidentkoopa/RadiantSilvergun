// ---------------------------------------------------------------------------
// Skill effects -- gameplay behavior driven by which skill is active, keyed
// off MAPINFO's ACSReturn on the skill block (see MAPINFO.txt). Nothing in
// this mod runs ACS; ACSReturn is MAPINFO's only "give me one small int per
// skill" hook, read natively via G_SkillPropertyInt(SKILLP_ACSReturn) --
// Object.G_SkillPropertyInt is a global-scope native (doombase.zs), callable
// from a plain EventHandler with no actor in hand.
//
// EXPANDING THIS: right now there is exactly one profile (Black Metal, ID 1)
// and one effect (speed). Add a NEW EFFECT to an existing profile by adding
// a field to RS_SkillFXProfile and setting it in GetProfile()'s matching
// case. Give a NEW SKILL its own effects by giving it a new ACSReturn ID in
// MAPINFO.txt and a new case here. Nothing else in this file changes shape.
// ---------------------------------------------------------------------------

struct RS_SkillFXProfile
{
	double SpeedMult;
}

class RS_SkillFXLib
{
	// FILLS AN OUT PARAMETER, does not return the struct.
	//
	// ZScript cannot return a struct BY VALUE -- written as
	// `static RS_SkillFXProfile GetProfile(int id)` with `return p;` the
	// compiler reads the return type as a POINTER to the struct and the
	// file will not compile: "Cannot convert Struct<RS_SkillFXProfile> to
	// Pointer<Struct<RS_SkillFXProfile>>".
	//
	// An out parameter rather than the two obvious alternatives. Returning
	// a bare double works only while there is exactly one field, and this
	// file's own header promises the opposite -- "add a field to
	// RS_SkillFXProfile" is the documented way to extend it. Making the
	// profile a class instead would allow a real return, but the caller is
	// WorldTick, running per player per tic, and that is an allocation
	// every tic to carry one number.
	static void GetProfile(int id, out RS_SkillFXProfile p)
	{
		p.SpeedMult = 1.0;

		switch (id)
		{
		case 1: // Black Metal -- "you move 25% faster"
			p.SpeedMult = 1.25;
			break;
		default:
			break;
		}
	}
}

// The actual movement hook. PlayerPawn.TweakSpeeds (player.zs) multiplies
// every carried Inventory item's GetSpeedFactor() together -- the one
// mechanism that reaches every player class this mod ships (nine of them,
// per MAPINFO's PlayerClasses) without subclassing each one individually.
// Mult is set by the handler below at runtime, not hardcoded here, so a
// profile's number can change without touching this class.
class RS_SkillSpeedToken : Inventory
{
	double Mult;

	default
	{
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.NOTELEPORTFREEZE
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
	}

	override double GetSpeedFactor()
	{
		return Mult > 0 ? Mult : 1.0;
	}
}

// Applies the active skill's profile to every in-game player, every tic.
// Per-tic rather than grant-once-on-spawn: a player pawn is replaced on
// death/respawn, and re-checking here means the token always follows
// whichever pawn is CURRENT without hooking every possible spawn path.
// Same shape as VRStabilizeSyncHandler in the engine's own zscript --
// don't chase every event that could change the answer, just resync it
// every tic.
class RS_SkillFXHandler : EventHandler
{
	override void WorldTick()
	{
		int id = G_SkillPropertyInt(SKILLP_ACSReturn);

		for (int i = 0; i < MAXPLAYERS; ++i)
		{
			if (!playeringame[i] || players[i].mo == null)
				continue;

			let pawn = players[i].mo;
			let token = RS_SkillSpeedToken(pawn.FindInventory("RS_SkillSpeedToken"));

			if (id == 0)
			{
				if (token)
					token.Destroy();
				continue;
			}

			RS_SkillFXProfile profile;
			RS_SkillFXLib.GetProfile(id, profile);

			if (!token)
				token = RS_SkillSpeedToken(pawn.GiveInventoryType("RS_SkillSpeedToken"));

			if (token)
				token.Mult = profile.SpeedMult;
		}
	}
}
