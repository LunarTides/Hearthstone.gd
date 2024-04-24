extends Node
## Singleton for multiplayer stuff.
## @experimental


#region Signals
## Emits when the server responds to a client's packet. Only responds to [method send_deckcode] for now.
signal server_responded(success: bool)
#endregion


#region Constants
const CONFIG_FILE_PATH: String = "./server.cfg"
#endregion


#region Public Variables
## The players of the game.[br][br]
## Looks like this:
## [code]{2732163217: Player, 432769823: Player}[/code]
var players: Dictionary = {}

## An [ENetMultiplayerPeer]. Gets used to get ips from peer ids.
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

## Whether or not this is a server.
var is_server: bool:
	get:
		if not multiplayer.multiplayer_peer:
			return true
		
		return multiplayer.is_server()
#endregion


#region Private Variables
# Only assigned server-side.
var _deckcodes: Dictionary
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
		
		if ip_address in Settings.server.ban_list:
			# Kick
			print("Banned player (%s) is trying to join. Kicking..." % ip_address)
			server_response.rpc_id(id, false, "You are banned.")
			kick(id, true)
			return
		
		var clients: int = multiplayer.get_peers().size()
		
		if clients < Settings.server.max_players:
			print("Client connected, waiting for %d more..." % (Settings.server.max_players - clients))
			return
		
		# Wait until the player sends their deckcode.
		while _deckcodes.size() < clients:
			await get_tree().create_timer(0.1).timeout
		
		print("Client connected, starting game...")
		Game.start_game()
	)
#endregion


#region Public Functions
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
	
	Settings.server.port = config.get_value("Server", "port", Settings.server.port)
	Settings.server.anticheat_level = config.get_value("Server", "anticheat_level", Settings.server.anticheat_level)
	Settings.server.anticheat_consequence = config.get_value("Server", "anticheat_consequence", Settings.server.anticheat_consequence)
	Settings.server.ban_list = config.get_value("Server", "ban_list", Settings.server.ban_list)
	
	Settings.server.max_board_space = config.get_value("Game", "max_board_space", Settings.server.max_board_space)
	Settings.server.max_hand_size = config.get_value("Game", "max_hand_size", Settings.server.max_hand_size)
	Settings.server.max_deck_size = config.get_value("Game", "max_deck_size", Settings.server.max_deck_size)
	Settings.server.min_deck_size = config.get_value("Game", "min_deck_size", Settings.server.min_deck_size)
	
	print("Config loaded:\n'''\n%s'''\n" % config.encode_to_text())


## Creates a config file at [constant CONFIG_FILE_PATH]. Only used by the server.
func save_config() -> void:
	if not is_server:
		return
	
	if FileAccess.file_exists(CONFIG_FILE_PATH):
		return
	
	var config: ConfigFile = ConfigFile.new()
	config.set_value("Server", "port", Settings.server.port)
	config.set_value("Server", "anticheat_level", Settings.server.anticheat_level)
	config.set_value("Server", "anticheat_consequence", Settings.server.anticheat_consequence)
	config.set_value("Server", "ban_list", Settings.server.ban_list)
	
	config.set_value("Game", "max_board_space", Settings.server.max_board_space)
	config.set_value("Game", "max_hand_size", Settings.server.max_hand_size)
	config.set_value("Game", "max_deck_size", Settings.server.max_deck_size)
	config.set_value("Game", "min_deck_size", Settings.server.min_deck_size)
	
	config.save(CONFIG_FILE_PATH)


## Returns an ip address from [param peer_id].
func get_ip_address(peer_id: int) -> String:
	return peer.get_peer(peer_id).get_remote_address()


## Kicks the player with the specified [param peer_id]. If [param force] is [code]true[/code] the [signal MultiplayerPeer.peer_disconnected] signal will not be emitted.
func kick(peer_id: int, force: bool = false) -> void:
	multiplayer.multiplayer_peer.disconnect_peer(peer_id, force)


## Joins a server at the specified [param ip_address] and [param port].
func join(ip_address: String, port: int, deckcode: String) -> void:
	Modules.load_config()
	
	await get_tree().create_timer(0.5).timeout
	Modules.load_all()
	
	Modules.save_config()
	
	peer.create_client(ip_address if ip_address else "localhost", port)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(func() -> void:
		# For some reason, we need to specify `Multiplayer` here.
		Multiplayer.send_deckcode.rpc_id(1, deckcode)
	)


## Hosts a server at [member port].
func host() -> void:
	if not OS.is_debug_build():
		# Will not really work with a dedicated server but there it nothing i can do.
		OS.set_restart_on_exit(true, ["--server"])
	
	peer.create_server(Settings.server.port, Settings.server.max_players)
	multiplayer.multiplayer_peer = peer
	
	load_config()
	
	Modules.load_config()
	
	await get_tree().create_timer(0.5).timeout
	
	Modules.load_all()
	Modules.save_config()
	
	# UPnP
	if not UPnP.has_tried_upnp:
		print("Attempting to use UPnP. Please wait...")
		UPnP.setup(Settings.server.port)
		
		UPnP.upnp_completed.connect(func(err: int) -> void:
			if err == OK:
				print("UPnP setup completed successfully. You do not need to port forward.")
			else:
				print("UPnP setup failed, you will need to port-forward port %s (TCP/UDP) manually." % Settings.server.port)
		)
	
	print("Waiting for a client to connect...")


