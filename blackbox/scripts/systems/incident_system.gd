extends Node

# ── Incident catalogue ────────────────────────────────────────────────────────

const INCIDENTS: Dictionary = {
	"solar_storm": {
		"name":             "Solar Storm",
		"category":         "environmental",
		"prob_per_day":     0.003,
		"damage_min":       10.0,
		"damage_max":       22.0,
		"systems_affected": ["power", "communications"],
		"fatal_threshold":  0.0,
		"description":      "A solar flare has impacted the spacecraft with elevated radiation.",
	},
	"micrometeorite": {
		"name":             "Micrometeorite Impact",
		"category":         "physical",
		"prob_per_day":     0.002,
		"damage_min":       5.0,
		"damage_max":       14.0,
		"systems_affected": ["structure", "thermal"],
		"fatal_threshold":  0.0,
		"description":      "A micrometeorite has struck the spacecraft hull.",
	},
	"software_glitch": {
		"name":             "Software Anomaly",
		"category":         "software",
		"prob_per_day":     0.004,
		"damage_min":       6.0,
		"damage_max":       16.0,
		"systems_affected": ["navigation", "communications"],
		"fatal_threshold":  0.0,
		"description":      "An unrecoverable software fault has been detected in the flight computer.",
	},
	"comms_noise": {
		"name":             "Communications Degradation",
		"category":         "electrical",
		"prob_per_day":     0.005,
		"damage_min":       3.0,
		"damage_max":       9.0,
		"systems_affected": ["communications"],
		"fatal_threshold":  0.0,
		"description":      "Signal interference has degraded the communications link.",
	},
	"thruster_anomaly": {
		"name":             "Thruster Anomaly",
		"category":         "propulsion",
		"prob_per_day":     0.002,
		"damage_min":       8.0,
		"damage_max":       20.0,
		"systems_affected": ["navigation", "structure"],
		"fatal_threshold":  0.0,
		"description":      "An unplanned thruster firing has altered the mission trajectory.",
	},
}

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	EventBus.time_advanced.connect(_on_time_advanced)

func _on_time_advanced(_date: Dictionary) -> void:
	for mission in MissionSystem.get_active():
		_roll_mission(mission)

func _roll_mission(mission: Dictionary) -> void:
	var def: Dictionary = MissionSystem.DEFS.get(mission["def_id"], {})
	var weights: Dictionary = def.get("incident_weights", {})

	for inc_id in INCIDENTS:
		var inc: Dictionary = INCIDENTS[inc_id]

		# Check if this mission type even exposes this incident
		var weight: float = weights.get(inc_id, 0.5)
		var prob: float   = inc["prob_per_day"] * weight

		# Tech tree can reduce probabilities
		prob *= TechTree.get_incident_modifier(inc_id)

		if _rng.randf() > prob:
			continue

		var damage: float = _rng.randf_range(inc["damage_min"], inc["damage_max"])
		# Damaged spacecraft are more vulnerable
		var vuln: float = 1.0 + (1.0 - mission["health"] / 100.0) * 0.5
		damage *= vuln

		var event: Dictionary = {
			"id":          inc_id,
			"name":        inc["name"],
			"date":        TimeManager.get_date_string(),
			"date_raw":    TimeManager.get_date(),
			"damage":      damage,
			"systems":     inc["systems_affected"].duplicate(),
			"description": inc["description"],
			"mission_id":  mission["id"],
			"mission_name": mission["name"],
		}
		mission["incidents"].append(event)

		MissionSystem.apply_incident_damage(mission["id"], damage, inc["systems_affected"])
		EventBus.emit_signal("incident_occurred", mission["id"], event)

		var level: String = "warning"
		if mission["health"] < 30.0:
			level = "critical"
		elif mission["health"] < 60.0:
			level = "warning"
		else:
			level = "info"

		EventBus.emit_signal("alert_added", {
			"date":  TimeManager.get_date_string(),
			"level": level,
			"text":  "ANOMALY DETECTED: " + mission["name"] + "  |  HEALTH " + str(int(mission["health"])) + "%  |  AFFECTED: " + ", ".join(inc["systems_affected"]).to_upper(),
		})
