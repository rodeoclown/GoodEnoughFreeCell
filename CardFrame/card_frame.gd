class_name CardFrame extends DropTarget

const scene: PackedScene = preload("res://CardFrame/card_frame.tscn")
const width = 61
const height = 83

enum FrameType {
	FreeCell,
	Hearts_Foundation,
	Spades_Foundation,
	Diamonds_Foundation,
	Clubs_Foundation,
	Cascade,
}

signal after_drop(frame: CardFrame)

@export var frameType: FrameType:
	set(value):
		frameType = value
		if (sprite): update_sprite()

@export var count: int

@onready var sprite = %AnimatedSprite2D
func update_sprite():
	sprite.frame = frameType

func _init() -> void:
	modulate_colour = Color(0.5, 0.5, 0.5)
	
	
func _to_string() -> String:
	return "%s" % [FrameType.find_key(frameType)]


func drag_start(_v: Vector2) -> Variant:
	return null


func can_drop(_at_position: Vector2, data: Variant) -> bool:
	var dragged = data as Card
	if dragged == null: return false
	
	var can_accept = false
	match frameType:
		FrameType.FreeCell:
			# If the cell and the dragged card both have no children, then it can accept any card
			can_accept = !has_children() and !dragged.has_children()
		
		FrameType.Cascade:
			if !has_children():
				# If the cascade is empty, then it can accept any card
				can_accept = true
			else:
				# The cascade can accept any card that is one lower in rank, and the opposite colour
				var prev_rank = (last_card.rank - 1)
				var opposite_color = Card.Colour.Black if (
						last_card.suit == Card.Suit.Hearts or 
						last_card.suit == Card.Suit.Diamonds
					) else Card.Colour.Red
				can_accept = (dragged.rank == prev_rank) and (dragged.colour == opposite_color)

		# Foundations
		_:
			if dragged.has_children():
				# If we are dragging multiple children, then we can't accept it (foundations can only handle one card at a time)
				can_accept = false
			else:
				# If the foundation is of the matching suit, then this can accept the next rank
				var matching_suit = (FrameType.find_key(frameType) as String).begins_with(Card.Suit.find_key(dragged.suit) as String)
				if !matching_suit: 
					can_accept = false;
				else:
					var next_rank = (last_card.rank + 1) if has_children() else Card.ACE
					can_accept = (dragged.rank == next_rank)
				
	# TODO: When using regular rules, prevent dropping multiple cards if there are not enough slots to move each card separately
		
	print("can drop? -- %s -> %s [%s]: %s " % [dragged, self, self.last_card, can_accept])
	return can_accept


func on_drop(_at_position: Vector2, data: Variant) -> void:
	var dragged = data as Card
	if dragged == null: return
	
	var old_root = dragged.root_ancestor
	
	# Remove dragged from previous parent/root
	if dragged.root_ancestor:
		dragged.parent.next_card = null
		dragged.parent.last_card = null
		if !(dragged.parent is CardFrame):
			dragged.root_ancestor.last_card = dragged.parent
	
	# Assign dragged to new parent/root
	if has_children():
		dragged.parent = last_card
		last_card.next_card = dragged
	else:
		dragged.parent = self
		next_card = dragged
	dragged.root_ancestor = self
	reset_cards()
	
	dragged.end_drop()
	if old_root:
		old_root.reset_cards()
		print("Moved %s from: %s [%s] -> %s [%s]." % [dragged, old_root, old_root.last_card, self, self.last_card])
	
	after_drop.emit(self, old_root)


func child_position() -> Vector2:
	return position + Vector2(3, 3)


# Walk down the tree fixing z_index and input priority
# Then walk back up the tree, setting the last_card to the child at the end
func reset_cards() -> void:
	print("\nResetting [%s] - Walking down:" % self)
	var child = next_card
	if !child:
		self.last_card = null
		return
	
	while child:
		var new_z = child.parent.z_index + 1
		child.z_index = new_z
		child.root_ancestor = self
		# Move Control node in the tree so that it is later in the 
		# list and will receive priority for input events
		child.move_to_front()
		self.last_card = child
		print("\t%s [z: %s, parent: %s]" % [child, new_z, child.parent])
		child = child.next_card
		
	child = self.last_card
	while child.parent:
		child = child.parent
		child.last_card = self.last_card

func _gui_input(event: InputEvent) -> void:
	var m_event = event as InputEventMouseButton
	if not m_event or m_event.button_index != MOUSE_BUTTON_LEFT : return
	get_viewport().set_input_as_handled()
	
	if m_event.double_click:
		return
	elif m_event.pressed:
		# Do nothing
		return
	elif not m_event.pressed: #released
		prints("%s: %s released" % [self, m_event.button_index])
		
		# If there is a selected card, try and drop it
		if (SelectionManager.selected_card != null and can_drop(Vector2.ZERO, SelectionManager.selected_card)):
			on_drop(Vector2.ZERO, SelectionManager.selected_card)
			SelectionManager.selected_card = null



static func newCardFrame(type: FrameType, _count: int) -> CardFrame:
	var frame = scene.instantiate() as CardFrame
	frame.frameType = type
	frame.z_index = -1
	
	frame.count = _count

	return frame
