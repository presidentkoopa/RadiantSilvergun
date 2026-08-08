// =====================================================================
// RS_BillboardUI -- level-up choices and weapon status, IN THE WORLD.
// ---------------------------------------------------------------------
// Built 2026-08-07, then rebuilt the same day. Both versions are worth
// recording because the first one was wrong in an instructive way.
//
// WHY THE FIRST VERSION WOULD HAVE DRAWN NOTHING:
// it built each screen out of one billboard PER ROW, using payloads
// 0/2/3/4/5 (panel, digits, glyph, ring, bar), on the reasoning that
// those need no texture handle and were therefore the cheap route while
// TextureID.GetIndex() was missing. The engine lane's answer: those
// payloads are ENUMERATED BUT HAVE NO SHADERS. ProcessBillboard only
// handles BB_TEXTURE; everything else falls through and submits no
// geometry. So the screens would have been invisible, not merely
// unstyled -- and nothing would have errored to say so.
//
// GetIndex() has since landed (engine base.zs:341), so this is the
// version that works: ONE billboard per screen, payload BB_TEXTURE,
// showing a canvas we paint ourselves. Which is also what the drop
// triptych has always done, so there is now one way in-world text is
// drawn in this project rather than two.
//
// ---------------------------------------------------------------------
// SCOPE SPLIT, and it is not optional:
//
//   PLAY (WorldTick, NetworkProcess) -- owns the row data, creates and
//        destroys the billboard, casts the aim ray.
//   UI   (RenderOverlay)             -- paints the canvas. TexMan.GetCanvas
//        and Canvas.DrawText are ui-only.
//
// The billboard shows whatever the canvas currently holds, so the two
// halves never have to talk: play changes the rows, ui repaints, the
// engine re-samples the texture. Same letterbox the panel stack uses.
// =====================================================================

class RS_BBScreen : Object abstract play
{
	// --- the row model (play side) ---------------------------------
	Array<string> mKey;
	Array<string> mVal;
	Array<int>    mColor;
	Array<bool>   mSelectable;

	string mTitle;
	int    mTitleColor;

	int  mHotRow;      // row the hand is pointing at, -1 = none
	bool mAlive;
	bool mDirty;       // set by play, cleared by the painter

	// The canvas we paint and the billboard that shows it.
	RS_Billboard mBoard;

	// Canvas geometry. Matches ANIMDEFS' RSCARDA (256x384).
	const CV_W = 256;
	const CV_H = 384;
	const PAD  = 14;
	const ROW_PITCH = 22;
	const ROWS_TOP  = 76;

	// World size of the quad, in map units.
	const BOARD_W = 72.0;
	const BOARD_H = 108.0;
	const BOARD_AHEAD = 96.0;

	void ClearRows()
	{
		mKey.Clear(); mVal.Clear(); mColor.Clear(); mSelectable.Clear();
		mHotRow = -1;
		mDirty = true;
	}

	void AddRow(string k, string v, int col, bool selectable = false)
	{
		mKey.Push(k); mVal.Push(v); mColor.Push(col);
		mSelectable.Push(selectable);
		mDirty = true;
	}

	virtual void Build(PlayerPawn pawn) {}
	virtual void Confirm(PlayerPawn pawn) {}

	// -----------------------------------------------------------------
	// Raise the quad. VIEW-LOCKED: `pos` becomes an offset from the
	// viewer (X ahead, Y right, Z up) resolved at RENDER rate, so the
	// screen is welded to the view instead of lagging a tic behind and
	// snapping -- which in VR reads as the UI swimming.
	// -----------------------------------------------------------------
	void Raise()
	{
		if (mBoard) return;

		TextureID tex = TexMan.CheckForTexture("RSCARDA", TexMan.Type_Any);
		if (!tex.IsValid()) { mAlive = false; return; }

		mBoard = RS_Billboard.MakeViewLocked(
			(BOARD_AHEAD, 0, 0), BOARD_W, BOARD_H,
			LevelLocals.BB_TEXTURE, tex.GetIndex(),
			Color(255, 255, 255, 255));

		mAlive = mBoard && mBoard.Alive();
		mDirty = true;
	}

	void Close()
	{
		if (mBoard) { mBoard.Release(); mBoard = null; }
		mAlive = false;
		mHotRow = -1;
	}

