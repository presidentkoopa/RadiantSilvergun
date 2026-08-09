// =====================================================================
// RS_Slate -- THE PANEL. One in-world screen class for the whole mod.
// ---------------------------------------------------------------------
// Built 2026-08-08 to the owner's spec (docs/rs_state_20260808.md, "THE
// BIG IN-FLIGHT PIECE: the offer panel"). It exists to replace ~20
// scattered entry points across nine UI files with one object, so that
// adding a screen is writing a function that fills a list -- never
// writing panel code again.
//
//   slate.Open("WEAPON STATUS", tier, SLS_Square);
//   slate.Value("DAMAGE", 45);
//   slate.Delta("ACCURACY", 70, 85);
//   slate.Bar("CONDITION", 80);
//   slate.Button("TAKE", "rs-slate-apply", 1);
//   slate.Show(where);
//
// ---------------------------------------------------------------------
// SHAPE SAYS WHAT KIND. COLOUR SAYS HOW GOOD.
//
//   SQUARE  a class weapon is being offered
//   ROUND   an imprint -- a stat package for a gun you already own
//
// and the TIER COLOUR drives the frame, the glow, the heading, the
// meters and the buttons. Not a word in a corner: the owner's ruling is
// that rarity is read, not spelled. The ramp is
// RS_PanelController.TierGlow -- the same one the drop beam and the
// dynamic light already use, so a card and the pillar under it cannot
// disagree about what tier something is.
//
// ---------------------------------------------------------------------
// FIVE REGIONS, SIX ROW TYPES, AND NOTHING ELSE.
//
//   identity   which of the six + rolled tier
//   sprite     the pickup image -- a shotgun from a rifle across a room
//   stats      up to 12, old -> new, coloured by direction
//   marks      what will not fit a number: sockets, affixes, curses
//   actions    touchable
//
//   HEADING VALUE BAR DELTA BUTTON SPRITE
//
// A MARK IS A VALUE ROW IN THE MARKS REGION, not a seventh kind. That
// is the whole point of the constraint: if a screen needs a new row
// type, the screen is wrong. Region and kind are separate fields so
// both rules hold at once.
//
// ---------------------------------------------------------------------
// WHY THIS IS COMPOSED BILLBOARDS AND NOT A PAINTED CANVAS.
//
// A canvas is a hand-declared ANIMDEFS resource. RS ships eleven and the
// drop triptych alone spends nine, and two billboards pointing at one
// canvas show the SAME PICTURE -- so a second card had nowhere to draw.
// A composed panel costs zero textures. All five non-texture payloads
// draw (verified in hw_sprites.cpp:1920-1987 before this file was
// written, not taken on report).
//
// WHAT THE PAYLOADS ACTUALLY DO, read out of the engine rather than out
// of BILLBOARDS.md, because one of them is documented wrong:
//
//   BB_PANEL   rounded plate, stretched to the quad
//   BB_BAR     data 0..100; a dark track plus a fill that grows from
//              the LEFT edge, so only the right end moves
//   BB_GLYPH   data is a raw character code 1..255. NOT id|palette --
//              the engine clamps it to 1..255 and prints that one char
//              (hw_sprites.cpp:1977-1981)
//   BB_DIGITS  data is the integer, printed with %d
//   BB_RING    A PLAIN RING. BILLBOARDS.md calls it a "progress ring"
//              and it is not: the case is one emit of the `bbring`
//              graphic and it ignores `data` entirely
//              (hw_sprites.cpp:1940-1942). It is a shape, so it is what
//              draws the ROUND panel's frame -- and nothing here should
//              ever try to drive a percentage through it.
//
// ---------------------------------------------------------------------
// UNIT-SPACE LAYOUT, WHICH IS WHAT MAKES DISTANCE-DRIVEN SCALE FREE.
//
// RS_BBComposedPanel stores its part offsets in MAP UNITS, so growing a
// card would mean re-laying it out -- destroying and rebuilding two
// hundred billboards for a player who is merely walking toward a drop.
//
// This file stores every offset and every size as a FRACTION of the
// panel's own width and height. Place() multiplies them by the current
// w/h, so continuous scale is three native calls per part per tic and
// no allocation at all. That is the whole reason this is not built on
// RS_BBComposedPanel: the owner asked for size to follow distance
// continuously, and unit space is what buys it.
//
// The one wrinkle unit space has: a glyph must stay square on a
// non-square panel. So the board carries the panel's ASPECT and text
// converts its height into an x-advance through it. Aspect is fixed at
// build time and scale never changes it.
//
// ---------------------------------------------------------------------
// THE HIT TEST IS NOT ARITHMETIC. THE ENGINE ANSWERS IT.
//
// Every earlier panel in this project resolved a press by taking a UV
// off the aim ray and dividing it by a row pitch -- which means the hit
// test and the painter each hold their own idea of where a row is, and
// they drift. That drift is invisible until a button stops working
// where it looks like it works.
//
// Here every part records WHICH ROW it belongs to, and AimBillboard /
// TouchBillboard return the handle they hit. Handle -> row is a lookup,
// not a calculation, so there is nothing to drift. Both natives bound
// the test to the quad's own extents (vmthunks.cpp:3203, :3286), so a
// hit is genuinely on the row.
//
// ONE TRAP, AND IT IS WHY BUTTONS ARE NUDGED FORWARD. TouchBillboard
// keeps the nearest by plane distance with a STRICT test --
// `if (dist >= bestDist) continue;` (vmthunks.cpp:3280) -- so among
// coplanar parts the FIRST one created wins, forever. A full-panel
// backing plate created first would swallow every touch and no button
// would ever be reachable. Interactive parts therefore sit a fraction
// of a unit toward the reader along the face normal, and the chrome
// sits behind: the ordering becomes geometric instead of accidental.
//
// ---------------------------------------------------------------------
// BASIS VECTORS, VERIFIED AGAINST THE ENGINE ON 2026-08-08.
//
//   face  F = ( cos y,  sin y, 0)   panel toward the reader
//   right R = (-sin y,  cos y, 0)   the VIEWER'S right
//   up    U = (-cos y*sin t, -sin y*sin t, cos t)
//
// All three copies in the engine now agree on this -- the renderer
// (hw_sprites.cpp:2126) and both query natives (vmthunks.cpp:3186,
// :3271) were corrected the same day. `bb_flipu` must be OFF; it is a
// workaround for the old wrong basis and turning it on now re-breaks
// every glyph. NOTE that RS_Panel.RightVec() still carries the OLD
// convention -- that is the known-wrong swapped-wings bug in the state
// doc, it belongs to the flatsprite path, and nothing in this file
// touches it.
//
// Constants are QUALIFIED -- LevelLocals.BBF_FIXED, never bare. They
// are declared inside LevelLocals (doombase.zs:541-565) and ZScript
// does not hoist them.
//
// ---------------------------------------------------------------------
// WHAT THIS SUPERSEDES (nothing is deleted -- that is the owner's call)
//
//   RS_PanelCard.zs        the canvas row model + painter
//   RS_BBWeaponCard.zs     the composed weapon card
//   RS_DropTriptych.zs     the three-panel drop comparison
//   RS_BillboardUI.zs      RS_BBWeaponStatus and RS_BBCardPicker
//   RS_Screens.zs          BuildWeaponSheet / BuildWeaponCard /
//                          BuildDropTriptych, as in-world screens
//
// They all still run. The offer's auto-raise is behind a cvar that
// deliberately refuses to arm while the old path is enabled, so the two
// can never both be up -- see OfferAuto().
// =====================================================================

// The six. Nothing else is ever added here: a screen that needs a
// seventh row type is a screen that has been designed wrong.
enum ERS_SlateKind
{
	SLK_Heading = 0,
	SLK_Value,
	SLK_Bar,
	SLK_Delta,
	SLK_Button,
	SLK_Sprite
}

// The five. Region is WHERE a row lands; kind is WHAT it draws. Keeping
// them apart is what lets a mark be a VALUE row without inventing a
// seventh kind for it.
enum ERS_SlateRegion
{
	SLRG_Identity = 0,
	SLRG_Sprite,
	SLRG_Stats,
	SLRG_Marks,
	SLRG_Actions
}

// Shape encodes what is being offered, before a word is read.
enum ERS_SlateShape
{
	SLS_Square = 0,   // a class weapon
	SLS_Round  = 1    // an imprint
}

// Which content set this slate is showing. Rebuild() refills from this,
// so a slate can be rebuilt (a scale step, a compare-hand change) without
// its owner having to be alive to re-describe it.
enum ERS_SlateScreen
{
	SLSC_None = 0,
	SLSC_WeaponStatus,
	SLSC_EliteOffer
}

// =====================================================================
// RS_SlateRow -- one row. Plain data.
//
// `play` because these are created and mutated from play scope and held
// by a play class; an unscoped Object subclass is DATA scope and mixing
// the two across an array boundary is exactly the sort of thing that
// produces a cascade of "static context" errors on this build.
// =====================================================================
class RS_SlateRow play
{
	int       kind;        // ERS_SlateKind
	int       region;      // ERS_SlateRegion

	string    label;       // left side
	string    text;        // right side (VALUE), or the NEW value (DELTA)
	string    prev;        // DELTA: the OLD value

	int       pct;         // BAR: 0..100
	int       dir;         // DELTA: -1 worse, 0 unchanged, +1 better
	bool      unknown;     // cursed -- the value reads "???"

	Color     tint;        // 0 = derive from the slate's tier colour
	bool      hasTint;

	string    cmd;         // BUTTON: the netevent to fire
	int       arg;         // BUTTON: its argument
	int       hand;        // BUTTON: -1 either, 0 offhand, 1 mainhand

	TextureID tex;         // SPRITE
}

