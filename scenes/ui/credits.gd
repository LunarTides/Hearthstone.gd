extends Control


#region Exported Variables
@export var speed: float
@export var text: RichTextLabel
#endregion


#region Internal Functions
func _process(delta: float) -> void:
	text.position.y -= speed * delta


func _input(event: InputEvent) -> void:
	if event.as_text() == "Escape":
		Game.exit_to_main_menu()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			speed *= 4
		else:
			speed /= 4
#endregion


#region Private Functions
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	Game.exit_to_main_menu()


func _on_rich_text_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)
#endregion
