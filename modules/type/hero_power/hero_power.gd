extends Module


#region Signals
## Emits whenever a hero power gets used.
signal used(after: bool, player: Player, sender_peer_id: int)
#endregion


#region Module Functions
func _name() -> StringName:
	return &"HeroPower"


func _dependencies() -> Array[StringName]:
	return [
		&"Type",
	]


func _load() -> void:
	register_hooks(handler)
	register_packet(&"Hero Power")
		
	TypeModule.register_type(&"HeroPower", false)
	ArmorModule.register(_name())
	AttackModule.register(_name())
	HealthModule.register(_name())


func _unload() -> void:
	TypeModule.unregister_type(&"HeroPower")
#endregion


#region Public Functions
func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.ANTICHEAT:
		return anticheat_hook.callv(info)
	elif what == Modules.Hook.ACCEPT_PACKET:
		return await accept_packet_hook.callv(info)
	
	return true


func is_hero_power(card: Card) -> bool:
	return TypeModule.is_card_type(card, &"HeroPower")


func accept_hero_power_packet(player: Player, sender_peer_id: int) -> bool:
	var hero_power: Card = player.hero.hero_power_card
	
	used.emit(false, player, sender_peer_id)
	
	hero_power.refunded = false
	
	hero_power.trigger_ability(&"Hero Power", [], false)
	if hero_power.refunded:
		return false
	
	player.has_used_hero_power_this_turn = true
	player.mana -= hero_power.cost
	
	used.emit(true, player, sender_peer_id)
	return true


func accept_play_packet(
	player: Player,
	sender_peer_id: int,
	
	location: StringName,
	location_index: int,
	board_index: int,
	position: Vector3i,
) -> bool:
	var card: Card = Card.get_from_index(player, location, location_index)
	
	if not is_hero_power(card):
		return true
	
	card.trigger_ability(&"Battlecry", [], false)
	await card._wait_for_ability(&"Battlecry")
	
	if card.refunded:
		return false
	
	card.location = &"Hero Power"
	return true


#region Hooks
# Hero Power
func anticheat_hook(packet_type: StringName, sender_peer_id: int, sender_player: Player, actor_player: Player, info: Array) -> bool:
	if packet_type != &"Hero Power":
		return true
	
	# The info needs to be correct.
	if not Anticheat.info_check(info, []):
		Anticheat.feedback("Invalid hero power info.", sender_peer_id)
		return false
	
	var hero_power: Card = actor_player.hero.hero_power_card
	
	# The player should not have already used the hero power this turn.
	if Anticheat.check(actor_player.has_used_hero_power_this_turn, 1):
		Anticheat.feedback("This player has already used their hero power this turn.", sender_peer_id)
		return false
	
	# The player should afford the hero power.
	if Anticheat.check(actor_player.mana < hero_power.cost, 1):
		Anticheat.feedback("This player cannot afford their hero power.", sender_peer_id)
		return false
	
	# The player who sent the packet should own the card.
	if Anticheat.check(sender_player != actor_player, 2):
		Anticheat.feedback("You are not authorized to trigger the hero power on behalf of your opponent.", sender_peer_id)
		return false
	
	return true


func accept_packet_hook(packet_type: StringName, player: Player, sender_peer_id: int, info: Array) -> bool:
	if packet_type == &"Play":
		return accept_play_packet.bindv(info).call(player, sender_peer_id)
	elif packet_type == &"Hero Power":
		return accept_hero_power_packet.bindv(info).call(player, sender_peer_id)
	
	return true
#endregion
#endregion
