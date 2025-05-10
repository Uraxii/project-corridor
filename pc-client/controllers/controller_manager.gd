class_name ControllerManager extends Node

var active: Array[Controller] = [LoginController.new()]


func find(type: String) -> Controller:
    var index: int = active.find_custom(
        func(control): return control.get_type() == type)
    
    if index == -1:
        push_error("Could not find %s controller!" % type)
        return null
        
    return active[index]
