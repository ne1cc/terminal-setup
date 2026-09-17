local map = vim.keymap.set
local opts = { buffer = true, silent = true }

-- Cycle checklist state: [ ] -> [x] -> [-] -> [ ]
local function toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  local patterns = {
    { "^(%s*[%*%-+]%s+)%[%s*%]", "%1[x]" }, -- [ ] -> [x]
    { "^(%s*[%*%-+]%s+)%[x%]", "%1[-]" }, -- [x] -> [-]
    { "^(%s*[%*%-+]%s+)%[%-%]", "%1[ ]" }, -- [-] -> [ ]
    { "^(%s*[%*%-+])%s+(%S)", "%1 [ ] %2" }, -- plain bullet -> [ ]
  }

  for _, item in ipairs(patterns) do
    local match, count = line:gsub(item[1], item[2])
    if count > 0 then
      vim.api.nvim_set_current_line(match)
      return
    end
  end
end

-- Insert a continuation bullet or numbered list item
local function insert_bullet()
  local line = vim.api.nvim_get_current_line()
  local bullet_match = line:match("^(%s*[%*%-+]%s+)")
  local checkbox_match = line:match("^(%s*[%*%-+]%s+%[[%sx%-]%]+%s+)")
  local num_match = line:match("^(%s*(%d+)%.%s+)")

  if checkbox_match then
    local indent = line:match("^(%s*[%*%-+])")
    vim.api.nvim_put({ indent .. " [ ] " }, "l", true, true)
  elseif bullet_match then
    vim.api.nvim_put({ bullet_match }, "l", true, true)
  elseif num_match then
    local num = tonumber(line:match("^%s*(%d+)%.%s+"))
    local indent = line:match("^(%s*)")
    vim.api.nvim_put({ indent .. tostring((num or 1) + 1) .. ". " }, "l", true, true)
  else
    vim.api.nvim_put({ "- " }, "l", true, true)
  end
  vim.cmd.startinsert()
end

-- Markdown display modes:
-- 1. "rendered" (prose default): Rich rendering, soft wrap ON (linebreak, breakindent)
-- 2. "table" (table view): Rich rendering, soft wrap OFF (tables stay on single lines without wrapping)
-- 3. "raw" (as-is view): Plain text, render-markdown OFF, wrap OFF, conceallevel=0
local function set_markdown_mode(mode)
  local rm_avail, rm = pcall(require, "render-markdown")

  if mode == "raw" then
    if rm_avail then
      rm.set_buf(false)
    end
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 8
    vim.wo.conceallevel = 0
    vim.wo.concealcursor = ""
    vim.b.markdown_display_mode = "raw"
    vim.notify("Markdown: Raw (As-Is) mode [nowrap, conceal=0]", vim.log.levels.INFO, { title = "Markdown Display" })
  elseif mode == "table" then
    if rm_avail then
      rm.set_buf(true)
    end
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 8
    vim.wo.conceallevel = 2
    vim.wo.concealcursor = "nc"
    vim.b.markdown_display_mode = "table"
    vim.notify("Markdown: Rendered Table mode [nowrap, conceal=2]", vim.log.levels.INFO, { title = "Markdown Display" })
  else -- "rendered" (prose default)
    if rm_avail then
      rm.set_buf(true)
    end
    vim.wo.wrap = true
    vim.wo.sidescrolloff = 8
    vim.wo.linebreak = true
    vim.wo.breakindent = true
    vim.wo.breakindentopt = "shift:2,min:20"
    vim.wo.showbreak = "↳ "
    vim.wo.conceallevel = 2
    vim.wo.concealcursor = "nc"
    vim.b.markdown_display_mode = "rendered"
    vim.notify("Markdown: Rendered mode [prose wrap, conceal=2]", vim.log.levels.INFO, { title = "Markdown Display" })
  end
end

-- Toggle between Rendered (Prose) and Raw (As-Is)
local function toggle_raw_as_is()
  local current = vim.b.markdown_display_mode or (vim.wo.wrap and "rendered" or "table")
  if current == "raw" then
    set_markdown_mode("rendered")
  else
    set_markdown_mode("raw")
  end
end

-- Toggle wrap on/off (Prose wrap vs Table nowrap) without disabling rendering
local function toggle_markdown_wrap()
  if vim.wo.wrap then
    vim.wo.wrap = false
    if vim.b.markdown_display_mode ~= "raw" then
      vim.b.markdown_display_mode = "table"
    end
    vim.notify("Markdown Wrap: OFF (Table / No-wrap mode)", vim.log.levels.INFO, { title = "Markdown Display" })
  else
    vim.wo.wrap = true
    vim.wo.linebreak = true
    vim.wo.breakindent = true
    vim.wo.breakindentopt = "shift:2,min:20"
    vim.wo.showbreak = "↳ "
    if vim.b.markdown_display_mode ~= "raw" then
      vim.b.markdown_display_mode = "rendered"
    end
    vim.notify("Markdown Wrap: ON (Prose wrap mode)", vim.log.levels.INFO, { title = "Markdown Display" })
  end
end

