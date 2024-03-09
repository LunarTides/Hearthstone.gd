extends PanelContainer


#region Constant Variables
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(320, 240),
	Vector2i(384, 288),
	Vector2i(480, 360),
	Vector2i(640, 480),
	Vector2i(720, 576),
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1640, 936),
	Vector2i(1280, 960),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
	Vector2i(7680, 4320),
]

const FULLSCREEN_MODES: Dictionary = {
	"Windowed": DisplayServer.WINDOW_MODE_WINDOWED,
	"Borderless Fullscreen": DisplayServer.WINDOW_MODE_FULLSCREEN,
	"Exclusive Fullscreen": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
}
#endregion


#region Exported Variables
#region Video
@export_category("Video")
@export var vsync: CheckBox
@export var fullscreen: OptionButton
@export var resolution: OptionButton
#endregion


#region Debug
@export_category("Debug")
@export var debug: Control
@export var cbx: SpinBox
@export var cby: SpinBox
@export var cbz: SpinBox
@export var crym: SpinBox
@export var cdx: SpinBox
#endregion
#endregion


#region Public Variables
var is_dragging: bool = false
#endregion


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	
	#region Video
	# Vsync
	vsync.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	
	# Fullscreen
	for key: String in FULLSCREEN_MODES.keys():
		var value: DisplayServer.WindowMode = FULLSCREEN_MODES[key]
		fullscreen.add_item(key)
	
	var fullscreen_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	fullscreen.select(FULLSCREEN_MODES.values().find(fullscreen_mode))
	
	# Resolution
	for pixels: Vector2i in RESOLUTIONS:
		var readable: String = "%dx%d" % [pixels.x, pixels.y]
		resolution.add_item(readable)
	
	var pixels: Vector2i = get_window().size
	resolution.select(RESOLUTIONS.find(pixels))
	#endregion
	
	
	#region Debug
	if not OS.is_debug_build():
		debug.queue_free()
	
	cbx.value = Game.card_bounds_x
	cby.value = Game.card_bounds_y
	cbz.value = Game.card_bounds_z
	crym.value = Game.card_rotation_y_multiplier
	cdx.value = Game.card_distance_x
	#endregion


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		is_dragging = event.pressed
	
	if is_dragging and event is InputEventMouseMotion:
		position += event.relative
#endregion


#region Private Functions
#region Video
func _on_back_button_pressed() -> void:
	hide()


func _on_vsync_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _on_fullscreen_item_selected(index: int) -> void:
	DisplayServer.window_set_mode(FULLSCREEN_MODES.values()[index])


func _on_resolution_item_selected(index: int) -> void:
	var pixels: Vector2i = RESOLUTIONS[index]
	get_window().size = Vector2i(pixels.x, pixels.y)
#endregion


#region Debug
func _on_cbx_value_changed(value: float) -> void:
	Game.card_bounds_x = value

func _on_cby_value_changed(value: float) -> void:
	Game.card_bounds_y = value


func _on_cbz_value_changed(value: float) -> void:
	Game.card_bounds_z = value


func _on_crym_value_changed(value: float) -> void:
	Game.card_rotation_y_multiplier = value


func _on_cdx_value_changed(value: float) -> void:
	Game.card_distance_x = value
#endregion
#endregion
