class_name Addon

var title           := "Unamed Addon"
var version         := "0.0.0"
var description     := "This addon has no description."


func load_metadata(addon_dir: String) -> int:
    var cfg := ConfigFile.new()
    var metadata_file := "%s/metadata.cfg" % addon_dir
    var err = cfg.load(metadata_file)

    if err: 
        Logger.error("Failed to load addon metadata!",
            {"path":metadata_file, "error":error_string(err)})
        
        return err

    title = cfg.get_value("addon", "name", title)
    version = cfg.get_value("addon", "version", version)
    description = cfg.get_value("addon", "description", description)
    
    return OK


func get_metadata() -> Dictionary:
    return {
        "title": title,
        "version": version,
        "description": description,
    }


func log_msg(msg: String):
    Console.print_message(msg)


# These are meant to be overridden by the addon.
func setup(): return
func after_setup(): return
func get_hooks() -> Dictionary: return {}


func _to_string() -> String:
    return "Addon<%s>:%s" % [get_instance_id() ,str(get_metadata())]
