extends Control

# ── Colour constants ──────────────────────────────────────────────────────────
const C_BG      := Color(0.07, 0.08, 0.09)
const C_PANEL   := Color(0.10, 0.11, 0.13)
const C_PANEL2  := Color(0.12, 0.13, 0.16)
const C_BORDER  := Color(0.18, 0.40, 0.24)
const C_BORDER2 := Color(0.14, 0.28, 0.18)
const C_TEXT    := Color(0.70, 0.88, 0.74)
const C_DIM     := Color(0.36, 0.50, 0.40)
const C_GREEN   := Color(0.16, 0.94, 0.36)
const C_AMBER   := Color(0.96, 0.68, 0.10)
const C_RED     := Color(0.96, 0.20, 0.16)
const C_HEADER  := Color(0.52, 0.84, 0.60)
const C_ACCENT  := Color(0.28, 0.72, 0.44)
const C_BLUE    := Color(0.28, 0.68, 1.00)

# ── Persistent refs ───────────────────────────────────────────────────────────
var _font:           SystemFont

var _date_label:     Label
var _funds_label:    Label
var _rep_label:      Label
var _time_label:     Label

var _missions_vbox:  VBoxContainer
var _available_vbox: VBoxContainer
var _log_vbox:       VBoxContainer
var _log_scroll:     ScrollContainer

var _inv_content:    VBoxContainer   # investigation cards scroll area
var _inv_badge:      Label
var _nav_btns:       Dictionary = {} # tab_id -> Button

# mission_id -> { card, prog_bar, days_lbl, hp_bar, hp_lbl, status_lbl }
var _mission_cards:  Dictionary = {}

# Views
var _mc_view:        Control
var _inv_view:       Control
var _current_view:   String = "mc"

# Hypothesis commitment state (per investigation)
var _hyp_btn_groups:           Dictionary    = {}  # mission_id -> {hyp_id -> {card, title}}
var _inv_selected_hypotheses:  Dictionary    = {}  # mission_id -> selected hyp_id
var _submit_btns:              Dictionary    = {}  # mission_id -> Button
var _dismissed_investigations: Array[String] = []

# File browser state (per investigation)
var _inv_viewed_files: Dictionary = {}  # mission_id -> Array[String] of opened file names
var _inv_active_file:  Dictionary = {}  # mission_id -> currently displayed file name

# Objectives panel
var _objectives_vbox: VBoxContainer

# Incident popup
var _popup:          Control
var _popup_label:    Label
var _popup_timer:    float = 0.0
const POPUP_DURATION := 4.5

# ── Boot ──────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Courier New", "Courier", "Liberation Mono", "DejaVu Sans Mono"])
	_build_ui()
	_connect_signals()
	_post_initial_log()

# ── UI construction ───────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	root.add_child(_build_top_bar())

	# View area — fills space between top and bottom bars
	var view_area := Control.new()
	view_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(view_area)

	_mc_view  = _build_mc_view()
	_mc_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	view_area.add_child(_mc_view)

	_inv_view = _build_investigations_view()
	_inv_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inv_view.visible = false
	view_area.add_child(_inv_view)

	root.add_child(_build_bottom_nav())

	_build_popup()

# ── Top bar ───────────────────────────────────────────────────────────────────

func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 60)
	bar.add_theme_stylebox_override("panel", _pstyle(C_PANEL, C_BORDER, 0, 0, 0, 1))

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	bar.add_child(h)

	h.add_child(_pad(14, 0, 14, 0, _lbl(GameState.agency_name.to_upper(), 18, C_HEADER)))
	h.add_child(_vsep())
	_date_label = _lbl(TimeManager.get_date_string(), 22, C_TEXT)
	h.add_child(_pad(22, 0, 22, 0, _date_label))
	h.add_child(_vsep())

	# Time controls
	var tc := HBoxContainer.new()
	tc.add_theme_constant_override("separation", 3)
	_time_label = _lbl("||  PAUSED", 13, C_AMBER)
	var tc_pad := _pad(14, 0, 4, 0)
	tc_pad.add_child(_time_label)
	h.add_child(tc_pad)
	for pair: Array in [["||", 0.0], [" > ", 1.0], [" >> ", 5.0], [" >>> ", 30.0]]:
		var b := _btn(pair[0], 13)
		b.custom_minimum_size = Vector2(50, 0)
		b.pressed.connect(_on_time_btn.bind(pair[1]))
		tc.add_child(b)
	h.add_child(_pad(0, 0, 10, 0, tc))
	h.add_child(_vsep())

	# Funding
	var f_vbox := VBoxContainer.new()
	f_vbox.add_theme_constant_override("separation", 1)
	f_vbox.add_child(_lbl("FUNDING", 10, C_DIM))
	_funds_label = _lbl(_fmt_funds(GameState.funding), 15, C_GREEN)
	f_vbox.add_child(_funds_label)
	h.add_child(_pad(16, 6, 16, 6, f_vbox))
	h.add_child(_vsep())

	# Reputation
	var r_vbox := VBoxContainer.new()
	r_vbox.add_theme_constant_override("separation", 1)
	r_vbox.add_child(_lbl("REPUTATION", 10, C_DIM))
	_rep_label = _lbl(_rep_string(), 14, _rep_color())
	r_vbox.add_child(_rep_label)
	h.add_child(_pad(16, 6, 16, 6, r_vbox))

	return bar

