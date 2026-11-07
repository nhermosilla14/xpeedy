class_name Difficulty
extends RefCounted
## The Survival difficulties of doc 10 as data (ADR 0019). Zones, bonuses, rollers and bouncers are added
## here by their own intents.

const CASUAL := "casual"
const EASY := "easy"
const STANDARD := "standard"
const EXTREME := "extreme"
const PURE := "pure"

## In menu order: key, target ms per segment, spikes, badge colour. The badge shows 1-5 triangles.
const TABLE := [
	{"key": CASUAL, "tps": 133.0, "spikes": true, "moving": true, "colour": Color("2CD9C8")},
	{"key": EASY, "tps": 100.0, "spikes": true, "moving": true, "colour": Color("33CC55")},
	{"key": STANDARD, "tps": 80.0, "spikes": true, "moving": true, "colour": Color("EBA52B")},
	{"key": EXTREME, "tps": 67.0, "spikes": true, "moving": true, "colour": Color("E04A30")},
	{"key": PURE, "tps": 50.0, "spikes": false, "moving": false, "colour": Color("3A44E0")},
]


static func keys() -> Array[String]:
	var result: Array[String] = []
	for row in TABLE:
		result.append(row["key"])
	return result


static func is_valid(key: String) -> bool:
	return keys().has(key)


## Number of triangles on the menu badge: 1 (casual) to 5 (pure).
static func triangles(key: String) -> int:
	return maxi(keys().find(key), 0) + 1


static func colour(key: String) -> Color:
	return TABLE[triangles(key) - 1]["colour"]


## The run settings of a difficulty; unknown keys give Standard.
static func config(key: String) -> RunConfig:
	var row: Dictionary = TABLE[triangles(key if is_valid(key) else STANDARD) - 1]
	var result := RunConfig.standard()
	result.target_tps = row["tps"]
	result.spikes_enabled = row["spikes"]
	result.rollers_enabled = row["moving"]
	result.bouncers_enabled = row["moving"]
	return result
