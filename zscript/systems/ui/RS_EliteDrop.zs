// =====================================================================
// RS_EliteDrop -- the thing the triptych card is FOR.
//
// The elite system is complete: 17 types, boosted health at spawn,
// hidden until 50%, a full reveal with powers and a pentagram. What it
// has never had is a payout. RS_Elite.zs says so in its own header --
// "the weapon-tier drop arms at the reveal; the drop system itself is a
// later step" -- and the options menu already promises the player that
// "an elite killed before revealing pays nothing", describing a rule
// that nothing enforced because nothing paid at all. This is that step.
//
// THE DROP IS A PEDESTAL, NOT A WEAPON ACTOR. That is deliberate and it
// dodges two live traps at once:
//
//   1. RS_ClassGating.WorldThingSpawned DESTROYS a world-spawned
//      RS_Weapon whose family does not match the player's class, and
//      leaves a Clip behind. An elite drop that IS an RS_Weapon would
//      be eaten before the player ever saw it.
//   2. Vanilla pickup of a class the player ALREADY OWNS converts the
//      weapon to ammo and calls GoAwayAndDie -- so the rolled
//      Prototype you were comparing evaporates on touch. With six class
//      weapons and a dual-wield loadout, that is the common case, not
//      the edge case.
//
// So the pedestal holds an inert weapon instance as its payload. The
// instance is real, its stats are really rolled, and the card reads it
// directly -- but it is not in the pickup path, so neither trap fires.
// Taking it is our own transfer, not Inventory::TryPickup.
//
// TWO-STAGE PRESENCE. The pedestal always glows, at any range. The CARD
// only materialises inside RS_PanelController.CardRadius and despawns
// when you leave -- spawn/despawn on radius rather than an alpha fade,
// so a map full of drops costs a marker each and not a live panel set
// each.
// =====================================================================

class RS_WeaponDrop : Actor
{
	Weapon   mPayload;       // the real, rolled instance the card reads
	RS_Panel mBeam;          // the vertical marker glow
	bool     mCardUp;
	int      mTier;

	Default
	{
		+NOGRAVITY
		+NOBLOCKMAP
		+NOINTERACTION
		+BRIGHT
		Radius 16;
		Height 16;
		// No RenderStyle/Alpha here on purpose. This actor's sprite is
		// TNT1 -- it is a positional anchor, never drawn. The visible
		// drop is its payload weapon and its beam, which carry their
		// own styles. Setting them here read as intent and did nothing.
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}

	static RS_WeaponDrop Create(Vector3 where, class<Weapon> what, int tier)
	{
		let d = RS_WeaponDrop(Actor.Spawn("RS_WeaponDrop", where));
		if (!d) return null;

		d.mTier = tier;

		// The payload IS the marker. It keeps its own pickup sprite --
		// so you can still tell a shotgun from a revolver across a room
		// -- and takes a luminance-preserving tier tint on top of it.
		// Only its pickup behaviour is removed, not its visibility.
		//
		// THE FLAG IS NOT OPTIONAL. This is a world spawn of a real
		// RS_Weapon, so it goes through WorldThingSpawned like any floor
		// pickup -- which means RS_ClassGating destroys it outright when its
		// family does not match the player's class, and Vanilla+ may swap it
		// for something else. On a Dual_X class that silently ate four of
		// the six possible drops INSIDE this Spawn call: w came back null,
		// mPayload stayed null, and the pedestal deleted itself on its next
		// tic, leaving a Clip on the floor where the drop should have been.
		// The pedestal design dodges the two PICKUP traps; it never dodged
		// this one, which fires at spawn.
		let dh = RS_PanelDropHandler(EventHandler.Find("RS_PanelDropHandler"));
		if (dh) dh.mSpawningDrop = true;

		let w = Weapon(Actor.Spawn(what, where));

		// Cleared immediately and unconditionally -- the exempt window is
		// exactly this one Spawn, so nothing can ride through behind it.
		if (dh) dh.mSpawningDrop = false;

		if (w)
		{
			w.bSpecial       = false;
			w.bNoInteraction = true;
			w.bNoGravity     = true;
			w.A_ChangeLinkFlags(1);      // bNoBlockmap is not directly assignable

			// Rarity tint. '%' in TRNSLATE is a DESATURATED remap: the
			// engine interpolates along the range using each pixel's
			// LUMINANCE, so shading and shape survive and only hue
			// changes. A plain index remap would scramble the sprite,
			// because Doom's palette is not ordered by brightness.
			w.A_SetTranslation(RS_PanelController.TierTranslation(tier));

			// Soft dynamic light in the tier colour. Attached to the
			// weapon rather than the pedestal so it sits where the
			// object visually is.
			Color glow = RS_PanelController.TierGlow(tier);
			w.A_AttachLight('RSDropGlow', DynamicLight.PointLight, glow,
				RS_PanelController.LightRadius(),
				RS_PanelController.LightRadius() / 2,
				0, (0, 0, 8));

			// Every world spawn in this project hardcodes VRT_Basic --
			// PostBeginPlay rolls Basic and nothing else ever re-rolls.
			// An elite drop that is meant to span the ladder has to say
			// so explicitly. RollStats is per-instance and re-callable,
			// so this is cheap and it is the ONLY way a non-Basic
			// weapon reaches the world today.
			let rsw = RS_Weapon(w);
			// EVR_Tier(x) is not a cast -- ZScript has no enum-constructor
			// syntax, so it parses as a call to an undefined function. An
			// int converts to the enum parameter on its own.
			if (rsw) rsw.RollStats(tier);

			d.mPayload = w;
		}

		d.RaiseBeam();
		return d;
	}

