# RS FX CATALOG â€” DELIVERABLE

Verified against the tree at `E:/RS_Main` on 2026-08-11. Every count below was re-measured, not carried over. Where my number differs from the census I was handed, mine is stated and the discrepancy is named.

---

## 1. WHAT THE MOD ACTUALLY OWNS

**Conclusion: the mod holds 1,170 FX classes. PACK reaches four of nine axes and, on the eight axes that are not PROJECTILE, it reaches at most two options. The monster tree holds 7.5x the FX content of the weapon tree, and none of it is addressable.**

Re-measured class counts:

| Tree | Files | Classes |
|---|---|---|
| Monster FX (`zscript/monsters/**/RS_*FX.zs`) | 18 | **1,033** |
| Weapon FX (`zscript/weapons/weaponfx/`) | â€” | **137** |
| **FX total** | | **1,170** |
| Whole monster tree (all `.zs`) | | 1,569 |

The census said 995 monster FX classes across 17 files. It is 1,033 across 18 â€” `zscript/monsters/RS_EliteFX.zs` (38 classes) sits at the tree root rather than in a monster folder and was missed. That file turns out to matter more than any other for Section 4.

Per axis, what is reachable **today**:

| # | Axis | Registry entries | PACK writes it? | What PACK actually draws from |
|---|---|---|---|---|
| 0 | PROJECTILE | 3 | yes | 409-class monster pool, `RS_PACKCatalog.zs:64-550` |
| 1 | CASING | **0** | yes | `RS_FamilyPalette.BulletCasings`, `RS_FamilyPalette.zs:64-76` â€” **1 option, or 0** for launcher/energy/bfg/flamethrower/melee |
| 2 | MUZZLE | **0** | no â€” hardcoded `false`, `RS_PACKAssembly.zs:202` | nothing. There is no muzzle-flash *class* field anywhere in the mod; axis 2 is `bool BigMuzzle`, `RS_AttackProfile.zs:134` |
| 3 | SMOKE | 1 | **no** â€” not passed | falls to `GunMuzzleSmoke`, `RS_Weapon.zs:903-910` |
| 4 | SOUND | **0** | yes, as `ExtraFireSound` | `DrawFireSound`, `RS_PACKCatalog.zs:561-572` â€” 8 themes â†’ **6 distinct strings** |
| 5 | PUFF | 14 | yes | `RS_FamilyPalette.BulletPuffs`, `:49-60` â€” **1 option**, 2 at Tier â‰¥ Advanced |
| 6 | SPARKS | 8 | **no** â€” not passed | gun's own |
| 7 | TRAIL | 13 | **no** â€” not passed | gun's own |
| 8 | PAYLOAD | 4 | **impossible** | no field on `RS_AttackProfile` or `RS_Weapon`. Four entries claim it and nothing can read them |

Verified at `RS_PACKAssembly.zs:145-221`: `Build` fills exactly PROJECTILE, CASING, PUFF and the layered sound. `false` at line 202 is muzzle; smoke, sparks and trail are simply absent from the `MakeBullet` call and default null.

Two corrections to the brief:

- **The 4/5/3/2/3 passthrough pools do not exist as live code.** `PuffAt`/`SparkAt`/`TrailAt`/`SmokeAt`/`CasingAt` at `RS_PACKCatalog.zs:579-635` have zero callers repo-wide, as does `ApplyTheme` at `:673-682`. The real per-axis reach is worse than the brief assumed, not better.
- **The registry holds 36 entries, not 37** (`RS_FXRegistry.zs:137-179`). All 36 class names resolve.

The theme roll is uniform over allowed non-empty themes (`RollTheme`, `RS_PACKAssembly.zs:117-131`), so on a ballistic gun a LIGHTNING class (2 members) is **68x** likelier per-class than a FIRE one (137 members). Flagging, not recommending â€” it may be deliberate variety-forcing.

---

## 2. REGISTRY ENTRIES, READY TO PASTE

### 2a. The struct change â€” do this first

Two trailing-defaulted fields and two trailing-defaulted params. All 36 existing `Add()` lines compile untouched.

In `RS_FXEntry`, `RS_FXRegistry.zs:49-68`:

```zscript
class RS_FXEntry : Object
{
	Class<Actor> Cls;
	string       Id;          // short human label, for the gallery
	string       Handle;      // STABLE, [a-z0-9_], what an affix types
	int          Themes;      // bitmask of 1 << MTHEME_*
	int          Axes;        // bitmask of 1 << RS_FXAXIS_*
	int          Roles;       // bitmask of 1 << RS_FXROLE_*. 0 = UNCLASSIFIED,
	                          // which is NOT "any" -- see FitsRole.

	static RS_FXEntry Make(Class<Actor> cls, string id, int themes, int axes,
		string handle = "", int roles = 0)
	{
		let e = RS_FXEntry(new("RS_FXEntry"));
		e.Cls = cls;
		e.Id = id;
		e.Themes = themes;
		e.Axes = axes;
		e.Handle = handle;
		e.Roles = roles;
		return e;
	}

	bool FitsAxis(int axis) const   { return (Axes & (1 << axis)) != 0; }
	bool FitsTheme(int theme) const { return (Themes & (1 << theme)) != 0; }

	// Roles == 0 fails EVERY role test. An untagged plume must never leak
	// into a constrained pistol-muzzle query just because nobody sized it
	// yet -- that is the exact failure the role field exists to prevent.
	bool FitsRole(int role) const   { return (Roles & (1 << role)) != 0; }
}
```

Role constants, beside `RS_FXAXIS_*` at `RS_FXRegistry.zs:77-86`:

```zscript
	// SIZE CLASS -- decidable from Default Scale plus any A_SetScale the
	// class applies to itself. Three bands, and a class that ramps across
	// them sets several bits (RS_DeepCharge1 runs 1.5 -> 0.3 in 18 tics).
	const RS_FXROLE_ACCENT   = 0;   // draws at <= 0.5
	const RS_FXROLE_BODY     = 1;   // 0.5 < scale <= 1.5
	const RS_FXROLE_HEADLINE = 2;   // > 1.5

	// BEHAVIOUR -- equally decidable, and both bits are safety rails
	// rather than taste. Set them and a query can exclude them.
	const RS_FXROLE_HOSTILE  = 3;   // damages, or hands an Inventory to
	                                // MONSTERS. RS_DarkFlameTrailVile's
	                                // only gameplay effect is buffing and
	                                // resurrecting enemies.
	const RS_FXROLE_SPAWNER  = 4;   // its own states spawn further actors.
	                                // RS_SplashAbyssVile2's Death spawns a
	                                // 112-tall Monster with a melee attack.
	const RS_FXROLE_COUNT    = 5;

	static string RoleName(int r)
	{
		if (r == RS_FXROLE_ACCENT)   return "ACCENT";
		if (r == RS_FXROLE_BODY)     return "BODY";
		if (r == RS_FXROLE_HEADLINE) return "HEADLINE";
		if (r == RS_FXROLE_HOSTILE)  return "HOSTILE";
		if (r == RS_FXROLE_SPAWNER)  return "SPAWNER";
		return "?";
	}
```

`Add`, `RS_FXRegistry.zs:186-192`:

```zscript
	private static void Add(out Array<RS_FXEntry> outv, string cls, string id,
		int themes, int axes, string handle = "", int roles = 0)
	{
		Class<Actor> c = cls;
		if (c)
			outv.Push(RS_FXEntry.Make(c, id, themes, axes, handle, roles));
	}
```

`Query` and `Draw` get a trailing `int role = -1`; `role < 0` means do not filter, which keeps `RS_FXGallery.zs:191` and every current call site working unchanged. And the lookup affixes need:

```zscript
	// Linear scan. 36-to-N entries, called at affix-install time, not hot.
	static RS_FXEntry ByHandle(string h)
	{
		if (!h.Length()) return null;
		Array<RS_FXEntry> all;  All(all);
		for (int i = 0; i < all.Size(); i++)
			if (all[i].Handle == h) return all[i];
		return null;
	}
```

