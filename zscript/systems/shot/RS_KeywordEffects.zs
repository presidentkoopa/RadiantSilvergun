// =====================================================================
// RS_KeywordEffects -- the generic resolver. Reads the real (base +
// weapon-granted + beat-local) keywords in play for the shot about to
// fire and turns them into one RS_ShotKeywordMods bundle -- multipliers
// plus behavior flags -- the runtime layer that makes a GunBonsai
// affix's whole job be `wpn.GrantKeyword(...)` (every shot) or
// `p.GrantLocal(...)` (one rotation beat), never touching profile math
// directly. A_RS_FireSlot resolves this fresh every shot, so multiple
// grants compose automatically without anyone authoring the specific
// combination.
//
// WHY A CONTAINER NOW, NOT OUT-PARAMS: the first version was two
// functions with out-params (GetPayloadMultipliers x3 doubles,
// GetBehaviorFlags x1 bool). That shape can't grow -- every new
// behavior value or drawback axis meant changing two signatures and
// their call site. One resolved object means adding a field here and
// reading it at the dispatch, nothing else moves. This was the known
// blocker on every future behavior: value ("the resolver is literally
// one boolean").
//
// Three axes live here:
//   payload:   pure multipliers on existing dmg/pellet/spread math.
//   behavior:  changes what the spawned projectile DOES (flags).
//   drawback:  deliberate self-nerfs. These exist for the affix
//              GENERATOR's economy -- a negative-cost ingredient the
//              budget system can spend to afford a positive one (see
//              RS_AffixIngredients.zs). They are real, honest penalties,
//              not flavor.
//
// Scope, kept honest: payload multi/cluster/slug are real;
// explosive/hazard need an impact-spawn hook that doesn't exist -- still
// no-ops. behavior homing and piercing are real (both ride native
// GZDoom: A_SeekerMissile, +RIPPER); ricochet is DELIBERATELY not wired
// -- RS_BallisticFired extends FastProjectile, and FastProjectile does
// not support bouncing (engine limitation, not a choice) -- wiring it
// would produce a keyword that silently fails on every bullet weapon.
// forking/orbiting/stick-delay/wall-runner remain unbuilt. drawback
// sluggish/wild are real.
// =====================================================================

class RS_ShotKeywordMods : Object
{
	// Multipliers -- all start neutral (1.0), compose multiplicatively
	// across every granted tag, same fold-in shape as Condition effects.
	double DmgMult;
	double PelletMult;
	double SpreadMult;
	double VelMult;

	// Visual/collision size of what spawns. Neutral 1.0 means "use the
	// scale derived from the firer's archetype" (RS_Catalog.
	// ScaleForArchetype); an affix multiplies it from there. This is the
	// hook a joke upgrade like "Giant Pellet" writes to, and it composes
	// with everything else exactly like the other four.
	double ScaleMult;

	// Behavior flags -- consumed by the mode dispatches. Homing works on
	// bullet + heavy paths; Piercing is bullet-only (+RIPPER needs a
	// travelling projectile; hitscan has none, and a ripping ROCKET
	// detonating inside each victim it passes through is not a behavior,
	// it's a bug generator).
	bool Homing;
	bool Piercing;

	// --- Designed-affix extensions (see docs/rs_09_affix_slate.txt) ---
	// Seeker: rounds always track true; SeekLevel is how many enemies one
	// round may cycle through (retarget when its target dies), 99 =
	// unlimited (Mastery). SeekPrecise adds SMF_PRECISE hard tracking.
	// SeekTurn: degrees/tic of tracking authority, SCALED FROM THE
	// WEAPON'S ROLLED ACCURACY (rs_11 amplifier rule: a precise gun
	// hunts hard, a sloppy gun's seekers drift - the Accuracy roll
	// matters MORE with Seeker, not less). 0 = legacy fixed rate.
	int    SeekLevel;
	bool   SeekPrecise;
	double SeekTurn;
	// Ghost: PierceLevel = victims one round may punch through (99 = all),
	// PierceRetention = damage kept per punch-through. Stitch (Mastery):
	// a rip-kill turns the round into an unlimited seeker mid-flight.
	int    PierceLevel;
	double PierceRetention;
	bool   Stitch;
	// Bonecaller mid-levels: chance per PELLET that this round seeks,
	// when Homing itself isn't outright granted. 0 = off.
	double HomingChance;
	// Masteries with weapon-side geometry/spawn consequences.
	bool MasteryFan;      // Splitter: deterministic even fan, no scatter
	bool MasteryKick;     // Giant: rounds carry real kickback
	bool MasteryIgnite;   // Painter: impact leaves burning ground

