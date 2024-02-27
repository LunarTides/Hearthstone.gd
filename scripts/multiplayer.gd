extends Node
## Singleton for multiplayer stuff.
## @experimental


#region Constant Variables
const CardScene: PackedScene = preload("res://scenes/card.tscn")

const CONFIG_FILE_PATH: String = "./server.conf"
#endregion


#region Public Variables
## The port of the multiplayer server.
var port: int = 4545

## The max amount of clients. The game only supports 2.
var max_clients: int = 2

## How aggressive the anticheat should be. Only affects the server.[br]
## [code]0: Disabled.
## 1: Only validation.
## 2: Basic cheat detection.
## 3-inf: More-and-more aggressive anticheat.
## -1: Max anticheat.[/code]
var anticheat_level: int = -1

var anticheat_conseqence: Enums.ANTICHEAT_CONSEQUENCE = Enums.ANTICHEAT_CONSEQUENCE.DROP_PACKET

## The players of the game. ONLY ASSIGNED SERVER-SIDE.[br][br]
## Looks like this:
## [code]{2732163217: Player, 432769823: Player}[/code]
var players: Dictionary = {}

var packet_history: Array[Array] = []

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var ban_list: Array[String] = []

var is_server: bool:
	get:
		if not multiplayer.multiplayer_peer:
			return false
		
		return multiplayer.is_server()
#endregion


#region Internal Functions
func _ready() -> void:
	multiplayer.server_disconnected.connect(func() -> void:
		quit()
	)
	multiplayer.peer_disconnected.connect(func(_id: int) -> void:
		quit()
	)
	multiplayer.peer_connected.connect(func(id: int) -> void:
		if not is_server:
			return
		
		var ip_address: String = get_ip_address(id)
		
		if ip_address in ban_list:
			# Kick
			print("Banned player (%s) is trying to join. Kicking..." % ip_address)
			kick(id, true)
			return
		
		var clients: int = multiplayer.get_peers().size()
		
		if clients < max_clients:
			print("Client connected, waiting for %d more..." % (Game.max_players - clients))
			return
		
		print("Client connected, starting game...")
		Game.start_game()
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_config()
#endregion


#region Public Functions
func get_readable_packet(sender_peer_id: int, packet_type: Enums.PACKET_TYPE, player_id: int, info: Array) -> String:
	var packet_name: String = Enums.PACKET_TYPE.keys()[packet_type]
	
	return "[Packet]: %s (Player: %d): [%s] %s" % [
		"Server" if sender_peer_id == 1 else str(sender_peer_id),
		player_id,
		packet_name,
		info
	]


## Sends a packet to the server that will be sent to all the clients.[br]
## This is used to sync every action.
func send_packet(packet_type: Enums.PACKET_TYPE, player_id: int, info: Array, suppress_warning: bool = false) -> void:
	# Only send the "Sending packet" message on non-debug builds since it spams the console with garbage.
	if not OS.is_debug_build() and not is_server:
		print("Sending packet: " + get_readable_packet(multiplayer.get_unique_id(), packet_type, player_id, info))
	
	if is_server and not suppress_warning:
		push_warning("A packet is being sent from the server. These packets bypass the anticheat. Be careful.")
	
	_send_packet.rpc_id(1, packet_type, player_id, info)


func load_config() -> void:
	if not is_server:
		return
	
	print("Loading config at '%s'..." % CONFIG_FILE_PATH)
	
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_FILE_PATH) == ERR_FILE_CANT_OPEN or not config.get_value("Server", "port", false):
		push_warning("No config found. Creating one...")
		
		save_config()
	
	config.load(CONFIG_FILE_PATH)
	
	port = config.get_value("Server", "port", port)
	anticheat_level = config.get_value("Server", "anticheat_level", anticheat_level)
	anticheat_conseqence = config.get_value("Server", "anticheat_consequence", anticheat_conseqence)
	ban_list = config.get_value("Server", "ban_list", ban_list)
	
	Game.max_board_space = config.get_value("Game", "max_board_space", Game.max_board_space)
	Game.max_hand_size = config.get_value("Game", "max_hand_size", Game.max_hand_size)
	
	print("Config loaded:\n'''\n%s'''\n" % config.encode_to_text())