**Handle uniqueness cannot be enforced at compile time and fails worse than a bad class name.** `Add` at `:189` silently drops an unresolvable class, but the gallery makes that absence visible; a duplicate or typo'd handle makes `ByHandle` return null with no surface at all. Add a duplicate-handle printer to `RS_FXGalleryHandler` â€” the gallery is already the debug surface.

`Id` cannot double as the handle: it is consumed only as the pedestal caption (`RS_FXGallery.zs:243`, `:249`) and existing Ids contain spaces and `(default)` suffixes.

### 2b. Entries

**Missing alias.** The local aliases inside `All()` (`RS_FXRegistry.zs:127-132`) cover only PUFF, SPARKS, TRAIL, SMOKE, PAYLOAD, PROJECTILE. Casing entries need this line added beside them or the file will not compile:

```zscript
		int A_CASING = 1 << RS_FXAXIS_CASING;
```

Role shorthand used below, declare alongside:

```zscript
		int R_ACC = 1 << RS_FXROLE_ACCENT;
		int R_BOD = 1 << RS_FXROLE_BODY;
		int R_HED = 1 << RS_FXROLE_HEADLINE;
		int R_HOS = 1 << RS_FXROLE_HOSTILE;
		int R_SPW = 1 << RS_FXROLE_SPAWNER;
```

---

