// =====================================================================
// RS_HealthBars -- world-space health bars over monsters and players.
// ---------------------------------------------------------------------
// SOURCE: coldcite's "Top HP Bars" 1.04, itself based on Nash Muhandes'
// SpriteShadow. Released with "feel free to use this in your mods, you
// don't have to ask my permission". Pulled in rather than run as a
// side-loaded mod so it can (a) be versioned with everything else and
// (b) read RS_MonsterMaster.TierMaxHealth, which is the number it was
// getting wrong.
//
// WHY A WORLD ACTOR AND NOT A HUD DRAW
//   The bar is a real sprite standing in the level over the monster's
//   head, not an overlay drawn in screen space. That is upstream's one
//   genuinely important decision and it is why this mod was worth
//   porting instead of writing fresh: screen-space health bars have no
//   depth, and in VR a flat bar pinned to the view over a monster
//   that is eight feet away is both wrong and unpleasant to look at.
//   If this is ever rewritten, it stays in the world.
//
// DEFAULT IS 1:1 WITH UPSTREAM. Same art, same 5% steps, same scale,
// same offset, same two styles, chip OFF. The only behavioural change
// at default settings is the health-ceiling fix below -- which is a bug
// fix, not a restyle. New ideas are opt-in; they do not touch Default.
//
// ---------------------------------------------------------------------
// THE BUG THIS PORT FIXES
//
//   PctHP = Health / SpawnHealth() * 100;   // upstream
//
// SpawnHealth() does NOT return the health the actor spawned with. It
// returns the Health property off the actor's CLASS DEFAULT block.
// Anything that raises a monster's health above its class default --
// Colourful Hell's colour multipliers, our own tier ladder, an archvile
// heal, a support aura -- therefore divides by too small a number,
// computes >=100%, and gets clamped to the full frame. The bar sits
// full for most of the fight and then drains in the last fraction.
//
// The copy this was pulled from had a hand-edit that suppressed the bar
// entirely while a monster was above its class default. That traded a
// wrong bar for no bar at all on exactly the monsters that most need
// one, and did not survive a mid-fight heal or a retier. It is gone;
// the denominator is fixed instead. See TrueMaxHealth().
// ---------------------------------------------------------------------
//
// THE 5% STEPS ARE STRUCTURAL, NOT LAZINESS. Worth knowing before
// anyone tries to make the fill continuous: the art is 21 baked frames
// and the sprite's origin is its horizontal CENTRE (Offset 56 of 112).
// Scaling X therefore shrinks the bar toward its middle, not from one
// end, so a continuous fill needs the actor moved sideways in SCREEN
// space -- which a world-space billboard cannot do, because "sideways"
// is view-relative and changes as you walk around the monster. A
// continuous bar means giving up either the world-space placement or
// this art. Both are deliberate. Don't spend an afternoon rediscovering
// this.
//
// REGISTRATION -- three things, all of which fail SILENTLY if missed:
//   1. This file must be in zscript.txt.                       (it is)
//   2. RS_HealthBarHandler must be in MAPINFO.txt's
//      GameInfo { AddEventHandlers = ... }. An EventHandler not
//      listed there does not exist at runtime -- that is what left
//      RS_MonsterDebug's whole menu dead.                      (it is)
//   3. The sprites must be registered by a state block. See
//      RS_HPBarSprites -- it looks like dead code and is not.
//
// ART. The bar frames (graphics/HP_A_*.png, HP_B_*.png) and their
// TEXTURES entries are upstream's, unchanged. The threshold marks
// (HP_M_*.png) and the boss bracket (HP_FRAME.png) are generated
// geometry added here -- see the commit that introduced them for the
// script.
//
// NOTHING IN THIS FEATURE TOUCHES A MONSTER FILE, and it should stay
// that way. The only thing it reads from the monster side is
// RS_MonsterMaster's own public TierMaxHealth and ThresholdFired(),
// both already there for other reasons.
// =====================================================================

