class_name TestCase
extends RefCounted
## Base class for unit tests: collects assertion failures instead of aborting.

var errors: PackedStringArray = []


func check(condition: bool, message: String) -> void:
	if not condition:
		errors.append(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		errors.append("%s expected %s, got %s" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		errors.append("%s expected %f ± %f, got %f" % [message, expected, tolerance, actual])
