extends Node

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal server_disconnected

const PORT:      int = 7000
const MAX_CONNS: int = 99

var network = ENetMultiplayerPeer.new()

var poll_timer: Timer = Timer.new()

# Number of timer per second to poll.
var poll_rate: int = 24:
        set(value):
                poll_rate = value
                # Seconds between each network poll.
                poll_timer.wait_time = poll_rate / 60.0


func _ready() -> void:
        if not network:
                Logger.error("Tried creating a server, but network is null!")
                return

        multiplayer.peer_connected.connect(_on_peer_connected)
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)
        multiplayer.connected_to_server.connect(_on_connected_ok)
        multiplayer.connection_failed.connect(_on_connected_fail)
        multiplayer.server_disconnected.connect(_on_server_disconnected)

        # Disables Godot automatic network polling.
        # We want to control this manually.
        get_tree().multiplayer_poll = false

        var err = network.create_server(PORT, MAX_CONNS)

        if err != OK:
                Logger.error("Failed to create server!", {"error code": err})
                return

        multiplayer.multiplayer_peer = network

        poll_timer.autostart = true
        poll_timer.timeout.connect(_poll)


func _poll() -> void:
        network.poll()

        for i in network.get_available_packet_count():
                var peer_id     = network.get_packet_peer()
                var channel     = network.get_packet_channel()
                var mode        = network.get_packet_mode()
                var packet      = network.get_packet()

                print("--- SERVER ---")


                print("message: ", bytes_to_var(packet))

                print("--------------")





func _on_peer_connected(id: int) -> void:
        Logger.info("Peer connected.", {"id":id})


func _on_peer_disconnected(id):
        peer_disconnected.emit(id)


func _on_connected_ok() -> void:
        var peer_id: int = multiplayer.get_unique_id()
        peer_connected.emit(peer_id)


func _on_connected_fail() -> void:
        multiplayer.multiplayer_peer = null


func _on_server_disconnected():
        multiplayer.multiplayer_peer = null
        server_disconnected.emit()
