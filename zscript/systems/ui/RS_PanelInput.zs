// =====================================================================
// RS_PanelInput -- THE BUTTONS. Every way a player can press an in-world
// panel that is not a keybind, funnelled into one confirm.
//
// Everything else already existed: panels render, the aim ray resolves
// off the hand poses, RowAtUV turns a hit into a row, and
// RS_PanelDropHandler's "rs-panel-use" branch dispatches whatever
// command that row carries. Nothing pressed it. Taking a drop was
// `netevent rs-panel-take 0` at the console and nothing else.
//
// ---------------------------------------------------------------------
// THE FOUR ROUTES (owner's spec, 2026-08-08)
// ---------------------------------------------------------------------
// A drop card must be takeable four ways, whichever the player reaches
// for, and all four must mean the same thing:
//
//   POKE      reach out and touch it        RS_PanelHandler.TracePoke
//   SHOOT     put a gun on it and fire      CaptureAttack, this file
//   HOLD USE  hold the use key              CaptureUse, this file
//   TAP USE   tap the use key               CaptureUse, this file
//
// plus the keybind (KEYCONF's rs_panel_use, MOUSE3) and the console,
// which have always worked and are unchanged.
//
// They converge on ONE netevent -- see Confirm() below -- because four
// arrival points must not become four implementations of "take this".
// The one that matters and the one you tested are rarely the same one.
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
	// CONFIRM MODE -- THE SHOT ROUTE'S SWITCH.
	//   0  bind only        -- the weapon trigger is never touched
	//   1  tracked hands    -- shooting the card works only when VR is
	//                          really driving the hand poses
	//   2  always           -- flat play too  (DEFAULT)
	//
	// DEFAULT CHANGED 1 -> 2 ON 2026-08-08, at the owner's direct
	// instruction that all four routes must work: poke, SHOT, hold USE,
	// tap USE. At 1 the shot route did not exist for a keyboard player at
	// all, so one of the four was simply absent on flat setups.
	//
	// The old reasoning for 1 is worth keeping because it names the real
	// hazard: in flat play the aim ray IS the view ray and the card holds
	// station directly in front of the reader, so the card is between you
	// and whatever you are shooting at for as long as it is up. What that
	// argument missed is that being in the way is not the same as
	// capturing the press. A press is only taken when the ray lands on a
	// row THAT CARRIES A COMMAND, and the only such rows on a drop card
	// are the one-line "> TAKE TO ..." rows on the two angled wings --
	// about one row in twenty, on panels turned away from you. Reading
	// the card never disarms you; the highlight bar shows you the moment
	// it would.
	//
	// Set it back to 1 if you want the old tracked-only behaviour, or 0
	// to leave the trigger alone entirely and take drops with USE, the
	// keybind and the punch.
	// -----------------------------------------------------------------
	static int ConfirmMode()
	{
		let cv = CVar.FindCVar("rs_panel_confirm");
		return cv ? cv.GetInt() : 2;
	}

	// How far a hand may sit off a panel's face and still count as
	// touching it. 0 disables the poke entirely.
	static double PokeDepth()
	{
		let cv = CVar.FindCVar("rs_panel_poke");
		return cv ? cv.GetFloat() : 6.0;
	}

	// -----------------------------------------------------------------
	// TOUCH IS THE PRESS. On by default, 2026-08-08, at the owner's
	// direct instruction that touch is the PRIMARY route and the keys are
	// the desktop fallback.
	//
	// Before this, reaching out and putting your hand on a button did
	// NOTHING unless the hand was also moving at rs_panel_punch. The poke
	// resolved a row and lit it and stopped there. Off restores that:
	// touch highlights, and a punch, the trigger, USE or the keybind
	// presses.
	// -----------------------------------------------------------------
	static bool TouchPress()
	{
		let cv = CVar.FindCVar("rs_panel_touchpress");
		return !cv || cv.GetBool();
	}

	// How much wider the RELEASE band is than the entry band, as a
	// multiple of rs_panel_poke.
	//
	// A hand does not hold still. Parked at the exact edge of the touch
	// volume it crosses in and out several times a second, and with one
	// threshold that is a button pressing itself. Entry at rs_panel_poke,
	// release at this times it, and the hand has to actually withdraw
	// before it can press again.
	//
	// RS_PanelHandler.TracePoke floors this at 1.0 -- a release band
	// narrower than the entry band is not a preference, it is a
	// repeat-fire.
	static double PokeRelease()
	{
		let cv = CVar.FindCVar("rs_panel_pokerelease");
		return cv ? cv.GetFloat() : 2.5;
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

	// =================================================================
	// ONE CONFIRM. FOUR ROUTES. NO SECOND CODE PATH.
	//
	// Owner's spec, 2026-08-08: the drop card must be usable by poking it
	// with a controller, by SHOOTING it, by HOLDING use, and by TAPPING
	// use -- whichever the player reaches for. Four routes is four ways
	// to arrive; it must not become four implementations of "take this",
	// because four implementations drift and only the one you tested
	// stays correct.
	//
	// So every route ends here, at one netevent:
	//
	//     poke / punch  RS_PanelHandler.TracePoke -> ConsumePokeStrike
	//                   -> RS_PanelDropHandler.WorldTick
	//     shot          CaptureAttack, below
	//     hold USE      CaptureUse, below
	//     tap USE       CaptureUse, below
	//     keybind       KEYCONF's rs_panel_use alias (MOUSE3)
	//     console       `netevent rs-panel-use`
	//
	//              ... all -> "rs-panel-use" -> RS_PanelDropHandler
	//                         .NetworkProcess, which resolves the row and
	//                         dispatches whatever command it carries.
	//
	// THE ARGUMENT IS A HAND, PLUS ONE.
	//
	// The offset is not cosmetic. `netevent rs-panel-use` typed at the
	// console, and the KEYCONF alias, both carry no argument at all and
	// therefore arrive as args[0] == 0. That has always meant "use the
	// row the pointer is on", and it has to keep meaning that -- so 0 is
	// reserved for "no hand information" and a real hand is sent as
	// hand+1. A route that knows which hand acted says so; one that
	// cannot passes -1 and the row's own argument decides.
	//
	// WHICH HAND ACTED IS THE HAND THAT RECEIVES. That law is enforced
	// downstream in the rs-panel-take branch, which prefers the POINTING
	// hand over the row's argument whenever VR is really driving the
	// poses. Nothing here needs to re-implement it, and nothing here
	// should: it already handles the case the naive version got wrong
	// (pointing with an empty hand at the other hand's row).
	// =================================================================
	static void Confirm(int hand)
	{
		EventHandler.SendNetworkEvent("rs-panel-use", hand + 1);
	}

	// -----------------------------------------------------------------
	// THE CAPTURE ITSELF.
	//
	// Called from VR_DualClassBase.PlayerThink BEFORE Super. It touches
	// exactly one thing: the button that confirmed is stripped out of
	// this tic's cmd, so neither the weapon nor the engine's use-line
	// check ever sees it.
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

		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		if (!ph) return;

		bool tracked = pawn.OverrideAttackPosDir;

		CaptureAttack(pawn, ph, tracked);
		CaptureUse(pawn, ph);
	}

	// -----------------------------------------------------------------
	// ROUTE: SHOOT THE CARD.
	//
	// WHY THIS IS AN INPUT TEST AND NOT A SHOOTABLE PANEL. The obvious
	// reading of "shoot it" is +SHOOTABLE on RS_Panel or on the pedestal,
	// and it is the wrong answer here for a reason that is specific to
	// this card rather than a general objection:
	//
	//   * The drop card runs in COMFORT MODE (RS_PanelDropHandler.
	//     RaiseCard sets mComfort/mComfortDist). It does not sit on the
	//     pedestal -- it holds station rs_panel_comfort units in front of
	//     the reader's eyes, on the line toward the drop, and follows
	//     them. A shootable quad there is a wall in front of your face.
	//   * In GZDoom a non-solid actor still stops a missile if it is
	//     shootable, and a hitscan still terminates on it. So every
	//     rocket and every bullet fired anywhere near the drop's bearing
	//     would detonate at arm's length for as long as the card was up.
	//   * The panels are Radius 1 / Height 1 cylinders. Their hitbox is
	//     not the quad, so a real hit could not say WHICH ROW was struck,
	//     and the Hand Law has no answer from a hitscan at all.
	//
	// The aim ray already solves all three: it comes off the real per-
	// hand pose (the same pose the engine spawns projectiles from), it
	// resolves to a row, and it records which hand. So the shot is
	// detected where the trigger is pressed, and the press is taken
	// before the weapon spends it. No ammo, no recoil, no muzzle flash,
	// no rocket in your face -- which is the "does not waste ammo
	// unfairly" half of the requirement, satisfied by construction.
	//
	// WHY A STRAY SHOT ACROSS A ROOM CANNOT DO THIS:
	//   1. no card, no capture -- mHotRowLive is false whenever nothing
	//      is up, and a card only exists inside rs_panel_radius;
	//   2. the ray must land on a row CARRYING A COMMAND. On a drop card
	//      that is the single "> TAKE TO ..." line on each wing. Every
	//      other row -- the whole stat block, the headers, the rules --
	//      publishes false and the trigger passes straight through;
	//   3. the hit must be within rs_panel_shootrange of the hand;
	//   4. it must be a fresh press, so holding fire through a card that
	//      drifts under your muzzle confirms nothing.
	// -----------------------------------------------------------------
	static void CaptureAttack(PlayerPawn pawn, RS_PanelHandler ph, bool tracked)
	{
		int mode = ConfirmMode();
		if (mode <= 0) return;
		if (mode == 1 && !tracked) return;

		// THE AIM RECORD, NOT THE HOT RECORD. Changed 2026-08-08.
		//
		// mHot* is whatever won overall, and TOUCH OVERWRITES IT -- which
		// is right for the highlight and fatal here. Rest one hand
		// anywhere on the card while aiming the other at a live row and
		// mHotHand became the resting hand, so this asked for that hand's
		// trigger and never read the one being pulled. The gun fired, the
		// row did not take, and the highlight was still lit on the row the
		// resting hand was under. Nothing to see, nothing logged.
		//
		// mAim* is the two rays' own answer, snapshotted in SolveAim before
		// TracePoke speaks. See its declaration in RS_PanelController.
		//
		// mAimRowLive is published by whoever owns the card's CONTENT --
		// the geometry handler cannot know what a row is. An inert text
		// row or the header publishes false, and the trigger is left
		// alone so you can still shoot past a card you are only reading.
		if (!ph.mAimRowLive) return;

		int hand = ph.mAimHand;
		if (hand < 0) return;

		if (ph.mAimDist > RS_PanelController.ShootRange()) return;

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

		// Untracked, SolveAim files its single view ray under hand 0 --
		// see ConfirmButton -- so "hand 0" there does not mean the left
		// controller, it means "the one ray there is". Reporting it as
		// the offhand would be a lie the fallback could act on, so a
		// keyboard shot declares the mainhand, which is the hand the fire
		// button actually belongs to.
		Confirm(tracked ? hand : 1);
	}

	// -----------------------------------------------------------------
	// ROUTES: TAP USE AND HOLD USE.
	//
	// MOVED HERE FROM RS_PanelDropHandler.WorldTick ON 2026-08-08, and
	// the move is the fix, not tidying. The old hold-to-take read BT_USE
	// in an EventHandler's WorldTick, which the engine runs at
	// p_tick.cpp:305 -- AFTER P_PlayerThink at :302. The use-line check
	// lives inside that think: player.zs:1793 calls CheckUse, whose
	// native body tests `player->cmd.ucmd.buttons & BT_USE` and opens the
	// door (p_user.cpp:1326-1334). So a USE read in WorldTick has already
	// been spent. Hold-to-take worked, but every hold also opened
	// whatever was in front of you, and a TAP route was impossible to
	// build there at all: by the time you knew it was a tap, the door was
	// open. Same class of error as reading the fire button in WorldTick,
	// one file over.
	//
	// Here, before Super.PlayerThink, the button can be taken away.
	//
	// TAP AND HOLD DO NOT FIGHT, AND THE RULE IS SIMPLE:
	//   * the press is swallowed the moment it begins, so nothing else
	//     acts on it while we decide what it was;
	//   * at UseHoldTics the HOLD fires, once, and mUseFired latches;
	//   * on release, if the hold never fired, it was a TAP.
	// A tap therefore cannot be eaten by the hold timer (it fires on the
	// release, before the timer is reached), and a hold cannot fire the
	// tap first (the tap only ever fires on release, and the latch blocks
	// it).
	//
	// WHICH HAND. USE is a keyboard key; no hand performed it. The card
	// has stated the answer since the day it was written -- OFFHAND wing
	// reads "hold USE to take", MAINHAND wing reads "tap USE to take"
	// (RS_DropTriptych.Header) -- so that is the documented default and
	// this implements the promise rather than inventing a new one:
	//
	//     TAP  -> mainhand      HOLD -> offhand
	//
	// It is only a DEFAULT. If a hand is pointing at a live row when the
	// key goes down, that row and that hand win; the hint is what decides
	// when nothing is being pointed at.
	//
	// WHEN USE IS LEFT ALONE. Doors matter more than convenience, so the
	// swallow is deliberately narrow -- RS_PanelDropHandler.CanTake
	// requires a card up, a payload, a hand that can actually receive it,
	// and the drop in front of you. And a press that BEGAN before any of
	// that was true is never ours: walk into a card's radius with USE
	// already held and the button still belongs to the door.
	// -----------------------------------------------------------------
	// No `tracked` parameter, unlike CaptureAttack: USE is USE whether or
	// not controllers are driving the poses, and a VR player with USE on
	// a controller face button gets the same two gestures.
	static void CaptureUse(PlayerPawn pawn, RS_PanelHandler ph)
	{
		let dh = RS_PanelDropHandler(EventHandler.Find("RS_PanelDropHandler"));

		if (!RS_PanelController.UseTakeEnabled() || !dh || !dh.CanTake(pawn))
		{
			ph.mUseHeld  = 0;
			ph.mUseArmed = false;
			ph.mUseFired = false;
			return;
		}

		let p = pawn.player;
		bool down    = (p.original_cmd.buttons      & BT_USE) != 0;
		bool wasDown = (p.original_oldbuttons       & BT_USE) != 0;

		if (down)
		{
			if (!wasDown)
			{
				ph.mUseHeld  = 0;
				ph.mUseFired = false;
				ph.mUseArmed = true;
			}

			// Not ours: this press was already running before the card
			// offered anything. Leave it in cmd and let the door have it.
			if (!ph.mUseArmed) return;

			p.cmd.buttons &= ~BT_USE;
			ph.mUseHeld++;

			if (!ph.mUseFired && ph.mUseHeld >= RS_PanelController.UseHoldTics())
			{
				ph.mUseFired = true;
				Confirm(0);              // HOLD -> offhand
			}
			return;
		}

		// Released. A press that never reached the hold threshold was a
		// tap -- and mUseHeld > 0 is what distinguishes a real tap from
		// the button simply being up, which is most tics.
		if (ph.mUseArmed && !ph.mUseFired && ph.mUseHeld > 0)
			Confirm(1);                  // TAP -> mainhand

		ph.mUseHeld  = 0;
		ph.mUseArmed = false;
		ph.mUseFired = false;
	}
}
