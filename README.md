# logtail.nvim

Stream any shell command's output into a Neovim buffer with syntax highlighting.

Inspired by the log panel in [flutter-tools.nvim](https://github.com/nvim-flutter/flutter-tools.nvim).

## Demo

https://github.com/user-attachments/assets/7c1e95d1-919f-43ba-9dac-75a1461117d9

## Why

Log viewers like k9s, stern, and Loki are great tools — but they live outside Neovim. logtail.nvim brings log output into a regular buffer, so you can use everything you already know: `/` search, `y` yank, syntax highlights, keymaps, and more.

## Requirements

- Neovim >= 0.10
- A log syntax highlighter of your choice (the buffer filetype is set to `log`):
  - [tree-sitter-log](https://github.com/Tudyx/tree-sitter-log) — treesitter-based
  - [vim-log-highlighting](https://github.com/MTDL9/vim-log-highlighting) — regex-based, no extra dependencies

## Installation

```lua
-- lazy.nvim
{
  "Yo-oo/logtail.nvim",
  opts = {},
}
```

## Usage

### Lua API

```lua
local logtail = require("logtail")

-- Start streaming a command
logtail.start({
  cmd        = "kubectl logs -f mypod -n app --tail=5000",
  title      = "mypod",             -- buffer name (optional, defaults to first 40 chars of cmd)
  layout     = { type = "split" },  -- optional, overrides default_layout
  -- Per-stream overrides (optional, fall back to setup() config):
  max_lines  = 10000,
  trim_batch = 1000,
  autoscroll = true,
})

-- Control streams
logtail.stop("mypod")   -- stop and clean up
logtail.clear("mypod")  -- clear the buffer, keep streaming
logtail.stop_all()      -- stop all active streams
logtail.list()          -- returns a list of active stream titles
```

Autoscroll is handled automatically: scrolling up pauses it, pressing `G` resumes it.

### Commands

| Command                     | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `:LogStart <cmd>`           | Start streaming `<cmd>`                            |
| `:LogStart <title> -- <cmd>`| Start with an explicit title                       |
| `:LogStop <title>`          | Stop a stream (Tab to complete title)             |
| `:LogClear <title>`         | Clear a buffer's contents (stream keeps running)  |
| `:LogList`                  | List active streams                               |
| `:LogStopAll`               | Stop all streams                                  |

## Configuration

```lua
require("logtail").setup({
  default_layout = {
    type = "current",  -- "split" | "vsplit" | "tab" | "current" | "float"
    size = 15,         -- lines for split/vsplit (ignored by float)
    -- For type = "float", size is ignored; use editor fractions instead:
    -- width  = 0.8,
    -- height = 0.8,
  },
  max_lines  = 5000, -- ring buffer size per stream
  trim_batch = 500,  -- lines removed per trim cycle
  filetype   = "log",  -- set to match your log highlighter's expected filetype
  autoscroll = true,
})
```

`max_lines`, `trim_batch`, and `autoscroll` can also be overridden per stream via `logtail.start({ ... })`.

Run `:checkhealth logtail` to verify your setup (Neovim version, `sh`, and the tree-sitter `log` parser).

## Picker integration

logtail.nvim has no built-in picker dependency. Use whichever picker you prefer:

### fzf-lua

```lua
vim.keymap.set("n", "<leader>kl", function()
  require("fzf-lua").fzf_exec(
    "kubectl get pods -n app --no-headers | awk '{print $1}'",
    {
      prompt = "Pod > ",
      actions = {
        ["default"] = function(selected)
          require("logtail").start({
            cmd   = "kubectl logs -f " .. selected[1] .. " -n app --tail=5000",
            title = selected[1],
          })
        end,
      },
    }
  )
end, { desc = "Tail pod logs" })
```

### vim.ui.select (no extra dependencies)

```lua
vim.keymap.set("n", "<leader>kl", function()
  local pods = vim.fn.systemlist("kubectl get pods -n app --no-headers | awk '{print $1}'")
  vim.ui.select(pods, { prompt = "Select pod:" }, function(pod)
    if not pod then return end
    require("logtail").start({
      cmd   = "kubectl logs -f " .. pod .. " -n app --tail=5000",
      title = pod,
    })
  end)
end, { desc = "Tail pod logs" })
```

## Scrolling behaviour

- **Autoscroll** follows the latest output by default.
- Scroll up freely — autoscroll pauses automatically when your cursor moves away from the bottom.
- Press `G` to jump back to the bottom and resume autoscroll.

## Notes on large initial output

For commands that produce a large backlog before streaming (e.g. long-running pods), limit the initial output on the command side:

```bash
kubectl logs -f mypod --tail=5000   # recommended
docker logs -f mycontainer --tail=5000
```

Piping through `tail -n N` does **not** work for follow-mode commands — `tail` buffers until EOF, which a follow command never sends.

## Contributing

Bug reports and PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the
project layout, how to run the tests (`make test`), and manual testing tips.

## License

MIT
