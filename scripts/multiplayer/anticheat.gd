extends Node
## @experimental


#region Signals
## Emits when the anticheat handles a request. Supports the Module system: on [code]false[/code], fail the anticheat.
signal request(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array)
#endregion


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
func run(packet_type: StringName, sender_peer_id: int, actor_player: Player, info: Array) -> bool:
	if Settings.server.anticheat_level == 0:
		return true
	
	var sender_player: Player = Player.get_from_peer_id(sender_peer_id)
	
	# Packets sent from the server should bypass the anitcheat.
	if sender_peer_id == 1:
		return true
	
	
	var method_name: String = "_run_" + packet_type.to_snake_case() + "_packet"
	
	# Check if there exists a method for that packet type in core. If not, it might still exist in a module.
	if get_method_list().any(func(dict: Dictionary) -> bool: return dict.name == method_name):
		var method: Callable = self[method_name]
		var core_anticheat_response: bool = method.bindv(info).call(sender_peer_id, sender_player, actor_player)
		
		print_verbose("\n[AC] Core Response: %s" % core_anticheat_response)
		
		if not core_anticheat_response:
			return false
	else:
		print_verbose("\n[AC] Core cannot handle packet (%s), passing to modules..." % packet_type)
	
	# Passed the core anticheat. Let the modules do their anticheat.
	var modules_anticheat_response: bool = await Modules.request(
		Modules.Hook.ANTICHEAT,
		[packet_type, sender_peer_id, sender_player, actor_player, info],
	)
	
	print_verbose("[AC] Modules Reponse: %s" % modules_anticheat_response)
	return modules_anticheat_response


#region Helper Functions
## Sends feedback to the client. Optimized for the anticheat.
func feedback(text: String, sender_peer_id: int) -> void:
	Multiplayer.feedback.rpc_id(sender_peer_id, "Anticheat Failed - %s" % text)


## Returns if [param condition] is true and [member anticheat_level] is more or equal to [param min_level].
func check(condition: bool, min_level: int) -> bool:
	return condition and (Settings.server.anticheat_level >= min_level or Settings.server.anticheat_level < 0)


## If the card gotten from [param player], [param location], [param index] doesn't exist, returns [code]true[/code].[br]
## Use this instead of [method check].
func check_card(player: Player, location: StringName, index: int, sender_peer_id: int) -> bool:
	var card: Card = Card.get_from_index(player, location, index)
	
	if check(not card, 1):
		feedback("The specified card does not exist in Player %d's %s at %d." % [
			player.id + 1,
			location,
			index,
		], sender_peer_id)
		return true
	
	return false


## Returns if [param info]'s size is equal to [param types]'s size and the elements in [param info] matches the types in [param types].
func info_check(info: Array, types: PackedInt32Array) -> bool:
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
func in_packet_history(info: Array, history_range: int, only_use_server_packets: bool = false) -> bool:
	history_range = history_range if history_range < Packet.history.size() else Packet.history.size()
	
	for i: int in history_range:
		var object: Array = Packet.history[-(i + 1)]
		var peer_id: int = object[0]
		var stored_info: Array = object[3]
		
		if stored_info == info and (not only_use_server_packets || peer_id == 1):
			return true
	
	return false
#endregion


#region Private Functions
#region Packet Specific Anticheat
# Attack
func _run_attack_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	attack_mode: StringName,
	
	attacker_location: StringName,
	attacker_index: int,
	
	target_location: StringName,
	target_index: int,
	
	attacker_player_id: int,
	target_player_id: int,
) -> bool:
	# The info needs to be correct.
	if not info_check([
		attack_mode,
		attacker_location,
		attacker_index,
		target_location,
		target_index,
		attacker_player_id,
		target_player_id,
	], [
		TYPE_STRING_NAME,
		TYPE_STRING_NAME,
		TYPE_INT,
		TYPE_STRING_NAME,
		TYPE_INT,
		TYPE_INT,
		TYPE_INT,
	]):
		feedback("Invalid attack info.", sender_peer_id)
		return false
	
	var attacker_card: Card = Card.get_from_index(actor_player, attacker_location, attacker_index)
	var target_card: Card = Card.get_from_index(actor_player.opponent, target_location, target_index)
	
	var attacker_player: Player = Player.get_from_id(attacker_player_id)
	var target_player: Player = Player.get_from_id(target_player_id)
	
	# The attack mode needs to be valid.
	if check(not Packet.attack_modes.has(attack_mode), 1):
		feedback("That attack mode does not exist.", sender_peer_id)
		return false
	
	# The player whose turn it is should be the same player as the one who sent the packet.
	if check(sender_player != Game.current_player, 2):
		feedback("It is not this player's turn.", sender_peer_id)
		return false
	
	# The player who attacks should be the same player as the one who sent the packet.
	if check(sender_player != actor_player, 2):
		feedback("You are not authorized to attack for your opponent.", sender_peer_id)
		return false
	
	# Test the attacker card
	if attack_mode == &"Card Vs Card" or attack_mode == &"Card Vs Player":
		# The attacking card needs to exist.
		if check_card(actor_player, attacker_location, attacker_index, sender_peer_id):
			feedback("The attacking card was not found.", sender_peer_id)
			return false
		
		# The attacking card needs to be owned by the actor.
		if check(attacker_card.player != actor_player, 2):
			feedback("You don't own the attacking card.", sender_peer_id)
			return false
		
		# The attacking card cannot have attacked this turn.
		if check(attacker_card.has_attacked_this_turn, 2):
			feedback("The attacker has already attacked this turn.", sender_peer_id)
			return false
		
		# The attacking card cannot be exhausted.
		if check(attacker_card.exhausted, 2):
			feedback("The attacker is exhausted.", sender_peer_id)
			return false
	
	# Test the target card
	if attack_mode == &"Card Vs Card" or attack_mode == &"Player Vs Card":
		# The target card needs to exist.
		if check_card(actor_player.opponent, target_location, target_index, sender_peer_id):
			feedback("The target card was not found.", sender_peer_id)
			return false
		
		# The target card needs to be owned by the actor's opponent.
		if check(target_card.player != actor_player.opponent, 2):
			feedback("You own the target card.", sender_peer_id)
			return false
	
	# TODO: Implement this when player attacking is added.
	if attack_mode == &"Player Vs Card" or attack_mode == &"Player Vs Player":
		return false
	
	return true


