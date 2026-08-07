// =====================================================================
// RS_RollProbe -- a throwaway instrument for ONE question: what does
// AttackRoll actually do on this machine, in this headset?
//
// WHY THIS EXISTS. The controller-encircling wheel design selects by
// WRIST ROLL, because roll is the one hand axis that does not change
// when the hand MOVES -- walk, lunge, raise your arm, and the twist
// angle is identical. That is what lets a ring be welded to the hand
// and still be selectable, which no amount of position-based selection
// can do (the ring would move with the input).
//
// The whole design therefore rests on AttackRoll/OffhandRoll, and:
//
//   * they are `native readonly double` on Actor (actor.zs:270,274) --
//     verified present;
//   * NOTHING IN THIS MOD HAS EVER READ EITHER ONE. Zero hits across
//     the whole zscript tree.
//
// So the axis the design depends on is completely unexercised, and
// three of the geometry constants are guesses against numbers nobody
// has measured. Rather than write a wheel and discover the input is
// unusable, measure the input first. This file is deliberately
// disposable: delete it, its include line and its MAPINFO name and it
// never existed.
//
// ---------------------------------------------------------------------
// WHAT THE ENGINE DOES TO ROLL BEFORE WE SEE IT -- and why (b) below is
// the question that matters most.
//
// gl_openvr.cpp:1312 computes the value we eventually read as:
//
//     weaponangles[ROLL] = normalizeAngle(-RAD2DEG(eulerAngles.v[2]) + 180.);
//
// then hands it straight through at :2490 as AttackRoll. There is a
// SIGN FLIP and a +180 OFFSET baked in. So a neutral grip almost
// certainly does NOT read zero -- and if it reads near 180, the
// wraparound sits in the MIDDLE of the range your wrist actually
// covers, which would make a naive linear roll->sector mapping jump
// across the ring at the worst possible moment.
//
// (The OpenXR path at gl_openxrdevice.cpp:575 does the same assignment,
// but nothing in this tree fills weaponangles on that path -- only
// gl_openvr.cpp writes it. On a Quest build the Android host layer
// does. That is exactly why this has to be measured where you actually
// play rather than reasoned about.)
//
// ---------------------------------------------------------------------
// THE FOUR QUESTIONS, and how each row answers one:
//
//   (a) SIGN         -- twist clockwise; does the number rise or fall?
//   (b) NEUTRAL      -- hold a normal grip; is it near 0 or near 180?
//   (c) WRAPPING     -- RAW vs DELTA. A wrap shows as a RAW jump near
//                       360 while DELTA stays small. If RAW MAX is ever
//                       huge, roll wraps and every comparison in the
//                       wheel must go through Actor.DeltaAngle.
//   (d) JITTER       -- hold DEAD STILL. The jitter row settles to the
//                       noise floor in degrees. That number sets the
//                       selection hysteresis; guessing it is how you
//                       ship a wheel that chatters at sector edges.
//
// Read it in the headset, not from a log -- it is drawn on the HUD
// because a console you cannot see is no use while wearing one.
// =====================================================================
class RS_RollProbe : EventHandler
{
	// RS_DIAG: temporary, see WorldTick.
	int mDiagCount;

	// Per hand: 0 = offhand, 1 = mainhand.
	double mRoll[2];
	double mPrev[2];
	bool   mHavePrev;

	double mMin[2], mMax[2];
	double mRawMax[2];      // biggest raw |roll - prevRoll| ever seen
	double mDeltaMax[2];    // biggest |DeltaAngle(roll, prevRoll)| ever seen

	// Rolling jitter estimate: the largest per-tic DeltaAngle inside a
	// short window, which is what "hold still and see what it does"
	// actually means. Decays so the reading follows the hand instead of
	// latching on one twitch forever.
	double mJitter[2];

	bool   mTracked;
	bool   mActive;

	override void NetworkProcess(ConsoleEvent evt)
	{
		if (evt.name == "rs-rollprobe")
		{
			mActive = !mActive;
			Reset();
		}
		else if (evt.name == "rs-rollprobe-reset")
		{
			Reset();
		}
	}

