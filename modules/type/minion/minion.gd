extends Module


#region Module Functions
func _name() -> StringName:
	return &"Minion"


func _dependencies() -> Array[StringName]:
	return [
		&"Type",
		&"Attack",
		&"Health",
	]


func _load() -> void:
	register_hooks(handler)
		
	TypeModule.register_type(&"Minion", true)
	AttackModule.register(_name())
	HealthModule.register(_name())


func _unload() -> void:
	TypeModule.unregister_type(&"Minion")
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ACCEPT_PACKET:
		return await accept_packet_hook.callv(info)
	
	return true


func is_minion(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Minion")


func accept_play_packet(
	player: Player,
	sender_peer_id: int,
	
	location: StringName,
	location_index: int,
	board_index: int,
	position: Vector3i,
) -> bool:
	var card: Card = Card.get_from_index(player, location, location_index)
	
	if not is_minion(card):
		return true
	
	if card.abilities.has(&"Battlecry"):
		card.trigger_ability(&"Battlecry", [], false)
		await card._wait_for_ability(&"Battlecry")
		
		if card.refunded:
			return false
	
	# Summon after ability for refunding.
	# This is gross since the card is summoned after triggering the ability.
	# This is so that the refunding logic can happen before the card is summoned,
	# since a card being summoned might trigger passives, so it is an irreversible action.
	# 
	# This might be confusing to card creators if they don't know the reasoning behind it,
	# since they need to account for this.
	card.summon(board_index, false)
	return true


#region Hooks
func accept_packet_hook(packet_type: StringName, player: Player, sender_peer_id: int, info: Array) -> bool:
	if packet_type == &"Play":
		return accept_play_packet.bindv(info).call(player, sender_peer_id)
	
	return true
#endregion
#endregion
