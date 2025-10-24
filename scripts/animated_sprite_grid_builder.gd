@tool
extends AnimatedSprite2D

@export var texture: Texture2D: set = set_texture
@export var hframes: int = 7: set = set_hframes
@export var vframes: int = 4: set = set_vframes
@export var start_frame: int = 0: set = set_start_frame
@export var animation_name: StringName = "explode": set = set_animation_name
@export var fps: float = 50.0: set = set_fps

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
	var fw := int(size.x / hframes)
	var fh := int(size.y / vframes)
	for v in range(vframes):
		for h in range(hframes):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(h * fw, v * fh, fw, fh)
			frames.add_frame(animation_name, atlas)
	self.sprite_frames = frames
	self.frame = clamp(start_frame, 0, hframes * vframes - 1)
