tool
extends EditorProperty

var ap_list_control: OptionButton
var current_value := ""
var updating := false


var animation_player: AnimationPlayer
var aseprite_file: String = ""


func _init():
	print("initializing")
#    # Add the control as a direct child of EditorProperty node.
#    add_child(property_control)
	if get_edited_object() != null:
		current_value = get_edited_object()[get_edited_property()]
	print(current_value)

#	add_focusable(ap_list_control) 
#    property_control.text = "Value: " + str(current_value)
	# TODO get list of animation players in scene
	# TODO verifies if current value is in the list
	# TODO update
	#
	ap_list_control.connect("item_selected", self, "_on_item_selected")


func _on_item_selected(index):
	if (updating):
		return
	current_value = str(index)
	emit_changed(get_edited_property(), current_value)


func update_property():
	var new_value = get_edited_object()[get_edited_property()]
	if (new_value == current_value):
		return
	updating = true
	current_value = new_value
#	property_control.text = "Value: " + str(current_value)
	updating = false