# Create Card
func _run_create_card_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	id: int,
	location: StringName,
	location_index: int,
) -> bool:
	# The info needs to be correct.
	if not info_check([id, location, location_index], [TYPE_INT, TYPE_STRING_NAME, TYPE_INT]):
		feedback("Invalid create card info.", sender_peer_id)
		return false
	
	# Id needs to be valid.
	if check(Card.create_from_id(id, Game.player) == null, 1):
		feedback("Invalid id.", sender_peer_id)
		return false
	
	# Only the server can do this.
	if check(true, 2):
		feedback("Only the server can do this.", sender_peer_id)
		return false
	
	if location == &"Hand":
		# The player needs to have enough space in their hand.
		if check(actor_player.hand.size() >= Settings.server.max_hand_size, 1):
			feedback("You do not have enough space in your hand.", sender_peer_id)
			return false
	elif location == &"Board":
		# The player needs to have enough space on their board.
		if check(actor_player.board.size() >= Settings.server.max_board_space, 1):
			feedback("You do not have enough space on your board.", sender_peer_id)
			return false
	
	return true


# Draw Cards
func _run_draw_cards_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	amount: int,
) -> bool:
	# The info needs to be correct.
	if not info_check([amount], [TYPE_INT]):
		feedback("Invalid draw cards info.", sender_peer_id)
		return false
	
	# Only the server can do this.
	if check(true, 2):
		feedback("Only the server can do this.", sender_peer_id)
		return false
	
	return true


# End Turn
func _run_end_turn_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player
) -> bool:
	# The info needs to be correct.
	if not info_check([], []):
		feedback("Invalid end turn info.", sender_peer_id)
		return false
	
	# The player whose turn it is should be the same player as the one who sent the packet.
	if check(sender_player != Game.current_player, 2):
		feedback("It is not your turn.", sender_peer_id)
		return false
	
	# The player who ends the turn should be the same player as the one who sent the packet.
	if check(sender_player != actor_player, 2):
		feedback("You are not authorized to end your opponent's turn.", sender_peer_id)
		return false
	
	return true


# Play
func _run_play_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	location: StringName,
	location_index: int,
	board_index: int,
	position: Vector3i,
) -> bool:
	# The info needs to be correct.
	if not info_check([
		location,
		location_index,
		board_index,
		position,
	], [
		TYPE_STRING_NAME,
		TYPE_INT,
		TYPE_INT,
		TYPE_VECTOR3I,
	]):
		feedback("Invalid play info.", sender_peer_id)
		return false
	
	var card: Card = Card.get_from_index(actor_player, location, location_index)
	
	# The card should exist.
	if check_card(actor_player, location, location_index, sender_peer_id):
		return false
	
	# The player should afford the card.
	if check(actor_player.mana < card.cost, 1):
		feedback("You can not afford this card.", sender_peer_id)
		return false
	
	# It should be the player's turn.
	if check(actor_player != Game.current_player, 1):
		feedback("It is not your turn.", sender_peer_id)
		return false
	
	# The player who play the card should be the same player as the one who sent the packet.
	if check(sender_player != actor_player, 2):
		feedback("You are not authorized to play a card on behalf of your opponent.", sender_peer_id)
		return false
	
	# The card should be in the player's hand.
	if check(card.location != &"Hand", 3):
		feedback("That card is not in your hand.", sender_peer_id)
		return false
	
	return true


