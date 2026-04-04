# Changelog
All notable changes to this project will be documented here. Keep entries in reverse chronological order and update after every modification.

## 2024-05-14
### Added
- `default.project.json`: Declared the full `DemoHouse` model (floor, walls, roof, door, window, invisible door sensor) so the scene appears instantly in Studio.
- `src/server/DoorController.luau`: Handles humanoid touches from the door and sensor, tweens the door 90° outward, and auto-closes after 3 seconds.
- `src/server/init.server.luau`: Boots the door controller for every server session.
- `CODE_DOCUMENTATION.md` and this `CHANGELOG.md` to explain architecture and track future updates.

### Removed
- `src/server/HouseBuilder.luau`: Procedural builder replaced by the static Workspace layout defined in `default.project.json`.
