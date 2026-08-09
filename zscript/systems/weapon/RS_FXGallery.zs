// =====================================================================
// RS_FXGallery -- look at the FX. Several at once, in world space.
// ---------------------------------------------------------------------
// Built 2026-08-08 at the owner's direction: "we need to see multiple of
// these at the same time, to arrange them in 3d space".
//
// THIS IS THE THING THAT UNBLOCKS THE CATALOG. docs/rs_MASTER_FX_CATALOG
// .txt has six content sections and every one of them reads "(pending
// inventory pass)" -- the descriptors were never written, and its own
// header says why: doing it means "re-viewing several thousand sprite
// frames by hand". Nobody could see them. A sprite name is not a
// description, and this project has already been burned by assuming it
// is (the catalog's own header records 40 sprites assumed to be revolver
// muzzle flashes from their filename prefix; they were unrelated voxel
// content).
//
// So: spawn them in a grid, in front of the player, labelled, and look.
//
// ---------------------------------------------------------------------
// USAGE
//
//   rs_fx_gallery <axis> [theme]
//
//     axis  -- 0 projectile, 1 casing, 2 muzzle, 3 smoke, 4 sound,
//              5 puff, 6 sparks, 7 trail, 8 payload
//     theme -- 0 fire, 1 ice, 2 plasma, 3 poison, 4 lightning,
//              5 psychic, 6 void, 7 impact. Omit or -1 for all themes.
//
//   rs_fx_clear     remove everything the gallery spawned
//
// Example: rs_fx_gallery 7      every trail in the registry, side by side
//          rs_fx_gallery 5 0    every fire-themed impact puff
// =====================================================================

// One pedestal: the effect itself plus a floating label, so a grid of
// twenty is readable rather than a wall of anonymous sparks.
class RS_FXGalleryPedestal : Actor
{
	string  mLabel;
	Class<Actor> mShow;
	int     mReplayTimer;

	Default
	{
		Radius 4;
		Height 8;
		+NOGRAVITY
		+NOINTERACTION
		+DONTSPLASH
		RenderStyle "None";
	}

	void Setup(Class<Actor> show, string label)
	{
		mShow = show;
		mLabel = label;
		mReplayTimer = 0;
	}

	// Most FX are one-shot -- they animate for a few tics and Stop. A
	// gallery of corpses is useless, so each pedestal RESPAWNS its effect
	// on a cycle. That is also how you judge a trail bit or an impact
	// puff honestly: by watching it play repeatedly, not by catching one
	// frame of it.
	override void Tick()
	{
		Super.Tick();
		if (!mShow)
			return;

		if (--mReplayTimer <= 0)
		{
			mReplayTimer = 35;   // one second
			Actor a = Spawn(mShow, pos, ALLOW_REPLACE);
			if (a)
			{
				// Kill velocity: a trail bit or a projectile body would
				// otherwise fly off the pedestal and out of the room.
				// The gallery is about what a thing LOOKS like, not where
				// it goes.
				a.Vel = (0, 0, 0);
				a.bNOGRAVITY = true;
				a.bNOINTERACTION = true;
				a.A_SetSize(1, 1);
			}
		}
	}
}

class RS_FXGalleryHandler : EventHandler
{
	// Everything spawned by the last gallery call, so rs_fx_clear can
	// take it all away without touching anything else in the level.
	Array<Actor> mSpawned;

	// Billboard HANDLES, not billboards. There is no ClearBillboards() --
	// the engine exposes AddBillboardPersistent() returning an id and
	// RemoveBillboard(id), so labels have to be tracked individually or
	// they cannot be taken back. A transient billboard would expire on
	// its own but could not be cleared on demand, and a gallery you
	// cannot dismiss is worse than no gallery.
	Array<int> mLabels;

