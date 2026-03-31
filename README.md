# logtail.nvim

Stream any shell command's output into a Neovim buffer with syntax highlighting.

Inspired by the log panel in [flutter-tools.nvim](https://github.com/nvim-flutter/flutter-tools.nvim).

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
  cmd   = "kubectl logs -f mypod -n app --tail=5000",
  title = "mypod",             -- buffer name (optional, defaults to first 40 chars of cmd)
  layout = { type = "split" }, -- optional, overrides default_layout
})

-- Control streams
logtail.stop("mypod")          -- stop and clean up
logtail.pause("mypod")         -- freeze autoscroll (stream keeps running)
logtail.resume("mypod")        -- resume autoscroll and jump to bottom
logtail.toggle("mypod")        -- pause / resume toggle
logtail.stop_all()             -- stop all active streams

-- Query
logtail.list()                 -- returns a list of active stream titles
```

### Commands

| Command              | Description             |
| -------------------- | ----------------------- |
| `:LogStart <cmd>`    | Start streaming `<cmd>` |
| `:LogStop <title>`   | Stop a stream           |
| `:LogPause <title>`  | Pause autoscroll        |
| `:LogResume <title>` | Resume autoscroll       |
| `:LogToggle <title>` | Toggle pause/resume     |
| `:LogList`           | List active streams     |
| `:LogStopAll`        | Stop all streams        |

## Configuration

```lua
require("logtail").setup({
  default_layout = {
    type = "current",  -- "split" | "vsplit" | "tab" | "current" | "float"
    size = 15,       -- lines for split/vsplit, percentage for float
  },
  max_lines  = 5000, -- ring buffer size per stream
  trim_batch = 500,  -- lines removed per trim cycle
  filetype   = "log",  -- set to match your log highlighter's expected filetype
  autoscroll = true,
})
```

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
- Use `:LogPause` / `:LogToggle` to keep the stream running while reading without autoscroll.

## Notes on large initial output

For commands that produce a large backlog before streaming (e.g. long-running pods), limit the initial output on the command side:

```bash
kubectl logs -f mypod --tail=5000   # recommended
docker logs -f mycontainer --tail=5000
```

Piping through `tail -n N` does **not** work for follow-mode commands — `tail` buffers until EOF, which a follow command never sends.

## License

MIT
