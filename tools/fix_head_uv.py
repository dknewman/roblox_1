"""
Blender Script: Remap Head UVs for Face Texture
Run this in Blender's Scripting workspace (or paste into Python Console).

This script:
1. Selects vertices in the "Head" vertex group
2. Projects their UVs from the front view (sphere projection)
3. Centers and scales the UV island to fill the 0-1 UV space
4. Positions the face map to align with the head's front face

Usage: Open blender_baddie.blend, switch to Scripting workspace, paste this, click Run.
"""

import bpy
import bmesh
import math
from mathutils import Vector

# Get the mesh object
obj = bpy.data.objects.get("char1")
if not obj:
    raise RuntimeError("Object 'char1' not found!")

# Switch to object mode first, then edit mode
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')

# Get bmesh
me = obj.data
bm = bmesh.from_edit_mesh(me)
bm.verts.ensure_lookup_table()
bm.faces.ensure_lookup_table()

# Get the Head vertex group index
head_group = obj.vertex_groups.get("Head")
if not head_group:
    raise RuntimeError("Vertex group 'Head' not found!")

head_idx = head_group.index

# Find head vertices
head_verts = set()
for v in bm.verts:
    for g in obj.data.vertices[v.index].groups:
        if g.group == head_idx and g.weight > 0.5:
            head_verts.add(v.index)
            break

print(f"Found {len(head_verts)} head vertices")

# Select only head faces (faces where all verts are in head group)
bpy.ops.mesh.select_all(action='DESELECT')
for face in bm.faces:
    all_head = all(v.index in head_verts for v in face.verts)
    face.select = all_head

bmesh.update_edit_mesh(me)

# Get UV layer
uv_layer = bm.loops.layers.uv.active
if not uv_layer:
    raise RuntimeError("No active UV layer!")

# Collect selected faces
head_faces = [f for f in bm.faces if f.select]
print(f"Found {len(head_faces)} head faces")

# Calculate the center and bounds of head vertices in 3D space
head_positions = [obj.data.vertices[vi].co for vi in head_verts]
center = Vector((0, 0, 0))
for pos in head_positions:
    center += pos
center /= len(head_positions)

# Calculate bounds for scaling
min_x = min(p.x for p in head_positions)
max_x = max(p.x for p in head_positions)
min_z = min(p.z for p in head_positions)
max_z = max(p.z for p in head_positions)

width = max_x - min_x
height = max_z - min_z
scale = max(width, height)

if scale < 0.0001:
    raise RuntimeError("Head vertices have zero size!")

# Project UVs from front view (X, Z -> U, V)
# Map head 3D positions to UV space centered in the face map
for face in head_faces:
    for loop in face.loops:
        vert = loop.vert
        co = obj.data.vertices[vert.index].co

        # Project from front: X -> U, Z -> V
        # Normalize to 0-1 range and center
        u = (co.x - center.x) / scale + 0.5
        v = (co.z - center.z) / scale + 0.5

        # Slight vertical offset to better center the face
        # (face map has face in upper portion, neck at bottom)
        v = v * 0.85 + 0.08

        loop[uv_layer].uv = (u, v)

bmesh.update_edit_mesh(me)

print("Head UVs remapped successfully!")
print("Now re-export the FBX: File > Export > FBX")
print("  - Object Types: Mesh only")
print("  - Path Mode: Copy + embed textures")
print("  - Apply Scalings: FBX All")
print("  - Save to /Users/ghost/BLENDER_EXPORT/blender_baddie.fbx")
