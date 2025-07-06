extends Control



func _on_number_of_players_option_item_selected(index: int) -> void:
	if index == 0:
		$MarginContainer/VBoxContainer/GridContainer/Label3.visible = false
		$MarginContainer/VBoxContainer/GridContainer/DifficultyOption.visible = false
	elif index == 1:
		$MarginContainer/VBoxContainer/GridContainer/Label3.visible = true
		$MarginContainer/VBoxContainer/GridContainer/DifficultyOption.visible = true


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")


func _on_play_button_pressed() -> void:
	var numOfPlayers = 2
	if $MarginContainer/VBoxContainer/GridContainer/NumberOfPlayersOption.selected == 1:
		numOfPlayers = 1
	var gridSize = 10
	if $MarginContainer/VBoxContainer/GridContainer/GridSizeOption.selected == 0:
		gridSize = 8
	elif $MarginContainer/VBoxContainer/GridContainer/GridSizeOption.selected == 2:
		gridSize = 12
	if numOfPlayers == 2:
		GameManager.setup(numOfPlayers, gridSize)
	else:
		var difficulty = GameManager.Difficulty.Easy
		if $MarginContainer/VBoxContainer/GridContainer/DifficultyOption.selected == 1:
			difficulty = GameManager.Difficulty.Medium
		elif $MarginContainer/VBoxContainer/GridContainer/DifficultyOption.selected == 2:
			difficulty = GameManager.Difficulty.Hard
		elif $MarginContainer/VBoxContainer/GridContainer/DifficultyOption.selected == 3:
			difficulty = GameManager.Difficulty.Impossible
		GameManager.setup(numOfPlayers, gridSize, difficulty)
	GameManager.next_scene()
