// =====================================================================
// RS_Grenade -- hold to charge, release to throw.
// ---------------------------------------------------------------------
// From the UAC Survival Pack's jGrenade. The source needed 22 classes
// and an ACS library to do this; it needs neither.
//
// WHY THE SOURCE IS SHAPED THE WAY IT IS: DECORATE cannot set a
// projectile's speed at fire time. So the author pre-built eleven weapons
// (J_HandGrenade0..10), each firing one of eleven pre-built projectiles
// (J_ThrownGrenade1..10, Speed 10..60), and wrote ACS that polled the
// key, bucketed the charge into a tier, hot-swapped your weapon to that
// tier's grenade, let its Ready state auto-throw, then swapped your real
// gun back. The tell that it is a workaround and not a design: the
// buckets run to `>100 && <=110 -> tier 10`, and charge caps at 100, so
// the eleventh grenade can never be thrown. It is unreachable code.
//
// ZScript sets the velocity. One weapon, one projectile, charge as a
// continuous fraction -- so the throw has infinite strengths instead of
// eleven, and nothing ever touches your hands.
//
// THE GUN STAYS DEPLOYED. This is an RS_Weapon so it lives in the
// arsenal properly (it owns the ammo, the stats, the tag), but it is
// NEVER made ReadyWeapon. The charge is read in PlayerThink and the
// throw spawns the projectile directly from the chosen hand's pose.
// Whatever you are holding stays up the whole time.
//
// NO ROLL, NO AFFIXES -- BUT NOT SPECIAL-CASED. RollStats stamps fixed
// numbers, and GunBonaiSockets is 0. Zero sockets already gates every
// slate affix (TFLV_Upgrade_RS_SlateBase.CanTake -> HasSockets), so
// affixes are off by construction. Turning them on later is changing
// one number, not rewriting anything.
// =====================================================================

// ---------------------------------------------------------------------
// The thrown object.
// ---------------------------------------------------------------------
class RS_GrenadeThrown : Actor
{
	// Throw speed at 0% and 100% charge. The source's eleven tiers ran
	// 10..60; this is the same range, continuous.
	const SPEED_MIN = 10.0;
	const SPEED_MAX = 60.0;

	// Fuse once thrown, in tics.
	const FUSE_TICS = 70;

	// Tumble, degrees per tic. Not a neat ratio, so the spin never looks
	// like it is on a metronome.
	const SPIN_ROLL  = 13.0;
	const SPIN_PITCH = 7.0;

	Default
	{
		Projectile;
		Radius 5;
		Height 3;
		Speed 26;
		Damage 1;                  // the blast is A_Explode, not the impact
		DamageType "Explosive";
		Scale 0.3;
		Mass 5;

		// THE ARC. Not NOGRAVITY, so it falls while it travels.
		-NOGRAVITY
		Gravity 0.7;

		// THE BOUNCE. Cleared at spawn when rs_grenade_impact is on.
		BounceType "Doom";
		BounceFactor 0.3;
		WallBounceFactor 0.2;
		BounceSound "rs_gren/bounce";
		+BOUNCEONFLOORS
		+BOUNCEONWALLS
		+BOUNCEONCEILINGS
		+CANBOUNCEWATER
		-BOUNCEONACTORS

		+MOVEWITHSECTOR
		-NOTELEPORT
		SeeSound "";
		DeathSound "";
		Obituary "$OB_RS_GRENADE";
	}

	int  mFuse;
	bool mImpact;       // detonate on first contact instead of bouncing

	// Set by the thrower before the projectile is released.
	void Launch(Vector3 dir, double charge, int fuseLeft)
	{
		double spd = SPEED_MIN + clamp(charge, 0.0, 1.0) * (SPEED_MAX - SPEED_MIN);
		vel = dir * spd;

		// A cooked grenade arrives with its fuse already part-burned --
		// that is the whole point of cooking.
		mFuse = fuseLeft > 0 ? fuseLeft : FUSE_TICS;
	}

