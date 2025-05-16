class_name GlobalManager extends Node

@onready var signal_bus: SignalBus = _new_global(SignalBus)
@onready var message_router: MessageRouter = _new_global(MessageRouter)
@onready var controllers: ControllerManager = _new_global(ControllerManager)
    

func _new_global(type: GDScript) -> Node:
    var instance = type.new()
    add_child(instance)
    return instance
