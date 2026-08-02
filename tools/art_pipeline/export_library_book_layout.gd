extends SceneTree

const SOURCE_SCENE := "res://scenes/levels/ashdown/rooms/LibraryBenchmark.tscn"
const OUTPUT_PATH := "res://assets/source/blender/library_book_dressing/layout.json"

func _initialize() -> void:
	call_deferred("_export_layout")

func _export_layout() -> void:
	var packed := load(SOURCE_SCENE) as PackedScene
	if packed == null:
		push_error("Could not load Library benchmark scene.")
		quit(1)
		return
	var root := packed.instantiate()
	root.name = "LibraryBenchmark"
	get_root().add_child(root)
	var clusters: Array[Dictionary] = []
	for node in root.find_children("Books_*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var aabb := mesh_instance.mesh.get_aabb()
		var centre := mesh_instance.global_transform * aabb.get_center()
		var scale := mesh_instance.global_basis.get_scale().abs()
		var size := aabb.size * scale
		clusters.append({
			"name": String(mesh_instance.name),
			"path": String(root.get_path_to(mesh_instance)),
			"position": [centre.x, centre.y, centre.z],
			"size": [size.x, size.y, size.z],
			"yaw": mesh_instance.global_rotation.y,
		})
	clusters.sort_custom(func(a: Dictionary, b: Dictionary): return String(a.path) < String(b.path))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write Library book layout.")
		quit(1)
		return
	file.store_string(JSON.stringify({"clusters": clusters}, "\t"))
	file.close()
	print("LIBRARY_BOOK_LAYOUT: %d clusters -> %s" % [clusters.size(), ProjectSettings.globalize_path(OUTPUT_PATH)])
	quit(0)
