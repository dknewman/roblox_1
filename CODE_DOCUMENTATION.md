# Code Documentation

## Overview
This project defines a small demo house that appears instantly in Studio via Rojo, plus a server-side controller that animates the door whenever a player character approaches. Everything is organized for quick iteration: geometry stays in `default.project.json`, while behavior lives in Luau modules under `src`.

## Project Layout
- `default.project.json`: Mirrors the DataModel tree. Workspace contains the `DemoHouse` model with declarative parts (floor, walls, roof, door, window, invisible sensor) so assets sync without running scripts.
- `src/server`: Holds runtime logic that executes on the server when Play starts. Currently includes `init.server.luau` (bootstrap) and `DoorController.luau` (door automation).
- `src/client` and `src/shared`: Reserved for future gameplay/UI logic.

## DemoHouse Composition
Each child under `Workspace.DemoHouse` is a single anchored part. Sizes/positions are defined relative to the origin so the house rests on the baseplate.
- `Floor`: 20×1×16 wood plank platform at Y=0.5.
- `BackWall`, `LeftWall`, `RightWall`: 9-stud-tall smooth plastic walls enclosing the back and sides.
- `FrontWallLeft`, `FrontWallRight`, `FrontWallHeader`: Frame the doorway opening.
- `Door`: Anchored wood plank that the controller rotates about its left edge.
- `DoorSensor`: Invisible, non-colliding trigger part in front of the doorway to register approaching players early.
- `FrontStep`: Small concrete step to ease entry.
- `Window`: Non-colliding, semi-transparent glass accent on the right wall.
- `Roof`: Slate slab slightly oversized to create an overhang.

## Door Interaction Flow
1. `ServerScriptService.Server.init.server.luau` requires `DoorController` on server start.
2. `DoorController.init()` locates `workspace.DemoHouse.Door` and `DoorSensor`, precalculates open/closed `CFrame`s (90° swing outward) using a hinge at the door's left edge, and subscribes to `Touched` events on both parts.
3. When a `Humanoid` touches either part, the controller tweens the door open over 0.8s and schedules an auto-close after 3s of inactivity. Additional touches reset the timer.
4. The door remains anchored, so every client sees the same animation without physics constraints.

## Workflow Notes
- Geometry tweaks happen in `default.project.json`; Rojo immediately reflects them in Studio.
- Runtime behavior should be encapsulated in modules (like `DoorController`) and required from `init.server.luau` to keep the server side organized.
- Update this documentation whenever new systems, assets, or scripts are introduced so newcomers understand how pieces fit together.
