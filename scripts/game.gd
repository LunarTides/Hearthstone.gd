extends Node
## The main singleton with a lot of helper functions.
## @experimental


#region Signals
## Emits when the game starts
signal game_started
#endregion


#region Constant Variables
const CardScene: PackedScene = preload("res://scenes/card.tscn")
const Sheep: Blueprint = preload("res://cards/sheep/sheep.tres")

# There should be a better way of doing this.
const CARD_BOUNDS_X: float = 9.05
const CARD_BOUNDS_Y: float = -0.5
const CARD_BOUNDS_Z: float = 13
const CARD_BOUNDS_ROTATION_Y: float = 21.2
const CARD_DISTANCE_X: float = 1.81
#endregion


#region Public Variables
## The player assigned to this client.
var player: Player

## The player assigned to the opponent client.
var opponent: Player

## The player whose turn it is.
var current_player: Player

## The opposing player to the player whose turn it is.
var opposing_player: Player

## The player who starts first. ONLY ASSIGNED CLIENT SIDE.
var player1: Player:
	get:
		if not player:
			return null
		
		return player if player.id == 0 else opponent

## The player who starts with the coin. ONLY ASSIGNED CLIENT SIDE.
var player2: Player:
	get:
		if not player:
			return null
		
		return player if player.id == 1 else opponent

## The player who starts first. ONLY ASSIGNED SERVER SIDE.
var player1_server: Player

## The player who starts with the coin. ONLY ASSIGNED SERVER SIDE.
var player2_server: Player

## If this client is [member player1].
var is_player_1: bool:
	get:
		return player.id == 0

## If this client is [member player2].
var is_player_2: bool:
	get:
		return player.id == 1

# Config
var max_board_space: int = 7
var max_hand_size: int = 10

var max_players: int = 2
# ------

## Returns the board node
var board_node: BoardNode:
	get:
		return get_node("/root/Main/Board") as BoardNode
#endregion


#region Internal Functions
func _unhandled_input(event: InputEvent) -> void:
	if event.is_released():
		return
	
	var key: String = event.as_text()
	
	# TODO: Make a better way to quit
	if key == "Escape":
		get_tree().quit()
	
	# TODO: Remove debug commands
	if key == "F1":
		layout_cards(player)
		layout_cards(opponent)
	
	# F2 reveals a friendly card
	elif key == "F2":
		var cards: Array[Card] = get_cards_for_player(player).filter(func(card: Card) -> bool: return not card.is_hidden)
		if cards.size() <= 0:
			return
		
		var card: Card = cards.pick_random()
		
		send_packet(Enums.PACKET_TYPE.REVEAL, player.id, {"location": card.location, "index": card.index})
	
	# F3 reveals an enemy card. This should trigger the anticheat and drop the packet.
	elif key == "F3":
		var cards: Array[Card] = get_cards_for_player(opponent).filter(func(card: Card) -> bool: return card.is_hidden)
		if cards.size() <= 0:
			return
		
		var card: Card = cards.pick_random()
		
		send_packet(Enums.PACKET_TYPE.REVEAL, opponent.id, {"location": card.location, "index": card.index})
#endregion


#region Public Functions
## Gets the [Player] with the specified [param id].
func get_player_from_id(id: int) -> Player:
	if multiplayer.is_server():
		if id == 0:
			return player1_server
		else:
			return player2_server
	
	if id == 0:
		return player1
	else:
		return player2


## Gets the [param player]'s [Card] in [param location] at [param index].
func get_card_from_index(player: Player, location: Enums.LOCATION, index: int) -> Card:
	match location:
		Enums.LOCATION.HAND:
			return player.hand[index]
		Enums.LOCATION.DECK:
			return player.deck[index]
		Enums.LOCATION.BOARD:
			return player.board[index]
		Enums.LOCATION.GRAVEYARD:
			return player.graveyard[index]
		_:
			return null


## Starts the game. Assigns an id to each player and changes scene to the game scene.
## Only the server can do this.
func start_game() -> void:
	if not multiplayer.is_server():
		return
	
	var id: int = randi_range(0, max_players - 1)
	
	var i: int = 0
	for peer: int in multiplayer.get_peers():
		var player: Player = Player.new()
		var player_id: int
		
		if i == 0:
			player_id = id
		else:
			player_id = 1 - id
		
		player.id = player_id
		Multiplayer.players[peer] = player
		
		if id == i:
			player1_server = player
		else:
			player2_server = player
		
		Multiplayer.assign_player.rpc_id(peer, player_id)
		
		print("Client %s assigned id: %s" % [peer, player_id])
		
		i += 1
	
	print("Changing to game scene...")
	Multiplayer.change_scene_to_file.rpc("res://scenes/game.tscn")
	
	game_started.emit()
	
	# TODO: Remove
	# Spawn 10 cards for each player
	var amount: int = 10
	
	for index: int in range(amount * 2):
		var card_player: Player = Multiplayer.players.values()[0]
		
		if index >= amount:
			index -= amount
			card_player = Multiplayer.players.values()[1]
		
		var card: Card = Card.new()
		card.blueprint = Sheep
		card.player = card_player
		
		_place_card_in_hand(card, index)


## Lays out all the cards for the specified player. Only works client side.
func layout_cards(player: Player) -> void:
	if multiplayer.is_server():
		return
	
	for card: CardNode in get_card_nodes_for_player(player):
		card.layout()


## Gets all [Card]s for the specified player.
func get_cards_for_player(player: Player) -> Array[Card]:
	return get_all_cards().filter(func(card: Card) -> bool: return card.player == player)


## Gets all [Card]s currently in the game scene.
func get_all_cards() -> Array[Card]:
	var array: Array[Card] = []
	
	array.assign(get_all_card_nodes().map(func(card_node: CardNode) -> Card:
		return card_node.card
	))
	
	return array


## Gets all [CardNode]s for the specified player.
func get_card_nodes_for_player(player: Player) -> Array[CardNode]:
	var array: Array[CardNode] = []
	
	array.assign(get_all_card_nodes().filter(func(card_node: CardNode) -> bool:
		if not card_node.card:
			return false
		
		return card_node.card.player == player
	))
	
	return array


## Gets all [CardNode]s currently in the game scene.
func get_all_card_nodes() -> Array[CardNode]:
	# ???
	var array: Array[CardNode] = []
	array.assign(get_tree().get_nodes_in_group("Cards"))
	return array


## Waits for a node at the specified [param node_path] to exist before returning it.[br]
## Use [code]await[/code] on this.
func wait_for_node(node_path: NodePath) -> Node:
	while not get_node_or_null(node_path):
		await get_tree().create_timer(0.1).timeout
	
	return get_node(node_path)


## Exits to the main menu. This disconnects from the server.
func exit_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


## Sends a packet to the server that will be sent to all the clients.[br]
## This is used to sync every action.
func send_packet(message: Enums.PACKET_TYPE, player_id: int, info: Dictionary) -> void:
	Multiplayer.send_packet(message, player_id, info)
#endregion


#region Private Functions
func _place_card_in_hand(card: Card, index: int) -> CardNode:
	card.location = Enums.LOCATION.HAND
	
	card.player.add_to_hand(card, index)
	
	var card_node: CardNode = CardScene.instantiate()
	card_node.card = card
	card_node.layout()
	
	layout_cards(card.player)
	
	return card_node
#endregion
