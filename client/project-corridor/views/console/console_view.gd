class_name ConsoleView extends View

enum {
    STATE_INIT,
    STATE_HIDDEN,
    STATE_SHOWN,
    STATE_EDITING,
}

var curr_state  := STATE_INIT
var next_state  := STATE_INIT

var history: Array[String] = []

@onready var window: RichTextLabel = %Window

func _process(delta: float) -> void:
    # TODO: Implement state logic.
    pass
    

func _ready() -> void:
    signals.log_new_message.connect(_on_log_message)
    signals.log_new_debug.connect(_on_log_debug)
    signals.log_new_warning.connect(_on_log_warning)
    signals.log_new_error.connect(_on_log_error)
    signals.log_new_announcment.connect(_on_log_announcement)


func _on_log_message(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    if len(signals.log_new_message.get_connections()) == 1 :
        window.text +=  "\n" + message


func _on_log_debug(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    if len(signals.log_new_debug.get_connections()) == 1:
        window.text +=  "\n" + message


func _on_log_warning(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    if len(signals.log_new_warning.get_connections()) == 1:
        window.text += "\n" + message
    
        
func _on_log_error(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    if len(signals.log_new_error.get_connections()) == 1:
        window.text += "\n" + message


func _on_log_announcement(message: String) -> void:
    history.append(message)
    
    await get_tree().process_frame
    
    if not len(signals.log_new_announcment.get_connections()) > 1:
        window.text +=  "\n" + message
