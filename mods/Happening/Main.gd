extends Node

const BannerScript = preload("res://mods/Happening/Banner.gd")
const Selection = preload("res://mods/Happening/Selection.gd")

var _lib
var _hook_ids: Array[int] = []
var _banner
var _pending_target := ""
var _pending_source: WeakRef
var _arrival_target := ""
var _visits: Dictionary = {}
var _btr_timers: Dictionary = {}


func _ready() -> void:
	if not Engine.has_meta("RTVModLib"):
		push_error("Happening: Metro is required")
		return
	_lib = Engine.get_meta("RTVModLib")
	var hooks := {
		"transition-interact-pre": _on_transition,
		"loader-loadscene-pre": _on_load_scene,
		"eventsystem-getavailableevents-post": _on_available,
		"eventsystem-activateweeklyevent": _on_weekly,
		"eventsystem-activatedynamicevent": _on_dynamic,
		"eventsystem-fighterjet": _on_fighter,
		"event-initialize": _on_event_row,
	}
	for hook_name in hooks:
		var hook_id: int = _lib.hook(hook_name, hooks[hook_name])
		if hook_id == -1:
			_release_hooks()
			push_error("Happening: hook conflict at " + hook_name + "; changes disabled")
			return
		_hook_ids.append(hook_id)
	_banner = BannerScript.new()
	add_child(_banner)


func _exit_tree() -> void:
	_release_hooks()
	_visits.clear()
	_cancel_btr_timers()


func _release_hooks() -> void:
	if is_instance_valid(_lib):
		for hook_id in _hook_ids:
			_lib.unhook(hook_id)
	_hook_ids.clear()


func _on_transition() -> void:
	_pending_target = ""
	_pending_source = null
	var transition = _lib._caller
	if not is_instance_valid(transition):
		return
	if transition.gameData.isDead or transition.locked or transition.tutorialExit or not transition.shelterExit:
		return
	_pending_target = transition.nextMap
	_pending_source = weakref(transition)


func _on_load_scene(destination: String) -> void:
	_arrival_target = ""
	_visits.clear()
	_cancel_btr_timers()
	var source = _pending_source.get_ref() if _pending_source != null else null
	if destination == _pending_target and is_instance_valid(source):
		if not source.gameData.isDead and not source.locked and source.shelterExit and not source.tutorialExit:
			_arrival_target = destination
	_pending_target = ""
	_pending_source = null
	if is_instance_valid(_banner):
		_banner.clear()


func _on_available() -> void:
	var system = _lib._caller
	if not is_instance_valid(system) or not is_instance_valid(system.map):
		return
	if _arrival_target.is_empty() or system.map.mapName != _arrival_target:
		return
	_arrival_target = ""
	var visit_id: int = system.get_instance_id()
	if _visits.has(visit_id):
		return
	var candidates: Array = Selection.candidates(system)
	if candidates.is_empty():
		push_error("Happening: no usable event on " + system.map.mapName)
		return
	_visits[visit_id] = {
		"system": weakref(system),
		"map": weakref(system.map),
		"candidates": candidates,
		"stock_dynamic": system.dynamicEvents.duplicate(),
		"stock_weekly": not system.weeklyEvents.is_empty(),
	}
	system.tree_exiting.connect(_end_visit.bind(visit_id), CONNECT_ONE_SHOT)
	_schedule_visit.call_deferred(visit_id)
	_schedule_btr.call_deferred(visit_id)


func _on_weekly() -> void:
	if _is_forced(_lib._caller):
		_lib.skip_super()


func _on_dynamic() -> void:
	if _is_forced(_lib._caller):
		_lib.skip_super()


func _on_fighter() -> void:
	_lib.skip_super()


func _on_event_row(event_data, _interface) -> void:
	if event_data.function == "FighterJet":
		_lib.skip_super()
		var row = _lib._caller
		row.hide()
		row.queue_free()


func _is_forced(system) -> bool:
	return is_instance_valid(system) and _visits.has(system.get_instance_id())


func _end_visit(visit_id: int) -> void:
	_visits.erase(visit_id)
	_cancel_btr_timer(visit_id)


func _cancel_btr_timers() -> void:
	for visit_id in _btr_timers.keys():
		_cancel_btr_timer(visit_id)


func _cancel_btr_timer(visit_id: int) -> void:
	if not _btr_timers.has(visit_id):
		return
	var timer: Timer = _btr_timers[visit_id]
	_btr_timers.erase(visit_id)
	timer.stop()
	timer.timeout.emit()
	if is_instance_valid(timer) and not timer.is_queued_for_deletion():
		timer.queue_free()


func _system_for(visit_id: int):
	if not _visits.has(visit_id):
		return null
	var visit: Dictionary = _visits[visit_id]
	var system = visit.system.get_ref()
	var map = visit.map.get_ref()
	if not is_instance_valid(system) or not is_instance_valid(map) or not system.is_inside_tree() or not map.is_inside_tree():
		return null
	if system.is_queued_for_deletion() or map.is_queued_for_deletion():
		return null
	if get_tree().current_scene != map:
		return null
	return system


func _schedule_visit(visit_id: int) -> void:
	var system = _system_for(visit_id)
	if system == null:
		return
	var remaining: Array = _visits[visit_id].candidates.duplicate()
	remaining.shuffle()
	for event in remaining:
		system = _system_for(visit_id)
		if system == null:
			return
		if not Selection.usable(system, event.function):
			continue
		var before: int = Selection.spawn_count(system, event.function)
		system.call(event.function)
		if event.function == "Gathering":
			# The vanilla coroutine is owned by the scene; observe it without retaining its state.
			var elapsed := 0.0
			while elapsed < 5.5:
				await get_tree().process_frame
				system = _system_for(visit_id)
				if system == null:
					return
				if Selection.spawn_count(system, event.function) > before:
					break
				if not get_tree().paused:
					elapsed += get_process_delta_time()
		system = _system_for(visit_id)
		if system == null:
			return
		if Selection.spawn_count(system, event.function) > before:
			var event_name: String = Selection.LABELS[event.function]
			_banner.announce(system.map.mapName, event_name, system.map)
			print("Happening: " + system.map.mapName + " | " + event_name)
			return
		push_warning("Happening: " + event.name + " did not spawn; trying another event")
	push_error("Happening: every eligible event failed to spawn")


func _schedule_btr(visit_id: int) -> void:
	if not _visits.has(visit_id):
		return
	var visit: Dictionary = _visits[visit_id]
	var stock: Array = visit.stock_dynamic
	if visit.stock_weekly or stock.is_empty():
		return
	# Keep the original selection pool, including the removed jet's probability slot.
	var event = stock.pick_random()
	if event.function != "BTR":
		return
	if event.possibility < randi_range(0, 100):
		return
	var system = _system_for(visit_id)
	if system == null or (event.night and system.gameData.TOD != 4):
		return
	if not event.instant:
		var timer := Timer.new()
		timer.one_shot = true
		timer.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(timer)
		_btr_timers[visit_id] = timer
		timer.start(maxf(float(randi_range(0, 300)), 0.001))
		await timer.timeout
		_btr_timers.erase(visit_id)
		timer.queue_free()
		system = _system_for(visit_id)
	if system != null and Selection.usable(system, "BTR"):
		system.call("BTR")
