extends Module


#region Module Functions
func _name() -> StringName:
	return &"LayoutHeroPower"


func _dependencies() -> Array[StringName]:
	return [&"Layout"]


func _load() -> void:
	LayoutModule.register_layout(&"Hero Power", layout_hero_power)


func _unload() -> void:
	LayoutModule.unregister_layout(&"Hero Power")
#endregion


#region Public Functions
func layout_hero_power(card: Card) -> Dictionary:
	var new_position: Vector3 = card.position
	
	if card.player == Game.player:
		new_position = (await Game.wait_for_node("/root/Main/PlayerHero")).position
	else:
		new_position = (await Game.wait_for_node("/root/Main/OpponentHero")).position
	
	new_position.x -= 3
	
	var new_rotation: Vector3 = Vector3.ZERO
	
	if card.player.has_used_hero_power_this_turn:
		card.force_cover_visible = true
		card.cover.position.y = -0.5
		card.cover.rotation_degrees.x = 180
		card.cover.show()
		
		new_rotation.x = PI
	
	return {
		"position": new_position,
		"rotation": new_rotation,
		"scale": Vector3(0.5, 0.5, 0.5),
	}
#endregion
