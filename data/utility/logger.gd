extends Node

var node:       String
var system:     String = OS.get_unique_id()
var component:  String = ''
var verbosity:  level

enum level {
        ERROR,
        WARNING,
        INFO,
        VERBOSE,
        DEBUG
}


func _init(node_name: String='', verbosity_level=level.DEBUG) -> void:
        self.node = node_name
        self.verbosity = verbosity_level


func error(description: String, details: Dictionary = {}) -> void:
        if level.ERROR > verbosity:
                return
        var message := construct(description, level.ERROR, details)

        printerr(message)


func warn(description: String, details: Dictionary = {}) -> void:
        if level.WARNING > verbosity:
                return	
        var message := construct(description, level.WARNING, details)

        print(message)


func info(description: String, details: Dictionary = {}) -> void:
        if level.INFO > verbosity:
                return	

        var message := construct(description, level.INFO, details) 
        print(message)


func verbose(description: String, details: Dictionary = {}) -> void:
        if level.VERBOSE > verbosity:
                return

        var message := construct(description, level.VERBOSE, details) 
        print_verbose(message)


func debug(description: String, details: Dictionary = {}) -> void:
        if level.DEBUG > verbosity:
                return

        var message := construct(description, level.DEBUG, details)
        print(message)


func construct(description: String, log_verbosity: level, details: Dictionary = {}) -> String:
        var message: String = level.keys()[log_verbosity] + "=" + description

        for value in details:
                message += "\t" + value.to_upper() + "=" + str(details[value])
        if multiplayer:
                message += "\tPEER="+ str(multiplayer.get_unique_id()) # + "\tSYSTEM=" + system + "\tNODE=" + node

        return message
