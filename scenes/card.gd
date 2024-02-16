extends Area3D


@export var card: Card


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	card._ready()
	card.trigger_ability(Enums.ABILITY.CAST)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