# Reveal
func _run_reveal_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	location: StringName,
	index: int,
) -> bool:
	# The info needs to be correct.
	if not info_check([location, index], [TYPE_STRING_NAME, TYPE_INT]):
		feedback("Invalid reveal info.", sender_peer_id)
		return false
	
	# The card should exist.
	if check_card(actor_player, location, index, sender_peer_id):
		return false
	
	# The player whose card gets revealed should be the same player as the one who sent the packet
	if check(sender_player != actor_player, 2):
		feedback("You are not authorized to reveal a card on behalf of your opponent.", sender_peer_id)
		return false
	
	return true


# Set Drag To Play
func _run_set_drag_to_play_target_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	target_mode: StringName,
	
	location: StringName,
	location_index: int,
	
	target_alignment: int,
	target_location: StringName,
	target_index: int,
) -> bool:
	# The info needs to be correct.
	if not info_check([
		target_mode,
	
		location,
		location_index,
		
		target_alignment,
		target_location,
		target_index,
	], [
		TYPE_STRING_NAME,
		TYPE_STRING_NAME,
		TYPE_INT,
		TYPE_INT,
		TYPE_STRING_NAME,
		TYPE_INT,
	]):
		feedback("Invalid set drag to play info.", sender_peer_id)
		return false
	
	var card: Card = Card.get_from_index(actor_player, location, location_index)
	var target_player: Player = Player.get_from_id(target_alignment)
	
	# The card should exist.
	if check_card(actor_player, location, location_index, sender_peer_id):
		return false
	
	# The player who who owns the card should be the same player as the one who sent the packet.
	if check(sender_player != actor_player, 2):
		feedback("You are not authorized to summon a card on behalf of your opponent.", sender_peer_id)
		return false
	
	if target_mode == &"Card":
		var target_card: Card = Card.get_from_index(target_player, target_location, target_index)
		
		# The card should exist.
		if check_card(target_player, location, location_index, sender_peer_id):
			return false
	else:
		if check(not target_player, 1):
			feedback("The specified player does not exist: %d." % target_alignment, sender_peer_id)
			return false
	
	return true


# Summon
func _run_summon_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	location: StringName,
	location_index: int,
	board_index: int,
) -> bool:
	# The info needs to be correct.
	if not info_check([location, location_index, board_index], [TYPE_STRING_NAME, TYPE_INT, TYPE_INT]):
		feedback("Invalid summon info.", sender_peer_id)
		return false
	
	var card: Card = Card.get_from_index(actor_player, location, location_index)
	
	# The card should exist.
	if check_card(actor_player, location, location_index, sender_peer_id):
		return false
		
	# The player should have enough space on their board.
	if check(actor_player.board.size() >= Settings.server.max_board_space, 1):
		feedback("You do not have enough space on your board.", sender_peer_id)
		return false
		
	# The player who summons the card should be the same player as the one who sent the packet.
	if check(sender_player != actor_player, 2):
		feedback("You are not authorized to summon a card on behalf of your opponent.", sender_peer_id)
		return false
	
	# Only the server can do this.
	if check(true, 2):
		feedback("Only the server can do this.", sender_peer_id)
		return false
	
	# The card should be in the player's hand.
	if check(card.location != &"Hand", 3):
		feedback("That card is not in your hand.", sender_peer_id)
		return false
	
	# Check if the card is queued to be summoned.
	if check(in_packet_history([location, location_index, board_index], 2, true), 3):
		feedback("That card does not have sufficent reason to be summoned.", sender_peer_id)
		return false
	
	return true


# Trigger Ability
func _run_trigger_ability_packet(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	location: StringName,
	location_index: int,
	ability: StringName,
) -> bool:
	# The info needs to be correct.
	if not info_check([location, location_index, ability], [TYPE_STRING_NAME, TYPE_INT, TYPE_STRING_NAME]):
		feedback("Invalid trigger ability info.", sender_peer_id)
		return false
	
	var card: Card = Card.get_from_index(actor_player, location, location_index)
	
	# The card should exist.
	if check_card(actor_player, location, location_index, sender_peer_id):
		return false
	
	# The ability should exist.
	if check(not ability in Card.all_abilities, 1):
		feedback("The specified ability (%s) does not exist." % ability, sender_peer_id)
		return false
	
	# The ability should exist on that card.
	if check(not card.abilities.has(ability), 1):
		feedback("The specified card does not have that ability (%s)." % ability, sender_peer_id)
		return false
	
	# The player who sent the packet should own the card.
	if check(sender_player != actor_player, 2):
		feedback("You are not authorized to trigger a card's ability on behalf of your opponent.", sender_peer_id)
		return false
	
	# Check if the card has already been triggered.
	if check(in_packet_history([location, location_index, ability], 3, true), 3):
		feedback("That card does not have sufficent reason to for its ability to be triggered.", sender_peer_id)
		return false
	
	return true
#endregion
#endregion
