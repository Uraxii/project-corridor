extends Node

const NOT_SET:  int = -1 # Initial value
const SUPRESS:  int = 0  # Show no log messages
const ERROR:    int = 1  # Show errors
const WARN:     int = 2  # Show warning
const INFO:     int = 3  # Show info logs
const VERBOSE:  int = 4  # Show verbose logs
const DEBUG:    int = 5  # Show debug logs

var level:      int     = ERROR
var system:     String  = OS.get_unique_id()
var node:       String  = ""
var component:  String  = ""


func _init(node_name:String='', log_level:int=DEBUG) -> void:
        self.node = node_name
        self.level = log_level


func error(description: String, details: Dictionary = {}) -> void:
        if ERROR >= level:
                return

        var message := _construct(description, "", details)
        printerr(message)


func warn(description: String, details: Dictionary = {}) -> void:
        if WARN >= level:
                return

        var message := _construct(description, "WARN", details)
        print(message)


func info(description: String, details: Dictionary = {}) -> void:
        if INFO >= level:
                return

        var message := _construct(description, "INFO", details) 
        print(message)


func verbose(description: String, details: Dictionary = {}) -> void:
        if VERBOSE >= level:
                return

        var message := _construct(description, "VERBOSE", details) 
        print_verbose(message)


func debug(description: String, details: Dictionary = {}) -> void:
        if DEBUG >= level:
                return

        var message := _construct(description, "", details)
        print(message)


func _construct(description: String, level_str: String, details: Dictionary = {}) -> String:
        var message: String = description

        if level_str:
                message = "%s=%s" % [level_str, message]

        for value in details:
                message += "\t" + value.to_upper() + "=" + str(details[value])

        message += "\tPEER="+ str(Network.my_peer_id) # + "\tSYSTEM=" + system + "\tNODE=" + node

        return message
