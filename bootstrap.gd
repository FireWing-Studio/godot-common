@tool

@icon("res://addons/godot_common/icon.svg")

extends EditorPlugin

const PLUGIN_NAME = "godot_common"

const sub_plugins = []

func _enable_plugin() -> void:
	for plugin in sub_plugins:
		EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/" + plugin, true)

func _disable_plugin() -> void:
	for plugin in sub_plugins:
		EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/" + plugin, false)
