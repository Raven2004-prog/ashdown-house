import argparse
from pathlib import Path
import math
import sys

import bpy


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(args)


def reset_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for value in list(bpy.data.materials):
        bpy.data.materials.remove(value)


def material(name: str, color: tuple[float, float, float, float], roughness: float, emission: float = 0.0) -> bpy.types.Material:
    value = bpy.data.materials.new(name)
    value.diffuse_color = color
    value.use_nodes = True
    principled = value.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Roughness"].default_value = roughness
    if emission > 0.0:
        principled.inputs["Emission Color"].default_value = color
        principled.inputs["Emission Strength"].default_value = emission
    return value


def cube(name: str, location: tuple[float, float, float], dimensions: tuple[float, float, float], value: bpy.types.Material, rotation=(0.0, 0.0, 0.0)) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(value)
    bevel = obj.modifiers.new("SoftEdges", "BEVEL")
    bevel.width = 0.012
    bevel.segments = 1
    return obj


def cylinder(name: str, location: tuple[float, float, float], radius: float, depth: float, value: bpy.types.Material, vertices: int = 8) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(value)
    bevel = obj.modifiers.new("SoftEdges", "BEVEL")
    bevel.width = 0.01
    bevel.segments = 1
    return obj


def build(project_root: Path) -> None:
    reset_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    coat = material("MAT_InvestigatorCoat", (0.035, 0.048, 0.052, 1.0), 0.88)
    coat_edge = material("MAT_InvestigatorCoatEdge", (0.075, 0.082, 0.077, 1.0), 0.82)
    leather = material("MAT_InvestigatorLeather", (0.115, 0.055, 0.03, 1.0), 0.72)
    metal = material("MAT_InvestigatorMetal", (0.18, 0.15, 0.10, 1.0), 0.5)
    shadow = material("MAT_InvestigatorShadow", (0.012, 0.012, 0.014, 1.0), 0.96)
    lantern = material("MAT_InvestigatorLanternGlow", (0.95, 0.43, 0.08, 1.0), 0.62, 2.2)

    cylinder("M_CoatSkirt", (0.0, 0.0, 0.72), 0.32, 0.82, coat, 6)
    cube("M_CoatTorso", (0.0, 0.0, 1.22), (0.50, 0.28, 0.56), coat)
    cube("M_CoatLapelLeft", (-0.105, -0.151, 1.31), (0.13, 0.025, 0.39), coat_edge, (0.0, 0.12, -0.16))
    cube("M_CoatLapelRight", (0.105, -0.151, 1.31), (0.13, 0.025, 0.39), coat_edge, (0.0, -0.12, 0.16))
    cube("M_LeftArm", (-0.315, 0.0, 1.08), (0.15, 0.18, 0.62), coat, (0.0, 0.0, -0.05))
    cube("M_RightArm", (0.315, 0.0, 1.08), (0.15, 0.18, 0.62), coat, (0.0, 0.0, 0.05))
    cube("M_LeftBoot", (-0.14, -0.035, 0.18), (0.18, 0.32, 0.34), leather)
    cube("M_RightBoot", (0.14, -0.035, 0.18), (0.18, 0.32, 0.34), leather)
    cylinder("M_Head", (0.0, 0.0, 1.58), 0.18, 0.28, shadow, 8)
    cylinder("M_HatBrim", (0.0, -0.015, 1.72), 0.255, 0.04, coat_edge, 10)
    cylinder("M_HatCrown", (0.0, 0.01, 1.80), 0.17, 0.16, coat, 8)

    cube("M_Satchel", (0.35, 0.16, 0.88), (0.34, 0.16, 0.40), leather)
    cube("M_SatchelFlap", (0.35, 0.07, 0.98), (0.35, 0.035, 0.18), leather)
    cube("M_SatchelStrap", (0.10, 0.14, 1.30), (0.055, 0.035, 0.90), leather, (0.0, 0.0, -0.34))

    lantern_x = -0.39
    cube("M_LanternBody", (lantern_x, -0.015, 0.76), (0.18, 0.16, 0.25), metal)
    cube("M_LanternGlow", (lantern_x, -0.02, 0.77), (0.125, 0.11, 0.16), lantern)
    cube("M_LanternTop", (lantern_x, -0.015, 0.91), (0.12, 0.12, 0.05), metal)
    cube("M_LanternHandleLeft", (lantern_x - 0.07, -0.015, 1.01), (0.025, 0.025, 0.20), metal, (0.0, 0.0, -0.20))
    cube("M_LanternHandleRight", (lantern_x + 0.07, -0.015, 1.01), (0.025, 0.025, 0.20), metal, (0.0, 0.0, 0.20))

    source_dir = project_root / "assets" / "source" / "blender" / "investigator"
    export_dir = project_root / "assets" / "hd2d" / "characters"
    source_dir.mkdir(parents=True, exist_ok=True)
    export_dir.mkdir(parents=True, exist_ok=True)
    blend_path = source_dir / "investigator_blockout.blend"
    glb_path = export_dir / "investigator_blockout.glb"
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    bpy.ops.export_scene.gltf(
        filepath=str(glb_path),
        export_format="GLB",
        use_selection=False,
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_animations=False,
        export_yup=True,
    )
    print(f"ASHDOWN_INVESTIGATOR_BLOCKOUT={glb_path}")


if __name__ == "__main__":
    build(Path(parse_args().project_root).resolve())
