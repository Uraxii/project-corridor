class_name LoginView extends View


func _ready() -> void:
    var submit_button: Button = %SubmitButton
    submit_button.pressed.connect(_on_submit_pressed)

    
func _on_submit_pressed() -> void:
    var user: LineEdit = %UsernameField
    var secret: LineEdit = %PasswordField
    
    if user.text.is_empty() or secret.text.is_empty():
        printerr("Username and password cannot be empty!")
        return
        
    API.login(user.text, secret.text)


func _on_login_success() -> void:
    despawn()
