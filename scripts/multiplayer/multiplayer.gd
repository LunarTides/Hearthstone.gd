extends Node
## Singleton for multiplayer stuff.
## @experimental


#region Constant Variables
const CardScene: PackedScene = preload("res://scenes/card.tscn")

const CONFIG_FILE_PATH: String = "./server.conf"
#endregion


#region Public Variables
## Packet related functions.
var packet: Packet = Packet.new()

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

## The action that should bw taken if the anticheat gets triggered.
var anticheat_conseqence: Enums.ANTICHEAT_CONSEQUENCE = Enums.ANTICHEAT_CONSEQUENCE.DROP_PACKET

## The players of the game. ONLY ASSIGNED SERVER-SIDE.[br][br]
## Looks like this:
## [code]{2732163217: Player, 432769823: Player}[/code]
var players: Dictionary = {}

## An [ENetMultiplayerPeer]. Gets used to get ips from peer ids.
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

## A list of banned ips. Gets populated by [method load_config]
var ban_list: Array[String] = []

## Whether or not this is a server.
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
	# Save on quit.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_config()
#endregion


#region Public Functions
## Sends a packet to the server that will be sent to all the clients.[br]
## This is used to sync every action.
func send_packet(packet_type: Enums.PACKET_TYPE, player_id: int, info: Array, suppress_warning: bool = false) -> void:
	packet.send_packet(packet_type, player_id, info, suppress_warning)


## Loads the config file specified at [constant CONFIG_FILE_PATH]. Only used by the server.
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


## Creates a config file at [constant CONFIG_FILE_PATH]. Only used by the server.
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


## Returns an ip address from [param peer_id].
func get_ip_address(peer_id: int) -> String:
	return peer.get_peer(peer_id).get_remote_address()


## Kicks the player with the specified [param peer_id]. If [param force] is [code]true[/code] the [signal MultiplayerPeer.peer_disconnected] signal will not be emitted.
func kick(peer_id: int, force: bool = false) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(peer_id, force)


## Quits to main menu. Use this instead of [code]Game.exit_to_main_menu[/code].
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
## Assigns [param id] to a client. CAN ONLY BE RPC CALLED SERVER SIDE.
@rpc("authority", "call_remote", "reliable")
func assign_player(id: int) -> void:
	if is_server:
		push_error("Trying to do `assign_player` on server.")
		return
	
	Game.player = Player.new()
	Game.player.id = id
	
	Game.opponent = Player.new()
	Game.opponent.id = 1 - id


## Makes the client switch to a scene. CAN ONLY BE RPC CALLED SERVER SIDE.
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
#endregion
