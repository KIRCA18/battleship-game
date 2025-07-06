extends Control

var historyCard = preload("res://HistoryCard.tscn")  # loads at compile time

func _ready() -> void:
	if DirAccess.dir_exists_absolute("user://prevgames/"):
		var cards = []
		var winner
		var score
		var date
		var mode
		var difficulty
		var difficultyText = ["Easy", "Medium", "Hard", "Impossible"]
		var dir = DirAccess.open("user://prevgames/")
		for fileName in dir.get_files():
			var gameFile = FileAccess.open("user://prevgames/{file}".format({"file": fileName}), FileAccess.READ)
			winner = gameFile.get_var()
			score = gameFile.get_var()
			date = gameFile.get_var()
			mode = gameFile.get_var()
			difficulty = gameFile.get_var()
			var card = historyCard.instantiate()
			card.setup(winner, score, date, mode, difficultyText[difficulty] if mode == "Player vs Computer" else null)
			cards.append(card)
		cards.reverse()
		for card in cards:
			$MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer.add_child(card)


func _on_back_button_texture_pressed() -> void:
	print("Back button pressed")
	get_tree().change_scene_to_file("res://Main.tscn")
