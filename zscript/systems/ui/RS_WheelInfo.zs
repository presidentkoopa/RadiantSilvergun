// =====================================================================
// RS_WheelInfo -- what the VR weapon wheel's info panel says.
// ---------------------------------------------------------------------
// The engine draws the panel and asks us what goes in it, through
// PlayerPawn.GetVRWheelInfo(item, hand) (E:\UZDXREMA, player.zs). It has
// to ask, because everything worth reading here lives in script: six
// copies of the same revolver are six subclasses with six different
// rolls, and anything the engine assembled by itself could only show
// class defaults -- the same four lines, six times, for six guns the
// whole mod exists to tell apart.
//
// THIS IS NOT THE WEAPON SHEET. The sheet (RS_Screens, S1/S2) is read
// standing still with time to spare, and shows everything. This is read
// mid-fight with a thumb on a stick, so it carries only what decides
// WHICH GUN TO HOLD: what it is, how rare, how hard it hits, whether
// it is about to break, and whether it is loaded. Rate of fire,
// velocity, crit, choke and the affix roster all stay on the sheet.
//
// COLOUR: rs_10's L4 doctrine -- rarity appears as data, never as
// decoration. So the name carries tier colour and condition carries its
// band colour, and nothing else is coloured at all.
// =====================================================================

extend class VR_DualClassBase
{
	// GZDoom's own escape form. The engine's world-text drawer parses these
	// exactly as the 2D one does, so \c[Gold] arrives as gold rather than as
	// four visible characters.
	static string RS_TierColorTag(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return "\c[DarkRed]";
			case VRT_Trash:     return "\c[Brown]";
			case VRT_Basic:     return "\c[Gray]";
			case VRT_Common:    return "\c[White]";
			case VRT_Uncommon:  return "\c[Green]";
			case VRT_Advanced:  return "\c[LightBlue]";
			case VRT_Designer:  return "\c[Purple]";
			case VRT_Prototype: return "\c[Gold]";
		}
		return "\c[Gray]";
	}

	// Matches RS_UIStyle.ConditionColor's bands, in escape form.
	static string RS_ConditionColorTag(double cnd)
	{
		if (cnd >= 80.0) return "\c[Green]";
		if (cnd >= 40.0) return "\c[Yellow]";
		return "\c[Red]";
	}

	override string GetVRWheelInfo(Inventory item, int hand)
	{
		if (item == null) return "";

		let wep = Weapon(item);
		if (wep == null)
		{
			// Not a weapon -- let the engine's own count-and-tag fallback do it.
			// There is nothing RS-specific to add about a medkit.
			return "";
		}

		let rsw = RS_Weapon(wep);
		if (rsw == null)
		{
			// A weapon from outside the RS roll system (an imported set piece, a
			// vanilla leftover). Say so plainly rather than printing zeroes that
			// look like a terrible roll.
			return wep.GetTag() .. "\n\c[DarkGray]not a rolled weapon";
		}

		// --- line 1: name, in tier colour. The engine draws it larger. ---
		string out = RS_TierColorTag(rsw.Tier) .. wep.GetTag();

		// --- line 2: tier and promotion pips ---
		out = out .. "\n" .. RS_UIStyle.TierName(rsw.Tier)
			.. "  " .. RS_UIStyle.Pips(rsw.PromotionCount);

		// --- line 3: level, damage, condition ---
		// Level comes from GunBonsai, which owns the XP axis; a weapon with no
		// info object yet simply has no level to show, which is not an error.
		string statLine = "";
		let stats = TFLV_PerPlayerStats.GetStatsFor(self);
		let info = stats ? stats.GetInfoFor(wep) : null;
		if (info)
		{
			statLine = String.Format("LVL %d   ", info.level);
		}
		statLine = statLine .. String.Format("DMG %d", rsw.DamagePerShot);
		statLine = statLine .. "   " .. RS_ConditionColorTag(rsw.Condition)
			.. String.Format("CND %d%%", int(rsw.Condition));
		out = out .. "\n" .. statLine;

		// --- line 4: affixes, as a count. Which ones is a sheet question; how
		// many is a "does this gun do anything special" question, and that is
		// the one being asked at arm's length. ---
		if (info && info.upgrades)
		{
			int held = 0;
			for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
			{
				if (info.upgrades.upgrades[i].level > 0) held++;
			}
			if (held > 0)
			{
				out = out .. "\n" .. String.Format("%d affix%s", held, held == 1 ? "" : "es");
			}
		}

		// --- line 5: loaded / reserve. Last because it is the only line that
		// changes second to second, so it never shifts the lines above it. ---
		// AmmoType2 is the chambered-round item across RS weapons and AmmoType1
		// the reserve it fills from, so loaded-then-reserve is the honest order.
		if (wep.Ammo2 != null)
		{
			int reserve = wep.Ammo1 != null ? wep.Ammo1.Amount : 0;
			out = out .. "\n" .. String.Format("%d / %d", wep.Ammo2.Amount, reserve);
		}
		else if (wep.Ammo1 != null)
		{
			out = out .. "\n" .. String.Format("%d", wep.Ammo1.Amount);
		}

		return out;
	}
}
