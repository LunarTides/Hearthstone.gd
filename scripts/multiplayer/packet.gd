extends Node
## Packet related functions.
## @experimental


#region Signals
## Emits when a packet gets received. EMITS BEFORE THE PACKET GETS HANDLED BY THE CLIENT WHO RECEIVED IT.[br]
## [br]
## [b]Use a signal from Game (E.g. [signal Game.card_summoned]) instead in most cases.[/b]
signal packet_received(sender_peer_id: int, packet_type: StringName, player_id: int, info: Array)
#endregion


#region Enum-likes
var packet_types: Array[StringName] = [
	&"Attack",
	&"Create Card",
	&"Draw Cards",
	&"End Turn",
	&"Hero Power",
	&"Play",
	&"Reveal",
	&"Set Drag To Play Target",
	&"Summon",
	&"Trigger Ability",
]

var packet_failure_types: Array[StringName] = [
	&"None",
	&"Unknown",
	&"Is Client",
	&"Anticheat",
]

var attack_modes: Array[StringName] = [
	&"Card Vs Card",
	&"Card Vs Player",
	&"Player Vs Card",
	&"Player Vs Player",
]

var target_modes: Array[StringName] = [
	&"Card",
	&"Player",
]
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
func get_readable(sender_peer_id: int, packet_type: StringName, player_id: int, info: Array) -> String:
	return "[Packet]: %s (Player: %d): [%s] %s" % [
		"Server" if sender_peer_id == 1 else str(sender_peer_id),
		player_id,
		packet_type,
		info
	]


## Sends a packet to the server that will be sent to all the clients.[br]
## This is used to sync every action.
func send(packet_type: StringName, player_id: int, info: Array, suppress_warning: bool = false) -> void:
	# Only send the "Sending packet" message on non-debug builds since it spams the console with garbage.
	if not OS.is_debug_build() and not is_server:
		print("Sending packet: " + get_readable(multiplayer.get_unique_id(), packet_type, player_id, info))
	
	if is_server and not suppress_warning:
		push_warning("A packet is being sent from the server. These packets bypass the anticheat. Be careful.")
	
	_send.rpc_id(1, packet_type, player_id, info)


## Sends a packet if [param condition] is [code]true[/code]. If not, only apply the packet locally.
func send_if(condition: bool, packet_type: StringName, player_id: int, info: Array, suppress_warning: bool = false) -> void:
	if condition:
		send(packet_type, player_id, info, suppress_warning)
	else:
		_accept(packet_type, multiplayer.get_unique_id(), player_id, info)
#endregion


#region Private Functions
@rpc("any_peer", "call_local", "reliable")
func _send(packet_type: StringName, player_id: int, info: Array) -> void:
	var result: StringName = await __send(packet_type, player_id, info)
	
	if result != &"None":
		push_warning("Packet dropped with code [%s] ^^^^" % result)


func __send(packet_type: StringName, player_id: int, info: Array) -> StringName:
	if not is_server:
		return &"Is Client"
	
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	
	var sender_player: Player = Player.get_from_peer_id(sender_peer_id)
	var actor_player: Player = Multiplayer.players.values().filter(func(player: Player) -> bool: return player.id == player_id)[0]
	
	print(get_readable(sender_peer_id, packet_type, player_id, info))
	
	# Anticheat
	if not await Anticheat.run(packet_type, sender_peer_id, actor_player, info):
		var consequence_text: String
		
		match Settings.server.anticheat_consequence:
			Anticheat.Consequence.DROP_PACKET:
				consequence_text = "PACKET DROPPED"
			
			Anticheat.Consequence.KICK:
				consequence_text = "PLAYER KICKED"
				Multiplayer.kick(sender_peer_id)
			
			Anticheat.Consequence.BAN:
				consequence_text = "PLAYER BANNED"
				var ip_address: String = Multiplayer.get_ip_address(sender_peer_id)
				Settings.server.ban_list.append(ip_address)
				Multiplayer.kick(sender_peer_id)
		
		push_error("!!! ANTICHEAT TRIGGERED IN PREVIOUS PACKET. %s. !!!" % consequence_text)
		return &"Anticheat"
	
	
	# Actually handle the packet
	
	# Invalid packet type
	if not packet_types.has(packet_type):
		var message: String = "Invalid packet '%s'." % packet_type
		Multiplayer.feedback.rpc_id(sender_peer_id, message)
		assert(false, message)
		
		push_error(message + " The client who sent this packet might be modded. If you think this is a bug, open an issue here: https://github.com/LunarTides/Hearthstone.gd")
		return &"Unknown"
	
	# Broadcast the packet to all clients & server
	_accept.rpc(packet_type, sender_peer_id, player_id, info)
	
	return &"None"


