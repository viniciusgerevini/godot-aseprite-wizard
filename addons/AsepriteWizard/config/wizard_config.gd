tool
extends Reference

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
			config[parts[0].strip_edges()] = parts[1].strip_edges()
	return config


static func _decode_base64(string: String):
	if string != "":
		return Marshalls.base64_to_utf8(string)
	return null


static func _is_wizard_config(cfg) -> bool:
	return cfg != null and cfg.begins_with(WIZARD_CONFIG_MARKER)

