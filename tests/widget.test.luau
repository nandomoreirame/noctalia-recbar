local assert = require("./support/assert")
local runner = require("./support/runner")
local mock = require("./support/noctalia_mock")
local entry = require("./support/entry")

local describe, it = runner.describe, runner.it

-- getenv returns nil in the mock, so the widget falls back to /tmp like gsr-toggle.
local STATE = "/tmp/gsr-toggle.state"

local function last(loaded, path)
	local calls = mock.calls(loaded.env, path)
	return calls[#calls]
end

local function texts(node, out)
	out = out or {}
	if typeof(node) == "table" and node.type then
		if node.props.text then
			table.insert(out, node.props.text)
		end
		for _, child in node.children or {} do
			texts(child, out)
		end
	end
	return out
end

local function has(list, value)
	for _, v in list do
		if v == value then
			return true
		end
	end
	return false
end

describe("widget", function()
	it("hides itself when there is no recording", function()
		local w = entry.load("widget.luau", { now = 100_000 })
		assert.equal(last(w, "barWidget.setVisible")[1], false)
	end)

	it("shows REC with the elapsed time while recording", function()
		local w = entry.load("widget.luau", { now = 1_083_000, fs = { [STATE] = "video 1000 /tmp/a.mp4\n" } })
		assert.equal(last(w, "barWidget.setVisible")[1], true)
		local tree = last(w, "barWidget.render")[1]
		assert.equal(tree.props.fill, "error")
		assert.equal(has(texts(tree), "REC"), true)
		assert.equal(has(texts(tree), "01:23"), true)
	end)

	it("polls every second so the counter advances", function()
		local w = entry.load("widget.luau", { now = 0 })
		assert.equal(last(w, "noctalia.setUpdateInterval")[1], 1000)
	end)

	it("re-reads the state on every update", function()
		local w = entry.load("widget.luau", { now = 1_005_000, fs = { [STATE] = "gif 1000 /tmp/a.mp4" } })
		local before = #mock.calls(w.env, "noctalia.readFile")
		w.call("update")
		assert.equal(#mock.calls(w.env, "noctalia.readFile"), before + 1)
		assert.equal(has(texts(last(w, "barWidget.render")[1]), "GIF"), true)
	end)

	it("shows only the glyph on a vertical bar", function()
		local w = entry.load("widget.luau", { vertical = true, now = 1_005_000, fs = { [STATE] = "gif 1000 /tmp/a.mp4" } })
		local tree = last(w, "barWidget.render")[1]
		assert.equal(tree.type, "column")
		assert.equal(#tree.children, 1)
	end)

	it("stops the recording on click", function()
		local done = { exitCode = 0, stdout = "", stderr = "", timedOut = false, stdoutTruncated = false, stderrTruncated = false }
		local w = entry.load("widget.luau", { now = 0, async = { ["$HOME/.dotfiles/bin/utils/gsr-toggle"] = done } })
		w.call("onClick")
		local run = last(w, "noctalia.runAsync")
		assert.equal(string.find(run[1], "gsr-toggle", 1, true) ~= nil, true)
	end)
end)
