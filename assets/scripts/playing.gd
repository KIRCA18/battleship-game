extends Node3D

@export var tileWidth: float
@export var tileHeight: float
@export var tileSpacing: float

@onready var TransitionCamera: Camera3D = $TransitionCamera
@onready var selected_camera: Camera3D = $Player1Grid/Camera3D

@onready var camera1 = $Player1Grid/Camera3D
@onready var camera2 = $Player2Grid/Camera3D2

var textures = {}

var prevTile = null
var TransitionTween: Tween

func getHalfWidth() -> float:
	return float(GameManager.gridSize * tileWidth + (GameManager.gridSize - 1) * tileSpacing)/2

func _ready() -> void:
	$TransitionCamera.make_current()
	GameManager.drawGrid(self, $Player1Grid, $Player2Grid, tileWidth, tileHeight, tileSpacing, _on_mouse_entered)
	$Player1Grid/Camera3D.transform.origin = Vector3(getHalfWidth() - 5,100,getHalfWidth() - 5)
	$Player2Grid/Camera3D2.transform.origin = Vector3(getHalfWidth() - 5,100,getHalfWidth() - 5)
	if GameManager.state == GameManager.GameState.Player1Guess:
		change_camera($Player1Grid/Camera3D)
	elif GameManager.state  == GameManager.GameState.Player2Guess:
		change_camera($Player2Grid/Camera3D2)
	GameManager.changePlayerSignal.connect(_on_player_changed)
	textures = {
		"2": preload("res://assets/textures/boat2pressed.png"),
		"3": preload("res://assets/textures/boat3pressed.png"),
		"4": preload("res://assets/textures/boat4pressed.png"),
		"5": preload("res://assets/textures/boat5pressed.png")
	}
	
	var player1boats = GameManager.players[0].getRemainingTypeOfBoats()
	var player2boats = GameManager.players[1].getRemainingTypeOfBoats()

	for size in player1boats:
		for i in range(player1boats[size]):
			var textureRect = TextureRect.new()
			textureRect.ignore_texture_size = true
			textureRect.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
			textureRect.texture = textures[size]
			textureRect.set_meta("size", size)
			textureRect.custom_minimum_size = Vector2(200, 55)
			$CanvasLayer/MarginContainer/MarginContainer/MarginContainer/VBoxContainer2.add_child(textureRect)
	
	for size in player2boats:
		for i in range(player2boats[size]):
			var textureRect = TextureRect.new()
			textureRect.ignore_texture_size = true
			textureRect.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
			textureRect.texture = textures[size]
			textureRect.set_meta("size", size)
			textureRect.custom_minimum_size = Vector2(200, 55)
			$CanvasLayer/MarginContainer/MarginContainer2/MarginContainer/VBoxContainer2.add_child(textureRect)
	


func _on_player_changed() -> void:
	print("camera should change")
	if GameManager.state == GameManager.GameState.Player1Guess:
		change_camera($Player1Grid/Camera3D)
	elif GameManager.state == GameManager.GameState.Player2Guess:
		change_camera($Player2Grid/Camera3D2)
		
		
		

func process_ai_guess(ai: AI, indices: Array[int]) -> bool:
	var tile = get_tile($Player2Grid, indices)
	paint_tiles([tile], Color(0.7, 0.7, 0.7))
	await get_tree().create_timer(0.7).timeout
	$Timer.start()
	tile.set_meta("hit", true)
	var res = GameManager.guess(indices[0], indices[1])
	return handle_guess_result($Player2Grid, ai, tile, res, indices)


func handle_guess_result(grid: Node3D, ai: AI, tile: StaticBody3D, res: Dictionary, indices: Array[int]) -> bool:
	if not res["hit"]:
		tile.visible = false
		tile.mouse_entered.disconnect(tile.mouse_entered.get_connections()[0].callable)
		return false
	else:
		if res["sunk"]:
			var b = res["boat"]
			place_sunk_boat(grid, b)
			remove_sunk_boat_hits(ai, b)
			removeBoatButton($CanvasLayer/MarginContainer/MarginContainer/MarginContainer/VBoxContainer2, b.size)
		else:
			ai.prev_hits.append(indices)
		paint_tiles([tile], Color(1, 0, 0))
		return true

func removeBoatButton(parent, size: int):
	for child in parent.get_children():
		print(child.get_meta("size"))
		if child.get_meta("size", "") == str(size):
			parent.remove_child(child)
			return

func remove_sunk_boat_hits(ai: AI, boat) -> void:
	var x = boat.index / GameManager.gridSize
	var y = boat.index % GameManager.gridSize
	ai.prev_hits.erase([x, y])
	for i in range(boat.size - 1):
		if boat.orientation == "vertical":
			x += 1
		else:
			y += 1
		ai.prev_hits.erase([x, y])
	if ai.prev_hits.size() == 0:
		ai.target_mode = false


func get_tile(grid: Node3D, indices: Array[int]) -> StaticBody3D:
	return grid.get_child(1 + indices[0] * GameManager.gridSize + indices[1])

func process_ai_hit(ai: AI) -> void:
	var indices = ai.hit()
	var tile = get_tile($Player2Grid, indices)
	paint_tiles([tile], Color(0.7, 0.7, 0.7))
	await get_tree().create_timer(0.3).timeout
	$Timer.start()
	tile.set_meta("hit", true)
	var res = GameManager.guess(indices[0], indices[1])
	handle_guess_result($Player2Grid, ai, tile, res, indices)