```zscript
		// =============================================================
		// AXIS 1 -- CASING. Was EMPTY. These are its first entries.
		// The three RS_Casing* are already live through
		// RS_HiFiFX.CasingEject (RS_FX_HiFiFX.zs:67-75), which applies
		// xoff/zoff and FRandom velocity at the spawn -- so the shape is
		// spawn-site evidenced, not Default-block guessed. HIGH.
		// RS_MagDrop is a real drawable nobody spawns. MEDIUM.
		// =============================================================
		Add(outv, "RS_CasingSmall",  "casing small",   T_IMP, A_CASING, "casing_small",  R_ACC);
		Add(outv, "RS_CasingRifle",  "casing rifle",   T_IMP, A_CASING, "casing_rifle",  R_ACC);
		Add(outv, "RS_CasingShell",  "casing shell",   T_IMP, A_CASING, "casing_shell",  R_BOD);
		Add(outv, "RS_MagDrop",      "magazine drop",  T_IMP, A_CASING, "magdrop",       R_BOD);

		// =============================================================
		// AXIS 3 -- SMOKE. The axis PACK never writes and the one the
		// owner's "muzzlesmoke3" handle actually lands on
		// (RS_Weapon.zs:903-910 hands p.MuzzleSmoke to MuzzleEffects).
		//
		// READ THIS BEFORE TAGGING ANY SMOKE ENTRY:
		// RS_FX_HiFiFX.zs:57-63 spawns smokeClass then calls SetupVisual
		// ONLY if the result casts to RS_SmokeWisp. Every non-wisp smoke
		// override draws at its own Default block with no override at
		// all. The numbers below are therefore what the gun will draw.
		// =============================================================
		// HIGH -- read in full at RS_FX_Blast.zs:179-198. Translucent,
		// not additive: the only large non-glowing smoke in the weapon
		// tree. Scale 1.4 / Alpha 0.12, JSMO A held 40 tics then 41
		// frames at 2 tics fading 0.002 -- ~122 tics of hanging bloom.
		// Its parent RS_BlastSmoke IS spawned (RS_FX_Blast.zs:312, :414);
		// the heavy variant is not. Free content, correctly sized.
		Add(outv, "RS_BlastSmokeHeavy", "blast smoke heavy", 0, A_SMOKE, "smoke_heavy", R_BOD);
		Add(outv, "RS_BlastSmoke",      "blast smoke",       0, A_SMOKE, "smoke_blast", R_BOD);
		// HIGH -- RS_FX_Blast.zs:200-237. Scale (1.4,1.0), 8x JS17 ABCD
		// at 5 tics = ~170 tics. A rising column, not a puff.
		Add(outv, "RS_BlastSmokeColumn","blast smoke column",0, A_SMOKE, "smoke_column",R_HED);
		// HIGH on SMOKE and TRAIL, MEDIUM on PUFF (no impact-site spawn
		// exists). RS_BaronFX.zs:190-228. Speed 0, +FLOATBOB, no damage,
		// Scale 0.5, and it ships FOUR silhouettes from one handle via
		// A_Jump(255,...) at :209 -- A_SetScale(0.7,0.25) at :214 is a
		// flat smear, (0.3,0.6) at :218 a tall wisp. Eleven live spawn
		// sites across baron, archvile and revenant.
		Add(outv, "RS_BrownVileGas",    "brown vile gas",    0, A_SMOKE | A_TRAIL | A_PUFF, "gas_brown", R_ACC | R_BOD);
		// HIGH -- RS_BaronFX.zs:478-512, read in full. Projectile with
		// NO Damage property, +FLOORHUGGER, Alpha 0.75, and it swells
		// from XScale 0.85/YScale 0.5 to 1.3/1.75 across three in-state
		// A_SetScale calls at :501-506, then fades over 16 tics. A clean
		// harmless ground shockwave -- rare in this tree.
		Add(outv, "RS_BBaronCmonAndSlam","baron ground slam",0, A_SMOKE | A_TRAIL | A_PUFF, "shockwave_ground", R_BOD | R_HED);
		// HIGH -- RS_BaronFX.zs:1022-1056. Scale 1.5, +FLOAT +NOGRAVITY
		// +NOCLIP, no damage, no DamageType. It sheds RS_Drt1/2/3 on
		// every frame, so the visual is the debris, not the sprite.
		// SPAWNER: it is a particulate generator by construction.
		Add(outv, "RS_BaronOfDirtCH",   "dirt plume",        0, A_SMOKE | A_TRAIL, "dust_plume", R_HED | R_SPW);
		// HIGH -- RS_ArchvileFX.zs:2002-2026. RenderStyle "Stencil" over
		// the VILE body sheet: a flat single-colour cutout, unique in
		// this tree. Eighteen spawn sites in RS_Archvile.zs each give it
		// frandom(-1.1,1.1) drift. See NEEDS EYES -- this is the one
		// entry whose SHAPE may break the illusion.
		Add(outv, "RS_BVileCloud2",     "vile afterimage",   0, A_SMOKE | A_TRAIL, "afterimage_vile", R_HED);
		// HIGH -- RS_BaronFX.zs:1768-1788. No Damage, no DamageType.
		// Six in-state A_SetScale calls run 1.5 -> 1.1 -> 0.9 -> 0.5 ->
		// (0.3,0.8) -> (0.3,2.0) in 18 tics: a bloom that implodes to a
		// point then snaps into a tall spike. Headline AND accent -- the
		// single best argument in the tree for role being a bitmask.
		Add(outv, "RS_DeepCharge1",     "deep charge",       0, A_SMOKE | A_PUFF | A_SPRK, "charge_collapse", R_ACC | R_BOD | R_HED);
		// HIGH, and T_FIRE is CODE-evidenced, not name-evidenced: it is
		// spawned at RS_Baron.zs:1705 and the same attack chain spawns
		// RS_BigBadFire1 two frames later at :1707, which carries
		// DamageType "Fire" (RS_BaronFX.zs:265). Harmless itself:
		// +NOINTERACTION at :237, Speed 0, no Damage. Scale 1.2, halves
		// to 0.6 for the tail at :249. The best muzzle-shaped candidate
		// found -- and it belongs on axis 3, not axis 2, because axis 2
		// has no class field.
		Add(outv, "RS_FireHand1",       "hand flare",        T_FIRE, A_SMOKE | A_PUFF | A_SPRK, "flare_hand", R_BOD);

		// =============================================================
		// AXIS 5 -- PUFF, and AXIS 6 -- SPARKS.
		// =============================================================
		// HIGH, and the strongest possible puff evidence in the tree:
		// it is passed as the PUFFTYPE argument of A_CustomBulletAttack
		// at RS_Cacodemon.zs:1716 and :1949. It is also a bombardment --
		// Scale 2, 21 tics of A_Explode(random(2,26),64) then 8 more
		// frames each dropping a full RS_HadeExpl across a 256x256x176
		// box. HOSTILE and SPAWNER both set. Do not roll this onto a
		// pistol without a size query.
		Add(outv, "RS_HadeAra",         "hade bullet puff",  0, A_PUFF | A_PAY, "puff_hade", R_HED | R_HOS | R_SPW);
		// HIGH -- RS_ArchvileFX.zs:1670-1689. Scale 1.25, Add, Alpha
		// 0.55, no Damage, PLSS AB then PLSE ABCDE. Fifteen at a time
		// with random pitch reads as spark spray; one reads as a flash.
		Add(outv, "RS_BlueGash2",       "blue gash",         0, A_PUFF | A_SPRK | A_TRAIL, "gash_blue", R_BOD);
		// HIGH -- RS_BaronFX.zs:667-692, 80 quoted spawn sites in
		// RS_Baron.zs (verified count). +NOINTERACTION, no Damage,
		// Scale 0.55 shrinking to 0.05 over ~20 tics.
		Add(outv, "RS_FrostWingBaron",  "frost mote",        0, A_PUFF | A_SPRK | A_TRAIL, "mote_frost", R_ACC);
		// HIGH -- RS_BaronFX.zs:697-719. Same 0.55 body, opposite tail:
		// A_Stop then A_SetScale 0.65 then 0.85. One look, two endings.
		Add(outv, "RS_FrostWingBaron2", "frost mote bloom",  0, A_PUFF | A_TRAIL, "mote_frost_bloom", R_ACC | R_BOD);
		// HIGH -- RS_BaronFX.zs:914-936. XScale 1.25 / YScale 1.80, a
		// tall narrow plume, Add at Alpha 1.95 (deliberate blowout).
		// No Damage. HAZARD: Death at :936 spawns RS_AbyssBaronSoul, a
		// summonable actor. SPAWNER set; needs a stripped variant.
		Add(outv, "RS_AbyssBaronHandFire3","hand plume",     0, A_PUFF | A_SPRK | A_SMOKE, "plume_hand", R_BOD | R_SPW);
		// HIGH, ICE is CODE -- DamageType "Ice" at RS_BaronFX.zs:952.
		// Scale 0.75, FRFX ABCD at 1 tic then eight death frames each
		// firing A_Explode(random(1,7),32,0).
		Add(outv, "RS_AbyssBaronHandFire2","ice shard burst",T_ICE, A_PUFF | A_SPRK | A_PAY, "burst_ice", R_ACC | R_HOS);
		// The four-actor ice set, RS_ArchvileFX.zs:827/856/886/912. All
		// four draw C3BB at Alpha 0.95 / Add / Radius 16 / Height 4 and
		// differ only in frame subset, scale, and whether A_Explode
		// fires. ICE is CODE on 2 and 3 (DamageType "Ice", :864, :894)
		// and on 4 (A_IceGuyDie at :931 -- the Hexen shatter pointer).
		// Vile1 has no DamageType, so it carries no theme.
		Add(outv, "RS_IceStartVile1",   "ice bloom",         0,     A_PUFF | A_SMOKE | A_SPRK, "bloom_ice", R_BOD);
		Add(outv, "RS_IceStartVile2",   "ice bloom armed",   T_ICE, A_PUFF | A_PAY, "bloom_ice_armed", R_BOD | R_HOS);
		Add(outv, "RS_IceStartVile3",   "ice bloom armed2",  T_ICE, A_PUFF | A_PAY, "bloom_ice_armed2", R_BOD | R_HOS);
		Add(outv, "RS_IceStartVile4",   "ice shard",         T_ICE, A_PUFF | A_SPRK, "shard_ice", R_ACC);
		// HIGH -- RS_BaronFX.zs:1575-1591. Scale 1.0 stated, Alpha 0.67,
		// no Damage. NOTE the 3-tic TNT1 lead-in before FBFX ABCDE: as a
		// trail node it appears three tics BEHIND the emitter, which
		// reads as lag rather than smear. Fourteen live spawn sites.
		Add(outv, "RS_FallenFX",        "fallen spark",      0, A_PUFF | A_SPRK | A_TRAIL, "spark_fallen", R_BOD);
		// HIGH -- RS_ArchvileFX.zs:1081-1099. XScale 0.2 / YScale 0.76,
		// the most extreme aspect in the archvile file, Stencil. Fifteen
		// at once is a spray of thin shards. SPAWNER (seeds 3x at :1099).
		Add(outv, "RS_PsychicTangleAbyVile2","shard sliver", 0, A_PUFF | A_SPRK, "sliver_shard", R_ACC | R_SPW);
		// HIGH -- RS_ArchvileFX.zs:2555-2580. Scale 1, Stencil, and
		// crucially NO A_Warp, unlike its Scale-2 sibling RS_BrightUpVile
		// which warps to AAPTR_TRACER every frame and will not reposition
		// without one. This is the one of the pair that drops cleanly in.
		Add(outv, "RS_BrightUpVile2",   "stencil burst",     0, A_PUFF | A_SPRK | A_PAY, "burst_stencil", R_BOD | R_HOS);
		// The RS_Blast ember/shrapnel/flare set. HIGH -- all four are
		// spawned from RS_Blast's Spawn state with explicit random angle
		// and pitch (RS_FX_Blast.zs:398-405), so the spawn parameters are
		// known. Weapon-tier art, correctly sized, and not one of them is
		// in the registry.
		Add(outv, "RS_BlastEmber",      "blast ember",       0, A_SPRK, "ember_blast",      R_ACC);
		Add(outv, "RS_BlastEmberFast",  "blast ember fast",  0, A_SPRK, "ember_blast_fast", R_ACC);
		Add(outv, "RS_BlastShrapnel",   "blast shrapnel",    0, A_SPRK, "shrapnel_blast",   R_ACC);
		Add(outv, "RS_BlastRedFlare",   "blast red flare",   0, A_SPRK | A_PUFF, "flare_red", R_ACC);
		// HIGH -- RS_FX_Blast.zs:105-124. Scale set to (0.8,0.4) in
		// PostBeginPlay, NOT in the Default block: a Default cannot hold
		// a non-uniform scale on this engine. An emitter reading Default
		// blocks alone would size this wrong.
		Add(outv, "RS_BlastFlare",      "blast flare",       0, A_SPRK | A_PUFF, "flare_blast", R_ACC);
		// MEDIUM -- RS_FX_Particles.zs:84-121, read in full. Nothing
		// spawns it and its own header says so. A one-call
		// omnidirectional burst that reads rs_fx_hifitier and scales
		// 10 -> 20 particles, then Destroy()s itself. The single
		// cheapest SPARKS win available.
		Add(outv, "RS_ExplosionParticleSpawner","particle burst", 0, A_SPRK, "burst_particles", R_BOD | R_SPW);

		// =============================================================
		// AXIS 7 -- TRAIL.
		// =============================================================
		// HIGH -- RS_ArchvileFX.zs:2373-2394. Scale 0.30, Alpha 0.3,
		// Add, +NOINTERACTION, 30-tic life, and its Death TAPERS
		// (0.3->0.2->0.1) instead of popping. Spawned at a fixed
		// (0,-3,2) offset from four sites at :2430-2444.
		Add(outv, "RS_VBtrail4",        "vile bolt trail",   0, A_TRAIL | A_SPRK, "trail_vilebolt", R_ACC);
		// HIGH -- RS_BaronFX.zs:1858-1878. XScale 0.9 / YScale 1.1, three
		// tics total: the shortest-lived drawable in the baron file,
		// which is exactly right for a dense trail. COPY THE CALL SHAPE
		// AT :1848, NOT JUST THE CLASS -- offset AND velocity are both
		// pitch-derived (cos(pitch), -sin(pitch)), so it lays along the
		// flight vector instead of behind the emitter's feet. Same
		// pattern as the already-registered RS_IceSeekerTrailBaron
		// (:542). That call shape is the reusable asset here.
		Add(outv, "RS_WhiteBaronSliceTrail","slash trail",   0, A_TRAIL, "trail_slash", R_ACC);
		// HIGH, FIRE is CODE -- DamageType "Fire" at RS_ChaingunnerFX.zs
		// :213 with SeeSound "Fire/fire3". YScale 0.3 / XScale 0.75, a
		// flattened floor smear that bounces off walls with a 1.5 gain
		// (BounceCount 999) and fires A_Explode(random(2,10),128) on each
		// of six frames. FOUR independent spawn sites across four monster
		// families (RS_ChaingunnerFX.zs:925, RS_CyberdemonFX.zs:1909,
		// RS_ImpFX.zs:1057, RS_MastermindFX.zs:1940). HOSTILE.
		Add(outv, "RS_GroundRedCyb",    "burning ground",    T_FIRE, A_TRAIL | A_SMOKE | A_PAY, "ground_fire", R_ACC | R_HOS);
		// MEDIUM -- orphan, Default block only. RS_FX_Rocket.zs:57-76.
		// +FORCEXYBILLBOARD +NOGRAVITY, Alpha 0.5, Scale 0.12, RSF1 A 2
		// and Stop. Weapon-tier, already the right size for a gun.
		Add(outv, "RS_SeekerFlare",     "seeker flare",      0, A_TRAIL | A_SPRK, "flare_seeker", R_ACC);
		// MEDIUM -- orphan. RS_ArchvileFX.zs:2339-2363. Scale 0.50,
		// Alpha 0.5, Add, four-step shrink plus a 4-particle white burst
		// mid-fade. RS_VBtrail3 (:2368) is this class with `Speed 20`
		// and nothing else -- one entry or one entry at two speeds.
		Add(outv, "RS_VBtrail2",        "vile trail wide",   0, A_TRAIL | A_SPRK, "trail_vile_wide", R_ACC);
		// MEDIUM -- orphan. RS_BaronFX.zs:1658-1676. The ONLY
		// RenderStyle "Normal" drawable in the baron file, so the only
		// candidate that will read as opaque smoke rather than glow, and
		// it has a tunable dwell (ReactionTime 60 + A_Countdown).
		Add(outv, "RS_FallenSP",        "fallen smoke",      0, A_TRAIL | A_PUFF | A_SMOKE, "smoke_fallen", R_BOD);

		// =============================================================
		// AXIS 0 -- PROJECTILE additions the 409-pool missed.
		// =============================================================
		// HIGH -- RS_BaronFX.zs:1748-1763. Its PARENT RS_TentacleBall1 is
		// in the PACK pool; this one is not. Inherits DamageType "Plasma"
		// / Add / Alpha 0.75, overrides Speed 10 and Damage 5, and plays
		// the SAME OLDP sheet BACKWARDS (FEDC vs AB). One sheet, two
		// projectiles, opposite frame order. Free.
		Add(outv, "RS_TentacleBall2",   "tentacle ball 2",   T_PLAS, A_PROJ, "proj_tentacle2", R_BOD);
```