// ---------------------------------------------------------------------
// SPRITE REGISTRATION -- DO NOT DELETE THIS CLASS.
//
// It is never spawned, never referenced, and has no behaviour. It
// exists because GZDoom only enters a sprite name into the sprite table
// if some actor STATE references it, and this bar picks its frame at
// runtime with GetSpriteIndex() rather than by walking states. Without
// a state block naming every frame, GetSpriteIndex() returns nothing and
// the bar renders blank.
//
// Upstream did this with 44 one-line dummy classes. Same trick, one
// class, now also covering the threshold marks and the boss bracket.
// If you add a style with new sprite names, add them here too.
// ---------------------------------------------------------------------
class RS_HPBarSprites : Actor
{
	States
	{
	Spawn:
		HAXX A 1; HA99 A 1; HA95 A 1; HA90 A 1; HA85 A 1; HA80 A 1;
		HA75 A 1; HA70 A 1; HA65 A 1; HA60 A 1; HA55 A 1; HA50 A 1;
		HA45 A 1; HA40 A 1; HA35 A 1; HA30 A 1; HA25 A 1; HA20 A 1;
		HA15 A 1; HA10 A 1; HA05 A 1; HA00 A 1;
		HBXX A 1; HB99 A 1; HB95 A 1; HB90 A 1; HB85 A 1; HB80 A 1;
		HB75 A 1; HB70 A 1; HB65 A 1; HB60 A 1; HB55 A 1; HB50 A 1;
		HB45 A 1; HB40 A 1; HB35 A 1; HB30 A 1; HB25 A 1; HB20 A 1;
		HB15 A 1; HB10 A 1; HB05 A 1; HB00 A 1;
		HM00 A 1; HM05 A 1; HM10 A 1; HM15 A 1; HM20 A 1; HM25 A 1;
		HM30 A 1; HM35 A 1; HM40 A 1; HM45 A 1; HM50 A 1; HM55 A 1;
		HM60 A 1; HM65 A 1; HM70 A 1; HM75 A 1; HM80 A 1; HM85 A 1;
		HM90 A 1; HM95 A 1;
		HFRM A 1;
		Stop;
	}
}

// ---------------------------------------------------------------------
// Shared half: owner, the health ceiling, and percentage -> sprite.
// ---------------------------------------------------------------------
class RS_HPBarBase : Actor
{
	Default
	{
		+NOINTERACTION
	}

	// The sprite art is 11px tall with its origin on the bottom row, so
	// a bar occupies [Z, Z + 11*scale] in world units. The chip
	// underline is placed off this.
	const RS_BAR_PX_H = 11.0;

	// Chip modes, matching rs_hpbar_chip.
	const RS_CHIP_OFF   = 0;
	const RS_CHIP_UNDER = 1;
	const RS_CHIP_LAYER = 2;

	// Who this bar belongs to.
	Actor ownerRef;

	// Running peak health, for owners we cannot ask directly. See
	// TrueMaxHealth(). Zero means "not seeded yet".
	protected int rsPeakHP;

	// Cached CVar HANDLES. The handle lookup is the expensive part
	// (string-keyed); reading GetInt()/GetFloat() off a held handle is
	// cheap and still live, so the options menu keeps working
	// immediately. Upstream called FindCVar five times per bar per tic,
	// which at a roomful of awake monsters is a few hundred string
	// lookups every tic for no gain.
	protected CVar cvStyle, cvScale, cvOffset, cvFullBright, cvStealth, cvEnable;
	protected CVar cvChip, cvChipSpeed, cvChipHold;
	protected CVar cvMarks, cvBossFrame, cvBossHP;

	protected void RS_CacheCVars()
	{
		if (!cvStyle)      cvStyle      = CVar.FindCVar("rs_hpbar_style");
		if (!cvScale)      cvScale      = CVar.FindCVar("rs_hpbar_scale");
		if (!cvOffset)     cvOffset     = CVar.FindCVar("rs_hpbar_offset");
		if (!cvFullBright) cvFullBright = CVar.FindCVar("rs_hpbar_fullbright");
		if (!cvStealth)    cvStealth    = CVar.FindCVar("rs_hpbar_stealth");
		if (!cvEnable)     cvEnable     = CVar.FindCVar("rs_hpbar_enable");
		if (!cvChip)       cvChip       = CVar.FindCVar("rs_hpbar_chip");
		if (!cvChipSpeed)  cvChipSpeed  = CVar.FindCVar("rs_hpbar_chip_speed");
		if (!cvChipHold)   cvChipHold   = CVar.FindCVar("rs_hpbar_chip_hold");
		if (!cvMarks)      cvMarks      = CVar.FindCVar("rs_hpbar_marks");
		if (!cvBossFrame)  cvBossFrame  = CVar.FindCVar("rs_hpbar_bossframe");
		if (!cvBossHP)     cvBossHP     = CVar.FindCVar("rs_hpbar_boss_hp");
	}

