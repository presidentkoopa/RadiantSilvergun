// =====================================================================
// RS_Crits -- making the crit roll VISIBLE, and the monster half of it.
//
// WHAT THIS IS NOT: a second crit system. RS already rolls crits, and it
// has since long before this file -- RS_Weapon.zs holds CritChance and
// CritMult as rolled weapon stats, the dispatch in A_RS_FireSlot rolls
// them on every pull, and RS_CritStreak feeds Momentum off the result.
// That is the crit system and nothing here replaces any of it.
//
// The problem this fixes is that a crit was completely INVISIBLE. The
// roll happens at fire time, the multiplier is folded into the damage
// before the round even spawns, and then... a monster takes more damage.
// There is nothing to see, nothing to hear, and no way for a player to
// know a crit happened at all rather than the damage roll landing high.
// A reward nobody can perceive is not a reward.
//
// So: a round that rolled a crit is TINTED IN FLIGHT. You see it leave
// the barrel knowing it is going to hurt, and you watch it travel. That
// only works because this mod fires real projectiles rather than
// hitscans -- there is a thing in the air to look at, for long enough to
// register it. A hitscan mod could not do this at all.
//
// ---------------------------------------------------------------------
// THE OTHER HALF: MONSTERS CRITTING THE PLAYER.
//
// Built, wired, and SHIPPED OFF at the owner's explicit direction --
// "no monster crits on player tho, no no, or build it and disable it".
//
// It is off via rs_crit_monster_enable, which defaults to false, and
// with it off nothing in this file's monster half ever runs: the item is
// not even handed out. Turning it on is one toggle in the Crits menu.
//
// It exists rather than being left unwritten because the asymmetry is a
// real design lever, not an oversight -- "only the player crits" is a
// deliberate power fantasy, and being able to switch it off makes that a
// choice instead of an accident.
// =====================================================================

// `play`: Apply calls A_SetTranslation on the projectile, which is a
// play function. An unscoped class is DATA scope and cannot call into
// play -- that is the "Can't call play function ... from data context"
// error, and it is exactly what this tree already hit in
// rs_monster_utils.zs. RS_BitUtil and RS_HeadshotUtil carry the same
// keyword for the same reason.
class RS_CritMark play
{
	// -----------------------------------------------------------------
	// Tint a round that rolled a crit.
	//
	// Called from BOTH fire paths in RS_Weapon.zs (bullet and heavy), so
	// it lives here rather than there -- that file is shared by every
	// weapon in three sets and the smaller its diff, the better.
	//
	// The translation itself is `rs_crit_teal` in TRNSLATE.txt. Teal
	// because Doom's palette is overwhelmingly warm, so a cold cyan is
	// the one hue that cannot be confused with muzzle flash, fire, blood
	// or an explosion at any brightness.
	//
	// A_SetTranslation NO-OPS SILENTLY on a name that is not defined --
	// no error, no warning, no log line, the round simply flies untinted.
	// That exact failure is recorded at the top of TRNSLATE.txt, where a
	// previous port referenced translation names that were never defined
	// and every monster tier came out looking identical. The name below
	// is defined; do not rename one without the other.
	// -----------------------------------------------------------------
	static void Apply(Actor proj)
	{
		if (!proj)
			return;

		// THE TOKEN IS STAMPED UNCONDITIONALLY. It is STATE, not a
		// visual, so it must not be gated on the tint cvar -- turning
		// the teal off is a display preference and must not silently
		// change what a crit is worth.
		proj.GiveInventory("RS_CritRoundToken", 1);

		let cv = CVar.FindCVar("rs_crit_mark");
		if (!cv || !cv.GetInt())
			return;

		proj.A_SetTranslation("rs_crit_teal");
	}

	// -----------------------------------------------------------------
	// Did the round that caused this damage roll a crit?
	//
	// THE ROUND CARRIES ITS OWN ANSWER, and this is why the token above
	// exists at all. The obvious alternative -- reading
	// RS_Weapon.RS_ShotWasCrit at impact -- is a field on the GUN, and a
	// gun's field is about its LAST PULL, not about the round currently
	// landing.
	//
	// For bullets that distinction never shows: they are FastProjectiles
	// crossing a room in a tic or two, so the shot that fired them is
	// still the last one. It breaks on anything slow. Fire a rocket,
	// pull again before it lands, and the rocket's damage is attributed
	// to the second pull's crit roll -- which is wrong in both
	// directions and completely invisible, because the number that comes
	// off is a plausible number either way.
	//
	// An Inventory token rather than a field on the projectile class
	// because the arsenal has no single projectile base: bullets are
	// RS_BallisticFired, while the heavies inherit vanilla Rocket,
	// PlasmaBall and BFGBall directly and share no ancestor with them.
	// A token attaches to any Actor, so one mechanism covers all of it,
	// and it is only ever created on rounds that actually critted.
	// -----------------------------------------------------------------
	static bool RoundWasCrit(Actor inflictor)
	{
		return inflictor && inflictor.FindInventory("RS_CritRoundToken") != null;
	}
}

