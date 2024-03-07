extends Node
## @experimental


#region Enums
enum Consequence {
	## Drops the cheated packet.
	DROP_PACKET,
	## Drops the cheated packet and kicks the player.
	KICK,
	## Drops the cheated packet and bans the player.
	BAN,
}
#endregion


#region Public Functions
## Runs the anticheat on a packet.
func run(packet_type: Packet.PacketType, sender_peer_id: int, actor_player: Player, info: Array) -> bool:
	if Multiplayer.anticheat_level == 0:
		return true
	
	var packet_name: String = Packet.PacketType.keys()[packet_type]
	var sender_player: Player = Player.get_from_peer_id(sender_peer_id)
	
	# Packets sent from the server should bypass the anitcheat.
	if sender_peer_id == 1:
		return true
	
	
	var method_name: String = "_run_" + packet_name.to_lower() + "_packet"
	var method: Callable = self[method_name]
	
	assert(method, "No anticheat logic for '%s'" % Packet.PacketType.keys()[packet_type])
	return method.call(sender_peer_id, sender_player, actor_player, info)
#endregion


#region Private Functions
#region Helper Functions
## Returns if [param condition] is true and [member anticheat_level] is more or equal to [param min_level].
func _check(condition: bool, min_level: int) -> bool:
	return condition and Multiplayer.anticheat_level >= min_level


## Returns if [param info]'s size is equal to [param types]'s size and the elements in [param info] matches the types in [param types].
func _info_check(info: Array, types: PackedInt32Array) -> bool:
	if info.size() != types.size():
		return false
	
	var i: int = 0
	for expected_type: int in types:
		var actual_type: int = typeof(info[i])
		
		if actual_type != expected_type:
			# Allow this.
			if (
				actual_type == TYPE_INT and expected_type == TYPE_FLOAT or
				actual_type == TYPE_FLOAT and expected_type == TYPE_INT
			):
				i += 1
				continue
			
			push_warning("info[%d] is of type %s, was expecting %s." % [
				i,
				type_string(actual_type),
				type_string(expected_type),
			])
			return false
		
		i += 1
	
	return true


## Returns if [param info] is in the history within [param range].
func _in_packet_history(info: Array, history_range: int, only_use_server_packets: bool = false) -> bool:
	history_range = history_range if history_range < Packet.history.size() else Packet.history.size()
	
	for i: int in history_range:
		var object: Array = Packet.history[-(i + 1)]
		var peer_id: int = object[0]
		var stored_info: Array = object[3]
		
		if stored_info == info and (not only_use_server_packets || peer_id == 1):
			return true
	
	return false


# Send feedback to the client. Optimized for the anticheat.
func _feedback(text: String, sender_peer_id: int) -> void:
	Multiplayer.feedback.rpc_id(sender_peer_id, "Anticheat Failed - %s" % text)
#endregion


#region Packet Specific Anticheat
# Attack
func _run_attack_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, [TYPE_INT, TYPE_INT, TYPE_INT, TYPE_INT, TYPE_INT]):
		_feedback("Invalid CREATE_CARD info.", sender_peer_id)
		return false
	
	var attack_mode: Packet.AttackMode = info[0]
	
	var attacker_location_or_player_id: int = info[1]
	var attacker_index: int = info[2]
	
	var target_location_or_player_id: int = info[3]
	var target_index: int = info[4]
	
	var attacker_card: Card = Card.get_from_index(actor_player, attacker_location_or_player_id, attacker_index)
	var target_card: Card = Card.get_from_index(actor_player.opponent, target_location_or_player_id, target_index)
	
	# The player whose turn it is should be the same player as the one who sent the packet.
	if _check(sender_player != Game.current_player, 2):
		_feedback("It is not your turn.", sender_peer_id)
		return false
	
	# The player who ends the turn should be the same player as the one who sent the packet.
	if _check(sender_player != actor_player, 2):
		_feedback("You are not authorized to attack for your opponent.", sender_peer_id)
		return false
	
	# Test the attacker card
	if attack_mode == Packet.AttackMode.CARD_VS_CARD or attack_mode == Packet.AttackMode.CARD_VS_PLAYER:
		# The attacking card needs to exist.
		if _check(attacker_card == null, 1):
			_feedback("The attacking card was not found.", sender_peer_id)
			return false
		
		# The attacking card needs to be owned by the actor.
		if _check(attacker_card.player != actor_player, 2):
			_feedback("You don't own the attacking card.", sender_peer_id)
			return false
		
		# The attacking card cannot have attacked this turn.
		if _check(attacker_card.has_attacked_this_turn, 2):
			_feedback("The attacker has already attacked this turn.", sender_peer_id)
			return false
		
		# The attacking card cannot be exhausted.
		if _check(attacker_card.exhausted, 2):
			_feedback("The attacker is exhausted.", sender_peer_id)
			return false
	
	# Test the target card
	if attack_mode == Packet.AttackMode.CARD_VS_CARD or attack_mode == Packet.AttackMode.PLAYER_VS_CARD:
		# The target card needs to exist.
		if _check(target_card == null, 1):
			_feedback("The target card was not found.", sender_peer_id)
			return false
		
		# The target card needs to be owned by the actor's opponent.
		if _check(target_card.player != actor_player.opponent, 2):
			_feedback("You own the target card.", sender_peer_id)
			return false
	
	# TODO: Implement this when attacking players is added.
	if attack_mode == Packet.AttackMode.CARD_VS_PLAYER or attack_mode == Packet.AttackMode.PLAYER_VS_CARD or attack_mode == Packet.AttackMode.PLAYER_VS_PLAYER:
		return false
	
	return true


