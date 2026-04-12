@abstract class_name DropTarget extends Control

@abstract func drag_start(at_position: Vector2) -> Variant
@abstract func can_drop(at_position:Vector2, data: Variant) -> bool
@abstract func on_drop(at_position: Vector2, data: Variant) -> void
@abstract func update_sprite() -> void

func _ready() -> void:
	update_sprite()
	set_drag_forwarding(drag_start, can_drop, on_drop)
