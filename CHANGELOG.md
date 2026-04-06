# Changelog

## 2026-04-06 (rev 8)
### Changed
- DTI body parts now use solid `Color3` skin tone instead of `SurfaceAppearance` textures. SurfaceAppearance from the DTI model caused blue/purple skin tint because the baked textures didn't render correctly outside the DTI game context.
- Head kept as default R15 (not replaced by DTI head) with `HeadScale = 0.65` to match DTI body proportions. Head color explicitly set to match DTI body skin tone.
- DTI clothing meshes from `EquippedAccessories` folder are now cached during model load and welded onto the character post-spawn (Phase 3 of `applyDTIBody`).
- Classic `Shirt`/`Pants` instances removed from DTI characters post-spawn (incompatible UV mapping).
- `buildDescription` skips classic clothing assignment for DTI outfits.
- Female `ProportionScale` changed to 10 (wider proportions for DTI body).

## 2026-04-06 (rev 7)
### Added
- `CharacterCreator.luau` server module: gender-based character spawning with DTI (Dress to Impress) body mesh support. Female characters use MeshParts loaded from Creator Store model (asset 90731674309295) via `InsertService:LoadAsset`. Body parts are cloned and swapped post-spawn with Motor6D joint reconnection and C0/C1 offset correction. Male characters use the standard "Man" body bundle (238).
- `PlayerData.luau` server module: persistent player profiles via ProfileService (`PlayerData_v4` DataStore). Tracks character creation state, gender, stats (coins, play time, session count), and settings. Syncs `CharacterCreated` BoolValue to client for UI gating.
- `ProfileService.luau`: third-party DataStore wrapper by loleris/madwork.
- Gender selection UI on client: dual-button modal (Female pink / Male purple) shown for new players or when `NewPlayer` flag is true.
- Death respawn handler: re-spawns with saved outfit after 3-second delay.
- Session duration tracking: `TotalPlayTime` updated on player leave.

### Changed
- `CharacterAutoLoads = false` moved to before all `require`/`WaitForChild` calls to prevent default avatar flash from race conditions.
- Camera intro simplified from 2.5s elevated pan to instant `CameraType.Custom` handoff.
- `NewPlayer` feature flag default changed to `false` (was `true`). When false, returning players keep their saved gender choice.
- Character spawning uses `LoadCharacterWithHumanoidDescription` instead of `LoadCharacter` + `ApplyDescription` to eliminate the double-load flash.
- Female outfit config changed from bundle-based (`BundleIds`) to DTI model-based (`DTIModelId`, `DTIRig`). DTI bundles (1594017, 387180) failed with HTTP 400; replaced with Creator Store model approach.
- Clothing IDs verified and corrected: Roblox Pink Shirt (855773575), Black Jeans (398633812), ROBLOX Jacket (607785314). Previous IDs were SolidModel assets, not clothing.
- Body colors (HeadColor, TorsoColor, etc.) now copied from bundle descriptions to prevent all-black avatar.

## 2026-04-05 (rev 6)
### Added
- `Maintenance` feature flag (default `false`). When enabled via Firebase, the server kicks all connected players, blocks new joins with a maintenance message, and halts further server initialization.

## 2026-04-05 (rev 5)
### Added
- `FeatureFlags.luau` server module: fetches remote flag overrides from Firebase Realtime Database (`/config/featureFlags.json`), falls back to `Constants.FeatureFlags` defaults, syncs flag values to clients via StringValue instances in `ReplicatedStorage/FeatureFlags`.
- `Constants.FeatureFlags` defaults: `NPCsEnabled`, `MusicEnabled`, `IntroScreenEnabled`, `NewPlayer`.
- Server gates NPC spawning behind `NPCsEnabled` flag.
- Client gates background music behind `MusicEnabled` flag and intro screen behind `IntroScreenEnabled` flag. When intro is disabled, character spawns immediately.

## 2026-04-05 (rev 4)
### Added
- Intro screen with full-screen background image (`Constants.IntroScreen.ImageId`), animated purple-to-pink galaxy sparkle fill, and `UIAspectRatioConstraint` for cross-device scaling. Invisible hitboxes over graphic's PLAY/CUSTOMIZE/SHOP buttons.
- "Coming Soon!" popup for CUSTOMIZE and SHOP buttons.
- Character spawn gated behind PLAY button (`CharacterAutoLoads = false`, `PlayerReady` RemoteEvent).
- Looping background music starting on intro screen (`Constants.Music.SoundId`).
- Persistent settings menu (gear icon, top-right) with volume and brightness sliders, visible on intro and in-game.
- Sittable chairs: arcade table and lounge area use `Seat` instances with proper seat/backrest/leg geometry.
- NPC screen-watching behavior (face nearby screens for 4-12s) and chair-sitting behavior (25% chance, 6-15s in empty seats).
- Global `ScriptContext.Error` handler logging all unhandled errors to Firebase.

