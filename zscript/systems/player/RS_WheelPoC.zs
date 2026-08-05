// =====================================================================
// RS_WheelPoC -- twin weapon wheel, PROOF OF CONCEPT. Disposable by
// design: this file, one include line, one MAPINFO handler name, one
// KEYCONF block. Delete all four and it never existed.
//
// What it does: hold the bind and each hand grows a ring of your owned
// weapons -- miniature display actors orbiting OffhandPos (left) and
// AttackPos (right), the VR controller positions the engine already
// exports (flat play falls back to two anchors ahead of you). Left
// stick picks on the left ring, right stick on the right ring; when a
// stick is idle, that hand's aim direction picks instead. Release the
// bind and both hands equip their selections.
//
// INPUT CAPTURE (the part the affix screens will reuse): while open,
// raw stick state is read from original_cmd and then cmd is ZEROED in
// WorldTick -- WorldTick runs before player thinkers, so the engine
// never sees the input. No angle-restore hacks. VR turn that bypasses
// cmd is silenced by the vr_snapTurn=360 guard: above 10 that cvar is
// an edge-triggered snap angle, and a 360-degree snap is a null turn.
// Saved and restored on close, level load, AND level unload, so a
// crash mid-wheel can't mangle the user's comfort setting.
//
// Hand routing on select: the engine assigns a selected weapon to the
// offhand iff the INSTANCE's bOffhandWeapon flag is set when it becomes
// PendingWeapon (BringUpWeapon routes on it). One PendingWeapon exists,
// so when both hands change in one release the offhand applies first
// and the mainhand follows a few tics later.
// =====================================================================
class RS_WheelHandler : EventHandler
{
	const RING_RADIUS = 26;
	const CURSOR_MAX = 80;
	const DEADZONE = 30;

	bool mOpen;
	Array<class<Weapon> > mListL;
	Array<class<Weapon> > mListR;
	Array<Actor> mRingL;
	Array<Actor> mRingR;
	int mSelL, mSelR;
	Vector2 mCurL, mCurR;

	double mSavedSnap;
	bool mSnapChanged;

	class<Weapon> mDeferredMain;
	int mDeferredTics;

	// -----------------------------------------------------------------
	override void NetworkProcess(ConsoleEvent evt)
	{
		if (evt.player < 0) return;
		if (evt.name == "rs-wheel-on")  OpenWheel(evt.player);
		if (evt.name == "rs-wheel-off") CloseWheel(evt.player, true);
	}

	void OpenWheel(int pnum)
	{
		if (mOpen) return;
		PlayerPawn pawn = players[pnum].mo;
		if (!pawn) return;

		mListL.Clear(); mListR.Clear();
		for (Inventory item = pawn.Inv; item; item = item.Inv)
		{
			let w = Weapon(item);
			if (!w) continue;
			mListL.Push((class<Weapon>)(w.GetClass()));
			mListR.Push((class<Weapon>)(w.GetClass()));
		}
		if (mListL.Size() == 0) return;

		// Preselect what's already in each hand.
		mSelL = 0; mSelR = 0;
		let offW = players[pnum].OffhandWeapon;
		let mainW = players[pnum].ReadyWeapon;
		for (int i = 0; i < mListL.Size(); i++)
		{
			if (offW && mListL[i] == offW.GetClass()) mSelL = i;
			if (mainW && mListR[i] == mainW.GetClass()) mSelR = i;
		}
		mCurL = SectorCenter(mSelL, mListL.Size()) * 50;
		mCurR = SectorCenter(mSelR, mListR.Size()) * 50;

		for (int i = 0; i < mListL.Size(); i++)
			mRingL.Push(SpawnIcon(mListL[i], RingPos(pawn, 0, i, mListL.Size())));
		for (int i = 0; i < mListR.Size(); i++)
			mRingR.Push(SpawnIcon(mListR[i], RingPos(pawn, 1, i, mListR.Size())));

		// VR turn silencer -- see file header.
		let sc = CVar.FindCVar("vr_snapTurn");
		if (sc)
		{
			mSavedSnap = sc.GetFloat();
			sc.SetFloat(360);
			mSnapChanged = true;
		}

		mOpen = true;
		pawn.A_StartSound("menu/activate");
	}

	Actor SpawnIcon(class<Weapon> cls, Vector3 spot)
	{
		let icon = Actor.Spawn(cls, spot);
		if (icon)
		{
			icon.bSpecial = false;
			icon.bNoGravity = true;
			icon.bNoInteraction = true;
			icon.A_ChangeLinkFlags(1);   // bNoBlockmap is not directly assignable
			icon.Scale = GetDefaultByType(cls).Scale * 0.3;
		}
		return icon;
	}

