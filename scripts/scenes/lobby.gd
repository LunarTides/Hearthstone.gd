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
#endregion


#region Public Functions
## Makes the game start hosting a server.
func host() -> void:
	# Will not really work with a dedicated server but there it nothing i can do.
	OS.set_restart_on_exit(true, ["--server"])
	
	join_button.hide()
	host_button.hide()
	ip_address.hide()
	port.hide()
	deckcode.hide()
	
	info_label.text = "Please wait for a client to connect..."
	info_label.show()
	
	Multiplayer.peer.create_server(Multiplayer.port, Multiplayer.max_clients)
	multiplayer.multiplayer_peer = Multiplayer.peer
	
	Multiplayer.load_config()
	
	# UPnP
	if not UPnP.has_tried_upnp:
		print("Attempting to use UPnP. Please wait...")
		UPnP.setup(Multiplayer.port)
		
		UPnP.upnp_completed.connect(func(err: int) -> void:
			if err == OK:
				print("UPnP setup completed successfully. You do not need to port forward.")
			else:
				print("UPnP setup failed, you will need to port-forward port %s (TCP/UDP) manually." % Multiplayer.port)
		)
	
	print("Waiting for a client to connect...")
	
	Game.game_started.connect(func() -> void: info_label.text = "A game is in progress.")
#endregion


#region Private Functions
func _on_join_button_pressed() -> void:
	if not Deckcode.validate(deckcode.text):
		Game.feedback("Invalid deckcode.", Game.FeedbackType.ERROR)
		push_warning("Invalid deckcode.")
		return
	
	Multiplayer.join(
		ip_address.text,
		port.text.to_int() if port.text.is_valid_int() else 4545,
	)
	
	multiplayer.connected_to_server.connect(func() -> void:
		Multiplayer.send_deckcode.rpc_id(1, deckcode.text)
		
		Multiplayer.server_responded.connect(func(success: bool) -> void:
			if not success:
				return
			
			join_button.hide()
			host_button.hide()
			ip_address.hide()
			port.hide()
			deckcode.hide()
			
			info_label.text = "Waiting for another player..."
			info_label.show()
		)
	)


func _on_host_button_pressed() -> void:
	host()


func _on_ip_address_text_submitted(_new_text: String) -> void:
	_on_join_button_pressed()
#endregion
