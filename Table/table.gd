class_name Table extends Control

@export var cards: Array[Card]
@export var foundations: Array[CardFrame]
@export var freeCells: Array[CardFrame]
@export var cascades: Array[CardFrame]

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

		var foundation = CardFrame.newCardFrame(i + 1, i)
		foundation.position = Vector2((screen_width / 2) + (3 * cardFrameXOffset) + ((CardFrame.width + cardFrameXOffset) * i), 10)
		foundations.push_back(foundation)
		add_child(foundation)

	for i in range(0, 8):
		var cascade = CardFrame.newCardFrame(CardFrame.FrameType.Cascade, i)
		var cascadeXOffset = (screen_width - (8 * CardFrame.width)) / 11
		cascade.position = Vector2((2 * cascadeXOffset) + ((CardFrame.width + cascadeXOffset) * i), CardFrame.height + 20)
		cascades.push_back(cascade)
		add_child(cascade)

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


# Right-click is cancel, but we want this to catch everything
func _process(_delta: float) -> void:
	if Input.is_action_just_released("ui_cancel"):
		SelectionManager.selected_card = null
	pass
