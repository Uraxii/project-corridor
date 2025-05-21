class_name WorldController extends Controller

var active: Array[Node] = []

func _ready() -> void:
    signals.load_world.connect(_on_load_world)
    

func _on_load_world():
    var file := "res://shared-code/environment/test_scene.tscn"
    var scene: PackedScene = load(file)
    
    if not scene:
        printerr("Cannot locate scene:" + file)
        signals.log_new_error.emit("Cannot locate scene:" + file)
        return
    
    var node := scene.instantiate()
    active.append(node)
    add_child(node)
    

func spawn_pc() -> void:
    pass
