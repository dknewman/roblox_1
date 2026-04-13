# Avatar Clothing Setup

This repo uses a hybrid approach: the female avatar body comes from our custom **BaddieFemale** rig, but head + hair + outfits rely on Roblox catalog assets. Follow these steps whenever you want to change or add clothing pieces.

## 1. Know the Slots

| Slot | Female Source | Notes |
|------|---------------|-------|
| Head | `Constants.Outfits.Female.HeadAssetId` (currently 113842569610805) | Cached via `CatalogHead` and automatically recolored + scaled (`CatalogHeadScale`). |
| Hair | `Constants.Outfits.Female.HairAccessory` | Inserted with `AccessoryUtil.applyAccessoryAsset`. Use an Avatar Shop hair accessory ID. |
| Layered Clothing | `Constants.Outfits.Female.LayeredAccessories` | Any layered clothing accessories (tops, skirts, shoes, etc.). Each ID is loaded and added via `Humanoid:AddAccessory` for both player females and NPCs. |
| Male Shirt/Pants | `Constants.Outfits.Male.ClassicShirt` / `ClassicPants` | Standard R15 clothing handled through `HumanoidDescription`. |

## 2. Finding Assets

- **Hair & Layered Clothing:** Use the [Avatar Shop](https://www.roblox.com/catalog) and filter by **Accessories → Hair** or **Clothing → Layered**. Set price to `0` for free items or buy the ones you need.
- **Asset IDs:** Copy the numeric ID from the URL (e.g., `https://www.roblox.com/catalog/9240776381/...`).
- **Permissions:** The asset must allow copying; otherwise InsertService will reject it.

## 3. Updating the Game

1. Edit `src/shared/Constants.luau`:
   - Set `HairAccessory` to the hair asset ID.
   - Update `LayeredAccessories` with any layered clothing IDs (e.g., `tie front top (9240752338)`, `ruffle skirt (9240776381)`).
2. The server automatically equips those accessories for:
   - Female players inside `CharacterCreator.spawnWithOutfit`.
   - Female NPCs when `NPCSpawner` clones each rig.
3. No extra code changes are needed as long as you just add IDs.

## 4. Creating Custom Clothing

If you want a look that doesn’t exist in the Avatar Shop:
1. **Model in Blender** against the Baddie rig.
2. Export as FBX, then in Studio use **Avatar → Setup → Import 3D** to convert it into an `Accessory` with attachments.
3. Publish the accessory (allow copying) or place it in `ServerStorage/HairAccessories` so the server can clone it directly.
4. Add the new asset ID to `LayeredAccessories`.

## 5. Troubleshooting

- **"Asset … did not contain an Accessory":** The ID is probably a MeshPart/Model. Convert it to an accessory in Studio or choose another asset.
- **"SurfaceAppearance can only be parented to MeshParts":** Indicates we tried to reuse decals/SurfaceAppearance from the original head. This was fixed by `CatalogHead.apply`; ensure you’re on the latest code.
- **Accessory not visible:** Make sure the asset is a layered accessory compatible with R15. Classic `Shirt`/`Pants` won’t render on our custom mesh.

Keeping this doc updated: whenever you add a new outfit component, list it below so designers know what the current look uses.

### Current Female Outfit
- Hair: 140198630246272 (Voxlore Long Hair)
- Layered top: 9240752338 (Tie Front Top)
- Layered skirt: 9240776381 (Ruffle Skirt – White)

Feel free to extend the list with shoes, jackets, etc.
