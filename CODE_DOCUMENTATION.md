# Code Documentation

## Overview

The Social Spotlight Plaza is built entirely at runtime via server scripts. When the game starts, `init.server.luau` calls three modules in sequence to construct the environment, apply lighting, and spawn NPCs.

## Module Reference

### MapBuilder (`src/server/Modules/MapBuilder.luau`)

The core geometry builder. Constructs the entire plaza using Roblox Part primitives (Blocks, Cylinders, WedgeParts) with Neon and SmoothPlastic materials.

**Build phases** (each is an isolated function):

| Phase | Function | What it creates |
|-------|----------|-----------------|
| 1 | `buildFoundation` | Floor (220x220), grid lines, 4 enclosing walls (with entrance gap), ceiling, neon border strips |
| 2 | `buildKeyhole` | Neon keyhole floor design: circle ring (outer/inner cylinder), stem outline (4 strips), cross pattern |
| 3 | `buildStage` | 3-tier stage platform, front approach steps, back wall panel, flanking tower structures, portal circle with neon ring and cross dividers, main screen, ceiling spotlights (brightness 1.5) |
| 4 | `buildStaircases` | Left/right grand staircases (center X=±55, width 18): 16 brown tread steps, solid riser body, inner wall with mounted screen, metal railing posts, handrails with neon accent strips. Bottom Z=-18 Y=1 → Top Z=-66 Y=24 connecting to balconies |
| 5 | `buildBalconies` | Left/right platforms (inner edge X=±46, Y=24) + back balcony (Y=30) bridging above stage. Glass railings with neon top rails, support columns, upper equipment mounts |
| 6 | `buildScreens` | 4 additional screens: 2 on stage tower flanks (angled 28° toward crowd), 2 on upper back wall flanking sign. Plus 2 stair-mounted screens from Phase 4 and 1 main screen from Phase 3 = 7 total |
| 7 | `buildProps` | Arcade station (table + chairs + screen), gaming kiosks, food truck (body + cab + roof + wheels + serving window), curved seating area, selfie booths with ring lights, speakers, decorative bollards |
| 8 | `buildLighting` | Wall neon strips (base, mid, top — no added lights, neon self-illuminates), sparse ceiling panels (9 total, brightness 0.3), 4 corner ambient PointLights (brightness 0.4, range 20) |
| 9 | `buildSign` | "SOCIAL SPOTLIGHT PLAZA" stacked 3-line SurfaceGui text on 32x10 backing panel with neon borders |
| 10 | `buildSpawns` | 5 SpawnLocation parts near the entrance |

**Returns**: `{ hub, navPoints, floor, stage }` — the hub Model, navigation points array, floor Part, and stage Part.

**Helper functions**: `makePart`, `makeNeon`, `makeCylinder`, `makeWedge`, `addPointLight`, `addSurfaceLight`, `addSpotLight`, `addTextGui`.

### ScreenGenerator (`src/server/Modules/ScreenGenerator.luau`)

Decorates billboard Parts with SurfaceGui content matching the cyan digital display aesthetic.

- **Background**: Bright cyan with gradient overlay
- **Content**: Banner text ("FEATURED CREATORS" / "NOW TRENDING" / "SPOTLIGHT"), 3-5 avatar silhouettes (head + body + hair shapes), bottom info bars, corner accents
- **Faces**: Decorates both Front and Back faces
- **Deterministic**: Uses seeded `Random` for reproducible layouts per screen

### LightingController (`src/server/Modules/LightingController.luau`)

Configures `Lighting` service properties and post-processing effects:

- **Brightness**: 0.6 with EnvironmentDiffuseScale 0.3 / SpecularScale 0.15
- **Ambient**: Deep purple (75, 45, 95) for subdued indoor neon feel
- **BloomEffect**: Intensity 0.5, size 20, threshold 0.92 — only the hottest neon parts bloom
- **ColorCorrectionEffect**: Pink tint (240, 210, 240), brightness -0.02, contrast 0.14, saturation 0.25
- **Atmosphere**: Soft purple haze (density 0.15, glare 0.1, haze 1.2)
- **DepthOfFieldEffect**: Subtle background softening (far 0.12, near 0.06)
- **Auto PointLights**: Scans Neon-material parts (volume > 2) and attaches dim PointLights — brightness clamp(vol×0.005, 0.1, 0.4), range clamp(vol×0.08, 3, 12)

### NPCSpawner (`src/server/Modules/NPCSpawner.luau`)

