-- gsr-toggle state -> bar model. Pure: every pt-BR string lives here.
-- No noctalia / barWidget / panel / ui.

local Present = {}

local LABELS = { video = "REC", gif = "GIF" }
-- Hidden pill still emits fill/fg: the host reconciler only applies props that
-- are present, so omitting them would keep stale colors on the next show.
local CLEAR = "#00000000"

-- "<mode> <start epoch> <file>" (gsr-toggle.state) -> { mode, since } or nil.
function Present.parse(raw: any): any
	if typeof(raw) ~= "string" then
		return nil
	end
	local mode, since = string.match(raw, "^(%a+)%s+(%d+)")
	if mode == nil or LABELS[mode] == nil then
		return nil
	end
	return { mode = mode, since = tonumber(since) }
end

-- Elapsed seconds -> "mm:ss", or "h:mm:ss" past one hour.
function Present.clock(sec: number): string
	local s = math.max(0, math.floor(sec))
	local h = s // 3600
	local m = (s % 3600) // 60
	local ss = s % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, ss)
	end
	return string.format("%02d:%02d", m, ss)
end

-- Bar model. nowS is epoch seconds.
function Present.bar(rec: any, nowS: number): any
	if rec == nil then
		return { visible = false, glyph = "player-record-filled", label = "", elapsed = "", fill = CLEAR, fg = "on_surface", tooltip = "" }
	end
	local kind = if rec.mode == "gif" then "GIF" else "vídeo"
	return {
		visible = true,
		glyph = "player-record-filled",
		label = LABELS[rec.mode],
		elapsed = Present.clock(nowS - rec.since),
		fill = "error",
		fg = "on_error",
		tooltip = "Gravando " .. kind .. ", clique para parar",
	}
end

return Present
