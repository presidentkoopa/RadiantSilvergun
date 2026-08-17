// =====================================================================
// RS_CardPanel -- the shared in-world card.
// ---------------------------------------------------------------------
// Everything two RS cards have in common: the plate, the type ladder,
// the flow layout, and the one rule about how BB_TEXT is sized.
//
// WHY THIS IS A BASE CLASS AND NOT A SECOND COPY. The rarity token's
// panel grew all of this first and grew it well -- the flow layout is
// the reason that card cannot overflow at any size. The weapon card
// needs the identical machinery. Copying it would have produced two
// versions of one layout engine that start identical and stop being
// identical the first time either is touched, which is exactly the
// failure this codebase keeps writing comments about: RS_TierPalette's
// header says a surface "calls this -- it does not write a table", and
// ANIMDEFS is a gravestone for eleven canvas names nothing referenced.
//
// So the machinery lives here once and both cards inherit it. A fix to
// the type ladder fixes both cards; a new payload is available to both.
// Subclasses supply only what is genuinely their own: which cvars carry
// their dials, what goes on the card, and when it is up.
// =====================================================================

class RS_CardPanel : EventHandler
{
	// Filled by the subclass's own ReadDials from its own cvars. Fields
	// rather than constants because getting a panel readable in a headset
	// is a dozen small adjustments and every one of them otherwise costs
	// a rebuild.
	protected double AHEAD, UP, SIDE, HALF_W, HALF_H, BORDER;

	// Plane offsets, in the direction Put()'s own depth parameter moves a
	// point -- which is TOWARD THE VIEWER, not away. mFacingYaw is built at
	// RS_RarityToken.zs:1275 as atan2(toPlayer.Y, toPlayer.X), the angle
	// FROM the card TO the player, and aheadDir there is that same angle --
	// so a BIGGER depth moves a point further along "toward the player",
	// i.e. CLOSER to the camera, and draws IN FRONT of a smaller one. This
	// comment used to say the opposite ("Bigger X is further away"), which
	// was backwards from what the code actually does, not a change in the
	// code: Z_SHELL and Z_FACE were both positive, which pulled the shell
	// and the inset face IN FRONT of every text element in the card --
	// text never sets its own depth and sits at the Put() default of 0,
	// the FARTHEST of the three. The border, drawn full-card-size, then
	// covered the face and every line of text behind it. Both constants
	// are negative now, which is what "further away" actually requires.
	//
	// CUT TO ZERO, having already been cut 15x once and still reported
	// broken from the exact same angles on the actually-tested build.
	// ANY nonzero depth offset moves a billboard's distance from the
	// camera by a real, if small, amount, and DispatchBillboards
	// (hw_drawinfo.cpp) sorts EVERY billboard as an ordinary translucent
	// sprite by that distance -- there is no special-cased "layer"
	// concept at the engine level at all, only "nearer draws over
	// farther." A SMALL offset does not make that sort safer, it makes
	// the two distances close enough to be sensitive to floating-point
	// noise and viewing angle instead of reliably ordered -- which is
	// exactly a sort that is sometimes right and sometimes not: "rarely
	// if i stand in the right place the card draws correctly."
	//
	// Zero removes the ambiguity a different way. EVERY element in a
	// build -- Shell()'s border and face, then every Put() call after it
	// -- is submitted at the IDENTICAL distance, and Shell() runs FIRST,
	// before Build() draws a single line of content. A stable sort ties
	// on equal keys by resolving them in submission order, so text and
	// bars created after the plate keep landing on top of it for the
	// same reason they always did -- they were created after it -- with
	// no depth-based tie-break needed, and nothing left for a viewing
	// angle to destabilise.
	const Z_SHELL = 0.0;
	const Z_FACE  = 0.0;

	// -----------------------------------------------------------------
	// THE WEAPON WHEEL'S PALETTE, because all of these are the same
	// object seen in different places.
	//
	// The wheel's cards and these panels are all "a thing in the world
	// telling you about a gun", and they were drawn in unrelated schemes
	// -- the wheel in slate and near-white, the token card on flat
	// 6,7,10 black with a dozen one-off greys typed at the call site. Two
	// schemes for one idea reads as two systems, and those greys had
	// drifted far enough apart (168,166,158 / 150,148,158 / 128,122,104 /
	// 124,124,134 / 118,118,128) that no two labels matched.
	//
	// These are the wheel's own constants, not approximations of them.
	const TH_FACE  = 0x2E3440;   // plate
	const TH_GRAD  = 0xFF11141B; // and what it falls off to
	const TH_TEXT  = 0xD8DEE9;   // anything you are meant to read
	const TH_MUTED = 0x7A8494;   // labels, units, the second half of a pair
	const TH_FAINT = 0x4A5262;   // present but not being offered

	protected Array<int> mIds;
	protected Array<int> mProgressIds;   // the subset that animates in
	protected int mGroup;                // the shared transform; 0 when none
	protected int mBornTic;

