extends Control


@export var join_button: Button
@export var host_button: Button
@export var ip_address: LineEdit
@export var host_label: Label


func _on_join_button_pressed() -> void:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address.text, Game.PORT)
	multiplayer.multiplayer_peer = peer


func _on_host_button_pressed() -> void:
	join_button.hide()
	host_button.hide()
	ip_address.hide()
	host_label.show()
	
	
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	peer.create_server(Game.PORT, Game.MAX_CLIENTS)
	multiplayer.multiplayer_peer = peer


func _on_ip_address_text_submitted(_new_text: String) -> void:
	_on_join_button_pressed()
