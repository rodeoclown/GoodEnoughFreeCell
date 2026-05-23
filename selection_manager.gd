extends Node

const SELECT_SHADER_MATERIAL = preload("res://Card/card_select_material.tres")

var selected_card: Card:
	set(value):
		if (selected_card):
			selected_card.sprite.material = null
		
		if (value && value.can_start_drag()):
			value.sprite.material = SELECT_SHADER_MATERIAL
		else:
			# If this is not a valid card selection, then we clear it
			value = null
			
		selected_card = value
