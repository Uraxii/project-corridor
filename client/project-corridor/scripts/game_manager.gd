class_name GameManager extends Node

var client_id := -1

# TODO: Make these views not class-level singletons.
var char_select: CharacterSelectView
var login: LoginView
var main: MainView
var console: ConsoleView
var pause: ViewPause

@onready var signals := Globals.signal_bus
@onready var views := Globals.views


func _ready() -> void:
    _connect_signals()
    console = views.spawn(ConsoleView)
    main = views.spawn(MainView)
    

func _connect_signals() -> void:
    signals.login_success.connect(_on_login_success)
    signals.api_status_passed.connect(_on_api_status_passed)


func _on_api_status_passed() -> void:
    if main:
        main.despawn()
        
    login = views.spawn(LoginView)


func _on_connection_closed() -> void:
    if login:
        login.despawn()
    
    main = views.spawn(MainView)


func _on_login_success() -> void:
    if login:
        login.despawn()
        
    pause = views.spawn(ViewPause)
    char_select = views.spawn(CharacterSelectView)
