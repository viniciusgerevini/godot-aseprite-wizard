@tool
extends TabContainer

signal close_requested

const WizardWindow = preload("./as_wizard_window.tscn")

func _ready():
	$Import.close_requested.connect(emit_signal.bind("close_requested"))
	$Import.import_success.connect(_on_import_success)
	$History.request_edit.connect(_on_edit_request)
	$History.request_import.connect(_on_import_request)
	$ImportedSpriteFrames.import_success.connect($History.add_entry)

	self.set_tab_title(1, "Imported Resources")


func _on_AsWizardDockContainer_tab_changed(tab: int):
	match tab:
		1:
			$ImportedSpriteFrames.init_resources()
		2:
			$History.reload()


func _on_edit_request(import_cfg: Dictionary):
	$Import.load_import_config(import_cfg)
	self.current_tab = 0


func _on_import_request(import_cfg: Dictionary):
	$Import.load_import_config(import_cfg)
	$Import.trigger_import()


func _on_import_success(settings: Dictionary):
	$ImportedSpriteFrames.init_resources()
	$ImportedSpriteFrames.reload_tree()
	$History.add_entry(settings)
