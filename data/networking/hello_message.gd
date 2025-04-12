class_name HelloMessage

var display_name:       String
var greeting:           String
var favorite_number:    int


func _init(display_name:String, greeting:String, favorite_number:int) -> void:
        self.display_name       = display_name
        self.greeting           = greeting
        self.favorite_number    = favorite_number


func serialize() -> Dictionary:
        return {
                "display_name":    display_name,
                "greeting":        greeting,
                "favorite_number": favorite_number,
        }

static func deserialize(data: Dictionary) -> HelloMessage:
        return HelloMessage.new(
                data.get("display_name"),
                data.get("greeting"),
                data.get("favorite_number")
        )
