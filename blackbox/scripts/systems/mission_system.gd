extends Node

# ── Mission definitions ───────────────────────────────────────────────────────

const DEFS: Dictionary = {
	# ── LUNAR PROGRAM ─────────────────────────────────────────────────────────
	"satellite_comm": {
		"name":            "Communications Satellite",
		"name_prefix":     "COMM-SAT",
		"type":            "satellite",
		"destination":     "LOW EARTH ORBIT",
		"duration_days":   90,
		"cost":            8_000_000.0,
		"crew_required":   0,
		"reward_funding":  13_000_000.0,
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
		"reward_funding":  17_000_000.0,
		"reward_rep":      4.0,
		"fail_rep":        -6.0,
		"description":     "Deploy a weather monitoring satellite into polar orbit.",
		"incident_weights": {"solar_storm": 1.0, "software_glitch": 0.8, "micrometeorite": 0.6},
		"unlocks_on_complete": ["lunar_trajectory_study"],
	},
	"lunar_trajectory_study": {
		"name":            "Lunar Trajectory Analysis",
		"name_prefix":     "TRAJ",
		"type":            "planning",
		"destination":     "GROUND OPS",
		"duration_days":   50,
		"cost":            2_500_000.0,
		"crew_required":   0,
		"reward_funding":  3_500_000.0,
		"reward_rep":      2.0,
		"fail_rep":        -1.0,
		"description":     "Model transfer orbit mechanics and calculate viable launch windows for the lunar program.",
		"incident_weights": {},
		"unlocks_on_complete": ["hardware_procurement"],
	},
	"hardware_procurement": {
		"name":            "Deep Space Hardware Procurement",
		"name_prefix":     "PROC",
		"type":            "planning",
		"destination":     "GROUND OPS",
		"duration_days":   65,
		"cost":            4_000_000.0,
		"crew_required":   0,
		"reward_funding":  5_500_000.0,
		"reward_rep":      2.0,
		"fail_rep":        -1.0,
		"description":     "Source and qualify deep space antenna arrays, propulsion components, and radiation-hardened electronics.",
		"incident_weights": {},
		"unlocks_on_complete": ["lunar_flyby"],
	},
	"lunar_flyby": {
		"name":            "Lunar Flyby Probe",
		"name_prefix":     "LUNA-FLY",
		"type":            "probe",
		"destination":     "LUNAR VICINITY",
		"duration_days":   180,
		"cost":            25_000_000.0,
		"crew_required":   0,
		"reward_funding":  38_000_000.0,
		"reward_rep":      8.0,
		"fail_rep":        -10.0,
		"description":     "Conduct a close flyby of the lunar surface. First mission beyond Earth orbit.",
		"incident_weights": {"solar_storm": 1.4, "micrometeorite": 1.2, "software_glitch": 1.0, "unknown_signal": 1.2},
		"unlocks_on_complete": ["lunar_orbit"],
	},
	"lunar_orbit": {
		"name":            "Lunar Orbit Insertion",
		"name_prefix":     "LUNA-ORB",
		"type":            "probe",
		"destination":     "LUNAR ORBIT",
		"duration_days":   220,
		"cost":            38_000_000.0,
		"crew_required":   0,
		"reward_funding":  58_000_000.0,
		"reward_rep":      12.0,
		"fail_rep":        -14.0,
		"description":     "Execute a lunar orbit insertion burn and conduct sustained orbital mapping of the surface.",
		"incident_weights": {"solar_storm": 1.4, "micrometeorite": 1.3, "software_glitch": 1.5, "thruster_anomaly": 2.0, "trajectory_deviation": 1.8, "comms_noise": 1.2},
		"unlocks_on_complete": ["lunar_lander"],
	},
	"lunar_lander": {
		"name":            "Lunar Landing Probe",
		"name_prefix":     "LUNA-LND",
		"type":            "lander",
		"destination":     "LUNAR SURFACE",
		"duration_days":   365,
		"cost":            48_000_000.0,
		"crew_required":   0,
		"reward_funding":  70_000_000.0,
		"reward_rep":      16.0,
		"fail_rep":        -18.0,
		"description":     "Land an uncrewed probe on the lunar surface and conduct surface analysis.",
		"incident_weights": {"solar_storm": 1.5, "micrometeorite": 1.8, "software_glitch": 1.3, "thruster_anomaly": 1.5, "trajectory_deviation": 1.2},
		"unlocks_on_complete": ["lunar_sample_return"],
	},
	"lunar_sample_return": {
		"name":            "Lunar Sample Return",
		"name_prefix":     "LUNA-SMR",
		"type":            "lander",
		"destination":     "LUNAR SURFACE",
		"duration_days":   480,
		"cost":            75_000_000.0,
		"crew_required":   0,
		"reward_funding":  115_000_000.0,
		"reward_rep":      20.0,
		"fail_rep":        -22.0,
		"description":     "Land, collect regolith samples, and return the sample capsule to Earth. Closes the lunar program.",
		"incident_weights": {"solar_storm": 1.8, "micrometeorite": 2.0, "software_glitch": 1.5, "thruster_anomaly": 1.8, "trajectory_deviation": 1.5, "unknown_signal": 1.4},
		"unlocks_on_complete": ["mars_window_calc"],
	},
	# ── MARS PROGRAM ──────────────────────────────────────────────────────────
	"mars_window_calc": {
		"name":            "Mars Transfer Window Study",
		"name_prefix":     "MARS-TWC",
		"type":            "planning",
		"destination":     "GROUND OPS",
		"duration_days":   80,
		"cost":            5_000_000.0,
		"crew_required":   0,
		"reward_funding":  7_000_000.0,
		"reward_rep":      3.0,
		"fail_rep":        -2.0,
		"description":     "Calculate viable Hohmann transfer windows and crewed mission architecture for a Mars trajectory.",
		"incident_weights": {},
		"unlocks_on_complete": ["mars_reconnaissance"],
	},
	"mars_reconnaissance": {
		"name":            "Mars Reconnaissance Probe",
		"name_prefix":     "MARS-RCN",
		"type":            "probe",
		"destination":     "MARS VICINITY",
		"duration_days":   600,
		"cost":            110_000_000.0,
		"crew_required":   0,
		"reward_funding":  165_000_000.0,
		"reward_rep":      25.0,
		"fail_rep":        -28.0,
		"description":     "First probe to reach the Martian system. Survey atmosphere, radiation environment, and candidate landing sites.",
		"incident_weights": {"solar_storm": 2.2, "micrometeorite": 1.8, "software_glitch": 1.6, "thruster_anomaly": 1.8, "comms_noise": 2.0, "unknown_signal": 2.2, "trajectory_deviation": 1.6},
		"unlocks_on_complete": ["mars_orbit"],
	},
	"mars_orbit": {
		"name":            "Mars Orbital Survey",
		"name_prefix":     "MARS-ORB",
		"type":            "probe",
		"destination":     "MARS ORBIT",
		"duration_days":   720,
		"cost":            190_000_000.0,
		"crew_required":   0,
		"reward_funding":  275_000_000.0,
		"reward_rep":      30.0,
		"fail_rep":        -35.0,
		"description":     "Achieve Mars orbit insertion and conduct a sustained high-resolution mapping campaign.",
		"incident_weights": {"solar_storm": 2.4, "micrometeorite": 2.0, "software_glitch": 1.8, "thruster_anomaly": 2.2, "comms_noise": 2.2, "unknown_signal": 2.8, "trajectory_deviation": 2.2},
		"unlocks_on_complete": ["mars_lander"],
	},
	"mars_lander": {
		"name":            "Mars Surface Lander",
		"name_prefix":     "MARS-LND",
		"type":            "lander",
		"destination":     "MARS SURFACE",
		"duration_days":   900,
		"cost":            320_000_000.0,
		"crew_required":   0,
		"reward_funding":  520_000_000.0,
		"reward_rep":      45.0,
		"fail_rep":        -50.0,
		"description":     "Land a surface station on Mars. The final objective of the Mars program.",
		"incident_weights": {"solar_storm": 2.8, "micrometeorite": 2.4, "software_glitch": 2.2, "thruster_anomaly": 2.6, "comms_noise": 2.5, "unknown_signal": 3.5, "trajectory_deviation": 2.8},
		"unlocks_on_complete": [],
	},
}

