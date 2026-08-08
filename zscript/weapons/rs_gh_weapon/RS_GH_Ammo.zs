// =====================================================================
// RS_GH_ magazines -- one chambered-ammo class per weapon per identity,
// same convention as the main arsenal (AmmoType2 = rounds in the gun).
// Capacities taken from the source pack's own magazine classes.
//
// EVERY CLASS HERE INHERITS FROM `Ammo` DIRECTLY. NEVER FROM ANOTHER
// LOADED CLASS. Fixed 2026-08-07; the whole file was wrong before.
//
// The identities 2..6 used to read `: RS_GH_PistolLoaded` etc., and that
// silently bricked 60 weapons -- every GH magazine weapon above identity
// 1, including the Vanilla+ starting offhand (RS_GH_Pistol4) and every
// GH elite drop. The engine, not this mod, is what breaks:
// Ammo.GetParentAmmo() (engine ammo.zs:73) resolves any derived ammo to
// its least-derived ancestor below Ammo, and HandlePickup (:90) only
// stacks an item onto a bag whose class EQUALS that parent, while
// CreateCopy (:139) converts anything unhandled into the parent class.
// So GiveInventory("RS_GH_PistolLoaded4", n) can never land on the
// Loaded4 bag -- the rounds silently credit identity 1's magazine.
// The gun then arrives empty, Fire falls into Reload, and every trigger
// pull eats a magazine of reserve ammo while never firing a shot.
//
// The main arsenal never had this bug because RS_Ammo.zs:12-15 already
// documents the rule. This file is now the same shape. If a new GH
// weapon family is added, its six Loaded classes each say `: Ammo`.
// =====================================================================
class RS_GH_PistolLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 16; Ammo.BackpackMaxAmount 16; +INVENTORY.IGNORESKILL } }
class RS_GH_PistolLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 16; Ammo.BackpackMaxAmount 16; +INVENTORY.IGNORESKILL } }
class RS_GH_PistolLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 16; Ammo.BackpackMaxAmount 16; +INVENTORY.IGNORESKILL } }
class RS_GH_PistolLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 16; Ammo.BackpackMaxAmount 16; +INVENTORY.IGNORESKILL } }
class RS_GH_PistolLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 16; Ammo.BackpackMaxAmount 16; +INVENTORY.IGNORESKILL } }
class RS_GH_PistolLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 16; Ammo.BackpackMaxAmount 16; +INVENTORY.IGNORESKILL } }
class RS_GH_RevolverLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RevolverLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RevolverLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RevolverLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RevolverLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RevolverLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_PumpShotgunLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 9; Ammo.BackpackMaxAmount 9; +INVENTORY.IGNORESKILL } }
class RS_GH_PumpShotgunLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 9; Ammo.BackpackMaxAmount 9; +INVENTORY.IGNORESKILL } }
class RS_GH_PumpShotgunLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 9; Ammo.BackpackMaxAmount 9; +INVENTORY.IGNORESKILL } }
class RS_GH_PumpShotgunLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 9; Ammo.BackpackMaxAmount 9; +INVENTORY.IGNORESKILL } }
class RS_GH_PumpShotgunLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 9; Ammo.BackpackMaxAmount 9; +INVENTORY.IGNORESKILL } }
class RS_GH_PumpShotgunLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 9; Ammo.BackpackMaxAmount 9; +INVENTORY.IGNORESKILL } }
class RS_GH_AssaultShotgunLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 20; Ammo.BackpackMaxAmount 20; +INVENTORY.IGNORESKILL } }
class RS_GH_AssaultShotgunLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 20; Ammo.BackpackMaxAmount 20; +INVENTORY.IGNORESKILL } }
class RS_GH_AssaultShotgunLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 20; Ammo.BackpackMaxAmount 20; +INVENTORY.IGNORESKILL } }
class RS_GH_AssaultShotgunLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 20; Ammo.BackpackMaxAmount 20; +INVENTORY.IGNORESKILL } }
class RS_GH_AssaultShotgunLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 20; Ammo.BackpackMaxAmount 20; +INVENTORY.IGNORESKILL } }
class RS_GH_AssaultShotgunLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 20; Ammo.BackpackMaxAmount 20; +INVENTORY.IGNORESKILL } }
class RS_GH_SSGLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 2; Ammo.BackpackMaxAmount 2; +INVENTORY.IGNORESKILL } }
class RS_GH_SSGLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 2; Ammo.BackpackMaxAmount 2; +INVENTORY.IGNORESKILL } }
class RS_GH_SSGLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 2; Ammo.BackpackMaxAmount 2; +INVENTORY.IGNORESKILL } }
class RS_GH_SSGLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 2; Ammo.BackpackMaxAmount 2; +INVENTORY.IGNORESKILL } }
class RS_GH_SSGLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 2; Ammo.BackpackMaxAmount 2; +INVENTORY.IGNORESKILL } }
class RS_GH_SSGLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 2; Ammo.BackpackMaxAmount 2; +INVENTORY.IGNORESKILL } }
class RS_GH_RifleLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 31; Ammo.BackpackMaxAmount 31; +INVENTORY.IGNORESKILL } }
class RS_GH_RifleLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 31; Ammo.BackpackMaxAmount 31; +INVENTORY.IGNORESKILL } }
class RS_GH_RifleLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 31; Ammo.BackpackMaxAmount 31; +INVENTORY.IGNORESKILL } }
class RS_GH_RifleLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 31; Ammo.BackpackMaxAmount 31; +INVENTORY.IGNORESKILL } }
class RS_GH_RifleLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 31; Ammo.BackpackMaxAmount 31; +INVENTORY.IGNORESKILL } }
class RS_GH_RifleLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 31; Ammo.BackpackMaxAmount 31; +INVENTORY.IGNORESKILL } }
class RS_GH_SMGLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 41; Ammo.BackpackMaxAmount 41; +INVENTORY.IGNORESKILL } }
class RS_GH_SMGLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 41; Ammo.BackpackMaxAmount 41; +INVENTORY.IGNORESKILL } }
class RS_GH_SMGLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 41; Ammo.BackpackMaxAmount 41; +INVENTORY.IGNORESKILL } }
class RS_GH_SMGLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 41; Ammo.BackpackMaxAmount 41; +INVENTORY.IGNORESKILL } }
class RS_GH_SMGLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 41; Ammo.BackpackMaxAmount 41; +INVENTORY.IGNORESKILL } }
class RS_GH_SMGLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 41; Ammo.BackpackMaxAmount 41; +INVENTORY.IGNORESKILL } }
class RS_GH_MP40Loaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 32; Ammo.BackpackMaxAmount 32; +INVENTORY.IGNORESKILL } }
class RS_GH_MP40Loaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 32; Ammo.BackpackMaxAmount 32; +INVENTORY.IGNORESKILL } }
class RS_GH_MP40Loaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 32; Ammo.BackpackMaxAmount 32; +INVENTORY.IGNORESKILL } }
class RS_GH_MP40Loaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 32; Ammo.BackpackMaxAmount 32; +INVENTORY.IGNORESKILL } }
class RS_GH_MP40Loaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 32; Ammo.BackpackMaxAmount 32; +INVENTORY.IGNORESKILL } }
class RS_GH_MP40Loaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 32; Ammo.BackpackMaxAmount 32; +INVENTORY.IGNORESKILL } }
class RS_GH_RocketLauncherLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RocketLauncherLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RocketLauncherLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RocketLauncherLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RocketLauncherLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_RocketLauncherLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 6; Ammo.BackpackMaxAmount 6; +INVENTORY.IGNORESKILL } }
class RS_GH_GrenadeLauncherLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 1; Ammo.BackpackMaxAmount 1; +INVENTORY.IGNORESKILL } }
class RS_GH_GrenadeLauncherLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 1; Ammo.BackpackMaxAmount 1; +INVENTORY.IGNORESKILL } }
class RS_GH_GrenadeLauncherLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 1; Ammo.BackpackMaxAmount 1; +INVENTORY.IGNORESKILL } }
class RS_GH_GrenadeLauncherLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 1; Ammo.BackpackMaxAmount 1; +INVENTORY.IGNORESKILL } }
class RS_GH_GrenadeLauncherLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 1; Ammo.BackpackMaxAmount 1; +INVENTORY.IGNORESKILL } }
class RS_GH_GrenadeLauncherLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 1; Ammo.BackpackMaxAmount 1; +INVENTORY.IGNORESKILL } }
class RS_GH_PlasmaLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_PlasmaLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_PlasmaLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_PlasmaLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_PlasmaLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_PlasmaLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_RailgunLoaded : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_RailgunLoaded2 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_RailgunLoaded3 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_RailgunLoaded4 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_RailgunLoaded5 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
class RS_GH_RailgunLoaded6 : Ammo { Default { Inventory.Amount 1; Inventory.MaxAmount 50; Ammo.BackpackMaxAmount 50; +INVENTORY.IGNORESKILL } }