	// EVERY ELEMENT'S OWN LOCAL OFFSET, parallel to mIds -- what Put() was
	// called with, kept around so Reface() can rebuild a position from it
	// under a NEW mFacingYaw. Without this, re-orienting alone desyncs the
	// card from itself: an element's WORLD position already depends on
	// yaw (Put()'s aheadDir/rightDir are both built from mFacingYaw), so
	// turning the plate to face the player while leaving every element's
	// position pinned to the OLD yaw rotates the face out from under its
	// own contents. Reported exactly that way: "it only shows one half of
	// the card text depending on where im pointing my gun" -- the plate
	// was tracking, the rows were not, and which half of a now-rotated
	// plate still overlapped which now-stationary row was a function of
	// viewing angle.
	protected Array<double> mRight, mUp, mDepth;

	// -----------------------------------------------------------------
	// WHERE THE CARD ACTUALLY LIVES, and which way it faces -- set by the
	// subclass every tic, BEFORE Build() or SyncOrigin() runs.
	//
	// This replaced BBFL_VIEWLOCKED, which glued every element to an
	// offset from the PLAYER'S OWN HEAD -- a HUD panel wearing a 3D
	// costume, not a thing that can sit "beside the wheel" or "over the
	// drop", because it could never leave the space in front of your
	// face. Owner's read, and it was correct: "the data card and the
	// token card are locked to my hud and follow my view... the data
	// card is part of the weapon wheel... it lives right next to the
	// wheel." mOrigin is the token's own actor position, or the wheel's
	// own hand anchor -- never the viewer.
	protected Vector3 mOrigin;
	protected double  mFacingYaw;

	// THE SPIN, separate from mFacingYaw on purpose. mFacingYaw only ever
	// matters at BUILD time now (Put()'s own placement math, and
	// FreezeCentre() right after) -- mViewYaw is what Reface() actually
	// rotates by every tic, computed fresh each time from the card's own
	// FROZEN mCardCentre rather than from the drop. Two fields because
	// they answer two different questions: mFacingYaw decided where the
	// card's centre landed, once; mViewYaw decides which way the card
	// already sitting there should turn, continuously.
	protected double  mViewYaw;

	// THE CARD'S OWN PIVOT, frozen the tic it is built, never touched
	// again after that.
	//
	// mOrigin is the DROP's position, not the card's -- the card sits
	// AHEAD units displaced from it. The first cut of Reface() rebuilt
	// every element from mOrigin using the CURRENT mFacingYaw every tic,
	// which does not just rotate the card in place: aheadDir is itself a
	// function of yaw, so re-deriving position from (mOrigin, live yaw)
	// swings the card's whole CENTRE around mOrigin like an orbit, always
	// AHEAD units out along whichever direction the player currently is.
	// Reported plainly: "it needs to stay exactly in place where it
	// spawns, not moving at all apart from rotating to face me."
	//
	// FreezeCentre(), called once right after Build(), captures where
	// that orbit math placed the card on the ONE tic it is allowed to:
	// build time. Every tic after that, Reface() rotates every element's
	// OWN offset around THIS fixed point instead of re-deriving the
	// point itself -- the difference between a card spinning in place
	// and a card orbiting the token while spinning.
	protected Vector3 mCardCentre;

	// Call once, right after Build() -- BEFORE the first Reface() -- so
	// mDepth/mRight/mUp (which Put() recorded relative to mOrigin under
	// THIS SAME mFacingYaw) and mCardCentre agree on the same pivot.
	protected void FreezeCentre()
	{
		Vector3 aheadDir = (cos(mFacingYaw), sin(mFacingYaw), 0);
		Vector3 rightDir = (-sin(mFacingYaw), cos(mFacingYaw), 0);
		mCardCentre = mOrigin + aheadDir * AHEAD + rightDir * SIDE + (0, 0, UP);
	}

	// -----------------------------------------------------------------
	// THE FLOW. Two cursors and a unit, and that is the whole layout
	// engine.
	//
	// LINE is the type scale: one line of body text, as a share of the
	// card's half-height. Everything sizes in multiples of it, so a
	// card's proportions survive any Half Height its slider is set to and
	// the type never grows out of step with the box holding it.
	//
	// The rule this buys: elements cannot collide, because each consumes
	// the space it occupies, and a card cannot overflow, because the only
	// thing that grows is the middle band and it grows into space that is
	// by definition unclaimed.
	// -----------------------------------------------------------------
	private double mFlowTop, mFlowBot;