# ── Mission Control view ──────────────────────────────────────────────────────

func _build_mc_view() -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.add_child(_build_missions_panel())
	h.add_child(_divider_v())
	h.add_child(_build_right_column())
	return h

func _build_missions_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio  = 0.42
	panel.add_theme_stylebox_override("panel", _pstyle(C_PANEL, Color(0,0,0,0)))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	vbox.add_child(_section_hdr("ACTIVE MISSIONS"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_missions_vbox = VBoxContainer.new()
	_missions_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_missions_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_missions_vbox)

	var empty := _lbl("No active missions.\nLaunch a mission to begin.", 13, C_DIM)
	empty.name = "EmptyLabel"
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.custom_minimum_size = Vector2(0, 100)
	_missions_vbox.add_child(empty)
	return panel

func _build_right_column() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio  = 0.58
	col.add_theme_constant_override("separation", 0)
	col.add_child(_build_objectives_panel())
	col.add_child(_divider_h())
	col.add_child(_build_available_panel())
	col.add_child(_divider_h())
	col.add_child(_build_log_panel())
	return col

func _build_available_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 200)
	panel.add_theme_stylebox_override("panel", _pstyle(C_PANEL, Color(0,0,0,0)))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	vbox.add_child(_section_hdr("AVAILABLE MISSIONS"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_available_vbox = VBoxContainer.new()
	_available_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_available_vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(_available_vbox)

	_rebuild_available()
	return panel

func _build_log_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _pstyle(C_PANEL, Color(0,0,0,0)))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	vbox.add_child(_section_hdr("OPERATIONS LOG"))

	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_log_scroll)

	_log_vbox = VBoxContainer.new()
	_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_vbox.add_theme_constant_override("separation", 1)
	_log_scroll.add_child(_log_vbox)
	return panel

func _build_objectives_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _pstyle(C_PANEL, Color(0,0,0,0)))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	vbox.add_child(_section_hdr("PROGRAM OBJECTIVES"))
	var inner := _pad(12, 6, 12, 8)
	_objectives_vbox = VBoxContainer.new()
	_objectives_vbox.add_theme_constant_override("separation", 5)
	inner.add_child(_objectives_vbox)
	vbox.add_child(inner)
	_rebuild_objectives()
	return panel

func _rebuild_objectives() -> void:
	if not _objectives_vbox:
		return
	for c in _objectives_vbox.get_children():
		c.queue_free()
	var phases: Array = [
		["satellite_comm",    "PHASE 1  Comm Satellite"],
		["satellite_weather", "PHASE 2  Weather Satellite"],
		["lunar_flyby",       "PHASE 3  Lunar Flyby"],
		["lunar_lander",      "PHASE 4  Lunar Landing"],
	]
	for phase: Array in phases:
		var def_id: String = phase[0]
		var label: String  = phase[1]
		var completed: bool = GameState.completion_count(def_id) > 0
		var is_active: bool = MissionSystem.has_active_of_type(def_id)
		var unlocked: bool  = def_id in GameState.unlocked_missions
		var icon: String
		var col: Color
		var status: String
		if completed:
			icon = "✓";  col = C_GREEN;  status = "COMPLETE"
		elif is_active:
			icon = "●";  col = C_AMBER;  status = "IN PROGRESS"
		elif unlocked:
			icon = "▸";  col = C_ACCENT; status = "READY"
		else:
			icon = "○";  col = C_DIM;    status = "LOCKED"
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_objectives_vbox.add_child(row)
		row.add_child(_lbl(icon, 11, col))
		var lbl := _lbl(label, 11, col)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		row.add_child(_lbl(status, 10, col))
	_objectives_vbox.add_child(_lbl("", 3, C_DIM))
	_objectives_vbox.add_child(_lbl("CAMPAIGN: Land on the Moon before agency dissolution.", 10, C_DIM))

# ── Investigations view ───────────────────────────────────────────────────────

func _build_investigations_view() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _pstyle(C_PANEL, Color(0,0,0,0)))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)
	vbox.add_child(_section_hdr("BLACK BOX  —  OPEN INVESTIGATIONS"))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_inv_content = VBoxContainer.new()
	_inv_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_inv_content)

	return panel

func _rebuild_investigations() -> void:
	for c in _inv_content.get_children():
		c.queue_free()

	var shown := false
	for inv_id: String in InvestigationSystem.investigations:
		if inv_id in _dismissed_investigations:
			continue
		shown = true
		_inv_content.add_child(_build_investigation_card(InvestigationSystem.investigations[inv_id]))

	if not shown:
		var lbl := _lbl("No open investigations.\nMissions that fail will generate\na black box investigation here.", 14, C_DIM)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0, 120)
		_inv_content.add_child(lbl)

