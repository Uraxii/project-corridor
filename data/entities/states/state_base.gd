class_name StateBase

extends Node


signal transition


func enter(entity) -> void:
        print('Entered state ', name.to_lower())


func frame_update(entity) -> void:
        pass


func physics_update(entity) -> void:
        pass


func exit(entity) -> void:
        print('Exited state ', name.to_lower())
