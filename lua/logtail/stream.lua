local buf_m  = require("logtail.buffer")
local config = require("logtail.config")
local util   = require("logtail.util")

local M = {}

-- streams[title] = { job_id, buf, win, timer }
M.streams = {}

local FLUSH_INTERVAL_MS = 80

-- Internal: start a job writing into an existing buf/win.
local function start_job(title, buf, win, opts)
	local max_lines  = opts.max_lines or config.options.max_lines
	local trim_batch = opts.trim_batch or config.options.trim_batch
	local autoscroll = opts.autoscroll
	if autoscroll == nil then
		autoscroll = config.options.autoscroll
	end

	local pending = {}
	local stdout_partial = ""
	local stderr_partial = ""

	local timer = vim.uv.new_timer()
	timer:start(FLUSH_INTERVAL_MS, FLUSH_INTERVAL_MS, vim.schedule_wrap(function()
		if not M.streams[title] or #pending == 0 then return end

		local lines = pending
		pending = {}
		buf_m.append(buf, lines, max_lines, trim_batch)

		if autoscroll then
			buf_m.scroll_to_bottom(win)
		end
	end))

	local function push(lines)
		for _, line in ipairs(lines) do
			pending[#pending + 1] = line
		end
		-- Bound `pending` between flushes so a burst can't blow up memory.
		if #pending > max_lines * 2 then
			local keep = {}
			for i = #pending - max_lines + 1, #pending do
				keep[#keep + 1] = pending[i]
			end
			pending = keep
		end
	end

	local job_id = vim.fn.jobstart({ "sh", "-c", opts.cmd }, {
		stdout_buffered = false,
		on_stdout = function(_, data)
			local lines
			lines, stdout_partial = util.process_chunk(stdout_partial, data)
			push(lines)
		end,
		on_stderr = function(_, data)
			local lines
			lines, stderr_partial = util.process_chunk(stderr_partial, data)
			push(lines)
		end,
		on_exit = function(_, code)
			if not M.streams[title] then return end
			if stdout_partial ~= "" then pending[#pending + 1] = stdout_partial end
			if stderr_partial ~= "" then pending[#pending + 1] = stderr_partial end
			if #pending > 0 then
				buf_m.append(buf, pending, max_lines, trim_batch)
				pending = {}
			end
			buf_m.append(buf, { "", "[logtail] process exited with code " .. code }, max_lines, trim_batch)
		end,
	})

	if job_id == 0 or job_id == -1 then
		vim.notify("[logtail] failed to start: " .. opts.cmd, vim.log.levels.ERROR)
		timer:stop()
		timer:close()
		return false
	end

	M.streams[title] = { job_id = job_id, buf = buf, win = win, timer = timer }
	return true
end

-- Internal: stop only the job and timer, leave buf/win untouched.
local function stop_job(title)
	local stream = M.streams[title]
	if not stream then return end
	if stream.timer then
		stream.timer:stop()
		stream.timer:close()
	end
	if stream.job_id then
		vim.fn.jobstop(stream.job_id)
	end
	M.streams[title] = nil
end

function M.start(opts)
	local title  = opts.title or opts.cmd:sub(1, 40)
	local layout = vim.tbl_deep_extend("force", config.options.default_layout, opts.layout or {})
	local ft     = config.options.filetype

	-- Reuse the existing window on restart instead of leaking a new one.
	local existing = M.streams[title]
	local reuse_win
	if existing then
		if existing.win and vim.api.nvim_win_is_valid(existing.win) then
			reuse_win = existing.win
		end
		stop_job(title)
	end

	local buf = buf_m.create_buf(title)
	local win
	if reuse_win then
		vim.api.nvim_win_set_buf(reuse_win, buf)
		buf_m.setup_win(reuse_win)
		win = reuse_win
	else
		win = buf_m.open_win(buf, title, layout)
	end
	buf_m.set_filetype(buf, ft)

	if not start_job(title, buf, win, opts) then return end

	-- Auto-stop when the buffer is wiped (e.g. user closes the window with :q).
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function() stop_job(title) end,
	})
end

function M.stop(title)
	stop_job(title)
end

function M.clear(title)
	local stream = M.streams[title]
	if not stream then return end
	buf_m.clear(stream.buf)
end

function M.list()
	local titles = {}
	for t in pairs(M.streams) do
		table.insert(titles, t)
	end
	return titles
end

function M.stop_all()
	local titles = M.list()
	for _, title in ipairs(titles) do
		stop_job(title)
	end
end

return M