### Changed
- Rebuilt arcade and lounge furniture with proper chairs (seat + backrest + 4 legs) arranged around tables.
- Fixed chair orientation (backrests now face away from tables).
- Fixed stage tower screens: rotated 180° to face audience, repositioned flush on pillar front face.

## 2026-04-05 (rev 3)
### Changed
- Rewrote NPCSpawner: builds one R6 rig template and clones it instead of 760 `Instance.new()` calls. Switched from `CreateHumanoidModelFromDescription` (network-dependent) to local Part-based rigs.
- Added PhysicsService collision groups (NPCs, Players, Default) so NPCs pass through each other and players while still standing on floors/walls.
- Rewrote FirebaseLogger: caches enabled state and base URL at startup, strips trailing slash from database URL.
- Removed unused `Constants.NPC.AnimationIds`, reduced NPC count from 40 to 20.
- Removed stale `SocialPlaza` cleanup from MapBuilder.
- Added global `ScriptContext.Error` handler to log all unhandled script errors to Firebase.
- Fixed stage tower screens facing backwards (rotated 180°) and clipping into pillars (repositioned to front face).
- Removed `Lighting.Technology` write (Studio-only property, now set only via `default.project.json`).

## 2026-04-05 (rev 2)
### Changed
- Repositioned grand staircases to center X=±55 (width 18, inner edge X=±46) so they connect directly to balconies. 16 brown tread steps from Z=-18 Y=1 to Z=-66 Y=24.
- Moved balcony inner edges from X=±66 to X=±46 so platforms are visible from the plaza floor. Added back balcony at Y=30 bridging above the stage.
- Relocated billboard screens from far side walls (X=±107) to stage tower flanks (angled 28° toward crowd), staircase inner walls, and upper back wall — 7 total decorated screens.
- Overhauled lighting to eliminate white blowout: Brightness 0.6, bloom threshold 0.92 (was 0.75), removed all floor SurfaceLights/uplights, reduced auto-PointLight multiplier to 0.005 (was much higher), capped brightness at 0.4 and range at 12.
- Toned NeonWhite from bright lavender (255, 230, 255) to soft (210, 185, 225).
- Changed sign to 3-line stacked layout: "SOCIAL / SPOTLIGHT / PLAZA" on 32×10 backing panel.
- Added support columns under balconies and glass railings with neon top rails.
- Added 4 corner ambient PointLights (brightness 0.4, range 20) and 9 sparse ceiling panels (brightness 0.3).

## 2026-04-05
### Added
- `FirebaseLogger.luau` module for structured logging to Firebase Realtime Database via REST API. Fire-and-forget async posting with `startTimer()` helper for elapsed-time tracking.
- `Constants.Firebase` config block (`DatabaseUrl`, `Enabled`) to toggle logging.
- Log events across all server modules: server startup, map build timing, lighting setup, NPC spawn results, player join/leave with session duration.
- Client-to-server log forwarding via `RemoteEvent` (`FirebaseLogEvent`) for client ready and camera intro events.

### Changed
- Switched from static `Workspace.SocialPlaza` geometry back to procedural generation to match the reference concept art.
- Rewrote `MapBuilder.luau` (1290 lines, 10 build phases) with complete indoor venue: enclosed walls/ceiling, keyhole floor design, tiered pink stage with portal circle, grand staircases with individual brown tread steps and metal railings, balconies with glass railings, 6 wall-mounted billboard screens, side props (arcade station, food truck, curved seating, selfie booths), neon lighting strips throughout, and "SOCIAL SPOTLIGHT PLAZA" sign.
- Rewrote `ScreenGenerator.luau` to produce cyan-blue billboard content with avatar silhouettes, banner text, and social media styling.
- Rewrote `LightingController.luau` with pink/purple neon atmosphere: bloom, color correction, atmosphere haze, and auto PointLight attachment to neon parts.
- Updated `NPCSpawner.luau` with error handling, varied display names, wider spawn distribution, and pcall protection.
- Expanded `Constants.luau` from 9 to 28 named colors covering all materials in the scene.
- Activated `init.server.luau` to orchestrate MapBuilder → LightingController → NPCSpawner.
- Added `init.client.luau` cinematic intro camera with smooth ease-out transition.
- Cleaned `default.project.json`: removed all static SocialPlaza parts, kept script paths and Lighting defaults.
- Added 5 SpawnLocations near the entrance.

## 2024-05-14
### Added
- Replaced all procedural generation with a static `Workspace.SocialPlaza` layout inside `default.project.json`, including the floor grid, neon runway, stacked stage + central screen, side screens, stair and balcony volumes, kiosks, selfie booths, speaker pillars, and food truck.
- Simplified server/client scripts (they now only print readiness messages) so the level is purely visual.
- Updated README and documentation to describe the manual editing workflow.
