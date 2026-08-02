import argparse
import json
import math
from pathlib import Path
import random
import sys

import bpy
from mathutils import Vector


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


def make_material(name: str, color: tuple[float, float, float, float], roughness: float = 0.84) -> bpy.types.Material:
    value = bpy.data.materials.new(name)
    value.diffuse_color = color
    value.use_nodes = True
    principled = value.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Roughness"].default_value = roughness
    return value


def godot_to_blender(position: Vector) -> Vector:
    return Vector((position.x, -position.z, position.y))


def rotate_xz(local_x: float, local_z: float, yaw: float) -> tuple[float, float]:
    return (
        local_x * math.cos(yaw) + local_z * math.sin(yaw),
        -local_x * math.sin(yaw) + local_z * math.cos(yaw),
    )


class MeshBatch:
    def __init__(self, name: str, value: bpy.types.Material) -> None:
        self.name = name
        self.material = value
        self.vertices: list[tuple[float, float, float]] = []
        self.faces: list[tuple[int, int, int, int]] = []

    def add_box(
        self,
        centre: Vector,
        dimensions: tuple[float, float, float],
        yaw: float,
        lean: float = 0.0,
    ) -> None:
        hx, hy, hz = dimensions[0] * 0.5, dimensions[1] * 0.5, dimensions[2] * 0.5
        start = len(self.vertices)
        for x, y, z in [
            (-hx, -hy, -hz), (hx, -hy, -hz), (hx, hy, -hz), (-hx, hy, -hz),
            (-hx, -hy, hz), (hx, -hy, hz), (hx, hy, hz), (-hx, hy, hz),
        ]:
            leaned_x = x * math.cos(lean) - y * math.sin(lean)
            leaned_y = x * math.sin(lean) + y * math.cos(lean)
            rotated_x, rotated_z = rotate_xz(leaned_x, z, yaw)
            point = godot_to_blender(centre + Vector((rotated_x, leaned_y, rotated_z)))
            self.vertices.append((point.x, point.y, point.z))
        self.faces.extend([
            (start + 0, start + 1, start + 2, start + 3),
            (start + 5, start + 4, start + 7, start + 6),
            (start + 4, start + 0, start + 3, start + 7),
            (start + 1, start + 5, start + 6, start + 2),
            (start + 3, start + 2, start + 6, start + 7),
            (start + 4, start + 5, start + 1, start + 0),
        ])

    def finish(self) -> bpy.types.Object | None:
        if not self.vertices:
            return None
        mesh = bpy.data.meshes.new(self.name)
        mesh.from_pydata(self.vertices, [], self.faces)
        mesh.materials.append(self.material)
        mesh.update()
        obj = bpy.data.objects.new(self.name, mesh)
        bpy.context.collection.objects.link(obj)
        return obj


def add_upright_cluster(
    rng: random.Random,
    cluster_index: int,
    centre: Vector,
    size: Vector,
    yaw: float,
    covers: list[bpy.types.Material],
    batches: dict[str, MeshBatch],
) -> int:
    usable_width = size.x * rng.uniform(0.76, 0.96)
    cursor = -usable_width * 0.5
    bottom = centre.y - size.y * 0.5
    count = 0
    while cursor < usable_width * 0.5 - 0.035:
        width = min(rng.uniform(0.035, 0.075), usable_width * 0.5 - cursor)
        if width < 0.025:
            break
        height = size.y * rng.uniform(0.72, 0.99)
        depth = max(0.08, size.z * rng.uniform(0.72, 1.04))
        local_x = cursor + width * 0.5
        local_z = rng.uniform(-0.012, 0.015)
        dx, dz = rotate_xz(local_x, local_z, yaw)
        position = Vector((centre.x + dx, bottom + height * 0.5, centre.z + dz))
        cover = covers[(cluster_index * 3 + count * 5) % len(covers)]
        lean = rng.uniform(-0.075, 0.075) if count in (0, 3, 6) else rng.uniform(-0.025, 0.025)
        batches[cover.name].add_box(position, (width, height, depth), yaw, lean)
        batches["MAT_AgedPages"].add_box(
            position,
            (max(0.012, width - 0.012), max(0.02, height - 0.018), max(0.04, depth - 0.018)),
            yaw,
            lean,
        )
        if (cluster_index + count) % 5 == 0 and height > 0.22:
            front_x, front_z = rotate_xz(local_x, -depth * 0.505, yaw)
            label_position = Vector((centre.x + front_x, bottom + height * 0.58, centre.z + front_z))
            batches["MAT_SpineLabels"].add_box(
                label_position,
                (max(0.014, width * 0.72), 0.022, 0.006),
                yaw,
                lean,
            )
        cursor += width + rng.uniform(0.006, 0.018)
        count += 1
    return count


