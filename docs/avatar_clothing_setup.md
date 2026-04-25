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

- **Hair & Layered Clothing:** Use the [Avatar Shop](https://www.roblox.com/catalog) and filter by **Accessories → Hair** (or **Clothing → Layered**). Set price -> `0` to surface free items.
- **Asset IDs:** Copy the numeric ID from the URL (e.g., `https://www.roblox.com/catalog/9240776381/...`).
- **Permissions:** Asset must allow copying; otherwise InsertService cannot deliver it.

## 3. Adding or Changing Pieces

1. Edit `src/shared/Constants.luau`:
   - Set `HairAccessory` to the hair asset ID.
   - Add layered accessories (tops, skirts, shoes) to `LayeredAccessories`.
2. NPCs and player females will automatically equip whatever IDs you specify (handled in `CharacterCreator` and `NPCSpawner`).

## 4. Creating Custom Accessories (Meshy boots example)

1. **Import:** Insert the MeshPart into Workspace.
2. **Convert to Accessory:** Avatar tab → `Accessory`. Studio creates an accessory with a `Handle`.
3. **Add Attachments:** On the Handle, add two attachments named `LeftFootAttachment` and `RightFootAttachment`. Position them at the ankle origin for each boot while previewing with a dummy Baddie rig.
4. **Scale/Align:** Use Move/Scale tools so the boots match the rig’s proportions. If they appear huge, scale the Handle (maintaining file scale in Blender before export helps).
5. **Publish/Store:** Save to Roblox (ensure “Allow copying”) or place the accessory in `ServerStorage/LayeredAccessories`.
6. **Wire into the game:** Add the asset ID to `Constants.Outfits.Female.LayeredAccessories`.

## 5. Troubleshooting Boots

- Boots appearing in front of the character usually mean the attachments are at the world origin. After adding `LeftFootAttachment` / `RightFootAttachment`, use the Move tool to snap each to the expected foot location on a preview rig.
- If the boots follow you but float, adjust the attachment’s CFrame or use the Rig Builder dummy to align them precisely.

### Current Female Outfit
- Hair: `140198630246272` (Voxlore Long Hair)
- Top: `9240752338` (Tie Front Top)
- Skirt: `9240776381` (Ruffle Skirt White)
- Shoes: *Add your boot asset ID once published*