func save_config() -> void:
	if not is_server:
		return
	
	var config: ConfigFile = ConfigFile.new()
	config.set_value("Server", "port", port)
	config.set_value("Server", "anticheat_level", anticheat_level)
	config.set_value("Server", "anticheat_consequence", anticheat_conseqence)
	config.set_value("Server", "ban_list", ban_list)
	
	config.set_value("Game", "max_board_space", Game.max_board_space)
	config.set_value("Game", "max_hand_size", Game.max_hand_size)
	
	config.save(CONFIG_FILE_PATH)


func get_ip_address(peer_id: int) -> String:
	return peer.get_peer(peer_id).get_remote_address()


func kick(peer_id: int, force: bool = false) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(peer_id, force)


func quit() -> void:
	# CRITICAL: This function crashes clients somehow?
	save_config()
	
	# Do this since after the multiplayer is closed, is_server will always return false
	var _is_server: bool = is_server
	
	peer.close()
	multiplayer.multiplayer_peer.close()
	
	peer = ENetMultiplayerPeer.new()
	multiplayer.multiplayer_peer = null
	
	Game.exit_to_main_menu()
	
	if _is_server:
		(await Game.wait_for_node("/root/Lobby")).host()
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
@rpc("authority", "call_local", "reliable")
func change_scene_to_file(file: StringName) -> void:
	get_tree().change_scene_to_file(file)


## Sends the server config options to the client.
@rpc("authority", "call_remote", "reliable")
func send_config(new_max_board_space: int, new_max_hand_size: int) -> void:
	if is_server:
		return
	
	Game.max_board_space = new_max_board_space
	Game.max_hand_size = new_max_hand_size
	
	print("Config loaded:\n'''\nmax_board_space=%d\nmax_hand_size=%d\n'''\n" % [
		Game.max_board_space,
		Game.max_hand_size,
	])


## Spawns in a card. THIS HAS TO BE CALLED SERVER SIDE. USE [method send_packet] FOR CLIENT SIDE.
@rpc("authority", "call_local", "reliable")
func spawn_card(blueprint_path: String, player_id: int, location: Enums.LOCATION, index: int) -> void:
	var card: Card = Card.new()
	card.blueprint = load(blueprint_path)
	card.player = Game.get_player_from_id(player_id)
	card.location = location
	card.add_to_location(index)
	
	var card_node: CardNode = CardScene.instantiate()
	card_node.card = card
	
	if is_server:
		add_child(card_node)
		return
	
	(await Game.wait_for_node("/root/Main")).add_child(card_node)
	Game.layout_cards(card.player)


@rpc("authority", "call_local", "reliable")
func _accept_start_game_packet(player_id: int, info: Array) -> void:
	var deckcodes: Array = info.slice(0, 2)
	
	for i: int in 2:
		var player: Player = Game.get_player_from_id(i)
		var deck: Dictionary = Deckcode.import(deckcodes[i], player)
		
		player.hero_class = deck.class
		player.deck = deck.cards
		
		# Do this to not send a packet.
		_accept_draw_cards_packet(i, [3 if player.id == 0 else 4], false)


# Summons a card as requested by the server. THIS HAS TO BE CALLED SERVER SIDE. USE [method send_packet] FOR CLIENT SIDE.
@rpc("authority", "call_local", "reliable")
func _accept_summon_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	card.location = Enums.LOCATION.BOARD
	card.add_to_location(board_index)
	
	Game.layout_cards(player)


# Summons a card as requested by the server. THIS HAS TO BE CALLED SERVER SIDE. USE [method send_packet] FOR CLIENT SIDE.
@rpc("authority", "call_local", "reliable")
func _accept_play_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	if not is_server:
		if card.types.has(Enums.TYPE.SPELL):
			card.location = Enums.LOCATION.NONE
		return
	
	if card.types.has(Enums.TYPE.MINION):
		player.summon_card(card, board_index)
		
		card.trigger_ability(Enums.ABILITY.BATTLECRY)
	
	if card.types.has(Enums.TYPE.SPELL):
		card.trigger_ability(Enums.ABILITY.CAST)
		
		card.location = Enums.LOCATION.NONE


@rpc("authority", "call_local", "reliable")
func _accept_create_card_packet(player_id: int, info: Array) -> void:
	var blueprint_path: String = info[0]
	var location: Enums.LOCATION = info[1]
	var location_index: int = info[2]
	
	spawn_card(blueprint_path, player_id, location, location_index)


