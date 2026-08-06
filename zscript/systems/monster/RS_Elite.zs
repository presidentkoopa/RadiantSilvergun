// =====================================================================
// RS_Elite -- hidden elite monsters and the reveal.
// ---------------------------------------------------------------------
// The shape of the system:
//
//   RS_EliteHandler    the spawn roll -- who is secretly an Elite, and
//                      which type (C01-C17) it will boost into; also
//                      the handler-side halves of the type powers
//                      (missile riders, on-hit payloads, magnet species)
//   RS_EliteToken      the monster's brain: boosted starting HP,
//                      nothing visible until 50% health, then the
//                      reveal -- full heal, double aggression and
//                      speed, sounds, sigil, type powers online
//   RS_ElitePentagram  the reveal sigil, tinted the elite's type colour
//
// HIDDEN BY DESIGN: an Elite gets its health boost at spawn but shows
// NOTHING until it drops to half health. The reveal is the contract --
// an Elite killed before revealing pays out nothing (docs/rs_00: the
// weapon-tier drop arms at the reveal; the drop system itself is a
// later step).
//
// Type powers live in RS_EliteColors.zs, their support actors in
// RS_EliteFX.zs. NOT BUILT YET: drops / tier roll, mutations, hybrids,
// the options menu, skill/playercount chance scaling.
//
// Works on PLAIN VANILLA MONSTERS -- token + event handler, nothing
// needs to inherit anything (see RS_SystemsMaster.zs header).
//
// WIRING (all four or it doesn't exist):
//   zscript.txt   -- includes (this file + RS_EliteColors.zs + RS_EliteFX.zs)
//   MAPINFO.txt   -- "RS_EliteHandler" in AddEventHandlers (a handler
//                    not listed there NEVER RUNS; a listed handler whose
//                    class is missing is a HARD CRASH at map load)
//   CVARINFO.txt  -- the rs_elite_* block
//   SNDINFO       -- rs/elite/* -> RSEL* lumps (sounds/monsters/)
// =====================================================================

class RS_EliteHandler : EventHandler
{
	// Weighted type pool: each type's weight cvar pushes its id N times,
	// the roll is one flat pick. Rebuilt per map so weight changes take
	// effect on the next level.
	Array<int> typePool;

	override void WorldLoaded(WorldEvent e)
	{
		typePool.Clear();
		PushTypeWeight(RSET_E01,   "rs_elite_weight_e01");
		PushTypeWeight(RSET_E02,       "rs_elite_weight_e02");
		PushTypeWeight(RSET_E03,    "rs_elite_weight_e03");
		PushTypeWeight(RSET_E04,    "rs_elite_weight_e04");
		PushTypeWeight(RSET_E05, "rs_elite_weight_e05");
		PushTypeWeight(RSET_E06,     "rs_elite_weight_e06");
		PushTypeWeight(RSET_E07,      "rs_elite_weight_e07");
		PushTypeWeight(RSET_E08,      "rs_elite_weight_e08");
		PushTypeWeight(RSET_E09,    "rs_elite_weight_e09");
		PushTypeWeight(RSET_E10,    "rs_elite_weight_e10");
		PushTypeWeight(RSET_E11,      "rs_elite_weight_e11");
		PushTypeWeight(RSET_E12,     "rs_elite_weight_e12");
		PushTypeWeight(RSET_E13,      "rs_elite_weight_e13");
		PushTypeWeight(RSET_E14,     "rs_elite_weight_e14");
		PushTypeWeight(RSET_E15,    "rs_elite_weight_e15");
		PushTypeWeight(RSET_E16,    "rs_elite_weight_e16");
		PushTypeWeight(RSET_E17,      "rs_elite_weight_e17");
	}

	private void PushTypeWeight(int id, string cvarName)
	{
		let cv = CVar.FindCVar(cvarName);
		if (!cv)
			return;
		for (int i = 0; i < cv.GetInt(); i++)
			typePool.Push(id);
	}

	// C16's pull thrusts by species so it drags players and nothing
	// else. Every player carries the species from map entry.
	override void PlayerEntered(PlayerEvent e)
	{
		let p = players[e.PlayerNumber];
		if (p && p.mo)
			p.mo.Species = 'RSEliteMagnet';
	}

