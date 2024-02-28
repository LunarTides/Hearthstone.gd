extends Node
## Packet related functions.
## @experimental


#region Signals
## Emits when a packet gets received. Emits before the packet gets handled by the client who received it.
signal packet_received_before(sender_peer_id: int, packet_type: Enums.PACKET_TYPE, player_id: int, info: Array)

## Emits when a packet gets received. Emits after the packet gets handled by the client who received it.
signal packet_received_after(sender_peer_id: int, packet_type: Enums.PACKET_TYPE, player_id: int, info: Array)
#endregion


#region Public Variables
## Returns [code]Multiplayer.is_server[/code]
var is_server: bool:
	get:
		return Multiplayer.is_server

## A history of packets. It looks like this: [[sender_peer_id, packet_type, player_id, info]]
var history: Array[Array] = []
#endregion


#region Public Functions
## Returns a packet in a readable format. E.g. [Packet]: Server (Player: 1): [PLAY] [1, 0, 1]
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
#endregion


#region Private Functions
@rpc("any_peer", "call_local", "reliable")
func _send_packet(packet_type: Enums.PACKET_TYPE, player_id: int, info: Array) -> void:
	var result: Enums.PACKET_FAILURE_TYPE = __send_packet(packet_type, player_id, info)
	
	if result != Enums.PACKET_FAILURE_TYPE.NONE:
		push_warning("Packet dropped with code [%s] ^^^^" % Enums.PACKET_FAILURE_TYPE.keys()[result])


func __send_packet(packet_type: Enums.PACKET_TYPE, player_id: int, info: Array) -> Enums.PACKET_FAILURE_TYPE:
	if not is_server:
		return Enums.PACKET_FAILURE_TYPE.IS_CLIENT
	
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	
	var sender_player: Player = Multiplayer.get_player_from_peer_id(sender_peer_id)
	var actor_player: Player = Multiplayer.players.values().filter(func(player: Player) -> bool: return player.id == player_id)[0]
	
	var packet_name: String = Enums.PACKET_TYPE.keys()[packet_type]
	print(get_readable_packet(sender_peer_id, packet_type, player_id, info))
	
	# Anticheat
	if not _anticheat(packet_type, actor_player, info):
		var consequence_text: String
		
		match Multiplayer.anticheat_conseqence:
			Enums.ANTICHEAT_CONSEQUENCE.DROP_PACKET:
				consequence_text = "PACKET DROPPED"
			
			Enums.ANTICHEAT_CONSEQUENCE.KICK:
				consequence_text = "PLAYER KICKED"
				Multiplayer.kick(sender_peer_id)
			
			Enums.ANTICHEAT_CONSEQUENCE.BAN:
				consequence_text = "PLAYER BANNED"
				var ip_address: String = Multiplayer.get_ip_address(sender_peer_id)
				Multiplayer.ban_list.append(ip_address)
				Multiplayer.kick(sender_peer_id)
		
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
	_accept_packet.rpc(packet_type, sender_peer_id, player_id, info)
	
	return Enums.PACKET_FAILURE_TYPE.NONE


## Runs the anticheat on a packet.
func _anticheat(packet_type: Enums.PACKET_TYPE, actor_player: Player, info: Array) -> bool:
	if Multiplayer.anticheat_level == 0:
		return true
	
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	var sender_player: Player = Multiplayer.get_player_from_peer_id(sender_peer_id)
	
	# Packets sent from the server should bypass the anitcheat.
	if sender_peer_id == 1:
		return true
	
	
	# TODO: More Anticheat
	match packet_type:
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
		
		# End turn
		Enums.PACKET_TYPE.END_TURN:
			# The player whose turn it is should be the same player as the one who sent the packet.
			if _anticheat_check(sender_player != Game.current_player, 2):
				return false
			
			# The player who ends the turn should be the same player as the one who sent the packet.
			if _anticheat_check(sender_player != actor_player, 2):
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
			
			# Only the server can do this.
			if _anticheat_check(true, 2):
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
			
			# The player should afford the card.
			if _anticheat_check(actor_player.mana < card.cost, 1):
				return false
			
			# It should be the player's turn.
			if _anticheat_check(actor_player != Game.current_player, 1):
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
	return condition and (Multiplayer.anticheat_level >= min_anticheat_level or Multiplayer.anticheat_level < 0)


