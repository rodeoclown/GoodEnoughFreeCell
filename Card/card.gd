class_name Card extends DropTarget

const scene: PackedScene = preload("res://Card/card.tscn")

const DEFAULT_CARD_Z_INDEX = 10
const SHOW_CARD_Z_INDEX = 50
const DRAGGED_CARD_Z_INDEX = 100

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

enum Colour {
	Red,
	Black,
}

const ACE = 1
const JACK = 11
const QUEEN = 12
const KING = 13

const CARDS_PER_SUIT = 13

@export 
var cardStyle: CardStyle:
	set(value):
		cardStyle = value
		if (sprite): update_sprite()

@export 
var suit: Suit: 
	set(value):
		suit = value

@export_range(ACE, KING) 
var rank: int : # 1 = Ace, 11 = Jack, 12 = Queen, 13 = King
	set(value):
		rank = value

@export 
var colour: Colour:
	get:
		return Colour.Red if (suit == Suit.Hearts or suit == Suit.Diamonds) else Colour.Black
		
@export
var table: Table

var root_ancestor: CardFrame = null

@onready 
var sprite: AnimatedSprite2D = %AnimatedSprite2D

func _init() -> void:
	modulate_colour = Color(1.25, 1.25, 1.25)

func _to_string() -> String:
	return "%s of %s (%s)" % [rank_str(rank), Suit.find_key(suit), Colour.find_key(colour)]

static func rank_str(r: int) -> String:
	match r:
		ACE: return "Ace"
		JACK: return "Jack"
		QUEEN: return "Queen"
		KING: return "King"
	return "%s" % r
		

var t: float = 0
func _process(delta: float) -> void:
	if is_dragging:
		if Input.is_action_pressed("mouse_action"):
			#print("dragging ", position)
			#position = get_global_mouse_position()
			pass
		else:
			cancel_drop()
		return
		
	# Look at what this card is attached to and move to the correct location
	# If on a CardFrame -> move to that exact location
	# If on another card -> move to that card's location, then parentCard.position.y += Y
	# If the direct parent is currently dragging, follow the mouse position + the preview card offset instead
	if parent:
		var move_target = parent.child_position()
		if (parent as Card) && (parent as Card).is_dragging:
			move_target = get_global_mouse_position() + preview_card.child_position() 
		
		if position.is_equal_approx(move_target):
			position = move_target
			t = 0
		else:
			t += delta
			#prints(self, "Moving:", position, "->", move_target)
			#lerp(position, move_target, 1 * delta)
			position = move_target


func _gui_input(event: InputEvent) -> void:
	#print(event)
	var m_event = event as InputEventMouseButton
	if not m_event or (m_event.button_index != MOUSE_BUTTON_LEFT and m_event.button_index != MOUSE_BUTTON_RIGHT): 
		return
		
	get_viewport().set_input_as_handled()
	
	if m_event.double_click:
		# Move this card to the best location it can go (can only double-click the last card)
		if !has_children():
			#prints("%s: %s double_clicked" % [self, m_event.button_index])
			self.move_to_best_location()
	elif m_event.pressed:
		# If right mouse button, bring the card to the front
		if m_event.button_index == MOUSE_BUTTON_RIGHT && !is_dragging:
			z_index = SHOW_CARD_Z_INDEX
		# Otherwise do nothing
		#prints("%s: %s pressed" % [self, m_event.button_index])
		pass
	elif not m_event.pressed: #released
		#prints("%s: %s released" % [self, m_event.button_index])
		if m_event.button_index == MOUSE_BUTTON_RIGHT:
			z_index = DEFAULT_CARD_Z_INDEX
			
		# Unselect if already selected, then return
		if (SelectionManager.selected_card == self):
			SelectionManager.selected_card = null
			return
		
		# If there is already a selected card see if we can drop it or one of its parents where we just clicked
		if SelectionManager.selected_card != null:
			var c = SelectionManager.selected_card
			while c:
				if (self.root_ancestor.can_drop(Vector2.ZERO, c)):
					self.root_ancestor.on_drop(Vector2.ZERO, c)
					SelectionManager.selected_card = null
					return
				# If the parent is one rank higher and opposite colour, then continue walking up the card stack
				var p = c.parent as Card
				if p && p.colour != c.colour && p.rank == c.rank + 1:
					c = p
				else:
					c = null
		
		# Otherwise select this card instead
		SelectionManager.selected_card = self


func update_sprite():
	sprite.animation = CardStyle.keys()[cardStyle]
	sprite.frame = (suit * CARDS_PER_SUIT) + rank

var is_dragging = false
var last_position: Vector2


