# Social Spotlight Plaza (Static Blockout)

This project now ships with a static, hand-authored blockout of the Social Spotlight Plaza built directly inside `default.project.json`. When you run Rojo (or open the generated place) you immediately see the pastel stage, glowing runway, screens, stair volumes, balconies, kiosks, selfie booths, and food truck inspired by the reference art—no runtime scripts are required.

## Usage
1. `rojo serve` and connect from Roblox Studio, **or** `rojo build -o build.rbxlx` and open the file.
2. The geometry lives under `Workspace > SocialPlaza`, so you can tweak colors/positions straight from Studio.

## Editing Notes
- All lighting values live under the `Lighting` block in `default.project.json`.
- Add new props by extending the `SocialPlaza` model with more Parts; keep the palette consistent so the neon vibe stays intact.
- Server/client scripts are stubs now because the level is purely visual.
