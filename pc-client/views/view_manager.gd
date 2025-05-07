class_name ViewManager extends Node

var main: MainMenu
var login: LoginView


func _ready() -> void:
    main = preload("res://views/main_menu/main_menu.tscn").instantiate()
    add_child(main)
    
    login = preload("res://views/login/login_view.tscn").instantiate()
    add_child(login)