Spawns crowd NPCs from a cloned R6 rig template (no network dependency):

- **Count**: 20 NPCs (configurable in Constants)
- **Architecture**: Builds one R6 template at module load, clones it per NPC for efficiency
- **Appearance**: Random HSV skin/shirt/pants coloring, R6 rig with face decal
- **Collision**: Uses PhysicsService collision groups — NPCs pass through each other and players, but collide with environment (floors, walls)
- **Behavior**: Wanders between navigation points with random pauses (2-6 seconds), cleanup via `model.Destroying`
- **Safety**: Wrapped in pcall for graceful failure

### CharacterCreator (`src/server/Modules/CharacterCreator.luau`)

Manages character appearance based on gender selection. Uses two approaches depending on gender:

- **Female**: Spawns with `LoadCharacterWithHumanoidDescription` (face, skin color, hair, head scale), then **replaces all R15 body parts (except Head)** with cloned DTI (Dress to Impress) MeshParts loaded from a Creator Store model (`InsertService:LoadAsset`). MeshId is read-only in Roblox, so entire MeshParts are cloned and swapped — Motor6D joints are reconnected and C0/C1 offsets updated to DTI proportions. SurfaceAppearance is stripped from DTI parts; skin color applied via solid `Color3`. Head is kept as default R15 with `HeadScale = 0.65` and head color matched to body. DTI clothing meshes from `EquippedAccessories` are welded onto the character. Classic `Shirt`/`Pants` instances are removed (incompatible UV mapping with DTI meshes).
- **Male**: Uses the standard Roblox "Man" body bundle (238) via `GetBundleDetailsAsync` + `GetHumanoidDescriptionFromOutfitId`.

**Startup**: Loads the DTI model (asset 90731674309295) in a background `task.spawn` during `init()`. Caches clonable MeshPart templates (all children stripped including SurfaceAppearance), Motor6D C0/C1 joint data, and clothing mesh templates with CFrame offsets from `EquippedAccessories`.

**Spawn flow**:
1. `buildDescription(gender)` — creates a `HumanoidDescription` with face, skin color, hair, body scales, head scale (cached per gender). Skips classic clothing for DTI outfits.
2. `spawnWithOutfit(player, gender)` — calls `LoadCharacterWithHumanoidDescription`, then runs `applyDTIBody` for female characters
3. `applyDTIBody(character, rigName, skinColor)` — Phase 1: clones DTI MeshParts with solid skin Color3, moves children (Motor6D, Attachments) from old parts, fixes Part0/Part1 references. Phase 2: updates Motor6D C0/C1 to DTI proportions. Phase 3: clones and welds DTI clothing meshes onto body parts. Also sets head color to match body and removes classic Shirt/Pants.

**API**:

| Method | Signature | Description |
|--------|-----------|-------------|
| `buildDescription` | `(gender: string) → HumanoidDescription?` | Build outfit description (cached) |
| `spawnWithOutfit` | `(player, gender)` | Spawn character with full outfit + DTI body |
| `saveGender` | `(player, gender) → boolean` | Persist gender choice to profile |
| `init` | `(spawnedPlayers)` | Load DTI model, create GenderSelected RemoteEvent |

### PlayerData (`src/server/Modules/PlayerData.luau`)

Persistent player data via ProfileService (DataStore wrapper). Profiles are loaded on join and released on leave.

**Profile template** (`PlayerData_v4`):
```
Character: { Created, Gender, BodyType, SkinColor, HairStyle, HairColor, FaceId, OutfitTop, OutfitBottom, ... }
Stats: { Coins, TotalPlayTime, SessionCount }
Settings: { MusicVolume, Brightness }
```

**Client sync**: Creates a `BoolValue` named `CharacterCreated` on the player so the client knows whether to show the gender selection screen.

**API**:

| Method | Signature | Description |
|--------|-----------|-------------|
| `loadProfile` | `(player)` | Load profile from DataStore, kick on failure |
| `releaseProfile` | `(player)` | Release profile lock |
| `get` | `(player) → data?` | Get profile data table (nil if not loaded) |
| `isLoaded` | `(player) → boolean` | Check if profile is loaded |

### FeatureFlags (`src/server/Modules/FeatureFlags.luau`)

Remote feature flag system backed by Firebase Realtime Database.

