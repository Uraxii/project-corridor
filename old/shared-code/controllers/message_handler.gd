# Global Controllers
class_name MessageHandler extends Node

var controllers: Dictionary[String, Callable] = {}
var default_controller: Callable = func(_peer, _msg): return {
    "type": "error",
    "message": "Unknown message type"
}

func register(message_type: String, controller: Callable) -> void:
    print("Registered Controller for ", message_type )
    controllers[message_type] = controller


func unregister(message_type: String) -> void:
    controllers.erase(message_type)


func set_default_controller(controller: Callable) -> void:
    default_controller = controller


func generate_routes(controllers: Array[Controller]) -> void:
    for controller in controllers:
        for route in controller.get_routes():
            var message_type: String = route.get("type", "")
            var handler_method: String = route.get("handler", "")

            if message_type.is_empty() or handler_method.is_empty():
                printerr("Controller route is missing type or handler!")
                continue

            register(message_type,
                func(peer, data):
                    return controller.call(handler_method, peer, data))


func _load_controllers_from_directory(path: String) -> void:
    var dir := DirAccess.open(path)

    if not dir:
        printerr("Could not open controllers directory! Dir: %s" % path)
        return

    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if file.ends_with(".gd"):
            print("Checking file: ", file)
            var script_path = path.path_join(file)
            var script = load(script_path)
            print("File: ", script_path, " Script: ", script)
            if script:
                var instance = script.new()
                if instance is Controller:
                    print("Is Controller")
                    var routes = instance.get_routes()
                    for route in routes:
                        var message_type: String = route.get(
                            "message_type", "")
                        var handler_method: String = route.get(
                            "handler_method", "")
                        if message_type.is_empty() or handler_method.is_empty():
                            push_error(
                                "Controller route is missing type or handler!")
                            continue
                        register(message_type, func(peer, data):
                            return instance.call(handler_method, peer, data))
        file = dir.get_next()
    dir.list_dir_end()


func dispatch(action: String, message: Dictionary, peer_id: int) -> Variant:
    var controller: Callable = controllers.get(action, default_controller)
    return controller.call(peer_id, message)