	// -----------------------------------------------------------------
	// THE BEAM. A thin vertical glow rising out of the pickup and
	// tapering to nothing around eye level, so a drop reads from across
	// a room without a HUD marker painted on your face.
	//
	// It is a PANEL, not a stack of sprite actors: one camera-facing
	// quad wearing a shared gradient canvas, tinted per tier through
	// AddStencil. So every beam in a map costs one canvas between them
	// and one quad each, and the taper is exact rather than approximated
	// by stepping alpha down a column of actors.
	// -----------------------------------------------------------------
	void RaiseBeam()
	{
		if (!RS_PanelController.BeamEnabled()) return;
		if (mBeam) return;

		// From the pickup up to roughly standing eye level. The taper is
		// painted INTO the gradient, so the quad is a plain rectangle
		// and the fade is texture, not geometry. Cvar-driven because it
		// is the number that decides whether the taper actually dies at
		// eye level, and eye level is per-player in VR.
		double h = RS_PanelController.BeamHeight();

		mBeam = RS_Panel.Create((pos.x, pos.y, pos.z + h * 0.5),
			"RSPNLBM", RS_PanelController.BeamWidth(), h, 0);

		if (mBeam)
		{
			mBeam.mFacing = RSPF_CameraYaw;
			mBeam.SetTint(RS_PanelController.TierGlow(mTier));
		}
	}

	override void Tick()
	{
		Super.Tick();
		if (!mPayload) { Destroy(); return; }

		// Keep the payload with the pedestal so a card reading it never
		// finds it somewhere else.
		mPayload.SetOrigin(pos, true);

		// The beam is not part of an assembly -- it has no parent and no
		// hinge -- so it re-aims itself here.
		if (mBeam)
		{
			PlayerPawn viewer = players[consoleplayer].mo;
			if (viewer)
			{
				mBeam.FaceViewer((viewer.pos.x, viewer.pos.y,
				                  viewer.player ? viewer.player.viewz : viewer.pos.z + 41));
				mBeam.ApplyOrientation();
			}
		}

		let handler = RS_PanelDropHandler(EventHandler.Find("RS_PanelDropHandler"));
		if (handler) handler.ConsiderDrop(self);
	}

	override void OnDestroy()
	{
		if (mPayload) mPayload.Destroy();
		if (mBeam)    mBeam.Destroy();
		Super.OnDestroy();
	}
}

// =====================================================================
// RS_PanelDropHandler -- arms the drop on an elite kill, and owns the
// radius that decides whether a card is up.
//
// MUST also be listed in MAPINFO.txt's AddEventHandlers.
// =====================================================================
class RS_PanelDropHandler : EventHandler
{
	RS_DropTriptych mCard;
	RS_WeaponDrop   mCardOwner;

	// PLAY, and it must stay play: PaintBeamTexture writes it, and that
	// painter is called from WorldThingDied (play), not from RenderOverlay.
	// Marking either of them `ui` breaks the pair -- a ui function cannot
	// write a play field, and a play context cannot call a ui function.
	bool            mBeamPainted;