// =====================================================================
// RS_SlateBoard -- the billboards, in unit space.
//
// Everything it owns is an integer handle the garbage collector cannot
// see. Every leak this project has found has been exactly that shape, so
// parts are created here, released here, and nowhere else.
// =====================================================================
class RS_SlateBoard play
{
	// Glyph advance as a fraction of glyph height. The engine fits each
	// BB_GLYPH inside the quad it is given, so this is spacing rather
	// than the letter's own width -- proportional spacing needs per-char
	// metrics script cannot reach, and a fixed pitch reads fine for the
	// short all-caps strings a panel uses.
	const GLYPH_PITCH = 0.62;

	private Array<RS_Billboard> mParts;
	private Array<double> mUX, mUY;     // unit offsets from the centre, -0.5..+0.5
	private Array<double> mUW, mUH;     // unit sizes, fractions of w and h
	private Array<double> mUZ;          // push along the face normal, MAP UNITS
	private Array<int>    mRowOf;       // which row this part belongs to, -1 = chrome
	private Array<bool>   mIsPlate;     // a hit target's backing, the part a highlight recolours

	// Panel width / height, so a glyph stays square on a tall panel.
	double mAspect;

	// Last transform Place() was handed, so a stationary panel costs
	// nothing.
	private Vector3 mAt;
	private double  mYaw, mTilt, mW, mH;
	private bool    mPlaced;

	static Vector3 RightOf(double yaw) { return (-sin(yaw), cos(yaw), 0); }
	static Vector3 FaceOf(double yaw)  { return (cos(yaw), sin(yaw), 0); }

	static Vector3 UpOf(double yaw, double tilt)
	{
		double st = sin(tilt), ct = cos(tilt);
		return (-cos(yaw) * st, -sin(yaw) * st, ct);
	}

	bool Empty() const { return mParts.Size() == 0; }
	int  PartCount() const { return mParts.Size(); }

	// Everything goes through here, so no part can exist without knowing
	// where it sits, how big it is relative to the panel, and which row
	// owns it. A part missing any of those could not be re-placed, could
	// not be scaled, and could not be pressed.
	RS_Billboard Add(int payload, int data, Color col,
		double ux, double uy, double uw, double uh,
		double uz = 0, int row = -1, bool plate = false)
	{
		let b = RS_Billboard.Make((0, 0, 0), 1, 1, 0, 0,
			payload, data, col, LevelLocals.BBF_FIXED, 0);
		if (!b) return null;

		mParts.Push(b);
		mUX.Push(ux); mUY.Push(uy);
		mUW.Push(uw); mUH.Push(uh);
		mUZ.Push(uz);
		mRowOf.Push(row);
		mIsPlate.Push(plate);
		mPlaced = false;
		return b;
	}

	// -----------------------------------------------------------------
	// TEXT. One BB_GLYPH per character.
	//
	// A billboard per letter sounds extravagant and is not -- the
	// primitive exists precisely so hundreds can be built without an
	// actor apiece, and a letter is the cheapest thing it draws.
	//
	// h is a fraction of the panel's HEIGHT; the advance is converted
	// through the aspect so a glyph stays square whatever shape the
	// panel is.
	//
	// align: -1 starts at x, 0 centres on it, +1 ends at it.
	// -----------------------------------------------------------------
	void Text(double x, double y, string txt, double h, Color col,
		int align = -1, int row = -1, double uz = 0)
	{
		if (txt.Length() == 0 || h <= 0 || mAspect <= 0) return;

		// Cached as an int, not compared against directly: String.Length()
		// returns UNSIGNED, and `int i < txt.Length()` is the "Comparison
		// between signed and unsigned value" warning that RS_BBCompose.zs
		// carries at its own equivalent line. Harmless, and free to not
		// have.
		int len = txt.Length();

		double pitch = (h * GLYPH_PITCH) / mAspect;
		double width = pitch * len;

		double start = x;
		if (align == 0)     start = x - width * 0.5;
		else if (align > 0) start = x - width;

		for (int i = 0; i < len; i++)
		{
			int ch = txt.ByteAt(i);
			if (ch == 32) continue;          // space: advance, draw nothing
			if (ch < 1 || ch > 255) continue; // the engine clamps; do not feed it junk

			Add(LevelLocals.BB_GLYPH, ch, col,
				start + pitch * (i + 0.5), y, pitch, h, uz, row);
		}
	}

	// -----------------------------------------------------------------
	// Move every part to match a new transform and size. No allocation
	// and no handle churn -- which is what makes continuous scale
	// affordable at tic rate.
	// -----------------------------------------------------------------
	void Place(Vector3 at, double yaw, double tilt, double w, double h)
	{
		if (mPlaced && at == mAt && yaw == mYaw && tilt == mTilt
			&& w == mW && h == mH) return;

		Vector3 r = RightOf(yaw);
		Vector3 u = UpOf(yaw, tilt);
		Vector3 f = FaceOf(yaw);

		for (int i = 0; i < mParts.Size(); i++)
		{
			if (!mParts[i]) continue;
			mParts[i].MoveTo(at + r * (mUX[i] * w) + u * (mUY[i] * h) + f * mUZ[i]);
			mParts[i].Orient(yaw, tilt, LevelLocals.BBF_FIXED);
			mParts[i].Resize(max(0.05, mUW[i] * w), max(0.05, mUH[i] * h));
		}

		mAt = at; mYaw = yaw; mTilt = tilt; mW = w; mH = h;
		mPlaced = true;
	}

	// Which row does a native hit id belong to? A lookup, never a
	// calculation -- see the file header.
	int RowForHandle(int id) const
	{
		if (id == 0) return -1;
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i] && mParts[i].Handle() == id)
				return mRowOf[i];
		return -1;
	}

	bool OwnsHandle(int id) const
	{
		if (id == 0) return false;
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i] && mParts[i].Handle() == id) return true;
		return false;
	}

	// Recolour only a row's BACKING, never its text. The text is
	// carrying meaning -- a direction colour, a curse red -- and
	// swapping it to show selection would destroy the information the
	// row exists to carry.
	void TintPlate(int row, Color c)
	{
		if (row < 0) return;
		for (int i = 0; i < mParts.Size(); i++)
			if (mIsPlate[i] && mRowOf[i] == row && mParts[i])
				mParts[i].SetData(mParts[i].mData, c);
	}

	void SetAlphaAll(double a)
	{
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i]) mParts[i].SetAlpha(a);
	}

	void ReleaseAll()
	{
		for (int i = 0; i < mParts.Size(); i++)
			if (mParts[i]) mParts[i].Release();
		mParts.Clear();
		mUX.Clear(); mUY.Clear();
		mUW.Clear(); mUH.Clear();
		mUZ.Clear();
		mRowOf.Clear();
		mIsPlate.Clear();
		mPlaced = false;
	}
}

// =====================================================================
// RS_Slate -- the panel itself. Model, layout, placement, hit test.
// =====================================================================
class RS_Slate play
{
	// --- the model ----------------------------------------------------
	Array<RS_SlateRow> mRows;

	string mTitle;
	string mSubtitle;
	int    mTier;          // EVR_Tier as a plain int -- EVR_Tier(x) is not a cast
	int    mShape;         // ERS_SlateShape

	// --- what to refill from -----------------------------------------
	int    mScreen;        // ERS_SlateScreen
	int    mHand;          // which hand a status screen is about
	Actor  mSubject;       // the drop an offer belongs to

	// Which hand an offer compares against. Deltas read "what I hold ->
	// what this is", so the answer changes with the hand being pointed
	// at. Only a CHANGE rebuilds; pointing steadily costs nothing.
	int    mCompareHand;

	// --- geometry -----------------------------------------------------
	RS_SlateBoard mBoard;
	Vector3 mAt;
	double  mYaw, mTilt;
	double  mBaseW, mBaseH;    // full size as ASKED FOR, map units
	// The height actually laid out. A ROUND panel is a square envelope,
	// so it is not always mBaseH -- and it is kept separate rather than
	// overwriting mBaseH, or a slate that changed shape would carry the
	// other shape's height forever.
	double  mDrawH;
	double  mScale;            // 0..1, driven by distance to the subject
	bool    mAlive;

	// --- interaction --------------------------------------------------
	int    mHotRow;        // row under a hand, or -1
	int    mHotHand;       // which hand found it, or -1
	double mHotDist;       // distance from that hand to the face

	private int mLastLitRow;

	// =================================================================
	// TASTE DIALS. Every one is a cvar for the same reason the rest of
	// the panel stack's are: a comfortable card size in a headset is a
	// property of the person and the lenses, not of the mod.
	// =================================================================
	static bool Enabled()
	{
		let cv = CVar.FindCVar("rs_slate_enabled");
		return cv ? cv.GetBool() : true;
	}

	static double BaseWidth()
	{
		let cv = CVar.FindCVar("rs_slate_width");
		return cv ? cv.GetFloat() : 22.0;
	}

	static double BaseHeight()
	{
		let cv = CVar.FindCVar("rs_slate_height");
		return cv ? cv.GetFloat() : 30.0;
	}

	// The near end of the ramp: at or inside this, the panel is full
	// size and its buttons are live.
	static double NearDist()
	{
		let cv = CVar.FindCVar("rs_slate_near");
		return cv ? cv.GetFloat() : 160.0;
	}

	// The far end: at or beyond this the panel is not raised at all.
	// Past here the drop reads as a pillar and a marker, which is the
	// floor-visual lane's half of the same design and not this file's.
	static double FarDist()
	{
		let cv = CVar.FindCVar("rs_slate_far");
		return cv ? cv.GetFloat() : 640.0;
	}

	static double MinScale()
	{
		let cv = CVar.FindCVar("rs_slate_minscale");
		return cv ? clamp(cv.GetFloat(), 0.05, 1.0) : 0.35;
	}

