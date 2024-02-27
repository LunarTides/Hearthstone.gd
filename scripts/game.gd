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
const TheCoin: Blueprint = preload("res://cards/the-coin/the-coin.tres")

# There should be a better way of doing this.
const CARD_BOUNDS_X: float = 9.05
const CARD_BOUNDS_Y: float = -0.5
const CARD_BOUNDS_Z: float = 13
const CARD_BOUNDS_ROTATION_Y: float = 21.2
const CARD_DISTANCE_X: float = 1.81
#endregion


#region Public Variables
## The player assigned to this client.
var player: Player:
	get:
		if Multiplayer.is_server:
			return player1
		
		return player

## The player assigned to the opponent client.
var opponent: Player:
	get:
		if Multiplayer.is_server:
			return player2
		
		return opponent

## The player whose turn it is.
var current_player: Player

## The opposing player to the player whose turn it is. Don't set this.
var opposing_player: Player:
	get:
		return current_player.opponent

## The player who starts first. ONLY ASSIGNED CLIENT SIDE.
var player1: Player:
	get:
		if Multiplayer.is_server:
			return _player1_server
		
		if not player:
			return null
		
		return player if player.id == 0 else opponent

## The player who starts with the coin. ONLY ASSIGNED CLIENT SIDE.
var player2: Player:
	get:
		if Multiplayer.is_server:
			return _player2_server
		
		if not player:
			return null
		
		return player if player.id == 1 else opponent

## If this client is [member player1].
var is_player_1: bool:
	get:
		if Multiplayer.is_server:
			return true
		
		return player.id == 0

## If this client is [member player2].
var is_player_2: bool:
	get:
		if Multiplayer.is_server:
			return false
		
		return player.id == 1

## Returns if it is currently the [member player]'s turn.
var is_players_turn: bool:
	get:
		return current_player == player

## The turn counter of the game.
var turn: int = 0

# Config
## The max amount of cards that can be on a player's board. Can be override by [code]Multiplayer.load_config()[/code].
var max_board_space: int = 7

## The max amount of cards that can be in a player's hand. Can be override by [code]Multiplayer.load_config()[/code].
var max_hand_size: int = 10

## The max amount of players that can be in a game at once. Any value other than 2 is not supported and will break.
var max_players: int = 2
# ------

## Returns the board node
var board_node: BoardNode:
	get:
		return get_node("/root/Main/Board") as BoardNode

## Returns an error label.
var error_text: String:
	set(new_error_text):
		error_text = new_error_text
		
		var error_label: RichTextLabel = get_node("/root/Main/ErrorLabel") as RichTextLabel
		error_label.modulate.a = 1
		error_label.text = "[center][color=red]" + error_text
		
		await get_tree().create_timer(1.0).timeout
		
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(error_label, "modulate:a", 0, 1)
#endregion


#region Private Variables
var _player1_server: Player
var _player2_server: Player
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
		
		send_packet(Enums.PACKET_TYPE.REVEAL, player.id, [card.location, card.index])
	
	# F3 reveals an enemy card. This should trigger the anticheat and drop the packet.
	elif key == "F3":
		var cards: Array[Card] = get_cards_for_player(opponent).filter(func(card: Card) -> bool: return card.is_hidden)
		if cards.size() <= 0:
			return
		
		var card: Card = cards.pick_random()
		
		send_packet(Enums.PACKET_TYPE.REVEAL, opponent.id, [card.location, card.index])
#endregion


#region Public Functions
## Gets the [Player] with the specified [param id].
func get_player_from_id(id: int) -> Player:
	if multiplayer.is_server():
		if id == 0:
			return _player1_server
		else:
			return _player2_server
	
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
			_player1_server = player
		else:
			_player2_server = player
		
		Multiplayer.assign_player.rpc_id(peer, player_id)
		
		print("Client %s assigned id: %s" % [peer, player_id])
		
		i += 1
	
	print("Sending config...")
	Multiplayer.send_config.rpc(
		Game.max_board_space,
		Game.max_hand_size,
	)
	
	print("Changing to game scene...")
	Multiplayer.change_scene_to_file.rpc("res://scenes/game/game.tscn")
	
	game_started.emit()
	
	# Give the player the debug deck.
	var deckcode: String = "1/1:30/1"
	
	Multiplayer.start_game.rpc(deckcode, deckcode)
	
	var coin: Card = get_card_from_blueprint(TheCoin, player2)
	player2.add_to_hand(coin, player2.hand.size())
	
	Game.layout_cards(player1)
	Game.layout_cards(player2)


## Sends a packet to end the [member current_player]'s turn. Returns if a packet was sent.
func end_turn() -> bool:
	if not is_players_turn:
		error_text = "It is not your turn."
		return false
	
	send_packet(Enums.PACKET_TYPE.END_TURN, current_player.id, [], true)
	return true


## Lays out all the cards for the specified player. Only works client side.
func layout_cards(player: Player) -> void:
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
	array.assign(get_tree().get_nodes_in_group("Cards").filter(func(card_node: CardNode) -> bool:
		return not card_node.is_queued_for_deletion()
	))
	return array


## Creates a [Blueprint] from the specified [param id]. Returns [code]null[/code] if no such blueprint exists.
func get_blueprint_from_id(id: int) -> Blueprint:
	var files: Array[String] = get_all_files_from_path("res://cards")
	
	for file_path: String in files:
		if not file_path.contains(".tres"):
			continue
		
		var blueprint: Blueprint = load(file_path)
		if blueprint.id == id:
			return blueprint
	
	return null


## Creates a card with the specified [param blueprint] with the specified [param player] as its owner.
func get_card_from_blueprint(blueprint: Blueprint, player: Player) -> Card:
	var card: Card = Card.new()
	card.blueprint = blueprint
	card.player = player
	return card


## Returns all filenames from the specified [param path].
func get_all_files_from_path(path: String) -> Array[String]:  
	var file_paths: Array[String] = []  
	var dir: DirAccess = DirAccess.open(path)  
	
	dir.list_dir_begin()  
	var file_name: String = dir.get_next()  

	while file_name != "":  
		var file_path: String = path + "/" + file_name  
		if dir.current_is_dir():  
			file_paths += get_all_files_from_path(file_path)  
		else:
			if file_path.ends_with(".tres.remap"):
				file_path = file_path.replace(".remap", "")
			file_paths.append(file_path)  
		
		file_name = dir.get_next()  
	
	return file_paths


## Waits for a node at the specified [param node_path] to exist before returning it.[br]
## Use [code]await[/code] on this.
func wait_for_node(node_path: NodePath) -> Node:
	while not get_node_or_null(node_path):
		await get_tree().create_timer(0.1).timeout
	
	return get_node(node_path)


## Exits to the main menu. You might want to use [code]Multiplayer.quit[/code] instead.
func exit_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")


## Sends a packet to the server that will be sent to all the clients.[br]
## This is used to sync every action.
func send_packet(packet_type: Enums.PACKET_TYPE, player_id: int, info: Array, suppress_warning: bool = false) -> void:
	Multiplayer.send_packet(packet_type, player_id, info, suppress_warning)


## Sends a packet if [param condition] is [code]true[/code]. If not, only apply the packet locally.
func send_packet_if(condition: bool, packet_type: Enums.PACKET_TYPE, player_id: int, info: Array, suppress_warning: bool = false) -> void:
	if condition:
		send_packet(packet_type, player_id, info, suppress_warning)
	else:
		Packet._accept_packet(packet_type, multiplayer.get_unique_id(), player_id, info)
#endregion