## Returns if [param info] is in the history within [param range].
func _in_packet_history(info: Array, range: int, only_use_server_packets: bool = false) -> bool:
	range = range if range < history.size() else history.size()
	
	for i: int in range:
		var object: Array = history[-(i + 1)]
		var peer_id: int = object[0]
		var stored_info: Array = object[3]
		
		if stored_info == info and (not only_use_server_packets || peer_id == 1):
			return true
	
	return false


#region Accept Packet Functions
@rpc("authority", "call_local", "reliable")
func _accept_packet(packet_type: Enums.PACKET_TYPE, sender_peer_id: int, player_id: int, info: Array) -> void:
	var packet_name: String = Enums.PACKET_TYPE.keys()[packet_type]
	
	packet_received_before.emit(sender_peer_id, packet_type, player_id, info)
	history.append([sender_peer_id, packet_type, player_id, info])
	
	var method_name: String = "_accept_" + packet_name.to_lower() + "_packet"
	assert(self[method_name], method_name + " doesn't exist.")
	self[method_name].call(player_id, info)
	
	packet_received_after.emit(sender_peer_id, packet_type, player_id, info)


# Here are the functions that gets called on the clients + server when a packet gets sent. Handled in _accept_packet
func _accept_summon_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	card.add_to_location(Enums.LOCATION.BOARD, board_index)
	Game.layout_cards(player)


func _accept_play_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	player.mana -= card.cost
	
	if card.types.has(Enums.TYPE.MINION):
		player.summon_card(card, board_index, false)
		
		card.trigger_ability(Enums.ABILITY.BATTLECRY, false)
	
	if card.types.has(Enums.TYPE.SPELL):
		card.trigger_ability(Enums.ABILITY.CAST, false)
		
		card.location = Enums.LOCATION.NONE


func _accept_create_card_packet(player_id: int, info: Array) -> void:
	var blueprint_path: String = info[0]
	var location: Enums.LOCATION = info[1]
	var location_index: int = info[2]
	
	Multiplayer.spawn_card(blueprint_path, player_id, location, location_index)


func _accept_draw_cards_packet(player_id: int, info: Array) -> void:
	var amount: int = info[0]
	
	var player: Player = Game.get_player_from_id(player_id)
	
	for _i: int in amount:
		var card: Card = player.deck.pop_back()
		
		if player.hand.size() >= Game.max_hand_size:
			# Burn the card.
			return
		
		card.add_to_location(Enums.LOCATION.HAND, player.hand.size())
		
		# Create card node.
		var card_node: CardNode = Multiplayer.CardScene.instantiate()
		card_node.card = card
		card_node.layout()
		
		(await Game.wait_for_node("/root/Main")).add_child(card_node)


func _accept_end_turn_packet(player_id: int, info: Array) -> void:
	Game.current_player = Game.opposing_player
	Game.turn += 1
	
	var player: Player = Game.current_player
	
	# TODO: Show the player's mana
	player.empty_mana = min(player.empty_mana + 1, player.max_mana)
	player.mana = player.empty_mana
	
	player.draw_cards(1, false)


func _accept_reveal_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	card.override_is_hidden = Enums.NULLABLE_BOOL.FALSE


func _accept_trigger_ability_packet(player_id: int, info: Array) -> void:
	var location: Enums.LOCATION = info[0]
	var location_index: int = info[1]
	var ability: Enums.ABILITY = info[2]
	
	var player: Player = Game.get_player_from_id(player_id)
	var card: Card = Game.get_card_from_index(player, location, location_index)
	
	for ability_callback: Callable in card.abilities[ability]:
		ability_callback.call(player, card)
#endregion
#endregion