- **Startup**: Copies defaults from `Constants.FeatureFlags`, then fetches overrides from Firebase at `/config/featureFlags.json` via `HttpService:GetAsync`
- **Fallback**: If Firebase is unreachable or disabled, defaults are used silently
- **Client sync**: Writes each flag as a `StringValue` in a `ReplicatedStorage/FeatureFlags` folder so clients can read flags without HttpService

**API**:

| Method | Signature | Description |
|--------|-----------|-------------|
| `get` | `(name: string) → any` | Get a single flag value |
| `getAll` | `() → { [string]: any }` | Get a read-only copy of all flags |

**Current flags**:

| Flag | Default | Controls |
|------|---------|----------|
| `NPCsEnabled` | `true` | NPC crowd spawning (server) |
| `MusicEnabled` | `true` | Background music (client) |
| `IntroScreenEnabled` | `true` | Intro screen + camera intro (client) |
| `NewPlayer` | `false` | When true, always shows gender selection even for returning players |
| `Maintenance` | `false` | Kicks all players and blocks joins when true; halts server init |

### FirebaseLogger (`src/server/Modules/FirebaseLogger.luau`)

Sends structured log events to Firebase Realtime Database via the REST API (`POST /logs/<category>.json`).

- **Fire-and-forget**: Every call runs in a detached `task.spawn` with `pcall` — never blocks callers
- **No-op when disabled**: If `Constants.Firebase.DatabaseUrl` is empty or `Enabled` is false, all calls return immediately with no HTTP traffic
- **Entry schema**: `{ timestamp, isoTime, category, event, data, serverId, placeId, placeVersion }`

**API**:

| Method | Signature | Description |
|--------|-----------|-------------|
| `log` | `(category, event, data?)` | Post a single log entry |
| `startTimer` | `(category, event) → callback(data?)` | Returns a callback that logs `event_complete` with `elapsedMs` when called |

**Log points across the codebase**:

| Source | Category | Event | Payload |
|--------|----------|-------|---------|
| init.server | `server` | `startup_begin` | — |
| init.server | `server` | `startup_complete` | — |
| init.server | `player` | `joined` | userId, displayName, playerCount |
| init.server | `player` | `left` | userId, displayName, sessionSeconds, playerCount |
| MapBuilder | `map` | `build_start` | — |
| MapBuilder | `map` | `build_complete` | elapsedMs, instanceCount, navPointCount |
| LightingController | `lighting` | `applied` | neonLightCount |
| NPCSpawner | `npc` | `spawn_start` | targetCount |
| NPCSpawner | `npc` | `spawn_failed` | index, error |
| NPCSpawner | `npc` | `spawn_summary` | targetCount, failCount |
| CharacterCreator | `character` | `created` | userId, displayName, gender |
| init.server | `player` | `play_pressed` | userId, displayName |
| PlayerData | `player_data` | `loaded` | userId, displayName, characterCreated, sessionCount |
| PlayerData | `player_data` | `load_failed` | userId |
| init.client | `client` | `ready` | userId, displayName |
| init.client | `client` | `camera_intro_complete` | userId, displayName |

Client events are forwarded via a `RemoteEvent` (`ReplicatedStorage.FirebaseLogEvent`). The server validates event names (string, max 64 chars) and attaches the player's userId and displayName before posting.

### Constants (`src/shared/Constants.luau`)

Central configuration:

- **Colors**: 28 named colors organized by category (floor, walls, neon, stage, screens, props, stairs, sign, portal)
- **Dimensions**: Floor size (220x220), wall/ceiling height (42), balcony height (24), stage Z position
- **NPC**: Count (20)
- **ScreenFaces**: Front and Back
- **IntroScreen**: `ImageId` for the intro background image asset
- **Music**: `SoundId` and `Volume` for looping background music
- **Outfits**: Gender-based outfit definitions:
  - `Female`: DTI body model (asset 90731674309295, WomanRig), UseDefaultHead, hair accessory, face (86487766), skin color (warm caramel), BodyTypeScale=1, ProportionScale=10, HeadScale=0.65
  - `Male`: Man body bundle (238), classic shirt/pants IDs
- **FeatureFlags**: Default values for `NPCsEnabled`, `MusicEnabled`, `IntroScreenEnabled`, `NewPlayer`, `Maintenance` — overridable via Firebase
- **Firebase**: `DatabaseUrl` (string) and `Enabled` (boolean) for logging and feature flag configuration

## Client (`src/client/init.client.luau`)

Manages the full player experience flow:

