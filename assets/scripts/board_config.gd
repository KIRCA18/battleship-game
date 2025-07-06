extends Node3D

var selected = null
var selectedSize = null
var ghost_boat: Node3D = null 
var lastTile: StaticBody3D = null
var marine_type: String
var models = {}
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 1:
			if not selected or not lastTile: return
			if(not ($Node3D.isValid(lastTile))):
				return
			for tile in $Node3D.hoveredTiles:
				tile.set_meta("free", false)
			
			GameManager.place_boat($Node3D.get_children().find(lastTile), selectedSize, ghost_boat.get_meta("orientation"), marine_type)
			selected.queue_free()
			selectedSize = null
			selected = null
			ghost_boat = null
			
		elif event.button_index == 2:
			if not selected: return
			ghost_boat.queue_free()
			selected = null
			selectedSize = null
			ghost_boat = null

func _ready() -> void:
	models = {
		"Boat2.blend": preload("res://assets/models/Boat2.blend"),
		"Boat3.blend": preload("res://assets/models/Boat3.blend"),
		"Boat4.blend": preload("res://assets/models/Boat4.blend"),
		"Boat5.blend": preload("res://assets/models/Boat5.blend"),
	}
	var textures = {
		2: [
			preload("res://assets/textures/boat2normal.png"),
			preload("res://assets/textures/boat2hover.png"),
			preload("res://assets/textures/boat2pressed.png")
		],
		3: [
			preload("res://assets/textures/boat3normal.png"),
			preload("res://assets/textures/boat3hover.png"),
			preload("res://assets/textures/boat3pressed.png")
		],
		4: [
			preload("res://assets/textures/boat4normal.png"),
			preload("res://assets/textures/boat4hover.png"),
			preload("res://assets/textures/boat4pressed.png")
		],
		5: [
			preload("res://assets/textures/boat5normal.png"),
			preload("res://assets/textures/boat5hover.png"),
			preload("res://assets/textures/boat5pressed.png")
		]
	}
	if GameManager.state == GameManager.GameState.Player1BoardConfig:
		$CanvasLayer/MarginContainer/Label.text = "Player 1 place your boats!"
	elif GameManager.state == GameManager.GameState.Player2BoardConfig:
		$CanvasLayer/MarginContainer/Label.text = "Player 2 place your boats!"
	for boatSize in GameManager.boatCombo:
		for i in range(GameManager.boatCombo[boatSize]):
			var textureButton = TextureButton.new()
			textureButton.ignore_texture_size = true
			textureButton.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
			textureButton.texture_normal = textures[boatSize][0]
			textureButton.texture_hover = textures[boatSize][1]
			textureButton.texture_pressed = textures[boatSize][2]
			
			textureButton.custom_minimum_size = Vector2(200, 55)
			textureButton.set_meta("resource_name", "Boat"+str(boatSize)+".blend")
			textureButton.pressed.connect(func() -> void: _on_button_pressed(textureButton, boatSize))
			$CanvasLayer/VBoxContainer.add_child(textureButton)
			
	var offset = sqrt(pow(90/cos(0.436332313),2) - pow(90,2)) + getHalfWidth() + 10
	print(offset)
	$Camera3D.global_transform.origin = Vector3($Camera3D.global_transform.origin.x + getHalfWidth() - 5, $Camera3D.global_transform.origin.y, $Node3D.global_transform.origin.z + offset)

func getHalfWidth() -> float:
	return float(GameManager.gridSize * 10 + (GameManager.gridSize - 1) * 1)/2

func _on_button_pressed(button: TextureButton, size: int):
	if ghost_boat:
		ghost_boat.queue_free()
	print(size)
	selected = button
	selectedSize = size
	ghost_boat = models[button.get_meta("resource_name")].instantiate()
	var name_and_suffix = button.get_meta("resource_name", "")
	var marine_name = name_and_suffix.split(".").get(0)
	marine_type = marine_name.substr(0, marine_name.length()-1)
	
	ghost_boat.transform = ghost_boat.transform.scaled_local(Vector3(3,3,3))
	ghost_boat.set_meta("size", size)
	ghost_boat.set_meta("orientation", "vertical")
	ghost_boat.set_meta("is_boat", true)
	
	add_child(ghost_boat)

func _process(_delta: float) -> void:
	var mouse_position = get_viewport().get_mouse_position()
	var camera = $Camera3D
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)
	var ray_end = ray_origin + ray_direction * 1000

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collision_mask = 1

	var result = space_state.intersect_ray(query)
	if ghost_boat and selected and result and result["collider"] is StaticBody3D:
		lastTile = result["collider"]
		var local_position: Vector3 = result.position
		local_position.x = result["collider"].transform.origin.x
		local_position.z = result["collider"].transform.origin.z
		ghost_boat.transform.origin = local_position


func _on_button_rotate_pressed() -> void:
	if not selected: return
	if ghost_boat.get_meta("orientation") == "vertical":
		ghost_boat.transform = ghost_boat.transform.rotated_local(Vector3(0,1,0).normalized(), PI/2)
		ghost_boat.set_meta("orientation", "horizontal")
	else:
		ghost_boat.transform = ghost_boat.transform.rotated_local(Vector3(0,1,0).normalized(), -PI/2)
		ghost_boat.set_meta("orientation", "vertical")


func _on_game_menu_button_pressed() -> void:
	$GameMenu.visible = !$GameMenu.visible
		

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_main_menu_button_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://Main.tscn")
