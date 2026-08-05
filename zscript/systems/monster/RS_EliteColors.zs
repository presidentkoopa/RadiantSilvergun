// =====================================================================
// RS_EliteColors -- the seventeen Elite types, C01-C17.
// ---------------------------------------------------------------------
// A type is what an Elite boosts INTO at the reveal. Each is a
// controller Thinker created at the spawn roll that sleeps until
// RS_EliteToken's 50% reveal; on wake its base power comes online and,
// with rs_elite_booster on, its boosted special fires on top.
//
//   C01 DarkRed   comes back unless its remains are destroyed
//   C02 Red       2x health
//   C03 Orange    explodes on death (boost: cluster explosion)
//   C04 Yellow    faster body and projectiles
//   C05 DarkGreen toxic creep trail (boost: red creep)
//   C06 Green     short-range combat teleports
//   C07 Cyan      constant wind push, orbiting leaves
//   C08 Blue      fireball burst on death and when hurt
//   C09 Indigo    splits into weakened clones on death
//   C10 Violet    periodic seeker-fireball volleys
//   C11 Pink      raises nearby corpses, paying with its own health
//   C12 Black     deals 2x and takes 2x (deliberate glass cannon)
//   C13 Grey      lunges, leaves afterimages
//   C14 White     slowing creep trail and slow-on-hit
//   C15 Bronze    painless immovable tank, but slower
//   C16 Silver    magnetic field drags players in
//   C17 Gold      gilds nearby monsters into thralls
//
// Support actors: RS_EliteFX.zs. Handler-side halves (missile riders,
// on-hit payloads, the player pull species): RS_Elite.zs.
//
// NO static const ARRAYS -- on this engine build they do not reliably
// resolve (CLAUDE.md, found and fixed three separate times). Anything
// that wants to be a table here is a switch.
//
// DEFERRED VISUALS (deliberate, not forgotten): overhead type icons,
// per-type blood colours, missile glow overlays, ice-death tint.
// =====================================================================

enum ERSEliteType
{
	RSET_None,
	RSET_C01_DarkRed,
	RSET_C02_Red,
	RSET_C03_Orange,
	RSET_C04_Yellow,
	RSET_C05_DarkGreen,
	RSET_C06_Green,
	RSET_C07_Cyan,
	RSET_C08_Blue,
	RSET_C09_Indigo,
	RSET_C10_Violet,
	RSET_C11_Pink,
	RSET_C12_Black,
	RSET_C13_Grey,
	RSET_C14_White,
	RSET_C15_Bronze,
	RSET_C16_Silver,
	RSET_C17_Gold
}

// One controller per elite, created at the spawn roll, dormant until
// the token reveals.
class RS_EliteColorController : Thinker
{
	Actor elite;
	RS_EliteToken token;
	bool awake;
	bool boosted;		// rs_elite_booster was on when we woke
	int tic;
	int eftic;			// TickEffect period in tics; 0 = no periodic effect
	int oldHealth;
	int startHealth;	// post-wake health, normalised for skill scaling
	state prevState;	// for types that retime animation (C04/C15/C17)

	// The one place a type id becomes a controller -- a switch, not a
	// class table (see the file header).
	static RS_EliteColorController Create(int typeId, Actor mon, RS_EliteToken tok)
	{
		RS_EliteColorController c = null;
		switch (typeId)
		{
			case RSET_C01_DarkRed:   c = new("RS_EliteC01_DarkRed");   break;
			case RSET_C02_Red:       c = new("RS_EliteC02_Red");       break;
			case RSET_C03_Orange:    c = new("RS_EliteC03_Orange");    break;
			case RSET_C04_Yellow:    c = new("RS_EliteC04_Yellow");    break;
			case RSET_C05_DarkGreen: c = new("RS_EliteC05_DarkGreen"); break;
			case RSET_C06_Green:     c = new("RS_EliteC06_Green");     break;
			case RSET_C07_Cyan:      c = new("RS_EliteC07_Cyan");      break;
			case RSET_C08_Blue:      c = new("RS_EliteC08_Blue");      break;
			case RSET_C09_Indigo:    c = new("RS_EliteC09_Indigo");    break;
			case RSET_C10_Violet:    c = new("RS_EliteC10_Violet");    break;
			case RSET_C11_Pink:      c = new("RS_EliteC11_Pink");      break;
			case RSET_C12_Black:     c = new("RS_EliteC12_Black");     break;
			case RSET_C13_Grey:      c = new("RS_EliteC13_Grey");      break;
			case RSET_C14_White:     c = new("RS_EliteC14_White");     break;
			case RSET_C15_Bronze:    c = new("RS_EliteC15_Bronze");    break;
			case RSET_C16_Silver:    c = new("RS_EliteC16_Silver");    break;
			case RSET_C17_Gold:      c = new("RS_EliteC17_Gold");      break;
		}
		if (c)
		{
			c.elite = mon;
			c.token = tok;
		}
		return c;
	}

