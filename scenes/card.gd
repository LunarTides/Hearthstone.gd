extends Area3D


@export var card: Card:
	set(new_card):
		card = new_card
		card._ready()
		
		# TODO: Remove
		card.trigger_ability(Enums.ABILITY.CAST)

@export var mesh: Node3D
@export var texture: Sprite3D
@export var name_label: Label3D
@export var cost_label: Label3D
@export var text_label: Label3D
@export var attack_label: Label3D
@export var health_label: Label3D
@export var tribe_label: Label3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update()


func _update() -> void:
	texture.texture = card.texture
	name_label.text = card.name
	cost_label.text = str(card.cost)
	text_label.text = card.text
	attack_label.text = str(card.attack)
	health_label.text = str(card.health)
	
	var tribe_keys: PackedStringArray = PackedStringArray(Enums.TRIBE.keys())
	tribe_label.text = " / ".join(card.tribes.map(func(tribe: Enums.TRIBE) -> String: return tribe_keys[tribe].capitalize()))
	
	mesh.rarity = card.rarities[0]
