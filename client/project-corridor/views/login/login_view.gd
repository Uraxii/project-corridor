class_name LoginView extends View


func _ready() -> void:
    multiplayer.connection_failed.connect(_on_connection_failed)
    signals.message_received.connect(_on_login)
    
    var submit_button: Button = %SubmitButton
    submit_button.pressed.connect(_on_submit_pressed)

    
func _on_submit_pressed() -> void:
    var user_field: LineEdit = %UsernameField
    var pass_field: LineEdit = %PasswordField
    
    if user_field.text.is_empty() or pass_field.text.is_empty():
        printerr("Username and password cannot be empty!")
        return
    
    var packet := NetUtils.new_packet()
    var creds := packet.new_credential()
    creds.set_user(user_field.text)
    creds.set_secret(pass_field.text)
    
    WS.send(packet)
    

func _on_connection_failed() -> void:
    despawn()


func _on_login(packet: NetUtils.MSG.Packet) -> void:
    # TODO: create login_resp packet
    if true:
        despawn()
    else:
        print("no")