	// Per-type hooks. BoostEffect fires at the reveal when
	// rs_elite_booster is on -- the type's stronger form.
	virtual void InitEffect() {}
	virtual void TickEffect() {}
	virtual void HitEffect() {}
	virtual void DeathEffect() {}
	virtual void BoostEffect() {}
	virtual color ParticleColor() { return Color(255, 255, 255, 255); }
	virtual string TintName() { return ""; }
	virtual color PentagramColor() { return Color(255, 255, 0, 0); }
	// A few types replace the rising-fleck aura with their own effect.
	virtual bool HasAura() { return true; }

	void Wake()
	{
		awake = true;
		boosted = CVar.FindCVar("rs_elite_booster").GetBool();
		InitEffect();
		if (boosted)
			BoostEffect();
		// Normalised so skill-level monster-health scaling doesn't skew
		// the fractions the types compute from it (C01 revive, C11 cost).
		startHealth = int(elite.health / G_SkillPropertyFloat(SKILLP_MonsterHealth));
		oldHealth = elite.health;
		if (CVar.FindCVar("rs_elite_colortint").GetBool() && TintName().Length() > 0)
			elite.A_SetTranslation(TintName());
		elite.A_SpawnItemEx("RS_EliteFX_WakeFire", flags: SXF_TRANSFERTRANSLATION);
	}

	override void Tick()
	{
		Super.Tick();

		if (!elite)
		{
			Destroy();
			return;
		}
		if (level.isFrozen())
			return;

		// Dormant: nothing happens until the token's 50% reveal.
		if (!awake)
		{
			// Killed before revealing: nothing ever fired, nothing to
			// clean up -- stop thinking instead of idling on a corpse.
			if (elite.health < 1)
			{
				Destroy();
				return;
			}
			if (token && token.revealed)
				Wake();
			return;
		}

		if (elite.health < 1)
		{
			DeathEffect();
			// Give the corpse its class defaults back, so a raise (vile,
			// C11) re-applies type stats onto a clean body instead of
			// compounding them -- C12's 2x would otherwise become 4x, 8x
			// with every revive cycle, and C15/C16/C17's masses likewise.
			elite.painchance = elite.default.painchance;
			elite.DamageFactor = elite.default.DamageFactor;
			elite.DamageMultiply = elite.default.DamageMultiply;
			elite.mass = elite.default.mass;
			Destroy();
			return;
		}

		if (HasAura() && CVar.FindCVar("rs_elite_particles").GetBool())
			SpawnAura();

		// Falling-edge detection: HitEffect fires once per real hit,
		// heals only raise the watermark.
		if (elite.health > oldHealth)
			oldHealth = elite.health;
		if (elite.health < oldHealth)
		{
			oldHealth = elite.health;
			HitEffect();
		}

		if (eftic > 0 && ++tic >= eftic)
		{
			tic = 0;
			TickEffect();
		}
	}

	// One rising fleck of the type's palette off the body per tic.
	private void SpawnAura()
	{
		elite.A_SpawnParticle(ParticleColor(), SPF_FULLBRIGHT | SPF_RELPOS,
			lifetime: 35,
			size: frandom[RSEliteAura](4.0, 6.0),
			angle: frandom[RSEliteAura](0.0, 359.9),
			xoff: elite.radius,
			zoff: frandom[RSEliteAura](elite.height * 0.25, elite.height * 0.75),
			velz: frandom[RSEliteAura](0.3, 0.6),
			accelz: 0.01);
	}
}

// ---------------------------------------------------------------------
// C01 Dark Red -- won't stay dead. At 1 HP (BUDDHA floor) the body
// vanishes in a blood burst and leaves shootable remains: destroy the
// remains inside the timer and the elite dies for real; fail and it
// climbs back out at partial health.
// ---------------------------------------------------------------------
class RS_EliteC01_DarkRed : RS_EliteColorController
{
	Actor remains;
	bool hidden;
	int restics;
	int basetics;

	override void InitEffect()
	{
		eftic = 1;
		elite.bBUDDHA = true;
		elite.DeathSound = "misc/gibbed";
		basetics = 105;
	}