def add_horizontal_cluster(
    rng: random.Random,
    cluster_index: int,
    centre: Vector,
    size: Vector,
    yaw: float,
    covers: list[bpy.types.Material],
    batches: dict[str, MeshBatch],
) -> int:
    count = 3 if size.y > 0.25 else 2
    thickness = min(0.055, size.y / (count + 0.6))
    bottom = centre.y - size.y * 0.5
    book_width = min(size.x * rng.uniform(0.55, 0.82), 0.34)
    depth = max(0.08, size.z * 0.9)
    local_x = rng.uniform(-size.x * 0.12, size.x * 0.12)
    for book_index in range(count):
        dx, dz = rotate_xz(local_x + rng.uniform(-0.018, 0.018), 0.0, yaw)
        position = Vector((centre.x + dx, bottom + thickness * (book_index + 0.5), centre.z + dz))
        cover = covers[(cluster_index + book_index * 2) % len(covers)]
        batches[cover.name].add_box(position, (book_width, thickness, depth), yaw)
        batches["MAT_AgedPages"].add_box(
            position,
            (book_width - 0.016, max(0.012, thickness - 0.012), depth - 0.018),
            yaw,
        )
    return count


def build(project_root: Path) -> None:
    reset_scene()
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0

    palette = [
        (0.18, 0.045, 0.035, 1.0), (0.06, 0.12, 0.13, 1.0),
        (0.17, 0.13, 0.06, 1.0), (0.07, 0.15, 0.10, 1.0),
        (0.20, 0.08, 0.07, 1.0), (0.08, 0.10, 0.18, 1.0),
        (0.22, 0.18, 0.10, 1.0), (0.12, 0.07, 0.16, 1.0),
    ]
    covers = [make_material(f"MAT_BookCover_{index:02d}", color) for index, color in enumerate(palette)]
    paper = make_material("MAT_AgedPages", (0.50, 0.40, 0.24, 1.0), 0.93)
    label = make_material("MAT_SpineLabels", (0.67, 0.56, 0.34, 1.0), 0.9)
    materials = covers + [paper, label]
    batches = {value.name: MeshBatch(f"M_LibraryBooks_{value.name.removeprefix('MAT_')}", value) for value in materials}

    source_dir = project_root / "assets" / "source" / "blender" / "library_book_dressing"
    export_dir = project_root / "assets" / "hd2d" / "library"
    layout_path = source_dir / "layout.json"
    data = json.loads(layout_path.read_text(encoding="utf-8"))
    book_count = 0
    for cluster_index, cluster in enumerate(data["clusters"]):
        centre = Vector(cluster["position"])
        size = Vector(cluster["size"])
        yaw = float(cluster["yaw"])
        rng = random.Random(1913 + cluster_index * 104729)
        if cluster_index % 11 in (4, 9):
            book_count += add_horizontal_cluster(rng, cluster_index, centre, size, yaw, covers, batches)
        else:
            book_count += add_upright_cluster(rng, cluster_index, centre, size, yaw, covers, batches)

    for batch in batches.values():
        batch.finish()

    source_dir.mkdir(parents=True, exist_ok=True)
    export_dir.mkdir(parents=True, exist_ok=True)
    blend_path = source_dir / "library_book_dressing.blend"
    glb_path = export_dir / "library_book_dressing.glb"
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
    print(f"ASHDOWN_LIBRARY_BOOK_DRESSING={glb_path}")
    print(f"ASHDOWN_LIBRARY_BOOK_COUNT={book_count}")


if __name__ == "__main__":
    build(Path(parse_args().project_root).resolve())