**Entries the adversarial pass refuted â€” do not paste these, and note the delta to what is already in the file:**

- `RS_DarkFlameTrailVile` is already registered at `RS_FXRegistry.zs:151` as `T_FIRE, A_TRAIL | A_SMOKE`. **Leave that line exactly as it is.** The proposed upgrade to `A_PAY` is wrong: its only gameplay effect is `A_RadiusGive("RS_GrowRaisin",60,RGF_MONSTERS|RGF_CORPSES,1)` at `RS_ArchvileFX.zs:2210` plus corpse resurrection through `A_VileChase` at `:2211` into a live `Heal` state at `:2217`. On a player gun that buffs and raises enemies. Its `Damage 2` at `:2194` is inert â€” the class has no Missile or Melee state. It is also a live AI `Monster` (`:2182`, Health 9999); a per-tick trail instantiates dozens of AI thinkers. If you keep it as a trail, set `R_HOS` on it.
- `RS_DFire` â€” refuted. It carries `+SEEKERMISSILE` (`RS_ArchvileFX.zs:1899`) and 28 of its 30 state lines call `A_Fire`, which `SetOrigin`s it onto the tracer every call. It is the vanilla archvile flame that rides its victim, not a planted column. TRAIL is geometrically incoherent (every instance stacks on one point, each running 29 `A_Explode` calls). PAYLOAD at medium only.
- `RS_VBtrail` (`RS_ArchvileFX.zs:2312`) â€” **never register.** It is spawned (`:2475`) and its Default block looks ideal (Scale 0.75, Alpha 0.6, Add, purple Translation), but its only sprite is `FBXP` and no `FBXP` lump exists in the tree. This is precisely the forty-phantom-muzzle-flashes failure recorded at `RS_FXGallery.zs:12-15`, one step further along: an emitter reading Default blocks would register a beautiful trail that draws nothing.
- `RS_SplashAbyssVile2` (`RS_ArchvileFX.zs:1189`) â€” needs `R_SPW` and probably exclusion: its Death at `:1217` spawns `RS_ABVileTentacle`, a full 112-tall Monster with a melee attack.
- `RS_BVileCloud` (`RS_ArchvileFX.zs:1973`) is **in the PACK projectile pool and misclassified** â€” it is a Stencil silhouette of the archvile body fading 0.25/frame and decelerating 14â†’12â†’8. It reads as a smoke afterimage, not a shot.

**Traps found in the weapon tree that must not be registered** (all verified by reading the class):

- `RS_GunBarrelSmoke`, `RS_FX_Smoke.zs:42-63` â€” every state is `TNT1`. Fully inert; its own header says so.
- `RS_HomingRocketFlare`, `RS_FX_Rocket.zs:40-55` â€” Default says Alpha 0.4 / Scale 0.09 but the Spawn state is two `TNT1` frames and a `Stop`. It is a master-proximity checker with no visual.
- `RS_BFGBallRayPuff`, `RS_FX_BFG.zs:81-88` â€” a `Default` block and **no `States` block at all**, so it inherits Actor's `TNT1 A -1`. Permanently invisible and permanent.
- `RS_BFGRailPuff`, `RS_FX_BFG.zs:132-151` â€” draws nothing itself; its three visible-looking Default properties are inherited and unused because the Spawn state is `TNT1` only. Its visual is entirely the two projectiles it spawns. Register it as a PAYLOAD/spawner if at all, never as a puff.

---

## 3. MULTI-USE PRECEDENTS

**Conclusion: `RS_SmokeWisp` is not the exception, it is the least interesting example. The tree contains at least nine sprite sheets serving 3-6 actors each at scale ranges up to 10x, and in several cases the same frames serve as projectile, trail, puff and impact simultaneously. This is the evidence base for the whole role design, and the repo already argues it at `RS_FXGallery.zs:48-52`.**

The known case, for calibration: `RS_SmokeWisp` Default is Alpha 0.3 / Scale 0.1 (`RS_FX_Smoke.zs:19-20`), but `RS_HiFiFX.MuzzleEffects` calls `SetupVisual(0.35, 0.18, 0.3)` at `RS_FX_HiFiFX.zs:63` â€” and at Standard tier `SetupVisual(0.22, 0.12, 0.3)` per `:54-55`. So one class has **three** live appearances and the Default is none of them. The gallery had to be patched on 2026-08-11 to match (`RS_FXGallery.zs:126-132`).

The ones that were not known:

