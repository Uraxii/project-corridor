class_name Module

var title           := "Unamed Module"
var version         := "0.0.0"
var description     := "This module has no description."


func load_metadata(module_dir: String) -> int:
    var cfg := ConfigFile.new()
    var metadata_file := "%s/metadata.cfg" % module_dir
    var err = cfg.load(metadata_file)

    if err: 
        Logger.error("Failed to load module metadata!",
            {"path":metadata_file, "error":error_string(err)})
        
        return err

    title = cfg.get_value("module", "name", title)
    version = cfg.get_value("module", "version", version)
    description = cfg.get_value("module", "description", description)
    
    return OK


func get_metadata() -> Dictionary:
    return {
        "title": title,
        "version": version,
        "description": description,
    }


func log_msg(msg: String):
    Console.print_message(msg)


# These are meant to be overridden by the module.
func setup(): return
func after_setup(): return
func get_hooks() -> Dictionary: return {}


func _to_string() -> String:
    return "Module<%s>:%s" % [get_instance_id() ,str(get_metadata())]
