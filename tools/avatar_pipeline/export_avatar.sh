#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: tools/avatar_pipeline/export_avatar.sh <BLEND_FILE> <AVATAR_NAME>" >&2
  exit 1
fi

BLEND_FILE=$1
AVATAR_NAME=$2
EXPORT_DIR="Assets/Characters/${AVATAR_NAME}/FBX"
mkdir -p "${EXPORT_DIR}"

blender -b "${BLEND_FILE}" --python-expr "import bpy; bpy.ops.object.select_all(action='DESELECT');
obj = bpy.data.objects['${AVATAR_NAME}']; obj.select_set(True); bpy.context.view_layer.objects.active = obj;
bpy.ops.export_scene.fbx(filepath='${EXPORT_DIR}/${AVATAR_NAME}_R15.fbx', use_selection=True, apply_scale_options='FBX_SCALE_ALL', add_leaf_bones=False, axis_forward='-Y', axis_up='Z')"