	// -----------------------------------------------------------------
	// LINE IS SOLVED FROM THE BUDGET, NOT GUESSED AT AS A FRACTION.
	//
	// It used to be HALF_H * 0.075 -- a coefficient calibrated by hand
	// against roughly twenty-six lines of content, with nothing anywhere
	// checking that the card still drew twenty-six lines.
	//
	// It stopped being twenty-six. Raising the type ladder and cutting
	// the writable height to 72% in one pass pushed the fixed furniture
	// past the space available, so FlowDown walked below where FlowUp had
	// walked up to, FlowLeft() clamped its negative band to zero, and
	// every stat row was built at zero height on top of the footer. The
	// flow's promise -- that a card cannot overflow -- only ever held
	// while the middle band had something left to absorb, and nothing
	// enforced that it did.
	//
	// Now the subclass declares how many lines it intends to draw and
	// LINE is whatever makes them fit. Overflow is impossible because the
	// type shrinks first, and the type is as large as the card can afford
	// rather than as large as one constant once assumed. To get bigger
	// text you now raise Half Height or Content Fit -- both sliders --
	// instead of editing a number that can silently disagree with the
	// layout it is sizing.
	// -----------------------------------------------------------------
	private double mLine;

	protected double LINE()  const { return mLine; }
	protected double PAD()   const { return BORDER + LINE() * 0.6; }

	// The writable half-height: what the plate offers, less the border,
	// scaled by the fit factor. PAD is deliberately NOT subtracted here --
	// it depends on LINE, which is what this is solving for, so its 1.2
	// lines are carried in the line count instead.
	protected double FitFrac() const
	{
		return clamp(CvInt("rs_card_fit", 72), 40, 100) / 100.0;
	}

	// Call at the top of a build, BEFORE FlowReset.
	//
	// totalLines is the whole card in LINE units -- every element's full
	// height plus every gap, plus what the middle band wants. Slightly
	// over is safe and slightly under is safe too: the band absorbs
	// whatever is left, so the only thing this has to get right is that
	// the FIXED furniture fits, which is the thing that broke.
	protected void FitLadder(double totalLines)
	{
		double writable = 2.0 * max(1.0, HALF_H * FitFrac() - BORDER);
		mLine = writable / max(totalLines + 1.2, 1.0);
	}

	// The inner edge. The border and the padding are not drawable space,
	// and every horizontal number should be measured against this rather
	// than against HALF_W -- the token card used to span to 0.99 * HALF_W,
	// which is underneath its own border.
	protected double INNER() const { return HALF_W - PAD(); }

	// -----------------------------------------------------------------
	// THE FIT FACTOR, and it exists because of a measured discrepancy
	// rather than a preference.
	//
	// A card specified at HALF_W 20 / HALF_H 11 -- 1.82 wide for tall --
	// renders at about 1.30, so the engine puts a vertical factor
	// somewhere between a quad's stated height and where a position at
	// the same magnitude lands. The visible consequence is exact and was
	// caught in a screenshot: the header and the weapon tag drew ABOVE
	// the plate and both footer lines drew BELOW it, while everything
	// between them sat correctly inside.
	//
	// The flow's own extent is therefore a FRACTION of the half-height
	// the plate is drawn at, not the whole of it. A slider rather than a
	// constant because the exact factor is the engine's, not this file's,
	// and dialling it in play costs seconds where guessing at it costs a
	// repack each time.
	//
	// It only ever shrinks the writable area, so the worst a wrong value
	// does is waste card -- never push content back outside the plate.
	// -----------------------------------------------------------------
	protected void FlowReset()
	{
		double fit = clamp(CvInt("rs_card_fit", 72), 40, 100) / 100.0;
		mFlowTop =  HALF_H * fit - PAD();
		mFlowBot = -HALF_H * fit + PAD();
	}

	// Take a band of half-height hh off the top and return its centre.
	// gap is the air left under it, in lines.
	protected double FlowDown(double hh, double gapLines = 0.5)
	{
		double c = mFlowTop - hh;
		mFlowTop = c - hh - LINE() * gapLines;
		return c;
	}

	// The same, walking up from the bottom edge.
	protected double FlowUp(double hh, double gapLines = 0.5)
	{
		double c = mFlowBot + hh;
		mFlowBot = c + hh + LINE() * gapLines;
		return c;
	}

	// What is left between the two cursors, and where its centre is. Rows
	// divide this rather than assuming a size, which is what makes a card
	// impossible to overflow.
	protected double FlowLeft() const   { return max(0.0, mFlowTop - mFlowBot); }
	protected double FlowMiddle() const { return (mFlowTop + mFlowBot) * 0.5; }

	// The raw bottom cursor, for a caller that needs to know where the
	// UNCONSUMED edge is -- a background plate sized to a section that
	// has not drawn yet, say, which has to be positioned before FlowUp
	// has moved the cursor at all.
	protected double FlowBottom() const { return mFlowBot; }

