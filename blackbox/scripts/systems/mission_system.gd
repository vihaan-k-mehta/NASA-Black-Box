extends Node

# ── Mission definitions ───────────────────────────────────────────────────────

const DEFS: Dictionary = {
	"satellite_comm": {
		"name":            "Communications Satellite",
		"name_prefix":     "COMM-SAT",
		"type":            "satellite",
		"destination":     "LOW EARTH ORBIT",
		"duration_days":   90,
		"cost":            8_000_000.0,
		"crew_required":   0,
		"reward_funding":  12_000_000.0,
		"reward_rep":      3.0,
		"fail_rep":        -5.0,
		"description":     "Deploy a communications satellite into low Earth orbit.",
		"incident_weights": {"solar_storm": 1.0, "software_glitch": 1.2, "comms_noise": 1.5},
		"unlocks_on_complete": ["satellite_weather"],
	},
	"satellite_weather": {
		"name":            "Weather Monitoring Satellite",
		"name_prefix":     "WEATHER",
		"type":            "satellite",
		"destination":     "POLAR ORBIT",
		"duration_days":   120,
		"cost":            10_000_000.0,
		"crew_required":   0,
		"reward_funding":  16_000_000.0,
		"reward_rep":      4.0,
		"fail_rep":        -6.0,
		"description":     "Deploy a weather monitoring satellite into polar orbit.",
		"incident_weights": {"solar_storm": 1.0, "software_glitch": 0.8, "micrometeorite": 0.6},
		"unlocks_on_complete": ["lunar_flyby"],
	},
	"lunar_flyby": {
		"name":            "Lunar Flyby Probe",
		"name_prefix":     "LUNA-FLY",
		"type":            "probe",
		"destination":     "LUNAR ORBIT",
		"duration_days":   180,
		"cost":            25_000_000.0,
		"crew_required":   0,
		"reward_funding":  35_000_000.0,
		"reward_rep":      8.0,
		"fail_rep":        -10.0,
		"description":     "Conduct a flyby survey of the lunar surface. First mission beyond Earth orbit.",
		"incident_weights": {"solar_storm": 1.4, "micrometeorite": 1.2, "software_glitch": 1.0},
		"unlocks_on_complete": ["lunar_lander"],
	},
	"lunar_lander": {
		"name":            "Lunar Landing Probe",
		"name_prefix":     "LUNA-LND",
		"type":            "lander",
		"destination":     "LUNAR SURFACE",
		"duration_days":   365,
		"cost":            45_000_000.0,
		"crew_required":   0,
		"reward_funding":  55_000_000.0,
		"reward_rep":      15.0,
		"fail_rep":        -18.0,
		"description":     "Land an uncrewed probe on the lunar surface and conduct surface analysis.",
		"incident_weights": {"solar_storm": 1.5, "micrometeorite": 1.8, "software_glitch": 1.2, "thruster_anomaly": 1.0},
		"unlocks_on_complete": [],
	},
}

# ── State ─────────────────────────────────────────────────────────────────────

var missions: Array = []
var _next_id: int = 0
var _name_counters: Dictionary = {}

# ── Init ──────────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.time_advanced.connect(_on_time_advanced)

# ── Public API ────────────────────────────────────────────────────────────────

func has_active_of_type(def_id: String) -> bool:
	for m: Dictionary in missions:
		if m["def_id"] == def_id and m["status"] == "active":
			return true
	return false