func _build_investigation_card(inv: Dictionary) -> Control:
	var mission_id: String = inv["mission_id"]
	var resolved: bool     = inv.get("resolved", false)
	var correct: bool      = inv.get("diagnosis_correct", false)
	var viewed: Array      = _inv_viewed_files.get(mission_id, [])

	var card := PanelContainer.new()
	var b_col: Color = (C_GREEN if correct else C_RED) if resolved else C_RED
	card.add_theme_stylebox_override("panel", _pstyle(C_PANEL2, b_col, 1, 1, 3, 1))

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	card.add_child(outer)

	# ── Header ──
	var hdr_row := HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 12)
	outer.add_child(hdr_row)
	var title := _lbl("▸ CASE FILE:  " + inv["mission_name"], 16, C_RED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_row.add_child(title)
	if resolved:
		hdr_row.add_child(_lbl("✓ RESOLVED" if correct else "✗ INCONCLUSIVE", 12, C_GREEN if correct else C_RED))
	else:
		hdr_row.add_child(_lbl("%d/3 FILES REVIEWED" % viewed.size(), 12, C_ACCENT if viewed.size() == 3 else C_DIM))
	outer.add_child(_lbl("/blackbox/%s/  —  MISSION FAILED ON DAY %d OF %d" % [mission_id, inv.get("elapsed_days",0), inv.get("total_days",0)], 11, C_DIM))
	outer.add_child(_divider_h())

	if not resolved:
		outer.add_child(_build_file_browser(inv))
		outer.add_child(_divider_h())
		if viewed.size() >= 2:
			outer.add_child(_build_hypothesis_section(inv))
		else:
			var need: int = 2 - viewed.size()
			var hint := _lbl("Open %d more file%s to unlock hypothesis submission." % [need, "s" if need > 1 else ""], 12, C_DIM)
			outer.add_child(_pad(0, 4, 0, 4, hint))
	else:
		outer.add_child(_build_result_section(inv))
		outer.add_child(_divider_h())
		var close_row := HBoxContainer.new()
		close_row.alignment = BoxContainer.ALIGNMENT_END
		outer.add_child(close_row)
		var cb := _btn("CLOSE  ▸", 12)
		cb.add_theme_color_override("font_color", C_DIM)
		cb.pressed.connect(_dismiss_investigation.bind(mission_id))
		close_row.add_child(cb)

	return card

# ── Bottom nav ────────────────────────────────────────────────────────────────

func _build_bottom_nav() -> Control:
	var bar := PanelContainer.new()
	bar.custom_minimum_size = Vector2(0, 58)
	bar.add_theme_stylebox_override("panel", _pstyle(C_PANEL, C_BORDER, 1, 0, 0, 0))

	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", 2)
	bar.add_child(h)

	var tabs: Array = [
		["mc",   "MISSION CONTROL",  true],
		["inv",  "INVESTIGATIONS",   true],
		["laun", "LAUNCH CENTER",    false],
		["res",  "RESEARCH",         false],
		["arc",  "ARCHIVE",          false],
	]
	for tab: Array in tabs:
		var id: String    = tab[0]
		var label: String = tab[1]
		var active: bool  = tab[2]

		var btn := _btn(label, 14)
		btn.custom_minimum_size = Vector2(200, 44)
		btn.disabled             = not active

		var col: Color
		if not active:
			col = C_DIM
		elif id == "mc":
			col = C_GREEN
		else:
			col = C_ACCENT
		btn.add_theme_color_override("font_color", col)

		if active:
			btn.pressed.connect(_on_nav.bind(id))
		h.add_child(btn)
		_nav_btns[id] = btn

		# Badge slot next to investigations button
		if id == "inv":
			_inv_badge = _lbl("", 10, C_RED)
			_inv_badge.visible = false
			h.add_child(_inv_badge)

	return bar

# ── Incident popup ────────────────────────────────────────────────────────────

func _build_popup() -> void:
	_popup = PanelContainer.new()
	_popup.anchor_left         = 0.5
	_popup.anchor_right        = 0.5
	_popup.anchor_top          = 0.0
	_popup.anchor_bottom       = 0.0
	_popup.grow_horizontal     = Control.GROW_DIRECTION_BOTH
	_popup.offset_left         = -280
	_popup.offset_right        = 280
	_popup.offset_top          = 72
	_popup.offset_bottom       = 145
	_popup.visible             = false
	_popup.mouse_filter        = Control.MOUSE_FILTER_STOP
	_popup.add_theme_stylebox_override("panel", _pstyle(Color(0.12, 0.05, 0.05, 0.96), C_RED, 2, 2, 2, 2))
	_popup.z_index             = 10

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_popup.add_child(vbox)

	vbox.add_child(_lbl("⚠  INCIDENT ALERT", 13, C_RED))
	_popup_label = _lbl("", 13, C_AMBER)
	vbox.add_child(_popup_label)

	var dismiss := _btn("ACKNOWLEDGE", 11)
	dismiss.add_theme_color_override("font_color", C_DIM)
	dismiss.pressed.connect(func(): _popup.visible = false; _popup_timer = 0.0)
	vbox.add_child(dismiss)
	add_child(_popup)

# ── Mission cards ─────────────────────────────────────────────────────────────

func _add_mission_card(mission: Dictionary) -> void:
	var empty := _missions_vbox.get_node_or_null("EmptyLabel")
	if empty:
		empty.queue_free()

	var card := PanelContainer.new()
	card.name = "Card_" + mission["id"]
	card.add_theme_stylebox_override("panel", _pstyle(C_PANEL2, C_BORDER2))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)

	# Header row
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vbox.add_child(hdr)
	var name_lbl := _lbl(mission["name"], 15, C_HEADER)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(name_lbl)
	var status_lbl := _lbl("●  ACTIVE", 12, C_GREEN)
	hdr.add_child(status_lbl)
	var def: Dictionary = MissionSystem.DEFS.get(mission["def_id"], {})
	hdr.add_child(_lbl("  " + def.get("destination",""), 11, C_DIM))

	# Progress row
	var prog_row := HBoxContainer.new()
	prog_row.add_theme_constant_override("separation", 7)
	vbox.add_child(prog_row)
	prog_row.add_child(_lbl("PROGRESS", 10, C_DIM))
	var prog_bar := _progress_bar(C_ACCENT, 0.0)
	prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_row.add_child(prog_bar)
	var days_lbl := _lbl("0 / %d d" % mission["total_days"], 10, C_DIM)
	days_lbl.custom_minimum_size = Vector2(90, 0)
	prog_row.add_child(days_lbl)

	# Health row
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 7)
	vbox.add_child(hp_row)
	hp_row.add_child(_lbl("HEALTH  ", 10, C_DIM))
	var hp_bar := _progress_bar(C_GREEN, 100.0)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_bar)
	var hp_lbl := _lbl("100%", 10, C_GREEN)
	hp_lbl.custom_minimum_size = Vector2(42, 0)
	hp_row.add_child(hp_lbl)

	_missions_vbox.add_child(card)
	# Store direct refs — no fragile path navigation
	_mission_cards[mission["id"]] = {
		"card":       card,
		"status_lbl": status_lbl,
		"prog_bar":   prog_bar,
		"days_lbl":   days_lbl,
		"hp_bar":     hp_bar,
		"hp_lbl":     hp_lbl,
	}

