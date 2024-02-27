extends Area3D


#region Exported Variables 
@export var mesh: MeshInstance3D
#endregion


#region Internal Functions
func _ready() -> void:
	rotation.x = deg_to_rad(180 if Game.player == Game.player2 else 0)
	
	Packet.packet_received_before.connect(func(_sender_peer_id: int, packet_type: Enums.PACKET_TYPE, player_id: int, _info: Array) -> void:
		if not packet_type == Enums.PACKET_TYPE.END_TURN:
			return
		
		var tween: Tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_BACK)
		
		var degrees: float = 180 if player_id == Game.player.id else 0
		
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
		Game.error_text = "The server is the ultimate authority. This would work without this safeguard."
		return
	
	Game.end_turn()


func _on_mouse_entered() -> void:
	if not Game.is_players_turn:
		mesh.get_active_material(0).albedo_color = Color.YELLOW
		return
	
	mesh.get_active_material(0).albedo_color = Color.GREEN


func _on_mouse_exited() -> void:
	mesh.get_active_material(0).albedo_color = Color.hex(0x302f00)
#endregion