func launch(def_id: String) -> Dictionary:
	if not DEFS.has(def_id):
		return {}
	if has_active_of_type(def_id):
		return {}
	var def: Dictionary = DEFS[def_id]
	if not GameState.spend_funding(def["cost"]):
		return {}

	if not _name_counters.has(def_id):
		_name_counters[def_id] = 0
	_name_counters[def_id] += 1
	var mission_name: String = "%s-%02d" % [def["name_prefix"], _name_counters[def_id]]

	var m: Dictionary = {
		"id":           str(_next_id),
		"def_id":       def_id,
		"name":         mission_name,
		"status":       "active",
		"launch_date":  TimeManager.get_date(),
		"elapsed_days": 0,
		"total_days":   def["duration_days"],
		"health":       100.0,
		"incidents":    [],
		"systems": {
			"power":          100.0,
			"communications": 100.0,
			"navigation":     100.0,
			"structure":      100.0,
			"thermal":        100.0,
		},
	}
	_next_id += 1
	missions.append(m)
	EventBus.emit_signal("mission_launched", m)
	EventBus.emit_signal("alert_added", {
		"date":  TimeManager.get_date_string(),
		"level": "info",
		"text":  "LAUNCHED: " + mission_name + "  →  " + def["destination"],
	})
	return m

func get_active() -> Array:
	return missions.filter(func(m): return m["status"] == "active")

func get_mission(mission_id: String) -> Dictionary:
	for m in missions:
		if m["id"] == mission_id:
			return m
	return {}

# ── Time tick ─────────────────────────────────────────────────────────────────

func _on_time_advanced(_date: Dictionary) -> void:
	for m in missions:
		if m["status"] != "active":
			continue
		m["elapsed_days"] += 1
		# Passive component wear
		_apply_health_delta(m, -0.015, "structure")
		_check_outcome(m)

func _apply_health_delta(m: Dictionary, delta: float, system: String = "") -> void:
	m["health"] = clamp(m["health"] + delta, 0.0, 100.0)
	if system != "" and m["systems"].has(system):
		m["systems"][system] = clamp(m["systems"][system] + delta * 2.0, 0.0, 100.0)
	EventBus.emit_signal("mission_updated", m)

func apply_incident_damage(mission_id: String, damage: float, systems_hit: Array) -> void:
	var m: Dictionary = get_mission(mission_id)
	if m.is_empty():
		return
	m["health"] = clamp(m["health"] - damage, 0.0, 100.0)
	for sys in systems_hit:
		if m["systems"].has(sys):
			m["systems"][sys] = clamp(m["systems"][sys] - damage * 1.5, 0.0, 100.0)
	EventBus.emit_signal("mission_updated", m)
	_check_outcome(m)

func _check_outcome(m: Dictionary) -> void:
	if m["health"] <= 0.0:
		_fail(m)
	elif m["elapsed_days"] >= m["total_days"]:
		_complete(m)

func _complete(m: Dictionary) -> void:
	m["status"] = "completed"
	var def: Dictionary = DEFS[m["def_id"]]
	GameState.add_funding(def["reward_funding"])
	GameState.change_reputation(def["reward_rep"])
	GameState.record_completion(m["def_id"])
	for unlock_id in def.get("unlocks_on_complete", []):
		if GameState.completion_count(m["def_id"]) == 1:
			GameState.unlock_mission(unlock_id)
	EventBus.emit_signal("mission_completed", m)
	EventBus.emit_signal("alert_added", {
		"date":  TimeManager.get_date_string(),
		"level": "success",
		"text":  "MISSION COMPLETE: " + m["name"] + "  |  +" + _fmt_funds(def["reward_funding"]) + "  |  REP +" + str(int(def["reward_rep"])),
	})

func _fail(m: Dictionary) -> void:
	m["status"] = "failed"
	var def: Dictionary = DEFS[m["def_id"]]
	GameState.change_reputation(def["fail_rep"])
	InvestigationSystem.open(m)
	EventBus.emit_signal("mission_failed", m)
	EventBus.emit_signal("alert_added", {
		"date":  TimeManager.get_date_string(),
		"level": "critical",
		"text":  "MISSION FAILED: " + m["name"] + "  |  INVESTIGATION REQUIRED  |  REP " + str(int(def["fail_rep"])),
	})

func _fmt_funds(amount: float) -> String:
	if amount >= 1_000_000.0:
		return "$%.1fM" % (amount / 1_000_000.0)
	return "$%d" % int(amount)
