// =====================================================================
// RS_Keywords -- string-parsing utility for the keyword system.
// ---------------------------------------------------------------------
// See docs/rs_03_keywords_v2.txt for the full schema. Syntax: space-
// delimited "key:value" tokens, e.g. "archetype:pistol trigger:semiauto
// payload:single". Multi-value keys just repeat ("trigger:semiauto
// trigger:burst"). Pure string parsing, no state -- the actual BASE/
// GRANTED storage and query API lives on RS_Weapon (RS_Weapon.zs), this
// is just the tokenizer both layers share.
// =====================================================================

class RS_Keywords
{
	static bool StringHas(string kwString, string key, string value)
	{
		Array<string> tokens;
		kwString.Split(tokens, " ");
		string needle = key .. ":" .. value;
		for (int i = 0; i < tokens.Size(); i++)
			if (tokens[i] == needle)
				return true;
		return false;
	}

	// Last matching token wins -- callers only use this for genuinely
	// single-value keys, where "last" just means "only."
	static string GetValue(string kwString, string key)
	{
		Array<string> tokens;
		kwString.Split(tokens, " ");
		string prefix = key .. ":";
		string result = "";
		for (int i = 0; i < tokens.Size(); i++)
			if (tokens[i].Left(prefix.Length()) == prefix)
				result = tokens[i].Mid(prefix.Length());
		return result;
	}

	static void GetValues(string kwString, string key, out Array<string> results)
	{
		Array<string> tokens;
		kwString.Split(tokens, " ");
		string prefix = key .. ":";
		for (int i = 0; i < tokens.Size(); i++)
			if (tokens[i].Left(prefix.Length()) == prefix)
				results.Push(tokens[i].Mid(prefix.Length()));
	}

	// The documented key set -- see RS_KeywordIndex.zs -- plus "curse" and
	// "characteristic" from RS_Weapon.zs's own GetKeywordValue(s) doc
	// comment. Purely a typo net: a key that's missing from this list
	// doesn't stop anything from working, it just means Validate() below
	// will log about it. Add to this list when a real new key ships;
	// don't "fix" a call site to match this list instead.
	// Plain comparison chain, not a static const array -- this engine
	// build doesn't resolve `static const string X[] = {...}` reliably.
	static bool IsKnownKey(string key)
	{
		return key == "archetype" || key == "set" || key == "trigger"
			|| key == "grip" || key == "delivery" || key == "payload"
			|| key == "behavior" || key == "element" || key == "feed"
			|| key == "sockets" || key == "reserve" || key == "promotion"
			|| key == "curse" || key == "characteristic"
			// monster-side keys -- see RS_MonsterKeywordIndex.zs. Shared
			// parser/validator, not forked, same as "set"/"delivery"/
			// "payload"/"element" above being reused by both domains.
			|| key == "species" || key == "role" || key == "mobility"
			|| key == "trait";
	}

	// Debug-only typo check, gated on rs_debug_validate_keywords (off by
	// default). Logs a console warning for any "key:value" token whose
	// key isn't in KnownKeys, or that's missing the colon entirely.
	// Doesn't touch, validate, or gate VALUES -- see RS_KeywordIndex.zs's
	// per-key notes for which values are real vs reserved vs cut; that
	// list changes too often to hardcode here without constant upkeep.
	// context is a label (the weapon's class name) so a hit is
	// actionable. Nothing calls this in a hot path -- see
	// RS_Weapon.PostBeginPlay's once-per-class guarded call.
	static void Validate(string kwString, string context)
	{
		if (!CVar.GetCVar("rs_debug_validate_keywords", null).GetBool())
			return;

		Array<string> tokens;
		kwString.Split(tokens, " ");
		for (int i = 0; i < tokens.Size(); i++)
		{
			string tok = tokens[i];
			int colon = tok.IndexOf(":");
			if (colon <= 0)
			{
				console.printf("RS_Keywords: %s -- malformed token \"%s\" (no key:value colon)", context, tok);
				continue;
			}
			string key = tok.Left(colon);
			if (!IsKnownKey(key))
				console.printf("RS_Keywords: %s -- unknown keyword key \"%s\" (token \"%s\") -- typo?", context, key, tok);
		}
	}
}