	override void TickEffect()
	{
		if (elite.health == 1 && !hidden)
		{
			for (int i; i < 32; i++)
				elite.A_SpawnItemEx("Blood", xvel: frandom(3.0, 8.0), zvel: frandom(4.0, 8.0), angle: frandom(0.0, 359.9), flags: SXF_USEBLOODCOLOR);

			hidden = true;
			elite.bSOLID = false;
			elite.bSHOOTABLE = false;
			elite.bNOTARGET = true;
			elite.bNOTAUTOAIMED = true;
			elite.bNEVERTARGET = true;
			elite.bINVISIBLE = true;
			elite.A_Stop();
			elite.tics = -1;
			restics = basetics;
			remains = Actor.Spawn("RS_EliteFX_Corpse", elite.pos);
			if (remains)
			{
				remains.translation = elite.translation;
				remains.CopyBloodColor(elite);
			}
			// Park the live body in a far map corner while the remains
			// stand in for it.
			elite.SetOrigin((16384, 16384, 0), false);
		}

		if (hidden && remains && remains.health < 1)
		{
			// The remains were destroyed in time: the elite dies for real.
			elite.SetOrigin(remains.pos, false);
			hidden = false;
			elite.bSOLID = true;
			elite.bSHOOTABLE = true;
			elite.bBUDDHA = false;
			elite.bSPECTRAL = false;
			elite.tics = 1;
			elite.A_Die();
		}

		if (hidden)
		{
			restics -= 1;
			if (restics < 0 && remains)
			{
				// Timer ran out: it comes back.
				hidden = false;
				elite.A_XScream();
				elite.SetStateLabel("Spawn");
				elite.SetOrigin(remains.pos, false);
				elite.health = int(boosted ? startHealth * 0.66 : startHealth * 0.33);
				elite.bSOLID = elite.default.bSOLID;
				elite.bSHOOTABLE = elite.default.bSHOOTABLE;
				// bNOTARGET is reveal-state (C01 only runs revealed) --
				// restoring the class default would strip the reveal.
				elite.bNOTARGET = true;
				elite.bNOTAUTOAIMED = elite.default.bNOTAUTOAIMED;
				elite.bNEVERTARGET = elite.default.bNEVERTARGET;
				elite.bINVISIBLE = elite.default.bINVISIBLE;
				elite.tics = 1;
				for (int i; i < 32; i++)
					elite.A_SpawnItemEx("Blood", xvel: frandom(3.0, 8.0), zvel: frandom(4.0, 8.0), angle: frandom(0.0, 359.9), flags: SXF_USEBLOODCOLOR);
				remains.Destroy();
			}
		}
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 4))
		{
			case 0:  return Color(255, 0xe6, 0x2e, 0x00);
			case 1:  return Color(255, 0xb3, 0x24, 0x00);
			case 2:  return Color(255, 0x80, 0x1a, 0x00);
			case 3:  return Color(255, 0x4d, 0x0f, 0x00);
			default: return Color(255, 0x1a, 0x05, 0x00);
		}
	}

	override string TintName() { return "rs_elite_c01"; }
	override color PentagramColor() { return Color(255, 128, 0, 0); }
}

// ---------------------------------------------------------------------
// C02 Red -- 2x health. Stacks on the token's boosted ceiling: the
// reveal heals to boostedHealth first, then this doubles it.
// ---------------------------------------------------------------------
class RS_EliteC02_Red : RS_EliteColorController
{
	override void InitEffect()
	{
		elite.health *= 2;
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 3))
		{
			case 0:  return Color(255, 0xff, 0x00, 0x00);
			case 1:  return Color(255, 0xff, 0x4d, 0x4d);
			case 2:  return Color(255, 0xff, 0x99, 0x99);
			default: return Color(255, 0xff, 0xff, 0xff);
		}
	}

	override string TintName() { return "rs_elite_c02"; }
	override color PentagramColor() { return Color(255, 255, 0, 0); }
}

// ---------------------------------------------------------------------
// C03 Orange -- explodes on death. Boost: cluster explosion that rains
// bomblets.
// ---------------------------------------------------------------------
class RS_EliteC03_Orange : RS_EliteColorController
{
	double missileofs;
	class<Actor> explosiontype;

	override void InitEffect()
	{
		missileofs = elite.height * 0.5;
		explosiontype = "RS_EliteFX_Explosion";
	}

	override void BoostEffect()
	{
		explosiontype = "RS_EliteFX_ClusterExplosion";
	}

	override void DeathEffect()
	{
		let explosion = elite.Spawn(explosiontype, (elite.pos.x, elite.pos.y, elite.pos.z + missileofs), 0);
		if (explosion)
			explosion.target = elite.target;
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 4))
		{
			case 0:  return Color(255, 0xff, 0xff, 0xff);
			case 1:  return Color(255, 0xff, 0x99, 0x00);
			case 2:  return Color(255, 0xff, 0xad, 0x33);
			case 3:  return Color(255, 0xff, 0x5c, 0x33);
			default: return Color(255, 0xff, 0x33, 0x00);
		}
	}

	override string TintName() { return "rs_elite_c03"; }
	override color PentagramColor() { return Color(255, 255, 156, 55); }
}

