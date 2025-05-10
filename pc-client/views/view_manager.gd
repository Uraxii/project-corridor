class_name ViewManager extends Node

const views_dir := "res://views"

var active_views: Array[View] = []
var _scene_map: Dictionary[String, PackedScene] = {}


func _ready():
    var root_path = "res://views"
    var scenes := find_tscn_files(root_path)

    for scene_path in scenes:
        var scene := load_scene(scene_path)
        if scene:
            var node = scene.instantiate() as View
            if node:
                _scene_map[node.get_type()] = scene
            else:
                printerr(scene_path, " does not extend View!")
                continue
                
    print("Views: ", _scene_map)


func spawn(type: String) -> View:
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
    Signals.spawn_view.emit(view_node)
    
    return view_node


func find_tscn_files(path: String) -> Array[String]:
    var results: Array[String] = []
    var dir := DirAccess.open(path)
    if not dir:
        push_error("Cannot open directory: " + path)
        return results

    dir.list_dir_begin()
    var file_name = dir.get_next()
    while file_name != "":
        if dir.current_is_dir():
            if file_name != "." and file_name != "..":
                results += find_tscn_files(path.path_join(file_name))
        elif file_name.ends_with(".tscn"):
            results.append(path.path_join(file_name))
        file_name = dir.get_next()
    dir.list_dir_end()
    return results


func load_scene(path: String) -> PackedScene:
    var res := ResourceLoader.load(path)
    if res and res is PackedScene:
        return res
    else:
        push_warning("Failed to load scene: " + path)
        return null
