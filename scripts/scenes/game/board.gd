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

@onready var timer: Timer = $Timer
#endregion


#region Private Variables
var _connected: Array[Card]
#endregion


#region Internal Functions
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Game.is_player_2:
		rotation.x += deg_to_rad(180)
		position.z -= 8
	
	# Use a timer to improve performance.
	timer.timeout.connect(func() -> void:
		for card: Card in Card.get_all().filter(func(card: Card) -> bool: return not _connected.has(card)):
			card.released.connect(func(pos: Vector3) -> void:
				if card.location == Card.Location.HAND and self["player%d" % (card.player.id + 1)].get_overlapping_areas().has(card):
					_place_card(card.player, card, pos)
			)
			_connected.append(card)
	)
#endregion


#region Private Functions
func _place_card(player: Player, card: Card, pos: Vector3) -> void:
	var index: int = _get_index(pos, player)
	player.play_card(card, index)


func _get_index(pos: Vector3, player: Player) -> int:
	return Card.get_all_owned_by(player).filter(func(card: Card) -> bool:
		return card.global_position.x < pos.x and card.location == Card.Location.BOARD
	).size()
#endregion
