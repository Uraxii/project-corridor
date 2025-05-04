class_name MessageBus extends Node

# Messages are sent here if no channel exists for the type
signal catch_all(message)

const MSG_SCRIPTS_PATH: String = "res://messages/types"

# Message type, message count
var channels: Dictionary = {"catch_all": 0}


func _ready() -> void:
    catch_all.connect(_on_catch_all)
    
    for type in _get_message_types(MSG_SCRIPTS_PATH):
        if type not in channels:
            channels[type] = 0
            add_user_signal("type")
            
    Logger.info("Message channels loaded.", {"channels":channels})
    

func send(message):
    var target_channel: Signal = channels.get(message.type)
    
    if not target_channel:
        catch_all.emit(message)
        
    target_channel.emit(message)


func _on_catch_all(message):
    Logger.warn("No channel for message. Sent to catch all!",
        {"message":message})


func _get_message_types(path: String) -> Array[String]:
    var dir = DirAccess.open(path)
    
    if not dir:
        push_error("Failed to open directory: " + path)
        return []

    dir.list_dir_begin()
    var file_name = dir.get_next()
    
    var message_types: Array[String] = []

    while file_name != "":
        if file_name.ends_with(".gd"):
            var script_path = path.path_join(file_name)
            var script = load(script_path)

            var message = script.new()
            
            if message:
                message_types.append(message.TYPE)

        file_name = dir.get_next()

    dir.list_dir_end()
    
    return message_types
