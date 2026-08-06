// =====================================================================
// RS_PanelCard -- the row model and the painter for one panel face.
//
// WHY THIS IS NOT RS_UIHandler's card model. That model is
// (key, value, colour) and nothing else -- three parallel arrays, no
// command channel. It cannot express "pointing at this row does
// something", which is the whole point of an in-world panel. The menu
// model next to it DOES have cmd/arg but is built for a flat list.
// This is the union: the card's three fields plus the menu's two, so
// one model feeds both the canvas and the aim ray.
//
// It is a separate file on purpose. rs_ui.zs is under active edit by
// another session; growing its models from here would collide.
//
// COLOUR DOCTRINE. Rows carry a Font.CR_* constant and the painter does
// not second-guess it. The tier ramp, condition bands and pips all come
// from RS_UIStyle, which is the single source for that vocabulary --
// this file introduces no colour of its own beyond the panel chrome.
// =====================================================================

class RS_PanelCard
{
	// Canvas geometry. 320x640 is a 1:2 portrait -- taller than the old
	// 256x384 card because the drop comparison wants every row it can
	// get, and a panel you lean toward can carry far more than one
	// pinned to your face.
	const CARD_W      = 320;
	const CARD_H      = 640;
	const PAD         = 16;    // uniform inner padding
	const TITLE_Y     = 16;
	const SUB_Y       = 48;
	const RULE_Y      = 70;
	const FIRST_ROW_Y = 84;

	// Row pitch is a cvar, not a constant -- see RS_PanelController's
	// typography block for why legibility here has to be the player's
	// call. Both the painter and RowAtUV read THIS, so the hit test can
	// never drift from what was drawn.
	static int Pitch()
	{
		return RS_PanelController.RowPitch();
	}

	// Rows that fit below the header before the card overflows. The
	// painter CLIPS at this rather than drawing past the bottom edge --
	// the old canvas painter had no overflow guard at all and an
	// 18-row triptych would have silently drawn into nothing.
	const MAX_ROWS    = 30;

	string  mCanvas;

	string  mTitle,  mSub;
	int     mTitleColor, mSubColor;

	Array<string> mKey;
	Array<string> mVal;
	Array<int>    mColor;
	Array<string> mCmd;    // "" = inert text row
	Array<int>    mArg;

	bool    mDirty;        // repaint requested

	static RS_PanelCard Create(string canvasName)
	{
		let c = new("RS_PanelCard");
		c.mCanvas     = canvasName;
		c.mTitleColor = Font.CR_GOLD;
		c.mSubColor   = Font.CR_WHITE;
		c.mDirty      = true;
		return c;
	}

	void Clear()
	{
		mTitle = ""; mSub = "";
		mTitleColor = Font.CR_GOLD;
		mSubColor   = Font.CR_WHITE;
		mKey.Clear(); mVal.Clear(); mColor.Clear();
		mCmd.Clear(); mArg.Clear();
		mDirty = true;
	}

	void SetHeader(string title, int titleColor, string sub, int subColor)
	{
		mTitle = title; mTitleColor = titleColor;
		mSub = sub;     mSubColor = subColor;
		mDirty = true;
	}

	void AddRow(string k, string v, int color, string cmd = "", int arg = 0)
	{
		mKey.Push(k);
		mVal.Push(v);
		mColor.Push(color);
		mCmd.Push(cmd);
		mArg.Push(arg);
		mDirty = true;
	}

	// A horizontal rule. Not a row type -- there is no row-kind tag in
	// this model on purpose, so a rule is just a row whose key is a run
	// of dots. Same convention rs_ui.zs already uses, kept identical so
	// the two renderers cannot drift.
	void AddRule()
	{
		AddRow("..............................", "", Font.CR_DARKGRAY);
	}

	int RowCount() const
	{
		return mKey.Size();
	}

	// -----------------------------------------------------------------
	// Which row does a normalised panel coordinate land on?
	//
	// uv is 0..1 with (0,0) at the panel's TOP-LEFT as the reader sees
	// it. Returns -1 for the header, the rule area, or past the last
	// row. This is the half that makes a panel clickable; it is written
	// now, against the same geometry the painter uses, so the two can
	// never disagree about where a row is.
	// -----------------------------------------------------------------
	int RowAtUV(Vector2 uv) const
	{
		if (uv.x < 0 || uv.x > 1 || uv.y < 0 || uv.y > 1) return -1;

		double py = uv.y * CARD_H;
		if (py < FIRST_ROW_Y) return -1;

		int idx = int((py - FIRST_ROW_Y) / Pitch());
		if (idx < 0 || idx >= mKey.Size() || idx >= MAX_ROWS) return -1;
		return idx;
	}

	bool RowIsSelectable(int i) const
	{
		if (i < 0 || i >= mCmd.Size()) return false;
		return mCmd[i] != "";
	}

	// -----------------------------------------------------------------
	// Paint. UI scope -- the canvas API is a UI-side surface, exactly
	// like RS_UIHandler.RenderOverlay uses it.
	//
	// `hotRow` is the row the aim ray is currently on, or -1. It is
	// drawn in the menu's hot colour so the panel gives the same
	// feedback a flat menu does.
	// -----------------------------------------------------------------
	ui void Paint(int hotRow = -1)
	{
		if (mCanvas == "") return;
		let cv = TexMan.GetCanvas(mCanvas);
		if (!cv) return;

		Font bodyF  = RS_PanelController.BodyFont();
		Font titleF = RS_PanelController.TitleFont();
		int  pitch  = Pitch();

		// Doom-toned chrome: near-black warm brown ground, muted gold
		// double frame. Deliberately the same palette as the existing
		// flat card so the two read as one instrument.
		cv.Clear(0, 0, CARD_W, CARD_H, Color(255, 20, 15, 12));
		cv.DrawLineFrame(Color(255, 106, 88, 54), 2, 2, CARD_W - 4, CARD_H - 4);
		cv.DrawLineFrame(Color(255, 58, 46, 30),  5, 5, CARD_W - 10, CARD_H - 10);

		if (mTitle != "")
			cv.DrawText(titleF, mTitleColor, PAD, TITLE_Y, mTitle);
		if (mSub != "")
			cv.DrawText(bodyF, mSubColor, PAD, SUB_Y, mSub);

		cv.Clear(PAD, RULE_Y, CARD_W - PAD, RULE_Y + 1, Color(255, 74, 64, 56));

		int y = FIRST_ROW_Y;
		int rows = min(mKey.Size(), MAX_ROWS);

		for (int i = 0; i < rows; i++)
		{
			int col = mColor[i];

			// Selection highlight: a filled bar behind the row, not a
			// colour swap, so the row keeps its own semantic colour
			// (green "better", dark red "locked") while still reading
			// as selected. Swapping the colour would destroy the very
			// information the row exists to carry.
			if (i == hotRow)
				cv.Clear(PAD - 4, y - 2, CARD_W - PAD + 4, y + pitch - 4,
				         Color(255, 48, 40, 26));

			cv.DrawText(bodyF, col, PAD, y, mKey[i]);

			if (mVal[i] != "")
			{
				int vx = CARD_W - PAD - bodyF.StringWidth(mVal[i]);
				cv.DrawText(bodyF, col, vx, y, mVal[i]);
			}

			y += pitch;
		}

		// Honest overflow marker. If the data does not fit, say so on
		// the card rather than dropping rows silently.
		if (mKey.Size() > MAX_ROWS)
		{
			cv.DrawText(bodyF, Font.CR_DARKGRAY, PAD, y,
				String.Format("+%d MORE", mKey.Size() - MAX_ROWS));
		}
	}
}
