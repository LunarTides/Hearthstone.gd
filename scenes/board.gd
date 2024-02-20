extends Node3D


#region Onready Variables
@onready var player1: Area3D = $Player1
@onready var player2: Area3D = $Player2
#endregion


#region Private Variables
var _connected: Array[CardNode]
#endregion


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Game.is_player_2:
		rotation.x += deg_to_rad(180)
		position.z -= 8


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
#endregion


#region Private Functions
func _place_card(player: Player, pos: Vector3) -> void:
	print_debug("Place at %s, id %s" % [pos, player.id])


func _on_player_area_entered(player: Player, area: Area3D) -> void:
	if not area is CardNode:
		return
	
	var card_node: CardNode = area as CardNode
	
	# Dont care if the side of the board is wrong
	if player != Game.player:
		return
	
	card_node.released.connect(func(pos: Vector3) -> void: _place_card(player, pos))
	_connected.append(card_node)


func _on_player_area_exited(player: Player, area: Area3D) -> void:
	if not area is CardNode:
		return
	
	var card_node: CardNode = area as CardNode
	
	for dict: Dictionary in card_node.released.get_connections():
		card_node.released.disconnect(dict.callable)
	
	_connected.erase(card_node)


func _on_player_1_area_entered(area: Area3D) -> void:
	_on_player_area_entered(Game.player1, area)


func _on_player_1_area_exited(area: Area3D) -> void:
	_on_player_area_exited(Game.player1, area)


func _on_player_2_area_entered(area: Area3D) -> void:
	_on_player_area_entered(Game.player2, area)


func _on_player_2_area_exited(area: Area3D) -> void:
	_on_player_area_entered(Game.player2, area)
#endregion
