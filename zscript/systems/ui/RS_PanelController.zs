// =====================================================================
// RS_PanelController -- layout policy for in-world panels, and the
// handler that drives them.
//
// The owner asked for this as its own file, and the split earns itself:
// RS_Panel knows how to be a quad and how to hinge to another quad, and
// nothing else. Every taste decision -- how big, how far, how steeply
// canted, how many at once, tall or stacked -- lives here, behind
// cvars, with its own options page. The primitive stays dumb; the
// controller is where the mod's opinion goes.
//
// TWO SCOPES, ON PURPOSE. Solving a panel's world placement moves
// actors, which is play scope. Painting a canvas is a UI-side surface.
// So WorldTick solves and RenderOverlay paints, exactly the split
// RS_UIHandler already uses. Do not try to merge them.
// =====================================================================

class RS_PanelController
{
	// -----------------------------------------------------------------
	// ORIENTATION BIAS -- the one number I could not verify without a
	// headset.
	//
	// RF_FLATSPRITE composes its matrix as yaw, then pitch, then roll,
	// and a flat sprite at pitch 0 lies FLAT ON THE FLOOR (that is what
	// the flag means). Standing it upright to face along its yaw needs
	// a quarter turn, and which sign depends on the engine's pitch
	// convention. Rather than guess in a constant and ship a panel that
	// renders edge-on and invisible, it is a cvar: if the first boot
	// shows a floor-flat or upside-down panel, this is the dial, and it
	// is a five-second fix in-game instead of a rebuild.
	//
	// *** READ THIS BEFORE YOU TOUCH THE DIAL. ***
	// There are THREE INDEPENDENT unknowns here, and two of them can
	// impersonate the third. Diagnose in this order or you will chase
	// the wrong one:
	//
	//   1. PITCH BIAS (this cvar) -- wrong sign gives a panel lying flat
	//      on the floor, or standing but facing away. GEOMETRY is wrong.
	//   2. U MIRRORING -- text reads right-to-left. The quad is placed
	//      correctly; only the horizontal texture coordinate is flipped.
	//      We build our own corners and assign UVs UNSWAPPED, following
	//      the decal path (hw_decal.cpp:339-344) rather than the sprite
	//      path's swap at hw_sprites.cpp:1658. That swap exists to
	//      compensate for HWSprite's own corner naming and means nothing
	//      to a path that never calls GetSpritePositioning. Note that
	//      "unswapped" is not automatically safe either -- ProcessParticle
	//      (:1559) is unswapped and WRONG, invisibly, because particles
	//      are round.
	//   3. CANVAS V-FLIP -- text upside down. Canvas textures are stored
	//      inverted and the sprite path, unlike walls and flats, does not
	//      compensate. We do not pre-flip.
	//
	// THE TRAP: if (2) and (3) are BOTH wrong, the card appears rotated
	// 180 degrees -- which looks exactly like a pitch/orientation problem
	// and will send you into this cvar, where nothing you do will fix it.
	// A 180 rotation is a UV problem, not a geometry problem. Check that
	// the panel is in the right PLACE and facing you before assuming the
	// bias is wrong; if the geometry is right and the content is turned,
	// leave this alone and go to (2) and (3).
	// -----------------------------------------------------------------
	static double PitchBias()
	{
		let cv = CVar.FindCVar("rs_panel_pitchbias");
		return cv ? cv.GetFloat() : -90.0;
	}

	static double RollBias()
	{
		let cv = CVar.FindCVar("rs_panel_rollbias");
		return cv ? cv.GetFloat() : 0.0;
	}

	static bool Enabled()
	{
		let cv = CVar.FindCVar("rs_panel_enabled");
		return cv ? cv.GetBool() : true;
	}

	// 0 = TALL (one panel per weapon), 1 = STACKED (three hinged
	// panels per weapon, curving toward the reader). Both are built;
	// this picks which one a triptych assembles.
	static int Density()
	{
		let cv = CVar.FindCVar("rs_panel_density");
		return cv ? cv.GetInt() : 0;
	}

	static double PanelWidth()
	{
		let cv = CVar.FindCVar("rs_panel_width");
		return cv ? cv.GetFloat() : 40.0;
	}