	static bool GlowEnabled()
	{
		let cv = CVar.FindCVar("rs_slate_glow");
		return !cv || cv.GetBool();
	}

	// Gold per tier step when an offer is refused. The table below turns
	// it into a real price -- refusing a Prototype pays far more than
	// refusing a Common, which is the owner's ruling that recycling
	// "pays more for higher tiers refused".
	static int RecycleUnit()
	{
		let cv = CVar.FindCVar("rs_slate_recycle");
		return cv ? max(0, cv.GetInt()) : 5;
	}

	// -----------------------------------------------------------------
	// THE AUTO-RAISE GATE, AND WHY IT IS A CONJUNCTION.
	//
	// The offer slate replaces RS_DropTriptych. Both watch the same
	// drops, so if both were armed a player would get two cards at once
	// and each would think it owned the take. Deleting the triptych is
	// the owner's approval to give, not this session's, so instead the
	// new path refuses to arm while the old one is enabled.
	//
	// Turn rs_panel_enabled OFF and rs_slate_offer ON and the new offer
	// takes over completely. Nothing is lost by doing so: the slate's
	// touch route is its own (TouchBillboard, this file), and the MOUSE3
	// keybind reaches it through the existing rs-panel-use netevent.
	// -----------------------------------------------------------------
	static bool OfferAuto()
	{
		let cv = CVar.FindCVar("rs_slate_offer");
		if (!cv || !cv.GetBool()) return false;
		return !RS_PanelController.Enabled();
	}

	// =================================================================
	// THE COLOUR VOCABULARY. One ramp, one source.
	// =================================================================
	static Color TierTint(int tier)
	{
		return RS_PanelController.TierGlow(tier);
	}

	// Scale a colour toward black. Used for the plate behind a tier
	// frame, the dim half of a delta, and a bar's own track.
	static Color Shade(Color c, double f)
	{
		f = clamp(f, 0.0, 1.0);
		return Color(c.a, int(c.r * f), int(c.g * f), int(c.b * f));
	}

	// Lift a colour toward white, for the highlight under a pressed
	// button. Brighter rather than a different hue, so the button keeps
	// saying what tier it belongs to while it is lit.
	static Color Lift(Color c, double f)
	{
		f = clamp(f, 0.0, 1.0);
		return Color(c.a,
			int(c.r + (255 - c.r) * f),
			int(c.g + (255 - c.g) * f),
			int(c.b + (255 - c.b) * f));
	}

	// Direction colour for a DELTA. Green up, red down, grey flat --
	// and NOT the tier ramp, deliberately: a delta is answering "is this
	// better", which is a different question from "how rare is this",
	// and colouring both off one ramp would make one of them unreadable.
	static Color DirTint(int dir)
	{
		if (dir > 0) return Color(255,  90, 224, 110);
		if (dir < 0) return Color(255, 228,  84,  70);
		return Color(255, 150, 150, 150);
	}

	// A cursed stat. Same dark red the sheets already use for ???.
	static Color CurseTint() { return Color(255, 190, 60, 60); }

	// What refusing an offer of this tier pays. The shape is the point:
	// the top of the ladder is worth several times the bottom, so
	// turning down a Prototype is a real decision and turning down a
	// Trash is not a windfall.
	static int RecycleValue(int tier)
	{
		int unit = RecycleUnit();
		switch (tier)
		{
			case VRT_Cursed:    return unit;
			case VRT_Trash:     return unit;
			case VRT_Basic:     return unit;
			case VRT_Common:    return unit * 2;
			case VRT_Uncommon:  return unit * 3;
			case VRT_Advanced:  return unit * 5;
			case VRT_Designer:  return unit * 8;
			case VRT_Prototype: return unit * 12;
		}
		return unit;
	}

	// Sockets a tier grants. The weapon's own GunBonaiSockets is always
	// preferred where there is an instance to ask; this is for the case
	// where a slate is describing a tier rather than an object.
	//
	// A switch, not a static array literal: `static const TYPE n[] =
	// {...}` does not reliably resolve on this build and has produced a
	// bogus "Unknown identifier" three separate times in this tree.
	static int SocketsForTier(int tier)
	{
		switch (tier)
		{
			case VRT_Common:    return 1;
			case VRT_Uncommon:  return 2;
			case VRT_Advanced:  return 3;
			case VRT_Designer:  return 4;
			case VRT_Prototype: return 5;
		}
		return 0;   // Cursed, Trash, Basic
	}

	// =================================================================
	// THE API. Ten content sets become ten short functions that fill a
	// list; no screen ever writes panel code again.
	// =================================================================

	static RS_Slate Create()
	{
		let s = new("RS_Slate");
		s.mBoard  = new("RS_SlateBoard");
		s.mTier   = VRT_Common;
		s.mShape  = SLS_Square;
		s.mScale  = 1.0;
		s.mHotRow = -1;
		s.mHotHand = -1;
		s.mLastLitRow = -1;
		s.mCompareHand = 1;
		s.mBaseW = BaseWidth();
		s.mBaseH = BaseHeight();
		s.mDrawH = s.mBaseH;
		return s;
	}

	// Start a screen. Clears whatever was there and writes the identity
	// region. Everything after this is content.
	void Open(string title, int tier = VRT_Common, int shape = SLS_Square,
		string subtitle = "")
	{
		mRows.Clear();
		mTitle    = title;
		mSubtitle = subtitle;
		mTier     = tier;
		mShape    = shape;
		mHotRow   = -1;
		mLastLitRow = -1;
	}

	private RS_SlateRow NewRow(int kind, int region)
	{
		let r = new("RS_SlateRow");
		r.kind   = kind;
		r.region = region;
		r.dir    = 0;
		r.hand   = -1;
		r.arg    = 0;
		mRows.Push(r);
		return r;
	}

	// A band label inside the stats region.
	void Heading(string label)
	{
		let r = NewRow(SLK_Heading, SLRG_Stats);
		r.label = label;
	}

	// label ......... 45
	void Value(string label, int v)
	{
		ValueText(label, String.Format("%d", v));
	}

	void ValueText(string label, string v, Color tint = 0, bool tinted = false)
	{
		let r = NewRow(SLK_Value, SLRG_Stats);
		r.label   = label;
		r.text    = v;
		r.tint    = tint;
		r.hasTint = tinted;
	}

	// A stat the player is not allowed to know yet. Cursed stats read
	// ??? -- the number is what the gold is buying, so showing it would
	// let the player simply never pay.
	void Unknown(string label)
	{
		let r = NewRow(SLK_Value, SLRG_Stats);
		r.label   = label;
		r.text    = "???";
		r.unknown = true;
	}

	// old -> new, coloured by direction. The comparison IS the verdict;
	// there is no score line, because a win-count would weight ACCURACY
	// the same as PELLETS and that is false.
	void Delta(string label, double oldV, double newV, int decimals = 0)
	{
		let r = NewRow(SLK_Delta, SLRG_Stats);
		r.label = label;
		r.prev  = Num(oldV, decimals);
		r.text  = Num(newV, decimals);
		if (newV > oldV)      r.dir =  1;
		else if (newV < oldV) r.dir = -1;
		else                  r.dir =  0;
	}

	// A delta against a hand that is holding nothing. "--", never "0" --
	// an empty hand and a weapon that scores zero are different facts,
	// and the direction is unambiguously an improvement.
	void DeltaFromEmpty(string label, double newV, int decimals = 0)
	{
		let r = NewRow(SLK_Delta, SLRG_Stats);
		r.label = label;
		r.prev  = "--";
		r.text  = Num(newV, decimals);
		r.dir   = 1;
	}

	// Spelled out rather than a star-precision "%.*f": ZScript's
	// String.Format supports a subset of printf and star precision is
	// not part of it.
	static string Num(double v, int decimals)
	{
		if (decimals >= 2) return String.Format("%.2f", v);
		if (decimals == 1) return String.Format("%.1f", v);
		return String.Format("%d", int(v));
	}

	// A meter. The one row type that answers "is this about to fail" at
	// a glance, where a number has to be read.
	void Bar(string label, int pct, Color tint = 0, bool tinted = false)
	{
		let r = NewRow(SLK_Bar, SLRG_Stats);
		r.label   = label;
		r.pct     = clamp(pct, 0, 100);
		r.tint    = tint;
		r.hasTint = tinted;
	}

	// The pickup image -- a SPRITE row. Tells a shotgun from a rifle
	// across a room, which is the whole job of the sprite region.
	//
	// Named Picture() rather than Sprite() on purpose: `sprite` is a
	// native Actor field name, and this codebase has already lost a boot
	// to a method name colliding with something the compiler wanted for
	// itself. RS_BBCompose.Picture is the proven spelling; matching it
	// costs nothing and removes a question nobody can answer without a
	// build.
	void Picture(TextureID tex)
	{
		if (!tex.IsValid()) return;
		let r = NewRow(SLK_Sprite, SLRG_Sprite);
		r.tex = tex;
	}

	// A MARK. Sockets, affixes, curses -- the things that will not fit a
	// number. A VALUE row in the marks region, not a seventh row type.
	void Mark(string text, Color tint = 0, bool tinted = false)
	{
		let r = NewRow(SLK_Value, SLRG_Marks);
		r.label   = text;
		r.tint    = tint;
		r.hasTint = tinted;
	}

	// A touchable action. `hand` is which hand the action WANTS: 0
	// offhand, 1 mainhand, -1 either -- in which case the hand that
	// presses is the hand that acts, which is the Hand Law expressed as
	// geometry rather than as a rule to memorise.
	void Button(string label, string cmd, int hand = -1, int arg = 0)
	{
		let r = NewRow(SLK_Button, SLRG_Actions);
		r.label = label;
		r.cmd   = cmd;
		r.hand  = hand;
		r.arg   = (hand >= 0) ? hand : arg;
	}

