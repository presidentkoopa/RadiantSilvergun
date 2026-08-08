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
		// EXEMPTION FROM CLASS GATING -- HOW IT ACTUALLY WORKS, 2026-08-07.
		//
		// This is a world spawn of a real RS_Weapon, so it goes through
		// WorldThingSpawned like any floor pickup -- which means
		// RS_ClassGating would destroy or convert it, and Vanilla+ might
		// swap it. That is a real hazard and it needed a real exemption.
		//
		// It USED to be a boolean window: set dh.mSpawningDrop true, spawn,
		// set it false, with a comment promising "the exempt window is
		// exactly this one Spawn." That was wrong at the root, because
		// WorldThingSpawned is NOT synchronous -- the engine defers it to
		// the fresh-thinker pass (p_mobj.cpp:5164 via dthinker.cpp:602-611),
		// so the flag was always back to false by the time the payload's
		// event arrived. The exemption never once applied, and on a Dual_X
		// class every elite drop fell into the class-gating fill loop.
		//
		// THE PAYLOAD IS NOW RECOGNISED BY ITS OWN STATE instead. The
		// bSpecial=false / bNoInteraction=true pair below is set before the
		// deferred event can fire, and nothing else on a floor is ever
		// non-interactive, so RS_ClassGating simply checks that. No window,
		// nothing to keep in sync across two files, and it cannot rot the
		// way a flag did.
		let w = Weapon(Actor.Spawn(what, where));

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
			if (rsw)
			{
				rsw.RollStats(tier);

				// RE-ANCHOR THE PROMOTION/CEILING BASELINE ON THE ROLL THE
				// PLAYER ACTUALLY GETS. PostBeginPlay already rolled this
				// weapon at Basic a moment ago and captured THAT number as
				// the baseline; the RollStats above then replaced every
				// stat with the real tier's roll, but the capture is
				// "once only" and kept the stale Basic figure. Everything
				// measured against the baseline was therefore measured
				// against a roll that never appeared on the weapon --
				// GetDamageCeiling(), the damage-card gate, and the
				// state-ladder tracer body, which sat pinned at "Peak" on
				// every elite drop in the game.
				rsw.ResetDamageBaseline();
				rsw.CaptureInitialDamageBaseline();
			}

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
	// Tics BT_USE has been held while a live row sits under the hand.
	// Reset the moment the button lifts or the row goes dead, so a hold
	// that wanders off the card does not carry over.
	int             mUseHeld;

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
	// =================================================================
	// THE FOOD SCATTER.
	//
	// Ported from the champions pack's champion_SpawnBundles: how much a
	// dead elite is worth is a function of how much health it had, in
	// six brackets, doubled if you gibbed it and doubled again if it was
	// a boss. That is a good rule and it is kept as-is -- a Cyberdemon
	// elite should bury you in food and a zombieman elite should not.
	//
	// The pack pushed a weighted pool and drew from it; we scatter
	// directly, because the pool only existed so one bundle actor could
	// mix food with ammo and armour, and RS pays those through Kill
	// Rewards instead.
	//
	// SURVIVES RS_NoMonsterDrops BY CONSTRUCTION: that handler suppresses
	// items carrying bTossed, which only A_DropItem sets. A_SpawnItemEx
	// does not, so this is invisible to it -- the same reason kill-reward
	// Bits survive.
	// =================================================================
	static int FoodTierFor(int startHealth)
	{
		if (startHealth >= 2000) return 5;
		if (startHealth >= 1000) return 4;
		if (startHealth >=  500) return 3;
		if (startHealth >=  300) return 2;
		if (startHealth >=  150) return 1;
		return 0;
	}

	void ScatterFood(Actor victim)
	{
		if (!victim) return;

		let cv = CVar.FindCVar("rs_elite_food");
		if (cv && !cv.GetBool()) return;

		int startHealth = victim.SpawnHealth();
		int tier = FoodTierFor(startHealth);

		// The pack's own count, kept: 5% of starting health, floored at 4
		// and capped at 25 so a Cyberdemon does not carpet the map.
		int n = clamp(int(startHealth * 0.05), 4, 25);

		// Gibbed things burst harder.
		if (victim.health <= victim.GetGibHealth()) n *= 2;
		if (victim.bBoss) n *= 2;

		// Scaled by the difficulty the elite actually presented.
		n = int(n * max(1.0, victim.DamageMultiply));

		let mult = CVar.FindCVar("rs_elite_food_mult");
		if (mult) n = int(n * clamp(mult.GetInt(), 0, 400) / 100.0);
		n = clamp(n, 0, 120);

		for (int i = 0; i < n; i++)
		{
			victim.A_SpawnItemEx("RS_FoodBonus",
				0, 0, 8,
				frandom(1.0, 2.0), 0, frandom(8.0, 10.0),
				frandom(0, 359.9),
				SXF_NOCHECKPOSITION);
		}
	}

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

		// FOOD FIRST, AND UNCONDITIONALLY. Owner ruling 2026-08-07:
		// "elites will drop their normal assortment of food icons."
		//
		// Deliberately ahead of every gate below. The weapon drop is
		// gated on a VR_ class, on a percentage roll, and on the player
		// still missing an identity -- so a GH/MeatGrinder player, or one
		// who already owns all six, would otherwise get NOTHING at all
		// from an elite. Food is the payout every class always gets.
		ScatterFood(e.Thing);

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
	// HOW MANY OF THIS PLAYER'S OWN SIX IDENTITIES THEY OWN.
	//
	// CORRECTED 2026-08-06. This used to loop ClassWeapon()'s hardcoded
	// list of 6 DIFFERENT weapon TYPES (Revolver/Rifle/Shotgun/SMG/
	// Chaingun/PlasmaRifle), counting how many different types the
	// player had found at least one of. That list was already wrong on
	// its own terms -- missing Pistol and SuperShotgun, which both have
	// real Dual_X classes (VR_Dual_Pistol, VR_Dual_SSG), and including
	// Plasma, which isn't even a gated family -- and it stopped meaning
	// anything the moment pedestals and elites were rewired to hand out
	// copies of the PLAYER'S OWN type instead of different types. A
	// Dual_Pistol or Dual_SSG player could never advance this count at
	// all, because neither type was in the list, so their tier ceiling
	// was permanently stuck at the starting window regardless of how
	// much they'd actually collected.
	//
	// This now counts the SAME six identities NextMissingIdentity
	// (RS_ClassGating.zs) already tracks for the same player. 1 and 4
	// are the guaranteed spawn grant, so a fresh player starts at 2
	// here -- which is exactly what TierCeiling already expects at
	// "0-2 owned", so its thresholds needed no change, only the count
	// feeding them.
	//
	// Ownership, not what is in your hands -- you only carry two at a
	// time, so "holding" would be a meaningless test. FindInventory
	// answers for the whole inventory. Sequential checks, not a loop
	// over an array: `static const TYPE name[] = {...}` does not
	// reliably resolve on this engine build (see CLAUDE.md).
	// -----------------------------------------------------------------
	static int ArsenalCount(PlayerPawn pawn)
	{
		if (!pawn) return 0;
		let pc = VR_DualClassBase(pawn);
		if (!pc) return 0;
		string mainhand = pc.GetMainhandClass();
		if (mainhand.Length() == 0) return 0;

		int n = 0;
		if (pawn.FindInventory(mainhand))        n++;
		if (pawn.FindInventory(mainhand .. "2")) n++;
		if (pawn.FindInventory(mainhand .. "3")) n++;
		if (pawn.FindInventory(mainhand .. "4")) n++;
		if (pawn.FindInventory(mainhand .. "5")) n++;
		if (pawn.FindInventory(mainhand .. "6")) n++;
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
	// TWO PHASES, NOT A RAMP. Owner ruling 2026-08-07:
	//
	//   "when player has less than six class weapons, elites drop rolled
	//    Basic or Trash class weapons until a player has 6, then drop
	//    frames of trash -> prototype"
	//
	// So the drop does one job at a time. Below six, an elite is how you
	// COMPLETE THE SET -- it hands you a missing identity, and the tier
	// is deliberately poor (Trash or Basic) because the weapon itself is
	// the prize. At six, the set is done and the drop switches jobs
	// entirely: now it is about QUALITY, and the whole Trash-to-Prototype
	// range opens up.
	//
	// This replaces a five-step ramp that raised the ceiling one tier per
	// weapon owned (3 owned -> Common, 4 -> Uncommon, 5 -> Advanced). That
	// blurred the two phases together: a player at five weapons was
	// already being handed Advanced guns, so completing the set stopped
	// meaning anything.
	static int TierCeiling(int owned)
	{
		return owned >= 6 ? VRT_Prototype : VRT_Basic;
	}

	// The floor moves with the phase too. Before the set is complete the
	// window is exactly Trash..Basic; after, it is Trash..Prototype.
	static int TierFloor(int owned)
	{
		return VRT_Trash;
	}

	// Weighted toward the bottom of whatever window is open, so the top
	// of the ladder stays an event rather than a Tuesday. Rolling a
	// position in the window rather than a fixed table means the same
	// curve applies however wide the window is.
	static int RollDropTier(PlayerPawn pawn)
	{
		int owned = ArsenalCount(pawn);
		int top   = TierCeiling(owned);
		int bot   = TierFloor(owned);
		int span  = top - bot;

		// PHASE 1 (under six owned): a flat coin-flip between Trash and
		// Basic. No bias worth having across two values, and the tier is
		// not the point yet -- the missing identity is.
		if (owned < 6)
			return bot + random[RSDropTier](0, span);

		// PHASE 2 (set complete): Trash through Prototype, biased low.
		// Two rolls, lower kept -- a triangular curve that makes
		// Prototype genuinely rare without a lookup table to keep in
		// step with the tier enum.
		int a = random[RSDropTier](0, span);
		int b = random[RSDropTier](0, span);
		return bot + min(a, b);
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

		// ORPHANED-CARD GUARD, added 2026-08-07.
		//
		// A card is normally torn down by the take path, by walking out
		// of radius, or by the pedestal's own Tick calling DropCard().
		// All three require the pedestal to still exist. If the
		// RS_WeaponDrop or its payload is destroyed ANY OTHER WAY --
		// console `remove`, a map script, a crusher -- that Tick stops,
		// mCardOwner goes null, and nothing ever tells the card.
		//
		// The panels then stay registered in RS_PanelHandler.mLive,
		// solved every tic and repainted every frame, for the rest of
		// the map. In comfort mode they hold station in front of the
		// reader, so the player is left staring through a stat sheet for
		// a weapon that no longer exists, with no way to dismiss it.
		//
		// One check, every tic, on the only condition that can produce
		// it: a card with no owner, or an owner with no payload.
		if (mCard && (!mCardOwner || !mCardOwner.mPayload))
			DropCard();

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

		// =============================================================
		// HOLD USE TO TAKE. Built 2026-08-07.
		//
		// The card's own wing text has always said "hold USE to take"
		// and NOTHING implemented it -- grep found no WorldThingActivated,
		// no BT_USE read, anywhere in the tree, and the pedestal is
		// +NOINTERACTION so it cannot be used in the ordinary way either.
		// The only working takes were point-and-trigger, MOUSE3 and the
		// punch. On a flat-play setup with no tracked controllers, that
		// left the most obvious instruction in the UI reading as broken.
		//
		// This is the fallback the owner asked for, on a toggle.
		//
		// READ FROM original_cmd, not cmd. RS_PanelInput edits `cmd` to
		// steal the trigger, which poisons the ordinary
		// buttons/oldbuttons edge test -- the raw pair is the only
		// honest source. Same reason that file uses it.
		//
		// HOLD, not tap: a tap of USE is how you open doors, and a drop
		// sitting in a doorway must not eat that.
		if (live && RS_PanelController.UseTakeEnabled() && pawn && pawn.player)
		{
			bool useDown = (pawn.player.original_cmd.buttons & BT_USE) != 0;
			if (useDown)
			{
				mUseHeld++;
				if (mUseHeld == RS_PanelController.UseHoldTics())
				{
					// == not >=, so one hold fires exactly once and does
					// not repeat while the button stays down.
					RS_PanelInput.Say(pawn, "menu/choose");
					EventHandler.SendNetworkEvent("rs-panel-use", 0);
				}
			}
			else mUseHeld = 0;
		}
		else mUseHeld = 0;

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

// =====================================================================
// RS_FoodBonus -- the elite's food scatter.
// ---------------------------------------------------------------------
// A HealthBonus wearing the FRUT sprite set (8 frames, sprites/rs_food/,
// imported 2026-08-07 from the champions pack at the owner's direction).
//
// Each one picks a random frame and a random horizontal flip at spawn,
// so a pile of twenty reads as an assortment of different food rather
// than twenty copies of one icon. That trick is the whole reason this
// is a separate class instead of a retextured HealthBonus.
//
// -COUNTITEM is deliberate and inherited from the source: dozens of
// these per elite would wreck the level's item percentage, and they are
// a combat payout, not a secret to be found.
// =====================================================================
class RS_FoodBonus : HealthBonus
{
	Default
	{
		+RANDOMIZE
		-COUNTITEM
		Inventory.PickupMessage "$PICKUP_RS_FOOD";
		Tag "$TAG_RS_FOOD";
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		bSpriteFlip = random(0, 1);
		frame = random(0, 7);
	}

	States
	{
	Spawn:
		// '#' holds whatever frame PostBeginPlay picked -- the state does
		// not advance it, which is what keeps each item on its own food.
		FRUT "#" 35;
		FRUT "#" 1 Bright;
		Loop;
	}
}