	// Fuse length, cvar-driven. FUSE_TICS is the source's 70 and the
	// fallback when the cvar is missing.
	static int FuseLen()
	{
		let cv = CVar.FindCVar("rs_grenade_fuse");
		return cv ? clamp(cv.GetInt(), 5, 350) : FUSE_TICS;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		if (mFuse <= 0) mFuse = FuseLen();

		// Start the tumble somewhere random so two grenades thrown back
		// to back are not in lockstep.
		roll  = random(0, 359);
		pitch = random(0, 359);

		// IMPACT MODE. Same projectile -- it just stops bouncing, so the
		// first thing it touches ends it.
		let cv = CVar.FindCVar("rs_grenade_impact");
		mImpact = cv && cv.GetBool();
		if (mImpact)
		{
			bBounceOnFloors   = false;
			bBounceOnWalls    = false;
			bBounceOnCeilings = false;
		}
	}

	override void Tick()
	{
		Super.Tick();
		if (bDestroyed || IsFrozen()) return;

		// THE ROTATION. The model tumbles; a sprite-frame cycle (what the
		// source used) does nothing to a model.
		roll  += SPIN_ROLL;
		pitch += SPIN_PITCH;

		if (mFuse > 0 && --mFuse <= 0)
			SetStateLabel("Death");
	}

	// Hitting something alive always ends it, bounce mode or not.
	override int SpecialMissileHit(Actor victim)
	{
		if (victim && victim.bShootable && victim != target)
		{
			SetStateLabel("Death");
			return 0;
		}
		return -1;
	}

	States
	{
	Spawn:
		// One frame. MODELDEF maps every JGRN frame to the same model
		// pose and the tumble comes from Tick(); the sprite is only the
		// fallback when models are off.
		JGRN A 4;
		Loop;

	Death:
		TNT1 A 0 A_NoBlocking;
		TNT1 A 0 A_AlertMonsters;
		TNT1 A 0 A_StartSound("rs_gren/explode", CHAN_AUTO);
		TNT1 A 0 A_StartSound("rs_gren/farexpl", CHAN_7);
		// The source's own detonation visuals, 1:1 -- see
		// zscript/weapons/weaponfx/RS_FX_Blast.zs.
		TNT1 A 0 A_SpawnItemEx("RS_Blast", 0, 0, 0, 0, 0, 0, 0,
			SXF_NOCHECKPOSITION);
		// The damage stays HERE, at the source's own numbers, because
		// A_Explode credits the calling actor's target as the killer.
		// Fired from the effect actor instead, the player would lose the
		// kill entirely -- obituary, score, Bits and XP all.
		TNT1 A 1 A_Explode(85, 200, 1);
		TNT1 A 1 A_Explode(75, 255, 1);
		Stop;
	}
}

// ---------------------------------------------------------------------
// The weapon. Owns the ammo and the numbers; never enters your hands.
// ---------------------------------------------------------------------
class RS_Grenade : RS_Weapon
{
	Default
	{
		Tag "$TAG_RS_GRENADE";
		Inventory.PickupMessage "$PICKUP_RS_GRENADE";
		Weapon.SelectionOrder 32767;     // last resort, effectively never
		Weapon.AmmoType1 "RS_GrenadeAmmo";
		Weapon.AmmoUse 1;
		Weapon.AmmoGive 2;
		Weapon.SlotNumber 0;             // no slot -- it is thrown, not wielded
		+WEAPON.NO_AUTO_SWITCH
		+WEAPON.NOAUTOAIM
		+NOALERT
		Scale 0.5;
	}

	// FIXED, NOT ROLLED. A grenade is the same grenade every time.
	// Marking bStatsRolled keeps AttachToOwner/PostBeginPlay's guards
	// satisfied without ever producing a Cursed or Prototype grenade.
	override void RollStats(EVR_Tier t)
	{
		Tier            = VRT_Basic;
		DamagePerShot   = 90;
		PelletCount     = 1;
		Accuracy        = 100;
		Velocity        = 26;
		CritChance      = 0.0;
		CritMult        = 1.0;
		Capacity        = 0;
		Condition       = 100;
		ReloadSpeed     = 1.0;
		GunBonaiSockets = 0;    // <- the affix gate. Raise to enable them.
		bStatsRolled    = true;
	}

	// Thrown by hand: no barrel, no muzzle, no beat. The throw is done by
	// RS_GrenadeThrower, not by the firing dispatch.
	override void BuildAttackProfiles() {}