	// Style letter. NOT a `static const String[]` indexed by the cvar,
	// which is what upstream used -- that construct does not reliably
	// resolve on this engine build and has produced three separate
	// "Unknown identifier" bugs in this repo. See CLAUDE.md.
	protected String RS_StyleLetter(int s)
	{
		return (s == 1) ? "B" : "A";
	}

	// Which of the 21 frames a percentage lands on, as the two digits in
	// the sprite name. 99 is the FULL frame, not 99%; the bucket
	// arithmetic can never produce it, so it doubles as the sentinel.
	//
	// Plain arithmetic where upstream ran a 19-iteration search per bar
	// per tic. Identical result, including negative health (a corpse)
	// landing on 00.
	protected int RS_Bucket(double pct)
	{
		if (pct >= 100.0) return 99;
		return clamp((int(pct) / 5) * 5, 0, 95);
	}

	protected String RS_FrameName(int style, bool invuln, double pct)
	{
		String base = String.Format("H%s", RS_StyleLetter(style));
		if (invuln)
			return String.Format("%sXX", base);
		return String.Format("%s%02d", base, RS_Bucket(pct));
	}

	// -----------------------------------------------------------------
	// The health ceiling. This is the fix; see the file header.
	//
	// Two sources, in order:
	//   1. RS_MonsterMaster.TierMaxHealth -- exact for our own monsters,
	//      and it MOVES when one retiers, so it is read live every tic
	//      rather than latched. A monster that tiers up mid-fight gets a
	//      correct bar against its new ceiling immediately.
	//   2. Everything else -- latch the running peak, seeded from
	//      SpawnHealth(). Self-corrects within a tic or two of any mod
	//      applying a spawn-time multiplier (they land after
	//      WorldThingSpawned, so reading health once at spawn is too
	//      early), and can never under-report.
	//
	// The peak latch does mean a monster healed above its own maximum
	// and then knocked back down reads below full. That is the honest
	// answer for an overheal and is deliberate.
	// -----------------------------------------------------------------
	int TrueMaxHealth()
	{
		if (!ownerRef)
			return 1;

		let mm = RS_MonsterMaster(ownerRef);
		if (mm && mm.TierMaxHealth > 0)
			return mm.TierMaxHealth;

		if (rsPeakHP <= 0)
			rsPeakHP = max(1, ownerRef.SpawnHealth());
		rsPeakHP = max(rsPeakHP, ownerRef.Health);
		return rsPeakHP;
	}

	// What this bar draws. Overridden by the chip layer.
	virtual void RS_UpdateSprite()
	{
		int maxhp = TrueMaxHealth();
		double pct = (maxhp > 0) ? (double(ownerRef.Health) / double(maxhp)) * 100.0 : 0.0;

		Sprite = GetSpriteIndex(RS_FrameName(cvStyle ? cvStyle.GetInt() : 0,
		                                     ownerRef.bInvulnerable, pct));
		Frame = 0;
		Angle = 0;
	}

	// "Allow Stealth" -- inherit the owner's alpha and renderstyle, so a
	// spectre's bar is as hard to see as the spectre.
	//
	// Lives on the base so EVERY bar applies it TO ITSELF. A_SetRenderStyle
	// is an action function, and this repo has already been bitten by
	// calling one from a plain method or on another actor (see the note in
	// RS_MonsterMaster.ApplyTier). The main bar driving the chip's
	// renderstyle from its own Tick would be exactly that; each actor
	// doing it in its own Tick is the shape upstream shipped and knows
	// works.
	protected void RS_ApplyStealth()
	{
		if (cvStealth && cvStealth.GetInt())
			A_SetRenderStyle(ownerRef.Alpha, ownerRef.GetRenderStyle());
	}

	override void Tick()
	{
		Super.Tick();

		if (!ownerRef)
			return;

		RS_CacheCVars();
		RS_ApplyStealth();
		RS_UpdateSprite();
	}
}

