
# ====================================
# FILE: addons/collision_exporter/collision_exporter_dock.gd
# ====================================
@tool
extends VBoxContainer

var CollisionParser = preload("res://addons/colex/colex_parser.gd")
var CollisionExporter = preload("res://addons/colex/colex_exporter.gd")

var parser: CollisionParser
var exporter: CollisionExporter

# References to UI elements (will be set by the scene)
@onready var export_button: Button = %ExportButton
@onready var parse_button: Button = %ParseButton
@onready var file_path_line_edit: LineEdit = %FilePathLineEdit
@onready var browse_button: Button = %BrowseButton
@onready var status_label: Label = %StatusLabel
@onready var export_options: OptionButton = %ExportOptions

# Current parsed data
var current_scene_data: CollisionParser.SceneCollisionData

# File dialog references
var output_file_dialog: FileDialog
var success_dialog: AcceptDialog
var fail_dialog: AcceptDialog
var files_error_dialog: AcceptDialog

func _ready():
        parser = CollisionParser.new()
        exporter = CollisionExporter.new()
        
        # Connect UI signals (these will be connected in the .tscn file)
        pass

func _on_parse_button_pressed():
        print("Hello from the ColEx parse button :D")
        var scene_root = EditorInterface.get_edited_scene_root()
        if not scene_root:
                _update_status("Error: No scene is open", true)
                return
        
        _update_status("Parsing scene...")
        
        # Parse the scene
        current_scene_data = parser.parse_scene(scene_root)
        
        if current_scene_data.nodes.size() > 0:
                _update_status("Parsed %d collision nodes (%d static, %d dynamic)" % [
                        current_scene_data.nodes.size(),
                        current_scene_data.static_objects.size(),
                        current_scene_data.dynamic_objects.size()
                ])
                export_button.disabled = false
        else:
                _update_status("No collision nodes found in scene", true)
                export_button.disabled = true

func _on_browse_button_pressed():
        if not output_file_dialog:
                return
                
        output_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
        output_file_dialog.access = FileDialog.ACCESS_RESOURCES
        
        # Clear existing filters
        output_file_dialog.clear_filters()
        
        if export_options.selected == 0:  # JSON
                output_file_dialog.add_filter("*.json", "JSON Files")
        else:  # Binary
                output_file_dialog.add_filter("*.dat", "Binary Files")
        
        output_file_dialog.popup_centered(Vector2i(800, 600))

func _on_output_file_dialog_file_selected(path: String):
        file_path_line_edit.text = path

func _on_export_button_pressed():
        if not current_scene_data:
                _update_status("Error: No scene data to export. Parse scene first.", true)
                return
        
        var file_path = file_path_line_edit.text.strip_edges()
        if file_path.is_empty():
                _update_status("Error: Please specify an export path", true)
                return
        
        _update_status("Exporting...")
        
        var success = false
        if export_options.selected == 0:  # JSON
                success = exporter.export_to_json(current_scene_data, file_path)
        else:  # Binary
                success = exporter.export_to_binary(current_scene_data, file_path)
        
        if success:
                _update_status("Successfully exported to: " + file_path)
                if success_dialog:
                        success_dialog.popup_centered()
        else:
                _update_status("Export failed!", true)
                if fail_dialog:
                        fail_dialog.popup_centered()

func _update_status(text: String, is_error: bool = false):
        if status_label:
                status_label.text = text
                if is_error:
                        status_label.modulate = Color.RED
                else:
                        status_label.modulate = Color.WHITE
        
        print("Collision Exporter: ", text)