func _update_mission_card(mission: Dictionary) -> void:
	if not _mission_cards.has(mission["id"]):
		return
	var c: Dictionary   = _mission_cards[mission["id"]]
	var pct:     float  = float(mission["elapsed_days"]) / float(mission["total_days"]) * 100.0
	var hp:      float  = mission["health"]

	(c["prog_bar"] as ProgressBar).value = pct
	(c["days_lbl"] as Label).text        = "%d / %d d" % [mission["elapsed_days"], mission["total_days"]]

	var hp_bar: ProgressBar = c["hp_bar"]
	hp_bar.value = hp
	var fill := StyleBoxFlat.new()
	fill.bg_color = C_GREEN if hp > 60 else (C_AMBER if hp > 25 else C_RED)
	fill.set_content_margin_all(0)
	hp_bar.add_theme_stylebox_override("fill", fill)

	var hp_lbl: Label = c["hp_lbl"]
	hp_lbl.text     = "%d%%" % int(hp)
	hp_lbl.modulate = C_GREEN if hp > 60 else (C_AMBER if hp > 25 else C_RED)

	var status_lbl: Label = c["status_lbl"]
	match mission["status"]:
		"completed":
			status_lbl.text     = "✓  COMPLETE"
			status_lbl.modulate = C_GREEN
		"failed":
			status_lbl.text     = "✗  FAILED — INVESTIGATE"
			status_lbl.modulate = C_RED

func _flash_card(mission_id: String) -> void:
	if not _mission_cards.has(mission_id):
		return
	var card: Control = _mission_cards[mission_id]["card"]
	var tw := create_tween()
	tw.tween_property(card, "modulate", Color(1.8, 0.4, 0.2), 0.08)
	tw.tween_property(card, "modulate", Color(1.0, 1.0, 1.0), 0.55)

# ── Available missions ────────────────────────────────────────────────────────

func _rebuild_available() -> void:
	for c in _available_vbox.get_children():
		c.queue_free()

	var shown := 0
	for def_id in GameState.unlocked_missions:
		if not MissionSystem.DEFS.has(def_id):
			continue
		var def: Dictionary  = MissionSystem.DEFS[def_id]
		var affordable: bool = GameState.funding >= def["cost"]
		var is_active: bool  = MissionSystem.has_active_of_type(def_id)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_available_vbox.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		row.add_child(info)
		info.add_child(_lbl(def["name"].to_upper(), 13, C_AMBER if is_active else C_TEXT))
		var meta := HBoxContainer.new()
		meta.add_theme_constant_override("separation", 14)
		info.add_child(meta)
		meta.add_child(_lbl(def["destination"], 11, C_DIM))
		meta.add_child(_lbl("%d DAYS" % def["duration_days"], 11, C_DIM))
		if not is_active:
			meta.add_child(_lbl(_fmt_funds(def["cost"]), 11, C_AMBER if not affordable else C_DIM))

		if is_active:
			var act := _lbl("● ACTIVE", 12, C_AMBER)
			act.custom_minimum_size = Vector2(100, 34)
			act.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row.add_child(act)
		else:
			var lb := _btn("LAUNCH", 12)
			lb.custom_minimum_size = Vector2(100, 34)
			lb.disabled             = not affordable
			if affordable:
				lb.add_theme_color_override("font_color", C_GREEN)
			lb.pressed.connect(_on_launch.bind(def_id))
			row.add_child(lb)
		shown += 1

	if shown == 0:
		_available_vbox.add_child(_lbl("No missions available.", 12, C_DIM))

# ── Operations log ────────────────────────────────────────────────────────────