	// Set only for the duration of the payload's Spawn call in
	// RS_WeaponDrop.Create, and read by RS_ClassGating.WorldThingSpawned so
	// class gating and Vanilla+ leave an elite drop alone. It lives here
	// because ZScript has no mutable statics; play scope is correct because
	// both the writer and the reader are play.
	bool            mSpawningDrop;

	// Last row the pointer rested on, so the hover chirp fires on CHANGE
	// rather than 35 times a second.
	int             mLastHotRow;
	int             mLastHotPanel;

	// The six RS class weapons.
	//
	// THE CLASSES ARE VR_*, NOT RS_*. The FILES are RS_Revolver.zs and
	// so on, but every class inside them is `class VR_Revolver :
	// RS_Weapon`. Naming these from the filenames is a silent failure,
	// not an error: Spawn() on a class that does not exist returns null,
	// the drop never appears, and nothing is logged. It has bitten this
	// project before -- four dead MODELDEF entries from the same
	// confusion. Five of these six were wrong on first write.
	//
	// A switch and not a static array literal: `static const
	// class<Weapon> x[] = {...}` does not reliably resolve on this
	// engine build and has produced a bogus "Unknown identifier" three
	// separate times in this tree.
	static class<Weapon> ClassWeapon(int i)
	{
		switch (i)
		{
			case 0: return "VR_Revolver";
			case 1: return "VR_Rifle";
			case 2: return "VR_Shotgun";
			case 3: return "VR_SMG";
			case 4: return "VR_Chaingun";
			default: return "VR_PlasmaRifle";
		}
	}

	static bool DropsEnabled()
	{
		let cv = CVar.FindCVar("rs_elitedrop_enabled");
		return cv ? cv.GetBool() : true;
	}

	// -----------------------------------------------------------------
	// THE PAYOUT GATE. An elite killed before it revealed pays nothing.
	// That is the contract the elite system's own header states and the
	// options menu already advertises to the player; this is the first
	// code that honours it.
	// -----------------------------------------------------------------
	override void WorldThingDied(WorldEvent e)
	{
		if (!DropsEnabled()) return;
		if (!e.Thing || !e.Thing.bIsMonster) return;

		// Paint the shared beam gradient before the first drop can raise a
		// beam. Self-guarding on mBeamPainted, so this is one canvas write
		// per level no matter how many elites die.
		PaintBeamTexture();

		let tok = RS_EliteToken(e.Thing.FindInventory("RS_EliteToken"));
		if (!tok || !tok.revealed) return;

		// -------------------------------------------------------------
		// ELIGIBILITY GATE (owner's direct instruction, 2026-08-06).
		// Elites only drop for a class whose weapon carries the VR_
		// prefix -- checked once, generically, off GetMainhandClass()
		// rather than a hardcoded list of which classes qualify. A
		// GH/PS/CZ-prefixed class (RS_GH_Weaponset, RS_PS_Weaponset, and
		// any future weapon set) currently gets NOTHING from elites --
		// not a bug, the stated default. If a weapon set is ever brought
		// into the VR_ system, it becomes elite-eligible for free, with
		// no change needed here.
		// -------------------------------------------------------------
		let pc = VR_DualClassBase(players[0].mo);
		if (!pc) return;
		if (pc.GetMainhandClass().Left(3) != "VR_") return;

		// Rate control. Before this every revealed elite dropped, which
		// was never a decision -- just a question nobody asked.
		if (random[RSDrop](1, 100) > RS_PanelController.DropChance()) return;

		// The ceiling is per-player, so the roll needs the pawn. Player 0
		// deliberately, matching the rest of this handler's single-player
		// assumptions -- flagged rather than hidden.
		int tier = RollDropTier(players[0].mo);

		// -------------------------------------------------------------
		// THE CLASS WEAPON, NOT THE OLD 6-TYPE LOOP (owner's direct
		// instruction, 2026-08-06). An elite drop is now another copy
		// of THIS PLAYER'S OWN weapon type, gap-filled in the same
		// order (2, 3, then 5, 6) pedestals use -- via the SAME
		// function, RS_ClassGating.NextMissingIdentity, so the two
		// triggers can never disagree about what's still missing.
		//
		// All six already owned: nothing to drop here. The OTHER side
		// of the eligible-elite branch -- a data/rarity packet -- is
		// deliberately not built yet; its content and visuals are
		// still undecided, and a placeholder would be worse than an
		// honest no-op.
		// -------------------------------------------------------------
		string mainhand = pc.GetMainhandClass();
		string gap = RS_ClassGating.NextMissingIdentity(players[0].mo, mainhand);
		if (gap == "") return;

		Vector3 where = (e.Thing.pos.x, e.Thing.pos.y, e.Thing.pos.z + 8);
		RS_WeaponDrop.Create(where, mainhand .. gap, tier);
	}