// ---------------------------------------------------------------------
// C04 Yellow -- faster: every new state's duration is divided by the
// factor (1.5 base, 2.0 boosted). Its projectiles are also scaled up by
// the handler at missile spawn -- see RS_EliteHandler.
// ---------------------------------------------------------------------
class RS_EliteC04_Yellow : RS_EliteColorController
{
	double factor;

	override void InitEffect()
	{
		eftic = 1;
		factor = 1.5;
	}

	override void BoostEffect()
	{
		factor = 2.0;
	}

	override void TickEffect()
	{
		// Never retime a dying state or a -1-duration state.
		if (elite.health < 1 || elite.tics <= 0)
			return;
		if (prevState != elite.curState)
			elite.A_SetTics(int(elite.tics / factor));
		prevState = elite.curState;
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 3))
		{
			case 0:  return Color(255, 0xff, 0xff, 0xff);
			case 1:  return Color(255, 0xff, 0xff, 0xb3);
			case 2:  return Color(255, 0xff, 0xff, 0x4d);
			default: return Color(255, 0xe6, 0xe6, 0x00);
		}
	}

	override string TintName() { return "rs_elite_c04"; }
	override color PentagramColor() { return Color(255, 255, 225, 0); }
}

// ---------------------------------------------------------------------
// C05 Dark Green -- drops a trail of toxic creep while it has a target.
// Boost: red creep, denser and longer-lived. Its projectiles drip creep
// too when rs_elite_missilecreep is on, and its hits poison -- both
// handler-side.
// ---------------------------------------------------------------------
class RS_EliteC05_DarkGreen : RS_EliteColorController
{
	class<Actor> creep;

	override void InitEffect()
	{
		eftic = 10;
		creep = "RS_EliteFX_DarkGreenCreep";
	}

	override void BoostEffect()
	{
		creep = "RS_EliteFX_RedCreep";
	}

	override void TickEffect()
	{
		if (elite.target)
			elite.A_SpawnItemEx(creep, xofs: -16, yofs: frandom(-16.0, 16.0), angle: frandom(0.00, 360.00), flags: SXF_SETTARGET);
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 3))
		{
			case 0:  return Color(255, 0x00, 0xb3, 0x00);
			case 1:  return Color(255, 0x00, 0x80, 0x00);
			case 2:  return Color(255, 0x00, 0x4d, 0x00);
			default: return Color(255, 0x00, 0x1a, 0x00);
		}
	}

	override string TintName() { return "rs_elite_c05"; }
	override color PentagramColor() { return Color(255, 0, 128, 0); }
}

// ---------------------------------------------------------------------
// C06 Green -- combat teleporter: every second or so it may blink a
// random distance in a random direction, fog on both ends. Boost:
// farther, more often. Getting hit can trigger one too.
// ---------------------------------------------------------------------
class RS_EliteC06_Green : RS_EliteColorController
{
	int steps;
	int chance;
	int cooldown;

	override void InitEffect()
	{
		eftic = 35;
		steps = 50;
		chance = 4;
	}

	override void BoostEffect()
	{
		steps = int(steps * 1.5);
		chance = 2;
	}

	override void TickEffect()
	{
		if (cooldown)
		{
			cooldown--;
			return;
		}

		if (elite.target && !random(0, chance))
		{
			int maxstep = random(steps, steps * 2);
			elite.A_SpawnItemEx("TeleportFog");
			elite.bJUMPDOWN = true;
			elite.bTHRUACTORS = true;
			elite.MaxDropOffHeight = 512;
			elite.MaxStepHeight = 512;
			elite.A_SetAngle(elite.angle + randompick(-90, -45, 0, 45, 90));
			for (int i = 0; i < maxstep; i++)
				elite.A_Chase(null, null, CHF_NORANDOMTURN);
			// bJUMPDOWN is reveal-state for non-bosses -- keep it.
			elite.bJUMPDOWN = elite.bBOSS ? elite.default.bJUMPDOWN : true;
			elite.bTHRUACTORS = elite.default.bTHRUACTORS;
			elite.MaxDropOffHeight = elite.default.MaxDropOffHeight;
			elite.MaxStepHeight = elite.default.MaxStepHeight;
			elite.A_SpawnItemEx("TeleportFog");
			cooldown = random(2, 5);
		}
	}

	override void HitEffect()
	{
		if (!random(0, 2))
			TickEffect();
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 4))
		{
			case 0:  return Color(255, 0xff, 0xff, 0xff);
			case 1:  return Color(255, 0x33, 0xcc, 0x33);
			case 2:  return Color(255, 0x70, 0xdb, 0x70);
			case 3:  return Color(255, 0x1f, 0x7a, 0x1f);
			default: return Color(255, 0xd8, 0xfe, 0x01);
		}
	}

	override string TintName() { return "rs_elite_c06"; }
	override color PentagramColor() { return Color(255, 0, 255, 0); }
}

