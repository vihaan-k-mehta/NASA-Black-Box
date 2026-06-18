extends Node

# ── Hypothesis categories (shown to player) ───────────────────────────────────
const HYPOTHESIS_CATEGORIES: Dictionary = {
	"RADIATION_EVENT":        "Solar or cosmic radiation event damaged spacecraft systems",
	"PHYSICAL_IMPACT":        "Debris or micrometeorite strike caused structural damage",
	"SOFTWARE_ANOMALY":       "Software or firmware fault caused cascading system failures",
	"COMMUNICATION_FAILURE":  "Signal degradation or antenna fault led to loss of contact",
	"ENGINEERING_DEFICIENCY": "Design, manufacturing, or component flaw caused premature failure",
	"UNKNOWN_PHENOMENON":     "No conventional explanation fits the observed telemetry profile",
}

# Maps internal incident id → hypothesis category (internal, not shown directly)
const INCIDENT_TO_HYPOTHESIS: Dictionary = {
	"solar_storm":          "RADIATION_EVENT",
	"micrometeorite":       "PHYSICAL_IMPACT",
	"software_glitch":      "SOFTWARE_ANOMALY",
	"comms_noise":          "COMMUNICATION_FAILURE",
	"thruster_anomaly":     "ENGINEERING_DEFICIENCY",
	"component_wear":       "ENGINEERING_DEFICIENCY",
	"unknown_signal":       "UNKNOWN_PHENOMENON",
	"trajectory_deviation": "UNKNOWN_PHENOMENON",
}

# Correct hypothesis → tech recommendations
const HYPOTHESIS_TO_TECH: Dictionary = {
	"RADIATION_EVENT":        ["radiation_shielding"],
	"PHYSICAL_IMPACT":        ["hull_reinforcement"],
	"SOFTWARE_ANOMALY":       ["fault_tolerant_software"],
	"COMMUNICATION_FAILURE":  ["redundant_comms"],
	"ENGINEERING_DEFICIENCY": [],
	"UNKNOWN_PHENOMENON":     ["forensic_lab", "signal_decoder", "telemetry_suite"],
}

