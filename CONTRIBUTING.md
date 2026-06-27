# Contributing

Thanks for your interest in improving logtail.nvim!

## Project layout

```
plugin/logtail.lua      user commands (:LogStart, :LogStop, ...)
lua/logtail/init.lua    public Lua API
lua/logtail/stream.lua  job lifecycle, flush timer, ring-buffer feeding
lua/logtail/buffer.lua  buffer/window creation, append + trim, autoscroll
lua/logtail/config.lua  defaults and setup()
lua/logtail/util.lua    pure helpers (chunk reassembly)
lua/logtail/health.lua  :checkhealth logtail
doc/logtail.txt         vimdoc
tests/                  plenary tests
```

## Running the tests

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

```bash
make test
```

The first run clones plenary into `.tests/` (gitignored). Subsequent runs reuse
it. To start clean:

```bash
make clean && make test
```

If you already have plenary installed (e.g. via lazy.nvim) and prefer not to
clone it, point Neovim at your copy instead:

```bash
nvim --headless --noplugin \
  -u <(printf 'lua vim.opt.runtimepath:prepend(vim.fn.getcwd())\nlua vim.opt.runtimepath:prepend(vim.fn.stdpath("data").."/lazy/plenary.nvim")\nruntime plugin/plenary.vim\n') \
  -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
```

### Writing tests

- Pure logic (no Neovim API) goes in `lua/logtail/util.lua` and is tested in
  `tests/logtail/util_spec.lua` — these are the cheapest and most valuable to add.
- Tests that need the Neovim API (buffers, windows) run inside the headless
  Neovim that plenary spawns; see `tests/logtail/buffer_spec.lua`. Always clean
  up buffers/windows you create.

## Manual / interactive testing

To try the working tree in an isolated Neovim (without your normal config or a
lazy-installed copy of the plugin):

```bash
nvim -u <(printf '%s\n' \
  'lua vim.opt.runtimepath:prepend(vim.fn.getcwd())' \
  'runtime plugin/logtail.lua' \
  'autocmd FileType log lua pcall(vim.treesitter.start, 0, "log")')
```

Then exercise the main paths:

```vim
" streaming + autoscroll
:LogStart for i in $(seq 1 100000); do echo "line $i"; sleep 0.05; done
"   - output should follow the bottom
"   - scroll up (k): autoscroll pauses
"   - press G: jumps to bottom and resumes

" explicit title + restart reuses the same window (no leaked split)
:LogStart mylog -- echo first
:LogStart mylog -- echo second

" partial (no trailing newline) line is flushed intact on exit
:LogStart printf 'no-newline-tail'; sleep 2; echo ' DONE'

" management
:LogList
:LogClear mylog
:LogStop mylog
:checkhealth logtail
```

## Conventions

- Tabs for indentation (matching the existing files).
- Keep Neovim-API-free logic in `util.lua` so it stays unit-testable.
- Update `doc/logtail.txt` and `README.md` when you change the public API,
  commands, or config options.

## Pull requests

- Run `make test` and make sure it passes.
- Keep changes focused; one logical change per PR where practical.
