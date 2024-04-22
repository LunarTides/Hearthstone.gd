extends Module


var _layouts: Dictionary

var _layout_tweens: Dictionary
var _should_layouts: Dictionary


#region Module Functions
func _name() -> StringName:
	return &"Layout"


func _dependencies() -> Array[StringName]:
	return [&"Location"]


func _load() -> void:
	register_hooks(handler)


func _unload() -> void:
	pass
#endregion


#region Public Functions
func layout(card: Card, instant: bool = false) -> bool:
	if not card.visible:
		return false
	
	if card.is_hovering or _should_layouts.get(card.get_rid(), true) == false:
		_layout_tweens[card.get_rid()].kill()
		return false
	
	if card.location == &"None":
		return false
	
	if not Settings.client.animations and not instant:
		return await layout(card, true)
	
	if not card.location in _layouts:
		assert(false, "Can't layout the card in this location (%s)." % card.location)
		return false
	
	var method: Callable = _layouts.get(card.location)
	var result: Dictionary = await method.call(card)
	
	var new_position: Vector3 = result.position
	var new_rotation: Vector3 = result.rotation
	var new_scale: Vector3 = result.scale
	
	if instant:
		card.position = new_position
		card.rotation = new_rotation
		card.scale = new_scale
	else:
		if _layout_tweens.has(card.get_rid()):
			_layout_tweens[card.get_rid()].kill()
		
		_layout_tweens[card.get_rid()] = create_tween().set_ease(Tween.EASE_OUT).set_parallel()
		_layout_tweens[card.get_rid()].tween_property(card, "position", new_position, 0.5)
		_layout_tweens[card.get_rid()].tween_property(card, "rotation", new_rotation, 0.5)
		_layout_tweens[card.get_rid()].tween_property(card, "scale", new_scale, 0.5)
	
	card._old_position = new_position
	return true


func register_layout(location: StringName, callback: Callable) -> void:
	_layouts[location] = callback


func unregister_layout(location: StringName) -> void:
	_layouts.erase(location)


## Stabilize a card's layout. This will freeze it's position, rotation, and scale in it's correct place while [param callback] is being called.
func stabilize_layout_while(card: Card, callback: Callable, should_layout: bool = false) -> void:
	if card._hover_tween:
		card._hover_tween.kill()
	
	card.is_hovering = false
	
	if should_layout:
		layout(card, true)
	
	_should_layouts[card.get_rid()] = false
	card._should_hover = false
	
	await callback.call()
	
	_should_layouts[card.get_rid()] = true
	card._should_hover = true


## Lays out all the cards. Only works client side.
func layout_all() -> void:
	for card: Card in Card.get_all():
		layout(card)


## Lays out all the cards for the specified player. Only works client side.
func layout_all_owned_by(player: Player) -> void:
	for card: Card in Card.get_all_owned_by(player):
		layout(card)


func handler(what: Modules.Hook, info: Array) -> bool:
	if what == Modules.Hook.CARD_HOVER_START:
		return card_hover_start_hook.callv(info)
	elif what == Modules.Hook.CARD_HOVER_STOP:
		return card_hover_stop_hook.callv(info)
	elif what == Modules.Hook.CARD_KILL:
		return card_kill_hook.callv(info)
	elif what == Modules.Hook.CARD_MAKE_WAY_START:
		return card_make_way_start_hook.callv(info)
	elif what == Modules.Hook.CARD_MAKE_WAY_STOP:
		return card_make_way_stop_hook.callv(info)
	elif what == Modules.Hook.CARD_PLAY_BEFORE:
		return card_play_before_hook.callv(info)
	elif what == Modules.Hook.CARD_TWEEN_START:
		return card_tween_start_hook.callv(info)
	elif what == Modules.Hook.CARD_UPDATE:
		return update_card_hook.callv(info)
	
	return true


#region Hooks
func card_hover_start_hook(card: Card) -> bool:
	if _layout_tweens.has(card.get_rid()):
		_layout_tweens[card.get_rid()].kill()
	
	return true


func card_hover_stop_hook(card: Card) -> bool:
	layout(card)
	return true


func card_kill_hook(card: Card) -> bool:
	_should_layouts[card.get_rid()] = true
	return true


func card_make_way_start_hook(card: Card, other: Card) -> bool:
	_should_layouts[card.get_rid()] = false
	return true


func card_make_way_stop_hook(card: Card) -> bool:
	_should_layouts[card.get_rid()] = true
	layout(card)
	return true


func card_play_before_hook(card: Card, board_index: int, position: Vector3i) -> bool:
	_should_layouts[card.get_rid()] = true
	return true


func card_tween_start_hook(card: Card, duration: float, new_position: Vector3, new_rotation: Vector3, new_scale: Vector3) -> bool:
	# This code breaks cards on the board. What does it do?
	#_should_layouts[card.get_rid()] = false
	return true


func update_card_hook(card: Card) -> bool:
	# Don't wait since there is no reason to.
	layout(card)
	
	# TODO: Make this better.
	if card.health <= 0 and card.location == &"Board" and not card.is_dying and card.should_die:
		_should_layouts[card.get_rid()] = false
	
	return true
#endregion
#endregion
