class_name LoginView extends Control


func _ready() -> void:
    hide()
    Network.connected.connect(func(): show())
    Controllers.login.login_success.connect(func(): hide())
    
    var submit_button: Button = %SubmitButton
    submit_button.pressed.connect(_on_submit_pressed)

    
func _on_submit_pressed() -> void:
    var user_field: TextEdit = %UserNameField
    var pass_field: TextEdit = %PasswordField
    
    Controllers.login.login(user_field.text, pass_field.text)
