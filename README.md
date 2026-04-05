# Social Spotlight Plaza

A fully procedural, neon-lit futuristic social hub built in Roblox using Lua and Rojo. The entire environment — geometry, lighting, screens, NPCs — is constructed at runtime from Roblox primitives with no external assets.

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
    init.client.luau          -- Camera intro + client log forwarding
  server/
    init.server.luau           -- Orchestrator: build → light → spawn → logging
    Modules/
      MapBuilder.luau          -- Procedural geometry (10 build phases)
      LightingController.luau  -- Atmosphere, bloom, color correction
      ScreenGenerator.luau     -- Cyan billboard SurfaceGui content
      NPCSpawner.luau          -- R15 crowd with idle animations
      FirebaseLogger.luau      -- Firebase Realtime Database logging
  shared/
    Constants.luau             -- Colors, dimensions, NPC config, Firebase config
```

## Architecture

The environment is built in three sequential phases on the server:

1. **MapBuilder.build()** — Constructs all geometry: enclosed walls/ceiling, keyhole floor design, tiered stage with portal circle, grand staircases with individual steps, balconies, billboard screens, side props (arcade, food truck, seating, selfie booths), neon lighting strips, and the "SOCIAL SPOTLIGHT PLAZA" sign.

2. **LightingController.apply()** — Sets the pink/purple neon atmosphere: ambient lighting, Bloom, ColorCorrection, Atmosphere haze, and auto-attaches PointLights to Neon material parts.

3. **NPCSpawner.spawn()** — Creates 40 R15 humanoid NPCs with random colors and idle animations (dance, wave, cheer, applaud) that wander between navigation points.

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
- **Geometry layout**: Edit `src/server/Modules/MapBuilder.luau` (organized by build phase)
- **Screen content**: Edit `src/server/Modules/ScreenGenerator.luau`
- **Atmosphere**: Edit `src/server/Modules/LightingController.luau`
- **NPC behavior**: Edit `src/server/Modules/NPCSpawner.luau`
- **Logging**: Edit `src/server/Modules/FirebaseLogger.luau`
- **Lighting defaults**: `default.project.json` under the `Lighting` block
