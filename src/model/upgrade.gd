class_name Upgrade
extends RefCounted
## The upgrade catalogue (doc 08, ADR 0028). Tachyon Boost does nothing in the original and is not built.

const STAGE := "stage"
const FLOW_CONTROL := "flow_control"
const FRACTAL_SHIELDS := "fractal_shields"
const MODULATOR := "modulator"
const RECHARGER := "recharger"
const TORPEDO := "torpedo"
const PHASE_SHIFT := "phase_shift"

## In shop order. `prices` per level and `unlock` per level: the total of completed races that unlocks it.
const TABLE := [
	{"key": FLOW_CONTROL, "name": "flow", "prices": [15, 30], "unlock": [0, 20], "survival": false},
	{"key": FRACTAL_SHIELDS, "name": "fractal", "prices": [15, 20, 35], "unlock": [0, 12, 24], "survival": true},
	{"key": MODULATOR, "name": "modulator", "prices": [25, 40], "unlock": [0, 33], "survival": false},
	{"key": RECHARGER, "name": "recharger", "prices": [20, 25, 35], "unlock": [0, 7, 42], "survival": true},
	{"key": TORPEDO, "name": "torpedo", "prices": [15, 30, 45], "unlock": [0, 26, 40], "survival": true},
	{"key": PHASE_SHIFT, "name": "phase shift", "prices": [25, 55], "unlock": [15, 36], "survival": true},
]


static func keys() -> Array[String]:
	var result: Array[String] = []
	for row in TABLE:
		result.append(row["key"])
	return result


static func row(key: String) -> Dictionary:
	for r in TABLE:
		if r["key"] == key:
			return r
	return {}


static func display_name(key: String) -> String:
	return row(key).get("name", key)


static func levels(key: String) -> int:
	return row(key).get("prices", []).size()


## Credits the given level (1-based) costs.
static func price(key: String, level: int) -> int:
	return row(key)["prices"][level - 1]


## Total completed races that unlock the given level (1-based).
static func unlock_at(key: String, level: int) -> int:
	return row(key)["unlock"][level - 1]


## Total price of every level of every upgrade.
static func total_price() -> int:
	var total := 0
	for r in TABLE:
		for p in r["prices"]:
			total += p
	return total


## Does the upgrade work in this mode: `STAGE` or a Survival difficulty key (doc 08)? Extreme and Pure have none;
## Flow Control and the Shields Modulator are for Stage races only.
static func applies(key: String, mode: String) -> bool:
	if mode == STAGE:
		return true
	if mode == Difficulty.EXTREME or mode == Difficulty.PURE:
		return false
	return row(key).get("survival", false)
