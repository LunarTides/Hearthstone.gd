extends Control


@export var join_button: Button
@export var host_button: Button
@export var ip_address: LineEdit
@export var port: LineEdit
@export var info_label: Label
@export var console_tip: Label


func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args() or OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		_on_host_button_pressed()


func host() -> void:
	join_button.hide()
	host_button.hide()
	ip_address.hide()
	port.hide()
	console_tip.show()
	
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


func _on_join_button_pressed() -> void:
	# TODO: Add a deckcode input
	Multiplayer.peer.create_client(ip_address.text if ip_address.text else "localhost", port.text.to_int() if port.text.is_valid_int() else 4545)
	multiplayer.multiplayer_peer = Multiplayer.peer
	
	multiplayer.connected_to_server.connect(func() -> void:
		join_button.hide()
		host_button.hide()
		ip_address.hide()
		port.hide()
		
		info_label.text = "Waiting for another player..."
		info_label.show()
	)


func _on_host_button_pressed() -> void:
	host()


func _on_ip_address_text_submitted(_new_text: String) -> void:
	_on_join_button_pressed()