	// Monster-signature spray economy (wave D1, docs/rs_13). How many
	// sub-projectiles a signature round releases -- beads on impact
	// (Nova), motes in flight (Swarm) -- and whether they seek. Capped
	// hard in the parts themselves: these numbers ride autofire weapons.
	int  SprayCount;
	bool SpraySeek;

	// Pain Train (wave D2): rounds force a flinch. ForcePain is the
	// +FORCEPAIN flag on the spawned round; FlinchChance is the
	// per-pellet odds below Mastery (a guaranteed stunlock at level 1
	// would trivialize the whole monster ladder).
	bool   ForcePain;
	double FlinchChance;

	// Momentum (wave D2): additive crit chance from the weapon's live
	// crit streak. Added to the weapon's rolled CritChance at dispatch,
	// never replacing it -- the roll stays king (rs_11 amplifier rule).
	double CritAdd;

	// Leveled-value tables for the designed affixes. Switch, not static
	// const arrays -- this engine build does not reliably resolve
	// `static const TYPE name[]` in class bodies (three separate real
	// bugs; see CLAUDE.md). Values are the tuned numbers from the affix
	// workshop -- change them here and docs/rs_09_affix_slate.txt
	// together or the doc lies.

	// Splitter: N-way exact wash. Returns the split count for a level.
	static int SplitCount(int lvl)
	{
		switch (lvl)
		{
			case 1: return 2;
			case 2: return 3;
			case 3: return 4;
			case 4: return 5;
		}
		return 6;   // L5 and Mastery
	}

	// Slugger: damage climbs, spread tightens, the round visibly grows.
	static void SlugRow(int lvl, out double dmg, out double spread, out double scale)
	{
		switch (lvl)
		{
			case 1: dmg = 1.8; spread = 0.30; scale = 1.0; return;
			case 2: dmg = 2.0; spread = 0.25; scale = 1.1; return;
			case 3: dmg = 2.2; spread = 0.20; scale = 1.2; return;
			case 4: dmg = 2.4; spread = 0.15; scale = 1.3; return;
		}
		dmg = 2.6; spread = 0.10; scale = 1.4;   // L5 and Mastery
	}

