extends Node

var selected_card: Card:
	set(value):
		if value == null:
			#TODO: Clear the highlight on the selected card
			prints("Unselecting %s" % SelectionManager.selected_card)
			pass
		else:
			#TODO: Set a highlight on the selected card
			prints("Selecting %s" % SelectionManager.selected_card)
			pass
		selected_card = value
