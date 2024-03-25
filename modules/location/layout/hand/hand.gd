extends Module


#region Module Functions
func _name() -> StringName:
	return &"LayoutHand"


func _dependencies() -> Array[StringName]:
	return [
		&"Layout",
	]


func _load() -> void:
	LayoutModule.register_layout(&"Hand", layout_hand)


func _unload() -> void:
	LayoutModule.unregister_layout(&"Hand")
#endregion


#region Public Functions
func layout_hand(card: Card) -> Dictionary:
	var new_position: Vector3 = card.position
	var new_rotation: Vector3 = card.rotation
	var new_scale: Vector3 = card.scale
	
	# TODO: Dont hardcode this.
	var player_weight: int = 1 if card.player == Game.player else -1
	
	# Integer division, but it's not a problem.
	@warning_ignore("integer_division")
	var half_hand_size: int = card.player.hand.size() / 2
	
	new_position.x = -(half_hand_size * 2) + Settings.client.card_bounds_x + (card.index * Settings.client.card_distance_x)
	new_position.y = Settings.client.card_bounds_y * abs(half_hand_size - card.index)
	new_position.z = Settings.client.card_bounds_z * player_weight
	
	new_rotation = Vector3.ZERO
	
	if card.index != half_hand_size:
		# Tilt it to the left/right.
		new_rotation.y = deg_to_rad(Settings.client.card_rotation_y_multiplier * player_weight * (half_hand_size - card.index))
	
	# Position it futher away the more rotated it is.
	# This makes it easier to select the right card.
	new_position.x -= new_rotation.y * player_weight
	
	# Rotate the card 180 degrees if it isn't already
	if card.player != Game.player and new_rotation.y < PI:
		new_rotation.y += PI
	
	new_scale = Vector3.ONE
	
	return {
		"position": new_position,
		"rotation": new_rotation,
		"scale": new_scale,
	}
#endregion
