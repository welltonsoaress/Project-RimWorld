@tool
extends TileMapLayer

@export var generateResources: bool:
	set(value):
		generateResources = false
		if is_inside_tree():
			generate()
		else:
			await ready
			generate()

@export var generationChance := 0.03
@export var clusterSize := 10

func generate():
	print("🔁 Gerando RESOURCES...")
	clear()
	var terrain_map = get_node("/root/Main/Terrain/TerrainMap") as TileMapLayer
	var object_map := get_node_or_null("/root/Main/Terrain/objects") as TileMapLayer
	if not terrain_map:
		print("❌ 'terrainmap' não encontrado.")
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var placed = {}

	for _i in range(terrain_map.mapWidth * terrain_map.mapHeight * generationChance):
		var start = Vector2i(rng.randi_range(0, terrain_map.mapWidth - 1), rng.randi_range(0, terrain_map.mapHeight - 1))
		var ground_tile = terrain_map.get_cell_atlas_coords(start)

		var has_object = false
		if object_map:
			has_object = object_map.get_cell_source_id(start) != -1

		var valid_terrains = [
			Vector2i(0, 0),  # grama clara
			Vector2i(1, 0),  # grama escura
			Vector2i(2, 0),  # terra
			Vector2i(1, 1),  # areia praia
			Vector2i(2, 1)   # areia deserto
		]

		if ground_tile not in valid_terrains or has_object:
			continue


		for _j in range(clusterSize):
			var offset = Vector2i(rng.randi_range(-2, 2), rng.randi_range(-2, 2))
			var pos = start + offset
			if pos.x < 0 or pos.y < 0 or pos.x >= terrain_map.mapWidth or pos.y >= terrain_map.mapHeight:
				continue
			if str(pos) in placed:
				continue

			var g = terrain_map.get_cell_atlas_coords(pos)
			var o = object_map and object_map.get_cell_source_id(pos) != -1

			if g not in valid_terrains or o:
				continue


			set_cell(pos, 0, Vector2i(2, 0))  # pedra
			placed[str(pos)] = true