// ---------------------------------------------------------------------
// CHIP DAMAGE -- the trailing bar showing where health just was.
//
// Driven entirely by RS_HPBar, which owns the lagging health value and
// pushes it in. This actor holds no logic of its own beyond drawing.
//
// It ALWAYS uses style B (the flat red set) regardless of the main
// bar's style, because "red where health used to be" is the read we
// want and it needs no new art. It also means the chip stays legible
// behind style A's green.
// ---------------------------------------------------------------------
class RS_HPBarChip : RS_HPBarBase
{
	// Pushed in by the main bar each tic.
	double chipPct;

	override void RS_UpdateSprite()
	{
		Sprite = GetSpriteIndex(RS_FrameName(1, false, chipPct));
		Frame = 0;
		Angle = 0;
	}
}

// ---------------------------------------------------------------------
// THRESHOLD MARK -- a gold tick above the bar at the next phase gate.
//
// Position is chosen by picking one of 20 pre-rendered sprites, because
// the tick's x offset is baked into the canvas. See the file header for
// why a billboard cannot be offset sideways at runtime.
// ---------------------------------------------------------------------
class RS_HPBarMark : RS_HPBarBase
{
	// Pushed in by the main bar: where the next gate sits, 0..100.
	double markPct;

	override void RS_UpdateSprite()
	{
		// Nearest 5%, not floor -- a mark is a point, and rounding a
		// 66% gate down to 65 rather than to the nearer 65 would be
		// arbitrary. (Both land on 65 here; nearest is still the right
		// rule for gates like 0.62.)
		int slot = clamp(int(round(markPct / 5.0)) * 5, 0, 95);
		Sprite = GetSpriteIndex(String.Format("HM%02d", slot));
		Frame = 0;
		Angle = 0;
	}
}

// ---------------------------------------------------------------------
// BOSS BRACKET -- corner pieces around the bar on high-health monsters.
//
// Its whole job is expectation-setting: a 5000 HP bar drains so slowly
// that without a signal it reads as broken rather than big.
// ---------------------------------------------------------------------
class RS_HPBarFrame : RS_HPBarBase
{
	override void RS_UpdateSprite()
	{
		Sprite = GetSpriteIndex("HFRM");
		Frame = 0;
		Angle = 0;
	}
}

// ---------------------------------------------------------------------
// The main bar. Owns everything that hangs off it -- the chip layer, the
// threshold mark, the boss bracket -- because all three need the same
// position, scale and visibility, and one actor computing that once and
// placing the others is cheaper and cannot drift out of sync.
// ---------------------------------------------------------------------
class RS_HPBar : RS_HPBarBase
{
	// How tall the underline chip is relative to the main bar, and the
	// gap between them -- both as fractions of full bar height, so they
	// track the Bar Size slider instead of needing their own.
	const RS_CHIP_UNDER_YSCALE = 0.4;
	const RS_CHIP_UNDER_GAP    = 0.15;

	// Mark sits above the bar by this fraction of bar height.
	const RS_MARK_GAP = 0.2;

	// The bracket art is 21px tall against the bar's 11, both centred,
	// so it hangs (21-11)/2 = 5px below the bar's bottom edge.
	const RS_FRAME_DROP_PX = 5.0;

	// Boss frame modes, matching rs_hpbar_bossframe.
	const RS_BOSSFRAME_OFF    = 0;
	const RS_BOSSFRAME_AUTO   = 1;
	const RS_BOSSFRAME_ALWAYS = 2;

	private RS_HPBarChip  rsChip;
	private RS_HPBarMark  rsMark;
	private RS_HPBarFrame rsFrame;

	// The lagging health value, in HEALTH UNITS (not percent, so it
	// stays correct across a retier that moves the ceiling).
	private double rsChipHP;
	private int    rsLastHP;
	private int    rsChipHold;
	private bool   rsChipSeeded;

	// Threshold-gate observation. See RS_LearnThresholds.
	private int  rsSeenFired;
	private bool rsGatesSeeded;

	// Cached for the same reason the CVar handles are: the mark path
	// wants this every tic, and EventHandler.Find walks the handler list.
	private RS_HealthBarHandler rsHandler;

	protected RS_HealthBarHandler RS_Handler()
	{
		if (!rsHandler)
			rsHandler = RS_HealthBarHandler(EventHandler.Find("RS_HealthBarHandler"));
		return rsHandler;
	}

	// -----------------------------------------------------------------
	// Advance the trailing value. Damage restarts a short hold, then it
	// drains toward current health at a rate proportional to MAX health,
	// so a 5000 HP boss's chip falls at the same visual speed as a
	// zombieman's rather than crawling.
	//
	// Healing snaps it up instantly -- a chip bar that lagged UPWARD
	// would read as damage that never happened.
	// -----------------------------------------------------------------
	private void RS_AdvanceChip(int cur, int maxhp)
	{
		if (!rsChipSeeded)
		{
			rsChipHP = cur;
			rsLastHP = cur;
			rsChipSeeded = true;
			return;
		}

		if (cur > rsChipHP)
			rsChipHP = cur;

		if (cur < rsLastHP)
			rsChipHold = cvChipHold ? cvChipHold.GetInt() : 10;

		rsLastHP = cur;

		if (rsChipHP > cur)
		{
			if (rsChipHold > 0)
			{
				rsChipHold--;
			}
			else
			{
				// Slider is percent of max health per SECOND.
				double rate = cvChipSpeed ? cvChipSpeed.GetFloat() : 60.0;
				double perTic = (double(maxhp) * (rate / 100.0)) / 35.0;
				rsChipHP = max(double(cur), rsChipHP - max(perTic, 0.01));
			}
		}
	}

	// Spawn/destroy the chip actor on demand rather than carrying one
	// per monster whether or not the feature is on -- this doubles the
	// actor count in a busy room otherwise.
	private void RS_SyncChipActor(int mode)
	{
		if (mode == RS_CHIP_OFF)
		{
			if (rsChip) { rsChip.Destroy(); rsChip = null; }
			return;
		}

		if (!rsChip)
		{
			let c = RS_HPBarChip(Spawn("RS_HPBarChip", Pos, NO_REPLACE));
			if (c) { c.ownerRef = ownerRef; rsChip = c; }
		}
	}

	// -----------------------------------------------------------------
	// THRESHOLD LEARNING.
	//
	// CheckThreshold's fraction is a literal at each call site -- nothing
	// stores it, so there is no table for the bar to read, and putting
	// one there would mean editing monster files this feature has no
	// business touching.
	//
	// So the bar learns instead. ThresholdFired(slot) is already public
	// and read-only; poll it, and the tic a slot flips from unfired to
	// fired IS the moment the gate tripped, so current health over max
	// is the gate's fraction. Hand it to the handler, which remembers it
	// PER MONSTER CLASS.
	//
	// The honest consequence: the first Baron you fight teaches the
	// system where Barons enrage, and every Baron after that shows the
	// mark before it happens. First of any given monster shows nothing.
	// A predictive mark on the very first encounter is not possible
	// without the monsters declaring their gates as data.
	//
	// Slots 0-3 only. Every gate in the tree today uses 0 or 1; polling
	// all 32 would be 32 calls per bar per tic to find nothing.
	// -----------------------------------------------------------------
	const RS_GATE_SLOTS = 4;

	private void RS_LearnThresholds(RS_MonsterMaster mm, int maxhp)
	{
		if (!mm || maxhp <= 0)
			return;

		for (int s = 0; s < RS_GATE_SLOTS; s++)
		{
			int bit = 1 << s;
			bool fired = mm.ThresholdFired(s);

			// Seed on the first pass: anything ALREADY fired when this
			// bar appeared did not fire on our watch, so we never saw
			// the health it fired at and must not record one.
			if (!rsGatesSeeded)
			{
				if (fired) rsSeenFired |= bit;
				continue;
			}

			if (fired && !(rsSeenFired & bit))
			{
				rsSeenFired |= bit;
				let h = RS_Handler();
				if (h)
					h.RS_LearnGate(mm.GetClassName(), s,
					               clamp(double(mm.Health) / double(maxhp), 0.0, 1.0));
			}
		}

		rsGatesSeeded = true;
	}

