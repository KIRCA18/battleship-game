extends Control

var placeholder = "Player {number} WON!"
var pointsPlaceholder = "{points} points!"

func _ready() -> void:
	print(GameManager.state)
	$VBoxContainer/Label.text = placeholder.format({"number": "1" if GameManager.state == GameManager.GameState.Player1Won else "2"})
	$VBoxContainer/ScoreLabel.text = pointsPlaceholder.format({"points": GameManager.players[0].score if GameManager.state == GameManager.GameState.Player1Won else GameManager.players[1].score})

func _on_play_again_button_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://GameConfig.tscn")


func _on_main_menu_button_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://Main.tscn")
