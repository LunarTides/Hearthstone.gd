extends Node


const CardScene: PackedScene = preload("res://scenes/card.tscn")

const PORT: int = 4545
const MAX_CLIENTS: int = 2

const CARD_BOUNDS_X: float = 9.05
const CARD_BOUNDS_Y: float = -0.5
const CARD_BOUNDS_Z: float = 7 # 3.62
const CARD_BOUNDS_ROTATION_Y: float = 21.2
const CARD_DISTANCE_X: float = 1.81

var player: Player
var opponent: Player

var current_player: Player = Player.new()
var opposing_player: Player = Player.new()


func _ready() -> void:
	multiplayer.peer_disconnected.connect(func(_id: int) -> void:
		multiplayer.multiplayer_peer = null
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	multiplayer.peer_connected.connect(func(_id: int) -> void:
		start_game()
	)


func _unhandled_input(event: InputEvent) -> void:
	# TODO: Make a better way to quit
	if event.as_text() == "Escape":
		get_tree().quit()


func start_game() -> void:
	if not multiplayer.is_server():
		return
	
	var id: int = randi_range(0, 1)
	print_debug("Server has id", id)
	
	assign_player(id)
	assign_player.rpc(1 - id)
	
	change_scene_to_file.rpc("res://scenes/game.tscn")


@rpc("authority", "call_remote", "reliable")
func assign_player(id: int) -> void:
	player = Player.new()
	player.id = id
	
	opponent = Player.new()
	opponent.id = 1 - id


@rpc("authority", "call_local", "reliable")
func change_scene_to_file(file: StringName) -> void:
	get_tree().change_scene_to_file(file)


func place_card_in_hand(card: Card, index: int) -> CardNode:
	card.index = index
	
	var card_node: CardNode = CardScene.instantiate()
	card_node.card = card
	card_node.layout()
	
	return card_node


func layout_cards(player: Player) -> void:
	for card: CardNode in get_card_nodes_for_player(player):
		card.layout()


func get_cards_for_player(player: Player) -> Array[Card]:
	return get_card_nodes_for_player(player).map(func(card_node: CardNode) -> Card: return card_node.card)


func get_card_nodes_for_player(player: Player) -> Array[CardNode]:
	return get_tree().get_nodes_in_group("Cards").filter(func(card_node: CardNode) -> bool:
		return card_node.card.player == player
	)
