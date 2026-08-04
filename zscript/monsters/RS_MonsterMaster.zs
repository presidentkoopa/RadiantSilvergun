// =====================================================================
// RS_MonsterMaster -- the monster-side parallel of RS_Weapon.
// ---------------------------------------------------------------------
// Owns three things and nothing else:
//
//   TIER     numeric 00..12 (+ EX via TierLocked). Runtime-safe,
//            idempotent, re-callable mid-fight.
//   BODY     which sprite (and which TRNSLATE colour) this monster
//            wears at this tier, as DATA -- two space-delimited
//            strings in ladder order.
//   ATTACKS  an RS_AttackSlot per tier (RS_AttackProfile.zs, same
//            structure the guns use).
//
// Content-free. No monster behaviour lives here.
//
// WHY THE BODY STRING: the previous port wrote Spawn/See/Pain/Death out
// once per tier -- thirteen near-identical blocks whose only difference
// was a four-letter sprite name. Measured across all 19 family files
// that was about three quarters of every file. Here the base owns one
// set of states and the family supplies thirteen sprite names on one
// line. A family that genuinely needs a bespoke tier still overrides
// the state outright; the table is the default, not a cage.
//
// The sprite and colour are applied on TIER CHANGE, not on state entry.
// A monster's body doesn't change because it took a step.
//
// Also owns the shared per-family base classes (RS_HumanMonster,
// RS_DemonBase, RS_KnightBase) -- they're template machinery, same as
// everything else in this file, even though each is only used by one
// group of concrete monster files.
// =====================================================================

class RS_MonsterTierRow
{
	// ABSOLUTE, HAND-ASSIGNED STATS -- the preferred way to state a tier.
	//
	// A tier is not a point on a curve. Colourful Hell and CHP hand-tuned
	// every colour's health and speed individually, and every tier we add
	// from here (TEX and whatever packs follow) is authored the same way:
	// somebody decides this creature has 5000 HP because that is what it
	// should have, not because 5000 is what the formula produced.
	//
	// Set hp/speed > 0 and they are used verbatim. Leave them 0 and the
	// multipliers below apply instead, recomputed from the actor's
	// Defaults. Writing the real number is clearer and cannot drift, so
	// prefer it -- the multiplier path exists for the generic base ladder
	// and for anything that genuinely wants to scale off a default.
	int    hp;
	int    speed;

	double hpMul;
	double spdMul;
	int    painChance;

	// Stored, NOT auto-applied. hp/speed/painChance are plain Actor
	// properties we can safely rescale here. Outgoing damage is not --
	// scaling it would mean reaching into every vanilla attack action on
	// every monster. It is data the monster's own attack code reads and
	// applies. Do not read this as "damage scaling is wired." It isn't.
	double dmgMul;
}

class RS_MonsterMaster : Actor abstract
{
	// --- Tier ---
	int    Tier;
	double TierDamageMul;   // see RS_MonsterTierRow.dmgMul -- data only

	// The health ceiling for our CURRENT tier. Tracked ourselves rather
	// than read back from the engine: we rescale health per tier, so the
	// actor's spawn health is the T00 default and would give the wrong
	// answer everywhere a fraction or a threshold is computed. Set in
	// ApplyTier, read by the retier fraction, CheckThreshold, and the
	// support-aura heal.
	int TierMaxHealth;

	// Cached Defaults, captured once. ALL scaling recomputes from these,
	// never from current values, so tier-up-then-down cannot drift or
	// compound however many times the dial moves.
	private int    rsBaseHealth;
	private double rsBaseSpeed;
	private int    rsBasePainChance;
	private bool   rsBaseCaptured;

	// --- Body / tint ---
	// BodyTable() is now DOCUMENTATION + AUDIT data only: the actual
	// bodies are real per-tier state clusters (See.T03, Missile.T03...)
	// with literal sprites, dispatched by TierState(). The sprite field
	// is never assigned at runtime -- that was the skin-system bug that
	// made monsters flash zombieman frames. TintTable() is still LIVE
	// data: translations apply on tier change in RS_ApplyTint().
	private Array<string> rsBodies;   // parsed BodyTable(), cached
	private Array<string> rsTints;    // parsed TintTable(), cached
	private bool rsTablesParsed;

	// Deferred state jump, applied in Tick where SetState is legal.
	// Set by ApplyTier after a tier change ("See.T05" if fighting,
	// "Spawn.T05" if idle); consumed exactly once. Jumping states from
	// a handler/inventory context silently fails -- this is the
	// HF-proven safe route.
	private string pendingStateJump;

	// --- Staggered transform ---
	private bool   rsTransforming;
	private int    rsPendingTier;
	private int    rsPendingTic;
	private int    rsTransformStart;   // when the tell began (for the accelerating flash)
	private int    rsXfOldTier;        // body we're transforming FROM (display only)
	private int    rsFlashPhase;       // beat counter: even=gold, odd=a real body
	private int    rsNextBeat;         // next flicker beat, shrinks as the snap nears

	// --- Attacks ---
	RS_AttackSlot CurrentAttacks;
	private int   rsAttacksBuiltFor;

	// --- Behaviour primitives (see the PRIMITIVES section below) ---
	// One-shot threshold guards, as a bitmask rather than an array of
	// bools: 32 independent slots, and no array-in-class-body risk.
	private int rsThresholdFlags;

	// Timed stat pulse.
	private bool   rsPulseActive;
	private int    rsPulseEndTic;
	private double rsPulseBaseSpeed;
	private double rsPulseBaseDamageMul;
	private bool   rsPulseSetNoPain;

