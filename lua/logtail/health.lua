local M = {}

local function check_nvim()
	if vim.fn.has("nvim-0.10") == 1 then
		vim.health.ok("Neovim >= 0.10")
	else
		vim.health.error("Neovim 0.10+ is required (uses vim.uv / vim.health)")
	end
end

local function check_shell()
	if vim.fn.executable("sh") == 1 then
		vim.health.ok("`sh` found in PATH")
	else
		vim.health.error("`sh` not found in PATH; streams are run via `sh -c`")
	end
end

local function check_treesitter()
	local config = require("logtail.config")
	local ft = config.options.filetype

	-- The core value prop is tree-sitter-log highlighting. The parser language
	-- name matches the `log` filetype regardless of the configured filetype.
	local ok = pcall(vim.treesitter.language.add, "log")
	if ok then
		vim.health.ok("tree-sitter `log` parser is installed")
	else
		vim.health.warn(
			"tree-sitter `log` parser not found",
			{ "Install it for syntax highlighting, e.g. `:TSInstall log`" }
		)
	end

	if ft ~= "log" then
		vim.health.info(("configured filetype is `%s` (default: `log`)"):format(ft))
	end
end

function M.check()
	vim.health.start("logtail.nvim")
	check_nvim()
	check_shell()
	check_treesitter()
end

return M