# Create Card
func _run_create_card_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, [TYPE_STRING, TYPE_INT, TYPE_INT]):
		_feedback("Invalid CREATE_CARD info.", sender_peer_id)
		return false
	
	var blueprint_path: String = info[0]
	var location: Card.Location = info[1]
	var location_index: int = info[2]
	
	# Blueprint path needs to be valid.
	if _check(load(blueprint_path) == null, 1):
		_feedback("Invalid blueprint path.", sender_peer_id)
		return false
	
	# Only the server can do this.
	if _check(true, 2):
		_feedback("Only the server can do this.", sender_peer_id)
		return false
	
	if location == Card.Location.HAND:
		# The player needs to have enough space in their hand.
		if _check(actor_player.hand.size() >= Game.max_hand_size, 1):
			_feedback("You do not have enough space in your hand.", sender_peer_id)
			return false
	elif location == Card.Location.BOARD:
		# The player needs to have enough space on their board.
		if _check(actor_player.board.size() >= Game.max_board_space, 1):
			_feedback("You do not have enough space on your board.", sender_peer_id)
			return false
	
	return true


# Draw Cards
func _run_draw_cards_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, [TYPE_INT]):
		_feedback("Invalid DRAW_CARDS info.", sender_peer_id)
		return false
	
	var amount: int = info[0]
	
	# Only the server can do this.
	if _check(true, 2):
		_feedback("Only the server can do this.", sender_peer_id)
		return false
	
	return true


# End Turn
func _run_end_turn_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, []):
		_feedback("Invalid END_TURN info.", sender_peer_id)
		return false
	
	# The player whose turn it is should be the same player as the one who sent the packet.
	if _check(sender_player != Game.current_player, 2):
		_feedback("It is not your turn.", sender_peer_id)
		return false
	
	# The player who ends the turn should be the same player as the one who sent the packet.
	if _check(sender_player != actor_player, 2):
		_feedback("You are not authorized to end your opponent's turn.", sender_peer_id)
		return false
	
	return true


# Play
func _run_play_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, [TYPE_INT, TYPE_INT, TYPE_INT, TYPE_VECTOR3]):
		_feedback("Invalid PLAY info.", sender_peer_id)
		return false
	
	var location: Card.Location = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	var position: Vector3 = info[3]
	
	var card: Card = Card.get_from_index(sender_player, location, location_index)
	
	# The card should exist.
	if _check(not card, 1):
		_feedback("The specified card does not exist in Player %d's %s at %d." % [
			sender_player.id + 1,
			Card.Location.keys()[location],
			location_index,
		], sender_peer_id)
		return false
	
	# The player should afford the card.
	if _check(actor_player.mana < card.cost, 1):
		_feedback("You can not afford this card.", sender_peer_id)
		return false
	
	# It should be the player's turn.
	if _check(actor_player != Game.current_player, 1):
		_feedback("It is not your turn.", sender_peer_id)
		return false
	
	# The player who play the card should be the same player as the one who sent the packet.
	if _check(sender_player != actor_player, 2):
		_feedback("You are not authorized to play a card on behalf of your opponent.", sender_peer_id)
		return false
	
	# The card should be in the player's hand.
	if _check(card.location != Card.Location.HAND, 3):
		_feedback("That card is not in your card.", sender_peer_id)
		return false
	
	# Minion
	if card.types.has(Card.Type.MINION):
		# The player should have enough space on their board.
		if _check(actor_player.board.size() >= Game.max_board_space, 1):
			_feedback("You do not have enough space on the board.", sender_peer_id)
			return false
	
	return true


