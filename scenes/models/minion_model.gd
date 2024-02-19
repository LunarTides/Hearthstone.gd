extends Node3D


@export var rarity: Enums.RARITY:
	set(new_rarity):
		rarity = new_rarity
		
		if is_inside_tree():
			_update()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update()


func _update() -> void:
	$Rarity.material_override.albedo_color = Enums.RARITY_COLOR.get(rarity)