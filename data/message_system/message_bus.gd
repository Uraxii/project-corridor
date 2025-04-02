extends Node

signal Broadcast

func SendMessage(message) -> void:
        Broadcast.emit(message)
