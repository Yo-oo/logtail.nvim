local api = vim.api

local M = {}

-- Create a scratch buffer for a stream
function M.create_buf(title)
	local buf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_name(buf, "logtail://" .. title)
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false
	return buf
end

-- Set filetype after buf is attached to a window (treesitter needs a window)
function M.set_filetype(buf, ft)
	vim.bo[buf].filetype = ft
end

-- Disable treesitter fold to prevent "invalid bot" errors on rapid buffer updates.
local function setup_win(win)
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
		local width = math.floor(vim.o.columns * 0.8)
		local height = math.floor(vim.o.lines * (size / 100))
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

	setup_win(win)
	return win
end

-- Append lines to buf with ring buffer trimming
function M.append(buf, lines, max_lines, trim_batch)
	if not api.nvim_buf_is_valid(buf) then
		return
	end

	vim.bo[buf].modifiable = true
	api.nvim_buf_set_lines(buf, -1, -1, false, lines)

	local count = api.nvim_buf_line_count(buf)
	if count > max_lines + trim_batch then
		api.nvim_buf_set_lines(buf, 0, trim_batch, false, {})
	end

	vim.bo[buf].modifiable = false
end

-- Scroll window to the last line only if cursor is near the bottom.
-- This lets users scroll up freely without being yanked back down.
local AUTOSCROLL_THRESHOLD = 10

function M.scroll_to_bottom(win)
	if not api.nvim_win_is_valid(win) then
		return
	end
	local buf = api.nvim_win_get_buf(win)
	local total = api.nvim_buf_line_count(buf)
	local cursor = api.nvim_win_get_cursor(win)[1]
	if total - cursor <= AUTOSCROLL_THRESHOLD then
		api.nvim_win_set_cursor(win, { total, 0 })
	end
end

-- Force scroll to bottom regardless of cursor position (used by resume())
function M.force_scroll_to_bottom(win)
	if not api.nvim_win_is_valid(win) then
		return
	end
	local buf = api.nvim_win_get_buf(win)
	local total = api.nvim_buf_line_count(buf)
	api.nvim_win_set_cursor(win, { total, 0 })
end

return M
