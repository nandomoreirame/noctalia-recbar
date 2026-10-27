-- RecBar widget: red REC/GIF pill with elapsed time while gsr-toggle records.
-- Reads $XDG_RUNTIME_DIR/gsr-toggle.state every second (a file read, no
-- process); hidden when the file is absent. Click stops the recording.

local present = require("./lib/present.luau")

local TICK_MS = 1000
local TOGGLE_CMD = "$HOME/.dotfiles/bin/utils/gsr-toggle"
-- Same fallback as gsr-toggle when XDG_RUNTIME_DIR is unset.
local STATE_FILE = (noctalia.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/gsr-toggle.state"

local function nowS(): number
	return math.floor(noctalia.nowMs() / 1000)
end

local function render()
	local raw = noctalia.readFile(STATE_FILE)
	local m = present.bar(present.parse(raw), nowS())

	local children = {
		ui.glyph({ name = m.glyph, color = m.fg }),
	}
	if not barWidget.isVertical() then
		table.insert(children, ui.label({ text = m.label, color = m.fg, fontWeight = "bold" }))
		table.insert(children, ui.label({ text = m.elapsed, color = m.fg, fontFamily = "monospace" }))
	end

	local container = if barWidget.isVertical() then ui.column else ui.row
	barWidget.render(container({
		gap = 6,
		align = "center",
		paddingH = 8,
		paddingV = 2,
		radius = 8,
		fill = m.fill,
	}, children))
	barWidget.setTooltip(m.tooltip)
	barWidget.setVisible(m.visible)
end

function update()
	render()
end

function onClick()
	noctalia.runAsync(TOGGLE_CMD, function(_result)
		render()
	end)
end

noctalia.setUpdateInterval(TICK_MS)
render()
