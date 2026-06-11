extends Node

# ── Hypothesis categories (shown to player) ───────────────────────────────────
const HYPOTHESIS_CATEGORIES: Dictionary = {
	"RADIATION_EVENT":        "Solar or cosmic radiation event damaged spacecraft systems",
	"PHYSICAL_IMPACT":        "Debris or micrometeorite strike caused structural damage",
	"SOFTWARE_ANOMALY":       "Software or firmware fault caused cascading system failures",
	"COMMUNICATION_FAILURE":  "Signal degradation or antenna fault led to loss of contact",
	"ENGINEERING_DEFICIENCY": "Design, manufacturing, or component flaw caused premature failure",
}

# Maps internal incident id → hypothesis category (internal, not shown directly)
const INCIDENT_TO_HYPOTHESIS: Dictionary = {
	"solar_storm":     "RADIATION_EVENT",
	"micrometeorite":  "PHYSICAL_IMPACT",
	"software_glitch": "SOFTWARE_ANOMALY",
	"comms_noise":     "COMMUNICATION_FAILURE",
	"thruster_anomaly": "ENGINEERING_DEFICIENCY",
	"component_wear":  "ENGINEERING_DEFICIENCY",
}

# Correct hypothesis → tech recommendations
const HYPOTHESIS_TO_TECH: Dictionary = {
	"RADIATION_EVENT":        ["radiation_shielding"],
	"PHYSICAL_IMPACT":        ["hull_reinforcement"],
	"SOFTWARE_ANOMALY":       ["fault_tolerant_software"],
	"COMMUNICATION_FAILURE":  ["redundant_comms"],
	"ENGINEERING_DEFICIENCY": [],
}

# Symptom strings per incident — describe EFFECTS, not causes
const INCIDENT_SYMPTOMS: Dictionary = {
	"solar_storm": [
		"Radiation flux anomaly detected across primary power bus.",
		"Power subsystem output dropped 18–24% following thermal event.",
		"Signal-to-noise ratio degraded 4 minutes after solar panel anomaly.",
		"Voltage spikes recorded across multiple primary circuits.",
		"Solar array output became erratic. Battery draw increased.",
	],
	"micrometeorite": [
		"Structural vibration sensor recorded a 0.8g transient impact event.",
		"Thermal regulation anomaly detected on hull exterior panel.",
		"Navigation gyroscope logged unexpected drift following brief mechanical event.",
		"Pressurization telemetry showed minor but sustained deviation from nominal.",
		"Unexpected mass redistribution noted by attitude control system.",
	],
	"software_glitch": [
		"Flight computer reported memory fault in guidance module.",
		"Attitude control system entered safe mode — no commanded input.",
		"Telemetry buffer overflow detected in communications processor.",
		"Autonomous recovery cycling observed. No operator action taken.",
		"Command acknowledgment latency increased 340ms beyond nominal.",
	],
	"comms_noise": [
		"Uplink signal quality fell below minimum acquisition threshold.",
		"Carrier wave showed irregular interference on primary frequency.",
		"Backup communications channel also reporting degraded signal.",
		"Ground station reported intermittent dropouts over 14-minute window.",
		"Downlink telemetry frame errors increased from 0.01% to 18.7%.",
	],
	"thruster_anomaly": [
		"Unexpected delta-V of 1.4 m/s recorded on navigation computer.",
		"Fuel consumption exceeded nominal rate by 12% with no planned maneuver.",
		"Attitude control system logged unplanned 3.2° rotation event.",
		"Orbital parameters deviated from planned trajectory by 0.08°.",
		"Thruster valve cycling detected outside of scheduled burn window.",
	],
}

# ── State ─────────────────────────────────────────────────────────────────────
var investigations: Dictionary = {}  # mission_id -> investigation dict

# ── Public API ────────────────────────────────────────────────────────────────

func open(mission: Dictionary) -> void:
	var inv_id: String = mission["id"]
	if investigations.has(inv_id):
		return
	investigations[inv_id] = _build_investigation(mission)
	EventBus.emit_signal("investigation_started", inv_id)

func submit_hypothesis(mission_id: String, hypothesis: String) -> Dictionary:
	var inv: Dictionary = investigations.get(mission_id, {})
	if inv.is_empty() or inv.get("resolved", false):
		return {}

	var root_cause: String       = inv["root_cause"]
	var correct_hyp: String      = INCIDENT_TO_HYPOTHESIS.get(root_cause, "ENGINEERING_DEFICIENCY")
	var correct: bool            = (hypothesis == correct_hyp)

	inv["resolved"]              = true
	inv["diagnosis_correct"]     = correct
	inv["submitted_hypothesis"]  = hypothesis
	if correct:
		inv["confirmed_hypothesis"] = correct_hyp  # shown only on correct

	if correct:
		GameState.change_reputation(4.0)
		EventBus.emit_signal("alert_added", {
			"date":  TimeManager.get_date_string(),
			"level": "success",
			"text":  "INVESTIGATION CLOSED: " + inv["mission_name"] + "  |  CORRECT DIAGNOSIS  |  REP +4",
		})
	else:
		GameState.change_reputation(-3.0)
		EventBus.emit_signal("alert_added", {
			"date":  TimeManager.get_date_string(),
			"level": "warning",
			"text":  "INVESTIGATION CLOSED: " + inv["mission_name"] + "  |  INCONCLUSIVE — ROOT CAUSE UNRESOLVED  |  REP -3",
		})

	var result: Dictionary = {
		"correct":            correct,
		"tech_recommendations": HYPOTHESIS_TO_TECH.get(hypothesis, []) if correct else [],
	}
	EventBus.emit_signal("investigation_completed", mission_id, result)
	return result

