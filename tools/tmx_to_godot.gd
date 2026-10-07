extends SceneTree

# Bootstraps a stage from an existing Tiled map (.tmx with one external .tsx tileset).
# Tiled is not our level editor: convert a map once, then edit the generated stage in Godot.
#
# Usage:
#   godot --headless --path . --script res://tools/tmx_to_godot.gd -- \
#       <map.tmx> <stage_name> [<tileset_name>]
#
# Output:
#   res://scenes/stages/<stage_name>.tscn             Stage (stage.gd) with one TileMapLayer per
#                                                     tile layer; the map's background colour
#                                                     becomes its sky_color
#   res://scenes/stages/tilesets/<tileset_name>.tres  TileSet, reused when it already exists
#   res://sprites/tilesets/<tileset_name>.png         atlas; animations whose frames are not
#                                                     consecutive get repacked into new rows
#
# Collisions: tiles with collision objects become solid; tiles whose `retrosharpCollision`
# property is `Platform` become one-way platforms.

const STAGE_DIR := "res://scenes/stages"
const TILESET_DIR := "res://scenes/stages/tilesets"
const ATLAS_DIR := "res://sprites/tilesets"
const STAGE_SCALE := 3.0
const STAGE_SCRIPT := preload("res://scripts/stage.gd")
const TERRAIN_COLLISION_LAYER := 1
const SOURCE_ID := 0
const TILE_COORDS_META := &"tiled_tile_coords"
const GID_FLIP_H := 0x80000000
const GID_FLIP_V := 0x40000000
const GID_FLIP_D := 0x20000000
const GID_MASK := 0x0FFFFFFF


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		_fail("usage: -- <map.tmx> <stage_name> [<tileset_name>]")
		return
	var error := _convert(args[0], args[1], args[2] if args.size() > 2 else "")
	if error != "":
		_fail(error)
		return
	quit(0)


func _fail(message: String) -> void:
	printerr("tmx_to_godot: ", message)
	quit(1)


func _convert(map_path: String, stage_name: String, tileset_name: String) -> String:
	var stage_path := "%s/%s.tscn" % [STAGE_DIR, stage_name]
	if FileAccess.file_exists(stage_path):
		return "%s already exists; stages are edited in Godot after the import" % stage_path

	var map := _parse_tmx(map_path)
	if map.has("error"):
		return map["error"]
	var tilesets: Array = map["tilesets"]
	if tilesets.size() != 1:
		return "expected exactly one tileset, found %d" % tilesets.size()
	var tsx_path: String = map_path.get_base_dir().path_join(tilesets[0]["source"])
	if tileset_name == "":
		tileset_name = tsx_path.get_file().get_basename().to_snake_case()

	var tileset_path := "%s/%s.tres" % [TILESET_DIR, tileset_name]
	var tile_set: TileSet
	if FileAccess.file_exists(tileset_path):
		tile_set = load(tileset_path)
		print("Reusing ", tileset_path)
	else:
		var tsx := _parse_tsx(tsx_path)
		if tsx.has("error"):
			return tsx["error"]
		tile_set = _build_tileset(tsx, tileset_name)
		if tile_set == null:
			return "could not build the tileset"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TILESET_DIR))
		if ResourceSaver.save(tile_set, tileset_path) != OK:
			return "could not save " + tileset_path
		print("Wrote ", tileset_path)
		# Reload it so the stage references the file instead of embedding a copy
		tile_set = load(tileset_path)

	var coords: Dictionary = tile_set.get_meta(TILE_COORDS_META)
	var root := Node2D.new()
	root.set_script(STAGE_SCRIPT)
	root.name = stage_name.to_pascal_case()
	if map["backgroundcolor"] != "":
		root.sky_color = Color(map["backgroundcolor"])
	var layers: Array = map["layers"]
	for layer: Dictionary in layers:
		var tile_layer := TileMapLayer.new()
		tile_layer.name = "Terrain" if layers.size() == 1 else String(layer["name"]).to_pascal_case()
		tile_layer.tile_set = tile_set
		tile_layer.scale = Vector2.ONE * STAGE_SCALE
		root.add_child(tile_layer)
		tile_layer.owner = root
		var warning := _fill_layer(tile_layer, layer, int(tilesets[0]["firstgid"]), coords)
		if warning != "":
			return warning

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(STAGE_DIR))
	var scene := PackedScene.new()
	scene.pack(root)
	if ResourceSaver.save(scene, stage_path) != OK:
		return "could not save " + stage_path
	root.free()
	print("Wrote ", stage_path, " (", map["width"], "x", map["height"], " tiles, sky ",
		map.get("backgroundcolor", "none"), ")")
	return ""


