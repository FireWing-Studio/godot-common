@tool

#@icon("res://addons/fw_godot_toolbox/icon.svg")

extends EditorPlugin

const PLUGIN_NAME = "fw_godot_toolbox"

const sub_plugins = []

func _enable_plugin() -> void:
	for plugin in sub_plugins:
		EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/" + plugin, true)

func _disable_plugin() -> void:
	for plugin in sub_plugins:
		EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/" + plugin, false)
