// =====================================================================
// RS_StatusBar -- the HUD, rebuilt for two hands.
//
// ---------------------------------------------------------------------
// WHY THIS EXISTS AT ALL
//
// Until now RS_Main shipped NO status bar. No statusbarclass line in
// MAPINFO, no SBARINFO lump, no BaseStatusBar subclass anywhere in the
// tree -- so the mod fell all the way through to the engine default,
// DoomStatusBar, and every number along the bottom of the screen was
// stock Doom.
//
// Survivable for health and armour. WRONG for ammo, and wrong in a way
// no amount of tuning could fix: BaseStatusBar.GetCurrentAmmo() reads
// CPlayer.ReadyWeapon.Ammo1/Ammo2 and nothing else. It has never heard
// of OffhandWeapon. So a mod whose entire premise is a gun in each hand
// was showing one gun's two ammo types in two corners, and the
// right-hand column -- the one that looks like it ought to be your
// offhand -- was your mainhand's reserve.
//
// There is no hook and no cvar that reaches the offhand. It needs a
// status bar of its own, which is this.
//
// ---------------------------------------------------------------------
// THE LAYOUT
//
// Owner's, from a painted-over frame on 2026-08-12: ammo pushed out to
// the two bottom corners, health and armour pulled into the middle.
//
//   MAINHAND              [+] health   [^] armour              OFFHAND
//   mag                                                            mag
//   reserve                                                    reserve
//
// The corners are the point. A hand is a SIDE -- your left gun's
// numbers on the left, your right gun's on the right -- and once ammo
// means "side", the vitals have nowhere to go but the centre, where
// they belong anyway: they are what you check under pressure, and the
// centre is where your eyes already are.
//
// MAG OVER RESERVE, because the top number is the one that runs out
// first. AmmoType2 is this project's magazine and AmmoType1 its reserve
// -- inverted from what the names suggest, and documented at
// RS_Weapon.zs:2452 rather than rediscovered here.
//
// ---------------------------------------------------------------------
// COLOUR
//
// The numerals stay Doom red: STTNUM patches through HUDFONT_DOOM at
// CR_UNTRANSLATED, the most legible thing on screen at speed.
// Recolouring them per hand would trade that legibility for information
// the LABEL already carries. So hand identity lives in the label, in the
// same orange and cyan the weapon sheet rails and the rarity card's
// MAINHAND/OFFHAND chip use. Three surfaces, one meaning.
//
// ---------------------------------------------------------------------
// WHY NOT SUBCLASS DoomStatusBar
//
// Tried first, and it does not work. Of DoomStatusBar's protected
// helpers only DrawBarKeys, DrawBarAmmo, DrawBarWeapons and
// DrawFullscreenKeys are virtual -- DrawFullScreenStuff, the one that
// draws the layout being replaced, is a plain protected method and
// cannot be overridden. Intercepting Draw() instead does not help
// either: BaseStatusBar.Draw is NATIVE, so a grandchild cannot call past
// its parent to reach it, and calling Super.Draw runs DoomStatusBar's
// fullscreen layout underneath this one.
//
// So: straight off BaseStatusBar. The cost is about fifteen lines of
// font and inventory-bar setup copied from DoomStatusBar.Init, which is
// cheaper than any of the ways around it.
//
// ONE CONSEQUENCE, STATED PLAINLY: there is no classic bar any more.
// Screenblocks 10 and below get this same layout rather than the Doom
// status bar graphic. That is deliberate -- the classic bar has one ammo
// slot and this mod has two hands, so it could only ever have lied.
// =====================================================================

class RS_StatusBar : BaseStatusBar
{
	// Stock ramps, nearest the orange/cyan the sheet rails and the rarity
	// card already use for the two hands. A custom TEXTCOLO entry would
	// match exactly and is worth doing if these read wrong beside them.
	const HAND_MAIN = Font.CR_ORANGE;
	const HAND_OFF  = Font.CR_CYAN;

	// Rows, in HUD units up from the bottom edge. The numerals are 16
	// units tall, so 20/40 leaves four units of air between them and the
	// label sits clear above both.
	const ROW_LO  = -20;
	const ROW_HI  = -40;
	const LABEL_Y = -54;

	// How far in from the screen edge. Generous, because a 2736x1113
	// window puts the corners a very long way into peripheral vision and
	// a headset crops the extremes of that further still.
	const EDGE    =  34;

	HUDFont mHUDFont;
	HUDFont mLabelFont;
	InventoryBarState diparms;

	override void Init()
	{
		Super.Init();
		SetSize(0, 320, 200);

		// HUDFONT_DOOM is STTNUM0-9 -- the big red Doom digits. Monospaced
		// on the zero's width so a 9 and a 1 occupy the same column and
		// the numbers stop jittering as they count down.
		Font fnt = "HUDFONT_DOOM";
		mHUDFont = HUDFont.Create(fnt, fnt.GetCharWidth("0"), Mono_CellLeft, 1, 1);

		// A proportional face for the labels. A label in STTNUM would be
		// digits-only and unreadable.
		mLabelFont = HUDFont.Create("SMALLFONT");

		diparms = InventoryBarState.Create();
	}

