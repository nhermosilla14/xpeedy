class_name SoundMap
extends RefCounted
## Which sound and vibration go with each run event (doc 15, ADR 0031). The menu click and the start lights'
## beeps are played by `main.gd` directly.

const NONE := {}


## `{"sound": String, "vibrate": int ms}` for an event, or an empty dictionary when it makes no sound.
## `bonus` is the bonus of a BONUS_FIRED event (Quake has its own QUAKE event).
static func for_event(kind: int, bonus := 0) -> Dictionary:
	match kind:
		RunEvent.Kind.SHIELD_PICKUP:
			return {"sound": "shieldup", "vibrate": 100}
		RunEvent.Kind.OBSTACLE_SMASHED:
			return {"sound": "breakobs", "vibrate": 50}
		RunEvent.Kind.TORPEDO_HIT:
			return {"sound": "breakobs", "vibrate": 0}
		RunEvent.Kind.ZONE_WARNING:
			return {"sound": "warning", "vibrate": 50}
		RunEvent.Kind.BONUS_PICKUP:
			return {"sound": "charge", "vibrate": 200}
		RunEvent.Kind.BONUS_FIRED:
			if bonus == SurvivalRun.Bonus.QUAKE:
				return NONE
			return {"sound": "phase", "vibrate": 0}
		RunEvent.Kind.QUAKE:
			return {"sound": "shockwave", "vibrate": 300}
		RunEvent.Kind.PLASMA_TOUCHED:
			return {"sound": "powerdown", "vibrate": 100}
		RunEvent.Kind.TORPEDO_FIRED:
			return {"sound": "torpedo", "vibrate": 50}
		RunEvent.Kind.RECHARGED:
			return {"sound": "shieldup", "vibrate": 150}
		RunEvent.Kind.PHASE_STARTED:
			return {"sound": "phase", "vibrate": 150}
		RunEvent.Kind.CRASH:
			return {"sound": "crash", "vibrate": 500}
		RunEvent.Kind.RACE_FINISHED:
			return {"sound": "finish", "vibrate": 0}
		RunEvent.Kind.RACE_STARTED:
			return {"sound": "start", "vibrate": 0}
		RunEvent.Kind.CONTINUED:
			return {"sound": "shockwave", "vibrate": 300}
	return NONE