	// -----------------------------------------------------------------
	// THE TYPE LADDER. Four sizes, and every string on a card is one of
	// them.
	//
	// The token card ran on ten -- 2.2, 1.4, 1.3, 1.25, 1.15, 1.0, 0.9,
	// 0.85, 0.75, 0.6 in LINEs, picked per element. That is not a
	// hierarchy, it is ten slightly different sizes, and the eye reads it
	// as text that will not sit still.
	// -----------------------------------------------------------------
	// Raised across the board -- owner's call, everything on the card read
	// too small in a headset. The RATIOS are what the ladder is for, so
	// all four moved together rather than the smallest ones being nudged
	// until they were legible; that is how a ladder turns back into ten
	// unrelated sizes.
	// Bumped again on top of the clamp fix below -- the earlier raise had
	// been quietly discounted by Row()'s own geometric cap on the token
	// card (see the note at lineHH in RS_RarityToken.Row), so this is
	// really the first increase to reach the screen for stat rows.
	protected double T_TITLE() const { return LINE() * 2.00; }
	protected double T_HEAD()  const { return LINE() * 1.40; }
	protected double T_BODY()  const { return LINE() * 1.15; }
	protected double T_FINE()  const { return LINE() * 0.92; }

	protected int CvInt(string nm, int def)
	{
		let cv = CVar.FindCVar(nm);
		return cv ? cv.GetInt() : def;
	}

	// For reading a NUMBER-VALUED cvar that is not this card's own --
	// the wheel's wr_radius/wr_scale, say, both genuine floats where
	// CvInt's truncation would be wrong.
	protected double CvFloat(string nm, double def)
	{
		let cv = CVar.FindCVar(nm);
		return cv ? cv.GetFloat() : def;
	}

	// -----------------------------------------------------------------
	// One door for every element, so parking and flags cannot drift.
	//
	// TAKES HALF-EXTENTS, PASSES FULL ONES. The engine's width and height
	// are full extents -- BillboardBasis does `halfw = bb.width * 0.5` --
	// while every number in a card is a half-extent measured from its
	// centre. This conversion lives here, once: handing half-extents
	// straight through draws everything at half size while leaving every
	// POSITION correct, which looks like a font problem rather than a
	// units problem and cost a full debugging pass to see.
	//
	// WORLD-ANCHORED, NOT VIEW-LOCKED. Every element is placed as an
	// offset from mOrigin along mFacingYaw's own ahead/right/up axes,
	// using the ENGINE'S OWN canonical basis (g_levellocals.h,
	// BillboardBasis's header comment, "THE ONE TRUE BILLBOARD BASIS" --
	// face F = (cos y, sin y, 0), right R = (-sin y, cos y, 0)) rather
	// than re-derived or copied from the wheel's own "viewRight", which
	// turns out to be this canonical R's exact NEGATION -- (cos(y-90),
	// sin(y-90)) reduces to (sin y, -cos y), not (-sin y, cos y). That
	// header exists specifically because this exact class of mistake
	// shipped once already: "on 2026-08-08 all three [copies] were wrong
	// in the same way at once... right was the viewer's LEFT." Matching
	// its formula directly, not a second hand-copy of it, is the fix.
	//
	// bb.yaw IS this y with no bias for a BBF_FIXED, non-view-locked
	// billboard (BillboardBasis: useYaw = bb.yaw + yawBias, and yawBias
	// is documented as "not optional for BBFL_VIEWLOCKED" -- i.e. zero
	// otherwise) -- so mFacingYaw, passed straight through as the
	// billboard's own yaw below, means the same y on both sides.
	//
	// THE CARD'S OWN FACE POINTS ALONG mFacingYaw, not mFacingYaw + 180.
	// This codebase already has a bug-fixed answer for that exact
	// question -- the wheel's card facing used to be
	// atan2(-toMe.Y, -toMe.X), which "pushed all card contents BEHIND
	// the plate", and the fix was dropping the negation:
	// atan2(toMe.Y, toMe.X), toMe being the vector FROM the card TOWARD
	// the viewer. mFacingYaw is built the same way here (ahead = anchor
	// toward the viewer), so the plate's yaw is that angle directly.
	// -----------------------------------------------------------------
	protected int Put(double right, double up, double w, double h,
		int payload, int data, color col, string text = "", double depth = 0)
	{
		// mOrigin IS PART OF THIS, NOT ADDED SEPARATELY BY THE GROUP.
		//
		// First cut of this left mOrigin out of localPos on the assumption
		// that SetBillboardGroupOrigin adds it on top of each member's own
		// (relative) position -- it does not. A group's origin is the
		// SCALE PIVOT, nothing more; every element's own `pos` has to be
		// its real, full position on its own. Confirmed against the code
		// this replaced: the OLD, working view-locked Put() ALSO put the
		// full (AHEAD, SIDE, UP) triple into both the group's origin AND
		// every member's own position -- never a relative-only offset in
		// the members -- and that pattern is kept here, just in world
		// space instead of view space. Leaving mOrigin out put every
		// element within a few dozen units of world (0,0,0), nowhere near
		// the token or the wheel -- rendering, just never where anyone
		// was standing.
		Vector3 aheadDir = (cos(mFacingYaw), sin(mFacingYaw), 0);
		Vector3 rightDir = (-sin(mFacingYaw), cos(mFacingYaw), 0);
		Vector3 localPos = mOrigin + aheadDir * (AHEAD + depth) + rightDir * (SIDE + right) + (0, 0, UP + up);

		int id = level.AddBillboardPersistent(
			localPos, w * 2.0, h * 2.0,
			mFacingYaw, 0, LevelLocals.BBF_FIXED,
			payload, data, col,
			LevelLocals.BBFL_PERSISTENT | LevelLocals.BBFL_NOHIT,
			0, text);
		if (id)
		{
			mIds.Push(id);
			// Parallel to mIds by construction -- pushed in the same
			// branch, in the same order, so index i in one is always
			// index i in the other. Reface() rebuilds localPos from
			// these under whatever mFacingYaw is current, the identical
			// formula this function just used under the yaw of the tic
			// the element was born on.
			mRight.Push(right);
			mUp.Push(up);
			mDepth.Push(depth);
			// Every element joins the group, so a grow scales the card as
			// an object -- sizes AND the gaps between them. An element
			// left out would stay full size inside a collapsing card,
			// which reads as a rendering fault.
			if (mGroup) level.SetBillboardGroup(id, mGroup);
		}
		return id;
	}

