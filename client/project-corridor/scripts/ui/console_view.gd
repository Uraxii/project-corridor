class_name ConsoleView extends View

var history: Array[String] = []

@onready var window: RichTextLabel = %Window


func _ready() -> void:
    signals.chat.connect(_on_chat)
    signals.log_new_message.connect(_on_log_message)
    signals.log_new_debug.connect(_on_log_debug)
    signals.log_new_warning.connect(_on_log_warning)
    signals.log_new_error.connect(_on_log_error)
    signals.log_new_success.connect(_on_log_success)
    signals.log_new_announcment.connect(_on_log_announcement)


func _on_chat(sender: String, content: String) -> void:
    window.append_text("[color=#%s]%s[/color]: [i]%s[/i]\n" % [
        Color.CORNFLOWER_BLUE.to_html(false), sender, content])


func _on_log_message(message: String) -> void:
    if len(signals.log_new_message.get_connections()) == 1 :
        _message(message, Color.PAPAYA_WHIP)


func _on_log_debug(message: String) -> void:
    if len(signals.log_new_debug.get_connections()) == 1:
        _message(message, Color.AQUA)


func _on_log_warning(message: String) -> void:
    if len(signals.log_new_warning.get_connections()) == 1:
        _message(message, Color.ORANGE_RED)

    
func _on_log_error(message: String) -> void:
    if len(signals.log_new_error.get_connections()) == 1:
        _message(message, Color.RED)
        

func _on_log_success(message: String) -> void:
    _message(message, Color.LAWN_GREEN)
    

func _on_log_announcement(message: String) -> void:
    if not len(signals.log_new_announcment.get_connections()) > 1:
        _message(message, Color.ORANGE_RED)


func _message(message: String, color: Color) -> void:
    await get_tree().process_frame
    history.append(message)
    window.append_text(
        "[color=#%s]%s[/color]\n" % [color.to_html(false), message])