	// The magazine and reserve for one weapon, as two strings.
	//
	// "--" rather than "0" when a slot is absent: fists, chainsaw and the
	// heavy weapons genuinely have no magazine, and a zero there reads as
	// "you are out" instead of "not applicable".
	private void HandAmmo(Weapon w, out string mag, out string res)
	{
		mag = "--";
		res = "--";
		if (!w) return;

		// AmmoType2 is the magazine in this project, AmmoType1 the
		// reserve. See RS_Weapon.zs:2452 -- the one place the naming is
		// genuinely inverted, so it is worth restating at every use.
		let m = w.Ammo2;
		let r = w.Ammo1;
		if (m) mag = String.Format("%d", m.Amount);
		if (r) res = String.Format("%d", r.Amount);
	}

	// One corner: label, magazine, reserve.
	//
	// `side` is -1 for the left corner and +1 for the right and does all
	// the mirroring -- the x sign and the text alignment. One body rather
	// than two, so the hands cannot drift apart the way two copies of a
	// layout always do.
	private void DrawHand(Weapon w, int side, string label, int xlat)
	{
		string mag, res;
		HandAmmo(w, mag, res);

		// SIGN, and the one that shipped backwards. In BeginHUD space a
		// POSITIVE x auto-aligns from the LEFT edge and a NEGATIVE x from
		// the RIGHT (base_sbar.cpp:636). `EDGE * side` therefore anchored
		// the left hand to the right edge and vice versa, and with the
		// alignment flags pulling the other way both columns walked off
		// the screen. side -1 wants +EDGE.
		int align  = (side < 0) ? DI_TEXT_ALIGN_LEFT : DI_TEXT_ALIGN_RIGHT;
		double x   = -EDGE * side;

		// DrawString has no tint parameter; colour goes through a font
		// translation.
		DrawString(mLabelFont, label, (x, LABEL_Y), align, xlat);
		DrawString(mHUDFont, mag, (x, ROW_HI), align);
		DrawString(mHUDFont, res, (x, ROW_LO), align);
	}

	// Keys, top right, in columns of three. DoomStatusBar's own version is
	// virtual but lives on a class this one no longer descends from.
	private void DrawKeys()
	{
		if (!deathmatch)
		{
			Vector2 keypos = (-10, 2);
			int rowc = 0;
			double roww = 0;
			for (let i = CPlayer.mo.Inv; i != null; i = i.Inv)
			{
				if (i is "Key" && i.Icon.IsValid())
				{
					DrawTexture(i.Icon, keypos, DI_SCREEN_RIGHT_TOP | DI_ITEM_LEFT_TOP);
					Vector2 size = TexMan.GetScaledSize(i.Icon);
					keypos.Y += size.Y + 2;
					roww = max(roww, size.X);
					if (++rowc == 3)
					{
						keypos.Y = 2;
						keypos.X -= roww + 2;
						roww = 0;
						rowc = 0;
					}
				}
			}
		}
		else
		{
			DrawString(mHUDFont, FormatNumber(CPlayer.FragCount, 3), (-3, 1),
				DI_TEXT_ALIGN_RIGHT, Font.CR_GOLD);
		}
	}

	private void DrawRS()
	{
		// --- the two hands, in the two corners ----------------------
		//
		// Either can be null -- mid-switch, or before the class hands out
		// its pair -- and DrawHand copes, so there is no guard here.
		// Swapped 2026-08-12 at the owner's request -- mainhand right,
		// offhand left. Only the SIDE argument moved; label and colour
		// still travel with the hand they name.
		DrawHand(Weapon(CPlayer.ReadyWeapon),   +1, "MAINHAND", HAND_MAIN);
		DrawHand(Weapon(CPlayer.OffhandWeapon), -1, "OFFHAND",  HAND_OFF);

		// --- vitals, centred ----------------------------------------
		//
		// DI_SCREEN_CENTER_BOTTOM re-anchors these to the middle of the
		// bottom edge so the pair stays centred at any aspect. At
		// 2736x1113 the corners are a very long way apart and anything
		// aligned to one would sit alone in the dark.
		int vitalFlags = DI_SCREEN_CENTER_BOTTOM | DI_ITEM_CENTER_BOTTOM;

		// The berserk fist replaces the medkit while Strength is held --
		// vanilla behaviour worth keeping, since it is the only tell that
		// the powerup is live.
		string hIcon = CPlayer.mo.FindInventory("PowerStrength") ? "PSTRA0" : "MEDIA0";
		DrawImage(hIcon, (-58, -6), vitalFlags);
		DrawString(mHUDFont, FormatNumber(CPlayer.health, 3), (-46, ROW_LO),
			DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_LEFT);

		// Armour only when you have some, so an unarmoured player gets a
		// clean centre rather than a permanent zero to learn to ignore.
		let armor = BasicArmor(CPlayer.mo.FindInventory("BasicArmor"));
		if (armor && armor.Amount > 0)
		{
			DrawInventoryIcon(armor, (22, -6), vitalFlags);
			DrawString(mHUDFont, FormatNumber(armor.Amount, 3), (34, ROW_LO),
				DI_SCREEN_CENTER_BOTTOM | DI_TEXT_ALIGN_LEFT);
		}

		DrawKeys();

		if (isInventoryBarVisible())
			DrawInventoryBar(diparms, (0, 0), 7, DI_SCREEN_CENTER_BOTTOM, HX_SHADOW);
	}

	override void Draw(int state, double TicFrac)
	{
		Super.Draw(state, TicFrac);
		if (state == HUD_None) return;

		// Same layout for both states. See the header -- the classic bar
		// is gone on purpose, because it has one ammo slot and this mod
		// has two hands.
		BeginHUD();
		DrawRS();
	}
}
