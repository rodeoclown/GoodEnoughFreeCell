extends Node

const SELECT_SHADER_MATERIAL = preload("res://Card/card_select_material.tres")

var selected_card: Card:
	set(value):
		if (selected_card):
			selected_card.sprite.material = null
		
		if (value):
			value.sprite.material = SELECT_SHADER_MATERIAL
			
		selected_card = value
