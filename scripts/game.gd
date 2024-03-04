extends Node
## The main singleton with a lot of helper functions.
## @experimental


#region Signals
## Emits when the game starts.
signal game_started

## Emits whenever a card gets created for any player.
signal card_created(card: Card, player: Player, sender_peer_id: int)

## Emits whenever a card gets summoned for any player.
signal card_summoned(card: Card, board_index: int, player: Player, sender_peer_id: int)

## Emits whenever a card gets played for any player.
signal card_played(card: Card, board_index: int, player: Player, sender_peer_id: int)

## Emits whenever a card gets revealed for any player.
signal card_revealed(card: Card, player: Player, sender_peer_id: int)

## Emits whenever one of a card's abilities gets triggered for any player.
signal card_ability_triggered(card: Card, ability: Card.Ability, player: Player, sender_peer_id: int)

## Emits whenever some amount of gets gets drawn by any player.
signal cards_drawn(amount: int, player: Player, sender_peer_id: int)

## Emits when the any player's turn ends.
signal turn_ended(player: Player, sender_peer_id: int)
#endregion


#region Enums
enum FeedbackType {
	INFO,
	WARNING,
	ERROR,
}

enum NullableBool {
	FALSE,
	TRUE,
	NULL,
}
#endregion


#region Constant Variables
const THE_COIN: Blueprint = preload("res://cards/the_coin/the_coin.tres")
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

## The max amount of cards that can be in a player's deck. Can be override by [code]Multiplayer.load_config()[/code].
var max_deck_size: int = 30

## The min amount of cards that can be in a player's deck. Can be override by [code]Multiplayer.load_config()[/code].
var min_deck_size: int = 30

## The max amount of players that can be in a game at once. Any value other than 2 is not supported and will break.
var max_players: int = 2
# ------


# There should be a better way of doing this.
var card_bounds_x: float = -3.05
var card_bounds_y: float = -0.5
var card_bounds_z: float = 13
var card_rotation_y_multiplier: float = 10.0
var card_distance_x: float = 1.81


## Returns the board node
var board_node: BoardNode:
	get:
		return get_tree().root.get_node("Main/Board") as BoardNode
#endregion


#region Private Variables
var _player1_server: Player
var _player2_server: Player
#endregion


#region Internal Functions
func _ready() -> void:
	# Add error label
	var error_label: RichTextLabel = RichTextLabel.new()
	error_label.bbcode_enabled = true
	error_label.fit_content = true
	error_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	error_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	error_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	error_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	error_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	error_label.anchors_preset = 14
	error_label.anchor_top = 0.5
	error_label.anchor_right = 1.0
	error_label.anchor_bottom = 0.5
	
	error_label.offset_top = -11.5
	error_label.offset_bottom = 11.5
	
	error_label.name = "ErrorLabel"
	get_tree().root.add_child.call_deferred(error_label, true)


func _notification(what: int) -> void:
	# Save on quit.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		OS.set_restart_on_exit(false)
		Multiplayer.quit()
#endregion


#region Public Functions
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
		player.peer_id = peer
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
		max_board_space,
		max_hand_size,
		max_deck_size,
		min_deck_size,
	)
	
	print("Changing to game scene...")
	Multiplayer.change_scene_to_file.rpc("res://scenes/game/game.tscn")
	
	current_player = player1
	player1.empty_mana = 1
	player1.mana = 1
	
	var deckcodes: Dictionary = Multiplayer._deckcodes
	Multiplayer.start_game.rpc(deckcodes[player1.peer_id], deckcodes[player2.peer_id])
	
	var coin: Card = Card.get_from_blueprint(THE_COIN, player2)
	player2.add_to_hand(coin, player2.hand.size())


## Sends a packet to end the [member current_player]'s turn. Returns if a packet was sent.
func end_turn() -> bool:
	if not is_players_turn:
		feedback("It is not your turn.", FeedbackType.ERROR)
		return false
	
	Packet.send(Packet.PacketType.END_TURN, current_player.id, [], true)
	return true


## Makes [param text] pop up in the middle of the player's screen. Its color will be derived from [param type].
func feedback(text: String, type: FeedbackType) -> void:
	var error_label: RichTextLabel = get_tree().root.get_node("ErrorLabel") as RichTextLabel
	error_label.modulate.a = 1
	
	# Get color from `type`.
	var color: String = ""
	
	match type:
		FeedbackType.INFO:
			pass
		
		FeedbackType.WARNING:
			color = "yellow"
		
		FeedbackType.ERROR:
			color = "red"
		
		_:
			assert(false, "Invalid feedback type: %s" % type)
	
	error_label.text = "[center]%s%s" % [
		("[color=%s]" % color) if color else "",
		text,
	]
	
	# Wait 1 second
	await get_tree().create_timer(1.0).timeout
	
	# Fade out
	var tween: Tween = create_tween()
	tween.tween_property(error_label, "modulate:a", 0, 1)


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
func exit_to_lobby() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/lobby.tscn")


## Returns [code]array[index][/code] if it exists, otherwise it returns [code]null[/code].
func get_or_null(array: Array, index: int) -> Variant:
	return array[index] if array.size() > index else null
#endregion
