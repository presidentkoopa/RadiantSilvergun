// =====================================================================
// RS_Material -- WHAT DID I JUST SHOOT?
// ---------------------------------------------------------------------
// Every impact effect in this mod used to be surface-blind. A bullet
// hitting a steel door, a rock wall, a pool of slime and a Baron all
// produced the same puff, the same debris and -- worst of it -- the same
// ricochet sound, unconditionally, on every single shot. That is the
// defect this file exists to end.
//
// The engine already knows the answer and hands it over for free:
// Actor.LineTrace fills an FLineTraceData with HitType (wall / floor /
// ceiling / actor / sky), HitTexture (the actual TextureID of the
// surface) and HitActor. No engine change, no per-map authoring, no
// TERRAIN lump. Resolve() does that trace from the impact point and
// turns it into one number.
//
// TEN MATERIALS -- six surfaces plus four flesh sub-types (owner ruling,
// 2026-08-07):
//
//     surfaces   METAL  STONE  WOOD  DIRT  LIQUID  GLASS
//     bodies     ORGANIC  ARMORED  MECHANICAL  ENERGY
//
// STONE is the fallback for any surface we cannot identify, because it
// is the least surprising wrong answer in a Doom map.
//
// ---------------------------------------------------------------------
// HOW TO EXTEND THIS (read before adding a monster or a texture set)
//
// Both resolvers are ordered `if` chains over substrings, NOT tables.
// `static const TYPE name[] = { ... }` array literals do not reliably
// resolve on this engine build -- that has been found and fixed three
// separate times in this project (see CLAUDE.md), and this file is not
// going to be the fourth.
//
// Texture matching is deliberately by SUBSTRING and case-insensitive, so
// BROWN96, BROWNGRN and SW1BROWN all land together without listing every
// variant. Order matters: the first match wins, so put specific patterns
// above general ones.
//
// THE MONSTER MAPPING IS A FIRST PASS AND IS MEANT TO BE TUNED. It reads
// engine properties first (bNOBLOOD is a hard fact, a class-name
// substring is a guess) and only falls back to names. It classifies from
// OUTSIDE the monster files on purpose: zscript/monsters/** is protected,
// so a monster can never be asked to declare its own material.
// =====================================================================

enum ERSMaterial
{
	RSMAT_STONE = 0,     // fallback -- also the honest answer for most Doom walls
	RSMAT_METAL,
	RSMAT_WOOD,
	RSMAT_DIRT,
	RSMAT_LIQUID,
	RSMAT_GLASS,

	RSMAT_FLESH_ORGANIC,
	RSMAT_FLESH_ARMORED,
	RSMAT_FLESH_MECHANICAL,
	RSMAT_FLESH_ENERGY
}

class RS_Material : Object
{
	// -----------------------------------------------------------------
	// THE TRACE. Called from a puff's PostBeginPlay.
	//
	// A puff is spawned AT the impact point, which is the one place a
	// forward trace finds nothing -- so we step back along the shot and
	// trace forward through where we already are. 24 units back, 48
	// forward: enough to re-acquire the surface, short enough that it
	// cannot reach past it to something behind.
	//
	// The engine sets a puff's angle facing BACK toward the shooter
	// (P_SpawnPuff), so the shot direction is angle+180 and the backward
	// offset is a negative forward offset.
	// -----------------------------------------------------------------
	// Delegates to ResolveEx rather than duplicating the trace.
	//
	// It used to have its own copy, and that copy called LineTrace
	// WITHOUT passing the out-parameter -- so `d` was never filled and
	// every HitType test below it read uninitialised memory. Two nearly
	// identical traces where one of them was silently wrong; now there
	// is one, and it is the one that works.
	static play int Resolve(Actor puff)
	{
		FLineTraceData d;
		int mat; bool sky;
		[mat, sky] = ResolveEx(puff, d);
		return mat;
	}

	// Convenience for callers that also want the trace data (decal
	// alignment, splash height, whether it was a floor). Same trace, one
	// call instead of two.
	static play int, bool ResolveEx(Actor puff, out FLineTraceData d)
	{
		if (!puff) return RSMAT_STONE, false;

		bool hit = puff.LineTrace(puff.angle + 180.0, 48.0, puff.pitch,
			0, 0.0, -24.0, 0.0, d);
		if (!hit)
			return RSMAT_STONE, false;

		if (d.HitType == FLineTraceData.TRACE_HasHitSky)
			return RSMAT_STONE, true;
		if (d.HitType == FLineTraceData.TRACE_HitActor)
			return FromActor(d.HitActor), false;
		if (d.HitType == FLineTraceData.TRACE_HitNone)
			return RSMAT_STONE, false;

		return FromTexture(d.HitTexture), false;
	}

