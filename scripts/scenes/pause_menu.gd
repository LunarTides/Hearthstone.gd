extends Panel


#region Exported Variables
@export var settings_menu: Panel
#endregion


#region Public Variables
var is_dragging: bool = false
#endregion


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


func _input(event: InputEvent) -> void:
	if event.is_released():
		return
	
	var key: String = event.as_text()
	
	if key == "Escape":
		toggle()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		is_dragging = event.pressed
	
	if is_dragging and event is InputEventMouseMotion:
		position += event.relative
#endregion


#region Public Functions
func toggle() -> void:
	settings_menu.hide()
	visible = not visible
#endregion


#region Private Functions
func _on_resume_pressed() -> void:
	settings_menu.hide()
	hide()


func _on_settings_button_pressed() -> void:
	settings_menu.show()


func _on_exit_pressed() -> void:
	OS.set_restart_on_exit(false)
	Multiplayer.quit()
#endregion
