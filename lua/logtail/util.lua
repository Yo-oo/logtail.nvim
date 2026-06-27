local M = {}

-- Reassemble jobstart stdout/stderr chunks into complete lines.
--
-- Neovim's channel protocol splits output on newlines, but the final element
-- of `data` is a *partial* line that must be joined with the first element of
-- the next chunk. An empty final element means the chunk ended on a newline.
--
-- Returns: (complete_lines, new_partial)
function M.process_chunk(partial, data)
	local out = {}
	local n = #data
	if n == 0 then
		return out, partial
	end

	-- The first element always continues the carried-over partial line.
	local first = partial .. data[1]
	if n == 1 then
		-- No newline seen yet; everything is still pending.
		return out, first
	end

	out[1] = first
	for i = 2, n - 1 do
		out[#out + 1] = data[i]
	end
	-- The last element is the new partial (empty string if chunk ended cleanly).
	return out, data[n]
end

return M