-- Cycle between all 3 modes: rendered -> table -> raw -> rendered
local function cycle_markdown_mode()
  local current = vim.b.markdown_display_mode or (vim.wo.wrap and "rendered" or "table")
  if current == "rendered" then
    set_markdown_mode("table")
  elseif current == "table" then
    set_markdown_mode("raw")
  else
    set_markdown_mode("rendered")
  end
end

-- Buffer-local commands
vim.api.nvim_buf_create_user_command(0, "MarkdownMode", function(cmd_opts)
  local arg = (cmd_opts.args or ""):lower():gsub("%s+", "")
  if arg == "raw" or arg == "asis" or arg == "plain" then
    set_markdown_mode("raw")
  elseif arg == "table" or arg == "nowrap" then
    set_markdown_mode("table")
  elseif arg == "rendered" or arg == "wrap" or arg == "prose" then
    set_markdown_mode("rendered")
  elseif arg == "" then
    cycle_markdown_mode()
  else
    vim.notify("Unknown Markdown mode: " .. arg .. ". Options: rendered | table | raw", vim.log.levels.WARN)
  end
end, {
  nargs = "?",
  complete = function()
    return { "rendered", "table", "raw" }
  end,
  desc = "Set or cycle Markdown display mode (rendered, table, raw)",
})

vim.api.nvim_buf_create_user_command(0, "MarkdownRaw", function()
  set_markdown_mode("raw")
end, { desc = "Switch to Markdown Raw (As-Is) mode" })

-- Toggle full-width viewport matching current terminal/screen width
local function toggle_fit_viewport()
  local tab = vim.api.nvim_get_current_tabpage()
  _G._markdown_viewport_state = _G._markdown_viewport_state or {}
  local state = _G._markdown_viewport_state[tab]

  if state and state.is_fit then
    -- Restore previous state
    if state.maximize_active then
      pcall(function()
        require("maximize").restore()
      end)
    end
    if state.tmux_zoomed and vim.env.TMUX then
      local zoomed = vim.fn.system("tmux display-message -p '#{window_zoomed_flag}'"):gsub("%s+", "")
      if zoomed == "1" then
        vim.fn.system("tmux resize-pane -Z")
      end
    end
    if state.neotree_was_open then
      pcall(function()
        require("neo-tree.command").execute({ action = "show" })
      end)
    end
    vim.wo.wrap = state.prev_wrap
    _G._markdown_viewport_state[tab] = nil
    vim.notify("Viewport restored to normal layout", vim.log.levels.INFO, { title = "Markdown Viewport" })
  else
    -- Expand viewport to match full terminal screen width
    local prev_wrap = vim.wo.wrap
    local neotree_was_open = false
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "neo-tree" then
        neotree_was_open = true
        break
      end
    end
    if neotree_was_open then
      pcall(function()
        require("neo-tree.command").execute({ action = "close" })
      end)
    end

    local maximize_active = false
    local max_avail, maximize = pcall(require, "maximize")
    if max_avail and not vim.t.maximized then
      local normal_wins = 0
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
          normal_wins = normal_wins + 1
        end
      end
      if normal_wins > 1 then
        maximize.maximize()
        maximize_active = true
      end
    end

    local tmux_zoomed = false
    if vim.env.TMUX then
      local zoomed = vim.fn.system("tmux display-message -p '#{window_zoomed_flag}'"):gsub("%s+", "")
      if zoomed == "0" then
        vim.fn.system("tmux resize-pane -Z")
        tmux_zoomed = true
      end
    end

    -- Disable wrapping so the table lays out in its true rectangular box format
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 8
    vim.b.markdown_display_mode = "table"

    _G._markdown_viewport_state[tab] = {
      is_fit = true,
      neotree_was_open = neotree_was_open,
      maximize_active = maximize_active,
      tmux_zoomed = tmux_zoomed,
      prev_wrap = prev_wrap,
    }
    vim.notify("Viewport matched to full screen width [nowrap, full-width]", vim.log.levels.INFO, { title = "Markdown Viewport" })
  end
end

vim.api.nvim_buf_create_user_command(0, "MarkdownFitViewport", toggle_fit_viewport, {
  desc = "Expand viewport to match full terminal/screen width without wrapping or overflow",
})

map("n", "<leader>mx", toggle_checkbox, vim.tbl_extend("force", opts, { desc = "Toggle checkbox" }))
map("n", "<leader>mi", insert_bullet, vim.tbl_extend("force", opts, { desc = "Insert list item" }))
map("n", "<leader>mr", toggle_raw_as_is, vim.tbl_extend("force", opts, { desc = "Toggle Raw (As-Is) / Rendered" }))
map("n", "<leader>mw", toggle_markdown_wrap, vim.tbl_extend("force", opts, { desc = "Toggle wrap (Prose / Table mode)" }))
map("n", "<leader>mz", toggle_fit_viewport, vim.tbl_extend("force", opts, { desc = "Fit viewport to full screen width" }))
map("n", "<leader>mm", cycle_markdown_mode, vim.tbl_extend("force", opts, { desc = "Cycle display mode (Prose/Table/Raw)" }))
map("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", vim.tbl_extend("force", opts, { desc = "Markdown browser preview" }))
