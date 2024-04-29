extends Module


#region Public Variables
var types: Array[Dictionary] = []
#endregion


#region Module Functions
func _name() -> StringName:
	return &"Type"


func _dependencies() -> Array[StringName]:
	return []


func _load() -> void:
	register_hooks(handler)


func _unload() -> void:
	pass
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ANTICHEAT:
		return anticheat_hook.callv(info)
	elif what == Modules.Hook.CARD_PLAY_CHECK:
		return card_play_check_hook.callv(info)
	
	return true


func register_type(type: StringName, summonable: bool) -> void:
	types.append({"name": type, "summonable": summonable})


func unregister_type(type: StringName) -> void:
	types.erase(type)


func is_summonable(card: Card) -> bool:
	return card.modules.has("types") and card.modules.types in types.filter(func(obj: Dictionary) -> bool: return obj["summonable"])


func is_card_type(card: Card, type: StringName) -> bool:
	# For some reason, it is possible for modules to pass null into this function.
	if not card:
		return false
	
	return card.modules.has("types") and card.modules.types.has(type)


func play_anticheat(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	card_uuid: int,
	board_index: int,
	position: Vector3i,
) -> bool:
	var card: Card = Card.get_from_uuid(card_uuid)
		
	# The player should have enough space on their board.
	if Anticheat.check(actor_player.board.size() >= Settings.server.max_board_space and is_summonable(card), 1):
		Anticheat.feedback("You do not have enough space on the board.", sender_peer_id)
		return false
	
	return true


func summon_anticheat(
	sender_peer_id: int,
	sender_player: Player,
	actor_player: Player,
	
	card_uuid: int,
	board_index: int,
) -> bool:
	var card: Card = Card.get_from_uuid(card_uuid)
	
	# The card should be summonable
	if Anticheat.check(not is_summonable(card), 2):
		Anticheat.feedback("A card with these types (%s) cannot be summoned." % ", ".join(card.modules.types), sender_peer_id)
		return false
	
	return true


#region Hooks
func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	if packet_type == &"Play":
		return play_anticheat.bindv(info).call(sender_peer_id, sender_player, actor_player)
	elif packet_type == &"Summon":
		return summon_anticheat.bindv(info).call(sender_peer_id, sender_player, actor_player)
	
	return true


func card_play_check_hook(player: Player, card: Card, board_index: int, send_packet: bool) -> bool:
	if player.board.size() >= Settings.server.max_board_space and is_summonable(card):
		Game.feedback("You do not have enough space on the board.", Game.FeedbackType.ERROR)
		return false
	
	return true
#endregion
#endregion

