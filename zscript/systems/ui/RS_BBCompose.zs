// =====================================================================
// RS_BBCompose -- build a panel out of billboard payloads.
// ---------------------------------------------------------------------
// The engine's five payloads landed 2026-08-07. Before that only
// BB_TEXTURE drew, so every in-world panel had to be PAINTED onto a
// canvas -- and a canvas is a named texture declared by hand in
// ANIMDEFS. RS has eleven of them and the drop triptych alone spends
// nine. Ten elites on screen was not a performance problem, it was an
// impossibility: there were no textures left to give them.
//
// A composed panel costs no textures at all. A number is BB_DIGITS, a
// meter is BB_BAR, a plate is BB_PANEL, a letter is BB_GLYPH. Build as
// many as you like.
//
// WHEN TO STILL USE A CANVAS: real artwork. A painted card face, a
// portrait, anything with a picture on it. Composition is for readouts
// -- names, numbers, bars, plates -- and those are exactly what the
// drop triptych is made of.
//
// EVERYTHING RETURNS INTO A GROUP. A billboard handle dropped without
// Release is a leak the garbage collector cannot see: it is not an
// actor, nothing owns it, and it survives until the level ends. So
// nothing here hands a raw handle back -- parts go into the
// RS_BillboardGroup you pass in, and that group's ReleaseAll is the one
// place cleanup happens.
// =====================================================================

class RS_BBCompose
{
	// Glyph advance as a fraction of glyph height. The engine fits each
	// BB_GLYPH inside the billboard it is given, so this is spacing, not
	// the letter's own width -- proportional spacing would need per-char
	// metrics that script cannot reach, and a fixed pitch reads fine for
	// the short all-caps strings these panels use.
	const GLYPH_PITCH = 0.62;

	// -----------------------------------------------------------------
	// TEXT. One BB_GLYPH per character, laid along `right`.
	//
	// Costs a billboard per letter, which sounds extravagant and is not:
	// the primitive exists precisely so hundreds can be built without an
	// actor apiece, and a letter is the cheapest thing it draws. A
	// twenty-character weapon name is twenty quads.
	//
	// align: -1 starts at `at`, 0 centres on it, +1 ends at it.
	// -----------------------------------------------------------------
	static void Text(RS_BillboardGroup grp, Vector3 at, string txt,
		double h, double yaw, double tilt, Color col,
		int align = -1, int row = -1, int facing = LevelLocals.BBF_FIXED,
		int flags = 0)
	{
		if (!grp || txt.Length() == 0 || h <= 0) return;

		double pitch = h * GLYPH_PITCH;
		double width = pitch * txt.Length();

		// Design-space right, matching the engine's own convention:
		// right = (sin yaw, -cos yaw, 0). ZScript's sin/cos take degrees,
		// which is what yaw already is. Getting this backwards writes the
		// string mirrored, and that survives a surprisingly long time
		// before anyone reads it closely enough to notice.
		Vector3 rightVec = (sin(yaw), -cos(yaw), 0);

		double start = 0;
		if (align == 0)      start = -width * 0.5;
		else if (align > 0)  start = -width;

		for (int i = 0; i < txt.Length(); i++)
		{
			int ch = txt.ByteAt(i);
			if (ch == 32) continue;		// space: advance, draw nothing

			Vector3 p = at + rightVec * (start + pitch * (i + 0.5));
			grp.Add(RS_Billboard.Make(p, pitch, h, yaw, tilt,
				LevelLocals.BB_GLYPH, ch, col, facing, flags), row);
		}
	}

	// -----------------------------------------------------------------
	// A NUMBER. One billboard whatever the magnitude -- the engine fits
	// the digits to the box, shrinking a long value rather than letting
	// it run off the ends of its own panel.
	// -----------------------------------------------------------------
	static RS_Billboard Number(RS_BillboardGroup grp, Vector3 at, int value,
		double w, double h, double yaw, double tilt, Color col,
		int row = -1, int facing = LevelLocals.BBF_FIXED, int flags = 0)
	{
		if (!grp) return null;
		return grp.Add(RS_Billboard.Make(at, w, h, yaw, tilt,
			LevelLocals.BB_DIGITS, value, col, facing, flags), row);
	}

	// -----------------------------------------------------------------
	// A METER. pct is 0..100 and the engine grows the fill from the LEFT
	// edge, so only the right end moves. Condition, XP, anything read at
	// a glance.
	// -----------------------------------------------------------------
	static RS_Billboard Bar(RS_BillboardGroup grp, Vector3 at, int pct,
		double w, double h, double yaw, double tilt, Color col,
		int row = -1, int facing = LevelLocals.BBF_FIXED, int flags = 0)
	{
		if (!grp) return null;
		return grp.Add(RS_Billboard.Make(at, w, h, yaw, tilt,
			LevelLocals.BB_BAR, clamp(pct, 0, 100), col, facing, flags), row);
	}

	// -----------------------------------------------------------------
	// A PLATE. The backing every other part sits on. Give it a row index
	// if it should be hit-testable -- the plate is a much bigger target
	// than the text on it, so pointing at a card should mean pointing at
	// its plate, not at whichever letter the ray happened to cross.
	// -----------------------------------------------------------------
	static RS_Billboard Plate(RS_BillboardGroup grp, Vector3 at,
		double w, double h, double yaw, double tilt, Color col,
		int row = -1, int facing = LevelLocals.BBF_FIXED, int flags = 0)
	{
		if (!grp) return null;
		return grp.Add(RS_Billboard.Make(at, w, h, yaw, tilt,
			LevelLocals.BB_PANEL, 0, col, facing, flags), row);
	}

	// -----------------------------------------------------------------
	// A PICTURE. The one payload that still needs a real texture -- a
	// weapon's own icon, or a painted canvas where artwork is wanted.
	// -----------------------------------------------------------------
	static RS_Billboard Picture(RS_BillboardGroup grp, Vector3 at, TextureID tex,
		double w, double h, double yaw, double tilt, Color col,
		int row = -1, int facing = LevelLocals.BBF_FIXED, int flags = 0)
	{
		if (!grp || !tex.IsValid()) return null;
		return grp.Add(RS_Billboard.Make(at, w, h, yaw, tilt,
			LevelLocals.BB_TEXTURE, tex.GetIndex(), col, facing, flags), row);
	}

	// -----------------------------------------------------------------
	// A LABELLED STAT ROW: "DAMAGE" on the left, the value on the right.
	// The shape every line of the owner's card template has.
	//
	// Returns the row's vertical size so a caller can stack them without
	// re-deriving the spacing.
	// -----------------------------------------------------------------
	static double StatRow(RS_BillboardGroup grp, Vector3 rowCentre, double panelW,
		string label, int value, double lineH, double yaw, double tilt,
		Color labelCol, Color valueCol, int row = -1)
	{
		if (!grp) return 0;

		Vector3 rightVec = (sin(yaw), -cos(yaw), 0);
		double edge = panelW * 0.5 * 0.88;		// inset from the plate's rim

		Text(grp, rowCentre - rightVec * edge, label, lineH, yaw, tilt,
			labelCol, -1, row);
		Number(grp, rowCentre + rightVec * (edge * 0.55), value,
			panelW * 0.28, lineH, yaw, tilt, valueCol, row);

		return lineH * 1.5;
	}
}
