class_name Item extends Resource

const INVALID_ID := -1






@export_category("Item")
@export var id:     int         = INVALID_ID
@export var title:  String      = "{ Title }"
@export var desc:   String      = "{ Description }"
@export var icon:   Texture2D   = preload("res://icons/default_icon.png")
@export var rarity: Rarity      = Rarity.Common
@export var tags: Array[Tag] = [Tag.Junk]

@export var tags_old: Dictionary ={
    "id"            = -1,
    "title"         = "{ Item }",
    "desc"          = "{ Description }",
    "icon"          = null,
    "catergory"     = "{ Category }",
    "sub_catergory" = "{ Sub-Catergory }",
    "element"       = "{ Element }",
    "gem_slots"     = 0,
    "max_stack"     = 1,
    "cost"          = 1,
}


@export var mods:   Array = []
@export var gems:   Array = []

@export_category("Equipable")
@export var trait_table: Dictionary[String, int] = {
    "vigor": 0,
    "juiced_up": 0,
    "iron_fist": 0,
    "big_iron": 0,
    "sniper": 0,
    "jackpot": 0,
}