	// -----------------------------------------------------------------
	// AIM. One ray, one billboard, and the engine hands back the UV --
	// so the row under the hand is just a division. The first version
	// needed a handle-to-row lookup table; this does not, and the hit
	// test cannot drift from the pixels because it IS the pixels.
	// -----------------------------------------------------------------
	void UpdateAim(PlayerPawn pawn, bool offhand)
	{
		if (!mAlive || !pawn || !mBoard) { mHotRow = -1; return; }

		Vector3 start;
		double ang, pit;
		if (offhand)
		{
			start = pawn.OffhandPos; ang = pawn.OffhandAngle; pit = pawn.OffhandPitch;
		}
		else
		{
			start = pawn.AttackPos;  ang = pawn.AttackAngle;  pit = pawn.AttackPitch;
		}

		// Positive pitch looks DOWN in Doom, hence the negated Z.
		Vector3 dir = (cos(ang) * cos(pit), sin(ang) * cos(pit), -sin(pit));

		int hit; Vector2 uv;
		[hit, uv] = level.AimBillboard(start, dir, 512.0);

		int row = -1;
		if (hit == mBoard.Handle())
		{
			// UV is 0..1 across and DOWN the face, the same UV the
			// shader sees. Convert to canvas Y, then to a row index.
			double y = uv.y * CV_H;
			if (y >= ROWS_TOP)
			{
				int r = int((y - ROWS_TOP) / ROW_PITCH);
				if (r >= 0 && r < mKey.Size() && mSelectable[r])
					row = r;
			}
		}

		if (row != mHotRow) { mHotRow = row; mDirty = true; }
	}
}

// ---------------------------------------------------------------------
// WEAPON STATUS -- what this gun is, right now. Read-only.
// ---------------------------------------------------------------------
class RS_BBWeaponStatus : RS_BBScreen
{
	bool mOffhand;

	static RS_BBWeaponStatus Open(PlayerPawn pawn, bool offhand)
	{
		let s = new("RS_BBWeaponStatus");
		s.mOffhand = offhand;
		s.Build(pawn);
		if (s.mKey.Size() == 0) return null;
		s.Raise();
		return s;
	}

	RS_Weapon Gun(PlayerPawn pawn) const
	{
		if (!pawn || !pawn.player) return null;
		return RS_Weapon(mOffhand ? pawn.player.OffhandWeapon
		                          : pawn.player.ReadyWeapon);
	}