	// -----------------------------------------------------------------
	// SHOW. Raise the panel at a world spot, or riding a subject.
	//
	// Show(where) pins it. ShowOn(actor) is the offer case: the card
	// belongs to the READER, not to the thing it describes, so it holds
	// a comfortable distance in front of you on the line toward the
	// subject and grows as you approach. Walking up to a drop must not
	// shove a card into your face.
	// -----------------------------------------------------------------
	void Show(Vector3 where)
	{
		mSubject = null;
		mAt      = where;
		mAlive   = true;
		Rebuild();
		Register();
	}

	void ShowOn(Actor subject)
	{
		mSubject = subject;
		mAlive   = true;
		Rebuild();
		Register();
	}

	private void Register()
	{
		let h = RS_SlateHandler(EventHandler.Find("RS_SlateHandler"));
		if (h) h.Adopt(self);
	}

	void Hide()
	{
		mAlive = false;
		if (mBoard) mBoard.ReleaseAll();
		mHotRow = -1; mHotHand = -1;
		mLastLitRow = -1;
	}

	// Refill from the screen id and lay out again. Called on a
	// compare-hand change and by whoever owns the slate when the world
	// moved under it. NOT called per tic -- a rebuild destroys and
	// recreates every part, which is exactly what unit-space placement
	// exists to avoid doing for a scale change.
	void Refill()
	{
		RS_SlateScreens.Fill(self);
		Rebuild();
	}

	// =================================================================
	// LAYOUT. Bands top-down, each region taking a share of the height
	// and an EMPTY REGION GIVING ITS SHARE TO THE STATS. A weapon status
	// sheet with no buttons should not carry a hole where the actions
	// would have been.
	// =================================================================
	void Rebuild()
	{
		if (!mBoard) return;
		mBoard.ReleaseAll();
		mLastLitRow = -1;
		if (!mAlive) return;

		// ROUND panels are square envelopes. A ring stretched to a tall
		// quad is an ellipse, and an ellipse does not read as "imprint"
		// -- it reads as a mistake.
		double w = mBaseW;
		double h = (mShape == SLS_Round) ? mBaseW : mBaseH;
		mDrawH = h;
		mBoard.mAspect = (h > 0) ? (w / h) : 1.0;

		// Content inset. A square panel uses nearly all of itself; a
		// round one has to fit inside its own circle, and 0.66 of the
		// diameter is the largest axis-aligned box that comfortably
		// does.
		double inset = (mShape == SLS_Round) ? 0.66 : 0.92;

		BuildChrome();

		// --- how much height each region gets ------------------------
		int nSprite = 0, nMark = 0, nButton = 0, nStat = 0;
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (!r) continue;
			if (r.region == SLRG_Sprite)       nSprite++;
			else if (r.region == SLRG_Marks)   nMark++;
			else if (r.region == SLRG_Actions) nButton++;
			else if (r.region == SLRG_Stats)   nStat++;
		}

		// Stats are capped at twelve by the spec. Beyond that a card
		// stops being readable at arm's length, and an honest overflow
		// mark is better than silently dropping rows.
		int statCap = min(nStat, 12);
		bool overflow = (nStat > statCap);

		double hIdent  = 0.13;
		double hSprite = (nSprite > 0) ? 0.20 : 0.0;
		double hMarks  = (nMark   > 0) ? 0.09 : 0.0;
		// Buttons sit two to a row.
		int    btnRows = (nButton + 1) / 2;
		double hAct    = (nButton > 0) ? min(0.34, 0.11 * btnRows) : 0.0;
		double hStats  = 1.0 - hIdent - hSprite - hMarks - hAct;
		if (hStats < 0.08) hStats = 0.08;

		// Unit-Y cursor, top down. 0.5 is the top edge.
		double top = 0.5 * inset;
		double span = inset;      // total usable height in unit-Y

		double yIdent  = top;
		double ySprite = yIdent  - hIdent  * span;
		double yStats  = ySprite - hSprite * span;
		double yMarks  = yStats  - hStats  * span;
		double yAct    = yMarks  - hMarks  * span;

		BuildIdentity(yIdent, hIdent * span, inset);
		if (nSprite  > 0) BuildSprite(ySprite, hSprite * span, inset);
		BuildStats(yStats, hStats * span, inset, statCap, overflow);
		if (nMark    > 0) BuildMarks(yMarks, hMarks * span, inset);
		if (nButton  > 0) BuildActions(yAct, hAct * span, inset, btnRows);

