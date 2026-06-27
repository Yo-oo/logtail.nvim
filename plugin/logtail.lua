local logtail = require("logtail")

-- :LogStart <cmd>
-- :LogStart <title> -- <cmd>   (explicit title before a `--` separator)
vim.api.nvim_create_user_command("LogStart", function(args)
	local title, cmd = args.args:match("^(.-)%s+%-%-%s+(.+)$")
	if title and title ~= "" and cmd then
		logtail.start({ title = title, cmd = cmd })
	else
		logtail.start({ cmd = args.args })
	end
end, { nargs = "+", desc = "Start streaming a command into a log buffer ([<title> --] <cmd>)" })

-- :LogStop <title>
vim.api.nvim_create_user_command("LogStop", function(args)
	logtail.stop(args.args)
end, {
	nargs = 1,
	complete = function() return logtail.list() end,
	desc = "Stop a log stream by title",
})

-- :LogClear <title>
vim.api.nvim_create_user_command("LogClear", function(args)
	logtail.clear(args.args)
end, {
	nargs = 1,
	complete = function() return logtail.list() end,
	desc = "Clear log buffer contents (stream keeps running)",
})

-- :LogList
vim.api.nvim_create_user_command("LogList", function()
	local titles = logtail.list()
	if #titles == 0 then
		vim.notify("[logtail] no active streams", vim.log.levels.INFO)
	else
		vim.notify("[logtail] active streams:\n  " .. table.concat(titles, "\n  "), vim.log.levels.INFO)
	end
end, { nargs = 0, desc = "List all active log streams" })

-- :LogStopAll
vim.api.nvim_create_user_command("LogStopAll", function()
	logtail.stop_all()
	vim.notify("[logtail] all streams stopped", vim.log.levels.INFO)
end, { nargs = 0, desc = "Stop all active log streams" })