	static double PanelHeight()
	{
		let cv = CVar.FindCVar("rs_panel_height");
		return cv ? cv.GetFloat() : 80.0;
	}

	// How far the wings cant inward. Positive folds them toward the
	// reader, which is what makes all three faces legible from one
	// standing position -- a flat row of three panels is not.
	static double HingeAngle()
	{
		let cv = CVar.FindCVar("rs_panel_hinge");
		return cv ? cv.GetFloat() : 35.0;
	}

	// Tilt between stacked panels in STACKED mode. The top panel leans
	// down toward the reader and the bottom leans up, so a column reads
	// as a curved surface rather than a wall.
	static double StackTilt()
	{
		let cv = CVar.FindCVar("rs_panel_stacktilt");
		return cv ? cv.GetFloat() : 18.0;
	}

	// Vertical offset from the player's LIVE view z -- never a world
	// constant. In VR the eye line is the player's real room-scale
	// height, not the 41 Player.ViewHeight assumes, so a fixed offset
	// is correct for exactly one person and wrong for everyone else.
	static double HeightOfs()
	{
		let cv = CVar.FindCVar("rs_panel_heightofs");
		return cv ? cv.GetFloat() : 0.0;
	}

	// Two-stage presence: the drop always glows at any range; the CARD
	// only materialises inside this radius, and despawns outside it.
	// Spawn/despawn on radius rather than an alpha fade -- far cheaper
	// than holding a live panel set per drop across a whole map.
	static double CardRadius()
	{
		let cv = CVar.FindCVar("rs_panel_radius");
		return cv ? cv.GetFloat() : 320.0;
	}

	static int MaxAssemblies()
	{
		let cv = CVar.FindCVar("rs_panel_maxlive");
		return cv ? cv.GetInt() : 8;
	}

	// How far in front of the reader the card holds station.
	static double Comfort()
	{
		let cv = CVar.FindCVar("rs_panel_comfort");
		return cv ? cv.GetFloat() : 72.0;
	}

	// -----------------------------------------------------------------
	// TYPOGRAPHY. Player-facing because legibility in a headset is
	// genuinely personal -- panel distance, IPD and lens sharpness all
	// move where the comfortable point is, and no default is right for
	// everyone.
	//
	// Resolved by NAME through Font.GetFont so a font that is not
	// present falls back rather than crashing.
	// -----------------------------------------------------------------
	static Font BodyFont()
	{
		let cv = CVar.FindCVar("rs_panel_font");
		int pick = cv ? cv.GetInt() : 0;
		Font f = Font.GetFont(FontName(pick));
		return f ? f : SmallFont;
	}

	static Font TitleFont()
	{
		let cv = CVar.FindCVar("rs_panel_titlefont");
		int pick = cv ? cv.GetInt() : 2;
		Font f = Font.GetFont(FontName(pick));
		return f ? f : BigFont;
	}

	// A switch, not a static array literal -- `static const TYPE n[] =
	// {...}` does not reliably resolve on this engine build and has
	// produced a bogus "Unknown identifier" three separate times here.
	static Name FontName(int pick)
	{
		switch (pick)
		{
			case 1:  return 'NewSmallFont';
			case 2:  return 'BigFont';
			case 3:  return 'ConFont';
			default: return 'SmallFont';
		}
	}

	static int RowPitch()
	{
		let cv = CVar.FindCVar("rs_panel_rowpitch");
		int p = cv ? cv.GetInt() : 18;
		return clamp(p, 8, 48);
	}

	// --- drop marker --------------------------------------------------
	static bool BeamEnabled()
	{
		let cv = CVar.FindCVar("rs_drop_beam");
		return cv ? cv.GetBool() : true;
	}

	static double BeamWidth()
	{
		let cv = CVar.FindCVar("rs_drop_beamwidth");
		return cv ? cv.GetFloat() : 7.0;
	}

	static double BeamHeight()
	{
		let cv = CVar.FindCVar("rs_drop_beamheight");
		return cv ? cv.GetFloat() : 44.0;
	}

	static int DropChance()
	{
		let cv = CVar.FindCVar("rs_elitedrop_chance");
		return cv ? clamp(cv.GetInt(), 0, 100) : 100;
	}

