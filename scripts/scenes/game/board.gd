class_name BoardNode
extends Node3D
## @experimental


#region Public Variables
var player: Area3D:
	get:
		return player1 if Game.is_player_1 else player2

var current_player: Area3D:
	get:
		return player1 if Game.current_player == Game.player1 else player2
#endregion


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
#endregion


#region Private Functions
func _place_card(player: Player, card_node: CardNode, pos: Vector3) -> void:
	for dict: Dictionary in card_node.released.get_connections():
		card_node.released.disconnect(dict.callable)
	
	var index: int = _get_index(pos, player)
	player.play_card(card_node.card, index)


func _get_index(pos: Vector3, player: Player) -> int:
	return Game.get_card_nodes_for_player(player).filter(func(card_node: CardNode) -> bool:
		return card_node.global_position.x < pos.x and card_node.card.location == Enums.LOCATION.BOARD
	).size()


func _on_player_area_entered(player: Player, area: Area3D) -> void:
	if not area is CardNode:
		return
	
	var card_node: CardNode = area as CardNode
	var card: Card = card_node.card
	
	# Dont care if the side of the board is wrong
	if player != Game.player:
		return
	
	if card_node.card.location != Enums.LOCATION.HAND:
		return
	
	card_node.released.connect(func(pos: Vector3) -> void: _place_card(player, card_node, pos))
	_connected.append(card_node)


func _on_player_area_exited(area: Area3D) -> void:
	if not area is CardNode:
		return
	
	var card_node: CardNode = area as CardNode
	
	for dict: Dictionary in card_node.released.get_connections():
		card_node.released.disconnect(dict.callable)
	
	_connected.erase(card_node)


func _on_player_1_area_entered(area: Area3D) -> void:
	_on_player_area_entered(Game.player1, area)


func _on_player_1_area_exited(area: Area3D) -> void:
	_on_player_area_exited(area)


func _on_player_2_area_entered(area: Area3D) -> void:
	_on_player_area_entered(Game.player2, area)


func _on_player_2_area_exited(area: Area3D) -> void:
	_on_player_area_exited(area)
#endregion
