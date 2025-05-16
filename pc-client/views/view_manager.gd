class_name ViewManager extends Node

const views_dir := "res://views"

var active_views: Array[View] = []
var _scene_map: Dictionary[GDScript, PackedScene] = {
    CharacterSelectView: preload("res://views/character_select_view.tscn"),
    LoginView: preload("res://views/login_view.tscn"),
    MainView: preload("res://views/main_view.tscn"),
}

var char_select: CharacterSelectView
var login: LoginView
var main: MainView

var signals: SignalBus


func _ready():
    signals = Global.signal_bus
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    signals.login_resp.connect(_on_login)


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


func _on_connected_to_server() -> void:
    if main:
        main.despawn()
        
    if not login:
        login = spawn(LoginView)
        

func _on_connection_failed() -> void:
    if login:
        login.despawn()
        
    if main:
        main.despawn()
        
    main = spawn(MainView)
     
       
func _on_login(resp: LoginResp) -> void:
    if not resp.success:
        return
    
    if login:
        login.despawn()
    
    if char_select:
        char_select.despawn()
        
    char_select = spawn(CharacterSelectView)
        
    