	override void Build(PlayerPawn pawn)
	{
		ClearRows();
		let w = Gun(pawn);
		if (!w) return;

		mTitle = (mOffhand ? "OFFHAND -- " : "MAINHAND -- ") .. w.GetTag();
		mTitleColor = RS_UIStyle.TierColor(w.Tier);

		AddRow("TIER", RS_UIStyle.TierName(w.Tier), RS_UIStyle.TierColor(w.Tier));
		// Cursed stats read ??? here too -- the sheet and the in-world
		// screen must not disagree about what the player is allowed to
		// know, or one of them gives the game away.
		AddRow("DAMAGE", w.LockedDamage ? "???" : string.format("%d", w.DamagePerShot),
			w.LockedDamage ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("ACCURACY", w.LockedAccuracy ? "???" : string.format("%d", int(w.Accuracy)),
			w.LockedAccuracy ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("CRIT", w.LockedCritChance ? "???" : string.format("%.1f%%", w.CritChance * 100.0),
			w.LockedCritChance ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("CONDITION", string.format("%d%%", int(w.Condition)),
			RS_UIStyle.ConditionColor(w.Condition));
		AddRow("MAGAZINE", w.LockedCapacity ? "???" : string.format("%d", w.Capacity),
			w.LockedCapacity ? Font.CR_DARKRED : Font.CR_TAN);
		AddRow("SOCKETS", string.format("%d", w.GunBonaiSockets), Font.CR_TAN);
		AddRow("PROMOTIONS", RS_UIStyle.Pips(w.PromotionCount), Font.CR_GOLD);
	}
}

// ---------------------------------------------------------------------
// CARD PICKER -- the level-up offer, in the world.
//
// Reads the live candidate list off the GunBonsai giver, and picking
// calls the same Choose(), so this and the flat menu stay in sync and
// neither becomes the "real" one.
// ---------------------------------------------------------------------
class RS_BBCardPicker : RS_BBScreen
{
	static RS_BBCardPicker Open(PlayerPawn pawn)
	{
		if (!pawn) return null;
		let s = new("RS_BBCardPicker");
		s.Build(pawn);
		if (s.mKey.Size() == 0) return null;
		s.Raise();
		return s;
	}

	static TFLV_UpgradeGiver GiverFor(PlayerPawn pawn)
	{
		if (!pawn) return null;
		// GetStatsFor, not the console-player helper: that one is ui
		// scope and this is play.
		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		return stats ? TFLV_UpgradeGiver(stats.currentEffectGiver) : null;
	}

	override void Build(PlayerPawn pawn)
	{
		ClearRows();
		let giver = GiverFor(pawn);
		if (!giver || giver.candidates.Size() == 0) return;

		mTitle = "LEVEL UP";
		mTitleColor = Font.CR_GOLD;

		for (int i = 0; i < giver.candidates.Size(); i++)
		{
			let u = giver.candidates[i];
			AddRow(u.GetName(), "", Font.CR_WHITE, true);
		}
	}

	override void Confirm(PlayerPawn pawn)
	{
		if (!mAlive || mHotRow < 0) return;
		let giver = GiverFor(pawn);
		if (!giver || mHotRow >= giver.candidates.Size()) { Close(); return; }

		giver.Choose(mHotRow);
		Close();
	}
}

// =====================================================================
// RS_BBUIHandler -- owns the live screen, drives it, and paints it.
//
// MUST be listed in MAPINFO.txt's AddEventHandlers. A handler class not
// named there compiles fine and silently never runs; a name there with
// no class is a hard crash at map load.
// =====================================================================
class RS_BBUIHandler : EventHandler
{
	RS_BBScreen mScreen;
	bool mOffhandAim;

	override void WorldTick()
	{
		if (!mScreen || !mScreen.mAlive) return;
		let pawn = PlayerPawn(players[consoleplayer].mo);
		if (!pawn) { CloseScreen(); return; }
		mScreen.UpdateAim(pawn, mOffhandAim);
	}

	void CloseScreen()
	{
		if (mScreen) mScreen.Close();
		mScreen = null;
	}

	override void WorldUnloaded(WorldEvent e)
	{
		// Billboard handles are not actors and nothing else collects them.
		CloseScreen();
	}

	// -----------------------------------------------------------------
	// THE PAINTER. ui scope -- TexMan.GetCanvas and Canvas.DrawText are
	// ui-only, which is why this cannot live beside the row data.
	//
	// Repaints only when play marks the model dirty, so a screen that is
	// simply sitting there costs nothing per frame.
	// -----------------------------------------------------------------
	override void RenderOverlay(RenderEvent e)
	{
		if (!mScreen || !mScreen.mAlive || !mScreen.mDirty) return;

		let cv = TexMan.GetCanvas("RSCARDA");
		if (!cv) return;
		mScreen.mDirty = false;

		int W = RS_BBScreen.CV_W, H = RS_BBScreen.CV_H;
		int P = RS_BBScreen.PAD;

		cv.Clear(0, 0, W, H, Color(235, 16, 14, 20));
		cv.DrawLineFrame(Color(255, 106, 88, 54), 2, 2, W - 4, H - 4);
		cv.DrawLineFrame(Color(255, 58, 46, 30), 5, 5, W - 10, H - 10);

		cv.DrawText(BigFont, mScreen.mTitleColor, P, 16, mScreen.mTitle);
		cv.Clear(P, 62, W - P, 63, Color(255, 74, 64, 56));

		int y = RS_BBScreen.ROWS_TOP;
		for (int i = 0; i < mScreen.mKey.Size(); i++)
		{
			// The highlight is drawn UNDER the row, so a selected card
			// reads without changing its text colour -- which matters
			// because the colour is carrying tier information.
			if (i == mScreen.mHotRow)
				cv.Clear(P - 5, y - 3, W - P + 5, y + RS_BBScreen.ROW_PITCH - 6,
					Color(255, 52, 46, 28));

			cv.DrawText(SmallFont, mScreen.mColor[i], P, y, mScreen.mKey[i]);

			string v = mScreen.mVal[i];
			if (v.Length())
				cv.DrawText(SmallFont, mScreen.mColor[i],
					W - P - SmallFont.StringWidth(v), y, v);

			y += RS_BBScreen.ROW_PITCH;
		}
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		let pawn = PlayerPawn(players[e.Player].mo);
		if (!pawn) return;

		if (e.Name == "rs-bb-status" || e.Name == "rs-bb-status-off")
		{
			bool off = (e.Name == "rs-bb-status-off");
			// Same hand again = toggle off.
			if (mScreen && (mScreen is "RS_BBWeaponStatus") && mOffhandAim == off)
			{
				CloseScreen();
				return;
			}
			CloseScreen();
			mOffhandAim = off;
			mScreen = RS_BBWeaponStatus.Open(pawn, off);
		}
		else if (e.Name == "rs-bb-cards")
		{
			CloseScreen();
			mOffhandAim = false;
			mScreen = RS_BBCardPicker.Open(pawn);
		}
		else if (e.Name == "rs-bb-confirm")
		{
			if (mScreen) mScreen.Confirm(pawn);
			if (mScreen && !mScreen.mAlive) mScreen = null;
		}
		else if (e.Name == "rs-bb-close")
		{
			CloseScreen();
		}
	}
}