func _add_log_entry(alert: Dictionary) -> void:
	var level: String = alert.get("level", "info")
	var col: Color = C_DIM
	match level:
		"success":  col = C_GREEN
		"warning":  col = C_AMBER
		"critical": col = C_RED

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	_log_vbox.add_child(line)

	var dl := _lbl("[%s]" % alert.get("date",""), 11, C_DIM)
	dl.custom_minimum_size = Vector2(148, 0)
	line.add_child(dl)
	line.add_child(_lbl(alert.get("text",""), 11, col))

	_log_scroll.set_deferred("scroll_vertical", 999999)
	if _log_vbox.get_child_count() > 80:
		_log_vbox.get_child(0).queue_free()

# ── Signal handlers ───────────────────────────────────────────────────────────

func _connect_signals() -> void:
	EventBus.time_advanced.connect(func(_d): _date_label.text = TimeManager.get_date_string())
	EventBus.mission_launched.connect(_on_mission_launched)
	EventBus.mission_updated.connect(func(m): _update_mission_card(m))
	EventBus.mission_completed.connect(func(m): _update_mission_card(m); _rebuild_objectives(); _rebuild_available())
	EventBus.mission_failed.connect(func(m): _update_mission_card(m); _rebuild_objectives())
	EventBus.incident_occurred.connect(_on_incident)
	EventBus.funding_changed.connect(func(v): _funds_label.text = _fmt_funds(v))
	EventBus.reputation_changed.connect(func(_v): _rep_label.text = _rep_string(); _rep_label.modulate = _rep_color())
	EventBus.mission_unlocked.connect(func(_id): _rebuild_available())
	EventBus.alert_added.connect(_add_log_entry)
	EventBus.investigation_started.connect(_on_investigation_started)
	EventBus.investigation_completed.connect(func(_id, _r): _rebuild_investigations(); _update_inv_badge())

func _on_mission_launched(mission: Dictionary) -> void:
	_add_mission_card(mission)
	_rebuild_available()
	_rebuild_objectives()

func _on_incident(mission_id: String, incident: Dictionary) -> void:
	_flash_card(mission_id)
	var m: Dictionary = MissionSystem.get_mission(mission_id)
	if m.is_empty():
		return
	if incident.get("damage", 0.0) >= 8.0 or m["health"] < 40.0:
		var pool: Array   = InvestigationSystem.INCIDENT_SYMPTOMS.get(incident.get("id",""), [])
		var symptom: String = pool[0] if not pool.is_empty() else "Anomalous telemetry detected."
		_popup_label.text = "%s  —  HEALTH %d%%\n%s" % [
			incident.get("mission_name", mission_id),
			int(m["health"]),
			symptom,
		]
		_popup.visible  = true
		_popup_timer    = POPUP_DURATION

func _on_investigation_started(_mission_id: String) -> void:
	_rebuild_investigations()
	_update_inv_badge()

func _on_time_btn(scale: float) -> void:
	if scale == 0.0:
		TimeManager.pause()
		_time_label.text     = "||  PAUSED"
		_time_label.modulate = C_AMBER
	else:
		TimeManager.set_scale(scale)
		_time_label.text     = {1.0: ">  1×", 5.0: ">>  5×", 30.0: ">>>  30×"}.get(scale, ">  LIVE")
		_time_label.modulate = C_GREEN

func _on_launch(def_id: String) -> void:
	MissionSystem.launch(def_id)
	_rebuild_available()

func _on_nav(tab_id: String) -> void:
	_current_view = tab_id
	_mc_view.visible  = (tab_id == "mc")
	_inv_view.visible = (tab_id == "inv")
	for id in _nav_btns:
		var active: bool = (id == tab_id)
		_nav_btns[id].add_theme_color_override("font_color",
			C_GREEN if active else (C_ACCENT if id in ["mc","inv"] else C_DIM))

func _on_research(tech_id: String) -> void:
	TechTree.research(tech_id)
	_rebuild_investigations()
	_rebuild_available()

func _dismiss_investigation(mission_id: String) -> void:
	_dismissed_investigations.append(mission_id)
	_rebuild_investigations()
	_update_inv_badge()

# ── File browser (investigation) ─────────────────────────────────────────────

