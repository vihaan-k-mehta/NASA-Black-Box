extends Node

var year:  int = 2025
var month: int = 1
var day:   int = 1

var time_scale: float = 1.0   # game-days per real second
var paused:     bool  = true

const MONTH_DAYS: Array[int]    = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const MONTH_NAMES: Array[String] = [
	"JAN", "FEB", "MAR", "APR", "MAY", "JUN",
	"JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
]

var _accumulator: float = 0.0

func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += delta * time_scale
	while _accumulator >= 1.0:
		_accumulator -= 1.0
		_advance_day()

func _advance_day() -> void:
	day += 1
	if day > MONTH_DAYS[month - 1]:
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
	EventBus.emit_signal("time_advanced", get_date())

func get_date() -> Dictionary:
	return {"year": year, "month": month, "day": day}

func get_date_string() -> String:
	return "%s %02d  %04d" % [MONTH_NAMES[month - 1], day, year]

func set_scale(scale: float) -> void:
	time_scale = scale
	if scale > 0.0:
		paused = false
	else:
		paused = true

func pause() -> void:
	paused = true

func unpause() -> void:
	paused = false

func days_since(from_date: Dictionary) -> int:
	# Approximate — good enough for mission tracking
	var fy: int = from_date.get("year",  year)
	var fm: int = from_date.get("month", month)
	var fd: int = from_date.get("day",   day)
	return (year - fy) * 365 + (month - fm) * 30 + (day - fd)
