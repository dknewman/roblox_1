# Code Documentation

## Overview
The workspace has been reset to the default Rojo layout with nothing but the grey baseplate visible in Studio. Geometry lives entirely in `default.project.json`, while runtime folders are ready for future scripts.

## Project Layout
- `default.project.json`: Mirrors the DataModel with only `Workspace.Baseplate` plus default Lighting and SoundService properties.
- `src/server/init.server.luau`: Placeholder server bootstrap that currently just logs when the world loads.
- `src/client/init.client.luau`: Minimal client stub for future local logic.
- `src/shared/Hello.luau`: Example module returning a simple function.

## Scene
- Workspace contains only the standard 512×20×512 anchored baseplate at Y = -10, giving a clean slate for future builds.

## Workflow Notes
- Update this document whenever new systems or assets are added so the current structure stays discoverable.
