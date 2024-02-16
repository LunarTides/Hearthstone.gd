extends Area3D


@export var card: Card

@export var texture: Sprite3D
@export var name_label: Label3D
@export var cost_label: Label3D
@export var text_label: Label3D
@export var attack_label: Label3D
@export var health_label: Label3D
@export var tribe_label: Label3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card._ready()
	card.trigger_ability(Enums.ABILITY.CAST)
	
	texture.texture = card.texture
	name_label.text = card.name
	cost_label.text = str(card.cost)
	text_label.text = card.text
	attack_label.text = str(card.attack)
	health_label.text = str(card.health)
	
	var tribe_keys: PackedStringArray = PackedStringArray(Enums.TRIBE.keys())
	tribe_label.text = " / ".join(card.tribes.map(func(tribe: Enums.TRIBE) -> String: return tribe_keys[tribe].capitalize()))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
