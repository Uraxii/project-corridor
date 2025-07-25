class_name View extends Control

var signals := Global.signal_bus

func initalize() -> void:
    visibility_changed.connect(_on_visibility_change)    
    

func despawn():
    signals.despawn_view.emit(self)
    queue_free.call_deferred()


func _on_visibility_change() -> void:
    var is_visible: bool = is_visible_in_tree()
    print(self, " visible:", is_visible)
