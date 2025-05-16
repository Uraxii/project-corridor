class_name Quality

enum Type {
    Poor, Common, Uncommon, Rare, Epic, Legendary, Iconic }

const INVALID_COLOR := Color.YELLOW
const DEFAULT_ICON: Texture2D = preload("res://icons/default_icon.png")

static var quality_settings: Array[Setting] = [
    Setting.new(Type.Poor,  Color.DARK_GRAY, DEFAULT_ICON),
    Setting.new(Type.Common, Color.GAINSBORO, DEFAULT_ICON),
    Setting.new(Type.Uncommon,Color.CHARTREUSE, DEFAULT_ICON),
    Setting.new(Type.Rare, Color.MEDIUM_BLUE, DEFAULT_ICON),
    Setting.new(Type.Epic, Color.MEDIUM_ORCHID, DEFAULT_ICON),
    Setting.new(Type.Legendary, Color.DARK_ORANGE, DEFAULT_ICON),
    Setting.new(Type.Iconic, Color.RED, DEFAULT_ICON)]


class Setting:
    var type:    Type
    var color:   Color
    var icon:    Texture2D
    
    func _init(quality: Type, color: Color, icon: Texture2D) -> void:
        self.type   = quality
        self.color  = color
        self.icon   = icon


func get_color(quality: Type) -> Color:
    var color := INVALID_COLOR
    
    var index: int = quality_settings.find_custom(
        func(item:Setting): return item.type == quality)
    
    if index != -1:
        color = quality_settings[index].color
            
    return color
    
    
func set_color(quality: Type, color: Color) -> void:
    var index: int = quality_settings.find_custom(
        func(item:Setting): return item.type == quality)
        
    if index != -1:
        quality_settings[index].color = color


func get_icon(quality: Type) -> Texture2D:
    var icon := DEFAULT_ICON
    
    var index: int = quality_settings.find_custom(
        func(item:Setting): return item.type == quality)
    
    if index != -1:
        icon = quality_settings[index].icon
            
    return icon


func set_icon(quality: Type, icon: Texture2D) -> void:
    var index: int = quality_settings.find_custom(
        func(item:Setting): return item.type == quality)
        
    if index != -1:
        quality_settings[index].icon = icon