# Reveal
func _run_reveal_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, [TYPE_INT, TYPE_INT]):
		_feedback("Invalid REVEAL info.", sender_peer_id)
		return false
	
	var location: Card.Location = info[0]
	var index: int = info[1]
	
	# The player whose card gets revealed should be the same player as the one who sent the packet
	if _check(sender_player != actor_player, 2):
		_feedback("You are not authorized to reveal a card on behalf of your opponent.", sender_peer_id)
		return false
	
	return true


# Summon
func _run_summon_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, [TYPE_INT, TYPE_INT, TYPE_INT]):
		_feedback("Invalid SUMMON info.", sender_peer_id)
		return false
	
	var location: Card.Location = info[0]
	var location_index: int = info[1]
	var board_index: int = info[2]
	
	var card: Card = Card.get_from_index(sender_player, location, location_index)
	
	# The card should exist.
	if _check(not card, 1):
		_feedback("The specified card does not exist in Player %d's %s at %d." % [
			sender_player.id + 1,
			Card.Location.keys()[location],
			location_index,
		], sender_peer_id)
		return false
		
	# The player should have enough space on their board.
	if _check(actor_player.board.size() >= Game.max_board_space, 1):
		_feedback("You do not have enough space on your board.", sender_peer_id)
		return false
		
	# The player who summons the card should be the same player as the one who sent the packet.
	if _check(sender_player != actor_player, 2):
		_feedback("You are not authorized to summon a card on behalf of your opponent.", sender_peer_id)
		return false
	
	# The card should be summonable
	if _check(not card.types.has(Card.Type.MINION) and not card.types.has(Card.Type.LOCATION), 2):
		_feedback("A minion with these types (%s) cannot be summoned." % ", ".join(card.types.map(func(type: Card.Type) -> String:
			return Card.Type.keys()[type]
		)), sender_peer_id)
		return false
	
	# Only the server can do this.
	if _check(true, 2):
		_feedback("Only the server can do this.", sender_peer_id)
		return false
	
	# The card should be in the player's hand.
	if _check(card.location != Card.Location.HAND, 3):
		_feedback("That card is not in your hand.", sender_peer_id)
		return false
	
	# Check if the card is queued to be summoned.
	if _check(_in_packet_history([location, location_index, board_index], 2, true), 3):
		_feedback("That card does not have sufficent reason to be summoned.", sender_peer_id)
		return false
	
	return true


# Trigger Ability
func _run_trigger_ability_packet(sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	# The info needs to be correct.
	if not _info_check(info, [TYPE_INT, TYPE_INT, TYPE_INT]):
		_feedback("Invalid TRIGGER_ABILITY info.", sender_peer_id)
		return false
	
	var location: Card.Location = info[0]
	var location_index: int = info[1]
	var ability: Card.Ability = info[2]
	
	var card: Card = Card.get_from_index(actor_player, location, location_index)
	
	# The card should exist.
	if _check(card == null, 1):
		_feedback("The specified card does not exist in Player %d's %s at %d." % [
			sender_player.id + 1,
			Card.Location.keys()[location],
			location_index,
		], sender_peer_id)
		return false
	
	# The ability should exist.
	if _check(!Card.Ability.values().has(ability), 1):
		_feedback("The specified ability (%s) does not exist." % ability, sender_peer_id)
		return false
	
	# The ability should exist on that card.
	if _check(!card.abilities.has(ability), 1):
		_feedback("The specified card does not have that ability (%s)." % Card.Ability.keys()[ability], sender_peer_id)
		return false
	
	# The player who sent the packet should own the card.
	if _check(sender_player != actor_player, 2):
		_feedback("You are not authorized to trigger a card's ability on behalf of your opponent.", sender_peer_id)
		return false
	
	# Check if the card has already been triggered.
	if _check(_in_packet_history([location, location_index, ability], 3, true), 3):
		_feedback("That card does not have sufficent reason to for its ability to be triggered.", sender_peer_id)
		return false
	
	return true
#endregion
#endregion