	void CloseWheel(int pnum, bool apply)
	{
		if (!mOpen) return;
		mOpen = false;

		for (int i = 0; i < mRingL.Size(); i++) if (mRingL[i]) mRingL[i].Destroy();
		for (int i = 0; i < mRingR.Size(); i++) if (mRingR[i]) mRingR[i].Destroy();
		mRingL.Clear(); mRingR.Clear();

		RestoreSnap();

		PlayerPawn pawn = players[pnum].mo;
		if (!apply || !pawn) return;

		bool switchedOff = false;
		if (mSelL < mListL.Size())
		{
			let cls = mListL[mSelL];
			let cur = players[pnum].OffhandWeapon;
			if (!cur || cur.GetClass() != cls)
			{
				let w = Weapon(pawn.FindInventory(cls));
				if (w)
				{
					w.bOffhandWeapon = true;
					pawn.A_SelectWeapon(cls);
					switchedOff = true;
				}
			}
		}
		if (mSelR < mListR.Size())
		{
			let cls = mListR[mSelR];
			let cur = players[pnum].ReadyWeapon;
			bool sameAsOffPick = switchedOff && mSelL < mListL.Size() && cls == mListL[mSelL];
			if ((!cur || cur.GetClass() != cls) && !sameAsOffPick)
			{
				if (switchedOff)
				{
					// One PendingWeapon slot: let the offhand switch land,
					// then bring the mainhand up behind it.
					mDeferredMain = cls;
					mDeferredTics = 12;
				}
				else
				{
					let w = Weapon(pawn.FindInventory(cls));
					if (w)
					{
						w.bOffhandWeapon = false;
						pawn.A_SelectWeapon(cls);
					}
				}
			}
		}
		pawn.A_StartSound("menu/choose");
	}

	void RestoreSnap()
	{
		if (!mSnapChanged) return;
		let sc = CVar.FindCVar("vr_snapTurn");
		if (sc) sc.SetFloat(mSavedSnap);
		mSnapChanged = false;
	}

	// -----------------------------------------------------------------
	// Geometry. Ring lives in the camera-facing vertical plane around
	// the hand anchor; entry 0 sits at the top, then clockwise.
	// -----------------------------------------------------------------
	Vector3 Anchor(PlayerPawn pawn, int hand)
	{
		Vector3 hp = hand == 0 ? pawn.OffhandPos : pawn.AttackPos;
		if ((hp - pawn.pos).Length() > 4) return hp;
		// Flat-screen fallback: two anchors ahead, chest height.
		return pawn.Vec3Angle(56, pawn.angle + (hand == 0 ? 18 : -18), 40);
	}

	Vector2 SectorCenter(int i, int n)
	{
		double phi = 90 - i * (360.0 / max(1, n));
		return (cos(phi), sin(phi));
	}

	Vector3 RingPos(PlayerPawn pawn, int hand, int i, int n)
	{
		Vector3 anchor = Anchor(pawn, hand);
		double a = pawn.angle;
		Vector3 rightv = (sin(a), -cos(a), 0);
		double phi = 90 - i * (360.0 / max(1, n));
		return anchor + rightv * (cos(phi) * RING_RADIUS) + (0, 0, sin(phi) * RING_RADIUS);
	}

	int PickSelection(PlayerPawn pawn, int hand, int n, Vector2 cursor, int current)
	{
		if (n <= 0) return 0;

		if (cursor.Length() > DEADZONE)
		{
			double phic = atan2(cursor.y, cursor.x);
			double halfStep = 180.0 / n;
			for (int i = 0; i < n; i++)
			{
				double phii = 90 - i * (360.0 / n);
				if (abs(Actor.DeltaAngle(phic, phii)) <= halfStep) return i;
			}
			return current;
		}

		// Stick idle: that hand's aim ray picks instead (VR path).
		double ha = hand == 0 ? pawn.OffhandAngle : pawn.AttackAngle;
		double hp = hand == 0 ? pawn.OffhandPitch : pawn.AttackPitch;
		Vector3 aim = (cos(ha) * cos(hp), sin(ha) * cos(hp), -sin(hp));
		Vector3 origin = Anchor(pawn, hand);
		int best = current;
		double bestDot = 0.85;   // don't steal selection on a slack wrist
		for (int i = 0; i < n; i++)
		{
			Vector3 toEntry = RingPos(pawn, hand, i, n) - origin;
			if (toEntry.Length() < 1) continue;
			double d = aim dot toEntry.Unit();
			if (d > bestDot) { bestDot = d; best = i; }
		}
		return best;
	}

