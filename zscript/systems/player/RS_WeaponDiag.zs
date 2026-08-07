// =====================================================================
// RS_WeaponDiag -- disposable. Prints both hands' weapon state to the
// console every tic for the first stretch after spawn, automatically,
// no toggle needed -- so it lands in +logfile output without the
// player having to do anything.
//
// Each line, per tic:
//   READY / OFFHAND / PENDING  -- which weapon each pointer holds
//   PSP_WEAPON / PSP_OFFHANDWEAPON -- whether that hand's psprite
//     actually EXISTS at all, and its .y (raise/lower position).
//     No psprite means that hand was never brought up -- no raise
//     animation, no ready state, nothing. That's the exact gap this
//     file exists to make visible.
//
// Disposable -- delete this file, its include line and its MAPINFO
// name and it never existed.
// =====================================================================
class RS_WeaponDiag : EventHandler
{
	int mTicks;
	const MAX_TICKS = 45; // spans past RS_OffhandSeat's 35-tic retry budget

	static string WeaponName(Weapon w)
	{
		if (!w) return "null";
		return w.GetClassName() .. "";
	}

	static string PendingName(PlayerInfo p)
	{
		if (p.PendingWeapon == WP_NOCHANGE) return "WP_NOCHANGE";
		if (!p.PendingWeapon) return "null";
		return p.PendingWeapon.GetClassName() .. "";
	}

	static string PSpriteInfo(PSprite psp)
	{
		if (!psp) return "NONE";
		return String.Format("y=%.1f", psp.y);
	}

	override void WorldTick()
	{
		if (mTicks >= MAX_TICKS) return;

		PlayerInfo p = players[consoleplayer];
		if (!p || !p.mo) return;

		mTicks++;

		let mainPsp = p.GetPSprite(PSP_WEAPON);
		let offPsp  = p.GetPSprite(PSP_OFFHANDWEAPON);

		Console.Printf("RS_DIAG tic %d: Ready=%s Offhand=%s Pending=%s | PSP_WEAPON=%s PSP_OFFHANDWEAPON=%s",
			mTicks,
			WeaponName(p.ReadyWeapon),
			WeaponName(p.OffhandWeapon),
			PendingName(p),
			PSpriteInfo(mainPsp),
			PSpriteInfo(offPsp));
	}
}
