class_name StateBase extends Node

signal transition


func enter(entity) -> void:
        # print('Entered state ', name.to_lower())
        pass


func frame_update(entity) -> void:
        # print('Frame update: %s' % name.to_lower())
        pass


func physics_update(entity) -> void:
        # print('Physics update: %s' % name.to_lower())
        pass


func exit(entity) -> void:
        # print('Exited state ', name.to_lower())
        pass
