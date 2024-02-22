extends Node
## Singleton for multiplayer stuff.
## @experimental


#region Constant Variables
const CardScene: PackedScene = preload("res://scenes/card.tscn")

## The port of the multiplayer server.
const PORT: int = 4545

## The max amount of clients. The game only supports 2.
const MAX_CLIENTS: int = 2
#endregion


#region Public Variables
## The players of the game. ONLY ASSIGNED SERVER-SIDE.[br][br]
## Looks like this:
## [code]{2732163217: Player, 432769823: Player}[/code]
var players: Dictionary = {}
#endregion


#region Internal Functions
func _ready() -> void:
	multiplayer.server_disconnected.connect(func() -> void:
		Game.exit_to_main_menu()
	)
	multiplayer.peer_disconnected.connect(func(_id: int) -> void:
		if multiplayer.is_server():
			Game.exit_to_main_menu()
			
			(await Game.wait_for_node("/root/Lobby")).host()
			return
		
		Game.exit_to_main_menu()
	)
	multiplayer.peer_connected.connect(func(_id: int) -> void:
		if not multiplayer.is_server():
			return
		
		var clients: int = multiplayer.get_peers().size()
		
		if clients < MAX_CLIENTS:
			print("Client connected, waiting for %d more..." % (Game.MAX_PLAYERS - clients))
			return
		
		print("Client connected, starting game...")
		Game.start_game()
	)
#endregion


#region Public Functions
## Sends a packet to the server that will be sent to all the clients.[br]
## This is used to sync every action.
func send_packet(message: Enums.PACKET_TYPE, player_id: int, info: Dictionary) -> void:
	_send_packet.rpc_id(1, message, player_id, info)
#endregion


#region RPC Functions
## Assigns [param id] to a client. CAN ONLY BE CALLED SERVER SIDE.
@rpc("authority", "call_remote", "reliable")
func assign_player(id: int) -> void:
	Game.player = Player.new()
	Game.player.id = id
	
	Game.opponent = Player.new()
	Game.opponent.id = 1 - id


## Makes the client switch to a scene. CAN ONLY BE CALLED SERVER SIDE.
@rpc("authority", "call_remote", "reliable")
func change_scene_to_file(file: StringName) -> void:
	get_tree().change_scene_to_file(file)


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
	
	(await Game.wait_for_node("/root/Main")).add_child(card_node)
	Game.layout_cards(card.player)


# Summons a card as requested by the server. THIS HAS TO BE CALLED SERVER SIDE. USE [method msg] FOR CLIENT SIDE.
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
	
	Game.layout_cards(player)


# Reveals a card for the player at the specified [param index] in the [param location]. THIS HAS TO BE CALLED SERVER SIDE. USE [method msg] FOR CLIENT SIDE.
@rpc("authority", "call_local", "reliable")
func _accept_reveal(player_id: int, location: Enums.LOCATION, index: int) -> void:
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, index)
	
	card.override_is_hidden = 0


@rpc("any_peer", "call_local", "reliable")
func _send_packet(message: Enums.PACKET_TYPE, player_id: int, info: Dictionary) -> void:
	var result: Enums.PACKET_FAILURE_TYPE = __send_packet(message, player_id, info)
	
	if result != Enums.PACKET_FAILURE_TYPE.NONE:
		push_warning("Packet dropped with code [%s] ^^^^" % Enums.PACKET_FAILURE_TYPE.keys()[result])

#endregion


