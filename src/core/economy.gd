class_name Economy
extends RefCounted
## Credits, the races completed and the upgrade levels bought, kept on the device (ADR 0028). Missing or
## corrupt files give zeros.

const RACE_REWARD_BASE := 2
const STAGE_BONUS := 10
const SURVIVAL_POINTS_PER_CREDIT := 500

var _path: String
var _gained := 0
var _spent := 0
var _races := 0
var _levels := {}


func _init(path := "user://economy.cfg") -> void:
	_path = path
	var file := ConfigFile.new()
	if file.load(_path) != OK:
		return
	_gained = maxi(_int(file.get_value("credits", "gained", 0)), 0)
	_spent = clampi(_int(file.get_value("credits", "spent", 0)), 0, _gained)
	_races = maxi(_int(file.get_value("progress", "races", 0)), 0)
	for key in Upgrade.keys():
		_levels[key] = clampi(_int(file.get_value("levels", key, 0)), 0, Upgrade.levels(key))


static func _int(value: Variant) -> int:
	return value if value is int else 0


func credits() -> int:
	return _gained - _spent


func races() -> int:
	return _races


func level(key: String) -> int:
	return _levels.get(key, 0)


func earn(amount: int) -> void:
	if amount > 0:
		_gained += amount
		save()


## Spends credits if the balance allows it. Returns whether it did.
func spend(amount: int) -> bool:
	if amount < 0 or amount > credits():
		return false
	_spent += amount
	save()
	return true


## Is the next level of an upgrade unlocked by the races completed? False when it is at its maximum.
func next_unlocked(key: String) -> bool:
	return level(key) < Upgrade.levels(key) and _races >= Upgrade.unlock_at(key, level(key) + 1)


## The price of the next level, or 0 at the maximum.
func next_price(key: String) -> int:
	return Upgrade.price(key, level(key) + 1) if level(key) < Upgrade.levels(key) else 0


func can_buy(key: String) -> bool:
	return next_unlocked(key) and next_price(key) <= credits()


## Buys the next level of an upgrade (levels are bought in order). Returns whether it did.
func buy(key: String) -> bool:
	if not can_buy(key):
		return false
	_spent += next_price(key)
	_levels[key] = level(key) + 1
	save()
	return true


func any_buyable() -> bool:
	for key in Upgrade.keys():
		if can_buy(key):
			return true
	return false


## A stage race was finished: a new one counts once and pays `2 + stage`, the last of a stage pays a bonus.
## Returns the credits earned.
func race_finished(stage: int, is_new_race: bool, is_stage_end: bool) -> int:
	if not is_new_race:
		return 0
	_races += 1
	var reward := RACE_REWARD_BASE + stage + (STAGE_BONUS if is_stage_end else 0)
	_gained += reward
	save()
	return reward


## A Survival run ended with `score` points: 1 credit per 500. Returns the credits earned.
func survival_score(score: int) -> int:
	var reward := score / SURVIVAL_POINTS_PER_CREDIT
	earn(reward)
	return reward


func save() -> void:
	var file := ConfigFile.new()
	file.set_value("credits", "gained", _gained)
	file.set_value("credits", "spent", _spent)
	file.set_value("progress", "races", _races)
	for key in Upgrade.keys():
		file.set_value("levels", key, level(key))
	file.save(_path)