1. **Feature flags** — reads flags from `ReplicatedStorage/FeatureFlags` (synced by server), falls back to Constants defaults
2. **Background music** — starts if `MusicEnabled` flag is true, loops for entire session (volume configurable in Constants)
3. **Settings menu** — persistent gear icon (top-right) with volume and brightness sliders, visible on both intro screen and in-game
4. **Intro screen** — shown if `IntroScreenEnabled` flag is true. Full-screen image with animated purple-to-pink galaxy sparkle fill behind it, `UIAspectRatioConstraint` for cross-device scaling. Invisible button hitboxes over the graphic's PLAY/CUSTOMIZE/SHOP buttons. PLAY fires `PlayerReady` to spawn the character; CUSTOMIZE and SHOP show a "Coming Soon!" popup. If disabled, character spawns immediately.
5. **Gender selection** — shown for new players (or when `NewPlayer` flag is true). Dual-button modal (Female pink / Male purple). Fires `GenderSelected` RemoteEvent to server. Checks `CharacterCreated` BoolValue on the player to determine if selection is needed.
6. **Camera intro** — instant handoff (`camera.CameraType = Enum.CameraType.Custom`) after character spawn
7. **Character spawn** — `CharacterAutoLoads` is disabled server-side (set before any `require` calls to prevent race conditions); character loads after gender selection (new players) or PLAY button (returning players)

## Data Flow

```
init.server.luau
  ├─ FeatureFlags: fetch remote overrides from Firebase, sync to ReplicatedStorage
  ├─ FirebaseLogger.log("server", "startup_begin")
  ├─ if Maintenance: kick all players, block new joins, return early
  ├─ ScriptContext.Error → FirebaseLogger (error/script_error)
  ├─ MapBuilder.build()
  │    ├─ FirebaseLogger (build_start / build_complete with timing)
  │    ├─ Creates hub Model in Workspace
  │    ├─ Calls ScreenGenerator.decorate() for each screen part
  │    └─ Returns { hub, navPoints, floor, stage }
  ├─ LightingController.apply()
  │    ├─ Configures Lighting service + adds PointLights to hub
  │    └─ FirebaseLogger (lighting/applied)
  ├─ if NPCsEnabled: NPCSpawner.spawn({ navPoints })
  │    ├─ Creates NPC folder, clones R6 template rigs
  │    ├─ Caches screen + seat parts for NPC interactions
  │    └─ FirebaseLogger (spawn_start / spawn_failed / spawn_summary)
  ├─ FirebaseLogger.log("server", "startup_complete")
  ├─ Players.CharacterAutoLoads = false (set BEFORE all requires)
  ├─ CharacterCreator.init(spawnedPlayers)
  │    ├─ task.spawn(loadDTIModel) — loads Creator Store model, caches MeshParts + joints
  │    └─ GenderSelected RemoteEvent → saveGender + spawnWithOutfit
  ├─ PlayerReady RemoteEvent → spawnWithOutfit (returning) or LoadCharacter (new)
  ├─ Players.PlayerAdded → PlayerData.loadProfile + FirebaseLogger (player/joined)
  │    └─ CharacterAdded → Died → respawn with saved outfit after 3s
  └─ Players.PlayerRemoving → update TotalPlayTime, release profile, FirebaseLogger (player/left)

init.client.luau
  ├─ Read feature flags from ReplicatedStorage/FeatureFlags
  ├─ if MusicEnabled: Background music starts (looped)
  ├─ Settings GUI created (gear icon + sliders)
  ├─ if IntroScreenEnabled: Intro screen shown → FirebaseLogEvent:FireServer("intro_shown")
  │    ├─ PLAY clicked → PlayerReady:FireServer()
  │    └─ Camera intro (instant handoff)
  ├─ else: PlayerReady:FireServer() immediately
  ├─ Gender selection (if new player or NewPlayer flag)
  │    └─ GenderSelected:FireServer(gender) → server spawns with outfit
  └─ FirebaseLogEvent:FireServer("ready")
       └─ Server receives via RemoteEvent → FirebaseLogger.log("client", ...)
```

## Coordinate System

- **Floor center**: (0, 0.5, 0)
- **Stage**: Z = -76 (back of plaza)
- **Entrance**: Z = +110 (front)
- **Walls**: X = ±110, Z = ±110
- **Balcony height**: Y = 24
- **Ceiling**: Y = 42
- **Positive Z** = toward viewer/entrance
- **Negative Z** = toward stage/back wall