	// Phase dodge / blink.
	private bool   rsDodgeActive;
	private int    rsDodgeEndTic;
	private double rsDodgeBaseSpeed;
	private double rsDodgeBaseAlpha;
	private int    rsDodgeBaseStyle;
	private bool   rsDodgeSetNoPain;

	// Generic escalation counter. CHP builds half its boss behaviour on
	// one of these (Archvile's charge portal, courage meters, live-pack
	// limits, combo stacks). One int plus helpers covers all of them.
	int ChargeCounter;

	Default
	{
		Monster;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();

		if (!rsBaseCaptured)
		{
			let def = GetDefaultByType(GetClass());
			rsBaseHealth     = def.Health;
			rsBaseSpeed      = def.Speed;
			rsBasePainChance = def.PainChance;
			rsBaseCaptured   = true;
		}

		rsAttacksBuiltFor = -1;
		ApplyTier(true);
	}

	// =================================================================
	// TIER
	// =================================================================

	// The ladder. T00..T12 are Colourful Hell's real hand-tuned numbers.
	//
	// THIS CURVE IS NOT MONOTONIC AND THAT IS DELIBERATE. T03 has less HP
	// than T02 but far more speed. T09 is the slowest tier in the table
	// yet nearly the toughest of the middle band. Each row was a distinct
	// designed creature, not a point on a ramp. Do not "fix" this into a
	// smooth curve -- the irregularity IS the ladder's character.
	//
	// Switch, not a static const array: this engine build does not
	// resolve `static const TYPE name[] = {...}` in a class body
	// reliably (three real bugs so far).
	virtual bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 200; r.dmgMul = 1.0;

