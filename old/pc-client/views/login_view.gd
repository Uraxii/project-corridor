class_name LoginView extends View

@onready var controller: LoginController = Global.controllers.find(LoginController)


func _ready() -> void:
    multiplayer.connection_failed.connect(_on_connection_failed)
    signals.login_resp.connect(_on_login)
    
    var submit_button: Button = %SubmitButton
    submit_button.pressed.connect(_on_submit_pressed)

    
func _on_submit_pressed() -> void:
    var user_field: LineEdit = %UsernameField
    var pass_field: LineEdit = %PasswordField
    
    var request := LoginReq.new()
    request.username = user_field.text
    request.password = pass_field.text
    
    controller.login(request)


func _on_connection_failed() -> void:
    despawn()


func _on_login(respone: LoginResp) -> void:
    if respone.success:
        despawn()
    else:
        print("no")
