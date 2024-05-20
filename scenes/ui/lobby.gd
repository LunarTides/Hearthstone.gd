extends Control


#region Exported Variables
@export var join_button: Button
@export var host_button: Button
@export var ip_address: LineEdit
@export var port: LineEdit
@export var deckcode: LineEdit
@export var info_label: Label
#endregion


#region Internal Functions
func _ready() -> void:
	if OS.get_cmdline_args().has("--server") or OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		host()
		return
#endregion


#region Public Functions
## Makes the game start hosting a server.
func host() -> void:
	info_label.text = "Please wait for a client to connect..."
	_toggle()
	
	Multiplayer.host()
	
	Game.game_started.connect(func() -> void: info_label.text = "A game is in progress.")
#endregion


#region Private Functions
func _toggle() -> void:
	join_button.visible = not join_button.visible
	host_button.visible = not host_button.visible
	ip_address.visible = not ip_address.visible
	port.visible = not port.visible
	deckcode.visible = not deckcode.visible
	
	info_label.visible = not info_label.visible


func _on_join_button_pressed() -> void:
	if not await Deckcode.validate(deckcode.text):
		Game.feedback("Invalid deckcode.", Game.FeedbackType.ERROR)
		push_warning("Invalid deckcode.")
		return
	
	info_label.text = "Waiting for response from server..."
	_toggle()
	
	Multiplayer.join(
		ip_address.text,
		port.text.to_int() if port.text.is_valid_int() else 4545,
		deckcode.text,
	)
	
	multiplayer.connected_to_server.connect(func() -> void:
		Multiplayer.server_responded.connect(func(success: bool, error_message: String) -> void:
			if not success:
				_toggle()
				
				push_error(error_message)
				Game.feedback(error_message, Game.FeedbackType.ERROR)
				return
			
			info_label.text = "Waiting for another player..."
		)
	)


func _on_host_button_pressed() -> void:
	host()


func _on_ip_address_text_submitted(_new_text: String) -> void:
	_on_join_button_pressed()
#endregion
