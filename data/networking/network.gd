extends Node

signal peer_connected(id: int)
signal peer_disconnected(id: int)
signal server_disconnected

const DEFAULT_SERVER_IP: String = "localhost"
const DEFAULT_PORT:      int    = 7000
const DEFAULT_MAX_PEERS: int    = 99
const DEFAULT_ID:        int    = -1
const SERVER_ID:         int    = 1
const ALL_PEERS_ID:      int    = 0

const MIN_VARIENT_PACKET_SIZE: int = 16

var network := ENetMultiplayerPeer.new()
var is_host: bool = false

var poll_timer: Timer = Timer.new()

# Number of times per second to poll the network.
var polling_rate: int = 24:
        set(value):
                polling_rate = value
                # Seconds between each network poll.
                poll_timer.wait_time = polling_rate / 60.0


func _ready() -> void:
        multiplayer.peer_connected.connect(_on_peer_connected)
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)
        multiplayer.connected_to_server.connect(_on_connected_ok)
        multiplayer.connection_failed.connect(_on_connected_fail)
        multiplayer.server_disconnected.connect(_on_server_disconnected)

        # Disables Godot automatic network polling.
        # We want to control this manually.
        get_tree().multiplayer_poll = false

        poll_timer.autostart = true
        poll_timer.timeout.connect(_poll)


func start_server(port:int, max_peers:int, host:bool):
        var err = network.create_server(port, max_peers)

        if err != OK:
                Logger.error("Failed to create server!", {"error code": err})
                return

        if host:
                is_host = host
                # TODO: Handle client stuff ...

        multiplayer.multiplayer_peer = network

        add_child(poll_timer)


func start_client(address:String, port:int) -> void:
        var err = network.create_client(address, port)

        if err != OK:
                Logger.error("Failed to create client!", {"error code": err})
                return

        multiplayer.multiplayer_peer = network

        add_child(poll_timer)


# Triggered by poll_timer.timeout.
func _poll() -> void:
        # Logger.debug("Polling")

        # !!! TODO: Encrypt network traffic !!!
        # Note: Investigate Godot's Crypto class.

        network.poll()

        for i in network.get_available_packet_count():
                var peer_id     = network.get_packet_peer()
                var channel     = network.get_packet_channel()
                var mode        = network.get_packet_mode()
                var packet: PackedByteArray = network.get_packet()

                # Not sure what is causing this condition.
                # Might just be corrupted packets.
                if packet.size() < MIN_VARIENT_PACKET_SIZE:
                        return

                print("--- PACKET ---")
                print("sender: ", peer_id)
                print("message: ", bytes_to_var(packet))
                print("--------------")


func _on_peer_connected(peer_id: int) -> void:
        # Logger.info("Peer connected.", {"peer_id":peer_id})
        var peer: ENetPacketPeer = network.get_peer(peer_id)
        var message: Dictionary = HelloMessage.new("Nicole", "Sup", 21).serialize()
        var buffer: PackedByteArray = var_to_bytes(message)
        var channel = 0

        peer.send(channel,buffer, ENetPacketPeer.FLAG_RELIABLE)


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