	// -----------------------------------------------------------------
	// SURFACE -> MATERIAL, by texture name substring.
	//
	// Covers the stock Doom/Doom2 texture and flat sets. A texture from a
	// custom map that matches nothing lands on STONE, which is the right
	// kind of wrong.
	// -----------------------------------------------------------------
	static int FromTexture(TextureID tex)
	{
		if (!tex.IsValid())
			return RSMAT_STONE;

		String n = TexMan.GetName(tex);
		n = n.MakeUpper();

		// --- LIQUID first: these are flats you stand in, and several of
		// them contain substrings that would otherwise match elsewhere.
		if (Has(n, "NUKAGE") || Has(n, "BLOOD") || Has(n, "SLIME")
		 || Has(n, "LAVA")   || Has(n, "WATER") || Has(n, "FWATER")
		 || Has(n, "SFALL")  || Has(n, "BFALL") || Has(n, "LFALL")
		 || Has(n, "WFALL")  || Has(n, "SWATER"))
			return RSMAT_LIQUID;

		// --- GLASS. Doom has very little; the light panels read as glass
		// and sound better for it.
		if (Has(n, "GLASS") || Has(n, "LITE") || Has(n, "TLITE")
		 || Has(n, "FLAT17") || Has(n, "FLAT22"))
			return RSMAT_GLASS;

		// --- METAL. The largest set in a Doom 2 tech base.
		if (Has(n, "METAL") || Has(n, "SHAWN") || Has(n, "SILVER")
		 || Has(n, "SUPPORT") || Has(n, "DOORTRAK") || Has(n, "TEKWALL")
		 || Has(n, "COMP")  || Has(n, "SPACEW") || Has(n, "PIPE")
		 || Has(n, "BIGDOOR") || Has(n, "SLADWALL") || Has(n, "STEP")
		 || Has(n, "PLAT")  || Has(n, "GRATE")  || Has(n, "CEIL5_")
		 || Has(n, "FLOOR7_") || Has(n, "TEKGREN") || Has(n, "PANEL"))
			return RSMAT_METAL;

		// --- WOOD.
		if (Has(n, "WOOD") || Has(n, "PLANK") || Has(n, "CRATE")
		 || Has(n, "SPLASH") || Has(n, "BROWNWEL"))
			return RSMAT_WOOD;

		// --- DIRT / organic ground.
		if (Has(n, "GRASS") || Has(n, "RROCK") || Has(n, "MFLR")
		 || Has(n, "SAND")  || Has(n, "GRNROCK") || Has(n, "FLOOR0_")
		 || Has(n, "MUD"))
			return RSMAT_DIRT;

		// --- STONE, stated rather than only implied, so the intent is
		// readable: brick, marble, rock, ashwall, the gore walls.
		if (Has(n, "STONE") || Has(n, "BRICK") || Has(n, "MARB")
		 || Has(n, "ROCK")  || Has(n, "ASH")   || Has(n, "GRAY")
		 || Has(n, "STARG") || Has(n, "STARTAN") || Has(n, "BROWN")
		 || Has(n, "SKIN")  || Has(n, "SP_")   || Has(n, "CEIL")
		 || Has(n, "FLAT"))
			return RSMAT_STONE;

		return RSMAT_STONE;
	}

	// -----------------------------------------------------------------
	// BODY -> MATERIAL SUB-TYPE.
	//
	// Engine facts first, guesses second.
	//
	// bNOBLOOD is authoritative: an actor the engine refuses to bleed is
	// not made of meat. Lost souls, the mechanical bosses and every
	// energy body in the CH tree carry it.
	//
	// After that it is class-name substrings, which is a guess, and is
	// why this is documented as a first pass. Names come from the 17 CH
	// families; the RS_ prefix is stripped by the substring test anyway.
	// -----------------------------------------------------------------
	static int FromActor(Actor a)
	{
		if (!a) return RSMAT_STONE;

		String n = a.GetClassName();
		n = n.MakeUpper();

		// --- ENERGY: no body to speak of. Souls, wraiths, spirits, the
		// vile's fire. These should spark and hiss, never crunch.
		if (Has(n, "SOUL")   || Has(n, "WRAITH") || Has(n, "GHOST")
		 || Has(n, "SPIRIT") || Has(n, "PHANTOM") || Has(n, "SHADE")
		 || Has(n, "SPECTRE"))
			return RSMAT_FLESH_ENERGY;

		// --- MECHANICAL: metal chassis. The cyberdemon line, the
		// arachnotron/mastermind spider platforms, anything cybernetic.
		if (Has(n, "CYB")   || Has(n, "MECH")  || Has(n, "BORG")
		 || Has(n, "ROBOT") || Has(n, "ARACH") || Has(n, "SPIDER")
		 || Has(n, "MASTERMIND") || Has(n, "TERMINATOR"))
			return RSMAT_FLESH_MECHANICAL;

		// --- ARMORED: thick hide and plate. Barons, knights, mancubi,
		// revenants (bone plate), and the boss tiers.
		if (Has(n, "BARON")   || Has(n, "KNIGHT") || Has(n, "HK")
		 || Has(n, "FATSO")   || Has(n, "MANCUB") || Has(n, "REVENANT")
		 || Has(n, "SKELE")   || Has(n, "BONE")   || Has(n, "ARCHON")
		 || Has(n, "BRUISER"))
			return RSMAT_FLESH_ARMORED;

		// bNOBLOOD after the name checks so a named organic that happens
		// to carry the flag is still classified by intent, but anything
		// unnamed and bloodless is machinery rather than meat.
		if (a.bNoBlood)
			return RSMAT_FLESH_MECHANICAL;

		return RSMAT_FLESH_ORGANIC;
	}