	override string GetBaseKeywords()
	{
		return "archetype:launcher payload:explosive hand:thrown";
	}

	States
	{
	Spawn:
		JGND D -1;
		Stop;
	Ready:
		JHND A 1 A_WeaponReady;
		Loop;
	Select:
		JHND A 1 A_Raise;
		Loop;
	Deselect:
		JHND A 1 A_Lower;
		Loop;
	Fire:
		Goto Ready;
	}
}

class RS_GrenadeAmmo : Ammo
{
	Default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 8;
		Ammo.BackpackAmount 2;
		Ammo.BackpackMaxAmount 16;
		Inventory.Icon "JGNDD0";
		Inventory.PickupMessage "$PICKUP_RS_GRENADEAMMO";
		Tag "$AMMO_RS_GRENADE";
	}

	// Carry cap from rs_grenade_max. MaxAmount is a Default property, so
	// it has to be re-stamped on the live item rather than declared --
	// and on the BACKPACK item too, or a backpack silently reverts the
	// cap to the Default block's 16.
	override void AttachToOwner(Actor other)
	{
		Super.AttachToOwner(other);
		ApplyCap();
	}

	override bool HandlePickup(Inventory item)
	{
		ApplyCap();
		return Super.HandlePickup(item);
	}

	void ApplyCap()
	{
		let cv = CVar.FindCVar("rs_grenade_max");
		if (!cv) return;
		int cap = clamp(cv.GetInt(), 1, 99);
		MaxAmount = cap;
		BackpackMaxAmount = cap * 2;
		if (Amount > MaxAmount) Amount = MaxAmount;
	}
}

// =====================================================================
// RS_GrenadeThrower -- the charge, the cook, and the throw.
//
// Driven from VR_DualClassBase.PlayerThink, which is the same hook
// RS_PanelInput uses and for the same reason: it runs BEFORE the weapon
// thinks, so reading the button here cannot fight your gun.
//
// This is a plain state holder rather than an EventHandler because
// WorldTick runs AFTER the player has already thought -- the exact
// ordering mistake that made RS_WheelPoC's input capture a no-op.
// =====================================================================
class RS_GrenadeThrower : Object
{
	// Tics to a full-strength throw. The source's number is 20 (+5/tic
	// to a cap of 100) and that is the default; the cvar lets it be
	// tuned without touching code.
	static int ChargeTics()
	{
		let cv = CVar.FindCVar("rs_grenade_charge");
		return cv ? clamp(cv.GetInt(), 4, 140) : 20;
	}

	static bool CookEnabled()
	{
		let cv = CVar.FindCVar("rs_grenade_cook");
		return !cv || cv.GetBool();
	}

	// COOKING. Holding PAST full charge starts burning the fuse early,
	// so the grenade can air-burst instead of landing and rolling. The
	// source never did this -- it is the one addition that turns a
	// distance dial into a skill.
	//
	// Cook budget IS the fuse: burn it all and it goes off in your hand,
	// which is supposed to happen.
	static int CookMax() { return RS_GrenadeThrown.FuseLen(); }

	int  mCharge;      // 0..CHARGE_TICS
	int  mCook;        // tics cooked past full charge
	bool mHeld;        // button state last tic, for edge detection

	// Read the throw button. GZDoom's user buttons are free for mods;
	// BT_USER4 is what the source used and KEYCONF binds it.
	static bool ButtonDown(PlayerPawn pawn)
	{
		return pawn && pawn.player
		    && (pawn.player.original_cmd.buttons & BT_USER4);
	}

	// Called once per tic from PlayerThink.
	void Update(PlayerPawn pawn)
	{
		if (!pawn || !pawn.player) return;

		bool down = ButtonDown(pawn);
		let wep   = RS_Grenade(pawn.FindInventory("RS_Grenade"));
		bool have = wep && pawn.CountInv("RS_GrenadeAmmo") > 0;

		if (down && have)
		{
			int chargeMax = ChargeTics();
			if (mCharge < chargeMax)
				mCharge++;
			else if (CookEnabled() && mCook < CookMax())
			{
				mCook++;
				// Cooked all the way. It goes off in your hand -- which
				// is the risk the mechanic is made of.
				if (mCook >= CookMax())
				{
					Detonate(pawn);
					Reset();
					mHeld = down;
					return;
				}
			}
		}
		else if (mHeld && mCharge > 0)
		{
			// RELEASE -> throw at whatever fraction was charged.
			Throw(pawn, double(mCharge) / double(ChargeTics()), mCook);
			Reset();
		}
		else if (!down)
		{
			Reset();
		}

		mHeld = down;
	}

