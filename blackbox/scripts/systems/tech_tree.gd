extends Node

const TECHS: Dictionary = {
	"radiation_shielding": {
		"name":        "Radiation Shielding",
		"category":    "Protection",
		"cost":        5_000_000.0,
		"description": "Advanced shielding reduces solar storm damage by 50%.",
		"prerequisites": [],
		"incident_modifiers": {"solar_storm": 0.5},
	},
	"redundant_comms": {
		"name":        "Redundant Communications",
		"category":    "Communications",
		"cost":        4_000_000.0,
		"description": "Backup antennas reduce communications incident probability by 40%.",
		"prerequisites": [],
		"incident_modifiers": {"comms_noise": 0.6},
	},
	"hull_reinforcement": {
		"name":        "Hull Reinforcement",
		"category":    "Structure",
		"cost":        6_000_000.0,
		"description": "Micrometeorite shielding reduces impact damage by 55%.",
		"prerequisites": [],
		"incident_modifiers": {"micrometeorite": 0.45},
	},
	"fault_tolerant_software": {
		"name":        "Fault-Tolerant Software",
		"category":    "Software",
		"cost":        4_500_000.0,
		"description": "Watchdog systems reduce software anomaly frequency by 45%.",
		"prerequisites": [],
		"incident_modifiers": {"software_glitch": 0.55},
	},
	"autonomous_diagnostics": {
		"name":        "Autonomous Diagnostics",
		"category":    "Software",
		"cost":        8_000_000.0,
		"description": "AI-driven self-repair reduces all incident probabilities by 20%.",
		"prerequisites": ["fault_tolerant_software"],
		"incident_modifiers": {},
		"global_modifier": 0.80,
	},
}

var _unlocked: Array[String] = []

func is_unlocked(tech_id: String) -> bool:
	return tech_id in _unlocked

func can_research(tech_id: String) -> bool:
	if is_unlocked(tech_id):
		return false
	if not TECHS.has(tech_id):
		return false
	for prereq in TECHS[tech_id]["prerequisites"]:
		if not is_unlocked(prereq):
			return false
	return true

func research(tech_id: String) -> bool:
	if not can_research(tech_id):
		return false
	var cost: float = TECHS[tech_id]["cost"]
	if not GameState.spend_funding(cost):
		return false
	_unlocked.append(tech_id)
	EventBus.emit_signal("tech_unlocked", tech_id)
	EventBus.emit_signal("alert_added", {
		"date":  TimeManager.get_date_string(),
		"level": "success",
		"text":  "RESEARCH COMPLETE: " + TECHS[tech_id]["name"].to_upper(),
	})
	return true

# Returns a probability multiplier for a given incident type
func get_incident_modifier(incident_id: String) -> float:
	var mult: float = 1.0
	for tech_id in _unlocked:
		var tech: Dictionary = TECHS[tech_id]
		if tech.has("global_modifier"):
			mult *= tech["global_modifier"]
		var mods: Dictionary = tech.get("incident_modifiers", {})
		if mods.has(incident_id):
			mult *= mods[incident_id]
	return mult