@rpc("authority", "call_local", "reliable")
func _accept_draw_cards_packet(player_id: int, info: Array, send_packet: bool = true) -> void:
	var amount: int = info[0]
	
	var player: Player = Game.get_player_from_id(player_id)
	
	for _i: int in amount:
		var card: Card = player.deck.pop_back()
		
		if player.hand.size() >= Game.max_hand_size:
			# Burn the card.
			return
		
		if send_packet:
			player.add_to_hand(card, player.hand.size())
		else:
			_accept_create_card_packet(player.id, [
				card.blueprint.resource_path,
				Enums.LOCATION.HAND,
				player.hand.size(),
			])
		
		card.location = Enums.LOCATION.HAND
		
		# Create card node.
		var card_node: CardNode = CardScene.instantiate()
		card_node.card = card
		card_node.layout()
		
		Game.layout_cards(card.player)


# Reveals a card for the player at the specified [param index] in the [param location]. THIS HAS TO BE CALLED SERVER SIDE. USE [method send_packet] FOR CLIENT SIDE.
@rpc("authority", "call_local", "reliable")
func _accept_reveal_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	card.override_is_hidden = Enums.NULLABLE_BOOL.FALSE


@rpc("authority", "call_local", "reliable")
func _accept_trigger_ability_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	var ability: Enums.ABILITY = info[2]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	for ability_callback: Callable in card.abilities[ability]:
		ability_callback.call(player, card)


@rpc("any_peer", "call_local", "reliable")
func _send_packet(packet_type: Enums.PACKET_TYPE, player_id: int, info: Array) -> void:
	var result: Enums.PACKET_FAILURE_TYPE = __send_packet(packet_type, player_id, info)
	
	if result != Enums.PACKET_FAILURE_TYPE.NONE:
		push_warning("Packet dropped with code [%s] ^^^^" % Enums.PACKET_FAILURE_TYPE.keys()[result])
#endregion


#region Private Functions
func __send_packet(packet_type: Enums.PACKET_TYPE, player_id: int, info: Array) -> Enums.PACKET_FAILURE_TYPE:
	if not is_server:
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
	
	var packet_name: String = Enums.PACKET_TYPE.keys()[packet_type]
	print(get_readable_packet(sender_peer_id, packet_type, player_id, info))
	
	# Anticheat
	if not _anticheat(packet_type, actor_player, other_player, info):
		var consequence_text: String
		
		match anticheat_conseqence:
			Enums.ANTICHEAT_CONSEQUENCE.DROP_PACKET:
				consequence_text = "PACKET DROPPED"
			
			Enums.ANTICHEAT_CONSEQUENCE.KICK:
				consequence_text = "PLAYER KICKED"
				kick(sender_peer_id)
			
			Enums.ANTICHEAT_CONSEQUENCE.BAN:
				consequence_text = "PLAYER BANNED"
				ban_list.append(get_ip_address(sender_peer_id))
				kick(sender_peer_id)
		
		push_error("!!! ANTICHEAT TRIGGERED IN PREVIOUS PACKET. %s. !!!" % consequence_text)
		return Enums.PACKET_FAILURE_TYPE.ANTICHEAT
	
	
	# Actually handle the packet
	
	# Invalid packet type
	if not Enums.PACKET_TYPE.values().has(packet_type):
		var message: String = "Invalid packet '%s'." % packet_type
		assert(false, message)
		
		push_error(message + " The client who sent this packet might be modded. If you think this is a bug, open an issue here: https://github.com/LunarTides/Hearthstone.gd")
		return Enums.PACKET_FAILURE_TYPE.UNKNOWN
	
	# Broadcast the packet to all clients & server
	var method_name: String = "_accept_" + packet_name.to_lower() + "_packet"
	assert(self[method_name], method_name + " doesn't exist.")
	self[method_name].rpc(player_id, info)
	
	packet_history.append([sender_peer_id, player_id, info])
	
	return Enums.PACKET_FAILURE_TYPE.NONE


