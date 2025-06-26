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
    signals.connection_closed.connect(_on_connection_closed)
    signals.connected_to_server.connect(_on_connected_to_server)
    signals.got_client_id.connect(_on_got_client_id)
    signals.login_success.connect(_on_login_success)

    console = views.spawn(ConsoleView)
    

func _on_connected_to_server() -> void:
    login = views.spawn(LoginView)


func _on_connection_closed() -> void:
    if login:
        login.despawn()
    
    main = views.spawn(MainView)


func _on_got_client_id(msg: PacketManager.PACKETS.IdMessage) -> void:
    client_id = msg.get_id()
    signals.log_new_success.emit("Got ID %d" % client_id)


func _on_login_success() -> void:
    pause = views.spawn(ViewPause)
    char_select = views.spawn(CharacterSelectView)