// ---------------------------------------------------------------------
// C07 Cyan -- a constant gale shoves everything away; leaves orbit the
// body. Boost: double the force. Its hits also knock the player back --
// handler-side.
// ---------------------------------------------------------------------
class RS_EliteC07_Cyan : RS_EliteColorController
{
	int windforce;

	override void InitEffect()
	{
		eftic = 1;
		windforce = 192;
		for (int i = 0; i < 8; i++)
			elite.A_SpawnItemEx("RS_EliteFX_Leaves", angle: i * 45, flags: SXF_SETMASTER | SXF_NOCHECKPOSITION);
	}

	override void BoostEffect()
	{
		windforce = 384;
	}

	override void TickEffect()
	{
		elite.A_RadiusThrust(windforce, 384, RTF_NOIMPACTDAMAGE | RTF_NOTMISSILE);
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 2))
		{
			case 0:  return Color(255, 0xff, 0xff, 0xff);
			case 1:  return Color(255, 0xcc, 0xff, 0xff);
			default: return Color(255, 0x33, 0xcc, 0xff);
		}
	}

	override string TintName() { return "rs_elite_c07"; }
	override color PentagramColor() { return Color(255, 188, 255, 255); }
}

// ---------------------------------------------------------------------
// C08 Blue -- dies in a radial fireball burst, sized by its body; also
// spits a smaller ring when hurt. Boost: more projectiles.
// ---------------------------------------------------------------------
class RS_EliteC08_Blue : RS_EliteColorController
{
	int projectiles;
	int hitPause;
	int tiers;

	override void InitEffect()
	{
		eftic = 20;
		projectiles = int((elite.radius * 0.33) * 2);
		tiers = int(max(1, elite.height / 32));
		tiers = int(tiers * (elite.bBOSS ? 1.5 : 1));
	}

	override void BoostEffect()
	{
		projectiles = int(elite.radius * 0.50);
	}

	override void TickEffect()
	{
		if (hitPause)
			hitPause--;
	}

	override void DeathEffect()
	{
		if (projectiles < 1)
			return;
		double step = double(360.0 / double(projectiles));
		for (int j = 0; j < tiers; j++)
		{
			for (int i = 0; i < projectiles; i++)
			{
				double ang = ((step * 0.5) * j) + (i * step);
				elite.A_SpawnProjectile("RS_EliteFX_Fireball1", spawnHeight: random(-4, 4) + (24 + (j * 24)), angle: ang, flags: CMF_AIMDIRECTION, pitch: -6.125);
			}
		}
	}

	override void HitEffect()
	{
		if (!random(0, 4) && !hitPause)
		{
			hitPause = random(1, 4);
			int proj2 = int(projectiles * 0.25);
			if (proj2 < 1)
				return;
			double step = 360 / proj2;
			for (int i = 0; i < proj2; i++)
				elite.A_SpawnProjectile("RS_EliteFX_Fireball1", angle: i * step, flags: CMF_AIMDIRECTION, pitch: -6.125);
		}
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 3))
		{
			case 0:  return Color(255, 0x59, 0x59, 0xff);
			case 1:  return Color(255, 0x80, 0x80, 0xff);
			case 2:  return Color(255, 0xb3, 0xb3, 0xff);
			default: return Color(255, 0xff, 0xff, 0xff);
		}
	}

	override string TintName() { return "rs_elite_c08"; }
	override color PentagramColor() { return Color(255, 89, 89, 255); }
}

// ---------------------------------------------------------------------
// C09 Indigo -- splits on death into weakened copies of itself: 75%
// size, health and damage, excluded from kill counts and from ever
// being Elites themselves. Boost: four instead of two.
// ---------------------------------------------------------------------
class RS_EliteC09_Indigo : RS_EliteColorController
{
	class<Actor> tospawn;
	int spawnCount;

	override void InitEffect()
	{
		tospawn = elite.GetClassName();
		spawnCount = 2;
	}

	override void BoostEffect()
	{
		spawnCount = 4;
	}

