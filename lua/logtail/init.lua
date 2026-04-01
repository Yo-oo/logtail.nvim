local config = require("logtail.config")
local stream = require("logtail.stream")

local M = {}

function M.setup(opts)
	config.setup(opts)
end

function M.start(opts)
	assert(opts and opts.cmd, "[logtail] opts.cmd is required")
	stream.start(opts)
end

function M.stop(title)
	stream.stop(title)
end

function M.clear(title)
	stream.clear(title)
end


function M.list()
	return stream.list()
end

function M.stop_all()
	stream.stop_all()
end

return M