	// -----------------------------------------------------------------
	// HOW MANY OF THE SIX CLASS WEAPONS THIS PLAYER HAS FOUND.
	//
	// Ownership, not what is in your hands -- you only carry two at a
	// time, so "holding" would be a meaningless test. FindInventory
	// answers for the whole inventory.
	// -----------------------------------------------------------------
	static int ArsenalCount(PlayerPawn pawn)
	{
		if (!pawn) return 0;
		int n = 0;
		for (int i = 0; i < 6; i++)
		{
			let c = ClassWeapon(i);
			if (c && pawn.FindInventory(c)) n++;
		}
		return n;
	}

	// -----------------------------------------------------------------
	// THE CEILING RISES WITH THE ARSENAL. The floor never moves.
	//
	// rs_00's original rule was a CLIFF -- only Cursed/Trash/Basic until
	// all six are found, then the whole ladder at once. That enforced
	// hunting the guns, which is right, but nothing changed for four
	// kills and then everything changed in one step; and a player unlucky
	// at finding weapons had no way to influence it.
	//
	// Shifting the ODDS instead would fix the cliff and be invisible --
	// 30% becoming 35% is not something a player can perceive over the
	// handful of drops they will actually see. They would just conclude
	// loot is random.
	//
	// So each weapon found unlocks a TIER, which the player can see
	// happen:
	//
	//     2 owned -> Basic        (the start: two class weapons)
	//     3       -> Common
	//     4       -> Uncommon
	//     5       -> Advanced
	//     6       -> Prototype    (completing the set unlocks the top)
	//
	// THE POOL WIDENS, IT DOES NOT SLIDE. The floor stays Cursed at every
	// stage on purpose. Per rs_00 those bottom tiers are not merely
	// "bad": a Cursed weapon is powerful with its stats locked behind
	// individual curses, and Trash has the small "Trash to Treasure"
	// chance of an exceptional roll. Both stay interesting forever, so a
	// Prototype-capable player still finding a Cursed is a gamble rather
	// than a disappointment.
	//
	// Knock-on that falls out for free: rs_00 gives Cursed/Trash/Basic no
	// GunBonsai sockets. Under a rising ceiling that stops being a phase
	// of the game and becomes a permanent property -- the bottom three
	// tiers are stat-only, always.
	// -----------------------------------------------------------------
	static int TierCeiling(int owned)
	{
		if (owned >= 6) return VRT_Prototype;
		if (owned == 5) return VRT_Advanced;
		if (owned == 4) return VRT_Uncommon;
		if (owned == 3) return VRT_Common;
		return VRT_Basic;               // 0-2 owned: the starting window
	}

	// Weighted toward the bottom of whatever window is open, so the top
	// of the ladder stays an event rather than a Tuesday. Rolling a
	// position in the window rather than a fixed table means the same
	// curve applies however wide the window is.
	static int RollDropTier(PlayerPawn pawn)
	{
		int top = TierCeiling(ArsenalCount(pawn));
		int span = top - VRT_Cursed;          // 2 at the start, 7 complete

		// Two rolls, lower kept. A clean triangular bias to the floor --
		// no table to keep in step with the tier enum, and it degrades
		// correctly at span 0.
		int a = random[RSDropTier](0, span);
		int b = random[RSDropTier](0, span);
		return VRT_Cursed + min(a, b);
	}

	// -----------------------------------------------------------------
	// Radius. One card at a time -- the nearest drop wins, so walking
	// past a field of them reads as the card following you rather than
	// nine cards fighting for the same air.
	// -----------------------------------------------------------------
	void ConsiderDrop(RS_WeaponDrop d)
	{
		if (!RS_PanelController.Enabled()) return;

		PlayerPawn pawn = players[consoleplayer].mo;
		if (!pawn) return;

		double dist = (d.pos - pawn.pos).Length();
		double r    = RS_PanelController.CardRadius();

		if (dist <= r && mCardOwner != d)
		{
			// A nearer drop takes the card off a farther one.
			if (mCardOwner && (mCardOwner.pos - pawn.pos).Length() <= dist) return;
			RaiseCard(pawn, d);
		}
		else if (dist > r && mCardOwner == d)
		{
			DropCard();
		}
	}