	// -----------------------------------------------------------------
	// A TEXT QUAD IS SIZED FROM ITS STRING, NEVER GUESSED AT.
	//
	// This is the single most load-bearing rule in this file, and it is
	// not obvious from script.
	//
	// BB_TEXT does not draw at the size you ask for. It FITS the string
	// to the quad -- hw_sprites.cpp:2074 takes
	//     scale = min(width / widestLine, height / blockHeight)
	// -- so whichever axis runs out first decides the type size. Hand a
	// short string a wide box and the height term wins and it draws at
	// the height you meant; hand a long one the same box and the WIDTH
	// term wins instead and it silently draws smaller. The token card
	// sized every box independently of its contents, so which term won
	// varied element by element and no ladder could have survived it.
	//
	// Measuring first and sizing the quad to the answer guarantees the
	// height term wins, which makes the requested size the drawn size. A
	// string too long for its space still shrinks -- it has to -- but it
	// shrinks HERE, once, by a stated amount, instead of by whatever
	// arithmetic fell out of a guessed box.
	//
	// MeasureBillboardText takes a FULL height and returns a FULL width,
	// while everything in a card is a half-extent. Both conversions live
	// here so no caller has to remember either.
	// -----------------------------------------------------------------
	protected double TextHW(string s, double lineHH)
	{
		double w = level.MeasureBillboardText(s, lineHH * 2.0);
		// Zero means no SDF atlas is loaded, which the native documents
		// as "estimate it yourself" rather than as an empty string. Half
		// a line per character keeps a card laid out on a machine that
		// would otherwise draw it as one long overlap.
		if (w <= 0.0) w = s.Length() * lineHH * 0.62;
		return w * 0.5;
	}

	// Centred on cx. maxHW is the space genuinely available; a string
	// wider than that comes down in size until it fits, keeping its
	// aspect, so it stays on the ladder rather than being squashed.
	protected int TextMid(double cx, double up, double lineHH, string s, color col,
		double maxHW = 0)
	{
		double hw = TextHW(s, lineHH);
		if (maxHW > 0 && hw > maxHW) { lineHH *= maxHW / hw; hw = maxHW; }
		return Put(cx, up, hw, lineHH, LevelLocals.BB_TEXT, 0, col, s);
	}

	// Anchored by an EDGE rather than a centre. A centred box whose width
	// depends on its contents moves BOTH its edges when the contents
	// change, which is why columns cannot be made to line up while every
	// call site passes a centre.
	protected int TextLeft(double leftX, double up, double lineHH, string s, color col,
		double maxHW = 0)
	{
		double hw = TextHW(s, lineHH);
		if (maxHW > 0 && hw > maxHW) { lineHH *= maxHW / hw; hw = maxHW; }
		return Put(leftX + hw, up, hw, lineHH, LevelLocals.BB_TEXT, 0, col, s);
	}

	protected int TextRight(double rightX, double up, double lineHH, string s, color col,
		double maxHW = 0)
	{
		double hw = TextHW(s, lineHH);
		if (maxHW > 0 && hw > maxHW) { lineHH *= maxHW / hw; hw = maxHW; }
		return Put(rightX - hw, up, hw, lineHH, LevelLocals.BB_TEXT, 0, col, s);
	}

	// A hairline. A panel a tenth of a line tall rather than a second
	// graphic to keep in sync.
	//
	// ALPHA GOES THROUGH SetBillboardAlpha, NOT THROUGH THE COLOUR --
	// ProcessBillboard does `ThingColor.a = 255` and throws the colour's
	// own alpha away, so a "half-strength" rule drew at full strength.
	protected void Rule(double y, color c, double frac = 0.88)
	{
		int id = Put(0, y, HALF_W * frac, LINE() * 0.1, LevelLocals.BB_PANEL, 0, c);
		if (id) level.SetBillboardAlpha(id, 0.47);
	}