func _build_file_browser(inv: Dictionary) -> Control:
	var mission_id: String  = inv["mission_id"]
	var viewed: Array       = _inv_viewed_files.get(mission_id, [])
	var active_file: String = _inv_active_file.get(mission_id, "")

	var browser := HBoxContainer.new()
	browser.add_theme_constant_override("separation", 0)

	# Sidebar
	var sidebar_bg := PanelContainer.new()
	sidebar_bg.custom_minimum_size = Vector2(200, 0)
	sidebar_bg.add_theme_stylebox_override("panel", _pstyle(C_PANEL, Color(0,0,0,0), 0, 0, 0, 0))
	browser.add_child(sidebar_bg)

	var sidebar := VBoxContainer.new()
	sidebar.add_theme_constant_override("separation", 0)
	sidebar_bg.add_child(sidebar)

	sidebar.add_child(_pad(10, 8, 10, 4, _lbl("/bb/" + mission_id + "/", 10, C_DIM)))
	sidebar.add_child(_divider_h())

	const FILE_LIST: Array = [
		["EVENTS.LOG",    "1.1K"],
		["TELEMETRY.DAT", "4.2K"],
		["COMMS.LOG",     "2.8K"],
	]
	for fd: Array in FILE_LIST:
		var fname: String   = fd[0]
		var fsize: String   = fd[1]
		var is_viewed: bool = fname in viewed
		var is_active: bool = fname == active_file

		var item := PanelContainer.new()
		item.mouse_filter = Control.MOUSE_FILTER_STOP
		item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var ibg: Color = Color(0.11, 0.20, 0.13) if is_active else (Color(0.09, 0.13, 0.10) if is_viewed else C_PANEL)
		item.add_theme_stylebox_override("panel", _pstyle(ibg, C_ACCENT if is_active else Color(0,0,0,0), 0, 0, 0, 2))
		sidebar.add_child(item)

		var item_row := HBoxContainer.new()
		item_row.add_theme_constant_override("separation", 6)
		item_row.mouse_filter = Control.MOUSE_FILTER_PASS
		item.add_child(item_row)

		var dot := _lbl("●" if is_viewed else "·", 11, C_GREEN if is_viewed else C_DIM)
		dot.mouse_filter = Control.MOUSE_FILTER_PASS
		item_row.add_child(_pad(10, 6, 0, 6, dot))

		var name_col := VBoxContainer.new()
		name_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_col.add_theme_constant_override("separation", 0)
		name_col.mouse_filter = Control.MOUSE_FILTER_PASS
		item_row.add_child(name_col)
		var nlbl := _lbl(fname, 11, C_TEXT if is_active else (C_ACCENT if is_viewed else C_DIM))
		nlbl.mouse_filter = Control.MOUSE_FILTER_PASS
		name_col.add_child(nlbl)
		var slbl := _lbl(fsize, 10, C_DIM)
		slbl.mouse_filter = Control.MOUSE_FILTER_PASS
		name_col.add_child(slbl)

		item.gui_input.connect(_on_file_click.bind(mission_id, fname))

	browser.add_child(_divider_v())

	# Content viewer
	var content_scroll := ScrollContainer.new()
	content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	browser.add_child(content_scroll)

	if active_file == "":
		var ph := _lbl("  Select a file to begin review.", 12, C_DIM)
		ph.custom_minimum_size = Vector2(0, 120)
		ph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		content_scroll.add_child(ph)
	else:
		content_scroll.add_child(_build_file_content(inv, active_file))

	return browser

func _build_file_content(inv: Dictionary, fname: String) -> Control:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)

	vbox.add_child(_pad(12, 6, 12, 4, _lbl("── " + fname + " ──", 11, C_ACCENT)))

	match fname:
		"EVENTS.LOG":
			for entry: Dictionary in inv.get("timeline", []):
				var row := HBoxContainer.new()
				row.add_theme_constant_override("separation", 10)
				vbox.add_child(_pad(12, 0, 12, 0, row))
				var dl := _lbl(entry.get("date",""), 10, C_DIM)
				dl.custom_minimum_size = Vector2(110, 0)
				row.add_child(dl)
				var t: String  = entry.get("type","normal")
				var ec: Color = C_RED if t == "critical" else (C_AMBER if t == "incident" else C_DIM)
				row.add_child(_lbl(entry.get("text",""), 11, ec))
		"TELEMETRY.DAT":
			for sys_name: String in inv.get("sensors", {}):
				var sd: Dictionary = inv["sensors"][sys_name]
				var val: float     = sd.get("value", 100.0)
				var status: String = sd.get("status","NOMINAL")
				var scol: Color    = C_GREEN if status == "NOMINAL" else (C_AMBER if status == "DEGRADED" else C_RED)
				var srow := HBoxContainer.new()
				srow.add_theme_constant_override("separation", 8)
				vbox.add_child(_pad(12, 0, 12, 0, srow))
				var nm := _lbl(sys_name.to_upper(), 11, C_DIM)
				nm.custom_minimum_size = Vector2(120, 0)
				srow.add_child(nm)
				var bar := _progress_bar(scol, val)
				bar.custom_minimum_size = Vector2(140, 10)
				srow.add_child(bar)
				srow.add_child(_lbl("%d%%  %s" % [int(val), status], 10, scol))
		"COMMS.LOG":
			for comm: Dictionary in inv.get("comms", []):
				var crow := HBoxContainer.new()
				crow.add_theme_constant_override("separation", 8)
				vbox.add_child(_pad(12, 0, 12, 0, crow))
				var fl := _lbl("[" + comm.get("from","") + "]", 10, C_ACCENT)
				fl.custom_minimum_size = Vector2(152, 0)
				crow.add_child(fl)
				crow.add_child(_lbl(comm.get("text",""), 11, C_DIM))

	return vbox

