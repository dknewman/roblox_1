# Code Documentation

## Overview
The project now ships with a small suburban block that loads instantly in Studio through `default.project.json`. The scene includes a paved road, sidewalks, three unique homes, parked cars, street lights, and foliage. Interactable doors are handled by server-side modules so every house can be entered as soon as the simulation starts.

## Project Layout
- `default.project.json`: Describes the DataModel tree. `Workspace.Neighborhood` contains the entire environment, broken down into reusable models:
  - Road + sidewalks + street lamps for the shared public space.
  - `HouseMaple`, `HousePine`, `HouseCedar` – different footprints and details to keep the block varied. Each house embeds a `Door` and invisible `DoorSensor` part, plus decorative windows, chimneys, porches, etc.
  - Vehicle props (`CarBlue`, `CarRed`) and foliage models (`TreeOak*`, `BushCluster*`).
- `src/server`:
  - `init.server.luau` – boots runtime services.
  - `DoorService.luau` – finds every part tagged with the `AutoDoor` attribute and wires up interactions.
  - `AutoDoor.luau` – encapsulates the tweening/state machine for a single door.
- `src/client` / `src/shared`: still placeholders for future gameplay systems.

## Neighborhood Composition Highlights
- **Road & sidewalks**: Asphalt strip with a center stripe and concrete sidewalks north/south of the road for navigation, plus walkway segments leading up to each house.
- **Houses**:
  - *Maple*: cozy single-story (18×14 footprint) with chimney, porch path, and door swinging outward to the left.
  - *Pine*: widest footprint with taller walls, porch overhang, and a right-hinged door that opens inward toward the house.
  - *Cedar*: compact footprint with side window and short walkway.
- **Cars**: Simple multi-part models with colored bodies and cylindrical wheels, parked along the road for life/scale cues.
- **Foliage**: Trees built from a trunk part + spherical canopy, plus clustered bushes for ground cover.

Every interactable door part carries attributes defined directly in the JSON:
```json
"$attributes": {
  "AutoDoor": true,
  "DoorSensorName": "DoorSensor",
  "OpenAngle": 95,
  "OpenDirection": -1,
  "AutoCloseDelay": 4,
  "HingeSide": -1
}
```
Adjust those values per house to control swing direction, hinge side, and closing delay without editing Lua.

## Door Interaction Flow
1. When the server starts, `init.server.luau` requires `DoorService`.
2. `DoorService` scans `workspace` for any `BasePart` whose `AutoDoor` attribute is `true`, instantiating an `AutoDoor` controller for each and watching for new parts added later.
3. `AutoDoor` precalculates open/closed `CFrame`s using the configured hinge side/direction, listens to `Touched` events from the door and its paired sensor, and tweens the door over 0.8 seconds.
4. After the last humanoid touch, a delayed task automatically closes the door once the configured timeout elapses.

## Workflow Notes
- Keep geometry declarative in the project file so Rojo mirrors the neighborhood instantly.
- When adding a new house or prop, prefer grouping it inside `Workspace.Neighborhood` for clarity.
- To make any door interactive, add the `AutoDoor` attribute block plus a matching sensor part; `DoorService` will pick it up automatically.
- Update this document whenever you add new services, systems, or notable scene components so contributors have a current mental model of the project.
