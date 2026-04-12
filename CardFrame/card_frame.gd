class_name CardFrame extends DropTarget

const scene: PackedScene = preload("res://CardFrame/card_frame.tscn")
const width = 61
const height = 83

enum FrameType {
	FreeCell,
	Hearts,
	Spades,
	Diamonds,
	Clubs,
	Cascade,
}

func init_drag() -> void:
	set_drag_forwarding(Callable(), can_drop, on_drop)

@export var frameType: FrameType:
	set(value):
		frameType = value
		if (sprite): update_sprite()

@onready var sprite = %AnimatedSprite2D
func update_sprite():
	sprite.frame = frameType

func drag_start(_v: Vector2) -> Variant:
	return null

func can_drop(_at_position: Vector2, _data: Variant) -> bool:
	#prints("can drop? -- CARD FRAME %", FrameType.find_key(frameType), at_position, data.suit, data.rank)
	return false

func on_drop(_at_position: Vector2, _data: Variant) -> void:
	return

static func newCardFrame(type: FrameType) -> CardFrame:
	var frame = scene.instantiate()
	frame.frameType = type

	return frame
