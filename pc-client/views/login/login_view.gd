class_name LoginView extends View

@onready var login_controller: LoginController = Controllers.find("login")

func _ready() -> void:
    Signals.login_resp.connect(_on_login)
    var submit_button: Button = %SubmitButton
    submit_button.pressed.connect(_on_submit_pressed)


func get_type() -> String:
    return "login"

    
func _on_submit_pressed() -> void:
    var user_field: LineEdit = %UsernameField
    var pass_field: LineEdit = %PasswordField
    
    var request := LoginReq.new()
    request.username = user_field.text
    request.password = pass_field.text
    
    login_controller.login(request)


func _on_login(respone: LoginResp) -> void:
    if respone.success:
        despawn()
