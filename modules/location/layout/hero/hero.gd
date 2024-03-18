extends Node


#region Internal Functions
func _ready() -> void:
	Modules.register(&"LayoutHero", [&"Layout"], func() -> void:
		LayoutModule.register_layout(&"Hero", self.layout_hero)
	, func() -> void:
		LayoutModule.unregister_layout(&"Hero")
	)
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
