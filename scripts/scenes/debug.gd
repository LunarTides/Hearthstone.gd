extends Control


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


func _ready() -> void:
	panel.hide()
	show_hide_text.hide()
	
	if OS.is_debug_build():
		show_hide_text.show()
	else:
		queue_free()
	
	for key: String in Enums.PACKET_TYPE.keys():
		send_packet_type.add_item(key)


func _input(event: InputEvent) -> void:
	if event.as_text() == "F1" and event.is_pressed():
		panel.visible = not panel.visible
		show_hide_text.visible = not panel.visible


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
		var packet_string: String = Packet.get_readable_packet(packet[0], packet[1], packet[2], packet[3])
		
		latest_packet_label.text = "Latest Packet: %s" % packet_string


func _on_send_packet_button_pressed() -> void:
	var packet_type: Enums.PACKET_TYPE = Enums.PACKET_TYPE.values()[send_packet_type.selected]
	var player_id: int = send_packet_player.value
	var info: Array = JSON.parse_string(send_packet_info.text)
	
	Game.send_packet(packet_type, player_id, info, true)


func _on_info_text_submitted(new_text: String) -> void:
	_on_send_packet_button_pressed()
