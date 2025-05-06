class_name Sanitizer

# TODO: Implement a better block list.
const BLOCKED: String = "/\\$#%.[]{}\"\'|"


static func sanitize(input: String) -> String:
    if input.is_empty():
        return ""

    var i: int = input.length() - 1

    while i >= 0:
        # if the character is banned, remove it from the string.
        if input[i] in BLOCKED:
            Logger.debug(
                "Found illegal character!",
            {"Char": input[i], })

            input[i] = ""

        i -= 1

    return input