func _anticheat(packet_type: Enums.PACKET_TYPE, actor_player: Player, other_player: Player, info: Array) -> bool:
	if anticheat_level < 0:
		anticheat_level = 10000
	elif anticheat_level == 0:
		return true
	
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	var sender_player: Player = players.get(sender_peer_id)
	
	# Packets sent from the server should bypass the anitcheat.
	if sender_peer_id == 1:
		return true
	
	
	# TODO: More Anticheat
	match packet_type:
		Enums.PACKET_TYPE.START_GAME:
			# Only the server can do this.
			if _anticheat_check(true, 2):
				return false
		
		# Create card
		Enums.PACKET_TYPE.CREATE_CARD:
			var blueprint_path: String = info[0]
			var location: Enums.LOCATION = info[1]
			var location_index: int = info[2]
			
			# Blueprint path needs to be valid.
			if _anticheat_check(load(blueprint_path) == null, 1):
				return false
			
			# Only the server can do this.
			if _anticheat_check(true, 2):
				return false
			
			if location == Enums.LOCATION.HAND:
				# The player needs to have enough space in their hand.
				if _anticheat_check(actor_player.hand.size() >= Game.max_hand_size, 1):
					return false
			elif location == Enums.LOCATION.BOARD:
				# The player needs to have enough space on their board.
				if _anticheat_check(actor_player.board.size() >= Game.max_board_space, 1):
					return false
		
		# Draw cards
		Enums.PACKET_TYPE.DRAW_CARDS:
			var amount: int = info[0]
			
			# Only the server can do this.
			if _anticheat_check(true, 2):
				return false
		
		# Summon
		Enums.PACKET_TYPE.SUMMON:
			var location: Enums.LOCATION = info[0]
			var location_index: int = info[1]
			var board_index: int = info[2]
			
			var card: Card = Game.get_card_from_index(sender_player, location, location_index)
			
			# The card should exist.
			if _anticheat_check(not card, 1):
				return false
				
			# The player should have enough space on their board.
			if _anticheat_check(actor_player.board.size() >= Game.max_board_space, 1):
				return false
				
			# The player who summons the card should be the same player as the one who sent the packet.
			if _anticheat_check(sender_player != actor_player, 2):
				return false
			
			# The card should be in the player's hand.
			if _anticheat_check(card.location != Enums.LOCATION.HAND, 3):
				return false
			
			# Check if the card is queued to be summoned.
			if _anticheat_check(_in_packet_history([location, location_index, board_index], 2, true), 3):
				return false
		
		# Play
		Enums.PACKET_TYPE.PLAY:
			var location: Enums.LOCATION = info[0]
			var location_index: int = info[1]
			var board_index: int = info[2]
			
			var card: Card = Game.get_card_from_index(sender_player, location, location_index)
			
			# The card should exist.
			if _anticheat_check(not card, 1):
				return false
			
			# The player who summons the card should be the same player as the one who sent the packet.
			if _anticheat_check(sender_player != actor_player, 2):
				return false
			
			# The card should be in the player's hand.
			if _anticheat_check(card.location != Enums.LOCATION.HAND, 3):
				return false
			
			# Minion
			if card.types.has(Enums.TYPE.MINION):
				# The player should have enough space on their board.
				if _anticheat_check(actor_player.board.size() >= Game.max_board_space, 1):
					return false
		
		# Reveal
		Enums.PACKET_TYPE.REVEAL:
			var location: Enums.LOCATION = info[0]
			var index: int = info[1]
			
			# The player whose card gets revealed should be the same player as the one who sent the packet
			if _anticheat_check(sender_player != actor_player, 2):
				return false
		
		# Trigger ability
		Enums.PACKET_TYPE.TRIGGER_ABILITY:
			var location: Enums.LOCATION = info[0]
			var location_index: int = info[1]
			var ability: Enums.ABILITY = info[2]
			
			var card: Card = Game.get_card_from_index(actor_player, location, location_index)
			
			# The card should exist.
			if _anticheat_check(card == null, 1):
				return false
			
			# The player who sent the packet should own the card.
			if _anticheat_check(sender_player != actor_player, 2):
				return false
			
			# Check if the card has already been triggered.
			if _anticheat_check(_in_packet_history([location, location_index, ability], 3, true), 3):
				return false
		
		_:
			assert(false, "No anticheat logic for '%s'" % Enums.PACKET_TYPE.keys()[packet_type])
	
	return true


## Returns if [param condition] is true and [member anticheat_level] is more or equal to [param min_anticheat_level].
func _anticheat_check(condition: bool, min_anticheat_level: int) -> bool:
	return condition and anticheat_level >= min_anticheat_level


func _in_packet_history(info: Array, range: int, only_use_server_packets: bool = false) -> bool:
	for i: int in range:
		var history: Array = packet_history[-(i + 1)]
		if history[2] == info and (not only_use_server_packets || history[1] == 1):
			return true
	
	return false
#endregion