	// -----------------------------------------------------------------
	// Queries. Callers ask these instead of comparing enum values, so a
	// later material insert doesn't have to be chased through the tree.
	// -----------------------------------------------------------------
	static bool IsFlesh(int m)
	{
		return m == RSMAT_FLESH_ORGANIC || m == RSMAT_FLESH_ARMORED
		    || m == RSMAT_FLESH_MECHANICAL || m == RSMAT_FLESH_ENERGY;
	}

	// CAN THIS SURFACE RICOCHET. Owner ruling 2026-08-07: hard surfaces
	// only, and then only on a roll. Never flesh, never wood, dirt or
	// liquid.
	static bool CanRicochet(int m)
	{
		return m == RSMAT_METAL || m == RSMAT_STONE || m == RSMAT_GLASS;
	}

	// The roll itself, so every caller uses one chance and one cvar.
	static bool RollRicochet(int m)
	{
		if (!CanRicochet(m))
			return false;

		let cv = CVar.FindCVar("rs_fx_ricochet");
		if (cv && !cv.GetBool())
			return false;

		int pct = 25;
		let pc = CVar.FindCVar("rs_fx_ricochet_chance");
		if (pc) pct = clamp(pc.GetInt(), 0, 100);

		return random(1, 100) <= pct;
	}

	// -----------------------------------------------------------------
	// Per-material dispatch. Sounds resolve through SNDINFO logical
	// names; a name with no lump behind it is silent and harmless, so
	// these can be authored incrementally.
	// -----------------------------------------------------------------
	static Sound ImpactSound(int m)
	{
		switch (m)
		{
			case RSMAT_METAL:              return "rs_impact/metal";
			case RSMAT_WOOD:               return "rs_impact/wood";
			case RSMAT_DIRT:               return "rs_impact/dirt";
			case RSMAT_LIQUID:             return "rs_impact/liquid";
			case RSMAT_GLASS:              return "rs_impact/glass";
			case RSMAT_FLESH_ORGANIC:      return "rs_impact/flesh";
			case RSMAT_FLESH_ARMORED:      return "rs_impact/armored";
			case RSMAT_FLESH_MECHANICAL:   return "rs_impact/mechanical";
			case RSMAT_FLESH_ENERGY:       return "rs_impact/energy";
			default:                       return "rs_impact/stone";
		}
	}

	// Debris the impact throws. Flesh throws nothing -- the engine's own
	// blood already covers it, and adding chips to a body reads wrong.
	static String DebrisClass(int m)
	{
		if (IsFlesh(m))
			return "";

		switch (m)
		{
			case RSMAT_METAL:  return "RS_WallPartMetal";
			case RSMAT_WOOD:   return "RS_WallPartWood";
			case RSMAT_DIRT:   return "RS_WallPartDirt";
			case RSMAT_GLASS:  return "RS_WallPartGlass";
			case RSMAT_LIQUID: return "";      // splash, not chips
			default:           return "RS_WallPart";
		}
	}

	static Name DecalName(int m)
	{
		switch (m)
		{
			case RSMAT_METAL:  return 'BulletChip';
			case RSMAT_WOOD:   return 'BulletChip';
			case RSMAT_GLASS:  return 'BulletChip';
			case RSMAT_LIQUID: return 'None';
			default:           return 'BulletChip';
		}
	}

	// A readable name, for the debug netevent and for menu text.
	static String DebugName(int m)
	{
		switch (m)
		{
			case RSMAT_METAL:            return "METAL";
			case RSMAT_WOOD:             return "WOOD";
			case RSMAT_DIRT:             return "DIRT";
			case RSMAT_LIQUID:           return "LIQUID";
			case RSMAT_GLASS:            return "GLASS";
			case RSMAT_FLESH_ORGANIC:    return "FLESH/organic";
			case RSMAT_FLESH_ARMORED:    return "FLESH/armored";
			case RSMAT_FLESH_MECHANICAL: return "FLESH/mechanical";
			case RSMAT_FLESH_ENERGY:     return "FLESH/energy";
			default:                     return "STONE";
		}
	}

	// Substring test. String.IndexOf returns -1 when absent.
	private static bool Has(String hay, String needle)
	{
		return hay.IndexOf(needle) >= 0;
	}
}