	void Reset()
	{
		mHavePrev = false;
		for (int h = 0; h < 2; h++)
		{
			mMin[h] = 99999; mMax[h] = -99999;
			mRawMax[h] = 0; mDeltaMax[h] = 0; mJitter[h] = 0;
		}
	}

	override void WorldTick()
	{
		// RS_DIAG: temporary, unconditional -- RS_RollProbe is LAST in
		// MAPINFO's AddEventHandlers list, so every print here means every
		// registered handler ahead of it got through WorldTick fine on
		// that tic. Capped at 10 so it shows the SEQUENCE (does this keep
		// firing tic after tic, or stop dead after some point) without
		// spamming forever if the game is actually running fine.
		if (mDiagCount < 10)
		{
			mDiagCount++;
			Console.Printf("RS_DIAG: RS_RollProbe.WorldTick #%d", mDiagCount);
		}

		if (!mActive) return;

		PlayerPawn pawn = players[consoleplayer].mo;
		if (!pawn) return;

		mTracked = pawn.OverrideAttackPosDir;

		mRoll[0] = pawn.OffhandRoll;
		mRoll[1] = pawn.AttackRoll;

		for (int h = 0; h < 2; h++)
		{
			double r = mRoll[h];

			if (r < mMin[h]) mMin[h] = r;
			if (r > mMax[h]) mMax[h] = r;

			if (mHavePrev)
			{
				// RAW is the naive subtraction a careless implementation
				// would do. DELTA is the shortest-arc answer. They agree
				// everywhere except across a wrap, which is precisely
				// what makes the pair a wrap detector.
				double raw   = abs(r - mPrev[h]);
				double delta = abs(Actor.DeltaAngle(mPrev[h], r));

				if (raw   > mRawMax[h])   mRawMax[h]   = raw;
				if (delta > mDeltaMax[h]) mDeltaMax[h] = delta;

				// Decay first, then admit this tic's motion, so a held-
				// still hand walks the number down to its noise floor.
				mJitter[h] *= 0.97;
				if (delta > mJitter[h]) mJitter[h] = delta;
			}

			mPrev[h] = r;
		}

		mHavePrev = true;
	}

	override void RenderOverlay(RenderEvent e)
	{
		if (!mActive) return;

		int x = 24;
		int y = int(Screen.GetHeight() * 0.30);
		int step = 20;

		Screen.DrawText(smallfont, Font.CR_GOLD, x, y,
			"ROLL PROBE   tracked=" .. (mTracked ? "YES" : "NO (numbers are meaningless)"));
		y += step * 2;

		for (int h = 0; h < 2; h++)
		{
			string who = (h == 0) ? "OFFHAND " : "MAINHAND";
			int col = (h == 0) ? Font.CR_ORANGE : Font.CR_GREEN;

			Screen.DrawText(smallfont, col, x, y,
				String.Format("%s  roll %8.2f   min %8.2f   max %8.2f",
					who, mRoll[h], mMin[h], mMax[h]));
			y += step;

			Screen.DrawText(smallfont, col, x + 24, y,
				String.Format("raw max %7.2f   delta max %7.2f   jitter %6.3f",
					mRawMax[h], mDeltaMax[h], mJitter[h]));
			y += step + 6;
		}

		y += step;
		Screen.DrawText(smallfont, Font.CR_DARKGRAY, x, y,
			"(a) twist CW: does roll rise or fall?");
		y += step;
		Screen.DrawText(smallfont, Font.CR_DARKGRAY, x, y,
			"(b) normal grip: is roll near 0, or near 180?");
		y += step;
		Screen.DrawText(smallfont, Font.CR_DARKGRAY, x, y,
			"(c) raw max huge but delta max small = IT WRAPS");
		y += step;
		Screen.DrawText(smallfont, Font.CR_DARKGRAY, x, y,
			"(d) hold DEAD STILL: jitter settles to the noise floor");
	}
}
