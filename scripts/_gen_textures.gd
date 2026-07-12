@tool
extends SceneTree

## Builds headless-safe ImageTexture `.tres` resources from raw RGBA pixel dumps
## produced by extract_pixels.py. This avoids Godot's PNG decoder entirely (it rejects
## the project's PNGs), feeding pixel data straight into an Image via create_from_data.
## The companion `.import` files (written by the shell) remap the original
## `res://...png` paths to these `.tres` resources, so no scene or script reference changes.

const IN_DIR := "res://generated/textures"
const FMT_RGBA8 := 4

func _initialize() -> void:
	var dir := DirAccess.open(IN_DIR)
	if dir == null:
		push_error("cannot open " + IN_DIR)
		quit()
	dir.list_dir_begin()
	var f := dir.get_next()
	var count := 0
	while f != "":
		if f.ends_with(".rgba"):
			if _build(f):
				count += 1
		f = dir.get_next()
	dir.list_dir_end()
	print("BUILD_DONE count=%d" % count)
	quit()


func _build(fname: String) -> bool:
	var path := IN_DIR + "/" + fname
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		push_error("cannot open " + path)
		return false
	var magic := fa.get_buffer(5)
	if magic.get_string_from_ascii() != "PHRAW":
		push_error("bad magic " + path)
		fa.close()
		return false
	var w := fa.get_32()
	var h := fa.get_32()
	var fmt := fa.get_32()
	if fmt != FMT_RGBA8:
		push_error("bad fmt " + path)
		fa.close()
		return false
	var n := w * h * 4
	var bytes := fa.get_buffer(n)
	fa.close()
	if bytes.size() != n:
		push_error("short data " + path)
		return false
	var img := Image.create_from_data(w, h, false, Image.Format.FORMAT_RGBA8, bytes)
	if img.is_empty():
		push_error("create_from_data failed " + path)
		return false
	var tex := ImageTexture.create_from_image(img)
	if tex == null:
		push_error("create_from_image failed " + path)
		return false
	var out := IN_DIR + "/" + fname.get_basename() + ".tex.tres"
	var serr := ResourceSaver.save(tex, out)
	if serr != OK:
		push_error("save failed " + out + " err=" + str(serr))
		return false
	print("BUILT " + out)
	return true