		Place();
	}

	// -----------------------------------------------------------------
	// CHROME. Glow, frame, body -- in that order, each one a little
	// further behind the reader than the last, so nothing depends on
	// submission order to sort correctly.
	// -----------------------------------------------------------------
	private void BuildChrome()
	{
		Color tier = TierTint(mTier);

		if (GlowEnabled())
		{
			// A soft oversized plate in the tier colour. This is the
			// panel's own half of "colour drives the glow" -- the floor
			// pillar and the dynamic light belong to the drop, not to
			// the card.
			let g = mBoard.Add(LevelLocals.BB_PANEL, 0, Shade(tier, 0.55),
				0, 0, 1.30, 1.24, -1.20);
			if (g) g.SetAlpha(0.22);
		}

		if (mShape == SLS_Round)
		{
			// The ring IS the frame. It is a shape, not a meter -- see
			// the header note about BB_RING.
			mBoard.Add(LevelLocals.BB_RING, 0, tier, 0, 0, 1.06, 1.06, -0.60);
			mBoard.Add(LevelLocals.BB_PANEL, 0, Color(235, 14, 12, 16),
				0, 0, 0.80, 0.80, -0.30);
		}
		else
		{
			mBoard.Add(LevelLocals.BB_PANEL, 0, tier, 0, 0, 1.06, 1.04, -0.60);
			mBoard.Add(LevelLocals.BB_PANEL, 0, Color(235, 14, 12, 16),
				0, 0, 1.00, 1.00, -0.30);
		}
	}

	// IDENTITY. The name in the tier colour, the tier word under it.
	// Rarity appears as data, never as decoration -- the NAME is where
	// it appears, which is why the title carries the colour.
	private void BuildIdentity(double yTop, double band, double inset)
	{
		Color tier = TierTint(mTier);
		double lh = min(band * 0.52, 0.075);

		mBoard.Text(0, yTop - band * 0.32, mTitle, lh, tier, 0);

		string sub = mSubtitle;
		if (sub == "") sub = RS_UIStyle.TierName(mTier);
		mBoard.Text(0, yTop - band * 0.78, sub, lh * 0.62, Shade(tier, 0.75), 0);
	}

	private void BuildSprite(double yTop, double band, double inset)
	{
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (!r || r.region != SLRG_Sprite || r.kind != SLK_Sprite) continue;

			// Through a local, not off the field directly -- the same
			// shape RS_BBWeaponCard uses, and the one that is known to
			// compile on this build.
			TextureID t = r.tex;
			if (!t.IsValid()) continue;

			mBoard.Add(LevelLocals.BB_TEXTURE, t.GetIndex(),
				Color(255, 255, 255, 255),
				0, yTop - band * 0.5, 0.46 * inset, band * 0.86, 0);
			return;      // one image; the region is not a gallery
		}
	}

	// -----------------------------------------------------------------
	// STATS. Up to twelve rows, all four readable kinds.
	// -----------------------------------------------------------------
	private void BuildStats(double yTop, double band, double inset,
		int cap, bool overflow)
	{
		Color tier   = TierTint(mTier);
		Color labelC = Color(255, 176, 166, 148);
		Color valueC = Color(255, 240, 240, 240);

		int shown = 0;
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (!r || r.region != SLRG_Stats) continue;
			if (shown >= cap) break;
			shown++;
		}
		if (shown <= 0) return;

		int slots = shown + (overflow ? 1 : 0);
		double pitch = band / slots;
		double lh    = min(pitch * 0.68, 0.055);

		double left  = -0.5 * inset * 0.94;
		double right =  0.5 * inset * 0.94;

		int n = 0;
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (!r || r.region != SLRG_Stats) continue;
			if (n >= cap) break;

			double y = yTop - pitch * (n + 0.5);
			n++;

			if (r.kind == SLK_Heading)
			{
				mBoard.Text(0, y, r.label, lh, tier, 0);
				continue;
			}

			if (r.kind == SLK_Bar)
			{
				Color fill = r.hasTint ? r.tint : tier;
				// Label on the left, meter filling the right half. The
				// engine's own track is the same plate darkened, so a
				// bar is exactly two quads whatever it reads.
				mBoard.Text(left, y, r.label, lh * 0.9, labelC, -1);
				mBoard.Add(LevelLocals.BB_BAR, r.pct, fill,
					right - (0.42 * inset) * 0.5, y, 0.42 * inset, lh * 0.72);
				continue;
			}

			if (r.kind == SLK_Delta)
			{
				Color dc = DirTint(r.dir);
				mBoard.Text(left, y, r.label, lh * 0.9, labelC, -1);
				// old > new, reading left to right, the old one dimmed.
				// The arrow is a glyph like everything else; there is no
				// second mechanism for it.
				string body = r.prev .. " > " .. r.text;
				mBoard.Text(right, y, body, lh * 0.9, dc, 1);
				continue;
			}

			// VALUE
			Color vc = valueC;
			if (r.unknown)      vc = CurseTint();
			else if (r.hasTint) vc = r.tint;

			mBoard.Text(left,  y, r.label, lh * 0.9, labelC, -1);
			mBoard.Text(right, y, r.text,  lh * 0.9, vc, 1);
		}

		if (overflow)
		{
			double y = yTop - pitch * (n + 0.5);
			mBoard.Text(0, y, "+ MORE", lh * 0.8, Color(255, 120, 114, 100), 0);
		}
	}

	// -----------------------------------------------------------------
	// MARKS. Chips across one strip, each on its own small plate so the
	// row reads as a set of tokens rather than a sentence.
	// -----------------------------------------------------------------
	private void BuildMarks(double yTop, double band, double inset)
	{
		Color tier = TierTint(mTier);

		int count = 0;
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (r && r.region == SLRG_Marks) count++;
		}
		if (count <= 0) return;
		if (count > 5) count = 5;   // a strip, not a list

		double y  = yTop - band * 0.5;
		double cw = (inset * 0.94) / count;
		double lh = min(band * 0.55, 0.038);

		int n = 0;
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (!r || r.region != SLRG_Marks) continue;
			if (n >= count) break;

			double cx = -0.5 * inset * 0.94 + cw * (n + 0.5);
			Color c = r.hasTint ? r.tint : tier;

			mBoard.Add(LevelLocals.BB_PANEL, 0, Shade(c, 0.42),
				cx, y, cw * 0.92, band * 0.80, -0.10);
			mBoard.Text(cx, y, r.label, lh, Lift(c, 0.45), 0);
			n++;
		}
	}

	// -----------------------------------------------------------------
	// ACTIONS. Two to a row, each on a tier-coloured plate that IS the
	// hit target -- the biggest thing on the row, nudged toward the
	// reader so touch resolves to it rather than to the chrome behind.
	// -----------------------------------------------------------------
	private void BuildActions(double yTop, double band, double inset, int btnRows)
	{
		Color tier = TierTint(mTier);

		int count = 0;
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (r && r.region == SLRG_Actions) count++;
		}
		if (count <= 0) return;

		double rowH = band / btnRows;
		double lh   = min(rowH * 0.46, 0.042);

		int n = 0;
		for (int i = 0; i < mRows.Size(); i++)
		{
			let r = mRows[i];
			if (!r || r.region != SLRG_Actions) continue;

			int col   = n % 2;
			int line  = n / 2;
			// A lone button on the last line takes the whole width --
			// a half-width DENY floating beside a hole reads as broken.
			bool wide = (col == 0 && n == count - 1);

			double bw = wide ? (inset * 0.94) : (inset * 0.94 * 0.48);
			double bx = wide ? 0.0
			                 : (-0.5 * inset * 0.94 + (inset * 0.94 * 0.52) * col
			                    + bw * 0.5);
			double by = yTop - rowH * (line + 0.5);

			Color plate = Shade(tier, 0.50);

			// THE PLATE IS THE TARGET, and it is nudged forward. See the
			// file header: TouchBillboard keeps the nearest by plane
			// distance with a strict test, so among coplanar parts the
			// first created wins. Geometry decides here, not creation
			// order.
			mBoard.Add(LevelLocals.BB_PANEL, 0, plate,
				bx, by, bw, rowH * 0.80, 0.35, i, true);

			mBoard.Text(bx, by, r.label, lh, Lift(tier, 0.55), 0, i, 0.45);
			n++;
		}
	}

	// =================================================================
	// PLACEMENT. Solved once per tic in play scope.
	// =================================================================

	// Distance from the reader to whatever this slate is about. For a
	// pinned slate that is the slate itself.
	double SubjectDistance(Vector3 eye) const
	{
		if (mSubject) return (mSubject.pos - eye).Length();
		return (mAt - eye).Length();
	}

	// -----------------------------------------------------------------
	// DISTANCE DRIVES SCALE, CONTINUOUSLY.
	//
	// The old drop card was a hard radius switch onto a fixed-size card:
	// it either was not there or was fully there. The owner's design is
	// a ramp -- far reads as a pillar and a marker, mid grows a card,
	// near is full size with live buttons.
	//
	// Note the distance measured is to the SUBJECT, not to the card. In
	// comfort mode the card holds station a fixed distance from the eye,
	// so its own distance never changes and could not drive anything.
	// -----------------------------------------------------------------
	double ScaleFor(double dist) const
	{
		double dNear = NearDist();
		double dFar  = FarDist();
		if (dFar <= dNear) return 1.0;
		if (dist <= dNear) return 1.0;
		if (dist >= dFar)  return MinScale();

		double t = (dFar - dist) / (dFar - dNear);
		return MinScale() + (1.0 - MinScale()) * t;
	}

	// Buttons only answer at full-ish size. A card you can barely read
	// is a card whose actions you did not mean to press.
	bool ActionsLive() const
	{
		return mScale >= 0.85;
	}

	void Solve(Vector3 eye)
	{
		if (!mAlive) return;

		double dist = SubjectDistance(eye);
		mScale = ScaleFor(dist);

		if (mSubject)
		{
			// Comfort: stand off from the reader toward the subject. If
			// you are already closer than the comfort distance the card
			// would end up BEHIND you, so it clamps to the subject
			// rather than inverting.
			Vector2 flat = (mSubject.pos.x - eye.x, mSubject.pos.y - eye.y);
			double  d    = flat.Length();
			double  reach = RS_PanelController.Comfort();

			if (d < 1)
			{
				mAt = (mSubject.pos.x, mSubject.pos.y,
				       eye.z + RS_PanelController.HeightOfs());
			}
			else
			{
				Vector2 dir = flat / d;
				double  r   = min(reach, d);
				mAt = (eye.x + dir.x * r, eye.y + dir.y * r,
				       eye.z + RS_PanelController.HeightOfs());
			}
		}

		// Face the reader, stay upright. A panel that pitches to track a
		// player looking down at it reads as unstable, and text on it
		// gets harder to read rather than easier.
		Vector3 d3 = level.Vec3Diff(mAt, eye);
		mYaw  = atan2(d3.y, d3.x);
		mTilt = 0;

		Place();
	}

	void Place()
	{
		if (!mBoard || !mAlive) return;
		if (mDrawH <= 0) mDrawH = mBaseH;
		mBoard.Place(mAt, mYaw, mTilt, mBaseW * mScale, mDrawH * mScale);
	}

	// =================================================================
	// THE HIT TEST. Touch beats pointing; the engine answers both.
	// =================================================================
	void UpdateHot(PlayerPawn pawn)
	{
		mHotRow = -1; mHotHand = -1; mHotDist = 1e9;

		if (!mAlive || !pawn || !mBoard || mBoard.Empty()) { Relight(); return; }

		// A card too small to read is a card whose actions you did not
		// mean to press. Below the threshold it is a presence, not a
		// control panel.
		if (!ActionsLive()) { Relight(); return; }

		bool tracked = pawn.OverrideAttackPosDir;

		// --- POINTING -------------------------------------------------
		// Two rays when hands are tracked, one down the view when they
		// are not. Nearest hit across both wins.
		for (int hand = 0; hand < 2; hand++)
		{
			Vector3 origin;
			double  yaw, pit;

			if (tracked)
			{
				origin = (hand == 0) ? pawn.OffhandPos   : pawn.AttackPos;
				yaw    = (hand == 0) ? pawn.OffhandAngle : pawn.AttackAngle;
				pit    = (hand == 0) ? pawn.OffhandPitch : pawn.AttackPitch;
			}
			else
			{
				if (hand == 1) continue;
				origin = (pawn.pos.x, pawn.pos.y,
				          pawn.player ? pawn.player.viewz : pawn.pos.z + 41);
				yaw    = pawn.angle;
				pit    = pawn.pitch;
			}

			// Positive pitch looks DOWN in Doom, hence the negated Z.
			Vector3 dir = (cos(yaw) * cos(pit), sin(yaw) * cos(pit), -sin(pit));

			int hit; Vector2 uv;
			[hit, uv] = level.AimBillboard(origin, dir,
				RS_PanelController.ShootRange());
			if (hit == 0) continue;

			int row = mBoard.RowForHandle(hit);
			if (row < 0) continue;
			if (!IsButton(row)) continue;

			double t = (mAt - origin).Length();
			if (t >= mHotDist) continue;

			mHotDist = t;
			mHotRow  = row;
			mHotHand = tracked ? hand : 1;
		}

		// --- TOUCH ----------------------------------------------------
		// TOUCH IS PRIMARY AND RUNS LAST, so it overwrites a ray.
		// Reaching out and putting your hand on a button is a stronger
		// statement of intent than a ray that happens to graze it from
		// across the room. Tracked hands only: without a real pose the
		// "hand" position is the player's own origin, which would put
		// you permanently inside any panel you walked through.
		if (tracked)
		{
			double depth = RS_PanelInput.PokeDepth();
			if (depth > 0)
			{
				for (int hand = 0; hand < 2; hand++)
				{
					Vector3 hp = (hand == 0) ? pawn.OffhandPos : pawn.AttackPos;

					int hit; Vector2 uv; double dist;
					[hit, uv, dist] = level.TouchBillboard(hp, depth);
					if (hit == 0) continue;

					int row = mBoard.RowForHandle(hit);
					if (row < 0 || !IsButton(row)) continue;

					mHotRow  = row;
					mHotHand = hand;
					mHotDist = 0;      // a hand inside the panel is at zero range
					break;
				}
			}
		}

		Relight();
	}

	bool IsButton(int row) const
	{
		if (row < 0 || row >= mRows.Size()) return false;
		let r = mRows[row];
		return r && r.kind == SLK_Button && r.cmd != "";
	}

	// Move the highlight. Only the plate changes colour -- see
	// RS_SlateBoard.TintPlate for why the text must not.
	private void Relight()
	{
		if (mHotRow == mLastLitRow) return;

		Color tier = TierTint(mTier);
		if (mLastLitRow >= 0) mBoard.TintPlate(mLastLitRow, Shade(tier, 0.50));
		if (mHotRow    >= 0) mBoard.TintPlate(mHotRow,    Lift(tier, 0.35));
		mLastLitRow = mHotRow;
	}

	// -----------------------------------------------------------------
	// PRESS. Fire the hot row's own netevent.
	//
	// Deliberately generic: the row carries the command, so every future
	// screen gets a working press for free and no new bind is ever
	// needed.
	//
	// WHICH HAND ACTED IS THE HAND THAT RECEIVES, unless the button
	// names a hand of its own. `hand` is the physical hand that pressed
	// (-1 when nothing knows), and a hand-agnostic button forwards it as
	// its argument -- so "Apply" pressed with your left goes left.
	// -----------------------------------------------------------------
	bool Press(PlayerPawn pawn, int hand)
	{
		if (!mAlive || mHotRow < 0 || !IsButton(mHotRow)) return false;

		let r = mRows[mHotRow];
		int arg = r.arg;
		if (r.hand < 0 && hand >= 0) arg = hand;

		RS_PanelInput.Say(pawn, "menu/activate");
		EventHandler.SendNetworkEvent(r.cmd, arg);
		return true;
	}
}

