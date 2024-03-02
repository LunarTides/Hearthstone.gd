extends Area3D


#region Exported Variables 
@export var mesh: Node3D
#endregion


#region Internal Functions
func _ready() -> void:
	rotation.x = deg_to_rad(180 if Game.player == Game.player2 else 0)
	
	Packet.packet_received_before.connect(func(_sender_peer_id: int, packet_type: Packet.PacketType, player_id: int, _info: Array) -> void:
		if packet_type != Packet.PacketType.END_TURN:
			return
		
		var degrees: float = 180 if player_id == Game.player.id else 0
		
		var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK)
		tween.tween_property(self, "rotation:x", deg_to_rad(degrees), 0.5)
	)
#endregion


#region Private Functions
func _on_input_event(camera: Node, event: InputEvent, position: Vector3, normal: Vector3, shape_idx: int) -> void:
	# Release lmb
	if not event is InputEventMouseButton:
		return
	
	if not event.is_released():
		return
	
	if not event.button_index == MOUSE_BUTTON_LEFT:
		return
	
	if Multiplayer.is_server and Game.is_players_turn:
		Game.feedback("The server is the ultimate authority. This would work without this safeguard.", Game.FeedbackType.WARNING)
		return
	
	Game.end_turn()


func _on_mouse_entered() -> void:
	if not Game.is_players_turn:
		mesh.get_node("Border").get_active_material(0).albedo_color = Color.YELLOW
		return
	
	mesh.get_node("Border").get_active_material(0).albedo_color = Color.GREEN


func _on_mouse_exited() -> void:
	mesh.get_node("Border").get_active_material(0).albedo_color = Color.WHITE
#endregion
