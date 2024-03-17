extends Node


#region Internal Functions
func _ready() -> void:
	LayoutModule.register_layout(&"Deck", layout_deck)
#endregion


#region Public Functions
func layout_deck(card: Card) -> Dictionary:
	return {
		"position": card.position,
		"rotation": card.rotation,
		"scale": card.scale,
	}
#endregion
