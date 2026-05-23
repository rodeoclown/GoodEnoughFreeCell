class_name Table extends Control

@export var cards: Array[Card]
@export var foundations: Array[CardFrame]
@export var freeCells: Array[CardFrame]
@export var cascades: Array[CardFrame]

var initialising = true

func _ready() -> void:
	self.z_index = RenderingServer.CANVAS_ITEM_Z_MIN
	
	## POSITIONING of Game Elements
	var screen_width = get_viewport_rect().size.x
	var _screen_height = get_viewport_rect().size.y

	for i in range(0, 4):
		var cell = CardFrame.newCardFrame(CardFrame.FrameType.FreeCell, i)
		var cardFrameXOffset = ((screen_width / 2) - (4 * CardFrame.width)) / 8
		cell.position = Vector2((2 * cardFrameXOffset) + ((CardFrame.width + cardFrameXOffset) * i), 10)
		freeCells.push_back(cell)
		add_child(cell)
		cell.after_drop.connect(after_drop)

		var foundation = CardFrame.newCardFrame(i + 1, i)
		foundation.position = Vector2((screen_width / 2) + (3 * cardFrameXOffset) + ((CardFrame.width + cardFrameXOffset) * i), 10)
		foundations.push_back(foundation)
		add_child(foundation)
		foundation.after_drop.connect(after_drop)

	for i in range(0, 8):
		var cascade = CardFrame.newCardFrame(CardFrame.FrameType.Cascade, i)
		var cascadeXOffset = (screen_width - (8 * CardFrame.width)) / 11
		cascade.position = Vector2((2 * cascadeXOffset) + ((CardFrame.width + cascadeXOffset) * i), CardFrame.height + 20)
		cascades.push_back(cascade)
		add_child(cascade)
		cascade.after_drop.connect(after_drop)

	for suit in Card.Suit.values():
		for rank in range(Card.ACE, Card.KING+1):
			cards.push_back(Card.newCard(suit, rank, self))

	cards.shuffle()
	
	var z = 0
	for card in cards:
		cascades[z % 8].on_drop(Vector2(), card)
		z += 1
		card.z_index = z
		add_child(card)
	
	initialising = false
	move_cards_to_foundations()


# Right-click is cancel, but we want this to catch everything
func _process(_delta: float) -> void:
	if Input.is_action_just_released("ui_cancel"):
		SelectionManager.selected_card = null
	pass


func after_drop(drop_target: CardFrame, drop_source: CardFrame):
	prints("DROPPED %s from %s" % [drop_target, drop_source])
	
	# Check for win
	if foundations.all(has_king):
		prints("WINNER")
	else:
		prints("NOT A WINNER")
	
	if !initialising:
		#Check if any cards can be moved to a foundation (and move them)
		move_cards_to_foundations()

func has_king(foundation: CardFrame):
	return foundation.last_card && foundation.last_card.rank == Card.KING

func last_card_rank_or_0(f: CardFrame): 
	return f.last_card.rank if f.last_card else 0

func move_cards_to_foundations():
	var min_foundation = foundations.map(last_card_rank_or_0).min()
	
	for target in (freeCells + cascades):
		if (target.last_card && target.last_card.rank <= min_foundation + 2):
			if target.last_card.move_to_best_location(true):
				prints("Can move %s" % target.last_card)
				return
