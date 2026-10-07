extends RefCounted

const METHODS := ["Police", "Airdrop", "Helicopter", "CrashSite", "Bogeyman", "Driver", "Gathering"]
const LABELS := {
	"Police": "Punisher",
	"Airdrop": "Airdrops",
	"Helicopter": "Attack Helicopters",
	"CrashSite": "Helicopter Crash Sites",
	"Bogeyman": "Bogeyman",
	"Driver": "Driver",
	"Gathering": "Nomad Gatherings",
}


static func candidates(system) -> Array:
	var result: Array = []
	for event in system.events.events:
		if event.function not in METHODS:
			continue
		# Driver runs on any map with usable vehicle paths, not only Highway.
		if event.function != "Driver":
			if not event.map.is_empty() and event.map != system.map.mapName:
				continue
			if not event.zone.is_empty() and event.zone != system.map.mapType:
				continue
		if usable(system, event.function):
			result.append(event)
	return result


static func usable(system, method: String) -> bool:
	if not is_instance_valid(system) or not system.has_method(method):
		return false
	if method in ["Police", "Driver", "BTR"]:
		if not _markers(system.paths):
			return false
		for path in system.paths.get_children():
			if not _markers(path):
				return false
	elif method == "CrashSite":
		return _markers(system.crashes)
	elif method == "Gathering":
		return _markers(system.gatherings) and is_instance_valid(system.AISpawner) and system.AISpawner.has_method("Deactivate")
	elif method == "Bogeyman":
		var ai = system.AISpawner
		if not is_instance_valid(ai) or not ai.has_method("SpawnBoss") or ai.lurks.is_empty():
			return false
		for point in ai.lurks:
			if not is_instance_valid(point) or not point is Node3D or not point.is_inside_tree():
				return false
		return is_instance_valid(ai.BPool) and ai.BPool.has_node("AI_Bogeyman") and is_instance_valid(ai.enemies)
	return true


static func _markers(node) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree() or node.get_child_count() == 0:
		return false
	for child in node.get_children():
		if not child is Node3D:
			return false
	return true


static func spawn_count(system, method: String) -> int:
	if method in ["CrashSite", "Gathering"]:
		var markers = system.crashes if method == "CrashSite" else system.gatherings
		var count := 0
		for marker in markers.get_children():
			count += marker.get_child_count()
		return count
	if method == "Bogeyman":
		return system.AISpawner.enemies.get_child_count()
	return system.get_child_count()
