# Baddie Batch Importer (Roblox Studio Plugin)

This plugin adds a toolbar button inside Roblox Studio that imports all four FBX avatars directly into `ReplicatedStorage/Characters` using the Avatar Importer API.

## Installation (macOS Roblox Studio)
1. Copy `BaddieBatchImporter.lua` into your local Studio plugins directory:
   ```bash
   mkdir -p "$HOME/Library/Application Support/Roblox/Plugins"
   cp /Users/ghost/REPOS/Roblox/my-new-game/tools/studio_plugin/BaddieBatchImporter.lua "$HOME/Library/Application Support/Roblox/Plugins/BaddieBatchImporter.lua"
   ```
2. Launch Roblox Studio.
3. Go to `File → Beta Features` and ensure **Avatar Importer API** is enabled. Restart Studio if you toggle it.

## Usage
1. Open the project place (`build.rbxlx`).
2. A new toolbar named **Baddies Tools** appears with a `Batch Import` button.
3. Click the button once. The plugin loops through:
   - `Assets/Characters/Blonde/FBX/Blonde_R15.fbx`
   - `Assets/Characters/BrunetteBlack/FBX/BrunetteBlack_R15.fbx`
   - `Assets/Characters/LeaderPink/FBX/LeaderPink_R15.fbx`
   - `Assets/Characters/LilacBucket/FBX/LilacBucket_R15.fbx`
4. Imported rigs are renamed and stored under `ReplicatedStorage/Characters/<Avatar>` and remain selected for inspection.

If your repo path differs, edit the `BASE_PATH` constant at the top of `BaddieBatchImporter.lua` and reload the plugin.