#region Accept Packet Functions
@rpc("authority", "call_local", "reliable")
func _accept(packet_type: StringName, sender_peer_id: int, player_id: int, info: Array) -> void:
	var player: Player = Player.get_from_id(player_id)
	
	packet_received.emit(sender_peer_id, packet_type, player_id, info)
	history.append([sender_peer_id, packet_type, player_id, info])
	
	var method_name: String = "_accept_" + packet_type.to_snake_case() + "_packet"
	var method: Callable = self[method_name]
	
	assert(method, method_name + " doesn't exist.")
	method.call(player, sender_peer_id, info)


# Here are the functions that gets called on the clients + server when a packet gets sent. Handled in _accept_packet
func _accept_attack_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var attack_mode: StringName = info[0]
	
	var attacker_location: StringName = info[1]
	var attacker_index: int = info[2]
	
	var target_location: StringName = info[3]
	var target_index: int = info[4]
	
	var attacker_player_id: int = info[5]
	var target_player_id: int = info[6]
	
	var attacker_card: Card = Card.get_from_index(player, attacker_location, attacker_index)
	var target_card: Card = Card.get_from_index(player.opponent, target_location, target_index)
	
	var attacker_player: Player = Player.get_from_id(attacker_player_id)
	var target_player: Player = Player.get_from_id(target_player_id)
	
	# Attacker is player and target is player
	if attack_mode == &"Player Vs Player":
		Game.attacked.emit(false, attacker_player, target_player, sender_peer_id)
		Game._attack_attacker_is_player_and_target_is_player(attacker_player, target_player)
		Game.attacked.emit(true, attacker_player, target_player, sender_peer_id)
	
	# Attacker is player and target is card
	elif attack_mode == &"Player Vs Card":
		Game.attacked.emit(false, attacker_player, target_card, sender_peer_id)
		Game._attack_attacker_is_player_and_target_is_card(attacker_player, target_card)
		Game.attacked.emit(true, attacker_player, target_card, sender_peer_id)
	
	# Attacker is card and target is player
	elif attack_mode == &"Card Vs Player":
		Game.attacked.emit(false, attacker_card, target_player, sender_peer_id)
		Game._attack_attacker_is_card_and_target_is_player(attacker_card, target_player)
		Game.attacked.emit(true, attacker_card, target_player, sender_peer_id)
	
	# Attacker is card and target is card
	elif attack_mode == &"Card Vs Card":
		Game.attacked.emit(false, attacker_card, target_card, sender_peer_id)
		Game._attack_attacker_is_card_and_target_is_card(attacker_card, target_card)
		Game.attacked.emit(true, attacker_card, target_card, sender_peer_id)


func _accept_create_card_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var id: int = info[0]
	var location: StringName = info[1]
	var location_index: int = info[2]
	
	var card: Card = Blueprint.create_from_id(id, player).card
	card.add_to_location(location, location_index)
	
	Game.card_created.emit(true, card, player, sender_peer_id)


func _accept_draw_cards_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var amount: int = info[0]
	
	Game.cards_drawn.emit(false, amount, player, sender_peer_id)
	
	for _i: int in amount:
		var card: Card = player.deck.pop_back()
		
		if player.hand.size() >= Settings.server.max_hand_size:
			# TODO: Burn the card.
			return
		
		if not card:
			# TODO: Fatigue
			return
		
		# Create card node.
		card.add_to_location(&"Hand", player.hand.size())
	
	Game.cards_drawn.emit(true, amount, player, sender_peer_id)


