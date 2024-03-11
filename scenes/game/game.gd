extends Node3D


#region Exported Variables
@export var player_hero_node: HeroNode
@export var opponent_hero_node: HeroNode
#endregion


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_hero_node.player = Game.player
	opponent_hero_node.player = Game.opponent
#endregion