	override void PlayerRespawned(PlayerEvent e)
	{
		let p = players[e.PlayerNumber];
		if (p && p.mo)
			p.mo.Species = 'RSEliteMagnet';
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		let mon = e.Thing;
		if (!mon)
			return;

		// Missile riders on a revealed elite's shots.
		if (mon.bMISSILE && mon.target)
		{
			// A clone's shots are downsized like the clone itself.
			if (mon.target.FindInventory("RS_EliteCloneToken"))
			{
				mon.scale.x = mon.scale.y = mon.scale.y * 0.75;
				mon.A_ScaleVelocity(0.75);
			}

			let mtok = RS_EliteToken(mon.target.FindInventory("RS_EliteToken"));
			if (mtok && mtok.revealed)
			{
				switch (mtok.colorId)
				{
					case RSET_E04:
						// C04's shots fly 1.5x, 2x boosted.
						mon.A_ScaleVelocity(CVar.FindCVar("rs_elite_booster").GetBool() ? 2.0 : 1.5);
						break;

					case RSET_E05:
						if (CVar.FindCVar("rs_elite_missilecreep").GetBool())
							mon.GiveInventory(CVar.FindCVar("rs_elite_booster").GetBool()
								? "RS_EliteFX_RedMissileCreep" : "RS_EliteFX_DarkGreenMissileCreep", 1);
						break;

					case RSET_E14:
						if (CVar.FindCVar("rs_elite_missilecreep").GetBool())
							mon.GiveInventory("RS_EliteFX_WhiteMissileCreep", 1);
						break;

					default:
						break;
				}
			}
			return;
		}

		if (!mon.bISMONSTER || mon.bFRIENDLY || mon.health <= 0)
			return;
		// COUNTKILL gate: decorative map actors flagged ISMONSTER but not
		// countable stay plain. SPECIAL things (pickup-flagged) never roll.
		if (!mon.bCOUNTKILL || mon.bSPECIAL)
			return;
		if (mon.FindInventory("RS_EliteToken"))
			return;
		// Clones (and anything else carrying the null marker) never roll.
		if (mon.FindInventory("RS_EliteNullToken"))
			return;

		int chance = CVar.FindCVar("rs_elite_chance").GetInt();
		if (chance <= 0)
			return;
		if (random[RSElite](1, 100) <= chance)
			MakeElite(mon, 0, false);
	}

	// The type roll. RSET_None on an empty pool (all weights 0) means a
	// plain typeless elite -- valid, not an error.
	private int RollType()
	{
		if (typePool.Size() == 0)
			return RSET_None;
		return typePool[random[RSElite](0, typePool.Size() - 1)];
	}

	// Marks a monster as an Elite: token, type, controller. typeId 0 =
	// weighted roll, 1-17 = forced type. Returns false if the monster is
	// ineligible or already marked.
	private bool MakeElite(Actor mon, int typeId, bool revealNow)
	{
		if (!mon || !mon.bISMONSTER || mon.health <= 0 || mon.bFRIENDLY)
			return false;
		if (mon.FindInventory("RS_EliteToken") || mon.FindInventory("RS_EliteNullToken"))
			return false;

		let tok = RS_EliteToken(mon.GiveInventoryType("RS_EliteToken"));
		if (!tok)
			return false;

		int id = (typeId >= RSET_E01 && typeId <= RSET_E17) ? typeId : RollType();
		if (id != RSET_None)
		{
			tok.colorId = id;
			tok.controller = RS_EliteColorController.Create(id, mon, tok);
		}
		if (revealNow)
			tok.Reveal();
		return true;
	}

