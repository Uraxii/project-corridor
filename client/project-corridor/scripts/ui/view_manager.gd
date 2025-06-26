class_name ViewManager extends Control

const views_dir := "res://views"

var active_views: Array[View] = []
var _scene_map: Dictionary[GDScript, PackedScene] = {
    CharacterSelectView: preload("res://scenes/ui/character_select_view.tscn"),
    LoginView: preload("res://scenes/ui/login_view.tscn"),
    MainView: preload("res://scenes/ui/main_view.tscn"),
    ConsoleView: preload("res://scenes/ui/console_view.tscn"),
    ViewPause: preload("res://scenes/ui/view_pause.tscn"),
}

@onready var signals := Globals.signal_bus


func spawn(type: GDScript) -> View:
    var view_scene = _scene_map.get(type)
    
    if not view_scene:
        printerr("Did not find scene for ", type, " view!")
        return null
        
    var view_node := view_scene.instantiate() as View
    
    if not view_node:
        printerr("Failed to instantiate node for ", type, " view.")
        return null
    
    active_views.append(view_node)
    add_child(view_node)
    view_node.initalize()
    signals.spawn_view.emit(view_node)
    return view_node


func _ready() :
    _set_full_rect(self)


func _set_full_rect(control: Control) -> void:
    control.anchor_left = 0.0
    control.anchor_top = 0.0
    control.anchor_right = 1.0
    control.anchor_bottom = 1.0

    control.offset_left = 0.0
    control.offset_top = 0.0
    control.offset_right = 0.0
    control.offset_bottom = 0.0
