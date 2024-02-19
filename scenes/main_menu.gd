extends Control


@export var join_button: Button
@export var host_button: Button
@export var ip_address: LineEdit
@export var host_label: Label


func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args() or OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless":
		host()


func host() -> void:
	print("Waiting for a client to connect...")
	
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(Game.PORT, Game.MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer


func _on_join_button_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(ip_address.text, Game.PORT)
	multiplayer.multiplayer_peer = peer
	
	if error == OK:
		join_button.hide()
		host_button.hide()
		ip_address.hide()
		
		host_label.text = "Waiting for another player..."
		host_label.show()


func _on_host_button_pressed() -> void:
	join_button.hide()
	host_button.hide()
	ip_address.hide()
	
	host_label.text = "Please wait for a client to connect..."
	host_label.show()
	host()
	
	Game.game_started.connect(func() -> void: host_label.text = "A game is in progress.")


func _on_ip_address_text_submitted(_new_text: String) -> void:
	_on_join_button_pressed()
