-- Automatically reload files changed outside of Neovim immediately
vim.o.autoread = true

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

vim.opt.clipboard = "unnamedplus"

local function open_system(path)
  local cmd
  if vim.fn.has("win32") == 1 then
    cmd = { "cmd.exe", "/c", "start", '""', path }
  elseif vim.fn.has("mac") == 1 then
    cmd = { "open", path }
  else
    cmd = { "xdg-open", path }
  end
  vim.fn.jobstart(cmd, { detach = true })
end

vim.keymap.set("n", "<Leader>gx", function()
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" then
    open_system(file)
  else
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
  end
end, { desc = "Open file in system viewer silently" })

vim.keymap.set("n", "gx", function()
  local file = vim.fn.expand("<cfile>")
  if not file or file == "" or file:match("^%s+$") or file == "|" then
    return
  end
  if file:match("^[%w%-%.]+/[%w%-%.]+$") and vim.fn.filereadable(file) == 0 then
    file = "https://github.com/" .. file
  end
  open_system(file)
end, { desc = "Open file or URL under cursor silently" })

vim.keymap.set("x", "gx", function()
  local old_reg = vim.fn.getreg('"')
  vim.cmd("normal! y")
  local selection = vim.fn.getreg('"')
  vim.fn.setreg('"', old_reg)
  selection = selection:gsub("^%s*(.-)%s*$", "%1")
  if selection ~= "" and selection ~= "|" then
    open_system(selection)
  end
end, { desc = "Open selected file or URL silently" })

vim.keymap.set("n", "<leader>ic", function()
  if pcall(require, "image") then
    require("image").clear()
  end
  if pcall(require, "diagram") then
    require("diagram").clear()
  end
  -- Send native Kitty Graphics Protocol delete-all sequence
  local clear_seq = "\x1b_Ga=d,d=a\x1b\\"
  if vim.env.TMUX then
    clear_seq = "\x1bPtmux;\x1b\x1b_Ga=d,d=a\x1b\x1b\\\x1b\\"
  end
  io.stdout:write(clear_seq)
  io.stdout:flush()
  vim.cmd("redraw!")
  vim.notify("Cleared all image and diagram overlays", vim.log.levels.INFO, { title = "Image Overlays" })
end, { desc = "Clear image and diagram overlay artifacts" })

local function resolve_companion_file(extension)
  local cfile = vim.fn.expand("<cfile>")
  if cfile ~= "" and vim.fn.filereadable(cfile) == 1 and cfile:match("%." .. extension .. "$") then
    return cfile
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file:match("%." .. extension .. "$") then
    return current_file
  end

  local companion = vim.fn.expand("%:p:r") .. "." .. extension
  if vim.fn.filereadable(companion) == 1 then
    return companion
  end

  return nil
end

local function open_in_mupdf()
  local target = resolve_companion_file("pdf")
  if not target then
    vim.notify("No valid PDF found to open.", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ "mupdf", vim.fn.fnamemodify(target, ":p") }, { detach = true })
end

local function open_in_omnireader()
  local target = resolve_companion_file("epub")
  if not target then
    vim.notify("No valid EPUB found to open.", vim.log.levels.WARN)
    return
  end
  local absolute_target = vim.fn.fnamemodify(target, ":p")
  if vim.fn.has("mac") == 1 then
    vim.fn.jobstart({ "open", "-a", "OmniReader", absolute_target }, { detach = true })
  elseif vim.fn.executable("xdg-open") == 1 then
    vim.fn.jobstart({ "xdg-open", absolute_target }, { detach = true })
  else
    vim.notify("No EPUB viewer found.", vim.log.levels.WARN)
  end
end

local function is_markdown(path)
  return path:match("%.md$") or path:match("%.markdown$")
end

local function resolve_markdown_file()
  local cfile = vim.fn.expand("<cfile>")
  if cfile ~= "" and vim.fn.filereadable(cfile) == 1 and is_markdown(cfile) then
    return cfile
  end

  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file ~= "" and is_markdown(current_file) then
    return current_file
  end

  for _, ext in ipairs({ "md", "markdown" }) do
    local companion = vim.fn.expand("%:p:r") .. "." .. ext
    if vim.fn.filereadable(companion) == 1 then
      return companion
    end
  end

  return nil
end

local function open_in_one_markdown()
  local target = resolve_markdown_file()
  if not target then
    vim.notify("No valid Markdown file found to open.", vim.log.levels.WARN)
    return
  end
  local absolute_target = vim.fn.fnamemodify(target, ":p")
  if vim.fn.has("mac") == 1 then
    vim.fn.jobstart({ "open", "-a", "One Markdown", absolute_target }, { detach = true })
  elseif vim.fn.executable("glow") == 1 then
    vim.fn.jobstart({ "glow", "-p", absolute_target }, { detach = true })
  elseif vim.fn.executable("xdg-open") == 1 then
    vim.fn.jobstart({ "xdg-open", absolute_target }, { detach = true })
  else
    vim.notify("No Markdown viewer found.", vim.log.levels.WARN)
  end
end

