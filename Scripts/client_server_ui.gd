extends Control


func _on_server_button_pressed() -> void:
	NetworkHandler.start_server()
	get_tree().change_scene_to_file("res://Scenes/battle_ground.tscn")


func _on_client_button_pressed() -> void:
	NetworkHandler.start_client()
	get_tree().change_scene_to_file("res://Scenes/battle_ground.tscn")
