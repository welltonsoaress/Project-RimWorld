@tool
extends TileMapLayer

@export var generateObjects: bool:
	set(value):
		generateObjects = false
		if is_inside_tree():
			generate()
		else:
			await ready
			generate()

@export var generationChance := 0.08

func generate():
	print("🔁 Gerando OBJECTS...")
	clear()
	var terrain_map = get_node("/root/Main/Terrain/TerrainMap") as TileMapLayer
	var resource_map = get_node_or_null("/root/Main/Resource/ResourceMap") as TileMapLayer
	if not terrain_map or not resource_map:
		print("❌ 'terrainmap' ou 'resourcemap' não encontrados.")
		return

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for x in range(terrain_map.mapWidth):
		for y in range(terrain_map.mapHeight):
			var pos = Vector2i(x, y)
			var ground_tile = terrain_map.get_cell_atlas_coords(pos)

			# 🧱 Verifica se há PEDRA neste tile (2,0)
			var tile_atlas = resource_map.get_cell_atlas_coords(pos)
			var source_id = resource_map.get_cell_source_id(pos)
			var has_stone = (source_id != -1 and tile_atlas == Vector2i(2, 0))

			# 🧾 Condição para NÃO colocar mato/árvore:
			# - Não é grama
			# - OU há pedra
			if ground_tile != Vector2i(0, 0) or has_stone:
				continue

			var roll = rng.randf()
			if roll < generationChance:
				set_cell(pos, 0, Vector2i(0, 0))  # mato
			elif roll < generationChance + 0.03:
				set_cell(pos, 0, Vector2i(1, 0))  # árvore
