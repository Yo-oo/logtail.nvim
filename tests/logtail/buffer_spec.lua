local buf_m = require("logtail.buffer")

local function gen(prefix, n)
	local t = {}
	for i = 1, n do
		t[i] = prefix .. i
	end
	return t
end

describe("buffer.append ring trimming", function()
	it("keeps an empty first line until real content arrives", function()
		local buf = buf_m.create_buf("test-empty")
		buf_m.append(buf, { "first" }, 100, 10)
		-- A fresh scratch buffer starts with one empty line; append adds after it.
		local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
		assert.same({ "", "first" }, lines)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("trims from the top once over max_lines + trim_batch", function()
		local buf = buf_m.create_buf("test-trim")
		local max_lines, trim_batch = 100, 50

		-- Push well past the trim point in one batch.
		buf_m.append(buf, gen("L", 200), max_lines, trim_batch)

		local count = vim.api.nvim_buf_line_count(buf)
		assert.is_true(count <= max_lines + trim_batch)

		-- The oldest lines must have been removed from the top.
		local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
		assert.is_not.equals("L1", first)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("is a no-op on an invalid buffer", function()
		assert.has_no.errors(function()
			buf_m.append(9999, { "x" }, 100, 10)
		end)
	end)
end)