const use_simple_rules = false
func can_start_drag() -> bool:
	#TODO: Possible Variant -- locked in on foundations
	#if (root_ancestor.frameType == CardFrame.FrameType.Hearts_Foundation ||
		#root_ancestor.frameType == CardFrame.FrameType.Spades_Foundation ||
		#root_ancestor.frameType == CardFrame.FrameType.Diamonds_Foundation ||
		#root_ancestor.frameType == CardFrame.FrameType.Clubs_Foundation):
		## Can't drag off the foundations
		#prints("Can't drag off a foundation")
		#return false
	if use_simple_rules:	
		return true
	
	# When using regular rules, prevent dragging a card if it's direct child is not the next rank down and the opposite colour
	return (!next_card || (next_card.colour != self.colour && next_card.rank == (self.rank-1)))

static var preview_card: Card
func drag_start(at_position: Vector2) -> Variant:
	if !can_start_drag():
		return null
	
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	preview_card = self.duplicate()
	preview_card.z_index = DRAGGED_CARD_Z_INDEX
	preview_card.modulate = Color(1, 1, 1, 1)
	var control = Control.new()
	control.add_child(preview_card)
	preview_card.position = Vector2.ZERO - at_position #This ensures the drag preview is at the expected location
	set_drag_preview(control)
	
	last_position = position
	is_dragging = true
	
	self.modulate.a = 0
	#print("%s of %s (First child: %s, Last child: %s)" % [self.rank, Suit.find_key(self.suit), self.next_card, self.last_card])
	
	# We need to muck around with the z-indexing while dragging to ensure that these child cards are layered correctly
	# and that they go over the top of all other cards
	var c = next_card
	var z = DRAGGED_CARD_Z_INDEX
	while c:
		z += 1
		c.z_index = z
		c = c.next_card
	
	return self


func end_drop() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	self.modulate = Color(1, 1, 1, 1)
	is_dragging = false


func cancel_drop() -> void:
	#print("drop cancelled")
	end_drop()
	position = last_position
	root_ancestor.reset_cards()
	pass

func can_drop(at_position:Vector2, data: Variant) -> bool:
	var dragged = data as Card
	# If this isn't a card, or isn't attached to anything, then we can't drop on it
	if dragged == null or !root_ancestor: return false
	
	# Use the root to determine whether we can drop here or not	
	return root_ancestor.can_drop(at_position, dragged)


func on_drop(at_position: Vector2, data: Variant) -> void:	
	print("drag end -> delegating to root ancestor", at_position, data)
	return root_ancestor.on_drop(at_position, data)


func child_position() -> Vector2:
	if root_ancestor and root_ancestor.frameType in [
		CardFrame.FrameType.Hearts_Foundation, 
		CardFrame.FrameType.Spades_Foundation, 
		CardFrame.FrameType.Diamonds_Foundation, 
		CardFrame.FrameType.Clubs_Foundation,
	]:
		return position
	return position + Vector2(0, 16)

func hover() -> void:
	if !is_dragging:
		super.hover()

func end_hover() -> void:
	if !is_dragging:
		super.end_hover()

func move_to_best_location(only_foundation: bool=false) -> bool:
	# See if there is a valid foundation to send the card to
	for foundation in table.foundations:
		if (foundation.can_drop(Vector2.ZERO, self)):
			foundation.on_drop(Vector2.ZERO, self)
			return true
	
	# If we only want to check foundations, then we are returning false (i.e., not moving anything)
	if (only_foundation):
		return false
	
	# See if there is a cascade to send the card to (starting with the next cascade from the one this is in and moving right)
	var start_i: int = 8
	if (self.root_ancestor.frameType == CardFrame.FrameType.Cascade):
		start_i = self.root_ancestor.count
		
	for i in table.cascades.size():
		var cascade = table.cascades[start_i % 8]
		if (cascade.can_drop(Vector2.ZERO, self)):
			cascade.on_drop(Vector2.ZERO, self)
			return true
		start_i += 1
		
	# Move to a valid free cell (unless already on one)
	if (self.root_ancestor.frameType == CardFrame.FrameType.FreeCell):
		return false
	for cell in table.freeCells:
		if (cell.can_drop(Vector2.ZERO, self)):
			cell.on_drop(Vector2.ZERO, self)
			return true
		
	# Otherwise, do nothing...
	return false


static func newCard(_suit: Suit, _rank: int, _table: Table) -> Card:
	var new_card = scene.instantiate() as Card

	new_card.suit = _suit
	new_card.rank = clampi(_rank, ACE, KING)

	new_card.table = _table
	
	return new_card