# Crew voice log dialogue per incident — hints at what's happening, never names it
const CREW_DIALOGUE: Dictionary = {
	"solar_storm": [
		{"from": "CDR",    "text": "Houston, panel readings are off. Nothing alarming yet but something's different out here."},
		{"from": "CAPCOM", "text": "Copy CDR. We're tracking elevated solar activity in your region. Keep monitoring."},
		{"from": "MS1",    "text": "Commander, secondary array just dropped. Battery's compensating but it's working overtime."},
		{"from": "CDR",    "text": "Power bus is fluctuating. Not losing it but the variance is outside anything I've seen."},
		{"from": "CAPCOM", "text": "We see it. Running numbers now. Do not execute any burns until we clear this."},
	],
	"micrometeorite": [
		{"from": "CDR",    "text": "Houston we heard something. A sharp sound, like someone knocked on the hull."},
		{"from": "CAPCOM", "text": "Say again? Are you declaring an emergency?"},
		{"from": "CDR",    "text": "Negative. No alarms. But nav is showing a slight drift. Correcting now."},
		{"from": "PLT",    "text": "Thermal sensors on sector four are reading high. Wasn't there a minute ago."},
		{"from": "CDR",    "text": "Yeah I see it. Trying to isolate the source. Pressure's holding for now."},
	],
	"software_glitch": [
		{"from": "MS1",    "text": "Flight computer just rebooted itself. Wasn't scheduled."},
		{"from": "CAPCOM", "text": "Copy that. Did it come back clean?"},
		{"from": "MS1",    "text": "Looks like it but attitude control isn't responding normally. Not taking commands."},
		{"from": "CDR",    "text": "Third time this hour. Running through the reset procedure again."},
		{"from": "CAPCOM", "text": "Stand by. We're pushing a patch from down here."},
	],
	"comms_noise": [
		{"from": "CDR",    "text": "Houston, are you receiving? Signal seems degraded on our end."},
		{"from": "CAPCOM", "text": "You're breaking up. Say again?"},
		{"from": "CDR",    "text": "Switching to backup frequency. Something's wrong with the link."},
		{"from": "CAPCOM", "text": "Backup showing the same. We're losing you. Stand by."},
		{"from": "CDR",    "text": "Copy. We're still here. Just... can't reach you clearly."},
	],
	"thruster_anomaly": [
		{"from": "CDR",    "text": "Houston, we've had an unexpected burn. About 1.4 meters per second. Unplanned."},
		{"from": "CAPCOM", "text": "Copy, we're seeing the trajectory deviation on our end."},
		{"from": "PLT",    "text": "Thrusters are cycling on their own. I haven't touched the controls."},
		{"from": "CDR",    "text": "Fuel consumption is up. If this keeps going we're going to have a real problem."},
		{"from": "CAPCOM", "text": "Understood. Running failure scenarios now. Do not attempt manual override yet."},
	],
	"component_wear": [
		{"from": "CDR",    "text": "Houston, systems are nominal but something feels off. Hard to put my finger on it."},
		{"from": "CAPCOM", "text": "Nothing alarming from down here. Can you be more specific?"},
		{"from": "PLT",    "text": "Performance is just... slightly below where it should be. Across the board."},
		{"from": "CDR",    "text": "It's like the vehicle is tired. Nothing critical. Just worn."},
		{"from": "CAPCOM", "text": "Copy. Flag it for post-mission review. Continue nominal ops."},
	],
	"unknown_signal": [
		{"from": "MS1",    "text": "Houston, we're receiving a signal. It's not on any of our frequencies."},
		{"from": "CAPCOM", "text": "Say again. What frequency?"},
		{"from": "MS1",    "text": "That's the thing. Our equipment shouldn't even be able to receive this. It doesn't match anything in the catalog."},
		{"from": "CDR",    "text": "It's structured. I don't know how else to say it. This isn't noise."},
		{"from": "CAPCOM", "text": "Stand by. We're looking into it."},
	],
	"trajectory_deviation": [
		{"from": "CDR",    "text": "Houston, we have a trajectory deviation. No burns were commanded."},
		{"from": "CAPCOM", "text": "We see it. Thruster logs show zero activity. What is your current status?"},
		{"from": "CDR",    "text": "No commanded burns. No unplanned venting. Nothing. We just... moved."},
		{"from": "PLT",    "text": "Navigation is trying to compensate but we're not getting normal response."},
		{"from": "CDR",    "text": "Houston, something pushed us. I don't know what else to call it."},
	],
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
	"unknown_signal": [
		"Unidentified RF signal received on frequency outside the published catalog.",
		"Signal showed modulated pattern inconsistent with any natural radio source.",
		"Communications array logged autonomous directional lock on unidentified origin.",
		"Navigation computer registered an unexplained heading suggestion during the signal window.",
		"Received signal contains repeating structure at 13.7-second intervals.",
	],
	"trajectory_deviation": [
		"Navigation log confirms 0.22° heading change with zero thruster activity.",
		"IMU recorded 1.8 m/s delta-V with no corresponding thruster event in the log.",
		"Fuel consumption during deviation window: zero. Cause of motion: unresolved.",
		"External force calculation yields no match to solar pressure, drag, or outgassing.",
		"Attitude control system logged resistance against commanded correction burn.",
	],
}

# ── Pre-built mystery cases (arrive on desk without mission failure) ──────────

