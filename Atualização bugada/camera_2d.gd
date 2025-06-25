extends Camera2D

@export var move_speed: float = 500.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

# Configurações do mapa
var map_width = 128
var map_height = 128
var tile_size = 32
var boundary_margin = 500.0  # Pixels extras além do mapa

func _ready():
	# Centraliza a câmera no meio do mapa apenas na inicialização
	var map_center_x = (map_width * tile_size) / 2.0
	var map_center_y = (map_height * tile_size) / 2.0
	position = Vector2(map_center_x, map_center_y)

func _process(delta):
	var input_vector = Vector2.ZERO

	# Movimento com WASD
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1

	position += input_vector.normalized() * move_speed * delta
	
	# Aplica limites à posição da câmera
	apply_camera_limits()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_camera(-zoom_speed, event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_camera(zoom_speed, event.position)

func zoom_camera(amount, mouse_viewport_pos):
	var old_zoom = zoom
	var new_zoom = zoom + Vector2(amount, amount)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	# Se o zoom mudou de fato
	if new_zoom != old_zoom:
		# CORREÇÃO: Converte posição do mouse no viewport para coordenadas do mundo
		# Considera o tamanho real do viewport e o zoom atual
		var viewport_size = get_viewport().get_visible_rect().size
		var viewport_center = viewport_size / 2.0
		
		# Calcula offset do mouse em relação ao centro do viewport
		var mouse_offset_from_center = mouse_viewport_pos - viewport_center
		
		# Converte esse offset para coordenadas do mundo considerando o zoom atual
		var world_offset_before = mouse_offset_from_center / old_zoom
		var world_offset_after = mouse_offset_from_center / new_zoom
		
		# Calcula a diferença que precisa ser compensada
		var world_offset_difference = world_offset_before - world_offset_after
		
		# Aplica o novo zoom
		zoom = new_zoom
		
		# Ajusta a posição da câmera para manter o ponto do mouse fixo
		position += world_offset_difference
		
		# Aplica limites após o zoom
		apply_camera_limits()

func apply_camera_limits():
	# CORREÇÃO: Calcula limites considerando o viewport real da câmera
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_half_width = (viewport_size.x / zoom.x) / 2.0
	var camera_half_height = (viewport_size.y / zoom.y) / 2.0
	
	# Tamanho total do mapa em pixels
	var map_pixel_width = map_width * tile_size  # 4096
	var map_pixel_height = map_height * tile_size  # 4096
	
	# Define limites: câmera pode ir até boundary_margin além do mapa
	# mas considerando que a câmera tem um "tamanho" baseado no zoom
	var min_x = -boundary_margin + camera_half_width
	var max_x = map_pixel_width + boundary_margin - camera_half_width
	var min_y = -boundary_margin + camera_half_height
	var max_y = map_pixel_height + boundary_margin - camera_half_height
	
	# Aplica os limites CORRIGIDOS
	position.x = clamp(position.x, min_x, max_x)
	position.y = clamp(position.y, min_y, max_y)
