class_name ControllerManager extends Node

var active: Array[Controller] = [
    LoginController.new(),
    CharacterSelectController.new(),
]


func _ready() -> void:
    for controller in active:
        add_child(controller)


func find(type: GDScript) -> Controller:
    var index: int = active.find_custom(
        func(control): return control.get_script() == type)
    
    if index == -1:
        push_error("Could not find %s controller!" % type)
        return null
        
    return active[index]