const INBOUND_CASES: Array[Dictionary] = [
	{
		"id":           "case_luna_sur",
		"trigger_day":  40,
		"mission_name": "LUNA-SUR-07",
		"mission_id":   "inbound_0",
		"elapsed_days": 5,
		"total_days":   180,
		"root_cause":   "trajectory_deviation",
		"summary":      "LUNAR SURFACE PROBE  |  LOSS OF CONTACT ON MISSION DAY 5",
		"timeline": [
			{"date": "JAN 14  2025", "type": "normal",   "text": "Probe landing confirmed. Surface operations initiated. All systems nominal."},
			{"date": "JAN 17  2025", "type": "incident", "text": "Seismic sensors registered micro-tremors. Magnitude 0.3. No correlation to known moonquake patterns."},
			{"date": "JAN 19  2025", "type": "incident", "text": "Soil sample analysis detected organic compound trace. Concentration 0.003%. Source: unidentified."},
			{"date": "JAN 19  2025", "type": "incident", "text": "Navigation system logged unplanned 0.4m surface displacement. No command issued."},
			{"date": "JAN 19  2025", "type": "critical", "text": "Telemetry link lost. Signal not recovered. Mission loss declared."},
		],
		"comms": [
			{"from": "CAPCOM",          "text": "Landing confirmed. Surface ops are go."},
			{"from": "MS1",             "text": "Houston, seismic sensors show micro-tremors. Not consistent with any known moonquake signature."},
			{"from": "CAPCOM",          "text": "Copy. Could be settling. Monitor and report."},
			{"from": "MS1",             "text": "We're seeing a trace organic compound in the sample data. That has to be a sensor error."},
			{"from": "CAPCOM",          "text": "Organic? Say again?"},
			{"from": "MS1",             "text": "The probe just moved. We didn't command that. It moved."},
			{"from": "CAPCOM",          "text": "[AUTO] Signal lost. No carrier on primary or backup."},
			{"from": "FLIGHT DIRECTOR", "text": "LUNA-SUR-07 is declared lost. Begin contingency procedures."},
		],
		"sensors": {
			"power":          {"value": 91.0, "status": "NOMINAL"},
			"communications": {"value":  8.0, "status": "FAILED"},
			"navigation":     {"value": 22.0, "status": "CRITICAL"},
			"structure":      {"value": 48.0, "status": "CRITICAL"},
			"thermal":        {"value": 86.0, "status": "NOMINAL"},
		},
	},
	{
		"id":           "case_deep_relay",
		"trigger_day":  100,
		"mission_name": "DEEP-RLY-11",
		"mission_id":   "inbound_1",
		"elapsed_days": 312,
		"total_days":   730,
		"root_cause":   "unknown_signal",
		"summary":      "DEEP SPACE RELAY  |  UNEXPLAINED SIGNAL EVENT ON MISSION DAY 312",
		"timeline": [
			{"date": "MAR 01  2025", "type": "normal",   "text": "Relay station fully operational. Signal routing nominal."},
			{"date": "NOV 08  2025", "type": "incident", "text": "Unidentified RF signal received on frequency 1420.4 MHz. Duration 72 seconds."},
			{"date": "NOV 08  2025", "type": "incident", "text": "Signal analysis shows repeating structure at 2, 3, 5, 7, 11, 13-second intervals. Prime sequence."},
			{"date": "NOV 08  2025", "type": "incident", "text": "Communications array autonomously reoriented toward signal source. No command issued."},
			{"date": "NOV 08  2025", "type": "critical", "text": "Telemetry link lost. Signal not recovered. Mission loss declared."},
		],
		"comms": [
			{"from": "CAPCOM",          "text": "Deep relay ops nominal. Routing telemetry from outer network."},
			{"from": "OPS",             "text": "Houston, unscheduled signal on 1420 megahertz. That's the hydrogen line."},
			{"from": "CAPCOM",          "text": "Confirm. Is this interference?"},
			{"from": "OPS",             "text": "Negative. Duration is 72 seconds. It's structured. The intervals match prime numbers."},
			{"from": "CAPCOM",          "text": "Do not respond. Maintain passive reception. We're escalating."},
			{"from": "OPS",             "text": "The antenna just realigned itself. We didn't command that."},
			{"from": "CAPCOM",          "text": "[AUTO] Signal lost. No carrier on primary or backup."},
			{"from": "FLIGHT DIRECTOR", "text": "DEEP-RLY-11 is declared lost. Begin contingency procedures."},
		],
		"sensors": {
			"power":          {"value": 78.0, "status": "NOMINAL"},
			"communications": {"value":  4.0, "status": "FAILED"},
			"navigation":     {"value": 61.0, "status": "DEGRADED"},
			"structure":      {"value": 82.0, "status": "NOMINAL"},
			"thermal":        {"value": 89.0, "status": "NOMINAL"},
		},
	},
	{
		"id":           "case_survey_delta",
		"trigger_day":  180,
		"mission_name": "SURVEY-DELTA-4",
		"mission_id":   "inbound_2",
		"elapsed_days": 67,
		"total_days":   365,
		"root_cause":   "trajectory_deviation",
		"summary":      "NEAR-EARTH SURVEY  |  UNREGISTERED RADAR CONTACT ON MISSION DAY 67",
		"timeline": [
			{"date": "FEB 22  2025", "type": "normal",   "text": "Survey satellite fully operational. Radar array initialized."},
			{"date": "APR 30  2025", "type": "incident", "text": "Radar contact: unregistered object at 847km altitude. Mass estimate 240,000 metric tons. No registry match."},
			{"date": "APR 30  2025", "type": "incident", "text": "Object orbital parameters: 97.4° inclination, eccentricity 0.000. Perfect circular retrograde orbit."},
			{"date": "APR 30  2025", "type": "incident", "text": "Satellite course deviation of 2.1° recorded with zero thruster activity. Object passed within 3km."},
			{"date": "APR 30  2025", "type": "critical", "text": "Telemetry link lost. Signal not recovered. Mission loss declared."},
		],
		"comms": [
			{"from": "CAPCOM",          "text": "Survey array online. Radar coverage nominal."},
			{"from": "CDR",             "text": "Houston, radar contact. Unregistered object. Reading 240,000 metric tons."},
			{"from": "CAPCOM",          "text": "Say again. Confirm mass estimate."},
			{"from": "CDR",             "text": "240,000 tons. Clean circular retrograde orbit. It's been up here a while."},
			{"from": "CAPCOM",          "text": "We have no record of that object. What is it?"},
			{"from": "CDR",             "text": "It passed 3 kilometers from us. Our satellite moved toward it. We didn't fire any thrusters."},
			{"from": "CAPCOM",          "text": "[AUTO] Signal lost. No carrier on primary or backup."},
			{"from": "FLIGHT DIRECTOR", "text": "SURVEY-DELTA-4 is declared lost. Begin contingency procedures."},
		],
		"sensors": {
			"power":          {"value": 84.0, "status": "NOMINAL"},
			"communications": {"value": 17.0, "status": "FAILED"},
			"navigation":     {"value": 11.0, "status": "FAILED"},
			"structure":      {"value": 56.0, "status": "DEGRADED"},
			"thermal":        {"value": 79.0, "status": "NOMINAL"},
		},
	},
]