// =====================================================================
// RS_SlateScreens -- the content sets.
//
// The point of the whole exercise: a screen is a function that fills a
// list. There is no panel code down here and there never will be.
//
// Ten of these are planned (weapon status, level-up, promotion, curses,
// repair, map stats, the offer, ...). Two are built, because two is
// what proves the shape.
//
// `play` IS LOAD-BEARING, NOT DECORATION. An unscoped Object subclass is
// DATA scope, and data scope cannot call a play function -- which is
// every method this class exists to call: RS_Slate is a play class, so
// Open/Value/Delta/Bar/Button all are, and so are
// TFLV_PerPlayerStats.GetStatsFor and every read of pawn.player. Without
// it this file produces a wall of "Can't call play function X from data
// context" plus cascading "Unknown identifier" noise from the locals
// that failed above them.
// =====================================================================
class RS_SlateScreens play
{
	static void Fill(RS_Slate s)
	{
		if (!s) return;
		PlayerPawn pawn = players[consoleplayer].mo;
		if (!pawn) return;

		switch (s.mScreen)
		{
			case SLSC_WeaponStatus: WeaponStatus(s, pawn, s.mHand); return;
			case SLSC_EliteOffer:   EliteOffer(s, pawn);            return;
		}
	}

	// -----------------------------------------------------------------
	// SCREEN 1 -- WEAPON STATUS. What this gun is, right now.
	//
	// The same facts RS_BillboardUI.RS_BBWeaponStatus and
	// RS_Screens.BuildWeaponSheet show, on the one panel. Cursed stats
	// read ??? here exactly as they do there -- the sheet and the
	// in-world screen must not disagree about what the player is allowed
	// to know, or one of them gives the game away.
	// -----------------------------------------------------------------
	static void WeaponStatus(RS_Slate s, PlayerPawn pawn, int hand)
	{
		if (!pawn.player) return;

		Weapon wep = (hand == 0) ? pawn.player.OffhandWeapon
		                         : pawn.player.ReadyWeapon;
		string handName = (hand == 0) ? "OFFHAND" : "MAINHAND";

		let w = RS_Weapon(wep);
		if (!w)
		{
			s.Open(handName, VRT_Trash, SLS_Square, "EMPTY");
			return;
		}

		int tier = int(w.Tier);
		s.Open(wep.GetTag(), tier, SLS_Square,
			handName .. "  " .. RS_UIStyle.TierName(tier));

		TextureID icon = PickIcon(wep);
		if (icon.IsValid()) s.Picture(icon);

		// DAMAGE and the three other rolled stats hide behind ??? when
		// cursed. DPS is derived from damage, so it has to hide too --
		// otherwise it leaks the exact number the curse is concealing.
		if (w.LockedDamage) s.Unknown("DAMAGE");
		else                s.Value("DAMAGE", w.DamagePerShot);

		int dps = int(w.DamagePerShot * max(1, w.PelletCount) * max(1, w.RateOfFire));
		if (w.LockedDamage) s.Unknown("DPS");
		else                s.Value("DPS", dps);

		if (w.LockedAccuracy) s.Unknown("ACCURACY");
		else                  s.Value("ACCURACY", int(w.Accuracy));

		if (w.LockedCritChance) s.Unknown("CRIT");
		else s.ValueText("CRIT", String.Format("%.1f%%", w.CritChance * 100.0));

		if (w.LockedVelocity) s.Unknown("VELOCITY");
		else                  s.Value("VELOCITY", int(w.Velocity));

		if (w.LockedCapacity) s.Unknown("MAGAZINE");
		else                  s.Value("MAGAZINE", w.Capacity);

		s.Value("PELLETS", w.PelletCount);
		s.Value("RATE OF FIRE", w.RateOfFire);

		// Condition is a meter where everything else is a number. It is
		// the one answering "is this about to fail", and a bar answers
		// that at a glance where a number has to be read.
		s.Bar("CONDITION", int(w.Condition),
			ConditionTint(w.Condition), true);

		// --- marks ---------------------------------------------------
		s.Mark(String.Format("%d SOCK", w.GunBonaiSockets));
		if (w.PromotionCount > 0)
			s.Mark(String.Format("P%d", w.PromotionCount),
				Color(255, 255, 208, 64), true);

		int affixes = AffixCount(pawn, wep);
		if (affixes > 0) s.Mark(String.Format("%d AFX", affixes));

		int stacks = w.TotalCurseStacks();
		if (stacks > 0)
			s.Mark(String.Format("%d CURSE", stacks), RS_Slate.CurseTint(), true);
	}

	// -----------------------------------------------------------------
	// SCREEN 2 -- THE ELITE OFFER. A class weapon on the floor, against
	// the hand you are pointing with.
	//
	// SQUARE, because a class weapon is what is being offered. An
	// imprint would raise the same screen ROUND, and that is the only
	// difference the player has to learn.
	//
	// The stats are DELTAS, not a three-column comparison: the old
	// triptych answered "how do these three guns compare" with nine
	// panels, and the question a player actually asks is "is this better
	// than the one in the hand I am reaching with". One panel, one
	// answer, and the answer follows the hand.
	// -----------------------------------------------------------------
	static void EliteOffer(RS_Slate s, PlayerPawn pawn)
	{
		if (!pawn.player) return;

		let drop = RS_WeaponDrop(s.mSubject);
		let offer = drop ? RS_Weapon(drop.mPayload) : null;
		if (!offer)
		{
			s.Open("GONE", VRT_Trash, SLS_Square, "");
			return;
		}

		int tier = int(offer.Tier);
		int cmp  = s.mCompareHand;

		Weapon heldW = (cmp == 0) ? pawn.player.OffhandWeapon
		                          : pawn.player.ReadyWeapon;
		let held = RS_Weapon(heldW);
		bool has = (held != null);
		string vs = (cmp == 0) ? "VS OFFHAND" : "VS MAINHAND";

		s.Open(offer.GetTag(), tier, SLS_Square,
			RS_UIStyle.TierName(tier) .. "   " .. vs);

		TextureID icon = PickIcon(offer);
		if (icon.IsValid()) s.Picture(icon);

		// PELLETS leads on purpose: it is the stat Promotion grows
		// permanently, so it is the one a player is most often deciding
		// about, and it multiplies everything below it.
		Cmp(s, "PELLETS", has, has ? held.PelletCount : 0, offer.PelletCount);
		Cmp(s, "DAMAGE",  has, has ? held.DamagePerShot : 0, offer.DamagePerShot);

		double volOld = has ? held.DamagePerShot * max(1, held.PelletCount) : 0;
		double volNew = offer.DamagePerShot * max(1, offer.PelletCount);
		Cmp(s, "VOLLEY", has, volOld, volNew);

		Cmp(s, "ACCURACY", has, has ? held.Accuracy : 0, offer.Accuracy, 1);

		// A cursed stat on the OFFER reads ???. The delta cannot be
		// shown without leaking the number the curse is hiding, so the
		// row degrades to an unknown instead of silently vanishing --
		// a missing row would read as "this gun has no crit".
		if (offer.LockedCritChance) s.Unknown("CRIT");
		else Cmp(s, "CRIT", has,
			has ? held.CritChance * 100.0 : 0, offer.CritChance * 100.0, 1);

		Cmp(s, "VELOCITY", has, has ? held.Velocity : 0, offer.Velocity);
		Cmp(s, "MAGAZINE", has, has ? held.Capacity : 0, offer.Capacity);
		Cmp(s, "SOCKETS",  has, has ? held.GunBonaiSockets : 0, offer.GunBonaiSockets);

		s.Bar("CONDITION", int(offer.Condition),
			ConditionTint(offer.Condition), true);

		// --- marks ---------------------------------------------------
		s.Mark(String.Format("%d SOCK", offer.GunBonaiSockets));

		// A dropped weapon has never been wielded, so GunBonsai has no
		// WeaponInfo for it. That is not an error state and must not
		// render as "0 affixes" -- it is genuinely unknown until you
		// pick the thing up.
		s.Mark("AFX ?");

		int stacks = offer.TotalCurseStacks();
		if (stacks > 0)
			s.Mark(String.Format("%d CURSE", stacks), RS_Slate.CurseTint(), true);

		// --- actions -------------------------------------------------
		// A REAL fist refuses a class weapon. VR_Fist2 and its
		// descendants are the empty-slot filler every class grants at
		// spawn, and an empty slot is the most takeable case there is --
		// which is why this asks IsRealFist rather than `is VR_Fist`.
		if (!RS_DropTriptych.IsRealFist(pawn.player.OffhandWeapon))
			s.Button("APPLY - OFFHAND", "rs-slate-apply", 0);
		if (!RS_DropTriptych.IsRealFist(pawn.player.ReadyWeapon))
			s.Button("APPLY - MAINHAND", "rs-slate-apply", 1);

		s.Button(String.Format("RECYCLE  %dg", RS_Slate.RecycleValue(tier)),
			"rs-slate-recycle");

		// DENY REMOVES IT FROM THE WORLD ENTIRELY. Owner's ruling
		// 2026-08-08, and it overrides the older note that said a
		// rejected package lingers. Nothing is left behind to walk back
		// to and nothing is left glowing on the floor.
		s.Button("DENY", "rs-slate-deny");
	}

