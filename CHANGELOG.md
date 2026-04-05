# Changelog
All notable changes to this project will be documented here. Keep entries in reverse chronological order and update after every modification.

## 2024-05-14
### Added
- `default.project.json`: Replaced the single demo house with `Workspace.Neighborhood`, including three unique homes (Maple, Pine, Cedar), sidewalks, street lamps, foliage clusters, and two parked cars.
- Door metadata attributes on every house door plus invisible sensors so each entrance is interactable.
- `src/server/AutoDoor.luau`: Handles hinge math, tweening, and auto-close timing for any door tagged with `AutoDoor`.
- `src/server/DoorService.luau`: Scans Workspace for tagged doors, instantiates controllers, and watches for future additions.
- Updated `CODE_DOCUMENTATION.md` to describe the neighborhood layout and door system.

### Changed
- `src/server/init.server.luau`: Now boots the new `DoorService` instead of a single hard-coded controller.

### Removed
- `src/server/DoorController.luau`: Legacy single-door script superseded by the generalized service.

## 2024-05-14 (Earlier)
### Added
- `default.project.json`: Declared the full `DemoHouse` model (floor, walls, roof, door, window, invisible door sensor) so the scene appears instantly in Studio.
- `src/server/DoorController.luau`: Handles humanoid touches from the door and sensor, tweens the door 90° outward, and auto-closes after 3 seconds.
- `src/server/init.server.luau`: Boots the door controller for every server session.
- `CODE_DOCUMENTATION.md` and this `CHANGELOG.md` to explain architecture and track future updates.

### Removed
- `src/server/HouseBuilder.luau`: Procedural builder replaced by the static Workspace layout defined in `default.project.json`.
