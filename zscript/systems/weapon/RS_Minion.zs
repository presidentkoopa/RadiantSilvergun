// =====================================================================
// RS_Minion -- friendly monsters summoned BY A WEAPON, and the XP lane
// that follows them.
// ---------------------------------------------------------------------
// Owner ruling 2026-08-11, recorded in docs/rs_payload_bestiary.md:
//
//   "A summoned minion earns XP for the weapon that spawned it,
//    permanently, regardless of what the player is holding when the kill
//    lands. Multiple lanes running at once is INTENDED."
//
// So a player can seed a fight with two guns, switch to two others, and
// have four weapons levelling at once. That is a BUILD, not an exploit --
// a card slot and an ammo cost were paid for it, and it makes a summon
// affix worth taking on a gun the player has finished levelling.
//
// ---------------------------------------------------------------------
// WHY A TOKEN AND NOT A FIELD
//
// A minion is an ARBITRARY monster class off the bestiary -- an
// RS_CommonRevenant, an RS_GreenImp. We do not own those classes and
// cannot add fields to them, so the weapon pointer rides in an Inventory
// item instead. That is the same shape RS_SummonToken already uses to
// answer "did the map place this?", and the same shape RS_EliteToken uses
// to carry elite state, so it is the established way this project bolts
// state onto a monster it does not own.
//
// mSource is a Weapon, not a class name: two RS_Shotguns in one run are
// different objects with different XP, and the lane belongs to the
// INSTANCE that summoned it.
//
// ---------------------------------------------------------------------
// WHY THE OWNER POINTER IS SEPARATE FROM master
//
// A friendly monster's `master` is claimed by the engine's own
// friend/ownership handling -- A_PainShootSkull calls CopyFriendliness,
// and the friendly AI reads master for who it is fighting alongside. So
// the weapon cannot ride there without fighting the engine for the field.
// Projectiles get away with `proj.master = self` precisely because a
// projectile is not a friend of anybody.
// =====================================================================

class RS_MinionToken : Inventory
{
	// The weapon instance whose XP lane this minion feeds. Held for the
	// minion's whole life -- switching weapons must not redirect it, which
	// is the entire point of the ruling.
	Weapon  mSource;

	// The player who owns it. Cached rather than re-derived from
	// FriendPlayer at damage time, because FriendPlayer is 1-indexed and
	// getting that conversion wrong silently credits the wrong player in
	// co-op.
	PlayerPawn mOwner;

	Default
	{
		Inventory.MaxAmount 1;
		+INVENTORY.UNTOSSABLE
		+INVENTORY.UNDROPPABLE
		+INVENTORY.QUIET
	}
}

class RS_Minion
{
	// -----------------------------------------------------------------
	// THE ONE PLACE A PAYLOAD MINION IS BORN.
	//
	// Everything a friendly summon must get right happens here so no
	// caller has to remember it:
	//
	//   - FRIENDLY + FriendPlayer, which is what makes GunBonsai's
	//     GetPlayerDamageSource (gunbonsai/EventHandler.zsc:357) attribute
	//     the minion's damage to the player at all. Without it the damage
	//     event is discarded and no lane exists.
	//   - -COUNTKILL, because a friendly that dies is not a kill and a
	//     summon that counts breaks 100% runs. Note RS_CommonLSoul
	//     re-declares Monster and gets +COUNTKILL BACK
	//     (RS_LostSoul.zs:779), so clearing it here rather than trusting
	//     the class is not paranoia.
	//   - the weapon pointer, per the ruling above.
	//   - placement validation, because a minion inside a wall is worse
	//     than no minion.
	//
	// RS_SummonToken is NOT given here: RS_SummonMarker.WorldThingSpawned
	// hands it to anything spawned after maptime 0, which covers this for
	// free. That is what stops a minion paying score and Bits.
	//
	// Returns the minion, or null if it could not be placed.
	// -----------------------------------------------------------------
	// MUST be `play`. RS_Minion is a plain class, which is data scope, and
	// Actor.Spawn / GiveInventoryType are play functions -- calling them
	// from data scope is a load error ("Can't call play function Spawn
	// from data context"), and every later reference to the local then
	// cascades as "Unknown identifier". Same marking RS_PACKAssembly.Build
	// and .Install already carry. Every caller (GunBonsai's OnKill and
	// OnDamageDealt, on Object play upgrades) is already play context.
	static play Actor Summon(PlayerPawn owner, Weapon source, Class<Actor> what,
		Vector3 where, double angle = 0)
	{
		if (!owner || !what) return null;

		let mo = Actor.Spawn(what, where, ALLOW_REPLACE);
		if (!mo) return null;

		// PLACEMENT, CHECKED AFTER THE FACT. Actor.Spawn performs no
		// geometry test at all -- StaticSpawn will happily put a revenant
		// inside a pillar -- so the check has to happen here, and a
		// failure has to take the body away again rather than leave it
		// stuck. Same discipline RS_ReserveSquads uses for its
		// reinforcements, for the same reason.
		if (!mo.TestMobjLocation())
		{
			mo.ClearCounters();
			mo.Destroy();
			return null;
		}

		mo.angle = angle;

		// ORDER IS LOAD-BEARING AND WAS WRONG. ClearCounters() only
		// decrements level.total_monsters when CountsAsKill() is true,
		// and CountsAsKill() is (bCOUNTKILL && !bFRIENDLY). Setting
		// bFRIENDLY first therefore made ClearCounters a silent no-op:
		// every summoned minion stayed counted in the map total forever,
		// and a map with any minion raised could never reach 100% kills.
		//
		// So: decrement FIRST, while the monster still looks like a
		// monster to the engine, and only then change what it is.
		mo.ClearCounters();
		mo.bCOUNTKILL = false;

		// FRIENDLY, AND WHOSE. FriendPlayer is 1-INDEXED -- 0 means "no
		// player", so a 0-indexed value here would silently mean nobody
		// and the whole attribution path would go quiet.
		mo.bFRIENDLY = true;
		mo.FriendPlayer = owner.PlayerNumber() + 1;
		mo.master = owner;

		// It should already be looking for something to fight rather than
		// standing still waiting to be shot at.
		mo.bAMBUSH = false;

		let tok = RS_MinionToken(mo.GiveInventoryType("RS_MinionToken"));
		if (tok)
		{
			tok.mSource = source;
			tok.mOwner  = owner;
		}

		return mo;
	}