	void Reset() { mCharge = 0; mCook = 0; }

	// Charge as 0..1, for the HUD.
	double ChargeFraction() const
	{
		int m = ChargeTics();
		return m > 0 ? double(mCharge) / double(m) : 0.0;
	}
	double CookFraction() const
	{
		int m = CookMax();
		return m > 0 ? double(mCook) / double(m) : 0.0;
	}
	bool Active() const { return mCharge > 0; }

	// Which hand it leaves from. Default offhand -- that is the one more
	// likely to be holding a fist. Your deployed gun is never touched
	// either way.
	static Vector3, double, double HandPose(PlayerPawn pawn)
	{
		let cv = CVar.FindCVar("rs_grenade_hand");
		bool useOff = !cv || cv.GetInt() != 1;   // 1 = mainhand

		if (useOff && pawn.OffhandPos != (0, 0, 0))
			return pawn.OffhandPos, pawn.OffhandAngle, pawn.OffhandPitch;
		return pawn.AttackPos, pawn.AttackAngle, pawn.AttackPitch;
	}

	void Throw(PlayerPawn pawn, double charge, int cooked)
	{
		if (pawn.CountInv("RS_GrenadeAmmo") <= 0) return;

		Vector3 origin; double ang, pit;
		[origin, ang, pit] = HandPose(pawn);

		// Positive pitch looks DOWN in Doom, hence the negated Z.
		Vector3 dir = (cos(ang) * cos(pit), sin(ang) * cos(pit), -sin(pit));

		let g = RS_GrenadeThrown(Actor.Spawn("RS_GrenadeThrown", origin));
		if (!g) return;

		g.target = pawn;
		g.master = pawn;
		g.angle  = ang;
		g.Launch(dir, charge, RS_GrenadeThrown.FuseLen() - cooked);

		pawn.TakeInventory("RS_GrenadeAmmo", 1);
		pawn.A_StartSound("rs_gren/toss", CHAN_WEAPON);
	}

	// Cooked too long. No throw, no ammo refund -- it just goes off.
	void Detonate(PlayerPawn pawn)
	{
		if (pawn.CountInv("RS_GrenadeAmmo") <= 0) return;
		pawn.TakeInventory("RS_GrenadeAmmo", 1);

		let g = RS_GrenadeThrown(Actor.Spawn("RS_GrenadeThrown", pawn.pos + (0, 0, 32)));
		if (!g) return;
		g.target = pawn;
		g.master = pawn;
		g.mFuse  = 1;
	}
}

// =====================================================================
// RS_GrenadeHUD -- the charge readout.
// ---------------------------------------------------------------------
// TWO STYLES, and the ORIGINAL IS THE DEFAULT.
//
// I built the bar first and ignored the source's own readout, which was
// wrong twice over: the source HAS a UI for this, and it is the one the
// owner already knows. It is reconstructed here from GRENADE.ACS's
// HudMessage calls -- same 730x560 hud space, same coordinates, same
// three elements:
//
//     "Strength"   smallfont, 562 x 435, alpha 0.65
//     "<n>%"       smallfont, 562 x 444, alpha 0.65
//     "J"          gold,      693 x 430
//     "<count>"    red,       694 x 450
//     grenade icon red,       700 x 450   -- ACS did SetFont("JGNDD0")
//                                            and drew the character "A",
//                                            i.e. the sprite AS a font.
//                                            We draw the graphic directly,
//                                            which is the same picture by
//                                            a less baroque route.
//
// The source's colour was "SaeHUDGr", defined in that pack's TEXTCOLO
// and not ours; RSScore_White is the nearest thing we ship.
//
// rs_grenade_meter: 0 Off, 1 Original (default), 2 Bar.
// =====================================================================
class RS_GrenadeHUD : EventHandler
{
	// The source's HUD space. Every coordinate below is in these units.
	const HUD_W = 730;
	const HUD_H = 560;