func _on_tween_finished():
	if GameManager.numberOfPlayers == 1 and GameManager.state == GameManager.GameState.Player2Guess:
		var temp = GameManager.players[1] as AI
		var first_hit_indices = temp.hit()
		var was_hit = await process_ai_guess(temp, first_hit_indices)
		
		if not was_hit:
			return
			
		while GameManager.state == GameManager.GameState.Player2Guess:
			var indices = temp.hit()
			if indices.size() == 0:
				break
			var result = await process_ai_guess(temp, indices)
			if not result:
				break

func _process(_delta: float) -> void:
	$CanvasLayer/MarginContainer/Label.text = "Player One\nBoats Left: {left}".format({"left":GameManager.players[0].boatsLeft})
	$CanvasLayer/MarginContainer/Label2.text = "Player Two\nBoats Left: {left}".format({"left":GameManager.players[1].boatsLeft})
	
	$CanvasLayer/MarginContainer/VBoxContainer/Label3.text = "Time to hit: " + str(int($Timer.time_left)) + "s"
	$CanvasLayer/MarginContainer/VBoxContainer/Label4.text = "Player {player} guesses!".format({"player": "1" if GameManager.state == GameManager.GameState.Player1Guess else "2"})
	

func _on_timer_timeout() -> void:
	GameManager.changePlayer()
	
func paint_tiles(tiles, color):
	if tiles:
		for t in tiles:
			if not t: continue
			var material = t.get_meta("material")
			if material and material is StandardMaterial3D:
				material.albedo_color = color
	
	
func _on_mouse_entered(tile: StaticBody3D):
	if ((GameManager.state == GameManager.GameState.Player1Guess and $Player2Grid.get_children().find(tile) != -1) or
		(GameManager.state == GameManager.GameState.Player2Guess and $Player1Grid.get_children().find(tile) != -1)):
		return
	if tile.has_meta("hit"): return
	if prevTile:
		if prevTile.has_meta("hit"):
			prevTile = tile
			return
		else:
			paint_tiles([prevTile], Color(0.5, 0.5, 0.5))
	paint_tiles([tile], Color(0.7, 0.7, 0.7))
	prevTile = tile
	

func getHitIndices(grid: Node3D, tile: StaticBody3D) -> Array[int]:
	var ind = grid.get_children().find(tile) - 1
	var x = ind / GameManager.gridSize
	var y =  ind % GameManager.gridSize
	return [x,y]

func hasChild(parent: Node3D, body: StaticBody3D) -> bool:
	return parent.get_children().has(body)
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 1 and prevTile:
			print(prevTile)
			$Timer.start()
			prevTile.set_meta("hit", true)
			var indices = null
			var parentVBox = $CanvasLayer/MarginContainer/MarginContainer/MarginContainer/VBoxContainer2
			if GameManager.state == GameManager.GameState.Player1Guess and hasChild($Player1Grid, prevTile):
				parentVBox = $CanvasLayer/MarginContainer/MarginContainer2/MarginContainer/VBoxContainer2
				indices = getHitIndices($Player1Grid, prevTile)
			elif GameManager.state == GameManager.GameState.Player2Guess and hasChild($Player2Grid, prevTile):
				indices = getHitIndices($Player2Grid, prevTile)
			if not indices:
				return
			var res = GameManager.guess(indices[0], indices[1])
			if res["hit"] == false:
				prevTile.visible = false
				prevTile.mouse_entered.disconnect(prevTile.mouse_entered.get_connections()[0].callable)
			else:
				paint_tiles([prevTile], Color(1,0,0))
				if res["sunk"]:
					var b = res["boat"]
					if GameManager.state == GameManager.GameState.Player1Guess:
						place_sunk_boat($Player1Grid, b)
					elif GameManager.state == GameManager.GameState.Player2Guess:
						place_sunk_boat($Player2Grid, b)
					removeBoatButton(parentVBox, b.size)
			prevTile = null

func change_camera(desired_camera: Camera3D):
	if TransitionTween:
		TransitionTween.kill()
	TransitionTween = create_tween()
	TransitionTween.finished.connect(_on_tween_finished)
	var target_transform: Transform3D = desired_camera.global_transform
	TransitionTween.tween_property(TransitionCamera, "global_transform", target_transform, 0.8)
	
	selected_camera = desired_camera
	

func place_sunk_boat(grid: Node3D, boat) -> void:
	var sunkBoat = load("res://assets/models/"+boat.type+str(boat.size)+".blend").instantiate()
	add_child(sunkBoat)
	if boat.orientation == "horizontal":
		sunkBoat.transform = sunkBoat.transform.rotated(Vector3(0,1,0).normalized(), PI/2)
	sunkBoat.global_transform = sunkBoat.global_transform.scaled_local(Vector3(3,3,3))
	sunkBoat.global_transform.origin = grid.get_child(boat.index + 1).global_transform.origin
					


func _on_save_button_pressed() -> void:
	GameManager.save_state()


func _on_game_menu_button_pressed() -> void:
	$GameMenu.visible = !$GameMenu.visible
	$Timer.paused = $GameMenu.visible
		


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_main_menu_button_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://Main.tscn")
	


func _on_danger_button_mouse_entered() -> void:
	$GameMenu/Label2.visible = true


func _on_danger_button_mouse_exited() -> void:
	$GameMenu/Label2.visible = false