func _accept_end_turn_packet(sender_player: Player, sender_peer_id: int, info: Array) -> void:
	var player: Player = sender_player.opponent
	
	Game.turn_ended.emit(false, sender_player, sender_peer_id)
	
	Game.current_player = player
	Game.turn += 1
	
	# TODO: Show the player's mana
	player.empty_mana = min(player.empty_mana + 1, player.max_mana)
	player.mana = player.empty_mana
	
	player.draw_cards(1, false)
	
	if Game.is_players_turn and not Multiplayer.is_server:
		DisplayServer.window_request_attention()
	
	Game.turn_ended.emit(true, sender_player, sender_peer_id)


func _accept_hero_power_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var hero_power: Card = player.hero.hero_power
	
	Game.hero_power.emit(false, player, sender_peer_id)
	
	hero_power.refunded = false
	
	_accept_trigger_ability_packet(player, sender_peer_id, [hero_power.location, hero_power.index, &"Hero Power"])
	if hero_power.refunded:
		return
	
	player.has_used_hero_power_this_turn = true
	player.mana -= hero_power.cost
	
	Game.hero_power.emit(true, player, sender_peer_id)


func _accept_play_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var location: StringName = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	var position: Vector3i = info[3]
	
	var card: Card = Card.get_from_index(player, location, location_index)
	Game.card_played.emit(false, card, board_index, player, sender_peer_id)
	
	card.override_is_hidden = Game.NullableBool.FALSE
	
	await card.tween_to(0.3, position, Vector3.ZERO, Vector3.ONE)
	card._should_layout = true
	
	player.mana -= card.cost
	player.armor += card.armor
	
	card.refunded = false
	
	if card.types.has(&"Minion"):
		if card.abilities.has(&"Battlecry"):
			card.trigger_ability(&"Battlecry", false)
			await card._wait_for_ability(&"Battlecry")
			
			if card.refunded:
				card._refund()
				return
		
		# Summon after ability for refunding.
		player.summon_card(card, board_index, false, true)
	
	if card.types.has(&"Spell"):
		card.trigger_ability(&"Cast", false)
		await card._wait_for_ability(&"Cast")
		
		if card.refunded:
			card._refund()
			return
		
		card.location = &"None"
	
	if card.types.has(&"Hero"):
		card.trigger_ability(&"Battlecry", false)
		await card._wait_for_ability(&"Battlecry")
		
		if card.refunded:
			card._refund()
			return
		
		card.location = &"Hero"
	
	Game.card_played.emit(true, card, board_index, player, sender_peer_id)


func _accept_reveal_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var location: StringName = info[0]
	var location_index: int = info[1]
	
	var card: Card = Card.get_from_index(player, location, location_index)
	Game.card_revealed.emit(false, card, player, sender_peer_id)
	
	card.override_is_hidden = Game.NullableBool.FALSE
	
	Game.card_revealed.emit(true, card, player, sender_peer_id)


func _accept_set_drag_to_play_target_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var target_mode: StringName = info[0]
	
	var location: StringName = info[1]
	var location_index: int = info[2]
	
	var target_alignment: int = info[3]
	var target_location: StringName = info[4]
	var target_index: int = info[5]

	var card: Card = Card.get_from_index(player, location, location_index)
	var target_player: Player = Player.get_from_id(target_alignment)
	
	if target_mode == &"Card":
		var target_card: Card = Card.get_from_index(target_player, target_location, target_index)
		card.drag_to_play_target = target_card
	else:
		card.drag_to_play_target = target_player


func _accept_summon_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var location: StringName = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	
	var card: Card = Card.get_from_index(player, location, location_index)
	Game.card_summoned.emit(false, card, board_index, player, sender_peer_id)
	
	card.add_to_location(&"Board", board_index)
	card.exhausted = true
	
	Game.card_summoned.emit(true, card, board_index, player, sender_peer_id)


func _accept_trigger_ability_packet(player: Player, sender_peer_id: int, info: Array) -> void:
	var location: StringName = info[0]
	var location_index: int = info[1]
	var ability: StringName = info[2]
	
	var card: Card = Card.get_from_index(player, location, location_index)
	
	Game.card_ability_triggered.emit(false, card, ability, player, sender_peer_id)
	
	for ability_callback: Callable in card.abilities[ability]:
		var success: int = await ability_callback.call()
		
		if success == Blueprint.REFUND:
			card.refunded = true
			break
	
	Game.card_ability_triggered.emit(true, card, ability, player, sender_peer_id)
#endregion
#endregion
