@tool
extends VBoxContainer

@onready var _details_btn = $label
@onready var _details_container = $MarginContainer/GridContainer

@onready var _split_layers_field = $MarginContainer/GridContainer/split_layers
@onready var _only_visible_layers = $MarginContainer/GridContainer/only_visible_layers
@onready var _layer_exclusion_pattern = $MarginContainer/GridContainer/layer_exclusion_pattern
@onready var _output_name = $MarginContainer/GridContainer/output_name
@onready var _do_not_create_resource = $MarginContainer/GridContainer/do_not_create_resource

var _entry

func _ready():
	_adjust_icon(false)
	_details_container.hide()
	_load_fields()


func set_details(entry: Dictionary):
	_entry = entry


func _load_fields():
	_split_layers_field.text = "Yes" if _entry.split_layers else "No"
	_only_visible_layers.text = "Yes" if _entry.only_visible_layers else "No"
	_layer_exclusion_pattern.text = _entry.layer_exclusion_pattern
	_output_name.text = _entry.output_name
	_output_name.text = _entry.output_name
	_do_not_create_resource.text = "Yes" if _entry.do_not_create_resource else "No"


func _adjust_icon(is_visible: bool) -> void:
	var icon_name = "GuiTreeArrowDown" if is_visible else "GuiTreeArrowRight"
	_details_btn.icon = get_theme_icon(icon_name, "EditorIcons")


func _on_label_pressed():
	_details_container.visible = not _details_container.visible
	_adjust_icon(_details_container.visible)

