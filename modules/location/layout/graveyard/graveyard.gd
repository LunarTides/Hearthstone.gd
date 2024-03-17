extends Node


#region Internal Functions
func _ready() -> void:
	LayoutModule.register_layout(&"Graveyard", layout_graveyard)
#endregion


#region Public Functions
func layout_graveyard(card: Card) -> Dictionary:
	return {
		"position": card.position,
		"rotation": card.rotation,
		"scale": card.scale,
	}
#endregion
