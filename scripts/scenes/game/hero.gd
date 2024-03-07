class_name HeroNode
extends Area3D


#region Exported Variables
# TODO: Implement a better system. Use an actual hero card.
@export var health_label: Label3D
#endregion


#region Public Variables
var player: Player
#endregion


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not player:
		return
	
	health_label.text = "Health: %d/%d" % [player.health, player.max_health]
#endregion
