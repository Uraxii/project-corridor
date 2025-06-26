class_name ViewPause extends View


enum {
    STATE_SHOWN,
    STATE_HIDDEN,
}

var curr_state := STATE_HIDDEN


func _ready() -> void:
    signals.in_cancel.connect(_on_cancel)
    
    var logout: Button = %Logout
    logout.pressed.connect(_on_logout_pressed)
    show()
    

func _on_cancel() -> void:
    match curr_state:
        STATE_SHOWN:
            hide()
            curr_state = STATE_HIDDEN
        STATE_HIDDEN:
            show()
            curr_state = STATE_SHOWN
     

func _on_logout_pressed() -> void:
    print("Logout pressed.")
    WS.disconn()
    despawn()
