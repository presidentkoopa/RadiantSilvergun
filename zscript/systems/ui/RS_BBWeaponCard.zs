// =====================================================================
// RS_BBWeaponCard -- one weapon card, composed, costing no textures.
// ---------------------------------------------------------------------
// This is zscript/CardTemplate.txt built for real. The owner's drawing
// is three of these side by side: offhand on the left, the new drop in
// the centre, mainhand on the right, and the take action on the wings.
//
// WHY THIS EXISTS RATHER THAN A CANVAS. A painted card needs a
// canvastexture declared by hand in ANIMDEFS, and two billboards
// pointing at the same canvas show the SAME picture -- so every
// simultaneously-visible card costs one texture. RS has eleven and the
// triptych spends nine. That is not a budget, it is a ceiling: a second
// elite dropping while the first card is up had nowhere to draw.
//
// Composed of payloads it costs none, so the answer to "how many cards
// can be up at once" stops being a number.
//
// LAYOUT IS IN PANEL UNITS, not map units. Everything is a fraction of
// the card's own width and height, so one card scales whole and a
// wing does not need its own set of magic numbers.
// =====================================================================

class RS_BBWeaponCard
{
	// Rows, top to bottom, matching CardTemplate.txt's order. Kept as a
	// count rather than a list because the stat block is fixed: the card
	// is a comparison, and a comparison whose rows move between the
	// things being compared is not one.
	const ROWS = 8;

	// -----------------------------------------------------------------
	// Build one card into `grp`.
	//
	// `at` is the card's centre. `row` is the hit-test row index the
	// whole card answers to, so pointing anywhere on it -- plate, name,
	// any number -- resolves to the same choice. Pass -1 for a card that
	// is display only, which is what the centre panel of a comparison is.
	// -----------------------------------------------------------------
	static void Build(RS_BillboardGroup grp, Vector3 at, double w, double h,
		double yaw, double tilt, Weapon wep, string heading, int row = -1,
		int facing = LevelLocals.BBF_FIXED, int flags = 0)
	{
		if (!grp || !wep) return;

		let rsw = RS_Weapon(wep);
		Color tier = rsw ? RS_BBWeaponCard.TierRGB(rsw.Tier) : Color(255, 200, 200, 200);

		Vector3 upVec = (0, 0, 1);
		double line = h * 0.055;

		// --- the plate. Carries the row index: it is far and away the
		// biggest target on the card, and pointing at a card should mean
		// the card, not whichever glyph the ray happened to cross. ---
		RS_BBCompose.Plate(grp, at, w, h, yaw, tilt,
			Color(210, 18, 18, 22), row, facing, flags);

		// --- heading: which hand, or that this is the drop ---
		RS_BBCompose.Text(grp, at + upVec * (h * 0.43), heading, line * 0.9,
			yaw, tilt, Color(255, 190, 190, 190), 0, row, facing, flags);

		// --- name, in tier colour. The one place rarity appears as
		// decoration is nowhere; it appears here as data. (rs_10 L4) ---
		RS_BBCompose.Text(grp, at + upVec * (h * 0.35), wep.GetTag(), line * 1.15,
			yaw, tilt, tier, 0, row, facing, flags);

		// --- the weapon's own icon ---
		TextureID icon = wep.Icon;
		if (icon.IsValid())
		{
			RS_BBCompose.Picture(grp, at + upVec * (h * 0.20), icon,
				w * 0.55, h * 0.16, yaw, tilt, Color(255, 255, 255, 255),
				row, facing, flags);
		}

		if (!rsw)
		{
			// Outside the roll system -- an import, a vanilla leftover.
			// Say so rather than printing a column of zeroes that reads
			// as the worst weapon ever generated.
			RS_BBCompose.Text(grp, at, "NOT ROLLED", line,
				yaw, tilt, Color(255, 140, 140, 140), 0, row, facing, flags);
			return;
		}

		// --- the stat block ---
		double y = h * 0.06;
		Color labelCol = Color(255, 170, 160, 140);
		Color valueCol = Color(255, 255, 255, 255);

		y -= RS_BBCompose.StatRow(grp, at + upVec * y, w, "DAMAGE",
			rsw.DamagePerShot, line, yaw, tilt, labelCol, valueCol, row);
		y -= RS_BBCompose.StatRow(grp, at + upVec * y, w, "ACCURACY",
			int(rsw.Accuracy), line, yaw, tilt, labelCol, valueCol, row);
		y -= RS_BBCompose.StatRow(grp, at + upVec * y, w, "CRIT",
			int(rsw.CritChance * 100), line, yaw, tilt, labelCol, valueCol, row);
		y -= RS_BBCompose.StatRow(grp, at + upVec * y, w, "CAPACITY",
			rsw.Capacity, line, yaw, tilt, labelCol, valueCol, row);
		y -= RS_BBCompose.StatRow(grp, at + upVec * y, w, "PELLETS",
			rsw.PelletCount, line, yaw, tilt, labelCol, valueCol, row);
		y -= RS_BBCompose.StatRow(grp, at + upVec * y, w, "SOCKETS",
			rsw.GunBonaiSockets, line, yaw, tilt, labelCol, valueCol, row);

		// --- condition as a meter, not a number. It is the one stat
		// answering "is this about to fail", and a bar answers that at a
		// glance where a number has to be read. ---
		RS_BBCompose.Text(grp, at + upVec * y - (sin(yaw), -cos(yaw), 0) * (w * 0.44),
			"CONDITION", line, yaw, tilt, labelCol, -1, row, facing, flags);
		y -= line * 1.4;
		RS_BBCompose.Bar(grp, at + upVec * y, int(rsw.Condition), w * 0.80, line * 0.8,
			yaw, tilt, ConditionRGB(rsw.Condition), row, facing, flags);
	}

	// RS_UIStyle's ramp, as real colours rather than font ranges, since a
	// billboard is tinted rather than translated.
	static Color TierRGB(int t)
	{
		switch (t)
		{
			case VRT_Cursed:    return Color(255, 120,  20,  20);
			case VRT_Trash:     return Color(255, 140, 100,  60);
			case VRT_Basic:     return Color(255, 170, 170, 170);
			case VRT_Common:    return Color(255, 255, 255, 255);
			case VRT_Uncommon:  return Color(255,  80, 220,  90);
			case VRT_Advanced:  return Color(255,  90, 170, 255);
			case VRT_Designer:  return Color(255, 190, 110, 255);
			case VRT_Prototype: return Color(255, 255, 205,  60);
		}
		return Color(255, 170, 170, 170);
	}

	// Matches RS_UIStyle.ConditionColor's bands.
	static Color ConditionRGB(double cnd)
	{
		if (cnd >= 80.0) return Color(255,  80, 220,  90);
		if (cnd >= 40.0) return Color(255, 235, 210,  70);
		return Color(255, 230,  70,  60);
	}
}
