// =====================================================================
// RS_ScoreRevival -- the death fire cone.
//
// When a player who has banked an extra life would die, they are pulled
// back at full health, made briefly untouchable, and the ground erupts:
// eight flame streams thrown outward and eight more raked along the
// floor, from an emitter that spins 2.5 degrees per tic for ~70 tics.
// The result is a rotating cone of fire that clears the room that just
// killed you.
//
// The arms are spawned in a real loop and every dimension of the cone --
// arm count, spin duration, blast damage and radius -- is a cvar, so it
// can be resized, retimed or made purely cosmetic without editing a
// single state.
//
// SPRITES: uses RSI1/RSI2 (sprites/combatfx/fire/), the same flame
// sheets RS_FireLoop already draws from -- verified present on disk, 13
// and 10 frames respectively. No new art dependency; the cone cannot
// break because an asset went missing.
// =====================================================================

// ---------------------------------------------------------------------
// The emitter. Spawned on the reviving player, spins, throws flame.
// ---------------------------------------------------------------------
class RS_ReviveExplosion : Actor
{
	// NOTE ON `invoker`: these are Actor states, not Weapon/Inventory
	// states, so the state code already runs on this actor -- member
	// fields are reached directly. `invoker` is only meaningful where an
	// item's states execute on its owner, and using it here does not
	// compile.
	int fireStep;
	int maxSteps;

	Default
	{
		+NOINTERACTION
		+NOGRAVITY
		+NOBLOCKMAP
		+FORCERADIUSDMG
		+NODAMAGETHRUST
		Radius 4;
		Height 4;
		Obituary "%o was caught in %k's revival.";
	}

	static int CVInt(string name, int def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetInt() : def;
	}

	static bool CVBool(string name, bool def)
	{
		let c = CVar.GetCVar(name, null);
		return c ? c.GetBool() : def;
	}

	// One rotation step: eight airborne streams + eight ground rakes.
	// A loop, not sixteen hand-written A_SpawnItemEx lines -- which is
	// what makes rs_score_revive_arms a real knob rather than a comment.
	void SpawnRing()
	{
		int arms = clamp(CVInt("rs_score_revive_arms", 8), 1, 32);
		double step = 360.0 / arms;
		double dist = 80.0;

		for (int i = 0; i < arms; i++)
		{
			double ang = i * step;

			A_SpawnItemEx("RS_RevivalFlame",
				dist, 0, -32,
				frandom(-0.5, 0.5), frandom(-0.5, 0.5), 2.5,
				ang, SXF_TRANSFERPOINTERS);

			A_SpawnItemEx("RS_RevivalFlameGround",
				dist, 0, -32,
				frandom(-0.2, 0.2), frandom(0.8, 1.2), 0,
				ang, SXF_TRANSFERPOINTERS);
		}
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			maxSteps = clamp(CVInt("rs_score_revive_tics", 70), 5, 210);

			if (CVBool("rs_score_revive_sound", true))
			{
				A_StartSound("weapons/rocklx", CHAN_BODY, CHANF_DEFAULT, 1.0, ATTN_NONE);
			}

			// The opening thump. 384 damage at radius 256 is a genuine
			// room-clearer, which is the point of spending a life.
			// Tunable, and settable to 0 for a cosmetic-only cone.
			int dmg = clamp(CVInt("rs_score_revive_blast", 384), 0, 2000);
			int rad = clamp(CVInt("rs_score_revive_blastradius", 256), 16, 1024);
			if (dmg > 0)
				A_Explode(dmg, rad, 0);
		}
		goto Burn;

	Burn:
		TNT1 A 1
		{
			SpawnRing();
			A_SetAngle(angle + 2.5);
			fireStep++;
		}
		TNT1 A 0 A_JumpIf(fireStep > maxSteps, "Finish");
		loop;

	Finish:
		// A final dense burst so the cone ends on a punch rather than
		// just stopping.
		TNT1 AAAA 0 { SpawnRing(); }
		TNT1 A 8;
		Stop;
	}
}