	// -----------------------------------------------------------------
	// THE SHELL: A FIELD IN A TIER-COLOURED BORDER.
	//
	// The first version of this tinted the whole FIELD with the tier
	// colour at low alpha, and that fails twice over. A wash behind text
	// eats the contrast the text needs -- red "worse" numbers on a red
	// Cursed card, green ones on a green Common card -- so the thing the
	// card exists to say goes quiet. And it makes rarity a MOOD rather
	// than a fact: a 16% tint is hard to name from across a room where a
	// hard border is unmistakable.
	//
	// So the rarity is the EDGE. The tier plate sits further out at full
	// size, the field is inset in front of it, and the strip of colour
	// left showing around it IS the border. Two quads, no frame graphic,
	// nothing to keep in sync.
	//
	// The field carries a gradient rather than being flat: that is what
	// stops a quad reading as a rectangle pasted into the air, because it
	// gives the surface a direction to be lit from. It is most of why the
	// wheel's cards look like objects.
	// -----------------------------------------------------------------
	// THE CORNER RADIUS IS A DIAL NOW, because BB_PANEL's is not.
	//
	// BB_PANEL is a stretched TEXTURE (bbpanel) -- hw_sprites.cpp says so
	// outright, and names the cost: "a rounded plate stretched to a
	// non-square billboard has its corner radius stretched with it". A
	// landscape card therefore gets landscape corners, which is exactly
	// the "too round" on a card that just got wider.
	//
	// BB_SDFPANEL solves its shape in a shader instead and reads a corner
	// radius and a border width out of `data`, a nibble each
	// (hw_sprites.cpp:2610). So the radius stops being a property of the
	// artwork and becomes a number.
	//
	// WITH A WAY BACK. BB_SEGMENT drew nothing at row size on this very
	// card while every neighbouring payload drew fine, so an unverified
	// payload holding the entire plate is not a bet worth making blind:
	// rs_card_sdf 0 returns to BB_PANEL live, no repack, and the card is
	// merely round again instead of absent.
	protected void Shell(color tierCol)
	{
		bool sdf = CvInt("rs_card_sdf", 1) != 0;
		int  rad = clamp(CvInt("rs_card_round", 3), 0, 15);
		int  kind = sdf ? LevelLocals.BB_SDFPANEL : LevelLocals.BB_PANEL;

		// Border width stays 0 on both: the BORDER this card has always
		// drawn is the tier plate showing around an inset face, and a
		// second border from the shader would sit inside that one.
		int borderId = Put(0, 0, HALF_W, HALF_H, kind, sdf ? rad : 0,
			tierCol, "", Z_SHELL);
		if (borderId) level.SetBillboardAlpha(borderId, 0.95);

		// The inner plate's radius comes down with its size, or the face
		// corners bulge outside the border's.
		int innerRad = sdf ? max(0, rad - 1) : 0;

		int faceId = Put(0, 0, HALF_W - BORDER, HALF_H - BORDER,
			kind, innerRad, TH_FACE, "", Z_FACE);
		if (faceId)
		{
			level.SetBillboardAlpha(faceId, 0.94);
			level.SetBillboardGradient(faceId, TH_GRAD);
		}

		// -------------------------------------------------------------
		// GLOSS, THE WEAPON WHEEL'S OWN TRICK, and it is free here rather
		// than built again: func_sdfpanel.fp reads its highlight strength
		// off the SAME green channel SetBillboardGlow already writes for
		// the halo (its own comment: "same packing as the other field
		// payloads"). The shader's words for what it buys: "This is what
		// stops a card reading as a coloured rectangle and starts it
		// reading as an object with a SURFACE" -- tied to the viewer, so
		// it slides as you turn your head rather than sitting on the
		// plate like a painted stripe.
		//
		// Only on the SDF path -- BB_PANEL is a sampled texture with no
		// field to read, which is the same reason it cannot glow either,
		// and rs_card_sdf 0 already exists as the way back.
		// -------------------------------------------------------------
		if (sdf && faceId)
			level.SetBillboardGlow(faceId, 0.7, 0.22);
	}

	// Tear down every element and the transform they share.
	//
	// Members first, then the group. A group outliving its members is a
	// leak the engine will not report -- ids are never recycled, so it
	// would sit there scaling nothing until the level ended.
	protected void ClearCard()
	{
		for (int i = 0; i < mIds.Size(); i++)
			level.RemoveBillboard(mIds[i]);
		mIds.Clear();
		mProgressIds.Clear();
		mRight.Clear();
		mUp.Clear();
		mDepth.Clear();

		if (mGroup) level.RemoveBillboardGroup(mGroup);
		mGroup = 0;
	}

