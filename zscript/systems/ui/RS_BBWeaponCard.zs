// =====================================================================
// RS_BBWeaponCard -- one weapon card, composed, costing no textures.
// ---------------------------------------------------------------------
// zscript/CardTemplate.txt built for real. The owner's drawing is three
// of these side by side: offhand on the left, the drop in the centre,
// mainhand on the right, and the take action on the wings.
//
// WHY, RATHER THAN A CANVAS. A painted card needs a canvastexture
// declared by hand in ANIMDEFS, and two billboards pointing at one
// canvas show the SAME picture -- so every simultaneously-visible card
// costs one texture. RS has eleven and the triptych spends nine. That
// was not a budget, it was a ceiling: a second elite dropping while the
// first card was up had nowhere to draw.
//
// Layout is in MAP UNITS relative to the panel's centre, matching what
// RS_BBComposedPanel stores, and derived from the panel's own width and
// height so one card scales whole.
// =====================================================================

class RS_BBWeaponCard
{
	// -----------------------------------------------------------------
	// Lay a card out into `p`. The panel is placed afterwards by
	// RS_BBComposedPanel.Place, so nothing here knows or cares where in
	// the world it ends up.
	//
	// heading: "MAINHAND", "OFFHAND", "DROP" -- which column this is.
	// -----------------------------------------------------------------
	static void Build(RS_BBComposedPanel p, double w, double h,
		Weapon wep, string heading)
	{
		if (!p || w <= 0 || h <= 0) return;

		let rsw = wep ? RS_Weapon(wep) : null;
		Color tier = rsw ? TierRGB(rsw.Tier) : Color(255, 200, 200, 200);
		double line = h * 0.055;

		// The plate first, so everything else draws over it. Depth testing
		// is off for billboards, so submission order is the only thing
		// deciding what wins.
		RS_BBCompose.Plate(p, 0, 0, w, h, Color(210, 18, 18, 22));

		if (!wep)
		{
			RS_BBCompose.Text(p, 0, 0, heading .. " EMPTY", line * 1.1,
				Color(255, 130, 130, 130), 0);
			return;
		}

		RS_BBCompose.Text(p, 0, h * 0.43, heading, line * 0.9,
			Color(255, 190, 190, 190), 0);

		// Rarity appears as data, never as decoration (rs_10 L4). The name
		// is where it appears.
		RS_BBCompose.Text(p, 0, h * 0.35, wep.GetTag(), line * 1.15, tier, 0);

		TextureID icon = wep.Icon;
		if (icon.IsValid())
		{
			RS_BBCompose.Picture(p, 0, h * 0.20, icon, w * 0.55, h * 0.16,
				Color(255, 255, 255, 255));
		}

		if (!rsw)
		{
			// Outside the roll system -- an import, a vanilla leftover. Say
			// so rather than printing a column of zeroes, which would read
			// as the worst weapon ever generated.
			RS_BBCompose.Text(p, 0, 0, "NOT ROLLED", line,
				Color(255, 140, 140, 140), 0);
			return;
		}

		Color labelCol = Color(255, 170, 160, 140);
		Color valueCol = Color(255, 255, 255, 255);
		double y = h * 0.06;
		double step = line * 1.5;

		RS_BBCompose.StatRow(p, y, w, "DAMAGE",   rsw.DamagePerShot,      line, labelCol, valueCol); y -= step;
		RS_BBCompose.StatRow(p, y, w, "ACCURACY", int(rsw.Accuracy),      line, labelCol, valueCol); y -= step;
		RS_BBCompose.StatRow(p, y, w, "CRIT",     int(rsw.CritChance*100), line, labelCol, valueCol); y -= step;
		RS_BBCompose.StatRow(p, y, w, "CAPACITY", rsw.Capacity,           line, labelCol, valueCol); y -= step;
		RS_BBCompose.StatRow(p, y, w, "PELLETS",  rsw.PelletCount,        line, labelCol, valueCol); y -= step;
		RS_BBCompose.StatRow(p, y, w, "SOCKETS",  rsw.GunBonaiSockets,    line, labelCol, valueCol); y -= step;

		// Condition is a meter where every other stat is a number. It is
		// the one answering "is this about to fail", and a bar answers that
		// at a glance where a number has to be read.
		RS_BBCompose.Text(p, -(w * 0.44), y, "CONDITION", line, labelCol, -1);
		y -= line * 1.4;
		RS_BBCompose.Bar(p, 0, y, int(rsw.Condition), w * 0.80, line * 0.8,
			ConditionRGB(rsw.Condition));
	}

	// RS_UIStyle's ramp as real colours rather than font ranges, since a
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
