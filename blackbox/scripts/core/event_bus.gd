extends Node

# ── Time ──────────────────────────────────────────────────────────────────────
signal time_advanced(date: Dictionary)

# ── Missions ──────────────────────────────────────────────────────────────────
signal mission_launched(mission: Dictionary)
signal mission_updated(mission: Dictionary)
signal mission_completed(mission: Dictionary)
signal mission_failed(mission: Dictionary)

# ── Incidents ─────────────────────────────────────────────────────────────────
signal incident_occurred(mission_id: String, incident: Dictionary)

# ── Investigations ────────────────────────────────────────────────────────────
signal investigation_started(mission_id: String)
signal investigation_completed(mission_id: String, result: Dictionary)

# ── Program ───────────────────────────────────────────────────────────────────
signal funding_changed(new_amount: float)
signal reputation_changed(new_value: float)
signal mission_unlocked(def_id: String)
signal tech_unlocked(tech_id: String)

# ── UI / alerts ───────────────────────────────────────────────────────────────
signal alert_added(alert: Dictionary)