	// One comparison row, degrading to "from empty" when the hand being
	// compared against is holding nothing.
	private static void Cmp(RS_Slate s, string label, bool has,
		double oldV, double newV, int decimals = 0)
	{
		if (has) s.Delta(label, oldV, newV, decimals);
		else     s.DeltaFromEmpty(label, newV, decimals);
	}

	// The inventory icon where a weapon has one, its spawn sprite where
	// it does not. Not every RS weapon declares Inventory.Icon, and a
	// card with a hole in its sprite region reads as broken rather than
	// as unadorned.
	static TextureID PickIcon(Weapon w)
	{
		TextureID none;
		none.SetInvalid();
		if (!w) return none;

		TextureID icon = w.Icon;
		if (icon.IsValid()) return icon;

		let st = w.SpawnState;
		if (st)
		{
			TextureID t; bool flip; Vector2 scl;
			[t, flip, scl] = st.GetSpriteTexture(0);
			if (t.IsValid()) return t;
		}
		return none;
	}

	// Matches RS_UIStyle.ConditionColor's bands, as real RGB -- a
	// billboard is tinted, not translated, so Font.CR_* cannot drive it.
	static Color ConditionTint(double cnd)
	{
		if (cnd >= 80.0) return Color(255,  80, 220,  90);
		if (cnd >= 40.0) return Color(255, 235, 210,  70);
		return Color(255, 230, 70, 60);
	}

	static int AffixCount(PlayerPawn pawn, Weapon w)
	{
		let stats = TFLV_PerPlayerStats.GetStatsFor(pawn);
		let info  = stats ? stats.GetInfoFor(w) : null;
		if (!info) return 0;

		int held = 0;
		for (int i = 0; i < info.upgrades.upgrades.Size(); i++)
			if (info.upgrades.upgrades[i] && info.upgrades.upgrades[i].level > 0)
				held++;
		return held;
	}
}

// =====================================================================
// RS_SlateHandler -- owns the live slates, drives them, routes presses.
//
// MUST ALSO be listed in MAPINFO.txt's AddEventHandlers. A handler name
// in MAPINFO with no class is a hard crash at map load; a class with no
// MAPINFO line compiles and silently never runs. Both halves or
// neither.
//
// NO PAINTER. That is the thing worth noticing about this class next to
// every other UI handler in the tree: a composed panel has no canvas, so
// there is no RenderOverlay, no ui-scope half, no dirty counter and no
// scope split to get wrong. The whole screen is play-scope data and
// engine geometry.
// =====================================================================
class RS_SlateHandler : EventHandler
{
	Array<RS_Slate> mLive;

	// The slate a hand is currently on, and the row -- so a press
	// arriving as a netevent knows what it is pressing.
	int mFocus;
	int mLastHotRow;
	int mLastHotSlate;

	// A slate raised by the auto-offer, so it can be dropped again when
	// the player walks away or the drop dies.
	RS_Slate mOffer;
	Actor    mOfferSubject;

	override void WorldLoaded(WorldEvent e)
	{
		mFocus = -1; mLastHotRow = -1; mLastHotSlate = -1;
	}

	// Take ownership of a slate. Called by RS_Slate.Show, so a caller
	// never has to remember to register one -- forgetting is how the
	// old drop card leaked panels for a whole map.
	play void Adopt(RS_Slate s)
	{
		if (!s) return;
		for (int i = 0; i < mLive.Size(); i++)
			if (mLive[i] == s) return;
		mLive.Push(s);
	}

	play void Retire(RS_Slate s)
	{
		if (!s) return;
		for (int i = 0; i < mLive.Size(); i++)
		{
			if (mLive[i] == s)
			{
				mLive[i].Hide();
				mLive.Delete(i);
				return;
			}
		}
		s.Hide();
	}

	play void RetireAll()
	{
		for (int i = 0; i < mLive.Size(); i++)
			if (mLive[i]) mLive[i].Hide();
		mLive.Clear();
		mOffer = null; mOfferSubject = null;
		mFocus = -1; mLastHotRow = -1; mLastHotSlate = -1;
	}

	// Whichever live slate has a hot row. Only one can, because
	// UpdateHot runs over all of them and the last one to claim a hand
	// wins -- which is settled by taking the nearest, below.
	play RS_Slate Focused()
	{
		if (mFocus < 0 || mFocus >= mLive.Size()) return null;
		return mLive[mFocus];
	}

	override void WorldTick()
	{
		if (!RS_Slate.Enabled())
		{
			if (mLive.Size() > 0) RetireAll();
			return;
		}

		PlayerPawn pawn = players[consoleplayer].mo;
		if (!pawn || !pawn.player) { if (mLive.Size() > 0) RetireAll(); return; }

		Vector3 eye = (pawn.pos.x, pawn.pos.y, pawn.player.viewz);

		ConsiderOffer(pawn, eye);

		// --- solve, then resolve the pointer --------------------------
		mFocus = -1;
		double bestDist = 1e9;

		for (int i = 0; i < mLive.Size(); i++)
		{
			let s = mLive[i];
			if (!s) continue;

			// A slate whose subject has gone is a slate nobody can
			// dismiss. The old drop card had exactly this hole: destroy
			// the pedestal any other way -- console `remove`, a map
			// script, a crusher -- and its panels stayed registered,
			// solved every tic, forever.
			if (s.mScreen == SLSC_EliteOffer && !s.mSubject)
			{
				Retire(s);
				i--;
				continue;
			}

			s.Solve(eye);
			s.UpdateHot(pawn);

			if (s.mHotRow >= 0 && s.mHotDist < bestDist)
			{
				bestDist = s.mHotDist;
				mFocus   = i;
			}
		}

		// --- the compare hand follows the pointing hand ---------------
		// An offer's deltas are against the hand you are reaching with,
		// so the hand changing rebuilds the card. ONLY a change: pointing
		// steadily costs nothing, which is what stops a rebuild-per-tic.
		let f = Focused();
		if (f && f.mScreen == SLSC_EliteOffer && f.mHotHand >= 0
			&& f.mHotHand != f.mCompareHand)
		{
			f.mCompareHand = f.mHotHand;
			f.Refill();

			// The rebuild issued a fresh set of handles, so the row that
			// was hot is described by an index into a list that no
			// longer exists. It happens to survive today -- the offer
			// emits the same rows whichever hand it compares against --
			// but relying on that would make a future screen's row order
			// load-bearing for the press. Drop it and re-resolve next
			// tic; the cost is one tic of no highlight on a gesture the
			// player just made deliberately.
			f.mHotRow = -1;
		}

		// --- hover ----------------------------------------------------
		// Only a live row chirps. Sweeping a hand across a card of stat
		// rows must not chatter: the sound has to mean "there is
		// something here", or it means nothing.
		int hotRow = f ? f.mHotRow : -1;
		if (hotRow >= 0 && (hotRow != mLastHotRow || mFocus != mLastHotSlate))
			RS_PanelInput.Say(pawn, "menu/cursor");

		mLastHotRow   = hotRow;
		mLastHotSlate = (hotRow >= 0) ? mFocus : -1;
	}

	// -----------------------------------------------------------------
	// AUTO-RAISE. Deliberately disarmed unless the old triptych is off
	// -- see RS_Slate.OfferAuto. Two offers for one drop would be two
	// implementations of "take this", and only the one you tested stays
	// correct.
	// -----------------------------------------------------------------
	play void ConsiderOffer(PlayerPawn pawn, Vector3 eye)
	{
		if (!RS_Slate.OfferAuto())
		{
			if (mOffer) { Retire(mOffer); mOffer = null; mOfferSubject = null; }
			return;
		}

		// Nearest live drop inside the far radius.
		double far = RS_Slate.FarDist();
		Actor best = null;
		double bestD = far;

		ThinkerIterator it = ThinkerIterator.Create("RS_WeaponDrop");
		Actor a;
		while (a = Actor(it.Next()))
		{
			let d = RS_WeaponDrop(a);
			if (!d || !d.mPayload) continue;
			double dist = (a.pos - eye).Length();
			if (dist >= bestD) continue;
			bestD = dist; best = a;
		}

		if (!best)
		{
			if (mOffer) { Retire(mOffer); mOffer = null; mOfferSubject = null; }
			return;
		}

		if (mOffer && mOfferSubject == best) return;

		if (mOffer) Retire(mOffer);
		mOffer = OpenOffer(best);
		mOfferSubject = best;
	}

	// -----------------------------------------------------------------
	// OPENERS. One per screen, so the netevents and the auto-raise share
	// exactly one way of building each.
	// -----------------------------------------------------------------
	play RS_Slate OpenOffer(Actor drop)
	{
		if (!drop) return null;
		let s = RS_Slate.Create();
		s.mScreen  = SLSC_EliteOffer;
		s.mSubject = drop;
		s.mCompareHand = 1;
		RS_SlateScreens.Fill(s);
		s.ShowOn(drop);
		return s;
	}

