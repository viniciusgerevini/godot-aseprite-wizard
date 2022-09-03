tool
extends Reference

const WIZARD_CONFIG_META_NAME = "_aseprite_wizard_config_"
const WIZARD_CONFIG_MARKER = "aseprite_wizard_config"
const SEPARATOR = "|="

static func encode(object: Dictionary):
	var text = "%s\n" % WIZARD_CONFIG_MARKER

	for prop in object:
		text += "%s%s%s\n" % [prop, SEPARATOR, object[prop]]

	return Marshalls.utf8_to_base64(text)


static func decode(string: String):
	var decoded = _decode_base64(string)
	if not _is_wizard_config(decoded):
		return null

	var cfg = decoded.split("\n")
	var config = {}
	for c in cfg:
		var parts = c.split(SEPARATOR, 1)
		if parts.size() == 2:
			var key = parts[0].strip_edges()
			var value = parts[1].strip_edges()
			
			#Convert bool properties
			if key == "only_visible" or key == "op_exp":
				match value:
					"True":
						config[key] = true
					"False":
						config[key] = false
					_:
						config[key] = false
			else:
				config[key] = value
				
	return config


static func _decode_base64(string: String):
	if string != "":
		return Marshalls.base64_to_utf8(string)
	return null


static func _is_wizard_config(cfg) -> bool:
	return cfg != null and cfg.begins_with(WIZARD_CONFIG_MARKER)

static func load_config(node:Node):
	if node.has_meta(WIZARD_CONFIG_META_NAME):
		return node.get_meta(WIZARD_CONFIG_META_NAME)
		
	return decode(node.editor_description)
	
static func save_config(node:Node, use_metadata:bool, cfg:Dictionary):
	if use_metadata:
		node.set_meta(WIZARD_CONFIG_META_NAME, cfg)
		
		#Delete config from editor_description
		var decoded = _decode_base64(node.editor_description)
		if  _is_wizard_config(decoded):
			node.editor_description = ""
	else:
		node.editor_description = encode(cfg)