// ---------------------------------------------------------------------
// The outward flame stream. Damages, pierces, ignores invulnerability --
// the cone is bought with a life, so it is not politely stopped by armour
// or an invulnerability sphere on the thing that just killed you.
// ---------------------------------------------------------------------
class RS_RevivalFlame : Actor
{
	int burnLeft;

	Default
	{
		Radius 2;
		Height 2;
		Speed 25;
		Projectile;
		+MTHRUSPECIES
		+THRUACTORS
		+BLOODLESSIMPACT
		+NODAMAGETHRUST
		+FORCERADIUSDMG
		+FOILINVUL
		+PIERCEARMOR
		+DONTSPLASH
		RenderStyle "Add";
		Scale 0.35;
		Alpha 0.6;
		Obituary "%o basked in %k's revival.";
	}

	States
	{
	Spawn:
		RSI1 A 0 Bright NoDelay
		{
			A_ScaleVelocity(frandom(0.9, 1.1));
			burnLeft = 24;
			// Most of these pass through the world; a minority collide,
			// which keeps the cone from being stopped by the first wall.
			bPAINLESS = (random(0, 6) > 0);
		}
		goto Burn;

	Burn:
		RSI1 A 1 Bright
		{
			A_SpawnItemEx("RS_RevivalFlameVisual", 0, 0, 0, 0, 0,
				frandom(0.0, 2.0), 0, SXF_ABSOLUTEPOSITION);
			A_Explode(1, 64, 0, 0, 32);
			burnLeft--;
		}
		RSI1 A 0 A_JumpIf(burnLeft > 0, "Burn");
		Stop;

	Death:
		TNT1 A 0 A_JumpIf(burnLeft <= 0, "Gone");
		TNT1 A 1
		{
			A_SpawnItemEx("RS_RevivalFlameVisual", 0, 0, 0, 0, 0,
				frandom(0.0, 2.0), 0, SXF_ABSOLUTEPOSITION);
			A_Explode(1, 64, 0, 0, 32);
			burnLeft -= 3;
		}
		loop;

	Gone:
		TNT1 A 1;
		Stop;
	}
}


// ---------------------------------------------------------------------
// The floor rake -- pure visual, hugs the ground, no collision.
// ---------------------------------------------------------------------
class RS_RevivalFlameGround : Actor
{
	int burnLeft;

	Default
	{
		Radius 2;
		Height 2;
		+NOINTERACTION
		+DONTSPLASH
		RenderStyle "Add";
		Scale 0.3;
		Alpha 0.5;
	}

	States
	{
	Spawn:
		RSI2 A 0 Bright NoDelay { burnLeft = 12; }
		goto Burn;

	Burn:
		RSI2 A 1 Bright
		{
			A_SpawnItemEx("RS_RevivalFlameVisual", 0, 0, 0, 0, 0,
				frandom(0.0, 2.0), 0, SXF_ABSOLUTEPOSITION);
			burnLeft--;
		}
		RSI2 A 0 A_JumpIf(burnLeft > 0, "Burn");
		Stop;
	}
}


// ---------------------------------------------------------------------
// Client-side sparkle left behind by the streams. Purely decorative,
// so it is CLIENTSIDEONLY and cheap.
// ---------------------------------------------------------------------
class RS_RevivalFlameVisual : Actor
{
	Default
	{
		Radius 0;
		Height 0;
		+NOINTERACTION
		+CLIENTSIDEONLY
		+DONTSPLASH
		RenderStyle "Add";
		Scale 0.22;
		Alpha 0.4;
	}

	States
	{
	Spawn:
		RSI1 A 0 Bright NoDelay
		{
			// Drift, so the trail has volume instead of being a line of
			// identical puffs.
			Vel3DFromAngle(frandom(0.0, 1.0), frandom(0, 360), frandom(-20, 20));
		}
		RSI1 "ABCDE" 2 Bright;
		Stop;
	}
}
