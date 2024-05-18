extends Control


#region Exported Variables
@export var show_hide_disabled_text: RichTextLabel
@export var show_hide_enabled_text: RichTextLabel
@export var fps_disabled_label: RichTextLabel

@export var panel: PanelContainer

#region Info
@export_category("Info")
@export var fps_label: RichTextLabel
@export var object_count_label: RichTextLabel
@export var node_count_label: RichTextLabel
@export var orphan_count_label: RichTextLabel
@export var resource_count_label: RichTextLabel
@export var process_time_label: RichTextLabel
@export var physics_process_time_label: RichTextLabel

@export var server_config_label: RichTextLabel
@export var peer_id_label: RichTextLabel
@export var player_id_label: RichTextLabel
@export var latest_packet_label: RichTextLabel
#endregion


#region Debug Buttons
@export_category("Debug Buttons")
@export var debug_buttons_card_id: SpinBox
#endregion


#region Send Packet
@export_category("Send Packet")
@export var send_packet_type: OptionButton
@export var send_packet_player: SpinBox
@export var send_packet_info: LineEdit
#endregion
#endregion


#region Internal Functions
func _ready() -> void:
	panel.hide()
	show_hide_disabled_text.hide()
	show_hide_enabled_text.hide()
	fps_disabled_label.hide()
	
	if OS.is_debug_build():
		show_hide_disabled_text.show()
	else:
		fps_disabled_label.show()
		return
	
	for key: String in Packet.packet_types:
		send_packet_type.add_item(key)
	
	Game.game_started.connect(func() -> void:
		send_packet_player.value = Game.player.id
	)


func _input(event: InputEvent) -> void:
	if not OS.is_debug_build() or event.is_released():
		return
	
	var key: String = event.as_text()
	
	# Show debug panel
	if key == "F1":
		show_hide_enabled_text.visible = not panel.visible
		panel.visible = not panel.visible
		show_hide_disabled_text.visible = not panel.visible


func _on_timer_timeout() -> void:
	fps_disabled_label.text = "FPS: %d" % Performance.get_monitor(Performance.TIME_FPS)
	
	if not OS.is_debug_build() or not panel.visible:
		return
	
	fps_label.text = fps_disabled_label.text
	object_count_label.text = "Object Count: %d" % Performance.get_monitor(Performance.OBJECT_COUNT)
	node_count_label.text = "Node Count: %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	orphan_count_label.text = "Orphan Count: %d" % Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	resource_count_label.text = "Resource Count: %d" % Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	process_time_label.text = "Process Time: %s" % Performance.get_monitor(Performance.TIME_PROCESS)
	physics_process_time_label.text = "Physics Process Time: %s" % Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)

	server_config_label.text = "Server Config: %s" % Settings.server
	
	if multiplayer.multiplayer_peer:
		peer_id_label.text = "Peer ID: %d" % multiplayer.multiplayer_peer.get_unique_id()
	
	if Game.player:
		player_id_label.text = "Player ID: %d" % Game.player.id
	
	if Packet.history.size() > 0:
		var packet: Array = Packet.history[-1]
		var packet_string: String = Packet.get_readable(packet[0], packet[1], packet[2], packet[3])
		
		latest_packet_label.text = "Latest Packet: %s" % packet_string
#endregion


#region Private Functions
func _on_send_packet_button_pressed() -> void:
	if not OS.is_debug_build():
		return
	
	var packet_type: StringName = Packet.packet_types[send_packet_type.selected]
	
	@warning_ignore("narrowing_conversion")
	var player_id: int = send_packet_player.value
	
	var info: Variant = JSON.parse_string(send_packet_info.text)
	if typeof(info) != TYPE_ARRAY:
		Game.feedback("The info needs to be a valid JSON Array.", Game.FeedbackType.ERROR)
		return
	
	Packet.send(packet_type, player_id, info, true)


func _on_info_text_submitted(new_text: String) -> void:
	_on_send_packet_button_pressed()


func _give_card(player: Player) -> void:
	if not Multiplayer.is_server:
		Game.feedback("Only the server can do this.", Game.FeedbackType.ERROR)
		return
	
	@warning_ignore("narrowing_conversion")
	var card: Card = Card.create_from_id(debug_buttons_card_id.value, player)
	
	if not card:
		Game.feedback("Invalid card. There is likely no card with that id.", Game.FeedbackType.ERROR)
		return
	
	player.add_to_hand(card.card, player.hand.size())


func _on_give_player_1_button_pressed() -> void:
	_give_card(Game.player1)


func _on_give_player_2_button_pressed() -> void:
	_give_card(Game.player2)


func _on_end_turn_button_pressed() -> void:
	if not Multiplayer.is_server:
		Game.feedback("Only the server can do this.", Game.FeedbackType.ERROR)
		return
	
	Packet.send(&"End Turn", Game.current_player.id, [], true)


func _on_mana_button_pressed() -> void:
	if not Multiplayer.is_server:
		Game.feedback("REMEMBER TO DO THIS ON THE SERVER TOO", Game.FeedbackType.WARNING)
	else:
		Game.feedback("Set the current player's mana to 10", Game.FeedbackType.INFO)
	
	Game.current_player.mana = 10
#endregion
