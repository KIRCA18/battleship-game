extends Control

func _ready() -> void:
	if not FileAccess.file_exists("user://lastgame.save"):
		$VBoxContainer/ContinueButton.visible = false

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://GameConfig.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_continue_button_pressed() -> void:
	if GameManager.load_state():
		GameManager.next_scene()


func _on_history_button_pressed() -> void:
	get_tree().change_scene_to_file("res://History.tscn")
