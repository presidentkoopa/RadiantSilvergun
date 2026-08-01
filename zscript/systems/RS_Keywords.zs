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
}
