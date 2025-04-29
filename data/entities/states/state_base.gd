class_name StateBase extends Node

signal transition


func enter(_entity) -> void:
        # print('Entered state ', name.to_lower())
        pass


func frame_update(_entity) -> void:
        # print('Frame update: %s' % name.to_lower())
        pass


func physics_update(_entity) -> void:
        # print('Physics update: %s' % name.to_lower())
        pass


func exit(_entity) -> void:
        # print('Exited state ', name.to_lower())
        pass
