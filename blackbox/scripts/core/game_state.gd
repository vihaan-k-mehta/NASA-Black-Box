extends Node

var agency_name: String = "Apex Space"
var funding:     float  = 50_000_000.0
var reputation:  float  = 50.0          # 0–100

# Missions available to launch (def_ids)
var unlocked_missions: Array[String] = ["satellite_comm"]

# How many times each mission type has been completed
var mission_completions: Dictionary = {}   # def_id -> int

# Investigations completed
var investigations_resolved: Array[String] = []

func add_funding(amount: float) -> void:
	funding += amount
	EventBus.emit_signal("funding_changed", funding)

func spend_funding(amount: float) -> bool:
	if funding < amount:
		return false
	funding -= amount
	EventBus.emit_signal("funding_changed", funding)
	return true

func change_reputation(delta: float) -> void:
	reputation = clamp(reputation + delta, 0.0, 100.0)
	EventBus.emit_signal("reputation_changed", reputation)

func record_completion(def_id: String) -> void:
	mission_completions[def_id] = mission_completions.get(def_id, 0) + 1

func completion_count(def_id: String) -> int:
	return mission_completions.get(def_id, 0)

func unlock_mission(def_id: String) -> void:
	if def_id not in unlocked_missions:
		unlocked_missions.append(def_id)
		EventBus.emit_signal("mission_unlocked", def_id)
		EventBus.emit_signal("alert_added", {
			"date":  TimeManager.get_date_string(),
			"level": "info",
			"text":  "NEW MISSION AVAILABLE: " + MissionSystem.DEFS.get(def_id, {}).get("name", def_id).to_upper(),
		})

func get_snapshot() -> Dictionary:
	return {
		"agency_name": agency_name,
		"funding":     funding,
		"reputation":  reputation,
	}