// The mark a crit round carries. No behaviour, no Tick, no states -- it
// is a flag with a class name, read once at impact.
class RS_CritRoundToken : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
	}
}

// =====================================================================
// MONSTER CRITS ON THE PLAYER -- built, off by default.
//
// Same shape as the headshot hook and for the same reason: ModifyDamage
// on an item the victim carries is the only in-engine hook that can
// change incoming damage on an arbitrary actor, and it is handed the
// inflictor and source directly.
//
// NO DoEffect AND NO TICK. What makes a per-actor item expensive is
// per-tic work, and this has none -- it is inert until the player is
// actually hurt, at which point ModifyDamage fires once. There is also
// only ever ONE of these in the level, on the player, so even that is
// not a per-monster cost.
// =====================================================================
class RS_PlayerCritTaker : Inventory
{
	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNDROPPABLE
		+INVENTORY.UNTOSSABLE
		+INVENTORY.QUIET
	}

	// Cached cvar HANDLES. The handle lookup is the string-keyed part and
	// is what costs; reading off a held handle is cheap and stays live,
	// so the menu keeps working immediately. Same pattern as
	// RS_HealthBars, and for the same reason.
	private CVar cvEnable, cvChance, cvMult, cvSound;

	private void CacheCVars()
	{
		if (!cvEnable) cvEnable = CVar.FindCVar("rs_crit_monster_enable");
		if (!cvChance) cvChance = CVar.FindCVar("rs_crit_monster_chance");
		if (!cvMult)   cvMult   = CVar.FindCVar("rs_crit_monster_mult");
		if (!cvSound)  cvSound  = CVar.FindCVar("rs_crit_monster_sound");
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage,
	                           bool passive, Actor inflictor, Actor source, int flags)
	{
		// `passive` means WE are being hurt. The active pass is the
		// player hurting something else, which the weapon's own roll
		// already owns.
		if (!passive || damage <= 0)
			return;

		CacheCVars();

		// THE MASTER SWITCH, and it is the first thing tested. Off means
		// off: no roll, no sound, no cost.
		if (!cvEnable || !cvEnable.GetInt())
			return;

		// A monster has to be doing it. Falling damage, crushers, lava
		// and our own backfire are not attacks and must never crit.
		if (!source || !source.bISMONSTER || source.player)
			return;

		// Never crit a hit that is already ours -- the weapon's own
		// backfire damage arrives with the player as source, and any
		// recursion here would compound.
		if (damageType == 'BackfireDamage' || damageType == 'RS_Headshot')
			return;

		double chance = cvChance ? cvChance.GetFloat() : 0.05;
		if (chance <= 0 || FRandom(0, 1) >= chance)
			return;

		double mult = cvMult ? cvMult.GetFloat() : 2.0;
		if (mult <= 1.0)
			return;

		newdamage = max(1, int(damage * mult));

		// A crit taken has to be AUDIBLE and distinct, or it reads as
		// the game randomly spiking damage. This is the one case where
		// the player cannot see the marked round coming -- monster
		// projectiles are not tinted, because the tell belongs to the
		// player's own shots.
		if (cvSound && cvSound.GetInt() && owner)
			owner.A_StartSound("rs_crit_taken", CHAN_AUTO, CHANF_OVERLAP, 1.0, ATTN_NONE);
	}
}

// =====================================================================
// Hands the taker to the player. One event per spawn and nothing else --
// there is no tick anywhere in this file.
// =====================================================================
class RS_CritHandler : EventHandler
{
	private void GiveTaker(PlayerPawn p)
	{
		// Handed out unconditionally rather than gated on the cvar, so
		// that switching monster crits on mid-game takes effect at once
		// instead of waiting for a respawn. The item itself checks the
		// switch and costs nothing while it is off.
		if (p) p.GiveInventory("RS_PlayerCritTaker", 1);
	}

	override void PlayerEntered(PlayerEvent e)
	{
		GiveTaker(players[e.PlayerNumber].mo);
	}

	override void PlayerRespawned(PlayerEvent e)
	{
		GiveTaker(players[e.PlayerNumber].mo);
	}
}
