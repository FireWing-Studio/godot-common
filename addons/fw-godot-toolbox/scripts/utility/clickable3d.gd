@tool

class_name Clickable3D
extends Node

@export var target: CollisionObject3D

@export var enabled := true

signal clicked()

func _ready() -> void:
	target.input_event.connect(_on_input_event)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if not enabled:
		return

	if event is InputEventMouseButton and event.is_pressed():
		clicked.emit()
		event.accepted = true