	override void Tick()
	{
		Super.Tick();

		if (ownerRef)
		{
			// Your own bar is hidden from your own first-person view,
			// but stays visible in a chasecam and to everyone else.
			if (ownerRef is "PlayerPawn" && players[consoleplayer].mo == ownerRef)
			{
				bInvisible = (players[consoleplayer].camera == players[consoleplayer].mo
				              && !(ownerRef.player.cheats & CF_CHASECAM));
			}
			else
			{
				bInvisible = (ownerRef.Health <= 0);
			}

			// Master off switch. Kept as a visibility flag rather than
			// a Destroy() so toggling it in the menu takes effect at
			// once, both ways, without waiting for respawns.
			if (cvEnable && !cvEnable.GetInt())
				bInvisible = true;

			// "Allow Stealth" already applied by RS_HPBarBase.Tick, on
			// this actor and on the chip independently.

			double sc = cvScale ? cvScale.GetFloat() : 0.3;
			Scale.X = sc;
			Scale.Y = sc;

			bBright = cvFullBright ? cvFullBright.GetInt() : false;

			// Height from the SPRITE, not the actor's Height property --
			// they disagree badly on tall or crouched monsters, and the
			// actor height is what made upstream's early versions park
			// bars in the middle of things.
			// CurState can be null on an actor mid-teardown or one whose
			// state machine has run off the end. Upstream dereferenced it
			// unguarded; its own 1.04 changelog lists "crashing issue
			// with some sprites", which is very likely this. Falling back
			// to actor Height only misplaces the bar for a tic.
			int spriteTexHeight = int(ownerRef.Height);
			if (ownerRef.CurState)
			{
				TextureID spriteTexture; bool spriteFlip; Vector2 spriteScale;
				[spriteTexture, spriteFlip, spriteScale] =
					ownerRef.CurState.GetSpriteTexture(ownerRef.SpriteRotation);
				if (spriteTexture)
					spriteTexHeight = TexMan.CheckRealHeight(spriteTexture);
			}

			double customOffset = 1.0 + (cvOffset ? cvOffset.GetFloat() : 0.1);
			int zpos = int(ownerRef.Pos.Z + ((spriteTexHeight * ownerRef.Scale.Y) * customOffset));
			SetOrigin((ownerRef.Pos.X, ownerRef.Pos.Y, zpos), true);

			// --- chip ---
			int mode = cvChip ? cvChip.GetInt() : RS_CHIP_OFF;
			int maxhp = TrueMaxHealth();
			RS_AdvanceChip(ownerRef.Health, maxhp);
			RS_SyncChipActor(mode);

			if (rsChip)
			{
				double curPct  = (maxhp > 0) ? (double(ownerRef.Health) / double(maxhp)) * 100.0 : 0.0;
				double chipPct = (maxhp > 0) ? (rsChipHP / double(maxhp)) * 100.0 : 0.0;

				rsChip.chipPct = chipPct;
				rsChip.bBright = bBright;

				// Show it ONLY when it would actually differ from the
				// main bar. Two reasons, and the second is the important
				// one: a chip that always draws is permanent visual
				// noise, AND in Layered mode the two bars are coplanar,
				// so their identical full-width frame rows can z-fight.
				// Keeping the chip hidden whenever there is nothing to
				// chip means that overlap only exists during the brief
				// window after a hit, instead of always.
				bool worthShowing = !ownerRef.bInvulnerable
				                    && ownerRef.Health > 0
				                    && RS_Bucket(chipPct) != RS_Bucket(curPct);

				rsChip.bInvisible = bInvisible || !worthShowing;

				if (mode == RS_CHIP_UNDER)
				{
					// Its own thin band just below the main bar. No
					// overlap at all, so no sort question.
					rsChip.Scale.X = sc;
					rsChip.Scale.Y = sc * RS_CHIP_UNDER_YSCALE;

					double barH  = RS_BAR_PX_H * sc;
					double chipH = barH * RS_CHIP_UNDER_YSCALE;
					rsChip.SetOrigin((ownerRef.Pos.X, ownerRef.Pos.Y,
					                  zpos - chipH - barH * RS_CHIP_UNDER_GAP), true);
				}
				else
				{
					// Directly behind the main bar, showing through its
					// hollow empty region. Relies on the art: the FILLED
					// part of every frame is opaque and the EMPTY part is
					// alpha 0 through the interior.
					rsChip.Scale.X = sc;
					rsChip.Scale.Y = sc;
					rsChip.SetOrigin((ownerRef.Pos.X, ownerRef.Pos.Y, zpos), true);
				}
			}

			// --- threshold mark ---
			// Only our own monsters have gates at all; anything else
			// simply never gets a mark.
			let mm = RS_MonsterMaster(ownerRef);
			bool wantMark = mm && cvMarks && cvMarks.GetInt();

			if (mm)
				RS_LearnThresholds(mm, maxhp);

			if (!wantMark)
			{
				if (rsMark) { rsMark.Destroy(); rsMark = null; }
			}
			else
			{
				if (!rsMark)
				{
					let m = RS_HPBarMark(Spawn("RS_HPBarMark", Pos, NO_REPLACE));
					if (m) { m.ownerRef = ownerRef; rsMark = m; }
				}

				if (rsMark)
				{
					double curFrac = (maxhp > 0)
						? clamp(double(ownerRef.Health) / double(maxhp), 0.0, 1.0) : 1.0;

					double gate = -1.0;
					let h = RS_Handler();
					if (h) gate = h.RS_NextGate(mm.GetClassName(), curFrac);

					rsMark.markPct = gate * 100.0;
					rsMark.bBright = bBright;
					// Nothing learned for this monster yet, or every gate
					// already behind us -- draw nothing rather than a mark
					// at zero.
					rsMark.bInvisible = bInvisible || gate < 0 || ownerRef.Health <= 0;

					rsMark.Scale.X = sc;
					rsMark.Scale.Y = sc;
					double barH = RS_BAR_PX_H * sc;
					rsMark.SetOrigin((ownerRef.Pos.X, ownerRef.Pos.Y,
					                  zpos + barH + barH * RS_MARK_GAP), true);
				}
			}

			// --- boss bracket ---
			int frameMode = cvBossFrame ? cvBossFrame.GetInt() : RS_BOSSFRAME_OFF;
			int bossCut   = cvBossHP ? cvBossHP.GetInt() : 1000;
			bool wantFrame = (frameMode == RS_BOSSFRAME_ALWAYS)
			                 || (frameMode == RS_BOSSFRAME_AUTO && maxhp >= bossCut);

			if (!wantFrame)
			{
				if (rsFrame) { rsFrame.Destroy(); rsFrame = null; }
			}
			else
			{
				if (!rsFrame)
				{
					let f = RS_HPBarFrame(Spawn("RS_HPBarFrame", Pos, NO_REPLACE));
					if (f) { f.ownerRef = ownerRef; rsFrame = f; }
				}

				if (rsFrame)
				{
					rsFrame.bBright   = bBright;
					rsFrame.bInvisible = bInvisible;
					rsFrame.Scale.X   = sc;
					rsFrame.Scale.Y   = sc;
					// Centred on the bar: the bracket is 21px to the
					// bar's 11, so it starts 5px lower. Its interior is
					// transparent exactly where the bar sits, so being
					// coplanar with the bar is safe here.
					rsFrame.SetOrigin((ownerRef.Pos.X, ownerRef.Pos.Y,
					                   zpos - RS_FRAME_DROP_PX * sc), true);
				}
			}
		}

		// Clean-up: the token going away is the owner's way of saying
		// "I am dead / gone", and a null owner means it was removed
		// outright. The chip goes with the bar in both cases.
		if (!ownerRef || ownerRef.CountInv("RS_HPBarToken") <= 0)
		{
			RS_DestroyAttachments();
			Destroy();
		}
	}

