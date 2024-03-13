extends PanelContainer


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("editor"):
		_on_play_button_pressed()


func _on_play_button_pressed() -> void:
	Game.exit_to_lobby()


func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/credits.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()
#endregion
