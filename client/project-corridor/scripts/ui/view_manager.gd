class_name ViewManager extends CanvasLayer

var system_view: SystemView
var console_view: ConsoleView
var active_views: Array[View] = []

var _scene_map: Dictionary[GDScript, PackedScene] = {
    CharacterSelectView: preload("res://scenes/ui/character_select_view.tscn"),
    CreateCharacterView: preload("res://scenes/ui/create_character_view.tscn"),
    LoginView: preload("res://scenes/ui/login_view.tscn"),
    MainView: preload("res://scenes/ui/main_view.tscn"),
    ConsoleView: preload("res://scenes/ui/console_view.tscn"),
    SystemView: preload("res://scenes/ui/system_view.tscn"),
}

@onready var signals := Globals.signal_bus


func despawn_all() -> void:
    for view in active_views:
        if view:
            view.despawn()


func spawn(type: GDScript, do_not_register=false) -> View:
    var view_scene = _scene_map.get(type)
    
    if not view_scene:
        printerr("Did not find scene for ", type, " view!")
        return null
        
    var view_node := view_scene.instantiate() as View
    
    if not view_node:
        printerr("Failed to instantiate node for ", type, " view.")
        return null
    
    if not do_not_register:
        active_views.append(view_node)
        
    add_child(view_node)
    view_node.initalize()
    signals.spawn_view.emit(view_node)
    return view_node


func _ready():
    #_set_full_rect(self)
    console_view = spawn(ConsoleView, true)
    system_view = spawn(SystemView, true)


func _on_despawn_view(view: View) -> void:
    active_views.erase(view)


func _set_full_rect(control: Control) -> void:
    control.anchor_left = 0.0
    control.anchor_top = 0.0
    control.anchor_right = 1.0
    control.anchor_bottom = 1.0

    control.offset_left = 0.0
    control.offset_top = 0.0
    control.offset_right = 0.0
    control.offset_bottom = 0.0