| Sheet | Actors | Scale range | Roles served |
|---|---|---|---|
| **FTRA** | 5 | 1.0 â€“ 1.25, Alpha 0.01 â€“ 1.25 | projectile (`RS_DarkFlameVile`, `RS_ArchvileFX.zs:2149`), floor puff (`RS_DFlamePuffVile`, `:2247`, +FLOORHUGGER), rising puff (`RS_DFlamePuffVile2`, `:2303`, +FLOATBOB), translucent trail (`RS_DarkFlameTrailVile`, `:2211`), and **deliberately invisible** (`RS_WhiteVileResser`, `:2622`, Alpha 0.01). Same pixels additive-overbright, translucent and transparent. |
| **SPIR** | 3 + 5 borrowers | **0.2 â€“ 2.0, a 10x range** | `RS_PsychicTangleAbyVile2` XScale 0.2/YScale 0.76 (`:1091`), `RS_BrightUpVile2` Scale 1 (`:2567`), `RS_BrightUpVile` Scale 2 (`:2529`), plus a shared `A_SetScale(2.0)` death flash inside five unrelated baron projectiles (`RS_BaronFX.zs:635`, `:842`, `:1459`, `:1852`, `:1912`). |
| **FLUM** | 5 | 0.6 â€“ 1.7 | and the harmless/armed split runs straight through it: `RS_BrownBaronFlame2` XScale 0.6 armed with DamageFunction(5,20) (`RS_BaronFX.zs:363`), `RS_BrownBaronFlame` 0.75 harmless +NOINTERACTION (`:338`), `RS_FireHand1` 1.2 harmless (`:241`), `RS_BigBadFire1` 1.5 armed DamageType Fire (`:266`), `RS_ReABreath` 1.7 armed (`RS_ArchvileFX.zs:1873`). Hand flare, muzzle bloom, trail node and projectile body from one sheet. |
| **MISL B/C/D** | 6 | 0.4 â€“ 1.5 | the vanilla rocket-explosion tail shared as a death flash at five sizes: `A_SetScale(0.4)` `RS_BaronFX.zs:347`, `(0.5)` `RS_ArchvileFX.zs:226`, `(0.6)` `RS_BaronFX.zs:249`, `(0.75)` `:373`, `RS_DFlameBoomVile` at 0.75 `RS_ArchvileFX.zs:2272`, `RS_BigBadFire1` unscaled at 1.5 `RS_BaronFX.zs:276`. **If the registry wants one generic impact entry with a role range, this is it.** |
| **RED8** | 3 | XScale 0.85â€“0.95, YScale 0.3â€“1.75 | a growing shockwave (`RS_BBaronCmonAndSlam`, `RS_BaronFX.zs:491`, `:501-506`), a flat burning bar (`RS_GroundRedBar`, `:869`), and a stationary seeder (`RS_RedPower`, `:1466`). One asset, three ground footprints. |
| **ICEY** | 4 | 0.45 â€“ 0.85 | projectile (`RS_IceSeekerBaron`, `RS_BaronFX.zs:546`), trail (`RS_IceSeekerTrailBaron`, `:660`), death bloom (`RS_FrostWingBaron2`, `:717-719`), impact (`RS_IceABVile`, `RS_ArchvileFX.zs:1046`) â€” plus the affix set reuses A/B for flight and Fâ€“I for shatter (`RS_FX_AffixParts.zs:218`, `:228`). Note `RS_FX_AffixParts.zs:12`: **ICEY has no D/E frames â€” do not "fix" a death state to CDE.** |
| **BOGY** | 2 | XScale 1.7 vs 1.85, YScale 0.15 both | `RS_SplashAbyssVile` armed with DamageFunction(10,30) (`RS_ArchvileFX.zs:1113`) and `RS_SplashAbyssVile2` unarmed (`:1196`). Textbook one-entry-two-roles pair. |
| **C3BB** | 4 | 0.5 and 1.0 | `RS_IceStartVile1/2/3/4`, all Alpha 0.95 / Add / Radius 16 / Height 4, differing only in frame subset, scale, and whether `A_Explode` fires (`RS_ArchvileFX.zs:827`, `:856`, `:886`, `:912`). Four rows, or one row with a role and a hostile flag â€” the code argues for the latter. |
| **RNGG** | 3 | 0.75 upright vs XScale 2.0/YScale 0.75 flat | `RS_AbyssBaronRing` a wide floor disc (`RS_BaronFX.zs:744`), `RS_WvileSpot` small and upright (`RS_ArchvileFX.zs:2740`), and two classes use `RNGG A 0` as a zero-tic entry frame before jumping to FTRA (`:2206`, `:2618`). |
| **JSMO** | 2 | 0.9 / Alpha 0.2 vs **1.4 / Alpha 0.12** | `RS_BlastSmoke` and `RS_BlastSmokeHeavy`, `RS_FX_Blast.zs:142` and `:179`. The heavy one holds 40 tics instead of 20 and fades at 0.002 instead of 0.01 â€” 122 tics versus 102. Same eleven frames, muzzle detail and smokescreen. **This is the owner's exact hypothesis, already written, in the weapon tree.** |

Two source-flagged asymmetries the registry must decide about rather than inherit blindly: `RS_BrownBaronFlame` draws at XScale 0.75 with YScale left at 1.0, flagged in-source at `RS_BaronFX.zs:338` ("CH lists xScale 1.0 then xscale 0.75; the last wins"), and `RS_BrownBaronFlame2` has the same at `:363` (1.25 then 0.6). And `RS_BlastFlare`/`RS_BlastSmokeColumn` set non-uniform scale in `PostBeginPlay` (`RS_FX_Blast.zs:113-117`, `:213-217`) because a Default block physically cannot hold one on this engine â€” any scale-reading emitter will get those two wrong.

---

## 4. PAYLOAD CANDIDATES

**Conclusion: you do not need to write a lingering-area mechanism. `RS_EliteFX_CreepBase` at `zscript/monsters/RS_EliteFX.zs:243-320` is already a fully generic, property-driven, self-expiring floor hazard that applies an arbitrary `Inventory` to everything in a radius on an interval. It ships four payload flavours. The smokescreen is a subclass plus a token â€” under fifty lines total â€” and the only structural change is one flag.**

The class, verified in full:

```
	property CreepEffect: CreepEffect;	class<Inventory> CreepEffect;
	property CreepRadius: CreepRadius;	int CreepRadius;
	property CreepTick:   CreepTick;	int CreepTick;
	property CreepLife:   CreepLife;	int CreepLife;
	property SpriteScale: SpriteScale;	double SpriteScale;
	property FlatScale:   FlatScale;	double FlatScale;
```
â€” `RS_EliteFX.zs:248-253`. Its `Tick()` at `:290-302` does:
```
		if (level.Time % creepTick == 0)
			A_RadiusGive(creepEffect, creepRadius, RGF_CUBE | RGF_PLAYERS, 1);
```
and expires itself after `creepLife` seconds into a `Disappear` state that fades and shrinks to nothing (`:317-319`). `BeginPlay` at `:266-283` reads `rs_elite_flatcreep` and either lays the sprite flat on the floor at `floorz + 1` with a random yaw, or stands it up â€” so it already supports both a ground stain and a volume.

Existing subclasses proving the pattern: `RS_EliteFX_DarkGreenCreep` (damage), `RS_EliteFX_RedCreep` (hotter, `CreepLife 6`, `CreepTick 17`), `RS_EliteFX_WhiteCreep` (**slowness**, `CreepEffect 'RS_EliteFX_Slowness1'`), `RS_EliteFX_BigWhiteCreep`, and small variants at `CreepRadius 32` â€” `RS_EliteFX.zs:324-400`.

**The one structural change**: `RGF_PLAYERS` at `:293` must become `RGF_MONSTERS` for a player-fired version. Add it as a seventh property (`CreepFlags`) rather than forking the class.

**For "enemies inside are 50% less accurate", two implementable hooks, both real:**

1. **Damage-side (recommended, robust).** A token on the monster, and a single `override int DamageMobj(...)` on `VR_DualClassBase` (`zscript/player/VR_PlayerClasses.zs:26`) â€” the one abstract base every player class inherits from, so one override covers all of them. If `inflictor`'s or `source`'s inventory holds the token, halve the damage. This is exact, cannot be dodged by attack type, and works identically for hitscan, projectiles and melee. There is no native accuracy stat in GZDoom, so this *is* what "50% less accurate" means mechanically.
2. **Aim-side (cosmetically truer, less exact).** The token's `DoEffect()` jitters `Owner.angle`/`Owner.pitch` while the owner is inside its Missile state sequence. Visibly wrong shots, but the magnitude does not map cleanly onto "50%" and hitscan spread is per-attack-function.