# ── Mission configuration options ────────────────────────────────────────────

const CONFIG_OPTIONS: Dictionary = {
	"power": {
		"standard": {"label": "Standard Solar Array", "extra_cost": 0.0,         "mods": {}},
		"hardened": {"label": "Hardened Power Array",  "extra_cost": 2_000_000.0, "mods": {"solar_storm": 0.55}},
	},
	"comms": {
		"standard":  {"label": "Standard Antenna",    "extra_cost": 0.0,         "mods": {}},
		"redundant": {"label": "Redundant Comm Array", "extra_cost": 3_000_000.0, "mods": {"comms_noise": 0.4, "software_glitch": 0.85}},
	},
	"nav": {
		"standard":  {"label": "Standard Computer",  "extra_cost": 0.0,         "mods": {}},
		"redundant": {"label": "Redundant Computer", "extra_cost": 2_000_000.0, "mods": {"software_glitch": 0.5, "thruster_anomaly": 0.7}},
	},
	"testing": {
		"basic":    {"label": "Basic Checkout",    "extra_cost": 0.0,         "mods": {}},
		"extended": {"label": "Extended Protocol", "extra_cost": 1_500_000.0, "mods": {"solar_storm": 0.88, "software_glitch": 0.85, "comms_noise": 0.85, "micrometeorite": 0.88, "thruster_anomaly": 0.85}},
	},
	"trajectory": {
		"conservative": {"label": "Conservative Route  (+25% duration)", "extra_cost": 2_000_000.0, "duration_mult": 1.25, "mods": {"solar_storm": 0.80, "micrometeorite": 0.75, "thruster_anomaly": 0.65, "unknown_signal": 0.70, "trajectory_deviation": 0.65}},
		"standard":     {"label": "Standard Transfer",                   "extra_cost": 0.0,         "duration_mult": 1.0,  "mods": {}},
		"fast_burn":    {"label": "Direct Fast Burn  (-30% duration)",   "extra_cost": -1_000_000.0,"duration_mult": 0.70, "mods": {"thruster_anomaly": 2.00, "micrometeorite": 1.50, "solar_storm": 1.25, "trajectory_deviation": 1.80}},
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

func config_extra_cost(config: Dictionary) -> float:
	var total: float = 0.0
	for cat: String in config:
		var opt: Dictionary = CONFIG_OPTIONS.get(cat, {}).get(config[cat], {})
		total += opt.get("extra_cost", 0.0)
	return total

func _build_config_modifiers(config: Dictionary) -> Dictionary:
	var mods: Dictionary = {}
	for cat: String in config:
		var opt: Dictionary = CONFIG_OPTIONS.get(cat, {}).get(config[cat], {})
		for inc_id: String in opt.get("mods", {}):
			mods[inc_id] = mods.get(inc_id, 1.0) * opt["mods"][inc_id]
	return mods

func launch(def_id: String, config: Dictionary = {}) -> Dictionary:
	if not DEFS.has(def_id):
		return {}
	if has_active_of_type(def_id):
		return {}
	var def: Dictionary   = DEFS[def_id]
	var total_cost: float = def["cost"] + config_extra_cost(config)
	if not GameState.spend_funding(total_cost):
		return {}

	if not _name_counters.has(def_id):
		_name_counters[def_id] = 0
	_name_counters[def_id] += 1
	var mission_name: String = "%s-%02d" % [def["name_prefix"], _name_counters[def_id]]

	var traj_id: String    = config.get("trajectory", "standard")
	var traj_opt: Dictionary = CONFIG_OPTIONS.get("trajectory", {}).get(traj_id, {})
	var duration_mult: float = traj_opt.get("duration_mult", 1.0)

	var m: Dictionary = {
		"id":               str(_next_id),
		"def_id":           def_id,
		"name":             mission_name,
		"type":             def.get("type", "mission"),
		"status":           "active",
		"launch_date":      TimeManager.get_date(),
		"elapsed_days":     0,
		"total_days":       int(def["duration_days"] * duration_mult),
		"health":           100.0,
		"incidents":        [],
		"config":             config.duplicate(),
		"config_modifiers":   _build_config_modifiers(config),
		"decision_modifiers": {},
		"resolved_decisions": [],
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