		switch (t)
		{
			case 0:  r.hpMul= 1.0; r.spdMul=1.0; r.painChance=200; r.dmgMul=1.0; break;
			case 1:  r.hpMul= 1.6; r.spdMul=1.1; r.painChance=180; r.dmgMul=1.2; break;
			case 2:  r.hpMul= 2.0; r.spdMul=1.2; r.painChance=160; r.dmgMul=1.3; break;
			case 3:  r.hpMul= 1.8; r.spdMul=1.6; r.painChance=120; r.dmgMul=1.3; break;
			case 4:  r.hpMul= 3.5; r.spdMul=1.4; r.painChance=100; r.dmgMul=1.6; break;
			case 5:  r.hpMul= 3.0; r.spdMul=1.7; r.painChance= 90; r.dmgMul=1.8; break;
			case 6:  r.hpMul= 4.0; r.spdMul=1.3; r.painChance=100; r.dmgMul=1.5; break;
			case 7:  r.hpMul= 2.5; r.spdMul=1.5; r.painChance=110; r.dmgMul=1.7; break;
			case 8:  r.hpMul= 3.0; r.spdMul=1.1; r.painChance=140; r.dmgMul=1.4; break;
			case 9:  r.hpMul= 3.8; r.spdMul=1.0; r.painChance= 90; r.dmgMul=1.5; break;
			case 10: r.hpMul= 5.0; r.spdMul=1.5; r.painChance= 70; r.dmgMul=2.0; break;
			case 11: r.hpMul=12.0; r.spdMul=1.6; r.painChance= 40; r.dmgMul=2.5; break;
			case 12: r.hpMul=20.0; r.spdMul=1.8; r.painChance= 24; r.dmgMul=3.0; break;
			default: return false;
		}
		return true;
	}

	// EX / SetPiece monsters ignore the ambient dial and keep their
	// hand-authored Default stats. Override to true.
	virtual bool TierLocked()
	{
		return false;
	}

	// Public entry. Safe to call repeatedly, safe mid-swing.
	//
	// STAGGERED TRANSFORM. A retier is NOT applied on the spot unless
	// asked for. Each monster picks a short random delay first, for two
	// reasons that both matter:
	//   (a) retiering a room full of monsters spreads the recompute over
	//       many tics instead of spiking one frame. This is a load
	//       balancer, not decoration.
	//   (b) it reads as an event. A monster that flashes for a moment
	//       and THEN changes looks deliberate; one that snaps looks
	//       like a bug.
	//
	// The tell is a plain additive RenderStyle flash -- a built-in
	// engine feature, no lump or external data required. Deliberately
	// NOT a named palette flash: the previous template flashed via
	// A_SetTranslation with names defined in no TRNSLATE lump anywhere,
	// which silently no-opped.
	void SetTier(int t, bool instant = false)
	{
		if (TierLocked())
			return;

		int want = clamp(t, 0, MaxTier());
		if (want == Tier && rsAttacksBuiltFor == Tier)
			return;

		if (instant || !RS_MonOpt("rs_mon_transform_tell", true))
		{
			int old = Tier;
			Tier = want;
			ApplyTier(instant);
			if (old != Tier)
				OnRetier(old, Tier);
			return;
		}

		// Re-targetable: a second call mid-stagger just changes the
		// destination, it doesn't queue a second transform.
		rsPendingTier = want;
		if (!rsTransforming)
		{
			rsTransforming   = true;
			rsXfOldTier      = Tier;
			rsTransformStart = level.time;
			// Random length, never longer than 3 seconds (105 tics).
			rsPendingTic     = level.time + random(45, 105);
			rsFlashPhase     = -1;
			rsNextBeat       = level.time;
		}
	}

	// Show a specific tier's BODY without committing to that tier --
	// display only, no stat recompute. Used by the transform tell to
	// flick between the old and new creature mid-telegraph.
	private void RS_ShowBody(int t)
	{
		State st = FindStateByString("See." .. TierLabel(t), true);
		if (!st) st = FindStateByString("Spawn." .. TierLabel(t), true);
		if (!st) st = FindStateByString("See.T00", true);
		if (st) SetState(st);
	}

	// Runs the staggered transform. Called from Tick.
	//
	// THE TELL, owner-specified: the monster alternates between the body
	// it IS and the body it is BECOMING, with a gold flash on every
	// beat between --
	//
	//     old -> GOLD -> new -> GOLD -> old -> GOLD -> new -> ...
	//
	// slow at first and accelerating into the snap. Total length is
	// random per monster and never exceeds 3 seconds (105 tics), so a
	// retiered room ripples instead of snapping, and each monster reads
	// as a 90s beat-em-up boss winding up.
	//
	// Beat length shrinks from ~10 tics to 1 as the deadline nears; the
	// acceleration IS the signal that something is about to change.
	private void RS_TickTransform()
	{
		if (!rsTransforming)
			return;

		if (level.time < rsPendingTic)
		{
			if (level.time < rsNextBeat)
				return;

			int remain = rsPendingTic - level.time;
			// 10 tics per beat at the start, tightening to 1 at the end.
			int beat = clamp(remain / 8, 1, 10);
			rsNextBeat = level.time + beat;

			rsFlashPhase++;
			// Even phases are gold; odd phases show a real body,
			// alternating old / new / old / new.
			if ((rsFlashPhase & 1) == 0)
			{
				A_SetTranslation("rs_gold_flash");
			}
			else
			{
				A_SetTranslation("");
				RS_ShowBody(((rsFlashPhase >> 1) & 1) == 0 ? rsXfOldTier : rsPendingTier);
			}
			return;
		}

		int old = Tier;
		Tier = rsPendingTier;
		rsTransforming = false;
		rsFlashPhase   = -1;
		ApplyTier(false);   // commits stats, tint, attacks and the real body

		if (old != Tier)
			OnRetier(old, Tier);
	}

	void ApplyTier(bool instant)
	{
		RS_MonsterTierRow r = new("RS_MonsterTierRow");
		if (!TierData(Tier, r))
			return;

		// Fraction-preserving: a monster retiered mid-fight keeps how
		// hurt it was rather than being silently full-healed or left on
		// a sliver. Toggleable -- some players want the raw dial.
		// Fraction is measured against the max we had BEFORE this
		// recompute -- TierMaxHealth is still the old ceiling here. On
		// the very first call it's 0, so a fresh monster spawns full.
		double frac = 1.0;
		if (RS_MonOpt("rs_mon_retier_preserve_fraction", true)
		    && !instant && health > 0 && TierMaxHealth > 0)
		{
			frac = clamp(double(health) / double(TierMaxHealth), 0.0, 1.0);
		}

		// Absolute hand-assigned health wins; the multiplier is the
		// fallback for rows that did not state one.
		int newMax = (r.hp > 0) ? r.hp : max(1, int(rsBaseHealth * r.hpMul));
		newMax = max(1, newMax);
		TierMaxHealth = newMax;
		// Direct assignment rather than A_SetHealth: that's an action
		// function, and calling one from a plain method (or on another
		// actor, as the heal path does) is a ZScript wrinkle not worth
		// gambling on. Equivalent here.
		health = max(1, int(newMax * frac));
		Speed         = (r.speed > 0) ? double(r.speed) : rsBaseSpeed * r.spdMul;
		PainChance    = r.painChance;
		TierDamageMul = r.dmgMul;

		RS_ApplyTint();
		BuildAttacksForTier(Tier);
		OnTierApplied(Tier);

		// Route the state machine into the new tier's body. Deferred to
		// Tick (SetState from a non-actor context silently fails). If
		// we're mid-fight, enter the new See; if idle, the new Spawn --
		// otherwise a retiered idle monster keeps showing the old body
		// until something wakes it.
		pendingStateJump = (target ? "See." : "Spawn.") .. TierLabel(Tier);
	}

	virtual void OnTierApplied(int t) {}
	virtual void OnRetier(int oldTier, int newTier) {}

	// =================================================================
	// BODY -- thirteen sprite names on one line, in ladder order.
	// "" anywhere in the table (or an empty table) means "leave the
	// authored sprite alone at that tier".
	// =================================================================

	virtual string BodyTable()
	{
		return "";
	}

	// Thirteen TRNSLATE names in ladder order, "-" for "no translation
	// at this tier". A tier with "-" is NOT unfinished -- it means that
	// tier wears a bespoke sprite that is already the right colour, or
	// uses a RenderStyle instead of a palette remap. Colourful Hell does
	// both, so we have to as well.
	virtual string TintTable()
	{
		return "";
	}

	private void RS_ParseTables()
	{
		if (rsTablesParsed)
			return;

		string b = BodyTable();
		if (b.Length() > 0) b.Split(rsBodies, " ");

		string t = TintTable();
		if (t.Length() > 0) t.Split(rsTints, " ");

		rsTablesParsed = true;
	}

	// Read-only views of the parsed tables, for diagnostics. Return "" when
	// the tier falls off the end of a short table -- which is itself the
	// answer to "why doesn't this tier change appearance".
	string RS_DbgBodyToken(int t)
	{
		RS_ParseTables();
		return (t >= 0 && t < rsBodies.Size()) ? rsBodies[t] : "";
	}

	string RS_DbgTintToken(int t)
	{
		RS_ParseTables();
		return (t >= 0 && t < rsTints.Size()) ? rsTints[t] : "";
	}

	// Tint only, on tier change only. The sprite half of the old
	// "wear body" system is GONE -- bodies are real per-tier state
	// clusters now (see TierState below), never runtime assignment.
	void RS_ApplyTint()
	{
		RS_ParseTables();

		if (Tier >= 0 && Tier < rsTints.Size())
		{
			string tn = rsTints[Tier];
			// "-" is the explicit "this tier has no translation" marker.
			// Setting "" here is a harmless no-op that also CLEARS a
			// translation left over from a previous tier, which is what
			// we want when tiering down into an untranslated body.
			A_SetTranslation(tn == "-" ? "" : tn);
		}
	}

	// =================================================================
	// TIER STATE DISPATCH -- the rebuilt body system.
	// A tier's body is a real state cluster: See.T03, Missile.T03...
	// with literal sprite tokens, exactly the architecture Colourful
	// Hell and the proven HF port use. These helpers route into it.
	// =================================================================

	// THE LADDER IS OPEN-ENDED. T00..T12 are Colourful Hell's thirteen
	// colours and TEX (13) is CHP's EX variant, but nothing here caps at
	// thirteen: a higher tier is simply ANOTHER KIND OF MONSTER. Import a
	// new monster pack and it becomes T14, T15, ... with no base-class
	// change -- author the cluster, add the TierData row, raise the
	// family's MaxTier(). The main game mode runs T00 -> TEX; the rest of
	// the ladder is headroom that costs nothing until it is used.
	//
	// Labels are generated, not enumerated, so a new tier can never be
	// "missing" from a switch someone forgot to extend.
	static string TierLabel(int t)
	{
		if (t <= 0)  return "T00";
		if (t == RS_TIER_EX) return "TEX";
		return String.Format("T%02d", t);
	}

	// TEX sits directly above T12. Named so nothing has to hardcode 13.
	const RS_TIER_EX = 13;

	// Highest tier THIS family actually authors clusters for. The base
	// ships the CH ladder plus TEX; a family that imports further packs
	// overrides this and the dial reaches them automatically. SetTier
	// clamps to it, and ApplyTier still bails if TierData has no row --
	// two independent guards, so an unauthored tier can never half-apply.
	virtual int MaxTier()
	{
		return RS_TIER_EX;
	}

	// Resolve "prefix.<current tier>", falling back to "prefix.T00" for
	// tiers that share the base body, then to null (caller's fallback
	// line handles it). Families stack labels for shared bodies; the
	// fallback is a safety net, not the design.
	State TierState(string prefix)
	{
		State st = FindStateByString(prefix .. "." .. TierLabel(Tier), true);
		if (st) return st;
		return FindStateByString(prefix .. ".T00", true);
	}

	// AUDIT support (RS_MonsterDebug). Reports tier clusters this class
	// is missing where the BodyTable says the tier wears a body DIFFERENT
	// from T00's -- those are the tiers where the T00 fallback would show
	// the wrong creature. Same-body tiers legitimately share clusters and
	// are not flagged. Missile and Melee count as one slot (melee-only
	// bodies are legal).
	string RS_AuditClusters()
	{
		string missing = "";
		string base = RS_DbgBodyToken(0);
		for (int t = 1; t <= 12; t++)
		{
			if (RS_DbgBodyToken(t) == base)
				continue;
			string lbl = TierLabel(t);
			if (!FindStateByString("See." .. lbl, true))
				missing = missing .. "See." .. lbl .. " ";
			if (!FindStateByString("Spawn." .. lbl, true))
				missing = missing .. "Spawn." .. lbl .. " ";
			if (!FindStateByString("Pain." .. lbl, true))
				missing = missing .. "Pain." .. lbl .. " ";
			if (!FindStateByString("Death." .. lbl, true))
				missing = missing .. "Death." .. lbl .. " ";
			if (!FindStateByString("Missile." .. lbl, true)
			    && !FindStateByString("Melee." .. lbl, true))
				missing = missing .. "Attack." .. lbl .. " ";
		}
		return missing;
	}

	// =================================================================
	// ATTACKS -- the same RS_AttackSlot the guns use.
	// =================================================================

	// Null = this tier has no data-driven attack and the family is
	// handling it in states.
	virtual RS_AttackSlot BuildTierAttacks(int t)
	{
		return null;
	}

	void BuildAttacksForTier(int t)
	{
		if (rsAttacksBuiltFor == t)
			return;
		CurrentAttacks = BuildTierAttacks(t);
		rsAttacksBuiltFor = t;
	}

	// Convenience for families doing hitscan attacks off the tier data,
	// so thirteen tiers don't need thirteen hand-tuned magic numbers.
	void RS_TierBullets(int shots, double spread, int dmgLo, int dmgHi, string puff = "BulletPuff")
	{
		A_FaceTarget();
		int dmg = int(random(dmgLo, dmgHi) * TierDamageMul);
		A_CustomBulletAttack(spread, 0, shots, dmg, puff);
	}

	// -----------------------------------------------------------------
	// THE DISPATCH -- the single place every monster attack mode meets,
	// the same role A_RS_FireSlot plays on the weapon side.
	//
	// A monster's Missile state calls this and the DATA decides what
	// happens: a fireball, a 36-shot ring, a summon, an aura, a self
	// buff. Adding an attack to a tier is editing a table, not writing
	// a state.
	//
	// Advances the slot cursor, so a rotation like [shot, shot, summon]
	// naturally makes every third attack the summon.
	// -----------------------------------------------------------------
	void A_RS_MonsterFire()
	{
		if (!CurrentAttacks || CurrentAttacks.IsEmpty())
			return;

		let p = PickProfile();
		if (!p)
			return;

		FireProfile(p);
	}

	// Advance the rotation, skipping any profile whose range band does
	// not contain the current distance to target. That is what turns a
	// rotation into close/mid/long attacks with no hand-written state
	// branching.
	//
	// Walks at most one full lap: if nothing in the slot fits the current
	// distance we fire the next entry anyway rather than standing there
	// doing nothing, which reads as a broken monster.
	RS_AttackProfile PickProfile()
	{
		if (!CurrentAttacks || CurrentAttacks.IsEmpty())
			return null;

		double dist = target ? Distance3D(target) : 0;
		int n = CurrentAttacks.Count();

		for (int i = 0; i < n; i++)
		{
			let p = CurrentAttacks.Advance();
			if (!p) continue;
			if (!p.HasRangeBand() || p.InRange(dist))
				return p;
		}

		return CurrentAttacks.Advance();
	}

	// Fire one profile directly, without touching the rotation cursor.
	// Used by monsters that pick an attack by condition (range band,
	// health gate) rather than by rotation.
	void FireProfile(RS_AttackProfile p)
	{
		if (!p)
			return;

		if (p.FireSound)
			A_StartSound(p.FireSound, CHAN_WEAPON);

		switch (p.Mode)
		{
			case RS_ATK_SUMMON:
			{
				if (p.SummonClass)
					SummonPack(p.SummonClass, p.SummonCount,
					           p.SummonCap, p.SummonTierOffset);
				break;
			}

			case RS_ATK_RADIAL:
			{
				if (p.RadialHeal > 0)
				{
					// Support aura -- heal/buff nearby monsters. Uses the
					// same idiom CHP does, just typed.
					ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
					RS_MonsterMaster mo;
					while (mo = RS_MonsterMaster(it.Next()))
					{
						if (mo == self || mo.health <= 0) continue;
						if (Distance3D(mo) > p.RadialRadius) continue;
						int cap = mo.TierMaxHealth > 0 ? mo.TierMaxHealth : mo.SpawnHealth();
						mo.health = min(cap, mo.health + p.RadialHeal);
					}
				}
				if (p.RadialDamage > 0)
				{
					// Plain A_Explode. Note this DOES splash other
					// monsters -- that's engine behaviour and it's what
					// CHP relied on (it starts infighting, which is
					// usually a feature in a crowd). RadialHitsAllies is
					// honoured on the heal path above, where we control
					// the iteration ourselves; it is NOT wired to the
					// damage path, because A_Explode has no
					// friendly-fire switch. Flagged rather than faked.
					int dmg = int(p.RadialDamage * TierDamageMul);
					A_Explode(dmg, int(p.RadialRadius), 0, false);
				}
				break;
			}

			case RS_ATK_SELFBUFF:
			{
				PulseStats(p.BuffSpeedMult, p.BuffDamageMult,
				           p.BuffDuration, p.BuffNoPain);
				break;
			}

			case RS_ATK_MELEE:
			{
				if (target && Distance3D(target) <= p.MeleeRange)
				{
					int dmg = int(random(8, 24) * p.DamageMult * TierDamageMul);
					int newdam = target.DamageMobj(self, self, dmg, "Melee");
					target.TraceBleed(newdam > 0 ? newdam : dmg, self);
				}
				break;
			}

			case RS_ATK_HITSCAN:
			{
				A_FaceTarget();
				int dmg = int(random(3, 15) * p.DamageMult * TierDamageMul);
				if (p.ImpactPuff)
					A_CustomBulletAttack(p.SpreadScale * 100.0, 0,
					                     max(1, p.VolleyCount), dmg, p.ImpactPuff);
				else
					A_CustomBulletAttack(p.SpreadScale * 100.0, 0,
					                     max(1, p.VolleyCount), dmg);
				break;
			}

			default:   // RS_ATK_HEAVY / RS_ATK_BULLET -- a projectile volley
			{
				FireVolley(p);
				break;
			}
		}
	}

	// The ring/fan burst. Colourful Hell's signature shape, as one
	// function instead of thirty hand-written A_CustomMissile lines.
	private void FireVolley(RS_AttackProfile p)
	{
		if (!p.ProjectileClass)
			return;

		A_FaceTarget();

		int n = max(1, p.VolleyCount);
		double arc = p.VolleyArc;

		// Size derived from what THIS monster is, unless the profile
		// forces it. A chaingunner throwing a Cacodemon ball is a
		// bullet-delivery skirmisher, so it throws a bullet-sized one.
		double projScale = (p.ProjScale > 0) ? p.ProjScale
			: RS_Catalog.ScaleForMonsterRole(GetKeywordValue("role"),
			                                 GetKeywordValue("delivery"));

		// A full ring divides evenly all the way round; a fan is
		// centred on where we're already facing.
		double step  = (n > 1) ? (arc / (arc >= 359.0 ? n : (n - 1))) : 0.0;
		double start = (arc >= 359.0) ? 0.0 : -arc * 0.5;

		for (int i = 0; i < n; i++)
		{
			double yaw = start + step * i;
			double pitchOff = (p.VolleyPitchJitter != 0)
			                ? frandom(-p.VolleyPitchJitter, p.VolleyPitchJitter)
			                : 0.0;

			// CMF_AIMDIRECTION so our computed yaw wins instead of the
			// engine re-aiming every shot at the target -- without it a
			// "ring" collapses into 36 shots all pointing the same way.
			let mo = A_SpawnProjectile(p.ProjectileClass, 32.0, 0, yaw,
			                           CMF_AIMDIRECTION | CMF_TRACKOWNER, pitchOff);
			// Size it to whoever fired it. No-ops at scale 1.0.
			RS_Catalog.ApplyProjectileScale(mo, projScale);
		}
	}

	// =================================================================
	// BEHAVIOUR PRIMITIVES
	// -----------------------------------------------------------------
	// Every one of these was found independently in five or more CHP
	// families during the behaviour survey -- summoning is in all 17,
	// per-actor state counters in 15, threshold triggers and timed
	// buffs nearly as often. They are shared machinery, not per-monster
	// content: a family file should be able to say "summon two of these,
	// cap four" in one line rather than reimplement pack tracking.
	//
	// Everything here is opt-in. A monster that calls none of it behaves
	// exactly like a vanilla Doom monster with a tier.
	// =================================================================

	// --- SUMMONING ---------------------------------------------------
	//
	// Live-pack counting walks the RS monster list rather than keeping a
	// stored array: an Array<Actor> of minions would need pruning every
	// time one died, and a stale pointer in it is a crash. Counting is
	// O(live monsters) but only runs when something actually tries to
	// summon, which is seconds apart at worst.

	int CountLiveMinions(Class<Actor> ofType = null)
	{
		int n = 0;
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster mo;
		while (mo = RS_MonsterMaster(it.Next()))
		{
			if (mo == self) continue;
			if (mo.master != self) continue;
			if (mo.health <= 0) continue;
			if (ofType && !(mo is ofType)) continue;
			n++;
		}
		return n;
	}

	// Spawn one minion bound to us. tierOffset is RELATIVE to our own
	// tier -- CHP's rule is that a summon inherits the summoner's
	// identity but is usually weaker, so -2 or -3 is the normal call and
	// 0 means "as strong as me".
	//
	// Minions are real RS_MonsterMaster monsters, deliberately: they get
	// the tier ladder, the body table, and can themselves be retiered by
	// the ambient dial. They do NOT count toward the level kill total --
	// a boss that spawns forever would make 100% kills impossible.
	Actor SummonMinion(Class<Actor> cls, int tierOffset = -2,
	                   double dist = 72.0, double zoff = 0.0, bool countKill = false)
	{
		if (!cls)
			return null;

		double ang = random(0, 359);
		Vector3 p = (pos.xy + (cos(ang), sin(ang)) * dist, pos.z + zoff);

		let mo = Spawn(cls, p, ALLOW_REPLACE);
		if (!mo)
			return null;

		mo.master = self;
		mo.target = target;          // inherit our current quarry
		mo.angle  = ang;
		if (!countKill)
			mo.bCOUNTKILL = false;

		let rm = RS_MonsterMaster(mo);
		if (rm)
			rm.SetTier(clamp(Tier + tierOffset, 0, 12), true);

		return mo;
	}

	// Capped pack summon. Returns how many actually spawned -- 0 means
	// the cap blocked it, which the caller usually wants to know so it
	// can fall back to a normal attack instead of standing there.
	int SummonPack(Class<Actor> cls, int count, int liveCap, int tierOffset = -2, double dist = 72.0)
	{
		if (!cls || count <= 0)
			return 0;

		int live = CountLiveMinions();
		int room = liveCap - live;
		if (room <= 0)
			return 0;

		int n = min(count, room);
		for (int i = 0; i < n; i++)
			SummonMinion(cls, tierOffset, dist);
		return n;
	}

	// Kill everything we summoned. CHP calls A_GivetoChildren("GoAway")
	// for this; we can do it directly since our minions are typed.
	// Prevents a dead boss leaving an unkillable pet swarm behind.
	void ReleaseMinions(bool killThem = true)
	{
		ThinkerIterator it = ThinkerIterator.Create("RS_MonsterMaster");
		RS_MonsterMaster mo;
		while (mo = RS_MonsterMaster(it.Next()))
		{
			if (mo == self || mo.master != self) continue;
			if (killThem && mo.health > 0)
				mo.DamageMobj(self, self, mo.health + 1000, "Massacre");
			else
				mo.master = null;
		}
	}

	// --- THRESHOLDS --------------------------------------------------
	//
	// One-shot health gate. Returns true EXACTLY once, the first time
	// health drops below the given fraction of max. Every CHP boss
	// enrage is this pattern guarded by a user_ variable; here the guard
	// is a bit in rsThresholdFlags, so a monster can have up to 32
	// independent gates without inventing a field per gate.
	//
	// slot is the caller's own index -- use 0, 1, 2... per monster.
	bool CheckThreshold(int slot, double fraction)
	{
		if (slot < 0 || slot > 31)
			return false;

		int bit = 1 << slot;
		if (rsThresholdFlags & bit)
			return false;

		int maxHP = TierMaxHealth > 0 ? TierMaxHealth : SpawnHealth();
		if (maxHP <= 0 || health > int(maxHP * fraction))
			return false;

		rsThresholdFlags |= bit;
		return true;
	}

	// Has a gate already fired? For attack pools that stay unlocked
	// after the enrage that opened them.
	bool ThresholdFired(int slot)
	{
		if (slot < 0 || slot > 31) return false;
		return (rsThresholdFlags & (1 << slot)) != 0;
	}

	// The permanent enrage itself, as CHP shapes it nearly every time:
	// faster, harder to stagger, more willing to shoot.
	void Enrage(double speedMult = 1.35, bool noPain = true, bool missileMore = true)
	{
		Speed *= speedMult;
		if (noPain)      bNOPAIN = true;
		if (missileMore) MissileChanceMult *= 2.0;
	}

	// --- TIMED PULSE -------------------------------------------------
	//
	// Temporary stat spike that reverts itself. CHP does this with ACS
	// delay() coroutines; a stored revert-tic checked in Tick is the
	// ZScript-native version. Guarded: calling it again while active is
	// ignored rather than stacking, so a monster spammed with pain
	// can't multiply its own speed.
	void PulseStats(double speedMult, double damageMult = 1.0,
	                int durationTics = 105, bool noPain = false)
	{
		if (rsPulseActive)
			return;

		rsPulseActive        = true;
		rsPulseBaseSpeed     = Speed;
		rsPulseBaseDamageMul = TierDamageMul;
		rsPulseSetNoPain     = noPain && !bNOPAIN;

		Speed         *= speedMult;
		TierDamageMul *= damageMult;
		if (rsPulseSetNoPain)
			bNOPAIN = true;

		rsPulseEndTic = level.time + durationTics;
	}

	private void RS_TickPulse()
	{
		if (!rsPulseActive || level.time < rsPulseEndTic)
			return;

		Speed         = rsPulseBaseSpeed;
		TierDamageMul = rsPulseBaseDamageMul;
		if (rsPulseSetNoPain)
			bNOPAIN = false;

		rsPulseActive = false;
	}

	// --- PHASE DODGE / BLINK -----------------------------------------
	//
	// Interrupt combat, become briefly hard to hit, resume. Found on
	// every high-tier CHP Archvile and on the Spectre/Revenant bosses,
	// always triggered off taking pain rather than off a timer.
	//
	// Won't start during a tier transform -- both want the render style,
	// and the transform is the more important read.
	void PhaseDodge(int tics = 54, double speedMult = 4.0, double toAlpha = 0.25)
	{
		if (rsDodgeActive || rsTransforming)
			return;

		rsDodgeActive    = true;
		rsDodgeBaseSpeed = Speed;
		rsDodgeBaseAlpha = alpha;
		rsDodgeBaseStyle = 0;
		rsDodgeSetNoPain = !bNOPAIN;

		Speed *= speedMult;
		A_SetRenderStyle(toAlpha, STYLE_Translucent);
		if (rsDodgeSetNoPain)
			bNOPAIN = true;

		rsDodgeEndTic = level.time + tics;
	}

	private void RS_TickDodge()
	{
		if (!rsDodgeActive || level.time < rsDodgeEndTic)
			return;

		Speed = rsDodgeBaseSpeed;
		A_SetRenderStyle(rsDodgeBaseAlpha, STYLE_Normal);
		if (rsDodgeSetNoPain)
			bNOPAIN = false;

		rsDodgeActive = false;
	}

	bool IsDodging() { return rsDodgeActive; }

	// --- ORBIT / ATTACH ----------------------------------------------
	//
	// Attach a satellite that follows us. The satellite class owns its
	// own warp loop and its own death condition (see
	// RS_MonsterSatellite in RS_MonsterCatalog.zs) -- all we do here is
	// spawn it and point it at ourselves.
	Actor AttachSatellite(Class<Actor> cls, double angleOffset = 0, double radius = 40, double height = 40)
	{
		if (!cls)
			return null;

		let mo = Spawn(cls, pos, ALLOW_REPLACE);
		if (!mo)
			return null;

		mo.master = self;
		mo.target = self;
		mo.angle  = angle + angleOffset;
		mo.bCOUNTKILL = false;

		let sat = RS_MonsterSatellite(mo);
		if (sat)
		{
			sat.OrbitRadius = radius;
			sat.OrbitHeight = height;
			sat.OrbitAngle  = angleOffset;
		}
		return mo;
	}

	// --- MORPH -------------------------------------------------------
	//
	// Replace ourselves with a different class, carrying our fight
	// forward. This is how CHP does multi-phase bosses: the "death" of
	// stage one spawns stage two rather than ending the encounter.
	//
	// Deliberately does NOT preserve health -- the new stage brings its
	// own pool, which is the whole point of a phase change.
	Actor MorphInto(Class<Actor> cls, bool inheritTier = true, bool inheritTarget = true)
	{
		if (!cls)
			return null;

		let mo = Spawn(cls, pos, ALLOW_REPLACE);
		if (!mo)
			return null;

		mo.angle = angle;
		mo.vel   = vel;
		if (inheritTarget && target)
			mo.target = target;

		let rm = RS_MonsterMaster(mo);
		if (rm && inheritTier)
			rm.SetTier(Tier, true);

		// Don't leave the corpse counting toward the kill total twice.
		bCOUNTKILL = false;
		return mo;
	}

	// --- CHARGE COUNTER ----------------------------------------------
	//
	// CHP's escalation engine, generalised. The Abyss Archvile's summon
	// portal ramps Revenant -> Imp -> Cacodemon off one of these; the
	// White Archvile spends it like a resource; the Black one uses it as
	// a live-pack budget paid down by dodging.
	void AddCharge(int n = 1)
	{
		ChargeCounter += n;
	}

	// Spend if affordable. Returns false (and spends nothing) if short,
	// so an attack can cleanly fall through to a cheaper option.
	bool SpendCharge(int cost)
	{
		if (ChargeCounter < cost)
			return false;
		ChargeCounter -= cost;
		return true;
	}

	void ResetCharge() { ChargeCounter = 0; }

	// =================================================================
	// KEYWORDS -- same BASE/GRANTED shape as RS_Weapon, same shared
	// RS_Keywords parser. Not forked.
	// =================================================================

	Array<string> GrantedKeywords;

	virtual string GetBaseKeywords()
	{
		return "";
	}

	bool HasKeyword(string key, string value)
	{
		if (RS_Keywords.StringHas(GetBaseKeywords(), key, value))
			return true;
		string needle = key .. ":" .. value;
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i] == needle)
				return true;
		return false;
	}

	string GetKeywordValue(string key)
	{
		string v = RS_Keywords.GetValue(GetBaseKeywords(), key);
		string prefix = key .. ":";
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i].Left(prefix.Length()) == prefix)
				v = GrantedKeywords[i].Mid(prefix.Length());
		return v;
	}

	void GetKeywordValues(string key, out Array<string> results)
	{
		RS_Keywords.GetValues(GetBaseKeywords(), key, results);
		string prefix = key .. ":";
		for (int i = 0; i < GrantedKeywords.Size(); i++)
			if (GrantedKeywords[i].Left(prefix.Length()) == prefix)
				results.Push(GrantedKeywords[i].Mid(prefix.Length()));
	}

	void GrantKeyword(string key, string value)
	{
		GrantedKeywords.Push(key .. ":" .. value);
	}

	// =================================================================
	// DEATH
	// =================================================================

	// Override true on a summoner whose pack should not outlive it.
	// CHP goes both ways on this deliberately -- the Deep One's
	// tentacles die with it, the Imp Master's imps don't -- so it's a
	// per-monster decision rather than a blanket rule.
	virtual bool MinionsDieWithMe()
	{
		return false;
	}

	// A morph-on-death monster names its next stage here. Returning a
	// class means "this death is a phase change, not the end of the
	// fight" -- the successor spawns where we fell.
	virtual Class<Actor> DeathMorphClass()
	{
		return null;
	}

	// --- FACTS ABOUT THIS MONSTER ------------------------------------
	//
	// These report what a monster IS. They deliberately do NOT decide
	// what any other system should do about it -- a monster shouldn't
	// know the loot system exists. RS_Bits reads these and applies its
	// own policy; if that policy later becomes "minions drop reduced
	// bits" instead of "minions drop nothing", that's an edit to Bits
	// and this file doesn't change.

	// Spawned by another monster rather than placed by the map or the
	// spawner. The thing that makes an infinite-summon loop farmable.
	bool IsSummonedMinion()
	{
		return master && (master is "RS_MonsterMaster");
	}

	// This body is one stage of a multi-stage fight and its death hands
	// off to another stage rather than ending the encounter.
	bool IsTransientStage()
	{
		return DeathMorphClass() != null;
	}

	override void Die(Actor source, Actor inflictor, int dmgflags, Name MeansOfDeath)
	{
		if (MinionsDieWithMe())
			ReleaseMinions(true);

		let next = DeathMorphClass();
		if (next)
		{
			let mo = MorphInto(next, true, true);
			// Hand the killer over so the next stage immediately knows
			// who it's fighting rather than standing idle.
			if (mo && source)
				mo.target = source;
		}

		Super.Die(source, inflictor, dmgflags, MeansOfDeath);
	}

	// =================================================================
	// TICK
	// =================================================================

	override void Tick()
	{
		Super.Tick();

		// Deferred tier-body jump (set by ApplyTier). Only while alive --
		// a corpse must never be yanked back into See.
		if (health > 0 && pendingStateJump.Length() > 0)
		{
			string j = pendingStateJump;
			pendingStateJump = "";
			State st = FindStateByString(j, true);
			if (st)
				SetState(st);
		}

		RS_TickTransform();
		RS_TickPulse();
		RS_TickDodge();

		// Corpse-nudge: a monster gibbed in mid-air can stick on its
		// infinite (-1) corpse frame before gravity grounds it. General
		// to every monster set, not tier-related.
		if (health <= 0 && !bNoGravity)
		{
			double fz = floorz;
			if (pos.z > fz + 0.5)
			{
				if (vel.z > -0.5) vel.z -= 0.8;
			}
			else if (pos.z < fz)
			{
				SetZ(fz);
				if (vel.z < 0) vel.z = 0;
			}
		}
	}

	// Every dynamic behaviour in here is meant to be switchable --
	// default settings keep combat Doom-honest, and a player who wants
	// full chaos turns them up.
	static bool RS_MonOpt(string name, bool def)
	{
		let cv = CVar.FindCVar(name);
		return cv ? cv.GetBool() : def;
	}

	// =================================================================
	// ENTRY-POINT DISPATCHERS. The engine enters monsters through these
	// fixed label names (A_Chase looks up "Missile"/"Melee", pain
	// routing looks up "Pain"...). Each one immediately routes to the
	// current tier's real cluster. The plain-frame fallbacks after each
	// dispatcher only run if a family shipped NO cluster at all for a
	// label -- the audit treats that as a defect; the fallback just
	// keeps it from being a freeze.
	// =================================================================

	States
	{
	Spawn:
		TNT1 A 0 NoDelay { return TierState("Spawn"); }
		TNT1 A 10 A_Look();
		Loop;
	See:
		TNT1 A 0 { return TierState("See"); }
		TNT1 A 4 A_Chase();
		Loop;
	Missile:
		TNT1 A 0 { return TierState("Missile"); }
		Goto See;
	Melee:
		TNT1 A 0 { return TierState("Melee"); }
		Goto See;
	Pain:
		TNT1 A 0 { return TierState("Pain"); }
		TNT1 A 3 A_Pain();
		Goto See;
	Death:
		TNT1 A 0 { return TierState("Death"); }
		TNT1 A 5 { A_Scream(); A_NoBlocking(); }
		Stop;
	XDeath:
		TNT1 A 0 { return TierState("XDeath"); }
		Goto Death;
	Raise:
		TNT1 A 0 { return TierState("Raise"); }
		Goto See;
	}
}

// =====================================================================
// Shared per-family base classes. Kept here rather than in a fourth
// kind of file -- this IS the template file, and a base class that
// exists purely to remove duplication across a family's concrete
// monster files belongs with the rest of the template machinery.
// =====================================================================

// Thin family-group shells. Their old shared "POSS"-literal state
// blocks were the skin-system bug -- every state advance re-baked a
// zombieman frame over whatever body the monster was supposed to wear.
// Bodies now live in each family's own per-tier clusters; these
// classes remain only as grouping points for shared mechanics and
// `is`-checks, inheriting the base dispatchers unchanged.
class RS_HumanMonster : RS_MonsterMaster abstract {}
class RS_DemonBase   : RS_MonsterMaster abstract {}
class RS_KnightBase  : RS_MonsterMaster abstract {}