	play RS_Slate OpenStatus(PlayerPawn pawn, int hand)
	{
		if (!pawn || !pawn.player) return null;

		let s = RS_Slate.Create();
		s.mScreen = SLSC_WeaponStatus;
		s.mHand   = hand;
		RS_SlateScreens.Fill(s);

		// Pinned in front of the reader at the comfort distance, at eye
		// level. Not view-locked: a status sheet welded to the eye
		// cannot be walked around, and every other screen in this
		// project is an object in the world you look at.
		Vector3 eye = (pawn.pos.x, pawn.pos.y, pawn.player.viewz);
		double  r   = RS_PanelController.Comfort();
		Vector3 at  = (eye.x + cos(pawn.angle) * r,
		               eye.y + sin(pawn.angle) * r,
		               eye.z + RS_PanelController.HeightOfs());
		s.Show(at);
		return s;
	}

	play RS_Slate FindScreen(int screen)
	{
		for (int i = 0; i < mLive.Size(); i++)
			if (mLive[i] && mLive[i].mScreen == screen) return mLive[i];
		return null;
	}

	override void WorldUnloaded(WorldEvent e)
	{
		// Billboard handles are not actors and nothing else collects
		// them.
		RetireAll();
	}

	override void NetworkProcess(ConsoleEvent evt)
	{
		if (evt.player < 0) return;
		PlayerPawn pawn = players[evt.player].mo;
		if (!pawn || !pawn.player) return;

		// -------------------------------------------------------------
		// THE PRESS. Shares the existing rs-panel-use netevent, which is
		// what MOUSE3 is bound to (KEYCONF), so the slate is reachable
		// on a desktop with no new bind and no edit to a file another
		// lane is holding.
		//
		// It cannot collide with the drop triptych: that branch returns
		// immediately when it has no card, and the offer slate refuses
		// to auto-raise while the triptych is enabled at all.
		//
		// The argument is a hand PLUS ONE -- 0 has always meant "no hand
		// information, use whatever is being pointed at", and it has to
		// keep meaning that for the console and the bind.
		// -------------------------------------------------------------
		if (evt.name == "rs-panel-use" || evt.name == "rs-slate-press")
		{
			let s = Focused();
			if (!s) return;
			int hint = evt.args[0] - 1;
			if (hint < 0) hint = s.mHotHand;
			if (!s.Press(pawn, hint))
				RS_PanelInput.Say(pawn, "menu/invalid");
			return;
		}

		if (evt.name == "rs-slate-status" || evt.name == "rs-slate-status-off")
		{
			bool off = (evt.name == "rs-slate-status-off");
			int hand = off ? 0 : 1;

			// Same hand again = toggle off, which is how every other
			// status screen in this project behaves.
			let live = FindScreen(SLSC_WeaponStatus);
			if (live)
			{
				bool same = (live.mHand == hand);
				Retire(live);
				if (same) return;
			}
			OpenStatus(pawn, hand);
			return;
		}

		if (evt.name == "rs-slate-close")
		{
			if (mLive.Size() > 0) RS_PanelInput.Say(pawn, "menu/clear");
			RetireAll();
			return;
		}

		// Dev harness: raise the offer against the nearest live drop
		// without needing the auto-raise armed. `netevent rs-slate-offer`
		if (evt.name == "rs-slate-offer")
		{
			Vector3 eye = (pawn.pos.x, pawn.pos.y, pawn.player.viewz);
			Actor best = null;
			double bestD = 1e9;

			ThinkerIterator it = ThinkerIterator.Create("RS_WeaponDrop");
			Actor a;
			while (a = Actor(it.Next()))
			{
				let d = RS_WeaponDrop(a);
				if (!d || !d.mPayload) continue;
				double dist = (a.pos - eye).Length();
				if (dist >= bestD) continue;
				bestD = dist; best = a;
			}

			// SAY SO OUT LOUD. This is a console-only dev route, and a
			// silent no-op here is indistinguishable from the panel
			// being broken -- which is exactly the confusion that cost
			// an afternoon the first time this was tested.
			if (!best)
			{
				RS_PanelInput.Say(pawn, "menu/invalid");
				Console.Printf("\c[Red]rs-slate-offer:\c- no live weapon drop with a payload in range.");
				return;
			}

			let existing = FindScreen(SLSC_EliteOffer);
			if (existing) Retire(existing);
			OpenOffer(best);
			return;
		}

		// =============================================================
		// THE OFFER'S OWN ACTIONS.
		//
		// WHY APPLY IS IMPLEMENTED HERE AND NOT ROUTED INTO
		// rs-panel-take. That branch reads RS_PanelDropHandler's OWN
		// card state (mCardOwner), which the slate never sets, so
		// sending it would be a no-op that looked like a working button.
		// The slate supersedes the triptych, so it owns its take.
		//
		// THIS IS DELIBERATELY A SECOND IMPLEMENTATION AND IT IS DEBT.
		// When the owner approves deleting RS_DropTriptych, these two
		// collapse into one. Until then the shape below mirrors the
		// verified original step for step -- undress, seat by
		// PendingWeapon, sound -- and every line that matters says why.
		// =============================================================
		if (evt.name == "rs-slate-apply")
		{
			let s = FindScreen(SLSC_EliteOffer);
			if (!s) return;

			let drop = RS_WeaponDrop(s.mSubject);
			if (!drop || !drop.mPayload) return;

			bool toOffhand = (evt.args[0] == 0);

			Weapon held = toOffhand ? pawn.player.OffhandWeapon
			                        : pawn.player.ReadyWeapon;

			// A REAL fist refuses a class weapon -- the card says so and
			// this honours it, so the two cannot disagree. VR_Fist2 is
			// the empty-slot filler and IS takeable, which is why this
			// is IsRealFist and not `is "VR_Fist"`.
			if (RS_DropTriptych.IsRealFist(held))
			{
				RS_PanelInput.Say(pawn, "menu/invalid");
				return;
			}

			let w = drop.mPayload;
			drop.mPayload = null;

			// UNDRESS THE DROP BEFORE HANDING IT OVER. Everything the
			// pedestal put ON the weapon to make it read as a drop is a
			// property of the WEAPON ACTOR, so it travels into inventory
			// unless it comes off here: an attached dynamic light
			// follows its actor, and an inventory item is moved to the
			// owner every tic, so a taken Prototype would leave the
			// player permanently haloed and carrying a light they could
			// not put down. It also stacks -- six drops is six lights.
			//
			// The tier TRANSLATION is deliberately left on: that is the
			// weapon's rarity and it should stay visible on the object.
			w.A_RemoveLight('RSDropGlow');
			w.bBright        = false;
			w.bInvisible     = false;
			w.bNoInteraction = false;
			w.bOffhandWeapon = toOffhand;
			w.AttachToOwner(pawn);

			// SEATING IS EXPLICIT. AttachToOwner alone is not a take: it
			// only seats the offhand when that slot is empty or holds
			// the filler, and it never touches the mainhand at all -- so
			// with a real weapon in the hand you chose, which is the
			// normal case, the drop would silently join inventory and
			// your hands would be unchanged.
			//
			// PendingWeapon, not a direct slot write: CheckWeaponChange
			// reads PendingWeapon.bOffhandWeapon to pick the hand and
			// then lowers and raises properly. And not A_SelectWeapon,
			// which resolves by CLASS -- if the player already owns a
			// weapon of this class it would raise THAT one and leave the
			// rolled instance, the entire reason the card exists,
			// unused in inventory.
			pawn.player.PendingWeapon = w;

			RS_PanelInput.Say(pawn, "misc/w_pkup");

			Retire(s);
			if (mOffer == s) { mOffer = null; mOfferSubject = null; }
			drop.Destroy();
			return;
		}

		// -------------------------------------------------------------
		// RECYCLE. The offer becomes gold, and a higher tier refused
		// pays more -- so turning down a Prototype is a real decision
		// rather than a shrug.
		// -------------------------------------------------------------
		if (evt.name == "rs-slate-recycle")
		{
			let s = FindScreen(SLSC_EliteOffer);
			if (!s) return;

			let drop = RS_WeaponDrop(s.mSubject);
			if (!drop || !drop.mPayload) return;

			let w = RS_Weapon(drop.mPayload);
			int tier = w ? int(w.Tier) : VRT_Basic;
			int paid = RS_Slate.RecycleValue(tier);

			if (paid > 0) pawn.A_GiveInventory("RS_Bit_Gold", paid);

			// The payload goes with the pedestal. A recycled weapon that
			// stayed in the world would be the same drop offered twice.
			drop.mPayload.Destroy();
			drop.mPayload = null;

			RS_PanelInput.Say(pawn, "misc/w_pkup");
			Console.Printf("\c[Gold]Recycled for %d gold.", paid);

			Retire(s);
			if (mOffer == s) { mOffer = null; mOfferSubject = null; }
			drop.Destroy();
			return;
		}

		// -------------------------------------------------------------
		// DENY REMOVES IT FROM THE WORLD ENTIRELY.
		//
		// Owner's ruling, 2026-08-08, and it OVERRIDES the older R3 note
		// that said a rejected package lingers. Nothing is left on the
		// floor, nothing keeps glowing, and there is no pillar to walk
		// back to. Refusing is final, which is what makes it a choice.
		// -------------------------------------------------------------
		if (evt.name == "rs-slate-deny")
		{
			let s = FindScreen(SLSC_EliteOffer);
			if (!s) return;

			let drop = RS_WeaponDrop(s.mSubject);

			RS_PanelInput.Say(pawn, "menu/clear");

			Retire(s);
			if (mOffer == s) { mOffer = null; mOfferSubject = null; }

			if (drop)
			{
				// The payload is a real weapon actor the pedestal is
				// carrying. Destroying only the pedestal would leak it.
				if (drop.mPayload) { drop.mPayload.Destroy(); drop.mPayload = null; }
				drop.Destroy();
			}
			return;
		}
	}
}
