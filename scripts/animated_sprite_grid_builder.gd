@tool
extends AnimatedSprite2D

@export var texture: Texture2D: set = set_texture
@export var hframes: int = 7: set = set_hframes
@export var vframes: int = 4: set = set_vframes
@export var start_frame: int = 0: set = set_start_frame
@export var animation_name: StringName = "explode": set = set_animation_name
@export var fps: float = 50.0: set = set_fps
# Outer margins (pixels)
@export var margin_left: int = 0: set = set_margin_left
@export var margin_top: int = 0: set = set_margin_top
@export var margin_right: int = 0: set = set_margin_right
@export var margin_bottom: int = 0: set = set_margin_bottom
# Spacing between frames (pixels)
@export var spacing_x: int = 0: set = set_spacing_x
@export var spacing_y: int = 0: set = set_spacing_y

func _ready():
	rebuild()

func set_texture(t):
	texture = t
	rebuild()

func set_hframes(h):
	hframes = h
	rebuild()

func set_vframes(v):
	vframes = v
	rebuild()

func set_start_frame(sf):
	start_frame = sf
	rebuild()

func set_animation_name(n):
	animation_name = n
	rebuild()

func set_fps(f):
	fps = f
	rebuild()

func set_margin_left(v):
	margin_left = v
	rebuild()

func set_margin_top(v):
	margin_top = v
	rebuild()

func set_margin_right(v):
	margin_right = v
	rebuild()

func set_margin_bottom(v):
	margin_bottom = v
	rebuild()

func set_spacing_x(v):
	spacing_x = v
	rebuild()

func set_spacing_y(v):
	spacing_y = v
	rebuild()

func rebuild():
	if texture == null:
		return
	var frames := SpriteFrames.new()
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, false)
	frames.set_animation_speed(animation_name, fps)
	var size := texture.get_size()
	if hframes <= 0 or vframes <= 0 or size.x == 0 or size.y == 0:
		return
	var inner_w := int(size.x) - margin_left - margin_right
	var inner_h := int(size.y) - margin_top - margin_bottom
	if inner_w <= 0 or inner_h <= 0:
		return
	var fw := int((inner_w - spacing_x * (hframes - 1)) / hframes)
	var fh := int((inner_h - spacing_y * (vframes - 1)) / vframes)
	if fw <= 0 or fh <= 0:
		return
	for v in range(vframes):
		for h in range(hframes):
			var x := margin_left + h * (fw + spacing_x)
			var y := margin_top + v * (fh + spacing_y)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(x, y, fw, fh)
			frames.add_frame(animation_name, atlas)
	self.sprite_frames = frames
	self.frame = clamp(start_frame, 0, hframes * vframes - 1)