	// Debug summons -- fired by the Monster Debug menu (MENUDEF) or the
	// console. `netevent rs_elite <type 0-17> <reveal 0/1>` marks the
	// monster under the crosshair; rs_elite_all marks everything living;
	// rs_elite_reveal pops the aimed elite without whittling it to 50%.
	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Player < 0 || !playeringame[e.Player])
			return;
		let pmo = players[e.Player].mo;
		if (!pmo)
			return;

		if (e.Name ~== "rs_elite")
		{
			let t = pmo.AimTarget();
			if (!t)
			{
				Console.Printf("rs_elite: no monster under the crosshair");
				return;
			}
			if (!MakeElite(t, e.Args[0], e.Args[1] != 0))
				Console.Printf("rs_elite: target ineligible or already an elite");
		}
		else if (e.Name ~== "rs_elite_all")
		{
			ThinkerIterator it = ThinkerIterator.Create("Actor");
			Actor mo;
			int count;
			while (mo = Actor(it.Next()))
			{
				if (MakeElite(mo, e.Args[0], false))
					count++;
			}
			Console.Printf("rs_elite_all: %d monsters marked", count);
		}
		else if (e.Name ~== "rs_elite_reveal")
		{
			let t = pmo.AimTarget();
			let tok = t ? RS_EliteToken(t.FindInventory("RS_EliteToken")) : null;
			if (!tok)
			{
				Console.Printf("rs_elite_reveal: aimed thing is not an elite");
				return;
			}
			if (!tok.revealed)
				tok.Reveal();
		}
	}

	override void WorldThingRevived(WorldEvent e)
	{
		let mon = e.Thing;
		if (!mon)
			return;

		// A raised clone doesn't get a second life -- it burns away.
		if (mon.FindInventory("RS_EliteNullToken"))
		{
			mon.A_SpawnItemEx("RS_EliteFX_WakeFire");
			mon.Destroy();
			return;
		}

		// A raised C01 was parked with its hiding flags still set (the
		// remains-destroyed death path leaves them on the corpse) --
		// give it its body back, or it returns invisible and unshootable.
		let tok = RS_EliteToken(mon.FindInventory("RS_EliteToken"));
		if (tok && tok.colorId == RSET_E01)
		{
			mon.bSOLID = mon.default.bSOLID;
			mon.bSHOOTABLE = mon.default.bSHOOTABLE;
			mon.bNOTAUTOAIMED = mon.default.bNOTAUTOAIMED;
			mon.bNEVERTARGET = mon.default.bNEVERTARGET;
			mon.bINVISIBLE = mon.default.bINVISIBLE;
			// bNOTARGET is reveal-state, not class default.
			mon.bNOTARGET = tok.revealed ? true : mon.default.bNOTARGET;
			mon.A_SpawnItemEx("RS_EliteFX_WakeFire");
		}
	}

	// On-hit payloads: a revealed elite hurting a player carries its
	// type's sting.
	override void WorldThingDamaged(WorldEvent e)
	{
		if (!(e.Thing is "PlayerPawn") || !e.DamageSource)
			return;

		let tok = RS_EliteToken(e.DamageSource.FindInventory("RS_EliteToken"));
		if (!tok || !tok.revealed)
			return;

		switch (tok.colorId)
		{
			case RSET_E14:
				e.Thing.GiveInventory("RS_EliteFX_Slowness1", 1);
				break;

			case RSET_E05:
				e.Thing.GiveInventory("RS_EliteFX_Poison", 1);
				break;

			case RSET_E07:
			{
				double ang = e.Thing.AngleTo(e.DamageSource);
				e.Thing.Thrust(24.0, ang - 180.0);
				break;
			}

			default:
				break;
		}
	}
}