	override void DeathEffect()
	{
		for (int i; i < spawnCount; i++)
		{
			Actor a;
			bool b;
			int spawnDist = int(-(12 * spawnCount) * 0.5);
			[b, a] = elite.A_SpawnItemEx(tospawn, xofs: random(-12, 12), yofs: spawnDist + (12 * i), xvel: frandom(2.0, 4.0), zvel: frandom(4.0, 6.0), angle: 180 + ((360 / spawnCount) * i), flags: SXF_TRANSFERTRANSLATION | SXF_NOCHECKPOSITION | SXF_TRANSFERPOINTERS);

			if (a)
			{
				a.GiveInventory("RS_EliteCloneToken", 1);
				a.health = int(a.SpawnHealth() * 0.75);
				a.A_SetSize(a.radius * 0.75, a.height * 0.75);
				a.scale = a.scale * 0.75;
				a.DamageMultiply = 0.75;
				a.alpha = elite.alpha;
				a.bTHRUSPECIES = true;
				a.bDONTHARMSPECIES = true;
				a.A_GiveInventory("RS_EliteNullToken");
				a.A_GiveInventory("RS_EliteFX_VoiceChanger");
				a.CopyBloodColor(elite);
				let voiceChange = RS_EliteFX_VoiceChanger(a.FindInventory("RS_EliteFX_VoiceChanger"));
				if (voiceChange)
					voiceChange.factor = 1.15;
				a.Species = "RSEliteClones";
				a.A_ChangeCountFlags(0, FLAG_NO_CHANGE, FLAG_NO_CHANGE);
			}
		}
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 3))
		{
			case 0:  return Color(255, 0xa0, 0x81, 0xfe);
			case 1:  return Color(255, 0x7a, 0x4e, 0xfd);
			case 2:  return Color(255, 0xb3, 0xb3, 0xff);
			default: return Color(255, 0xc6, 0xb3, 0xfe);
		}
	}

	override string TintName() { return "rs_elite_c09"; }
	override color PentagramColor() { return Color(255, 160, 129, 254); }
}

// ---------------------------------------------------------------------
// C10 Violet -- periodic volleys of seeker fireballs in one of three
// patterns (straight, forked, radial). Boost: faster cycle and an
// extra layer on every pattern.
// ---------------------------------------------------------------------
class RS_EliteC10_Violet : RS_EliteColorController
{
	override void InitEffect()
	{
		eftic = 30;
	}

	override void BoostEffect()
	{
		eftic = 20;
	}

	override void TickEffect()
	{
		if (elite.target && random(0, 2))
		{
			int rand = randompick(0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2);
			switch (rand)
			{
				case 0:
					elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 0, CMF_AIMDIRECTION, pitch: -6.125);
					if (boosted)
					{
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, -12.5, CMF_AIMDIRECTION, pitch: -6.125);
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 12.5, CMF_AIMDIRECTION, pitch: -6.125);
					}
					break;

				case 1:
					elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, -12.5, CMF_AIMDIRECTION, pitch: -6.125);
					elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 12.5, CMF_AIMDIRECTION, pitch: -6.125);
					if (boosted)
					{
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, -25.0, CMF_AIMDIRECTION, pitch: -6.125);
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 25.0, CMF_AIMDIRECTION, pitch: -6.125);
					}
					break;

				case 2:
					elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 0.0, CMF_AIMDIRECTION, pitch: -6.125);
					elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 90.0, CMF_AIMDIRECTION, pitch: -6.125);
					elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, -90.0, CMF_AIMDIRECTION, pitch: -6.125);
					elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, -180.0, CMF_AIMDIRECTION, pitch: -6.125);
					if (boosted)
					{
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 45.0, CMF_AIMDIRECTION, pitch: -6.125);
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, -45.0, CMF_AIMDIRECTION, pitch: -6.125);
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, 135.0, CMF_AIMDIRECTION, pitch: -6.125);
						elite.A_SpawnProjectile("RS_EliteFX_Fireball2", elite.height * 0.5, 0, -130.0, CMF_AIMDIRECTION, pitch: -6.125);
					}
					break;
			}
		}
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 4))
		{
			case 0:  return Color(255, 0x80, 0x00, 0x80);
			case 1:  return Color(255, 0xcc, 0x00, 0xcc);
			case 2:  return Color(255, 0x33, 0x00, 0x33);
			case 3:  return Color(255, 0xff, 0xb3, 0xff);
			default: return Color(255, 0x00, 0x00, 0x00);
		}
	}

	override string TintName() { return "rs_elite_c10"; }
	override color PentagramColor() { return Color(255, 128, 0, 128); }
}

// ---------------------------------------------------------------------
// C11 Pink -- battlefield necromancer: every two seconds it raises
// every raisable corpse in range, paying 20% of its own base health per
// body. Stops when it's down to its last fifth. Boost: double reach.
// ---------------------------------------------------------------------
class RS_EliteC11_Pink : RS_EliteColorController
{
	int radfactor;

	override void InitEffect()
	{
		eftic = 70;
		radfactor = 4;
	}

	override void BoostEffect()
	{
		radfactor = 8;
	}