	// Every actor hanging off this bar, torn down together. Anything
	// added later goes here as well as in OnDestroy -- an orphaned
	// attachment has no owner to hide or move it and just sits in the
	// level.
	private void RS_DestroyAttachments()
	{
		if (rsChip)  { rsChip.Destroy();  rsChip = null;  }
		if (rsMark)  { rsMark.Destroy();  rsMark = null;  }
		if (rsFrame) { rsFrame.Destroy(); rsFrame = null; }
	}

	override void OnDestroy()
	{
		RS_DestroyAttachments();
		Super.OnDestroy();
	}
}

// ---------------------------------------------------------------------
// Owner-side marker. Holds the pointer to the bar and is what the bar
// watches to know it should go away.
// ---------------------------------------------------------------------
class RS_HPBarToken : CustomInventory
{
	Actor sr;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.AUTOACTIVATE
	}

	override void Tick()
	{
		// Owner is normally non-null for a held item, but a token that
		// has been detached would crash the spawn below. Upstream did
		// not guard this.
		if (!sr && Owner)
		{
			Actor sh = Spawn("RS_HPBar", Owner.Pos, NO_REPLACE);
			sr = sh;
			RS_HPBar(sh).ownerRef = Owner;
		}

		Super.Tick();
	}

	States
	{
	Use:
		TNT1 A 0;
		Fail;
	Pickup:
		TNT1 A 0 { return true; }
		Stop;
	}
}

