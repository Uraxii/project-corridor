class_name ChatInput extends View

enum {
    STATE_EDITING,
    STATE_HIDDEN,
}

var curr_state := STATE_HIDDEN

@onready var line: LineEdit = %LineEdit


func _ready() -> void:
    signals.in_accept.connect(_on_accept)
    signals.in_cancel.connect(_on_cancel)
    line.text_submitted.connect(_on_submit)
    hide()


func _on_accept() -> void:
    match curr_state:
        STATE_HIDDEN:
            show()
            curr_state = STATE_EDITING


func _on_cancel() -> void:
    match curr_state:
        STATE_EDITING:
            hide()
            curr_state = STATE_HIDDEN
            
            
func _on_submit(content: String) -> void:
    line.text = ""
    
    signals.chat.emit("You", content)
    
    var packet := PacketManager.new_packet()
    var chat := packet.new_chat()
    chat.set_content(content)
    WS.send(packet)