	// Open the group. Called BEFORE the first Put, because Put joins
	// whatever group is live at the time. The group's own origin is
	// mOrigin now (a world point, not the old (AHEAD, SIDE, UP) triple,
	// which only meant anything under the view-locked scheme this
	// replaced) -- the SCALE PIVOT for growth and breathing lives here.
	protected void OpenGroup()
	{
		mGroup = level.AddBillboardGroup(mOrigin);
		mBornTic = level.maptime;
	}

	// Keeps the SCALE PIVOT honest every tic -- NOT a live translation.
	//
	// First cut of this claimed the opposite: that a group's origin
	// composes with each member's own position, so updating it here would
	// move the whole card without a rebuild. It does not compose --
	// Put()'s own note covers the actual mechanics -- a group's origin is
	// only where growth and breathing scale FROM. Every element's real
	// position is baked into it directly at Build() time and does not
	// move again until the next one.
	//
	// Still worth calling every tic rather than only at Build(): if
	// mOrigin drifts between rebuilds for any reason, the NEXT grow or
	// breathe pulse pivots from the current point instead of a stale one.
	// In practice neither card's anchor actually moves while shown -- the
	// token's drop does not move, and the wheel's own anchor is resolved
	// once and held for as long as it stays open -- so this mostly costs
	// nothing and buys safety against a future anchor that does move.
	// Safe to call before the group exists; it is simply a no-op that tic.
	// mCardCentre, NOT mOrigin. The group's origin is the SCALE PIVOT --
	// what Breathe() (below) scales every element's position AROUND,
	// continuously, every tic for as long as the card is shown, not just
	// during the one-shot grow-in. Breathe() never settles at exactly
	// 1.0 (it oscillates 1.0 +/- amp forever), so this was never a
	// one-time error: every tic, every element's position was pulled
	// slightly toward or away from mOrigin (the DROP) instead of toward
	// or away from mCardCentre (the CARD's own middle) -- pivoting a
	// rigid object's breathing around a point that is not its own centre
	// reads as a continuous, small skew rather than a clean pulse, and
	// compounds with whatever else is already unstable about a card this
	// close to what it pivots around.
	protected void SyncOrigin()
	{
		if (mGroup) level.SetBillboardGroupOrigin(mGroup, mCardCentre);
	}

	// -----------------------------------------------------------------
	// SPIN IN PLACE, EVERY TIC -- around the card's own FROZEN centre,
	// never re-deriving where that centre is.
	//
	// mViewYaw updates every tic (the token sets it fresh in WorldTick,
	// from mCardCentre, before calling this) -- but updating the FIELD
	// was never the same thing as updating the BILLBOARDS. Put() bakes
	// yaw into BOTH the orientation it hands AddBillboardPersistent AND
	// the position it computes, at CREATION time, and nothing touched
	// either again after that: a card built while you stood north of it
	// kept facing north forever, correct only from the one angle it
	// happened to be born at. Owner's report: "needs to face me at all
	// times."
	//
	// THE FIRST CUT OF THIS ONLY RE-ORIENTED, and that was a worse bug
	// than the one it fixed: the plate turned to track the player, but
	// every element's WORLD POSITION stayed pinned to the OLD yaw's
	// aheadDir/rightDir -- so the face rotated out from under its own
	// contents. "it only shows one half of the card text depending on
	// where im pointing my gun" -- fixed by recomputing position too,
	// but from mOrigin, which was the SECOND bug: aheadDir is itself a
	// function of yaw, so re-deriving position from (mOrigin, live yaw)
	// every tic does not spin the card in place, it re-anchors the whole
	// card's CENTRE, always AHEAD units out along wherever the player
	// currently is -- an orbit around the drop, not a card spinning on
	// its own axis. "it needs to stay exactly in place where it spawns,
	// not moving at all apart from rotating to face me."
	//
	// The actual fix: mCardCentre is a POINT, frozen once at build time
	// (FreezeCentre(), called right after Build() -- see RS_RarityToken's
	// own note on why the ordering there matters). Every element's
	// (mRight, mUp, mDepth) is that element's own offset from THAT point,
	// measured under the SAME yaw Put() built it with. Rotating those
	// offsets by a NEW yaw and re-adding them to the SAME frozen centre
	// is what actually spins a rigid card around its own middle instead
	// of sliding its middle around the token.
	//
	// Cheap and safe to call unconditionally every tic even though nothing
	// about most cards' facing changes tic to tic in the way their origin
	// can: moving/orienting a billboard to where it already is is a
	// no-op cost, not a correctness risk, and the alternative -- tracking
	// whether mViewYaw actually changed since last tic -- is a second
	// piece of state to keep in sync with the first for a comparison this
	// cheap to just always do instead.
	protected void Reface()
	{
		Vector3 aheadDir = (cos(mViewYaw), sin(mViewYaw), 0);
		Vector3 rightDir = (-sin(mViewYaw), cos(mViewYaw), 0);

		for (int i = 0; i < mIds.Size(); i++)
		{
			Vector3 pos = mCardCentre
				+ aheadDir * mDepth[i]
				+ rightDir * mRight[i]
				+ (0, 0, mUp[i]);

			level.MoveBillboard(mIds[i], pos);
			level.OrientBillboard(mIds[i], mViewYaw, 0, LevelLocals.BBF_FIXED);
		}
	}