	static int LightRadius()
	{
		let cv = CVar.FindCVar("rs_drop_lightradius");
		return cv ? int(cv.GetFloat()) : 96;
	}

	// -----------------------------------------------------------------
	// Tier -> the TRNSLATE name that tints a dropped weapon's sprite,
	// and the tier colour for its glow and light.
	//
	// Rarity names, not numbers: the monster block in TRNSLATE.txt is
	// rs_<family>_t<NN> because monsters have numeric difficulty tiers.
	// Weapons have rarity tiers. The two vocabularies stay apart.
	// -----------------------------------------------------------------
	static Name TierTranslation(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return 'rs_wpn_cursed';
			case VRT_Trash:     return 'rs_wpn_trash';
			case VRT_Basic:     return 'rs_wpn_basic';
			case VRT_Common:    return 'rs_wpn_common';
			case VRT_Uncommon:  return 'rs_wpn_uncommon';
			case VRT_Advanced:  return 'rs_wpn_advanced';
			case VRT_Designer:  return 'rs_wpn_designer';
			default:            return 'rs_wpn_prototype';
		}
	}

	// The same ramp as RS_UIStyle.TierColor, as literal RGB for the
	// glow and the dynamic light. RS_UIStyle returns Font.CR_* constants,
	// which are text-colour indices and cannot light a room.
	static Color TierGlow(int tier)
	{
		switch (tier)
		{
			case VRT_Cursed:    return Color(255, 168,  24,  24);
			case VRT_Trash:     return Color(255, 150, 104,  56);
			case VRT_Basic:     return Color(255, 184, 184, 184);
			case VRT_Common:    return Color(255, 255, 255, 255);
			case VRT_Uncommon:  return Color(255,  64, 224,  88);
			case VRT_Advanced:  return Color(255,  96, 168, 255);
			case VRT_Designer:  return Color(255, 184,  96, 255);
			default:            return Color(255, 255, 208,  64);
		}
	}
}

// =====================================================================
// RS_PanelHandler -- solves every live assembly each tic, paints their
// cards each frame, and resolves the aim ray to a row.
//
// MUST also be listed in MAPINFO.txt's AddEventHandlers. A handler name
// in MAPINFO with no class is a hard crash at map load; a class with no
// MAPINFO line compiles and silently never runs. Both halves or
// neither.
// =====================================================================
class RS_PanelHandler : EventHandler
{
	Array<RS_PanelAssembly> mLive;
	Array<RS_PanelCard>     mCards;   // parallel to every panel, by slot

	// Aim resolution, recomputed each tic in play scope and read by the
	// painter. -1 = the ray is on nothing.
	// This handler owns GEOMETRY -- which panel the ray hit and where on
	// it (mHotUV). It does not own CONTENT and cannot know what a row
	// is; resolving uv -> row needs the card, which belongs to whoever
	// built the panel.
	int      mHotAssembly;
	int      mHotPanel;
	// Which controller is pointing: 0 offhand/left, 1 mainhand/right,
	// -1 nothing. In flat play this is always 0 (the view ray).
	int      mHotHand;
	Vector2  mHotUV;

	// --- published BY the content side, read by the input side --------
	// These two used to be deliberately absent, on the grounds that a
	// geometry handler cannot know what a row is and the only value
	// anything ever wrote was -1. That reasoning held right up until
	// something needed to press a row: the trigger capture runs in
	// PlayerThink, where neither the card nor the painter is reachable,
	// so the row state has to be somewhere it can see.
	//
	// It is still not RESOLVED here -- the card owner resolves it and
	// calls PublishHotRow. This is a letterbox, not a decision.
	int      mHotRow;
	bool     mHotRowLive;

	play void PublishHotRow(int row, bool live)
	{
		mHotRow     = row;
		mHotRowLive = live;
	}

	play void ClearHot()
	{
		mHotAssembly = -1; mHotPanel = -1; mHotHand = -1;
		mHotRow = -1; mHotRowLive = false;
	}

