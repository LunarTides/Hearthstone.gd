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

## The port of the multiplayer server.
const PORT: int = 4545

## The max amount of clients. The game only supports 2.
const MAX_CLIENTS: int = 2

# There should be a better way of doing this.
const CARD_BOUNDS_X: float = 9.05
const CARD_BOUNDS_Y: float = -0.5
const CARD_BOUNDS_Z: float = 13
const CARD_BOUNDS_ROTATION_Y: float = 21.2
const CARD_DISTANCE_X: float = 1.81

const MAX_BOARD_SPACE: int = 7
const MAX_HAND_SIZE: int = 10

const MAX_PLAYERS: int = 2
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

## The players of the game. ONLY ASSIGNED SERVER-SIDE.[br][br]
## Looks like this:
## [code]{"2732163217": Player, "432769823": Player}[/code]
var players: Dictionary = {}

## If this client is [member player1].
var is_player_1: bool:
	get:
		return player.id == 0

## If this client is [member player2].
var is_player_2: bool:
	get:
		return player.id == 1

## Returns the board node
var board_node: BoardNode:
	get:
		return get_node("/root/Main/Board") as BoardNode
#endregion


#region Internal Functions
func _ready() -> void:
	multiplayer.server_disconnected.connect(func() -> void:
		exit_to_main_menu()
	)
	multiplayer.peer_disconnected.connect(func(_id: int) -> void:
		exit_to_main_menu()
	)
	multiplayer.peer_connected.connect(func(_id: int) -> void:
		if not multiplayer.is_server():
			return
		
		var clients: int = multiplayer.get_peers().size()
		
		if clients < MAX_CLIENTS:
			print("Client connected, waiting for %d more..." % (MAX_PLAYERS - clients))
			return
		
		print("Client connected, starting game...")
		start_game()
	)


func _unhandled_input(event: InputEvent) -> void:
	# TODO: Make a better way to quit
	if event.as_text() == "Escape":
		get_tree().quit()
	
	# TODO: Remove debug commands
	if event.as_text() == "F1":
		layout_cards(player)
		layout_cards(opponent)
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


## Starts the game. Assigns an id to each player and changes scene to the game scene.
## Only the server can do this.
func start_game() -> void:
	if not multiplayer.is_server():
		return
	
	var id: int = randi_range(0, MAX_PLAYERS - 1)
	
	var i: int = 0
	for peer: int in multiplayer.get_peers():
		var player: Player = Player.new()
		var player_id: int
		
		if i == 0:
			player_id = id
		else:
			player_id = 1 - id
		
		player.id = player_id
		players[peer] = player
		
		if id == i:
			player1_server = player
		else:
			player2_server = player
		
		assign_player.rpc_id(peer, player_id)
		
		print("Client %s assigned id: %s" % [peer, player_id])
		
		i += 1
	
	print("Changing to game scene...")
	change_scene_to_file.rpc("res://scenes/game.tscn")
	
	game_started.emit()
	
	# TODO: Remove
	# Spawn 10 cards for each player
	var amount: int = 10
	
	for index: int in range(amount * 2):
		var card_player: Player = players.values()[0]
		
		if index >= amount:
			index -= amount
			card_player = players.values()[1]
		
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
	return get_card_nodes_for_player(player).map(func(card_node: CardNode) -> Card: return card_node.card)


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


## Exits to the main menu. This disconnects from the server.
func exit_to_main_menu() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")
#endregion


#region RPC Functions
## Assigns [param id] to a client. CAN ONLY BE CALLED SERVER SIDE.
@rpc("authority", "call_remote", "reliable")
func assign_player(id: int) -> void:
	player = Player.new()
	player.id = id
	
	opponent = Player.new()
	opponent.id = 1 - id


## Makes the client switch to a scene. CAN ONLY BE CALLED SERVER SIDE.
@rpc("authority", "call_remote", "reliable")
func change_scene_to_file(file: StringName) -> void:
	get_tree().change_scene_to_file(file)


## Sends a message to the game that will be sent to all the clients.[br]
## This is used to sync every action.
@rpc("any_peer", "call_local", "reliable")
func msg(message: Enums.GAME_MULTIPLAYER_MESSAGE, sender_player_id: int, info: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	
	# The 0th element is the sender_player, the 1th element is the other_player
	var sorted_player_keys: Array = players.keys()
	sorted_player_keys.sort_custom(func(a: int, b: int) -> bool:
		return players[a].id == sender_player_id
	)
	
	var sender_player: Player = players[sorted_player_keys[0]]
	var other_player: Player = players[sorted_player_keys[1]]
	
	# TODO: Anticheat
	match message:
		# Summon
		Enums.GAME_MULTIPLAYER_MESSAGE.SUMMON:
			var hand_index: int = info.hand_index
			var board_index: int = info.board_index
			
			_accept_summon_card.rpc(sender_player.id, Enums.LOCATION.HAND, hand_index, board_index)
		
		# Add to hand
		Enums.GAME_MULTIPLAYER_MESSAGE.ADD_TO_HAND:
			var blueprint_path: NodePath = info.blueprint_path
			var index: int = info.index
			
			spawn_card.rpc(blueprint_path, sender_player.id, Enums.LOCATION.HAND, index)


## Spawns in a card. THIS HAS TO BE CALLED SERVER SIDE. USE [method msg] FOR CLIENT SIDE.
@rpc("authority", "call_local", "reliable")
func spawn_card(blueprint_path: NodePath, player_id: int, location: Enums.LOCATION, index: int) -> void:
	var card: Card = Card.new()
	card.blueprint = load(str(blueprint_path))
	card.player = Game.get_player_from_id(player_id)
	card.location = location
	card.add_to_location(index)
	
	var card_node: CardNode = CardScene.instantiate()
	card_node.card = card
	
	if multiplayer.is_server():
		add_child(card_node)
		return
	
	while not get_node_or_null("/root/Main"):
		await get_tree().create_timer(0.1).timeout
	
	get_node("/root/Main").add_child(card_node)
	Game.layout_cards(card.player)


## Summons a card as requested by the server. THIS HAS TO BE CALLED SERVER SIDE. USE [method msg] FOR CLIENT SIDE.
@rpc("authority", "call_local", "reliable")
func _accept_summon_card(player_id: int, location: Enums.LOCATION, location_index: int, board_index: int) -> void:
	var player: Player = Game.get_player_from_id(player_id)
	
	if location != Enums.LOCATION.HAND:
		return
	if player.board.size() >= Game.MAX_BOARD_SPACE:
		return
	
	var card: Card = player.hand[location_index]
	
	card.location = Enums.LOCATION.BOARD
	card.add_to_location(board_index)
	
	layout_cards(player)
#endregion


#region Private Functions
## Places a [Card] in its player's hand at some index. You shouldn't touch this.
func _place_card_in_hand(card: Card, index: int) -> CardNode:
	card.location = Enums.LOCATION.HAND
	
	card.player.add_to_hand(card, index)
	
	var card_node: CardNode = CardScene.instantiate()
	card_node.card = card
	card_node.layout()
	
	layout_cards(card.player)
	
	return card_node
#endregion
