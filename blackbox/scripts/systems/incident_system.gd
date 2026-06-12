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

# ── Decision catalogue ────────────────────────────────────────────────────────

const DECISIONS: Array[Dictionary] = [
	{
		"id": "power_fluctuation",
		"prob_per_day": 0.018,
		"title": "POWER ANOMALY",
		"situation": "Flight computer reports irregular voltage on the secondary power bus. Source is unconfirmed.",
		"options": [
			{"label": "REDUCE SECONDARY POWER",  "health_delta": -3.0, "mods": {"solar_storm": 0.60}},
			{"label": "MAINTAIN NORMAL OPS",      "health_delta":  0.0, "mods": {"solar_storm": 1.40}},
		],
	},
	{
		"id": "comms_interference",
		"prob_per_day": 0.016,
		"title": "UPLINK INTERFERENCE",
		"situation": "Intermittent interference on the primary uplink. Backup antenna available but lower bandwidth.",
		"options": [
			{"label": "SWITCH TO BACKUP ANTENNA",  "health_delta": -1.0, "mods": {"comms_noise": 0.40}},
			{"label": "ATTEMPT PRIMARY RECOVERY",  "health_delta":  0.0, "mods": {"comms_noise": 1.60}},
		],
	},
	{
		"id": "guidance_fault",
		"prob_per_day": 0.015,
		"title": "GUIDANCE FAULT",
		"situation": "Memory fault logged in guidance module. Reboot clears it but causes a 4-minute navigation gap.",
		"options": [
			{"label": "COMMAND REBOOT",      "health_delta": -2.0, "mods": {"software_glitch": 0.50}},
			{"label": "CONTINUE MONITORING", "health_delta":  0.0, "mods": {"software_glitch": 1.50}},
		],
	},
	{
		"id": "debris_field",
		"prob_per_day": 0.012,
		"title": "DEBRIS FIELD AHEAD",
		"situation": "Radar detects debris on current trajectory. Evasive burn clears the zone at a fuel cost.",
		"options": [
			{"label": "EXECUTE EVASIVE BURN",  "health_delta": -4.0, "mods": {"micrometeorite": 0.20}},
			{"label": "MAINTAIN TRAJECTORY",   "health_delta":  0.0, "mods": {"micrometeorite": 2.50}},
		],
	},
	{
		"id": "thermal_spike",
		"prob_per_day": 0.014,
		"title": "THERMAL ALERT",
		"situation": "Port panel thermal sensors showing elevated readings. Cooling protocol available.",
		"options": [
			{"label": "ACTIVATE COOLING",    "health_delta": -2.0, "mods": {"solar_storm": 0.75, "micrometeorite": 0.80}},
			{"label": "PASSIVE MONITORING",  "health_delta":  0.0, "mods": {"solar_storm": 1.30}},
		],
	},
]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	EventBus.time_advanced.connect(_on_time_advanced)

func _on_time_advanced(_date: Dictionary) -> void:
	for mission in MissionSystem.get_active():
		_roll_decisions(mission)
		_roll_mission(mission)

func _roll_decisions(mission: Dictionary) -> void:
	var resolved: Array = mission.get("resolved_decisions", [])
	for dec: Dictionary in DECISIONS:
		if dec["id"] in resolved:
			continue
		if _rng.randf() > dec["prob_per_day"]:
			continue
		mission["resolved_decisions"].append(dec["id"])
		TimeManager.pause()
		EventBus.emit_signal("decision_required", mission["id"], dec)
		return  # one decision at a time

func _roll_mission(mission: Dictionary) -> void:
	var def: Dictionary = MissionSystem.DEFS.get(mission["def_id"], {})
	var weights: Dictionary = def.get("incident_weights", {})

	for inc_id in INCIDENTS:
		var inc: Dictionary = INCIDENTS[inc_id]

		# Check if this mission type even exposes this incident
		var weight: float = weights.get(inc_id, 0.5)
		var prob: float   = inc["prob_per_day"] * weight

		prob *= TechTree.get_incident_modifier(inc_id)
		prob *= mission.get("config_modifiers", {}).get(inc_id, 1.0)
		prob *= mission.get("decision_modifiers", {}).get(inc_id, 1.0)

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

func resolve_decision(mission_id: String, decision_id: String, option_idx: int) -> void:
	var mission: Dictionary = MissionSystem.get_mission(mission_id)
	if mission.is_empty():
		return

	var dec: Dictionary = {}
	for d: Dictionary in DECISIONS:
		if d["id"] == decision_id:
			dec = d
			break
	if dec.is_empty():
		return

	var opt: Dictionary = dec["options"][option_idx]

	# Apply health delta
	var health_delta: float = opt.get("health_delta", 0.0)
	if health_delta != 0.0:
		MissionSystem.apply_incident_damage(mission_id, -health_delta, [])

	# Merge decision modifiers (multiplicative)
	for inc_id: String in opt.get("mods", {}):
		mission["decision_modifiers"][inc_id] = \
			mission["decision_modifiers"].get(inc_id, 1.0) * opt["mods"][inc_id]

	EventBus.emit_signal("decision_resolved", mission_id, decision_id)
	EventBus.emit_signal("alert_added", {
		"date":  TimeManager.get_date_string(),
		"level": "info",
		"text":  mission["name"] + "  |  DECISION: " + opt["label"],
	})
	TimeManager.unpause()
