local assert = require("./support/assert")
local runner = require("./support/runner")
local modules = require("./support/modules")

local describe, it = runner.describe, runner.it

local toml = modules.text("plugin.toml")

describe("plugin.toml", function()
	it("declares the id, api level and the bar widget", function()
		for _, needle in {
			'id = "nandomoreirame/recbar"',
			"plugin_api = 22",
			'entry = "widget.luau"',
		} do
			if string.find(toml, needle, 1, true) == nil then
				error("plugin.toml lacks " .. needle)
			end
		end
	end)

	it("keeps the description within 120 characters", function()
		local description = string.match(toml, '\ndescription%s*=%s*"([^"]*)"')
		assert.equal(description ~= nil and utf8.len(description) <= 120, true)
	end)
end)

describe("lib purity", function()
	it("lib modules never touch host globals", function()
		local source = string.gsub(modules.text("lib/present.luau"), "%-%-[^\n]*", "")
		source = string.gsub(source, '"[^"\n]*"', '""')
		for _, global in { "noctalia%.", "barWidget%.", "panel%.", "ui%." } do
			assert.equal(string.find(source, "%f[%w_]" .. global) == nil, true)
		end
	end)
end)