# ── State ─────────────────────────────────────────────────────────────────────
var investigations: Dictionary = {}  # mission_id -> investigation dict
var _triggered_cases: Array[String] = []

# ── Public API ────────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.time_advanced.connect(_check_inbound_cases)

func _check_inbound_cases(_date: Dictionary) -> void:
	for case: Dictionary in INBOUND_CASES:
		if case["id"] in _triggered_cases:
			continue
		if GameState.days_elapsed >= case["trigger_day"]:
			_triggered_cases.append(case["id"])
			_open_inbound(case)

func _open_inbound(case: Dictionary) -> void:
	var inv_id: String = case["mission_id"]
	if investigations.has(inv_id):
		return
	investigations[inv_id] = {
		"mission_id":      inv_id,
		"mission_name":    case["mission_name"],
		"mission_def":     "",
		"elapsed_days":    case["elapsed_days"],
		"total_days":      case["total_days"],
		"opened_date":     TimeManager.get_date_string(),
		"resolved":        false,
		"diagnosis_correct": false,
		"timeline":        case["timeline"],
		"comms":           case["comms"],
		"sensors":         case["sensors"],
		"root_cause":      case["root_cause"],
		"total_incidents": case["timeline"].size(),
		"source":          "inbound",
		"summary":         case.get("summary", ""),
	}
	EventBus.emit_signal("alert_added", {
		"date":  TimeManager.get_date_string(),
		"level": "critical",
		"text":  "CASE FILED: " + case["mission_name"] + "  |  CLASSIFIED INVESTIGATION ASSIGNED",
	})
	EventBus.emit_signal("investigation_started", inv_id)
	EventBus.emit_signal("case_filed", case["id"])

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
		var rep_gain: float = 6.0 if hypothesis == "UNKNOWN_PHENOMENON" else 4.0
		GameState.change_reputation(rep_gain)
		EventBus.emit_signal("alert_added", {
			"date":  TimeManager.get_date_string(),
			"level": "success",
			"text":  "INVESTIGATION CLOSED: " + inv["mission_name"] + "  |  CORRECT DIAGNOSIS  |  REP +" + str(int(rep_gain)),
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
		"from": "CAPCOM",
		"text": "Separation confirmed. Trajectory nominal. Good luck out there.",
	})
	comms.append({
		"from": "CDR",
		"text": "Copy Houston. All systems nominal. " + mission["name"] + " is go.",
	})

	var root: String = _determine_likely_cause(incidents)
	var dialogue: Array = CREW_DIALOGUE.get(root, CREW_DIALOGUE["component_wear"])
	for line: Dictionary in dialogue:
		comms.append(line)

	comms.append({
		"from": "CAPCOM",
		"text": "[AUTO] Signal lost. No carrier on primary or backup.",
	})
	comms.append({
		"from": "FLIGHT DIRECTOR",
		"text": mission["name"] + " is declared lost. Begin contingency procedures.",
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