	// -----------------------------------------------------------------
	// Registration
	// -----------------------------------------------------------------
	int RegisterAssembly(RS_PanelAssembly a)
	{
		if (!a) return -1;
		if (mLive.Size() >= RS_PanelController.MaxAssemblies())
		{
			// Oldest out. An options-menu cap plus a radial cull is the
			// design; when the cap bites, the panel you walked away
			// from is the one that goes.
			let old = mLive[0];
			if (old) old.Destroy();
			mLive.Delete(0);
		}
		mLive.Push(a);
		return mLive.Size() - 1;
	}

	void DropAssembly(RS_PanelAssembly a)
	{
		for (int i = 0; i < mLive.Size(); i++)
		{
			if (mLive[i] == a)
			{
				if (mLive[i]) mLive[i].Destroy();
				mLive.Delete(i);
				return;
			}
		}
	}

	void ClearAll()
	{
		for (int i = 0; i < mLive.Size(); i++)
			if (mLive[i]) mLive[i].Destroy();
		mLive.Clear();
		ClearHot();
	}

	// -----------------------------------------------------------------
	// AIM -- FROM THE HANDS, NOT FROM THE VIEW.
	//
	// The ray starts where the weapon is actually held. GZDoom exposes a
	// full per-hand pose natively -- AttackPos/Angle/Pitch/Roll for the
	// main hand and OffhandPos/Angle/Pitch/Roll for the off hand
	// (actor.zs:268-275) -- and OverrideAttackPosDir (:276) says whether
	// VR is really driving them. It is the same pose the engine spawns
	// projectiles from, so pointing at a panel and shooting at it agree
	// about where you were pointing.
	//
	// Flat play falls back to the view ray, so nothing here needs a
	// headset to be testable.
	//
	// WHICH HAND POINTED IS RECORDED, and that turns out to settle the
	// Hand Law by itself: point at the card with your left controller
	// and the drop goes to your left hand. No per-wing buttons, no rule
	// to memorise, no new bind.
	//
	// uv is 0..1 with (0,0) at the panel's TOP-LEFT as the reader sees
	// it -- the origin RS_PanelCard.RowAtUV expects. The old engine used
	// bottom-left and it was a permanent source of off-by-one-row
	// confusion; top-left matches how the card is painted and read.
	// -----------------------------------------------------------------
	play void SolveAim(PlayerPawn pawn)
	{
		mHotAssembly = -1; mHotPanel = -1; mHotHand = -1;
		if (!pawn) { mHotRow = -1; mHotRowLive = false; return; }

		double best = 1e9;

		// Hand 0 = offhand/left, 1 = mainhand/right. Two rays, nearest
		// hit across both wins.
		for (int hand = 0; hand < 2; hand++)
		{
			Vector3 origin;
			double  yaw, pit;

			if (pawn.OverrideAttackPosDir)
			{
				// Tracked controllers.
				origin = (hand == 0) ? pawn.OffhandPos   : pawn.AttackPos;
				yaw    = (hand == 0) ? pawn.OffhandAngle : pawn.AttackAngle;
				pit    = (hand == 0) ? pawn.OffhandPitch : pawn.AttackPitch;
			}
			else
			{
				// Flat play: one ray down the view, and only once --
				// two identical rays would just cost double.
				if (hand == 1) continue;
				origin = (pawn.pos.x, pawn.pos.y,
				          pawn.player ? pawn.player.viewz : pawn.pos.z + 41);
				yaw    = pawn.angle;
				pit    = pawn.pitch;
			}

			Vector3 dir = (cos(yaw) * cos(pit), sin(yaw) * cos(pit), -sin(pit));
			TraceHand(origin, dir, hand, best);
		}

		// TOUCH BEATS POINTING, so it runs last and overwrites.
		TracePoke(pawn);
	}

