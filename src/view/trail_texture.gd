class_name TrailTexture
extends RefCounted
## The `TrailMap` as a 16 × 64 RGBA8 texture the tunnel shader reads per tile (ADR 0011). Uploaded only
## when the map changes. Image data is kept on the CPU side too, so headless tests can read it.

var texture: ImageTexture
var image: Image

var _built_for := 0
var _built_version := -1


func _init() -> void:
	image = Image.create(TrailMap.LANES, TrailMap.ROWS, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)


## Uploads the map if it changed since the last call (or is a different map).
func refresh(map: TrailMap) -> void:
	var id := map.get_instance_id()
	if id == _built_for and map.version == _built_version:
		return
	_built_for = id
	_built_version = map.version
	image.set_data(TrailMap.LANES, TrailMap.ROWS, false, Image.FORMAT_RGBA8, map.data)
	texture.update(image)