func _on_file_click(event: InputEvent, mission_id: String, file_name: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _inv_viewed_files.has(mission_id):
		_inv_viewed_files[mission_id] = []
	if file_name not in _inv_viewed_files[mission_id]:
		_inv_viewed_files[mission_id].append(file_name)
	_inv_active_file[mission_id] = file_name
	_rebuild_investigations()

# ── Hypothesis selector builders ──────────────────────────────────────────────

func _build_hypothesis_section(inv: Dictionary) -> Control:
	var mission_id: String = inv["mission_id"]
	if not _inv_selected_hypotheses.has(mission_id):
		_inv_selected_hypotheses[mission_id] = ""
	_hyp_btn_groups[mission_id] = {}

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)

	outer.add_child(_lbl("SUBMIT YOUR FINDINGS", 13, C_ACCENT))
	outer.add_child(_lbl("Based on the evidence above, what caused the loss of " + inv["mission_name"] + "?", 12, C_DIM))

	var hyps: Dictionary = InvestigationSystem.HYPOTHESIS_CATEGORIES
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	outer.add_child(row1)
	row1.add_child(_build_hyp_card(mission_id, "RADIATION_EVENT",       hyps["RADIATION_EVENT"]))
	row1.add_child(_build_hyp_card(mission_id, "PHYSICAL_IMPACT",       hyps["PHYSICAL_IMPACT"]))
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 8)
	outer.add_child(row2)
	row2.add_child(_build_hyp_card(mission_id, "SOFTWARE_ANOMALY",      hyps["SOFTWARE_ANOMALY"]))
	row2.add_child(_build_hyp_card(mission_id, "COMMUNICATION_FAILURE", hyps["COMMUNICATION_FAILURE"]))
	outer.add_child(_build_hyp_card(mission_id, "ENGINEERING_DEFICIENCY", hyps["ENGINEERING_DEFICIENCY"]))

	var sub_row := HBoxContainer.new()
	sub_row.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(sub_row)
	var sub_btn := _btn("SUBMIT FINDINGS  ▸", 13)
	sub_btn.disabled = _inv_selected_hypotheses[mission_id].is_empty()
	if not sub_btn.disabled:
		sub_btn.add_theme_color_override("font_color", C_GREEN)
	sub_btn.pressed.connect(_on_submit_hypothesis.bind(mission_id))
	_submit_btns[mission_id] = sub_btn
	sub_row.add_child(sub_btn)

	return outer

func _build_hyp_card(mission_id: String, hyp_id: String, desc: String) -> Control:
	var selected: bool = _inv_selected_hypotheses.get(mission_id, "") == hyp_id
	var c := PanelContainer.new()
	c.size_flags_horizontal      = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size        = Vector2(0, 52)
	c.mouse_filter               = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_hyp_style(c, selected)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	c.add_child(vbox)

	var title_lbl := _lbl(hyp_id.replace("_", " "), 12, C_TEXT if selected else C_DIM)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(title_lbl)
	var desc_lbl := _lbl(desc, 10, C_DIM)
	desc_lbl.mouse_filter  = Control.MOUSE_FILTER_PASS
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)

	_hyp_btn_groups[mission_id][hyp_id] = {"card": c, "title": title_lbl}
	c.gui_input.connect(_on_hyp_click.bind(mission_id, hyp_id))
	return c

func _apply_hyp_style(card: Control, selected: bool) -> void:
	if selected:
		card.add_theme_stylebox_override("panel", _pstyle(Color(0.08, 0.16, 0.10), C_ACCENT))
	else:
		card.add_theme_stylebox_override("panel", _pstyle(C_PANEL, C_BORDER2))

func _build_result_section(inv: Dictionary) -> Control:
	var correct: bool  = inv.get("diagnosis_correct", false)
	var bg_col: Color  = Color(0.05, 0.12, 0.06) if correct else Color(0.12, 0.05, 0.05)
	var brd_col: Color = C_GREEN if correct else C_RED

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _pstyle(bg_col, brd_col, 2, 2, 2, 2))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	if correct:
		vbox.add_child(_lbl("✓  CORRECT DIAGNOSIS", 16, C_GREEN))
		var conf: String = inv.get("confirmed_hypothesis","").replace("_"," ")
		vbox.add_child(_lbl("Root cause confirmed:  " + conf, 12, C_TEXT))
		vbox.add_child(_lbl("Agency reputation increased.  REP +4", 11, C_DIM))
		var techs: Array = InvestigationSystem.HYPOTHESIS_TO_TECH.get(inv.get("confirmed_hypothesis",""), [])
		if not techs.is_empty():
			vbox.add_child(_lbl("", 4, C_DIM))
			vbox.add_child(_lbl("RESEARCH UNLOCKED:", 11, C_ACCENT))
			for tech_id: String in techs:
				var tech: Dictionary = TechTree.TECHS.get(tech_id, {})
				if tech.is_empty():
					continue
				var already: bool    = TechTree.is_unlocked(tech_id)
				var affordable: bool = GameState.funding >= tech.get("cost", 0.0) and not already
				var rec_row := HBoxContainer.new()
				rec_row.add_theme_constant_override("separation", 12)
				vbox.add_child(rec_row)
				var ri := VBoxContainer.new()
				ri.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				ri.add_theme_constant_override("separation", 2)
				rec_row.add_child(ri)
				ri.add_child(_lbl("► " + tech.get("name","").to_upper() + "  ·  " + _fmt_funds(tech.get("cost",0.0)), 13, C_TEXT))
				ri.add_child(_lbl(tech.get("description",""), 11, C_DIM))
				if already:
					rec_row.add_child(_lbl("✓ RESEARCHED", 12, C_GREEN))
				else:
					var rb := _btn("RESEARCH  " + _fmt_funds(tech.get("cost",0.0)), 12)
					rb.disabled = not affordable
					if affordable:
						rb.add_theme_color_override("font_color", C_GREEN)
					rb.pressed.connect(_on_research.bind(tech_id))
					rec_row.add_child(rb)
	else:
		vbox.add_child(_lbl("✗  INVESTIGATION INCONCLUSIVE", 16, C_RED))
		vbox.add_child(_lbl("Your diagnosis did not match the telemetry profile.", 12, C_TEXT))
		vbox.add_child(_lbl("The root cause of " + inv["mission_name"] + " remains unresolved.", 12, C_DIM))
		vbox.add_child(_lbl("Future missions of this type remain at elevated risk.  REP -3", 11, C_DIM))

	return panel