	override void NetworkProcess(ConsoleEvent e)
	{
		Super.NetworkProcess(e);

		if (e.Name == "rs_fx_clear")
		{
			ClearGallery();
			Console.Printf("\c[GOLD][RS FX]\c- gallery cleared.");
			return;
		}

		if (e.Name != "rs_fx_gallery")
			return;

		let pawn = players[e.Player].mo;
		if (!pawn)
			return;

		int axis  = e.Args[0];
		int theme = (e.Args[1] != 0 || e.Args[2] != 0) ? e.Args[1] : -1;

		if (axis < 0 || axis >= RS_FXRegistry.RS_FXAXIS_COUNT)
		{
			Console.Printf("\c[RED][RS FX]\c- axis must be 0..%d",
				RS_FXRegistry.RS_FXAXIS_COUNT - 1);
			return;
		}

		Array<RS_FXEntry> hits;
		RS_FXRegistry.Query(axis, theme, hits);

		ClearGallery();

		if (hits.Size() == 0)
		{
			Console.Printf("\c[YELLOW][RS FX]\c- nothing registered for axis %s%s.",
				RS_FXRegistry.AxisName(axis),
				theme >= 0 ? (", theme " .. RS_PACKCatalog.ThemeName(theme)) : "");
			return;
		}

		Console.Printf("\c[GOLD][RS FX]\c- %s%s -- %d entries",
			RS_FXRegistry.AxisName(axis),
			theme >= 0 ? (" / " .. RS_PACKCatalog.ThemeName(theme)) : " / all themes",
			hits.Size());

		SpawnGrid(pawn, hits);
	}

	// A grid laid out in front of the player, on the plane they are
	// facing. Rows of five, because a row of twenty is a line you have to
	// walk rather than a set you can compare at a glance.
	private void SpawnGrid(PlayerPawn pawn, Array<RS_FXEntry> hits)
	{
		const COLS    = 5;
		const SPACING = 48.0;
		const STANDOFF = 160.0;

		double yaw = pawn.angle;
		Vector3 fwd = (cos(yaw), sin(yaw), 0);
		Vector3 rgt = (cos(yaw - 90), sin(yaw - 90), 0);
		Vector3 base = pawn.pos + fwd * STANDOFF + (0, 0, 40);

		for (int i = 0; i < hits.Size(); i++)
		{
			int col = i % COLS;
			int row = i / COLS;

			// Centre each row on the player rather than running off to
			// one side.
			double xoff = (col - (COLS - 1) * 0.5) * SPACING;
			double zoff = -row * SPACING;

			Vector3 at = base + rgt * xoff + (0, 0, zoff);

			let ped = RS_FXGalleryPedestal(Actor.Spawn("RS_FXGalleryPedestal", at));
			if (!ped)
				continue;

			ped.Setup(hits[i].Cls, hits[i].Id);
			mSpawned.Push(ped);

			// The label. Billboards carry their colour correctly as of
			// the engine fix on 2026-08-08 -- before that every one of
			// these would have rendered white regardless.
			Label(at + (0, 0, 18.0), hits[i].Id);
		}

		Console.Printf("\c[GOLD][RS FX]\c- 'rs_fx_clear' to remove.");
	}

	// Signature, verified against the engine rather than assumed:
	//   AddBillboardPersistent(pos, w, h, yaw, tilt, facing, payload,
	//                          data, col, flags, lifetime, text) -> id
	private void Label(Vector3 at, string text)
	{
		if (!level)
			return;

		// One BB_GLYPH per character, laid out along the viewer's right.
		// Small and close-spaced: these are captions, not signage.
		double h = 6.0;
		double pitch = h * 0.62;
		double startX = -(pitch * text.Length()) * 0.5;

		for (int i = 0; i < text.Length(); i++)
		{
			int ch = text.ByteAt(i);
			if (ch == 32)
				continue;

			// BBF_CAMERAYAW so a caption turns to face the viewer as they
			// walk the grid -- a fixed-yaw label goes edge-on and vanishes,
			// which is the exact failure the trail bits carry
			// FORCEXYBILLBOARD to avoid.
			int id = level.AddBillboardPersistent(
				at + (startX + pitch * i, 0, 0),
				pitch, h,
				0, 0,
				LevelLocals.BBF_CAMERAYAW,
				LevelLocals.BB_GLYPH, ch,
				Color(255, 235, 225, 200));
			if (id != 0)
				mLabels.Push(id);
		}
	}

	private void ClearGallery()
	{
		for (int i = 0; i < mSpawned.Size(); i++)
			if (mSpawned[i])
				mSpawned[i].Destroy();
		mSpawned.Clear();

		// Billboards are not actors and are not in mSpawned -- they are
		// handles held by the level, removed one at a time.
		if (level)
			for (int i = 0; i < mLabels.Size(); i++)
				level.RemoveBillboard(mLabels[i]);
		mLabels.Clear();
	}
}
