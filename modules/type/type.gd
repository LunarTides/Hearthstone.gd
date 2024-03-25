extends Node


#region Public Variables
var types: Array[Dictionary] = []
#endregion


#region Internal Functions
func _ready() -> void:
	Modules.register(&"Type", [], func() -> void:
		# Load module.
		Modules.register_hooks(&"Type", self.handler)
	, func() -> void:
		# Unload module. No need to unregister hooks.
		pass
	)
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
	return card.modules.has("types") and card.modules.types.has(type)



#region Hooks
func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	if packet_type == &"Summon":
		var location: StringName = info[0]
		var location_index: int = info[1]
		var board_index: int = info[2]
		
		var card: Card = Card.get_from_index(sender_player, location, location_index)
		
		# The card should be summonable
		if Anticheat.check(not is_summonable(card), 2):
			Anticheat.feedback("A card with these types (%s) cannot be summoned." % ", ".join(card.modules.types), sender_peer_id)
			return false
	elif packet_type == &"Play":
		var location: StringName = info[0]
		var location_index: int = info[1]
		var board_index: int = info[2]
		var position: Vector3i = info[3]
		
		var card: Card = Card.get_from_index(sender_player, location, location_index)
		
		# The player should have enough space on their board.
		if Anticheat.check(actor_player.board.size() >= Settings.server.max_board_space and is_summonable(card), 1):
			Anticheat.feedback("You do not have enough space on the board.", sender_peer_id)
			return false
	
	return true


func card_play_check_hook(player: Player, card: Card, board_index: int, send_packet: bool) -> bool:
	if player.board.size() >= Settings.server.max_board_space and is_summonable(card):
		Game.feedback("You do not have enough space on the board.", Game.FeedbackType.ERROR)
		return false
	
	return true
#endregion
#endregion

