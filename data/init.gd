extends Node

var game_manager: Resource = preload("res://data/game_manager.tscn")
var network_manager: Resource = preload("res://data/networking/network_manager.tscn")


func _ready() -> void:
        var root_node: Node = get_tree().root

        var players_node = Node.new()
        players_node.name = "Players"
        root_node.add_child.call_deferred(players_node)

        root_node.add_child.call_deferred(game_manager.instantiate())
        root_node.add_child.call_deferred(network_manager.instantiate())

        queue_free.call_deferred()
