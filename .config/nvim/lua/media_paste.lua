local M = {}

local IMAGE_CLIPBOARD_PATTERN = "[Pp][Nn][Gg]f|[Jj][Pp][Ee][Gg]|[Tt][Ii][Ff][Ff]|[Gg][Ii][Ff]|[Aa][Vv][Ii][Ff]|[Bb][Mm][Pp]|picture|PICT|TPIC|8BPS|jp2"

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "img-clip" })
end

local function register_has_content(reg)
  local info = vim.fn.getreginfo(reg)
  return info and info.regcontents == 1
end

local function paste_from_register(reg)
  if not register_has_content(reg) then
    return false
  end

  local lines = vim.fn.getreg(reg, 1, 1)
  if type(lines) ~= "table" or (#lines == 1 and lines[1] == "") then
    return false
  end

  local regtype = vim.fn.getregtype(reg)
  local put_type = "c"
  if regtype == "V" then
    put_type = "l"
  elseif regtype == "\22" then
    put_type = "b"
  end

  vim.api.nvim_put(lines, put_type, true, false)
  return true
end

local function clipboard_info_text()
  if vim.fn.has("mac") ~= 1 then
    return nil
  end

  local ok = vim.system({ "osascript", "-e", "clipboard info" }, { text = true }):wait()
  if ok.code ~= 0 or not ok.stdout then
    return nil
  end

  return ok.stdout
end

local function clipboard_info_has_image()
  local info = clipboard_info_text()
  return info ~= nil and info:match(IMAGE_CLIPBOARD_PATTERN) ~= nil
end

local function pngpaste_has_image()
  if vim.fn.executable("pngpaste") ~= 1 then
    return false
  end

  local ok = vim.system({ "sh", "-c", "pngpaste - > /dev/null 2>&1" }):wait()
  return ok.code == 0
end

local function clipboard_has_image()
  if pngpaste_has_image() then
    return true
  end

  if clipboard_info_has_image() then
    return true
  end

  if vim.fn.has("mac") ~= 1 then
    return false
  end

  local script = [[
    try
      (the clipboard as «class PNGf»)
      return "png"
    on error
      try
        (the clipboard as JPEG picture)
        return "jpeg"
      on error
        try
          (the clipboard as TIFF picture)
          return "tiff"
        on error
          try
            (the clipboard as GIF picture)
            return "gif"
          on error
            return "none"
          end try
        end try
      end try
    end try
  ]]
  local ok = vim.system({ "osascript", "-e", script }, { text = true }):wait()
  return ok.code == 0 and ok.stdout:match("%S") and not ok.stdout:match("none")
end

local function run_shell(cmd)
  return vim.system({ "sh", "-c", cmd }):wait()
end

local function write_clipboard_image(path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

  if vim.fn.executable("pngpaste") == 1 then
    local direct = vim.system({ "pngpaste", path }):wait()
    if direct.code == 0 and vim.fn.getfsize(path) > 0 then
      return true
    end

    local stdout = run_shell(string.format("pngpaste - > %s", vim.fn.shellescape(path)))
    if stdout.code == 0 and vim.fn.getfsize(path) > 0 then
      return true
    end
    vim.fn.delete(path)
  end

  if vim.fn.has("mac") ~= 1 then
    return false
  end

  local tmp = path .. ".tmp"
  local formats = {
    { label = "png", script = 'the clipboard as «class PNGf»' },
    { label = "jpeg", script = "the clipboard as JPEG picture" },
    { label = "tiff", script = "the clipboard as TIFF picture" },
    { label = "gif", script = "the clipboard as GIF picture" },
  }

  for _, fmt in ipairs(formats) do
    vim.fn.delete(tmp)
    local script = string.format(
      [[
      try
        set imageData to %s
        set f to open for access (POSIX file "%s") with write permission
        write imageData to f
        close access f
        return "ok"
      on error
        return "fail"
      end try
    ]],
      fmt.script,
      tmp
    )

    local ok = vim.system({ "osascript", "-e", script }):wait()
    if ok.code == 0 and vim.fn.getfsize(tmp) > 0 then
      if fmt.label == "png" then
        vim.fn.rename(tmp, path)
        return true
      end
      if vim.fn.executable("sips") == 1 then
        local converted = vim.system({ "sips", "-s", "format", "png", tmp, "--out", path }):wait()
        vim.fn.delete(tmp)
        if converted.code == 0 and vim.fn.getfsize(path) > 0 then
          return true
        end
      else
        vim.fn.rename(tmp, path)
        return true
      end
    end
  end

  vim.fn.delete(tmp)

  if vim.fn.executable("pbpaste") == 1 then
    for _, prefer in ipairs({ "png", "tiff", "jpeg", "gif" }) do
      local pasted = run_shell(string.format("pbpaste -Prefer %s > %s 2>/dev/null", prefer, vim.fn.shellescape(tmp)))
      if pasted.code == 0 and vim.fn.getfsize(tmp) > 0 then
        if prefer == "png" then
          vim.fn.rename(tmp, path)
          return true
        end
        if vim.fn.executable("sips") == 1 then
          local converted = vim.system({ "sips", "-s", "format", "png", tmp, "--out", path }):wait()
          vim.fn.delete(tmp)
          if converted.code == 0 and vim.fn.getfsize(path) > 0 then
            return true
          end
        end
      end
      vim.fn.delete(tmp)
    end
  end

  return false
end

local function get_macos_clipboard_text()
  if vim.fn.has("mac") ~= 1 or vim.fn.executable("pbpaste") ~= 1 then
    return nil
  end

  if clipboard_has_image() then
    return nil
  end

  local result = vim.system({ "pbpaste" }, { text = true }):wait()
  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    return nil
  end

  if result.stdout:find("\0", 1, true) then
    return nil
  end

  return result.stdout
end

local function is_image_path(text)
  local path = text:match("^%s*(.-)%s*$")
  if not path or path == "" then
    return false
  end

  path = path:gsub("^file://", "")
  if vim.fn.filereadable(path) ~= 1 then
    return false
  end

  local ext = path:lower():match("%.(%w+)$")
  return ext ~= nil and vim.tbl_contains({ "png", "jpg", "jpeg", "gif", "webp", "avif", "tiff", "bmp", "heic" }, ext)
end

local function copy_file(src, dest)
  if vim.uv and vim.uv.fs_copyfile then
    return vim.uv.fs_copyfile(src, dest) == 0
  end
  return run_shell(string.format("cp %s %s", vim.fn.shellescape(src), vim.fn.shellescape(dest))).code == 0
end

local function paste_image_path(path)
  path = path:match("^%s*(.-)%s*$"):gsub("^file://", "")

  local ext = "png"
  local dir = "./assets"
  local name = os.date("%Y-%m-%d-%H-%M-%S") .. "." .. ext
  local dest = vim.fn.fnamemodify(dir .. "/" .. name, ":p")
  vim.fn.mkdir(vim.fn.fnamemodify(dest, ":h"), "p")

  if vim.fn.executable("sips") == 1 then
    local converted = vim.system({ "sips", "-s", "format", "png", path, "--out", dest }):wait()
    if converted.code == 0 and vim.fn.getfsize(dest) > 0 then
      path = dest
      name = vim.fn.fnamemodify(dest, ":t")
    else
      if not copy_file(path, dest) then
        return false
      end
      path = dest
      name = vim.fn.fnamemodify(dest, ":t")
    end
  else
    if not copy_file(path, dest) then
      return false
    end
    path = dest
    name = vim.fn.fnamemodify(dest, ":t")
  end

  local line = string.format("![%s](%s)", name, path)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, { line })
  vim.api.nvim_win_set_cursor(0, { row, col + #line })
  notify("Pasted image: " .. name)
  return true
end

local function paste_macos_clipboard_text()
  local text = get_macos_clipboard_text()
  if not text then
    return false
  end

  if is_image_path(text) then
    return paste_image_path(text)
  end

  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end

  if #lines == 0 then
    return false
  end

  local put_type = #lines == 1 and "c" or "l"
  vim.api.nvim_put(lines, put_type, true, false)
  return true
end

function M.paste()
  if not clipboard_has_image() then
    notify(
      "Clipboard has no image. Copy in Shottr (Cmd+C or Esc), then press p or Space+ip.",
      vim.log.levels.WARN
    )
    return false
  end

  return M.paste_force()
end

function M.has_image()
  return clipboard_has_image()
end

function M.paste_force()
  local ext = "png"
  local dir = "./assets"
  local name = os.date("%Y-%m-%d-%H-%M-%S") .. "." .. ext
  local path = vim.fn.fnamemodify(dir .. "/" .. name, ":p")

  if not write_clipboard_image(path) then
    local info = clipboard_info_text()
    notify(
      "Could not read image from clipboard."
        .. (info and (" Types: " .. info:gsub("\n", " "):sub(1, 120)) or ""),
      vim.log.levels.ERROR
    )
    return false
  end

  local line = string.format("![%s](%s)", name, path)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, { line })
  vim.api.nvim_win_set_cursor(0, { row, col + #line })
  notify("Pasted image: " .. name)
  return true
end

--- Safe smart paste for markdown: registers, image clipboard, then text/path.
function M.smart_paste()
  for _, reg in ipairs({ '"', "+", "*" }) do
    if paste_from_register(reg) then
      return true
    end
  end

  if clipboard_has_image() then
    return M.paste_force()
  end

  if paste_macos_clipboard_text() then
    return true
  end

  notify("Nothing to paste. For Shottr images, copy with Cmd+C or Esc first.", vim.log.levels.INFO)
  return false
end

return M
