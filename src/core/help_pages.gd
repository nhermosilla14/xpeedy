class_name HelpPages
extends RefCounted
## The help pages (ADR 0032): topics, each a list of pages, each page a few short lowercase lines. The wording
## is ours. A page has at most MAX_LINES lines of at most MAX_WIDTH characters so it fits the text panel at
## 480x320; the tests keep it so.

const MAX_LINES := 6
const MAX_WIDTH := 28

const CONTENT := [
	["controls", [
		["steer with left and right:", "keys, d-pad or left stick.", "pause: esc, p or start.",
			"fire a held bonus: enter,", "space or the confirm button."],
		["recharger: q or x button.", "torpedo: w or y button.", "phase shift: e or r1.",
			"the buttons on the left edge", "also work with a tap."],
		["settings (the gear icon):", "invert steering, button", "layout nintendo or xbox,", "sound, music and vibration."],
	]],
	["obstacles", [
		["trails on the track warn you", "of what is coming. red means", "it is close to your lane.", "touching an obstacle ends",
			"the run unless a shield", "can smash it."],
		["cube and spike: one shield.", "beam: two shields; with one", "you crash. inside a tube a", "beam also blocks the far",
			"side of the tunnel."],
		["roller: tumbles sideways", "from lane to lane.", "bouncer: slides up and down", "from its tile; dangerous",
			"only while low.", "smashing them pays more."],
	]],
	["shields", [
		["orange spots give a shield.", "the bar at the bottom right", "shows your shields; they", "fade with time.",
			"smash obstacles with them", "for points."],
	]],
	["bonuses", [
		["coloured spots give bonuses.", "hold one at a time; fire it", "with enter, space or a tap.",
			"a spot picked up while you", "hold one does nothing."],
		["quake (red): destroys every", "obstacle in view, free.", "time dilation (blue): slows", "everything for seven",
			"seconds; rollers and", "bouncers freeze."],
		["space fold (green): ends the", "zone that is active.", "plasma throws away the", "bonus you hold."],
	]],
	["zones", [
		["a ring across the track", "starts a three second", "warning, then a zone lasts", "seven seconds. space fold",
			"ends it early."],
		["blackout: trails vanish.", "gravity well: a force pushes", "you sideways; counter-steer.", "hue shift: lanes change",
			"colour and hide trails."],
		["dark nebula: the track", "pulses dark and light.", "plasma cloud: avoid the blue", "vortices; they cost a shield",
			"and your bonus."],
	]],
	["upgrades", [
		["the shop is on the main", "menu. credits come from", "finishing new stage races", "and from survival scores.",
			"levels unlock as you", "finish more races."],
		["flow: slower stage races.", "fractal: shields fade more", "slowly. modulator: more", "shields in stage races.",
			"they start with three."],
		["recharger: shields, once.", "torpedo: clears the lane", "ahead for no points.", "phase shift: fly through",
			"obstacles for a while.", "none in extreme or pure."],
	]],
	["modes", [
		["survival: an endless run on", "a random track. pick casual,", "easy, standard, extreme or", "pure; each keeps its own",
			"best score."],
		["single: four stages of", "twelve races. finish a race", "to open the next; a crash", "resets your stage score.",
			"finish all twelve for a", "stage best."],
		["keep going: after an", "obstacle crash you can pay", "one credit to continue", "once per run."],
	]],
]


static func topics() -> Array[String]:
	var names: Array[String] = []
	for entry in CONTENT:
		names.append(entry[0])
	return names


## The pages of a topic: an array of pages, each an array of lines.
static func pages(topic: String) -> Array:
	for entry in CONTENT:
		if entry[0] == topic:
			return entry[1]
	return []