	static play RS_ShotKeywordMods Resolve(RS_Weapon wpn, RS_AttackProfile p)
	{
		let m = RS_ShotKeywordMods(new("RS_ShotKeywordMods"));
		m.DmgMult = 1.0;
		m.PelletMult = 1.0;
		m.SpreadMult = 1.0;
		m.VelMult = 1.0;
		m.ScaleMult = 1.0;
		m.PierceRetention = 1.0;

		// Overcharged's spread cost is accumulated separately and applied
		// at the end: its Focus Mastery waives the spread penalty (only
		// the penalty -- never the weapon's own base spread) for the
		// first shot after a deliberate >= 1s pause, and that decision
		// needs the whole parse done first.
		double overSpread = 1.0;
		bool focusMastery = false;

		// ---- payload: ------------------------------------------------
		// GRANTED + beat-local only. BASE keywords are identity, not
		// live math -- see GetGrantedValues' own comment for the
		// double-firing-shotgun bug that rule exists to prevent.
		Array<string> vals;
		wpn.GetGrantedValues("payload", vals);
		if (p) p.GetLocalValues("payload", vals);

		for (int i = 0; i < vals.Size(); i++)
		{
			if (vals[i] == "slug")
			{
				// Collapses the weapon's real current pellet count down
				// to one heavy round -- computed against its OWN count so
				// it stays correct across Promotion. The single-pellet
				// free-buff hole is closed at the ELIGIBILITY layer
				// (RS_AffixIngredients gates slug to PelletCount >= 2),
				// not here -- the math alone can't express "you may not
				// have this."
				int current = max(1, wpn.PelletCount);
				m.DmgMult *= 1.8;
				m.PelletMult *= 1.0 / current;
				m.SpreadMult *= 0.3;
			}
			else if (vals[i] == "cluster")
			{
				// Exact wash (0.333 * 3 = 1.0). Coverage, not power --
				// Promotion owns net pellet growth.
				m.DmgMult *= 1.0 / 3.0;
				m.PelletMult *= 3.0;
			}
			else if (vals[i] == "multi")
			{
				// Exact wash (0.5 * 2 = 1.0), same rule.
				m.DmgMult *= 0.5;
				m.PelletMult *= 2.0;
			}
			// --- Splitter (designed, leveled): splitN = N-way wash. ---
			else if (vals[i].Left(5) == "split")
			{
				string tail = vals[i].Mid(5);
				int n = (tail == "master") ? 6 : clamp(tail.ToInt(), 2, 6);
				m.DmgMult    *= 1.0 / n;
				m.PelletMult *= double(n);
				if (tail == "master")
					m.MasteryFan = true;
			}
			// --- Slugger (designed, leveled): slugN. Same collapse as
			// the generator's "slug" above, deeper numbers per level.
			// slugmaster additionally punches through a couple bodies. ---
			else if (vals[i].Left(4) == "slug" && vals[i].Length() > 4)
			{
				string tail = vals[i].Mid(4);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				double sdmg, sspread, sscale;
				SlugRow(lvl, sdmg, sspread, sscale);
				int current = max(1, wpn.PelletCount);
				m.DmgMult    *= sdmg;
				m.PelletMult *= 1.0 / current;
				m.SpreadMult *= sspread;
				m.ScaleMult  *= sscale;
				if (tail == "master")
				{
					m.Piercing = true;
					m.PierceLevel = 2;
					m.PierceRetention = 0.8;
				}
			}
			// --- Overcharged (designed, leveled): overN. Both numbers
			// climb together; the spread half is the honest price and is
			// applied at the end (Focus Mastery, see above). ---
			else if (vals[i].Left(4) == "over")
			{
				string tail = vals[i].Mid(4);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				m.DmgMult *= 1.0 + 0.15 * lvl;
				overSpread *= 1.0 + 0.20 * lvl;
				if (tail == "master")
					focusMastery = true;
			}
			// --- Giant (designed, leveled): giantN. Scale is visual AND
			// hitbox (ApplyProjectileScale), damage untouched. ---
			else if (vals[i].Left(5) == "giant")
			{
				string tail = vals[i].Mid(5);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				m.ScaleMult *= 1.0 + 0.25 * lvl;
				if (tail == "master")
					m.MasteryKick = true;
			}
			// explosive/hazard: no-ops on purpose, see header. single:
			// the neutral default, already expressed by 1.0s.
		}

		// ---- behavior: -----------------------------------------------
		vals.Clear();
		wpn.GetGrantedValues("behavior", vals);
		if (p) p.GetLocalValues("behavior", vals);

		for (int i = 0; i < vals.Size(); i++)
		{
			if (vals[i] == "homing")
				m.Homing = true;
			else if (vals[i] == "piercing")
				m.Piercing = true;
			// --- Seeker (designed, leveled): seekN. Homes true at every
			// level; the level buys retarget cycling, not accuracy.
			// Price: -5% damage per level (rounds that can't miss earn
			// slightly less per hit). Mastery: unlimited cycling +
			// precise tracking; a locked round curves around corners
			// because seeking never needed line of sight to steer. ---
			else if (vals[i].Left(4) == "seek")
			{
				string tail = vals[i].Mid(4);
				m.Homing = true;
				// Tracking authority comes from the ROLL: 4 deg/tic on a
				// sloppy gun up to 12 on a laser-accurate one. Accuracy
				// stays king even when rounds hunt.
				m.SeekTurn = 4.0 + 8.0 * clamp(wpn.Accuracy / 100.0, 0.0, 1.0);
				if (tail == "master")
				{
					m.SeekLevel = 99;
					m.SeekPrecise = true;
					m.DmgMult *= 0.95 ** 5;
				}
				else
				{
					int lvl = clamp(tail.ToInt(), 1, 5);
					m.SeekLevel = lvl;
					m.DmgMult *= 0.95 ** lvl;
				}
			}
			// --- Ghost (designed, leveled): pierceN. The retention loss
			// per punch-through IS the price; no separate tax. ---
			else if (vals[i].Left(6) == "pierce")
			{
				string tail = vals[i].Mid(6);
				m.Piercing = true;
				// Velocity's first real job (rs_11 amplifier rule): a fast
				// round punches deeper -- up to +10% retention at the top
				// of the velocity roll range. Rolled 2500-12500.
				double velBonus = 0.10 * clamp((wpn.Velocity - 2500.0) / 10000.0, 0.0, 1.0);
				if (tail == "master")
				{
					m.PierceLevel = 99;
					m.PierceRetention = min(0.95, 0.90 + velBonus);
					m.Stitch = true;
				}
				else
				{
					int lvl = clamp(tail.ToInt(), 1, 5);
					m.PierceLevel = (lvl >= 5) ? 99 : lvl;
					m.PierceRetention = min(0.95, 0.70 + 0.05 * (lvl - 1) + velBonus);
				}
			}
			// --- Bonecaller mid-levels: per-pellet homing chance. L5
			// grants plain "homing" instead; Mastery is the twin-fire:
			// every round doubles into a straight+seeking pair at half
			// damage each -- an exact wash with double the menace. ---
			else if (vals[i] == "bonechance25")
				m.HomingChance = 0.25;
			else if (vals[i] == "bonechance50")
				m.HomingChance = 0.50;
			else if (vals[i] == "bonechance75")
				m.HomingChance = 0.75;
			// L5: every round hunts. Expressed as chance 1.0 rather than
			// granting plain "homing" so ungranting a Bonecaller level
			// can never strip a homing granted by someone else (the
			// generator's ingredient, another affix).
			else if (vals[i] == "bonechance100")
				m.HomingChance = 1.0;
			else if (vals[i] == "bonemaster")
			{
				m.HomingChance = 1.0;
				m.DmgMult    *= 0.5;
				m.PelletMult *= 2.0;
			}
			// ricochet/forking/orbiting/stick-delay/wall-runner: not
			// wired, see header for exactly why each isn't.
		}

		// ---- element: (first live wiring of this axis -- Painter/Cryo).
		// The part identity (projectile class, sounds, DamageType) is
		// installed by the upgrade through the Affix* part-swap layer;
		// this is only the leveled math riding along with it.
		vals.Clear();
		wpn.GetGrantedValues("element", vals);
		if (p) p.GetLocalValues("element", vals);

		for (int i = 0; i < vals.Size(); i++)
		{
			// Painter: identity-first, +3%/level. Mastery ignites the
			// ground at impact (the minimal impact-spawn hook's first
			// real consumer).
			if (vals[i].Left(4) == "fire")
			{
				string tail = vals[i].Mid(4);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				m.DmgMult *= 1.0 + 0.03 * lvl;
				if (tail == "master")
					m.MasteryIgnite = true;
			}
			// Cryo: heavier rounds hit harder (+6%/level); the price is
			// the Capacity cut the upgrade itself applies. Mastery swaps
			// the part to the bouncing orb -- upgrade-side, not here.
			else if (vals[i].Left(3) == "ice")
			{
				string tail = vals[i].Mid(3);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				m.DmgMult *= 1.0 + 0.06 * lvl;
			}
			// --- WAVE D1 MONSTER SIGNATURES (docs/rs_13) ---------------
			// Arach-Plasma: the arachnotron's relentless bolt. Cheap, fast,
			// clean -- the smallest damage ramp of the three because its
			// identity is RATE, not weight. Mastery: plasma burns through
			// two bodies (the Slugger-mastery precedent for pierce as a
			// signature flavor, not a Ghost duplicate -- no level ladder,
			// no retention scaling, just the burn-through).
			else if (vals[i].Left(5) == "arach")
			{
				string tail = vals[i].Mid(5);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				m.DmgMult *= 1.0 + 0.02 * lvl;
				if (tail == "master")
				{
					m.Piercing = true;
					m.PierceLevel = 2;
					m.PierceRetention = 0.85;
				}
			}
			// Swarm: the Overlord's bee carrier. Levels buy MOTES, not
			// damage -- the round's rolled damage still lands on the
			// direct hit (rs_05's null-profile trap: a carrier that deals
			// nothing is hollow). Mastery: the motes hunt precisely.
			else if (vals[i].Left(5) == "swarm")
			{
				string tail = vals[i].Mid(5);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				m.SprayCount = 1 + lvl;          // 2..6 motes
				if (tail == "master")
				{
					m.SprayCount = 8;
					m.SpraySeek = true;
				}
			}
			// Nova: the cyberdemon's swoosh round -- a heavy shell that
			// detonates into a plasma bead nova. Levels buy beads AND a
			// real damage ramp (it's the heaviest of the three).
			// Mastery: the beads seek.
			// Pain Train: the flinch ladder. Levels buy the ODDS, Mastery
			// buys certainty -- against the monster ladder's own
			// painChance, which collapses at high tier (T12 = 16).
			else if (vals[i].Left(6) == "flinch")
			{
				string tail = vals[i].Mid(6);
				if (tail == "master")
				{
					m.ForcePain = true;
					m.FlinchChance = 1.0;
				}
				else
				{
					int lvl = clamp(tail.ToInt(), 1, 5);
					m.FlinchChance = 0.15 * lvl;   // 15% .. 75%
				}
			}
			// Momentum: each consecutive crit makes the next one likelier.
			// Reads the streak the weapon itself tracks; the ladder buys
			// how much each link in the chain is worth. Pure Crit-roll
			// amplifier -- a high-crit gun chains far more often.
			else if (vals[i].Left(8) == "momentum")
			{
				string tail = vals[i].Mid(8);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				double perLink = 0.02 * lvl;
				int cap = (tail == "master") ? 8 : 4;
				m.CritAdd += perLink * min(wpn.RS_CritStreak, cap);
			}
			else if (vals[i].Left(4) == "nova")
			{
				string tail = vals[i].Mid(4);
				int lvl = (tail == "master") ? 5 : clamp(tail.ToInt(), 1, 5);
				m.DmgMult *= 1.0 + 0.04 * lvl;
				m.SprayCount = 2 + lvl * 2;      // 4..12 beads
				if (tail == "master")
				{
					m.SprayCount = 16;
					m.SpraySeek = true;
				}
			}
		}

		// ---- drawback: -----------------------------------------------
		vals.Clear();
		wpn.GetGrantedValues("drawback", vals);
		if (p) p.GetLocalValues("drawback", vals);

		for (int i = 0; i < vals.Size(); i++)
		{
			if (vals[i] == "sluggish")
			{
				// Real velocity cost -- only meaningful on travelling
				// rounds, which is why the ingredient is mode-gated to
				// bullet weapons (a hitscan weapon taking "sluggish"
				// would bank the generator credit for free).
				m.VelMult *= 0.6;
			}
			else if (vals[i] == "wild")
			{
				// Real accuracy cost -- spread applies to bullet AND
				// hitscan paths, so the ingredient allows both.
				m.SpreadMult *= 1.5;
			}
		}

		// Overcharged's accumulated spread penalty, last. Focus Mastery:
		// the first shot after a >= 1 second pause pays no penalty --
		// rhythm inside the chaos. RS_LastShotTic is stamped by
		// A_RS_FireSlot on every committed pull (and on backfires).
		if (overSpread != 1.0)
		{
			bool focused = focusMastery
				&& (wpn.RS_LastShotTic == 0
					|| wpn.Level.maptime - wpn.RS_LastShotTic >= 35);
			if (!focused)
				m.SpreadMult *= overSpread;
		}

		return m;
	}
}