The token itself is a copy of `RS_ST_BurnToken` (`zscript/weapons/weaponfx/RS_FX_StreakMech.zs:85-135`) with a different `DoEffect` body â€” that class already demonstrates the whole contract: a refresh-not-stack duration, an `Actor BurnSource` back-pointer so kills credit the firer, self-`Destroy()` on expiry or owner death, and a cosmetic spawn every 6 tics so the affected target reads as affected. `RS_ST_Burn.Apply` at `:139-160` is the static entry point. **Nothing calls either of them yet** â€” its own header says so.

Lingering area effects already in the tree that could host a gameplay property, ranked by how little work each needs:

| Class | Path:line | Life | Damage today | What it takes |
|---|---|---|---|---|
| **`RS_EliteFX_CreepBase`** | `RS_EliteFX.zs:243` | property-driven, 3-6 s | property-driven | **Nothing.** Subclass it, name your token, flip `RGF_PLAYERS`â†’`RGF_MONSTERS`. Confidence: high. |
| `RS_VoidField` | `RS_CacodemonFX.zs:942` | **~640 tics â‰ˆ 18 s** expected (exits on a 2-in-256 roll per 5-tic cycle, `:980`) | `A_Explode(5,64)` per cycle | Best *visual* host: Scale 1.5 breathing 1.5â†’1.3â†’1.0, Add, Alpha 0.75, `+INVULNERABLE` so the player cannot pop it. **Safe despite being a `Monster`** â€” Speed 0, FastSpeed 0, `+NOTARGET`, and it has no `See` or `Missile` state at all, so the AI never runs. `A_Explode` credits `target`, so a player-spawned copy must have `target` set to the player or it will hurt you. Confidence: high. |
| `RS_AffixGroundFire` | `RS_FX_AffixParts.zs:135-159` | ~120 tics | fixed `A_Explode(4,64)` x3 | Already the correct shape and already player-side â€” its header states the design rule you want ("area denial, not a second payload"). Add a token give beside each `A_Explode`. Confidence: high. |
| `RS_BrownSandBagCGuy` | `RS_ChaingunnerFX.zs:254` | **303 tics â‰ˆ 8.7 s** (`SB4G X 300`, `:287`) | none | The only true **deployable cover** in the mod: Radius 42, Health 80, grows 0.3â†’1.0 over 12 tics then `bTHRUACTORS = false` at `:283` makes it solid and destructible. Zero damage anywhere. If a non-damaging lingering payload affix is wanted, this is already written. Confidence: high. |
| `RS_CacoARMSU2` / `RS_CacoARMSU` | `RS_CacodemonFX.zs:2013`, `:2053` | ~96 / ~60 tics | `A_Explode(random(10,50),64)` repeatedly | Speed 0, `+FLOORHUGGER`, y-scale animates 0.25â†’1.0â†’1.25 to fake rising out of the floor. A clean two-step ladder of one payload. Confidence: high. |
| `RS_ArmSpawnerCACO2` | `RS_CacodemonFX.zs:1979` | 12 tics itself | none of its own | The **delivery** half: `A_VileTarget` plants it at the target's feet, Scale 4.7 black Stencil bloom, then its Death dispenses **16** `RS_CacoARMSU2` across Â±256 (`:2006-2008`, counted). Register it and you buy the whole two-stage effect. Confidence: high. |
| `RS_HadesBolt` | `RS_CacodemonFX.zs:1717` | `ReactionTime 35` Ã— ~10-tic cycles â‰ˆ 350 tics | five `A_Explode(random(5,15),64,0)` per cycle | The largest sustained payload found. `+FLOORHUGGER +RIPPER`, YScale 4.0 / XScale 0.7, Hexen bounce. Far too much for a per-shot payload; right for a mastery. Confidence: high. |
| `RS_Puddle2` | `RS_ChaingunnerFX.zs:1001` | ~190 tics | Damage 4, **PoisonDamage 15 / PoisonDamageType "Poison"** | The only explicit poison hazard found, and POISON is the thinnest live theme (12 classes). It wanders (`A_Wander`), wall-bounces at gain 1.5, and spits a projectile every 2 tics. Confidence: high. |
| `RS_ST_StickyProjectile` | `RS_FX_StreakMech.zs:207-330` | until fuse | none | Not an area effect â€” the **placement** primitive. Sticks and aligns flat to whatever surface it hit, with a `Fuse` property and an empty `Detonate` state waiting for a subclass. Deliberately leaves `master` alone (`:250-262`) so XP attribution survives. Nothing fires it. Confidence: high. |

**Before any of this ships, PAYLOAD needs wiring that does not exist.** `RS_FXAXIS_PAYLOAD` (`RS_FXRegistry.zs:85`) has no backing field on `RS_AttackProfile` or `RS_Weapon` and no spawn site. Four entries already claim it and nothing can consume them. The minimum is a `Class<Actor> Payload` + `int PayloadCount` on the profile and a spawn site in `RS_BallisticFired`'s Death state. Note also that the `"payload"` keyword in `RS_AffixIngredients.zs:112-132` is a **different domain** (pellet/damage math) and `RS_Keywords.zs:81` already records the name collision.

---

## 5. WHAT NOBODY CAN REACH

**Conclusion: 37 FX classes are declared and never mentioned again anywhere in the 217-file zscript tree. Four of them are worth wiring today; three of them are traps that would register as beautiful entries and draw nothing.**

Method: every class declared in `zscript/monsters/**/RS_*FX.zs` and `zscript/weapons/weaponfx/`, cross-checked against every quoted identifier in every `.zs`/`.zsc`, then each survivor counted for total whole-word occurrences repo-wide. One occurrence = the declaration only.

**Worth wiring, in order of return:**

1. **`RS_ExplosionParticleSpawner`** â€” `RS_FX_Particles.zs:84`. A one-call omnidirectional spark burst that reads the FX tier and scales 10â†’20 particles, then `Destroy()`s itself (`:94-120`). Its own header: nothing calls it yet, it exists so a future effect has one line to reach for. Highest value per line of work in the whole list.
2. **`RS_BlastSmokeHeavy`** â€” `RS_FX_Blast.zs:179`. Scale 1.4, Alpha 0.12, **Translucent not additive**, ~122 tics. Its parent is live; the heavy variant is not. The smokescreen visual, already imported, already sized, already water-aware (`:189`, `:191`).
3. **`RS_MagDrop`** â€” `RS_FX_Casings.zs:66`. RSM0 Aâ€“H, Scale 1.0, gravity, bounce. `RS_HiFiFX.MagDrop` exists at `RS_FX_HiFiFX.zs:79-87` and takes a class name â€” but no weapon passes this one. Axis 1 (CASING) has zero entries; this is a free second.
4. **`RS_SeekerFlare`** â€” `RS_FX_Rocket.zs:57`. Alpha 0.5, Scale 0.12, `+FORCEXYBILLBOARD`, two tics and Stop. Weapon-tier trail art at the right size.
5. **`RS_FallenSP`** â€” `RS_BaronFX.zs:1658`. The only `RenderStyle "Normal"` drawable in the baron file, with a tunable `ReactionTime 60` dwell.
6. **`RS_VBtrail2` / `RS_VBtrail3`** â€” `RS_ArchvileFX.zs:2339`, `:2368`. Drawable, four-step shrink, particle kicker. VBtrail3's entire body is `Default { Speed 20; }`.
7. `RS_AffixFireEmber` (`RS_FX_AffixParts.zs:89`), `RS_AffixIceShard` (`:204`) â€” authored affix rounds with full Death states that are not reachable from any installed affix. Different problem (affix wiring, not FX registry) but same symptom.

**Do not wire â€” verified traps:**

- `RS_GunBarrelSmoke` (`RS_FX_Smoke.zs:42`) â€” all states `TNT1`.
- `RS_HomingRocketFlare` (`RS_FX_Rocket.zs:40`) â€” Default advertises Alpha 0.4/Scale 0.09, Spawn state is `TNT1` only.
- `RS_BFGBallRayPuff` (`RS_FX_BFG.zs:81`) â€” no `States` block at all; inherits `TNT1 A -1`, i.e. permanently invisible and never removed.
- `RS_VBtrail` (`RS_ArchvileFX.zs:2312`) â€” **not** an orphan (spawned at `:2475`) but renders nothing: sprite prefix `FBXP` has no lump in the tree.
- `RS_BvileDummy` (`RS_ArchvileFX.zs:2102`) â€” live, but its whole job is two `A_SpawnParticle("Purple")` calls. Engine particles, not a sprite: unrepresentable as an `RS_FXEntry`.

