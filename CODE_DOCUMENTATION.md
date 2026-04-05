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
| `NewPlayer` | `true` | New-player onboarding flow (reserved for future use) |

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
- **FeatureFlags**: Default values for `NPCsEnabled`, `MusicEnabled`, `IntroScreenEnabled`, `NewPlayer` — overridable via Firebase
- **Firebase**: `DatabaseUrl` (string) and `Enabled` (boolean) for logging and feature flag configuration

## Client (`src/client/init.client.luau`)

Manages the full player experience flow:

1. **Feature flags** — reads flags from `ReplicatedStorage/FeatureFlags` (synced by server), falls back to Constants defaults
2. **Background music** — starts if `MusicEnabled` flag is true, loops for entire session (volume configurable in Constants)
2. **Settings menu** — persistent gear icon (top-right) with volume and brightness sliders, visible on both intro screen and in-game
4. **Intro screen** — shown if `IntroScreenEnabled` flag is true. Full-screen image with animated purple-to-pink galaxy sparkle fill behind it, `UIAspectRatioConstraint` for cross-device scaling. Invisible button hitboxes over the graphic's PLAY/CUSTOMIZE/SHOP buttons. PLAY fires `PlayerReady` to spawn the character; CUSTOMIZE and SHOP show a "Coming Soon!" popup. If disabled, character spawns immediately.
5. **Camera intro** — elevated overview (Y=80) sweeping down over 2.5 seconds with cubic ease-out after PLAY is pressed
6. **Character spawn** — `CharacterAutoLoads` is disabled server-side; character loads only after clicking PLAY via the `PlayerReady` RemoteEvent

## Data Flow

```
init.server.luau
  ├─ FeatureFlags: fetch remote overrides from Firebase, sync to ReplicatedStorage
  ├─ FirebaseLogger.log("server", "startup_begin")
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
  ├─ Players.CharacterAutoLoads = false
  ├─ PlayerReady RemoteEvent → player:LoadCharacter()
  ├─ Players.PlayerAdded → FirebaseLogger (player/joined)
  └─ Players.PlayerRemoving → FirebaseLogger (player/left + sessionSeconds)

init.client.luau
  ├─ Read feature flags from ReplicatedStorage/FeatureFlags
  ├─ if MusicEnabled: Background music starts (looped)
  ├─ Settings GUI created (gear icon + sliders)
  ├─ if IntroScreenEnabled: Intro screen shown → FirebaseLogEvent:FireServer("intro_shown")
  │    ├─ PLAY clicked → PlayerReady:FireServer()
  │    └─ Camera intro → FirebaseLogEvent:FireServer("camera_intro_complete")
  ├─ else: PlayerReady:FireServer() immediately
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
