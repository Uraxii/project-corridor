class_name View extends Control


func get_type() -> String:
    push_error("get_type must be implemented.")
    return "base"
    

func despawn():
    Signals.despawn_view.emit(self)
    queue_free.call_deferred()


func _on_show_view(view_type: String) -> void:
    if view_type != get_type():
        return
        
    show()

    
func _on_hide_view(view_type: String) -> void:
    if view_type != get_type():
        return
        
    hide()
