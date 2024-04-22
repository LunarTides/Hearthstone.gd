extends Module


#region Module Functions
func _name() -> StringName:
	return &"LayoutGraveyard"


func _dependencies() -> Array[StringName]:
	return [&"Layout"]


func _load() -> void:
	LayoutModule.register_layout(&"Graveyard", layout_graveyard)


func _unload() -> void:
	LayoutModule.unregister_layout(&"Graveyard")
#endregion


#region Public Functions
func layout_graveyard(card: Card) -> Dictionary:
	return {
		"position": card.position,
		"rotation": card.rotation,
		"scale": card.scale,
	}
#endregion