	// -----------------------------------------------------------------
	override void WorldTick()
	{
		// Deferred mainhand switch runs even after the wheel closed.
		if (mDeferredMain != null && --mDeferredTics <= 0)
		{
			PlayerPawn pawn = players[consoleplayer].mo;
			if (pawn)
			{
				let w = Weapon(pawn.FindInventory(mDeferredMain));
				if (w)
				{
					w.bOffhandWeapon = false;
					pawn.A_SelectWeapon(mDeferredMain);
				}
			}
			mDeferredMain = null;
		}

		if (!mOpen) return;
		let p = players[consoleplayer];
		PlayerPawn pawn = p.mo;
		if (!pawn) { CloseWheel(consoleplayer, false); return; }

		// Read the raw sticks, then eat the input before the engine
		// spends it -- WorldTick runs ahead of the player thinker.
		mCurL.x += p.original_cmd.sidemove / 1280.0;
		mCurL.y += p.original_cmd.forwardmove / 1280.0;
		mCurR.x -= p.original_cmd.yaw * (360.0 / 65536.0) * 1.2;
		mCurR.y -= p.original_cmd.pitch * (360.0 / 65536.0) * 1.6;
		if (mCurL.Length() > CURSOR_MAX) mCurL = mCurL.Unit() * CURSOR_MAX;
		if (mCurR.Length() > CURSOR_MAX) mCurR = mCurR.Unit() * CURSOR_MAX;

		int oldL = mSelL, oldR = mSelR;
		mSelL = PickSelection(pawn, 0, mListL.Size(), mCurL, mSelL);
		mSelR = PickSelection(pawn, 1, mListR.Size(), mCurR, mSelR);
		if (mSelL != oldL || mSelR != oldR)
			pawn.A_StartSound("menu/change");

		PositionRing(pawn, 0);
		PositionRing(pawn, 1);

		p.cmd.forwardmove = 0;
		p.cmd.sidemove = 0;
		p.cmd.yaw = 0;
		p.cmd.pitch = 0;
		p.cmd.buttons &= ~(BT_ATTACK | BT_ALTATTACK | BT_OFFHANDATTACK | BT_OFFHANDALTATTACK);
	}

	void PositionRing(PlayerPawn pawn, int hand)
	{
		int n = hand == 0 ? mRingL.Size() : mRingR.Size();
		int sel = hand == 0 ? mSelL : mSelR;
		for (int i = 0; i < n; i++)
		{
			let icon = hand == 0 ? mRingL[i] : mRingR[i];
			if (!icon) continue;
			icon.SetOrigin(RingPos(pawn, hand, i, n), true);
			bool isSel = i == sel;
			let cls = hand == 0 ? mListL[i] : mListR[i];
			icon.Scale = GetDefaultByType(cls).Scale * (isSel ? 0.55 : 0.3);
			if (isSel)
				icon.angle = (level.time * 8) % 360;   // the pick turns
			else
				icon.angle = atan2(pawn.pos.y - icon.pos.y, pawn.pos.x - icon.pos.x);
		}
	}

	// -----------------------------------------------------------------
	override void RenderOverlay(RenderEvent e)
	{
		if (!mOpen) return;
		if (mSelL >= mListL.Size() || mSelR >= mListR.Size()) return;
		int w = Screen.GetWidth();
		int h = Screen.GetHeight();
		Screen.DrawText(smallfont, Font.CR_ORANGE,
			w * 0.25 - 40, h * 0.80, "OFFHAND: " .. mListL[mSelL].GetClassName() .. "");
		Screen.DrawText(smallfont, Font.CR_GOLD,
			w * 0.75 - 40, h * 0.80, "MAINHAND: " .. mListR[mSelR].GetClassName() .. "");
	}

	// -----------------------------------------------------------------
	// A save mid-wheel or a level change must never leak ring actors or
	// the user's real snap-turn setting.
	override void WorldLoaded(WorldEvent e)
	{
		if (mOpen || mSnapChanged)
		{
			mOpen = false;
			for (int i = 0; i < mRingL.Size(); i++) if (mRingL[i]) mRingL[i].Destroy();
			for (int i = 0; i < mRingR.Size(); i++) if (mRingR[i]) mRingR[i].Destroy();
			mRingL.Clear(); mRingR.Clear();
			RestoreSnap();
		}
	}

	override void WorldUnloaded(WorldEvent e)
	{
		RestoreSnap();
	}
}
