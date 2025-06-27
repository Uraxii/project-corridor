class_name GameManager extends Node

var client_id := -1

# TODO: Make these views not class-level singletons.
var char_select: CharacterSelectView
var create_character: CreateCharacterView
var login: LoginView
var main: MainView

@onready var signals := Globals.signal_bus
@onready var views := Globals.views


func _ready() -> void:
    _connect_signals()
    main = views.spawn(MainView)
    

func _connect_signals() -> void:
    signals.login_success.connect(_on_login_success)
    signals.api_status_passed.connect(_on_api_status_passed)
    signals.logout_success.connect(_on_logout)
    signals.load_world.connect(_on_load_world)


func _on_api_status_passed() -> void:
    views.despawn_all()
    login = views.spawn(LoginView)


func _on_connection_closed() -> void:
    views.despawn_all()
    main = views.spawn(MainView)


func _on_login_success() -> void:
    views.despawn_all()
    char_select = views.spawn(CharacterSelectView)
    

func _on_logout() -> void:
    views.despawn_all()
    main = views.spawn(MainView)
    

func _on_load_world() -> void:
    views.despawn_all()