	void RaiseCard(PlayerPawn pawn, RS_WeaponDrop d)
	{
		DropCard();
		if (!d || !d.mPayload) return;

		mCard = RS_DropTriptych.Build(pawn, d, d.mPayload);
		if (!mCard) return;

		// The card belongs to the reader: it holds a comfortable
		// distance in front of you on the line toward the drop, at eye
		// level, instead of being pinned to the pickup. Walking up to a
		// drop must not shove the card into your face.
		if (mCard.mAsm)
		{
			mCard.mAsm.mComfort     = true;
			mCard.mAsm.mComfortDist = RS_PanelController.Comfort();
		}

		mCardOwner = d;
		d.mCardUp  = true;

		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		if (ph && mCard.mAsm) ph.RegisterAssembly(mCard.mAsm);
	}

	void DropCard()
	{
		if (mCard)
		{
			let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
			if (ph && mCard.mAsm) ph.DropAssembly(mCard.mAsm);
			mCard.Dismiss();
		}
		mCard = null;
		if (mCardOwner) mCardOwner.mCardUp = false;
		mCardOwner = null;

		// Otherwise the next card that comes up on the same row index
		// starts already-hovered and never chirps.
		mLastHotRow   = -1;
		mLastHotPanel = -1;
	}

	// -----------------------------------------------------------------
	// ROW RESOLUTION, in one place.
	//
	// Geometry (which panel, and where on it) belongs to
	// RS_PanelHandler; CONTENT (what row that is) belongs to the card,
	// which this handler owns. Every consumer of "what row is under the
	// pointer" -- the painter, the confirm netevent, and now the
	// trigger capture -- comes through here, so the highlight you see,
	// the row that fires, and the press that is eaten cannot disagree
	// about which row it was.
	// -----------------------------------------------------------------
	int ResolveHotRow(RS_PanelHandler ph, out bool live)
	{
		live = false;
		if (!mCard || !ph || ph.mHotPanel < 0) return -1;

		let c = mCard.CardFor(ph.mHotPanel);
		if (!c) return -1;

		int row = c.RowAtUV(ph.mHotUV);
		live = c.RowIsSelectable(row);
		return row;
	}

	// Publish it where the trigger capture can see it. That capture runs
	// in VR_DualClassBase.PlayerThink, which is upstream of every event
	// handler on this tic (p_tick.cpp:175 vs :178) and has no route to a
	// card -- so the answer has to be left somewhere it can read.
	//
	// Also where the panel makes its two noises that are not tied to an
	// action: the hover chirp, and a punch landing.
	override void WorldTick()
	{
		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		if (!ph) return;

		bool live;
		int row = ResolveHotRow(ph, live);
		ph.PublishHotRow(row, live);

		PlayerPawn pawn = players[consoleplayer].mo;

		// HOVER. Only LIVE rows chirp. Sweeping a hand across a card of
		// twenty stat rows must not chatter -- the sound has to mean
		// "there is something here", or it means nothing.
		if (live && (row != mLastHotRow || ph.mHotPanel != mLastHotPanel))
			RS_PanelInput.Say(pawn, "menu/cursor");

		if (live) { mLastHotRow = row;  mLastHotPanel = ph.mHotPanel; }
		else      { mLastHotRow = -1;   mLastHotPanel = -1; }

		// THE PUNCH. Read-and-clear even when the row is dead, so a
		// swing at an inert part of the card is spent rather than banked
		// and delivered to whatever row you point at next.
		int strike = ph.ConsumePokeStrike();
		if (strike >= 0 && live)
			EventHandler.SendNetworkEvent("rs-panel-use", 0);
	}

