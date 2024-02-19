extends Node
## The main singleton with a lot of helper functions.
## @experimental


#region Signals
## Emits when the game starts
signal game_started
#endregion


#region Constant Variables
const CardScene: PackedScene = preload("res://scenes/card.tscn")

## The port of the multiplayer server.
const PORT: int = 4545

## The max amount of clients. The game only supports 2.
const MAX_CLIENTS: int = 2

const CARD_BOUNDS_X: float = 9.05
const CARD_BOUNDS_Y: float = -0.5
const CARD_BOUNDS_Z: float = 7
const CARD_BOUNDS_ROTATION_Y: float = 21.2
const CARD_DISTANCE_X: float = 1.81

const MAX_PLAYERS: int = 2
#endregion


#region Public Variables
## The player assigned to this client.
var player: Player

## The player assigned to the opponent client.
var opponent: Player

## The player whose turn it is.
var current_player: Player = Player.new()

## The opposing player to the player whose turn it is.
var opposing_player: Player = Player.new()
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
#endregion


#region Public Functions
## Starts the game. Assigns an id to each player and changes scene to the game scene.
## Only the host can do this.
func start_game() -> void:
	if not multiplayer.is_server():
		return
	
	var id: int = randi_range(0, MAX_PLAYERS - 1)
	
	var i: int = 0
	for peer: int in multiplayer.get_peers():
		var player_id: int
		
		if i == 0:
			player_id = id
		else:
			player_id = 1 - id
		
		assign_player.rpc_id(peer, player_id)
		
		print("Client %s assigned id: %s" % [peer, player_id])
		
		i += 1
	
	print("Changing to game scene...")
	change_scene_to_file.rpc("res://scenes/game.tscn")
	
	game_started.emit()


## Places a [Card] in its player's hand at some index. You probably shouldn't touch this.
func place_card_in_hand(card: Card, index: int) -> CardNode:
	card.index = index
	card.location = Enums.LOCATION.HAND
	
	var card_node: CardNode = CardScene.instantiate()
	card_node.card = card
	card_node.layout()
	
	return card_node


## Lays out all the cards for the specified player.
func layout_cards(player: Player) -> void:
	for card: CardNode in get_card_nodes_for_player(player):
		card.layout()


## Gets all cards for the specified player.
func get_cards_for_player(player: Player) -> Array[Card]:
	return get_card_nodes_for_player(player).map(func(card_node: CardNode) -> Card: return card_node.card)


## Gets all card nodes for the specified player.
func get_card_nodes_for_player(player: Player) -> Array[CardNode]:
	return get_tree().get_nodes_in_group("Cards").filter(func(card_node: CardNode) -> bool:
		return card_node.card.player == player
	)

## Exits to the main menu. This disconnects from the server.
func exit_to_main_menu() -> void:
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
#endregion


#region RPC Functions
## Assigns [param id] to a client.
@rpc("authority", "call_remote", "reliable")
func assign_player(id: int) -> void:
	player = Player.new()
	player.id = id
	
	opponent = Player.new()
	opponent.id = 1 - id


## Makes the client switch to a scene.
@rpc("authority", "call_remote", "reliable")
func change_scene_to_file(file: StringName) -> void:
	get_tree().change_scene_to_file(file)
#endregion
