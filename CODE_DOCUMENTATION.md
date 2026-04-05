# Code Documentation

The plaza is now authored entirely inside `default.project.json` under `Workspace.SocialPlaza`. There is no procedural build step—the moment Rojo syncs, the geometry appears in Studio.

## Layout Summary
- **Floor & Runway**: `Floor`, `FloorBorder`, `RunwayStem`, and `RunwayHead` establish the glossy base and neon keyhole pattern.
- **Stage Wall**: `StageBase`, `StageTier`, `StageTop`, `Podium`, `BackdropFrame`, `BackdropPanel`, `BackdropCircle`, and the `MainScreen*` parts recreate the magenta stage stack and center LED.
- **Side Screens & Rear Screens**: parts named `SideScreen*` and `RearScreen*` represent the additional billboards.
- **Staircases & Balconies**: `GrandStairLeft/Right`, `Balcony*` parts block out the twin stair volumes and upper rails.
- **Props**: kiosks, selfie booths, ring lights, speaker pillars, and the food truck are individual parts near the social ring.

## Scripts
- `src/server/init.server.luau` and `src/client/init.client.luau` are empty placeholders; no runtime logic runs today.

## Editing Flow
Use Studio + Rojo to nudge parts into the exact positions you want. Because everything lives in `default.project.json`, edits made in Studio will be reflected when you pull the file back through Rojo.
