class_name ArgParser


static func parse() -> Dictionary:
    var arguments = {}

    for argument in OS.get_cmdline_args():
        if argument.contains("="):
            var key_value = argument.split("=")
            var key = key_value[0].trim_prefix("--")
            var value = key_value[1]
            
            # Handle comma-separated lists
            if value.contains(","):
                arguments[key] = value.split(",", false)  # false = keep empty parts
            else:
                arguments[key] = value
        else:
            # Options without a value
            arguments[argument.trim_prefix("--")] = ""
            
    return arguments
