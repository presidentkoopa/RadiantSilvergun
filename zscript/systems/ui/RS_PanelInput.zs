// =====================================================================
// RS_PanelInput -- THE BUTTON. The half of "point at the wing and
// confirm" that was never built.
//
// Everything else already existed: panels render, the aim ray resolves
// off the hand poses, RowAtUV turns a hit into a row, and
// RS_PanelDropHandler's "rs-panel-use" branch dispatches whatever
// command that row carries. Nothing pressed it. Taking a drop was
// `netevent rs-panel-take 0` at the console and nothing else.
//
// ---------------------------------------------------------------------
// WHY THIS IS NOT RS_WheelPoC'S PATTERN, AND WHY THAT MATTERS
// ---------------------------------------------------------------------
// RS_WheelPoC's header states its capture mechanism as: read raw input
// from original_cmd, then zero `cmd` in WorldTick, "WorldTick runs
// before player thinkers, so the engine never sees the input."
//
// THAT ORDERING IS BACKWARDS ON THIS BUILD. Verified in the engine at
// E:\UZDXREMA (branch questzdoom), reading down the call chain rather
// than trusting the comment:
//
//   p_tick.cpp:175   P_PlayerThink(Level->Players[i])   <-- FIRST
//   p_tick.cpp:178   localEventManager->WorldTick()     <-- SECOND
//
// and inside that player think, the weapon has already spent the
// buttons:
//
//   p_user.cpp:1358  IFVIRTUALPTRNAME(mo, PlayerPawn, PlayerThink)
//   player.zs:1796     player.mo.TickPSprites()
//   player.zs:583        player.attackdown = CheckWeaponFire(0)
//   player.zs:478          player.cmd.buttons & bt_attack  --> FireWeapon
//
// So an EventHandler that zeroes cmd.buttons in WorldTick is clearing
// them AFTER the shot has already been fired for that tic. Copying that
// pattern here would have shipped exactly the thing the requirement
// forbids: a confirm press that also discharges your weapon.
//
// The correct interception is the first line of the player's own think,
// before Super hands control to TickPSprites. `PlayerThink` is virtual
// (player.zs:1732); `CheckWeaponFire` is NOT (player.zs:463, no
// `virtual`), so it cannot be overridden and this is the hook. Nothing
// in native P_PlayerThink between its entry (1284) and that virtual
// call (1358) touches buttons -- it is haptics, angle offsets, the
// original_cmd copy and cheat-flag clears -- so a button cleared here
// has genuinely not been read by anything yet.
//
// VR_DualClassBase.PlayerThink is where the call lives. The engine's
// own PlayerPawn is not extendable on this build ("class playerpawn
// cannot be found in current translation unit"); the project's base is.
//
// ---------------------------------------------------------------------
// EDGE, NOT LEVEL -- AND NOT WITH `oldbuttons`
// ---------------------------------------------------------------------
// One pull of the trigger must be one take. The obvious edge test is
// the engine's own idiom, `cmd.buttons & X && !(oldbuttons & X)`
// (player.zs:1614), and it is WRONG for anything that edits cmd, which
// is exactly what this does.
//
// G_Ticker rolls the previous tic's command forward:
//
//   g_game.cpp:1379   players[i].oldbuttons = cmd->ucmd.buttons;
//   g_game.cpp:1389   memcpy(cmd, newcmd, sizeof(ticcmd_t));
//
// -- it snapshots `players[i].cmd` AS IT STOOD AT THE END OF THE LAST
// TIC, and we cleared the bit out of that during the last tic. So
// oldbuttons never has the confirm bit set, every tic reads as a fresh
// press, and holding the trigger would re-confirm 35 times a second.
//
// The unmodified pair is what to use. Both are written inside
// P_PlayerThink BEFORE it calls the virtual we hook from:
//
//   p_user.cpp:1347   original_oldbuttons = original_cmd.buttons  (prev tic, raw)
//   p_user.cpp:1348   original_cmd        = cmd->ucmd             (this tic, raw)
//   p_user.cpp:1358   IFVIRTUALPTRNAME(mo, PlayerPawn, PlayerThink)
//
// `original_cmd` is readonly and nothing here can perturb it, so the
// edge it reports is the player's actual finger. This is the half of
// RS_WheelPoC's design that IS right, and the reason it reads
// original_cmd at all.
// =====================================================================

class RS_PanelInput play
{
	// -----------------------------------------------------------------
	// CONFIRM MODE.
	//   0  bind only        -- the weapon trigger is never touched
	//   1  tracked hands    -- gun/poke confirm only when VR is really
	//                          driving the hand poses  (DEFAULT)
	//   2  always           -- flat play too
	//
	// 1 is the default and the asymmetry is deliberate, not timidity.
	// In flat play the aim ray IS the view ray and the card holds
	// station directly in front of the reader, so a live row sits under
	// the crosshair most of the time a card is up -- trigger capture
	// there would eat shots constantly. With tracked controllers the
	// ray comes off the hand and a take row is a two-row target on a
	// wing you have to actually point at.
	// -----------------------------------------------------------------
	static int ConfirmMode()
	{
		let cv = CVar.FindCVar("rs_panel_confirm");
		return cv ? cv.GetInt() : 1;
	}

	// How far a hand may sit off a panel's face and still count as
	// touching it. 0 disables the poke entirely.
	static double PokeDepth()
	{
		let cv = CVar.FindCVar("rs_panel_poke");
		return cv ? cv.GetFloat() : 6.0;
	}

