class_name CommandBus extends Node

signal register_new_command(command_name: String, handler: Callable)

var _commands: Dictionary[String, Callable] = {}


func register(command_name: String, handler_func: Callable) -> void:
    if _commands.has(command_name):
        Console.print_message("Overwritting command <%s>" % command_name)
        
    _commands[command_name] = handler_func
    register_new_command.emit(command_name, handler_func)
    
    #Logger.info("Registed new command",
    #    {"command":command_name,"handler":handler_func})


func run(command_name: String, args: Array = []) -> void:
    var handler: Callable = _commands.get(command_name)
    
    if not handler:
        Logger.warn("Command not found!", {"command":command_name})
    
    #Logger.info("Running command.",
    #    {"command": command_name, "handler": handler})
    
    # NOTE: callv acts like rpc and will fail silently
    # if the arguments provided do not match the funtion's signature.
    
    handler.callv(args)
