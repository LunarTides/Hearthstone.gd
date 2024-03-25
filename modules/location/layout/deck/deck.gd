extends Module


#region Module Functions
func _name() -> StringName:
	return &"LayoutDeck"


func _dependencies() -> Array[StringName]:
	return [
		&"Layout",
	]


func _load() -> void:
	LayoutModule.register_layout(&"Deck", layout_deck)


func _unload() -> void:
	LayoutModule.unregister_layout(&"Deck")
#endregion


#region Public Functions
func layout_deck(card: Card) -> Dictionary:
	return {
		"position": card.position,
		"rotation": card.rotation,
		"scale": card.scale,
	}
#endregion