	// -----------------------------------------------------------------
	// WHICH WEAPON DOES THIS DAMAGE BELONG TO?
	//
	// Called from GunBonsai's WorldThingDamaged. Returns the summoning
	// weapon, or null if the damage did not come from one of ours -- in
	// which case the caller falls through to its ordinary mainhand and
	// offhand handling and nothing changes.
	//
	// Takes BOTH the inflictor and the damage source because a minion
	// hurts things two ways: melee, where the source IS the minion, and
	// a projectile it fired, where the source is the minion and the
	// inflictor is the round. Checking the source covers both.
	// -----------------------------------------------------------------
	static Weapon SourceWeaponFor(Actor inflictor, Actor damagesource)
	{
		let a = damagesource;

		// A projectile fired by a minion carries the minion as its target
		// (the engine's own "who shot this"), so if the source is not a
		// minion the round itself may still name one.
		if (!a || !a.FindInventory("RS_MinionToken"))
		{
			if (inflictor && inflictor.target
				&& inflictor.target.FindInventory("RS_MinionToken"))
			{
				a = inflictor.target;
			}
			else
			{
				return null;
			}
		}

		let tok = RS_MinionToken(a.FindInventory("RS_MinionToken"));
		if (!tok || !tok.mSource) return null;

		// The weapon can be destroyed out from under the minion -- sold,
		// replaced by a drop, or lost on a class change -- and a dangling
		// pointer here would credit XP into freed memory. A minion whose
		// gun is gone simply stops paying, which is the honest outcome.
		if (!tok.mSource.owner) return null;

		return tok.mSource;
	}

	// Is this actor one of ours? Cheap enough for a damage-time guard.
	static bool IsMinion(Actor a)
	{
		return a && a.FindInventory("RS_MinionToken") != null;
	}

	// -----------------------------------------------------------------
	// DID A MINION LAND THIS, rather than the player?
	//
	// The compounding guard on every summon card was written as
	// IsMinion(target) -- and in OnKill, `target` is the VICTIM. That
	// asks "did I just kill a minion", which is not the question and is
	// nearly never true. The question is "did a MINION get this kill",
	// because a minion's kill crediting a weapon that then raises
	// another minion is how two become four and a saturated fight never
	// stops growing.
	//
	// Same resolution SourceWeaponFor already does: the killer is either
	// the inflictor itself, or -- for a projectile -- whatever fired it.
	// -----------------------------------------------------------------
	static bool KilledByMinion(Actor inflictor, Actor damagesource)
	{
		if (IsMinion(damagesource)) return true;
		if (inflictor && IsMinion(inflictor)) return true;
		// A round in flight carries its shooter as `target`.
		if (inflictor && inflictor.target && IsMinion(inflictor.target)) return true;
		return false;
	}
}
