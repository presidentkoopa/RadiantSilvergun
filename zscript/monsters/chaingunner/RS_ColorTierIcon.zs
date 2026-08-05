// =====================================================================
// RS_ColorTierIcon -- CH's floating tier marker, rebuilt.
// ---------------------------------------------------------------------
// SOURCE:  E:\New folder\ART SOURCE\CH\DECORATE.txt:709-...
// ACTORS:  ColorTierIconCH .. ColorTierIconCH13  (one per tier)
//
// WHAT THIS ACTUALLY IS, because the name undersells it: in CH this is an
// ACCESSIBILITY FEATURE, not decoration. CH's whole difficulty ladder is
// encoded as a palette tint, so a player who cannot separate green from
// brown cannot read how dangerous the thing walking at them is. The icon
// puts the tier on screen as a SHAPE instead of a colour.
//
// CH gates it on `CallACS("CH_ColorBlind") == 1`, i.e. it is OFF unless
// the player turns it on. We keep that behaviour and that default, and
// the ACS call becomes a direct CVar read -- rs_mon_tiericons, exposed in
// Monster Diagnostics. There is no ACS in this tree and none is needed;
// the CH script did nothing but `SetResultValue(GetCVar(...))`.
//
// This matters more here than it did in CH. With the glow system in play
// the environment itself is coloured, so a monster's tint competes with
// the floor and walls for the same channel. A shape does not.
//
// Every previous import deleted these spawns outright. They are being
// restored to all fourteen chaingunner bodies.
//
// SPRITES: TI3R A-M, thirteen frames, one per tier. Already in
// sprites/ -- all thirteen verified present, matching CH's own count.
//
// SPAWNED AS: CH calls
//   A_SpawnItemEx("ColorTierIconCH<n>", 0,0,32, random(1,4),0,random(0,2),
//                 random(0,359), SXF_NOCHECKPOSITION)
// -- z+32, a small random drift, random facing. Kept verbatim at the
// call sites so the icons scatter the way CH's do rather than stacking
// into one blob over the monster's head.
// =====================================================================

class RS_ColorTierIcon : Actor
{
	Default
	{
		Radius 1;
		Height 1;
		Speed 1;
		Projectile;
		+NOINTERACTION
	}

	// The tier frame this icon shows. Subclasses override; the base is
	// tier 0. Using one virtual instead of thirteen copied state blocks
	// means the CVar gate exists exactly once -- CH repeats the whole
	// Fly/Death/Show chain in all thirteen actors, and a change there has
	// to be made thirteen times.
	virtual int IconFrame() { return 0; }

	States
	{
	Spawn:
		TNT1 A 0;
	Fly:
		TNT1 A 0
		{
			// CH: A_JumpIf(CallACS("CH_ColorBlind") == 1, "Show").
			// Off by default, exactly as CH ships it.
			let cv = CVar.FindCVar("rs_mon_tiericons");
			if (cv && cv.GetInt() != 0) return ResolveState("Show");
			return ResolveState("Death");
		}
	Death:
		TNT1 A 0;
		Stop;
	Show:
		// A_SetTics/frame chosen from IconFrame() so one block serves
		// every tier. TI3R A is the placeholder the frame call replaces.
		TI3R A 30 Bright
		{
			frame = IconFrame();
		}
		Stop;
	}
}

// One per tier. CH names these ColorTierIconCH (tier 0, frame A) through
// ColorTierIconCH13; the number in CH's name is the tier, and the frame
// letter follows it. Frame letters are 0-indexed here: A=0 .. M=12.
class RS_ColorTierIcon1  : RS_ColorTierIcon { override int IconFrame() { return 1;  } }
class RS_ColorTierIcon2  : RS_ColorTierIcon { override int IconFrame() { return 2;  } }
class RS_ColorTierIcon3  : RS_ColorTierIcon { override int IconFrame() { return 3;  } }
class RS_ColorTierIcon4  : RS_ColorTierIcon { override int IconFrame() { return 4;  } }
class RS_ColorTierIcon5  : RS_ColorTierIcon { override int IconFrame() { return 5;  } }
class RS_ColorTierIcon6  : RS_ColorTierIcon { override int IconFrame() { return 6;  } }
class RS_ColorTierIcon7  : RS_ColorTierIcon { override int IconFrame() { return 7;  } }
class RS_ColorTierIcon8  : RS_ColorTierIcon { override int IconFrame() { return 8;  } }
class RS_ColorTierIcon9  : RS_ColorTierIcon { override int IconFrame() { return 9;  } }
class RS_ColorTierIcon10 : RS_ColorTierIcon { override int IconFrame() { return 10; } }
class RS_ColorTierIcon11 : RS_ColorTierIcon { override int IconFrame() { return 11; } }
class RS_ColorTierIcon12 : RS_ColorTierIcon { override int IconFrame() { return 12; } }
