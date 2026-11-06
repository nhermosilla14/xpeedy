extends SceneTree
## Minimal headless test runner: runs every `test_*` method of every script in res://tests/unit/.
## Each test script extends TestCase.

const UNIT_DIR := "res://tests/unit/"


func _init() -> void:
	var failures := 0
	var total := 0
	var files := DirAccess.get_files_at(UNIT_DIR)
	files.sort()
	for file in files:
		if not file.ends_with(".gd"):
			continue
		var script: GDScript = load(UNIT_DIR + file)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			var case: TestCase = script.new()
			case.call(name)
			if case.errors.is_empty():
				print("  ok    %s::%s" % [file, name])
			else:
				failures += 1
				print("  FAIL  %s::%s" % [file, name])
				for e in case.errors:
					print("        " + e)
	print("%d tests, %d failed" % [total, failures])
	quit(1 if failures > 0 or total == 0 else 0)
