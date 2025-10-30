extends TextureRect

func _ready():
	# Ensure it fills the viewport and keeps aspect covered
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
