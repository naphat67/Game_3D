class_name InventoryItem extends Node

var BASE_CHUNK: WorldGen_Chunk = null

var ID: int = -1
@export var Name: String = ""
@export var Tags: Array[String] = []
@export var MaxUses: int = 1
var Owner: String = ""
var Permissions: Dictionary[String, int] = {
	"groups": 3,
	"everyone": 0
}

func Interact() -> void:
	BASE_CHUNK.BASE_WORLD_GENERATOR.Player.Inv_AddItem(self)
