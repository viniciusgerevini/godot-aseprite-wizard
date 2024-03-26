@tool
extends MarginContainer

signal dock_requested

enum Tabs {
	DOCK_IMPORTS = 0,
}

@onready var _tabs: TabContainer = $TabContainer
@onready var _dock_button: Button = $dock_button

func _ready():
	_tabs.set_tab_title(Tabs.DOCK_IMPORTS, "Dock Imports")
	_dock_button.icon = get_theme_icon("MakeFloating", "EditorIcons")
	_dock_button.tooltip_text = "Dock Window"


func _on_dock_button_pressed():
	dock_requested.emit()