	override void TickEffect()
	{
		if (elite.health <= startHealth * 0.2)
			return;

		ThinkerIterator think = ThinkerIterator.Create("Actor");
		Actor mo;
		while (mo = Actor(think.Next()))
		{
			// Owner ruling 2026-08-05: dead elites of OTHER types are fair
			// game to raise -- only fellow C11s and clones are off the
			// menu. (An earlier pass excluded every elite corpse; reverted.)
			let dtok = RS_EliteToken(mo.FindInventory("RS_EliteToken"));
			if (mo.Distance2D(elite) < (elite.radius * radfactor) &&
				mo.bISMONSTER && mo.health < 1 &&
				mo.FindState("Raise") &&
				!(dtok && dtok.colorId == RSET_C11_Pink) &&
				!mo.CountInv("RS_EliteNullToken"))
			{
				if (mo.RaiseActor(mo))
					elite.A_DamageSelf(int(startHealth * 0.2));
			}
		}
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 4))
		{
			case 0:  return Color(255, 0xff, 0x8a, 0xa0);
			case 1:  return Color(255, 0xff, 0x66, 0x82);
			case 2:  return Color(255, 0xff, 0xcc, 0xd5);
			case 3:  return Color(255, 0xff, 0xb3, 0xff);
			default: return Color(255, 0xff, 0xff, 0xff);
		}
	}

	override string TintName() { return "rs_elite_c11"; }
	override color PentagramColor() { return Color(255, 255, 130, 143); }
}

// ---------------------------------------------------------------------
// C12 Black -- deals 2x damage AND takes 2x damage. Deliberate glass
// cannon; the DamageFactor line is intentional, do not "fix" it.
// ---------------------------------------------------------------------
class RS_EliteC12_Black : RS_EliteColorController
{
	override void InitEffect()
	{
		elite.DamageMultiply *= 2.0;
		elite.DamageFactor *= 2.0;
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 2))
		{
			case 0:  return Color(255, 0x00, 0x00, 0x00);
			case 1:  return Color(255, 0x4d, 0x4d, 0x4d);
			default: return Color(255, 0x99, 0x99, 0x99);
		}
	}

	override string TintName() { return "rs_elite_c12"; }
	// Near-invisible sigil lines are the point -- the black elite
	// announces itself less.
	override color PentagramColor() { return Color(255, 32, 32, 32); }
}

// ---------------------------------------------------------------------
// C13 Grey -- closes distance violently: sudden sidesteps and 48-unit
// lunges straight at you, each leaving a fading afterimage trail.
// ---------------------------------------------------------------------
class RS_EliteC13_Grey : RS_EliteColorController
{
	override void InitEffect()
	{
		eftic = 8;
	}

	override void TickEffect()
	{
		if (elite.target && random(0, 1) && elite.CheckSight(elite.target))
		{
			if (random(0, 1) && elite.CheckIfInTargetLOS(30, 0, 500))
			{
				elite.A_FaceTarget();
				elite.A_SkelWhoosh();
				elite.A_ChangeVelocity(0, frandompick(-16, 16), 0, CVF_RELATIVE);
				elite.GiveInventory("RS_EliteFX_GreyShadowSpawner", 1);
				return;
			}
			if (!random(0, 3) && elite.CheckIfInTargetLOS(30, 0, 500))
			{
				elite.A_FaceTarget();
				elite.A_ChangeVelocity(48.0, 0, 2.0, CVF_RELATIVE);
				elite.A_SkelWhoosh();
				elite.GiveInventory("RS_EliteFX_GreyShadowSpawner", 1);
			}
		}
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 2))
		{
			case 0:  return Color(255, 0xff, 0xff, 0xff);
			case 1:  return Color(255, 0x80, 0x80, 0x80);
			default: return Color(255, 0x00, 0x00, 0x00);
		}
	}

	override string TintName() { return "rs_elite_c13"; }
	override color PentagramColor() { return Color(255, 192, 192, 192); }
}

// ---------------------------------------------------------------------
// C14 White -- slowing creep trail, plus a periodic slow-pulse around
// itself. Boost: bigger creep, wider pulse. Its projectiles drip creep
// (rs_elite_missilecreep) and its hits slow -- handler-side.
// ---------------------------------------------------------------------
class RS_EliteC14_White : RS_EliteColorController
{
	class<Actor> creep;
	int radfactor;

	override void InitEffect()
	{
		eftic = 10;
		creep = "RS_EliteFX_WhiteCreep";
		radfactor = 2;
	}

	override void BoostEffect()
	{
		creep = "RS_EliteFX_BigWhiteCreep";
		radfactor = 3;
	}