func resolve(mission_id: String) -> void:
	if investigations.has(mission_id):
		investigations[mission_id]["resolved"] = true
	EventBus.emit_signal("investigation_completed", mission_id, {})

func get_investigation(mission_id: String) -> Dictionary:
	return investigations.get(mission_id, {})

func has_open() -> bool:
	for id in investigations:
		if not investigations[id].get("resolved", false):
			return true
	return false

func get_open_count() -> int:
	var n: int = 0
	for id in investigations:
		if not investigations[id].get("resolved", false):
			n += 1
	return n

# ── Evidence builder ──────────────────────────────────────────────────────────

func _build_investigation(mission: Dictionary) -> Dictionary:
	var incidents: Array = mission.get("incidents", [])

	var timeline: Array = []
	timeline.append({
		"date": _date_str(mission["launch_date"]),
		"type": "normal",
		"text": "Launch vehicle separation confirmed. All systems nominal.",
	})

	var rng := RandomNumberGenerator.new()
	for inc: Dictionary in incidents:
		var pool: Array = INCIDENT_SYMPTOMS.get(inc["id"], ["Anomalous telemetry reading recorded."])
		rng.seed = hash(inc["id"] + str(inc.get("date","")))
		var available: Array = pool.duplicate()
		var count: int = min(2, available.size())
		for _i in range(count):
			var idx: int = rng.randi() % available.size()
			timeline.append({
				"date": inc.get("date", ""),
				"type": "incident",
				"text": available[idx],
			})
			available.remove_at(idx)

	timeline.append({
		"date": TimeManager.get_date_string(),
		"type": "critical",
		"text": "Telemetry link lost. Signal not recovered. Mission loss declared.",
	})

	return {
		"mission_id":      mission["id"],
		"mission_name":    mission["name"],
		"mission_def":     mission["def_id"],
		"elapsed_days":    mission.get("elapsed_days", 0),
		"total_days":      mission.get("total_days", 0),
		"opened_date":     TimeManager.get_date_string(),
		"resolved":        false,
		"diagnosis_correct": false,
		"timeline":        timeline,
		"comms":           _generate_comms(mission, incidents),
		"sensors":         _build_sensor_summary(mission),
		"root_cause":      _determine_likely_cause(incidents),  # internal only
		"total_incidents": incidents.size(),
	}

func _generate_comms(mission: Dictionary, incidents: Array) -> Array:
	var comms: Array = []
	comms.append({
		"from": "FLIGHT",
		"text": mission["name"] + " — separation confirmed. Trajectory nominal.",
	})
	comms.append({
		"from": "CAPCOM",
		"text": "Roger. All channels clean. Power nominal. Proceeding on nominal timeline.",
	})
	for inc: Dictionary in incidents:
		comms.append({
			"from": "TELEMETRY",
			"text": "[AUTO] Anomalous reading on " + mission["name"] + ". Diagnostic mode activated.",
		})
		comms.append({
			"from": "FLIGHT",
			"text": "Copy anomaly. Team evaluating. Standing by for recovery.",
		})
	comms.append({
		"from": "TELEMETRY",
		"text": "[AUTO] Signal lost. No carrier detected on primary or backup. Contact lost.",
	})
	comms.append({
		"from": "FLIGHT DIRECTOR",
		"text": "We have lost the vehicle. " + mission["name"] + " is declared lost. Begin contingency.",
	})
	return comms

func _build_sensor_summary(mission: Dictionary) -> Dictionary:
	var summary: Dictionary = {}
	for sys in mission.get("systems", {}):
		var val: float  = mission["systems"][sys]
		var status: String
		if val < 20.0:      status = "FAILED"
		elif val < 50.0:    status = "CRITICAL"
		elif val < 75.0:    status = "DEGRADED"
		else:               status = "NOMINAL"
		summary[sys] = {"value": val, "status": status}
	return summary

func _determine_likely_cause(incidents: Array) -> String:
	if incidents.is_empty():
		return "component_wear"
	var totals: Dictionary = {}
	for inc: Dictionary in incidents:
		var id: String = inc["id"]
		totals[id] = totals.get(id, 0.0) + inc.get("damage", 0.0)
	var top_id: String = ""
	var top_dmg: float = 0.0
	for id in totals:
		if totals[id] > top_dmg:
			top_dmg = totals[id]
			top_id  = id
	return top_id

func _date_str(d: Dictionary) -> String:
	const NAMES: Array[String] = ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"]
	return "%s %02d  %04d" % [NAMES[d.get("month",1) - 1], d.get("day",1), d.get("year",2025)]
