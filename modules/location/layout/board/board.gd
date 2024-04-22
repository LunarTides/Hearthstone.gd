extends Module


#region Module Functions
func _name() -> StringName:
	return &"LayoutBoard"


func _dependencies() -> Array[StringName]:
	return [&"Layout"]


func _load() -> void:
	LayoutModule.register_layout(&"Board", layout_board)


func _unload() -> void:
	LayoutModule.unregister_layout(&"Board")
#endregion


#region Public Functions
func layout_board(card: Card) -> Dictionary:
	var new_position: Vector3 = card.position
	var new_rotation: Vector3 = card.rotation
	var new_scale: Vector3 = card.scale
	
	var player_weight: int = 1 if card.player == Game.player else -1
	
	new_rotation = Vector3.ZERO
	
	new_position.x = (card.index - 4) * 3.5 + Settings.client.card_distance_x
	new_position.y = 0
	new_position.z = Game.board_node.player.position.z + player_weight * (
		# I love hardcoded values.
		3 if Game.is_player_1
		else -6 if card.player == Game.opponent
		else 11
	)
	
	if Game.is_player_1 and card.player == Game.opponent:
		new_position.z += 1
	
	new_scale = Vector3.ONE
	
	return {
		"position": new_position,
		"rotation": new_rotation,
		"scale": new_scale,
	}
#endregion
