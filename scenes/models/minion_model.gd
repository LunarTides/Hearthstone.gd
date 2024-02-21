extends Node3D


@export var rarity: Enums.RARITY:
	set(new_rarity):
		rarity = new_rarity
		
		if is_inside_tree():
			_update()

@export var covered: bool:
	set(new_covered):
		covered = new_covered
		for child: Node3D in get_children():
			child.visible = not covered
		
		$Cover.visible = covered


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update()


func _update() -> void:
	var rarity_node: MeshInstance3D = get_node("Rarity")
	rarity_node.mesh.surface_get_material(0).albedo_color = Enums.RARITY_COLOR.get(rarity)
