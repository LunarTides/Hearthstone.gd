extends Module


#region Module Functions
func _name() -> StringName:
	return &"Spell"


func _dependencies() -> Array[StringName]:
	return [
		&"Type",
	]


func _load() -> void:
	register_hooks(handler)
	
	# TODO: Use _name()
	TypeModule.register_type(&"Spell", false)


func _unload() -> void:
	TypeModule.unregister_type(&"Spell")
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ACCEPT_PACKET:
		return await accept_packet_hook.callv(info)
	
	return true


func is_spell(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"Spell")


func accept_play_packet(
	player: Player,
	sender_peer_id: int,
	
	location: StringName,
	location_index: int,
	board_index: int,
	position: Vector3i,
) -> bool:
	var card: Card = Card.get_from_index(player, location, location_index)
	
	if not is_spell(card):
		return true
	
	card.trigger_ability(&"Cast", [], false)
	await card._wait_for_ability(&"Cast")
	
	if card.refunded:
		return false
	
	card.location = &"None"
	return true


#region Hooks
func accept_packet_hook(packet_type: StringName, player: Player, sender_peer_id: int, info: Array) -> bool:
	if packet_type == &"Play":
		return await accept_play_packet.bindv(info).call(player, sender_peer_id)
	
	return true
#endregion
#endregion
