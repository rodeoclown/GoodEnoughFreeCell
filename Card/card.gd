class_name Card extends DropTarget

const scene: PackedScene = preload("res://Card/card.tscn")

enum CardStyle {
	aged,
	red_back,
	blue_back,
	glass_red_back,
	glass_blue_back,
	stone,
}

enum Suit {
	Hearts,
	Spades,
	Diamonds,
	Clubs,
}

const ACE = 1
const JACK = 11
const QUEEN = 12
const KING = 13

const CARDS_PER_SUIT = 13

@export var cardStyle: CardStyle:
	set(value):
		cardStyle = value
		if (sprite): update_sprite()

@export var suit: Suit: 
	set(value):
		suit = value

@export_range(ACE, KING) var rank: int : # 1 = Ace, 11 = Jack, 12 = Queen, 13 = King
	set(value):
		rank = value

@onready var sprite = %AnimatedSprite2D

func _process(_delta: float) -> void:
	# Each _process -> Look at what this card is attached to and move to the correct location
	# If on a CardFrame -> move to that exact location
	# If on another card -> move to that card's location, then parentCard.position.y += Y
	
	if is_dragging:
		if Input.is_action_pressed("mouse_action"):
			#print("dragging ", position, drag_offset)
			#position = get_global_mouse_position()
			pass
		else:
			cancel_drop()

func update_sprite():
	sprite.animation = CardStyle.keys()[cardStyle]
	sprite.frame = (suit * CARDS_PER_SUIT) + rank

var is_dragging = false
var last_position: Vector2

func drag_start(at_position: Vector2) -> Variant:
	last_position = position
	is_dragging = true
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	var preview_card = self.duplicate()
	preview_card.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
	var control = Control.new()
	control.add_child(preview_card)
	preview_card.position = Vector2.ZERO - at_position #This ensures the drag preview is at the expected location
	set_drag_preview(control)
	
	self.modulate.a = 0
	print(self.rank, " ", Suit.find_key(self.suit))
	return self

func end_drop() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.modulate.a = 1
	is_dragging = false

func cancel_drop() -> void:
	print("drop cancelled")
	end_drop()
	position = last_position
	pass

func can_drop(at_position:Vector2, data: Variant) -> bool:
	prints("can drop?", at_position, data.suit, data.rank)
	return true

func on_drop(at_position: Vector2, data: Variant) -> void:
	end_drop()
	print("drag end", at_position, data)
	pass



static func newCard(_suit: Suit, _rank: int) -> Card:
	var new_card = scene.instantiate()

	new_card.suit = _suit
	new_card.rank = clampi(_rank, ACE, KING)

	return new_card
