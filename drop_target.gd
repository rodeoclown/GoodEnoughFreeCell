@abstract class_name DropTarget extends Control

@abstract func drag_start(at_position: Vector2) -> Variant
@abstract func can_drop(at_position:Vector2, data: Variant) -> bool
@abstract func on_drop(at_position: Vector2, data: Variant) -> void
@abstract func child_position() -> Vector2
@abstract func update_sprite() -> void

var modulate_colour: Color
var is_mouseover: bool

func _ready() -> void:
	update_sprite()
	set_drag_forwarding(drag_start, can_drop, on_drop)

var parent: DropTarget = null
var next_card: Card = null
var last_card: Card = null

func has_children() -> bool:
	return next_card != null


func hover() -> void:
	if GameManager.title_visible: return
	self.is_mouseover = true
	self.modulate = modulate_colour

func end_hover() -> void:
	if GameManager.title_visible: return
	self.is_mouseover = false
	self.modulate = Color(1,1,1,1)
