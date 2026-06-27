local api = vim.api

local M = {}

-- Create a scratch buffer for a stream
function M.create_buf(title)
	local name = "logtail://" .. title
	-- Delete any orphaned buffer with the same name (e.g. after a restart).
	local existing = vim.fn.bufnr(name)
	if existing ~= -1 then
		api.nvim_buf_delete(existing, { force = true })
	end
	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_name(buf, name)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	return buf
end

-- Clear all lines in the buffer without stopping the stream
function M.clear(buf)
	if not api.nvim_buf_is_valid(buf) then return end
	vim.bo[buf].modifiable = true
	api.nvim_buf_set_lines(buf, 0, -1, false, {})
	vim.bo[buf].modifiable = false
end

-- Set filetype after buf is attached to a window (treesitter needs a window)
function M.set_filetype(buf, ft)
	vim.bo[buf].filetype = ft
end

-- Disable treesitter fold to prevent "invalid bot" errors on rapid buffer updates.
function M.setup_win(win)
	vim.wo[win].foldenable = false
	vim.wo[win].foldmethod = "manual"
end

-- Open a window for buf according to layout config
-- Returns the window id
function M.open_win(buf, title, layout)
	local t = layout.type or "split"
	local size = layout.size or 15
	local win

	if t == "split" then
		vim.cmd(size .. "split")
		win = api.nvim_get_current_win()
		api.nvim_win_set_buf(win, buf)
	elseif t == "vsplit" then
		vim.cmd(size .. "vsplit")
		win = api.nvim_get_current_win()
		api.nvim_win_set_buf(win, buf)
	elseif t == "tab" then
		vim.cmd("tabnew")
		win = api.nvim_get_current_win()
		api.nvim_win_set_buf(win, buf)
	elseif t == "current" then
		win = api.nvim_get_current_win()
		api.nvim_win_set_buf(win, buf)
	elseif t == "float" then
		-- Float ignores `size`; use width/height as editor fractions instead.
		-- `size / 100` is kept as a height fallback for backward compatibility.
		local wfrac = layout.width or 0.8
		local hfrac = layout.height or (size / 100)
		local width = math.floor(vim.o.columns * wfrac)
		local height = math.floor(vim.o.lines * hfrac)
		local row = math.floor((vim.o.lines - height) / 2)
		local col = math.floor((vim.o.columns - width) / 2)
		win = api.nvim_open_win(buf, true, {
			relative = "editor",
			row = row,
			col = col,
			width = width,
			height = height,
			style = "minimal",
			border = "rounded",
			title = " logtail: " .. title .. " ",
			title_pos = "center",
		})
	else
		-- fallback
		vim.cmd(size .. "split")
		win = api.nvim_get_current_win()
		api.nvim_win_set_buf(win, buf)
	end

	M.setup_win(win)
	return win
end

-- Append lines to buf with ring buffer trimming
function M.append(buf, lines, max_lines, trim_batch)
	if not api.nvim_buf_is_valid(buf) then
		return
	end

	vim.bo[buf].modifiable = true
	api.nvim_buf_set_lines(buf, -1, -1, false, lines)

	-- Hysteresis: only trim once we exceed max_lines by a full batch, but then
	-- drop everything above max_lines so a large single append can't stay over.
	local count = api.nvim_buf_line_count(buf)
	if count > max_lines + trim_batch then
		api.nvim_buf_set_lines(buf, 0, count - max_lines, false, {})
	end

	vim.bo[buf].modifiable = false
end

-- Scroll window to the last line only if the bottom of the buffer is already
-- (nearly) in view. This is based on the window's viewport, not the cursor, so
-- it works even when focus is elsewhere and lets users scroll up freely without
-- being yanked back down.
local AUTOSCROLL_THRESHOLD = 10

function M.scroll_to_bottom(win)
	if not api.nvim_win_is_valid(win) then
		return
	end
	local buf = api.nvim_win_get_buf(win)
	local total = api.nvim_buf_line_count(buf)
	local botline = api.nvim_win_call(win, function()
		return vim.fn.line("w$")
	end)
	if total - botline <= AUTOSCROLL_THRESHOLD then
		api.nvim_win_set_cursor(win, { total, 0 })
	end
end

return M