**Sequences with no class** â€” 156 of the 1,265 files under `sounds/` have no SNDINFO alias and are unaddressable by name (per the sound census: `rs_weapon` 59, `ch` 37, `rs_gh_weapon` 31, `combatfx` 25, `rs_grenade` 4). I did not re-audit that count myself.

The two static utility classes `RS_ST_LanceHit` (`RS_FX_StreakMech.zs:35`) and `RS_ST_Push` (`:186`) are also uncalled, but they are mechanisms rather than FX â€” a capsule-shaped damage volume and mass-normalized knockback, both fully implemented. Worth knowing they exist before anyone writes either again.

---

## 6. NEEDS EYES

**First, a blocker nobody has hit yet: the documented gallery command does not work as typed.**

`RS_FXGallery.zs:22` documents `rs_fx_gallery <axis> [theme]`, but `KEYCONF` (72 lines, read in full) contains **no alias** for it â€” only `bonsai-*`, `gboh-*`, `rs_ui_debug` and `rs_curse_list`. There is no alias anywhere else in the repo. So the working invocation is the raw netevent:

```
netevent rs_fx_gallery 7            all trails, all themes
netevent rs_fx_gallery 5 0 1        fire-themed puffs -- the THIRD arg is the
                                    sentinel that distinguishes theme 0 from
                                    theme omitted (RS_FXGallery.zs:181)
netevent rs_fx_clear
rs_fx_gallery_scale 0               0 = as the gun draws it (CVARINFO.txt:1569)
```

Two lines in `KEYCONF` fix this permanently:
```
alias rs_fx_gallery "netevent rs_fx_gallery"
alias rs_fx_clear   "netevent rs_fx_clear"
```

**Second: the gallery only shows what is in the registry.** Every question below requires its entry pasted in first. Paste Section 2b, then work down this list.

Ordered by return on one look:

