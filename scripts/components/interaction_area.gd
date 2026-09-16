class_name InteractionArea
extends Area3D

## Reusable focus target for short-range player interactions.

@export_multiline var interaction_hint := ""

signal interaction_requested(area: InteractionArea)


func get_interaction_hint() -> String:
	return interaction_hint


func request_interaction() -> void:
	interaction_requested.emit(self)