class RS_EliteToken : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNTOSSABLE;
	}

	int boostedHealth;
	bool revealed;
	int colorId;								// ERSEliteType; RSET_None = no type half
	RS_EliteColorController controller;			// dormant until revealed flips; wakes itself

	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);

		int mult = other.bBOSS
			? CVar.FindCVar("rs_elite_healthmult_boss").GetInt()
			: CVar.FindCVar("rs_elite_healthmult").GetInt();
		// Multiply BEFORE dividing, or integer math floors the percent.
		boostedHealth = other.SpawnHealth() * mult / 100;
		if (boostedHealth < other.SpawnHealth())
			boostedHealth = other.SpawnHealth();
		other.health = boostedHealth;
	}

	override void DoEffect()
	{
		Super.DoEffect();
		if (!owner || owner.health <= 0)
			return;

		if (!revealed && owner.health <= boostedHealth / 2)
			Reveal();

		// A revealed elite raised from the dead (vile, C11) comes back
		// with its controller destroyed and its stats reset to class
		// defaults (the controller's death path does that so revives
		// can't compound multipliers). Re-apply the reveal's damage
		// multiplier, then rebuild the controller; it sees `revealed`
		// and wakes itself, re-running the type's setup on a clean body.
		if (revealed && colorId != RSET_None && !controller)
		{
			owner.DamageMultiply = owner.bBOSS
				? CVar.FindCVar("rs_elite_damagemult_boss").GetFloat()
				: CVar.FindCVar("rs_elite_damagemult").GetFloat();
			controller = RS_EliteColorController.Create(colorId, owner, self);
		}
	}

	// The 50% moment: full heal to the boosted ceiling, double
	// aggression and speed, both sound layers, the sigil -- and the
	// type controller wakes on its own next tick.
	void Reveal()
	{
		revealed = true;
		let mon = owner;
		bool isBoss = mon.bBOSS;

		mon.health = boostedHealth;
		// The field is DamageMultiply (DamageMultiplier is the ACS APROP
		// name only -- it does not compile here).
		mon.DamageMultiply = isBoss
			? CVar.FindCVar("rs_elite_damagemult_boss").GetFloat()
			: CVar.FindCVar("rs_elite_damagemult").GetFloat();

		mon.bALWAYSFAST = true;
		mon.bMISSILEMORE = true;
		mon.bMISSILEEVENMORE = true;
		mon.bNOINFIGHTING = true;
		mon.bNOTARGET = true;
		mon.bQUICKTORETALIATE = true;
		mon.bNOFEAR = true;
		mon.bNOTIMEFREEZE = true;
		mon.bSEEINVISIBLE = true;
		mon.bDROPOFF = true;
		mon.bBRIGHT = true;
		if (isBoss)
		{
			mon.bNOPAIN = true;
			mon.bDONTTHRUST = true;
		}
		else
		{
			mon.bJUMPDOWN = true;
		}
		mon.target = null;

		// Loop on channel 6 (stopped at death), reveal sting on 7, boss
		// layer on 5.
		mon.A_StartSound("rs/elite/loop", 6, CHANF_LOOPING, 0.8, isBoss ? 0.4 : 1.2);
		mon.A_StartSound("rs/elite/reveal", 7, 0, 1.0, 0.6);
		if (isBoss)
			mon.A_StartSound("rs/elite/boss", 5, 0, 1.0, 0.1);

		let penta = RS_ElitePentagram(Spawn("RS_ElitePentagram", mon.pos));
		if (penta)
		{
			penta.pentaRadius = mon.radius * 2.0;
			// The colour announces what just woke up. No controller =
			// plain elite = standard red.
			if (controller)
				penta.pentaColor = controller.PentagramColor();
		}
	}

	override void OwnerDied()
	{
		if (owner)
		{
			owner.A_StopSound(6);
			owner.bBRIGHT = false;
		}
		Super.OwnerDied();
	}
}

// The reveal sigil: a 360-point particle circle plus a five-line star
// (connect every second vertex of a pentagon = step 144 degrees, so no
// point table is needed), redrawn every tic with a fast alpha ramp-in
// and a slow fade-out, then gone.
class RS_ElitePentagram : Actor
{
	Default
	{
		+NOINTERACTION;
		+NOTONAUTOMAP;
		+NOTIMEFREEZE;
		RenderStyle "None";
	}

	double pentaRadius;
	color pentaColor;
	double pentaAlpha;
	bool fading;

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		angle = 0; // offsets go through SPF_RELPOS; zero angle keeps them unrotated
		pentaAlpha = 0.06;
		if (pentaColor == 0)
			pentaColor = Color(255, 255, 0, 0);
		if (pentaRadius <= 0)
			pentaRadius = 64;
	}

	override void Tick()
	{
		Super.Tick();
		DrawPentagram();

		// ~13 tics ramp to full, then ~2 seconds of fade.
		if (!fading)
		{
			pentaAlpha += 0.08;
			if (pentaAlpha >= 1.0)
			{
				pentaAlpha = 1.0;
				fading = true;
			}
		}
		else
		{
			pentaAlpha -= 0.008;
			if (pentaAlpha <= 0.01)
				Destroy();
		}
	}

	private void DrawPentagram()
	{
		for (int i = 0; i < 360; i++)
			SpawnDot(pentaRadius * cos(double(i)), pentaRadius * sin(double(i)));

		for (int k = 0; k < 5; k++)
		{
			double a1 = k * 144.0;
			double a2 = (k + 1) * 144.0;
			vector2 p1 = (pentaRadius * cos(a1), pentaRadius * sin(a1));
			vector2 p2 = (pentaRadius * cos(a2), pentaRadius * sin(a2));
			vector2 dir = p2 - p1;
			double len = dir.Length();
			if (len <= 0)
				continue;
			dir /= len;
			for (double s = 0; s < len; s += 1.0)
				SpawnDot(p1.x + dir.x * s, p1.y + dir.y * s);
		}
	}

	private void SpawnDot(double dx, double dy)
	{
		A_SpawnParticle(pentaColor, SPF_FULLBRIGHT | SPF_RELPOS,
			random[RSElitePenta](1, 3), random[RSElitePenta](5, 7), 0,
			dx, dy, 0,
			startalphaf: pentaAlpha);
	}
}
