@tool
extends EditorPlugin

var dock

func _enter_tree():
        # Load the dock scene and instance it
        dock = preload("res://addons/colex/colex_ui.tscn").instantiate()
        
        # Add the loaded scene to the docks
        add_control_to_dock(DOCK_SLOT_LEFT_BR, dock)
        print("Collision Data Exporter Plugin: Enabled")

func _exit_tree():
        # Clean-up of the plugin
        if dock:
                remove_control_from_docks(dock)
                dock.queue_free()
        print("Collision Data Exporter Plugin: Disabled")