	// -----------------------------------------------------------------
	// Taking the drop. NOT vanilla pickup -- see the file header. The
	// payload instance is handed to the player intact, with its roll,
	// its condition and its locks, and the weapon it displaces goes
	// back onto the pedestal so the trade is reversible.
	// -----------------------------------------------------------------
	override void NetworkProcess(ConsoleEvent evt)
	{
		if (evt.player < 0) return;
		PlayerPawn pawn = players[evt.player].mo;
		if (!pawn || !pawn.player) return;

		// -------------------------------------------------------------
		// THE CONFIRM. This is what makes an in-world panel usable at
		// all: it resolves whatever row the pointing hand is on and
		// fires that row's own netevent.
		//
		// It is deliberately GENERIC -- it dispatches whatever `cmd` the
		// row carries, so every future panel gets a working confirm for
		// free and no new bind is ever needed. Rows with an empty cmd
		// are inert text and are ignored.
		//
		// Resolution happens HERE, in play scope, not in the painter.
		// RS_PanelHandler owns geometry (which panel, and where on it);
		// the card owns content (which row that is). Keeping the row
		// lookup on the content side is why the handler carries a uv
		// and not a row number.
		// -------------------------------------------------------------
		if (evt.name == "rs-panel-use")
		{
			if (!mCard) return;

			let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
			if (!ph) return;

			bool live;
			int row = ResolveHotRow(ph, live);
			if (!live) return;

			let c = mCard.CardFor(ph.mHotPanel);
			if (!c) return;

			// ACKNOWLEDGE THE PRESS ITSELF, before dispatching what it
			// meant. Two sounds, two facts: this one says the button
			// registered, and whatever the row does says whether it
			// worked. That split matters here more than in a flat menu,
			// because the press was CONSUMED -- your gun deliberately did
			// not fire, and without a click that is indistinguishable
			// from an input that went nowhere.
			//
			// It also means a future row that forgets its own sound is
			// merely terse rather than silent.
			RS_PanelInput.Say(pawn, "menu/activate");

			// Re-enter NetworkProcess with the row's own command. Sending
			// the netevent rather than calling the branch directly keeps
			// one dispatch path, so a row behaves identically whether it
			// was pointed at or fired from the console.
			EventHandler.SendNetworkEvent(c.mCmd[row], c.mArg[row]);
			return;
		}

		if (evt.name == "rs-panel-take")
		{
			if (!mCardOwner || !mCardOwner.mPayload) return;

			let w = mCardOwner.mPayload;

			// WHICH HAND TAKES IT IS THE HAND THAT POINTED.
			//
			// The row carries a fallback (the wing you aimed at implies
			// a hand, and flat play has no controllers), but when VR is
			// really driving the poses the physical gesture wins: reach
			// out with your left controller and the drop lands in your
			// left hand. That collapses the Hand Law into something you
			// do rather than something you remember, and it costs no
			// bind and no extra row.
			bool toOffhand = (evt.args[0] == 0);

			let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
			if (ph && ph.mHotHand >= 0 && pawn.OverrideAttackPosDir)
			{
				// THE POINTING HAND WINS -- BUT ONLY IF IT CAN TAKE.
				//
				// This override used to be unconditional, and that made
				// a dead trigger. A row only EXISTS on a wing whose hand
				// holds a real weapon, but the override re-aimed the
				// take at whichever hand was pointing. Hold a fist in
				// your left, a revolver in your right, and point the
				// left at "> TAKE TO MAINHAND": the row was live, so the
				// press got eaten, then the take resolved to the fist
				// and bailed. Button swallowed, gun silent, nothing
				// taken, no feedback.
				//
				// The row's own arg is the fallback and it is always
				// valid -- Refresh only writes the row when that hand is
				// a real weapon. So a fist can point at the other hand's
				// row and mean exactly what it looks like it means.
				bool wantOff = (ph.mHotHand == 0);
				Weapon wantHeld = wantOff ? pawn.player.OffhandWeapon
				                          : pawn.player.ReadyWeapon;
				// IsRealFist, NOT `is "VR_Fist"` -- and this is the second
				// site of the same mistake, which is why it is spelled out
				// here as well as at the guard below.
				//
				// VR_Fist2 : VR_Fist, and VR_Fist4/VR_Fist6 sit under
				// VR_Fist2, so a bare `is "VR_Fist"` is TRUE for the
				// empty-slot filler every class grants at spawn. The
				// condition then reads false, the override never applies,
				// and toOffhand falls back to the row's arg.
				//
				// Symptom: point at TAKE TO MAINHAND with an EMPTY left
				// hand, and the drop goes to the mainhand and displaces a
				// real weapon -- in the one case where the hand you pointed
				// with was free and the take was guaranteed to work. The
				// exact inversion of the intent, and silent.
				//
				// This line did not conflict during the merge that fixed
				// its twin twenty lines down, so nothing surfaced it. That
				// is the whole argument for auditing what git auto-merges,
				// not just what it stops to ask about.
				if (!RS_DropTriptych.IsRealFist(wantHeld)) toOffhand = wantOff;
			}

			// Fists never take a class weapon -- the card says so and
			// the netevent honours it, so the two cannot disagree.
			//
			// VR_Fist2 IS NOT A FIST FOR THIS PURPOSE. It is the empty-slot
			// filler every class grants at spawn, and RS_Weapon.AttachToOwner
			// treats it as "slot is free" (RS_Weapon.zs:1334). Blocking on
			// plain `is "VR_Fist"` blocked VR_Fist2 too -- which is the one
			// case where the take would definitely have worked.
			//
			// MERGE NOTE: the test is IsRealFist (which honours the VR_Fist2
			// exception) and the sound is the interaction lane's. Its version
			// used a bare `is "VR_Fist"`, which would have rejected the empty
			// slot -- but it was right that a silent return here is
			// indistinguishable from a broken button, now that the press has
			// already been taken away from the weapon. Both halves kept.
			Weapon held = toOffhand ? pawn.player.OffhandWeapon
			                        : pawn.player.ReadyWeapon;
			if (RS_DropTriptych.IsRealFist(held))
			{
				RS_PanelInput.Say(pawn, "menu/invalid");
				return;
			}

			mCardOwner.mPayload = null;

			w.bInvisible     = false;
			w.bNoInteraction = false;
			w.bOffhandWeapon = toOffhand;
			w.AttachToOwner(pawn);

			// SEATING IS EXPLICIT, AND THAT IS THE WHOLE POINT OF THE ROW.
			//
			// AttachToOwner alone is not a take. It only seats the offhand
			// when that slot is empty or holds the VR_Fist2 filler
			// (RS_Weapon.zs:1334), and it never touches the mainhand at all
			// -- so with a real weapon in the hand you pointed at, which is
			// the normal case, the drop silently joined inventory, the card
			// and the pedestal vanished, and your hands were unchanged. The
			// take appeared to succeed and did nothing.
			//
			// PendingWeapon, not a direct OffhandWeapon/ReadyWeapon write:
			// CheckWeaponChange reads PendingWeapon.bOffhandWeapon to pick
			// the hand (player.zs:514) and then lowers and raises properly.
			// Assigning the slot by hand would teleport the gun into view
			// and leave WeaponState out of step.
			//
			// It is also why this is a PendingWeapon and not A_SelectWeapon,
			// which the wheel uses: A_SelectWeapon resolves by CLASS through
			// FindInventory, and if the player already owns a weapon of this
			// class it would raise THAT one and leave the rolled drop -- the
			// entire reason the card exists -- sitting unused in inventory.
			// Seating the instance is the only correct move here.
			pawn.player.PendingWeapon = w;

			// The drop is in your hand. Vanilla's own weapon-pickup sound,
			// because that is exactly what just happened -- even though this
			// deliberately never went through the pickup path (see the file
			// header).
			//
			// MERGE NOTE: the interaction lane's branch had this sound INSTEAD
			// of the PendingWeapon seating above, which would have made the
			// take announce itself and then do nothing -- the exact failure
			// the seating comment describes. Both kept, seat first.
			RS_PanelInput.Say(pawn, "misc/w_pkup");

			DropCard();
		}
		else if (evt.name == "rs-panel-dismiss")
		{
			if (mCard) RS_PanelInput.Say(pawn, "menu/clear");
			DropCard();
		}
		else if (evt.name == "rs-panel-test")
		{
			// Dev harness: drop a rolled class weapon in front of you
			// without needing an elite. `netevent rs-panel-test <tier>`
			int tier = evt.args[0];
			if (tier < 0 || tier > 7) tier = RollDropTier(pawn);
			Vector3 spot = pawn.Vec3Angle(96, pawn.angle);
			spot.z = pawn.pos.z + 16;
			RS_WeaponDrop.Create(spot, ClassWeapon(random[RSDrop](0, 5)), tier);
		}
	}

