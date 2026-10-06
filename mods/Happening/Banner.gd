extends CanvasLayer

const FADE_IN := 0.4
const HOLD := 4.5
const FADE_OUT := 0.8

var fade_in_seconds := FADE_IN
var hold_seconds := HOLD
var fade_out_seconds := FADE_OUT
var _panel: Control
var _map_label: Label
var _event_label: Label
var _tween: Tween
var _scene: Node


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	get_viewport().size_changed.connect(_resize)
	_resize()


func announce(map_name: String, event_name: String, scene: Node) -> void:
	clear()
	if not is_instance_valid(scene) or not scene.is_inside_tree():
		return
	_build()
	_scene = scene
	_scene.tree_exiting.connect(clear, CONNECT_ONE_SHOT)
	_map_label.text = map_name.to_upper()
	_event_label.text = event_name
	_panel.visible = true
	_panel.modulate.a = 0.0
	_resize()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_panel, "modulate:a", 1.0, maxf(fade_in_seconds, 0.0))
	_tween.tween_interval(maxf(hold_seconds, 0.0))
	_tween.tween_property(_panel, "modulate:a", 0.0, maxf(fade_out_seconds, 0.0))
	_tween.tween_callback(clear)


func clear() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if is_instance_valid(_scene) and _scene.tree_exiting.is_connected(clear):
		_scene.tree_exiting.disconnect(clear)
	_scene = null
	if is_instance_valid(_panel):
		_panel.hide()
		_panel.modulate.a = 0.0


func _exit_tree() -> void:
	clear()
	if get_viewport().size_changed.is_connected(_resize):
		get_viewport().size_changed.disconnect(_resize)


func _build() -> void:
	if is_instance_valid(_panel):
		return
	_panel = Control.new()
	_panel.name = "Announcement"
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.hide()
	add_child(_panel)
	var stack := VBoxContainer.new()
	stack.name = "Titles"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	stack.anchor_left = 0.05
	stack.anchor_right = 0.95
	stack.anchor_top = 0.17
	stack.anchor_bottom = 0.17
	stack.add_theme_constant_override("separation", 8)
	_panel.add_child(stack)
	_map_label = _label("Map", Color(0.96, 0.96, 0.92))
	_event_label = _label("Event", Color(1.0, 0.81, 0.43))
	stack.add_child(_map_label)
	stack.add_child(_event_label)


func _label(label_name: String, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	return label


func _resize() -> void:
	if not is_instance_valid(_map_label):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var scale_factor := clampf(minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0), 0.55, 1.8)
	_map_label.add_theme_font_size_override("font_size", roundi(64.0 * scale_factor))
	_event_label.add_theme_font_size_override("font_size", roundi(42.0 * scale_factor))