	override void RenderOverlay(RenderEvent e)
	{
		int style = 1;
		let cv = CVar.GetCVar("rs_grenade_meter", players[consoleplayer]);
		if (cv) style = cv.GetInt();
		if (style <= 0) return;

		let pawn = VR_DualClassBase(players[consoleplayer].mo);
		if (!pawn || !pawn.mGrenade) return;

		int count = pawn.CountInv("RS_GrenadeAmmo");
		let g = pawn.mGrenade;

		if (style == 2) { DrawBar(g); return; }

		// --- THE ORIGINAL LAYOUT ------------------------------------
		// The strength readout only appears while the key is held, which
		// is what the ACS did: its HudMessage lived inside the
		// button-down branch of the loop.
		if (g.Active())
		{
			double frac = g.ChargeFraction();
			int pct = int(frac * 100);

			// Cooking pushes past 100 and turns red, which the source had
			// no concept of -- it could not cook. Kept in the original's
			// own visual language rather than adding a second widget.
			int col = Font.CR_WHITE;
			string pctText;
			if (g.CookFraction() > 0)
			{
				col = Font.CR_RED;
				pctText = string.format("%d%%  COOK", int(g.CookFraction() * 100));
			}
			else pctText = string.format("%d%%", pct);

			Screen.DrawText(SmallFont, col, 562, 435, "Strength",
				DTA_VirtualWidth, HUD_W, DTA_VirtualHeight, HUD_H,
				DTA_Alpha, 0.65);
			Screen.DrawText(SmallFont, col, 562, 444, pctText,
				DTA_VirtualWidth, HUD_W, DTA_VirtualHeight, HUD_H,
				DTA_Alpha, 0.65);
		}

		// --- THE COUNTER. Always on while you carry any, exactly as the
		// source did (its own check was CheckInventory > 0).
		// NO "J" LABEL. The source drew a gold "J" above the count --
		// that is the jGrenade's own branding and it means nothing here.
		// The icon and the number say everything the letter did.
		if (count > 0)
		{
			Screen.DrawText(SmallFont, Font.CR_RED, 694, 450,
				string.format("%d", count),
				DTA_VirtualWidth, HUD_W, DTA_VirtualHeight, HUD_H);

			TextureID icon = TexMan.CheckForTexture("JGNDD0", TexMan.Type_Any);
			if (icon.IsValid())
				Screen.DrawTexture(icon, true, 706, 450,
					DTA_VirtualWidth, HUD_W, DTA_VirtualHeight, HUD_H,
					DTA_CenterOffset, true);
		}
	}

	// --- STYLE 2: the bar. Mine, kept as the alternative. -----------
	void DrawBar(RS_GrenadeThrower g)
	{
		if (!g.Active()) return;

		double charge = g.ChargeFraction();
		double cook   = g.CookFraction();

		int vw = 320, vh = 200;
		int w = 96, h = 6;
		int x = (vw - w) / 2;
		int y = vh - 44;

		Screen.Dim(Color(255, 10, 8, 6), 0.65, x - 2, y - 2, w + 4, h + 4,
			DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);

		int fill = int(w * clamp(charge, 0.0, 1.0));
		if (fill > 0)
			Screen.Dim(Color(255, 230, 200, 90), 0.95, x, y, fill, h,
				DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);

		if (cook > 0)
		{
			int burn = int(w * clamp(cook, 0.0, 1.0));
			if (burn > 0)
				Screen.Dim(Color(255, 220, 60, 40), 0.95, x, y, burn, h,
					DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);
		}

		string label = (cook > 0)
			? string.format("COOKING  %d%%", int(cook * 100))
			: string.format("THROW  %d%%",   int(charge * 100));
		int col = (cook > 0) ? Font.CR_RED : Font.CR_GOLD;

		Screen.DrawText(SmallFont, col,
			x + (w - SmallFont.StringWidth(label)) / 2, y - 12, label,
			DTA_VirtualWidth, vw, DTA_VirtualHeight, vh);
	}
}
