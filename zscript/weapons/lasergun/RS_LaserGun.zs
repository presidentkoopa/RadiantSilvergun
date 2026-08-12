// RS_LaserGun -- the Lance. A REAL beam.
// zscript/weapons/lasergun/ -- its own folder, because a beam weapon shares
// almost nothing with the projectile sets besides the model it borrows.
// ---------------------------------------------------------------------
// Wears the Bolter model (bound by class name in MODELDEF, exactly as
// RS_PS_Plasma's header says it can be) and does the opposite thing with it:
// where the Bolter throws two bolts per cycle, this holds ONE CONTINUOUS
// SEGMENT from muzzle to whatever it hits, re-traced every tic.
//
// WHAT MAKES IT A BEAM AND NOT A FAST HITSCAN. The engine fork draws it by
// lighting every pixel by its distance from the segment -- Level.SetBeam, see
// FORK_CHANGES.md section 13. So it is not a sprite and not a chain of puffs:
// it is continuous at any length, it wraps floor/wall/ceiling as one unbroken
// object, and the surfaces near it brighten because they ARE near it. Nothing
// extra is spawned to fake that.
//
// AND THAT IS THE WEAPON'S REAL COST. In a dark map you can see twenty metres;
// the moment you fire, a line of white light hangs in the air lighting the
// corridor and you standing in it. This is the one gun in the set where
// pulling the trigger is a tactical disclosure. The damage is balanced knowing
// that -- it is strong, and it tells the room exactly where you are.
//
// FOUR BEATS, and they are readable without a HUD element because they are
// visible IN THE BEAM:
//
//   spin-up   0.0-0.4s  thin, dim, cold blue-white. Low damage. A commitment
//                       cost, and what stops this being strictly better than
//                       the bolt version.
//   lock      0.4-2.0s  wide, hard white. The working state.
//   heat      2.0-4.0s  white -> amber -> orange, core fattening, sound
//                       pitching up. You can see and hear the limit coming.
//   overheat  4.0s+     beam cuts, weapon locks ~1.5s. After four seconds of
//                       white glare you are standing in a black room, which
//                       is a worse punishment than any number going down.
//
// TWO HANDS, TWO BEAMS. Variants I-III are mainhand and IV-VI are offhand,
// the same split RS_PS_Plasma uses. Each hand owns its own beam slot, so
// firing one never disturbs the other -- which is why this releases its own
// slot on stopping rather than calling ClearBeams().
//
// ENGINE DEPENDENCY, stated plainly: Level.SetBeam/SetBeamCount are natives of
// this fork. On stock GZDoom this file does not compile. That is true of the
// billboard and sweep work as well and is the deal with the fork.
// =====================================================================

class RS_LaserGun : RS_Weapon
{
	// Tics the trigger has been held, and the heat that builds from it. Heat
	// is separate because it BLEEDS -- release early and it falls at about
	// half the rate it rose, so tapping is a real technique.
	int beamHeld;
	int beamHeat;
	bool beamLocked;      // overheated: refuses to fire until cool
	bool beamFiring;      // was the beam live last tic, for edge detection

	const BEAM_SPINUP   = 14;    // 0.4s
	const BEAM_LOCK     = 70;    // 2.0s -- heat starts climbing
	const BEAM_OVERHEAT = 140;   // 4.0s
	const BEAM_RANGE    = 2200.0;

