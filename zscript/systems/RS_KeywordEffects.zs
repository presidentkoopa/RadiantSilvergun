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

	static play RS_ShotKeywordMods Resolve(RS_Weapon wpn, RS_AttackProfile p)
	{
		let m = RS_ShotKeywordMods(new("RS_ShotKeywordMods"));
		m.DmgMult = 1.0;
		m.PelletMult = 1.0;
		m.SpreadMult = 1.0;
		m.VelMult = 1.0;
		m.ScaleMult = 1.0;

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
			// ricochet/forking/orbiting/stick-delay/wall-runner: not
			// wired, see header for exactly why each isn't.
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

		return m;
	}
}
