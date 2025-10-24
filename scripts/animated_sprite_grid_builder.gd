extends AnimatedSprite2D

@export var texture: Texture2D
@export var hframes: int = 7
@export var vframes: int = 4
@export var start_frame: int = 0
@export var animation_name: StringName = "explode"
@export var fps: float = 50.0

func _ready():
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
	self.frame = start_frame
