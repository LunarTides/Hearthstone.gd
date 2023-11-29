extends Area3D

@export var card: Card

# Called when the node enters the scene tree for the first time.
func _ready():
	card.trigger(Enums.ABILITY.CAST)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