	// -----------------------------------------------------------------
	// The painter. This runs in ui scope because RenderOverlay IS a ui
	// override -- the engine declares it that way. NOT because canvases
	// are a UI-side surface: they aren't. `class Canvas : Object native
	// abstract` has unscoped methods (base.zs:529) and TexMan.GetCanvas
	// is a plain native static (base.zs:332), so canvas painting needs
	// no ui context anywhere.
	//
	// That distinction is not pedantry -- it caused a real bug. Believing
	// "canvas work must be ui" is what got `ui` put on PaintBeamTexture
	// below, which made the play field it writes read-only to it and
	// produced an "Expression must be a modifiable value" that looked
	// like it was about the field rather than the scope.
	//
	// Solving where the panels ARE is play scope and lives in
	// RS_PanelHandler; this half only draws.
	//
	// Canvas content is uploaded before the 3D scene is rendered each
	// frame, so a card painted here is on the GPU by the time the panel
	// quads sample it. No one-frame lag.
	// -----------------------------------------------------------------
	override void RenderOverlay(RenderEvent e)
	{
		// PaintBeamTexture is NOT called here. RenderOverlay is a `ui`
		// override -- the engine declares it that way -- and the painter is
		// play scope because it writes mBeamPainted. It runs from
		// WorldThingDied instead, which is play and fires before any beam
		// can exist. Painting is a one-time texture write, not per-frame
		// work, so it never belonged in a render hook anyway.
		if (!mCard) return;

		let ph = RS_PanelHandler(EventHandler.Find("RS_PanelHandler"));
		int hotPanel = ph ? ph.mHotPanel : -1;

		// READ the published row; do not re-resolve it here.
		//
		// This used to call RowAtUV itself, and still COULD -- RowAtUV
		// lives on RS_PanelCard, an unscoped class, so ui may call it,
		// and reading play fields like mHotUV from ui is legal. What it
		// cannot do is share ResolveHotRow with the confirm path:
		// RenderOverlay is `virtual ui void` (events.zs:181) and
		// StaticEventHandler is `native play` (events.zs:147), so that
		// resolver is play-only.
		//
		// So the choice was two copies of the same lookup or one lookup
		// published once. Published wins: the highlight is now literally
		// the number the trigger capture will act on, rather than a
		// second computation that merely ought to agree with it -- and
		// "agrees with itself" is the failure mode this project keeps
		// paying for.
		//
		// Nothing is lost by not resolving per frame: mHotUV is solved
		// in WorldTick, so it only changes per tic regardless.
		int hotRow = ph ? ph.mHotRow : -1;

		for (int i = 0; i < TRI_COUNT; i++)
		{
			let c = mCard.CardFor(i);
			if (!c) continue;
			c.Paint(i == hotPanel ? hotRow : -1);
		}
	}

