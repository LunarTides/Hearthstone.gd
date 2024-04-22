extends Module


#region Module Functions
func _name() -> StringName:
	return &"LayoutHero"


func _dependencies() -> Array[StringName]:
	return [&"Layout"]


func _load() -> void:
	LayoutModule.register_layout(&"Hero", layout_hero)


func _unload() -> void:
	LayoutModule.unregister_layout(&"Hero")
#endregion


#region Public Functions
func layout_hero(card: Card) -> Dictionary:
	var new_position: Vector3 = card.position
	
	if card.player == Game.player:
		new_position = (await Game.wait_for_node("/root/Main/PlayerHero")).position
	else:
		new_position = (await Game.wait_for_node("/root/Main/OpponentHero")).position
	
	return {
		"position": new_position,
		"rotation": card.rotation,
		"scale": Vector3.ONE,
	}
#endregion