| # | Class | The one question | Command |
|---|---|---|---|
| 1 | `RS_BlastSmokeHeavy` vs `RS_BlastSmoke` | Set the scale to 0.2, then 1.0, then 3.0. **Is this one entry with three roles or three entries?** This is the whole design hypothesis and this pair is the cleanest test of it â€” same eleven JSMO frames, Translucent, already authored at two sizes. | `netevent rs_fx_gallery 3` then step `rs_fx_gallery_scale` 0.2 / 1.0 / 3.0 |
| 2 | `RS_BVileCloud2` | Eighteen archvile-body silhouettes drifting at once (`RS_ArchvileFX.zs:2002`, Stencil). **Does it read as a smoke volume, or unmistakably as a monster?** If the latter it breaks the "your gun fired something strange" premise and must never be a SMOKE entry. | `netevent rs_fx_gallery 3` |
| 3 | `RS_BrownVileGas` | Its `A_Jump(255,...)` yields four silhouettes from one class (`RS_BaronFX.zs:209-222). **Do all four read as gas/dust, or does the brown Translation at `:202` make it read as a specific brown object?** A brown-tinted anything is exactly the call that has burned this project twice. | `netevent rs_fx_gallery 3` â€” watch one pedestal for ~20 s |
| 4 | `RS_DeepCharge1` | It runs 1.5 â†’ 1.1 â†’ 0.9 â†’ 0.5 â†’ (0.3,0.8) â†’ (0.3,2.0) in 18 tics (`RS_BaronFX.zs:1783-1788`). **Is the final (0.3, 2.0) frame a readable vertical spike or a stretched artifact?** Decides whether it gets headline, accent, or both bits. | `netevent rs_fx_gallery 3` |
| 5 | `RS_FallenSP` | The only `RenderStyle "Normal"` drawable in the baron file. **Does FBSP read as opaque smoke â€” which would make it the only true non-glowing smoke available â€” or as a solid object sprite that looks wrong as FX?** | `netevent rs_fx_gallery 7` |
| 6 | `RS_VBtrail2` / `RS_VBtrail3` | Nothing spawns them, so only the Default block is known. **Do the MANF frames at Scale 0.50 / Alpha 0.5 read as a trail smear or a discrete puff?** One answer decides TRAIL vs PUFF for both. | `netevent rs_fx_gallery 7` |
| 7 | `RS_AbyssBaronHandFire3` and `...HandFire2` | Both are Add at **Alpha 1.95**, nearly double over-bright (`RS_BaronFX.zs:924`, `:954`). **Does the FRFX sheet survive that blowout with any shape left, or clip to a white blob?** Decides whether 1.95 is preserved or clamped on reuse. | `netevent rs_fx_gallery 5` |
| 8 | `RS_BrownBaronFlame` / `RS_BrownBaronFlame2` | Both draw at XScale 0.75 (resp. 0.6) with YScale left at 1.0 â€” flagged in-source as ambiguous at `RS_BaronFX.zs:338` and `:363`. **Deliberate stretch or CH bug?** Decides whether the registry carries the asymmetry or normalises it. | `netevent rs_fx_gallery 3` |
| 9 | `RS_SeekerFlare`, `RS_MagDrop` | Orphans with Default blocks only. **Do they draw at all, and at the right size?** Cheap to check, and confirms the orphan-detection method before trusting the rest of Section 5. | `netevent rs_fx_gallery 7` / `netevent rs_fx_gallery 1` |
| 10 | `RS_ExplosionParticleSpawner` | It `Destroy()`s itself in `PostBeginPlay` (`RS_FX_Particles.zs:119`). **Does the gallery's 35-tic respawn cycle show it at all**, or does a self-destroying spawner need a gallery special case? Answering this tells you whether the gallery can honestly display any spawner-type entry. | `netevent rs_fx_gallery 6` |
| 11 | `RS_HadeAra` | It is a *bullet puff* that carpets a 256Ã—256Ã—176 box (`RS_CacodemonFX.zs:1523-1525`). **At `rs_fx_gallery_scale 0.3`, is there a usable small puff hiding inside it**, or is the bombardment inseparable from the look? | `netevent rs_fx_gallery 5`, scale 0.3 |
| 12 | `RS_VoidField` | Scale 1.5 breathing to 1.0 on a 5-tic cycle, Add, Alpha 0.75 (`RS_CacodemonFX.zs:976-981`). **Does a single BBOM frame pulsing read as an area you would avoid walking into?** It is the leading smokescreen visual and the whole affix rests on that reading. | `netevent rs_fx_gallery 8` |

---

## 7. SOUND

**Conclusion: `RS_FXEntry` structurally cannot hold a sound â€” its payload field is `Class<Actor>` (`RS_FXRegistry.zs:51`) â€” which is why `RS_FXAXIS_SOUND` is declared, named, and set by zero of the 36 entries. A parallel `RS_SndRegistry` is the right shape, not more `RS_FXEntry` rows. Meanwhile the entire PACK sound axis is eight themes mapped to six distinct strings, against 1,265 declared names.**

Re-measured: `E:/RS_Main/SNDINFO` is 1,836 lines and declares **1,265 distinct logical names** (1,160 definition lines + `$random` groups + 10 `$alias`, deduplicated). The brief said 881; the census said 1,284; `RS_PACKCatalog.zs:558` says 1,255. My number is from parsing the file; the spread is small and does not change any conclusion.

**What the naming supports, and where it stops.** The corpus is two tiers that behave completely differently:

- **Tier A â€” the RS-authored weapon sets** (`rs_st/`, `rs_gh/`, `rs_ps/`, `rs_fx_`, `rs_vp_`, `rs_foley_`, plus the 340 `Sounds/â€¦` path-backed entries). A **moment** axis works here and is deliberate: `SNDINFO:853-901` gives `rs_st/flame_start` / `_loop` / `_stop`, `minigun_spinup` / `_spindown`, `rocket_fire` / `_fly` / `_explode`, `arc_charge` / `_fire` / `_fry`. `SNDINFO:593-611` gives `rs_fx_ice_cast` / `_fly` / `_hit` / `_shatter` â€” one element carrying launch, loop, impact and tail. That is the second dimension already written down.
- **Tier B â€” the 688-name CH import plus 386 unsegmented DOS lumps**, 53% of the corpus (`SNDINFO:912-1646`). Its second segment is **monster state**, not projectile moment: death 35, sight 29, pain 28, active 22, melee 11. Only `attack`/`atk`/`fire`/`cast` (~30 names) and `hit`/`explode`/`thud`/`splat` (~16) carry over.

So: **moment classifies the tier PACK should be drawing from, and does not classify the tier that is half the file.** TAIL is the bucket that barely exists â€” 7 names corpus-wide on a strict whole-token match, against 148 LAUNCH and 61 IMPACT. Ship it as a schema with an almost-empty fourth bucket, or fold TAIL into LOOP as its terminator.

A third dimension exists and is already live: **MATERIAL**. `SNDINFO:177-204` defines ten `rs_impact/*` `$random` groups (stone, metal, wood, dirt, glass, liquid, flesh, armored, mechanical, energy) driven by `RS_Material.ImpactSound()`. Any impact-moment entry wants an optional material field.

**What a registry should be.** Not `RS_FXEntry` with a nullable `Cls`. A parallel type:

```
	sound  Snd;      // the logical name
	string Handle;   // stable, [a-z0-9_], same convention as RS_FXEntry
	int    Themes;   // 1 << MTHEME_*, empty unless a call site evidences it
	int    Moment;   // LAUNCH / LOOP / IMPACT / TAIL bitmask
	int    Material; // optional, mirrors rs_impact/*
	bool   Layers;   // TRUE = safe as ExtraFireSound; FALSE = override only
```

That last field is load-bearing and easy to miss: `RS_AttackProfile` has **two** sound fields, not one â€” `sound FireSound` at `:112` (override; replaces the gun's report) and `sound ExtraFireSound` at `:130` (additive; layers under it). PACK was corrected on 2026-08-08 specifically because a themed sound on axis 5 **silenced** the gun (`RS_PACKAssembly.zs:186-198`). A registry that cannot say which of the two an entry suits will reintroduce that bug.

**Evidence rules for a sound entry**, same discipline as FX:
- `$limit rs_st/flame_loop 1` and `$limit rs_st/bfg_loop 1` (`SNDINFO:895-911`) are machine-readable statements of intent: a name carrying `$limit 1` is loop-moment evidence at MEDIUM with no call site at all. `$rolloff` on `rs_gren/explode 1100 1600` and `rs_gren/farexpl 3200 5400` marks a distance-scaled explosion pair.
- **No theme from a name.** I have not listened to a single file and neither has any prior pass. Every theme must come from a call site or a `$`-directive.

**Next step, concretely.** The highest-value available content is the **33 unused `$random` groups** â€” stable typed handles with multi-take variation already wired: `rs_vp_shotgun_fire`, `rs_vp_ssg_fire`, `rs_vp_pistol_fire`, `rs_vp_plasma_fire`, `rs_fx_explode_near` (`SNDINFO:531`), `rs_fx_explode_dist`, `rs_fx_plasma_explode`, `rs_fx_magdrop_small/_large/_bfg`, `obsidian/impact`, `obsidian/missile`. The entire `rs_vp_` family (116 of 116 names) is unreferenced, and the SNDINFO header at `:29-36` **pre-authorizes reuse**: the Vanilla+ weapon classes were deleted and the audio deliberately re-homed rather than discarded, "available to PACK or a future weapon."

Two cautions from the census I did not independently verify: ~20 entries resolve to no file anywhere in the repo (silent at runtime â€” `RS_PACKCatalog.zs:557-560` warns about exactly this failure mode), and 65 of the usable-unused names classify as HANDLING (mag drops, clip in/out, holster) and are almost certainly wrong content for a projectile axis even though the files are live.

---

## 8. COVERAGE

**Conclusion: 1,170 FX classes went into the classification pass and I received usable per-class findings for roughly 100 of them â€” one full chunk and part of a second, out of seventeen. Fifteen chunks' payloads did not survive into my input. The registry additions in Section 2 are real and defensible, but they are a sample of the archvile, baron, cacodemon and chaingunner families plus the weapon tree, not a survey of the mod.**

What I actually received and used:

| Source | Status |
|---|---|
| PACK format / registry format census | Complete. Verified against source; three corrections made (36 entries not 37, 1,033 monster FX classes not 995, the five passthrough pools are dead code). |
| Sound census | Complete. Count re-measured independently (1,265 vs 1,284). |
| Weapon-side usage census | **Truncated mid-sentence.** I have its summary (casing proven at 24 call sites, muzzleSmoke passed at 0 of 51, `MakeHitscan` has zero call sites anywhere, `MakeMelee` defaults `bigMuzzle` true so all six melee weapons emit muzzle smoke on every swing) but not its per-weapon table. |
| Classification chunk 1 â€” archvile + baron | Complete. ~40 entries, multi-use list, orphans, needs-eyes. Three high-confidence claims adversarially refuted; corrections applied above. |
| Classification chunk 2 â€” cacodemon + chaingunner | **Truncated mid-entry**, at `RS_SpiralSaw5`. I used the ~13 entries that arrived intact and verified two of them (`RS_VoidField`, `RS_BrownSandBagCGuy`) against source myself. |
| Classification chunks 3â€“17 | **Did not arrive.** |

**Still dark**, by file, with class counts I measured:

`RS_CyberdemonFX.zs` (100), `RS_MastermindFX.zs` (81), `RS_SpiderFX.zs` (80), `RS_LostSoulFX.zs` (76), `RS_RevenantFX.zs` (70), `RS_PainElementalFX.zs` (66), `RS_ZombiemanFX.zs` (50), `RS_FatsoFX.zs` (50), `RS_ShotgunnerFX.zs` (49), `RS_ImpFX.zs` (45), `RS_HellKnightFX.zs` (45), `RS_EliteFX.zs` (38), `RS_DemonFX.zs` (31), `RS_SpectreFX.zs` (18). **749 classes, 64% of the FX tree, unexamined at class level.**

I did partially cover the weapon tree myself: I read `RS_FX_Smoke.zs`, `RS_FX_Rocket.zs`, `RS_FX_Plasma.zs`, `RS_FX_Blast.zs`, `RS_FX_BFG.zs`, `RS_FX_Casings.zs`, `RS_FX_Particles.zs`, `RS_FX_AffixParts.zs`, `RS_FX_StreakMech.zs` and `RS_FX_HiFiFX.zs` in full â€” that is where every weapon-side entry and every trap in Sections 2 and 5 comes from. `RS_FX_Streak.zs`, `RS_FX_Sparks.zs` and the remaining weaponfx files are unread.

Three things I did **not** do, stated plainly:

- **I looked at no sprites.** Every visual claim here is from `Default` blocks, state tables and spawn-site parameters. That is why Section 6 exists and why it is ordered by value rather than by file.
- **The orphan analysis is repo-wide and complete** â€” that one is not a sample. All 1,170 FX classes were cross-checked against every quoted identifier in all 217 zscript files, and every candidate was re-counted for whole-word occurrences. The 37 orphans and the four render-nothing traps are exhaustive for the FX tree as of this commit.
- **No per-axis "classes that could serve it" denominator is honest yet.** Section 1's table gives what is reachable, not what exists, because the classification needed to produce the second number covers a third of the tree. Anyone who quotes a number for "how many puffs the mod owns" today is guessing.

Finally, stale comments in files this work will touch: `RS_PACKCatalog.zs:4-7` says EIGHT axes numbered 1-8 while `RS_FXRegistry.zs:77-86` uses NINE numbered 0-8 â€” the two files disagree on both the count and the base. `RS_PACKAssembly.zs:35-38` claims the palette supplies casing, muzzle, smoke, puff, sparks and trail; only casing and puff are true. `RS_PACKAssembly.zs:211-218` says `MakeBullet` defaults `ammoCost` to 0; it has defaulted to 1 since 2026-08-07 (`RS_AttackProfile.zs:369`).
