-- Minimal init for headless test runs.
-- Adds plenary (cloned by the Makefile) and the plugin itself to runtimepath.

local cwd = vim.fn.getcwd()
vim.opt.runtimepath:prepend(cwd)

local plenary = cwd .. "/.tests/site/pack/deps/start/plenary.nvim"
vim.opt.runtimepath:prepend(plenary)

vim.cmd("runtime plugin/plenary.vim")
