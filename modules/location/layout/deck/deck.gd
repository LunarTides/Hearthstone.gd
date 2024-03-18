extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"LayoutDeck", [&"Layout"], func() -> void:
		LayoutModule.register_layout(&"Deck", self.layout_deck)
	, func() -> void:
		LayoutModule.unregister_layout(&"Deck")
	)
#endregion


#region Public Functions
func layout_deck(card: Card) -> Dictionary:
	return {
		"position": card.position,
		"rotation": card.rotation,
		"scale": card.scale,
	}
#endregion
