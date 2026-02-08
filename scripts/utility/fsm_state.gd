
class_name FSMState
extends Node

var actor: Node

signal finished(next_state_name: StringName, data: Dictionary)


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	set_process_input(false)


func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func enter(previous_state_name: StringName, data: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass
