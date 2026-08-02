import argparse
from pathlib import Path
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
    for material in list(bpy.data.materials):
        bpy.data.materials.remove(material)


def make_material(name: str, color: tuple[float, float, float, float], roughness: float) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Roughness"].default_value = roughness
    return material


def add_box(name: str, location: tuple[float, float, float], dimensions: tuple[float, float, float], material: bpy.types.Material) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    return obj


def build_probe(project_root: Path) -> None:
    reset_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    cover = make_material("MAT_ProbeCover", (0.24, 0.055, 0.045, 1.0), 0.72)
    paper = make_material("MAT_ProbePaper", (0.62, 0.50, 0.30, 1.0), 0.88)

    add_box("M_PipelineProbeBook", (0.0, 0.0, 0.13), (0.18, 0.28, 0.26), cover)
    add_box("M_PipelineProbePages", (0.0, -0.008, 0.13), (0.155, 0.258, 0.235), paper)
    collision = add_box("COL_PipelineProbeBook-convcolonly", (0.0, 0.0, 0.13), (0.18, 0.28, 0.26), cover)
    collision.display_type = "WIRE"

    source_dir = project_root / "assets" / "source" / "blender" / "pipeline_probe"
    export_dir = project_root / "assets" / "hd2d" / "pipeline_probe"
    source_dir.mkdir(parents=True, exist_ok=True)
    export_dir.mkdir(parents=True, exist_ok=True)

    blend_path = source_dir / "pipeline_probe.blend"
    glb_path = export_dir / "pipeline_probe.glb"
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
    print(f"ASHDOWN_PIPELINE_PROBE={glb_path}")


if __name__ == "__main__":
    build_probe(Path(parse_args().project_root).resolve())
