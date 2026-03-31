local M = {}

M.defaults = {
	default_layout = {
		type = "current", -- "split" | "vsplit" | "tab" | "current" | "float"
		size = 15,
	},
	max_lines = 5000,
	trim_batch = 500,
	filetype = "log",
	autoscroll = true,
}

-- Initialize with defaults so start() works without an explicit setup() call.
M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
