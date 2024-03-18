extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"LayoutGraveyard", [&"Layout"], func() -> void:
		LayoutModule.register_layout(&"Graveyard", self.layout_graveyard)
	, func() -> void:
		LayoutModule.unregister_layout(&"Graveyard")
	)
#endregion


#region Public Functions
func layout_graveyard(card: Card) -> Dictionary:
	return {
		"position": card.position,
		"rotation": card.rotation,
		"scale": card.scale,
	}
#endregion