	override void TickEffect()
	{
		if (elite.target)
		{
			if (!random(0, 1))
				elite.A_RadiusGive("RS_EliteFX_Slowness2", elite.radius * radfactor, RGF_PLAYERS);
			elite.A_SpawnItemEx(creep, xofs: -16, yofs: frandom(-16.0, 16.0), flags: SXF_SETTARGET);
		}
	}

	override color ParticleColor()
	{
		switch (random[RSEliteAura](0, 2))
		{
			case 0:  return Color(255, 0xff, 0xff, 0xff);
			case 1:  return Color(255, 0xb3, 0xb3, 0xb3);
			default: return Color(255, 0x66, 0x66, 0x66);
		}
	}

	override string TintName() { return "rs_elite_c14"; }
	override color PentagramColor() { return Color(255, 255, 255, 255); }
}

// ---------------------------------------------------------------------
// C15 Bronze -- the wall: no pain, half damage taken, double health,
// immovable mass, but every state runs 1.75x slower. Sparkles instead
// of an aura.
// ---------------------------------------------------------------------
class RS_EliteC15_Bronze : RS_EliteColorController
{
	override bool HasAura() { return false; }

	override void InitEffect()
	{
		eftic = 1;
		elite.painchance = 0;
		elite.DamageFactor *= 0.5;
		elite.health = int(elite.health * 2.0);
		elite.mass = 0x7FFFFFFF;
		elite.bNOBLOOD = true;
	}

	override void TickEffect()
	{
		if (!random(0, 8))
		{
			elite.A_SpawnItemEx("RS_EliteFX_Sparkle", xofs: elite.radius,
				zofs: frandom(0, elite.height), angle: random(0, 359), failchance: 224);
		}

		if (elite.health < 1 || elite.tics <= 0)
			return;

		if (prevState != elite.curState)
			elite.A_SetTics(int(elite.tics * 1.75));
		prevState = elite.curState;
	}

	override string TintName() { return "rs_elite_c15"; }
	override color PentagramColor() { return Color(255, 156, 100, 63); }
}

// ---------------------------------------------------------------------
// C16 Silver -- magnetic: 1.25x health, heavy, bloodless, and a
// constant pull dragging players toward it, with field-ring visuals.
// Boost: much stronger pull. Player pull works through the
// RSEliteMagnet species set in RS_EliteHandler.PlayerEntered.
// ---------------------------------------------------------------------
class RS_EliteC16_Silver : RS_EliteColorController
{
	int radfactor;

	override bool HasAura() { return false; }

	override void InitEffect()
	{
		eftic = 1;
		elite.health = int(elite.health * 1.25);
		elite.mass *= 4;
		elite.bNOBLOOD = true;
		radfactor = -224;
	}

	override void BoostEffect()
	{
		radfactor = -384;
	}

	override void TickEffect()
	{
		elite.A_RadiusThrust(radfactor, 384, RTF_NOIMPACTDAMAGE | RTF_NOTMISSILE, species: 'RSEliteMagnet');

		if (level.time % 16 == 0)
			elite.A_SpawnItemEx("RS_EliteFX_Magnetism", flags: SXF_SETMASTER);
	}

	override string TintName() { return "rs_elite_c16"; }
	override color PentagramColor() { return Color(255, 208, 255, 255); }
}

// ---------------------------------------------------------------------
// C17 Gold -- the gilder: 5x health, near-painless, heavy, and an aura
// that converts ordinary monsters into gilded thralls. Boost: wider
// aura, harder conversion. Slower like Bronze; sparkles instead of an
// aura.
// ---------------------------------------------------------------------
class RS_EliteC17_Gold : RS_EliteColorController
{
	double radfactor;
	class<Inventory> midas;

	override bool HasAura() { return false; }

	override void InitEffect()
	{
		eftic = 1;
		elite.painchance = int(elite.painchance * 0.1);
		elite.health = int(elite.health * 5.0);
		elite.mass *= 12;
		elite.bNOBLOOD = true;
		radfactor = 3.0;
		midas = "RS_EliteFX_MidasTouch1";
	}

	override void BoostEffect()
	{
		radfactor = 5.0;
		midas = "RS_EliteFX_MidasTouch2";
	}

	override void TickEffect()
	{
		if (!random(0, 1))
		{
			elite.A_RadiusGive(midas, elite.radius * radfactor, RGF_MONSTERS);
			elite.A_SpawnItemEx("RS_EliteFX_Sparkle", xofs: elite.radius,
				zofs: frandom(0, elite.height), angle: random(0, 359), failchance: 224);
		}

		if (elite.health < 1 || elite.tics <= 0)
			return;

		if (prevState != elite.curState)
			elite.A_SetTics(int(elite.tics * 1.75));
		prevState = elite.curState;
	}

	override string TintName() { return "rs_elite_c17"; }
	override color PentagramColor() { return Color(255, 255, 238, 0); }
}