func _fill_layer(tile_layer: TileMapLayer, layer: Dictionary, first_gid: int,
		coords: Dictionary) -> String:
	var width: int = layer["width"]
	var gids: PackedInt64Array = layer["gids"]
	for i in gids.size():
		var gid := gids[i]
		if gid == 0:
			continue
		var tile_id := (gid & GID_MASK) - first_gid
		if not coords.has(tile_id):
			return "layer %s uses tile %d, which is not in the tileset" % [layer["name"], tile_id]
		var alternative := 0
		if gid & GID_FLIP_H:
			alternative |= TileSetAtlasSource.TRANSFORM_FLIP_H
		if gid & GID_FLIP_V:
			alternative |= TileSetAtlasSource.TRANSFORM_FLIP_V
		if gid & GID_FLIP_D:
			alternative |= TileSetAtlasSource.TRANSFORM_TRANSPOSE
		tile_layer.set_cell(Vector2i(i % width, i / width), SOURCE_ID, coords[tile_id], alternative)
	return ""


# --- TileSet ---

func _build_tileset(tsx: Dictionary, tileset_name: String) -> TileSet:
	var tile_size := Vector2i(tsx["tilewidth"], tsx["tileheight"])
	var columns: int = tsx["columns"]
	var tile_count: int = tsx["tilecount"]
	var rows := ceili(float(tile_count) / columns)
	var tiles: Dictionary = tsx["tiles"]
	var source := Image.load_from_file(tsx["image"])
	if source == null:
		printerr("cannot read ", tsx["image"])
		return null
	source.convert(Image.FORMAT_RGBA8)

	# Godot plays an animation from consecutive atlas cells, so animations whose frames are
	# not consecutive (or repeat a frame) are copied into new rows below the original atlas.
	var coords := {}
	var frame_cells := {}
	var repacked: Array[int] = []
	for id: int in tiles:
		var frames: Array = tiles[id].get("frames", [])
		if frames.is_empty():
			continue
		var in_place := id % columns + frames.size() <= columns
		for k in frames.size():
			in_place = in_place and int(frames[k]["tileid"]) == id + k
		if in_place:
			for k in range(1, frames.size()):
				frame_cells[id + k] = true
		else:
			if frames.size() > columns:
				printerr("animation of tile %d has more frames than the atlas has columns" % id)
				return null
			repacked.append(id)

	var atlas_image := Image.create_empty(columns * tile_size.x,
		(rows + repacked.size()) * tile_size.y, false, Image.FORMAT_RGBA8)
	atlas_image.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i.ZERO)
	for row in repacked.size():
		var id := repacked[row]
		var frames: Array = tiles[id]["frames"]
		for k in frames.size():
			var frame_id: int = frames[k]["tileid"]
			atlas_image.blit_rect(source, Rect2i(_cell(frame_id, columns) * tile_size, tile_size),
				Vector2i(k, rows + row) * tile_size)
		coords[id] = Vector2i(0, rows + row)

	var atlas_path := "%s/%s.png" % [ATLAS_DIR, tileset_name]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ATLAS_DIR))
	if atlas_image.save_png(atlas_path) != OK:
		printerr("cannot write ", atlas_path)
		return null
	print("Wrote ", atlas_path)
	var texture := _import_texture(atlas_path)
	if texture == null:
		return null

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = tile_size
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, TERRAIN_COLLISION_LAYER)
	tile_set.add_source(atlas, SOURCE_ID)

	for id in tile_count:
		if frame_cells.has(id):
			continue
		if not coords.has(id):
			coords[id] = _cell(id, columns)
		var cell: Vector2i = coords[id]
		var tile: Dictionary = tiles.get(id, {})
		if not tiles.has(id) and atlas_image.get_region(Rect2i(cell * tile_size, tile_size)).is_invisible():
			coords.erase(id)
			continue
		atlas.create_tile(cell)
		var frames: Array = tile.get("frames", [])
		if not frames.is_empty():
			atlas.set_tile_animation_frames_count(cell, frames.size())
			for k in frames.size():
				atlas.set_tile_animation_frame_duration(cell, k, int(frames[k]["duration"]) / 1000.0)
		_add_collision(atlas.get_tile_data(cell, 0), tile, Vector2(tile_size))

	tile_set.set_meta(TILE_COORDS_META, coords)
	return tile_set


func _add_collision(data: TileData, tile: Dictionary, tile_size: Vector2) -> void:
	var one_way: bool = tile.get("properties", {}).get("retrosharpCollision", "") == "Platform"
	var polygons: Array = tile.get("polygons", [])
	if polygons.is_empty() and one_way:
		polygons = [PackedVector2Array([Vector2.ZERO, Vector2(tile_size.x, 0), tile_size,
			Vector2(0, tile_size.y)])]
	var seen := {}
	for points: PackedVector2Array in polygons:
		var key := str(points)
		if seen.has(key):
			continue
		seen[key] = true
		var centered := PackedVector2Array()
		for p in points:
			centered.append(p - tile_size / 2.0)
		var index := data.get_collision_polygons_count(0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, index, centered)
		data.set_collision_polygon_one_way(0, index, one_way)