	// -----------------------------------------------------------------
	// THE POKE -- the "punchable" half, and the only one of the two
	// physical routes that is genuinely its own gesture.
	//
	// This is a POSITION test, not a ray: is the hand actually in the
	// panel? Reaching out and putting your hand on a row is a stronger
	// statement of intent than a ray that happens to graze it from
	// across the room, so a poke wins outright over both aim rays.
	//
	// Tracked hands only. Without OverrideAttackPosDir the "hand"
	// position is the player's own origin, which would put you
	// permanently inside any panel you walked through.
	// -----------------------------------------------------------------
	play void TracePoke(PlayerPawn pawn)
	{
		if (!pawn.OverrideAttackPosDir) return;

		double depth = RS_PanelInput.PokeDepth();
		if (depth <= 0) return;

		for (int hand = 0; hand < 2; hand++)
		{
			Vector3 hp = (hand == 0) ? pawn.OffhandPos : pawn.AttackPos;

			for (int a = 0; a < mLive.Size(); a++)
			{
				let asm = mLive[a];
				if (!asm) continue;

				for (int p = 0; p < asm.Size(); p++)
				{
					let pan = asm.Get(p);
					if (!pan) continue;

					Vector3 local = hp - pan.pos;

					// Distance off the face, signed either way -- a hand
					// that has punched THROUGH the card is still on it.
					// Held in a local rather than nested inside abs():
					// every other `dot` in this file is either its own
					// statement or explicitly parenthesised, and this is
					// not the codebase to get clever about precedence in.
					double off = local dot pan.FaceVec();
					if (abs(off) > depth) continue;

					double lx = local dot pan.RightVec();
					double ly = local dot pan.UpVec();

					if (abs(lx) > pan.mWidth  * 0.5) continue;
					if (abs(ly) > pan.mHeight * 0.5) continue;

					mHotAssembly = a;
					mHotPanel    = p;
					mHotHand     = hand;
					mHotUV       = (lx / pan.mWidth + 0.5, 0.5 - ly / pan.mHeight);
					return;
				}
			}
		}
	}

	// One hand's ray against every live panel. `best` carries in so a
	// nearer hit from the other hand is not overwritten by a farther one.
	play void TraceHand(Vector3 origin, Vector3 dir, int hand, out double best)
	{
		for (int a = 0; a < mLive.Size(); a++)
		{
			let asm = mLive[a];
			if (!asm) continue;

			for (int p = 0; p < asm.Size(); p++)
			{
				let pan = asm.Get(p);
				if (!pan) continue;

				Vector3 n = pan.FaceVec();
				double denom = dir dot n;
				if (abs(denom) < 0.0001) continue;   // ray parallel to the face

				double t = ((pan.pos - origin) dot n) / denom;
				if (t <= 0 || t >= best) continue;   // behind the hand, or farther than a hit we hold

				Vector3 local = (origin + dir * t) - pan.pos;

				double lx = local dot pan.RightVec();
				double ly = local dot pan.UpVec();

				if (abs(lx) > pan.mWidth  * 0.5) continue;
				if (abs(ly) > pan.mHeight * 0.5) continue;

				best         = t;
				mHotAssembly = a;
				mHotPanel    = p;
				mHotHand     = hand;
				mHotUV       = (lx / pan.mWidth + 0.5, 0.5 - ly / pan.mHeight);
			}
		}
	}

	// -----------------------------------------------------------------
	override void WorldTick()
	{
		if (!RS_PanelController.Enabled())
		{
			if (mLive.Size() > 0) ClearAll();
			else ClearHot();
			return;
		}

		// A stale hot row is not harmless now that something PRESSES it.
		// Before the confirm existed these fields were read only by the
		// painter, which draws nothing when there is no card, so leaving
		// them set on the way out cost nothing. The trigger capture runs
		// in PlayerThink and does not know whether a card is up -- so
		// every path that leaves this function without solving has to
		// say "nothing is hot" rather than leave the last answer lying
		// around.
		if (mLive.Size() == 0) { ClearHot(); return; }

		PlayerPawn pawn = players[consoleplayer].mo;
		if (!pawn) { ClearHot(); return; }

		// Live view z, not pos.z + a constant. See HeightOfs above.
		Vector3 eye = (pawn.pos.x, pawn.pos.y, pawn.player.viewz);

		for (int i = 0; i < mLive.Size(); i++)
			if (mLive[i]) mLive[i].Solve(eye);

		// Aim comes off the HANDS, not the view -- see SolveAim.
		SolveAim(pawn);

		// Row resolution needs the card, which the triptych owns; the
		// hot row is recomputed there when it repaints. Storing the uv
		// is what couples the two without either knowing the other.
	}

	override void WorldUnloaded(WorldEvent e)
	{
		ClearAll();
	}
}
