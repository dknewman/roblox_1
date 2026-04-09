# Baddies: Play to Slay!

A neon-lit social hub built in Roblox using Luau and Rojo. The environment is constructed procedurally at runtime. Players choose a gender at first join and spawn with a custom character model — the female body is a custom Blender-sculpted R15 avatar imported via Roblox Avatar Auto-Setup and stored in ServerStorage.

## Quick Start

```bash
# Option A: Live sync
rojo serve
# Connect from Roblox Studio via the Rojo plugin, then press Play

# Option B: Build file
rojo build -o build.rbxlx
# Open build.rbxlx in Roblox Studio, then press Play
```

The server scripts construct the plaza when the game starts. You must **press Play** in Studio to see the environment.

## Project Structure

```
src/
  client/
    init.client.luau           -- Intro screen, gender select, settings, music, log forwarding
  server/
    init.server.luau           -- Orchestrator: build → light → spawn → characters → logging
    Modules/
      MapBuilder.luau          -- Procedural geometry (10 build phases)
      LightingController.luau  -- Atmosphere, bloom, color correction
      ScreenGenerator.luau     -- Cyan billboard SurfaceGui content
      NPCSpawner.luau          -- R15 custom avatar crowd NPCs (cloned from ServerStorage)
      CharacterCreator.luau    -- Gender-based character spawning (custom Blender avatar)
      PlayerData.luau           -- Persistent profiles via ProfileService
      ProfileService.luau       -- Third-party DataStore wrapper (madwork)
      FeatureFlags.luau         -- Firebase-backed remote flag system
      FirebaseLogger.luau       -- Firebase Realtime Database logging
  shared/
    Constants.luau             -- Colors, dimensions, outfits, flags, Firebase config
```

## Architecture

The server builds the environment in three phases, then handles player characters:

1. **MapBuilder.build()** — Constructs all geometry: enclosed walls/ceiling, keyhole floor design, tiered stage with portal circle, grand staircases, balconies, billboard screens, side props, neon lighting strips, and the "SOCIAL SPOTLIGHT PLAZA" sign.

2. **LightingController.apply()** — Sets the pink/purple neon atmosphere: ambient lighting, Bloom, ColorCorrection, Atmosphere haze, and auto-attaches PointLights to Neon material parts.

3. **NPCSpawner.spawn()** — Clones 20 R15 custom avatar NPCs from the `BaddieFemale` model in ServerStorage. NPCs wander between navigation points, watch screens, and sit in chairs.

4. **Character Creation** — `CharacterAutoLoads` is disabled. New players see a gender selection screen (Male/Female). Female characters are cloned directly from the `BaddieFemale` R15 model in ServerStorage (custom Blender avatar imported via Avatar Auto-Setup). Male characters use the standard Roblox "Man" body bundle. Returning players respawn with their saved gender automatically.

## Visual Style

- **Theme**: Futuristic social hub / digital plaza
- **Palette**: Pink/magenta neon, purple accents, cyan screens, soft lavender walls
- **Materials**: SmoothPlastic, Neon, Glass
- **Lighting**: Subdued ambient (Brightness 0.6) with neon self-illumination; Bloom, ColorCorrection, and Atmosphere for a soft purple haze — accent glow without white blowout

## Firebase Logging

All server and client events can be logged to a Firebase Realtime Database.

1. Create a Firebase project and Realtime Database at [console.firebase.google.com](https://console.firebase.google.com)
2. Set your database URL in `src/shared/Constants.luau`:
   ```lua
   Constants.Firebase = {
       DatabaseUrl = "https://your-project-default-rtdb.firebaseio.com",
       Enabled = true,
   }
   ```
3. Enable **HttpService** in Studio: Game Settings > Security > Allow HTTP Requests

Logs are posted to `/logs/<category>.json` with entries containing timestamp, event name, payload, server ID, and place version. Client events (ready, camera intro) route through a `RemoteEvent` to the server for forwarding.

Set `DatabaseUrl = ""` or `Enabled = false` to disable logging entirely (no HTTP calls are made).

## Editing

- **Colors & dimensions**: Edit `src/shared/Constants.luau`
- **Outfits & character config**: Edit `Constants.Outfits` in `src/shared/Constants.luau`
- **Geometry layout**: Edit `src/server/Modules/MapBuilder.luau` (organized by build phase)
- **Screen content**: Edit `src/server/Modules/ScreenGenerator.luau`
- **Atmosphere**: Edit `src/server/Modules/LightingController.luau`
- **NPC behavior**: Edit `src/server/Modules/NPCSpawner.luau`
- **Character creation**: Edit `src/server/Modules/CharacterCreator.luau`
- **Player data template**: Edit `src/server/Modules/PlayerData.luau`
- **Logging**: Edit `src/server/Modules/FirebaseLogger.luau`
- **Lighting defaults**: `default.project.json` under the `Lighting` block