// One learned phase gate: "monsters of class X have a gate in slot N at
// fraction F". Plain Object holder, same shape RS_MonsterTierRow uses in
// RS_MonsterMaster -- that pattern is known to work on this build.
class RS_HPLearnedGate
{
	Name   cls;
	int    slot;
	double frac;
}

// ---------------------------------------------------------------------
// Hands out and takes back the token, and remembers where each monster
// class's phase gates sit. MUST be listed in MAPINFO.txt's
// AddEventHandlers or none of this runs.
// ---------------------------------------------------------------------
class RS_HealthBarHandler : EventHandler
{
	// Learned gates, shared by every bar. See RS_HPBar.RS_LearnThresholds
	// for why this is learned rather than read from a table: the gate
	// fractions are literals at their call sites inside the monsters, and
	// health bars have no business editing monster files to expose them.
	//
	// Lives for the session, not the level -- what you learned about
	// Barons on MAP01 is still true on MAP02.
	private Array<RS_HPLearnedGate> rsGates;

	void RS_LearnGate(Name cls, int slot, double frac)
	{
		if (frac <= 0.0 || frac >= 1.0)
			return;

		for (int i = 0; i < rsGates.Size(); i++)
		{
			// Already known. Keep the FIRST reading: later ones are
			// measured a tic or two after the gate tripped, by which
			// point the monster has taken more damage and the fraction
			// reads low.
			if (rsGates[i].cls == cls && rsGates[i].slot == slot)
				return;
		}

		let g = new("RS_HPLearnedGate");
		g.cls  = cls;
		g.slot = slot;
		g.frac = frac;
		rsGates.Push(g);
	}

	// The next gate this monster will hit: the highest learned fraction
	// still below its current one. -1 if nothing is known or they are all
	// behind it.
	double RS_NextGate(Name cls, double curFrac)
	{
		double best = -1.0;
		for (int i = 0; i < rsGates.Size(); i++)
		{
			let g = rsGates[i];
			if (g.cls != cls)     continue;
			if (g.frac >= curFrac) continue;
			if (g.frac > best) best = g.frac;
		}
		return best;
	}

	// Same filter upstream used: real monsters only, nothing decorative
	// or non-interacting.
	static bool RS_WantsBar(Actor a)
	{
		return a && a.bIsMonster && !a.bNoInteraction && !a.bNoTeleStomp;
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if (RS_WantsBar(e.Thing) && !e.Thing.CountInv("RS_HPBarToken"))
			e.Thing.GiveInventory("RS_HPBarToken", 1);
	}

	override void WorldThingDied(WorldEvent e)
	{
		if (RS_WantsBar(e.Thing))
			while (e.Thing.CountInv("RS_HPBarToken"))
				e.Thing.TakeInventory("RS_HPBarToken", 1);
	}

	override void WorldThingRevived(WorldEvent e)
	{
		if (RS_WantsBar(e.Thing) && !e.Thing.CountInv("RS_HPBarToken"))
			e.Thing.GiveInventory("RS_HPBarToken", 1);
	}

	// Players are handled separately -- they are not bIsMonster and
	// they persist across events monsters do not see.

	void RS_GivePlayerBar(PlayerPawn p)
	{
		if (p) p.GiveInventory("RS_HPBarToken", 1);
	}

	void RS_TakePlayerBar(PlayerPawn p)
	{
		if (p) p.TakeInventory("RS_HPBarToken", 0x7FFFFFFF);
	}

	override void PlayerEntered(PlayerEvent e)
	{
		RS_GivePlayerBar(players[e.PlayerNumber].mo);
	}

	override void PlayerRespawned(PlayerEvent e)
	{
		RS_GivePlayerBar(players[e.PlayerNumber].mo);
	}

	override void PlayerDied(PlayerEvent e)
	{
		RS_TakePlayerBar(players[e.PlayerNumber].mo);
	}

	override void WorldUnloaded(WorldEvent e)
	{
		// Leaving the level -- tear the player bars down explicitly so
		// they do not survive into the next one.
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			let p = players[i].mo;
			if (p && playeringame[i])
			{
				let tok = RS_HPBarToken(p.FindInventory("RS_HPBarToken"));
				if (tok && tok.sr) tok.sr.Destroy();
				RS_TakePlayerBar(p);
			}
		}
	}
}
