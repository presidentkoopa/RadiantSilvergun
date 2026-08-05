================================================================================
   COLOURFUL HELL *PLUS* BUILDS -- QUARANTINE.  DO NOT WORK IN THIS FOLDER.
   Moved here 2026-08-05 at the owner's direction: "move the CHP shit into
   another folder and stay the fuck away from it."
================================================================================

WHAT THIS IS

  Nineteen files, sixteen monster families, all built from COLOURFUL HELL
  PLUS (CHP) by earlier import attempts. Every stat in them is CHP's, not
  Colourful Hell's.

  They are still INCLUDED and still RUNNING -- deleting them would leave
  the mod with no monsters for sixteen of seventeen families. They are
  quarantined so that nobody mistakes them for finished work and nobody
  reads a number out of them believing it came from CH.

WHY THAT MATTERS

  CHP is a separate add-on that INHERITS Colourful Hell's actors and
  re-stats them. Building from it produced numbers that are CHP's
  overrides, not CH's originals -- e.g. CH's green chaingunner is
  Health 85 and CHP's is 90; the tree shipped 90 for eight attempts.

  The project is now a CH-ONLY import. CHP is a LATER, SEPARATE layer.

THE RULE

  DO NOT EDIT ANYTHING IN HERE. Not to fix a bug, not to correct a stat,
  not to tidy. Every file in this folder is scheduled for deletion, and
  work spent on it is work thrown away.

  A family leaves this folder by being REBUILT FROM CH, not by being
  corrected. See docs/rs_29_ch_import_law.txt, and
  zscript/monsters/chaingunner/ for the worked example.

HOW A FAMILY LEAVES

  1. Rebuild from E:\New folder\ART SOURCE\CH\decorate\<Family>.txt,
     one class per creature, into zscript/monsters/<family>/
  2. Leave a five-line abstract base at zscript/monsters/RS_<Family>.zs
     holding only the RS-side mechanics (keywords, minion cleanup, rage)
  3. Repoint every reference, update zscript.txt
  4. DELETE the file from this folder

  Family 04 (chaingunner) did exactly this and is out.

STILL IN HERE -- 16 FAMILIES

  RS_Shotgunner  RS_BlackSGTrooper  RS_Imp        RS_Demon
  RS_Spectre     RS_LostSoul        RS_Cacodemon  RS_PainElemental
  RS_Baron       RS_HellKnight      RS_Revenant   RS_Mancubus
  RS_Arachnotron RS_Archvile        RS_Mastermind RS_Cyberdemon
  plus RS_Minions, RS_MonsterStages, RS_ExBosses (cross-family CHP content)

NOT IN HERE, AND NOT CHP

  zscript/monsters/RS_MonsterMaster.zs    the tier/behaviour system, ours
  zscript/monsters/RS_MonsterCommands.zs  CH's ACS rebuilt as ZScript
  zscript/monsters/RS_Chaingunner.zs      family 04's base class, ours
  zscript/monsters/chaingunner/           family 04, CH-only
  zscript/monsters/Zombieman/             family 01, its own layout
  zscript/monsters/monsterfx/             the projectile library -- MIXED.
      267 damage rolls and family 04's 38 projectiles were corrected to
      CH on 2026-08-05; the rest is still CHP-derived and is corrected
      per-family as each family is rebuilt.
================================================================================