local function open_in_marktext()
  local target = resolve_markdown_file()
  if not target then
    vim.notify("No valid Markdown file found to open.", vim.log.levels.WARN)
    return
  end
  local absolute_target = vim.fn.fnamemodify(target, ":p")
  if vim.fn.has("mac") == 1 then
    vim.fn.jobstart({ "open", "-na", "Mark Text", "--args", absolute_target }, { detach = true })
  elseif vim.fn.executable("marktext") == 1 then
    vim.fn.jobstart({ "marktext", absolute_target }, { detach = true })
  else
    vim.notify("Mark Text not found.", vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<leader>op", open_in_mupdf, { desc = "Open PDF in MuPDF", silent = true })
vim.keymap.set("n", "<leader>oe", open_in_omnireader, { desc = "Open EPUB in OmniReader", silent = true })
vim.keymap.set("n", "<leader>om", open_in_one_markdown, { desc = "Open Markdown in One Markdown", silent = true })
vim.keymap.set("n", "<leader>mt", open_in_marktext, { desc = "Open Markdown in Mark Text", silent = true })

local function toggle_strikethrough()
  local function strip_or_wrap(text)
    if text:match("^~~(.-)~~$") then
      return text:gsub("^~~(.-)~~$", "%1")
    end
    return "~~" .. text .. "~~"
  end

  local mode = vim.fn.mode()
  if mode:match("[vV]") or mode == "\22" then
    local saved = vim.fn.getreg('"')
    vim.cmd("normal! gvy")
    local text = vim.fn.getreg('"')
    vim.fn.setreg('"', saved)
    vim.api.nvim_put({ strip_or_wrap(text) }, "c", false, true)
    return
  end

  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col(".") - 1
  local start, finish = line:find(vim.pesc(word), col + 1, true)
  if not start then
    return
  end
  local wrapped = strip_or_wrap(word)
  vim.api.nvim_set_current_line(line:sub(1, start - 1) .. wrapped .. line:sub(finish + 1))
end

vim.keymap.set({ "n", "v" }, "<leader>~", toggle_strikethrough, { desc = "Toggle strikethrough" })
vim.keymap.set({ "n", "v" }, "<leader>ms", toggle_strikethrough, { desc = "Toggle strikethrough" })

vim.keymap.set("i", "<A-k>", "<C-o>d$", { desc = "Cut to end of line" })
vim.keymap.set("c", "<A-k>", "<C-u>", { desc = "Cut to start of command line" })

local markdown_fts = { markdown = true, ["markdown.mdx"] = true, vimwiki = true }

local function apply_markdown_wrap(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local mode = vim.b[buf] and vim.b[buf].markdown_display_mode or "rendered"

  if mode == "raw" then
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 8
    vim.wo.conceallevel = 0
    vim.wo.concealcursor = ""
    vim.wo.spell = false
    return
  elseif mode == "table" then
    vim.wo.wrap = false
    vim.wo.sidescrolloff = 8
    vim.wo.conceallevel = 2
    vim.wo.concealcursor = "nc"
    vim.wo.spell = false
    return
  end

  -- wrap is window-local (vim.wo), not buffer-local — set explicitly per window
  vim.wo.wrap = true
  vim.wo.sidescrolloff = 8
  vim.wo.linebreak = true
  vim.wo.breakindent = true
  vim.wo.breakindentopt = "shift:2,min:20"
  vim.wo.showbreak = "↳ "
  vim.wo.conceallevel = 2
  vim.wo.concealcursor = "nc"
  vim.wo.spell = false
end

local markdown_wrap_group = vim.api.nvim_create_augroup("markdown_dynamic_wrap", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = markdown_wrap_group,
  pattern = { "markdown", "markdown.mdx", "vimwiki" },
  callback = function(args)
    apply_markdown_wrap(args.buf)
  end,
})

-- FileType only fires once per buffer; BufWinEnter covers splits and window switches
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = markdown_wrap_group,
  callback = function(args)
    if markdown_fts[vim.bo[args.buf].filetype] then
      apply_markdown_wrap(args.buf)
    end
  end,
})

local function cycle_sibling_file(step)
  -- 1. Get the full canonical path of the active buffer
  local current_path = vim.api.nvim_buf_get_name(0)
  if current_path == "" or vim.bo.buftype ~= "" then
    vim.notify("Buffer is not a normal file on disk", vim.log.levels.WARN)
    return
  end

  -- Resolve symlinks to ensure exact path matching
  local uv = vim.uv or vim.loop
  current_path = vim.fs.normalize(uv.fs_realpath(current_path) or current_path)
  local current_dir = vim.fs.dirname(current_path)

  -- 2. Collect all regular files in the directory
  local files = {}
  for name, type in vim.fs.dir(current_dir) do
    if type == "file" then
      local full_path = vim.fs.normalize(current_dir .. "/" .. name)
      table.insert(files, full_path)
    end
  end

  if #files == 0 then
    return
  end

  -- 3. Sort alphabetically (matches Neo-tree alphanumeric ordering)
  table.sort(files)

  -- 4. Locate current file index and calculate destination
  for idx, file_path in ipairs(files) do
    if file_path == current_path then
      local target_idx = idx + step

      -- Bounds check: prevent out-of-index errors at top/bottom of folder
      if target_idx < 1 then
        vim.notify("Already at first file in directory", vim.log.levels.INFO)
        return
      elseif target_idx > #files then
        vim.notify("Already at last file in directory", vim.log.levels.INFO)
        return
      end

      -- 5. Open target file in current window
      vim.cmd("edit " .. vim.fn.fnameescape(files[target_idx]))
      return
    end
  end

  vim.notify("Current file not found in directory listing", vim.log.levels.ERROR)
end

-- Cycle through sibling files in current directory alphabetically
vim.keymap.set("n", "]f", function()
  cycle_sibling_file(1)
end, {
  desc = "Next sibling file in directory",
  silent = true,
})

vim.keymap.set("n", "[f", function()
  cycle_sibling_file(-1)
end, {
  desc = "Previous sibling file in directory",
  silent = true,
})