	// How hard a hand must drive INTO a panel to count as a punch rather
	// than a hand that happens to be resting there. Map units of travel
	// per tic, measured along the face normal. 0 disables the punch and
	// leaves the poke as highlight-only.
	//
	// 1.5/tic is ~52 units/sec, which is a deliberate jab and not a
	// drift. Resting-hand jitter does not reach it.
	static double PunchSpeed()
	{
		let cv = CVar.FindCVar("rs_panel_punch");
		return cv ? cv.GetFloat() : 1.5;
	}

	static bool SoundsEnabled()
	{
		let cv = CVar.FindCVar("rs_panel_sound");
		return cv ? cv.GetBool() : true;
	}

	// -----------------------------------------------------------------
	// THE PANEL'S VOICE.
	//
	// Named here rather than spelled at each call site so the whole
	// vocabulary is auditable in one place -- which matters more than
	// usual, because an unresolved sound name in this engine is
	// COMPLETELY INERT. No error, no warning, no log line; the panel
	// just goes quiet and there is no check that can fail. Every name
	// below was verified against the engine's own
	// filter/game-doomchex/sndinfo.txt before being used:
	//
	//   menu/cursor    :442  dspstop    row change under the pointer
	//   menu/activate  :439  dsswtchn   a press registered
	//   menu/invalid   :444  dsoof      refused, nothing happened
	//   menu/clear     :447  dsswtchx   card dismissed
	//   misc/w_pkup    :418  dswpnup    the drop is now in your hand
	//
	// menu/choose was deliberately NOT used for the confirm even though
	// it is the conventional menu-accept sound: it maps to dspistol, and
	// a gunshot is precisely the thing this button is suppressing.
	// -----------------------------------------------------------------
	// `sound`, not `Name` -- A_StartSound takes a `sound` (actor.zs:1194)
	// and that is the type a string literal converts to at a call site.
	static void Say(PlayerPawn pawn, sound snd)
	{
		if (!pawn || !SoundsEnabled()) return;
		pawn.A_StartSound(snd);
	}

	// THE HAND THAT POINTS IS THE HAND THAT PRESSES. Offhand rows are
	// confirmed with the offhand trigger, mainhand rows with the main
	// trigger -- so the gesture that selects and the gesture that
	// commits are the same hand, and neither hand can confirm what the
	// other is pointing at.
	//
	// EXCEPT IN FLAT PLAY, where that mapping is actively broken rather
	// than merely unnecessary: SolveAim casts ONE ray without tracked
	// controllers and files it under hand 0, so every flat-play hit
	// reports as the offhand -- and BT_OFFHANDATTACK is unbound for a
	// keyboard-and-mouse player. Confirm mode 2 would have looked
	// enabled and done nothing. Untracked, the fire button is the only
	// honest answer.
	static int ConfirmButton(int hand, bool tracked)
	{
		if (!tracked) return BT_ATTACK;
		return (hand == 0) ? BT_OFFHANDATTACK : BT_ATTACK;
	}

	// -----------------------------------------------------------------
	// THE CAPTURE ITSELF.
	//
	// Called from VR_DualClassBase.PlayerThink BEFORE Super. Returns
	// nothing and touches exactly one thing: the confirming button is
	// stripped out of this tic's cmd so the weapon never sees it.
	//
	// ONE TIC OF LAG IS CORRECT HERE, not a defect. The aim it reads was
	// solved in the previous tic's WorldTick, which is also the aim the
	// previous frame PAINTED as the highlighted row. So the player
	// confirms the row they were shown, not one resolved a fraction
	// later from a hand that has since moved.
	// -----------------------------------------------------------------
	static void Capture(PlayerPawn pawn)
	{
		if (!pawn || !pawn.player) return;

		// PlayerThink runs for EVERY player in the game, on every
		// machine. The panel system is consoleplayer-only throughout --
		// SolveAim, the card radius and the painter all read
		// players[consoleplayer] -- so without this gate a second
		// player's think would test the console player's aim and send a
		// duplicate confirm.
		if (pawn.PlayerNumber() != consoleplayer) return;

		if (!RS_PanelController.Enabled()) return;

		bool tracked = pawn.OverrideAttackPosDir;

		int mode = ConfirmMode();
		if (mode <= 0) return;
		if (mode == 1 && !tracked) return;

		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		if (!ph) return;

		// mHotRowLive is published by whoever owns the card's CONTENT --
		// the geometry handler cannot know what a row is. An inert text
		// row or the header publishes false, and the trigger is left
		// alone so you can still shoot past a card you are only reading.
		if (!ph.mHotRowLive) return;

		int hand = ph.mHotHand;
		if (hand < 0) return;

		let p = pawn.player;
		int bt = ConfirmButton(hand, tracked);

		// The RAW pair -- see the header. p.oldbuttons is downstream of
		// our own edit and would report a fresh press every tic.
		if (!(p.original_cmd.buttons & bt)) return;

		// Eat it whether it is a fresh press or a hold, so resting your
		// finger on the trigger while pointing at a live row keeps the
		// gun quiet instead of firing on tic two.
		p.cmd.buttons &= ~bt;

		// ...but only a fresh press confirms.
		if (p.original_oldbuttons & bt) return;

		// The generic confirm, not a per-action event. rs-panel-use
		// resolves the hot row and fires whatever command IT carries, so
		// every future panel gets a working button with no new bind --
		// and a row behaves identically whether it was pressed, poked,
		// or typed at the console.
		EventHandler.SendNetworkEvent("rs-panel-use", 0);
	}
}
