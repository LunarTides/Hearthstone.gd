extends Control


#region Exported Variables
@export var show_hide_text: RichTextLabel

@export var panel: Panel

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

@export var send_packet_type: OptionButton
@export var send_packet_player: SpinBox
@export var send_packet_info: LineEdit
#endregion


#region Internal Functions
func _ready() -> void:
	panel.hide()
	show_hide_text.hide()
	
	if OS.is_debug_build():
		show_hide_text.show()
	else:
		queue_free()
	
	for key: String in Packet.PacketType.keys():
		send_packet_type.add_item(key)
	
	Game.game_started.connect(func() -> void:
		send_packet_player.value = Game.player.id
	)


func _input(event: InputEvent) -> void:
	if event.is_released():
		return
	
	var key: String = event.as_text()
	
	# Show debug panel
	if key == "F1":
		panel.visible = not panel.visible
		show_hide_text.visible = not panel.visible
	# Set 10 mana
	elif key == "F2":
		if not Multiplayer.is_server:
			Game.feedback("REMEMBER TO DO THIS ON THE SERVER TOO", Game.FeedbackType.WARNING)
		else:
			Game.feedback("Set the current player's mana to 10", Game.FeedbackType.INFO)
		
		Game.current_player.mana = 10


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	fps_label.text = "FPS: %d" % Performance.get_monitor(Performance.TIME_FPS)
	object_count_label.text = "Object Count: %d" % Performance.get_monitor(Performance.OBJECT_COUNT)
	node_count_label.text = "Node Count: %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	orphan_count_label.text = "Orphan Count: %d" % Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	resource_count_label.text = "Resource Count: %d" % Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
	process_time_label.text = "Process Time: %d" % Performance.get_monitor(Performance.TIME_PROCESS)
	physics_process_time_label.text = "Physics Process Time: %d" % Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	
	server_config_label.text = "Server Config: {max_board_space: %s, hand_hand_size: %s}" % [Game.max_board_space, Game.max_hand_size]
	
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
	var packet_type: Packet.PacketType = Packet.PacketType.values()[send_packet_type.selected]
	
	@warning_ignore("narrowing_conversion")
	var player_id: int = send_packet_player.value
	
	var info: Variant = JSON.parse_string(send_packet_info.text)
	if typeof(info) != TYPE_ARRAY:
		Game.feedback("The info needs to be a valid JSON Array.", Game.FeedbackType.ERROR)
		return
	
	Packet.send(packet_type, player_id, info, true)


func _on_info_text_submitted(new_text: String) -> void:
	_on_send_packet_button_pressed()
#endregion
