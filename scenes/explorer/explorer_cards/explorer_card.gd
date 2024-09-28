class_name ExplorerCard
extends Resource

@export var name: String
@export_range(0, 7) var speed_start_index := 3
@export var speed_spread: Array[int]
@export_range(0, 7) var might_start_index := 3
@export var might_spread: Array[int]
@export_range(0, 7) var sanity_start_index := 3
@export var sanity_spread: Array[int]
@export_range(0, 7) var knowledge_start_index := 3
@export var knowledge_spread: Array[int]
@export_color_no_alpha var color: Color

@export_group("Storytelling Stats")
@export_range(1, 99) var age: int
@export_range(40, 80) var height: int # Inches
@export_range(40, 300) var weight: int # lbs
@export var hobbies: Array[String]
# var birthday: Date

var current_speed := 3
var current_might := 3
var current_sanity := 3
var current_knowledge := 3