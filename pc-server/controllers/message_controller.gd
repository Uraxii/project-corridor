class_name MessageController extends Object

var controllers: Dictionary[String, Callable] = {}
var default_controller: Callable = func(peer, msg): return {
    "type": "error",
    "message": "Unknown message type"
}


func register(message_type: String, controller: Callable) -> void:
    controllers[message_type] = controller


func unregister(message_type: String) -> void:
    controllers.erase(message_type)


func set_default_controller(controller: Callable) -> void:
    default_controller = controller


func load_controllers_from_directory(path: String) -> void:
    var dir := DirAccess.open(path)
    
    if not dir:
        printerr("Could not open controllers directory!")
        return
        
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".gd"):
            var script_path = path.path_join(file)
            var script = load(script_path)
            if script:
                var instance = script.new()
                if instance.has_method("call") and instance.has_meta("message_type"):
                    var message_type = instance.get_meta("message_type")
                    register(message_type, func(peer, msg): return instance.call("call", peer, msg))
        file = dir.get_next()
    dir.list_dir_end()


func dispatch(peer: StreamPeerTCP, message: Dictionary) -> Variant:
    var message_type = message.get("type", "")
    var controller: Callable = controllers.get(message_type, default_controller)
    return controller.call(peer, message)
