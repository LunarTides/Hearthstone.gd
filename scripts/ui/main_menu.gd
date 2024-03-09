extends PanelContainer


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("editor") or get_children().size() == 1:
		_on_join_button_pressed()


func _on_join_button_pressed() -> void:
	Game.exit_to_lobby()
#endregion