func _cell(id: int, columns: int) -> Vector2i:
	return Vector2i(id % columns, id / columns)


# A freshly written PNG is only loadable after the import step, so run it in a child process.
func _import_texture(path: String) -> Texture2D:
	var output := []
	OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "--import"], output, true)
	var texture: Texture2D = load(path)
	if texture == null:
		printerr("cannot load the imported atlas ", path, "\n", "\n".join(output))
	return texture


# --- Tiled XML ---

func _parse_tmx(path: String) -> Dictionary:
	var parser := XMLParser.new()
	if parser.open(path) != OK:
		return {"error": "cannot open " + path}
	var map := {"tilesets": [], "layers": []}
	var layer := {}
	var in_data := false
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				match parser.get_node_name():
					"map":
						if parser.get_named_attribute_value_safe("infinite") == "1":
							return {"error": "infinite maps are not supported"}
						map["width"] = int(parser.get_named_attribute_value("width"))
						map["height"] = int(parser.get_named_attribute_value("height"))
						map["backgroundcolor"] = parser.get_named_attribute_value_safe(
							"backgroundcolor")
					"tileset":
						var source := parser.get_named_attribute_value_safe("source")
						if source == "":
							return {"error": "embedded tilesets are not supported"}
						map["tilesets"].append({"source": source,
							"firstgid": int(parser.get_named_attribute_value("firstgid"))})
					"layer":
						layer = {"name": parser.get_named_attribute_value("name"),
							"width": int(parser.get_named_attribute_value("width"))}
					"data":
						if parser.get_named_attribute_value_safe("encoding") != "csv":
							return {"error": "only CSV layer data is supported"}
						in_data = true
					"objectgroup", "imagelayer", "group":
						print("Skipping ", parser.get_node_name(), " ",
							parser.get_named_attribute_value_safe("name"))
			XMLParser.NODE_TEXT:
				if in_data:
					var gids := PackedInt64Array()
					for value in parser.get_node_data().split(",", false):
						if value.strip_edges() != "":
							gids.append(int(value.strip_edges()))
					layer["gids"] = gids
			XMLParser.NODE_ELEMENT_END:
				if parser.get_node_name() == "data":
					in_data = false
				elif parser.get_node_name() == "layer":
					map["layers"].append(layer)
	return map


func _parse_tsx(path: String) -> Dictionary:
	var parser := XMLParser.new()
	if parser.open(path) != OK:
		return {"error": "cannot open " + path}
	var tsx := {"tiles": {}}
	var tile := {}
	var in_tile := false
	var object_origin := Vector2.ZERO
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "tile":
			in_tile = false
		if parser.get_node_type() != XMLParser.NODE_ELEMENT:
			continue
		match parser.get_node_name():
			"tileset":
				for key in ["tilewidth", "tileheight", "tilecount", "columns"]:
					tsx[key] = int(parser.get_named_attribute_value(key))
			"image":
				if not in_tile:
					tsx["image"] = path.get_base_dir().path_join(
						parser.get_named_attribute_value("source"))
				else:
					return {"error": "image collection tilesets are not supported"}
			"tile":
				tile = {}
				tsx["tiles"][int(parser.get_named_attribute_value("id"))] = tile
				in_tile = not parser.is_empty()
			"property":
				if in_tile:
					tile.get_or_add("properties", {})[parser.get_named_attribute_value("name")] = \
						parser.get_named_attribute_value_safe("value")
			"object":
				object_origin = Vector2(float(parser.get_named_attribute_value_safe("x")),
					float(parser.get_named_attribute_value_safe("y")))
				var size := Vector2(float(parser.get_named_attribute_value_safe("width")),
					float(parser.get_named_attribute_value_safe("height")))
				if size != Vector2.ZERO:
					tile.get_or_add("polygons", []).append(PackedVector2Array([object_origin,
						object_origin + Vector2(size.x, 0), object_origin + size,
						object_origin + Vector2(0, size.y)]))
			"polygon":
				var points := PackedVector2Array()
				for pair in parser.get_named_attribute_value("points").split(" ", false):
					var xy := pair.split(",")
					points.append(object_origin + Vector2(float(xy[0]), float(xy[1])))
				tile.get_or_add("polygons", []).append(points)
			"frame":
				tile.get_or_add("frames", []).append({
					"tileid": int(parser.get_named_attribute_value("tileid")),
					"duration": int(parser.get_named_attribute_value("duration"))})
	if not tsx.has("image"):
		return {"error": "tileset %s has no image" % path}
	return tsx