func _on_hyp_click(event: InputEvent, mission_id: String, hyp_id: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	_inv_selected_hypotheses[mission_id] = hyp_id
	if _hyp_btn_groups.has(mission_id):
		for hid: String in _hyp_btn_groups[mission_id]:
			var refs: Dictionary = _hyp_btn_groups[mission_id][hid]
			var sel := (hid == hyp_id)
			_apply_hyp_style(refs["card"], sel)
			(refs["title"] as Label).modulate = C_TEXT if sel else C_DIM
	if _submit_btns.has(mission_id):
		var sb: Button = _submit_btns[mission_id]
		sb.disabled = false
		sb.add_theme_color_override("font_color", C_GREEN)

func _on_submit_hypothesis(mission_id: String) -> void:
	var hyp: String = _inv_selected_hypotheses.get(mission_id, "")
	if hyp.is_empty():
		return
	InvestigationSystem.submit_hypothesis(mission_id, hyp)

func _update_inv_badge() -> void:
	var n: int = InvestigationSystem.get_open_count()
	if _inv_badge:
		_inv_badge.visible = n > 0
		_inv_badge.text    = "  [%d OPEN]" % n
		if n > 0:
			_nav_btns["inv"].add_theme_color_override("font_color", C_RED)

# ── Per-frame ─────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _popup_timer > 0.0:
		_popup_timer -= delta
		if _popup_timer <= 0.0:
			_popup.visible = false

# ── Initial log ───────────────────────────────────────────────────────────────

func _post_initial_log() -> void:
	_add_log_entry({"date": TimeManager.get_date_string(), "level": "info",
		"text": "AGENCY INITIALIZED. " + GameState.agency_name.to_upper() + " MISSION CONTROL ONLINE."})
	_add_log_entry({"date": TimeManager.get_date_string(), "level": "info",
		"text": "BUDGET: " + _fmt_funds(GameState.funding) + "  |  SELECT A MISSION AND PRESS [LAUNCH]."})
	_add_log_entry({"date": TimeManager.get_date_string(), "level": "info",
		"text": "USE TIME CONTROLS TO ADVANCE THE CLOCK.  MISSIONS THAT FAIL APPEAR IN [INVESTIGATIONS]."})

# ── Widget helpers ────────────────────────────────────────────────────────────

func _section_hdr(title: String) -> Control:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", _pstyle(C_PANEL2, C_BORDER, 0, 0, 1, 0))
	c.add_child(_pad(12, 7, 12, 7, _lbl("▸  " + title, 12, C_ACCENT)))
	return c

func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text     = text
	l.modulate = color
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	return l

func _btn(text: String, size: int) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal",   _pstyle(C_PANEL2, C_BORDER2))
	b.add_theme_stylebox_override("hover",    _pstyle(Color(0.14, 0.18, 0.20), C_BORDER))
	b.add_theme_stylebox_override("pressed",  _pstyle(C_PANEL, C_ACCENT))
	b.add_theme_stylebox_override("disabled", _pstyle(C_PANEL, Color(0.12,0.13,0.12)))
	return b

func _progress_bar(color: Color, value: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.min_value = 0.0; bar.max_value = 100.0; bar.value = value
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color; fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.09,0.10,0.12); bg.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bg)
	return bar

func _pad(l: int, t: int, r: int, b: int, child: Control = null) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",   l)
	m.add_theme_constant_override("margin_top",    t)
	m.add_theme_constant_override("margin_right",  r)
	m.add_theme_constant_override("margin_bottom", b)
	if child:
		m.add_child(child)
	return m

func _pstyle(bg: Color, border: Color, bt: int = 1, bb: int = 1, bl: int = 1, br: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.border_width_top = bt; s.border_width_bottom = bb
	s.border_width_left = bl; s.border_width_right = br
	s.set_content_margin_all(8)
	return s

func _vsep() -> Control:
	var r := ColorRect.new()
	r.color = C_BORDER2
	r.custom_minimum_size = Vector2(1, 0)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return r

func _divider_v() -> Control:
	var r := ColorRect.new()
	r.color = C_BORDER
	r.custom_minimum_size = Vector2(1, 0)
	r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return r

func _divider_h() -> Control:
	var r := ColorRect.new()
	r.color = C_BORDER2
	r.custom_minimum_size = Vector2(0, 1)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r

func _fmt_funds(amount: float) -> String:
	if amount >= 1_000_000_000.0: return "$%.2fB" % (amount / 1_000_000_000.0)
	if amount >= 1_000_000.0:     return "$%.1fM" % (amount / 1_000_000.0)
	return "$%d" % int(amount)

func _rep_string() -> String:
	var r := GameState.reputation
	if r >= 75: return "EXCELLENT  %.0f" % r
	if r >= 50: return "GOOD  %.0f" % r
	if r >= 25: return "POOR  %.0f" % r
	return "CRITICAL  %.0f" % r

func _rep_color() -> Color:
	var r := GameState.reputation
	if r >= 75: return C_GREEN
	if r >= 50: return C_ACCENT
	if r >= 25: return C_AMBER
	return C_RED
