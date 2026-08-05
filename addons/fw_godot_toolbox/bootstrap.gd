@tool

#@icon("res://addons/fw_godot_toolbox/icon.svg")

extends EditorPlugin

const PLUGIN_NAME = "fw_godot_toolbox"

const sub_plugins = []

func _enable_plugin() -> void:
	for plugin in sub_plugins:
		EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/" + plugin, true)

	add_autoload_singleton("Log", "res://addons/fw_godot_toolbox/scripts/core/fw_logger.gd")

func _disable_plugin() -> void:
	for plugin in sub_plugins:
		EditorInterface.set_plugin_enabled(PLUGIN_NAME + "/" + plugin, false)
	
	remove_autoload_singleton("Log")
