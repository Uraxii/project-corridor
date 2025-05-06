extends Addon

var hooks: Dictionary = {
    "world" = {
        "game_load_start" = [
            _on_game_load_start,
            func(): Logger.info("From HelloWorld addon: Called anonmyous func.")
        ]
    },
}


func setup() -> void:
    Commands.register("HelloWorld", custom_event)


func get_hooks():
    return hooks


func custom_event(msg: String):
    Console.log_message("From HelloWorld addon custom_event: %s" % msg)


func _on_game_load_start():
    Commands.run("HelloWorld", ["Hello world!"])    