	// The beam gradient, painted ONCE and shared by every beam in the
	// map. White on purpose -- each beam tints it through fillcolor, so
	// one texture serves all eight tiers.
	//
	// The taper lives here rather than in geometry: full strength at the
	// bottom where it leaves the pickup, fading to nothing by the top so
	// it dies out around eye level instead of ending in a hard edge.
	// Squaring the fade keeps it bright near the object and makes the
	// last third almost vapour.
	// PLAY, AND CALLED FROM WorldThingDied -- NOT FROM RenderOverlay.
	//
	// This is a scope pair and there is no third option. An unscoped method
	// in a class descending from `StaticEventHandler : Object native play`
	// is a PLAY function, and RenderOverlay is `virtual ui` (events.zs:181)
	// -- an override with no qualifier inherits that ui scope
	// (zcc_compile.cpp:2841). So calling this from RenderOverlay is "Can't
	// call play function ... from ui context" (scopebarrier.cpp:204), and
	// marking it `ui` to fix that makes the mBeamPainted write below fail
	// instead, because ui cannot write a play field. An earlier pass tried
	// both halves in turn and traded one error for the other.
	//
	// The way out is not a scope keyword, it is the call site: this is a
	// one-time texture write, not per-frame work, so it belongs in play
	// where its flag already lives. Do not move it back into the painter.
	void PaintBeamTexture()
	{
		if (mBeamPainted) return;
		let cv = TexMan.GetCanvas("RSPNLBM");
		if (!cv) return;

		cv.Clear(0, 0, 32, 256, Color(0, 0, 0, 0));

		for (int y = 0; y < 256; y++)
		{
			// y = 0 is the TOP of the canvas, which is the top of the
			// beam -- so strength rises as y does.
			double t = double(y) / 255.0;
			double a = t * t;

			// Narrow the core toward the top as well, so it reads as a
			// taper and not just a fade.
			int inset = int((1.0 - t) * 12.0);
			int a8 = int(a * 255.0);
			cv.Clear(inset, y, 32 - inset, y + 1, Color(a8, 255, 255, 255));
		}
		mBeamPainted = true;
	}

	override void WorldUnloaded(WorldEvent e)
	{
		DropCard();
	}
}