	// And start it growing, which is a SEPARATE call because it has to
	// happen AFTER the build: a group with no members yet animates
	// nothing. It is not an error, it just silently does not grow, which
	// is the worst of both -- so the two halves stay apart rather than
	// being folded into one convenient call that would be wrong half the
	// time.
	protected void StartGrow(int growTics)
	{
		if (mGroup) level.AnimateBillboardGroup(mGroup, 0.0, 1.0, growTics);
	}

	// -----------------------------------------------------------------
	// THE CARD BREATHES, the wheel's move for "a card you are not
	// actively doing anything to should still not look dead". The
	// wheel's own words for it: "A colour change is a state you have to
	// notice; a card that is moving is one you cannot miss, and motion
	// survives being in the corner of your eye where colour does not."
	//
	// The wheel only breathes the HOVERED card, because on a ring of
	// eight the breathing IS the "this one" signal and every card
	// breathing at once would cancel the message. A stat card has no
	// hover -- it is the only thing this system draws once open -- so
	// there is nothing for breathing to distinguish it FROM, and the
	// whole card takes the pulse instead.
	//
	// Same sine, same period as the wheel's PULSE_SPEED (14 deg/tic,
	// ZScript trig is degrees): never stops, never snaps, and a player
	// who has looked at both cards gets the same organism twice rather
	// than two unrelated animation systems.
	//
	// SetBillboardGroupScale is a MULTIPLIER on top of whatever
	// AnimateBillboardGroup already set, not a replacement for it -- so
	// this composes with the one-shot grow-in instead of fighting it: a
	// growing card breathes as it grows, a settled one breathes at 1.0
	// as its centre.
	// -----------------------------------------------------------------
	protected void Breathe(int bornTic, double amp = 0.012)
	{
		if (!mGroup || amp <= 0.0) return;
		double t = (level.maptime - bornTic) * 14.0;
		level.SetBillboardGroupScale(mGroup, 1.0 + amp + amp * sin(t));
	}

	// -----------------------------------------------------------------
	// The row model carries Font.CR_ ramp indices, because its first
	// reader was a menu and DrawText takes exactly that. A billboard
	// takes an RGB colour, so the two have to be bridged somewhere, and
	// here is the only honest place: the model should not start carrying
	// RGB for one renderer's benefit, and RS_TierPalette must not grow a
	// second table -- its own header says a surface "calls this, it does
	// not write a table".
	//
	// These are the console ramps' mid-tones. Anything unlisted comes
	// back as the readable text colour, which is legible and wrong rather
	// than invisible and wrong.
	// -----------------------------------------------------------------
	// -----------------------------------------------------------------
	// THE STAT FAMILY SPLIT, named once so both cards read the same
	// meaning into the same hue. RS_Screens.BuildWeaponCard is the
	// model's own copy of this exact split (Font.CR_FIRE / Font.CR_SAPPHIRE),
	// spelled there because AddRow takes a CR_ index, not a colour --
	// this is the RGB side of the identical decision, for the token
	// card's stat labels, which have no menu-side row to draw from.
	//
	// FIRE for offense, SAPPHIRE for handling -- not orange/cyan. Those two
	// already mean something on this HUD: RS_StatusBar's
	// HAND_MAIN/HAND_OFF are Font.CR_ORANGE and Font.CR_CYAN, and the
	// token card's own hand chip matches them in RGB. A stat family
	// cannot reuse that pair without also reading as "mainhand" or
	// "offhand" on a card that already shows a REAL hand chip in exactly
	// those colours two lines away.
	//
	// Matched by the stat's own display label, so a candidate the token
	// card decides to show and the corresponding row on the weapon grid
	// land on the same colour without either file naming the other's
	// stat set. CAPACITY stays neutral on both -- logistics, not
	// offense or handling.
	// -----------------------------------------------------------------
	protected static color StatFamilyColor(string label)
	{
		string s = label.MakeUpper();
		if (s == "DAMAGE" || s == "DPS" || s == "CRIT" || s == "CRIT MULT" || s == "PELLETS")
			return Color(255, 255, 130, 40);      // Font.CR_FIRE
		if (s == "ACCURACY" || s == "VELOCITY" || s == "ROF" || s == "RELOAD" || s == "CHOKE")
			return Color(255, 80, 170, 255);      // Font.CR_SAPPHIRE
		return Color(255, 122, 132, 148);         // TH_MUTED -- neutral
	}

}
