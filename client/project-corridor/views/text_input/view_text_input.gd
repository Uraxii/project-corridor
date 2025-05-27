class_name ViewTextInput extends View

enum {
    STATE_EDITING,
    STATE_HIDDEN,
}

var curr_state := STATE_HIDDEN

@onready var input_field: LineEdit = %LineEdit


func _ready() -> void:
    signals.in_accept.connect(_on_accept)
    signals.in_cancel.connect(_on_cancel)
    hide()


func _on_accept() -> void:
    match curr_state:
        STATE_EDITING:
            var msg := input_field.text
            input_field.text = ""
            signals.log_new_message.emit(msg)
        STATE_HIDDEN:
            show()
            curr_state = STATE_EDITING


func _on_cancel() -> void:
    match curr_state:
        STATE_EDITING:
            hide()
            curr_state = STATE_HIDDEN
            
            