## Quits to main menu. Use this instead of [code]Game.exit_to_lobby[/code].
func quit() -> void:
	# CRITICAL: This function crashes clients somehow?
	if not is_server:
		push_warning("Quitting. This will crash the game for some reason.")
	
	save_config()
	Modules.save_config()
	
	# Do this since after the multiplayer is closed, is_server will always return false
	var _is_server: bool = is_server
	
	peer.close()
	multiplayer.multiplayer_peer.close()
	
	peer = ENetMultiplayerPeer.new()
	multiplayer.multiplayer_peer = null
	
	if _is_server:
		get_tree().quit()
	else:
		Game.exit_to_lobby()
#endregion


#region RPC Functions
## Assigns [param id] to a client. CAN ONLY BE RPC CALLED SERVER SIDE.
@rpc("authority", "call_remote", "reliable")
func assign_player(id: int) -> void:
	Game.player = Player.new()
	Game.player.id = id
	
	Game.opponent = Player.new()
	Game.opponent.id = 1 - id
	
	var client_peer_id: int = multiplayer.get_unique_id()
	Multiplayer.players[client_peer_id] = Game.player
	Player.get_from_id(id).peer_id = client_peer_id
	
	for peer: int in multiplayer.get_peers():
		if peer == 1:
			continue
		
		Multiplayer.players[peer] = Game.opponent
		Player.get_from_id(1 - id).peer_id = peer
		break


## Makes the client switch to a scene. CAN ONLY BE RPC CALLED SERVER SIDE.
@rpc("authority", "call_local", "reliable")
func change_scene_to_file(file: StringName) -> void:
	get_tree().change_scene_to_file(file)


## Sets the random seed of the client.
@rpc("authority", "call_local", "reliable")
func seed_random(random_seed: int) -> void:
	seed(random_seed)


## Sends the server config options to the client.
@rpc("authority", "call_remote", "reliable")
func send_config(max_board_space: int, max_hand_size: int, max_deck_size: int, min_deck_size: int) -> void:
	if is_server:
		return
	
	Settings.server.max_board_space = max_board_space
	Settings.server.max_hand_size = max_hand_size
	Settings.server.max_deck_size = max_deck_size
	Settings.server.min_deck_size = min_deck_size
	
	print("Config loaded:\n'''\nmax_board_space=%d\nmax_hand_size=%d\nmax_deck_size=%d\nmin_deck_size=%d\n'''\n" % [
		max_board_space,
		max_hand_size,
		max_deck_size,
		min_deck_size,
	])


## Send the client's deckcode to the server.
@rpc("any_peer", "call_remote", "reliable")
func send_deckcode(deckcode: String) -> void:
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = Player.get_from_peer_id(sender_peer_id)
	deckcode = deckcode if deckcode else "4/1:30/1"
	
	var deck_info: Dictionary = Deckcode.import(deckcode, player)
	
	if not deck_info.has("cards"):
		server_response.rpc_id(sender_peer_id, false, "Invalid deckcode")
		kick(sender_peer_id, true)
		return
	
	_deckcodes[sender_peer_id] = {
		"deckcode": deckcode,
		"hero": deck_info.hero,
		"hero_id": deck_info.hero_id,
		"cards": deck_info.cards,
	}
	
	server_response.rpc_id(sender_peer_id, true)


## Creates a [Blueprint] from [param id].
@rpc("authority", "call_local", "reliable")
func create_blueprint_from_id(id: int, player_id: int, location: StringName, index: int) -> Blueprint:
	var player: Player = Player.get_from_id(player_id)
	var blueprint: Blueprint = Blueprint.create_from_id(id, player)
	blueprint.card.add_to_location(location, index)
	
	return blueprint


## Sends a response from the server to the client.[br]
## [br]
## If [param text] is set, it will call [method feedback] on the client with that text too.
@rpc("authority", "call_remote", "reliable")
func server_response(success: bool, text: String = "") -> void:
	server_responded.emit(success, text)


## Sends feedback to the client using [member Game.feedback].
@rpc("authority", "call_remote", "reliable")
func feedback(text: String) -> void:
	text = "[Server]: %s" % text
	
	print(text)
	Game.feedback(text, Game.FeedbackType.ERROR)


## Sends all the information needed to start the game to the clients.
@rpc("authority", "call_local", "reliable")
func start_game(deckcode: String, opponent_deckcode_size: int, opponent_hero_id: int) -> void:
	Game.current_player = Game.player1
	Game.player1.empty_mana = 1
	Game.player1.mana = 1
	
	Game.player.deckcode = deckcode
	Game.opponent.deckcode = ""
	
	for i: int in opponent_deckcode_size:
		# The placeholder card has an id of 6.
		var placeholder: Blueprint = Blueprint.create_from_id(6, Game.opponent)
		placeholder.card.add_to_location(&"Deck", i)
	
	var deck: Dictionary = Deckcode.import(deckcode, Game.player, is_server)
	
	Game.player.hero_class = deck.hero.classes[0]
	Game.player.deck = deck.cards
	
	var opponents_hero: Blueprint = Blueprint.create_from_id(opponent_hero_id, Game.opponent)
	opponents_hero.card.location = &"Hero"
	
	var opponents_hero_power: Blueprint = Blueprint.create_from_id(opponents_hero.hero_power_id, Game.opponent)
	opponents_hero_power.card.location = &"Hero Power"
	
	opponents_hero.card.hero_power = opponents_hero_power.card
	
	Game.player.draw_cards(3 if Game.player.id == 0 else 4, false)
	Game.opponent.draw_cards(3 if Game.player.id == 0 else 4, false)
	
	Game.game_started.emit()
#endregion