#region Private Functions
func __send_packet(message: Enums.PACKET_TYPE, player_id: int, info: Dictionary) -> Enums.PACKET_FAILURE_TYPE:
	if not multiplayer.is_server():
		return Enums.PACKET_FAILURE_TYPE.IS_CLIENT
	
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	var sender_player: Player = players.get(sender_peer_id)
	
	# The 0th element is the sender_player, the 1th element is the other_player
	var sorted_player_keys: Array = players.keys()
	sorted_player_keys.sort_custom(func(a: int, _b: int) -> bool:
		return players[a].id == player_id
	)
	
	var actor_player: Player = players[sorted_player_keys[0]]
	var other_player: Player = players[sorted_player_keys[1]]
	
	print("[Packet]: %s (Player: %d): [%s] %s" % [
		"Server" if sender_peer_id == 1 else str(sender_peer_id),
		player_id,
		Enums.PACKET_TYPE.keys()[message],
		info
	])
	
	# Anticheat
	var anticheat_message: Enums.ANTICHEAT_MESSAGE = _anticheat(message, actor_player, other_player, info)
	
	if anticheat_message != Enums.ANTICHEAT_MESSAGE.NONE:
		match anticheat_message:
			Enums.ANTICHEAT_MESSAGE.INVALID:
				push_error("Previous packet was invalid. This was not determined to be cheating. Packet dropped.")
			
			Enums.ANTICHEAT_MESSAGE.CHEATING:
				push_error("!!! ANTICHEAT TRIGGERED IN PREVIOUS PACKET DUE TO CHEATING. PACKET DROPPED. !!!")
			
		return Enums.PACKET_FAILURE_TYPE.ANTICHEAT
	
	
	# Actually handle the packet
	match message:
		# Summon
		Enums.PACKET_TYPE.SUMMON:
			var hand_index: int = info.hand_index
			var board_index: int = info.board_index
			
			_accept_summon_card.rpc(player_id, Enums.LOCATION.HAND, hand_index, board_index)
		
		# Add to hand
		Enums.PACKET_TYPE.ADD_TO_HAND:
			var blueprint_path: NodePath = info.blueprint_path
			var index: int = info.index
			
			spawn_card.rpc(blueprint_path, player_id, Enums.LOCATION.HAND, index)
		
		# Reveal
		Enums.PACKET_TYPE.REVEAL:
			var location: Enums.LOCATION = info.location
			var index: int = info.index
			
			_accept_reveal.rpc(player_id, location, index)
	
	return Enums.PACKET_FAILURE_TYPE.NONE


func _anticheat(message: Enums.PACKET_TYPE, actor_player: Player, other_player: Player, info: Dictionary) -> Enums.ANTICHEAT_MESSAGE:
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	var sender_player: Player = players.get(sender_peer_id)
	
	# TODO: Figure out if this is a good idea
	# Trust the server packets
	#if sender_peer_id == 1:
		#return Enums.ANTICHEAT_MESSAGE.NONE
	
	# TODO: More Anticheat
	match message:
		# Add to hand
		Enums.PACKET_TYPE.ADD_TO_HAND:
			pass
		
		# Summon
		Enums.PACKET_TYPE.SUMMON:
			# The player who summons the card should be the same player as the one who sent the packet
			if sender_player != actor_player:
				return Enums.ANTICHEAT_MESSAGE.CHEATING
			
			var hand_index: int = info.hand_index
			var board_index: int = info.board_index
			
			var card: Card = Game.get_card_from_index(sender_player, Enums.LOCATION.HAND, hand_index)
			# Card doesn't exist
			if not card:
				return Enums.ANTICHEAT_MESSAGE.INVALID
			
			# Card not in the player's hand
			if card.location != Enums.LOCATION.HAND:
				return Enums.ANTICHEAT_MESSAGE.CHEATING
			
			# Not enough space
			if actor_player.board.size() >= Game.MAX_BOARD_SPACE:
				return Enums.ANTICHEAT_MESSAGE.INVALID
		
		# Reveal
		Enums.PACKET_TYPE.REVEAL:
			# The player whose card gets revealed should be the same player as the one who sent the packet
			if sender_player != actor_player:
				return Enums.ANTICHEAT_MESSAGE.CHEATING
	
	return Enums.ANTICHEAT_MESSAGE.NONE
#endregion
