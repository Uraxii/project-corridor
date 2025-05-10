class_name LoginView extends View

@onready var login_controller: LoginController = Controllers.find("login")

func _ready() -> void:
    Signals.login.connect(_on_login)
    var submit_button: Button = %SubmitButton
    submit_button.pressed.connect(_on_submit_pressed)


func get_type() -> String:
    return "login"

    
func _on_submit_pressed() -> void:
    var user_field: TextEdit = %UserNameField
    var pass_field: TextEdit = %PasswordField
    
    var request := LoginRequest.new()
    request.username = user_field.text
    request.password = pass_field.text
    
    login_controller.login(request)


func _on_login(respone: LoginResponse) -> void:
    if respone.success:
        despawn()