	Default
	{
		Tag "Lance";
		Weapon.SelectionOrder 1080;
		Weapon.SlotNumber 6;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Cell";
		Inventory.Icon "PLASA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Energy; }

	override string GetBaseKeywords()
	{
		return "archetype:energy trigger:beam delivery:sustained payload:single feed:pool reserve:cell element:kinetic promotion:pellet set:meatgrinder";
	}

	// HITSCAN, NOT HEAVY, and it is fired for real.
	//
	// The first version authored a heavy (projectile) profile and then never
	// fired it, tracing and damaging by hand instead. That was wrong twice
	// over. A beam is not a projectile, so the profile described something the
	// gun does not do -- and an authored-but-unfired slot still makes
	// HasBeatMode() answer true, so every affix gating on it passed its
	// suitability check and then did nothing. Cards offered, taken, shown as
	// held, silently inert.
	//
	// It fires through A_RS_FireSlot now like every other weapon in the set,
	// which is what GunBonsai's tracking, the shot-keyword resolver, the affix
	// axes and the spend path all hang off. The beam gets its far end from a
	// SEPARATE trace that does no damage -- see A_LaserBeam. Geometry and
	// damage are two questions and only one of them needed answering by hand.
	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHitscan(
			fireSnd: "",              // the loop below is the weapon's voice
			spreadScale: 0.0,         // a beam does not scatter
			ammoCost: 1,
			ammo: "Cell",
			bigMuzzle: false,
			profName: "Lance"));
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(2, 3);
				Accuracy = RS_Roll.RollDouble(88, 95);
				Velocity = RS_Roll.RollDouble(90, 100);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(2, 4);
				Accuracy = RS_Roll.RollDouble(90, 96);
				Velocity = RS_Roll.RollDouble(92, 100);
				CritChance = RS_Roll.RollDouble(0.015, 0.025);
				Capacity = 0;
				break;
			default:
				DamagePerShot = RS_Roll.RollInt(3, 5);
				Accuracy = RS_Roll.RollDouble(92, 98);
				Velocity = RS_Roll.RollDouble(94, 100);
				CritChance = RS_Roll.RollDouble(0.020, 0.035);
				Capacity = 0;
				break;
		}
		if (!bStatsRolled) Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);
		bStatsRolled = true;
	}

	// Which beam slot this gun owns. Two hands, two slots, so one hand's beam
	// can never blink the other's out.
	int BeamSlot()
	{
		if (owner && owner.player && owner.player.OffhandWeapon == self) return 1;
		return 0;
	}

	// ---- the beam itself -------------------------------------------------
	//
	// Called once per tic while the trigger is down. Traces, draws, damages.
	action void A_LaserBeam()
	{
		let w = RS_LaserGun(invoker);
		if (!w || !self || !player) return;

		w.beamHeld++;

		// Heat only starts climbing once the beam is locked on -- the spin-up
		// is free, so tapping never overheats you.
		if (w.beamHeld > BEAM_LOCK) w.beamHeat += 2;

		if (w.beamHeld >= BEAM_OVERHEAT)
		{
			w.BeamOverheat(self);
			return;
		}

		// WHERE IT ENDS -- and this trace does NO damage.
		//
		// It exists only to answer "what is the beam's far end", which is a
		// geometry question A_RS_FireSlot cannot answer because it does not
		// hand a hit position back. The damage, the ammo, the affixes, the
		// shot keywords and GunBonsai's tracking all go through the slot
		// below, exactly as they do on every other weapon in the set.
		//
		// TRF_THRUACTORS on purpose: the beam should be drawn to the WALL
		// behind whatever it is burning through, not stop short at the first
		// monster. The slot's own attack decides what it actually hits.
		FLineTraceData d;
		LineTrace(angle, BEAM_RANGE, pitch, TRF_THRUACTORS,
			player.viewheight, data: d);

		Vector3 from = (pos.x, pos.y, pos.z + player.viewheight);
		Vector3 to = d.HitLocation;

		// SHAPE, AND IT IS ALL DRIVEN BY HOW LONG YOU HAVE HELD IT.
		//
		// The halo widening is what actually sells "hotter" -- more than the
		// colour does, which is why soft climbs faster than thick.
		double t = clamp(double(w.beamHeld) / double(BEAM_LOCK), 0.0, 1.0);
		double heat = clamp(double(w.beamHeld - BEAM_LOCK)
			/ double(BEAM_OVERHEAT - BEAM_LOCK), 0.0, 1.0);

		double thick = 1.5 + 2.5 * t + 4.0 * heat;
		double soft  = 2.0 + 3.0 * t + 4.0 * heat;
		double inten = 0.5 + 0.9 * t + 0.8 * heat;

		// Cold blue-white, to hard white, to amber, to orange. The colour is
		// the heat gauge; there is deliberately no meter for it.
		Color col;
		if (heat <= 0.0)
			col = RS_LaserGun.LerpCol(0xA0C8FF, 0xE8F4FF, t);
		else if (heat < 0.5)
			col = RS_LaserGun.LerpCol(0xE8F4FF, 0xFFD070, heat * 2.0);
		else
			col = RS_LaserGun.LerpCol(0xFFD070, 0xFF6020, (heat - 0.5) * 2.0);

		level.SetBeamCount(2, 0.45, 1.0);

		// HOW THE BEAM LOOKS, AND ALL OF IT RIDES THE HEAT.
		//
		// Air glow is what makes it a laser rather than a spotlight -- the
		// beam is visible hanging in the air, not just as a bright patch
		// where it lands. It is also what feeds bloom, so the core burning
		// past white blooms on its own with no light and no sprite.
		//
		// SCROLL SPEEDS UP AS IT HEATS. A held beam with nothing travelling
		// along it goes static within a second and the eye stops believing it
		// is carrying anything; tying the scroll to heat means the beam
		// visibly works harder the longer you hold it.
		//
		// TAPER SLACKENS as it heats -- a cold beam is tight at the aperture,
		// a hot one has lost its discipline and is nearly parallel-sided.
		level.SetBeamLook(
			1.0,                          // air glow: it is an object in space
			5.0 + 9.0 * heat,             // scroll speed
			0.18 + 0.22 * heat,           // scroll depth
			0.45 - 0.30 * heat,           // taper, slackening
			1.2 + 1.1 * heat);            // impact flare

		level.SetBeam(w.BeamSlot(), from, to, thick, soft, col, inten);

		// THE SOUND RISES WITH THE HEAT. Started once on the trigger edge and
		// pitched every tic after, so the overheat is audible before it is
		// visible -- which matters, because you are usually looking at what
		// you are shooting rather than at the beam.
		// CHAN_5, NOT CHAN_7. A_RS_FireSlot plays AffixExtraFireSound on
		// CHAN_7 -- the layered themed voice a Brand or Attune card installs.
		// A looping heat tone parked there would fight the first such card
		// that lands on this gun, and since the loop never stops on its own
		// the card would simply not be heard.
		if (!w.beamFiring)
		{
			A_StartSound("rs_vp_plasma_chrg", CHAN_WEAPON, 0, 0.7);
			A_StartSound("rs_vp_plasma_altfire", CHAN_5, CHANF_LOOPING, 0.8, ATTN_NORM);
			w.beamFiring = true;
		}
		A_SoundPitch(CHAN_5, 0.85 + 0.5 * heat);

		// AND NOW THE ACTUAL SHOT, THROUGH THE SLOT LIKE EVERY OTHER WEAPON.
		//
		// This is the whole reason the profile above is real and fired rather
		// than authored and ignored. A_RS_FireSlot is where the mod resolves
		// the affix axes, the granted shot keywords, the crit and spread
		// mods, the ammo spend, RS_LastShotTic -- and GunBonsai's per-weapon
		// tracking. Tracing and damaging by hand skips all of it, and the
		// symptom is the worst kind: cards that are offered, taken, displayed
		// as held, and silently do nothing.
		//
		// Not every tic. A hitscan profile is one SHOT, and firing one per
		// tic would spend a cell every tic and hand GunBonsai thirty-five
		// hits a second. Every third tic is roughly ten a second, which reads
		// as continuous, spends at a sane rate, and gives the tracking a
		// believable cadence for a sustained weapon.
		// AND NOTHING AT ALL DURING SPIN-UP. The first four tenths of a second
		// are a targeting laser: visible, aimable, and harmless. That is the
		// commitment cost, and it is what stops the beam being strictly
		// better than the bolt version -- you pay for the lock before you get
		// the damage, so a flinch tap costs a cell and achieves nothing.
		if (w.beamHeld > BEAM_SPINUP && (w.beamHeld % 3) == 1) A_RS_FireSlot(0);
	}

	// Trigger released, or the state machine left Fire. Put the beam away.
	//
	// Releases only THIS hand's slot rather than calling ClearBeams, or firing
	// the mainhand would blink the offhand's beam out every tic.
	action void A_LaserStop()
	{
		let w = RS_LaserGun(invoker);
		if (!w) return;
		w.BeamRelease(self);
	}

	void BeamRelease(Actor who)
	{
		if (beamFiring)
		{
			if (who) who.A_StopSound(CHAN_7);
			beamFiring = false;
		}
		level.SetBeam(BeamSlot(), (0, 0, 0), (0, 0, 0), 0.01, 0.01, 0, 0.0);
		beamHeld = 0;
	}

	void BeamOverheat(Actor who)
	{
		BeamRelease(who);
		beamLocked = true;
		beamHeat = BEAM_OVERHEAT;
		if (who) who.A_StartSound("rs_vp_plasma_cout", CHAN_WEAPON, 0, 1.0);
	}

	// Heat bleeds whenever the trigger is not down, at about half the rate it
	// built. The lock clears only once it is fully cold, so an overheat costs
	// the whole climb back rather than a fixed pause.
	override void DoEffect()
	{
		Super.DoEffect();
		if (!beamFiring && beamHeat > 0)
		{
			beamHeat--;
			if (beamHeat <= 0) { beamHeat = 0; beamLocked = false; }
		}
	}

	static Color LerpCol(int a, int b, double t)
	{
		t = clamp(t, 0.0, 1.0);
		int ar = (a >> 16) & 255, ag = (a >> 8) & 255, ab = a & 255;
		int br = (b >> 16) & 255, bg = (b >> 8) & 255, bb = b & 255;
		return Color(255,
			int(ar + (br - ar) * t),
			int(ag + (bg - ag) * t),
			int(ab + (bb - ab) * t));
	}

	States
	{
	Spawn:
		PLAS A -1;
		Stop;

	Ready:
		PLSC A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		TNT1 A 0 A_LaserStop();
		PLSC A 1 A_Lower;
		Loop;

	Select:
		PLSC A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(invoker.beamLocked, "Overheated");
		TNT1 A 0 A_JumpIf(CountInv("Cell") > 0, "Beam");
		Goto OutOfAmmo;

	// ONE TIC PER LOOP. The beam is re-traced and re-drawn every tic, which
	// is what makes it track as you turn rather than lagging behind the
	// crosshair like a spawned object would.
	Beam:
		PLSF A 1 Bright A_LaserBeam();
		TNT1 A 0 A_ReFire("Beam");
		TNT1 A 0 A_LaserStop();
		Goto Ready;

	Overheated:
		TNT1 A 0 A_LaserStop();
		PLSC C 52;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		PLSF A 1 Bright A_Light1();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_LaserStop();
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

// Six, the same split the Bolter uses: I-III mainhand, IV-VI offhand, so a
// pair can be held one per hand.
class RS_LaserGun2 : RS_LaserGun
{ Default { Tag "Lance II"; Weapon.SelectionOrder 1079; } }

class RS_LaserGun3 : RS_LaserGun
{ Default { Tag "Lance III"; Weapon.SelectionOrder 1078; } }

class RS_LaserGun4 : RS_LaserGun
{ Default { Tag "Lance IV"; Weapon.SelectionOrder 1077; +WEAPON.OFFHANDWEAPON; } }

class RS_LaserGun5 : RS_LaserGun
{ Default { Tag "Lance V"; Weapon.SelectionOrder 1076; +WEAPON.OFFHANDWEAPON; } }

class RS_LaserGun6 : RS_LaserGun
{ Default { Tag "Lance VI"; Weapon.SelectionOrder 1075; +WEAPON.OFFHANDWEAPON; } }
